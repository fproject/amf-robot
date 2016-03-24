////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////
package net.fproject.robot.util
{
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.Fault;
	import mx.utils.ObjectProxy;
	import mx.utils.object_proxy;
	
	import net.fproject.utils.StringUtil;
	
	public class DataUtil
	{
		public static function getResultJSON(data:Object):String
		{
			if(data is Fault)
				return '{"name" : "' + Fault(data).name + '",\n' +
					'"faultCode" : "' + Fault(data).faultCode + '",\n' +
					'"faultDetail" : "' + Fault(data).faultDetail + '"}';
			return JSON.stringify(data,function(k:*,v:*):*{
				if(v is ObjectProxy)
				{
					return ObjectProxy(v).object_proxy::object;
				}
				return v;
			});
		}
		
		public static function getResultTree(resultData:Object):Array
		{
			propDepth = 0;
			if(isSimpleType(resultData))
			{
				var resultTree:Array = [simpleTypeToString(resultData)];
			} 
			else if(getQualifiedClassName(resultData) == 'mx.rpc::Fault')
			{
				var err:Object = {};
				err.label = 'Error';
				var dscr:Object = {};
				dscr.label = resultData.faultString as String;
				err.children = [dscr];
				resultTree = [err];	
			} 
			else 
			{
				if(resultData is Array)
					resultTree = makeTree(resultData as Array);
				else 
					resultTree = makeTree([resultData]);
				
				resultTree = enumerateTree(resultTree);
			}
			
			return resultTree;
		}
		
		private static function isSimpleType(data:Object):Boolean
		{
			if(data == null)
				return true;
			var t:String = getQualifiedClassName(data).toLowerCase();
			return (['uint','int','boolean','string', 'number','date','xml']).indexOf(t) != -1;
		}
		
		private static function simpleTypeToString(data:Object):String
		{
			if(data == null)
				return "null";
			if(data is XML)
				return XML(data).toXMLString();
			if(data.hasOwnProperty('toString') && data['toString'] is Function)
				return data['toString']();
			return String(data);
		}
		
		private static function toString(data:Object):String
		{
			if(isSimpleType(data))
				return simpleTypeToString(data);
			return String(data);
		}
		
		private static function enumerateTree(data:Object):Array
		{
			var a:Array = [];
			var n:int = 0;
			if(data is Array)
			{
				for each(var o:Object in data)
				{
					o.label = '('+n+') '+o.label; 
					if(o.hasOwnProperty('children'))
					{
						o.children = enumerateTree(o.children);
					}
					a.push(o);
					n++;
				}
			}			
			
			return a;	
		}
		
		private static function makeTree(source:Array):Array
		{
			var n:Array = [];
			for each(var o:Object in source)
			{
				n.push(makeNode(o));
			}
			return n;
		}
		
		private static function makeNode(o:Object):Object
		{
			var n:Object = {};
			
			if(o is Array) 
			{
				// branch?
				if(o.hasOwnProperty('label'))
					n.label = o.label;
				else 
					n.label = '(array)';
				n.children = makeTree(o as Array);
			} 
			else 
			{
				if(!o.hasOwnProperty('label'))
				{
					n.label = getQualifiedClassName(o);
					if(o.toString().charAt(0) != '[')
						n.label += ": " + String(o);
				} 
				else if(o.hasOwnProperty('label')) 
				{
					n.label = o.label;
				}
				var numprops:int = 0;
				for (var p:Object in o)
				{
					numprops++;
				}
				if(numprops > 0)
					n.children = propsToChildren(o);
			}
				
			return n;
		}
		
		private static var propDepth:int = 0;
		
		private static function propsToChildren(obj:Object):Array
		{
			propDepth++;
			var ret:Array = [];
			var o:Object;
			for (var prop:Object in obj)
			{
				var propVal:Object = obj[prop];
				o = {};
				var label:String = toString(propVal);
				if(label != null)
				{
					if(label.length > 50)
						label = label.substr(0,50) + "...";
					label = label.replace(/[\r\n\u000d\u000a\u0008\u0020]+/g," ");
				}
				o.label = String(prop) + " = " + label;
				
				if(propDepth < 5 && !(propVal is XML))
				{
					var n:int = 0;
					
					for (var s:String in propVal)
					{
						n++;
					}
					if(n > 0)
						o.children = propsToChildren(propVal);
				}
				
				ret.push(o);
			}
			propDepth--;
			return ret;				
		}
		
		public static function isBlank(s:String):Boolean
		{
			return s == null || s.length == 0;
		}
		
		public static function parseDate(str:String):Date
		{
			if(str == null || str == "")
				return null;
			var matches : Array = str.match(/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d).*/);
			
			var d : Date = new Date();
			
			d.setFullYear(int(matches[1]), int(matches[2]) - 1, int(matches[3]));
			d.setHours(int(matches[4]), int(matches[5]), int(matches[6]), 0);
			
			return d;
		}
		
		public static function parseBoolean(str:String):Boolean
		{
			if(str == null)
				return false;
			str = str.toLowerCase();
			switch(str)
			{
				case "true":
				case "t":
				case "1":
				case "yes":
				case "y":
					return true;
				default:
					return false;
			}
		}
		
		public static function parseNumber(str:String):Number
		{
			if(str == null || str == "")
				return NaN;
			else
				return Number(str);
		}
		
		public static function parseRemoteType(type:String):String
		{
			if(type == "mixed")
				type = "Object";
			if(type.toLowerCase() == "DateTime")
				type = "Date";
			if(type == "string")
				type = "String";
			if(type.toLowerCase() == "bool" || type.toLowerCase() == "boolean")
				type = "Boolean";
			if(type.toLowerCase() == "float" || type.toLowerCase() == "double" || type.toLowerCase() == "long")
				type = "Number";
			if(StringUtil.endsWith(type, "[]") || type.toLowerCase() == "array")
				type = "Array";
			return type;
		}		
	}
}