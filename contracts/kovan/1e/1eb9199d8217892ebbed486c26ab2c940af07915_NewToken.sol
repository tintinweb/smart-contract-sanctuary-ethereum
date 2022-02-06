pragma solidity ^0.5.7;

//░█████╗░██╗░░░░░████████╗██████╗░██╗░░░██╗
//██╔══██╗██║░░░░░╚══██╔══╝██╔══██╗╚██╗░██╔╝
//███████║██║░░░░░░░░██║░░░██████╔╝░╚████╔╝░
//██╔══██║██║░░░░░░░░██║░░░██╔══██╗░░╚██╔╝░░
//██║░░██║███████╗░░░██║░░░██║░░██║░░░██║░░░
//╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝░░░╚═╝░░░

import "./ERC20Standard.sol";

contract NewToken is ERC20Standard {
	constructor() public {
		totalSupply = 20000000;
		name = "Altry";
		decimals = 8;
		symbol = "ALT";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}