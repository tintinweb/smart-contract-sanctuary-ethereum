// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {IAttestationsRegistry} from './interfaces/IAttestationsRegistry.sol';
import {AttestationsRegistryConfigLogic} from './libs/attestations-registry/AttestationsRegistryConfigLogic.sol';
import {AttestationsRegistryState} from './libs/attestations-registry/AttestationsRegistryState.sol';
import {Range, RangeUtils} from './libs/utils/RangeLib.sol';
import {Attestation, AttestationData} from './libs/Structs.sol';
import {IBadges} from './interfaces/IBadges.sol';

/**
 * @title Attestations Registry
 * @author Sismo
 * @notice Main contract of Sismo, stores all recorded attestations in attestations collections
 * Only authorized attestations issuers can record attestation in the registry
 * Attesters that expect to record in the Attestations Registry must be authorized issuers
 * For more information: https://attestations-registry.docs.sismo.io

 * For each attestation recorded, a badge is received by the user
 * The badge is the Non transferrable NFT representation of an attestation 
 * Its ERC1155 contract is stateless, balances are read directly from the registry. Badge balances <=> Attestations values
 * After the creation or update of an attestation, the registry triggers a TransferSingle event from the ERC1155 Badges contracts
 * It enables off-chain apps such as opensea to catch the "shadow mint" of the badge
 **/
contract AttestationsRegistry is
  AttestationsRegistryState,
  IAttestationsRegistry,
  AttestationsRegistryConfigLogic
{
  uint8 public constant IMPLEMENTATION_VERSION = 3;
  IBadges immutable BADGES;

  /**
   * @dev Constructor.
   * @param owner Owner of the contract, has the right to authorize/unauthorize attestations issuers
   * @param badgesAddress Stateless ERC1155 Badges contract
   */
  constructor(address owner, address badgesAddress) {
    BADGES = IBadges(badgesAddress);
    initialize(owner);
  }

  /**
   * @dev Initialize function, to be called by the proxy delegating calls to this implementation
   * @param ownerAddress Owner of the contract, has the right to authorize/unauthorize attestations issuers
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(address ownerAddress) public reinitializer(IMPLEMENTATION_VERSION) {
    // if proxy did not setup owner yet or if called by constructor (for implem setup)
    if (owner() == address(0) || address(this).code.length == 0) {
      _transferOwnership(ownerAddress);
    }
  }

  /**
   * @dev Main function to be called by authorized issuers
   * @param attestations Attestations to be recorded (creates a new one or overrides an existing one)
   */
  function recordAttestations(Attestation[] calldata attestations) external override whenNotPaused {
    address issuer = _msgSender();
    for (uint256 i = 0; i < attestations.length; i++) {
      if (!_isAuthorized(issuer, attestations[i].collectionId))
        revert IssuerNotAuthorized(issuer, attestations[i].collectionId);

      uint256 previousAttestationValue = _attestationsData[attestations[i].collectionId][
        attestations[i].owner
      ].value;

      _attestationsData[attestations[i].collectionId][attestations[i].owner] = AttestationData(
        attestations[i].issuer,
        attestations[i].value,
        attestations[i].timestamp,
        attestations[i].extraData
      );

      _triggerBadgeTransferEvent(
        attestations[i].collectionId,
        attestations[i].owner,
        previousAttestationValue,
        attestations[i].value
      );
      emit AttestationRecorded(attestations[i]);
    }
  }

  /**
   * @dev Delete function to be called by authorized issuers
   * @param owners The owners of the attestations to be deleted
   * @param collectionIds The collection ids of the attestations to be deleted
   */
  function deleteAttestations(
    address[] calldata owners,
    uint256[] calldata collectionIds
  ) external override whenNotPaused {
    if (owners.length != collectionIds.length)
      revert OwnersAndCollectionIdsLengthMismatch(owners, collectionIds);

    address issuer = _msgSender();
    for (uint256 i = 0; i < owners.length; i++) {
      AttestationData memory attestationData = _attestationsData[collectionIds[i]][owners[i]];

      if (!_isAuthorized(issuer, collectionIds[i]))
        revert IssuerNotAuthorized(issuer, collectionIds[i]);
      delete _attestationsData[collectionIds[i]][owners[i]];

      _triggerBadgeTransferEvent(collectionIds[i], owners[i], attestationData.value, 0);

      emit AttestationDeleted(
        Attestation(
          collectionIds[i],
          owners[i],
          attestationData.issuer,
          attestationData.value,
          attestationData.timestamp,
          attestationData.extraData
        )
      );
    }
  }

  /**
   * @dev Returns whether a user has an attestation from a collection
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function hasAttestation(
    uint256 collectionId,
    address owner
  ) external view override returns (bool) {
    return _getAttestationValue(collectionId, owner) != 0;
  }

  /**
   * @dev Getter of the data of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationData(
    uint256 collectionId,
    address owner
  ) external view override returns (AttestationData memory) {
    return _getAttestationData(collectionId, owner);
  }

  /**
   * @dev Getter of the value of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationValue(
    uint256 collectionId,
    address owner
  ) external view override returns (uint256) {
    return _getAttestationValue(collectionId, owner);
  }

  /**
   * @dev Getter of the data of a specific attestation as tuple
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationDataTuple(
    uint256 collectionId,
    address owner
  ) external view override returns (address, uint256, uint32, bytes memory) {
    AttestationData memory attestationData = _attestationsData[collectionId][owner];
    return (
      attestationData.issuer,
      attestationData.value,
      attestationData.timestamp,
      attestationData.extraData
    );
  }

  /**
   * @dev Getter of the extraData of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationExtraData(
    uint256 collectionId,
    address owner
  ) external view override returns (bytes memory) {
    return _attestationsData[collectionId][owner].extraData;
  }

  /**
   * @dev Getter of the issuer of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationIssuer(
    uint256 collectionId,
    address owner
  ) external view override returns (address) {
    return _attestationsData[collectionId][owner].issuer;
  }

  /**
   * @dev Getter of the timestamp of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationTimestamp(
    uint256 collectionId,
    address owner
  ) external view override returns (uint32) {
    return _attestationsData[collectionId][owner].timestamp;
  }

  /**
   * @dev Getter of the data of specific attestations
   * @param collectionIds Collection identifiers of the targeted attestations
   * @param owners Owners of the targeted attestations
   */
  function getAttestationDataBatch(
    uint256[] memory collectionIds,
    address[] memory owners
  ) external view override returns (AttestationData[] memory) {
    AttestationData[] memory attestationsDataArray = new AttestationData[](collectionIds.length);
    for (uint256 i = 0; i < collectionIds.length; i++) {
      attestationsDataArray[i] = _getAttestationData(collectionIds[i], owners[i]);
    }
    return attestationsDataArray;
  }

  /**
   * @dev Getter of the values of specific attestations
   * @param collectionIds Collection identifiers of the targeted attestations
   * @param owners Owners of the targeted attestations
   */
  function getAttestationValueBatch(
    uint256[] memory collectionIds,
    address[] memory owners
  ) external view override returns (uint256[] memory) {
    uint256[] memory attestationsValues = new uint256[](collectionIds.length);
    for (uint256 i = 0; i < collectionIds.length; i++) {
      attestationsValues[i] = _getAttestationValue(collectionIds[i], owners[i]);
    }
    return attestationsValues;
  }

  /**
   * @dev Function that trigger a TransferSingle event from the stateless ERC1155 Badges contract
   * It enables off-chain apps such as opensea to catch the "shadow mints/burns" of badges
   */
  function _triggerBadgeTransferEvent(
    uint256 badgeTokenId,
    address owner,
    uint256 previousValue,
    uint256 newValue
  ) internal {
    bool isGreaterValue = newValue > previousValue;
    address operator = address(this);
    address from = isGreaterValue ? address(0) : owner;
    address to = isGreaterValue ? owner : address(0);
    uint256 value = isGreaterValue ? newValue - previousValue : previousValue - newValue;

    // if isGreaterValue is true, function triggers mint event. Otherwise triggers burn event.
    BADGES.triggerTransferEvent(operator, from, to, badgeTokenId, value);
  }

  function _getAttestationData(
    uint256 collectionId,
    address owner
  ) internal view returns (AttestationData memory) {
    return (_attestationsData[collectionId][owner]);
  }

  function _getAttestationValue(
    uint256 collectionId,
    address owner
  ) internal view returns (uint256) {
    return _attestationsData[collectionId][owner].value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Attestation, AttestationData} from '../libs/Structs.sol';
import {IAttestationsRegistryConfigLogic} from './IAttestationsRegistryConfigLogic.sol';

/**
 * @title IAttestationsRegistry
 * @author Sismo
 * @notice This is the interface of the AttestationRegistry
 */
interface IAttestationsRegistry is IAttestationsRegistryConfigLogic {
  error IssuerNotAuthorized(address issuer, uint256 collectionId);
  error OwnersAndCollectionIdsLengthMismatch(address[] owners, uint256[] collectionIds);
  event AttestationRecorded(Attestation attestation);
  event AttestationDeleted(Attestation attestation);

  /**
   * @dev Main function to be called by authorized issuers
   * @param attestations Attestations to be recorded (creates a new one or overrides an existing one)
   */
  function recordAttestations(Attestation[] calldata attestations) external;

  /**
   * @dev Delete function to be called by authorized issuers
   * @param owners The owners of the attestations to be deleted
   * @param collectionIds The collection ids of the attestations to be deleted
   */
  function deleteAttestations(address[] calldata owners, uint256[] calldata collectionIds) external;

  /**
   * @dev Returns whether a user has an attestation from a collection
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function hasAttestation(uint256 collectionId, address owner) external returns (bool);

  /**
   * @dev Getter of the data of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationData(
    uint256 collectionId,
    address owner
  ) external view returns (AttestationData memory);

  /**
   * @dev Getter of the value of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationValue(uint256 collectionId, address owner) external view returns (uint256);

  /**
   * @dev Getter of the data of a specific attestation as tuple
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationDataTuple(
    uint256 collectionId,
    address owner
  ) external view returns (address, uint256, uint32, bytes memory);

  /**
   * @dev Getter of the extraData of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationExtraData(
    uint256 collectionId,
    address owner
  ) external view returns (bytes memory);

  /**
   * @dev Getter of the issuer of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationIssuer(
    uint256 collectionId,
    address owner
  ) external view returns (address);

  /**
   * @dev Getter of the timestamp of a specific attestation
   * @param collectionId Collection identifier of the targeted attestation
   * @param owner Owner of the targeted attestation
   */
  function getAttestationTimestamp(
    uint256 collectionId,
    address owner
  ) external view returns (uint32);

  /**
   * @dev Getter of the data of specific attestations
   * @param collectionIds Collection identifiers of the targeted attestations
   * @param owners Owners of the targeted attestations
   */
  function getAttestationDataBatch(
    uint256[] memory collectionIds,
    address[] memory owners
  ) external view returns (AttestationData[] memory);

  /**
   * @dev Getter of the values of specific attestations
   * @param collectionIds Collection identifiers of the targeted attestations
   * @param owners Owners of the targeted attestations
   */
  function getAttestationValueBatch(
    uint256[] memory collectionIds,
    address[] memory owners
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.14;

import {Range, RangeUtils} from '../libs/utils/RangeLib.sol';

interface IAttestationsRegistryConfigLogic {
  error AttesterNotFound(address issuer);
  error RangeIndexOutOfBounds(address issuer, uint256 expectedArrayLength, uint256 rangeIndex);
  error IdsMismatch(
    address issuer,
    uint256 rangeIndex,
    uint256 expectedFirstId,
    uint256 expectedLastId,
    uint256 FirstId,
    uint256 lastCollectionId
  );
  error AttributeDoesNotExist(uint8 attributeIndex);
  error AttributeAlreadyExists(uint8 attributeIndex);
  error ArgsLengthDoesNotMatch();

  event NewAttributeCreated(uint8 attributeIndex, bytes32 attributeName);
  event AttributeNameUpdated(
    uint8 attributeIndex,
    bytes32 newAttributeName,
    bytes32 previousAttributeName
  );
  event AttributeDeleted(uint8 attributeIndex, bytes32 deletedAttributeName);

  event AttestationsCollectionAttributeSet(
    uint256 collectionId,
    uint8 attributeIndex,
    uint8 attributeValue
  );

  event IssuerAuthorized(address issuer, uint256 firstCollectionId, uint256 lastCollectionId);
  event IssuerUnauthorized(address issuer, uint256 firstCollectionId, uint256 lastCollectionId);

  /**
   * @dev Returns whether an attestationsCollection has a specific attribute referenced by its index
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute. Can go from 0 to 63.
   */
  function attestationsCollectionHasAttribute(
    uint256 collectionId,
    uint8 index
  ) external view returns (bool);

  function attestationsCollectionHasAttributes(
    uint256 collectionId,
    uint8[] memory indices
  ) external view returns (bool);

  /**
   * @dev Returns the attribute's value (from 1 to 15) of an attestationsCollection
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param attributeIndex Index of the attribute. Can go from 0 to 63.
   */
  function getAttributeValueForAttestationsCollection(
    uint256 collectionId,
    uint8 attributeIndex
  ) external view returns (uint8);

  function getAttributesValuesForAttestationsCollection(
    uint256 collectionId,
    uint8[] memory indices
  ) external view returns (uint8[] memory);

  /**
   * @dev Set a value for an attribute of an attestationsCollection. The attribute should already be created.
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute (must be between 0 and 63)
   * @param value Value of the attribute we want to set for this attestationsCollection. Can take the value 0 to 15
   */
  function setAttributeValueForAttestationsCollection(
    uint256 collectionId,
    uint8 index,
    uint8 value
  ) external;

  function setAttributesValuesForAttestationsCollections(
    uint256[] memory collectionIds,
    uint8[] memory indices,
    uint8[] memory values
  ) external;

  /**
   * @dev Returns all the enabled attributes names and their values for a specific attestationsCollection
   * @param collectionId Collection Id of the targeted attestationsCollection
   */
  function getAttributesNamesAndValuesForAttestationsCollection(
    uint256 collectionId
  ) external view returns (bytes32[] memory, uint8[] memory);

  /**
   * @dev Authorize an issuer for a specific range
   * @param issuer Issuer that will be authorized
   * @param firstCollectionId First collection Id of the range for which the issuer will be authorized
   * @param lastCollectionId Last collection Id of the range for which the issuer will be authorized
   */
  function authorizeRange(
    address issuer,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) external;

  /**
   * @dev Unauthorize an issuer for a specific range
   * @param issuer Issuer that will be unauthorized
   * @param rangeIndex Index of the range to be unauthorized
   * @param firstCollectionId First collection Id of the range for which the issuer will be unauthorized
   * @param lastCollectionId Last collection Id of the range for which the issuer will be unauthorized
   */
  function unauthorizeRange(
    address issuer,
    uint256 rangeIndex,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) external;

  /**
   * @dev Authorize an issuer for specific ranges
   * @param issuer Issuer that will be authorized
   * @param ranges Ranges for which the issuer will be authorized
   */
  function authorizeRanges(address issuer, Range[] memory ranges) external;

  /**
   * @dev Unauthorize an issuer for specific ranges
   * @param issuer Issuer that will be unauthorized
   * @param ranges Ranges for which the issuer will be unauthorized
   */
  function unauthorizeRanges(
    address issuer,
    Range[] memory ranges,
    uint256[] memory rangeIndexes
  ) external;

  /**
   * @dev Returns whether a specific issuer is authorized or not to record in a specific attestations collection
   * @param issuer Issuer to be checked
   * @param collectionId Collection Id for which the issuer will be checked
   */
  function isAuthorized(address issuer, uint256 collectionId) external view returns (bool);

  /**
   * @dev Pauses the registry. Issuers can no longer record or delete attestations
   */
  function pause() external;

  /**
   * @dev Unpauses the registry
   */
  function unpause() external;

  /**
   * @dev Create a new attribute.
   * @param index Index of the attribute. Can go from 0 to 63.
   * @param name Name in bytes32 of the attribute
   */
  function createNewAttribute(uint8 index, bytes32 name) external;

  function createNewAttributes(uint8[] memory indices, bytes32[] memory names) external;

  /**
   * @dev Update the name of an existing attribute
   * @param index Index of the attribute. Can go from 0 to 63. The attribute must exist
   * @param newName new name in bytes32 of the attribute
   */
  function updateAttributeName(uint8 index, bytes32 newName) external;

  function updateAttributesName(uint8[] memory indices, bytes32[] memory names) external;

  /**
   * @dev Delete an existing attribute
   * @param index Index of the attribute. Can go from 0 to 63. The attribute must exist
   */
  function deleteAttribute(uint8 index) external;

  function deleteAttributes(uint8[] memory indices) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * @title Interface for Badges contract
 * @author Sismo
 * @notice Stateless ERC1155 contract. Reads balance from the values of attestations
 * The associated attestations registry triggers TransferSingle events from this contract
 * It allows badge "shadow mints and burns" to be caught by off-chain platforms
 */
interface IBadges {
  error BadgesNonTransferrable();

  /**
   * @dev Initializes the contract, to be called by the proxy delegating calls to this implementation
   * @param uri Uri for the metadata of badges
   * @param owner Owner of the contract, super admin, can setup roles and update the attestation registry
   * @notice The reinitializer modifier is needed to configure modules that are added through upgrades and that require initialization.
   */
  function initialize(string memory uri, address owner) external;

  /**
   * @dev Main function of the ERC1155 badge
   * The balance of a user is equal to the value of the underlying attestation.
   * attestationCollectionId == badgeId
   * @param account Address to check badge balance (= value of attestation)
   * @param id Badge Id to check (= attestationCollectionId)
   */
  function balanceOf(address account, uint256 id) external view returns (uint256);

  /**
   * @dev Emits a TransferSingle event, so subgraphs and other off-chain apps relying on events can see badge minting/burning
   * can only be called by address having the EVENT_TRIGGERER_ROLE (attestations registry address)
   * @param operator who is calling the TransferEvent
   * @param from address(0) if minting, address of the badge holder if burning
   * @param to address of the badge holder is minting, address(0) if burning
   * @param id badgeId for which to trigger the event
   * @param value minted/burned balance
   */
  function triggerTransferEvent(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 value
  ) external;

  /**
   * @dev Set the attestations registry address. Can only be called by owner (default admin)
   * @param attestationsRegistry new attestations registry address
   */
  function setAttestationsRegistry(address attestationsRegistry) external;

  /**
   * @dev Set the URI. Can only be called by owner (default admin)
   * @param uri new attestations registry address
   */
  function setUri(string memory uri) external;

  /**
   * @dev Getter of the attestations registry
   */
  function getAttestationsRegistry() external view returns (address);

  /**
   * @dev Getter of the badge issuer
   * @param account Address that holds the badge
   * @param id Badge Id to check (= attestationCollectionId)
   */
  function getBadgeIssuer(address account, uint256 id) external view returns (address);

  /**
   * @dev Getter of the badge timestamp
   * @param account Address that holds the badge
   * @param id Badge Id to check (= attestationCollectionId)
   */
  function getBadgeTimestamp(address account, uint256 id) external view returns (uint32);

  /**
   * @dev Getter of the badge extra data (it can store nullifier and burnCount)
   * @param account Address that holds the badge
   * @param id Badge Id to check (= attestationCollectionId)
   */
  function getBadgeExtraData(address account, uint256 id) external view returns (bytes memory);

  /**
   * @dev Getter of the value of a specific badge attribute
   * @param id Badge Id to check (= attestationCollectionId)
   * @param index Index of the attribute
   */
  function getAttributeValueForBadge(uint256 id, uint8 index) external view returns (uint8);

  /**
   * @dev Getter of all badge attributes and their values for a specific badge
   * @param id Badge Id to check (= attestationCollectionId)
   */
  function getAttributesNamesAndValuesForBadge(
    uint256 id
  ) external view returns (bytes32[] memory, uint8[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * @title  Attestations Registry State
 * @author Sismo
 * @notice This contract holds all of the storage variables and data
 *         structures used by the AttestationsRegistry and parent
 *         contracts.
 */

// User Attestation Request, can be made by any user
// The context of an Attestation Request is a specific attester contract
// Each attester has groups of accounts in its available data
// eg: for a specific attester:
//     group 1 <=> accounts that sent txs on mainnet
//     group 2 <=> accounts that sent txs on polygon
// eg: for another attester:
//     group 1 <=> accounts that sent eth txs in 2022
//     group 2 <=> accounts sent eth txs in 2021
struct Request {
  // implicit address attester;
  // implicit uint256 chainId;
  Claim[] claims;
  address destination; // destination that will receive the end attestation
}

struct Claim {
  uint256 groupId; // user claims to have an account in this group
  uint256 claimedValue; // user claims this value for its account in the group
  bytes extraData; // arbitrary data, may be required by the attester to verify claims or generate a specific attestation
}

/**
 * @dev Attestation Struct. This is the struct receive as argument by the Attestation Registry.
 * @param collectionId Attestation collection
 * @param owner Attestation collection
 * @param issuer Attestation collection
 * @param value Attestation collection
 * @param timestamp Attestation collection
 * @param extraData Attestation collection
 */
struct Attestation {
  // implicit uint256 chainId;
  uint256 collectionId; // Id of the attestation collection (in the registry)
  address owner; // Owner of the attestation
  address issuer; // Contract that created or last updated the record.
  uint256 value; // Value of the attestation
  uint32 timestamp; // Timestamp chosen by the attester, should correspond to the effective date of the attestation
  // it is different from the recording timestamp (date when the attestation was recorded)
  // e.g a proof of NFT ownership may have be recorded today which is 2 month old data.
  bytes extraData; // arbitrary data that can be added by the attester
}

// Attestation Data, stored in the registry
// The context is a specific owner of a specific collection
struct AttestationData {
  // implicit uint256 chainId
  // implicit uint256 collectionId - from context
  // implicit owner
  address issuer; // Address of the contract that recorded the attestation
  uint256 value; // Value of the attestation
  uint32 timestamp; // Effective date of issuance of the attestation. (can be different from the recording timestamp)
  bytes extraData; // arbitrary data that can be added by the attester
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.14;

import './OwnableLogic.sol';
import './PausableLogic.sol';
import './InitializableLogic.sol';
import './AttestationsRegistryState.sol';
import {IAttestationsRegistryConfigLogic} from './../../interfaces/IAttestationsRegistryConfigLogic.sol';
import {Range, RangeUtils} from '../utils/RangeLib.sol';
import {Bitmap256Bit} from '../utils/Bitmap256Bit.sol';

/**
 * @title Attestations Registry Config Logic contract
 * @author Sismo
 * @notice Holds the logic of how to authorize/ unauthorize issuers of attestations in the registry
 **/
contract AttestationsRegistryConfigLogic is
  AttestationsRegistryState,
  IAttestationsRegistryConfigLogic,
  OwnableLogic,
  PausableLogic,
  InitializableLogic
{
  using RangeUtils for Range[];
  using Bitmap256Bit for uint256;
  using Bitmap256Bit for uint8;

  /******************************************
   *
   *    ATTESTATION REGISTRY WRITE ACCESS MANAGEMENT (ISSUERS)
   *
   *****************************************/

  /**
   * @dev Pauses the registry. Issuers can no longer record or delete attestations
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses the registry
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /**
   * @dev Authorize an issuer for a specific range
   * @param issuer Issuer that will be authorized
   * @param firstCollectionId First collection Id of the range for which the issuer will be authorized
   * @param lastCollectionId Last collection Id of the range for which the issuer will be authorized
   */
  function authorizeRange(
    address issuer,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) external override onlyOwner {
    _authorizeRange(issuer, firstCollectionId, lastCollectionId);
  }

  /**
   * @dev Unauthorize an issuer for a specific range
   * @param issuer Issuer that will be unauthorized
   * @param rangeIndex Index of the range to be unauthorized
   * @param firstCollectionId First collection Id of the range for which the issuer will be unauthorized
   * @param lastCollectionId Last collection Id of the range for which the issuer will be unauthorized
   */
  function unauthorizeRange(
    address issuer,
    uint256 rangeIndex,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) external override onlyOwner {
    _unauthorizeRange(issuer, rangeIndex, firstCollectionId, lastCollectionId);
  }

  /**
   * @dev Authorize an issuer for specific ranges
   * @param issuer Issuer that will be authorized
   * @param ranges Ranges for which the issuer will be authorized
   */
  function authorizeRanges(address issuer, Range[] memory ranges) external override onlyOwner {
    for (uint256 i = 0; i < ranges.length; i++) {
      _authorizeRange(issuer, ranges[i].min, ranges[i].max);
    }
  }

  /**
   * @dev Unauthorize an issuer for specific ranges
   * @param issuer Issuer that will be unauthorized
   * @param ranges Ranges for which the issuer will be unauthorized
   */
  function unauthorizeRanges(
    address issuer,
    Range[] memory ranges,
    uint256[] memory rangeIndexes
  ) external override onlyOwner {
    for (uint256 i = 0; i < rangeIndexes.length; i++) {
      _unauthorizeRange(issuer, rangeIndexes[i] - i, ranges[i].min, ranges[i].max);
    }
  }

  /**
   * @dev Returns whether a specific issuer is authorized or not to record in a specific attestations collection
   * @param issuer Issuer to be checked
   * @param collectionId Collection Id for which the issuer will be checked
   */
  function isAuthorized(address issuer, uint256 collectionId) external view returns (bool) {
    return _isAuthorized(issuer, collectionId);
  }

  /******************************************
   *
   *    ATTRIBUTES CONFIG LOGIC
   *
   *****************************************/

  /**
   * @dev Create a new attribute.
   * @param index Index of the attribute. Can go from 0 to 63.
   * @param name Name in bytes32 of the attribute
   */
  function createNewAttribute(uint8 index, bytes32 name) public onlyOwner {
    index._checkIndexIsValid();
    if (_isAttributeCreated(index)) {
      revert AttributeAlreadyExists(index);
    }
    _createNewAttribute(index, name);
  }

  function createNewAttributes(uint8[] memory indices, bytes32[] memory names) external onlyOwner {
    if (indices.length != names.length) {
      revert ArgsLengthDoesNotMatch();
    }

    for (uint256 i = 0; i < indices.length; i++) {
      createNewAttribute(indices[i], names[i]);
    }
  }

  /**
   * @dev Update the name of an existing attribute
   * @param index Index of the attribute. Can go from 0 to 63. The attribute must exist
   * @param newName new name in bytes32 of the attribute
   */
  function updateAttributeName(uint8 index, bytes32 newName) public onlyOwner {
    index._checkIndexIsValid();
    if (!_isAttributeCreated(index)) {
      revert AttributeDoesNotExist(index);
    }
    _updateAttributeName(index, newName);
  }

  function updateAttributesName(
    uint8[] memory indices,
    bytes32[] memory newNames
  ) external onlyOwner {
    if (indices.length != newNames.length) {
      revert ArgsLengthDoesNotMatch();
    }

    for (uint256 i = 0; i < indices.length; i++) {
      updateAttributeName(indices[i], newNames[i]);
    }
  }

  /**
   * @dev Delete an existing attribute
   * @param index Index of the attribute. Can go from 0 to 63. The attribute must already exist
   */
  function deleteAttribute(uint8 index) public onlyOwner {
    index._checkIndexIsValid();
    if (!_isAttributeCreated(index)) {
      revert AttributeDoesNotExist(index);
    }
    _deleteAttribute(index);
  }

  function deleteAttributes(uint8[] memory indices) external onlyOwner {
    for (uint256 i = 0; i < indices.length; i++) {
      deleteAttribute(indices[i]);
    }
  }

  /**
   * @dev Set a value for an attribute of an attestationsCollection. The attribute should already be created.
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute (must be between 0 and 63)
   * @param value Value of the attribute we want to set for this attestationsCollection. Can take the value 0 to 15
   */
  function setAttributeValueForAttestationsCollection(
    uint256 collectionId,
    uint8 index,
    uint8 value
  ) public onlyOwner {
    index._checkIndexIsValid();

    if (!_isAttributeCreated(index)) {
      revert AttributeDoesNotExist(index);
    }

    _setAttributeForAttestationsCollection(collectionId, index, value);
  }

  function setAttributesValuesForAttestationsCollections(
    uint256[] memory collectionIds,
    uint8[] memory indices,
    uint8[] memory values
  ) external onlyOwner {
    if (collectionIds.length != indices.length || collectionIds.length != values.length) {
      revert ArgsLengthDoesNotMatch();
    }
    for (uint256 i = 0; i < collectionIds.length; i++) {
      setAttributeValueForAttestationsCollection(collectionIds[i], indices[i], values[i]);
    }
  }

  /**
   * @dev Returns the attribute's value (from 0 to 15) of an attestationsCollection
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute. Can go from 0 to 63.
   */
  function getAttributeValueForAttestationsCollection(
    uint256 collectionId,
    uint8 index
  ) public view returns (uint8) {
    uint256 currentAttributesValues = _getAttributesValuesBitmapForAttestationsCollection(
      collectionId
    );
    return currentAttributesValues._get(index);
  }

  function getAttributesValuesForAttestationsCollection(
    uint256 collectionId,
    uint8[] memory indices
  ) external view returns (uint8[] memory) {
    uint8[] memory attributesValues = new uint8[](indices.length);
    for (uint256 i = 0; i < indices.length; i++) {
      attributesValues[i] = getAttributeValueForAttestationsCollection(collectionId, indices[i]);
    }
    return attributesValues;
  }

  /**
   * @dev Returns whether an attestationsCollection has a specific attribute referenced by its index
   * @param collectionId Collection Id of the targeted attestationsCollection
   * @param index Index of the attribute. Can go from 0 to 63.
   */
  function attestationsCollectionHasAttribute(
    uint256 collectionId,
    uint8 index
  ) public view returns (bool) {
    uint256 currentAttributeValues = _getAttributesValuesBitmapForAttestationsCollection(
      collectionId
    );
    return currentAttributeValues._get(index) > 0;
  }

  function attestationsCollectionHasAttributes(
    uint256 collectionId,
    uint8[] memory indices
  ) external view returns (bool) {
    for (uint256 i = 0; i < indices.length; i++) {
      if (!attestationsCollectionHasAttribute(collectionId, indices[i])) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Returns all the enabled attributes names and their values for a specific attestationsCollection
   * @param collectionId Collection Id of the targeted attestationsCollection
   */
  function getAttributesNamesAndValuesForAttestationsCollection(
    uint256 collectionId
  ) public view returns (bytes32[] memory, uint8[] memory) {
    uint256 currentAttributesValues = _getAttributesValuesBitmapForAttestationsCollection(
      collectionId
    );

    (
      uint8[] memory indices,
      uint8[] memory values,
      uint8 nbOfNonZeroValues
    ) = currentAttributesValues._getAllNonZeroValues();

    bytes32[] memory attributesNames = new bytes32[](nbOfNonZeroValues);
    uint8[] memory attributesValues = new uint8[](nbOfNonZeroValues);
    for (uint8 i = 0; i < nbOfNonZeroValues; i++) {
      attributesNames[i] = _attributesNames[indices[i]];
      attributesValues[i] = values[i];
    }

    return (attributesNames, attributesValues);
  }

  /*****************************
   *
   *      INTERNAL FUNCTIONS
   *
   *****************************/

  function _authorizeRange(
    address issuer,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) internal {
    Range memory newRange = Range(firstCollectionId, lastCollectionId);
    _authorizedRanges[issuer].push(newRange);
    emit IssuerAuthorized(issuer, firstCollectionId, lastCollectionId);
  }

  function _unauthorizeRange(
    address issuer,
    uint256 rangeIndex,
    uint256 firstCollectionId,
    uint256 lastCollectionId
  ) internal onlyOwner {
    if (rangeIndex >= _authorizedRanges[issuer].length)
      revert RangeIndexOutOfBounds(issuer, _authorizedRanges[issuer].length, rangeIndex);

    uint256 expectedFirstId = _authorizedRanges[issuer][rangeIndex].min;
    uint256 expectedLastId = _authorizedRanges[issuer][rangeIndex].max;
    if (firstCollectionId != expectedFirstId || lastCollectionId != expectedLastId)
      revert IdsMismatch(
        issuer,
        rangeIndex,
        expectedFirstId,
        expectedLastId,
        firstCollectionId,
        lastCollectionId
      );

    _authorizedRanges[issuer][rangeIndex] = _authorizedRanges[issuer][
      _authorizedRanges[issuer].length - 1
    ];
    _authorizedRanges[issuer].pop();
    emit IssuerUnauthorized(issuer, firstCollectionId, lastCollectionId);
  }

  function _isAuthorized(address issuer, uint256 collectionId) internal view returns (bool) {
    return _authorizedRanges[issuer]._includes(collectionId);
  }

  function _setAttributeForAttestationsCollection(
    uint256 collectionId,
    uint8 index,
    uint8 value
  ) internal {
    uint256 currentAttributes = _getAttributesValuesBitmapForAttestationsCollection(collectionId);

    _attestationsCollectionAttributesValuesBitmap[collectionId] = currentAttributes._set(
      index,
      value
    );

    emit AttestationsCollectionAttributeSet(collectionId, index, value);
  }

  function _createNewAttribute(uint8 index, bytes32 name) internal {
    _attributesNames[index] = name;

    emit NewAttributeCreated(index, name);
  }

  function _updateAttributeName(uint8 index, bytes32 newName) internal {
    bytes32 previousName = _attributesNames[index];

    _attributesNames[index] = newName;

    emit AttributeNameUpdated(index, newName, previousName);
  }

  function _deleteAttribute(uint8 index) internal {
    bytes32 deletedName = _attributesNames[index];

    delete _attributesNames[index];

    emit AttributeDeleted(index, deletedName);
  }

  function _getAttributesValuesBitmapForAttestationsCollection(
    uint256 collectionId
  ) internal view returns (uint256) {
    return _attestationsCollectionAttributesValuesBitmap[collectionId];
  }

  function _isAttributeCreated(uint8 index) internal view returns (bool) {
    if (_attributesNames[index] == 0) {
      return false;
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Range} from '../utils/RangeLib.sol';
import {Attestation, AttestationData} from '../Structs.sol';

contract AttestationsRegistryState {
  /*******************************************************
    Storage layout:
    19 slots for config
      4 currently used for _initialized, _initializing, _paused, _owner
      15 place holders
    16 slots for logic
      3 currently used for _authorizedRanges, _attestationsCollectionAttributesValuesBitmap, _attributesNames
      13 place holders
    1 slot for _attestationsData 
  *******************************************************/

  // main config
  // changed `_initialized` from bool to uint8
  // as we were using OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)
  // and changed to OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)
  // PR: https://github.com/sismo-core/sismo-protocol/pull/41
  uint8 internal _initialized;
  bool internal _initializing;
  bool internal _paused;
  address internal _owner;
  // keeping some space for future
  uint256[15] private _placeHoldersAdmin;

  // storing the authorized ranges for each attesters
  mapping(address => Range[]) internal _authorizedRanges;
  // Storing the attributes values used for each attestations collection
  // Each attribute value is an hexadecimal
  mapping(uint256 => uint256) internal _attestationsCollectionAttributesValuesBitmap;
  // Storing the attribute name for each attributes index
  mapping(uint8 => bytes32) internal _attributesNames;
  // keeping some space for future
  uint256[13] private _placeHoldersConfig;
  // storing the data of attestations
  // =collectionId=> =owner=> attestationData
  mapping(uint256 => mapping(address => AttestationData)) internal _attestationsData;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.14;

import '../utils/Address.sol';
import './AttestationsRegistryState.sol';

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract InitializableLogic is AttestationsRegistryState {
  // only diff with oz
  // /**
  //  * @dev Indicates that the contract has been initialized.
  //  */
  // bool private _initialized;

  // /**
  //  * @dev Indicates that the contract is in the process of being initialized.
  //  */
  // bool private _initializing;

  /**
   * @dev Triggered when the contract has been initialized or reinitialized.
   */
  event Initialized(uint8 version);

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts.
   *
   * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
   * constructor.
   *
   * Emits an {Initialized} event.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) ||
        (!Address.isContract(address(this)) && _initialized == 1),
      'Initializable: contract is already initialized'
    );
    _initialized = 1;
    if (isTopLevelCall) {
      _initializing = true;
    }
    _;
    if (isTopLevelCall) {
      _initializing = false;
      emit Initialized(1);
    }
  }

  /**
   * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
   * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
   * used to initialize parent contracts.
   *
   * A reinitializer may be used after the original initialization step. This is essential to configure modules that
   * are added through upgrades and that require initialization.
   *
   * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
   * cannot be nested. If one is invoked in the context of another, execution will revert.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   *
   * WARNING: setting the version to 255 will prevent any future reinitialization.
   *
   * Emits an {Initialized} event.
   */
  modifier reinitializer(uint8 version) {
    require(
      !_initializing && _initialized < version,
      'Initializable: contract is already initialized'
    );
    _initialized = version;
    _initializing = true;
    _;
    _initializing = false;
    emit Initialized(version);
  }

  /**
   * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
   * {initializer} and {reinitializer} modifiers, directly or indirectly.
   */
  modifier onlyInitializing() {
    require(_initializing, 'Initializable: contract is not initializing');
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   *
   * Emits an {Initialized} event the first time it is successfully executed.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing, 'Initializable: contract is initializing');
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }

  /**
   * @dev Internal function that returns the initialized version. Returns `_initialized`
   */
  function _getInitializedVersion() internal view returns (uint8) {
    return _initialized;
  }

  /**
   * @dev Internal function that returns the initialized version. Returns `_initializing`
   */
  function _isInitializing() internal view returns (bool) {
    return _initializing;
  }
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.14;

import '../utils/Context.sol';
import './AttestationsRegistryState.sol';

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
abstract contract OwnableLogic is Context, AttestationsRegistryState {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // This is the only diff with OZ contract
  // address private _owner;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferOwnership(_msgSender());
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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
// Forked from, removed storage, OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.14;

import '../utils/Context.sol';
import './AttestationsRegistryState.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableLogic is Context, AttestationsRegistryState {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  // this is the only diff with OZ contract
  // bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), 'Pausable: paused');
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), 'Pausable: not paused');
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
   *
   * [IMPORTANT]
   * ====
   * You shouldn't rely on `isContract` to protect against flash loan attacks!
   *
   * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
   * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
   * constructor.
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
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
    return functionCall(target, data, 'Address: low-level call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
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
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: delegate call to non-contract');

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

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
pragma solidity ^0.8.14;

/*
 * The 256-bit bitmap is structured in 64 chuncks of 4 bits each.
 * The 4 bits can encode any value from 0 to 15.

    chunck63            chunck2      chunck1      chunck0
    bits                bits         bits         bits 
   ┌────────────┐      ┌────────────┬────────────┬────────────┐
   │ 1  1  1  1 │ .... │ 1  0  1  1 │ 0  0  0  0 │ 0  0  0  1 │
   └────────────┘      └────────────┴────────────┴────────────┘
      value 15            value 11     value 0      value 1

  * A chunck index must be between 0 and 63.
  * A value must be between 0 and 15.
 **/

library Bitmap256Bit {
  uint256 constant MAX_INT = 2 ** 256 - 1;

  error IndexOutOfBounds(uint8 index);
  error ValueOutOfBounds(uint8 value);

  /**
   * @dev Return the value at a given index of a 256-bit bitmap
   * @param index index where the value can be found. Can be between 0 and 63
   */
  function _get(uint256 self, uint8 index) internal pure returns (uint8) {
    uint256 currentValues = self;
    // Get the encoded 4-bit value by right shifting to the `index` position
    uint256 shifted = currentValues >> (4 * index);
    // Get the value by only masking the last 4 bits with an AND operator
    return uint8(shifted & (2 ** 4 - 1));
  }

  /**
   * @dev Set a value at a chosen index in a 256-bit bitmap
   * @param index index where the value will be stored. Can be between 0 and 63
   * @param value value to store. Can be between 0 and 15
   */
  function _set(uint256 self, uint8 index, uint8 value) internal pure returns (uint256) {
    _checkIndexIsValid(index);
    _checkValueIsValid(value);

    uint256 currentValues = self;
    // 1. first we need to remove the current value for the inputed `index`
    // Left Shift 4 bits mask (1111 mask) to the `index` position
    uint256 mask = (2 ** 4 - 1) << (4 * index);
    // Apply a XOR operation to obtain a mask with all bits set to 1 except the 4 bits that we want to remove
    uint256 negativeMask = MAX_INT ^ mask;
    // Apply a AND operation between the current values and the negative mask to remove the wanted bits
    uint256 newValues = currentValues & negativeMask;

    // 2. We set the new value wanted at the `index` position
    // Create the 4 bits encoding the new value and left shift them to the `index` position
    uint256 newValueMask = uint256(value) << (4 * index);
    // Apply an OR operation between the current values and the newValueMask to reference new value
    return newValues | newValueMask;
  }

  /**
   * @dev Get all the non-zero values in a 256-bit bitmap
   * @param self a 256-bit bitmap
   */
  function _getAllNonZeroValues(
    uint256 self
  ) internal pure returns (uint8[] memory, uint8[] memory, uint8) {
    uint8[] memory indices = new uint8[](64);
    uint8[] memory values = new uint8[](64);
    uint8 nbOfNonZeroValues = 0;
    for (uint8 i = 0; i < 63; i++) {
      uint8 value = _get(self, i);
      if (value > 0) {
        indices[nbOfNonZeroValues] = i;
        values[nbOfNonZeroValues] = value;
        nbOfNonZeroValues++;
      }
    }
    return (indices, values, nbOfNonZeroValues);
  }

  /**
   * @dev Check if the index is valid (is between 0 and 63)
   * @param index index of a chunck
   */
  function _checkIndexIsValid(uint8 index) internal pure {
    if (index > 63) {
      revert IndexOutOfBounds(index);
    }
  }

  /**
   * @dev Check if the value is valid (is between 0 and 15)
   * @param value value to encode in a chunck
   */
  function _checkValueIsValid(uint8 value) internal pure {
    if (value > 15) {
      revert ValueOutOfBounds(value);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.14;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

struct Range {
  uint256 min;
  uint256 max;
}

// Range [0;3] includees 0 and 3
library RangeUtils {
  function _includes(Range[] storage ranges, uint256 collectionId) internal view returns (bool) {
    for (uint256 i = 0; i < ranges.length; i++) {
      if (collectionId >= ranges[i].min && collectionId <= ranges[i].max) {
        return true;
      }
    }
    return false;
  }
}