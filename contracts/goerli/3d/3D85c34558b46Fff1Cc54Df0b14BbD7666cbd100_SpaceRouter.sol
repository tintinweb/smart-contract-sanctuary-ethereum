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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    uint256 private constant MAX_SUPPLY = 500000;
    uint256 private constant TRANSFER_TAX = 2;

    address public immutable owner;
    address public immutable treasury;
    bool public transferTaxEnabled;

    /**
     * Sets initial state and mints 500,000 SPC to the minter and treasury.
     * @param _minter The recipient address for the specified _minterSupply amount of SPC tokens
     * @param _owner The address of the contract owner
     * @param _treasury The address of the contract treasury
     * @param _minterSupply The amount of SPC to mint to the given minter, with the rest going to the treasury
     */
    constructor(
        address _minter,
        address _owner,
        address _treasury,
        uint256 _minterSupply
    ) ERC20("SpaceCoin", "SPC") {
        if (_minterSupply > MAX_SUPPLY) {
            revert InvalidMinterSupply(_minterSupply);
        }

        owner = _owner;
        treasury = _treasury;

        _mint(_minter, _minterSupply * 10**decimals());
        _mint(_treasury, (MAX_SUPPLY - _minterSupply) * 10**decimals());
    }

    /**
     * Modifier that reverts if the msg.sender is not the owner of the contract.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
        _;
    }

    /**
     * Owner-only function that toggles the transfer tax on and off.
     */
    function toggleTax() external onlyOwner {
        transferTaxEnabled = !transferTaxEnabled;
        emit ToggleTax(transferTaxEnabled);
    }

    /**
     * Function override for the ERC20 _transfer helper function. If the transfer tax is enabled,
     * sends 2% of the specified _amount to the contract treasury.
     * @param _from The sender address of the tokens
     * @param _to The recipient address of the tokens
     * @param _amount The amount of SPC tokens to transfer
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        if (transferTaxEnabled) {
            super._transfer(_from, treasury, (TRANSFER_TAX * _amount) / 100);
        }

        uint256 postTaxAmount = transferTaxEnabled
            ? ((100 - TRANSFER_TAX) * _amount) / 100
            : _amount;
        super._transfer(_from, _to, postTaxAmount);
    }

    // Events
    event ToggleTax(bool enabled);

    // Errors
    error Unauthorized(address user);
    error InvalidMinterSupply(uint256 supply);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

contract SpaceLP is ERC20 {
    // Constants
    uint256 public constant TRADE_FEE_PERCENTAGE = 1;

    // Storage
    SpaceCoin public immutable spaceCoin;

    uint256 public spcReserve;
    uint256 public ethReserve;

    // Events
    event Deposit(
        address indexed to,
        uint256 liquidity,
        uint256 spcIn,
        uint256 ethIn
    );
    event Withdrawal(
        address indexed to,
        uint256 liquidity,
        uint256 spcOut,
        uint256 ethOut
    );
    event Swap(
        address indexed to,
        bool indexed isETHToSPC,
        uint256 input,
        uint256 output
    );

    // Errors
    // Deposit Errors
    error NoDepositLiquidity(address to, uint256 spcIn, uint256 ethIn);

    // Withdraw Errors
    error NoSPCWithdrawalOutput(address to, uint256 liquidity);
    error NoETHWithdrawalOutput(address to, uint256 liquidity);
    error ETHWithdrawalFailed(address to, uint256 amount);

    // Swap Errors
    error ETHSwapReceiveFailed(address to, uint256 amount);
    error NoETHSwapOutput(address to, uint256 spcIn);
    error NoSPCSwapOutput(address to, uint256 ethIn);

    /// @notice Initialize the contract as a ERC-20 token
    /// @param _spaceCoin The address of the SPC token
    constructor(SpaceCoin _spaceCoin) ERC20("Space LP Token", "SLP") {
        spaceCoin = _spaceCoin;
    }

    /// @notice Returns the min of the 2 provided parameters.
    /// @param _a The first integer
    /// @param _b The second integer
    /// @return The min value of _a and _b
    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    /// @notice Get the constant product output, with a 1% trade fee applied on the input.
    /// @param _b1 The initial value of b
    /// @param _a1 The initial value of a
    /// @param _aInput The additional input value of a
    /// @return bOutput The amount of b that should be given to the user
    function _getConstantProductOutput(
        uint256 _b1,
        uint256 _a1,
        uint256 _aInput
    ) private pure returns (uint256 bOutput) {
        // a1 * b1 = a2 * b2 --> b2 = a1 * b1 / a2
        // a2 = a1 + (input * (100 - TRADE_FEE_PERCENTAGE)) / 100
        // output = b1 - b2
        uint256 a2 = _a1 + (_aInput * (100 - TRADE_FEE_PERCENTAGE)) / 100;
        uint256 b2 = (_a1 * _b1) / a2;
        bOutput = _b1 - b2;
        return bOutput;
    }

    /// @notice Helper function to update reserve values in storage.
    /// @param _spcReserve The new value of the SPC reserve
    /// @param _ethReserve The new value of the ETH reserve
    function _updateReserves(uint256 _spcReserve, uint256 _ethReserve) private {
        spcReserve = _spcReserve;
        ethReserve = _ethReserve;
    }

    /// @notice Helper function to get the current SPC and ETH balances.
    /// @return spcBalance The current amount of SPC in the LP
    /// @return ethBalance The current amount of ETH in the LP
    function _getBalances()
        private
        view
        returns (uint256 spcBalance, uint256 ethBalance)
    {
        spcBalance = spaceCoin.balanceOf(address(this));
        ethBalance = address(this).balance;
        return (spcBalance, ethBalance);
    }

    /// @notice Returns the amount of SPC and ETH that has been inputted since the last transaction.
    /// @param _spcBalance The current SPC balance
    /// @param _ethBalance The current ETH balance
    /// @return spcIn The amount of SPC that has been inputted
    /// @return ethIn the amount of ETH that has been inputted
    function _getDepositInputs(uint256 _spcBalance, uint256 _ethBalance)
        private
        view
        returns (uint256 spcIn, uint256 ethIn)
    {
        spcIn = _spcBalance - spcReserve;
        ethIn = _ethBalance - ethReserve;
        return (spcIn, ethIn);
    }

    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    /// @return liquidity The amount of minted LP tokens
    function deposit(address to) external payable returns (uint256 liquidity) {
        (uint256 spcBalance, uint256 ethBalance) = _getBalances();
        (uint256 spcIn, uint256 ethIn) = _getDepositInputs(
            spcBalance,
            ethBalance
        );

        uint256 totalLiquidity = totalSupply();

        if (totalLiquidity == 0) {
            // NOTE: The exact expression doesn't matter here, as there's no existing ratio to maintain.
            liquidity = (ethIn + spcIn) / 2;
        } else {
            liquidity = _min(
                (totalLiquidity * ethIn) / ethReserve,
                (totalLiquidity * spcIn) / spcReserve
            );
        }

        if (liquidity == 0) {
            revert NoDepositLiquidity(to, spcIn, ethIn);
        }

        _updateReserves(spcBalance, ethBalance);
        _mint(to, liquidity);

        emit Deposit(to, liquidity, spcIn, ethIn);

        return liquidity;
    }

    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    /// @return spcOut The amount of SPC that is returned
    /// @return ethOut The amount of ETH that is returned
    function withdraw(address to)
        external
        returns (uint256 spcOut, uint256 ethOut)
    {
        (uint256 spcBalance, uint256 ethBalance) = _getBalances();

        uint256 liquidity = balanceOf(address(this));
        uint256 totalLiquidity = totalSupply();

        spcOut = (spcBalance * liquidity) / totalLiquidity;
        ethOut = (ethBalance * liquidity) / totalLiquidity;

        if (spcOut == 0) {
            revert NoSPCWithdrawalOutput(to, liquidity);
        }
        if (ethOut == 0) {
            revert NoETHWithdrawalOutput(to, liquidity);
        }

        _updateReserves(spcBalance - spcOut, ethBalance - ethOut);
        _burn(address(this), liquidity);

        // Transfer SPC and ETH to `to` address
        spaceCoin.transfer(to, spcOut);
        (bool success, ) = to.call{value: ethOut}("");
        if (!success) {
            revert ETHWithdrawalFailed(to, ethOut);
        }

        emit Withdrawal(to, liquidity, spcOut, ethOut);

        return (spcOut, ethOut);
    }

    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    /// @param isETHtoSPC Boolean indicating the direction of the trade
    /// @return out The amount of ETH or SPC that was transferred to the user
    function swap(address to, bool isETHtoSPC)
        external
        payable
        returns (uint256 out)
    {
        (uint256 spcBalance, uint256 ethBalance) = _getBalances();
        (uint256 spcIn, uint256 ethIn) = _getDepositInputs(
            spcBalance,
            ethBalance
        );

        uint256 input;
        if (isETHtoSPC) {
            input = ethIn;
            out = _getConstantProductOutput(spcReserve, ethReserve, ethIn);

            if (out == 0) {
                revert NoSPCSwapOutput(to, input);
            }

            _updateReserves(spcBalance - out, ethBalance);
            spaceCoin.transfer(to, out);
        } else {
            input = spcIn;
            out = _getConstantProductOutput(ethReserve, spcReserve, spcIn);

            if (out == 0) {
                revert NoETHSwapOutput(to, input);
            }

            _updateReserves(spcBalance, ethBalance - out);
            (bool success, ) = to.call{value: out}("");
            if (!success) {
                revert ETHSwapReceiveFailed(to, out);
            }
        }

        emit Swap(to, isETHtoSPC, input, out);

        return out;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceLP.sol";
import "./SpaceCoin.sol";

contract SpaceRouter {
    // Storage
    SpaceLP public immutable spaceLP;
    SpaceCoin public immutable spaceCoin;

    // Errors
    // Add Liquidity Errors
    error InvalidLiquidityDepositRatio(
        address provider,
        uint256 spcIn,
        uint256 ethIn
    );
    error ETHDepositRefundFailed(address provider, uint256 amount);

    // Remove Liquidity Errors
    error NoLiquidityWithdrawn(address provider);

    // Swap Errors
    error NoETHSwapInput(address swapper);
    error NoSPCSwapInput(address swapper);
    error InsufficientSPCSwapOutput(
        address swapper,
        uint256 output,
        uint256 minOutput
    );
    error InsufficientETHSwapOutput(
        address swapper,
        uint256 output,
        uint256 minOutput
    );

    /// @notice Initialize contract with the token pair.
    /// @param _spaceLP The SpaceLP contract address
    /// @param _spaceCoin The SpaceCoin contract address
    constructor(SpaceLP _spaceLP, SpaceCoin _spaceCoin) {
        spaceLP = _spaceLP;
        spaceCoin = _spaceCoin;
    }

    /// @notice Calculates the unknown a1 value in the equation a1 / b1 = a2 / b2. Rounds the result
    /// up to the nearest integer.
    /// @param _a2 RHS numerator
    /// @param _b1 LHS denominator
    /// @param _b2 RHS denominator
    /// @return a1 The unknown a1 value (LHS numerator)
    function _getValueInRatio(
        uint256 _a2,
        uint256 _b1,
        uint256 _b2
    ) private pure returns (uint256 a1) {
        if (_b2 == 0) {
            return 0;
        }

        // a1 / b1 = a2 / b2
        // a1 = a2 * b1 / b2
        return (_a2 * _b1) / _b2;
    }

    /// @notice Calculates the actual amounts of SPC and ETH to be deposited, based on the
    /// the existing ratio within the LP. If there are no funds in the LPs, any ratio is accepted.
    /// @param _spcDesired The amount of SPC that the user wants to deposit
    /// @param _ethDesired The amount of ETH that the user wants to deposit
    /// @return spcIn The actual amount of SPC to deposit
    /// @return ethIn The actual amount of ETH to deposit
    function _adjustDepositInputs(uint256 _spcDesired, uint256 _ethDesired)
        private
        view
        returns (uint256 spcIn, uint256 ethIn)
    {
        if (_spcDesired == 0 || _ethDesired == 0) {
            revert InvalidLiquidityDepositRatio(
                msg.sender,
                _spcDesired,
                _ethDesired
            );
        }

        uint256 spcReserve = spaceLP.spcReserve();
        uint256 ethReserve = spaceLP.ethReserve();

        // Just returns the desired amounts, since the ratio hasn't been set
        if (spcReserve == 0 && ethReserve == 0) {
            return (_spcDesired, _ethDesired);
        }

        // Calculate the SPC amount, given the desired ETH amount
        uint256 spcExact = _getValueInRatio(
            spcReserve,
            _ethDesired,
            ethReserve
        );
        if (spcExact > 0 && spcExact <= _spcDesired) {
            return (spcExact, _ethDesired);
        }

        // Calculate the ETH amount, given the desired SPC amount
        uint256 ethExact = _getValueInRatio(
            ethReserve,
            _spcDesired,
            spcReserve
        );
        if (ethExact > 0 && ethExact <= _ethDesired) {
            return (_spcDesired, ethExact);
        }

        revert InvalidLiquidityDepositRatio(
            msg.sender,
            _spcDesired,
            _ethDesired
        );
    }

    /// @notice Provides ETH-SPC liquidity to LP contract
    /// @param spc The amount of SPC to be deposited
    /// @return liquidity The amount of SLP that was minted to the user
    /// @return spcIn The SPC amount that was deposited
    /// @return ethIn The ETH amount that was deposited
    function addLiquidity(uint256 spc)
        external
        payable
        returns (
            uint256 liquidity,
            uint256 spcIn,
            uint256 ethIn
        )
    {
        (spcIn, ethIn) = _adjustDepositInputs(spc, msg.value);

        // Refund any unused ETH
        if (msg.value > ethIn) {
            uint256 refundedETH = msg.value - ethIn;
            (bool success, ) = msg.sender.call{value: refundedETH}("");
            if (!success) {
                revert ETHDepositRefundFailed(msg.sender, refundedETH);
            }
        }

        spaceCoin.transferFrom(msg.sender, address(spaceLP), spcIn);
        liquidity = spaceLP.deposit{value: ethIn}(msg.sender);

        return (liquidity, spcIn, ethIn);
    }

    /// @notice Removes ETH-SPC liquidity from LP contract
    /// @param lpToken The amount of LP tokens being returned
    /// @return spcOut The amount of SPC being returned
    /// @return ethOut The amount of ETH being returned
    function removeLiquidity(uint256 lpToken)
        external
        returns (uint256 spcOut, uint256 ethOut)
    {
        if (lpToken == 0) {
            revert NoLiquidityWithdrawn(msg.sender);
        }

        spaceLP.transferFrom(msg.sender, address(spaceLP), lpToken);
        (spcOut, ethOut) = spaceLP.withdraw(msg.sender);

        return (spcOut, ethOut);
    }

    /// @notice Swaps ETH for SPC in LP contract
    /// @param spcOutMin The minimum acceptable amount of SPC to be received
    /// @return spcOut The amount of SPC given in exchange to the swapper
    function swapETHForSPC(uint256 spcOutMin)
        external
        payable
        returns (uint256 spcOut)
    {
        if (msg.value == 0) {
            revert NoETHSwapInput(msg.sender);
        }

        spcOut = spaceLP.swap{value: msg.value}(msg.sender, true);

        if (spcOut < spcOutMin) {
            revert InsufficientSPCSwapOutput(msg.sender, spcOut, spcOutMin);
        }

        return spcOut;
    }

    /// @notice Swaps SPC for ETH in LP contract
    /// @param spcIn The amount of inbound SPC to be swapped
    /// @param ethOutMin The minimum acceptable amount of ETH to be received
    /// @return ethOut The amount of ETH given in exchange to the swapper
    function swapSPCForETH(uint256 spcIn, uint256 ethOutMin)
        external
        returns (uint256 ethOut)
    {
        if (spcIn == 0) {
            revert NoSPCSwapInput(msg.sender);
        }

        spaceCoin.transferFrom(msg.sender, address(spaceLP), spcIn);
        ethOut = spaceLP.swap(msg.sender, false);

        if (ethOut < ethOutMin) {
            revert InsufficientETHSwapOutput(msg.sender, ethOut, ethOutMin);
        }

        return ethOut;
    }
}