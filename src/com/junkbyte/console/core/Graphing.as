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
package com.junkbyte.console.core
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.GraphFPSGroup;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.GraphInterest;
	import com.junkbyte.console.vos.GraphMemoryGroup;
	
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	/**
	 * @private
	 */
	public class Graphing extends ConsoleCore
	{

		private var _groups:Array = [];
		private var _map:Object = {};

		private var _fpsGroup:GraphGroup;
		private var _memGroup:GraphGroup;

		private var _groupAddedDispatcher:CcCallbackDispatcher = new CcCallbackDispatcher();

		public function Graphing(m:Console)
		{
			super(m);
			
			remoter.addEventListener(Event.CONNECT, onRemoteConnection);
			
			
			/*
			remoter.registerCallback("fps", function(bytes:ByteArray):void
			{
				fpsMonitor = bytes.readBoolean();
			});
			remoter.registerCallback("mem", function(bytes:ByteArray):void
			{
				memoryMonitor = bytes.readBoolean();
			});
			remoter.registerCallback("removeGroup", function(bytes:ByteArray):void
			{
				removeGroupByName(bytes.readUTF());
			});
			remoter.registerCallback("graph", handleRemoteGraph, true);
			*/
		}

		private function onRemoteConnection(event:Event):void
		{
			var bytes:ByteArray = new ByteArray();
			bytes.writeShort(_groups.length);
			for each(var group:GraphGroup in _groups)
			{
				group.writeToBytes(bytes);
			}
			//remoter.send("graphGroups", bytes);
		}

		public function add(n:String, obj:Object, prop:String, col:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):GraphGroup
		{
			if (obj == null)
			{
				report("ERROR: Graph [" + n + "] received a null object to graph property [" + prop + "].", 10);
				return null;
			}
			var group:GraphGroup = _map[n];
			var newGroup:Boolean;
			if (!group)
			{
				newGroup = true;
				group = new GraphGroup(n);
			}
			var interests:Array = group.interests;
			if (isNaN(col) || col < 0)
			{
				if (interests.length <= 5)
				{
					col = config.style["priority" + (10 - interests.length * 2)];
				}
				else
				{
					col = Math.random() * 0xFFFFFF;
				}
			}
			if (key == null)
			{
				key = prop;
			}
			for each (var i:GraphInterest in interests)
			{
				if (i.key == key)
				{
					report("Graph with key [" + key + "] already exists in [" + n + "]", 10);
					return null;
				}
			}
			if (rect)
				group.rect = rect;
			if (inverse)
				group.inverted = inverse;
			var interest:GraphInterest = new GraphInterest(key, col);
			var v:Number = NaN;
			try
			{
				v = interest.setObject(obj, prop);
			}
			catch (e:Error)
			{
				report("Error with graph value for [" + key + "] in [" + n + "]. " + e, 10);
				return null;
			}
			if (isNaN(v))
			{
				report("Graph value for key [" + key + "] in [" + n + "] is not a number (NaN).", 10);
			}
			else
			{
				group.interests.push(interest);
				if (newGroup)
				{
					_map[n] = group;
					addGroup(group);
				}
			}
			return group;
		}

		public function remove(n:String, obj:Object = null, prop:String = null):void
		{
			if (obj == null && prop == null)
			{
				removeGroupByName(n);
			}
			else if (_map[n])
			{
				var interests:Array = _map[n].interests;
				for (var i:int = interests.length - 1; i >= 0; i--)
				{
					var interest:GraphInterest = interests[i];
					if ((obj == null || interest.obj == obj) && (prop == null || interest.prop == prop))
					{
						interests.splice(i, 1);
					}
				}
				if (interests.length == 0)
				{
					removeGroupByName(n);
				}
			}
		}

		private function removeGroupByName(n:String):void
		{
			/*if (remoter.remoting == Remoting.RECIEVER)
			{
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF(n);
				remoter.send("removeGroup", bytes);
			}
			else
			{*/
				var g:GraphGroup = _map[n];
				if (g)
				{
					removeGroup(g);
				}
			//}
		}

		public function get fpsMonitor():Boolean
		{
			return _fpsGroup != null;
		}

		public function set fpsMonitor(b:Boolean):void
		{
			/*if (remoter.remoting == Remoting.RECIEVER)
			{
				var bytes:ByteArray = new ByteArray();
				bytes.writeBoolean(b);
				remoter.send("fps", bytes);
			}
			else if (b != fpsMonitor)
			{*/
				if (b)
				{
					_fpsGroup = new GraphFPSGroup(console);
					_fpsGroup.addEventListener(Event.CLOSE, onFPSGroupClose);
					addGroup(_fpsGroup);
					
					console.panels.mainPanel.updateMenu();
				}
				else
				{
					_fpsGroup.close();
				}
			//}
		}
		
		private function onFPSGroupClose(event:Event):void
		{
			
			var group:GraphGroup = event.currentTarget as GraphGroup;
			group.removeEventListener(Event.CLOSE, onFPSGroupClose);
			_fpsGroup = null;
			
			console.panels.mainPanel.updateMenu();
		}

		//
		public function get memoryMonitor():Boolean
		{
			return _memGroup != null;
		}

		public function set memoryMonitor(b:Boolean):void
		{
			/*if (remoter.remoting == Remoting.RECIEVER)
			{
				var bytes:ByteArray = new ByteArray();
				bytes.writeBoolean(b);
				remoter.send("mem", bytes);
			}
			else if (b != memoryMonitor)
			{*/
				if (b)
				{
					_memGroup = new GraphMemoryGroup();
					_memGroup.addEventListener(Event.CLOSE, onMemGroupClose);
					addGroup(_memGroup);
					
					console.panels.mainPanel.updateMenu();
				}
				else
				{
					_memGroup.close();
				}
			//}
		}

		private function onMemGroupClose(event:Event):void
		{
			var group:GraphGroup = event.currentTarget as GraphGroup;
			group.removeEventListener(Event.CLOSE, onMemGroupClose);
			_memGroup = null;
			
			console.panels.mainPanel.updateMenu();
		}

		public function addGroupAddedListener(listener:Function):void
		{
			_groupAddedDispatcher.add(listener);
		}

		public function removeGroupAddedListener(listener:Function):void
		{
			_groupAddedDispatcher.remove(listener);
		}

		public function addGroup(group:GraphGroup):void
		{
			if (_groups.indexOf(group) < 0)
			{
				_groups.push(group);
				group.addEventListener(Event.CLOSE, onGroupClose);

				_groupAddedDispatcher.apply([group]);

				group.update();
			}
		}

		private function onGroupClose(event:Event):void
		{
			var group:GraphGroup = event.currentTarget as GraphGroup;

			removeGroup(group);
		}

		public function removeGroup(group:GraphGroup):void
		{
			group.removeEventListener(Event.CLOSE, onGroupClose);
			var index:int = _groups.indexOf(group);
			if (index >= 0)
			{
				_groups.splice(index, 1);
			}
		}

		public function update(timeDelta:uint, fps:Number = 0):void
		{
			for each (var group:GraphGroup in _groups)
			{
				group.tick(timeDelta);
			}
		}

		private function handleRemoteGraph(bytes:ByteArray = null):void
		{
			if (bytes && bytes.length)
			{
				bytes.position = 0;
				var a:Array = new Array();
				while (bytes.bytesAvailable)
				{
					a.push(GraphGroup.FromBytes(bytes));
				}
					//console.panels.updateGraphs(a);
			}
			else
			{
				//console.panels.updateGraphs(new Array());
			}
		}
	}
}
