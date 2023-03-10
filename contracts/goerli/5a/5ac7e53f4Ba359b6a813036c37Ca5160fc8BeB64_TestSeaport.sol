/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED,

    // 4: contract order type
    CONTRACT
}

enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}


struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

struct OfferItem2 {
    uint8 itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct OfferItem3 {
    uint256 itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

struct OrderParameters2 {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem2[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

struct Item {
    uint256 startAmount;
    uint256 endAmount;
}


struct Items {
    Item[] items;
}

struct OfferItem2Parameters {
    OfferItem2[] offer; // 0x40
}

struct OfferItem3Parameters {
    OfferItem3[] offer; // 0x40
}

contract TestSeaport {

    uint public count;

    function fulfillAdvancedOrder(
        /**
         * @custom:name advancedOrder
         */
        AdvancedOrder calldata,
        /**
         * @custom:name criteriaResolvers
         */
        CriteriaResolver[] calldata,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }

    function fulfillOrderParameters(
        OrderParameters calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }

    function fulfillOrderParameters2(
        OrderParameters2 calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }

    function fulfillOfferItem(
        OfferItem calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }


    function fulfillItem(
        Item[] calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }


    function fulfillItems(
        Items calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }


    function fulfillOfferItem2(
        OfferItem2Parameters calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }

    function fulfillOfferItem3(
        OfferItem3Parameters calldata params
    ) external payable returns (bool fulfilled) {
        count++;
        return true;
    }
}