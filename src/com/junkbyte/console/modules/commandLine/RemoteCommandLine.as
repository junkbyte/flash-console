package com.junkbyte.console.modules.commandLine
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.interfaces.IRemoter;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	
	import flash.utils.ByteArray;
	
	public class RemoteCommandLine extends SlashCommandLine implements ICommandLine
	{
		
		public var localCommands:Array = new Array("filter", "filterexp");
		
		public function RemoteCommandLine()
		{
			super();
		}
		
		public function get scopeString():String
		{
			return null;
		}
		
		public function run(str:String, params:*=null):*
		{
			if (!str)
				return;
			
			var remoter:IRemoter = modules.getModuleByName(ConsoleModuleNames.REMOTING) as IRemoter;
			if (getRemoter() != null)
			{
				if (str.charAt(0) == "~")
				{
					str = str.substring(1);
				}
				else if (str.search(new RegExp("\/" + localCommands.join("|\/"))) != 0)
				{
					report("Run command at remote: " + str, -2);
					
					var bytes:ByteArray = new ByteArray();
					bytes.writeUTF(str);
					if (!getRemoter().send("cmd", bytes))
					{
						report("Command could not be sent to client.", 10);
					}
					return null;
				}
			}
			return super.run(str, params);
		}
		
		protected function getRemoter():IRemoter
		{
			return modules.getModuleByName(ConsoleModuleNames.REMOTING);
		}
	}
}