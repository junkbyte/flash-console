package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.console_internal;
	import com.junkbyte.console.core.Graphing;
	import com.junkbyte.console.vos.GraphGroup;
	
	import flash.events.Event;
	import flash.utils.ByteArray;

	use namespace console_internal;

	public class GraphingRemote extends Graphing
	{

		private var _closingFromRemoter:Boolean;

		public function GraphingRemote(m:Console)
		{
			super(m);

			remoter.registerCallback("graphGroups", onRemotingGraphGroups, true);
			remoter.registerCallback("addGraphGroup", onRemotingAddGraphGroup, true);
			remoter.registerCallback("removeGraphGroup", onRemotingRemoveGraphGroup, true);
			remoter.registerCallback("updateGraphGroup", onRemotingUpdateGraphGroup, true);
		}

		override protected function onRemoteConnection(event:Event):void
		{
			_closingFromRemoter = true;
			while (_groups.length)
			{
				GraphGroup(_groups[0]).close();
			}
			_closingFromRemoter = false;
		}

		override public function update(timeDelta:uint):void
		{

		}

		override protected function syncRemoveGroup(index:int):void
		{
			if (!_closingFromRemoter)
			{
				super.syncRemoveGroup(index);
			}
		}

		override protected function syncAddGroup(group:GraphGroup):void
		{

		}

		override protected function syncGroupUpdate(group:GraphGroup, values:Array):void
		{

		}

		override protected function onRemotingRemoveGraphGroup(bytes:ByteArray):void
		{
			_closingFromRemoter = true;
			super.onRemotingRemoveGraphGroup(bytes);
			_closingFromRemoter = false;
		}

		private function onRemotingGraphGroups(bytes:ByteArray):void
		{
			var count:uint = bytes.readShort();
			_groups = new Array();
			for (var i:uint = 0; i < count; i++)
			{
				addGroup(GraphGroup.FromBytes(bytes));
			}
		}

		private function onRemotingAddGraphGroup(bytes:ByteArray):void
		{
			var group:GraphGroup = GraphGroup.FromBytes(bytes);
			
			addGroup(group);
			
			group.onMenu.add(function (menukey:String):void
			{
				var index:int = _groups.indexOf(group);
				if (index >= 0)
				{
					syncMenuGroup(index, menukey);
				}
			}
			);
		}

		private function onRemotingUpdateGraphGroup(bytes:ByteArray):void
		{
			var index:uint = bytes.readShort();
			var group:GraphGroup = _groups[index];
			if (group)
			{
				var values:Array = new Array();
				while (bytes.bytesAvailable)
				{
					values.push(bytes.readDouble());
				}
				group.applyUpdateDispather(values);
			}
		}

		override public function set fpsMonitor(b:Boolean):void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeBoolean(b);
			remoter.send("fps", bytes);
		}

		override public function set memoryMonitor(b:Boolean):void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeBoolean(b);
			remoter.send("mem", bytes);
		}
		
		
		protected function syncMenuGroup(groupIndex:int, menuKey:String):void
		{
			if (remoter.connected)
			{
				var bytes:ByteArray = new ByteArray();
				bytes.writeShort(groupIndex);
				bytes.writeUTF(menuKey);
				remoter.send("menuGraphGroup", bytes);
			}
		}
	}
}
