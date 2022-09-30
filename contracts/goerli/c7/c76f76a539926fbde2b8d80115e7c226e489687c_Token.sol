/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Token{

    string public name = "SooskaTokenV2";
    string public symbol = "SKT";
    uint8 public decimals = 18;
    
    address admin;
    mapping (address => uint) public balanceOf;

    constructor (uint initSupply) {
        balanceOf[msg.sender] = initSupply * (10**decimals);
        admin = msg.sender;
    }

    function transfer (address to, uint amount) public returns(bool) {
        balanceOf[to] += amount;
        balanceOf[msg.sender] -= amount;
        return true;
    }

    function mint (uint amount) public {
        require(msg.sender == admin);
        balanceOf[msg.sender] += amount;
    }

    function burn (uint amount) public {
        balanceOf[msg.sender] -= amount;
    }
}