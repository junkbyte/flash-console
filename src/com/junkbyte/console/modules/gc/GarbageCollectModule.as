package com.junkbyte.console.modules.gc
{
    import com.junkbyte.console.ConsoleLevel;
    import com.junkbyte.console.core.ConsoleModule;
    import com.junkbyte.console.interfaces.IConsoleOnDemandModule;
    import com.junkbyte.console.modules.ConsoleModuleNames;
    
    import flash.system.System;

    public class GarbageCollectModule extends ConsoleModule implements IConsoleOnDemandModule
    {
		
        public function GarbageCollectModule()
        {
            super();
        }

        override public function getModuleName():String
        {
            return ConsoleModuleNames.GARBAGE_COLLECTOR;
        }

        public function run(params:* = null):void
        {
            var ok:Boolean = false;
			try
			{
				// have to put in brackes cause some compilers will complain.
				System["gc"]();
				ok = true;
			}
			catch (e:Error)
			{
			}
			var str:String = "Manual garbage collection " + (ok ? "successful." : "FAILED. You need debugger version of flash player.");
			report(str, (ok ? ConsoleLevel.CONSOLE_STATUS : ConsoleLevel.ERROR));
        }
    }
}
