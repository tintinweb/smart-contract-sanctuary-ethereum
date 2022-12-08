pragma solidity ^0.4.11;

import "./ERC20Standard.sol";

contract TokenMEVSO is ERC20Standard {
	function TokenMEVSO() {
		totalSupply = 10000000000000;
		name = "mevso.io";
		decimals = 8;
		symbol = "MEVSO";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}