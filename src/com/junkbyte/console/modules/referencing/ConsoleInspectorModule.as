package com.junkbyte.console.modules.referencing
{
	import com.junkbyte.console.core.ConsoleModule;
	import com.junkbyte.console.core.ConsoleModules;
	import com.junkbyte.console.core.Logs;
	import com.junkbyte.console.interfaces.IConsoleModule;
	import com.junkbyte.console.modules.remoting.IRemoter;
	import com.junkbyte.console.utils.EscHTML;
	import com.junkbyte.console.vos.ConsoleModuleMatch;
	import com.junkbyte.console.vos.WeakObject;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class ConsoleInspectorModule extends ConsoleModule
	{
		private var _current:*;// current will be kept as hard reference so that it stays...
		
		private var _history:Array;
		private var _hisIndex:uint;
		
		private var _dofull:Boolean;
		
		private var _ref:ConsoleReferencingModule;
		
		public function ConsoleInspectorModule()
		{
		}
		
		override public function getDependentModules():Vector.<ConsoleModuleMatch>
		{
			var vect:Vector.<ConsoleModuleMatch> = super.getDependentModules();
			vect.push(ConsoleModuleMatch.createForClass(IRemoter));
			vect.push(ConsoleModuleMatch.createForClass(ConsoleReferencingModule));
			return vect;
		}
		
		override public function dependentModuleRegistered(module:IConsoleModule):void
		{
			if(module is IRemoter)
			{
				var remoter:IRemoter = module as IRemoter;
				remoter.registerCallback("ref", function(bytes:ByteArray):void{
					handleString(bytes.readUTF());
				});
				remoter.registerCallback("focus", handleFocused);
			}
			if(module is ConsoleReferencingModule)
			{
				_ref = module as ConsoleReferencingModule;
			}
		}
		
		override public function dependentModuleUnregistered(module:IConsoleModule):void
		{
			if(module is IRemoter)
			{
				var remoter:IRemoter = module as IRemoter;
				remoter.registerCallback("ref", null);
				remoter.registerCallback("focus", null);
			}
			if(module is ConsoleReferencingModule)
			{
				_ref = null;
			}
		}
		
		
		private function historyInc(i:int):void{
			_hisIndex+=i;
			var v:* = _history[_hisIndex];
			if(v){
				focus(v, _dofull);
			}
		}
		public function handleRefEvent(str:String):void{
			if(remoter != null && !remoter.isSender){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF(str);
				remoter.send("ref", bytes);
			}else{
				handleString(str);
			}
		}
		
		private function handleString(str:String):void{
			if(str == "refexit"){
				exitFocus();
				_central.console.setViewingChannels();
			}else if(str == "refprev"){
				historyInc(-2);
			}else if(str == "reffwd"){
				historyInc(0);
			}else if(str == "refi"){
				focus(_current, !_dofull);
			}else{
				var ind1:int = str.indexOf("_")+1;
				if(ind1>0){
					var id:uint;
					var prop:String = "";
					var ind2:int = str.indexOf("_", ind1);
					if(ind2>0){
						id = uint(str.substring(ind1, ind2));
						prop = str.substring(ind2+1);
					}else{
						id = uint(str.substring(ind1));
					}
					var o:Object = _ref.getRefById(id);
					if(prop) o = o[prop];
					if(o){
						if(str.indexOf("refe_")==0){
							_central.console.explodech(_central.display.mainPanel.reportChannel, o);
						}else{
							focus(o, _dofull);
						}
						return;
					}
				}
				report("Reference no longer exist (garbage collected).", -2);
			}
		}
		
		public function focus(o:*, full:Boolean = false):void{
			if(remoter != null)
			{
				remoter.send("focus");
			}
			_central.console.clear(Logs.INSPECTING_CHANNEL);
			_central.console.setViewingChannels(Logs.INSPECTING_CHANNEL);
			
			if(!_history) _history = new Array();
			
			if(_current != o){
				_current = o; // current is kept as hard reference so that it stays...
				if(_history.length <= _hisIndex) _history.push(o);
				else _history[_hisIndex] = o;
				_hisIndex++;
			}
			_dofull = full;
			inspect(o, _dofull);
		}
		private function handleFocused():void{
			_central.console.clear(Logs.INSPECTING_CHANNEL);
			_central.console.setViewingChannels(Logs.INSPECTING_CHANNEL);
		}
		public function exitFocus():void{
			_current = null;
			_dofull = false;
			_history = null;
			_hisIndex = 0;
			if(remoter != null && remoter.isSender){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTF("refexit");
				remoter.send("ref", bytes);
			}
			_central.console.clear(Logs.INSPECTING_CHANNEL);
		}
		
		public function inspect(obj:*, viewAll:Boolean= true, ch:String = null):void {
			if(!obj){
				report(obj, -2, true, ch);
				return;
			}
			var refIndex:uint = _ref.setLogRef(obj);
			var showInherit:String = "";
			if(!viewAll) showInherit = " [<a href='event:refi'>show inherited</a>]";
			var menuStr:String;
			if(_history){
				menuStr = "<b>[<a href='event:refexit'>exit</a>]";
				if(_hisIndex>1){
					menuStr += " [<a href='event:refprev'>previous</a>]";
				}
				if(_history && _hisIndex < _history.length){
					menuStr += " [<a href='event:reffwd'>forward</a>]";
				}
				menuStr += "</b> || [<a href='event:ref_"+refIndex+"'>refresh</a>]";
				menuStr += "</b> [<a href='event:refe_"+refIndex+"'>explode</a>]";
				if(config.commandLineAllowed){
					menuStr += " [<a href='event:cl_"+refIndex+"'>scope</a>]";
				}
				
				if(viewAll) menuStr += " [<a href='event:refi'>hide inherited</a>]";
				else menuStr += showInherit;
				report(menuStr, -1, true, ch);
				report("", 1, true, ch);
			}
			//
			// Class extends... extendsClass
			// Class implements... implementsInterface
			// constant // statics
			// methods
			// accessors
			// varaibles
			// values
			// EVENTS .. metadata name="Event"
			//
			var V:XML = describeType(obj);
			var cls:Object = obj is Class?obj:obj.constructor;
			var clsV:XML = describeType(cls);
			var self:String = V.@name;
			var isClass:Boolean = obj is Class;
			var st:String = isClass?"*":"";
			var str:String = "<b>{"+st+_ref.genLinkString(obj, null, EscHTML(self))+st+"}</b>";
			var props:Array = [];
			var nodes:XMLList;
			if(V.@isStatic=="true"){
				props.push("<b>static</b>");
			}
			if(V.@isDynamic=="true"){
				props.push("dynamic");
			}
			if(V.@isFinal=="true"){
				props.push("final");
			}
			if(props.length > 0){
				str += " <p-1>"+props.join(" | ")+"</p-1>";
			}
			report(str, -2, true, ch);
			//
			// extends...
			//
			nodes = V.extendsClass;
			if(nodes.length()){
				props = [];
				for each (var extendX:XML in nodes) {
					st = extendX.@type.toString();
					props.push(st.indexOf("*")<0?makeValue(getDefinitionByName(st)):EscHTML(st));
					if(!viewAll) break;
				}
				report("<p10>Extends:</p10> "+props.join(" &gt; "), 1, true, ch);
			}
			//
			// implements...
			//
			nodes = V.implementsInterface;
			if(nodes.length()){
				props = [];
				for each (var implementX:XML in nodes) {
					props.push(makeValue(getDefinitionByName(implementX.@type.toString())));
				}
				report("<p10>Implements:</p10> "+props.join(", "), 1, true, ch);
			}
			report("", 1, true, ch);
			//
			// events
			// metadata name="Event"
			props = [];
			nodes = V.metadata.(@name == "Event");
			if(nodes.length()){
				for each (var metadataX:XML in nodes) {
					var mn:XMLList = metadataX.arg;
					var en:String = mn.(@key=="name").@value;
					var et:String = mn.(@key=="type").@value;
					if(refIndex) props.push("<a href='event:cl_"+refIndex+"_dispatchEvent(new "+et+"(\""+en+"\"))'>"+en+"</a><p0>("+et+")</p0>");
					else props.push(en+"<p0>("+et+")</p0>");
				}
				report("<p10>Events:</p10> "+props.join("<p-1>; </p-1>"), 1, true, ch);
				report("", 1, true, ch);
			}
			//
			// display's parents and direct children
			//
			if (obj is DisplayObject) {
				var disp:DisplayObject = obj as DisplayObject;
				var theParent:DisplayObjectContainer = disp.parent;
				if (theParent) {
					props = new Array("@"+theParent.getChildIndex(disp));
					while (theParent) {
						var pr:DisplayObjectContainer = theParent;
						theParent = theParent.parent;
						var indstr:String = theParent?"@"+theParent.getChildIndex(pr):"";
						props.push("<b>"+pr.name+"</b>"+indstr+makeValue(pr));
					}
					report("<p10>Parents:</p10> "+props.join("<p-1> -> </p-1>")+"<br/>", 1, true, ch);
				}
			}
			if (obj is DisplayObjectContainer) {
				props = [];
				var cont:DisplayObjectContainer = obj as DisplayObjectContainer;
				var clen:int = cont.numChildren;
				for (var ci:int = 0; ci<clen; ci++) {
					var child:DisplayObject = cont.getChildAt(ci);
					props.push("<b>"+child.name+"</b>@"+ci+makeValue(child));
				}
				if(clen){
					report("<p10>Children:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 1, true, ch);
				}
			}
			//
			// constants...
			//
			props = [];
			nodes = clsV..constant;
			for each (var constantX:XML in nodes) {
				report(" const <p3>"+constantX.@name+"</p3>:"+constantX.@type+" = "+makeValue(cls, constantX.@name.toString())+"</p0>", 1, true, ch);
			}
			if(nodes.length()){
				report("", 1, true, ch);
			}
			var inherit:uint = 0;
			var hasstuff:Boolean;
			var isstatic:Boolean;
			//
			// methods
			//
			props = [];
			nodes = clsV..method; // '..' to include from <factory>
			for each (var methodX:XML in nodes) {
				if(viewAll || self==methodX.@declaredBy){
					hasstuff = true;
					isstatic = methodX.parent().name()!="factory";
					str = " "+(isstatic?"static ":"")+"function ";
					var params:Array = [];
					var mparamsList:XMLList = methodX.parameter;
					for each(var paraX:XML in mparamsList){
						params.push(paraX.@optional=="true"?("<i>"+paraX.@type+"</i>"):paraX.@type);
					}
					if(refIndex && (isstatic || !isClass)){
						str += "<a href='event:cl_"+refIndex+"_"+methodX.@name+"()'><p3>"+methodX.@name+"</p3></a>";
					}else{
						str += "<p3>"+methodX.@name+"</p3>";
					}
					str += "("+params.join(", ")+"):"+methodX.@returnType;
					report(str, 1, true, ch);
				}else{
					inherit++;
				}
			}
			if(inherit){
				report("   \t + "+inherit+" inherited methods."+showInherit, 1, true, ch);
			}else if(hasstuff){
				report("", 1, true, ch);
			}
			//
			// accessors
			//
			hasstuff = false;
			inherit = 0;
			props = [];
			nodes = clsV..accessor; // '..' to include from <factory>
			for each (var accessorX:XML in nodes) {
				if(viewAll || self==accessorX.@declaredBy){
					hasstuff = true;
					isstatic = accessorX.parent().name()!="factory";
					str = " ";
					if(isstatic) str += "static ";
					var access:String = accessorX.@access;
					if(access == "readonly") str+= "get";
					else if(access == "writeonly") str+= "set";
					else str += "assign";
					
					if(refIndex && (isstatic || !isClass)){
						str += " <a href='event:cl_"+refIndex+"_"+accessorX.@name+"'><p3>"+accessorX.@name+"</p3></a>:"+accessorX.@type;
					}else{
						str += " <p3>"+accessorX.@name+"</p3>:"+accessorX.@type;
					}
					if(access != "writeonly" && (isstatic || !isClass))
					{
						str += " = "+makeValue(isstatic?cls:obj, accessorX.@name.toString());
					}
					report(str, 1, true, ch);
				}else{
					inherit++;
				}
			}
			if(inherit){
				report("   \t + "+inherit+" inherited accessors."+showInherit, 1, true, ch);
			}else if(hasstuff){
				report("", 1, true, ch);
			}
			//
			// variables
			//
			nodes = clsV..variable;
			for each (var variableX:XML in nodes) {
				isstatic = variableX.parent().name()!="factory";
				str = isstatic?" static":"";
				if(refIndex) str += " var <p3><a href='event:cl_"+refIndex+"_"+variableX.@name+" = '>"+variableX.@name+"</a>";
				else str += " var <p3>"+variableX.@name;
				str += "</p3>:"+variableX.@type+" = "+makeValue(isstatic?cls:obj, variableX.@name.toString());
				report(str, 1, true, ch);
			}
			//
			// dynamic values
			// - It can sometimes fail if we are looking at proxy object which havnt extended nextNameIndex, nextName, etc.
			try{
				props = [];
				for (var X:* in obj) {
					if(X is String){
						if(refIndex) str = "<a href='event:cl_"+refIndex+"_"+X+" = '>"+X+"</a>";
						else str = X;
						report(" dynamic var <p3>"+str+"</p3> = "+makeValue(obj, X), 1, true, ch);
					}else{
						report(" dictionary <p3>"+makeValue(X)+"</p3> = "+makeValue(obj, X), 1, true, ch);
					}
				}
			} catch(e : Error) {
				report("Could not get dynamic values. " + e.message, 9, false, ch);
			}
			if(obj is String){
				report("", 1, true, ch);
				report("String", 10, true, ch);
				report(EscHTML(obj), 1, true, ch);
			}else if(obj is XML || obj is XMLList){
				report("", 1, true, ch);
				report("XMLString", 10, true, ch);
				report(EscHTML(obj.toXMLString()), 1, true, ch);
			}
			if(menuStr){
				report("", 1, true, ch);
				report(menuStr, -1, true, ch);
			}
		}
		
		private function makeValue(obj:*, prop:* = null):String{
			return _ref.makeString(obj, prop, false, config.useObjectLinking?100:-1);
		}
		
	}
}