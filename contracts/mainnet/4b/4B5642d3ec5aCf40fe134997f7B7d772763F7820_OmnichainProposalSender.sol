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
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

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
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";

/// @title Omnichain Governance Proposal Sender
/// @notice Sends a proposal's data to remote chains for execution after the proposal passes on the main chain
/// @dev When used with GovernorBravo the owner of this contract must be set to the Timelock contract
contract OmnichainProposalSender is Ownable, ReentrancyGuard {
    uint64 public lastStoredPayloadNonce;

    /// @notice Execution hashes of failed messages
    /// @dev [nonce] -> [executionHash]
    mapping(uint64 => bytes32) public storedExecutionHashes;

    /// @notice LayerZero endpoint for sending messages to remote chains
    ILayerZeroEndpoint public immutable lzEndpoint;

    /// @notice Specifies the allowed path for sending messages (remote chainId => remote app address + local app address)
    mapping(uint16 => bytes) public trustedRemoteLookup;

    /// @notice Emitted when a remote message receiver is set for the remote chain
    event SetTrustedRemoteAddress(uint16 remoteChainId, bytes remoteAddress);

    /// @notice Emitted when a proposal execution request sent to the remote chain
    event ExecuteRemoteProposal(uint16 indexed remoteChainId, bytes payload);

    /// @notice Emitted when a previously failed message successfully sent to the remote chain
    event ClearPayload(uint64 indexed nonce, bytes32 executionHash);

    /// @notice Emitted when an execution hash of a failed message saved
    event StorePayload(uint64 indexed nonce, uint16 indexed remoteChainId, bytes payload, bytes adapterParams, uint value, bytes reason);

    constructor(ILayerZeroEndpoint _lzEndpoint) {
        require(address(_lzEndpoint) != address(0), "OmnichainProposalSender: invalid endpoint");
        lzEndpoint = _lzEndpoint;
    }

    /// @notice Estimates LayerZero fees for cross-chain message delivery to the remote chain
    /// @dev The estimated fees are the minimum required, it's recommended to increase the fees amount when sending a message. The unused amount will be refunded
    /// @param remoteChainId The LayerZero id of a remote chain
    /// @param payload The payload to be sent to the remote chain. It's computed as follows payload = abi.encode(targets, values, signatures, calldatas)
    /// @param adapterParams The params used to specify the custom amount of gas required for the execution on the destination
    /// @return nativeFee The amount of fee in the native gas token (e.g. ETH)
    /// @return zroFee The amount of fee in ZRO token
    function estimateFees(uint16 remoteChainId, bytes calldata payload, bytes calldata adapterParams) external view returns (uint nativeFee, uint zroFee) {
        return lzEndpoint.estimateFees(remoteChainId, address(this), payload, false, adapterParams);
    }

    /// @notice Sends a message to execute a remote proposal
    /// @dev Stores the hash of the execution parameters if sending fails (e.g., due to insufficient fees)
    /// @param remoteChainId The LayerZero id of the remote chain
    /// @param payload The payload to be sent to the remote chain. It's computed as follows payload = abi.encode(targets, values, signatures, calldatas)
    /// @param adapterParams The params used to specify the custom amount of gas required for the execution on the destination
    function execute(uint16 remoteChainId, bytes calldata payload, bytes calldata adapterParams) external payable onlyOwner {
        bytes memory trustedRemote = trustedRemoteLookup[remoteChainId];
        require(trustedRemote.length != 0, "OmnichainProposalSender: destination chain is not a trusted source");

        try lzEndpoint.send{value: msg.value}(remoteChainId, trustedRemote, payload, payable(tx.origin), address(0), adapterParams){
            emit ExecuteRemoteProposal(remoteChainId, payload);  
        } catch (bytes memory reason) {
            uint64 _lastStoredPayloadNonce = ++lastStoredPayloadNonce;
            bytes memory execution = abi.encode(remoteChainId, payload, adapterParams, msg.value);
            storedExecutionHashes[_lastStoredPayloadNonce] = keccak256(execution);
            emit StorePayload(_lastStoredPayloadNonce, remoteChainId, payload, adapterParams, msg.value, reason);
        }
    }

    /// @notice Resends a previously failed message
    /// @dev Allows to provide more fees if needed. The extra fees will be refunded to the caller
    /// @param nonce The nonce to identify a failed message
    /// @param remoteChainId The LayerZero id of the remote chain
    /// @param payload The payload to be sent to the remote chain. It's computed as follows payload = abi.encode(targets, values, signatures, calldatas)
    /// @param adapterParams The params used to specify the custom amount of gas required for the execution on the destination
    /// @param originalValue The msg.value passed when execute() function was called
    function retryExecute(uint64 nonce, uint16 remoteChainId, bytes calldata payload, bytes calldata adapterParams, uint originalValue) external payable nonReentrant {
        bytes32 hash = storedExecutionHashes[nonce];
        require(hash != bytes32(0), "OmnichainProposalSender: no stored payload");

        bytes memory execution = abi.encode(remoteChainId, payload, adapterParams, originalValue);
        require(keccak256(execution) == hash, "OmnichainProposalSender: invalid execution params");

        delete storedExecutionHashes[nonce];

        lzEndpoint.send{value: originalValue + msg.value}(remoteChainId, trustedRemoteLookup[remoteChainId], payload, payable(msg.sender), address(0), adapterParams);
        emit ClearPayload(nonce, hash);
    }

    /// @notice Sets the remote message receiver address
    /// @param remoteChainId The LayerZero id of a remote chain
    /// @param remoteAddress The address of the contract on the remote chain to receive messages sent by this contract
    function setTrustedRemoteAddress(uint16 remoteChainId, bytes calldata remoteAddress) external onlyOwner {
        trustedRemoteLookup[remoteChainId] = abi.encodePacked(remoteAddress, address(this));
        emit SetTrustedRemoteAddress(remoteChainId, remoteAddress);
    }

    /// @notice Sets the configuration of the LayerZero messaging library of the specified version
    /// @param version Messaging library version
    /// @param chainId The LayerZero chainId for the pending config change
    /// @param configType The type of configuration. Every messaging library has its own convention
    /// @param config The configuration in bytes. It can encode arbitrary content
    function setConfig(uint16 version, uint16 chainId, uint configType, bytes calldata config) external onlyOwner {
        lzEndpoint.setConfig(version, chainId, configType, config);
    }

    /// @notice Sets the configuration of the LayerZero messaging library of the specified version
    /// @param version New messaging library version
    function setSendVersion(uint16 version) external onlyOwner {
        lzEndpoint.setSendVersion(version);
    }

    /// @notice Gets the configuration of the LayerZero messaging library of the specified version
    /// @param version Messaging library version
    /// @param chainId The LayerZero chainId
    /// @param configType Type of configuration. Every messaging library has its own convention.
    function getConfig(uint16 version, uint16 chainId, uint configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(version, chainId, address(this), configType);
    }
}