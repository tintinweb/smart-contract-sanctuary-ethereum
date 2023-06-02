pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/ICommunityFairLaunch.sol";

// The general steps of the presale are:
// 1. Investors commit their ETH
// 2. After presale ended, 2.5% of totalEthCommitted will be used to add liquidity
// 3. At the same block, this contract will be using 35.5% of totalEthCommitted to buy back
// 4. After buy back, 32% of totalEthCommitted will be used to add extra liquidity with the PoDeb bought
// 5. After adding liquidity, the leftover PoDeb will be distributed to the investors based on their allocations

contract Presale is Ownable, ReentrancyGuard, ICommunityFairLaunch  {

    address saleToken;
    address public marketingFund;
    address public developmentFund;

    struct UserInfo {
        uint256 ethCommitted;
        address referrer;
        uint256 lastClaimTs;
        uint256 claimedAmount;
    }

    mapping(address => UserInfo) public userInfo;

    address public uniswapV2Pair;
    address public uniswapV2Router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public presaleStartTs;
    uint256 public presaleEndTs;
    uint256 public constant PRESALE_DURATION = 3 days;

    uint256 public startClaimTs;
    uint256 public endClaimTs;
    uint256 public constant VESTING_DURATION = 2 days;
    uint256 public constant UNLOCK_TGE_PERCENT = 200000; // 20% unlock TGE

    uint256 public totalEthCommitted;
    uint256 public constant MAX_COMMIT_AMOUNT = 5 ether;
    uint256 public constant MIN_COMMIT_AMOUNT = 0.01 ether;

    mapping(address => uint256) public committedEth; // Get eth amount of an investor;
    mapping(address => bool) public gasClaimed;

    mapping(address => address) public referrer;
    mapping(address => uint256) public referralReward; // Record rewards of the referrers

    uint256 public constant REFERRAL_REWARD_PERCENT = 50000; // 50000/1000000*100 = 5%
    uint256 public constant MARKETING_FUND_PERCENT = 150000; // Fund will be used for marketing
    uint256 public constant DEVELOPMENT_FUND_PERCENT = 100000; // Fund will be used for team salaries & development in long term
    uint256 public constant RATIO_PRECISION = 1000000;

    bool public presaleEnded;

    uint256 public constant INITIAL_ETH_LIQUIDITY_PERCENT = 25000; // 2.5% of totalEthCommitted will be used to add for liquidity;
    uint256 public constant ETH_BUYBACK_PERCENT = 280000; // 28% of totalEthCommitted
    uint256 public constant GAS_REFUND = 0.01 ether;

    bool public canClaim;
    uint256 public tokenPerEther; // Presale price

    event ParticipatedPublicSale(address indexed investor, uint256 ethAmount);
    event ClaimPresaleToken(address indexed investor, uint256 amount);
    event PresaleEnded(uint256 marketingFundAllocation, uint256 developmentFundAllocation);
    event PresaleFinished(uint256 tokenPerEth);

    function initialize(
        address _marketingFund,
        address _developmentFund,
        uint256 _presaleStartTs,
        address _saleToken
    ) external onlyOwner {
        require(_marketingFund != address(0), "Invalid address");
        require(_developmentFund != address(0), "Invalid address");
        require(_saleToken != address(0), "Invalid address");

        presaleStartTs = _presaleStartTs;
        presaleEndTs = _presaleStartTs + PRESALE_DURATION;
        saleToken = _saleToken;
        marketingFund = _marketingFund;
        developmentFund = _developmentFund;
    }

    function buy(address _referrer) payable external override nonReentrant {
        require(_referrer != msg.sender, "Can not self-referring");
        require(block.timestamp > presaleStartTs && block.timestamp <= presaleEndTs, "Presale is not started or presale has already ended");
        require(msg.value > MIN_COMMIT_AMOUNT, "Invalid amount");
        UserInfo storage user = userInfo[msg.sender];
        require(msg.value + user.ethCommitted <= MAX_COMMIT_AMOUNT, "Exceed max commit amount");

        if (user.referrer == address(0) || user.referrer == owner()) {
            // If investor have no referrer, referrer will be sent to development fund
            user.referrer = _referrer != address(0) ? _referrer : developmentFund;
        }

        if (user.referrer != address(0)) {
            uint256 _referralReward = msg.value * REFERRAL_REWARD_PERCENT / 1000000;
            payable(user.referrer).transfer(_referralReward);
            referralReward[user.referrer] += _referralReward;
        }

        totalEthCommitted += msg.value;
        user.ethCommitted += msg.value;

        emit ParticipatedPublicSale(msg.sender, msg.value);
    }

    function endSale() external override onlyOwner {
        // Calculate and transfer funds
        uint256 _marketingAllocation = totalEthCommitted * MARKETING_FUND_PERCENT / 1000000;
        payable(marketingFund).transfer(_marketingAllocation);

        uint256 _developmentFundAllocation = totalEthCommitted * DEVELOPMENT_FUND_PERCENT / 1000000;
        payable(developmentFund).transfer(_developmentFundAllocation);

        presaleEnded = true;
        emit PresaleEnded(_marketingAllocation, _developmentFundAllocation);
    }

    function finalizeSale() external override onlyOwner {
        require(presaleEnded, "need to call endSale() first");

        address factory = IUniswapV2Router01(uniswapV2Router).factory();
        uniswapV2Pair = IUniswapV2Factory(factory).createPair(saleToken, weth);

        IERC20 _saleToken = IERC20(saleToken);
        IUniswapV2Router01 router = IUniswapV2Router01(uniswapV2Router);

        // Add liquidity
        uint256 initialEthForLiquidity = totalEthCommitted * INITIAL_ETH_LIQUIDITY_PERCENT / RATIO_PRECISION;
        _saleToken.approve(uniswapV2Router, type(uint).max);

        router.addLiquidityETH{value : initialEthForLiquidity}(
            saleToken,
            _saleToken.balanceOf(address(this)),
            0,
            0,
            developmentFund,
            block.timestamp + 60 * 5
        );

        // Buy Back with 30% of totalEthCommitted
        uint256 ethForBuyBack = totalEthCommitted * ETH_BUYBACK_PERCENT / RATIO_PRECISION;
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = saleToken;

        router.swapExactETHForTokens{value : ethForBuyBack}(
            0,
            path,
            address(this),
            block.timestamp + 60 * 5
        );

        // Add extra liquidity with all leftover ETH (55% of totalEthCommitted)
        uint256 currentEthBalance = address(this).balance;
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        uint256 saleTokenDesired = 0;

        if (IUniswapV2Pair(uniswapV2Pair).token0() == weth) {
            saleTokenDesired = currentEthBalance * reserve1 / reserve0;
        } else {
            saleTokenDesired = currentEthBalance * reserve0 / reserve1;
        }

        router.addLiquidityETH{value : currentEthBalance}(
            saleToken,
            saleTokenDesired,
            0,
            0,
            developmentFund,
            block.timestamp + 60 * 20
        );

        // Calculate presale price
        tokenPerEther = _saleToken.balanceOf(address(this)) * 1e18 / totalEthCommitted;

        emit PresaleFinished(tokenPerEther);
    }

    function claim() external override nonReentrant {
        require(canClaim, "Can not claim yet");

        UserInfo storage user = userInfo[msg.sender];
        require(user.ethCommitted > 0, "You didn't participate in the presale");

        uint256 claimableAmount = getClaimableAmount(msg.sender);
        require(claimableAmount > 0, "No claimable amount yet");

        require(claimableAmount + user.claimedAmount <= getUserAllocation(msg.sender), "Exceed allocation");

        // Refeund gas for user
        if (!gasClaimed[msg.sender]) {
            payable(msg.sender).transfer(GAS_REFUND);
            gasClaimed[msg.sender] = true;
        }

        user.claimedAmount += claimableAmount;
        user.lastClaimTs = block.timestamp;

        IERC20(saleToken).transfer(msg.sender, claimableAmount);

        emit ClaimPresaleToken(msg.sender, claimableAmount);
    }


    function getUserAllocation(address _investor) public view override returns (uint256 _allocation) {
        UserInfo memory user = userInfo[_investor];
        _allocation = user.ethCommitted * tokenPerEther / 1e18;
    }

    function getClaimableAmount(address _investor) public view override returns (uint256 _claimableAmount) {
        UserInfo memory user = userInfo[_investor];

        uint256 _allocation = getUserAllocation(_investor);
        uint256 _tokenPerSecond = _allocation / VESTING_DURATION;
        uint256 lastClaimTs = user.lastClaimTs == 0 ? startClaimTs : user.lastClaimTs;

        _claimableAmount = (block.timestamp - lastClaimTs) * _tokenPerSecond;

        if (lastClaimTs == startClaimTs) {
            uint256 unlockTgeAmount = _allocation * UNLOCK_TGE_PERCENT / RATIO_PRECISION;
            _claimableAmount += unlockTgeAmount;
        }

        if (_claimableAmount + user.claimedAmount > _allocation) {
            _claimableAmount = _allocation - user.claimedAmount;
        }
    }

    function enableClaim() external onlyOwner {
        require(presaleEnded, "Need to finalize sale first");

        startClaimTs = block.timestamp;
        canClaim = true;
    }

    receive() external payable {

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

pragma solidity ^0.8.0;

interface ICommunityFairLaunch {
    function buy(address _referrer) external payable;

    function endSale() external;

    function finalizeSale() external;

    function getUserAllocation(address _investor) external view returns (uint256);

    function getClaimableAmount(address _investor) external view returns (uint256);

    function claim() external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
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