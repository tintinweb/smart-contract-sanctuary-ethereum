// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./utils/PriceCalculator.sol";

contract AgelessStakingRewards is Ownable, ReentrancyGuard, PriceCalculator {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    address public treasury;

    enum LOCK_TIER {
        NO_LOCK,
        ONE_WEEK,
        ONE_MONTH,
        THREE_MONTH
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardPerTokenPaid;
        uint256 rewardToBeClaimed;
        uint8 lockTier;
        uint256 stakedTime;
    }

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // tier reward multiplier
    mapping (uint8 => uint256) public tierMutiplier;
    // tier => period in sec
    mapping (uint256 => uint256) public tierLockupPeriod;

    // // User address => rewardPerTokenStored
    // mapping(address => uint) public userRewardPerTokenPaid;
    // // User address => rewards to be claimed
    // mapping(address => uint) public rewards;

    mapping (address => UserInfo) public users;

    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // Total staked
    uint public totalSupply;

    constructor(address _stakingToken, address _rewardToken, address _treasury) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        treasury = _treasury;
        tierMutiplier[uint8(LOCK_TIER.NO_LOCK)] = 100;
        tierMutiplier[uint8(LOCK_TIER.ONE_WEEK)] = 125;
        tierMutiplier[uint8(LOCK_TIER.ONE_MONTH)] = 150;
        tierMutiplier[uint8(LOCK_TIER.THREE_MONTH)] = 200;
        tierLockupPeriod[uint(LOCK_TIER.NO_LOCK)] = 0;
        tierLockupPeriod[uint(LOCK_TIER.ONE_WEEK)] = 604800;
        tierLockupPeriod[uint(LOCK_TIER.ONE_MONTH)] = 2592000;
        tierLockupPeriod[uint(LOCK_TIER.THREE_MONTH)] = 7776000;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        UserInfo storage user = users[_account];

        if (_account != address(0)) {
            user.rewardToBeClaimed = earned(_account);
            user.rewardPerTokenPaid = rewardPerTokenStored;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function tvl() public view returns (uint256) {
        return totalSupply * getTokenPriceInEthPair(IUniswapV2Router02(uniswapRouter), address(rewardsToken)) / 1e18;
    }

    function apr() public view returns (uint256) {
        uint256 reward = uint256(86400) * 365 * rewardRate;
        if (reward > 0) {
            return tvl() > 0 ? reward * getTokenPriceInEthPair(IUniswapV2Router02(uniswapRouter), address(rewardsToken)) / tvl() : 0;
        }
        return 0;
    }

    function stake(uint _amount, uint8 _lockTier) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        UserInfo storage user = users[_msgSender()];

        if (user.amount > 0) {
            require(_lockTier >= user.lockTier, 'lock tier cannot be less than previous one');
        }

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        user.amount += _amount;
        user.stakedTime = block.timestamp;
        user.lockTier = _lockTier;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external nonReentrant updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        UserInfo storage user = users[_msgSender()];
        if (!claimable(_msgSender())) {
            user.rewardToBeClaimed -= user.rewardToBeClaimed * 1e12 * _amount / user.amount / 1e12;
        }
        user.amount -= _amount;
        if (user.amount == 0) {
            user.lockTier = 0;
            user.stakedTime = 0;
        }
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned(address _account) public view returns (uint) {
        UserInfo memory user = users[_account];
        uint multiplier = tierMutiplier[user.lockTier];

        return ((user.amount * (rewardPerToken() - user.rewardPerTokenPaid)) * multiplier / 100 / 1e18) + user.rewardToBeClaimed;
    }

    function claimable(address _account) public view returns (bool) {
        UserInfo memory user = users[_account];
        uint lockupPeriod = tierLockupPeriod[user.lockTier];
        return user.stakedTime + lockupPeriod <= block.timestamp;
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        require(claimable(_msgSender()), "not claimable");
        UserInfo storage user = users[msg.sender];
        if (user.rewardToBeClaimed > 0) {
            rewardsToken.transferFrom(treasury, msg.sender, user.rewardToBeClaimed);
            user.rewardToBeClaimed = 0;
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(uint _amount)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(treasury),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './Utilities.sol';

abstract contract PriceCalculator is Utilities {
	function _getTokenPrice(
		IUniswapV2Router02 router,
		address[] memory tokenToStable
	) internal view virtual returns (uint256) {
		//special case where token is stable
		if (tokenToStable.length == 1) {
			return 1e18;
		}

		uint256[] memory amounts = router.getAmountsOut(1e18, tokenToStable);
		// stable token decimal is currently 6 so change to 18 decimals
		return amounts[amounts.length - 1] * 1e12;
	}

	function getTokenPriceInEthPair(
		IUniswapV2Router02 router,
		address token
	) public view virtual returns (uint256) {
		address WETH = router.WETH();
		address[] memory pair = new address[](2);
		pair[0] = token;
		pair[1] = WETH;
		uint256[] memory amounts = router.getAmountsOut(1e18, pair);
		uint256 amountInETH = amounts[amounts.length - 1];
		uint256 chainId = _getChainID();
		return amountInETH * _getETHPrice(router, usdc[chainId]) / 1e18;
	}

	function _getETHPrice(
		IUniswapV2Router02 router,
		address stableToken
	) internal view virtual returns (uint256) {
		address WETH = router.WETH();
		address[] memory tokenToStable = new address[](2);
		tokenToStable[0] = WETH;
		tokenToStable[1] = stableToken;
		return _getTokenPrice(router, tokenToStable);
	}

	function _getLPTokenPrice(
		IUniswapV2Router02 router,
		address[] memory token0ToStable,
		address[] memory token1ToStable,
		IERC20 lpToken
	) internal view virtual returns (uint256) {
		uint256 token0InPool = IERC20(token0ToStable[0]).balanceOf(
			address(lpToken)
		);
		uint256 token1InPool = IERC20(token1ToStable[0]).balanceOf(
			address(lpToken)
		);

		uint256 totalPriceOfPool = token0InPool *
			(_getTokenPrice(router, token0ToStable)) +
			token1InPool *
			(_getTokenPrice(router, token1ToStable));

		return totalPriceOfPool / (lpToken.totalSupply());
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract Utilities is Ownable {
    address internal uniswapRouter;
    mapping (uint256 => address) internal usdc;
    mapping (uint256 => address) internal usdt;

    constructor() {
        uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        usdc[1] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
		    usdc[4] = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
    }

    function _getChainID() internal view returns (uint256) {
      uint256 id;
      assembly {
        id := chainid()
      }
      return id;
    }
}