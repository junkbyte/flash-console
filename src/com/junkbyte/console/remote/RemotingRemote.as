package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.Remoting;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.system.Security;
	import flash.utils.ByteArray;

	public class RemotingRemote extends Remoting
	{
		
		protected var _lastLogin:String = "";
		
		public function RemotingRemote(m:Console)
		{
			super(m);
			registerCallback("started", clientStarted);
			registerCallback("loginRequest", requestLogin);
			registerCallback("loginFail", loginFail);
			registerCallback("loginSuccess", loginSuccess);
		}

		private function loginFail():void
		{
			report("Login Failed", 10);
			
			console.panels.mainPanel.requestLogin();
		}
		
		private function loginSuccess():void
		{
			_loggedIn = true;
			console.setViewingChannels();
			report("Login Successful", -1);
			dispatchEvent(new Event(Event.CONNECT));
		}
		
		private function clientStarted():void
		{
			login();
		}
		
		private function requestLogin():void
		{
			_sendBuffer = new ByteArray();
			if (_lastLogin)
			{
				login(_lastLogin);
			}
			else
			{
				console.panels.mainPanel.requestLogin();
			}
		}

		override public function login(pass:String = ""):void
		{
			_lastLogin = pass;
			report("Attempting to login...", -1);
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTF(pass);
			send("login", bytes);
		}
		
		override protected function startRemoting():void
		{
			if (startLocalConnection())
			{
				_sendBuffer = new ByteArray();
				_local.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onRemoteAsyncError, false, 0, true);
				report("<b>Remote started.</b> " + getInfo(), -1);
				var sdt:String = Security.sandboxType;
				if (sdt == Security.LOCAL_WITH_FILE || sdt == Security.LOCAL_WITH_NETWORK)
				{
					report("Untrusted local sandbox. You may not be able to listen for logs properly.", 10);
					printHowToGlobalSetting();
				}
				login(_lastLogin);
			}
			else
			{
				report("Could not create remote service. You might have a console remote already running.", 10);
			}
		}

		override protected function get selfLlocalConnectionName():String
		{
			return super.remoteLocalConnectionName;
		}

		override protected function get remoteLocalConnectionName():String
		{
			return super.selfLlocalConnectionName;
		}
		
		override protected function onLocalConnectionStatus(e:StatusEvent):void
		{
			if (e.level == "error")
			{
				report("Problem communicating to client.", 10);
			}
		}
	}
}
