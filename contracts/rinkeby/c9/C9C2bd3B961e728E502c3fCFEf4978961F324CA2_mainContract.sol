//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract mainContract{
    
    mapping(address => bool) public isAddApproved; 

    uint256 public health = 7;

    function getHealth() public view returns(uint256){
        return health;
    }

    function changeHealth(uint256 newHealth) public {
        health = newHealth;
    }

    function approveAddress() public {
        isAddApproved[msg.sender] = true;
    }

    function checkApprove(address appAddress) public view returns(bool){
        return isAddApproved[appAddress];
    }

    function removeApprovedAddress() public {
        isAddApproved[msg.sender] = false;
    }



}