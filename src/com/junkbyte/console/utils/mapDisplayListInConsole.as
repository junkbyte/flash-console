package com.junkbyte.console.utils
{
	import com.junkbyte.console.Console;
	import com.junkbyte.console.modules.ConsoleModuleNames;
	import com.junkbyte.console.modules.referencing.ConsoleReferencingModule;
	import com.junkbyte.console.core.ModuleTypeMatcher;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;

	public function mapDisplayListInConsole(console:Console, base:DisplayObjectContainer, maxstep:uint = 0, ch:String = null):void{
		if(!base){
			console.logger.report("Not a DisplayObjectContainer.", 10, true, ch);
			return;
		}
		
		var steps:int = 0;
		var wasHiding:Boolean;
		var index:int = 0;
		var lastmcDO:DisplayObject = null;
		var list:Array = new Array();
		list.push(base);
		while(index<list.length){
			var mcDO:DisplayObject = list[index];
			index++;
			// add children to list
			if(mcDO is DisplayObjectContainer){
				var mc:DisplayObjectContainer = mcDO as DisplayObjectContainer;
				var numC:int = mc.numChildren;
				for(var i:int = 0;i<numC;i++){
					var child:DisplayObject = mc.getChildAt(i);
					list.splice(index+i,0,child);
				}
			}
			// figure out the depth and print it out.
			if(lastmcDO){
				if(lastmcDO is DisplayObjectContainer && (lastmcDO as DisplayObjectContainer).contains(mcDO)){
					steps++;
				}else{
					while(lastmcDO){
						lastmcDO = lastmcDO.parent;
						if(lastmcDO is DisplayObjectContainer){
							if(steps>0){
								steps--;
							}
							if((lastmcDO as DisplayObjectContainer).contains(mcDO)){
								steps++;
								break;
							}
						}
					}
				}
			}
			var str:String = "";
			for(i=0;i<steps;i++){
				str += (i==steps-1)?" ∟ ":" - ";
			}
			var refs:ConsoleReferencingModule = console.modules.getFirstMatchingModule(new ModuleTypeMatcher(ConsoleReferencingModule)) as ConsoleReferencingModule;
			if(maxstep<=0 || steps<=maxstep){
				wasHiding = false;
				var ind:uint = refs.setLogRef(mcDO);
				var n:String = mcDO.name;
				if(ind) n = "<a href='event:cl_"+ind+"'>"+n+"</a>";
				if(mcDO is DisplayObjectContainer){
					n = "<b>"+n+"</b>";
				}else{
					n = "<i>"+n+"</i>";
				}
				str += n+" "+refs.makeRefTyped(mcDO);
				console.logger.report(str,mcDO is DisplayObjectContainer?5:2, true, ch);
			}else if(!wasHiding){
				wasHiding = true;
				console.logger.report(str+"...",5, true, ch);
			}
			lastmcDO = mcDO;
		}
		console.logger.report(base.name + ":" +refs.makeRefTyped(base) + " has " + (list.length - 1) + " children/sub-children.", 9, true, ch);
		
		if(console.modules.findModulesByMatcher(new ModuleTypeMatcher(ICommandLine)) != null)
		{
			console.logger.report("Click on the child display's name to set scope.", -2, true, ch);
		}
	}
		
}