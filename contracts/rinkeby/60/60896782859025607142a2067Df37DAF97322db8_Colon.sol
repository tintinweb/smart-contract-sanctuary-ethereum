/**
 *Submitted for verification at Etherscan.io on 2022-08-08
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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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


// File contracts/ApolloSafePlayMultiCurrency/ApolloSafePlayBRLM.sol

/*******************************************
 * Apollo Safe play
 */

/**
 * Apollo safe play token with all functionalities and reflection in native token
 */

pragma solidity ^0.8.14;





contract Colon is Context, IERC20Metadata, Ownable, Pausable {
    // Token parameters
    string private constant NAME = "Colon";
    string private constant SYMBOL = "COLON";
    uint8 private constant DECIMALS = 18;
    uint256 private _tTotal = 10000000000 * 1e18;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => bool) public blacklist;

    address public marketingAddress;
    address public liquidityAddress;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public _burnAddress = 0x000000000000000000000000000000000000dEaD;

    address[] private _excludedFromReward;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal;

    struct feeRateStruct {
        uint256 reflection;
        uint256 liquidity;
        uint256 marketing;
    }

    feeRateStruct public buyFeeRates;
    feeRateStruct public sellFeeRates;

    feeRateStruct public totalFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rReflection;
        uint256 rLiquidity;
        uint256 rMarketing;
        uint256 tTransferAmount;
        uint256 tReflection;
        uint256 tLiquidity;
        uint256 tMarketing;
    }

    event FeesChanged();

    /**
     * @dev Sets the values for {name}, {symbol}, {totalSupply}, feeRate and some addresses .
     */
    constructor(
        feeRateStruct memory _buyFee,
        feeRateStruct memory _sellFee,
        address _marketingAddress,
        address _liquidityAddress,
        address _router
    ) {
        require(
            _marketingAddress != address(0) && _liquidityAddress != address(0),
            "Invalid address"
        );

        _rTotal = (MAX - (MAX % _tTotal));

        buyFeeRates = _buyFee;
        sellFeeRates = _sellFee;

        marketingAddress = _marketingAddress;
        liquidityAddress = _liquidityAddress;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        uniswapV2Router = IUniswapV2Router02(_router);
        // Setting default pair as pair of BNB and token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        // Transferring total supply to owner
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
        whenNotPaused
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
    ) public virtual override whenNotPaused returns (bool) {
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
            blacklist[sender] == false && blacklist[recipient] == false,
            "You are blacklisted"
        );

        require(
            amount <= balanceOf(sender),
            "ERC20: transfer amount exceeds balance"
        );

        _tokenTransfer(
            sender,
            recipient,
            amount,
            !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
        );
    }

    /**
     * @dev Sets Marketing Address
     */
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "zero address");
        marketingAddress = _marketingAddress;
    }

    /**
     * @dev Sets Liquidity Wallet Address
     */
    function setLiquidityAddress(address _liquidityAddress) external onlyOwner {
        require(_liquidityAddress != address(0), "zero address");
        liquidityAddress = _liquidityAddress;
    }

    function addToBlacklist(address account) public onlyOwner {
        blacklist[account] = true;
    }

    function removeFromBlacklist(address account) public onlyOwner {
        blacklist[account] = false;
    }

    /**
     * @dev Setting fee rates
     * Total tax should be below or equal to MAX_TX_FEES
     */
    function setFeeRates(
        feeRateStruct memory _buyFeeRates,
        feeRateStruct memory _sellFeeRates
    ) external onlyOwner {
        buyFeeRates = _buyFeeRates;
        sellFeeRates = _sellFeeRates;

        emit FeesChanged();
    }

    /**
     * @dev Setting account as excluded from reward.
     */
    function excludeFromReward(address account) public onlyOwner whenNotPaused {
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
    function includeInReward(address account) external onlyOwner whenNotPaused {
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

        if (sender == uniswapV2Pair) {
            isBuy = true;
        } else if (recipient == uniswapV2Pair) {
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
        if (takeFee) {
            if (isBuy) {
                _reflectFee(values.rReflection, values.tReflection);
                _takeLiquidity(values.rLiquidity, values.tLiquidity);
                emit Transfer(sender, liquidityAddress, values.tLiquidity);
            } else if (isSell) {
                _takeLiquidity(values.rLiquidity, values.tLiquidity);
                _takeMarketing(values.rMarketing, values.tMarketing);
                emit Transfer(sender, liquidityAddress, values.tLiquidity);
                emit Transfer(sender, marketingAddress, values.tMarketing);
            }
        }

        emit Transfer(sender, recipient, values.tTransferAmount);
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
        values = _getRValues(values, tAmount, takeFee, isBuy, isSell,_getRate());

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
            values.tLiquidity = percent(tAmount, buyFeeRates.liquidity);
            values.tTransferAmount =
                tAmount -
                values.tReflection -
                values.tLiquidity;
        } else if (isSell) {
            values.tLiquidity = percent(tAmount, sellFeeRates.liquidity);
            values.tMarketing = percent(tAmount, sellFeeRates.marketing);
            values.tTransferAmount =
                tAmount -
                values.tLiquidity -
                values.tMarketing;
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
        returnValues.rLiquidity = values.tLiquidity * currentRate;
        returnValues.rTransferAmount =
            returnValues.rAmount -
            returnValues.rReflection -
            returnValues.rMarketing - 
            returnValues.rLiquidity;
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
     * @dev Taking liquidity fees
     */
    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totalFeesPaid.liquidity += tLiquidity;

        _rOwned[liquidityAddress] = _rOwned[liquidityAddress] + rLiquidity;
        if (_isExcludedFromReward[liquidityAddress]) {
            _tOwned[liquidityAddress] = _tOwned[liquidityAddress] + tLiquidity;
        }
    }

    /**
     * @dev Taking marketing fees
     */
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totalFeesPaid.marketing += tMarketing;

        _rOwned[marketingAddress] = _rOwned[marketingAddress] + rMarketing;
        if (_isExcludedFromReward[marketingAddress]) {
            _tOwned[marketingAddress] = _tOwned[marketingAddress] + tMarketing;
        }
    }

    function burn(uint256 amount) public virtual {
        transfer(_burnAddress, amount);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external virtual whenNotPaused onlyOwner {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external virtual whenPaused onlyOwner {
        super._unpause();
    }

    /**
     * @dev to recieve BNB from uniswapV2Router when swaping
     */
    receive() external payable {}
}