/**
 * @class 		FramePerSecond
 * @author 		Lu
 * @version 	1.5
 * @requires 	AS3
 * 
 * 
 * 
**/
/*
	USAGE:
		
		import com.atticmedia.console.*;
		oFPS = new fps(this);
		
		Methods:
		oFPS.reset(); // reset records
		oFPS.pause(); // pause recording
		oFPS.start(); // start , use after pause
		oFPS.remove(); // remove oFPS.
		
		Properties:
		fps.get // get FPS data as html string format;
		fps.format = 2 // change default format of 'get()';
		fps.getInFormat(1) // get FPS data in the format number;
		fps.instance  // (read) to get instance of last ftp (oFPS)
		oFPS.running  // (read) true if it is not paused
		oFPS.base; // maximum number of FPS history to record(which is used in caculating average)
		oFPS.current; // (read) current FPS
		oFPS.min; // (read) minimum FPS since last reset 
		oFPS.max; // (read) maximum FPS since last reset
		oFPS.mid; // (read) mid FPS since last reset 
		oFPS.averageFPS // (read) Average FPS
		oFPS.averageMin // (read) average Minimum FPS
		oFPS.averageMax // (read) average Maximum FPS
		oFPS.mspf // (read) miliseconds per frame
*/

package com.atticmedia.console.core {
	import flash.display.DisplayObjectContainer;
	import flash.utils.getTimer;

	public class FpsMonitor {

		private var _mc:DisplayObjectContainer;
		private var _previousTime:Number;
		private var _fps:Number;
		private var _mspf:Number;
		private var _min:Number;
		private var _max:Number;
		private var _averageFPS:Number;
		private var _averageMsPF:Number;
		
		private var _history:Array;
		private var _defaultFormat:int = 1;
		private var _base:Number = 50;
		private var _isRunning:Boolean = false;
		
		
		
		public function FpsMonitor(mc:DisplayObjectContainer) {
			_mc = mc;
			_isRunning = false;
		}
		public function reset():void {
			_fps = NaN;
			_previousTime = NaN;
			_min = NaN;
			_max = NaN;
			_history = new Array();
		}
		public function get running():Boolean {
			return _isRunning;
		}
		public function get get():String{
			return getInFormat(_defaultFormat);
		}
		public function getInFormat(preset:Number = 0):String{
			switch(preset){
				case 2:
					return Math.round(min)+"-<b>"+current.toFixed(1) +"</b>-"+ Math.round(max);
				break;
				case 3:
					return Math.round(min)+"-<b>"+current.toFixed(1)+"</b>-"+ Math.round(max) + ": <b>" + Math.round(averageFPS)+ "</b>";
				break;
				case 4:
					var stageFrameRate:String = "";
					if(_mc.stage){
						stageFrameRate = "/"+_mc.stage.frameRate;
					}
					return Math.round(min)+"-<b>"+current.toFixed(1)+stageFrameRate+"</b>-"+ Math.round(max) + ": <b>" + Math.round(averageFPS) + "</b> " + Math.round(averageMsPF)+"ms-"+Math.round(mspf)+"ms";
				break;
				case 5:
					var stageMS:String = "";
					if(_mc.stage){
						stageMS = "/"+Math.round(1000/_mc.stage.frameRate)+"ms";
					}
					return Math.round(averageMsPF)+"ms-"+Math.round(mspf)+"ms "+stageMS;
				break;
				default:
					return current.toFixed(1);
				break;
			}
		}
		public function set format(newN:int):void{
			_defaultFormat = newN;
		}
		public function get format():int{
			return _defaultFormat;
		}
		public function start():void{
			reset();
			_isRunning = true;
		}
		public function pause():void {
			_isRunning = false;
		}
		public function get base():Number {
			return _base;
		}
		public function set base(num:Number):void{
			if (num is Number && num>0) {
				_base = num;
			}
		}
		public function get current():Number {
			return _fps;
		}
		public function get min():Number {
			return _min;
		}
		public function get max():Number {
			return _max;
		}
		public function get mid():Number {
			return _min + _max / 2;
		}
		public function get averageFPS():Number {
			return _averageFPS;
		}
		public function get averageMsPF():Number {
			return _averageMsPF;
		}
		public function get mspf():Number {
			return _mspf;
		}
		public function destory():void{
			pause();
			reset();
			_mc = null;
		}
		public function update():void{
			if(!_isRunning){
				return;
			}
			if (_previousTime) {
				var time:int = getTimer();
				_mspf = time-_previousTime;
				_fps = 1000/_mspf;
				if (!_min || _fps < _min) {
					_min = _fps;
				}
				if (!_max || _fps > _max) {
					_max = _fps;
				}
				_history.push({fps:_fps,time:_mspf});
				if (_history.length>_base) {
					delete _history.shift();
				}
				if(isNaN(_averageFPS)){
					_averageFPS = _fps;
				}
				_averageFPS += ((_fps/_base)-(_averageFPS/_base));
				if(isNaN(_averageMsPF)){
					_averageMsPF = _mspf;
				}
				_averageMsPF += ((_mspf/_base)-(_averageMsPF/_base));
			}
			_previousTime = getTimer();
		}
	}
}