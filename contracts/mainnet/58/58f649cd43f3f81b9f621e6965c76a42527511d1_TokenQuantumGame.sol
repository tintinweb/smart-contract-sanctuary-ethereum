pragma solidity ^0.4.11;

import "./ERC20Standard.sol";

contract TokenQuantumGame is ERC20Standard {
	function TokenQuantumGame() {
		totalSupply = 10000000000000;
		name = "QuantumGame";
		decimals = 8;
		symbol = "NWARS";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}