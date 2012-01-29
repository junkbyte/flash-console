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
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.utils.getQualifiedShortClassName;
	import com.junkbyte.console.vos.WeakObject;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	public class ConsoleReferencingModule extends ConsoleModule
	{

		/**
		 * Seconds in which object links should be hard referenced for.
		 * If you logged a temp object (object that is not referenced anywhere else), it will become a link in console.
		 * However it will get garbage collected almost straight away which prevents you from clicking on the object link.
		 * (You will normally get this message: "Reference no longer exists")
		 * This feature allow you to set how many seconds console should hard reference object logs.
		 * Example, if you set 120, you will get 2 mins guaranteed time that any object link will work since it first appeared.
		 * Default is 0, meaning everything is weak linked straight away.
		 * Recommend not to use too high numbers. possibly 120 (2 minutes) is max you should set.
		 *
		 * Example:
		 * <code>
		 * Cc.log("This is a temp object:", new Object());
		 * // if you click this link in run time, it'll most likely say 'no longer exist'.
		 * // However if you set objectHardReferenceTimer to 60, you will get AT LEAST 60 seconds before it become unavailable.
		 * </code>
		 */
		public var objectHardReferenceTimer:uint = 0;

		private var _refMap:WeakObject = new WeakObject();

		private var _refRev:Dictionary = new Dictionary(true);

		private var _refIndex:uint = 1;

		private var _prevBank:Array = new Array();

		private var _currentBank:Array = new Array();

		private var _msSinceWithdraw:uint;

		public function ConsoleReferencingModule()
		{
			super();
		}

		override protected function registeredToConsole():void
		{
			super.registeredToConsole();
			
			logger.processor.push(new ReferencingLogProcessor(logger));

			modules.ticker.addUpdateDataCallback(onUpdateData);
		}

		override protected function unregisteredFromConsole():void
		{
			super.unregisteredFromConsole();
			
			modules.ticker.removeUpdateDataCallback(onUpdateData);
		}

		protected function onUpdateData(msDelta:uint):void
		{
			if (_currentBank.length || _prevBank.length)
			{
				_msSinceWithdraw += msDelta;
				if (_msSinceWithdraw >= objectHardReferenceTimer * 1000)
				{
					_prevBank = _currentBank;
					_currentBank = new Array();
					_msSinceWithdraw = 0;
				}
			}
		}

		public function setLogRef(o:*):uint
		{
			var ind:uint = _refRev[o];
			if (!ind)
			{
				ind = _refIndex;
				_refMap[ind] = o;
				_refRev[o] = ind;
				if (objectHardReferenceTimer)
				{
					_currentBank.push(o);
				}
				_refIndex++;
				// Look through every 50th older _refMap ids and delete empty ones
				// 50s rather than all to be faster.
				var i:int = ind - 50;
				while (i >= 0)
				{
					if (_refMap[i] === null)
					{
						delete _refMap[i];
					}
					i -= 50;
				}
			}
			return ind;
		}

		public function getRefId(o:*):uint
		{
			return _refRev[o];
		}

		public function getRefById(ind:uint):*
		{
			return _refMap[ind];
		}

		public function makeString(o:*, prop:* = null, html:Boolean = false, maxlen:int = -1):String
		{
			var txt:String;
			try
			{
				var v:* = prop ? o[prop] : o;
			}
			catch (err:Error)
			{
				return "<p0><i>" + err.toString() + "</i></p0>";
			}
			if (v is Error)
			{
				var err:Error = v as Error;
				// err.getStackTrace() is not supported in non-debugger players...
				var stackstr:String = err.hasOwnProperty("getStackTrace") ? err.getStackTrace() : err.toString();
				if (stackstr)
				{
					return stackstr;
				}
				return err.toString();
			}
			else if (v is XML || v is XMLList)
			{
				return shortenString(EscHTML(v.toXMLString()), maxlen, o, prop);
			}
			else if (v is QName)
			{
				return String(v);
			}
			else if (v is Array || getQualifiedClassName(v).indexOf("__AS3__.vec::Vector.") == 0)
			{
				// note: using getQualifiedClassName for vector for backward compatibility
				// Need to specifically cast to string in array to produce correct results
				// e.g: new Array("str",null,undefined,0).toString() // traces to: str,,,0, SHOULD BE: str,null,undefined,0
				var str:String = "[";
				var len:int = v.length;
				var hasmaxlen:Boolean = maxlen >= 0;
				for (var i:int = 0; i < len; i++)
				{
					var strpart:String = makeString(v[i], null, false, maxlen);
					str += (i ? ", " : "") + strpart;
					maxlen -= strpart.length;
					if (hasmaxlen && maxlen <= 0 && i < len - 1)
					{
						str += ", " + genLinkString(o, prop, "...");
						break;
					}
				}
				return str + "]";
			}
			else if (v && typeof v == "object")
			{
				var add:String = "";
				if (v is ByteArray)
				{
					add = " position:" + v.position + " length:" + v.length;
				}
				else if (v is Date || v is Rectangle || v is Point || v is Matrix || v is Event)
				{
					add = " " + String(v);
				}
				else if (v is DisplayObject && v.name)
				{
					add = " " + v.name;
				}
				txt = "{" + genLinkString(o, prop, EscHTML(getQualifiedShortClassName(v) + add)) + "}";
			}
			else
			{
				if (v is ByteArray)
				{
					txt = "[ByteArray position:" + ByteArray(v).position + " length:" + ByteArray(v).length + "]";
				}
				else
				{
					txt = String(v);
				}
				if (!html)
				{
					return shortenString(EscHTML(txt), maxlen, o, prop);
				}
			}
			return txt;
		}

		public function makeRefTyped(v:*):String
		{
			if (v && typeof v == "object" && !(v is QName))
			{
				return "{" + genLinkString(v, null, EscHTML(getQualifiedShortClassName(v))) + "}";
			}
			return EscHTML(getQualifiedShortClassName(v));
		}

		public function genLinkString(o:*, prop:*, str:String):String
		{
			if (prop && !(prop is String))
			{
				o = o[prop];
				prop = null;
			}
			var ind:uint = setLogRef(o);
			if (ind)
			{
				return "<menu><a href='event:ref_" + ind + (prop ? ("_" + prop) : "") + "'>" + str + "</a></menu>";
			}
			else
			{
				return str;
			}
		}

		private function shortenString(str:String, maxlen:int, o:*, prop:* = null):String
		{
			if (maxlen >= 0 && str.length > maxlen)
			{
				str = str.substring(0, maxlen);
				return str + genLinkString(o, prop, " ...");
			}
			return str;
		}
	}
}
