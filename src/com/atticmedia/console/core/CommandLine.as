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
package com.atticmedia.console.core {
	import flash.system.Security;
	import flash.events.Event;

	import com.atticmedia.console.Console;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.EventDispatcher;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class CommandLine extends EventDispatcher {
		public static const CHANGED_SCOPE:String = "changedScope";
		
		private static const VALUE_CONST:String = "^";
		private static const MAX_INTERNAL_STACK_TRACE:int = 1;
		
		private var _saved:WeakObject;
		
		private var _returned:*;
		private var _returned2:*;
		private var _mapBases:WeakObject;
		private var _mapBaseIndex:uint = 1;
		private var _reserved:Array;
		private var _values:Array;
		
		private var _master:Console;
		
		public var useStrong:Boolean;
		private var _permission:uint = 1;

		public function CommandLine(m:Console) {
			_master = m;
			_saved = new WeakObject();
			_mapBases = new WeakObject();
			_returned = m;
			_saved.set("C", m);
			_reserved = new Array("base", "C");
		}
		public function set base(obj:Object):void {
			if (base) {
				report("Set new commandLine base from "+base+ " to "+ obj, 10);
			}else{
				_returned = obj;
				dispatchEvent(new Event(CHANGED_SCOPE));
			}
			_saved.set("base", obj, useStrong);
		}
		public function get base():Object {
			return _saved.get("base");
		}
		public function destory():void {
			_saved = null;
			_master = null;
			_reserved = null;
		}
		public function get permission():int{
			return _permission;
		}
		public function set permission(i:int):void{
			if(_values && i > _permission){
				// dont allow to change through command line...
				// TODO: This is not fool proof... 
				// You could make a new Console instance on top.. then get the new console's commandline to call the first console's commandline permission...
				throw new SecurityError("Can not lift CommandLine permission. You must set Console commandLinePermission in source code and recompile.", 10);
			}else
				_permission = i;
		}
		public function store(n:String, obj:Object, strong:Boolean = false):String {
			n = n.replace(/[^\w]*/g, "");
			if(_reserved.indexOf(n)>=0){
				report("ERROR: The name ["+n+"] is reserved",10);
				return null;
			}else{
				// if it is a function it needs to be strong reference atm, 
				// otherwise it fails if the function passed is from a dynamic class/instance
				_saved.set(n, obj, strong?true:(obj is Function?true:useStrong));
			}
			return n;
		}
		public function get scopeString():String{
			return Utils.shortClassName(_returned);
		}
		//
		//
		public function run(str:String):* {
			report("&gt; "+str,5, false);
			if(permission==0) {
				report("CommandLine is disabled.",10);
				return null;
			}
			if(str.charAt(0) == "/"){
				try{
					doCommand(str);
				}catch(e:Error){
					reportError(e);
				}
				return;
			}
			// incase you are calling a new command from commandLine... paradox?
			// EXAMPLE: $C.runCommand('/help') - but why would you?
			var isclean:Boolean = _values?false:true;
			if(isclean){
				_values = [];
			}
			// STRIP empty strings "",''
			var matchstring:String;
			var strReg:RegExp = /('')|("")/g;
			var result:Object = strReg.exec(str);
			while(result != null){
				var ind:int = result["index"];
				matchstring = result[0];
				str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, ind, ind+matchstring.length);
				_values.push(new Value("", "", matchstring));
				strReg.lastIndex = ind+1;
				result = strReg.exec(str);
			}
			// STRIP strings - '...' and "..." wihle ignoring \' \" inside.
			// have to do again after empty string strip because matching string got extra first char
			strReg = /([^\\]'(.*?[^\\])')|([^\\]"(.*?[^\\])")/g;
			result = strReg.exec(str);
			while(result != null){
				matchstring = result[0];
				var substring:String = result[2]?result[2]:result[4]?result[4]:"";
				var ind2:int = result["index"]+matchstring.indexOf(substring);
				strReg.lastIndex = ind2+1;
				str = Utils.replaceByIndexes(str, VALUE_CONST+_values.length, ind2-1, ind2+substring.length+1);
				//report(VALUE_CONST+_values.length+" = "+substring, 2, false);
				_values.push(new Value(substring));
				result = strReg.exec(str);
			}
			// All strings will have replaced by ^0, ^1, etc
			//
			// Run each line
			var v:* = null;
			var lineBreaks:Array = str.split(/\s*;\s*/);
			for each(var line:String in lineBreaks){
				if(line.length){
					v = runLine(line);
				}
			}
			if(isclean){
				_values = null;
			}
			return v;
		}
		// com.atticmedia.console.C.instance.visible
		// com.atticmedia.console.C.instance.addGraph('test',stage,'mouseX')
		// test('simple stuff. what ya think?');
		// test('He\'s cool! (not really)','',"yet 'another string', what ya think?");
		// this.getChildAt(0); 
		// stage.addChild(root.addChild(this.getChildAt(0)));
		// third(second(first('console'))).final(0).alpha;
		// getChildByName(String('Console')).getChildByName('message').alpha = 0.5;
		// getChildByName(String('Console').abcd().asdf).getChildByName('message').alpha = 0.5;
		// com.atticmedia.console.C.add('Hey how are you?');
		//
		private function runLine(line:String):*{
			try{
				var majorParts:Array = line.split(/\s*\=\s*/);
				majorParts.reverse();
				var v:Value = execChunk(majorParts[0]);
				for(var i:int = 1;i<majorParts.length;i++){
					var vtoset:Value = execChunk(majorParts[i]);
					//report("Target base = "+vtoset.base + " prop = "+vtoset.prop);
					vtoset.base[vtoset.prop] = v.value;
					report("<b>SET</b> "+getQualifiedClassName(vtoset.base)+"."+vtoset.prop+" = <b>"+v.value+"</b>", -2);
				}
				doReturn(v.value);
				return v.value;
			}catch(e:Error){
				reportError(e);
			}
			return null;
		}
		//
		// Nest. such as aaa.bbb(ccc.ddd().eee).fff().ggg
		//
		private function execChunk(line:String):Value{
			// exec values inside functions (params of functions)
			var indOpen:int = line.lastIndexOf("(");
			while(indOpen>0){
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
					line = Utils.replaceByIndexes(line, VALUE_CONST+_values.length, indOpen+1, indClose);
					var params:Array = inside.split(",");
					_values.push(new Value(params));
					for(var X:String in params){
						params[X] = execStrip(params[X].replace(/\s*(.+)\s*/,"$1")).value;
					}
					//report("^"+_values.length+" stores params ["+params+"]");
					//report(line);
				}
				indOpen = line.lastIndexOf("(", indOpen-1);
			}
			return execStrip(line);
		}
		//
		// Simple strip. such as aaa.bbb.ccc(1,2,3).ddd  
		// includes class path detection and 'new' operation
		//
		private function execStrip(str:String):Value{
			var v:Value = new Value();
			//
			// if it is 'new' operation
			if(str.indexOf("new ")==0){
				var newstr:String = str;
				var defclose:int = str.indexOf(")");
				if(defclose>=0){
					newstr = str.substring(0, defclose+1);
				}
				str = str.substring(newstr.length);
				str = str.replace(/\s*(.*)\s*/,"$1");// clean white space
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
						var def:* = getDefinitionByName(classstr);
						var havemore:Boolean = str.length>classstr.length;
						//report(classstr+" is a class "+def);
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
				var basestr:String = str.substring(previndex, index);
				//report("scopestr = "+basestr+ " v.base = "+v.base);
				var newv:Value = execValue(basestr, v.base);
				var newbase:* = newv.value;
				v.base = newv.base;
				//report("scope = "+newbase+"  isFun:"+isFun);
				if(isFun){
					var closeindex:int = str.indexOf(")", index);
					var paramstr:String = str.substring(index+1, closeindex);
					paramstr = paramstr.replace(/\s/g,"");
					var params:Array = [];
					if(paramstr){
						params = execValue(paramstr).value;
					}
					//report("params = "+params.length+" - ["+ params+"]");
					if(permission < 2 && (newbase == Security.allowDomain || newbase == Security.allowInsecureDomain)){
						throw new SecurityError("Not accessible due to low commandLinePermission. You must recompile client flash with Console commandLinePermission set to a higher level.");
						return null;
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
					//report("no more result: index="+index+" str.length="+str.length);
					//report("LEFT: "+str.substring(index+1, str.length));
					v.base = v.value;
					reg.lastIndex = str.length;
					result = {index:str.length};
				}
			}
			return v;
		}
		//
		// single values such as string, int, object, $a, ^1 and Classes without package.
		//
		private function execValue(str:String, base:* = null):Value{
			var nobase:Boolean = base?false:true;
			var v:Value = new Value(null, base, str);
			base = base?base:_returned;
			if(nobase && (!base || !base.hasOwnProperty(str))){
				if (str == "true") {
					v.value = true;
				}else if (str == "false") {
					v.value = false;
				}else if (str == "this") {
					v.base = _returned;
					v.value = _returned;
				}else if (str == "null") {
					v.value = null;
				}else if (str == "NaN") {
					v.value = NaN;
				}else if (!isNaN(Number(str))) {
					v.value = Number(str);
				}else if(str.indexOf(VALUE_CONST)==0){
					var vv:Value = _values[str.substring(VALUE_CONST.length)];
					//report(VALUE_CONST+str.substring(VALUE_CONST.length)+" = " +vv);
					v.base = vv.base;
					v.value = vv.value;
				}else if(str.charAt(0) == "$"){
					v.base = _saved[str.substring(1)];
					v.value = v.base;
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
			//report("value: "+str+" = "+getQualifiedClassName(v.value)+" - "+v.value+" base:"+v.base);
			return v;
		}
		//
		// make new instance
		//
		private function makeNew(str:String):*{
			//report("makeNew "+str);
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
				}else if(len==20){
					return new (def)(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16], p[17], p[18], p[19]);
				}
				// won't work with more than 20 arguments...
			}
			return new (def)();
		}
		private function doReturn(returned:*):void{
			var newb:Boolean = false;
			var typ:String = typeof(returned);
			if(returned && returned !== _returned && (typ == "object" || typ=="xml")){
				newb = true;
				_returned2 = _returned;
				_returned = returned;
				dispatchEvent(new Event(CHANGED_SCOPE));
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
			//report("doCommand: "+ cmd+(param?(": "+param):""));
			if (cmd == "help") {
				printHelp();
			} else if (cmd == "remap") {
				// this is a special case... no user will be able to do this command
				reMap(param);
			} else if (cmd == "strong") {
				if(param == "true"){
					useStrong = true;
					report("Now using STRONG referencing.", 10);
				}else if (param == "false"){
					useStrong = false;
					report("Now using WEAK referencing.", 10);
				}else if(useStrong){
					report("Using STRONG referencing. '/strong false' to use weak", -2);
				}else{
					report("Using WEAK referencing. '/strong true' to use strong", -2);
				}
			} else if (cmd == "save" || cmd == "store") {
				if (_returned) {
					if(!param){
						report("ERROR: Give a name to save.",10);
					}else if(_reserved.indexOf(param)>=0){
						report("ERROR: The name ["+param+ "] is reserved",10);
					}else{
						_saved.set(param, _returned,useStrong);
						report("SAVED "+getQualifiedClassName(_returned) + " at "+ param);
					}
				} else {
					report("Nothing to save", 10);
				}
			} else if (cmd == "string") {
				report("String with "+param.length+" chars stored. Use /save <i>(name)</i> to save.", -2);
				_returned = param;
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
			} else if (cmd == "filter") {
				_master.filterText = str.substring(8);
			} else if (cmd == "inspect" || cmd == "inspectfull") {
				if (_returned) {
					var viewAll:Boolean = (cmd == "inspectfull")? true: false;
					inspect(_returned,viewAll);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "map") {
				if (_returned) {
					map(_returned as DisplayObjectContainer);
				} else {
					report("Empty", 10);
				}
			} else if (cmd == "/") {
				doReturn(_returned2?_returned2:base);
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
		public function map(base:DisplayObjectContainer):void{
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
				var n:String = "<a href='event:clip_"+basestr+indexes.join(Console.MAPPING_SPLITTER)+"'>"+mcDO.name+"</a>";
				if(mcDO is DisplayObjectContainer){
					n = "<b>"+n+"</b>";
				}else{
					n = "<i>"+n+"</i>";
				}
				str += n+" ("+getQualifiedClassName(mcDO)+")";
				report(str,mcDO is DisplayObjectContainer?5:2);
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
				//reportStackTrace(e.getStackTrace());
			}
		}
		private function printHelp():void {
			report("____Command Line Help___",10);
			report("Gives you ability to read/write/execute properties and methods",0);
			report("__Example: ",10);
			report("root.mc => <b>root.mc</b>",5);
			report("(save mc's reference) => <b>/save mc</b>",5);
			report("(load mc's reference) => <b>$mc</b>",5);
			report("root.mc.myProperty => <b>$mc.myProperty</b>",5);
			report("root.mc.myProperty = \"newProperty\" => <b>$mc.myProperty = 'newProperty'</b>",5);
			report("(view info) => <b>/inspect</b>",5);
			report("(view all info) => <b>/inspectfull</b>",5);
			report("(see display map) => <b>/map</b>",5);
			report("__Filtering:",10);
			report("/filter &lt;text you want to filter&gt;",5);
			report("This will create a new channel called filtered with all matching lines",5);
			report("__Other useful examples:",10);
			report("<b>stage.width</b>",5);
			report("<b>stage.scaleMode = 'noScale'</b>",5);
			report("<b>stage.frameRate = 12</b>",5);
			report("__________",10);
		}
		public function report(obj:*,priority:Number = 1, skipSafe:Boolean = true):void{
			_master.report(obj, priority, skipSafe);
		}
	}
}
class Value{
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