#!/usr/bin/env python
# encoding: utf-8

import sys
import os
import shutil
import subprocess

version = "1.0"
current_folder = os.path.abspath(os.path.dirname(__file__))
disk = "MNX"
pkg = disk + '-' + version + ".pkg"
# dmg_icns = "../Artworks/icon2008/ovdmg/ovdmg.icns"

applescript  = "tell application \"Finder\"\n\
		tell disk \"" + disk + "\"\n" + """
			open
			set theXOrigin to 40
			set theYOrigin to 60
			set theWidth to 500
			set theHeight to 375
			set theBottomRightX to (theXOrigin + theWidth)
			set theBottomRightY to (theYOrigin + theHeight)
			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				set statusbar visible to false
			end tell

			set opts to the icon view options of container window
			tell opts
				set icon size to 168
				set arrangement to not arranged
			end tell
			set background picture of opts to file ".images:background.jpg"
			set position of item "MNX.app" to {350, 220}
			set label index of item "MNX.app" to 1
			set position of item "Drop it here!" to {130, 220}
			set label index of item "Drop it here!" to 2
			update without registering applications
			delay 2
		end tell
	end tell
"""

def build_release():
	project_target_name = "MNX"
	clean_command = "xcodebuild -project ../MNX.xcodeproj -configuration Release clean"
	build_command = "xcodebuild -project ../MNX.xcodeproj -configuration Release -target \"" + project_target_name + "\" build"
	# os.system(clean_command)
	os.system(build_command)

def copy_release_to_tmp():
	source_filename = "MNX.app"
	source_path = "../build/Release"
	source = os.path.abspath(os.path.join(current_folder, source_path, source_filename))
	target = os.path.abspath(os.path.join(current_folder, "tmp"))
	try:
		os.system("sudo rm -rf " + target)
	except Exception: # as e:
		# print str(e)
		print "exception!"
		pass
	try:
		os.mkdir(target)
	except Exception: # as e:
		# print str(e)
		print "exception!"
		pass
	shutil.copytree(source, os.path.join(target, source_filename))
	# os.system("sudo chown -R root:admin " + os.path.join(target, source_filename))
	os.system("sudo chown -R root:admin ./tmp/*")

def build_package():
	package_maker = "./PackageMaker.app/Contents/MacOS/PackageMaker"
	arg = " -build -ds -v -proj TLIM.pmproj -p " + pkg
	print package_maker + arg
	os.system(package_maker + arg)

def make_dmg():
	size = 8 * 1024 * 2;
	command = "/usr/bin/hdiutil"
	arg = [command, "create",  "-sectors", str(size), "-volname", disk, "-attach", "-fs", "HFS+", "MNX.dmg"]
	
	result = subprocess.Popen(arg, stdout=subprocess.PIPE).communicate()
	lines = result[0].split("\n")
	device = ""
	for line in lines:
		if line.find("Apple_HFS") > -1:
			space = line.find(" ")
			device = line[:12]

	# string_folder = os.path.abspath(os.path.join(current_folder, 'strings'))
	# shutil.copytree(string_folder, os.path.join("/Volumes", disk , '.localized'))
	
	source_filename = "MNX.app"
	source_path = "../build/Release"
	source = os.path.abspath(os.path.join(current_folder, source_path, source_filename))

	shutil.copytree(source, os.path.join("/Volumes", disk , source_filename))
	imageFolder = os.path.join("/Volumes", disk , '.images')
	os.mkdir(imageFolder)	
	shutil.copy('images/background.jpg', os.path.join(imageFolder, 'background.jpg'))
	os.symlink('/Applications', os.path.join("/Volumes", disk, 'Drop it here!'))
	
	# shutil.copy(dmg_icns, os.path.join("/Volumes", disk , ".VolumeIcon.icns"))
	# os.system("SetFile -a C " + os.path.join("/Volumes", disk))

	subprocess.Popen(["osascript", "-e", applescript])
	os.system("sleep 2")
	
	os.system("hdiutil detach " + device )
	command = "hdiutil convert MNX.dmg -format UDZO -imagekey zlib-level=9 -o " + disk + '-' + version +".dmg"
	os.system(command)

def main():
	os.system("sudo rm -rf *.dmg")
	build_release()
	print "Building DMG..."
	make_dmg()
	print "Done.."
	pass


if __name__ == '__main__':
	main()

