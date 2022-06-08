// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './ERC721.sol';

contract Single_Fixed_Price{

    address public owner;
    uint marketItemId=1;
  
   
    uint public platformFee = 2500000000000000000;
    
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

    

    constructor( ) {
      owner = msg.sender;
    }
 

//----------------------------------Bidding-----------------------------------------

   
    function createMarketItemFixed(address _collectionAddress, uint _nftId,uint _price) public {
        uint _itemId = marketItemId;
        marketItemId+=1;
        Clix721collection erc = Clix721collection(_collectionAddress);

        require(!itemTime[_itemId].started, "Already started!");
        
        address ownerOf = erc.ownerOf(_nftId);

        require(msg.sender==ownerOf,"Your are not a Owner");

        item[_itemId].nft_price = _price;

        
        //check for owner of nft before starting th bid

        itemTime[_itemId].startAt = block.timestamp;
        item[_itemId].collectionAddress = _collectionAddress;
        item[_itemId].nft_id = _nftId;
        item[_itemId].seller = payable(msg.sender);
       
        itemTime[_itemId].started = true;
        itemTime[_itemId].ended = false;
        
    }

    
    function withdraw(uint _itemId) external payable {
        require(item[_itemId].offerBy!=msg.sender, "Could not withdraw");
        require(orderList[msg.sender] != 0,"No Bid amount found..!!");
        uint bal = orderList[msg.sender];
        orderList[msg.sender] = 0;
        (bool sent, bytes memory data) = payable(msg.sender).call{value: bal}("");
        require(sent, "Could not withdraw");
    }


    function buy(uint _itemId) external payable {
        require(itemTime[_itemId].started, "Not started.");
        require(msg.value >= item[_itemId].nft_price,"Amount is Less than Price");
        require(msg.value > item[_itemId].offerAmount, "NFT already has highest Offer..!!");
        
        orderList[msg.sender] = msg.value;

       address _collectionAddress = item[_itemId].collectionAddress; 
        item[_itemId].offerAmount = msg.value;
        item[_itemId].offerBy = msg.sender;

        accept(_collectionAddress,_itemId);
    }


    function accept(address _collectionAddress,uint _itemId) internal {

        Clix721collection erc = Clix721collection(_collectionAddress);

        require(itemTime[_itemId].started, "You need to start first!");
        require(!itemTime[_itemId].ended, "Auction already ended!");

        erc._transfer(item[_itemId].seller,item[_itemId].offerBy, item[_itemId].nft_id);

//--------Platform Fee/Service Fee

            uint transferOfferAmount = (item[_itemId].offerAmount * platformFee)/100000000000000000000;
            uint amountToTransfer = item[_itemId].offerAmount - transferOfferAmount;

//--------Platform Fee/Service Fee



//-----------Calculate Royalty Amount------------

            address temp_user_transfer = erc.artistOfNFT(item[_itemId].nft_id);
            uint roylaty_amount = (amountToTransfer * erc.getRoyaltyOfNFT(item[_itemId].nft_id)) / 100000000000000000000;
           
            (bool msgdata, bytes memory msgmetadata) = temp_user_transfer.call{value: roylaty_amount}("");
            require(msgdata, "Could not pay Royalty!");

            uint finalAmountToTransfer = amountToTransfer - roylaty_amount;

//-----------Calculate Royalty Amount------------

            (bool sent, bytes memory data) = item[_itemId].seller.call{value: finalAmountToTransfer}("");
            require(sent, "Could not pay Buyer!");
            orderList[item[_itemId].offerBy] -=item[_itemId].offerAmount;

            itemTime[_itemId].ended = true;
            itemTime[_itemId].started = false;
            item[_itemId].seller = payable(address(0));
    }


//----------------------------------Bidding-----------------------------------------

function removeFromSale(uint _itemId) public{
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