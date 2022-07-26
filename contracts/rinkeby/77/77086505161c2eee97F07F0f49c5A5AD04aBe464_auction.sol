// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract auction  {
    mapping(address => uint) public bidders;

    function make_bid() public payable{
        require(msg.value > 0);
        bidders[msg.sender] += msg.value;
    }


    function return_money(address to) public payable{
        payable(to).transfer(bidders[to]);
        bidders[to] = 0;
    }
}


// Contract Address - 0x77086505161c2eee97F07F0f49c5A5AD04aBe464