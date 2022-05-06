// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.4;

import "./Shopex.sol";

contract EthSwap{
    SHOPEXCOIN public token;
    address public owner;
    // uint256 public rate;

    event TokensPurchased(
        address account,
        address token,
        uint amount,
        uint rate
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
        uint tokenAmount = msg.value * rate;
        require(token.balanceOf(address(this)) >= tokenAmount);
        token.transfer(msg.sender, tokenAmount);
        emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
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