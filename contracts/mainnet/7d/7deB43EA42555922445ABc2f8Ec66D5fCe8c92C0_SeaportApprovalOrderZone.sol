// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISeaport {
    enum OrderType {
        FULL_OPEN,
        PARTIAL_OPEN,
        FULL_RESTRICTED,
        PARTIAL_RESTRICTED
    }

    enum ItemType {
        NATIVE,
        ERC20,
        ERC721,
        ERC1155,
        ERC721_WITH_CRITERIA,
        ERC1155_WITH_CRITERIA
    }

    enum Side {
        OFFER,
        CONSIDERATION
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
        address recipient;
    }

    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address recipient;
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

    struct Order {
        OrderParameters parameters;
        bytes signature;
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

    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }

    function getOrderHash(OrderComponents calldata order)
        external
        view
        returns (bytes32 orderHash);

    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    function getCounter(address offerer)
        external
        view
        returns (uint256 counter);

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    function matchAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ISeaport} from "../interfaces/ISeaport.sol";

// One way to stay approval-less is to use one-time Seaport orders
// that effectively act as gifts. These are prone to front-running
// though. To prevent this, all such approval orders should ensure
// the offerer matches the transaction's sender (eg. `tx.origin`).
// Although relying on `tx.origin` is considered bad practice, the
// validity time of these orders should be in the range of minutes
// so that the risk of reusing them via a malicious contract which
// forwards them is low.
contract SeaportApprovalOrderZone {
    // --- Errors ---

    error Unauthorized();

    // --- Seaport `ZoneInterface` overrides ---

    function isValidOrder(
        bytes32,
        address,
        address offerer,
        bytes32
    ) external view returns (bytes4 validOrderMagicValue) {
        if (offerer != tx.origin) {
            revert Unauthorized();
        }

        validOrderMagicValue = this.isValidOrder.selector;
    }

    function isValidOrderIncludingExtraData(
        bytes32,
        address,
        ISeaport.AdvancedOrder calldata order,
        bytes32[] calldata,
        ISeaport.CriteriaResolver[] calldata
    ) external view returns (bytes4 validOrderMagicValue) {
        if (order.parameters.offerer != tx.origin) {
            revert Unauthorized();
        }

        validOrderMagicValue = this.isValidOrder.selector;
    }
}