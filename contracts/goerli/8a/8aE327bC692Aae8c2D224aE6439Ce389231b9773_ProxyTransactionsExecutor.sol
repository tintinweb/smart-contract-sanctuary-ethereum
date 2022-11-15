/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITransactionsExecutorImplementation {
	function initialize(address newOwner, address newManager) external;
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

contract ProxyTransactionsExecutor is Manageable {
	ITransactionsExecutorImplementation internal _implementation;
	
	constructor(address owner, address manager, ITransactionsExecutorImplementation implementation) {
		_owner = owner;
		_manager = manager;
		_implementation = implementation;
		(bool success,) = address(implementation).call{value: 0}(abi.encodeWithSelector(implementation.initialize.selector, owner, manager));
		require(success);
	}
	
	receive()   payable external {}
	
	fallback () payable external {
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), sload(_implementation.slot), 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
	
	function setImplementation(ITransactionsExecutorImplementation newImplementation) external onlyManager {
		_implementation = newImplementation;
	}
	
	function getImplementation() external view returns (ITransactionsExecutorImplementation) {
		return _implementation;
	}	
}