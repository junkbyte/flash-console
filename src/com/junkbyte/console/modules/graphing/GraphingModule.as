package com.junkbyte.console.modules.graphing
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ConsoleTicker;
	import com.junkbyte.console.interfaces.ConsoleUpdateDataListener;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	import com.junkbyte.console.events.ConsoleEvent;
	
	import flash.events.Event;

	public class GraphingModule extends ConsoleModule implements ConsoleUpdateDataListener
	{
		protected var graphModule:GraphingCentralModule;

		protected var timeSinceUpdate:uint;

		private var _group:GraphingGroup;

		public function GraphingModule()
		{
			super();

			addModuleRegisteryCallback(new ModuleTypeMatcher(GraphingCentralModule), graphModuleRegistered, graphModuleUnregistered);
		}

		final public function get group():GraphingGroup
		{
			return _group;
		}

		protected function graphModuleRegistered(module:GraphingCentralModule):void
		{
			graphModule = module;
			checkIfDependenciesReady();
		}

		protected function graphModuleUnregistered(module:GraphingCentralModule):void
		{
			stop();
			graphModule = null;
		}

		protected function isDependenciesReady():Boolean
		{
			return graphModule != null;
		}

		protected function checkIfDependenciesReady():void
		{
			if (_group == null && isDependenciesReady())
			{
				onDependenciesReady();
			}
		}

		// OVERRIDE
		protected function onDependenciesReady():void
		{

		}

		protected function start():void
		{
			if (_group != null)
			{
				return;
			}
			timeSinceUpdate = 0;

			_group = createGraphingGroup();
			if (_group == null)
			{
				throw new Error("createGraphingGroup() must return non-null.");
			}
			_group.addEventListener(Event.CLOSE, onGroupClose);
			
			graphModule.registerGroup(_group);

			var ticker:ConsoleTicker = modules.findFirstModuleByClass(ConsoleTicker) as ConsoleTicker;
			ticker.addUpdateDataListener(this);
			
			pushValues();
		}
		
		protected function onGroupClose(event:Event):void
		{
			stop();
		}

		protected function stop():void
		{
			if (_group == null)
			{
				return;
			}
			
			var ticker:ConsoleTicker = modules.findFirstModuleByClass(ConsoleTicker) as ConsoleTicker;
			ticker.removeUpdateDataListener(this);
			
			graphModule.removeGroup(_group);
			_group = null;
		}
		
		
		public function onUpdateData(msDelta:uint):void
		{
			timeSinceUpdate += msDelta;

			if (timeSinceUpdate >= _group.updateFrequencyMS)
			{
				pushValues();
				timeSinceUpdate = Math.min(timeSinceUpdate - _group.updateFrequencyMS, _group.updateFrequencyMS)
			}
		}

		protected function pushValues():void
		{
			var values:Vector.<Number> = getValues();
			if (values != null)
			{
				if (values.length != _group.lines.length)
				{
					throw new Error("Graphing: getValues() must retun the same number of lenght as group.lines.length.");
				}
				_group.push(values);
			}
		}

		// OVERRIDE
		protected function createGraphingGroup():GraphingGroup
		{
			return null;
		}

		// OVERRIDE
		protected function getValues():Vector.<Number>
		{
			return null;
		}

		override protected function unregisteredFromConsole():void
		{
			stop();
			super.unregisteredFromConsole();
		}
	}
}
