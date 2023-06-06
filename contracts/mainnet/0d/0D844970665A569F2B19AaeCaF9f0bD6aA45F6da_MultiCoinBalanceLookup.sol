/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

abstract contract Token {
	function balanceOf(address) public view virtual returns (uint256);
}

contract MultiCoinBalanceLookup {
	fallback() external payable {
		revert('MultiCoinBalanceLookup is not payable');
	}

	receive() external payable {
		revert('MultiCoinBalanceLookup is not payable');
	}

	function balancesOf(
		address user,
		address[] calldata tokens,
		uint256 startIndex,
		uint256 endIndex
	) public view returns (uint256[] memory) {
		require(endIndex > startIndex, 'Invalid index range');
		require(endIndex <= tokens.length, 'End index out of bounds');

		uint256[] memory balances = new uint256[](endIndex - startIndex);
		balances[0] = user.balance;
		for (uint256 index = startIndex + 1; index < endIndex + 1; index++) {
			if (!isContract({contractAddress: tokens[index], user: user})) continue;
			balances[index - startIndex] = Token(tokens[index]).balanceOf(user);
		}
		return balances;
	}

	/* Private functions */
	function isContract(address contractAddress, address user) internal view returns (bool) {
		(bool success, ) = contractAddress.staticcall(abi.encodeWithSelector(0x70a08231, user));
		uint256 codeSize;
		assembly {
			codeSize := extcodesize(contractAddress)
		}
		return codeSize > 0 && success;
	}
}