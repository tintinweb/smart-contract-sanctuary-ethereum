/**
 *Submitted for verification at Etherscan.io on 2023-01-10
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

// File: kickass.sol



//DogeBank | MemeBank © 2023

//A Decentralised Bank - Banking projects,

pragma solidity ^0.8.4;








contract DogeBankToken is ERC20, Ownable {

    modifier admin(){

		require(msg.sender == _adminWallet);

		_;

	}

    modifier lockSwap {

        require(!_inSwap);

        _inSwap = true;

        _;

        _inSwap = false;

    }

    modifier liquidityAdd {

        _inLiquidityAdd = true;

        _;

        _inLiquidityAdd = false;

    }

    modifier reentrant {

        require(!_inTransfer);

        _inTransfer = true;

        _;

        _inTransfer = false;

    }

    modifier OnlyCharity(){

		require(msg.sender == _charityBeneficiary);

		_;

	}

    uint public _buyRate = 5;//adjustable

    uint public _sellRate = 5;//adjustable

    uint256 public bonfirePool;

    uint256 public _maxHoldings = 18000000 * 1e18;

    uint256 private _feeTokens;

    uint256 public _holders;

    uint256 private _tradingStart;

    uint256 private _tradingStartBlock;

    uint256 public _totalSupply;

    uint256 public _charityPool;

    uint256 public _ethRewardBasis;

    uint256 public _netRewardClaims;

    uint256 public _totalBeneficiaryAssigns;

    uint256 public _beneficiaryReward;

    address public _pairAddress;

    address payable public _bornFireWallet;

    address payable private _marketingWallet;

    address payable private _developmentWallet;

    address private _adminWallet;

    address payable public _charityBeneficiary;

    address constant public _burnAddress = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));

    bool internal _inSwap = false;

    bool internal _inTransfer = false;

    bool internal _inLiquidityAdd = false;

   

    mapping(address => bool) private _rewardExclude;

    mapping(address => bool) private _taxExcluded;

    mapping(address => bool) private _teamLocked;

    mapping(address => bool) private _bot;

    mapping(address => uint256) private _tradeBlock; 

    mapping(address => uint256) private _balances;

    mapping(address => uint256) public _lastRewardBasis;

    mapping(address => uint256) public _netEthRewardedWallet;

    mapping(address => uint256) public _netRewardsmyDonors;

    mapping(address => uint256) public _netRewardsTomyBE;

    mapping(address => address) public _claimBeneficiary;

    mapping(address => myBenefactors) private _privateList;

    

    event ClaimReflection(address indexed claimer, uint256 reflection);

    event BuyBack(address indexed torcher, uint256 ethbuy, uint256 amount);

    event Donation(address indexed charity, uint256 auctioned);

  

    constructor(address payable developmentAddr, address payable marketingAddr) ERC20("DOGE BANK", "DBANK"){

        _marketingWallet = marketingAddr;

        _developmentWallet = developmentAddr;

        addTaxExcluded(owner());

        addTaxExcluded(address(this));

        addTaxExcluded(_burnAddress);

        addTaxExcluded(marketingAddr);

        addTaxExcluded(developmentAddr);

        //Uniswap

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this),_uniswapV2Router.WETH());

        _router = _uniswapV2Router;

    }

    function addLiquidity() public payable onlyOwner() liquidityAdd {

        uint256 tokens = 1000000000 * 1e18;

        uint256 LPtokens = (tokens * 90) / 100;

        uint256 teamTokens = tokens - LPtokens;

        _mint(address(this), LPtokens);

        _mint(msg.sender, teamTokens);

        _approve(address(this), address(_router), LPtokens);

        _router.addLiquidityETH{value: msg.value}(

            address(this),LPtokens,0,0,owner(),block.timestamp

        );

    }

    function circulatingSupply() public view returns (uint256) {

        return _totalSupply - balanceOf(_burnAddress);

    }

    //taxes

    function isTaxExcluded(address account) public view returns (bool) {

        return _taxExcluded[account];

    }

    function addTaxExcluded(address account) internal {

        _taxExcluded[account] = true;

    }

    function addTaxExcludedArray(address[] calldata accounts) public onlyOwner {

        for(uint256 i = 0; i < accounts.length; i++) {

                 _taxExcluded[accounts[i]] = true;

        }

    }

    //team lock

    function addTeamLock(address account) public admin() {

        _teamLocked[account] = true;

    }

    function isTeamLocked(address account) public view returns (bool) {

        return _teamLocked[account];

    }

    //bot accounts on uniswap trading from router

    function isBot(address account) public view returns (bool) {

        return _bot[account];

    }

    function _addBot(address account) internal {

        _bot[account] = true;

        _rewardExclude[account] = true;

    }

    function addBot(address account) public admin() {

        if(account == address(_router) || account == _pairAddress){revert();}

        _addBot(account);

    }

    function removeBot(address account) public admin() {

        _bot[account] = false;

        _rewardExclude[account] = false;

    }

    //token balances

    function _addBalance(address account, uint256 amount) internal {

        _balances[account] = _balances[account] + amount;

    }

    function _subtractBalance(address account, uint256 amount) internal {

        _balances[account] = _balances[account] - amount;

    }

    //------------------------------------------------------------------

    //Transfer overwrites erc-20 method. 

    function _transfer(

        address sender,

        address recipient,

        uint256 amount

    ) internal override {

        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {

            if(balanceOf(recipient) == 0){_holders +=1; }//before

            _rawTransfer(sender, recipient, amount);

            if(balanceOf(sender) == 0){_holders -= 1;}//after

            return;

        }

        //automatic start to trading

        require(_tradingStartBlock != 0 && block.number >= _tradingStartBlock);

        require(!isBot(sender) && !isBot(msg.sender) && !isBot(recipient));

        require(_inLiquidityAdd || _inSwap || amount <= _maxHoldings);

        if (isTeamLocked(sender)){

            require(block.timestamp > (_tradingStart + (1 * 60 * 60 * 24 * 30)),"team tokens locked 30 days");

        }

        //if snipers or mev devs manipulate block number

        if(block.number <= _tradingStartBlock && sender == _pairAddress){

            _addBot(recipient);

        }

        if (!_inSwap && _feeTokens > 0 && recipient == _pairAddress) {

            _swap(_feeTokens);

        }

        //indicates swap

        uint256 send = amount; uint256 selltaxtokens; uint256 buytaxtokens; 

        // Buy

        if (sender == _pairAddress) {

            require(balanceOf(recipient)+amount<_maxHoldings);

            (send,buytaxtokens) = _getTax(amount, _buyRate);

        }

        // Sell

        if (recipient == _pairAddress) {

            require(amount<_maxHoldings);

            (send,selltaxtokens) = _getTax(amount, _sellRate);

        }

        //transfer

        _rawTransfer(sender, recipient, send);

        //take sell taxrevenue

        if(selltaxtokens>0){

            _takeSellTax(sender, selltaxtokens);

        }

        //take buy tax

        if(buytaxtokens>0){

            _takeBuyTax(sender, buytaxtokens);

        }

        //anti snipe the mev mechants (in addition to deadblocks)

        if(sender == _pairAddress){

            _tradeBlock[recipient] = block.number;

        }

        if(recipient == _pairAddress && _tradeBlock[sender] == block.number){

            _addBot(sender);

        }

    }

    //liquidate fee tokens on each sell tx

    function _swap(uint256 amountSwap) internal lockSwap {

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = _router.WETH();

        _approve(address(this), address(_router), amountSwap);

        uint256 balanceB4 = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(

            amountSwap,

            0,

            path,

            address(this),

            block.timestamp

        ); 

        uint256 swappedETH = address(this).balance - balanceB4;

        //finally adjust feeTokens

        _feeTokens -= amountSwap;

        //send eth balance

        uint256 marketingETH = (swappedETH * 60) / 100;

        uint256 teamETH = (swappedETH * 10) / 100;

        uint256 reflectionsETH = (swappedETH * 10) / 100;

        uint256 charityETH = (swappedETH * 5) / 100;

        //send funds

        _ethRewardBasis += reflectionsETH;

        _charityPool += charityETH;

        uint256 burnETH = swappedETH - marketingETH - teamETH - reflectionsETH - charityETH;

        bonfirePool += burnETH;

        //transfer

        _paymentETH(_bornFireWallet, burnETH);

        _paymentETH(_marketingWallet, marketingETH);

        _paymentETH(_developmentWallet, teamETH); 

    }

    //bonfire/buy backs

    function bonfireEvent(uint swapdeadline) public payable returns (uint256) {

        address[] memory path = new address[](2);

        path[0] = _router.WETH();

        path[1] = address(this);

        uint deadline = block.timestamp + swapdeadline;

        uint[] memory tokens_ = _router.swapExactETHForTokens{value: msg.value}(0, path, payable(_burnAddress), deadline);

        uint256 outputTokenCount = uint256(tokens_[tokens_.length - 1]);

        if(outputTokenCount >0){

            emit BuyBack(msg.sender, msg.value, outputTokenCount);

        }else{revert();}

        return outputTokenCount;

    }

    //charity withdrawal

    function charityWithdraw() public OnlyCharity() {

        uint256 donation = _charityPool;

        _paymentETH(_charityBeneficiary, donation);

        _charityPool -= donation;

        emit Donation(msg.sender, donation);

    }

    //REFLECTIONS

    struct myBenefactors {

        address[] myDonors;

        mapping(address => uint) myDonorsIndex;

    }

    //add reflection beneficiary

    function addBeneficiary(address account) public{

        require(!isBot(msg.sender) && !isBot(account));

        require(_claimBeneficiary[msg.sender] != account, "Already added as Donor");

       //adding self as donor to beneficiarys private storage

       _claimBeneficiary[msg.sender] = account;//who is wallets beneficiary..1 max

       _privateList[account].myDonors.push(msg.sender);

       uint index = _privateList[account].myDonors.length;

       //store key

       _privateList[account].myDonorsIndex[msg.sender] = index;//add self

       _totalBeneficiaryAssigns += 1;

    }

    function removeBeneficiary(address account) public{

        require(_privateList[account].myDonorsIndex[msg.sender] != 0,"you are not in donors list!");

       //removing beneficiary by restoring myself

       _claimBeneficiary[msg.sender] = msg.sender;

       uint index = _privateList[account].myDonorsIndex[msg.sender];

       //remove myself as donor from his array of donors

       uint lastIndex = _privateList[account].myDonors.length;

       _privateList[account].myDonors[index - 1] = _privateList[account].myDonors[lastIndex];

       _privateList[account].myDonors.pop();

       _privateList[account].myDonorsIndex[msg.sender] = 0; //reset

       _totalBeneficiaryAssigns -= 1;

    }

    function viewBenefactors() public view returns(address[] memory){

       return _privateList[msg.sender].myDonors;

    }

    function currentDonorRewards(address addr) public view returns(uint n, uint256 netreward) {

        n = _privateList[addr].myDonors.length;

        for (uint i = 0; i < n; i++) {

            //sum the rewards

            netreward += currentRewardForWallet(_privateList[addr].myDonors[i]);

            if(i == n-1){break;}

        }

        return (n, netreward);

    }

    function currentRewardForWallet(address addr) public view returns(uint256) {

        uint256 ethChange = _ethRewardBasis - _lastRewardBasis[addr];

        return (ethChange * balanceOf(addr)) / (circulatingSupply() - balanceOf(_pairAddress));

    }

    function claimReflection() public reentrant(){

        require(!_rewardExclude[msg.sender]);//covers bots

        uint winpass; uint256 netreward;

        uint n = _privateList[msg.sender].myDonors.length;

        if(isTaxExcluded(msg.sender)){winpass=1;}

        netreward = currentRewardForWallet(msg.sender);

        

        if(n>0){

            for (uint i = 0; i < n; i++) {

                address donor = _privateList[msg.sender].myDonors[i];

                uint256 owed = currentRewardForWallet(donor);

                _netRewardsmyDonors[msg.sender] += owed;

                _netRewardsTomyBE[donor] += owed;

                netreward += owed; _beneficiaryReward += owed; 

                _lastRewardBasis[donor] = _ethRewardBasis;

                //break

                if(i == n-1){break;}

            }

        }

        if(netreward>0){

            _paymentETH(msg.sender, netreward);

            _netRewardClaims += netreward;

            _netEthRewardedWallet[msg.sender] += netreward;

            _lastRewardBasis[msg.sender] = _ethRewardBasis;

            emit ClaimReflection(msg.sender, netreward);

        }        

    }

    function _paymentETH(address receiver, uint256 amount) internal {

        (bool sent, ) = receiver.call{value: amount}("");

        require(sent, "Failed to send Ether");

    }

    function _takeSellTax(address account, uint256 totalFees) internal {

        _feeTokens += totalFees;

        _rawTransfer(account, address(this), totalFees);

    }

    function _takeBuyTax(address sender,  uint256 totalFees) internal {

        _feeTokens += totalFees;

        _rawTransfer(sender, address(this), totalFees);

    }

    function _getTax(uint256 amount, uint taxRate)internal pure returns (uint256 send, uint256 tax){

        tax = (amount * taxRate) / 100;

        send = amount - tax;

        return(send, tax);

    }

    //setters

    function setBuyTax(uint rate) external admin() {

        require( rate >= 0 && rate <= 10); 

        _buyRate = rate;

    }

    function setSellTax(uint rate) external admin() {

        require( rate >= 0 && rate <= 10); 

        _sellRate = rate;

    }

    function setAdmin(address payable _wallet) external onlyOwner(){

        _adminWallet = _wallet;

    }

    function setDevelopment(address payable _wallet) external admin(){

        _developmentWallet = _wallet;

    }

    function setMarketing(address payable _wallet) external admin(){

        _marketingWallet = _wallet;

    }

    function setBornfire(address payable _wallet) external admin(){

        _bornFireWallet = _wallet;

    }

    function setCharityWallet(address payable _charityWallet) external admin(){

        _charityBeneficiary = _charityWallet;

    }

    function setMaxHoldings(uint256 maxHoldings) external admin() {

        _maxHoldings = maxHoldings;

    }

    function setTradingStart(bool _tradingOpen) external onlyOwner() {

        if(_tradingOpen){

            _tradingStartBlock = block.number;

            _tradingStart = block.timestamp;

        }else{}//cant stop trading        

    }

    // modified from OpenZeppelin ERC20

    function _rawTransfer(

        address sender,

        address recipient,

        uint256 amount

    ) internal {

        require(sender != address(0));

        require(recipient != address(0));



        uint256 senderBalance = balanceOf(sender);

        require(senderBalance >= amount);

        unchecked {

            _subtractBalance(sender, amount);

        }

        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);

    }

    function balanceOf(address account) public view virtual override returns (uint256){

        return _balances[account];

    }

    function totalSupply() public view override returns (uint256) {

        return _totalSupply;

    }

    function _mint(address account, uint256 amount) internal override {

        require(_totalSupply < 1000000001 * 1e18);

        _totalSupply += amount;

        _addBalance(account, amount);

        emit Transfer(address(0), account, amount);

    }

    

    receive() external payable {}

}