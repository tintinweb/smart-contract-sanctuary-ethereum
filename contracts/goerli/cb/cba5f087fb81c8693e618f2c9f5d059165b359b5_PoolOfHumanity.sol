// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleTreeWithHistory.sol";

interface IHumanityVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[5] calldata input
    ) external view returns (bool);
}

interface IUpdateVerifier {
    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[47] calldata input
    ) external view returns (bool);
}

interface IHasher3 {
    function poseidon(bytes32[3] calldata leftRight)
        external
        pure
        returns (bytes32);
}

enum Status {
    None,
    Vouching,
    PendingRegistration,
    PendingRemoval
}

interface IProofOfHumanity {
    function submissionDuration() external view returns (uint64);

    function getSubmissionInfo(address _submissionID) external view returns (
            Status status,
            uint64 submissionTime,
            uint64 index,
            bool registered,
            bool hasVouched,
            uint numberOfRequests
        );
}

/**
 *  @title PoolOfHumanity
 *  This contract manages a pool of users who are registered for the Proof of Humanity. Users who have a submission in the Proof of
 *  Humanity that has finised vouching and is not currently being challenged can register for the Pool. Users can then
 *  prove that they have a submission in the Proof of Humanity without revealing their identity.
 * 
 *  Registration to the pool requires a small deposit, which is returned if the user unregisters. If the user's Proof of Humanity
 *  registration is revoked, the deposit can be claimed by someone who updates the revoked user's registration in the pool.
 */
contract PoolOfHumanity is MerkleTreeWithHistory {

    event Registered(address indexed user, uint index, bytes32 pubKey, uint submissionTime);
    event Updated(address indexed user, uint submissionTime, bool registered);

    uint32 constant HEIGHT = 20; // Height of the merkle tree

    uint public depositAmount = 0.05 ether;

    IHumanityVerifier public immutable humanityVerifier;
    IUpdateVerifier public immutable updateVerifier;
    IProofOfHumanity public immutable poh;
    IHasher3 public immutable hasher3;

    mapping (address => bytes32) public users; // Maps users to their public key

    constructor(
        address _humanityVerifier,
        address _updateVerifier,
        address _poh,
        address _hasher2,
        address _hasher3
    ) MerkleTreeWithHistory(HEIGHT, _hasher2) {
        humanityVerifier = IHumanityVerifier(_humanityVerifier);
        updateVerifier = IUpdateVerifier(_updateVerifier);
        poh = IProofOfHumanity(_poh);
        hasher3 = IHasher3(_hasher3);
    }

    /**
     *  @dev Registers a user for the pool. The user must have a submission in the Proof of Humanity that has finished vouching
     *  and is not currently being challenged.
     *  @param pubkey The user's public key. The public key is the poseidon hash of the private key. This private key is required
     *  to verify a user's registration in the pool.
     */
    function register(bytes32 pubkey) public payable {
        require(users[msg.sender] == 0, "already in pool");
        require(msg.value == depositAmount, "incorrect deposit amount");

        Status  status;
        uint64 submissionTime;
        bool registered; 
        (status, submissionTime, , registered, , ) = poh.getSubmissionInfo(msg.sender);

        require(registered, "not registered");
        require(status == Status.None, "incorrect status");

        bytes32 submissionTimeB = bytes32(uint256(submissionTime));
        bytes32[3] memory leafHashElements = [pubkey, submissionTimeB, bytes32(uint(1))];
        bytes32 leafHash = hasher3.poseidon(leafHashElements);

        uint index = _insert(leafHash);
        emit Registered(msg.sender, index, pubkey, submissionTime);

        users[msg.sender] = pubkey;
    }

    function updateSubmission(
            address user,
            bytes32 pubkey,
            uint previousSubmissionTime,
            uint previouslyRegistered,
            bytes32[] memory currentPath,
            bytes32[] memory updatedPath,
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c
    ) public payable {
        require(users[user] == pubkey, "incorrect pubkey");
        require(roots[currentRootIndex] == currentPath[20], "current root not on current path");

        Status status;
        uint64 submissionTime;
        bool registered;
        (status, submissionTime, , registered, , ) = poh.getSubmissionInfo(user);

        require(status == Status.None, "incorrect status");

        // If the user was not previously registered, they must pay the deposit
        if (previouslyRegistered == 0 && registered == true) {
            require(msg.value == depositAmount, "incorrect deposit amount");
        }

        uint[2 * HEIGHT + 7] memory inputs;
        inputs[0] = uint(pubkey);
        inputs[1] = uint(previousSubmissionTime);
        inputs[2] = previouslyRegistered;
        for (uint i = 0; i < HEIGHT + 1; i++) {
            inputs[i + 3] = uint(currentPath[i]);
        }
        inputs[HEIGHT + 4] = uint(submissionTime);
        inputs[HEIGHT + 5] = uint(registered ? 1 : 0);
        for (uint i = 0; i < HEIGHT + 1; i++) {
            inputs[i + 6 + HEIGHT] = uint(updatedPath[i]);
        }
        require(updateVerifier.verifyProof(a, b, c, inputs),  "update not verified");

        _update(currentPath, updatedPath);

        emit Updated(msg.sender, submissionTime, registered);
    }

    function unregister(
            bytes32 pubkey,
            uint previousSubmissionTime,
            uint previouslyRegistered,
            bytes32[] memory currentPath,
            bytes32[] memory updatedPath,
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c
    ) public {
        require(users[msg.sender] != 0, "not in pool");
        require(previouslyRegistered == 1, "not registered");

        uint[2 * HEIGHT + 7] memory inputs;
        inputs[0] = uint(pubkey);
        inputs[1] = uint(previousSubmissionTime);
        inputs[2] = previouslyRegistered;
        for (uint i = 0; i < HEIGHT + 1; i++) {
            inputs[i + 3] = uint(currentPath[i]);
        }
        inputs[HEIGHT + 4] = uint(previousSubmissionTime);
        inputs[HEIGHT + 5] = uint(0);
        for (uint i = 0; i < HEIGHT + 1; i++) {
            inputs[i + 6 + HEIGHT] = uint(updatedPath[i]);
        }
        require(updateVerifier.verifyProof(a, b, c, inputs),  "update not verified");
        _update(currentPath, updatedPath);
        emit Updated(msg.sender, previousSubmissionTime, false);
        
        (bool ok, ) = payable(msg.sender).call{value: depositAmount}("");
        require(ok == true, "transfer failed");
    }

    function checkHumanity(
        bytes32 root,
        uint currentTime,
        uint appID,
        uint expectedAppNullifier,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c
    ) public view returns (bool) {
        require(isKnownRoot(root), "unknown root");
        uint[5] memory inputs = [expectedAppNullifier, currentTime, appID, uint(root), uint(poh.submissionDuration())];
        return humanityVerifier.verifyProof(a, b, c, inputs);
    }
}