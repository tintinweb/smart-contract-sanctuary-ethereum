//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IFlexiSwap.sol";

contract FlexiSwap is IFlexiSwap {
    constructor() {
        // constructor
    }

    function createTrade(Offer memory givings, Offer[] memory receivings) external  {
        revert("Not implemented");
    }

    function acceptOffer(uint256 tradeId, uint256 offerIndex) external override {
        revert("Not implemented");
    }

    function createCounterOffer(uint256 tradeId, Offer memory offer) external override {
        revert("Not implemented");
    }

    function acceptCounterOffer(uint256 tradeId, uint256 counterOfferIndex) external override {
        revert("Not implemented");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct Trade {
    address initiator;
    Offer givings;
    Offer[] receivings;
    CounterOffer[] counterOffers;
}

struct Offer {
    Item[] items;
}

struct CounterOffer {
    address  offerer;
    Item[] items;
}

struct Item {
    address nftAddress;
    uint256 tokenId;
    bool isEmptyToken;
}

// hierarchy of structs
// Trade => [Offer]

interface IFlexiSwap {
    // mapping(uint => Trade) trades;
    event TradeCreated(uint256 tradeId, Trade trade);
    event TradeAccepted(address accpter, int256 tradeId, uint256 offerIndex);
    event CounterOfferCreated(address counterOfferer, int256 tradeId, Offer counterOffer);
    event CounterOfferAccepted(uint256 tradeId, uint256 counterOfferIndex);

    function createTrade(Offer memory givings, Offer[] memory receivings) external;
    
    function acceptOffer(uint256 tradeId, uint256 offerIndex) external;
    
    function createCounterOffer(uint256 tradeId, Offer memory offer) external;

    function acceptCounterOffer(uint256 tradeId, uint256 counterOfferIndex) external;
}