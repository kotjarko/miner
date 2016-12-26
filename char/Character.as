package char{
	
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.geom.Point;
	import flash.display.DisplayObject;
	import level.Stairs;
	import level.Bar;
	import level.Brick;
	import level.Treasure;
	import level.Solid;
	import flash.utils.Dictionary;

	public class Character extends MovieClip {
		
		static public const LEFT = -1;
		static public const RIGHT = 1;
		
		static protected const VELOCITY = 75;
		
		static public const STAY = 0;
		static public const MOVE = 1;
		static public const CLIMB = 2;
		static public const FALL = 3;
		
		public var action: Number = STAY;
		
		static public const UP = -1;
		static public const DOWN = 1;
		
		static protected const CLIMB_FULL_CONNECTION = 3;
		static protected const CLIMB_PARTICULARY_CONNECTION = 2;
		static protected const KEY_LEFTDIG = Keyboard.Z;
		static protected const KEY_RIGHTDIG = Keyboard.X;
		static protected const KEY_TEST = Keyboard.T;
		

		protected var downedKeys: Array = [];
		protected var climbDirection:Number = STAY;
		
		protected var jumpDownHeight:Number = -1;	
		protected function get velocity(): Number {
			return VELOCITY * stage.frameRate / 1000;
		}
		//private var 
		
		
		public function get direction (): Number{
			return this.scaleX;
		}
		public function set direction (num: Number): void{
			this.scaleX = num;
		}
			
		public function Character() {
			this.direction = LEFT;
			
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);
			addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
		}
		
		public function OnEnterFrame(e: Event): void {	
			if (stage == null)
				return;
		
			if (downedKeys[Keyboard.UP])
				climbDirection = UP;
			else if (downedKeys[Keyboard.DOWN])
				climbDirection = DOWN;
			else
				climbDirection = STAY;
				
			TestDeathForBrick();
			GrabTreasure();	
			
			if (Climb(CLIMB_FULL_CONNECTION))
				action = CLIMB;
			else if (Fall())
				action = FALL;
					
			switch (action){
				case FALL: {
					CentreHorizontal(false);
					
					if(!Fall(false)){
						action = STAY;
					}
						
				}break;
				
				case CLIMB:{
					if (downedKeys[Keyboard.LEFT] ) {
						direction = LEFT;
						Move(false);
					}else if (downedKeys[Keyboard.RIGHT] != undefined) { 
						direction = RIGHT;
						Move(false);
					}
					
					if(!Climb(CLIMB_PARTICULARY_CONNECTION, false))
						action = STAY;
				}break;
				case MOVE: {
					if ( Move(false))
						action = STAY;
				}
				case STAY: {						
					
					//Moving
					if (downedKeys[Keyboard.LEFT]) {
						this.direction = LEFT;
						action = MOVE;
					}else if (downedKeys[Keyboard.RIGHT] ) {
						this.direction = RIGHT;
						action = MOVE;
					}else
						action = STAY;
					CentreVertical(false);
				}break;				
			}			
		}
		
		public function OnRemovedFromStage(e: Event):void{
			removeEventListener(Event.ENTER_FRAME, OnEnterFrame);
			removeEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
		}
				
		public function Fall(onlyTest: Boolean = true):Boolean {
			if (stage == null) {
				return false;
			}
			
			if( Swarm(onlyTest) )
				return false;
				
			var mustFall: Boolean = canMove(0, DOWN) && (action != CLIMB || canMove(0, UP)) ;
			
			if(mustFall && !onlyTest){
				this.y += velocity;
			}

			return mustFall;
		}
		
		public function Move(onlyTest: Boolean = true): Boolean{
			var can = canMove(this.direction, 0);
			if(can && !onlyTest){
				this.x += velocity * this.direction;			
			}
			return can;
		}		
		
		public function Climb(connectionCount: Number, onlyTest: Boolean = true): Boolean{
			var result: Boolean = false;
			var climbConnectionPointsCount: Number = 0;			
			
			for each (var object in getObjectsUnder(this.x, getLegY() )) {
				if (LodeRunner.getMovieClipForCollide(object) is Stairs)
					climbConnectionPointsCount ++;
			}
			
			result = climbConnectionPointsCount >= connectionCount;
			result &&= canMove(0, climbDirection);
			
			if(!onlyTest && result ){				
				
				this.y += climbDirection*velocity;
			}
			
			return result;
		}
		
		public function Swarm(onlyTest: Boolean = true): Boolean{
			onlyTest = false;
			
			if( this.jumpDownHeight != - 1){

				if( this.y - jumpDownHeight > this.height ){
					if(!onlyTest)
						jumpDownHeight = -1;
				}else{
					CentreHorizontal(false);
					return false;
				}
			}
					
			var nextX: Number = this.x;// + 
				//direction * velocity * stage.frameRate/1000;
			
			var objectsNear: Array = this.getObjectsUnder(
								nextX,
								this.y - this.height / 3);
			
			var result: Boolean = false;
			for each (var object in objectsNear){
				if (object.parent is level.Bar){
					if(jumpDownHeight == -1){
						if(downedKeys[Keyboard.DOWN]){
							result = false;
							
							if(!onlyTest)
								jumpDownHeight = this.y;
						}else
							result = true;
					}else {
						result = false;
						
					}
				}
			}
			
			return result;
		}
		
	
		public function CentreVertical (onlyTest: Boolean = true): Boolean {
			//return true;
			var tileHeight = LodeRunner.TILE_HEIGHT;
			
			if (this.y % tileHeight - tileHeight / 2 > 0) {
				if(!onlyTest)
					this.y -= Math.min(this.y % tileHeight - tileHeight / 2, velocity);
				return false;
			}else if (this.y % tileHeight - tileHeight / 2 < 0) {
				if(!onlyTest)
					this.y += 1;
				return false;
			}
			return true;
		}
		
		static private var centreCount: Number = 0;
		public function CentreHorizontal(onlyTest: Boolean = true):Boolean{
										
			return true;
			var tileWidth: Number = LodeRunner.TILE_WIDTH;
			if( this.x % tileWidth  < tileWidth / 2){
				if(!onlyTest)
				{
					direction = RIGHT;
					this.x +=  Math.min( velocity, 
										(this.x - tileWidth) % tileWidth);
				}
				return false;
			}else if( this.x % tileWidth > tileWidth  / 2){
				if(!onlyTest){
					direction = LEFT;
					this.x -= Math.min( velocity, 
										(this.x - tileWidth/2) % tileWidth);
				}
				return false;
			}
			return true;
		}
		
		public function GrabTreasure(): Boolean{
			for each (var treasure in getObjectsUnder(this.x, this.y)){
				if(treasure.parent.parent is level.Treasure){
					Treasure(treasure.parent.parent).beGrabbed();
					return true;
				}
			}
			return false;
		}
		
		public function Die(){
			this.x = 200;
			this.y = 200;
		}
		public function TestDeathForBrick():Boolean{
			for each (var object in getObjectsUnder(this.x, this.y)){
				if(LodeRunner.getMovieClipForCollide(object) is Brick){
					if( Brick(LodeRunner.getMovieClipForCollide(object)).isAppearing()){
						Die();
						return true;
					}
				}
			}
			return false;
		}

		protected function getLegY():Number {
			return this.y + this.height / 2 - 1;
		}
		public function canMove(directionX: Number, directionY: Number):Boolean {
			if (stage == null)
				return false;
			
			var newPosition: Point = new Point(this.x + 
											 	directionX * (velocity + this.width/2),
										   this.y + directionY * this.height/2 + velocity);
			if(newPosition.x < 0)
				return false;
			
			if(newPosition.x > stage.stageWidth )
				return false;
			
			var intersections: Array = [];
			if(directionX != 0)
				intersections = intersections.concat(getObjectsNear(newPosition.x, newPosition.y));
			
			if(directionY != 0)
				intersections = intersections.concat(getObjectsUnder(newPosition.x, newPosition.y));
									
			var result:Boolean = true;
			
			var collisionCount: Number = 0;
			var collide: Boolean = false;//directionY>=0?true:false;
			for (var i: String in intersections){
				var intersection: MovieClip = 
					LodeRunner.getMovieClipForCollide(intersections[i]);
				
				if(intersection is Solid)
					if ( !Solid(intersection).isPassable())
						collisionCount ++;
					
			}
			
			collide = collisionCount >= 1;
			result = !collide;
			
			if(directionY < 0){
				if (!collide) {
					intersections = getObjectsUnder(newPosition.x, getLegY());
					var stairConnectionCount: Number = 0;
					for (var i: String in intersections){
						intersection = LodeRunner.getMovieClipForCollide(intersections[i]);
						if(intersection is Stairs)
							stairConnectionCount ++;
					}
					
					result &&= (stairConnectionCount >= CLIMB_FULL_CONNECTION);
				};
			}
			
			return result;
			
		}
		public function getObjectsUnder(_x: Number, _y: Number):Array{
			return LodeRunner.getObjectsUnder(_x, _y, this.width);
		}
		
		public function getObjectsNear(_x: Number, _y: Number): Array{
			return LodeRunner.getObjectsNear(_x, _y, this.height);
		}
	}
	
}
