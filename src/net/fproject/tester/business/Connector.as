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
package net.fproject.tester.business
{
	import mx.controls.Alert;
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.mxml.RemoteObject;
	
	import net.fproject.tester.controller.EventHub;
	import net.fproject.tester.events.LogEvent;
	import net.fproject.tester.events.StatusChangeEvent;
	import net.fproject.tester.model.Profile;
	import net.fproject.tester.model.RArgument;
	import net.fproject.tester.model.RMethod;
	import net.fproject.tester.model.RService;
	import net.fproject.tester.model.ServiceInfo;
	import net.fproject.tester.util.DataUtil;
	
	public class Connector
	{
		public static var FMT_AMFPHP:String = "amfphp";
		
		private var eventHub:EventHub 		= EventHub.getInstance();
		private var serviceInfo:ServiceInfo 	= ServiceInfo.getInstance();

		private var proxy:RemoteObject;
		
		private static var _instance:Connector;
		
		public function Connector()
		{
			if(_instance != null)
			{
				throw new Error("Connector must be used as singleton");
			}
		}
		
		public static function getInstance():Connector
		{
			if(_instance == null)
				_instance = new Connector;
			
			return _instance;
		}
		
		public function connect( profile:Profile ):void
		{
			eventHub.dispatchEvent( new StatusChangeEvent( StatusChangeEvent.CONNECTING ) );
			
			proxy = new RemoteObject();
			proxy.endpoint = DataUtil.isBlank(profile.xdebugSessionId) ? profile.url : profile.url + "&XDEBUG_SESSION_START=" + profile.xdebugSessionId;
			proxy.destination = profile.serviceDest;
			
			if(profile.useCredentials)
				proxy.setCredentials(profile.user, profile.password);
			
			proxy.showBusyCursor = true;
			eventHub.dispatchEvent( new StatusChangeEvent( StatusChangeEvent.CONNECTED ) );
		}
		
		public function call( service:RService, method:RMethod, resp:RResponder ):void
		{	
			var profile:Profile = ServiceInfo.getInstance().activeProfile;
			proxy.endpoint = DataUtil.isBlank(profile.xdebugSessionId) ? profile.url : profile.url + "&XDEBUG_SESSION_START=" + profile.xdebugSessionId;
			proxy.source = service.name;
			var op:AbstractOperation = proxy.getOperation( method.name );
			if( !op.hasEventListener( ResultEvent.RESULT ) )
				op.addEventListener( ResultEvent.RESULT, resp.result );
			if( !op.hasEventListener( FaultEvent.FAULT ) )
				op.addEventListener( FaultEvent.FAULT, resp.fault );

			// set arguments
			var args:Array = new Array();
			for each( var arg:RArgument in method.arguments ) 
			{
				args.push(arg.remoteValue);	
			}
			op.arguments = args;
			
			// call
			op.send();
		}
		
		public function discover(format:String, serviceName:String, methodName:String):void
		{
			serviceInfo.activeProfile.services.removeAll();
			eventHub.dispatchEvent( new StatusChangeEvent( StatusChangeEvent.RESET ) );
			proxy.source = serviceName;
			if( format == Connector.FMT_AMFPHP )
			{
				if(methodName == null || methodName == '')
					methodName = 'discover';
				var op:AbstractOperation = proxy.getOperation(methodName);
				if( !op.hasEventListener( ResultEvent.RESULT ) )
					op.addEventListener( ResultEvent.RESULT, onAMFPHPDiscoverResult );
				if( !op.hasEventListener( FaultEvent.FAULT ) )
					op.addEventListener( FaultEvent.FAULT, onServicesFault );
				op.send();
			}
		}
		
		private function onAMFPHPDiscoverResult( event:ResultEvent ):void
		{
			
			for each(var serviceObj:Object in event.result)
			{				
				// Create service
				var service:RService = new RService(serviceObj.name as String);
				service.doc = serviceObj.comment;
				for each(var methodObj:Object in serviceObj.methods)
				{
					var method:RMethod = new RMethod(methodObj.name as String);
					method.doc = methodObj.comment;
					for each(var arg:Object in methodObj.parameters)
					{
						if(arg.type == undefined || arg.type == "")
							eventHub.dispatchEvent(new LogEvent(LogEvent.LOG, 
								"[WARN]Empty parameter type:\r\nService: " + service.name + ", Method: " + method.name
								+ ", Parameter: " + arg.name));
						method.arguments.addItem(new RArgument(arg.name as String, arg.type)); 
					}
					service.methods.addItem(method);
				}
				
				serviceInfo.activeProfile.services.addItem(service);
			}
		}
		
		private function onServicesFault( event:FaultEvent ):void
		{
			Alert.show("Unable to do services discovery, invalid service URL or server response", "Error");
		}
	}
}