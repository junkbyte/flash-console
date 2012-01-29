/*
*
* Copyright (c) 2008-2011 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
* http://junkbyte.com
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
package com.junkbyte.console.core
{
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.logging.ConsoleLogger;
	import com.junkbyte.console.logging.ConsoleLogs;
	import com.junkbyte.console.logging.ConsoleLogsFilter;
	import com.junkbyte.console.view.ChannelsPanel;
	import com.junkbyte.console.view.StageModule;
	import com.junkbyte.console.view.mainPanel.MainPanel;

	public class ConsoleCoreModulesMap
	{
		private static const NAME_TO_TYPE_MAP:Object = 
		{ 
			logger: ConsoleLogger, 
			logs: ConsoleLogs,
			stage: StageModule,
			mainPanel: MainPanel,
			channelsPanel: ChannelsPanel,
			logsFilter: ConsoleLogsFilter
		};
		
		public static function isModuleWithNameValid(module:IConsoleModule, name:String):Boolean
		{
			var type:Class = NAME_TO_TYPE_MAP[name];
			return type == null || module is type;
		}
	}
}