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
package com.junkbyte.console.view
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;

    [Event(name = "scroll", type = "flash.events.Event")]
    [Event(name = "startedScrolling", type = "com.junkbyte.console.view.ConsoleScrollBar")]
    [Event(name = "stoppedScrolling", type = "com.junkbyte.console.view.ConsoleScrollBar")]
    public class ConsoleScrollBar extends ConsoleDisplayModule
    {
        public static const STARTED_SCROLLING:String = "startedScrolling";

        public static const STOPPED_SCROLLING:String = "stoppedScrolling";

        private var _scroll:uint;

        private var _maxScroll:uint;

        private var _scroller:Sprite;

        private var _scrolldelay:uint;

        private var _delayedScrollDelta:int;

        private var _scrolling:Boolean;

        private var _height:Number;

        public function ConsoleScrollBar()
        {
            sprite.name = "scroller";
            sprite.tabEnabled = false;
            sprite.buttonMode = true;
            sprite.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);

            _scroller = new Sprite();
            _scroller.name = "scrollbar";
            _scroller.tabEnabled = false;
            _scroller.y = 5;
            _scroller.addEventListener(MouseEvent.MOUSE_DOWN, onScrollBarDown, false, 0, true);

            addChild(_scroller);
        }

        override protected function registeredToConsole():void
        {
			_scroller.graphics.clear();
            _scroller.graphics.beginFill(style.controlColor, 1);
            _scroller.graphics.drawRect(-5, 0, 5, 30);
            _scroller.graphics.beginFill(0, 0);
            _scroller.graphics.drawRect(-10, 0, 10, 30);
            _scroller.graphics.endFill();

            super.registeredToConsole();
        }

        public function setBarSize(width:Number, height:Number):void
        {
            _height = height;
            sprite.graphics.clear();
            _scroller.visible = height > 50;
            if (_height >= 10)
            {
                sprite.graphics.beginFill(style.controlColor, 0.7);
                sprite.graphics.drawRect(-5, 0, 5, 5);
                sprite.graphics.drawRect(-5, _height - 5, 5, 5);
                sprite.graphics.beginFill(style.controlColor, 0.25);
                sprite.graphics.drawRect(-5, 5, 5, _height - 10);
                sprite.graphics.beginFill(0, 0);
                sprite.graphics.drawRect(-10, 10, 10, _height - 10);
                sprite.graphics.endFill();
            }
        }

        public function get scroll():int
        {
            return _scroll;
        }

        public function set scroll(i:int):void
        {
            if (i < 0)
                i = 0;
            else if (i > _maxScroll)
                i = _maxScroll;
            _scroll = i;
            updateScrollBar();
            announceScrolled();
        }

        public function get scrollPercent():Number
        {
            return scroll / maxScroll;
        }

        public function set scrollPercent(percent:Number):void
        {
            scroll = percent * maxScroll;
        }

        public function get maxScroll():uint
        {
            return _maxScroll;
        }

        public function set maxScroll(i:uint):void
        {
            _maxScroll = i;
			sprite.visible = i > 0;
        }

        private function announceScrolled():void
        {
            dispatchEvent(new Event(Event.SCROLL));
        }

        protected function updateScrollBar():void
        {
            _scroller.y = 5 + (getBarMaxY() * scrollPercent);
        }

        private function onMouseDown(e:MouseEvent):void
        {
            var delta:int = -3;
            if ((_scroller.visible && _scroller.mouseY > 0) || (!_scroller.visible && sprite.mouseY > _height * 0.5))
            {
                delta = 3;
            }
            scroll += delta;
            startDelayedScroll(delta);
        }

        private function getBarMaxY():Number
        {
            return _height - 40;
        }

        private function onMouseUp(e:Event):void
        {
            sprite.removeEventListener(Event.ENTER_FRAME, onDelayScrollFrame);
            sprite.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }

        protected function startDelayedScroll(delta:int):void
        {
            _delayedScrollDelta = delta;
            _scrolldelay = 0;
            sprite.addEventListener(Event.ENTER_FRAME, onDelayScrollFrame, false, 0, true);
            sprite.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
        }

        private function onDelayScrollFrame(e:Event):void
        {
            _scrolldelay++;
            if (_scrolldelay > 10)
            {
                _scrolldelay = 9;
                if ((_delayedScrollDelta < 0 && _scroller.y > sprite.mouseY) || (_delayedScrollDelta > 0 && _scroller.y + _scroller.height < sprite.mouseY))
                {
                    scroll += _delayedScrollDelta;
                }
            }
        }

        private function onScrollBarDown(e:MouseEvent):void
        {
            e.stopPropagation();
            startScrolling();
        }

        private function onScrollBarUp(e:MouseEvent):void
        {
            stopScrolling();
        }

        public function startScrolling():void
        {
            if (isScrolling)
            {
                return;
            }
            _scrolling = true;

            _scroller.startDrag(false, new Rectangle(0, 5, 0, getBarMaxY()));
            _scroller.stage.addEventListener(MouseEvent.MOUSE_MOVE, onScrollBarMove, false, 0, true);
            _scroller.stage.addEventListener(MouseEvent.MOUSE_UP, onScrollBarUp, false, 0, true);

            dispatchEvent(new Event(STARTED_SCROLLING));
        }

        public function stopScrolling():void
        {
            if (!isScrolling)
            {
                return;
            }
            _scroller.stopDrag();
            _scroller.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onScrollBarMove);
            _scroller.stage.removeEventListener(MouseEvent.MOUSE_UP, onScrollBarUp);
            _scrolling = false;
            dispatchEvent(new Event(STOPPED_SCROLLING));
        }

        public function get isScrolling():Boolean
        {
            return _scrolling;
        }

        private function onScrollBarMove(e:MouseEvent):void
        {
            var percent:Number = (_scroller.y - 5) / getBarMaxY();
            _scroll = percent * _maxScroll;

            announceScrolled();
        }
    }
}
