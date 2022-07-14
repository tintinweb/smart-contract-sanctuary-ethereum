pragma solidity >=0.7.3
;

contract Auction {

    // Create a structure to store information about an item in the auction house
	struct Item{			
		uint id;
        uint bidIncrement;
        bool ended;
    }

    // Creating hash tables for storing information
    address HighestBidder;
    uint public high;
    uint second;
    mapping(address => uint) public bids;
    Item item;
    address _owner;

	// Constructor
	constructor() {	
        item = Item(1, 1, false);
        high = 0;
        second = 0;
        _owner = msg.sender;
    }
		
    // Function to place a bid
    function placeBid (uint _bidAmt) public {
        require(item.ended == false);
        if (_bidAmt > high) {
            second = high;
            high = _bidAmt;
            HighestBidder = msg.sender;
        }	
        bids[msg.sender] = _bidAmt;
    }

    function endAuction() public {
        require(msg.sender == _owner);
        item.ended = true;
    }

}