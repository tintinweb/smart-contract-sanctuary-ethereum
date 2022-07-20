/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract hotelbooking{
    enum statuses { vacant , Occupied}
    statuses currentStatus;
    address payable public owner;
    event Occupy(address _occupier, uint _ammount);
     constructor() public{
        owner = msg.sender;
        currentStatus = statuses.vacant;
    }
    modifier checkFree{
        require(currentStatus == statuses.vacant,'no room currently available');
        _;
    }
    modifier costs(uint _ammount){
        require(msg.value >= _ammount,'please keep your price up');
        _;
    }
    receive() external payable costs(0.01 ether) checkFree{
         
        currentStatus = statuses.Occupied;
        owner.transfer(msg.value);
        emit Occupy(msg.sender,msg.value);
    }
}