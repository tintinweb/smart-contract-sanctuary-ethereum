// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

// prettier-ignore
enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
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

// prettier-ignore
enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {
    OrderType,
    BasicOrderType,
    ItemType,
    Side
} from "./ConsiderationEnums.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
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

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
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

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
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

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
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
    // Total length, excluding dynamic array data: 0x264 (580)
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

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be included in a staticcall to
 *      `isValidOrderIncludingExtraData` on the zone for the order if the order
 *      type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBuyActions {
    function buy(
        address nftContract,
        uint256 tokenID,
        uint256 value,
        address to,
        bytes calldata callData
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions that the ship can take
interface IBuyEvents {
    event NFTBought(
        uint256 timestamp,
        uint256 price,
        address nftContract,
        uint256 nftTokenID
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions for revenue claims
interface IClaimActions {
    /// @notice Get the amount claimable at an event
    /// @param account The address to get claim amount
    /// @param claimID The claim event ID to claim revenue
    /// @return The amount claimed
    function getClaimAmount(
        address account,
        uint256 claimID
    ) external view returns (uint256);

    /// @notice Check if an address has claims at an event
    /// @param account The address to check
    /// @param claimID The claim event ID to check for claim revenue
    /// @return True of address has claim
    function hasClaim(
        address account,
        uint256 claimID
    ) external view returns (bool);

    /// @notice Claim revenue at for a particular event
    /// @param claimID The claim event ID to claim revenue
    /// @return The amount claimed
    function claim(uint256 claimID) external payable returns (uint256);

    // Make this receive eth
    receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions that the ship can take
interface IClaimEvents {
    // When a user claims their share
    event Claimed(address account, uint256 amount, uint256 claimID);

    // Wben a new claim is available
    event Claimable(uint256 amount, uint256 claimID);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions open during the Crowdfund phase
interface ICrowdfundActions {
    /// @notice Contribute ETH for ship tokens
    /// @return minted The amount of ship tokens minted
    function contribute() external payable returns (uint256 minted);

    /// @notice Check if raise met
    /// @return True if raise was met
    function hasRaiseMet() external view returns (bool);

    /// @notice Check users can still contribute
    /// @return True if closed
    function isRaiseOpen() external view returns (bool);

    /// @notice End the ship raise
    function endRaise() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Events for crowdfund phase
interface ICrowdfundEvents {
    /// @notice When the minimum raise is met
    event RaiseMet();

    /// @notice When the captain or authorized 3rd party (eg: SZNS DAO) closes the ship before the pool duration
    event ForceEndRaise();

    /// @notice When the minimum raise is met
    /// @param contributor Address that contributed
    /// @param amount Amount contributed
    event Contributed(address indexed contributor, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IListActions {
    function list(
        address nftContract,
        uint256 tokenID,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Order} from "seaport/lib/ConsiderationStructs.sol";

// Actions that the ship can take
interface IListEvents {
    event NFTListed(
        uint256 timestamp,
        address nftContract,
        uint256 tokenID,
        uint256 price
    );
    event ListingCanceled(
        uint256 timestamp,
        address nftContract,
        uint256 tokenID
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct SetupReturnVars {
    address safeAddress;
    address captainGuardAddress;
    address shipModifierAddress;
    address buyModuleAddress;
    address listModuleAddress;
}

interface IDeployerActions {
    function createAndSetup(
        string memory name,
        string memory symbol,
        uint256 endDuration,
        uint256 minRaise,
        address captain,
        address[] memory nfts
    ) external returns (SetupReturnVars memory rv);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {SetupReturnVars} from "szns/interfaces/zodiac/deployer/IDeployerActions.sol";

interface IDeployerEvents {
    /// @notice When the the ship is created
    event NewShipCreated(
        uint256 timestamp,
        address captain,
        address[] targetedNFTs,
        uint256 minRaise,
        string name,
        string symbol,
        uint256 endDuration,
        SetupReturnVars addresses
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions open during the Crowdfund phase
interface ICaptainGuard {
    // When msg.sender is not a captain
    error NotCaptain();

    /// @notice Assign a new captain
    /// @param captain The new address to assign as captain
    function updateCaptain(address captain) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Actions open during the Crowdfund phase
interface ICaptainGuardEvents {
    // When new captain assigned
    event CaptainAssigned(
        address initiator,
        address indexed avatar,
        address indexed captain
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "szns/interfaces/buy/IBuyEvents.sol";
import "szns/interfaces/buy/IBuyActions.sol";

contract MockBuyModule is IBuyEvents, IBuyActions {
    function buy(
        address nftContract,
        uint256 tokenID,
        uint256 value,
        address to,
        bytes calldata callData
    ) external {
        emit NFTBought(block.timestamp, value, nftContract, tokenID);
    }
}

pragma solidity ^0.8.13;
import "szns/interfaces/zodiac/guards/ICaptainGuard.sol";
import "szns/interfaces/zodiac/guards/ICaptainGuardEvents.sol";

contract MockCaptainGuard is ICaptainGuard, ICaptainGuardEvents {
    function updateCaptain(address captain) external {
        emit CaptainAssigned(msg.sender, address(this), captain);
    }
}

pragma solidity ^0.8.13;
import "szns/interfaces/list/IListEvents.sol";
import "szns/interfaces/list/IListActions.sol";

contract MockListModule is IListEvents, IListActions {
    function list(
        address nftContract,
        uint256 tokenID,
        uint256 amount
    ) external {
        emit NFTListed(block.timestamp, nftContract, tokenID, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MockShip {
    string name = "THIS IS A TEST SAFE";
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "szns/interfaces/zodiac/deployer/IDeployerEvents.sol";
import "szns/interfaces/zodiac/deployer/IDeployerActions.sol";
import "szns/mock/MockShip.sol";
import "szns/mock/MockBuyModule.sol";
import "szns/mock/MockListModule.sol";
import "szns/mock/MockShipModifier.sol";
import "szns/mock/MockCaptainGuard.sol";

contract MockShipDeployer is IDeployerEvents, IDeployerActions {
    address[] public ships;

    event ShipCanceled(address ship);

    function createAndSetup(
        string memory name,
        string memory symbol,
        uint256 endDuration,
        uint256 minRaise,
        address captain,
        address[] memory nfts
    ) external returns (SetupReturnVars memory rv) {
        MockShip mockShip = new MockShip();
        MockBuyModule mockBuyModule = new MockBuyModule();
        MockListModule mockListModule = new MockListModule();
        MockShipModifier mockShipModifier = new MockShipModifier();
        MockCaptainGuard mockCaptainGuard = new MockCaptainGuard();
        ships.push(address(mockShip));
        rv.safeAddress = address(mockShip);
        rv.captainGuardAddress = address(mockCaptainGuard);
        rv.shipModifierAddress = address(mockShipModifier);
        rv.buyModuleAddress = address(mockBuyModule);
        rv.listModuleAddress = address(mockListModule);

        emit NewShipCreated(
            block.timestamp,
            captain,
            nfts,
            minRaise,
            "Test Ship",
            symbol,
            endDuration,
            rv
        );
    }
}

pragma solidity ^0.8.13;
import "szns/interfaces/claim/IClaimEvents.sol";
import "szns/interfaces/claim/IClaimActions.sol";
import "szns/interfaces/crowdfund/ICrowdfundEvents.sol";
import "szns/interfaces/crowdfund/ICrowdfundActions.sol";

contract MockShipModifier is
    IClaimEvents,
    IClaimActions,
    ICrowdfundEvents,
    ICrowdfundActions
{
    function getClaimAmount(address account, uint256 claimID)
        external
        view
        returns (uint256)
    {
        return 1000000000000000000; // return .1 as example
    }

    function hasClaim(address account, uint256 claimID)
        external
        view
        returns (bool)
    {
        return true;
    }

    function claim(uint256 claimID) external payable returns (uint256) {
        emit Claimed(msg.sender, 1000000000000000000, claimID);
        return 1000000000000000000;
    }

    // This is just for test purposes
    function makeClaimed(
        address account,
        uint256 amount,
        uint256 claimID
    ) external {
        emit Claimed(account, amount, claimID);
    }

    function makeClaimable(uint256 amount, uint256 claimID) external {
        emit Claimable(amount, claimID);
    }

    // send eth as value, returns 1000000000000000000000 (1000) for now
    function contribute() external payable returns (uint256 minted) {
        // assumes you always contribute 1 eth for now
        emit Contributed(msg.sender, 1000000000000000000);
        return 1000000000000000000000;
    }

    function hasRaiseMet() external view returns (bool) {
        return false;
    }

    function isRaiseOpen() external view returns (bool) {
        return true;
    }

    function endRaise() external {
        emit ForceEndRaise();
    }

    receive() external payable {}
}