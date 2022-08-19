// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9; 

/**
 * what is the scope of this project?
 * Build a aunction for an ecommerce website
 * This aunction is to have a start time, end time, can be cancelled, and once it has ended, persons who participated in the auntion will request for their money.
 * What are the things we are considering"
 * a. construtor, an enum to indicate to us when the aunction commences or otherwise,
 * b. a function to indicate deposits for the aunction
 * c. a function to increase the bids, to help us identify the highest bidder.
 * d. a function to allow participants to rewuest for their ether once the aunction is over.
 * e. let's see if we can deploy and create a smart contract to interact with our contract.
 * f. use a modifier to further ensure code reusability
 */

contract Aunction {

    address payable public owner;
    uint public aunctionStartBLock;
    uint public aunctionEndBLock;
    string public ipfsHash;
    enum State {started, running, cancelled, completed}
    State public auctionState;

    uint public highestBindingBid;
    address payable highestBidder;
    mapping(address => uint) public validBids;

    uint bidIncrements;

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.running;
        aunctionStartBLock = block.number;
        aunctionEndBLock = aunctionStartBLock + 40320;
        ipfsHash = "";
        bidIncrements = 0.1 ether;

    }

    // this is a modifier to guide against redundant code

    modifier onlyOnwer() {
        require(owner == msg.sender, "You are not the Valid Owner");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "Owner cannot participate in Aunction");
        _;
    }

    modifier afterAnctionStarts() {
        require(block.number >= aunctionStartBLock, "Aunction has commenced");
        _;
    }

    modifier beforeAunctionEnd() {
        require(block.number <= aunctionEndBLock, "Anction has Ended");

        _;
    }

    // Should after deployment we desire to change the owner, this can help

    function changeOwner(address payable _changedOwner) public {
        owner = _changedOwner;
    }

    // To calculate the minimum bid between participants, we need a helper function
    //  this helper function as the name implies merely helps the major function.

    function minBid(uint one, uint two) pure internal returns (uint) {
        if (one >= two) {
            return one;
        } else {
            return two;
        }

    }

    function placeEarlyBid() public payable notOwner afterAnctionStarts beforeAunctionEnd {
        require(auctionState == State.running, "Sorry you can't join, Aunction has commenced");
        require(msg.value >= 0.1 ether, "Your bid is too low");

        uint currentBids = validBids[msg.sender] + msg.value;
        require(currentBids > highestBindingBid, "Binding Bid Higher than your current Bid");
        validBids[msg.sender] = currentBids;

        if (currentBids <= validBids[highestBidder]) {
            highestBindingBid = minBid(currentBids + bidIncrements, validBids[highestBidder]);
        } else {
            highestBindingBid = minBid(currentBids, validBids[highestBidder] + bidIncrements);
            highestBidder = payable(msg.sender);
        }

    }

    function cancelAunction() public onlyOnwer {
        auctionState = State.cancelled;

    }

    function endAuction() public {
        require((auctionState == State.cancelled || block.number > aunctionEndBLock));
        require(msg.sender == owner || validBids[msg.sender] > 0, "Auction Ended");

        address payable recipient;
        uint bidValueDeposited;

        if(auctionState ==  State.cancelled) {
            recipient = payable(msg.sender);
            bidValueDeposited = validBids[msg.sender];

        } else {
            
            if (msg.sender == owner) {
                recipient == owner;
                bidValueDeposited = highestBindingBid;
            } else {

                if(msg.sender == highestBidder) {
                    recipient = highestBidder;
                    bidValueDeposited = validBids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    bidValueDeposited = validBids[msg.sender];
                }

            }
        }

// TO prevent reenterancy attack, do well to update the balance of the resipient before transferring the sum
        validBids[recipient] = 0;
        recipient.transfer(bidValueDeposited);

    }





}