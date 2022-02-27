// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

contract Market {

	enum ListingStatus {
		Active,
		Sold,
		Cancelled
	}

    struct Offers {
        address offerer;
        uint price;
    }

    event Offered (
        address offerer,
        uint price,
        uint tokenId
    );

	struct Listing {
		ListingStatus status;
		address seller;
		address token;
		uint tokenId;
		uint price;
	}

	event Listed(
		uint listingId,
		address seller,
		address token,
		uint tokenId,
		uint price,
        ListingStatus status	
    );

	event Sale(
		uint listingId,
		address buyer,
        address seller,
		address token,
		uint tokenId,
		uint price,
        ListingStatus status
	);


	event Cancel(
		uint listingId,
		address seller
	);

	uint public _listingId = 0;
    uint public countListing = 0;
    uint public offeringId = 0;

	mapping(uint => Listing) public _listings;
    mapping(uint => mapping(uint =>  Offers)) public _offers;
    mapping (uint256 => uint256) public countingOffer;

	function listToken(address token, uint tokenId, uint price) external {

		IERC721(token).transferFrom(msg.sender, address(this), tokenId);

		Listing memory listing = Listing(
			ListingStatus.Active,
			msg.sender,
			token,
			tokenId,
			price 
		);

		_listingId++;
        countListing++;
		_listings[_listingId] = listing;

		emit Listed(
			_listingId,
			msg.sender,
			token,
			tokenId,
			price,
            ListingStatus.Active
		);
	}

	function getListing(uint listingId) public view returns (Listing memory) {
		return _listings[listingId];
	}

    function getListings() public view returns (Listing[] memory){
    Listing[] memory listings = new Listing[](countListing);
    for (uint i = 0; i < countListing; i++) {
        listings[i] = _listings[i+1];
    }
        return listings;
    }

	function buyToken(uint listingId) public payable {
		Listing storage listing = _listings[listingId];
		require(msg.sender != listing.seller, "Seller cannot be buyer");
		require(listing.status == ListingStatus.Active, "Listing is not active");
		require(msg.value >= listing.price * 10 ** 9 , "Insufficient payment");

		listing.status = ListingStatus.Sold;

		IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);
		payable(listing.seller).transfer(listing.price * 10 ** 9);

		emit Sale(
			listingId,
			msg.sender,
            listing.seller,
			listing.token,
			listing.tokenId,
			listing.price,
            ListingStatus.Sold
		);
	}

	function cancel(uint listingId) public {
		Listing storage listing = _listings[listingId];

		require(msg.sender == listing.seller, "Only seller can cancel listing");
		require(listing.status == ListingStatus.Active, "Listing is not active");

		listing.status = ListingStatus.Cancelled;
	
		IERC721(listing.token).transferFrom(address(this), msg.sender, listing.tokenId);
		if(countingOffer[listingId] > 0){
			for(uint i=1; i < countingOffer[listingId]+1; i++){
            Offers storage offerpeoples =  _offers[listingId][i];
            payable(offerpeoples.offerer).transfer(offerpeoples.price * 10 ** 9);
        }
		}
		emit Cancel(listingId, listing.seller);
	}



    function offer(uint _price, uint listingId) public payable {

        Listing storage listing = _listings[listingId];
        require(listing.status == ListingStatus.Active, "Listing is not active");
        require(msg.value >= _price, "Insufficient payment");
        require(msg.sender != listing.seller, "Seller cannot be offerer");

        Offers memory offerpeple = Offers(
            msg.sender,
            _price
        ) ;

        emit Offered(msg.sender, _price, listingId);

		if(countingOffer[listingId] == 0 ) {
			offeringId++;
			countingOffer[listingId] ++ ;
			_offers[listingId][offeringId] =  offerpeple;
			offeringId = 0;
		}else {
			offeringId = countingOffer[listingId] + 1;
			countingOffer[listingId] ++ ;
			_offers[listingId][offeringId] =  offerpeple;
			offeringId = 0;
		}
    }


    function acceptOffer(uint listingId, uint idoffer)  public  {
		Listing storage listing = _listings[listingId];
        require (countingOffer[listingId] > 0);
		require(msg.sender  == listing.seller, "you're not the seller");

        for(uint i=1; i < countingOffer[listingId]+1; i++){
            Offers storage offerpeoples =  _offers[listingId][i];
            if( i == idoffer) {
                listing.status = ListingStatus.Sold;
                IERC721(listing.token).transferFrom(address(this),  offerpeoples.offerer, listing.tokenId);
                payable(listing.seller).transfer(offerpeoples.price * 10 ** 9);

                emit Sale(
			        listingId,
			        offerpeoples.offerer,
                    listing.seller,
			        listing.token,
			        listing.tokenId,
			        offerpeoples.price,
                    ListingStatus.Sold
		        );
            }else {
                payable(offerpeoples.offerer).transfer(offerpeoples.price * 10 ** 9);
            }
        }
    }

    function showOfferforListitem(uint listingId) public view returns (Offers[] memory) {
        Offers[] memory peopleOffer = new Offers[](countingOffer[listingId]);
        for(uint8 i=0; i < countingOffer[listingId]; i++){
            peopleOffer[i] = _offers[listingId][i+1];
        }
        return peopleOffer;
    }
}