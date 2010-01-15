#summary Read me and Changes log.


= READ ME =

==Flash Console==

  * Version: 2.31 (Jan 2010)
  * Project home page: http://code.google.com/p/flash-console/
  * Author: Lu Aye Oo, http://www.luaye.com
  * Required: `ActionScript 3.0`, Flash player 9 or above
  * Authoring: Flash, Flex or AIR

---- 


==Short description==
Console is an as3 logger, debugger which runs inside the flash app.
Features include: priorities, channels, FPS display, memory/garbage collection monitor, graphing, remote logging, non-repeative tracing, ruler tool, display mapping, and many more!


==Known issues/bugs==
Please see project issues page for latest bugs and features requests.
http://code.google.com/p/flash-console/issues/


== Credits ==
  * Created by Lu Aye Oo
  * Logo by Nick Holliday
  * Special thanks to Joe Nash


== Change Log ==

===2.31===
  * Added support for additional commandline operations, such as + - & | ^ += ,etc
  * CommandLine should now try to execute `AS3` namespaced methods such as ones in XML (E4X) 
  * Added commandLine syntax such as /savestrong /scope. type /help in commandline for info.


===2.3===
  * console source package renamed to com.luaye.console.
  * memoryMonitor and fpsMonitor setters are now Boolean (used to be int)
  * Added Ch functionality where you can create instances of console channel.
  * Performace increase in terms of log lines management.
  * Added 'copy to clipboard' button on top menu.
  * Added 'save to file' button on top menu of AIR remote.
  * Removed 'disallowBrowser' setting from C.start and C.startOnStage.


===2.2===
  * Remote console now ask for password (older remotes will fail to work with new console clients)
  * commandline no longer have permission levels - just enable or disable.
  * Much faster logs update
  * Scroll bar for logs


===2.12===
  * Major discovery with untrusted local sandboxing in Remoting. Now shows a warning and how to work around the sandbox.


===2.11===
  * You can now create new instances in commandLine. for example `new flash.display.Sprite()`
  * Added `commandLinePermission` - security feature to disallow changing Security sensitive settings through commandLine.
  * Improved `inspect`
  * Minor fix on commandLine bug.
  * New Icon by Nick Holiday


===2.1===
  * commandLine should now execute commands in a much better way with less restrictions (such as nested functions, long strings in quotations, etc)
  * Minior updates and fixes to increase speed in view/panels
  * Remote AIR console added
  * Improvements in remote


===2.0===
  * MAJOR revamp to interface and code structure.
  * Added C.startOnStage() which should be an easier way to use Console in flex.
  * Features such as fpsMonitor and MemoryMonitor are now independent panels.
  * Graphing feature added.
  * Minor C. accessor name changes, such as isRemote to remote, fpsMode to fpsMonitor.
  * Console logs will no longer render HTML, it will appear as plain text.
  * Improvements to command line such as /string - string block adding and more stable display mapping.


===1.15===
  * `C.inspect(...)` or commandline: `/inspect` should now also print 'variables' of the object.
  * Fixed bug with ignoring HTML tags - still not perfect.
  * DisplayRoller now look from stage no matter where console sits.
  * Included console in SWC file
  * Remote and Remoter now print their sandbox type so that you can try match local/network sandbox, they won't log if you are on different sandbox.


===1.11===
  * Major bug fix with not tracing /inspect and other HTML prints. - still HTML safe checking is not perfect yet.


===1.1===
  * *DisplayRoller (Ro)*: Shows you the display map under your mouse as you roll around - when turned on.
  * *Ruler (Ru)*: Improved ruller tool. Press Ru at menu to use.
  * Fixed bug with not printing HTML/XML traces properly.


===1.02===
  * *Multiple channel selections*: At run time holding down shift key or in code pass with comma delimiters, such as `C.viewingChannel = "shell,game";`
  * *Strong referencing*: Now you can set console to work in strong referencing. In command line type `/strong true` or in code. `C.strongRef = true;` This is useful when you are trying to store objects that will not persist for the time you need to debug with. But be careful as these items will not get garbage collected.
  * *Improved auto-scroll*: While you have scrolled up from the bottom of log, it will no longer auto-scroll back to the bottom when new log line is added. A red line flashes at the bottom everytime there is a new line.


===1.0===
  * *First stable version*
  * Have known problems with commandLine