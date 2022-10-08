/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

contract WeR1_Sidecar {
	address private immutable _owner;
	constructor() { _owner = msg.sender; }
	function owner() external view returns (address) { return _owner; }
	function recoverErc20Tokens(address tokenCA) external returns (uint256) {
		require(msg.sender == _owner, "Not authorized");
		uint256 balance = IERC20(tokenCA).balanceOf(address(this));
		if (balance > 0) { IERC20(tokenCA).transfer(msg.sender, balance); }
		return balance;
	}
}