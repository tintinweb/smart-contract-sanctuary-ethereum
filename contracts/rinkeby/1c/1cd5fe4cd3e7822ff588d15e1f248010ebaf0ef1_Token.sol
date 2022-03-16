/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.8;

contract Token {

    mapping ( address => uint ) balances;

    constructor() {
        balances[msg.sender]= 10000;
    }

    function transfer(address to, uint amount) public {
        assert(balances[msg.sender] >= amount);
        
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
    }

}