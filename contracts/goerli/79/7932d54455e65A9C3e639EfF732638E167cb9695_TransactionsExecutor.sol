/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20TransferFrom {
	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}

contract Manageable {
	address internal _owner;
	address internal _manager;

	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}
	
	modifier onlyManager() {
		require(msg.sender == _manager);
		_;
	}

	modifier onlyOwnerManager() {
		require(msg.sender == _owner || msg.sender == _manager);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
		}
	}
	
	function setManager(address newManager) public onlyOwner {
		_manager = newManager;
	}

	function getOwner() public onlyOwnerManager returns (address) {
		return _owner;
	}
	
	function getManager() public onlyOwnerManager returns (address) {
		return _manager;
	}

}

contract TransactionsExecutor is Manageable {

	bool internal _initialized;

	function initialize(address newOwner, address newManager) public {
		require(!_initialized);
		require(newOwner != address(0));
		_owner = newOwner;
		_manager = newManager;
		_initialized = true;
	}
	
	function batchTransferFrom(
		IERC20TransferFrom[] calldata _token,
		address[] calldata _from,
		address[] calldata _to,
		uint256[] calldata _value
	) public onlyManager {
		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
			_token[i].transferFrom(_from[i], _to[i], _value[i]);
			unchecked {++i;}
		}
	}
}