pragma solidity 0.8.10;

contract Auction{
    event Start();
    event End(address highestBidder, uint highestBid);
    event Bid(address bidder, uint newBid);
    event Withdraw(address withdrawer, uint amount);

    address payable public seller;

    bool public started;
    bool public ended;
    uint public endAt;
    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public bids;

    constructor(){
        seller = payable(msg.sender);
    }

    function start(uint startingBid) external{
        require(!started, "Already started");
        require(msg.sender == seller, "You did not start the auction");
        started = true;
        endAt = block.timestamp + 7 days;
        highestBid = startingBid;
        emit Start();
    }
    function end() external{
        require(started, "Auction not started yet!");
        require(block.timestamp >= endAt , "Not end time yet");
        require(!ended, "Auction already ended");

        ended = true;
        emit End(highestBidder, highestBid);
    }

    function bid() external payable{
        require(started, "Auction not started yet!");
        require(block.timestamp < endAt, "Auction has already ended!");
        require(!ended, "Auction has already ended");
        require(msg.value > highestBid, "Minimum bid not reached");

        highestBid = msg.value;
        highestBidder = msg.sender;

        bids[msg.sender] += highestBid;
        emit Bid(msg.sender, msg.value);
    }
    function withdraw() external payable{
        require(started, "Auction not started yet!");
        require(block.timestamp < endAt, "Auction has already ended!");
        require(!ended, "Auction has already ended");
        uint bal = bids[msg.sender];
        require(bal > 0, "Bid is empty!");
        (bool sent, bytes memory data) = payable(msg.sender).call{value:bal}("");
        require(sent, "Could not withdraw");
        bids[msg.sender] = 0;
        emit Withdraw(msg.sender, bal);
        
    }
}