//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./ERC20Standard.sol";

contract MyToken2 is ERC20Standard {
	constructor() public {
		totalSupply = 1000000000;
		name = "My Token 2";
		decimals = 18;
		symbol = "MYT2";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}