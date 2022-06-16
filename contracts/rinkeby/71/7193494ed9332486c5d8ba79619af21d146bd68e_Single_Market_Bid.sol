// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Single_Collection.sol';

contract Single_Market_Bid{

    address public owner;

    uint marketItemId=1;
  
    address public serviceFeeReceiver = address(0);

    uint public serviceFee = 0;

    event itemId(uint);

    struct MarketItems{
        address[] paidBidders;
        address payable seller;
        uint nft_id;

        uint highestBid;
        address highestBidder;
    }

    struct MarketItemTimeManagement{
        bool started;
        bool ended;

        uint startAt;
    } 

    mapping(uint=>address)collectionAddress;

    mapping(uint => MarketItemTimeManagement) itemTime;

    mapping(uint => MarketItems) item;

    mapping(address => uint) public bids;

    constructor (){
        owner = msg.sender;
    }

    function changeTheOwner(address _address)public{
    require(owner==msg.sender,"Access Denied");
    owner = _address;
    }

    function updateServiceFeeReceiver(address _address) public{
        require(owner==msg.sender,"Access Denied");
        serviceFeeReceiver = _address;
    }  
    
    function updateServiceFee(uint _serviceFee) public{
        require(owner==msg.sender,"Access Denied");
        serviceFee = _serviceFee;
    }


//----------------------------------Bid-----------------------------------------

    function createMarketItem(address _collectionAddress, uint _nftId) public {
        require(serviceFee>0,"Please setup service fee");
        require(serviceFeeReceiver!=address(0),"Please setup service receiver");
        uint _itemId = marketItemId;
        marketItemId+=1;
        require(!itemTime[_itemId].started, "Already started!");
        
        Single_Collection erc = Single_Collection(_collectionAddress);

        address ownerOf = erc.ownerOf(_nftId);

        require(msg.sender==ownerOf,"Your are not a Owner");

        itemTime[_itemId].startAt = block.timestamp;
     
        itemTime[_itemId].started = true;
        itemTime[_itemId].ended = false;

        collectionAddress[_itemId] = _collectionAddress;
        item[_itemId].highestBid = 0;
        item[_itemId].nft_id = _nftId;
        item[_itemId].seller = payable(msg.sender);

        emit itemId(_itemId);

    }


    function withdraw(uint _itemId) external payable {
        require(item[_itemId].highestBidder!=msg.sender, "Could not withdraw");
        require(bids[msg.sender] != 0,"No Bid amount found..!!");
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
    }

    function bid(uint _itemId) external payable {
        require(msg.sender != item[_itemId].highestBidder,"You are already Highest Bidder");
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value > item[_itemId].highestBid,"Please enter amount greater than Previous Bid");
        
        if(bids[msg.sender] == 0)
        {
            item[_itemId].paidBidders.push(msg.sender);
        }
        
        item[_itemId].highestBid = msg.value;
        item[_itemId].highestBidder = msg.sender;

        bids[msg.sender] += msg.value;
    }


    function end(uint _itemId) external {
        address _collectionAddress = collectionAddress[_itemId];
        Single_Collection erc = Single_Collection(_collectionAddress);

        require(msg.sender==item[_itemId].seller,"Your are not a Owner");
        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Bid already ended!");

        erc._transfer(
            item[_itemId].seller,
            item[_itemId].highestBidder, 
            item[_itemId].nft_id
            );

//--------Calculate Platform Fee/Service Fee

            uint  transferHighestBid = (item[_itemId].highestBid * serviceFee)/100000000000000000000;
            uint amountToTransfer = item[_itemId].highestBid - transferHighestBid;
            payable(serviceFeeReceiver).transfer(transferHighestBid);

//--------Calculate Platform Fee/Service Fee

            uint finalAmountToTransfer = transferRoyalty(_itemId, amountToTransfer);

            payable(item[_itemId].seller).transfer(finalAmountToTransfer);

            bids[item[_itemId].highestBidder] -= item[_itemId].highestBid;
            
            
            for(uint i=0;i<item[_itemId].paidBidders.length;i++)
            {
                payable(item[_itemId].paidBidders[i]).transfer(bids[item[_itemId].paidBidders[i]]);
            }
            reset(_itemId);
    }


//----------------------------------Bid-----------------------------------------

function reset(uint _itemId) internal{
    require(msg.sender==item[_itemId].seller,"Your are not a Owner");
    
    delete item[_itemId].paidBidders;
    itemTime[_itemId].ended = true;
    itemTime[_itemId].started = false;
    item[_itemId].seller = payable(address(0));
}

function transferRoyalty(uint _itemId,uint amountToTransfer)internal returns(uint){
            require(msg.sender==item[_itemId].seller,"Your are not a Owner");
            address _collectionAddress = collectionAddress[_itemId];
            Single_Collection erc = Single_Collection(_collectionAddress);

            address temp_user_transfer = erc.artistOfNFT(item[_itemId].nft_id);

            uint roylaty_amount = (amountToTransfer * erc.getRoyaltyOfNFT(item[_itemId].nft_id)) / 100000000000000000000;

            uint finalAmountToTransfer = amountToTransfer - roylaty_amount;
            payable(temp_user_transfer).transfer(roylaty_amount);

            return finalAmountToTransfer;
}

function removeFromSale(uint _itemId) public{
        itemTime[_itemId].ended = true;
        itemTime[_itemId].started = false;
        item[_itemId].seller = payable(address(0));
}

function ETH() public view returns(uint){
    return address(this).balance;
}

function itemDetailsInMarket(uint _itemId) public view returns(address[] memory,address,uint,uint,address){
    return(
        item[_itemId].paidBidders,
        item[_itemId].seller,
        item[_itemId].nft_id,
        item[_itemId].highestBid,
        item[_itemId].highestBidder
        );
}

function getSaleTimeDetails(uint _itemId)public view returns(bool, bool, uint)
{
    return(
        itemTime[_itemId].started,
        itemTime[_itemId].ended,
        itemTime[_itemId].startAt
    );
}



}