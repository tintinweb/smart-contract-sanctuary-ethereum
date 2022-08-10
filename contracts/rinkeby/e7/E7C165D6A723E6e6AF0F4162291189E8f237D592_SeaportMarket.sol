// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ISeaport {
    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
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

    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    struct OrderParameters {
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
        uint256 totalOriginalConsiderationItems;
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function fulfillOrder(Order memory order, bytes32 fulfillerConduitKey) external payable;
}

library SeaportMarket {
    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    function buyAsset(ISeaport.Order memory order, bytes32 fulfillerConduitKey) public {
        ISeaport(SEAPORT).fulfillOrder(order, fulfillerConduitKey);
    }
}