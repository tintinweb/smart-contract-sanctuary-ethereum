//SPDX-License-Identifier: Unlicense    

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator {
    Auction[] public auctions; 

    function createAuction() public{
        //create new auction
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{
    /** 
        @dev declare all state variables 
    */
    address payable public owner; 
    //declare time variables with start block and end block
    uint public startBlock;
    uint public endBlock;
    //declare string for IPFS Hash 
    string public ipfsHash;
    //List for States of running Auction
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    //declare variable for the price and the highest bid
    uint public highestBindingBid;
    address payable public highestBidder;
    //declare state variable for the add address for peoples lauching the auction
    mapping(address => uint ) public bids;
    //declare state variable for increment peoples for lauching the auction.
    uint bidIncrement;

    string public _name = "Auction";

    receive() external payable {}
    constructor(address eoa){
        owner = payable(eoa);
        auctionState = State.Running;
        //calculate the blocktime: 
        /**@dev the block on Ethereum is updated every 15 secounds*/
        startBlock = block.number; 
        // 1 week = 60*60*24*7 = 604800 / 15(secounds) = 40,320 
        endBlock = startBlock + 4;
        ipfsHash = "";
        //increment = 100 wei
        bidIncrement = 1 ether;

    }

    event AuctionCanceled();
    event EndAuction();

    //modifier for verift if msg.sender not owner
    modifier  notOwner() {
        require(msg.sender != owner); 
        _;
    }
    //modifier for verift if time is start
    modifier afterStart(){
        require(block.number >= startBlock,"Auction has not started!");
        _;
    }
    //modifier for verift if time is end 
    modifier beforeEnd(){
        require(block.number <= endBlock, "The auction has ended!");
        _;
    }
    //modifier to check if msg.sender is owner
    modifier onlyOwner(){
        require(msg.sender == owner, "The address call not is owner!");
        _;
    }

    //* function to calculate highest bid and lowest bid, 
    //* this functions is pure because not change the block (tx)
    function min(uint a, uint b) pure internal returns(uint){
        /**@dev if a < b return a value
           ->  if value = a this lance A is larger
           ->  if value = b this lance B is larger
         */
        if(a<=b){
            return a;
        }else{
            return b;
        }
    }

    function cancelAuction() public  onlyOwner  { 
       auctionState = State.Canceled;
       emit AuctionCanceled();
    }

    function placeBid() external payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100); //min 100wei
        
        uint currentBid = bids[msg.sender] + msg.value; 
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;

        if(currentBid <= highestBindingBid){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);   
        }else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function finishAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock, "The auction has not finished!");
        require(msg.sender == owner || bids[msg.sender] > 0, "You have already withdrawn your funds or you not is owner!");
    
        address payable recipient;
        uint value; 
        if(auctionState == State.Canceled){ //auction was canceled
            recipient = payable(msg.sender);
            /**@dev the bids[] is mapping value was deposit. */
            value = bids[msg.sender];
        }else{ //auction not canceled
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }else{ //this is a bidder
               if(msg.sender == highestBidder){
                   recipient = highestBidder;
                   value = bids[highestBidder] - highestBindingBid;
               }else{ // this is neither the owner nor the highestBidder
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
               }
            }
        }
        bids[recipient] = 0;
        recipient.transfer(value);
        auctionState = State.Ended;
        emit EndAuction();
    }
}