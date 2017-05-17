on run
	set f to choose file
	processTheFiles({f})
end run

on open theFiles
	processTheFiles(theFiles)
end open

on processTheFiles(theFiles)
	tell application "Image Events" to launch
	repeat with f in theFiles
		set thisFile to f as text
		
		-- iPhone und iPad... all in one...
		scaleAndSave(f, thisFile, 29 * 1, "-29")
		scaleAndSave(f, thisFile, 29 * 2, "-29@2x")
		scaleAndSave(f, thisFile, 29 * 3, "-29@3x")
		scaleAndSave(f, thisFile, 40 * 1, "-40")
		scaleAndSave(f, thisFile, 40 * 2, "-40@2x")
		scaleAndSave(f, thisFile, 40 * 3, "-40@3x")
		scaleAndSave(f, thisFile, 50 * 1, "-50")
		scaleAndSave(f, thisFile, 50 * 2, "-50@2x")
		scaleAndSave(f, thisFile, 50 * 3, "-50@3x")
		scaleAndSave(f, thisFile, 57 * 1, "-57")
		scaleAndSave(f, thisFile, 57 * 2, "-57@2x")
		scaleAndSave(f, thisFile, 57 * 3, "-57@3x")
		scaleAndSave(f, thisFile, 60 * 1, "-60")
		scaleAndSave(f, thisFile, 60 * 2, "-60@2x")
		scaleAndSave(f, thisFile, 60 * 3, "-60@3x")
		scaleAndSave(f, thisFile, 72 * 1, "-72")
		scaleAndSave(f, thisFile, 72 * 2, "-72@2x")
		scaleAndSave(f, thisFile, 72 * 3, "-72@3x")
		scaleAndSave(f, thisFile, 76 * 1, "-76")
		scaleAndSave(f, thisFile, 76 * 2, "-76@2x")
		scaleAndSave(f, thisFile, 76 * 3, "-76@3x")
		
	end repeat
	tell application "Image Events" to quit
end processTheFiles

on scaleAndSave(aPath, aFile, aSize, aName)
	set savePath to text 1 thru -5 of aFile & aName & text -4 thru -1 of aFile
	tell application "Image Events"
		set a to open aPath
		scale a to size aSize
		save a in savePath
	end tell
	delay 0.2
end scaleAndSave
