// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PhatRollupAnchor.sol";
import "./Interfaces.sol";

/// A Phat Contract Rollup Anchor with a built-in request queue
///
/// Call `pushRequest(data)` to push the raw message to the Phat Contract. It returns the request
/// id, which can be used to link the response to the request later.
///
/// On the Phat Contract side, when some requests are processed, it should send an action
/// `ACTION_QUEUE_PROCESSED_TO` to removed the finished requests, and increment the queue lock
/// (very important!).
///
/// Storage layout:
///
/// - `<lockKey>`: `uint` - the version of the queue lock
/// - `<prefix>/start`: `uint` - index of the first element
/// - `<prefix>/end`: `uint` - index of the next element to push to the queue
/// - `<prefix/<n>`: `bytes` - the `n`-th message
contract PhatQueuedAnchor is PhatRollupAnchor, IPhatQueuedAnchor, Ownable {
    event RequestQueued(uint256 idx, bytes data);
    event RequestProcessedTo(uint256);

    bytes queuePrefix;
    bytes lockKey;

    uint8 constant ACTION_QUEUE_PROCESSED_TO = 0;

    constructor(address caller_, address actionCallback_, bytes memory queuePrefix_)
        PhatRollupAnchor(caller_, actionCallback_)
    {
        // TODO: Now we are using the global lock. Should switch to fine grained lock in the
        // future.
        lockKey = hex"00";
        queuePrefix = queuePrefix_;
    }

    function getUint(bytes memory key) public view returns (uint256) {
        bytes memory storageKey = bytes.concat(queuePrefix, key);
        return toUint256Strict(phatStorage[storageKey], 0);
    }

    function setUint(bytes memory key, uint256 value) internal {
        bytes memory storageKey = bytes.concat(queuePrefix, key);
        phatStorage[storageKey] = abi.encode(value);
    }

    function setBytes(bytes memory key, bytes memory value) internal {
        bytes memory storageKey = bytes.concat(queuePrefix, key);
        phatStorage[storageKey] = value;
    }

    function removeBytes(bytes memory key) internal {
        bytes memory storageKey = bytes.concat(queuePrefix, key);
        phatStorage[storageKey] = "";
    }

    function incLock() internal {
        uint256 v = toUint256Strict(phatStorage[lockKey], 0);
        phatStorage[lockKey] = abi.encode(v + 1);
    }

    /// Pushes a request to the queue waiting for the Phat Contract to process
    ///
    /// Returns the index of the reqeust.
    function pushRequest(bytes memory data) public onlyOwner() returns (uint256) {
        uint256 end = getUint("end");
        bytes memory itemKey = abi.encode(end);
        setBytes(itemKey, data);
        setUint("end", end + 1);
        incLock();
        emit RequestQueued(end, data);
        return end;
    }

    function popTo(uint256 end) internal {
        uint256 queueEnd = getUint("end");
        require(end <= queueEnd, "invalid queue end");
        for (uint256 i = getUint("start"); i < end; i++) {
            bytes memory itemKey = abi.encode(end);
            removeBytes(itemKey);
        }
        setUint("start", end);
        emit RequestProcessedTo(end);
    }

    // Handle queue related messages
    function handleCustomAction(bytes calldata action) internal override {
        require(action.length > 0, "invalid action");
        // processed to: [0] [u256 to]
        uint8 actionType = uint8(action[0]);
        if (actionType == ACTION_QUEUE_PROCESSED_TO) {
            uint256 end = abi.decode(action[1:], (uint256));
            popTo(end);
        } else {
            revert("unsupported action");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PhatRollupReceiver.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract PhatRollupAnchor is ReentrancyGuard {
    bytes4 constant ROLLUP_RECEIVED = 0x43a53d89;
    // function genReceiverSelector() public pure returns (bytes4) {
    //     return bytes4(keccak256("onPhatRollupReceived(address,bytes)"));
    // }
    // function testConvert(bytes calldata inputData) public view returns (uint256) {
    //     return toUint256(inputData, 0);
    // }

    uint8 constant ACTION_SYS = 0;
    uint8 constant ACTION_CALLBACK = 1;
    uint8 constant ACTION_CUSTOM = 2;
    
    address caller;
    address actionCallback;
    mapping (bytes => bytes) phatStorage;

    constructor(address caller_, address actionCallback_) {
        // require(actionCallback_.isContract(), "bad callback");
        caller = caller_;
        actionCallback = actionCallback_;
    }
    
    /// Triggers a rollup transaction with `eq` conditoin check on uint256 values
    ///
    /// - actions: Starts with one byte to define the action type and followed by the parameter of
    ///     the actions. Supported actions: ACTION_SYS, ACTION_CALLBACK
    function rollupU256CondEq(
        bytes[] calldata condKeys,
        bytes[] calldata condValues,
        bytes[] calldata updateKeys,
        bytes[] calldata updateValues,
        bytes[] calldata actions
    ) public nonReentrant() returns (bool) {
        require(msg.sender == caller, "bad caller");
        require(condKeys.length == condValues.length, "bad cond len");
        require(updateKeys.length == updateValues.length, "bad update len");
        
        // check cond
        for (uint i = 0; i < condKeys.length; i++) {
            uint256 value = toUint256Strict(phatStorage[condKeys[i]], 0);
            uint256 expected = toUint256Strict(condValues[i], 0);
            if (value != expected) {
                revert("cond not met");
            }
        }
        
        // apply actions
        for (uint i = 0; i < actions.length; i++) {
            handleAction(actions[i]);
        }
        
        // apply updates
        for (uint i = 0; i < updateKeys.length; i++) {
            phatStorage[updateKeys[i]] = updateValues[i];
        }

        return true;
    }

    function handleAction(bytes calldata action) private {
        uint8 actionType = uint8(action[0]);
        if (actionType == ACTION_SYS) {
            // pass
        } else if (actionType == ACTION_CALLBACK) {
            require(checkAndCallReceiver(action[1:]), "action failed");
        } else if (actionType == ACTION_CUSTOM) {
            handleCustomAction(action[1:]);
        } else {
            revert("unsupported action");
        }
    }

    /// Handles a custom action defined in a child contract
    ///
    /// Override it in the child class if you want to implement any special custom actions. Revert
    /// if you want to interrupt the transaction.
    function handleCustomAction(bytes calldata action) internal virtual {}
    
    function checkAndCallReceiver(bytes calldata action) private returns(bool) {
        bytes4 retval = PhatRollupReceiver(actionCallback)
            .onPhatRollupReceived(address(this), action);
        return (retval == ROLLUP_RECEIVED);
    }

    function getStorage(bytes memory key) public view returns(bytes memory) {
        return phatStorage[key];
    }

    function toUint256Strict(bytes memory _bytes, uint256 _start) public pure returns (uint256) {
        if (_bytes.length == 0) {
            return 0;
        }
        require(_bytes.length == _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }
        return tempUint;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IPhatQueuedAnchor {
    function pushRequest(bytes memory data) external returns (uint256);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

abstract contract PhatRollupReceiver {
    // bytes4(keccak256("onPhatRollupReceived(address,bytes)"))
    bytes4 constant ROLLUP_RECEIVED = 0x43a53d89;
    function onPhatRollupReceived(address _from, bytes calldata _action)
        public virtual returns(bytes4);
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