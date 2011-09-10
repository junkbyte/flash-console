package com.junkbyte.console.modules.userdata
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	
	import flash.net.SharedObject;

	public class UserData extends ConsoleModule implements IConsoleUserData
	{
		private var _so:SharedObject;
		private var _soData:Object = {};
		
		public function UserData()
		{
			
		}
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.USER_INFO;
		}
		
		override public function registeredToConsole(console:Console):void
		{
			super.registeredToConsole(console);
			
			if (config.sharedObjectName)
			{
				try
				{
					_so = SharedObject.getLocal(config.sharedObjectName, config.sharedObjectPath);
					_soData = _so.data;
				}
				catch(e:Error)
				{
					
				}
			}
		}
		
		public function get data():Object
		{
			return _soData;
		}
		
		public function updateData(key:String = null):void
		{
			if (_so)
			{
				if (key) _so.setDirty(key);
				else _so.clear();
			}
		}
		
		
	}
}