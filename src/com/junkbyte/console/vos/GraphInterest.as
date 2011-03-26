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
*/package com.junkbyte.console.vos {
	import flash.utils.ByteArray;
	import com.junkbyte.console.core.Executer;
	import com.junkbyte.console.vos.WeakRef;

	public class GraphInterest {
		
		private var _ref:WeakRef;
		public var _prop:String;
		private var useExec:Boolean;
		public var key:String;
		public var col:Number;
		public var v:Number;
		public var avg:Number;
		
		public function GraphInterest(keystr:String ="", color:Number = 0):void{
			col = color;
			key = keystr;
		}
		public function setObject(object:Object, property:String):Number{
			_ref = new WeakRef(object);
			_prop = property;
			useExec = _prop.search(/[^\w\d]/) >= 0;
			//
			v = getCurrentValue();
			avg = v;
			return v;
		}
		public function get obj():Object{
			return _ref!=null?_ref.reference:undefined;
		}
		public function get prop():String{
			return _prop;
		}
		//
		//
		//
		public function getCurrentValue():Number{
			return useExec?Executer.Exec(obj, _prop):obj[_prop];
		}
		public function setValue(val:Number, averaging:uint = 0):void{
			v = val;
			if(averaging>0)
			{
				if(isNaN(avg))
				{
					avg = v;
				}
				else
				{
					avg += ((v-avg)/averaging);
				}
			}
		}
		//
		//
		//
		public function toBytes(bytes:ByteArray):void{
			bytes.writeUTF(key);
			bytes.writeUnsignedInt(col);
			bytes.writeDouble(v);
			bytes.writeDouble(avg);
		}
		public static function FromBytes(bytes:ByteArray):GraphInterest{
			var interest:GraphInterest = new GraphInterest(bytes.readUTF(), bytes.readUnsignedInt());
			interest.v = bytes.readDouble();
			interest.avg = bytes.readDouble();
			return interest;
		}
	}
}
