/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 < 0.9.0;


// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


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

// File: contracts/NEREUS.sol


interface IStakingPool {
    function totalStaked() external view returns (uint);
    function fund() external payable;
}


/// @title King Nereus (NRS) token contract
/// @notice For lines that are marked ERC20 Token Standard, learn more at https://eips.ethereum.org/EIPS/eip-20.
contract NEREUS is IERC20, Ownable, Pausable {

    // ERC20 Token Standard
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private _name;
    string private _symbol;

    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) public AMMPairs;

    mapping(address => bool) public isBlacklisted;

    IUniswapV2Router02 internal _uniswapV2Router;

    IUniswapV2Pair internal _uniswapV2Pair;

    address public treasury;

    IStakingPool public stakingContract;

    uint8 public maxSellAmountPercent;
    
    /*
        Tax rate = (_taxXXX / 10**_tax_XXXDecimals) percent.
        For example: if _buyTax is 1 and _taxTreasuryDecimals is 2.
        Tax rate = 0.01%

        If you want tax rate for staking to be 5% for example,
        set _buyTax to 5 and _taxTreasuryDecimals to 0.
        5 * (10 ** 0) = 5
    */

    // Decimals of taxTreasury. Used for have tax less than 1%.
    uint8 private _taxTreasuryDecimals;

    // This percent of a transaction will be transferred to Treasury wallet.
    uint8 private _buyTax;
    uint8 private _sellTax; 

    // Total amount of tokens burnt.
    uint256 private _totalBurnt;

    // A threshold before swap staking tax.
    uint256 private _minTokensBeforeSwap;

    // Total amount of tokens collected as tax.
    uint256 private _totalTaxCollected;

    // Whether a previous call of swapTokensForEth process is still in process.
    bool private _inSwap;

    bool private _treasuryRewardEnabled;
    
    // Prevent reentrancy.
    modifier lock {
        require(!_inSwap, "currently in swap.");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    // Return values of _getValues function.
    struct ValuesFromAmount {
        // Amount of tokens for to transfer.
        uint256 amount;
        // Tax that goes to treasury wallet.
        uint256 tTreasuryFee;
        // Amount tokens after fees.
        uint256 tTransferAmount;
    }

    /* ========== EVENTS ========== */
    event Airdrop(uint256 amount);
    event AMMPairUpdated(address pair, bool value);
    event Burn(address from, uint256 amount);
    event DisabledTreasuryReward();
    event EnabledTreasuryReward();
    event ExcludeAccountFromFee(address account);
    event IncludeAccountInFee(address account);
    event MinTokensBeforeSwapUpdated(uint256 previous, uint256 current);
    event StakingContractAddressUpdated(address previous, address current);
    event TaxTreasuryUpdate(uint8 previousBuyTax, uint8 previousSellTax, uint8 previousDecimals, uint8 currentBuyTax, uint8 currentSellTax, uint8 currentDecimal);
    event TreasuryAddressUpdated(address previous, address current);    

    
    constructor () {
        // Sets the values for `name`, `symbol`, `decimals` and `totalSupply`.
        _name = "King Nereus";
        _symbol = "NRS";
        _decimals = 9; 
        _totalSupply = 10 ** 12 * (10 ** _decimals); // 1 Trillion

        // Mint
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        // exclude owner and this contract from fee.
        excludeAccountFromFee(owner());
        excludeAccountFromFee(address(this));

        uint8 buyTax_ = 10;
        uint8 sellTax_ = 15;
        uint8 _taxDecimals = 0;

        uint8 _maxSellAmount = 4; // 4% of total liquidity tokens
        uint256 minTokensBeforeSwap_ = 500 * (10 ** 6) * (10 ** _decimals); // 500 Million

        /**
         * @dev Choose proper router address according to your network:
         * Ethereum: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D (Uniswap)
         * BSC mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E (PancakeSwap)
         * BSC testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
         */
        address _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        address _treasury = _msgSender();
        address _stakingPool = address(0x70d2dE87B242E1a2257F3A1C642185717a275388);

        enableTreasuryTax(buyTax_, sellTax_, _taxDecimals, _treasury);
        changeMaxSellAmountPercent(_maxSellAmount);

        initSwap(_routerAddress);
        setStakingContract(_stakingPool, minTokensBeforeSwap_);
    }

    // allow the contract to receive ETH
    receive() external payable {}

    
    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    /// @dev Returns the symbol of the token, usually a shorter version of the name.
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /// @dev See {IERC20-totalSupply}.
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @dev See {IERC20-balanceOf}.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, recipient, amount);
        return true;
    }
    
    /// @dev See {IERC20-allowance}.
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
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual whenNotPaused {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "Blacklisted address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        if (sender != owner() && recipient != owner()) {
            _beforeTokenTransfer(sender);
        }

        bool buying = false;

        if( // BUY
            AMMPairs[sender] &&
            recipient != address(_uniswapV2Router) //pair -> router is changing liquidity
        ) {
            buying = true;
        }

        bool selling = false;

        if ( // SELL
            AMMPairs[recipient] &&
            !_isExcludedFromFee[sender]
        ) {
            require(amount <= getReservePercent(maxSellAmountPercent), "Sell transfer amount exceeds max limit");

            selling = true;
        }

        ValuesFromAmount memory values = _getValues(
            amount,
            !(!_isExcludedFromFee[sender] || (buying && !_isExcludedFromFee[recipient])),
            selling, 
            buying
        );

        unchecked {
            _balances[sender] = _balances[sender] - values.amount;
        }
        _balances[recipient] += values.tTransferAmount;

        emit Transfer(sender, recipient, values.tTransferAmount);

        if (!_isExcludedFromFee[sender] || (buying && !_isExcludedFromFee[recipient])) {
            _afterTokenTransfer(values, selling, buying);
        }
    }

    function _beforeTokenTransfer(address sender) internal virtual {
        if (_treasuryRewardEnabled && 
            !_inSwap &&
            !AMMPairs[sender]
            ) {
            // uint tokensToSwap = getReservePercent(maxSellAmountPercent);
            uint tokensToSwap = _minTokensBeforeSwap;
            bool overMinTokensBeforeSwap = _totalTaxCollected >= tokensToSwap && tokensToSwap > 0;
            if (overMinTokensBeforeSwap) {

                // Contract's current ETH balance.
                uint256 initialBalance = address(this).balance;
                sendFeeInEthToAddress(address(this), tokensToSwap);
                _totalTaxCollected -= tokensToSwap;

                // Figure out the exact amount of tokens received from swapping.
                uint256 ethReceived = address(this).balance - initialBalance;

                uint receivedx20 = ethReceived * 20;
                uint percentx20 = receivedx20 / 100;
                uint percentx80 = ethReceived - percentx20;

                (bool success,) = treasury.call{value: percentx80}("");
                require(success, "failed to send ether");

                if (address(stakingContract) == address(0)) { return; }
                uint stakedTotal = stakingContract.totalStaked();
                if (stakedTotal == 0) { return; }
                stakingContract.fund{value: percentx20}();                
            }
        }
    }
    
    /// @dev Performs all the functionalities that are enabled.
    function _afterTokenTransfer(ValuesFromAmount memory values, bool selling, bool buying) internal virtual {    
        
        if (buying || selling) {
            if (_treasuryRewardEnabled) {
                _balances[address(this)] += values.tTreasuryFee;
                _totalTaxCollected += values.tTreasuryFee;
            }
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Burn} event indicating the amount burnt.
     * Emits a {Transfer} event with `to` set to the burn address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual whenNotPaused {
        require(account != address(0), "ERC20: burn from the zero address");
        require(!isBlacklisted[account], "Blacklisted address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        _totalBurnt += amount;

        emit Burn(account, amount);
        emit Transfer(account, address(0), amount);
    }
    
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /// @dev Returns the total number of tokens burnt. 
    function totalBurnt() external view virtual returns (uint256) {
        return _totalBurnt;
    }
    
    /// @dev Returns the address of this token and WETH pair.
    function uniswapV2Pair() public view virtual returns (address) {
        return address(_uniswapV2Pair);
    }

    function buyTax() public view virtual returns (uint8) {
        return _buyTax;
    }

    function sellTax() public view virtual returns (uint8) {
        return _sellTax;
    }

    function taxTreasuryDecimals() public view virtual returns (uint8) {
        return _taxTreasuryDecimals;
    }

    function treasuryRewardEnabled() public view virtual returns (bool) {
        return _treasuryRewardEnabled;
    }

    function minTokensBeforeSwap() external view virtual returns (uint256) {
        return _minTokensBeforeSwap;
    }
    
    /// @dev Returns whether an account is excluded from fee. 
    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }        
    
    /**
     * @dev Airdrop tokens to all holders that are included from reward. 
     *  Requirements:
     * - the caller must have a balance of at least `amount`.
     */
    function airdrop(uint256 amount) public whenNotPaused {
        address sender = _msgSender();
        require(!isBlacklisted[_msgSender()], "Blacklisted address");
        require(balanceOf(sender) >= amount, "The caller must have balance >= amount.");

        ValuesFromAmount memory values = _getValues(amount, false, false, false);
        _balances[sender] -= values.amount;
        
        emit Airdrop(amount);
    }

    /// @dev returns the total amount of tokens staked in the staking contract.
    function totalStakedInPool() public view returns (uint256) {
        uint stakedTotal = stakingContract.totalStaked();
        return stakedTotal;
    }

    function getReservePercent(uint8 percent) public view returns (uint256) {
        uint112 reserve;
        if (_uniswapV2Pair.token0() == address(this))
            (reserve,,) = _uniswapV2Pair.getReserves();
        else
            (,reserve,) = _uniswapV2Pair.getReserves();

        return _calculateTax(uint256(reserve), percent, 0);
    }

    /**
     * @dev Swap `amount` tokens for ETH and send to `to`
     *
     * Emits {Transfer} event. From this contract to the token and WETH Pair.
     */
    function swapTokensForEth(uint256 amount, address to) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        // Approve uniswapV2Router to spend tokens
        uint currentAllowance = _allowances[address(this)][address(_uniswapV2Router)];
        if(currentAllowance < amount) {
            _approve(address(this), address(_uniswapV2Router), type(uint256).max - currentAllowance);
        }


        // Swap tokens to ETH
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount, 
            0, 
            path, 
            to,
            block.timestamp + 60 * 1000
            );
    }
    
    /**
     * @dev Returns fees and transfer amount in tokens.
     * tXXXX stands for tokenXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getValues(uint256 amount, bool deductTransferFee, bool selling, bool buying) private view returns (ValuesFromAmount memory) {
        ValuesFromAmount memory values;
        values.amount = amount;
        _getTValues(values, deductTransferFee, selling, buying);
        return values;
    }

    /**
     * @dev Adds fees and transfer amount in tokens to `values`.
     * tXXXX stands for tokenXXXX
     * More details can be found at comments for ValuesForAmount Struct.
     */
    function _getTValues(ValuesFromAmount memory values, bool deductTransferFee, bool selling, bool buying) view private {
        
        if (deductTransferFee) {
            values.tTransferAmount = values.amount;
        } else {
            // calculate fee
            if (buying || selling) {
                uint8 _taxTreasury;
                if(buying) { _taxTreasury = _buyTax; }
                if(selling) { _taxTreasury = _sellTax; }
                values.tTreasuryFee = _calculateTax(values.amount, _taxTreasury, _taxTreasuryDecimals);
            }
            
            // amount after fee
            values.tTransferAmount = values.amount - values.tTreasuryFee;
        }
        
    }
    
    /// @dev Returns fee based on `amount` and `taxRate`
    function _calculateTax(uint256 amount, uint8 tax, uint8 taxDecimals_) private pure returns (uint256) {
        return amount * tax / (10 ** taxDecimals_) / (10 ** 2);
    }

    function sendFeeInEthToAddress(address addr, uint256 tAmount) private lock {
        if (tAmount>0) {
            swapTokensForEth(tAmount, addr);
        }
    }


    /* ========== OWNER FUNCTIONS ========== */

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

     /**
      * @dev Excludes an account from fee.
      *
      * Emits a {ExcludeAccountFromFee} event.
      *
      * Requirements:
      *
      * - `account` is included in fee.
      */
    function excludeAccountFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;

        emit ExcludeAccountFromFee(account);
    }

    /**
      * @dev Includes an account from fee.
      *
      * Emits a {IncludeAccountFromFee} event.
      *
      * Requirements:
      *
      * - `account` is excluded in fee.
      */
    function includeAccountInFee(address account) public onlyOwner {
        require(_isExcludedFromFee[account], "Account is already included.");

        _isExcludedFromFee[account] = false;
        
        emit IncludeAccountInFee(account);
    }

    function blacklistAddress(address addr, bool value) external onlyOwner {
        isBlacklisted[addr] = value;
    }

    function enableTreasuryTax(uint8 buyTax_, uint8 sellTax_, uint8 taxTreasuryDecimals_, address treasury_) public onlyOwner {
        require(!_treasuryRewardEnabled, "Treasury tax feature is already enabled.");
        require(buyTax_ > 0 && sellTax_ > 0, "Tax must be greater than 0.");
        require(taxTreasuryDecimals_ + 2  <= decimals(), "Tax decimals must be less than token decimals - 2");

        _treasuryRewardEnabled = true;
        setTreasuryTax(buyTax_, sellTax_, taxTreasuryDecimals_);
        setTreasuryAddress(treasury_);

        emit EnabledTreasuryReward();
    }

    function disableTreasuryTax() public onlyOwner {
        require(_treasuryRewardEnabled, "Treasury reward feature is already disabled.");

        setTreasuryTax(0, 0, 0);
        setTreasuryAddress(address(0x0));
        _treasuryRewardEnabled = false;
        
        emit DisabledTreasuryReward();
    }

    function initSwap(address routerAddress) public onlyOwner {
        // init Router
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(routerAddress);

        address uniswapV2Pair_ = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());

        if (uniswapV2Pair_ == address(0)) {
            uniswapV2Pair_ = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }
        
        _uniswapV2Router = uniswapV2Router;
        _approve(address(this), address(_uniswapV2Router), type(uint256).max);
        _uniswapV2Pair = IUniswapV2Pair(uniswapV2Pair_);

        _setAMMPair(uniswapV2Pair_, true);

        // exclude uniswapV2Router from paying fees.
        excludeAccountFromFee(address(uniswapV2Router));
        // exclude WETH and this Token Pair from paying fees.
        // excludeAccountFromFee(uniswapV2Pair_);
        // Account already exluded in _setAMMPair
    }

    function setAMMPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair(), "The main pair cannot be removed from AMMPairs.");

        _setAMMPair(pair, value);
    }

    function _setAMMPair(address pair, bool value) private {
        AMMPairs[pair] = value;

        if(value) {
            excludeAccountFromFee(pair);
        }

        emit AMMPairUpdated(pair, value);
    }

    function setTreasuryTax(uint8 buyTax_, uint8 sellTax_, uint8 taxTreasuryDecimals_) public onlyOwner {
        require(_treasuryRewardEnabled, "Treasury reward feature must be enabled. Try the enableTreasuryTax function.");

        uint8 previousBuyTax = _buyTax;
        uint8 previousSellTax = _sellTax;
        uint8 previousDecimals = _taxTreasuryDecimals;
        _buyTax = buyTax_;
        _sellTax = sellTax_;
        _taxTreasuryDecimals = taxTreasuryDecimals_;

        emit TaxTreasuryUpdate(previousBuyTax, previousSellTax, previousDecimals, buyTax_, sellTax_, taxTreasuryDecimals_);
    }

    function setTreasuryAddress(address treasury_) public onlyOwner {
        require(treasury != treasury_, "New treasury address must be different than old one.");

        address previous = treasury;
        treasury = treasury_;

        emit TreasuryAddressUpdated(previous, treasury_);
    }

    function setStakingContract(address stakingContract_, uint256 minTokensBeforeSwap_) public onlyOwner {
        address previous = address(stakingContract);
        stakingContract = IStakingPool(stakingContract_);

        setMinTokensBeforeSwap(minTokensBeforeSwap_);

        emit StakingContractAddressUpdated(previous, stakingContract_);
    }    

    function changeMaxSellAmountPercent(uint8 amount) public onlyOwner {
        maxSellAmountPercent = amount;
    }

    /**
      * @dev Updates `_minTokensBeforeSwap`
      *
      * Emits a {MinTokensBeforeSwap} event.
      *
      * Requirements:
      *
      * - `minTokensBeforeSwap_` must be less than _totalSupply .
      */
    function setMinTokensBeforeSwap(uint256 minTokensBeforeSwap_) public onlyOwner {
        require(minTokensBeforeSwap_ < _totalSupply , "minTokensBeforeSwap must be lower than current supply.");

        uint256 previous = _minTokensBeforeSwap;
        _minTokensBeforeSwap = minTokensBeforeSwap_;

        emit MinTokensBeforeSwapUpdated(previous, minTokensBeforeSwap_);
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw this token");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverETH(uint256 ethAmount) public virtual onlyOwner returns (bool success) {
        (success,) = owner().call{value: ethAmount}("");
    }
}