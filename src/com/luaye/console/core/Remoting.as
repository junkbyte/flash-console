/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
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
package com.luaye.console.core {
	import com.luaye.console.Console;

	import flash.events.EventDispatcher;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	import flash.system.Security;

	public class Remoting extends EventDispatcher{
		
		public static const REMOTE_PREFIX:String = "R";
		public static const CLIENT_PREFIX:String = "C";
		
		private var _master:Console;
		private var _logsend:Function;
		private var _isRemoting:Boolean;
		private var _isRemote:Boolean;
		private var _sharedConnection:LocalConnection;
		private var _remoteLinesQueue:Array;
		private var _mspfsForRemote:Array;
		private var _remoteDelayed:int;
		
		private var _lastLogin:String = "";
		private var _loggedIn:Boolean;
		
		public var remoteMem:int;
		
		public function Remoting(m:Console, logsend:Function) {
			_master = m;
			_logsend = logsend;
		}
		public function addLineQueue(line:Log):void{
			if(!_loggedIn) return;
			_remoteLinesQueue.push(line.toObject());
			var maxlines:int = _master.maxLines;
			if(_remoteLinesQueue.length > maxlines && maxlines > 0 ){
				_remoteLinesQueue.splice(0,1);
			}
		}
		public function update(mspf:Number, sFR:Number = NaN):void{
			_remoteDelayed++;
			if(!_loggedIn) return;
			_mspfsForRemote.push(mspf);
			if(sFR){
				// this is to try add the frames that have been lagged
				var frames:int = Math.floor(mspf/(1000/sFR));
				if(frames>Console.FPS_MAX_LAG_FRAMES) frames = Console.FPS_MAX_LAG_FRAMES;
				while(frames>1){
					_mspfsForRemote.push(mspf);
					frames--;
				}
			}
			if(_remoteDelayed >= _master.remoteDelay){
				_remoteDelayed = 0;
				var newQueue:Array = new Array();
				// don't send too many lines at once cause there is 50kb limit with LocalConnection.send
				// Buffer it...
				if(_remoteLinesQueue.length > 20){
					newQueue = _remoteLinesQueue.splice(20);
					// to force update next farme
					_remoteDelayed = _master.remoteDelay;
				}
				send("logSend", [_remoteLinesQueue, _mspfsForRemote, _master.currentMemory, _master.cl.scopeString]);
				_remoteLinesQueue = newQueue;
				_mspfsForRemote = [sFR?sFR:30];
			}
		}
		public function send(command:String, ...args):void{
			var target:String = Console.REMOTING_CONN_NAME+(_isRemote?CLIENT_PREFIX:REMOTE_PREFIX);
			args = [target, command].concat(args);
			try{
				_sharedConnection.send.apply(this, args);
			}catch(e:Error){
				// don't care
			}
		}
		public function get remoting():Boolean{
			return _isRemoting;
		}
		public function set remoting(newV:Boolean):void{
			_remoteLinesQueue = null;
			_mspfsForRemote = null;
			if(newV){
				_isRemote = false;
				_remoteDelayed = 0;
				_mspfsForRemote = [30];
				_remoteLinesQueue = new Array();
				startSharedConnection();
				_sharedConnection.addEventListener(StatusEvent.STATUS, onRemotingStatus);
				_sharedConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError);
				try{
					_sharedConnection.connect(Console.REMOTING_CONN_NAME+CLIENT_PREFIX);
					_master.report("<b>Remoting started.</b> "+getInfo(),-1);
					_isRemoting = true;
					_loggedIn = _master.checkLogin("");
					if(_loggedIn){
						_remoteLinesQueue = _master.getLogsAsObjects();
						send("loginSuccess");
					}else{
						send("requestLogin");
					}
				}catch (error:Error){
					_master.report("Could not create client service. You will not be able to control this console with remote.", 10);
				}
			}else{
				_isRemoting = false;
				close();
			}
		}
		private function onRemotingStatus(e:StatusEvent):void{
			// this will get called quite often...
		}
		private function onRemotingSecurityError(e:SecurityErrorEvent):void{
			_master.report("Sandbox security error.", 10);
			printHowToGlobalSetting();
		}
		public function get isRemote():Boolean{
			return _isRemote;
		}
		public function set isRemote(newV:Boolean):void{
			_isRemote = newV ;
			if(newV){
				_isRemoting = false;
				startSharedConnection();
				_sharedConnection.addEventListener(StatusEvent.STATUS, onRemoteStatus);
				_sharedConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR , onRemotingSecurityError);
				try{
					_sharedConnection.connect(Console.REMOTING_CONN_NAME+REMOTE_PREFIX);
					_master.report("<b>Remote started.</b> "+getInfo(),-1);
					var sdt:String = Security.sandboxType;
					if(sdt == Security.LOCAL_WITH_FILE || sdt == Security.LOCAL_WITH_NETWORK){
						_master.report("Untrusted local sandbox. You may not be able to listen for logs properly.", 10);
						printHowToGlobalSetting();
					}
					login(_lastLogin);
				}catch (error:Error){
					_isRemoting = false;
					_master.report("Could not create remote service. You might have a console remote already running.", 10);
				}
			}else{
				close();
			}
		}
		private function onRemoteStatus(e:StatusEvent):void{
			if(_isRemote && e.level=="error"){
				_master.report("Problem communicating to client.", 10);
			}
		}
		private function getInfo():String{
			return "</p5>channel:<p5>"+Console.REMOTING_CONN_NAME+" ("+Security.sandboxType+")";
		}
		private function printHowToGlobalSetting():void{
			_master.report("Make sure your flash file is 'trusted' in Global Security Settings.", -2);
			_master.report("Go to Settings Manager [<a href='event:settings'>click here</a>] &gt; 'Global Security Settings Panel' (on left) &gt; add the location of the local flash (swf) file.", -2);
		}
		private function startSharedConnection():void{
			close();
			_sharedConnection = new LocalConnection();
			_sharedConnection.allowDomain("*");
			_sharedConnection.allowInsecureDomain("*");
			// just for sort of security
			_sharedConnection.client = {
				login:login, requestLogin:requestLogin, loginFail:loginFail, loginSuccess:loginSuccess,
				logSend:_logsend, gc:_master.gc, runCommand:_master.runCommand
				};
		}
		public function loginFail():void{
			_master.report("Login Failed", 10);
			_master.panels.mainPanel.requestLogin();
		}
		public function loginSuccess():void{
			_master.report("Login Successful", -1);
		}
		public function requestLogin():void{
			if(_lastLogin){
				login(_lastLogin);
			}else{
				_master.panels.mainPanel.requestLogin();
			}
		}
		public function login(pass:String = null):void{
			if(_isRemote){
				_lastLogin = pass;
				_master.report("Attempting to login...", -1);
				send("login", pass);
			}else{
				// once logged in, next login attempts will always be success
				if(_loggedIn || _master.checkLogin(pass)){
					_loggedIn = true;
					_remoteLinesQueue = _master.getLogsAsObjects();
					send("loginSuccess");
				}else{
					send("loginFail");
				}
			}
		}
		public function close():void{
			if(_sharedConnection){
				try{
					_sharedConnection.close();
				}catch(error:Error){
					_master.report("Remote.close: "+error, 10);
				}
			}
			_sharedConnection = null;
		}
	}
}