// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./interfaces/IFastBridgeReceiver.sol";
import "./interfaces/ISafeBridgeReceiver.sol";
import "./merkle/MerkleProof.sol";

/**
 * Fast Receiver Base
 * Counterpart of `FastSenderBase`
 */
abstract contract FastBridgeReceiverBase is MerkleProof, IFastBridgeReceiver, ISafeBridgeReceiver {
    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

    struct Claim {
        bytes32 batchMerkleRoot;
        address bridger;
        bool honest;
    }

    struct Challenge {
        address challenger;
        bool honest;
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint256 public immutable deposit; // The deposit required to submit a claim or challenge
    uint256 public immutable genesis; // Marks the beginning of the first epoch.
    uint256 public immutable override epochPeriod; // Epochs mark the period between potential batches of messages.

    address public immutable safeRouter; // The address of the Safe Router on the connecting chain.

    mapping(uint256 => bytes32) public fastInbox; // epoch => validated batch merkle root(optimistically, or challenged and verified with the safe bridge)
    mapping(uint256 => Claim) public claims; // epoch => claim
    mapping(uint256 => Challenge) public challenges; // epoch => challenge
    mapping(uint256 => mapping(uint256 => bytes32)) public relayed; // epoch => packed replay bitmap

    /**
     * @dev Constructor.
     * @param _deposit The deposit amount to submit a claim in wei.
     * @param _epochPeriod The duration of the period allowing to challenge a claim.
     * @param _genesis The genesis time to synchronize epochs.
     * @param _safeRouter The address of the Safe Router on Ethereum.
     */
    constructor(
        uint256 _deposit,
        uint256 _epochPeriod,
        uint256 _genesis,
        address _safeRouter
    ) {
        deposit = _deposit;
        epochPeriod = _epochPeriod;
        genesis = _genesis;
        safeRouter = _safeRouter;
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the last completed epoch from the Fast Bridge  and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _batchMerkleRoot The batch merkle root claimed for the last completed epoch.
     */
    function claim(bytes32 _batchMerkleRoot) external payable override {
        require(msg.value >= deposit, "Insufficient claim deposit.");
        require(_batchMerkleRoot != bytes32(0), "Invalid claim.");

        uint256 epochCount = (block.timestamp - genesis) / epochPeriod;
        uint256 epochClaim = epochCount - 1; // Can only claim last completed epoch.
        uint256 claimDeadline = genesis + epochCount * epochPeriod + epochPeriod / 2;

        require(block.timestamp < claimDeadline, "Claim period expired.");
        require(claims[epochClaim].bridger == address(0), "Claim already made for most recent finalized epoch.");

        claims[epochClaim] = Claim({batchMerkleRoot: _batchMerkleRoot, bridger: msg.sender, honest: false});

        emit ClaimReceived(epochClaim, _batchMerkleRoot);
    }

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     */
    function challenge() external payable override {
        require(msg.value >= deposit, "Not enough claim deposit");

        // can only challenge the only active claim, about the previous epoch
        uint256 epochChallenge = (block.timestamp - genesis) / epochPeriod - 1;
        require(claims[epochChallenge].bridger != address(0), "No claim to challenge.");

        challenges[epochChallenge] = Challenge({challenger: msg.sender, honest: false});

        emit ClaimChallenged(epochChallenge);
    }

    /**
     * @dev Resolves the optimistic claim for '_epoch'.
     * @param _epoch The epoch of the optimistic claim.
     */
    function verify(uint256 _epoch) public {
        uint256 epochCount = (block.timestamp - genesis) / epochPeriod;

        require(epochCount > _epoch + 1, "Challenge period for epoch has not elapsed.");
        require(fastInbox[_epoch] == bytes32(0), "Epoch already verified.");

        Claim storage claim = claims[_epoch];
        require(claim.bridger != address(0), "Invalid epoch, no claim to verify.");

        if (challenges[_epoch].challenger == address(0)) {
            // optimistic happy path
            claim.honest = true;
            fastInbox[_epoch] = claim.batchMerkleRoot;
        }
    }

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     * @param _nonce The nonce (index in the merkle tree) to avoid replay.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message,
        uint256 _nonce
    ) external override {
        bytes32 batchMerkleRoot = fastInbox[_epoch];
        require(batchMerkleRoot != bytes32(0), "Invalid epoch.");

        uint256 index = _nonce / 256;
        uint256 offset = _nonce - index * 256;

        bytes32 replay = relayed[_epoch][index];
        require(((replay >> offset) & bytes32(uint256(1))) == 0, "Message already relayed");
        relayed[_epoch][index] = replay | bytes32(1 << offset);

        // Claim assessment if any
        bytes32 messageHash = sha256(abi.encodePacked(_message, _nonce));

        require(validateProof(_proof, messageHash, batchMerkleRoot) == true, "Invalid proof.");
        require(_relay(_message), "Failed to call contract"); // Checks-Effects-Interaction
    }

    /**
     * Note: Access restricted to the Safe Bridge.
     * @dev Resolves any challenge of the optimistic claim for '_epoch'.
     * @param _epoch The epoch to verify.
     * @param _batchMerkleRoot The true batch merkle root for the epoch.
     */
    function verifySafe(uint256 _epoch, bytes32 _batchMerkleRoot) onlyFromSafeBridge() external override {
        require(isSentBySafeBridge(), "Access not allowed: SafeBridgeSender only.");

        fastInbox[_epoch] = _batchMerkleRoot;

        if (_batchMerkleRoot == claims[_epoch].batchMerkleRoot) {
            claims[_epoch].honest = true;
        } else {
            challenges[_epoch].honest = true;
        }
    }

    /**
     * @dev Sends the deposit back to the Bridger if their claim is not successfully challenged. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
     * @param _epoch The epoch associated with the claim deposit to withraw.
     */
    function withdrawClaimDeposit(uint256 _epoch) external override {
        Claim memory claim = claims[_epoch];
        Challenge memory challenge = challenges[_epoch];
        require(claim.bridger != address(0), "Claim does not exist");
        require(claim.honest == true, "Claim not verified.");

        uint256 amount = deposit;
        if (challenge.challenger != address(0)) amount = (deposit * 3) / 2; // half burnt

        delete claims[_epoch];
        delete challenges[_epoch];
        payable(claim.bridger).send(amount); // Use of send to prevent reverting fallback. User is responsibility for accepting ETH.
        // Checks-Effects-Interaction
    }

    /**
     * @dev Sends the deposit back to the Challenger if their challenge is successful. Includes a portion of the Bridger's deposit.
     * @param _epoch The epoch associated with the challenge deposit to withraw.
     */
    function withdrawChallengeDeposit(uint256 _epoch) external override {
        Challenge memory challenge = challenges[_epoch];
        require(challenge.challenger != address(0), "Claim does not exist");
        require(challenge.honest == true, "Claim not verified: deposit forfeited");

        uint256 amount = (deposit * 3) / 2;

        delete claims[_epoch];
        delete challenges[_epoch];
        payable(challenge.challenger).send(amount); // Use of send to prevent reverting fallback. User is responsibility for accepting ETH.
        // Checks-Effects-Interaction
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     *  Returns the `start` and `end` time of challenge period for this `_epoch`.
     *  start The start time of the challenge period.
     *  end The end time of the challenge period.
     */
    function challengePeriod() external view override returns (uint256 start, uint256 end) {
        // start begins latest after the claim deadline expiry
        // however can begin as soon as a claim is made
        // can only challenge the only active claim, about the previous epoch
        uint256 epochChallenge = (block.timestamp - genesis) / epochPeriod - 1;
        start = genesis + epochChallenge * epochPeriod + epochPeriod / 2;
        end = start + epochPeriod / 2;
        return (start, end);
    }

    /**
     *  Returns the `start` and `end` time of challenge period for this `_epoch`.
     *  start The start time of the challenge period.
     *  end The end time of the challenge period.
     */
    function epochCount() external view returns (uint256 _epochCount) {
        _epochCount = (block.timestamp - genesis) / epochPeriod;
    }

    // ************************ //
    // *       Internal       * //
    // ************************ //

    function _relay(bytes calldata _messageData) internal returns (bool success) {
        // Decode the receiver address from the data encoded by the IFastBridgeSender
        (address receiver, bytes memory data) = abi.decode(_messageData, (address, bytes));
        (success, ) = address(receiver).call(data);
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./FastBridgeReceiverBase.sol";
import "./interfaces/gnosis-chain/IAMB.sol";

/**
 * Fast Bridge Receiver on Ethereum from Arbitrum
 * Counterpart of `FastBridgeSenderToGnosis`
 */
contract FastBridgeReceiverOnGnosis is FastBridgeReceiverBase {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    IAMB public immutable amb; // The address of the AMB contract on GC.

    /**
     * @dev Constructor.
     * @param _deposit The deposit amount to submit a claim in wei.
     * @param _epochPeriod The duration of the period allowing to challenge a claim.
     * @param _genesis The genesis time to synchronize epochs.
     * @param _amb The the AMB contract on Gnosis Chain.
     * @param _safeRouter The address of the Safe Bridge Router on Ethereum.
     */
    constructor(
        uint256 _deposit,
        uint256 _epochPeriod,
        uint256 _genesis,
        address _amb,
        address _safeRouter
    ) FastBridgeReceiverBase(_deposit, _epochPeriod, _genesis, _safeRouter) {
        amb = IAMB(_amb);
    }

    // ************************************* //
    // *              Views                * //
    // ************************************* //

    function isSentBySafeBridge() internal view override returns (bool) {
        return (msg.sender == address(amb)) && (amb.messageSender() == safeRouter);
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IFastBridgeReceiver {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants watch for these events to decide if a challenge should be submitted.
     * @param _epoch The epoch in  the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev The Fast Bridge participants watch for these events to call `sendSafeFallback()` on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 _epoch);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     */
    function challenge() external payable;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the most recent possible epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     * @param _nonce The nonce (index in the merkle tree) to avoid replay.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message,
        uint256 _nonce
    ) external;

    /**
     * @dev Sends the deposit back to the Bridger if their claim is not successfully challenged. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
     * @param _epoch The epoch associated with the claim deposit to withraw.
     */
    function withdrawClaimDeposit(uint256 _epoch) external;

    /**
     * @dev Sends the deposit back to the Challenger if his challenge is successful. Includes a portion of the Bridger's deposit.
     * @param _epoch The epoch associated with the challenge deposit to withraw.
     */
    function withdrawChallengeDeposit(uint256 _epoch) external;

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Returns the `start` and `end` time of challenge period for this `epoch`.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function challengePeriod() external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epoch);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ISafeBridgeReceiver {
    /**
     * Note: Access restricted to the Safe Bridge.
     * @dev Resolves any challenge of the optimistic claim for '_epoch'.
     * @param _epoch The epoch associated with the _batchmerkleRoot.
     * @param _batchMerkleRoot The true batch merkle root for the epoch sent by the safe bridge.
     */
    function verifySafe(uint256 _epoch, bytes32 _batchMerkleRoot) external virtual;

    function isSentBySafeBridge() internal view virtual returns (bool);

    modifier onlyFromSafeBridge() {
        require(isSentBySafeBridge(), "Safe Bridge only.");
        _;
    }
}

// SPDX-License-Identifier: MIT
// Complete IAMB Interface 
// https://github.com/poanetwork/tokenbridge-contracts/blob/master/contracts/interfaces/IAMB.sol

pragma solidity ^0.8.0;

interface IAMB {
    function requireToPassMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) external returns (bytes32);

    function maxGasPerTx() external view returns (uint256);

    function messageSender() external view returns (address);

    function messageSourceChainId() external view returns (uint256);

    function messageId() external view returns (bytes32);

    function transactionHash() external view returns (bytes32);

    function messageCallStatus(bytes32 _messageId) external view returns (bool);

    function failedMessageDataHash(bytes32 _messageId) external view returns (bytes32);

    function failedMessageReceiver(bytes32 _messageId) external view returns (address);

    function failedMessageSender(bytes32 _messageId) external view returns (address);

    function requireToConfirmMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas)
    external returns (bytes32);

    function requireToGetInformation(
        bytes32 _requestSelector,
        bytes memory _data)
    external returns (bytes32);

    function sourceChainId() external view returns (uint256);

    function destinationChainId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

/**
 *  @title MerkleProof
 *  @author Shotaro N. - <[email protected]>
 *  @dev A set of funcitons to verify merkle proofs.
 */
contract MerkleProof {
    /** @dev Validates membership of leaf in merkle tree with merkle proof.
     *  @param proof The merkle proof.
     *  @param leaf The leaf to validate membership in merkle tree.
     *  @param merkleRoot The root of the merkle tree.
     */
    function validateProof(
        bytes32[] memory proof,
        bytes32 leaf,
        bytes32 merkleRoot
    ) internal pure returns (bool) {
        return (merkleRoot == calculateRoot(proof, leaf));
    }

    /** @dev Calculates merkle root from proof.
     *  @param proof The merkle proof.
     *  @param leaf The leaf to validate membership in merkle tree..
     */
    function calculateRoot(bytes32[] memory proof, bytes32 leaf) private pure returns (bytes32) {
        uint256 proofLength = proof.length;
        require(proofLength <= 32, "Invalid Proof");
        bytes32 h = leaf;
        for (uint256 i = 0; i < proofLength; i++) {
            bytes32 proofElement = proof[i];
            // effecient hash
            if (proofElement > h)
                assembly {
                    mstore(0x00, h)
                    mstore(0x20, proofElement)
                    h := keccak256(0x00, 0x40)
                }
            else
                assembly {
                    mstore(0x00, proofElement)
                    mstore(0x20, h)
                    h := keccak256(0x00, 0x40)
                }
        }
        return h;
    }
}