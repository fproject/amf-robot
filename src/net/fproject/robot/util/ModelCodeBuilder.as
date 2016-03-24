package net.fproject.robot.util
{
	import mx.core.ByteArrayAsset;
	import mx.utils.StringUtil;
	
	import net.fproject.as3syntaxhighlight.CodePrettyPrint;
	import net.fproject.robot.model.RemoteModel;
	import net.fproject.robot.model.RemoteVariable;

	public class ModelCodeBuilder
	{
		[Bindable]
		public var packageName:String;
		
		[Bindable]
		public var model:RemoteModel;
		
		public function ModelCodeBuilder(model:RemoteModel)
		{
			this.model = model;
		}
		
		[Embed(source="modelTemplate.txt", mimeType="application/octet-stream")]  
		private var TEMPLATE:Class;
		
		private var _template:String;
		
		public function get template():String
		{
			if(_template == null)
			{
				var byteArray:ByteArrayAsset = ByteArrayAsset(new TEMPLATE());  
				_template = byteArray.readUTFBytes(byteArray.length);
				_template = _template.replace("r\n", "\n");
			}
			
			return _template;
		}
		
		public function build():String
		{
			if(packageName == null)
				packageName = "com.mypackage";
			return StringUtil.substitute(this.template, this.packageName, model.name, model.name, buildMembers());
		}
		
		public function buildPrettyPrint():String
		{
			var prettyPrint:CodePrettyPrint = new CodePrettyPrint();
			return prettyPrint.prettyPrintOne(this.build(), null, true);
		}
		
		protected function buildMembers():String
		{
			var s:String = "";
			for each (var variable:RemoteVariable in this.model.properties)
			{
				if(s != "")
					s += "\n\n        ";
				s += variable.doc + "\n        public var " + variable.name + ":" + variable.type + ";"; 
			}
			return s;
		}
	}
}