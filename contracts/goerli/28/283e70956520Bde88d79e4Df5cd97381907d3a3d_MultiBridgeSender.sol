// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "./interfaces/IBridgeSenderAdapter.sol";
import "./MessageStruct.sol";

contract MultiBridgeSender {
    // List of bridge sender adapters
    address[] public senderAdapters;
    // The dApp contract that can use this multi-bridge sender for cross-chain remoteCall.
    // This means the current MultiBridgeSender is only intended to be used by a single dApp.
    address public immutable caller;
    uint32 public nonce;

    event MultiBridgeMsgSent(uint32 nonce, uint64 dstChainId, address target, bytes callData, address[] senderAdapters);
    event SenderAdapterUpdated(address senderAdapter, bool add); // add being false indicates removal of the adapter
    event ErrorSendMessage(address senderAdapters, MessageStruct.Message message);

    modifier onlyCaller() {
        require(msg.sender == caller, "not caller");
        _;
    }

    constructor(address _caller) {
        caller = _caller;
    }

    /**
     * @notice Call a remote function on a destination chain by sending multiple copies of a cross-chain message
     * via all available bridges.
     *
     * A fee in native token may be required by each message bridge to send messages. Any native token fee remained
     * will be refunded back to msg.sender, which requires caller being able to receive native token.
     * Caller can use estimateTotalMessageFee() to get total message fees before calling this function.
     *
     * @param _dstChainId is the destination chainId.
     * @param _target is the contract address on the destination chain.
     * @param _callData is the data to be sent to _target by low-level call(eg. address(_target).call(_callData)).
     */
    function remoteCall(
        uint64 _dstChainId,
        address _target,
        bytes calldata _callData
    ) external payable onlyCaller {
        MessageStruct.Message memory message = MessageStruct.Message(
            uint64(block.chainid),
            _dstChainId,
            nonce,
            _target,
            _callData,
            ""
        );
        uint256 totalFee;
        // send copies of the message through multiple bridges
        for (uint256 i = 0; i < senderAdapters.length; i++) {
            uint256 fee = IBridgeSenderAdapter(senderAdapters[i]).getMessageFee(message);
            // if one bridge is paused it shouldn't halt the process
            try IBridgeSenderAdapter(senderAdapters[i]).sendMessage{value: fee}(message) {
                totalFee += fee;
            }
            catch 
            {
                 emit ErrorSendMessage(senderAdapters[i], message);
            }
        }
        emit MultiBridgeMsgSent(nonce, _dstChainId, _target, _callData, senderAdapters);
        nonce++;
        // refund remaining native token to msg.sender
        if (totalFee < msg.value) {
            payable(msg.sender).transfer(msg.value - totalFee);
        }
    }

    /**
     * @notice Add bridge sender adapters
     */
    function addSenderAdapters(address[] calldata _senderAdapters) external onlyCaller {
        for (uint256 i = 0; i < _senderAdapters.length; i++) {
            _addSenderAdapter(_senderAdapters[i]);
        }
    }

    /**
     * @notice Remove bridge sender adapters
     */
    function removeSenderAdapters(address[] calldata _senderAdapters) external onlyCaller {
        for (uint256 i = 0; i < _senderAdapters.length; i++) {
            _removeSenderAdapter(_senderAdapters[i]);
        }
    }

    /**
     * @notice A helper function for estimating total required message fee by all available message bridges.
     */
    function estimateTotalMessageFee(
        uint64 _dstChainId,
        address _target,
        bytes calldata _callData
    ) public view returns (uint256) {
        MessageStruct.Message memory message = MessageStruct.Message(
            uint64(block.chainid),
            _dstChainId,
            nonce,
            _target,
            _callData,
            ""
        );
        uint256 totalFee;
        for (uint256 i = 0; i < senderAdapters.length; i++) {
            uint256 fee = IBridgeSenderAdapter(senderAdapters[i]).getMessageFee(message);
            totalFee += fee;
        }
        return totalFee;
    }

    function _addSenderAdapter(address _senderAdapter) private {
        for (uint256 i = 0; i < senderAdapters.length; i++) {
            if (senderAdapters[i] == _senderAdapter) {
                return;
            }
        }
        senderAdapters.push(_senderAdapter);
        emit SenderAdapterUpdated(_senderAdapter, true);
    }

    function _removeSenderAdapter(address _senderAdapter) private {
        uint256 lastIndex = senderAdapters.length - 1;
        for (uint256 i = 0; i < senderAdapters.length; i++) {
            if (senderAdapters[i] == _senderAdapter) {
                if (i < lastIndex) {
                    senderAdapters[i] = senderAdapters[lastIndex];
                }
                senderAdapters.pop();
                emit SenderAdapterUpdated(_senderAdapter, false);
                return;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "../MessageStruct.sol";

/**
 * @dev Adapter that connects MultiBridgeSender and each message bridge.
 * Message bridge can implement their favourite encode&decode way for MessageStruct.Message.
 */
interface IBridgeSenderAdapter {
    /**
     * @dev Return native token amount in wei required by this message bridge for sending a MessageStruct.Message.
     */
    function getMessageFee(MessageStruct.Message memory _message) external view returns (uint256);

    /**
     * @dev Send a MessageStruct.Message through this message bridge.
     */
    function sendMessage(MessageStruct.Message memory _message) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

library MessageStruct {
    /**
     * @dev Message indicates a remote call to target contract on destination chain.
     *
     * @param srcChainId is the id of chain where this message is sent from.
     * @param dstChainId is the id of chain where this message is sent to.
     * @param nonce is an incrementing number held by MultiBridgeSender to ensure msgId uniqueness
     * @param target is the contract to be called on dst chain.
     * @param callData is the data to be sent to target by low-level call(eg. address(target).call(callData)).
     * @param bridgeName is the message bridge name used for sending this message.
     */
    struct Message {
        uint64 srcChainId;
        uint64 dstChainId;
        uint32 nonce;
        address target;
        bytes callData;
        string bridgeName;
    }
}