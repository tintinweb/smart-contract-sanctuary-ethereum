// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Chit.sol";

// ---------------------------------------------------------------------------
// A basic market to trade Chits with zero fees.
//
// Chits are standard ERC721 NFTs that can be traded here or anywhere NFTs are
// supported.
//
// Steps:
//
// 1. A Seller has an asset, calls ChitFactory.make() to submit it and receive
//    a new Chit for it.
//
// 2. The Seller then creates one or more Asks identifying the asset Chit and
//    what is wanted in trade.
//
// 3. A Buyer who has what the Seller wants sees the Ask and responds. The
//    Buyer establishes payment by calling ChitFactory.make() and receives a
//    new Chit for it.
//
// 4. The Buyer creates an Offer that meets or exceeds the Ask by approve()ing
//    the payment chit for this contract and calling offer().
//    The type of item in the Offer must match the Ask.
//    Offers may exceed asks in amount only, as in an auction scenario.
//
// 5. The Seller sees the Offer and accepts it by approving() the asset Chit
//    for this contract and calling accept(), which then swaps ownership of
//    the Chits. The Seller comes away owning the payment Chit and the
//    Buyer owns the asset Chit.
//
// ---------------------------------------------------------------------------

contract ChitMarket {

  Chit public chit;

  struct Ask {
    uint256 assetChitId; // for this chit representing some asset
    // SELLER asks to be paid with:
    address askType;     // 0 means ETH, non-zero is a token SCA
    uint256 askAmount;   // wei or token units if ERC20
    uint256 askTokenId;  // token id if ERC721 (NFT)
  }

  struct Offer {
    uint256 askId;
    uint256 payChitId;
  }

  uint256 public askCounter;
  mapping( uint256 => Ask ) public asks; // askId => Ask

  uint256 public offerCounter;
  mapping( uint256 => Offer ) public offers; // offerId => Offer

  function ask( uint256 assetChitId,
                address askType,
                uint256 askAmount,
                uint256 askTokenId ) public {

    require( msg.sender == chit.ownerOf(assetChitId),
             "caller must own the chit to create an ask" );

    asks[askCounter++] = Ask( assetChitId, askType, askAmount, askTokenId );
  }

  function cancelAsk( uint256 askId ) public {

    require( msg.sender == chit.ownerOf(asks[askId].assetChitId),
             "must own chit to cancel ask" );

    asks[askId].assetChitId = 0;
  }

  function offer( uint256 askId, uint256 payChitId ) public {

    require( asks[askId].assetChitId != 0, "ask missing or canceled" );

    require(    chit._itemTypes(payChitId) == asks[askId].askType
             && chit._itemAmounts(payChitId) >= asks[askId].askAmount
             && chit._itemTokenIds(payChitId) == asks[askId].askTokenId,
             "offer must meet or exceed ask" );

    require(    chit.getApproved(payChitId) == address(this)
             || chit.isApprovedForAll(msg.sender, address(this)),
             "payment chit must be approved for ChitMarket" );

    offers[offerCounter++] = Offer( askId, payChitId );
  }

  function cancelOffer( uint256 offerId ) public {

    require( msg.sender == chit.ownerOf( offers[offerId].payChitId ),
             "must own payment chit to cancel offer" );

    offers[offerId].payChitId = 0;
  }

  function accept( uint256 offerId ) public {

    require( offers[offerId].payChitId != 0, "offer missing or canceled" );

    address seller = chit.ownerOf( asks[offers[offerId].askId].assetChitId );

    require( msg.sender == seller,
             "caller must own the asset chit to accept offer" );

    address buyer = chit.ownerOf( offers[offerId].payChitId );

    chit.transferFrom( seller,
                       buyer,
                       asks[offers[offerId].askId].assetChitId );

    chit.transferFrom( buyer,
                       seller,
                       offers[offerId].payChitId );

    asks[offers[offerId].askId].assetChitId = 0;
    offers[offerId].payChitId = 0;
  }

  // =========================================================================

  constructor( address _chit ) {
    chit = Chit(_chit);
    askCounter = 1;
    offerCounter = 1;
  }

}