package {
	import com.bit101.components.HBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import com.bit101.components.VBox;
	import com.junkbyte.console.Cc;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	
	// REQUIRES: minimalcomps: http://www.minimalcomps.com/
	
	[SWF(width='700',height='400',backgroundColor='0xFFFFFF',frameRate='30')]
	public class ConsoleStressTest extends Sprite {
		
		
		private var linesPerFrame:HUISlider;
		private var wordsPerFrame:HUISlider;
		private var channelsCount:HUISlider;
		private var pauseButton:PushButton;
		
		private var timeSinceLastLine:int;
			
		public function ConsoleStressTest() {
			Cc.startOnStage(this);
			Cc.width = 700;
			Cc.height = 260;
			Cc.fpsMonitor = true;
			Cc.memoryMonitor = true;
			Cc.config.commandLineAllowed = true;
			Cc.remoting = true;
			Cc.config.remotingPassword = "";
			
			initComponents();
			addEventListener(Event.ENTER_FRAME, tick);
		}
		
		private function initComponents():void
		{
			new Label(this, 0, 384, "Using Minimal Comps");
			
			var hbox:HBox = new HBox(this, 10, 280);
			hbox.width = 380;
			
			
			var leftBox:VBox = new VBox(hbox);
			leftBox.width = 340;
			var rightBox:VBox = new VBox(hbox);
			rightBox.width = 340;
			
			linesPerFrame = new HUISlider(leftBox);
			linesPerFrame.label = "Logs per sec";
			linesPerFrame.width = 300;
			linesPerFrame.minimum = 0;
			linesPerFrame.maximum = 200;
			linesPerFrame.value = 20;
			
			wordsPerFrame = new HUISlider(leftBox);
			wordsPerFrame.label = "Words per line";
			wordsPerFrame.width = 200;
			wordsPerFrame.minimum = 5;
			wordsPerFrame.maximum = 200;
			wordsPerFrame.value = 25;
			
			channelsCount = new HUISlider(rightBox);
			channelsCount.label = "Number of channels";
			channelsCount.width = 200;
			channelsCount.minimum = 1;
			channelsCount.maximum = 50;
			channelsCount.value = 5;
			
			pauseButton = new PushButton(rightBox,0,0, "pause");
			pauseButton.toggle = true;
		}
		
		private function tick(e:Event):void{
			var thisTime:int = getTimer();
			var ms:int = thisTime-timeSinceLastLine;
			
			var lines:int = ((ms/1000)*linesPerFrame.value);
			if(lines){
				timeSinceLastLine = thisTime;
				
				if(!pauseButton.selected)
				{
					var maxwords:int = wordsPerFrame.value;
					var maxchs:int = channelsCount.value-1;
					
					while(lines){
						lines--;
						var str:String = "";
						for(var w:int = maxwords; w>0; w-=5){
							str += _wordSamples[Math.round(Math.random()*_wordSamples.length)];
						}
						Cc.ch("chn"+Math.round(Math.random()*maxchs), str, Math.round(Math.random()*10));
					}
				}
			}
		}
		
		
		private var _wordSamples:Array = new Array(
			"sed ut perspiciatis unde omnis ",
			"iste natus error sit voluptatem ",
			"accusantium doloremque laudantium, totam rem ",
			"eaque ipsa quae ab illo inventore ",
			"consectetur, adipisci velit, sed quia ",
			"temporibus autem quibusdam et aut ",
			"voluptatum deleniti atque corrupti quos ",
			"deserunt mollitia animi, id est",
			"molestias excepturi sint occaecati cupiditate",
			"est laborum et dolorum fuga",
			"nam libero tempore, cum soluta",
			"qui officia deserunt mollitia animi"
		);
		
		
		
	}
}
