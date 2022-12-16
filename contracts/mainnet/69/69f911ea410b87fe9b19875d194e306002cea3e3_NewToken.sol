pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 1000000000;
		name = "Bonari Protocol";
		decimals = 2;
		symbol = "BON";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}