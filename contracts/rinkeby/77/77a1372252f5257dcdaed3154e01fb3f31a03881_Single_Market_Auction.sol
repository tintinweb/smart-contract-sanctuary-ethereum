// SPDX-License-Identifier: none
pragma solidity ^0.8.0;

import './Single_Collection.sol';
import './admin.sol';

contract Single_Market_Auction{

    Admin admin;

    address public owner;

    uint marketItemId=1;

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
        uint endAt;
    } 

    mapping(uint=>address)collectionAddress;

    mapping(uint => MarketItemTimeManagement) itemTime;

    mapping(uint => MarketItems) item;

    mapping(address => uint) public bids;

    constructor (){
        owner = msg.sender;
    }

    function setupAdmin(address _address)public{
    require(owner==msg.sender,"Access Denied");
    admin = Admin(_address);
    }

//----------------------------------Auction-----------------------------------------

    function createMarketItem(address _collectionAddress, uint _nftId, uint _startAt, uint _endAt, uint min_bid_amount) public {
        require(admin.getServiceFee()>0,"Please setup service fee");
        require(admin.getServiceFeeReceiver()!=address(0),"Please setup service receiver");
        uint _itemId = marketItemId;
        marketItemId+=1;
        require(!itemTime[_itemId].started, "Already started!");
        
        Single_Collection erc = Single_Collection(_collectionAddress);

        address ownerOf = erc.ownerOf(_nftId);

        require(msg.sender==ownerOf,"Your are not a Owner");

        itemTime[_itemId].startAt = _startAt;
        itemTime[_itemId].endAt = _endAt;
        itemTime[_itemId].started = true;
        itemTime[_itemId].ended = false;

        collectionAddress[_itemId] = _collectionAddress;
        item[_itemId].highestBid = min_bid_amount;
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


    function bid(uint _itemId, uint wei_service_fee) external payable {
        // require(block.timestamp>=itemTime[_itemId].startAt,"Auction is Not Started");
        // require(block.timestamp<=itemTime[_itemId].endAt,"Auction is over. Please end the Auction");
        require(msg.sender != item[_itemId].highestBidder,"You are already Highest Bidder");
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value > item[_itemId].highestBid,"Please enter amount greater than Previous Bid");
        
        uint lastMinCal = block.timestamp - itemTime[_itemId].endAt;

        if(lastMinCal<=600)
        {
            itemTime[_itemId].startAt+=600;
        }

        if(bids[msg.sender] == 0)
        {
            item[_itemId].paidBidders.push(msg.sender);
        }
        
        item[_itemId].highestBid = msg.value - wei_service_fee;
        item[_itemId].highestBidder = msg.sender;

        bids[msg.sender] += msg.value;
    }

    function end(uint _itemId) external {
        // require(block.timestamp>=itemTime[_itemId].startAt,"Auction is Not Started");
        // require(block.timestamp>=itemTime[_itemId].endAt,"Auction is Not Over Yet. Please Wait..!!");
        address _collectionAddress = collectionAddress[_itemId];
        Single_Collection erc = Single_Collection(_collectionAddress);
        address ownerOf = erc.ownerOf(item[_itemId].nft_id);
        require(msg.sender==ownerOf,"Your are not a Owner");
        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Auction already ended!");

//--------Calculate Platform Fee/Service Fee

            uint service_fee = (item[_itemId].highestBid * admin.getServiceFee()) / 100000000000000000000;
            
            payable(admin.getServiceFeeReceiver()).transfer(service_fee);
            payable(admin.getServiceFeeReceiver()).transfer(service_fee);

            bids[item[_itemId].highestBidder] -= service_fee;

//--------Calculate Platform Fee/Service Fee

            uint finalAmountToTransfer = transferRoyalty(_itemId, item[_itemId].highestBid);

            payable(item[_itemId].seller).transfer(finalAmountToTransfer - service_fee);

            bids[item[_itemId].highestBidder] -= item[_itemId].highestBid;
            
            for(uint i=0;i<item[_itemId].paidBidders.length;i++)
            {
                payable(item[_itemId].paidBidders[i]).transfer(bids[item[_itemId].paidBidders[i]]);
            }

            erc._transfer(
            item[_itemId].seller,
            item[_itemId].highestBidder, 
            item[_itemId].nft_id
            );

            reset(_itemId);
    }


//----------------------------------Auction-----------------------------------------

function reset(uint _itemId) internal{

    delete item[_itemId].paidBidders;
    itemTime[_itemId].ended = true;
    itemTime[_itemId].started = false;
    item[_itemId].seller = payable(address(0));

}

function transferRoyalty(uint _itemId,uint amountToTransfer)internal returns(uint){
            address _collectionAddress = collectionAddress[_itemId];
            Single_Collection erc = Single_Collection(_collectionAddress);

            address temp_user_transfer = erc.artistOfNFT(item[_itemId].nft_id);

            uint roylaty_amount = (amountToTransfer * erc.getRoyaltyOfNFT(item[_itemId].nft_id)) / 100000000000000000000;
            payable(temp_user_transfer).transfer(roylaty_amount);

            uint finalAmountToTransfer = amountToTransfer - roylaty_amount;

            return finalAmountToTransfer;
}

function removeFromSale(uint _itemId) public{
            address _collectionAddress = collectionAddress[_itemId];
            Single_Collection erc = Single_Collection(_collectionAddress);
            address ownerOf = erc.ownerOf(item[_itemId].nft_id);

            require(msg.sender==ownerOf,"Your are not a Owner");
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

}