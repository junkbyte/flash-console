/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
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
package com.luaye.console.core {
	import com.luaye.console.vos.WeakRef;
	import com.luaye.console.Console;
	import com.luaye.console.utils.Utils;
	import com.luaye.console.vos.WeakObject;

	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;

	public class CommandLine extends EventDispatcher {
		
		private static const MAX_INTERNAL_STACK_TRACE:int = 1;
		private static const RETURNED_KEY:String = "returned";
		public static const MONITORING_OBJ_KEY:String = "monitorObj";
		
		private static const RESERVED_SAVES:Array = [RETURNED_KEY, "base", "C", MONITORING_OBJ_KEY];
		
		
		private var _saved:WeakObject;
		
		private var _scope:WeakRef;
		private var _prevScope:WeakRef;
		
		private var _master:Console;
		private var _tools:CommandTools;
		private var _autoScope:Boolean;
		
		public function CommandLine(m:Console) {
			_master = m;
			_tools = new CommandTools(report);
			_saved = new WeakObject();
			_scope = new WeakRef(m);
			_prevScope = new WeakRef(m);
			_saved.set("C", m);
			_saved.set(MONITORING_OBJ_KEY, m.om.getObject);
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_prevScope.reference = _scope.reference;
				_scope.reference = obj;
				dispatchEvent(new Event(Event.CHANGE));
			}
			_saved.set("base", obj);
		}
		public function get base():Object {
			return _saved.get("base");
		}
		public function destory():void {
			_saved = null;
			_master = null;
			_tools = null;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void {
			// if it is a function it needs to be strong reference atm, 
			// otherwise it fails if the function passed is from a dynamic class/instance
			strong = (strong || obj is Function);
			n = n.replace(/[^\w]*/g, "");
			if(RESERVED_SAVES.indexOf(n)>=0){
				report("ERROR: The name ["+n+"] is reserved",10);
				return;
			}else{
				_saved.set(n, obj, strong);
			}
			if(!_master.quiet){
				var str:String = strong?"STRONG":"WEAK";
				report("Stored <p5>$"+n+"</p5> for <b>"+getQualifiedClassName(obj)+"</b> using <b>"+ str +"</b> reference.",-1);
			}
		}
		public function get scopeString():String{
			return Utils.shortClassName(_scope.reference);
		}
		public function run(str:String):* {
			report("&gt; "+str,5, false);
			if(!_master.commandLineAllowed) {
				report("CommandLine is disabled.",10);
				return null;
			}
			var v:* = null;
			try{
				if(str.charAt(0) == "/"){
					execCommand(str);
				}else{
					var a:Array = Executer.Execs(_scope.reference, str, _saved, RESERVED_SAVES);
					for each(v in a) {
						setReturned(v);
					}
				}
			}catch(e:Error){
				reportError(e);
			}
			return v;
		}
		private function execCommand(str:String):void{
			var brk:int = str.indexOf(" ");
			var cmd:String = str.substring(1, brk>0?brk:str.length);
			var param:String = brk>0?str.substring(brk+1):"";
			//debug("execSlashCommand: "+ cmd+(param?(": "+param):""));
			if (cmd == "help") {
				_tools.printHelp();
			} else if (cmd == "remap") {
				// this is a special case... no user will be able to do this command
				setScope(_tools.reMap(param, _master.stage));
			} else if (cmd == "save" || cmd == "store" || cmd == "savestrong" || cmd == "storestrong") {
				if (_saved[RETURNED_KEY]) {
					param = param.replace(/[^\w]/g, "");
					if(!param){
						report("ERROR: Give a name to save.",10);
					}else{
						store(param, _saved[RETURNED_KEY], (cmd == "savestrong" || cmd == "storestrong"));
					}
				} else {
					report("Nothing to save", 10);
				}
			} else if (cmd == "string") {
				report("String with "+param.length+" chars stored. Use /save <i>(name)</i> to save.", -2);
				if(_autoScope) setScope(param);
				else setReturned(param);
				//_scope = param;
				//dispatchEvent(new Event(Event.CHANGE));
			} else if (cmd == "saved" || cmd == "stored") {
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
			} else if (cmd == "filter" || cmd == "search") {
				_master.filterText = param;
			} else if (cmd == "filterexp" || cmd == "searchexp") {
				_master.filterRegExp = new RegExp(param, "i");
			} else if (cmd == "inspect" || cmd == "inspectfull") {
				if (_scope.reference) {
					var viewAll:Boolean = (cmd == "inspectfull")? true: false;
					inspect(_scope.reference, viewAll);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "explode") {
				if (_scope.reference) {
					var depth:int = Number(param);
					_master.explode(_scope.reference, depth<=0?3:depth);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "monitor") {
				if (_scope.reference) {
					_master.monitor(_scope.reference, param);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "map") {
				if (_scope.reference) {
					map(_scope.reference as DisplayObjectContainer, int(param));
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "function") {
				var fakeFunction:FakeFunction = new FakeFunction(run, param);
				setReturned(fakeFunction.exec);
			} else if (cmd == "/") {
				if(_prevScope.reference) setScope(_prevScope.reference);
				else report("No previous scope",8);
			} else if (cmd == "" || cmd == "scope") {
				setScope(_saved["returned"]);
			} else if (cmd == "autoscope") {
				_autoScope = !_autoScope;
				report("Auto-scoping <b>"+(_autoScope?"enabled":"disabled")+"</b>.",10);
			} else if (cmd == "clearhistory") {
				_master.panels.mainPanel.clearCommandLineHistory();
			} else if (cmd == "base") {
				setScope(base);
			} else{
				report("Undefined command <b>/help</b> for info.",10);
			}
		}
		private function setScope(newscope:*):void
		{
			if(newscope && _scope.reference !== newscope)
			{
				_prevScope.reference = _scope.reference;
				_scope.reference = newscope;
				setReturned(newscope);
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		private function setReturned(returned:*):void{
			if(returned)
			{
				_saved.set("returned", returned, true);
				if(_autoScope && _scope.reference !== returned){
					var typ:String = typeof(returned);
					if(typ == "object" || typ=="xml"){
						setScope(returned);
						return;
					}
				}
			}
			if(returned !== undefined){
				var rtext:String = String(returned);
				// this is incase its something like XML, need to keep the <> tags...
				rtext = rtext.replace(new RegExp("<", "gm"), "&lt;");
 				//rtext = rtext.replace(new RegExp(">", "gm"), "&gt;");
				report("Returned "+ getQualifiedClassName(returned) +": <b>"+rtext+"</b>", -2);
			}else{
				report("Exec successful, undefined return.", -2);
			}
		}
		private function reportError(e:Error):void{
			// e.getStackTrace() is not supported in non-//debugger players...
			var str:String = e.hasOwnProperty("getStackTrace")?e.getStackTrace():String(e);
			if(!str){
				str = String(e);
			}
			var lines:Array = str.split(/\n\s*/);
			var p:int = 10;
			var internalerrs:int = 0;
			var len:int = lines.length;
			var parts:Array = [];
			var reg:RegExp = new RegExp("\\s*at\\s+("+Executer.EXE_CLASSNAMES+")");
			for (var i:int = 0; i < len; i++){
				var line:String = lines[i];
				if(MAX_INTERNAL_STACK_TRACE >=0 && (line.search(reg) == 0)){
					// don't trace too many internal errors :)
					if(internalerrs>=MAX_INTERNAL_STACK_TRACE && i > 0) {
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
		public function inspect(obj:Object, viewAll:Boolean= true):void {
			_tools.inspect(obj, viewAll);
		}
		public function report(obj:*,priority:Number = 1, skipSafe:Boolean = true):void{
			_master.report(obj, priority, skipSafe);
		}
		//private function debug(...args):void{
		//	_master.report(_master.joinArgs(args), 2, false);
		//}
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