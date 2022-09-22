/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ManufacturersPool {
    struct Offer {
        // Id of the offer
        string id;
        // The entity that post an offer to the pool
        address client;
        // Required price for the offer
        uint price;
        //0 new offer, 1 - accepted, 2 - removed
        uint state;
        uint endDate;
        address manufacturer;
    }

    Offer[] public offers;

    function isOfferUnique(string memory id) public view returns (bool){
        for (uint i = 0; i < offers.length; i++) {
            if (keccak256(abi.encodePacked(offers[i].id)) == keccak256(abi.encodePacked(id))) {
                return false;
            }
        }
        return true;
    }

    function addOffer(string memory id, uint price, uint endDate) public returns (Offer memory){
        //Check if id is unique
        require(isOfferUnique(id), "Offer id is not unique");
        //Check expiration date
        require(endDate > block.timestamp, "Expiration date is in the past");
        offers.push(Offer(id, msg.sender, price, 0, endDate, address(0)));
        return offers[offers.length - 1];
    }

    //Find offer from offer id revert if not found
    function getOffer(string memory offerId) public view returns (Offer memory){
        for (uint i = 0; i < offers.length; i++) {
            if (keccak256(abi.encodePacked(offers[i].id)) == keccak256(abi.encodePacked(offerId))) {
                return offers[i];
            }
        }
        revert("Offer not found");
    }

    function acceptOffer(string memory offerId) public returns (bool){
        //Get offer
        Offer memory offer = getOffer(offerId);
        //Check if offer is expired
        require(offer.endDate > block.timestamp, "Offer is expired");

        //Check if offer is available
        require(offer.state != 0, "Offer is not available");

        offer.manufacturer = msg.sender;
        offer.state = 1;
        return true;
    }

    //Find offer that matches id and set state to 2
    function removeOffer(string memory offerId) public returns (bool){
        //Must be the offer owner
        require(getOffer(offerId).client == msg.sender, "You are not the offer owner");
        Offer memory offer = getOffer(offerId);
        offer.state = 2;
        return true;
    }

    function getOffers() public view returns (Offer[] memory){
        return offers;
    }

    function isExpired(string memory offerId) public view returns (bool){
        return getOffer(offerId).endDate < block.timestamp;
    }
}