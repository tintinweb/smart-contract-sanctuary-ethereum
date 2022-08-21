/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Token {
    address public minter;
    mapping(address => uint) public balances;

    event Transfer(address from, address to, uint amount);

    constructor(){
        minter = msg.sender;
    }
    function mint(address receiver, uint amount) public{
        require(msg.sender == minter);
        balances[receiver] += amount;
    }
    function burn(address receiver, uint amount) public{
        require(receiver == minter);
        balances[receiver] -= amount;
    }
    function transfer (address receiver, uint amount) public{
        require(amount <= balances[msg.sender]);
        balances[receiver] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, receiver, amount);
    }
    // function name() external view returns (string memory);

    // function symbol() external view returns (string memory);

    // function decimals() external view returns (uint8);
}