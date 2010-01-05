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
	import flash.utils.flash_proxy;

	import com.luaye.console.Console;
	import com.luaye.console.utils.Utils;
	import com.luaye.console.utils.WeakObject;

	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class CommandLine extends EventDispatcher {
		public static const CHANGED_SCOPE:String = "changedScope";
		
		private static const VALUE_CONST:String = "#";
		private static const MAX_INTERNAL_STACK_TRACE:int = 1;
		
		private var _saved:WeakObject;
		
		private var _scope:*;
		private var _prevScope:*;
		private var _reserved:Array;
		private var _values:Array;
		
		private var _master:Console;
		private var _tools:CommandTools;
		
		public function CommandLine(m:Console) {
			_master = m;
			_tools = new CommandTools(report);
			_saved = new WeakObject();
			_scope = m;
			_saved.set("C", m);
			_reserved = new Array("returned", "base", "C");
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_scope = obj;
				dispatchEvent(new Event(CHANGED_SCOPE));
			}
			_saved.set("base", obj, _master.strongRef);
		}
		public function get base():Object {
			return _saved.get("base");
		}
		public function destory():void {
			_saved = null;
			_master = null;
			_reserved = null;
			_tools = null;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void {
			// if it is a function it needs to be strong reference atm, 
			// otherwise it fails if the function passed is from a dynamic class/instance
			strong = (strong || _master.strongRef || obj is Function);
			n = n.replace(/[^\w]*/g, "");
			if(_reserved.indexOf(n)>=0){
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
		// com.luaye.console.C.instance.visible
		// com.luaye.console.C.instance.addGraph('test',stage,'mouseX')
		// test('simple stuff. what ya think?');
		// test('He\'s cool! (not really)','',"yet 'another string', what ya think?");
		// this.getChildAt(0); 
		// stage.addChild(root.addChild(this.getChildAt(0)));
		// third(second(first('console'))).final(0).alpha;
		// getChildByName(String('Console')).getChildByName('message').alpha = 0.5;
		// getChildByName(String('Console').abcd().asdf).getChildByName('message').alpha = 0.5;
		// com.luaye.console.C.add('Hey how are you?');
		public function run(str:String):* {
			report("&gt; "+str,5, false);
			if(!_master.commandLineAllowed) {
				report("CommandLine is disabled.",10);
				return null;
			}
			var v:* = null;
			// incase you are calling the run from commandLine... paradox?
			// EXAMPLE: $C.runCommand("$C.warn('PARADOX!')") - but why would you?
			var isclean:Boolean = _values==null;
			if(isclean) _values = [];
			try{
				if(str.charAt(0) == "/"){
					execCommand(str);
				}else{
					v = exec(str);
				}
			}catch(e:Error){
				reportError(e);
			}
			if(isclean) _values = null;
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
			} else if (cmd == "strong") {
				if(param == "true"){
					_master.strongRef = true;
					report("Now using STRONG referencing.", 10);
				}else if (param == "false"){
					_master.strongRef = false;
					report("Now using WEAK referencing.", 10);
				}else if(_master.strongRef){
					report("Using STRONG referencing. '/strong false' to use weak", -2);
				}else{
					report("Using WEAK referencing. '/strong true' to use strong", -2);
				}
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
				_master.filterText = str.substring(8);
			} else if (cmd == "inspect" || cmd == "inspectfull") {
				if (_scope) {
					var viewAll:Boolean = (cmd == "inspectfull")? true: false;
					inspect(_scope, viewAll);
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
				doReturn(_prevScope?_prevScope:base);
			} else if (cmd == "scope") {
				doReturn(_saved["returned"], true);
			} else if (cmd == "base") {
				doReturn(base);
			} else{
				report("Undefined command <b>/help</b> for info.",10);
			}
		}
		private function exec(str:String):* {
			//
			// STRIP strings - '...', "...", '', "", while ignoring \' \" etc inside.
			var strReg:RegExp = /('(.*?)[^\\]')|("(.*?)[^\\]")|''|""/;
			var result:Object = strReg.exec(str);
			while(result != null){
				var match:String = result[0];
				var quote:String = match.charAt(0);
				var start:int = match.indexOf(quote);
				var end:int = match.lastIndexOf(quote);
				var string:String = match.substring(start+1,end).replace(/\\(.)/g, "$1");
				//debug(VALUE_CONST+_values.length+" = "+string, 2, false);
				//debug(str);
				str = tempValue(str,new Value(string), result.index+start, result.index+end+1);
				result = strReg.exec(str);
			}
			//
			// All strings will have replaced by ^0, ^1, etc
			if(str.search(new RegExp('\'|\"'))>=0){
				throw new Error('Bad syntax extra quotation marks');
			}
			//
			// Run each line
			var v:* = null;
			var lineBreaks:Array = str.split(/\s*;\s*/);
			for each(var line:String in lineBreaks){
				if(line.length){
					v = execNest(line);
				}
			}
			return v;
		}
		//
		// Nested strip
		// aaa.bbb(1/2,ccc(dd().ee)).ddd = fff+$g.hhh();
		//
		private function execNest(line:String):*{
			// exec values inside () - including functions and groups.
			line = ignoreWhite(line);
			var indOpen:int = line.lastIndexOf("(");
			while(indOpen>=0){
				var firstClose:int = line.indexOf(")", indOpen);
				//if there is params...
				if(line.substring(indOpen+1, firstClose).search(/\w/)>=0){
					// increment closing if there r more opening inside
					var indopen2:int = indOpen;
					var indClose:int = indOpen+1;
					while(indopen2>=0 && indopen2<indClose){
						indopen2++;
						indopen2 = line.indexOf("(",indopen2);
						indClose = line.indexOf(")",indClose+1);
					}
					//
					var inside:String = line.substring(indOpen+1, indClose);
					// must be a better way to see if its letter/digit or not :/
					var isfun:Boolean = false;
					var fi:int = indOpen-1;
					while(true){
						var char:String = line.charAt(fi);
						if(char.match(/[^\s]/) || fi<=0) {
							if(char.match(/\w/)) isfun = true;
							break;
						}
						fi--;
					}
					if(isfun){
						var params:Array = inside.split(",");
						line = tempValue(line,new Value(params), indOpen+1, indClose);
						//debug("^"+_values.length+" stores function params ["+params+"]");
						for(var X:String in params){
							params[X] = execOperations(ignoreWhite(params[X])).value;
						}
					}else{
						var groupv:* = new Value(groupv);
						line = tempValue(line,groupv, indOpen, indClose+1);
						//debug("^"+_values.length+" stores group value for "+inside);
						groupv.value = execOperations(ignoreWhite(inside)).value;
					}
					
					//debug(line);
				}
				indOpen = line.lastIndexOf("(", indOpen-1);
			}
			var v:* = execOperations(line).value;
			doReturn(v);
			return v;
		}
		private function tempValue(str:String,v:*, indOpen:int, indClose:int):String{
			str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, indOpen, indClose);
			_values.push(v);
			return str;
		}
		//
		// Simple strip with operations.
		// aaa.bbb.ccc(1/2,3).ddd += fff+$g.hhh();
		//
		private function execOperations(str:String):Value{
			var reg:RegExp = /\s*(((\|\||\&\&|[+|\-|*|\/|\%|\||\&|\^]|\=\=?|\!\=|\>\>?\>?|\<\<?)\=?)|=|\~|\sis\s|typeof\s)\s*/g;
			var result:Object = reg.exec(str);
			var seq:Array = [];
			if(result == null){
				seq.push(str);
			}else{
				var lastindex:int = 0;
				while(result != null){
					var index:int = result.index;
					var operation:String = result[0];
					result = reg.exec(str);
					if(result==null){
						seq.push(str.substring(lastindex, index));
						seq.push(operation.replace(/\s/g, ""));
						seq.push(str.substring(index+operation.length));
					}else{
						seq.push(str.substring(lastindex, index));
						seq.push(operation.replace(/\s/g, ""));
						lastindex = index+operation.length;
					}
				}
			}
			//debug("execOperations: "+seq);
			// EXEC values in sequence fisrt
			var len:int = seq.length;
			for(var i:int = 0;i<len;i+=2){
				seq[i] = execSimple(seq[i]);
			}
			var op:String;
			var res:*;
			var setter:RegExp = /((\|\||\&\&|[+|\-|*|\/|\%|\||\&|\^]|\>\>\>?|\<\<)\=)|=/;
			// EXEC math operations
			for(i = 1;i<len;i+=2){
				op = seq[i];
				if(op.replace(setter,"")!=""){
					res = operate(seq[i-1].value, op, seq[i+1].value);
					//debug("operate: "+seq[i-1].value, op, seq[i+1].value, "=", res);
					seq[i-1].value = res;
					seq.splice(i,2);
					i-=2;
					len-=2;
				}
			}
			// EXEC setter operations after reversing the sequence
			seq.reverse();
			var v:Value = seq[0];
			for(i = 1;i<len;i+=2){
				op = seq[i];
				if(op.replace(setter,"")==""){
					v = seq[i+1];
					if(op.length>1) op = op.substring(0,op.length-1);
					res = operate(v.value, op, seq[i-1].value);
					//debug("operate setter: "+v.prop, v.value, op, seq[i-1].value, "=", res);
					v.value = res;
					if(v.base!=null) {
						v.base[v.prop] = v.value;
					}
				}
			}
			return v;
		}
		//
		// Simple strip
		// aaa.bbb.ccc(0.5,3).ddd
		// includes class path detection and 'new' operation
		//
		private function execSimple(str:String):Value{
			var v:Value = new Value();
			//debug('execStrip: '+str);
			//
			// if it is 'new' operation
			if(str.indexOf("new ")==0){
				var newstr:String = str;
				var defclose:int = str.indexOf(")");
				if(defclose>=0){
					newstr = str.substring(0, defclose+1);
				}
				var newobj:* = makeNew(newstr.substring(4));
				str = tempValue(str, new Value(newobj,newobj, newstr), 0, newstr.length);
			}
			//
			//
			var reg:RegExp = /\.|\(/g;
			var result:Object = reg.exec(str);
			if(result==null || !isNaN(Number(str))){
				return execValue(str, null);
			}
			//
			// AUTOMATICALLY detect classes in packages
			var firstparts:Array = str.split("(")[0].split(".");
			if(firstparts.length>0){
				while(firstparts.length){
					var classstr:String = firstparts.join(".");
					try{
						var def:* = getDefinitionByName(ignoreWhite(classstr));
						var havemore:Boolean = str.length>classstr.length;
						//debug(classstr+" is a class.");
						str = tempValue(str, new Value(def, def, classstr), 0, classstr.length);
						if(havemore){
							reg.lastIndex = 0;
							result = reg.exec(str);
						}else{
							return execValue(str, null);
						}
						break;
					}catch(e:Error){
						firstparts.pop();
					}
				}
			}
			//
			// dot syntex and simple function steps
			var previndex:int = 0;
			while(result != null){
				var index:int = result.index;
				var isFun:Boolean = str.charAt(index)=="(";
				var basestr:String = ignoreWhite(str.substring(previndex, index));
				//debug("scopestr = "+basestr+ " v.base = "+v.base);
				var newv:Value = execValue(basestr, v.base);
				var newbase:* = newv.value;
				v.base = newv.base;
				//debug("scope = "+newbase+"  isFun:"+isFun);
				if(isFun){
					var closeindex:int = str.indexOf(")", index);
					var paramstr:String = str.substring(index+1, closeindex);
					paramstr = paramstr.replace(/\s/g,"");
					var params:Array = [];
					if(paramstr){
						params = execValue(paramstr).value;
					}
					//debug("params = "+params.length+" - ["+ params+"]");
					// this is because methods in stuff like XML/XMLList got AS3 namespace.
					if(!(newbase is Function)){
						try{
							var nss:Array = [AS3, flash_proxy];
							for each(var ns:Namespace in nss){
								var nsv:* = v.base.ns::[basestr];
								if(nsv is Function){
									newbase = nsv;
									break;
								}
							}
						}catch(e:Error){
							// Will thorow below...
						}
						if(!(newbase is Function)){
							throw new Error(basestr+" is not a function.");
						}
					}
					v.value = (newbase as Function).apply(v.base, params);
					v.base = v.value;
					index = closeindex+1;
				}else{
					v.value = newbase;
				}
				v.prop = basestr;
				previndex = index+1;
				reg.lastIndex = index+1;
				result = reg.exec(str);
				if(result != null){
					v.base = v.value;
				}else if(index+1 < str.length){
					v.base = v.value;
					reg.lastIndex = str.length;
					result = {index:str.length};
				}
			}
			return v;
		}
		//
		// single values such as string, int, null, $a, ^1 and Classes without package.
		//
		private function execValue(str:String, base:* = null):Value{
			var nobase:Boolean = base?false:true;
			var v:Value = new Value(null, base, str);
			base = base?base:_scope;
			if(nobase && (!base || !base.hasOwnProperty(str))){
				if (str == "true") {
					v.value = true;
				}else if (str == "false") {
					v.value = false;
				}else if (str == "this") {
					v.base = _scope;
					v.value = _scope;
				}else if (str == "null") {
					v.value = null;
				}else if (str == "NaN") {
					v.value = NaN;
				}else if (str == "Infinity") {
					v.value = Infinity;
				}else if (str == "undefined") {
					v.value = undefined;
				}else if (!isNaN(Number(str))) {
					v.value = Number(str);
				}else if(str.indexOf(VALUE_CONST)==0){
					var vv:Value = _values[str.substring(VALUE_CONST.length)];
					//debug(VALUE_CONST+str.substring(VALUE_CONST.length)+" = " +vv);
					v.base = vv.base;
					v.value = vv.value;
				}else if(str.charAt(0) == "$"){
					var key:String = str.substring(1);
					v.value = _saved[key];
					if(_reserved.indexOf(key)<0){
						if(v.value == null){
							store(key, v.value);
						}
						v.base = _saved;
						v.prop = key;
					}
				}else{
					try{
						v.value = getDefinitionByName(str);
						v.base = v.value;
					}catch(e:Error){
						v.base = base;
						v.value = base[str];
					}
				}
			}else{
				v.base = base;
				v.value = base[str];
			}
			//debug("value: "+str+" = "+getQualifiedClassName(v.value)+" - "+v.value+" base:"+v.base);
			return v;
		}
		// * typed cause it could be String +  OR comparison such as || or &&
		private function operate(v1:*, op:String, v2:*):*{
			switch (op){
				case "=":
					return v2;
				case "+":
					return v1+v2;
				case "-":
					return v1-v2;
				case "*":
					return v1*v2;
				case "/":
					return v1/v2;
				case "%":
					return v1%v2;
				case "^":
					return v1^v2;
				case "&":
					return v1&v2;
				case ">>":
					return v1>>v2;
				case ">>>":
					return v1>>>v2;
				case "<<":
					return v1<<v2;
				case "~":
					return ~v2;
				case "|":
					return v1|v2;
				case "!":
					return !v2;
				case ">":
					return v1>v2;
				case ">=":
					return v1>=v2;
				case "<":
					return v1<v2;
				case "<=":
					return v1<=v2;
				case "||":
					return v1||v2;
				case "&&":
					return v1&&v2;
				case "is":
					return v1 is v2;
				case "typeof":
					return typeof v2;
				case "==":
					return v1==v2;
				case "===":
					return v1===v2;
				case "!=":
					return v1!=v2;
				case "!==":
					return v1!==v2;
			}
		}
		//
		// make new instance
		//
		private function makeNew(str:String):*{
			//debug("makeNew "+str);
			var openindex:int = str.indexOf("(");
			var defstr:String = openindex>0?str.substring(0, openindex):str;
			defstr = ignoreWhite(defstr);
			var def:* = execValue(defstr).value;
			if(openindex>0){
				var closeindex:int = str.indexOf(")", openindex);
				var paramstr:String = str.substring(openindex+1, closeindex);
				paramstr = paramstr.replace(/\s/g,"");
				var p:Array = [];
				if(paramstr){
					p = execValue(paramstr).value;
				}
				var len:int = p.length;
				//
				// TODO: HELP! how do you construct an object with unknown number of arguments?
				// calling a functionw with multiple arguments can be done by fun.apply()... but can't for constructor :(
				if(len==0){
					return new (def)();
				}if(len==1){
					return new (def)(p[0]);
				}else if(len==2){
					return new (def)(p[0], p[1]);
				}else if(len==3){
					return new (def)(p[0], p[1], p[2]);
				}else if(len==4){
					return new (def)(p[0], p[1], p[2], p[3]);
				}else if(len==5){
					return new (def)(p[0], p[1], p[2], p[3], p[4]);
				}else if(len==6){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5]);
				}else if(len==7){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
				}else if(len==8){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]);
				}else if(len==9){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]);
				}else if(len==10){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]);
				}else if(len==11){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10]);
				}else if(len==12){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11]);
				}else if(len==13){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12]);
				}else if(len==14){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13]);
				}else if(len==15){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14]);
				}else if(len>=16){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15]);
				}
				// won't work with more than 16 arguments...
			}
			return null;
		}
		private function ignoreWhite(str:String):String{
			// can't just do /\s*(.*?)\s*/  :(  any better way?
			str = str.replace(/\s*(.*)/,"$1");
			var i:int = str.length-1;
			while(i>0){
				if(str.charAt(i).match(/\s/)) str = str.substring(0,i);
				else break;
				i--;
			}
			return str;
		}
		private function doReturn(returned:*, force:Boolean = false):void{
			var newb:Boolean = false;
			var typ:String = typeof(returned);
			if(returned){
				_saved.set("returned", returned, true);
				if(returned !== _scope && (force || typ == "object" || typ=="xml")){
					newb = true;
					_prevScope = _scope;
					_scope = returned;
					dispatchEvent(new Event(CHANGED_SCOPE));
				}
			}
			var rtext:String = String(returned);
			// this is incase its something like XML, need to keep the <> tags...
			rtext = rtext.replace(/</gim, "&lt;");
 			rtext = rtext.replace(/>/gim, "&gt;");
			report((newb?"<b>+</b> ":"")+"Returned "+ getQualifiedClassName(returned) +": <b>"+rtext+"</b>", -2);
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
			var self:String = getQualifiedClassName(this);
			var len:int = lines.length;
			var parts:Array = [];
			for (var i:int = 0; i < len; i++){
				var line:String = lines[i];
				if(MAX_INTERNAL_STACK_TRACE >=0 && line.search(new RegExp("\\s*at "+self)) == 0 ){
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