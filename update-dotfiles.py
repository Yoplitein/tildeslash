#!/usr/bin/env python3
#This fetches the latest files from the repo and puts them in the given folder
from argparse import ArgumentParser
from urllib.error import URLError
from urllib.request import Request, build_opener, HTTPError
import os, syslog, stat

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

def getFile(url, logName, encoding=None):
    file = None
    
    try:
        req = Request(url)
        req.add_header("Pragma", "no-cache")
        
        file = opener.open(req)
        contents = file.read()
        if encoding != None:
            contents = contents.decode(encoding)
        return contents
    except (HTTPError, URLError) as e:
        if type(e) is URLError:
            message = e.reason.strerror.lower()
        else:
            message = f"server returned: {e}"
        
        log(f"Error fetching {logName}, {message}")
        
        raise SystemExit(1)
    finally:
        if file:
            file.close()
    

def getBaseURLBitbucket():
    global revisionHash
    
    if   REPO_TYPE == "hg":
        branch = "default"
    elif REPO_TYPE == "git":
        branch = "master"
    else:
        raise ValueError("Unknown repo type " + REPO_TYPE)
    
    revisionHash = json.loads(
        getFile("http://api.bitbucket.org/2.0/repositories/" + REPO_NAME + "/commit/" + branch, "branchInfo", encoding="utf-8")
    )["hash"]
    
    return "https://bitbucket.org/" + REPO_NAME + "/raw/" + revisionHash + "/"

def getBaseURLGithub():
    global revisionHash
    
    assert REPO_TYPE == "git", "Github only supports git!"
    
    revisionHash = json.loads(getFile("https://api.github.com/repos/" + REPO_NAME + "/git/refs", "refs", encoding="utf-8"))[0]["object"]["url"].split("/")[-1]
    
    return "https://github.com/" + REPO_NAME + "/raw/" + revisionHash + "/"

def getBaseURL():
    if   REPO_HOST == "bitbucket":
        return getBaseURLBitbucket()
    elif REPO_HOST == "github":
        return getBaseURLGithub()
    else:
        log(f"Unknown repository host '{REPO_HOST}'")

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
    parser.add_argument("-v", dest="checkFilesVersion",
                help="print dotfiles version and exit.", action="store_true", default=False)
    parser.add_argument("-r", "--remote", dest="useRemote",
                help="checks remote (repository) version instead", action="store_true", default=False)
    
    args = parser.parse_args()
    
    if args.checkFilesVersion:
        if args.useRemote:
            getBaseURL()
            print("Remote dotfiles are at version", revisionHash)
            raise SystemExit
        else:
            print("Dotfiles are at version ", end="")
            with open(f"{args.directory}/.dotfileshash", "r") as hash:
                print(hash.read().strip())
            raise SystemExit
    
    #Log to stdout by default
    def stdoutLog(message):
        os.sys.stdout.write(message + "\n")
        os.sys.stdout.flush()
    
    #Log to syslog if running silently
    def silentLog(msg):
        syslog.syslog(f"[{getUsername()}:{os.path.basename(os.getcwd())}] {msg}")
    
    if args.runSilent:
        log = silentLog
    else:
        log = stdoutLog
    
    #Confirm, for safety's sake
    if not args.runSilent:
        yesNo = input("Are you sure? (Y/n) ")
        
        if yesNo.lower() not in ["y", ""]:
            log("Aborting.")
            
            raise SystemExit(1)
    
    baseURL = getBaseURL()
    
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
    fileNames, folderNames = parseFileList(getFile(baseURL + "files.txt", "file and folder list", encoding="utf-8"))
    
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
                log(f"Removing stale file {realFileName}")
            except:
                pass
            finally:
                fileNames.remove(fileName)
    
    #Write the files
    for fileName in fileNames:
        #we're evaluating this here so we don't exit with open file handlers if there's an error
        bbFile = getFile(baseURL + fileName, fileName)
        
        try:
            with open(fileName, "wb") as file:
                file.write(bbFile)
                file.flush()
                file.close()
        except IOError as e:
            log(f"Error: Unable to write {fileName} to disk. ({e})")
            log("Exiting.")
            raise SystemExit(1)
        
        if not args.runSilent:
            log(f"Wrote {fileName} to disk.")
    
    #make files in bin/ executable
    if os.path.exists("bin"):
        for file in fileNames:
            if not file.startswith("bin/"):
                continue
            
            mode = os.stat(file)
            
            try:
                os.chmod(file, mode.st_mode | stat.S_IEXEC)
                log(f"Marking {file} as executable")
            except IOError:
                log(f"Failed to change mode of {file}")
    
    #Write hash to .dotfileshash
    if args.logHash:
        try:
            with open(".dotfileshash", "w") as hashFile:
                hashFile.write(revisionHash)
                hashFile.flush()
        except IOError as e:
            log(f"Unable to save revision hash. ({e})")
    
    log(f"Successfully updated all files to revision {revisionHash}.")

if __name__ == "__main__":
    main()
