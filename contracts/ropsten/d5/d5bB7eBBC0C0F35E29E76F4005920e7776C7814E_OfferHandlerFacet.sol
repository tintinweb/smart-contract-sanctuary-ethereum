// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBosonOfferHandler } from "../../interfaces/IBosonOfferHandler.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { ProtocolBase } from "../ProtocolBase.sol";
import { ProtocolLib } from "../ProtocolLib.sol";

/**
 * @title OfferHandlerFacet
 *
 * @notice Handles offers within the protocol
 */
contract OfferHandlerFacet is IBosonOfferHandler, ProtocolBase {

    /**
     * @notice Facet Initializer
     */
    function initialize()
    public
    onlyUnInitialized(type(IBosonOfferHandler).interfaceId)
    {
        DiamondLib.addSupportedInterface(type(IBosonOfferHandler).interfaceId);
    }

    /////////////////////////////////////
    ///    SINGLE OFFER MANAGEMENT    ///
    /////////////////////////////////////

    /**
     * @notice Creates an offer.
     *
     * Emits an OfferCreated event if successful.
     *
     * Reverts if:
     * - internal any of validations to store offer fails
     *
     * @param _offer - the fully populated struct with offer id set to 0x0 and voided set to false
     */
    function createOffer(
        Offer memory _offer
    )
    external
    override
    {        
        // Get the next offerId and increment the counter
        uint256 offerId = protocolCounters().nextOfferId++;
        
        // modify incoming struct so event value represents true state
        _offer.id = offerId;

        storeOffer(_offer);
      
        // Notify watchers of state change
        emit OfferCreated(offerId, _offer.sellerId, _offer);
    }

    /**
     * @notice Updates an existing offer.
     *
     * Emits an OfferUpdated event if successful.
     *
     * Reverts if:
     * - Offer is not updateable, i.e. is voided or some exchanges exist
     * - Any other validation for offer creation fails
     *
     * @param _offer - the fully populated struct with offer id set to offer to be updated and voided set to false
     */
    function updateOffer(
        Offer memory _offer
    )
    external
    override
    {
        // Offer must be updateable
        (, bool updateable) = isOfferUpdateable(_offer.id);
        require(updateable, OFFER_NOT_UPDATEABLE);

        storeOffer(_offer);

        // Notify watchers of state change
        emit OfferUpdated(_offer.id, _offer.sellerId, _offer);
    }
    
    /**
     * @notice Validates offer struct and store it to storage
     *
     * Reverts if:
     * - Valid from date is greater than valid until date
     * - Valid until date is not in the future
     * - Buyer cancel penalty is greater than price
     * - Voided is set to true
     *
     * @param _offer - the fully populated struct with offer id set to offer to be updated and voided set to false
     */
    function storeOffer(Offer memory _offer) internal {
        // TODO: check seller ID matches msg.sender

        // validFrom date must be less than validUntil date
        require(_offer.validFromDate < _offer.validUntilDate, OFFER_PERIOD_INVALID);

        // validUntil date must be in the future
        require(_offer.validUntilDate > block.timestamp, OFFER_PERIOD_INVALID);

        // buyerCancelPenalty should be less or equal to the item price
        require(_offer.buyerCancelPenalty <= _offer.price, OFFER_PENALTY_INVALID);

        // when creating offer, it cannot be set to voided
        require(!_offer.voided, OFFER_MUST_BE_ACTIVE);

        // Get storage location for offer
        (,Offer storage offer) = fetchOffer(_offer.id);

        // Set offer props individually since memory structs can't be copied to storage
        offer.id = _offer.id;
        offer.sellerId = _offer.sellerId;
        offer.price = _offer.price;
        offer.sellerDeposit = _offer.sellerDeposit;
        offer.buyerCancelPenalty = _offer.buyerCancelPenalty;
        offer.quantityAvailable = _offer.quantityAvailable;
        offer.validFromDate = _offer.validFromDate;
        offer.validUntilDate = _offer.validUntilDate;
        offer.redeemableFromDate = _offer.redeemableFromDate;
        offer.fulfillmentPeriodDuration = _offer.fulfillmentPeriodDuration;
        offer.voucherValidDuration = _offer.voucherValidDuration;
        offer.exchangeToken = _offer.exchangeToken;
        offer.metadataUri = _offer.metadataUri;
        offer.metadataHash = _offer.metadataHash;

    }

    /**
     * @notice Voids a given offer.
     *
     * Emits an OfferVoided event if successful.
     * Existing exchanges are not affected.
     * No further vouchers can be issued against a voided offer.
     *
     * Reverts if:
     * - Offer ID is invalid
     * - Offer is not owned by caller
     * - Offer has already been voided
     *
     * @param _offerId - the id of the offer to check
     */
    function voidOffer(uint256 _offerId)
    external
    override
    {
        // Get offer
        Offer storage offer = getValidOffer(_offerId);

        // Void the offer
        offer.voided = true;

        // Notify listeners of state change
        emit OfferVoided(_offerId, offer.sellerId);

    }

    /**
     * @notice Sets new valid until date
     *
     * Emits an OfferUpdated event if successful.
     *
     * Reverts if:
     * - Offer does not exist
     * - Caller is not the seller (TODO)
     * - New valid until date is before existing valid until dates
     *
     *  @param _offerId - the id of the offer to check
     *  @param _validUntilDate - new valid until date
     */
    function extendOffer(
        uint256 _offerId, uint _validUntilDate
    )
    external
    override
    {
        // Get offer
        Offer storage offer = getValidOffer(_offerId);

        // New valid until date must be greater than existing one
        require(offer.validUntilDate < _validUntilDate, OFFER_PERIOD_INVALID);

        // Void the offer
        offer.validUntilDate = _validUntilDate;

        // Notify watchers of state change
        emit OfferUpdated(_offerId, offer.sellerId, offer);
    }

    /**
     * @notice Gets offer from protocol storage, makes sure it exist and not voided
     *
     * Reverts if:
     * - Offer does not exist
     * - Caller is not the seller (TODO)
     * - Offer already voided
     *
     *  @param _offerId - the id of the offer to check
     */
    function getValidOffer(uint256 _offerId) internal view returns (Offer storage offer){

        bool exists;
        Seller storage seller;

        // Get offer
        (exists, offer) = fetchOffer(_offerId);

        // Offer must already exist
        require(exists, NO_SUCH_OFFER);

        // Get seller, we assume seller exists if offer exists
        (,seller) = fetchSeller(offer.sellerId);

        // Caller must be seller's operator address
        //require(seller.operator == msg.sender, NOT_OPERATOR); // TODO add back when AccountHandler is working

        // Offer must not already be voided
        require(!offer.voided, OFFER_ALREADY_VOIDED);
    }

    /**
     * @notice Gets the details about a given offer.
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function getOffer(uint256 _offerId)
    external
    view
    returns(bool exists, Offer memory offer) {
        return fetchOffer(_offerId);
    }

    /**
     * @notice Gets the next offer id.
     *
     * Does not increment the counter.
     *
     * @return nextOfferId - the next offer id
     */
    function getNextOfferId()
    public
    view
    returns(uint256 nextOfferId) {

        nextOfferId = protocolCounters().nextOfferId;

    }

    /**
     * @notice Tells if offer is voided or not
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offerVoided - true if voided, false otherwise
     */
    function isOfferVoided(uint256 _offerId)
    public
    view
    returns(bool exists, bool offerVoided) {
        Offer memory offer;
        (exists, offer) = fetchOffer(_offerId);
        offerVoided = offer.voided;
    }


    /**
     * @notice Tells if offer is can be updated or not
     *
     * Offer is updateable if:
     * - it exists
     * - is not voided
     * - has no exchanges
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offerUpdateable - true if updateable, false otherwise
     */
    function isOfferUpdateable(uint256 _offerId)
    public
    view
    returns(bool exists, bool offerUpdateable)
    {
        // Get the offer
        Offer storage offer;
        (exists, offer) = fetchOffer(_offerId);

        // Offer must exist, not be voided, and have no exchanges to be updateable
        offerUpdateable =
            exists &&
            !offer.voided &&
            (protocolStorage().exchangesByOffer[_offerId].length == 0);
        
    }


    //////////////////////////////
    ///    GROUP MANAGEMENT    ///
    //////////////////////////////

    /**
     * @notice Creates a group.
     *
     * Emits a GroupCreated event if successful.
     *
     * Reverts if:
     * 
     * - seller does not match caller
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different group
     *
     * @param _group - the fully populated struct with group id set to 0x0
     */
    function createGroup(
        Group memory _group
    )
    external
    override
    {
        // TODO: check seller ID matches msg.sender

        // limit maximum number of offers to avoid running into block gas limit in a loop
        require(_group.offerIds.length <= protocolStorage().maxOffersPerGroup, TOO_MANY_OFFERS);

        // Get the next group and increment the counter
        uint256 groupId = protocolCounters().nextGroupId++;

        for (uint i = 0; i < _group.offerIds.length; i++) {
            // make sure all offers exist and belong to the seller
            getValidOffer(_group.offerIds[i]);
            
            // Add to groupByOffer mapping
            require(protocolStorage().groupByOffer[_group.offerIds[i]] == 0, OFFER_MUST_BE_UNIQUE);
            protocolStorage().groupByOffer[_group.offerIds[i]] = groupId;
        }
       
        // Get storage location for group
        (,Group storage group) = fetchGroup(groupId);

        // Set group props individually since memory structs can't be copied to storage
        group.id = groupId;
        group.sellerId = _group.sellerId;
        group.offerIds = _group.offerIds;
        group.condition = _group.condition;

        // modify incoming struct so event value represents true state
        _group.id = groupId; 
      
        // Notify watchers of state change
        emit GroupCreated(groupId, _group.sellerId, _group);
    }

    /**
     * @notice Gets the details about a given group.
     *
     * @param _groupId - the id of the group to check
     * @return exists - the offer was found
     * @return group - the offer details. See {BosonTypes.Group}
     */
    function getGroup(uint256 _groupId)
    external
    view
    returns(bool exists, Group memory group) {
        return fetchGroup(_groupId);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/BosonTypes.sol";

/**
 * @title IBosonOfferHandler
 *
 * @notice Manages creation, voiding, and querying of offers within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0xaf7dd438
 */
interface IBosonOfferHandler {
    /// Events
    event OfferCreated(uint256 indexed offerId, uint256 indexed sellerId, BosonTypes.Offer offer);
    event OfferUpdated(uint256 indexed offerId, uint256 indexed sellerId, BosonTypes.Offer offer);
    event OfferVoided(uint256 indexed offerId, uint256 indexed sellerId);
    event GroupCreated(uint256 indexed groupId, uint256 indexed sellerId, BosonTypes.Group group);

    /**
     * @notice Creates an offer
     *
     * Emits an OfferCreated event if successful.
     *
     * Reverts if:
     * - Valid from date is greater than valid until date
     * - Valid until date is not in the future
     *
     * @param _offer - the fully populated struct with offer id set to 0x0
     */
    function createOffer(BosonTypes.Offer memory _offer) external;

    /**
     * @notice Updates an existing offer.
     *
     * Emits an OfferUpdated event if successful.
     *
     * Reverts if:
     * - Offer is not updateable, i.e. is voided or some exchanges are active
     * - Any other validation for offer creation fails
     *
     * @param _offer - the fully populated struct with offer id set to offer to be updated, active exchanges set to 0 and voided set to false
     */
    function updateOffer(BosonTypes.Offer memory _offer) external;

    /**
     * @notice Voids a given offer
     *
     * Emits an OfferVoided event if successful.
     *
     * Note:
     * Existing exchanges are not affected.
     * No further vouchers can be issued against a voided offer.
     *
     * Reverts if:
     * - Offer ID is invalid
     * - Offer is not owned by caller
     *
     * @param _offerId - the id of the offer to check
     */
    function voidOffer(uint256 _offerId) external;

    /**
     * @notice Sets new valid until date
     *
     * Emits an OfferUpdated event if successful.
     *
     * Reverts if:
     * - Offer does not exist
     * - Caller is not the seller (TODO)
     * - New valid until date is before existing valid until dates
     *
     *  @param _offerId - the id of the offer to check
     *  @param _validUntilDate - new valid until date
     */
    function extendOffer(uint256 _offerId, uint256 _validUntilDate) external;

    /**
     * @notice Gets the details about a given offer.
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function getOffer(uint256 _offerId) external view returns (bool exists, BosonTypes.Offer memory offer);

    /**
     * @notice Gets the next offer id.
     *
     * Does not increment the counter.
     *
     * @return nextOfferId - the next offer id
     */
    function getNextOfferId() external view returns (uint256 nextOfferId);

    /**
     * @notice Tells if offer is voided or not
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offerVoided - true if voided, false otherwise
     */
    function isOfferVoided(uint256 _offerId) external view returns (bool exists, bool offerVoided);

    /**
     * @notice Tells if offer is can be updated or not
     *
     * Offer is updateable if:
     * - it exists
     * - is not voided
     * - has no exchanges
     *
     * @param _offerId - the id of the offer to check
     * @return exists - the offer was found
     * @return offerUpdateable - true if updateable, false otherwise
     */
    function isOfferUpdateable(uint256 _offerId) external view returns (bool exists, bool offerUpdateable);

    /**
     * @notice Creates a group.
     *
     * Emits a GroupCreated event if successful.
     *
     * Reverts if:
     *
     * - seller does not match caller
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different group
     *
     * @param _group - the fully populated struct with group id set to 0x0
     */
    function createGroup(BosonTypes.Group memory _group) external;

    /**
     * @notice Gets the details about a given group.
     *
     * @param _groupId - the id of the group to check
     * @return exists - the offer was found
     * @return group - the offer details. See {BosonTypes.Group}
     */
    function getGroup(uint256 _groupId) external view returns (bool exists, BosonTypes.Group memory group);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces. Also added copious code comments throughout.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactor/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // The Boson Protocol AccessController
        IAccessControlUpgradeable accessController;
    }

    /**
     * @notice Get the Diamond storage slot
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Add a supported interface to the Diamond
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId] || false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ProtocolLib.sol";
import "../diamond/DiamondLib.sol";
import "../domain/BosonTypes.sol";
import "../domain/BosonConstants.sol";

/**
 * @title ProtocolBase
 *
 * @notice Provides domain and common modifiers to Protocol facets
 */
abstract contract ProtocolBase is BosonTypes, BosonConstants {
    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized(bytes4 interfaceId) {
        ProtocolLib.ProtocolInitializers storage pi = protocolInitializers();
        require(!pi.initializedInterfaces[interfaceId], ALREADY_INITIALIZED);
        pi.initializedInterfaces[interfaceId] = true;
        _;
    }

    /**
     * @dev Modifier that checks that an offer exists
     *
     * Reverts if the offer does not exist
     */
    modifier offerExists(uint256 _offerId) {
        // Make sure the offer exists TODO: remove me, not used and not the way to check
        require(_offerId > 0 && _offerId < protocolCounters().nextOfferId, "Offer does not exist");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msg.sender), ACCESS_DENIED);
        _;
    }

    /**
     * @dev Get the Protocol Storage slot
     *
     * @return ps the Protocol Storage slot
     */
    function protocolStorage() internal pure returns (ProtocolLib.ProtocolStorage storage ps) {
        ps = ProtocolLib.protocolStorage();
    }

    /**
     * @dev Get the Protocol Counters slot
     *
     * @return pc the Protocol Counters slot
     */
    function protocolCounters() internal pure returns (ProtocolLib.ProtocolCounters storage pc) {
        pc = ProtocolLib.protocolCounters();
    }

    /**
     * @dev Get the Protocol Initializers slot
     *
     * @return pi the Protocol Initializers slot
     */
    function protocolInitializers() internal pure returns (ProtocolLib.ProtocolInitializers storage pi) {
        pi = ProtocolLib.protocolInitializers();
    }

    /**
     * @notice Fetches a given seller from storage by id
     *
     * @param _sellerId - the id of the seller
     * @return exists - whether the seller exists
     * @return seller - the seller details. See {BosonTypes.Seller}
     */
    function fetchSeller(uint256 _sellerId) internal view returns (bool exists, BosonTypes.Seller storage seller) {
        // Get the seller's slot
        seller = protocolStorage().sellers[_sellerId];

        // Determine existence
        exists = (_sellerId > 0 && seller.id == _sellerId);
    }

    /**
     * @notice Fetches a given offer from storage by id
     *
     * @param _offerId - the id of the offer
     * @return exists - whether the offer exists
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function fetchOffer(uint256 _offerId) internal view returns (bool exists, BosonTypes.Offer storage offer) {
        // Get the offer's slot
        offer = protocolStorage().offers[_offerId];

        // Determine existence
        exists = (_offerId > 0 && offer.id == _offerId);
    }

    /**
     * @notice Fetches a given group from storage by id
     *
     * @param _groupId - the id of the group
     * @return exists - whether the group exists
     * @return group - the group details. See {BosonTypes.Group}
     */
    function fetchGroup(uint256 _groupId) internal view returns (bool exists, BosonTypes.Group storage group) {
        // Get the group's slot
        group = protocolStorage().groups[_groupId];

        // Determine existence
        exists = (group.id > 0 && group.id == _groupId);
    }

    /**
     * @notice Fetches a given exchange from storage by id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether the exchange exists
     * @return exchange - the exchange details. See {BosonTypes.Exchange}
     */
    function fetchExchange(uint256 _exchangeId)
        internal
        view
        returns (bool exists, BosonTypes.Exchange storage exchange)
    {
        // Get the exchange's slot
        exchange = protocolStorage().exchanges[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && exchange.id == _exchangeId);
    }

    /**
     * @notice Fetches a given twin from storage by id
     *
     * @param _twinId - the id of the twin
     * @return exists - whether the twin exists
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function fetchTwin(uint256 _twinId) internal view returns (bool exists, BosonTypes.Twin storage twin) {
        // Get the twin's slot
        twin = protocolStorage().twins[_twinId];

        // Determine existence
        exists = (_twinId > 0 && twin.id == _twinId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../domain/BosonTypes.sol";

/**
 * @title ProtocolLib
 *
 * @dev Provides access to the Protocol Storage, Counters, and Initializer slots for Facets
 */
library ProtocolLib {
    bytes32 internal constant PROTOCOL_STORAGE_POSITION = keccak256("boson.protocol.storage");
    bytes32 internal constant PROTOCOL_COUNTERS_POSITION = keccak256("boson.protocol.counters");
    bytes32 internal constant PROTOCOL_INITIALIZERS_POSITION = keccak256("boson.protocol.initializers");

    // Shared storage for all protocol facets
    struct ProtocolStorage {
        // Address of the Boson Protocol treasury
        address payable treasuryAddress;
        // Address of the Boson Token (ERC-20 contract)
        address payable tokenAddress;
        // Address of the Boson Protocol Voucher proxy
        address voucherAddress;
        // Percentage that will be taken as a fee from the net of a Boson Protocol exchange
        uint16 protocolFeePercentage; // 1.75% = 175, 100% = 10000
        // limit how many offers can be added to the group
        uint16 maxOffersPerGroup;
        // offer id => offer
        mapping(uint256 => BosonTypes.Offer) offers;
        // exchange id => exchange
        mapping(uint256 => BosonTypes.Exchange) exchanges;
        // exchange id => dispute
        mapping(uint256 => BosonTypes.Dispute) disputes;
        // seller id => seller
        mapping(uint256 => BosonTypes.Seller) sellers;
        //seller operator address => sellerId
        mapping(address => uint256) sellerByOperator;
        //seller admin address => sellerId
        mapping(address => uint256) sellerByAdmin;
        //seller clerk address => sellerId
        mapping(address => uint256) sellerByClerk;
        // buyer id => buyer
        mapping(uint256 => BosonTypes.Buyer) buyers;
        // group id => group
        mapping(uint256 => BosonTypes.Group) groups;
        // bundle id => bundle
        mapping(uint256 => BosonTypes.Bundle) bundles;
        // twin id => twin
        mapping(uint256 => BosonTypes.Twin) twins;
        // offer id => exchange ids
        mapping(uint256 => uint256[]) exchangesByOffer;
        // offer id => group id
        mapping(uint256 => uint256) groupByOffer;
    }

    // Incrementing ID counters
    struct ProtocolCounters {
        // Next account id
        uint256 nextAccountId;
        // Next offer id
        uint256 nextOfferId;
        // Next exchange id
        uint256 nextExchangeId;
        // Next twin id
        uint256 nextTwinId;
        // Next group id
        uint256 nextGroupId;
        // Next twin id
        uint256 nextBundleId;
    }

    // Individual facet initialization states
    struct ProtocolInitializers {
        // interface id => initialized?
        mapping(bytes4 => bool) initializedInterfaces;
    }

    /**
     * @dev Get the protocol storage slot
     *
     * @return ps the the protocol storage slot
     */
    function protocolStorage() internal pure returns (ProtocolStorage storage ps) {
        bytes32 position = PROTOCOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    /**
     * @dev Get the protocol counters slot
     *
     * @return pc the the protocol counters slot
     */
    function protocolCounters() internal pure returns (ProtocolCounters storage pc) {
        bytes32 position = PROTOCOL_COUNTERS_POSITION;
        assembly {
            pc.slot := position
        }
    }

    /**
     * @dev Get the protocol initializers slot
     *
     * @return pi the the protocol initializers slot
     */
    function protocolInitializers() internal pure returns (ProtocolInitializers storage pi) {
        bytes32 position = PROTOCOL_INITIALIZERS_POSITION;
        assembly {
            pi.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */
contract BosonTypes {
    enum EvaluationMethod {
        None,
        AboveThreshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed
    }

    enum DisputeState {
        Disputed,
        Retracted,
        Resolved,
        Escalated,
        Decided
    }

    struct Seller {
        uint256 id;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        bool active;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct Resolver {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        uint256 validFromDate;
        uint256 validUntilDate;
        uint256 redeemableFromDate;
        uint256 fulfillmentPeriodDuration;
        uint256 voucherValidDuration;
        address exchangeToken;
        string metadataUri;
        string metadataHash;
        bool voided;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        Condition condition;
    }

    struct Condition {
        EvaluationMethod method;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        Voucher voucher;
        uint256 committedDate;
        uint256 redeemedDate;
        bool disputed;
        ExchangeState state;
    }

    struct Voucher {
        uint256 exchangeId;
        uint256 committedDate;
        uint256 redeemedDate;
    }

    struct Dispute {
        uint256 exchangeId;
        string complaint;
        DisputeState state;
        Resolution resolution;
    }

    struct Resolution {
        uint256 buyerPercent;
    }

    struct Receipt {
        Offer offer;
        Exchange exchange;
        Dispute dispute;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 supplyAvailable; // ERC-1155 / ERC-20
        uint256[] supplyIds; // ERC-721
        uint256 tokenId; // ERC-1155
        address tokenAddress; // all
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IDiamondCut
 *
 * @notice Diamond Facet management
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and
     * optionally execute a function with delegatecall
     *
     * _calldata is executed with delegatecall on _init
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonConstants
 *
 * @notice Constants used by the Boson Protocol contract ecosystem.
 */
contract BosonConstants {
    // Access Control Roles
    bytes32 internal constant ADMIN = keccak256("ADMIN"); // Role Admin
    bytes32 internal constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
    bytes32 internal constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
    bytes32 internal constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
    bytes32 internal constant RESOLVER = keccak256("RESOLVER"); // Role for resolving the outcome of an escalated dispute
    bytes32 internal constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

    //Revert Reasons: General
    string internal constant INVALID_ADDRESS = "Invalid address";

    // Revert Reasons: Facet initializer related
    string internal constant ALREADY_INITIALIZED = "Already initialized";

    // Revert Reasons: Access related
    string internal constant ACCESS_DENIED = "Access denied, caller doesn't have role";
    string internal constant NOT_OPERATOR = "Not seller's operator";

    //Revert Reasons: Seller-related
    string internal constant SELLER_MUST_BE_ACTIVE = "Seller must be active";
    string internal constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";

    // Revert Reasons: Offer related
    string internal constant NO_SUCH_OFFER = "No such offer";
    string internal constant OFFER_ALREADY_VOIDED = "Offer already voided";
    string internal constant OFFER_PERIOD_INVALID = "Offer period invalid";
    string internal constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
    string internal constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
    string internal constant OFFER_NOT_UPDATEABLE = "Offer not updateable";
    string internal constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
    string internal constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";

    // Revert Reasons: Exchange related
    string internal constant NO_SUCH_EXCHANGE = "No such exchange";

    // Revert Reasons: Twin related
    string internal constant NO_TRANSFER_APPROVED = "No transfer approved";
    string internal constant UNSUPPORTED_TOKEN = "Unsupported token";
}