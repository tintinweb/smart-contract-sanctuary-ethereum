// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere, @hrishibhat]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./interfaces/IFastBridgeReceiver.sol";
import "./interfaces/ISafeBridgeReceiver.sol";
import "./canonical/arbitrum/IInbox.sol";
import "./canonical/arbitrum/IOutbox.sol";

/**
 * Fast Receiver On Ethereum
 * Counterpart of `FastSenderFromArbitrum`
 */
contract FastBridgeReceiverOnEthereum is IFastBridgeReceiver, ISafeBridgeReceiver {
    // **************************************** //
    // *                                      * //
    // *     Ethereum Receiver Specific       * //
    // *                                      * //
    // **************************************** //

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    IInbox public immutable inbox; // The address of the Arbitrum Inbox contract.

    // ************************************* //
    // *              Views                * //
    // ************************************* //

    function isSentBySafeBridge() internal view override returns (bool) {
        IOutbox outbox = IOutbox(inbox.bridge().activeOutbox());
        return outbox.l2ToL1Sender() == safeBridgeSender;
    }

    /**
     * @dev Constructor.
     * @param _deposit The deposit amount to submit a claim in wei.
     * @param _epochPeriod The duration of each epoch.
     * @param _challengePeriod The duration of the period allowing to challenge a claim.
     * @param _safeBridgeSender The address of the Safe Bridge Sender on the connecting chain.
     * @param _inbox Ethereum receiver specific: The address of the inbox contract on Ethereum.
     */
    constructor(
        uint256 _deposit,
        uint256 _epochPeriod,
        uint256 _challengePeriod,
        address _safeBridgeSender,
        address _inbox // Ethereum receiver specific
    ) {
        deposit = _deposit;
        epochPeriod = _epochPeriod;
        challengePeriod = _challengePeriod;
        safeBridgeSender = _safeBridgeSender;
        inbox = IInbox(_inbox); // Ethereum receiver specific
    }

    // ************************************** //
    // *                                    * //
    // *         General Receiver           * //
    // *                                    * //
    // ************************************** //

    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

    struct Claim {
        bytes32 batchMerkleRoot;
        address bridger;
        uint32 timestamp;
        bool honest;
        bool verificationAttempted;
        bool depositAndRewardWithdrawn;
    }

    struct Challenge {
        address challenger;
        bool honest;
        bool depositAndRewardWithdrawn;
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    uint256 public immutable deposit; // The deposit required to submit a claim or challenge
    uint256 public immutable override epochPeriod; // Epochs mark the period between potential batches of messages.
    uint256 public immutable override challengePeriod; // Epochs mark the period between potential batches of messages.
    address public immutable safeBridgeSender; // The address of the Safe Bridge Sender on the connecting chain.

    mapping(uint256 => bytes32) public fastInbox; // epoch => validated batch merkle root(optimistically, or challenged and verified with the safe bridge)
    mapping(uint256 => Claim) public claims; // epoch => claim
    mapping(uint256 => Challenge) public challenges; // epoch => challenge
    mapping(uint256 => mapping(uint256 => bytes32)) public relayed; // epoch => packed replay bitmap

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the last completed epoch from the Fast Bridge  and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _epoch The epoch in which the batch to claim.
     * @param _batchMerkleRoot The batch merkle root claimed for the last completed epoch.
     */
    function claim(uint256 _epoch, bytes32 _batchMerkleRoot) external payable override {
        require(msg.value >= deposit, "Insufficient claim deposit.");
        require(_batchMerkleRoot != bytes32(0), "Invalid claim.");

        uint256 epochNow = block.timestamp / epochPeriod;
        // allow claim about current or previous epoch
        require(_epoch == epochNow || _epoch == epochNow + 1, "Invalid epoch.");
        require(claims[_epoch].bridger == address(0), "Claim already made for most recent finalized epoch.");

        claims[_epoch] = Claim({
            batchMerkleRoot: _batchMerkleRoot,
            bridger: msg.sender,
            timestamp: uint32(block.timestamp),
            honest: false,
            verificationAttempted: false,
            depositAndRewardWithdrawn: false
        });
        emit ClaimReceived(_epoch, _batchMerkleRoot);
    }

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to challenge.
     */
    function challenge(uint256 _epoch) external payable override {
        require(msg.value >= deposit, "Not enough claim deposit");

        // Can only challenge the only active claim, about the previous epoch
        require(claims[_epoch].bridger != address(0), "No claim to challenge.");
        require(block.timestamp < uint256(claims[_epoch].timestamp) + challengePeriod, "Challenge period elapsed.");

        challenges[_epoch] = Challenge({challenger: msg.sender, honest: false, depositAndRewardWithdrawn: false});
        emit ClaimChallenged(_epoch);
    }

    /**
     * @dev Resolves the optimistic claim for '_epoch'.
     * @param _epoch The epoch of the optimistic claim.
     */
    function verifyBatch(uint256 _epoch) external override {
        Claim storage claim = claims[_epoch];
        require(claim.bridger != address(0), "Invalid epoch, no claim to verify.");
        require(claim.verificationAttempted == false, "Optimistic verification already attempted.");
        require(
            block.timestamp > uint256(claims[_epoch].timestamp) + challengePeriod,
            "Challenge period has not yet elapsed."
        );

        if (challenges[_epoch].challenger == address(0)) {
            // Optimistic happy path
            claim.honest = true;
            fastInbox[_epoch] = claim.batchMerkleRoot;
            emit BatchVerified(_epoch, true);
        } else {
            emit BatchVerified(_epoch, false);
        }
        claim.verificationAttempted = true;
    }

    /**
     * Note: Access restricted to the Safe Bridge.
     * @dev Resolves any challenge of the optimistic claim for '_epoch'.
     * @param _epoch The epoch to verify.
     * @param _batchMerkleRoot The true batch merkle root for the epoch.
     */
    function verifySafeBatch(uint256 _epoch, bytes32 _batchMerkleRoot) external override onlyFromSafeBridge {
        require(isSentBySafeBridge(), "Access not allowed: SafeBridgeSender only.");

        fastInbox[_epoch] = _batchMerkleRoot;

        // Corner cases:
        // a) No claim submitted,
        // b) Receiving the root of an empty batch,
        // c) Batch root is zero.
        if (claims[_epoch].bridger != address(0)) {
            if (_batchMerkleRoot == claims[_epoch].batchMerkleRoot) {
                claims[_epoch].honest = true;
            } else {
                claims[_epoch].honest = false;
                challenges[_epoch].honest = true;
            }
        }
        emit BatchSafeVerified(_epoch, claims[_epoch].honest, challenges[_epoch].honest);
    }

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message
    ) external override {
        bytes32 batchMerkleRoot = fastInbox[_epoch];
        require(batchMerkleRoot != bytes32(0), "Invalid epoch.");

        // Claim assessment if any
        require(validateProof(_proof, sha256(_message), batchMerkleRoot) == true, "Invalid proof.");
        require(_checkReplayAndRelay(_epoch, _message), "Failed to call contract"); // Checks-Effects-Interaction
    }

    /**
     * @dev Sends the deposit back to the Bridger if their claim is not successfully challenged. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
     * @param _epoch The epoch associated with the claim deposit to withraw.
     */
    function withdrawClaimDeposit(uint256 _epoch) external override {
        Claim storage claim = claims[_epoch];

        require(claim.bridger != address(0), "Claim does not exist");
        require(claim.honest == true, "Claim failed.");
        require(claim.depositAndRewardWithdrawn == false, "Claim deposit and any rewards already withdrawn.");

        uint256 amount = deposit;
        if (challenges[_epoch].challenger != address(0) && challenges[_epoch].honest == false) {
            amount += deposit / 2; // half burnt
        }

        claim.depositAndRewardWithdrawn = true;
        emit ClaimDepositWithdrawn(_epoch, claim.bridger);

        payable(claim.bridger).send(amount); // Use of send to prevent reverting fallback. User is responsibility for accepting ETH.
        // Checks-Effects-Interaction
    }

    /**
     * @dev Sends the deposit back to the Challenger if their challenge is successful. Includes a portion of the Bridger's deposit.
     * @param _epoch The epoch associated with the challenge deposit to withraw.
     */
    function withdrawChallengeDeposit(uint256 _epoch) external override {
        Challenge storage challenge = challenges[_epoch];

        require(challenge.challenger != address(0), "Challenge does not exist");
        require(challenge.honest == true, "Challenge failed.");
        require(challenge.depositAndRewardWithdrawn == false, "Challenge deposit and rewards already withdrawn.");

        uint256 amount = deposit;
        if (claims[_epoch].bridger != address(0) && claims[_epoch].honest == false) {
            amount += deposit / 2; // half burnt
        }

        challenge.depositAndRewardWithdrawn = true;
        emit ChallengeDepositWithdrawn(_epoch, challenge.challenger);

        payable(challenge.challenger).send(amount); // Use of send to prevent reverting fallback. User is responsibility for accepting ETH.
        // Checks-Effects-Interaction
    }

    // ********************************** //
    // *         Merkle Proof           * //
    // ********************************** //

    /**
     * @dev Validates membership of leaf in merkle tree with merkle proof.
     * Note: Inlined from `merkle/MerkleProof.sol` for performance.
     * @param proof The merkle proof.
     * @param leaf The leaf to validate membership in merkle tree.
     * @param merkleRoot The root of the merkle tree.
     */
    function validateProof(
        bytes32[] memory proof,
        bytes32 leaf,
        bytes32 merkleRoot
    ) internal pure returns (bool) {
        return (merkleRoot == calculateRoot(proof, leaf));
    }

    /**
     * @dev Calculates merkle root from proof.
     * @param proof The merkle proof.
     * @param leaf The leaf to validate membership in merkle tree..
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

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Returns the `start` and `end` time of challenge period for this `epoch`.
     * @param _epoch The epoch of the claim to request the challenge period.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function claimChallengePeriod(uint256 _epoch) external view override returns (uint256 start, uint256 end) {
        // start begins latest after the claim deadline expiry
        // however can begin as soon as a claim is made
        // can only challenge the only active claim, about the previous epoch
        start = claims[_epoch].timestamp;
        end = start + challengePeriod;
    }

    // ************************ //
    // *       Internal       * //
    // ************************ //

    function _checkReplayAndRelay(uint256 _epoch, bytes calldata _messageData) internal returns (bool success) {
        // Decode the receiver address from the data encoded by the IFastBridgeSender
        (uint256 nonce, address receiver, bytes memory data) = abi.decode(_messageData, (uint256, address, bytes));

        uint256 index = nonce / 256;
        uint256 offset = nonce % 256;
        bytes32 replay = relayed[_epoch][index];
        require(((replay >> offset) & bytes32(uint256(1))) == 0, "Message already relayed");
        relayed[_epoch][index] = replay | bytes32(1 << offset);
        emit MessageRelayed(_epoch, nonce);

        (success, ) = receiver.call(data);
        // Checks-Effects-Interaction
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.7.0;

interface IInbox {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);
}

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.7.0;

interface IOutbox {
    event OutboxEntryCreated(uint256 indexed batchNum, uint256 outboxIndex, bytes32 outputRoot, uint256 numInBatch);

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths) external;
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere, @hrishibhat]
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
     * @param _epoch The epoch for which the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 indexed _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev This event indicates that `sendSafeFallback()` should be called on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 indexed _epoch);

    /**
     * @dev This events indicates that optimistic verification has succeeded. The messages are ready to be relayed.
     * @param _epoch The epoch associated with the batch.
     * @param _success The success of the optimistic verification.
     */
    event BatchVerified(uint256 indexed _epoch, bool _success);

    /**
     * @dev This event indicates that the batch has been received via the Safe Bridge.
     * @param _epoch The epoch associated with the batch.
     * @param _isBridgerHonest Whether the bridger made an honest claim.
     * @param _isChallengerHonest Whether the bridger made an honest challenge.
     */
    event BatchSafeVerified(uint256 indexed _epoch, bool _isBridgerHonest, bool _isChallengerHonest);

    /**
     * @dev This event indicates that the claim deposit has been withdrawn.
     * @param _epoch The epoch associated with the batch.
     * @param _bridger The recipient of the claim deposit.
     */
    event ClaimDepositWithdrawn(uint256 indexed _epoch, address indexed _bridger);

    /**
     * @dev This event indicates that the challenge deposit has been withdrawn.
     * @param _epoch The epoch associated with the batch.
     * @param _challenger The recipient of the challenge deposit.
     */
    event ChallengeDepositWithdrawn(uint256 indexed _epoch, address indexed _challenger);

    /**
     * @dev This event indicates that a message has been relayed for the batch in this `_epoch`.
     * @param _epoch The epoch associated with the batch.
     * @param _nonce The nonce of the message that was relayed.
     */
    event MessageRelayed(uint256 indexed _epoch, uint256 indexed _nonce);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to claim.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(uint256 _epoch, bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to challenge.
     */
    function challenge(uint256 _epoch) external payable;

    /**
     * @dev Resolves the optimistic claim for '_epoch'.
     * @param _epoch The epoch of the optimistic claim.
     */
    function verifyBatch(uint256 _epoch) external;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the most recent possible epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message
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
     * @param _epoch The epoch of the claim to request the challenge period.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function claimChallengePeriod(uint256 _epoch) external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epochPeriod);

    /**
     * @dev Returns the challenge period.
     */
    function challengePeriod() external view returns (uint256 challengePeriod);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

abstract contract ISafeBridgeReceiver {
    /**
     * Note: Access restricted to the Safe Bridge.
     * @dev Resolves any challenge of the optimistic claim for '_epoch'.
     * @param _epoch The epoch associated with the _batchmerkleRoot.
     * @param _batchMerkleRoot The true batch merkle root for the epoch sent by the safe bridge.
     */
    function verifySafeBatch(uint256 _epoch, bytes32 _batchMerkleRoot) external virtual;

    function isSentBySafeBridge() internal view virtual returns (bool);

    modifier onlyFromSafeBridge() {
        require(isSentBySafeBridge(), "Safe Bridge only.");
        _;
    }
}