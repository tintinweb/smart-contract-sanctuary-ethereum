//SPDX-License Identifier:MIT
pragma solidity ^0.8.19;

import { SignedZoneCaptain } from "./SignedZoneCaptain.sol";

contract OpenSeaSignedZoneCaptain is SignedZoneCaptain {
    constructor(address signedZoneController)
        SignedZoneCaptain(signedZoneController)
    {}

    /**
     * @notice Internal function to assert that the caller is a valid deployer.
     */
    function _assertValidDeployer() internal view override {
        // Ensure that the contract is being deployed by an approved
        // deployer.
        // tx.origin is used here, because we use the SignedZoneDeployer
        // contract to deploy this contract, and initailize the owner,
        // rotator, and sanitizer roles.
        if (
            tx.origin != address(0x939C8d89EBC11fA45e576215E2353673AD0bA18A) &&
            tx.origin != address(0xe80a65eB7a3018DedA407e621Ef5fb5B416678CA) &&
            tx.origin != address(0x86D26897267711ea4b173C8C124a0A73612001da) &&
            tx.origin != address(0x3B52ad533687Ce908bA0485ac177C5fb42972962)
        ) {
            revert InvalidDeployer();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    SignedZoneCaptainInterface
} from "./interfaces/SignedZoneCaptainInterface.sol";

import {
    SignedZoneControllerInterface
} from "./interfaces/SignedZoneControllerInterface.sol";

import {
    SignedZoneCaptainEventsAndErrors
} from "./interfaces/SignedZoneCaptainEventsAndErrors.sol";

import { TwoStepOwnable } from "../ownable/TwoStepOwnable.sol";

/**
 * @title SignedZoneCaptain
 * @author BCLeFevre
 * @notice SignedZoneCaptain is a contract that owns signed zones and manages
 *         their active signers via two roles. The rotator role can update
 *         the active signers of a zone. The sanitizer role can remove all
 *         active signers of a zone controlled by the captain and clear the
 *         rotator role on the captain.
 */
abstract contract SignedZoneCaptain is
    TwoStepOwnable,
    SignedZoneCaptainInterface,
    SignedZoneCaptainEventsAndErrors
{
    // The address of the signed zone controller. The signed zone controller
    // manages signed zones.
    SignedZoneControllerInterface private immutable _SIGNED_ZONE_CONTROLLER;

    // The address of the rotator. The rotator can manage the active signers of
    // a zone controlled by this contract.
    address private _rotator;

    // The address of the sanitizer. The sanitizer can remove all active
    // signers of a zone controlled by the captain and clear the rotator role
    // on the captain.
    address private _sanitizer;

    /**
     * @dev Initialize contract by setting the signed zone controller.
     *
     * @param signedZoneController The address of the signed zone controller.
     */
    constructor(address signedZoneController) {
        // Ensure that the contract is being deployed by an approved deployer.
        _assertValidDeployer();

        // Ensure that a contract is deployed to the given signed zone controller.
        if (signedZoneController.code.length == 0) {
            revert InvalidSignedZoneController(signedZoneController);
        }

        // Set the signed zone controller.
        _SIGNED_ZONE_CONTROLLER = SignedZoneControllerInterface(
            signedZoneController
        );
    }

    /**
     * @notice External initialization called by the deployer to set the owner,
     *         rotator and sanitizer, and create a signed zone with the given
     *         name, API endpoint, documentation URI. This function can only be
     *         called once, as there is a check to ensure that the current
     *         owner is address(0) before the initialization is performed, the
     *         owner must then be set to a non address(0) address during
     *         initialization and finally the owner cannot be set to address(0)
     *         after initialization.
     *
     * @param initialOwner     The address to be set as the owner.
     * @param initialRotator   The address to be set as the rotator.
     * @param initialSanitizer The address to be set as the sanitizer.
     * @param zoneName         The name of the zone being created.
     * @param apiEndpoint      The API endpoint of the zone being created.
     * @param documentationURI The documentation URI of the zone being created.
     * @param zoneSalt         The salt to use when creating the zone.
     */
    function initialize(
        address initialOwner,
        address initialRotator,
        address initialSanitizer,
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        bytes32 zoneSalt
    ) external override {
        // Ensure the origin is an approved deployer.
        _assertValidDeployer();

        // Call initialize.
        _initialize(
            initialOwner,
            initialRotator,
            initialSanitizer,
            zoneName,
            apiEndpoint,
            documentationURI,
            zoneSalt
        );
    }

    /**
     * @notice Internal initialization function to set the owner, rotator, and
     *         sanitizer and create a new zone with the given name, API
     *         endpoint, documentation URI and the captain as the zone owner.
     *
     * @param initialOwner     The address to be set as the owner.
     * @param initialRotator   The address to be set as the rotator.
     * @param initialSanitizer The address to be set as the sanitizer.
     * @param zoneName         The name of the zone being created.
     * @param apiEndpoint      The API endpoint of the zone being created.
     * @param documentationURI The documentation URI of the zone being created.
     * @param zoneSalt         The salt to use when creating the zone.
     */
    function _initialize(
        address initialOwner,
        address initialRotator,
        address initialSanitizer,
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        bytes32 zoneSalt
    ) internal {
        // Set the owner of the captain.
        _setInitialOwner(initialOwner);

        // Set the rotator.
        _setRotator(initialRotator);

        // Set the sanitizer.
        _setSanitizer(initialSanitizer);

        // Create a new zone, with the captain as the zone owner, the given
        // zone name, API endpoint, and documentation URI.
        SignedZoneControllerInterface(_SIGNED_ZONE_CONTROLLER).createZone(
            zoneName,
            apiEndpoint,
            documentationURI,
            address(this),
            zoneSalt
        );
    }

    /**
     * @notice Update the API endpoint returned by the supplied zone.
     *         Only the owner can call this function.
     *
     * @param zone           The signed zone to update the API endpoint for.
     * @param newApiEndpoint The new API endpoint.
     */
    function updateZoneAPIEndpoint(address zone, string calldata newApiEndpoint)
        external
        override
    {
        // Ensure caller is the owner.
        _assertCallerIsOwner();

        // Call to the signed zone controller to update the zone API endpoint.
        _SIGNED_ZONE_CONTROLLER.updateAPIEndpoint(zone, newApiEndpoint);
    }

    /**
     * @notice Update the documentationURI returned by a zone. Only the owner
     *         of the supplied zone can call this function.
     *
     * @param zone                The signed zone to update the API endpoint
     *                            for.
     * @param newDocumentationURI The new documentation URI.
     */
    function updateZoneDocumentationURI(
        address zone,
        string calldata newDocumentationURI
    ) external override {
        // Ensure caller is the owner.
        _assertCallerIsOwner();

        // Call to the signed zone controller to update the zone documentation
        // URI.
        _SIGNED_ZONE_CONTROLLER.updateDocumentationURI(
            zone,
            newDocumentationURI
        );
    }

    /**
     * @notice Update the signer for a given signed zone.
     *
     * @param zone       The signed zone to update the signer for.
     * @param signer     The signer to update.
     * @param active     If the signer should be active or not.
     */
    function updateZoneSigner(
        address zone,
        address signer,
        bool active
    ) external override {
        // Ensure caller is the owner.
        _assertCallerIsOwner();

        // Call to the signed zone controller to update the zone signer.
        _SIGNED_ZONE_CONTROLLER.updateSigner(zone, signer, active);
    }

    /**
     * @notice Update the rotator role on the captain.
     *
     * @param newRotator The new rotator of the captain.
     */
    function updateRotator(address newRotator) external override {
        // Ensure caller is owner.
        _assertCallerIsOwner();

        // Set the new rotator.
        _setRotator(newRotator);
    }

    /**
     * @notice Update the sanitizer role on the captain.
     *
     * @param newSanitizer The new sanitizer of the captain.
     */
    function updateSanitizer(address newSanitizer) external override {
        // Ensure caller is owner.
        _assertCallerIsOwner();

        // Set the new sanitizer.
        _setSanitizer(newSanitizer);
    }

    /**
     * @notice Initiate zone ownership transfer by assigning a new potential
     *         owner for the given zone. Only callable by the owner.
     *
     * @param zone              The zone for which to initiate ownership
     *                          transfer.
     * @param newPotentialOwner The new potential owner to set.
     */
    function transferZoneOwnership(address zone, address newPotentialOwner)
        external
        override
    {
        // Ensure caller is the owner.
        _assertCallerIsOwner();

        // Call to the signed zone controller to transfer the zone ownership.
        _SIGNED_ZONE_CONTROLLER.transferOwnership(zone, newPotentialOwner);
    }

    /**
     * @notice Clear the currently set potential owner, if any, from a zone.
     *         Only callable by the owner.
     *
     * @param zone The zone for which to cancel ownership transfer.
     */
    function cancelZoneOwnershipTransfer(address zone) external override {
        // Ensure caller is the owner.
        _assertCallerIsOwner();

        // Call to the signed zone controller to cancel the zone ownership
        // transfer.
        _SIGNED_ZONE_CONTROLLER.cancelOwnershipTransfer(zone);
    }

    /**
     * @notice Accept ownership of a given zone once the address has been set
     *         as the current potential owner. Only callable by the owner.
     *
     * @param zone The zone for which to accept ownership transfer.
     */
    function acceptZoneOwnership(address zone) external override {
        // Call to the signed zone controller to accept the zone ownership.
        _SIGNED_ZONE_CONTROLLER.acceptOwnership(zone);
    }

    /**
     * @notice Rotate the signers for a given zone. Only callable by the owner
     *         or the rotator of the zone.
     *
     * @param zone              The zone to rotate the signers for.
     * @param signerToRemove    The signer to remove.
     * @param signerToAdd       The signer to add.
     */
    function rotateSigners(
        address zone,
        address signerToRemove,
        address signerToAdd
    ) external override {
        // Ensure caller is the owner or the rotator.
        _assertCallerIsOwnerOrRotator();

        // Call to the signed zone controller to remove the signer.
        _SIGNED_ZONE_CONTROLLER.updateSigner(zone, signerToRemove, false);

        // Call to the signed zone controller to add the signer.
        _SIGNED_ZONE_CONTROLLER.updateSigner(zone, signerToAdd, true);
    }

    /**
     * @notice This will remove all active signers of the given zone and clear
     *         the rotator address on the captain. Only callable by the owner
     *         or the sanitizer of the zone.
     *
     * @param zone The zone to revoke.
     */
    function sanitizeSignedZone(address zone) external override {
        // Ensure caller is the owner or the sanitizer.
        _assertCallerIsOwnerOrSanitizer();

        // Call to the signed zone controller to sanitize the signed zone.
        address[] memory signers = _SIGNED_ZONE_CONTROLLER.getActiveSigners(
            zone
        );

        // Loop through the signers and deactivate them.
        for (uint256 i = 0; i < signers.length; i++) {
            _SIGNED_ZONE_CONTROLLER.updateSigner(zone, signers[i], false);
        }

        // Clear the rotator role.
        delete _rotator;

        // Emit the sanitized event.
        emit ZoneSanitized(zone);
    }

    /**
     * @notice Get the rotator address.
     *
     * @return The rotator address.
     */
    function getRotator() external view override returns (address) {
        return _rotator;
    }

    /**
     * @notice Get the sanitizer address.
     *
     * @return The sanitizer address.
     */
    function getSanitizer() external view override returns (address) {
        return _sanitizer;
    }

    /**
     * @notice Internal function to set the rotator role on the contract,
     *         checking to make sure the provided address is not the null
     *         address
     *
     * @param newRotator The new rotator address.
     */
    function _setRotator(address newRotator) internal {
        // Ensure new rotator is not null.
        if (newRotator == address(0)) {
            revert RotatorCannotBeNullAddress();
        }

        _rotator = newRotator;

        emit RotatorUpdated(newRotator);
    }

    /**
     * @notice Internal function to set the sanitizer role on the contract,
     *         checking to make sure the provided address is not the null
     *         address
     *
     * @param newSanitizer The new sanitizer address.
     */
    function _setSanitizer(address newSanitizer) internal {
        // Ensure new sanitizer is not null.
        if (newSanitizer == address(0)) {
            revert SanitizerCannotBeNullAddress();
        }

        _sanitizer = newSanitizer;

        emit SanitizerUpdated(newSanitizer);
    }

    /**
     * @notice Internal function to assert that the caller is a valid deployer.
     *         This must be overwritten by the contract that inherits from this
     *         contract.  This is to ensure that the caller or tx.orign is
     *         permitted to deploy this contract.
     */
    function _assertValidDeployer() internal view virtual {
        revert("Not implemented assertValidDeployer");
    }

    /**
     * @dev Internal view function to revert if the caller is not the owner or
     *      the sanitizer.
     */
    function _assertCallerIsOwnerOrSanitizer() internal view {
        // Ensure caller is the owner or the sanitizer.
        if (msg.sender != owner() && msg.sender != _sanitizer) {
            revert CallerIsNotOwnerOrSanitizer();
        }
    }

    /**
     * @dev Internal view function to revert if the caller is not the owner or
     *      the rotator.
     */
    function _assertCallerIsOwnerOrRotator() internal view {
        // Ensure caller is the owner or the rotator.
        if (msg.sender != owner() && msg.sender != _rotator) {
            revert CallerIsNotOwnerOrRotator();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    TwoStepOwnableInterface
} from "./interfaces/TwoStepOwnableInterface.sol";

/**
 * @title   TwoStepOwnable
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnable provides access control for inheriting contracts,
 *          where the ownership of the contract can be exchanged via a two step
 *          process. A potential owner is set by the current owner by calling
 *          `transferOwnership`, then accepted by the new potential owner by
 *          calling `acceptOwnership`.
 */
abstract contract TwoStepOwnable is TwoStepOwnableInterface {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external override {
        // Ensure the caller is the owner.
        _assertCallerIsOwner();

        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress();
        }

        // Ensure the new potential owner is not already set.
        if (newPotentialOwner == _potentialOwner) {
            revert NewPotentialOwnerAlreadySet(_potentialOwner);
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any. Only the owner
     *         of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override {
        // Ensure the caller is the owner.
        _assertCallerIsOwner();

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Ensure that ownership transfer is currently possible.
        if (_potentialOwner == address(0)) {
            revert NoPotentialOwnerCurrentlySet();
        }

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;

        // Set the caller as the owner of this contract.
        _setOwner(msg.sender);
    }

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice A public view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @notice Internal function that sets the inital owner of the base
     *         contract. The initial owner must not already be set.
     *         To be called in the constructor or when initializing a proxy.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure that the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Set the initial owner.
        _setOwner(initialOwner);
    }

    /**
     * @dev Internal view function to revert if the caller is not the owner.
     */
    function _assertCallerIsOwner() internal view {
        // Ensure caller is the owner.
        if (msg.sender != owner()) {
            revert CallerIsNotOwner();
        }
    }

    /**
     * @notice Private function that sets a new owner and emits a corresponding
     *         event.
     *
     * @param newOwner The address to assign as the new owner.
     */
    function _setOwner(address newOwner) private {
        // Emit an event indicating that the new owner has been set.
        emit OwnershipTransferred(_owner, newOwner);

        // Set the new owner.
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title  SignedZoneCaptainInterface
 * @author BCLeFevre
 * @notice SignedZoneCaptainInterface contains function declarations for the
 *         SignedZoneCaptain contract.
 */
interface SignedZoneCaptainInterface {
    /**
     * @notice External initialization called by the deployer to set the owner,
     *         rotator and sanitizer, and create a signed zone with the given
     *         name, API endpoint, documentation URI.
     *
     * @param initialOwner     The address to be set as the owner.
     * @param initialRotator   The address to be set as the rotator.
     * @param initialSanitizer The address to be set as the sanitizer.
     * @param zoneName         The name of the zone being created.
     * @param apiEndpoint      The API endpoint of the zone being created.
     * @param documentationURI The documentation URI of the zone being created.
     * @param zoneSalt         The salt to use when creating the zone.
     */
    function initialize(
        address initialOwner,
        address initialRotator,
        address initialSanitizer,
        string calldata zoneName,
        string calldata apiEndpoint,
        string calldata documentationURI,
        bytes32 zoneSalt
    ) external;

    /**
     * @notice Update the signer for a given signed zone.
     *
     * @param zone       The signed zone to update the signer for.
     * @param signer     The signer to update.
     * @param active     If the signer should be active or not.
     */
    function updateZoneSigner(
        address zone,
        address signer,
        bool active
    ) external;

    /**
     * @notice Update the API endpoint returned by the supplied zone.
     *         Only the owner can call this function.
     *
     * @param zone           The signed zone to update the API endpoint for.
     * @param newApiEndpoint The new API endpoint.
     */
    function updateZoneAPIEndpoint(address zone, string calldata newApiEndpoint)
        external;

    /**
     * @notice Update the documentationURI returned by a zone. Only the owner
     *         of the supplied zone can call this function.
     *
     * @param zone                The signed zone to update the API endpoint
     *                            for.
     * @param newDocumentationURI The new documentation URI.
     */
    function updateZoneDocumentationURI(
        address zone,
        string calldata newDocumentationURI
    ) external;

    /**
     * @notice Initiate zone ownership transfer by assigning a new potential
     *         owner for the given zone. Only callable by the owner.
     *
     * @param zone              The zone for which to initiate ownership
     *                          transfer.
     * @param newPotentialOwner The new potential owner to set.
     */
    function transferZoneOwnership(address zone, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a zone.
     *         Only callable by the owner.
     *
     * @param zone The zone for which to cancel ownership transfer.
     */
    function cancelZoneOwnershipTransfer(address zone) external;

    /**
     * @notice Accept ownership of a given zone once the address has been set
     *         as the current potential owner. Only callable by the owner.
     *
     * @param zone The zone for which to accept ownership transfer.
     */
    function acceptZoneOwnership(address zone) external;

    /**
     * @notice Rotate the signers for a given zone. Only callable by the owner
     *         or the rotator of the zone.
     *
     * @param zone              The zone to rotate the signers for.
     * @param signerToRemove    The signer to remove.
     * @param signerToAdd       The signer to add.
     */
    function rotateSigners(
        address zone,
        address signerToRemove,
        address signerToAdd
    ) external;

    /**
     * @notice This will remove all active signers and clear the rotator
     *         address on the captain. Only callable by the owner or the
     *         sanitizer of the zone.
     *
     * @param zone The zone to sanitize.
     */
    function sanitizeSignedZone(address zone) external;

    /**
     * @notice Update the rotator role on the captain.
     *
     * @param newRotator The new rotator of the captain.
     */
    function updateRotator(address newRotator) external;

    /**
     * @notice Update the sanitizer role on the captain.
     *
     * @param newSanitizer The new sanitizer of the captain.
     */
    function updateSanitizer(address newSanitizer) external;

    /**
     * @notice Get the rotator address.
     *
     * @return The rotator address.
     */
    function getRotator() external view returns (address);

    /**
     * @notice Get the sanitizer address.
     *
     * @return The sanitizer address.
     */
    function getSanitizer() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
     * @param zoneName          The name for the zone returned in
     *                          getSeaportMetadata().
     * @param apiEndpoint       The API endpoint where orders for this zone can
     *                          be signed.
     * @param documentationURI  The URI to the documentation describing the
     *                          behavior of the contract. Request and response
     *                          payloads are defined in SIP-7.
     * @param salt              The salt to be used to derive the zone address
     * @param initialOwner      The initial owner to set for the new zone.
     *
     * @return signedZone The derived address for the zone.
     */
    function createZone(
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        address initialOwner,
        bytes32 salt
    ) external returns (address signedZone);

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
     * @param signedZone     The signed zone to update the API endpoint for.
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(
        address signedZone,
        string calldata newApiEndpoint
    ) external;

    /**
     * @notice Update the documentationURI returned by a zone.
     *         Only the owner or an active signer of the supplied zone can call
     *         this function.
     *
     * @param zone             The signed zone to update the API endpoint for.
     * @param documentationURI The new documentation URI.
     */
    function updateDocumentationURI(
        address zone,
        string calldata documentationURI
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
     * @param zone              The zone for which to initiate ownership
     *                          transfer.
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
     * @param zoneName The name of the zone.
     * @param salt     The salt to be used to derive the zone address.
     *
     * @return derivedAddress The derived address of the signed zone.
     */
    function getZone(string memory zoneName, bytes32 salt)
        external
        view
        returns (address derivedAddress);

    /**
     * @notice Returns whether or not the supplied address is an active signer
     *         for the supplied zone.
     *
     * @param zone   The zone to check if the supplied address is an active
     *               signer for.
     * @param signer The address to check if it is an active signer for
     *
     * @return active If the supplied address is an active signer for the
     *                supplied zone.
     */
    function isActiveSigner(address zone, address signer)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @notice SignedZoneCaptainEventsAndErrors contains errors and events
 *         related to owning signed zones.
 */
interface SignedZoneCaptainEventsAndErrors {
    /**
     * @dev Emit an event when the contract owner updates the rotator.
     *
     * @param newRotator The new rotator of the contract.
     */
    event RotatorUpdated(address newRotator);

    /**
     * @dev Emit an event when the contract owner updates the sanitizer.
     *
     * @param newSanitizer The new sanitizer of the contract.
     */
    event SanitizerUpdated(address newSanitizer);

    /**
     * @dev Emit an event when the sanitizer sanitizes a zone.
     *
     * @param zone The zone address being sanitized.
     */
    event ZoneSanitized(address zone);

    /**
     * @dev Revert with an error when attempting to deploy the contract with an
     *      invalid deployer.
     */
    error InvalidDeployer();

    /**
     * @dev Revert with an error when attempting to set a zone controller
     *      that does not contain contract code.
     *
     * @param signedZoneController The invalid address.
     */
    error InvalidSignedZoneController(address signedZoneController);

    /**
     * @dev Revert with an error when attempting to set the rotator
     *      to the null address.
     */
    error RotatorCannotBeNullAddress();

    /**
     * @dev Revert with an error when attempting to set the sanitizer
     *      to the null address.
     */
    error SanitizerCannotBeNullAddress();

    /**
     * @dev Revert with an error when attempting to call a function that
     *      requires the caller to be the owner or sanitizer of the zone.
     */
    error CallerIsNotOwnerOrSanitizer();

    /**
     * @dev Revert with an error when attempting to call a function that
     *      requires the caller to be the owner or rotator of the zone.
     */
    error CallerIsNotOwnerOrRotator();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title   TwoStepOwnableInterface
 * @author  OpenSea Protocol
 * @notice  TwoStepOwnableInterface contains all external function interfaces,
 *          events and errors for the TwoStepOwnable contract.
 */
interface TwoStepOwnableInterface {
    /**
     * @dev Emit an event whenever the contract owner registers a new potential
     *      owner.
     *
     * @param newPotentialOwner The new potential owner of the contract.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever contract ownership is transferred.
     *
     * @param previousOwner The previous owner of the contract.
     * @param newOwner      The new owner of the contract.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Revert with an error when attempting to call a function that
     *      requires ownership with a caller that is not the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register an initial owner
     *      and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to call a function that
     *      requires the owner to not have been set.
     */
    error OwnerAlreadySet(address owner);

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(address newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to claim ownership of the
     *      contract with a caller that is not the current potential owner.
     */
    error CallerIsNotNewPotentialOwner();

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet();

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any. Only the owner
     *         of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}