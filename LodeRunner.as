package  {
	
	import char.Character;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.display.Stage;
	import char.Player;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import level.Bar;
	import level.Brick;
	import level.Completed;
	import level.Solid;
	import level.Stairs;
	import level.Tile;
	import flash.net.*;
	import flash.events.Event;
	import flash.events.*;
	import flash.system.Security;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
	// import com.adobe.serialization.json.JSON;
	
	public class LodeRunner extends MovieClip {
		static public const TIME_BETWEEN_LEVELS = 3; //In seconds
		
		static public const TILE_WIDTH = 48;
		static public const TILE_HEIGHT = 48;
		
		static public const MAP_LEFT = 1;
		static public const MAP_RIGHT = 2;
		static public const MAP_DOWN = 4;
		static public const MAP_UP = 8;
		
		static public function set scores(score: Number) {
			levelScores += score - _scores;
			trace(levelScores, score, _scores);
			
			_scores = score;
			
			if (_scores > hiScores)
				hiScores = _scores;
		}
		static public function get scores(): Number { 
			return _scores; 
		}
		
		static private var _scores: Number = 0;
		static public var mainCharacter: char.Player = null;
		static public var treasureCount: Number = 0;
		static public var passMap: Array = [];
		static public var viewMap: Array = [];
		static public var blocks: Array = [];
		static public var lifeCount: Number = 5;
		static public var currentLevel: Number = 1;
		static public var levelScores: Number = 0;
		static public var deadEnemiesScores: Number = 0;
		static public var treasureScores: Number = 0;
		static public var hiScores: Number = 0;
				
		public function LodeRunner() {
			var level_id = Load_Map_Info();
			gotoAndStop(1, "Level"+level_id);
			addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);
		}
		
		public function Load_Map_Info(){
			// var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters.LevelID;
			Security.loadPolicyFile("http://kavadzu.com/crossdomain.xml");
			var loader:URLLoader = new URLLoader();
			// var request:URLRequest = new URLRequest("http://kavadzu.com/ajax?type=level&load=load_client&data="+paramObj.toString());
			var request:URLRequest = new URLRequest("http://kavadzu.com/ajax?type=level&load=load_client&data=1");
			request.method = URLRequestMethod.GET;
			loader.addEventListener(Event.COMPLETE, onComplete);
			try {
				loader.load(request);
			}
			catch (ex:Error) {
				trace('error: ' + ex.message);
			}
			function onComplete(event:Event):void {
				var tmp_str=loader.data.toString();
				var parse_json:Object = JSON.parse(tmp_str);
				// BLOCKS
				for( var prop:String in parse_json['blocks'])
				{
					blocks[parse_json['blocks'][prop]['id']]=[];
					trace( parse_json['blocks'][prop]['id'], " = (", parse_json['blocks'][prop]['type'], ") ", parse_json['blocks'][prop]['images'] );
					// blocks[prop]['id']=parse_json['blocks'][prop]['id'];
					blocks[parse_json['blocks'][prop]['id']]['type']=parse_json['blocks'][prop]['type'];
					var temp = parse_json['blocks'][prop]['images']; //.split(",");
					blocks[parse_json['blocks'][prop]['id']]['image']=temp;
					
				}
				trace ("\n\n ---");
				trace(blocks[40]['image']);
				trace ("--- \n\n");
				// FIELD
				for( var prop:String in parse_json['field']['level'])
				{
					// 1 кирпич 2 канат 3 лесница 4 артефакт 5 дверь 6 лифт
					var row = parse_json['field']['level'][prop].toString();
					//trace( prop, " = ",  row);
					var row = row.split(",");
					viewMap[prop]=[];
					
					for( var irt:String in row) {
						// trace("(", irt, ",",prop,") = ", row[irt],"\n");
						viewMap[prop][irt]=row[irt];
						
						// blahblahblah
						
						if(row[irt]=="0"){
							passMap[prop][irt]&= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
						}
						else{								
							switch(blocks[row[irt]]['type']){
								case "0": passMap[prop][irt]&= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
									break;								
								case "1": passMap[prop][irt]&= 0;
									break;
								case "2": passMap[prop][irt]|= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
									break;
								case "3": passMap[prop][irt]|= MAP_LEFT|MAP_RIGHT|MAP_DOWN|MAP_UP;
									break;
								case "4": passMap[prop][irt]|= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
									break;
								case "5": passMap[prop][irt]|= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
									break;
								case "6": passMap[prop][irt]|= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
									break;		
								default: passMap[prop][irt]&= 0;
									break;							
							}
						}						
					}
				}
				tracePassMap();
					for( var i:String in passMap) {
						var rr=passMap[i];
						//for( var j:String in rr) {
							//trace(rr[j],",");
						//}
						// trace(rr,"\n");
					}				
			}
			
			return 3;
			// return paramObj.toString();
		}
		
		public function levelStarts() {
			for (var i: Number = 0; i < numChildren; i++) {
				if (getChildAt(i) is Completed) {
					getChildAt(i).visible = false;
				}
			}
		}
		public function levelCompleted() {
			for (var i: Number = 0; i < numChildren; i++) {
				if (getChildAt(i) is Completed) {
					getChildAt(i).visible = true;
					MovieClip(getChildAt(i)).gotoAndPlay("Appearing");
				}
			}
		}
		
		public function nextLevel() {
			trace("nextLevel");
			currentLevel ++;
			gotoAndStop(1, "StageCompleted");
			generatePassMap();
		}
		
		private var animatedTotal: Number = 0;
		private var animatedEnemies: Number = 0;
		private var animatedTreasures: Number = 0;		
		private var framesBeforeNextLevel: Number = 0;
		public function OnEnterFrame(e: Event) {
			stop();
			
			
			if (currentScene.name == "GameOver") {
				if (framesBeforeNextLevel == 0) {
					framesBeforeNextLevel = TIME_BETWEEN_LEVELS * stage.frameRate;
					
					yourScoresLabel.text = ""+scores;
					hiScoresLabel.text = ""+hiScores;
				}else if (framesBeforeNextLevel == 1) {
					resetGame();
					return;
				}else
					framesBeforeNextLevel --;
			}
			if (currentScene.name == "StageLoading") {
				if (framesBeforeNextLevel == 0) {
					framesBeforeNextLevel = TIME_BETWEEN_LEVELS * stage.frameRate;
					
					stageLabel.text = "Stage: " + currentLevel;
					leftLabel.text = "Left: " + lifeCount;
					scoresLabel.text = "Scores: " + scores;
					hiScoresLabel.text = "Hi Scores: " + hiScores;
				}else if (framesBeforeNextLevel == 1) {
					gotoAndStop(1, "Level" + currentLevel);
					framesBeforeNextLevel = 0;
					return;
				}else
					framesBeforeNextLevel --;
				
				
			}
			if (currentScene.name == "StageCompleted") {
				if (framesBeforeNextLevel == 0) {
					framesBeforeNextLevel = TIME_BETWEEN_LEVELS * stage.frameRate;
					animatedTotal = 0;
					animatedEnemies = 0;
					animatedTreasures = 0;
				}
				
				if (animatedTotal < levelScores) {
					animatedTotal = Math.min( 
						animatedTotal + Math.round(levelScores / (TIME_BETWEEN_LEVELS * stage.frameRate)) , 
						levelScores);
				}
				if (animatedEnemies < deadEnemiesScores) {
					animatedEnemies = Math.min(
						animatedEnemies + Math.round(deadEnemiesScores / (TIME_BETWEEN_LEVELS * stage.frameRate)) , 
						deadEnemiesScores);
				}
				if ( animatedTreasures < treasureScores) {
					animatedTreasures = Math.min(
						animatedTreasures + Math.round(treasureScores / (TIME_BETWEEN_LEVELS * stage.frameRate)) ,
						treasureScores);
				}
				
				totalLabel.text = "Total: " + animatedTotal;
				enemiesLabel.text = " x " + animatedEnemies;
				treasuresLabel.text = " x " + animatedTreasures;
					
				if ((animatedTotal == levelScores) && 
					(animatedEnemies == deadEnemiesScores) && 
					(animatedTreasures == treasureScores)) {
						
						framesBeforeNextLevel --;
					
						if (framesBeforeNextLevel <= 2) {
							gotoAndStop(1, "Level"+currentLevel);
							framesBeforeNextLevel = 0;
							animatedTotal = 0;
							animatedEnemies = 0;
							animatedTreasures = 0;
							
							levelScores = 0;
							treasureScores = 0;
							deadEnemiesScores = 0;
							
							generatePassMap();
						}
				};
				
				
				return;
			}
				
			if (mainCharacter.y < mainCharacter.height && treasureCount == 0)
				nextLevel();
			
		}
		
		private static var _stage: Stage = null;
		
		static public function getMovieClipForCollide(object: DisplayObject): MovieClip{
			while( !(object.parent is LodeRunner)){
				object = object.parent;
			}
			if(object is MovieClip)
				return MovieClip( object);
			else
				return null;
		}
		static public function getObjectsUnder(_x: Number, _y: Number, _width: Number):Array{
			var result: Array = [];
			var position: Point = new Point(_x - _width/3, 
											_y);
			
			result = result.concat(_stage.getObjectsUnderPoint(position));
			position.x += _width / 3;
			
			result = result.concat(_stage.getObjectsUnderPoint(position));
			position.x += _width /3;
			
			result = result.concat(_stage.getObjectsUnderPoint(position));
			
			return result;
		}
		
		static public function getObjectsNear(_x: Number, _y: Number, _height: Number): Array{
			var result: Array = [];
			var position: Point = new Point(_x, 
											_y - _height / 3);
			
			result = result.concat(_stage.getObjectsUnderPoint(position));
			position.y += _height / 3;
			
			result = result.concat(_stage.getObjectsUnderPoint(position));
			position.y += _height / 3;
			
			result = result.concat(_stage.getObjectsUnderPoint(position));
			
			return result;
		}
	
		private function OnAddedToStage(e: Event): void{
			_stage = stage;			
			generatePassMap();
			levelStarts();
		}
		
		private function OnKeyDown(e: KeyboardEvent):void{
		}
		
		private function generatePassMap(): void {
			
			var p: Point = new Point();
			var o: MovieClip = null;
			
			
			clearPassMap();
			/*
			for (p.y = TILE_HEIGHT / 2; p.y <= stage.stageHeight - TILE_HEIGHT / 2; p.y += TILE_HEIGHT){
				for (p.x = TILE_WIDTH / 2; p.x <= stage.stageWidth - TILE_WIDTH / 2; p.x += TILE_WIDTH){
				
					o = null;
					
					for each (var object in getObjectsUnderPoint(p)) {
						if (LodeRunner.getMovieClipForCollide(object) is Tile)
							o = LodeRunner.getMovieClipForCollide(object);
					}
					
					if (o == null) {
						p.y += TILE_HEIGHT;
						var u: MovieClip = null;
						
						for each (object in getObjectsUnderPoint(p)) {
							if (LodeRunner.getMovieClipForCollide(object) is Tile)
								u = LodeRunner.getMovieClipForCollide(object);
						}
						
						p.y -= TILE_HEIGHT;
						if (u == null) {
							//trace((p.x - TILE_WIDTH / 2) / TILE_WIDTH);
							passMap [(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
								[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] = MAP_DOWN;
						}else if ( u is Solid && u is Tile)
							passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
								[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] |= MAP_LEFT | MAP_RIGHT;
						else if (u is Stairs)
							passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
								[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] |= MAP_LEFT | MAP_RIGHT | MAP_DOWN;
						else {
							passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
									[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] |= MAP_DOWN;
						}
						
					}else {
						if (o is Solid) {
							passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
								[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] &= 0;
						}else if (o is Stairs) {
							passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT] 
								[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] |= MAP_LEFT|MAP_RIGHT|MAP_DOWN|MAP_UP;
						}else if (o is Bar) {
							passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT] 
								[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] |= MAP_LEFT|MAP_RIGHT|MAP_DOWN;
						}
					}
				}
			}
			
			for (p.y = TILE_HEIGHT / 2; p.y <= stage.stageHeight - TILE_HEIGHT / 2; p.y += TILE_HEIGHT){
				for (p.x = TILE_WIDTH / 2; p.x <= stage.stageWidth - TILE_WIDTH / 2; p.x += TILE_WIDTH) {
					o = null;
					for each (var object in getObjectsUnderPoint(p)) {
						if ( (LodeRunner.getMovieClipForCollide(object) is Solid) 
								&& 
							(LodeRunner.getMovieClipForCollide(object) is Tile) ) 
								o = LodeRunner.getMovieClipForCollide(object);
					}
					
					if (o == null)
						continue;
						
					if ((o is Solid) && (o is Tile)) {
						
						passMap[ (p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
							[Math.max((p.x - TILE_WIDTH / 2) / TILE_WIDTH - 1, 0)] &= ~MAP_RIGHT;
									
						passMap[(p.y - TILE_HEIGHT / 2) / TILE_HEIGHT]
							[Math.min( (p.x - TILE_WIDTH / 2) / TILE_WIDTH + 1, 
											stage.stageWidth / TILE_WIDTH - 1)] &= ~MAP_LEFT;
									
						passMap[Math.max( (p.y - TILE_HEIGHT / 2) / TILE_HEIGHT - 1, 0) ]
							[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] &= ~MAP_DOWN;
									
						passMap[ Math.min( (p.y - TILE_HEIGHT / 2) / TILE_HEIGHT + 1,
									stage.stageHeight / TILE_HEIGHT - 1)]
							[(p.x - TILE_WIDTH / 2) / TILE_WIDTH] &= ~MAP_UP;
					}
						
				}
			}
			
			for (var i: Number = 0; i < stage.stageWidth / TILE_WIDTH; i++){
				passMap[0][i] &= ~MAP_UP;
				passMap[stage.stageHeight / TILE_HEIGHT - 1][i] &= ~MAP_DOWN;
			}
			
			for (i = 0; i < stage.stageHeight / TILE_HEIGHT; i++) {
				passMap[i][0] &= ~MAP_LEFT;
				passMap[i][stage.stageWidth / TILE_WIDTH - 1] &= ~MAP_RIGHT;
			}*/
			
			passMap[6][6]=MAP_DOWN;
			tracePassMap();
				
		}
		
		static public function tracePassMap() {
			for (var i: Number = 0; i < passMap.length; i++) {
				var output: String = "";
				for ( var j: Number = 0; j < passMap[i].length; j++) {
					switch (passMap[i][j]){
						case 0: output += '#'; break;
						case 1: output += '←'; break;
						case 2: output += '→'; break;
						case 3: output += '↔'; break;
						case 4: output += '↓'; break;
						case 5: output += '┐'; break;
						case 6: output += '┌'; break;
						case 7: output += '┬'; break;
						case 8: output += '↑'; break;
						case 9: output += '┘'; break;
						case 10: output += '└'; break;
						case 11: output += '┴'; break;
						case 12: output += '↕'; break;
						case 13: output += '┤'; break;
						case 14: output += '├'; break;
						case 15: output += '┼'; break;
					}
					output += '  ';
				}
				trace(output);
			}
		}
		
		private function clearPassMap() {
			for (var i: Number = -2; i < stage.stageHeight / TILE_HEIGHT; i++) {
				passMap[i] = [];
				for (var j: Number = -2; j < stage.stageWidth / TILE_WIDTH; j++)
					passMap[i][j] = 0;
			}
		}
		private function resetGame() {
			scores = 0;
			levelScores = 0;
			lifeCount = 5;
			gotoAndStop(1, "Level1");
		}
	}
}
