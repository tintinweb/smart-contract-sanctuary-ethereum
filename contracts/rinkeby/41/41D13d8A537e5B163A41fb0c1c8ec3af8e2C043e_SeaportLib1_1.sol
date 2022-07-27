// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Seaport/1_1_structs.sol";

interface ISeaport {
    function fulfillBasicOrder(BasicOrderParameters memory parameters) external payable returns (bool fulfilled);

    function fulfillOrder(Order memory order, bytes32 fulfillerConduitKey) external payable returns (bool fulfilled);

    function fulfillAdvancedOrder(
        AdvancedOrder memory advancedOrder,
        CriteriaResolver[] memory criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvailableOrders(
        Order[] memory orders,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    ) external payable returns (bool[] memory availableOrders, Execution[] memory executions);

    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] memory criteriaResolvers,
        FulfillmentComponent[][] memory offerFulfillments,
        FulfillmentComponent[][] memory considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    ) external payable returns (bool[] memory availableOrders, Execution[] memory executions);

    function matchOrders(Order[] memory orders, Fulfillment[] memory fulfillments)
        external
        payable
        returns (Execution[] memory executions);

    function matchAdvancedOrders(
        AdvancedOrder[] memory orders,
        CriteriaResolver[] memory criteriaResolvers,
        Fulfillment[] memory fulfillments
    ) external payable returns (Execution[] memory executions);

    function cancel(OrderComponents[] memory orders) external returns (bool cancelled);

    function validate(Order[] memory orders) external returns (bool validated);

    function incrementCounter() external returns (uint256 newCounter);
}

error InputLengthMismatch();

contract SeaportLib1_1 {
    address public constant OPENSEA = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    struct SeaportBuyOrder {
        AdvancedOrder[] advancedOrders;
        CriteriaResolver[] criteriaResolvers;
        FulfillmentComponent[][] offerFulfillments;
        FulfillmentComponent[][] considerationFulfillments;
        bytes32 fulfillerConduitKey;
        address recipient;
        uint256 maximumFulfilled;
    }

    function fulfillAvailableAdvancedOrders(
        SeaportBuyOrder[] memory openSeaBuys,
        uint256[] memory msgValue,
        bool revertIfTrxFails
    ) external {
        uint256 l1 = openSeaBuys.length;
        if (l1 != msgValue.length) revert InputLengthMismatch();

        for (uint256 i = 0; i < l1; ) {
            _fulfillAvailableAdvancedOrders(openSeaBuys[i], msgValue[i], revertIfTrxFails);

            unchecked {
                ++i;
            }
        }
    }

    function _fulfillAvailableAdvancedOrders(
        SeaportBuyOrder memory _openSeaBuy,
        uint256 _msgValue,
        bool _revertIfTrxFails
    ) internal {
        bytes memory _data = abi.encodeWithSelector(
            ISeaport.fulfillAvailableAdvancedOrders.selector,
            _openSeaBuy.advancedOrders,
            _openSeaBuy.criteriaResolvers,
            _openSeaBuy.offerFulfillments,
            _openSeaBuy.considerationFulfillments,
            _openSeaBuy.fulfillerConduitKey,
            _openSeaBuy.recipient,
            _openSeaBuy.maximumFulfilled
        );

        (bool success, ) = OPENSEA.call{ value: _msgValue }(_data);

        if (!success && _revertIfTrxFails) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./1_1_enums.sol";

struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
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

struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

struct BasicOrderParameters {
    address considerationToken;
    uint256 considerationIdentifier;
    uint256 considerationAmount;
    address payable offerer;
    address zone;
    address offerToken;
    uint256 offerIdentifier;
    uint256 offerAmount;
    BasicOrderType basicOrderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 offererConduitKey;
    bytes32 fulfillerConduitKey;
    uint256 totalOriginalAdditionalRecipients;
    AdditionalRecipient[] additionalRecipients;
    bytes signature;
}

struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

enum Side {
    OFFER,
    CONSIDERATION
}

enum ItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155,
    ERC721_WITH_CRITERIA,
    ERC1155_WITH_CRITERIA
}

enum BasicOrderRouteType {
    ETH_TO_ERC721,
    ETH_TO_ERC1155,
    ERC20_TO_ERC721,
    ERC20_TO_ERC1155,
    ERC721_TO_ERC20,
    ERC1155_TO_ERC20
}

enum BasicOrderType {
    ETH_TO_ERC721_FULL_OPEN,
    ETH_TO_ERC721_PARTIAL_OPEN,
    ETH_TO_ERC721_FULL_RESTRICTED,
    ETH_TO_ERC721_PARTIAL_RESTRICTED,
    ETH_TO_ERC1155_FULL_OPEN,
    ETH_TO_ERC1155_PARTIAL_OPEN,
    ETH_TO_ERC1155_FULL_RESTRICTED,
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,
    ERC20_TO_ERC721_FULL_OPEN,
    ERC20_TO_ERC721_PARTIAL_OPEN,
    ERC20_TO_ERC721_FULL_RESTRICTED,
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,
    ERC20_TO_ERC1155_FULL_OPEN,
    ERC20_TO_ERC1155_PARTIAL_OPEN,
    ERC20_TO_ERC1155_FULL_RESTRICTED,
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,
    ERC721_TO_ERC20_FULL_OPEN,
    ERC721_TO_ERC20_PARTIAL_OPEN,
    ERC721_TO_ERC20_FULL_RESTRICTED,
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,
    ERC1155_TO_ERC20_FULL_OPEN,
    ERC1155_TO_ERC20_PARTIAL_OPEN,
    ERC1155_TO_ERC20_FULL_RESTRICTED,
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

enum OrderType {
    FULL_OPEN,
    PARTIAL_OPEN,
    FULL_RESTRICTED,
    PARTIAL_RESTRICTED
}