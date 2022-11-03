/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

//SPDX-License-Identifier: UNLICENSED

// use the latest version of solidity
pragma solidity ^0.8.0;
// This contract is upgradeable
contract ProxyContract {
    // address of the current implementation
    address public currentImplementation;
    // address of the owner
    address public owner;
    // event to log the change of implementation
    event Upgraded(address indexed implementation);
    // constructor
    constructor(address _implementation) {
        owner = msg.sender;
        currentImplementation = _implementation;
    }
    // fallback function
    fallback() external payable {
        address _impl = currentImplementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    // function to upgrade the implementation
    function upgradeTo(address _newImplementation) public {
        require(msg.sender == owner);
        currentImplementation = _newImplementation;
        emit Upgraded(_newImplementation);
    }
}