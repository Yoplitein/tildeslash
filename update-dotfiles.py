#!/usr/bin/env python
#This fetches the latest files from the repo and puts them in the given folder
from __future__ import with_statement
from urllib2 import urlopen, HTTPError
from argparse import ArgumentParser
import os, syslog, time, subprocess

VERSION = "1.5"
REPO_NAME = "Yoplitein/tildeslash"

if __name__ == "__main__":
    #Get options
    parser = ArgumentParser(usage="update-dotfiles")
    parser.add_argument("-c", "--cron", dest="runSilent",
                help="run in cronjob (silent) mode", action="store_true", default=False)
    parser.add_argument("-d", "--dir", dest="directory",
                help="directory to save files to, default ~/", default=os.getenv("HOME"))
    parser.add_argument("-C", "--no-check-hash", dest="logHash",
                help="don't check for revision hash in .dotfileshash", action="store_false", default=True)
    parser.add_argument("-v", "--version", dest="checkVersion",
                help="check update-dotfiles version", action="store_true", default=False)
    parser.add_argument("-n", "--no-update", dest="noUpdate",
                help="Don't attempt to update self", action="store_false", default=True)
    
    args = parser.parse_args()
    
    if(args.checkVersion):
        print "update-dotfiles version %s" % VERSION
        fileMTime = time.ctime(os.path.getmtime(__file__))
        print "Script last updated on %s" % fileMTime
        os.sys.exit()
    
    #By default, we log with print
    def fauxPrint(message):
        os.sys.stdout.write(message + "\n")
        os.sys.stdout.flush()
    
    log = fauxPrint
    
    #Wrapper for syslog to prepend dir information
    def silentLog(msg):
        syslog.syslog("[dir %s] %s" % (os.path.basename(os.getcwd()), msg))
    
    #Use syslog if we're running in cron mode
    if args.runSilent:
        log = silentLog
    
    try:
        import json
    except ImportError:
        try:
            import simplejson as json
        except ImportError:
            log("Fatal: json/simplejson module not importable. Exiting.")
            os.sys.exit(1)
    
    #Confirm, for safety's sake
    if not args.runSilent:
        yesNo = raw_input("Are you sure? (y/N) ")
        if yesNo != "y":
            log("Aborting.")
            os.sys.exit()
    
    #Fetch a file and make sure the server didn't mess up
    def getFile(url, logName):
        file = None
        try:
            file = urlopen(url)
        except (HTTPError, urllib2.URLError), e:
            log("Error fetching %s, server returned status code %s" % (logName, e.code))
            os.sys.exit(1)
        
        contents = file.read()
        file.close()
        return contents
    
    #Get the revision hash to calculate the base URL
    revisionHash = json.loads(\
        getFile("http://api.bitbucket.org/1.0/repositories/" + REPO_NAME + "/changesets", "changesets"))\
        ["changesets"][-1]["node"]
    baseURL = "https://bitbucket.org/" + REPO_NAME + "/raw/" + revisionHash + "/"
    
    if os.geteuid() == 0 and args.noUpdate: #Are we running as root?
        #Get the version number from the repo's version
        repoUpdateDotfiles = getFile(baseURL + "update-dotfiles.py", "update-dotfiles.py")
        scope = {}
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
            os.sys.exit()
    
    #Change to the specified directory
    os.chdir(args.directory)
    
    #Check for a hash, if enabled
    if args.logHash:
        try:
            upHash = ""
            with open(".dotfileshash", "r") as f:
                upHash = f.read()
            if(upHash == revisionHash):
                log("All files are at latest revision, exiting")
                os.sys.exit()
        except IOError:
            pass
    
    #Get the file and folder lists
    fileFolderList = getFile(baseURL + "files.txt", "file and folder list").split("--FOLDERS--")
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
    
    #Make sure each folder exists
    for folder in folderNames:
        if not os.path.exists(folder):
            os.mkdir(folder)
    
    #Write the files
    for fileName in fileNames:
        #we're evaluating this here so we don't exit with open file handlers if there's an error
        bbFile = getFile(baseURL + fileName, fileName)
        
        try:
            with open(fileName, "w") as file:
                file.write(bbFile)
                file.flush()
                file.close()
        except IOError, e:
            log("Error: Unable to write %s to disk. (%s)" % (fileName, e))
            log("Exiting.")
            os.sys.exit(1)
        if not args.runSilent:
            log("Wrote %s to disk." % fileName)
    
    #Write hash to .dotfileshash
    if args.logHash:
        try:
            with open(".dotfileshash", "w") as hashFile:
                hashFile.write(revisionHash)
                hashFile.flush()
        except IOError, e:
            log("Unable to save revision hash. (%s)" % e)
    
    log("Successfully updated all files to revision %s." % revisionHash)
