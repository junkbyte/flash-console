package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.CommandLine;
	
	import flash.events.Event;
	import flash.utils.ByteArray;

	public class CommandLineRemote extends CommandLine
	{
		public function CommandLineRemote(m:Console)
		{
			super(m);
			remoter.registerCallback("cls", handleScopeString);
		}
		
		override public function sendCmdScope2Remote(e:Event = null):void{
		}
		override public function run(str:String, saves:Object = null, canThrowError:Boolean = false):*
		{
			if (!str)
			{
				return;
			}
			str = str.replace(/\s*/, "");

			if (str.charAt(0) == "~")
			{
				str = str.substring(1);
				super.run(str, saves);
			}
			else if (str.search(new RegExp("\/" + localCommands.join("|\/"))) != 0)
			{
				report("Run command at remote: " + str, -2);

				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF(str);
				if (!console.remoter.send("cmd", bytes))
				{
					report("Command could not be sent to client.", 10);
				}
			}
		}
		public function handleScopeString(bytes:ByteArray):void{
			_scopeStr = bytes.readUTF();
		}
		
		override public function handleScopeEvent(id:uint):void{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUnsignedInt(id);
			remoter.send("scope", bytes);
		}
	}
}
