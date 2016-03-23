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
package net.fproject.tester.controller
{
	import com.adobe.air.preferences.Preference;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import net.fproject.tester.business.Connector;
	import net.fproject.tester.events.ProfileModifiedEvent;
	import net.fproject.tester.model.Profile;
	import net.fproject.tester.model.ServiceInfo;

	public class ConnectController
	{
		[Bindable]
		public var profiles:ArrayCollection;
		
		private var prefs:Preference;
		private var serviceInfo:ServiceInfo = ServiceInfo.getInstance();
		private var eventHub:EventHub = EventHub.getInstance();
		private var fileName:String = "data.obj";
		
		public function ConnectController()
		{
			loadProfiles();
			eventHub.addEventListener( ProfileModifiedEvent.CHANGED, onProfileModified );
		}
		
		private function onProfileModified( event:ProfileModifiedEvent ):void
		{
			saveProfiles();
		}
		
		public function loadProfiles(prefsFile:File=null):void
		{
			if(prefsFile == null)
				prefsFile = File.applicationStorageDirectory.resolvePath(fileName);
			var fs:FileStream = new FileStream();
			if( !prefsFile.exists )
			{
				profiles = new ArrayCollection();
			} else {
				try {
					fs.open( prefsFile, FileMode.READ );
					profiles = fs.readObject() as ArrayCollection;
					fs.close();
				} catch( e:Error ) {
					Alert.show( "Error while loading profiles: "+e.message, "Load error");
				}
			}
		}
		
		public function saveProfiles(prefsFile:File=null):void
		{
			if(prefsFile == null)
				prefsFile = File.applicationStorageDirectory.resolvePath(fileName);		
			var fs:FileStream = new FileStream();
			try {
				fs.open( prefsFile, FileMode.WRITE );
				fs.writeObject(profiles);
				fs.close();
			} catch( e:Error ) {
				Alert.show("Failed to save profiles: "+e.message, "Save error");
			}
		}
		
		public function deleteProfile( index:int):void
		{
			profiles.removeItemAt( index );	
		}
		
		public function addProfile():void
		{
			var profile:Profile = new Profile();
			profiles.addItem( profile );
		}
		
		public function connect( p:Profile ):void
		{
			serviceInfo.activeProfile = p;
			var connector:Connector = Connector.getInstance();
			connector.connect( p );
		}

		private static var _instance:ConnectController;
		public static function getInstance():ConnectController
		{
			if(_instance == null)
				_instance = new ConnectController();
			return _instance;
		}
	}
}