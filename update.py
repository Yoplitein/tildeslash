#!/usr/bin/env python
#This fetches the latest files from the repo and puts them in ~/
import json, os
from urllib import urlopen

if __name__ == "__main__":
    #Confirm, for safety's sake
    yesNo = raw_input("Are you sure? (y/N) ")
    if yesNo != "y":
        print "Aborting."
        os.sys.exit()
    
    #Get the path for the
    revisionHash = json.loads(\
    urlopen("https://api.bitbucket.org/1.0/repositories/Yoplitein/tildeslash/changesets")\
    .read())["changesets"][-1]["node"]
    baseURL = "https://bitbucket.org/Yoplitein/tildeslash/raw/" + revisionHash + "/"

    fileNames = [".bash_logout", ".bash_profile", ".bashrc", ".vimrc", "bin/afk"]
    
    #Make sure we're in the home directory
    os.chdir(os.getenv("HOME"))
    
    #Make sure ~/bin exists
    if not os.path.exists("bin"):
        os.mkdir("bin")
    
    #Write the files
    for fileName in fileNames:
        file = open(fileName, "w")
        fileContents = urlopen(baseURL + fileName).read()
        file.write(fileContents)
        file.flush()
        file.close()
        print "Wrote %s to disk." % fileName
    
    print "Done."