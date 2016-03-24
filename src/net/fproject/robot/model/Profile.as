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
	
	[RemoteClass(alias="Profile")]
	public class Profile
	{
		[Bindable]
		public var xdebugSessionId:String;
		
		[Bindable]
		public var name:String = "new";
		[Bindable]
		public var url:String = "http://localhost/";
		[Bindable]
		public var useCredentials:Boolean = false;
		[Bindable]
		public var user:String = "admin";
		[Bindable]
		public var password:String;
		[Bindable]
		public var serviceDest:String = 'amfphp';
		[Bindable]
		public var services:ArrayCollection;
		
		public function Profile()
		{
			services = new ArrayCollection();
		}
		
		public function getServiceByName( name:String ):RemoteService
		{

			for each( var s:RemoteService in services )
			{
				if( s.name == name )
				{
					return s;
				}
			}
			return null;
		}
	}
}