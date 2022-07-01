// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Multiple_Collection.sol";
import "./admin.sol";

contract Multiple_Market_Fixed {

    address public owner;
    uint marketItemId=1;

    Admin admin;

    struct MarketItems{
        address[] paidUsers;
        address collectionAddress;
        address payable seller;
        uint nft_id;
        uint nft_price;
        uint offerAmount;
        address offerBy;
        uint quantityOnSale;
    }

    struct MarketItemTimeManagement{
        bool started;
        bool ended;
        uint startAt;
    } 

    Multiple_Collection erc;

    mapping(uint => MarketItemTimeManagement) itemTime;

    mapping(uint => MarketItems) item;

    mapping(address=>uint) totalOrderAmount;

    mapping(string=>bool)hash;

    modifier ifHashExist(string memory _hash) {
    require(hash[_hash]==false,"NFT Already Exists");
    _;
    }

    event itemId(uint);

    constructor() 
    {
        owner = msg.sender;
    }


function setupAdmin(address _address)public{
    require(owner==msg.sender,"Access Denied");
    admin = Admin(_address);
}



//----------------------Sale------------------------

//Place NFT onto Market Place
    function createMarketItem(address _collectionAddress, uint _nftId, uint _price_each, uint _quantity) public {
        require(admin.getServiceFee()>0,"Please setup service fee");
        require(admin.getServiceFeeReceiver()!=address(0),"Please setup service fee Receiver");
        erc = Multiple_Collection(_collectionAddress);
        uint balanceOf = erc.balanceOf(msg.sender,_nftId);

        require(!itemTime[marketItemId].started, "Already started!");
        require(_quantity<=balanceOf, "No Sufficient Balance To Start Sale");

        
        itemTime[marketItemId].startAt = block.timestamp;

        item[marketItemId].nft_price = _price_each;
        item[marketItemId].nft_id = _nftId;

        item[marketItemId].seller = payable(msg.sender);
       
        item[marketItemId].quantityOnSale = _quantity;
        item[marketItemId].collectionAddress = _collectionAddress;

        itemTime[marketItemId].started = true;
        itemTime[marketItemId].ended = false;
        emit itemId(marketItemId);

         
        
        marketItemId+=1;
    }

    function buy(uint _itemId, uint _quanity, uint wei_service_fee) external payable {
        require(msg.value >= (item[_itemId].nft_price * _quanity),"Check Buy amount..!!");
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value>=item[_itemId].nft_price, "Amount is less than actual NFT Price");
        require(item[_itemId].quantityOnSale>0,"NFT already Soldout");
        require(_quanity<=item[_itemId].quantityOnSale,"Please enter quantity less then Sale");

          
        item[_itemId].offerAmount = msg.value - wei_service_fee;
        item[_itemId].offerBy = msg.sender;

        totalOrderAmount[msg.sender] +=msg.value; 
        
        item[_itemId].paidUsers.push(msg.sender);
        item[_itemId].quantityOnSale -=_quanity;
        acceptOrder(_itemId, _quanity, wei_service_fee);
    }

    function acceptOrder(uint _itemId, uint _quanity, uint wei_service_fee) internal{
        address _collectionAddress = item[_itemId].collectionAddress;
        erc = Multiple_Collection(_collectionAddress);
        address winner_address = item[_itemId].offerBy;
        uint winner_amount = item[_itemId].offerAmount;
        uint winner_quantity = _quanity;

//--------Platform Fee/Service Fee

            payable(admin.getServiceFeeReceiver()).transfer(wei_service_fee);
            payable(admin.getServiceFeeReceiver()).transfer(wei_service_fee);

//--------Platform Fee/Service Fee



//-----------Calculate Royalty Amount------------

        uint finalAmountToTransfer = transferRoyalty(_itemId, winner_amount);

//-----------Calculate Royalty Amount------------

            payable(item[_itemId].seller).transfer(finalAmountToTransfer - wei_service_fee);

            totalOrderAmount[winner_address] -=winner_amount;

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


//----------------------------------Sale-----------------------------------------


//-------Return Contract Ether Balance
function ETH() public view returns(uint){
         return address(this).balance;
}

function itemDetails(uint _itemId) public view returns(address, address,uint, uint,uint,address,uint)
{
    return(
        item[_itemId].collectionAddress,
        item[_itemId].seller,
        item[_itemId].nft_id,
        item[_itemId].nft_price,
        item[_itemId].offerAmount,
        item[_itemId].offerBy,
        item[_itemId].quantityOnSale
    );
}


}