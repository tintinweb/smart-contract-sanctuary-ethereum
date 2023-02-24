// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import "Ownable.sol";
import "IGStrategyGuard.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title GStopLossResolver
/// @notice Targets GStopLossExecutor contract to update/reset primer values
/// alongside this triggering a strategy stop loss if primer interval threshold
/// is met.
contract GStopLossResolver is Ownable {
    address immutable stopLossExecutor;

    constructor(address _stopLossExecutor) {
        stopLossExecutor = _stopLossExecutor;
    }

    /// @notice returns correct payload to gelato to update strategy
    /// stop loss primer on the GStopLossExecutor
    function taskUpdateStopLossPrimer()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        IGStrategyGuard executor = IGStrategyGuard(stopLossExecutor);
        if (executor.canUpdateStopLoss()) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                executor.setStopLossPrimer.selector
            );
        }
    }

    /// @notice returns correct payload to gelato to stop the strategy
    /// stop loss primer on the GStopLossExecutor
    function taskStopStopLossPrimer()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        IGStrategyGuard executor = IGStrategyGuard(stopLossExecutor);
        if (executor.canEndStopLoss()) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                executor.endStopLossPrimer.selector
            );
        }
    }

    /// @notice returns correct payload to gelato to trigger strategy
    /// stop loss on the GStopLossExecutor
    function taskTriggerStopLoss()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        IGStrategyGuard executor = IGStrategyGuard(stopLossExecutor);
        if (executor.canExecuteStopLossPrimer()) {
            canExec = true;
            execPayload = abi.encodeWithSelector(
                executor.executeStopLoss.selector
            );
        }
    }

    /// @notice returns correct payload to gelato to trigger Strategy Harvest
    function taskStrategyHarvest()
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        IGStrategyGuard executor = IGStrategyGuard(stopLossExecutor);
        if (executor.canHarvest()) {
            canExec = true;
            execPayload = abi.encodeWithSelector(executor.harvest.selector);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

interface IGStrategyGuard {
    /// @notice returns true if keeper should call setStopLossPrimer for strategy
    function canUpdateStopLoss() external view returns (bool);

    /// @notice sets timer if update stop loss returns true
    function setStopLossPrimer() external;

    /// @notice returns true if keeper should call stopStopLossPrimer for strategy
    function canEndStopLoss() external view returns (bool);

    /// @notice resets timer if endStopLoss returns true
    function endStopLossPrimer() external;

    /// @notice returns true if keeper should call executeStopLoss for strategy
    function canExecuteStopLossPrimer() external view returns (bool);

    /// @notice run stop loss function if canExecuteStopLossPrimer is true
    function executeStopLoss() external;

    /// @notice returns true if keeper can execute harvest
    function canHarvest() external view returns (bool);

    /// @notice run strategy harvest
    function harvest() external;
}