// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {AbacusConnectionClient} from "./base/AbacusConnectionClient.sol";
import {IMessageRecipient} from "@abacus-network/core/interfaces/IMessageRecipient.sol";
import {TypeCasts} from "@abacus-network/core/contracts/libs/TypeCasts.sol";
import "../interfaces/IAxelarGateway.sol";
import "../structures/CrossChainMessage.sol";

import "./base/CCMPAdaptorBase.sol";

error HyperlaneAdapterDestinationChainUnsupported(uint256 chainId);
error InvalidOriginChain(uint256 chainId);
error InvalidSender(address sender, uint256 chainId);

/// @title Hyperlane Adaptor
/// @author [email protected]
/// @notice Adaptor for the abacus protocol into the CCMP System
contract HyperlaneAdaptor is
    AbacusConnectionClient,
    CCMPAdaptorBase,
    IMessageRecipient
{
    using CCMPMessageUtils for CCMPMessage;

    event DomainIdUpdated(uint256 indexed chainId, uint32 indexed newDomainId);
    event HyperlaneMessageRouted(uint256 indexed messageId);
    event HyperlaneMessageVerified(
        bytes32 indexed ccmpMessageHash,
        uint32 indexed origin,
        uint256 indexed sourceChainId,
        address sender
    );
    event HyperlaneAdaptorUpdated(
        uint256 indexed chainId,
        address indexed newAbacusAdaptor
    );

    // Hyperlane Domain ID to Chain ID
    mapping(uint256 => uint32) public chainIdToDomainId;
    mapping(uint32 => uint256) public domainIdToChainId;

    // Whether a message has been verified or not
    mapping(bytes32 => bool) public messageHashVerified;

    // Hyperlane Adaptor Mapping from other chains
    mapping(uint256 => address) public chainIdToHyperlaneAdaptor;

    constructor(
        address _ccmpGateway,
        address _owner,
        address _pauser,
        address _abacusConnectionManager,
        address _interchainGasPaymaster
    )
        CCMPAdaptorBase(_ccmpGateway, _owner, _pauser)
        AbacusConnectionClient(
            _abacusConnectionManager,
            _interchainGasPaymaster
        )
    {
        if (_ccmpGateway == address(0)) {
            revert InvalidAddress("ccmpGateway", _ccmpGateway);
        }
        if (_pauser == address(0)) {
            revert InvalidAddress("pauser", _pauser);
        }
        if (_abacusConnectionManager == address(0)) {
            revert InvalidAddress(
                "abacusConnectionManager",
                _abacusConnectionManager
            );
        }
        if (_interchainGasPaymaster == address(0)) {
            revert InvalidAddress(
                "interchainGasPaymaster",
                _interchainGasPaymaster
            );
        }
        // Initialize default domain IDs: https://docs.useabacus.network/abacus-docs/developers/domains
        // Testnet
        _updateDomainId(44787, 1000);
        _updateDomainId(421611, 0x61722d72);
        _updateDomainId(97, 0x62732d74);
        _updateDomainId(43113, 43113);
        _updateDomainId(5, 5);
        _updateDomainId(42, 3000);
        _updateDomainId(80001, 80001);
        _updateDomainId(69, 0x6f702d6b);

        // Mainnet
        _updateDomainId(42161, 0x617262);
        _updateDomainId(43114, 0x61766178);
        _updateDomainId(56, 0x627363);
        _updateDomainId(42220, 0x63656c6f);
        _updateDomainId(1, 0x657468);
        _updateDomainId(10, 0x6f70);
        _updateDomainId(137, 0x706f6c79);
    }

    /// @notice Called by Abacus's Inbox Contract (onlyInbox) to verify a inbound CCMP Message
    /// @param _origin The origin domain ID
    /// @param _sender The sender contract on the source chain
    /// @param _message The message to be verified
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external onlyInbox {
        // Check if the source chain is registered
        uint256 originChainId = domainIdToChainId[_origin];
        if (originChainId == 0 || originChainId == block.chainid) {
            revert InvalidOriginChain(_origin);
        }

        // Ensure that the message is sent by the Abacus Adaptor on the source chain
        address sender = TypeCasts.bytes32ToAddress(_sender);
        if (sender != chainIdToHyperlaneAdaptor[originChainId]) {
            revert InvalidSender(sender, originChainId);
        }

        bytes32 ccmpMessageHash = abi.decode(_message, (bytes32));
        messageHashVerified[ccmpMessageHash] = true;

        emit HyperlaneMessageVerified(
            ccmpMessageHash,
            _origin,
            originChainId,
            sender
        );
    }

    /// @notice Called by the CCMP Gateway to route a message via Abacus
    /// @param _message The message to be routed
    function routePayload(
        CCMPMessage calldata _message,
        bytes calldata
    ) external nonReentrant whenNotPaused onlyCCMPGateway {
        uint32 destinationChainDomainId = chainIdToDomainId[
            _message.destinationChainId
        ];
        address destinationRouterAddress = chainIdToHyperlaneAdaptor[
            _message.destinationChainId
        ];

        if (
            destinationChainDomainId == 0 ||
            destinationRouterAddress == address(0)
        ) {
            revert HyperlaneAdapterDestinationChainUnsupported(
                _message.destinationChainId
            );
        }

        bytes32 destinationRouterAddressEncoded = TypeCasts.addressToBytes32(
            chainIdToHyperlaneAdaptor[_message.destinationChainId]
        );

        uint256 messageId = _outbox().dispatch(
            destinationChainDomainId,
            destinationRouterAddressEncoded,
            abi.encode(_message.hash())
        );

        emit HyperlaneMessageRouted(messageId);
    }

    /// @notice Called by the CCMP Gateway to verify a message routed via Abacus
    /// @param _ccmpMessage The message to be verified
    /// @return status Whether the message is verified or not
    /// @return message Message/Error string
    function verifyPayload(
        CCMPMessage calldata _ccmpMessage,
        bytes calldata
    ) external view virtual whenNotPaused returns (bool, string memory) {
        return
            messageHashVerified[_ccmpMessage.hash()]
                ? (true, "")
                : (false, "ERR__MESSAGE_NOT_VERIFIED");
    }

    function _updateDomainId(uint256 _chainId, uint32 _domainId) internal {
        chainIdToDomainId[_chainId] = _domainId;
        domainIdToChainId[_domainId] = _chainId;
        emit DomainIdUpdated(_chainId, _domainId);
    }

    function updateDomainId(
        uint256 _chainId,
        uint32 _domainId
    ) external onlyOwner {
        _updateDomainId(_chainId, _domainId);
    }

    function updateDomainIdBatch(
        uint256[] calldata _chainIds,
        uint32[] calldata _domainIds
    ) external onlyOwner {
        if (_chainIds.length != _domainIds.length) {
            revert ParameterArrayLengthMismatch();
        }
        uint256 length = _chainIds.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                _updateDomainId(_chainIds[i], _domainIds[i]);
            }
        }
    }

    function _setHyperlaneAdaptor(
        uint256 _chainId,
        address _hyperlaneAdaptor
    ) internal {
        chainIdToHyperlaneAdaptor[_chainId] = _hyperlaneAdaptor;
        emit HyperlaneAdaptorUpdated(_chainId, _hyperlaneAdaptor);
    }

    function setHyperlaneAdaptor(
        uint256 _chainId,
        address _hyperlaneAdaptor
    ) external onlyOwner {
        _setHyperlaneAdaptor(_chainId, _hyperlaneAdaptor);
    }

    function setHyperlaneAdaptorBatch(
        uint256[] calldata _chainIds,
        address[] calldata _hyperlaneAdaptors
    ) external onlyOwner {
        if (_chainIds.length != _hyperlaneAdaptors.length) {
            revert ParameterArrayLengthMismatch();
        }
        uint256 length = _chainIds.length;
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                _setHyperlaneAdaptor(_chainIds[i], _hyperlaneAdaptors[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

// ============ Internal Imports ============
import {IInterchainGasPaymaster} from "@abacus-network/core/interfaces/IInterchainGasPaymaster.sol";
import {IOutbox} from "@abacus-network/core/interfaces/IOutbox.sol";
import {IAbacusConnectionManager} from "@abacus-network/core/interfaces/IAbacusConnectionManager.sol";

// ============ External Imports ============
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AbacusConnectionClient is Ownable {
    // ============ Mutable Storage ============

    IAbacusConnectionManager public abacusConnectionManager;
    // Interchain Gas Paymaster contract. The relayer associated with this contract
    // must be willing to relay messages dispatched from the current Outbox contract,
    // otherwise payments made to the paymaster will not result in relayed messages.
    IInterchainGasPaymaster public interchainGasPaymaster;

    // ============ Events ============

    /**
     * @notice Emitted when a new abacusConnectionManager is set.
     * @param abacusConnectionManager The address of the abacusConnectionManager contract
     */
    event AbacusConnectionManagerSet(address indexed abacusConnectionManager);

    /**
     * @notice Emitted when a new Interchain Gas Paymaster is set.
     * @param interchainGasPaymaster The address of the Interchain Gas Paymaster.
     */
    event InterchainGasPaymasterSet(address indexed interchainGasPaymaster);

    // ============ Modifiers ============

    /**
     * @notice Only accept messages from an Abacus Inbox contract
     */
    modifier onlyInbox() {
        require(_isInbox(msg.sender), "!inbox");
        _;
    }

    // ======== Initializer =========

    function __AbacusConnectionClient_initialize(
        address _abacusConnectionManager
    ) internal {
        _setAbacusConnectionManager(_abacusConnectionManager);
    }

    constructor(
        address _abacusConnectionManager,
        address _interchainGasPaymaster
    ) Ownable() {
        _setInterchainGasPaymaster(_interchainGasPaymaster);
        __AbacusConnectionClient_initialize(_abacusConnectionManager);
    }

    // ============ External functions ============

    /**
     * @notice Sets the address of the application's AbacusConnectionManager.
     * @param _abacusConnectionManager The address of the AbacusConnectionManager contract.
     */
    function setAbacusConnectionManager(address _abacusConnectionManager)
        external
        virtual
        onlyOwner
    {
        _setAbacusConnectionManager(_abacusConnectionManager);
    }

    /**
     * @notice Sets the address of the application's InterchainGasPaymaster.
     * @param _interchainGasPaymaster The address of the InterchainGasPaymaster contract.
     */
    function setInterchainGasPaymaster(address _interchainGasPaymaster)
        external
        virtual
        onlyOwner
    {
        _setInterchainGasPaymaster(_interchainGasPaymaster);
    }

    // ============ Internal functions ============

    /**
     * @notice Sets the address of the application's InterchainGasPaymaster.
     * @param _interchainGasPaymaster The address of the InterchainGasPaymaster contract.
     */
    function _setInterchainGasPaymaster(address _interchainGasPaymaster)
        internal
    {
        interchainGasPaymaster = IInterchainGasPaymaster(
            _interchainGasPaymaster
        );
        emit InterchainGasPaymasterSet(_interchainGasPaymaster);
    }

    /**
     * @notice Modify the contract the Application uses to validate Inbox contracts
     * @param _abacusConnectionManager The address of the abacusConnectionManager contract
     */
    function _setAbacusConnectionManager(address _abacusConnectionManager)
        internal
    {
        abacusConnectionManager = IAbacusConnectionManager(
            _abacusConnectionManager
        );
        emit AbacusConnectionManagerSet(_abacusConnectionManager);
    }

    /**
     * @notice Get the local Outbox contract from the abacusConnectionManager
     * @return The local Outbox contract
     */
    function _outbox() internal view returns (IOutbox) {
        return abacusConnectionManager.outbox();
    }

    /**
     * @notice Determine whether _potentialInbox is an enrolled Inbox from the abacusConnectionManager
     * @return True if _potentialInbox is an enrolled Inbox
     */
    function _isInbox(address _potentialInbox) internal view returns (bool) {
        return abacusConnectionManager.isInbox(_potentialInbox);
    }

    /**
     * @notice Get the local domain from the abacusConnectionManager
     * @return The local domain
     */
    function _localDomain() internal view virtual returns (uint32) {
        return abacusConnectionManager.localDomain();
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf)
        internal
        pure
        returns (string memory _newStr)
    {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenDailyMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function tokenDailyMintLimit(string memory symbol) external view returns (uint256);

    function tokenDailyMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenDailyMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/ICCMPGateway.sol";
import "../interfaces/ICCMPRouterAdaptor.sol";

struct CCMPMessagePayload {
    address to;
    bytes _calldata;
}

struct GasFeePaymentArgs {
    address feeTokenAddress;
    uint256 feeAmount;
    address relayer;
}

/*
    {
        "sender": "0xUSER",
        "sourceGateway": "0xGATEWAY",
        "sourceAdaptor": "0xADAPTOR",
        "sourceChainId: 80001,
        "destinationChainGateway": "0xGATEWAY2",
        "destinationChainId": "1",
        "nonce": 1,
        "routerAdaptor": "wormhole",
        "gasFeePaymentArgs": GasFeePaymentArgs,
        "payload": [
            {
                "to": 0xCONTRACT,
                "_calldata": "0xabc"
            }
        ]
    }
*/
struct CCMPMessage {
    address sender;
    ICCMPGateway sourceGateway;
    ICCMPRouterAdaptor sourceAdaptor;
    uint256 sourceChainId;
    ICCMPGateway destinationGateway;
    uint256 destinationChainId;
    uint256 nonce;
    string routerAdaptor;
    GasFeePaymentArgs gasFeePaymentArgs;
    CCMPMessagePayload[] payload;
}

library CCMPMessageUtils {
    function hash(CCMPMessage memory message) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    message.sender,
                    address(message.sourceGateway),
                    address(message.sourceAdaptor),
                    message.sourceChainId,
                    address(message.destinationGateway),
                    message.destinationChainId,
                    message.nonce,
                    message.routerAdaptor,
                    message.gasFeePaymentArgs.feeTokenAddress,
                    message.gasFeePaymentArgs.feeAmount,
                    message.gasFeePaymentArgs.relayer,
                    message.payload
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../interfaces/ICCMPRouterAdaptor.sol";
import "../../interfaces/IAxelarGateway.sol";
import "../../interfaces/ICCMPGateway.sol";
import "../../structures/CrossChainMessage.sol";
import "../../security/Pausable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title CCMPAdaptorBase
/// @author [email protected]
/// @notice Base contract for all CCMP Adaptors
abstract contract CCMPAdaptorBase is
    Ownable,
    ReentrancyGuard,
    PausableBase,
    ICCMPRouterAdaptor
{
    ICCMPGateway public ccmpGateway;

    modifier onlyCCMPGateway() {
        if (_msgSender() != address(ccmpGateway)) {
            revert CallerIsNotCCMPGateway();
        }
        _;
    }

    constructor(
        address _ccmpGateway,
        address _owner,
        address _pauser
    ) PausableBase(_pauser) {
        ccmpGateway = ICCMPGateway(_ccmpGateway);
        _transferOwnership(_owner);
    }

    function setCCMPGateway(
        ICCMPGateway _ccmpGateway
    ) external whenNotPaused onlyOwner {
        ccmpGateway = _ccmpGateway;
        emit CCMPGatewayUpdated(ccmpGateway);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payGasFor(
        address _outbox,
        uint256 _leafIndex,
        uint32 _destinationDomain
    ) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IMailbox} from "./IMailbox.sol";

interface IOutbox is IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (uint256);

    function cacheCheckpoint() external;

    function latestCheckpoint() external view returns (bytes32, uint256);

    function count() external returns (uint256);

    function fail() external;

    function cachedCheckpoints(bytes32) external view returns (uint256);

    function latestCachedCheckpoint()
        external
        view
        returns (bytes32 root, uint256 index);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

import {IOutbox} from "./IOutbox.sol";

interface IAbacusConnectionManager {
    function outbox() external view returns (IOutbox);

    function isInbox(address _inbox) external view returns (bool);

    function localDomain() external view returns (uint32);
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMailbox {
    function localDomain() external view returns (uint32);
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
pragma solidity ^0.8.0;

import "../structures/CrossChainMessage.sol";
import "./ICCMPRouterAdaptor.sol";
import "./ICCMPExecutor.sol";

interface ICCMPGatewayBase {
    error UnsupportedAdapter(string adaptorName);
}

interface ICCMPGatewaySender is ICCMPGatewayBase {
    // Errors
    error UnsupportedDestinationChain(uint256 destinationChainId);
    error InvalidPayload(string reason);
    error AmountIsZero();
    error NativeAmountMismatch();
    error NativeTransferFailed(address relayer, bytes data);
    error AmountExceedsBalance(uint256 _amount, uint256 balance);
    error InsufficientNativeAmount(
        uint256 requiredAmount,
        uint256 actualAmount
    );

    // Events
    event CCMPMessageRouted(
        bytes32 indexed hash,
        address indexed sender,
        ICCMPGateway sourceGateway,
        ICCMPRouterAdaptor sourceAdaptor,
        uint256 sourceChainId,
        ICCMPGateway destinationGateway,
        uint256 indexed destinationChainId,
        uint256 nonce,
        string routerAdaptor,
        GasFeePaymentArgs gasFeePaymentArgs,
        CCMPMessagePayload[] payload
    );
    event FeePaid(
        address indexed _tokenAddress,
        uint256 indexed _amount,
        address indexed _relayer
    );

    // Functions
    function sendMessage(
        uint256 _destinationChainId,
        string calldata _adaptorName,
        CCMPMessagePayload[] calldata _payloads,
        GasFeePaymentArgs calldata _gasFeePaymentArgs,
        bytes calldata _routerArgs
    ) external payable returns (bool sent);

    function getGasFeePaymentDetails(
        bytes32 _messageHash,
        address[] calldata _tokens
    ) external view returns (uint256[] memory balances);

    /// @notice Handles fee payment
    function addGasFee(
        GasFeePaymentArgs memory _args,
        bytes32 _messageHash,
        address _sender
    ) external payable;
}

interface ICCMPGatewayReceiver is ICCMPGatewayBase {
    // Errors
    error InvalidSource(uint256 sourceChainId, ICCMPGateway sourceGateway);
    error WrongDestination(
        uint256 destinationChainId,
        ICCMPGateway destinationGateway
    );
    error AlreadyExecuted(uint256 nonce);
    error VerificationFailed(string reason);
    error ExternalCallFailed(
        uint256 index,
        address contractAddress,
        bytes returndata
    );

    // Events
    event CCMPMessageExecuted(
        bytes32 indexed hash,
        address indexed sender,
        ICCMPGateway sourceGateway,
        ICCMPRouterAdaptor sourceAdaptor,
        uint256 sourceChainId,
        ICCMPGateway destinationGateway,
        uint256 indexed destinationChainId,
        uint256 nonce,
        string routerAdaptor,
        GasFeePaymentArgs gasFeePaymentArgs,
        CCMPMessagePayload[] payload
    );

    event CCMPPayloadExecuted(
        uint256 indexed index,
        address indexed contractAddress,
        bool success,
        bytes returndata
    );

    // Functions
    function receiveMessage(
        CCMPMessage calldata _message,
        bytes calldata _verificationData,
        bool _allowPartialCompletion
    ) external returns (bool received);
}

interface ICCMPConfiguration {
    error ParameterArrayLengthMismatch();

    // Events
    event GatewayUpdated(
        uint256 indexed destinationChainId,
        ICCMPGateway indexed gateway
    );
    event CCMPExecutorUpdated(ICCMPExecutor indexed _ccmpExecutor);
    event AdaptorUpdated(string indexed adaptorName, address indexed adaptor);
    event ContractPaused();
    event ContractUnpaused();
    event PauserUpdated(address indexed pauser);

    // Functions
    function setGateway(uint256 _chainId, ICCMPGateway _gateway) external;

    function setRouterAdaptor(
        string calldata name,
        ICCMPRouterAdaptor adaptor
    ) external;

    function setGatewayBatch(
        uint256[] calldata _chainId,
        ICCMPGateway[] calldata _gateway
    ) external;

    function setRouterAdaptorBatch(
        string[] calldata names,
        ICCMPRouterAdaptor[] calldata adaptors
    ) external;

    function setCCMPExecutor(ICCMPExecutor _ccmpExecutor) external;

    function setPauser(address _pauser) external;

    function gateway(
        uint256 _chainId
    ) external view returns (ICCMPGateway gateway_);

    function routerAdaptor(
        string calldata name
    ) external view returns (ICCMPRouterAdaptor adaptor);

    function ccmpExecutor() external view returns (ICCMPExecutor executor);

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);

    function pauser() external view returns (address pauser_);

    function pause() external;

    function unpause() external;
}

interface ICCMPGateway is
    ICCMPGatewaySender,
    ICCMPGatewayReceiver,
    ICCMPConfiguration
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structures/CrossChainMessage.sol";
import "./ICCMPGateway.sol";

interface ICCMPRouterAdaptor {
    error CallerIsNotCCMPGateway();
    error InvalidAddress(string parameterName, address value);
    error ParameterArrayLengthMismatch();

    event CCMPGatewayUpdated(ICCMPGateway indexed newCCMPGateway);

    function verifyPayload(
        CCMPMessage calldata _ccmpMessage,
        bytes calldata _verificationData
    ) external returns (bool, string memory);

    function routePayload(
        CCMPMessage calldata _ccmpMessage,
        bytes calldata _routeArgs
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICCMPExecutor {
    function execute(address _to, bytes calldata _calldata)
        external
        returns (bool success, bytes memory returndata);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableBase is Pausable {
    address private _pauser;

    event PauserChanged(
        address indexed previousPauser,
        address indexed newPauser
    );

    constructor(address pauser) Pausable() {
        require(pauser != address(0), "Pauser Address cannot be 0");
        _pauser = pauser;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isPauser(address pauser) public view returns (bool) {
        return pauser == _pauser;
    }

    /**
     * @return address Address of Pauser
     */
    function getPauser() external view returns (address) {
        return _pauser;
    }

    /**
     * @dev Throws if called by any account other than the pauser.
     */
    modifier onlyPauser() {
        require(
            isPauser(msg.sender),
            "Only pauser is allowed to perform this operation"
        );
        _;
    }

    /**
     * @dev Allows the current pauser to transfer control of the contract to a newPauser.
     * @param newPauser The address to transfer pauserShip to.
     */
    function changePauser(address newPauser) external onlyPauser whenNotPaused {
        _changePauser(newPauser);
    }

    /**
     * @dev Transfers control of the contract to a newPauser.
     * @param newPauser The address to transfer ownership to.
     */
    function _changePauser(address newPauser) internal {
        require(newPauser != address(0));
        emit PauserChanged(_pauser, newPauser);
        _pauser = newPauser;
    }

    function renouncePauser() external virtual onlyPauser whenNotPaused {
        emit PauserChanged(_pauser, address(0));
        _pauser = address(0);
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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