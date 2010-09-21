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
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.Log;

	import flash.events.AsyncErrorEvent;
	import flash.events.EventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.Security;
	import flash.utils.ByteArray;

	public class Remoting extends EventDispatcher{
		
		private static const MAXSIZE:uint = 36000; // real limit is 40kb
		
		private static const RECIEVER:String = "R";
		private static const SENDER:String = "C";
		
		private static const LOGIN:String = "login";
		private static const LOGINREQUEST:String = "requestLogin";
		private static const LOGINFAIL:String = "loginFail";
		private static const LOGINSUCCESS:String = "loginSuccess";
		private static const SYNC:String = "sync";
		public static const GC:String = "gc";
		public static const FPS:String = "fps";
		public static const MEM:String = "mem";
		public static const CMD:String = "cmd";
		//public static const CALL_UNMONITOR:String = "unmonitor";
		//public static const CALL_MONITORIN:String = "monitorIn";
		//public static const CALL_MONITOROUT:String = "monitorOut";
		
		private var _c:Console;
		private var _cfg:ConsoleConfig;
		private var _mode:String;
		private var _connection:LocalConnection;
		private var _queue:Array;
		
		private var _lastLogin:String = "";
		private var _password:String;
		private var _loggedIn:Boolean;
		private var _canDraw:Boolean;
		
		public function Remoting(m:Console, pass:String) {
			_c = m;
			_cfg = _c.config;
			_password = pass;
		}
		public function set remotingPassword(str:String):void{
			_password = str;
			if(remoting && !str) login();
		}
		public function addLineQueue(line:Log):void{
			if(!(remoting && _loggedIn)) return;
			_queue.push(line.toBytes());
			var maxlines:int = _cfg.maxLines;
			if(_queue.length > maxlines && maxlines > 0 ){
				_queue.splice(0,1);
			}
		}
		public function update(graphs:Array):void{
			if(remoting){
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
					if(size <= MAXSIZE || i == 0){
						logs.writeBytes(line);
					}else break;
				}
				_queue = _queue.splice(i);
				//
				var bytes:ByteArray = new ByteArray();
				bytes.writeObject(logs);
				bytes.writeObject(ga);
				bytes.writeUTF(_c.cl.scopeString);
				send(SYNC, bytes);
			}else if(!_c.paused){
				_canDraw = true;
			}
		}
		private function remoteSync(bytes:ByteArray):void{
			if(!isRemote || !bytes) return;
			bytes.position = 0;
			var logs:ByteArray = bytes.readObject();
			logs.position = 0;
			while(logs.bytesAvailable){
				var t:String = logs.readUTF();
				var c:String = logs.readUTF();
				var p:int = logs.readInt();
				var r:Boolean = logs.readBoolean();
				_c.addLine(t,p,c,r, true);
			}
			try{
				var a:Array = [];
				var graphs:ByteArray = bytes.readObject();
				graphs.position = 0;
				while(graphs.bytesAvailable){
					a.push(GraphGroup.FromBytes(graphs));
				}
				_c.panels.updateGraphs(a, _canDraw);
				if(_canDraw) {
					//_master.panels.updateObjMonitors(vo.om);
					_c.panels.mainPanel.updateCLScope(bytes.readUTF());
					_canDraw = false;
				}
			}catch(e:Error){
				_c.report(e);
			}
		}
		public function send(command:String, ...args):Boolean{
			var target:String = _cfg.remotingConnectionName+(isRemote?SENDER:RECIEVER);
			args = [target, command].concat(args);
			try{
				_connection.send.apply(this, args);
			}catch(e:Error){
				return false;
			}
			return true;
		}
		public function get remoting():Boolean{
			return _mode == SENDER;
		}
		public function set remoting(newV:Boolean):void{
			if(newV == remoting) return;
			_queue = null;
			if(newV){
				//_delayed = 0;
				_queue = new Array();
				if(!startSharedConnection(SENDER)){
					_c.report("Could not create remoting client service. You will not be able to control this console with remote.", 10);
				}
				_connection.addEventListener(StatusEvent.STATUS, onRemotingStatus, false, 0, true);
				_c.report("<b>Remoting started.</b> "+getInfo(),-1);
				_loggedIn = checkLogin("");
				if(_loggedIn){
					_queue = _c.getLogsAsBytes();
					send(LOGINSUCCESS);
				}else{
					send(LOGINREQUEST);
				}
			}else{
				close();
			}
		}
		private function onRemotingStatus(e:StatusEvent):void{
			if(e.level == "error") {
				_loggedIn = false;
			}
		}
		private function onRemotingSecurityError(e:SecurityErrorEvent):void{
			_c.report("Remoting security error.", 9);
			printHowToGlobalSetting();
		}
		public function get isRemote():Boolean{
			return _mode == RECIEVER;
		}
		public function set isRemote(newV:Boolean):void{
			if(newV == isRemote) return;
			if(newV){
				if(startSharedConnection(RECIEVER)){
					_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR , onRemoteAsyncError, false, 0, true);
					_connection.addEventListener(StatusEvent.STATUS, onRemoteStatus, false, 0, true);
					_c.report("<b>Remote started.</b> "+getInfo(),-1);
					var sdt:String = Security.sandboxType;
					if(sdt == Security.LOCAL_WITH_FILE || sdt == Security.LOCAL_WITH_NETWORK){
						_c.report("Untrusted local sandbox. You may not be able to listen for logs properly.", 10);
						printHowToGlobalSetting();
					}
					login(_lastLogin);
				}else{
					_c.report("Could not create remote service. You might have a console remote already running.", 10);
				}
			}else {
				close();
			}
		}
		private function onRemoteAsyncError(e:AsyncErrorEvent):void{
			_c.report("Problem with remote sync. [<a href='event:remote'>Click here</a>] to restart.", 10);
			isRemote = false;
		}
		private function onRemoteStatus(e:StatusEvent):void{
			if(isRemote && e.level=="error"){
				_c.report("Problem communicating to client.", 10);
			}
		}
		
		private function getInfo():String{
			return "</p5>channel:<p5>"+_cfg.remotingConnectionName+" ("+Security.sandboxType+")";
		}
		
		private function printHowToGlobalSetting():void{
			_c.report("Make sure your flash file is 'trusted' in Global Security Settings.", -2);
			_c.report("Go to Settings Manager [<a href='event:settings'>click here</a>] &gt; 'Global Security Settings Panel' (on left) &gt; add the location of the local flash (swf) file.", -2);
		}
		
		private function startSharedConnection(targetmode:String):Boolean{
			close();
			_mode = targetmode;
			_connection = new LocalConnection();
			if(_cfg.allowedRemoteDomain){
				_connection.allowDomain(_cfg.allowedRemoteDomain);
				_connection.allowInsecureDomain(_cfg.allowedRemoteDomain);
			}
			_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError, false, 0, true);
			var o:Object = new Object();
			o[LOGIN] = login;
			o[LOGINREQUEST] = requestLogin;
			o[LOGINFAIL] = loginFail;
			o[LOGINSUCCESS] = loginSuccess;
			o[SYNC] = remoteSync;
			o[GC] = _c.gc;
			o[FPS] = fpsRequest;
			o[MEM] = memRequest;
			o[CMD] = _c.runCommand;
			/*o[CALL_UNMONITOR] = _master.unmonitor;
			o[CALL_MONITORIN] = _master.monitorIn;
			o[CALL_MONITOROUT] = _master.monitorOut;*/
			_connection.client = o;
			
			try{
				_connection.connect(_cfg.remotingConnectionName+_mode);
			}catch(err:Error){
				return false;
			}
			return true;
		}
		private function fpsRequest(b:Boolean):void{
			_c.fpsMonitor = b;
		}
		private function memRequest(b:Boolean):void{
			_c.memoryMonitor = b;
		}
		private function loginFail():void{
			if(!isRemote) return;
			_c.report("Login Failed", 10);
			_c.panels.mainPanel.requestLogin();
		}
		private function loginSuccess():void{
			_c.report("Login Successful", -1);
		}
		private function requestLogin():void{
			if(!isRemote) return;
			if(_lastLogin){
				login(_lastLogin);
			}else{
				_c.panels.mainPanel.requestLogin();
			}
		}
		public function login(pass:String = null):void{
			if(isRemote){
				_lastLogin = pass;
				_c.report("Attempting to login...", -1);
				send(LOGIN, pass);
			}else{
				// once logged in, next login attempts will always be success
				if(_loggedIn || checkLogin(pass)){
					_loggedIn = true;
					_queue = _c.getLogsAsBytes();
					send(LOGINSUCCESS);
				}else{
					send(LOGINFAIL);
				}
			}
		}
		public function checkLogin(pass:String):Boolean{
			return (!_password || _password == pass);
		}
		public function close():void{
			if(_connection){
				try{
					_connection.close();
				}catch(error:Error){
					_c.report("Remote.close: "+error, 10);
				}
			}
			_mode = null;
			_connection = null;
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