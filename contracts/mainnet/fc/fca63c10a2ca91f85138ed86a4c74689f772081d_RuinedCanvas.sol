/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract RuinedCanvas{
    event Joined(address);
    event PixelSet(uint indexed x, uint indexed y, uint rgb);
    
    mapping(uint => mapping(uint => uint)) public pixel;
    mapping(address => bool) public joined;
    mapping(address => uint) cd;

    uint membershipCost = 2400000000000000;
    address benefactor;

    constructor(){
        benefactor = msg.sender;
        joined[msg.sender] = true;
    }
    ///@param rgb hex value 
    function aSetPixel(uint x, uint y, uint rgb) public payable{
        require(joined[msg.sender], "Ya gotta join first buddy");
        require(block.number > cd[msg.sender], "On CD");
        cd[msg.sender] = block.number;
        pixel[x][y] = rgb;
        emit PixelSet(x,y,rgb);
    }

    function cJoin() public payable{
        require(msg.value == membershipCost, "Invalid payment, sorry friend");
        require(!joined[msg.sender], "Already joined mate");
        joined[msg.sender] = true;
        emit Joined(msg.sender);
    }
    function dGiftMembership(address addy) public payable{
        require(msg.value == membershipCost, "Invalid payment, sorry friend");
        require(!joined[addy], "Already joined mate");
        joined[addy] = true;
        emit Joined(addy);
    }
    function zBenefactorWithdraw() public{
        require(msg.sender == benefactor);
        payable(benefactor).transfer(address(this).balance);
    }
}