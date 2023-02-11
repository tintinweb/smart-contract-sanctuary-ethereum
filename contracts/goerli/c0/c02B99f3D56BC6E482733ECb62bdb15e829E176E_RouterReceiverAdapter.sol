// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMultiBridgeReceiver.sol";
import "../interfaces/Router/IRouterGateway.sol";
import "../interfaces/Router/IRouterReceiver.sol";

contract RouterReceiverAdapter is Pausable, Ownable, IRouterReceiver {
    /* ========== STATE VARIABLES ========== */

    mapping(uint64 => address) public senderAdapters;
    IRouterGateway public immutable routerGateway;
    address public multiBridgeReceiver;

    /* ========== MODIFIERS ========== */

    modifier onlyRouterGateway() {
        require(msg.sender == address(routerGateway), "caller is not router gateway");
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    constructor(address _routerGateway) {
        routerGateway = IRouterGateway(_routerGateway);
    }

    /* ========== EXTERNAL METHODS ========== */

    // Called by the Router Gateway on destination chain to receive cross-chain messages.
    // srcContractAddress is the address of contract on the source chain where the request was intiated
    // The payload is abi.encode of (MessageStruct.Message).
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory, // srcChainId
        uint64 //srcChainType
    ) external override onlyRouterGateway whenNotPaused returns (bytes memory) {
        MessageStruct.Message memory message = abi.decode(payload, (MessageStruct.Message));
        require(toAddress(srcContractAddress) == senderAdapters[message.srcChainId], "not allowed message sender");
        IMultiBridgeReceiver(multiBridgeReceiver).receiveMessage(message);
        return "";
    }

    /* ========== ADMIN METHODS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateSenderAdapter(uint64[] calldata _srcChainIds, address[] calldata _senderAdapters)
        external
        onlyOwner
    {
        require(_srcChainIds.length == _senderAdapters.length, "mismatch length");
        for (uint256 i = 0; i < _srcChainIds.length; i++) {
            senderAdapters[_srcChainIds[i]] = _senderAdapters[i];
        }
    }

    function setMultiBridgeReceiver(address _multiBridgeReceiver) external onlyOwner {
        multiBridgeReceiver = _multiBridgeReceiver;
    }

    /* ========== UTILS METHODS ========== */

    function toAddress(bytes memory _bytes) internal pure returns (address contractAddress) {
        bytes20 srcTokenAddress;
        assembly {
            srcTokenAddress := mload(add(_bytes, 0x20))
        }
        contractAddress = address(srcTokenAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Utils {
    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }
}

interface IRouterGateway {
    /// @notice Function to send a message to the destination chain
    /// @param expTimestamp the timestamp when the request ceases to be valid. If this timestamp has
    /// passed by, the request will fail on the destination chain.
    /// @param isAtomicCalls boolean value suggesting whether the calls are atomic. If true, either all the
    /// calls will be executed or none will be executed on the destination chain. If false, even if some calls
    /// fail, others will not be affected.
    /// @param ackType type of acknowledgement you want: ACK_ON_SUCCESS, ACK_ON_ERR, ACK_ON_BOTH.
    /// @param ackGasParams This includes the gas limit required for the execution of handler function for
    /// crosstalk acknowledgement on the source chain and the gas price of the source chain.
    /// @param destChainParams dest chain params include the destChainType, destChainId, the gas limit
    /// required to execute handler function on the destination chain and the gas price of destination chain.
    /// @param contractCalls Array of struct ContractCalls containing the multiple payloads to be sent to multiple
    /// contract addresses (in bytes format) on the destination chain.
    /// @return Returns the nonce from the gateway contract.
    function requestToDest(
        uint64 expTimestamp,
        bool isAtomicCalls,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    /// @notice Function to fetch the fees for cross-chain message transfer.
    /// @return fees
    function requestToDestDefaultFee() external view returns (uint256 fees);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Router Receiver Interface.
 */
interface IRouterReceiver {
    /// @notice Function to handle incoming cross-chain message.
    /// @param srcContractAddress address of contract on source chain where the request was initiated.
    /// @param payload abi encoded message sent from the source chain.
    /// @param srcChainId chainId of the source chain.
    /// @param srcChainType chainType of the source chain (0 for EVM).
    /// @return return value
    function handleRequestFromSource(
        bytes memory srcContractAddress,
        bytes memory payload,
        string memory srcChainId,
        uint64 srcChainType
    ) external returns (bytes memory);
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