/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Basic {
	bool public b = true;

	uint256 public u = 1;
	int256 public i = -1;

	int256 public minInt = type(int256).min;
	int256 public maxInt = type(int256).max;

	address public constant MY_ADDR = 0x1A24f7B01087665AF51EfC816aC1a96D813C6db5; // 較少 Gas
	address public MY_ADDR_2 = 0x1A24f7B01087665AF51EfC816aC1a96D813C6db5;
	bytes32 public b32 = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;

	bytes1 public b1 = 0xf0;
	bytes1[] public b1_array;
	bytes public b_array;

	function b_push(bytes1 n) external {
		b_array.push(n);
	}

	function b_pop() external {
		b_array.pop();
	}

	function b_length() external view returns (uint256) {
		return b_array.length;
	}

	function ifelse(uint32 _x) external pure returns (uint32) {
		if (_x < 10) {
			return 1;
		} else if (_x < 20) {
			return 2;
		}

		return 3;
	}

	function ternary(uint32 _x) external pure returns (uint32) {
		return _x < 10 ? 1 : 2;
	}

	function sum(uint256 x) external pure returns (uint256) {
		uint256 s = 0;
		for (uint256 j = 0; j <= x; j++) {
			s += j;
		}
		return s;
	}

	function _recursive_sum(uint256 x) internal pure returns (uint256) {
		if (x == 0) {
			return 0;
		}

		return x + _recursive_sum(x - 1);
	}

	function recursive_sum(uint256 x) external pure returns (uint256) {
		return _recursive_sum(x);
	}

	function _tail_recursive_sum(uint256 x, uint256 res) internal pure returns (uint256) {
		if (x == 0) {
			return res;
		}

		return _tail_recursive_sum(x - 1, res + x);
	}

	function tail_recursive_sum(uint256 x) external pure returns (uint256) {
		return _tail_recursive_sum(x, 0);
	}
}