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

	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.net.Socket;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	[Event(name="CONNECT", type="flash.events.Event")]
	/**
	 * @private
	 */
	public class Remoting extends ConsoleCore{
		
		public static const NONE:uint = 0;
		public static const SENDER:uint = 1;
		public static const RECIEVER:uint = 2;
		
		private var _callbacks:Object = new Object();
		private var _mode:uint;
		private var _local:LocalConnection;
		private var _socket:Socket;
		private var _sendBuffer:ByteArray = new ByteArray();
		private var _recBuffers:Object = new Object();
		private var _senders:Dictionary = new Dictionary();
		
		private var _lastLogin:String = "";
		private var _loggedIn:Boolean;
		
		private var _sendID:String;
		private var _lastReciever:String;
		
		public function Remoting(m:Console) {
			super(m);
			registerCallback("login", function(bytes:ByteArray):void{
				login(bytes.readUTF());
			});
			registerCallback("requestLogin", requestLogin);
			registerCallback("loginFail", loginFail);
			registerCallback("loginSuccess", loginSuccess);
		}
		public function update():void{
			if(_sendBuffer.length){
				if(_socket && _socket.connected){
					_socket.writeBytes(_sendBuffer);
					//_socket.flush();
					_sendBuffer = new ByteArray();
				}else if(_local){
					var packet:ByteArray;
						_sendBuffer.position = 0;
					if(_sendBuffer.bytesAvailable < 38000){
						packet = _sendBuffer;
						_sendBuffer = new ByteArray();
					}else{
						packet = new ByteArray();
						_sendBuffer.readBytes(packet, 0, Math.min(38000, _sendBuffer.bytesAvailable));
						var newbuffer:ByteArray = new ByteArray();
						_sendBuffer.readBytes(newbuffer);
						_sendBuffer = newbuffer;
					}
					var target:String = config.remotingConnectionName+(remoting == Remoting.RECIEVER?SENDER:RECIEVER);
					_local.send(target, "synchronize", _sendID, packet);
				}else{
					_sendBuffer = new ByteArray();
				}
			}
			for (var id:String in _recBuffers){
				processRecBuffer(id);
			}
		}

		private function processRecBuffer(id:String):void
		{
			if(!_senders[id]){
				_senders[id] = true;
				if(_lastReciever){
					report("Remote switched to new sender ["+id+"] as primary.", -2);
				}
				_lastReciever = id;
			}
		
			var buffer:ByteArray = _recBuffers[id];
			try{
				var pointer:uint = buffer.position = 0;
				while(buffer.bytesAvailable){
					var cmd:String = buffer.readUTF();
					var arg:ByteArray = null;
					if(buffer.bytesAvailable == 0) break;
					if(buffer.readBoolean()){
						if(buffer.bytesAvailable == 0) break;
						var blen:uint = buffer.readUnsignedInt();
						if(buffer.bytesAvailable < blen) break;
						arg = new ByteArray();
						buffer.readBytes(arg, 0, blen);
					}
					var callbackData:Object = _callbacks[cmd];
					if(!callbackData.latest || id == _lastReciever){
						if(arg) callbackData.fun(arg);
						else callbackData.fun();
					}
					pointer = buffer.position;
				}
				if(pointer < buffer.length){
					var recbuffer:ByteArray = new ByteArray();
					recbuffer.writeBytes(buffer, pointer);
					_recBuffers[id] = buffer = recbuffer;
				}else{
					delete _recBuffers[id];
				}
			}catch(err:Error){
				report("Remoting sync error: "+err, 9);
			}
		}


		private function synchronize(id:String, obj:Object):void{
			if(!(obj is ByteArray)){
				report("Remoting sync error. Recieved non-ByteArray:"+obj, 9);
				return;
			}
			var packet:ByteArray = obj as ByteArray;
			var buffer:ByteArray = _recBuffers[id];
			if(buffer){
				buffer.position = buffer.length;
				buffer.writeBytes(packet);
			}else{
				_recBuffers[id] = packet;
			}
		}
		public function send(command:String, arg:ByteArray = null):Boolean{
			if(_mode == NONE) return false;
			_sendBuffer.position = _sendBuffer.length;
			_sendBuffer.writeUTF(command);
			if(arg){
				_sendBuffer.writeBoolean(true);
				_sendBuffer.writeUnsignedInt(arg.length);
				_sendBuffer.writeBytes(arg);
			}else{
				_sendBuffer.writeBoolean(false);
			}
			return true;
		}
		public function get remoting():uint{
			return _mode;
		}
		public function get canSend():Boolean{
			return _mode == SENDER && _loggedIn;
		}
		public function set remoting(newMode:uint):void{
			if(newMode == _mode) return;
			_sendID = generateId();
			if(newMode == SENDER){
				if(!startSharedConnection(SENDER)){
					report("Could not create remoting client service. You will not be able to control this console with remote.", 10);
				}
				_sendBuffer = new ByteArray();
				_local.addEventListener(StatusEvent.STATUS, onSenderStatus, false, 0, true);
				report("<b>Remoting started.</b> "+getInfo(),-1);
				_loggedIn = checkLogin("");
				if(_loggedIn){
					sendLoginSuccess();
				}else{
					send("requestLogin");
				}
			}else if(newMode == RECIEVER){
				if(startSharedConnection(RECIEVER)){
					_sendBuffer = new ByteArray();
					_local.addEventListener(AsyncErrorEvent.ASYNC_ERROR , onRemoteAsyncError, false, 0, true);
					_local.addEventListener(StatusEvent.STATUS, onRecieverStatus, false, 0, true);
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
		public function remotingSocket(host:String, port:int = 0):void{
			if(_socket && _socket.connected){
				_socket.close();
				_socket = null;
			}
			if(host && port)
			{
				remoting = SENDER;
				report("Connecting to socket " + host + ":" + port);
				_socket = new Socket();
		        _socket.addEventListener(Event.CLOSE, socketCloseHandler);
		        _socket.addEventListener(Event.CONNECT, socketConnectHandler);
		        _socket.addEventListener(IOErrorEvent.IO_ERROR, socketIOErrorHandler);
		        _socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, socketSecurityErrorHandler);
		        _socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		        _socket.connect(host, port);
			}
		}

		private function socketCloseHandler(e:Event) : void {
			if(e.currentTarget == _socket){
				_socket = null;
			}
		}
		private function socketConnectHandler(e:Event) : void {
			report("Remoting socket connected.", -1);
			_sendBuffer = new ByteArray();
			if(_loggedIn || checkLogin("")){
				sendLoginSuccess();
			}else{
				send("requestLogin");
			}
			// not needed yet
		}
		private function socketIOErrorHandler(e:Event) : void {
			report("Remoting socket error." + e, 9);
			remotingSocket(null);
		}
		private function socketSecurityErrorHandler(e:Event) : void {
			report("Remoting security error." + e, 9);
			remotingSocket(null);
		}
		private function socketDataHandler(e:Event) : void {
			handleSocket(e.currentTarget as Socket);
		}
		public function handleSocket(socket:Socket):void{
			if(!_senders[socket]){
				_senders[socket] = generateId();
				_socket = socket;
			}
			var bytes:ByteArray = new ByteArray();
			socket.readBytes(bytes);
			synchronize(_senders[socket], bytes);
		}
		private function onSenderStatus(e:StatusEvent):void{
			if(e.level == "error" && !(_socket && _socket.connected)) {
				_loggedIn = false;
			}
		}
		private function onRecieverStatus(e:StatusEvent):void{
			if(remoting == Remoting.RECIEVER && e.level=="error"){
				report("Problem communicating to client.", 10);
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
		
		private function getInfo():String{
			return "<p4>channel:"+config.remotingConnectionName+" ("+Security.sandboxType+")</p4>";
		}
		
		private function printHowToGlobalSetting():void{
			report("Make sure your flash file is 'trusted' in Global Security Settings.", -2);
			report("Go to Settings Manager [<a href='event:settings'>click here</a>] &gt; 'Global Security Settings Panel' (on left) &gt; add the location of the local flash (swf) file.", -2);
		}
		
		private function generateId():String{
			return new Date().time+"."+Math.floor(Math.random()*100000);
		}
		private function startSharedConnection(targetmode:uint):Boolean{
			close();
			_mode = targetmode;
			_local = new LocalConnection();
			_local.client = {synchronize:synchronize};
			if(config.allowedRemoteDomain){
				_local.allowDomain(config.allowedRemoteDomain);
				_local.allowInsecureDomain(config.allowedRemoteDomain);
			}
			_local.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError, false, 0, true);
			
			try{
				_local.connect(config.remotingConnectionName+_mode);
			}catch(err:Error){
				return false;
			}
			return true;
		}
		public function registerCallback(key:String, fun:Function, latestOnly:Boolean = false):void{
			_callbacks[key] = {fun:fun, latest:latestOnly};
		}
		private function loginFail():void{
			if(remoting != Remoting.RECIEVER) return;
			report("Login Failed", 10);
			console.panels.mainPanel.requestLogin();
		}
		private function sendLoginSuccess():void{
			_loggedIn = true;
			send("loginSuccess");
			dispatchEvent(new Event(Event.CONNECT));
		}
		private function loginSuccess():void{
			console.setViewingChannels();
			report("Login Successful", -1);
		}
		private function requestLogin():void{
			if(remoting != Remoting.RECIEVER) return;
			_sendBuffer = new ByteArray();
			if(_lastLogin){
				login(_lastLogin);
			}else{
				console.panels.mainPanel.requestLogin();
			}
		}
		public function login(pass:String = ""):void{
			if(remoting == Remoting.RECIEVER){
				_lastLogin = pass;
				report("Attempting to login...", -1);
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF(pass);
				send("login", bytes);
			}else{
				// once logged in, next login attempts will always be success
				if(_loggedIn || checkLogin(pass)){
					sendLoginSuccess();
				}else{
					send("loginFail");
				}
			}
		}

		private function checkLogin(pass : String) : Boolean {
			return ((config.remotingPassword === null && config.keystrokePassword == pass) 
					|| config.remotingPassword === "" 
					|| config.remotingPassword == pass
				);
		}
		public function close():void{
			if(_local){
				try{
					_local.close();
				}catch(error:Error){
					report("Remote.close: "+error, 10);
				}
			}
			_mode = NONE;
			_sendBuffer = new ByteArray();
			_local = null;
		}
	}
}