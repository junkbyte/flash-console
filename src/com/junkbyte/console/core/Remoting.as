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
package com.junkbyte.console.core 
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.Log;

	import flash.events.AsyncErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.Security;
	import flash.utils.ByteArray;

	public class Remoting extends ConsoleCore{
		
		public static const NONE:uint = 0;
		public static const SENDER:uint = 1;
		public static const RECIEVER:uint = 2;
		
		private var _client:Object;
		private var _mode:uint;
		private var _connection:LocalConnection;
		private var _queue:Array;
		
		private var _lastLogin:String = "";
		private var _password:String;
		private var _loggedIn:Boolean;
		private var _canDraw:Boolean;
		
		private var _prevG:Boolean;
		private var _prevScope:String;
		
		public function Remoting(m:Console, pass:String) {
			super(m);
			_password = pass;
			_client = new Object();
			_client.login = login;
			_client.requestLogin = requestLogin;
			_client.loginFail = loginFail;
			_client.loginSuccess = loginSuccess;
			_client.sync = remoteSync;
		}
		public function queueLog(line:Log):void{
			if(_mode != SENDER || !_loggedIn) return;
			_queue.push(line.toBytes());
			var maxlines:int = config.maxLines;
			if(_queue.length > maxlines && maxlines > 0 ){
				_queue.splice(0,1);
			}
		}
		public function update(graphs:Array):void{
			if(_mode == SENDER){
				if(!_loggedIn) return;
				// graphs
				var ga:ByteArray = new ByteArray();
				len = graphs.length;
				for(i = 0; i<len; i++){
					ga.writeBytes(GraphGroup(graphs[i]).toBytes());
				}
				//
				// logs
				var size:uint = ga.length;
				var len:uint = _queue.length;
				var logs:ByteArray = new ByteArray();
				for(var i:uint = 0 ; i<len; i++){
					var line:ByteArray = _queue[i];
					size += line.length;
					// real limit is 40,000
					if(size <= 36000 || i == 0){
						logs.writeBytes(line);
					}else break;
				}
				_queue = _queue.splice(i);
				//
				var bytes:ByteArray = new ByteArray();
				bytes.writeObject(logs);
				bytes.writeObject(ga);
				bytes.writeUTF(console.cl.scopeString);
				if(size>0 || _prevScope!=console.cl.scopeString || _prevG)
				{
					_prevG = ga.length?true:false;
					_prevScope = console.cl.scopeString;
					send("sync", bytes);
				}
			}else if(!console.paused){
				_canDraw = true;
			}
		}
		private function remoteSync(bytes:ByteArray):void{
			if(remoting != Remoting.RECIEVER || !bytes) return;
			bytes.position = 0;
			var logs:ByteArray = bytes.readObject();
			logs.position = 0;
			while(logs.bytesAvailable){
				var t:String = logs.readUTF();
				var c:String = logs.readUTF();
				var p:int = logs.readInt();
				var r:Boolean = logs.readBoolean();
				console.addLine(new Array(t),p,c,r, true);
			}
			try{
				var a:Array = [];
				var graphs:ByteArray = bytes.readObject();
				graphs.position = 0;
				while(graphs.bytesAvailable){
					a.push(GraphGroup.FromBytes(graphs));
				}
				console.panels.updateGraphs(a, _canDraw);
				if(_canDraw) {
					console.panels.mainPanel.updateCLScope(bytes.readUTF());
					_canDraw = false;
				}
			}catch(e:Error){
				report(e);
			}
		}
		public function send(command:String, ...args):Boolean{
			var target:String = config.remotingConnectionName+(remoting == Remoting.RECIEVER?SENDER:RECIEVER);
			args = [target, command].concat(args);
			try{
				_connection.send.apply(this, args);
			}catch(e:Error){
				return false;
			}
			return true;
		}
		public function get remoting():uint{
			return _mode;
		}
		public function set remoting(newMode:uint):void{
			if(newMode == _mode) return;
			if(newMode == SENDER){
				_queue = new Array();
				if(!startSharedConnection(SENDER)){
					report("Could not create remoting client service. You will not be able to control this console with remote.", 10);
				}
				_connection.addEventListener(StatusEvent.STATUS, onRemotingStatus, false, 0, true);
				report("<b>Remoting started.</b> "+getInfo(),-1);
				_loggedIn = checkLogin("");
				if(_loggedIn){
					_queue = console.logs.getLogsAsBytes();
					send("loginSuccess");
				}else{
					send("requestLogin");
				}
			}else if(newMode == RECIEVER){
				if(startSharedConnection(RECIEVER)){
					_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR , onRemoteAsyncError, false, 0, true);
					_connection.addEventListener(StatusEvent.STATUS, onRemoteStatus, false, 0, true);
					report("<b>Remote started.</b> "+getInfo(),-1);
					var sdt:String = Security.sandboxType;
					if(sdt == Security.LOCAL_WITH_FILE || sdt == Security.LOCAL_WITH_NETWORK){
						report("Untrusted local sandbox. You may not be able to listen for logs properly.", 10);
						printHowToGlobalSetting();
					}
					login(_lastLogin);
				}else{
					report("Could not create remote service. You might have a console remote already running.", 10);
				}
			}else{
				close();
			}
			console.panels.updateMenu();
		}
		public function set remotingPassword(str:String):void{
			_password = str;
			if(_mode == SENDER && !str) login();
		}
		private function onRemotingStatus(e:StatusEvent):void{
			if(e.level == "error") {
				_loggedIn = false;
			}
		}
		private function onRemotingSecurityError(e:SecurityErrorEvent):void{
			report("Remoting security error.", 9);
			printHowToGlobalSetting();
		}
		private function onRemoteAsyncError(e:AsyncErrorEvent):void{
			report("Problem with remote sync. [<a href='event:remote'>Click here</a>] to restart.", 10);
			remoting = NONE;
		}
		private function onRemoteStatus(e:StatusEvent):void{
			if(remoting == Remoting.RECIEVER && e.level=="error"){
				report("Problem communicating to client.", 10);
			}
		}
		
		private function getInfo():String{
			return "</p5>channel:<p5>"+config.remotingConnectionName+" ("+Security.sandboxType+")";
		}
		
		private function printHowToGlobalSetting():void{
			report("Make sure your flash file is 'trusted' in Global Security Settings.", -2);
			report("Go to Settings Manager [<a href='event:settings'>click here</a>] &gt; 'Global Security Settings Panel' (on left) &gt; add the location of the local flash (swf) file.", -2);
		}
		
		private function startSharedConnection(targetmode:uint):Boolean{
			close();
			_mode = targetmode;
			_connection = new LocalConnection();
			if(config.allowedRemoteDomain){
				_connection.allowDomain(config.allowedRemoteDomain);
				_connection.allowInsecureDomain(config.allowedRemoteDomain);
			}
			_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError, false, 0, true);
			_connection.client = _client;
			
			try{
				_connection.connect(config.remotingConnectionName+_mode);
			}catch(err:Error){
				return false;
			}
			return true;
		}
		public function registerClient(key:String, fun:Function):void{
			_client[key] = fun;
		}
		private function loginFail():void{
			if(remoting != Remoting.RECIEVER) return;
			report("Login Failed", 10);
			console.panels.mainPanel.requestLogin();
		}
		private function loginSuccess():void{
			console.setViewingChannels();
			report("Login Successful", -1);
		}
		private function requestLogin():void{
			if(remoting != Remoting.RECIEVER) return;
			if(_lastLogin){
				login(_lastLogin);
			}else{
				console.panels.mainPanel.requestLogin();
			}
		}
		public function login(pass:String = null):void{
			if(remoting == Remoting.RECIEVER){
				_lastLogin = pass;
				report("Attempting to login...", -1);
				send("login", pass);
			}else{
				// once logged in, next login attempts will always be success
				if(_loggedIn || checkLogin(pass)){
					_loggedIn = true;
					_queue = console.logs.getLogsAsBytes();
					send("loginSuccess");
				}else{
					send("loginFail");
				}
			}
		}
		private function checkLogin(pass:String):Boolean{
			return (!_password || _password == pass);
		}
		public function close():void{
			if(_connection){
				try{
					_connection.close();
				}catch(error:Error){
					report("Remote.close: "+error, 10);
				}
			}
			_mode = NONE;
			_connection = null;
			_queue = null;
		}
		//
		//
		//
		/*public static function get RemoteIsRunning():Boolean{
			var sCon:LocalConnection = new LocalConnection();
			try{
				sCon.allowInsecureDomain("*");
				sCon.connect(Console.RemotingConnectionName+REMOTE_PREFIX);
			}catch(error:Error){
				return true;
			}
			sCon.close();
			return false;
		}*/
	}
}