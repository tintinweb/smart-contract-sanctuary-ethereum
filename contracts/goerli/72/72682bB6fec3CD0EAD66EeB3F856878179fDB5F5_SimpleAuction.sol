/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// This is a simple auction smart contract
// It supports 3 basic features:
// - bid: where a user can place a bid for the item on the auction
// - withdraw: where a user can withdraw there money back from the contract,
// - auctionEnd: end an auction and transfer the highestBid amount to the beneficiary
contract SimpleAuction {
    address payable public beneficiary; // address of the beneficiary
    uint256 public auctionEndTime; // end time of auction
    address public highestBidder; // the address of the highest bidder
    uint256 public highestBid; // the value of the highest bid
    mapping(address => uint256) pendingReturns; // a list of address and their corresponding bid
    bool ended; // a boolean value of whether the auction has ended

    // * ADDITION * //

    uint256 minBid;
    uint256 minIncrement;
    bool received; // a boolean value of whether the bidder has received the item
    bool blockWithdrawal; // block the bid winner from withdrawing the bid

    // * ADDITION * //

    // event that can be subscribed to listen to when emitted
    // they return the arguments embedded in the envent
    // in this case the value are bidder address and the bid amount
    // this allow for software to listen to the event and respond in real time
    // when there is an important change
    event HighestBidIncreased(address bidder, uint256 amount); // Alert a new highest bid
    event AuctionEnded(address winner, uint256 amount); // Alert that the auction has ended

    // constructor is used to initiallized the value of the smart contract
    // in this case it set the value of the beneficiary
    // and the auctionEndTime which are value that should exist
    // at the start of the smart contract
    // in 0.7 and above, constructor does not need to specify the visibility anymore
    constructor(
        uint256 _biddingTime,
        address payable _beneficiary,
        uint256 _minBid,
        uint256 _minIncrement
    ) {
        beneficiary = _beneficiary; // the address of the beneficiary
        auctionEndTime = block.timestamp + (_biddingTime * 1 seconds); // take the sum at the start time + the total bidding time
        // now is deprecated and replaced with block.timestamp

        // * ADDITION * //

        minBid = _minBid;
        minIncrement = _minIncrement;

        // * ADDITION * //
    }

    // the bid function allow a user to place a new bid in the auction
    function bid() public payable {
        // require ensure that the bid is valid first before proceeding
        // with adding the user to the lid of bidder
        // it has to makre sure the auctions has not ended
        // and it has to make sure that the new bid value is higher than the highest bid
        require(block.timestamp <= auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

        // * ADDITION * //

        require(
            msg.value >= minBid,
            "You must bid higher than the minimum bid."
        );

        require(
            highestBid - msg.value >= minIncrement,
            "Your bid increment must be higher than the minimum increment."
        );

        // * ADDITION * //

        if (highestBid != 0) {
            // if the highest bid is not 0
            // we map the bidder address to the bid
            // and store it in the pendingReturns list
            // to keep track of the amount that each bidder put in
            // to return to them after the auction ended
            // if they fail to get the item
            pendingReturns[highestBidder] += highestBid;
        }

        // save the highestBidder info
        highestBidder = msg.sender;
        highestBid = msg.value;
        // emit the HighestBidIncreased event
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // The withdraw function allow user to withdraw
    // the amount of bid that they have inside the contract
    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];

        if (msg.sender == highestBidder && blockWithdrawal) {
            return false;
        }

        if (amount > 0) {
            // if the amount is more than 0
            // we set the amount back to 0
            // to prevent spamming of return
            // before the first return is processed
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                // the transfer is triggered above
                // if the transfer fail indicate by the !
                // it will just reset the pendingReturns amount
                // because the transfer fail
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // * ADDITION * //

    function getConfirmation() public {
        require(msg.sender == highestBidder, "You are not the auction winner");
        require(!received, "Received confirmation has already been called");
        received = true;
    }

    // * ADDITION * //

    // End the auction and send the highest bid to the beneficiary
    function auctionEnd() public {
        // check if the auction time has ended
        // and if the auction end has already been called
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // set the ended variable to true
        // to prevent people from spamming the auctionEnd
        // to claim multiple ether pay out
        ended = true;
        blockWithdrawal = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function releaseBid() public {
        require(msg.sender == beneficiary, "You are not the beneficiary");
        require(received, "The bidder has not confirmed receival of goods");
        beneficiary.transfer(highestBid);
    }
}