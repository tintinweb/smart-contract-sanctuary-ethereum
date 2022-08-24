// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBosonTwinHandler } from "../../interfaces/handlers/IBosonTwinHandler.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";
import { TwinBase } from "../bases/TwinBase.sol";
import "../../domain/BosonConstants.sol";

/**
 * @title TwinHandlerFacet
 *
 * @notice Manages digital twinning associated with exchanges within the protocol
 */
contract TwinHandlerFacet is IBosonTwinHandler, TwinBase {
    /**
     * @notice Facet Initializer
     */
    function initialize() public onlyUnInitialized(type(IBosonTwinHandler).interfaceId) {
        DiamondLib.addSupportedInterface(type(IBosonTwinHandler).interfaceId);
    }

    /**
     * @notice Creates a Twin.
     *
     * Emits a TwinCreated event if successful.
     *
     * Reverts if:
     * - seller does not exist
     * - Not approved to transfer the seller's token
     * - supplyAvailable is zero
     * - Twin is NonFungibleToken and amount was set
     * - Twin is NonFungibleToken and range is already being used in another twin of the seller
     * - Twin is FungibleToken or MultiToken and amount was not set
     *
     * @param _twin - the fully populated struct with twin id set to 0x0
     */
    function createTwin(Twin memory _twin) external override {
        createTwinInternal(_twin);
    }

    /**
     * @notice Gets the details about a given twin.
     *
     * @param _twinId - the id of the twin to check
     * @return exists - the twin was found
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function getTwin(uint256 _twinId) external view override returns (bool exists, Twin memory twin) {
        return fetchTwin(_twinId);
    }

    /**
     * @notice Gets the next twin id.
     *
     * Does not increment the counter.
     *
     * @return nextTwinId - the next twin id
     */
    function getNextTwinId() public view override returns (uint256 nextTwinId) {
        nextTwinId = protocolCounters().nextTwinId;
    }

    /**
     * @notice Removes the twin.
     *
     * Emits a TwinDeleted event if successful.
     *
     * Reverts if:
     * - caller is not the seller.
     * - Twin does not exist.
     * - Bundle for twin exists
     *
     * @param _twinId - the id of the twin to check.
     */
    function removeTwin(uint256 _twinId) external override {
        // Get storage location for twin
        (bool exists, Twin memory twin) = fetchTwin(_twinId);
        require(exists, NO_SUCH_TWIN);

        // Get seller id
        (, uint256 sellerId) = getSellerIdByOperator(msgSender());
        // Caller's seller id must match twin seller id
        require(sellerId == twin.sellerId, NOT_OPERATOR);

        // Check if there are bundles for this twin
        (bool bundleForTwinExist, ) = fetchBundleIdByTwin(_twinId);
        require(!bundleForTwinExist, BUNDLE_FOR_TWIN_EXISTS);

        // delete struct
        delete protocolEntities().twins[_twinId];

        // Also remove from twinRangesBySeller mapping
        if (twin.tokenType == TokenType.NonFungibleToken) {
            TokenRange[] storage twinRanges = protocolLookups().twinRangesBySeller[sellerId][twin.tokenAddress];
            for (uint256 index = 0; index < twinRanges.length; index++) {
                if (twinRanges[index].start == twin.tokenId) {
                    twinRanges[index] = twinRanges[twinRanges.length - 1];
                    twinRanges.pop();
                    break;
                }
            }
        }

        emit TwinDeleted(_twinId, twin.sellerId, msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { BosonTypes } from "../../domain/BosonTypes.sol";
import { IBosonTwinEvents } from "../events/IBosonTwinEvents.sol";

/**
 * @title IBosonTwinHandler
 *
 * @notice Handles creation, removal, and querying of twins within the protocol.
 *
 * The ERC-165 identifier for this interface is: 0x44f98e5d
 */
interface IBosonTwinHandler is IBosonTwinEvents {
    /**
     * @notice Creates a Twin
     *
     * Emits a TwinCreated event if successful.
     *
     * Reverts if:
     * - seller does not exist
     * - Not approved to transfer the seller's token
     *
     * @param _twin - the fully populated struct with twin id set to 0x0
     */
    function createTwin(BosonTypes.Twin memory _twin) external;

    /**
     * @notice Gets the details about a given twin.
     *
     * @param _twinId - the id of the twin to check
     * @return exists - the twin was found
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function getTwin(uint256 _twinId) external view returns (bool exists, BosonTypes.Twin memory twin);

    /**
     * @notice Gets the next twin id.
     *
     * Does not increment the counter.
     *
     * @return nextTwinId - the next twin id
     */
    function getNextTwinId() external view returns (uint256 nextTwinId);

    /**
     * @notice Removes the twin.
     *
     * Emits a TwinDeleted event if successful.
     *
     * Reverts if:
     * - caller is not the seller.
     * - Twin does not exist.
     * - Twin has bundles.
     *
     * @param _twinId - the id of the twin to check.
     */
    function removeTwin(uint256 _twinId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../interfaces/diamond/IDiamondCut.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title ProtocolLib
 *
 * @dev Provides access to the Protocol Storage, Counters, and Initializer slots for Facets
 */
library ProtocolLib {
    bytes32 internal constant PROTOCOL_ADDRESSES_POSITION = keccak256("boson.protocol.addresses");
    bytes32 internal constant PROTOCOL_LIMITS_POSITION = keccak256("boson.protocol.limits");
    bytes32 internal constant PROTOCOL_ENTITIES_POSITION = keccak256("boson.protocol.entities");
    bytes32 internal constant PROTOCOL_LOOKUPS_POSITION = keccak256("boson.protocol.lookups");
    bytes32 internal constant PROTOCOL_FEES_POSITION = keccak256("boson.protocol.fees");
    bytes32 internal constant PROTOCOL_COUNTERS_POSITION = keccak256("boson.protocol.counters");
    bytes32 internal constant PROTOCOL_INITIALIZERS_POSITION = keccak256("boson.protocol.initializers");
    bytes32 internal constant PROTOCOL_META_TX_POSITION = keccak256("boson.protocol.metaTransactions");

    // Protocol addresses storage
    struct ProtocolAddresses {
        // Address of the Boson Protocol treasury
        address payable treasuryAddress;
        // Address of the Boson Token (ERC-20 contract)
        address payable tokenAddress;
        // Address of the Boson Protocol Voucher beacon
        address voucherBeaconAddress;
        // Address of the Boson Beacon proxy implementation
        address beaconProxyAddress;
    }

    // Protocol limits storage
    struct ProtocolLimits {
        // limit how many exchanges can be processed in single batch transaction
        uint16 maxExchangesPerBatch;
        // limit how many offers can be added to the group
        uint16 maxOffersPerGroup;
        // limit how many offers can be added to the bundle
        uint16 maxOffersPerBundle;
        // limit how many twins can be added to the bundle
        uint16 maxTwinsPerBundle;
        // limit how many offers can be processed in single batch transaction
        uint16 maxOffersPerBatch;
        // limit how many different tokens can be withdrawn in a single transaction
        uint16 maxTokensPerWithdrawal;
        // limit how many dispute resolver fee structs can be processed in a single transaction
        uint16 maxFeesPerDisputeResolver;
        // limit on the escalation response period that a dispute resolver can specify
        uint256 maxEscalationResponsePeriod;
        // limit how many disputes can be processed in single batch transaction
        uint16 maxDisputesPerBatch;
        // limit how many sellers can be added to or removed from an allow list in a single transaction
        uint16 maxAllowedSellers;
        // limit the sum of (Protocol Fee percentage + Agent Fee perpercentagecent) of an offer fee
        uint16 maxTotalOfferFeePercentage;
    }

    // Protocol fees storage
    struct ProtocolFees {
        // Percentage that will be taken as a fee from the net of a Boson Protocol exchange
        uint16 percentage; // 1.75% = 175, 100% = 10000
        // Flat fee taken for exchanges in $BOSON
        uint256 flatBoson;
    }

    // Protocol entities storage
    struct ProtocolEntities {
        // offer id => offer
        mapping(uint256 => BosonTypes.Offer) offers;
        // offer id => offer dates
        mapping(uint256 => BosonTypes.OfferDates) offerDates;
        // offer id => offer fees
        mapping(uint256 => BosonTypes.OfferFees) offerFees;
        // offer id => offer durations
        mapping(uint256 => BosonTypes.OfferDurations) offerDurations;
        // offer id => dispute resolution terms
        mapping(uint256 => BosonTypes.DisputeResolutionTerms) disputeResolutionTerms;
        // exchange id => exchange
        mapping(uint256 => BosonTypes.Exchange) exchanges;
        // exchange id => dispute
        mapping(uint256 => BosonTypes.Dispute) disputes;
        // exchange id => dispute dates
        mapping(uint256 => BosonTypes.DisputeDates) disputeDates;
        // seller id => seller
        mapping(uint256 => BosonTypes.Seller) sellers;
        // buyer id => buyer
        mapping(uint256 => BosonTypes.Buyer) buyers;
        // dispute resolver id => dispute resolver
        mapping(uint256 => BosonTypes.DisputeResolver) disputeResolvers;
        // dispute resolver id => dispute resolver fee array
        mapping(uint256 => BosonTypes.DisputeResolverFee[]) disputeResolverFees;
        // agent id => agent
        mapping(uint256 => BosonTypes.Agent) agents;
        // group id => group
        mapping(uint256 => BosonTypes.Group) groups;
        // bundle id => bundle
        mapping(uint256 => BosonTypes.Bundle) bundles;
        // twin id => twin
        mapping(uint256 => BosonTypes.Twin) twins;
        //entity id => auth token
        mapping(uint256 => BosonTypes.AuthToken) authTokens;
    }

    // Protocol lookups storage
    struct ProtocolLookups {
        // offer id => exchange ids
        mapping(uint256 => uint256[]) exchangeIdsByOffer;
        // offer id => bundle id
        mapping(uint256 => uint256) bundleIdByOffer;
        // twin id => bundle id
        mapping(uint256 => uint256) bundleIdByTwin;
        // offer id => group id
        mapping(uint256 => uint256) groupIdByOffer;
        // offer id => agent id
        mapping(uint256 => uint256) agentIdByOffer;
        // seller operator address => sellerId
        mapping(address => uint256) sellerIdByOperator;
        // seller admin address => sellerId
        mapping(address => uint256) sellerIdByAdmin;
        // seller clerk address => sellerId
        mapping(address => uint256) sellerIdByClerk;
        // buyer wallet address => buyerId
        mapping(address => uint256) buyerIdByWallet;
        // dispute resolver operator address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByOperator;
        // dispute resolver admin address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByAdmin;
        // dispute resolver clerk address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByClerk;
        // dispute resolver id to fee token address => index of the token address
        mapping(uint256 => mapping(address => uint256)) disputeResolverFeeTokenIndex;
        // agent wallet address => agentId
        mapping(address => uint256) agentIdByWallet;
        // seller/buyer id => token address => amount
        mapping(uint256 => mapping(address => uint256)) availableFunds;
        // seller/buyer id => all tokens with balance > 0
        mapping(uint256 => address[]) tokenList;
        // seller id => cloneAddress
        mapping(uint256 => address) cloneAddress;
        // buyer id => number of active vouchers
        mapping(uint256 => uint256) voucherCount;
        // buyer address => groupId => commit count (addresses that have committed to conditional offers)
        mapping(address => mapping(uint256 => uint256)) conditionalCommitsByAddress;
        // buyer escalation deposit percentage
        uint16 buyerEscalationDepositPercentage;
        //AuthTokenType => Auth NFT contract address.
        //Would normally be in ProtocolAddresses but can't be because the ProtocolAddresses struct is passed into the initialize function
        mapping(BosonTypes.AuthTokenType => address) authTokenContracts;
        // AuthTokenType => tokenId => sellerId
        mapping(BosonTypes.AuthTokenType => mapping(uint256 => uint256)) sellerIdByAuthToken;
        // seller id => token address (only ERC721) => start and end of token ids range
        mapping(uint256 => mapping(address => BosonTypes.TokenRange[])) twinRangesBySeller;
        // seller id => token address (only ERC721) => twin ids
        mapping(uint256 => mapping(address => uint256[])) twinIdsByTokenAddressAndBySeller;
        // dispute resolver id => list of allowed sellers
        mapping(uint256 => uint256[]) allowedSellers;
        // dispute resolver id => seller id => index of allowed seller in allowedSellers
        mapping(uint256 => mapping(uint256 => uint256)) allowedSellerIndex;
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

    // Storage related to Meta Transactions
    struct ProtocolMetaTxInfo {
        // The current sender address associated with the transaction
        address currentSenderAddress;
        // A flag that tells us whether the current transaction is a meta-transaction or a regular transaction.
        bool isMetaTransaction;
        // The domain Separator of the protocol
        bytes32 domainSeparator;
        // nonce => existance of nonce in the mapping
        mapping(uint256 => bool) usedNonce;
        // map function name to input type
        mapping(string => BosonTypes.MetaTxInputType) inputType;
        // map input type => hash info
        mapping(BosonTypes.MetaTxInputType => BosonTypes.HashInfo) hashInfo;
    }

    // Individual facet initialization states
    struct ProtocolInitializers {
        // interface id => initialized?
        mapping(bytes4 => bool) initializedInterfaces;
    }

    /**
     * @dev Get the protocol addresses slot
     *
     * @return pa the protocol addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolAddresses storage pa) {
        bytes32 position = PROTOCOL_ADDRESSES_POSITION;
        assembly {
            pa.slot := position
        }
    }

    /**
     * @dev Get the protocol limits slot
     *
     * @return pl the protocol limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLimits storage pl) {
        bytes32 position = PROTOCOL_LIMITS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @dev Get the protocol entities slot
     *
     * @return pe the protocol entities slot
     */
    function protocolEntities() internal pure returns (ProtocolEntities storage pe) {
        bytes32 position = PROTOCOL_ENTITIES_POSITION;
        assembly {
            pe.slot := position
        }
    }

    /**
     * @dev Get the protocol lookups slot
     *
     * @return pl the protocol lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLookups storage pl) {
        bytes32 position = PROTOCOL_LOOKUPS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @dev Get the protocol fees slot
     *
     * @return pf the protocol fees slot
     */
    function protocolFees() internal pure returns (ProtocolFees storage pf) {
        bytes32 position = PROTOCOL_FEES_POSITION;
        assembly {
            pf.slot := position
        }
    }

    /**
     * @dev Get the protocol counters slot
     *
     * @return pc the protocol counters slot
     */
    function protocolCounters() internal pure returns (ProtocolCounters storage pc) {
        bytes32 position = PROTOCOL_COUNTERS_POSITION;
        assembly {
            pc.slot := position
        }
    }

    /**
     * @dev Get the protocol meta-transactions storage slot
     *
     * @return pmti the protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolMetaTxInfo storage pmti) {
        bytes32 position = PROTOCOL_META_TX_POSITION;
        assembly {
            pmti.slot := position
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../domain/BosonConstants.sol";
import { IBosonTwinEvents } from "../../interfaces/events/IBosonTwinEvents.sol";
import { ITwinToken } from "../../interfaces/ITwinToken.sol";
import { ProtocolBase } from "./../bases/ProtocolBase.sol";
import { ProtocolLib } from "./../libs/ProtocolLib.sol";

/**
 * @title TwinBase
 *
 * @dev Provides methods for twin creation that can be shared accross facets
 */
contract TwinBase is ProtocolBase, IBosonTwinEvents {
    /**
     * @notice Creates a Twin.
     *
     * Emits a TwinCreated event if successful.
     *
     * Reverts if:
     * - seller does not exist
     * - Not approved to transfer the seller's token
     * - supplyAvailable is zero
     * - Twin is NonFungibleToken and amount was set
     * - Twin is NonFungibleToken and range is already being used in another twin of the seller
     * - Twin is FungibleToken or MultiToken and amount was not set
     *
     * @param _twin - the fully populated struct with twin id set to 0x0
     */
    function createTwinInternal(Twin memory _twin) internal {
        // get seller id, make sure it exists and store it to incoming struct
        (bool exists, uint256 sellerId) = getSellerIdByOperator(msgSender());
        require(exists, NOT_OPERATOR);

        // Protocol must be approved to transfer seller’s tokens
        require(isProtocolApproved(_twin.tokenAddress, msgSender(), address(this)), NO_TRANSFER_APPROVED);

        // Twin supply must exist and can't be zero
        require(_twin.supplyAvailable > 0, INVALID_SUPPLY_AVAILABLE);

        if (_twin.tokenType == TokenType.NonFungibleToken) {
            // Check if the token supports IERC721 interface
            require(contractSupportsInterface(_twin.tokenAddress, 0x80ac58cd), INVALID_TOKEN_ADDRESS);

            // If token is NonFungible amount should be zero
            require(_twin.amount == 0, INVALID_TWIN_PROPERTY);

            // Calculate new twin range [tokenId...lastTokenId]
            uint256 tokenId = _twin.tokenId;
            uint256 lastTokenId = tokenId + _twin.supplyAvailable - 1;
            require(lastTokenId >= tokenId, INVALID_TWIN_TOKEN_RANGE);

            // Get all seller twin ids that belong to the same token address of the new twin to validate if they have not unlimited supply since ranges can overlaps each other
            uint256[] storage twinIds = protocolLookups().twinIdsByTokenAddressAndBySeller[sellerId][
                _twin.tokenAddress
            ];

            for (uint256 i = 0; i < twinIds.length; i++) {
                // Get storage location for looped twin
                (, Twin storage currentTwin) = fetchTwin(twinIds[i]);

                // The protocol cannot allow two twins with unlimited supply and with the same token address because range overlaps with each other
                if (currentTwin.supplyAvailable == type(uint256).max || _twin.supplyAvailable == type(uint256).max) {
                    require(currentTwin.tokenAddress != _twin.tokenAddress, INVALID_TWIN_TOKEN_RANGE);
                }
            }

            // Get all ranges of twins that belong to the seller and to the same token address of the new twin to validate if range is available
            TokenRange[] memory twinRanges = protocolLookups().twinRangesBySeller[sellerId][_twin.tokenAddress];

            // Checks if token range isn't being used in any other twin of seller
            for (uint256 i = 0; i < twinRanges.length; i++) {
                // A valid range has:
                // - the first id of range greater than the last token id (tokenId + initialSupply - 1) of the looped twin or
                // - the last id of range lower than the looped twin tokenId (beginning of range)
                require(tokenId > twinRanges[i].end || lastTokenId < twinRanges[i].start, INVALID_TWIN_TOKEN_RANGE);
            }

            // Add range to twinRangesBySeller mapping
            protocolLookups().twinRangesBySeller[sellerId][_twin.tokenAddress].push(TokenRange(tokenId, lastTokenId));
        } else if (_twin.tokenType == TokenType.MultiToken) {
            // If token is Fungible or MultiToken amount should not be zero
            require(_twin.amount > 0, INVALID_AMOUNT);
            // Not every ERC20 has supportsInterface method so we can't check interface support if token type is NonFungible
            // Check if the token supports IERC1155 interface
            require(contractSupportsInterface(_twin.tokenAddress, 0xd9b67a26), INVALID_TOKEN_ADDRESS);
            // Add twin id to twinIdsByTokenAddressAndBySeller mapping
            protocolLookups().twinIdsByTokenAddressAndBySeller[sellerId][_twin.tokenAddress].push(_twin.id);
        } else {
            // If token is Fungible or MultiToken amount should not be zero
            require(_twin.amount > 0, INVALID_AMOUNT);
        }

        // Get the next twinId and increment the counter
        uint256 twinId = protocolCounters().nextTwinId++;

        // Get storage location for twin
        (, Twin storage twin) = fetchTwin(twinId);

        // Set twin props individually since memory structs can't be copied to storage
        twin.id = _twin.id = twinId;
        twin.sellerId = _twin.sellerId = sellerId;
        twin.supplyAvailable = _twin.supplyAvailable;
        twin.amount = _twin.amount;
        twin.tokenId = _twin.tokenId;
        twin.tokenAddress = _twin.tokenAddress;
        twin.tokenType = _twin.tokenType;

        // Notify watchers of state change
        emit TwinCreated(twinId, sellerId, _twin, msgSender());
    }

    /**
     * @notice Check if the contract supports the correct interface for the selected token type.
     *
     * @param _tokenAddress - the address of the token to check
     * @param _interfaceId - the interface to check for
     * @return true if the contract supports the interface, false otherwise
     */
    function contractSupportsInterface(address _tokenAddress, bytes4 _interfaceId) internal view returns (bool) {
        try ITwinToken(_tokenAddress).supportsInterface(_interfaceId) returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }

    /**
     * @notice Check if protocol is approved to transfer the tokens.
     *
     * @param _tokenAddress - the address of the seller's twin token contract.
     * @param _operator - the seller's operator address.
     * @param _protocol - the protocol address.
     * @return _approved - the approve status.
     */
    function isProtocolApproved(
        address _tokenAddress,
        address _operator,
        address _protocol
    ) internal view returns (bool _approved) {
        require(_tokenAddress != address(0), UNSUPPORTED_TOKEN);

        try ITwinToken(_tokenAddress).allowance(_operator, _protocol) returns (uint256 _allowance) {
            if (_allowance > 0) {
                _approved = true;
            }
        } catch {
            try ITwinToken(_tokenAddress).isApprovedForAll(_operator, _protocol) returns (bool _isApproved) {
                _approved = _isApproved;
            } catch {
                revert(UNSUPPORTED_TOKEN);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Access Control Roles
bytes32 constant ADMIN = keccak256("ADMIN"); // Role Admin
bytes32 constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
bytes32 constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
bytes32 constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
bytes32 constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

// Revert Reasons: General
string constant INVALID_ADDRESS = "Invalid address";
string constant INVALID_STATE = "Invalid state";
string constant ARRAY_LENGTH_MISMATCH = "Array length mismatch";

// Revert Reasons: Facet initializer related
string constant ALREADY_INITIALIZED = "Already initialized";

// Revert Reasons: Access related
string constant ACCESS_DENIED = "Access denied, caller doesn't have role";
string constant NOT_OPERATOR = "Not seller's operator";
string constant NOT_ADMIN = "Not admin";
string constant NOT_BUYER_OR_SELLER = "Not buyer or seller";
string constant NOT_VOUCHER_HOLDER = "Not current voucher holder";
string constant NOT_BUYER_WALLET = "Not buyer's wallet address";
string constant NOT_AGENT_WALLET = "Not agent's wallet address";
string constant NOT_DISPUTE_RESOLVER_OPERATOR = "Not dispute resolver's operator address";

// Revert Reasons: Account-related
string constant NO_SUCH_SELLER = "No such seller";
string constant MUST_BE_ACTIVE = "Account must be active";
string constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
string constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";
string constant DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE = "Dispute Resolver address cannot be assigned to another dispute resolver Id";
string constant AGENT_ADDRESS_MUST_BE_UNIQUE = "Agent address cannot be assigned to another agent Id";
string constant NO_SUCH_BUYER = "No such buyer";
string constant NO_SUCH_AGENT = "No such agent";
string constant WALLET_OWNS_VOUCHERS = "Wallet address owns vouchers";
string constant NO_SUCH_DISPUTE_RESOLVER = "No such dispute resolver";
string constant INVALID_ESCALATION_PERIOD = "Invalid escalation period";
string constant INVALID_AMOUNT_DISPUTE_RESOLVER_FEES = "Dispute resolver fees are not present or exceeds maximum dispute resolver fees in a single transaction";
string constant DUPLICATE_DISPUTE_RESOLVER_FEES = "Duplicate dispute resolver fee";
string constant DISPUTE_RESOLVER_FEE_NOT_FOUND = "Dispute resolver fee not found";
string constant SELLER_ALREADY_APPROVED = "Seller id is approved already";
string constant SELLER_NOT_APPROVED = "Seller id is not approved";
string constant INVALID_AMOUNT_ALLOWED_SELLERS = "Allowed sellers not present or exceeds maximum allowed sellers in a single transaction";
string constant INVALID_AUTH_TOKEN_TYPE = "Invalid AuthTokenType";
string constant ADMIN_OR_AUTH_TOKEN = "An admin address or an auth token is required";
string constant AUTH_TOKEN_MUST_BE_UNIQUE = "Auth token cannot be assigned to another entity of the same type";

// Revert Reasons: Offer related
string constant NO_SUCH_OFFER = "No such offer";
string constant OFFER_PERIOD_INVALID = "Offer period invalid";
string constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
string constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
string constant OFFER_NOT_UPDATEABLE = "Offer not updateable";
string constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
string constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
string constant OFFER_HAS_EXPIRED = "Offer has expired";
string constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
string constant OFFER_SOLD_OUT = "Offer has sold out";
string constant CANNOT_COMMIT = "Caller cannot commit";
string constant EXCHANGE_FOR_OFFER_EXISTS = "Exchange for offer exists";
string constant AMBIGUOUS_VOUCHER_EXPIRY = "Exactly one of voucherRedeemableUntil and voucherValid must be non zero";
string constant REDEMPTION_PERIOD_INVALID = "Redemption period invalid";
string constant INVALID_FULFILLMENT_PERIOD = "Invalid fulfillemnt period";
string constant INVALID_DISPUTE_DURATION = "Invalid dispute duration";
string constant INVALID_DISPUTE_RESOLVER = "Invalid dispute resolver";
string constant INVALID_QUANTITY_AVAILABLE = "Invalid quantity available";
string constant DR_UNSUPPORTED_FEE = "Dispute resolver does not accept this token";
string constant AGENT_FEE_AMOUNT_TOO_HIGH = "Sum of Agent fee amount and protocol fee amount should be <= offer fee limit";

// Revert Reasons: Group related
string constant NO_SUCH_GROUP = "No such group";
string constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
string constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
string constant NOTHING_UPDATED = "Nothing updated";
string constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

// Revert Reasons: Exchange related
string constant NO_SUCH_EXCHANGE = "No such exchange";
string constant FULFILLMENT_PERIOD_NOT_ELAPSED = "Fulfillment period has not yet elapsed";
string constant VOUCHER_NOT_REDEEMABLE = "Voucher not yet valid or already expired";
string constant VOUCHER_EXTENSION_NOT_VALID = "Proposed date is not later than the current one";
string constant VOUCHER_STILL_VALID = "Voucher still valid";
string constant VOUCHER_HAS_EXPIRED = "Voucher has expired";
string constant TOO_MANY_EXCHANGES = "Exceeded maximum exchanges in a single transaction";

// Revert Reasons: Twin related
string constant NO_SUCH_TWIN = "No such twin";
string constant NO_TRANSFER_APPROVED = "No transfer approved";
string constant TWIN_TRANSFER_FAILED = "Twin could not be transferred";
string constant UNSUPPORTED_TOKEN = "Unsupported token";
string constant BUNDLE_FOR_TWIN_EXISTS = "Bundle for twin exists";
string constant INVALID_SUPPLY_AVAILABLE = "supplyAvailable can't be zero";
string constant INVALID_AMOUNT = "Amount must be greater than zero if token is ERC20 or ERC1155";
string constant INVALID_TWIN_PROPERTY = "Invalid property for selected token type";
string constant INVALID_TWIN_TOKEN_RANGE = "Token range is already being used in another Twin";
string constant INVALID_TOKEN_ADDRESS = "Token address is a contract that doesn't implement the interface for selected token type";

// Revert Reasons: Bundle related
string constant NO_SUCH_BUNDLE = "No such bundle";
string constant TWIN_NOT_IN_BUNDLE = "Twin not part of the bundle";
string constant OFFER_NOT_IN_BUNDLE = "Offer not part of the bundle";
string constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
string constant BUNDLE_OFFER_MUST_BE_UNIQUE = "Offer must be unique to a bundle";
string constant BUNDLE_TWIN_MUST_BE_UNIQUE = "Twin must be unique to a bundle";
string constant EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS = "Exchange for the bundled offers exists";
string constant INSUFFICIENT_TWIN_SUPPLY_TO_COVER_BUNDLE_OFFERS = "Insufficient twin supplyAvailable to cover total quantity of bundle offers";

// Revert Reasons: Funds related
string constant NATIVE_WRONG_ADDRESS = "Native token address must be 0";
string constant NATIVE_WRONG_AMOUNT = "Transferred value must match amount";
string constant TOKEN_NAME_UNSPECIFIED = "Token name unspecified";
string constant NATIVE_CURRENCY = "Native currency";
string constant TOO_MANY_TOKENS = "Too many tokens";
string constant TOKEN_AMOUNT_MISMATCH = "Number of amounts should match number of tokens";
string constant NOTHING_TO_WITHDRAW = "Nothing to withdraw";
string constant NOT_AUTHORIZED = "Not authorized to withdraw";
string constant TOKEN_TRANSFER_FAILED = "Token transfer failed";
string constant INSUFFICIENT_VALUE_SENT = "Insufficient value sent";
string constant INSUFFICIENT_AVAILABLE_FUNDS = "Insufficient available funds";
string constant NATIVE_NOT_ALLOWED = "Transfer of native currency not allowed";

// Revert Reasons: Meta-Transactions related
string constant NONCE_USED_ALREADY = "Nonce used already";
string constant FUNCTION_CALL_NOT_SUCCESSFUL = "Function call not successful";
string constant INVALID_FUNCTION_SIGNATURE = "functionSignature can not be of executeMetaTransaction method";
string constant SIGNER_AND_SIGNATURE_DO_NOT_MATCH = "Signer and signature do not match";
string constant INVALID_FUNCTION_NAME = "Invalid function name";
string constant INVALID_SIGNATURE = "Invalid signature";

// Revert Reasons: Dispute related
string constant COMPLAINT_MISSING = "Complaint missing";
string constant FULFILLMENT_PERIOD_HAS_ELAPSED = "Fulfillment period has already elapsed";
string constant DISPUTE_HAS_EXPIRED = "Dispute has expired";
string constant INVALID_BUYER_PERCENT = "Invalid buyer percent";
string constant DISPUTE_STILL_VALID = "Dispute still valid";
string constant INVALID_DISPUTE_TIMEOUT = "Invalid dispute timeout";
string constant TOO_MANY_DISPUTES = "Exceeded maximum disputes in a single transaction";
string constant ESCALATION_NOT_ALLOWED = "Disputes without dispute resolver cannot be escalated";

// Revert Reasons: Config related
string constant FEE_PERCENTAGE_INVALID = "Percentage representation must be less than 10000";

// EIP712Lib
bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
);

// BosonVoucher
string constant VOUCHER_NAME = "Boson Voucher";
string constant VOUCHER_SYMBOL = "BOSON_VOUCHER";

// Meta Transations - Structs
bytes32 constant META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
        "MetaTransaction(uint256 nonce,address from,address contractAddress,string functionName,bytes functionSignature)"
    )
);
bytes32 constant OFFER_DETAILS_TYPEHASH = keccak256("MetaTxOfferDetails(address buyer,uint256 offerId)");
bytes32 constant META_TX_COMMIT_TO_OFFER_TYPEHASH = keccak256(
    "MetaTxCommitToOffer(uint256 nonce,address from,address contractAddress,string functionName,MetaTxOfferDetails offerDetails)MetaTxOfferDetails(address buyer,uint256 offerId)"
);
bytes32 constant EXCHANGE_DETAILS_TYPEHASH = keccak256("MetaTxExchangeDetails(uint256 exchangeId)");
bytes32 constant META_TX_EXCHANGE_TYPEHASH = keccak256(
    "MetaTxExchange(uint256 nonce,address from,address contractAddress,string functionName,MetaTxExchangeDetails exchangeDetails)MetaTxExchangeDetails(uint256 exchangeId)"
);
bytes32 constant FUND_DETAILS_TYPEHASH = keccak256(
    "MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant META_TX_FUNDS_TYPEHASH = keccak256(
    "MetaTxFund(uint256 nonce,address from,address contractAddress,string functionName,MetaTxFundDetails fundDetails)MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant DISPUTE_DETAILS_TYPEHASH = keccak256("MetaTxDisputeDetails(uint256 exchangeId,string complaint)");
bytes32 constant META_TX_DISPUTES_TYPEHASH = keccak256(
    "MetaTxDispute(uint256 nonce,address from,address contractAddress,string functionName,MetaTxDisputeDetails disputeDetails)MetaTxDisputeDetails(uint256 exchangeId,string complaint)"
);
bytes32 constant DISPUTE_RESOLUTION_DETAILS_TYPEHASH = keccak256(
    "MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercent,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);
bytes32 constant META_TX_DISPUTE_RESOLUTIONS_TYPEHASH = keccak256(
    "MetaTxDisputeResolution(uint256 nonce,address from,address contractAddress,string functionName,MetaTxDisputeResolutionDetails disputeResolutionDetails)MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercent,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);

// Function names
string constant COMMIT_TO_OFFER = "commitToOffer(address,uint256)";
string constant CANCEL_VOUCHER = "cancelVoucher(uint256)";
string constant REDEEM_VOUCHER = "redeemVoucher(uint256)";
string constant COMPLETE_EXCHANGE = "completeExchange(uint256)";
string constant WITHDRAW_FUNDS = "withdrawFunds(uint256,address[],uint256[])";
string constant RETRACT_DISPUTE = "retractDispute(uint256)";
string constant RAISE_DISPUTE = "raiseDispute(uint256,string)";
string constant ESCALATE_DISPUTE = "escalateDispute(uint256)";
string constant RESOLVE_DISPUTE = "resolveDispute(uint256,uint256,bytes32,bytes32,uint8)";

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
        Threshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed,
        Disputed
    }

    enum DisputeState {
        Resolving,
        Retracted,
        Resolved,
        Escalated,
        Decided,
        Refused
    }

    enum TokenType {
        FungibleToken,
        NonFungibleToken,
        MultiToken
    } // ERC20, ERC721, ERC1155

    enum MetaTxInputType {
        Generic,
        CommitToOffer,
        Exchange,
        Funds,
        RaiseDispute,
        ResolveDispute
    }

    enum AuthTokenType {
        None,
        Lens,
        ENS
    }

    struct AuthToken {
        uint256 tokenId;
        AuthTokenType tokenType;
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

    struct DisputeResolver {
        uint256 id;
        uint256 escalationResponsePeriod;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        string metadataUri;
        bool active;
    }

    struct DisputeResolverFee {
        address tokenAddress;
        string tokenName;
        uint256 feeAmount;
    }

    struct Agent {
        uint256 id;
        uint256 feePercentage;
        address payable wallet;
        bool active;
    }

    struct DisputeResolutionTerms {
        uint256 disputeResolverId;
        uint256 escalationResponsePeriod;
        uint256 feeAmount;
        uint256 buyerEscalationDeposit;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        string metadataUri;
        string metadataHash;
        bool voided;
    }

    struct OfferDates {
        uint256 validFrom;
        uint256 validUntil;
        uint256 voucherRedeemableFrom;
        uint256 voucherRedeemableUntil;
    }

    struct OfferDurations {
        uint256 fulfillmentPeriod;
        uint256 voucherValid;
        uint256 resolutionPeriod;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        Condition condition;
    }

    struct Condition {
        EvaluationMethod method;
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
        uint256 maxCommits;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        Voucher voucher;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        string complaint;
        DisputeState state;
        uint256 buyerPercent;
    }

    struct DisputeDates {
        uint256 disputed;
        uint256 escalated;
        uint256 finalized;
        uint256 timeout;
    }

    struct Receipt {
        Offer offer;
        Exchange exchange;
        Dispute dispute;
    }

    struct TokenRange {
        uint256 start;
        uint256 end;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 amount; // ERC-1155 / ERC-20 (amount to be transferred to each buyer on redemption)
        uint256 supplyAvailable; // all
        uint256 tokenId; // ERC-1155 / ERC-721 (must be initialized with the initial pointer position of the ERC-721 ids available range)
        address tokenAddress; // all
        TokenType tokenType;
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }

    struct Funds {
        address tokenAddress;
        string tokenName;
        uint256 availableAmount;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        bytes functionSignature;
    }

    struct HashInfo {
        bytes32 typeHash;
        function(bytes memory) internal pure returns (bytes32) hashFunction;
    }

    struct OfferFees {
        uint256 protocolFee;
        uint256 agentFee;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonTwinEvents
 *
 * @notice Events related to management of twins within the protocol.
 */
interface IBosonTwinEvents {
    event TwinCreated(
        uint256 indexed twinId,
        uint256 indexed sellerId,
        BosonTypes.Twin twin,
        address indexed executedBy
    );
    event TwinDeleted(uint256 indexed twinId, uint256 indexed sellerId, address indexed executedBy);
    // Amount must be 0 if token type is TokenType.NonFungible
    // tokenId must be 0 if token type is TokenType.Fungible
    event TwinTransferred(
        uint256 indexed twinId,
        address indexed tokenAddress,
        uint256 indexed exchangeId,
        uint256 tokenId,
        uint256 amount,
        address executedBy
    );
    event TwinTransferFailed(
        uint256 indexed twinId,
        address indexed tokenAddress,
        uint256 indexed exchangeId,
        uint256 tokenId,
        uint256 amount,
        address executedBy
    );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @title ITwinToken
 *
 * @notice The minimum interface a Twin token must expose to be supported by the Boson Protocol
 */
interface ITwinToken is IERC165 {
    /**
     * @notice Returns true if the `operator` is allowed to manage the assets of `owner`.
     *
     * @param _owner - the token owner address.
     * @param _operator - the operator address.
     * @return _isApproved - the approval was found.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool _isApproved);

    /**
     * @notice Returns the remaining number of tokens that `_operator` will be
     * allowed to spend on behalf of `_owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     *
     * @param _owner - the owner address
     * @param _operator - the operator address
     * @return The remaining amount allowed
     */
    function allowance(address _owner, address _operator) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";
import { EIP712Lib } from "../libs/EIP712Lib.sol";

/**
 * @title ProtocolBase
 *
 * @notice Provides domain and common modifiers to Protocol facets
 */
abstract contract ProtocolBase is BosonTypes {
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
        require(ds.accessController.hasRole(_role, msgSender()), ACCESS_DENIED);
        _;
    }

    /**
     * @dev Get the Protocol Addresses slot
     *
     * @return pa the Protocol Addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolLib.ProtocolAddresses storage pa) {
        pa = ProtocolLib.protocolAddresses();
    }

    /**
     * @dev Get the Protocol Limits slot
     *
     * @return pl the Protocol Limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLib.ProtocolLimits storage pl) {
        pl = ProtocolLib.protocolLimits();
    }

    /**
     * @dev Get the Protocol Entities slot
     *
     * @return pe the Protocol Entities slot
     */
    function protocolEntities() internal pure returns (ProtocolLib.ProtocolEntities storage pe) {
        pe = ProtocolLib.protocolEntities();
    }

    /**
     * @dev Get the Protocol Lookups slot
     *
     * @return pl the Protocol Lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLib.ProtocolLookups storage pl) {
        pl = ProtocolLib.protocolLookups();
    }

    /**
     * @dev Get the Protocol Fees slot
     *
     * @return pf the Protocol Fees slot
     */
    function protocolFees() internal pure returns (ProtocolLib.ProtocolFees storage pf) {
        pf = ProtocolLib.protocolFees();
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
     * @dev Get the Protocol meta-transactions storage slot
     *
     * @return pmti the Protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolLib.ProtocolMetaTxInfo storage pmti) {
        pmti = ProtocolLib.protocolMetaTxInfo();
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
     * @notice Gets a seller Id from storage by operator address
     *
     * @param _operator - the operator address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByOperator(address _operator) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByOperator[_operator];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by admin address
     *
     * @param _admin - the admin address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByAdmin(address _admin) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByAdmin[_admin];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by clerk address
     *
     * @param _clerk - the clerk address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByClerk(address _clerk) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByClerk[_clerk];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by auth token.  A seller will have either an admin address or an auth token
     *
     * @param _authToken - the potential _authToken of the seller.
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByAuthToken(AuthToken calldata _authToken)
        internal
        view
        returns (bool exists, uint256 sellerId)
    {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a buyer id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer Id exists
     * @return buyerId  - the buyer Id
     */
    function getBuyerIdByWallet(address _wallet) internal view returns (bool exists, uint256 buyerId) {
        // Get the buyer Id
        buyerId = protocolLookups().buyerIdByWallet[_wallet];

        // Determine existence
        exists = (buyerId > 0);
    }

    /**
     * @notice Gets a agent id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer Id exists
     * @return agentId  - the buyer Id
     */
    function getAgentIdByWallet(address _wallet) internal view returns (bool exists, uint256 agentId) {
        // Get the buyer Id
        agentId = protocolLookups().agentIdByWallet[_wallet];

        // Determine existence
        exists = (agentId > 0);
    }

    /**
     * @notice Gets a dispute resolver Id from storage by operator address
     *
     * @param _operator - the operator address of the dispute resolver
     * @return exists - whether the dispute resolver Id exists
     * @return disputeResolverId  - the dispute resolver  Id
     */
    function getDisputeResolverIdByOperator(address _operator)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver Id
        disputeResolverId = protocolLookups().disputeResolverIdByOperator[_operator];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a dispute resolver Id from storage by admin address
     *
     * @param _admin - the admin address of the dispute resolver
     * @return exists - whether the dispute resolver Id exists
     * @return disputeResolverId  - the dispute resolver Id
     */
    function getDisputeResolverIdByAdmin(address _admin)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver Id
        disputeResolverId = protocolLookups().disputeResolverIdByAdmin[_admin];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a dispute resolver Id from storage by clerk address
     *
     * @param _clerk - the clerk address of the dispute resolver
     * @return exists - whether the dispute resolver Id exists
     * @return disputeResolverId  - the dispute resolver Id
     */
    function getDisputeResolverIdByClerk(address _clerk)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver Id
        disputeResolverId = protocolLookups().disputeResolverIdByClerk[_clerk];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a group id from storage by offer id
     *
     * @param _offerId - the offer id
     * @return exists - whether the group id exists
     * @return groupId  - the group id.
     */
    function getGroupIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 groupId) {
        // Get the group Id
        groupId = protocolLookups().groupIdByOffer[_offerId];

        // Determine existence
        exists = (groupId > 0);
    }

    /**
     * @notice Fetches a given seller from storage by id
     *
     * @param _sellerId - the id of the seller
     * @return exists - whether the seller exists
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     */
    function fetchSeller(uint256 _sellerId)
        internal
        view
        returns (
            bool exists,
            Seller storage seller,
            AuthToken storage authToken
        )
    {
        // Get the seller's slot
        seller = protocolEntities().sellers[_sellerId];

        //Get the seller's auth token's slot
        authToken = protocolEntities().authTokens[_sellerId];

        // Determine existence
        exists = (_sellerId > 0 && seller.id == _sellerId);
    }

    /**
     * @notice Fetches a given buyer from storage by id
     *
     * @param _buyerId - the id of the buyer
     * @return exists - whether the buyer exists
     * @return buyer - the buyer details. See {BosonTypes.Buyer}
     */
    function fetchBuyer(uint256 _buyerId) internal view returns (bool exists, BosonTypes.Buyer storage buyer) {
        // Get the buyer's slot
        buyer = protocolEntities().buyers[_buyerId];

        // Determine existence
        exists = (_buyerId > 0 && buyer.id == _buyerId);
    }

    /**
     * @notice Fetches a given dispute resolver from storage by id
     *
     * @param _disputeResolverId - the id of the dispute resolver
     * @return exists - whether the dispute resolver exists
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     */
    function fetchDisputeResolver(uint256 _disputeResolverId)
        internal
        view
        returns (
            bool exists,
            BosonTypes.DisputeResolver storage disputeResolver,
            BosonTypes.DisputeResolverFee[] storage disputeResolverFees
        )
    {
        // Get the dispute resolver's slot
        disputeResolver = protocolEntities().disputeResolvers[_disputeResolverId];

        //Get dispute resolver's fee list slot
        disputeResolverFees = protocolEntities().disputeResolverFees[_disputeResolverId];

        // Determine existence
        exists = (_disputeResolverId > 0 && disputeResolver.id == _disputeResolverId);
    }

    /**
     * @notice Fetches a given agent from storage by id
     *
     * @param _agentId - the id of the agent
     * @return exists - whether the agent exists
     * @return agent - the agent details. See {BosonTypes.Agent}
     */
    function fetchAgent(uint256 _agentId) internal view returns (bool exists, BosonTypes.Agent storage agent) {
        // Get the agent's slot
        agent = protocolEntities().agents[_agentId];

        // Determine existence
        exists = (_agentId > 0 && agent.id == _agentId);
    }

    /**
     * @notice Fetches a given offer from storage by id
     *
     * @param _offerId - the id of the offer
     * @return exists - whether the offer exists
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function fetchOffer(uint256 _offerId) internal view returns (bool exists, Offer storage offer) {
        // Get the offer's slot
        offer = protocolEntities().offers[_offerId];

        // Determine existence
        exists = (_offerId > 0 && offer.id == _offerId);
    }

    /**
     * @notice Fetches the offer dates from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDates - the offer dates details. See {BosonTypes.OfferDates}
     */
    function fetchOfferDates(uint256 _offerId) internal view returns (BosonTypes.OfferDates storage offerDates) {
        // Get the offerDates's slot
        offerDates = protocolEntities().offerDates[_offerId];
    }

    /**
     * @notice Fetches the offer durations from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDurations - the offer durations details. See {BosonTypes.OfferDurations}
     */
    function fetchOfferDurations(uint256 _offerId)
        internal
        view
        returns (BosonTypes.OfferDurations storage offerDurations)
    {
        // Get the offer's slot
        offerDurations = protocolEntities().offerDurations[_offerId];
    }

    /**
     * @notice Fetches the dispute resolution terms from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return disputeResolutionTerms - the details about the dispute resolution terms. See {BosonTypes.DisputeResolutionTerms}
     */
    function fetchDisputeResolutionTerms(uint256 _offerId)
        internal
        view
        returns (BosonTypes.DisputeResolutionTerms storage disputeResolutionTerms)
    {
        // Get the disputeResolutionTerms's slot
        disputeResolutionTerms = protocolEntities().disputeResolutionTerms[_offerId];
    }

    /**
     * @notice Fetches a given group from storage by id
     *
     * @param _groupId - the id of the group
     * @return exists - whether the group exists
     * @return group - the group details. See {BosonTypes.Group}
     */
    function fetchGroup(uint256 _groupId) internal view returns (bool exists, Group storage group) {
        // Get the group's slot
        group = protocolEntities().groups[_groupId];

        // Determine existence
        exists = (_groupId > 0 && group.id == _groupId);
    }

    /**
     * @notice Fetches a given exchange from storage by id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether the exchange exists
     * @return exchange - the exchange details. See {BosonTypes.Exchange}
     */
    function fetchExchange(uint256 _exchangeId) internal view returns (bool exists, Exchange storage exchange) {
        // Get the exchange's slot
        exchange = protocolEntities().exchanges[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && exchange.id == _exchangeId);
    }

    /**
     * @notice Fetches a given dispute from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange associated with the dispute
     * @return exists - whether the dispute exists
     * @return dispute - the dispute details. See {BosonTypes.Dispute}
     */
    function fetchDispute(uint256 _exchangeId)
        internal
        view
        returns (
            bool exists,
            Dispute storage dispute,
            DisputeDates storage disputeDates
        )
    {
        // Get the dispute's slot
        dispute = protocolEntities().disputes[_exchangeId];

        // Get the disputeDates's slot
        disputeDates = protocolEntities().disputeDates[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && dispute.exchangeId == _exchangeId);
    }

    /**
     * @notice Fetches a given twin from storage by id
     *
     * @param _twinId - the id of the twin
     * @return exists - whether the twin exists
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function fetchTwin(uint256 _twinId) internal view returns (bool exists, Twin storage twin) {
        // Get the twin's slot
        twin = protocolEntities().twins[_twinId];

        // Determine existence
        exists = (_twinId > 0 && twin.id == _twinId);
    }

    /**
     * @notice Fetches a given bundle from storage by id
     *
     * @param _bundleId - the id of the bundle
     * @return exists - whether the bundle exists
     * @return bundle - the bundle details. See {BosonTypes.Bundle}
     */
    function fetchBundle(uint256 _bundleId) internal view returns (bool exists, Bundle storage bundle) {
        // Get the bundle's slot
        bundle = protocolEntities().bundles[_bundleId];

        // Determine existence
        exists = (_bundleId > 0 && bundle.id == _bundleId);
    }

    /**
     * @notice Gets offer from protocol storage, makes sure it exist and not voided
     *
     * Reverts if:
     * - Offer does not exist
     * - Offer already voided
     * - Caller is not the seller
     *
     *  @param _offerId - the id of the offer to check
     */
    function getValidOffer(uint256 _offerId) internal view returns (Offer storage offer) {
        bool exists;
        Seller storage seller;

        // Get offer
        (exists, offer) = fetchOffer(_offerId);

        // Offer must already exist
        require(exists, NO_SUCH_OFFER);

        // Offer must not already be voided
        require(!offer.voided, OFFER_HAS_BEEN_VOIDED);

        // Get seller, we assume seller exists if offer exists
        (, seller, ) = fetchSeller(offer.sellerId);

        // Caller must be seller's operator address
        require(seller.operator == msgSender(), NOT_OPERATOR);
    }

    /**
     * @notice Gets the bundle id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the bundle Id exists
     * @return bundleId  - the bundle Id.
     */
    function fetchBundleIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle Id
        bundleId = protocolLookups().bundleIdByOffer[_offerId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the bundle id for a given twin id.
     *
     * @param _twinId - the twin Id.
     * @return exists - whether the bundle Id exist
     * @return bundleId  - the bundle Id.
     */
    function fetchBundleIdByTwin(uint256 _twinId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle Id
        bundleId = protocolLookups().bundleIdByTwin[_twinId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the exchange ids for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the exchange Ids exist
     * @return exchangeIds  - the exchange Ids.
     */
    function getExchangeIdsByOffer(uint256 _offerId) internal view returns (bool exists, uint256[] memory exchangeIds) {
        // Get the exchange Ids
        exchangeIds = protocolLookups().exchangeIdsByOffer[_offerId];

        // Determine existence
        exists = (exchangeIds.length > 0);
    }

    /**
     * @notice Make sure the caller is buyer associated with the exchange
     *
     * Reverts if
     * - caller is not the buyer associated with exchange
     *
     * @param _currentBuyer - id of current buyer associated with the exchange
     */
    function checkBuyer(uint256 _currentBuyer) internal view {
        // Get the caller's buyer account id
        (, uint256 buyerId) = getBuyerIdByWallet(msgSender());

        // Must be the buyer associated with the exchange (which is always voucher holder)
        require(buyerId == _currentBuyer, NOT_VOUCHER_HOLDER);
    }

    /**
     * @notice Get a valid exchange
     *
     * Reverts if
     * - Exchange does not exist
     * - Exchange is not in the expected state
     *
     * @param _exchangeId - the id of the exchange to complete
     * @param _expectedState - the state the exchange should be in
     * @return exchange - the exchange
     */
    function getValidExchange(uint256 _exchangeId, ExchangeState _expectedState)
        internal
        view
        returns (Exchange storage exchange)
    {
        // Get the exchange
        bool exchangeExists;
        (exchangeExists, exchange) = fetchExchange(_exchangeId);

        // Make sure the exchange exists
        require(exchangeExists, NO_SUCH_EXCHANGE);
        // Make sure the exchange is in expected state
        require(exchange.state == _expectedState, INVALID_STATE);
    }

    /**
     * @notice Returns the current sender address.
     */
    function msgSender() internal view returns (address) {
        return EIP712Lib.msgSender();
    }

    /**
     * @notice Gets the agent id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the exchange Ids exist
     * @return agentId - the agent Id.
     */
    function fetchAgentIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 agentId) {
        // Get the exchange Ids
        agentId = protocolLookups().agentIdByOffer[_offerId];

        // Determine existence
        exists = (agentId > 0);
    }

    /**
     * @notice Fetches the offer fees from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerFees - the offer fees details. See {BosonTypes.OfferFees}
     */
    function fetchOfferFees(uint256 _offerId) internal view returns (BosonTypes.OfferFees storage offerFees) {
        // Get the offerFees's slot
        offerFees = protocolEntities().offerFees[_offerId];
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";

/**
 * @title EIP712Lib
 *
 * @dev Provides the domain seperator and chain id.
 */
library EIP712Lib {
    /**
     * @notice Get the domain separator
     *
     * @param _name - the name of the protocol.
     * @param _version -  The version of the protocol.
     */
    function domainSeparator(string memory _name, string memory _version) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(_name)),
                    keccak256(bytes(_version)),
                    address(this),
                    getChainID()
                )
            );
    }

    /**
     * @notice Get the chain id
     *
     * @return id - the chain id, 1 for Ethereum mainnet, > 1 for public testnets.
     */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * @notice Recovers the Signer from the Signature components.
     *
     * Reverts if:
     * - signer is a zero address
     *
     * @param _user  - the sender of the transaction.
     * @param _hashedMetaTx - hashed meta transaction.
     * @param _sigR - r part of the signer's signature.
     * @param _sigS - s part of the signer's signature.
     * @param _sigV - v part of the signer's signature.
     */
    function verify(
        address _user,
        bytes32 _hashedMetaTx,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(_hashedMetaTx), _sigV, _sigR, _sigS);
        require(signer != address(0), INVALID_SIGNATURE);
        return signer == _user;
    }

    /**
     * @notice Get the domain separator.
     */
    function getDomainSeparator() private view returns (bytes32) {
        return ProtocolLib.protocolMetaTxInfo().domainSeparator;
    }

    /**
     * @dev Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     *
     * @param _messageHash  - the message hash.
     */
    function toTypedMessageHash(bytes32 _messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), _messageHash));
    }

    /**
     * @notice Get the current sender address from storage.
     */
    function getCurrentSenderAddress() internal view returns (address) {
        return ProtocolLib.protocolMetaTxInfo().currentSenderAddress;
    }

    /**
     * @notice Returns the current sender address.
     */
    function msgSender() internal view returns (address) {
        bool isItAMetaTransaction = ProtocolLib.protocolMetaTxInfo().isMetaTransaction;

        // Get sender from the storage if this is a meta transaction
        if (isItAMetaTransaction) {
            return getCurrentSenderAddress();
        } else {
            return msg.sender;
        }
    }
}