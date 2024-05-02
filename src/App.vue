<template>
	<div id="main">
		<div id="controls">
			<div id="file-chooser-container">
				<label id="file-chooser-label" class="button"
					>Choose Image File
					<input type="file" id="image-file-chooser" @change="setImageFile" />
				</label>
				<br />
			</div>
			<div v-if="isImageLoaded" class="control-section">
				<div>
					<label>
						<input
							type="radio"
							name="contrast-type"
							value="hue"
							id="contrast-type-hue"
							@change="updateContrast"
						/>
						Hue
					</label>
					<label>
						<input
							type="radio"
							name="contrast-type"
							value="sat"
							id="contrast-type-sat"
							@change="updateContrast"
						/>
						Saturation
					</label>
					<label>
						<input
							type="radio"
							name="contrast-type"
							value="val"
							id="contrast-type-val"
							checked
							@change="updateContrast"
						/>
						Value
					</label>
				</div>
				<div id="slider-container">
					<label>
						Cutoff
						<input
							type="range"
							min="1"
							max="100"
							value="50"
							class="slider"
							id="contrast-range"
							@click="updateContrast"
							@change="updateContrast"
						/>
					</label>
				</div>
			</div>
			<div v-if="isContrastComputed" class="control-section">
				<div>Edge detection algorithm</div>
				<div>
					<label>
						<input
							type="radio"
							name="edge-detection-type"
							value="simple"
							id="edge-detection-type-simple"
							@change="setEdgeDetectionType"
						/>
						Simple
					</label>
					<label>
						<input
							type="radio"
							name="edge-detection-type"
							value="canny"
							id="edge-detection-type-canny"
							@change="setEdgeDetectionType"
						/>
						Canny
					</label>
					<label>
						<input
							type="radio"
							name="edge-detection-type"
							value="none"
							id="edge-detection-type-none"
							@change="setEdgeDetectionType"
						/>
						None
					</label>
					<div v-if="isShowCannyParams" id="canny-params">
						<div id="hysteresis-threshold-range-container">
							Hysteresis thresholds <br />
							<div id="hysteresis-threshold-range"></div>
						</div>
						<div>
							Gaussian blur sigma: {{ gaussianSigma.toFixed(2) }}<br />
							<input
								type="range"
								min="0"
								max="100"
								class="slider"
								id="gaussian-sigma-range"
								@input="setGaussianSigmaRange"
							/>
						</div>
					</div>
				</div>
				<div id="detect-edges-button" class="button" @click="detectEdges">
					Detect Edges
				</div>
			</div>
			<div v-if="isEdgesComputed" class="control-section">
				<div
					v-if="isContourDrawn"
					id="save-image-button"
					class="button"
					@click="saveImage"
				>
					Save Image
				</div>
				<div v-else>
					<label>
						Radius: {{ contourRadius }}<br />
						<input
							type="range"
							min="2"
							max="20"
							:value="contourRadius"
							class="slider"
							id="contour-radius-range"
							@input="setContourRadiusRange"
						/>
					</label>
				</div>
				<div>
					<label>
						<input id="fuzzy-contours-checkbox" type="checkbox" />
						Fuzzy contours?
					</label>
				</div>
				<div>
					<div id="draw-contours-button" class="button" @click="drawContours">
						Draw Contours
					</div>
				</div>
			</div>
			<div id="reset-button" class="button" @click="reset">Reset</div>
			<div id="spinner" v-if="isInProgress">
				<img src="spinner.gif" />
			</div>
			<!-- 		<div id="progress-container"> -->
			<!-- 			<div id="progress"></div> -->
			<!-- 		</div> -->
		</div>
		<div id="output">
			<canvas id="preview-canvas" width="300" height="600"></canvas>
		</div>
		<canvas id="input-canvas" width="300" height="600"></canvas>
		<canvas id="output-canvas"></canvas>
		<img id="input-image" class="hidden" />
		<img id="edge-image" class="hidden" />
	</div>
</template>

<script>
import CannyEdgeDetector from 'canny-edge-detector';
import Image from 'image-js';

const gaussianSigmaDefault = 1.1;
const black = '#000000';
const white = '#ffffff';

const hysteresisThresholds = {
	low: 10,
	high: 30,
};

export default {
	name: 'App',

	data() {
		return {
			isInProgress: false,
			isImageLoaded: false,
			isContrastComputed: false,
			isShowCannyParams: false,
			isEdgesComputed: false,
			isContourDrawn: false,
			gaussianSigma: gaussianSigmaDefault,
			contourRadius: 6,
			edgeDetectionType: 'simple',

			previewContext: null,
			outputContext: null,
			inputContext: null,
			inputCanvas: null,
			previewCanvas: null,

			edgePoints: [],
			img: null,
			edgeImg: null,
		};
	},

	methods: {
		saveImage() {
			const link = document.createElement('a');
			const base64 = this.outputCanvas.toDataURL();
			link.setAttribute('href', base64);
			link.setAttribute('download', 'contour-doodler-output.png');
			//		link.setAttribute("target", "_blank");
			link.click();
			this.copyToPreview();
			console.log('saved');
		},

		drawContours() {
			this.isContourDrawn = false;
			this.isInProgress = true;
			setTimeout(() => {
				const radius = this.contourRadius;
				const isFuzzy = document.getElementById(
					'fuzzy-contours-checkbox'
				).checked;
				this.outputContext.fillStyle = black;
				for (const point of this.edgePoints) {
					if (isFuzzy) {
						const grd = this.outputContext.createRadialGradient(
							point[0],
							point[1],
							0,
							point[0],
							point[1],
							radius
						);
						grd.addColorStop(0, black);
						grd.addColorStop(1, 'rgba(255, 255, 255, 0)');
						this.outputContext.fillStyle = grd;
					}
					this.outputContext.beginPath();
					this.outputContext.arc(point[0], point[1], radius, 0, 2 * Math.PI);
					this.outputContext.fill();
				}
				for (const point of this.edgePoints) {
					this.setPixel(this.outputContext, point[0], point[1], white);
				}
				this.isInProgress = false;
				this.copyToPreview();
				this.isContourDrawn = true;
			}, 0);
		},

		reset() {
			this.isContrastComputed = false;
			this.isEdgesComputed = false;
			this.isContourDrawn = false;
			this.previewContext.clearRect(
				0,
				0,
				this.previewCanvas.width,
				this.previewCanvas.height
			);
			this.outputContext.clearRect(
				0,
				0,
				this.outputCanvas.width,
				this.outputCanvas.height
			);
			this.repaint();
		},

		detectEdges() {
			const edgeAlgorithm = this.edgeDetectionType;
			this.isInProgress = true;
			this.isEdgesComputed = false;
			this.isContourDrawn = false;
			setTimeout(async () => {
				if (edgeAlgorithm == 'none') {
					this.edgePoints = [];
					const imageData = this.outputContext.getImageData(
						0,
						0,
						this.outputCanvas.width,
						this.outputCanvas.height
					);
					for (let x = 0; x < this.outputCanvas.width; x++) {
						for (let y = 0; y < this.outputCanvas.height; y++) {
							if (this.isBlack(this.getPixel(imageData, x, y))) {
								this.edgePoints.push([x, y]);
							}
						}
					}
					this.isEdgesComputed = true;
					this.isInProgress = false;
				} else if (edgeAlgorithm == 'canny') {
					const image = await Image.load(this.outputCanvas.toDataURL());
					const gray = image.gray();
					const options = {
						gaussianBlur: this.gaussianSigma,
						lowThreshold: hysteresisThresholds.low,
						highThreshold: hysteresisThresholds.high,
					};
					const edge = CannyEdgeDetector(gray, options);
					this.edgeImg.src = edge.toDataURL();
				} else if (edgeAlgorithm == 'simple') {
					this.edgePoints = [];
					const imageData = this.outputContext.getImageData(
						0,
						0,
						this.outputCanvas.width,
						this.outputCanvas.height
					);
					this.outputContext.fillStyle = white;
					this.outputContext.fillRect(
						0,
						0,
						this.outputCanvas.width,
						this.outputCanvas.height
					);
					for (let x = 1; x < this.outputCanvas.width - 1; x++) {
						for (let y = 1; y < this.outputCanvas.height - 1; y++) {
							if (
								this.isWhite(this.getPixel(imageData, x, y)) &&
								(this.isBlack(this.getPixel(imageData, x - 1, y)) ||
									this.isBlack(this.getPixel(imageData, x + 1, y)) ||
									this.isBlack(this.getPixel(imageData, x, y - 1)) ||
									this.isBlack(this.getPixel(imageData, x, y + 1)))
							) {
								this.edgePoints.push([x, y]);
								this.setPixel(this.outputContext, x, y, black);
							}
						}
					}
					this.isEdgesComputed = true;
					this.copyToPreview();
					this.isInProgress = false;
				}
			}, 0);
		},

		setEdgeDetectionType() {
			this.isEdgesComputed = false;
			this.isContourDrawn = false;
			this.edgeDetectionType = document.querySelector(
				"[name='edge-detection-type']:checked"
			).value;
			this.isShowCannyParams = this.edgeDetectionType == 'canny';
			if (this.isShowCannyParams) {
				setTimeout(this.initHysteresisRange, 0);
			}
		},

		setGaussianSigmaRange() {
			const value = parseInt(
				document.getElementById('gaussian-sigma-range').value
			);
			this.gaussianSigma = Math.pow(value / 50, 2);
		},

		setContourRadiusRange() {
			const value = parseInt(
				document.getElementById('contour-radius-range').value
			);
			this.contourRadius = value;
		},

		setImageFile() {
			this.isImageLoaded = false;
			this.isContrastComputed = false;
			this.isEdgesComputed = false;
			this.isContourDrawn = false;
			if (typeof window.FileReader !== 'function') {
				alert(
					'The browser you are using sucks.\nTry using Firefox or Chrome instead.'
				);
				return;
			}

			const input = document.getElementById('image-file-chooser');
			if (!input) {
				alert('Failed to find the image-file-chooser element... somehow.');
			} else if (!input.files) {
				alert(
					'The browser you are using sucks.\nTry using Firefox or Chrome instead.'
				);
			} else if (!input.files[0]) {
				alert("Please select a file before clicking 'Load'.");
			} else {
				this.isInProgress = true;
				this.previewContext.clearRect(
					0,
					0,
					this.previewCanvas.width,
					this.previewCanvas.height
				);
				const file = input.files[0];
				const fr = new FileReader();
				fr.onload = async () => {
					try {
						const image = await Image.load(fr.result);
						this.img.src = image.toDataURL();
					} catch (err) {
						this.isInProgress = false;
						console.error(err);
						alert("Well that failed.\n\nMaybe this file isn't an image?");
					}
				};
				fr.readAsDataURL(file);
			}
		},

		updateContrast() {
			this.isContrastComputed = false;
			this.isInProgress = true;
			setTimeout(() => {
				const contrast = parseInt(
					document.getElementById('contrast-range').value
				);
				const imageData = this.inputContext.getImageData(
					0,
					0,
					this.inputCanvas.width,
					this.inputCanvas.height
				);
				const contrastType = document.querySelector(
					"[name='contrast-type']:checked"
				).value;
				let cutoff = contrast / 100;
				if (contrastType == 'val') {
					cutoff *= 1 << 8;
				}
				//			console.log("cutoff ", cutoff);
				let offset = 0;
				for (let y = 0; y < imageData.height; y++) {
					//				setProgress(y / imageData.height);
					//				console.log("% done", (y / imageData.height) * 100);
					for (let x = 0; x < imageData.width; x++) {
						let value;
						if (contrastType == 'val') {
							// turns out value is just max of R, G, B
							value = Math.max(
								imageData.data[offset++],
								imageData.data[offset++],
								imageData.data[offset++]
							);
						} else {
							const color = {
								red: imageData.data[offset++],
								green: imageData.data[offset++],
								blue: imageData.data[offset++],
							};
							const hsv = this.rgb2hsv(color);
							if (contrastType == 'sat') {
								value = hsv[1];
							} else if (contrastType == 'hue') {
								value = hsv[0];
							}
							//						if (Math.random() < 0.02) {
							//							console.log("value ", value);
							//						}
						}

						this.setPixel(
							this.outputContext,
							x,
							y,
							value < cutoff ? black : white
						);

						//					// RGB
						//					//					const offset = ((y * (imageData.width * 4)) + (x * 4));
						//					const color = [
						//						imageData.data[offset++],
						//						imageData.data[offset++],
						//						imageData.data[offset++]
						//					];
						//					color.alpha = imageData.data[((y * (imageData.width * 4)) + (x * 4)) + 3];
						offset++;
					}
				}
				//			setProgress(1);

				this.copyToPreview();

				this.isContrastComputed = true;
				this.isInProgress = false;
				setTimeout(() => {
					document.querySelector(
						"input[name='edge-detection-type']"
					).checked = false;
					if (this.edgeDetectionType) {
						document.getElementById(
							'edge-detection-type-' + this.edgeDetectionType
						).checked = true;
					}
					this.initHysteresisRange();
				}, 0);
			}, 40);
		},

		rgb2hsv(color) {
			const r = color.red / 255;
			const g = color.green / 255;
			const b = color.blue / 255;
			const minRGB = Math.min(r, g, b);
			const maxRGB = Math.max(r, g, b);
			const computedV = maxRGB;

			// Black-gray-white
			if (minRGB == maxRGB) {
				return [0, 0, computedV];
			}

			// Colors other than black-gray-white:
			const d = r == minRGB ? g - b : b == minRGB ? r - g : b - r;
			const h = r == minRGB ? 3 : b == minRGB ? 1 : 5;
			const computedH = (h - d / (maxRGB - minRGB)) / 4;
			const computedS = (maxRGB - minRGB) / maxRGB;
			return [computedH, computedS, computedV];
		},

		getPixel(imageData, x, y) {
			let offset = 4 * (y * imageData.width + x);
			return {
				red: imageData.data[offset++],
				green: imageData.data[offset++],
				blue: imageData.data[offset++],
				//		alpha : imageData.data[offset],
			};
		},

		setPixel(context, x, y, color) {
			context.fillStyle = color;
			context.fillRect(x, y, 1, 1);
		},

		isBlack(pixel) {
			return !this.isWhite(pixel);
			//	return pixel.red == 0 && pixel.green == 0 && pixel.blue == 0;
		},

		isWhite(pixel) {
			return pixel.red == 255 && pixel.green == 255 && pixel.blue == 255;
		},

		// TODO
		initHysteresisRange() {
			// document.getElementById('hysteresis-threshold-range').slider({
			// 	range: true,
			// 	min: 0,
			// 	max: 100,
			// 	values: [hysteresisThresholds.low, hysteresisThresholds.high],
			// 	slide: function (event, ui) {
			// 		hysteresisThresholds.low = ui.values[0];
			// 		hysteresisThresholds.high = ui.values[1];
			// 		// TODO?
			// 		// $($('.ui-slider-handle').get(0)).html(hysteresisThresholds.low);
			// 		// $($('.ui-slider-handle').get(1)).html(hysteresisThresholds.high);
			// 	},
			// });
			// TODO?
			// $($('.ui-slider-handle').get(0)).html(hysteresisThresholds.low);
			// $($('.ui-slider-handle').get(1)).html(hysteresisThresholds.high);
		},

		repaint() {
			// const imageDimensions = {
			// 	width: this.previewCanvas.width,
			// 	height: (this.img.height * this.previewCanvas.width) / this.img.width,
			// };
			// this.previewContext.drawImage(
			// 	this.img,
			// 	0,
			// 	0,
			// 	imageDimensions.width,
			// 	imageDimensions.height
			// );
			this.previewCanvas.width = this.img.width;
			this.previewCanvas.height = this.img.height;
			this.inputCanvas.width = this.img.width;
			this.inputCanvas.height = this.img.height;
			this.outputCanvas.width = this.img.width;
			this.outputCanvas.height = this.img.height;

			this.previewContext.drawImage(
				this.img,
				0,
				0,
				this.previewCanvas.width,
				this.previewCanvas.height
			);

			this.inputContext.drawImage(
				this.img,
				0,
				0,
				this.img.width,
				this.img.height
			);
		},

		copyToPreview() {
			this.previewContext.drawImage(
				this.outputCanvas,
				0,
				0,
				this.outputCanvas.width,
				this.outputCanvas.height,
				0,
				0,
				this.previewCanvas.width,
				(this.img.height * this.previewCanvas.width) / this.img.width
			);
		},
	},

	computed: {},

	// created() {
	// 	console.log('cannyEdgeDetector', cannyEdgeDetector);
	// 	console.log('Image', Image);
	// },

	mounted() {
		console.log('mounted');
		this.img = document.getElementById('input-image');
		this.edgeImg = document.getElementById('edge-image');
		this.inputCanvas = document.getElementById('input-canvas');
		this.previewCanvas = document.getElementById('preview-canvas');
		this.outputCanvas = document.getElementById('output-canvas');
		this.previewContext = this.previewCanvas.getContext('2d');
		this.inputContext = this.inputCanvas.getContext('2d');
		this.outputContext = this.outputCanvas.getContext('2d');
		function f(c) {
			const width = parseInt(
				window.getComputedStyle(document.getElementById('controls')).width
			);
			c.setAttribute('width', innerWidth - width - 60);
			c.setAttribute('height', innerHeight - 40);
		}
		f(this.inputCanvas);
		f(this.previewCanvas);

		window.addEventListener('resize', () => {
			f(this.inputCanvas);
			f(this.previewCanvas);
		});

		// document
		// 	.getElementById('gaussian-sigma-range')
		// 	.val(50 * Math.sqrt(gaussianSigmaDefault));

		this.img.onload = () => {
			this.repaint();
			//						alert(previewCanvas.toDataURL("image/png"));
			this.isImageLoaded = true;
			this.isInProgress = false;
		};

		this.edgeImg.onload = () => {
			this.outputContext.fillStyle = white;
			this.outputContext.fillRect(
				0,
				0,
				this.outputCanvas.width,
				this.outputCanvas.height
			);
			this.outputContext.drawImage(
				this.edgeImg,
				0,
				0,
				this.outputCanvas.width,
				this.outputCanvas.height
			);

			const imageData = this.outputContext.getImageData(
				0,
				0,
				this.outputCanvas.width,
				this.outputCanvas.height
			);
			for (let x = 1; x < this.outputCanvas.width - 1; x++) {
				for (let y = 1; y < this.outputCanvas.height - 1; y++) {
					if (this.isWhite(this.getPixel(imageData, x, y))) {
						this.setPixel(this.outputContext, x, y, black);
						this.edgePoints.push([x, y]);
					} else {
						this.setPixel(this.previewContext, x, y, white);
					}
				}
			}
			this.isEdgesComputed = true;
			this.copyToPreview();

			this.isInProgress = false;
		};
	},
};
</script>

<style>
/* 
#app {
	font-family: Avenir, Helvetica, Arial, sans-serif;
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
	text-align: center;
	color: #2c3e50;
	margin-top: 60px;
} */

#main {
	font-family: Arial, Helvetica, sans-serif;
}

#controls {
	text-align: center;
	width: 300px;
	display: inline-block;
	vertical-align: top;
	margin-right: 12px;
	width: 300px;
}

.button {
	background-color: orange;
	border-radius: 6px;
	padding: 4px;
	margin: 12px;
	min-width: 100px;
	max-width: 140px;
	text-align: center;
	font-weight: bold;
	cursor: pointer;
	border-width: 2px;
	border-color: #ddd;
	border-style: solid;
	display: inline-block;
}

.button:hover {
	background-color: #0059dd;
	color: white;
}

#main {
	width: 100%;
}

#output {
	display: inline-block;
}

#preview-canvas {
	background-color: #eee;
	border-radius: 6px;
}

#input-canvas {
	display: none;
}

#output-canvas {
	display: none;
}

/* #file-chooser-container { */
/* 	padding-bottom: 16px; */
/* } */
#file-chooser-label [type='file'] {
	cursor: pointer;
	display: block;
	filter: alpha(opacity = 0);
	min-width: 100%;
	opacity: 0;
	position: absolute;
	right: 0;
	top: 0;
}

#spinner {
	display: none;
	text-align: center;
	width: 100%;
	margin-top: 18px;
}

.control-section {
	margin-top: 12px;
	border-radius: 8px;
	border-width: 2px;
	border-color: #222;
	border-style: solid;
	padding-top: 6px;
	padding-bottom: 6px;
	background-color: #eee;
	line-height: 1.6em;
}

.hidden {
	display: none;
}

#hysteresis-threshold-range {
	width: 85%;
	margin-left: auto;
	margin-right: auto;
	margin-top: 8px;
	background: orange;
	height: 8px;
}

#canny-params div {
	margin-bottom: 12px;
}

.ui-widget-header {
	background: #888 !important;
}

.ui-slider-handle {
	background: white !important;
	border-color: black !important;
	color: black !important;
	top: -8px !important;
	padding-bottom: 4px !important;
}

/* #hysteresis-threshold-range-container { */
/* } */

/* #progress-container { */
/* 	width: 100%; */
/* 	background-color: #aaa; */
/* 	height: 16px; */
/* 	margin-top: 4px; */
/* 	border-width: 2px; */
/* 	border-radius: 4px; */
/* 	border-style: solid; */
/* 	border-color: #ddd; */
/* } */

/* #progress { */
/* 	background-color: orange; */
/* 	height: 16px; */
/* } */

/* #slider-container { */
/* 	margin-top: 12px; */
/* } */

/*  slider styling follows */
input[type='range'] {
	-webkit-appearance: none;
	width: 65%;
	margin-left: 12px;
	background: transparent;
}

input[type='range']::-webkit-slider-thumb {
	-webkit-appearance: none;
}

input[type='range']:focus {
	outline: none;
}

input[type='range']::-ms-track {
	width: 100%;
	cursor: pointer;
	background: transparent;
	border-color: transparent;
	color: transparent;
}

input[type='range']::-webkit-slider-thumb {
	-webkit-appearance: none;
	border: 1px solid black;
	height: 18px;
	width: 8px;
	border-radius: 3px;
	background: white;
	cursor: pointer;
	margin-top: -6px;
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
}

input[type='range']::-moz-range-thumb {
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
	border: 1px solid black;
	height: 36px;
	width: 16px;
	border-radius: 3px;
	background: white;
	cursor: pointer;
}

input[type='range']::-ms-thumb {
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
	border: 1px solid black;
	height: 18px;
	width: 8px;
	border-radius: 3px;
	background: white;
	cursor: pointer;
}

input[type='range']::-webkit-slider-runnable-track {
	width: 100%;
	height: 8.4px;
	cursor: pointer;
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
	background: orange;
	border-radius: 1.3px;
	border: 0.2px solid #010101;
}

input[type='range']:focus::-webkit-slider-runnable-track {
	background: orange;
}

input[type='range']::-moz-range-track {
	width: 100%;
	height: 8.4px;
	cursor: pointer;
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
	background: orange;
	border-radius: 1.3px;
	border: 0.2px solid #010101;
}

input[type='range']::-ms-track {
	width: 100%;
	height: 8.4px;
	cursor: pointer;
	background: transparent;
	border-color: transparent;
	border-width: 16px 0;
	color: transparent;
}

input[type='range']::-ms-fill-lower {
	background: orange;
	border: 0.2px solid #010101;
	border-radius: 2.6px;
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
}

input[type='range']:focus::-ms-fill-lower {
	background: orange;
}

input[type='range']::-ms-fill-upper {
	background: orange;
	border: 0.2px solid #010101;
	border-radius: 2.6px;
	box-shadow: 1px 1px 1px black, 0px 0px 1px #0d0d0d;
}

input[type='range']:focus::-ms-fill-upper {
	background: orange;
}
</style>
