/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Tester {
    event Paused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Upgraded(address indexed implementation);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    
    function pause() external {
        emit Paused(msg.sender);
    }

    function owner() external {
        emit OwnershipTransferred(address(this), msg.sender);
    }

    function upgraded() external {
        emit Upgraded(msg.sender);
    }

    function roleAdmin() external {
        emit RoleAdminChanged("132", "123", "123");
    }

    function roleGranted() external {
        emit RoleGranted("123", msg.sender, msg.sender);
    }

    function roleRevoked() external {
        emit RoleRevoked("123", msg.sender, msg.sender);
    }
}