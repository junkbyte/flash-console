package com.luaye.console.vos {
	import com.luaye.console.core.Executer;
	import com.luaye.console.vos.WeakRef;

	/**
	 * @author LuAye
	 */
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
			if(averaging>0) avg += ((v-avg)/averaging);
		}
		//
		//
		//
		public function toObject():Object{
			return {key:key, col:col, v:v, avg:avg};
		}
		public static function FromObject(o:Object):GraphInterest{
			var interest:GraphInterest = new GraphInterest(o.key, o.col);
			interest.v = o.v;
			interest.avg = o.avg;
			return interest;
		}
	}
}
