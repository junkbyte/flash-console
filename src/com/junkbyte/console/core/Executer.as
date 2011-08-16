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
	import com.junkbyte.console.vos.WeakObject;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getDefinitionByName;

	public class Executer extends EventDispatcher{
		
		public static const RETURNED:String = "returned";
		public static const CLASSES:String = "ExeValue|((com.junkbyte.console.core::)?Executer)";
		
		public static function Exec(scope:Object, str:String, saved:Object = null):*{
			var e:Executer = new Executer();
			e.setStored(saved);
			return e.exec(scope, str);
		}
		
		
		private static const VALKEY:String = "#";
		
		private var _values:Array;
		private var _running:Boolean;
		private var _scope:*;
		private var _returned:*;
		
		private var _saved:Object;
		private var _reserved:Array;
		
		public var autoScope:Boolean;
		
		public function get returned():*{
			return _returned;
		}
		public function get scope():*{
			return _scope;
		}
		public function setStored(o:Object):void{
			_saved = o;
		}
		public function setReserved(a:Array):void{
			_reserved = a;
		}
		
		// TEST CASES...
		// com.junkbyte.console.Cc.instance.visible
		// com.junkbyte.console.Cc.instance.addGraph('test',stage,'mouseX')
		// trace('simple stuff. what ya think?');
		// $C.error('He\'s cool! (not really)','',"yet 'another string', what ya think?");
		// this.getChildAt(0); 
		// stage.addChild(root.addChild(this.getChildAt(0)));
		// getChildByName(new String('Console')).getChildByName('mainPanel').alpha = 0.5
		// com.junkbyte.console.Cc.add('Hey how are you?');
		// new Array(11,22,33,44,55,66,77,88,99).1 // should return 22
		// new Array(11,22,33,44,55,66,77,88,99);/;1 // should be 1
		// new Array(11,22,33,44,55,66,77,88,99);/;this.1 // should be 22
		// new XML("<t a=\"A\"><b>B</b></t>").attribute("a")
		// new XML("<t a=\"A\"><b>B</b></t>").b
		public function exec(s:*, str:String):*{
			if(_running) throw new Error("CommandExec.exec() is already runnnig. Does not support loop backs.");
			_running = true;
			_scope = s;
			_values = [];
			if(!_saved) _saved = new Object();
			if(!_reserved) _reserved = new Array();
			try{
				_exec(str);
			}catch (e:Error){
				reset();
				throw e;
			}
			reset();
			return _returned;
		}
		private function reset():void{
			_saved = null;
			_reserved = null;
			_values = null;
			_running = false;
		}
		private function _exec(str:String):void{
			//
			// STRIP strings - '...', "...", '', "", while ignoring \' \" etc inside.
			var strReg:RegExp = /''|""|('(.*?)[^\\]')|("(.*?)[^\\]")/;
			var result:Object = strReg.exec(str);
			while(result != null){
				var match:String = result[0];
				var quote:String = match.charAt(0);
				var start:int = match.indexOf(quote);
				var end:int = match.lastIndexOf(quote);
				var string:String = match.substring(start+1,end).replace(/\\(.)/g, "$1");
				//trace(VALUE_CONST+_values.length+" = "+string);
				str = tempValue(str,new ExeValue(string), result.index+start, result.index+end+1);
				//trace(str);
				result = strReg.exec(str);
			}
			//
			// All strings will have replaced by #0, #1, etc
			if(str.search(new RegExp('\'|\"'))>=0){
				throw new Error('Bad syntax extra quotation marks');
			}
			//
			// Run each line
			var lineBreaks:Array = str.split(/\s*;\s*/);
			for each(var line:String in lineBreaks){
				if(line.length){
					var returned:* = _saved[RETURNED];
					if(returned && line == "/"){
						_scope = returned;
						dispatchEvent(new Event(Event.COMPLETE));
					}else{
						execNest(line);
					}
				}
			}
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
						//trace("#"+_values.length+" stores function params ["+params+"]");
						line = tempValue(line,new ExeValue(params), indOpen+1, indClose);
						for(var X:String in params){
							params[X] = execOperations(ignoreWhite(params[X])).value;
						}
					}else{
						var groupv:ExeValue = new ExeValue(groupv);
						//trace("#"+_values.length+" stores group value for "+inside);
						line = tempValue(line,groupv, indOpen, indClose+1);
						groupv.setValue(execOperations(ignoreWhite(inside)).value);
					}
					
					//trace(line);
				}
				indOpen = line.lastIndexOf("(", indOpen-1);
			}
			_returned = execOperations(line).value;
			if(_returned && autoScope){
				var typ:String = typeof(_returned);
				if(typ == "object" || typ=="xml"){
					_scope = _returned;
				}
			}
			dispatchEvent(new Event(Event.COMPLETE));
			return _returned;
		}
		private function tempValue(str:String,v:*, indOpen:int, indClose:int):String{
			//trace("tempValue", VALUE_CONST+_values.length, " = "+str);
			str = str.substring(0,indOpen)+VALKEY+_values.length+str.substring(indClose);
			_values.push(v);
			return str;
		}
		//
		// Simple strip with operations.
		// aaa.bbb.ccc(1/2,3).ddd += fff+$g.hhh();
		//
		private function execOperations(str:String):ExeValue{
			var reg:RegExp = /\s*(((\|\||\&\&|[+|\-|*|\/|\%|\||\&|\^]|\=\=?|\!\=|\>\>?\>?|\<\<?)\=?)|=|\~|\sis\s|typeof|delete\s)\s*/g;
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
						seq.push(ignoreWhite(operation));
						seq.push(str.substring(index+operation.length));
					}else{
						seq.push(str.substring(lastindex, index));
						seq.push(ignoreWhite(operation));
						lastindex = index+operation.length;
					}
				}
			}
			//trace("execOperations: "+seq);
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
					res = operate(seq[i-1], op, seq[i+1]);
					//debug("operate: "+seq[i-1].value, op, seq[i+1].value, "=", res);
					var sv:ExeValue = ExeValue(seq[i-1]);
					sv.setValue(res);
					seq.splice(i,2);
					i-=2;
					len-=2;
				}
			}
			// EXEC setter operations after reversing the sequence
			seq.reverse();
			var v:ExeValue = seq[0];
			for(i = 1;i<len;i+=2){
				op = seq[i];
				if(op.replace(setter,"")==""){
					v = seq[i-1];
					var subject:ExeValue = seq[i+1];
					if(op.length>1) op = op.substring(0,op.length-1);
					res = operate(subject, op, v);
					subject.setValue(res);
				}
			}
			return v;
		}
		//
		// Simple strip
		// aaa.bbb.ccc(0.5,3).ddd
		// includes class path detection and 'new' operation
		//
		private function execSimple(str:String):ExeValue{
			var v:ExeValue = new ExeValue(_scope);
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
				str = tempValue(str, new ExeValue(newobj), 0, newstr.length);
			}
			//
			//
			var reg:RegExp = /\.|\(/g;
			var result:Object = reg.exec(str);
			if(result==null || !isNaN(Number(str))){
				return execValue(str, _scope);
			}
			//
			// AUTOMATICALLY detect classes in packages
			var firstparts:Array = String(str.split("(")[0]).split(".");
			if(firstparts.length>0){
				while(firstparts.length){
					var classstr:String = firstparts.join(".");
					try{
						var def:* = getDefinitionByName(ignoreWhite(classstr));
						var havemore:Boolean = str.length>classstr.length;
						//trace(classstr+" is a definition:", def);
						str = tempValue(str, new ExeValue(def), 0, classstr.length);
						//trace(str);
						if(havemore){
							reg.lastIndex = 0;
							result = reg.exec(str);
						}else{
							return execValue(str);
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
			//trace("str = "+str);
			while(result != null){
				var index:int = result.index;
				var isFun:Boolean = str.charAt(index)=="(";
				var basestr:String = ignoreWhite(str.substring(previndex, index));
				//trace("_scopestr = "+basestr+ " v.base = "+v.value);
				var newv:ExeValue = previndex==0?execValue(basestr, v.value):new ExeValue(v.value, basestr);
				//trace("_scope = "+newv.value+"  isFun:"+isFun);
				if(isFun){
					var newbase:* = newv.value;
					var closeindex:int = str.indexOf(")", index);
					var paramstr:String = str.substring(index+1, closeindex);
					paramstr = ignoreWhite(paramstr);
					var params:Array = [];
					if(paramstr){
						params = execValue(paramstr).value;
					}
					//debug("params = "+params.length+" - ["+ params+"]");
					// this is because methods in stuff like XML/XMLList got AS3 namespace.
					if(!(newbase is Function)){
						try{
							var nss:Array = [AS3];
							for each(var ns:Namespace in nss){
								var nsv:* = v.obj.ns::[basestr];
								if(nsv is Function){
									newbase = nsv;
									break;
								}
							}
						}catch(e:Error){
							// Will throw below...
						}
						if(!(newbase is Function)){
							throw new Error(basestr+" is not a function.");
						}
					}
					//trace("Apply function:", newbase, v.base, params);
					v.obj = (newbase as Function).apply(v.value, params);
					v.prop = null;
					//trace("Function return:", v.base);
					index = closeindex+1;
				}else{
					v = newv;
				}
				previndex = index+1;
				reg.lastIndex = index+1;
				result = reg.exec(str);
				if(result != null){
					//v.base = v.value;
				}else if(index+1 < str.length){
					//v.base = v.value;
					reg.lastIndex = str.length;
					result = {index:str.length};
				}
			}
			return v;
		}
		//
		// single values such as string, int, null, $a, ^1 and Classes without package.
		//
		private function execValue(str:String, base:* = null):ExeValue{
			var v:ExeValue = new ExeValue();
			if (str == "true") {
				v.obj = true;
			}else if (str == "false") {
				v.obj = false;
			}else if (str == "this") {
				v.obj = _scope;
			}else if (str == "null") {
				v.obj = null;
			}else if (!isNaN(Number(str))) {
				v.obj = Number(str);
			}else if(str.indexOf(VALKEY)==0){
				var vv:ExeValue = _values[str.substring(VALKEY.length)];
				v.obj = vv.value;
			}else if(str.charAt(0) == "$"){
				var key:String = str.substring(1);
				if(_reserved.indexOf(key)<0){
					v.obj = _saved;
					v.prop = key;
				}else if(_saved is WeakObject){
					v.obj = WeakObject(_saved).get(key);
				}else {
					v.obj = _saved[key];
				}
			}else{
				try{
					v.obj = getDefinitionByName(str);
				}catch(e:Error){
					v.obj = base;
					v.prop = str;
				}
			}
			//debug("value: "+str+" = "+getQualifiedClassName(v.value)+" - "+v.value+" base:"+v.base);
			return v;
		}
		// * typed cause it could be String +  OR comparison such as || or &&
		private function operate(v1:ExeValue, op:String, v2:ExeValue):*{
			switch (op){
				case "=":
					return v2.value;
				case "+":
					return v1.value+v2.value;
				case "-":
					return v1.value-v2.value;
				case "*":
					return v1.value*v2.value;
				case "/":
					return v1.value/v2.value;
				case "%":
					return v1.value%v2.value;
				case "^":
					return v1.value^v2.value;
				case "&":
					return v1.value&v2.value;
				case ">>":
					return v1.value>>v2.value;
				case ">>>":
					return v1.value>>>v2.value;
				case "<<":
					return v1.value<<v2.value;
				case "~":
					return ~v2.value;
				case "|":
					return v1.value|v2.value;
				case "!":
					return !v2.value;
				case ">":
					return v1.value>v2.value;
				case ">=":
					return v1.value>=v2.value;
				case "<":
					return v1.value<v2.value;
				case "<=":
					return v1.value<=v2.value;
				case "||":
					return v1.value||v2.value;
				case "&&":
					return v1.value&&v2.value;
				case "is":
					return v1.value is v2.value;
				case "typeof":
					return typeof v2.value;
				case "delete":
					return delete v2.obj[v2.prop];
				case "==":
					return v1.value==v2.value;
				case "===":
					return v1.value===v2.value;
				case "!=":
					return v1.value!=v2.value;
				case "!==":
					return v1.value!==v2.value;
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
				paramstr = ignoreWhite(paramstr);
				var p:Array = [];
				if(paramstr){
					p = execValue(paramstr).value;
				}
				var len:int = p.length;
				//
				// HELP! how do you construct an object with unknown number of arguments?
				// calling a function with multiple arguments can be done by fun.apply()... but can't for constructor :(
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
				}else {
					throw new Error("CommandLine can't create new class instances with more than 10 arguments.");
				}
				// won't work with more than 10 arguments...
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
	}
}
internal class ExeValue{
	public var obj:*;
	public var prop:String;
	
	public function ExeValue(b:Object = null, p:String = null):void{
		obj = b;
		prop = p;
	}
	public function get value():*{
		return prop?obj[prop]:obj;
	}
	public function setValue(v:*):void{
		if(prop) obj[prop] = v;
		else obj = v;
	}
}