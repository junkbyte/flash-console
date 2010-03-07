package com.luaye.console.core {
	import flash.net.SharedObject;

	/**
	 * @author LuAye
	 */
	public class UserData {
		
		private static const COMMANDLINE_HISTORY_KEY:String = "clhistory";
		
		private var _so:SharedObject;
		private var _data:Object = {};
		
		public function UserData(name:String, localPath:String = null){
			if(name){
				try{
					_so = SharedObject.getLocal(name, localPath);
					_data = _so.data;
				}catch(e:Error){
					
				}
			}
		}
		
		public function get commandLineHistory():Array{
			if(_data[COMMANDLINE_HISTORY_KEY] is Array){
				return _data[COMMANDLINE_HISTORY_KEY];
			}else{
				var a:Array = new Array();
				_data[COMMANDLINE_HISTORY_KEY] = a;
				return a;
			}
		}
		public function commandLineHistoryChanged():void{
			if(_so) _so.setDirty(COMMANDLINE_HISTORY_KEY);
		}
	}
}
