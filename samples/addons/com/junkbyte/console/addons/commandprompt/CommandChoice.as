package com.junkbyte.console.addons.commandprompt {
	
	public class CommandChoice {
		
		public var key:String;
		public var callback:Function;
		public var text:String;
		
		public function CommandChoice(choiceKey : String, selectionCallback:Function, txt : String = "") {
			key = choiceKey;
			callback = selectionCallback;
			text = txt;
		}
		
		public function toHTMLString():String{
			var txt:String = (text ? text : "" );
			if(key) return "&gt; <b>"+key+"</b>: " + txt;
			return txt ? txt : "[CommandChoice empty]";
		}
	}
}
