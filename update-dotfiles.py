#!/usr/bin/env python
#This fetches the latest files from the repo and puts them in the given folder
from __future__ import with_statement
from urllib2 import urlopen, HTTPError, URLError
from argparse import ArgumentParser
import os, syslog, time, subprocess, stat, glob

VERSION = "1.13"
REPO_NAME = "Yoplitein/tildeslash"

#globals
args = log = json = baseURL = revisionHash = None

def getFile(url, logName):
    file = None
    try:
        file = urlopen(url)
    except (HTTPError, URLError) as e:
        if type(e) is URLError:
            message = e.reason.strerror.lower()
        else:
            message = "server returned: %s" % str(e)
            
        log("Error fetching %s, %s" % (logName, message))
        raise SystemExit, 1
    
    contents = file.read()
    file.close()
    return contents

def getBaseURL():
    global revisionHash
    
    revisionHash = json.loads(\
        getFile("http://api.bitbucket.org/1.0/repositories/" + REPO_NAME + "/changesets/default", "changesets"))["node"]
    
    return "https://bitbucket.org/" + REPO_NAME + "/raw/" + revisionHash + "/"

def tryUpdateSelf():
    repoUpdateDotfiles = getFile(baseURL + "update-dotfiles.py", "update-dotfiles.py")
    scope = {}
    
    try:
        exec repoUpdateDotfiles in scope
    
        if scope["VERSION"] != VERSION: #We're out of date! D:
            log("Attempting to update self..")
            
            fullFileName = os.path.abspath(__file__)
            file = open(fullFileName, "w")
            
            file.truncate()
            file.write(repoUpdateDotfiles)
            file.close()
            
            log("Updated! Re-running script.")
            subprocess.call(os.sys.argv + ["-n"])
            
            raise SystemExit
    except (KeyError, Exception) as e:
        if type(e) is KeyError:
            msg = "Remote update-dotfiles does not have a version, will not update"
        elif type(e) is SystemExit:
            raise
        else:
            msg = "Remote update-dotfiles threw exception, will not update."
        
        log(msg)
        
        raise SystemExit, 1

def parseFileList(fileList):
    fileFolderList = fileList.split("--FOLDERS--")
    fileNames = fileFolderList[0].split("\n")
    folderNames = fileFolderList[1].split("\n")
    
    #Remove empty strings from file and folder list
    try:
        while True:
            fileNames.remove('')
    except ValueError:
        pass
    
    try:
        while True:
            folderNames.remove('')
    except ValueError:
        pass
    
    return fileNames, folderNames

def main():
    global args, log, json, baseURL
    
    #Get options
    parser = ArgumentParser(description="Updates your dotfiles with copies from a central repository.",
                            usage="update-dotfiles")
    
    parser.add_argument("-c", "--cron", dest="runSilent",
                help="run in cronjob (silent) mode", action="store_true", default=False)
    parser.add_argument("-d", "--dir", dest="directory",
                help="directory to save files to, default ~/", default=os.getenv("HOME"))
    parser.add_argument("-C", "--no-check-hash", dest="logHash",
                help="don't check for revision hash in .dotfileshash", action="store_false", default=True)
    parser.add_argument("-v", "--version", dest="checkVersion",
                help="check update-dotfiles version", action="store_true", default=False)
    parser.add_argument("-n", "--no-update", dest="doUpdate",
                help="Don't attempt to update self", action="store_false", default=True)
    parser.add_argument("-f", "--force-update", dest="forceUpdate", action="store_true", default=False,
                help="Attempt to force update self")
    
    args = parser.parse_args()
    
    if(args.checkVersion):
        print "update-dotfiles version %s" % VERSION
        
        fileMTime = time.ctime(os.path.getmtime(__file__))
        
        print "Script last updated on %s" % fileMTime
        
        raise SystemExit
    
    #Log to stdout by default
    def stdoutLog(message):
        os.sys.stdout.write(message + "\n")
        os.sys.stdout.flush()
    
    #Log to syslog if running silently
    def silentLog(msg):
        syslog.syslog("[%s:%s] %s" % (os.environ["USER"], os.path.basename(os.getcwd()), msg))
        
    if args.runSilent:
        log = silentLog
    else:
        log = stdoutLog
    
    try:
        import json as _json
    except ImportError:
        try:
            import simplejson as _json
        except ImportError:
            log("Fatal: json/simplejson module not importable. Exiting.")
            
            raise SystemExit, 1
    
    json = _json
    
    #Confirm, for safety's sake
    if not args.runSilent:
        yesNo = raw_input("Are you sure? (y/N) ")
        
        if yesNo != "y":
            log("Aborting.")
            
            raise SystemExit, 1
    
    baseURL = getBaseURL()
    
    #attempt to update if we're root
    #or if an update is forced
    #or if update-dotfiles is in the executing user's home directory
    #unless updating is turned off (--no-update)
    if (os.geteuid() == 0 or args.forceUpdate or (os.environ["HOME"] in os.path.abspath(__file__))) and args.doUpdate:
        tryUpdateSelf()
    
    #Change to the specified directory
    os.chdir(args.directory)
    
    #Check for a hash, if enabled
    if args.logHash:
        try:
            hash = ""
            
            with open(".dotfileshash", "r") as f:
                hash = f.read()
            
            if(hash == revisionHash):
                log("All files are at latest revision, exiting")
                
                raise SystemExit
        except IOError:
            pass
    
    #Get the file and folder lists
    fileNames, folderNames = parseFileList(getFile(baseURL + "files.txt", "file and folder list"))
    
    #Make sure each folder exists
    for folder in folderNames:
        if not os.path.exists(folder):
            os.mkdir(folder)
    
    #Remove stale files
    for fileName in fileNames[:]:
        if fileName.startswith("_stale"):
            try:
                realFileName = fileName.split("_stale")[1]
                
                os.remove(realFileName)
                log("Removing stale file %s" % realFileName)
            except:
                pass
            finally:
                fileNames.remove(fileName)
    
    #Write the files
    for fileName in fileNames:
        #we're evaluating this here so we don't exit with open file handlers if there's an error
        bbFile = getFile(baseURL + fileName, fileName)
        
        try:
            with open(fileName, "w") as file:
                file.write(bbFile)
                file.flush()
                file.close()
        except IOError as e:
            log("Error: Unable to write %s to disk. (%s)" % (fileName, e))
            log("Exiting.")
            raise SystemExit, 1
        
        if not args.runSilent:
            log("Wrote %s to disk." % fileName)
    
    #make files in bin/ executable
    if os.path.exists("bin"):
        for file in glob.glob("bin/*"):
            mode = os.stat(file)
            os.chmod(file, mode.st_mode | stat.S_IEXEC)
    
    #Write hash to .dotfileshash
    if args.logHash:
        try:
            with open(".dotfileshash", "w") as hashFile:
                hashFile.write(revisionHash)
                hashFile.flush()
        except IOError as e:
            log("Unable to save revision hash. (%s)" % e)
    
    log("Successfully updated all files to revision %s." % revisionHash)

if __name__ == "__main__":
    main()
