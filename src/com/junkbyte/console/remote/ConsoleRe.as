package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.core.CommandLine;
	import com.junkbyte.console.core.ConsoleTools;
	import com.junkbyte.console.core.KeyBinder;
	import com.junkbyte.console.core.LogReferences;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.core.MemoryMonitor;
	import com.junkbyte.console.core.Remoting;

	public class ConsoleRe extends Console
	{
		public function ConsoleRe(password:String = "", config:ConsoleConfig = null)
		{
			super(password, config);
			
			_config.displayRollerEnabled = false;
		}

		override protected function initModules():void
		{
			_remoter = new RemotingRemote(this);
			_logs = new LogsRemote(this);
			_refs = new LogReferencesRemote(this);
			_cl = new CommandLineRemote(this);
			_tools = new ConsoleTools(this);
			_graphing = new GraphingRemote(this);
			_mm = new MemoryMonitorRemote(this);
			_kb = new KeyBinder(this);
			
			_panels = new PanelsManagerRemote(this);
		}
	}
}
