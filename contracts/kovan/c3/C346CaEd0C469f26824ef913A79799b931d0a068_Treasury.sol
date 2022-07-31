//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./interfaces/ITreasury.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Treasury Contract
/// @notice Contract taking care of:
/// - rewarding users for the executions of scripts
/// - taking care of rewards distributions to users that staked DAEM
/// - holds the commissions money, until it's withdrawn by the owner
/// - buy and hold the DAEM-ETH LP
contract Treasury is ITreasury, Ownable {
    address private gasTank;
    IERC20 private token;
    address private lpRouter;

    uint16 public PERCENTAGE_COMMISSION = 100;
    uint16 public PERCENTAGE_POL = 4900;
    // the remaining percentage will be redistributed

    uint16 public PERCENTAGE_POL_TO_ENABLE_BUYBACK = 1000;

    uint16 public override TIPS_AFTER_TAXES_PERCENTAGE = 8000;

    uint256 public redistributionPool;
    uint256 public commissionsPool;
    uint256 public polPool;
    address public polLp;
    address[] private ethToDAEMPath;

    // staking vars
    uint256 public redistributionInterval = 180 days;
    uint256 public stakedAmount;
    uint256 public distributed;
    uint256 private lastUpdateTime;
    uint256 private rewardPerTokenStored;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _token,
        address _gasTank,
        address _lpRouter
    ) {
        require(_token != address(0));
        token = IERC20(_token);
        gasTank = _gasTank;
        lpRouter = _lpRouter;
        ethToDAEMPath = new address[](2);
        ethToDAEMPath[0] = IUniswapV2Router01(lpRouter).WETH();
        ethToDAEMPath[1] = address(token);
    }

    /* ========== VIEWS STAKING ========== */

    /// @inheritdoc ITreasury
    function tokensForDistribution() external view override returns (uint256) {
        return token.balanceOf(address(this)) - stakedAmount;
    }

    /// @notice The staked balance of a user
    /// @param user the user that should be checked
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }

    /// @notice The amount of DAEM earned by a user
    /// @param user the user that should be checked
    function earned(address user) public view returns (uint256) {
        return
            ((balances[user] * (rewardPerToken() - userRewardPerTokenPaid[user])) / 1e18) +
            rewards[user];
    }

    function rewardPerToken() private view returns (uint256) {
        if (stakedAmount == 0) return 0;
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * getRewardRate() * 1e18) / stakedAmount);
    }

    /// @notice Number of ETH that will be distributed each second
    /// @dev This depends on the amount in the redistributionPool and
    /// the time we intend to distribute this amount in.
    function getRewardRate() public view returns (uint256) {
        return redistributionPool / redistributionInterval;
    }

    /* ========== OTHER VIEWS ========== */

    /// @inheritdoc ITreasury
    function ethToDAEM(uint256 ethAmount) public view override returns (uint256) {
        require(polLp != address(0), "PoL not initialized yet");
        return IUniswapV2Router01(lpRouter).getAmountsOut(ethAmount, ethToDAEMPath)[1];
    }

    /// @notice calculate the percentage of DAEM tokens (of the total supply on this chain)
    /// that are locked forever in the treasury-owned LP token
    function percentageDAEMTokensStoredInLP() public view returns (uint256) {
        require(polLp != address(0), "PoL not initialized yet");
        uint256 totalSupply = token.totalSupply();
        IUniswapV2Pair lp = IUniswapV2Pair(polLp);
        uint256 lpTotalSupply = lp.totalSupply();
        uint256 ownedLp = lp.balanceOf(address(this));
        (uint256 resA, uint256 resB, ) = lp.getReserves();
        uint256 DAEMInLp = lp.token0() == address(token) ? resA : resB;
        uint256 ownedDAEMInLp = (ownedLp * DAEMInLp) / lpTotalSupply;
        return (ownedDAEMInLp * 10000) / totalSupply;
    }

    /// @notice defines whether the daily treasury operation should buy back DAEM or fund the LP
    /// @dev returns true if the treasury-owned LP contains less than
    /// PERCENTAGE_POL_TO_ENABLE_BUYBACK of the total supply of DAEM on this chain.
    function shouldFundLP() public view returns (bool) {
        return percentageDAEMTokensStoredInLP() < PERCENTAGE_POL_TO_ENABLE_BUYBACK;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Stake a certain amount of DAEM tokens in the treasury
    /// @param amount the amount of tokens to stake
    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        token.transferFrom(msg.sender, address(this), amount);
        stakedAmount += amount;
        balances[msg.sender] += amount;
    }

    function stakeFor(address user, uint256 amount) private {
        require(amount > 0, "Cannot stake 0");
        // no need to move funds as the tokens are already in the treasury
        stakedAmount += amount;
        balances[user] += amount;
    }

    /// @notice Withdraw a certain amount of DAEM tokens from the treasury
    /// @param amount the amount of tokens to withdraw
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(balances[msg.sender] >= amount, "Insufficient staked funds");
        require(stakedAmount > amount, "Cannot withdraw all funds");
        stakedAmount -= amount;
        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    /// @notice Claims the earned ETH
    function getReward() public updateReward(msg.sender) {
        require(rewards[msg.sender] > 0, "Nothing to claim");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(reward);
        distributed = distributed + reward;
    }

    /// @notice Claims the earned DAEM tokens
    /// @param amountOutMin the minimum amount of DAEM token that should be received in the swap
    function compoundReward(uint256 amountOutMin)
        public
        updateReward(msg.sender)
    {
        require(rewards[msg.sender] > 0, "Nothing to claim");
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

        uint256[] memory swappedAmounts = IUniswapV2Router01(lpRouter).swapExactETHForTokens{
            value: reward
        }(amountOutMin, ethToDAEMPath, address(this), block.timestamp);
        stakeFor(msg.sender, swappedAmounts[1]);
        distributed = distributed + reward;
    }

    /// @notice Withdraw all staked DAEM tokens and claim the due ETH reward
    function exit() external {
        getReward();
        withdraw(balances[msg.sender]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice Set the address of a new GasTank
    /// @param _gasTank the new GasTank address
    function setGasTank(address _gasTank) external onlyOwner {
        gasTank = _gasTank;
    }

    /// @notice Checks whether the contract is ready to operate
    function preliminaryCheck() external view {
        require(address(gasTank) != address(0), "GasTank");
        require(token.balanceOf(address(this)) > 0, "Treasury is empty");
        require(polLp != address(0), "POL not initialized");
    }

    /// @notice Set the commission percentage value
    /// @dev this value can be at most 5%
    /// @param value the new commission percentage
    function setCommissionPercentage(uint16 value) external onlyOwner {
        require(value <= 500, "Commission must be at most 5%");
        PERCENTAGE_COMMISSION = value;
    }

    /// @notice Set the PoL percentage value
    /// @dev this value can be at most 50% and at least 5%
    /// @param value the new PoL percentage
    function setPolPercentage(uint16 value) external onlyOwner {
        require(value >= 500, "POL must be at least 5%");
        require(value <= 5000, "POL must be at most 50%");
        PERCENTAGE_POL = value;
    }

    /// @notice Defines how fast the ETH in the redistribution pool will be given out to DAEM stakers
    /// @dev this value must be between 30 and 730 days
    /// @param newInterval the new PoL percentage
    function setRedistributionInterval(uint256 newInterval) external onlyOwner {
        require(newInterval >= 30 days, "RI must be at least 30 days");
        require(newInterval <= 730 days, "RI must be at most 730 days");
        redistributionInterval = newInterval;
    }

    /// @notice Defines the threshold that will cause buybacks instead of LP funding
    /// @dev this value must be between 2.5% and 60%
    /// @param value the new percentage threshold
    function setPercentageToEnableBuyback(uint16 value) external onlyOwner {
        require(value >= 250, "POL must be at least 2.5%");
        require(value <= 6000, "POL must be at most 60%");
        PERCENTAGE_POL_TO_ENABLE_BUYBACK = value;
    }

    /// @notice Creates the Protocol-owned-Liquidity LP
    /// @param DAEMAmount the amount of DAEM tokens to be deposited in the LP, together with 100% of owned ETH
    function createLP(uint256 DAEMAmount) external payable onlyOwner {
        require(polLp == address(0), "PoL already initialized");

        // during initialization, we specify both ETH and DAEM amounts
        addLiquidity(msg.value, DAEMAmount);

        // fetch DAEM-ETH-LP address
        address lpAddress = IUniswapV2Factory(IUniswapV2Router01(lpRouter).factory()).getPair(
            ethToDAEMPath[0],
            ethToDAEMPath[1]
        );
        polLp = lpAddress;
    }

    /// @notice Sets the already existing DAEM-ETH-LP address
    /// @param lpAddress the address of the DAEM-ETH-LP
    function setPolLP(address lpAddress) external onlyOwner {
        require(polLp == address(0), "PoL already initialized");
        polLp = lpAddress;
    }

    /// @notice Adds funds to the Protocol-owned-Liquidity LP
    /// @dev Funds in the PoL pool will be used. 50% of it to buyback DAEM and then funding the LP.
    /// @param amountOutMin the minimum amount of DAEM tokens to receive during buyback
    function fundLP(uint256 amountOutMin) external onlyOwner {
        require(shouldFundLP(), "Funding forbidden. Should buyback");
        // First we buy back some DAEM at market price using half of the polPool
        IUniswapV2Router01(lpRouter).swapExactETHForTokens{value: polPool / 2}(
            amountOutMin,
            ethToDAEMPath,
            address(this),
            block.timestamp
        );

        // we send all the polPool ETH to the LP.
        // The amount of DAEM will be automatically decided by the LP to keep the ratio.
        addLiquidity(polPool / 2, token.balanceOf(address(this)));
        polPool = 0;
    }

    /// @notice Buybacks DAEM tokens using the PoL funds and keeps them in the treasury
    /// @dev 100% of funds in the PoL pool will be used to buyback DAEM.
    /// @param amountOutMin the minimum amount of DAEM tokens to receive during buyback
    function buybackDAEM(uint256 amountOutMin) external onlyOwner {
        require(!shouldFundLP(), "Buyback forbidden. Should fund");
        // We buy back some DAEM at market price using all the polPool
        IUniswapV2Router01(lpRouter).swapExactETHForTokens{value: polPool}(
            amountOutMin,
            ethToDAEMPath,
            address(this),
            block.timestamp
        );

        polPool = 0;
    }

    /// @notice Claims the commissions and send them to the contract owner wallet
    function claimCommission() external onlyOwner {
        uint256 amount = commissionsPool;
        commissionsPool = 0;
        payable(_msgSender()).transfer(amount);
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /// @inheritdoc ITreasury
    function requestPayout(address user, uint256 dueFromTips) external payable override {
        require(gasTank == _msgSender(), "Unauthorized. Only GasTank");
        uint256 payoutFromGas = calculatePayout();
        uint256 payoutFromTips = (dueFromTips * TIPS_AFTER_TAXES_PERCENTAGE) / 10000;
        token.transfer(user, payoutFromGas + payoutFromTips);
    }

    /// @inheritdoc ITreasury
    function stakePayout(address user, uint256 dueFromTips)
        external
        payable
        override
        updateReward(user)
    {
        require(gasTank == _msgSender(), "Unauthorized. Only GasTank");
        uint256 payoutFromGas = calculatePayout();
        uint256 payoutFromTips = (dueFromTips * TIPS_AFTER_TAXES_PERCENTAGE) / 10000;
        stakeFor(user, payoutFromGas + payoutFromTips);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function calculatePayout() private returns (uint256) {
        // split funds
        commissionsPool += (msg.value * PERCENTAGE_COMMISSION) / 10000;
        polPool += (msg.value * PERCENTAGE_POL) / 10000;
        redistributionPool +=
            (msg.value * (10000 - PERCENTAGE_COMMISSION - PERCENTAGE_POL)) /
            10000;

        // calculate payout
        return ethToDAEM(msg.value);
    }

    function addLiquidity(uint256 amountETH, uint256 amountDAEM) private {
        if (token.allowance(address(this), lpRouter) < 0xffffffffffffffffffff)
            token.approve(lpRouter, type(uint256).max);

        IUniswapV2Router01(lpRouter).addLiquidityETH{value: amountETH}(
            address(token),
            amountDAEM,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITreasury {
    /// @notice The percentage that will be given to the executor after the taxes on tips have been calculated
    function TIPS_AFTER_TAXES_PERCENTAGE() external view returns (uint16);

    /// @notice The amount of DAEM tokens left to be distributed
    function tokensForDistribution() external view returns (uint256);

    /// @notice Function called by the gas tank to initialize a payout to the specified user
    /// @param user the user to be paid
    /// @param dueFromTips the amount the user earned via DAEM tips
    function requestPayout(address user, uint256 dueFromTips) external payable;

    /// @notice Function called by the gas tank to immediately stake the payout of the specified user
    /// @param user the user to be paid
    /// @param dueFromTips the amount the user earned via DAEM tips
    function stakePayout(address user, uint256 dueFromTips) external payable;

    /// @notice Given an amount of Ethereum, calculates how many DAEM it corresponds to
    /// @param ethAmount the ethereum amount
    function ethToDAEM(uint256 ethAmount) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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