//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

contract SpaceLP is ERC20 {
    SpaceCoin public spaceCoin;
    uint256 public balanceSPC = 0;
    uint256 public balanceETH = 0;

    // The following variables are set in the separate transactions before
    // executing swap(), withdraw() or deposit() functions. Therefore, these
    // functions can be front-run. Be aware, that this LP contract is designed
    // to be used with the Router contract. The router contract batches
    // transactions together and executes them and therefore prevents
    // front-running.
    uint256 public depositedETH = 0;
    uint256 public depositedSPC = 0;
    uint256 public ethToSwap = 0;
    uint256 public spcToSwap = 0;
    uint256 public lpToWithdraw = 0;

    uint256 public constant LP_TOKEN_SCALE = 1e18;

    event Deposit(
        address indexed to,
        uint256 spc,
        uint256 eth,
        uint256 lpTokenEmitted
    );

    event BalanceUpdate(uint256 spc, uint256 eth, uint256 lpTokenSupply);

    event Withdraw(
        address indexed to,
        uint256 lpToken,
        uint256 spc,
        uint256 eth
    );

    event Swap(
        address indexed to,
        uint256 spcIn,
        uint256 ethIn,
        uint256 spcOut,
        uint256 ethOut
    );

    constructor(SpaceCoin _spaceCoin) ERC20("LPCoin", "LPC") {
        spaceCoin = _spaceCoin;
    }

    /// @notice Adds ETH-SPC liquidity to LP contract
    /// @param to The address that will receive the LP tokens
    // NOTE: do not change the function signature
    function deposit(address to) public {
        if (depositedSPC == 0 || depositedETH == 0) {
            revert("SpaceLP: zero deposit balances");
        }
        uint256 spc = depositedSPC;
        uint256 eth = depositedETH;
        depositedSPC = 0;
        depositedETH = 0;

        balanceSPC += spc;
        balanceETH += eth;

        uint256 lpToken = quoteDeposit(spc, eth);

        _mint(to, lpToken);
        emit Deposit(to, spc, eth, lpToken);
        emit BalanceUpdate(balanceSPC, balanceETH, totalSupply());
    }

    /// @notice Returns ETH-SPC liquidity to liquidity provider
    /// @param to The address that will receive the outbound token pair
    // NOTE: do not change the function signature
    function withdraw(address to) public {
        uint256 lpToken = lpToWithdraw;
        lpToWithdraw = 0;
        if (lpToken == 0) {
            revert("SpaceLP: zero liquidity token balance");
        }

        (uint256 spc, uint256 eth) = quoteWithdrawal(lpToken);
        balanceSPC -= spc;
        balanceETH -= eth;
        _burn(address(this), lpToken);

        (bool success, ) = payable(to).call{value: eth}("");
        if (!success) {
            revert("SpaceLP: withdraw ETH failed");
        }

        success = spaceCoin.transfer(to, spc);
        if (!success) {
            revert("SpaceLP: withdraw SPC failed");
        }

        emit Withdraw(to, lpToken, spc, eth);
        emit BalanceUpdate(balanceSPC, balanceETH, totalSupply());
    }

    /// @notice Swaps ETH for SPC, or SPC for ETH
    /// @param to The address that will receive the outbound SPC or ETH
    /// @dev I specifically do not prevent the user from swapping both SPC
    /// and ETH in the same transaction. This is because malisious actors can
    /// lock the cotract by depositing both SPC and ETH.
    // NOTE: do not change the function signature
    function swap(address to) public {
        if (spcToSwap == 0 && ethToSwap == 0) {
            revert("SpaceLP: zero swap balances");
        }

        uint256 spc = spcToSwap;
        uint256 eth = ethToSwap;
        spcToSwap = 0;
        ethToSwap = 0;

        (uint256 spcOut, uint256 ethOut) = quoteSwap(spc, eth);

        balanceSPC = balanceSPC + spc - spcOut;
        balanceETH = balanceETH + eth - ethOut;

        bool success;
        if (spcOut > 0) {
            success = spaceCoin.transfer(to, spcOut);
            if (!success) {
                revert("SpaceLP: swap SPC failed");
            }
        }

        if (ethOut > 0) {
            (success, ) = to.call{value: ethOut}("");
            if (!success) {
                revert("SpaceLP: swap ETH failed");
            }
        }

        emit Swap(to, spc, eth, spcOut, ethOut);
        emit BalanceUpdate(balanceSPC, balanceETH, totalSupply());
    }

    /// @notice Returns the amount of ETH or SPC that can be received for a
    // given amount of LP tokens
    /// @param lpToken The amount of LP tokens being
    function quoteWithdrawal(uint256 lpToken)
        public
        view
        returns (uint256, uint256)
    {
        uint256 spc = (lpToken * LP_TOKEN_SCALE) / balanceETH;
        uint256 eth = (lpToken * LP_TOKEN_SCALE) / balanceSPC;

        return (spc, eth);
    }

    /// @notice Returns the amount of LP tokens that can be received for a given
    // amount of ETH and SPC
    /// @param spc The amount of inbound SPC
    /// @param eth The amount of inbound ETH
    function quoteDeposit(uint256 spc, uint256 eth)
        public
        view
        returns (uint256)
    {
        uint256 lpTokenUnscaled;
        if (totalSupply() == 0) {
            lpTokenUnscaled = spc * eth;
        } else {
            uint256 lpTokenSPC = (spc * balanceETH);
            uint256 lpTokenETH = (eth * balanceSPC);
            // lpToken = min(lpTokenSPC, lpTokenETH)
            // if the ratio is not right then the users will get less than they
            // expected.
            lpTokenUnscaled = lpTokenSPC < lpTokenETH ? lpTokenSPC : lpTokenETH;
        }

        return lpTokenUnscaled / LP_TOKEN_SCALE;
    }

    /// @notice Returns the amount of ETH or SPC that can be received for a swap
    // of a given amount of ETH or SPC
    /// @param spc The amount of inbound SPC
    /// @param eth The amount of inbound ETH
    function quoteSwap(uint256 spc, uint256 eth)
        public
        view
        returns (uint256, uint256)
    {
        uint256 spcOut = balanceSPC - K() / (balanceETH + eth);
        uint256 ethOut = balanceETH - K() / (balanceSPC + spc);

        return (spcOut, ethOut);
    }

    /// @notice on the recive of the eth encrement the depositedETH
    function depositETHForLiquidity() public payable {
        depositedETH += msg.value;
    }

    /// @notice receive SpaceCoin and increment the depositedSPC
    /// @param from The address that will send the SPC
    /// @param spc The amount of SPC
    function depositSPCForLiquidity(address from, uint256 spc) public {
        bool success = spaceCoin.transferFrom(from, address(this), spc);
        if (!success) {
            revert("SpaceLP: depositSPC failed");
        }
        depositedSPC += spc;
    }

    /// @notice receive SpaceCoin and increment the spcToSwap
    /// @param from The address that will send the SPC
    /// @param spc The amount of SPC
    function depositSpcToSwap(address from, uint256 spc) public {
        bool success = spaceCoin.transferFrom(from, address(this), spc);
        if (!success) {
            revert("SpaceLP: depositSPC failed");
        }

        spcToSwap += (spc * 99) / 100; // 1% fee
    }

    /// @notice on the recive of the eth encrement the ethToSwap
    function depositEthToSwap() public payable {
        ethToSwap += (msg.value * 99) / 100; // 1% fee
    }

    /// @notice deposit LP token to the contract to withdraw later
    /// @param from The address that will send the LP token
    /// @param lpToken The amount of LP token
    function depositLPToWithdraw(address from, uint256 lpToken) public {
        bool success = this.transferFrom(from, address(this), lpToken);
        if (!success) {
            revert("SpaceLP: depositLPToWithdraw failed");
        }

        lpToWithdraw += lpToken;
    }

    /// @notice total liquidity (or K) in the contract
    function K() public view returns (uint256) {
        return balanceSPC * balanceETH;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    address public owner;
    address public treasury;
    bool public taxed;

    constructor(
        address _ico,
        uint256 _icoAmount,
        address _treasury,
        uint256 _treasuryAmount
    ) ERC20("SpaceCoin", "SPC") {
        _mint(_ico, _icoAmount);
        _mint(_treasury, _treasuryAmount);
        treasury = _treasury;
        owner = msg.sender;
    }

    /// @dev Override the low-level transfer function. This covers both .transfer() and .transferFrom()
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (taxed) {
            uint256 tax = amount / 50;
            amount -= tax;
            super._transfer(sender, treasury, tax);
        }
        super._transfer(sender, recipient, amount);
    }

    function switchTax(bool toggle) external {
        require(msg.sender == owner, "Only owner can do this");
        taxed = toggle;
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