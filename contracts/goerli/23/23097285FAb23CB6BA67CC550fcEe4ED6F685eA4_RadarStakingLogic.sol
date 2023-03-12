// SPDX-License-Identifier: MIT LICENSE

// TODO: Add auto-compound logic
// TODO: Add logic to handle changes in APR

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iRadarToken.sol";
import "./interfaces/iRadarStake.sol";

contract RadarStakingLogic is Ownable, Pausable, ReentrancyGuard {

    constructor() {
        _pause();
    }

    /** EVENTS */
    event TokensStaked(address indexed owner, uint256 amount);
    event TokensHarvested(address indexed owner, uint256 amount);
    event TokensUnstaked(address indexed owner, uint256 amount);

    /** PUBLIC VARS */
    iRadarToken public radarTokenContract;
    iRadarStake public radarStakeContract;
    uint256 public cooldownSeconds = 30 days; // e.g. 86_400 = 1 day
    uint256 public stakingApr = 300; // e.g. 300 = 3%

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;

    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "RadarStakingLogic: Only admins can call this");
        _;
    }

    modifier requireVariablesSet() {
        require(address(radarTokenContract) != address(0), "RadarStakingLogic: Token contract not set");
        require(address(radarStakeContract) != address(0), "RadarStakingLogic: Staking contract not set");
        _;
    }

    /** PUBLIC */
    // this contract needs to have permission to move RADAR for the _msgSender() before this function can be called
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        /** Checks */
        // check if the user owns the amount of tokens he wants to stake
        require(radarTokenContract.balanceOf(_msgSender()) >= amount, "RadarStakingLogic: Not enough tokens to stake");
        require(radarTokenContract.allowance(_msgSender(), address(this)) >= amount, "RadarStakingLogic: This contact is not allowed to move the amount of tokens you want to stake");

        /** Mutate */
        // calculate reward in case the user already had a stake and now added to it
        uint256 tokenReward = calculateReward(_msgSender());
        radarStakeContract.addToStake(amount + tokenReward, _msgSender(), stakingApr, cooldownSeconds);
        // move tokens from this token to the stake contract's address
        radarTokenContract.transferFrom(_msgSender(), address(radarStakeContract), amount);

        emit TokensStaked(_msgSender(), amount);
    }

    function harvest(bool restake) public nonReentrant {
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(_msgSender());
        
        /** Checks */
        require(myStake.totalStaked > 0, "RadarStakingLogic: You don't have tokens staked");
        require(block.timestamp >= myStake.lastStakedTimestamp + myStake.cooldownSeconds, "RadarStakingLogic: Can't harvest during the cooldown period");

        /** Mutate */
        uint256 tokenReward = calculateReward(_msgSender());
        if (restake) {
            // stake again to reset the clock + add the reward to the stake (this happens automatically in the stake contract)
            radarStakeContract.addToStake(tokenReward, _msgSender(), stakingApr, cooldownSeconds);
        } else {
            // pay out the rewards, keep the original stake, reset the clock
            radarTokenContract.transferFrom(address(radarStakeContract), _msgSender(), tokenReward);
            // stake again to reset the clock
            radarStakeContract.addToStake(0, _msgSender(), stakingApr, cooldownSeconds);
        }

        emit TokensHarvested(_msgSender(), tokenReward);
    }

    function unstake(uint256 amount) external nonReentrant {
        // TODO: trigger events

        iRadarStake.Stake memory myStake = radarStakeContract.getStake(_msgSender());

        /** Checks */
        require(myStake.totalStaked >= amount, "RadarStakingLogic: Amount you want to unstake exceeds your staked amount");
        require(block.timestamp >= myStake.lastStakedTimestamp + myStake.cooldownSeconds, "RadarStakingLogic: Can't unstake during the cooldown period");

        /** Mutate */
        uint256 tokenReward = calculateReward(_msgSender());
        radarStakeContract.removeFromStake(amount, _msgSender(), stakingApr, cooldownSeconds);
        radarTokenContract.transferFrom(address(radarStakeContract), _msgSender(), amount + tokenReward);

        emit TokensUnstaked(_msgSender(), amount);
    }

    // TODO: Test this well
    function calculateReward(address addr) public view returns(uint256) {
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(addr);

        // if the cooldown has not yet passed, the user get's 0 rewards
        if (block.timestamp < myStake.lastStakedTimestamp + myStake.cooldownSeconds) {
            return 0;
        }

        uint256 secondsInYear = 1 days * 365;
        uint256 secondsStaked = (block.timestamp - myStake.lastStakedTimestamp - myStake.cooldownSeconds);
        uint256 reward = myStake.totalStaked * myStake.apr/10000 * secondsStaked/secondsInYear;

        return reward;
    }

    function isAdmin(address addr) external view returns (bool) {
        return (_admins[addr]);
    }

    /** ONLY OWNER */
    function setPaused(bool _paused) external requireVariablesSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setContracts(address radarTokenContractAddr, address radarStakeContractAddr) external onlyOwner {
        radarTokenContract = iRadarToken(radarTokenContractAddr);
        radarStakeContract = iRadarStake(radarStakeContractAddr);
    }

    function setCooldownSeconds(uint256 number) external onlyOwner {
        cooldownSeconds = number;
    }

    function setStakingApr(uint256 number) external onlyOwner {
        stakingApr = number;
    }

    // if someone sends ETH to this contract by accident we want to be able to send it back to them
    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;

        bool sent;
        (sent, ) = owner().call{value: totalAmount}("");
        require(sent, "RadarStakingLogic: Failed to send funds to projectWallet");
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }

}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iRadarToken is IERC20 {

}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

interface iRadarStake {

    // store lock meta data
    struct Stake {
        uint256 totalStaked;
        uint256 apr;
        uint256 lastStakedTimestamp;
        uint256 cooldownSeconds;
    }

    function addToStake(uint256 amount, address addr, uint256 apr, uint256 cooldownSeconds) external; // onlyAdmin
    function removeFromStake(uint256 amount, address addr, uint256 apr, uint256 cooldownSeconds) external; // onlyAdmin

    function getTotalStaked() external view returns (uint256);
    function getStake(address addr) external view returns (Stake memory);
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