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
	import com.luaye.console.Console;
	import com.luaye.console.utils.Utils;
	import com.luaye.console.utils.WeakObject;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class CommandLine extends EventDispatcher {
		public static const CHANGED_SCOPE:String = "changedScope";
		
		private static const VALUE_CONST:String = "#";
		private static const MAX_INTERNAL_STACK_TRACE:int = 1;
		
		private var _saved:WeakObject;
		
		private var _returned:*;
		private var _scope:*;
		private var _prevScope:*;
		private var _mapBases:WeakObject;
		private var _mapBaseIndex:uint = 1;
		private var _reserved:Array;
		private var _values:Array;
		
		private var _master:Console;

		public function CommandLine(m:Console) {
			_master = m;
			_saved = new WeakObject();
			_mapBases = new WeakObject();
			_scope = m;
			_returned = m;
			_saved.set("C", m);
			_reserved = new Array("base", "C");
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_returned = obj;
				_scope = obj;
				dispatchEvent(new Event(CHANGED_SCOPE));
			}
			_saved.set("base", obj, _master.strongRef);
		}
		public function get base():Object {
			return _saved.get("base");
		}
		public function destory():void {
			_returned = null;
			_saved = null;
			_master = null;
			_reserved = null;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):void {
			// if it is a function it needs to be strong reference atm, 
			// otherwise it fails if the function passed is from a dynamic class/instance
			strong = (strong || _master.strongRef || obj is Function) ?true:false;
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
			// incase you are calling a new command from commandLine... paradox?
			// EXAMPLE: $C.runCommand('/help') - but why would you?
			var isclean:Boolean = _values==null;
			if(isclean){
				_values = [];
			}
			try{
				v = exec(str);
			}catch(e:Error){
				reportError(e);
			}
			if(isclean){
				_values = null;
			}
			return v;
		}
		private function exec(str:String):* {
			if(str.charAt(0) == "/"){
				doCommand(str);
				return;
			}
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
				str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, result.index+start, result.index+end+1);
				//debug(VALUE_CONST+_values.length+" = "+string, 2, false);
				//debug(str);
				_values.push(new Value(string));
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
						line = Utils.replaceByIndexes(line, VALUE_CONST+_values.length, indOpen+1, indClose);
						var params:Array = inside.split(",");
						//debug("^"+_values.length+" stores function params ["+params+"]");
						_values.push(new Value(params));
						for(var X:String in params){
							params[X] = execOperations(ignoreWhite(params[X])).value;
						}
					}else{
						line = Utils.replaceByIndexes(line, VALUE_CONST+_values.length, indOpen, indClose+1);
						//debug("^"+_values.length+" stores group value for "+inside);
						var groupv:* = new Value(groupv);
						_values.push(groupv);
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
		//
		// Simple strip with operations.
		// aaa.bbb.ccc(1/2,3).ddd += fff+$g.hhh();
		//
		private function execOperations(str:String):Value{
			var reg:RegExp = /\s*(((\|\||\&\&|[+|\-|*|\/|\%|\||\&|\^|\!]|\=\=?|\>\>?\>?|\<\<?)\=?)|=|\sis\s|typeof\s)\s*/g;
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
			var setter:RegExp = /((\|\||\&\&|[+|\-|*|\/|\%|\||\&|\^]|\=\=?|\>\>\>?|\<\<)\=)|=/;
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
				str = str.substring(newstr.length);
				str = ignoreWhite(str);
				str = VALUE_CONST+_values.length+str;
				var newobj:* = makeNew(newstr.substring(4));
				_values.push(new Value(newobj,newobj, newstr));
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
						str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, 0, classstr.length);
						_values.push(new Value(def, def, classstr));
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
					v.value = _saved[str.substring(1)];
					if(v.value && _reserved.indexOf(key)<0){
						v.base = _saved;
						v.prop = str.substring(1);
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
			}
		}
		//
		// make new instance
		//
		private function makeNew(str:String):*{
			//debug("makeNew "+str);
			var openindex:int = str.indexOf("(");
			var defstr:String = openindex>0?str.substring(0, openindex):str;
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
				}else if(len==16){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15]);
				}else if(len==17){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16]);
				}else if(len==18){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17]);
				}else if(len==19){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18]);
				}else if(len>=20){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19]);
				}
				// won't work with more than 20 arguments...
			}
			return new (def)();
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
				_returned = returned;
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
		private function doCommand(str:String):void{
			var brk:int = str.indexOf(" ");
			var cmd:String = str.substring(1, brk>0?brk:str.length);
			var param:String = brk>0?str.substring(brk+1):"";
			//debug("doCommand: "+ cmd+(param?(": "+param):""));
			if (cmd == "help") {
				printHelp();
			} else if (cmd == "remap") {
				// this is a special case... no user will be able to do this command
				reMap(param);
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
				doReturn(_returned, true);
			} else if (cmd == "base") {
				doReturn(base);
			} else{
				report("Undefined commandLine syntex <b>/help</b> for info.",10);
			}
		}
		private function reportError(e:Error):void{
			// e.getStackTrace() is not supported in non-debugger players...
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
		public function inspect(obj:Object, viewAll:Boolean= true):void {
			//
			// Class extends... extendsClass
			// Class implements... implementsInterface
			// constant // statics
			// methods
			// accessors
			// varaibles
			// values
			// EVENTS .. metadata name="Event"
			//
			var V:XML = describeType(obj);
			var cls:Object = obj is Class?obj:obj.constructor;
			var clsV:XML = describeType(cls);
			var self:String = V.@name;
			var str:String = "<b>"+self+"</b>";
			var props:Array = [];
			var props2:Array = [];
			var staticPrefix:String = "<p1><i>[static]</i></p1>";
			var nodes:XMLList;
			if(V.@isDynamic=="true"){
				props.push("dynamic");
			}
			if(V.@isFinal=="true"){
				props.push("final");
			}
			if(V.@isStatic=="true"){
				props.push("static");
			}
			if(props.length > 0){
				str += " <p-1>"+props.join(" | ")+"</p-1>";
			}
			report(str+"<br/>", -2);
			//
			// extends...
			//
			props = [];
			nodes = V.extendsClass;
			for each (var extendX:XML in nodes) {
				props.push(extendX.@type.toString());
				if(!viewAll) break;
			}
			if(props.length){
				report("<p10>Extends:</p10> "+props.join("<p-1> &gt; </p-1>")+"<br/>", 5);
			}
			//
			// implements...
			//
			props = [];
			nodes = V.implementsInterface;
			for each (var implementX:XML in nodes) {
				props.push(implementX.@type.toString());
			}
			if(props.length){
				report("<p10>Implements:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// constants...
			//
			props = [];
			nodes = clsV..constant;
			for each (var constantX:XML in nodes) {
				props.push(constantX.@name+"<p0>("+constantX.@type+")</p0>");
			}
			if(props.length){
				report("<p10>Constants:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// methods
			//
			props = [];
			props2 = [];
			nodes = clsV..method; // '..' to include from <factory>
			for each (var methodX:XML in nodes) {
				var mparamsList:XMLList = methodX.parameter;
				str = methodX.parent().name()=="factory"?"":staticPrefix;
				if(viewAll){
					var params:Array = [];
					for each(var paraX:XML in mparamsList){
						params.push(paraX.@optional=="true"?("<i>"+paraX.@type+"</i>"):paraX.@type);
					}
					str += methodX.@name+"<p0>(<i>"+params.join(",")+"</i>):"+methodX.@returnType+"</p0>";
				}else{
					str += methodX.@name+"<p0>(<i>"+mparamsList.length()+"</i>):"+methodX.@returnType+"</p0>";
				}
				arr = (self==methodX.@declaredBy?props:props2);
				arr.push(str);
			}
			makeInheritLine(props, props2, viewAll, "Methods", viewAll?"<br/>":"<p-1>; </p-1>");
			//
			// accessors
			//
			var arr:Array;
			props = [];
			props2 = [];
			nodes = clsV..accessor; // '..' to include from <factory>
			for each (var accessorX:XML in nodes) {
				str = accessorX.parent().name()=="factory"?"":staticPrefix;
				str += (accessorX.@access=="readonly"?("<i>"+accessorX.@name+"</i>"):accessorX.@name)+"<p0>("+accessorX.@type+")</p0>";
				arr = (self==accessorX.@declaredBy?props:props2);
				arr.push(str);
			}
			makeInheritLine(props, props2, viewAll, "Accessors", "<p-1>; </p-1>");
			//
			// variables
			//
			props = [];
			nodes = clsV..variable;
			for each (var variableX:XML in nodes) {
				str = (variableX.parent().name()=="factory"?"":staticPrefix)+variableX.@name+"<p0>("+variableX.@type+")</p0>";
				props.push(str);
			}
			if(props.length){
				report("<p10>Variables:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// dynamic values
			//
			props = [];
			for (var X:String in obj) {
				props.push(X+"<p0>("+getQualifiedClassName(obj[X])+")</p0>");
			}
			if(props.length){
				report("<p10>Values:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// events
			// metadata name="Event"
			props = [];
			nodes = V.metadata;
			for each (var metadataX:XML in nodes) {
				if(metadataX.@name=="Event"){
					var mn:XMLList = metadataX.arg;
					props.push(mn.(@key=="name").@value+"<p0>("+mn.(@key=="type").@value+")</p0>");
				}
			}
			if(props.length){
				report("<p10>Events:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
			}
			//
			// display's parents and direct children
			//
			if (viewAll && obj is DisplayObjectContainer) {
				props = [];
				var mc:DisplayObjectContainer = obj as DisplayObjectContainer;
				var clen:int = mc.numChildren;
				for (var ci:int = 0; ci<clen; ci++) {
					var child:DisplayObject = mc.getChildAt(ci);
					props.push("<b>"+child.name+"</b>:("+ci+")"+getQualifiedClassName(child));
				}
				if(props.length){
					report("<p10>Children:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
				}
				var theParent:DisplayObjectContainer = mc.parent;
				if (theParent) {
					props = ["("+theParent.getChildIndex(mc)+")"];
					while (theParent) {
						var pr:DisplayObjectContainer = theParent;
						theParent = theParent.parent;
						props.push("<b>"+pr.name+"</b>:("+(theParent?theParent.getChildIndex(pr):"")+")"+getQualifiedClassName(pr));
					}
					if(props.length){
						report("<p10>Parents:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 5);
					}
				}
			}
			if(!viewAll){
				report("Tip: use /inspectfull to see full inspection with inheritance",-1);
			}
		}
		private function makeInheritLine(props:Array, props2:Array, viewAll:Boolean, type:String, breaker:String):void{
			var str:String = "";
			if(props.length || props2.length){
				str += "<p10>"+type+":</p10> "+props.join(breaker);
				if(viewAll){
					str += (props.length?breaker:"")+"<p2>"+props2.join(breaker)+"</p2>";
				}else if(props2.length){
					str += (props.length?breaker:"")+"<p2>+ "+props2.length+" inherited</p2>";
				}
				report(str+"<br/>", 5);
			}
		}
		public function map(base:DisplayObjectContainer, maxstep:uint = 0):void{
			if(!base){
				report("It is not a DisplayObjectContainer", 10);
				return;
			}
			_mapBases[_mapBaseIndex] = base;
			var basestr:String = _mapBaseIndex+Console.MAPPING_SPLITTER;
			
			var list:Array = new Array();
			var index:int = 0;
			list.push(base);
			while(index<list.length){
				var mcDO:DisplayObject = list[index];
				if(mcDO is DisplayObjectContainer){
					var mc:DisplayObjectContainer = mcDO as DisplayObjectContainer;
					var numC:int = mc.numChildren;
					for(var i:int = 0;i<numC;i++){
						var child:DisplayObject = mc.getChildAt(i);
						list.splice((index+i+1),0,child);
					}
				}
				index++;
			}
			
			var steps:int = 0;
			var lastmcDO:DisplayObject = null;
			var indexes:Array = new Array();
			var wasHiding:Boolean;
			for (var X:String in list){
				mcDO = list[X];
				if(lastmcDO){
					if(lastmcDO is DisplayObjectContainer && (lastmcDO as DisplayObjectContainer).contains(mcDO)){
						steps++;
						//indexes.push((lastmcDO as DisplayObjectContainer).getChildIndex(mcDO));
						indexes.push(mcDO.name);
					}else{
						while(lastmcDO){
							lastmcDO = lastmcDO.parent;
							if(lastmcDO is DisplayObjectContainer){
								if(steps>0){
									indexes.pop();
									steps--;
								}
								if((lastmcDO as DisplayObjectContainer).contains(mcDO)){
									steps++;
									indexes.push(mcDO.name);
									break;
								}
							}
						}
					}
				}
				var str:String = "";
				for(i=0;i<steps;i++){
					str += (i==steps-1)?" ∟ ":" - ";
				}
				if(maxstep<=0 || steps<=maxstep){
					wasHiding = false;
					var n:String = "<a href='event:clip_"+basestr+indexes.join(Console.MAPPING_SPLITTER)+"'>"+mcDO.name+"</a>";
					if(mcDO is DisplayObjectContainer){
						n = "<b>"+n+"</b>";
					}else{
						n = "<i>"+n+"</i>";
					}
					str += n+" ("+getQualifiedClassName(mcDO)+")";
					report(str,mcDO is DisplayObjectContainer?5:2);
				}else if(!wasHiding){
					wasHiding = true;
					report(str+"...",5);
				}
				lastmcDO = mcDO;
			}
			_mapBaseIndex++;
			report(base.name+":"+getQualifiedClassName(base)+" has "+list.length+" children/sub-children.", 10);
			report("Click on the name to return a reference to the child clip. <br/>Note that clip references will be broken when display list is changed",-2);
		}
		public function reMap(path:String, mc:DisplayObjectContainer = null):void{
			var pathArr:Array = path.split(Console.MAPPING_SPLITTER);
			if(!mc){
				var first:String = pathArr.shift();
				if(first == "0"){
					mc = _master.stage;
				}else{
					mc = _mapBases[first];
				}
			}
			var child:DisplayObject = mc as DisplayObject;
			try{
				for each(var nn:String in pathArr){
					if(!nn) break;
					child = mc.getChildByName(nn);
					if(child is DisplayObjectContainer){
						mc = child as DisplayObjectContainer;;
					}else{
						// assume it reached to end since there can no longer be a child
						break;
					}
				}
				doReturn(child);
			} catch (e:Error) {
				report("Problem getting the clip reference. Display list must have changed since last map request",10);
				//debug(e.getStackTrace());
			}
		}
		private function printHelp():void {
			report("____Command Line Help___",10);
			report("/filter (text) = filter/search logs for matching text",5);
			report("// = return to previous scope",5);
			report("/base = return to base scope (same as typing $base)",5);
			report("/store (name) = store current scope to that name (default is weak reference). to call back: $(name)",5);
			report("/savestrong (name) = store current scope as strong reference",5);
			report("/stored = list all stored variables",5);
			report("/inspect = get info of your current scope.",5);
			report("/inspectfull = get more detailed info of your current scope.",5);
			report("/map = get the display list map starting from your current scope",5);
			report("/strong true = turn on strong referencing, you need to turn this on if you want to start manipulating with instances that are newly created.",5);
			report("/string = return the param of this command as a string. This is useful if you want to paste a block of text to use in commandline.",5);
			report("Press up/down arrow keys to recall previous commands",2);
			report("__Examples:",10);
			report("<b>stage.width</b>",5);
			report("<b>stage.scaleMode = flash.display.StageScaleMode.NO_SCALE</b>",5);
			report("<b>stage.frameRate = 12</b>",5);
			report("__________",10);
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