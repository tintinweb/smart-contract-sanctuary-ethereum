/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity^0.6.0;

contract auction {
    address payable public seller;
    address payable public auctioneer;//拍卖师

    address payable public buyer;
    uint public auctionAmount;

    uint auctionEndTime;

    bool isFinished;

    constructor(address payable _seller, uint _duration) public {
        seller = _seller;
        auctioneer = msg.sender;
        auctionEndTime = _duration + now;
        isFinished = false;
    }

    function bid() public payable {
        require(!isFinished);
        require(now <auctionEndTime);
        require(msg.value > auctionAmount);
        if(auctionAmount > 0 && address(0)!=buyer) {
            buyer.transfer(auctionAmount);
        }
        buyer = msg.sender;
        auctionAmount = msg.value;
    }

    function auctionEnd() public payable {
        require(now >= auctionEndTime);
        require(!isFinished);
        isFinished = true;
        seller.transfer(auctionAmount);
    }
}