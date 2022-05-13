// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.4;

import "./Shopex.sol";

contract ETHSwap{
    SHOPEXCOIN public token;
    address public owner;
    // uint256 public rate;

    event TokensPurchased(
        address account,
        address token,
        uint256 amount,
        uint256 rate
    );

    // event TokensSold(
    //     address account,
    //     address token,
    //     uint amount,
    //     uint rate
    // );


    constructor(SHOPEXCOIN _token) {
        token = _token;
        owner = msg.sender;
    } 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    function buytokens(uint256 rate) public payable {
        uint256 tokenAmount = msg.value* rate;
        uint256 tokenAmount1 = tokenAmount/100000;
        require(token.balanceOf(address(this)) >= tokenAmount1);
        token.transfer(msg.sender, tokenAmount1);
        emit TokensPurchased(msg.sender, address(token), tokenAmount, tokenAmount1);
    }

    function withDrawOwner(uint256 _amount)onlyOwner public returns(bool){
        payable(msg.sender).transfer(_amount);
         return true;
    }

    // function sellTokens(uint _amount) public {
    //     require(token.balanceOf(msg.sender) >= _amount);
    //     uint etherAmount = _amount / rate;
    //     require(address(this).balance >= etherAmount);
    //     token.transferFrom(msg.sender, address(this), _amount);
    //     // msg.sender.transfer(etherAmount);
    //     emit TokensSold(msg.sender, address(token), _amount, rate);
    // }
}