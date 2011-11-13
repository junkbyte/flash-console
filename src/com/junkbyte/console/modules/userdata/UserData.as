package com.junkbyte.console.modules.userdata
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	
	import flash.net.SharedObject;

	public class UserData extends ConsoleModule implements IConsoleUserData
	{
		/** 
		 * Local shared object used for storing user data such as command line history
		 * Set to null to disable storing to local shared object.
		 */
		public var sharedObjectName:String = "com.junkbyte/Console/UserData";
		
		/** Local shared object path */
		public var sharedObjectPath:String = "/";
		
		
		private var _so:SharedObject;
		private var _soData:Object = {};
		
		public function UserData()
		{
			
		}
		
		override public function getModuleName():String
		{
			return ConsoleModuleNames.USER_INFO;
		}
		
		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			
			if (sharedObjectName)
			{
				try
				{
					_so = SharedObject.getLocal(sharedObjectName, sharedObjectPath);
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