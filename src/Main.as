/*

SkyBox example in Away3d

Demonstrates:

How to use a CubeTexture to create a SkyBox object.
How to apply a CubeTexture to a material as an environment map.

Code by Rob Bateman
rob@infiniteturtles.co.uk
http://www.infiniteturtles.co.uk

This code is distributed under the MIT License

Copyright (c)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the “Software”), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

package
{
	import away3d.cameras.lenses.*;
	import away3d.containers.*;
	import away3d.entities.*;
	import away3d.materials.*;
	import away3d.materials.methods.*;
	import away3d.primitives.*;
	import away3d.textures.*;
	import away3d.utils.*;

	import com.codecatalyst.promise.Deferred;
	import com.codecatalyst.promise.Promise;

	import flash.display.*;
	import flash.events.*;
	import flash.geom.Vector3D;
	import flash.system.Security;
	import flash.net.URLRequest;
	import flash.external.ExternalInterface;


	[SWF(backgroundColor="#000000", frameRate="60", quality="LOW")]

	public class Main extends Sprite
	{
		//engine variables
		private var _view:View3D;
		private var trackMove:Boolean = false;
		private var isOver:Boolean = false;
		private var startX:Number = 0;
		private var startY:Number = 0;
		//scene objects
		private var _skyBox:SkyBox;
		private var _torus:Mesh;
		private var emptyBitmap:BitmapData = new BitmapData(size, size, false);
		private var size:int = 1024;
		private var jsInterfaceName:String;
		private var sides:Array = sides = [
		    {
		      	side: "left",
		      	lng: Math.PI * 1.5,
		      	lat: 0
		    }, {
		      	side: "front",
		      	lng: 0,
		      	lat: 0
		    }, {
		      	side: "right",
		      	lng: Math.PI / 2,
		      	lat: 0
		    }, {
		      	side: "back",
		      	lng: Math.PI,
		      	lat: 0
		    }, {
		      	side: "top",
		      	lng: -1 * Math.PI / 2,
		      	lat: Math.PI
		    }, {
		      	side: "bottom",
		      	lng: Math.PI / 2,
		      	lat: -1 * Math.PI
		    }
		];

		/**
		 * Constructor
		 */
		public function Main()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");

			Security.loadPolicyFile('http://scs.ganjistatic1.com/crossdomain.xml');
			Security.loadPolicyFile('http://image.ganjistatic1.com/crossdomain.xml');

			jsInterfaceName = stage.loaderInfo.parameters.jsInterfaceName as String;

			//setup the view
			_view = new View3D();
			addChild(_view);

			//setup the camera
			_view.camera.z = -100;
			_view.camera.y = 0;
			_view.camera.lookAt(new Vector3D());
			_view.camera.lens = new PerspectiveLens(60);
			var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(
				emptyBitmap,
				emptyBitmap,
				emptyBitmap,
				emptyBitmap,
				emptyBitmap,
				emptyBitmap
			);

			_skyBox = new SkyBox(cubeTexture);
			_view.scene.addChild(_skyBox);

			//setup the render loop
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);

			stage.addEventListener(Event.RESIZE, onResize);
			onResize();

			_view.camera.position = new Vector3D();
			_view.camera.moveBackward(600);
			_view.render();

			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);

			ExternalInterface.addCallback('loadImage', function (url:String):void {
				loadImage(url);
			});

			send('ready');
		}

		private function onMouseOver(e:Event):void {
			isOver = true;
		}

		private function onMouseDown(e:Event):void {
			trackMove = true;
			startX = stage.mouseX;
			startY = stage.mouseY;
		}

		private function onMouseUp(e:Event):void {
			trackMove = false;
		}

		private function onMouseOut(e:Event):void {
			trackMove = false;
			isOver = false;
		}

		private function onMouseMove(e:Event):void {
			if (!trackMove) {
				return;
			}
			_view.camera.rotationY += -0.3 * (stage.mouseX - startX);
			_view.camera.rotationX -= 0.3 * (stage.mouseY - startY);

			startX = stage.mouseX;
			startY = stage.mouseY;

			_view.render();
		}

		private function loadImage(url:String):void {
			var loader:Loader = new Loader();
			var material:SkyBoxMaterial = _skyBox.material as SkyBoxMaterial;
			var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(
				emptyBitmap,
				emptyBitmap,
				emptyBitmap,
				emptyBitmap,
				emptyBitmap,
				emptyBitmap
			);

			_view.camera.rotationX = 0;

			material.cubeMap = cubeTexture;
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function (e:Event):void {
				var bmp:Bitmap = loader.content as Bitmap;
				var bitmaps:Array = [];
				var side:int = 0;
				while (side <= 5) {
					bitmaps[side] = processSide(bmp.bitmapData, side);
					side ++;
				}

				//setup the cube texture
				var cubeTexture:BitmapCubeTexture = new BitmapCubeTexture(
					bitmaps[2],
					bitmaps[0],
					bitmaps[4],
					bitmaps[5],
					bitmaps[1],
					bitmaps[3]
				);

				material.cubeMap = cubeTexture;

				_view.render();
				send('ready: '+url);
			});

			loader.load(new URLRequest(url));
		}

		private function processSide(sourceImage:BitmapData, side:int):BitmapData {
			var data:BitmapData = new BitmapData(size, size, false);
			var x:int = 0, y:int = 0, j:int = 0, k:int = 0;
			var color:uint;
			var ref:Array;
			var count:int = 0;
			for (y = j = 0; 0 <= size ? j <= size : j >= 0; y = (0 <= size ? ++j : --j)) {
				for (x = k = 0; 0 <= size ? k <= size : k >= size; x = (0 <= size ? ++k : --k)) {
					ref = getAngleTo(side, x, y);

					color = sourceImage.getPixel(
						int(ref[0] / Math.PI / 2 * sourceImage.width),
						int((ref[1] + Math.PI / 2) / Math.PI * sourceImage.height)
					);

					data.setPixel(x, y, color);
				}
			}
			return data;
		}

		private function getAngleTo(side:int, x:int, y:int):Array {
			var X:Number, Y:Number, Z:Number;
			var hyp:Number, lat:Number, lng:Number;
			var latOffset:Number, lngOffset:Number;

			X = x - size / 2;
			Y = y - size / 2;
			Z = size / 2;

			lngOffset = sides[side].lng;
			latOffset = sides[side].lat;
			/* top == 4, bottom === 5*/
			if (side === 4 || side === 5) {
				hyp = Math.sqrt(X*X + Y*Y);
				lng = lngOffset + Math.atan2(Y, X);
				lat = Math.atan2(Z, hyp);

				if (side === 4) {
					lat *= -1;
					lng *= -1;
				}
			} else {
				hyp = Math.sqrt(X*X + Z*Z);
				lng = lngOffset + Math.atan2(X, Z);
				lat = Math.atan2(Y, hyp);
			}

			while (lng < 0) {
				lng += Math.PI * 2;
			}

			lng = lng % (Math.PI * 2);

			return [lng, lat];
		}

		/**
		 * render loop
		 */
		private function _onEnterFrame(e:Event):void
		{
			if (trackMove || isOver) {
				return;
			}

			_view.camera.position = new Vector3D();
			_view.camera.rotationY += 0.2;

			_view.camera.moveBackward(600);

			_view.render();
		}

		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}

		private function debug(msg:String):void{
			/*ExternalInterface.call('window.alert', msg);*/
		}

		private function send(msg:String):void {
			ExternalInterface.call(jsInterfaceName, msg);
		}
	}
}
