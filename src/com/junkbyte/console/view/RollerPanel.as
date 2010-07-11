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
package com.junkbyte.console.view {
	import com.junkbyte.console.Console;
	import com.junkbyte.console.KeyBind;
	import com.junkbyte.console.utils.ShortClassName;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.utils.Dictionary;	

	public class RollerPanel extends AbstractPanel{
		
		public static const NAME:String = "rollerPanel";
		
		private var _base:DisplayObjectContainer;
		
		private var _settingKey:Boolean;
		
		public function RollerPanel(m:Console) {
			super(m);
			name = NAME;
			init(60,100,false);
			txtField = makeTF("rollerprints");
			txtField.multiline = true;
			txtField.autoSize = TextFieldAutoSize.LEFT;
			registerTFRoller(txtField, onMenuRollOver, linkHandler);
			registerDragger(txtField);
			addChild(txtField);
		}
		public function start(base:DisplayObjectContainer):void{
			_base = base;
			addEventListener(Event.ENTER_FRAME, _onFrame);
			addEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
		}
		private function removeListeners(e:Event=null):void{
			removeEventListener(Event.ENTER_FRAME, _onFrame);
			removeEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
			if(stage) stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		public function capture():String{
			return getMapString(true);
		}
		private function _onFrame(e:Event):void{
			if(!_base.stage){
				close();
				return;
			}
			if(_settingKey){
				txtField.htmlText = "<w><menu>Press a key to set [ <a href=\"event:cancel\"><b>cancel</b></a> ]</menu></w>";
			}else{
				txtField.htmlText = "<s>"+getMapString()+"</s>";
				txtField.autoSize = TextFieldAutoSize.LEFT;
				txtField.setSelection(0, 0);
			}
			width = txtField.width+4;
			height = txtField.height;
		}
		private function getMapString(dolink:Boolean = false):String{
			var stg:Stage = _base.stage;
			var str:String = "";
			if(!dolink){
				var key:String = master.rollerCaptureKey?master.rollerCaptureKey.toString():"unassigned";
				str = "<menu> <a href=\"event:close\"><b>X</b></a></menu> Capture key: <menu><a href=\"event:capture\">"+key+"</a></menu><br/>";
			}
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
						for(var j:uint = i;j>0;j--){
							str += j==1?" ∟":" -";
						}
						if(dolink){
							if(obj == stg){
								str +=  "<p3><a href='event:sclip_'><i>Stage</i></a> ["+stg.mouseX+","+stg.mouseY+"]</p3><br/>";
							}else if(i == len-1){
								str +=  "<p5><a href='event:sclip_"+mapUpward(obj)+"'>"+obj.name+" ("+ShortClassName(obj)+")</a></p5><br/>";
							}else {
								str +=  "<p2><a href='event:sclip_"+mapUpward(obj)+"'><i>"+obj.name+" ("+ShortClassName(obj)+")</i></a></p2><br/>";
							}
						}else{
							if(obj == stg){
								str +=  "<p1><i>Stage</i> ["+stg.mouseX+","+stg.mouseY+"]</p1><br/>";
							}else if(i == len-1){
								str +=  "<p5>"+obj.name+" ("+ShortClassName(obj)+")</p5><br/>";
							}else {
								str +=  "<p2>"+obj.name+" ("+ShortClassName(obj)+")</p2><br/>";
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
			cancelCaptureKeySet();
			removeListeners();
			_base = null;
			super.close();
			master.panels.updateMenu(); // should be black boxed :/
		}
		private function onMenuRollOver(e:TextEvent):void{
			var txt:String = e.text?e.text.replace("event:",""):"";
			if(txt == "close"){
				txt = "Close";
			}else if(txt == "capture"){
				var key:KeyBind = master.rollerCaptureKey;
				if(key){
					txt = "Unassign key ::"+key.toString();
				}else{
					txt = "Assign key";
				}
			}else if(txt == "cancel"){
				txt = "Cancel assign key";
			}else{
				txt = null;
			}
			master.panels.tooltip(txt, this);
		}
		protected function linkHandler(e:TextEvent):void{
			TextField(e.currentTarget).setSelection(0, 0);
			if(e.text == "close"){
				close();
			}else if(e.text == "capture"){
				if(master.rollerCaptureKey){
					master.setRollerCaptureKey(null);
				}else{
					_settingKey = true;
					stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
				}
				master.panels.tooltip(null);
			}else if(e.text == "cancel"){
				cancelCaptureKeySet();
				master.panels.tooltip(null);
			}
			e.stopPropagation();
		}
		private function cancelCaptureKeySet():void{
			_settingKey = false;
			if(stage) stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		}
		private function keyDownHandler(e:KeyboardEvent):void{
			if(!e.charCode) return;
			var char:String = String.fromCharCode(e.charCode);
			cancelCaptureKeySet();
			master.setRollerCaptureKey(char, e.shiftKey, e.ctrlKey, e.altKey);
			master.panels.tooltip(null);
		}
	}
}