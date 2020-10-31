Select peripheral 1 (mouse/keyboard)
+
>
Mode 1 (get mouse pos)
+
>
For selecting peripheral 2 (screen)
++
Skip over the 2 spaces where mouse pos will be read into
>>>
255 255 255 for white (relies on 8bit underflow)
->->-
Move back to initial memory pos
<<<<<<<
Enter input loop
[
	Execute: select peripheral 1 and mode 1
	.>.>
	Move over and read mouse pos into designated spots 
	>,>,
	Move back to the select peripheral 2 command
	<<
	Output everything which should select the screen and draw mouse pos as a point to the screen
	.>.>.>.>.>.
	Move back to initial memory pos to select peripheral 1
	<<<<<<<
]