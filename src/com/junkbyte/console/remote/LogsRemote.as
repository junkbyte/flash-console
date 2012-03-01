package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.vos.Log;

	import flash.utils.ByteArray;

	public class LogsRemote extends Logs
	{
		public function LogsRemote(console:Console)
		{
			super(console);
			remoter.registerCallback("log", onRemotingLog);
		}
		
		private function onRemotingLog(bytes:ByteArray):void
		{
			registerLog(Log.FromBytes(bytes));
		}
		override protected function send2Remote(line:Log):void{
			
		}
	}
}
