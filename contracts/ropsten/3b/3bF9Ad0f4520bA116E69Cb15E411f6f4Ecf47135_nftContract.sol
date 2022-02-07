/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract nftContract 
{
    mapping(address => uint256) public NFTsOwned;
    uint public mintPrice = 1 ether;


    function mint() public payable
    {
        require(msg.value == mintPrice);
        NFTsOwned[msg.sender]++;
    }
}