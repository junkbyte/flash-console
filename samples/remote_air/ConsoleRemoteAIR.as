/*
 * 
 * Copyright (c) 2008-2010 Lu Aye Oo
 * 
 * @author Lu Aye Oo
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
package {
	import com.junkbyte.console.Console;
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.addons.htmlexport.ConsoleHtmlExportAddon;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.remote.ConsoleRe;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.PanelsManager;
	
	import flash.display.MovieClip;
	import flash.display.NativeWindowDisplayState;
	import flash.display.NativeWindowResize;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.GlowFilter;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.text.TextField;

	public class ConsoleRemoteAIR extends MovieClip {
		
		private var console:Console;
		
		private var _serverSocket : ServerSocket;
		
		private var _autoClear:Boolean = true;

		public function ConsoleRemoteAIR() {
			
			console = new ConsoleRe();
			addChild(console);
			
			console.config.maxLines = 2000;
			console.config.style.backgroundAlpha = 0.55;
			console.config.commandLineAllowed = true;
			
			var panels:PanelsManager = console.panels;
			
			console.remoter.addEventListener(Event.CONNECT, onRemotingConnect);
			console.remoter.remoting = true;
			console.commandLine = true;
			console.x = 10;
			console.y = 10;
			console.addMenu("top", toggleOnTop, null, "Toggle always in front");
			console.addMenu("auto-clear", toggleAutoClear, null, "Toggle auto clear on new connection");
			
			ConsoleHtmlExportAddon.addToMenu("save");
			
			var menu : TextField = panels.mainPanel.getChildByName("menuField") as TextField;
			menu.doubleClickEnabled = true;
			menu.addEventListener(MouseEvent.DOUBLE_CLICK, ondouble);
			panels.mainPanel.addEventListener(ConsolePanel.DRAGGING_STARTED, moveHandle);
			panels.mainPanel.addEventListener(ConsolePanel.SCALING_STARTED, scaleHandle);

			console.filters = new Array(new GlowFilter(0, 0.7, 5, 5));

			panels.mainPanel.addEventListener(Event.CLOSE, onMainPanelClose);
			stage.frameRate = 60;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			onStageResize();
			
			console.addSlashCommand("listen", function (params:String = ""):void{
				var parts:Array = params.split(/\s+/);
				bindServer(parts[0], parts[1]);
			});
			console.cl.localCommands.push("listen");
			console.report("Use <b>/listen <i>ip port</i></b> command to listen to socket connection.", -2);
			console.report("Example <b>/listen 127.0.0.1 200</b> command to listen to socket connection.", -1);
		}

		private function onRemotingConnect(event:Event):void
		{
			if(_autoClear)
			{
				console.clear();
			}
		}
		
		private function toggleOnTop() : void {
			stage.nativeWindow.alwaysInFront = !stage.nativeWindow.alwaysInFront;
			console.report("Always in front " + (stage.nativeWindow.alwaysInFront ? "enabled." : "disabled"), -1);
		}
		
		private function toggleAutoClear() : void {
			_autoClear = !_autoClear;
			console.report("Auto clear on new connection " + (_autoClear ? "enabled." : "disabled"), -1);
		}

		private function onMainPanelClose(e : Event) : void {
			stage.nativeWindow.close();
		}

		private function saveToFile() : void {
			try {
				var docsDir : File = File.desktopDirectory;
				docsDir.browseForSave("Save Log As");
				docsDir.addEventListener(Event.SELECT, saveData);
			} catch (err : Error) {
				console.error("Failed:", err.message);
			}
		}

		private	function saveData(e : Event) : void {
			var file : File = e.target as File;
			if (!file.exists) {
				var path : String = file.nativePath;
				var dot : int = path.lastIndexOf(".");
				var separator : int = path.lastIndexOf(File.separator);
				if (dot < 0 || separator > dot) {
					file.nativePath = path + ".txt";
				}
			}
			var str : String = console.getAllLog(File.lineEnding);
			var stream : FileStream = new FileStream();
			try {
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(str);
				stream.close();
				console.report("Saved log to " + file.nativePath, -1);
			} catch(e : Error) {
				// maybe read-only , etc
				console.report("There was a problem saving the log to " + file.nativePath + "\n" + e, 10);
			}
		}

		private function ondouble(e : Event) : void {
			if (stage.nativeWindow.displayState != NativeWindowDisplayState.MAXIMIZED) {
				stage.nativeWindow.maximize();
			} else {
				stage.nativeWindow.restore();
			}
		}

		private function moveHandle(e : Event) : void {
			stage.nativeWindow.startMove();
		}

		private function scaleHandle(e : Event) : void {
			console.panels.mainPanel.stopScaling();
			stage.nativeWindow.startResize(NativeWindowResize.BOTTOM_RIGHT);
		}

		private function onStageResize(e : Event = null) : void {
			console.width = stage.stageWidth - 20;
			console.height = stage.stageHeight - 20;
		}

		public function bindServer(host : String, port : int) : void {
			if (_serverSocket && _serverSocket.bound) {
				_serverSocket.close();
			}
			_serverSocket = new ServerSocket();
			_serverSocket.bind(port, host);
			_serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
			_serverSocket.listen();
			console.report("Listening to: " + _serverSocket.localAddress + ":" + _serverSocket.localPort, -1);
		}

		private function onConnect(event : ServerSocketConnectEvent) : void {
			var clientSocket : Socket = event.socket;
			clientSocket.addEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData);
			console.report("Connection from " + clientSocket.remoteAddress + ":" + clientSocket.remotePort);
		}

		private function onClientSocketData(event : ProgressEvent) : void {
			var clientSocket : Socket = event.currentTarget as Socket;
			console.remoter.handleSocket(clientSocket);
		}
	}
}