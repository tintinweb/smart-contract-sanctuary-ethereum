//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import './ERC20.sol';

contract VestigeGlobalCapital is ERC20{
	address public admin;
	constructor() ERC20('Vestige Global Capital','VEST'){
		_mint(msg.sender,20000000 * 10 ** 18);
		admin = msg.sender;
	}

	function mint(address to, uint amount) external{
		require(msg.sender==admin, "only admin");
		_mint(to,amount);
	}
	function burn(uint amount) external {
		_burn(msg.sender, amount);
	}
}