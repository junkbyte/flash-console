package com.junkbyte.console.addons.commandprompt {
	import com.junkbyte.console.Cc;
	import com.junkbyte.console.Console;
	
	public class CommandPrompt {
		
		public var ch : String = Console.CONSOLE_CHANNEL;
		public var headerQuestion:String;
		public var footerText:String;
		public var defaultCallback:Function;
		
		protected var _console:Console;
		protected var _choices:Array = new Array();
		
		private var _wasAutoCompleteEnabled:Boolean;
		private var _wasScopeShown:Boolean;
		
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
		
		public function start():void{
			if (console) {
				console.config.commandLineInputPassThrough = commandLinePassThrough;
				_wasAutoCompleteEnabled = console.config.commandLineAutoCompleteEnabled;
				_wasScopeShown = console.config.style.showCommandLineScope;
				console.config.commandLineAutoCompleteEnabled = false;
				console.config.style.showCommandLineScope = false;
				ask();
			}
		}
		
		protected function ask():void{
			if(headerQuestion){
				console.addHTMLch(ch, -2, "<b>" + headerQuestion + "</b>");
			}
			printChoices();
			if(footerText !== null){
				console.addHTMLch(ch, -2, footerText);
			}
		}
		
		protected function printChoices():void{
			for each (var choice:CommandChoice in _choices) {
				console.addHTMLch(ch, 4,  choice.toHTMLString());
			}
		}
		
		protected function commandLinePassThrough(command:String):void{
			for each (var choice:CommandChoice in _choices) {
				if (choice.key.toLowerCase() == command.toLowerCase()) {
					end();
					choice.callback(choice.key);
					return;
				}
			}
			if(defaultCallback != null){
				end();
				defaultCallback(command);
			}
		}
		
		protected function end():void{
			console.config.commandLineInputPassThrough = null;
			console.config.commandLineAutoCompleteEnabled = _wasAutoCompleteEnabled;
			console.config.style.showCommandLineScope = _wasScopeShown;
		}
		
		public function setConsole(targetC:Console):void{
			if(targetC) _console = targetC;
		}
		
		protected function get console():Console{
			if(_console) return _console;
			return Cc.instance;
		}
	}
}
