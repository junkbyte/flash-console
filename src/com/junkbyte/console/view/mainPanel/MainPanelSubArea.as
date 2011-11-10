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

    
    import flash.geom.Rectangle;
    import com.junkbyte.console.view.ConsoleDisplayModule;
    import com.junkbyte.console.view.ConsolePanel;

    public class MainPanelSubArea extends ConsoleDisplayModule
    {

        private var parentPanel:ConsolePanel;

        private var _area:Rectangle = new Rectangle();

        public function MainPanelSubArea(parentPanel:ConsolePanel)
        {
            super();
            this.parentPanel = parentPanel;
        }

        override protected function registeredToConsole():void
        {
            super.registeredToConsole();

            if (parentPanel != null)
            {
                parentPanel.addChild(sprite);
            }
        }

        override protected function unregisteredFromConsole():void
        {
            super.unregisteredFromConsole();

            if (parentPanel != null)
            {
                parentPanel.removeChild(sprite);
            }
        }

        protected function get mainPanel():MainPanel
        {
            return layer.mainPanel;
        }

        public function setArea(x:Number, y:Number, width:Number, height:Number):void
        {
            _area.x = x;
            _area.y = y;
            _area.width = width;
            _area.height = height;
        }

        public function get area():Rectangle
        {
            return _area;
        }
    }
}
