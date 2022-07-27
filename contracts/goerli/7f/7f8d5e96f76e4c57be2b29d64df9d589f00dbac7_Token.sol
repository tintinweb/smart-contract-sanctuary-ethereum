/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

pragma solidity ^0.8.13;

contract Token {
    string public name = 'My Wochan Token';
    string public symbol = "MWT";
    uint public totalSupply = 1000000;
    address public owner;
    mapping(address => uint) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint amount) external{
        require(balances[msg.sender] >= amount, 'Not enough tokens to transfer');
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns(uint){
        return balances[account];
    }
}