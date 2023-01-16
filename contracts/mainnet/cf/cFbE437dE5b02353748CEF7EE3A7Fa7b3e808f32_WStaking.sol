//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

interface IStaking {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address receiver, uint amount) external;
}

contract WStaking is Ownable {
    uint public tokensPerDay;
    uint public totalStaked;
    bool public status;

    struct Profile {
        uint amount;
        uint start;
        uint lastClaim;
    }

    address public StakingToken;
    mapping(address => Profile) public stakers;

    constructor(address stakingToken) {
        StakingToken = stakingToken;
        tokensPerDay = 2e18;
    }

    function setEmissionPerDay(uint amount) public onlyOwner {
        tokensPerDay = amount;
    }

    function setStakingStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function stake(uint amount) public {
        require(status, "Staking is not started yet");
        IStaking(StakingToken).transferFrom(msg.sender, address(this), amount);
        if (stakers[msg.sender].start == 0) {
            stakers[msg.sender] = Profile(
                amount,
                block.timestamp,
                block.timestamp
            );
        } else {
            stakers[msg.sender].amount += amount;
        }
        totalStaked += amount;
    }

    function unstake(uint amount) public {
        require(stakers[msg.sender].amount >= amount, "not enough tokens!");
        uint rewards = getRewards(msg.sender);
        stakers[msg.sender].amount -= amount;
        stakers[msg.sender].lastClaim = block.timestamp;
        if (stakers[msg.sender].amount == 0) {
            stakers[msg.sender].start = 0;
            stakers[msg.sender].lastClaim = 0;
            stakers[msg.sender].start = 0;
        }
        IStaking(StakingToken).transfer(msg.sender, amount);
        IStaking(StakingToken).mint(msg.sender, rewards);
        totalStaked -= amount;
    }

    function getRewards(address staker) public view returns (uint256) {
        if (stakers[staker].amount == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == 0 || stakers[staker].start == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == block.timestamp) {
            return 0;
        }
        return
            tokensPerDay *
            (((block.timestamp - stakers[staker].lastClaim) / 1 days));
    }

    function getTotalStaked(address staker) public view returns (uint256) {
        return stakers[staker].amount;
    }

    function getStakingStartTime(address staker) public view returns (uint) {
        return stakers[staker].start;
    }

    function getStakerLastClaimTim(address staker) public view returns (uint) {
        return stakers[staker].lastClaim;
    }

    function nextRewardIn(address staker) public view returns (uint) {
        if (stakers[staker].amount == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == 0 || stakers[staker].start == 0) {
            return 0;
        }
        if (stakers[staker].lastClaim == block.timestamp) {
            return 1 days;
        }
        return 1 days - (block.timestamp - stakers[staker].lastClaim);
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