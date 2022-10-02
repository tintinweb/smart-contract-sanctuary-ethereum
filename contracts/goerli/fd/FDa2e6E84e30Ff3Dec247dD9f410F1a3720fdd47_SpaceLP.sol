//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

contract SpaceLP is ERC20 {
    SpaceCoin public immutable spaceCoin;

    uint256 public ethReserve;
    uint256 public spaceCoinReserve;

    error FailToTransferEth();
    error FailToTransferSpaceCoin();
    error CannotSwapToEth();
    error CannotSwapToSpaceCoin();
    error NothingToSwap();
    error OneOfTheTokenMustBeZero();
    error NoLiquidityInPool();
    error NoLiquidityToSwap();

    event Deposit(address indexed recipient, uint256 liquidity);
    event Withdraw(address indexed recipient, uint256 liquidty);
    event Swap(
        address indexed to,
        uint256 amountEthIn,
        uint256 amountSpaceCoinIn,
        uint256 amountEthOut,
        uint256 amountSpaceCoinOut
    );

    constructor(SpaceCoin _spaceCoin)
        ERC20("SpaceCoin-Ether LP", "SpaceCoin-Ether LP")
    {
        spaceCoin = _spaceCoin;
    }

    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    function deposit(address to) external {
        // get total balance of ETH and space coin
        uint256 ethBalance = address(this).balance;
        uint256 spaceCoinBalance = spaceCoin.balanceOf(address(this));

        // get added eth & spaceCoin
        uint256 _ethReserve = ethReserve;
        uint256 _spaceCoinReserve = spaceCoinReserve;

        uint256 addedEth = ethBalance - _ethReserve;
        uint256 addedSpaceCoin = spaceCoinBalance - _spaceCoinReserve;

        uint256 _totalLiquidity = totalSupply();
        uint256 liquidity = 0;

        // check liquidity
        // if zero, create liquidity
        if (_totalLiquidity == 0) {
            liquidity = addedEth * addedSpaceCoin;
        } else {
            // else add liquidity
            uint256 liquidityEth = (_totalLiquidity * addedEth) / _ethReserve;
            uint256 liquiditySpaceCoin = (_totalLiquidity * addedSpaceCoin) /
                _spaceCoinReserve;

            // mint the lower liquditiy amount
            // the extra will be 'donated' to the pool
            liquidity = liquidityEth > liquiditySpaceCoin
                ? liquiditySpaceCoin
                : liquidityEth;
        }
        ethReserve += addedEth;
        spaceCoinReserve += addedSpaceCoin;

        _mint(to, liquidity);
        emit Deposit(to, liquidity);
    }

    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    function withdraw(address to) external {
        uint256 _totalLiquidity = totalSupply();

        if (_totalLiquidity == 0) {
            revert NoLiquidityInPool();
        }
        
        uint256 thisLiquidity = balanceOf(address(this));
        uint256 ethWithdrawn = (ethReserve * thisLiquidity) / _totalLiquidity;
        uint256 spaceCoinWithdrawn = (spaceCoinReserve * thisLiquidity) /
            _totalLiquidity;

        ethReserve -= ethWithdrawn;
        spaceCoinReserve -= spaceCoinWithdrawn;

        _burn(address(this), thisLiquidity);

        // transfer eth to 'to'
        (bool successEth, ) = to.call{value: ethWithdrawn}("");
        if (!successEth) {
            revert FailToTransferEth();
        }

        // transfer spacecoin to 'to'
        bool successSpaceCoin = spaceCoin.transfer(to, spaceCoinWithdrawn);
        if (!successSpaceCoin) {
            revert FailToTransferSpaceCoin();
        }

        emit Withdraw(to, thisLiquidity);
    }

    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    function swap(address to) external returns (uint256) {
        // get total balance of ETH and space coin
        // get added eth & spaceCoin

        uint256 _ethReserve = ethReserve;
        uint256 _spaceCoinReserve = spaceCoinReserve;

        if (_ethReserve == 0 && _spaceCoinReserve == 0) {
            revert NoLiquidityToSwap();
        }

        uint256 addedEth = address(this).balance - _ethReserve;
        uint256 addedSpaceCoin = spaceCoin.balanceOf(address(this)) -
            _spaceCoinReserve;

        if (addedEth == 0 && addedSpaceCoin == 0) {
            revert NothingToSwap();
        }

        if (addedEth != 0 && addedSpaceCoin != 0) {
            revert OneOfTheTokenMustBeZero();
        }

        uint256 k = _ethReserve * _spaceCoinReserve;

        if (addedEth != 0) {
            uint256 effectiveTokenAfterFees = (addedEth * 99) / 100;

            uint256 _ethReserveAdded = _ethReserve + effectiveTokenAfterFees;

            uint256 spcSwappedAmount = _spaceCoinReserve -
                (k / _ethReserveAdded);

            // update reserve here
            ethReserve = _ethReserve + addedEth;
            spaceCoinReserve = _spaceCoinReserve - spcSwappedAmount;

            bool success = spaceCoin.transfer(to, spcSwappedAmount);
            if (!success) {
                revert CannotSwapToSpaceCoin();
            }

            emit Swap(to, addedEth, addedSpaceCoin, 0, spcSwappedAmount);
            return spcSwappedAmount;
        } else {
            uint256 effectiveTokenAfterFees = (addedSpaceCoin * 99) / 100;

            uint256 _spcReserveAdded = _spaceCoinReserve +
                effectiveTokenAfterFees;

            uint256 ethSwappedAmount = _ethReserve - (k / _spcReserveAdded);

            // update reserve here
            ethReserve = _ethReserve - ethSwappedAmount;
            spaceCoinReserve = _spaceCoinReserve + addedSpaceCoin;

            (bool success, ) = to.call{value: ethSwappedAmount}("");
            if (!success) {
                revert CannotSwapToEth();
            }

            emit Swap(to, addedEth, addedSpaceCoin, ethSwappedAmount, 0);
            return ethSwappedAmount;
        }
    }

    /// @notice Receive function so that the LP pool can receive ETH
    receive() external payable {}

    /**
     * Return the reserves of the tokens in one call
     * @return _ethReserve the eth reserve
     * @return _spcReserve the space coin reserve
     */
    function getReserves()
        external
        view
        returns (uint256 _ethReserve, uint256 _spcReserve)
    {
        _ethReserve = ethReserve;
        _spcReserve = spaceCoinReserve;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    /**
     * Owner of this contract
     * @dev It is in the spec that the owner is non-transferable
     */
    address public immutable owner;

    /**
     * The treasury of the address of which the tax will be sent to
     * @dev Assumed to be an EOA for the time being. Treasury cannot be changed after
     * deployment
     */
    address public immutable treasury;

    /**
     * Status to present if there is tax per transfer.
     * Toggle-able by the owner. Has no tax initially
     */
    bool public hasTax;

    /**
     * The tax rate per transfer that will be sent to the treasury
     */
    uint256 public constant taxRate = 2;

    error NotOwner();

    event TaxStatus(bool hasTax);
    event TaxAmount(uint256 amount);

    constructor(
        address _owner,
        address _icoContract,
        address _treasury
    ) ERC20("SpaceCoin", "SPC") {
        owner = _owner;
        treasury = _treasury;
        _mint(_treasury, 350_000 * 10**decimals());
        _mint(_icoContract, 150_000 * 10**decimals());
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        _;
    }

    /**
     * Owner only function to set if the transfer incurs tax
     * @param _hasTax True or false
     */
    function setHasTax(bool _hasTax) external onlyOwner {
        hasTax = _hasTax;

        emit TaxStatus(_hasTax);
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address from = _msgSender();

        if (hasTax) {
            amount = _transferTax(amount, from);
        }

        _transfer(from, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        if (hasTax) {
            amount = _transferTax(amount, from);
        }

        _transfer(from, to, amount);
        return true;
    }

    function _transferTax(uint256 amount, address from)
        internal
        returns (uint256)
    {
        uint256 taxedAmount = (amount * taxRate) / 1e2;
        amount = amount - taxedAmount;

        _transfer(from, treasury, taxedAmount);

        emit TaxAmount(taxedAmount);

        return amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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