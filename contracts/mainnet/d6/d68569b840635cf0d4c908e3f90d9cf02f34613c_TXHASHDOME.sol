/**
 *Submitted for verification at Etherscan.io on 2022-09-05
 */

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

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
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function purge(address receiver) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    //Reward token passed through constructor
    IERC20 public REWARD;
    //address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 1 * (10**9);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address rewardToken) {
        router = _router != address(0)
            ? IUniswapV2Router02(_router) //: IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
            : IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
        REWARD = IERC20(rewardToken);
    }

    receive() external payable {}

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function purge(address receiver) external override onlyToken {
        uint256 balance = REWARD.balanceOf(address(this));
        REWARD.transfer(receiver, balance);
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(REWARD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = REWARD.balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            REWARD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getHolderDetails(address holder)
        public
        view
        returns (
            uint256 lastClaim,
            uint256 unpaidEarning,
            uint256 totalReward,
            uint256 holderIndex
        )
    {
        lastClaim = shareholderClaims[holder];
        unpaidEarning = getUnpaidEarnings(holder);
        totalReward = shares[holder].totalRealised;
        holderIndex = shareholderIndexes[holder];
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return currentIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return shareholders.length;
    }

    function getShareHoldersList() external view returns (address[] memory) {
        return shareholders;
    }

    function totalDistributedRewards() external view returns (uint256) {
        return totalDistributed;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract TXHASHDOME is IERC20, Ownable {
    using SafeMath for uint256;

    //address WBNB    = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address WBNB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    // Swap token can be set to a non-WBNB token if desired
    //address public SWAPTOKEN    = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public SWAPTOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // USDT Reward
    //address public REWARD   = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    address public REWARD = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    string public constant _name = "TxHash Dome";
    string public constant _symbol = "TxHD";
    uint8 public constant _decimals = 18;
    uint256 public _totalSupply = 100_000_000_000 * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply.div(200); //.5%
    uint256 public _maxWalletAmount = _totalSupply.div(100); //1%

    bool public tradingStart = false;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isDividendExempt;

    // Buy fees - 10% - base 1000
    uint256 public buyDividendRewardsFee = 0;
    uint256 public buyMarketingFee = 40;
    uint256 public buyLiquidityFee = 20;
    uint256 public buyDevFee = 30;
    uint256 public buyBurnFee = 0;
    uint256 public buyCharityFee = 10;
    uint256 public buyTotalFees = 100;

    // Sell fees - 12% - base 1000
    uint256 public sellDividendRewardsFee = 0;
    uint256 public sellMarketingFee = 50;
    uint256 public sellLiquidityFee = 20;
    uint256 public sellDevFee = 40;
    uint256 public sellBurnFee = 0;
    uint256 public sellCharityFee = 10;
    uint256 public sellTotalFees = 120;

    uint256 public totalLiquidityFee = buyLiquidityFee.add(sellLiquidityFee);
    uint256 public totalMarketingFee = buyMarketingFee.add(sellMarketingFee);
    uint256 public totalDevFee = buyDevFee.add(sellDevFee);
    uint256 public totalBurnFee = buyBurnFee.add(sellBurnFee);
    uint256 public totalCharityFee = buyCharityFee.add(sellCharityFee);
    uint256 public totalDividendRewardsFee =
        buyDividendRewardsFee.add(sellDividendRewardsFee);
    uint256 public totalFees = buyTotalFees.add(sellTotalFees);

    address public marketingFeeReceiver =
        0xa559115d3a5A7d82d39Bd5Fb0c6B9f2B556A6467;
    address public devFeeReceiver = 0xc9243539FdBd1d7707E9234c2036f380d67c2f11;
    address public charityFeeReceiver =
        0xA7F4784606dC04E32a129b63322824BF242052a9;
    address public LPReceiver = 0x808d5f4f990B861d764b24b3dD6bB41246E7CedF;

    IUniswapV2Router02 public router;
    address public pair;

    DividendDistributor public dividendDistributor;
    uint256 distributorGas = 500000;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event SendFeesInToken(address wallet, uint256 amount);
    event ChangeRewardTracker(address token);
    event IncludeInReward(address holder);

    bool public swapEnabled = true;

    // Swap threshold is set at .01% of supply currently, 10m tokens
    uint256 public swapThreshold = _totalSupply.div(10000);
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        //router      = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pair = IUniswapV2Factory(router.factory()).createPair(
            WBNB,
            address(this)
        );

        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendDistributor = new DividendDistributor(address(router), REWARD);

        isFeeExempt[msg.sender] = true;
        isDividendExempt[msg.sender] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[devFeeReceiver] = true;
        isFeeExempt[charityFeeReceiver] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // tracker dashboard functions
    function getHolderDetails(address holder)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendDistributor.getHolderDetails(holder);
    }

    function getLastProcessedIndex() public view returns (uint256) {
        return dividendDistributor.getLastProcessedIndex();
    }

    function getNumberOfTokenHolders() public view returns (uint256) {
        return dividendDistributor.getNumberOfTokenHolders();
    }

    function totalDistributedRewards() public view returns (uint256) {
        return dividendDistributor.totalDistributedRewards();
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            require(tradingStart == true, "Trading not started yet");

            if (sender == pair) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount"
                );

                uint256 contractBalanceRecepient = balanceOf(recipient);
                require(
                    contractBalanceRecepient + amount <= _maxWalletAmount,
                    "Exceeds max wallet token amount"
                );
            }
        }

        if (shouldSwapBack()) {
            if (SWAPTOKEN == WBNB) {
                swapBackInBnb();
            } else {
                swapBackInTokens();
            }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount, recipient)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try
                dividendDistributor.setShare(sender, _balances[sender])
            {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                dividendDistributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try dividendDistributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        return (!isFeeExempt[sender] && !isFeeExempt[recipient]);
    }

    function takeFee(
        address sender,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 burnFee = 0;

        if (to == pair) {
            feeAmount = amount.mul(sellTotalFees).div(1000);

            if (sellBurnFee > 0) {
                burnFee = feeAmount.mul(sellBurnFee).div(sellTotalFees);
                _balances[DEAD] = _balances[DEAD].add(burnFee);
                emit Transfer(sender, DEAD, burnFee);
            }
        } else {
            feeAmount = amount.mul(buyTotalFees).div(1000);

            if (buyBurnFee > 0) {
                burnFee = feeAmount.mul(buyBurnFee).div(buyTotalFees);
                _balances[DEAD] = _balances[DEAD].add(burnFee);
                emit Transfer(sender, DEAD, burnFee);
            }
        }

        uint256 feesToContract = feeAmount.sub(burnFee);
        _balances[address(this)] = _balances[address(this)].add(feesToContract);
        emit Transfer(sender, address(this), feesToContract);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB.mul(amountPercentage).div(100));
    }

    function changeSwapToken(address token) external onlyOwner {
        SWAPTOKEN = token;
    }

    // Taxes are set based on 1000
    // Where 10 is equal to a 1% tax (10/1000 = 1%)
    function updateBuyFees(
        uint256 reward,
        uint256 marketing,
        uint256 liquidity,
        uint256 dev,
        uint256 burn,
        uint256 charity
    ) public onlyOwner {
        require(
            (reward + marketing + liquidity + dev + burn + charity) <= 250,
            "Total Fee must be less than 25%"
        );

        buyDividendRewardsFee = reward;
        buyMarketingFee = marketing;
        buyLiquidityFee = liquidity;
        buyDevFee = dev;
        buyBurnFee = burn;
        buyCharityFee = charity;
        buyTotalFees = reward
            .add(marketing)
            .add(liquidity)
            .add(dev)
            .add(burn)
            .add(charity);

        totalLiquidityFee = buyLiquidityFee.add(sellLiquidityFee);
        totalMarketingFee = buyMarketingFee.add(sellMarketingFee);
        totalDevFee = buyDevFee.add(sellDevFee);
        totalBurnFee = buyBurnFee.add(sellBurnFee);
        totalCharityFee = buyCharityFee.add(sellCharityFee);
        totalDividendRewardsFee = buyDividendRewardsFee.add(
            sellDividendRewardsFee
        );
        totalFees = buyTotalFees.add(sellTotalFees);
    }

    // Taxes are set based on 1000
    // Where 10 is equal to a 1% tax (10/1000 = 1%)
    function updateSellFees(
        uint256 reward,
        uint256 marketing,
        uint256 liquidity,
        uint256 dev,
        uint256 burn,
        uint256 charity
    ) public onlyOwner {
        require(
            (reward + marketing + liquidity + dev + burn + charity) <= 250,
            "Total Fee must be less than 25%"
        );

        sellDividendRewardsFee = reward;
        sellMarketingFee = marketing;
        sellLiquidityFee = liquidity;
        sellDevFee = dev;
        sellBurnFee = burn;
        sellCharityFee = charity;
        sellTotalFees = reward
            .add(marketing)
            .add(liquidity)
            .add(dev)
            .add(burn)
            .add(charity);

        totalLiquidityFee = buyLiquidityFee.add(sellLiquidityFee);
        totalMarketingFee = buyMarketingFee.add(sellMarketingFee);
        totalDevFee = buyDevFee.add(sellDevFee);
        totalBurnFee = buyBurnFee.add(sellBurnFee);
        totalCharityFee = buyCharityFee.add(sellCharityFee);
        totalDividendRewardsFee = buyDividendRewardsFee.add(
            sellDividendRewardsFee
        );
        totalFees = buyTotalFees.add(sellTotalFees);
    }

    function whitelistPreSalePlatform(address _preSale) public onlyOwner {
        isFeeExempt[_preSale] = true;
        isDividendExempt[_preSale] = true;
    }

    // new dividend tracker, clear balance
    function purgeBeforeSwitch() public onlyOwner {
        dividendDistributor.purge(msg.sender);
    }

    function includeMeinRewards() public {
        require(
            !isDividendExempt[msg.sender],
            "You are not allowed to get rewards"
        );
        try
            dividendDistributor.setShare(msg.sender, _balances[msg.sender])
        {} catch {}

        emit IncludeInReward(msg.sender);
    }

    // new dividend tracker
    function switchToken(address rewardToken, bool isIncludeHolders)
        public
        onlyOwner
    {
        require(rewardToken != WBNB, "Can not reward BNB in this tracker");
        REWARD = rewardToken;
        // get current shareholders list
        address[] memory currentHolders = dividendDistributor
            .getShareHoldersList();

        dividendDistributor = new DividendDistributor(address(router), REWARD);

        if (isIncludeHolders) {
            // add old share holders to new tracker
            for (uint256 i = 0; i < currentHolders.length; i++) {
                try
                    dividendDistributor.setShare(
                        currentHolders[i],
                        _balances[currentHolders[i]]
                    )
                {} catch {}
            }
        }

        emit ChangeRewardTracker(rewardToken);
    }

    // manual claim
    function ___claimRewards(bool tryAll) public {
        dividendDistributor.claimDividend();
        if (tryAll) {
            try dividendDistributor.process(distributorGas) {} catch {}
        }
    }

    // manually clear the queue
    function claimProcess() public {
        try dividendDistributor.process(distributorGas) {} catch {}
    }

    function swapBackInBnb() internal swapping {
        // Swap is limited to swapTheshold value to protect holders
        uint256 contractTokenBalance = swapThreshold;

        uint256 totalSwapFee = totalFees.sub(totalBurnFee);
        uint256 amountToLiquify = contractTokenBalance
            .mul(totalLiquidityFee)
            .div(totalSwapFee)
            .div(2);
        uint256 tokensToSwap = contractTokenBalance.sub(amountToLiquify);

        // Exchange tokens for BNB
        swapTokensForBNB(tokensToSwap);

        // Get swapped BNB amount
        uint256 swappedBnbAmount = address(this).balance;

        uint256 totalBNBFee = totalSwapFee.sub(totalLiquidityFee.div(2));

        uint256 liquidityFeeBnb = swappedBnbAmount
            .mul(totalLiquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 marketingFeeBnb = swappedBnbAmount.mul(totalMarketingFee).div(
            totalBNBFee
        );
        uint256 rewardsFeeBnb = swappedBnbAmount
            .mul(totalDividendRewardsFee)
            .div(totalBNBFee);
        uint256 charityFeeBnb = swappedBnbAmount.mul(totalCharityFee).div(
            totalBNBFee
        );
        uint256 devFeeBnb = swappedBnbAmount
            .sub(liquidityFeeBnb)
            .sub(marketingFeeBnb)
            .sub(rewardsFeeBnb)
            .sub(charityFeeBnb);

        if (amountToLiquify > 0) {
            // Create LP
            createSCTLP(amountToLiquify, liquidityFeeBnb);
        }

        if (rewardsFeeBnb > 0) {
            // Send BNB for rewards to distributor
            try dividendDistributor.deposit{value: rewardsFeeBnb}() {} catch {}
        }

        if (marketingFeeBnb > 0) {
            (bool marketingSuccess, ) = payable(marketingFeeReceiver).call{
                value: marketingFeeBnb,
                gas: 30000
            }("");
            // only to supress warning msg
            marketingSuccess = false;
        }

        if (charityFeeBnb > 0) {
            (bool charitySuccess, ) = payable(charityFeeReceiver).call{
                value: charityFeeBnb,
                gas: 30000
            }("");
            // only to supress warning msg
            charitySuccess = false;
        }

        if (devFeeBnb > 0) {
            (bool devSuccess, ) = payable(devFeeReceiver).call{
                value: devFeeBnb,
                gas: 30000
            }("");
            // only to supress warning msg
            devSuccess = false;
        }
    }

    function swapBackInTokens() internal swapping {
        // Swap is limited to swapTheshold value to protect holders
        uint256 contractTokenBalance = swapThreshold;
        uint256 totalSwapFee = totalFees.sub(totalBurnFee);

        uint256 amountToLiquify = contractTokenBalance
            .mul(totalLiquidityFee)
            .div(totalSwapFee)
            .div(2);
        uint256 rewardsFeeTokens = contractTokenBalance
            .mul(totalDividendRewardsFee)
            .div(totalSwapFee);

        uint256 tokensToSwap = rewardsFeeTokens.add(amountToLiquify);

        // Exchange tokens for BNB
        swapTokensForBNB(tokensToSwap);

        // Get swapped BNB amount
        uint256 swappedBnbAmount = address(this).balance;

        uint256 totalBNBFee = totalDividendRewardsFee.add(
            totalLiquidityFee.div(2)
        );

        uint256 liquidityFeeBnb = swappedBnbAmount
            .mul(totalLiquidityFee)
            .div(totalBNBFee)
            .div(2);
        uint256 rewardsFeeBnb = swappedBnbAmount
            .mul(totalDividendRewardsFee)
            .div(totalBNBFee);

        uint256 tokensForFee = contractTokenBalance.sub(rewardsFeeTokens).sub(
            amountToLiquify.mul(2)
        );

        if (amountToLiquify > 0) {
            createSCTLP(amountToLiquify, liquidityFeeBnb);
        }

        if (rewardsFeeBnb > 0) {
            try dividendDistributor.deposit{value: rewardsFeeBnb}() {} catch {}
        }

        // Send remaining tokens for token to token swap
        if (tokensForFee > 0) {
            swapAndSendFees(tokensForFee);
        }
    }

    function swapAndSendFees(uint256 tokensForFee) private {
        uint256 totalSwapFee = totalMarketingFee.add(totalDevFee).add(
            totalCharityFee
        );

        // // swap tokens
        swapTokensForTokens(tokensForFee, SWAPTOKEN);

        uint256 currentTokenBalance = IERC20(SWAPTOKEN).balanceOf(
            address(this)
        );

        uint256 marketingToken = currentTokenBalance.mul(totalMarketingFee).div(
            totalSwapFee
        );
        uint256 charityToken = currentTokenBalance.mul(totalCharityFee).div(
            totalSwapFee
        );
        uint256 devToken = currentTokenBalance.sub(marketingToken).sub(
            charityToken
        );

        //send tokens to wallets
        if (marketingToken > 0) {
            _approve(address(this), marketingFeeReceiver, marketingToken);
            IERC20(SWAPTOKEN).transfer(marketingFeeReceiver, marketingToken);
            emit SendFeesInToken(marketingFeeReceiver, marketingToken);
        }

        if (devToken > 0) {
            _approve(address(this), devFeeReceiver, devToken);
            IERC20(SWAPTOKEN).transfer(devFeeReceiver, devToken);
            emit SendFeesInToken(devFeeReceiver, devToken);
        }

        if (charityToken > 0) {
            _approve(address(this), charityFeeReceiver, charityToken);
            IERC20(SWAPTOKEN).transfer(charityFeeReceiver, charityToken);
            emit SendFeesInToken(charityFeeReceiver, charityToken);
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForTokens(uint256 tokenAmount, address tokenToSwap)
        private
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = tokenToSwap;
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );
    }

    function createSCTLP(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LPReceiver,
            block.timestamp
        );
        emit AutoLiquify(bnbAmount, tokenAmount);
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            dividendDistributor.setShare(holder, 0);
        } else {
            dividendDistributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFeeReceivers(
        address _marketingFeeReceiver,
        address _charityFeeReceiver,
        address _LPReceiver,
        address _devFeeReceiver
    ) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        charityFeeReceiver = _charityFeeReceiver;
        LPReceiver = _LPReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external onlyOwner {
        dividendDistributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution
        );
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function claimTokens(
        address from,
        address[] calldata addresses,
        uint256[] calldata tokens
    ) external onlyOwner {
        uint256 SCCC = 0;

        require(
            addresses.length == tokens.length,
            "Mismatch between Address and token count"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Not enough tokens to airdrop");

        for (uint256 i = 0; i < addresses.length; i++) {
            _basicTransfer(from, addresses[i], tokens[i]);
            if (!isDividendExempt[addresses[i]]) {
                try
                    dividendDistributor.setShare(
                        addresses[i],
                        _balances[addresses[i]]
                    )
                {} catch {}
            }
        }

        // Dividend tracker
        if (!isDividendExempt[from]) {
            try dividendDistributor.setShare(from, _balances[from]) {} catch {}
        }
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setWalletLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 1000);
        _maxWalletAmount = amount;
    }

    function startTrading() external onlyOwner {
        tradingStart = true;
    }
}