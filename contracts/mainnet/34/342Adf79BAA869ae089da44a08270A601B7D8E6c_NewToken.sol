// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() {
		totalSupply = 100000000;
		name = "Levsha Instruments Token";
		decimals = 2;
		symbol = "JLIN";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}