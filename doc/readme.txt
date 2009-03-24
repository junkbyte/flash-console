You can find a copy of this file at project wiki:
http://code.google.com/p/flash-console/w/list

#summary Read me and Changes log.


= READ ME =

==Flash Console==

  * Version: 2.02 (Mar 2009)
  * Project home page: http://code.google.com/p/flash-console/
  * Author: Lu Aye Oo

  * Required: `ActionScript 3.0`, Flash player 9 or above
  * Authoring: Flash, Flex or AIR


NOTE: To use in flex or AIR, you need to pass in a UIImage (which is somewhere on stage) as console's base display. Passing in document class or stage does not work in Flex, for some reason. - will be looked at very soon.
---- 

==Short description==
Console is an as3 logger, debugger which runs inside the flash app.
Features include: priorities, channels, FPS display, memory/garbage collection monitor, remote logging, non-repeative tracing, ruler tool, display mapping, and many more!


== Change Log ==
===1.02===
  * *Multiple channel selections*: At run time holding down shift key or in code pass with comma delimiters, such as `C.viewingChannel = "shell,game";`
  * *Strong referencing*: Now you can set console to work in strong referencing. In command line type `/strong true` or in code. `C.strongRef = true;` This is useful when you are trying to store objects that will not persist for the time you need to debug with. But be careful as these items will not get garbage collected.
  * *Improved auto-scroll*: While you have scrolled up from the bottom of log, it will no longer auto-scroll back to the bottom when new log line is added. A red line flashes at the bottom everytime there is a new line.


===1.0===
  * *First stable version*
  * Have known problems with commandLine