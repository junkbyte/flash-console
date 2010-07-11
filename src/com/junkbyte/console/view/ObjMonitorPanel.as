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
	import com.junkbyte.console.core.CommandLine;
	
	import flash.events.TextEvent;
	import flash.text.TextField;		

	public class ObjMonitorPanel extends AbstractPanel{
		
		private var _menuField:TextField;
		private var _scroller:TextScroller;
		
		private var _hasPrevious:Boolean;
		
		public var id:String;
		
		public function ObjMonitorPanel(m:Console) {
			super(m);
			
			txtField = makeTF("monitorField");
			txtField.name = "monitorField";
			txtField.y = m.config.menuFontSize;
			txtField.wordWrap = true;
			txtField.multiline = true;
			txtField.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			registerDragger(txtField);
			addChild(txtField);
			
			_menuField = makeTF("menuField");
			_menuField.height = m.config.menuFontSize+6;
			_menuField.y = -2;
			registerTFRoller(_menuField, onMenuRollOver, linkHandler);
			registerDragger(_menuField);
			addChild(_menuField);
			
			_scroller = new TextScroller(txtField, config.controlColor);
			_scroller.y = config.menuFontSize;
			addChild(_scroller);
			
			updateMenu();
			init(160,100,true);
		}
		public override function set width(n:Number):void{
			_scroller.x = n;
			_menuField.width = n;
			txtField.width = n-8;
			super.width = n;
		}
		public override function set height(n:Number):void{
			_scroller.height = n - config.menuFontSize-12;
			txtField.height = n - config.menuFontSize;
			super.height = n;
		}
		private function updateMenu():void{
			_menuField.htmlText = "<w><menu> <b><a href=\"event:close\">X</a></b>"+(_hasPrevious?" | <a href=\"event:out\">previous</a>":"")+"</menu></w>";
		}
		public function update(obj:Object):void{
			txtField.mouseEnabled = true;
			var str:String = "<w>";
			for(var X:String in obj){
				str += "<p-2><a href=\"event:n_"+X+"\">"+X+"</a></p-2>=<p-1><a href=\"event:o_"+X+"\">"+obj[X]+"</a></p-1><br/>";
			}
			txtField.htmlText = str+"</w>";
		}
		private function onMenuRollOver(e:TextEvent):void{
			var txt:String = e.text?e.text.replace("event:",""):"";
			if(txt == "close"){
				txt = "Close";
			}else if(txt == "out"){
				txt = "Previous object";
			}else{
				txt = null;
			}
			master.panels.tooltip(txt, this);
		}
		protected function linkHandler(e:TextEvent):void{
			if(e.text == "close"){
				master.unmonitor(id);
			}else if(e.text == "out"){
				txtField.mouseEnabled = false;
				master.monitorOut(id);
			}else if(e.text.substring(0,2) == "n_"){
				master.panels.mainPanel.commandLineText = "$"+CommandLine.MONITORING_OBJ_KEY+"('"+id+"')."+e.text.substring(2);
			}else if(e.text.substring(0,2) == "o_"){
				_hasPrevious = true;
				txtField.mouseEnabled = false;
				master.monitorIn(id, e.text.substring(2));
				updateMenu();
			}
			txtField.setSelection(0, 0);
			e.stopPropagation();
		}
	}
}