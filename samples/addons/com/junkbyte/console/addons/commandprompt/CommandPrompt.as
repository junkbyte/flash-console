package com.junkbyte.console.addons.commandprompt {
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	
	public class CommandPrompt {
		
		public var headerQuestion:String;
		public var defaultCallback:Function;
		
		protected var _console:Console;
		protected var _choices:Array = new Array();
		
		public function CommandPrompt(headerQuestion:String = null, defaultCB:Function = null, choices:Array = null){
			
			this.headerQuestion = headerQuestion;
			defaultCallback = defaultCB;
			if(choices){
				_choices = choices;
			}
		}
		
		public function addCmdChoice(cmdChoice:CommandChoice):void {
			_choices.push(cmdChoice);
		}
		
		public function start():void
		{
			var console:Console = getConsole();
			if (console) {
				console.config.commandLineInputPassThrough = commandLinePassThrough;
				print();
			}
		}
		
		protected function print():void{
			var console:Console = getConsole();
			if(headerQuestion){
				console.info(headerQuestion);
				
				for each (var choice:CommandChoice in _choices) {
					console.addHTML( "<b>"+choice.key+"</b>:", (choice.text ? choice.text : "" ) );
				}
				console.info(" ");
			}
		}
		
		protected function commandLinePassThrough(command:String):void
		{
			for each (var choice:CommandChoice in _choices) {
				if (choice.key.toLowerCase() == command.toLowerCase()) {
					getConsole().config.commandLineInputPassThrough = null;
					choice.callback(choice.key);
					return;
				}
			}
			if(defaultCallback != null){
				getConsole().config.commandLineInputPassThrough = null;
				defaultCallback(command);
			}
		}
		
		public function setConsole(targetC:Console):void{
			if(targetC) _console = targetC;
		}
		
		protected function getConsole():Console{
			if(_console) return _console;
			return Cc.instance;
		}
	}
}
