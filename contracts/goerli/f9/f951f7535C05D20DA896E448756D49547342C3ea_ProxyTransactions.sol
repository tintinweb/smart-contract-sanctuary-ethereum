/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ownable {
	address internal _owner;

	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
		}
	}

    function renounceOwnership() public onlyOwner {
		_owner = address(0);
	}

	function getOwner() public view returns (address) {
		return _owner;
	}
}

contract ProxyTransactions is Ownable {
	address internal _implementation;
	
	constructor(address owner, address implementation) {
		_implementation = implementation;
        _owner = owner;
	}
	
	fallback () external {
        this.delegate();
	}

    function delegate() external {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), sload(_implementation.slot), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
	
	function setImplementation(address newImplementation) public onlyOwner {
		_implementation = newImplementation;
	}
	
	function getImplementation() public view returns (address) {
		return _implementation;
	}	
}