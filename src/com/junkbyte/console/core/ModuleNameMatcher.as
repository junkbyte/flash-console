package com.junkbyte.console.core
{
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.interfaces.IConsoleModuleMatcher;

	public class ModuleNameMatcher implements IConsoleModuleMatcher
	{
		protected var name:String;
		
		public function ModuleNameMatcher(name:String):void
		{
			this.name = name;
		}
		
		public function matches(module:IConsoleModule):Boolean
		{
			return module.getModuleName() == name;
		}
	}
}