// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GBKTrade {
	constructor() {}

	error CallFailed();
	event RechargeWallet(address account, uint256 amount);

	event RechargeId(uint256 id, uint256 amount);

	function transderToWallet() external payable {
		_transfer();
		emit RechargeWallet(msg.sender, msg.value);
	}

	function transderToId(uint256 id) external payable {
		_transfer();
		emit RechargeId(id, msg.value);
	}

	function _transfer() internal {
		(bool success, ) = payable(this).call{value: msg.value}("");
		if (!success) {
			revert CallFailed();
		}
	}

	function getBalanceOfContract() public view returns (uint256) {
		return address(this).balance;
	}

	fallback() external payable {}

	receive() external payable {}
}