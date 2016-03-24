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
package net.fproject.robot.business
{
	import mx.rpc.AbstractOperation;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.mxml.RemoteObject;
	
	import net.fproject.robot.controller.EventHub;
	import net.fproject.robot.events.LogEvent;
	import net.fproject.robot.events.StatusChangeEvent;
	import net.fproject.robot.model.Profile;
	import net.fproject.robot.model.RemoteMethod;
	import net.fproject.robot.model.RemoteModel;
	import net.fproject.robot.model.RemoteService;
	import net.fproject.robot.model.RemoteVariable;
	import net.fproject.robot.model.ServiceInfo;
	import net.fproject.robot.util.DataUtil;
	
	public class Connector
	{
		public static var FMT_PHP_AMF:String = "phpamf";
		
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
		
		public function connect(profile:Profile):void
		{
			eventHub.dispatchEvent(new StatusChangeEvent(StatusChangeEvent.CONNECTING));
			
			proxy = new RemoteObject();
			proxy.endpoint = DataUtil.isBlank(profile.xdebugSessionId) ? profile.url : profile.url + "&XDEBUG_SESSION_START=" + profile.xdebugSessionId;
			proxy.destination = profile.serviceDest;
			
			if(profile.useCredentials)
				proxy.setCredentials(profile.user, profile.password);
			
			proxy.showBusyCursor = true;
			eventHub.dispatchEvent(new StatusChangeEvent(StatusChangeEvent.CONNECTED));
		}
		
		public function call(service:RemoteService, method:RemoteMethod, resp:RecoveryResponder):void
		{	
			var profile:Profile = ServiceInfo.getInstance().activeProfile;
			proxy.endpoint = DataUtil.isBlank(profile.xdebugSessionId) ? profile.url : profile.url + "&XDEBUG_SESSION_START=" + profile.xdebugSessionId;
			proxy.source = service.name;
			var op:AbstractOperation = proxy.getOperation(method.name);
			if(!op.hasEventListener(ResultEvent.RESULT))
				op.addEventListener(ResultEvent.RESULT, resp.result);
			if(!op.hasEventListener(FaultEvent.FAULT))
				op.addEventListener(FaultEvent.FAULT, resp.fault);

			// set arguments
			var args:Array = new Array();
			for each(var arg:RemoteVariable in method.arguments) 
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
			serviceInfo.activeProfile.models.removeAll();
			eventHub.dispatchEvent(new StatusChangeEvent(StatusChangeEvent.RESET));
			proxy.source = serviceName;
			if(format == Connector.FMT_PHP_AMF)
			{
				if(methodName == null || methodName == '')
					methodName = 'discover';
				var op:AbstractOperation = proxy.getOperation(methodName);
				if(!op.hasEventListener(ResultEvent.RESULT))
					op.addEventListener(ResultEvent.RESULT, onPhpAmfDiscoverResult);
				if(!op.hasEventListener(FaultEvent.FAULT))
					op.addEventListener(FaultEvent.FAULT, onServicesFault);
				op.send();
			}
		}
		
		private function onPhpAmfDiscoverResult(event:ResultEvent):void
		{
			if(event.result == null || !event.result.hasOwnProperty("services"))
				return;
			
			var serviceObjects:Array = event.result["services"];
			for each(var serviceObj:Object in serviceObjects)
			{				
				// Create service
				var service:RemoteService = new RemoteService(serviceObj.name as String);
				service.doc = serviceObj.comment;
				for each(var methodObj:Object in serviceObj.methods)
				{
					var method:RemoteMethod = new RemoteMethod(methodObj.name as String);
					method.doc = methodObj.comment;
					method.returnType = DataUtil.parseRemoteType(methodObj.returnType);
					for each(var arg:Object in methodObj.parameters)
					{
						if(arg.type == undefined || arg.type == "")
							eventHub.dispatchEvent(new LogEvent(LogEvent.LOG, 
								"[WARN]Empty parameter type:\r\nService: " + service.name + ", Method: " + method.name
								+ ", Parameter: " + arg.name));
						method.arguments.addItem(new RemoteVariable(arg.name, DataUtil.parseRemoteType(arg.type))); 
					}
					method.populateASDocs();
					service.methods.addItem(method);
				}
				
				serviceInfo.activeProfile.services.addItem(service);
			}
			
			var modelObjects:Array = event.result["models"];
			
			for each(var modelObj:Object in modelObjects)
			{				
				// Create service
				var model:RemoteModel = new RemoteModel(modelObj.name as String);
				model.doc = modelObj.comment;
				for each(var propObj:Object in modelObj.properties)
				{
					var prop:RemoteVariable = new RemoteVariable(propObj.name as String);
					prop.doc = propObj.comment;
					prop.type = DataUtil.parseRemoteType(propObj.type);
					
					model.properties.addItem(prop);
				}
				
				serviceInfo.activeProfile.models.addItem(model);
			}
		}
		
		private function onServicesFault(event:FaultEvent):void
		{
			eventHub.dispatchEvent(new LogEvent(LogEvent.LOG, 
				"[ERROR]Unable to do services discovery, invalid service URL or server response:\r\n" + event.fault.message));
		}
	}
}