//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICO/ISpaceCoin.sol";

/// @title LP Project
/// @author Agustin Bravo
/// @notice Liquidity pool contract to manage SPC/ETH trades and liquidity providers.
contract SpaceCoinLP is ERC20, Ownable {
    /// Min liquidity minted only once when liquidity is added for the first time.
    uint256 public constant MIN_LIQUIDITY = 1_000;
    /// Burn address constant
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// Storage reserve variables.
    uint256 private spcReserve;
    uint256 private ethReserve;

    /// Variables used to avoid reentrancy in the pool functions.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _locked;
        
    /// Immutable address of the SpaceCoin token setted in the constructor.
    address public immutable spaceCoinToken;

    /// @notice Event emmited once LP tokens are minted. Also this means liquidity was added to the pool.
    /// @param to Address were the LP tokens were minted.
    /// @param lpAmount Amount of LP tokens minted.
    event Minted(address indexed to, uint256 lpAmount);

    /// @notice Event emmited once LP tokens are burned. Also this means liquidity was removed from the pool.
    /// @param from Address that sent the LP tokens
    /// @param lpAmount Amount of LP tokens burned.
    event Burned(address indexed from, uint256 lpAmount);

    /// @notice Event emmited when a swap is executed successfully.
    /// @param sender Address that called the swap function in the pool contract.
    /// @param amountSpcIn Amount of SPC provided to the pool.
    /// @param amountEthIn Amount of ETH provided to the pool.
    /// @param amountSpcOut Amount of SPC tranfered from the pool.
    /// @param amountEthOut Amount of ETH tranfered from the pool.
    /// @param to Address where the funds were sent.
    event Swap(
        address indexed sender,
        uint256 amountSpcIn,
        uint256 amountEthIn,
        uint256 amountSpcOut,
        uint256 amountEthOut,
        address indexed to
    );

    /// @notice Event emmited when reserves are updated. Most functionalities will sync the pool reserves.
    /// @param spcReserve Amount of SPC in the pool reserves.
    /// @param ethReserve Amount of ETH in the pool reserves.    
    event Synced(uint256 spcReserve, uint256 ethReserve);

    /// Modifier used to avoid reentrancy in mintLpTokens, burnLpTokens and swap functions.
    modifier nonReentrant() {
        require(_locked != _ENTERED, "REENTRANT_CALL");
        _locked = _ENTERED;
        _;
        _locked = _NOT_ENTERED;
    }

    /// Constructor initialize spaceCointToken address and ERC20 name and symbol.
    constructor(address _spaceCoinToken, address _multiSig) ERC20("SPC-LP", "SPC-LP") {
        spaceCoinToken = _spaceCoinToken;
        transferOwnership(_multiSig);
    }

    /// @notice Getter function for the pool reserves.
    /// @return _spc Amount of SPC in the pool reserves.
    /// @return _eth Amount of ETH in the pool reserves.    
    function getReserves() public view returns (uint256 _spc, uint256 _eth) {
        _spc = spcReserve;
        _eth = ethReserve;
    }

    /// @notice Getter function for the pool balances.
    /// @return _spc Balance of SPC in the pool.
    /// @return _eth Balance of ETH in the pool.
    function getBalances() public view returns (uint256 _spc, uint256 _eth) {
        _spc = ERC20(spaceCoinToken).balanceOf(address(this));
        _eth = address(this).balance;
    }

    /// note: This function performs minimal checks and calling it directly will almost certainly incur user losses.
    /// @notice This function mints Lp tokens depending on the balances-reserves difference. Ideally should be called by the router.
    /// @param to Address were the LP tokens will be sent.
    /// @return liquidity Amount of LP tokens minted.
    function mintLpTokens(address to)
        external
        payable
        nonReentrant
        returns (uint256 liquidity)
    {
        (uint256 _spcReserve, uint256 _ethReserve) = getReserves();
        (uint256 spcBalance, uint256 ethBalance) = getBalances();
        uint256 totalSupply = totalSupply();
        // Transfer assets before calling (ETH in same function)
        uint256 spcProvided = spcBalance - _spcReserve;
        uint256 ethProvided = ethBalance - _ethReserve;
        if (totalSupply == 0) {
            // Trying to add liquidity bellow 1000 will revert with underflow added a specific check to help interactions
            uint256 firstLiquidity = sqrt(spcProvided * ethProvided);
            require(
                firstLiquidity > MIN_LIQUIDITY,
                "LIQUIDITY_MUST_BE_HIGHER_THAN_MIN_LIQ"
            );
            liquidity = firstLiquidity - MIN_LIQUIDITY;
            _mint(BURN_ADDRESS, MIN_LIQUIDITY);
        } else {
            uint256 lpFromSpc = (spcProvided * totalSupply) / _spcReserve;
            uint256 lpFromEth = (ethProvided * totalSupply) / _ethReserve;
            liquidity = lpFromSpc > lpFromEth ? lpFromEth : lpFromSpc;
        }
        require(liquidity > 0, "INSUFICIENT_LIQUIDITY");
        _mint(to, liquidity);

        _update(spcBalance, ethBalance);
        emit Minted(to, liquidity);
    }


    /// @notice This function burn Lp tokens depending on the balances-reserves difference. Ideally should be called by the router.
    /// @param to Address were the SPC-ETH funds will be sent.
    /// @return spcAmount Amount of SPC transfered from the pool to the "to" address.
    /// @return ethAmount Amount of ETH transfered from the pool to the "to" address.
    function burnLpTokens(address to)
        external
        nonReentrant
        returns (uint256 spcAmount, uint256 ethAmount)
    {
        (uint256 spcBalance, uint256 ethBalance) = getBalances();

        uint256 totalSupply = totalSupply();

        // Router must transfer lp tokens before calling burn
        uint256 liquidity = balanceOf(address(this));
        spcAmount = (liquidity * spcBalance) / totalSupply;
        ethAmount = (liquidity * ethBalance) / totalSupply;
        require(spcAmount > 0 && ethAmount > 0, "NO_LP_TO_BURN");
        _burn(address(this), liquidity);

        _safeTransferEth(to, ethAmount);
        _safeTransferSpc(to, spcAmount);

        (spcBalance, ethBalance) = getBalances();

        _update(spcBalance, ethBalance);
        emit Burned(to, liquidity);
    }

    /// @notice This function sends SPC or ETH depending on the current balances and reserves.
    /// @dev This function uses the same structure as Uniswap V2, ideally sending the amountsOut and then checkin the new K.
    /// @param to Address where the output asset will be sent.
    /// @param spcAmountOut Amount of SPC that will be sent from the pool.
    /// @param ethAmountOut Amount of ETH that will be sent from the pool.
    function swap(
        address to,
        uint256 spcAmountOut,
        uint256 ethAmountOut
    ) external payable nonReentrant {
        require(spcAmountOut > 0 || ethAmountOut > 0, "NO_OUTPUT_AMOUNTS");
        (uint256 _spcReserve, uint256 _ethReserve) = getReserves();
        require(
            spcAmountOut < _spcReserve && ethAmountOut < _ethReserve,
            "NOT_ENOUGHT_LIQUIDITY"
        );

        if (ethAmountOut > 0) {
            _safeTransferEth(to, ethAmountOut);
        }
        if (spcAmountOut > 0) {
            _safeTransferSpc(to, spcAmountOut);
        }

        (uint256 spcBalance, uint256 ethBalance) = getBalances();

        uint256 spcAmountIn = spcBalance > _spcReserve - spcAmountOut
            ? (spcBalance - _spcReserve)
            : 0;
        uint256 ethAmountIn = ethBalance > _ethReserve - ethAmountOut
            ? (ethBalance - ethReserve)
            : 0;
        require(spcAmountIn > 0 || ethAmountIn > 0, "NO_INPUTS");
        // Substracting 1% fee to pool and comparing newK
        uint256 spcBalanceAdjusted = (spcBalance * 100) - spcAmountIn;
        uint256 ethBalanceAdjusted = (ethBalance * 100) - ethAmountIn;
        // New K should always be equal or higher than old K (with reserves before update)
        require(
            spcBalanceAdjusted * ethBalanceAdjusted >=
                _spcReserve * _ethReserve * 10_000,
            "WRONG_K"
        );

        _update(spcBalance, ethBalance);
        emit Swap(
            msg.sender,
            spcAmountIn,
            ethAmountIn,
            spcAmountOut,
            ethAmountOut,
            to
        );
    }

    /// @dev Function used to sync the current reserves with the inputs balances.
    function _update(uint256 _spcBalance, uint256 _ethBalance) internal {
        spcReserve = _spcBalance;
        ethReserve = _ethBalance;
        emit Synced(spcReserve, ethReserve);
    }


    /// @dev Safe transfering SPC with return checks.
    function _safeTransferSpc(address to, uint256 spcAmountOut) internal {
        bool success = ISpaceCoin(spaceCoinToken).transfer(to, spcAmountOut);
        require(success, "SPC_TRANSFER_FAILED");
    }

    /// @dev Safe transfering ETH with return checks.
    function _safeTransferEth(address to, uint256 ethAmount) internal {
        (bool success, bytes memory data) = to.call{value: ethAmount}("");
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SPC_TRANSFER_FAILED"
        );
    }

    /// @dev implementatio of the babylonian method to find the square root of a given number.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface ISpaceCoin {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event TaxActive();

    event TaxInactive();

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function activateTax() external;

    function deactivateTax() external;
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