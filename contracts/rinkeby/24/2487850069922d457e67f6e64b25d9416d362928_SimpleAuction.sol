/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

pragma solidity ^0.4.11;

contract SimpleAuction {
    // Auction parameters. Times are either
    // in the format of unix timestamps (seconds that have passed since 1970-01-01)
    // or a time period in seconds.
    address public beneficiaryAddress;
    uint public auctionClose;

    // Current state of the auction.
    address public topBidder;
    uint public topBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) returnsPending;

    // Will be set true once the auction is complete, preventing any further change
    bool auctionComplete;

    // Events to fire when change happens.
    event topBidIncreased(address bidder, uint bidAmount);
    event auctionResult(address winner, uint bidAmount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// Create an auction with `_biddingTime`
    /// seconds for bidding on behalf of the
    /// beneficiary address `_beneficiary`.
    function SimpleAuction(
        uint _biddingTime,
        address _beneficiary
    ) {
        beneficiaryAddress = _beneficiary;
        auctionClose = now + _biddingTime;
    }

    /// You may bid on the auction with the value sent
    /// along with this transaction.
    /// The value may only be refunded if the
    /// auction was not won.
    function bid() payable {
        // No argument is necessary, all
        // information is already added to
        // the transaction. The keyword payable
        // is required so the function
        // receives Ether.

        // Revert the call in case the bidding
        // period is over.
        require(now <= auctionClose);

        // If the bid is not greater,
        // the money is sent back.
        require(msg.value > topBid);

        if (topBidder != 0) {
            // Sending the money back by simply using
            // topBidder.send(topBid) is a risk to the security
            // since it could execute a contract that is not trusted.
            // It is always preferable to let the recipients
            // withdraw their money themselves.
            returnsPending[topBidder] += topBid;
        }
        topBidder = msg.sender;
        topBid = msg.value;
        topBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw() returns (bool) {
        uint bidAmount = returnsPending[msg.sender];
        if (bidAmount > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receiving call
            // before `send` returns.
            returnsPending[msg.sender] = 0;

            if (!msg.sender.send(bidAmount)) {
                //Calling throw not necessary here, simply reset the bidAmount owing
                returnsPending[msg.sender] = bidAmount;
                return false;
            }
        }
        return true;
    }

    /// Auction ends and highest bid is sent
    /// to the beneficiary.
    function auctionClose() {
        // It is a good practice to structure functions which interact
        // with other contracts (i.e. call functions or send Ether)
        // into three phases:
        // 1. check conditions
        // 2. perform actions (potentially change conditions)
        // 3. interact with other contracts
        // If these phases get mixed up, the other contract might call
        // back into the current contract and change the state or cause
        // effects (ether payout) to be done multiple times.
        // If functions that are called internally include interactions with external
        // contracts, they have to be considered interaction with
        // external contracts too.

        // 1. Conditions
        require(now >= auctionClose); // auction did not yet end
        require(!auctionComplete); // this function has already been called

        // 2. Effects
        auctionComplete = true;
        auctionResult(topBidder, topBid);

        // 3. Interaction
        beneficiaryAddress.transfer(topBid);
    }
}