pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 10000000000000000000000000000;
		name = "Shlipa Coin";
		decimals = 18;
		symbol = "SHLC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}