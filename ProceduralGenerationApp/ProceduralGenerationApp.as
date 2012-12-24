package {
import components.LabelX;
import components.NumericStepperX;

import content.*;

import fl.core.UIComponent;

import flash.display.*;
import flash.events.*;
import flash.filters.*;
import flash.geom.Point;
import flash.media.Sound;
import flash.text.*;

import keyboard.KeyPoller;

import object.*;
import object.entity.enemy.Plane;
import object.tile.Tile;

	public class ProceduralGenerationApp extends MovieClip
	{
		[SWF(backgroundColor="0x000000",width="1280",height="960",frameRate="50")]
		private var rotationFactor:Number = 0;
		private var objectArray:Array = new Array();
		private var tileArray:Array = new Array;
		private var hideDelay:Number = 1;
		private var componentHash:Object = new Object();
		private var bitmapArray:Array = new Array();
		private var scrollingObjectsArray:Array = new Array();
		private var data:BitmapData;
		private var tileSpeed:Number = 5;
		private var keyPoller:KeyPoller;
		private const OBJECT_SCROLL:Boolean = false;
		private const NUM_OBJECTS_INIT:Number = 100;
		// !TODO! Add information on objects on click, or altClick, etc. (show vx, vy, accel, grav, etc.)
		
		public function ProceduralGenerationApp()
		{
			//	loadMusic();
			var player:BmpPlayer = new BmpPlayer();	
			bitmapArray.push(player);
			var startText:TextField = showStartText();
			keyPoller = new KeyPoller();
			trace('init app');
		//	trace('bounds: ' + stage.stageWidth + ", "+ stage.stageHeight);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			createObjects(NUM_OBJECTS_INIT);
			sortBySize();
			tileBackground();
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyPressed);
		}
		
		private function createComponent(comName:String, labelText:String, objectType:DisplayObject):DisplayObject {
			var label:LabelX = new LabelX(labelText);
			var component:Object = objectType;
			componentHash[comName] = component;
			componentHash[comName].addChild(label);
			trace(componentHash[comName].getChildAt(3));
			label.textField.setTextFormat(new TextFormat("_sans"));
			return componentHash[comName];
		}
		
		private function initAccelStepper():void {
			var accelStepper:NumericStepperX = createComponent('accelStepper', "Acceleration", new NumericStepperX) as NumericStepperX;
			var accelLabel:LabelX = componentHash['accelStepper'].getChildAt(3);
			addChild(accelStepper);
		//	addChild(accelLabel);
			accelStepper.minimum = 0;
			accelStepper.maximum = 2;
			accelStepper.value = objectArray[0].accel;
			accelStepper.stepSize = .1;
			accelStepper.x = accelStepper.y = 250;
			accelLabel.y += 1;
			accelLabel.x = accelStepper.width + 4;
			accelStepper.addEventListener(Event.CHANGE, onStepperChange);
		//	componentHash = new Object();
		//	componentHash += {accelStepper:accelStepper};
		}
		
		private function initGravityStepper():void {
			var gravStepper:NumericStepperX = createComponent('gravStepper', "Gravity (down)", new NumericStepperX) as NumericStepperX;
			var gravLabel:LabelX = componentHash['gravStepper'].getChildAt(3);
			addChild(gravStepper);
		//	addChild(gravLabel);
			gravStepper.minimum = 0;
			gravStepper.maximum = 2;
			gravStepper.value = objectArray[0].gravity;
			gravStepper.stepSize = .05;
			gravStepper.x = 250;
			gravStepper.y = 220;
			gravLabel.y += 1;
			gravLabel.x = gravStepper.width + 4;
			gravStepper.addEventListener(Event.CHANGE, onStepperChange);
		//	componentHash = new Object();
		//	componentHash += {gravStepper:gravStepper};	
		}
		
		
		// !TODO! build into baseObject, children, pause functions, pause variable
		private function pause():void {
			trace("p pressed, going to pause menu");
			for each (var ob:Object in objectArray) {
				ob.paused = true;
				ob.removeEventListener(MouseEvent.CLICK, onObjectClick);
				ob.blendMode = BlendMode.SCREEN;
				ob.alpha = .3;
			}
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			// if components have NOT been made yet, below will be false; when they are made, turns to true
			// this is needed to add them to the 
			var componentsInit:Boolean = false;
			hideDelay = 199;
			if (!componentHash.accelStepper) {
				initAccelStepper();
				
 			}
			if (!componentHash.gravStepper) {
				initGravityStepper();
			}
			for each (var obj:UIComponent in componentHash) {
				addChild(obj);
				obj.enabled = true;
			}

		}
		
		private function unpause():void {
			var totalVx:Number = 0;
			var totalVy:Number = 0;
			trace('num of objects: ' + objectArray.length);
			for each (var ob:Object in objectArray) {
				
				ob.accel = componentHash.accelStepper.value;
				ob.gravity = componentHash.gravStepper.value;
				ob.paused = false;
			//	ob.addEventListener(MouseEvent.CLICK, onObjectClick);
				ob.blendMode = BlendMode.NORMAL;
				ob.alpha = 1;
				totalVx += ob.vx;
				totalVy += ob.vy;
			}
			//trace('Total vx = ' + totalVx + ', total vy = ' + totalVy + ', total v = ' + String(totalVx + totalVy)); 
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			for each (var obj:UIComponent in componentHash) {
				trace(obj.parent);
				obj.enabled = false;
				removeChild(obj);
				trace('removed ' + obj + ' from display list')
			}
			//removeChild(componentHash.accelSlider);
			//for each (var num:TextField in componentHash.accelSlider.textArray) {
				//removeChild(num);
			//}
			stage.focus = stage;
		}
		
		private function onKeyPressed(event:KeyboardEvent):void {

			//trace('bounds: ' + stage.stageWidth + ", "+ stage.stageHeight);
			if (event.keyCode == 80 && !objectArray[0].paused) {
				pause();
			}
			// on "P" pressed again, unpause game
			else if (event.keyCode == 80) {
				unpause();
			}
		}
		
		private function onStepperChange(event:Event):void {
			//trace(event.currentTarget.value);
			//for each (var ob:Object in objectArray) {
				//ob.accel = event.currentTarget.value;
			//}
		}
		
		private function showStartText():TextField {
			var msg:TextField = new TextField();
			addChild(msg);
			msg.text = 'Press "P" for options';
			msg.alpha = .7;
			msg.autoSize = TextFieldAutoSize.CENTER;
			msg.x = stage.stageWidth / 2 - msg.width / 2;
			msg.y = stage.stageHeight / 2 - 20;
			msg.selectable = false;
			msg.backgroundColor = 0xFFFFFF;
			msg.background = true;
			msg.blendMode = BlendMode.SCREEN;
			//trace(msg.alpha);
			var msgFormat:TextFormat = new TextFormat(); 
			msgFormat.font = "OCR A Std";
			msgFormat.bold = true;
			msgFormat.size = 30;
			msgFormat.color = 0x111111;
			msgFormat.align = "center";
			msg.setTextFormat(msgFormat)
			msg.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			return msg;
		}
		
		private function tileBackground():void {
			var sampleTile:Tile = new Tile();
			var numHorz:Number = Math.ceil(stage.stageWidth / sampleTile.width) + 2;
			var numVert:Number = Math.ceil(stage.stageHeight / sampleTile.height) + 2;
			for (var i:Number = 0; i <= numHorz; i++) {
				for (var j:Number = 0; j <= numVert; j++) {
					var tile:Tile = new Tile();
					tile.x = (i-1)*tile.width;
					tile.y = (j-1)*tile.height;
					this.addChildAt(tile, 0);
					tileArray.push(tile);
					objectArray.push(tile);
				//	scrollObject(tile);
	//				trace("tile " + i + ", " + j + " has x, y of " + tile.x + ", " + tile.y);
				}
			}
		}
		
		private function createObjects(repeatTimes:uint):void {
			//!TODO! put blur/scale function into object class
			//!TODO! tweak blur function so less blur (esp. on foreground)
			var char_rotation:Number = 49;
			var j:Number = 0;
			for(var i:Number = 0; i < repeatTimes; i++) {
				var character:Plane = new Plane(); 
				scrollObject(character);
				this.addChild(character);
			//  	var hexPool:Array = new Array("0","1","2","3","4",'5','6','7','8','9','A','B','C','D','E'/*,'F'*/);
			//	var randHex:Function = new Function();
			//	var hexNum:String ="0x" + hexPool[Math.floor(Math.random() * hexPool.length)] + hexPool[Math.floor(Math.random() * hexPool.length)] + hexPool[Math.floor(Math.random() * hexPool.length)] + hexPool[Math.floor(Math.random() * hexPool.length)] + hexPool[Math.floor(Math.random() * hexPool.length)] + hexPool[Math.floor(Math.random() * hexPool.length)];
			//	character.hexColor = uint(hexNum);  //THIS STUFF USED FOR DRAWING CIRCLES (not sprites)
				var playerImg:BmpPlayer = new BmpPlayer();
		//		playerImg.blendMode = 'difference';
				character.addChild(playerImg);
			//	character.graphics.beginFill(uint(hexNum)); //uncomment to turn circles back on
				var random:Number = 4*Math.random(); //random number between 0 and 4
			//	if(random <= 4) character.graphics.drawCircle(character.x, character.y, 10);
			//	else if (random <= 4) character.graphics.drawRect(character.x, character.y, 20, 15);
				//else if (random <= 4) character.graphics.drawEllipse(character.x, character.y, 20, 15);
				//else if (random <= 4) character.graphics.drawRoundRect(character.x, character.y, 20, 15, 20);
				//character.graphics.lineStyle(1, uint(hexNum));
				//character.graphics.lineTo(character.x+10, character.y);
			//	character.graphics.endFill();
				character.rotation = char_rotation; // character.x += character.y += (Math.random()*360);
				if(j > (stage.stageWidth)/10) j = -1;
				j++;
				var blur:BlurFilter = new BlurFilter();
				// the higher random, the higher blur, the lower scale, the lower dropShadow.distance
				random = Math.random() - .5; //range is +/- 0.5
				var dropShadow:DropShadowFilter = new DropShadowFilter(1 + random*10, char_rotation+90); //orig 4
				dropShadow.quality = BitmapFilterQuality.HIGH;
				dropShadow.alpha = 0.9 + random/2;
				// scale range SHOULD BE .5 -> 2.0
				character.scaleX = character.scaleY = 1.3 - 4*random;
				if (character.scaleX < .5)
					character.alpha = 0;
				blur.blurX = blur.blurY = (1+random) //random+Math.round(random/10);
				blur.quality = BitmapFilterQuality.HIGH;
				character.filters = [dropShadow, blur];
				//!TODO! fix bounds issues, out of bounds object creation
				var xCheck:Number = 10+200*Math.random()*character.scaleX*2;
			//	if (xCheck < 0 || xCheck > stage.stageWidth) trace('x changed from '+xCheck);
				character.x = !(xCheck < 0 || xCheck > stage.stageWidth) ?  xCheck : 200*Math.random()*1.5;
			//	trace('character.x: ' + character.x);
				var yCheck:Number = j*10*Math.random()*character.scaleY*2;
				//if (yCheck < 0 || yCheck > stage.stageHeight) trace('y changed from '+yCheck);
				character.y = !(yCheck < 0 || yCheck > stage.stageHeight) ?  yCheck : 200*Math.random()*2;
			//	trace('character.y: ' + character.y);
				//character.vy = (Math.random()-.5) * 5;
				//character.vx = (Math.random()-.5) * 5;
				objectArray.push(character);
				var obj:Object = new Object();
				var point:Point = character.globalToLocal(new Point(0,0));
			//	trace('point: ' + point);
				obj = {left:0, right: stage.stageWidth, down: stage.stageHeight, up:0+10};
				character.bounds = obj;
				var randNum:Number = Math.random();
				var randFactor:Number = 10;
				// turn below eq'n (and line above) into seperate function
				// also, make it so that below ~0.3, goes to above 0.3 (change formula, or add if statement);
				character.accelFactor = .1;
			//	character.accelFactor =  Math.abs(randNum/randFactor - 1/(2*randFactor)) ;
				if (character.accelFactor < .03) {
					character.accelFactor == 0.3;
				//	trace('character accel changed');
				}
				trace(character.scaleX + ' , ' + character.scaleY + ' for character ' + i);
			//	character.addEventListener(MouseEvent.CLICK, onObjectClick);
			//	character.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			}
			trace(repeatTimes +" objects of class " + objectArray[0] + " created");
		}
		
		private function onMouseOver(event:MouseEvent):void {
			var target:Object = event.currentTarget;
			target.graphics.beginFill(target.hexColor);
			target.graphics.lineStyle(5, 1, .5);
			target.graphics.lineTo(event.currentTarget.x+1000, event.target.y);
			target.graphics.endFill();
			//trace(target.filters[0].blurX);
			target.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver); 
		}
			
		private function onObjectClick(event:MouseEvent):void {
			var target:Object = event.currentTarget;
			//trace('target is ' + target.name);
			//trace('local x and y: ' + target.x +", " + target.y);
			//trace('stage x and y: ' + target.localToGlobal(new Point(target.x, target.y)).valueOf());
			reset();
		}
			
		// !TODO! change boundaries of character(s) based on scaleX or filters[0].blurX
		private function sortBySize():void {
			objectArray.sortOn("scaleX", Array.NUMERIC);
			for(var i:Number = 0; i < objectArray.length; i++) {
				this.addChildAt(objectArray[i], i);
			//trace(objectArray[i].scaleX +", " + objectArray[i].filters[0].blurX);
			}
			trace('Sorted ' + objectArray.length + " objects by scaleX")
		}
	
		private function hideStartText(event:Event):void {
			var obj:Object = event.currentTarget;
	    	obj.alpha -= hideDelay / 200;
	    	if (obj.alpha < .005) {
				removeChild(obj as DisplayObject);
	    		obj.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
	    	//	trace('pause text hidden');
	    	}
	    	//trace(obj.alpha);
		}

		
		
		private function reset():void {
			changeNumObjects(100);
			sortBySize();
		}
		
		private function changeNumObjects(num:Number):void {
			var ob:PhyicsObject;
			if (!num) return;
			num = Math.round(num);
			if (num>0) {
				for each (ob in objectArray) {
					//ob.vx = ob.vy = 0;
				}
				createObjects(num);
			}
			else if (num<0) {
				for each (ob in objectArray) {
					//ob.vx = ob.vy = 0;
				}
				// !TODO! add deleteObjects function (object=null, removeChild(), etc.)
				//deleteObjects(num);
				trace('deleted ' + num + ' objects');
			}
		}
		
		// !NOTE! This is a test/experiment... Treat it carefully.
	/*	private function loadMusic():void {
			try {
			var mp3Url:String = new String('http://www.unity303.com/mp3/tapt%20-%20gemstone.mp3');
			var context:SoundLoaderContext = new SoundLoaderContext(3000);
			var request:URLRequest = new URLRequest(mp3Url);
		// !TODO! WHY doesn't below work???? Debug...
			var music:Sound = new Sound();
			//music.play();
			var loader:Loader = new Loader;
			//request = new URLRequest("test.mp3");
			//music.load(request);
			try {
				loader.load(request);
			} catch(error:Error) {
				trace('FUCKED: ' + error.message);
			}
			//request.addEventListener(Event.COMPLETE, playMusic);
			//music.load(request, context);
			} catch(error:Error) {
				trace('fucked again: ' + error.message);
			}
		} */
		
		// !NOTE! see above !NOTE!
		private function playMusic(event:Event):void {
			var music:Sound = event.currentTarget as Sound;
			trace('played');
			
		}
		
		// !TODO! avoid onEnterFrame, uses too much memory/cpu, etc. just use eventListeners, if possible
		private function onEnterFrame(event:Event):void {
		 //  trace('entering frame from' + event.target);
		    //trace("entering frame");
		    if (event.currentTarget is TextField) {
		    	hideStartText(event);
		    }
		    // else if trying to read keys currently pressed
		    // !TODO! transfer stuff below in baseObject or mainStage (displayContainer) class, encapsulate
		    else {
				keyPoller.checkKeyPoll();
				// !TODO! add event listeners for arrow key events, test (keyboard.left, right, up, down, etc)
			}
			if(OBJECT_SCROLL) {
				for each (var obj:DisplayObject in scrollingObjectsArray) {
					// below for x-axis scrolling
					if (obj.x > stage.stageWidth) obj.x -= stage.stageWidth;
					else if (obj.x < 0/*stage.x*/) obj.x += stage.stageWidth;
					//below for y-axis scrolling
					if (obj.y > stage.stageHeight) obj.y -= stage.stageHeight;
					else if (obj.y < 0/*stage.y*/) obj.y += stage.stageHeight;
				}
			}
			for each (var tile:Tile in tileArray) {
				// below for x-axis TILE scrolling
				if (tile.x > stage.stageWidth + tile.width) tile.x -= stage.stageWidth + 2*tile.width;
				else if (tile.x < 0 - tile.width/*stage.x*/) tile.x += stage.stageWidth + 2*tile.width;
				//below for y-axis TILE scrolling
				if (tile.y > stage.stageHeight  + tile.height) tile.y -= stage.stageHeight + 2*tile.height;
				else if (tile.y < 0  - tile.height/*stage.y*/) tile.y += stage.stageHeight + 2*tile.height;
			}
		}
		
		private function scrollObject(target:DisplayObject):void {
			scrollingObjectsArray.push(target);
		}
	}
}
