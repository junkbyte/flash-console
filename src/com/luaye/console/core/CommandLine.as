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
	import com.luaye.console.utils.WeakRef;
	import com.luaye.console.Console;
	import com.luaye.console.utils.Utils;
	import com.luaye.console.utils.WeakObject;

	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;

	public class CommandLine extends EventDispatcher {
		public static const CHANGED_SCOPE:String = "changedScope";
		
		private static const MAX_INTERNAL_STACK_TRACE:int = 1;
		private static const RESERVED_SAVES:Array = ["returned", "base", "C"];
		
		private var _saved:WeakObject;
		
		// TODO: prev scope should be weak.
		private var _scope:*;
		private var _prevScope:WeakRef;
		
		private var _master:Console;
		private var _tools:CommandTools;
		
		public function CommandLine(m:Console) {
			_master = m;
			_tools = new CommandTools(report);
			_saved = new WeakObject();
			_prevScope = new WeakRef(m);
			_scope = m;
			_saved.set("C", m);
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_prevScope.reference = _scope;
				_scope = obj;
				dispatchEvent(new Event(CHANGED_SCOPE));
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
			return Utils.shortClassName(_scope);
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
					var a:Array = Executer.Execs(_scope, str, _saved, RESERVED_SAVES);
					for each(v in a) {
						doReturn(v);
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
				doReturn(_tools.reMap(param, _master.stage));
			} else if (cmd == "save" || cmd == "store" || cmd == "savestrong" || cmd == "storestrong") {
				if (_scope) {
					param = param.replace(/[^\w]/g, "");
					if(!param){
						report("ERROR: Give a name to save.",10);
					}else{
						store(param, _scope, (cmd == "savestrong" || cmd == "storestrong"));
					}
				} else {
					report("Nothing to save", 10);
				}
			} else if (cmd == "string") {
				report("String with "+param.length+" chars stored. Use /save <i>(name)</i> to save.", -2);
				_scope = param;
				dispatchEvent(new Event(CHANGED_SCOPE));
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
				if (_scope) {
					var viewAll:Boolean = (cmd == "inspectfull")? true: false;
					inspect(_scope, viewAll);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "explode") {
				if (_scope) {
					var depth:int = Number(param);
					_master.explode(_scope, depth<=0?-1:depth);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "map") {
				if (_scope) {
					map(_scope as DisplayObjectContainer, int(param));
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "/") {
				doReturn(_prevScope.reference?_prevScope.reference:base);
			} else if (cmd == "scope") {
				doReturn(_saved["returned"], true);
			} else if (cmd == "base") {
				doReturn(base);
			} else{
				report("Undefined command <b>/help</b> for info.",10);
			}
		}
		private function doReturn(returned:*, force:Boolean = false):void{
			var newb:Boolean = false;
			if(returned != null){
				var typ:String = typeof(returned);
				_saved.set("returned", returned, true);
				if(returned !== _scope && (force || typ == "object" || typ=="xml")){
					newb = true;
					_prevScope.reference = _scope;
					_scope = returned;
					dispatchEvent(new Event(CHANGED_SCOPE));
				}
			}
			if(returned !== undefined){
				var rtext:String = String(returned);
				// this is incase its something like XML, need to keep the <> tags...
				rtext = rtext.replace(/</gim, "&lt;");
 				rtext = rtext.replace(/>/gim, "&gt;");
				report((newb?"<b>+</b> ":"")+"Returned "+ getQualifiedClassName(returned) +": <b>"+rtext+"</b>", -2);
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
			var selfreg:RegExp = new RegExp("\\s*at "+getQualifiedClassName(this));
			var exereg:RegExp = new RegExp("\\s*at "+getQualifiedClassName(Executer));
			for (var i:int = 0; i < len; i++){
				var line:String = lines[i];
				if(MAX_INTERNAL_STACK_TRACE >=0 && (line.search(selfreg) == 0 || line.search(exereg) == 0)){
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
class Value{
	// TODO: potentially, we can have value only for 'non-reference', and have a boolen to tell if its a reference or value
	
	// this is a class to remember the base object and property name that holds the value...
	public var base:Object;
	public var prop:String;
	public var value:*;
	
	public function Value(v:* = null, b:Object = null, p:String = null):void{
		base = b;
		prop = p;
		value = v;
	}
}