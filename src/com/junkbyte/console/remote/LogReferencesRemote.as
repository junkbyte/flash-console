package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.LogReferences;
	
	import flash.utils.ByteArray;
	
	public class LogReferencesRemote extends LogReferences
	{
		public function LogReferencesRemote(console:Console)
		{
			super(console);
		}
		override public function handleRefEvent(str:String):void{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTF(str);
			remoter.send("ref", bytes);
		}
		override public function exitFocus():void{
			
		}
	}
}