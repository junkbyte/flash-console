/*
* 
* Copyright (c) 2008-2009 Lu Aye Oo
* 
* @author Lu Aye Oo
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
* 
DUMMY Console interface

Where would you need it?
If you are loading a module (swf/swc) that require the use of Console, but you don't want to
embed the console inside that swf (because of size), you might as well use a dummy Console interfce (this) in these swfs.
When loaded into the main/shell swf which have the real console instantiated, Console would work as intended in the loaded swfs.
- Thats provided you set the applicationDomain to use the main swf's applicationDomain.
While using this class, console related functions will silently fail to work.
If C.tracing is set to true, you will get traces in your flash authoring.
//
Another use is when you have finished development and no longer need Console. 
Replacing the real console's C class with this one will save you some size (~35kb) on the final SWF.
*/
package com.atticmedia.console{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;

	public class C {
		
		private static var _tracing:Boolean = false;
		private static var _traceCall:Function = trace;
		
		public function C() {
			throw new Error("[CONSOLE] Do not construct class. Please use C.start(mc:DisplayObjectContainer, password:String='')");
		}
		public static function start(mc:DisplayObjectContainer, pass:String = "", skin:int= 1, disallowBrowser:uint = 0):void {
		}
		public static function startOnStage(mc:DisplayObject, pass:String = "", skin:int= 1, disallowBrowser:uint = 0):void {
		}
		public static function add(str:*, priority:Number = 2, isRepeating:Boolean = false):void {
			_log(str);
		}
		public static function ch(channel:*, newLine:*, priority:Number = 2, isRepeating:Boolean = false):void {
			_log(newLine);
		}
		public static function log(...args):void {
			_log(args);
		}
		public static function info(...args):void {
			_log(args);
		}
		public static function debug(...args):void {
			_log(args);
		}
		public static function warn(...args):void {
			_log(args);
		}
		public static function error(...args):void {
			_log(args);
		}
		public static function logch(channel:*, ...args):void {
			_log(args);
		}
		public static function infoch(channel:*, ...args):void {
			_log(args);
		}
		public static function debugch(channel:*, ...args):void {
			_log(args);
		}
		public static function warnch(channel:*, ...args):void {
			_log(args);
		}
		public static function errorch(channel:*, ...args):void {
			_log(args);
		}
		public static function remove():void {
		}
		public static function get paused():Boolean {
			return false;
		}
		public static function set paused(v:Boolean):void {
		}
		public static function set enabled(v:Boolean):void {
		}
		public static function get enabled():Boolean {
			return false;
		}
		public static function clear(channel:String = null):void {
		}
		public static function get viewingChannel():String {
			return null;
		}
		public static function set viewingChannel(v:String):void {
		}
		public static function get viewingChannels():Array {
			return [];
		}
		public static function set viewingChannels(v:Array):void {
		}
		public static function get filterText():String {
			return null;
		}
		public static function set filterText(v:String):void {
		}
		public static function get prefixChannelNames():Boolean {
			return true;
		}
		public static function set prefixChannelNames(v:Boolean):void {
		}
		public static function get maxLines():int {
			return 1000;
		}
		public static function set maxLines(v:int):void {
		}
		public static function get maxRepeats():Number {
			return 0;
		}
		public static function set maxRepeats(v:Number):void {
		}
		public static function set tracing(v:Boolean):void {
			_tracing = v;
		}
		public static function get tracing():Boolean {
			return _tracing;
		}
		public static function set tracingChannels(v:Array):void {
		}
		public static function get tracingChannels():Array {
			return [];
		}
		public static function set tracingPriority(v:int):void {
		}
		public static function get tracingPriority():int {
			return 0;
		}
		public static function set traceCall(f:Function):void {
			_traceCall = f;
		}
		public static function get traceCall():Function {
			return _traceCall;
		}
		public static function setPanelArea(panelname:String, rect:Rectangle):void {
		}
		public static function set fpsMonitor(v:int):void {
		}
		public static function get fpsMonitor():int {
			return 0;
		}
		public static function set memoryMonitor(v:int):void {
		}
		public static function get memoryMonitor():int {
			return 0;
		}
		public static function set displayRoller(v:Boolean):void {
		}
		public static function get displayRoller():Boolean {
			return false;
		}
		public static function set rulerHidesMouse(v:Boolean):void {
		}
		public static function get rulerHidesMouse():Boolean {
			return false;
		}
		public static function get width():Number {
			return 0;
		}
		public static function set width(v:Number):void {
		}
		public static function get height():Number {
			return 0;
		}
		public static function set height(v:Number):void {
		}
		public static function get x():Number {
			return 0;
		}
		public static function set x(v:Number):void {
		}
		public static function get y():Number {
			return 0;
		}
		public static function set y(v:Number):void {
		}
		public static function get visible():Boolean {
			return false;
		}
		public static function set visible(v:Boolean):void {
		}
		public static function set quiet(v:Boolean):void {
		}
		public static function get quiet():Boolean {
			return false;
		}
		public static function set alwaysOnTop(v:Boolean):void {
		}
		public static function get alwaysOnTop():Boolean {
			return false;
		}
		public static function get remoting():Boolean {
			return false;
		}
		public static function set remoting(v:Boolean):void {
		}
		public static function get remote():Boolean {
			return false;
		}
		public static function set remote(v:Boolean):void {
		}
		public static function get remoteDelay():int {
			return 20;
		}
		public static function set remoteDelay(v:int):void {
		}
		public static function set remotingPassword(v:String):void {
		}
		public static function inspect(obj:Object, detail:Boolean = true):void {
		}
		public static function set commandLine(v:Boolean):void {
		}
		public static function get commandLine():Boolean {
			return false;
		}
		public static function set commandLineAllowed(b:Boolean):void {
		}
		public static function get commandLinePermission():Boolean {
			return false;
		}
		public static function get commandBase():Object {
			return null;
		}
		public static function set commandBase(v:Object):void {
		}
		public static function get strongRef():Boolean {
			return false;
		}
		public static function set strongRef(v:Boolean):void {
		}
		public static function store(n:String, obj:Object, strong:Boolean = false):void {
		}
		public static function map(base:DisplayObjectContainer, maxstep:uint = 0):void {
		}
		public static function runCommand(str:String):* {
			return null;
		}
		public static function watch(obj:Object,n:String = null):String {
			return null;
		}
		public static function unwatch(n:String):void {
		}
		public static function gc():void {
		}
		public static function addGraph(n:String, obj:Object, prop:String, col:Number = -1, key:String = null, rect:Rectangle = null, inverse:Boolean = false):void {
		}
		public static function fixGraphRange(n:String, min:Number = NaN, max:Number = NaN):void {
		}
		public static function removeGraph(n:String, obj:Object = null, prop:String = null):void {
		}
		public static function bindKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false, fun:Function = null,args:Array = null):void {
		}
		public static function setRollerCaptureKey(char:String, ctrl:Boolean = false, alt:Boolean = false, shift:Boolean = false):void {
		}
		public static function get exists():Boolean {
			return false;
		}
		
		private static function _log(args:*):void{
			if(_tracing && _traceCall != null) _traceCall(args);
		}
		
		public static function getAllLog(splitter:String = "\n"):String {
			return "";
		}
		public static function get instance():Object {
			return null;
		}
	}
}