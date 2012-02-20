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
package com.junkbyte.console.addons.htmlexport
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.core.LogReferences;
	import com.junkbyte.console.vos.Log;
	
	import flash.utils.describeType;

	/**
	 * @private
	 */
	public class ConsoleHTMLRefsGen
	{
		private static const refSearchExpression:RegExp = /<a(\s+)href=\'event:ref_(\d+)\'>/g;
		
		private var console:Console;
		private var referencesDepth:uint;
		
		private var referencesMap:Object;
		
		public function ConsoleHTMLRefsGen(console:Console, referencesDepth:uint)
		{
			this.console = console;
			this.referencesDepth = referencesDepth;
		}
		
		public function fillData(data:Object):void
		{
			referencesMap = new Object();
			
			data.references = referencesMap;
			
			var line:Log = console.logs.last;
			while(line)
			{
				processRefIdsFromLine(line.text);
				line = line.prev;
			}
		}
		
		private function processRefIdsFromLine(line:String, currentDepth:uint = 0):void
		{
			refSearchExpression.lastIndex = 0;
			var result:Object = refSearchExpression.exec(line);
			while(result != null)
			{
				var id:uint = uint(result[2]);
				processRefId(id, currentDepth);
				result = refSearchExpression.exec(line);
			}
		}
		
		private function processRefId(id:uint, currentDepth:uint):void
		{
			var obj:* = console.refs.getRefById(id);
			if(obj != null && referencesMap[id] == null)
			{
				referencesMap[id] = processRef(obj, currentDepth);
			}
		}
		
		private function processRef(obj:Object, currentDepth:uint):Object
		{
			// should reuse code from LogReference, but not possible atm. wait for modular version.
			
			var V:XML = describeType(obj);
			var cls:Object = obj is Class?obj:obj.constructor;
			var clsV:XML = describeType(cls);
			
			var isClass:Boolean = obj is Class;
			
			var result:Object = new Object();
			var isstatic:Boolean;
			var targetObj:Object;
			
			
			result.name = LogReferences.EscHTML(V.@name);
			/*
			var properties:Object = new Object();
			result.properties = properties;
			properties.isStatic = V.@isDynamic=="true";
			properties.isDynamic = V.@isDynamic=="true";
			properties.isFinal = V.@isFinal=="true";
			*/
			//
			// constants
			//
			var constants:Object = new Object();
			result.constants = constants;
			for each (var constantX:XML in clsV..constant)
			{
				constants[constantX.@name.toString()] = makeValue(cls, constantX.@name.toString(), currentDepth);
			}
			//
			// accessors
			//
			var accessors:Object = new Object();
			result.accessors = accessors;
			var staticAccessors:Object = new Object();
			result.staticAccessors = staticAccessors;
			for each (var accessorX:XML in clsV..accessor)
			{
				isstatic = accessorX.parent().name()!="factory";
				targetObj = isstatic ? staticAccessors : accessors;
				
				if(accessorX.@access.toString() != "writeonly" && (isstatic || !isClass))
				{
					targetObj[accessorX.@name] = makeValue(isstatic?cls:obj, accessorX.@name.toString(), currentDepth);
				}
			}
			
			//
			// variables
			//
			var variables:Object = new Object();
			result.variables = variables;
			var staticVariables:Object = new Object();
			result.staticVariables = staticVariables;
			for each (var variableX:XML in clsV..variable) 
			{
				isstatic = variableX.parent().name()!="factory";
				targetObj = isstatic ? staticVariables : variables;
				targetObj[variableX.@name] = makeValue(isstatic ? cls : obj, variableX.@name.toString(), currentDepth);
			}
			//
			// dynamic values
			// - It can sometimes fail if we are looking at proxy object which havnt extended nextNameIndex, nextName, etc.
			var dynamicVariables:Object = new Object();
			result.dynamicVariables = dynamicVariables;
			try
			{
				for (var X:* in obj)
				{
					dynamicVariables[X] = makeValue(obj, X, currentDepth);
				}
			}
			catch(e : Error)
			{
				result.dynamicVariables = e.message;
			}
			
			return result;
		}
		
		private function makeValue(obj:*, prop:*, currentDepth:uint):String
		{
			try
			{
				var v:* = obj[prop];
			}
			catch(err:Error)
			{
				return "<p0><i>"+err.toString()+"</i></p0>";
			}
			var string:String = console.refs.makeString(v, null, true);
			if(currentDepth < referencesDepth)
			{
				currentDepth++;
				processRefIdsFromLine(string, currentDepth);
			}
			return string;
		}
		
	}
}