extends VBoxContainer

var info : Dictionary : set = setInfo


func setInfo(i):
	info = i
	%AnimationName.text = i["animName"]
	%FrameCount.text = str(i["frame count"])
	
	if i["isCompressed"]:
		%IsCompressed.text = "yes"
	else:
		%IsCompressed.text = "no"
		
		
	%FirstFrameOffset.text = EGLO.intToHex(i["frameOffset"])
	%FrameSize.text = str(i["frameSize"])
	
