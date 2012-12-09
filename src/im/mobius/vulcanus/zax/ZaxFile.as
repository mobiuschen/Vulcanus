package im.mobius.vulcanus.zax
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    import flash.utils.setTimeout;
    
    import im.mobius.vulcanus.debug.Debugger;

    public class ZaxFile
    {
        /*** 版本 */        
        static public const ZAX_VERSION:Number = 1.0;
        
        /*** key限制的字节数 */        
        static public const KEY_LIMIT:int = 100;
        
        /*** 每个ZaxBlockIndex保存在本地后，占多少字节 */        
        static public var IDX_BYTES_LEN:int = 8 + KEY_LIMIT;
        
        /*** 最大Block数量*/        
        static public const BLOCK_MAX:int = 100;
        
        
        private var _version:Number = 0;
        
        /**
         * 是否只读 
         */        
        private var _isReadOnly:Boolean = false;
        
        /**
         * key -> ZaxBlockIndex 
         */        
        private var _indexDict:Object;
        
        /**
         * ZaxBlockIndex数量 
         */        
        private var _indexesNum:int = 0;
        
        private var _fileStream:FileStream;
        
        private var _file:File;
        
        private var _path:String
        
        private var _state:String;
        
        
        /**
         * 如果没有path指定的文件不存在，且isReadOnly=false，则会创建一个新文件。 
         * 
         * @param path
         * @param isReadOnly 是否是只读属性
         * 
         */        
        public function ZaxFile(path:String, isReadOnly:Boolean)
        {
            if(path == null || path == "")
            {
                _state = ZaxFileState.INVALID;
                throw new ArgumentError("Argument Error");
                return;
            }
            
            _isReadOnly = isReadOnly;
            _path = path;
            init();
        }
        
        
        /**
         * 读取一段资源, 异步。
         * @param key
         * @param callback function(ba:ByteArray):void
         */        
        public function readByKey(key:String, callback:Function):void
        {
            if(!checkState([ZaxFileState.OPEN]))
                return;
            
            var idx:ZaxBlockIndex = _indexDict[key];
            if(idx == null)
            {
                throw new Error("错误的Key");
                return;
            }
            
            var ba:ByteArray = new ByteArray();
            if(_fileStream.position == idx.postion)
            {
                _fileStream.readBytes(ba, 0, idx.len);
                setTimeout(callback, 10, ba);
                return;
            }
            
            //trace("idx", idx.postion, idx.len);
            //trace("before read:", "_fileStream.position:" + _fileStream.position, "_fileStream.bytesAvailable:" + _fileStream.bytesAvailable);
            _fileStream.addEventListener(Event.COMPLETE, onSetPositionComplete);
            _fileStream.position = idx.postion;
            
            function onSetPositionComplete(evt:Event):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onSetPositionComplete);
                _fileStream.readBytes(ba, 0, idx.len);
                //trace("after read:", "_fileStream.position:" + _fileStream.position, "_fileStream.bytesAvailable:" + _fileStream.bytesAvailable);
                callback(ba);
            }
        }
        
        
        /**
         * 是否有这个key，必须是OPEN状态才能查询.
         *  
         * @param key
         * @return 
         * 
         */        
        public function hasKey(key:String):Boolean
        {
            if(!checkState([ZaxFileState.OPEN, ZaxFileState.OPERATING]))
                return false;
            
            return _indexDict[key] != null;
        }
        
        
        /**
         * To do... 
         * @param key
         * @return 
         * 
         */        
        /*public function deleteByKey(key:String):Boolean
        {
            if(!checkState([ZaxFileState.OPEN]))
                return false;
            
            return false;
        }*/
        
        
        /**
         * 增加一个Block 
         * @param byteArray
         * @param key
         * @param callback function(success:Boolean):void 
         * 
         */
        public function appendBlock(baArray:Array/*of ByteArray*/, 
                                    keys:Array/*of String*/, 
                                    callback:Function):void
        {
            if(!checkState([ZaxFileState.OPEN]))
            {
                callback(false);
                return;
            }
            if(_isReadOnly)
            {
                throw new Error("This is File is readonly.");
                callback(false);
                return;
            }
            Debugger.assert(baArray.length == keys.length);
            if(_indexesNum + baArray.length >= BLOCK_MAX)
            {
                throw new Error("超过ZaxFile可容纳最大的Block数量。最大Block数量:" + BLOCK_MAX);
                callback(false);
                return;
            }
            
            var n:int = keys.length;
            var indexes:Vector.<ZaxBlockIndex> = new Vector.<ZaxBlockIndex>(n);
            
            _state = ZaxFileState.OPERATING;
            _fileStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            _fileStream.addEventListener(Event.COMPLETE, onOpen);
            _fileStream.position = _fileStream.position + _fileStream.bytesAvailable;
            
            function onOpen(evt:Event):void
            {
                //写入内容
                for(var i:int = 0; i < n; i++)
                {
                    var k:String = keys[i];
                    var ba:ByteArray = baArray[i];
                    if(k == null || k == "" || ba == null || ba.length == 0)
                        continue;
                    if(_indexDict[k] != null)
                        continue;
                    var idx:ZaxBlockIndex = new ZaxBlockIndex();
                    idx.postion = _fileStream.position;
                    idx.key = keys[i];
                    idx.len = ba.length;
                    //trace("idx", idx.postion, idx.len);
                    //trace("before write:", "_fileStream.position:" + _fileStream.position, "_fileStream.bytesAvailable:" + _fileStream.bytesAvailable);
                    _fileStream.writeBytes(ba, 0, ba.length);
                    _indexDict[k] = idx;
                    _indexesNum++;
                }
                
                _fileStream.removeEventListener(Event.COMPLETE, onOpen);
                _fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                //trace("after write:", "_fileStream.position:" + _fileStream.position, "_fileStream.bytesAvailable:" + _fileStream.bytesAvailable);
                _state = ZaxFileState.OPEN;
                if(callback != null)
                    callback(true);
            }
            
            function onIOError(evt:IOErrorEvent):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onOpen);
                _fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                _state = ZaxFileState.OPEN;
                if(callback != null)
                    callback(false);
            }
        }
        
        
        /**
         * 异步打开文件 
         * 
         * @return function(success:Boolean):void
         * 
         */        
        public function open(callback:Function):void
        {
            if(!checkState([ZaxFileState.CLOSED]))
            {
                callback(false);
                return;
            }
            
            if(_fileStream == null)
                _fileStream = new FileStream();
            
            _state = ZaxFileState.OPERATING;
            _fileStream.addEventListener(Event.COMPLETE, onOpenComplete);
            _fileStream.openAsync(_file, FileMode.UPDATE);
            
            function onOpenComplete(evt:Event):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onOpenComplete);
                
                _indexDict = {};
                //状态赋值要写在前面，因为readFileHead()要求状态是OPEN
                _state = ZaxFileState.OPEN;
                if(_fileStream.bytesAvailable == 0)
                {
                    //新文件，写入头信息
                    _version = ZAX_VERSION;
                    _indexesNum = 0;
                    _fileStream.writeFloat(ZaxFile.ZAX_VERSION);//写入版本号
                    _fileStream.writeInt(0);//写入Block数量
                    //预留ZaxFile.BLOCK_MAX个Block的空间
                    var n:int = ZaxFile.BLOCK_MAX * ZaxFile.IDX_BYTES_LEN;
                    for(var i:int = 0; i < n; i++)
                        _fileStream.writeByte(0);
                }
                else
                {
                    readFileHead();
                }
                
                
                if(callback != null)
                    callback(true);
            }
        }
        
        
        /**
         * 关闭文件 
         * @return function(success:Boolean):void
         * 
         */        
        public function close(callback:Function):void
        {
            if(!checkState([ZaxFileState.OPEN]))
            {
                callback(false);
                return;
            }
            _state = ZaxFileState.OPERATING;
            saveIndexes(onSaveIndexesComplete);
            
            function onSaveIndexesComplete(success:Boolean):void
            {
                _fileStream.addEventListener(Event.CLOSE, onClose);
                _fileStream.close();
            }
            
            function onClose():void
            {
                _fileStream.removeEventListener(Event.CLOSE, onClose);
                _fileStream = null;
                _indexDict = null;
                _indexesNum = 0;
                _state = ZaxFileState.CLOSED;
                
                callback(true);
            }
        }
        
        
        /**
         *  
         * @param callback function(success:Boolean):void
         * 
         */        
        private function saveIndexes(callback:Function):void
        {
            _fileStream.addEventListener(Event.COMPLETE, onSetPositionComplete);
            _fileStream.position = 4;//跳过版本号
            
            function onSetPositionComplete(evt:Event):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onSetPositionComplete);
                _fileStream.writeInt(_indexesNum);
                var count:int = 0;
                for(var k:String in _indexDict)
                {
                    count++;
                    
                    var keyBa:ByteArray = new ByteArray();
                    keyBa.writeUTFBytes(k);
                    var fillLen:int = Math.max(0, KEY_LIMIT - keyBa.length);
                    //key长度不够KEY_LIMIT字节，则后面填充0。
                    for(var i:int = 0; i < fillLen; i++)
                    {
                        keyBa.writeByte(0);
                    }
                    Debugger.assert(keyBa.length == KEY_LIMIT);
                    
                    var idx:ZaxBlockIndex = _indexDict[k];
                    _fileStream.writeInt(idx.postion);
                    _fileStream.writeInt(idx.len);
                    _fileStream.writeBytes(keyBa, 0, keyBa.length);
                }
                Debugger.assert(count == _indexesNum);
                
                callback(true);
            }
        }
        
        
        public function getState():String
        {
            return _state;
        }
        
        
        public function isReadOnly():Boolean
        {
            return _isReadOnly;
        }
        
        
        /**
         * 当前这个ZaxFile的版本 
         * @return 
         * 
         */        
        public function getVersion():Number
        {
            if(!checkState([ZaxFileState.OPEN]))
                return 0;
            
            return _version;
        }
            
        
        private function init():void
        {
            _file = new File(_path);
            var file:FileReference;
            if(_file.isPackage)
            {
                _state = ZaxFileState.INVALID;
                throw Error("错误路径。");
                return;
            }
            if(!_file.exists)
            {
                if(_isReadOnly)
                {
                    _state = ZaxFileState.INVALID;
                    throw Error("ReadOnly模式，无法创建新文件。");
                    return;
                }
            }
            _state = ZaxFileState.CLOSED;
        }
        
        
        /**
         * 读取文件头和索引信息。需要保证_fileStream.position == 0。 
         * 
         */        
        private function readFileHead():void
        {
            if(!checkState([ZaxFileState.OPEN]))
                return;
            
            Debugger.assert(_fileStream.position == 0);
            
            _version = _fileStream.readFloat();
            _indexesNum = _fileStream.readInt();

            var prePos:int = 0;
            var postPos:int = 0;
            for(var i:int = 0; i < _indexesNum; i++)
            {
                if(i == 0)
                    prePos = _fileStream.position;
                
                var idx:ZaxBlockIndex = new ZaxBlockIndex();
                idx.postion = _fileStream.readInt();
                idx.len = _fileStream.readInt();
                idx.key = _fileStream.readUTFBytes(KEY_LIMIT);
                _indexDict[idx.key] = idx;
                
                if(i == 0)
                    postPos = _fileStream.position;
            }
            //计算每个索引
            IDX_BYTES_LEN = postPos - prePos;
        }
        
        
        private function checkState(permittedState:Array):Boolean
        {
            if(permittedState.indexOf(_state) < 0)
            {
                throw new Error("改状态下不允许此操作: state=" + _state);
                return false;
            }
            return true;
        }
        
        
        //----------------------------------------------------------------------
        //
        //  Test methods
        //
        //----------------------------------------------------------------------
        
        public function _testGetIndexNum():int
        {
            if(!checkState([ZaxFileState.OPEN]))
                return 0;
            
            return _indexesNum;
        }
        
    }
}