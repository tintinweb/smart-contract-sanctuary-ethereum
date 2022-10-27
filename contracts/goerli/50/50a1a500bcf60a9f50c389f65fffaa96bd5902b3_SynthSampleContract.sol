/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

contract SynthSampleContract {
	event Mint(address user, uint256 amount);
	event Burn(address user, uint256 amount);

	function mint(address user, uint256 amount) public {
		emit Mint(user, amount);
	}

	function burn(address user, uint256 amount) public {
		emit Burn(user, amount);
	}
}

contract FactorySampleContract {
	event PoolCreated(address pool);

	function createPool(address pool) public {
		emit PoolCreated(pool);
	}
}