package  char{
	
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
	
	
	public class Player extends Character {		
		
		static public const DIG = 4;
		static public const DIE = 5;
		public function Player() {

			super();
			
			LodeRunner.mainCharacter = this;
			
			this.direction = LEFT;
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, OnKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, OnKeyUp);
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);
			addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);			
		}
		
		public function OnKeyDown(e: KeyboardEvent): void{
			downedKeys[e.keyCode] = true;
			
			if(this.action == FALL)
				return;
		}
		
		public function OnKeyUp(e: KeyboardEvent): void{
			delete downedKeys[e.keyCode];
		}
		
				
		public function TestDeathForEnemy(): Boolean {
			for each(var object in getObjectsUnder(this.x, this.y)) {
				if (LodeRunner.getMovieClipForCollide(object) is Enemy ) {
					Die();
					return true;
				}
			}
			return true;
		}
		public override function OnEnterFrame(e: Event):void {
			if (action != DIE) {
				if (this.currentLabel != "Run") {
					this.gotoAndPlay("Run");
				}
			}else {
				if (this.currentLabel != "Death") {
					
					if ( LodeRunner.lifeCount <= 0 )
						LodeRunner(root).gotoAndStop ( 1, "GameOver");
					else
						LodeRunner(root).gotoAndStop(1, "StageLoading");
					action = STAY;
					gotoAndPlay("Run");
				}else
					return;
			}
			
			if(action == DIG){
				return;
			};
			super.OnEnterFrame(e);
			if(downedKeys[KEY_LEFTDIG]){
				if ( Dig(-1) )
					action = DIG;
			}else if(downedKeys[KEY_RIGHTDIG]){
				if ( Dig(1) )
					action = DIG;
			}
			TestDeathForEnemy();
			return;
		}
		
		public function Dig(direction: Number): Boolean{
			var place: Point = new Point(this.x + this.width  * direction, 
										 this.y + this.height);
			var objects: Array = stage.getObjectsUnderPoint(place);
			
			this.direction = direction;
			for (var i: String in objects) {
				var object: MovieClip = LodeRunner.getMovieClipForCollide(objects[i]);
				if(object is level.Brick){
					if( object.Disappear() ){
						object.addEventListener(level.Brick.DISAPPEARED,
															  OnDisappeared);
						return true;
					}
				}
			}
			return false;
		}
		
		public function OnDisappeared(e: Event) {
			action = STAY;	
		}
		
		public override function Die() {
			action = DIE;
			LodeRunner.lifeCount -= 1;
			gotoAndPlay("Death");
		}
	}
}
