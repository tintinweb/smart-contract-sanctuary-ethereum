// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "Ownable.sol";
import {IERC20} from "IERC20.sol";

/// @title Distributor
/// @author dantop114
/// @notice Distribution contract that handles IDLE distribution for Idle Liquidity Gauges.
contract Distributor is Ownable {

    /*///////////////////////////////////////////////////////////////
                        IMMUTABLES AND CONSTANTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice The treasury address (used in case of emergency withdraw).
    address immutable treasury;

    /// @notice The IDLE token (the token to distribute).
    IERC20 immutable idle;

    /// @notice One week in seconds.
    uint256 public constant ONE_WEEK = 86400 * 7;

    /// @notice Initial distribution rate (as per IIP-*).
    /// @dev 178_200 IDLEs in 6 months.
    uint256 public constant INITIAL_RATE = (178_200 * 10 ** 18) / (26 * ONE_WEEK);

    /// @notice Distribution epoch duration.
    /// @dev 6 months epoch duration.
    uint256 public constant EPOCH_DURATION = ONE_WEEK;

    /// @notice Initial distribution epoch delay.
    /// @dev This needs to be updated when deploying if 1 day is not enough.
    uint256 public constant INITIAL_DISTRIBUTION_DELAY = 86400;

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Distributed IDLEs so far.
    uint256 public distributed;

    /// @notice Running distribution epoch rate.
    uint256 public rate;

    /// @notice Running distribution epoch starting epoch time
    uint256 public startEpochTime = block.timestamp + INITIAL_DISTRIBUTION_DELAY - EPOCH_DURATION;

    /// @notice Total distributed IDLEs when current epoch starts
    uint256 public epochStartingDistributed;

    /// @notice Distribution rate pending for upcoming epoch
    uint256 public pendingRate = INITIAL_RATE;

    /// @notice The DistributorProxy contract
    address public distributorProxy;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when distributor proxy is updated.
    event UpdateDistributorProxy(address oldProxy, address newProxy);

    /// @notice Event emitted when distribution parameters are updated for upcoming distribution epoch.
    event UpdatePendingRate(uint256 rate);

    /// @notice Event emitted when distribution parameters are updated.
    event UpdateDistributionParameters(uint256 time, uint256 rate);

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev The constructor.
    /// @param _idle The IDLE token address.
    /// @param _treasury The emergency withdrawal address.
    constructor(IERC20 _idle, address _treasury) {
        idle = _idle;
        treasury = _treasury;
    }

    /// @notice Update the DistributorProxy contract
    /// @dev Only owner can call this method
    /// @param proxy New DistributorProxy contract
    function setDistributorProxy(address proxy) external onlyOwner {
        address distributorProxy_ = distributorProxy;
        distributorProxy = proxy;

        emit UpdateDistributorProxy(distributorProxy_, proxy);
    }

    /// @notice Update rate for next epoch
    /// @dev Only owner can call this method
    /// @param newRate Rate for upcoming epoch
    function setPendingRate(uint256 newRate) external onlyOwner {
        pendingRate = newRate;
        emit UpdatePendingRate(newRate);
    }

    /// @dev Updates internal state to match current epoch distribution parameters.
    function _updateDistributionParameters() internal {
        startEpochTime += EPOCH_DURATION; // set start epoch timestamp
        epochStartingDistributed += (rate * EPOCH_DURATION); // set initial distributed floor
        rate = pendingRate; // set new rate

        emit UpdateDistributionParameters(startEpochTime, rate);
    }

    /// @notice Updates distribution rate and start timestamp of the epoch.
    /// @dev Callable by anyone if pending epoch should start.
    function updateDistributionParameters() external {
        require(block.timestamp >= startEpochTime + EPOCH_DURATION, "epoch still running");
        _updateDistributionParameters();
    }

    /// @notice Get timestamp of the current distribution epoch start.
    /// @return _startEpochTime Timestamp of the current epoch start.
    function startEpochTimeWrite() external returns (uint256 _startEpochTime) {
        _startEpochTime = startEpochTime;

        if (block.timestamp >= _startEpochTime + EPOCH_DURATION) {
            _updateDistributionParameters();
            _startEpochTime = startEpochTime;
        }
    }

    /// @notice Get timestamp of the next distribution epoch start.
    /// @return _futureEpochTime Timestamp of the next epoch start.
    function futureEpochTimeWrite() external returns (uint256 _futureEpochTime) {
        _futureEpochTime = startEpochTime + EPOCH_DURATION;

        if (block.timestamp >= _futureEpochTime) {
            _updateDistributionParameters();
            _futureEpochTime = startEpochTime + EPOCH_DURATION;
        }
    }

    /// @dev Returns max available IDLEs to distribute.
    /// @dev This will revert until initial distribution begins.
    function _availableToDistribute() internal view returns (uint256) {
        return epochStartingDistributed + (block.timestamp - startEpochTime) * rate;
    }

    /// @notice Returns max available IDLEs for current distribution epoch.
    /// @return Available IDLEs to distribute.
    function availableToDistribute() external view returns (uint256) {
        return _availableToDistribute();
    }

    /// @notice Distribute `amount` IDLE to address `to`.
    /// @param to The account that will receive IDLEs.
    /// @param amount The amount of IDLEs to distribute.
    function distribute(address to, uint256 amount) external returns(bool) {
        require(msg.sender == distributorProxy, "not proxy");
        require(to != address(0), "address zero");

        if (block.timestamp >= startEpochTime + EPOCH_DURATION) {
            _updateDistributionParameters();
        }

        uint256 _distributed = distributed + amount;
        require(_distributed <= _availableToDistribute(), "amount too high");

        distributed = _distributed;
        return idle.transfer(to, amount);
    }

    /// @notice Emergency method to withdraw funds.
    /// @param amount The amount of IDLEs to withdraw from contract.
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        idle.transfer(treasury, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}