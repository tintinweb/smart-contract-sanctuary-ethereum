/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Electricity {
    struct Offer { 
      uint price;
      uint amount;
    }

    Offer[] offers;
    Offer[] bids;
    uint public count;
    constructor(){
    }

    // Offer operation 
    function addOffer(uint _price, uint _amount) public returns (uint){
        offers.push(Offer(_price, _amount));
        return offers.length;
    }

    function getOfferCount() public view returns(uint) {
        return offers.length;
    }

    function getOffer(uint _idx) public view returns(uint, uint) {
        return (offers[_idx].price, offers[_idx].amount);
    }

    // Bid Operation
    function addBid(uint _price, uint _amount) public returns (uint){
        bids.push(Offer(_price, _amount));
        return bids.length;
    }

    function getBidCount() public view returns(uint) {
        return bids.length;
    }

    function getBid(uint _idx) public view returns(uint, uint) {
        return (bids[_idx].price, bids[_idx].amount);
    }

    function calcPrice() public view returns(uint) {
        uint offer_cnt = getOfferCount();
        uint bid_cnt = getBidCount();
        uint offer_sum = 0;
        uint bid_sum = 0;
        
        for(uint _idx = 0; _idx < offer_cnt; _idx++){
            uint price;
            (price, ) = getOffer(_idx);
            offer_sum += price;
        }
        
        for(uint _idx = 0; _idx < bid_cnt; _idx++){
            uint price;
            (price, ) = getBid(_idx);
            bid_sum += price;
        }

        uint res = ( offer_sum + bid_sum ) / ( offer_cnt + bid_cnt );
        return res;
    }
}