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

import "./Bridge.sol";
import "./Outbox.sol";
import "./Inbox.sol";
import "./SequencerInbox.sol";
import "./Old_Outbox/OldOutbox.sol";
import "../rollup/facets/RollupAdmin.sol";
import "../rollup/RollupEventBridge.sol";
import "../rollup/RollupLib.sol";
import "../libraries/NitroReadyQuery.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@arbitrum/nitro-contracts/src/bridge/IBridge.sol" as INitroBridge;
import "@arbitrum/nitro-contracts/src/bridge/IInbox.sol" as INitroInbox;

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

interface INitroRollup {
    struct GlobalState {
        bytes32[2] bytes32Vals;
        uint64[2] u64Vals;
    }

    enum MachineStatus {
        RUNNING,
        FINISHED,
        ERRORED,
        TOO_FAR
    }

    struct ExecutionState {
        GlobalState globalState;
        MachineStatus machineStatus;
    }
    struct NitroRollupAssertion {
        ExecutionState beforeState;
        ExecutionState afterState;
        uint64 numBlocks;
    }

    function bridge() external view returns (INitroBridge.IBridge);

    function inbox() external view returns (INitroInbox.IInbox);

    function setInbox(IInbox newInbox) external;

    function setOwner(address newOwner) external;

    function paused() external view returns (bool);

    function pause() external;

    function resume() external;

    function latestNodeCreated() external returns (uint64);

    function createNitroMigrationGenesis(NitroRollupAssertion calldata assertion) external;
}

interface IArbOwner {
    function addChainOwner(address newOwner) external;
}

contract NitroMigrator is OwnableUpgradeable, IMessageProvider {
    uint8 internal constant L1MessageType_shutdownForNitro = 128;

    Inbox public inbox;
    SequencerInbox public sequencerInbox;
    Bridge public bridge;
    RollupEventBridge public rollupEventBridge;
    // assumed this contract is now the rollup admin
    RollupAdminFacet public rollup;
    ProxyAdmin public classicProxyAdmin;

    INitroRollup public nitroRollup;
    INitroBridge.IBridge public nitroBridge;
    ProxyAdmin public nitroProxyAdmin;

    /// @dev The nitro migration includes various steps.
    ///
    /// > Uninitialized is before the rollup contract addresses have been set.
    ///
    /// > Step0 is setup with contract deployments and integrity checks
    ///
    /// This is the setup for the upgrade, where all contracts are deployed but the upgrade migration hasn't started yet.
    /// The sequencer should stop receiving messages over RPC and post its final batch before Step1 is called.
    ///
    /// > Step1 is settling the current state of inputs to the system (bridge, delayed and sequencer inbox) in a consistent way
    ///
    /// The validator must now post the final assertion that executes all messages included in Step1 (ie the shutdownForNitro message)
    ///
    /// > Step2 is settling the current state of outputs to the system (rollup assertions) in a consistent way that includes state from step1. This pauses most of the rollup functionality
    ///
    /// The validator is now able to confirm all pending nodes between latestConfirmed and latestCreated. Step3 is only possible after this happens.
    ///
    /// > Step3 is enabling the nitro chain from the state settled in Step1 and Step2.
    enum NitroMigrationSteps {
        Uninitialized,
        Step0,
        Step1,
        Step2,
        Step3
    }
    NitroMigrationSteps public latestCompleteStep;

    function initialize() external initializer {
        __Ownable_init();
        latestCompleteStep = NitroMigrationSteps.Uninitialized;
    }

    function configureDeployment(
        Inbox _inbox,
        SequencerInbox _sequencerInbox,
        Bridge _bridge,
        RollupEventBridge _rollupEventBridge,
        RollupAdminFacet _rollup,
        ProxyAdmin _classicProxyAdmin,
        INitroRollup _nitroRollup,
        ProxyAdmin _nitroProxyAdmin
    ) external onlyOwner {
        require(latestCompleteStep == NitroMigrationSteps.Uninitialized, "WRONG_STEP");

        inbox = _inbox;
        sequencerInbox = _sequencerInbox;
        bridge = _bridge;
        rollupEventBridge = _rollupEventBridge;
        rollup = _rollup;
        classicProxyAdmin = _classicProxyAdmin;

        nitroRollup = _nitroRollup;
        nitroBridge = nitroRollup.bridge();
        nitroProxyAdmin = _nitroProxyAdmin;

        {
            // this contract is the rollup admin, and we want to check if the user facet is upgraded
            // so we deploy a new contract to ensure the query is dispatched to the user facet, not the admin
            NitroReadyQuery queryContract = new NitroReadyQuery();
            require(
                queryContract.isNitroReady(address(_rollup)) == 0xa4b1,
                "USER_ROLLUP_NOT_NITRO_READY"
            );
        }
        // this returns a different magic value so we can differentiate the user and admin facets
        require(_rollup.isNitroReady() == 0xa4b2, "ADMIN_ROLLUP_NOT_NITRO_READY");

        uint256 numOutboxes = bridge.allowedOutboxListLength();
        for (uint256 i = 0; i < numOutboxes; i++) {
            address currOutbox = bridge.allowedOutboxList(i);
            require(IOutbox(currOutbox).isNitroReady() == 0xa4b1, "OUTBOX_NOT_NITRO_READY");
        }
        require(_bridge.isNitroReady() == 0xa4b1, "BRIDGE_NOT_UPGRADED");
        require(_inbox.isNitroReady() == 0xa4b1, "INBOX_NOT_UPGRADED");
        require(_sequencerInbox.isNitroReady() == 0xa4b1, "SEQINBOX_NOT_UPGRADED");

        // we check that the new contracts that will receive permissions are actually contracts
        require(Address.isContract(address(nitroBridge)), "NITRO_BRIDGE_NOT_CONTRACT");

        // The nitro deployment script already configured a delayed inbox, so we disable it here
        INitroInbox.IInbox oldNitroInbox = nitroRollup.inbox();
        nitroBridge.setDelayedInbox(address(oldNitroInbox), false);

        require(nitroRollup.latestNodeCreated() == 0, "NITRO_ROLLUP_HAS_NODES");
        if (!nitroRollup.paused()) {
            nitroRollup.pause();
        }

        latestCompleteStep = NitroMigrationSteps.Step0;
    }

    /// @dev this assumes this contract owns the rollup/inboxes/bridge before this function is called (else it will revert)
    /// this will create the final input in the inbox, but there won't be the final assertion available yet.
    /// it is assumed that at this point the sequencer has stopped receiving txs and has posted its final batch on-chain
    /// Before this step the ownership of the Rollup and Bridge  must have been transferred to this contract
    function nitroStep1() external onlyOwner {
        require(latestCompleteStep == NitroMigrationSteps.Step0, "WRONG_STEP");

        // check that ownership of the bridge and rollup has been transferred
        require(rollup.owner() == address(this), "ROLLUP_OWNER_NOT_SET");
        if (bridge.owner() != address(this)) {
            rollup.transferOwnership(Ownable(address(bridge)), address(this));
        }

        uint256 delayedMessageCount = inbox.shutdownForNitro();

        // the `bridge` won't have any enabled inboxes after nitroStep2, so force inclusion after this shouldn't be possible
        // the rollup event bridge will update the delayed accumulator after the final rollup shutdown events, but this
        // shouldn't be an issue
        bridge.setInbox(address(inbox), false);

        // we disable the rollupEventBridge later since its needed in order to create/confirm assertions
        // the rollup event bridge will still add messages to the Bridge's accumulator, but these will never be included into the sequencer inbox
        // it is not a problem that these messages will be lost, as long as classic shutdown and nitro boot are deterministic

        // Upgrade the classic inbox to the nitro inbox's impl,
        // and configure nitro to use the classic inbox's address.
        // Right now the inbox isn't authorized on the nitro bridge, so users can't post txs.
        INitroInbox.IInbox oldNitroInbox = nitroRollup.inbox();
        address nitroInboxImpl = nitroProxyAdmin.getProxyImplementation(
            TransparentUpgradeableProxy(payable(address(oldNitroInbox)))
        );
        classicProxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(address(inbox))),
            nitroInboxImpl,
            abi.encodeWithSelector(INitroInbox.IInbox.postUpgradeInit.selector, nitroBridge)
        );
        nitroRollup.setInbox(inbox);

        // if the sequencer posted its final batch and was shutdown before `nitroStep1` there shouldn't be any reorgs
        // even though we remove the seqAddr from the sequencer inbox with `shutdownForNitro` this wouldnt stop a reorg from
        // the sequencer accepting txs in the RPC interface without posting a batch.
        // `nitroStep2` will only enforce inclusion of assertions that read up to this current point.
        sequencerInbox.shutdownForNitro(
            delayedMessageCount,
            bridge.inboxAccs(delayedMessageCount - 1)
        );

        // this speeds up the process allowing validators to post assertions more frequently
        rollup.setMinimumAssertionPeriod(4);

        // we don't remove permissions from gas refunder to current sequencer inbox as that can be handled independently from the upgrade
        latestCompleteStep = NitroMigrationSteps.Step1;
    }

    /// @dev this assumes step 1 has executed succesfully and that a validator has made the final assertion that includes the inbox shutdownForNitro
    function nitroStep2(
        uint256 finalNodeNum,
        bool destroyAlternatives,
        bool destroyChallenges
    ) external onlyOwner {
        require(latestCompleteStep == NitroMigrationSteps.Step1, "WRONG_STEP");
        rollup.shutdownForNitro(finalNodeNum, destroyAlternatives, destroyChallenges);
        latestCompleteStep = NitroMigrationSteps.Step2;
    }

    // CHRIS: TODO: remove skipCheck
    function nitroStep3(
        uint64 nitroGenesisBlockNumber,
        bytes32 nitroGenesisHash,
        bool skipCheck
    ) external onlyOwner {
        require(latestCompleteStep == NitroMigrationSteps.Step2, "WRONG_STEP");
        // CHRIS: TODO: destroying the node in the previous steps does not reset latestConfirmed/latestNodeCreated
        require(
            skipCheck || rollup.latestConfirmed() == rollup.latestNodeCreated(),
            "ROLLUP_SHUTDOWN_NOT_COMPLETE"
        );

        bridge.setInbox(address(rollupEventBridge), false);

        // Move the classic bridge funds to the nitro bridge
        bridge.setOutbox(address(this), true);
        {
            uint256 bal = address(bridge).balance;
            // TODO: import nitro contracts and use interface
            (bool success, ) = bridge.executeCall(
                address(nitroBridge),
                bal,
                abi.encodeWithSelector(INitroBridge.IBridge.acceptFundsFromOldBridge.selector)
            );
            require(success, "ESCROW_TRANSFER_FAIL");
        }
        bridge.setOutbox(address(this), false);

        uint256 numOutboxes = bridge.allowedOutboxListLength();
        for (uint256 i = 0; i < numOutboxes; i++) {
            // when we disable the list, it always shrinks by 1, so first index should always be a new one
            address currOutbox = bridge.allowedOutboxList(0);
            IOutbox(currOutbox).setBridge(IBridge(address(nitroBridge)));
            bridge.setOutbox(currOutbox, false);
            nitroBridge.setOutbox(currOutbox, true);
        }

        // we don't enable sequencer inbox and the rollup event bridge in nitro bridge as they are already configured in the deployment
        nitroBridge.setDelayedInbox(address(inbox), true);

        bytes32[2] memory newStateBytes32;
        newStateBytes32[0] = nitroGenesisHash;
        uint64[2] memory newStateU64;
        newStateU64[0] = 1;
        INitroRollup.GlobalState memory emptyGlobalState;
        INitroRollup.NitroRollupAssertion memory assertion = INitroRollup.NitroRollupAssertion({
            beforeState: INitroRollup.ExecutionState({
                globalState: emptyGlobalState,
                machineStatus: INitroRollup.MachineStatus.FINISHED
            }),
            afterState: INitroRollup.ExecutionState({
                globalState: INitroRollup.GlobalState({
                    bytes32Vals: newStateBytes32,
                    u64Vals: newStateU64
                }),
                machineStatus: INitroRollup.MachineStatus.FINISHED
            }),
            numBlocks: nitroGenesisBlockNumber + 1
        });

        nitroRollup.createNitroMigrationGenesis(assertion);
        nitroRollup.resume();

        // the migration is complete, relinquish ownership back to the
        // nitro proxy admin owner
        address nitroProxyAdminOwner = nitroProxyAdmin.owner();
        rollup.setOwner(nitroProxyAdminOwner);
        classicProxyAdmin.transferOwnership(nitroProxyAdminOwner);
        nitroRollup.setOwner(address(nitroProxyAdminOwner));

        latestCompleteStep = NitroMigrationSteps.Step3;
    }

    /// @dev allows the owner to do arbitrary calls. This is useful in case an unexpected event
    /// happens and we need to react to it using the migrator.
    /// This should be enough to recover from any unexpected state since no external contracts rely
    /// on this contract's state (ie `latestCompleteStep`).
    /// If other contracts relied on this, we'd need to use a delegate call instead.
    function executeTransaction(
        bytes calldata data,
        address destination,
        uint256 amount
    ) external payable onlyOwner {
        if (data.length > 0) require(Address.isContract(destination), "NO_CODE_AT_ADDR");
        (bool success, ) = destination.call{ value: amount }(data);
        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }

    function transferOtherContractOwnership(Ownable ownable, address newOwner) external onlyOwner {
        ownable.transferOwnership(newOwner);
    }

    uint8 internal constant L2_MSG = 3;
    uint8 internal constant L2MessageType_unsignedContractTx = 1;

    function addArbosOwner(address newOwner) external onlyOwner {
        require(latestCompleteStep != NitroMigrationSteps.Uninitialized, "UNINITIALIZED");
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(chainId > 100, "SHADOW_FORKS_ONLY");
        address bridgeOwner = bridge.owner();
        if (bridgeOwner != address(this)) {
            rollup.transferOwnership(Ownable(address(bridge)), address(this));
        }
        bridge.setInbox(address(this), true);
        bytes memory msgData = abi.encodePacked(
            L2MessageType_unsignedContractTx,
            uint256(1000000),
            uint256(2000000000),
            uint256(0x6B), // ArbOwner
            uint256(0),
            abi.encodeWithSelector(IArbOwner.addChainOwner.selector, newOwner)
        );
        uint256 seqNum = bridge.deliverMessageToInbox(L2_MSG, address(0), keccak256(msgData));
        emit InboxMessageDelivered(seqNum, msgData);
        bridge.setInbox(address(this), false);
        if (bridgeOwner != address(this)) {
            bridge.transferOwnership(bridgeOwner);
        }
    }
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

pragma solidity ^0.6.11;

import "./Inbox.sol";
import "./Outbox.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IBridge.sol";

contract Bridge is OwnableUpgradeable, IBridge {
    using Address for address;
    struct InOutInfo {
        uint256 index;
        bool allowed;
    }

    mapping(address => InOutInfo) private allowedInboxesMap;
    mapping(address => InOutInfo) private allowedOutboxesMap;

    address[] public allowedInboxList;
    address[] public allowedOutboxList;

    address public override activeOutbox;

    // Accumulator for delayed inbox; tail represents hash of the current state; each element represents the inclusion of a new message.
    bytes32[] public override inboxAccs;

    function initialize() external initializer {
        __Ownable_init();
    }

    function allowedInboxes(address inbox) external view override returns (bool) {
        return allowedInboxesMap[inbox].allowed;
    }

    function allowedOutboxes(address outbox) external view override returns (bool) {
        return allowedOutboxesMap[outbox].allowed;
    }

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable override returns (uint256) {
        require(allowedInboxesMap[msg.sender].allowed, "NOT_FROM_INBOX");
        return
            addMessageToInbox(
                kind,
                sender,
                block.number,
                block.timestamp, // solhint-disable-line not-rely-on-time
                tx.gasprice,
                messageDataHash
            );
    }

    function addMessageToInbox(
        uint8 kind,
        address sender,
        uint256 blockNumber,
        uint256 blockTimestamp,
        uint256 gasPrice,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        uint256 count = inboxAccs.length;
        bytes32 messageHash = Messages.messageHash(
            kind,
            sender,
            blockNumber,
            blockTimestamp,
            count,
            gasPrice,
            messageDataHash
        );
        bytes32 prevAcc = 0;
        if (count > 0) {
            prevAcc = inboxAccs[count - 1];
        }
        inboxAccs.push(Messages.addMessageToInbox(prevAcc, messageHash));
        emit MessageDelivered(count, prevAcc, msg.sender, kind, sender, messageDataHash);
        return count;
    }

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool success, bytes memory returnData) {
        require(allowedOutboxesMap[msg.sender].allowed, "NOT_FROM_OUTBOX");
        if (data.length > 0) require(destAddr.isContract(), "NO_CODE_AT_DEST");
        address currentOutbox = activeOutbox;
        activeOutbox = msg.sender;
        // We set and reset active outbox around external call so activeOutbox remains valid during call
        (success, returnData) = destAddr.call{ value: amount }(data);
        activeOutbox = currentOutbox;
        emit BridgeCallTriggered(msg.sender, destAddr, amount, data);
    }

    function setInbox(address inbox, bool enabled) external override onlyOwner {
        InOutInfo storage info = allowedInboxesMap[inbox];
        bool alreadyEnabled = info.allowed;
        emit InboxToggle(inbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedInboxesMap[inbox] = InOutInfo(allowedInboxList.length, true);
            allowedInboxList.push(inbox);
        } else {
            allowedInboxList[info.index] = allowedInboxList[allowedInboxList.length - 1];
            allowedInboxesMap[allowedInboxList[info.index]].index = info.index;
            allowedInboxList.pop();
            delete allowedInboxesMap[inbox];
        }
    }

    function setOutbox(address outbox, bool enabled) external override onlyOwner {
        InOutInfo storage info = allowedOutboxesMap[outbox];
        bool alreadyEnabled = info.allowed;
        emit OutboxToggle(outbox, enabled);
        if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
            return;
        }
        if (enabled) {
            allowedOutboxesMap[outbox] = InOutInfo(allowedOutboxList.length, true);
            allowedOutboxList.push(outbox);
        } else {
            allowedOutboxList[info.index] = allowedOutboxList[allowedOutboxList.length - 1];
            allowedOutboxesMap[allowedOutboxList[info.index]].index = info.index;
            allowedOutboxList.pop();
            delete allowedOutboxesMap[outbox];
        }
    }

    function messageCount() external view override returns (uint256) {
        return inboxAccs.length;
    }

    function allowedOutboxListLength() external view returns (uint256) {
        return allowedOutboxList.length;
    }

    function isNitroReady() external view override returns (uint256) {
        return 0xa4b1;
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

pragma solidity ^0.6.11;

import "./interfaces/IOutbox.sol";
import "./interfaces/IBridge.sol";

import "./Messages.sol";
import "../libraries/MerkleLib.sol";
import "../libraries/BytesLib.sol";
import "../libraries/Cloneable.sol";
import "../rollup/Rollup.sol";

import "@openzeppelin/contracts/proxy/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Outbox is IOutbox, Cloneable {
    using BytesLib for bytes;

    struct OutboxEntry {
        // merkle root of outputs
        bytes32 root;
        // mapping from output id => is spent
        mapping(bytes32 => bool) spentOutput;
    }

    bytes1 internal constant MSG_ROOT = 0;

    uint8 internal constant SendType_sendTxToL1 = 3;

    address public rollup;
    IBridge public bridge;

    mapping(uint256 => OutboxEntry) public outboxEntries;

    struct L2ToL1Context {
        uint128 l2Block;
        uint128 l1Block;
        uint128 timestamp;
        uint128 batchNum;
        bytes32 outputId;
        address sender;
    }
    // Note, these variables are set and then wiped during a single transaction.
    // Therefore their values don't need to be maintained, and their slots will
    // be empty outside of transactions
    L2ToL1Context internal context;
    uint128 public constant OUTBOX_VERSION = 1;

    function initialize(address _rollup, IBridge _bridge) external {
        require(rollup == address(0), "ALREADY_INIT");
        rollup = _rollup;
        bridge = _bridge;
    }

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    /// When the return value is zero, that means this is a system message
    /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
    function l2ToL1Sender() external view override returns (address) {
        return context.sender;
    }

    function l2ToL1Block() external view override returns (uint256) {
        return uint256(context.l2Block);
    }

    function l2ToL1EthBlock() external view override returns (uint256) {
        return uint256(context.l1Block);
    }

    function l2ToL1Timestamp() external view override returns (uint256) {
        return uint256(context.timestamp);
    }

    function l2ToL1BatchNum() external view override returns (uint256) {
        return uint256(context.batchNum);
    }

    function l2ToL1OutputId() external view override returns (bytes32) {
        return context.outputId;
    }

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external
        override
    {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        // If we've reached here, we've already confirmed that sum(sendLengths) == sendsData.length
        uint256 messageCount = sendLengths.length;
        uint256 offset = 0;
        for (uint256 i = 0; i < messageCount; i++) {
            handleOutgoingMessage(bytes(sendsData[offset:offset + sendLengths[i]]));
            offset += sendLengths[i];
        }
    }

    function handleOutgoingMessage(bytes memory data) private {
        // Otherwise we have an unsupported message type and we skip the message
        if (data[0] == MSG_ROOT) {
            require(data.length == 97, "BAD_LENGTH");
            uint256 batchNum = data.toUint(1);
            // Ensure no outbox entry already exists w/ batch number
            require(!outboxEntryExists(batchNum), "ENTRY_ALREADY_EXISTS");

            // This is the total number of msgs included in the root, it can be used to
            // detect when all msgs were executed against a root.
            // It currently isn't stored, but instead emitted in an event for utility
            uint256 numInBatch = data.toUint(33);
            bytes32 outputRoot = data.toBytes32(65);

            OutboxEntry memory newOutboxEntry = OutboxEntry(outputRoot);
            outboxEntries[batchNum] = newOutboxEntry;
            // keeping redundant batchnum in event (batchnum and old outboxindex field) for outbox version interface compatibility
            emit OutboxEntryCreated(batchNum, batchNum, outputRoot, numInBatch);
        }
    }

    /**
     * @notice Executes a messages in an Outbox entry.
     * @dev Reverts if dispute period hasn't expired, since the outbox entry
     * is only created once the rollup confirms the respective assertion.
     * @param batchNum Index of OutboxEntry in outboxEntries array
     * @param proof Merkle proof of message inclusion in outbox entry
     * @param index Merkle path to message
     * @param l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @param destAddr destination address for L1 contract call
     * @param l2Block l2 block number at which sendTxToL1 call was made
     * @param l1Block l1 block number at which sendTxToL1 call was made
     * @param l2Timestamp l2 Timestamp at which sendTxToL1 call was made
     * @param amount value in L1 message in wei
     * @param calldataForL1 abi-encoded L1 message data
     */
    function executeTransaction(
        uint256 batchNum,
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) external virtual {
        bytes32 outputId;
        {
            bytes32 userTx = calculateItemHash(
                l2Sender,
                destAddr,
                l2Block,
                l1Block,
                l2Timestamp,
                amount,
                calldataForL1
            );

            outputId = recordOutputAsSpent(batchNum, proof, index, userTx);
            emit OutBoxTransactionExecuted(destAddr, l2Sender, batchNum, index);
        }

        // we temporarily store the previous values so the outbox can naturally
        // unwind itself when there are nested calls to `executeTransaction`
        L2ToL1Context memory prevContext = context;

        context = L2ToL1Context({
            sender: l2Sender,
            l2Block: uint128(l2Block),
            l1Block: uint128(l1Block),
            timestamp: uint128(l2Timestamp),
            batchNum: uint128(batchNum),
            outputId: outputId
        });

        // set and reset vars around execution so they remain valid during call
        executeBridgeCall(destAddr, amount, calldataForL1);

        context = prevContext;
    }

    function recordOutputAsSpent(
        uint256 batchNum,
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) internal returns (bytes32) {
        require(proof.length < 256, "PROOF_TOO_LONG");
        require(path < 2**proof.length, "PATH_NOT_MINIMAL");

        // Hash the leaf an extra time to prove it's a leaf
        bytes32 calcRoot = calculateMerkleRoot(proof, path, item);
        OutboxEntry storage outboxEntry = outboxEntries[batchNum];
        require(outboxEntry.root != bytes32(0), "NO_OUTBOX_ENTRY");

        // With a minimal path, the pair of path and proof length should always identify
        // a unique leaf. The path itself is not enough since the path length to different
        // leaves could potentially be different
        bytes32 uniqueKey = keccak256(abi.encodePacked(path, proof.length));

        require(!outboxEntry.spentOutput[uniqueKey], "ALREADY_SPENT");
        require(calcRoot == outboxEntry.root, "BAD_ROOT");

        outboxEntry.spentOutput[uniqueKey] = true;
        return uniqueKey;
    }

    function executeBridgeCall(
        address destAddr,
        uint256 amount,
        bytes memory data
    ) internal {
        (bool success, bytes memory returndata) = bridge.executeCall(destAddr, amount, data);
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("BRIDGE_CALL_FAILED");
            }
        }
    }

    function calculateItemHash(
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    SendType_sendTxToL1,
                    uint256(uint160(bytes20(l2Sender))),
                    uint256(uint160(bytes20(destAddr))),
                    l2Block,
                    l1Block,
                    l2Timestamp,
                    amount,
                    calldataForL1
                )
            );
    }

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) public pure returns (bytes32) {
        return MerkleLib.calculateRoot(proof, path, keccak256(abi.encodePacked(item)));
    }

    function outboxEntryExists(uint256 batchNum) public view override returns (bool) {
        return outboxEntries[batchNum].root != bytes32(0);
    }

    function setBridge(IBridge newBridge) external override {
        require(msg.sender == OwnableUpgradeable(address(bridge)).owner(), "NOT_BRIDGE_OWNER");
        bridge = newBridge;
    }

    function isNitroReady() external pure override returns (uint256) {
        return 0xa4b1;
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

pragma solidity ^0.6.11;

import "./interfaces/IInbox.sol";
import "./interfaces/IBridge.sol";
import "../rollup/Rollup.sol";

import "./Messages.sol";
import "../libraries/Cloneable.sol";
import "../libraries/Whitelist.sol";
import "../libraries/ProxyUtil.sol";
import "../libraries/AddressAliasHelper.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "./Bridge.sol";

contract Inbox is IInbox, WhitelistConsumer, Cloneable {
    uint8 internal constant ETH_TRANSFER = 0;
    uint8 internal constant L2_MSG = 3;
    uint8 internal constant L1MessageType_L2FundedByL1 = 7;
    uint8 internal constant L1MessageType_submitRetryableTx = 9;
    uint8 internal constant L1MessageType_endOfBlock = 6;
    uint8 internal constant L1MessageType_shutdownForNitro = 128;

    uint8 internal constant L2MessageType_unsignedEOATx = 0;
    uint8 internal constant L2MessageType_unsignedContractTx = 1;

    IBridge public override bridge;

    bool public isCreateRetryablePaused;
    bool public shouldRewriteSender;

    function initialize(IBridge _bridge, address _whitelist) external {
        require(address(bridge) == address(0), "ALREADY_INIT");
        bridge = _bridge;
        WhitelistConsumer.whitelist = _whitelist;
    }

    function isNitroReady() external pure returns (uint256) {
        return 0xa4b1;
    }

    function shutdownForNitro() external returns (uint256 msgNum) {
        require(msg.sender == Bridge(address(bridge)).owner(), "ONLY_BRIDGE_OWNER");
        // we deliver an end of block message followed by the shutdown message
        msgNum = _deliverMessage(L1MessageType_endOfBlock, msg.sender, abi.encodePacked(""));
        msgNum = _deliverMessage(L1MessageType_shutdownForNitro, msg.sender, abi.encodePacked(""));
        // return the new message _count_ (one greater than the last _sequence number_)
        return msgNum + 1;
    }

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method is an optimization to avoid having to emit the entirety of the messageData in a log. Instead validators are expected to be able to parse the data from the transaction's input
     * @param messageData Data of the message being sent
     */
    function sendL2MessageFromOrigin(bytes calldata messageData)
        external
        onlyWhitelisted
        returns (uint256)
    {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "origin only");
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDeliveredFromOrigin(msgNum);
        return msgNum;
    }

    /**
     * @notice Send a generic L2 message to the chain
     * @dev This method can be used to send any type of message that doesn't require L1 validation
     * @param messageData Data of the message being sent
     */
    function sendL2Message(bytes calldata messageData)
        external
        override
        onlyWhitelisted
        returns (uint256)
    {
        uint256 msgNum = deliverToBridge(L2_MSG, msg.sender, keccak256(messageData));
        emit InboxMessageDelivered(msgNum, messageData);
        return msgNum;
    }

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable virtual override onlyWhitelisted returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    maxGas,
                    gasPriceBid,
                    nonce,
                    uint256(uint160(bytes20(destAddr))),
                    msg.value,
                    data
                )
            );
    }

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable virtual override onlyWhitelisted returns (uint256) {
        return
            _deliverMessage(
                L1MessageType_L2FundedByL1,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    maxGas,
                    gasPriceBid,
                    uint256(uint160(bytes20(destAddr))),
                    msg.value,
                    data
                )
            );
    }

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external virtual override onlyWhitelisted returns (uint256) {
        return
            _deliverMessage(
                L2_MSG,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedEOATx,
                    maxGas,
                    gasPriceBid,
                    nonce,
                    uint256(uint160(bytes20(destAddr))),
                    amount,
                    data
                )
            );
    }

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external virtual override onlyWhitelisted returns (uint256) {
        return
            _deliverMessage(
                L2_MSG,
                msg.sender,
                abi.encodePacked(
                    L2MessageType_unsignedContractTx,
                    maxGas,
                    gasPriceBid,
                    uint256(uint160(bytes20(destAddr))),
                    amount,
                    data
                )
            );
    }

    modifier onlyOwner() {
        // the rollup contract owns the bridge
        address rollup = Bridge(address(bridge)).owner();
        // we want to validate the owner of the rollup
        address owner = RollupBase(rollup).owner();
        require(msg.sender == owner, "NOT_ROLLUP");
        _;
    }

    event PauseToggled(bool enabled);

    /// @notice pauses creating retryables
    function pauseCreateRetryables() external override onlyOwner {
        require(!isCreateRetryablePaused, "ALREADY_PAUSED");
        isCreateRetryablePaused = true;
        emit PauseToggled(true);
    }

    /// @notice unpauses creating retryables
    function unpauseCreateRetryables() external override onlyOwner {
        require(isCreateRetryablePaused, "NOT_PAUSED");
        isCreateRetryablePaused = false;
        emit PauseToggled(false);
    }

    event RewriteToggled(bool enabled);

    /// @notice start rewriting addresses in eth deposits
    function startRewriteAddress() external override onlyOwner {
        require(!shouldRewriteSender, "ALREADY_REWRITING");
        shouldRewriteSender = true;
        emit RewriteToggled(true);
    }

    /// @notice stop rewriting addresses in eth deposits
    function stopRewriteAddress() external override onlyOwner {
        require(shouldRewriteSender, "NOT_REWRITING");
        shouldRewriteSender = false;
        emit RewriteToggled(false);
    }

    /// @notice deposit eth from L1 to L2
    /// @dev this function should not be called inside contract constructors
    function depositEth(uint256 maxSubmissionCost)
        external
        payable
        virtual
        override
        onlyWhitelisted
        returns (uint256)
    {
        require(!isCreateRetryablePaused, "CREATE_RETRYABLES_PAUSED");
        address sender = msg.sender;
        address destinationAddress = msg.sender;

        if (shouldRewriteSender) {
            if (!Address.isContract(sender) && tx.origin == msg.sender) {
                // isContract check fails if this function is called during a contract's constructor.
                // We don't adjust the address for calls coming from L1 contracts since their addresses get remapped
                // If the caller is an EOA, we adjust the address.
                // This is needed because unsigned messages to the L2 (such as retryables)
                // have the L1 sender address mapped.
                // Here we preemptively reverse the mapping for EOAs so deposits work as expected
                sender = AddressAliasHelper.undoL1ToL2Alias(sender);
            } else {
                destinationAddress = AddressAliasHelper.applyL1ToL2Alias(destinationAddress);
            }
        }

        return
            _deliverMessage(
                L1MessageType_submitRetryableTx,
                sender,
                abi.encodePacked(
                    // the beneficiary and other refund addresses don't get rewritten by arb-os
                    // so we use the original msg.sender value
                    uint256(uint160(bytes20(destinationAddress))),
                    uint256(0),
                    msg.value,
                    maxSubmissionCost,
                    uint256(uint160(bytes20(destinationAddress))),
                    uint256(uint160(bytes20(destinationAddress))),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    ""
                )
            );
    }

    /**
     * @notice will be deprecated post-nitro in favour of unsafeCreateRetryableTicket
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress). createRetryableTicket method is the recommended standard.
     * @param destAddr destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param  maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress maxgas x gasprice - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param gasPriceBid price bid for L2 execution
     * @param data ABI encoded data of L2 message
     * @return unique id for retryable transaction (keccak256(requestID, uint(0) )
     */
    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) public payable virtual onlyWhitelisted returns (uint256) {
        require(!isCreateRetryablePaused, "CREATE_RETRYABLES_PAUSED");

        return
            _deliverMessage(
                L1MessageType_submitRetryableTx,
                msg.sender,
                abi.encodePacked(
                    uint256(uint160(bytes20(destAddr))),
                    l2CallValue,
                    msg.value,
                    maxSubmissionCost,
                    uint256(uint160(bytes20(excessFeeRefundAddress))),
                    uint256(uint160(bytes20(callValueRefundAddress))),
                    maxGas,
                    gasPriceBid,
                    data.length,
                    data
                )
            );
    }

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev all msg.value will deposited to callValueRefundAddress on L2
     * @param destAddr destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param  maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress maxgas x gasprice - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param gasPriceBid price bid for L2 execution
     * @param data ABI encoded data of L2 message
     * @return unique id for retryable transaction (keccak256(requestID, uint(0) )
     */
    function createRetryableTicket(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable virtual override onlyWhitelisted returns (uint256) {
        // ensure the user's deposit alone will make submission succeed
        require(msg.value >= maxSubmissionCost + l2CallValue, "insufficient value");

        // if a refund address is a contract, we apply the alias to it
        // so that it can access its funds on the L2
        // since the beneficiary and other refund addresses don't get rewritten by arb-os
        if (shouldRewriteSender && Address.isContract(excessFeeRefundAddress)) {
            excessFeeRefundAddress = AddressAliasHelper.applyL1ToL2Alias(excessFeeRefundAddress);
        }
        if (shouldRewriteSender && Address.isContract(callValueRefundAddress)) {
            // this is the beneficiary. be careful since this is the address that can cancel the retryable in the L2
            callValueRefundAddress = AddressAliasHelper.applyL1ToL2Alias(callValueRefundAddress);
        }

        return
            createRetryableTicketNoRefundAliasRewrite(
                destAddr,
                l2CallValue,
                maxSubmissionCost,
                excessFeeRefundAddress,
                callValueRefundAddress,
                maxGas,
                gasPriceBid,
                data
            );
    }

    /**
     * @notice Put a message in the L2 inbox that can be reexecuted for some fixed amount of time if it reverts
     * @dev Advanced usage only (does not rewrite aliases for excessFeeRefundAddress and callValueRefundAddress). createRetryableTicket method is the recommended standard.
     * @param destAddr destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param  maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
     * @param excessFeeRefundAddress maxgas x gasprice - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param gasPriceBid price bid for L2 execution
     * @param data ABI encoded data of L2 message
     * @return unique id for retryable transaction (keccak256(requestID, uint(0) )
     */
    function unsafeCreateRetryableTicket(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable virtual override returns (uint256) {
        return
            createRetryableTicketNoRefundAliasRewrite(
                destAddr,
                l2CallValue,
                maxSubmissionCost,
                excessFeeRefundAddress,
                callValueRefundAddress,
                maxGas,
                gasPriceBid,
                data
            );
    }

    function _deliverMessage(
        uint8 _kind,
        address _sender,
        bytes memory _messageData
    ) internal returns (uint256) {
        uint256 msgNum = deliverToBridge(_kind, _sender, keccak256(_messageData));
        emit InboxMessageDelivered(msgNum, _messageData);
        return msgNum;
    }

    function deliverToBridge(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) internal returns (uint256) {
        return bridge.deliverMessageToInbox{ value: msg.value }(kind, sender, messageDataHash);
    }
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

pragma solidity ^0.6.11;

import "./interfaces/ISequencerInbox.sol";
import "./interfaces/IBridge.sol";
import "../arch/Marshaling.sol";
import "../libraries/Cloneable.sol";
import "../rollup/Rollup.sol";
import "../validator/IGasRefunder.sol";

import "./Messages.sol";

interface OldRollup {
    function sequencerInboxMaxDelayBlocks() external view returns (uint256);

    function sequencerInboxMaxDelaySeconds() external view returns (uint256);
}

contract SequencerInbox is ISequencerInbox, Cloneable {
    // Sequencer-Inbox state accumulator
    bytes32[] public override inboxAccs;

    // Number of messages included in the sequencer-inbox; tracked seperately from inboxAccs since multiple messages can be included in a single inboxAcc update (i.e., many messages in a batch, many batches in a single inboxAccs update, etc)
    uint256 public override messageCount;

    // count of messages read from the delayedInbox
    uint256 public totalDelayedMessagesRead;

    IBridge public delayedInbox;
    address private deprecatedSequencer;
    address public rollup;
    mapping(address => bool) public override isSequencer;

    // Window in which only the Sequencer can update the Inbox; this delay is what allows the Sequencer to give receipts with sub-blocktime latency.
    uint256 public override maxDelayBlocks;
    uint256 public override maxDelaySeconds;

    bool public isShutdownForNitro;

    string internal constant SHUTDOWN_FOR_NITRO = "SHUTDOWN_FOR_NITRO";

    modifier whenNotShutdownForNitro() {
        require(!isShutdownForNitro, SHUTDOWN_FOR_NITRO);
        _;
    }

    function initialize(
        IBridge _delayedInbox,
        address _sequencer,
        address _rollup
    ) external {
        require(address(delayedInbox) == address(0), "ALREADY_INIT");
        delayedInbox = _delayedInbox;
        isSequencer[_sequencer] = true;
        rollup = _rollup;
        // it is assumed that maxDelayBlocks and maxDelaySeconds are set by the rollup
    }

    function postUpgradeInit() external view {
        // it is assumed the sequencer inbox contract is behind a Proxy controlled by a
        // proxy admin. this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");
    }

    /// @notice DEPRECATED - use isSequencer instead
    function sequencer() external view override returns (address) {
        return deprecatedSequencer;
    }

    function setIsSequencer(address addr, bool newIsSequencer) external override {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        isSequencer[addr] = newIsSequencer;
        emit IsSequencerUpdated(addr, newIsSequencer);
    }

    function setMaxDelay(uint256 newMaxDelayBlocks, uint256 newMaxDelaySeconds) external override {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        maxDelayBlocks = newMaxDelayBlocks;
        maxDelaySeconds = newMaxDelaySeconds;
        emit MaxDelayUpdated(newMaxDelayBlocks, newMaxDelaySeconds);
    }

    function isNitroReady() external pure returns (uint256) {
        return 0xa4b1;
    }

    /**
     * @notice Move messages from the delayed inbox into the Sequencer inbox. Callable by any address. Necessary iff Sequencer hasn't included them before delay period expired.
     */
    function forceInclusion(
        uint256 _totalDelayedMessagesRead,
        uint8 kind,
        uint256[2] calldata l1BlockAndTimestamp,
        uint256 inboxSeqNum,
        uint256 gasPriceL1,
        address sender,
        bytes32 messageDataHash,
        bytes32 delayedAcc
    ) external whenNotShutdownForNitro {
        {
            bytes32 messageHash = Messages.messageHash(
                kind,
                sender,
                l1BlockAndTimestamp[0],
                l1BlockAndTimestamp[1],
                inboxSeqNum,
                gasPriceL1,
                messageDataHash
            );
            // Can only force-include after the Sequencer-only window has expired.
            require(l1BlockAndTimestamp[0] + maxDelayBlocks < block.number, "MAX_DELAY_BLOCKS");
            require(l1BlockAndTimestamp[1] + maxDelaySeconds < block.timestamp, "MAX_DELAY_TIME");

            // Verify that message hash represents the last message sequence of delayed message to be included
            bytes32 prevDelayedAcc = 0;
            if (_totalDelayedMessagesRead > 1) {
                prevDelayedAcc = delayedInbox.inboxAccs(_totalDelayedMessagesRead - 2);
            }
            require(
                delayedInbox.inboxAccs(_totalDelayedMessagesRead - 1) ==
                    Messages.addMessageToInbox(prevDelayedAcc, messageHash),
                "DELAYED_ACCUMULATOR"
            );
        }
        forceInclusionImpl(_totalDelayedMessagesRead, delayedAcc);
    }

    /// @dev this function is intended to force include the delayed inbox a final time in the nitro migration
    function shutdownForNitro(uint256 _totalDelayedMessagesRead, bytes32 delayedAcc)
        external
        whenNotShutdownForNitro
    {
        // no delay on force inclusion, triggered only by rollup's owner
        require(Rollup(payable(rollup)).owner() == msg.sender, "ONLY_ROLLUP_OWNER");

        // if _totalDelayedMessagesRead == totalDelayedMessagesRead, we don't need to force include
        // if _totalDelayedMessagesRead < totalDelayedMessagesRead we are trying to read backwards and will revert in forceInclusionImpl
        // if _totalDelayedMessagesRead > totalDelayedMessagesRead we will force include the new delayed messages into the seqInbox
        if (_totalDelayedMessagesRead != totalDelayedMessagesRead) {
            forceInclusionImpl(_totalDelayedMessagesRead, delayedAcc);
        }

        isShutdownForNitro = true;
    }

    function undoShutdownForNitro() external {
        require(Rollup(payable(rollup)).owner() == msg.sender, "ONLY_ROLLUP_OWNER");
        require(isShutdownForNitro, "NOT_SHUTDOWN");
        isShutdownForNitro = false;
    }

    function forceInclusionImpl(uint256 _totalDelayedMessagesRead, bytes32 delayedAcc) internal {
        require(_totalDelayedMessagesRead > totalDelayedMessagesRead, "DELAYED_BACKWARDS");

        uint256 startNum = messageCount;
        bytes32 beforeAcc = 0;
        if (inboxAccs.length > 0) {
            beforeAcc = inboxAccs[inboxAccs.length - 1];
        }

        (bytes32 acc, uint256 count) = includeDelayedMessages(
            beforeAcc,
            startNum,
            _totalDelayedMessagesRead,
            block.number,
            block.timestamp,
            delayedAcc
        );
        inboxAccs.push(acc);
        messageCount = count;
        emit DelayedInboxForced(
            startNum,
            beforeAcc,
            count,
            _totalDelayedMessagesRead,
            [acc, delayedAcc],
            inboxAccs.length - 1
        );
    }

    function addSequencerL2BatchFromOrigin(
        bytes calldata transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc
    ) external whenNotShutdownForNitro {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "origin only");
        uint256 startNum = messageCount;
        bytes32 beforeAcc = addSequencerL2BatchImpl(
            transactions,
            lengths,
            sectionsMetadata,
            afterAcc
        );
        emit SequencerBatchDeliveredFromOrigin(
            startNum,
            beforeAcc,
            messageCount,
            afterAcc,
            inboxAccs.length - 1
        );
    }

    function addSequencerL2BatchFromOriginWithGasRefunder(
        bytes calldata transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc,
        IGasRefunder gasRefunder
    ) external whenNotShutdownForNitro {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "origin only");

        uint256 startGasLeft = gasleft();
        uint256 calldataSize;
        assembly {
            calldataSize := calldatasize()
        }

        uint256 startNum = messageCount;
        bytes32 beforeAcc = addSequencerL2BatchImpl(
            transactions,
            lengths,
            sectionsMetadata,
            afterAcc
        );
        emit SequencerBatchDeliveredFromOrigin(
            startNum,
            beforeAcc,
            messageCount,
            afterAcc,
            inboxAccs.length - 1
        );

        if (gasRefunder != IGasRefunder(0)) {
            gasRefunder.onGasSpent(msg.sender, startGasLeft - gasleft(), calldataSize);
        }
    }

    /**
     * @notice Sequencer adds a batch to inbox.
     * @param transactions concatenated bytes of L2 messages
     * @param lengths length of each txn in transctions (for parsing)
     * @param sectionsMetadata Each consists of [numItems, l1BlockNumber, l1Timestamp, newTotalDelayedMessagesRead, newDelayedAcc]
     * @param afterAcc Expected inbox hash after batch is added
     * @dev sectionsMetadata lets the sequencer delineate new l1Block numbers and l1Timestamps within a given batch; this lets the sequencer minimize the number of batches created (and thus amortizing cost) while still giving timely receipts
     */
    function addSequencerL2Batch(
        bytes calldata transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc
    ) external whenNotShutdownForNitro {
        uint256 startNum = messageCount;
        bytes32 beforeAcc = addSequencerL2BatchImpl(
            transactions,
            lengths,
            sectionsMetadata,
            afterAcc
        );
        emit SequencerBatchDelivered(
            startNum,
            beforeAcc,
            messageCount,
            afterAcc,
            transactions,
            lengths,
            sectionsMetadata,
            inboxAccs.length - 1,
            msg.sender
        );
    }

    function addSequencerL2BatchImpl(
        bytes memory transactions,
        uint256[] calldata lengths,
        uint256[] calldata sectionsMetadata,
        bytes32 afterAcc
    ) private returns (bytes32 beforeAcc) {
        require(isSequencer[msg.sender], "ONLY_SEQUENCER");

        if (inboxAccs.length > 0) {
            beforeAcc = inboxAccs[inboxAccs.length - 1];
        }

        uint256 runningCount = messageCount;
        bytes32 runningAcc = beforeAcc;
        uint256 processedItems = 0;
        uint256 dataOffset;
        assembly {
            dataOffset := add(transactions, 32)
        }
        for (uint256 i = 0; i + 5 <= sectionsMetadata.length; i += 5) {
            // Each metadata section consists of:
            // [numItems, l1BlockNumber, l1Timestamp, newTotalDelayedMessagesRead, newDelayedAcc]
            {
                uint256 l1BlockNumber = sectionsMetadata[i + 1];
                require(l1BlockNumber + maxDelayBlocks >= block.number, "BLOCK_TOO_OLD");
                require(l1BlockNumber <= block.number, "BLOCK_TOO_NEW");
            }
            {
                uint256 l1Timestamp = sectionsMetadata[i + 2];
                require(l1Timestamp + maxDelaySeconds >= block.timestamp, "TIME_TOO_OLD");
                require(l1Timestamp <= block.timestamp, "TIME_TOO_NEW");
            }

            {
                bytes32 prefixHash = keccak256(
                    abi.encodePacked(msg.sender, sectionsMetadata[i + 1], sectionsMetadata[i + 2])
                );
                uint256 numItems = sectionsMetadata[i];
                (runningAcc, runningCount, dataOffset) = calcL2Batch(
                    dataOffset,
                    lengths,
                    processedItems,
                    numItems,
                    prefixHash,
                    runningCount,
                    runningAcc
                );
                processedItems += numItems;
            }

            uint256 newTotalDelayedMessagesRead = sectionsMetadata[i + 3];
            require(newTotalDelayedMessagesRead >= totalDelayedMessagesRead, "DELAYED_BACKWARDS");
            require(newTotalDelayedMessagesRead >= 1, "MUST_DELAYED_INIT");
            require(
                totalDelayedMessagesRead >= 1 || sectionsMetadata[i] == 0,
                "MUST_DELAYED_INIT_START"
            );
            // Sequencer decides how many messages (if any) to include from the delayed inbox
            if (newTotalDelayedMessagesRead > totalDelayedMessagesRead) {
                (runningAcc, runningCount) = includeDelayedMessages(
                    runningAcc,
                    runningCount,
                    newTotalDelayedMessagesRead,
                    sectionsMetadata[i + 1], // block number
                    sectionsMetadata[i + 2], // timestamp
                    bytes32(sectionsMetadata[i + 4]) // delayed accumulator
                );
            }
        }

        uint256 startOffset;
        assembly {
            startOffset := add(transactions, 32)
        }
        require(dataOffset >= startOffset, "OFFSET_OVERFLOW");
        require(dataOffset <= startOffset + transactions.length, "TRANSACTIONS_OVERRUN");

        require(runningCount > messageCount, "EMPTY_BATCH");
        inboxAccs.push(runningAcc);
        messageCount = runningCount;

        require(runningAcc == afterAcc, "AFTER_ACC");
    }

    function calcL2Batch(
        uint256 beforeOffset,
        uint256[] calldata lengths,
        uint256 lengthsOffset,
        uint256 itemCount,
        bytes32 prefixHash,
        uint256 beforeCount,
        bytes32 beforeAcc
    )
        private
        pure
        returns (
            bytes32 acc,
            uint256 count,
            uint256 offset
        )
    {
        offset = beforeOffset;
        count = beforeCount;
        acc = beforeAcc;
        itemCount += lengthsOffset;
        for (uint256 i = lengthsOffset; i < itemCount; i++) {
            uint256 length = lengths[i];
            bytes32 messageDataHash;
            assembly {
                messageDataHash := keccak256(offset, length)
            }
            acc = keccak256(abi.encodePacked(acc, count, prefixHash, messageDataHash));
            offset += length;
            count++;
        }
        return (acc, count, offset);
    }

    // Precondition: _totalDelayedMessagesRead > totalDelayedMessagesRead
    function includeDelayedMessages(
        bytes32 acc,
        uint256 count,
        uint256 _totalDelayedMessagesRead,
        uint256 l1BlockNumber,
        uint256 timestamp,
        bytes32 delayedAcc
    ) private returns (bytes32, uint256) {
        require(_totalDelayedMessagesRead <= delayedInbox.messageCount(), "DELAYED_TOO_FAR");
        require(delayedAcc == delayedInbox.inboxAccs(_totalDelayedMessagesRead - 1), "DELAYED_ACC");
        acc = keccak256(
            abi.encodePacked(
                "Delayed messages:",
                acc,
                count,
                totalDelayedMessagesRead,
                _totalDelayedMessagesRead,
                delayedAcc
            )
        );
        count += _totalDelayedMessagesRead - totalDelayedMessagesRead;
        bytes memory emptyBytes;
        acc = keccak256(
            abi.encodePacked(
                acc,
                count,
                keccak256(abi.encodePacked(address(0), l1BlockNumber, timestamp)),
                keccak256(emptyBytes)
            )
        );
        count++;
        totalDelayedMessagesRead = _totalDelayedMessagesRead;
        return (acc, count);
    }

    /**
     * @notice Prove message count as of provided inbox state hash
     * @param proof proof data
     * @param offset offset for parsing proof data
     * @param inboxAcc target inbox state hash
     */
    function proveSeqBatchMsgCount(
        bytes calldata proof,
        uint256 offset,
        bytes32 inboxAcc
    ) internal pure returns (uint256, uint256) {
        uint256 endMessageCount;

        bytes32 buildingAcc;
        uint256 seqNum;
        bytes32 messageHeaderHash;
        bytes32 messageDataHash;
        (offset, buildingAcc) = Marshaling.deserializeBytes32(proof, offset);
        (offset, seqNum) = Marshaling.deserializeInt(proof, offset);
        (offset, messageHeaderHash) = Marshaling.deserializeBytes32(proof, offset);
        (offset, messageDataHash) = Marshaling.deserializeBytes32(proof, offset);
        buildingAcc = keccak256(
            abi.encodePacked(buildingAcc, seqNum, messageHeaderHash, messageDataHash)
        );
        endMessageCount = seqNum + 1;
        require(buildingAcc == inboxAcc, "BATCH_ACC");

        return (offset, endMessageCount);
    }

    /**
     * @notice Show that given messageCount falls inside of some batch and prove/return inboxAcc state. This is used to ensure that the creation of new nodes are replay protected to the state of the inbox, thereby ensuring their validity/invalidy can't be modified upon reorging the inbox contents.
     * @dev (wrapper in leiu of proveBatchContainsSequenceNumber for sementics)
     * @return (message count at end of target batch, inbox hash as of target batch)
     */
    function proveInboxContainsMessage(bytes calldata proof, uint256 _messageCount)
        external
        view
        override
        returns (uint256, bytes32)
    {
        return proveInboxContainsMessageImp(proof, _messageCount);
    }

    // deprecated in favor of proveInboxContainsMessage
    function proveBatchContainsSequenceNumber(bytes calldata proof, uint256 _messageCount)
        external
        view
        returns (uint256, bytes32)
    {
        return proveInboxContainsMessageImp(proof, _messageCount);
    }

    function proveInboxContainsMessageImp(bytes calldata proof, uint256 _messageCount)
        internal
        view
        returns (uint256, bytes32)
    {
        if (_messageCount == 0) {
            return (0, 0);
        }

        (uint256 offset, uint256 targetInboxStateIndex) = Marshaling.deserializeInt(proof, 0);

        uint256 messageCountAsOfPreviousInboxState = 0;
        if (targetInboxStateIndex > 0) {
            (offset, messageCountAsOfPreviousInboxState) = proveSeqBatchMsgCount(
                proof,
                offset,
                inboxAccs[targetInboxStateIndex - 1]
            );
        }

        bytes32 targetInboxState = inboxAccs[targetInboxStateIndex];
        uint256 messageCountAsOfTargetInboxState;
        (offset, messageCountAsOfTargetInboxState) = proveSeqBatchMsgCount(
            proof,
            offset,
            targetInboxState
        );

        require(_messageCount > messageCountAsOfPreviousInboxState, "BATCH_START");
        require(_messageCount <= messageCountAsOfTargetInboxState, "BATCH_END");

        return (messageCountAsOfTargetInboxState, targetInboxState);
    }

    function getInboxAccsLength() external view override returns (uint256) {
        return inboxAccs.length;
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

pragma solidity ^0.6.11;

import "./OutboxEntry.sol";

import "../interfaces/IOutbox.sol";
import "../interfaces/IBridge.sol";

import "../Messages.sol";
import "../../libraries/MerkleLib.sol";
import "../../libraries/BytesLib.sol";
import "../../libraries/Cloneable.sol";
import "../../rollup/Rollup.sol";

import "@openzeppelin/contracts/proxy/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OldOutbox is IOutbox, Cloneable {
    using BytesLib for bytes;

    bytes1 internal constant MSG_ROOT = 0;

    uint8 internal constant SendType_sendTxToL1 = 3;

    address public rollup;
    IBridge public bridge;

    UpgradeableBeacon public beacon;
    OutboxEntry[] public outboxes;

    // Note, these variables are set and then wiped during a single transaction.
    // Therefore their values don't need to be maintained, and their slots will
    // be empty outside of transactions
    address internal _sender;
    uint128 internal _l2Block;
    uint128 internal _l1Block;
    uint128 internal _timestamp;
    uint128 public constant OUTBOX_VERSION = 0;

    function initialize(address _rollup, IBridge _bridge) external {
        require(rollup == address(0), "ALREADY_INIT");
        rollup = _rollup;
        bridge = _bridge;

        address outboxEntryTemplate = address(new OutboxEntry());
        beacon = new UpgradeableBeacon(outboxEntryTemplate);
        beacon.transferOwnership(_rollup);
    }

    /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
    /// When the return value is zero, that means this is a system message
    function l2ToL1Sender() external view override returns (address) {
        return _sender;
    }

    function l2ToL1Block() external view override returns (uint256) {
        return uint256(_l2Block);
    }

    function l2ToL1EthBlock() external view override returns (uint256) {
        return uint256(_l1Block);
    }

    function l2ToL1Timestamp() external view override returns (uint256) {
        return uint256(_timestamp);
    }

    function l2ToL1BatchNum() external view override returns (uint256) {
        revert("NOT_IMPLEMENTED");
    }

    function l2ToL1OutputId() external view override returns (bytes32) {
        revert("NOT_IMPLEMENTED");
    }

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external
        override
    {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        // If we've reached here, we've already confirmed that sum(sendLengths) == sendsData.length
        uint256 messageCount = sendLengths.length;
        uint256 offset = 0;
        for (uint256 i = 0; i < messageCount; i++) {
            handleOutgoingMessage(bytes(sendsData[offset:offset + sendLengths[i]]));
            offset += sendLengths[i];
        }
    }

    function handleOutgoingMessage(bytes memory data) private {
        // Otherwise we have an unsupported message type and we skip the message
        if (data[0] == MSG_ROOT) {
            require(data.length == 97, "BAD_LENGTH");
            uint256 batchNum = data.toUint(1);
            uint256 numInBatch = data.toUint(33);
            bytes32 outputRoot = data.toBytes32(65);

            address clone = address(new BeaconProxy(address(beacon), ""));
            OutboxEntry(clone).initialize(outputRoot, numInBatch);
            uint256 outboxIndex = outboxes.length;
            outboxes.push(OutboxEntry(clone));
            emit OutboxEntryCreated(batchNum, outboxIndex, outputRoot, numInBatch);
        }
    }

    /**
     * @notice Executes a messages in an Outbox entry. Reverts if dispute period hasn't expired and
     * @param outboxIndex Index of OutboxEntry in outboxes array
     * @param proof Merkle proof of message inclusion in outbox entry
     * @param index Merkle path to message
     * @param l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @param destAddr destination address for L1 contract call
     * @param l2Block l2 block number at which sendTxToL1 call was made
     * @param l1Block l1 block number at which sendTxToL1 call was made
     * @param l2Timestamp l2 Timestamp at which sendTxToL1 call was made
     * @param amount value in L1 message in wei
     * @param calldataForL1 abi-encoded L1 message data
     */
    function executeTransaction(
        uint256 outboxIndex,
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) external virtual {
        bytes32 userTx = calculateItemHash(
            l2Sender,
            destAddr,
            l2Block,
            l1Block,
            l2Timestamp,
            amount,
            calldataForL1
        );

        spendOutput(outboxIndex, proof, index, userTx);
        emit OutBoxTransactionExecuted(destAddr, l2Sender, outboxIndex, index);

        address currentSender = _sender;
        uint128 currentL2Block = _l2Block;
        uint128 currentL1Block = _l1Block;
        uint128 currentTimestamp = _timestamp;

        _sender = l2Sender;
        _l2Block = uint128(l2Block);
        _l1Block = uint128(l1Block);
        _timestamp = uint128(l2Timestamp);

        executeBridgeCall(destAddr, amount, calldataForL1);

        _sender = currentSender;
        _l2Block = currentL2Block;
        _l1Block = currentL1Block;
        _timestamp = currentTimestamp;
    }

    function spendOutput(
        uint256 outboxIndex,
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) internal {
        require(proof.length < 256, "PROOF_TOO_LONG");
        require(path < 2**proof.length, "PATH_NOT_MINIMAL");

        // Hash the leaf an extra time to prove it's a leaf
        bytes32 calcRoot = calculateMerkleRoot(proof, path, item);
        OutboxEntry outbox = outboxes[outboxIndex];
        require(address(outbox) != address(0), "NO_OUTBOX");

        // With a minimal path, the pair of path and proof length should always identify
        // a unique leaf. The path itself is not enough since the path length to different
        // leaves could potentially be different
        bytes32 uniqueKey = keccak256(abi.encodePacked(path, proof.length));
        uint256 numRemaining = outbox.spendOutput(calcRoot, uniqueKey);

        if (numRemaining == 0) {
            outbox.destroy();
            outboxes[outboxIndex] = OutboxEntry(address(0));
        }
    }

    function executeBridgeCall(
        address destAddr,
        uint256 amount,
        bytes memory data
    ) internal {
        (bool success, bytes memory returndata) = bridge.executeCall(destAddr, amount, data);
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("BRIDGE_CALL_FAILED");
            }
        }
    }

    function calculateItemHash(
        address l2Sender,
        address destAddr,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 amount,
        bytes calldata calldataForL1
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    SendType_sendTxToL1,
                    uint256(uint160(bytes20(l2Sender))),
                    uint256(uint160(bytes20(destAddr))),
                    l2Block,
                    l1Block,
                    l2Timestamp,
                    amount,
                    calldataForL1
                )
            );
    }

    function calculateMerkleRoot(
        bytes32[] memory proof,
        uint256 path,
        bytes32 item
    ) public pure returns (bytes32) {
        return MerkleLib.calculateRoot(proof, path, keccak256(abi.encodePacked(item)));
    }

    function outboxEntryExists(uint256 batchNum) public view override returns (bool) {
        return batchNum < outboxes.length;
    }

    function outboxesLength() public view returns (uint256) {
        return outboxes.length;
    }

    function setBridge(IBridge newBridge) external override {
        require(msg.sender == OwnableUpgradeable(address(bridge)).owner(), "NOT_BRIDGE_OWNER");
        bridge = newBridge;
    }

    function isNitroReady() external pure override returns (uint256) {
        return 0xa4b1;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.11;

import "../Rollup.sol";
import "../INode.sol";
import "./IRollupFacets.sol";
import "../../bridge/interfaces/IOutbox.sol";
import "../../bridge/interfaces/ISequencerInbox.sol";
import "../../libraries/Whitelist.sol";

import "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RollupAdminFacet is RollupBase, IRollupAdmin {
    event NodeDestroyedInMigration(uint256 nodeNum);
    event ChallengeDestroyedInMigration(address challenge);
    event StakerWithdrawnInMigration(address staker);

    /**
     * Functions are only to reach this facet if the caller is the owner
     * so there is no need for a redundant onlyOwner check
     */

    /**
     * @notice Add a contract authorized to put messages into this rollup's inbox
     * @param _outbox Outbox contract to add
     */
    function setOutbox(IOutbox _outbox) external override {
        outbox = _outbox;
        delayedBridge.setOutbox(address(_outbox), true);
        emit OwnerFunctionCalled(0);
    }

    /**
     * @notice Disable an old outbox from interacting with the bridge
     * @param _outbox Outbox contract to remove
     */
    function removeOldOutbox(address _outbox) external override {
        require(_outbox != address(outbox), "CUR_OUTBOX");
        delayedBridge.setOutbox(_outbox, false);
        emit OwnerFunctionCalled(1);
    }

    /**
     * @notice Enable or disable an inbox contract
     * @param _inbox Inbox contract to add or remove
     * @param _enabled New status of inbox
     */
    function setInbox(address _inbox, bool _enabled) external override {
        delayedBridge.setInbox(address(_inbox), _enabled);
        emit OwnerFunctionCalled(2);
    }

    /**
     * @notice Pause interaction with the rollup contract.
     * The time spent paused is not incremented in the rollup's timing for node validation.
     */
    function pause() external override {
        _pause();
        emit OwnerFunctionCalled(3);
    }

    /**
     * @notice Resume interaction with the rollup contract
     */
    function resume() external override {
        _unpause();
        emit OwnerFunctionCalled(4);
    }

    /**
     * @notice Set the addresses of rollup logic facets called
     * @param newAdminFacet address of logic that owner of rollup calls
     * @param newUserFacet address of logic that user of rollup calls
     */
    function setFacets(address newAdminFacet, address newUserFacet) external override {
        facets[0] = newAdminFacet;
        facets[1] = newUserFacet;
        emit OwnerFunctionCalled(5);
    }

    /**
     * @notice Set the addresses of the validator whitelist
     * @dev It is expected that both arrays are same length, and validator at
     * position i corresponds to the value at position i
     * @param _validator addresses to set in the whitelist
     * @param _val value to set in the whitelist for corresponding address
     */
    function setValidator(address[] memory _validator, bool[] memory _val) external override {
        require(_validator.length == _val.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < _validator.length; i++) {
            isValidator[_validator[i]] = _val[i];
        }
        emit OwnerFunctionCalled(6);
    }

    /**
     * @notice Set a new owner address for the rollup
     * @param newOwner address of new rollup owner
     */
    function setOwner(address newOwner) external override {
        owner = newOwner;
        emit OwnerFunctionCalled(7);
    }

    /**
     * @notice Set minimum assertion period for the rollup
     * @param newPeriod new minimum period for assertions
     */
    function setMinimumAssertionPeriod(uint256 newPeriod) external override {
        minimumAssertionPeriod = newPeriod;
        emit OwnerFunctionCalled(8);
    }

    /**
     * @notice Set number of blocks until a node is considered confirmed
     * @param newConfirmPeriod new number of blocks
     */
    function setConfirmPeriodBlocks(uint256 newConfirmPeriod) external override {
        confirmPeriodBlocks = newConfirmPeriod;
        emit OwnerFunctionCalled(9);
    }

    /**
     * @notice Set number of extra blocks after a challenge
     * @param newExtraTimeBlocks new number of blocks
     */
    function setExtraChallengeTimeBlocks(uint256 newExtraTimeBlocks) external override {
        extraChallengeTimeBlocks = newExtraTimeBlocks;
        emit OwnerFunctionCalled(10);
    }

    /**
     * @notice Set speed limit per block
     * @param newAvmGasSpeedLimitPerBlock maximum avmgas to be used per block
     */
    function setAvmGasSpeedLimitPerBlock(uint256 newAvmGasSpeedLimitPerBlock) external override {
        avmGasSpeedLimitPerBlock = newAvmGasSpeedLimitPerBlock;
        emit OwnerFunctionCalled(11);
    }

    /**
     * @notice Set base stake required for an assertion
     * @param newBaseStake minimum amount of stake required
     */
    function setBaseStake(uint256 newBaseStake) external override {
        baseStake = newBaseStake;
        emit OwnerFunctionCalled(12);
    }

    /**
     * @notice Set the token used for stake, where address(0) == eth
     * @dev Before changing the base stake token, you might need to change the
     * implementation of the Rollup User facet!
     * @param newStakeToken address of token used for staking
     */
    function setStakeToken(address newStakeToken) external override {
        stakeToken = newStakeToken;
        emit OwnerFunctionCalled(13);
    }

    /**
     * @notice Set max delay for sequencer inbox
     * @param newSequencerInboxMaxDelayBlocks max number of blocks
     * @param newSequencerInboxMaxDelaySeconds max number of seconds
     */
    function setSequencerInboxMaxDelay(
        uint256 newSequencerInboxMaxDelayBlocks,
        uint256 newSequencerInboxMaxDelaySeconds
    ) external override {
        ISequencerInbox(sequencerBridge).setMaxDelay(
            newSequencerInboxMaxDelayBlocks,
            newSequencerInboxMaxDelaySeconds
        );
        emit OwnerFunctionCalled(14);
    }

    /**
     * @notice Set execution bisection degree
     * @param newChallengeExecutionBisectionDegree execution bisection degree
     */
    function setChallengeExecutionBisectionDegree(uint256 newChallengeExecutionBisectionDegree)
        external
        override
    {
        challengeExecutionBisectionDegree = newChallengeExecutionBisectionDegree;
        emit OwnerFunctionCalled(16);
    }

    /**
     * @notice Updates a whitelist address for its consumers
     * @dev setting the newWhitelist to address(0) disables it for consumers
     * @param whitelist old whitelist to be deprecated
     * @param newWhitelist new whitelist to be used
     * @param targets whitelist consumers to be triggered
     */
    function updateWhitelistConsumers(
        address whitelist,
        address newWhitelist,
        address[] memory targets
    ) external override {
        Whitelist(whitelist).triggerConsumers(newWhitelist, targets);
        emit OwnerFunctionCalled(17);
    }

    /**
     * @notice Updates a whitelist's entries
     * @dev user at position i will be assigned value i
     * @param whitelist whitelist to be updated
     * @param user users to be updated in the whitelist
     * @param val if user is or not allowed in the whitelist
     */
    function setWhitelistEntries(
        address whitelist,
        address[] memory user,
        bool[] memory val
    ) external override {
        require(user.length == val.length, "INVALID_INPUT");
        Whitelist(whitelist).setWhitelist(user, val);
        emit OwnerFunctionCalled(18);
    }

    /**
     * @notice Updates a sequencer address at the sequencer inbox
     * @param newSequencer new sequencer address to be used
     */
    function setIsSequencer(address newSequencer, bool isSequencer) external override {
        ISequencerInbox(sequencerBridge).setIsSequencer(newSequencer, isSequencer);
        emit OwnerFunctionCalled(19);
    }

    /**
     * @notice Upgrades the implementation of a beacon controlled by the rollup
     * @param beacon address of beacon to be upgraded
     * @param newImplementation new address of implementation
     */
    function upgradeBeacon(address beacon, address newImplementation) external override {
        UpgradeableBeacon(beacon).upgradeTo(newImplementation);
        emit OwnerFunctionCalled(20);
    }

    function forceResolveChallenge(address[] memory stakerA, address[] memory stakerB)
        external
        override
        whenPaused
    {
        require(stakerA.length == stakerB.length, "WRONG_LENGTH");
        for (uint256 i = 0; i < stakerA.length; i++) {
            address chall = inChallenge(stakerA[i], stakerB[i]);

            require(address(0) != chall, "NOT_IN_CHALL");
            clearChallenge(stakerA[i]);
            clearChallenge(stakerB[i]);

            IChallenge(chall).clearChallenge();
        }
        emit OwnerFunctionCalled(21);
    }

    function forceRefundStaker(address[] memory staker) external override whenPaused {
        for (uint256 i = 0; i < staker.length; i++) {
            reduceStakeTo(staker[i], 0);
            turnIntoZombie(staker[i]);
        }
        emit OwnerFunctionCalled(22);
    }

    function forceCreateNode(
        bytes32 expectedNodeHash,
        bytes32[3][2] calldata assertionBytes32Fields,
        uint256[4][2] calldata assertionIntFields,
        bytes calldata sequencerBatchProof,
        uint256 beforeProposedBlock,
        uint256 beforeInboxMaxCount,
        uint256 prevNode
    ) external override whenPaused {
        require(prevNode == latestConfirmed(), "ONLY_LATEST_CONFIRMED");

        RollupLib.Assertion memory assertion = RollupLib.decodeAssertion(
            assertionBytes32Fields,
            assertionIntFields,
            beforeProposedBlock,
            beforeInboxMaxCount,
            sequencerBridge.messageCount()
        );

        createNewNode(
            assertion,
            assertionBytes32Fields,
            assertionIntFields,
            sequencerBatchProof,
            CreateNodeDataFrame({
                avmGasSpeedLimitPerBlock: avmGasSpeedLimitPerBlock,
                confirmPeriodBlocks: confirmPeriodBlocks,
                prevNode: prevNode,
                sequencerInbox: sequencerBridge,
                rollupEventBridge: rollupEventBridge,
                nodeFactory: nodeFactory
            }),
            expectedNodeHash
        );

        emit OwnerFunctionCalled(23);
    }

    function forceConfirmNode(
        uint256 nodeNum,
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount
    ) external override whenPaused {
        // this skips deadline, staker and zombie validation
        confirmNode(
            nodeNum,
            beforeSendAcc,
            sendsData,
            sendLengths,
            afterSendCount,
            afterLogAcc,
            afterLogCount,
            outbox,
            rollupEventBridge
        );
        emit OwnerFunctionCalled(24);
    }

    /// @dev this function is intended to be called as part of the shutdown process of the classic contracts in favour of nitro
    /// It is expected that the rollup is not paused during the start of shutdown step, the shutdown procedure will pause the rollup.
    /// A final rollup node number is specified, then the rollup will only allow that node and its direct predecessors to be confirmed.
    /// All nodes that aren't directly previous to this are deleted, but in practice none are expected to be present (as this would mean an eventual challenge).
    /// Even though the rollup is paused, we use the `shutdownForNitroMode` var to allow validators to go through the sequence of final nodes confirming them so their send values are added to the outbox
    /// The deadline for the nodes marked as final are ignored to a lower value to allow for these faster confirmations, which will make L2 to L1 txs available for execution sooner
    function shutdownForNitro(
        uint256 finalNodeNum,
        bool destroyAlternatives,
        bool destroyChallenges
    ) external whenNotPaused {
        require(!shutdownForNitroMode(), "ALREADY_SHUTDOWN_MODE");
        // TODO: prove that final node num includes the last send by arbos

        // first we destroy all nodes that aren't in the correct chain
        uint256 latestConfirmedNodeNum = latestConfirmed();
        uint256 curr = latestNodeCreated();
        uint256 expectedPrev = finalNodeNum;
        // if finalNodeNum == latestConfirmed we don't need to delete any siblings
        while (curr != latestConfirmedNodeNum) {
            if (curr == expectedPrev) {
                INode currNode = getNode(curr);
                expectedPrev = currNode.prev();
            } else {
                require(destroyAlternatives, "ALTERNATIVES_NOT_EXPECTED");
                destroyNode(curr);
                emit NodeDestroyedInMigration(curr);
            }
            curr--;
        }

        uint256 stakerCount = stakerCount();
        address[] memory stakerAddresses = new address[](stakerCount);

        // we separate the loop that gets staker addresses to be different from the loop that withdraw stakers
        // since withdrawing stakers has side-effects on the array that is queried in `getStakerAddress`.
        for (uint64 i = 0; i < stakerCount; ++i) {
            stakerAddresses[i] = getStakerAddress(i);
        }

        for (uint64 i = 0; i < stakerCount; ++i) {
            address stakerAddr = stakerAddresses[i];
            address chall = currentChallenge(stakerAddr);

            if (chall != address(0)) {
                require(destroyChallenges, "CHALLENGE_NOT_EXPECTED");
                address asserter = IChallenge(chall).asserter();
                address challenger = IChallenge(chall).challenger();

                clearChallenge(asserter);
                clearChallenge(challenger);

                IChallenge(chall).clearChallenge();
                emit ChallengeDestroyedInMigration(chall);
            }

            if (getNode(latestStakedNode(stakerAddr)) == INode(0)) {
                // this node got destroyed, so we force refund the staker
                withdrawStaker(stakerAddr);
                emit StakerWithdrawnInMigration(stakerAddr);
            }
            // else the staker can unstake and withdraw regularly using `returnOldDeposit`
        }

        shutdownForNitroBlock = block.number;
        _pause();
        emit OwnerFunctionCalled(25);
    }

    /// @dev stops the rollup from shutdownForNitro mode in case something goes wrong during the migration process
    function undoShutdownForNitro() external whenPaused {
        require(shutdownForNitroMode(), "NOT_SHUTDOWN_MODE");
        shutdownForNitroBlock = type(uint256).max;
        _unpause();
        emit OwnerFunctionCalled(26);
    }

    /// @dev allows the admin to transfer the ownership of a contract controlled by the rollup
    function transferOwnership(Ownable target, address newOwner) external {
        target.transferOwnership(newOwner);
        emit OwnerFunctionCalled(27);
    }

    function isNitroReady() external pure returns (uint256) {
        return 0xa4b2;
    }
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

pragma solidity ^0.6.11;

import "./Rollup.sol";
import "./facets/IRollupFacets.sol";

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/IMessageProvider.sol";
import "./INode.sol";
import "../libraries/Cloneable.sol";

contract RollupEventBridge is IMessageProvider, Cloneable {
    uint8 internal constant INITIALIZATION_MSG_TYPE = 11;
    uint8 internal constant ROLLUP_PROTOCOL_EVENT_TYPE = 8;

    uint8 internal constant CREATE_NODE_EVENT = 0;
    uint8 internal constant CONFIRM_NODE_EVENT = 1;
    uint8 internal constant REJECT_NODE_EVENT = 2;
    uint8 internal constant STAKE_CREATED_EVENT = 3;

    IBridge bridge;
    address rollup;

    modifier onlyRollup() {
        require(msg.sender == rollup, "ONLY_ROLLUP");
        _;
    }

    function initialize(address _bridge, address _rollup) external {
        require(rollup == address(0), "ALREADY_INIT");
        bridge = IBridge(_bridge);
        rollup = _rollup;
    }

    function rollupInitialized(
        uint256 confirmPeriodBlocks,
        uint256 avmGasSpeedLimitPerBlock,
        address owner,
        bytes calldata extraConfig
    ) external onlyRollup {
        bytes memory initMsg = abi.encodePacked(
            keccak256("ChallengePeriodEthBlocks"),
            confirmPeriodBlocks,
            keccak256("SpeedLimitPerSecond"),
            avmGasSpeedLimitPerBlock / 100, // convert avm gas to arbgas
            keccak256("ChainOwner"),
            uint256(uint160(bytes20(owner))),
            extraConfig
        );
        uint256 num = bridge.deliverMessageToInbox(
            INITIALIZATION_MSG_TYPE,
            address(0),
            keccak256(initMsg)
        );
        emit InboxMessageDelivered(num, initMsg);
    }

    function nodeCreated(
        uint256 nodeNum,
        uint256 prev,
        uint256 deadline,
        address asserter
    ) external onlyRollup {
        deliverToBridge(
            abi.encodePacked(
                CREATE_NODE_EVENT,
                nodeNum,
                prev,
                block.number,
                deadline,
                uint256(uint160(bytes20(asserter)))
            )
        );
    }

    function nodeConfirmed(uint256 nodeNum) external onlyRollup {
        deliverToBridge(abi.encodePacked(CONFIRM_NODE_EVENT, nodeNum));
    }

    function nodeRejected(uint256 nodeNum) external onlyRollup {
        deliverToBridge(abi.encodePacked(REJECT_NODE_EVENT, nodeNum));
    }

    function stakeCreated(address staker, uint256 nodeNum) external onlyRollup {
        deliverToBridge(
            abi.encodePacked(
                STAKE_CREATED_EVENT,
                uint256(uint160(bytes20(staker))),
                nodeNum,
                block.number
            )
        );
    }

    function deliverToBridge(bytes memory message) private {
        emit InboxMessageDelivered(
            bridge.deliverMessageToInbox(
                ROLLUP_PROTOCOL_EVENT_TYPE,
                msg.sender,
                keccak256(message)
            ),
            message
        );
    }
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

pragma solidity ^0.6.11;

import "../challenge/ChallengeLib.sol";
import "./INode.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

library RollupLib {
    using SafeMath for uint256;

    struct Config {
        bytes32 machineHash;
        uint256 confirmPeriodBlocks;
        uint256 extraChallengeTimeBlocks;
        uint256 avmGasSpeedLimitPerBlock;
        uint256 baseStake;
        address stakeToken;
        address owner;
        address sequencer;
        uint256 sequencerDelayBlocks;
        uint256 sequencerDelaySeconds;
        bytes extraConfig;
    }

    struct ExecutionState {
        uint256 gasUsed;
        bytes32 machineHash;
        uint256 inboxCount;
        uint256 sendCount;
        uint256 logCount;
        bytes32 sendAcc;
        bytes32 logAcc;
        uint256 proposedBlock;
        uint256 inboxMaxCount;
    }

    function stateHash(ExecutionState memory execState) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    execState.gasUsed,
                    execState.machineHash,
                    execState.inboxCount,
                    execState.sendCount,
                    execState.logCount,
                    execState.sendAcc,
                    execState.logAcc,
                    execState.proposedBlock,
                    execState.inboxMaxCount
                )
            );
    }

    struct Assertion {
        ExecutionState beforeState;
        ExecutionState afterState;
    }

    function decodeExecutionState(
        bytes32[3] memory bytes32Fields,
        uint256[4] memory intFields,
        uint256 proposedBlock,
        uint256 inboxMaxCount
    ) internal pure returns (ExecutionState memory) {
        return
            ExecutionState(
                intFields[0],
                bytes32Fields[0],
                intFields[1],
                intFields[2],
                intFields[3],
                bytes32Fields[1],
                bytes32Fields[2],
                proposedBlock,
                inboxMaxCount
            );
    }

    function decodeAssertion(
        bytes32[3][2] memory bytes32Fields,
        uint256[4][2] memory intFields,
        uint256 beforeProposedBlock,
        uint256 beforeInboxMaxCount,
        uint256 inboxMaxCount
    ) internal view returns (Assertion memory) {
        return
            Assertion(
                decodeExecutionState(
                    bytes32Fields[0],
                    intFields[0],
                    beforeProposedBlock,
                    beforeInboxMaxCount
                ),
                decodeExecutionState(bytes32Fields[1], intFields[1], block.number, inboxMaxCount)
            );
    }

    function executionStateChallengeHash(ExecutionState memory state)
        internal
        pure
        returns (bytes32)
    {
        return
            ChallengeLib.assertionHash(
                state.gasUsed,
                ChallengeLib.assertionRestHash(
                    state.inboxCount,
                    state.machineHash,
                    state.sendAcc,
                    state.sendCount,
                    state.logAcc,
                    state.logCount
                )
            );
    }

    function executionHash(Assertion memory assertion) internal pure returns (bytes32) {
        return
            ChallengeLib.bisectionChunkHash(
                assertion.beforeState.gasUsed,
                assertion.afterState.gasUsed - assertion.beforeState.gasUsed,
                RollupLib.executionStateChallengeHash(assertion.beforeState),
                RollupLib.executionStateChallengeHash(assertion.afterState)
            );
    }

    function assertionGasUsed(RollupLib.Assertion memory assertion)
        internal
        pure
        returns (uint256)
    {
        return assertion.afterState.gasUsed.sub(assertion.beforeState.gasUsed);
    }

    function challengeRoot(
        Assertion memory assertion,
        bytes32 assertionExecHash,
        uint256 blockProposed
    ) internal pure returns (bytes32) {
        return challengeRootHash(assertionExecHash, blockProposed, assertion.afterState.inboxCount);
    }

    function challengeRootHash(
        bytes32 execution,
        uint256 proposedTime,
        uint256 maxMessageCount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(execution, proposedTime, maxMessageCount));
    }

    function confirmHash(Assertion memory assertion) internal pure returns (bytes32) {
        return
            confirmHash(
                assertion.beforeState.sendAcc,
                assertion.afterState.sendAcc,
                assertion.afterState.logAcc,
                assertion.afterState.sendCount,
                assertion.afterState.logCount
            );
    }

    function confirmHash(
        bytes32 beforeSendAcc,
        bytes32 afterSendAcc,
        bytes32 afterLogAcc,
        uint256 afterSendCount,
        uint256 afterLogCount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    beforeSendAcc,
                    afterSendAcc,
                    afterSendCount,
                    afterLogAcc,
                    afterLogCount
                )
            );
    }

    function feedAccumulator(
        bytes memory messageData,
        uint256[] memory messageLengths,
        bytes32 beforeAcc
    ) internal pure returns (bytes32) {
        uint256 offset = 0;
        uint256 messageCount = messageLengths.length;
        uint256 dataLength = messageData.length;
        bytes32 messageAcc = beforeAcc;
        for (uint256 i = 0; i < messageCount; i++) {
            uint256 messageLength = messageLengths[i];
            require(offset + messageLength <= dataLength, "DATA_OVERRUN");
            bytes32 messageHash;
            assembly {
                messageHash := keccak256(add(messageData, add(offset, 32)), messageLength)
            }
            messageAcc = keccak256(abi.encodePacked(messageAcc, messageHash));
            offset += messageLength;
        }
        require(offset == dataLength, "DATA_LENGTH");
        return messageAcc;
    }

    function nodeHash(
        bool hasSibling,
        bytes32 lastHash,
        bytes32 assertionExecHash,
        bytes32 inboxAcc
    ) internal pure returns (bytes32) {
        uint8 hasSiblingInt = hasSibling ? 1 : 0;
        return keccak256(abi.encodePacked(hasSiblingInt, lastHash, assertionExecHash, inboxAcc));
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

pragma solidity ^0.6.11;

interface NitroReadyContract {
    function isNitroReady() external pure returns (uint256);
}

contract NitroReadyQuery {
    /// @dev queries a contract to know if its ready for the nitro upgrade
    function isNitroReady(address target) external pure returns (uint256) {
        return NitroReadyContract(target).isNitroReady();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IOwnable.sol";

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function enqueueSequencerMessage(bytes32 dataHash, uint256 afterDelayedMessagesRead)
        external
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        );

    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256 msgNum);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    function setSequencerInbox(address _sequencerInbox) external;

    // View functions

    function sequencerInbox() external view returns (address);

    function activeOutbox() external view returns (address);

    function allowedDelayedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function delayedInboxAccs(uint256 index) external view returns (bytes32);

    function sequencerInboxAccs(uint256 index) external view returns (bytes32);

    function delayedMessageCount() external view returns (uint256);

    function sequencerMessageCount() external view returns (uint256);

    function rollup() external view returns (IOwnable);

    function acceptFundsFromOldBridge() external payable;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";

interface IInbox is IDelayedMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    /// @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
    function createRetryableTicket(
        address to,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /// @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
    function unsafeCreateRetryableTicket(
        address to,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth() external payable returns (uint256);

    /// @notice deprecated in favour of depositEth with no parameters
    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);

    function postUpgradeInit(IBridge _bridge) external;
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed destAddr,
        uint256 amount,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

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

    function isNitroReady() external view returns (uint256);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
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

    function unsafeCreateRetryableTicket(
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

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
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

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./RollupEventBridge.sol";
import "./RollupCore.sol";
import "./RollupLib.sol";
import "./INode.sol";
import "./INodeFactory.sol";

import "../challenge/IChallenge.sol";
import "../challenge/IChallengeFactory.sol";

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/IOutbox.sol";
import "../bridge/Messages.sol";

import "../libraries/ProxyUtil.sol";
import "../libraries/Cloneable.sol";
import "./facets/IRollupFacets.sol";

abstract contract RollupBase is Cloneable, RollupCore, Pausable {
    // Rollup Config
    uint256 public confirmPeriodBlocks;
    uint256 public extraChallengeTimeBlocks;
    uint256 public avmGasSpeedLimitPerBlock;
    uint256 public baseStake;

    // Bridge is an IInbox and IOutbox
    IBridge public delayedBridge;
    ISequencerInbox public sequencerBridge;
    IOutbox public outbox;
    RollupEventBridge public rollupEventBridge;
    IChallengeFactory public challengeFactory;
    INodeFactory public nodeFactory;
    address public owner;
    address public stakeToken;
    uint256 public minimumAssertionPeriod;

    uint256 public STORAGE_GAP_1;
    uint256 public STORAGE_GAP_2;
    uint256 public challengeExecutionBisectionDegree;

    address[] internal facets;

    mapping(address => bool) isValidator;

    /// @dev indicates the block which the rollup starts the shutdown for nitro mode
    uint256 public shutdownForNitroBlock;

    /// @dev indicates if rollup is in shutdown for nitro mode
    function shutdownForNitroMode() public view returns (bool) {
        return block.number >= shutdownForNitroBlock;
    }

    /// @dev allows a function to be executed either if contract is either in `shutdownForNitroMode` or not paused
    modifier whenInShutdownModeOrNotPaused() {
        if (!shutdownForNitroMode()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    /// @notice DEPRECATED -- this method is deprecated but still mantained for backward compatibility
    /// @dev this actually returns the avmGasSpeedLimitPerBlock
    /// @return this actually returns the avmGasSpeedLimitPerBlock
    function arbGasSpeedLimitPerBlock() external view returns (uint256) {
        return avmGasSpeedLimitPerBlock;
    }
}

contract Rollup is Proxy, RollupBase {
    using Address for address;

    constructor(uint256 _confirmPeriodBlocks) public Cloneable() Pausable() {
        // constructor is used so logic contract can't be init'ed
        confirmPeriodBlocks = _confirmPeriodBlocks;
        require(isInit(), "CONSTRUCTOR_NOT_INIT");
    }

    function isInit() internal view returns (bool) {
        return confirmPeriodBlocks != 0;
    }

    // _rollupParams = [ confirmPeriodBlocks, extraChallengeTimeBlocks, avmGasSpeedLimitPerBlock, baseStake ]
    // connectedContracts = [delayedBridge, sequencerInbox, outbox, rollupEventBridge, challengeFactory, nodeFactory]
    function initialize(
        bytes32 _machineHash,
        uint256[4] calldata _rollupParams,
        address _stakeToken,
        address _owner,
        bytes calldata _extraConfig,
        address[6] calldata connectedContracts,
        address[2] calldata _facets,
        uint256[2] calldata sequencerInboxParams
    ) public {
        require(!isInit(), "ALREADY_INIT");

        // calls initialize method in user facet
        require(_facets[0].isContract(), "FACET_0_NOT_CONTRACT");
        require(_facets[1].isContract(), "FACET_1_NOT_CONTRACT");
        (bool success, ) = _facets[1].delegatecall(
            abi.encodeWithSelector(IRollupUser.initialize.selector, _stakeToken)
        );
        require(success, "FAIL_INIT_FACET");

        delayedBridge = IBridge(connectedContracts[0]);
        sequencerBridge = ISequencerInbox(connectedContracts[1]);
        outbox = IOutbox(connectedContracts[2]);
        delayedBridge.setOutbox(connectedContracts[2], true);
        rollupEventBridge = RollupEventBridge(connectedContracts[3]);
        delayedBridge.setInbox(connectedContracts[3], true);

        rollupEventBridge.rollupInitialized(
            _rollupParams[0],
            _rollupParams[2],
            _owner,
            _extraConfig
        );

        challengeFactory = IChallengeFactory(connectedContracts[4]);
        nodeFactory = INodeFactory(connectedContracts[5]);

        INode node = createInitialNode(_machineHash);
        initializeCore(node);

        confirmPeriodBlocks = _rollupParams[0];
        extraChallengeTimeBlocks = _rollupParams[1];
        avmGasSpeedLimitPerBlock = _rollupParams[2];
        baseStake = _rollupParams[3];
        owner = _owner;
        // A little over 15 minutes
        minimumAssertionPeriod = 75;
        challengeExecutionBisectionDegree = 400;

        sequencerBridge.setMaxDelay(sequencerInboxParams[0], sequencerInboxParams[1]);

        // facets[0] == admin, facets[1] == user
        facets = _facets;

        shutdownForNitroBlock = type(uint256).max;

        emit RollupCreated(_machineHash);
        require(isInit(), "INITIALIZE_NOT_INIT");
    }

    function postUpgradeInit() external {
        // it is assumed the rollup contract is behind a Proxy controlled by a proxy admin
        // this function can only be called by the proxy admin contract
        address proxyAdmin = ProxyUtil.getProxyAdmin();
        require(msg.sender == proxyAdmin, "NOT_FROM_ADMIN");

        shutdownForNitroBlock = type(uint256).max;
    }

    function createInitialNode(bytes32 _machineHash) private returns (INode) {
        bytes32 state = RollupLib.stateHash(
            RollupLib.ExecutionState(
                0, // total gas used
                _machineHash,
                0, // inbox count
                0, // send count
                0, // log count
                0, // send acc
                0, // log acc
                block.number, // block proposed
                1 // Initialization message already in inbox
            )
        );
        return
            INode(
                nodeFactory.createNode(
                    state,
                    0, // challenge hash (not challengeable)
                    0, // confirm data
                    0, // prev node
                    block.number // deadline block (not challengeable)
                )
            );
    }

    /**
     * This contract uses a dispatch pattern from EIP-2535: Diamonds
     * together with Open Zeppelin's proxy
     */

    function getFacets() external view returns (address, address) {
        return (getAdminFacet(), getUserFacet());
    }

    function getAdminFacet() public view returns (address) {
        return facets[0];
    }

    function getUserFacet() public view returns (address) {
        return facets[1];
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual override returns (address) {
        require(msg.data.length >= 4, "NO_FUNC_SIG");
        address rollupOwner = owner;
        // if there is an owner and it is the sender, delegate to admin facet
        address target = rollupOwner != address(0) && rollupOwner == msg.sender
            ? getAdminFacet()
            : getUserFacet();
        require(target.isContract(), "TARGET_NOT_CONTRACT");
        return target;
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

pragma solidity ^0.6.11;

library Messages {
    function messageHash(
        uint8 kind,
        address sender,
        uint256 blockNumber,
        uint256 timestamp,
        uint256 inboxSeqNum,
        uint256 gasPriceL1,
        bytes32 messageDataHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    kind,
                    sender,
                    blockNumber,
                    timestamp,
                    inboxSeqNum,
                    gasPriceL1,
                    messageDataHash
                )
            );
    }

    function addMessageToInbox(bytes32 inbox, bytes32 message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(inbox, message));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./ICloneable.sol";

contract Cloneable is ICloneable {
    string private constant NOT_CLONE = "NOT_CLONE";

    bool private isMasterCopy;

    constructor() public {
        isMasterCopy = true;
    }

    function isMaster() external view override returns (bool) {
        return isMasterCopy;
    }

    function safeSelfDestruct(address payable dest) internal {
        require(!isMasterCopy, NOT_CLONE);
        selfdestruct(dest);
    }
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

pragma solidity ^0.6.11;

abstract contract WhitelistConsumer {
    address public whitelist;

    event WhitelistSourceUpdated(address newSource);

    modifier onlyWhitelisted() {
        if (whitelist != address(0)) {
            require(Whitelist(whitelist).isAllowed(msg.sender), "NOT_WHITELISTED");
        }
        _;
    }

    function updateWhitelistSource(address newSource) external {
        require(msg.sender == whitelist, "NOT_FROM_LIST");
        whitelist = newSource;
        emit WhitelistSourceUpdated(newSource);
    }
}

contract Whitelist {
    address public owner;
    mapping(address => bool) public isAllowed;

    event OwnerUpdated(address newOwner);
    event WhitelistUpgraded(address newWhitelist, address[] targets);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setWhitelist(address[] memory user, bool[] memory val) external onlyOwner {
        require(user.length == val.length, "INVALID_INPUT");

        for (uint256 i = 0; i < user.length; i++) {
            isAllowed[user[i]] = val[i];
        }
    }

    // set new whitelist to address(0) to disable whitelist
    function triggerConsumers(address newWhitelist, address[] memory targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            WhitelistConsumer(targets[i]).updateWhitelistSource(newWhitelist);
        }
        emit WhitelistUpgraded(newWhitelist, targets);
    }
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

pragma solidity ^0.6.11;

library ProxyUtil {
    function getProxyAdmin() internal view returns (address admin) {
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/proxy/TransparentUpgradeableProxy.sol#L48
        // Storage slot with the admin of the proxy contract.
        // This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
        bytes32 slot = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        assembly {
            admin := sload(slot)
        }
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

pragma solidity ^0.6.11;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        l1Address = address(uint160(l2Address) - offset);
    }
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

pragma solidity ^0.6.11;

import "./INode.sol";
import "./IRollupCore.sol";
import "./RollupLib.sol";
import "./INodeFactory.sol";
import "./RollupEventBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

contract RollupCore is IRollupCore {
    using SafeMath for uint256;

    // Stakers become Zombies after losing a challenge
    struct Zombie {
        address stakerAddress;
        uint256 latestStakedNode;
    }

    struct Staker {
        uint256 index;
        uint256 latestStakedNode;
        uint256 amountStaked;
        // currentChallenge is 0 if staker is not in a challenge
        address currentChallenge;
        bool isStaked;
    }

    uint256 private _latestConfirmed;
    uint256 private _firstUnresolvedNode;
    uint256 private _latestNodeCreated;
    uint256 private _lastStakeBlock;
    mapping(uint256 => INode) private _nodes;
    mapping(uint256 => bytes32) private _nodeHashes;

    address payable[] private _stakerList;
    mapping(address => Staker) public override _stakerMap;

    Zombie[] private _zombies;

    mapping(address => uint256) private _withdrawableFunds;

    /**
     * @notice Get the address of the Node contract for the given node
     * @param nodeNum Index of the node
     * @return Address of the Node contract
     */
    function getNode(uint256 nodeNum) public view override returns (INode) {
        return _nodes[nodeNum];
    }

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint256 stakerNum) public view override returns (address) {
        return _stakerList[stakerNum];
    }

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) public view override returns (bool) {
        return _stakerMap[staker].isStaked;
    }

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) public view override returns (uint256) {
        return _stakerMap[staker].latestStakedNode;
    }

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) public view override returns (address) {
        return _stakerMap[staker].currentChallenge;
    }

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) public view override returns (uint256) {
        return _stakerMap[staker].amountStaked;
    }

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) public view override returns (address) {
        return _zombies[zombieNum].stakerAddress;
    }

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) public view override returns (uint256) {
        return _zombies[zombieNum].latestStakedNode;
    }

    /// @return Current number of un-removed zombies
    function zombieCount() public view override returns (uint256) {
        return _zombies.length;
    }

    function isZombie(address staker) public view override returns (bool) {
        for (uint256 i = 0; i < _zombies.length; i++) {
            if (staker == _zombies[i].stakerAddress) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param owner Address to check the funds of
     * @return Amount of funds withdrawable by owner
     */
    function withdrawableFunds(address owner) external view override returns (uint256) {
        return _withdrawableFunds[owner];
    }

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() public view override returns (uint256) {
        return _firstUnresolvedNode;
    }

    /// @return Index of the latest confirmed node
    function latestConfirmed() public view override returns (uint256) {
        return _latestConfirmed;
    }

    /// @return Index of the latest rollup node created
    function latestNodeCreated() public view override returns (uint256) {
        return _latestNodeCreated;
    }

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view override returns (uint256) {
        return _lastStakeBlock;
    }

    /// @return Number of active stakers currently staked
    function stakerCount() public view override returns (uint256) {
        return _stakerList.length;
    }

    /**
     * @notice Initialize the core with an initial node
     * @param initialNode Initial node to start the chain with
     */
    function initializeCore(INode initialNode) internal {
        _nodes[0] = initialNode;
        _firstUnresolvedNode = 1;
    }

    /**
     * @notice React to a new node being created by storing it an incrementing the latest node counter
     * @param node Node that was newly created
     * @param nodeHash The hash of said node
     */
    function nodeCreated(INode node, bytes32 nodeHash) internal {
        _latestNodeCreated++;
        _nodes[_latestNodeCreated] = node;
        _nodeHashes[_latestNodeCreated] = nodeHash;
    }

    /// @return Node hash as of this node number
    function getNodeHash(uint256 index) public view override returns (bytes32) {
        return _nodeHashes[index];
    }

    /// @notice Reject the next unresolved node
    function _rejectNextNode() internal {
        destroyNode(_firstUnresolvedNode);
        _firstUnresolvedNode++;
    }

    /// @notice Confirm the next unresolved node
    function confirmNextNode(
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount,
        IOutbox outbox,
        RollupEventBridge rollupEventBridge
    ) internal {
        confirmNode(
            _firstUnresolvedNode,
            beforeSendAcc,
            sendsData,
            sendLengths,
            afterSendCount,
            afterLogAcc,
            afterLogCount,
            outbox,
            rollupEventBridge
        );
    }

    function confirmNode(
        uint256 nodeNum,
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount,
        IOutbox outbox,
        RollupEventBridge rollupEventBridge
    ) internal {
        bytes32 afterSendAcc = RollupLib.feedAccumulator(sendsData, sendLengths, beforeSendAcc);

        INode node = getNode(nodeNum);
        // Authenticate data against node's confirm data pre-image
        require(
            node.confirmData() ==
                RollupLib.confirmHash(
                    beforeSendAcc,
                    afterSendAcc,
                    afterLogAcc,
                    afterSendCount,
                    afterLogCount
                ),
            "CONFIRM_DATA"
        );

        // trusted external call to outbox
        outbox.processOutgoingMessages(sendsData, sendLengths);

        destroyNode(_latestConfirmed);
        _latestConfirmed = nodeNum;
        _firstUnresolvedNode = nodeNum + 1;

        rollupEventBridge.nodeConfirmed(nodeNum);
        emit NodeConfirmed(nodeNum, afterSendAcc, afterSendCount, afterLogAcc, afterLogCount);
    }

    /**
     * @notice Create a new stake at latest confirmed node
     * @param stakerAddress Address of the new staker
     * @param depositAmount Stake amount of the new staker
     */
    function createNewStake(address payable stakerAddress, uint256 depositAmount) internal {
        uint256 stakerIndex = _stakerList.length;
        _stakerList.push(stakerAddress);
        _stakerMap[stakerAddress] = Staker(
            stakerIndex,
            _latestConfirmed,
            depositAmount,
            address(0), // new staker is not in challenge
            true
        );
        _lastStakeBlock = block.number;
        emit UserStakeUpdated(stakerAddress, 0, depositAmount);
    }

    /**
     * @notice Check to see whether the two stakers are in the same challenge
     * @param stakerAddress1 Address of the first staker
     * @param stakerAddress2 Address of the second staker
     * @return Address of the challenge that the two stakers are in
     */
    function inChallenge(address stakerAddress1, address stakerAddress2)
        internal
        view
        returns (address)
    {
        Staker storage staker1 = _stakerMap[stakerAddress1];
        Staker storage staker2 = _stakerMap[stakerAddress2];
        address challenge = staker1.currentChallenge;
        require(challenge != address(0), "NO_CHAL");
        require(challenge == staker2.currentChallenge, "DIFF_IN_CHAL");
        return challenge;
    }

    /**
     * @notice Make the given staker as not being in a challenge
     * @param stakerAddress Address of the staker to remove from a challenge
     */
    function clearChallenge(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        staker.currentChallenge = address(0);
    }

    /**
     * @notice Mark both the given stakers as engaged in the challenge
     * @param staker1 Address of the first staker
     * @param staker2 Address of the second staker
     * @param challenge Address of the challenge both stakers are now in
     */
    function challengeStarted(
        address staker1,
        address staker2,
        address challenge
    ) internal {
        _stakerMap[staker1].currentChallenge = challenge;
        _stakerMap[staker2].currentChallenge = challenge;
    }

    /**
     * @notice Add to the stake of the given staker by the given amount
     * @param stakerAddress Address of the staker to increase the stake of
     * @param amountAdded Amount of stake to add to the staker
     */
    function increaseStakeBy(address stakerAddress, uint256 amountAdded) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 initialStaked = staker.amountStaked;
        uint256 finalStaked = initialStaked.add(amountAdded);
        staker.amountStaked = finalStaked;
        emit UserStakeUpdated(stakerAddress, initialStaked, finalStaked);
    }

    /**
     * @notice Reduce the stake of the given staker to the given target
     * @param stakerAddress Address of the staker to reduce the stake of
     * @param target Amount of stake to leave with the staker
     * @return Amount of value released from the stake
     */
    function reduceStakeTo(address stakerAddress, uint256 target) internal returns (uint256) {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 current = staker.amountStaked;
        require(target <= current, "TOO_LITTLE_STAKE");
        uint256 amountWithdrawn = current.sub(target);
        staker.amountStaked = target;
        increaseWithdrawableFunds(stakerAddress, amountWithdrawn);
        emit UserStakeUpdated(stakerAddress, current, target);
        return amountWithdrawn;
    }

    /**
     * @notice Remove the given staker and turn them into a zombie
     * @param stakerAddress Address of the staker to remove
     */
    function turnIntoZombie(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        _zombies.push(Zombie(stakerAddress, staker.latestStakedNode));
        deleteStaker(stakerAddress);
    }

    /**
     * @notice Update the latest staked node of the zombie at the given index
     * @param zombieNum Index of the zombie to move
     * @param latest New latest node the zombie is staked on
     */
    function zombieUpdateLatestStakedNode(uint256 zombieNum, uint256 latest) internal {
        _zombies[zombieNum].latestStakedNode = latest;
    }

    /**
     * @notice Remove the zombie at the given index
     * @param zombieNum Index of the zombie to remove
     */
    function removeZombie(uint256 zombieNum) internal {
        _zombies[zombieNum] = _zombies[_zombies.length - 1];
        _zombies.pop();
    }

    /**
     * @notice Remove the given staker and return their stake
     * @param stakerAddress Address of the staker withdrawing their stake
     */
    function withdrawStaker(address stakerAddress) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 initialStaked = staker.amountStaked;
        increaseWithdrawableFunds(stakerAddress, initialStaked);
        deleteStaker(stakerAddress);
        emit UserStakeUpdated(stakerAddress, initialStaked, 0);
    }

    /**
     * @notice Advance the given staker to the given node
     * @param stakerAddress Address of the staker adding their stake
     * @param nodeNum Index of the node to stake on
     */
    function stakeOnNode(
        address stakerAddress,
        uint256 nodeNum,
        uint256 confirmPeriodBlocks
    ) internal {
        Staker storage staker = _stakerMap[stakerAddress];
        INode node = _nodes[nodeNum];
        uint256 newStakerCount = node.addStaker(stakerAddress);
        staker.latestStakedNode = nodeNum;
        if (newStakerCount == 1) {
            INode parent = _nodes[node.prev()];
            parent.newChildConfirmDeadline(block.number.add(confirmPeriodBlocks));
        }
    }

    /**
     * @notice Clear the withdrawable funds for the given address
     * @param owner Address of the account to remove funds from
     * @return Amount of funds removed from account
     */
    function withdrawFunds(address owner) internal returns (uint256) {
        uint256 amount = _withdrawableFunds[owner];
        _withdrawableFunds[owner] = 0;
        emit UserWithdrawableFundsUpdated(owner, amount, 0);
        return amount;
    }

    /**
     * @notice Increase the withdrawable funds for the given address
     * @param owner Address of the account to add withdrawable funds to
     */
    function increaseWithdrawableFunds(address owner, uint256 amount) internal {
        uint256 initialWithdrawable = _withdrawableFunds[owner];
        uint256 finalWithdrawable = initialWithdrawable.add(amount);
        _withdrawableFunds[owner] = finalWithdrawable;
        emit UserWithdrawableFundsUpdated(owner, initialWithdrawable, finalWithdrawable);
    }

    /**
     * @notice Remove the given staker
     * @param stakerAddress Address of the staker to remove
     */
    function deleteStaker(address stakerAddress) private {
        Staker storage staker = _stakerMap[stakerAddress];
        uint256 stakerIndex = staker.index;
        _stakerList[stakerIndex] = _stakerList[_stakerList.length - 1];
        _stakerMap[_stakerList[stakerIndex]].index = stakerIndex;
        _stakerList.pop();
        delete _stakerMap[stakerAddress];
    }

    /**
     * @notice Destroy the given node and clear out its address
     * @param nodeNum Index of the node to remove
     */
    function destroyNode(uint256 nodeNum) internal {
        _nodes[nodeNum].destroy();
        _nodes[nodeNum] = INode(0);
    }

    function nodeDeadline(
        uint256 avmGasSpeedLimitPerBlock,
        uint256 gasUsed,
        uint256 confirmPeriodBlocks,
        INode prevNode
    ) internal view returns (uint256 deadlineBlock) {
        // Set deadline rounding up to the nearest block
        uint256 checkTime = gasUsed.add(avmGasSpeedLimitPerBlock.sub(1)).div(
            avmGasSpeedLimitPerBlock
        );

        deadlineBlock = max(block.number.add(confirmPeriodBlocks), prevNode.deadlineBlock()).add(
            checkTime
        );

        uint256 olderSibling = prevNode.latestChildNumber();
        if (olderSibling != 0) {
            deadlineBlock = max(deadlineBlock, getNode(olderSibling).deadlineBlock());
        }
        return deadlineBlock;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    struct StakeOnNewNodeFrame {
        uint256 currentInboxSize;
        INode node;
        bytes32 executionHash;
        INode prevNode;
        bytes32 lastHash;
        bool hasSibling;
        uint256 deadlineBlock;
        uint256 gasUsed;
        uint256 sequencerBatchEnd;
        bytes32 sequencerBatchAcc;
    }

    struct CreateNodeDataFrame {
        uint256 prevNode;
        uint256 confirmPeriodBlocks;
        uint256 avmGasSpeedLimitPerBlock;
        ISequencerInbox sequencerInbox;
        RollupEventBridge rollupEventBridge;
        INodeFactory nodeFactory;
    }

    uint8 internal constant MAX_SEND_COUNT = 100;

    function createNewNode(
        RollupLib.Assertion memory assertion,
        bytes32[3][2] calldata assertionBytes32Fields,
        uint256[4][2] calldata assertionIntFields,
        bytes calldata sequencerBatchProof,
        CreateNodeDataFrame memory inputDataFrame,
        bytes32 expectedNodeHash
    ) internal returns (bytes32 newNodeHash) {
        StakeOnNewNodeFrame memory memoryFrame;
        {
            // validate data
            memoryFrame.gasUsed = RollupLib.assertionGasUsed(assertion);
            memoryFrame.prevNode = getNode(inputDataFrame.prevNode);
            memoryFrame.currentInboxSize = inputDataFrame.sequencerInbox.messageCount();

            // Make sure the previous state is correct against the node being built on
            require(
                RollupLib.stateHash(assertion.beforeState) == memoryFrame.prevNode.stateHash(),
                "PREV_STATE_HASH"
            );

            // Ensure that the assertion doesn't read past the end of the current inbox
            require(
                assertion.afterState.inboxCount <= memoryFrame.currentInboxSize,
                "INBOX_PAST_END"
            );
            // Insure inbox tip after assertion is included in a sequencer-inbox batch and return inbox acc; this gives replay protection against the state of the inbox
            (memoryFrame.sequencerBatchEnd, memoryFrame.sequencerBatchAcc) = inputDataFrame
                .sequencerInbox
                .proveInboxContainsMessage(sequencerBatchProof, assertion.afterState.inboxCount);
        }

        {
            memoryFrame.executionHash = RollupLib.executionHash(assertion);

            memoryFrame.deadlineBlock = nodeDeadline(
                inputDataFrame.avmGasSpeedLimitPerBlock,
                memoryFrame.gasUsed,
                inputDataFrame.confirmPeriodBlocks,
                memoryFrame.prevNode
            );

            memoryFrame.hasSibling = memoryFrame.prevNode.latestChildNumber() > 0;
            // here we don't use ternacy operator to remain compatible with slither
            if (memoryFrame.hasSibling) {
                memoryFrame.lastHash = getNodeHash(memoryFrame.prevNode.latestChildNumber());
            } else {
                memoryFrame.lastHash = getNodeHash(inputDataFrame.prevNode);
            }

            memoryFrame.node = INode(
                inputDataFrame.nodeFactory.createNode(
                    RollupLib.stateHash(assertion.afterState),
                    RollupLib.challengeRoot(assertion, memoryFrame.executionHash, block.number),
                    RollupLib.confirmHash(assertion),
                    inputDataFrame.prevNode,
                    memoryFrame.deadlineBlock
                )
            );
        }

        {
            uint256 nodeNum = latestNodeCreated() + 1;
            memoryFrame.prevNode.childCreated(nodeNum);

            newNodeHash = RollupLib.nodeHash(
                memoryFrame.hasSibling,
                memoryFrame.lastHash,
                memoryFrame.executionHash,
                memoryFrame.sequencerBatchAcc
            );
            require(newNodeHash == expectedNodeHash, "UNEXPECTED_NODE_HASH");

            nodeCreated(memoryFrame.node, newNodeHash);
            inputDataFrame.rollupEventBridge.nodeCreated(
                nodeNum,
                inputDataFrame.prevNode,
                memoryFrame.deadlineBlock,
                msg.sender
            );
        }

        emit NodeCreated(
            latestNodeCreated(),
            getNodeHash(inputDataFrame.prevNode),
            newNodeHash,
            memoryFrame.executionHash,
            memoryFrame.currentInboxSize,
            memoryFrame.sequencerBatchEnd,
            memoryFrame.sequencerBatchAcc,
            assertionBytes32Fields,
            assertionIntFields
        );

        return newNodeHash;
    }
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface INode {
    function initialize(
        address _rollup,
        bytes32 _stateHash,
        bytes32 _challengeHash,
        bytes32 _confirmData,
        uint256 _prev,
        uint256 _deadlineBlock
    ) external;

    function destroy() external;

    function addStaker(address staker) external returns (uint256);

    function removeStaker(address staker) external;

    function childCreated(uint256) external;

    function newChildConfirmDeadline(uint256 deadline) external;

    function stateHash() external view returns (bytes32);

    function challengeHash() external view returns (bytes32);

    function confirmData() external view returns (bytes32);

    function prev() external view returns (uint256);

    function deadlineBlock() external view returns (uint256);

    function noChildConfirmedBeforeBlock() external view returns (uint256);

    function stakerCount() external view returns (uint256);

    function stakers(address staker) external view returns (bool);

    function firstChildBlock() external view returns (uint256);

    function latestChildNumber() external view returns (uint256);

    function requirePastDeadline() external view;

    function requirePastChildConfirmDeadline() external view;
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface INodeFactory {
    function createNode(
        bytes32 _stateHash,
        bytes32 _challengeHash,
        bytes32 _confirmData,
        uint256 _prev,
        uint256 _deadlineBlock
    ) external returns (address);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";
import "../arch/IOneStepProof.sol";

interface IChallenge {
    function initializeChallenge(
        IOneStepProof[] calldata _executors,
        address _resultReceiver,
        bytes32 _executionHash,
        uint256 _maxMessageCount,
        address _asserter,
        address _challenger,
        uint256 _asserterTimeLeft,
        uint256 _challengerTimeLeft,
        ISequencerInbox _sequencerBridge,
        IBridge _delayedBridge
    ) external;

    function currentResponderTimeLeft() external view returns (uint256);

    function lastMoveBlock() external view returns (uint256);

    function timeout() external;

    function asserter() external view returns (address);

    function challenger() external view returns (address);

    function clearChallenge() external;
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

interface IChallengeFactory {
    function createChallenge(
        address _resultReceiver,
        bytes32 _executionHash,
        uint256 _maxMessageCount,
        address _asserter,
        address _challenger,
        uint256 _asserterTimeLeft,
        uint256 _challengerTimeLeft,
        ISequencerInbox _sequencerBridge,
        IBridge _delayedBridge
    ) external returns (address);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxEntryIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxEntryIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function l2ToL1BatchNum() external view returns (uint256);

    function l2ToL1OutputId() external view returns (bytes32);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external;

    function outboxEntryExists(uint256 batchNum) external view returns (bool);

    function setBridge(IBridge newBridge) external;

    function isNitroReady() external pure returns (uint256);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "../INode.sol";
import "../../bridge/interfaces/IOutbox.sol";

interface IRollupUser {
    function initialize(address _stakeToken) external;

    function completeChallenge(address winningStaker, address losingStaker) external;

    function returnOldDeposit(address stakerAddress) external;

    function requireUnresolved(uint256 nodeNum) external view;

    function requireUnresolvedExists() external view;

    function countStakedZombies(INode node) external view returns (uint256);
}

interface IRollupAdmin {
    event OwnerFunctionCalled(uint256 indexed id);

    /**
     * @notice Add a contract authorized to put messages into this rollup's inbox
     * @param _outbox Outbox contract to add
     */
    function setOutbox(IOutbox _outbox) external;

    /**
     * @notice Disable an old outbox from interacting with the bridge
     * @param _outbox Outbox contract to remove
     */
    function removeOldOutbox(address _outbox) external;

    /**
     * @notice Enable or disable an inbox contract
     * @param _inbox Inbox contract to add or remove
     * @param _enabled New status of inbox
     */
    function setInbox(address _inbox, bool _enabled) external;

    /**
     * @notice Pause interaction with the rollup contract
     */
    function pause() external;

    /**
     * @notice Resume interaction with the rollup contract
     */
    function resume() external;

    /**
     * @notice Set the addresses of rollup logic facets called
     * @param newAdminFacet address of logic that owner of rollup calls
     * @param newUserFacet ddress of logic that user of rollup calls
     */
    function setFacets(address newAdminFacet, address newUserFacet) external;

    /**
     * @notice Set the addresses of the validator whitelist
     * @dev It is expected that both arrays are same length, and validator at
     * position i corresponds to the value at position i
     * @param _validator addresses to set in the whitelist
     * @param _val value to set in the whitelist for corresponding address
     */
    function setValidator(address[] memory _validator, bool[] memory _val) external;

    /**
     * @notice Set a new owner address for the rollup
     * @param newOwner address of new rollup owner
     */
    function setOwner(address newOwner) external;

    /**
     * @notice Set minimum assertion period for the rollup
     * @param newPeriod new minimum period for assertions
     */
    function setMinimumAssertionPeriod(uint256 newPeriod) external;

    /**
     * @notice Set number of blocks until a node is considered confirmed
     * @param newConfirmPeriod new number of blocks until a node is confirmed
     */
    function setConfirmPeriodBlocks(uint256 newConfirmPeriod) external;

    /**
     * @notice Set number of extra blocks after a challenge
     * @param newExtraTimeBlocks new number of blocks
     */
    function setExtraChallengeTimeBlocks(uint256 newExtraTimeBlocks) external;

    /**
     * @notice Set speed limit per block
     * @param newAvmGasSpeedLimitPerBlock maximum avmgas to be used per block
     */
    function setAvmGasSpeedLimitPerBlock(uint256 newAvmGasSpeedLimitPerBlock) external;

    /**
     * @notice Set base stake required for an assertion
     * @param newBaseStake maximum avmgas to be used per block
     */
    function setBaseStake(uint256 newBaseStake) external;

    /**
     * @notice Set the token used for stake, where address(0) == eth
     * @dev Before changing the base stake token, you might need to change the
     * implementation of the Rollup User facet!
     * @param newStakeToken address of token used for staking
     */
    function setStakeToken(address newStakeToken) external;

    /**
     * @notice Set max delay for sequencer inbox
     * @param newSequencerInboxMaxDelayBlocks max number of blocks
     * @param newSequencerInboxMaxDelaySeconds max number of seconds
     */
    function setSequencerInboxMaxDelay(
        uint256 newSequencerInboxMaxDelayBlocks,
        uint256 newSequencerInboxMaxDelaySeconds
    ) external;

    /**
     * @notice Set execution bisection degree
     * @param newChallengeExecutionBisectionDegree execution bisection degree
     */
    function setChallengeExecutionBisectionDegree(uint256 newChallengeExecutionBisectionDegree)
        external;

    /**
     * @notice Updates a whitelist address for its consumers
     * @dev setting the newWhitelist to address(0) disables it for consumers
     * @param whitelist old whitelist to be deprecated
     * @param newWhitelist new whitelist to be used
     * @param targets whitelist consumers to be triggered
     */
    function updateWhitelistConsumers(
        address whitelist,
        address newWhitelist,
        address[] memory targets
    ) external;

    /**
     * @notice Updates a whitelist's entries
     * @dev user at position i will be assigned value i
     * @param whitelist whitelist to be updated
     * @param user users to be updated in the whitelist
     * @param val if user is or not allowed in the whitelist
     */
    function setWhitelistEntries(
        address whitelist,
        address[] memory user,
        bool[] memory val
    ) external;

    /**
     * @notice Updates whether an address is a sequencer at the sequencer inbox
     * @param newSequencer address to be modified
     * @param isSequencer whether this address should be authorized as a sequencer
     */
    function setIsSequencer(address newSequencer, bool isSequencer) external;

    /**
     * @notice Upgrades the implementation of a beacon controlled by the rollup
     * @param beacon address of beacon to be upgraded
     * @param newImplementation new address of implementation
     */
    function upgradeBeacon(address beacon, address newImplementation) external;

    function forceResolveChallenge(address[] memory stackerA, address[] memory stackerB) external;

    function forceRefundStaker(address[] memory stacker) external;

    function forceCreateNode(
        bytes32 expectedNodeHash,
        bytes32[3][2] calldata assertionBytes32Fields,
        uint256[4][2] calldata assertionIntFields,
        bytes calldata sequencerBatchProof,
        uint256 beforeProposedBlock,
        uint256 beforeInboxMaxCount,
        uint256 prevNode
    ) external;

    function forceConfirmNode(
        uint256 nodeNum,
        bytes32 beforeSendAcc,
        bytes calldata sendsData,
        uint256[] calldata sendLengths,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount
    ) external;
}

interface INitroRollupCore {
    function inbox() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./INode.sol";

interface IRollupCore {
    function _stakerMap(address stakerAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool
        );

    event RollupCreated(bytes32 machineHash);

    event NodeCreated(
        uint256 indexed nodeNum,
        bytes32 indexed parentNodeHash,
        bytes32 nodeHash,
        bytes32 executionHash,
        uint256 inboxMaxCount,
        uint256 afterInboxBatchEndCount,
        bytes32 afterInboxBatchAcc,
        bytes32[3][2] assertionBytes32Fields,
        uint256[4][2] assertionIntFields
    );

    event NodeConfirmed(
        uint256 indexed nodeNum,
        bytes32 afterSendAcc,
        uint256 afterSendCount,
        bytes32 afterLogAcc,
        uint256 afterLogCount
    );

    event NodeRejected(uint256 indexed nodeNum);

    event RollupChallengeStarted(
        address indexed challengeContract,
        address asserter,
        address challenger,
        uint256 challengedNode
    );

    event UserStakeUpdated(address indexed user, uint256 initialBalance, uint256 finalBalance);

    event UserWithdrawableFundsUpdated(
        address indexed user,
        uint256 initialBalance,
        uint256 finalBalance
    );

    function getNode(uint256 nodeNum) external view returns (INode);

    /**
     * @notice Get the address of the staker at the given index
     * @param stakerNum Index of the staker
     * @return Address of the staker
     */
    function getStakerAddress(uint256 stakerNum) external view returns (address);

    /**
     * @notice Check whether the given staker is staked
     * @param staker Staker address to check
     * @return True or False for whether the staker was staked
     */
    function isStaked(address staker) external view returns (bool);

    /**
     * @notice Get the latest staked node of the given staker
     * @param staker Staker address to lookup
     * @return Latest node staked of the staker
     */
    function latestStakedNode(address staker) external view returns (uint256);

    /**
     * @notice Get the current challenge of the given staker
     * @param staker Staker address to lookup
     * @return Current challenge of the staker
     */
    function currentChallenge(address staker) external view returns (address);

    /**
     * @notice Get the amount staked of the given staker
     * @param staker Staker address to lookup
     * @return Amount staked of the staker
     */
    function amountStaked(address staker) external view returns (uint256);

    /**
     * @notice Get the original staker address of the zombie at the given index
     * @param zombieNum Index of the zombie to lookup
     * @return Original staker address of the zombie
     */
    function zombieAddress(uint256 zombieNum) external view returns (address);

    /**
     * @notice Get Latest node that the given zombie at the given index is staked on
     * @param zombieNum Index of the zombie to lookup
     * @return Latest node that the given zombie is staked on
     */
    function zombieLatestStakedNode(uint256 zombieNum) external view returns (uint256);

    /// @return Current number of un-removed zombies
    function zombieCount() external view returns (uint256);

    function isZombie(address staker) external view returns (bool);

    /**
     * @notice Get the amount of funds withdrawable by the given address
     * @param owner Address to check the funds of
     * @return Amount of funds withdrawable by owner
     */
    function withdrawableFunds(address owner) external view returns (uint256);

    /**
     * @return Index of the first unresolved node
     * @dev If all nodes have been resolved, this will be latestNodeCreated + 1
     */
    function firstUnresolvedNode() external view returns (uint256);

    /// @return Index of the latest confirmed node
    function latestConfirmed() external view returns (uint256);

    /// @return Index of the latest rollup node created
    function latestNodeCreated() external view returns (uint256);

    /// @return Ethereum block that the most recent stake was created
    function lastStakeBlock() external view returns (uint256);

    /// @return Number of active stakers currently staked
    function stakerCount() external view returns (uint256);

    /// @return Node hash as of this node number
    function getNodeHash(uint256 index) external view returns (bytes32);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface ISequencerInbox {
    event SequencerBatchDelivered(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        bytes32 afterAcc,
        bytes transactions,
        uint256[] lengths,
        uint256[] sectionsMetadata,
        uint256 seqBatchIndex,
        address sequencer
    );

    event SequencerBatchDeliveredFromOrigin(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        bytes32 afterAcc,
        uint256 seqBatchIndex
    );

    event DelayedInboxForced(
        uint256 indexed firstMessageNum,
        bytes32 indexed beforeAcc,
        uint256 newMessageCount,
        uint256 totalDelayedMessagesRead,
        bytes32[2] afterAccAndDelayed,
        uint256 seqBatchIndex
    );

    /// @notice DEPRECATED - look at IsSequencerUpdated for new updates
    // event SequencerAddressUpdated(address newAddress);

    event IsSequencerUpdated(address addr, bool isSequencer);
    event MaxDelayUpdated(uint256 newMaxDelayBlocks, uint256 newMaxDelaySeconds);

    /// @notice DEPRECATED - look at MaxDelayUpdated for new updates
    // event MaxDelayBlocksUpdated(uint256 newValue);
    /// @notice DEPRECATED - look at MaxDelayUpdated for new updates
    // event MaxDelaySecondsUpdated(uint256 newValue);

    function setMaxDelay(uint256 newMaxDelayBlocks, uint256 newMaxDelaySeconds) external;

    function setIsSequencer(address addr, bool isSequencer) external;

    function messageCount() external view returns (uint256);

    function maxDelayBlocks() external view returns (uint256);

    function maxDelaySeconds() external view returns (uint256);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function getInboxAccsLength() external view returns (uint256);

    function proveInboxContainsMessage(bytes calldata proof, uint256 inboxCount)
        external
        view
        returns (uint256, bytes32);

    /// @notice DEPRECATED - use isSequencer instead
    function sequencer() external view returns (address);

    function isSequencer(address seq) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

pragma solidity ^0.6.11;

import "../libraries/MerkleLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library ChallengeLib {
    using SafeMath for uint256;

    function firstSegmentSize(uint256 totalCount, uint256 bisectionCount)
        internal
        pure
        returns (uint256)
    {
        return totalCount / bisectionCount + (totalCount % bisectionCount);
    }

    function otherSegmentSize(uint256 totalCount, uint256 bisectionCount)
        internal
        pure
        returns (uint256)
    {
        return totalCount / bisectionCount;
    }

    function bisectionChunkHash(
        uint256 _segmentStart,
        uint256 _segmentLength,
        bytes32 _startHash,
        bytes32 _endHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_segmentStart, _segmentLength, _startHash, _endHash));
    }

    function assertionHash(uint256 _avmGasUsed, bytes32 _restHash) internal pure returns (bytes32) {
        // Note: make sure this doesn't return Challenge.UNREACHABLE_ASSERTION (currently 0)
        return keccak256(abi.encodePacked(_avmGasUsed, _restHash));
    }

    function assertionRestHash(
        uint256 _totalMessagesRead,
        bytes32 _machineState,
        bytes32 _sendAcc,
        uint256 _sendCount,
        bytes32 _logAcc,
        uint256 _logCount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _totalMessagesRead,
                    _machineState,
                    _sendAcc,
                    _sendCount,
                    _logAcc,
                    _logCount
                )
            );
    }

    function updatedBisectionRoot(
        bytes32[] memory _chainHashes,
        uint256 _challengedSegmentStart,
        uint256 _challengedSegmentLength
    ) internal pure returns (bytes32) {
        uint256 bisectionCount = _chainHashes.length - 1;
        bytes32[] memory hashes = new bytes32[](bisectionCount);
        uint256 chunkSize = ChallengeLib.firstSegmentSize(_challengedSegmentLength, bisectionCount);
        uint256 segmentStart = _challengedSegmentStart;
        hashes[0] = ChallengeLib.bisectionChunkHash(
            segmentStart,
            chunkSize,
            _chainHashes[0],
            _chainHashes[1]
        );
        segmentStart = segmentStart.add(chunkSize);
        chunkSize = ChallengeLib.otherSegmentSize(_challengedSegmentLength, bisectionCount);
        for (uint256 i = 1; i < bisectionCount; i++) {
            hashes[i] = ChallengeLib.bisectionChunkHash(
                segmentStart,
                chunkSize,
                _chainHashes[i],
                _chainHashes[i + 1]
            );
            segmentStart = segmentStart.add(chunkSize);
        }
        return MerkleLib.generateRoot(hashes);
    }

    function verifySegmentProof(
        bytes32 challengeState,
        bytes32 item,
        bytes32[] calldata _merkleNodes,
        uint256 _merkleRoute
    ) internal pure returns (bool) {
        return challengeState == MerkleLib.calculateRoot(_merkleNodes, _merkleRoute, item);
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

pragma solidity ^0.6.11;

library MerkleLib {
    function generateRoot(bytes32[] memory _hashes) internal pure returns (bytes32) {
        bytes32[] memory prevLayer = _hashes;
        while (prevLayer.length > 1) {
            bytes32[] memory nextLayer = new bytes32[]((prevLayer.length + 1) / 2);
            for (uint256 i = 0; i < nextLayer.length; i++) {
                if (2 * i + 1 < prevLayer.length) {
                    nextLayer[i] = keccak256(
                        abi.encodePacked(prevLayer[2 * i], prevLayer[2 * i + 1])
                    );
                } else {
                    nextLayer[i] = prevLayer[2 * i];
                }
            }
            prevLayer = nextLayer;
        }
        return prevLayer[0];
    }

    function calculateRoot(
        bytes32[] memory nodes,
        uint256 route,
        bytes32 item
    ) internal pure returns (bytes32) {
        uint256 proofItems = nodes.length;
        require(proofItems <= 256);
        bytes32 h = item;
        for (uint256 i = 0; i < proofItems; i++) {
            if (route % 2 == 0) {
                h = keccak256(abi.encodePacked(nodes[i], h));
            } else {
                h = keccak256(abi.encodePacked(h, nodes[i]));
            }
            route /= 2;
        }
        return h;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019, Offchain Labs, Inc.
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface ICloneable {
    function isMaster() external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "../bridge/interfaces/IBridge.sol";
import "../bridge/interfaces/ISequencerInbox.sol";

interface IOneStepProof {
    // Bridges is sequencer bridge then delayed bridge
    function executeStep(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    )
        external
        view
        returns (
            uint64 gas,
            uint256 afterMessagesRead,
            bytes32[4] memory fields
        );

    function executeStepDebug(
        address[2] calldata bridges,
        uint256 initialMessagesRead,
        bytes32[2] calldata accs,
        bytes calldata proof,
        bytes calldata bproof
    ) external view returns (string memory startMachine, string memory afterMachine);
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.6.11;

/* solhint-disable no-inline-assembly */
library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= (_start + 20), "Read out of bounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= (_start + 1), "Read out of bounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }
}
/* solhint-enable no-inline-assembly */

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";
import "./IBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 private constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) public payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _setBeacon(beacon, data);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address beacon) {
        bytes32 slot = _BEACON_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            beacon := sload(slot)
        }
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_beacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        require(
            Address.isContract(beacon),
            "BeaconProxy: beacon is not a contract"
        );
        require(
            Address.isContract(IBeacon(beacon).implementation()),
            "BeaconProxy: beacon implementation is not a contract"
        );
        bytes32 slot = _BEACON_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, beacon)
        }

        if (data.length > 0) {
            Address.functionDelegateCall(_implementation(), data, "BeaconProxy: function call failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IBeacon.sol";
import "../access/Ownable.sol";
import "../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) public {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.6.11;

import "./Value.sol";
import "./Hashing.sol";

import "../libraries/BytesLib.sol";

library Marshaling {
    using BytesLib for bytes;
    using Value for Value.Data;

    function deserializeHashPreImage(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (uint256 offset, Value.Data memory value)
    {
        require(data.length >= startOffset && data.length - startOffset >= 64, "too short");
        bytes32 hashData;
        uint256 size;
        (offset, hashData) = extractBytes32(data, startOffset);
        (offset, size) = deserializeInt(data, offset);
        return (offset, Value.newTuplePreImage(hashData, size));
    }

    function deserializeInt(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            uint256 // val
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, data.toUint(startOffset));
    }

    function deserializeBytes32(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            bytes32 // val
        )
    {
        require(data.length >= startOffset && data.length - startOffset >= 32, "too short");
        return (startOffset + 32, data.toBytes32(startOffset));
    }

    function deserializeCodePoint(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            Value.Data memory // val
        )
    {
        uint256 offset = startOffset;
        uint8 immediateType;
        uint8 opCode;
        Value.Data memory immediate;
        bytes32 nextHash;

        (offset, immediateType) = extractUint8(data, offset);
        (offset, opCode) = extractUint8(data, offset);
        if (immediateType == 1) {
            (offset, immediate) = deserialize(data, offset);
        }
        (offset, nextHash) = extractBytes32(data, offset);
        if (immediateType == 1) {
            return (offset, Value.newCodePoint(opCode, nextHash, immediate));
        }
        return (offset, Value.newCodePoint(opCode, nextHash));
    }

    function deserializeTuple(
        uint8 memberCount,
        bytes memory data,
        uint256 startOffset
    )
        internal
        pure
        returns (
            uint256, // offset
            Value.Data[] memory // val
        )
    {
        uint256 offset = startOffset;
        Value.Data[] memory members = new Value.Data[](memberCount);
        for (uint8 i = 0; i < memberCount; i++) {
            (offset, members[i]) = deserialize(data, offset);
        }
        return (offset, members);
    }

    function deserialize(bytes memory data, uint256 startOffset)
        internal
        pure
        returns (
            uint256, // offset
            Value.Data memory // val
        )
    {
        require(startOffset < data.length, "invalid offset");
        (uint256 offset, uint8 valType) = extractUint8(data, startOffset);
        if (valType == Value.intTypeCode()) {
            uint256 intVal;
            (offset, intVal) = deserializeInt(data, offset);
            return (offset, Value.newInt(intVal));
        } else if (valType == Value.codePointTypeCode()) {
            return deserializeCodePoint(data, offset);
        } else if (valType == Value.bufferTypeCode()) {
            bytes32 hashVal;
            (offset, hashVal) = deserializeBytes32(data, offset);
            return (offset, Value.newBuffer(hashVal));
        } else if (valType == Value.tuplePreImageTypeCode()) {
            return deserializeHashPreImage(data, offset);
        } else if (valType >= Value.tupleTypeCode() && valType < Value.valueTypeCode()) {
            uint8 tupLength = uint8(valType - Value.tupleTypeCode());
            Value.Data[] memory tupleVal;
            (offset, tupleVal) = deserializeTuple(tupLength, data, offset);
            return (offset, Value.newTuple(tupleVal));
        }
        require(false, "invalid typecode");
    }

    function extractUint8(bytes memory data, uint256 startOffset)
        private
        pure
        returns (
            uint256, // offset
            uint8 // val
        )
    {
        return (startOffset + 1, uint8(data[startOffset]));
    }

    function extractBytes32(bytes memory data, uint256 startOffset)
        private
        pure
        returns (
            uint256, // offset
            bytes32 // val
        )
    {
        return (startOffset + 32, data.toBytes32(startOffset));
    }
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
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

pragma solidity ^0.6.11;

library Value {
    uint8 internal constant INT_TYPECODE = 0;
    uint8 internal constant CODE_POINT_TYPECODE = 1;
    uint8 internal constant HASH_PRE_IMAGE_TYPECODE = 2;
    uint8 internal constant TUPLE_TYPECODE = 3;
    uint8 internal constant BUFFER_TYPECODE = TUPLE_TYPECODE + 9;
    // All values received from clients will have type codes less than the VALUE_TYPE_COUNT
    uint8 internal constant VALUE_TYPE_COUNT = TUPLE_TYPECODE + 10;

    // The following types do not show up in the marshalled format and is
    // only used for internal tracking purposes
    uint8 internal constant HASH_ONLY = 100;

    struct CodePoint {
        uint8 opcode;
        bytes32 nextCodePoint;
        Data[] immediate;
    }

    struct Data {
        uint256 intVal;
        CodePoint cpVal;
        Data[] tupleVal;
        bytes32 bufferHash;
        uint8 typeCode;
        uint256 size;
    }

    function tupleTypeCode() internal pure returns (uint8) {
        return TUPLE_TYPECODE;
    }

    function tuplePreImageTypeCode() internal pure returns (uint8) {
        return HASH_PRE_IMAGE_TYPECODE;
    }

    function intTypeCode() internal pure returns (uint8) {
        return INT_TYPECODE;
    }

    function bufferTypeCode() internal pure returns (uint8) {
        return BUFFER_TYPECODE;
    }

    function codePointTypeCode() internal pure returns (uint8) {
        return CODE_POINT_TYPECODE;
    }

    function valueTypeCode() internal pure returns (uint8) {
        return VALUE_TYPE_COUNT;
    }

    function hashOnlyTypeCode() internal pure returns (uint8) {
        return HASH_ONLY;
    }

    function isValidTupleSize(uint256 size) internal pure returns (bool) {
        return size <= 8;
    }

    function typeCodeVal(Data memory val) internal pure returns (Data memory) {
        if (val.typeCode == 2) {
            // Map HashPreImage to Tuple
            return newInt(TUPLE_TYPECODE);
        }
        return newInt(val.typeCode);
    }

    function valLength(Data memory val) internal pure returns (uint8) {
        if (val.typeCode == TUPLE_TYPECODE) {
            return uint8(val.tupleVal.length);
        } else {
            return 1;
        }
    }

    function isInt(Data memory val) internal pure returns (bool) {
        return val.typeCode == INT_TYPECODE;
    }

    function isInt64(Data memory val) internal pure returns (bool) {
        return val.typeCode == INT_TYPECODE && val.intVal < (1 << 64);
    }

    function isCodePoint(Data memory val) internal pure returns (bool) {
        return val.typeCode == CODE_POINT_TYPECODE;
    }

    function isTuple(Data memory val) internal pure returns (bool) {
        return val.typeCode == TUPLE_TYPECODE;
    }

    function isBuffer(Data memory val) internal pure returns (bool) {
        return val.typeCode == BUFFER_TYPECODE;
    }

    function newEmptyTuple() internal pure returns (Data memory) {
        return newTuple(new Data[](0));
    }

    function newBoolean(bool val) internal pure returns (Data memory) {
        if (val) {
            return newInt(1);
        } else {
            return newInt(0);
        }
    }

    function newInt(uint256 _val) internal pure returns (Data memory) {
        return
            Data(_val, CodePoint(0, 0, new Data[](0)), new Data[](0), 0, INT_TYPECODE, uint256(1));
    }

    function newHashedValue(bytes32 valueHash, uint256 valueSize)
        internal
        pure
        returns (Data memory)
    {
        return
            Data(
                uint256(valueHash),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                0,
                HASH_ONLY,
                valueSize
            );
    }

    function newTuple(Data[] memory _val) internal pure returns (Data memory) {
        require(isValidTupleSize(_val.length), "Tuple must have valid size");
        uint256 size = 1;

        for (uint256 i = 0; i < _val.length; i++) {
            size += _val[i].size;
        }

        return Data(0, CodePoint(0, 0, new Data[](0)), _val, 0, TUPLE_TYPECODE, size);
    }

    function newTuplePreImage(bytes32 preImageHash, uint256 size)
        internal
        pure
        returns (Data memory)
    {
        return
            Data(
                uint256(preImageHash),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                0,
                HASH_PRE_IMAGE_TYPECODE,
                size
            );
    }

    function newCodePoint(uint8 opCode, bytes32 nextHash) internal pure returns (Data memory) {
        return newCodePoint(CodePoint(opCode, nextHash, new Data[](0)));
    }

    function newCodePoint(
        uint8 opCode,
        bytes32 nextHash,
        Data memory immediate
    ) internal pure returns (Data memory) {
        Data[] memory imm = new Data[](1);
        imm[0] = immediate;
        return newCodePoint(CodePoint(opCode, nextHash, imm));
    }

    function newCodePoint(CodePoint memory _val) private pure returns (Data memory) {
        return Data(0, _val, new Data[](0), 0, CODE_POINT_TYPECODE, uint256(1));
    }

    function newBuffer(bytes32 bufHash) internal pure returns (Data memory) {
        return
            Data(
                uint256(0),
                CodePoint(0, 0, new Data[](0)),
                new Data[](0),
                bufHash,
                BUFFER_TYPECODE,
                uint256(1)
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2020, Offchain Labs, Inc.
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

pragma solidity ^0.6.11;

import "./Value.sol";

library Hashing {
    using Hashing for Value.Data;
    using Value for Value.CodePoint;

    function keccak1(bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(b));
    }

    function keccak2(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(a, b));
    }

    function bytes32FromArray(
        bytes memory arr,
        uint256 offset,
        uint256 arrLength
    ) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < 32; i++) {
            res = res << 8;
            bytes1 b = arrLength > offset + i ? arr[offset + i] : bytes1(0);
            res = res | uint256(uint8(b));
        }
        return res;
    }

    /*
     * !! Note that dataLength must be a power of two !!
     *
     * If you have an arbitrary data length, you can round it up with roundUpToPow2.
     * The boolean return value tells if the data segment data[startOffset..startOffset+dataLength] only included zeroes.
     * If pack is true, the returned value is the merkle hash where trailing zeroes are ignored, that is,
     *   if h is the smallest height for which all data[startOffset+2**h..] are zero, merkle hash of data[startOffset..startOffset+2**h] is returned.
     * If all elements in the data segment are zero (and pack is true), keccak1(bytes32(0)) is returned.
     */
    function merkleRoot(
        bytes memory data,
        uint256 rawDataLength,
        uint256 startOffset,
        uint256 dataLength,
        bool pack
    ) internal pure returns (bytes32, bool) {
        if (dataLength <= 32) {
            if (startOffset >= rawDataLength) {
                return (keccak1(bytes32(0)), true);
            }
            bytes32 res = keccak1(bytes32(bytes32FromArray(data, startOffset, rawDataLength)));
            return (res, res == keccak1(bytes32(0)));
        }
        (bytes32 h2, bool zero2) = merkleRoot(
            data,
            rawDataLength,
            startOffset + dataLength / 2,
            dataLength / 2,
            false
        );
        if (zero2 && pack) {
            return merkleRoot(data, rawDataLength, startOffset, dataLength / 2, pack);
        }
        (bytes32 h1, bool zero1) = merkleRoot(
            data,
            rawDataLength,
            startOffset,
            dataLength / 2,
            false
        );
        return (keccak2(h1, h2), zero1 && zero2);
    }

    function roundUpToPow2(uint256 len) internal pure returns (uint256) {
        if (len <= 1) return 1;
        else return 2 * roundUpToPow2((len + 1) / 2);
    }

    function bytesToBufferHash(
        bytes memory buf,
        uint256 startOffset,
        uint256 length
    ) internal pure returns (bytes32) {
        (bytes32 mhash, ) = merkleRoot(
            buf,
            startOffset + length,
            startOffset,
            roundUpToPow2(length),
            true
        );
        return keccak2(bytes32(uint256(123)), mhash);
    }

    function hashInt(uint256 val) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(val));
    }

    function hashCodePoint(Value.CodePoint memory cp) internal pure returns (bytes32) {
        assert(cp.immediate.length < 2);
        if (cp.immediate.length == 0) {
            return
                keccak256(abi.encodePacked(Value.codePointTypeCode(), cp.opcode, cp.nextCodePoint));
        }
        return
            keccak256(
                abi.encodePacked(
                    Value.codePointTypeCode(),
                    cp.opcode,
                    cp.immediate[0].hash(),
                    cp.nextCodePoint
                )
            );
    }

    function hashTuplePreImage(bytes32 innerHash, uint256 valueSize)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(uint8(Value.tupleTypeCode()), innerHash, valueSize));
    }

    function hash(Value.Data memory val) internal pure returns (bytes32) {
        if (val.typeCode == Value.intTypeCode()) {
            return hashInt(val.intVal);
        } else if (val.typeCode == Value.codePointTypeCode()) {
            return hashCodePoint(val.cpVal);
        } else if (val.typeCode == Value.tuplePreImageTypeCode()) {
            return hashTuplePreImage(bytes32(val.intVal), val.size);
        } else if (val.typeCode == Value.tupleTypeCode()) {
            Value.Data memory preImage = getTuplePreImage(val.tupleVal);
            return preImage.hash();
        } else if (val.typeCode == Value.hashOnlyTypeCode()) {
            return bytes32(val.intVal);
        } else if (val.typeCode == Value.bufferTypeCode()) {
            return keccak256(abi.encodePacked(uint256(123), val.bufferHash));
        } else {
            require(false, "Invalid type code");
        }
    }

    function getTuplePreImage(Value.Data[] memory vals) internal pure returns (Value.Data memory) {
        require(vals.length <= 8, "Invalid tuple length");
        bytes32[] memory hashes = new bytes32[](vals.length);
        uint256 hashCount = hashes.length;
        uint256 size = 1;
        for (uint256 i = 0; i < hashCount; i++) {
            hashes[i] = vals[i].hash();
            size += vals[i].size;
        }
        bytes32 firstHash = keccak256(abi.encodePacked(uint8(hashes.length), hashes));
        return Value.newTuplePreImage(firstHash, size);
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

pragma solidity ^0.6.11;

import "../../libraries/Cloneable.sol";

contract OutboxEntry is Cloneable {
    address outbox;
    bytes32 public root;
    uint256 public numRemaining;
    mapping(bytes32 => bool) public spentOutput;

    function initialize(bytes32 _root, uint256 _numInBatch) external {
        require(outbox == address(0), "ALREADY_INIT");
        require(root == 0, "ALREADY_INIT");
        require(_root != 0, "BAD_ROOT");
        outbox = msg.sender;
        root = _root;
        numRemaining = _numInBatch;
    }

    function spendOutput(bytes32 _root, bytes32 _id) external returns (uint256) {
        require(msg.sender == outbox, "NOT_FROM_OUTBOX");
        require(!spentOutput[_id], "ALREADY_SPENT");
        require(_root == root, "BAD_ROOT");

        spentOutput[_id] = true;
        numRemaining--;

        return numRemaining;
    }

    function destroy() external {
        require(msg.sender == outbox, "NOT_FROM_OUTBOX");
        safeSelfDestruct(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
    function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    /// same as InboxMessageDelivered but the batch data is available in tx.input
    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}