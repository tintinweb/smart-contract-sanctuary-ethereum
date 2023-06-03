/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract simpleBank {
    mapping (address => uint) private balances ;
    address public owner ;
    event depositLog (address AccountAddress , uint amount );
    constructor() {
        owner = msg.sender ;
    }
    function deposit () public payable returns (uint) {
        require ((msg.value + balances[msg.sender])> balances [msg.sender]);
        balances[msg.sender] += msg.value ;
        emit depositLog(msg.sender , msg.value);
        return balances[msg.sender] ;
    }
    function Withdraw (uint withdrawamount) public returns(uint){
        require (balances[msg.sender]>=withdrawamount , "insufficient funds");
        balances[msg.sender] -= withdrawamount ;
        payable (msg.sender).transfer(withdrawamount);
        return balances [msg.sender] ;        
    } 
    function balances1 ( ) public view returns (uint){
        return balances[msg.sender];
    }
}