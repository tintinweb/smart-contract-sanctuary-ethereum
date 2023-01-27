/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: storage.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Storage {

    uint256 public n;

      constructor() {
        n=0;
 }

  struct MarketToken {
    uint256 itemId;
     uint256 tokenId;
     string uri;
     address nftContract;
     address payable owner;
     address payable creater;
     address payable prev_owner;
     uint256 price;
     uint256 copyid;
     uint royalities;
     uint256 time;//this says the time for auction
     address payable bidder;
     bool sell; // this is bool statement to keep it for sale or not
     bool is_fixed;//this says that item is for fixed price or not
     bool is_single;//this says item is single or multiples
     bool is_timed;//this says that the item is for timed auction
     
}

    mapping(uint256 => MarketToken) private markettokens;

     function increment() private {
          n = n+1;
      }

    function create_market_items(uint256 tokenId,
        string memory uri,
        address nftContract,
        uint256 royalities,
        address owner_item,
     address creater,bool is_single,uint256 copyid)public {
        increment();
        MarketToken memory market_token = MarketToken(
            n,
            tokenId,
            uri,
            nftContract,
            payable(owner_item),
            payable(creater),
            payable(0x00),
            0,
            copyid,
            royalities,
            0,
            payable(0x00),
            false,
            false,
            is_single,
            false
        );
        markettokens[n] = market_token;
    }

    function get_items() public view returns(MarketToken[] memory) {
        uint totalItemCount = n;
        uint itemCount = 0;
        uint currentIndex = 0;
        for(uint i = 0; i < totalItemCount; i++) {
        if(markettokens[i + 1].owner != address(0x00)) {
            itemCount += 1;
            }
        }
        MarketToken[] memory items = new MarketToken[](itemCount);
        for(uint i = 0; i < totalItemCount; i++) {
            if(markettokens[i +1].owner != address(0x00)) {
                uint currentId = i+1;
                MarketToken memory currentItem = markettokens[currentId];
                items[currentIndex]= currentItem;
                currentIndex += 1;
            }
        }
        return items;
        }

    function edit_market_items(uint256 i , MarketToken memory market_token)public {
        markettokens[i] = market_token;
    }

    function get_items_by_id(uint256 item_id)public view returns(MarketToken memory){
        return markettokens[item_id];
    }

    function fetchmynfts() public view returns (MarketToken[] memory) {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].owner != address(0x00)) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].owner != address(0x00)) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchmynftsbyOwner(address addr) public view returns (MarketToken[] memory) {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].owner == addr) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].owner == msg.sender) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchmynftsbyCreater(address addr)view public returns (MarketToken[] memory) {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].creater == addr
            ) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].creater == msg.sender) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchmynftsbyBidder(address addr) public view returns (MarketToken[] memory) {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].bidder == addr) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (markettokens[i+1].bidder == msg.sender) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchmynftsbyOpen_bid()
        public
        view
        returns (MarketToken[] memory)
    {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].sell == true &&
                markettokens[i+1].is_fixed == false &&
                markettokens[i+1].is_timed == false
            ) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].sell == true &&
                markettokens[i+1].is_fixed == false &&
                markettokens[i+1].is_timed == false
            ) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchmynftsbyfixed_price()
        public
        view
        returns (MarketToken[] memory)
    {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].sell == true &&
                markettokens[i+1].is_fixed == true
            ) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].sell == true &&
                markettokens[i+1].is_fixed == true
            ) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchmynftsbytimedauction()
        public
        view
        returns (MarketToken[] memory)
    {
        uint256 totalItemCount = n;

        uint256 itemCount = 0;

        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].sell == true &&
                markettokens[i+1].is_fixed == false &&
                markettokens[i+1].is_timed == true
            ) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                markettokens[i+1].sell == true &&
                markettokens[i+1].is_fixed == false &&
                markettokens[i+1].is_timed == true
            ) {
                uint256 currentId = i + 1;

                MarketToken memory currentItem =markettokens[currentId];

                items[currentIndex] = currentItem;

                currentIndex += 1;
            }
        }

        return items;
    }


    function update_owner(uint256 tokenId,address owner)public{
        markettokens[tokenId].owner = payable(owner);
    }

    function update_prev_owner(uint256 tokenId,address prev_owner)public{
        markettokens[tokenId].prev_owner = payable(prev_owner);
    }

    function update_price(uint256 tokenId,uint256 price)public{
        markettokens[tokenId].price = price;
    }

    function update_royalities(uint256 tokenId,uint royalities)public{
        markettokens[tokenId].royalities = royalities;
    }

    function update_time(uint256 tokenId,uint256 time)public{
        markettokens[tokenId].time = time;
    }

    function update_bidder(uint256 tokenId,address bidder)public{
        markettokens[tokenId].bidder = payable(bidder);
    }


    function update_sell(uint256 tokenId,bool sell)public{
        markettokens[tokenId].sell = sell;
    }

    function update_is_fixed(uint256 tokenId,bool is_fixed)public{
        markettokens[tokenId].is_fixed = is_fixed;
    }

    function update_is_timed(uint256 tokenId,bool is_timed)public{
        markettokens[tokenId].is_timed = is_timed;
    }

    function update_is_single(uint256 tokenId,bool is_single)public{
        markettokens[tokenId].is_single = is_single;
    }


 
}