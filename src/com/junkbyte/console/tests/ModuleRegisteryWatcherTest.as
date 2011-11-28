package com.junkbyte.console.tests
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModulesManager;
	import com.junkbyte.console.core.ModuleRegisteryWatcher;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.logging.ConsoleLogger;
	import com.junkbyte.console.logging.ConsoleLogs;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertTrue;
	import org.flexunit.async.Async;
	import org.flexunit.async.AsyncNativeTestResponder;

	public class ModuleRegisteryWatcherTest
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
		
		[Test(async)]
		public function registerModuleAfterAddingCallbackTest():void
		{
			var module:FakeModule = new FakeModule();
			
			var callback:Function = function(argument:IConsoleModule):void
			{
				assertEquals(module, argument);
			}
			var watcher:ModuleRegisteryWatcher = ModuleRegisteryWatcher.createUsingModulesManager(console.modules);
			watcher.addCallback(new ModuleTypeMatcher(FakeModule), createAsyncCallback(callback));
			
			modules.registerModule(module);
		}
		
		[Test(async)]
		public function unregisterModuleCallbackTest():void
		{
			var module:FakeModule = new FakeModule();
			modules.registerModule(module);
			
			var callback:Function = function(argument:IConsoleModule):void
			{
				assertEquals(module, argument);
			}
			var watcher:ModuleRegisteryWatcher = ModuleRegisteryWatcher.createUsingModulesManager(console.modules);
			watcher.addCallback(new ModuleTypeMatcher(FakeModule), null, createAsyncCallback(callback));
			
			modules.unregisterModule(module);
		}
		
		
		[Test(async)]
		public function registerModuleBeforeAddingCallbackTest():void
		{
			var module:FakeModule = new FakeModule();
			modules.registerModule(module);
			
			var callback:Function = function(argument:IConsoleModule):void
			{
				assertEquals(module, argument);
			}
			var watcher:ModuleRegisteryWatcher = ModuleRegisteryWatcher.createUsingModulesManager(console.modules);
			watcher.addCallback(new ModuleTypeMatcher(FakeModule), createAsyncCallback(callback));
		}
		
		[Test(async)]
		public function callbacksInOrderOfRegisteryTest():void
		{
			var module1:FakeModule = new FakeModule();
			modules.registerModule(module1);
			var module2:FakeModule = new FakeModule();
			modules.registerModule(module2);
			
			var callbackNumber:uint = 0;
			var callback:Function = function(argument:IConsoleModule):void
			{
				if(callbackNumber == 0)
				{
					assertEquals(module1, argument);
				}
				else
				{
					assertEquals(argument, module2);
				}
				callbackNumber++;
			}
			var watcher:ModuleRegisteryWatcher = ModuleRegisteryWatcher.createUsingModulesManager(console.modules);
			watcher.addCallback(new ModuleTypeMatcher(FakeModule), createAsyncCallback(callback));
		}
		
		[Test(async)]
		public function watcherWithModuleGettingCallbackOnRegister():void
		{
			var module:FakeModule = new FakeModule();
			var watcher:ModuleRegisteryWatcher = ModuleRegisteryWatcher.createUsingModule(module);
			watcher.addCallback(new ModuleTypeMatcher(ConsoleLogger), createAsyncCallback(moduleIsLogger));
			watcher.addCallback(new ModuleTypeMatcher(ConsoleLogs), createAsyncCallback(moduleIsConsoleLogs));
			modules.registerModule(module);
		}
		
		[Test(async)]
		public function watcherWithModuleGettingCallbackOnUnregister():void
		{
			var module:FakeModule = new FakeModule();
			modules.registerModule(module);
			var watcher:ModuleRegisteryWatcher = ModuleRegisteryWatcher.createUsingModule(module);
			watcher.addCallback(new ModuleTypeMatcher(ConsoleLogs), null, createAsyncCallback(moduleIsConsoleLogs));
			watcher.addCallback(new ModuleTypeMatcher(ConsoleLogger), null, createAsyncCallback(moduleIsLogger));
			modules.unregisterModule(module);
		}
		
		private function moduleIsLogger(argument:IConsoleModule):void
		{
			assertEquals(console.logger, argument);
		}
		
		private function moduleIsConsoleLogs(argument:IConsoleModule):void
		{
			assertEquals(console.logger.logs, argument);
		}
		
		private function createAsyncCallback(callback:Function):Function
		{
			var responder:AsyncNativeTestResponder = Async.asyncNativeResponder(this, callback, null, 100) as AsyncNativeTestResponder;
			return responder.result
		}
	}
}