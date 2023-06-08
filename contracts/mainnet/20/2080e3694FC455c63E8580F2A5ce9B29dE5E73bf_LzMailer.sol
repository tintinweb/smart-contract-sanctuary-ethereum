// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IZKBridgeEntrypoint.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mailer
/// @notice An example contract for sending messages to other chains, using the ZKBridgeEntrypoint.
contract LzMailer is Ownable {
    /// @notice The ZKBridgeEntrypoint contract, which sends messages to other chains.
    IZKBridgeEntrypoint public zkBridgeEntrypoint;

    ILayerZeroEndpoint public immutable lzEndpoint;

    bool public zkBridgePaused = false;
    bool public layerZeroPaused = false;

    uint256 public maxLength = 200;

    /// @notice Fee for each chain.
    mapping(uint16 => uint256) public fees;

    event MessageSend(
        uint64 indexed sequence,
        uint32 indexed dstChainId,
        address indexed dstAddress,
        address sender,
        address recipient,
        string message
    );

    event LzMessageSend(
        uint64 indexed sequence,
        uint32 indexed dstChainId,
        address indexed dstAddress,
        address sender,
        address recipient,
        string message
    );
    event NewFee(uint16 chainId, uint256 fee);
    /// @notice Event emitted when an action is paused/unpaused
    event PauseSendAction(
        address account,
        bool zkBridgePaused,
        bool layerZeroPaused
    );

    constructor(address _zkBridgeEntrypoint, address _lzEndpoint) {
        zkBridgeEntrypoint = IZKBridgeEntrypoint(_zkBridgeEntrypoint);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    /// @notice Sends a message to a destination MessageBridge.
    /// @param dstChainId The chain ID where the destination MessageBridge.
    /// @param dstAddress The address of the destination MessageBridge.
    /// @param recipient Recipient of the target chain message.
    /// @param message The message to send.
    function sendMessage(
        uint16 dstChainId,
        address dstAddress,
        uint16 lzChainId,
        address lzDstAddress,
        uint256 nativeFee,
        address recipient,
        string memory message
    ) external payable {
        if (layerZeroPaused && zkBridgePaused) {
            revert("Nothing to do");
        }

        uint256 zkFee = fees[dstChainId];
        if (zkBridgePaused) {
            zkFee = 0;
        }

        if (layerZeroPaused) {
            require(nativeFee == 0, "Invalid native fee");
        }
        require(msg.value >= nativeFee + zkFee, "Insufficient Fee");
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );

        if (!zkBridgePaused) {
            _sendMessage(dstChainId, dstAddress, recipient, message);
        }

        if (!layerZeroPaused) {
            _sendToLayerZero(
                lzChainId,
                lzDstAddress,
                recipient,
                nativeFee,
                message
            );
        }
    }

    function zkSendMessage(
        uint16 dstChainId,
        address dstAddress,
        address recipient,
        string memory message
    ) external payable {
        if (zkBridgePaused) {
            revert("Paused");
        }
        require(msg.value >= fees[dstChainId], "Insufficient Fee");
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );

        _sendMessage(dstChainId, dstAddress, recipient, message);
    }

    function lzSendMessage(
        uint16 lzChainId,
        address lzDstAddress,
        address recipient,
        string memory message
    ) external payable {
        if (layerZeroPaused) {
            revert("Paused");
        }
        require(
            bytes(message).length <= maxLength,
            "Maximum message length exceeded."
        );

        _sendToLayerZero(
            lzChainId,
            lzDstAddress,
            recipient,
            msg.value,
            message
        );
    }

    function _sendMessage(
        uint16 dstChainId,
        address dstAddress,
        address recipient,
        string memory message
    ) private {
        bytes memory payload = abi.encode(msg.sender, recipient, message);
        uint64 _sequence = zkBridgeEntrypoint.send(
            dstChainId,
            dstAddress,
            payload
        );
        emit MessageSend(
            _sequence,
            dstChainId,
            dstAddress,
            msg.sender,
            recipient,
            message
        );
    }

    function _sendToLayerZero(
        uint16 _dstChainId,
        address _dstAddress,
        address _recipient,
        uint256 _nativeFee,
        string memory _message
    ) private {
        bytes memory payload = abi.encode(msg.sender, _recipient, _message);
        bytes memory path = abi.encodePacked(_dstAddress, address(this));

        lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            path,
            payload,
            payable(msg.sender),
            msg.sender,
            bytes("")
        );

        uint64 _sequence = lzEndpoint.outboundNonce(_dstChainId, address(this));

        emit LzMessageSend(
            _sequence,
            _dstChainId,
            _dstAddress,
            msg.sender,
            _recipient,
            _message
        );
    }

    /// @notice Allows owner to set a new msg length.
    /// @param _maxLength new msg length.
    function setMsgLength(uint256 _maxLength) external onlyOwner {
        maxLength = _maxLength;
    }

    /// @notice Allows owner to claim all fees sent to this contract.
    /// @notice Allows owner to set a new fee.
    /// @param _dstChainId The chain ID where the destination MessageBridge.
    /// @param _fee The new fee to use.
    function setFee(uint16 _dstChainId, uint256 _fee) external onlyOwner {
        require(fees[_dstChainId] != _fee, "Fee has already been set.");
        fees[_dstChainId] = _fee;
        emit NewFee(_dstChainId, _fee);
    }

    /**
     * @notice Pauses different actions
     * @dev Changes the owner address.
     * @param zkBridgePaused_ Boolean for zkBridge send
     * @param layerZeroPaused_ Boolean for layer zero send
     */
    function pause(
        bool zkBridgePaused_,
        bool layerZeroPaused_
    ) external onlyOwner {
        zkBridgePaused = zkBridgePaused_;
        layerZeroPaused = layerZeroPaused_;
        emit PauseSendAction(msg.sender, zkBridgePaused, layerZeroPaused);
    }

    /// @notice Allows owner to claim all fees sent to this contract.
    function claimFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function estimateLzFee(
        uint16 _dstChainId,
        address _recipient,
        string memory _message
    ) public view returns (uint256 nativeFee) {
        if (layerZeroPaused) {
            return 0;
        }

        bytes memory payload = abi.encode(msg.sender, _recipient, _message);
        (nativeFee, ) = lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            bytes("")
        );
    }

    /**
     * @notice set the configuration of the LayerZero messaging library of the specified version
     * @param _version - messaging library version
     * @param _dstChainId - the chainId for the pending config change
     * @param _configType - type of configuration. every messaging library has its own convention.
     * @param _config - configuration in the bytes. can encode arbitrary content.
     */
    function setConfig(
        uint16 _version,
        uint16 _dstChainId,
        uint _configType,
        bytes calldata _config
    ) external onlyOwner {
        lzEndpoint.setConfig(_version, _dstChainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    /// @notice get the send() LayerZero messaging library version
    function getSendVersion() external view returns (uint16) {
        return lzEndpoint.getSendVersion(address(this));
    }

    /**
     * @notice get the configuration of the LayerZero messaging library of the specified version
     * @param _version - messaging library version
     * @param _dstChainId - the chainId for the pending config change
     * @param _configType - type of configuration. every messaging library has its own convention.
     */
    function getConfig(
        uint16 _version,
        uint16 _dstChainId,
        uint _configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                _version,
                _dstChainId,
                address(this),
                _configType
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(
        uint16 _dstChainId,
        address _srcAddress
    ) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(
        address _userApplication
    ) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(
        address _userApplication
    ) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(
        address _userApplication
    ) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(
        address _userApplication
    ) external view returns (uint16);

    function defaultSendLibrary() external view returns (address);

    function outboundNonce(
        uint16 _chainId,
        address _userApplication
    ) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZKBridgeEntrypoint {
    /// @notice send a ZKBridge message to the specified address at a ZKBridge endpoint.
    /// @param dstChainId - the destination chain identifier
    /// @param dstAddress - the address on destination chain
    /// @param payload - a custom bytes payload to send to the destination contract
    function send(
        uint16 dstChainId,
        address dstAddress,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    /// @return Current chain id.
    function chainId() external view returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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