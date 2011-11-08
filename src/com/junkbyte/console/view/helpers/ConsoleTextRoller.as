package com.junkbyte.console.view.helpers
{
    import flash.events.TextEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;

    /**
     * @author LuAye
     */
    public class ConsoleTextRoller
    {


        private static const TEXT_ROLL:String = "TEXT_ROLL";

        public static function register(field:TextField, overhandle:Function, linkHandler:Function = null):void
        {
            field.addEventListener(MouseEvent.MOUSE_MOVE, onTextFieldMouseMove, false, 0, true);
            field.addEventListener(MouseEvent.ROLL_OUT, onTextFieldMouseOut, false, 0, true);
            field.addEventListener(TEXT_ROLL, overhandle, false, 0, true);
            if (linkHandler != null)
                field.addEventListener(TextEvent.LINK, linkHandler, false, 0, true);
        }

        private static function onTextFieldMouseOut(e:MouseEvent):void
        {
            TextField(e.currentTarget).dispatchEvent(new TextEvent(TEXT_ROLL));
        }

        private static function onTextFieldMouseMove(e:MouseEvent):void
        {
            var field:TextField = e.currentTarget as TextField;
            var index:int;
            if (field.scrollH > 0)
            {
                // kinda a hack really :(
                var scrollH:Number = field.scrollH;
                var w:Number = field.width;
                field.width = w + scrollH;
                index = field.getCharIndexAtPoint(field.mouseX + scrollH, field.mouseY);
                field.width = w;
                field.scrollH = scrollH;
            }
            else
            {
                index = field.getCharIndexAtPoint(field.mouseX, field.mouseY);
            }
            var url:String = null;
            //var txt:String = null;
            if (index > 0)
            {
                // TextField.getXMLText(...) is not documented
                try
                {
                    var X:XML = new XML(field.getXMLText(index, index + 1));
                    if (X.hasOwnProperty("textformat"))
                    {
                        var txtformat:XML = X["textformat"][0] as XML;
                        if (txtformat)
                        {
                            url = txtformat.@url;
                                //txt = txtformat.toString();
                        }
                    }
                }
                catch (err:Error)
                {
                    url = null;
                }
            }
            field.dispatchEvent(new TextEvent(TEXT_ROLL, false, false, url));
        }
    }
}
