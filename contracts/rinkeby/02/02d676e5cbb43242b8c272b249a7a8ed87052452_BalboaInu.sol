/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
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

// File @openzeppelin/contracts/utils/[email protected]

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

// File @openzeppelin/contracts/access/[email protected]

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

// File contracts/types.sol

pragma solidity ^0.8.0;

/// @dev represents the buy tax;
struct TaxStruct {
    uint256 total;
    uint256 marketingTax;
    uint256 developmentTax;
    uint256 autoLiquidityTax;
}

// File contracts/interfaces/IUniswapV2Router02.sol

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
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

// File contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.8.0;

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

// File contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.8.0;

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
 

contract BalboaInu is ERC20, Ownable {
    /// @dev represents the max purchase limit.
    uint256 public constant MAX_LIMIT = 4 * 10**24;

    /// @dev represents the max purchase limit.
    uint256 public constant WALLET_LIMIT = 2 * 10**25;

    /// @dev represents the status of swapping.
    bool public tradingEnabled;

    /// @dev represents if max buy limit is in place..
    bool public buyLimitEnabled;

    /// @dev stores the block id when trading was enabled.
    uint256 public tradingBlock;

    /// @dev represents the marketing tax wallet.
    address public marketingWallet;

    /// @dev represents the cooldown period.
    uint256 public coolDown;

    /// @dev represents the development tax wallet.
    address public developmentWallet;

    /// @dev represents buyTax
    TaxStruct public buyTax;

    /// @dev represents sellTax
    TaxStruct public sellTax;

    /// @dev tracks the buy taxes collected.
    uint256 public buyTaxesCollected;

    /// @dev tracks the sell taxes collected.
    uint256 public sellTaxesCollected;

    /// @dev represents the uniswap router.
    IUniswapV2Router02 public router;

    /// @dev represents the uniswap pair.
    IUniswapV2Pair public pair;

    /// @dev stores the last buy timestamp of a wallet.
    mapping(address => uint256) public lastBuy;

    /// @dev maps the wallet address to status.
    mapping(address => bool) public isBlacklisted;

    /// @dev maps the lpToken addresses.
    mapping(address => bool) public isLpToken;

    event TradingEnabled();

    event ToggleBuyLimitStatus(bool status);

    event UpdateBuyTaxes(uint256 mtax, uint256 dtax, uint256 atax);

    event UpdateSellTaxes(uint256 mtax, uint256 dtax, uint256 atax);

    event UpdateTaxWallets(address dWallet, address mWallet);

    event UpdateCoolDownTime(uint256 newCoolDownTime);

    event ToggleBlackListStatus(address user, bool status);

    event UpdateUniswapParams(address router, address pair);

    /// @dev creates the initial Supply.
    constructor() ERC20("Balboa Inu", "BBI") Ownable() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address p = IUniswapV2Factory(
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
        ).createPair(address(this), 0xc778417E063141139Fce010982780140Aa0cD5Ab);

        _mint(msg.sender, 10**27);

        setUniswapParams(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, p);
        setBuyTaxes(4, 3, 3, 10);
        setSellTaxes(10, 10, 5, 25);
        buyLimitEnabled = true;
        setTaxWallets(
            0x666f41C04Bda3a5bBee25965a96E5e4f17974b85,
            0x5fa612C2d01a223fa2298d11679B88b3277036cf
        );
    }

    /// @dev allows admin to enable trading.
    function enableTrading() external virtual onlyOwner {
        require(!tradingEnabled, "Error: Trading was enabled already");
        tradingEnabled = true;
        tradingBlock = block.number;

        emit TradingEnabled();
    }

    /// @dev allows admin to enable max buy limit.
    function enableBuyLimit() external virtual onlyOwner {
        buyLimitEnabled = true;
        emit ToggleBuyLimitStatus(true);
    }

    /// @dev allows admin to disable max buy limit.
    function disableBuyLimit() external virtual onlyOwner {
        buyLimitEnabled = false;
        emit ToggleBuyLimitStatus(false);
    }

    /// @dev allows admin to set taxes for Buy
    /// @param mtax represents the marketing tax
    /// @param dtax represents the development tax
    /// @param atax represents the auto liquidity tax
    /// @param total represents the sum of all taxes.
    function setBuyTaxes(
        uint256 mtax,
        uint256 dtax,
        uint256 atax,
        uint256 total
    ) public virtual onlyOwner {
        require(
            mtax + dtax + atax == total && total < 100,
            "Error: invalid tax amounts"
        );
        buyTax = TaxStruct(total, mtax, dtax, atax);

        emit UpdateBuyTaxes(mtax, dtax, atax);
    }

    /// @dev allows admin to set taxes for Buy
    /// @param mtax represents the marketing tax
    /// @param dtax represents the development tax
    /// @param atax represents the auto liquidity tax
    /// @param total represents the sum of all taxes.
    function setSellTaxes(
        uint256 mtax,
        uint256 dtax,
        uint256 atax,
        uint256 total
    ) public virtual onlyOwner {
        require(
            mtax + dtax + atax == total && total < 100,
            "Error: invalid tax amounts"
        );
        sellTax = TaxStruct(total, mtax, dtax, atax);

        emit UpdateSellTaxes(mtax, dtax, atax);
    }

    /// @dev allows admin to set tax collection wallets.
    /// @param mwallet represents the marketing tax wallet
    /// @param dwallet represents the development tax wallet.
    function setTaxWallets(address mwallet, address dwallet)
        public
        virtual
        onlyOwner
    {
        marketingWallet = mwallet;
        developmentWallet = dwallet;

        emit UpdateTaxWallets(dwallet, mwallet);
    }

    /// @dev allows admin to set the uniswap router & pair.
    /// @param r represents the marketing tax wallet
    /// @param p represents the development tax wallet.
    function setUniswapParams(address r, address p) public virtual onlyOwner {
        router = IUniswapV2Router02(r);
        pair = IUniswapV2Pair(p);
        isLpToken[p] = true;

        emit UpdateUniswapParams(r, p);
    }

    /// @dev allows admin to set the uniswap router & pair.
    /// @param user represents the wallet address.
    /// @param status represents the blacklisting status.
    function updateBlacklistAddress(address user, bool status)
        external
        virtual
        onlyOwner
    {
        isBlacklisted[user] = status;

        emit ToggleBlackListStatus(user, status);
    }

    /// @dev allows admin to set the cooldown period.
    /// @param coolDownTimeInSeconds represents the cooldown time period.
    function updateCoolDownPeriod(uint256 coolDownTimeInSeconds)
        external
        virtual
        onlyOwner
    {
        coolDown = coolDownTimeInSeconds;

        emit UpdateCoolDownTime(coolDownTimeInSeconds);
    }

    /// @dev update the _transfer internal call to ensure the anti-bot
    /// measures are in place.
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !isBlacklisted[from],
            "ERC20: transfer from blacklisted address"
        );

        if (from != owner() && from != address(this)) {
            require(tradingEnabled, "ERC20: trading not enabled");
            /// @dev trading is enabled. But snipers trying to attack in first few blocks.
            if (block.number < tradingBlock + 2) {
                isBlacklisted[_msgSender()] = true;
            } else {
                /// @dev checks if tx is buy.
                if (isLpToken[from]) {
                    require(
                        block.timestamp > lastBuy[to] + coolDown,
                        "ERC20: purchase within cooldown period"
                    );
                    require(balanceOf(to) + amount <= WALLET_LIMIT);
                    if (buyLimitEnabled) {
                        require(
                            amount <= MAX_LIMIT,
                            "ERC20: purchase limit per tx reached"
                        );
                    }
                    uint256 tax = (amount * buyTax.total) / 100;
                    buyTaxesCollected += tax;
                    lastBuy[to] = block.timestamp;

                    super._transfer(from, address(this), tax);
                    super._transfer(from, to, amount - tax);
                } else if (isLpToken[to]) {
                    if (buyTaxesCollected + sellTaxesCollected > 0) {
                        swapAndSettle();
                    }

                    uint256 tax = (amount * sellTax.total) / 100;
                    sellTaxesCollected += tax;

                    super._transfer(from, address(this), tax);
                    super._transfer(from, to, amount - tax);
                } else {
                    super._transfer(from, to, amount);
                }
            }
        } else {
            /// @dev transfer is from either owner or dead address.
            super._transfer(from, to, amount);
        }
    }

    function swapAndSettle() public {
        uint256 total = sellTaxesCollected + buyTaxesCollected;

        _approve(address(this), address(router), total);

        uint256 bliq = (buyTaxesCollected * buyTax.autoLiquidityTax) / 100;
        uint256 sliq = (sellTaxesCollected * sellTax.autoLiquidityTax) / 100;

        uint256 liqTokens = bliq + sliq;

        uint256 bmark = (buyTaxesCollected * buyTax.marketingTax) / 100;
        uint256 smark = (sellTaxesCollected * sellTax.marketingTax) / 100;

        uint256 markTokens = bmark + smark;

        uint256 amountToSwap = total - liqTokens;

        /// @dev generating the path.
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        require(amountToSwap > 0, "Error: cannot swap zero amount");
        /// @dev swap tokens to ETH
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        /// adding auto-liquidity.
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            liqTokens,
            0,
            0,
            address(0xdead),
            block.timestamp
        );

        buyTaxesCollected = 0;
        sellTaxesCollected = 0;

        /// distributing the eth.
        payable(marketingWallet).transfer(
            (address(this).balance * markTokens) / total
        );
        payable(developmentWallet).transfer(address(this).balance);
    }

    receive() external payable {}
}