#!/usr/bin/env python2
#This fetches the latest files from the repo and puts them in the given folder
from __future__ import with_statement
from urllib2 import Request, build_opener, HTTPError, URLError
from argparse import ArgumentParser
import os, syslog, time, subprocess, stat, glob

VERSION = "1.16"
REPO_NAME = "Yoplitein/tildeslash"
REPO_HOST = "bitbucket"
REPO_TYPE = "git"

try:
    import json
except ImportError:
    try:
        import simplejson as json
    except ImportError:
        log("Fatal: json/simplejson module not importable. Exiting.")
        
        raise SystemExit(1)

#globals
args = log = baseURL = revisionHash = None
opener = build_opener()

def getFile(url, logName):
    file = None
    
    try:
        req = Request(url)
        
        req.add_header("Pragma", "no-cache")
        
        file = opener.open(req)
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

def getBaseURLBitbucket():
    global revisionHash
    
    if   REPO_TYPE == "hg":
        branch = "default"
    elif REPO_TYPE == "git":
        branch = "master"
    else:
        raise ValueError("Unknown repo type " + REPO_TYPE)
    
    revisionHash = json.loads(
            getFile("http://api.bitbucket.org/1.0/repositories/" + REPO_NAME + "/changesets/" + branch, "changesets"))["node"]
    
    return "https://bitbucket.org/" + REPO_NAME + "/raw/" + revisionHash + "/"

def getBaseURLGithub():
    global revisionHash
    
    assert REPO_TYPE == "git", "Github only supports git!"
    
    revisionHash = json.loads(getFile("https://api.github.com/repos/" + REPO_NAME + "/git/refs", "refs"))[0]["object"]["url"].split("/")[-1]
    
    return "https://github.com/" + REPO_NAME + "/raw/" + revisionHash + "/"

def getBaseURL():
    if   REPO_HOST == "bitbucket":
        return getBaseURLBitbucket()
    elif REPO_HOST == "github":
        return getBaseURLGithub()
    else:
        log("Unknown repository host '%s'" % (REPO_HOST,))

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
    for x in range(0, fileNames.count('')):
        fileNames.remove('')
    
    for x in range(0, folderNames.count('')):
        folderNames.remove('')
    
    return fileNames, folderNames

def getUsername():
    try:
        return os.environ["USER"]
    except KeyError:
        return os.path.basename(os.environ["HOME"])

def main():
    global args, log, json, baseURL, VERSION
    
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
                help="print update-dotfiles version", action="store_true", default=False)
    parser.add_argument("-V", dest="checkFilesVersion",
                help="print dotfiles version and exit.", action="store_true", default=False)
    parser.add_argument("-r", "--remote", dest="useRemote",
                help="checks remote (repository) version instead", action="store_true", default=False)
    parser.add_argument("-n", "--no-update", dest="doUpdate",
                help="don't attempt to update self", action="store_false", default=True)
    parser.add_argument("-f", "--force-update", dest="forceUpdate", action="store_true", default=False,
                help="attempt to force update self")
    
    args = parser.parse_args()
    
    if args.checkVersion:
        if args.useRemote:
            repoUpdateDotfiles = getFile(getBaseURL() + "update-dotfiles.py", "update-dotfiles.py")
            scope = {}
            
            try:
                exec repoUpdateDotfiles in scope
                
                VERSION = "(remote) " + scope["VERSION"]
            except:
                print "Remote update-dotfiles did not execute properly."
                
                raise SystemExit
        
        print "update-dotfiles version %s" % VERSION
        
        fileMTime = time.ctime(os.path.getmtime(__file__))
        
        print "Script last updated on %s" % fileMTime
        
        raise SystemExit
    
    if args.checkFilesVersion:
        if args.useRemote:
            getBaseURL()
            
            print "Remote dotfiles are at version", revisionHash
            
            raise SystemExit
        else:
            print "Dotfiles are at version",
            
            with open("%s/.dotfileshash" % (args.directory,), "r") as hash:
                print hash.read(), "\b."
            
            raise SystemExit
    
    #Log to stdout by default
    def stdoutLog(message):
        os.sys.stdout.write(message + "\n")
        os.sys.stdout.flush()
    
    #Log to syslog if running silently
    def silentLog(msg):
        syslog.syslog("[%s:%s] %s" % (getUsername(), os.path.basename(os.getcwd()), msg))
    
    if args.runSilent:
        log = silentLog
    else:
        log = stdoutLog
    
    #Confirm, for safety's sake
    if not args.runSilent:
        yesNo = raw_input("Are you sure? (Y/n) ")
        
        if yesNo.lower() not in ["y", ""]:
            log("Aborting.")
            
            raise SystemExit, 1
    
    baseURL = getBaseURL()
    
    #attempt to update
    if ((os.geteuid() == 0 #if we're root
         or (os.environ["HOME"] in os.path.abspath(__file__))) #or if the script is in the user's home directory
         or args.forceUpdate #or we're forced
         and args.doUpdate): #unless updating is turned off entirely
        
        tryUpdateSelf()
    
    #Change to the specified directory
    os.chdir(args.directory)
    
    #Check for a hash, if enabled
    if args.logHash:
        try:
            hash = ""
            
            with open(".dotfileshash", "r") as f:
                hash = f.read()
                
            if hash == revisionHash:
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
