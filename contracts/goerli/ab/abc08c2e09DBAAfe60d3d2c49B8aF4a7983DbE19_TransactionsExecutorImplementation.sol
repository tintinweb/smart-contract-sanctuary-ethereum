/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20TransferFrom {
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

	function transferOwnership(address newOwner) external onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
		}
	}
	
	function setManager(address newManager) external onlyOwner {
		_manager = newManager;
	}

	function getOwner() external view returns (address) {
		return _owner;
	}
	
	function getManager() external view returns (address) {
		return _manager;
	}

}

contract TransactionsExecutorImplementation is Manageable {

	bool internal _initialized;

	function initialize(address owner, address manager) external {
		require(!_initialized);
		require(owner != address(0));
		_owner = owner;
		_manager = manager;
		_initialized = true;
	}
	
	function batchTransferFrom(
		IERC20TransferFrom[] calldata _token,
		address[] calldata _from,
		address[] calldata _to,
		uint256[] calldata _value
	) external onlyManager {
		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
			_token[i].transferFrom(_from[i], _to[i], _value[i]);
			unchecked {++i;}
		}
	}	
}