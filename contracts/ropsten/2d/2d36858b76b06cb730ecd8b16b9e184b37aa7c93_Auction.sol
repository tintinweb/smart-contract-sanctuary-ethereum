/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity >=0.7.0 <0.9.0;

contract Auction{

    address payable public Seller;
    uint public AuctionEndTime;
    address public HighestBidder;
    uint public HighestBid;

    mapping(address=> uint) public PendingReturns;
    bool ended= false;

    event HighestBidIncrease(address Bidder,uint amount);
    event AuctionEnded(address Buyer,uint amount);

    constructor(uint _biddingTime, address payable _Seller){
        Seller=_Seller;
        AuctionEndTime=block.timestamp + _biddingTime;
    }

    function bid() public payable{
        if(block.timestamp > AuctionEndTime){
            revert('The Auction has ended');
        }
        if(msg.value < 50){
            revert("Please revise and submit your bid as Minimum Bid is 50");
        }
        
        if(msg.value <= HighestBid){
            revert("Please check your bid amount as there is already a higher or equal Bid already placed!");
        }
        if(HighestBid!=0){
            PendingReturns[HighestBidder]+=HighestBid;
        }

        HighestBidder=msg.sender;
        HighestBid=msg.value;
        emit HighestBidIncrease(msg.sender,msg.value);

    }

    function withdraw() public returns(bool){
        uint amount= PendingReturns[msg.sender];
        if(amount>0){
            PendingReturns[msg.sender]=0;
            if(!payable(msg.sender).send(amount)){
                PendingReturns[msg.sender]= amount;
                return false;
            }
            return true;
        }
    }
    function AuctionEnd() public{
        if(block.timestamp <AuctionEndTime){
            revert("The Auction is still ongoing");
        }
        if(ended){
            revert("The Auction has ended");
        }
        ended=true;
        emit AuctionEnded(HighestBidder,HighestBid);
        Seller.transfer(HighestBid);
    }

}