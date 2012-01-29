package com.junkbyte.console.core
{
	import com.junkbyte.console.ConsoleLevel;

	public class ConsoleTextLinks extends ConsoleModule
	{

		private var _linkMaps:Vector.<LinkMap> = new Vector.<LinkMap>();

		public function ConsoleTextLinks()
		{
			super();
		}

		public function onLinkClicked(link:String):void
		{
			var linkMap:LinkMap = findLinkMapForTerm(link);
			if (linkMap == null)
			{
				console.logger.report("Unknown link: [" + link + "].", ConsoleLevel.CONSOLE_EVENT);
			}
			else
			{
				linkMap.callback(link);
			}
		}

		public function addLinkCallback(expression:*, callback:Function):void
		{
			var linkMap:LinkMap = new LinkMap(expression);
			linkMap.callback = callback;
			_linkMaps.push(linkMap);
		}

		public function removeLinkCallback(expression:*, callback:Function):void
		{
			for (var i:int = _linkMaps.length - 1; i >= 0; i--)
			{
				if (_linkMaps[i].equals(expression) && _linkMaps[i].callback == callback)
				{
					_linkMaps.splice(i, 1);
				}
			}
		}

		private function findLinkMapForTerm(link:String):LinkMap
		{
			for each (var linkMap:LinkMap in _linkMaps)
			{
				if (linkMap.matches(link))
				{
					return linkMap;
				}
			}
			return null;
		}
	}
}

class LinkMap
{

	public var string:String;
	public var regexp:RegExp;
	public var callback:Function;

	public function LinkMap(expression:*)
	{
		if (expression is String)
		{
			string = expression as String;
		}
		else if (expression is RegExp)
		{
			regexp = expression as RegExp;
		}
		else
		{
			throw new Error("Unknow link callback exp: " + expression);
		}
	}

	public function matches(term:String):Boolean
	{
		if (regexp == null)
		{
			return string == term;
		}
		return term.replace(regexp, "") == "";
	}

	public function equals(expression:*):Boolean
	{
		if (regexp == null && expression is String)
		{
			return string == expression;
		}
		else if (regexp != null && expression is RegExp)
		{
			return regexp.source == RegExp(expression).source;
		}
		return false;
	}
}
