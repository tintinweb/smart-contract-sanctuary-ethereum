/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract RuinedCanvas{
    event PixelSet(uint indexed x, uint indexed y, uint rgb);
    
    mapping(uint => mapping(uint => uint)) pixel;
    mapping(address => bool) joined;
    mapping(address => uint) cd;

    uint membershipCost = 1000000000000000;
    address benefactor;
    uint benefactorClaimed;

    constructor(){
        benefactor = msg.sender;
    }
    ///@param rgb hex value 
    function aSetPixel(uint16 x, uint16 y, uint224 rgb) public payable{
        require(joined[msg.sender], "Ya gotta join first buddy");
        require(block.number > cd[msg.sender], "On CD");
        cd[msg.sender] = block.number + 24;
        pixel[x][y] = rgb;
        emit PixelSet(x,y,rgb);
    }

    function cJoin() public payable{
        require(msg.value == membershipCost, "Invalid payment, sorry friend");
        require(!joined[msg.sender], "Already joined mate");
        joined[msg.sender] = true;
    }
    function dGiftMembership(address addy) public payable{
        require(msg.value == membershipCost, "Invalid payment, sorry friend");
        require(!joined[addy], "Already joined mate");
        joined[addy] = true;
    }
    function zBenefactorWithdraw() public{
        require(msg.sender == benefactor);
        uint claim = address(this).balance - benefactorClaimed;
        benefactorClaimed += claim;
        payable(benefactor).transfer(claim);
    }
}