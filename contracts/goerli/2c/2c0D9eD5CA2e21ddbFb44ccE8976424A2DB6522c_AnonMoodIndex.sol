/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

contract AnonMoodIndex {
    struct UserState {
        uint256 userId;
        uint256 moodIndex;
    }

    IProofOfHumanitySemaphore proofOfHumanitySemaphore;
    mapping(uint256 => uint256) public lastMoodIndexPerUserId;
    UserState[] public userStates;

    constructor(IProofOfHumanitySemaphore _proofOfHumanitySemaphore) {
        proofOfHumanitySemaphore = _proofOfHumanitySemaphore;
    }

    function averageMoodIndex() external view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < userStates.length; i++) {
            total += userStates[i].moodIndex;
        }
        return total / userStates.length;
    }

    function updateMoodIndexVerifiably(
        uint256 userMoodIndex,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 serviceNullifier,
        uint256 externalNullifier,
        uint256 identityProxy,
        uint256[8] calldata nullifierConsistencyProof,
        uint256[8] calldata semaphoreProof
    ) external {
        proofOfHumanitySemaphore.verifyProof(
            signal,
            nullifierHash,
            serviceNullifier,
            externalNullifier,
            identityProxy,
            nullifierConsistencyProof,
            semaphoreProof
        );
        updateMoodIndex(identityProxy, userMoodIndex);
    }

    function updateMoodIndex(uint256 userId, uint256 moodIndex) private {
        for (uint256 i = 0; i < userStates.length; i++) {
            if (userStates[i].userId == userId) {
                userStates[i].moodIndex = moodIndex;
                return;
            }
        }
        UserState memory userState;
        userState.userId = userId;
        userState.moodIndex = moodIndex;
        userStates.push(userState);
    }
}