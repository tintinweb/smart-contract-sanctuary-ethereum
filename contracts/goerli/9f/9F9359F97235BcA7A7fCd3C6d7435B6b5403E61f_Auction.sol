/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

pragma solidity >=0.8.0 <0.9.0;

contract Auction {
    address private owner;
    uint public startTime;
    uint public endTime;
    mapping(address => uint) public bids;

    struct House {
        string houseType;
        string houseName;
        string houseColor;
    }

    struct HighestBid{
        uint amount;
        address bidder;
    }

    House public newHouse;
    HighestBid public highestBid;

    constructor() {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp +24 hours;
        newHouse.houseColor = "#000000";
        newHouse.houseName = "My house";
        newHouse.houseType = "Townhouse";
    }

    event LogBid(address indexed _highestBidder, uint256 _highestBid);
    event LogWithdrawal(address indexed _withdrawer, uint256 amount);

    modifier isOngoing {
        require(block.timestamp < endTime, 'Task is over');
        _;
    }

    modifier notOngoing {
        require(block.timestamp >= endTime, 'Task still continuing');
        _;
    }

    modifier isOwner {
        require(owner == msg.sender, 'Only owner can perform task.');
        _;
    }


    modifier isNotOwner {
        require(owner != msg.sender, 'Owner is not allowed to bid.');
        _;
    }


    function makeBid() public payable isOngoing() isNotOwner()  returns(bool) {
        uint amount = bids[msg.sender] + msg.value;
        require(amount > highestBid.amount,"Bid error: Make a higher Bid.");
        highestBid.amount = amount;
        highestBid.bidder = msg.sender;
        bids[msg.sender] = amount;
        emit LogBid(highestBid.bidder, highestBid.amount);
        return true;
    }

    function withdraw() public notOngoing() isOwner()  returns(bool){
        uint amount = highestBid.amount;
        address bidder = highestBid.bidder;
        bids[highestBid.bidder] = 0;
        highestBid.bidder = address(0);
        highestBid.amount = 0;
        (bool success,) = payable(owner).call{value:amount}("");
        require(success, 'Withdrawal failed.');
        emit LogWithdrawal(bidder, amount);
        return true;
    }

    function fetchHighestBid() public view returns(HighestBid memory) {
        HighestBid memory _bidder = highestBid;
        return _bidder;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

}