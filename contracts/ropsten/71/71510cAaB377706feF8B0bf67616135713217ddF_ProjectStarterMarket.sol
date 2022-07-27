// SPDX-License-Identifier: MIT


pragma solidity ^ 0.8.0;

import './Auction.sol';

contract ProjectStarterMarket is AuctionHouse{

    // Index of Offer
  uint256 public indexOffer = 0;
  _Offer[] public offers;
  mapping (address => uint) public userBalance;

  
  // struct for offer 
  struct _Offer {
    uint256 index;  //index
    address addressNFTCollection; // Address of the ERC721 NFT Collection contract
    uint256 nftId; // NFT Id
    address offerer;
    uint price;
    bool fulfilled;
    bool cancelled;
  }

// offer created
  event Offer(
    uint256 index,  //index
    address addressNFTCollection, // Address of the ERC721 NFT Collection contract
    uint256 nftId, // NFT Id
    address offerer,
    uint offerPrice,
    bool fulfilled,
    bool cancelled
  );


  // offer status
  event OfferFilled(uint offerId, uint nftId,address nftCollectionAdress,address newOwner);
  event OfferCancelled(uint offerId, uint id,address nftCollectionAdress, address owner);
  event ClaimFunds(address user, uint amount);

  constructor(string memory name) AuctionHouse(name) {
   
  }
  
  function makeOffer(uint _nftId,address _nftAddress,uint _nftPrice) public payable {
      //check for mini offer
      require(msg.value>_nftPrice,"Not enough fund price");

      //updating funds provided by user
      userBalance[msg.sender]+=msg.value;
      
      // creating instance 
      _Offer memory newOffer= _Offer(indexOffer,_nftAddress,_nftId,msg.sender,msg.value,false,false);
      
      //adding offer in array
      offers.push(newOffer);

    
      
      emit Offer(indexOffer,_nftAddress,_nftId,msg.sender,msg.value,false,false);

      //increamenting index
      indexOffer++; 


  }

  function fillOffer(uint _offerId) public {

    _Offer storage _offer = offers[_offerId];
    // conditon for offer check
    require(_offer.index == _offerId, "The offer must exist");
    require(_offer.offerer != msg.sender, "The owner of the offer cannot fill it");
    require(!_offer.fulfilled, "An offer cannot be fulfilled twice");
    require(!_offer.cancelled, "A cancelled offer cannot be fulfilled");


    IERC721 nftCollection = IERC721(_offer.addressNFTCollection);
     // Make sure the owner of the NFT approved that the MarketPlace contract
        // is allowed to change ownership of the NFT
    require(
          nftCollection.getApproved(_offer.nftId) == address(this),
          "Require NFT ownership transfer approval");
    
     // transfer from owner to offerer
     nftCollection.safeTransferFrom(msg.sender, _offer.offerer, _offer.nftId);

     // update user fund in market
     userBalance[_offer.offerer]-= _offer.price;
     //update offer status
    _offer.fulfilled = true;

    emit OfferFilled(_offerId, _offer.nftId,_offer.addressNFTCollection,msg.sender);
  
  }

  function cancelOffer(uint _offerId) public {

    // retrive
    _Offer storage _offer = offers[_offerId];

    // checks
    require(_offer.index == _offerId, "The offer must exist");
    require(_offer.offerer == msg.sender, "The offer can only be canceled by the owner");
    require(_offer.fulfilled == false, "A fulfilled offer cannot be cancelled");
    require(_offer.cancelled == false, "An offer cannot be cancelled twice");
    
    // updated offer status
    _offer.cancelled = true;

    // refund deposit funds for offer
    require(userBalance[msg.sender] > 0, "Cant refun while you cancellling offer");
    payable(msg.sender).transfer(_offer.price);

    emit OfferCancelled(_offerId, _offer.nftId,_offer.addressNFTCollection, msg.sender);
  }


  function claimFunds() public {
    //check for balance
    require(userBalance[msg.sender] > 0, 'This user has no funds to be claimed');
    // trabsfer back
    payable(msg.sender).transfer(userBalance[msg.sender]);

    emit ClaimFunds(msg.sender, userBalance[msg.sender]);
    userBalance[msg.sender] = 0;    
  }


}