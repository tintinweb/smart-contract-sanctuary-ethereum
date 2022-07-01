//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";
import "./SpaceLibrary.sol";

/// @notice SpaceCoin and ETH liquidity pool contract
contract SpacePool is ERC20, Ownable {
    /// Name of the LP token used by SpacePool
    string public constant NAME = "SpacePool Liquidity Token";

    /// Symbol of LP token
    string public constant SYMBOL = "SPL";

    /// Trading fee incurred on every swap.
    uint256 public constant FEE_PERCENT = 1;

    /// @notice This amount is burned upon initial deposit to prevent divide by zero,
    /// as well as a scenario in which on LP token share being too expensive,
    /// which would turn away small LPs.
    uint256 public constant MIN_LIQUIDITY = 10**3;

    /// OpenZeppelin ERC20 does not allow for zero address minting.
    /// Use this burn address instead.
    address public constant BURN_ADDRESS =
        0xBaaaaaaaAAaaAaaaaaaAaAAAaaAAaAaaAAaaAAAD;

    /// Token contract for the liquidity pool.
    SpaceCoin public immutable spaceCoin;

    /// Amount of ETH the pool has in reserve.
    uint256 private reserveETH;

    /// Amount of SPC tokens the pool has in reserve.
    uint256 private reserveSPC;

    /// Mutex used to prevent reentrancy vulnerabilities.
    bool private reentrancyLock = false;

    /// Prevents functions with this modifier from being reentrant.
    modifier nonReentrant() {
        require(!reentrancyLock, "Operation already in progress");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    /// Emitted in the mint() function.
    event Mint(address indexed sender, uint256 ethAmount, uint256 spcAmount);

    /// Emitted in the burn() function.
    event Burn(
        address indexed sender,
        uint256 ethAmount,
        uint256 spcAmount,
        address indexed to
    );

    /// Emitted in the swap() function.
    event Swap(
        address indexed sender,
        uint256 ethIn,
        uint256 spcIn,
        uint256 ethOut,
        uint256 spcOut,
        address indexed to
    );

    /// Emitted in _updateReserves() which is called in swap/mint/burn/sync.
    event Sync(uint256 ethReserve, uint256 spcReserve);

    /// Constructor to set the immutable variable and ERC20 inputs.
    constructor(SpaceCoin spc) ERC20(NAME, SYMBOL) {
        spaceCoin = spc;
    }

    /// @notice Used when someone want to trade tokens.
    /// @param ethOut Amount of ETH caller expects to receive.
    /// @param spcOut Amount of SPC caller expects to receive.
    /// @param swapper Address of the swapper.
    /// @dev Router contract sends tokens before this function is called.
    function swap(
        uint256 ethOut,
        uint256 spcOut,
        address swapper
    ) external payable nonReentrant {
        require(swapper != address(0), "Invalid swapper");
        require(swapper != address(spaceCoin), "Address cannot be SPC");
        require(
            (ethOut > 0 && spcOut == 0 && msg.value == 0) ||
                (ethOut == 0 && spcOut > 0 && msg.value > 0),
            "Only single-sided swaps allowed"
        );
        (uint256 _reserveETH, uint256 _reserveSPC) = getReserves();
        require(ethOut < _reserveETH, "Not enough ETH in reserve");
        require(spcOut < _reserveSPC, "Not enough SPC in reserve");

        uint256 k;
        uint256 ethBalance = address(this).balance;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));
        (uint256 ethIn, uint256 spcIn) = (0, 0);
        if (ethOut > 0) {
            // Swapping SPC for ETH
            spcIn = spcBalance - (_reserveSPC - spcOut);
            require(spcIn > 0, "Insufficient SPC input amount");
            SpaceLibrary.safeTransferETH(swapper, ethOut);
        } else {
            // Swapping ETH for SPC
            ethIn = ethBalance - (_reserveETH - ethOut);
            require(ethIn > 0, "Insufficient ETH input amount");
            SpaceLibrary.safeTransferSPC(spaceCoin, swapper, spcOut);
        }
        uint256 HUNDRED_PERCENT = 100;
        {
            ethBalance = address(this).balance;
            spcBalance = spaceCoin.balanceOf(address(this));
            uint256 x = (ethBalance * HUNDRED_PERCENT) - (ethIn * FEE_PERCENT);
            uint256 y = (spcBalance * HUNDRED_PERCENT) - (spcIn * FEE_PERCENT);
            k = x * y;
        }
        // The new k with fees calculated should never be lower than the previous k
        require(
            k >= (_reserveETH * _reserveSPC) * (HUNDRED_PERCENT**2),
            "Invalid K"
        );

        _updateReserves(ethBalance, spcBalance);
        emit Swap(msg.sender, ethIn, spcIn, ethOut, spcOut, swapper);
    }

    /// @notice Used when someone adds liquidity to the pool.
    /// @param to The account the protocol will mint new LP tokens to.
    /// @dev Assumes tokens and ETH have already been sent to this pool first.
    function mint(address to) external payable nonReentrant returns (uint256) {
        (uint256 _reserveETH, uint256 _reserveSPC) = getReserves();
        uint256 ethBalance = address(this).balance;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));
        uint256 diffETH = ethBalance - _reserveETH;
        uint256 diffSPC = spcBalance - _reserveSPC;
        uint256 amountToMint;

        uint256 lpTokenSupply = totalSupply();
        bool isFirstDeposit = lpTokenSupply == 0;
        if (isFirstDeposit) {
            amountToMint = SpaceLibrary.sqrt(diffETH * diffSPC) - MIN_LIQUIDITY;
            _mint(BURN_ADDRESS, MIN_LIQUIDITY);
        } else {
            amountToMint = SpaceLibrary.min(
                (diffETH * lpTokenSupply) / _reserveETH,
                (diffSPC * lpTokenSupply) / _reserveSPC
            );
        }
        require(amountToMint > 0, "Not enough liquidity minted");

        _mint(to, amountToMint);
        _updateReserves(ethBalance, spcBalance);

        emit Mint(msg.sender, diffETH, diffSPC);
        return amountToMint;
    }

    /// @notice Used when someone removes liquidity to the pool.
    /// @param to The account the protocol will return ETH and SPC to.
    /// @dev Assumes LP token has been sent to this pool first.
    function burn(address to) external nonReentrant returns (uint256, uint256) {
        require(to != address(spaceCoin), "Address cannot be SPC");
        uint256 ethBalance = address(this).balance;
        uint256 spcBalance = spaceCoin.balanceOf(address(this));
        uint256 amountToBurn = balanceOf(address(this));

        uint256 lpTokenSupply = totalSupply();
        uint256 ethToSend = (amountToBurn * ethBalance) / lpTokenSupply;
        uint256 spcToSend = (amountToBurn * spcBalance) / lpTokenSupply;
        require(ethToSend > 0 && spcToSend > 0, "Not enough liquidity burned");

        _burn(address(this), amountToBurn);

        SpaceLibrary.safeTransferSPC(spaceCoin, to, spcToSend);
        SpaceLibrary.safeTransferETH(to, ethToSend);

        ethBalance = address(this).balance;
        spcBalance = spaceCoin.balanceOf(address(this));
        _updateReserves(ethBalance, spcBalance);
        emit Burn(msg.sender, ethToSend, spcToSend, to);
        return (ethToSend, spcToSend);
    }

    /// @notice Returns the x and y values of the pool. (Constant product formula).
    /// @dev These numbers may be out of date, which is why `_updateReserves()` is called
    /// throughout this contract.
    function getReserves()
        public
        view
        returns (uint256 ethReserve, uint256 spcReserve)
    {
        return (reserveETH, reserveSPC);
    }

    /// @notice Used to update the `reserveETH` and `reserveSPC` values with given inputs.
    /// @param ethBalance new value to update `reserveETH` with.
    /// @param spcBalance new value to update `reserveSPC` with.
    function _updateReserves(uint256 ethBalance, uint256 spcBalance) private {
        reserveETH = ethBalance;
        reserveSPC = spcBalance;
        emit Sync(reserveETH, reserveSPC);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 500000 * (10**18);
    uint256 public constant SUPPLY_FOR_INVESTORS = 150000 * (10**18);
    uint256 public constant FEE_PERCENT = 2;
    uint256 public constant PERCENT_DENOMINATOR = 100;

    address public immutable manager;
    bool public transferTaxActive = false;
    address payable public immutable treasury;

    event TransferTaxEnabled();
    event TransferTaxDisabled();

    constructor(
        address _manager,
        address payable _treasuryAddress,
        address payable _icoTreasury
    ) ERC20("SpaceCoin", "SPC") {
        require(_manager != address(0), "Cannot use zero address");
        require(_treasuryAddress != address(0), "Cannot use zero address");
        require(_icoTreasury != address(0), "Cannot use zero address");
        manager = _manager;
        treasury = _treasuryAddress;
        _mint(_icoTreasury, SUPPLY_FOR_INVESTORS);
        _mint(treasury, TOTAL_SUPPLY - SUPPLY_FOR_INVESTORS);
    }

    function enableTransferTax() external {
        require(msg.sender == manager, "Invalid permissions");
        require(!transferTaxActive, "Transfer tax already active");
        transferTaxActive = true;
        emit TransferTaxEnabled();
    }

    function disableTransferTax() external {
        require(msg.sender == manager, "Invalid permissions");
        require(transferTaxActive, "Transfer tax already inactive");
        transferTaxActive = false;
        emit TransferTaxDisabled();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (transferTaxActive) {
            uint256 fee = (amount * FEE_PERCENT) / PERCENT_DENOMINATOR;
            super._transfer(from, treasury, fee);
            super._transfer(from, to, amount - fee);
        } else {
            super._transfer(from, to, amount);
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./SpaceCoin.sol";
import "./SpacePool.sol";

/// @notice Utility functions used in the Space contracts
library SpaceLibrary {
    /// @notice Transfers ETH to address. Reverts if it does not succeed.
    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Unable to transfer ETH");
    }

    /// @notice A transferFrom() wrapper for SpaceCoin.
    /// Reverts if it does not succeed.
    function safeTransferFromSPC(
        SpaceCoin spaceCoin,
        address from,
        address to,
        uint256 numTokens
    ) internal {
        bool success = spaceCoin.transferFrom(from, to, numTokens);
        require(success, "Unable to transferFrom SPC");
    }

    /// @notice A transfer() wrapper for SpaceCoin.
    /// Reverts if it does not succeed.
    function safeTransferSPC(
        SpaceCoin spaceCoin,
        address to,
        uint256 numTokens
    ) internal {
        bool success = spaceCoin.transfer(to, numTokens);
        require(success, "Unable to transfer SPC");
    }

    /// @notice A transferFrom() wrapper for SpacePool.
    /// Reverts if it does not succeed.
    function safeTransferFromSPL(
        SpacePool pool,
        address from,
        address to,
        uint256 numTokens
    ) internal {
        bool success = pool.transferFrom(from, to, numTokens);
        require(success, "Unable to transferFrom SPL");
    }

    /// @notice Returns the square root of a given uint256.
    /// @param y The number to square root.
    /// @dev Uses the 'Babylonian Method' of efficiently computing square roots.
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @notice Returns the min of x and y.
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
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