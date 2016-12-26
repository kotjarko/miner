package  char{
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import level.Brick;
	import level.Solid;
	
	
	public class Enemy extends Character implements Solid {
		static const STICK = 4;
		static const STICK_TIME = 3; 
		static const REGENERATION_TIME = 3;
		
		public var paused: Boolean = false;	
		private var regenerationFrames = 0;		
		
		
		private var stickedFrames: Number = 0;
		private var stickPosition: Point = new Point();
		private var climbingOutPosition: Point = new Point();
		private var waveMap: Array = [];	
		private var nextStep: Point = null;
		private var startPosition: Point = new Point();
		
		public function isPassable(): Boolean {
			return stickedFrames == 0;
		}
		
		private var currentDestination: Point = new Point();
		
		public function Enemy() {
			super();
			
			addEventListener(Event.ENTER_FRAME, this.OnEnterFrame);
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			
			return;
		}
		
		public function OnAddedToStage(e: Event): void {
			startPosition.x = this.x;
			startPosition.y = this.y;
			nextStep = new Point(this.x, this.y);
		}
		
		public override function OnEnterFrame(e: Event): void {
			if (paused)
				return;
			
			if (regenerationFrames > 1)
				regenerationFrames --;
			else if (regenerationFrames == 1) {
				this.x = startPosition.x;
				this.y = startPosition.y;
				regenerationFrames = 0;
				stickedFrames = 0;
				visible = true;
			}
			//traceWaveMap();
			var tileX = Math.round((this.x - LodeRunner.TILE_WIDTH / 2 ) / LodeRunner.TILE_WIDTH);
			var tileY = Math.round((this.y - LodeRunner.TILE_HEIGHT / 2 ) / LodeRunner.TILE_HEIGHT);
			clearWaveMap();
			generateWaveMap( tileX, tileY);
						
			//Math.abs(velocity) * LodeRunner.TILE_WIDTH * 10 - is a random coefficient of untruth
			
			if ( Math.abs( Math.abs(nextStep.x) - Math.abs(x)) <= Math.abs(velocity) * LodeRunner.TILE_WIDTH/10){
				if ( Math.abs( Math.abs(nextStep.y) - Math.abs(y)) <= Math.abs(velocity) * LodeRunner.TILE_HEIGHT / 10){
					
					var path: Array = getPath( new Point(
									Math.round( (LodeRunner.mainCharacter.x - LodeRunner.TILE_WIDTH / 2) / LodeRunner.TILE_WIDTH),
									Math.round( (LodeRunner.mainCharacter.y - LodeRunner.TILE_HEIGHT / 2) / LodeRunner.TILE_HEIGHT)
								));
				
					if (path != null)
						if (path.length > 0)
							nextStep = path[0];
							
					if (path.length == 0)
						return;
					
					nextStep.x *= LodeRunner.TILE_WIDTH;
					nextStep.y *= LodeRunner.TILE_HEIGHT;
					
					nextStep.x += LodeRunner.TILE_WIDTH / 2;
					nextStep.y += LodeRunner.TILE_HEIGHT / 2;
				}
			}
			
			delete downedKeys[Keyboard.DOWN];
			delete downedKeys[Keyboard.UP];
			delete downedKeys[Keyboard.LEFT];
			delete downedKeys[Keyboard.RIGHT];
			//downedKeys = [];
			if (nextStep.x  > x + velocity) {
				downedKeys[Keyboard.RIGHT] = true;
			}else if ( x > nextStep.x + velocity){
				downedKeys[Keyboard.LEFT] = true;
			};
			
			if (nextStep.y < y) {
				downedKeys[Keyboard.UP] = true;
			}else if (nextStep.y > y)
				downedKeys[Keyboard.DOWN] = true;
			
			Stick();
			if (stickedFrames > 0) {
				
				if(stickedFrames > 1){
					stickedFrames --;
					stickMove();
				}else {
					stickMove();
					
				}
				
				
				return;
			}
		
			
			var isClimb: Boolean = false;
			
			/*Moving to character */
			/*if ( LodeRunner.mainCharacter.y - this.y >= LodeRunner.TILE_HEIGHT ) {
				downedKeys[Keyboard.DOWN] = true;
				if ( Climb(CLIMB_FULL_CONNECTION) ) {
					isClimb = true;
				}
			}
			if ( this.y - LodeRunner.mainCharacter.y >= 0) {
				downedKeys[Keyboard.UP] = true;
				if ( Climb(CLIMB_FULL_CONNECTION)) {
					isClimb = true;
				}
			}
				
			if(isClimb){
				if(LodeRunner.mainCharacter.y > this.y){
					downedKeys[Keyboard.DOWN] = true;
					climbDirection = DOWN;
				}else{
					downedKeys[Keyboard.UP] = true;
					climbDirection = UP;
				}
					
			}else {
				if(Math.abs (LodeRunner.mainCharacter.x - this.x) >= 2){
					if (LodeRunner.mainCharacter.x  < this.x ){
						downedKeys[Keyboard.LEFT] = true;
							Move();
					}else{
						downedKeys[Keyboard.RIGHT] = true;
						Move();
					}
				}
			}*/
			
			
			super.OnEnterFrame(e);
		}
		
		public function Stick(): Boolean {
			if (stickedFrames == 0) {
				var objects: Array = [];
				objects = getObjectsUnder (this.x, this.y);
				
				if (objects.length == 0)
					return false;
				
				var object: MovieClip;
				for (var i: String in objects) {
					object = LodeRunner.getMovieClipForCollide(objects[i]);
					if (object is Brick) {
						if ( Brick(object).isDisappeared()){
							stickedFrames = STICK_TIME * stage.frameRate;
							stickPosition.x = object.x;
							stickPosition.y = object.y;
							
							if (direction == 0)
								direction = RIGHT;
							climbingOutPosition.x = object.x + direction * LodeRunner.TILE_WIDTH;
							climbingOutPosition.y = object.y - LodeRunner.TILE_HEIGHT;
						}
					}
				}
			}else {
				
			}
			
			return true;
		}
		
		public function stickMove():Boolean {	
			if (stickedFrames > 1 ) {
				TestDeathForBrick();
				translateToPoint(stickPosition, false);
			}else {
				if (translateToPoint(climbingOutPosition, true))
					stickedFrames = 0;
				TestDeathForBrick();
			}
			
			return true;
		}
		
		private function translateToPoint(point: Point, beforeY: Boolean) : Boolean {
			var result: Boolean = true;
			
			var directionX: Number = 0;
			var directionY: Number = 0;
			var deltaX: Number = 0;
			var deltaY: Number = 0;
			
			if (x < point.x)
				directionX = 1;
			else if (x > point.x)
				directionX = -1;
			
			if (directionX != 0) {
				deltaX = Math.min(velocity, Math.abs(point.x - x));
				deltaX *= directionX;
			};
			
			if (y < point.y)
				directionY = 1;
			else if (y > point.y)
				directionY = -1;
			
			deltaY = Math.min(velocity, Math.abs(point.y - y));
			deltaY *= directionY;
			
			if (beforeY){
				y += deltaY;
				if (deltaY == 0)
					x += deltaX;
			}else{
				x += deltaX;
				if (deltaX == 0)
					y += deltaY;
			}
						
			return deltaX == 0 && deltaY == 0;
		}
		
		private function clearWaveMap() {
			var passMap = LodeRunner.passMap;
			for (var i: Number = 0; i < passMap.length; i++) {
				waveMap[i] = [];
				for (var j: Number = 0; j < passMap[i].length; j++) {
					waveMap[i][j] = Infinity;
				}
			}
		}
		private function generateWaveMap(startX: Number, startY: Number, currentNumber: Number = -1, from: Number = 0) {
			var passMap: Array = LodeRunner.passMap;
			var currentTile: Number = 0;
			
			currentNumber ++;
			
			if (waveMap[startY] [startX] < currentNumber) 
				return;
				
			waveMap[startY][startX] = currentNumber;
				
			
			currentTile = passMap[startY][startX];
			
			if ( currentTile & LodeRunner.MAP_LEFT )
				generateWaveMap(startX - 1, startY, currentNumber);
			
			if ( currentTile & LodeRunner.MAP_RIGHT )
				generateWaveMap(startX + 1, startY, currentNumber);
			
			if ( currentTile & LodeRunner.MAP_DOWN )
				generateWaveMap(startX, startY + 1, currentNumber);
			
			if ( currentTile & LodeRunner.MAP_UP )
				generateWaveMap(startX, startY - 1, currentNumber);
				
			
		}
		
		private function getNextStep(finish: Point ): Point {
			if ( waveMap[finish.y][finish.x] == 0)
				return null;
		
			if ( waveMap[finish.y][finish.x] == Infinity )
				return null;
			var result: Point = new Point();
			
			var minX, minY: Number = 0;
			
			minX = Math.max(finish.x - 1, 0);
			minY = Math.max(finish.y - 1, 0);
			
			if (finish.x > 0) {
				if ( waveMap[finish.y][finish.x - 1] <= waveMap[finish.y][finish.x] )
					if (LodeRunner.passMap[finish.y][finish.x - 1] & LodeRunner.MAP_RIGHT) {
						result.x = finish.x - 1;
						result.y = finish.y;
						return result;
					}
			}
			
			if (finish.x < stage.stageWidth / LodeRunner.TILE_WIDTH - 1) {
				if ( waveMap[finish.y][finish.x + 1] <= waveMap[finish.y][finish.x] )
					if (LodeRunner.passMap[finish.y][finish.x + 1] & LodeRunner.MAP_LEFT){
						result.x = finish.x + 1;
						result.y = finish.y;
						return result;
					}
			}
			
			if (finish.y > 0) {
				if ( waveMap[finish.y - 1][finish.x] <= waveMap[finish.y][finish.x] )
					if (LodeRunner.passMap[finish.y - 1][finish.x] & LodeRunner.MAP_DOWN){
						result.x = finish.x;
						result.y = finish.y - 1;
						return result;
					}				
			}
			
			if (finish.y < stage.stageHeight / LodeRunner.TILE_HEIGHT - 1) {
				if ( waveMap[finish.y + 1][finish.x] <= waveMap[finish.y][finish.x] )
					if (LodeRunner.passMap[finish.y + 1][finish.x] & LodeRunner.MAP_UP){
						result.x = finish.x;
						result.y = finish.y + 1;
						return result;
					}
			}			
			return null;
		}
		
		private function getPath(destination: Point): Array {
			var result: Array = [destination];
			var nextStep: Point = destination.clone();
			
			while ( (nextStep = getNextStep(nextStep)) != null ) {
				result.push(nextStep);
			}
			
			result.length = result.length - 1;
			result.reverse();
			return result;
		}
		
		private function traceWaveMap() {
			for ( var i: Number = 0; i < waveMap.length; i++) {
				
				var s: String = "";
				
				for ( var j: Number = 0; j < waveMap[i].length; j++) {
					if ( waveMap [i][j] < 10 )
						s += '0' + waveMap[i][j] + ' ';
					else if (waveMap[i][j] < Infinity)
						s += waveMap[i][j] + ' ';
					else s += "## ";
					
				}
				trace(s);
			}
		}
		
		public override function Die() {
			if (regenerationFrames != 0)
				return;
				
			LodeRunner.deadEnemiesScores += 100;
			LodeRunner.scores += 100;
			visible = false;
			regenerationFrames = REGENERATION_TIME * stage.frameRate;
		}
	}
	
}
