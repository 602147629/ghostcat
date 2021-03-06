package ghostcattools.util
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NativeDragOptions;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.NativeDragEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import ghostcat.fileformat.zip.ZipFile;
	import ghostcat.util.text.ANSI;
	
	import mx.controls.Alert;

	public final class FileControl
	{
		static public function dragFileIn(rHandler:Function,target:*,extension:Array = null,isDirectory:Boolean = false,isAll:Boolean = false):void
		{
			if (!(target is Array))
				target = [target];
			
			for each (var child:IEventDispatcher in target)
			{
				if (child)
				{
					child.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER,onDragIn);		
					child.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP,onDrop);
				}
			}
			
			function onDragIn(event:NativeDragEvent):void
			{
				var transferable:Clipboard = event.clipboard;
				if (transferable.hasFormat(ClipboardFormats.FILE_LIST_FORMAT))
				{
					var files:Array = transferable.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
					if (files)
					{
						var file:File = File(files[0]);
						if (isAll)
						{
							NativeDragManager.acceptDragDrop(event.currentTarget as InteractiveObject);
						}
						else if (isDirectory)
						{ 
							if (file.isDirectory)
								NativeDragManager.acceptDragDrop(event.currentTarget as InteractiveObject);
						}
						else						
						{
							if (!file.isDirectory && (!extension || extension.length == 0 || extension.lastIndexOf(file.extension.toLowerCase()) != -1))
								NativeDragManager.acceptDragDrop(event.currentTarget as InteractiveObject);
						}
					}
				}
			}
			
			function onDrop(event:NativeDragEvent):void
			{
				rHandler(event.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT));
			}
		}
		
		static public function dragTextFileOut(target:InteractiveObject,data:*,relativePath:String):void
		{
			var transfer:Clipboard = new Clipboard();
			transfer.setDataHandler(ClipboardFormats.FILE_PROMISE_LIST_FORMAT,getDataHandler);
			NativeDragManager.doDrag(target,transfer);
			
			function getDataHandler():Array
			{
				var bytes:ByteArray = new ByteArray();
				var text:* = data is Function ? data() : data;
				if (text is String)
					bytes.writeUTFBytes(text as String);
				else if (text is ByteArray)
 					bytes = text as ByteArray;
				
				return [new CreateFilePromise(relativePath,bytes)];
			}
		}
		
		static public function browseForOpen(rHandler:Function,title:String = "选择一个文件",extension:Array = null):void
		{
			var file:File = File.documentsDirectory;
			file.browseForOpen(title,extension);
			if (rHandler != null)
				file.addEventListener(Event.SELECT,selectHandler);
			
			function selectHandler(event:Event):void
			{
				rHandler([file]);
			}
		}
		
		static public function browseForOpenMultiple(rHandler:Function,title:String = "选择多个文件",extension:Array = null):void
		{
			var file:File = File.documentsDirectory;
			file.browseForOpenMultiple(title,extension);
			if (rHandler != null)
				file.addEventListener(FileListEvent.SELECT_MULTIPLE,selectHandler);
			
			function selectHandler(event:FileListEvent):void
			{
				rHandler(event.files);
			}
		}
		
		static public function browseForSave(rHandler:Function,title:String = "保存文件",path:String = null):void
		{
			var file:File = File.documentsDirectory;
			if (path)
				file = file.resolvePath(path);
			file.browseForSave(title);
			if (rHandler != null)
				file.addEventListener(Event.SELECT,selectHandler);
			
			function selectHandler(event:Event):void
			{
				rHandler([file]);
			}
		}
		
		static public function browseForDirectory(rHandler:Function,title:String = "选择一个目录"):void
		{
			var file:File = File.documentsDirectory;
			file.browseForDirectory(title);
			if (rHandler != null)
				file.addEventListener(Event.SELECT,selectHandler);
			
			function selectHandler(event:Event):void
			{
				rHandler([file]);
			}
		}
		
		static public function readFile(file:File):ByteArray
		{
			var fs:FileStream = new FileStream();
			fs.open(file,FileMode.READ);
			var bytes:ByteArray = new ByteArray();
			fs.readBytes(bytes);
			fs.close();
			return bytes;
		}
		
		
		static public function writeFile(file:File,bytes:ByteArray):void
		{
			if (!bytes)
				return;
			bytes.position = 0;
			
			var fs:FileStream = new FileStream();
			fs.open(file,FileMode.WRITE);
			fs.writeBytes(bytes);
			fs.close();
		}
		
		static public function createLoadContext():LoaderContext
		{
			var context:LoaderContext = new LoaderContext();
			context.allowCodeImport = true;
			return context;
		}
		
		static public function getSWFFromSWC(bytes:ByteArray):ByteArray
		{
			try
			{
				var zip:ZipFile = new ZipFile(bytes);
				return zip.getInput(zip.getEntry("library.swf"))
			} 
			catch(error:Error) 
			{	
			}
			return null;
		}
		
		static public function run(file:File,arg:Array = null,exitHandler:Function = null,traceHandler:Function =  null,errorHandler:Function =  null,workingDirectory:File = null):Boolean
		{
			if (!file.exists)
				return false;
			
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			nativeProcessStartupInfo.executable = file;
			nativeProcessStartupInfo.workingDirectory = workingDirectory;
			
			if (arg)
			{
				var vector:Vector.<String> = new Vector.<String>();
				vector.push.apply(null,arg);
				nativeProcessStartupInfo.arguments = vector;
			}
			
			var process:NativeProcess = new NativeProcess();
			
			if (dataHandler != null)
			{
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,dataHandler);
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA,dataHandler);
			}
			
			if (exitHandler != null)
				process.addEventListener(NativeProcessExitEvent.EXIT,exitHandler);
			
			process.start(nativeProcessStartupInfo);
			return true;
			
			function dataHandler(event:Event):void
			{
				var process:NativeProcess = event.currentTarget as NativeProcess;
				var str:String;
				if (event.type == ProgressEvent.STANDARD_OUTPUT_DATA)
				{
					str = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,"gb2312").toString();
					if (traceHandler != null)
						traceHandler(str);
				}
				else
				{
					str = process.standardError.readMultiByte(process.standardError.bytesAvailable,"gb2312").toString();
					if (errorHandler != null)
						errorHandler(str);
				}
				
			}
		}
		
		static public function runNotePad(url:String,completeHandler:Function = null):void
		{
			var file:File = new File(Config.NOTEPAD_PATH);
			if (file.exists)
				FileControl.run(file,[url],completeHandler);
		}
		
		static public function runMXMLC(source:*,completeHandler:Function = null,traceHandler:Function = null,errorHandler:Function = null,sendResultBytes:Boolean = true):void
		{
			var mxmls:File = new File(Config.MXMLC_PATH);
			if (!mxmls.exists)
				return;
			
			if (source is String)
			{	
				var text:String = source as String;
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(text);
				var temp:File = File.createTempDirectory();
				var asFile:File = temp.resolvePath("Test.as");
				var swfFile:File = temp.resolvePath("Test.swf");
				FileControl.writeFile(asFile,bytes);
			}
			else if (source is File)
			{
				asFile = source as File;
				swfFile = asFile.parent.resolvePath(asFile.name.split(".")[0] + ".swf");
			}
			else
			{
				return;
			}
			var params:Array = [asFile.nativePath,"-debug=false"];
			if (Config.FLEXSDK_4_0)
				params.push("-static-link-runtime-shared-libraries=true");
			FileControl.run(mxmls,params,exitHandler,traceHandler,errorHandler)
			function exitHandler(event:Event):void
			{
				var swfBytes:ByteArray = swfFile.exists ? (sendResultBytes ? FileControl.readFile(swfFile) : new ByteArray()) : null;
				if (completeHandler != null)
					completeHandler(swfBytes);
				
				if (source is String)
					temp.deleteDirectory(true);
			}
		}
		
		static public function openExplorer(path:String):void
		{
			try
			{
				var explorer:File = new File(Config.EXPLORER_PATH);
				if (!explorer.exists)
					return;
				
				FileControl.run(explorer,[path])
			}
			catch (e:Error){};
		}
	}
}