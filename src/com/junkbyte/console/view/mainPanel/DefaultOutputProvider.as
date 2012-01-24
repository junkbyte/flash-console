package com.junkbyte.console.view.mainPanel
{
	import com.junkbyte.console.ConsoleChannels;
	import com.junkbyte.console.core.CallbackDispatcher;
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.vos.Log;

	public class DefaultOutputProvider extends ConsoleModule implements ConsoleOutputProvider
	{
		protected var outputUpdateDispatcher:CallbackDispatcher = new CallbackDispatcher();

		public function DefaultOutputProvider()
		{
		}

		public function getFullOutput():String
		{
			var str:String = "";
			var line:Log = console.logger.logs.last;
			var showch:Boolean = console.mainPanel.viewingChannels.length != 1;
			var lineShouldShow:Function = console.mainPanel.lineShouldShow;
			while (line)
			{
				if (lineShouldShow(line))
				{
					str = makeLine(line, showch) + str;
				}
				line = line.prev;
			}
			return str;
		}

		public function getOutputFromBottom(maxLines:uint, maxChars:uint):String
		{
			var lines:Array = new Array();
			var linesLeft:int = maxLines;

			var line:Log = console.logger.logs.last;
			var showch:Boolean = console.mainPanel.viewingChannels.length != 1;
			var lineShouldShow:Function = console.mainPanel.lineShouldShow;
			while (line)
			{
				if (lineShouldShow(line))
				{
					lines.push(makeLine(line, showch));
					var numlines:int = Math.ceil(line.text.length / maxChars);
					linesLeft -= numlines;
					if (linesLeft <= 0)
					{
						break;
					}
				}
				line = line.prev;
			}
			return lines.reverse().join("");
		}

		public function addUpdateCallback(callback:Function):void
		{
			outputUpdateDispatcher.add(callback);
		}

		public function removeUpdateCallback(callback:Function):void
		{
			outputUpdateDispatcher.remove(callback);
		}

		public function changed():void
		{
			outputUpdateDispatcher.apply();
		}

		private function makeLine(line:Log, showch:Boolean):String
		{
			var str:String = "";
			var txt:String = line.text;
			if (showch && line.channel != ConsoleChannels.DEFAULT)
			{
				txt = "[<a href=\"event:channel_" + line.channel + "\">" + line.channel + "</a>] " + txt;
			}
			var ptag:String = "p" + line.priority;
			str += "<p><" + ptag + ">" + txt + "</" + ptag + "></p>";
			return str;
		}
	}
}
