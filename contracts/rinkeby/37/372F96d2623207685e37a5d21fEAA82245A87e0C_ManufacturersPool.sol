/**
 *Submitted for verification at Etherscan.io on 2022-09-23
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

    //Get offer index from id revert if not found
    function getOfferIndex(string memory offerId) public view returns (uint){
        for (uint i = 0; i < offers.length; i++) {
            if (keccak256(abi.encodePacked(offers[i].id)) == keccak256(abi.encodePacked(offerId))) {
                return i;
            }
        }
        revert("Offer not found");
    }

    function acceptOffer(string memory offerId) public returns (bool){
        //Get offer
        uint offerIndex = getOfferIndex(offerId);
        //Check if offer is expired
        require(offers[offerIndex].endDate > block.timestamp, "Offer is expired");

        //Check if offer is available
        require(offers[offerIndex].state == 0, "Offer is not available");

        offers[offerIndex].manufacturer = msg.sender;
        offers[offerIndex].state = 1;
        return true;
    }

    //Find offer that matches id and set state to 2
    function removeOffer(string memory offerId) public returns (bool){
        uint offerIndex = getOfferIndex(offerId);
        //Must be the offer owner
        require(offers[offerIndex].client == msg.sender, "You are not the offer owner");
        offers[offerIndex].state = 2;
        return true;
    }

    function getOffers() public view returns (Offer[] memory){
        return offers;
    }

    function isExpired(string memory offerId) public view returns (bool){
        return getOffer(offerId).endDate < block.timestamp;
    }

    //Get offers length
    function getOffersLength() public view returns (uint){
        return offers.length;
    }
}