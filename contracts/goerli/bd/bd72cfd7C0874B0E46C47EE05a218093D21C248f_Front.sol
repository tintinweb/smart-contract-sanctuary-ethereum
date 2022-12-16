// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {IFront} from './interfaces/IFront.sol';
import {IAttester} from './interfaces/IAttester.sol';
import {IAttestationsRegistry} from './interfaces/IAttestationsRegistry.sol';
import {Request, Attestation} from './libs/Structs.sol';

/**
 * @title Front
 * @author Sismo
 * @notice This is the Front contract of the Sismo protocol
 * Behind a proxy, it routes attestations request to the targeted attester and can perform some actions
 * This specific implementation rewards early users with a early user attestation if they used sismo before ethcc conference

 * For more information: https://front.docs.sismo.io
 */
contract Front is IFront {
  IAttestationsRegistry public immutable ATTESTATIONS_REGISTRY;
  uint256 public constant EARLY_USER_COLLECTION = 0;
  uint32 public constant EARLY_USER_BADGE_END_DATE = 1663200000; // Sept 15

  /**
   * @dev Constructor
   * @param attestationsRegistryAddress Attestations registry contract address
   */
  constructor(address attestationsRegistryAddress) {
    ATTESTATIONS_REGISTRY = IAttestationsRegistry(attestationsRegistryAddress);
  }

  /**
   * @dev Forward a request to an attester and generates an early user attestation
   * @param attester Attester targeted by the request
   * @param request Request sent to the attester
   * @param proofData Data provided to the attester to back the request
   */
  function generateAttestations(
    address attester,
    Request calldata request,
    bytes calldata proofData
  ) external override returns (Attestation[] memory) {
    Attestation[] memory attestations = _forwardAttestationsGeneration(
      attester,
      request,
      proofData
    );
    _generateEarlyUserAttestation(request.destination);
    return attestations;
  }

  /**
   * @dev generate multiple attestations at once, to the same destination, generates an early user attestation
   * @param attesters Attesters targeted by the attesters
   * @param requests Requests sent to attester
   * @param proofDataArray Data sent with each request
   */
  function batchGenerateAttestations(
    address[] calldata attesters,
    Request[] calldata requests,
    bytes[] calldata proofDataArray
  ) external override returns (Attestation[][] memory) {
    Attestation[][] memory attestations = new Attestation[][](attesters.length);
    address destination = requests[0].destination;
    for (uint256 i = 0; i < attesters.length; i++) {
      if (requests[i].destination != destination) revert DifferentRequestsDestinations();
      attestations[i] = _forwardAttestationsGeneration(
        attesters[i],
        requests[i],
        proofDataArray[i]
      );
    }
    _generateEarlyUserAttestation(destination);
    return attestations;
  }

  /**
   * @dev build the attestations from a user request targeting a specific attester.
   * Forwards to the build function of targeted attester
   * @param attester Targeted attester
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function buildAttestations(
    address attester,
    Request calldata request,
    bytes calldata proofData
  ) external view override returns (Attestation[] memory) {
    return _forwardAttestationsBuild(attester, request, proofData);
  }

  /**
   * @dev build the attestations from multiple user requests.
   * Forwards to the build function of targeted attester
   * @param attesters Targeted attesters
   * @param requests User requests
   * @param proofDataArray Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function batchBuildAttestations(
    address[] calldata attesters,
    Request[] calldata requests,
    bytes[] calldata proofDataArray
  ) external view override returns (Attestation[][] memory) {
    Attestation[][] memory attestations = new Attestation[][](attesters.length);

    for (uint256 i = 0; i < attesters.length; i++) {
      attestations[i] = _forwardAttestationsBuild(attesters[i], requests[i], proofDataArray[i]);
    }
    return attestations;
  }

  function _forwardAttestationsBuild(
    address attester,
    Request calldata request,
    bytes calldata proofData
  ) internal view returns (Attestation[] memory) {
    return IAttester(attester).buildAttestations(request, proofData);
  }

  function _forwardAttestationsGeneration(
    address attester,
    Request calldata request,
    bytes calldata proofData
  ) internal returns (Attestation[] memory) {
    return IAttester(attester).generateAttestations(request, proofData);
  }

  function _generateEarlyUserAttestation(address destination) internal {
    uint32 currentTimestamp = uint32(block.timestamp);
    if (currentTimestamp < EARLY_USER_BADGE_END_DATE) {
      bool alreadyHasAttestation = ATTESTATIONS_REGISTRY.hasAttestation(
        EARLY_USER_COLLECTION,
        destination
      );

      if (!alreadyHasAttestation) {
        Attestation[] memory attestations = new Attestation[](1);
        attestations[0] = Attestation(
          EARLY_USER_COLLECTION,
          destination,
          address(this),
          1,
          currentTimestamp,
          'With strong love from Sismo'
        );
        ATTESTATIONS_REGISTRY.recordAttestations(attestations);
        emit EarlyUserAttestationGenerated(destination);
      }
    }
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

import {Request, Attestation} from '../libs/Structs.sol';
import {IAttestationsRegistry} from '../interfaces/IAttestationsRegistry.sol';

/**
 * @title IAttester
 * @author Sismo
 * @notice This is the interface for the attesters in Sismo Protocol
 */
interface IAttester {
  event AttestationGenerated(Attestation attestation);

  event AttestationDeleted(Attestation attestation);

  error AttestationDeletionNotImplemented();

  /**
   * @dev Main external function. Allows to generate attestations by making a request and submitting proof
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that has been recorded
   */
  function generateAttestations(
    Request calldata request,
    bytes calldata proofData
  ) external returns (Attestation[] memory);

  /**
   * @dev External facing function. Allows to delete an attestation by submitting proof
   * @param collectionIds Collection identifier of attestations to delete
   * @param attestationsOwner Owner of attestations to delete
   * @param proofData Data sent along the deletion request to prove its validity
   * @return attestations Attestations that was deleted
   */
  function deleteAttestations(
    uint256[] calldata collectionIds,
    address attestationsOwner,
    bytes calldata proofData
  ) external returns (Attestation[] memory);

  /**
   * @dev MANDATORY: must be implemented in attesters
   * It should build attestations from the user request and the proof
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function buildAttestations(
    Request calldata request,
    bytes calldata proofData
  ) external view returns (Attestation[] memory);

  /**
   * @dev Attestation registry address getter
   * @return attestationRegistry Address of the registry
   */
  function getAttestationRegistry() external view returns (IAttestationsRegistry);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Request, Attestation} from '../libs/Structs.sol';

/**
 * @title IFront
 * @author Sismo
 * @notice This is the interface of the Front Contract
 */
interface IFront {
  error DifferentRequestsDestinations();
  event EarlyUserAttestationGenerated(address destination);

  /**
   * @dev Forward a request to an attester and generates an early user attestation
   * @param attester Attester targeted by the request
   * @param request Request sent to the attester
   * @param proofData Data provided to the attester to back the request
   */
  function generateAttestations(
    address attester,
    Request calldata request,
    bytes calldata proofData
  ) external returns (Attestation[] memory);

  /**
   * @dev generate multiple attestations at once, to the same destination
   * @param attesters Attesters targeted by the attesters
   * @param requests Requests sent to attester
   * @param proofDataArray Data sent with each request
   */
  function batchGenerateAttestations(
    address[] calldata attesters,
    Request[] calldata requests,
    bytes[] calldata proofDataArray
  ) external returns (Attestation[][] memory);

  /**
   * @dev build the attestations from a user request targeting a specific attester.
   * Forwards to the build function of targeted attester
   * @param attester Targeted attester
   * @param request User request
   * @param proofData Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function buildAttestations(
    address attester,
    Request calldata request,
    bytes calldata proofData
  ) external view returns (Attestation[] memory);

  /**
   * @dev build the attestations from multiple user requests.
   * Forwards to the build function(s) of targeted attester(s)
   * @param attesters Targeted attesters
   * @param requests User requests
   * @param proofDataArray Data sent along the request to prove its validity
   * @return attestations Attestations that will be recorded
   */
  function batchBuildAttestations(
    address[] calldata attesters,
    Request[] calldata requests,
    bytes[] calldata proofDataArray
  ) external view returns (Attestation[][] memory);
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