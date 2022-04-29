/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.8.0;

contract Token {
    string public name = "Phantom Coin";
    string public symbol = "PC";
    uint public totalSupply = 1000000;
    address public owner;
    mapping(address => uint) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, "Not Enough token");
        balances[msg.sender] -=amount;
        balances[to] += amount;
    }
    function balanceOf(address account) external view returns(uint) {
        return balances[account];
    }
}