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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDSQStaking {
    function balanceOf(address account) external view returns (uint256);

    function stake(address account, uint256 amount) external;

    function withdraw(address account, uint256 amount) external;

    function exit(address account) external;

    function getReward(address account, address recipient) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IesDSQStaking {
    function stake(address _account, uint256 _amount, bool _adminStake) external;

    function unstake(address _account, uint256 _amount) external;

    function notify(address _address) external;

    function claim(address _account, address _recipient) external returns (uint256);

    function emergencyWithdraw(address _account) external;
}

// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IDSQStaking.sol";
import "../interfaces/IesDSQStaking.sol";

/**
 * @title   DSquared Router
 * @notice  Interface point for DSQStaking and esDSQStaking
 * @author  HessianX
 * @custom:developer BowTiedOriole
 */

contract Router is Ownable, Pausable, ReentrancyGuard {
    // ----- State Variables -----

    /// @notice Address of DSQ Token
    IERC20 public immutable dsq;

    /// @notice Address of esDSQ Token
    IERC20 public immutable esdsq;

    /// @notice Address of DSQStaking Contract
    IDSQStaking public immutable dsqStaking;

    /// @notice Address of esDSQStaking Contract
    IesDSQStaking public immutable esdsqStaking;

    // ----- Construction -----

    /**
     * @notice  Sets the addresses of DSQ token, esDSQ token, DSQStaking contract, and esDSQStaking contract. All are immutable
     * @dev     Router sets infinite approvals for staking contracts
     * @param   _owner          Owner address
     * @param   _dsq            DSQ token address
     * @param   _esdsq          esDSQ token address
     * @param   _dsqStaking     DSQStaking contract address
     * @param   _esdsqStaking   esDSQStaking contract address
     */
    constructor(address _owner, IERC20 _dsq, IERC20 _esdsq, address _dsqStaking, address _esdsqStaking) {
        require(_owner != address(0), "Router: Zero address");
        _transferOwnership(_owner);
        dsq = _dsq;
        esdsq = _esdsq;
        dsqStaking = IDSQStaking(_dsqStaking);
        esdsqStaking = IesDSQStaking(_esdsqStaking);
        dsq.approve(address(dsqStaking), type(uint256).max);
        esdsq.approve(address(esdsqStaking), type(uint256).max);
    }

    // ----- State Changing -----

    // ----- DSQStaking Calls -----

    /**
     * @notice  Stakes the given amount of DSQ tokens
     * @dev     Requires approval for router to spend user's tokens
     * @param   _amount Amount of DSQ to stake
     */
    function stakeDSQStaking(uint256 _amount) external whenNotPaused nonReentrant {
        dsq.transferFrom(msg.sender, address(this), _amount);
        dsqStaking.stake(msg.sender, _amount);
        esdsqStaking.notify(msg.sender);
    }

    /**
     * @notice  Harvests esDSQ rewards from DSQStaking
     */
    function harvestDSQStaking() external nonReentrant returns (uint256) {
        return dsqStaking.getReward(msg.sender, msg.sender);
    }

    /**
     * @notice  Withdraws the given amount of DSQ tokens
     * @dev     Will pause esDSQ vesting if DSQ amount drops below required amount
     * @param   _amount Amount of DSQ to withdraw
     */
    function withdrawDSQStaking(uint256 _amount) external nonReentrant {
        dsqStaking.withdraw(msg.sender, _amount);
        esdsqStaking.notify(msg.sender);
    }

    /**
     * @notice  Harvests esDSQ rewards from DSQStaking and withdraws all DSQ
     * @dev     Will pause vesting if user has esDSQ vesting position
     */
    function exitDSQStaking() external nonReentrant {
        dsqStaking.exit(msg.sender);
        esdsqStaking.notify(msg.sender);
    }

    /**
     * @notice  Emergency withdraw from DSQStaking
     * @dev     Does not claim rewards from DSQStaking.
     */
    function emergencyWithdrawDSQStaking() external nonReentrant {
        uint256 bal = dsqStaking.balanceOf(msg.sender);
        if (bal > 0) dsqStaking.withdraw(msg.sender, bal);
        esdsqStaking.notify(msg.sender);
    }

    // ----- esDSQStaking Calls -----

    /**
     * @notice  Stakes the given amount of esDSQ tokens
     * @dev     Requires approval for router to spend user's tokens
     * @param   _amount Amount of esDSQ to stake
     */
    function stakeESDSQStaking(uint256 _amount) external whenNotPaused nonReentrant {
        esdsq.transferFrom(msg.sender, address(this), _amount);
        esdsqStaking.stake(msg.sender, _amount, false);
    }

    /**
     * @notice  Claims DSQ rewards from esdsqStaking
     */
    function claimESDSQStaking() external nonReentrant {
        esdsqStaking.claim(msg.sender, msg.sender);
    }

    /**
     * @notice  Withdraws all esDSQ tokens from esDSQStaking
     * @dev     WARNING: This resets the vesting position & forfeits any progress
     */
    function emergencyWithdrawESDSQStaking() external nonReentrant {
        esdsqStaking.emergencyWithdraw(msg.sender);
    }

    // ----- Combined Calls -----

    /**
     * @notice  Claims DSQ rewards from esDSQStaking and stakes them in DSQStaking
     */
    function claimESDSQStakingAndStakeDSQStaking() external whenNotPaused nonReentrant {
        uint256 bal = esdsqStaking.claim(msg.sender, address(this));
        dsqStaking.stake(msg.sender, bal);
        esdsqStaking.notify(msg.sender);
    }

    /**
     * @notice  Harvests esDSQ rewards from DSQStaking and stakes in esDSQStaking
     * @dev     Will revert if claimed rewards > DSQ staked
     */
    function harvestDSQStakingAndStakeESDSQStaking() external whenNotPaused nonReentrant {
        uint256 bal = dsqStaking.getReward(msg.sender, address(this));
        if (bal > 0) esdsqStaking.stake(msg.sender, bal, false);
    }

    /**
     * @notice  Emergency withdraw from both DSQStaking and esDSQStaking
     * @dev     WARNING: This resets the vesting position & forfeits any progress
     */
    function emergencyWithdrawAll() external nonReentrant {
        uint256 bal = dsqStaking.balanceOf(msg.sender);
        if (bal > 0) dsqStaking.withdraw(msg.sender, bal);
        esdsqStaking.emergencyWithdraw(msg.sender);
    }

    // ----- Admin Functions -----

    /**
     * @notice  Stakes the given amount of esDSQ tokens on behalf of the given account
     * @dev     Requires approval for router to spend msg.sender's tokens
     * @param   _account    User to stake esDSQ on behalf of
     * @param   _amount     Amount of esDSQ to stake
     */
    function adminStakeESDSQStaking(address _account, uint256 _amount) external whenNotPaused onlyOwner nonReentrant {
        esdsq.transferFrom(msg.sender, address(this), _amount);
        esdsqStaking.stake(_account, _amount, true);
    }

    /**
     * @notice  Pauses all staking functions
     * @dev     User can still call functions to claim rewards & withdraw funds
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice  Unpauses all staking functions
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}