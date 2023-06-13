// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {WarpedToken} from "./WarpedToken.sol";
import {WarpedTaxHandler} from "./WarpedTaxHandler.sol";
import {WarpedTreasuryHandler, IUniswapV2Router02} from "./WarpedTreasuryHandler.sol";
import {WarpedPoolManager, EnumerableSet, IPoolManager} from "./WarpedPoolManager.sol";

import {IUniswapV2Factory} from "./interfaces/IUniswapV2Router02.sol";

/**
 * @title WARPED token manager.
 * @dev Manage WARPED token such as creating token and adding liquidity.
 */
contract WarpedTokenManager is WarpedPoolManager {
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeERC20 for IERC20;

	/// @notice WARPED token
	IERC20 public warpedToken;
	/// @notice Uniswap v2 router address
	IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
		IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	/// @notice Constructor of WARPED token manager
	/// @dev Create TaxHandler, TreasuryHandler, and Token contract
	/// @param treasuryAddress final tax treasury address
	/// @param nftContracts array of addresses of NFT contracts to calculate tax rate
	/// @param nftLevels array of levels of NFT contracts to calculate tax rate
	constructor(
		address treasuryAddress,
		address[] memory nftContracts,
		uint8[] memory nftLevels
	) {
		// 1. Create treasury and tax Handler
		WarpedTreasuryHandler treasuryHandler = new WarpedTreasuryHandler(
			IPoolManager(this)
		);
		WarpedTaxHandler taxHandler = new WarpedTaxHandler(
			IPoolManager(this),
			nftContracts,
			nftLevels
		);

		// 2. Create token contract and initilize treasury handler
		WarpedToken tokenContract = new WarpedToken(
			address(taxHandler),
			address(treasuryHandler)
		);
		// Initialize treasury handler with created token contract
		treasuryHandler.initialize(treasuryAddress, address(tokenContract));

		// 3. Transfer ownership of tax and transfer handlers into msgSender
		taxHandler.transferOwnership(_msgSender());
		treasuryHandler.transferOwnership(_msgSender());

		// 4. Transfer ownership of token contract into msgSender
		tokenContract.transferOwnership(_msgSender());
		warpedToken = IERC20(tokenContract);
	}

	/// @notice Ownable function to create and add liquidity
	/// @param amountToLiquidity amount of new tokens to add into liquidity
	function addLiquidity(uint256 amountToLiquidity) external payable onlyOwner {
		require(
			amountToLiquidity <= warpedToken.balanceOf(address(this)),
			"Amount exceed balance"
		);

		warpedToken.approve(address(UNISWAP_V2_ROUTER), amountToLiquidity);
		address uniswapV2Pair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory())
			.createPair(address(warpedToken), UNISWAP_V2_ROUTER.WETH());
		UNISWAP_V2_ROUTER.addLiquidityETH{value: address(this).balance}(
			address(warpedToken),
			amountToLiquidity,
			0,
			0,
			owner(),
			block.timestamp
		);
		IERC20(uniswapV2Pair).approve(address(UNISWAP_V2_ROUTER), type(uint).max);

		_exchangePools.add(address(uniswapV2Pair));
		primaryPool = address(uniswapV2Pair);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

/**
 * @title Exchange pool processor abstract contract.
 * @dev Keeps an enumerable set of designated exchange addresses as well as a single primary pool address.
 */
interface IPoolManager {
	/// @notice Primary exchange pool address.
	function primaryPool() external view returns (address);

	/**
	 * @notice Check if the given address is pool address.
	 * @param addr Address to check.
	 * @return bool True if the given address is pool address.
	 */
	function isPoolAddress(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

interface ITaxHandler {
	/**
	 * @notice Get number of tokens to pay as tax.
	 * @param benefactor Address of the benefactor.
	 * @param beneficiary Address of the beneficiary.
	 * @param amount Number of tokens in the transfer.
	 * @return taxAmount Number of tokens for tax.
	 */
	function getTax(
		address benefactor,
		address beneficiary,
		uint256 amount
	) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

/**
 * @title Treasury handler interface
 * @dev Any class that implements this interface can be used for protocol-specific operations pertaining to the treasury.
 */
interface ITreasuryHandler {
	/**
	 * @notice Perform operations before a transfer is executed.
	 * @param benefactor Address of the benefactor.
	 * @param beneficiary Address of the beneficiary.
	 * @param amount Number of tokens in the transfer.
	 */
	function processTreasury(
		address benefactor,
		address beneficiary,
		uint256 amount
	) external;
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

interface IUniswapV2Factory {
	function createPair(
		address tokenA,
		address tokenB
	) external returns (address pair);
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

/**
 * @title Lenient Reentrancy Guard
 * @dev A near carbon copy of OpenZeppelin's ReentrancyGuard contract. The difference between the two being that this
 * contract will silently return instead of failing.
 */
abstract contract LenientReentrancyGuard {
	// Booleans are more expensive than uint256 or any type that takes up a full
	// word because each write operation emits an extra SLOAD to first read the
	// slot's contents, replace the bits taken up by the boolean, and then write
	// back. This is the compiler's defense against contract upgrades and
	// pointer aliasing, and it cannot be disabled.

	// The values being non-zero value makes deployment a bit more expensive,
	// but in exchange the refund on every call to nonReentrant will be lower in
	// amount. Since refunds are capped to a percentage of the total
	// transaction's gas, it is best to keep them low in cases like this one, to
	// increase the likelihood of the full refund coming into effect.
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and making it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		if (_status == _ENTERED) {
			return;
		}

		_status = _ENTERED;
		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";

/**
 * @title Exchange pool processor abstract contract.
 * @dev Keeps an enumerable set of designated exchange addresses as well as a single primary pool address.
 */
contract WarpedPoolManager is IPoolManager, Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;

	/// @dev Set of exchange pool addresses.
	EnumerableSet.AddressSet internal _exchangePools;

	/// @notice Primary exchange pool address.
	address public override primaryPool;

	/// @notice Emitted when an exchange pool address is added to the set of tracked pool addresses.
	event ExchangePoolAdded(address exchangePool);

	/// @notice Emitted when an exchange pool address is removed from the set of tracked pool addresses.
	event ExchangePoolRemoved(address exchangePool);

	/// @notice Emitted when the primary pool address is updated.
	event PrimaryPoolUpdated(address oldPrimaryPool, address newPrimaryPool);

	// solhint-disable-next-line no-empty-blocks
	constructor() {}

	/**
	 * @notice Check if the given address is pool address.
	 * @param addr Address to check.
	 * @return bool True if the given address is pool address.
	 */
	function isPoolAddress(address addr) external view override returns (bool) {
		return _exchangePools.contains(addr);
	}

	/**
	 * @notice Add an address to the set of exchange pool addresses.
	 * @dev Nothing happens if the pool already exists in the set.
	 * @param exchangePool Address of exchange pool to add.
	 */
	function addExchangePool(address exchangePool) external onlyOwner {
		if (_exchangePools.add(exchangePool)) {
			emit ExchangePoolAdded(exchangePool);
		}
	}

	/**
	 * @notice Remove an address from the set of exchange pool addresses.
	 * @dev Nothing happens if the pool doesn't exist in the set..
	 * @param exchangePool Address of exchange pool to remove.
	 */
	function removeExchangePool(address exchangePool) external onlyOwner {
		if (_exchangePools.remove(exchangePool)) {
			emit ExchangePoolRemoved(exchangePool);
		}
	}

	/**
	 * @notice Set exchange pool address as primary pool.
	 * @dev To prevent issues, only addresses inside the set of exchange pool addresses can be selected as primary pool.
	 * @param exchangePool Address of exchange pool to set as primary pool.
	 */
	function setPrimaryPool(address exchangePool) external onlyOwner {
		require(
			_exchangePools.contains(exchangePool),
			"Not registered as exchange pool"
		);
		require(primaryPool != exchangePool, "Already primary pool address");

		address oldPrimaryPool = primaryPool;
		primaryPool = exchangePool;

		emit PrimaryPoolUpdated(oldPrimaryPool, exchangePool);
	}
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {ITaxHandler} from "./interfaces/ITaxHandler.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";

contract WarpedTaxHandler is ITaxHandler, Ownable {
	/// @notice NFTs to be used to determine user tax level.
	IERC721[] public nftContracts;
	/// @notice Bits representing levels of each NFTs: 1,2,4,8
	mapping(IERC721 => uint8) public nftLevels;

	struct TaxRatePoint {
		uint256 threshold;
		uint256 rate;
	}

	TaxRatePoint[] public taxRates;
	uint256 public basisTaxRate;
	uint256 public maxTaxRate = 400;
	bool public taxDisabled;
	IPoolManager public poolManager;

	/// @notice Constructor of tax handler contract
	/// @param _poolManager exchange pool manager address
	/// @param _nftContracts array of addresses of NFT contracts
	/// @param _levels array of levels of NFT contracts
	constructor(
		IPoolManager _poolManager,
		address[] memory _nftContracts,
		uint8[] memory _levels
	) {
		poolManager = _poolManager;

		_addNFTs(_nftContracts, _levels);
		// init default tax rates
		basisTaxRate = 400;
		taxRates.push(TaxRatePoint(7, 100));
		taxRates.push(TaxRatePoint(5, 200));
		taxRates.push(TaxRatePoint(1, 300));
		taxDisabled = false;
	}

	/**
	 * @notice Get number of tokens to pay as tax.
	 * @dev There is no easy way to differentiate between a user swapping
	 * tokens and a user adding or removing liquidity to the pool. In both
	 * cases tokens are transferred to or from the pool. This is an unfortunate
	 * case where users have to accept being taxed on liquidity additions and
	 * removal. To get around this issue a separate liquidity addition contract
	 * can be deployed. This contract could be exempt from taxes if its
	 * functionality is verified to only add and remove liquidity.
	 * @param benefactor Address of the benefactor.
	 * @param beneficiary Address of the beneficiary.
	 * @param amount Number of tokens in the transfer.
	 * @return taxAmount Number of tokens for tax
	 */
	function getTax(
		address benefactor,
		address beneficiary,
		uint256 amount
	) external view override returns (uint256) {
		if (taxDisabled) {
			return 0;
		}

		// Transactions between regular users (this includes contracts) aren't taxed.
		if (
			!poolManager.isPoolAddress(benefactor) &&
			!poolManager.isPoolAddress(beneficiary)
		) {
			return 0;
		}

		// Transactions between pools aren't taxed.
		if (
			poolManager.isPoolAddress(benefactor) &&
			poolManager.isPoolAddress(beneficiary)
		) {
			return 0;
		}

		uint256 taxRate = 0;
		// If the benefactor is found in the set of exchange pools, then it's a buy transactions, otherwise a sell
		// transactions, because the other use cases have already been checked above.
		if (poolManager.isPoolAddress(benefactor)) {
			taxRate = _getTaxBasisPoints(beneficiary);
		} else {
			taxRate = _getTaxBasisPoints(benefactor);
		}

		return (amount * taxRate) / 10000;
	}

	/**
	 * @notice Reset tax rate points.
	 * @param thresholds of user level.
	 * @param rates of tax per each threshold.
	 * @param _basisTaxRate basis tax rate.
	 *
	 * Requirements:
	 *
	 * - values of `thresholds` must be placed in ascending order.
	 */
	function setTaxRates(
		uint256[] memory thresholds,
		uint256[] memory rates,
		uint256 _basisTaxRate
	) external onlyOwner {
		require(thresholds.length == rates.length, "Invalid level points");
		require(_basisTaxRate > 0, "Invalid base rate");
		require(_basisTaxRate <= maxTaxRate, "Base rate must be <= than max");

		delete taxRates;
		for (uint256 i = 0; i < thresholds.length; i++) {
			require(rates[i] <= maxTaxRate, "Rate must be less than max rate");
			taxRates.push(TaxRatePoint(thresholds[i], rates[i]));
		}
		basisTaxRate = _basisTaxRate;
	}

	/**
	 * @notice Add addresses and their levels of NFTs(only ERC721).
	 * @dev For future NFT launch, allow to add new NFT addresses and levels.
	 * @param contracts NFT contract addresses.
	 * @param levels NFT contract levels to be used for user level calculation.
	 */
	function addNFTs(
		address[] memory contracts,
		uint8[] memory levels
	) external onlyOwner {
		require(contracts.length > 0 && levels.length > 0, "Invalid parameters");
		_addNFTs(contracts, levels);
	}

	/**
	 * @notice Remove nft level by address.
	 * @param contracts NFT contract addresses.
	 */
	function removeNFTs(address[] memory contracts) external onlyOwner {
		require(contracts.length > 0, "Invalid parameters");
		for (uint8 i = 0; i < contracts.length; i++) {
			for (uint8 j = 0; j < nftContracts.length; j++) {
				if (address(nftContracts[j]) == contracts[i]) {
					delete nftContracts[j];
					break;
				}
			}
			nftLevels[IERC721(contracts[i])] = 0;
		}
	}

	/**
	 * @notice Set no tax for special period
	 */
	function pauseTax() external onlyOwner {
		require(!taxDisabled, "Already paused");
		taxDisabled = true;
	}

	/**
	 * @notice Resume tax handling
	 */
	function resumeTax() external onlyOwner {
		require(taxDisabled, "Not paused");
		taxDisabled = false;
	}

	/**
	 * @notice Get percent of tax to pay for the given user.
	 * @dev Basis tax percent will be varied based on user's ownership of NFTs
	 * in the STARL metaverse. There are 3 user levels and user's level will be
	 * determined by bit-or of nft levels he owned.
	 * SATE: 8(4th bit), LM/LMvX: 4(3rd bit), PAL: 2(2nd bit), PN: 1(first bit)
	 * bit-or >= 7 : 1%
	 * bit-or >= 5 : 2%
	 * bit-or >= 1 : 3%
	 * @param user Address of user(buyer/seller address).
	 * @return Number Basis tax percent in 2 decimal.
	 */
	function _getTaxBasisPoints(address user) internal view returns (uint256) {
		uint256 userLevel = 0;
		for (uint256 i = 0; i < nftContracts.length; i++) {
			IERC721 nft = nftContracts[i];
			if (nft.balanceOf(user) > 0) {
				userLevel = userLevel | nftLevels[nftContracts[i]];
			}
		}
		for (uint256 i = 0; i < taxRates.length; i++) {
			if (userLevel >= taxRates[i].threshold) {
				return taxRates[i].rate;
			}
		}
		return basisTaxRate;
	}

	function _addNFTs(
		address[] memory contracts,
		uint8[] memory levels
	) internal {
		require(contracts.length == levels.length, "Invalid parameters");

		for (uint8 i = 0; i < contracts.length; i++) {
			require(IERC165(contracts[i]).supportsInterface(type(IERC721).interfaceId), "IERC721 not implemented");

			nftContracts.push(IERC721(contracts[i]));
			nftLevels[IERC721(contracts[i])] = levels[i];
		}
	}
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ITaxHandler} from "./interfaces/ITaxHandler.sol";
import {ITreasuryHandler} from "./interfaces/ITreasuryHandler.sol";
import {LenientReentrancyGuard} from "./LenientReentrancyGuard.sol";

/// @notice WARPED token contract
/// @dev extends standard ERC20 contract
contract WarpedToken is ERC20, Ownable, LenientReentrancyGuard {
	uint8 private constant _DECIMALS = 18;
	uint256 private constant _T_TOTAL = 10_000_000_000 * 10 ** _DECIMALS;
	string private constant _NAME = unicode"WARPED";
	string private constant _SYMBOL = unicode"WARPED";

	/// @notice Tax handler address
	ITaxHandler public taxHandler;
	/// @notice Treasury handler address
	ITreasuryHandler public treasuryHandler;

	/// @notice Constructor of WARPED token contract
	/// @dev initialize with tax and treasury handler addresses.
	/// @param taxHandlerAddress tax handler contract address
	/// @param treasuryHandlerAddress treasury handler contract address
	constructor(
		address taxHandlerAddress,
		address treasuryHandlerAddress
	) ERC20(_NAME, _SYMBOL) {
		taxHandler = ITaxHandler(taxHandlerAddress);
		treasuryHandler = ITreasuryHandler(treasuryHandlerAddress);

		_mint(_msgSender(), _T_TOTAL);
	}

	/**
	 * @dev See {ERC20-_beforeTokenTransfer}.
	 * forward into beforeTokenTransferHandler function of treasury handler
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override nonReentrant {
		treasuryHandler.processTreasury(from, to, amount);
	}

	/**
	 * @dev See {ERC20-_afterTokenTransfer}.
	 * calculate tax, reward, and burn amount using tax handler and transfer using _transfer function
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override nonReentrant {
		if (from == address(0x0)) {
			// skip for mint
			return;
		}

		uint256 taxAmount;
		taxAmount = taxHandler.getTax(from, to, amount);
		if (taxAmount > 0) {
			_transfer(to, address(treasuryHandler), taxAmount);
		}
	}

	/**
	 * @notice Update tax handler
	 * @param taxHandlerAddress address of tax handler contract.
	 */
	function updateTaxHandler(address taxHandlerAddress) external onlyOwner {
		require(taxHandlerAddress != address(0x00), "Zero tax handler address");
		require(
			taxHandlerAddress != address(taxHandler),
			"Same tax handler address"
		);

		taxHandler = ITaxHandler(taxHandlerAddress);
	}

	/**
	 * @notice Update treasury handler
	 * @param treasuryHandlerAddress address of treasury handler contract.
	 */
	function updateTreasuryHandler(
		address treasuryHandlerAddress
	) external onlyOwner {
		require(
			treasuryHandlerAddress != address(0x00),
			"Zero treasury handler address"
		);
		require(
			treasuryHandlerAddress != address(treasuryHandler),
			"Same treasury handler address"
		);

		treasuryHandler = ITreasuryHandler(treasuryHandlerAddress);
	}
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

import {IPoolManager} from "./interfaces/IPoolManager.sol";
import {ITreasuryHandler} from "./interfaces/ITreasuryHandler.sol";

/**
 * @title Treasury handler contract
 * @dev Sells tokens that have accumulated through taxes and sends the resulting ETH to the treasury. If
 * `liquidityBasisPoints` has been set to a non-zero value, then that percentage will instead be added to the designated
 * liquidity pool.
 */
contract WarpedTreasuryHandler is ITreasuryHandler, Ownable {
	using Address for address payable;

	IPoolManager public poolManager;

	/// @notice The Treasury address.
	address payable public treasury;

	/// @notice The token that accumulates through taxes. This will be sold for ETH.
	IERC20 public token;

	/// @notice The basis points of tokens to sell and add as liquidity to the pool.
	uint256 public liquidityBasisPoints;

	/// @notice The maximum price impact the sell (initiated from this contract) may have.
	uint256 public priceImpactBasisPoints;

	/// @dev swap contract balance if it's over this value
	uint256 private _taxSwap;

	bool private _isInitialized;

	/// @notice The Uniswap router that handles the sell and liquidity operations.
	IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
		IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	/// @notice Emitted when the basis points value of tokens to add as liquidity is updated.
	event LiquidityBasisPointsUpdated(
		uint256 oldBasisPoints,
		uint256 newBasisPoints
	);

	/// @notice Emitted when the maximum price impact basis points value is updated.
	event PriceImpactBasisPointsUpdated(
		uint256 oldBasisPoints,
		uint256 newBasisPoints
	);

	/// @notice Emitted when the treasury address is updated.
	event TreasuryAddressUpdated(
		address oldTreasuryAddress,
		address newTreasuryAddress
	);

	/// @notice Constructor of tax handler contract
	/// @param _poolManager exchange pool manager address
	constructor(IPoolManager _poolManager) {
		poolManager = _poolManager;
	}

	/**
	 * @param treasuryAddress Address of treasury to use.
	 * @param tokenAddress Address of token to accumulate and sell.
	 */
	function initialize(
		address treasuryAddress,
		address tokenAddress
	) external onlyOwner {
		require(!_isInitialized, "Already initialized");

		treasury = payable(treasuryAddress);
		token = IERC20(tokenAddress);
		liquidityBasisPoints = 0;
		priceImpactBasisPoints = 500;
		_taxSwap = 10_000_000 * 10 ** 18;
		_isInitialized = true;
	}

	/**
	 * @notice Perform operations before a sell action (or a liquidity addition) is executed. The accumulated tokens are
	 * then sold for ETH. In case the number of accumulated tokens exceeds the price impact percentage threshold, then
	 * the number will be adjusted to stay within the threshold. If a non-zero percentage is set for liquidity, then
	 * that percentage will be added to the primary liquidity pool instead of being sold for ETH and sent to the
	 * treasury.
	 * @param benefactor Address of the benefactor.
	 * @param beneficiary Address of the beneficiary.
	 * @param amount Number of tokens in the transfer.
	 */
	function processTreasury(
		address benefactor,
		address beneficiary,
		uint256 amount
	) external override {
		if (!_isInitialized || benefactor == address(0x0)) {
			// skip when not initialized or mint
			return;
		}

		// No actions are done on transfers other than sells.
		if (!poolManager.isPoolAddress(beneficiary)) {
			return;
		}

		uint256 contractTokenBalance = token.balanceOf(address(this));
		if (contractTokenBalance > _taxSwap) {
			uint256 primaryPoolBalance = token.balanceOf(poolManager.primaryPool());
			uint256 maxPriceImpactSale = (primaryPoolBalance *
				priceImpactBasisPoints) / 10000;

			contractTokenBalance = _taxSwap > amount ? amount : _taxSwap;

			// Ensure the price impact is within reasonable bounds.
			if (contractTokenBalance > maxPriceImpactSale) {
				contractTokenBalance = maxPriceImpactSale;
			}

			// The number of tokens to sell for liquidity purposes. This is calculated as follows:
			//
			//      B     P
			//  L = - * -----
			//      2   10000
			//
			// Where:
			//  L = tokens to sell for liquidity
			//  B = available token balance
			//  P = basis points of tokens to use for liquidity
			//
			// The number is divided by two to preserve the token side of the token/WETH pool.
			uint256 tokensForLiquidity = (contractTokenBalance *
				liquidityBasisPoints) / 20000;
			uint256 tokensForSwap = contractTokenBalance - tokensForLiquidity;

			uint256 currentWeiBalance = address(this).balance;
			_swapTokensForEth(tokensForSwap);
			uint256 weiEarned = address(this).balance - currentWeiBalance;

			// No need to divide this number, because that was only to have enough tokens remaining to pair with this
			// ETH value.
			uint256 weiForLiquidity = (weiEarned * liquidityBasisPoints) / 10000;

			if (tokensForLiquidity > 0) {
				_addLiquidity(tokensForLiquidity, weiForLiquidity);
			}

			// It's cheaper to get the active balance rather than calculating based off of the `currentWeiBalance` and
			// `weiForLiquidity` numbers.
			uint256 remainingWeiBalance = address(this).balance;
			if (remainingWeiBalance > 0) {
				treasury.sendValue(remainingWeiBalance);
			}
		}
	}

	/**
	 * @notice Set new liquidity basis points value.
	 * @param newBasisPoints New liquidity basis points value. Cannot exceed 10,000 (i.e., 100%) as that would break the
	 * calculation.
	 */
	function setLiquidityBasisPoints(uint256 newBasisPoints) external onlyOwner {
		require(newBasisPoints <= 10000, "Max is 10000");

		uint256 oldBasisPoints = liquidityBasisPoints;
		liquidityBasisPoints = newBasisPoints;

		emit LiquidityBasisPointsUpdated(oldBasisPoints, newBasisPoints);
	}

	/**
	 * @notice Set new price impact basis points value.
	 * @param newBasisPoints New price impact basis points value.
	 */
	function setPriceImpactBasisPoints(
		uint256 newBasisPoints
	) external onlyOwner {
		require(newBasisPoints < 1500, "Too high value");

		uint256 oldBasisPoints = priceImpactBasisPoints;
		priceImpactBasisPoints = newBasisPoints;

		emit PriceImpactBasisPointsUpdated(oldBasisPoints, newBasisPoints);
	}

	/**
	 * @notice Set new treasury address.
	 * @param newTreasuryAddress New treasury address.
	 */
	function setTreasury(address newTreasuryAddress) external onlyOwner {
		require(newTreasuryAddress != address(0), "Zero address");

		address oldTreasuryAddress = address(treasury);
		treasury = payable(newTreasuryAddress);

		emit TreasuryAddressUpdated(oldTreasuryAddress, newTreasuryAddress);
	}

	/**
	 * @notice Withdraw any tokens or ETH stuck in the treasury handler.
	 * @param tokenAddress Address of the token to withdraw. If set to the zero address, ETH will be withdrawn.
	 * @param amount The number of tokens to withdraw.
	 */
	function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
		if (tokenAddress == address(0)) {
			treasury.sendValue(amount);
		} else {
			IERC20(tokenAddress).transfer(address(treasury), amount);
		}
	}

	function updateTaxSwap(uint256 taxSwap) external onlyOwner {
		require(taxSwap > 0, "Zero taxSwap");
		_taxSwap = taxSwap;
	}

	/**
	 * @notice Allow contract to accept ETH.
	 */
	// solhint-disable-next-line no-empty-blocks
	receive() external payable {}

	/**
	 * @dev Swap accumulated tokens for ETH.
	 * @param tokenAmount Number of tokens to swap for ETH.
	 */
	function _swapTokensForEth(uint256 tokenAmount) internal {
		// The ETH/token pool is the primary pool. It always exists.
		address[] memory path = new address[](2);
		path[0] = address(token);
		path[1] = UNISWAP_V2_ROUTER.WETH();

		// Ensure the router can perform the swap for the designated number of tokens.
		token.approve(address(UNISWAP_V2_ROUTER), tokenAmount);
		UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0,
			path,
			address(this),
			block.timestamp
		);
	}

	/**
	 * @dev Add liquidity to primary pool.
	 * @param tokenAmount Number of tokens to add as liquidity.
	 * @param weiAmount ETH value to pair with the tokens.
	 */
	function _addLiquidity(uint256 tokenAmount, uint256 weiAmount) internal {
		// Ensure the router can perform the transfer for the designated number of tokens.
		token.approve(address(UNISWAP_V2_ROUTER), tokenAmount);

		// Both minimum values are set to zero to allow for any form of slippage.
		UNISWAP_V2_ROUTER.addLiquidityETH{value: weiAmount}(
			address(token),
			tokenAmount,
			0,
			0,
			address(treasury),
			block.timestamp
		);
	}
}