// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/transfer-manager/contracts/lib/LibTransfer.sol";
import "@rarible/lib-bp/contracts/BpLibrary.sol";
import "@rarible/lib-part/contracts/LibPart.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

import "./interfaces/IWyvernExchange.sol";
import "./interfaces/IExchangeV2.sol";
import "./interfaces/ISeaPort.sol";
import "./interfaces/Ix2y2.sol";
import "./interfaces/ILooksRare.sol";

import "./libraries/IsPausable.sol";

contract ExchangeWrapper is Ownable, ERC721Holder, ERC1155Holder, IsPausable {
    using LibTransfer for address;
    using BpLibrary for uint;
    using SafeMath for uint;

    address public immutable wyvernExchange;
    address public immutable exchangeV2;
    address public immutable seaPort;
    address public immutable x2y2;
    address public immutable looksRare;
    address public immutable sudoswap;

    event Execution(bool result);

    enum Markets {
        ExchangeV2,
        WyvernExchange,
        SeaPort,
        X2Y2,
        LooksRareOrders,
        SudoSwap
    }

    /**
        @notice struct for the purchase data
        @param marketId - market key from Markets enum (what market to use)
        @param amount - eth price (amount of eth that needs to be send to the marketplace)
        @param fees - 2 fees (in base points) that are going to be taken on top of order amount encoded in 1 uint256
                        bytes (29,30) used for the first value (goes to feeRecipientFirst)
                        bytes (31,32) are used for the second value (goes to feeRecipientSecond)
        @param data - data for market call 
     */
    struct PurchaseDetails {
        Markets marketId;
        uint256 amount;
        uint fees;
        bytes data;
    }

    constructor(
        address _wyvernExchange,
        address _exchangeV2,
        address _seaPort,
        address _x2y2,
        address _looksRare,
        address _sudoswap
    ) {
        wyvernExchange = _wyvernExchange;
        exchangeV2 = _exchangeV2;
        seaPort = _seaPort;
        x2y2 = _x2y2;
        looksRare = _looksRare;
        sudoswap = _sudoswap;
    }

    /**
        @notice executes a single purchase
        @param purchaseDetails - deatails about the purchase (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
     */
    function singlePurchase(PurchaseDetails memory purchaseDetails, address feeRecipientFirst, address feeRecipientSecond) external payable {
        requireNotPaused();

        (bool success, uint feeAmountFirst, uint feeAmountSecond) = purchase(purchaseDetails, false);
        emit Execution(success);
        
        transferFee(feeAmountFirst, feeRecipientFirst);
        transferFee(feeAmountSecond, feeRecipientSecond);

        transferChange();
    }

    /**
        @notice executes an array of purchases
        @param purchaseDetails - array of deatails about the purchases (more info in PurchaseDetails struct)
        @param feeRecipientFirst - address of the first fee recipient
        @param feeRecipientSecond - address of the second fee recipient
        @param allowFail - true if fails while executing orders are allowed, false if fail of a single order means fail of the whole batch
     */
    
    function bulkPurchase(PurchaseDetails[] memory purchaseDetails, address feeRecipientFirst, address feeRecipientSecond, bool allowFail) external payable {
        requireNotPaused();

        uint sumFirstFees = 0;
        uint sumSecondFees = 0;
        bool result = false;

        for (uint i = 0; i < purchaseDetails.length; i++) {
            (bool success, uint firstFeeAmount, uint secondFeeAmount) = purchase(purchaseDetails[i], allowFail);

            result = result || success;
            emit Execution(success);

            sumFirstFees = sumFirstFees.add(firstFeeAmount);
            sumSecondFees = sumSecondFees.add(secondFeeAmount);
        }

        require(result, "no successful executions");

        transferFee(sumFirstFees, feeRecipientFirst);
        transferFee(sumSecondFees, feeRecipientSecond);

        transferChange();
    }

    /**
        @notice executes one purchase
        @param purchaseDetails - details about the purchase
        @param allowFail - true if errors are handled, false if revert on errors
        @return result false if execution failed, true if succeded
        @return firstFeeAmount amount of the first fee of the purchase, 0 if failed
        @return secondFeeAmount amount of the second fee of the purchase, 0 if failed
     */
    function purchase(PurchaseDetails memory purchaseDetails, bool allowFail) internal returns(bool, uint, uint) {
        uint paymentAmount = purchaseDetails.amount;
        if (purchaseDetails.marketId == Markets.SeaPort){
            (bool success,) = address(seaPort).call{value : paymentAmount}(purchaseDetails.data);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase SeaPort failed");
            }
        } else if (purchaseDetails.marketId == Markets.WyvernExchange) {
            (bool success,) = address(wyvernExchange).call{value : paymentAmount}(purchaseDetails.data);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase wyvernExchange failed");
            }
        } else if (purchaseDetails.marketId == Markets.ExchangeV2) {
            (bool success,) = address(exchangeV2).call{value : paymentAmount}(purchaseDetails.data);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase rarible failed");
            }
        } else if (purchaseDetails.marketId == Markets.X2Y2) {
            Ix2y2.RunInput memory input = abi.decode(purchaseDetails.data, (Ix2y2.RunInput));

            if (allowFail) {
                try Ix2y2(x2y2).run{value : paymentAmount}(input) {
                } catch {
                    return (false, 0, 0);
                }
            } else {
                Ix2y2(x2y2).run{value : paymentAmount}(input);
            }
            for (uint i = 0; i < input.orders.length; i++) {
                for (uint j = 0; j < input.orders[i].items.length; j++) {
                    Ix2y2.Pair[] memory pairs = abi.decode(input.orders[i].items[j].data, (Ix2y2.Pair[]));
                    for (uint256 k = 0; k < pairs.length; k++) {
                        Ix2y2.Pair memory p = pairs[k];
                        IERC721Upgradeable(address(p.token)).safeTransferFrom(address(this), _msgSender(), p.tokenId);
                    }    
                }
            } 
        } else if (purchaseDetails.marketId == Markets.LooksRareOrders) {
            (LibLooksRare.TakerOrder memory takerOrder, LibLooksRare.MakerOrder memory makerOrder, bytes4 typeNft) = abi.decode(purchaseDetails.data, (LibLooksRare.TakerOrder, LibLooksRare.MakerOrder, bytes4));
            if (allowFail) {
                try ILooksRare(looksRare).matchAskWithTakerBidUsingETHAndWETH{value : paymentAmount}(takerOrder, makerOrder) {
                }   catch {
                    return (false, 0, 0);
                }
            } else {
                ILooksRare(looksRare).matchAskWithTakerBidUsingETHAndWETH{value : paymentAmount}(takerOrder, makerOrder);
            }
            if (typeNft == LibAsset.ERC721_ASSET_CLASS) {
                IERC721Upgradeable(makerOrder.collection).safeTransferFrom(address(this), _msgSender(), makerOrder.tokenId);
            } else if (typeNft == LibAsset.ERC1155_ASSET_CLASS) {
                IERC1155Upgradeable(makerOrder.collection).safeTransferFrom(address(this), _msgSender(), makerOrder.tokenId, makerOrder.amount, "");
            } else {
                revert("Unknown token type");
            }
        } else if (purchaseDetails.marketId == Markets.SudoSwap) {
            (bool success,) = address(sudoswap).call{value : paymentAmount}(purchaseDetails.data);
            if (allowFail) {
                if (!success) {
                    return (false, 0, 0);
                }
            } else {
                require(success, "Purchase sudoswap failed");
            }
        } else {
            revert("Unknown purchase details");
        }
        
        (uint firstFeeAmount, uint secondFeeAmount) = getFees(purchaseDetails.fees, purchaseDetails.amount);
        return (true, firstFeeAmount, secondFeeAmount);
    }

    /**
        @notice transfers fee to feeRecipient
        @param feeAmount - amount to be transfered
        @param feeRecipient - address of the recipient
     */
    function transferFee(uint feeAmount, address feeRecipient) internal {
        if (feeAmount > 0 && feeRecipient != address(0)) {
            LibTransfer.transferEth(feeRecipient, feeAmount);
        }
    }

    /**
        @notice transfers change back to sender
     */
    function transferChange() internal {
        uint ethAmount = address(this).balance;
        if (ethAmount > 0) {
            address(msg.sender).transferEth(ethAmount);
        }
    }

    /**
        @notice parses fees in base points from one uint and calculates real amount of fees
        @param fees two fees encoded in one uint, 29 and 30 bytes are used for the first fee, 31 and 32 bytes for second fee
        @param amount price of the order
        @return firstFeeAmount real amount for the first fee
        @return secondFeeAmount real amount for the second fee
     */
    function getFees(uint fees, uint amount) internal pure returns(uint, uint) {
        uint firstFee = uint(uint16(fees >> 16));
        uint secondFee = uint(uint16(fees));
        return (amount.bp(firstFee), amount.bp(secondFee));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

interface IWyvernExchange {
    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata)
    external
    payable;

    enum Side {
        Buy,
        Sell
    }

    enum SaleKind {
        FixedPrice,
        DutchAuction
    }

    function calculateFinalPrice(
        Side side,
        SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@rarible/exchange-v2/contracts/ExchangeV2.sol";

import {RoyaltiesRegistry} from "@rarible/royalties-registry/contracts/RoyaltiesRegistry.sol";
import {TransferProxy} from "@rarible/transfer-proxy/contracts/proxy/TransferProxy.sol";
import {ERC20TransferProxy} from "@rarible/transfer-proxy/contracts/proxy/ERC20TransferProxy.sol";

interface IExchangeV2 {
    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

    function directPurchase(
        LibDirectTransfer.Purchase calldata direct
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "../libraries/LibSeaPort.sol";

interface ISeaPort {
    function fulfillAdvancedOrder(
        LibSeaPort.AdvancedOrder calldata advancedOrder,
        LibSeaPort.CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    function fulfillAvailableAdvancedOrders(
        LibSeaPort.AdvancedOrder[] memory advancedOrders,
        LibSeaPort.CriteriaResolver[] calldata criteriaResolvers,
        LibSeaPort.FulfillmentComponent[][] calldata offerFulfillments,
        LibSeaPort.FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    ) external payable returns (bool[] memory availableOrders, LibSeaPort.Execution[] memory executions);

    function fulfillBasicOrder(LibSeaPort.BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

library LibSeaPort {
    /**
      * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
      *      matching, a group of six functions may be called that only requires a
      *      subset of the usual order arguments. Note the use of a "basicOrderType"
      *      enum; this represents both the usual order type as well as the "route"
      *      of the basic order (a simple derivation function for the basic order
      *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
      */
    struct BasicOrderParameters {
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        BasicOrderType basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
    }
    /**
     * @dev Basic orders can supply any number of additional recipients, with the
     *      implied assumption that they are supplied from the offered ETH (or other
     *      native token) or ERC20 token for the order.
     */
    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    // prettier-ignore
    enum BasicOrderType {
        // 0: no partial fills, anyone can execute
        ETH_TO_ERC721_FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        ETH_TO_ERC721_PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        ETH_TO_ERC721_FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC721_PARTIAL_RESTRICTED,

        // 4: no partial fills, anyone can execute
        ETH_TO_ERC1155_FULL_OPEN,

        // 5: partial fills supported, anyone can execute
        ETH_TO_ERC1155_PARTIAL_OPEN,

        // 6: no partial fills, only offerer or zone can execute
        ETH_TO_ERC1155_FULL_RESTRICTED,

        // 7: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,

        // 8: no partial fills, anyone can execute
        ERC20_TO_ERC721_FULL_OPEN,

        // 9: partial fills supported, anyone can execute
        ERC20_TO_ERC721_PARTIAL_OPEN,

        // 10: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC721_FULL_RESTRICTED,

        // 11: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,

        // 12: no partial fills, anyone can execute
        ERC20_TO_ERC1155_FULL_OPEN,

        // 13: partial fills supported, anyone can execute
        ERC20_TO_ERC1155_PARTIAL_OPEN,

        // 14: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC1155_FULL_RESTRICTED,

        // 15: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

        // 16: no partial fills, anyone can execute
        ERC721_TO_ERC20_FULL_OPEN,

        // 17: partial fills supported, anyone can execute
        ERC721_TO_ERC20_PARTIAL_OPEN,

        // 18: no partial fills, only offerer or zone can execute
        ERC721_TO_ERC20_FULL_RESTRICTED,

        // 19: partial fills supported, only offerer or zone can execute
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,

        // 20: no partial fills, anyone can execute
        ERC1155_TO_ERC20_FULL_OPEN,

        // 21: partial fills supported, anyone can execute
        ERC1155_TO_ERC20_PARTIAL_OPEN,

        // 22: no partial fills, only offerer or zone can execute
        ERC1155_TO_ERC20_FULL_RESTRICTED,

        // 23: partial fills supported, only offerer or zone can execute
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }

     /**
     * @dev The full set of order components, with the exception of the counter,
     *      must be supplied when fulfilling more sophisticated orders or groups of
     *      orders. The total number of original consideration items must also be
     *      supplied, as the caller may specify additional consideration items.
     */
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

    /**
     * @dev Orders require a signature in addition to the other order parameters.
     */
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

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    /**
     * @dev A consideration item has the same five components as an offer item and
     *      an additional sixth component designating the required recipient of the
     *      item.
     */
    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
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

    /**
     * @dev A fulfillment is applied to a group of orders. It decrements a series of
     *      offer and consideration items, then generates a single execution
     *      element. A given fulfillment can be applied to as many offer and
     *      consideration items as desired, but must contain at least one offer and
     *      at least one consideration that match. The fulfillment must also remain
     *      consistent on all key parameters across all offer items (same offerer,
     *      token, type, tokenId, and conduit preference) as well as across all
     *      consideration items (token, type, tokenId, and recipient).
     */
    struct Fulfillment {
        FulfillmentComponent[] offerComponents;
        FulfillmentComponent[] considerationComponents;
    }

    /**
     * @dev Each fulfillment component contains one index referencing a specific
     *      order and another referencing a specific offer or consideration item.
     */
    struct FulfillmentComponent {
        uint256 orderIndex;
        uint256 itemIndex;
    }

    /**
     * @dev An execution is triggered once all consideration items have been zeroed
     *      out. It sends the item in question from the offerer to the item's
     *      recipient, optionally sourcing approvals from either this contract
     *      directly or from the offerer's chosen conduit if one is specified. An
     *      execution is not provided as an argument, but rather is derived via
     *      orders, criteria resolvers, and fulfillments (where the total number of
     *      executions will be less than or equal to the total number of indicated
     *      fulfillments) and returned as part of `matchOrders`.
     */
    struct Execution {
        ReceivedItem item;
        address offerer;
        bytes32 conduitKey;
    }

    /**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
    struct ReceivedItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
        address payable recipient;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    // prettier-ignore
    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

interface Ix2y2 {

    struct OrderItem {
        uint256 price;
        bytes data;
    }

    struct Pair {
        address token;
        uint256 tokenId;
    }

    struct Order {
        uint256 salt;
        address user;
        uint256 network;
        uint256 intent;
        uint256 delegateType;
        uint256 deadline;
        address currency;
        bytes dataMask;
        OrderItem[] items;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 signVersion;
    }

    struct Fee {
        uint256 percentage;
        address to;
    }

    struct SettleDetail {
        Op op;
        uint256 orderIdx;
        uint256 itemIdx;
        uint256 price;
        bytes32 itemHash;
        address executionDelegate;
        bytes dataReplacement;
        uint256 bidIncentivePct;
        uint256 aucMinIncrementPct;
        uint256 aucIncDurationSecs;
        Fee[] fees;
    }

    struct SettleShared {
        uint256 salt;
        uint256 deadline;
        uint256 amountToEth;
        uint256 amountToWeth;
        address user;
        bool canFail;
    }

    struct RunInput {
        Order[] orders;
        SettleDetail[] details;
        SettleShared shared;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum Op {
        INVALID,
        // off-chain
        COMPLETE_SELL_OFFER,
        COMPLETE_BUY_OFFER,
        CANCEL_OFFER,
        // auction
        BID,
        COMPLETE_AUCTION,
        REFUND_AUCTION,
        REFUND_AUCTION_STUCK_ITEM
    }

    function run(RunInput memory input) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/LibLooksRare.sol";

interface ILooksRare {
    function matchAskWithTakerBidUsingETHAndWETH(
        LibLooksRare.TakerOrder calldata takerBid,
        LibLooksRare.MakerOrder calldata makerAsk
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

library LibLooksRare {
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IsPausable is Ownable {
    bool public paused;

    event Paused(bool paused);

    function pause(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    function requireNotPaused() internal view {
        require (!paused, "the contract is paused");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibTransfer {
    function transferEth(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library BpLibrary {
    using SafeMathUpgradeable for uint;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ExchangeV2Core.sol";
import "@rarible/transfer-manager/contracts/RaribleTransferManager.sol";

contract ExchangeV2 is ExchangeV2Core, RaribleTransferManager {
    function __ExchangeV2_init(
        address _transferProxy,
        address _erc20TransferProxy,
        uint newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __TransferExecutor_init_unchained(_transferProxy, _erc20TransferProxy);
        __RaribleTransferManager_init_unchained(newProtocolFee, newDefaultFeeReceiver, newRoyaltiesProvider);
        __OrderValidator_init_unchained();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./libraries/LibFill.sol";
import "./libraries/LibOrderData.sol";
import "./libraries/LibDirectTransfer.sol";
import "./OrderValidator.sol";
import "./AssetMatcher.sol";

import "@rarible/transfer-manager/contracts/TransferExecutor.sol";
import "@rarible/transfer-manager/contracts/interfaces/ITransferManager.sol";
import "@rarible/transfer-manager/contracts/lib/LibDeal.sol";

abstract contract ExchangeV2Core is Initializable, OwnableUpgradeable, AssetMatcher, TransferExecutor, OrderValidator, ITransferManager {
    using SafeMathUpgradeable for uint;
    using LibTransfer for address;

    uint256 private constant UINT256_MAX = 2 ** 256 - 1;

    //state of the orders
    mapping(bytes32 => uint) public fills;

    //events
    event Cancel(bytes32 hash);
    event Match(bytes32 leftHash, bytes32 rightHash, uint newLeftFill, uint newRightFill);

    function cancel(LibOrder.Order memory order) external {
        require(_msgSender() == order.maker, "not a maker");
        require(order.salt != 0, "0 salt can't be used");
        bytes32 orderKeyHash = LibOrder.hashKey(order);
        fills[orderKeyHash] = UINT256_MAX;
        emit Cancel(orderKeyHash);
    }

    /**
     * @dev function, generate sellOrder and buyOrder from parameters and call validateAndMatch() for purchase transaction
 
    */

    function directPurchase(
        LibDirectTransfer.Purchase calldata direct
    ) external payable{
        LibAsset.AssetType memory paymentAssetType = getPaymentAssetType(direct.paymentToken);
                
        LibOrder.Order memory sellOrder = LibOrder.Order(
            direct.sellOrderMaker,
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.sellOrderNftAmount
            ),
            address(0),
            LibAsset.Asset(
                paymentAssetType,
                direct.sellOrderPaymentAmount
            ),
            direct.sellOrderSalt,
            direct.sellOrderStart,
            direct.sellOrderEnd,
            direct.sellOrderDataType,
            direct.sellOrderData
        );

        LibOrder.Order memory buyOrder = LibOrder.Order(
            address(0),
            LibAsset.Asset(
                paymentAssetType,
                direct.buyOrderPaymentAmount
            ),
            address(0),
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.buyOrderNftAmount
            ),
            0,
            0,
            0,
            getOtherOrderType(direct.sellOrderDataType),
            direct.buyOrderData
        );

        validateFull(sellOrder, direct.sellOrderSignature);

        matchAndTransfer(sellOrder, buyOrder);
    }

    /**
     * @dev function, generate sellOrder and buyOrder from parameters and call validateAndMatch() for accept bid transaction
     * @param direct struct with parameters for accept bid operation
     */
    function directAcceptBid(
        LibDirectTransfer.AcceptBid calldata direct
    ) external payable {
        LibAsset.AssetType memory paymentAssetType = getPaymentAssetType(direct.paymentToken);

        LibOrder.Order memory buyOrder = LibOrder.Order(
            direct.bidMaker,
            LibAsset.Asset(
                paymentAssetType,
                direct.bidPaymentAmount
            ),
            address(0),
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.bidNftAmount
            ),
            direct.bidSalt,
            direct.bidStart,
            direct.bidEnd,
            direct.bidDataType,
            direct.bidData
        );

        LibOrder.Order memory sellOrder = LibOrder.Order(
            address(0),
            LibAsset.Asset(
                LibAsset.AssetType(
                    direct.nftAssetClass,
                    direct.nftData
                ),
                direct.sellOrderNftAmount
            ),
            address(0),
            LibAsset.Asset(
                paymentAssetType,
                direct.sellOrderPaymentAmount
            ),
            0,
            0,
            0,
            getOtherOrderType(direct.bidDataType),
            direct.sellOrderData
        );

        validateFull(buyOrder, direct.bidSignature);

        matchAndTransfer(sellOrder, buyOrder);
    }

    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable {
        validateOrders(orderLeft, signatureLeft, orderRight, signatureRight);
        matchAndTransfer(orderLeft, orderRight);
    }

    /**
      * @dev function, validate orders
      * @param orderLeft left order
      * @param signatureLeft order left signature
      * @param orderRight right order
      * @param signatureRight order right signature
      */
    function validateOrders(LibOrder.Order memory orderLeft, bytes memory signatureLeft, LibOrder.Order memory orderRight, bytes memory signatureRight) internal view {
        validateFull(orderLeft, signatureLeft);
        validateFull(orderRight, signatureRight);
        if (orderLeft.taker != address(0)) {
            if (orderRight.maker != address(0))
                require(orderRight.maker == orderLeft.taker, "leftOrder.taker verification failed");
        }
        if (orderRight.taker != address(0)) {
            if (orderLeft.maker != address(0))
                require(orderRight.taker == orderLeft.maker, "rightOrder.taker verification failed");
        }
    }

    /**
        @notice matches valid orders and transfers their assets
        @param orderLeft the left order of the match
        @param orderRight the right order of the match
    */
    function matchAndTransfer(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal {
        (LibAsset.AssetType memory makeMatch, LibAsset.AssetType memory takeMatch) = matchAssets(orderLeft, orderRight);

        (LibOrderData.GenericOrderData memory leftOrderData, LibOrderData.GenericOrderData memory rightOrderData, LibFill.FillResult memory newFill) =
            parseOrdersSetFillEmitMatch(orderLeft, orderRight);

        (uint totalMakeValue, uint totalTakeValue) = doTransfers(
            LibDeal.DealSide(
                LibAsset.Asset( 
                    makeMatch,
                    newFill.leftValue
                ),
                leftOrderData.payouts,
                leftOrderData.originFees,
                proxies[makeMatch.assetClass],
                orderLeft.maker
            ), 
            LibDeal.DealSide(
                LibAsset.Asset( 
                    takeMatch,
                    newFill.rightValue
                ),
                rightOrderData.payouts,
                rightOrderData.originFees,
                proxies[takeMatch.assetClass],
                orderRight.maker
            ),
            getDealData(
                makeMatch.assetClass,
                takeMatch.assetClass,
                orderLeft.dataType,
                orderRight.dataType,
                leftOrderData,
                rightOrderData
            )
        );
        if (makeMatch.assetClass == LibAsset.ETH_ASSET_CLASS) {
            require(takeMatch.assetClass != LibAsset.ETH_ASSET_CLASS);
            require(msg.value >= totalMakeValue, "not enough eth");
            if (msg.value > totalMakeValue) {
                address(msg.sender).transferEth(msg.value.sub(totalMakeValue));
            }
        } else if (takeMatch.assetClass == LibAsset.ETH_ASSET_CLASS) {
            require(msg.value >= totalTakeValue, "not enough eth");
            if (msg.value > totalTakeValue) {
                address(msg.sender).transferEth(msg.value.sub(totalTakeValue));
            }
        }
    }

    function parseOrdersSetFillEmitMatch(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight
    ) internal returns (LibOrderData.GenericOrderData memory leftOrderData, LibOrderData.GenericOrderData memory rightOrderData, LibFill.FillResult memory newFill) {
        bytes32 leftOrderKeyHash = LibOrder.hashKey(orderLeft);
        bytes32 rightOrderKeyHash = LibOrder.hashKey(orderRight);

        address msgSender = _msgSender();
        if (orderLeft.maker == address(0)) {
            orderLeft.maker = msgSender;
        }
        if (orderRight.maker == address(0)) {
            orderRight.maker = msgSender;
        }

        leftOrderData = LibOrderData.parse(orderLeft);
        rightOrderData = LibOrderData.parse(orderRight);

        newFill = setFillEmitMatch(
            orderLeft,
            orderRight,
            leftOrderKeyHash,
            rightOrderKeyHash,
            leftOrderData.isMakeFill,
            rightOrderData.isMakeFill
        );
    }

    function getDealData(
        bytes4 makeMatchAssetClass,
        bytes4 takeMatchAssetClass,
        bytes4 leftDataType,
        bytes4 rightDataType,
        LibOrderData.GenericOrderData memory leftOrderData,
        LibOrderData.GenericOrderData memory rightOrderData
    ) internal pure returns(LibDeal.DealData memory dealData) {
        dealData.feeSide = LibFeeSide.getFeeSide(makeMatchAssetClass, takeMatchAssetClass);
        dealData.maxFeesBasePoint = getMaxFee(
            leftDataType,
            rightDataType,
            leftOrderData,
            rightOrderData,
            dealData.feeSide
        );
    }

    /**
        @notice determines the max amount of fees for the match
        @param dataTypeLeft data type of the left order
        @param dataTypeRight data type of the right order
        @param leftOrderData data of the left order
        @param rightOrderData data of the right order
        @param feeSide fee side of the match
        @return max fee amount in base points
    */
    function getMaxFee(
        bytes4 dataTypeLeft,
        bytes4 dataTypeRight,
        LibOrderData.GenericOrderData memory leftOrderData,
        LibOrderData.GenericOrderData memory rightOrderData,
        LibFeeSide.FeeSide feeSide
    ) internal pure returns(uint) {
        if (
            dataTypeLeft != LibOrderDataV3.V3_SELL &&
            dataTypeRight != LibOrderDataV3.V3_SELL &&
            dataTypeLeft != LibOrderDataV3.V3_BUY &&
            dataTypeRight != LibOrderDataV3.V3_BUY
        ){
            return 0;
        }

        uint matchFees = getSumFees(leftOrderData.originFees, rightOrderData.originFees);
        uint maxFee;
        if (feeSide == LibFeeSide.FeeSide.LEFT) {
            maxFee = rightOrderData.maxFeesBasePoint;
            require(
                dataTypeLeft == LibOrderDataV3.V3_BUY &&
                dataTypeRight == LibOrderDataV3.V3_SELL,
                "wrong V3 type1"
            );

        } else if (feeSide == LibFeeSide.FeeSide.RIGHT) {
            maxFee = leftOrderData.maxFeesBasePoint;
            require(
                dataTypeRight == LibOrderDataV3.V3_BUY &&
                dataTypeLeft == LibOrderDataV3.V3_SELL,
                "wrong V3 type2"
            );
        } else {
            return 0;
        }
        require(
            maxFee > 0 &&
            maxFee >= matchFees &&
            maxFee <= 1000,
            "wrong maxFee"
        );

        return maxFee;
    }

    /**
        @notice calculates amount of fees for the match
        @param originLeft origin fees of the left order
        @param originRight origin fees of the right order
        @return sum of all fees for the match (protcolFee + leftOrder.originFees + rightOrder.originFees)
     */
    function getSumFees(LibPart.Part[] memory originLeft, LibPart.Part[] memory originRight) internal pure returns(uint) {
        uint result = 0;

        //adding left origin fees
        for (uint i; i < originLeft.length; i ++) {
            result = result + originLeft[i].value;
        }

        //adding right origin fees
        for (uint i; i < originRight.length; i ++) {
            result = result + originRight[i].value;
        }

        return result;
    }

    /**
        @notice calculates fills for the matched orders and set them in "fills" mapping
        @param orderLeft left order of the match
        @param orderRight right order of the match
        @param leftMakeFill true if the left orders uses make-side fills, false otherwise
        @param rightMakeFill true if the right orders uses make-side fills, false otherwise
        @return returns change in orders' fills by the match 
    */
    function setFillEmitMatch(
        LibOrder.Order memory orderLeft,
        LibOrder.Order memory orderRight,
        bytes32 leftOrderKeyHash,
        bytes32 rightOrderKeyHash,
        bool leftMakeFill,
        bool rightMakeFill
    ) internal returns (LibFill.FillResult memory) {
        uint leftOrderFill = getOrderFill(orderLeft.salt, leftOrderKeyHash);
        uint rightOrderFill = getOrderFill(orderRight.salt, rightOrderKeyHash);
        LibFill.FillResult memory newFill = LibFill.fillOrder(orderLeft, orderRight, leftOrderFill, rightOrderFill, leftMakeFill, rightMakeFill);

        require(newFill.rightValue > 0 && newFill.leftValue > 0, "nothing to fill");

        if (orderLeft.salt != 0) {
            if (leftMakeFill) {
                fills[leftOrderKeyHash] = leftOrderFill.add(newFill.leftValue);
            } else {
                fills[leftOrderKeyHash] = leftOrderFill.add(newFill.rightValue);
            }
        }

        if (orderRight.salt != 0) {
            if (rightMakeFill) {
                fills[rightOrderKeyHash] = rightOrderFill.add(newFill.rightValue);
            } else {
                fills[rightOrderKeyHash] = rightOrderFill.add(newFill.leftValue);
            }
        }

        emit Match(leftOrderKeyHash, rightOrderKeyHash, newFill.rightValue, newFill.leftValue);

        return newFill;
    }

    function getOrderFill(uint salt, bytes32 hash) internal view returns (uint fill) {
        if (salt == 0) {
            fill = 0;
        } else {
            fill = fills[hash];
        }
    }

    function matchAssets(LibOrder.Order memory orderLeft, LibOrder.Order memory orderRight) internal view returns (LibAsset.AssetType memory makeMatch, LibAsset.AssetType memory takeMatch) {
        makeMatch = matchAssets(orderLeft.makeAsset.assetType, orderRight.takeAsset.assetType);
        require(makeMatch.assetClass != 0, "assets don't match");
        takeMatch = matchAssets(orderLeft.takeAsset.assetType, orderRight.makeAsset.assetType);
        require(takeMatch.assetClass != 0, "assets don't match");
    }

    function validateFull(LibOrder.Order memory order, bytes memory signature) internal view {
        LibOrder.validate(order);
        validate(order, signature);
    }

    function getPaymentAssetType(address token) internal pure returns(LibAsset.AssetType memory){
        LibAsset.AssetType memory result;
        if(token == address(0)) {
            result.assetClass = LibAsset.ETH_ASSET_CLASS;
        } else {
            result.assetClass = LibAsset.ERC20_ASSET_CLASS;
            result.data = abi.encode(token);
        }
        return result;
    }

    function getOtherOrderType(bytes4 dataType) internal pure returns(bytes4) {
        if (dataType == LibOrderDataV3.V3_SELL) {
            return LibOrderDataV3.V3_BUY;
        }
        if (dataType == LibOrderDataV3.V3_BUY) {
            return LibOrderDataV3.V3_SELL;
        }
        return dataType;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./LibOrder.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

library LibFill {
    using SafeMathUpgradeable for uint;

    struct FillResult {
        uint leftValue;
        uint rightValue;
    }

    struct IsMakeFill {
        bool leftMake;
        bool rightMake;
    }

    /**
     * @dev Should return filled values
     * @param leftOrder left order
     * @param rightOrder right order
     * @param leftOrderFill current fill of the left order (0 if order is unfilled)
     * @param rightOrderFill current fill of the right order (0 if order is unfilled)
     * @param leftIsMakeFill true if left orders fill is calculated from the make side, false if from the take side
     * @param rightIsMakeFill true if right orders fill is calculated from the make side, false if from the take side
     */
    function fillOrder(LibOrder.Order memory leftOrder, LibOrder.Order memory rightOrder, uint leftOrderFill, uint rightOrderFill, bool leftIsMakeFill, bool rightIsMakeFill) internal pure returns (FillResult memory) {
        (uint leftMakeValue, uint leftTakeValue) = LibOrder.calculateRemaining(leftOrder, leftOrderFill, leftIsMakeFill);
        (uint rightMakeValue, uint rightTakeValue) = LibOrder.calculateRemaining(rightOrder, rightOrderFill, rightIsMakeFill);

        //We have 3 cases here:
        if (rightTakeValue > leftMakeValue) { //1nd: left order should be fully filled
            return fillLeft(leftMakeValue, leftTakeValue, rightOrder.makeAsset.value, rightOrder.takeAsset.value);
        }//2st: right order should be fully filled or 3d: both should be fully filled if required values are the same
        return fillRight(leftOrder.makeAsset.value, leftOrder.takeAsset.value, rightMakeValue, rightTakeValue);
    }

    function fillRight(uint leftMakeValue, uint leftTakeValue, uint rightMakeValue, uint rightTakeValue) internal pure returns (FillResult memory result) {
        uint makerValue = LibMath.safeGetPartialAmountFloor(rightTakeValue, leftMakeValue, leftTakeValue);
        require(makerValue <= rightMakeValue, "fillRight: unable to fill");
        return FillResult(rightTakeValue, makerValue);
    }

    function fillLeft(uint leftMakeValue, uint leftTakeValue, uint rightMakeValue, uint rightTakeValue) internal pure returns (FillResult memory result) {
        uint rightTake = LibMath.safeGetPartialAmountFloor(leftTakeValue, rightMakeValue, rightTakeValue);
        require(rightTake <= leftMakeValue, "fillLeft: unable to fill");
        return FillResult(leftMakeValue, leftTakeValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@rarible/lib-asset/contracts/LibAsset.sol";

import "./LibMath.sol";
import "./LibOrderDataV3.sol";
import "./LibOrderDataV2.sol";
import "./LibOrderDataV1.sol";

library LibOrder {
    using SafeMathUpgradeable for uint;

    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,Asset makeAsset,address taker,Asset takeAsset,uint256 salt,uint256 start,uint256 end,bytes4 dataType,bytes data)Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    bytes4 constant DEFAULT_ORDER_TYPE = 0xffffffff;

    struct Order {
        address maker;
        LibAsset.Asset makeAsset;
        address taker;
        LibAsset.Asset takeAsset;
        uint salt;
        uint start;
        uint end;
        bytes4 dataType;
        bytes data;
    }

    function calculateRemaining(Order memory order, uint fill, bool isMakeFill) internal pure returns (uint makeValue, uint takeValue) {
        if (isMakeFill){
            makeValue = order.makeAsset.value.sub(fill);
            takeValue = LibMath.safeGetPartialAmountFloor(order.takeAsset.value, order.makeAsset.value, makeValue);
        } else {
            takeValue = order.takeAsset.value.sub(fill);
            makeValue = LibMath.safeGetPartialAmountFloor(order.makeAsset.value, order.takeAsset.value, takeValue); 
        } 
    }

    function hashKey(Order memory order) internal pure returns (bytes32) {
        if (order.dataType == LibOrderDataV1.V1 || order.dataType == DEFAULT_ORDER_TYPE) {
            return keccak256(abi.encode(
                order.maker,
                LibAsset.hash(order.makeAsset.assetType),
                LibAsset.hash(order.takeAsset.assetType),
                order.salt
            ));
        } else {
            //order.data is in hash for V2, V3 and all new order
            return keccak256(abi.encode(
                order.maker,
                LibAsset.hash(order.makeAsset.assetType),
                LibAsset.hash(order.takeAsset.assetType),
                order.salt,
                order.data
            ));
        }
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ORDER_TYPEHASH,
                order.maker,
                LibAsset.hash(order.makeAsset),
                order.taker,
                LibAsset.hash(order.takeAsset),
                order.salt,
                order.start,
                order.end,
                order.dataType,
                keccak256(order.data)
            ));
    }

    function validate(LibOrder.Order memory order) internal view {
        require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
        require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

library LibMath {
    using SafeMathUpgradeable for uint;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.mul(1000) >= numerator.mul(target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).add(denominator.sub(1)).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.sub(remainder) % denominator;
        isError = remainder.mul(1000) >= numerator.mul(target);
        return isError;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibOrderDataV3 {
    bytes4 constant public V3_SELL = bytes4(keccak256("V3_SELL"));
    bytes4 constant public V3_BUY = bytes4(keccak256("V3_BUY"));

    struct DataV3_SELL {
        uint payouts;
        uint originFeeFirst;
        uint originFeeSecond;
        uint maxFeesBasePoint;
        bytes32 marketplaceMarker;
    }

    struct DataV3_BUY {
        uint payouts;
        uint originFeeFirst;
        uint originFeeSecond;
        bytes32 marketplaceMarker;
    }

    function decodeOrderDataV3_SELL(bytes memory data) internal pure returns (DataV3_SELL memory orderData) {
        orderData = abi.decode(data, (DataV3_SELL));
    }

    function decodeOrderDataV3_BUY(bytes memory data) internal pure returns (DataV3_BUY memory orderData) {
        orderData = abi.decode(data, (DataV3_BUY));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibOrderDataV2 {
    bytes4 constant public V2 = bytes4(keccak256("V2"));

    struct DataV2 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        bool isMakeFill;
    }

    function decodeOrderDataV2(bytes memory data) internal pure returns (DataV2 memory orderData) {
        orderData = abi.decode(data, (DataV2));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibOrderDataV1 {
    bytes4 constant public V1 = bytes4(keccak256("V1"));

    struct DataV1 {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
    }

    function decodeOrderDataV1(bytes memory data) internal pure returns (DataV1 memory orderData) {
        orderData = abi.decode(data, (DataV1));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./LibOrder.sol";

library LibOrderData {

    struct GenericOrderData {
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        bool isMakeFill;
        uint maxFeesBasePoint;
    } 

    function parse(LibOrder.Order memory order) pure internal returns (GenericOrderData memory dataOrder) {
        if (order.dataType == LibOrderDataV1.V1) {
            LibOrderDataV1.DataV1 memory data = LibOrderDataV1.decodeOrderDataV1(order.data);
            dataOrder.payouts = data.payouts;
            dataOrder.originFees = data.originFees;
        } else if (order.dataType == LibOrderDataV2.V2) {
            LibOrderDataV2.DataV2 memory data = LibOrderDataV2.decodeOrderDataV2(order.data);
            dataOrder.payouts = data.payouts;
            dataOrder.originFees = data.originFees;
            dataOrder.isMakeFill = data.isMakeFill;
        } else if (order.dataType == LibOrderDataV3.V3_SELL) {
            LibOrderDataV3.DataV3_SELL memory data = LibOrderDataV3.decodeOrderDataV3_SELL(order.data);
            dataOrder.payouts = parsePayouts(data.payouts);
            dataOrder.originFees = parseOriginFeeData(data.originFeeFirst, data.originFeeSecond);
            dataOrder.isMakeFill = true;
            dataOrder.maxFeesBasePoint = data.maxFeesBasePoint;
        } else if (order.dataType == LibOrderDataV3.V3_BUY) {
            LibOrderDataV3.DataV3_BUY memory data = LibOrderDataV3.decodeOrderDataV3_BUY(order.data);
            dataOrder.payouts = parsePayouts(data.payouts);
            dataOrder.originFees = parseOriginFeeData(data.originFeeFirst, data.originFeeSecond);
            dataOrder.isMakeFill = false;
        } else if (order.dataType == 0xffffffff) {
        } else {
            revert("Unknown Order data type");
        }
        if (dataOrder.payouts.length == 0) {
            dataOrder.payouts = payoutSet(order.maker);
        }
    }

    function payoutSet(address orderAddress) pure internal returns (LibPart.Part[] memory) {
        LibPart.Part[] memory payout = new LibPart.Part[](1);
        payout[0].account = payable(orderAddress);
        payout[0].value = 10000;
        return payout;
    }

    function parseOriginFeeData(uint dataFirst, uint dataSecond) internal pure returns(LibPart.Part[] memory) {
        LibPart.Part[] memory originFee;

        if (dataFirst > 0 && dataSecond > 0){
            originFee = new LibPart.Part[](2);

            originFee[0] = uintToLibPart(dataFirst);
            originFee[1] = uintToLibPart(dataSecond);
        }

        if (dataFirst > 0 && dataSecond == 0) {
            originFee = new LibPart.Part[](1);

            originFee[0] = uintToLibPart(dataFirst);
        }

        if (dataFirst == 0 && dataSecond > 0) {
            originFee = new LibPart.Part[](1);

            originFee[0] = uintToLibPart(dataSecond);
        }

        return originFee;
    }

    function parsePayouts(uint data) internal pure returns(LibPart.Part[] memory) {
        LibPart.Part[] memory payouts;

        if (data > 0) {
            payouts = new LibPart.Part[](1);
            payouts[0] = uintToLibPart(data);
        }

        return payouts;
    }

    /**
        @notice converts uint to LibPart.Part
        @param data address and value encoded in uint (first 12 bytes )
        @return result LibPart.Part 
     */
    function uintToLibPart(uint data) internal pure returns(LibPart.Part memory result) {
        if (data > 0){
            result.account = payable(address(data));
            result.value = uint96(data >> 160);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@rarible/lib-asset/contracts/LibAsset.sol";

library LibDirectTransfer { //LibDirectTransfers
    /*All buy parameters need for create buyOrder and sellOrder*/
    struct Purchase {
        address sellOrderMaker; //
        uint256 sellOrderNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 sellOrderPaymentAmount;
        address paymentToken;
        uint256 sellOrderSalt;
        uint sellOrderStart;
        uint sellOrderEnd;
        bytes4 sellOrderDataType;
        bytes sellOrderData;
        bytes sellOrderSignature;

        uint256 buyOrderPaymentAmount;
        uint256 buyOrderNftAmount;
        bytes buyOrderData;
    }

    /*All accept bid parameters need for create buyOrder and sellOrder*/
    struct AcceptBid {
        address bidMaker; //
        uint256 bidNftAmount;
        bytes4 nftAssetClass;
        bytes nftData;
        uint256 bidPaymentAmount;
        address paymentToken;
        uint256 bidSalt;
        uint bidStart;
        uint bidEnd;
        bytes4 bidDataType;
        bytes bidData;
        bytes bidSignature;

        uint256 sellOrderPaymentAmount;
        uint256 sellOrderNftAmount;
        bytes sellOrderData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./libraries/LibOrder.sol";

import "@rarible/lib-signature/contracts/IERC1271.sol";
import "@rarible/lib-signature/contracts/LibSignature.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";

abstract contract OrderValidator is Initializable, ContextUpgradeable, EIP712Upgradeable {
    using LibSignature for bytes32;
    using AddressUpgradeable for address;
    
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function __OrderValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Exchange", "2");
    }

    function validate(LibOrder.Order memory order, bytes memory signature) internal view {
        if (order.salt == 0) {
            if (order.maker != address(0)) {
                require(_msgSender() == order.maker, "maker is not tx sender");
            }
        } else {
            if (_msgSender() != order.maker) {
                bytes32 hash = LibOrder.hash(order);
                address signer;
                if (signature.length == 65) {
                    signer = _hashTypedDataV4(hash).recover(signature);
                }
                if  (signer != order.maker) {
                    if (order.maker.isContract()) {
                        require(
                            IERC1271(order.maker).isValidSignature(_hashTypedDataV4(hash), signature) == MAGICVALUE,
                            "contract order signature verification error"
                        );
                    } else {
                        revert("order signature verification error");
                    }
                } else {
                    require (order.maker != address(0), "no maker");
                }
            }
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/exchange-interfaces/contracts/IAssetMatcher.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract AssetMatcher is Initializable, OwnableUpgradeable {

    bytes constant EMPTY = "";
    mapping(bytes4 => address) matchers;

    event MatcherChange(bytes4 indexed assetType, address matcher);

    function setAssetMatcher(bytes4 assetType, address matcher) external onlyOwner {
        matchers[assetType] = matcher;
        emit MatcherChange(assetType, matcher);
    }

    function matchAssets(LibAsset.AssetType memory leftAssetType, LibAsset.AssetType memory rightAssetType) internal view returns (LibAsset.AssetType memory) {
        LibAsset.AssetType memory result = matchAssetOneSide(leftAssetType, rightAssetType);
        if (result.assetClass == 0) {
            return matchAssetOneSide(rightAssetType, leftAssetType);
        } else {
            return result;
        }
    }

    function matchAssetOneSide(LibAsset.AssetType memory leftAssetType, LibAsset.AssetType memory rightAssetType) private view returns (LibAsset.AssetType memory) {
        bytes4 classLeft = leftAssetType.assetClass;
        bytes4 classRight = rightAssetType.assetClass;
        if (classLeft == LibAsset.ETH_ASSET_CLASS) {
            if (classRight == LibAsset.ETH_ASSET_CLASS) {
                return leftAssetType;
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        if (classLeft == LibAsset.ERC20_ASSET_CLASS) {
            if (classRight == LibAsset.ERC20_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        if (classLeft == LibAsset.ERC721_ASSET_CLASS) {
            if (classRight == LibAsset.ERC721_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        if (classLeft == LibAsset.ERC1155_ASSET_CLASS) {
            if (classRight == LibAsset.ERC1155_ASSET_CLASS) {
                return simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, EMPTY);
        }
        address matcher = matchers[classLeft];
        if (matcher != address(0)) {
            return IAssetMatcher(matcher).matchAssets(leftAssetType, rightAssetType);
        }
        if (classLeft == classRight) {
            return simpleMatch(leftAssetType, rightAssetType);
        }
        revert("not found IAssetMatcher");
    }

    function simpleMatch(LibAsset.AssetType memory leftAssetType, LibAsset.AssetType memory rightAssetType) private view returns (LibAsset.AssetType memory) {
        bytes32 leftHash = keccak256(leftAssetType.data);
        bytes32 rightHash = keccak256(rightAssetType.data);
        if (leftHash == rightHash) {
            return leftAssetType;
        }
        return LibAsset.AssetType(0, EMPTY);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@rarible/exchange-interfaces/contracts/IRoyaltiesProvider.sol";
import "@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "@rarible/royalties/contracts/LibRoyaltiesV1.sol";
import "@rarible/royalties/contracts/LibRoyalties2981.sol";
import "@rarible/royalties/contracts/RoyaltiesV1.sol";
import "@rarible/royalties/contracts/RoyaltiesV2.sol";
import "@rarible/royalties/contracts/IERC2981.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RoyaltiesRegistry is IRoyaltiesProvider, OwnableUpgradeable {
    /// @dev deprecated
    event RoyaltiesSetForToken(address indexed token, uint indexed tokenId, LibPart.Part[] royalties);
    /// @dev emitted when royalties set for token in 
    event RoyaltiesSetForContract(address indexed token, LibPart.Part[] royalties);

    /// @dev struct to store royalties in royaltiesByToken
    struct RoyaltiesSet {
        bool initialized;
        LibPart.Part[] royalties;
    }

    /// @dev deprecated
    mapping(bytes32 => RoyaltiesSet) public royaltiesByTokenAndTokenId;
    /// @dev stores royalties for token contract, set in setRoyaltiesByToken() method
    mapping(address => RoyaltiesSet) public royaltiesByToken;
    /// @dev stores external provider and royalties type for token contract
    mapping(address => uint) public royaltiesProviders;

    /// @dev total amount or supported royalties types
    // 0 - royalties type is unset
    // 1 - royaltiesByToken, 2 - v2, 3 - v1,
    // 4 - external provider, 5 - EIP-2981
    // 6 - unsupported/nonexistent royalties type
    uint constant royaltiesTypesAmount = 6;

    function __RoyaltiesRegistry_init() external initializer {
        __Ownable_init_unchained();
    }

    /// @dev sets external provider for token contract, and royalties type = 4
    function setProviderByToken(address token, address provider) external {
        checkOwner(token);
        setRoyaltiesType(token, 4, provider);
    }

    /// @dev returns provider address for token contract from royaltiesProviders mapping
    function getProvider(address token) public view returns(address) {
        return address(royaltiesProviders[token]);
    }

    /// @dev returns royalties type for token contract
    function getRoyaltiesType(address token) external view returns(uint) {
        return _getRoyaltiesType(royaltiesProviders[token]);
    }

    /// @dev returns royalties type from uint
    function _getRoyaltiesType(uint data) internal pure returns(uint) {
        for (uint i = 1; i <= royaltiesTypesAmount; i++) {
            if (data / 2**(256-i) == 1) {
                return i;
            }
        }
        return 0;
    }

    /// @dev sets royalties type for token contract
    function setRoyaltiesType(address token, uint royaltiesType, address royaltiesProvider) internal {
        require(royaltiesType > 0 && royaltiesType <= royaltiesTypesAmount, "wrong royaltiesType");
        royaltiesProviders[token] = uint(royaltiesProvider) + 2**(256 - royaltiesType);
    }

    /// @dev clears and sets new royalties type for token contract
    function forceSetRoyaltiesType(address token, uint royaltiesType) external {
        checkOwner(token);
        setRoyaltiesType(token, royaltiesType, getProvider(token));
    }

    /// @dev clears royalties type for token contract
    function clearRoyaltiesType(address token) external {
        checkOwner(token);
        royaltiesProviders[token] = uint(getProvider(token));
    }

    /// @dev sets royalties for token contract in royaltiesByToken mapping and royalties type = 1
    function setRoyaltiesByToken(address token, LibPart.Part[] memory royalties) external {
        checkOwner(token);
        //clearing royaltiesProviders value for the token
        delete royaltiesProviders[token];
        // setting royaltiesType = 1 for the token
        setRoyaltiesType(token, 1, address(0));
        uint sumRoyalties = 0;
        delete royaltiesByToken[token];
        for (uint i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0), "RoyaltiesByToken recipient should be present");
            require(royalties[i].value != 0, "Royalty value for RoyaltiesByToken should be > 0");
            royaltiesByToken[token].royalties.push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties < 10000, "Set by token royalties sum more, than 100%");
        royaltiesByToken[token].initialized = true;
        emit RoyaltiesSetForContract(token, royalties);
    }

    /// @dev checks if msg.sender is owner of this contract or owner of the token contract
    function checkOwner(address token) internal view {
        if ((owner() != _msgSender()) && (OwnableUpgradeable(token).owner() != _msgSender())) {
            revert("Token owner not detected");
        }
    }

    /// @dev calculates royalties type for token contract
    function calculateRoyaltiesType(address token, address royaltiesProvider ) internal view returns(uint) {   
        try IERC165Upgradeable(token).supportsInterface(LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) returns(bool result) {
            if (result) {
                return 2;
            }
        } catch { }

        try IERC165Upgradeable(token).supportsInterface(LibRoyaltiesV1._INTERFACE_ID_FEES) returns(bool result) {
            if (result) {
                return 3;
            }
        } catch { }
        
        try IERC165Upgradeable(token).supportsInterface(LibRoyalties2981._INTERFACE_ID_ROYALTIES) returns(bool result) {
            if (result) {
                return 5;
            }
        } catch { }
        
        if (royaltiesProvider != address(0)) {
            return 4;
        }

        if (royaltiesByToken[token].initialized) {
            return 1;
        }

        return 6;
    }

    /// @dev returns royalties for token contract and token id
    function getRoyalties(address token, uint tokenId) override external returns (LibPart.Part[] memory) {
        uint royaltiesProviderData = royaltiesProviders[token];

        address royaltiesProvider = address(royaltiesProviderData);
        uint royaltiesType = _getRoyaltiesType(royaltiesProviderData);

        // case when royaltiesType is not set
        if (royaltiesType == 0) {
            // calculating royalties type for token
            royaltiesType = calculateRoyaltiesType(token, royaltiesProvider);
            
            //saving royalties type
            setRoyaltiesType(token, royaltiesType, royaltiesProvider);
        }

        //case royaltiesType = 1, royalties are set in royaltiesByToken
        if (royaltiesType == 1) {
            return royaltiesByToken[token].royalties;
        }

        //case royaltiesType = 2, royalties rarible v2
        if (royaltiesType == 2) {
            return getRoyaltiesRaribleV2(token,tokenId);
        }

        //case royaltiesType = 3, royalties rarible v1
        if (royaltiesType == 3) {
            return getRoyaltiesRaribleV1(token, tokenId);
        }

        //case royaltiesType = 4, royalties from external provider
        if (royaltiesType == 4) {
            return providerExtractor(token, tokenId, royaltiesProvider);
        }

        //case royaltiesType = 5, royalties EIP-2981
        if (royaltiesType == 5) {
            return getRoyaltiesEIP2981(token, tokenId);
        }

        // case royaltiesType = 6, unknown/empty royalties
        if (royaltiesType == 6) {
            return new LibPart.Part[](0);
        } 

        revert("something wrong in getRoyalties");
    }

    /// @dev tries to get royalties rarible-v2 for token and tokenId
    function getRoyaltiesRaribleV2(address token, uint tokenId) internal view returns (LibPart.Part[] memory) {
        try RoyaltiesV2(token).getRaribleV2Royalties(tokenId) returns (LibPart.Part[] memory result) {
            return result;
        } catch {
            return new LibPart.Part[](0);
        }
    }

    /// @dev tries to get royalties rarible-v1 for token and tokenId
    function getRoyaltiesRaribleV1(address token, uint tokenId) internal view returns (LibPart.Part[] memory) {
        RoyaltiesV1 v1 = RoyaltiesV1(token);
        address payable[] memory recipients;
        try v1.getFeeRecipients(tokenId) returns (address payable[] memory resultRecipients) {
            recipients = resultRecipients;
        } catch {
            return new LibPart.Part[](0);
        }
        uint[] memory values;
        try v1.getFeeBps(tokenId) returns (uint[] memory resultValues) {
            values = resultValues;
        } catch {
            return new LibPart.Part[](0);
        }
        if (values.length != recipients.length) {
            return new LibPart.Part[](0);
        }
        LibPart.Part[] memory result = new LibPart.Part[](values.length);
        for (uint256 i = 0; i < values.length; i++) {
            result[i].value = uint96(values[i]);
            result[i].account = recipients[i];
        }
        return result;
    }

    /// @dev tries to get royalties EIP-2981 for token and tokenId
    function getRoyaltiesEIP2981(address token, uint tokenId) internal view returns (LibPart.Part[] memory) {
        try IERC2981(token).royaltyInfo(tokenId, LibRoyalties2981._WEIGHT_VALUE) returns (address receiver, uint256 royaltyAmount) {
            return LibRoyalties2981.calculateRoyalties(receiver, royaltyAmount);
        } catch {
            return new LibPart.Part[](0);
        }
    }

    /// @dev tries to get royalties for token and tokenId from external provider set in royaltiesProviders
    function providerExtractor(address token, uint tokenId, address providerAddress) internal returns (LibPart.Part[] memory) {
        try IRoyaltiesProvider(providerAddress).getRoyalties(token, tokenId) returns (LibPart.Part[] memory result) {
            return result;
        } catch {
            return new LibPart.Part[](0);
        }
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "@rarible/role-operator/contracts/OperatorRole.sol";
import "@rarible/exchange-interfaces/contracts/INftTransferProxy.sol";

contract TransferProxy is INftTransferProxy, Initializable, OperatorRole {

    function __TransferProxy_init() external initializer {
        __Ownable_init();
    }

    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) override external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(IERC1155Upgradeable token, address from, address to, uint256 id, uint256 value, bytes calldata data) override external onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "@rarible/role-operator/contracts/OperatorRole.sol";
import "@rarible/exchange-interfaces/contracts/IERC20TransferProxy.sol";

contract ERC20TransferProxy is IERC20TransferProxy, Initializable, OperatorRole {

    function __ERC20TransferProxy_init() external initializer {
        __Ownable_init();
    }

    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) override external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-asset/contracts/LibAsset.sol";

interface IAssetMatcher {
    function matchAssets(
        LibAsset.AssetType memory leftAssetType,
        LibAsset.AssetType memory rightAssetType
    ) external view returns (LibAsset.AssetType memory);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@rarible/lazy-mint/contracts/erc-721/LibERC721LazyMint.sol";
import "@rarible/lazy-mint/contracts/erc-1155/LibERC1155LazyMint.sol";

import "@rarible/exchange-interfaces/contracts/IRoyaltiesProvider.sol";

import "@rarible/lib-bp/contracts/BpLibrary.sol";

import "./interfaces/ITransferManager.sol";

abstract contract RaribleTransferManager is OwnableUpgradeable, ITransferManager {
    using BpLibrary for uint;
    using SafeMathUpgradeable for uint;

    uint public protocolFee;
    IRoyaltiesProvider public royaltiesRegistry;

    address public defaultFeeReceiver;
    mapping(address => address) public feeReceivers;

    /// @dev event that's emitted when protocolFee changes
    event ProtocolFeeChanged(uint oldValue, uint newValue);

    function __RaribleTransferManager_init_unchained(
        uint newProtocolFee,
        address newDefaultFeeReceiver,
        IRoyaltiesProvider newRoyaltiesProvider
    ) internal initializer {
        protocolFee = newProtocolFee;
        defaultFeeReceiver = newDefaultFeeReceiver;
        royaltiesRegistry = newRoyaltiesProvider;
    }

    function setRoyaltiesRegistry(IRoyaltiesProvider newRoyaltiesRegistry) external onlyOwner {
        royaltiesRegistry = newRoyaltiesRegistry;
    }

    function setProtocolFee(uint64 _protocolFee) external onlyOwner {
        emit ProtocolFeeChanged(protocolFee, _protocolFee);
        protocolFee = _protocolFee;
    }

    function setDefaultFeeReceiver(address payable newDefaultFeeReceiver) external onlyOwner {
        defaultFeeReceiver = newDefaultFeeReceiver;
    }

    function setFeeReceiver(address token, address wallet) external onlyOwner {
        feeReceivers[token] = wallet;
    }

    function getFeeReceiver(address token) internal view returns (address) {
        address wallet = feeReceivers[token];
        if (wallet != address(0)) {
            return wallet;
        }
        return defaultFeeReceiver;
    }

    /**
        @notice executes transfers for 2 matched orders
        @param left DealSide from the left order (see LibDeal.sol)
        @param right DealSide from the right order (see LibDeal.sol)
        @param dealData DealData of the match (see LibDeal.sol)
        @return totalLeftValue - total amount for the left order
        @return totalRightValue - total amout for the right order
    */
    function doTransfers(
        LibDeal.DealSide memory left,
        LibDeal.DealSide memory right,
        LibDeal.DealData memory dealData
    ) override internal returns (uint totalLeftValue, uint totalRightValue) {
        totalLeftValue = left.asset.value;
        totalRightValue = right.asset.value;

        if (dealData.feeSide == LibFeeSide.FeeSide.LEFT) {
            totalLeftValue = doTransfersWithFees(left, right, dealData.protocolFee, dealData.maxFeesBasePoint);
            transferPayouts(right.asset.assetType, right.asset.value, right.from, left.payouts, right.proxy);
        } else if (dealData.feeSide == LibFeeSide.FeeSide.RIGHT) {
            totalRightValue = doTransfersWithFees(right, left, dealData.protocolFee, dealData.maxFeesBasePoint);
            transferPayouts(left.asset.assetType, left.asset.value, left.from, right.payouts, left.proxy);
        } else {
            transferPayouts(left.asset.assetType, left.asset.value, left.from, right.payouts, left.proxy);
            transferPayouts(right.asset.assetType, right.asset.value, right.from, left.payouts, right.proxy);
        }
    }

    /**
        @notice executes the fee-side transfers (payment + fees)
        @param paymentSide DealSide of the fee-side order
        @param nftSide  DealSide of the nft-side order
        @param _protocolFee protocol fee for the match (always 0 for V2 and earlier orders)
        @param maxFeesBasePoint max fee for the sell-order (used and is > 0 for V3 orders only)
        @return totalAmount of fee-side asset
    */
    function doTransfersWithFees(
        LibDeal.DealSide memory paymentSide,
        LibDeal.DealSide memory nftSide,
        uint _protocolFee,
        uint maxFeesBasePoint
    ) internal returns (uint totalAmount) {
        totalAmount = calculateTotalAmount(paymentSide.asset.value, _protocolFee, paymentSide.originFees, maxFeesBasePoint);
        uint rest = transferProtocolFee(totalAmount, paymentSide.asset.value, paymentSide.from, _protocolFee, paymentSide.asset.assetType, paymentSide.proxy);

        rest = transferRoyalties(paymentSide.asset.assetType, nftSide.asset.assetType, nftSide.payouts, rest, paymentSide.asset.value, paymentSide.from, paymentSide.proxy);
        if (
            paymentSide.originFees.length  == 1 &&
            nftSide.originFees.length  == 1 &&
            nftSide.originFees[0].account == paymentSide.originFees[0].account
        ) { 
            LibPart.Part[] memory origin = new  LibPart.Part[](1);
            origin[0].account = nftSide.originFees[0].account;
            origin[0].value = nftSide.originFees[0].value + paymentSide.originFees[0].value;
            (rest,) = transferFees(paymentSide.asset.assetType, rest, paymentSide.asset.value, origin, paymentSide.from, paymentSide.proxy);
        } else {
            (rest,) = transferFees(paymentSide.asset.assetType, rest, paymentSide.asset.value, paymentSide.originFees, paymentSide.from, paymentSide.proxy);
            (rest,) = transferFees(paymentSide.asset.assetType, rest, paymentSide.asset.value, nftSide.originFees, paymentSide.from, paymentSide.proxy);
        }
        transferPayouts(paymentSide.asset.assetType, rest, paymentSide.from, nftSide.payouts, paymentSide.proxy);
    }

    function transferProtocolFee(
        uint totalAmount,
        uint amount,
        address from,
        uint _protocolFee,
        LibAsset.AssetType memory matchCalculate,
        address proxy
    ) internal returns (uint) {
        (uint rest, uint fee) = subFeeInBp(totalAmount, amount, _protocolFee);
        if (fee > 0) {
            address tokenAddress = address(0);
            if (matchCalculate.assetClass == LibAsset.ERC20_ASSET_CLASS) {
                tokenAddress = abi.decode(matchCalculate.data, (address));
            } else if (matchCalculate.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
                uint tokenId;
                (tokenAddress, tokenId) = abi.decode(matchCalculate.data, (address, uint));
            }
            transfer(LibAsset.Asset(matchCalculate, fee), from, getFeeReceiver(tokenAddress), proxy);
        }
        return rest;
    }

    /**
        @notice Transfer royalties. If there is only one royalties receiver and one address in payouts and they match,
           nothing is transferred in this function
        @param paymentAssetType Asset Type which represents payment
        @param nftAssetType Asset Type which represents NFT to pay royalties for
        @param payouts Payouts to be made
        @param rest How much of the amount left after previous transfers
        @param from owner of the Asset to transfer
        @param proxy Transfer proxy to use
        @return How much left after transferring royalties
    */
    function transferRoyalties(
        LibAsset.AssetType memory paymentAssetType,
        LibAsset.AssetType memory nftAssetType,
        LibPart.Part[] memory payouts,
        uint rest,
        uint amount,
        address from,
        address proxy
    ) internal returns (uint) {
        LibPart.Part[] memory royalties = getRoyaltiesByAssetType(nftAssetType);
        if (
            royalties.length == 1 &&
            payouts.length == 1 &&
            royalties[0].account == payouts[0].account
        ) {
            require(royalties[0].value <= 5000, "Royalties are too high (>50%)");
            return rest;
        }
        (uint result, uint totalRoyalties) = transferFees(paymentAssetType, rest, amount, royalties, from, proxy);
        require(totalRoyalties <= 5000, "Royalties are too high (>50%)");
        return result;
    }

    /**
        @notice calculates royalties by asset type. If it's a lazy NFT, then royalties are extracted from asset. otherwise using royaltiesRegistry
        @param nftAssetType NFT Asset Type to calculate royalties for
        @return calculated royalties (Array of LibPart.Part)
    */
    function getRoyaltiesByAssetType(LibAsset.AssetType memory nftAssetType) internal returns (LibPart.Part[] memory) {
        if (nftAssetType.assetClass == LibAsset.ERC1155_ASSET_CLASS || nftAssetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(nftAssetType.data, (address, uint));
            return royaltiesRegistry.getRoyalties(token, tokenId);
        } else if (nftAssetType.assetClass == LibERC1155LazyMint.ERC1155_LAZY_ASSET_CLASS) {
            (, LibERC1155LazyMint.Mint1155Data memory data) = abi.decode(nftAssetType.data, (address, LibERC1155LazyMint.Mint1155Data));
            return data.royalties;
        } else if (nftAssetType.assetClass == LibERC721LazyMint.ERC721_LAZY_ASSET_CLASS) {
            (, LibERC721LazyMint.Mint721Data memory data) = abi.decode(nftAssetType.data, (address, LibERC721LazyMint.Mint721Data));
            return data.royalties;
        }
        LibPart.Part[] memory empty;
        return empty;
    }

    /**
        @notice Transfer fees
        @param assetType Asset Type to transfer
        @param rest How much of the amount left after previous transfers
        @param amount Total amount of the Asset. Used as a base to calculate part from (100%)
        @param fees Array of LibPart.Part which represents fees to pay
        @param from owner of the Asset to transfer
        @param proxy Transfer proxy to use
        @return newRest how much left after transferring fees
        @return totalFees total number of fees in bp
    */
    function transferFees(
        LibAsset.AssetType memory assetType,
        uint rest,
        uint amount,
        LibPart.Part[] memory fees,
        address from,
        address proxy
    ) internal returns (uint newRest, uint totalFees) {
        totalFees = 0;
        newRest = rest;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFees = totalFees.add(fees[i].value);
            uint feeValue;
            (newRest, feeValue) = subFeeInBp(newRest, amount, fees[i].value);
            if (feeValue > 0) {
                transfer(LibAsset.Asset(assetType, feeValue), from, fees[i].account, proxy);
            }
        }
    }

    /**
        @notice transfers main part of the asset (payout)
        @param assetType Asset Type to transfer
        @param amount Amount of the asset to transfer
        @param from Current owner of the asset
        @param payouts List of payouts - receivers of the Asset
        @param proxy Transfer Proxy to use
    */
    function transferPayouts(
        LibAsset.AssetType memory assetType,
        uint amount,
        address from,
        LibPart.Part[] memory payouts,
        address proxy
    ) internal {
        require(payouts.length > 0, "transferPayouts: nothing to transfer");
        uint sumBps = 0;
        uint rest = amount;
        for (uint256 i = 0; i < payouts.length - 1; i++) {
            uint currentAmount = amount.bp(payouts[i].value);
            sumBps = sumBps.add(payouts[i].value);
            if (currentAmount > 0) {
                rest = rest.sub(currentAmount);
                transfer(LibAsset.Asset(assetType, currentAmount), from, payouts[i].account, proxy);
            }
        }
        LibPart.Part memory lastPayout = payouts[payouts.length - 1];
        sumBps = sumBps.add(lastPayout.value);
        require(sumBps == 10000, "Sum payouts Bps not equal 100%");
        if (rest > 0) {
            transfer(LibAsset.Asset(assetType, rest), from, lastPayout.account, proxy);
        }
    }
    
    /**
        @notice calculates total amount of fee-side asset that is going to be used in match
        @param amount fee-side order value
        @param feeOnTopBp protocolFee (it adds on top of the amount for the orders of )
        @param orderOriginFees fee-side order's origin fee (it adds on top of the amount)
        @param maxFeesBasePoint max fee for the sell-order (used and is > 0 for V3 orders only)
        @return total amount of fee-side asset
    */
    function calculateTotalAmount(
        uint amount,
        uint feeOnTopBp,
        LibPart.Part[] memory orderOriginFees,
        uint maxFeesBasePoint
    ) internal pure returns (uint) {
        if (maxFeesBasePoint > 0) {
            return amount;
        }
        uint total = amount.add(amount.bp(feeOnTopBp));
        for (uint256 i = 0; i < orderOriginFees.length; i++) {
            total = total.add(amount.bp(orderOriginFees[i].value));
        }
        return total;
    }

    function subFeeInBp(uint value, uint total, uint feeInBp) internal pure returns (uint newValue, uint realFee) {
        return subFee(value, total.bp(feeInBp));
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value.sub(fee);
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/exchange-interfaces/contracts/ITransferProxy.sol";
import "@rarible/exchange-interfaces/contracts/INftTransferProxy.sol";
import "@rarible/exchange-interfaces/contracts/IERC20TransferProxy.sol";
import "./interfaces/ITransferExecutor.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./lib/LibTransfer.sol";

abstract contract TransferExecutor is Initializable, OwnableUpgradeable, ITransferExecutor {
    using LibTransfer for address;

    mapping (bytes4 => address) proxies;

    event ProxyChange(bytes4 indexed assetType, address proxy);

    function __TransferExecutor_init_unchained(address transferProxy, address erc20TransferProxy) internal { 
        proxies[LibAsset.ERC20_ASSET_CLASS] = address(erc20TransferProxy);
        proxies[LibAsset.ERC721_ASSET_CLASS] = address(transferProxy);
        proxies[LibAsset.ERC1155_ASSET_CLASS] = address(transferProxy);
    }

    function setTransferProxy(bytes4 assetType, address proxy) external onlyOwner {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        address proxy
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            //not using transfer proxy when transfering from this contract
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            require(asset.value == 1, "erc721 value error");
            if (from == address(this)){
                IERC721Upgradeable(token).safeTransferFrom(address(this), to, tokenId);
            } else {
                INftTransferProxy(proxy).erc721safeTransferFrom(IERC721Upgradeable(token), from, to, tokenId);
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            //not using transfer proxy when transfering from this contract
            (address token) = abi.decode(asset.assetType.data, (address));
            if (from == address(this)){
                IERC20Upgradeable(token).transfer(to, asset.value);
            } else {
                IERC20TransferProxy(proxy).erc20safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            //not using transfer proxy when transfering from this contract
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            if (from == address(this)){
                IERC1155Upgradeable(token).safeTransferFrom(address(this), to, tokenId, asset.value, "");
            } else {
                INftTransferProxy(proxy).erc1155safeTransferFrom(IERC1155Upgradeable(token), from, to, tokenId, asset.value, "");  
            }
        } else if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            if (to != address(this)) {
                to.transferEth(asset.value);
            }
        } else {
            ITransferProxy(proxy).transfer(asset, from, to);
        }
    }
    
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../lib/LibDeal.sol";
import "./ITransferExecutor.sol";

abstract contract ITransferManager is ITransferExecutor {

    function doTransfers(
        LibDeal.DealSide memory left,
        LibDeal.DealSide memory right,
        LibDeal.DealData memory dealData
    ) internal virtual returns (uint totalMakeValue, uint totalTakeValue);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";
import "@rarible/lib-asset/contracts/LibAsset.sol";
import "./LibFeeSide.sol";

library LibDeal {
    struct DealSide {
        LibAsset.Asset asset;
        LibPart.Part[] payouts;
        LibPart.Part[] originFees;
        address proxy;
        address from;
    }

    struct DealData {
        uint protocolFee;
        uint maxFeesBasePoint;
        LibFeeSide.FeeSide feeSide;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IERC1271 {

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _hash Hash of the data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) virtual external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library LibSignature {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(
                v - 4 == 27 || v - 4 == 28,
                "ECDSA: invalid signature 'v' value"
            );
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 constant public CRYPTO_PUNKS = bytes4(keccak256("CRYPTO_PUNKS"));

    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                assetType.assetClass,
                keccak256(assetType.data)
            ));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPEHASH,
                hash(asset.assetType),
                asset.value
            ));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";

interface IRoyaltiesProvider {
    function getRoyalties(address token, uint tokenId) external returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibRoyaltiesV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 constant _INTERFACE_ID_FEES = 0xb7799584;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibRoyalties2981 {
    /*
     * https://eips.ethereum.org/EIPS/eip-2981: bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0x2a55205a;
    uint96 constant _WEIGHT_VALUE = 1000000;

    /*Method for converting amount to percent and forming LibPart*/
    function calculateRoyalties(address to, uint256 amount) internal view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory result;
        if (amount == 0) {
            return result;
        }
        uint256 percent = amount * 10000 / _WEIGHT_VALUE;
        require(percent < 10000, "Royalties 2981 exceeds 100%");
        result = new LibPart.Part[](1);
        result[0].account = payable(to);
        result[0].value = uint96(percent);
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

interface RoyaltiesV1 {
    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
    function getFeeBps(uint256 id) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "@rarible/lib-part/contracts/LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
import "@rarible/lib-part/contracts/LibPart.sol";
///
/// @dev Interface for the NFT Royalty Standard
///
//interface IERC2981 is IERC165 {
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OperatorRole is OwnableUpgradeable {
    mapping (address => bool) operators;

    function __OperatorRole_init() external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperatorRole: caller is not the operator");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20TransferProxy {
    function erc20safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface INftTransferProxy {
    function erc721safeTransferFrom(IERC721Upgradeable token, address from, address to, uint256 tokenId) external;

    function erc1155safeTransferFrom(IERC1155Upgradeable token, address from, address to, uint256 id, uint256 value, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibERC721LazyMint {
    bytes4 constant public ERC721_LAZY_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

    struct Mint721Data {
        uint tokenId;
        string tokenURI;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint721(uint256 tokenId,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)");

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                keccak256(bytes(data.tokenURI)),
                keccak256(abi.encodePacked(creatorsBytes)),
                keccak256(abi.encodePacked(royaltiesBytes))
            ));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@rarible/lib-part/contracts/LibPart.sol";

library LibERC1155LazyMint {
    bytes4 constant public ERC1155_LAZY_ASSET_CLASS = bytes4(keccak256("ERC1155_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

    struct Mint1155Data {
        uint tokenId;
        string tokenURI;
        uint supply;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)");

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);
        for (uint i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);
        for (uint i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                data.supply,
                keccak256(bytes(data.tokenURI)),
                keccak256(abi.encodePacked(creatorsBytes)),
                keccak256(abi.encodePacked(royaltiesBytes))
            ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;
pragma abicoder v2;

import "@rarible/lib-asset/contracts/LibAsset.sol";

interface ITransferProxy {
    function transfer(LibAsset.Asset calldata asset, address from, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "@rarible/lib-asset/contracts/LibAsset.sol";

abstract contract ITransferExecutor {
    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        address proxy
    ) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@rarible/lib-asset/contracts/LibAsset.sol";

library LibFeeSide {

    enum FeeSide {NONE, LEFT, RIGHT}

    function getFeeSide(bytes4 leftClass, bytes4 rightClass) internal pure returns (FeeSide) {
        if (leftClass == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibAsset.ETH_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        if (leftClass == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibAsset.ERC20_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        if (leftClass == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.LEFT;
        }
        if (rightClass == LibAsset.ERC1155_ASSET_CLASS) {
            return FeeSide.RIGHT;
        }
        return FeeSide.NONE;
    }
}