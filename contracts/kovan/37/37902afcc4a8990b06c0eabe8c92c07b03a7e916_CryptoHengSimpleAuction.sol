/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//CryptoHeng公开拍卖合约
contract CryptoHengSimpleAuction {
    //受益人
    address payable public beneficiary;
    //拍卖结束时间
    uint public auctionEndTime;
    //出价最高者地址
    address public highestBidder;
    //出价最高价格
    uint256 public highestBid;
    //地址对应的出价记录映射,用以退款
    mapping(address => uint) public pendingReturns;
    //拍卖是否结束
    bool ended;

    //最高出价变化事件
    event HighestBidIncreased(address bidder, uint amount);
    //拍卖结束事件
    event AuctionEnded(address winner, uint amount);

    //错误：拍卖已结束
    error AuctionAlredayEnded();
    //错误：出价不够高
    error BidNotHighEnough(uint highestBid);
    //错误: 拍卖尚未结束
    error AuctionNotYetEnded();
    //错误: 拍卖结束函数已经被执行过
    error AuctionEndAlreadyCalled();

    constructor(uint auctionTime, address payable setBeneficiary){
        auctionEndTime = block.timestamp + auctionTime;
        beneficiary = setBeneficiary;
    }

    //出价
    function bid() external payable {
        //检查拍卖是否结束
        if(block.timestamp > auctionEndTime || ended){
           revert AuctionAlredayEnded();
        }

        //检查出价
        if(msg.value <= highestBid){
            revert BidNotHighEnough(highestBid);
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        
        //出价只要大于0且是最高价格，就记录到待返回中竞拍失败后返回给用户
        if(highestBid > 0){
            pendingReturns[msg.sender] += highestBid;
        }
        
        //发送最高出价变化事件
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// 撤销出价过高的出价。
    function withdraw() external returns (bool){
        uint amount = pendingReturns[msg.sender];
        if(amount > 0){
            if(msg.sender == highestBidder){
                //当前提款人为最高出价者，将锁定最高出价，只退还之前作废的出价，防止恶意出价，再提取的非法操作
                pendingReturns[msg.sender] = highestBid;
                amount -= highestBid;
            }else{
                pendingReturns[msg.sender] = 0;
            }
        }

        if(!payable(msg.sender).send(amount)){
            pendingReturns[msg.sender] = amount;
            return false;
        }
        return true;
    }

    ///拍卖结束
    function auctionEnd() external {
        if (block.timestamp < auctionEndTime){
            revert AuctionNotYetEnded();
        }
            
        if (ended){
            revert AuctionEndAlreadyCalled();
        }

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }


}