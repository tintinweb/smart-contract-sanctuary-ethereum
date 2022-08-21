// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./SpaceCoin.sol";
import "./libraries/Helpers.sol";

contract LiquidityPool is ERC20 {
    SpaceCoin public immutable spaceCoin;

    uint256 private ethReserve;
    uint256 private spcReserve;

    /* need a lock to avoid reentrancy, details on lock modifier */
    uint8 isUnlocked = 1;

    constructor(address _spaceCoin) ERC20("Ether-SpaceCoin Pair", "ETHSPCLP") {
        spaceCoin = SpaceCoin(_spaceCoin);
    }

    /**
     * @notice check if the function is locked
     *
     * @dev needed because actions are performed after .call function, not using checks-effect-interaction in swap function (and keep safe also mint/burn)
     * I believe this approach is more clear in this case compared to checks-effect-interactions while swapping
     */
    modifier lock() {
        if (isUnlocked == 2) {
            revert LiquidityPoolLocked();
        }
        isUnlocked = 2;
        _;
        isUnlocked = 1;
    }

    /**
     * @notice mint LP tokens to add liquidity to the pool
     *
     * @dev the function is payable in order to receive ETH directly
     *
     * @param to the address where the LP tokens will be sent
     *
     * @return amount of minted LP tokens
     */
    function mint(address to) external payable returns (uint256) {
        (uint256 _ethReserve, uint256 _spcReserve) = getReserves();
        (uint256 ethBalance, uint256 spcBalance) = getBalances();
        uint256 liquidity;
        uint256 _totalSupply = totalSupply();
        uint256 _spcIn = spcBalance - _spcReserve;
        uint256 _ethIn = ethBalance - _ethReserve;

        if (_totalSupply == 0) {
            liquidity = Helpers.sqrt(_spcIn * _ethIn);
        } else {
            liquidity = Helpers.min((_ethIn * _totalSupply) / _ethReserve, (_spcIn * _totalSupply) / _spcReserve);
        }

        if (liquidity <= 0) revert NoLiquidityProvided(to);

        _mint(to, liquidity);

        sync();

        emit Minted(msg.sender, _ethIn, _spcIn);

        return liquidity;
    }

    /**
     * @notice burn user's LP tokens and return ETH/SPC values
     *
     * @param liquidity LP tokens to burn
     * @param to the address where ETH/SPC will be sent
     *
     * @return amount of minted LP tokens
     */
    function burn(uint256 liquidity, address to) external lock returns (uint256, uint256) {
        (uint256 _ethReserve, uint256 _spcReserve) = getReserves();
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) revert NoLiquidityInPool();

        uint256 ethOut = (liquidity * _ethReserve) / _totalSupply;
        uint256 spcOut = (liquidity * _spcReserve) / _totalSupply;

        if (ethOut <= 0 || spcOut <= 0) revert InsuffiecientLiquidityBurned(ethOut, spcOut);

        _burn(address(this), liquidity);

        spaceCoin.transfer(to, spcOut);
        (bool success, bytes memory data) = to.call{value: ethOut}("");
        if (!success) {
            if (data.length > 0) {
                // "Catch" the revert reason using memory via assembly
                assembly {
                    let data_size := mload(data)
                    revert(add(32, data), data_size)
                }
            } else {
                revert BurnTransferEthToError(to);
            }
        }

        sync();

        emit Burned(msg.sender, ethOut, spcOut);

        return (ethOut, spcOut);
    }

    /**
     *
     * @notice receives an amount in (ETH or SPC) and return the amount of the opposite token.
     *
     * @dev Function is payable because it could receive ETH
     * Fee will be deposited in the pool, amount less fee will be used to perfrom the amountOut calculation.
     * If tax is active on spc, need to calc the value without the tax that will be sent to the liquidity pool.
     *
     * @param to address to send the swapped token
     *
     */
    function swap(address to) external payable lock returns (uint256) {
        (uint256 _ethReserve, uint256 _spcReserve) = getReserves();
        (uint256 ethBalance, uint256 spcBalance) = getBalances();
        uint256 _spcIn = spcBalance - _spcReserve;
        uint256 _ethIn = ethBalance - _ethReserve;

        uint256 amountOut;

        if (_ethIn <= 0 && _spcIn <= 0) revert InsufficientInAmount(_ethIn, _spcIn);
        if (_ethIn > 0 && _spcIn > 0) revert OnlyOneTokenInAllowed(_ethIn, _spcIn);

        if (_ethReserve <= 0 || _spcReserve <= 0) {
            revert ReservesAmountInvalid(_ethReserve, _spcReserve);
        }

        if (_ethIn > 0) {
            amountOut = getAmountReceived(_ethIn, _ethReserve, _spcReserve);
            if (amountOut >= _spcReserve) revert InsufficientLiquidity(amountOut, _spcReserve);
            spaceCoin.transfer(to, amountOut);
        } else {
            amountOut = getAmountReceived(_spcIn, _spcReserve, _ethReserve);
            if (amountOut >= _ethReserve) revert InsufficientLiquidity(amountOut, _ethReserve);
            (bool success, bytes memory data) = to.call{value: amountOut}("");
            if (!success) {
                if (data.length > 0) {
                    // "Catch" the revert reason using memory via assembly
                    assembly {
                        let data_size := mload(data)
                        revert(add(32, data), data_size)
                    }
                } else {
                    revert SwapTransferEthToError(to, amountOut);
                }
            }
        }

        /*
         * Ho to get to (ethBalance * 100) - amountEthIn, explained by AbhiG on discord
         * balance0Adjusted = _reserve0 + .997 * amount0In =>
         * balance0Adjusted = balance0 - amount0In + .997 * amount0In =>
         * balance0Adjusted = balance0 - .003 * amount0In
         *
         * replace 997 with 999 in our case and remove mul(3) since  (1%)
         *
         */
        (ethBalance, spcBalance) = getBalances();

        uint256 balanceETHWithFee = (ethBalance * 100) - _ethIn;
        uint256 balanceSPCWithFee = (spcBalance * 100) - _spcIn;

        if ((balanceETHWithFee * balanceSPCWithFee) < (ethReserve * spcReserve) * 100**2)
            revert WrongKValueAfterSwap(balanceETHWithFee * balanceSPCWithFee, ethReserve * spcReserve * 100**2);

        sync();

        emit Swapped(
            msg.sender,
            _ethIn > 0 ? "ETH_FOR_SPC" : "SPC_FOR_ETH",
            _ethIn,
            _ethIn > 0 ? 0 : amountOut,
            _spcIn,
            _spcIn > 0 ? 0 : amountOut
        );
        return amountOut;
    }

    /**
     * @return liquidity pool's balances
     */
    function getBalances() internal view returns (uint256, uint256) {
        return (address(this).balance, spaceCoin.balanceOf(address(this)));
    }

    /**
     * @return liquidity pool's reserves
     */
    function getReserves() public view returns (uint256, uint256) {
        return (ethReserve, spcReserve);
    }

    /**
     * @notice calculate tokens received in a swap
     *
     * @param amountIn amount to deposit
     * @param reserveIn reserve of the tokens to deposit
     * @param reserveOut reserve of the tokens to receive
     *
     * @return amount token that will be received
     *
     */
    function getAmountReceived(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 99; // 1% fee
        return (amountInWithFee * reserveOut) / ((reserveIn * 100) + amountInWithFee);
    }

    function sync() public {
        spcReserve = IERC20(spaceCoin).balanceOf(address(this));
        ethReserve = address(this).balance;
    }

    event Minted(address indexed sender, uint256 ethIn, uint256 spcIn);
    event Burned(address indexed sender, uint256 ethOut, uint256 spcOut);
    event Swapped(
        address indexed sender,
        string direction,
        uint256 ethIn,
        uint256 ethOut,
        uint256 spcIn,
        uint256 spcOut
    );

    error LiquidityPoolLocked();
    error NoLiquidityInPool();
    error WrongDepositInput();
    error NoLiquidityProvided(address);
    error InsuffiecientLiquidityBurned(uint256 _ethOut, uint256 _spcOut);
    error BurnTransferEthToError(address);
    error InsufficientInAmount(uint256 _ethIn, uint256 _spcIn);
    error InsufficientLiquidity(uint256 _amountOut, uint256 _reserve);
    error WrongKValueAfterSwap(uint256, uint256);
    error SwapTransferEthToError(address, uint256 _amountOut);
    error ReservesAmountInvalid(uint256 _ethReserve, uint256 _spcReserve);
    error OnlyOneTokenInAllowed(uint256 _ethIn, uint256 _spcIn);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SpaceCoin is ERC20 {
    // used only within this contract
    uint256 private constant SPC_TOTAL_SUPPLY = 500_000;

    // public since it's used in frontend too
    uint256 public constant ICO_SUPPLY = 150_000;

    address private immutable _owner;
    address payable public treasuryWallet;

    bool public isTaxActive;

    error MustBeOwner(string);

    /// @param _treasuryWallet Treasury wallet address
    constructor(address _treasuryWallet) ERC20("SpaceCoin", "SPC") {
        require(_treasuryWallet != address(0), "Invalid address");

        _owner = msg.sender;
        treasuryWallet = payable(_treasuryWallet);

        // mint tokens that are not part of ICO to treasury address
        _mint(treasuryWallet, (SPC_TOTAL_SUPPLY - ICO_SUPPLY) * (10**uint256(decimals())));

        // mint tokens that are part of ICO to the deployer
        // thehy will be transfered, during deploy, from deployer address to ICO contract
        // https://ethereum.stackexchange.com/a/97745
        _mint(msg.sender, ICO_SUPPLY * (10**uint256(decimals())));
    }

    /// @dev check sender is the owner
    modifier onlyOwner() {
        if (_owner != msg.sender) {
            revert MustBeOwner("NOT_OWNER");
        }
        _;
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * @param to Address where tokens will be moved
     * @param amount Amount to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (isTaxActive) {
            uint256 taxFee = (amount * 200) / 10000;
            amount -= taxFee;
            super._transfer(from, treasuryWallet, taxFee);
        }
        super._transfer(from, to, amount);
    }

    /// @dev toggle tax flag on/off
    function toggleTax() external onlyOwner {
        isTaxActive = !isTaxActive;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library Helpers {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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