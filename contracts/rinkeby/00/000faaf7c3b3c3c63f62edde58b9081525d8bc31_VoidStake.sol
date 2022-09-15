// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**

    website: https://void.cash/
    twitter: https://twitter.com/voidcasherc
    telegram: https://t.me/voidcashportal
    medium: https://medium.com/@voidcash
    
    prepare to enter the
    ██╗   ██╗ ██████╗ ██╗██████╗ 
    ██║   ██║██╔═══██╗██║██╔══██╗
    ██║   ██║██║   ██║██║██║  ██║
    ╚██╗ ██╔╝██║   ██║██║██║  ██║
     ╚████╔╝ ╚██████╔╝██║██████╔╝
      ╚═══╝   ╚═════╝ ╚═╝╚═════╝ 

 */

import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/access/Ownable.sol";
import "./IMintableERC20.sol";

contract VoidStake is Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ZeroStakeAmount();
    error ZeroWithdrawAmount();
    error InvalidWithdrawAmount();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event VoidStaked(address indexed account, uint256 amount);
    event VoidWithdraw(address indexed account, uint256 amount);
    event VoidClaimed(address indexed account, uint256 amount);
    event RewardRateChanged(uint256 rewardRate);

    /* -------------------------------------------------------------------------- */
    /*                                public states                               */
    /* -------------------------------------------------------------------------- */
    address public immutable stakingTokenAddress;
    address public immutable rewardTokenAddress;

    uint256 public immutable rewardStartTime;

    uint256 public rewardRate = 1e13; // 0.00001 ether per second (0.864 ether per day)

    mapping(address => uint256) public userStakedAmount;
    uint256 public totalStaked;

    /* -------------------------------------------------------------------------- */
    /*                               private states                               */
    /* -------------------------------------------------------------------------- */
    uint256 private lastUpdatedAt;
    uint256 private currentRewardPerTokenE18;
    mapping(address => uint256) private userLastRewardPerToken;
    mapping(address => uint256) private userClaimableRewardTokens;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address _s, address _r) {
        stakingTokenAddress = _s;
        rewardTokenAddress = _r;
        rewardStartTime = block.timestamp;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  modifiers                                 */
    /* -------------------------------------------------------------------------- */
    modifier updateRewardVariables(address account) {

        // calculate current rewardPerToken
        uint256 _currentRewardPerToken = calculateRewardPerTokenE18();

        // update currentRewardPerToken
        currentRewardPerTokenE18 = _currentRewardPerToken;

        // update lastUpdatedAt
        lastUpdatedAt = block.timestamp;

        // update userClaimableRewardTokens for user
        userClaimableRewardTokens[account] = calculateClaimableRewardTokens(account, _currentRewardPerToken);

        // update userLastRewardPerToken for user
        userLastRewardPerToken[account] = _currentRewardPerToken;

        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    function claimableRewardTokens(address account) public view returns (uint256) {
        uint256 _currentRewardPerToken = calculateRewardPerTokenE18();
        return calculateClaimableRewardTokens(account, _currentRewardPerToken);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function stake(uint256 amount) external updateRewardVariables(msg.sender) {

        // check amount
        if (amount == 0) { revert ZeroStakeAmount(); }

        // transfer
        IERC20(stakingTokenAddress).transferFrom(msg.sender, address(this), amount);

        // update variables
        totalStaked += amount;
        userStakedAmount[msg.sender] += amount;

        // event
        emit VoidStaked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external updateRewardVariables(msg.sender) {

        // check amount
        if (amount == 0) { revert ZeroWithdrawAmount(); }
        if (amount > userStakedAmount[msg.sender]) { revert InvalidWithdrawAmount(); }

        // transfer
        IERC20(stakingTokenAddress).transfer(msg.sender, amount);

        // update variables
        totalStaked -= amount;
        userStakedAmount[msg.sender] -= amount;

        // event
        emit VoidWithdraw(msg.sender, amount);
    }

    function claim() external updateRewardVariables(msg.sender) {

        // get reward
        uint256 reward = userClaimableRewardTokens[msg.sender];

        // do nothing
        if (reward == 0) { return; }

        // send reward
        userClaimableRewardTokens[msg.sender] = 0;
        IMintableERC20(rewardTokenAddress).mint(msg.sender, reward);

        // event
        emit VoidClaimed(msg.sender, reward);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   private                                  */
    /* -------------------------------------------------------------------------- */
    function calculateRewardPerTokenE18() private view returns (uint256) {

        // none staked
        if (totalStaked == 0) { return currentRewardPerTokenE18; }

        // cumulative reward per token
        // scaled by 1e18, otherwise rewards may go into the fractions and be erased
        return currentRewardPerTokenE18 + (rewardRate * (block.timestamp - lastUpdatedAt) * 1e18) / totalStaked;
    }

    function calculateClaimableRewardTokens(address account, uint256 _currentRewardPerToken) private view returns (uint256) {
        // undo the scaling by 1e18 performed in `calculateRewardPerTokenE18`
        return userClaimableRewardTokens[account] + userStakedAmount[account] * (_currentRewardPerToken - userLastRewardPerToken[account]) / 1e18;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;

        emit RewardRateChanged(_rewardRate);
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
pragma solidity ^0.8.16;

import "openzeppelin/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
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