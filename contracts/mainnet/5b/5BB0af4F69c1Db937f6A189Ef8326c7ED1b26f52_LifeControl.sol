// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {IPausable} from "../../lib/IPausable.sol";

/**
 * @dev Contract logic responsible for xSwap protocol live control.
 */
interface ILifeControl is IPausable {
    /**
     * @dev Emitted when the termination is triggered by `account`.
     */
    event Terminated(address account);

    /**
     * @dev Pauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must not be in paused state
     */
    function pause() external;

    /**
     * @dev Unpauses xSwap protocol.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function unpause() external;

    /**
     * @dev Terminates xSwap protocol.
     *
     * Puts xSwap protocol into the paused state with no further ability to unpause.
     * This action essentially stops protocol so is expected to be called in
     * extraordinary scenarios only.
     *
     * Requires contract to be put into the paused state prior the call.
     *
     * Requirements:
     * - called by contract owner
     * - must be in paused state
     * - must not be in terminated state
     */
    function terminate() external;

    /**
     * @dev Returns whether protocol is terminated ot not.
     *
     * Terminated protocol is guaranteed to be in paused state forever.
     *
     * @return _ `true` if protocol is terminated, `false` otherwise.
     */
    function terminated() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Pausable} from "../../lib/Pausable.sol";
import {Ownable} from "../../lib/Ownable.sol";

import {ILifeControl} from "./ILifeControl.sol";

/**
 * @dev See {ILifeControl}.
 */
contract LifeControl is ILifeControl, Ownable, Pausable {
    bool private _terminated;

    /**
     * @dev See {ILifeControl-pause}.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {ILifeControl-unpause}.
     */
    function unpause() public onlyOwner {
        _requireNotTerminated();
        _unpause();
    }

    /**
     * @dev See {ILifeControl-terminate}.
     */
    function terminate() public onlyOwner whenPaused {
        _requireNotTerminated();
        _terminated = true;
        emit Terminated(_msgSender());
    }

    /**
     * @dev See {ILifeControl-terminated}.
     */
    function terminated() public view returns (bool) {
        return _terminated;
    }

    /**
     * @dev Throws if contract is in the terminated state.
     */
    function _requireNotTerminated() private view {
        require(!_terminated, "LC: terminated");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Context} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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

pragma solidity ^0.8.16;

interface IOwnable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

/**
 * @dev Public interface of OpenZeppelin's {Pausable}.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Ownable} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Context} import (use `library` implementation)
 * - shortify `require` messages (`Ownable:` -> `OW:` + others to avoid length warnings)
 * - extract {IOwnable} interface
 */

pragma solidity ^0.8.16;

import {IOwnable} from "./IOwnable.sol";
import {Context} from "./Context.sol";

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;

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
     * @dev See {IOwnable-owner}
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "OW: caller is not the owner");
    }

    /**
     * @dev See {IOwnable-renounceOwnership}
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev See {IOwnable-transferOwnership}
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OW: new owner is zero address");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Pausable} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Context} import (use `library` implementation)
 * - inherit from {IPausable}
 * - remove IPausable-duplicated events
 * - shortify `require` messages (`Pausable:` -> `PA:`)
 */

pragma solidity ^0.8.16;

import {IPausable} from "./IPausable.sol";
import {Context} from "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is IPausable, Context {
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
        require(!paused(), "PA: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "PA: not paused");
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