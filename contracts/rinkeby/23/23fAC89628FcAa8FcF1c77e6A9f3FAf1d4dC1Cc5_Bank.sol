/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// File: contracts/Bank.sol


pragma solidity ^0.8.0;

contract Bank {

// struct Game {
//         address treasury;
//         uint256 balance;
//     }    

// mapping (address=>mapping(uint256=> Game)) private balances;

mapping (address=>uint256) private balances;

function deposit() payable public {
balances[msg.sender]+=msg.value;
}

function withdraw(uint256 amount) public{
    require(balanceOf(msg.sender)>=amount);

    balances[msg.sender]-=amount;

   payable( msg.sender).transfer(amount);
}

function balanceOf(address account) public view returns (uint256){
    return balances[account];
}

}