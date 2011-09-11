package com.junkbyte.console.utils
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.modules.referencing.ConsoleReferencingModule;
	
	import flash.utils.ByteArray;
	import flash.utils.describeType;

	public function explodeObjectsInConsole(console:Console, obj:Object, depth:int = 3, p:int = 9):String
	{
		var t:String = typeof obj;
		if(obj == null){ 
			// could be null, undefined, NaN, 0, etc. all should be printed as is
			return "<p-2>"+obj+"</p-2>";
		}else if(obj is String){
			return '"'+EscHTML(obj as String)+'"';
		}else if(t != "object" || depth == 0 || obj is ByteArray){
			return console.modules.refs.makeString(obj);
		}
		if(p<0) p = 0;
		var V:XML = describeType(obj);
		var nodes:XMLList, n:String;
		var list:Array = [];
		//
		var stepExp:Function = function(console:Console,o:*, n:String, d:int, p:int):String{
			return n+":"+explodeObjectsInConsole(console, o[n], d-1, p-1);
		}
		//
		nodes = V["accessor"];
		for each (var accessorX:XML in nodes) {
			n = accessorX.@name;
			if(accessorX.@access!="writeonly"){
				try{
					list.push(stepExp(console, obj, n, depth, p));
				}catch(e:Error){}
			}else{
				list.push(n);
			}
		}
		//
		nodes = V["variable"];
		for each (var variableX:XML in nodes) {
			n = variableX.@name;
			list.push(stepExp(console, obj, n, depth, p));
		}
		//
		try{
			for (var X:String in obj) {
				list.push(stepExp(console, obj, X, depth, p));
			}
		}catch(e:Error){}
		return "<p"+p+">{"+ConsoleReferencingModule.ShortClassName(obj)+"</p"+p+"> "+list.join(", ")+"<p"+p+">}</p"+p+">";
	}
}