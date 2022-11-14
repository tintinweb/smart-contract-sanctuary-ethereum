/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

	function getOwner() public view returns (address) {
		return _owner;
	}
	
	function getManager() public view returns (address) {
		return _manager;
	}

}

contract SmartWallet is Manageable {
	address internal _implementation;
    address public _contractAddr;
	
	constructor(address owner, address manager, address implementation) {
        _owner = owner;
        _manager = manager;
		_implementation = implementation;
	}
	
	receive()   payable external {}
	
	fallback () payable external onlyManager {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), sload(_implementation.slot), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
	}
	
	function getImplementation() public view returns (address) {
		return _implementation;
	}	
}

contract SmartWalletCreator{

    event SmartWalletCreate(address indexed newSmartWallet);
	
	function createSmartWallet(address owner, address manager, address implementation) public returns (address) {
		SmartWallet sWallet = new SmartWallet(owner, manager, implementation);
        emit SmartWalletCreate(address(sWallet));
		return address(sWallet);
	}

}