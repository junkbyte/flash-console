package com.junkbyte.console.core
{
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	
	import flash.display.Sprite;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertStrictlyEquals;
	import org.flexunit.asserts.assertTrue;

	public class CommandLineTests
	{
		private var container:Sprite;
		private var console:Console;
		private var commandLine:CommandLine;
		private var saves:Object;
		
		[Before]
		public function setUp():void
		{
			console = new Console();
			console.config.commandLineAllowed = true;
			
			container = new Sprite();
			container.addChild(console);
			
			commandLine = console.cl;
			commandLine.base = this;
			
			saves = null;
		}
		
		private function run(str:String):*
		{
			return commandLine.run(str, saves, true);
		}
		
		[Test]
		public function testBasicCommands():void
		{
			// assertStrictlyEquals don't seem to pick up === cases.
			assertTrue(null === run("null"));
			assertTrue(undefined === run("undefined"));
			assertTrue(true === run("true"));
			assertTrue(false === run("false"));
			
			assertEquals(123, run("123"));
			assertEquals(123.456, run("123.456"));
			assertTrue(isNaN(run("NaN")));
			assertTrue(Infinity === run("Infinity"));
			
			var text:String = "Abcd \"EFG\" hijk";
			assertEquals(text, run("'"+text+"'"));
			text = "Abcd 'EFG' hijk";
			assertEquals(text, run("\""+text+"\""));
			
			assertEquals(this, run("this"));
			
			assertEquals(int, run("int"));
			assertEquals(Array, run("Array"));
			assertEquals(Function, run("Function"));
			assertEquals(XML, run("XML"));
			assertEquals(Sprite, run("flash.display.Sprite"));
			assertEquals(Cc, run("com.junkbyte.console.Cc"));
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
			//assertEquals(this, run("$C; /; /base")); // tests mixing slash commands in multiline
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