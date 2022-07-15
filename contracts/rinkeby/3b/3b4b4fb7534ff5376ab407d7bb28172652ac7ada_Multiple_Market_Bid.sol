// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Multiple_Collection.sol";
import "./admin.sol";

contract Multiple_Market_Bid {

    address public owner;

    uint marketItemId=1;
    uint public bidCounter = 1;

    struct MarketItems{
        address collectionAddress;
        address payable seller;
        uint nft_id;
        uint nft_price;
        uint quantityOnSale;
    }

    struct MarketItemTimeManagement{
        bool started;
        bool ended;
        uint startAt;
    } 

    struct Bids{
        uint itemId;
        address addressData;
        uint amount;
        uint wei_service_fee;
        uint quantity;
        bool status;
    }

    Multiple_Collection erc;
    Admin admin;

    mapping(uint => Bids) public bids;

    mapping(uint => MarketItemTimeManagement) itemTime;

    mapping(uint => MarketItems) item;

    mapping(string=>bool)hash;

    modifier ifHashExist(string memory _hash) {
    require(hash[_hash]==false,"NFT Already Exists");
    _;
    }

    event itemId(uint);
    event bidId(uint);

    constructor() 
    {
        owner = msg.sender;
    }

function setupAdmin(address _address)public{
    require(owner==msg.sender,"Access Denied");
    admin = Admin(_address);
}



//----------------------Sale------------------------

    function createMarketItem(address _collectionAddress, uint _nftId, uint _quantity) public {
        require(admin.getServiceFee()>0,"Please setup service fee");
        require(admin.getServiceFeeReceiver()!=address(0),"Please setup service fee Receiver");
        erc = Multiple_Collection(_collectionAddress);
        uint balanceOf = erc.balanceOf(msg.sender,_nftId);

        require(!itemTime[marketItemId].started, "Already started!");
        require(_quantity<=balanceOf, "No Sufficient Balance To Start Sale");

           
        itemTime[marketItemId].startAt = block.timestamp;

        item[marketItemId].nft_price = 0;
        item[marketItemId].nft_id = _nftId;

        item[marketItemId].seller = payable(msg.sender);
       
        item[marketItemId].quantityOnSale = _quantity;
        item[marketItemId].collectionAddress = _collectionAddress;

        itemTime[marketItemId].started = true;
        itemTime[marketItemId].ended = false;

        emit itemId(marketItemId);

        marketItemId +=1;
    }    

   
    function bid(uint _itemId, uint _quanity, uint wei_service_fee) external payable {

        
        require(msg.value >= (item[_itemId].nft_price * _quanity),"Check Buy amount..!!");
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value>=item[_itemId].nft_price, "Amount is less than actual NFT Price");
        require(item[_itemId].quantityOnSale>0,"NFT already Soldout");
        require(_quanity<=item[_itemId].quantityOnSale,"Please enter quantity less then Sale");
    
       
    

        bids[bidCounter].itemId = _itemId;
        bids[bidCounter].addressData = msg.sender;
        bids[bidCounter].amount = msg.value;
        bids[bidCounter].wei_service_fee = wei_service_fee;

        bids[bidCounter].quantity = _quanity;
        bids[bidCounter].status = false;

        emit bidId(bidCounter);

        bidCounter +=1;
    }

    function upgrade_bid(uint _bid_id, uint _nft_quantity, uint extra_wei_service_fee) public payable{
        require(bids[_bid_id].addressData == msg.sender,"Access Denied");
        require(bids[_bid_id].status == false,"Bid Already Accepted/Withdrawan");
        bids[_bid_id].amount += msg.value;
        bids[_bid_id].wei_service_fee += extra_wei_service_fee;
        bids[_bid_id].quantity = _nft_quantity;
    }

    function acceptBid(uint _bidId) public{
        uint _itemId = bids[_bidId].itemId;
        uint _quanity = bids[_bidId].quantity;

        require(msg.sender==item[_itemId].seller,"Your are not a Owner");
        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Auction already ended!");
        require(bids[_bidId].status == false,"Bid already has Withdrawn/Accepted");
        require(_quanity <= item[_itemId].quantityOnSale,"Not Enough NFTs on Sale");


        address _collectionAddress = item[_itemId].collectionAddress;
        erc = Multiple_Collection(_collectionAddress);

        bids[_bidId].status = true;
        address winner_address = bids[_bidId].addressData;
        uint winner_amount = bids[_bidId].amount - bids[_bidId].wei_service_fee;
        uint winner_quantity = _quanity;

//--------Calculate Platform Fee/Service Fee

        uint transferHighestAmount = (winner_amount * admin.getServiceFee())/100000000000000000000;
       
        
        payable(admin.getServiceFeeReceiver()).transfer(transferHighestAmount);
        payable(admin.getServiceFeeReceiver()).transfer(transferHighestAmount);
        
//--------Calculate Platform Fee/Service Fee

//-----------Calculate Royalty Amount------------

        uint finalAmountToTransfer = transferRoyalty(_itemId, winner_amount);

//-----------Calculate Royalty Amount------------

            payable(item[_itemId].seller).transfer(finalAmountToTransfer - transferHighestAmount);

           
            item[_itemId].quantityOnSale -=_quanity;
            //transfering Ownership
            erc.transfer(item[_itemId].seller,winner_address, item[_itemId].nft_id,winner_quantity);
            
            if(item[_itemId].quantityOnSale==0)
            {
                removeFromSale(_itemId);
            }
    }

    function transferRoyalty( uint _itemId,uint amountToTransfer) internal returns(uint){
            address _collectionAddress = item[_itemId].collectionAddress;
            erc = Multiple_Collection(_collectionAddress);
            uint nft_id = item[_itemId].nft_id;
            address temp_user_transfer = erc.artistOfNFT(nft_id);
            uint royalty = erc.getRoyaltyOfNFT(item[_itemId].nft_id);
            uint roylaty_amount = (amountToTransfer * royalty) / 100000000000000000000;

            payable(temp_user_transfer).transfer(roylaty_amount);

            uint finalAmountToTransfer = amountToTransfer - roylaty_amount;
            return finalAmountToTransfer;
    }

    function removeFromSale(uint _itemId) public payable {
    
        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Auction already ended!");

            item[_itemId].nft_id = 0;
            itemTime[_itemId].ended = true;
            itemTime[_itemId].started = false;
            item[_itemId].seller = payable(address(0));
    }
    
    function withdrawBid(uint _bidId) external {
        require(bids[_bidId].addressData == msg.sender,"Access Denied");
        require( bids[_bidId].status == false,"Bid Already Accepted/Withdrawan");
        bids[_bidId].status = true;
        payable(msg.sender).transfer(bids[_bidId].amount);
    }

//----------------------------------Sale-----------------------------------------



//-------Return Contract Ether Balance
function ETH() public view returns(uint){
         return address(this).balance;
}

function itemDetails(uint _itemId) public view returns(address, address,uint, uint,uint)
{
    return(
        item[_itemId].collectionAddress,
        item[_itemId].seller,
        item[_itemId].nft_id,
        item[_itemId].nft_price,
        item[_itemId].quantityOnSale
    );
}

function BidDetails(uint bid_id) public view returns(uint,address, uint,uint, bool)
{
    return(
        bids[bid_id].itemId,
        bids[bid_id].addressData,
        bids[bid_id].amount,
        bids[bid_id].quantity,
        bids[bid_id].status
    );
}

}