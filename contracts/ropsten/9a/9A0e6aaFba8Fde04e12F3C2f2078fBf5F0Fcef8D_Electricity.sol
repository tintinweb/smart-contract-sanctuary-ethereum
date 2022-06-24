/**
 *Submitted for verification at Etherscan.io on 2022-06-24
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

    
    uint[] indexes;
    uint[] prices;
    uint[] amounts;

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

    function sortOffers() public {
        for (uint i = 0; i < offers.length; i++) {
            for (uint j = 0; j < i; j++){
                if (offers[i].price < offers[j].price) {
                    uint price = offers[j].price;
                    uint amount = offers[j].amount;
                    offers[j].price = offers[i].price;
                    offers[j].amount = offers[i].amount;
                    offers[i].price = price;
                    offers[i].amount = amount;
                }
            }
        }
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

    function sortBids() public {
        for (uint i = 0; i < bids.length; i++) {
            for (uint j = 0; j < i; j++){
                if (bids[i].price < bids[j].price) {
                    uint price = bids[j].price;
                    uint amount = bids[j].amount;
                    bids[j].price = bids[i].price;
                    bids[j].amount = bids[i].amount;
                    bids[i].price = price;
                    bids[i].amount = amount;
                }
            }
        }
    }

    function calcPairs() public returns(uint[] memory,  uint[] memory, uint[] memory) {
        uint offer_cnt = getOfferCount();
        uint bid_cnt = getBidCount();
        uint tot_cnt = offer_cnt < bid_cnt ? offer_cnt : bid_cnt;

        for(uint _idx = 0; _idx < tot_cnt; _idx++){
            if(offers[_idx].price < bids[_idx].price){
                indexes.push(_idx);
                uint cprice = (offers[_idx].price + bids[_idx].price) / 2;
                uint camount = offers[_idx].amount < bids[_idx].amount ? offers[_idx].amount : bids[_idx].amount;
                prices.push(cprice);
                amounts.push(camount);
            }
        }
        
        return (indexes, prices, amounts);
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