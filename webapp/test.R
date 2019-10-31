#testing opening shiny app

suppressPackageStartupMessages(require(shiny,quietly = T))

#Retrieving the arguments passes via batch file and assigning
args = commandArgs(trailingOnly=TRUE)
defaultHost <- args[1]
defaultPort <- as.integer(args[2])

#Location of shiny app relat
dirName = sprintf("%s/webapp", getwd())


#Default location of Chrome executable
#defaultChromeExe = "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
defaultURL = sprintf("http://%s:%g/",defaultHost, defaultPort)

#cat(sprintf("\nLaunching url:\t%s", defaultURL))

#Opening Chrome and running App
#system(sprintf('"%s" %s', defaultChromeExe, defaultURL))
runApp(appDir = dirName, launch.browser=F, port = defaultPort, host = defaultHost, quiet = T)

#cat("\n\n")
