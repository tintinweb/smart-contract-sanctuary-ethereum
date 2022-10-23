//https://lockjaw.finance/

pragma solidity ^0.8.5;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

contract LOCKJAW is ERC20, Ownable {

    // store addresses that are automatic market maker pairs. 
    // transfer *to* these addresses could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public blacklist;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    address public marketingWallet;
    address public LOCKJAWWallet;
    address public devWallet= 0x96bA30287fc4A23e32a728c22777672D81e409c7;

    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public swapEnabled;
    bool public limitsEnabled;
    bool public txDelayEnabled;
    bool public tradingEnabled;

    uint256 public buyTotalFees = 8; 
    uint256 public buyDivisorFees = 4;
    
    uint256 public sellWindow1 = 30 minutes;   
    uint256 public sellWindow2 = 90 minutes; 
    uint256 public sellWindow3 = 180 minutes; 
    uint256 public sellWindow4 = 360 minutes; 
    
    uint256 public sellLiquidityFeeWindow1 = 2;
    uint256 public sellLiquidityFeeWindow2 = 2;
    uint256 public sellLiquidityFeeWindow3 = 2;
    uint256 public sellLiquidityFeeWindow4 = 2;

    uint256 public sellMarketingFeeWindow1 = 4;
    uint256 public sellMarketingFeeWindow2 = 4;
    uint256 public sellMarketingFeeWindow3 = 4;
    uint256 public sellMarketingFeeWindow4 = 4;

    uint256 public sellLOCKJAWFee = 1;
    uint256 public sellDevFee = 1; 
 
    uint256 public tokensForLiquidity;   
    uint256 public tokensForMarketing;
    uint256 public tokensForLOCKJAW;
    uint256 public tokensForDev;

    bool private swapping;
    
    /******************/

    // exclude from fees and max transaction amount, track latest buy and transfer...
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;

    mapping(address => uint256) private _latestSwapIn;
    mapping(address => uint256) private _latestTransfer; 

    event UpdateUniswapV2Router(address indexed newAddr, address indexed oldAddr);
    event ExcludeFromFees(address indexed newAddr, bool isExcluded);
    event Blacklisted(address newAddr, bool isBlacklisted);
    event SetAutomatedMarketMakerPair(address indexed newAddr, bool indexed isPair);
    event MarketingWalletUpdated(address indexed newAddr, address indexed oldAddr);
    event LOCKJAWWalletUpdated(address indexed newAddr, address indexed oldAddr);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("LOCKJAW INU", "LOCKJAW") {
        
        IUniswapV2Router02 _uniswapV2Router = 
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        
        uint256 totalSupply = 69000000 ether;
        
        maxTransactionAmount = totalSupply * 4 / 100; //3% 
        maxWallet = totalSupply * 5 / 100; //5% 
        swapTokensAtAmount = totalSupply * 6 / 100000; //.005% 
        
        marketingWallet = address(owner());
        LOCKJAWWallet = address(owner());   

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        limitsEnabled = true;
        txDelayEnabled = true;
        
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function enableTradingAndSwapping() external onlyOwner returns (bool) {
        require(!tradingEnabled && !swapEnabled, 
        "trading and swapping must not be enabled already");

        tradingEnabled = true;
        swapEnabled = true;
        return true;
    }
    
    function removeLimits() external onlyOwner returns (bool) {
        require(!limitsEnabled, 
        "limits must not be removed already");

        limitsEnabled = false;
        return true;
    }
    
    function disableTransferDelay() external onlyOwner returns (bool) {
        require(txDelayEnabled, 
        "tx delay must not already be enabled");

        txDelayEnabled = false;
        return true;
    }

    function updateBlacklist(address addr, bool isBlacklisted) external onlyOwner returns (bool) {
        require(addr != address(0), 
        "must not blacklist the zero address");

        blacklist[addr] = isBlacklisted;
        emit Blacklisted(addr, isBlacklisted);
        return true;
    }
    
    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner returns (bool) {
  	    require(amount >= totalSupply() * 1 / 100000, 
        "swap amount cannot be lower than 0.001% total supply.");

  	    require(amount <= totalSupply() * 5 / 1000, 
        "swap amount cannot be higher than 0.5% total supply.");

  	    swapTokensAtAmount = amount;
  	    return true;
  	}
    
    function updateMaxTransactionAmount(uint256 amount) external onlyOwner returns (bool) {
        require(amount >= (totalSupply() * 1 / 1000) / 1e18, 
        "must not be set to lower than 0.1%");

        maxTransactionAmount = amount * (10**18);
        return true;
    }

    function updateMaxWalletAmount(uint256 amount) external onlyOwner returns (bool) {
        require(amount >= (totalSupply() * 5 / 1000) / 1e18, 
        "must be set to lower than 0.5%");

        maxWallet = amount * (10**18);
        return true;
    }

    function updateMarketingWallet(address addr) external onlyOwner returns (bool) {
        emit MarketingWalletUpdated(addr, marketingWallet);
        marketingWallet = addr;
        return true;
    }
    
    function updateLOCKJAWWallet(address addr) external onlyOwner returns (bool) {
        emit LOCKJAWWalletUpdated(addr, LOCKJAWWallet);
        LOCKJAWWallet = addr;
        return true;
    }
    
    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner returns (bool) {
        swapEnabled = enabled;
        return true;
    }
    
    function updateBuyTotalFees(uint256 fee) external onlyOwner returns (bool) {  
        require(fee <= 15, 
        "must not be higher than 15%");

        buyTotalFees = fee;
        return true;
    }

    function updateBuyDivisorFees(uint256 divisor) external onlyOwner returns (bool) {  
        buyDivisorFees = divisor;
        return true;
    }

    function updateLOCKJAWSellFee(uint256 fee) external onlyOwner returns (bool) {  
        require(fee <= 15, 
        "must not be higher than 15%");

        sellLOCKJAWFee = fee;
        return true;
    }

    function updateSellWindows(
        uint256 window1, 
        uint256 window2, 
        uint256 window3, 
        uint256 window4) 
        external 
        onlyOwner
        returns (bool) 
    {
        sellWindow1 = window1;
        sellWindow2 = window2;
        sellWindow3 = window3;
        sellWindow4 = window4;
        return true;
    }

    function updateLiquidityFeeForSellWindows(
        uint256 fee1, 
        uint256 fee2, 
        uint256 fee3, 
        uint256 fee4) 
        external 
        onlyOwner 
        returns (bool) 
    {
        require(
            fee1 <= 15 && 
            fee2 <= 15 && 
            fee3 <= 15 && 
            fee4 <= 15,
            "must not be higher than 15%");

        sellLiquidityFeeWindow1 = fee1;
        sellLiquidityFeeWindow2 = fee2;
        sellLiquidityFeeWindow3 = fee3;
        sellLiquidityFeeWindow4 = fee4;
        return true;
    }

   function updateMarketingFeeForSellWindows(
        uint256 fee1, 
        uint256 fee2, 
        uint256 fee3, 
        uint256 fee4) 
        external 
        onlyOwner 
        returns (bool) 
    {
        require(
            fee1 <= 15 && 
            fee2 <= 15 && 
            fee3 <= 15 && 
            fee4 <= 15,
            "must not be higher than 15%");

        sellMarketingFeeWindow1 = fee1;
        sellMarketingFeeWindow2 = fee2;
        sellMarketingFeeWindow3 = fee3;
        sellMarketingFeeWindow4 = fee4;
        return true;
    }
 
    function excludeFromMaxTransaction(address addr, bool isExcluded) public onlyOwner returns (bool) {
        _isExcludedMaxTransactionAmount[addr] = isExcluded;
        return true;
    }

    function excludeFromFees(address addr, bool isExcluded) public onlyOwner returns (bool) {
        _isExcludedFromFees[addr] = isExcluded;
        emit ExcludeFromFees(addr, isExcluded);
        return true;
    }

    function setAutomatedMarketMakerPair(address addr, bool isPair) public onlyOwner returns (bool) {
        require(addr != uniswapV2Pair, 
        "the uniswapV2Pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(addr, isPair);
        return true;
    }

    function isExcludedFromFees(address addr) public view returns(bool) {
        return _isExcludedFromFees[addr];
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount) 
        internal 
        override 
    {
        require(from != address(0), 
        "ERC20: transfer from the zero address");

        require(to != address(0), 
        "ERC20: transfer to the zero address");

        require(!blacklist[from],
        "sender must not be blacklisted");
        
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        if (limitsEnabled){

            if (from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping)
                {
                    
                if (!tradingEnabled) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], 
                    "trading is not active.");
                }

                if (txDelayEnabled) {
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                        require(_latestTransfer[tx.origin] < block.number, 
                        "_transfer: transfer delay enabled. Only one purchase per block allowed.");
    
                        _latestTransfer[tx.origin] = block.number;
                    }
                }
                 
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, 
                        "buy transfer amount exceeds the max transaction amount.");
                        require(amount + balanceOf(to) <= maxWallet, 
                        "max wallet exceeded");
                }
                
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, 
                        "sell transfer amount exceeds the max transaction amount.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, 
                    "max wallet exceeded");
                }
            }
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]) 
        {
            swapping = true;       
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;

        if (takeFee) {

            //on sell
            if (automatedMarketMakerPairs[to]) {

                (
                    uint256 sellTotalFees, 
                    uint256 currentLiquidityFee, 
                    uint256 currentMarketingFee
                ) 

                = getSellFeesAccount(from);

                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += fees * currentLiquidityFee / sellTotalFees;
                tokensForMarketing += fees * currentMarketingFee / sellTotalFees;
                tokensForLOCKJAW += fees * sellLOCKJAWFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
            }
            //on buy
            if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {

        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees / buyDivisorFees;
                tokensForLOCKJAW += fees / buyDivisorFees;
                tokensForMarketing += fees / buyDivisorFees;
                tokensForDev += fees / buyDivisorFees;
                _latestSwapIn[to] = block.timestamp;
            }
            
            if (fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function _setAutomatedMarketMakerPair(address addr, bool isPair) private {
        automatedMarketMakerPairs[addr] = isPair;
        emit SetAutomatedMarketMakerPair(addr, isPair);
    }

    function _swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        //make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
        
    }
    
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        //add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));

        uint256 tokensToSwap = 
        (
            tokensForLiquidity + 
            tokensForMarketing + 
            tokensForLOCKJAW + 
            tokensForDev
        );

        bool success;
        
        if (contractBalance == 0 || tokensToSwap == 0) { return; }

        if (contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }
        
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / tokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;
        
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        
        uint256 ethForMarketing = ethBalance * tokensForMarketing / tokensToSwap;
        uint256 ethForLOCKJAW = ethBalance * tokensForLOCKJAW / tokensToSwap; 
        uint256 ethForDev = ethBalance * tokensForDev / tokensToSwap;
        
        uint256 ethForLiquidity = 
        (
            ethBalance - 
            ethForMarketing - 
            ethForLOCKJAW - 
            ethForDev
        );
        
        delete tokensForLiquidity;
        delete tokensForMarketing;
        delete tokensForLOCKJAW;
        delete tokensForDev;
        
        (success,) = address(LOCKJAWWallet).call{value: ethForLOCKJAW}("");
        (success,) = address(devWallet).call{value: ethForDev}("");
        
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            
            emit SwapAndLiquify(
                amountToSwapForETH, 
                ethForLiquidity, 
                tokensForLiquidity
                );
        }
        
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
    }
    
    function getSellFeesAccount(address addr) 
        public 
        view 
        returns (
        uint256 SellFeeTotal, 
        uint256 CurrentLiquidityFee, 
        uint256 CurrentMarketingFee) 
    {
        uint256 feesWithoutLiquidityAndMarketing = sellLOCKJAWFee + sellDevFee;

        if (block.timestamp < _latestSwapIn[addr] + sellWindow1) {
            
            return (
                (
                sellLiquidityFeeWindow1 + 
                sellMarketingFeeWindow1 + 
                feesWithoutLiquidityAndMarketing
                ), 

                sellLiquidityFeeWindow1, 
                sellMarketingFeeWindow1
            );
        }

        if (block.timestamp > _latestSwapIn[addr] + sellWindow1
            && block.timestamp < _latestSwapIn[addr] + sellWindow2)  {
            
            return (
                (
                sellLiquidityFeeWindow2 + 
                sellMarketingFeeWindow2 + 
                feesWithoutLiquidityAndMarketing), 

                sellLiquidityFeeWindow2, 
                sellMarketingFeeWindow2
            );
        }

        if (block.timestamp > _latestSwapIn[addr] + sellWindow2
            && block.timestamp < _latestSwapIn[addr] + sellWindow3) {
            
            return (
                (
                sellLiquidityFeeWindow3 + 
                sellMarketingFeeWindow3 + 
                feesWithoutLiquidityAndMarketing), 

                sellLiquidityFeeWindow3, 
                sellMarketingFeeWindow3
            );
        }
        if (block.timestamp > _latestSwapIn[addr] + sellWindow3) {
            
            return (
                (
                sellLiquidityFeeWindow4 + 
                sellMarketingFeeWindow4 + 
                feesWithoutLiquidityAndMarketing),

                sellLiquidityFeeWindow4, 
                sellMarketingFeeWindow4
            );
        }
    }
}