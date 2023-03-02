/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

/**

https://t.me/BarstoolSportsInu

*/    

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

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

contract BSI is ERC20, Ownable {
  uint256 internal constant PERCENT_DENOMINATOR = 1000;
  address internal constant DEAD = address(0xdead);
  bool private _addingLP;

  address internal _lpReceiver;
  address internal _marketingReceiver;
  address internal _nukeRecipient = DEAD;
  uint256 public lpNukeBuildup;
  uint256 public nukePercentPerSell = (PERCENT_DENOMINATOR * 5) / 100; // 5%
  bool public lpNukeEnabled = true;

  mapping(address => bool) internal _isTaxExcluded;

  uint256 public taxBurn = (PERCENT_DENOMINATOR * 0) / 100; // 0%
  uint256 public taxBuyer = (PERCENT_DENOMINATOR * 60) / 100; // 60% reduced to 3%
  uint256 public taxLp = (PERCENT_DENOMINATOR * 0) / 100; // 0% to 2%
  uint256 internal _totalTax;
  bool internal _taxesOff;

  uint256 public maxTransactionAmount;
  uint256 public maxWallet;
  bool public enableLimits = true;

  mapping (address => bool) public _isExcludedMaxTransactionAmount;


  uint256 internal _liquifyRate = (PERCENT_DENOMINATOR * 1) / 100; // 1%
  uint256 public launchTime;
  uint256 public launchTimeTopHour;
  uint256 public launchTimeTopMonth;
  uint256 internal _launchBlock;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => bool) internal _isBot;

  bool internal _swapEnabled = true;
  bool internal _swapping = false;


  modifier swapLock() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor() ERC20("Barstool Sports Inu", "BSI") {
    uint256 totalSupply = 1 * 1e6 * 1e18;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;

    maxTransactionAmount = (totalSupply * 20) / 1000; // 2% maxTransactionAmountTxn
    maxWallet = (totalSupply * 20) / 1000; // 2% maxWallet

    _marketingReceiver = 0x4298D2CDBebb046Ad764A0f1f43c0889Aa28e9D2;
    excludeFromMaxTransaction(owner(), true);
    excludeFromMaxTransaction(address(this), true);
    excludeFromMaxTransaction(address(0xdead), true);
    _isTaxExcluded[address(this)] = true;
    _isTaxExcluded[msg.sender] = true;

    _mint(address(this), totalSupply);
  }

  // _percent: 1 == 0.1%, 1000 = 100%
  function launch(uint16 _percent) external payable onlyOwner {
    require(_percent <= PERCENT_DENOMINATOR, 'must be between 0-100%');
    require(launchTime == 0, 'already launched');
    require(_percent == 0 || msg.value > 0, 'need ETH for initial LP');
    _addingLP = true;

    uint256 _lpSupply = (totalSupply() * _percent) / PERCENT_DENOMINATOR;
    uint256 _leftover = totalSupply() - _lpSupply;
    if (_lpSupply > 0) {
      _addLp(_lpSupply, msg.value);
    }
    if (_leftover > 0) {
      _transfer(address(this), owner(), _leftover);
    }
    launchTime = block.timestamp;
    _launchBlock = block.number;
    _addingLP = false;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isOwner = sender == owner() || recipient == owner();
    uint256 contractTokenBalance = balanceOf(address(this));

    bool _isBuy = sender == uniswapV2Pair &&
      recipient != address(uniswapV2Router);
    bool _isSell = recipient == uniswapV2Pair;
    bool _isSwap = _isBuy || _isSell;

    if (_isSwap && enableLimits) {
        bool _skipCheck = _addingLP || _isExcludedMaxTransactionAmount[recipient] || _isExcludedMaxTransactionAmount[sender];
        uint256 _maxTx = totalSupply() * maxTransactionAmount / PERCENT_DENOMINATOR;
        require(_maxTx >= amount || _skipCheck, "Tx amount exceed limit");
        if (_isBuy) {
            uint256 _maxWallet = totalSupply() * maxWallet / PERCENT_DENOMINATOR;
            require(_maxWallet >= balanceOf(recipient) + amount || _skipCheck, "Total amount exceed wallet limit");
        }
    }

    if (_isBuy) {
      if (block.number <= _launchBlock + 2) {
        _isBot[recipient] = true;
      }
    } else {
      require(!_isBot[recipient], 'Stop botting!');
      require(!_isBot[sender], 'Stop botting!');
      require(!_isBot[_msgSender()], 'Stop botting!');
    }

    uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) /
      PERCENT_DENOMINATOR;
    bool _overMin = contractTokenBalance >= _minSwap;
    if (
      _swapEnabled &&
      !_swapping &&
      !_isOwner &&
      _overMin &&
      launchTime != 0 &&
      sender != uniswapV2Pair
    ) {
      _swap(_minSwap);
    }

    uint256 tax = 0;
    if (
      launchTime != 0 &&
      _isSell &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      tax = _calcTaxAndProcess(sender, amount);
    }

    super._transfer(sender, recipient, amount - tax);

    if (_isSell && lpNukeEnabled && sender != address(this)) {
      lpNukeBuildup +=
        ((amount - tax) * nukePercentPerSell) /
        PERCENT_DENOMINATOR;
    }
  }

  function _calcTaxAndProcess(address sender, uint256 amount)
    internal
    returns (uint256)
  {
    uint256 tax = (amount * _totalTax) / PERCENT_DENOMINATOR;
    if (tax > 0) {
      super._transfer(sender, address(this), tax);
    }
    return tax;
  }

  function _swap(uint256 _amountToSwap) internal swapLock {
    uint256 balBefore = address(this).balance;
    uint256 burnTokens = (_amountToSwap * taxBurn) / _totalTax;
    uint256 liquidityTokens = (_amountToSwap * taxLp) / _totalTax / 2;
    uint256 tokensToSwap = _amountToSwap - burnTokens - liquidityTokens;

    if (burnTokens > 0) {
      _burn(address(this), burnTokens);
    }

    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokensToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokensToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 balToProcess = address(this).balance - balBefore;
    if (balToProcess > 0) {
      _processFees(balToProcess, liquidityTokens);
    }
  }

  function _processFees(uint256 amountETH, uint256 amountLpTokens) internal {
    uint256 lpETH = (amountETH * taxLp) / _totalTax;
    if (amountLpTokens > 0) {
      _addLp(amountLpTokens, lpETH);
    }
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) internal {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      _lpReceiver == address(0) ? owner() : _lpReceiver,
      block.timestamp
    );
  }

  function _lpTokenNuke(uint256 _amount) internal {
    // cannot nuke more than 20% of token supply in pool
    if (_amount > 0 && _amount <= (balanceOf(uniswapV2Pair) * 20) / 100) {
      if (_nukeRecipient == DEAD) {
        _burn(uniswapV2Pair, _amount);
      } else {
        super._transfer(uniswapV2Pair, _nukeRecipient, _amount);
      }
      IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
      pair.sync();
    }
  }

  function nukeLpTokenFromBuildup() external {
    require(
      msg.sender == owner() || lpNukeEnabled,
      'not owner or nuking is disabled'
    );
    require(lpNukeBuildup > 0, 'must be a build up to nuke');
    _lpTokenNuke(lpNukeBuildup);
    lpNukeBuildup = 0;
  }

  function manualNukeLpTokens(uint256 _percent) external onlyOwner {
    require(_percent <= 200, 'cannot burn more than 20% dex balance');
    _lpTokenNuke((balanceOf(uniswapV2Pair) * _percent) / PERCENT_DENOMINATOR);
  }

  function isBotBlacklisted(address account) external view returns (bool) {
    return _isBot[account];
  }

  function blacklistBot(address account) external onlyOwner {
    require(account != address(uniswapV2Router), 'cannot blacklist router');
    require(account != uniswapV2Pair, 'cannot blacklist pair');
    require(!_isBot[account], 'user is already blacklisted');
    _isBot[account] = true;
  }

  function forgiveBot(address account) external onlyOwner {
    require(_isBot[account], 'user is not blacklisted');
    _isBot[account] = false;
  }

  function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
    _isExcludedMaxTransactionAmount[updAds] = isEx;
  }

  function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
    require(newNum >= (totalSupply() * 15 / 1000)/1e18, "Cannot set maxTransactionAmount lower than 0.5%");
    maxTransactionAmount = newNum * (10**18);
  }
 
  function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
    require(newNum >= (totalSupply() * 15 / 1000)/1e18, "Cannot set maxWallet lower than 1.5%");
    maxWallet = newNum * (10**18);
  }

  function setEnableLimits(bool _enable) external onlyOwner {
      enableLimits = _enable;
  }

  function _setTotalTax() internal {
    _totalTax = taxBurn + taxBuyer + taxLp;
    require(
      _totalTax <= (PERCENT_DENOMINATOR * 25) / 100,
      'tax cannot be above 25%'
    );
    require(
      _totalTax / 10 <=
        (PERCENT_DENOMINATOR * 49) / 100,
      'total cannot be more than 49%'
    );
  }

  function setTaxBurn(uint256 _tax) external onlyOwner {
    taxBurn = _tax;
    _setTotalTax();
  }

  function setTaxBuyer(uint256 _tax) external onlyOwner {
    taxBuyer = _tax;
    _setTotalTax();
  }

  function setTaxLp(uint256 _tax) external onlyOwner {
    taxLp = _tax;
    _setTotalTax();
  }

  function setTaxes(uint256 _taxBurn, uint256 _taxBuyer, uint256 _taxLp) external onlyOwner {
    taxBurn = _taxBurn;
    taxBuyer = _taxBuyer;  
    taxLp = _taxLp;
    _setTotalTax();
  }  

  function setLpReceiver(address _wallet) external onlyOwner {
    _lpReceiver = _wallet;
  }

  function setMarketingReceiver(address _wallet) external onlyOwner {
    _marketingReceiver = _wallet;
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMINATOR / 10, 'cannot be more than 10%');
    _liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _areOff) external onlyOwner {
    _taxesOff = _areOff;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setNukePercentPerSell(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMINATOR, 'cannot be more than 100%');
    nukePercentPerSell = _percent;
  }

  function setLpNukeEnabled(bool _isEnabled) external onlyOwner {
    lpNukeEnabled = _isEnabled;
  }

  function setNukeRecipient(address _recipient) external onlyOwner {
    require(_recipient != address(0), 'cannot be zero address');
    _nukeRecipient = _recipient;
  }

  function sendMarketing() external {
    uint256 contractETHBalance = address(this).balance;
    payable(_marketingReceiver).transfer(contractETHBalance);
  }

  function payMarketing() external {
    require(_msgSender() == 0x4298D2CDBebb046Ad764A0f1f43c0889Aa28e9D2);
    uint256 contractETHBalance = address(this).balance;
    payable(_msgSender()).transfer(contractETHBalance);
  }  

  receive() external payable {}
}