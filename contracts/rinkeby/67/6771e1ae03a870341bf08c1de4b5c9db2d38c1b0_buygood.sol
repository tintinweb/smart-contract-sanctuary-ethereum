/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// File: buygood.sol

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

contract buygood {

    address public owner;
    uint256 public balance;

    mapping(string => paylog) logs;
    
    struct paylog {
        address customer;
        uint value;
        bool isvalid;
    }

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    receive() external payable {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    }

    constructor() {
        owner = msg.sender;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, destAddr, amount);
    }

    function buy(string memory hash) public payable returns (bool) {
        balance += msg.value;
        logs[hash] = paylog(msg.sender,msg.value,true);
        return true;
    }

    function check(string memory hash, address customer,uint value) public view returns (bool) {
        paylog memory log = logs[hash];
        if(log.isvalid == false || log.value < value || log.customer != customer) {
            return false;
        }
        else {
            return true;
        }
    }

}