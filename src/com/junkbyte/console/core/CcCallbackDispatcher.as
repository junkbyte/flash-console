package com.junkbyte.console.core
{

	public class CcCallbackDispatcher
	{

		protected var _list:Array = new Array();

		public function add(callback:Function):void
		{
			if (_list.indexOf(callback) < 0)
			{
				_list.push(callback);
			}
		}

		public function remove(callback:Function):void
		{
			var index:int = _list.indexOf(callback);
			if (index >= 0)
			{
				_list.splice(index, 1);
			}
		}

		public function apply(arguments:Array = null):void
		{
			var len:uint = _list.length;
			for (var i:uint = 0; i < len; i++)
			{
				_list[i].apply(null, arguments);
			}
		}

		public function clear():void
		{
			_list.splice(0, _list.length);
		}
	}
}
