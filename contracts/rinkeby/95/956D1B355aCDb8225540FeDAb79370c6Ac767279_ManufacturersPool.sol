/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ManufacturersPool {
    struct Offer {
        // Id of the offer
        string id;
        // The entity that post an offer to the pool
        address poster;
        // Required price for the offer
        uint price;
        //Location of the package for pickup
        address source;
        //Location of the package for delivery
        address target;
        //0 new offer, 1 - accepted, 2 - expired, 3 - removed
        uint state;
        uint endDate;
    }

    Offer[] public offers;

    function isOfferIdUnique(string memory id) public view returns (bool){
        for (uint i = 0; i < offers.length; i++) {
            if (keccak256(abi.encodePacked(offers[i].id)) == keccak256(abi.encodePacked(id))) {
                return false;
            }
        }
        return true;
    }

    function addOffer(string memory id, uint price, address source, address target, uint endDate) public returns (uint){
        //Check if id is unique
        require(isOfferIdUnique(id), "Offer id is not unique");
        offers.push(Offer(id, msg.sender, price, source, target, 0, endDate));
        return offers.length - 1;
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
        require(offer.state == 0, "Offer is not available");

        offer.target = msg.sender;
        offer.state = 1;
        return true;
    }

    //Find offer that matches id and set state to 2
    function removeOffer(string memory offerId) public returns (bool){
        Offer memory offer = getOffer(offerId);
        offer.state = 2;
        return true;
    }

    function getAllOffers() public view returns (Offer[] memory){
        return offers;
    }

    function getValidOffers() public view returns (Offer[] memory){
        Offer[] memory validOffers;
        uint j=0;
        for (uint i = 0; i < offers.length; i++) {
            if (offers[i].endDate > block.timestamp && offers[i].state == 0) {
                validOffers[j]=offers[i];
                j++;
            }
        }
        return validOffers;
    }
}