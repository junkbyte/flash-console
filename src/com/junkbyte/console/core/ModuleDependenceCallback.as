package com.junkbyte.console.core
{
    import com.junkbyte.console.events.ConsoleModuleEvent;
    import com.junkbyte.console.interfaces.IConsoleModule;
    import com.junkbyte.console.vos.ConsoleModuleMatch;

    import flash.utils.Dictionary;

    public class ModuleDependenceCallback
    {

        protected var srcModule:ConsoleModule;

        protected var unregisteredList:Vector.<DependentCallback> = new Vector.<DependentCallback>();

        protected var registeredMatches:Dictionary = new Dictionary();

        public function ModuleDependenceCallback(module:ConsoleModule)
        {
            this.srcModule = module;
			
			srcModule.addEventListener(ConsoleModuleEvent.REGISTERED_TO_CONSOLE, onSrcModuleRegistered);
			srcModule.addEventListener(ConsoleModuleEvent.UNREGISTERED_TO_CONSOLE, onSrcModuleUnregistered);
        }

        public function addCallback(matcher:ConsoleModuleMatch, registerCallback:Function, unregisterCallback:Function):void
        {
            var cb:DependentCallback = new DependentCallback(matcher, registerCallback, unregisterCallback);
			
            if (srcModule.console == null)
            {
                addToUnregisteredList(cb);
            }
            else
            {
                var matchingModule:IConsoleModule = srcModule.modules.findModuleByMatcher(matcher);

                if (matchingModule == null)
                {
                    addToUnregisteredList(cb);
                    srcModule.modules.addEventListener(ConsoleModuleEvent.MODULE_REGISTERED, onAnyModuleRegistered);
                }
                else
                {
                    matchRegistered(cb, matchingModule);
                }
            }
        }

        private function onSrcModuleRegistered(event:ConsoleModuleEvent):void
        {
            srcModule.modules.addEventListener(ConsoleModuleEvent.MODULE_REGISTERED, onAnyModuleRegistered);

            var len:uint = unregisteredList.length;
            for (var i:int = 0; i < len; i++)
            {
                var cb:DependentCallback = unregisteredList[i];
                var matchingModule:IConsoleModule = srcModule.modules.findModuleByMatcher(cb.moduleMatch);

                if (matchingModule != null)
                {
                    matchRegistered(cb, matchingModule);
                    i--;
                    len--;
                }
            }
        }

        private function onSrcModuleUnregistered(event:ConsoleModuleEvent):void
        {
            srcModule.modules.removeEventListener(ConsoleModuleEvent.MODULE_REGISTERED, onAnyModuleRegistered);
            var list:Vector.<IConsoleModule> = new Vector.<IConsoleModule>();

            for (var key:* in registeredMatches)
            {
                list.push(key as IConsoleModule);
            }
            for each (var matchModule:IConsoleModule in list)
            {
                var cb:DependentCallback = registeredMatches[matchModule];
                matchUnRegistered(cb, srcModule);
            }
        }

        private function onAnyModuleRegistered(event:ConsoleModuleEvent):void
        {
            for each (var cb:DependentCallback in unregisteredList)
            {
                if (cb.moduleMatch.matches(event.module))
                {
                    matchRegistered(cb, event.module);
                    break;
                }
            }
        }

        private function matchRegistered(cb:DependentCallback, module:IConsoleModule):void
        {
            registeredMatches[module] = cb;
            removeFromUnregisteredList(cb);

            module.addEventListener(ConsoleModuleEvent.UNREGISTERED_TO_CONSOLE, moduleUnregistered);
            cb.callRegistered(module);
        }

        private function matchUnRegistered(cb:DependentCallback, module:IConsoleModule):void
        {
            delete registeredMatches[module];
            addToUnregisteredList(cb);

            module.removeEventListener(ConsoleModuleEvent.UNREGISTERED_TO_CONSOLE, moduleUnregistered);
            cb.callUnregistered(module);
        }

        private function addToUnregisteredList(cb:DependentCallback):void
        {
            if (unregisteredList.indexOf(cb) < 0)
            {
                unregisteredList.push(cb);
            }
        }

        private function removeFromUnregisteredList(cb:DependentCallback):void
        {
            var index:int = unregisteredList.indexOf(cb);
            if (index >= 0)
            {
                unregisteredList.splice(index, 1);
            }
        }

        private function moduleUnregistered(event:ConsoleModuleEvent):void
        {
            var cb:DependentCallback = registeredMatches[event.module];
            if (cb != null)
            {
                matchUnRegistered(cb, event.module);
            }
        }
    }
}

import com.junkbyte.console.interfaces.IConsoleModule;
import com.junkbyte.console.vos.ConsoleModuleMatch;

class DependentCallback
{
    public var moduleMatch:ConsoleModuleMatch;

    public var registerCallback:Function;

    public var unregisterCallback:Function;

    public function DependentCallback(interestedModule:ConsoleModuleMatch, registerCallback:Function, unregisterCallback:Function):void
    {
        this.moduleMatch = interestedModule;
        this.registerCallback = registerCallback;
        this.unregisterCallback = unregisterCallback;
    }

    public function callRegistered(matchingModule:IConsoleModule):void
    {
        if (registerCallback != null)
        {
            registerCallback(matchingModule);
        }
    }

    public function callUnregistered(matchingModule:IConsoleModule):void
    {
        if (unregisterCallback != null)
        {
            unregisterCallback(matchingModule);
        }
    }
}
