<template>
	<div>Doodler</div>
</template>

<script>
import cannyEdgeDetector from 'canny-edge-detector';
import Image from 'image-js';

// const gaussianSigmaDefault = 1.1;
// const black = '#000000';
// const white = '#ffffff';

// const hysteresisThresholds = {
// 	low: 10,
// 	high: 30,
// };

export default {
	name: 'App',

	created() {
		console.log('cannyEdgeDetector', cannyEdgeDetector);
		console.log('Image', Image);
	},
};
</script>

<style>
#app {
	font-family: Avenir, Helvetica, Arial, sans-serif;
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
	text-align: center;
	color: #2c3e50;
	margin-top: 60px;
}
</style>
