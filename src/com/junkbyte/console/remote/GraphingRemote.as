package com.junkbyte.console.remote
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.Graphing;

	import flash.utils.ByteArray;

	public class GraphingRemote extends Graphing
	{
		public function GraphingRemote(m:Console)
		{
			super(m);

			remoter.registerCallback("graphGroups", onRemotingGraphGroups);
		}

		private function onRemotingGraphGroups(bytes:ByteArray):void
		{
			report(bytes);
		}
	}
}
