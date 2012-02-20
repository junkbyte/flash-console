#summary Read me and Changes log.
#labels Phase-Requirements


= READ ME =

==Flash Console==

  * Version 2.6 (Feb 2012)
  * Project home page: http://code.google.com/p/flash-console/
  * Author: Lu Aye Oo, http://www.junkbyte.com
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
  * Icon by Nick Holliday


== Change Log ==

===2.6 ===
  * Addons are now included in Console.swc
  * DisplayMap addon, Allows inspecting of display tree
  * Removed Cc.remotingPassword. use Cc.config.remotingPassword (should be set before starting remote)
  * Basic timestamp display support. Use Cc.config.showTimestamp = true;
  * Line number display support. Use Cc.config.showLineNumber = true;
  * Key binds allow for key down or key up state
  * Multi line top menu
  * Support for delete operation in commandLine
  * Fixed Issue 90. UTF8 chars failing to send to remote
  
===2.52 ===
  * Multi-line support with slash commands. E.g. "/base; /explode" will now work
  * Added config.commandLineInputPassThrough which allows replacing command input execution
  * Fixed bug: Issue 82, No output when selecting Unlimited 'maxLines'
  * Fixed bug: Issue 84: Cc.visible doesn't work if user already closed console via X button
  * Fix where slash command auto complete was adding blank argument
  
===2.51 ===
  * Major changes
   * HTML formatted logging support. see Cc.addHTML, Cc.addHTMLch
   * Socket remoting support
   * Extensive changes were made on remoting. Older remotes will not work with this version
   * Improved commandLine autocomplete / hinting
    * CommandLine autocomplete is now stepped so that it will stop completion at multiple matches
    * TAB key to accept autocomplete suggestion in CL (in REPLACEMENT of previous SPACE key)
   * Cc.config.rememberFilterSettings to remember channel and priority level settings as SharedObject
  * Minor changes
   * *Cc* button on top menu changed to *Sv* with additional controls:
    * Normal click copies all text with channel names to clipboard
    * Shift click copies text without channel names
    * Ctrl click copies using current filtering (channels, priority level)
    * Alt click prompts a save dialog on flash player 10 or above
    * Keys can be combiled. Example:
     * Ctrl+alt+shift click will open a dialog to save logs without channel names using current filters
   * Cc.setIgnoredChannels() to set ignored channels
   * Ctrl click on channel name now use setIgnoredChannels which function slightly differently than it used to
   * SHIFT+scroll wheel to make log text bigger / smaller
   * Reintroduced Cc.minimumPriority
   * TAB key focuses to command line if visible (in addition to previous ENTER key)
   * SWC now include argument names. However it will no longer support importing in CS3 as a component
  * Bug fixes
   * Fixed not sending very long lines to remote
   * ByteArray.toString() no longer brake console prints
   * Fixed issue where single Number/int logs to Cc.add, Cc.stack,Cc.stackch, Cc.ch doesn't work

===2.5 ===
  * Features
   * *Object linking* where you can click on an object in the log to inspect or get scope for commandline
   * *Custom slash commands* use Cc.addSlashCommand(...);
   * *Custom top menu* use Cc.addMenu(...) to add your own menu on top
   * *Commandline hinting* suggests possible first words. Press space to accept suggestion.
   * */filter* and */filterexp* will also underline matching strings
   * *Magnification* in ruler tool
  * Major changes
   * You must set Cc.config.commandLineAllowed = true; to be able to use full commandline features
   * Commandline can set to visible even if Cc.config.commandLineAllowed is set to false so that /filter and /filterexp is available
   * Cc.stack() no longer accept channel name. use Cc.stackch() for channel
   * Key bindings and password will not trigger if you have focus on an input textfield
   * Removed Cc.viewingChannel. use Cc.setViewingChannel to set
   * Removed Cc.paused. If you want to pause, press P in top menu
   * Removed Cc.remote as it is a special use case
   * Removed Cc.setPanelArea, Cc.commandBase and Cc.runCommand for simplicity
   * Console will no longer trace about Cc.keybind, Cc.store and Cc.watch. Due to this, Cc.quiet is removed
   * Remoting now use ByteArray data format which will break older clients but is faster and more efficent
  * Minor changes
   * Clicking on the priority filter *P0* will skip priorities that are not used. Shift click to go backwards
   * Ctrl click on channel name to invert select. (shift click to multi select as used to)
   * Top menu can now be minimized from UI OR Cc.config.style.topMenu = false;
   * Remote: to run local command line on remote, prefix string with ~, e.g. `~stage.frameRate=100;`
   * Remote: /filter and /filterexp will now do the filtering on remote rather than sending the command to client
   * Classes now get a `*` around the name to signify that its a class and not an instance of a class. eg. `*Sprite*`
   * Added `Cc.explodech()` to output explode to channel
   * Added `Cc.inspectch()` to output inspects to channel
   * Added `Cc.mapch()` to output map to channel
   * Added `Cc.config.keyBindsEnabled` - to be able to disable all keybinds
   * Added `Cc.config.displayRollerEnabled` - to be able to disable display roller to increase security
   * Pressing Enter while console is visible will auto focus to commandLine
   * added /commands command to list all slash commands
   * added /keybinds command to list all used key binds
   * commandLine autoScoping can be set from Cc.config.commandLineAutoScope
   * You can no longer change the name of global/console/default/filtered channels through Cc.config
   * Simplied sourcecode where possible while keeping compile size down
   * Merged some classes and functions to further reduce compile size
  * Bug fixes
   * Channel name generation from non-string param in Cc.logch, Cc.warnch, etc...
   * Not being able to keep selection while scrolling up. You may sometimes still have problem selecting while scrolling down
   * After dragging the main panel outside screen, it will snap back to view if you toggle it by entering the password
   * Fixed memory leak from deleted logs
   * Cc.config.maxRepeats is now int so that you can set -1
   * Fixed bug where inspecting Dictionary would always print undefined value to those that use non-string key
   * Fixed where logging QName causes error on previous 2.5 beta versions
   * Fixed where clicking on global channel changes to default channel instead on previous 2.5 beta versions

===2.4===
  * Renamed source package name to com.junkbyte.console - to be less personal
  * Renamed C to Cc so that FlashBuilder pick up as auto complete. Cc stands for Console controller.
  * Moved a lot of 'configuration' settings from Cc. to ConsoleConfig (that you pass at start)
  * Moved a lot of 'style' settings from Cc. to ConsoleStyle (that you modify using ConsoleConfig.style)
  * Due to security concern, CommandLine is no longer allowed by default. You must do ConsoleConfig.commandLineAllowed = true OR Cc.commandLine = true (to allow and show)
  * CommandLine: no longer auto scope to new return. Enter '/' to change scope to last returned object. Turn on auto-scoping by typing /autoscope
  * Added Cc.listenUncaughtErrors, which log global errors in flash player 10.1 or above.
  * Very long lines are automatically split before displaying to increase speed
  * Custom graphing is now passed into remote.
  * Added Cc.explode
  * Added Cc.stack
  * Added Cc.autoStackPriority and defaultStackDepth in ConsoleConfig
  * Cc.fatal will get auto stack trace by default.
  * External trace call will have channel name as first param, log line as second param and priority as third
  * Removed tracingPriorty, prefixChannelNames, tracingChannels
  * Removed Cc.filterText and Cc.filterRegExp - use /filter in interface
  * Removed Cc.gc() - use memoryMonitor - G button in interface.
  * Removed Cc.remoteDelay. it is now always 1.
  * Fixed bug with not being able to access array indexes.
  * Fixed bug with not sending too many log lines in remoting.

===2.35===
  * Removed /strong AND C.strongRef. Must now use /savestrong individually.
  * Added ConsoleStyle which can be passed in at start to define console styles
  * /filterexp regular expression text filtering
  * C.viewingChannel no longer used. now only using C.viewingChannels
  * Graphing param can now be a command line string
  * Minor bug fixes with command line


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