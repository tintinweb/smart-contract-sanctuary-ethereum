/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity 0.8.7;

contract auctionContract {
    
bool winnerDecleared=false;
uint startTime=block.number;
uint endTime;
uint intialBid;
uint public highestBid;
address  payable public highestBidder;
enum Status {Inactive, Active, Ended}
Status  public currentStatus;
mapping (address => uint) public bids;
address payable auctioner;

constructor(){
    auctioner=payable(msg.sender);
    currentStatus= Status.Inactive;

}

function startAuction(uint _endtime, uint _intialBid) public returns(string memory){
    require( msg.sender == auctioner," only owner can start");
    require( currentStatus != Status.Active , " already started");
    currentStatus=Status.Active;
    startTime = block.number;
    endTime = startTime + _endtime;
    intialBid = _intialBid;
    return "auction started";

}
function checkStatus() public  view returns(string memory){
    if(currentStatus == Status.Active){
        return "Active";
    }
    else if(currentStatus == Status.Inactive){
        return " Inactive ";
    }
    else {
        return "Ended";
    }
}
function mybid() public view returns(uint ){
    return bids[msg.sender];
}
function setbid() public payable {
    require(currentStatus==Status.Active," Auction is not available");
    require(msg.sender!=auctioner," You are not allowed to bid" );
    require(bids[msg.sender]==0,"already given bid");
    require(msg.value > intialBid);
    require(msg.value > highestBid);
    if(block.number>= endTime){
        currentStatus= Status.Ended;
        payable(msg.sender).send(msg.value);
    }
    else{
        if(highestBid==0){
            highestBidder = payable(msg.sender);
            highestBid= msg.value;
            bids[msg.sender] = msg.value;
        }
        else{
            highestBidder.send(highestBid);
            highestBid= msg.value;
            highestBidder = payable(msg.sender);
            bids[msg.sender] = msg.value;
        }

    }

}

function declareWinner() public {
    require(msg.sender== auctioner," only owner can do this");
    require(block.number>= endTime," wait till Auction end");
    require(highestBid!=0,"No winner");
    auctioner.transfer(highestBid);
}
function showWinner() public view returns(address ){
    require(winnerDecleared==true);
    return address(highestBidder);
    
}
function destructContract() public {
    require(block.number>= endTime," wait till Auction end");
    selfdestruct(auctioner);
}
}