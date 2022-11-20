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
    uint80 public constant ICO_SUPPLY = 150000 * 10 ** 18; //18 decimals.
    uint80 public constant TREASURY_SUPPLY = 350000 * 10 ** 18; //18 decimals.

    //Tax rate in basis points.
    uint8 public constant TAX_RATE_BP = 200;

    //Divisor to convert back from basis points
    uint16 public constant BP_DIVISOR = 10000;

    address public immutable owner;
    address public immutable treasury;

    bool public isTaxed = false;

    error NotOwner();

    event TaxationChangedTo(bool state);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @dev SpaceCoin constructor
     * @param _owner The ICO owner
     * @param _treasury The treasury address
     */
    constructor(address _owner, address _treasury) ERC20("SpaceCoin", "SPC") {
        owner = _owner;
        treasury = _treasury;
        _mint(msg.sender, ICO_SUPPLY);
        _mint(treasury, TREASURY_SUPPLY);
    }

    /**
     * @dev Used by owner to toggle taxation
     */
    function toggleTaxation() external onlyOwner {
        isTaxed = !isTaxed;
        emit TaxationChangedTo(isTaxed);
    }

    /**
     * @dev Overrides ERC20 -> _transfer(), implementing tax.
     * @param to Recipient
     * @param amount The amount of SPC to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isTaxed) {
            uint tax = (amount * TAX_RATE_BP) / BP_DIVISOR;
            super._transfer(from, treasury, tax);
            amount -= tax;
        }
        super._transfer(from, to, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";

contract SpaceLP is ERC20 {
    uint256 public constant FEE_DIVISOR = 100;

    SpaceCoin public immutable spaceCoin;

    uint256 public reserveEth;
    uint256 public reserveSpc;

    error InsufficientLpTokens(uint256 returnedLp, uint256 totalLp);
    error InsufficientLiquidity(address to, string asset);
    error EthSendFailed(address to, uint256 amount);
    error NoAssetInFound(address user);
    error NoLPTokensToMint(address user, uint256 ethAmount, uint256 spcAmount);

    event LiquidityAdded(
        address indexed user,
        uint256 amountEth,
        uint256 amountSpc,
        uint256 amountEthSpcLp
    );
    event LiquidityRemoved(
        address indexed user,
        uint256 amountEth,
        uint256 amountSpc,
        uint256 amountEthSpcLp
    );
    event EthForSpcSwap(
        address indexed user,
        uint256 amountEth,
        uint256 amountSpc,
        uint256 feeEth
    );
    event SpcForEthSwap(
        address indexed user,
        uint256 amountSpc,
        uint256 amountEth,
        uint256 feeSpc
    );

    constructor(
        SpaceCoin _spaceCoin
    ) ERC20("Ether_SpaceCoin_LP", "ETH_SPC_LP") {
        spaceCoin = _spaceCoin;
    }

    /**
     * @notice Updates reserves and mints liquidity tokens for the depositor.
     * @param to The depositor.
     */
    function deposit(address to) external payable {
        uint256 differenceEth = address(this).balance - reserveEth;
        uint256 differenceSpc = spaceCoin.balanceOf(address(this)) - reserveSpc;
        uint256 totalSupply = totalSupply();
        uint256 lpAmount;

        if (differenceEth == 0 && differenceSpc == 0) {
            revert NoAssetInFound(to);
        }

        if (totalSupply == 0) {
            lpAmount = (differenceEth + differenceSpc) / 2;
        } else {
            if (differenceEth > 0 && differenceSpc > 0) {
                //Prevent divide-by-zero
                lpAmount = min(
                    (differenceEth * totalSupply) / reserveEth,
                    (differenceSpc * totalSupply) / reserveSpc
                );
            }
        }

        if (lpAmount == 0) {
            revert NoLPTokensToMint(to, differenceEth, differenceSpc);
        }

        reserveEth = address(this).balance;
        reserveSpc = spaceCoin.balanceOf(address(this));

        emit LiquidityAdded(to, differenceEth, differenceSpc, lpAmount);

        if (lpAmount > 0) {
            _mint(to, lpAmount);
        }
    }

    /**
     * @notice Returns ETH-SPC liquidity to liquidity provider
     * @param to The address that will receive the outbound token pair
     */
    function withdraw(address to) external {
        uint256 balanceEth = address(this).balance;
        uint256 balanceSpc = spaceCoin.balanceOf(address(this));
        uint256 returnedLp = balanceOf(address(this)); //This will be the amount just submitted by withdrawer.

        if (returnedLp == 0) {
            revert NoAssetInFound(to);
        }

        uint256 dueEth = (balanceEth * returnedLp) / totalSupply();
        uint256 dueSpc = (balanceSpc * returnedLp) / totalSupply();

        if (dueEth == 0 || dueSpc == 0) {
            revert InsufficientLpTokens(returnedLp, totalSupply());
        }

        _burn(address(this), returnedLp);

        reserveEth = balanceEth - dueEth;
        reserveSpc = balanceSpc - dueSpc;

        emit LiquidityRemoved(to, dueEth, dueSpc, returnedLp);

        spaceCoin.transfer(to, dueSpc);
        sendEth(to, dueEth);
    }

    /**
     * @notice Swaps ETH for SPC, or SPC for ETH
     * @param to The address that will receive the outbound SPC or ETH
     * @param isETHtoSPC Boolean indicating the direction of the trade
     */
    function swap(address to, bool isETHtoSPC) external payable {
        if (isETHtoSPC) {
            swapEthToSpc(to);
        } else {
            swapSpcToEth(to);
        }
    }

    /**
     * @notice Swaps ETH for SPC
     * @param to The address that will receive the outbound SPC or ETH
     */
    function swapEthToSpc(address to) private {
        uint256 ethIn = address(this).balance - reserveEth;

        if (ethIn == 0) {
            revert NoAssetInFound(to);
        }

        uint256 fee = ethIn / FEE_DIVISOR;
        uint256 ethInLessFee = ethIn - fee;

        uint256 dueSpc = (ethInLessFee * reserveSpc) /
            (reserveEth + ethInLessFee);

        if (dueSpc == 0) {
            revert InsufficientLiquidity(to, "SPC");
        }

        reserveEth = address(this).balance;
        reserveSpc = spaceCoin.balanceOf(address(this)) - dueSpc;

        emit EthForSpcSwap(to, ethIn, dueSpc, fee);

        spaceCoin.transfer(to, dueSpc);
    }

    /**
     * @notice Swaps SPC for ETH
     * @param to The address that will receive the outbound SPC or ETH
     */
    function swapSpcToEth(address to) private {
        uint256 spcIn = spaceCoin.balanceOf(address(this)) - reserveSpc;

        if (spcIn == 0) {
            revert NoAssetInFound(to);
        }

        uint256 fee = spcIn / FEE_DIVISOR;
        uint256 spcInLessFee = spcIn - fee;

        uint256 dueEth = (spcInLessFee * reserveEth) /
            (reserveSpc + spcInLessFee);

        if (dueEth == 0) {
            revert InsufficientLiquidity(to, "ETH");
        }

        reserveEth = address(this).balance - dueEth;
        reserveSpc = spaceCoin.balanceOf(address(this));

        emit SpcForEthSwap(to, spcIn, dueEth, fee);

        sendEth(to, dueEth);
    }

    /**
     * @notice Send ETH
     * @param to The address to pay
     * @param amount The amount of ETH to send
     */
    function sendEth(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert EthSendFailed(to, amount);
        }
    }

    /**
     * @notice Return reserves for the asset pair.
     * @return _reserveEth Eth reserves tracked.
     * @return _reserveSpc Spc reserve tracked.
     */
    function getReserves() external view returns (uint256, uint256) {
        return (reserveEth, reserveSpc);
    }

    /**
     * @notice Utility function to return the minimum.
     */
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceLP.sol";
import "./SpaceCoin.sol";

contract SpaceRouter {
    SpaceLP public immutable spaceLP;
    SpaceCoin public immutable spaceCoin;

    error ZeroAmount(string asset);
    error ZeroLiquidity(uint256 ethAmount, uint256 spcAmount);
    error RefundFailed(address to, uint256 amount);
    error CannotFill(address to, string asset, uint256 minimum);

    modifier nonZeroEth() {
        if (msg.value == 0) {
            revert ZeroAmount("ETH");
        }
        _;
    }

    modifier nonZeroSpc(uint256 amount) {
        if (amount == 0) {
            revert ZeroAmount("SPC");
        }
        _;
    }

    modifier nonZeroEthSpcLp(uint256 amount) {
        if (amount == 0) {
            revert ZeroAmount("ETH_SPC_LP");
        }
        _;
    }

    modifier liquidityExists() {
        (uint256 reserveEth, uint256 reserveSpc) = spaceLP.getReserves();
        if (reserveEth == 0 || reserveSpc == 0) {
            revert ZeroLiquidity(reserveEth, reserveSpc);
        }
        _;
    }

    constructor(SpaceLP _spaceLP, SpaceCoin _spaceCoin) {
        spaceLP = _spaceLP;
        spaceCoin = _spaceCoin;
    }

    /**
     * @notice Provides ETH-SPC liquidity to LP contract
     * @param spc The amount of SPC to be deposited
     */
    function addLiquidity(
        uint256 spc
    ) external payable nonZeroEth nonZeroSpc(spc) {
        uint256 amountEthOffered = msg.value;
        uint256 amountSpcOffered = spc;

        uint256 amountEthToAdd;
        uint256 amountSpcToAdd;

        uint256 ethRefund;

        (uint256 reserveEth, uint256 reserveSpc) = spaceLP.getReserves();

        if (reserveEth == 0 && reserveSpc == 0) {
            amountEthToAdd = amountEthOffered;
            amountSpcToAdd = amountSpcOffered;
        } else {
            if (reserveEth == 0 || reserveSpc == 0) {
                revert ZeroLiquidity(reserveEth, reserveSpc);
            }

            /// @dev Get best deal for liquidity provider
            uint256 amountSpcOptimal = (amountEthOffered * reserveSpc) /
                reserveEth;
            if (amountSpcOptimal <= amountSpcOffered) {
                amountEthToAdd = amountEthOffered;
                amountSpcToAdd = amountSpcOptimal;
            } else {
                uint256 amountEthOptimal = (amountSpcOffered * reserveEth) /
                    reserveSpc;
                assert(amountEthOptimal <= amountEthOffered); /// Must be the case if we've gotten this far
                amountEthToAdd = amountEthOptimal;
                amountSpcToAdd = amountSpcOffered;
                ethRefund = amountEthOffered - amountEthToAdd;
            }
        }

        /// @dev If spc taxation is on, deduct the eth amount by the same percentage.
        if (spaceCoin.isTaxed()) {
            uint256 ethDeduction = (amountEthToAdd * spaceCoin.TAX_RATE_BP()) /
                spaceCoin.BP_DIVISOR();
            amountEthToAdd -= ethDeduction;
            ethRefund += ethDeduction;
        }

        spaceCoin.transferFrom(msg.sender, address(spaceLP), amountSpcToAdd);
        spaceLP.deposit{value: amountEthToAdd}(msg.sender);

        if (ethRefund > 0) {
            refund(msg.sender, ethRefund);
        }
    }

    /**
     * @notice Removes ETH-SPC liquidity from LP contract
     * @param lpToken The amount of LP tokens being returned
     */
    function removeLiquidity(
        uint256 lpToken
    ) external nonZeroEthSpcLp(lpToken) {
        spaceLP.transferFrom(msg.sender, address(spaceLP), lpToken);
        spaceLP.withdraw(msg.sender);
    }

    /**
     * @notice Swaps ETH for SPC in LP contract
     * @param spcOutMin The minimum acceptable amount of SPC to be received
     */
    function swapETHForSPC(
        uint256 spcOutMin
    ) external payable nonZeroEth liquidityExists {
        uint256 balanceBefore = spaceCoin.balanceOf(msg.sender);
        spaceLP.swap{value: msg.value}(msg.sender, true);
        uint256 balanceAfter = spaceCoin.balanceOf(msg.sender);

        assert(balanceAfter >= balanceBefore);
        if ((balanceAfter - balanceBefore) < spcOutMin) {
            revert CannotFill(msg.sender, "SPC", spcOutMin);
        }
    }

    /**
     * @notice Swaps SPC for ETH in LP contract
     * @param spcIn The amount of inbound SPC to be swapped
     * @param ethOutMin The minimum acceptable amount of ETH to be received
     */
    function swapSPCForETH(
        uint256 spcIn,
        uint256 ethOutMin
    ) external nonZeroSpc(spcIn) liquidityExists {
        uint256 balanceBefore = msg.sender.balance;
        spaceCoin.transferFrom(msg.sender, address(spaceLP), spcIn);
        spaceLP.swap(msg.sender, false);
        uint256 balanceAfter = msg.sender.balance;

        assert(balanceAfter >= balanceBefore);
        if ((balanceAfter - balanceBefore) < ethOutMin) {
            revert CannotFill(msg.sender, "ETH", ethOutMin);
        }
    }

    /**
     * @notice Refund ETH to user
     * @param to The address to refund
     * @param amount The amount of ETH to send
     */
    function refund(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert RefundFailed(to, amount);
        }
    }
}