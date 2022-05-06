/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// File: BidderContract_flat.sol


// File: BidderContract.sol

//SPDX-License-Identifier : MIT

pragma solidity ^0.5.0;

contract Bidder {
    
string public name;
uint public bidAmount = 20000;
bool public eligible;
uint constant minBid = 1000;

function setName(string memory newName) public {
    name = newName;
}

function setBidAmount (uint newBidAmount) public{
    bidAmount = newBidAmount;
}

function determineEligibility() public {

    if(bidAmount>=minBid){
        eligible = true;
    }else {
        eligible = false;
    }
}
 
}