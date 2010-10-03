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
package com.junkbyte.console.core {
	import com.junkbyte.console.ConsoleConfig;
	import com.junkbyte.console.vos.RemoteSync;
	import com.junkbyte.console.vos.GraphGroup;
	import com.junkbyte.console.vos.Log;
	import com.junkbyte.console.Console;

	import flash.events.EventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.Security;

	public class Remoting extends EventDispatcher{
		
		private static const MAXSIZE:uint = 32000; // real limit is 40kb
		
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
		
		private var _master:Console;
		private var _config:ConsoleConfig;
		private var _mode:String;
		//private var _isRemoting:Boolean;
		//private var _isRemote:Boolean;
		private var _connection:LocalConnection;
		private var _queue:Array;
		//private var _delayed:int;
		
		private var _lastLogin:String = "";
		private var _password:String;
		private var _loggedIn:Boolean;
		private var _canDraw:Boolean;
		
		public function Remoting(m:Console, pass:String) {
			_master = m;
			_config = _master.config;
			_password = pass;
		}
		public function set remotingPassword(str:String):void{
			_password = str;
			if(remoting && !str) login();
		}
		public function addLineQueue(line:Log):void{
			if(!(remoting && _loggedIn)) return;
			_queue.push(line.toObject());
			var maxlines:int = _config.maxLines;
			if(_queue.length > maxlines && maxlines > 0 ){
				_queue.splice(0,1);
			}
		}
		public function update(graphs:Array):void{
			if(remoting){
				if(!_loggedIn) return;
				//_delayed++;
				//if(_delayed >= _config.remoteDelay){
				//	_delayed = 0;
					// don't send too many lines at once cause there is 40kb limit with LocalConnection.send					
					var size:uint = 0;
					var len:uint = _queue.length;
					for(var i:uint = 0 ; i<len; i++){
						var line:Object = _queue[i];
						size += line.t.length+50; // 50 = extra bytes for channel name, priority num, etc.
						if(i > 0 && size > MAXSIZE){
							break;
						}
					}
					var newQueue:Array = _queue.splice(i);
					// to force update next farme if there is still lines left
				//	if(newQueue.length){
				//		_delayed = _config.remoteDelay;
				//	}
					//
					var ga:Array = [];
					len = graphs.length;
					for(i = 0; i<len; i++){
						ga.push(GraphGroup(graphs[i]).toObject());
					}
					var vo:RemoteSync = new RemoteSync();
					vo.lines = _queue;
					vo.graphs = ga;
					vo.cl = _master.cl.scopeString;
					//vo.om = om;
					send(SYNC, vo);
					_queue = newQueue;
				//}
			}else if(!_master.paused){
				_canDraw = true;
			}
		}
		private function remoteSync(obj:Object):void{
			if(!isRemote || !obj) return;
			//_master.clear();
			//_master.explode(obj, -1);
			var vo:RemoteSync = RemoteSync.FromObject(obj);
			for each( var line:Object in vo.lines){
				if(line) _master.addLine(line.t,line.p,line.c,line.r, true);
			}
			try{
				var a:Array = [];
				for each(var o:Object in vo.graphs){
					a.push(GraphGroup.FromObject(o));
				}
				_master.panels.updateGraphs(a, _canDraw);
				if(_canDraw) {
					//_master.panels.updateObjMonitors(vo.om);
					_master.panels.mainPanel.updateCLScope(vo.cl);
					_canDraw = false;
				}
			}catch(e:Error){
				_master.report(e);
			}
		}
		public function send(command:String, ...args):void{
			var target:String = _config.remotingConnectionName+(isRemote?SENDER:RECIEVER);
			args = [target, command].concat(args);
			try{
				_connection.send.apply(this, args);
			}catch(e:Error){
				// don't care
			}
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
					_master.report("Could not create remoting client service. You will not be able to control this console with remote.", 10);
				}
				_connection.addEventListener(StatusEvent.STATUS, onRemotingStatus, false, 0, true);
				_master.report("<b>Remoting started.</b> "+getInfo(),-1);
				_loggedIn = checkLogin("");
				if(_loggedIn){
					_queue = _master.getLogsAsObjects();
					send(LOGINSUCCESS);
				}else{
					send(LOGINREQUEST);
				}
			}else{
				close();
			}
		}
		private function onRemotingStatus(e:StatusEvent):void{
			if(e.level == "error") _loggedIn = false;
		}
		private function onRemotingSecurityError(e:SecurityErrorEvent):void{
			_master.report("Remoting security error.", 9);
			printHowToGlobalSetting();
		}
		public function get isRemote():Boolean{
			return _mode == RECIEVER;
		}
		public function set isRemote(newV:Boolean):void{
			if(newV == isRemote) return;
			if(newV){
				if(startSharedConnection(RECIEVER)){
					_connection.addEventListener(StatusEvent.STATUS, onRemoteStatus, false, 0, true);
					_master.report("<b>Remote started.</b> "+getInfo(),-1);
					var sdt:String = Security.sandboxType;
					if(sdt == Security.LOCAL_WITH_FILE || sdt == Security.LOCAL_WITH_NETWORK){
						_master.report("Untrusted local sandbox. You may not be able to listen for logs properly.", 10);
						printHowToGlobalSetting();
					}
					login(_lastLogin);
				}else{
					_master.report("Could not create remote service. You might have a console remote already running.", 10);
				}
			}else {
				close();
			}
		}
		private function onRemoteStatus(e:StatusEvent):void{
			if(isRemote && e.level=="error"){
				_master.report("Problem communicating to client.", 10);
			}
		}
		
		private function getInfo():String{
			return "</p5>channel:<p5>"+_config.remotingConnectionName+" ("+Security.sandboxType+")";
		}
		
		private function printHowToGlobalSetting():void{
			_master.report("Make sure your flash file is 'trusted' in Global Security Settings.", -2);
			_master.report("Go to Settings Manager [<a href='event:settings'>click here</a>] &gt; 'Global Security Settings Panel' (on left) &gt; add the location of the local flash (swf) file.", -2);
		}
		
		private function startSharedConnection(targetmode:String):Boolean{
			close();
			_mode = targetmode;
			_connection = new LocalConnection();
			if(_config.allowedRemoteDomain){
				_connection.allowDomain(_config.allowedRemoteDomain);
				_connection.allowInsecureDomain(_config.allowedRemoteDomain);
			}
			_connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError, false, 0, true);
			var o:Object = new Object();
			o[LOGIN] = login;
			o[LOGINREQUEST] = requestLogin;
			o[LOGINFAIL] = loginFail;
			o[LOGINSUCCESS] = loginSuccess;
			o[SYNC] = remoteSync;
			o[GC] = _master.gc;
			o[FPS] = fpsRequest;
			o[MEM] = memRequest;
			o[CMD] = _master.runCommand;
			/*o[CALL_UNMONITOR] = _master.unmonitor;
			o[CALL_MONITORIN] = _master.monitorIn;
			o[CALL_MONITOROUT] = _master.monitorOut;*/
			_connection.client = o;
			
			try{
				_connection.connect(_config.remotingConnectionName+_mode);
			}catch(err:Error){
				return false;
			}
			return true;
		}
		private function fpsRequest(b:Boolean):void{
			_master.fpsMonitor = b;
		}
		private function memRequest(b:Boolean):void{
			_master.memoryMonitor = b;
		}
		public function loginFail():void{
			if(!isRemote) return;
			_master.report("Login Failed", 10);
			_master.panels.mainPanel.requestLogin();
		}
		public function loginSuccess():void{
			_master.report("Login Successful", -1);
		}
		public function requestLogin():void{
			if(!isRemote) return;
			if(_lastLogin){
				login(_lastLogin);
			}else{
				_master.panels.mainPanel.requestLogin();
			}
		}
		public function login(pass:String = null):void{
			if(isRemote){
				_lastLogin = pass;
				_master.report("Attempting to login...", -1);
				send(LOGIN, pass);
			}else{
				// once logged in, next login attempts will always be success
				if(_loggedIn || checkLogin(pass)){
					_loggedIn = true;
					_queue = _master.getLogsAsObjects();
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
					_master.report("Remote.close: "+error, 10);
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