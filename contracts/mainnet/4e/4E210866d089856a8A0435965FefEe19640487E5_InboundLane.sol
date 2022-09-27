/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// hevm: flattened sources of src/message/InboundLane.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

////// src/interfaces/ICrossChainFilter.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

/// @title A interface for message layer to filter unsafe message
/// @author echo
/// @notice The app layer must implement the interface `ICrossChainFilter`
interface ICrossChainFilter {
    /// @notice Verify the source sender and payload of source chain messages,
    /// Generally, app layer cross-chain messages require validation of sourceAccount
    /// @param bridgedChainPosition The source chain position which send the message
    /// @param bridgedLanePosition The source lane position which send the message
    /// @param sourceAccount The source contract address which send the message
    /// @param payload The calldata which encoded by ABI Encoding
    /// @return Can call target contract if returns true
    function cross_chain_filter(uint32 bridgedChainPosition, uint32 bridgedLanePosition, address sourceAccount, bytes calldata payload) external view returns (bool);
}

////// src/interfaces/IVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

interface IVerifier {
    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);
}

////// src/message/InboundLaneVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../interfaces/IVerifier.sol"; */

contract InboundLaneVerifier {
    /// @dev Indentify slot
    Slot0 internal slot0;

    /// @dev The contract address of on-chain verifier
    IVerifier public immutable VERIFIER;

    struct Slot0 {
        // Bridged lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
        uint32 bridged_lane_pos;
        // Bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
        uint32 bridged_chain_pos;
        // This lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
        uint32 this_lane_pos;
        // This chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
        uint32 this_chain_pos;
    }

    constructor(
        address _verifier,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) {
        VERIFIER = IVerifier(_verifier);
        slot0.this_chain_pos = _thisChainPosition;
        slot0.this_lane_pos = _thisLanePosition;
        slot0.bridged_chain_pos = _bridgedChainPosition;
        slot0.bridged_lane_pos = _bridgedLanePosition;
    }

    function _verify_messages_proof(
        bytes32 outlane_data_hash,
        bytes memory encoded_proof
    ) internal view {
        Slot0 memory _slot0 = slot0;
        require(
            VERIFIER.verify_messages_proof(
                outlane_data_hash,
                _slot0.this_chain_pos,
                _slot0.bridged_lane_pos,
                encoded_proof
            ), "!proof"
        );
    }

    function getLaneInfo() external view returns (uint32,uint32,uint32,uint32) {
        Slot0 memory _slot0 = slot0;
        return (
           _slot0.this_chain_pos,
           _slot0.this_lane_pos,
           _slot0.bridged_chain_pos,
           _slot0.bridged_lane_pos
       );
    }

    /// 32 bytes to identify an unique message from source chain
    /// MessageKey encoding:
    /// BridgedChainPosition | BridgedLanePosition | ThisChainPosition | ThisLanePosition | Nonce
    /// [0..8)   bytes ---- Reserved
    /// [8..12)  bytes ---- BridgedChainPosition
    /// [16..20) bytes ---- BridgedLanePosition
    /// [12..16) bytes ---- ThisChainPosition
    /// [20..24) bytes ---- ThisLanePosition
    /// [24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`
    function encodeMessageKey(uint64 nonce) public view returns (uint256) {
        Slot0 memory _slot0 = slot0;
        return (uint256(_slot0.bridged_chain_pos) << 160) +
                (uint256(_slot0.bridged_lane_pos) << 128) +
                (uint256(_slot0.this_chain_pos) << 96) +
                (uint256(_slot0.this_lane_pos) << 64) +
                uint256(nonce);
    }
}


////// src/spec/SourceChain.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

contract SourceChain {
    /// The MessagePayload is the structure of RPC which should be delivery to target chain
    /// @param source The source contract address which send the message
    /// @param target The targe contract address which receive the message
    /// @param encoded The calldata which encoded by ABI Encoding
    struct MessagePayload {
        address source;
        address target;
        bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
    }

    /// Message key (unique message identifier) as it is stored in the storage.
    struct MessageKey {
        // This chain position
        uint32 this_chain_pos;
        // Position of the message this lane.
        uint32 this_lane_pos;
        // Bridged chain position
        uint32 bridged_chain_pos;
        // Position of the message bridged lane.
        uint32 bridged_lane_pos;
        // Nonce of the message.
        uint64 nonce;
    }

    struct MessageStorage {
        uint256 encoded_key;
        bytes32 payload_hash;
    }

    /// Message as it is stored in the storage.
    struct Message {
        // Encoded message key.
        uint256 encoded_key;
        // Message payload.
        MessagePayload payload;
    }

    /// Outbound lane data.
    struct OutboundLaneData {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Messages sent through this lane.
        Message[] messages;
    }

    struct OutboundLaneDataStorage {
        uint64 latest_received_nonce;
        MessageStorage[] messages;
    }

    /// @dev Hash of the OutboundLaneData Schema
    /// keccak256(abi.encodePacked(
    ///     "OutboundLaneData(uint256 latest_received_nonce,Message[] messages)",
    ///     "Message(uint256 encoded_key,MessagePayload payload)",
    ///     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    ///     )
    /// )
    bytes32 internal constant OUTBOUNDLANEDATA_TYPEHASH = 0x823237038687bee0f021baf36aa1a00c49bd4d430512b28fed96643d7f4404c6;


    /// @dev Hash of the Message Schema
    /// keccak256(abi.encodePacked(
    ///     "Message(uint256 encoded_key,MessagePayload payload)",
    ///     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    ///     )
    /// )
    bytes32 internal constant MESSAGE_TYPEHASH = 0xfc686c8227203ee2031e2c031380f840b8cea19f967c05fc398fdeb004e7bf8b;

    /// @dev Hash of the MessagePayload Schema
    /// keccak256(abi.encodePacked(
    ///     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    ///     )
    /// )
    bytes32 internal constant MESSAGEPAYLOAD_TYPEHASH = 0x582ffe1da2ae6da425fa2c8a2c423012be36b65787f7994d78362f66e4f84101;

    function hash(OutboundLaneData memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                OUTBOUNDLANEDATA_TYPEHASH,
                data.latest_received_nonce,
                hash(data.messages)
            )
        );
    }

    function hash(OutboundLaneDataStorage memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                OUTBOUNDLANEDATA_TYPEHASH,
                data.latest_received_nonce,
                hash(data.messages)
            )
        );
    }

    function hash(MessageStorage[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        uint msgsLength = msgs.length;
        bytes memory encoded = abi.encode(msgsLength);
        for (uint256 i = 0; i < msgsLength; i ++) {
            MessageStorage memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    message.payload_hash
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(Message[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        uint msgsLength = msgs.length;
        bytes memory encoded = abi.encode(msgsLength);
        for (uint256 i = 0; i < msgsLength; i ++) {
            Message memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    hash(message.payload)
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(MessagePayload memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MESSAGEPAYLOAD_TYPEHASH,
                payload.source,
                payload.target,
                keccak256(payload.encoded)
            )
        );
    }

    function decodeMessageKey(uint256 encoded) internal pure returns (MessageKey memory key) {
        key.this_chain_pos = uint32(encoded >> 160);
        key.this_lane_pos = uint32(encoded >> 128);
        key.bridged_chain_pos = uint32(encoded >> 96);
        key.bridged_lane_pos = uint32(encoded >> 64);
        key.nonce = uint64(encoded);
    }
}

////// src/spec/TargetChain.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

contract TargetChain {
    /// Delivered messages with their dispatch result.
    struct DeliveredMessages {
        // Nonce of the first message that has been delivered (inclusive).
        uint64 begin;
        // Nonce of the last message that has been delivered (inclusive).
        uint64 end;
    }

    /// Unrewarded relayer entry stored in the inbound lane data.
    ///
    /// This struct represents a continuous range of messages that have been delivered by the same
    /// relayer and whose confirmations are still pending.
    struct UnrewardedRelayer {
        // Address of the relayer.
        address relayer;
        // Messages range, delivered by this relayer.
        DeliveredMessages messages;
    }

    /// Inbound lane data
    struct InboundLaneData {
        // Identifiers of relayers and messages that they have delivered to this lane (ordered by
        // message nonce).
        //
        // This serves as a helper storage item, to allow the source chain to easily pay rewards
        // to the relayers who successfully delivered messages to the target chain (inbound lane).
        //
        // All nonces in this queue are in
        // range: `(self.last_confirmed_nonce; self.last_delivered_nonce()]`.
        //
        // When a relayer sends a single message, both of begin and end nonce are the same.
        // When relayer sends messages in a batch, the first arg is the lowest nonce, second arg the
        // highest nonce. Multiple dispatches from the same relayer are allowed.
        UnrewardedRelayer[] relayers;
        // Nonce of the last message that
        // a) has been delivered to the target (this) chain and
        // b) the delivery has been confirmed on the source chain
        //
        // that the target chain knows of.
        //
        // This value is updated indirectly when an `OutboundLane` state of the source
        // chain is received alongside with new messages delivery.
        uint64 last_confirmed_nonce;
        // Nonce of the latest received or has been delivered message to this inbound lane.
        uint64 last_delivered_nonce;
    }

    /// @dev Hash of the InboundLaneData Schema
    /// keccak256(abi.encodePacked(
    ///     "InboundLaneData(UnrewardedRelayer[] relayers,uint64 last_confirmed_nonce,uint64 last_delivered_nonce)",
    ///     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
    ///     "DeliveredMessages(uint64 begin,uint64 end)"
    ///     )
    /// )
    bytes32 internal constant INBOUNDLANEDATA_TYPEHASH = 0xcf4a39e72acc9d64da0fc507104c55de6ee7e6e1a477d8700014bcb981f85106;

    /// @dev Hash of the UnrewardedRelayer Schema
    /// keccak256(abi.encodePacked(
    ///     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
    ///     "DeliveredMessages(uint64 begin,uint64 end)"
    ///     )
    /// )
    bytes32 internal constant UNREWARDEDRELAYER_TYPETASH = 0x6d8ba9a028be62615788b0b9200c2e575678c124d2db04ca91582405eba190a1;

    /// @dev Hash of the DeliveredMessages Schema
    /// keccak256(abi.encodePacked(
    ///     "DeliveredMessages(uint64 begin,uint64 end)"
    ///     )
    /// )
    bytes32 internal constant DELIVEREDMESSAGES_TYPETASH = 0x1984c1907b379883ef1736e0351d28f5b4b82026a854e28971d89eb48f32fbe2;

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                INBOUNDLANEDATA_TYPEHASH,
                hash(inboundLaneData.relayers),
                inboundLaneData.last_confirmed_nonce,
                inboundLaneData.last_delivered_nonce
            )
        );
    }

    function hash(UnrewardedRelayer[] memory relayers)
        internal
        pure
        returns (bytes32)
    {
        uint relayersLength = relayers.length;
        bytes memory encoded = abi.encode(relayersLength);
        for (uint256 i = 0; i < relayersLength; i++) {
            UnrewardedRelayer memory r = relayers[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    UNREWARDEDRELAYER_TYPETASH,
                    r.relayer,
                    hash(r.messages)
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(DeliveredMessages memory messages)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                DELIVEREDMESSAGES_TYPETASH,
                messages.begin,
                messages.end
            )
        );
    }
}

////// src/message/InboundLane.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.
//
// Message module that allows sending and receiving messages using lane concept:
//
// 1) the message is sent using `send_message()` call;
// 2) every outbound message is assigned nonce;
// 3) the messages are stored in the storage;
// 4) external component (relay) delivers messages to bridged chain;
// 5) messages are processed in order (ordered by assigned nonce);
// 6) relay may send proof-of-delivery back to this chain.
//
// Once message is sent, its progress can be tracked by looking at lane contract events.
// The assigned nonce is reported using `MessageAccepted` event. When message is
// delivered to the the bridged chain, it is reported using `MessagesDelivered` event.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../interfaces/ICrossChainFilter.sol"; */
/* import "./InboundLaneVerifier.sol"; */
/* import "../spec/SourceChain.sol"; */
/* import "../spec/TargetChain.sol"; */

/// @title Everything about incoming messages receival
/// @author echo
/// @notice The inbound lane is the message layer of the bridge
/// @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
contract InboundLane is InboundLaneVerifier, SourceChain, TargetChain {
    /// slot 1
    InboundLaneNonce public inboundLaneNonce;
    /// slot 2
    /// index => UnrewardedRelayer
    /// indexes to relayers and messages that they have delivered to this lane (ordered by
    /// message nonce).
    ///
    /// This serves as a helper storage item, to allow the source chain to easily pay rewards
    /// to the relayers who successfully delivered messages to the target chain (inbound lane).
    ///
    /// All nonces in this queue are in
    /// range: `(self.last_confirmed_nonce; self.last_delivered_nonce()]`.
    ///
    /// When a relayer sends a single message, both of begin and end nonce are the same.
    /// When relayer sends messages in a batch, the first arg is the lowest nonce, second arg the
    /// highest nonce. Multiple dispatches from the same relayer are allowed.
    mapping(uint64 => UnrewardedRelayer) public relayers;
    uint256 internal locked;

    /// @dev Gas used per message needs to be less than `MAX_GAS_PER_MESSAGE` wei
    uint256 private constant MAX_GAS_PER_MESSAGE = 240000;
    /// @dev Gas buffer for executing `send_message` tx
    uint256 private constant GAS_BUFFER = 10000;
    /// @dev This parameter must lesser than 256
    /// Maximal number of unconfirmed messages at inbound lane. Unconfirmed means that the
    /// message has been delivered, but either confirmations haven't been delivered back to the
    /// source chain, or we haven't received reward confirmations for these messages yet.
    ///
    /// This constant limits difference between last message from last entry of the
    /// `InboundLaneData::relayers` and first message at the first entry.
    ///
    /// This value also represents maximal number of messages in single delivery transaction.
    /// Transaction that is declaring more messages than this value, will be rejected. Even if
    /// these messages are from different lanes.
    uint256 private constant MAX_UNCONFIRMED_MESSAGES = 20;

    /// @dev Notifies an observer that the message has dispatched
    /// @param nonce The message nonce
    /// @param result The message result
    event MessageDispatched(uint64 nonce, bool result);

    /// @dev ID of the next message, which is incremented in strict order
    /// @notice When upgrading the lane, this value must be synchronized
    struct InboundLaneNonce {
        // Nonce of the last message that
        // a) has been delivered to the target (this) chain and
        // b) the delivery has been confirmed on the source chain
        //
        // that the target chain knows of.
        //
        // This value is updated indirectly when an `OutboundLane` state of the source
        // chain is received alongside with new messages delivery.
        uint64 last_confirmed_nonce;
        // Nonce of the latest received or has been delivered message to this inbound lane.
        uint64 last_delivered_nonce;

        // Range of UnrewardedRelayers
        // Front index of the UnrewardedRelayers (inclusive).
        uint64 relayer_range_front;
        // Back index of the UnrewardedRelayers (inclusive).
        uint64 relayer_range_back;
    }

    // --- Synchronization ---
    modifier nonReentrant {
        require(locked == 0, "Lane: locked");
        locked = 1;
        _;
        locked = 0;
    }

    /// @dev Deploys the InboundLane contract
    /// @param _lightClientBridge The contract address of on-chain light client
    /// @param _thisChainPosition The thisChainPosition of inbound lane
    /// @param _thisLanePosition The lanePosition of this inbound lane
    /// @param _bridgedChainPosition The bridgedChainPosition of inbound lane
    /// @param _bridgedLanePosition The lanePosition of target outbound lane
    /// @param _last_confirmed_nonce The last_confirmed_nonce of inbound lane
    /// @param _last_delivered_nonce The last_delivered_nonce of inbound lane
    constructor(
        address _lightClientBridge,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        uint64 _last_confirmed_nonce,
        uint64 _last_delivered_nonce
    ) InboundLaneVerifier(
        _lightClientBridge,
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
        inboundLaneNonce = InboundLaneNonce(
            _last_confirmed_nonce,
            _last_delivered_nonce,
            1,
            0
        );
    }

    /// Receive messages proof from bridged chain.
    ///
    /// The weight of the call assumes that the transaction always brings outbound lane
    /// state update. Because of that, the submitter (relayer) has no benefit of not including
    /// this data in the transaction, so reward confirmations lags should be minimal.
    function receive_messages_proof(
        OutboundLaneData memory outboundLaneData,
        bytes memory messagesProof,
        uint delivery_size
    ) external nonReentrant {
        _verify_messages_proof(hash(outboundLaneData), messagesProof);
        // Require there is enough gas to play all messages
        require(
            gasleft() >= outboundLaneData.messages.length * (MAX_GAS_PER_MESSAGE + GAS_BUFFER),
            "!gas"
        );
        _receive_state_update(outboundLaneData.latest_received_nonce);
        _receive_message(outboundLaneData.messages, delivery_size);
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return hash(data());
    }

    /// Get lane data from the storage.
    function data() public view returns (InboundLaneData memory lane_data) {
        uint64 size = _relayers_size();
        if (size > 0) {
            lane_data.relayers = new UnrewardedRelayer[](size);
            uint64 front = inboundLaneNonce.relayer_range_front;
            for (uint64 index = 0; index < size; index++) {
                lane_data.relayers[index] = relayers[front + index];
            }
        }
        lane_data.last_confirmed_nonce = inboundLaneNonce.last_confirmed_nonce;
        lane_data.last_delivered_nonce = inboundLaneNonce.last_delivered_nonce;
    }

    function _relayers_size() private view returns (uint64 size) {
        if (inboundLaneNonce.relayer_range_back >= inboundLaneNonce.relayer_range_front) {
            size = inboundLaneNonce.relayer_range_back - inboundLaneNonce.relayer_range_front + 1;
        }
    }

    function _relayers_back() private view returns (address pre_relayer) {
        if (_relayers_size() > 0) {
            uint64 back = inboundLaneNonce.relayer_range_back;
            pre_relayer = relayers[back].relayer;
        }
    }

    /// Receive state of the corresponding outbound lane.
    /// Syncing state from SourceChain::OutboundLane, deal with nonce and relayers.
    function _receive_state_update(uint64 latest_received_nonce) private returns (uint64) {
        uint64 last_delivered_nonce = inboundLaneNonce.last_delivered_nonce;
        uint64 last_confirmed_nonce = inboundLaneNonce.last_confirmed_nonce;
        // SourceChain::OutboundLane::latest_received_nonce must less than or equal to TargetChain::InboundLane::last_delivered_nonce, otherwise it will receive the future nonce which has not delivery.
        // This should never happen if proofs are correct
        require(latest_received_nonce <= last_delivered_nonce, "InvalidReceivedNonce");
        if (latest_received_nonce > last_confirmed_nonce) {
            uint64 new_confirmed_nonce = latest_received_nonce;
            uint64 front = inboundLaneNonce.relayer_range_front;
            uint64 back = inboundLaneNonce.relayer_range_back;
            for (uint64 index = front; index <= back; index++) {
                UnrewardedRelayer storage entry = relayers[index];
                if (entry.messages.end <= new_confirmed_nonce) {
                    // Firstly, remove all of the records where higher nonce <= new confirmed nonce
                    delete relayers[index];
                    inboundLaneNonce.relayer_range_front = index + 1;
                } else if (entry.messages.begin <= new_confirmed_nonce) {
                    // Secondly, update the next record with lower nonce equal to new confirmed nonce if needed.
                    // Note: There will be max. 1 record to update as we don't allow messages from relayers to
                    // overlap.
                    entry.messages.begin = new_confirmed_nonce + 1;
                }
            }
            inboundLaneNonce.last_confirmed_nonce = new_confirmed_nonce;
        }
        return latest_received_nonce;
    }

    /// Receive new message.
    function _receive_message(Message[] memory messages, uint delivery_size) private {
        require(delivery_size <= messages.length, "!size");
        address relayer = msg.sender;
        uint64 begin = inboundLaneNonce.last_delivered_nonce + 1;
        uint64 next = begin;
        for (uint256 i = 0; i < delivery_size; i++) {
            Message memory message = messages[i];
            MessageKey memory key = decodeMessageKey(message.encoded_key);
            MessagePayload memory message_payload = message.payload;
            if (key.nonce < next) {
                continue;
            }
            Slot0 memory _slot0 = slot0;
            // check message nonce is correct and increment nonce for replay protection
            require(key.nonce == next, "InvalidNonce");
            // check message is from the correct source chain position
            require(key.this_chain_pos == _slot0.bridged_chain_pos, "InvalidSourceChainId");
            // check message is from the correct source lane position
            require(key.this_lane_pos == _slot0.bridged_lane_pos, "InvalidSourceLaneId");
            // check message delivery to the correct target chain position
            require(key.bridged_chain_pos == _slot0.this_chain_pos, "InvalidTargetChainId");
            // check message delivery to the correct target lane position
            require(key.bridged_lane_pos == _slot0.this_lane_pos, "InvalidTargetLaneId");
            // if there are more unconfirmed messages than we may accept, reject this message
            require(next - inboundLaneNonce.last_confirmed_nonce <= MAX_UNCONFIRMED_MESSAGES, "TooManyUnconfirmedMessages");

            // then, dispatch message
            bool dispatch_result = _dispatch(message_payload);
            emit MessageDispatched(key.nonce, dispatch_result);

            // update inbound lane nonce storage
            inboundLaneNonce.last_delivered_nonce = next;

            next += 1;
        }
        if (inboundLaneNonce.last_delivered_nonce >= begin) {
            uint64 end = inboundLaneNonce.last_delivered_nonce;
            // now let's update inbound lane storage
            address pre_relayer = _relayers_back();
            if (pre_relayer == relayer) {
                UnrewardedRelayer storage r = relayers[inboundLaneNonce.relayer_range_back];
                r.messages.end = end;
            } else {
                inboundLaneNonce.relayer_range_back += 1;
                relayers[inboundLaneNonce.relayer_range_back] = UnrewardedRelayer(relayer, DeliveredMessages(begin, end));
            }
        }
    }

    /// @dev dispatch the cross chain message
    /// @param payload payload of the dispatch message
    /// @return dispatch_result the dispatch call result
    /// - Return True:
    ///   1. filter return True and dispatch call successfully
    /// - Return False:
    ///   1. filter return False
    ///   2. filter return True and dispatch call failed
    function _dispatch(MessagePayload memory payload) private returns (bool dispatch_result) {
        Slot0 memory _slot0 = slot0;
        bytes memory filterCallData = abi.encodeWithSelector(
            ICrossChainFilter.cross_chain_filter.selector,
            _slot0.bridged_chain_pos,
            _slot0.bridged_lane_pos,
            payload.source,
            payload.encoded
        );
        if (_filter(payload.target, filterCallData)) {
            // Deliver the message to the target
            (dispatch_result,) = payload.target.call{gas: MAX_GAS_PER_MESSAGE}(payload.encoded);
        }
    }

    /// @dev filter the cross chain message
    /// @dev The app layer must implement the interface `ICrossChainFilter`
    /// to verify the source sender and payload of source chain messages.
    /// @param target target of the dispatch message
    /// @param encoded encoded calldata of the dispatch message
    /// @return canCall the filter static call result, Return True only when target contract
    /// implement the `ICrossChainFilter` interface with return data is True.
    function _filter(address target, bytes memory encoded) private view returns (bool canCall) {
        (bool ok, bytes memory result) = target.staticcall{gas: GAS_BUFFER}(encoded);
        if (ok) {
            if (result.length == 32) {
                canCall = abi.decode(result, (bool));
            }
        }
    }
}