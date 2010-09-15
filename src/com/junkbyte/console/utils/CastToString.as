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
package com.junkbyte.console.utils {
	//import com.junkbyte.console.core.CommandTools;
	
	import flash.utils.getQualifiedClassName;		
	/**
	 * Produces better toString() for Error, XML, XMLList, Array, Vector
	 */
	public function CastToString(obj:*):String{
		if(obj is String){
			return obj;
		}else if(obj is Error) {
			var err:Error = obj as Error;
			// err.getStackTrace() is not supported in non-debugger players...
			var stackstr:String = err.hasOwnProperty("getStackTrace")?err.getStackTrace():err.toString();		
			if(stackstr){
				return stackstr;
			}
			return err.toString();
		}else if(obj is XML || obj is XMLList){
			return obj.toXMLString();
		}else if(obj is Array || getQualifiedClassName(obj).indexOf("__AS3__.vec::Vector.") == 0){
			// note: using getQualifiedClassName for vector for backward compatibility
			// Need to specifically cast to string in array to produce correct results
			// e.g: new Array("str",null,undefined,0).toString() // traces to: str,,,0, SHOULD BE: str,null,undefined,0
			var str:String = "[";
			var len:int = obj.length;
			for(var i:int = 0; i < len; i++){
				str += (i?",":"")+CastToString(obj[i]);
			}
			return str+"]";
		}
		// TODO: auto explode objects ?	
		return String(obj);
	}
}