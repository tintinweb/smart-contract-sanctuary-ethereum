// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Single_Collection.sol';
import './admin.sol';

contract Single_Marketplace_Fixed{

    address public owner;

    uint marketItemId=1;

    Admin admin;
    
    struct MarketItems{
        address collectionAddress;
        address payable seller;
        uint nft_id;
         uint nft_price;
        uint offerAmount ;
        address offerBy;
    }

    struct MarketItemTimeManagement{
        bool started;
        bool ended;
        uint startAt;
    } 

    mapping(uint => MarketItemTimeManagement) itemTime;

    mapping(uint => MarketItems) item;

    mapping(address => uint) public orderList;

    event itemId(uint);

    constructor( ) {
      owner = msg.sender;
    }

function setUpAdmin(address _address) public{

    require(owner==msg.sender,"Access Denied");

    admin = Admin(_address);

}

function changeTheOwner(address _address)public{
    require(owner==msg.sender,"Access Denied");
    owner = _address;
}

//----------------------------------Bidding-----------------------------------------

   
    function createMarketItemFixed(address _collectionAddress, uint _nftId,uint _price) public{

        require(admin.getServiceFee()>0,"Please setup service fee");
        require(admin.getServiceFeeReceiver()!=address(0),"Please setup service fee Receiver");
        uint _itemId = marketItemId;
        marketItemId+=1;
        Single_Collection erc = Single_Collection(_collectionAddress);

        require(!itemTime[_itemId].started, "Already started!");
        
        address ownerOf = erc.ownerOf(_nftId);

        require(msg.sender==ownerOf,"Your are not a Owner");

        //--------Platform Fee/Service Fee

            //payable(admin.getServiceFeeReceiver()).transfer(wei_service_fee);

        //--------Platform Fee/Service Fee

        item[_itemId].nft_price = _price;

        
        //check for owner of nft before starting th bid

        itemTime[_itemId].startAt = block.timestamp;
        item[_itemId].collectionAddress = _collectionAddress;
        item[_itemId].nft_id = _nftId;
        item[_itemId].seller = payable(msg.sender);
       
        itemTime[_itemId].started = true;
        itemTime[_itemId].ended = false;

        emit itemId(_itemId);
    }

    function buy(uint _itemId, uint wei_service_fee) external payable {
        require(admin.getServiceFee()>0,'Please setup service fee');
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value >= item[_itemId].nft_price,"Amount is Less than Price");
        require(msg.value > item[_itemId].offerAmount, "NFT already has highest Offer..!!");

        orderList[msg.sender] = msg.value;

        address _collectionAddress = item[_itemId].collectionAddress; 
        item[_itemId].offerAmount = msg.value - wei_service_fee;
        item[_itemId].offerBy = msg.sender;

        accept(_collectionAddress,_itemId, wei_service_fee);
    }


    function accept(address _collectionAddress,uint _itemId, uint wei_service_fee) internal {
        require(admin.getServiceFee()>0,'Please setup service fee');
        Single_Collection erc = Single_Collection(_collectionAddress);

        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Auction already ended!");

        erc._transfer(item[_itemId].seller,item[_itemId].offerBy, item[_itemId].nft_id);

//--------Platform Fee/Service Fee

            payable(admin.getServiceFeeReceiver()).transfer(wei_service_fee);
            payable(admin.getServiceFeeReceiver()).transfer(wei_service_fee);

//--------Platform Fee/Service Fee



//-----------Calculate Royalty Amount------------

            address temp_user_transfer = erc.artistOfNFT(item[_itemId].nft_id);
            uint roylaty_amount = (item[_itemId].offerAmount * erc.getRoyaltyOfNFT(item[_itemId].nft_id)) / 100000000000000000000;
            payable(temp_user_transfer).transfer(roylaty_amount);
            uint finalAmountToTransfer = item[_itemId].offerAmount - roylaty_amount;

//-----------Calculate Royalty Amount------------
            payable(item[_itemId].seller).transfer(finalAmountToTransfer-wei_service_fee);

            orderList[item[_itemId].offerBy] -=item[_itemId].offerAmount;

            itemTime[_itemId].ended = true;
            itemTime[_itemId].started = false;
            item[_itemId].seller = payable(address(0));
    }


//----------------------------------Bidding-----------------------------------------

function removeFromSale(uint _itemId) public{
            require(admin.getServiceFee()>0,'Please setup service fee');
            require(itemTime[_itemId].started, "You need to start first!");
            itemTime[_itemId].ended = true;
            itemTime[_itemId].started = false;
            item[_itemId].seller = payable(address(0));
}


function itemDetailsInMarket(uint _itemId) public view returns(address,address,uint,uint,address){
    return(
        item[_itemId].collectionAddress,
        item[_itemId].seller,
        item[_itemId].nft_id,
        item[_itemId].offerAmount,
        item[_itemId].offerBy
        );
}




}