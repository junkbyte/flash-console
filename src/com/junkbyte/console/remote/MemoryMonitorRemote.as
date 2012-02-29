package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.MemoryMonitor;
	
	public class MemoryMonitorRemote extends MemoryMonitor
	{
		public function MemoryMonitorRemote(m:Console)
		{
			super(m);
		}
		
		override public function gc():void {
			try{
				report("Sending garbage collection request to client",-1);
				remoter.send("gc");
			}catch(e:Error){
				report(e,10);
			}
		}
	}
}