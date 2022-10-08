pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 1000000000000;
		name = "W.M.S.F.";
		decimals = 4;
		symbol = "WMSF";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}