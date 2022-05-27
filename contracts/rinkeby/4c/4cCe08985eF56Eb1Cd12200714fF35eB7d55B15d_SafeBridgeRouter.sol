// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./interfaces/ISafeBridgeReceiver.sol";
import "./interfaces/ISafeBridgeSender.sol";
import "./interfaces/gnosis-chain/IAMB.sol";
import "./interfaces/arbitrum/IInbox.sol";
import "./interfaces/arbitrum/IOutbox.sol";

/**
 * Router on Ethereum from Arbitrum to Gnosis Chain.
 */
contract SafeBridgeRouter is ISafeBridgeReceiver, ISafeBridgeSender {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    event safeRelayed(bytes32 indexed txID);

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    IInbox public immutable inbox; // The address of the Arbitrum Inbox contract.
    IAMB public immutable amb; // The address of the AMB contract on Ethereum.
    address public immutable safeBridgeSender; // The address of the Safe Bridge sender on Arbitrum.
    address public immutable fastBridgeReceiverOnGnosisChain; // The address of the Fast Bridge Receiver on Gnosis Chain.

    /**
     * @dev Constructor.
     * @param _inbox The address of the inbox contract on Ethereum.
     * @param _amb The duration of the period allowing to challenge a claim.
     * @param _safeBridgeSender The safe bridge sender on Arbitrum.
     * @param _fastBridgeReceiverOnGnosisChain The fast bridge receiver on Gnosis Chain.
     */
    constructor(
        IInbox _inbox,
        IAMB _amb,
        address _safeBridgeSender,
        address _fastBridgeReceiverOnGnosisChain
    ) {
        inbox = _inbox;
        amb = _amb;
        safeBridgeSender = _safeBridgeSender;
        fastBridgeReceiverOnGnosisChain = _fastBridgeReceiverOnGnosisChain;
    }

    /**
     * Routes an arbitrary message from one domain to another.
     * Note: Access restricted to the Safe Bridge.
     * @param _epoch The epoch associated with the _batchmerkleRoot.
     * @param _batchMerkleRoot The true batch merkle root for the epoch sent by the safe bridge.     * @return Unique id to track the message request/transaction.
     */
    function verifySafe(uint256 _epoch, bytes32 _batchMerkleRoot) external onlyFromSafeBridge override {
        require(isSentBySafeBridge(), "Access not allowed: SafeBridgeSender only.");

        bytes4 methodSelector = ISafeBridgeReceiver.verifySafe.selector;
        bytes memory safeMessageData = abi.encodeWithSelector(methodSelector, _epoch, _batchMerkleRoot);

        // replace maxGasPerTx with safe level for production deployment
        bytes32 txID = _sendSafe(fastBridgeReceiverOnGnosisChain, safeMessageData);
        emit safeRelayed(txID);
    }

    function _sendSafe(address _receiver, bytes memory _calldata) internal override returns (bytes32){
        return amb.requireToPassMessage(_receiver, _calldata, amb.maxGasPerTx());
    }

    // ************************************* //
    // *              Views                * //
    // ************************************* //

    function isSentBySafeBridge() internal view override returns (bool) {
        IOutbox outbox = IOutbox(inbox.bridge().activeOutbox());
        return outbox.l2ToL1Sender() == safeBridgeSender;
    }
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

pragma solidity ^0.8.0;

abstract contract ISafeBridgeSender {
    /**
     * Sends an arbitrary message from one domain to another.
     *
     * @param _receiver The foreign chain contract address who will receive the calldata
     * @param _calldata The home chain encoded message data.
     * @return Unique id to track the message request/transaction.
     */
    function _sendSafe(address _receiver, bytes memory _calldata) internal virtual returns (bytes32);
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