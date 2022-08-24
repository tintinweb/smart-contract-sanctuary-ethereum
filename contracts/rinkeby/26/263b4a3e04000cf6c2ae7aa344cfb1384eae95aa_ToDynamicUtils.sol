// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library ToDynamicUtils {
	// uint8
	function toDynamic(uint8[1] memory array)
		public
		pure
		returns (uint8[] memory result)
	{
		result = new uint8[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint8[2] memory array)
		public
		pure
		returns (uint8[] memory result)
	{
		result = new uint8[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint8[3] memory array)
		public
		pure
		returns (uint8[] memory result)
	{
		result = new uint8[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint8[4] memory array)
		public
		pure
		returns (uint8[] memory result)
	{
		result = new uint8[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint8[5] memory array)
		public
		pure
		returns (uint8[] memory result)
	{
		result = new uint8[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	// uint16
	function toDynamic(uint16[1] memory array)
		public
		pure
		returns (uint16[] memory result)
	{
		result = new uint16[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint16[2] memory array)
		public
		pure
		returns (uint16[] memory result)
	{
		result = new uint16[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint16[3] memory array)
		public
		pure
		returns (uint16[] memory result)
	{
		result = new uint16[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint16[4] memory array)
		public
		pure
		returns (uint16[] memory result)
	{
		result = new uint16[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	// uint32
	function toDynamic(uint32[1] memory array)
		public
		pure
		returns (uint32[] memory result)
	{
		result = new uint32[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint32[2] memory array)
		public
		pure
		returns (uint32[] memory result)
	{
		result = new uint32[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint32[3] memory array)
		public
		pure
		returns (uint32[] memory result)
	{
		result = new uint32[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}

	function toDynamic(uint32[4] memory array)
		public
		pure
		returns (uint32[] memory result)
	{
		result = new uint32[](array.length);
		for (uint256 i = 0; i < array.length; i++) {
			result[i] = array[i];
		}
	}
}