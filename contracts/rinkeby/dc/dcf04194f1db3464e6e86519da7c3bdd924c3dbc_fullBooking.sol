/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract fullBooking {

    address payable public owner; 
    enum roomStatus { Free, Occupied } 
    roomStatus public States;
    mapping(uint => customer) public custBase;

    struct customer {
        string name;
        string email;
        uint phone;
    }

    constructor() {
        owner = payable(msg.sender);
        States = roomStatus.Free;
    }

    modifier cost(uint _amount) {
        require(msg.value >= _amount, "Not Enough Money");
        _;
    }
    modifier confStatuses() {
        require(States == roomStatus.Free);
        _;
    }
    
    function bookDone(uint _id, string memory _name, string memory _email, uint _phone) public payable cost(800000 gwei) {
        custBase[_id] = customer(_name, _email, _phone);
        owner.call{value: msg.value };
        require(true);

    }


}