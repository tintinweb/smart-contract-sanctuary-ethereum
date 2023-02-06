// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISeaport {

    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }

    // prettier-ignore
    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    // prettier-ignore
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

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external returns (bool fulfilled);

    function information() external view returns (
        string memory version,
        bytes32 domainSeparator,
        address conduitController
    );
}

interface IConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract OkxMarketProxy {
    uint256 public constant MASK_128 = ((1 << 128) - 1);
    ISeaport public immutable OKX;

    constructor(ISeaport okx) {
        OKX = okx;
    }

    function fulfillAdvancedOrder(
        ISeaport.AdvancedOrder calldata advancedOrder,
        ISeaport.CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        uint256 payableAmount
    ) external payable {
        if (advancedOrder.parameters.consideration[0].itemType == ISeaport.ItemType.ERC20) {
            IERC20 token = IERC20(advancedOrder.parameters.consideration[0].token);
            address conduit = _getConduit(fulfillerConduitKey);

            token.approve(conduit, MASK_128);
            try OKX.fulfillAdvancedOrder(advancedOrder, criteriaResolvers, fulfillerConduitKey, msg.sender) {
                token.approve(conduit, 0);
            } catch (bytes memory reason) {
                token.approve(conduit, 0);

                uint256 reasonLength = reason.length;
                if (reasonLength == 0) {
                    revert("OKX.fulfillAdvancedOrder failed");
                } else {
                    assembly {
                        revert(add(reason, 0x20), reasonLength)
                    }
                }
            }
        } else {
            ISeaport okx = OKX;
            assembly {
                // selector for ISeaport.fulfillAdvancedOrder
                mstore(0x0, 0xe7acab24)

                // copy data
                calldatacopy(0x20, 0x4, sub(calldatasize(), 4))

                // modify recipient
                // 0x80 = 0x20(selector) + 0x20(advancedOrder.offset) + 0x20(criteriaResolvers.offset) + 0x20(fulfillerConduitKey)
                mstore(0x80, caller())

                if call(gas(), okx, payableAmount, 0x1c, calldatasize(), 0, 0) {
                    return(0, 0)
                }
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _getConduit(bytes32 conduitKey) internal view returns (address conduit) {
        conduit = address(OKX);
        if (conduitKey != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            (, , address conduitController) = OKX.information();
            (address _conduit, bool _exists) = IConduitController(conduitController).getConduit(conduitKey);
            if (_exists) {
                conduit = _conduit;
            }
        }
        return conduit;
    }
}