// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IBosonBundleHandler } from "../../interfaces/handlers/IBosonBundleHandler.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { BundleBase } from "../bases/BundleBase.sol";

/**
 * @title BundleHandlerFacet
 *
 * @notice Manages bundling associated with offers and twins within the protocol
 */
contract BundleHandlerFacet is IBosonBundleHandler, BundleBase {

    enum BundleUpdateAttribute {
        TWIN,
        OFFER
    }

    /**
     * @notice Facet Initializer
     */
    function initialize()
    public
    onlyUnInitialized(type(IBosonBundleHandler).interfaceId)
    {
        DiamondLib.addSupportedInterface(type(IBosonBundleHandler).interfaceId);
    }

    /**
     * @notice Creates a Bundle.
     *
     * Emits a BundleCreated event if successful.
     *
     * Reverts if:
     * - Seller does not exist
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different bundle
     * - number of offers exceeds maximum allowed number per bundle
     * - any of twins belongs to different seller
     * - any of twins does not exist
     * - number of twins exceeds maximum allowed number per bundle
     * - duplicate twins added in same bundle
     * - exchange already exists for the offer id in bundle
     *
     * @param _bundle - the fully populated struct with bundle id set to 0x0
     */
    function createBundle(
        Bundle memory _bundle
    )
    external
    override
    {
        createBundleInternal(_bundle);
    }

    /**
     * @notice Gets the details about a given bundle.
     *
     * @param _bundleId - the id of the bundle to check
     * @return exists - the bundle was found
     * @return bundle - the bundle details. See {BosonTypes.Bundle}
     */
    function getBundle(uint256 _bundleId) external override view returns(bool exists, Bundle memory bundle) {
        return fetchBundle(_bundleId);
    }

    /**
     * @notice Gets the next bundle id.
     *
     * Does not increment the counter.
     *
     * @return nextBundleId - the next bundle id
     */
    function getNextBundleId() public override view returns(uint256 nextBundleId) {
        nextBundleId = protocolCounters().nextBundleId;
    }

    /**
     * @notice Adds twins to an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - twin ids is an empty list
     * - number of twins exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any of twins belongs to different seller
     * - any of twins does not exist
     * - twin already exists in the same bundle
     * - twin ids contains duplicated twins
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _twinIds - array of twin ids to be added to the bundle
     */
    function addTwinsToBundle(
        uint256 _bundleId,
        uint256[] calldata _twinIds
    )
    external
    override
    {
        // check if bundle can be updated
        (uint256 sellerId, Bundle storage bundle) = preBundleUpdateChecks(_bundleId, _twinIds, BundleUpdateAttribute.TWIN);

        for (uint i = 0; i < _twinIds.length; i++) {
            uint twinId = _twinIds[i];
            // make sure twin exist and belong to the seller
            getValidTwin(twinId);

            // Twin can already be associated with a different bundle, but it cannot be added to the same bundle twice.
            (bool bundlesForTwinExist, uint256[] memory bundleIds) = fetchBundleIdsByTwin(twinId);
            if (bundlesForTwinExist) {
                for (uint j = 0; j < bundleIds.length; j++) {
                    // Revert if bundleId already exists in the bundleIdsByTwin mapping
                    require((bundleIds[j] != _bundleId), TWIN_ALREADY_EXISTS_IN_SAME_BUNDLE);
                }
            }

            // add to bundleIdsByTwin mapping
            protocolLookups().bundleIdsByTwin[twinId].push(_bundleId);

            // add to bundle struct
            bundle.twinIds.push(twinId);
        }

        // Notify watchers of state change
        emit BundleUpdated(_bundleId, sellerId, bundle, msgSender());
    }

    /**
     * @notice Removes twins from an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - twin ids is an empty list
     * - number of twins exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any twin is not part of the bundle
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _twinIds - array of twin ids to be removed to the bundle
     */
    function removeTwinsFromBundle(
        uint256 _bundleId,
        uint256[] calldata _twinIds
    )
    external
    override
    {
        // check if bundle can be updated
        (uint256 sellerId, Bundle storage bundle) = preBundleUpdateChecks(_bundleId, _twinIds, BundleUpdateAttribute.TWIN);

        for (uint i = 0; i < _twinIds.length; i++) {
            uint twinId = _twinIds[i];

            // Get all bundleIds that are associated to this Twin.
            (bool bundlesForTwinExist, uint256[] memory bundleIds) = fetchBundleIdsByTwin(twinId);

            // Revert here if no bundles found
            require(bundlesForTwinExist, TWIN_NOT_IN_BUNDLE);

            // remove bundleId from the bundleIdsByTwin mapping
            bool foundMatchingBundle;
            for (uint j = 0; j < bundleIds.length; j++) {
                if (bundleIds[j] == _bundleId) {
                    foundMatchingBundle = true;
                    protocolLookups().bundleIdsByTwin[twinId][j] = bundleIds[bundleIds.length - 1];
                    protocolLookups().bundleIdsByTwin[twinId].pop();
                    break;
                }
            }
            require(foundMatchingBundle, TWIN_NOT_IN_BUNDLE);

            // Also remove from the bundle struct
            uint256 twinIdsLength = bundle.twinIds.length;
            for (uint j = 0; j < twinIdsLength; j++) {
                if (bundle.twinIds[j] == twinId) {
                    bundle.twinIds[j] = bundle.twinIds[twinIdsLength - 1];
                    bundle.twinIds.pop();
                    break;
                }
            }
        }

        // Notify watchers of state change
        emit BundleUpdated(_bundleId, sellerId, bundle, msgSender());
    }

    /**
     * @dev Before performing an update, make sure update can be done
     * and return seller id and bundle storage pointer for further use.
     *
     * Reverts if:
     * - caller is not the seller
     * - twin ids / offer ids is an empty list.
     * - number of twins / number of offers exceeds maximum allowed number per bundle
     * - bundle does not exist
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _ids - array of twin ids / offer ids to be added to / removed from the bundle.
     * @param _attribute attribute, one of {TWIN, OFFER}
     * @return sellerId  - the seller Id
     * @return bundle - the bundle details
     */
    function preBundleUpdateChecks(uint256 _bundleId, uint256[] calldata _ids, BundleUpdateAttribute _attribute) internal view returns (uint256 sellerId, Bundle storage bundle) {
        // make sure that at least something will be updated
        require(_ids.length != 0, NOTHING_UPDATED);

        if (_attribute == BundleUpdateAttribute.TWIN) {
            // limit maximum number of twins to avoid running into block gas limit in a loop
            require(_ids.length <= protocolLimits().maxTwinsPerBundle, TOO_MANY_TWINS);
        } else if (_attribute == BundleUpdateAttribute.OFFER) {
            // limit maximum number of offers to avoid running into block gas limit in a loop
            require(_ids.length <= protocolLimits().maxOffersPerBundle, TOO_MANY_OFFERS);
        }

        // Get storage location for bundle
        bool exists;
        (exists, bundle) = fetchBundle(_bundleId);
        require(exists, NO_SUCH_BUNDLE);

        // Get seller id, we assume seller id exists if bundle exists
        (, sellerId) = getSellerIdByOperator(msg.sender);

        // Caller's seller id must match bundle seller id
        require(sellerId == bundle.sellerId, NOT_OPERATOR);
    }

    /**
     * @notice Adds offers to an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - offer ids is an empty list
     * - number of offers exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different bundle
     * - offer ids contains duplicated offers
     * - exchange already exists for the offer id in bundle
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _offerIds - array of offer ids to be added to the bundle
     */
    function addOffersToBundle(
        uint256 _bundleId,
        uint256[] calldata _offerIds
    )
    external
    override
    {
        // check if bundle can be updated
        (uint256 sellerId, Bundle storage bundle) = preBundleUpdateChecks(_bundleId, _offerIds, BundleUpdateAttribute.OFFER);

        for (uint i = 0; i < _offerIds.length; i++) {
            uint offerId = _offerIds[i];
            // make sure offer exist and belong to the seller
            getValidOffer(offerId);

            // make sure exchange does not already exist for this offer id.
            (bool exchangeIdsForOfferExists, ) = getExchangeIdsByOffer(offerId);
            require(!exchangeIdsForOfferExists, EXCHANGE_FOR_OFFER_EXISTS);

            // Offer should not belong to another bundle already
            (bool exists, ) = fetchBundleIdByOffer(offerId);
            require(!exists, BUNDLE_OFFER_MUST_BE_UNIQUE);

            // add to bundleIdByOffer mapping
            protocolLookups().bundleIdByOffer[offerId] = _bundleId;

            // add to bundle struct
            bundle.offerIds.push(offerId);
        }

        // Notify watchers of state change
        emit BundleUpdated(_bundleId, sellerId, bundle, msgSender());
    }

    /**
     * @notice Removes offers from an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - offer ids is an empty list
     * - number of offers exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any offer is not part of the bundle
     * - exchange already exists for the offer id in bundle
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _offerIds - array of offer ids to be removed to the bundle
     */
    function removeOffersFromBundle(
        uint256 _bundleId,
        uint256[] calldata _offerIds
    )
    external
    override
    {
        // check if bundle can be updated
        (uint256 sellerId, Bundle storage bundle) = preBundleUpdateChecks(_bundleId, _offerIds, BundleUpdateAttribute.OFFER);

        for (uint i = 0; i < _offerIds.length; i++) {
            uint offerId = _offerIds[i];

            // Offer should belong to the bundle
            (, uint256 bundleId) = fetchBundleIdByOffer(offerId);
            require(_bundleId == bundleId, OFFER_NOT_IN_BUNDLE);

            // make sure exchange does not already exist for this offer id.
            (bool exchangeIdsForOfferExists, ) = getExchangeIdsByOffer(offerId);
            require(!exchangeIdsForOfferExists, EXCHANGE_FOR_OFFER_EXISTS);

            // remove bundleIdByOffer mapping
            delete protocolLookups().bundleIdByOffer[offerId];

            // remove from the bundle struct
            uint256 offerIdsLength = bundle.offerIds.length;

            for (uint j = 0; j < offerIdsLength; j++) {
                if (bundle.offerIds[j] == offerId) {
                    bundle.offerIds[j] = bundle.offerIds[offerIdsLength - 1];
                    bundle.offerIds.pop();
                    break;
                }
            }
        }

        // Notify watchers of state change
        emit BundleUpdated(_bundleId, sellerId, bundle, msgSender());
    }

    /**
     * @notice Removes the bundle.
     *
     * Emits a BundleDeleted event if successful.
     *
     * Reverts if:
     * - caller is not the seller.
     * - Bundle does not exist.
     * - exchanges exists for bundled offers.
     *
     * @param _bundleId - the id of the bundle to check.
     */
    function removeBundle(uint256 _bundleId) override external {
        // Get storage location for bundle
        (bool exists, Bundle memory bundle) = fetchBundle(_bundleId);
        require(exists, NO_SUCH_BUNDLE);

        // Get seller id
        (, uint256 sellerId) = getSellerIdByOperator(msg.sender);
        // Caller's seller id must match bundle seller id
        require(sellerId == bundle.sellerId, NOT_OPERATOR);

        // Check if offers from the bundle have any exchanges
        bundledOffersExchangeCheck(_bundleId);

        // delete from bundleIdByOffer mapping
        uint256[] memory offerIds = bundle.offerIds;
        for (uint256 i = 0; i < offerIds.length; i++) {
            delete protocolLookups().bundleIdByOffer[offerIds[i]];
        }

        // delete from bundleIdsByTwin mapping
        uint256[] memory twinIds = bundle.twinIds;
        // loop over all the twins in the bundle
        for (uint256 j = 0; j < twinIds.length; j++) {

            uint256 twinId = twinIds[j];
            (bool bundlesForTwinExist, uint256[] memory bundleIds) = fetchBundleIdsByTwin(twinId);

            if (bundlesForTwinExist) {

                uint256 bundleIdsLength = bundleIds.length;
                // loop over all the bundleIds associated with a twin
                for (uint k = 0; k < bundleIdsLength; k++) {

                    // If bundleId is found in the array, then pop it.
                    if (protocolLookups().bundleIdsByTwin[twinId][k] == _bundleId) {
                        protocolLookups().bundleIdsByTwin[twinId][k] = protocolLookups().bundleIdsByTwin[twinId][bundleIdsLength - 1];
                        protocolLookups().bundleIdsByTwin[twinId].pop();
                        break;
                    }
                }
            }
        }

        // delete from bundles mapping
        delete protocolEntities().bundles[_bundleId];

        emit BundleDeleted(_bundleId, bundle.sellerId, msgSender());
    }

    /**
     * @notice Checks if exchanges for bundled offers exists.
     *
     * Reverts if:
     * - exchange Ids for an offer exists.
     *
     * @param _bundleId - the bundle Id.
     */
    function bundledOffersExchangeCheck(uint256 _bundleId) internal view {
        // Get storage location for bundle
        (, Bundle storage bundle) = fetchBundle(_bundleId);

        // Get the offer Ids in the bundle
        uint256[] memory offerIds = bundle.offerIds;

        for (uint256 i = 0; i < offerIds.length; i++) {
            (bool exchangeIdsForOfferExists, ) = getExchangeIdsByOffer(offerIds[i]);
            require(!exchangeIdsForOfferExists, EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS);
        }
    }

    /**
     * @notice Gets the bundle id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the bundle Id exists
     * @return bundleId  - the bundle Id.
     */
    function getBundleIdByOffer(uint256 _offerId) external override view returns(bool exists, uint256 bundleId) {
        return fetchBundleIdByOffer(_offerId);
    }

    /**
     * @notice Gets the bundle ids for a given twin id.
     *
     * @param _twinId - the twin Id.
     * @return exists - whether the bundle Ids exist
     * @return bundleIds  - the bundle Ids.
     */
    function getBundleIdsByTwin(uint256 _twinId) external override view returns(bool exists, uint256[] memory bundleIds) {
        return fetchBundleIdsByTwin(_twinId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BosonTypes} from "../../domain/BosonTypes.sol";
import {IBosonBundleEvents} from "../events/IBosonBundleEvents.sol";

/**
 * @title IBosonBundleHandler
 *
 * @notice Handles bundling of offers and twins within the protocol
 *
 * The ERC-165 identifier for this interface is: 0xa13dc8bd
 */
interface IBosonBundleHandler is IBosonBundleEvents {

    /**
     * @notice Creates a bundle.
     *
     * Emits a BundleCreated event if successful.
     *
     * Reverts if:
     * - Seller does not exist
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different bundle
     * - number of offers exceeds maximum allowed number per bundle
     * - any of twins belongs to different seller
     * - any of twins does not exist
     * - number of twins exceeds maximum allowed number per bundle
     * - duplicate twins added in same bundle
     * - exchange already exists for the offer id in bundle
     *
     * @param _bundle - the fully populated struct with bundle id set to 0x0
     */
    function createBundle(BosonTypes.Bundle memory _bundle) external;

    /**
     * @notice Gets the details about a given bundle.
     *
     * @param _bundleId - the id of the bundle to check
     * @return exists - the bundle was found
     * @return bundle - the bundle details. See {BosonTypes.Bundle}
     */
    function getBundle(uint256 _bundleId) external view returns (bool exists, BosonTypes.Bundle memory bundle);

    /**
     * @notice Gets the next bundle id.
     *
     * Does not increment the counter.
     *
     * @return nextBundleId - the next bundle id
     */
    function getNextBundleId() external view returns (uint256 nextBundleId);

    /**
     * @notice Adds twins to an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - twin ids is an empty list
     * - number of twins exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any of twins belongs to different seller
     * - any of twins does not exist
     * - twin already exists in the same bundle
     * - twin ids contains duplicated twins
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _twinIds - array of twin ids to be added to the bundle
     */
    function addTwinsToBundle(uint256 _bundleId, uint256[] calldata _twinIds) external;

    /**
     * @notice Removes twins from an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - twin ids is an empty list
     * - number of twins exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any twin is not part of the bundle
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _twinIds - array of twin ids to be removed to the bundle
     */
    function removeTwinsFromBundle(uint256 _bundleId, uint256[] calldata _twinIds) external;

    /**
     * @notice Adds offers to an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - offer ids is an empty list
     * - number of offers exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different bundle
     * - offer ids contains duplicated offers
     * - exchange already exists for the offer id in bundle
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _offerIds - array of offer ids to be added to the bundle
     */
    function addOffersToBundle(uint256 _bundleId, uint256[] calldata _offerIds) external;

    /**
     * @notice Removes offers from an existing bundle
     *
     * Emits a BundleUpdated event if successful.
     *
     * Reverts if:
     * - caller is not the seller
     * - offer ids is an empty list
     * - number of offers exceeds maximum allowed number per bundle
     * - bundle does not exist
     * - any offer is not part of the bundle
     * - exchange already exists for the offer id in bundle
     *
     * @param _bundleId  - the id of the bundle to be updated
     * @param _offerIds - array of offer ids to be removed to the bundle
     */
    function removeOffersFromBundle(uint256 _bundleId, uint256[] calldata _offerIds) external;

    /**
     * @notice Removes the bundle.
     *
     * Emits a BundleDeleted event if successful.
     *
     * Reverts if:
     * - caller is not the seller.
     * - Bundle does not exist.
     * - exchanges exists for bundled offers.
     *
     * @param _bundleId - the id of the bundle to check.
     */
    function removeBundle(uint256 _bundleId) external;

    /**
     * @notice Gets the bundle id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the bundle Id exists
     * @return bundleId  - the bundle Id.
     */
    function getBundleIdByOffer(uint256 _offerId) external view returns (bool exists, uint256 bundleId);

    /**
     * @notice Gets the bundle ids for a given twin id.
     *
     * @param _twinId - the twin Id.
     * @return exists - whether the bundle Ids exist
     * @return bundleIds  - the bundle Ids.
     */
    function getBundleIdsByTwin(uint256 _twinId) external view returns (bool exists, uint256[] memory bundleIds);
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

import { IBosonBundleEvents } from "../../interfaces/events/IBosonBundleEvents.sol";
import { ProtocolBase } from "./../bases/ProtocolBase.sol";
import { ProtocolLib } from "./../libs/ProtocolLib.sol";

/**
 * @title BundleBase
 *
 * @dev Provides methods for bundle creation that can be shared accross facets
 */
contract BundleBase is ProtocolBase, IBosonBundleEvents {
    /**
     * @notice Creates a Bundle.
     *
     * Emits a BundleCreated event if successful.
     *
     * Reverts if:
     * - Seller does not exist
     * - any of offers belongs to different seller
     * - any of offers does not exist
     * - offer exists in a different bundle
     * - number of offers exceeds maximum allowed number per bundle
     * - any of twins belongs to different seller
     * - any of twins does not exist
     * - number of twins exceeds maximum allowed number per bundle
     * - duplicate twins added in same bundle
     *
     * @param _bundle - the fully populated struct with bundle id set to 0x0
     */
    function createBundleInternal(Bundle memory _bundle) internal {
        // get seller id, make sure it exists and store it to incoming struct
        (bool exists, uint256 sellerId) = getSellerIdByOperator(msg.sender);
        require(exists, NOT_OPERATOR);

        // limit maximum number of offers to avoid running into block gas limit in a loop
        require(_bundle.offerIds.length <= protocolLimits().maxOffersPerBundle, TOO_MANY_OFFERS);

        // limit maximum number of twins to avoid running into block gas limit in a loop
        require(_bundle.twinIds.length <= protocolLimits().maxTwinsPerBundle, TOO_MANY_TWINS);

        // Get the next bundle and increment the counter
        uint256 bundleId = protocolCounters().nextBundleId++;

        for (uint i = 0; i < _bundle.offerIds.length; i++) {
            // make sure all offers exist and belong to the seller
            getValidOffer(_bundle.offerIds[i]);

            (bool bundleByOfferExists, ) = fetchBundleIdByOffer(_bundle.offerIds[i]);
            require(!bundleByOfferExists, BUNDLE_OFFER_MUST_BE_UNIQUE);

            // make sure exchange does not already exist for this offer id.
            (bool exchangeIdsForOfferExists, ) = getExchangeIdsByOffer(_bundle.offerIds[i]);
            require(!exchangeIdsForOfferExists, EXCHANGE_FOR_OFFER_EXISTS);

            // Add to bundleIdByOffer mapping
            protocolLookups().bundleIdByOffer[_bundle.offerIds[i]] = bundleId;
        }

        for (uint i = 0; i < _bundle.twinIds.length; i++) {
            // make sure all twins exist and belong to the seller
            getValidTwin(_bundle.twinIds[i]);

            // A twin can belong to multiple bundles
            (bool bundlesForTwinExist, uint256[] memory bundleIds) = fetchBundleIdsByTwin(_bundle.twinIds[i]);
            if (bundlesForTwinExist) {
                for (uint j = 0; j < bundleIds.length; j++) {
                    require((bundleIds[j] != bundleId), TWIN_ALREADY_EXISTS_IN_SAME_BUNDLE);
                }
            }

            // Push to bundleIdsByTwin mapping
            protocolLookups().bundleIdsByTwin[_bundle.twinIds[i]].push(bundleId);
        }

        // Get storage location for bundle
        (, Bundle storage bundle) = fetchBundle(bundleId);

        // Set bundle props individually since memory structs can't be copied to storage
        bundle.id = _bundle.id = bundleId;
        bundle.sellerId = _bundle.sellerId = sellerId;
        bundle.offerIds = _bundle.offerIds;
        bundle.twinIds = _bundle.twinIds;

        // Notify watchers of state change
        emit BundleCreated(bundleId, sellerId, _bundle, msgSender());
    }

    /**
     * @notice Gets twin from protocol storage, makes sure it exist.
     *
     * Reverts if:
     * - Twin does not exist
     * - Caller is not the seller
     *
     *  @param _twinId - the id of the twin to check
     */
    function getValidTwin(uint256 _twinId) internal view returns (Twin storage twin) {
        bool exists;
        // Get twin
        (exists, twin) = fetchTwin(_twinId);

        // Twin must already exist
        require(exists, NO_SUCH_TWIN);

        // Get seller id, we assume seller id exists if twin exists
        (, uint256 sellerId) = getSellerIdByOperator(msg.sender);

        // Caller's seller id must match twin seller id
        require(sellerId == twin.sellerId, NOT_OPERATOR);
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
        address payable wallet;
        bool active;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 protocolFee;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        uint256 disputeResolverId;
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
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
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

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 supplyAvailable; // ERC-1155 / ERC-20
        uint256[] supplyIds; // ERC-721
        uint256 tokenId; // ERC-1155
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

    struct MetaTxCommitToOffer {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxOfferDetails offerDetails;
    }

    struct MetaTxOfferDetails {
        address buyer;
        uint256 offerId;
    }

    struct MetaTxExchange {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxExchangeDetails exchangeDetails;
    }

    struct MetaTxExchangeDetails {
        uint256 exchangeId;
    }

    struct MetaTxFund {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxFundDetails fundDetails;
    }

    struct MetaTxFundDetails {
        uint256 entityId;
        address[] tokenList;
        uint256[] tokenAmounts;
    }

    struct MetaTxDispute {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxDisputeDetails disputeDetails;
    }

    struct MetaTxDisputeDetails {
        uint256 exchangeId;
        string complaint;
    }

    struct MetaTxDisputeResolution {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        MetaTxDisputeResolutionDetails disputeResolutionDetails;
    }

    struct MetaTxDisputeResolutionDetails {
        uint256 exchangeId;
        uint256 buyerPercent;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {BosonTypes} from "../../domain/BosonTypes.sol";

/**
 * @title IBosonBundleEvents
 *
 * @notice Events related to management of bundles within the protocol
 */
interface IBosonBundleEvents {
    event BundleCreated(uint256 indexed bundleId, uint256 indexed sellerId, BosonTypes.Bundle bundle, address indexed executedBy);
    event BundleUpdated(uint256 indexed bundleId, uint256 indexed sellerId, BosonTypes.Bundle bundle, address indexed executedBy);
    event BundleDeleted(uint256 indexed bundleId, uint256 indexed sellerId, address indexed executedBy);
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

import {ProtocolLib} from "../libs/ProtocolLib.sol";
import {DiamondLib} from "../../diamond/DiamondLib.sol";
import {BosonTypes} from "../../domain/BosonTypes.sol";
import {BosonConstants} from "../../domain/BosonConstants.sol";

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
     */
    function fetchSeller(uint256 _sellerId) internal view returns (bool exists, Seller storage seller) {
        // Get the seller's slot
        seller = protocolEntities().sellers[_sellerId];

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
     */
    function fetchDisputeResolver(uint256 _disputeResolverId) internal view returns (bool exists, BosonTypes.DisputeResolver storage disputeResolver) {
        // Get the dispute resolver's slot
        disputeResolver = protocolEntities().disputeResolvers[_disputeResolverId];

        // Determine existence
        exists = (_disputeResolverId > 0 && disputeResolver.id == _disputeResolverId);
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
    function fetchOfferDurations(uint256 _offerId) internal view returns (BosonTypes.OfferDurations storage offerDurations) {
        // Get the offer's slot
        offerDurations = protocolEntities().offerDurations[_offerId];
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
    function fetchExchange(uint256 _exchangeId)
        internal
        view
        returns (bool exists, Exchange storage exchange)
    {
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
    returns (bool exists, Dispute storage dispute, DisputeDates storage disputeDates)
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
        (, seller) = fetchSeller(offer.sellerId);

        // Caller must be seller's operator address
        require(seller.operator == msg.sender, NOT_OPERATOR);
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
     * @notice Gets the bundle ids for a given twin id.
     *
     * @param _twinId - the twin Id.
     * @return exists - whether the bundle Ids exist
     * @return bundleIds  - the bundle Ids.
     */
    function fetchBundleIdsByTwin(uint256 _twinId) internal view returns (bool exists, uint256[] memory bundleIds) {
        // Get the bundle Ids
        bundleIds = protocolLookups().bundleIdsByTwin[_twinId];

        // Determine existence
        exists = (bundleIds.length > 0);
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
    function checkBuyer(uint256 _currentBuyer)
    internal
    view
    {
        // Get the caller's buyer account id
        uint256 buyerId;
        (, buyerId) = getBuyerIdByWallet(msgSender());

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
    returns(Exchange storage exchange)
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
    bytes32 internal constant PROTOCOL_META_TX_POSITION = keccak256("boson.protocol.metaTransactionsStorage");

    // Protocol addresses storage
    struct ProtocolAddresses {
        // Address of the Boson Protocol treasury
        address payable treasuryAddress;
        // Address of the Boson Token (ERC-20 contract)
        address payable tokenAddress;
        // Address of the Boson Protocol Voucher proxy
        address voucherAddress;
    }

    // Protocol limits storage
    struct ProtocolLimits {
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
        // offer id => offer durations
        mapping(uint256 => BosonTypes.OfferDurations) offerDurations;
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
        // buyer id => dispute resolver
        mapping(uint256 => BosonTypes.DisputeResolver) disputeResolvers;
        // group id => group
        mapping(uint256 => BosonTypes.Group) groups;
        // bundle id => bundle
        mapping(uint256 => BosonTypes.Bundle) bundles;
        // twin id => twin
        mapping(uint256 => BosonTypes.Twin) twins;
    }

    // Protocol lookups storage
    struct ProtocolLookups {
        // offer id => exchange ids
        mapping(uint256 => uint256[]) exchangeIdsByOffer;
        // offer id => bundle id
        mapping(uint256 => uint256) bundleIdByOffer;
        // twin id => bundle ids
        mapping(uint256 => uint256[]) bundleIdsByTwin;
        // offer id => group id
        mapping(uint256 => uint256) groupIdByOffer;
        //seller operator address => sellerId
        mapping(address => uint256) sellerIdByOperator;
        //seller admin address => sellerId
        mapping(address => uint256) sellerIdByAdmin;
        //seller clerk address => sellerId
        mapping(address => uint256) sellerIdByClerk;
        //buyer wallet address => buyerId
        mapping(address => uint256) buyerIdByWallet;
        //dispute resolver wallet address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByWallet;
        // seller/buyer id => token address => amount
        mapping(uint256 => mapping(address => uint256)) availableFunds;
        // seller/buyer id => all tokens with balance > 0
        mapping(uint256 => address[]) tokenList;
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
    bytes32 internal constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

    // Revert Reasons: General
    string internal constant INVALID_ADDRESS = "Invalid address";
    string internal constant INVALID_STATE = "Invalid state";
    string internal constant ARRAY_LENGTH_MISMATCH = "Array length mismatch";

    // Revert Reasons: Facet initializer related
    string internal constant ALREADY_INITIALIZED = "Already initialized";

    // Revert Reasons: Access related
    string internal constant ACCESS_DENIED = "Access denied, caller doesn't have role";
    string internal constant NOT_OPERATOR = "Not seller's operator";
    string internal constant NOT_ADMIN = "Not seller's admin";
    string internal constant NOT_BUYER_OR_SELLER = "Not buyer or seller";
    string internal constant NOT_VOUCHER_HOLDER = "Not current voucher holder";
    string internal constant NOT_BUYER_WALLET = "Not buyer's wallet address";
    string internal constant NOT_DISPUTE_RESOLVER_WALLET = "Not dispute resolver's wallet address";

    // Revert Reasons: Account-related
    string internal constant NO_SUCH_SELLER = "No such seller";
    string internal constant MUST_BE_ACTIVE = "Account must be active";
    string internal constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
    string internal constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";
    string internal constant DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE =
        "Dispute Resolver address cannot be assigned to another dispute resolver Id";
    string internal constant NO_SUCH_BUYER = "No such buyer";
    string internal constant WALLET_OWNS_VOUCHERS = "Wallet address owns vouchers";
    string internal constant NO_SUCH_DISPUTE_RESOLVER = "No such dispute resolver";

    // Revert Reasons: Offer related
    string internal constant NO_SUCH_OFFER = "No such offer";
    string internal constant OFFER_PERIOD_INVALID = "Offer period invalid";
    string internal constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
    string internal constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
    string internal constant OFFER_NOT_UPDATEABLE = "Offer not updateable";
    string internal constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
    string internal constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
    string internal constant OFFER_HAS_EXPIRED = "Offer has expired";
    string internal constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
    string internal constant OFFER_SOLD_OUT = "Offer has sold out";
    string internal constant EXCHANGE_FOR_OFFER_EXISTS = "Exchange for offer exists";
    string internal constant AMBIGUOUS_VOUCHER_EXPIRY =
        "Exactly one of voucherRedeemableUntil and voucherValid must be non zero";
    string internal constant REDEMPTION_PERIOD_INVALID = "Redemption period invalid";
    string internal constant INVALID_FULFILLMENT_PERIOD = "Invalid fulfillemnt period";
    string internal constant INVALID_DISPUTE_DURATION = "Invalid dispute duration";
    string internal constant INVALID_DISPUTE_RESOLVER = "Invalid dispute resolver";
    string internal constant INVALID_QUANTITY_AVAILABLE = "Invalid quantity available";

    // Revert Reasons: Group related
    string internal constant NO_SUCH_GROUP = "No such offer";
    string internal constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
    string internal constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
    string internal constant NOTHING_UPDATED = "Nothing updated";
    string internal constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

    // Revert Reasons: Exchange related
    string internal constant NO_SUCH_EXCHANGE = "No such exchange";
    string internal constant FULFILLMENT_PERIOD_NOT_ELAPSED = "Fulfillment period has not yet elapsed";
    string internal constant VOUCHER_NOT_REDEEMABLE = "Voucher not yet valid or already expired";
    string internal constant VOUCHER_STILL_VALID = "Voucher still valid";
    string internal constant VOUCHER_HAS_EXPIRED = "Voucher has expired";

    // Revert Reasons: Twin related
    string internal constant NO_SUCH_TWIN = "No such twin";
    string internal constant NO_TRANSFER_APPROVED = "No transfer approved";
    string internal constant TWIN_TRANSFER_FAILED = "Twin could not be transferred";
    string internal constant UNSUPPORTED_TOKEN = "Unsupported token";
    string internal constant TWIN_HAS_BUNDLES = "Twin has bundles";

    // Revert Reasons: Bundle related
    string internal constant NO_SUCH_BUNDLE = "No such bundle";
    string internal constant TWIN_NOT_IN_BUNDLE = "Twin not part of the bundle";
    string internal constant OFFER_NOT_IN_BUNDLE = "Offer not part of the bundle";
    string internal constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
    string internal constant TWIN_ALREADY_EXISTS_IN_SAME_BUNDLE = "Twin already exists in the same bundle";
    string internal constant BUNDLE_OFFER_MUST_BE_UNIQUE = "Offer must be unique to a bundle";
    string internal constant EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS = "Exchange for the bundled offers exists";

    // Revert Reasons: Funds related
    string internal constant NATIVE_WRONG_ADDRESS = "Native token address must be 0";
    string internal constant NATIVE_WRONG_AMOUNT = "Transferred value must match amount";
    string internal constant TOKEN_NAME_UNSPECIFIED = "Token name unspecified";
    string internal constant NATIVE_CURRENCY = "Native currency";
    string internal constant TOO_MANY_TOKENS = "Too many tokens";
    string internal constant TOKEN_AMOUNT_MISMATCH = "Number of amounts should match number of tokens";
    string internal constant NOTHING_TO_WITHDRAW = "Nothing to withdraw";
    string internal constant NOT_AUTHORIZED = "Not authorized to withdraw";

    // Revert Reasons: Meta-Transactions related
    string internal constant NONCE_USED_ALREADY = "Nonce used already";
    string internal constant FUNCTION_CALL_NOT_SUCCESSFUL = "Function call not successful";
    string internal constant INVALID_FUNCTION_SIGNATURE =
        "functionSignature can not be of executeMetaTransaction method";
    string internal constant SIGNER_AND_SIGNATURE_DO_NOT_MATCH = "Signer and signature do not match";
    string internal constant INVALID_FUNCTION_NAME = "Invalid function name";

    // Revert Reasons: Dispute related
    string internal constant COMPLAINT_MISSING = "Complaint missing";
    string internal constant FULFILLMENT_PERIOD_HAS_ELAPSED = "Fulfillment period has already elapsed";
    string internal constant DISPUTE_HAS_EXPIRED = "Dispute has expired";
    string internal constant INVALID_BUYER_PERCENT = "Invalid buyer percent";
    string internal constant DISPUTE_STILL_VALID = "Dispute still valid";
    string internal constant INVALID_DISPUTE_TIMEOUT = "Invalid dispute timeout";

    // Revert Reasons: Config related
    string internal constant PROTOCOL_FEE_PERCENTAGE_INVALID = "Percentage representation must be less than 10000";
}

// TODO: Refactor to use file level constants throughout or use custom Errors
// Libraries cannot inherit BosonConstants, therefore these revert reasons are defined on the file level
string constant TOKEN_TRANSFER_FAILED = "Token transfer failed";
string constant INSUFFICIENT_VALUE_SENT = "Insufficient value sent";
string constant INSUFFICIENT_AVAILABLE_FUNDS = "Insufficient available funds";
string constant NATIVE_NOT_ALLOWED = "Transfer of native currency not allowed";
string constant INVALID_SIGNATURE = "Invalid signature";