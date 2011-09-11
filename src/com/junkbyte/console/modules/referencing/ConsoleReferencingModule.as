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

package com.junkbyte.console.modules.referencing 
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ConsoleModules;
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.vos.WeakObject;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;

	public class ConsoleReferencingModule extends ConsoleModule
	{
		
		private var _refMap:WeakObject = new WeakObject();
		private var _refRev:Dictionary = new Dictionary(true);
		private var _refIndex:uint = 1;
		
		private var _prevBank:Array = new Array();
		private var _currentBank:Array = new Array();
		private var _msSinceWithdraw:uint;
		
		public function ConsoleReferencingModule() {
			super();
		}
		
		override public function registeredToConsole(console:Console):void
		{
			super.registeredToConsole(console);
			console.addEventListener(ConsoleEvent.UPDATE_DATA, update);
		}
		
		override public function unregisteredFromConsole(console:Console):void
		{
			super.unregisteredFromConsole(console);
			console.removeEventListener(ConsoleEvent.UPDATE_DATA, update);
		}
		
		protected function update(event:ConsoleEvent):void
		{
			if(_currentBank.length || _prevBank.length){
				_msSinceWithdraw += event.msDelta;
				if(_msSinceWithdraw >= config.objectHardReferenceTimer*1000){
					_prevBank = _currentBank;
					_currentBank = new Array();
					_msSinceWithdraw = 0;
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
		
		public function genLinkString(o:*, prop:*, str:String):String{
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
