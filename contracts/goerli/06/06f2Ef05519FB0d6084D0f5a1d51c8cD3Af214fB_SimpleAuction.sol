/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// define the solidity version
pragma solidity >=0.4.22 <0.6.0;

//create our contract
contract SimpleAuction {
    // define the beneficiary variable, and make publically available
    address payable public beneficiary;
    // define the end time variable of the auction and also make publically available
    uint public auctionEndTime;
    // define the highest bidder variable and make publically available
    address public highestBidder;
    // define highest bid variable and make publically available
    uint public highestBid;
    // define a list of pending returns, do not make publically available (this doesn't mean it's secret, it only means that it cannot be used for other contracts)
    mapping(address => uint) pendingReturns;
    // define ended variable, do not make publically available (this doesn't mean it's secret, it only means that it cannot be used for other contracts)
    bool ended;
    
    //define variable for the minimum bid
    uint public minBid; //in wei
    
    //define variable for the minimum increment
    uint public minIncrement; //in wei
    
    //define variable that specifies if the beneficiary has already been payed out
    bool public payedOut = false;

    //define events for user machines to easily be able to react to certain actions (this helps with integration in, for example, a webpage)
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    //define the constructor, this will only be run by the person who publishes the contract at the time that the contract is published
    //this constructor sets the bidding time and beneficiary address to the values given
    constructor(
        //require bidding time and the beneficiary to be known at the time the contract is published
        uint _biddingTime, 
        address payable _beneficiary,
        uint _minBid, //in wei
        uint _minIncrement //in wei
    ) public {
        //set the global variables accordingly
        beneficiary = _beneficiary;
        auctionEndTime = now + _biddingTime;
        minBid = _minBid;
        minIncrement = _minIncrement;
    }

    //the bid function can be called by anyone, and it is possible to put money into the contract when calling this function
    //this function allows anyone to bid more then the previous highest bid if the auction is still ongoing
    //it has been extended to only allow more then the minimum bid and minimum increment
    function bid() public payable {
        //cancel the transaction if the auction has already ended
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );
        
        //cancel the transaction if a higher bid has already come in
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );
        
        //require more then the minimum bid
        require(
            msg.value > minBid,
            "Bid more then the minimum bid."
        );
        
        //require more then the minimum increment
        require(
            (msg.value - highestBid) > minIncrement,
            "Bid more then the minimum increment."
        );

        //if the (previous) highest bid is not 0, the previous bidder gets the value of its bid added to its pending returns (this money can be extracted with the withdraw function)
        //this way the previous bidder can get its money back
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        
        //highest bidder and highest bid varables are updated to represent the new highest bid
        highestBidder = msg.sender;
        highestBid = msg.value;
        
        //tell all clients that the highest bid has been increased
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    //the withdraw function can be called by anyone, it is not possible to put money into it
    //this function pays the caller back the money it is owed (the money it is owed is calculated in the bid function)
    function withdraw() public returns (bool) {
        //get the amount the user is owed
        uint amount = pendingReturns[msg.sender];
        //only run if the user is owed more then zero
        if (amount > 0) {
            //set the pending returns to 0
            pendingReturns[msg.sender] = 0;

            //try to send the caller the amount it is owed
            if (!msg.sender.send(amount)) {
                //if the transaction did not go trough, reset the amount owed
                pendingReturns[msg.sender] = amount;
                //tell the caller that the transaction was not successful
                return false;
            }
        }
        //tell the caller that the function ran successfully
        return true;
    }

    //if the auction time has ellapsed, but the auction has not been ended, anyone can call this function, the beneficiary does not get payed out yet. This function can only ever be called once
    function auctionEnd() public {
        //require the auction time to have been ellapsed
        require(now >= auctionEndTime, "Auction not yet ended.");
        //require the auction to not have ended (prevents function from being called multiple times)
        require(!ended, "auctionEnd has already been called.");

        //set the ended value to true to officially end the auction
        ended = true;
        //tell all users that the transaction has ended
        emit AuctionEnded(highestBidder, highestBid);
    }
    
    //payout beneficiary if highest bidder agrees
    function payOutBeneficiary() public {
        require(ended == true, "The auction has to have finished.");
        require(msg.sender == highestBidder, "Only the highest bidder can call this function.");
        require(payedOut == false, "Money has already been payed out.");
        
        payedOut = true;
        beneficiary.transfer(highestBid);
    }
    
    //return money to highest bidder if beneficiary agrees
    function payOutHighestBidder() public {
        require(ended == true, "The auction has to have finished.");
        require(msg.sender == beneficiary, "Only the beneficiary can call this function.");
        require(payedOut == false, "Money has already been payed out.");
        
        payedOut = true;
        pendingReturns[highestBidder] += highestBid;
    }
}