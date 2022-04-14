/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// File: contracts/AJINU.sol

/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// File: contracts/AJINU.sol


pragma solidity ^0.8.0;

contract AJINU is ERC20, Ownable {

    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;

    // _maxTransfer set to 10 means the max transfer is 0.10% of the total supply
    uint256 internal _maxTransfer = 10;
    bool internal _isMaxBuyTransferEnabled = true;
    uint256 internal _taxReliefInterval = 7 days;
    uint256 public treasuryRate = 15;
    uint256 public reflectRate = 15;
    uint256 public cooldownPeriod = 1 days;
    /// @notice Contract AJINU balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000000 ether;
    bool public swapFees = true;

    // total wei reflected ever
    uint256 public ethReflectionBasis;
    uint256 public totalReflected;
    uint256 public totalTreasury;

    address payable public treasuryWallet;

    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool public tradingActive = false;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _taxExcluded;
    mapping(address => uint256) public lastReflectionBasis;
    mapping(address => uint256) public cooldownExpiresAt;
    mapping(address => uint256) public taxReliefStartDate;

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        address payable _treasuryWallet
    ) ERC20("AntiJeet Inu", "AJINU") Ownable() {
        addTaxExcluded(owner());
        addTaxExcluded(address(0));
        addTaxExcluded(_treasuryWallet);
        addTaxExcluded(address(this));

        treasuryWallet = _treasuryWallet;

        _router = IUniswapV2Router02(_uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    /// @notice Change the address of the treasury wallet
    /// @param _treasuryWallet The new address of the treasury wallet
    function setTreasuryWallet(address payable _treasuryWallet) external onlyOwner() {
        treasuryWallet = _treasuryWallet;
    }

    /// @notice Change the treasury tax rate
    /// @param _treasuryRate The new treasury tax rate
    function setTreasuryRate(uint256 _treasuryRate) external onlyOwner() {
        require(_treasuryRate <= 100, "_treasuryRate cannot exceed 100%");
        treasuryRate = _treasuryRate;
    }

    /// @notice Change the reflection tax rate
    /// @param _reflectRate The new reflection tax rate
    function setReflectRate(uint256 _reflectRate) external onlyOwner() {
        require(_reflectRate <= 100, "_reflectRate cannot exceed 100%");
        reflectRate = _reflectRate;
    }

    /// @notice Change the minimum contract AJINU balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner() {
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the cooldown period
    /// @param _cooldownPeriod The new cooldown period
    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyOwner() {
        require(_cooldownPeriod <= 1 days && _cooldownPeriod > 0, "_cooldownPeriod must be less than 1 day");
        cooldownPeriod = _cooldownPeriod;
    }

    /// @notice Rescue AJINU from the treasury amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of AJINU to rescue
    /// @param _recipient The recipient of the rescued AJINU
    function rescueTreasuryTokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalTreasury, "Amount cannot be greater than totalTreasury");
        _rawTransfer(address(this), _recipient, _amount);
        totalTreasury -= _amount;
    }

    /// @notice Rescue AJINU from the reflection amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of AJINU to rescue
    /// @param _recipient The recipient of the rescued AJINU
    function rescueReflectionTokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalReflected, "Amount cannot be greater than totalReflected");
        _rawTransfer(address(this), _recipient, _amount);
        totalReflected -= _amount;
    }

    function addLiquidity(uint256 tokens) external payable onlyOwner() liquidityAdd {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value : msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
        // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Enables trading on Uniswap
    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    /// @notice Disables trading on Uniswap
    function disableTrading() external onlyOwner {
        tradingActive = false;
    }

    function addReflection() external payable {
        ethReflectionBasis += msg.value;
    }

    function isTaxExcluded(address account) public view returns (bool) {
        return _taxExcluded[account];
    }

    function addTaxExcluded(address account) public onlyOwner() {
        require(!isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = true;
    }

    function removeTaxExcluded(address account) external onlyOwner() {
        require(isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = false;
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

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 maxTxAmount = totalSupply() * _maxTransfer / 10000;

        if(_isMaxBuyTransferEnabled && sender == _pair) {
            require(amount <= maxTxAmount);
        }

        require(amount <= maxTxAmount || sender == _pair || _inLiquidityAdd || _inSwap || recipient == address(_router), "Exceeds max transaction amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokenBalance;

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            overMinTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            swapFees
        ) {
            _swap(contractTokenBalance);
        }

        _claimReflection(payable(sender));
        _claimReflection(payable(recipient));

        uint256 send = amount;
        uint256 reflect;
        uint256 treasury;
        if (sender == _pair || recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            uint256 userTaxReliefStartDate = getTaxReliefStartDate(recipient);
            if (sender == _pair && userTaxReliefStartDate == 0) {
                taxReliefStartDate[recipient] = block.timestamp;
            }
            if (recipient == _pair) {
                // sell
                require(block.timestamp >= getCooldownExpiration(sender));
                (
                send,
                reflect,
                treasury
                ) = _getTaxAmounts(amount, getUserTaxRelief(sender));

                // set cooldown period
                cooldownExpiresAt[sender] = block.timestamp + cooldownPeriod;
                // reset taxReliefStartDate
                if (balanceOf(sender) - amount < 1 ether) {
                    taxReliefStartDate[sender] = 0;
                }

                _takeTaxes(sender, treasury, reflect);
            }
        }
        _rawTransfer(sender, recipient, send);
    }

    function getCooldownExpiration(address addr) public view returns (uint256) {
        return cooldownExpiresAt[addr];
    }

    function getTaxReliefStartDate(address addr) public view returns (uint256) {
        return taxReliefStartDate[addr];
    }

    function getUserTaxRelief(address addr) public view returns (uint8) {
        uint256 userTaxReliefStartDate = getTaxReliefStartDate(addr);

        // get tax relief
        uint8 taxReliefInterval = 0;

        if(userTaxReliefStartDate > 0) {
            // calculate the difference in weeks between the current time vs when the users tax relief starts
            uint256 taxReliefDateDifference = (block.timestamp - userTaxReliefStartDate) / _taxReliefInterval;
            if(taxReliefDateDifference > 4) {
                taxReliefInterval = 4;
            } else {
                taxReliefInterval = uint8(taxReliefDateDifference);
            }
        }

        return taxReliefInterval;
    }

    function unclaimedReflection(address addr) public view returns (uint256) {
        if (addr == _pair || addr == address(_router)) return 0;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[addr];
        return basisDifference * balanceOf(addr) / _totalSupply;
    }

    /// @notice Claims reflection pool ETH
    /// @param addr The address to claim the reflection for
    function _claimReflection(address payable addr) internal {
        uint256 unclaimed = unclaimedReflection(addr);
        lastReflectionBasis[addr] = ethReflectionBasis;
        if (unclaimed > 0) {
            addr.transfer(unclaimed);
        }
    }

    function claimReflection() external {
        _claimReflection(payable(msg.sender));
    }

    /// @notice Perform a Uniswap v2 swap from AJINU to ETH and handle tax distribution
    /// @param amount The amount of AJINU to swap in wei
    /// @dev `amount` is always <= this contract's ETH balance. Calculate and distribute treasury and reflection taxes
    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 totalTaxes = totalTreasury + totalReflected;
        uint256 treasuryAmount = amount * totalTreasury / totalTaxes;
        uint256 reflectedAmount = amount - treasuryAmount;

        uint256 treasuryEth = tradeValue * totalTreasury / totalTaxes;
        uint256 reflectedEth = tradeValue - treasuryEth;

        if (treasuryEth > 0) {
            treasuryWallet.transfer(treasuryEth);
        }
        totalTreasury = totalTreasury - treasuryAmount;
        totalReflected = totalReflected - reflectedAmount;
        ethReflectionBasis = ethReflectionBasis + reflectedEth;
    }

    function swapAll() external onlyOwner() {
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 10000;
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount)
        {
            contractTokenBalance = maxTxAmount;
        }

        if (
            !_inSwap
        ) {
            _swap(contractTokenBalance);
        }
    }

    function withdrawAll() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers AJINU from an account to this contract for taxes
    /// @param _account The account to transfer AJINU from
    /// @param _treasuryAmount The amount of treasury tax to transfer
    /// @param _reflectAmount The amount of reflection tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _treasuryAmount,
        uint256 _reflectAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _treasuryAmount + _reflectAmount;
        _rawTransfer(_account, address(this), totalAmount);
        totalTreasury += _treasuryAmount;
        totalReflected += _reflectAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return reflect The raw reflection tax amount
    /// @return treasury The raw treasury tax amount
    function _getTaxAmounts(uint256 amount, uint8 taxReliefInterval)
    internal
    view
    returns (
        uint256 send,
        uint256 reflect,
        uint256 treasury
    )
    {
        uint256 taxRelief = 1000;

        if(taxReliefInterval == 1) {
            taxRelief = 833;
        } else if (taxReliefInterval == 2) {
            taxRelief = 666;
        } else if (taxReliefInterval == 3) {
            taxRelief = 500;
        } else if (taxReliefInterval == 4) {
            taxRelief = 333;
        }

        reflect = amount * reflectRate * taxRelief / 100000;
        treasury = amount * treasuryRate * taxRelief / 100000;
        send = amount - reflect - treasury;
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
    unchecked {
        _subtractBalance(sender, amount);
    }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function setMaxTransfer(uint256 maxTransfer) external onlyOwner() {
        require(maxTransfer < 2000, "Cannot set max transfer above 20 percent");
        _maxTransfer = maxTransfer;
    }

    function setIsMaxBuyTransferEnabled(bool isMaxBuyTransferEnabled) external onlyOwner() {
        _isMaxBuyTransferEnabled = isMaxBuyTransferEnabled;
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner() {
        swapFees = _swapFees;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        require(_totalSupply + amount <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner() {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) external onlyOwner() {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}
}