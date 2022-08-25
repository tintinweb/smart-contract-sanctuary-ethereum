// SPDX-License-Identifier: GPL-3.0

//Create a function to bid
//create a function to withdraw if there balance is less compared to next bid
pragma solidity >=0.7.0 <0.9.0;
error NotHighestBid();
error AuctionHasEnded();
error YouareTheHighestBidder();
error unableToSendMoney();
error AuctionNotEnded();


contract SimpleAuction{
    uint public highestBid;
    uint public auctionTime;
    address public highestBidder;
    address payable public beneficary;
    uint public numberCounter;
    mapping(uint => mapping(address => uint)) public pendingBalance;

    event BidWasSucessFull(address sender,uint _value);

    constructor(address payable _beneficary , uint _auctionEnd){
        beneficary = payable(_beneficary);
        auctionTime = _auctionEnd;
    }


    function Bid() public payable {
        if(msg.value <= highestBid ){
            revert NotHighestBid();
        }
        if(block.timestamp > auctionTime){
            revert AuctionHasEnded();
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit BidWasSucessFull(msg.sender,msg.value);
    }
    function withdraw() external returns(bool){
          uint amount = pendingBalance[numberCounter][msg.sender];    
            pendingBalance[numberCounter][msg.sender] = 0;
            payable(msg.sender).transfer(amount);
            return true;
    }
    function toBeneficary() public {
        if(block.timestamp<=auctionTime){
            revert AuctionNotEnded();
        }
        (bool sucess,) = beneficary.call{value:highestBid}("");
        if(!sucess) revert unableToSendMoney();
    }

    function reset(address payable _beneficary , uint _auctionEnd) public {
        if(block.timestamp<=auctionTime)
        revert AuctionNotEnded();
        beneficary  = payable(_beneficary);
        auctionTime = _auctionEnd;
        numberCounter += 1;
        pendingBalance[numberCounter][address(0)] = 0;
    }

    function AuctionRet() public view  returns (uint) {
        return auctionTime;
    }
    
}