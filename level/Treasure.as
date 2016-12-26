package level {
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	
	public class Treasure extends MovieClip{
		
		
		public function Treasure() {
			// constructor code
			stop();
			addEventListener(Event.ADDED_TO_STAGE, OnAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, OnRemovedFromStage);
			addEventListener(Event.ENTER_FRAME, OnEnterFrame);
		}
		
		public function isGrabbed(): Boolean{
			return currentLabel != "Normal";
		}
		public function beGrabbed(){
			if(isGrabbed())
				return;
			
			LodeRunner.treasureCount --;
			LodeRunner.treasureScores += 100;
			LodeRunner.scores += 100;
			
			if (LodeRunner.treasureCount == 0) {
				LodeRunner(root).levelCompleted();
			}
			gotoAndPlay("Disappearing");
		}

		private function OnAddedToStage(e: Event):void{
			LodeRunner.treasureCount ++;
		}
		
		private function OnRemovedFromStage(e: Event): void {
		}

		private function OnEnterFrame(e: Event){
			if(currentLabel == "Disappeared"){
				stop();
			}
		}
	}
	
}
