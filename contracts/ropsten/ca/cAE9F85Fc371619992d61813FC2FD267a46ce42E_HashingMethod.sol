/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;

 contract HashingMethod{

     event bid(address indexed bidder,bytes32 indexed _Amount);
     event reveal(address indexed bidder,uint _amountReveal);

     struct userBidInfo{
         bytes32 amountHashed;
         uint amountRevealed;  // By default its value will be 0 before reveal the amount value
         uint biddingTime;
         bool isBid;
     }

     mapping(address=>userBidInfo) userBiddes;
     uint private bidClossingTime;
     uint private _highestBid;
     address private _highestBidder;


     constructor(){
         bidClossingTime=block.timestamp+30 minutes;
     }

     function Bid(bytes32 _Amount) external{
         require(bidClossingTime>block.timestamp,"HashingMethod:bidding time is over now,you Can't bid");
         userBiddes[msg.sender]=userBidInfo(_Amount,0,block.timestamp,true);
         emit bid(msg.sender, _Amount);
     }

     modifier check(uint _amountRevealed){
         require(keccak256(abi.encodePacked(_amountRevealed))==userBiddes[msg.sender].amountHashed,"HashingMethod:you did not bid this amount");
         _;
     }

     function Reveal(uint _amountRevealed) external check(_amountRevealed){
         userBiddes[msg.sender].amountRevealed=_amountRevealed;
         if(_amountRevealed>_highestBid){
             _highestBid=_amountRevealed;
             _highestBidder=msg.sender;
         }
         emit reveal(msg.sender, _amountRevealed);
     }

     function isUserBid(address _User) external view returns(bool){
         return userBiddes[_User].isBid;
     }

     modifier bidClosed(){
         require(block.timestamp> bidClossingTime,"HashingMethod:bidding time is not over yet");
         _;
     }

     function getHighestBid() external view bidClosed() returns(uint){
         return _highestBid;
     }

      function getHighestBider() external view bidClosed() returns(address){
         return _highestBidder;
     }

     function getTimeLeft() external view returns(uint){
        uint timeRemain=bidClossingTime -block.timestamp;
         return timeRemain;
     }

     function getAmountHashed(address _user) external view returns(bytes32){
         return userBiddes[_user].amountHashed;
     }

 }