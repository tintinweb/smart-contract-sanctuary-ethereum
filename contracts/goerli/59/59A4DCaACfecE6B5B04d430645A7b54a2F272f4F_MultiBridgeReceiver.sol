// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "./interfaces/IMultiBridgeReceiver.sol";
import "./MessageStruct.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiBridgeReceiver is IMultiBridgeReceiver, Ownable {
    uint256 public constant THRESHOLD_DECIMAL = 100;
    // minimum accumulated power precentage for each message to be executed
    uint64 public quorumThreshold;

    address[] public receiverAdapters;
    // receiverAdapter => power of bridge receive adapers
    mapping(address => uint64) public receiverAdapterPowers;
    // total power of all bridge adapters
    uint64 public totalPower;

    struct MsgInfo {
        bool executed;
        mapping(address => bool) from; // bridge receiver adapters that has already delivered this message.
    }
    // msgId => MsgInfo
    mapping(bytes32 => MsgInfo) public msgInfos;

    event ReceiverAdapterUpdated(address receiverAdapter, uint64 power);
    event QuorumThresholdUpdated(uint64 quorumThreshold);
    event SingleBridgeMsgReceived(uint64 srcChainId, string indexed bridgeName, uint32 nonce, address receiverAddr);
    event MessageExecuted(uint64 srcChainId, uint32 nonce, address target, bytes callData);

    modifier onlyReceiverAdapter() {
        require(receiverAdapterPowers[msg.sender] > 0, "not allowed bridge receiver adapter");
        _;
    }

    /**
     * @notice A modifier used for restricting the caller of some functions to be this contract itself.
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "not self");
        _;
    }

    /**
     * @notice A one-time function to initialize contract states by the owner.
     * The contract ownership will be renounced at the end of this call.
     */
    function initialize(
        address[] memory _receiverAdapters,
        uint32[] memory _powers,
        uint64 _quorumThreshold
    ) external onlyOwner {
        require(_receiverAdapters.length == _powers.length, "mismatch length");
        require(_quorumThreshold <= THRESHOLD_DECIMAL, "invalid threshold");
        for (uint256 i = 0; i < _receiverAdapters.length; i++) {
            _updateReceiverAdapter(_receiverAdapters[i], _powers[i]);
        }
        quorumThreshold = _quorumThreshold;
        renounceOwnership();
    }

    /**
     * @notice Receive messages from allowed bridge receiver adapters.
     * If the accumulated power of a message has reached the power threshold,
     * this message will be executed immediately, which will invoke an external function call
     * according to the message content.
     */
    function receiveMessage(MessageStruct.Message calldata _message) external override onlyReceiverAdapter {
        bytes32 msgId = getMsgId(_message);
        MsgInfo storage msgInfo = msgInfos[msgId];
        require(msgInfo.from[msg.sender] == false, "already received from this bridge adapter");
        msgInfo.from[msg.sender] = true;
        emit SingleBridgeMsgReceived(_message.srcChainId, _message.bridgeName, _message.nonce, msg.sender);

        _executeMessage(_message, msgInfo);
    }

    /**
     * @notice Update bridge receiver adapters.
     * This function can only be called by _executeMessage() invoked within receiveMessage() of this contract,
     * which means the only party who can make these updates is the caller of the MultiBridgeSender at the source chain.
     */
    function updateReceiverAdapter(address[] calldata _receiverAdapters, uint32[] calldata _powers) external onlySelf {
        require(_receiverAdapters.length == _powers.length, "mismatch length");
        for (uint256 i = 0; i < _receiverAdapters.length; i++) {
            _updateReceiverAdapter(_receiverAdapters[i], _powers[i]);
        }
    }

    /**
     * @notice Update power quorum threshold of message execution.
     * This function can only be called by _executeMessage() invoked within receiveMessage() of this contract,
     * which means the only party who can make these updates is the caller of the MultiBridgeSender at the source chain.
     */
    function updateQuorumThreshold(uint64 _quorumThreshold) external onlySelf {
        require(_quorumThreshold <= THRESHOLD_DECIMAL, "invalid threshold");
        quorumThreshold = _quorumThreshold;
        emit QuorumThresholdUpdated(_quorumThreshold);
    }

    /**
     * @notice Compute message Id.
     * message.bridgeName is not included in the message id.
     */
    function getMsgId(MessageStruct.Message calldata _message) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _message.srcChainId,
                    _message.dstChainId,
                    _message.nonce,
                    _message.target,
                    _message.callData
                )
            );
    }

    /**
     * @notice Execute the message (invoke external call according to the message content) if the message
     * has reached the power threshold (the same message has been delivered by enough multiple bridges).
     */
    function _executeMessage(MessageStruct.Message calldata _message, MsgInfo storage _msgInfo) private {
        if (_msgInfo.executed) {
            return;
        }
        uint64 msgPower = _computeMessagePower(_msgInfo);
        if (msgPower >= (totalPower * quorumThreshold) / THRESHOLD_DECIMAL) {
            (bool ok, ) = _message.target.call(_message.callData);
            require(ok, "external message execution failed");
            _msgInfo.executed = true;
            emit MessageExecuted(_message.srcChainId, _message.nonce, _message.target, _message.callData);
        }
    }

    function _computeMessagePower(MsgInfo storage _msgInfo) private view returns (uint64) {
        uint64 msgPower;
        for (uint32 i = 0; i < receiverAdapters.length; i++) {
            address adapter = receiverAdapters[i];
            if (_msgInfo.from[adapter]) {
                msgPower += receiverAdapterPowers[adapter];
            }
        }
        return msgPower;
    }

    function _updateReceiverAdapter(address _receiverAdapter, uint32 _power) private {
        totalPower -= receiverAdapterPowers[_receiverAdapter];
        totalPower += _power;
        if (_power > 0) {
            _setReceiverAdapter(_receiverAdapter, _power);
        } else {
            _removeReceiverAdapter(_receiverAdapter);
        }
        emit ReceiverAdapterUpdated(_receiverAdapter, _power);
    }

    function _setReceiverAdapter(address _receiverAdapter, uint32 _power) private {
        require(_power > 0, "zero power");
        if (receiverAdapterPowers[_receiverAdapter] == 0) {
            receiverAdapters.push(_receiverAdapter);
        }
        receiverAdapterPowers[_receiverAdapter] = _power;
    }

    function _removeReceiverAdapter(address _receiverAdapter) private {
        require(receiverAdapterPowers[_receiverAdapter] > 0, "not a receiver adapter");
        uint256 lastIndex = receiverAdapters.length - 1;
        for (uint256 i = 0; i < receiverAdapters.length; i++) {
            if (receiverAdapters[i] == _receiverAdapter) {
                if (i < lastIndex) {
                    receiverAdapters[i] = receiverAdapters[lastIndex];
                }
                receiverAdapters.pop();
                receiverAdapterPowers[_receiverAdapter] = 0;
                return;
            }
        }
        revert("receiver adapter not found"); // this should never happen
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "../MessageStruct.sol";

interface IMultiBridgeReceiver {
    /**
     * @notice Receive messages from allowed bridge receiver adapters.
     * If the accumulated power of a message has reached the power threshold,
     * this message will be executed immediately, which will invoke an external function call
     * according to the message content.
     *
     * @dev Every receiver adapter should call this function with decoded MessageStruct.Message
     * when receiver adapter receives a message produced by a corresponding sender adapter on the source chain.
     */
    function receiveMessage(MessageStruct.Message calldata _message) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}