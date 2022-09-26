/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract class32{
    address payable owner;

    constructor() payable{
        owner = payable(msg.sender);
    }    

    function queryContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function querybalance() public view returns(uint){
        return owner.balance;
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}