package im.mobius.vulcanus.zax
{
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;
    
    import im.mobius.vulcanus.debug.Debugger;

    /**
     * 
     * 
     * 可扩展功能:
     * <li>可设置.zax文件里最大Block数量</li>
     * <li>完成deleteByKey(), cmopress()</li>
     * 
     * @author mobius.chen
     * 
     */    
    public class ZaxFile
    {
        /*** 版本 */
        static public const ZAX_VERSION:Number = 1.0;
        
        /*** key限制的字节数 */        
        static public const KEY_LIMIT:int = 100;
        
        /*** 每个ZaxBlockIndex保存在本地后，占多少字节 */        
        static public var IDX_BYTES_LEN:int = 8 + KEY_LIMIT;
        
        /*** 默认最大Block数量*/        
        static public const MAX_BLOCKS:int = 100;
        
        
        
        /*** 当前ZaxFile的版本 */        
        private var _version:Number = 0;
        
        /*** 是否只读 */        
        private var _isReadOnly:Boolean = false;
        
        /*** key -> ZaxBlockIndex */        
        private var _indexDict:Object;
        
        /*** ZaxBlockIndex数量 */        
        private var _indexesNum:int = 0;
        
        private var _fileStream:FileStream;
        
        private var _file:File;
        
        /*** 当前状态. ZaxFileState */        
        private var _state:String;
        
        /**
         * 操作锁。每个操作开始时，会把这个锁+1，完成后-1。所有操作完成后，这个锁==0。
         * 用于处理多个并发异步操作。
         */        
        private var _operationLock:int = 0;
        
        /*** 读请求的队列 */        
        private var _readQueue:Vector.<ReadRequest>;
        
        
        
        
        /**
         * 如果没有path指定的文件不存在，且isReadOnly=false，则会创建一个新文件。 
         * 
         * @param path
         * @param isReadOnly 是否是只读属性
         * @param maxBlocks 最大Block数量。如果是这个.zax文件当前已经存在，则会忽略这个参数，以.zax文件的参数为准。
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
            init(path);
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
        public function deleteByKey(key:String):Boolean
        {
            return false;
        }
        
        
        /**
         * 
         * @param baArray
         * @param keys
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
                throw new Error("This is File is read only.");
                callback(false);
                return;
            }
            Debugger.assert(baArray.length == keys.length);
            if(_indexesNum + baArray.length >= MAX_BLOCKS)
            {
                throw new Error("超过ZaxFile可容纳最大的Block数量。最大Block数量:" + MAX_BLOCKS);
                callback(false);
                return;
            }
            
            var n:int = keys.length;
            var indexes:Vector.<ZaxBlockIndex> = new Vector.<ZaxBlockIndex>(n);
            
            _state = ZaxFileState.OPERATING;
            _operationLock++;
            _fileStream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            _fileStream.addEventListener(Event.COMPLETE, onSetPosition);
            _fileStream.position = _fileStream.position + _fileStream.bytesAvailable;
            
            function onSetPosition(evt:Event):void
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
                    _fileStream.writeBytes(ba, 0, ba.length);
                    _indexDict[k] = idx;
                    _indexesNum++;
                }
                
                _fileStream.removeEventListener(Event.COMPLETE, onSetPosition);
                _fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                
                if(--_operationLock == 0)
                    _state = ZaxFileState.OPEN;
                
                if(callback != null)
                    callback(true);
            }
            
            function onIOError(evt:IOErrorEvent):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onSetPosition);
                _fileStream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                
                if(--_operationLock == 0)
                    _state = ZaxFileState.OPEN;
                
                if(callback != null)
                    callback(false);
            }
        }
        
        
        /**
         * 异步打开文件 
         * 
         * @param callback function(success:Boolean):void
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
            _operationLock++;
            
            _fileStream.addEventListener(Event.COMPLETE, onOpenComplete);
            _fileStream.openAsync(_file, FileMode.UPDATE);
            
            function onOpenComplete(evt:Event):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onOpenComplete);
                
                _indexDict = {};
                //状态赋值要写在前面，因为readFileHead()要求状态是OPEN
                if(--_operationLock == 0)
                    _state = ZaxFileState.OPEN;
                
                if(_fileStream.bytesAvailable == 0)
                {
                    //新文件，写入头信息
                    _version = ZAX_VERSION;
                    _indexesNum = 0;
                    _fileStream.writeFloat(ZaxFile.ZAX_VERSION);//写入版本号
                    _fileStream.writeInt(0);//写入Block数量
                    //预留ZaxFile.BLOCK_MAX个Block的空间
                    var n:int = ZaxFile.MAX_BLOCKS * ZaxFile.IDX_BYTES_LEN;
                    for(var i:int = 0; i < n; i++)
                        _fileStream.writeByte(0);
                }
                else
                {
                    readFileHead();
                }
                
                _readQueue = new Vector.<ReadRequest>();
                
                if(callback != null)
                    callback(true);
            }
        }
        
        
        /**
         * 读取一段资源, 异步。新的读取请求会放入到请求队列中。
         * 
         * @param key
         * @param callback function(key:String, ba:ByteArray):void
         */        
        public function readByKey(key:String, callback:Function):void
        {
            if(!checkState([ZaxFileState.OPEN, ZaxFileState.OPERATING]))
                return;
            if(key == null || key == "" || callback == null)
            {
                throw new ArgumentError("无效的参数.");
                return;
            }
            var idx:ZaxBlockIndex = _indexDict[key];
            if(idx == null)
            {
                throw new Error("错误的Key");
                callback(key, null);
                return;
            }
            
            var startReadFlg:Boolean = _readQueue.length == 0;
            var req:ReadRequest = new ReadRequest();
            req.idx = idx;
            req.callback = callback;
            _readQueue.push(req);
            
            if(startReadFlg)
            {
                //启动读取
                _operationLock++;
                _state = ZaxFileState.OPERATING;
                readNext();
            }
        }
        
        
        
        /**
         * 关闭文件。如果当前有请求未完成，会等待请求完成之后，再关闭。
         * 
         * @param callback function(success:Boolean):void
         * 
         */
        public function close(callback:Function):void
        {
            var checkTimeID:int = -1;
            
            if(_state == ZaxFileState.OPEN)
            {
                //理想情况，没有其他操作进行
                _state = ZaxFileState.OPERATING;
                _operationLock++;
                checkOtherComplete();
            }
            else if(_state == ZaxFileState.OPERATING)
            {
                //有其他操作正在进行，等待完成
                _state = ZaxFileState.OPERATING;
                _operationLock++;
                checkTimeID = setInterval(checkOtherComplete, 20);
            }
            else if(callback != null)//其他情况，标识close操作失败
                setTimeout(callback, 10, false);

            
            function checkOtherComplete():void
            {
                //等待其他操作完成
                if(_operationLock > 1)
                    return;
                
                Debugger.assert(_operationLock == 1);
                clearInterval(checkTimeID);
                checkTimeID = -1;
                saveIndexes(onSaveIndexesComplete);   
            }
            
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
                
                Debugger.assert(_operationLock == 1);
                _operationLock = 0;
                _state = ZaxFileState.CLOSED;
                callback(true);
            }
        }
        
        
        /**
         * 返回所有key。 
         * @return Array of String.
         * 
         */        
        public function getKeys():Array/*of String*/
        {
            if(_indexDict == null)
                return null;
            
            var keys:Array = [];
            for(var k:String in _indexDict)
                keys.push(k);
            
            return keys;
        }
        
        
        public function getState():String
        {
            return _state;
        }
        
        
        public function isReadOnly():Boolean
        {
            return _isReadOnly;
        }
        
        
        public function getPath():String
        {
            return _file.nativePath;
        }
        
        
        /**
         * 当前这个ZaxFile的版本 
         * @return 
         * 
         */        
        public function getVersion():Number
        {
            if(!checkState([ZaxFileState.OPEN, ZaxFileState.OPERATING]))
                return 0;
            
            return _version;
        }
            
        
        private function init(path:String):void
        {
            _file = new File(path);
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
        
        
        private function readNext():void
        {
            if(_readQueue == null || _readQueue.length == 0)
                return;
            
            var req:ReadRequest = _readQueue[0];
            var ba:ByteArray = new ByteArray();
            if(_fileStream.position == req.idx.postion)
            {
                _fileStream.readBytes(ba, 0, req.idx.len);
                callbackAll();
            }
            else
            {
                _fileStream.addEventListener(Event.COMPLETE, onSetPositionComplete);
                _fileStream.position = req.idx.postion;
            }
            
            function onSetPositionComplete(evt:Event):void
            {
                _fileStream.removeEventListener(Event.COMPLETE, onSetPositionComplete);
                _fileStream.readBytes(ba, 0, req.idx.len);
                callbackAll();
            }
            
            function callbackAll():void
            {
                //这里要判断null，因为可能ZaxFile被close了
                if(_readQueue == null)
                    return;
                
                //构造一个新Vector，取代原来的Vector
                var newVec:Vector.<ReadRequest> = new Vector.<ReadRequest>();
                for each(var r:ReadRequest in _readQueue)
                {
                    if(r.idx.key != req.idx.key)
                    {
                        newVec.push(r);
                        continue;
                    }
                    if(r == _readQueue[0])
                        continue;
                    //如果找到同样请求，则把ByteArray复制一份，发给另外请求.
                    var newBa:ByteArray = new ByteArray();
                    newBa.writeBytes(ba, 0, ba.length);
                    newBa.position = 0;
                    r.callback(r.idx.key, newBa);
                }
                _readQueue[0].callback(req.idx.key, ba);
                
                if(newVec.length != _readQueue.length)
                    _readQueue = newVec;
                
                
                if(_readQueue.length > 0)
                    readNext();
                else if(--_operationLock == 0)
                    _state = ZaxFileState.OPEN;
            }
        }
        
        
        /**
         * 把索引信息保存到文件
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
        
        
        
        private function checkState(permittedState:Array, throwError:Boolean = true):Boolean
        {
            if(permittedState.indexOf(_state) < 0)
            {
                if(throwError)
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

import im.mobius.vulcanus.zax.ZaxBlockIndex;

class ReadRequest
{
    public var idx:ZaxBlockIndex;
    public var callback:Function;
}