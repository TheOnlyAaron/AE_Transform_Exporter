--*****************************************************
-- AE_Position_Exporter.ms
--
--Aaron Dabelow, theonlyaaron@gmail.com
-- www.aarondabelow.com
-- Written for MAX v.9.0 and up
--*****************************************************
-- PURPOSE:
--		Export transforms and cameras to AE
--*****************************************************
-- HISTORY:
--    - v1.0 (8.13.12):
--        (i) 1st version.
--*****************************************************

(try(closeRolloutFloater AETransformsExporter)catch())
	
(
global framesStart = 0
global framesEnd = 100
global clipboardString = "defined"
global headderText
global footerText
global clipbpardString
global theAnimatedObject
global currentFrame
global totalFrames
global updateEditText()
)

(
global headderText = "Adobe After Effects 8.0 Keyframe Data
 "
	
global positionHeadderText = "Transform	Position
	Frame	X pixels	Y pixels	Z pixels"
	
global positionScaleText = "Transform	Scale
	Frame	X percent	Y percent	Z percent"
	
global positionRotationZText = "Transform	Rotation
	Frame	degrees	"
	
global positionRotationXText = "Transform	X Rotation
	Frame	degrees	"
	
global positionRotationYText = "Transform	Y Rotation
	Frame	degrees	"

global returnText ="
"
global footerText = "
End of Keyframe Data"

global fpsText = "	Units Per Second	"

clipbpardString = "defined"

enablesceneredraw()
)

rollout StaticPositionExporter "Static"
(
	groupBox GrabGroup "Copy Static Transforms" width:151 height:64 pos: [5,5]
	button copyToClipboardStatic " Copy To Clipboard " width: 135 height:20 pos: [13,22] tooltip: "Copy selected objects position data to your clipboard to be pasted into After Effects."
	button saveTextStatic " Save to File " width: 135 height:20 pos: [13,42] tooltip: "Save selected objects position data as a .txt file to be copied into After Effects."
	
	function parseTransformsStatic obj =
		(
		currentFrameText = "	"+((currentTime as integer)/TicksPerFrame) as string
				
		xPosition =((floor (obj.pos.x * 1000)) / 1000)
		yPosition =((floor (obj.pos.y * 1000)) / 1000)
		zPosition =((floor (obj.pos.z * 1000)) / 1000)

-- 		xPositionMod = xPosition
-- 		yPositionMod = -zPosition
-- 		zPositionMod = yPosition	
		
		xPositionMod = xPosition
		yPositionMod = yPosition
		zPositionMod = zPosition	
			
		xPositionText = "	"+xPosition as string
		yPositionText = "	"+( -1 * zPosition) as string
		zPositionText = "	"+yPosition as string	
		
		xScaleText = "	"+ (int(obj.scale[1] * 100) as string)
		yScaleText = "	"+ (int(obj.scale[2] * 100) as string)
		zScaleText = "	"+ (int(obj.scale[3] * 100) as string)
		
		fn float4dec arg = ((floor (1000 * arg)) / 1000)

		quatRotations = quatToEuler obj.rotation order:3
		eulerRotations = [-(float4dec quatRotations.x),-(float4dec quatRotations.y),-(float4dec quatRotations.z)]

									-------------------------------------- HERE IS WHERE TO DICK AROUND -------------------------------
		xRotationText = positionRotationXText + returnText + currentFrameText + "	" + (1 * eulerRotations[3]) as string + returnText
		yRotationText = positionRotationYText + returnText + currentFrameText +  "	" + ( -1 * eulerRotations[2] ) as string + returnText
		zRotationText = positionRotationZText + returnText + currentFrameText +  "	" + (-1 * eulerRotations[1]) as string + returnText
				
		comboString = headderText + returnText +  positionHeadderText + returnText + currentFrameText + xPositionText + yPositionText + zPositionText + returnText + returnText + positionScaleText + returnText + currentFrameText + xScaleText + yScaleText + zScaleText  + returnText  + returnText + zRotationText + returnText + xRotationText + returnText + yRotationText + footerText

		return comboString
		)
	
	on copyToClipboardStatic pressed do
		(
			if selection.count ==1 then
				(
				try(
					comboString = parseTransformsStatic selection[1]
					setclipboardText comboString
					--print comboString as string
		
					messagebox "AE keyframe Data has been copied to your clipboard."
				)
				catch(Messagebox "Error")
			)
			else (messagebox "You must select one (1) object")
		)
	
	on saveTextStatic pressed do
		(
			if selection.count == 1 then
			(
				try
					(
					saveForAEFileStaticName = "c:/StaticPositionForAE.txt"
						
					if saveForAEFileStaticName != undefined then
					 (
						saveForAEFileStatic = createfile saveForAEFileStaticName
					
						comboString = parseTransformsStatic selection[1]
						--print comboString as string
						 
						format "%\n" comboString to:saveForAEFileStatic  ---  SAVE THE COMBO
						
						close saveForAEFileStatic
						shelllaunch "notepad.exe" saveForAEFileStaticName
						)
					else()	
					)
				catch(Messagebox "unexpected error")
			)
			else (Messagebox "You must select one (1) object")
		)
)

rollout AnimatedPositionsExporter "Animated"
(
	groupBox optionsGroup "Channels" width:151 height:65 pos: [5,5]
	checkbox checkboxPosition "Positions" pos: [15,20] checked:true
	checkbox checkboxRotation "Rotations" pos: [15,35] checked:true
	checkbox checkboxScale "Scale" pos: [15,50] checked:true
	
	checkbox checkboxFOV "FOV (cam)" pos: [80,20] checked:false visible:false
	
	groupBox framesGroup "Frame range" width:151 height:60 pos: [5,72]
	spinner framesStartSpinner "" range:[0,99999,0] width:58 type:#integer pos: [13,88]
	spinner framesEndSpinner "To " range:[0,99999,100] width:70 type:#integer pos: [78,88]
	button timeSnap "Snap to Timeline" width: 135 height:20 pos: [13,105]
	

	groupBox Processing "Copy Animated Transforms" width:151 height:93 pos: [5,135]
		button processPositionsClipboard " Copy to Clipboard " width: 135 height:20 pos: [13,150]
	button processPositions " Save to File " width: 135 height:20 pos: [13,170]
	label lab1 "Status: Ready"
	progressbar objProgress   width: 134 height:7 pos: [13,215]
	
	function float4dec arg = ((floor (1000 * arg)) / 1000)
		
	function parsePositionsAnimated obj =
		(
		xPosition =((floor (obj.pos.x * 1000)) / 1000) --as string
		yPosition =((floor (obj.pos.y * 1000)) / 1000) --as string
		zPosition =((floor (obj.pos.z * 1000)) / 1000) --as string
			
		return [xPosition,yPosition,zPosition]
		)
	
	function parseScalesAnimated obj =
		(
		xScaleText =int(obj.scale[1] * 100) --as string)
		yScaleText =int(obj.scale[2] * 100) --as string)
		zScaleText =int(obj.scale[3] * 100) --as string)
			
		return [xScaleText,yScaleText,zScaleText]
		)
		
	function parseRotationsAnimated obj =
		(
		quatRotations = quatToEuler obj.rotation order:1 --order:3
			
		return [-(float4dec quatRotations.x),-(float4dec quatRotations.y),(float4dec quatRotations.z)]
		--return [-(float4dec quatRotations.x),-(float4dec quatRotations.y),-(float4dec quatRotations.z)]
		)	
	
	function functionTimeSnap = 
		(
		framesStartSpinner.range = [-99999,99999,animationRange.start]
		framesEndSpinner.range = [-99999,99999,animationRange.end]
		framesStart = animationRange.start
		framesEnd = animationRange.end
		framesStartVal = framesStart
		framesEndVal = framesEnd
		)
	
	on AnimatedPositionsExporter open do
		(
		functionTimeSnap()
		)

	on framesStartSpinner changed framesStartVal do
		(
		framesStart = framesStartVal
		--print ("Start Frame: " + framesStart as string)
			
		if (framesStart >= framesEnd) then
			(
			framesEndUpdate = (framesStart+1)
			framesEnd = framesEndUpdate
			--print framesEndUpdate
			framesEndSpinner.range = [0,99999,framesEndUpdate]
			)
		else ()
			
		)
	
	on framesEndSpinner changed framesEndVal do
		(
		framesEnd = framesEndVal
		--print ("End Frame: " + framesEnd as string)
			
		if (framesStart >= framesEnd) then
			(
			framesStartUpdate = (framesEnd-1)
			framesStart = framesStartUpdate
			--print framesStartUpdate
			framesStartSpinner.range = [0,99999,framesStartUpdate]
			)
		else ()
			
		)	
		
	on timeSnap pressed do
		(
		functionTimeSnap()
		)
		
	on processPositionsClipboard pressed do
		(
		try(
		if selection.count == 1 then
			(
				lab1.text = "Status: Initalizing"
				masterString = ""
				
				disableSceneRedraw()
				obj = selection[1]
				
				-- Prepare Timeline Data
				oldAnimationRange = animationRange
				animationRange = interval framesStart FramesEnd
				oldSliderTime = sliderTime
				
				-- Prepare Save File
				 
				-- Set Timeline for start
				sliderTime = framesStart
				totalFrames =(framesEnd-framesStart)
				currentFrame = 0
					
				------ PREPARE READER and OBJ -------
				readerPoint = point()
				
				 ----- WRITE HEADDER DATA -----
				masterString = masterString + headderText
				masterString = masterString + returnText
				masterString = masterString + (fpsText + (framerate as string))
					
				headderjunk = "	Source Width	100
 	Source Height	100
 	Source Pixel Aspect Ratio	1
 	Comp Pixel Aspect Ratio	1"
				
				masterString = masterString + returnText
				masterString = masterString + headderjunk
					
					
				----- CLEAR CANNEL STRINGS ----------
				positionChannelString =  returnText + positionHeadderText
				scaleChannelString = returnText + positionScaleText 
				rotationZChannelString = returnText + positionRotationZText
				rotationXChannelString = returnText + positionRotationXText
				rotationYChannelString = returnText + positionRotationYText

				lab1.text = "Status: Baking"
					
				 ------ LOOP THROUGH FRAMERANGE ------
				 for i in framesStart to framesEnd do
					(
					currentFrameText =((currentTime as integer)/TicksPerFrame) as string
					readerPoint.transform = obj.transform
						
					if checkboxPosition.checked == true then 
						(
						curPos = parsePositionsAnimated readerPoint
						positionChannelString = positionChannelString + returnText + "	" + currentFrameText + "	" +(curPos[1] as string) + "	" +((-1 * curPos[3]) as string) + "	" +((1 * curPos[2]) as string) 
						)else()
						
					if checkboxRotation.checked == true then
						(
						curRots = parseRotationsAnimated readerPoint 
						rotationZChannelString = rotationZChannelString + returnText + "	" + currentFrameText + "	" +(curRots[1] as string)
						rotationXChannelString = rotationXChannelString + returnText + "	" + currentFrameText + "	" +(curRots[2] as string)
						rotationYChannelString = rotationYChannelString + returnText + "	" + currentFrameText + "	" +(curRots[3] as string)
						)else()
						
					if checkboxScale.checked == true then 
						(
						curScale = parseScalesAnimated readerPoint 
						scaleChannelString = scaleChannelString + returnText + "	" + currentFrameText + "	" +(curScale[1] as string) + "	" +(curScale[2] as string) + "	" +(curScale[3] as string) 
						)else()
						
					if doFOV == true then
						(
						)else()
						
					-- Update UI and i 
					sliderTime =(sliderTime+1)
					objProgress.value = 100.*currentFrame/totalFrames
					currentFrame = (currentFrame+1)
					)
					
				 -------- WRITE CREATED DATA IN PROPER ORDER ------------
				lab1.text = "Status: Writing File"
					
				if checkboxPosition.checked == true then
					(
					masterString = masterString + returnText
					masterString = masterString + positionChannelString
					)else()
					
				if checkboxScale.checked == true then
					(
					masterString = masterString + returnText
					masterString = masterString +  scaleChannelString
					)else()
					
				if checkboxRotation.checked == true then
					(
					masterString = masterString + returnText
					masterString = masterString + rotationZChannelString
					masterString = masterString + returnText
					masterString = masterString + rotationXChannelString
					masterString = masterString + returnText
					masterString = masterString + rotationYChannelString
					)else()
					
				if checkboxFOV.checked == true then
					(
					--format "%\n" "FOV CHECK" to:saveForAEFileAnimated	
					)else()
					
				 ------ CREATE FOOTER DATA and WRITE FILE TO DISK-----------
				masterString = masterString + returnText
				masterString = masterString + footerText
				 
				 -------- RESET TIMELINE and VIEWS ---------------
				delete readerPoint
				animationRange = oldAnimationRange 
				SliderTime = oldSliderTime
				redraw = on
				enableSceneRedraw()
				redrawViews()
				 
				 ------ OPEN FILE -----------
				setclipboardText masterString
				
				messagebox "AE keyframe Data has been copied to your clipboard."
				
			)else(messagebox"Select 1 object")
		)catch(messagebox "unhandled exception, sorry! :D")
		lab1.text = "Status: Completed"
		)	
		
	on processPositions pressed do
		(
		try(
		if selection.count == 1 then
			(
				lab1.text = "Status: Initalizing"
				
				disableSceneRedraw()
				obj = selection[1]
				
				-- Prepare Timeline Data
				oldAnimationRange = animationRange
				animationRange = interval framesStart FramesEnd
				oldSliderTime = sliderTime
				
				-- Prepare Save File
				saveForAEFileAnimatedName = "c:/AnimatedPositionForAE.txt"
				saveForAEFileAnimated = createfile saveForAEFileAnimatedName
				 
				-- Set Timeline for start
				sliderTime = framesStart
				totalFrames =(framesEnd-framesStart)
				currentFrame = 0
					
				------ PREPARE READER and OBJ -------
				readerPoint = point()
				
				 ----- WRITE HEADDER DATA -----
				format "%\n" headderText to:saveForAEFileAnimated
				format "%\n" (fpsText + (framerate as string)) to:saveForAEFileAnimated 
					
				headderjunk = "	Source Width	100
 	Source Height	100
 	Source Pixel Aspect Ratio	1
 	Comp Pixel Aspect Ratio	1"
					
				format "%\n" headderjunk to:saveForAEFileAnimated
					
					
				----- CLEAR CANNEL STRINGS ----------
				positionChannelString =  returnText + positionHeadderText
				scaleChannelString = returnText + positionScaleText 
				rotationZChannelString = returnText + positionRotationZText
				rotationXChannelString = returnText + positionRotationXText
				rotationYChannelString = returnText + positionRotationYText

				lab1.text = "Status: Baking"
					
				 ------ LOOP THROUGH FRAMERANGE ------
				 for i in framesStart to framesEnd do
					(
					currentFrameText =((currentTime as integer)/TicksPerFrame) as string
					readerPoint.transform = obj.transform
						
					if checkboxPosition.checked == true then 
						(
						curPos = parsePositionsAnimated readerPoint
						positionChannelString = positionChannelString + returnText + "	" + currentFrameText + "	" +(curPos[1] as string) + "	" +((-1 * curPos[3]) as string) + "	" +((1 * curPos[2]) as string) 
						)else()
						
					if checkboxRotation.checked == true then
						(
						curRots = parseRotationsAnimated readerPoint 
						rotationZChannelString = rotationZChannelString + returnText + "	" + currentFrameText + "	" +(curRots[1] as string)
						rotationXChannelString = rotationXChannelString + returnText + "	" + currentFrameText + "	" +(curRots[2] as string)
						rotationYChannelString = rotationYChannelString + returnText + "	" + currentFrameText + "	" +(curRots[3] as string)
						)else()
						
					if checkboxScale.checked == true then 
						(
						curScale = parseScalesAnimated readerPoint 
						scaleChannelString = scaleChannelString + returnText + "	" + currentFrameText + "	" +(curScale[1] as string) + "	" +(curScale[2] as string) + "	" +(curScale[3] as string) 
						)else()
						
					if doFOV == true then
						(
						)else()
						
					-- Update UI and i 
					sliderTime =(sliderTime+1)
					objProgress.value = 100.*currentFrame/totalFrames
					currentFrame = (currentFrame+1)
					)
					
				 -------- WRITE CREATED DATA IN PROPER ORDER ------------
				lab1.text = "Status: Writing File"
					
				if checkboxPosition.checked == true then
					(
					format "%\n" positionChannelString to:saveForAEFileAnimated	
					)else()
					
				if checkboxScale.checked == true then
					(
					format "%\n" scaleChannelString to:saveForAEFileAnimated		
					)else()
					
				if checkboxRotation.checked == true then
					(
					format "%\n" rotationZChannelString to:saveForAEFileAnimated	
					format "%\n" rotationXChannelString to:saveForAEFileAnimated	
					format "%\n" rotationYChannelString to:saveForAEFileAnimated	
					)else()
					
				if checkboxFOV.checked == true then
					(
					--format "%\n" "FOV CHECK" to:saveForAEFileAnimated	
					)else()
					
				 ------ CREATE FOOTER DATA and WRITE FILE TO DISK-----------
				format "%\n" footerText to:saveForAEFileAnimated	
				close saveForAEFileAnimated
				 
				 -------- RESET TIMELINE and VIEWS ---------------
				delete readerPoint
				animationRange = oldAnimationRange 
				SliderTime = oldSliderTime
				redraw = on
				enableSceneRedraw()
				redrawViews()
				 
				 ------ OPEN FILE -----------
				shelllaunch "notepad.exe" saveForAEFileAnimatedName
				
			)else(messagebox"Select 1 object")
		)catch(messagebox "unhandled exception, sorry! :D")
		lab1.text = "Status: Completed"
		)	
)-- end rollout

rollout settingsRollout "Settings and Information" 
(
	groupbox groupboxCustomFormatting "Custom Formatting" pos:[5,5] width:151 height:40
	button buttonCustomHeadder "Headder" pos:[10,20] width:70
	button buttonCustomFooter "Footer" pos:[80,20] width:70
	
	hyperLink aaronDabelow "© 2012  Aaron Dabelow" address:"http://aarondabelow.com/" pos: [7,53]
	button informationButton "?"  width: 20 height:20 pos: [136,50]
	
	on buttonCustomHeadder pressed do 
	(
		rollout customHeadderRollout "Set custom keframe data headder"
		(
		editText editTextHeadder width:300 height:150 text:headderText pos:[5,8]
		button acceptButton "accept" pos:[210,160]
		button cancelButton "cancel" pos:[259,160]
			
		on acceptButton pressed do
			(
			headderText = editTextHeadder.text
			try (destroydialog customHeadderRollout) catch()
			)
			
		on cancelButton pressed do 
			(
			try (destroydialog customHeadderRollout) catch()
			)
		)
		createDialog customHeadderRollout 315 185
	)
	
	on buttonCustomFooter pressed do
		(
		rollout customFooterRollout "Set custom keframe data Footer"
		(
		editText editTextFooter width:300 height:150 text:FooterText pos:[5,8]
		button acceptButton "accept" pos:[210,160]
		button cancelButton "cancel" pos:[259,160]
			
		on acceptButton pressed do
			(
			FooterText = editTextFooter.text
			try (destroydialog customFooterRollout) catch()
			)
			
		on cancelButton pressed do 
			(
			try (destroydialog customFooterRollout) catch()
			)
		)
		createDialog customFooterRollout 315 185
		)
			
		
	on informationButton pressed do
	(
		rollout InformationDialog "AE Position Exporter Info"
		(
		hyperLink DTBLink "AE Transforms Exporter v1.01  Help" address:"http://www.aarondabelow.com/v1/pages/maxscript/maxscript-afterFXtrans_exporter.html" align:#center
		label lab4 ""
		label lab5 "To Use 'Static ':" align:#left
		label lab19 ""
		label lab6 "(1)  Select object whose position you want."  align:#left
		label lab7 "      translated to Adobe After Effects space."  align:#left
		label lab8 "(2)  Choose your export method to AE as"align:#left
		label lab9 "      data to be pasted from clipboard, or as"align:#left
		label lab10 "      a .txt file to be copied and pasted or" align:#left
		label lab11 "      shared." align:#left
		label lab12 ""
		label lab13 "To Use 'Animated ':" align:#left
		label lab14 ""
		label lab15 "(1)  Select object with the floater." align:#left
		label lab16 "(2)  Set your desired range to export." align:#left
		label lab17 "(3)  Push the 'Export Animated Position'" align:#left
		label lab18 "      and set your export location." align:#left
		label lab22 "(4)  Open the saved .txt file, and copy" align:#left
		label lab23 "      and paste its contents into AE" align:#left
		label lab24 ""
		hyperLink aaronDabelow "Aaron Dabelow" address:"http://aarondabelow.com/" align:#center
		label lab21 "theonlyaaron@gmail.com"
		)
	createDialog InformationDialog 225 410
	)
)

(
global AETransformsExporter=newrolloutfloater "AE Transforms Exporter" 175 472 
addrollout StaticPositionExporter AETransformsExporter
addrollout AnimatedPositionsExporter AETransformsExporter
addrollout settingsRollout AETransformsExporter
)
