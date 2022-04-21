// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Sentt{
    address private manager;
    address payable[] private user;
    uint256 public balance;
    uint256 public constant min = 100000000000000000; // 0.1 ETH

    constructor() {
        manager= msg.sender;
    }
    
    modifier onlyManager() {
        require(msg.sender==manager,"Only manager can call this function");
        _;
    }
    
    //Events
    event userSentt(address user, uint256 amount);
        
    //Gimme Ether
    function sentt() payable public {
        //limit
        require(msg.value >= min, "Must to send at least 0.1 ether");
        user.push(payable(msg.sender));
        emit userSentt(msg.sender, msg.value);       
    }

    function getBalance() public view onlyManager returns(uint) {
        return address(this).balance;
    }

    function withdraw() public onlyManager {
        address payable _manager = payable(msg.sender);
        _manager.transfer(address(this).balance);
    }
}

// Contract Adress: 0x3fe98Ec9A46acb5993536DF38A8C159Ee32aa19b