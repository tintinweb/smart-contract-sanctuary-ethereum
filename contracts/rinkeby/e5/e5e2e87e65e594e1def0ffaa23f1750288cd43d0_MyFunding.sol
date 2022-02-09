/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract MyFunding {
    constructor() {
        owner = msg.sender;
    }

    // minimum funding value each time
    uint256 _MINIMUM_VALUE = 0.01 ether;

    // funding owner
    address public owner;
    
    // funding target
    uint256 public target = 10 ether;
    uint256 public total = 0 ether;
    bool public isActive = true;
    
    // sponsors
    mapping (address => uint256) public sponsors;
    
    // register an funding Event
    event Fund(address _sponsor, uint256 _value);

    function fund() public payable {
        // check if the funding is finished
        require(isActive, "The funding is not active");

        // throw an error and stop function if the funding value is less than 0.01 ether
        require(msg.value >= _MINIMUM_VALUE, "Too little, please support me more");

        // calculate the funding total
        total += msg.value;
        // add funding value to the mapping
        sponsors[msg.sender] += msg.value;

        // emit the fund event
        emit Fund(msg.sender, msg.value);

        // check if it's able to withdraw
        if (total >= target) {
            withdraw();
        }
    }

    function withdraw() internal {
        address payable ownerPayable = payable(owner);
        (bool sent, ) = ownerPayable.call{value: total}("");
        require(sent, "Failed to withdraw funding");
        isActive = false;
    }

}