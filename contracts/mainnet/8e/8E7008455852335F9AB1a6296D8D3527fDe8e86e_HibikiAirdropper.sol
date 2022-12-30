/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HibikiAirdropper {

	address public owner;
	address public hibiki;

	constructor(address bikky) {
		owner = msg.sender;
		hibiki = bikky;
	}

	function recoverTokens() external {
		IERC20 bikky = IERC20(hibiki);
		bikky.transfer(owner, bikky.balanceOf(address(this)));
	}

	function airdrops(address[] calldata drops, uint256[] calldata amounts) external {
		require(msg.sender == owner);
		IERC20 bikky = IERC20(hibiki);
		require(drops.length == amounts.length);
		for (uint256 i = 0; i < drops.length; i++) {
			bikky.transfer(drops[i], amounts[i]);
		}
	}
}