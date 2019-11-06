############################
#Scripted Rule importModules
# This scripted rule will import custom Jython modules for use in scripts
# It doesn't actually compute a release limit
# This rule should be located at the very first reservoir to initialize
# so that all other scripts can use these modules
# As of ResSim 3.2.1197, this means the first reservoir in the alphabet
# Scripted rules init before state variables, so it shouldn't be in a state variable
# If additional modules are to be added, make sure to add paths to them in sys.path
# Default paths include ExternalModules for JAR files and CRTModules for custom CRT
# code such as functionHolder
# OLD CODE used to:
#And perform the 'reload' function on them
#All modules should be stored in the "scripts" folder of the watershed
############################
from hec.script import Constants
import os, sys, glob, types

def reloadImports():
	#rjc 3/2/2018. For some reason, the looping reload doesn't fully do the reloading.
	#Have to do it manually if you want it to stick
	#from NWDJyLib import cTimes
	#reload(cTimes)
	#from NWDJyLib.CanadianOps import cRefillFRMBCH
	#from NWDJyLib.CanadianOps import cLocalFRM
	#reload(cRefillFRMBCH)
	#reload(cLocalFRM)
	for name, val in globals().items():
		if isinstance(val, types.ModuleType):
			reload(val)
			print("Reloaded module %s as %s" % (val.__name__, name))

def initRuleScript(currentRule, network):
	# Add the custom module locations to sys.path
	# The scripts do not need to individually check sys.path if it is done once here
	modulePath = network.makeAbsolutePathFromWatershed("scripts")
	#modulePath = os.path.join(ClientAppWrapper.getWatershed().getWkspDir(), "scripts")
	modPaths = []
	#modPaths.append() #for subfolders
	modPaths.append(modulePath)
	modPaths.append("/".join([modulePath, "ExternalModules"])) #for Jython / Python modules
	modPaths += glob.glob("/".join([modulePath, "ExternalModules", "*.jar"])) # for JARs
	for mPath in modPaths:
		if not mPath in sys.path:
			sys.path.append(mPath)
	#network.printWarningMessage("\n".join(sys.path))

	#reloading the modules makes sure that any changes to the .py scripts are incorporated
	reloadImports()

	return Constants.TRUE

def runRuleScript(currentRule, network, currentRuntimestep):
	#Dummy rule
	return None