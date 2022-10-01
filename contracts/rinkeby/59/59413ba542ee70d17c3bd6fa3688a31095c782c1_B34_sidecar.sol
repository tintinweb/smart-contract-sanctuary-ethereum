/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
}

contract B34_sidecar {
	address public owner;
	constructor() { owner = msg.sender; }
	function recoverErc20Tokens(address tokenCA) external returns (uint256) {
		require(msg.sender==owner,"Not authorized");
		uint256 balance = IERC20(tokenCA).balanceOf(address(this));
		if (balance>0) { IERC20(tokenCA).transfer(msg.sender, balance); }
		return balance;
	}
}