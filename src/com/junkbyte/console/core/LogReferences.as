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
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.WeakObject;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * @private
	 */
	public class LogReferences extends ConsoleCore
	{
		
		public static const INSPECTING_CHANNEL:String = "⌂";
		
		private var _refMap:WeakObject = new WeakObject();
		private var _refRev:Dictionary = new Dictionary(true);
		private var _refIndex:uint = 1;
		
		private var _dofull:Boolean;
		private var _current:*;// current will be kept as hard reference so that it stays...
		
		private var _history:Array;
		private var _hisIndex:uint;
		
		private var _prevBank:Array = new Array();
		private var _currentBank:Array = new Array();
		private var _lastWithdraw:uint;
		
		public function LogReferences(console:Console) {
			super(console);
			
			remoter.registerCallback("ref", function(bytes:ByteArray):void{
				handleString(bytes.readUTF());
			});
			remoter.registerCallback("focus", handleFocused);
		}
		public function update(time:uint):void{
			if(_currentBank.length || _prevBank.length){
				if( time > _lastWithdraw+config.objectHardReferenceTimer*1000){
					_prevBank = _currentBank;
					_currentBank = new Array();
					_lastWithdraw = time;
				}
			}
		}
		public function setLogRef(o:*):uint{
			if(!config.useObjectLinking) return 0;
			var ind:uint = _refRev[o];
			if(!ind){
				ind = _refIndex;
				_refMap[ind] = o;
				_refRev[o] = ind;
				if(config.objectHardReferenceTimer)
				{
					_currentBank.push(o);
				}
				_refIndex++;
				// Look through every 50th older _refMap ids and delete empty ones
				// 50s rather than all to be faster.
				var i:int = ind-50;
				while(i>=0){
					if(_refMap[i] === null){
						delete _refMap[i];
					}
					i-=50;
				}
			}
			return ind;
		}
		public function getRefId(o:*):uint{
			return _refRev[o];
		}
		public function getRefById(ind:uint):*{
			return _refMap[ind];
		}
		public function makeString(o:*, prop:* = null, html:Boolean = false, maxlen:int = -1):String{
			var txt:String;
			try{
				var v:* = prop?o[prop]:o;
			}catch(err:Error){
				return "<p0><i>"+err.toString()+"</i></p0>";
			}
			if(v is Error) {
				var err:Error = v as Error;
				// err.getStackTrace() is not supported in non-debugger players...
				var stackstr:String = err.hasOwnProperty("getStackTrace")?err.getStackTrace():err.toString();		
				if(stackstr){
					return stackstr;
				}
				return err.toString();
			}else if(v is XML || v is XMLList){
				return shortenString(EscHTML(v.toXMLString()), maxlen, o, prop);
			}else if(v is QName){
				return String(v);
			}else if(v is Array || getQualifiedClassName(v).indexOf("__AS3__.vec::Vector.") == 0){
				// note: using getQualifiedClassName for vector for backward compatibility
				// Need to specifically cast to string in array to produce correct results
				// e.g: new Array("str",null,undefined,0).toString() // traces to: str,,,0, SHOULD BE: str,null,undefined,0
				var str:String = "[";
				var len:int = v.length;
				var hasmaxlen:Boolean = maxlen>=0;
				for(var i:int = 0; i < len; i++){
					var strpart:String = makeString(v[i], null, false, maxlen);
					str += (i?", ":"")+strpart;
					maxlen -= strpart.length;
					if(hasmaxlen && maxlen<=0 && i<len-1){
						str += ", "+genLinkString(o, prop, "...");
						break;
					}
				}
				return str+"]";
			}else if(config.useObjectLinking && v && typeof v == "object") {
				var add:String = "";
				if(v is ByteArray) add = " position:"+v.position+" length:"+v.length;
				else if(v is Date || v is Rectangle || v is Point || v is Matrix || v is Event) add = " "+String(v);
				else if(v is DisplayObject && v.name) add = " "+v.name;
				txt = "{"+genLinkString(o, prop, ShortClassName(v))+EscHTML(add)+"}";
			}else{
				if(v is ByteArray) txt = "[ByteArray position:"+ByteArray(v).position+" length:"+ByteArray(v).length+"]";
				else txt = String(v);
				if(!html){
					return shortenString(EscHTML(txt), maxlen, o, prop);
				}
			}
			return txt;
		}
		public function makeRefTyped(v:*):String{
			if(v && typeof v == "object" && !(v is QName)){
				return "{"+genLinkString(v, null, ShortClassName(v))+"}";
			}
			return ShortClassName(v);
		}
		private function genLinkString(o:*, prop:*, str:String):String{
			if(prop && !(prop is String)) {
				o = o[prop];
				prop = null;
			}
			var ind:uint = setLogRef(o);
			if(ind){
				return "<menu><a href='event:ref_"+ind+(prop?("_"+prop):"")+"'>"+str+"</a></menu>";
			}else{
				return str;
			}
		}
		private function shortenString(str:String, maxlen:int, o:*, prop:* = null):String{
			if(maxlen>=0 && str.length > maxlen) {
				str = str.substring(0, maxlen);
				return str+genLinkString(o, prop, " ...");
			}
			return str;
		}
		private function historyInc(i:int):void{
			_hisIndex+=i;
			var v:* = _history[_hisIndex];
			if(v){
				focus(v, _dofull);
			}
		}
		public function handleRefEvent(str:String):void{
			if(remoter.remoting == Remoting.RECIEVER){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF(str);
				remoter.send("ref", bytes);
			}else{
				handleString(str);
			}
		}
		private function handleString(str:String):void{
			if(str == "refexit"){
				exitFocus();
				console.setViewingChannels();
			}else if(str == "refprev"){
				historyInc(-2);
			}else if(str == "reffwd"){
				historyInc(0);
			}else if(str == "refi"){
				focus(_current, !_dofull);
			}else{
				var ind1:int = str.indexOf("_")+1;
				if(ind1>0){
					var id:uint;
					var prop:String = "";
					var ind2:int = str.indexOf("_", ind1);
					if(ind2>0){
						id = uint(str.substring(ind1, ind2));
						prop = str.substring(ind2+1);
					}else{
						id = uint(str.substring(ind1));
					}
					var o:Object = getRefById(id);
					if(prop) o = o[prop];
					if(o){
						if(str.indexOf("refe_")==0){
							console.explodech(console.panels.mainPanel.reportChannel, o);
						}else{
							focus(o, _dofull);
						}
						return;
					}
				}
				report("Reference no longer exist (garbage collected).", -2);
			}
		}
		public function focus(o:*, full:Boolean = false):void{
			remoter.send("focus");
			console.clear(LogReferences.INSPECTING_CHANNEL);
			console.setViewingChannels(LogReferences.INSPECTING_CHANNEL);
			
			if(!_history) _history = new Array();
			
			if(_current != o){
				_current = o; // current is kept as hard reference so that it stays...
				if(_history.length <= _hisIndex) _history.push(o);
				else _history[_hisIndex] = o;
				_hisIndex++;
			}
			_dofull = full;
			inspect(o, _dofull);
		}
		private function handleFocused():void{
			console.clear(LogReferences.INSPECTING_CHANNEL);
			console.setViewingChannels(LogReferences.INSPECTING_CHANNEL);
		}
		public function exitFocus():void{
			_current = null;
			_dofull = false;
			_history = null;
			_hisIndex = 0;
			if(remoter.remoting == Remoting.SENDER){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF("refexit");
				remoter.send("ref", bytes);
			}
			console.clear(LogReferences.INSPECTING_CHANNEL);
		}
		
		
		public function inspect(obj:*, viewAll:Boolean= true, ch:String = null):void {
			if(!obj){
				report(obj, -2, true, ch);
				return;
			}
			var refIndex:uint = setLogRef(obj);
			var showInherit:String = "";
			if(!viewAll) showInherit = " [<a href='event:refi'>show inherited</a>]";
			var menuStr:String;
			if(_history){
				menuStr = "<b>[<a href='event:refexit'>exit</a>]";
				if(_hisIndex>1){
					menuStr += " [<a href='event:refprev'>previous</a>]";
				}
				if(_history && _hisIndex < _history.length){
					menuStr += " [<a href='event:reffwd'>forward</a>]";
				}
				menuStr += "</b> || [<a href='event:ref_"+refIndex+"'>refresh</a>]";
				menuStr += "</b> [<a href='event:refe_"+refIndex+"'>explode</a>]";
				if(config.commandLineAllowed){
					menuStr += " [<a href='event:cl_"+refIndex+"'>scope</a>]";
				}
				
				if(viewAll) menuStr += " [<a href='event:refi'>hide inherited</a>]";
				else menuStr += showInherit;
				report(menuStr, -1, true, ch);
				report("", 1, true, ch);
			}
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
			var isClass:Boolean = obj is Class;
			var st:String = isClass?"*":"";
			var str:String = "<b>{"+st+genLinkString(obj, null, EscHTML(self))+st+"}</b>";
			var props:Array = [];
			var nodes:XMLList;
			if(V.@isStatic=="true"){
				props.push("<b>static</b>");
			}
			if(V.@isDynamic=="true"){
				props.push("dynamic");
			}
			if(V.@isFinal=="true"){
				props.push("final");
			}
			if(props.length > 0){
				str += " <p-1>"+props.join(" | ")+"</p-1>";
			}
			report(str, -2, true, ch);
			//
			// extends...
			//
			nodes = V.extendsClass;
			if(nodes.length()){
				props = [];
				for each (var extendX:XML in nodes) {
					st = extendX.@type.toString();
					props.push(st.indexOf("*")<0?makeValue(getDefinitionByName(st)):EscHTML(st));
					if(!viewAll) break;
				}
				report("<p10>Extends:</p10> "+props.join(" &gt; "), 1, true, ch);
			}
			//
			// implements...
			//
			nodes = V.implementsInterface;
			if(nodes.length()){
				props = [];
				for each (var implementX:XML in nodes) {
					props.push(makeValue(getDefinitionByName(implementX.@type.toString())));
				}
				report("<p10>Implements:</p10> "+props.join(", "), 1, true, ch);
			}
			report("", 1, true, ch);
			//
			// events
			// metadata name="Event"
			props = [];
			nodes = V.metadata.(@name == "Event");
			if(nodes.length()){
				for each (var metadataX:XML in nodes) {
					var mn:XMLList = metadataX.arg;
					var en:String = mn.(@key=="name").@value;
					var et:String = mn.(@key=="type").@value;
					if(refIndex) props.push("<a href='event:cl_"+refIndex+"_dispatchEvent(new "+et+"(\""+en+"\"))'>"+en+"</a><p0>("+et+")</p0>");
					else props.push(en+"<p0>("+et+")</p0>");
				}
				report("<p10>Events:</p10> "+props.join("<p-1>; </p-1>"), 1, true, ch);
				report("", 1, true, ch);
			}
			//
			// display's parents and direct children
			//
			if (obj is DisplayObject) {
				var disp:DisplayObject = obj as DisplayObject;
				var theParent:DisplayObjectContainer = disp.parent;
				if (theParent) {
					props = new Array("@"+theParent.getChildIndex(disp));
					while (theParent) {
						var pr:DisplayObjectContainer = theParent;
						theParent = theParent.parent;
						var indstr:String = theParent?"@"+theParent.getChildIndex(pr):"";
						props.push("<b>"+pr.name+"</b>"+indstr+makeValue(pr));
					}
					report("<p10>Parents:</p10> "+props.join("<p-1> -> </p-1>")+"<br/>", 1, true, ch);
				}
			}
			if (obj is DisplayObjectContainer) {
				props = [];
				var cont:DisplayObjectContainer = obj as DisplayObjectContainer;
				var clen:int = cont.numChildren;
				for (var ci:int = 0; ci<clen; ci++) {
					var child:DisplayObject = cont.getChildAt(ci);
					props.push("<b>"+child.name+"</b>@"+ci+makeValue(child));
				}
				if(clen){
					report("<p10>Children:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 1, true, ch);
				}
			}
			//
			// constants...
			//
			props = [];
			nodes = clsV..constant;
			for each (var constantX:XML in nodes) {
				report(" const <p3>"+constantX.@name+"</p3>:"+constantX.@type+" = "+makeValue(cls, constantX.@name.toString())+"</p0>", 1, true, ch);
			}
			if(nodes.length()){
				report("", 1, true, ch);
			}
			var inherit:uint = 0;
			var hasstuff:Boolean;
			var isstatic:Boolean;
			//
			// methods
			//
			props = [];
			nodes = clsV..method; // '..' to include from <factory>
			for each (var methodX:XML in nodes) {
				if(viewAll || self==methodX.@declaredBy){
					hasstuff = true;
					isstatic = methodX.parent().name()!="factory";
					str = " "+(isstatic?"static ":"")+"function ";
					var params:Array = [];
					var mparamsList:XMLList = methodX.parameter;
					for each(var paraX:XML in mparamsList){
						params.push(paraX.@optional=="true"?("<i>"+paraX.@type+"</i>"):paraX.@type);
					}
					if(refIndex && (isstatic || !isClass)){
						str += "<a href='event:cl_"+refIndex+"_"+methodX.@name+"()'><p3>"+methodX.@name+"</p3></a>";
					}else{
						str += "<p3>"+methodX.@name+"</p3>";
					}
					str += "("+params.join(", ")+"):"+methodX.@returnType;
					report(str, 1, true, ch);
				}else{
					inherit++;
				}
			}
			if(inherit){
				report("   \t + "+inherit+" inherited methods."+showInherit, 1, true, ch);
			}else if(hasstuff){
				report("", 1, true, ch);
			}
			//
			// accessors
			//
			hasstuff = false;
			inherit = 0;
			props = [];
			nodes = clsV..accessor; // '..' to include from <factory>
			for each (var accessorX:XML in nodes) {
				if(viewAll || self==accessorX.@declaredBy){
					hasstuff = true;
					isstatic = accessorX.parent().name()!="factory";
					str = " ";
					if(isstatic) str += "static ";
					var access:String = accessorX.@access;
					if(access == "readonly") str+= "get";
					else if(access == "writeonly") str+= "set";
					else str += "assign";
					
					if(refIndex && (isstatic || !isClass)){
						str += " <a href='event:cl_"+refIndex+"_"+accessorX.@name+"'><p3>"+accessorX.@name+"</p3></a>:"+accessorX.@type;
					}else{
						str += " <p3>"+accessorX.@name+"</p3>:"+accessorX.@type;
					}
					if(access != "writeonly" && (isstatic || !isClass))
					{
						str += " = "+makeValue(isstatic?cls:obj, accessorX.@name.toString());
					}
					report(str, 1, true, ch);
				}else{
					inherit++;
				}
			}
			if(inherit){
				report("   \t + "+inherit+" inherited accessors."+showInherit, 1, true, ch);
			}else if(hasstuff){
				report("", 1, true, ch);
			}
			//
			// variables
			//
			nodes = clsV..variable;
			for each (var variableX:XML in nodes) {
				isstatic = variableX.parent().name()!="factory";
				str = isstatic?" static":"";
				if(refIndex) str += " var <p3><a href='event:cl_"+refIndex+"_"+variableX.@name+" = '>"+variableX.@name+"</a>";
				else str += " var <p3>"+variableX.@name;
				str += "</p3>:"+variableX.@type+" = "+makeValue(isstatic?cls:obj, variableX.@name.toString());
				report(str, 1, true, ch);
			}
			//
			// dynamic values
			// - It can sometimes fail if we are looking at proxy object which havnt extended nextNameIndex, nextName, etc.
			try{
				props = [];
				for (var X:* in obj) {
					if(X is String){
						if(refIndex) str = "<a href='event:cl_"+refIndex+"_"+X+" = '>"+X+"</a>";
						else str = X;
						report(" dynamic var <p3>"+str+"</p3> = "+makeValue(obj, X), 1, true, ch);
					}else{
						report(" dictionary <p3>"+makeValue(X)+"</p3> = "+makeValue(obj, X), 1, true, ch);
					}
				}
			} catch(e : Error) {
				report("Could not get dynamic values. " + e.message, 9, false, ch);
			}
			if(obj is String){
				report("", 1, true, ch);
				report("String", 10, true, ch);
				report(EscHTML(obj), 1, true, ch);
			}else if(obj is XML || obj is XMLList){
				report("", 1, true, ch);
				report("XMLString", 10, true, ch);
				report(EscHTML(obj.toXMLString()), 1, true, ch);
			}
			if(menuStr){
				report("", 1, true, ch);
				report(menuStr, -1, true, ch);
			}
		}
		public function getPossibleCalls(obj:*):Array{
			var list:Array = new Array();
			var V:XML = describeType(obj);
			var nodes:XMLList = V.method;
			for each (var methodX:XML in nodes) {
				var params:Array = [];
				var mparamsList:XMLList = methodX.parameter;
				for each(var paraX:XML in mparamsList){
					params.push(paraX.@optional=="true"?("<i>"+paraX.@type+"</i>"):paraX.@type);
				}
				list.push([methodX.@name+"(", params.join(", ")+" ):"+methodX.@returnType]);
			}
			nodes = V.accessor;
			for each (var accessorX:XML in nodes) {
				list.push([String(accessorX.@name), String(accessorX.@type)]);
			}
			nodes = V.variable;
			for each (var variableX:XML in nodes) {
				list.push([String(variableX.@name), String(variableX.@type)]);
			}
			return list;
		}
		private function makeValue(obj:*, prop:* = null):String{
			return makeString(obj, prop, false, config.useObjectLinking?100:-1);
		}
		
		
		public static function EscHTML(str:String):String{
			return str.replace(/</g, "&lt;").replace(/\>/g, "&gt;").replace(/\x00/g, "");
		}
		/*public static function UnEscHTML(str:String):String{
	 		return str.replace(/&lt;/g, "<").replace(/&gt;/g, ">");
		}*/
		/** 
		 * Produces class name without package path
		 * e.g: flash.display.Sprite => Sprite
		 */	
		public static function ShortClassName(obj:Object, eschtml:Boolean = true):String{
			var str:String = getQualifiedClassName(obj);
			var ind:int = str.indexOf("::");
			var st:String = obj is Class?"*":"";
			str = st+str.substring(ind>=0?(ind+2):0)+st;
			if(eschtml) return EscHTML(str);
			return str;
		}
	}
}
