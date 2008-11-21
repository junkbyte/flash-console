/**
 * @class 		Timers
 * @author 		Lu
 * @version 	1.0
 * @requires 	AS3
 * 
 * 
 * 
**/
package com.atticmedia.console.core {
	
	import flash.utils.getTimer;

	public class Timers {

		private var _timers:Object;
		private var _quiet:Boolean;
		private var _reportFunction:Function;
		
		public function Timers(reportFunction:Function = null) {
			_timers = new Object();
			_quiet = true;
			_reportFunction = reportFunction;
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
			if (_reportFunction != null) {
				_reportFunction(new LogLineVO(txt,null,prio,false,true));
			} else {
				trace("C: "+ txt);
			}
		}
	}
}