/*
* Copyright (c) 2008 Lu Aye Oo (Atticmedia)
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
*/

package com.atticmedia.console {
	
	import flash.utils.getTimer;

	public class timers {

		private var _timers:Object;
		private var _quiet:Boolean;
		private var _channel:String = "C";
		
		public function timers() {
			_timers = new Object();
			_quiet = true;
		}
		public function get quiet():Boolean{
			return _quiet? true : false;
		}
		public function set quiet(newB:Boolean):void{
			_quiet = newB;
		}
		public function start(id:String = "default"):void{
			var time:int = getTimer();
			var nuldges:Array = new Array();
			_timers[id] = {startTime:time,nuldges:nuldges};
			if(!_quiet){
				report("<b>"+id+"</b> started at <b>"+ time +"</b>ms.", 1);
			}
		}
		public function nuldge(id:String = "default"):void{
			var time:int = getTimer();
			if(_timers[id]){
				_timers[id].nuldges.push(time);
				var timeTaken:int = time-_timers[id].startTime;
				if(!_quiet){
					report("<b>"+id+"</b> nuldged after <b>"+ timeTaken +"</b>ms at "+time+"ms.", 3);
				}
			}
		}
		public function getNuldges(id:String = "default"):int{
			if(_timers[id]){
				return _timers[id].nuldges;
			}
			return -1;
		}
		public function stop(id:String = "default"):Object{
			var time:int = getTimer();
			var timer:Object =_timers[id];
			if(timer){
				timer['stopTime'] = time;
				var timeTaken:int = time-timer['startTime'];
				report("<b>"+id+"</b> took <b>"+ timeTaken +"</b>ms with "+ timer['nuldges'].length +" nuldges. " + timer['startTime']+"ms - "+timer['stopTime']+"ms.", 8);
				return timer;
			}
			return null;
		}
		//
		//
		//
		private function report(txt:String, prio:Number=5):void {
			if (c.exists) {
				c.ch(_channel, "Timers: "+txt, prio);
			} else {
				trace("[Timers]: "+ txt);
			}
		}
	}
}