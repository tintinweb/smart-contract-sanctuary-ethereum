/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IProofOfHumanity {
    /** @dev Return true if the submission is registered and not expired.
     *  @param _submissionID The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) external view returns (bool);

    /** @dev Return the number of submissions irrespective of their status.
     *  @return The number of submissions.
     */
    function submissionCounter() external view returns (uint256);
}

/// @title Proof of Humanity Semaphore interface.
/// @dev Interface of a ProofOfHumanitySemaphore contract.
interface IProofOfHumanitySemaphore {
    error ProofOfHumanitySemaphore__CallerIsNotRegistered();
    error ProofOfHumanitySemaphore__AlreadyRegistered();
    error ProofOfHumanitySemaphore__IncorrectPayment();
    error ProofOfHumanitySemaphore__RegistrationNotFound();
    error ProofOfHumanitySemaphore__RegistrationStillValid();
    error ProofOfHumanitySemaphore__PaymentFailed();
    error ProofOfHumanitySemaphore__InconsistentNullifiers();

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param submissionId: PoH submissionId i.e. the user's address
    /// @param identityCommitment: The identity commitment
    event IdentityCommitmentRegistered(
        address indexed submissionId,
        uint256 identityCommitment
    );

    /// @dev Emitted when a Semaphore and NullifierConsistency proof pair is
    /// verified.
    /// @param signal: The signal
    /// @param nullifierHash: The nullifier hash
    /// @param serviceNullifier: The service nullifier
    /// @param externalNullifier: The external nullifier
    /// @param identityProxy: The identity proxy
    event ProofVerified(
        bytes32 signal,
        uint256 nullifierHash,
        uint256 serviceNullifier,
        uint256 externalNullifier,
        uint256 identityProxy
    );

    /// @dev This should probably be in the constructor instead.
    /// @param groupDepth: Depth of the group tree.
    /// @param groupDepth: Leaf initialisation value for tree.
    function initGroup(uint8 groupDepth, uint256 zeroValue) external;

    /// @dev Registers an identity commitment against the caller. The must pay
    /// enough to reward whoever later removes the registration.
    /// @param identityCommitment: identityCommitment of the user.
    function registerIdentityCommitment(uint256 identityCommitment)
        external
        payable;

    /// @dev Removes a registered identity commitment and pays the caller if
    /// the caller can prove it's dur for removal.
    /// @param submissionID: PoH submissionID counterpart of identitiy commitment.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function deregisterIdentityCommitment(
        address submissionID,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /// @dev Saves the nullifier hash to avoid double signaling and emits an event
    /// if the zero-knowledge proof is valid.
    /// @param signal: The signal is arbitrary for this use case.
    /// @param nullifierHash: Nullifier hash.
    /// @param serviceNullifier: Service nullifier.
    /// @param externalNullifier: External nullifier.
    /// @param identityProxy: Unique to the user for the given service.
    /// @param nullifierConsistencyProof: Zero-knowledge proof.
    /// @param semaphoreProof: Zero-knowledge proof.
    function verifyProof(
        bytes32 signal,
        uint256 nullifierHash,
        uint256 serviceNullifier,
        uint256 externalNullifier,
        uint256 identityProxy,
        uint256[8] calldata nullifierConsistencyProof,
        uint256[8] calldata semaphoreProof
    ) external;
}

/// @title Semaphore interface.
/// @dev Interface of a Semaphore contract.
interface ISemaphore {
    error Semaphore__CallerIsNotTheGroupAdmin();
    error Semaphore__TreeDepthIsNotSupported();

    struct Verifier {
        address contractAddress;
        uint8 merkleTreeDepth;
    }

    /// @dev Emitted when an admin is assigned to a group.
    /// @param groupId: Id of the group.
    /// @param oldAdmin: Old admin of the group.
    /// @param newAdmin: New admin of the group.
    event GroupAdminUpdated(
        uint256 indexed groupId,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    event ProofVerified(uint256 indexed groupId, bytes32 signal);

    /// @dev Saves the nullifier hash to avoid double signaling and emits an event
    /// if the zero-knowledge proof is valid.
    /// @param groupId: Id of the group.
    /// @param signal: Semaphore signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param zeroValue: Zero value of the tree.
    /// @param admin: Admin of the group.
    function createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) external;

    /// @dev Updates the group admin.
    /// @param groupId: Id of the group.
    /// @param newAdmin: New admin of the group.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;

    /// @dev Adds a new member to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function addMember(uint256 groupId, uint256 identityCommitment) external;

    /// @dev Removes a member from an existing group. A proof of membership is
    /// needed to check if the node to be removed is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Identity commitment to be deleted.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;
}

/// @title Verifier interface.
/// @dev Interface of Verifier contract.
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view returns (bool);
}

contract ProofOfHumanitySemaphore is IProofOfHumanitySemaphore {
    uint256 deregisteringIncentive;
    IProofOfHumanity proofOfHumanity;
    ISemaphore semaphore;
    IVerifier nullifierConsistencyVerifier;
    uint256 public semaphoreGroupId;
    mapping(address => uint256) public addressToIdentityCommitment;
    mapping(uint256 => address) public identityCommitmentToAddress; // TODO: Remove once mapping is available via The Graph

    constructor(
        uint256 _deregisteringIncentive,
        IProofOfHumanity _proofOfHumanity,
        ISemaphore _semaphore,
        IVerifier _nullifierConsistencyVerifier,
        uint256 _semaphoreGroupId
    ) {
        deregisteringIncentive = _deregisteringIncentive;
        proofOfHumanity = _proofOfHumanity;
        semaphore = _semaphore;
        nullifierConsistencyVerifier = _nullifierConsistencyVerifier;
        semaphoreGroupId = _semaphoreGroupId;
    }

    function initGroup(uint8 groupDepth, uint256 zeroValue) external {
        address admin = address(this);
        semaphore.createGroup(semaphoreGroupId, groupDepth, zeroValue, admin);
    }

    function registerIdentityCommitment(uint256 identityCommitment)
        external
        payable
    {
        address submissionId = msg.sender;
        if (addressToIdentityCommitment[submissionId] != 0) {
            revert ProofOfHumanitySemaphore__AlreadyRegistered();
        }
        if (!proofOfHumanity.isRegistered(submissionId)) {
            revert ProofOfHumanitySemaphore__CallerIsNotRegistered();
        }
        if (msg.value != deregisteringIncentive) {
            revert ProofOfHumanitySemaphore__IncorrectPayment();
        }
        semaphore.addMember(semaphoreGroupId, identityCommitment);
        addressToIdentityCommitment[submissionId] = identityCommitment;
        emit IdentityCommitmentRegistered(submissionId, identityCommitment);
    }

    function deregisterIdentityCommitment(
        address submissionId,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external {
        if (addressToIdentityCommitment[submissionId] == 0) {
            revert ProofOfHumanitySemaphore__RegistrationNotFound();
        }
        if (proofOfHumanity.isRegistered(submissionId)) {
            revert ProofOfHumanitySemaphore__RegistrationStillValid();
        }
        uint256 identityCommitment = addressToIdentityCommitment[submissionId];
        semaphore.removeMember(
            semaphoreGroupId,
            identityCommitment,
            proofSiblings,
            proofPathIndices
        );
        addressToIdentityCommitment[submissionId] = 0;
        identityCommitmentToAddress[identityCommitment] = address(0);
        bool sent = payable(msg.sender).send(deregisteringIncentive);
        if (!sent) {
            revert ProofOfHumanitySemaphore__PaymentFailed();
        }
    }

    function verifyProof(
        bytes32 signal,
        uint256 nullifierHash,
        uint256 serviceNullifier,
        uint256 externalNullifier,
        uint256 identityProxy,
        uint256[8] calldata nullifierConsistencyProof,
        uint256[8] calldata semaphoreProof
    ) external {
        bool isConsistent = verifyNullifierConsistencyProof(
            serviceNullifier,
            identityProxy,
            externalNullifier,
            nullifierHash,
            nullifierConsistencyProof
        );
        if (!isConsistent) {
            revert ProofOfHumanitySemaphore__InconsistentNullifiers();
        }
        semaphore.verifyProof(
            semaphoreGroupId,
            signal,
            nullifierHash,
            externalNullifier,
            semaphoreProof
        );
        emit ProofVerified(
            signal,
            nullifierHash,
            serviceNullifier,
            externalNullifier,
            identityProxy
        );
    }

    function verifyNullifierConsistencyProof(
        uint256 serviceNullifier,
        uint256 identityProxy,
        uint256 externalNullifier,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) private view returns (bool) {
        return
            nullifierConsistencyVerifier.verifyProof(
                [proof[0], proof[1]],
                [[proof[2], proof[3]], [proof[4], proof[5]]],
                [proof[6], proof[7]],
                [
                    serviceNullifier,
                    identityProxy,
                    externalNullifier,
                    nullifierHash
                ]
            );
    }
}