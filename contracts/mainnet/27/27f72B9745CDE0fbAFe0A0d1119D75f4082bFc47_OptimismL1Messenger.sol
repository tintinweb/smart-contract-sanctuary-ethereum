/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// The messenger interface.
///
/// Implementations of this interface are expected to transport
/// messages across the L1 <-> L2 boundary. For instance,
/// if an implementation is deployed on L1, the :sol:func:`sendMessage`
/// would send a message to a L2 chain, as determined by the implementation.
/// In order to do this, a messenger implementation may use a native
/// messenger contract. In such cases, :sol:func:`nativeMessenger` must
/// return the address of the native messenger contract.
interface IMessenger {
    /// Send a message across the L1 <-> L2 boundary.
    ///
    /// @param target The message recipient.
    /// @param message The message.
    function sendMessage(address target, bytes calldata message) external;

    /// Return whether the call is allowed or not.
    ///
    /// @param caller The caller.
    /// @param courier The contract that is trying to deliver the message.
    function callAllowed(address caller, address courier)
    external
    view
    returns (bool);
}


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



/// A helper contract that provides a way to restrict callers of restricted functions
/// to a single address. This allows for a trusted call chain,
/// as described in :ref:`contracts' architecture <contracts-architecture>`.
contract RestrictedCalls is Ownable {
    /// Maps caller chain IDs to tuples [caller, messenger].
    ///
    /// For same-chain calls, the messenger address is 0x0.
    mapping(uint256 => address[2]) public callers;

    function _addCaller(
        uint256 callerChainId,
        address caller,
        address messenger
    ) internal {
        require(caller != address(0), "RestrictedCalls: caller cannot be 0");
        require(
            callers[callerChainId][0] == address(0),
            "RestrictedCalls: caller already exists"
        );
        callers[callerChainId] = [caller, messenger];
    }

    /// Allow calls from an address on the same chain.
    ///
    /// @param caller The caller.
    function addCaller(address caller) external onlyOwner {
        _addCaller(block.chainid, caller, address(0));
    }

    /// Allow calls from an address on another chain.
    ///
    /// @param callerChainId The caller's chain ID.
    /// @param caller The caller.
    /// @param messenger The messenger.
    function addCaller(
        uint256 callerChainId,
        address caller,
        address messenger
    ) external onlyOwner {
        _addCaller(callerChainId, caller, messenger);
    }

    /// Mark the function as restricted.
    ///
    /// Calls to the restricted function can only come from an address that
    /// was previously added by a call to :sol:func:`addCaller`.
    ///
    /// Example usage::
    ///
    ///     restricted(block.chainid)   // expecting calls from the same chain
    ///     restricted(otherChainId)    // expecting calls from another chain
    ///
    modifier restricted(uint256 callerChainId) {
        address caller = callers[callerChainId][0];

        if (callerChainId == block.chainid) {
            require(msg.sender == caller, "RestrictedCalls: call disallowed");
        } else {
            address messenger = callers[callerChainId][1];
            require(
                messenger != address(0),
                "RestrictedCalls: messenger not set"
            );
            require(
                IMessenger(messenger).callAllowed(caller, msg.sender),
                "RestrictedCalls: call disallowed"
            );
        }
        _;
    }
}

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(address indexed target, address sender, bytes message, uint256 messageNonce, uint256 gasLimit);
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}
/**
 * @title Lib_PredeployAddresses
 */
library Lib_PredeployAddresses {
    address internal constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000000;
    address internal constant L1_MESSAGE_SENDER = 0x4200000000000000000000000000000000000001;
    address internal constant DEPLOYER_WHITELIST = 0x4200000000000000000000000000000000000002;
    address payable internal constant OVM_ETH = payable(0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000);
    address internal constant L2_CROSS_DOMAIN_MESSENGER =
    0x4200000000000000000000000000000000000007;
    address internal constant LIB_ADDRESS_MANAGER = 0x4200000000000000000000000000000000000008;
    address internal constant PROXY_EOA = 0x4200000000000000000000000000000000000009;
    address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
    address internal constant SEQUENCER_FEE_WALLET = 0x4200000000000000000000000000000000000011;
    address internal constant L2_STANDARD_TOKEN_FACTORY =
    0x4200000000000000000000000000000000000012;
    address internal constant L1_BLOCK_NUMBER = 0x4200000000000000000000000000000000000013;
}


abstract contract OptimismMessengerBase is IMessenger, RestrictedCalls {
    uint32 private constant MESSAGE_GAS_LIMIT = 1_000_000;

    ICrossDomainMessenger public nativeMessenger;

    function callAllowed(address caller, address courier)
        external
        view
        returns (bool)
    {
        return
            courier == address(nativeMessenger) &&
            caller == nativeMessenger.xDomainMessageSender();
    }

    function sendMessage(address target, bytes calldata message)
        external
        restricted(block.chainid)
    {
        nativeMessenger.sendMessage(target, message, MESSAGE_GAS_LIMIT);
    }
}

contract OptimismL1Messenger is OptimismMessengerBase {
    constructor(address messenger_) {
        nativeMessenger = ICrossDomainMessenger(messenger_);
    }
}

contract OptimismL2Messenger is OptimismMessengerBase {
    constructor() {
        nativeMessenger = ICrossDomainMessenger(
            Lib_PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER
        );
    }
}