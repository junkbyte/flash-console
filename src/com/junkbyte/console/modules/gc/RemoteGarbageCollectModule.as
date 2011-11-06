package com.junkbyte.console.modules.gc
{
    import com.junkbyte.console.ConsoleLevel;
    import com.junkbyte.console.core.ConsoleModule;
    import com.junkbyte.console.interfaces.IConsoleOnDemandModule;
    import com.junkbyte.console.interfaces.IRemoter;
    import com.junkbyte.console.modules.ConsoleModuleNames;

    public class RemoteGarbageCollectModule extends ConsoleModule implements IConsoleOnDemandModule
    {
		
        public function RemoteGarbageCollectModule()
        {
            super();
        }

        override public function getModuleName():String
        {
            return ConsoleModuleNames.GARBAGE_COLLECTOR;
        }

        public function run(params:* = null):void
        {
            try
			{
				var remoter:IRemoter = modules.getModuleByName(ConsoleModuleNames.REMOTING);
				// report("Sending garbage collection request to client",-1);
				remoter.send("gc");
			}
			catch (e:Error)
			{
				report(e, ConsoleLevel.ERROR);
            }
        }
    }
}
