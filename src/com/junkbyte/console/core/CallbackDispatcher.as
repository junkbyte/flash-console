package com.junkbyte.console.core
{

	public class CallbackDispatcher
	{

		private var _list:Array = new Array();

		public function add(listener:Object):void
		{
			_list.push(listener);
		}

		public function remove(listener:Object):void
		{
			var index:int = _list.indexOf(listener);
			if (index >= 0)
			{
				_list.splice(index, 1);
			}
		}
		
		public function get list():Array
		{
			return _list;
		}

		public function forEach(callback:Function):void
		{
			_list.forEach(callback);
		}
	}
}
