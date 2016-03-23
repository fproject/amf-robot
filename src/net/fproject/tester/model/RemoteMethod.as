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
package net.fproject.tester.model
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
		
		public function RemoteMethod(name:String='new', args:ArrayCollection=null)
		{
			this.name = name;
			this.arguments = args;
			if( this.arguments == null )
			{
				this.arguments = new ArrayCollection();
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
			var i:int = s.search(/(\r|\n)+( |t)*\* *@[a-z]+/);
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
		
		public function get asDoc():String
		{
			return this.doc;
		}
	}
}