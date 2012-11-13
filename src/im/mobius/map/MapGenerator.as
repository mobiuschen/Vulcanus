package im.mobius.map
{
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import im.mobius.utils.MathM;
    

    public class MapGenerator
    {
        static public const WALL_INT:int = 1;
        
        static public const ROAD_INT:int = 0;
        
        /**
         * 地砖密度 
         */        
        static private const ROAD_DENSITY:Number = 0.4;
        
        public function MapGenerator()
        {
        }
        
        
        public function getMap(w:int, h:int):Vector.<Vector.<int>>
        {
            var map:Vector.<Vector.<int>> = initMap(w, h, ROAD_DENSITY);
            putRoadPointsTogehter(map);
            var collection:Vector.<Vector.<Point>> = calCollections(map);
            var centerPoints:Vector.<Point> = searchCollectionCenterPoint(collection);
            var lines:Vector.<Line> = joint(centerPoints);
            s(lines, map);
            
            return map;
        }
        
        
        /**
         * 生成指定尺寸的地图, 根据地砖密度填充数据.
         * @param w
         * @param h
         * @param roadDensity 地砖密度
         * @return 
         * 
         */        
        private function initMap(w:int, h:int, roadDensity:Number):Vector.<Vector.<int>>
        {
            var result:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(h, true);
            for(var i:int = 0, n:int = result.length; i < n; i++)
            {
                var row:Vector.<int> = new Vector.<int>(w, true); 
                for(var j:int = 0, m:int = row.length; j < m; j++)
                    row[j] = Math.random() > roadDensity ? WALL_INT : ROAD_INT;
                
                result[i] = row;
            }
            
            return result;
        }
        
        
        
        /**
         * 遍历所有点, 把同类点归拢.
         *  
         * @param map
         * 
         */        
        private function putRoadPointsTogehter(map:Vector.<Vector.<int>>):void
        {
            var rN:int = 0;
            var wN:int = 0;
            for(var i:int = 0, n:int = map.length; i < n; i++)
            {
                var row:Vector.<int> = map[i];
                for(var j:int = 0, m:int = row.length; j < m; j++)
                {
                    //m是列数, n是行数
                    var weight:int = 0;
                    if(j > 0)
                    {
                        if(i <= 0 || map[i - 1][j - 1] == WALL_INT) weight++;
                        if(map[i][j - 1] == WALL_INT) weight++;
                        if(i >= n - 1 || map[i + 1][j - 1] == WALL_INT) weight++;
                    }
                    else
                    {
                        weight += 3;
                    }
                    
                    if(i <= 0 || map[i - 1][j] == WALL_INT) weight++;
                    if(i >= n - 1 || map[i + 1][j] == WALL_INT) weight++;
                    
                    if(j < m - 1)
                    {
                        if(i <= 0 || map[i - 1][j + 1] == WALL_INT) weight++;
                        if(map[i][j + 1] == WALL_INT) weight++;
                        if(i >= 0 || map[i + 1][j + 1] == WALL_INT) weight++;   
                    }
                    else
                    {
                        weight += 3;
                    }
                    
                    
                    if(weight < 4)
                    {
                        rN++;
                        map[i][j] = ROAD_INT;
                    }
                    else if(weight > 5)
                    {
                        wN++;
                        map[i][j] = WALL_INT;
                    }
                }//for
            }//for
            //trace(rN, wN);
        }
        

        /**
         * 计算map中有几个连接在一起的"块".
         *  
         * @param map
         * @return 
         * 
         */        
        private function calCollections(map:Vector.<Vector.<int>>):Vector.<Vector.<Point>>
        {
            var result:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();
            for(var i:int = 0, n:int = map.length; i < n; i++)
            {
                var row:Vector.<int> = map[i];
                for(var j:int = 0, m:int = row.length; j < m; j++)
                {
                    if(row[j] == WALL_INT)
                        continue;
                    //m是列数, n是行数
                    //其实只要计算右边和下面的邻接点就可以了
                    checkSameCollection(j - 1, i + 1, j, i);//左下
                    checkSameCollection(j, i + 1, j, i);//下
                    checkSameCollection(j + 1, i, j, i);//右
                    checkSameCollection(j + 1, i + 1, j, i);//右下
                    if(!hasBeenCollect(j, i))
                        result.push(new <Point>[new Point(j, i)]);
                }//for
            }//for
                
            return result;
            
            function checkSameCollection(x1:int, y1:int, x2:int, y2:int):Boolean
            {
                if(x1 < 0 || x1 >= m || y1 < 0 || y1 >= n || map[y1][x1] == WALL_INT)
                    return false;
                if(x2 < 0 || x2 >= m || y2 < 0 || y2 >= n || map[y2][x2] == WALL_INT)
                    return false;
                
                //Assert.assertTrue(x1 != x2 || y1 != y2);
                
                var vec1:Vector.<Point> = null;
                var vec2:Vector.<Point> = null;
                for each(var vec:Vector.<Point> in result)
                {
                    for each(var p:Point in vec)
                    {
                        if(x1 == p.x && y1 == p.y)
                            vec1 = vec;
                        if(x2 == p.x && y2 == p.y)
                            vec2 = vec;
                        if(vec1 != null && vec2 != null)
                            break;
                    }
                }
                
                if(vec1 == null && vec2 == null)
                    result.push(new <Point>[new Point(x1, y1), new Point(x2, y2)]);
                else if(vec1 == null)
                    vec2.push(new Point(x1, y1));
                else if(vec2 == null)
                    vec1.push(new Point(x2, y2));
                else if(vec1 != vec2)
                {
                    result.push(vec1.concat(vec2));
                    result.splice(result.indexOf(vec1), 1);
                    result.splice(result.indexOf(vec2), 1);
                }
                
                return true;
            }
            
            function hasBeenCollect(x:int, y:int):Boolean
            {
                for each(var vec:Vector.<Point> in result)
                    for each(var p:Point in vec)
                        if(x == p.x && y == p.y)
                            return true;
                        
                return false;
            }
        }
        
        
        /**
         * 寻找各个集合的中心点
         * 
         */        
        private function searchCollectionCenterPoint(collection:Vector.<Vector.<Point>>):Vector.<Point>
        {
            var centerPoints:Vector.<Point> = new Vector.<Point>();
            for(var i:int = 0, n:int = collection.length; i < n; i++)
            {
                var vec:Vector.<Point> = collection[i];
                vec.sort(sortByPosition);
                centerPoints.push(vec[int(vec.length / 2)]);
            }
            
            return centerPoints;
            
            
            function sortByPosition(p1:Point, p2:Point):int
            {
                if(p1.x < p2.x)
                    return -1;
                else if(p1.x > p2.x)
                    return 1;
                else if(p1.y < p2.y)
                    return -1;
                else if(p1.y > p2.y)
                    return 1;
                
                return 0;
            }
        }
        
        
        private function s(lines:Vector.<Line>, map:Vector.<Vector.<int>>):void
        {
            for(var i:int = 0, n:int = map.length; i < n; i++)
            {
                for(var j:int = 0, m:int = map[i].length; j < m; j++)
                {
                    var rect:Rectangle = new Rectangle(j, i, 1, 1);
                    for each(var line:Line in lines)
                    {
                        if(MathM.lineIntersectsRect(line.p1, line.p2, rect))
                        {
                            map[i][j] = ROAD_INT;
                            break;
                        }
                    }
                }//for
            }//for
        }
        
        
        
        /**
         * 根据给定的点, 连接成地图 
         * @param allPoints
         * 
         */        
        private function joint(allPoints:Vector.<Point>):Vector.<Line>
        {
            var allLines:Vector.<Line> = getAllLines(allPoints);
            var collections:Vector.<Vector.<Point>> = initCollections(allPoints);
            
            var result:Vector.<Line> = new Vector.<Line>();
            
            while(allPoints.length > 0)
            {
                if(collections.length == 1)
                    break;
                //寻找最短的边
                //var selectedLine:Line = allLines.shift();
                
                //不一定寻找最短的线段, 而是在前几名中随机选一条线段.
                var idx:int = int(Math.random() * Math.min(allLines.length, 10));
                var selectedLine:Line = allLines.splice(idx, 1)[0];
                
                if(!checkCrossPoint(selectedLine.p1, selectedLine.p2, allPoints) &&
                    !checkCrossLine(selectedLine.p1, selectedLine.p2, result))
                {
                    joint2Point(selectedLine, collections, result);
                }
            }
            
            //Assert.assertTrue(collections.length == 1);
            
            return result;
        }
        
        
        
        /**
         * 连接两个点
         *  
         * @param selectedLine
         * @param collections
         * @param lines
         * @return 
         * 
         */        
        private function joint2Point(selectedLine:Line, 
                                     collections:Vector.<Vector.<Point>>, 
                                     lines:Vector.<Line>):Boolean
        {
            var p1:Point = selectedLine.p1;
            var p2:Point = selectedLine.p2;
            
            if(p1 == p2)
                return false;
            var vec1:Vector.<Point>;
            var vec2:Vector.<Point>;
            for each(var vec:Vector.<Point> in collections)
            {
                if(vec.indexOf(p1) >= 0)
                    vec1 = vec;
                if(vec.indexOf(p2) >= 0)
                    vec2 = vec;
            }//for 
            
            //Assert.assertTrue(vec1 != null && vec2 != null);
            
            //两个点在同一个集合内, 不允许连接.
            if(vec1 == vec2)
                return false;
            
            //连接两个集合
            collections.push(vec1.concat(vec2));
            collections.splice(collections.indexOf(vec1), 1);
            collections.splice(collections.indexOf(vec2), 1);
            
            lines.push(selectedLine);
            return true;
            
        }//function joint2Point
        
        
        /**
         * 根据所有点, 生成所有距离. 
         * @param points
         * @return 
         * 
         */        
        private function getAllLines(points:Vector.<Point>):Vector.<Line>
        {
            var dis:Number;
            var p1:Point;
            var p2:Point;
            var result:Vector.<Line> = new Vector.<Line>();
            for each(p1 in points)
            {
                for each(p2 in points)
                {
                    if(p1 == p2)
                        continue;
                    var dx:Number = p1.x - p2.x;
                    var dy:Number = p1.y - p2.y;
                    dis = Math.sqrt(dx * dx + dy * dy);
                    result.push(new Line(dis, p1, p2));
                }
            }
            //Assert.assertEquals(result.length, (points.length * points.length - points.length));
            result.sort(sortByDis);
            return result;
            
            function sortByDis(a:Line, b:Line):int
            {
                if(a.distance < b.distance)
                    return -1;
                else if(a.distance > b.distance)
                    return 1;
                return 0;
            }
        }//function
        
        
        /**
         * 初始化集合 
         * @param points
         * @return 
         * 
         */        
        private function initCollections(points:Vector.<Point>):Vector.<Vector.<Point>>
        {
            var result:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>();
            for each(var p:Point in points)
            result.push(new <Point>[p]);
            
            return result;
        }
        
        
        /**
         * 检查新的线段是否会和其他线段相交
         * 
         * @param p1
         * @param p2
         * @param crtLines
         * @return 
         * 
         */        
        private function checkCrossLine(p1:Point, p2:Point, allLines:Vector.<Line>):Boolean
        {
            for each(var line:Line in allLines)
            {
                if(MathM.checkLinesIntersecion(p1, p2, line.p1, line.p2))
                    return true;
            }
            return false;
        }//function
        
        
        /**
         * 检查p1, p2组成的线段, 是否会和其他点相交. 
         * 
         * @param p1
         * @param p2
         * @param allPoints
         * @return 
         * 
         */        
        private function checkCrossPoint(p1:Point, p2:Point, allPoints:Vector.<Point>):Boolean
        {
            for each(var p3:Point in allPoints)
            {
                if(MathM.pointOnLine(p3, p1, p2))
                    return true;
            }
            return false;
        }
        
        
        
        public function _testCalCollections(map:Vector.<Vector.<int>>):Vector.<Vector.<Point>>
        {
            return calCollections(map);
        }
            
    }//class
}//package

import flash.geom.Point;

class Line
{
    
    public function Line(distance:Number, p1:Point, p2:Point)
    {
        this.distance = distance;
        this.p1 = p1;
        this.p2 = p2;
    }
    
    public function toString():String
    {
        return "[p1=(" +p1.x + ", " + p1.y + "), p2=(" + p2.x + ", " + p2.y + "), distance=" + distance + "]";
    }
    
    public var distance:Number;
    public var p1:Point;
    public var p2:Point
}