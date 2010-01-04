/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
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
package com.luaye.console.view {
	import com.luaye.console.Console;
	import com.luaye.console.utils.Utils;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;

	public class RollerPanel extends AbstractPanel{
		
		private var _txtField:TextField;
		private var _base:DisplayObjectContainer;
		
		public function RollerPanel(m:Console) {
			super(m);
			name = Console.PANEL_ROLLER;
			init(60,100,false);
			_txtField = new TextField();
			_txtField.name = "rollerprints";
			_txtField.multiline = true;
			_txtField.autoSize = TextFieldAutoSize.LEFT;
			_txtField.styleSheet = style.css;
			_txtField.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			registerRollOverTextField(_txtField);
			_txtField.addEventListener(AbstractPanel.TEXT_LINK, onMenuRollOver, false, 0, true);
			registerDragger(_txtField);
			addChild(_txtField);
		}
		public function start(base:DisplayObjectContainer):void{
			_base = base;
			addEventListener(Event.ENTER_FRAME, _onFrame, false, 0, true);
		}
		public function capture():String{
			return getMapString(true);
		}
		private function onMenuRollOver(e:TextEvent):void{
			master.panels.tooltip(e.text?"Close":null, this);
		}
		private function _onFrame(e:Event):void{
			if(!_base.stage){
				close();
				return;
			}
			_txtField.htmlText = "<ro>"+getMapString()+"</ro>";
			_txtField.autoSize = TextFieldAutoSize.LEFT;
			_txtField.setSelection(0, 0);
			width = _txtField.width+4;
			height = _txtField.height;
		}
		private function getMapString(dolink:Boolean = false):String{
			var stg:Stage = _base.stage;
			var str:String = "";
			var objs:Array = stg.getObjectsUnderPoint(new Point(stg.mouseX, stg.mouseY));
			var stepMap:Dictionary = new Dictionary(true);
			if(objs.length == 0){
				objs.push(stg);// if nothing at least have stage.
			}
			for each(var child:DisplayObject in objs){
				var chain:Array = new Array(child);
				var par:DisplayObjectContainer = child.parent;
				while(par){
					chain.unshift(par);
					par = par.parent;
				}
				var len:uint = chain.length;
				for (var i:uint=0; i<len; i++){
					var obj:DisplayObject = chain[i];
					if(stepMap[obj] == undefined){
						stepMap[obj] = i;
						if(dolink) str+="<br/>";
						for(var j:uint = i;j>0;j--){
							str += j==1?" ∟":" -";
						}
						if(dolink){
							if(obj == stg){
								str +=  "<p3><a href='event:sclip_'><i>Stage</i></a> ["+stg.mouseX+","+stg.mouseY+"]</p3>";
							}else if(i == len-1){
								str +=  "<p5><a href='event:sclip_"+mapUpward(obj)+"'>"+obj.name+"("+Utils.shortClassName(obj)+")</a></p5>";
							}else {
								str +=  "<p2><a href='event:sclip_"+mapUpward(obj)+"'><i>"+obj.name+"("+Utils.shortClassName(obj)+")</i></a></p2>";
							}
						}else{
							if(obj == stg){
								str +=  "<menu> <a href=\"event:close\"><b>X</b></a></menu> <i>Stage</i> ["+stg.mouseX+","+stg.mouseY+"]<br/>";
							}else if(i == len-1){
								str +=  "<roBold>"+obj.name+"("+Utils.shortClassName(obj)+")</roBold>";
							}else {
								str +=  "<i>"+obj.name+"("+Utils.shortClassName(obj)+")</i><br/>";
							}
						}
					}
				}
			}
			return str;
		}
		private function mapUpward(mc:DisplayObject):String{
			var arr:Array = [mc.name];
			mc = mc.parent;
			while(mc && mc!=mc.stage){
				arr.push(mc.name);
				mc = mc.parent;
			}
			return arr.reverse().join(Console.MAPPING_SPLITTER);
		}
		public override function close():void {
			removeEventListener(Event.ENTER_FRAME, _onFrame);
			_base = null;
			super.close();
			master.panels.updateMenu(); // should be black boxed :/
		}
		protected function linkHandler(e:TextEvent):void{
			TextField(e.currentTarget).setSelection(0, 0);
			if(e.text == "close"){
				close();
			}
			e.stopPropagation();
		}
	}
}