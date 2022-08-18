/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;




contract FunToken {
    
    string public name= "FunToken";
    string public symbol = "FUN";
    uint256 public decimals = 18;
    uint public totalSupply = 1000e18;

    
    address public owner;
    mapping (address => uint) balance;

    constructor()
    {
        balance[msg.sender] = totalSupply;
        owner = msg.sender;

    }

    function transfer(address _to, uint256 _amount) external
    {
        
        require(balance[msg.sender]>=_amount, "Insufficient balance");

        balance[msg.sender] = balance[msg.sender] - _amount;
        balance[_to] = balance[_to] + (_amount);
    }

    function balanceOf(address account) public view returns (uint256) 
    {
     return balance[account];
    }
   
}