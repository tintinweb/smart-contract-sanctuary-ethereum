/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/interfaces.sol

pragma solidity ^0.8.4;



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


// File contracts/ApolloSafePlayMultiCurrency/ApolloSafePlayL.sol

/*******************************************
 * Apollo Safe play
 */

/**
 * Apollo safe play token with liquidity
 */



pragma solidity ^0.8.14;




contract ApolloSafePlayL is Context, IERC20Metadata, Ownable {
    // Token parameters
    string private NAME;
    string private SYMBOL;
    uint8 private immutable DECIMALS;
    uint256 private _tTotal;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFee;
    // Address of pair contract from which tax is deducted
    mapping(address => bool) public isPair;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;
    IERC20 public apollo; // ApolloVenture contract address for buyback
    address public platformOwner = 0xec2B17F13615be38B4407d21ED97b921a6748e37;
    address public buyBackAddress = 0xec2B17F13615be38B4407d21ED97b921a6748e37;
    address public factory; // Address of launchpad factory
    IERC20 public raiseIn; // Address of token in which presale was raised

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    struct feeRateStruct {
        uint256 liquidity;
        uint256 buyBack;
    }

    feeRateStruct public buyFeeRates;
    feeRateStruct public sellFeeRates;

    feeRateStruct public totalFeesPaid;
    feeRateStruct public pendingToPay;

    uint256 public swapTokensAtAmount;
    uint256 public buyBackUpperLimit = 1 ether;
    uint256 public maxTxLimit;
    uint256 public constant MAX_TX_FEES = 1500;

    bool private swapping;
    bool public swapEnabled;
    bool public buyBackEnabled;

    struct valuesFromGetValues {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tBuyBack;
    }

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    event FeesChanged();

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        feeRateStruct memory _txFeeRates,
        address _router,
        IERC20 _apollo,
        address[] memory currency, // Possible token address on chain that can be used to raise presale
        address _factory
    ) {
        require(_factory != address(0), "Invalid address");
        NAME = _name;
        SYMBOL = _symbol;
        DECIMALS = _decimals;
        swapTokensAtAmount = 100_000 * 10**DECIMALS;
        maxTxLimit = 500_000 * 10**DECIMALS;

        require(
            (_txFeeRates.liquidity + _txFeeRates.buyBack) <= MAX_TX_FEES,
            "Total Tx fees exceeds limit"
        );

        buyFeeRates = _txFeeRates;
        sellFeeRates = _txFeeRates;

        factory = _factory;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        uniswapV2Router = IUniswapV2Router02(_router);
        // Setting default pair as pair of BNB and token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isPair[uniswapV2Pair] = true;

        // Making all possible pair and setting true in mapping
        if (currency.length > 0) {
            address pair;
            for (uint256 i; i < currency.length; i++) {
                pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                    address(this),
                    currency[i]
                );
                isPair[pair] = true;
            }
        }
        apollo = _apollo;

        _mint(owner(), _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return NAME;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return SYMBOL;
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
        return DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address account, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[account][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _tTotal += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _tTotal -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `account` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address account,
        address spender,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= balanceOf(sender),
            "ERC20: transfer amount exceeds balance"
        );

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (
            !swapping &&
            swapEnabled &&
            canSwap &&
            !isPair[sender] && // Should not be a buy tx
            balanceOf(uniswapV2Pair) > 0 // To ensure liquidity as we are going to swap tokens for BNB or raiseIn token
        ) {
            uint256 balance = address(this).balance;

            if (
                buyBackEnabled &&
                balance >= buyBackUpperLimit &&
                isPair[recipient] &&
                (block.chainid == 56 || block.chainid == 97)
            ) {
                balance = buyBackUpperLimit;
                buyBackTokens(balance / 100);
            }
            swapAndLiquify();
        }

        _tokenTransfer(
            sender,
            recipient,
            amount,
            !(isExcludedFromFee[sender] || isExcludedFromFee[recipient])
        );
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Customization

    /// @dev Will be called by factory whenever presale of ASP is created
    /// @param _raiseIn address in which presale is being raised
    function setRaiseInAddress(address _raiseIn) external {
        require(
            msg.sender == factory || msg.sender == owner(),
            "Only owner or factory can call"
        );
        require(_raiseIn != address(0), "Invalid address");
        raiseIn = IERC20(_raiseIn);
        address get_pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            address(this),
            _raiseIn
        );
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), _raiseIn);
        } else {
            uniswapV2Pair = get_pair;
        }
        isPair[uniswapV2Pair] = true;
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(uniswapV2Router));
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            uniswapV2Pair = get_pair;
        }
        uniswapV2Router = _newRouter;
    }

    /**
     * @dev Setting token amount at which swap will happen
     */
    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount)
        external
        onlyOwner
    {
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    /**
     * @dev Setting maximum token amount to transfer in single trasaction
     */
    function setMaxTxLimit(uint256 _maxTxLimit) external onlyOwner {
        maxTxLimit = _maxTxLimit;
    }

    /**
     * @dev Enabling/Disabling swapping
     */
    function changeSwapStatus(bool status) external onlyOwner {
        swapEnabled = status;
    }

    /**
     * @dev Enabling/Disabling buyBack
     */
    function changeBuyBackStatus(bool status) external OnlyPlatformOwner {
        buyBackEnabled = status;
    }

    /**
     * @dev Setting amount at which buyBack will happen
     */
    function setBuybackUpperLimit(uint256 buyBackLimit)
        external
        OnlyPlatformOwner
    {
        buyBackUpperLimit = buyBackLimit;
    }

    /**
     * @dev Setting buyBack fees
     */
    function setBuyBackfees(uint256 _buyingBuyBack, uint256 _sellingBuyBack)
        external
        OnlyPlatformOwner
    {
        buyFeeRates.buyBack = _buyingBuyBack;
        sellFeeRates.buyBack = _sellingBuyBack;
    }

    /**
     * @dev Setting buyBack Address
     */
    function setBuyBackAddress(address _buyBackAddress)
        external
        OnlyPlatformOwner
    {
        require(_buyBackAddress != address(0), "Invalid address");
        buyBackAddress = _buyBackAddress;
    }

    function setApolloAddress(address _apollo) external OnlyPlatformOwner {
        require(_apollo != address(0), "Invalid address");
        apollo = IERC20(_apollo);
    }

    function setPlatformOwner(address _platformOwner)
        external
        OnlyPlatformOwner
    {
        require(_platformOwner != address(0), "Invalid address");
        platformOwner = _platformOwner;
    }

    /**
     * @dev Setting fee rates
     * Total tax should be below or equal to MAX_TX_FEES
     */
    function setFeeRates(
        feeRateStruct memory _buyFeeRates,
        feeRateStruct memory _sellFeeRates
    ) external onlyOwner {
        uint256 buyFees = _buyFeeRates.liquidity;

        uint256 sellFees = _sellFeeRates.liquidity;

        require(
            (buyFees + buyFeeRates.buyBack) <= MAX_TX_FEES &&
                (sellFees + sellFeeRates.buyBack) <= MAX_TX_FEES,
            "Total Tax above MAX_TX_FEES"
        );

        uint256 buyingBuyBack = buyFeeRates.buyBack;
        uint256 sellingBuyBack = sellFeeRates.buyBack;
        buyFeeRates = _buyFeeRates;
        sellFeeRates = _sellFeeRates;
        buyFeeRates.buyBack = buyingBuyBack;
        sellFeeRates.buyBack = sellingBuyBack;

        emit FeesChanged();
    }

    /// @dev Add pair support. Tax is deducted if this address is sender or recipient
    /// @param _pair address to add support of
    function addPairSupport(address _pair) external onlyOwner {
        require(
            IUniswapV2Pair(_pair).token0() == address(this) ||
                IUniswapV2Pair(_pair).token1() == address(this),
            "Invalid pair"
        );
        isPair[_pair] = true;
    }

    /// @dev Remove pair support. Tax isn't deducted if this address is sender or recipient
    /// @param _pair address to remove support of
    function removePairSupport(address _pair) external onlyOwner {
        require(isPair[_pair], "Pair already not supported");
        isPair[_pair] = false;
    }

    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }

    /**
     * @dev Setting factory address
     */
    function setFactoryAddress(address _factory) public ownerAndPlatformOwner {
        require(_factory != address(0), "Invalid Address");
        factory = _factory;
    }

    /**
     * @dev Calculates percentage with two decimal support.
     */
    function percent(uint256 amount, uint256 fraction)
        public
        pure
        virtual
        returns (uint256)
    {
        return ((amount) * (fraction)) / (10000);
    }

    /**
     * @dev transfers tokens from sender to recipient with or without fees
     */
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        bool isBuy;
        bool isSell;

        if (isPair[sender]) {
            isBuy = true;
        } else if (isPair[recipient]) {
            isSell = true;
        }

        valuesFromGetValues memory values = _getValues(
            amount,
            takeFee,
            isBuy,
            isSell
        );
        unchecked {
            _balances[sender] = balanceOf(sender) - amount;
        }
        _balances[recipient] = _balances[recipient] + values.tTransferAmount;
        if (takeFee && (isBuy || isSell)) {
            _takeLiquidity(values.tLiquidity);
            _takeBuyBack(values.tBuyBack);
        }

        emit Transfer(sender, recipient, values.tTransferAmount);
        emit Transfer(
            sender,
            address(this),
            values.tLiquidity + values.tBuyBack
        );
    }

    /**
     * @dev Returns tAmount and rAmount with or without fees
     */
    function _getValues(
        uint256 tAmount,
        bool takeFee,
        bool isBuy,
        bool isSell
    ) private view returns (valuesFromGetValues memory values) {
        if (!takeFee || (!isBuy && !isSell)) {
            values.tTransferAmount = tAmount;
        } else if (isBuy) {
            values.tLiquidity = percent(tAmount, buyFeeRates.liquidity);
            values.tBuyBack = percent(tAmount, buyFeeRates.buyBack);
            values.tTransferAmount =
                tAmount -
                values.tLiquidity -
                values.tBuyBack;
        } else if (isSell) {
            values.tLiquidity = percent(tAmount, sellFeeRates.liquidity);
            values.tBuyBack = percent(tAmount, sellFeeRates.buyBack);
            values.tTransferAmount =
                tAmount -
                values.tLiquidity -
                values.tBuyBack;
        }

        return values;
    }

    /**
     * @dev Taking liquidity fees
     */
    function _takeLiquidity(uint256 tLiquidity) private {
        totalFeesPaid.liquidity += tLiquidity;
        pendingToPay.liquidity += tLiquidity;

        _balances[address(this)] = _balances[address(this)] + tLiquidity;
    }

    /**
     * @dev Taking buyback fees
     */
    function _takeBuyBack(uint256 tBuyBack) private {
        totalFeesPaid.buyBack += tBuyBack;
        pendingToPay.buyBack += tBuyBack;

        _balances[address(this)] = _balances[address(this)] + tBuyBack;
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 pendingLiquidity = pendingToPay.liquidity;
        uint256 deltaBalance;
        if (pendingLiquidity > 0) {
            deltaBalance = swapTokensForETH(
                pendingLiquidity / 2,
                address(this),
                false
            );
        }

        if (deltaBalance > 0) {
            // Add liquidity to pancake
            addLiquidity(pendingLiquidity / 2, deltaBalance);
            pendingToPay.liquidity =
                balanceOf(address(this)) -
                pendingToPay.buyBack;
        }

        // Swap tokens to Eth for buyBack
        if (pendingToPay.buyBack > 0) {
            if (block.chainid == 56 || block.chainid == 97) {
                swapTokensForETH(pendingToPay.buyBack, address(this), true);
                pendingToPay.buyBack =
                    balanceOf(address(this)) -
                    pendingToPay.liquidity;
            } else {
                _transfer(address(this), buyBackAddress, pendingToPay.buyBack);
                // Address(this) is excluded from fees. So during above transfer no fees will be deducted so we can set it 0
                pendingToPay.buyBack = 0;
            }
        }
    }

    /**
     * @dev Converting tokens to BNB while swap and liquify
     */
    function swapTokensForETH(
        uint256 tokenAmount,
        address to,
        bool isBuyBack
    ) private returns (uint256) {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uint256 initialBalance = address(this).balance;

        // If raiseIN is other than bnb then we swap from token => raiseIn => bnb
        if (address(raiseIn) != uniswapV2Router.WETH()) {
            uint256 initialRaiseInBalance = raiseIn.balanceOf(address(this));
            // generate the uniswap pair path of token -> raiseIn -> wbnb
            address[] memory path = new address[](3);
            path[0] = address(this);
            path[1] = address(raiseIn);
            path[2] = uniswapV2Router.WETH();
            // make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BNB
                path,
                to,
                block.timestamp
            );
            if (isBuyBack) return 0; // In case of buyback we need BNB from swapping our token

            uint256 deltaBalance = address(this).balance - initialBalance;

            // Swapping from BNB => raiseIN
            swapETHForTokens(deltaBalance, address(raiseIn), address(this));
            uint256 deltaRaiseInBalance = raiseIn.balanceOf(address(this)) -
                initialRaiseInBalance;

            return deltaRaiseInBalance;
        } else {
            // If raiseIn is BNB than we swap from token => BNB (as liquidity of them will be available from presale)
            // generate the uniswap pair path of token -> wbnb
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            // make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BNB
                path,
                to,
                block.timestamp
            );
            uint256 deltaBalance = address(this).balance - initialBalance;
            return deltaBalance;
        }
    }

    /**
     * @dev Adding liquidity while swap and liquify
     */
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        if (address(raiseIn) != uniswapV2Router.WETH()) {
            raiseIn.approve(address(uniswapV2Router), bnbAmount);
            uniswapV2Router.addLiquidity(
                address(this),
                address(raiseIn),
                tokenAmount,
                bnbAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
        } else {
            uniswapV2Router.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
        }
    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount, address(apollo), _burnAddress);
        }
    }

    function swapETHForTokens(
        uint256 amount,
        address tokenAddress,
        address to
    ) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            to, // Burn address
            block.timestamp + 300
        );
    }

    /**
     * @dev Withdraw BNB Dust as there is possibility that some amount is returned when adding into liquidity
     */
    function withdrawDust(uint256 weiAmount, address to)
        external
        ownerAndPlatformOwner
    {
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        (bool sent, ) = payable(to).call{value: weiAmount}("");
        require(sent, "Failed to withdraw");
    }

    /**
     * @dev Withdraw BUSD Dust as there is possibility that some amount is returned when adding into liquidity
     */
    function withdrawRaiseInDust(uint256 weiAmount, address to)
        external
        ownerAndPlatformOwner
    {
        require(
            raiseIn.balanceOf(address(this)) >= weiAmount,
            "insufficient raiseIn balance"
        );
        bool sent = raiseIn.transfer(payable(to), weiAmount);
        require(sent, "Failed to withdraw");
    }

    modifier OnlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only Platform owner can call");
        _;
    }

    modifier ownerAndPlatformOwner() {
        require(
            msg.sender == owner() || msg.sender == platformOwner,
            "Can not call"
        );
        _;
    }

    /**
     * @dev to recieve BNB from uniswapV2Router when swaping
     */
    receive() external payable {}
}