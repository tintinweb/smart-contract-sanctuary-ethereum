/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/**
 * Holds tokens with future use.
 * This contract holds tokens for vesting, bridge liquidity, CEX liquidity, and so on.
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
	function transfer(address recipient, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HibikiHolder {

	address public owner;
	address public hibiki;

	constructor(address bikky) {
		owner = msg.sender;
		hibiki = bikky;
	}

	function setHibiki(address b) external {
		require(msg.sender == owner);
		hibiki = b;
	}

	function sendTokens(address receiver) external {
		require(msg.sender == owner);
		IERC20 bikky = IERC20(hibiki);
		bikky.transfer(receiver, bikky.balanceOf(address(this)));
	}
}