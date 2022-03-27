/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// File: buygood.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

struct paylog{
    address customer;
    uint value;
    bool isvalid;
}

contract buygood{

    address public owner;
    mapping(string => paylog) logs;
    uint256 public balance;
    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyowner() {
        require(msg.sender == owner,"Only Owner");
        _;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount);
        balance -= amount;
        emit TransferSent(msg.sender, destAddr, amount);
    }

    function buy(string memory hash, uint _price) public payable returns (bool) {
        logs[hash] = paylog(msg.sender,_price,true);
        return true;
    }

    function check(string memory hash, address customer,uint value) public view returns (bool) {
        paylog memory log = logs[hash];
        if(log.customer != customer || log.value < value || log.isvalid == false){
            return false;
        }
        else{
            return true;
        }
    }

}