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
package com.atticmedia.console.core {
	import com.atticmedia.console.Console;
	
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;	

	public class Remoting extends EventDispatcher{
		
		public static const REMOTE_PREFIX:String = "R";
		public static const CLIENT_PREFIX:String = "C";
		
		private var _master:Console;
		private var _isRemoting:Boolean;
		private var _isRemote:Boolean;
		private var _sharedConnection:LocalConnection;
		private var _remoteLinesQueue:Array;
		private var _mspfsForRemote:Array;
		private var _remoteDelayed:int;
		
		public var logsend:Function;
		
		public var remoteMem:int;
		
		public function Remoting(m:Console) {
			_master = m;
		}
		public function addLineQueue(line:LogLineVO):void{
			_remoteLinesQueue.push(line);
		}
		public function update(mspf:Number, sFR:Number = NaN):void{
			_remoteDelayed++;
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
			if(_remoteDelayed > _master.remoteDelay){
				_remoteDelayed = 0;
				var newQueue:Array = new Array();
				// don't send too many lines at once, so buffer it
				if(_remoteLinesQueue.length > 50){
					newQueue = newQueue.splice(50);
					// to force update sooner
					if(_master.remoteDelay>5){
						_remoteDelayed = _master.remoteDelay-5;
					}
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
				try{
                	_sharedConnection.connect(Console.REMOTING_CONN_NAME+CLIENT_PREFIX);
					_master.report("<b>Remoting started.</b> "+getInfo(),-1);
					_isRemoting = true;
           		}catch (error:Error){
					_master.report("Could not create client service. You will not be able to control this console with remote.", 10);
           		}
			}else{
				_isRemoting = false;
				close();
			}
		}
		public function get isRemote():Boolean{
			return _isRemote;
		}
		public function set isRemote(newV:Boolean):void{
			_isRemote = newV ;
			if(newV){
				_isRemoting = false;
				startSharedConnection();
				try{
                	_sharedConnection.connect(Console.REMOTING_CONN_NAME+REMOTE_PREFIX);
					_master.report("<b>Remote started.</b> "+getInfo(),-1);
           		}catch (error:Error){
					_isRemoting = false;
					_master.report("Could not create remote service. You might have a console remote already running.", 10);
           		}
			}else{
				close();
			}
		}
		private function getInfo():String{
			return "</p5>channel:<p5>"+Console.REMOTING_CONN_NAME;
		}
		private function startSharedConnection():void{
			close();
			_sharedConnection = new LocalConnection();
			_sharedConnection.allowDomain("*");
			_sharedConnection.allowInsecureDomain("*");
			_sharedConnection.addEventListener(StatusEvent.STATUS, onSharedStatus);
			// just for sort of security
			var client:Object = {logSend:logsend, gc:_master.gc, runCommand:_master.runCommand};
			_sharedConnection.client = client;
		}
		private function onSharedStatus(e:StatusEvent):void{
			// this will get called quite often if there is no actual remote server running...
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
