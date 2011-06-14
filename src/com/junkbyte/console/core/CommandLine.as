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
package com.junkbyte.console.core 
{
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.WeakObject;
	import com.junkbyte.console.vos.WeakRef;

	import flash.display.DisplayObjectContainer;
	import flash.events.Event;

	public class CommandLine extends ConsoleCore{
		
		private static const DISABLED:String = "<b>Advanced CommandLine is disabled.</b>\nEnable by setting `Cc.config.commandLineAllowed = true;´\nType <b>/commands</b> for permitted commands.";
		
		private static const RESERVED:Array = [Executer.RETURNED, "base", "C"];
		
		private var _saved:WeakObject;
		
		private var _scope:*;
		private var _prevScope:WeakRef;
		private var _scopeStr:String = "";
		private var _slashCmds:Object;
		
		public var localCommands:Array = new Array("filter", "filterexp");
		
		public function CommandLine(m:Console) {
			super(m);
			_saved = new WeakObject();
			_scope = m;
			_slashCmds = new Object();
			_prevScope = new WeakRef(m);
			_saved.set("C", m);
			
			remoter.registerCallback("cmd", function(bytes:ByteArray):void{
				run(bytes.readUTF());
			});
			remoter.registerCallback("scope", function(bytes:ByteArray):void{
				handleScopeEvent(bytes.readUnsignedInt());
			});
			remoter.registerCallback("cls", handleScopeString);
			remoter.addEventListener(Event.CONNECT, sendCmdScope2Remote);
			
			addCLCmd("help", printHelp, "How to use command line");
			addCLCmd("save|store", saveCmd, "Save current scope as weak reference. (same as Cc.store(...))");
			addCLCmd("savestrong|storestrong", saveStrongCmd, "Save current scope as strong reference");
			addCLCmd("saved|stored", savedCmd, "Show a list of all saved references");
			addCLCmd("string", stringCmd, "Create String, useful to paste complex strings without worrying about \" or \'", false, null);
			addCLCmd("commands", cmdsCmd, "Show a list of all slash commands", true);
			addCLCmd("inspect", inspectCmd, "Inspect current scope");
			addCLCmd("explode", explodeCmd, "Explode current scope to its properties and values (similar to JSON)");
			addCLCmd("map", mapCmd, "Get display list map starting from current scope");
			addCLCmd("function", funCmd, "Create function. param is the commandline string to create as function. (experimental)");
			addCLCmd("autoscope", autoscopeCmd, "Toggle autoscoping.");
			addCLCmd("base", baseCmd, "Return to base scope");
			addCLCmd("/", prevCmd, "Return to previous scope");
			
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_prevScope.reference = _scope;
				_scope = obj;
				_scopeStr = LogReferences.ShortClassName(obj, false);
			}
			_saved.set("base", obj);
		}
		public function get base():Object {
			return _saved.get("base");
		}
		public function handleScopeString(bytes:ByteArray):void{
			_scopeStr = bytes.readUTF();
		}
		public function handleScopeEvent(id:uint):void{
			if(remoter.remoting == Remoting.RECIEVER){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUnsignedInt(id);
				remoter.send("scope", bytes);
			}else{
				var v:* = console.refs.getRefById(id);
				if(v) console.cl.setReturned(v, true, false);
				else console.report("Reference no longer exist.", -2);
			}
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void {
			if(!n) {
				report("ERROR: Give a name to save.",10);
				return;
			}
			// if it is a function it needs to be strong reference atm, 
			// otherwise it fails if the function passed is from a dynamic class/instance
			if(obj is Function) strong = true;
			n = n.replace(/[^\w]*/g, "");
			if(RESERVED.indexOf(n)>=0){
				report("ERROR: The name ["+n+"] is reserved",10);
				return;
			}else{
				_saved.set(n, obj, strong);
			}
			/*if(!config.quiet){
				var str:String = strong?"STRONG":"WEAK";
				report("Stored <p5>$"+n+"</p5> for <b>"+console.links.makeRefTyped(obj)+"</b> using <b>"+ str +"</b> reference.",-1);
			}*/
		}
		public function getHintsFor(str:String, max:uint):Array{
			var all:Array = new Array();
			for (var X:String in _slashCmds){
				var cmd:Object = _slashCmds[X];
				if(config.commandLineAllowed || cmd.allow)
				all.push(["/"+X+" ", cmd.d?cmd.d:null]);
			}
			if(config.commandLineAllowed){
				for (var Y:String in _saved){
					all.push(["$"+Y, LogReferences.ShortClassName(_saved.get(Y))]);
				}
				if(_scope){
					all.push(["this", LogReferences.ShortClassName(_scope)]);
					all = all.concat(console.refs.getPossibleCalls(_scope));
				}
			}
			str = str.toLowerCase();
			var hints:Array = new Array();
			for each(var canadate:Array in all){
				if(canadate[0].toLowerCase().indexOf(str) == 0){
					hints.push(canadate);
				}
			}
			hints = hints.sort(function(a:Array, b:Array):int{
				if(a[0].length < b[0].length) return -1;
				if(a[0].length > b[0].length) return 1;
				return 0;
			});
			if(max > 0 && hints.length > max){
				hints.splice(max);
				hints.push(["..."]);
			}
			return hints;
		}
		public function get scopeString():String{
			return config.commandLineAllowed?_scopeStr:"";
		}
		public function addCLCmd(n:String, callback:Function, desc:String, allow:Boolean = false, endOfArgsMarker:String = ";"):void{
			var split:Array = n.split("|");
			for(var i:int = 0; i<split.length; i++){
				n = split[i];
				_slashCmds[n] = new SlashCommand(n, callback, desc, false, allow, endOfArgsMarker);
				if(i>0) _slashCmds.setPropertyIsEnumerable(n, false);
			}
		}
		public function addSlashCommand(n:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void{
			n = n.replace(/[^\w]*/g, "");
			if(_slashCmds[n] != null){
				var prev:SlashCommand = _slashCmds[n];
				if(!prev.user) {
					throw new Error("Can not alter build-in slash command ["+n+"]");
				}
			}
			if(callback == null) delete _slashCmds[n];
			else _slashCmds[n] = new SlashCommand(n, callback, LogReferences.EscHTML(desc), true, alwaysAvailable, endOfArgsMarker);
		}
		public function run(str:String, saves:Object = null):* {
			if(!str) return;
			str = str.replace(/\s*/,"");
			if(remoter.remoting == Remoting.RECIEVER){
				if(str.charAt(0) == "~"){
					str = str.substring(1);
				}else if(str.search(new RegExp("\/"+localCommands.join("|\/"))) != 0){
					report("Run command at remote: "+str,-2);
					
					var bytes:ByteArray = new ByteArray();
					bytes.writeUTF(str);
					if(!console.remoter.send("cmd", bytes)){
						report("Command could not be sent to client.", 10);
					}
					return null;
				}
			}
			report("&gt; "+str, 4, false);
			var v:* = null;
			try{
				if(str.charAt(0) == "/"){
					execCommand(str.substring(1));
				}else{
					if(!config.commandLineAllowed) {
						report(DISABLED, 9);
						return null;
					}
					var exe:Executer = new Executer();
					exe.addEventListener(Event.COMPLETE, onExecLineComplete, false, 0, true);
					if(saves){
						for(var X:String in _saved){
							if(!saves[X]) saves[X] = _saved[X];
						}
					}else{
						saves = _saved;
					}
					exe.setStored(saves);
					exe.setReserved(RESERVED);
					exe.autoScope = config.commandLineAutoScope;
					v = exe.exec(_scope, str);
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
			var brk:int = str.search(/[^\w]/); 
			var cmd:String = str.substring(0, brk>0?brk:str.length);
			if(cmd == ""){
				setReturned(_saved.get(Executer.RETURNED), true);
				return;
			}
			var param:String = brk>0?str.substring(brk+1):"";
			if(_slashCmds[cmd] != null){
				try{
					var slashcmd:SlashCommand = _slashCmds[cmd];
					if(!config.commandLineAllowed && !slashcmd.allow)
					{
						report(DISABLED, 9);
						return;
					}
					var restStr:String;
					if(slashcmd.endMarker){
						var endInd : int = param.indexOf(slashcmd.endMarker);
						if(endInd >= 0){
							restStr = param.substring(endInd+slashcmd.endMarker.length);
							param = param.substring(0, endInd);
						}
					}
					if(param.length == 0){
						slashcmd.f();
					} else {
						slashcmd.f(param);
					}
					if(restStr){
						run(restStr);
					}
				}catch(err:Error){
					reportError(err);
				}
			} else{
				report("Undefined command <b>/commands</b> for list of all commands.",10);
			}
		}
		public function setReturned(returned:*, changeScope:Boolean = false, say:Boolean = true):void{
			if(!config.commandLineAllowed) {
				report(DISABLED, 9);
				return;
			}
			if(returned !== undefined)
			{
				_saved.set(Executer.RETURNED, returned, true);
				if(changeScope && returned !== _scope){
					// scope changed
					_prevScope.reference = _scope;
					_scope = returned;
					if(remoter.remoting != Remoting.RECIEVER){
						_scopeStr = LogReferences.ShortClassName(_scope, false);
						sendCmdScope2Remote();
					}
					report("Changed to "+console.refs.makeRefTyped(returned), -1);
				}else{
					if(say) report("Returned "+console.refs.makeString(returned), -1);
				}
			}else{
				if(say) report("Exec successful, undefined return.", -1);
			}
		}
		public function sendCmdScope2Remote(e:Event = null):void{
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTF(_scopeStr);
			console.remoter.send("cls", bytes);
		}
		private function reportError(e:Error):void{
			var str:String = console.refs.makeString(e);
			var lines:Array = str.split(/\n\s*/);
			var p:int = 10;
			var internalerrs:int = 0;
			var len:int = lines.length;
			var parts:Array = [];
			var reg:RegExp = new RegExp("\\s*at\\s+("+Executer.CLASSES+"|"+getQualifiedClassName(this)+")");
			for (var i:int = 0; i < len; i++){
				var line:String = lines[i];
				if(line.search(reg) == 0){
					// don't trace more than one internal errors :)
					if(internalerrs>0 && i > 0) {
						break;
					}
					internalerrs++;
				}
				parts.push("<p"+p+"> "+line+"</p"+p+">");
				if(p>6) p--;
			}
			report(parts.join("\n"), 9);
		}
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
				var ref:WeakRef = _saved.getWeakRef(X);
				sii++;
				if(ref.reference==null) sii2++;
				report((ref.strong?"strong":"weak")+" <b>$"+X+"</b> = "+console.refs.makeString(ref.reference), -2);
			}
			report("Found "+sii+" item(s), "+sii2+" empty.", -1);
		}
		private function stringCmd(param:String):void{
			report("String with "+param.length+" chars entered. Use /save <i>(name)</i> to save.", -2);
			setReturned(param, true);
		}
		private function cmdsCmd(...args:Array):void{
			var buildin:Array = [];
			var custom:Array = [];
			for each(var cmd:SlashCommand in _slashCmds){
				if(config.commandLineAllowed || cmd.allow){
					if(cmd.user) custom.push(cmd);
					else buildin.push(cmd);
				}
			}
			buildin = buildin.sortOn("n");
			report("Built-in commands:"+(!config.commandLineAllowed?" (limited permission)":""), 4);
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
		private function inspectCmd(...args:Array):void{
			console.refs.focus(_scope);
		}
		private function explodeCmd(param:String = "0"):void{
			var depth:int = int(param);
			console.explodech(console.panels.mainPanel.reportChannel, _scope, depth<=0?3:depth);
		}
		private function mapCmd(param:String = "0"):void{
			console.mapch(console.panels.mainPanel.reportChannel, _scope as DisplayObjectContainer, int(param));
		}
		private function funCmd(param:String = ""):void{
			var fakeFunction:FakeFunction = new FakeFunction(run, param);
			report("Function created. Use /savestrong <i>(name)</i> to save.", -2);
			setReturned(fakeFunction.exec, true);
		}
		private function autoscopeCmd(...args:Array):void{
			config.commandLineAutoScope = !config.commandLineAutoScope;
			report("Auto-scoping <b>"+(config.commandLineAutoScope?"enabled":"disabled")+"</b>.",10);
		}
		private function baseCmd(...args:Array):void{
			setReturned(base, true);
		}
		private function prevCmd(...args:Array):void{
			setReturned(_prevScope.reference, true);
		}
		private function printHelp(...args:Array):void {
			report("____Command Line Help___",10);
			report("/filter (text) = filter/search logs for matching text",5);
			report("/commands to see all slash commands",5);
			report("Press up/down arrow keys to recall previous line",2);
			report("__Examples:",10);
			report("<b>stage.stageWidth</b>",5);
			report("<b>stage.scaleMode = flash.display.StageScaleMode.NO_SCALE</b>",5);
			report("<b>stage.frameRate = 12</b>",5);
			report("__________",10);
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
		return run(line, args);
	}
}
internal class SlashCommand{
	public var n:String;
	public var f:Function;
	public var d:String;
	public var user:Boolean;
	public var allow:Boolean;
	public var endMarker:String;
	public function SlashCommand(nn:String, ff:Function, dd:String, cus:Boolean, permit:Boolean, argsMarker:String){
		n = nn;
		f = ff;
		d = dd?dd:"";
		user = cus;
		allow = permit;
		endMarker = argsMarker;
	}
}