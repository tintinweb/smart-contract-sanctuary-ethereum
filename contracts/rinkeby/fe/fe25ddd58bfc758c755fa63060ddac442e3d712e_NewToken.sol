pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 12300;
		name = "Percab coin";
		decimals = 4;
		symbol = "PEC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}