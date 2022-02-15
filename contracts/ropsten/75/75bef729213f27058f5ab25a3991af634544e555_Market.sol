//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import './ERC721.sol';
import './ReentrancyGuard.sol';
import './Counters.sol';




contract Market is ReentrancyGuard {
    using Counters for Counters.Counter;    

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;


    address payable owner;

   
    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketToken {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketToken) private idToMarketToken;

    event MarkettokenMinted(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );


    function makeMarketItem(address nftContract,uint tokenId,uint price, uint256 Feeadmin)
public payable nonReentrant {

   // require(price > 0,'price must atleast one wei');
    //require(msg.value == listingprice, 'price must be equal to lisitng price');

    _tokenIds.increment();
    uint itemId = _tokenIds.current();

    idToMarketToken[itemId] = MarketToken(
        itemId,
        nftContract,
        tokenId,
        payable(msg.sender),
        payable(address(0)),
        price,
        false
    );

    IERC721(nftContract).transferFrom(msg.sender,address(this), tokenId);

        Feeadmin = price * 2/100;
        payable(0x2AA5322e399E049900B7C80dA5fCfE7efDB6d42b).transfer(Feeadmin);

    emit MarkettokenMinted(itemId, nftContract, tokenId, msg.sender, address(0), price, false);
 }

    function createMarketsale(address nftContract, uint itemId, uint256 Royalty, uint256 Listingprice)public payable nonReentrant {
        uint price = idToMarketToken[itemId].price;
        uint tokenId = idToMarketToken[itemId].tokenId;
        require(msg.value == price, 'please submit the asking price in order to continue');
        idToMarketToken[itemId].seller.transfer(msg.value);

        IERC721(nftContract).transferFrom(address (this), msg.sender, tokenId);
        idToMarketToken[itemId].owner = payable(msg.sender);
        idToMarketToken[itemId].sold = true;
        _tokensSold.increment();

        Royalty = price * Royalty/100;
        payable(owner).transfer(Royalty);

        Listingprice = price * Listingprice/100;
        payable (0x2AA5322e399E049900B7C80dA5fCfE7efDB6d42b).transfer(Listingprice);
    }

    function fetchMarketTokens() public view returns(MarketToken[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _tokensSold.current();
        uint currentIndex = 0;

        MarketToken[] memory items = new MarketToken[](unsoldItemCount);
        for(uint i=0; i< itemCount; i++) {
            if(idToMarketToken[i+1].owner == address(0)) {
                uint currentId = i + 1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;  
            }
        }
        return items;
    }

        function fetchMyNFTs() public view returns (MarketToken[] memory) {
            uint totalItemCount = _tokenIds.current();
            uint itemCount = 0;
            uint currentIndex = 0;

            for(uint i=0; i < totalItemCount; i++) {
                if(idToMarketToken[ i + 1 ].owner == msg.sender) {
                    itemCount += 1;
                }
            }

            MarketToken[] memory items = new MarketToken[](itemCount);
            for(uint i=0; i < totalItemCount; i++) {
                if(idToMarketToken[i+1].owner == msg.sender)  {
                    uint currentId = idToMarketToken[i+1].itemId;

                    MarketToken storage currentItem = idToMarketToken[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return items;
        }

}