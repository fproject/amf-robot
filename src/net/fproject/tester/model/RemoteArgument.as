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
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.controls.Alert;
	
	import net.fproject.tester.util.DataUtil;
	
	[RemoteClass(alias="RArgument")]
	public class RemoteArgument extends RemoteItemBase
	{
		[Bindable]
		public var type:String;
		[Bindable]
		public var value:String;
		
		public function get remoteValue():*
		{
			var v:* = undefined;
			if(this.type == TYPE_NULL)
			{
				v = null;
			}
			else if(this.type == TYPE_JSON)
			{
				try 
				{
					v = JSON.parse(this.value);
				} catch(e:Error)
				{
					Alert.show("Invalid JSON string: '"+this.value+"'", "Error");
				}
			} 
			else if(this.type == TYPE_DATE_TIME)
			{
				v = DataUtil.parseDate(this.value);
			}
			else if(this.type == TYPE_BOOLEAN)
			{
				v = DataUtil.parseBoolean(this.value);
			}
			else if(this.type == TYPE_NUMBER)
			{
				v = DataUtil.parseNumber(this.value);
			}
			else 
			{
				v = this.value;	
			}
			
			return v;
		}
		
		
		public function RemoteArgument(name:String='new', type:String=TYPE_STRING, value:String='')
		{
			this.name = name;
			this.value = value;
			this.type = type;
		}

		public static const TYPE_STRING:String = "String";
		public static const TYPE_JSON:String = "JSON";
		public static const TYPE_DATE_TIME:String = "DateTime";
		public static const TYPE_BOOLEAN:String = "Boolean";
		public static const TYPE_NUMBER:String = "Number";
		public static const TYPE_NULL:String = "<null>";
		
		[Bindable("none")]
		public static var allTypes:IList = new ArrayList([TYPE_STRING, TYPE_BOOLEAN, 
			TYPE_DATE_TIME, TYPE_JSON, TYPE_NUMBER, TYPE_NULL]);
	}
}