//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./FlexiSwapCore.sol";

contract FlexiSwap is FlexiSwapCore {
    uint256 private MAX_OFFER_ITEMS = 10;
    uint256 private MAX_OFFERS_PER_TRADE = 10;

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
            if (
                counterOfferer == _counterOfferInitiators[counterOfferItemsId]
            ) {
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

    function acceptOffer(
        uint256 _tradeId,
        uint256 _itemsId,
        Item[] memory _additionalAssets
    )
        public
        virtual
        override
        tradeExists(_tradeId)
        notTradeOwner(_tradeId)
        offerExists(_tradeId, _itemsId)
    {
        super.acceptOffer(_tradeId, _itemsId, _additionalAssets);
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
        tradeExists(_tradeId)
        isTradeOwner(_tradeId)
        counterOfferExists(_tradeId, _itemsId)
    {
        super.acceptCounterOffer(_tradeId, _itemsId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./IFlexiSwap.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

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

    function verifyApproved(Item[] memory _itemsToVerify) private view {
        for (uint256 i = 0; i < _itemsToVerify.length; ++i) {
            if (
                IERC721(_itemsToVerify[i].nftAddress).getApproved(
                    _itemsToVerify[i].tokenId
                ) != address(this)
            ) {
                revert TokenNotApproved(
                    _itemsToVerify[i].nftAddress,
                    _itemsToVerify[i].tokenId
                );
            }
        }
    }

    function verifyAdditionalAssets(
        Item[] memory _orderItems,
        Item[] memory _additionalAssets
    ) private pure returns (bool) {
        uint256 _orderAdditionalAssetsCount = 0;
        for (uint256 i = 0; i < _additionalAssets.length; ++i) {
            for (uint256 j = 0; j < _orderItems.length; ++j) {
                if (_orderItems[j].isEmptyToken) {
                    _orderAdditionalAssetsCount++;
                }
            }
        }

        if (_orderAdditionalAssetsCount != _additionalAssets.length) {
            revert InvalidAdditionalAssets();
        }

        for (uint256 i = 0; i < _additionalAssets.length; ++i) {
            bool isFound = false;
            for (uint256 j = 0; j < _orderItems.length; ++j) {
                if (
                    _orderItems[j].isEmptyToken &&
                    _additionalAssets[j].nftAddress == _orderItems[i].nftAddress
                ) {
                    isFound = true;
                    break;
                }
            }
            if (!isFound) {
                revert InvalidAdditionalAssets();
            }
        }

        return true;
    }

    function batchTransfer(
        Item[] memory _itemsToTransfer,
        address _from,
        address _to
    ) private {
        for (uint256 i = 0; i < _itemsToTransfer.length; ++i) {
            Item memory itemToTransfer = _itemsToTransfer[i];
            IERC721(itemToTransfer.nftAddress).safeTransferFrom(
                _from,
                _to,
                itemToTransfer.tokenId
            );
        }
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
        Item[] memory givingItems = _items[givingItemsId];
        verifyApproved(givingItems);

        for (uint256 i = 0; i < _receivings.length; ++i) {
            uint256 receivingsItemsId = registerItemsToStorage(_receivings[i]);
            receivingItemsIdsList[i] = receivingsItemsId;
        }

        Trade memory _trade = Trade({
            initiator: msg.sender,
            givingsId: givingItemsId,
            receivingsIds: receivingItemsIdsList,
            counterOfferItemsIds: new uint256[](0)
        });

        _trades[tradeId] = _trade;

        emit TradeCreated(tradeId, _trade);
    }

    function acceptOffer(
        uint256 _tradeId,
        uint256 _itemsId,
        Item[] memory _additionalAssets
    ) public virtual override {
        Trade memory _trade = _trades[_tradeId];
        Item[] memory items_ = _items[_itemsId];

        bool validAdditionalAssets = verifyAdditionalAssets(
            items_,
            _additionalAssets
        );

        if (!validAdditionalAssets) {
            revert InvalidAdditionalAssets();
        }

        Item[] memory givings = _items[_trade.givingsId];

        verifyApproved(givings);

        batchTransfer(givings, _trade.initiator, msg.sender);
        batchTransfer(items_, msg.sender, _trade.initiator);
        batchTransfer(_additionalAssets, msg.sender, _trade.initiator);

        emit TradeAccepted(msg.sender, _tradeId, _itemsId);
    }

    function createCounterOffer(uint256 _tradeId, Item[] memory _offerItems)
        public
        virtual
        override
    {
        uint256 counterOfferItemsId = registerItemsToStorage(_offerItems);
        _trades[_tradeId].counterOfferItemsIds.push(counterOfferItemsId);
        _counterOfferInitiators[counterOfferItemsId] = msg.sender;
        Item[] memory counterOfferItems = _items[counterOfferItemsId];
        verifyApproved(counterOfferItems);

        emit CounterOfferCreated(msg.sender, _tradeId, counterOfferItemsId);
    }

    function acceptCounterOffer(uint256 _tradeId, uint256 _itemsId)
        public
        virtual
        override
    {
        Trade memory _trade = _trades[_tradeId];
        Item[] memory items_ = _items[_itemsId];
        Item[] memory givings = _items[_trade.givingsId];

        address counterOfferInitiator = _counterOfferInitiators[_itemsId];

        batchTransfer(givings, _trade.initiator, counterOfferInitiator);
        batchTransfer(items_, counterOfferInitiator, _trade.initiator);

        emit CounterOfferAccepted(_tradeId, _itemsId);
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
    error TokenNotApproved(address nftAddress, uint256 tokenId);
    error InvalidAdditionalAssets();

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

    // additionalAssets is a list of additional assets that the initiator wants to receive in addition to the items in the trade
    // for exmple, if trade initiator stated that he wants 2 nfts from collection A in addition, then additionalAssets
    // should contain strictly 2 nfts from collection A
    function acceptOffer(uint256 _tradeId, uint256 _itemsId, Item[] memory _additionalAssets) external;

    function createCounterOffer(uint256 _tradeId, Item[] memory _offerItems)
        external;

    function acceptCounterOffer(uint256 _tradeId, uint256 _itemsId) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}