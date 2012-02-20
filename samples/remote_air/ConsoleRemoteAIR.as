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
	import flash.events.ProgressEvent;
	import flash.net.Socket;

	import com.junkbyte.console.Console;
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.core.Remoting;
	import com.junkbyte.console.view.ConsolePanel;

	import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.display.NativeWindowDisplayState;
	import flash.display.NativeWindowResize;

	public class ConsoleRemoteAIR extends MovieClip {
		private var _c : Console;
		private var _serverSocket : ServerSocket;

		public function ConsoleRemoteAIR() {
			var config : ConsoleConfig = new ConsoleConfig();
			config.maxLines = 2000;
			config.style.backgroundAlpha = 0.55;
			config.commandLineAllowed = true;
			_c = new Console(null, config);
			addChild(_c);
			_c.visible = true;
			_c.remoter.remoting = Remoting.RECIEVER;
			_c.commandLine = true;
			_c.x = 10;
			_c.y = 10;
			_c.addMenu("top", toggleOnTop, null, "Toggle always in front");
			_c.addMenu("save", saveToFile, null, "Save to file");
			var menu : TextField = _c.panels.mainPanel.getChildByName("menuField") as TextField;
			menu.doubleClickEnabled = true;
			menu.addEventListener(MouseEvent.DOUBLE_CLICK, ondouble);
			_c.panels.mainPanel.addEventListener(ConsolePanel.DRAGGING_STARTED, moveHandle);
			_c.panels.mainPanel.addEventListener(ConsolePanel.SCALING_STARTED, scaleHandle);

			_c.filters = new Array(new GlowFilter(0, 0.7, 5, 5));

			_c.panels.mainPanel.addEventListener(Event.CLOSE, onMainPanelClose);
			stage.frameRate = 60;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			onStageResize();
			
			_c.addSlashCommand("listen", function (params:String = ""):void{
				var parts:Array = params.split(/\s+/);
				bindServer(parts[0], parts[1]);
			});
			_c.cl.localCommands.push("listen");
			_c.report("Use <b>/listen <i>ip port</i></b> command to listen to socket connection.", -2);
			_c.report("Example <b>/listen 127.0.0.1 200</b> command to listen to socket connection.", -1);
		}

		private function toggleOnTop() : void {
			stage.nativeWindow.alwaysInFront = !stage.nativeWindow.alwaysInFront;
			_c.report("Always in front " + (stage.nativeWindow.alwaysInFront ? "enabled." : "disabled"), -1);
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
				_c.error("Failed:", err.message);
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
			var str : String = _c.getAllLog(File.lineEnding);
			var stream : FileStream = new FileStream();
			try {
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(str);
				stream.close();
				_c.report("Saved log to " + file.nativePath, -1);
			} catch(e : Error) {
				// maybe read-only , etc
				_c.report("There was a problem saving the log to " + file.nativePath + "\n" + e, 10);
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
			_c.panels.mainPanel.stopScaling();
			stage.nativeWindow.startResize(NativeWindowResize.BOTTOM_RIGHT);
		}

		private function onStageResize(e : Event = null) : void {
			_c.width = stage.stageWidth - 20;
			_c.height = stage.stageHeight - 20;
		}

		public function bindServer(host : String, port : int) : void {
			if (_serverSocket && _serverSocket.bound) {
				_serverSocket.close();
			}
			_serverSocket = new ServerSocket();
			_serverSocket.bind(port, host);
			_serverSocket.addEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
			_serverSocket.listen();
			_c.report("Listening to: " + _serverSocket.localAddress + ":" + _serverSocket.localPort, -1);
		}

		private function onConnect(event : ServerSocketConnectEvent) : void {
			var clientSocket : Socket = event.socket;
			clientSocket.addEventListener(ProgressEvent.SOCKET_DATA, onClientSocketData);
			_c.report("Connection from " + clientSocket.remoteAddress + ":" + clientSocket.remotePort);
		}

		private function onClientSocketData(event : ProgressEvent) : void {
			var clientSocket : Socket = event.currentTarget as Socket;
			_c.remoter.handleSocket(clientSocket);
		}
	}
}