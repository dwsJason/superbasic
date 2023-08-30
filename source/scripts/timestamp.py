# *******************************************************************************************
# *******************************************************************************************
#
#		Name : 		timestamp.py
#		Purpose :	Output assembly timestamp
#		Date :		5th October 2022
#		Author : 	Paul Robson (paul@robsons.org.uk)
#
# *******************************************************************************************
# *******************************************************************************************

import os,sys,math,datetime

buildCount = int(sys.argv[-1])

time = datetime.datetime.now()
build = time.strftime("%d/%m/%y")
h = open("common/generated/timestamp.asm","w")
h.write(";\n;\tThis file is automatically generated.\n;\n")
h.write("\t.text 9,9,\"{0} {1:02}d\"\n".format(build,buildCount))
h.close()	
