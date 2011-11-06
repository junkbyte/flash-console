package com.junkbyte.console.tests
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertTrue;

	public class ConsoleModulesTest
	{		
		
		public var console:Console;
		
		[Before]
		public function setUp():void
		{
			console = new Console();
			console.start();
		}
		
		public function get modules():ConsoleModulesManager
		{
			return console.modules;
		}
		
		[Test]
		public function registerModuleTest():void
		{
			var module:ConsoleModule = new ConsoleModule();
			modules.registerModule(module);
			
			assertTrue(modules.isModuleRegistered(module));
			
			modules.unregisterModule(module);
		}
		
		[Test]
		public function registerModulesTest():void
		{
			var module:ConsoleModule = new ConsoleModule();
			var module2:ConsoleModule = new ConsoleModule();
			
			modules.registerModules(Vector.<IConsoleModule>([module, module2]));
			
			assertTrue(modules.isModuleRegistered(module));
			assertTrue(modules.isModuleRegistered(module2));
			
			modules.unregisterModule(module);
			modules.unregisterModule(module2);
		}
		
		[Test]
		public function unregisterModuleTest():void
		{
			var module:ConsoleModule = new ConsoleModule();
			modules.registerModule(module);
			
			modules.unregisterModule(module);
			
			assertFalse(modules.isModuleRegistered(module));
		}
		
		[Test]
		public function namedModuleCanBeFound():void
		{
			var namedModule:FakeNamedModule = new FakeNamedModule();
			modules.registerModule(namedModule);
			
			assertEquals(namedModule, modules.getModuleByName("fakeModule"));
			
			modules.unregisterModule(namedModule);
		}
		
		[Test]
		public function namedModuleReplacesPreviousSameNameModule():void
		{
			var namedModule:FakeNamedModule = new FakeNamedModule();
			var namedModule2:FakeNamedModule = new FakeNamedModule();
			
			modules.registerModules(Vector.<IConsoleModule>([namedModule, namedModule2]));
			
			assertTrue(modules.isModuleRegistered(namedModule2));
			assertFalse(modules.isModuleRegistered(namedModule));
			assertEquals(namedModule2, modules.getModuleByName("fakeModule"));
			
			modules.unregisterModule(namedModule);
			modules.unregisterModule(namedModule2);
		}
		
		[Test]
		public function registeredModulesCanBeFoundUsingTypeSearch():void
		{
			var module:FakeModule = new FakeModule();
			var module2:FakeModule = new FakeModule();
			var module3:FakeModule = new FakeModule();
			
			modules.registerModules(Vector.<IConsoleModule>([module, module2, module3]));
			
			var matches:Vector.<IConsoleModule> = modules.findModulesByMatcher(ConsoleModuleMatch.createForClass(FakeModule));
			
			assertEquals(3, matches.length);
			assertEquals(matches[0], module);
			assertEquals(matches[1], module2);
			assertEquals(matches[2], module3);
			
			modules.unregisterModule(module);
			modules.unregisterModule(module2);
			modules.unregisterModule(module3);
		}
		
		[Test]
		public function getFirstMatchingModuleReturnsFirstRegisteredModule():void
		{
			var module:FakeModule = new FakeModule();
			var module2:FakeModule = new FakeModule();
			
			modules.registerModules(Vector.<IConsoleModule>([module, module2]));
			
			var match:IConsoleModule = modules.getFirstMatchingModule(ConsoleModuleMatch.createForClass(FakeModule));
			
			assertEquals(module, match);
			
			modules.unregisterModule(module);
			modules.unregisterModule(module2);
		}
	}
}
import com.junkbyte.console.core.ConsoleModule;
class FakeModule extends ConsoleModule
{
	public function FakeModule():void
	{
		
	}
}

import com.junkbyte.console.core.ConsoleModule;
class FakeNamedModule extends ConsoleModule
{
	public function FakeNamedModule():void
	{
		
	}
	
	
	override public function getModuleName():String
	{
		return "fakeModule";
	}
}