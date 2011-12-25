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

    import com.junkbyte.console.core.ConsoleModule;

    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Sprite;
    import flash.events.Event;

    [Event(name = "addedToConsoleLayer", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    [Event(name = "removedFromConsoleLayer", type = "com.junkbyte.console.events.ConsolePanelEvent")]
    public class ConsoleDisplayModule extends ConsoleModule
    {

        private var _display:DisplayObject;

        protected var initlizedToConsole:Boolean;

        public function ConsoleDisplayModule()
        {
            super();

            createDisplay();

            if (sprite != null)
            {
                sprite.addEventListener(Event.ADDED, onAddedHandle);
                sprite.addEventListener(Event.REMOVED, onRemovedHandle);
            }
        }

        protected function createDisplay():void
        {
            _display = new Sprite();
        }

        // override for init
        protected function initToConsole():void
        {

        }

        override protected function registeredToConsole():void
        {
            super.registeredToConsole();

            if (initlizedToConsole == false)
            {
                initlizedToConsole = true;
                initToConsole();
            }
        }
		
		override protected function unregisteredFromConsole():void
		{
			removeFromParent();
			super.unregisteredFromConsole();
		}
		
		public function removeFromParent():void
		{
			if (parent != null)
			{
				parent.removeChild(sprite);
			}
		}

        private function onAddedHandle(e:Event):void
        {
            if (e.target == sprite)
            {
                onAddedToParentDisplay();
            }
        }

        private function onRemovedHandle(e:Event):void
        {
            if (e.target == sprite)
            {
                onRemovedFromParentDisplay();
            }
        }

        protected function onAddedToParentDisplay():void
        {
            // override if needed
        }

        protected function onRemovedFromParentDisplay():void
        {
            // override if needed
        }

        public function addChild(child:DisplayObject):void
        {
            sprite.addChild(child);
        }

        public function removeChild(child:DisplayObject):void
        {
            sprite.removeChild(child);
        }

        public function get display():DisplayObject
        {
            return _display;
        }

        public function get sprite():Sprite
        {
            return _display as Sprite;
        }

        public function get name():String
        {
            return sprite.name;
        }

        public function get parent():DisplayObjectContainer
        {
            return sprite.parent;
        }

        public function get x():Number
        {
            return sprite.x;
        }

        public function set x(n:Number):void
        {
            sprite.x = n;
        }

        public function get y():Number
        {
            return sprite.y;
        }

        public function set y(n:Number):void
        {
            sprite.y = n;
        }
    }
}
