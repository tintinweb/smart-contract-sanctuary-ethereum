/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: no-license
pragma solidity >=0.8.0 <= 0.8.17;

contract Token {
    string public name = "Hardhat Token";
    string public symbol = "HHT";
    uint public totalSupply = 1000000;
    address public owner;

    mapping(address => uint) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Not enougth tokens");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
    }



}