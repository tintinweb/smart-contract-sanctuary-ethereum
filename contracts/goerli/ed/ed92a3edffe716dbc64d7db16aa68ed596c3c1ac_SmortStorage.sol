/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.17;

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

contract SmortStorage is protected {

    mapping(address => string) hashed;
    mapping(address => address) recovery_address;
    mapping(address => bool) requested_recovery;
    mapping(address => uint) recovery_request_time;

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;
    }

    // With wallet operations

    function setHash(string memory hash) public {
        if(bytes(hashed[msg.sender]).length != 0) {
            hashed[msg.sender] = hash;
        } else {
            revert("Hash already set");
        }
    }

    function getHash() public view returns (string memory) {
        if(bytes(hashed[msg.sender]).length != 0) {
            return hashed[msg.sender];
        } else {
            return "";
        }
    }

    function delHash() public safe {
        delete hashed[msg.sender];
    }

    function setRecoveryAddy(address recovery) public {
        if(recovery_address[msg.sender] == address(0)) {
            // Resetting any recovery request
            requested_recovery[msg.sender] = false;
        } 
        recovery_address[msg.sender] = recovery;
    }

    // Recovery request by third parts
    function askRecovery(address addy) public {
        if(bytes(hashed[addy]).length == 0) {
            revert("Hash does not exists");
        }
        // Safety check
        if (msg.sender != recovery_address[addy]) {
            revert("Not recovery mail");
        }
        // Check if is already requested
        if (requested_recovery[addy]) {
            // Check if is not too soon
            if (recovery_request_time[addy] + 7 days > block.timestamp) {
                revert("Too soon");
            }
        }
        // Or if is a first request
        else {
            requested_recovery[addy] = true;
            recovery_request_time[addy] = block.timestamp;
        }
    }

    // Reset of recovery request
    function resetRecovery() public {
        requested_recovery[msg.sender] = false;
    }

    // Recovery method without wallet
    function getSpecificHash(address addy) 
                             public view onlyAuth
                             returns (string memory) {
        return hashed[addy];
    }

}