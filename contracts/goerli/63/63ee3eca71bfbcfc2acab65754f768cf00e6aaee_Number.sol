/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// contracts/classExamples/number.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Number {
    address payable public owner;
    uint256 public units;
    uint256 public timesChanged;
    mapping (address => bool) public admins;
    uint256 public lastChangeTimestamp; 

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isAuthorized() {
        require(admins[msg.sender] == true || msg.sender == owner);
        _;
    }

    constructor(uint256 initialUnits) {
        units = initialUnits;
        timesChanged = 0;
        owner = payable(msg.sender);
        lastChangeTimestamp = block.timestamp;
    }

    function setUnits(uint256 newUnits) isAuthorized public {
        require(block.timestamp > lastChangeTimestamp + 3 minutes, "too early to change units");
        units = newUnits;
        lastChangeTimestamp = block.timestamp;
        timesChanged += 1;
    }

    function incrementUnits(uint256 inc) isAuthorized payable public {
        require(msg.value >= 0.01 ether * inc, "no enough ether");
        units += inc;
        timesChanged += 1;
    }

    // NEW function
    function decrementUnits(uint256 inc) isAuthorized payable public {
        require(msg.value >= 0.01 ether * inc, "no enough ether");
        units -= inc;
        timesChanged += 1;
    }

    function addAdmin(address newAdmin) isOwner public {
        admins[newAdmin] = true;
    }

    function removeAdmin(address admin_address) isOwner public {
        admins[admin_address] = false;
    }

    function balance() private view returns (uint256) {
        return address(this).balance;
    }
    function widthdraw() isOwner public {
        owner.transfer(balance());
    }
}