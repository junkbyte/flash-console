/*
* 
* Copyright (c) 2008-2010 Lu Aye Oo
* 
* @author 		Lu Aye Oo
* 
* http://code.google.com/p/flash-console/
* 
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
* 
*/
package com.junkbyte.console.core {
	import com.junkbyte.console.utils.ShortClassName;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.WeakObject;
	import com.junkbyte.console.vos.WeakRef;
	
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;import com.junkbyte.console.utils.CastToString;	

	public class CommandLine extends EventDispatcher {
		
		private static const INTSTACKS:int = 1; // max number of internal (commandLine) stack traces
		
		public static const BASE:String = "base";
		//public static const MONITORING_OBJ_KEY:String = "monitorObj";
		
		private static const RESERVED:Array = [Executer.RETURNED, BASE, "C"];
		
		private var _saved:WeakObject;
		
		private var _scope:*;
		private var _prevScope:WeakRef;
		
		private var _master:Console;
		private var _tools:CommandTools;
		private var _slashCmds:Object;
		
		public function CommandLine(m:Console) {
			_master = m;
			_tools = new CommandTools(report);
			_saved = new WeakObject();
			_scope = m;
			_slashCmds = new Object();
			_prevScope = new WeakRef(m);
			_saved.set("C", m);
			
			addCLCmd("help", _tools.printHelp, "How to use command line");
			addCLCmd("save|store", saveCmd, "Save current scope as weak reference. (same as Cc.store(...))");
			addCLCmd("savestrong|storestrong", saveStrongCmd, "Save current scope as strong reference");
			addCLCmd("saved|stored", savedCmd, "Show a list of all saved references");
			addCLCmd("string", stringCmd, "Create String, useful to paste complex strings without worrying about \" or \'");
			addCLCmd("commands", cmdsCmd, "Show a list of all slash commands");
			addCLCmd("filter", filterCmd, "Filter console logs to matching string. When done, click on the * (global channel) at top.");
			addCLCmd("filterexp", filterexpCmd, "Filter console logs to matching regular expression");
			addCLCmd("inspect", inspectCmd, "Inspect current scope");
			addCLCmd("inspectfull", inspectfullCmd, "Inspect current scope in detail");
			addCLCmd("explode", explodeCmd, "Explode current scope to its properties and values (similar to JSON)");
			addCLCmd("map", mapCmd, "Get display list map starting from current scope");
			addCLCmd("function", funCmd, "Create function. param is the commandline string to create as function. (experimental)");
			addCLCmd("autoscope", autoscopeCmd, "Toggle autoscoping.");
			addCLCmd("clearhistory", clearhisCmd, "Clear history of commands you have entered.");
			addCLCmd("base", baseCmd, "Return to base scope");
			
		}
		
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_prevScope.reference = _scope;
				_scope = obj;
				dispatchEvent(new Event(Event.CHANGE));
			}
			_saved.set(BASE, obj);
		}
		public function get base():Object {
			return _saved.get(BASE);
		}
		public function destory():void {
			_saved = null;
			_master = null;
			_tools = null;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void {
			// if it is a function it needs to be strong reference atm, 
			// otherwise it fails if the function passed is from a dynamic class/instance
			if(!n) {
				report("ERROR: Give a name to save.",10);
				return;
			}
			strong = (strong || obj is Function);
			n = n.replace(/[^\w]*/g, "");
			if(RESERVED.indexOf(n)>=0){
				report("ERROR: The name ["+n+"] is reserved",10);
				return;
			}else{
				_saved.set(n, obj, strong);
			}
			if(!_master.config.quiet){
				var str:String = strong?"STRONG":"WEAK";
				report("Stored <p5>$"+n+"</p5> for <b>"+getQualifiedClassName(obj)+"</b> using <b>"+ str +"</b> reference.",-1);
			}
		}
		public function get scopeString():String{
			return ShortClassName(_scope);
		}
		private function addCLCmd(n:String, callback:Function, desc:String):void{
			var split:Array = n.split("|");
			for(var i:int = 0; i<split.length; i++){
				n = split[i];
				_slashCmds[n] = new SlashCommand(n, callback, desc, false);
				if(i>0) _slashCmds.setPropertyIsEnumerable(n, false);
			}
		}
		public function addSlashCommand(n:String, callback:Function, desc:String = ""):void{
			if(_slashCmds[n] != null){
				var prev:SlashCommand = _slashCmds[n];
				if(!prev.c) {
					throw new Error("Can not alter build-in slash command ["+n+"]");
				}
			}
			if(callback == null) delete _slashCmds[n];
			else _slashCmds[n] = new SlashCommand(n, callback, desc);
		}
		public function run(str:String):* {
			report("&gt; "+str,5, false);
			if(!_master.config.commandLineAllowed) {
				report("CommandLine is disabled.",10);
				return null;
			}
			var v:* = null;
			try{
				if(str.charAt(0) == "/"){
					execCommand(str);
				}else{
					var exe:Executer = new Executer();
					exe.addEventListener(Event.COMPLETE, onExecLineComplete, false, 0, true);
					v = exe.exec(_scope, str, _saved, RESERVED);
				}
			}catch(e:Error){
				reportError(e);
			}
			return v;
		}
		private function onExecLineComplete(e:Event):void{
			var exe:Executer = e.currentTarget as Executer;
			if(_scope == exe.scope) setReturned(exe.returned);
			else if(exe.scope == exe.returned) setReturned(exe.scope, true);
			else {
				setReturned(exe.returned);
				setReturned(exe.scope, true);
			}
		}
		private function execCommand(str:String):void{
			var brk:int = str.indexOf(" ");
			var cmd:String = str.substring(1, brk>0?brk:str.length);
			var param:String = brk>0?str.substring(brk+1):"";
			if(_slashCmds[cmd] != null){
				try{
					var slashcmd:SlashCommand = _slashCmds[cmd];
					if(param.length == 0){
						slashcmd.f();
					}else{
						slashcmd.f(param);
					}
				}catch(err:Error){
					report("ERROR slash command: "+CastToString(err), 10);
				}
			} else{
				report("Undefined command <b>/cmds</b> for list of all commands.",10);
			}
		}
		private function setReturned(returned:*, changeScope:Boolean = false):void{
			var change:Boolean = false;
			if(returned)
			{
				_saved.set(Executer.RETURNED, returned, true);
				if(returned !== _scope){
					if(changeScope){
						change = true;
					}else if(_master.config.commandLineAutoScope){
						var typ:String = typeof(returned);
						if(typ == "object" || typ=="xml"){
							change = true;
						}
					}
					if(change){
						_prevScope.reference = _scope;
						_scope = returned;
						dispatchEvent(new Event(Event.CHANGE));
					}
				}
				
			}
			if(returned !== undefined){
				var rtext:String = String(returned);
				// this is incase its something like XML, need to keep the <> tags...
				rtext = rtext.replace(new RegExp("<", "gm"), "&lt;");
 				//rtext = rtext.replace(new RegExp(">", "gm"), "&gt;");
 				if(change){
					report("Changed to "+ getQualifiedClassName(returned) +": <b>"+rtext+"</b>", -1);
 				}else{
					report("Returned "+ getQualifiedClassName(returned) +": <b>"+rtext+"</b>", -2);
 				}
			}else{
				report("Exec successful, undefined return.", -2);
			}
		}
		private function reportError(e:Error):void{
			var str:String = CastToString(e);
			var lines:Array = str.split(/\n\s*/);
			var p:int = 10;
			var internalerrs:int = 0;
			var len:int = lines.length;
			var parts:Array = [];
			var reg:RegExp = new RegExp("\\s*at\\s+("+Executer.CLASSES+")");
			for (var i:int = 0; i < len; i++){
				var line:String = lines[i];
				if(INTSTACKS >=0 && (line.search(reg) == 0)){
					// don't trace too many internal errors :)
					if(internalerrs>=INTSTACKS && i > 0) {
						break;
					}
					internalerrs++;
				}
				parts.push("<p"+p+">&gt;&nbsp;"+line.replace(/\s/, "&nbsp;")+"</p"+p+">");
				if(p>6) p--;
			}
			report(parts.join("\n"), 9);
		}
		public function map(base:DisplayObjectContainer, maxstep:uint = 0):void{
			_tools.map(base, maxstep);
		}
		public function reMap(param:String):void {
			setReturned(_tools.reMap(param, _master.stage), true);
		}
		public function inspect(obj:Object, viewAll:Boolean= true):void {
			_tools.inspect(obj, viewAll);
		}
		public function report(obj:*,priority:Number = 1, skipSafe:Boolean = true):void{
			_master.report(obj, priority, skipSafe);
		}
		//private function debug(...args):void{
		//	_master.report(_master.joinArgs(args), 2, false);
		//}
		private function saveCmd(param:String = null):void{
			store(param, _scope, false);
		}
		private function saveStrongCmd(param:String = null):void{
			store(param, _scope, true);
		}
		private function savedCmd(...args:Array):void{
			report("Saved vars: ", -1);
			var sii:uint = 0;
			var sii2:uint = 0;
			for(var X:String in _saved){
				var sao:* = _saved[X];
				sii++;
				if(sao==null) sii2++;
				report("<b>$"+X+"</b> = "+(sao==null?"null":getQualifiedClassName(sao)), -2);
			}
			report("Found "+sii+" item(s), "+sii2+" empty (or garbage collected).", -1);
		}
		private function stringCmd(param:String):void{
			report("String with "+param.length+" chars entered. Use /save <i>(name)</i> to save.", -2);
			setReturned(param, true);
		}
		private function cmdsCmd(...args:Array):void{
			var buildin:Array = [];
			var custom:Array = [];
			for each(var cmd:SlashCommand in _slashCmds){
				if(cmd.c) custom.push(cmd);
				else buildin.push(cmd);
			}
			buildin = buildin.sortOn("n");
			report("build-in commands:", 4);
			for each(cmd in buildin){
				report("<b>/"+cmd.n+"</b> <p-1>" + cmd.d+"</p-1>", -2);
			}
			if(custom.length){
				custom = custom.sortOn("n");
				report("User commands:", 4);
				for each(cmd in custom){
					report("<b>/"+cmd.n+"</b> <p-1>" + cmd.d+"</p-1>", -2);
				}
			}
		}
		private function filterCmd(param:String):void{
			_master.panels.mainPanel.filterText = param;
		}
		private function filterexpCmd(param:String):void{
			_master.panels.mainPanel.filterRegExp = new RegExp(param, "i");
		}
		private function inspectCmd(...args:Array):void{
			inspect(_scope, false);
		}
		private function inspectfullCmd(...args:Array):void{
			inspect(_scope, true);
		}
		private function explodeCmd(param:String):void{
			var depth:int = int(param);
			_master.explode(_scope, depth<=0?3:depth);
		}
		private function mapCmd(param:String):void{
			map(_scope as DisplayObjectContainer, int(param));
		}
		private function funCmd(param:String):void{
			var fakeFunction:FakeFunction = new FakeFunction(run, param);
			setReturned(fakeFunction.exec);
		}
		private function autoscopeCmd(...args:Array):void{
			_master.config.commandLineAutoScope = !_master.config.commandLineAutoScope;
			report("Auto-scoping <b>"+(_master.config.commandLineAutoScope?"enabled":"disabled")+"</b>.",10);
		}
		private function baseCmd(...args:Array):void
		{
			setReturned(base, true);
		}
		private function clearhisCmd(...args:Array):void
		{
			_master.panels.mainPanel.clearCommandLineHistory();
		}
	}
}
internal class FakeFunction{
	private var line:String;
	private var run:Function;
	public function FakeFunction(r:Function, l:String):void
	{
		run = r;
		line = l;
	}
	public function exec(...args):*
	{
		return run(line);
	}
}
internal class SlashCommand{
	public var n:String;
	public var f:Function;
	public var d:String;
	public var c:Boolean;
	public function SlashCommand(nn:String, ff:Function, dd:String = "", cus:Boolean = true){
		n = nn;
		f = ff;
		d = dd?dd:"";
		c = cus;
	}
}