// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "hardhat/console.sol";

contract Token {
    string public name = "My Hardhat Token";
    string public symbol = "MHT";

    uint256 public totalSupply = 1000000_000_000_000_000_000_000;
    address public owner;

    mapping(address => uint256) balances;

    constructor () {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
        External to     
     */
    function transfer(address to, uint256 amount) external {
        //console.log("Sender balance is %s token", balances[msg.sender]);
        //console.log("Trying to send %s tokens to %s", amount, to);
        //Check balances
        require(balances[msg.sender] >= amount, 'Not enough tokens');

        //Transfer
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

}