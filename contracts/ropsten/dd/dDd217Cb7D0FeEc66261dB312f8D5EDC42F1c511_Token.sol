// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import 'hardhat/console.sol';

contract Token {
    string public name = 'BBT Token';
    string public symbol = 'BBTT';
    uint public totalSupply = 1000000;
    address public owner;
    mapping(address => uint) balances;

    constructor() { 

       // Give the total supply to the address that deploys the contract
       balances[msg.sender] = totalSupply;

       // Set the owner of the contract
       owner = msg.sender;
    }

    function transfer(address to, uint amount) external {

       // console.log('Sender balance is %s tokens', balances[msg.sender]);
       // console.log('Trying to send %s tokens to %s', amount, to);

       // Check that there is enough to do the transfer
       require(balances[msg.sender] >= amount, 'Not enough tokens');

       // Update the balances
       balances[msg.sender] -= amount;
       balances[to] += amount;
    }

    // Function to check balance
    function balanceOf(address account) external view returns(uint) {
       return balances[account];
    }
}