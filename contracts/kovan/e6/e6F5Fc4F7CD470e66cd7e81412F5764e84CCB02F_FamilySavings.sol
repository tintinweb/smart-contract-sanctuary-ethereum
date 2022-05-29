// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract FamilySavings {
	// withdrawal limit (can be reset by the owner)
	// list of allowed addresses to withdraw
	// event money withdrawn

	address immutable owner;

	mapping(address => uint256) private amountSent;

	mapping(address => bool) private allowedToWithdraw;

	constructor() {
		owner = address(msg.sender);
		allowedToWithdraw[msg.sender] = true;
	}

	receive() external payable {
		amountSent[msg.sender] += msg.value;
	}

	function myTotalAmountSent() public view returns (uint256) {
		return amountSent[msg.sender];
	}

	function setAllowedAddress(address _address, bool _canWithdraw) public {
		require(msg.sender == owner);
		allowedToWithdraw[_address] = _canWithdraw;
	}

	function withdraw(uint256 _amount) public {
		require(allowedToWithdraw[msg.sender] == true);
		require(_amount <= address(this).balance);
		payable(msg.sender).transfer(_amount);
	}
}