/*
 *
 * Copyright (c) 2008-2010 Lu Aye Oo
 *
 * @author 		Lu Aye Oo
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
 */
package com.junkbyte.console.modules.commandLine
{
    import com.junkbyte.console.core.ConsoleModule;
    import com.junkbyte.console.interfaces.IConsoleModule;
    import com.junkbyte.console.modules.ConsoleModuleNames;
    import com.junkbyte.console.interfaces.IRemoter;
    import com.junkbyte.console.utils.EscHTML;
    import com.junkbyte.console.core.ModuleTypeMatcher;

    import flash.utils.ByteArray;
    import flash.utils.getQualifiedClassName;

    public class SlashCommandLine extends ConsoleModule implements ICommandLine
    {
        private var _slashCmds:Object;

        public function SlashCommandLine()
        {
            super();
            _slashCmds = new Object();

            addInternalSlashCommand("help", printHelp, "How to use command line");
            addInternalSlashCommand("commands", cmdsCmd, "Show a list of all slash commands", true);
			
			addModuleRegisteryCallback(new ModuleTypeMatcher(IRemoter), remoterRegistered, remoterUnregistered);
        }

        protected function remoterRegistered(remoter:IRemoter):void
        {
           remoter.registerCallback("cmd", function(bytes:ByteArray):void
           {
           		run(bytes.readUTF());
           });
        }

		protected function remoterUnregistered(remoter:IRemoter):void
        {
        	remoter.registerCallback("cmd", null);
        }

        override public function getModuleName():String
        {
            return ConsoleModuleNames.COMMAND_LINE;
        }

        public function getHintsFor(str:String, max:uint):Array
        {
            var all:Array = getAllHintCandidates();
            str = str.toLowerCase();
            var hints:Array = new Array();
            for each (var canadate:Array in all)
            {
                if (canadate[0].toLowerCase().indexOf(str) == 0)
                {
                    hints.push(canadate);
                }
            }
            hints = hints.sort(function(a:Array, b:Array):int
            {
                if (a[0].length < b[0].length)
                    return -1;
                if (a[0].length > b[0].length)
                    return 1;
                return 0;
            });
            if (max > 0 && hints.length > max)
            {
                hints.splice(max);
                hints.push([ "..." ]);
            }
            return hints;
        }

        protected function getAllHintCandidates():Array
        {
            var all:Array = new Array();
            for (var X:String in _slashCmds)
            {
                var cmd:Object = _slashCmds[X];
                if (config.commandLineAllowed || cmd.allow)
                    all.push([ "/" + X + " ", cmd.d ? cmd.d : null ]);
            }
            return all;
        }

        public function get scopeString():String
        {
            return "";
        }

        public function addInternalSlashCommand(n:String, callback:Function, desc:String = "", allow:Boolean = false, endOfArgsMarker:String = ";"):void
        {
            var split:Array = n.split("|");
            for (var i:int = 0; i < split.length; i++)
            {
                n = split[i];
                if (callback != null)
                {
                    _slashCmds[n] = new SlashCommand(n, callback, desc, false, allow, endOfArgsMarker);
                    if (i > 0)
                        _slashCmds.setPropertyIsEnumerable(n, false);
                }
                else
                {
                    delete _slashCmds[n];
                }
            }
        }

        public function addSlashCommand(n:String, callback:Function, desc:String = "", alwaysAvailable:Boolean = true, endOfArgsMarker:String = ";"):void
        {
            n = n.replace(/[^\w]*/g, "");
            if (_slashCmds[n] != null)
            {
                var prev:SlashCommand = _slashCmds[n];
                if (!prev.user)
                {
                    throw new Error("Can not alter build-in slash command [" + n + "]");
                }
            }
            if (callback == null)
                delete _slashCmds[n];
            else
                _slashCmds[n] = new SlashCommand(n, callback, EscHTML(desc), true, alwaysAvailable, endOfArgsMarker);
        }

        public function run(str:String, saves:* = null):*
        {
            if (!str)
                return;
            str = str.replace(/\s*/, "");
			
            report("&gt; " + str, 4, false);
            var v:* = null;
            try
            {
                if (str.charAt(0) == "/")
                {
                    execCommand(str.substring(1));
                }
                else
                {
                    execCommand(str);
                }
            }
            catch (e:Error)
            {
                reportError(e);
            }
            return v;
        }

        private function execCommand(str:String):void
        {
            var brk:int = str.search(/[^\w]/);
            var cmd:String = str.substring(0, brk > 0 ? brk : str.length);
            var param:String = brk > 0 ? str.substring(brk + 1) : "";
            if (_slashCmds[cmd] != null)
            {
                try
                {
                    var slashcmd:SlashCommand = _slashCmds[cmd];
                    var restStr:String;
                    if (slashcmd.endMarker)
                    {
                        var endInd:int = param.indexOf(slashcmd.endMarker);
                        if (endInd >= 0)
                        {
                            restStr = param.substring(endInd + slashcmd.endMarker.length);
                            param = param.substring(0, endInd);
                        }
                    }
                    if (param.length == 0)
                    {
                        slashcmd.f();
                    }
                    else
                    {
                        slashcmd.f(param);
                    }
                    if (restStr)
                    {
                        run(restStr);
                    }
                }
                catch (err:Error)
                {
                    reportError(err);
                }
            }
            else
            {
                report("Undefined command <b>/commands</b> for list of all commands.", 10);
            }
        }

        private function reportError(e:Error):void
        {
            var str:String = console.logger.makeString(e);
            var lines:Array = str.split(/\n\s*/);
            var p:int = 10;
            var internalerrs:int = 0;
            var len:int = lines.length;
            var parts:Array = [];
            var reg:RegExp = new RegExp("\\s*at\\s+(" + Executer.CLASSES + "|" + getQualifiedClassName(this) + ")");
            for (var i:int = 0; i < len; i++)
            {
                var line:String = lines[i];
                if (line.search(reg) == 0)
                {
                    // don't trace more than one internal errors :)
                    if (internalerrs > 0 && i > 0)
                    {
                        break;
                    }
                    internalerrs++;
                }
                parts.push("<p" + p + "> " + line + "</p" + p + ">");
                if (p > 6)
                    p--;
            }
            report(parts.join("\n"), 9);
        }


        private function cmdsCmd(... args:Array):void
        {
            var buildin:Array = [];
            var custom:Array = [];
            for each (var cmd:SlashCommand in _slashCmds)
            {
                if (config.commandLineAllowed || cmd.allow)
                {
                    if (cmd.user)
                        custom.push(cmd);
                    else
                        buildin.push(cmd);
                }
            }
            buildin = buildin.sortOn("n");
            report("Built-in commands:" + (!config.commandLineAllowed ? " (limited permission)" : ""), 4);
            for each (cmd in buildin)
            {
                report("<b>/" + cmd.n + "</b> <p-1>" + cmd.d + "</p-1>", -2);
            }
            if (custom.length)
            {
                custom = custom.sortOn("n");
                report("User commands:", 4);
                for each (cmd in custom)
                {
                    report("<b>/" + cmd.n + "</b> <p-1>" + cmd.d + "</p-1>", -2);
                }
            }
        }

        /*
                private function inspectCmd(...args:Array):void
                {
                    _central.refs.focus(_scope);
                }
        */

        private function printHelp(... args:Array):void
        {
            report("____Command Line Help___", 10);
            report("/filter (text) = filter/search logs for matching text", 5);
            report("/commands to see all slash commands", 5);
            report("__________", 10);
        }
    }
}

internal class SlashCommand
{
    public var n:String;

    public var f:Function;

    public var d:String;

    public var user:Boolean;

    public var allow:Boolean;

    public var endMarker:String;

    public function SlashCommand(nn:String, ff:Function, dd:String, cus:Boolean, permit:Boolean, argsMarker:String)
    {
        n = nn;
        f = ff;
        d = dd ? dd : "";
        user = cus;
        allow = permit;
        endMarker = argsMarker;
    }
}