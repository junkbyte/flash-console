/*
 *
 * Copyright (c) 2008-2011 Lu Aye Oo
 *
 * @author 		Lu Aye Oo
 *
 * http://code.google.com/p/flash-console/
 * http://junkbyte.com
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
package com.junkbyte.console.view.mainPanel
{
	import com.junkbyte.console.events.ConsoleEvent;
	import com.junkbyte.console.interfaces.IKeyStates;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.view.ConsolePanel;
	import com.junkbyte.console.view.ConsoleScrollBar;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.TextField;

	public class ConsoleOutputDisplay extends MainPanelSubArea
	{
		private var _traceField:TextField;
		private var _bottomLine:Shape;
		private var _selectionStart:int;
		private var _selectionEnd:int;

		private var _scrollBar:ConsoleScrollBar;
		private var _needsUpdate:Boolean;
		private var _lockScrollUpdate:Boolean;
		private var _atBottom:Boolean = true;

		private var _dataProvider:ConsoleOutputProvider;

		public function ConsoleOutputDisplay(parentPanel:ConsolePanel)
		{
			super(parentPanel);
			_traceField = new TextField();
			_traceField.name = "traceField";
			_traceField.wordWrap = true;
			_traceField.multiline = true;
			_traceField.addEventListener(Event.SCROLL, onTraceScroll);
			
			_traceField.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
			//
			_bottomLine = new Shape();
			_bottomLine.name = "blinkLine";
			_bottomLine.alpha = 0.2;

			//
			_scrollBar = new ConsoleScrollBar();
			_scrollBar.addEventListener(Event.SCROLL, onScrollBarScroll);
			_scrollBar.addEventListener(ConsoleScrollBar.STARTED_SCROLLING, onScrollStarted);
			_scrollBar.addEventListener(ConsoleScrollBar.STOPPED_SCROLLING, onScrollEnded);

			_traceField.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel, false, 0, true);
		}

		public function setDataProvider(provider:ConsoleOutputProvider):void
		{
			if (_dataProvider != null)
			{
				_dataProvider.removeUpdateCallback(onProviderUpdate);
				_dataProvider = null;
			}
			if (provider != null)
			{
				_dataProvider = provider;
				_dataProvider.addUpdateCallback(onProviderUpdate);
			}
			_needsUpdate = true;
		}

		override protected function registeredToConsole():void
		{
			var mainPanel:MainPanel = console.mainPanel;

			_traceField.styleSheet = style.styleSheet;

			_scrollBar.setConsole(console);

			addChild(_traceField);
			addChild(_bottomLine);
			addChild(_scrollBar.sprite);

			console.addEventListener(ConsoleEvent.PAUSED, onConsolePaused);
			console.addEventListener(ConsoleEvent.RESUMED, onConsoleResumed);

			display.addEventListener(Event.ENTER_FRAME, onEnterFrame);

			super.registeredToConsole();

		}

		override protected function unregisteredFromConsole():void
		{
			throw new Error();
			super.unregisteredFromConsole();
		}

		protected function onProviderUpdate():void
		{
			_needsUpdate = true;
			_bottomLine.alpha = 1;
		}

		protected function onConsolePaused(e:Event):void
		{
			if (_atBottom)
			{
				_atBottom = false;
				_updateTraces();
				_traceField.scrollV = _traceField.maxScrollV;
			}
		}

		protected function onConsoleResumed(e:Event):void
		{
			_atBottom = true;
			updateBottom();
		}
		
		private function linkHandler(e:TextEvent):void
		{
			sprite.stopDrag();
			
			modules.textLinks.onLinkClicked(e.text);
		}

		override public function setArea(x:Number, y:Number, width:Number, height:Number):void
		{
			super.setArea(x, y, width, height);
			_lockScrollUpdate = true;
			_traceField.x = x;
			_traceField.y = y;
			_traceField.width = width - 5;
			_traceField.height = height;

			_bottomLine.graphics.clear();
			_bottomLine.graphics.lineStyle(1, style.controlColor);
			_bottomLine.graphics.moveTo(x + 10, -1);
			_bottomLine.graphics.lineTo(x + width - 10, -1);
			_bottomLine.y = y + height;
			//
			_scrollBar.x = x + width;
			_scrollBar.y = y;
			_scrollBar.setBarSize(5, height);
			//
			_atBottom = true;
			_needsUpdate = true;
			_lockScrollUpdate = false;
		}

		protected function onEnterFrame(event:Event):void
		{
			if (_bottomLine.alpha > 0)
			{
				_bottomLine.alpha -= 0.25;
			}
			if (_needsUpdate)
			{
				_updateTraces(true);
			}
		}

		public function updateToBottom():void
		{
			_atBottom = true;
			_needsUpdate = true;
		}

		private function _updateTraces(onlyBottom:Boolean = false):void
		{
			_needsUpdate = false;
			if (_atBottom)
			{
				updateBottom();
			}
			else if (!onlyBottom)
			{
				updateFull();
			}
			if (_selectionStart != _selectionEnd)
			{
				if (_atBottom)
				{
					_traceField.setSelection(_traceField.text.length - _selectionStart, _traceField.text.length - _selectionEnd);
				}
				else
				{
					_traceField.setSelection(_traceField.text.length - _selectionEnd, _traceField.text.length - _selectionStart);
				}
				_selectionEnd = -1;
				_selectionStart = -1;
			}
		}

		private function updateFull():void
		{
			_lockScrollUpdate = true;
			_traceField.htmlText = _dataProvider.getFullOutput();
			_lockScrollUpdate = false;
			updateScroller();
		}

		private function updateBottom():void
		{
			var linesLeft:int = Math.round(_traceField.height / style.traceFontSize);
			var maxchars:int = Math.round(_traceField.width * 5 / style.traceFontSize);

			_lockScrollUpdate = true;
			_traceField.htmlText = _dataProvider.getOutputFromBottom(linesLeft, maxchars)
			_traceField.scrollV = _traceField.maxScrollV;
			_lockScrollUpdate = false;
			updateScroller();
		}

		private function onTraceScroll(e:Event = null):void
		{
			var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;

			if (_lockScrollUpdate || (keyStates != null && keyStates.shiftKeyDown))
			{
				return;
			}
			var atbottom:Boolean = _traceField.scrollV >= _traceField.maxScrollV;
			if (!console.paused && _atBottom != atbottom)
			{
				var diff:int = _traceField.maxScrollV - _traceField.scrollV;
				_selectionStart = _traceField.text.length - _traceField.selectionBeginIndex;
				_selectionEnd = _traceField.text.length - _traceField.selectionEndIndex;
				_atBottom = atbottom;
				_updateTraces();
				_traceField.scrollV = _traceField.maxScrollV - diff;
			}
			updateScroller();
		}

		private function updateScroller():void
		{
			_scrollBar.maxScroll = _traceField.maxScrollV - 1;
			if (_atBottom)
			{
				_scrollBar.scroll = _scrollBar.maxScroll;
			}
			else
			{
				_scrollBar.scroll = _traceField.scrollV - 1;
			}
		}

		private function onScrollBarScroll(e:Event):void
		{
			_lockScrollUpdate = true;
			_traceField.scrollV = _scrollBar.scroll + 1;
			_lockScrollUpdate = false;
		}

		private function onScrollStarted(e:Event):void
		{
			if (!console.paused && _atBottom)
			{
				_atBottom = false;
				var p:Number = _scrollBar.scrollPercent;
				_updateTraces();
				_scrollBar.scrollPercent = p;
			}
		}

		private function onScrollEnded(e:Event):void
		{
			onTraceScroll();
		}

		private function onMouseWheel(e:MouseEvent):void
		{
			var keyStates:IKeyStates = modules.getModuleByName(ConsoleModuleNames.KEY_STATES) as IKeyStates;

			if (keyStates != null && keyStates.shiftKeyDown)
			{
				var s:int = style.traceFontSize + (e.delta > 0 ? 1 : -1);
				if (s >= 8 && s <= 20)
				{
					style.traceFontSize = s;
					style.updateStyleSheet();
					updateToBottom();
					e.stopPropagation();
				}
			}
		}
	}
}
