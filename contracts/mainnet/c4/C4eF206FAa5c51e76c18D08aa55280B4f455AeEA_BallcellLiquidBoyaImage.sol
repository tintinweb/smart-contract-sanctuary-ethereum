// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "@openzeppelin/contracts/utils/Strings.sol";
import "../common/BallcellLiquidBoyaParameters.sol";
import "./BallcellLiquidBoyaImageScript.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

contract BallcellLiquidBoyaImage {
	uint256 private _passcode = 0;

	function settingPasscode(uint256 value) public {
		require(_passcode == 0, "already set");
		_passcode = value;
	}

	function svg(BallcellLiquidBoyaParameters.Parameters memory parameters) external view returns (bytes memory) {
		require(parameters.passcode == _passcode, "passcode error");
		return _svgMain(parameters);
	}

	function _fixedInt(int256 valueInteger) private pure returns (int256) {
		return valueInteger << 64;
	}

	function _fixedFloat(int256 numeratorInteger, int256 denominatorInteger) private pure returns (int256) {
		return (numeratorInteger << 64) / denominatorInteger;
	}

	function _fixedMul(int256 value1Fixed, int256 value2Fixed) private pure returns (int256) {
		return (value1Fixed * value2Fixed) >> 64;
	}

	function _fixedMulMul(int256 value1Fixed, int256 value2Fixed, int256 value3Fixed) private pure returns (int256) {
		return (((value1Fixed * value2Fixed) >> 64) * value3Fixed) >> 64;
	}

	function _fixedDiv(int256 value1Fixed, int256 value2Fixed) private pure returns (int256) {
		return (value1Fixed << 64) / value2Fixed;
	}

	function _fixedString(int256 valueFixed) private pure returns (string memory) {
		if (valueFixed < 0) { return string(abi.encodePacked("-", Strings.toString(uint256(-valueFixed >> 64)))); }
		return Strings.toString(uint256(valueFixed >> 64));
	}

	function _mathDegreesSin(int256 degreesFixed) private pure returns (int256) {
		// 度数法から弧度法に変換する
		int256 piFixed =  _fixedFloat(314159265, 100000000);
		int256 radianFixed = _fixedMul(degreesFixed, piFixed) / 180;
		// 原点を中心とした1周分に範囲を変換する
		int256 radianRangeFixed = (radianFixed % (2 * piFixed) + (3 * piFixed)) % (2 * piFixed) - piFixed;
		int256 radianRangeSquaredFixed = _fixedMul(radianRangeFixed, radianRangeFixed);
		// テイラー展開を用いて正弦関数を解く
		int256 valFixed = radianRangeFixed;
		int256 sumFixed = valFixed;
		for (uint i = 1; i < 10; i++) {
			valFixed = _fixedMul(valFixed, - radianRangeSquaredFixed / int256((2 * i) * (2 * i + 1)));
			sumFixed = sumFixed + valFixed;
		}
		return sumFixed;
	}

	function _mathDegreesCos(int256 degreesFixed) private pure returns (int256) {
		// 三角関数の変換公式を用いて正弦関数の結果から余弦関数を解く
		return _mathDegreesSin(_fixedInt(90) - degreesFixed);
		// // 度数法から弧度法に変換する
		// int256 piFixed =  _fixedFloat(314159265, 100000000);
		// int256 radianFixed = _fixedMul(degreesFixed, piFixed) / 180;
		// // 原点を中心とした1周分に範囲を変換する
		// int256 radianRangeFixed = (radianFixed % (2 * piFixed) + (3 * piFixed)) % (2 * piFixed) - piFixed;
		// int256 radianRangeSquaredFixed = _fixedMul(radianRangeFixed, radianRangeFixed);
		// // テイラー展開を用いて余弦関数を解く
		// int256 valFixed = _fixedInt(1);
		// int256 sumFixed = valFixed;
		// for (uint i = 1; i < 10; i++) {
		// 	valFixed = _fixedMul(valFixed, - radianRangeSquaredFixed / int256((2 * i - 1) * (2 * i)));
		// 	sumFixed = sumFixed + valFixed;
		// }
		// return sumFixed;
	}

	function _matCopy(int256[16] memory a, int256[16] memory b) private pure {
		for (uint i = 0; i < 16; i++) {
			a[i] = b[i];
		}
	}

	function _matIdentity(int256[16] memory a) private pure {
		for (uint i = 0; i < 16; i++) { a[i] = 0; }
		a[0] = _fixedInt(1);
		a[5] = _fixedInt(1);
		a[10] = _fixedInt(1);
		a[15] = _fixedInt(1);
		// a[0] = _fixedInt(1);
		// a[1] = 0;
		// a[2] = 0;
		// a[3] = 0;
		// a[4] = 0;
		// a[5] = _fixedInt(1);
		// a[6] = 0;
		// a[7] = 0;
		// a[8] = 0;
		// a[9] = 0;
		// a[10] = _fixedInt(1);
		// a[11] = 0;
		// a[12] = 0;
		// a[13] = 0;
		// a[14] = 0;
		// a[15] = _fixedInt(1);
	}

	function _matFrustum(int256[16] memory a) private pure {
		for (uint i = 0; i < 16; i++) { a[i] = 0; }
		a[0] = _fixedInt(1);
		a[5] = _fixedInt(-1);
		a[10] = _fixedFloat(-12, 10);
		a[11] = _fixedInt(-1);
		a[14] = _fixedFloat(-22, 10);
		// a[0] = _fixedInt(1);
		// a[1] = 0;
		// a[2] = 0;
		// a[3] = 0;
		// a[4] = 0;
		// a[5] = _fixedInt(-1);
		// a[6] = 0;
		// a[7] = 0;
		// a[8] = 0;
		// a[9] = 0;
		// a[10] = _fixedFloat(-12, 10);
		// a[11] = _fixedInt(-1);
		// a[12] = 0;
		// a[13] = 0;
		// a[14] = _fixedFloat(-22, 10);
		// a[15] = 0;
	}

	function _matMulTranslate(int256[16] memory a, int256 x, int256 y, int256 z) private pure {
		a[12] = _fixedMul(a[0], x) + _fixedMul(a[4], y) + _fixedMul(a[8], z) + a[12];
		a[13] = _fixedMul(a[1], x) + _fixedMul(a[5], y) + _fixedMul(a[9], z) + a[13];
		a[14] = _fixedMul(a[2], x) + _fixedMul(a[6], y) + _fixedMul(a[10], z) + a[14];
		a[15] = _fixedMul(a[3], x) + _fixedMul(a[7], y) + _fixedMul(a[11], z) + a[15];
	}

	function _matMulDegreesRotBase(int256[16] memory a, int256 r, uint8[8] memory indexes) private pure {
		int256 c = _mathDegreesCos(r);
		int256 s = _mathDegreesSin(r);
		int256[8] memory b;
		for (uint i = 0; i < 8; i++) { b[i] = a[indexes[i]]; }
		for (uint i = 0; i < 4; i++) {
			a[indexes[i + 0]] = _fixedMul(s, b[i + 4]) + _fixedMul(c, b[i + 0]);
			a[indexes[i + 4]] = _fixedMul(c, b[i + 4]) - _fixedMul(s, b[i + 0]);
		}
	}

	function _matMulDegreesRotX(int256[16] memory a, int256 r) private pure {
		uint8[8] memory indexes = [4, 5, 6, 7, 8, 9, 10, 11];
		_matMulDegreesRotBase(a, r, indexes);
		// int256 c = _mathDegreesCos(r);
		// int256 s = _mathDegreesSin(r);
		// int256 a4 = a[4];
		// int256 a5 = a[5];
		// int256 a6 = a[6];
		// int256 a7 = a[7];
		// int256 a8 = a[8];
		// int256 a9 = a[9];
		// int256 a10 = a[10];
		// int256 a11 = a[11];
		// a[4] = _fixedMul(s, a8) + _fixedMul(c, a4);
		// a[5] = _fixedMul(s, a9) + _fixedMul(c, a5);
		// a[6] = _fixedMul(s, a10) + _fixedMul(c, a6);
		// a[7] = _fixedMul(s, a11) + _fixedMul(c, a7);
		// a[8] = _fixedMul(c, a8) - _fixedMul(s, a4);
		// a[9] = _fixedMul(c, a9) - _fixedMul(s, a5);
		// a[10] = _fixedMul(c, a10) - _fixedMul(s, a6);
		// a[11] = _fixedMul(c, a11) - _fixedMul(s, a7);
	}

	function _matMulDegreesRotY(int256[16] memory a, int256 r) private pure {
		uint8[8] memory indexes = [8, 9, 10, 11, 0, 1, 2, 3];
		_matMulDegreesRotBase(a, r, indexes);
		// int256 c = _mathDegreesCos(r);
		// int256 s = _mathDegreesSin(r);
		// int256 a8 = a[8];
		// int256 a9 = a[9];
		// int256 a10 = a[10];
		// int256 a11 = a[11];
		// int256 a0 = a[0];
		// int256 a1 = a[1];
		// int256 a2 = a[2];
		// int256 a3 = a[3];
		// a[8] = _fixedMul(s, a0) + _fixedMul(c, a8);
		// a[9] = _fixedMul(s, a1) + _fixedMul(c, a9);
		// a[10] = _fixedMul(s, a2) + _fixedMul(c, a10);
		// a[11] = _fixedMul(s, a3) + _fixedMul(c, a11);
		// a[0] = _fixedMul(c, a0) - _fixedMul(s, a8);
		// a[1] = _fixedMul(c, a1) - _fixedMul(s, a9);
		// a[2] = _fixedMul(c, a2) - _fixedMul(s, a10);
		// a[3] = _fixedMul(c, a3) - _fixedMul(s, a11);
	}

	function _matMulDegreesRotZ(int256[16] memory a, int256 r) private pure {
		uint8[8] memory indexes = [0, 1, 2, 3, 4, 5, 6, 7];
		_matMulDegreesRotBase(a, r, indexes);
		// int256 c = _mathDegreesCos(r);
		// int256 s = _mathDegreesSin(r);
		// int256 a0 = a[0];
		// int256 a1 = a[1];
		// int256 a2 = a[2];
		// int256 a3 = a[3];
		// int256 a4 = a[4];
		// int256 a5 = a[5];
		// int256 a6 = a[6];
		// int256 a7 = a[7];
		// a[0] = _fixedMul(s, a4) + _fixedMul(c, a0);
		// a[1] = _fixedMul(s, a5) + _fixedMul(c, a1);
		// a[2] = _fixedMul(s, a6) + _fixedMul(c, a2);
		// a[3] = _fixedMul(s, a7) + _fixedMul(c, a3);
		// a[4] = _fixedMul(c, a4) - _fixedMul(s, a0);
		// a[5] = _fixedMul(c, a5) - _fixedMul(s, a1);
		// a[6] = _fixedMul(c, a6) - _fixedMul(s, a2);
		// a[7] = _fixedMul(c, a7) - _fixedMul(s, a3);
	}

	struct Variables {
		uint n1;
		uint n2;
		uint n3;
		int256 r0Fixed;
		int256 r1Fixed;
		int256 r2Fixed;
		int256 r3Fixed;
		string[9] color;
		int256 rotFixed;
		int256 angFixed;
		int256 distFixed;
		int256 swingFixed;
		int256 thetaFixed;
		int256 updownFixed;
		int256[16] matrix0;
		int256[16] matrix1;
		int256[16] matrix2;
		int256[16] matrix3;
	}

	function _svgMain(BallcellLiquidBoyaParameters.Parameters memory parameters) private pure returns (bytes memory) {
		Variables memory variables;
		variables.n1 = 5;
		variables.n2 = 8;
		variables.n3 = 8;
		variables.r0Fixed = _fixedFloat(int256(parameters.radiusBody), 10);
		variables.r1Fixed = _fixedFloat(int256(parameters.radiusFoot), 10);
		variables.r2Fixed = _fixedFloat(int256(parameters.radiusHand), 10);
		variables.r3Fixed = _fixedFloat(int256(parameters.radiusHead), 10);
		variables.color[0] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueBody), ", 100%, ", Strings.toString(parameters.colorLightnessBody), "%)"));
		variables.color[1] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueRFoot), ", 100%, ", Strings.toString(parameters.colorLightnessBody), "%)"));
		variables.color[2] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueLFoot), ", 100%, ", Strings.toString(parameters.colorLightnessBody), "%)"));
		variables.color[3] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueRHand), ", 100%, ", Strings.toString(parameters.colorLightnessBody), "%)"));
		variables.color[4] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueLHand), ", 100%, ", Strings.toString(parameters.colorLightnessBody), "%)"));
		variables.color[5] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueHead), ", 100%, ", Strings.toString(parameters.colorLightnessBody), "%)"));
		variables.color[6] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueREye), ", 100%, ", Strings.toString(parameters.colorLightnessEye), "%)"));
		variables.color[7] = string(abi.encodePacked("hsl(", Strings.toString(parameters.colorHueLEye), ", 100%, ", Strings.toString(parameters.colorLightnessEye), "%)"));
		variables.color[8] = "black";
		int256[5][] memory balls = new int256[5][](variables.n1 + variables.n2 + variables.n3 * 2);

		variables.rotFixed = _fixedInt(int256(parameters.rotation) + 120);
		variables.angFixed = _fixedInt(int256(parameters.angle) - 45);
		variables.distFixed = _fixedInt(int256(parameters.distance) * 2 + 4);
		variables.swingFixed = _mathDegreesSin(9 * _fixedInt(int256(parameters.swing)));
		variables.thetaFixed = 30 * variables.swingFixed;
		variables.updownFixed = _fixedMul(_fixedFloat(3, 10), variables.swingFixed < 0 ? -variables.swingFixed : variables.swingFixed);

		// 胴体
		_matIdentity(variables.matrix0);
		balls[0][0] = 0;
		balls[0][1] = 0;
		balls[0][2] = 0;
		balls[0][3] = variables.r0Fixed;
		balls[0][4] = 0;

		// 両足
		for (uint i = 0; i < 2; i++) {
			uint index = 1 + i;
			int256 sign = (i == 0 ? int256(1) : int256(-1));
			_matCopy(variables.matrix1, variables.matrix0);
			_matMulDegreesRotZ(variables.matrix1, _fixedInt(30) * sign);
			_matMulDegreesRotX(variables.matrix1, -variables.thetaFixed  * sign);
			_matMulTranslate(variables.matrix1, 0, -(variables.r0Fixed + variables.r1Fixed * 7 / 10), 0);
			balls[index][0] = variables.matrix1[12];
			balls[index][1] = variables.matrix1[13];
			balls[index][2] = variables.matrix1[14];
			balls[index][3] = variables.r1Fixed;
			balls[index][4] = int256(index);
		}

		// 両手
		for (uint i = 0; i < 2; i++) {
			uint index = 3 + i;
			int256 sign = (i == 0 ? int256(1) : int256(-1));
			_matCopy(variables.matrix1, variables.matrix0);
			_matMulDegreesRotY(variables.matrix1, variables.thetaFixed);
			_matMulTranslate(variables.matrix1, (variables.r0Fixed + variables.r2Fixed * 5 / 10) * sign, 0, 0);
			balls[index][0] = variables.matrix1[12];
			balls[index][1] = variables.matrix1[13];
			balls[index][2] = variables.matrix1[14];
			balls[index][3] = variables.r2Fixed;
			balls[index][4] = int256(index);
		}

		// 頭
		_matCopy(variables.matrix1, variables.matrix0);
		_matMulDegreesRotX(variables.matrix1, _fixedInt(-30));
		_matMulTranslate(variables.matrix1, 0, (variables.r0Fixed + variables.r3Fixed * 7 / 10), 0);
		_matMulDegreesRotX(variables.matrix1, _fixedInt(30));
		_matCopy(variables.matrix2, variables.matrix1);
		_matMulDegreesRotX(variables.matrix2, _fixedInt(150));
		for (uint i = 0; i < variables.n2; i++) {
			uint index = variables.n1 + i;
			int256 numerator = int256(i);
			int256 denominator = int256(variables.n2 - 1);
			int256 t = _fixedFloat(numerator, denominator);
			int256 r = variables.r3Fixed;
			_matCopy(variables.matrix3, variables.matrix2);
			_matMulTranslate(variables.matrix3, 0, 0, _fixedMulMul(_fixedFloat(-1333, 1000), r, t));
			balls[index][0] = variables.matrix3[12];
			balls[index][1] = variables.matrix3[13];
			balls[index][2] = variables.matrix3[14];
			balls[index][3] = _fixedMul(variables.r3Fixed, (_fixedInt(3) - 2 * t) / 3);
			balls[index][4] = 5;
		}

		// 両目
		for (uint i = 0; i < 2; i++) {
			int256 sign = (i == 0 ? int256(1) : int256(-1));
			_matCopy(variables.matrix2, variables.matrix1);
			_matMulDegreesRotY(variables.matrix2, _fixedInt(-15) * sign);
			_matMulTranslate(variables.matrix2, 0, 0, variables.r3Fixed * - 8 / 10);
			for (uint j = 0; j < variables.n3; j++) {
				uint index = variables.n1 + variables.n2 + variables.n3 * i + j;
				int256 numerator = int256(j);
				int256 denominator = int256(variables.n3 - 1);
				int256 t = _fixedFloat(numerator, denominator) - _fixedFloat(5, 10);
				_matCopy(variables.matrix3, variables.matrix2);
				_matMulTranslate(variables.matrix3, 0, _fixedMulMul(variables.r3Fixed, _fixedFloat(6, 10), t), 0);
				balls[index][0] = variables.matrix3[12];
				balls[index][1] = variables.matrix3[13];
				balls[index][2] = variables.matrix3[14];
				balls[index][3] = variables.r3Fixed / 6;
				balls[index][4] = 6 + int256(i);
			}
		}

		// 高さ調整
		int256 offsetFixed = 0;
		for (uint i = 0; i < balls.length; i++) {
			int256 value = balls[i][1] - balls[i][3];
			if (offsetFixed > value) { offsetFixed = value; }
		}
		for (uint i = 0; i < balls.length; i++) { balls[i][1] = balls[i][1] + variables.updownFixed - offsetFixed; }

		// 位置計算
		_matFrustum(variables.matrix0);
		_matMulTranslate(variables.matrix0, 0, 0, -variables.distFixed);
		_matMulDegreesRotX(variables.matrix0, variables.angFixed);
		_matMulDegreesRotY(variables.matrix0, variables.rotFixed);
		_matMulTranslate(variables.matrix0, 0, _fixedFloat(-14, 10), 0);
		for (uint i = 0; i < balls.length; i++) {
			_matCopy(variables.matrix1, variables.matrix0);
			_matMulTranslate(variables.matrix1, balls[i][0], balls[i][1], balls[i][2]);
			balls[i][0] = _fixedDiv(variables.matrix1[12], variables.matrix1[15]);
			balls[i][1] = _fixedDiv(variables.matrix1[13], variables.matrix1[15]);
			balls[i][2] = _fixedDiv(variables.matrix1[14], variables.matrix1[15]);
			balls[i][3] = _fixedDiv(balls[i][3], variables.matrix1[15]);
		}

		// バブルソートで並べ替え
		uint[] memory sortedIndexes = new uint[](balls.length);
		for (uint i = 0; i < sortedIndexes.length; i++) { sortedIndexes[i] = i; }
		for (uint i = 0; i < sortedIndexes.length; i++) {
			for (uint j = 0; j < sortedIndexes.length - i - 1; j++) {
				uint temp0 = sortedIndexes[j + 0];
				uint temp1 = sortedIndexes[j + 1];
				int256 z0 = balls[temp0][2];
				int256 z1 = balls[temp1][2];
				if (z1 > z0) {
					sortedIndexes[j + 0] = temp1;
					sortedIndexes[j + 1] = temp0;
				}
			}
		}

		// svg作成
		bytes memory temporary = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 350 350">';
		temporary = abi.encodePacked(temporary, _svgBackground(parameters));
		temporary = abi.encodePacked(temporary, '<g id="balls">');
		for (uint i = 0; i < 2; i++) {
			for (uint j = 0; j < sortedIndexes.length; j++) {
				int256 x = (2 * balls[sortedIndexes[j]][0] + _fixedFloat(5, 10)) * 350;
				int256 y = (2 * balls[sortedIndexes[j]][1] + _fixedFloat(5, 10)) * 350;
				int256 r = (2 * balls[sortedIndexes[j]][3] * 350) + _fixedInt(i == 0 ? int256(16) : int256(0));
				uint color = i == 0 ? 8 : uint(balls[sortedIndexes[j]][4]);
				temporary = abi.encodePacked(temporary,
					"<circle",
					' cx="', _fixedString(x), '"',
					' cy="', _fixedString(y), '"',
					' r="', _fixedString(r), '"',
					' fill="', variables.color[color], '"',
					"></circle>"
				);
			}
		}
		temporary = abi.encodePacked(temporary, "</g>");
		temporary = abi.encodePacked(temporary, _svgForeground(parameters));
		temporary = abi.encodePacked(temporary, _svgScript(parameters));
		return abi.encodePacked(temporary, "</svg>");
	}

	function _svgBackground(BallcellLiquidBoyaParameters.Parameters memory parameters) private pure returns (bytes memory) {
		string memory color = string(abi.encodePacked("hsl(", Strings.toString(parameters.backgroundColor), ", 100%, 50%)"));
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.Single) {
			return abi.encodePacked('<rect x="25" y="25" width="300" height="300" fill="', color, '"></rect>');
		} else if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.Circle) {
			string memory width = Strings.toString(160 + parameters.backgroundRandom % 50);
			bytes memory temporary = '<defs><mask id="mask">';
			temporary = abi.encodePacked(temporary, '<circle cx="175" cy="175" r="', width, '" fill="white"></circle>');
			temporary = abi.encodePacked(temporary, '<circle cx="175" cy="175" r="150" fill="black"></circle>');
			temporary = abi.encodePacked(temporary, "</mask></defs>");
			return abi.encodePacked(temporary, '<rect x="25" y="25" width="300" height="300" fill="', color, '" mask="url(#mask)" />');
		} else if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.PolkaDot) {
			uint typePolkaDot = parameters.backgroundRandom % 3;
			uint8[4] memory radius;
			if (typePolkaDot == 0) { radius = [20, 20, 20, 20]; }
			if (typePolkaDot == 1) { radius = [30, 10, 10, 20]; }
			if (typePolkaDot == 2) { radius = [40, 5, 5, 20]; }
			bytes memory temporary = '<defs><mask id="mask">';
			temporary = abi.encodePacked(temporary, '<rect x="25" y="25" width="300" height="300" fill="white" />');
			temporary = abi.encodePacked(temporary, "</mask></defs>");
			temporary = abi.encodePacked(temporary, '<g mask="url(#mask)">');
			for (uint i = 0; i < 5; i++) {
				for (uint j = 0; j < 5; j++) {
					uint index = (j % 2) + ((i % 2) << 1);
					string memory x = Strings.toString(25 + 75 * j);
					string memory y = Strings.toString(25 + 75 * i);
					string memory r = Strings.toString(radius[index]);
					temporary = abi.encodePacked(temporary, '<circle cx="', x, '" cy="', y, '" r="', r, '" fill="', color, '"></circle>');
				}
			}
			return abi.encodePacked(temporary, "</g>");
		}
		return "";
	}

	function _svgForeground(BallcellLiquidBoyaParameters.Parameters memory parameters) private pure returns (bytes memory) {
		if (parameters.revealed) { return ""; }
		bytes memory temporary = '<text';
		temporary = abi.encodePacked(temporary, ' x="175"');
		temporary = abi.encodePacked(temporary, ' y="175"');
		temporary = abi.encodePacked(temporary, ' fill="black"');
		temporary = abi.encodePacked(temporary, ' stroke="white"');
		temporary = abi.encodePacked(temporary, ' text-anchor="middle"');
		temporary = abi.encodePacked(temporary, ' dominant-baseline="central"');
		temporary = abi.encodePacked(temporary, ' font-size="128"');
		return abi.encodePacked(temporary, ">?</text>");
	}

	function _svgScript(BallcellLiquidBoyaParameters.Parameters memory parameters) private pure returns (bytes memory) {
		if (!parameters.revealed) { return ""; }
		uint16[18] memory array = BallcellLiquidBoyaParameters.createArray(parameters);
		bytes memory temporary = "<script><![CDATA[";
		temporary = abi.encodePacked(temporary, BallcellLiquidBoyaImageScript.code);
		temporary = abi.encodePacked(temporary, "window.setTimeout(() => startPuppet(");
		temporary = abi.encodePacked(temporary, 'document.getElementById("balls").getElementsByTagName("circle")');
		temporary = abi.encodePacked(temporary, ",[");
		for (uint i = 0; i < array.length; i++) { temporary = abi.encodePacked(temporary, Strings.toString(array[i]), ","); }
		temporary = abi.encodePacked(temporary, "]), 1000);");
		return abi.encodePacked(temporary, "]]></script>");
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaParameters {
	struct Parameters {
		bool revealed;
		uint256 tokenId;
		uint256 passcode;

		uint256 rotation;
		uint256 angle;
		uint256 distance;
		uint256 swing;
		uint256 radiusBody;
		uint256 radiusFoot;
		uint256 radiusHand;
		uint256 radiusHead;

		uint256 colorHueBody;
		uint256 colorHueRFoot;
		uint256 colorHueLFoot;
		uint256 colorHueRHand;
		uint256 colorHueLHand;
		uint256 colorHueHead;
		uint256 colorHueREye;
		uint256 colorHueLEye;
		uint256 colorLightnessBody;
		uint256 colorLightnessEye;

		bool colorFlagOne;
		ColorTypeBody colorTypeBody;
		ColorTypeEye colorTypeEye;

		BackgroundType backgroundType;
		uint256 backgroundColor;
		uint256 backgroundRandom;
	}

	enum ColorTypeBody { Neutral, Bright, Dark }
	enum ColorTypeEye { Monotone, Single, Double }
	enum BackgroundType { None, Single, Circle, PolkaDot, GradationLinear, Lgbt }

	uint constant _keyRotation = 0;
	uint constant _keyAngle = 1;
	uint constant _keyDistance = 2;
	uint constant _keySwing = 3;
	uint constant _keyRadiusBody = 4;
	uint constant _keyRadiusFoot = 5;
	uint constant _keyRadiusHand = 6;
	uint constant _keyRadiusHead = 7;
	uint constant _keyColorHueBody = 8;
	uint constant _keyColorHueRFoot = 9;
	uint constant _keyColorHueLFoot = 10;
	uint constant _keyColorHueRHand = 11;
	uint constant _keyColorHueLHand = 12;
	uint constant _keyColorHueHead = 13;
	uint constant _keyColorHueREye = 14;
	uint constant _keyColorHueLEye = 15;
	uint constant _keyColorLightnessBody = 16;
	uint constant _keyColorLightnessEye = 17;
	function createArray(Parameters memory parameters) internal pure returns (uint16[18] memory) {
		uint16[18] memory array;
		array[_keyRotation] = uint16(parameters.rotation);
		array[_keyAngle] = uint16(parameters.angle);
		array[_keyDistance] = uint16(parameters.distance);
		array[_keySwing] = uint16(parameters.swing);
		array[_keyRadiusBody] = uint16(parameters.radiusBody);
		array[_keyRadiusFoot] = uint16(parameters.radiusFoot);
		array[_keyRadiusHand] = uint16(parameters.radiusHand);
		array[_keyRadiusHead] = uint16(parameters.radiusHead);
		array[_keyColorHueBody] = uint16(parameters.colorHueBody);
		array[_keyColorHueRFoot] = uint16(parameters.colorHueRFoot);
		array[_keyColorHueLFoot] = uint16(parameters.colorHueLFoot);
		array[_keyColorHueRHand] = uint16(parameters.colorHueRHand);
		array[_keyColorHueLHand] = uint16(parameters.colorHueLHand);
		array[_keyColorHueHead] = uint16(parameters.colorHueHead);
		array[_keyColorHueREye] = uint16(parameters.colorHueREye);
		array[_keyColorHueLEye] = uint16(parameters.colorHueLEye);
		array[_keyColorLightnessBody] = uint16(parameters.colorLightnessBody);
		array[_keyColorLightnessEye] = uint16(parameters.colorLightnessEye);
		return array;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaImageScript {
	string constant code = '"use strict";window.startPuppet=(()=>{let t=(t,e)=>e.forEach(((e,l)=>t[l]=e)),e=(t,e,l,r)=>Array(4).fill(0).map(((o,h)=>t[12+h]=t[0+h]*e+t[4+h]*l+t[8+h]*r+t[12+h])),l=(t,e)=>h(t,e,[4,5,6,7,8,9,10,11]),r=(t,e)=>h(t,e,[8,9,10,11,0,1,2,3]),o=(t,e)=>h(t,e,[0,1,2,3,4,5,6,7]),h=(t,e,l)=>{let r=Math.cos(e*Math.PI/180),o=Math.sin(e*Math.PI/180),h=l.map((e=>t[e]));for(let e=0;e<4;e++)t[l[e+0]]=o*h[e+4]+r*h[e+0],t[l[e+4]]=r*h[e+4]-o*h[e+0]};const a=16;return(h,s)=>{const f=(t,e)=>s[t]>=0?s[t]:e;let i=f(4,5)/10,$=f(5,3)/10,c=f(6,2)/10,n=f(7,6)/10,M=[];M[0]=`hsl(${f(8,0)},100%,${f(a,50)}%)`,M[1]=`hsl(${f(9,0)},100%,${f(a,50)}%)`,M[2]=`hsl(${f(10,0)},100%,${f(a,50)}%)`,M[3]=`hsl(${f(11,0)},100%,${f(a,50)}%)`,M[4]=`hsl(${f(12,0)},100%,${f(a,50)}%)`,M[5]=`hsl(${f(13,0)},100%,${f(a,50)}%)`,M[6]=`hsl(${f(14,0)},100%,${f(17,0)}%)`,M[7]=`hsl(${f(15,0)},100%,${f(17,0)}%)`,M[8]="black";let u=0,m=[],A=[],b=[],w=[],p=Array(29).fill(0).map((()=>[0,0,0,0,0]));if(h.length!==2*p.length)throw new Error("circles num error");let E=()=>{let a=f(0,60)+120+u,s=f(1,45)-45,P=2*f(2,2)+4,d=Math.sin(9*(f(3,0)+u)*Math.PI/180),y=30*d,I=.3*Math.abs(d);u++,t(m,[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]),p[0]=[0,0,0,i,0];for(let r=0;r<2;r++){let h=1+r,a=0===r?1:-1;t(A,m),o(A,30*a),l(A,-y*a),e(A,0,-(i+.7*$),0),p[h]=[A[12],A[13],A[14],$,h]}for(let l=0;l<2;l++){let o=3+l,h=0===l?1:-1;t(A,m),r(A,+y),e(A,(i+.5*c)*h,0,0),p[o]=[A[12],A[13],A[14],c,o]}t(A,m),l(A,-30),e(A,0,+(i+.7*n),0),l(A,30),t(b,A),l(b,150);for(let l=0;l<8;l++){let r=l/7;t(w,b),e(w,0,0,-1.333*n*r),p[5+l]=[w[12],w[13],w[14],n*(3-2*r)/3,5]}for(let l=0;l<2;l++){let o=0===l?1:-1;t(b,A),r(b,-15*o),e(b,0,0,-.8*n);for(let r=0;r<8;r++){let o=r/7-.5;t(w,b),e(w,0,.6*n*o,0),p[13+8*l+r]=[w[12],w[13],w[14],n/6,6+l]}}let g=p.reduce(((t,e)=>Math.min(t,e[1]-e[3])),0);p.forEach((t=>{t[1]+=I-g})),(e=>{t(e,[1,0,0,0,0,-1,0,0,0,0,-1.2,-1,0,0,-2.2,0])})(m),e(m,0,0,-P),l(m,s),r(m,a),e(m,0,-1.4,0),p.forEach((l=>{t(A,m),e(A,l[0],l[1],l[2]),l[0]=A[12]/A[15],l[1]=A[13]/A[15],l[2]=A[14]/A[15],l[3]=l[3]/A[15]})),p.sort(((t,e)=>e[2]-t[2]));let k=0;for(let t=0;t<2;t++)p.forEach((e=>{let l=h.item(k++);l.setAttribute("cx",Math.floor(350*(2*e[0]+.5))),l.setAttribute("cy",Math.floor(350*(2*e[1]+.5))),l.setAttribute("r",Math.floor(2*e[3]*350+(0===t?16:0))),l.setAttribute("fill",M[0===t?8:e[4]])}));window.requestAnimationFrame(E)};E()}})();';
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------