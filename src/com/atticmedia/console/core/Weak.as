package com.atticmedia.console.core {
	import flash.utils.Dictionary;
	
	public class Weak {
		private var _dir:Object;
		
		public function Weak() {
			_dir = new Object();
		}
		
		
		public function set(n:String,obj:Object, strong:Boolean = false):void{
			if(obj == null){
				return;
			}
			var dic:Dictionary = new Dictionary(!strong);
			dic[obj] = null;
			_dir[n] = dic;
		}
		
		public function get(n:String):Object{
			if(_dir[n]){
				return extract(_dir[n]);
			}
			return null;
		}
		
		private function extract(dir:Dictionary):Object{
			//there should be only 1 key in it anyway
			for(var X:Object in dir){
				return X;
			}
			return null;
		}
	}
}