package im.mobius.debug.unitest
{
    import asunit.framework.Assert;
    import asunit.framework.TestCase;
    
    import flash.display.DisplayObjectContainer;
    import flash.filesystem.File;
    
    import im.mobius.debug.DarkFog;
    import im.mobius.debug.Debugger;
    import im.mobius.debug.LogBatch;
    import im.mobius.debug.LogEntity;
    import im.mobius.debug.LogType;
    
    /**
     * 
     * @author mobiuschen
     * 
     */    
    public class TestCase_LogBatch extends TestCase
    {
        
        private var _logBatch:LogBatch;
        
        private var _logView:DarkFog;
        
        public function TestCase_LogBatch(testMethod:String=null)
        {
            super(testMethod);
        }
        
        
        override public function setContext(context:DisplayObjectContainer):void
        {
            _logView = new DarkFog();
            context.addChild(_logView);
            Debugger.init(context.stage, new Date().time, _logView);
        }
        
        
        
        public function testLogEntitySerialize():void
        {
            var xml:XML;
            var log:LogEntity;
            
            xml = <log type="misc" msg="Serialize" time="1339765141319"/>;
            log = LogEntity.deserialize(xml);
            Assert.assertTrue(log.msg == xml.@msg);
            Assert.assertTrue(log.type == xml.@type);
            Assert.assertTrue(log.time.toString() == xml.@time);
            
            
            xml = <log type="misc" msg="Serialize" time="0"/>;
            log = LogEntity.deserialize(xml);
            Assert.assertTrue(log.msg == xml.@msg);
            Assert.assertTrue(log.type == xml.@type);
            Assert.assertTrue(log.time == 0);
            
            xml = null;
            log = LogEntity.deserialize(xml);
            Assert.assertTrue(log == null);
            
            xml = <log msg="Serialize" time="0"/>;
            log = LogEntity.deserialize(xml);
            Assert.assertTrue(log.type == LogType.MISC);
            
            xml = <log type="misc" time="1339765141319"/>;
            log = LogEntity.deserialize(xml);
            Assert.assertTrue(log == null);
            
            xml = <nolog type="misc" msg="Serialize" time="1339765141319"/>;
            log = LogEntity.deserialize(xml);
            Assert.assertTrue(log == null);
        }
        
        
        public function testLogEntityDeserialie():void
        {
            _logBatch = new LogBatch();
            var idx:int = _logBatch.createLog(LogType.MISC, "Deserialie");
            var log:LogEntity = _logBatch.getLogByIndex(idx);
            var xml:XML = LogEntity.serialize(log);
            trace(xml.toXMLString());
            
            Assert.assertTrue(log.msg == xml.@msg);
            Assert.assertTrue(log.type == xml.@type);
            Assert.assertTrue(log.time.toString() == xml.@time);
        }
        
        
        /**
         * 测试LogBatch序列化 
         * 
         */        
        public function testLogBatchSerialize():void
        {
            var lb:LogBatch = new LogBatch();
            lb.createLog(LogType.MISC, "1st log");
            lb.createLog(LogType.MISC, "2nd log");
            lb.createLog(LogType.MISC, "3th log");
            lb.createLog(LogType.USER_ACTION, "4th: click the button");
            lb.createLog(LogType.NETWORK, "5th: request fail");
            lb.createLog("NO THIE TYPE!", "6th: hello");
            var xml:XML = LogBatch.serialize(lb);
            var list:XMLList = xml.log;
            
            Assert.assertTrue(list.length() == 6);
            Assert.assertTrue(list[1].@msg == "2nd log");
            Assert.assertTrue(list[5].@type == "NO THIE TYPE!");
            trace(xml.toXMLString());
        }
        
        
        /**
         * 测试LogBatch反序列化 
         * 
         */        
        public function testLogBatchDeserialize():void
        {
            var xml:XML = 
                <LogBatch>
                    <log type="misc" msg="1st log" time="1339767988929"/>
                    <log type="misc" msg="2nd log" time="1339767988930"/>
                    <log type="misc" msg="3th log" time="1339767988931"/>
                    <log type="userAction" msg="4th: click the button" time="1339767988932"/>
                    <log type="network" msg="5th: request fail" time="1339767988933"/>
                    <log type="NO THIE TYPE!" msg="6th: hello" time="1339767988934"/>
                </LogBatch>;
            var lb:LogBatch = LogBatch.deserialize(xml);
            Assert.assertTrue(lb.getAllLogs().length == 6);
            Assert.assertTrue(lb.getLogsByType(LogType.MISC).length == 3);
            Assert.assertTrue(lb.getLogsByType(LogType.USER_ACTION).length == 1);
            
            xml = <LogBatch/>
            lb = LogBatch.deserialize(xml);
            Assert.assertTrue(lb.getAllLogs().length == 0);
            
            xml = null;
            lb = LogBatch.deserialize(xml);
            Assert.assertTrue(lb == null);
            
            xml = 
                <LogBatch>
                    <log type="misc" msg="1st log" time="1339767988929"/>
                    <log type="misc" msg="2nd log" time="1339767988930"/>
                    <log type="misc" msg="3th log" time="1339767988931"/>
                    <log type="userAction" time="1339767988932"/> //no @msg
                    <nolog type="network" msg="5th: request fail" time="1339767988933"/>
                    <nolog type="NO THIE TYPE!" msg="6th: hello" time="1339767988934"/>
                </LogBatch>;
            lb = LogBatch.deserialize(xml);
            Assert.assertTrue(lb.getAllLogs().length == 3);
        }
        
        
        
        /**
         * 测试LogBatch反序列化 
         * 
         */        
        public function testSaveLog():void
        {
            Debugger.log("1st log", LogType.MISC);
            Debugger.log("2nd log", LogType.MISC);
            Debugger.log("3th log", LogType.MISC);
            Debugger.log("4th click button", LogType.USER_ACTION);
            Debugger.log("5th network", LogType.NETWORK);
            Assert.assertTrue(Debugger.save());
        }
        
        
        public function testLoadLogs():void
        {
            var file:File = File.applicationStorageDirectory.resolvePath(Debugger.SAVE_PATH);
            file = file.getDirectoryListing()[0];
            Assert.assertTrue(Debugger.load(file));
        }
        
        
        public function testUnloadLog():void
        {
            var func:Function = addAsync(callback, 3000);
            var uin:String = "346404978";
            var ts:Number = new Date().time;
            Debugger.uploadLastLoginBatch(uin+"@@"+ts, func);
                
            function callback(success:Boolean):void
            {
                trace(success);
            }
        }
    }
}