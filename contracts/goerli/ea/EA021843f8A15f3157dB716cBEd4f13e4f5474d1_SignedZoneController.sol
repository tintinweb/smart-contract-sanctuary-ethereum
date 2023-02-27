// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ZoneParameters, Schema } from "../lib/ConsiderationStructs.sol";

interface ZoneInterface {
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external returns (bytes4 validOrderMagicValue);

    function getSeaportMetadata()
        external
        view
        returns (
            string memory name,
            Schema[] memory schemas // map to Seaport Improvement Proposal IDs
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// prettier-ignore
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
pragma solidity ^0.8.13;

import { OrderType, BasicOrderType, ItemType, Side } from "./ConsiderationEnums.sol";

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
 *      for supplying extra data; this data will be provided to the zone if the
 *      order type is restricted and the zone is not the caller, or will be
 *      provided to the offerer as context for contract order types.
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

/**
 * @dev Restricted orders are validated post-execution by calling validateOrder
 *      on the zone. This struct provides context about the order fulfillment
 *      and any supplied extraData, as well as all order hashes fulfilled in a
 *      call to a match or fulfillAvailable method.
 */
struct ZoneParameters {
    bytes32 orderHash;
    address fulfiller;
    address offerer;
    SpentItem[] offer;
    ReceivedItem[] consideration;
    bytes extraData;
    bytes32[] orderHashes;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
}

/**
 * @dev Zones and contract offerers can communicate which schemas they implement
 *      along with any associated metadata related to each schema.
 */
struct Schema {
    uint256 id;
    bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @notice SignedZoneControllerEventsAndErrors contains errors and events
 *         related to deploying and managing new signed zones.
 */
interface SignedZoneControllerEventsAndErrors {
    /**
     * @dev Emit an event whenever a new zone is created.
     *
     * @param zoneAddress The address of the zone.
     * @param zoneName    The name for the zone returned in
     *                    getSeaportMetadata().
     * @param apiEndpoint The API endpoint where orders for this zone can be
     *                    signed.
     * @param documentationURI The URI to the documentation describing the
     *                         behavior of the contract.
     *                    Request and response payloads are defined in SIP-7.
     * @param salt        The salt used to deploy the zone.
     */
    event ZoneCreated(
        address zoneAddress,
        string zoneName,
        string apiEndpoint,
        string documentationURI,
        bytes32 salt
    );

    /**
     * @dev Emit an event whenever zone ownership is transferred.
     *
     * @param zone          The zone for which ownership has been
     *                      transferred.
     * @param previousOwner The previous owner of the zone.
     * @param newOwner      The new owner of the zone.
     */
    event OwnershipTransferred(
        address indexed zone,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit an event whenever a zone owner registers a new potential
     *      owner for that zone.
     *
     * @param newPotentialOwner The new potential owner of the zone.
     */
    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    /**
     * @dev Emit an event when a signer has been updated.
     */
    event SignerUpdated(address signedZone, address signer, bool active);

    /**
     * @dev Revert with an error when attempting to update channels or transfer
     *      ownership of a zone when the caller is not the owner of the
     *      zone in question.
     */
    error CallerIsNotOwner(address zone);

    /**
     * @dev Revert with an error when the caller is not the owner or an active
     *      signer of the signed zone in question.
     */
    error CallerIsNotOwnerOrSigner(address zone);

    /**
     * @dev Revert with an error when attempting to claim ownership of a zone
     *      with a caller that is not the current potential owner for the
     *      zone in question.
     */
    error CallerIsNotNewPotentialOwner(address zone);

    /**
     * @dev Revert with an error when attempting to create a new signed zone
     *      using a salt where the first twenty bytes do not match the address
     *      of the caller or are not set to zero.
     */
    error InvalidCreator();

    /**
     * @dev Revert with an error when attempting to create a new zone when no
     *      initial owner address is supplied.
     */
    error InvalidInitialOwner();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(address zone, address newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet(address zone);
    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsZeroAddress(address zone);

    /**
     * @dev Revert with an error when attempting to interact with a zone that
     *      does not yet exist.
     */
    error NoZone();

    /**
     * @dev Revert with an error if trying to add a signer that is
     *      already active.
     */
    error SignerAlreadyAdded(address signer);

    /**
     * @dev Revert with an error if a new signer is the zero address.
     */
    error SignerCannotBeZeroAddress();

    /**
     * @dev Revert with an error if a removed signer is trying to be
     *      reauthorized.
     */
    error SignerCannotBeReauthorized(address signer);

    /**
     * @dev Revert with an error if trying to remove a signer that is
     *      not present.
     */
    error SignerNotPresent(address signer);

    /**
     * @dev Revert with an error when attempting to deploy a zone that is
     *      currently deployed.
     */
    error ZoneAlreadyExists(address zone);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title  SignedZoneControllerInterface
 * @author BCLeFevre
 * @notice SignedZoneControllerInterface enables the deploying of SignedZones.
 *         SignedZones are an implementation of SIP-7 that requires orders
 *         to be signed by an approved signer.
 *         https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 *
 */
interface SignedZoneControllerInterface {
    /**
     * @notice Deploy a SignedZone to a precomputed address.
     *
     * @param zoneName    The name for the zone returned in
     *                    getSeaportMetadata().
     * @param apiEndpoint The API endpoint where orders for this zone can be
     *                    signed.
     * @param documentationURI The URI to the documentation describing the
     *                         behavior of the contract.
     *                    Request and response payloads are defined in SIP-7.
     * @param salt        The salt to be used to derive the zone address
     * @param initialOwner The initial owner to set for the new zone.
     *
     * @return derivedAddress The derived address for the zone.
     */
    function createZone(
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        address initialOwner,
        bytes32 salt
    ) external returns (address derivedAddress);

    /**
     * @notice Returns the active signers for the zone.
     *
     * @param signedZone The signed zone to get the active signers for.
     *
     * @return signers The active signers.
     */
    function getActiveSigners(address signedZone)
        external
        view
        returns (address[] memory signers);

    /**
     * @notice Returns additional information about the zone.
     *
     * @param zone The zone to get the additional information for.
     *
     * @return domainSeparator  The domain separator used for signing.
     * @return zoneName         The name of the zone.
     * @return apiEndpoint      The API endpoint for the zone.
     * @return substandards     The substandards supported by the zone.
     * @return documentationURI The documentation URI for the zone.
     */
    function getAdditionalZoneInformation(address zone)
        external
        view
        returns (
            bytes32 domainSeparator,
            string memory zoneName,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        );

    /**
     * @notice Update the API endpoint returned by the supplied zone.
     *         Only the owner or an active signer can call this function.
     *
     * @param signedZone    The signed zone to update the API endpoint for.
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(
        address signedZone,
        string calldata newApiEndpoint
    ) external;

    /**
     * @notice Update the signer for a given signed zone.
     *
     * @param signedZone The signed zone to update the signer for.
     * @param signer     The signer to update.
     * @param active     If the signer should be active or not.
     */
    function updateSigner(
        address signedZone,
        address signer,
        bool active
    ) external;

    /**
     * @notice Initiate zone ownership transfer by assigning a new potential
     *         owner for the given zone. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the zone.
     *         Only the owner of the zone in question may call this function.
     *
     * @param zone The zone for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the zone.
     */
    function transferOwnership(address zone, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a zone.
     *         Only the owner of the zone in question may call this function.
     *
     * @param zone The zone for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address zone) external;

    /**
     * @notice Accept ownership of a supplied zone. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param zone The zone for which to accept ownership.
     */
    function acceptOwnership(address zone) external;

    /**
     * @notice Retrieve the current owner of a deployed zone.
     *
     * @param zone The zone for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied zone.
     */
    function ownerOf(address zone) external view returns (address owner);

    /**
     * @notice Retrieve the potential owner, if any, for a given zone. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the zone in question via `acceptOwnership`.
     *
     * @param zone The zone for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the zone.
     */
    function getPotentialOwner(address zone)
        external
        view
        returns (address potentialOwner);

    /**
     * @notice Derive the zone address associated with a salt.
     *
     * @param salt        The salt to be used to derive the zone address
     *
     * @return derivedAddress The derived address of the signed zone.
     */
    function getZone(bytes32 salt)
        external
        view
        returns (address derivedAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @notice SignedZoneEventsAndErrors contains errors and events
 *         related to zone interaction.
 */
interface SignedZoneEventsAndErrors {
    /**
     * @dev Emit an event when a new signer is added.
     */
    event SignerAdded(address signer);

    /**
     * @dev Emit an event when a signer is removed.
     */
    event SignerRemoved(address signer);

    /**
     * @dev Revert with an error if msg.sender is not the owner
     *      or an active signer.
     */
    error OnlyOwnerOrActiveSigner();

    /**
     * @dev Revert with an error when the signature has expired.
     */
    error SignatureExpired(uint256 expiration, bytes32 orderHash);

    /**
     * @dev Revert with an error when attempting to update the signers of a
     *      the zone from a caller that is not the zone's controller.
     */
    error InvalidController();

    /**
     * @dev Revert with an error if supplied order extraData is an invalid
     *      length.
     */
    error InvalidExtraDataLength(bytes32 orderHash);

    /**
     * @dev Revert with an error if the supplied order extraData does not
     *      support the zone's SIP6 version.
     */
    error InvalidSIP6Version(bytes32 orderHash);

    /**
     * @dev Revert with an error if the supplied order extraData does not
     *      support the zone's substandard requirements.
     */
    error InvalidSubstandardSupport(
        string reason,
        uint256 substandardVersion,
        bytes32 orderHash
    );

    /**
     * @dev Revert with an error if the supplied order extraData does not
     *      support the zone's substandard version.
     */
    error InvalidSubstandardVersion(bytes32 orderHash);

    /**
     * @dev Revert with an error if the fulfiller does not match.
     */
    error InvalidFulfiller(
        address expectedFulfiller,
        address actualFulfiller,
        bytes32 orderHash
    );

    /**
     * @dev Revert with an error if the consideration does not match.
     */
    error InvalidConsideration(
        uint256 expectedConsiderationHash,
        uint256 actualConsiderationHash,
        bytes32 orderHash
    );

    /**
     * @dev Revert with an error if the zone parameter encoding is invalid.
     */
    error InvalidZoneParameterEncoding();

    /**
     * @dev Revert with an error when an order is signed with a signer
     *      that is not active.
     */
    error SignerNotActive(address signer, bytes32 orderHash);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title  SignedZone
 * @author ryanio, BCLeFevre
 * @notice SignedZone is an implementation of SIP-7 that requires orders
 *         to be signed by an approved signer.
 *         https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 *
 */
interface SignedZoneInterface {
    /**
     * @notice Update the active status of a signer.
     *
     * @param signer The signer address to update.
     * @param active The new active status of the signer.
     */
    function updateSigner(address signer, bool active) external;

    /**
     * @notice Returns the active signers for the zone.
     *
     * @return signers The active signers.
     */
    function getActiveSigners()
        external
        view
        returns (address[] memory signers);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Schema } from "../../lib/ConsiderationStructs.sol";

/**
 * @dev SIP-5: Contract Metadata Interface for Seaport Contracts
 *      https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-5.md
 */
interface SIP5Interface {
    /**
     * @dev An event that is emitted when a SIP-5 compatible contract is deployed.
     */
    event SeaportCompatibleContractDeployed();

    /**
     * @dev Returns Seaport metadata for this contract, returning the
     *      contract name and supported schemas.
     *
     * @return name    The contract name
     * @return schemas The supported SIPs
     */
    function getSeaportMetadata()
        external
        view
        returns (string memory name, Schema[] memory schemas);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @dev ECDSA signature offsets.
uint256 constant ECDSA_MaxLength = 65;
uint256 constant ECDSA_signature_s_offset = 0x40;
uint256 constant ECDSA_signature_v_offset = 0x60;

/// @dev Helpers for memory offsets.
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;
uint256 constant FourWords = 0x80;
uint256 constant FiveWords = 0xa0;
uint256 constant Signature_lower_v = 27;
uint256 constant MaxUint8 = 0xff;
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
uint256 constant Ecrecover_precompile = 1;
uint256 constant Ecrecover_args_size = 0x80;
uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant Slot0x80 = 0x80;

/// @dev The EIP-712 digest offsets.
uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_SignedOrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;
uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

/*
 *  error InvalidController()
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidController_error_selector = 0x6d5769be;
uint256 constant InvalidController_error_length = 0x04;

/*
 *  error InvalidFulfiller(address expectedFulfiller, address actualFulfiller, bytes32 orderHash)
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: expectedFulfiller
 *    - 0x40: actualFullfiller
 *    - 0x60: orderHash
 * Revert buffer is memory[0x1c:0x80]
 */
uint256 constant InvalidFulfiller_error_selector = 0x1bcf9bb7;
uint256 constant InvalidFulfiller_error_expectedFulfiller_ptr = 0x20;
uint256 constant InvalidFulfiller_error_actualFulfiller_ptr = 0x40;
uint256 constant InvalidFulfiller_error_orderHash_ptr = 0x60;
uint256 constant InvalidFulfiller_error_length = 0x64;

/*
 *  error InvalidConsideration(uint256 expectedConsideration, uint256 actualConsideration, bytes32 orderHash)
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: expectedConsideration
 *    - 0x40: actualConsideration
 *    - 0x60: orderHash
 * Revert buffer is memory[0x1c:0x80]
 */
uint256 constant InvalidConsideration_error_selector = 0x59cb96d1;
uint256 constant InvalidConsideration_error_expectedConsideration_ptr = 0x20;
uint256 constant InvalidConsideration_error_actualConsideration_ptr = 0x40;
uint256 constant InvalidConsideration_error_orderHash_ptr = 0x60;
uint256 constant InvalidConsideration_error_length = 0x64;

/*
 *  error InvalidZoneParameterEncoding()
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidZoneParameterEncoding_error_selector = 0x46d5d895;
uint256 constant InvalidZoneParameterEncoding_error_length = 0x04;

/*
 * error InvalidExtraDataLength()
 *   - Defined in SignedZoneEventsAndErrors.sol
 * Memory layout:
 *   - 0x00: Left-padded selector (data begins at 0x1c)
 *   - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidExtraDataLength_error_selector = 0xd232fd2c;
uint256 constant InvalidExtraDataLength_error_orderHash_ptr = 0x20;
uint256 constant InvalidExtraDataLength_error_length = 0x24;
uint256 constant InvalidExtraDataLength_epected_length = 0x7e;

uint256 constant ExtraData_expiration_offset = 0x35;
uint256 constant ExtraData_substandard_version_byte_offset = 0x7d;
/*
 *  error InvalidSIP6Version()
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidSIP6Version_error_selector = 0x64115774;
uint256 constant InvalidSIP6Version_error_orderHash_ptr = 0x20;
uint256 constant InvalidSIP6Version_error_length = 0x24;

/*
 *  error InvalidSubstandardVersion()
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidSubstandardVersion_error_selector = 0x26787999;
uint256 constant InvalidSubstandardVersion_error_orderHash_ptr = 0x20;
uint256 constant InvalidSubstandardVersion_error_length = 0x24;

/*
 *  error InvalidSubstandardSupport()
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: reason
 *    - 0x40: substandardVersion
 *    - 0x60: orderHash
 * Revert buffer is memory[0x1c:0xe0]
 */
uint256 constant InvalidSubstandardSupport_error_selector = 0x2be76224;
uint256 constant InvalidSubstandardSupport_error_reason_offset_ptr = 0x20;
uint256 constant InvalidSubstandardSupport_error_substandard_version_ptr = 0x40;
uint256 constant InvalidSubstandardSupport_error_orderHash_ptr = 0x60;
uint256 constant InvalidSubstandardSupport_error_reason_length_ptr = 0x80;
uint256 constant InvalidSubstandardSupport_error_reason_ptr = 0xa0;
uint256 constant InvalidSubstandardSupport_error_reason_2_ptr = 0xc0;
uint256 constant InvalidSubstandardSupport_error_length = 0xc4;

/*
 * error SignatureExpired()
 *   - Defined in SignedZoneEventsAndErrors.sol
 * Memory layout:
 *   - 0x00: Left-padded selector (data begins at 0x1c)
 *   - 0x20: expiration
 *   - 0x40: orderHash
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant SignatureExpired_error_selector = 0x16546071;
uint256 constant SignatureExpired_error_expiration_ptr = 0x20;
uint256 constant SignatureExpired_error_orderHash_ptr = 0x40;
uint256 constant SignatureExpired_error_length = 0x44;

// Zone parameter calldata pointers
uint256 constant Zone_parameters_cdPtr = 0x04;
uint256 constant Zone_parameters_fulfiller_cdPtr = 0x44;
uint256 constant Zone_consideration_head_cdPtr = 0xa4;
uint256 constant Zone_extraData_cdPtr = 0xc4;

// Zone parameter memory pointers
uint256 constant Zone_parameters_ptr = 0x20;

// Zone parameter offsets
uint256 constant Zone_parameters_offset = 0x24;
uint256 constant expectedFulfiller_offset = 0x45;
uint256 constant actualConsideration_offset = 0x84;
uint256 constant expectedConsideration_offset = 0xa2;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    ZoneParameters,
    Schema,
    ReceivedItem
} from "../lib/ConsiderationStructs.sol";

import { ZoneInterface } from "../interfaces/ZoneInterface.sol";

import {
    SignedZoneEventsAndErrors
} from "./interfaces/SignedZoneEventsAndErrors.sol";

import { SIP5Interface } from "./interfaces/SIP5Interface.sol";

import {
    SignedZoneControllerInterface
} from "./interfaces/SignedZoneControllerInterface.sol";

import "./lib/SignedZoneConstants.sol";

/**
 * @title  SignedZone
 * @author ryanio, BCLeFevre
 * @custom:modifiedby Tony Snark
 * @notice SignedZone is an implementation of SIP-7 that requires orders
 *         to be signed by an approved signer.
 *         https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 *
 *         Modification:
 *         Removes support for SIP7 sub-standard 1.
 *         Adds support for SIP7 sub-standard 3.
 */
contract SignedZone is SignedZoneEventsAndErrors, ZoneInterface, SIP5Interface {
    /// @dev The zone's controller that is set during deployment.
    address private immutable _controller;

    /// @dev The authorized signers, and if they are active
    mapping(address => bool) private _signers;

    /// @dev The EIP-712 digest parameters.
    bytes32 internal immutable _NAME_HASH = keccak256(bytes("SignedZone"));
    bytes32 internal immutable _VERSION_HASH = keccak256(bytes("1.0.0"));
    // prettier-ignore
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH = keccak256(
          abi.encodePacked(
            "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
            ")"
          )
        );
    // prettier-ignore
    bytes32 internal immutable _SIGNED_ORDER_TYPEHASH = keccak256(
          abi.encodePacked(
            "SignedOrder(",
                "address fulfiller,",
                "uint64 expiration,",
                "bytes32 orderHash,",
                "bytes context",
            ")"
          )
        );

    bytes public constant CONSIDERATION_BYTES =
        // prettier-ignore
        abi.encodePacked(
              "Consideration(",
                  "ReceivedItem[] consideration",
              ")"
        );

    bytes public constant RECEIVED_ITEM_BYTES =
        // prettier-ignore
        abi.encodePacked(
              "ReceivedItem(",
                  "uint8 itemType,",
                  "address token,",
                  "uint256 identifier,",
                  "uint256 amount,",
                  "address recipient",
              ")"
        );

    bytes32 public constant RECEIVED_ITEM_HASHTYPE =
        keccak256(RECEIVED_ITEM_BYTES);

    bytes32 public constant CONSIDERATION_HASHTYPE =
        keccak256(abi.encodePacked(CONSIDERATION_BYTES, RECEIVED_ITEM_BYTES));

    uint256 internal immutable _CHAIN_ID = block.chainid;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /**
     * @notice Constructor to deploy the contract.
     */
    constructor() {
        // Set the deployer as the controller.
        _controller = msg.sender;

        // Derive and set the domain separator.
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Emit an event to signal a SIP-5 contract has been deployed.
        emit SeaportCompatibleContractDeployed();
    }

    /**
     * @notice Check if a given order including extraData is currently valid.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller.
     *
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function validateOrder(ZoneParameters calldata zoneParameters)
        public
        view
        virtual
        override
        returns (bytes4 validOrderMagicValue)
    {
        // Check Zone parameters validity.
        _assertValidZoneParameters();

        // Put the extraData and orderHash on the stack for cheaper access.
        bytes calldata extraData = zoneParameters.extraData;
        bytes32 orderHash = zoneParameters.orderHash;
        uint256 considerationLength;
        // Declare a variable to hold the expiration.
        uint64 expiration;

        // Validate the extraData.
        assembly {
            // Get the length of the extraData.
            let extraDataPtr := add(0x24, calldataload(Zone_extraData_cdPtr))
            let extraDataLength := calldataload(extraDataPtr)

            if iszero(
                eq(extraDataLength, InvalidExtraDataLength_epected_length)
            ) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidExtraDataLength_error_selector)
                mstore(InvalidExtraDataLength_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //   "InvalidExtraDataLength(bytes32)", orderHash)
                // )
                revert(0x1c, InvalidExtraDataLength_error_length)
            }

            // extraData bytes 0-1: SIP-6 version byte (MUST be 0x00)
            let versionByte := shr(248, calldataload(add(extraDataPtr, 0x20)))

            if iszero(eq(versionByte, 0x00)) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidSIP6Version_error_selector)
                mstore(InvalidSIP6Version_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //   "InvalidSIP6Version(bytes32)", orderHash)
                // )
                revert(0x1c, InvalidSIP6Version_error_length)
            }

            // extraData bytes 93-94: Substandard #1 (MUST be 0x00)
            let subStandardVersionByte := shr(
                248,
                calldataload(
                    add(extraDataPtr, ExtraData_substandard_version_byte_offset)
                )
            )

            if iszero(eq(subStandardVersionByte, 0x00)) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidSubstandardVersion_error_selector)
                mstore(InvalidSubstandardVersion_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //   "InvalidSubstandardVersion(bytes32)", orderHash)
                // )
                revert(0x1c, InvalidSubstandardVersion_error_length)
            }

            // extraData bytes 21-29: expiration timestamp (uint64)
            expiration := shr(
                192,
                calldataload(add(extraDataPtr, ExtraData_expiration_offset))
            )
            // Revert if expired.
            if lt(expiration, timestamp()) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, SignatureExpired_error_selector)
                mstore(SignatureExpired_error_expiration_ptr, expiration)
                mstore(SignatureExpired_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //   "SignatureExpired(uint256, bytes32)", expiration orderHash)
                // )
                revert(0x1c, SignatureExpired_error_length)
            }

            // // Get the length of the consideration array.
            considerationLength := calldataload(
                add(0x24, calldataload(Zone_consideration_head_cdPtr))
            )
        }

        // extraData bytes 29-93: signature
        // (strictly requires 64 byte compact sig, EIP-2098)
        bytes calldata signature = extraData[29:93];

        // extraData bytes 93-end: context (optional, variable length)
        bytes calldata context = extraData[93:];

        // Check the validity of the Substandard #1 extraData and get the
        // expected fulfiller address.
        address expectedFulfiller = _getExpectedFulfiller(orderHash);

        // Check the validity of the Substandard #1 extraData and get the
        // expected fulfiller address.
        if (considerationLength > 0) {
            _assertValidSubstandard(
                _deriveConsiderationHash(zoneParameters.consideration),
                orderHash
            );
        }

        // Derive the signedOrder hash.
        bytes32 signedOrderHash = _deriveSignedOrderHash(
            expectedFulfiller,
            expiration,
            orderHash,
            context
        );

        // Derive the EIP-712 digest using the domain separator and signedOrder
        // hash.
        bytes32 digest = _deriveEIP712Digest(
            _domainSeparator(),
            signedOrderHash
        );

        // Recover the signer address from the digest and signature.
        address recoveredSigner = _recoverSigner(digest, signature);

        // Revert if the signer is not active.
        if (!_signers[recoveredSigner]) {
            revert SignerNotActive(recoveredSigner, orderHash);
        }
        // Return the selector of validateOrder as the magic value.
        validOrderMagicValue = ZoneInterface.validateOrder.selector;
    }

    /**
     * @dev Returns Seaport metadata for this contract, returning the
     *      contract name and supported schemas.
     *
     * @return name The contract name
     * @return schemas  The supported SIPs
     */
    function getSeaportMetadata()
        external
        view
        override(SIP5Interface, ZoneInterface)
        returns (string memory name, Schema[] memory schemas)
    {
        // Return the supported SIPs.
        schemas = new Schema[](1);
        schemas[0].id = 7;

        // Get the SIP-7 information.
        (
            bytes32 domainSeparator,
            string memory zoneName,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        ) = _sip7Information();

        // Return the zone name.
        name = zoneName;

        // Encode the SIP-7 information.
        schemas[0].metadata = abi.encode(
            domainSeparator,
            apiEndpoint,
            substandards,
            documentationURI
        );
    }

    /**
     * @notice The fallback function is used as a dispatcher for the
     *         `updateSigner`, `getActiveSigners` and `supportsInterface`
     *         functions.
     */
    // prettier-ignore
    fallback(bytes calldata) external payable returns (bytes memory output) {
        // Get the function selector.
        bytes4 selector = msg.sig;

        if (selector == 0xf460590b) {
            // updateSigner(address,bool)

            // Get the signer, and active status.
            address signer = abi.decode(msg.data[4:], (address));
            bool active = abi.decode(msg.data[36:], (bool));

            // Call to update the signer.
            _updateSigner(signer, active);
        } else if (selector == 0xa784b80c) {
            // getActiveSigners()

            // Call the internal function to get the active signers.
            return abi.encode(_getActiveSigners());
        } else if (selector == 0x01ffc9a7) {
            // supportsInterface(bytes4)

            // Get the interface ID.
            bytes4 interfaceId = abi.decode(msg.data[4:], (bytes4));

            // Call the internal function to determine if the interface is
            // supported.
            return abi.encode(_supportsInterface(interfaceId));
        }
    }

    /**
     * @notice Add or remove a signer to the zone.
     *         Only the controller can call this function.
     *
     * @param signer The signer address to add or remove.
     */
    function _updateSigner(address signer, bool active) internal {
        // Only the controller can call this function.
        _assertCallerIsController();
        // Add or remove the signer.
        active ? _addSigner(signer) : _removeSigner(signer);
    }

    /**
     * @notice Add a new signer to the zone.
     *         Only the controller or an active signer can call this function.
     *
     * @param signer The new signer address to add.
     */
    function _addSigner(address signer) internal {
        // Set the signer info.
        _signers[signer] = true;
        // Emit an event that the signer was added.
        emit SignerAdded(signer);
    }

    /**
     * @notice Remove an active signer from the zone.
     *         Only the controller or an active signer can call this function.
     *
     * @param signer The signer address to remove.
     */
    function _removeSigner(address signer) internal {
        // Set the signer's active status to false.
        _signers[signer] = false;

        // Emit an event that the signer was removed.
        emit SignerRemoved(signer);
    }

    /**
     * @notice Returns the active signers for the zone.
     *
     * @return signers The active signers.
     */
    function _getActiveSigners()
        internal
        view
        returns (address[] memory signers)
    {
        // Return the active signers for the zone by calling the controller.
        signers = SignedZoneControllerInterface(_controller).getActiveSigners(
            address(this)
        );
    }

    /**
     * @notice Returns whether the interface is supported.
     *
     * @param interfaceId The interface id to check against.
     */
    function _supportsInterface(bytes4 interfaceId)
        internal
        pure
        returns (bool supportsInterface)
    {
        // Determine if the interface is supported.
        supportsInterface =
            interfaceId == type(SIP5Interface).interfaceId || // SIP-5
            interfaceId == type(ZoneInterface).interfaceId || // ZoneInterface
            interfaceId == 0x01ffc9a7; // ERC-165
    }

    /**
     * @notice Internal call to return the signing information, substandards,
     *         and documentation about the zone.
     *
     * @return domainSeparator  The domain separator used for signing.
     * @return zoneName         The zone name.
     * @return apiEndpoint      The API endpoint for the zone.
     * @return substandards     The substandards supported by the zone.
     * @return documentationURI The documentation URI for the zone.
     */
    function _sip7Information()
        internal
        view
        returns (
            bytes32 domainSeparator,
            string memory zoneName,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        )
    {
        // Return the SIP-7 information.
        domainSeparator = _domainSeparator();

        // Get the SIP-7 information from the controller.
        (
            ,
            zoneName,
            apiEndpoint,
            substandards,
            documentationURI
        ) = SignedZoneControllerInterface(_controller)
            .getAdditionalZoneInformation(address(this));
    }

    /**
     * @dev Derive the signedOrder hash from the orderHash and expiration.
     *
     * @param fulfiller  The expected fulfiller address.
     * @param expiration The signature expiration timestamp.
     * @param orderHash  The order hash.
     * @param context    The optional variable-length context.
     *
     * @return signedOrderHash The signedOrder hash.
     *
     */
    function _deriveSignedOrderHash(
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes calldata context
    ) internal view returns (bytes32 signedOrderHash) {
        // Derive the signed order hash.
        signedOrderHash = keccak256(
            abi.encode(
                _SIGNED_ORDER_TYPEHASH,
                fulfiller,
                expiration,
                orderHash,
                keccak256(context)
            )
        );
    }

    /**
     * @dev Internal view function to return the signer of a signature.
     *
     * @param digest    The digest to verify the signature against.
     * @param signature A signature from the signer indicating that the order
     *                  has been approved.
     *
     * @return recoveredSigner The recovered signer.
     */
    function _recoverSigner(bytes32 digest, bytes memory signature)
        internal
        view
        returns (address recoveredSigner)
    {
        // Utilize assembly to perform optimized signature verification check.
        assembly {
            // Ensure that first word of scratch space is empty.
            mstore(0, 0)

            // Declare value for v signature parameter.
            let v

            // Get the length of the signature.
            let signatureLength := mload(signature)

            // Get the pointer to the value preceding the signature length.
            // This will be used for temporary memory overrides - either the
            // signature head for isValidSignature or the digest for ecrecover.
            let wordBeforeSignaturePtr := sub(signature, OneWord)

            // Cache the current value behind the signature to restore it later.
            let cachedWordBeforeSignature := mload(wordBeforeSignaturePtr)

            // Declare lenDiff + recoveredSigner scope to manage stack pressure.
            {
                // Take the difference between the max ECDSA signature length
                // and the actual signature length. Overflow desired for any
                // values > 65. If the diff is not 0 or 1, it is not a valid
                // ECDSA signature - move on to EIP1271 check.
                let lenDiff := sub(ECDSA_MaxLength, signatureLength)

                // If diff is 0 or 1, it may be an ECDSA signature.
                // Try to recover signer.
                if iszero(gt(lenDiff, 1)) {
                    // Read the signature `s` value.
                    let originalSignatureS := mload(
                        add(signature, ECDSA_signature_s_offset)
                    )

                    // Read the first byte of the word after `s`. If the
                    // signature is 65 bytes, this will be the real `v` value.
                    // If not, it will need to be modified - doing it this way
                    // saves an extra condition.
                    v := byte(
                        0,
                        mload(add(signature, ECDSA_signature_v_offset))
                    )

                    // If lenDiff is 1, parse 64-byte signature as ECDSA.
                    if lenDiff {
                        // Extract yParity from highest bit of vs and add 27 to
                        // get v.
                        v := add(
                            shr(MaxUint8, originalSignatureS),
                            Signature_lower_v
                        )

                        // Extract canonical s from vs, all but the highest bit.
                        // Temporarily overwrite the original `s` value in the
                        // signature.
                        mstore(
                            add(signature, ECDSA_signature_s_offset),
                            and(
                                originalSignatureS,
                                EIP2098_allButHighestBitMask
                            )
                        )
                    }
                    // Temporarily overwrite the signature length with `v` to
                    // conform to the expected input for ecrecover.
                    mstore(signature, v)

                    // Temporarily overwrite the word before the length with
                    // `digest` to conform to the expected input for ecrecover.
                    mstore(wordBeforeSignaturePtr, digest)

                    // Attempt to recover the signer for the given signature. Do
                    // not check the call status as ecrecover will return a null
                    // address if the signature is invalid.
                    pop(
                        staticcall(
                            gas(),
                            Ecrecover_precompile, // Call ecrecover precompile.
                            wordBeforeSignaturePtr, // Use data memory location.
                            Ecrecover_args_size, // Size of digest, v, r, and s.
                            0, // Write result to scratch space.
                            OneWord // Provide size of returned result.
                        )
                    )

                    // Restore cached word before signature.
                    mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)

                    // Restore cached signature length.
                    mstore(signature, signatureLength)

                    // Restore cached signature `s` value.
                    mstore(
                        add(signature, ECDSA_signature_s_offset),
                        originalSignatureS
                    )

                    // Read the recovered signer from the buffer given as return
                    // space for ecrecover.
                    recoveredSigner := mload(0)
                }
            }

            // Restore the cached values overwritten by selector, digest and
            // signature head.
            mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)
        }
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator() internal view returns (bytes32) {
        // prettier-ignore
        return block.chainid == _CHAIN_ID
            ? _DOMAIN_SEPARATOR
            : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return domainSeparator The derived domain separator.
     */
    function _deriveDomainSeparator()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        bytes32 typehash = _EIP_712_DOMAIN_TYPEHASH;
        bytes32 nameHash = _NAME_HASH;
        bytes32 versionHash = _VERSION_HASH;

        // Leverage scratch space and other memory to perform an efficient hash.
        assembly {
            // Retrieve the free memory pointer; it will be replaced afterwards.
            let freeMemoryPointer := mload(FreeMemoryPointerSlot)

            // Retrieve value at 0x80; it will also be replaced afterwards.
            let slot0x80 := mload(Slot0x80)

            // Place typehash, name hash, and version hash at start of memory.
            mstore(0, typehash)
            mstore(OneWord, nameHash)
            mstore(TwoWords, versionHash)

            // Place chainId in the next memory location.
            mstore(ThreeWords, chainid())

            // Place the address of this contract in the next memory location.
            mstore(FourWords, address())

            // Hash relevant region of memory to derive the domain separator.
            domainSeparator := keccak256(0, FiveWords)

            // Restore the free memory pointer.
            mstore(FreeMemoryPointerSlot, freeMemoryPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)

            // Restore the value at 0x80.
            mstore(Slot0x80, slot0x80)
        }
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param signedOrderHash The signedOrder hash.
     *
     * @return digest The digest hash.
     */
    function _deriveEIP712Digest(
        bytes32 domainSeparator,
        bytes32 signedOrderHash
    ) internal pure returns (bytes32 digest) {
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the signed order hash in scratch space, spilling into the
            // first two bytes of the free memory pointer — this should never be
            // set as memory cannot be expanded to that size, and will be
            // zeroed out after the hash is performed.
            mstore(EIP712_SignedOrderHash_offset, signedOrderHash)

            // Hash the relevant region
            digest := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_SignedOrderHash_offset, 0)
        }
    }

    /**
     * @dev Private view function to revert if the caller is not the
     *      controller.
     */
    function _assertCallerIsController() internal view {
        // Get the controller address to use in the assembly block.
        address controller = _controller;

        assembly {
            // Revert if the caller is not the controller.
            if iszero(eq(caller(), controller)) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidController_error_selector)
                // revert(abi.encodeWithSignature(
                //   "InvalidController()")
                // )
                revert(0x1c, InvalidController_error_length)
            }
        }
    }

    /**
     * @dev Internal pure function to validate calldata offsets for the
     *      dyanamic type in ZoneParameters. This ensures that functions using
     *      the calldata object normally will be using the same data as the
     *      assembly functions and that values that are bound to a given range
     *      are within that range.
     */
    function _assertValidZoneParameters() internal pure {
        // Utilize assembly in order to read offset data directly from calldata.
        assembly {
            /*
             * Checks:
             * 1. Zone parameters struct offset == 0x20
             */

            // Zone parameters at calldata 0x04 must have offset of 0x20.
            if iszero(
                eq(calldataload(Zone_parameters_cdPtr), Zone_parameters_ptr)
            ) {
                // Store left-padded selector with push4 (reduces bytecode), mem[28:32] = selector
                mstore(0, InvalidZoneParameterEncoding_error_selector)
                // revert(abi.encodeWithSignature("InvalidZoneParameterEncoding()"))
                revert(0x1c, InvalidZoneParameterEncoding_error_length)
            }
        }
    }

    /**
     * @dev Internal pure function to ensure that the context argument for the
     *      supplied extra data follows the substandard #1 format. Returns the
     *      expected fulfiller of the order for deriving the signed order hash.
     *
     * @param orderHash The order hash.
     *
     * @return expectedFulfiller The expected fulfiller of the order.
     */
    function _getExpectedFulfiller(bytes32 orderHash)
        internal
        pure
        returns (address expectedFulfiller)
    {
        // Revert if the expected fulfiller is not the zero address and does
        // not match the actual fulfiller
        assembly {
            // Get the actual fulfiller.
            let actualFulfiller := calldataload(Zone_parameters_fulfiller_cdPtr)
            let extraDataPtr := calldataload(Zone_extraData_cdPtr)

            // Get the expected fulfiller.
            expectedFulfiller := shr(
                96,
                calldataload(add(expectedFulfiller_offset, extraDataPtr))
            )

            // Revert if expected fulfiller is not the zero address and does
            // not match the actual fulfiller.
            if and(
                iszero(iszero(expectedFulfiller)),
                iszero(eq(expectedFulfiller, actualFulfiller))
            ) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidFulfiller_error_selector)
                mstore(
                    InvalidFulfiller_error_expectedFulfiller_ptr,
                    expectedFulfiller
                )
                mstore(
                    InvalidFulfiller_error_actualFulfiller_ptr,
                    actualFulfiller
                )
                mstore(InvalidFulfiller_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //   "InvalidFulfiller(address,address,bytes32)", expectedFulfiller, actualFulfiller, orderHash)
                // )
                revert(0x1c, InvalidFulfiller_error_length)
            }
        }
    }

    /**
     * @dev Internal pure function to ensure that the context argument for the
     *      supplied extra data follows the substandard #1 format. Returns the
     *      expected fulfiller of the order for deriving the signed order hash.
     *
     */
    function _assertValidSubstandard(
        bytes32 considerationHash,
        bytes32 orderHash
    ) internal pure {
        // identifier does not match the actual consideration.
        assembly {
            let extraDataPtr := calldataload(Zone_extraData_cdPtr)
            let considerationPtr := calldataload(Zone_consideration_head_cdPtr)
            // Get the actual consideration.
            let actualConsideration := calldataload(
                add(actualConsideration_offset, considerationPtr)
            )

            // Get the expected consideration.
            let expectedConsiderationHash := calldataload(
                add(expectedConsideration_offset, extraDataPtr) //TODO rename
            )
            // Revert if expected consideration item does not match the actual
            // consideration item.
            if iszero(eq(considerationHash, expectedConsiderationHash)) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidConsideration_error_selector)
                mstore(
                    InvalidConsideration_error_expectedConsideration_ptr,
                    expectedConsiderationHash
                )
                mstore(
                    InvalidConsideration_error_actualConsideration_ptr,
                    actualConsideration
                )
                mstore(InvalidConsideration_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //   "InvalidConsideration(uint256,uint256,bytes32)", expectedConsideration, actualConsideration, orderHash)
                // )
                revert(0x1c, InvalidConsideration_error_length)
            }
        }
    }

    /// @dev Calculates consideration hash
    function _deriveConsiderationHash(ReceivedItem[] calldata consideration)
        internal
        pure
        returns (bytes32)
    {
        uint256 numberOfItems = consideration.length;
        bytes32[] memory considerationHashes = new bytes32[](numberOfItems);
        for (uint256 i; i < numberOfItems; ) {
            considerationHashes[i] = _deriveReceivedItemHash(consideration[i]);
            unchecked {
                ++i;
            }
        }
        return
            keccak256(
                abi.encode(
                    CONSIDERATION_HASHTYPE,
                    keccak256(abi.encodePacked(considerationHashes))
                )
            );
    }

    /// @dev Calculates consideration item hash
    function _deriveReceivedItemHash(ReceivedItem calldata receivedItem)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    RECEIVED_ITEM_HASHTYPE,
                    receivedItem.itemType,
                    receivedItem.token,
                    receivedItem.identifier,
                    receivedItem.amount,
                    receivedItem.recipient
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { SignedZone } from "./SignedZone.sol";

import { SignedZoneInterface } from "./interfaces/SignedZoneInterface.sol";

import {
    SignedZoneControllerInterface
} from "./interfaces/SignedZoneControllerInterface.sol";

import {
    SignedZoneControllerEventsAndErrors
} from "./interfaces/SignedZoneControllerEventsAndErrors.sol";

import "./lib/SignedZoneConstants.sol";

/**
 * @title  SignedZoneController
 * @author BCLeFevre
 * @notice SignedZoneController enables the deploying of SignedZones.
 *         SignedZones are an implementation of SIP-7 that requires orders to
 *         be signed by  an approved signer.
 *         https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 */
contract SignedZoneController is
    SignedZoneControllerInterface,
    SignedZoneControllerEventsAndErrors
{
    /**
     * @dev The struct for storing signer info.
     */
    struct SignerInfo {
        /// @dev If the signer is currently active.
        bool active;
        /// @dev If the signer has been active before.
        bool previouslyActive;
    }

    // Properties used by the signed zone, stored on the controller.
    struct SignedZoneProperties {
        /// @dev Owner of the signed zone (used for permissioned functions)
        address owner;
        /// @dev Potential owner of the signed zone
        address potentialOwner;
        /// @dev The name for this zone returned in getSeaportMetadata().
        string zoneName;
        /// @dev The API endpoint where orders for this zone can be signed.
        ///      Request and response payloads are defined in SIP-7.
        string apiEndpoint;
        /// @dev The URI to the documentation describing the behavior of the
        ///      contract.
        string documentationURI;
        /// @dev The substandards supported by this zone.
        ///      Substandards are defined in SIP-7.
        uint256[] substandards;
        /// @dev Mapping of signer information keyed by signer Address
        mapping(address => SignerInfo) signers;
        /// @dev List of active signers
        address[] activeSignerList;
    }

    /// @dev Mapping of signed zone properties keyed by the Signed Zone
    ///      address.
    mapping(address => SignedZoneProperties) internal _signedZones;

    /// @dev The EIP-712 digest parameters for the SignedZone.
    bytes32 internal immutable _NAME_HASH = keccak256(bytes("SignedZone"));
    bytes32 internal immutable _VERSION_HASH = keccak256(bytes("1.0"));
    // prettier-ignore
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH = keccak256(
          abi.encodePacked(
            "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
            ")"
          )
        );
    uint256 internal immutable _CHAIN_ID = block.chainid;

    // Set the signed zone creation code as an immutable argument.
    bytes32 internal immutable _SIGNED_ZONE_CREATION_CODE_HASH;

    /**
     * @dev Initialize contract
     */
    constructor() {
        // Derive the signed zone creation code hash and set it as an
        // immutable.
        _SIGNED_ZONE_CREATION_CODE_HASH = keccak256(
            type(SignedZone).creationCode
        );
    }

    /**
     * @notice Deploy a SignedZone to a precomputed address.
     *
     * @param zoneName    The name for the zone returned in
     *                    getSeaportMetadata().
     * @param apiEndpoint The API endpoint where orders for this zone can be
     *                    signed.
     * @param documentationURI The URI to the documentation describing the
     *                         behavior of the contract.
     *                    Request and response payloads are defined in SIP-7.
     * @param salt        The salt to be used to derive the zone address
     * @param initialOwner The initial owner to set for the new zone.
     *
     * @return derivedAddress The derived address for the zone.
     */
    function createZone(
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        address initialOwner,
        bytes32 salt
    ) external override returns (address derivedAddress) {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InvalidInitialOwner();
        }

        // Ensure the first 20 bytes of the salt are the same as the msg.sender.
        if ((address(uint160(bytes20(salt))) != msg.sender)) {
            // Revert with an error indicating that the creator is invalid.
            revert InvalidCreator();
        }

        // Derive the SignedZone address from the deployer, salt and creation
        // code hash.
        derivedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            _SIGNED_ZONE_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        // TODO : Check runtime code hash to ensure that the zone is not already
        // deployed.
        // Revert if a zone is currently deployed to the derived address.
        if (derivedAddress.code.length != 0) {
            revert ZoneAlreadyExists(derivedAddress);
        }

        // Deploy the zone using the supplied salt.
        new SignedZone{ salt: salt }();

        // Initialize storage variable referencing signed zone properties.
        SignedZoneProperties storage signedZoneProperties = _signedZones[
            derivedAddress
        ];

        // Set the supplied intial owner as the owner of the zone.
        signedZoneProperties.owner = initialOwner;
        // Set the zone name.
        signedZoneProperties.zoneName = zoneName;
        // Set the API endpoint.
        signedZoneProperties.apiEndpoint = apiEndpoint;
        // Set the documentation URI.
        signedZoneProperties.documentationURI = documentationURI;
        // Set the substandard.
        signedZoneProperties.substandards = [3];

        // Emit an event signifying that the zone was created.
        emit ZoneCreated(
            derivedAddress,
            zoneName,
            apiEndpoint,
            documentationURI,
            salt
        );

        // Emit an event indicating that zone ownership has been assigned.
        emit OwnershipTransferred(derivedAddress, address(0), initialOwner);
    }

    /**
     * @notice Initiate zone ownership transfer by assigning a new potential
     *         owner for the given zone. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the zone.
     *         Only the owner of the zone in question may call this function.
     *
     * @param zone The zone for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the zone.
     */
    function transferOwnership(address zone, address newPotentialOwner)
        external
        override
    {
        // Ensure the caller is the current owner of the zone in question.
        _assertCallerIsZoneOwner(zone);

        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsZeroAddress(zone);
        }

        // Ensure the new potential owner is not already set.
        if (newPotentialOwner == _signedZones[zone].potentialOwner) {
            revert NewPotentialOwnerAlreadySet(zone, newPotentialOwner);
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner of the zone.
        _signedZones[zone].potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a zone.
     *         Only the owner of the zone in question may call this function.
     *
     * @param zone The zone for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address zone) external override {
        // Ensure the caller is the current owner of the zone in question.
        _assertCallerIsZoneOwner(zone);

        // Ensure that ownership transfer is currently possible.
        if (_signedZones[zone].potentialOwner == address(0)) {
            revert NoPotentialOwnerCurrentlySet(zone);
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the zone.
        _signedZones[zone].potentialOwner = address(0);
    }

    /**
     * @notice Accept ownership of a supplied zone. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param zone The zone for which to accept ownership.
     */
    function acceptOwnership(address zone) external override {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // If caller does not match current potential owner of the zone...
        if (msg.sender != _signedZones[zone].potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner(zone);
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner from the zone.
        _signedZones[zone].potentialOwner = address(0);

        // Emit an event indicating zone ownership has been transferred.
        emit OwnershipTransferred(zone, _signedZones[zone].owner, msg.sender);

        // Set the caller as the owner of the zone.
        _signedZones[zone].owner = msg.sender;
    }

    /**
     * @notice Retrieve the current owner of a deployed zone.
     *
     * @param zone The zone for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied zone.
     */
    function ownerOf(address zone)
        external
        view
        override
        returns (address owner)
    {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // Retrieve the current owner of the zone in question.
        owner = _signedZones[zone].owner;
    }

    /**
     * @notice Retrieve the potential owner, if any, for a given zone. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the zone in question via `acceptOwnership`.
     *
     * @param zone The zone for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the zone.
     */
    function getPotentialOwner(address zone)
        external
        view
        override
        returns (address potentialOwner)
    {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // Retrieve the current potential owner of the zone in question.
        potentialOwner = _signedZones[zone].potentialOwner;
    }

    /**
     * @notice Returns the active signers for the zone.
     *
     * @param zone The zone to return the active signers for.
     *
     * @return signers The active signers.
     */
    function getActiveSigners(address zone)
        external
        view
        override
        returns (address[] memory signers)
    {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // Retrieve storage region where the singers for the signedZone are
        // stored.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Return the active signers for the zone.
        signers = signedZoneProperties.activeSignerList;
    }

    /**
     * @notice Update the API endpoint returned by a zone.
     *         Only the owner or an active signer of the supplied zone can call
     *         this function.
     *
     * @param zone     The signed zone to update the API endpoint for.
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(address zone, string calldata newApiEndpoint)
        external
        override
    {
        // Ensure the caller is the owner or an active signer of the signed zone.
        _assertCallerIsZoneOwnerOrSigner(zone);

        // Retrieve storage region where the singers for the signedZone are
        // stored.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Update the API endpoint on the signed zone.
        signedZoneProperties.apiEndpoint = newApiEndpoint;
    }

    /**
     * @notice Add or remove a signer from the supplied zone.
     *         Only the owner or an active signer of the supplied zone can call
     *         this function.
     *
     * @param zone     The signed zone to update the signer permissions for.
     * @param signer   The signer to update the permissions for.
     * @param active   Whether the signer should be active or not.
     */
    function updateSigner(
        address zone,
        address signer,
        bool active
    ) external override {
        // Ensure the caller is the owner or an active signer of the signed zone.
        _assertCallerIsZoneOwnerOrSigner(zone);

        // Retrieve storage region where the singers for the signedZone are
        // stored.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Validate signer permissions.
        _assertSignerPermissions(signedZoneProperties, signer, active);

        // Update the signer on the signed zone.
        SignedZoneInterface(zone).updateSigner(signer, active);

        // Update the signer information.
        signedZoneProperties.signers[signer].active = active;
        signedZoneProperties.signers[signer].previouslyActive = true;
        // Add the signer to the list of signers if they are active.
        if (active) {
            signedZoneProperties.activeSignerList.push(signer);
        } else {
            // Remove the signer from the list of signers.
            for (
                uint256 i = 0;
                i < signedZoneProperties.activeSignerList.length;

            ) {
                if (signedZoneProperties.activeSignerList[i] == signer) {
                    signedZoneProperties.activeSignerList[
                            i
                        ] = signedZoneProperties.activeSignerList[
                        signedZoneProperties.activeSignerList.length - 1
                    ];
                    signedZoneProperties.activeSignerList.pop();
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        }

        // Emit an event signifying that the signer was updated.
        emit SignerUpdated(zone, signer, active);
    }

    /**
     * @notice Derive the zone address associated with a salt.
     *
     * @param salt  The salt to be used to derive the zone address.
     *
     * @return derivedAddress The derived address of the signed zone.
     */
    function getZone(bytes32 salt)
        external
        view
        override
        returns (address derivedAddress)
    {
        // Derive the SignedZone address from deployer, salt and creation code
        // hash.
        derivedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            _SIGNED_ZONE_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /**
     * @notice External call to return the signing information, substandards,
     *         and documentation about the zone.
     *
     * @return domainSeparator  The domain separator used for signing.
     * @return zoneName         The name of the zone.
     * @return apiEndpoint      The API endpoint for the zone.
     * @return substandards     The substandards supported by the zone.
     * @return documentationURI The documentation URI for the zone.
     */
    function getAdditionalZoneInformation(address zone)
        external
        view
        override
        returns (
            bytes32 domainSeparator,
            string memory zoneName,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        )
    {
        // Ensure the zone exists.
        _assertZoneExists(zone);

        // Return the zone's additional information.
        return _additionalZoneInformation(zone);
    }

    /**
     * @notice Internal call to return the signing information, substandards,
     *         and documentation about the zone.
     *
     * @return domainSeparator  The domain separator used for signing.
     * @return zoneName         The name of the zone.
     * @return apiEndpoint      The API endpoint for the zone.
     * @return substandards     The substandards supported by the zone.
     * @return documentationURI The documentation URI for the zone.
     */
    function _additionalZoneInformation(address zone)
        internal
        view
        returns (
            bytes32 domainSeparator,
            string memory zoneName,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        )
    {
        // Get the zone properties.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Return the SIP-7 information.
        domainSeparator = _domainSeparator(zone);
        zoneName = signedZoneProperties.zoneName;
        apiEndpoint = signedZoneProperties.apiEndpoint;
        substandards = signedZoneProperties.substandards;
        documentationURI = signedZoneProperties.documentationURI;
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator(address zone) internal view returns (bytes32) {
        // prettier-ignore
        return _deriveDomainSeparator(zone);
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return domainSeparator The derived domain separator.
     */
    function _deriveDomainSeparator(address zone)
        internal
        view
        returns (bytes32 domainSeparator)
    {
        bytes32 typehash = _EIP_712_DOMAIN_TYPEHASH;
        bytes32 nameHash = _NAME_HASH;
        bytes32 versionHash = _VERSION_HASH;

        // Leverage scratch space and other memory to perform an efficient hash.
        assembly {
            // Retrieve the free memory pointer; it will be replaced afterwards.
            let freeMemoryPointer := mload(FreeMemoryPointerSlot)

            // Retrieve value at 0x80; it will also be replaced afterwards.
            let slot0x80 := mload(Slot0x80)

            // Place typehash, name hash, and version hash at start of memory.
            mstore(0, typehash)
            mstore(OneWord, nameHash)
            mstore(TwoWords, versionHash)

            // Place chainId in the next memory location.
            mstore(ThreeWords, chainid())

            // Place the address of the signed zone contract in the next memory location.
            mstore(FourWords, zone)

            // Hash relevant region of memory to derive the domain separator.
            domainSeparator := keccak256(0, FiveWords)

            // Restore the free memory pointer.
            mstore(FreeMemoryPointerSlot, freeMemoryPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)

            // Restore the value at 0x80.
            mstore(Slot0x80, slot0x80)
        }
    }

    /**
     * @dev Private view function to revert if the caller is not the owner of a
     *      given zone.
     *
     * @param zone The zone for which to assert ownership.
     */
    function _assertCallerIsZoneOwner(address zone) private view {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // If the caller does not match the current owner of the zone...
        if (msg.sender != _signedZones[zone].owner) {
            // Revert, indicating that the caller is not the owner.
            revert CallerIsNotOwner(zone);
        }
    }

    /**
     * @dev Private view function to revert if the caller is not the owner or
     *      an active signer of a given zone.
     *
     * @param zone The zone for which to assert ownership.
     */
    function _assertCallerIsZoneOwnerOrSigner(address zone) private view {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // Initialize storage variable referencing signed zone properties.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Ensure the caller is the owner or an active signer of the signed zone.
        if (
            msg.sender != _signedZones[zone].owner &&
            !signedZoneProperties.signers[msg.sender].active
        ) {
            // Revert, indicating that the caller is not the owner.
            revert CallerIsNotOwnerOrSigner(zone);
        }
    }

    /**
     * @dev Private view function to revert if a given zone does not exist.
     *
     * @param zone The zone for which to assert existence.
     */
    function _assertZoneExists(address zone) private view {
        // Attempt to retrieve a the owner for the zone in question.
        if (_signedZones[zone].owner == address(0)) {
            // Revert if no ownerwas located.
            revert NoZone();
        }
    }

    /**
     * @dev Private view function to revert if a signer being added to a zone
     *      is the zero address or the signer already exists, or the signer was
     *      previously authorized.  If the signer is being removed, the
     *      function will revert if the signer is not active.
     *
     * @param signedZoneProperties The signed zone properties for the zone.
     * @param signer The signer to add or remove.
     * @param active Whether the signer is being added or removed.
     */
    function _assertSignerPermissions(
        SignedZoneProperties storage signedZoneProperties,
        address signer,
        bool active
    ) private view {
        // If the signer is being added...
        if (active) {
            // Do not allow the zero address to be added as a signer.
            if (signer == address(0)) {
                revert SignerCannotBeZeroAddress();
            }

            // Revert if the signer is already added.
            if (signedZoneProperties.signers[signer].active) {
                revert SignerAlreadyAdded(signer);
            }

            // Revert if the signer was previously authorized.
            if (signedZoneProperties.signers[signer].previouslyActive) {
                revert SignerCannotBeReauthorized(signer);
            }
        } else {
            // Revert if the signer is not active.
            if (!signedZoneProperties.signers[signer].active) {
                revert SignerNotPresent(signer);
            }
        }
    }
}