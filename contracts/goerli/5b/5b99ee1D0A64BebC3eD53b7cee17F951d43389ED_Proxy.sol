/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Proxy {
    address private _implementation;

    event Upgraded(address indexed implementation);

    constructor(address implementation_) {
        _implementation = implementation_;
        emit Upgraded(implementation_);
    }

    fallback() external payable {
        _delegate(_implementation);
    }

    receive() external payable {
        _delegate(_implementation);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    function upgrade(address newImplementation) public {
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    function _delegate(address implementation_) private {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), implementation_, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}