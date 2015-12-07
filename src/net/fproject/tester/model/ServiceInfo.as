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
	import net.fproject.tester.business.Connector;
	import net.fproject.tester.controller.EventHub;
	import net.fproject.tester.events.ProfileModifiedEvent;
	import net.fproject.tester.events.StatusChangeEvent;
	
	public class ServiceInfo
	{
		private var eventHub:EventHub = EventHub.getInstance();
		
		[Bindable]
		public var activeProfile:Profile;
		
		private static var _instance:ServiceInfo;
		
		public function ServiceInfo()
		{
			if(_instance != null)
			{
				throw new Error("Connector must be used as singleton");
			}
		}
		
		public static function getInstance():ServiceInfo
		{
			if(_instance == null)
				_instance = new ServiceInfo;
			
			return _instance;
		}
		
		private function onDisconnect( event:StatusChangeEvent ):void
		{
			activeProfile = null;
		}
		
		public function dataChanged():void
		{
			eventHub.dispatchEvent( new ProfileModifiedEvent( ProfileModifiedEvent.CHANGED ) );
		}

	}
}