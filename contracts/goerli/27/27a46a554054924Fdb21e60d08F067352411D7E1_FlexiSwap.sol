//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./FlexiSwapValidator.sol";
import "./FlexiSwapCore.sol";
import "./IFlexiSwap.sol";

contract FlexiSwap is FlexiSwapValidator {
    constructor() {
        // constructor
    }

    function createTrade(Item[] memory _givings, Item[][] memory _receivings)
        public
        virtual
        override
    {
        super.createTrade(_givings, _receivings);
    }

    function acceptOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        super.acceptOffer(_tradeId, _itemsId);
    }

    function createCounterOffer(uint256 _tradeId, Item[] memory _offerItems)
        public
        virtual
        override
    {
        super.createCounterOffer(_tradeId, _offerItems);
    }

    function acceptCounterOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        super.acceptCounterOffer(_tradeId, _itemsId);
    }
}

pragma solidity ^0.8.15;

import "./FlexiSwapCore.sol";

contract FlexiSwapValidator is FlexiSwapCore {
    uint256 private MAX_OFFER_ITEMS = 10;
    uint256 private MAX_OFFERS_PER_TRADE = 10;

    constructor() {
        // constructor
    }

    modifier tradeExists(uint256 tradeId) {
        if (_trades[tradeId].initiator == address(0)) {
            revert TradeDoesNotExist(tradeId);
        }
        _;
    }

    modifier offerExists(uint256 tradeId, uint256 itemsId) {
        Trade memory trade = _trades[tradeId];
        for (uint256 i = 0; i < trade.receivingsIds.length; i++) {
            if (trade.receivingsIds[i] == itemsId) {
                _;
                return;
            }
        }

        revert OfferDoesNotExist(tradeId, itemsId);
    }

    modifier counterOfferExists(uint256 tradeId, uint256 itemsId) {
        Trade memory trade = _trades[tradeId];
        for (uint256 i = 0; i < trade.counterOfferItemsIds.length; i++) {
            if (trade.counterOfferItemsIds[i] == itemsId) {
                _;
                return;
            }
        }

        revert CounterOfferDoesNotExist(tradeId, itemsId);
    }

    // validates whether the trade has at least one offer and not more than MAX_OFFERS_PER_TRADE
    modifier validOffersNumber(Item[][] memory receivings) {
        if (
            receivings.length == 0 || receivings.length > MAX_OFFERS_PER_TRADE
        ) {
            revert InvalidTradeOffersNumber();
        }
        _;
    }

    // validates whether the trade offers includes at least one item and not more than MAX_OFFER_ITEMS
    modifier validOffersItemNumber(Item[][] memory receivings) {
        for (uint256 i = 0; i < receivings.length; i++) {
            if (
                receivings[i].length == 0 ||
                receivings[i].length > MAX_OFFER_ITEMS
            ) {
                revert InvalidTradeOffersItemNumber();
            }
        }
        _;
    }

    // validates whether the offer includes at least one item and not more than MAX_OFFER_ITEMS
    modifier validOfferItemNumber(Item[] memory offerItems) {
        if (offerItems.length == 0 || offerItems.length > MAX_OFFER_ITEMS) {
            revert InvalidTradeOffersItemNumber();
        }
        _;
    }

    modifier notTradeOwner(uint256 tradeId) {
        if (_trades[tradeId].initiator == msg.sender) {
            revert InvalidForTradeOwner();
        }
        _;
    }

    modifier isTradeOwner(uint256 tradeId) {
        if (_trades[tradeId].initiator != msg.sender) {
            revert TradeOwnerOnly();
        }
        _;
    }

    modifier notExistingCounterOffer(uint256 tradeId, address counterOfferer) {
        Trade memory trade = _trades[tradeId];
        for (uint256 i = 0; i < trade.counterOfferItemsIds.length; i++) {
            uint counterOfferItemsId = trade.counterOfferItemsIds[i];
            if (counterOfferer == _counterOfferInitiators[counterOfferItemsId]) {
                revert CounterOfferAlreadyExists(tradeId, counterOfferItemsId);
            }
        }
        _;
    }

    function createTrade(Item[] memory _givings, Item[][] memory _receivings)
        public
        virtual
        override
        validOffersNumber(_receivings)
        validOffersItemNumber(_receivings)
        validOfferItemNumber(_givings)
    {
        super.createTrade(_givings, _receivings);
    }

    function acceptOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        super.acceptOffer(_tradeId, _itemsId);
    }

    function createCounterOffer(uint256 _tradeId, Item[] memory _offerItems)
        public
        virtual
        override
        tradeExists(_tradeId)
        notTradeOwner(_tradeId)
        notExistingCounterOffer(_tradeId, msg.sender)
        validOfferItemNumber(_offerItems)
    {
        super.createCounterOffer(_tradeId, _offerItems);
    }

    function acceptCounterOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        super.acceptCounterOffer(_tradeId, _itemsId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IFlexiSwap {
    struct Trade {
        address initiator;
        uint256 givingsId;
        uint256[] receivingsIds;
        uint256[] counterOfferItemsIds;
    }

    struct Item {
        address nftAddress;
        uint256 tokenId;
        bool isEmptyToken;
    }

    error TradeDoesNotExist(uint256 tradeId);
    error OfferDoesNotExist(uint256 tradeId, uint256 itemsId);
    error CounterOfferDoesNotExist(uint256 tradeId, uint256 itemsId);
    error CounterOfferAlreadyExists(
        uint256 tradeId,
        uint256 counterOfferItemsId
    );
    error InvalidTradeOffersNumber();
    error InvalidTradeOffersItemNumber();
    error TradeOwnerOnly();
    error InvalidForTradeOwner();

    event TradeCreated(uint256 tradeId, Trade trade);
    event TradeAccepted(address accepter, uint256 tradeId, uint256 itemsId);
    event CounterOfferCreated(
        address counterOfferer,
        uint256 tradeId,
        uint256 itemsId
    );
    event CounterOfferAccepted(uint256 tradeId, uint256 itemsId);

    function trade(uint256 _tradeId) external view returns (Trade memory);

    function items(uint256 _itemsId) external view returns (Item[] memory);

    function createTrade(Item[] memory _givings, Item[][] memory _receivings)
        external;

    function acceptOffer(uint256 _tradeId, uint256 _itemsId) external;

    function createCounterOffer(uint256 _tradeId, Item[] memory _offerItems)
        external;

    function acceptCounterOffer(uint256 _tradeId, uint256 _itemsId) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IFlexiSwap.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FlexiSwapCore is IFlexiSwap {
    using Counters for Counters.Counter;

    Counters.Counter internal _tradeIds;
    Counters.Counter internal _itemsIds;

    // tradeId => trade
    mapping(uint256 => Trade) internal _trades;

    // itemsId => items[]
    mapping(uint256 => Item[]) internal _items;

    // itemsId => initiatorAddress
    mapping(uint256 => address) internal _counterOfferInitiators;

    constructor() {
        // constructor
    }

    function registerItemsToStorage(Item[] memory _itemsToRegister)
        private
        returns (uint256)
    {
        uint256 itemsId = _itemsIds.current();
        _itemsIds.increment();
        for (uint256 i = 0; i < _itemsToRegister.length; i++) {
            _items[itemsId].push(_itemsToRegister[i]);
        }
        return itemsId;
    }

    function trade(uint256 _tradeId) external view returns (Trade memory) {
        return _trades[_tradeId];
    }

    function items(uint256 _itemsId) external view returns (Item[] memory) {
        return _items[_itemsId];
    }

    function createTrade(Item[] memory _givings, Item[][] memory _receivings)
        public
        virtual
        override
    {
        _tradeIds.increment();
        uint256 tradeId = _tradeIds.current();

        uint256[] memory receivingItemsIdsList = new uint256[](
            _receivings.length
        );

        uint256 givingItemsId = registerItemsToStorage(_givings);

        for (uint256 i = 0; i < _receivings.length; ++i) {
            uint256 receivingsItemsId = registerItemsToStorage(_receivings[i]);
            receivingItemsIdsList[i] = receivingsItemsId;
        }

        Trade memory trade = Trade({
            initiator: msg.sender,
            givingsId: givingItemsId,
            receivingsIds: receivingItemsIdsList,
            counterOfferItemsIds: new uint256[](0)
        });

        _trades[tradeId] = trade;

        emit TradeCreated(tradeId, trade);
    }

    function acceptOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        revert("Not implemented");
    }

    function createCounterOffer(uint256 _tradeId, Item[] memory _offerItems)
        public
        virtual
        override
    {
        uint256 counterOfferItemsId = registerItemsToStorage(_offerItems);

        _trades[_tradeId].counterOfferItemsIds.push(counterOfferItemsId);

        _counterOfferInitiators[counterOfferItemsId] = msg.sender;

        emit CounterOfferCreated(
            msg.sender,
            _tradeId,
            counterOfferItemsId
        );
    }

    function acceptCounterOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        revert("Not implemented");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}