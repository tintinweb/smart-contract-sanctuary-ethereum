pragma solidity >=0.7.3;

contract Auction {

    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    address payable public highestBidder;
    uint bidIncrement;

    // Creating hash tables for storing information
    uint public highestBindingBid;
    mapping(address => uint) public bids;
    address _owner;


	// Constructor
	constructor() {	
        highestBindingBid = 0;
        highestBidder = payable(msg.sender);
        _owner = payable(msg.sender);
        auctionState = State.Running;

        startBlock = block.number;
        endBlock = startBlock + 10;
        ipfsHash = "";
        bidIncrement = 1; // bidding in multiple of ETH
    }

    function min(uint a, uint b) pure internal returns(uint){
        if (a <= b){
            return a;
        }else{
            return b;
        }
    }
		
    // Function to place a bid
    function placeBid(uint currentBid) public payable returns(bool){
        require(auctionState == State.Running);
        require(block.number >= startBlock);
        require(block.number <= endBlock);
        // minimum value allowed to be sent
        // require(msg.value > 0.0001 ether);
        
        
        
        // the currentBid should be greater than the highestBindingBid. 
        // Otherwise there's nothing to do.
        require(currentBid + bidIncrement > highestBindingBid);
        
        // updating the mapping variable
        bids[msg.sender] = currentBid;
        
        if (currentBid <= bids[highestBidder]){ // highestBidder remains unchanged
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }else{ // highestBidder is another bidder
             highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
             highestBidder = payable(msg.sender);
        }
    return true;
    }

    function cancelAuction() public {
        require(block.number <= endBlock);
        require(msg.sender == _owner);
        auctionState = State.Canceled;
    }


}