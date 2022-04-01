/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract BiddingContract {
    
    uint startTime = 0;
    uint endTime = 0;
    address payable public ownerAdress;
    enum BidStatus { Active, Inactive, Ended }
    BidStatus bidStatus;

    uint public highestBid = 0;
    address payable public highestBidder;

    mapping(address => uint) users;

    constructor () {
        ownerAdress = payable(msg.sender);
        bidStatus = BidStatus.Inactive;
    }

    modifier checkOwner () {
        require(msg.sender == ownerAdress, "Only owner is authorized");
        _;
    }

    modifier checkTime () {
        if (block.timestamp >= endTime) {
            bidStatus = BidStatus.Inactive;
        }
        _;
    }

    modifier checkStatus () {
        require(bidStatus == BidStatus.Active, "Bidding is Not Active");
        _;
    }

    modifier checkBid () {
        require(users[msg.sender]==0, "Already bid");
        _;
    }

    modifier checkIfTimePassed () {
        require(block.timestamp >= endTime, "Bidding is still Active");
        _;
    }

    function startBidding (uint timeInMinutes) public checkOwner checkTime {
        require(bidStatus != BidStatus.Active, "Bid is Already Active");
        bidStatus = BidStatus.Active;
        startTime = block.timestamp;
        endTime = startTime + ( timeInMinutes * 60 );
    }

    function checkBidStatus () public view returns(string memory) {
        if (bidStatus == BidStatus.Active && (block.timestamp < endTime)) {
        return "Bidding is Active";
        } else {
        return "Bidding is Not Active";
        }
    }

    function bid () public payable checkTime checkStatus {
        users[msg.sender] = msg.value;

        if (highestBid == 0) {
            if (msg.value > highestBid) {

                highestBid = msg.value;
                highestBidder = payable(msg.sender);
            }
        } else {
            if (msg.value > highestBid) {
                highestBidder.transfer(highestBid);
                highestBid = msg.value;
                highestBidder = payable(msg.sender);
            }
        }
    }

    function showWinner () public checkIfTimePassed view returns(address) {
        return address(highestBidder);
    }

    function endBid () public checkOwner checkIfTimePassed {
        ownerAdress.transfer(highestBid);
        bidStatus = BidStatus.Ended;

    }

    function destroyContract () public checkOwner checkIfTimePassed {
        selfdestruct(ownerAdress);
    }
}