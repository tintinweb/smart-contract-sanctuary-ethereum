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

// SPDX-License-Identifier: MIT

import "../framework/SynMessagingReceiver.sol";

pragma solidity 0.8.13;

/** @title Example app of sending multiple messages in one transaction
 */

contract BatchMessageSender is SynMessagingReceiver {
    constructor(address _messageBus) {
        messageBus = _messageBus;
    }

    function sendMultipleMessages(bytes32[] memory _receiver, uint256[] memory _dstChainId, bytes[] memory _message, bytes[] memory _options) public payable {
        require(_receiver.length == _dstChainId.length);
        require(_receiver.length == _message.length);
        require(_receiver.length == _options.length);

        uint256 feePerMessage = msg.value / _message.length;

        // Care for block gas limit
        for (uint16 i = 0; i < _message.length; i++) {
            require(trustedRemoteLookup[_dstChainId[i]] != bytes32(0), "Receiver not trusted remote");
            IMessageBus(messageBus).sendMessage{value: feePerMessage}(_receiver[i], _dstChainId[i], _message[i], _options[i]);
        }
    }

    function _handleMessage(bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes memory _message,
        address _executor) internal override returns (MsgExecutionStatus) {
            return MsgExecutionStatus.Success;
        }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interfaces/ISynMessagingReceiver.sol";
import "../interfaces/IMessageBus.sol";
import "@openzeppelin/contracts-4.5.0/access/Ownable.sol";

abstract contract SynMessagingReceiver is ISynMessagingReceiver, Ownable {
    
    address public messageBus;

    // Maps chain ID to the bytes32 trusted addresses allowed to be source senders
    mapping(uint256 => bytes32) internal trustedRemoteLookup;

    event SetTrustedRemote(uint256 _srcChainId, bytes32 _srcAddress);


    /**
     * @notice Executes a message called by MessageBus (MessageBusReceiver)
     * @dev Must be called by MessageBug & sent from src chain by a trusted srcApp
     * @param _srcAddress The bytes32 address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     * @return status Enum containing options of Success, Fail, Retry
     */
    function executeMessage(
        bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external returns (MsgExecutionStatus) {
        // Must be called by the MessageBus/MessageBus for security
        require(msg.sender == messageBus, "caller is not message bus");
        // Must also be from a trusted source app
        require(_srcAddress == trustedRemoteLookup[_srcChainId], "Invalid source sending app");

        return _handleMessage(_srcAddress, _srcChainId, _message, _executor);
    }

    // Logic here handling messsage contents
    function _handleMessage(bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes memory _message,
        address _executor) internal virtual returns (MsgExecutionStatus);


    function _send(bytes32 _receiver,
        uint256 _dstChainId,
        bytes memory _message,
        bytes memory _options) internal virtual {
            require(trustedRemoteLookup[_dstChainId] != bytes32(0), "Receiver not trusted remote");
            IMessageBus(messageBus).sendMessage{value: msg.value}(_receiver, _dstChainId, _message, _options);
    }

    //** Config Functions */
    function setMessageBus(address _messageBus) public onlyOwner {
        messageBus = _messageBus;
    }

     // allow owner to set trusted addresses allowed to be source senders
    function setTrustedRemote(uint256 _srcChainId, bytes32 _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    //** View functions */
    function getTrustedRemote(uint256 _chainId) external view returns (bytes32 trustedRemote) {
        return trustedRemoteLookup[_chainId];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMessageBus {
    
    /**
     * @notice Sends a message to a receiving contract address on another chain. 
     * Sender must make sure that the message is unique and not a duplicate message.
     * @param _receiver The bytes32 address of the destination contract to be called
     * @param _dstChainId The destination chain ID - typically, standard EVM chain ID, but differs on nonEVM chains
     * @param _message The arbitrary payload to pass to the destination chain receiver
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits
     */
    function sendMessage(
        bytes32 _receiver,
        uint256 _dstChainId,
        bytes calldata _message,
        bytes calldata _options
    ) external payable;

    /**
     * @notice Relayer executes messages through an authenticated method to the destination receiver
     based on the originating transaction on source chain
     * @param _srcChainId Originating chain ID - typically a standard EVM chain ID, but may refer to a Synapse-specific chain ID on nonEVM chains
     * @param _srcAddress Originating bytes address of the message sender on the srcChain
     * @param _dstAddress Destination address that the arbitrary message will be passed to
     * @param _gasLimit Gas limit to be passed alongside the message, depending on the fee paid on srcChain
     * @param _message Arbitrary message payload to pass to the destination chain receiver
     */
    function executeMessage(
        uint256 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint256 _gasLimit,
        uint256 _nonce,
        bytes calldata _message
    ) external;


    /**
     * @notice Returns srcGasToken fee to charge in wei for the cross-chain message based on the gas limit
     * @param _options Versioned struct used to instruct relayer on how to proceed with gas limits. Contains data on gas limit to submit tx with.
     */
    function estimateFee(uint256 _dstChainId, bytes calldata _options)
        external
        returns (uint256);

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     */
    function withdrawFee(
        address _account
    ) external;



}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISynMessagingReceiver {

    // Maps chain ID to the bytes32 trusted addresses allowed to be source senders
    // mapping(uint256 => bytes32) internal trustedRemoteLookup;


    /** 
     * @notice MsgExecutionStatus state
     * @return Success execution succeeded, finalized
     * @return Fail // execution failed, finalized
     * @return Retry // execution failed or rejected, set to be retryable
    */ 
    enum MsgExecutionStatus {
        Success, 
        Fail
    }

     /**
     * @notice Called by MessageBus 
     * @dev MUST be permissioned to trusted source apps via trustedRemote
     * @param _srcAddress The bytes32 address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        bytes32 _srcAddress,
        uint256 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external returns (MsgExecutionStatus);
}