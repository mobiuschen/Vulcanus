package im.mobius.debug
{
import flash.utils.Dictionary;
import flash.utils.getTimer;
    
/**
 * LogEntity的数据簇，通过这个类组织、获取各种类型的LogEntity
 * @author mobiuschen
 * 
 */    
public class LogBatch
{
    static public const SPERATOR:String = "&&\n";
    
    /**
     * 序列化 
     * @param logBatch
     * @return 
     * 
     */    
    static public function serialize(logBatch:LogBatch):XML
    {
        //输出示例
        /*
            <LogBatch>
                <log type="misc" msg="1st log" time="1339767988929"/>
                <log type="misc" msg="2nd log" time="1339767988930"/>
                <log type="misc" msg="3th log" time="1339767988931"/>
                <log type="userAction" msg="4th: click the button" time="1339767988932"/>
                <log type="network" msg="5th: request fail" time="1339767988933"/>
                <log type="NO THIE TYPE!" msg="6th: hello" time="1339767988934"/>
            </LogBatch>; 
        */
        
        if(logBatch == null)
            return null;
        var xml:XML = <LogBatch/>;
        var all:Vector.<LogEntity> = logBatch.getAllLogs();
        for(var i:int = 0, n:int = all.length; i < n; i++)
        {
            xml.appendChild(LogEntity.serialize(all[i]));
        }
        return xml;
    }
    
    
    /**
     * 反序列化 
     * @param xml
     * @return 
     * 
     */    
    static public function deserialize(xml:XML):LogBatch
    {
        if(xml == null || xml.name() != "LogBatch")
            return null;
        
        var list:XMLList = xml.log;
        if(list == null)
            return null;
        
        var logBatch:LogBatch = new LogBatch();
        var log:LogEntity;
        for(var i:int = 0, n:int = list.length(); i < n; i++)
        {
            log = LogEntity.deserialize(list[i]);
            logBatch.push(log);
        }
        
        return logBatch;
    }
    
    
    
    public function LogBatch()
    {
    }
    
    private var typeDict:Dictionary = new Dictionary();
    
    private var lastLog:LogEntity;
    
    
    /**
     * 生成一条新的LogEntity，且放进LogBatch.
     * 
     * @param type
     * @param msg
     * @return 
     * 
     */    
    public function createLog(type:String, msg:String):LogEntity
    {
        if(type == null || type == "")
        {
            throw new ArgumentError("ArgumentError");
            return;
        }
        
        var log:LogEntity = new LogEntity(msg, new Date().time, type);
        //如果时间相同, 则保证添加的顺序.
        if(lastLog != null && lastLog.time >= log.time)
        {
            log.time = lastLog.time + 1;
        }
        
        push(log);
        
        lastLog = log;
        return log.clone();
    }
    
    
    
    /**
     * 直接塞入一条LogEntity，放在制定类别最后，不检查时间. 
     * @param log
     * @return 
     * 
     */    
    public function push(log:LogEntity):Boolean
    {
        if(log == null)
            return false;
        
        if(typeDict[log.type] == null)
            typeDict[log.type] = new Vector.<LogEntity>();
        
        var vec:Vector.<LogEntity> = typeDict[log.type];
        vec.push(log);
        
        return true;
    }
    
    
    
    
    /**
     * 获取某个类型的LogEntity，按照time字段由小到大排序。
     * @param type
     * @return 
     * 
     */    
    public function getLogsByType(type:String):Vector.<LogEntity>
    {
        if(type == null || type == "")
        {
            throw new ArgumentError("ArgumentError");
            return null;
        }
        return typeDict[type];
    }
    
    
    
    /**
     * 返回这个LogBatch里所有的LogEntity，按照time字段由小到大排序。 
     * @return 
     * 
     */    
    public function getAllLogs():Vector.<LogEntity>
    {
        var all:Vector.<LogEntity> = new Vector.<LogEntity>();
        var vec:Vector.<LogEntity>;
        for each(vec in typeDict)
        {
            if(vec == null)
                continue;
            all = all.concat(vec);
        }//for
        all.sort(compare);
        return all;
        
        function compare(log1:LogEntity, log2:LogEntity):int
        {
            if(log1.time < log2.time)
                return -1;
            else if(log1.time > log2.time)
                return 1;
            return 0;
        }
    }
    
    
    public function getAllToString():String
    {
        var arr:Vector.<String> = new <String>[];
        getAllLogs().forEach(push);
        return arr.join(SPERATOR);
        
        function push(log:LogEntity):void
        {
            arr.push(log.toStringWithoutFormat());
        }
    }
    
    
    public function clear():void
    {
        var key:String;
        for(key in typeDict)
        {
            typeDict[key] = null;
        }//for
        lastLog = null;
    }
    
}
}

