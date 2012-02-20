/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
*/
package com.junkbyte.console.addons.displaymap
{
    import com.junkbyte.console.Cc;
    import com.junkbyte.console.Console;
    import com.junkbyte.console.view.ConsolePanel;
    
    import flash.display.DisplayObject;
	
	/**
	 * Display tree mapping panel addon
	 * 
	 * <ul>
	 * <li>Displays a panel mapping the display tree/map.</li>
	 * <li>Start from code: DisplayMapAddon.start();</li>
	 * <li>Add to menu: DisplayMapAddon.addToMenu();</li>
	 * <li>Register to commandLine: DisplayMapAddon.registerCommand(); use /mapdisplay, starts mapping from current command scope.</li>
	 * </ul>
	 */
    public class DisplayMapAddon
    {
		/**
		 * Start DisplayMapAddon
		 * 
		 * @param startingContainer Starting DisplayObject to map.
		 * @param console Instance to Console. You do not need to pass this param if you use Cc.
		 */
        public static function start(targetDisplay:DisplayObject, console:Console = null):DisplayMapPanel
        {
            if (console == null)
            {
                console = Cc.instance;
            }
            if (console == null)
            {
                return null;
            }
            var mapPanel:DisplayMapPanel = new DisplayMapPanel(console);
            mapPanel.start(targetDisplay);
            console.panels.addPanel(mapPanel);
			return mapPanel;
        }
		
		/**
		 * Register DisplayMapAddon to console slash command.
		 * 
		 * @param commandName Command name to trigger. Default = 'mapdisplay'
		 * @param console Instance to Console. You do not need to pass this param if you use Cc.
		 */
        public static function registerCommand(commandName:String = "mapdisplay", console:Console = null):void
        {
            if (console == null)
            {
                console = Cc.instance;
            }
            if (console == null || commandName == null)
            {
                return;
            }

            var callbackFunction:Function = function(... arguments:Array):void
            {
                var scope:* = console.cl.run("this");
                if (scope is DisplayObject)
                {
                    start(scope as DisplayObject, console);
                }
                else
                {
                    console.error("Current scope", scope, "is not a DisplayObject.");
                }
            }
            console.addSlashCommand(commandName, callbackFunction);
        }
		
		
		/**
		 * Add DisplayMapAddon to console top menu.
		 * 
		 * @param menuName Name of menu. Default = 'DM'
		 * @param startingContainer Starting DisplayObject to map. When null, it uses console's parent display.
		 * @param console Instance to Console. You do not need to pass this param if you use Cc.
		 */
        public static function addToMenu(menuName:String = "DM", startingContainer:DisplayObject = null, console:Console = null):void
        {
            if (console == null)
            {
                console = Cc.instance;
            }
            if (console == null || menuName == null)
            {
                return;
            }
			
            var callbackFunction:Function = function():void
            {
				var panel:DisplayMapPanel = console.panels.getPanel(DisplayMapPanel.NAME) as DisplayMapPanel;
				if(panel)
				{
					panel.close();
				}
				else
				{
					if(startingContainer == null)
					{
						startingContainer = console.parent;
					}
					panel = start(startingContainer);
					panel.x = console.mouseX - panel.width * 0.5;
					panel.y = console.mouseY + 10;
				}
            }
            console.addMenu(menuName, callbackFunction);
        }
    }
}
