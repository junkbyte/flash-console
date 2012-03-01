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
package com.junkbyte.console.vos
{
	import com.junkbyte.console.core.Executer;

	import flash.utils.ByteArray;

	/**
	 * @private
	 */
	public class GraphInterest
	{

		private var _ref:WeakRef;
		public var _prop:String;

		private var _getValueMethod:Function;

		private var useExec:Boolean;
		public var key:String;
		public var col:Number;

		public function GraphInterest(keystr:String = "", color:Number = 0):void
		{
			col = color;
			key = keystr;
		}

		public function setObject(object:Object, property:String):Number
		{
			_ref = new WeakRef(object);
			_prop = property;
			_getValueMethod = getAppropriateGetValueMethod();

			return getCurrentValue();
		}

		public function setGetValueCallback(callback:Function):void
		{
			if (callback == null)
			{
				_getValueMethod = getAppropriateGetValueMethod();
			}
			else
			{
				_getValueMethod = callback;
			}
		}

		public function get obj():Object
		{
			return _ref != null ? _ref.reference : undefined;
		}

		public function get prop():String
		{
			return _prop;
		}

		public function getCurrentValue():Number
		{
			return _getValueMethod(this);
		}
		
		private function getAppropriateGetValueMethod():Function
		{
			if(_prop.search(/[^\w\d]/) >= 0)
			{
				return executerValueCallback;
			}
			return defaultValueCallback;
		}
		
		private function defaultValueCallback(graph:GraphInterest):Number
		{
			return obj[_prop];
		}

		private function executerValueCallback(graph:GraphInterest):Number
		{
			return Executer.Exec(obj, _prop);
		}

		//
		//
		//
		public function writeToBytes(bytes:ByteArray):void
		{
			bytes.writeUTF(key);
			bytes.writeUnsignedInt(col);
		}

		public static function FromBytes(bytes:ByteArray):GraphInterest
		{
			var interest:GraphInterest = new GraphInterest(bytes.readUTF(), bytes.readUnsignedInt());
			return interest;
		}
	}
}
