/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// hevm: flattened sources of src/message/OutboundLane.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

////// src/interfaces/IFeeMarket.sol
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

/// @title A interface for user to enroll to be a relayer.
/// @author echo
/// @notice After enroll to be a relyer , you have the duty to relay
/// the meesage which is assigned to you, or you will be slashed
interface IFeeMarket {
    //  Relayer which delivery the messages
    struct DeliveredRelayer {
        // relayer account
        address relayer;
        // encoded message key begin
        uint256 begin;
        // encoded message key end
        uint256 end;
    }
    /// @dev return the real time market maker fee
    /// @notice Revert `!top` when there is not enroll relayer in the fee-market
    function market_fee() external view returns (uint256 fee);
    // Assign new message encoded key to top N relayers in fee-market
    function assign(uint256 nonce) external payable returns(bool);
    // Settle delivered messages and reward/slash relayers
    function settle(DeliveredRelayer[] calldata delivery_relayers, address confirm_relayer) external returns(bool);
}

////// src/interfaces/IOutboundLane.sol
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

/// @title A interface for app layer to send cross chain message
/// @author echo
/// @notice The app layer could implement the interface `IOnMessageDelivered` to receive message dispatch result (optionally)
interface IOutboundLane {
    /// @notice Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param target The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding `abi.encodePacked(SELECTOR, PARAMS)`
    /// @return nonce Latest generated nonce
    function send_message(address target, bytes calldata encoded) external payable returns (uint64 nonce);
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

////// src/message/OutboundLaneVerifier.sol
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

contract OutboundLaneVerifier {
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

    function _verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        bytes memory encoded_proof
    ) internal view {
        Slot0 memory _slot0 = slot0;
        require(
            VERIFIER.verify_messages_delivery_proof(
                inlane_data_hash,
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

    // 32 bytes to identify an unique message from source chain
    // MessageKey encoding:
    // ThisChainPosition | ThisLanePosition | BridgedChainPosition | BridgedLanePosition | Nonce
    // [0..8)   bytes ---- Reserved
    // [8..12)  bytes ---- ThisChainPosition
    // [16..20) bytes ---- ThisLanePosition
    // [12..16) bytes ---- BridgedChainPosition
    // [20..24) bytes ---- BridgedLanePosition
    // [24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`
    function encodeMessageKey(uint64 nonce) public view returns (uint256) {
        Slot0 memory _slot0 = slot0;
        return (uint256(_slot0.this_chain_pos) << 160) +
                (uint256(_slot0.this_lane_pos) << 128) +
                (uint256(_slot0.bridged_chain_pos) << 96) +
                (uint256(_slot0.bridged_lane_pos) << 64) +
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

////// src/message/OutboundLane.sol
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
// 3) the messages hash are stored in the storage;
// 4) external component (relay) delivers messages to bridged chain;
// 5) messages are processed in order (ordered by assigned nonce);
// 6) relay may send proof-of-delivery back to this chain.
//
// Once message is sent, its progress can be tracked by looking at lane contract events.
// The assigned nonce is reported using `MessageAccepted` event. When message is
// delivered to the the bridged chain, it is reported using `MessagesDelivered` event.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../interfaces/IOutboundLane.sol"; */
/* import "../interfaces/IFeeMarket.sol"; */
/* import "./OutboundLaneVerifier.sol"; */
/* import "../spec/SourceChain.sol"; */
/* import "../spec/TargetChain.sol"; */

// Everything about outgoing messages sending.
contract OutboundLane is IOutboundLane, OutboundLaneVerifier, TargetChain, SourceChain {
    /// slot 1
    OutboundLaneNonce public outboundLaneNonce;
    /// slot 2
    /// nonce => hash(MessagePayload)
    mapping(uint64 => bytes32) public messages;

    address public immutable FEE_MARKET;

    uint256 private constant MAX_CALLDATA_LENGTH       = 2048;
    uint64  private constant MAX_PENDING_MESSAGES      = 20;
    uint64  private constant MAX_PRUNE_MESSAGES_ATONCE = 5;

    event MessageAccepted(uint64 indexed nonce, address source, address target, bytes encoded);
    event MessagesDelivered(uint64 indexed begin, uint64 indexed end);
    event MessagePruned(uint64 indexed oldest_unpruned_nonce);

    /// Outbound lane nonce.
    struct OutboundLaneNonce {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Nonce of the latest message, generated by this lane.
        uint64 latest_generated_nonce;
        // Nonce of the oldest message that we haven't yet pruned. May point to not-yet-generated
        // message if all sent messages are already pruned.
        uint64 oldest_unpruned_nonce;
    }

    /// @dev Deploys the OutboundLane contract
    /// @param _lightClientBridge The contract address of on-chain light client
    /// @param _thisChainPosition The thisChainPosition of outbound lane
    /// @param _thisLanePosition The lanePosition of this outbound lane
    /// @param _bridgedChainPosition The bridgedChainPosition of outbound lane
    /// @param _bridgedLanePosition The lanePosition of target inbound lane
    /// @param _oldest_unpruned_nonce The oldest_unpruned_nonce of outbound lane
    /// @param _latest_received_nonce The latest_received_nonce of outbound lane
    /// @param _latest_generated_nonce The latest_generated_nonce of outbound lane
    constructor(
        address _lightClientBridge,
        address _feeMarket,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        uint64 _oldest_unpruned_nonce,
        uint64 _latest_received_nonce,
        uint64 _latest_generated_nonce
    ) OutboundLaneVerifier(
        _lightClientBridge,
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
        outboundLaneNonce = OutboundLaneNonce(
            _latest_received_nonce,
            _latest_generated_nonce,
            _oldest_unpruned_nonce
        );
        FEE_MARKET = _feeMarket;
    }

    /// @dev Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param target The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding
    /// @return nonce Latest generated nonce
    function send_message(address target, bytes calldata encoded) external payable override returns (uint64) {
        require(outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce < MAX_PENDING_MESSAGES, "TooManyPendingMessages");
        require(outboundLaneNonce.latest_generated_nonce < type(uint64).max, "Overflow");
        require(encoded.length <= MAX_CALLDATA_LENGTH, "TooLargeCalldata");

        uint64 nonce = outboundLaneNonce.latest_generated_nonce + 1;

        // assign the message to top relayers
        uint encoded_key = encodeMessageKey(nonce);
        require(IFeeMarket(FEE_MARKET).assign{value: msg.value}(encoded_key), "AssignRelayersFailed");

        outboundLaneNonce.latest_generated_nonce = nonce;
        MessagePayload memory payload = MessagePayload({
            source: msg.sender,
            target: target,
            encoded: encoded
        });
        messages[nonce] = hash(payload);
        // message sender prune at most `MAX_PRUNE_MESSAGES_ATONCE` messages
        _prune_messages(MAX_PRUNE_MESSAGES_ATONCE);
        emit MessageAccepted(
            nonce,
            msg.sender,
            target,
            encoded);
        return nonce;
    }

    /// Receive messages delivery proof from bridged chain.
    function receive_messages_delivery_proof(
        InboundLaneData calldata inboundLaneData,
        bytes memory messagesProof
    ) external {
        _verify_messages_delivery_proof(hash(inboundLaneData), messagesProof);
        DeliveredMessages memory confirmed_messages = _confirm_delivery(inboundLaneData);
        // settle the confirmed_messages at fee market
        settle_messages(inboundLaneData.relayers, confirmed_messages.begin, confirmed_messages.end);
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return hash(data());
    }

    function message_size() public view returns (uint64 size) {
        size = outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce;
    }

    /// Get lane data from the storage.
    function data() public view returns (OutboundLaneDataStorage memory lane_data) {
        uint64 size = message_size();
        if (size > 0) {
            lane_data.messages = new MessageStorage[](size);
            uint64 begin = outboundLaneNonce.latest_received_nonce + 1;
            for (uint64 index = 0; index < size; index++) {
                uint64 nonce = index + begin;
                lane_data.messages[index] = MessageStorage(encodeMessageKey(nonce), messages[nonce]);
            }
        }
        lane_data.latest_received_nonce = outboundLaneNonce.latest_received_nonce;
    }

    function _extract_inbound_lane_info(
        InboundLaneData memory lane_data
    ) private pure returns (
        uint64 total_unrewarded_messages,
        uint64 last_delivered_nonce
    ) {
        total_unrewarded_messages = lane_data.last_delivered_nonce - lane_data.last_confirmed_nonce;
        last_delivered_nonce = lane_data.last_delivered_nonce;
    }

    /// Confirm messages delivery.
    function _confirm_delivery(
        InboundLaneData memory inboundLaneData
    ) private returns (
        DeliveredMessages memory confirmed_messages
    ) {
        (uint64 total_messages, uint64 latest_delivered_nonce) = _extract_inbound_lane_info(inboundLaneData);

        OutboundLaneNonce memory nonce = outboundLaneNonce;
        require(latest_delivered_nonce > nonce.latest_received_nonce, "NoNewConfirmations");
        require(latest_delivered_nonce <= nonce.latest_generated_nonce, "FailedToConfirmFutureMessages");
        // that the relayer has declared correct number of messages that the proof contains (it
        // is checked outside of the function). But it may happen (but only if this/bridged
        // chain storage is corrupted, though) that the actual number of confirmed messages if
        // larger than declared.
        require(latest_delivered_nonce - nonce.latest_received_nonce <= total_messages, "TryingToConfirmMoreMessagesThanExpected");
        _check_relayers(latest_delivered_nonce, inboundLaneData.relayers);
        uint64 prev_latest_received_nonce = nonce.latest_received_nonce;
        outboundLaneNonce.latest_received_nonce = latest_delivered_nonce;
        confirmed_messages = DeliveredMessages({
            begin: prev_latest_received_nonce + 1,
            end: latest_delivered_nonce
        });
        // emit 'MessagesDelivered' event
        emit MessagesDelivered(confirmed_messages.begin, confirmed_messages.end);
    }

    /// Extract new dispatch results from the unrewarded relayers vec.
    ///
    /// Revert if unrewarded relayers vec contains invalid data, meaning that the bridged
    /// chain has invalid runtime storage.
    function _check_relayers(uint64 latest_received_nonce, UnrewardedRelayer[] memory relayers) private pure {
        // the only caller of this functions checks that the
        // prev_latest_received_nonce..=latest_received_nonce is valid, so we're ready to accept
        // messages in this range => with_capacity call must succeed here or we'll be unable to receive
        // confirmations at all
        uint64 last_entry_end = 0;
        for (uint64 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory entry = relayers[i];
            // unrewarded relayer entry must have at least 1 unconfirmed message
            // (guaranteed by the `InboundLane::receive_message()`)
            require(entry.messages.end >= entry.messages.begin, "EmptyUnrewardedRelayerEntry");
            if (last_entry_end > 0) {
                uint64 expected_entry_begin = last_entry_end + 1;
                // every entry must confirm range of messages that follows previous entry range
                // (guaranteed by the `InboundLane::receive_message()`)
                require(entry.messages.begin == expected_entry_begin, "NonConsecutiveUnrewardedRelayerEntries");
            }
            last_entry_end = entry.messages.end;
            // entry can't confirm messages larger than `inbound_lane_data.latest_received_nonce()`
            // (guaranteed by the `InboundLane::receive_message()`)
			// technically this will be detected in the next loop iteration as
			// `InvalidNumberOfDispatchResults` but to guarantee safety of loop operations below
			// this is detected now
            require(entry.messages.end <= latest_received_nonce, "FailedToConfirmFutureMessages");
        }
    }

    /// Prune at most `max_messages_to_prune` already received messages.
    ///
    /// Returns number of pruned messages.
    function _prune_messages(uint64 max_messages_to_prune) private returns (uint64 pruned_messages) {
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        while (pruned_messages < max_messages_to_prune &&
            nonce.oldest_unpruned_nonce <= nonce.latest_received_nonce)
        {
            delete messages[nonce.oldest_unpruned_nonce];
            pruned_messages += 1;
            nonce.oldest_unpruned_nonce += 1;
        }
        if (pruned_messages > 0) {
            outboundLaneNonce.oldest_unpruned_nonce = nonce.oldest_unpruned_nonce;
            emit MessagePruned(outboundLaneNonce.oldest_unpruned_nonce);
        }
        return pruned_messages;
    }

    function settle_messages(
        UnrewardedRelayer[] memory relayers,
        uint64 received_start,
        uint64 received_end
    ) private {
        IFeeMarket.DeliveredRelayer[] memory delivery_relayers = new IFeeMarket.DeliveredRelayer[](relayers.length);
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory r = relayers[i];
            uint64 nonce_begin = _max(r.messages.begin, received_start);
            uint64 nonce_end = _min(r.messages.end, received_end);
            delivery_relayers[i] = IFeeMarket.DeliveredRelayer(r.relayer, encodeMessageKey(nonce_begin), encodeMessageKey(nonce_end));
        }
        require(IFeeMarket(FEE_MARKET).settle(delivery_relayers, msg.sender), "SettleFailed");
    }

    // --- Math ---
    function _min(uint64 x, uint64 y) private pure returns (uint64 z) {
        return x <= y ? x : y;
    }

    function _max(uint64 x, uint64 y) private pure returns (uint64 z) {
        return x >= y ? x : y;
    }
}