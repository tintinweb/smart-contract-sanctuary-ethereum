pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 20000000000000000000000000;
		name = "wTransistor";
		decimals = 18;
		symbol = "wTRITR";
		version = "1.1";
		balances[msg.sender] = totalSupply;
	}
}