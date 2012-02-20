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
package com.junkbyte.console.core {
	import flash.utils.ByteArray;
	import com.junkbyte.console.Console;
	import flash.system.System;
	import flash.utils.getTimer;

	import com.junkbyte.console.vos.GraphInterest;
	import com.junkbyte.console.vos.GraphGroup;

	import flash.geom.Rectangle;
	
	/**
	 * @private
	 */
	public class Graphing extends ConsoleCore{
		
		private var _groups:Array = [];
		private var _map:Object = {};
		
		private var _fpsGroup:GraphGroup;
		private var _memGroup:GraphGroup;
		
		private var _hadGraph:Boolean;
		private var _previousTime:Number = -1;
		
		public function Graphing(m:Console){
			super(m);
			remoter.registerCallback("fps", function(bytes:ByteArray):void{
				fpsMonitor = bytes.readBoolean();
			});
			remoter.registerCallback("mem", function(bytes:ByteArray):void{
				memoryMonitor = bytes.readBoolean();
			});
			remoter.registerCallback("removeGroup", function(bytes:ByteArray):void{
				removeGroup(bytes.readUTF());
			});
			remoter.registerCallback("graph", handleRemoteGraph, true);
			
		}
		public function add(n:String, obj:Object, prop:String, col:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void{
			if(obj == null) {
				report("ERROR: Graph ["+n+"] received a null object to graph property ["+prop+"].", 10);
				return;
			}
			var group:GraphGroup = _map[n];
			var newGroup:Boolean;
			if(!group) {
				newGroup = true;
				group = new GraphGroup(n);
			}
			var interests:Array = group.interests;
			if (isNaN(col) || col < 0) {
				if (interests.length <= 5) col = config.style["priority"+ (10-interests.length*2)];
				else col = Math.random()*0xFFFFFF;
			}
			if(key == null) key = prop;
			for each(var i:GraphInterest in interests){
				if(i.key == key){
					report("Graph with key ["+key+"] already exists in ["+n+"]", 10);
					return;
				}
			}
			if(rect) group.rect = rect;
			if(inverse) group.inv = inverse;
			var interest:GraphInterest = new GraphInterest(key, col);
			var v:Number = NaN;
			try{
				v = interest.setObject(obj, prop);
			}catch (e:Error){
				report("Error with graph value for ["+key+"] in ["+n+"]. "+e, 10);
				return;
			}
			if(isNaN(v)){
				report("Graph value for key ["+key+"] in ["+n+"] is not a number (NaN).", 10);
			}else{
				group.interests.push(interest);
				if(newGroup){
					_map[n] = group;
					_groups.push(group);
				}
			}
		}

		public function fixRange(n:String, low:Number = NaN, high:Number = NaN):void{
			var group:GraphGroup = _map[n];
			if(!group) return;
			group.low = low;
			group.hi = high;
			group.fixed = !(isNaN(low)||isNaN(high));
		}
		public function remove(n:String, obj:Object = null, prop:String = null):void{
			if(obj==null&&prop==null){	
				removeGroup(n);
			}else if(_map[n]){
				var interests:Array = _map[n].interests;
				for(var i:int = interests.length-1;i>=0;i--){
					var interest:GraphInterest = interests[i];
					if((obj == null || interest.obj == obj) && (prop == null || interest.prop == prop)){
						interests.splice(i, 1);
					}
				}
				if(interests.length==0){
					removeGroup(n);
				}
			}
		}
		private function removeGroup(n:String):void{
			if(remoter.remoting == Remoting.RECIEVER) {
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF(n);
				remoter.send("removeGroup", bytes);
			}else{
				var g:GraphGroup = _map[n];
				var index:int = _groups.indexOf(g);
				if(index>=0) _groups.splice(index, 1);
				delete _map[n];
			}
		}
		public function get fpsMonitor():Boolean{
			if(remoter.remoting == Remoting.RECIEVER) return console.panels.fpsMonitor;
			return _fpsGroup!=null;
		}
		public function set fpsMonitor(b:Boolean):void{
			if(remoter.remoting == Remoting.RECIEVER) {
				var bytes:ByteArray = new ByteArray();
				bytes.writeBoolean(b);
				remoter.send("fps", bytes);
			}else if(b != fpsMonitor){
				if(b) {
					_fpsGroup = addSpecialGroup(GraphGroup.FPS);
					_fpsGroup.low = 0;
					_fpsGroup.fixed = true;
					_fpsGroup.averaging = 30;
				} else{
					_previousTime = -1;
					var index:int = _groups.indexOf(_fpsGroup);
					if(index>=0) _groups.splice(index, 1);
					_fpsGroup = null;
				}
				console.panels.mainPanel.updateMenu();
			}
		}
		//
		public function get memoryMonitor():Boolean{
			if(remoter.remoting == Remoting.RECIEVER) return console.panels.memoryMonitor;
			return _memGroup!=null;
		}
		public function set memoryMonitor(b:Boolean):void{
			if(remoter.remoting == Remoting.RECIEVER) {
				var bytes:ByteArray = new ByteArray();
				bytes.writeBoolean(b);
				remoter.send("mem", bytes);
			}else if(b != memoryMonitor){
				if(b) {
					_memGroup = addSpecialGroup(GraphGroup.MEM);
					_memGroup.freq = 20;
				} else{
					var index:int = _groups.indexOf(_memGroup);
					if(index>=0) _groups.splice(index, 1);
					_memGroup = null;
				}
				console.panels.mainPanel.updateMenu();
			}
		}
		private function addSpecialGroup(type:int):GraphGroup{
			var group:GraphGroup = new GraphGroup("special");
			group.type = type;
			_groups.push(group);
			var graph:GraphInterest = new GraphInterest("special");
			if(type == GraphGroup.FPS) {
				graph.col = 0xFF3333;
			}else{
				graph.col = 0x5060FF;
			}
			group.interests.push(graph);
			return group;
		}
		public function update(fps:Number = 0):Array{
			var interest:GraphInterest;
			var v:Number;
			for each(var group:GraphGroup in _groups){
				var ok:Boolean = true;
				if(group.freq>1){
					group.idle++;
					if(group.idle<group.freq){
						ok = false;
					}else{
						group.idle = 0;
					}
				}
				if(ok){
					var typ:uint = group.type;
					var averaging:uint = group.averaging;
					var interests:Array = group.interests;
					if(typ == GraphGroup.FPS){
						group.hi = fps;
						interest = interests[0];
						var time:int = getTimer();
						if(_previousTime >= 0){
							var mspf:Number = time-_previousTime;
							v = 1000/mspf;
							interest.setValue(v, averaging);
						}
						_previousTime = time;
					}else if(typ == GraphGroup.MEM){
						interest = interests[0];
						v = Math.round(System.totalMemory/10485.76)/100;
						group.updateMinMax(v);
						interest.setValue(v, averaging);
					}else{
						updateExternalGraphGroup(group);
					}
				}
			}
			if(remoter.canSend && (_hadGraph || _groups.length)){
				var len:uint = _groups.length;
				var ga:ByteArray = new ByteArray();
				for(var j:uint = 0; j<len; j++){
					GraphGroup(_groups[j]).toBytes(ga);
				}
				remoter.send("graph", ga);
				_hadGraph = _groups.length>0;
			}
			return _groups;
		}
		
		private function updateExternalGraphGroup(group:GraphGroup):void
		{
			for each(var i:GraphInterest in group.interests){
				try{
					var v:Number = i.getCurrentValue();
					i.setValue(v, group.averaging);
				}catch(e:Error){
					report("Error with graph value for key ["+i.key+"] in ["+group.name+"]. "+e, 10);
					remove(group.name, i.obj, i.prop);
				}
				group.updateMinMax(v);
			}
		}
		
		private function handleRemoteGraph(bytes:ByteArray = null):void{
			if(bytes && bytes.length){
				bytes.position = 0;
				var a:Array = new Array();
				while(bytes.bytesAvailable){
					a.push(GraphGroup.FromBytes(bytes));
				}
				console.panels.updateGraphs(a);
			}else{
				console.panels.updateGraphs(new Array());
			}
		}
	}
}