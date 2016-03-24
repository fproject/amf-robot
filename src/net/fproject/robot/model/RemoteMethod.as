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
package net.fproject.robot.model
{
	import mx.collections.ArrayCollection;
	
	import net.fproject.utils.StringUtil;
	
	[RemoteClass(alias="RMethod")]
	public class RemoteMethod extends RemoteItemBase
	{
		[Bindable]
		public var arguments:ArrayCollection;
		
		[Bindable]
		public var returnType:String;
		
		[Bindable]
		public var returnASDoc:String;
		
		public function RemoteMethod(name:String='new', args:ArrayCollection=null)
		{
			this.name = name;
			this.arguments = args;
			if( this.arguments == null )
			{
				this.arguments = new ArrayCollection();
			}
		}
		
		public function populateASDocs():void
		{
			if(this.arguments == null || this.arguments.length == 0)
				return;
			var s:String = StringUtil.trim(this.doc, " \t");
			if(StringUtil.isBlank(s))
				return;
			var params:Object = {};
			var regex:RegExp = /( |\t)*\*( |\t)*@param(.(?!@param|@return|@var))*/g;
			var sp:String;
			var i:int;
			var p:Object;
			var r:Object;
			var pname:String;
			var ptype:String;
			do
			{
				r = regex.exec(s);
				if(r != null)
				{
					sp = r[0];
					if(sp != null)
					{
						i = sp.indexOf("@param");
						if(i > -1)
						{
							sp = StringUtil.trim(sp.substr(i + 6), " \t\r\n");
							i = sp.indexOf("$");
							if(i > -1)
							{
								p = {type:StringUtil.trim(sp.substr(0,i), " \t\r\n"),doc:""};
								sp = StringUtil.trim(sp.substr(i + 1), " \t\r\n");
								i = sp.indexOf(" ");
								if(i == -1)
									i = sp.indexOf("\t");
								if(i == -1)
									i = sp.length;
								p.name = StringUtil.trim(sp.substr(0, i), " \t\r\n");
								if(i < sp.length - 1)
									p.doc = StringUtil.trim(sp.substr(i + 1), " \t\r\n");
								params[p.name] = p;
							}
						}
					}
				}
				else
					break;
				
			} while(true);
			
			for each(var ra:RemoteVariable in this.arguments)
			{
				if(params.hasOwnProperty(ra.name))
					ra.doc = params[ra.name].doc;
			}
			i = s.lastIndexOf("@return");
			if(i > -1)
			{
				returnASDoc = StringUtil.trim(s.substr(i + 7), " \t\r\n");
				if(StringUtil.endsWith(returnASDoc, "*/"))
					returnASDoc = StringUtil.trim(returnASDoc.substr(0, returnASDoc.length - 2), " \t\r\n");
			}
		}
		
		override public function toString():String
		{
			return name;	
		}
		
		public function getASDocBody():String
		{
			var s:String = StringUtil.trim(this.doc);
			if(StringUtil.isBlank(s))
				return null;
			var i:int = s.search(/(\r|\n)+( |t)*\*( |\t)*@[a-z]+/);
			if(i > 0)
				s = s.substring(0, i);
			
			do
			{
				var a:Array = s.match(/^(\r|\n)*( |t)*(\*|\/\*\*)/);
				if(a != null && a.length > 0)
				{
					s = s.substr(a[0].length);
				}
				else
					break;
				
			} while(true);
			
			s = StringUtil.trim(s);
			
			return s;
		}
		
		override public function set doc(value:String):void
		{
			super.doc = value;
			dispatchChangeEvent("asDoc", null, this.asDoc);
		}
		
		[Bindable("propertyChange")]
		public function get asDoc():String
		{
			var s:String = "Method: " + this.name + "\n\n" +
				this.getASDocBody() + "\n";
			for each (var ra:RemoteVariable in this.arguments)
			{
				s = s + "\n@param " + ra.name + " " + ra.doc;
			}
			if(!StringUtil.isBlank(returnASDoc))
				s += "\n\n@return " + this.returnASDoc;
			
			return s;
		}
	}
}