// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

// Straight from UniSwap V2:
// https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Throw when attempt to execute operations without authorization (not owner)
error SpaceCoin__Unauthorized();

/// @notice Throw when attempt to transfer an invalid amount
error SpaceCoin__InvalidAmount();

/// @notice Throw when provided address is invalid
error SpaceCoin__InvalidAddress();

contract SpaceCoin is ERC20 {
    uint256 public constant ONE_COIN = 10 ** 18;
    uint256 public constant TREASURY_SUPPLY = 350_000 * ONE_COIN;
    uint256 public constant ICO_SUPPLY = 150_000 * ONE_COIN;
    uint256 public constant TAX_PERCENTAGE = 2;
    bool public collectTax;
    address public immutable owner;
    address public immutable treasury;

    /**
     * @notice Emitted when the owner toggles the tax collection capability
     * @param collectTax Value that determines if collect tax is enabled/disabled
     */
    event ToggleTax(bool indexed collectTax);

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert SpaceCoin__Unauthorized();
        }
        _;
    }

    constructor(
        address _owner,
        address _treasury,
        address _icoAddress
    ) ERC20("SpaceCoin", "SPC") {
        // check to prevent being locked out by invalid addresses
        if (
            _isAddressZero(_owner) ||
            _isAddressZero(_treasury) ||
            _isAddressZero(_icoAddress)
        ) {
            revert SpaceCoin__InvalidAddress();
        }

        owner = _owner;
        treasury = _treasury;
        _mint(_treasury, TREASURY_SUPPLY);
        _mint(_icoAddress, ICO_SUPPLY);
    }

    /**
     * @notice Toggle the collection of the `TAX_PERCENTAGE` for every transfer
     * @param _collectTax Boolean representing if the tax collection is enabled or not
     */
    function toggleTax(bool _collectTax) external onlyOwner {
        collectTax = _collectTax;
        emit ToggleTax(_collectTax);
    }

    /**
     * @notice Transfer a specific amount of tokens to another address
     * @param _to The address to receive the tokens
     * @param _amount The amount of tokens to send
     */
    function _transfer(
        address _sender,
        address _to,
        uint256 _amount
    ) internal virtual override {
        if (_amount <= 0) {
            revert SpaceCoin__InvalidAmount();
        }

        if (collectTax) {
            uint256 taxAmount = (_amount * TAX_PERCENTAGE) / 100;
            _amount -= taxAmount;
            super._transfer(_sender, treasury, taxAmount);
        }

        super._transfer(_sender, _to, _amount);
    }

    /**
     * @notice Check if an address is the address zero
     * @param _address Address to be checked
     * @return Bool that represents if the address is zero or not
     */
    function _isAddressZero(address _address) private pure returns (bool) {
        return _address == address(0);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";
import "./libraries/Math.sol";

/// @notice Throw when a transaction failed
error LP__TransactionFailed();

/// @notice Throw when there's insufficient balance to perform the operations
error LP__InsufficientBalance();

/// @notice Throw when invalid input provided
error LP__InvalidTransaction();

contract SpaceLP is ERC20 {
    // SPC contract
    SpaceCoin public immutable spaceCoin;

    // percentage amount to be taken on each swap
    uint256 public constant SWAP_FEE_PERCENT = 1;

    // internal tracking of SPC reserve
    uint256 public spcReserve;

    // internal tracking of ETH reserve
    uint256 public ethReserve;

    // indicates if the contract execution is locked
    // see `nonReentrant` modifier for implementation details
    bool private lock;

    /// @notice Emitted when a deposit is made
    /// @param to The address that received LP tokens from a deposit
    /// @param ethAdded The amount of ETH deposited
    /// @param spcAdded The amount of SPC deposited
    /// @param tokensReceived The amount of LP tokens returned from the deposit
    event Deposit(
        address indexed to,
        uint256 ethAdded,
        uint256 spcAdded,
        uint256 tokensReceived
    );

    /// @notice Emitted when a withdraw is made
    /// @param to The address that received the assets from the withdraw
    /// @param lpTokensBurned The amount of LP tokens burned
    /// @param ethOut The amount of ETH returned
    /// @param spcOut The amount of SPC returned
    event Withdraw(address indexed to, uint256 lpTokensBurned, uint256 ethOut, uint256 spcOut);

    /// @notice Emitted when a trader swaps
    /// @param to The address that received the out tokens
    /// @param amountIn The amount of tokens added to the pool
    /// @param amountOut The amount of tokens removed from the pool
    /// @dev `amountIn` and `amountOut` will change to ETH or SPC depending on the swap direction
    event Swap(address indexed to, uint256 amountIn, uint256 amountOut);

    /// @notice Simple locker to prevent reentrancy attacks
    modifier nonReentrant() {
        require(!lock, "ReentrancyGuard: reentrant call");
        lock = true;
        _;
        lock = false;
    }

    constructor(SpaceCoin _spaceCoin) ERC20("SpaceLP", "SPACE") {
        spaceCoin = _spaceCoin;
    }

    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    function deposit(address to) public payable nonReentrant {
        // total ETH and SPC balance
        (uint256 ethBalance, uint256 spcBalance) = getCurrentBalance();

        // amount of ETH deposited
        uint256 amountEthIn = _getAmountIn(true, ethBalance, spcBalance);

        // amount of SPC deposited
        uint256 amountSpcIn = _getAmountIn(false, ethBalance, spcBalance);

        // track if any value from the token pair is zero
        bool isZeroDepositAmount = amountEthIn == 0 || amountSpcIn == 0;

        if (isZeroDepositAmount) {
            revert LP__InsufficientBalance();
        }

        // Update the pool reserve
        _updateReserves(ethBalance, spcBalance);

        // amount of LP tokens to be minted
        uint256 amountLpTokensOut = _getLpTokensFrom(amountEthIn, amountSpcIn);

        // mint proportional LP tokens
        _mint(to, amountLpTokensOut);

        emit Deposit(to, amountEthIn, amountSpcIn, amountLpTokensOut);
    }

    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    function withdraw(address to) public nonReentrant {
        // amount of LP tokens sent in
        uint256 amountToBurn = balanceOf(address(this));

        // total LP token supply
        uint256 lpTokenSupply = totalSupply();

        // total ETH and SPC balance
        (uint256 ethBalance, uint256 spcBalance) = getCurrentBalance();

        // indicate if any of the withdraw assets has zero balance
        bool isZeroBalance = ethBalance == 0 ||
            spcBalance == 0 ||
            amountToBurn == 0 ||
            lpTokenSupply == 0;

        // spaceCoin address is an invalid destination to withdraw
        bool isInvalidTo = to == address(spaceCoin);

        if (isZeroBalance) {
            revert LP__InsufficientBalance();
        }

        if (isInvalidTo) {
            revert LP__InvalidTransaction();
        }

        // calculate how many ETH/SPC to be returned
        uint256 amountEthOut = (amountToBurn * ethBalance) / lpTokenSupply;
        uint256 amountSpcOut = (amountToBurn * spcBalance) / lpTokenSupply;

        // return ETH
        (bool success, ) = to.call{value: amountEthOut}("");
        if (!success) {
            revert LP__TransactionFailed();
        }

        // return SPC
        spaceCoin.transfer(to, amountSpcOut);

        // burn the LP tokens
        _burn(address(this), amountToBurn);

        // update the pool reserve
        ethBalance -= amountEthOut;
        spcBalance -= amountSpcOut;
        _updateReserves(ethBalance, spcBalance);

        emit Withdraw(to, amountToBurn, amountEthOut, amountSpcOut);
    }

    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    /// @param isETHtoSPC Boolean indicating the direction of the trade
    function swap(
        address to,
        bool isETHtoSPC
    ) public payable nonReentrant returns (uint256) {
        // total ETH and SPC balance
        (uint256 ethBalance, uint256 spcBalance) = getCurrentBalance();

        // amout of value added to the pool
        uint256 amountIn = _getAmountIn(isETHtoSPC, ethBalance, spcBalance);

        // indicate if the reserve has valid amounts to swap
        bool isEmptyReserve = ethReserve == 0 || spcReserve == 0;

        // indicate if there's new amount received by the pool for a valid swap
        bool isZeroSwapAmount = amountIn == 0;

        // spaceCoin address is an invalid destination to swap
        bool isInvalidTo = to == address(spaceCoin);

        if (isEmptyReserve || isZeroSwapAmount) {
            revert LP__InsufficientBalance();
        }

        if (isInvalidTo) {
            revert LP__InvalidTransaction();
        }

        // get the new balance using the constant product formula
        uint256 newBalance = _getNewBalance(isETHtoSPC, amountIn);

        // based on the new balance, get the amount of tokens out
        uint256 amountOut = _getAmountOut(isETHtoSPC, newBalance);

        // transfer the assets based on swap type
        if (isETHtoSPC) {
            spaceCoin.transfer(to, amountOut);
        } else {
            (bool success, ) = to.call{value: amountOut}("");
            if (!success) {
                revert LP__TransactionFailed();
            }
        }

        // update the liquidity pool internal reserves
        ethBalance = isETHtoSPC ? ethBalance : newBalance;
        spcBalance = isETHtoSPC ? newBalance : spcBalance;
        _updateReserves(ethBalance, spcBalance);

        emit Swap(to, amountIn, amountOut);

        return amountOut;
    }

    /// @notice Returns the real and current pool balance
    /// @dev The return value is the actual assets instead of the
    /// internal balance tracked on the storage reserve variables
    function getCurrentBalance() public view returns (uint256, uint256) {
        // total ETH balance
        uint256 ethBalance = address(this).balance;

        // total SPC balance
        uint256 spcBalance = spaceCoin.balanceOf(address(this));

        return (ethBalance, spcBalance);
    }

    /// @notice Updates the current liqidity pool reserves
    /// @param _ethBalance Amount of ETH to update the `ethReserve`
    /// @param _spcBalance Amount of SPC to update the `spcReserve`
    function _updateReserves(
        uint256 _ethBalance,
        uint256 _spcBalance
    ) internal {
        ethReserve = _ethBalance;
        spcReserve = _spcBalance;
    }

    /// @notice Returns the new amount sent in to the pool
    /// @param isETHtoSPC Boolean indicating which amount type to return
    /// @param _ethBalance Total ETH balance on the pool
    /// @param _spcBalance Total SPC balance on the pool
    /// @dev when `isETHtoSPC` is `true` returns ETH; when it is `false` returns SPC
    function _getAmountIn(
        bool isETHtoSPC,
        uint256 _ethBalance,
        uint256 _spcBalance
    ) internal view returns (uint256) {
        // return the amount sent in by diffing the current balance
        // and the internal tracked reserves of each asset on the pool
        if (isETHtoSPC) {
            return _ethBalance - ethReserve;
        } else {
            return _spcBalance - spcReserve;
        }
    }

    /// @notice Returns the amount of LP tokens proportional to ETH/SPC contribution
    /// @param _amountEthIn Amount of ETH tokens deposited
    /// @param _amountSpcIn Amount of SPC tokens deposited
    function _getLpTokensFrom(
        uint256 _amountEthIn,
        uint256 _amountSpcIn
    ) internal view returns (uint256) {
        // total LP tokens minted so far
        uint256 _totalSupply = totalSupply();

        // when it's the first deposit
        if (_totalSupply == 0) {
            // use geometric mean to initiate the LP tokens supply
            return Math.sqrt(_amountEthIn * _amountSpcIn);
        } else {
            // for the other cases, calculate the percentage that the tokens added are
            // relative to the total reserve, and generate the number of new LP tokens
            uint256 lpTokenAmountFromEth = (_amountEthIn * _totalSupply) / ethReserve;
            uint256 lpTokenAmountFromSpc = (_amountSpcIn * _totalSupply) / spcReserve;
            // to prevent minting incorrect amount of LP tokens from an
            // unbalanced deposit, return the lowest amount from the pair
            return Math.min(lpTokenAmountFromEth, lpTokenAmountFromSpc);
        }
    }

    /// @notice Returns the new balance for a given token applying the constant product formula
    /// and taking into consideration the liquidity pool swap fee
    /// @param isETHtoSPC Boolean indicating which balance type to return
    /// @param _amountIn Amount of ETH tokens deposited
    function _getNewBalance(
        bool isETHtoSPC,
        uint256 _amountIn
    ) internal view returns (uint256) {
        // use the complementary value of the swap fee percentage
        uint256 percentageFee = 100 - SWAP_FEE_PERCENT;

        // amount of tokens in minuts the percentage fee
        uint256 amountInMinusFee = (_amountIn * percentageFee) / 100;

        // this is the `k`, using the previous `x` and `y`
        uint256 numerator = ethReserve * spcReserve;

        // depending on the swap, this is the `x` or `y`
        // for each one, select the current ETH or SPC reserve
        uint256 denominator = isETHtoSPC ? ethReserve : spcReserve;

        // increase the denominator with the amount in minus the fees
        denominator += amountInMinusFee;

        // return the new balance
        return numerator / denominator;
    }

    /// @notice Returns the expected amount of tokens to be sent out on a swap
    /// @param isETHtoSPC Boolean indicating which amount type to return
    /// @param _newBalance The new balance of the given asset on the pool
    function _getAmountOut(
        bool isETHtoSPC,
        uint256 _newBalance
    ) internal view returns (uint256) {
        // depending on the swap, select the previous balance using the current reserve
        uint256 previousBalance = isETHtoSPC ? spcReserve : ethReserve;
        // return the amount out by diffing the previous with the new balance
        return previousBalance - _newBalance;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./SpaceLP.sol";
import "./SpaceCoin.sol";

/// @notice Throw when a transaction failed
error Router__TransactionFailed();

/// @notice Throw when there's insufficient balance to perform the operations
error Router__InsufficientBalance();

/// @notice Throw when out amount is not in the slippage protection boundry
error Router__InsufficientOutAmount();

contract SpaceRouter {
    SpaceLP public immutable spaceLP;
    SpaceCoin public immutable spaceCoin;

    constructor(SpaceLP _spaceLP, SpaceCoin _spaceCoin) {
        spaceLP = _spaceLP;
        spaceCoin = _spaceCoin;
    }

    /// @notice Provides ETH-SPC liquidity to LP contract
    /// @param spc The amount of SPC to be deposited
    function addLiquidity(uint256 spc) public payable {
        // track if both assets are provided
        bool isZeroDepositAmount = msg.value == 0 || spc == 0;

        if (isZeroDepositAmount) {
            revert Router__InsufficientBalance();
        }

        // amount of ETH provided
        uint256 desiredEthIn = msg.value;

        // amount of SPC provided
        uint256 desiredSpcIn = spc;

        // given the desired ETH and SPC provided, get the optimal amount
        // of each, while maintaining the current liquidity pool ratio
        (uint256 optimalEthAmount, uint256 optimalSpcAmount) = getOptimalPrice(
            desiredEthIn,
            desiredSpcIn
        );

        // transfer SPC
        spaceCoin.transferFrom(msg.sender, address(spaceLP), optimalSpcAmount);

        // send deposit request to the liquidity pool
        spaceLP.deposit{value: optimalEthAmount}(msg.sender);

        // if unbalanced amount of assets provided,
        // perform a refund with the remainder assets
        if (desiredEthIn > optimalEthAmount) {
            uint256 ethToRefund = desiredEthIn - optimalEthAmount;
            (bool success, ) = msg.sender.call{value: ethToRefund}("");
            if (!success) {
                revert Router__TransactionFailed();
            }
        }
    }

    /// @notice Removes ETH-SPC liquidity from LP contract
    /// @param lpToken The amount of LP tokens being returned
    function removeLiquidity(uint256 lpToken) public {
        if (lpToken == 0) {
            revert Router__InsufficientBalance();
        }

        spaceLP.transferFrom(msg.sender, address(spaceLP), lpToken);
        spaceLP.withdraw(msg.sender);
    }

    /// @notice Swaps ETH for SPC in LP contract
    /// @param spcOutMin The minimum acceptable amout of SPC to be received
    function swapETHForSPC(uint256 spcOutMin) public payable {
        uint256 amountOut = spaceLP.swap{value: msg.value}(msg.sender, true);
        if (amountOut < spcOutMin) {
            revert Router__InsufficientOutAmount();
        }
    }

    /// @notice Swaps SPC for ETH in LP contract
    /// @param spcIn The amount of inbound SPC to be swapped
    /// @param ethOutMin The minimum acceptable amount of ETH to be received
    function swapSPCForETH(uint256 spcIn, uint256 ethOutMin) public {
        spaceCoin.transferFrom(msg.sender, address(spaceLP), spcIn);
        uint256 amountOut = spaceLP.swap(msg.sender, false);
        if (amountOut < ethOutMin) {
            revert Router__InsufficientOutAmount();
        }
    }

    /// @notice Get the optimal amount of ETH and SPC to be added to the pool
    /// @dev Takes in consideration the fact that each deposit must respect the pool ratio
    /// @param desiredEth The desired amount of ETH to be added
    /// @param desiredSpc The desired amount of SPC to be added
    function getOptimalPrice(
        uint256 desiredEth,
        uint256 desiredSpc
    ) public view returns (uint256, uint256) {
        // get the current liquidity pool balance
        (uint256 ethBalance, uint256 spcBalance) = spaceLP.getCurrentBalance();

        // track if the liqudity pool has balance
        bool isZeroBalance = ethBalance == 0 && spcBalance == 0;

        // when the balance is zero, it's the first deposit;
        // in that case, return the amount desired for each asset,
        // so the pool ratio will be defined by them
        if (isZeroBalance) {
            return (desiredEth, desiredSpc);
        }

        // calculate the optimal amount of ETH
        uint256 optimalEth = (desiredSpc * ethBalance) / spcBalance;

        // calculate the optimal amount of SPC
        uint256 optimalSpc = (desiredEth * spcBalance) / ethBalance;

        // ensure that the optimal amount of SPC is within
        // the boundry of the desired SPC provided
        if (optimalSpc <= desiredSpc) {
            return (desiredEth, optimalSpc);
        } else {
            // use the optimal ETH amount instead,
            // and limit the SPC to the desired amount
            return (optimalEth, desiredSpc);
        }
    }
}