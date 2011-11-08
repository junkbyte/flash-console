package com.junkbyte.console.core
{
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IConsoleModuleMatcher;

	public class ModuleTypeMatcher implements IConsoleModuleMatcher
	{
		protected var type:Class;
		
		public function ModuleTypeMatcher(type:Class):void
		{
			this.type = type;
		}
		
		public function matches(module:IConsoleModule):Boolean
		{
			return type != null && module is type;
		}
	}
}