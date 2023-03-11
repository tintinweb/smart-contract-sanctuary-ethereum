/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// Author: JiceJin#7270

contract Counter{
    uint256 public count;
    address public owner;

    constructor (){
        owner = msg.sender;
    }

    modifier isOwner {
        require(owner==msg.sender,'Must be owner');
        _;
    }

    function add(uint a) public isOwner{
        count += a;
    }
}