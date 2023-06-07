/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/*
Token Name ; ASAP SNIPER BOT
SYMBOL : ASAP
Auto discord dex sniper BOT
The fastest discord DEX (uniswap, pancakeswap ) sniper bot , Be the first to buy the next 1000X tokens.
Buy/sell Tax 6/6: 
Treasury : 4% 
liquidity Pool : 1%
Holders reward (paid in ether) : 1%
website : https://asapbot.xyz/
twitter : https://twitter.com/MyAsapBot
Telegram :https://t.me/myasapbot

Features
New Token listing
Manual Buy/Sell
Auto-Buying
Degen Vault
Hold & Earn

*/
/// @custom:security-contact [email protected]
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

contract ASAP is Pausable, Ownable, IERC20 {
    address constant UNISWAPROUTER =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string private constant _name = "ASAP SNIPER BOT";
    string private constant _symbol = "ASAP";

    uint256 public buyTreasuryFeeBPS = 400;
    uint256 public buyLiquidityFeeBPS = 100;
    uint256 public buyRewardFeeBPS = 100;
    uint256 public buyTotalFeeBPS = 600;

    uint256 public sellTreasuryFeeBPS = 400;
    uint256 public sellLiquidityFeeBPS = 100;
    uint256 public sellRewardFeeBPS = 100;
    uint256 public sellTotalFeeBPS = 600;

    uint256 public tokensForTreasury;
    uint256 public tokensForLiquidity;
    uint256 public tokensForRewards;

    uint256 public swapTokensAtAmount = 100000 * (10**18);
    uint256 public lastSwapTime;
    bool swapAllToken = true;

    bool public swapEnabled = true;
    bool public taxEnabled = true;
    bool public transferTaxEnabled = false;
    bool public compoundingEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;
    bool private isCompounding;

    address treasuryWallet;
    address liquidityWallet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) isBlacklisted;

    event SwapAndAddLiquidity(
        uint256 tokensSwapped,
        uint256 nativeReceived,
        uint256 tokensIntoLiquidity
    );
    event SendRewards(uint256 tokensSwapped, uint256 amount);
    event SendTreasury(uint256 tokensSwapped, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SwapEnabled(bool enabled);
    event TaxEnabled(bool enabled);
    event TransferTaxEnabled(bool enabled);
    event CompoundingEnabled(bool enabled);
    event BlacklistEnabled(bool enabled);
    event SellFeeUpdated(uint256 treasury, uint256 liquidity, uint256 reward);
    event BuyFeeUpdated(uint256 treasury, uint256 liquidity, uint256 reward);
    event WalletUpdated(address treasury, address liquidity);
    event TradingEnabled();
    event UniswapV2RouterUpdated();
    event RewardSettingsUpdated(
        bool swapEnabled,
        uint256 swapTokensAtAmount,
        bool swapAllToken
    );
    event AccountExcludedFromMaxTx(address account);
    event AccountExcludedFromMaxWallet(address account);
    event MaxWalletBPSUpdated(uint256 bps);
    event TokenRescued(address token, uint256 amount);
    event ETHRescued(uint256 amount);
    event AccountBlacklisted(address account);
    event AccountWhitelisted(address account);
    event LogErrorString(string message);

    RewardTracker public immutable rewardTracker;
    IUniswapV2Router02 public uniswapV2Router;

    address public uniswapV2Pair;

    uint256 public maxTxBPS = 50;
    uint256 public maxWalletBPS = 250;

    bool isOpen = false;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    constructor() {
        treasuryWallet = owner();
        liquidityWallet = owner();

        rewardTracker = new RewardTracker(address(this), UNISWAPROUTER);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPROUTER);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        rewardTracker.excludeFromRewards(address(rewardTracker), true);
        rewardTracker.excludeFromRewards(address(this), true);
        rewardTracker.excludeFromRewards(owner(), true);
        rewardTracker.excludeFromRewards(address(_uniswapV2Router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(rewardTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(rewardTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(rewardTracker), true);

        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ASAP: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ASAP: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function openTrading() external onlyOwner {
        isOpen = true;
        emit TradingEnabled();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            isOpen ||
                sender == owner() ||
                recipient == owner() ||
                _whiteList[sender] ||
                _whiteList[recipient],
            "Not Open"
        );

        require(!isBlacklisted[sender], "ASAP: Sender is blacklisted");
        require(!isBlacklisted[recipient], "ASAP: Recipient is blacklisted");

        require(sender != address(0), "ASAP: transfer from the zero address");
        require(recipient != address(0), "ASAP: transfer to the zero address");

        uint256 _maxTxAmount = (totalSupply() * maxTxBPS) / 10000;
        uint256 _maxWallet = (totalSupply() * maxWalletBPS) / 10000;
        require(
            amount <= _maxTxAmount || _isExcludedFromMaxTx[sender],
            "TX Limit Exceeded"
        );

        if (
            sender != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair
        ) {
            uint256 currentBalance = balanceOf(recipient);
            require(
                _isExcludedFromMaxWallet[recipient] ||
                    (currentBalance + amount <= _maxWallet),
                "Wallet hold too large amount of token"
            );
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ASAP: transfer amount exceeds balance"
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractNativeBalance = address(this).balance;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            swapEnabled && // True
            canSwap && // true
            !swapping && // swapping=false !false true
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            if (!swapAllToken) {
                contractTokenBalance = swapTokensAtAmount;
            }
            _executeSwap(contractTokenBalance, contractNativeBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if (
            sender == address(uniswapV2Pair) ||
            recipient == address(uniswapV2Pair) ||
            automatedMarketMakerPairs[recipient] ||
            automatedMarketMakerPairs[sender] ||
            transferTaxEnabled
        ) {
            takeFee = true;
        }

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (swapping || isCompounding || !taxEnabled) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;
            // selling
            if (automatedMarketMakerPairs[recipient] && sellTotalFeeBPS > 0) {
                fees = (amount * sellTotalFeeBPS) / 10000;
                tokensForTreasury +=
                    (fees * sellTreasuryFeeBPS) /
                    sellTotalFeeBPS;
                tokensForRewards += (fees * sellRewardFeeBPS) / sellTotalFeeBPS;
                tokensForLiquidity +=
                    (fees * sellLiquidityFeeBPS) /
                    sellTotalFeeBPS;
            } else if (
                automatedMarketMakerPairs[sender] && buyTotalFeeBPS > 0
            ) {
                // buying
                fees = (amount * buyTotalFeeBPS) / 10000;
                tokensForTreasury +=
                    (fees * buyTreasuryFeeBPS) /
                    buyTotalFeeBPS;
                tokensForRewards += (fees * buyRewardFeeBPS) / buyTotalFeeBPS;
                tokensForLiquidity +=
                    (fees * buyLiquidityFeeBPS) /
                    buyTotalFeeBPS;
            }
            amount -= fees;
            _executeTransfer(sender, address(this), fees);
        }

        _executeTransfer(sender, recipient, amount);

        rewardTracker.setBalance(payable(sender), balanceOf(sender));
        rewardTracker.setBalance(payable(recipient), balanceOf(recipient));
    }

    function _executeTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ASAP: transfer from the zero address");
        require(recipient != address(0), "ASAP: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ASAP: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ASAP: approve from the zero address");
        require(spender != address(0), "ASAP: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ASAP: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ASAP: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ASAP: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 native) private {
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.addLiquidityETH{value: native}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function includeToWhiteList(address[] memory _users) private {
        for (uint8 i = 0; i < _users.length; i++) {
            _whiteList[_users[i]] = true;
        }
    }

    function _executeSwap(uint256 tokens, uint256 native) private {
        if (tokens <= 0) {
            return;
        }

        uint256 swapTokensTreasury;
        if (address(treasuryWallet) != address(0)) {
            swapTokensTreasury = tokensForTreasury;
        }

        uint256 swapTokensRewards;
        if (rewardTracker.totalSupply() > 0) {
            swapTokensRewards = tokensForRewards;
        }

        uint256 swapTokensLiquidity = tokensForLiquidity / 2;
        uint256 addTokensLiquidity = tokensForLiquidity - swapTokensLiquidity;
        uint256 swapTokensTotal = swapTokensRewards +
            swapTokensTreasury +
            swapTokensLiquidity;

        uint256 initNativeBal = address(this).balance;
        swapTokensForNative(swapTokensTotal);
        uint256 nativeSwapped = (address(this).balance - initNativeBal) +
            native;

        tokensForTreasury = 0;
        tokensForRewards = 0;
        tokensForLiquidity = 0;

        uint256 nativeTreasury = (nativeSwapped * swapTokensTreasury) /
            swapTokensTotal;
        uint256 nativeRewards = (nativeSwapped * swapTokensRewards) /
            swapTokensTotal;
        uint256 nativeLiquidity = nativeSwapped -
            nativeTreasury -
            nativeRewards;

        if (nativeTreasury > 0) {
            (bool success, ) = payable(treasuryWallet).call{
                value: nativeTreasury
            }("");
            if (success) {
                emit SendTreasury(swapTokensTreasury, nativeTreasury);
            } else {
                emit LogErrorString("Wallet failed to receive treasury tokens");
            }
        }

        addLiquidity(addTokensLiquidity, nativeLiquidity);
        emit SwapAndAddLiquidity(
            swapTokensLiquidity,
            nativeLiquidity,
            addTokensLiquidity
        );

        if (nativeRewards > 0) {
            (bool success, ) = address(rewardTracker).call{
                value: nativeRewards
            }("");
            if (success) {
                emit SendRewards(swapTokensRewards, nativeRewards);
            } else {
                emit LogErrorString("Tracker failed to receive tokens");
            }
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "ASAP: account is already set to requested state"
        );
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function manualSendReward(uint256 amount, address holder)
        external
        onlyOwner
    {
        rewardTracker.manualSendReward(amount, holder);
    }

    function excludeFromRewards(address account, bool excluded)
        public
        onlyOwner
    {
        rewardTracker.excludeFromRewards(account, excluded);
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return rewardTracker.isExcludedFromRewards(account);
    }

    function setWallet(
        address payable _treasuryWallet,
        address payable _liquidityWallet
    ) external onlyOwner {
        require(
            _liquidityWallet != address(0),
            "_liquidityWallet can not be zero address!"
        );
        require(
            _treasuryWallet != address(0),
            "_treasuryWallet can not be zero address!"
        );

        treasuryWallet = _treasuryWallet;
        liquidityWallet = _liquidityWallet;

        emit WalletUpdated(treasuryWallet, liquidityWallet);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(pair != uniswapV2Pair, "ASAP: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function setBuyFee(
        uint256 _treasuryFee,
        uint256 _liquidityFee,
        uint256 _rewardFee
    ) external onlyOwner {
        buyTreasuryFeeBPS = _treasuryFee;
        buyLiquidityFeeBPS = _liquidityFee;
        buyRewardFeeBPS = _rewardFee;
        buyTotalFeeBPS = _treasuryFee + _liquidityFee + _rewardFee;
        require(buyTotalFeeBPS <= 5000, "Total buy fee is too large");
        emit BuyFeeUpdated(_treasuryFee, _liquidityFee, _rewardFee);
    }

    function setSellFee(
        uint256 _treasuryFee,
        uint256 _liquidityFee,
        uint256 _rewardFee
    ) external onlyOwner {
        sellTreasuryFeeBPS = _treasuryFee;
        sellLiquidityFeeBPS = _liquidityFee;
        sellRewardFeeBPS = _rewardFee;
        sellTotalFeeBPS = _treasuryFee + _liquidityFee + _rewardFee;
        require(sellTotalFeeBPS <= 5000, "Total sell fee is too large");
        emit SellFeeUpdated(_treasuryFee, _liquidityFee, _rewardFee);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "ASAP: automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            rewardTracker.excludeFromRewards(pair, true);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(0),
            "uniswapV2Router can not be zero address!"
        );
        require(
            newAddress != address(uniswapV2Router),
            "ASAP: the router is already set to the new address"
        );

        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;

        emit UniswapV2RouterUpdated();
    }

    function claim() public {
        rewardTracker.processAccount(payable(_msgSender()));
    }

    function compound() public {
        require(compoundingEnabled, "ASAP: compounding is not enabled");
        isCompounding = true;
        rewardTracker.compoundAccount(payable(_msgSender()));
        isCompounding = false;
    }

    function withdrawableRewardOf(address account)
        public
        view
        returns (uint256)
    {
        return rewardTracker.withdrawableRewardOf(account);
    }

    function withdrawnRewardOf(address account) public view returns (uint256) {
        return rewardTracker.withdrawnRewardOf(account);
    }

    function accumulativeRewardOf(address account)
        public
        view
        returns (uint256)
    {
        return rewardTracker.accumulativeRewardOf(account);
    }

    function getAccountInfo(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return rewardTracker.getAccountInfo(account);
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return rewardTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    function setTaxEnabled(bool _enabled) external onlyOwner {
        taxEnabled = _enabled;
        emit TaxEnabled(_enabled);
    }

    function setTransferTaxEnabled(bool _enabled) external onlyOwner {
        transferTaxEnabled = _enabled;
        emit TransferTaxEnabled(_enabled);
    }

    function setCompoundingEnabled(bool _enabled) external onlyOwner {
        compoundingEnabled = _enabled;
        emit CompoundingEnabled(_enabled);
    }

    function updateRewardSettings(
        bool _swapEnabled,
        uint256 _swapTokensAtAmount,
        bool _swapAllToken
    ) external onlyOwner {
        swapEnabled = _swapEnabled;
        swapTokensAtAmount = _swapTokensAtAmount;
        swapAllToken = _swapAllToken;

        emit RewardSettingsUpdated(
            swapEnabled,
            swapTokensAtAmount,
            swapAllToken
        );
    }

    function setMaxTxBPS(uint256 bps) external onlyOwner {
        require(bps >= 75 && bps <= 10000, "BPS must be between 75 and 10000");
        maxTxBPS = bps;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxTx[account] = excluded;
        emit AccountExcludedFromMaxTx(account);
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setMaxWalletBPS(uint256 bps) external onlyOwner {
        require(
            bps >= 175 && bps <= 10000,
            "BPS must be between 175 and 10000"
        );
        maxWalletBPS = bps;
        emit MaxWalletBPSUpdated(bps);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
        emit AccountExcludedFromMaxWallet(account);
    }

    function isExcludedFromMaxWallet(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxWallet[account];
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);

        emit TokenRescued(_token, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH rescue failed.");
        emit ETHRescued(_amount);
    }

    function blackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
        emit AccountBlacklisted(_user);
    }

    function removeFromBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "user already whitelisted");
        isBlacklisted[_user] = false;
        emit AccountWhitelisted(_user);
    }

    function blackListMany(address[] memory _users) public onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            blackList(_users[i]);
        }
    }

    function unBlackListMany(address[] memory _users) public onlyOwner {
        for (uint8 i = 0; i < _users.length; i++) {
            removeFromBlacklist(_users[i]);
        }
    }
}

contract RewardTracker is Ownable, IERC20 {
    address immutable UNISWAPROUTER;

    string private constant _name = "ASAP_RewardTracker";
    string private constant _symbol = "ASAP_RewardTracker";

    uint256 public lastProcessedIndex;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 private constant magnitude = 2**128;
    uint256 public immutable minTokenBalanceForRewards;
    uint256 private magnifiedRewardPerShare;
    uint256 public totalRewardsDistributed;
    uint256 public totalRewardsWithdrawn;

    address public immutable tokenAddress;

    mapping(address => bool) public excludedFromRewards;
    mapping(address => int256) private magnifiedRewardCorrections;
    mapping(address => uint256) private withdrawnRewards;
    mapping(address => uint256) private lastClaimTimes;

    event RewardsDistributed(address indexed from, uint256 weiAmount);
    event RewardWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromRewards(address indexed account, bool excluded);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount, uint256 tokens);
    event LogErrorString(string message);

    struct AccountInfo {
        address account;
        uint256 withdrawableRewards;
        uint256 totalRewards;
        uint256 lastClaimTime;
    }

    constructor(address _tokenAddress, address _uniswapRouter) {
        minTokenBalanceForRewards = 1 * (10**18);
        tokenAddress = _tokenAddress;
        UNISWAPROUTER = _uniswapRouter;
    }

    receive() external payable {
        distributeRewards();
    }

    function distributeRewards() public payable {
        require(_totalSupply > 0, "Total supply invalid");
        if (msg.value > 0) {
            magnifiedRewardPerShare =
                magnifiedRewardPerShare +
                ((msg.value * magnitude) / _totalSupply);
            emit RewardsDistributed(msg.sender, msg.value);
            totalRewardsDistributed += msg.value;
        }
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromRewards[account]) {
            return;
        }
        if (newBalance >= minTokenBalanceForRewards) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function excludeFromRewards(address account, bool excluded)
        external
        onlyOwner
    {
        require(
            excludedFromRewards[account] != excluded,
            "ASAP_RewardTracker: account already set to requested state"
        );
        excludedFromRewards[account] = excluded;
        if (excluded) {
            _setBalance(account, 0);
        } else {
            uint256 newBalance = IERC20(tokenAddress).balanceOf(account);
            if (newBalance >= minTokenBalanceForRewards) {
                _setBalance(account, newBalance);
            } else {
                _setBalance(account, 0);
            }
        }
        emit ExcludeFromRewards(account, excluded);
    }

    function isExcludedFromRewards(address account) public view returns (bool) {
        return excludedFromRewards[account];
    }

    function manualSendReward(uint256 amount, address holder)
        external
        onlyOwner
    {
        uint256 contractETHBalance = address(this).balance;
        (bool success, ) = payable(holder).call{
            value: amount > 0 ? amount : contractETHBalance
        }("");
        require(success, "Manual send failed.");
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if (newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(account, addAmount);
        } else if (newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _burn(account, subAmount);
        }
    }

    function _mint(address account, uint256 amount) private {
        require(
            account != address(0),
            "ASAP_RewardTracker: mint to the zero address"
        );
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        magnifiedRewardCorrections[account] =
            magnifiedRewardCorrections[account] -
            int256(magnifiedRewardPerShare * amount);
    }

    function _burn(address account, uint256 amount) private {
        require(
            account != address(0),
            "ASAP_RewardTracker: burn from the zero address"
        );
        uint256 accountBalance = _balances[account];
        require(
            accountBalance >= amount,
            "ASAP_RewardTracker: burn amount exceeds balance"
        );
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        magnifiedRewardCorrections[account] =
            magnifiedRewardCorrections[account] +
            int256(magnifiedRewardPerShare * amount);
    }

    function processAccount(address payable account)
        public
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawRewardOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }

    function _withdrawRewardOfUser(address payable account)
        private
        returns (uint256)
    {
        uint256 _withdrawableReward = withdrawableRewardOf(account);
        if (_withdrawableReward > 0) {
            withdrawnRewards[account] += _withdrawableReward;
            totalRewardsWithdrawn += _withdrawableReward;
            (bool success, ) = account.call{value: _withdrawableReward}("");
            if (!success) {
                withdrawnRewards[account] -= _withdrawableReward;
                totalRewardsWithdrawn -= _withdrawableReward;
                emit LogErrorString("Withdraw failed");
                return 0;
            }
            emit RewardWithdrawn(account, _withdrawableReward);
            return _withdrawableReward;
        }
        return 0;
    }

    function compoundAccount(address payable account)
        public
        onlyOwner
        returns (bool)
    {
        (uint256 amount, uint256 tokens) = _compoundRewardOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Compound(account, amount, tokens);
            return true;
        }
        return false;
    }

    function _compoundRewardOfUser(address payable account)
        private
        returns (uint256, uint256)
    {
        uint256 _withdrawableReward = withdrawableRewardOf(account);
        if (_withdrawableReward > 0) {
            withdrawnRewards[account] += _withdrawableReward;
            totalRewardsWithdrawn += _withdrawableReward;

            IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
                UNISWAPROUTER
            );

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(tokenAddress);

            bool success;
            uint256 tokens;

            uint256 initTokenBal = IERC20(tokenAddress).balanceOf(account);
            try
                uniswapV2Router
                    .swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: _withdrawableReward
                }(0, path, address(account), block.timestamp)
            {
                success = true;
                tokens = IERC20(tokenAddress).balanceOf(account) - initTokenBal;
            } catch Error(
                string memory /*err*/
            ) {
                success = false;
            }

            if (!success) {
                withdrawnRewards[account] -= _withdrawableReward;
                totalRewardsWithdrawn -= _withdrawableReward;
                emit LogErrorString("Withdraw failed");
                return (0, 0);
            }

            emit RewardWithdrawn(account, _withdrawableReward);
            return (_withdrawableReward, tokens);
        }
        return (0, 0);
    }

    function withdrawableRewardOf(address account)
        public
        view
        returns (uint256)
    {
        return accumulativeRewardOf(account) - withdrawnRewards[account];
    }

    function withdrawnRewardOf(address account) public view returns (uint256) {
        return withdrawnRewards[account];
    }

    function accumulativeRewardOf(address account)
        public
        view
        returns (uint256)
    {
        int256 a = int256(magnifiedRewardPerShare * balanceOf(account));
        int256 b = magnifiedRewardCorrections[account]; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountInfo(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableRewards = withdrawableRewardOf(account);
        info.totalRewards = accumulativeRewardOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableRewards,
            info.totalRewards,
            info.lastClaimTime,
            totalRewardsWithdrawn
        );
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return lastClaimTimes[account];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("ASAP_RewardTracker: method not implemented");
    }

    function allowance(address, address)
        public
        pure
        override
        returns (uint256)
    {
        revert("ASAP_RewardTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("ASAP_RewardTracker: method not implemented");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("ASAP_RewardTracker: method not implemented");
    }
}