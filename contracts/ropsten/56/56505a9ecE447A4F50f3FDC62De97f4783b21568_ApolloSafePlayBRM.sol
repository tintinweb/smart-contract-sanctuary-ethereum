/**
 *Submitted for verification at Etherscan.io on 2022-07-22
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


// File contracts/ApolloSafePlayMultiCurrency/ApolloSafePlayBRM.sol

/*******************************************
 * Apollo Safe play
 */

/**
 * Apollo safe play token with all functionalities except liquidity
 * Reflection in native token
 */


pragma solidity ^0.8.14;




contract ApolloSafePlayBRM is Context, IERC20Metadata, Ownable {
    // Token parameters
    string private NAME;
    string private SYMBOL;
    uint8 private immutable DECIMALS;
    uint256 private _tTotal;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    // Address of pair contract from which tax is deducted
    mapping(address => bool) public isPair;

    address public marketingAddress;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;
    IERC20 public apollo; // ApolloVenture contract address for buyback
    address public platformOwner = 0x9464b7220920E4F2db4730fa98D939c58C74Bac4;
    address public buyBackAddress = 0x34bC342fE478b1F6C57a329B04E755300c2aF841;
    address public factory; // Address of launchpad factory
    IERC20 public raiseIn; // Address of token in which presale was raised

    address[] private _excludedFromReward;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal;

    bool private swapping;
    bool public swapEnabled;
    bool public buyBackEnabled;

    uint256 public swapTokensAtAmount;
    uint256 public buyBackUpperLimit = 1 ether;
    uint256 public maxTxLimit;
    uint256 public constant MAX_TX_FEES = 1500;

    // Reflection and burning will happen in every transactions while other 3 will happen after thresold
    struct feeRateStruct {
        uint256 reflection;
        uint256 marketing;
        uint256 burning;
        uint256 buyBack;
    }

    feeRateStruct public buyFeeRates;
    feeRateStruct public sellFeeRates;

    feeRateStruct public totalFeesPaid;
    feeRateStruct public pendingToPay;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflection;
        uint256 rMarketing;
        uint256 rBurning;
        uint256 rBuyBack;
        uint256 tTransferAmount;
        uint256 tReflection;
        uint256 tMarketing;
        uint256 tBurning;
        uint256 tBuyBack;
    }

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    event FeesChanged();

    /**
     * @dev Sets the values for {name}, {symbol}, {totalSupply}, feeRate and some addresses .
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        feeRateStruct memory _txFeeRates,
        address _marketingAddress,
        address _router,
        IERC20 _apollo,
        address[] memory currency, // Possible token address on chain that can be used to raise presale
        address _factory
    ) {
        require(
            _marketingAddress != address(0) && _factory != address(0),
            "Invalid address"
        );
        NAME = _name;
        SYMBOL = _symbol;
        DECIMALS = _decimals;
        _tTotal = _totalSupply;
        _rTotal = (MAX - (MAX % _tTotal));
        swapTokensAtAmount = 100_000 * 10**DECIMALS;
        maxTxLimit = 500_000 * 10**DECIMALS;
        require(
            (_txFeeRates.burning +
                _txFeeRates.reflection +
                _txFeeRates.marketing +
                _txFeeRates.buyBack) <=
                MAX_TX_FEES,
            "Total Tx fees exceeds limit"
        );

        buyFeeRates = _txFeeRates;
        sellFeeRates = _txFeeRates;

        marketingAddress = _marketingAddress;
        factory = _factory;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

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
        _rOwned[_msgSender()] = _rTotal;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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

        // if balance is more than the limit(i.e. swapTokensAtAmount) then only we will swap
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        // To get rid of loop
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
                (block.chainid == 56 ||
                    block.chainid == 97 ||
                    block.chainid == 31337 ||
                    block.chainid == 3)
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
            !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
        );
    }

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

    /**
     * @dev Update router address in case of pancakeswap migration
     */
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
     * @dev Sets Marketing Address
     */
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "zero address");
        marketingAddress = _marketingAddress;
    }

    /**
     * @dev Setting token amount as which swap will happen
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
    function setBuybackUpperLimit(uint256 buyBackLimit) external OnlyPlatformOwner {
        buyBackUpperLimit = buyBackLimit;
    }

     /**
     * @dev Setting buyBack fees
     */
    function setBuyBackfees(uint256 _buyingBuyBack, uint256 _sellingBuyBack) external OnlyPlatformOwner {
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

    /**
     * @dev Setting fee rates
     * Total tax should be below or equal to MAX_TX_FEES
     */
    function setFeeRates(
        feeRateStruct memory _buyFeeRates,
        feeRateStruct memory _sellFeeRates
    ) external onlyOwner {
        uint256 buyFees = _buyFeeRates.reflection +
            _buyFeeRates.marketing +
            _buyFeeRates.burning;

        uint256 sellFees = _sellFeeRates.reflection +
            _sellFeeRates.marketing +
            _sellFeeRates.burning;

        require(
            (buyFees + buyFeeRates.buyBack) <= MAX_TX_FEES && (sellFees + sellFeeRates.buyBack) <= MAX_TX_FEES,
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

    /**
     * @dev Setting account as excluded from reward.
     */
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    /**
     * @dev Setting account as included in reward.
     */
    function includeInReward(address account) external onlyOwner {
        require(_isExcludedFromReward[account], "Account is not excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[
                    _excludedFromReward.length - 1
                ];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }

    /**
     * @dev Setting account as excluded from fee.
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @dev Setting account as included in fee.
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Returns account is excluded from fee or not.
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev Returns account is excluded from reward or not.
     */
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
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
     * @dev Changes token/reflected token ratio
     */
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward[sender],
            "Excluded addresses cannot call this function"
        );
        valuesFromGetValues memory values = _getValues(
            tAmount,
            true,
            false,
            false
        );
        _rOwned[sender] = _rOwned[sender] - values.rAmount;
        _rTotal = _rTotal - values.rAmount;
        totalFeesPaid.reflection = totalFeesPaid.reflection + tAmount;
    }

    /**
     * @dev Return rAmount of tAmount with or without fees
     */
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        valuesFromGetValues memory values = _getValues(
            tAmount,
            true,
            false,
            false
        );
        if (!deductTransferFee) {
            return values.rAmount;
        } else {
            return values.rTransferAmount;
        }
    }

    /**
     * @dev Return tAmount of rAmount
     */
    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
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

        if (_isExcludedFromReward[sender]) {
            //from excluded
            _tOwned[sender] = _tOwned[sender] - amount;
        }
        if (_isExcludedFromReward[recipient]) {
            //to excluded
            _tOwned[recipient] = _tOwned[recipient] + values.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender] - values.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + values.rTransferAmount;
        if (takeFee && (isBuy || isSell)) {
            _reflectFee(values.rReflection, values.tReflection);
            _takeMarketing(values.rMarketing, values.tMarketing);
            _takeBurn(values.rBurning, values.tBurning);
            _takeBuyBack(values.rBuyBack, values.tBuyBack);
        }

        emit Transfer(sender, recipient, values.tTransferAmount);
        emit Transfer(
            sender,
            address(this),
            values.tMarketing + values.tBuyBack
        );
        emit Transfer(sender, _burnAddress, values.tBurning);
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
        values = _getTValues(tAmount, takeFee, isBuy, isSell);
        values = _getRValues(
            values,
            tAmount,
            takeFee,
            isBuy,
            isSell,
            _getRate()
        );

        return values;
    }

    /**
     * @dev Returns tAmount with or without fees
     */
    function _getTValues(
        uint256 tAmount,
        bool takeFee,
        bool isBuy,
        bool isSell
    ) private view returns (valuesFromGetValues memory values) {
        if (!takeFee || (!isBuy && !isSell)) {
            values.tTransferAmount = tAmount;
        } else if (isBuy) {
            values.tReflection = percent(tAmount, buyFeeRates.reflection);
            values.tMarketing = percent(tAmount, buyFeeRates.marketing);
            values.tBurning = percent(tAmount, buyFeeRates.burning);
            values.tBuyBack = percent(tAmount, buyFeeRates.buyBack);
            values.tTransferAmount =
                tAmount -
                values.tReflection -
                values.tMarketing -
                values.tBurning -
                values.tBuyBack;
        } else if (isSell) {
            values.tReflection = percent(tAmount, sellFeeRates.reflection);
            values.tMarketing = percent(tAmount, sellFeeRates.marketing);
            values.tBurning = percent(tAmount, sellFeeRates.burning);
            values.tBuyBack = percent(tAmount, sellFeeRates.buyBack);
            values.tTransferAmount =
                tAmount -
                values.tReflection -
                values.tMarketing -
                values.tBurning -
                values.tBuyBack;
        }

        return values;
    }

    /**
     * @dev Returns rAmount with or without fees
     */
    function _getRValues(
        valuesFromGetValues memory values,
        uint256 tAmount,
        bool takeFee,
        bool isBuy,
        bool isSell,
        uint256 currentRate
    ) private pure returns (valuesFromGetValues memory returnValues) {
        returnValues = values;
        returnValues.rAmount = tAmount * currentRate;

        if (!takeFee || (!isBuy && !isSell)) {
            returnValues.rTransferAmount = tAmount * currentRate;
            return returnValues;
        }

        returnValues.rReflection = values.tReflection * currentRate;
        returnValues.rMarketing = values.tMarketing * currentRate;
        returnValues.rBurning = values.tBurning * currentRate;
        returnValues.rBuyBack = values.tBuyBack * currentRate;
        returnValues.rTransferAmount =
            returnValues.rAmount -
            returnValues.rReflection -
            returnValues.rMarketing -
            returnValues.rBurning -
            returnValues.rBuyBack;
        return returnValues;
    }

    /**
     * @dev Returns current rate or ratio of reflected tokens over tokens
     */
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    /**
     * @dev Returns current rSupply and tSupply
     */
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (
                _rOwned[_excludedFromReward[i]] > rSupply ||
                _tOwned[_excludedFromReward[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excludedFromReward[i]];
            tSupply = tSupply - _tOwned[_excludedFromReward[i]];
        }
        if (rSupply < (_rTotal / _tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    

    /**
     * @dev Taking/reflecting reflection fees
     */
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        totalFeesPaid.reflection += tFee;
    }

    /**
     * @dev Taking marketing fees
     */
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totalFeesPaid.marketing += tMarketing;
        pendingToPay.marketing += tMarketing;

        _rOwned[address(this)] = _rOwned[address(this)] + rMarketing;
        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)] + tMarketing;
        }
    }

    /**
     * Transfering burning fees to burning address
     */
    function _takeBurn(uint256 rBurning, uint256 tBurning) private {
        totalFeesPaid.burning += tBurning;

        _rOwned[_burnAddress] = _rOwned[_burnAddress] + rBurning;
        if (_isExcludedFromReward[_burnAddress]) {
            _tOwned[_burnAddress] = _tOwned[_burnAddress] + tBurning;
        }
    }

    /**
     * @dev Taking buyback fees
     */
    function _takeBuyBack(uint256 rBuyBack, uint256 tBuyBack) private {
        totalFeesPaid.buyBack += tBuyBack;
        pendingToPay.buyBack += tBuyBack;

        _rOwned[address(this)] = _rOwned[address(this)] + rBuyBack;
        if (_isExcludedFromReward[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)] + tBuyBack;
        }
    }

    /**
     * @dev Swapping
     */
    function swapAndLiquify() private lockTheSwap {
        uint256 reflection = balanceOf(address(this)) -
            (pendingToPay.marketing + pendingToPay.buyBack);
        uint256 totalFeePercent = buyFeeRates.marketing + buyFeeRates.buyBack;
        pendingToPay.marketing +=
            (reflection * buyFeeRates.marketing) /
            totalFeePercent;
        pendingToPay.buyBack +=
            (reflection * buyFeeRates.buyBack) /
            totalFeePercent;

        // Send BNB to Marketing Address
        if (pendingToPay.marketing > 0) {
            _transfer(address(this), marketingAddress, pendingToPay.marketing);
            // Address(this) is excluded from fees. So during above transfer no fees will be deducted so we can set it 0
            pendingToPay.marketing = 0;
        }

        // Swap tokens to Eth for buyBack
        if (pendingToPay.buyBack > 0) {
            if (
                block.chainid == 56 ||
                block.chainid == 97 ||
                block.chainid == 31337 ||
                block.chainid == 3
            ) {
                swapTokensForETH(pendingToPay.buyBack, address(this));
            pendingToPay.buyBack =
                balanceOf(address(this)) -
                pendingToPay.marketing;
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
    function swapTokensForETH(uint256 tokenAmount, address to) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // If raiseIN is other than bnb then we swap from token => raiseIn => bnb
        if (address(raiseIn) != uniswapV2Router.WETH()) {
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
        }
    }

    

    

    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(apollo);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            _burnAddress, // Burn address
            block.timestamp + 300
        );
    }

    modifier OnlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only Platform owner can call");
        _;
    }

    /**
     * @dev Withdraw BNB Dust as there is possibility that some amount is returned when adding into liquidity
     */
    function withdrawDust(uint256 weiAmount, address to) external onlyOwner {
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        (bool sent, ) = payable(to).call{value: weiAmount}("");
        require(sent, "Failed to withdraw");
    }

    /**
     * @dev Withdraw BUSD Dust as there is possibility that some amount is returned when adding into liquidity
     */
    function withdrawRaiseInDust(uint256 weiAmount, address to)
        external
        onlyOwner
    {
        require(
            raiseIn.balanceOf(address(this)) >= weiAmount,
            "insufficient BNB balance"
        );
        bool sent = raiseIn.transfer(payable(to), weiAmount);
        require(sent, "Failed to withdraw");
    }

    /**
     * @dev to recieve BNB from uniswapV2Router when swaping
     */
    receive() external payable {}
}