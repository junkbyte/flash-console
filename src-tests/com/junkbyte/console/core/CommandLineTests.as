package com.junkbyte.console.core
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	
	import org.flexunit.asserts.assertEquals;

	public class CommandLineTests
	{
		
		private var console:Console;
		private var commandLine:CommandLine;
		
		[Before]
		public function setUp():void
		{
			console = new Console();
			console.config.commandLineAllowed = true;
			
			commandLine = console.cl;
			commandLine.base = this;
		}
		
		private function run(str:String, saves:Object = null):*
		{
			return commandLine.run(str, saves);
		}
		
		[Test]
		public function testBasicCommands():void
		{
			assertEquals(this, run("this"));
			assertEquals(console, run("$C"));
		}
		
		[Test]
		public function testChangecope():void
		{
			assertEquals(this, run("this"));
			run("$C");
			run("/");
			assertEquals(console, run("this"));
		}
		
		[Test]
		public function testBasicMultilineCommands():void
		{
			assertEquals(this, run("this;$C ; $base ")); // just tests that it returns the last value
			assertEquals(console, run("$C; /; this"));
		}
		
		[Test]
		public function testChangePreviousScope():void
		{
			run("$C;/;");
			run("//");
			assertEquals(this, run("this"));
		}
		
		[Test]
		public function testSaveSlashCommand():void
		{
			run("$C;/;");
			run("/save console");
			assertEquals(console, run("$console"));
		}
		
		[Test]
		public function testSlashCommandMatching():void
		{
			console.addSlashCommand("test", function (param:String = ""):String{return "test:"+param;});
			console.addSlashCommand("test 2", function (param:String = ""):String{return "test 2:"+param;});
			console.addSlashCommand("test 23", function (param:String = ""):String{return "test 23:"+param;});
			console.addSlashCommand("test 3", function (param:String = ""):String{return "test 3:"+param;});
			
			assertEquals(undefined, run("/doNotExist"));
			
			assertEquals("test:", run("/test"));
			assertEquals("test:", run("/test "));
			
			assertEquals("test:abcd", run("/test abcd"));
			assertEquals("test: abcd", run("/test  abcd"));
			
			assertEquals("test 2:", run("/test 2"));
			assertEquals("test 2:", run("/test 2 "));
			assertEquals("test 2:abcd", run("/test 2 abcd"));
			assertEquals("test 23:", run("/test 23 "));
			assertEquals("test 23:abcd", run("/test 23 abcd"));
			assertEquals("test 3:abcd", run("/test 3 abcd"));
		}
	}
}