// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
 * @notice SignedZoneController enables the deploying of SignedZones and
 *         managing new SignedZone.
 *         SignedZones are an implementation of SIP-7 that requires orders to
 *         be signed by an approved signer.
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

    /**
     * @dev Initialize contract
     */
    constructor() {}

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
    ) external override returns (address signedZone) {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InvalidInitialOwner();
        }

        // Ensure the first 20 bytes of the salt are the same as the msg.sender.
        if ((address(uint160(bytes20(salt))) != msg.sender)) {
            // Revert with an error indicating that the creator is invalid.
            revert InvalidCreator();
        }

        // Get the creation code for the signed zone.
        bytes memory _SIGNED_ZONE_CREATION_CODE = abi.encodePacked(
            type(SignedZone).creationCode,
            abi.encode(zoneName)
        );

        // Using assembly try to deploy the zone.
        assembly {
            signedZone := create2(
                0,
                add(0x20, _SIGNED_ZONE_CREATION_CODE),
                mload(_SIGNED_ZONE_CREATION_CODE),
                salt
            )

            if iszero(extcodesize(signedZone)) {
                revert(0, 0)
            }
        }

        // Initialize storage variable referencing signed zone properties.
        SignedZoneProperties storage signedZoneProperties = _signedZones[
            signedZone
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
        signedZoneProperties.substandards = [1];

        // Emit an event signifying that the zone was created.
        emit ZoneCreated(
            signedZone,
            zoneName,
            apiEndpoint,
            documentationURI,
            salt
        );

        // Emit an event indicating that zone ownership has been assigned.
        emit OwnershipTransferred(signedZone, address(0), initialOwner);
    }

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
        external
        override
    {
        // Ensure the caller is the current owner of the zone in question.
        _assertCallerIsZoneOwner(zone);

        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress(zone);
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
     * @notice Update the API endpoint returned by a zone.
     *         Only the owner or an active signer of the supplied zone can call
     *         this function.
     *
     * @param zone           The signed zone to update the API endpoint for.
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(address zone, string calldata newApiEndpoint)
        external
        override
    {
        // Ensure the caller is the owner of the signed zone.
        _assertCallerIsZoneOwner(zone);

        // Retrieve storage region where the singers for the signedZone are
        // stored.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Update the API endpoint on the signed zone.
        signedZoneProperties.apiEndpoint = newApiEndpoint;
    }

    /**
     * @notice Update the documentationURI returned by a zone.
     *         Only the owner or an active signer of the supplied zone can call
     *         this function.
     *
     * @param zone             The signed zone to update the documentationURI
     *                         for.
     * @param documentationURI The new documentation URI.
     */
    function updateDocumentationURI(
        address zone,
        string calldata documentationURI
    ) external override {
        // Ensure the caller is the owner of the signed zone.
        _assertCallerIsZoneOwner(zone);

        // Retrieve storage region where the singers for the signedZone are
        // stored.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Update the documentationURI on the signed zone.
        signedZoneProperties.documentationURI = documentationURI;
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
        // Ensure the caller is the owner of the signed zone.
        _assertCallerIsZoneOwner(zone);

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
     * @notice Returns the active signers for the zone. Note that the array of
     *         active signers could grow to a size that this function could not
     *         return, the array of active signers is expected to be small,
     *         and is managed by the controller.
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
     * @notice Returns if the given address is an active signer for the zone.
     *
     * @param zone   The zone to return the active signers for.
     * @param signer The address to check if it is an active signer.
     *
     * @return The address is an active signer, false otherwise.
     */
    function isActiveSigner(address zone, address signer)
        external
        view
        override
        returns (bool)
    {
        // Ensure that the zone in question exists.
        _assertZoneExists(zone);

        // Retrieve storage region where the singers for the signedZone are
        // stored.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];

        // Return whether the signer is an active signer for the zone.
        return signedZoneProperties.signers[signer].active;
    }

    /**
     * @notice Derive the zone address associated with a salt.
     *
     * @param salt  The salt to be used to derive the zone address.
     *
     * @return derivedAddress The derived address of the signed zone.
     */
    function getZone(string memory zoneName, bytes32 salt)
        external
        view
        override
        returns (address derivedAddress)
    {
        // Get the zone creation code hash.
        bytes32 _SIGNED_ZONE_CREATION_CODE_HASH = keccak256(
            abi.encodePacked(
                type(SignedZone).creationCode,
                abi.encode(zoneName)
            )
        );
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
        // Get the name hash from the zone properties.
        SignedZoneProperties storage signedZoneProperties = _signedZones[zone];
        bytes32 nameHash = keccak256(bytes(signedZoneProperties.zoneName));
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
     *      is the null address or the signer already exists, or the signer was
     *      previously authorized.  If the signer is being removed, the
     *      function will revert if the signer is not active.
     *
     * @param signedZoneProperties The signed zone properties for the zone.
     * @param signer               The signer to add or remove.
     * @param active               Whether the signer is being added or
     *                             removed.
     */
    function _assertSignerPermissions(
        SignedZoneProperties storage signedZoneProperties,
        address signer,
        bool active
    ) private view {
        // Do not allow the null address to be added as a signer.
        if (signer == address(0)) {
            revert SignerCannotBeNullAddress();
        }

        // If the signer is being added...
        if (active) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ZoneParameters, Schema } from "../lib/ConsiderationStructs.sol";

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
 * @notice SignedZone is an implementation of SIP-7 that requires orders
 *         to be signed by an approved signer.
 *         https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 */
contract SignedZone is SignedZoneEventsAndErrors, ZoneInterface, SIP5Interface {
    /// @dev The zone's controller that is set during deployment.
    address private immutable _controller;

    /// @dev The authorized signers, and if they are active.
    mapping(address => bool) private _signers;

    /// @dev The EIP-712 digest parameters.
    bytes32 internal immutable _NAME_HASH;
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
    uint256 internal immutable _CHAIN_ID = block.chainid;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /**
     * @notice Constructor to deploy the contract.
     *
     * @param zoneName The name for the zone used in the domain separator
     *                 derivation.
     */
    constructor(string memory zoneName) {
        // Set the deployer as the controller.
        _controller = msg.sender;

        // Set the name hash.
        _NAME_HASH = keccak256(bytes(zoneName));

        // Derive and set the domain separator.
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Emit an event to signal a SIP-5 contract has been deployed.
        emit SeaportCompatibleContractDeployed();
    }

    /**
     * @notice The fallback function is used as a dispatcher for the
     *         `updateSigner`, `isActiveSigner`, `getActiveSigners` and
     *         `supportsInterface` functions.
     */
    // prettier-ignore
    fallback(bytes calldata) external payable returns (bytes memory output) {
        // Get the function selector.
        bytes4 selector = msg.sig;

        if (selector == UPDATE_SIGNER_SELECTOR) {
            // abi.encodeWithSignature("updateSigner(address,bool)", signer,
            // active)
          
            // Get the signer, and active status.
            address signer = abi.decode(msg.data[4:], (address));
            bool active = abi.decode(msg.data[36:], (bool));

            // Call to update the signer.
            _updateSigner(signer, active);
        } else if (selector == GET_ACTIVE_SIGNERS_SELECTOR) {
            // abi.encodeWithSignature("getActiveSigners()")
        
            // Call the internal function to get the active signers.
            return abi.encode(_getActiveSigners());
        } else if (selector == SUPPORTS_INTERFACE_SELECTOR) {
            // abi.encodeWithSignature("supportsInterface(bytes4)", interfaceId)

            // Get the interface ID.
            bytes4 interfaceId = abi.decode(msg.data[4:], (bytes4));

            // Call the internal function to determine if the interface is
            // supported.
            return abi.encode(_supportsInterface(interfaceId));
        } else if (selector == IS_ACTIVE_SIGNER_SELECTOR) {
            // abi.encodeWithSignature("isActiveSigner(address)", signer)

            // Get the signer.
            address signer = abi.decode(msg.data[4:], (address));

            // Call the internal function to determine if the signer is active.
            return abi.encode(_isActiveSigner(signer));
        }
        else {
             // Revert if the function selector is not supported.
            assembly {
                // Store left-padded selector with push4 (reduces bytecode),
                // mem[28:32] = selector
                mstore(0, UnsupportedFunctionSelector_error_selector)
                // revert(abi.encodeWithSignature(
                //  "UnsupportedFunctionSelector()"
                // ))
                revert(0x1c, UnsupportedFunctionSelector_error_length)
            }
        }
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
        external
        view
        override
        returns (bytes4 validOrderMagicValue)
    {
        // Check Zone Parameters validity.
        _assertValidZoneParameters();
        // Put the extraData and orderHash on the stack for cheaper access.
        bytes calldata extraData = zoneParameters.extraData;
        bytes32 orderHash = zoneParameters.orderHash;

        // Declare a variable to hold the expiration.
        uint64 expiration;

        // Validate the extraData.
        assembly {
            // Get the length of the extraData.
            let extraDataPtr := add(0x24, calldataload(Zone_extraData_cdPtr))
            let extraDataLength := calldataload(extraDataPtr)

            // Validate the extra data length.
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

            // Validate the SIP6 Version byte.
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

            // Validate the substandard version byte.
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
                //   "SignatureExpired(uint256,bytes32)", expiration, orderHash)
                // )
                revert(0x1c, SignatureExpired_error_length)
            }

            // Get the length of the consideration array.
            let considerationLength := calldataload(
                add(0x24, calldataload(Zone_consideration_head_cdPtr))
            )

            // Revert if the order does not have any consideration items due to
            // the Substandard #1 requirement.
            if iszero(considerationLength) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidSubstandardSupport_error_selector)
                mstore(InvalidSubstandardSupport_error_reason_offset_ptr, 0x60)
                mstore(
                    InvalidSubstandardSupport_error_substandard_version_ptr,
                    1
                )
                mstore(InvalidSubstandardSupport_error_orderHash_ptr, orderHash)
                mstore(InvalidSubstandardSupport_error_reason_length_ptr, 0x2a)
                mstore(
                    InvalidSubstandardSupport_error_reason_ptr,
                    "Consideration must have at least"
                )
                mstore(
                    InvalidSubstandardSupport_error_reason_2_ptr,
                    " one item."
                )
                // revert(abi.encodeWithSignature(
                //     "InvalidSubstandardSupport(string,uint256,bytes32)",
                //     reason,
                //     substandardVersion,
                //     orderHash
                // ))
                revert(0x1c, InvalidSubstandardSupport_error_length)
            }
        }

        // extraData bytes 29-93: signature
        // (strictly requires 64 byte compact sig, EIP-2098)
        bytes calldata signature = extraData[29:93];

        // extraData bytes 93-end: context (optional, variable length)
        bytes calldata context = extraData[93:];

        // Check the validity of the Substandard #1 extraData and get the
        // expected fulfiller address.
        address expectedFulfiller = (
            _assertValidSubstandardAndGetExpectedFulfiller(orderHash)
        );

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
     * @return name     The contract name
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
        // Set the signer's active status to true.
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
     * @notice Returns the active signers for the zone. Note that the array of
     *         active signers could grow to a size that this function could not
     *         return, the array of active signers is  expected to be small,
     *         and is managed by the controller.
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
     * @notice Returns if the given address is an active signer for the zone.
     *
     * @param signer The address to check if it is an active signer.
     *
     * @return The address is an active signer, false otherwise.
     */
    function _isActiveSigner(address signer) internal view returns (bool) {
        // Return the active status of the caller.
        return _signers[signer];
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
     * @dev Internal view function to revert if the caller is not the
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
                // Store left-padded selector with push4 (reduces bytecode),
                // mem[28:32] = selector
                mstore(0, InvalidZoneParameterEncoding_error_selector)
                // revert(abi.encodeWithSignature(
                //  "InvalidZoneParameterEncoding()"
                // ))
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
    function _assertValidSubstandardAndGetExpectedFulfiller(bytes32 orderHash)
        internal
        pure
        returns (address expectedFulfiller)
    {
        // Revert if the expected fulfiller is not the zero address and does
        // not match the actual fulfiller or if the expected received
        // identifier does not match the actual received identifier.
        assembly {
            // Get the actual fulfiller.
            let actualFulfiller := calldataload(Zone_parameters_fulfiller_cdPtr)
            let extraDataPtr := calldataload(Zone_extraData_cdPtr)
            let considerationPtr := calldataload(Zone_consideration_head_cdPtr)

            // Get the expected fulfiller.
            expectedFulfiller := shr(
                96,
                calldataload(add(expectedFulfiller_offset, extraDataPtr))
            )

            // Get the actual received identifier.
            let actualReceivedIdentifier := calldataload(
                add(actualReceivedIdentifier_offset, considerationPtr)
            )

            // Get the expected received identifier.
            let expectedReceivedIdentifier := calldataload(
                add(expectedReceivedIdentifier_offset, extraDataPtr)
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
                //     "InvalidFulfiller(address,address,bytes32)",
                //     expectedFulfiller,
                //     actualFulfiller,
                //     orderHash
                // ))
                revert(0x1c, InvalidFulfiller_error_length)
            }

            // Revert if expected received item does not match the actual
            // received item.
            if iszero(
                eq(expectedReceivedIdentifier, actualReceivedIdentifier)
            ) {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, InvalidReceivedItem_error_selector)
                mstore(
                    InvalidReceivedItem_error_expectedReceivedItem_ptr,
                    expectedReceivedIdentifier
                )
                mstore(
                    InvalidReceivedItem_error_actualReceivedItem_ptr,
                    actualReceivedIdentifier
                )
                mstore(InvalidReceivedItem_error_orderHash_ptr, orderHash)
                // revert(abi.encodeWithSignature(
                //     "InvalidReceivedItem(uint256,uint256,bytes32)",
                //     expectedReceivedIdentifier,
                //     actualReceievedIdentifier,
                //     orderHash
                // ))
                revert(0x1c, InvalidReceivedItem_error_length)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
pragma solidity ^0.8.19;

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

// @dev Function selectors used in the fallback function..
bytes4 constant UPDATE_SIGNER_SELECTOR = 0xf460590b;
bytes4 constant GET_ACTIVE_SIGNERS_SELECTOR = 0xa784b80c;
bytes4 constant IS_ACTIVE_SIGNER_SELECTOR = 0x7dff5a79;
bytes4 constant SUPPORTS_INTERFACE_SELECTOR = 0x01ffc9a7;

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
 *  error InvalidReceivedItem(uint256 expectedReceivedIdentifier, uint256 actualReceievedIdentifier, bytes32 orderHash)
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: expectedReceivedIdentifier
 *    - 0x40: actualReceievedIdentifier
 *    - 0x60: orderHash
 * Revert buffer is memory[0x1c:0x80]
 */
uint256 constant InvalidReceivedItem_error_selector = 0xb36c03e8;
uint256 constant InvalidReceivedItem_error_expectedReceivedItem_ptr = 0x20;
uint256 constant InvalidReceivedItem_error_actualReceivedItem_ptr = 0x40;
uint256 constant InvalidReceivedItem_error_orderHash_ptr = 0x60;
uint256 constant InvalidReceivedItem_error_length = 0x64;

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

/*
 *  error UnsupportedFunctionSelector()
 *    - Defined in SignedZoneEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant UnsupportedFunctionSelector_error_selector = 0x54c91b87;
uint256 constant UnsupportedFunctionSelector_error_length = 0x04;

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
uint256 constant actualReceivedIdentifier_offset = 0x84;
uint256 constant expectedReceivedIdentifier_offset = 0xa2;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @notice SignedZoneControllerEventsAndErrors contains errors and events
 *         related to deploying and managing new signed zones.
 */
interface SignedZoneControllerEventsAndErrors {
    /**
     * @dev Emit an event whenever a new zone is created.
     *
     * @param zoneAddress       The address of the zone.
     * @param zoneName          The name for the zone returned in
     *                          getSeaportMetadata().
     * @param apiEndpoint       The API endpoint where orders for this zone can
     *                          be signed.
     * @param documentationURI  The URI to the documentation describing the
     *                          behavior of the contract.
     *                          Request and response payloads are defined in
     *                          SIP-7.
     * @param salt              The salt used to deploy the zone.
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
     * @dev Revert with an error when attempting to update zone information or
     *      transfer ownership of a zone when the caller is not the owner of
     *      the zone in question.
     */
    error CallerIsNotOwner(address zone);

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
    error NewPotentialOwnerIsNullAddress(address zone);

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
     * @dev Revert with an error if a new signer is the null address.
     */
    error SignerCannotBeNullAddress();

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
pragma solidity ^0.8.13;

import { ZoneParameters, Schema } from "../lib/ConsiderationStructs.sol";

/**
 * @title  ZoneInterface
 * @notice Contains functions exposed by a zone.
 */
interface ZoneInterface {
    /**
     * @dev Validates an order.
     *
     * @param zoneParameters The context about the order fulfillment and any
     *                       supplied extraData.
     *
     * @return validOrderMagicValue The magic value that indicates a valid
     *                              order.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external returns (bytes4 validOrderMagicValue);

    /**
     * @dev Returns the metadata for this zone.
     *
     * @return name The name of the zone.
     * @return schemas The schemas that the zone implements.
     */
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

import {
    BasicOrderType,
    ItemType,
    OrderType,
    Side
} from "./ConsiderationEnums.sol";

import {
    CalldataPointer,
    MemoryPointer
} from "../helpers/PointerLibraries.sol";

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

using StructPointers for OrderComponents global;
using StructPointers for OfferItem global;
using StructPointers for ConsiderationItem global;
using StructPointers for SpentItem global;
using StructPointers for ReceivedItem global;
using StructPointers for BasicOrderParameters global;
using StructPointers for AdditionalRecipient global;
using StructPointers for OrderParameters global;
using StructPointers for Order global;
using StructPointers for AdvancedOrder global;
using StructPointers for OrderStatus global;
using StructPointers for CriteriaResolver global;
using StructPointers for Fulfillment global;
using StructPointers for FulfillmentComponent global;
using StructPointers for Execution global;
using StructPointers for ZoneParameters global;

/**
 * @dev This library provides a set of functions for converting structs to
 *      pointers.
 */
library StructPointers {
    /**
     * @dev Get a MemoryPointer from OrderComponents.
     *
     * @param obj The OrderComponents object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderComponents memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderComponents.
     *
     * @param obj The OrderComponents object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderComponents calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OfferItem.
     *
     * @param obj The OfferItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OfferItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OfferItem.
     *
     * @param obj The OfferItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OfferItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ConsiderationItem.
     *
     * @param obj The ConsiderationItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ConsiderationItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ConsiderationItem.
     *
     * @param obj The ConsiderationItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ConsiderationItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from SpentItem.
     *
     * @param obj The SpentItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        SpentItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from SpentItem.
     *
     * @param obj The SpentItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        SpentItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ReceivedItem.
     *
     * @param obj The ReceivedItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ReceivedItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ReceivedItem.
     *
     * @param obj The ReceivedItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ReceivedItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from BasicOrderParameters.
     *
     * @param obj The BasicOrderParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        BasicOrderParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from BasicOrderParameters.
     *
     * @param obj The BasicOrderParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        BasicOrderParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from AdditionalRecipient.
     *
     * @param obj The AdditionalRecipient object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        AdditionalRecipient memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from AdditionalRecipient.
     *
     * @param obj The AdditionalRecipient object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        AdditionalRecipient calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OrderParameters.
     *
     * @param obj The OrderParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderParameters.
     *
     * @param obj The OrderParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Order.
     *
     * @param obj The Order object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Order memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Order.
     *
     * @param obj The Order object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Order calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from AdvancedOrder.
     *
     * @param obj The AdvancedOrder object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        AdvancedOrder memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from AdvancedOrder.
     *
     * @param obj The AdvancedOrder object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        AdvancedOrder calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OrderStatus.
     *
     * @param obj The OrderStatus object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderStatus memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderStatus.
     *
     * @param obj The OrderStatus object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderStatus calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from CriteriaResolver.
     *
     * @param obj The CriteriaResolver object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        CriteriaResolver memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from CriteriaResolver.
     *
     * @param obj The CriteriaResolver object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        CriteriaResolver calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Fulfillment.
     *
     * @param obj The Fulfillment object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Fulfillment memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Fulfillment.
     *
     * @param obj The Fulfillment object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Fulfillment calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from FulfillmentComponent.
     *
     * @param obj The FulfillmentComponent object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        FulfillmentComponent memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from FulfillmentComponent.
     *
     * @param obj The FulfillmentComponent object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        FulfillmentComponent calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Execution.
     *
     * @param obj The Execution object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Execution memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Execution.
     *
     * @param obj The Execution object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Execution calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ZoneParameters.
     *
     * @param obj The ZoneParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ZoneParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ZoneParameters.
     *
     * @param obj The ZoneParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ZoneParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
     * @dev Revert with an error if the received item does not match.
     */
    error InvalidReceivedItem(
        uint256 expectedReceivedIdentifier,
        uint256 actualReceievedIdentifier,
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

    /**
     * @dev Revert when an unsupported function selector is found.
     */
    error UnsupportedFunctionSelector();
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

enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

type CalldataPointer is uint256;

type ReturndataPointer is uint256;

type MemoryPointer is uint256;

using CalldataPointerLib for CalldataPointer global;
using MemoryPointerLib for MemoryPointer global;
using ReturndataPointerLib for ReturndataPointer global;

using CalldataReaders for CalldataPointer global;
using ReturndataReaders for ReturndataPointer global;
using MemoryReaders for MemoryPointer global;
using MemoryWriters for MemoryPointer global;

CalldataPointer constant CalldataStart = CalldataPointer.wrap(0x04);
MemoryPointer constant FreeMemoryPPtr = MemoryPointer.wrap(0x40);
uint256 constant IdentityPrecompileAddress = 0x4;
uint256 constant OffsetOrLengthMask = 0xffffffff;
uint256 constant _OneWord = 0x20;
uint256 constant _FreeMemoryPointerSlot = 0x40;

/// @dev Allocates `size` bytes in memory by increasing the free memory pointer
///    and returns the memory pointer to the first byte of the allocated region.
// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function malloc(uint256 size) pure returns (MemoryPointer mPtr) {
    assembly {
        mPtr := mload(_FreeMemoryPointerSlot)
        mstore(_FreeMemoryPointerSlot, add(mPtr, size))
    }
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function getFreeMemoryPointer() pure returns (MemoryPointer mPtr) {
    mPtr = FreeMemoryPPtr.readMemoryPointer();
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function setFreeMemoryPointer(MemoryPointer mPtr) pure {
    FreeMemoryPPtr.write(mPtr);
}

library CalldataPointerLib {
    function lt(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    /// @dev Resolves an offset stored at `cdPtr + headOffset` to a calldata.
    ///      pointer `cdPtr` must point to some parent object with a dynamic
    ///      type's head stored at `cdPtr + headOffset`.
    function pptr(
        CalldataPointer cdPtr,
        uint256 headOffset
    ) internal pure returns (CalldataPointer cdPtrChild) {
        cdPtrChild = cdPtr.offset(
            cdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
        );
    }

    /// @dev Resolves an offset stored at `cdPtr` to a calldata pointer.
    ///      `cdPtr` must point to some parent object with a dynamic type as its
    ///      first member, e.g. `struct { bytes data; }`
    function pptr(
        CalldataPointer cdPtr
    ) internal pure returns (CalldataPointer cdPtrChild) {
        cdPtrChild = cdPtr.offset(cdPtr.readUint256() & OffsetOrLengthMask);
    }

    /// @dev Returns the calldata pointer one word after `cdPtr`.
    function next(
        CalldataPointer cdPtr
    ) internal pure returns (CalldataPointer cdPtrNext) {
        assembly {
            cdPtrNext := add(cdPtr, _OneWord)
        }
    }

    /// @dev Returns the calldata pointer `_offset` bytes after `cdPtr`.
    function offset(
        CalldataPointer cdPtr,
        uint256 _offset
    ) internal pure returns (CalldataPointer cdPtrNext) {
        assembly {
            cdPtrNext := add(cdPtr, _offset)
        }
    }

    /// @dev Copies `size` bytes from calldata starting at `src` to memory at
    ///      `dst`.
    function copy(
        CalldataPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal pure {
        assembly {
            calldatacopy(dst, src, size)
        }
    }
}

library ReturndataPointerLib {
    function lt(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    /// @dev Resolves an offset stored at `rdPtr + headOffset` to a returndata
    ///      pointer. `rdPtr` must point to some parent object with a dynamic
    ///      type's head stored at `rdPtr + headOffset`.
    function pptr(
        ReturndataPointer rdPtr,
        uint256 headOffset
    ) internal pure returns (ReturndataPointer rdPtrChild) {
        rdPtrChild = rdPtr.offset(
            rdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
        );
    }

    /// @dev Resolves an offset stored at `rdPtr` to a returndata pointer.
    ///    `rdPtr` must point to some parent object with a dynamic type as its
    ///    first member, e.g. `struct { bytes data; }`
    function pptr(
        ReturndataPointer rdPtr
    ) internal pure returns (ReturndataPointer rdPtrChild) {
        rdPtrChild = rdPtr.offset(rdPtr.readUint256() & OffsetOrLengthMask);
    }

    /// @dev Returns the returndata pointer one word after `cdPtr`.
    function next(
        ReturndataPointer rdPtr
    ) internal pure returns (ReturndataPointer rdPtrNext) {
        assembly {
            rdPtrNext := add(rdPtr, _OneWord)
        }
    }

    /// @dev Returns the returndata pointer `_offset` bytes after `cdPtr`.
    function offset(
        ReturndataPointer rdPtr,
        uint256 _offset
    ) internal pure returns (ReturndataPointer rdPtrNext) {
        assembly {
            rdPtrNext := add(rdPtr, _offset)
        }
    }

    /// @dev Copies `size` bytes from returndata starting at `src` to memory at
    /// `dst`.
    function copy(
        ReturndataPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal pure {
        assembly {
            returndatacopy(dst, src, size)
        }
    }
}

library MemoryPointerLib {
    function copy(
        MemoryPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal view {
        assembly {
            let success := staticcall(
                gas(),
                IdentityPrecompileAddress,
                src,
                size,
                dst,
                size
            )
            if or(iszero(returndatasize()), iszero(success)) {
                revert(0, 0)
            }
        }
    }

    function lt(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    /// @dev Returns the memory pointer one word after `mPtr`.
    function next(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer mPtrNext) {
        assembly {
            mPtrNext := add(mPtr, _OneWord)
        }
    }

    /// @dev Returns the memory pointer `_offset` bytes after `mPtr`.
    function offset(
        MemoryPointer mPtr,
        uint256 _offset
    ) internal pure returns (MemoryPointer mPtrNext) {
        assembly {
            mPtrNext := add(mPtr, _offset)
        }
    }

    /// @dev Resolves a pointer pointer at `mPtr + headOffset` to a memory
    ///    pointer. `mPtr` must point to some parent object with a dynamic
    ///    type's pointer stored at `mPtr + headOffset`.
    function pptr(
        MemoryPointer mPtr,
        uint256 headOffset
    ) internal pure returns (MemoryPointer mPtrChild) {
        mPtrChild = mPtr.offset(headOffset).readMemoryPointer();
    }

    /// @dev Resolves a pointer pointer stored at `mPtr` to a memory pointer.
    ///    `mPtr` must point to some parent object with a dynamic type as its
    ///    first member, e.g. `struct { bytes data; }`
    function pptr(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer mPtrChild) {
        mPtrChild = mPtr.readMemoryPointer();
    }
}

library CalldataReaders {
    /// @dev Reads the value at `cdPtr` and applies a mask to return only the
    ///    last 4 bytes.
    function readMaskedUint256(
        CalldataPointer cdPtr
    ) internal pure returns (uint256 value) {
        value = cdPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `cdPtr` in calldata.
    function readBool(
        CalldataPointer cdPtr
    ) internal pure returns (bool value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the address at `cdPtr` in calldata.
    function readAddress(
        CalldataPointer cdPtr
    ) internal pure returns (address value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes1 at `cdPtr` in calldata.
    function readBytes1(
        CalldataPointer cdPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes2 at `cdPtr` in calldata.
    function readBytes2(
        CalldataPointer cdPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes3 at `cdPtr` in calldata.
    function readBytes3(
        CalldataPointer cdPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes4 at `cdPtr` in calldata.
    function readBytes4(
        CalldataPointer cdPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes5 at `cdPtr` in calldata.
    function readBytes5(
        CalldataPointer cdPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes6 at `cdPtr` in calldata.
    function readBytes6(
        CalldataPointer cdPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes7 at `cdPtr` in calldata.
    function readBytes7(
        CalldataPointer cdPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes8 at `cdPtr` in calldata.
    function readBytes8(
        CalldataPointer cdPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes9 at `cdPtr` in calldata.
    function readBytes9(
        CalldataPointer cdPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes10 at `cdPtr` in calldata.
    function readBytes10(
        CalldataPointer cdPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes11 at `cdPtr` in calldata.
    function readBytes11(
        CalldataPointer cdPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes12 at `cdPtr` in calldata.
    function readBytes12(
        CalldataPointer cdPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes13 at `cdPtr` in calldata.
    function readBytes13(
        CalldataPointer cdPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes14 at `cdPtr` in calldata.
    function readBytes14(
        CalldataPointer cdPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes15 at `cdPtr` in calldata.
    function readBytes15(
        CalldataPointer cdPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes16 at `cdPtr` in calldata.
    function readBytes16(
        CalldataPointer cdPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes17 at `cdPtr` in calldata.
    function readBytes17(
        CalldataPointer cdPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes18 at `cdPtr` in calldata.
    function readBytes18(
        CalldataPointer cdPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes19 at `cdPtr` in calldata.
    function readBytes19(
        CalldataPointer cdPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes20 at `cdPtr` in calldata.
    function readBytes20(
        CalldataPointer cdPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes21 at `cdPtr` in calldata.
    function readBytes21(
        CalldataPointer cdPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes22 at `cdPtr` in calldata.
    function readBytes22(
        CalldataPointer cdPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes23 at `cdPtr` in calldata.
    function readBytes23(
        CalldataPointer cdPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes24 at `cdPtr` in calldata.
    function readBytes24(
        CalldataPointer cdPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes25 at `cdPtr` in calldata.
    function readBytes25(
        CalldataPointer cdPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes26 at `cdPtr` in calldata.
    function readBytes26(
        CalldataPointer cdPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes27 at `cdPtr` in calldata.
    function readBytes27(
        CalldataPointer cdPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes28 at `cdPtr` in calldata.
    function readBytes28(
        CalldataPointer cdPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes29 at `cdPtr` in calldata.
    function readBytes29(
        CalldataPointer cdPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes30 at `cdPtr` in calldata.
    function readBytes30(
        CalldataPointer cdPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes31 at `cdPtr` in calldata.
    function readBytes31(
        CalldataPointer cdPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes32 at `cdPtr` in calldata.
    function readBytes32(
        CalldataPointer cdPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint8 at `cdPtr` in calldata.
    function readUint8(
        CalldataPointer cdPtr
    ) internal pure returns (uint8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint16 at `cdPtr` in calldata.
    function readUint16(
        CalldataPointer cdPtr
    ) internal pure returns (uint16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint24 at `cdPtr` in calldata.
    function readUint24(
        CalldataPointer cdPtr
    ) internal pure returns (uint24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint32 at `cdPtr` in calldata.
    function readUint32(
        CalldataPointer cdPtr
    ) internal pure returns (uint32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint40 at `cdPtr` in calldata.
    function readUint40(
        CalldataPointer cdPtr
    ) internal pure returns (uint40 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint48 at `cdPtr` in calldata.
    function readUint48(
        CalldataPointer cdPtr
    ) internal pure returns (uint48 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint56 at `cdPtr` in calldata.
    function readUint56(
        CalldataPointer cdPtr
    ) internal pure returns (uint56 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint64 at `cdPtr` in calldata.
    function readUint64(
        CalldataPointer cdPtr
    ) internal pure returns (uint64 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint72 at `cdPtr` in calldata.
    function readUint72(
        CalldataPointer cdPtr
    ) internal pure returns (uint72 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint80 at `cdPtr` in calldata.
    function readUint80(
        CalldataPointer cdPtr
    ) internal pure returns (uint80 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint88 at `cdPtr` in calldata.
    function readUint88(
        CalldataPointer cdPtr
    ) internal pure returns (uint88 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint96 at `cdPtr` in calldata.
    function readUint96(
        CalldataPointer cdPtr
    ) internal pure returns (uint96 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint104 at `cdPtr` in calldata.
    function readUint104(
        CalldataPointer cdPtr
    ) internal pure returns (uint104 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint112 at `cdPtr` in calldata.
    function readUint112(
        CalldataPointer cdPtr
    ) internal pure returns (uint112 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint120 at `cdPtr` in calldata.
    function readUint120(
        CalldataPointer cdPtr
    ) internal pure returns (uint120 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint128 at `cdPtr` in calldata.
    function readUint128(
        CalldataPointer cdPtr
    ) internal pure returns (uint128 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint136 at `cdPtr` in calldata.
    function readUint136(
        CalldataPointer cdPtr
    ) internal pure returns (uint136 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint144 at `cdPtr` in calldata.
    function readUint144(
        CalldataPointer cdPtr
    ) internal pure returns (uint144 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint152 at `cdPtr` in calldata.
    function readUint152(
        CalldataPointer cdPtr
    ) internal pure returns (uint152 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint160 at `cdPtr` in calldata.
    function readUint160(
        CalldataPointer cdPtr
    ) internal pure returns (uint160 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint168 at `cdPtr` in calldata.
    function readUint168(
        CalldataPointer cdPtr
    ) internal pure returns (uint168 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint176 at `cdPtr` in calldata.
    function readUint176(
        CalldataPointer cdPtr
    ) internal pure returns (uint176 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint184 at `cdPtr` in calldata.
    function readUint184(
        CalldataPointer cdPtr
    ) internal pure returns (uint184 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint192 at `cdPtr` in calldata.
    function readUint192(
        CalldataPointer cdPtr
    ) internal pure returns (uint192 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint200 at `cdPtr` in calldata.
    function readUint200(
        CalldataPointer cdPtr
    ) internal pure returns (uint200 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint208 at `cdPtr` in calldata.
    function readUint208(
        CalldataPointer cdPtr
    ) internal pure returns (uint208 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint216 at `cdPtr` in calldata.
    function readUint216(
        CalldataPointer cdPtr
    ) internal pure returns (uint216 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint224 at `cdPtr` in calldata.
    function readUint224(
        CalldataPointer cdPtr
    ) internal pure returns (uint224 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint232 at `cdPtr` in calldata.
    function readUint232(
        CalldataPointer cdPtr
    ) internal pure returns (uint232 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint240 at `cdPtr` in calldata.
    function readUint240(
        CalldataPointer cdPtr
    ) internal pure returns (uint240 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint248 at `cdPtr` in calldata.
    function readUint248(
        CalldataPointer cdPtr
    ) internal pure returns (uint248 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint256 at `cdPtr` in calldata.
    function readUint256(
        CalldataPointer cdPtr
    ) internal pure returns (uint256 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int8 at `cdPtr` in calldata.
    function readInt8(
        CalldataPointer cdPtr
    ) internal pure returns (int8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int16 at `cdPtr` in calldata.
    function readInt16(
        CalldataPointer cdPtr
    ) internal pure returns (int16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int24 at `cdPtr` in calldata.
    function readInt24(
        CalldataPointer cdPtr
    ) internal pure returns (int24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int32 at `cdPtr` in calldata.
    function readInt32(
        CalldataPointer cdPtr
    ) internal pure returns (int32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int40 at `cdPtr` in calldata.
    function readInt40(
        CalldataPointer cdPtr
    ) internal pure returns (int40 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int48 at `cdPtr` in calldata.
    function readInt48(
        CalldataPointer cdPtr
    ) internal pure returns (int48 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int56 at `cdPtr` in calldata.
    function readInt56(
        CalldataPointer cdPtr
    ) internal pure returns (int56 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int64 at `cdPtr` in calldata.
    function readInt64(
        CalldataPointer cdPtr
    ) internal pure returns (int64 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int72 at `cdPtr` in calldata.
    function readInt72(
        CalldataPointer cdPtr
    ) internal pure returns (int72 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int80 at `cdPtr` in calldata.
    function readInt80(
        CalldataPointer cdPtr
    ) internal pure returns (int80 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int88 at `cdPtr` in calldata.
    function readInt88(
        CalldataPointer cdPtr
    ) internal pure returns (int88 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int96 at `cdPtr` in calldata.
    function readInt96(
        CalldataPointer cdPtr
    ) internal pure returns (int96 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int104 at `cdPtr` in calldata.
    function readInt104(
        CalldataPointer cdPtr
    ) internal pure returns (int104 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int112 at `cdPtr` in calldata.
    function readInt112(
        CalldataPointer cdPtr
    ) internal pure returns (int112 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int120 at `cdPtr` in calldata.
    function readInt120(
        CalldataPointer cdPtr
    ) internal pure returns (int120 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int128 at `cdPtr` in calldata.
    function readInt128(
        CalldataPointer cdPtr
    ) internal pure returns (int128 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int136 at `cdPtr` in calldata.
    function readInt136(
        CalldataPointer cdPtr
    ) internal pure returns (int136 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int144 at `cdPtr` in calldata.
    function readInt144(
        CalldataPointer cdPtr
    ) internal pure returns (int144 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int152 at `cdPtr` in calldata.
    function readInt152(
        CalldataPointer cdPtr
    ) internal pure returns (int152 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int160 at `cdPtr` in calldata.
    function readInt160(
        CalldataPointer cdPtr
    ) internal pure returns (int160 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int168 at `cdPtr` in calldata.
    function readInt168(
        CalldataPointer cdPtr
    ) internal pure returns (int168 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int176 at `cdPtr` in calldata.
    function readInt176(
        CalldataPointer cdPtr
    ) internal pure returns (int176 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int184 at `cdPtr` in calldata.
    function readInt184(
        CalldataPointer cdPtr
    ) internal pure returns (int184 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int192 at `cdPtr` in calldata.
    function readInt192(
        CalldataPointer cdPtr
    ) internal pure returns (int192 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int200 at `cdPtr` in calldata.
    function readInt200(
        CalldataPointer cdPtr
    ) internal pure returns (int200 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int208 at `cdPtr` in calldata.
    function readInt208(
        CalldataPointer cdPtr
    ) internal pure returns (int208 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int216 at `cdPtr` in calldata.
    function readInt216(
        CalldataPointer cdPtr
    ) internal pure returns (int216 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int224 at `cdPtr` in calldata.
    function readInt224(
        CalldataPointer cdPtr
    ) internal pure returns (int224 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int232 at `cdPtr` in calldata.
    function readInt232(
        CalldataPointer cdPtr
    ) internal pure returns (int232 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int240 at `cdPtr` in calldata.
    function readInt240(
        CalldataPointer cdPtr
    ) internal pure returns (int240 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int248 at `cdPtr` in calldata.
    function readInt248(
        CalldataPointer cdPtr
    ) internal pure returns (int248 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int256 at `cdPtr` in calldata.
    function readInt256(
        CalldataPointer cdPtr
    ) internal pure returns (int256 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }
}

library ReturndataReaders {
    /// @dev Reads value at `rdPtr` & applies a mask to return only last 4 bytes
    function readMaskedUint256(
        ReturndataPointer rdPtr
    ) internal pure returns (uint256 value) {
        value = rdPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `rdPtr` in returndata.
    function readBool(
        ReturndataPointer rdPtr
    ) internal pure returns (bool value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the address at `rdPtr` in returndata.
    function readAddress(
        ReturndataPointer rdPtr
    ) internal pure returns (address value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes1 at `rdPtr` in returndata.
    function readBytes1(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes2 at `rdPtr` in returndata.
    function readBytes2(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes3 at `rdPtr` in returndata.
    function readBytes3(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes4 at `rdPtr` in returndata.
    function readBytes4(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes5 at `rdPtr` in returndata.
    function readBytes5(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes6 at `rdPtr` in returndata.
    function readBytes6(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes7 at `rdPtr` in returndata.
    function readBytes7(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes8 at `rdPtr` in returndata.
    function readBytes8(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes9 at `rdPtr` in returndata.
    function readBytes9(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes10 at `rdPtr` in returndata.
    function readBytes10(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes11 at `rdPtr` in returndata.
    function readBytes11(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes12 at `rdPtr` in returndata.
    function readBytes12(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes13 at `rdPtr` in returndata.
    function readBytes13(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes14 at `rdPtr` in returndata.
    function readBytes14(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes15 at `rdPtr` in returndata.
    function readBytes15(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes16 at `rdPtr` in returndata.
    function readBytes16(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes17 at `rdPtr` in returndata.
    function readBytes17(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes18 at `rdPtr` in returndata.
    function readBytes18(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes19 at `rdPtr` in returndata.
    function readBytes19(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes20 at `rdPtr` in returndata.
    function readBytes20(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes21 at `rdPtr` in returndata.
    function readBytes21(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes22 at `rdPtr` in returndata.
    function readBytes22(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes23 at `rdPtr` in returndata.
    function readBytes23(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes24 at `rdPtr` in returndata.
    function readBytes24(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes25 at `rdPtr` in returndata.
    function readBytes25(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes26 at `rdPtr` in returndata.
    function readBytes26(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes27 at `rdPtr` in returndata.
    function readBytes27(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes28 at `rdPtr` in returndata.
    function readBytes28(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes29 at `rdPtr` in returndata.
    function readBytes29(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes30 at `rdPtr` in returndata.
    function readBytes30(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes31 at `rdPtr` in returndata.
    function readBytes31(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes32 at `rdPtr` in returndata.
    function readBytes32(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint8 at `rdPtr` in returndata.
    function readUint8(
        ReturndataPointer rdPtr
    ) internal pure returns (uint8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint16 at `rdPtr` in returndata.
    function readUint16(
        ReturndataPointer rdPtr
    ) internal pure returns (uint16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint24 at `rdPtr` in returndata.
    function readUint24(
        ReturndataPointer rdPtr
    ) internal pure returns (uint24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint32 at `rdPtr` in returndata.
    function readUint32(
        ReturndataPointer rdPtr
    ) internal pure returns (uint32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint40 at `rdPtr` in returndata.
    function readUint40(
        ReturndataPointer rdPtr
    ) internal pure returns (uint40 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint48 at `rdPtr` in returndata.
    function readUint48(
        ReturndataPointer rdPtr
    ) internal pure returns (uint48 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint56 at `rdPtr` in returndata.
    function readUint56(
        ReturndataPointer rdPtr
    ) internal pure returns (uint56 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint64 at `rdPtr` in returndata.
    function readUint64(
        ReturndataPointer rdPtr
    ) internal pure returns (uint64 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint72 at `rdPtr` in returndata.
    function readUint72(
        ReturndataPointer rdPtr
    ) internal pure returns (uint72 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint80 at `rdPtr` in returndata.
    function readUint80(
        ReturndataPointer rdPtr
    ) internal pure returns (uint80 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint88 at `rdPtr` in returndata.
    function readUint88(
        ReturndataPointer rdPtr
    ) internal pure returns (uint88 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint96 at `rdPtr` in returndata.
    function readUint96(
        ReturndataPointer rdPtr
    ) internal pure returns (uint96 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint104 at `rdPtr` in returndata.
    function readUint104(
        ReturndataPointer rdPtr
    ) internal pure returns (uint104 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint112 at `rdPtr` in returndata.
    function readUint112(
        ReturndataPointer rdPtr
    ) internal pure returns (uint112 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint120 at `rdPtr` in returndata.
    function readUint120(
        ReturndataPointer rdPtr
    ) internal pure returns (uint120 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint128 at `rdPtr` in returndata.
    function readUint128(
        ReturndataPointer rdPtr
    ) internal pure returns (uint128 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint136 at `rdPtr` in returndata.
    function readUint136(
        ReturndataPointer rdPtr
    ) internal pure returns (uint136 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint144 at `rdPtr` in returndata.
    function readUint144(
        ReturndataPointer rdPtr
    ) internal pure returns (uint144 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint152 at `rdPtr` in returndata.
    function readUint152(
        ReturndataPointer rdPtr
    ) internal pure returns (uint152 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint160 at `rdPtr` in returndata.
    function readUint160(
        ReturndataPointer rdPtr
    ) internal pure returns (uint160 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint168 at `rdPtr` in returndata.
    function readUint168(
        ReturndataPointer rdPtr
    ) internal pure returns (uint168 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint176 at `rdPtr` in returndata.
    function readUint176(
        ReturndataPointer rdPtr
    ) internal pure returns (uint176 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint184 at `rdPtr` in returndata.
    function readUint184(
        ReturndataPointer rdPtr
    ) internal pure returns (uint184 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint192 at `rdPtr` in returndata.
    function readUint192(
        ReturndataPointer rdPtr
    ) internal pure returns (uint192 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint200 at `rdPtr` in returndata.
    function readUint200(
        ReturndataPointer rdPtr
    ) internal pure returns (uint200 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint208 at `rdPtr` in returndata.
    function readUint208(
        ReturndataPointer rdPtr
    ) internal pure returns (uint208 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint216 at `rdPtr` in returndata.
    function readUint216(
        ReturndataPointer rdPtr
    ) internal pure returns (uint216 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint224 at `rdPtr` in returndata.
    function readUint224(
        ReturndataPointer rdPtr
    ) internal pure returns (uint224 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint232 at `rdPtr` in returndata.
    function readUint232(
        ReturndataPointer rdPtr
    ) internal pure returns (uint232 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint240 at `rdPtr` in returndata.
    function readUint240(
        ReturndataPointer rdPtr
    ) internal pure returns (uint240 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint248 at `rdPtr` in returndata.
    function readUint248(
        ReturndataPointer rdPtr
    ) internal pure returns (uint248 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint256 at `rdPtr` in returndata.
    function readUint256(
        ReturndataPointer rdPtr
    ) internal pure returns (uint256 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int8 at `rdPtr` in returndata.
    function readInt8(
        ReturndataPointer rdPtr
    ) internal pure returns (int8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int16 at `rdPtr` in returndata.
    function readInt16(
        ReturndataPointer rdPtr
    ) internal pure returns (int16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int24 at `rdPtr` in returndata.
    function readInt24(
        ReturndataPointer rdPtr
    ) internal pure returns (int24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int32 at `rdPtr` in returndata.
    function readInt32(
        ReturndataPointer rdPtr
    ) internal pure returns (int32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int40 at `rdPtr` in returndata.
    function readInt40(
        ReturndataPointer rdPtr
    ) internal pure returns (int40 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int48 at `rdPtr` in returndata.
    function readInt48(
        ReturndataPointer rdPtr
    ) internal pure returns (int48 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int56 at `rdPtr` in returndata.
    function readInt56(
        ReturndataPointer rdPtr
    ) internal pure returns (int56 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int64 at `rdPtr` in returndata.
    function readInt64(
        ReturndataPointer rdPtr
    ) internal pure returns (int64 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int72 at `rdPtr` in returndata.
    function readInt72(
        ReturndataPointer rdPtr
    ) internal pure returns (int72 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int80 at `rdPtr` in returndata.
    function readInt80(
        ReturndataPointer rdPtr
    ) internal pure returns (int80 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int88 at `rdPtr` in returndata.
    function readInt88(
        ReturndataPointer rdPtr
    ) internal pure returns (int88 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int96 at `rdPtr` in returndata.
    function readInt96(
        ReturndataPointer rdPtr
    ) internal pure returns (int96 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int104 at `rdPtr` in returndata.
    function readInt104(
        ReturndataPointer rdPtr
    ) internal pure returns (int104 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int112 at `rdPtr` in returndata.
    function readInt112(
        ReturndataPointer rdPtr
    ) internal pure returns (int112 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int120 at `rdPtr` in returndata.
    function readInt120(
        ReturndataPointer rdPtr
    ) internal pure returns (int120 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int128 at `rdPtr` in returndata.
    function readInt128(
        ReturndataPointer rdPtr
    ) internal pure returns (int128 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int136 at `rdPtr` in returndata.
    function readInt136(
        ReturndataPointer rdPtr
    ) internal pure returns (int136 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int144 at `rdPtr` in returndata.
    function readInt144(
        ReturndataPointer rdPtr
    ) internal pure returns (int144 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int152 at `rdPtr` in returndata.
    function readInt152(
        ReturndataPointer rdPtr
    ) internal pure returns (int152 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int160 at `rdPtr` in returndata.
    function readInt160(
        ReturndataPointer rdPtr
    ) internal pure returns (int160 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int168 at `rdPtr` in returndata.
    function readInt168(
        ReturndataPointer rdPtr
    ) internal pure returns (int168 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int176 at `rdPtr` in returndata.
    function readInt176(
        ReturndataPointer rdPtr
    ) internal pure returns (int176 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int184 at `rdPtr` in returndata.
    function readInt184(
        ReturndataPointer rdPtr
    ) internal pure returns (int184 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int192 at `rdPtr` in returndata.
    function readInt192(
        ReturndataPointer rdPtr
    ) internal pure returns (int192 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int200 at `rdPtr` in returndata.
    function readInt200(
        ReturndataPointer rdPtr
    ) internal pure returns (int200 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int208 at `rdPtr` in returndata.
    function readInt208(
        ReturndataPointer rdPtr
    ) internal pure returns (int208 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int216 at `rdPtr` in returndata.
    function readInt216(
        ReturndataPointer rdPtr
    ) internal pure returns (int216 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int224 at `rdPtr` in returndata.
    function readInt224(
        ReturndataPointer rdPtr
    ) internal pure returns (int224 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int232 at `rdPtr` in returndata.
    function readInt232(
        ReturndataPointer rdPtr
    ) internal pure returns (int232 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int240 at `rdPtr` in returndata.
    function readInt240(
        ReturndataPointer rdPtr
    ) internal pure returns (int240 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int248 at `rdPtr` in returndata.
    function readInt248(
        ReturndataPointer rdPtr
    ) internal pure returns (int248 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int256 at `rdPtr` in returndata.
    function readInt256(
        ReturndataPointer rdPtr
    ) internal pure returns (int256 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }
}

library MemoryReaders {
    /// @dev Reads the memory pointer at `mPtr` in memory.
    function readMemoryPointer(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads value at `mPtr` & applies a mask to return only last 4 bytes
    function readMaskedUint256(
        MemoryPointer mPtr
    ) internal pure returns (uint256 value) {
        value = mPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `mPtr` in memory.
    function readBool(MemoryPointer mPtr) internal pure returns (bool value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the address at `mPtr` in memory.
    function readAddress(
        MemoryPointer mPtr
    ) internal pure returns (address value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes1 at `mPtr` in memory.
    function readBytes1(
        MemoryPointer mPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes2 at `mPtr` in memory.
    function readBytes2(
        MemoryPointer mPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes3 at `mPtr` in memory.
    function readBytes3(
        MemoryPointer mPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes4 at `mPtr` in memory.
    function readBytes4(
        MemoryPointer mPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes5 at `mPtr` in memory.
    function readBytes5(
        MemoryPointer mPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes6 at `mPtr` in memory.
    function readBytes6(
        MemoryPointer mPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes7 at `mPtr` in memory.
    function readBytes7(
        MemoryPointer mPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes8 at `mPtr` in memory.
    function readBytes8(
        MemoryPointer mPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes9 at `mPtr` in memory.
    function readBytes9(
        MemoryPointer mPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes10 at `mPtr` in memory.
    function readBytes10(
        MemoryPointer mPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes11 at `mPtr` in memory.
    function readBytes11(
        MemoryPointer mPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes12 at `mPtr` in memory.
    function readBytes12(
        MemoryPointer mPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes13 at `mPtr` in memory.
    function readBytes13(
        MemoryPointer mPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes14 at `mPtr` in memory.
    function readBytes14(
        MemoryPointer mPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes15 at `mPtr` in memory.
    function readBytes15(
        MemoryPointer mPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes16 at `mPtr` in memory.
    function readBytes16(
        MemoryPointer mPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes17 at `mPtr` in memory.
    function readBytes17(
        MemoryPointer mPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes18 at `mPtr` in memory.
    function readBytes18(
        MemoryPointer mPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes19 at `mPtr` in memory.
    function readBytes19(
        MemoryPointer mPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes20 at `mPtr` in memory.
    function readBytes20(
        MemoryPointer mPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes21 at `mPtr` in memory.
    function readBytes21(
        MemoryPointer mPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes22 at `mPtr` in memory.
    function readBytes22(
        MemoryPointer mPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes23 at `mPtr` in memory.
    function readBytes23(
        MemoryPointer mPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes24 at `mPtr` in memory.
    function readBytes24(
        MemoryPointer mPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes25 at `mPtr` in memory.
    function readBytes25(
        MemoryPointer mPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes26 at `mPtr` in memory.
    function readBytes26(
        MemoryPointer mPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes27 at `mPtr` in memory.
    function readBytes27(
        MemoryPointer mPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes28 at `mPtr` in memory.
    function readBytes28(
        MemoryPointer mPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes29 at `mPtr` in memory.
    function readBytes29(
        MemoryPointer mPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes30 at `mPtr` in memory.
    function readBytes30(
        MemoryPointer mPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes31 at `mPtr` in memory.
    function readBytes31(
        MemoryPointer mPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes32 at `mPtr` in memory.
    function readBytes32(
        MemoryPointer mPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint8 at `mPtr` in memory.
    function readUint8(MemoryPointer mPtr) internal pure returns (uint8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint16 at `mPtr` in memory.
    function readUint16(
        MemoryPointer mPtr
    ) internal pure returns (uint16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint24 at `mPtr` in memory.
    function readUint24(
        MemoryPointer mPtr
    ) internal pure returns (uint24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint32 at `mPtr` in memory.
    function readUint32(
        MemoryPointer mPtr
    ) internal pure returns (uint32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint40 at `mPtr` in memory.
    function readUint40(
        MemoryPointer mPtr
    ) internal pure returns (uint40 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint48 at `mPtr` in memory.
    function readUint48(
        MemoryPointer mPtr
    ) internal pure returns (uint48 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint56 at `mPtr` in memory.
    function readUint56(
        MemoryPointer mPtr
    ) internal pure returns (uint56 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint64 at `mPtr` in memory.
    function readUint64(
        MemoryPointer mPtr
    ) internal pure returns (uint64 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint72 at `mPtr` in memory.
    function readUint72(
        MemoryPointer mPtr
    ) internal pure returns (uint72 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint80 at `mPtr` in memory.
    function readUint80(
        MemoryPointer mPtr
    ) internal pure returns (uint80 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint88 at `mPtr` in memory.
    function readUint88(
        MemoryPointer mPtr
    ) internal pure returns (uint88 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint96 at `mPtr` in memory.
    function readUint96(
        MemoryPointer mPtr
    ) internal pure returns (uint96 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint104 at `mPtr` in memory.
    function readUint104(
        MemoryPointer mPtr
    ) internal pure returns (uint104 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint112 at `mPtr` in memory.
    function readUint112(
        MemoryPointer mPtr
    ) internal pure returns (uint112 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint120 at `mPtr` in memory.
    function readUint120(
        MemoryPointer mPtr
    ) internal pure returns (uint120 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint128 at `mPtr` in memory.
    function readUint128(
        MemoryPointer mPtr
    ) internal pure returns (uint128 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint136 at `mPtr` in memory.
    function readUint136(
        MemoryPointer mPtr
    ) internal pure returns (uint136 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint144 at `mPtr` in memory.
    function readUint144(
        MemoryPointer mPtr
    ) internal pure returns (uint144 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint152 at `mPtr` in memory.
    function readUint152(
        MemoryPointer mPtr
    ) internal pure returns (uint152 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint160 at `mPtr` in memory.
    function readUint160(
        MemoryPointer mPtr
    ) internal pure returns (uint160 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint168 at `mPtr` in memory.
    function readUint168(
        MemoryPointer mPtr
    ) internal pure returns (uint168 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint176 at `mPtr` in memory.
    function readUint176(
        MemoryPointer mPtr
    ) internal pure returns (uint176 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint184 at `mPtr` in memory.
    function readUint184(
        MemoryPointer mPtr
    ) internal pure returns (uint184 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint192 at `mPtr` in memory.
    function readUint192(
        MemoryPointer mPtr
    ) internal pure returns (uint192 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint200 at `mPtr` in memory.
    function readUint200(
        MemoryPointer mPtr
    ) internal pure returns (uint200 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint208 at `mPtr` in memory.
    function readUint208(
        MemoryPointer mPtr
    ) internal pure returns (uint208 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint216 at `mPtr` in memory.
    function readUint216(
        MemoryPointer mPtr
    ) internal pure returns (uint216 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint224 at `mPtr` in memory.
    function readUint224(
        MemoryPointer mPtr
    ) internal pure returns (uint224 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint232 at `mPtr` in memory.
    function readUint232(
        MemoryPointer mPtr
    ) internal pure returns (uint232 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint240 at `mPtr` in memory.
    function readUint240(
        MemoryPointer mPtr
    ) internal pure returns (uint240 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint248 at `mPtr` in memory.
    function readUint248(
        MemoryPointer mPtr
    ) internal pure returns (uint248 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint256 at `mPtr` in memory.
    function readUint256(
        MemoryPointer mPtr
    ) internal pure returns (uint256 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int8 at `mPtr` in memory.
    function readInt8(MemoryPointer mPtr) internal pure returns (int8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int16 at `mPtr` in memory.
    function readInt16(MemoryPointer mPtr) internal pure returns (int16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int24 at `mPtr` in memory.
    function readInt24(MemoryPointer mPtr) internal pure returns (int24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int32 at `mPtr` in memory.
    function readInt32(MemoryPointer mPtr) internal pure returns (int32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int40 at `mPtr` in memory.
    function readInt40(MemoryPointer mPtr) internal pure returns (int40 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int48 at `mPtr` in memory.
    function readInt48(MemoryPointer mPtr) internal pure returns (int48 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int56 at `mPtr` in memory.
    function readInt56(MemoryPointer mPtr) internal pure returns (int56 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int64 at `mPtr` in memory.
    function readInt64(MemoryPointer mPtr) internal pure returns (int64 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int72 at `mPtr` in memory.
    function readInt72(MemoryPointer mPtr) internal pure returns (int72 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int80 at `mPtr` in memory.
    function readInt80(MemoryPointer mPtr) internal pure returns (int80 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int88 at `mPtr` in memory.
    function readInt88(MemoryPointer mPtr) internal pure returns (int88 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int96 at `mPtr` in memory.
    function readInt96(MemoryPointer mPtr) internal pure returns (int96 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int104 at `mPtr` in memory.
    function readInt104(
        MemoryPointer mPtr
    ) internal pure returns (int104 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int112 at `mPtr` in memory.
    function readInt112(
        MemoryPointer mPtr
    ) internal pure returns (int112 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int120 at `mPtr` in memory.
    function readInt120(
        MemoryPointer mPtr
    ) internal pure returns (int120 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int128 at `mPtr` in memory.
    function readInt128(
        MemoryPointer mPtr
    ) internal pure returns (int128 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int136 at `mPtr` in memory.
    function readInt136(
        MemoryPointer mPtr
    ) internal pure returns (int136 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int144 at `mPtr` in memory.
    function readInt144(
        MemoryPointer mPtr
    ) internal pure returns (int144 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int152 at `mPtr` in memory.
    function readInt152(
        MemoryPointer mPtr
    ) internal pure returns (int152 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int160 at `mPtr` in memory.
    function readInt160(
        MemoryPointer mPtr
    ) internal pure returns (int160 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int168 at `mPtr` in memory.
    function readInt168(
        MemoryPointer mPtr
    ) internal pure returns (int168 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int176 at `mPtr` in memory.
    function readInt176(
        MemoryPointer mPtr
    ) internal pure returns (int176 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int184 at `mPtr` in memory.
    function readInt184(
        MemoryPointer mPtr
    ) internal pure returns (int184 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int192 at `mPtr` in memory.
    function readInt192(
        MemoryPointer mPtr
    ) internal pure returns (int192 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int200 at `mPtr` in memory.
    function readInt200(
        MemoryPointer mPtr
    ) internal pure returns (int200 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int208 at `mPtr` in memory.
    function readInt208(
        MemoryPointer mPtr
    ) internal pure returns (int208 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int216 at `mPtr` in memory.
    function readInt216(
        MemoryPointer mPtr
    ) internal pure returns (int216 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int224 at `mPtr` in memory.
    function readInt224(
        MemoryPointer mPtr
    ) internal pure returns (int224 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int232 at `mPtr` in memory.
    function readInt232(
        MemoryPointer mPtr
    ) internal pure returns (int232 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int240 at `mPtr` in memory.
    function readInt240(
        MemoryPointer mPtr
    ) internal pure returns (int240 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int248 at `mPtr` in memory.
    function readInt248(
        MemoryPointer mPtr
    ) internal pure returns (int248 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int256 at `mPtr` in memory.
    function readInt256(
        MemoryPointer mPtr
    ) internal pure returns (int256 value) {
        assembly {
            value := mload(mPtr)
        }
    }
}

library MemoryWriters {
    /// @dev Writes `valuePtr` to memory at `mPtr`.
    function write(MemoryPointer mPtr, MemoryPointer valuePtr) internal pure {
        assembly {
            mstore(mPtr, valuePtr)
        }
    }

    /// @dev Writes a boolean `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, bool value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes an address `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, address value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes a bytes32 `value` to `mPtr` in memory.
    /// Separate name to disambiguate literal write parameters.
    function writeBytes32(MemoryPointer mPtr, bytes32 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes a uint256 `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, uint256 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes an int256 `value` to `mPtr` in memory.
    /// Separate name to disambiguate literal write parameters.
    function writeInt(MemoryPointer mPtr, int256 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }
}