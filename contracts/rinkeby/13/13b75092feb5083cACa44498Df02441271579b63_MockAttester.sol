// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.12;


import {Claim, Attestation, AttestationRequest} from '../core/libs/CoreLib.sol';
import {Attester} from '../core/Attester.sol';
import {IAttester} from '../core/interfaces/IAttester.sol';

contract MockAttester is IAttester, Attester {
  constructor(
    address ATTESTATION_REGISTRY_ADDRESS
  ) Attester(ATTESTATION_REGISTRY_ADDRESS) {}

  function _verifyClaim(AttestationRequest memory request, bytes calldata proofData) 
    internal 
    virtual 
    override {}

  function constructAttestation(AttestationRequest memory request, bytes calldata /*proofData*/)
    public
    view
    virtual
    override(Attester, IAttester)
    returns (Attestation memory)
  {
    uint256 attestationId = request.claim.id;
    return
      Attestation(
        attestationId,
        request.destination,
        request.claim,
        request.value,
        request.timestamp,
        ''
      );
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

// User Claim, can be made by any user.
// Need to provide proof to the underlying attester to generate an attestation.
struct AttestationRequest {
  Claim claim;
  address destination;
  uint256 value; // value of the underlying claim
  uint32 timestamp; // timestamp of the underlying claim
  bytes extraData; // arbitrary data
}

// Claim structure (context is in an attester. An attester features a set of claims.)
struct Claim {
  address attester; // attester featuring the claim and verifying it against a proof
  uint256 id; // Id of the claim (in supported claims of this attester)
}

// Attestation format (context in the global attestation registry)
struct Attestation {
  // chainId implicit
  uint256 attestationId; // Id of the attestation (in the registry)
  address owner; // Owner of the attestation
  Claim origin; // Verified Claim
  uint256 value; // Value of the attestation
  uint32 timestamp; // Timestamp of the underlying claim
  bytes extraData; // extra data that can be added by the attester
}

struct AttestationCollection {
  uint256 id;
}

// Attestation Data
struct AttestationData {
  Claim origin; // Claim used to generate the attestation
  uint256 value; // Value of the attestation
  uint32 timestamp; // Timestamp of the underlying claim
  uint32 recordingTimestamp; //
  bytes extraData;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.12;
import {IAttester} from './interfaces/IAttester.sol';
import {IAttestationsRegistry} from './interfaces/IAttestationsRegistry.sol';
import {AttestationRequest, Attestation} from './libs/CoreLib.sol';

/**
 * @title Attester Abstract Contract
 * @author Sismo
 * @notice Standard attester
 * All attesters that expect to be authorized in Sismo Protocol need to inherit this abstract contract
 * Find an example here: TODO link
 * @dev Developpers need to override the core internal function _verifyClaim and constructAttestation
 * @dev _beforeAttest and _afterAttest function can be overridden. They are optional.
 **/
abstract contract Attester is IAttester {
  IAttestationsRegistry immutable ATTESTATIONS_REGISTRY;

  /**
   * @dev Constructor.
   * @param attestationsRegistryAddress The address of the AttestationsRegistry contract on which the attester should write attestations
   */
  constructor(address attestationsRegistryAddress) {
    ATTESTATIONS_REGISTRY = IAttestationsRegistry(attestationsRegistryAddress);
  }

  /// @inheritdoc IAttester
  function attest(AttestationRequest memory request, bytes calldata proofData)
    external
    override
    returns (Attestation memory)
  {
    _beforeAttest(request, proofData);

    _verifyClaim(request, proofData);

    Attestation memory attestation = constructAttestation(request, proofData);

    ATTESTATIONS_REGISTRY.recordAttestation(attestation);

    _afterAttest(request, proofData);

    emit Attested(request, attestation, proofData);

    return attestation;
  }

  /**
   * @dev Must be overriden in attesters inheriting this contract.
   * It should check whether user provided a correct proof backing their claim
   * @param request The user attestation request
   * @param proofData data needed, in bytes, to validate the claim
   */
  function _verifyClaim(AttestationRequest memory request, bytes calldata proofData)
    internal
    virtual;

  /**
   * @dev Must be overriden in attesters inheriting this contract.
   * It should generate the Attestation from the claim, the destination and the proof
   * @param request The user attestation request
   * @param proofData data needed, in bytes, to validate the claim
   */
  function constructAttestation(AttestationRequest memory request, bytes calldata proofData)
    public
    virtual
    returns (Attestation memory);

  /**
   * @dev (Optional) Can be overriden in attesters inheriting this contract.
   * Will be called before attesting. Used to do check (e.g check nullifiers in ZK schemes)
   * @param request The user attestation request
   * @param proofData data needed, in bytes, to validate the claim
   */
  function _beforeAttest(AttestationRequest memory request, bytes calldata proofData)
    internal
    virtual
  {}

  /**
   * @dev (Optional) Can be overriden in attesters inheriting this contract.
   * Will be called after attesting. (e.g register nullifiers in ZK schemes)
   * @param request The user attestation request
   * @param proofData data needed, in bytes, to validate the claim
   */
  function _afterAttest(AttestationRequest memory request, bytes calldata proofData)
    internal
    virtual
  {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.12;

import {AttestationRequest, Attestation} from '../libs/CoreLib.sol';

/**
 * @title IAttester
 * @author Sismo
 * @notice This is the interface for the attesters in Sismo Protocol
 */
interface IAttester {
  event Attested(AttestationRequest request, Attestation attestation, bytes proofData);

  /**
   * @dev Main function of an attester. A user can call it with a claim and a proof backing their claim. It verifies the claim against the proof.
   * @param request The user attestation request
   * @param proofData data needed, in bytes, to validate the claim
   */
  function attest(AttestationRequest memory request, bytes calldata proofData)
    external
    returns (Attestation memory);

  function constructAttestation(AttestationRequest memory request, bytes calldata proofData)
    external
    returns (Attestation memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import {Attestation, AttestationData, Claim} from '../libs/CoreLib.sol';

/**
 * @title IAttestationsRegistry
 * @author Sismo
 * @notice This is the interface of the AttestationRegistry
 */
interface IAttestationsRegistry {
  event AttestationRecorded(Attestation attestation);
  event AttestationDeleted(Attestation attestation);

  function recordAttestation(Attestation memory attestation) external;

  function deleteAttestation(uint256 attestationId, address owner) external;

  function getAttestationData(uint256 attestationId, address owner)
    external
    view
    returns (AttestationData memory);

  function getAttestationAttester(uint256 attestationId, address owner)
    external
    view
    returns (address);

  function getAttestationExtraData(uint256 attestationId, address owner)
    external
    view
    returns (bytes memory);

  function getAttestationOrigin(uint256 attestationId, address owner)
    external
    view
    returns (Claim memory);

  function getAttestationValue(uint256 attestationId, address owner)
    external
    view
    returns (uint256);

  function getAttestationTimestamp(uint256 attestationId, address owner)
    external
    view
    returns (uint32);

  function getAttestationRecordingTimestamp(uint256 attestationId, address owner)
    external
    view
    returns (uint32);

  function getAttestationClaimId(uint256 attestationId, address owner)
    external
    view
    returns (uint256);
}