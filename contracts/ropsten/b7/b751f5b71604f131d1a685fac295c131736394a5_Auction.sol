/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.8.4;

contract Auction {

    //拍卖的受益人
    address payable public beneficiary;
    //拍卖的结束时间
    uint public auctionEndTime;
    // 最高出价的人
    address public highestBidder;
    // 最高出价的价格
    uint public highestBid;

    // 这个map用来存放出价的人以及对应的出价，便于拍卖结束后退还
    mapping(address => uint) pendingReturns;

    //标识拍卖结束了，一旦结束就不能改了
    bool ended;

    // 用来记录当前出价最高的事件
    event HighestBidIncreased(address bidder, uint amount);
    // 用来记录拍卖结束后
    event AuctionEnded(address winner, uint amount);

    /// 拍卖已经结束
    error AuctionAlreadyEnded();
    /// 已经有更高的出价者了
    error BidNotHighEnough(uint highestBid);
    /// 拍卖还未结束
    error AuctionNotYetEnded();
    /// auctionEnd 方法已经被调用了
    error AuctionEndAlreadyCalled();

    // 通过构造函数初始化受益人和拍卖的结束时间
    constructor(uint biddingTime, address payable beneficiaryAddress) {
        beneficiary = beneficiaryAddress;
        auctionEndTime = block.timestamp + biddingTime;
    }

    function bid() external payable {

        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();

        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] = highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {

        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }

}