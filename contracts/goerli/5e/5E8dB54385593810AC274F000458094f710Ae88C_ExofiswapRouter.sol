// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IExofiswapERC20.sol";

contract ExofiswapERC20 is ERC20, IExofiswapERC20
{
	// keccak256("permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 private constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
	mapping(address => uint256) private _nonces;

	constructor(string memory tokenName) ERC20(tokenName, "ENERGY")
	{ } // solhint-disable-line no-empty-blocks

	// The standard ERC-20 race condition for approvals applies to permit as well.
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) override public
	{
		// solhint-disable-next-line not-rely-on-time
		require(deadline >= block.timestamp, "Exofiswap: EXPIRED");
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR(),
				keccak256(
					abi.encode(
						_PERMIT_TYPEHASH,
						owner,
						spender,
						value,
						_nonces[owner]++,
						deadline
					)
				)
			)
		);
		address recoveredAddress = ecrecover(digest, v, r, s);
		// Since the ecrecover precompile fails silently and just returns the zero address as signer when given malformed messages,
		// it is important to ensure owner != address(0) to avoid permit from creating an approval to spend “zombie funds”
		// belong to the zero address.
		require(recoveredAddress != address(0) && recoveredAddress == owner, "Exofiswap: INVALID_SIGNATURE");
		_approve(owner, spender, value);
	}

	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() override public view returns(bytes32)
	{
		// If the DOMAIN_SEPARATOR contains the chainId and is defined at contract deployment instead of reconstructed
		// for every signature, there is a risk of possible replay attacks between chains in the event of a future chain split
		return keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name())),
				keccak256(bytes("1")),
				block.chainid,
				address(this)
			)
		);
	}

	function nonces(address owner) override public view returns (uint256)
	{
		return _nonces[owner];
	}

	function PERMIT_TYPEHASH() override public pure returns (bytes32) //solhint-disable-line func-name-mixedcase
	{
		return _PERMIT_TYPEHASH;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/token/ERC20/extensions/IERC20AltApprove.sol";
import "../../interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
* @notice Implementation of the {IERC20Metadata} interface.
* The IERC20Metadata interface extends the IERC20 interface.
*
* This implementation is agnostic to the way tokens are created. This means
* that a supply mechanism has to be added in a derived contract using {_mint}.
* For a generic mechanism see Open Zeppelins {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20AltApprove, IERC20Metadata
{
	uint256 internal _totalSupply;
	mapping(address => uint256) internal _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	string private _name;
	string private _symbol;

	/**
	* @notice Sets the values for {name} and {symbol}.
	*
	* The default value of {decimals} is 18. To select a different value for
	* {decimals} you should overload it.
	*
	* All two of these values are immutable: they can only be set once during
	* construction.
	*/
	constructor(string memory tokenName, string memory tokenSymbol)
	{
		_name = tokenName;
		_symbol = tokenSymbol;
	}

	/**
	* @notice See {IERC20-approve}.
	*
	* NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
	* `transferFrom`. This is semantically equivalent to an infinite approval.
	*
	* Requirements:
	*
	* - `spender` cannot be the zero address.
	*/
	function approve(address spender, uint256 amount) override public virtual returns (bool)
	{
		address owner = _msgSender();
		_approve(owner, spender, amount);
		return true;
	}

	/**
	* @notice Atomically decreases the allowance granted to `spender` by the caller.
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
	function decreaseAllowance(address spender, uint256 subtractedValue) override public virtual returns (bool)
	{
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: reduced allowance below 0");
		unchecked {
			_approve(owner, spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	/**
	* @notice Atomically increases the allowance granted to `spender` by the caller.
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
	function increaseAllowance(address spender, uint256 addedValue) override public virtual returns (bool)
	{
		address owner = _msgSender();
		_approve(owner, spender, allowance(owner, spender) + addedValue);
		return true;
	}

	/**
	* @notice See {IERC20-transfer}.
	*
	* Requirements:
	*
	* - `to` cannot be the zero address.
	* - the caller must have a balance of at least `amount`.
	*/
	function transfer(address to, uint256 amount) override public virtual returns (bool)
	{
		address owner = _msgSender();
		_transfer(owner, to, amount);
		return true;
	}

	/**
	* @notice See {IERC20-transferFrom}.
	*
	* Emits an {Approval} event indicating the updated allowance. This is not
	* required by the EIP. See the note at the beginning of {ERC20}.
	*
	* NOTE: Does not update the allowance if the current allowance is the maximum `uint256`.
	*
	* Requirements:
	*
	* - `from` and `to` cannot be the zero address.
	* - `from` must have a balance of at least `amount`.
	* - the caller must have allowance for ``from``'s tokens of at least
	* `amount`.
	*/
	function transferFrom(address from, address to, uint256 amount) override public virtual returns (bool)
	{
		address spender = _msgSender();
		_spendAllowance(from, spender, amount);
		_transfer(from, to, amount);
		return true;
	}

	/**
	* @notice See {IERC20-allowance}.
	*/
	function allowance(address owner, address spender) override public view virtual returns (uint256)
	{
		return _allowances[owner][spender];
	}

	/**
	* @notice See {IERC20-balanceOf}.
	*/
	function balanceOf(address account) override public view virtual returns (uint256)
	{
		return _balances[account];
	}

	/**
	* @notice Returns the name of the token.
	*/
	function name() override public view virtual returns (string memory)
	{
		return _name;
	}

	/**
	* @notice Returns the symbol of the token, usually a shorter version of the
	* name.
	*/
	function symbol() override public view virtual returns (string memory)
	{
		return _symbol;
	}

	/**
	* @notice See {IERC20-totalSupply}.
	*/
	function totalSupply() override public view virtual returns (uint256)
	{
		return _totalSupply;
	}

	/**
	* @notice Returns the number of decimals used to get its user representation.
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
	function decimals() override public pure virtual returns (uint8)
	{
		return 18;
	}

	/**
	* @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
	function _approve(address owner, address spender, uint256 amount) internal virtual
	{
		require(owner != address(0), "ERC20: approve from address(0)");
		require(spender != address(0), "ERC20: approve to address(0)");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	* @notice Destroys `amount` tokens from `account`, reducing the
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
		require(account != address(0), "ERC20: burn from address(0)");

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
		}
		_totalSupply -= amount;

		emit Transfer(account, address(0), amount);
	}

	/** @notice Creates `amount` tokens and assigns them to `account`, increasing
	* the total supply.
	*
	* Emits a {Transfer} event with `from` set to the zero address.
	*
	* Requirements:
	*
	* - `account` cannot be the zero address.
	*/
	function _mint(address account, uint256 amount) internal virtual
	{
		require(account != address(0), "ERC20: mint to address(0)");

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);
	}

	/**
	* @notice Updates `owner` s allowance for `spender` based on spent `amount`.
	*
	* Does not update the allowance amount in case of infinite allowance.
	* Revert if not enough allowance is available.
	*
	* Might emit an {Approval} event.
	*/
	function _spendAllowance(address owner, address spender, uint256 amount) internal virtual
	{
		uint256 currentAllowance = allowance(owner, spender);
		if (currentAllowance != type(uint256).max) {
			require(currentAllowance >= amount, "ERC20: insufficient allowance");
			unchecked {
				_approve(owner, spender, currentAllowance - amount);
			}
		}
	}

	/**
	* @notice Moves `amount` of tokens from `sender` to `recipient`.
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
	function _transfer(address from, address to, uint256 amount) internal virtual
	{
		require(from != address(0), "ERC20: transfer from address(0)");
		require(to != address(0), "ERC20: transfer to address(0)");

		uint256 fromBalance = _balances[from];
		require(fromBalance >= amount, "ERC20: transfer exceeds balance");
		unchecked {
			_balances[from] = fromBalance - amount;
		}
		_balances[to] += amount;

		emit Transfer(from, to, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20AltApprove.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";

interface IExofiswapERC20 is IERC20AltApprove, IERC20Metadata
{
	// Functions as described in EIP 2612
	function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
	function nonces(address owner) external view returns (uint256);
	function DOMAIN_SEPARATOR() external view returns (bytes32); // solhint-disable-line func-name-mixedcase
	function PERMIT_TYPEHASH() external pure returns (bytes32); //solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC20Metadata interface.
/// @author Ing. Michael Goldfinger
/// @notice Interface for an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}.
/// @dev This is not part of the ERC20 specification.
interface IERC20AltApprove
{
	/**
	* @notice Atomically decreases the allowance granted to `spender` by the caller.
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
	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

	/**
	* @notice Atomically increases the allowance granted to `spender` by the caller.
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
	function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC20.sol";

/// @title ERC20Metadata interface.
/// @author Ing. Michael Goldfinger
/// @notice Interface for the optional metadata functions from the ERC20 standard.
interface IERC20Metadata is IERC20
{
	/// @notice Returns the name of the token.
	/// @return The token name.
	function name() external view returns (string memory);

	/// @notice Returns the symbol of the token.
	/// @return The symbol for the token.
	function symbol() external view returns (string memory);

	/// @notice Returns the decimals of the token.
	/// @return The decimals for the token.
	function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @notice Provides information about the current execution context, including the
* sender of the transaction and its data. While these are generally available
* via msg.sender and msg.data, they should not be accessed in such a direct
* manner, since when dealing with meta-transactions the account sending and
* paying for execution may not be the actual sender (as far as an application
* is concerned).
*
* This contract is only required for intermediate, library-like contracts.
*/
abstract contract Context
{
	/// @notice returns the sender of the transaction.
	/// @return The sender of the transaction.
	function _msgSender() internal view virtual returns (address)
	{
		return msg.sender;
	}

	/// @notice returns the data of the transaction.
	/// @return The data of the transaction.
	function _msgData() internal view virtual returns (bytes calldata)
	{
		return msg.data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface.
 * @author Ing. Michael Goldfinger
 * @notice Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20
{
	/**
	 * @notice Emitted when the allowance of a {spender} for an {owner} is set to a new value.
	 *
	 * NOTE: {value} may be zero.
	 * @param owner (indexed) The owner of the tokens.
	 * @param spender (indexed) The spender for the tokens.
	 * @param value The amount of tokens that got an allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @notice Emitted when {value} tokens are moved from one address {from} to another {to}.
	 *
	 * NOTE: {value} may be zero.
	 * @param from (indexed) The origin of the transfer.
	 * @param to (indexed) The target of the transfer.
	 * @param value The amount of tokens that got transfered.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

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
	* @dev Moves `amount` tokens from the caller's account to `to`.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
	function transfer(address to, uint256 amount) external returns (bool);

	/**
	* @dev Moves `amount` tokens from `from` to `to` using the allowance mechanism.
	* `amount` is then deducted from the caller's allowance.
	*
	* Returns a boolean value indicating whether the operation succeeded.
	*
	* Emits a {Transfer} event.
	*/
	function transferFrom(address from, address to, uint256 amount) external returns (bool);

	/**
	* @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
	* This is zero by default.
	*
	* This value changes when {approve}, {increaseAllowance}, {decreseAllowance} or {transferFrom} are called.
	*/
	function allowance(address owner, address spender) external view returns (uint256);

	/**
	* @dev Returns the amount of tokens owned by `account`.
	*/
	function balanceOf(address account) external view returns (uint256);

	/**
	* @dev Returns the amount of tokens in existence.
	*/
	function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Exofiswap/ExofiswapERC20.sol";

contract ExofiswapERC20Mock is ExofiswapERC20
{
	constructor(string memory name, uint256 supply) ExofiswapERC20(name)
	{
		_mint(msg.sender, supply);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IExofiswapCallee.sol";
import "./interfaces/IExofiswapFactory.sol";
import "./interfaces/IExofiswapPair.sol";
import "./interfaces/IMigrator.sol";
import "./ExofiswapERC20.sol";
import "./libraries/MathUInt32.sol";
import "./libraries/MathUInt256.sol";
import "./libraries/UQ144x112.sol";

contract ExofiswapPair is IExofiswapPair, ExofiswapERC20
{
	// using UQ144x112 for uint256;
	// using SafeERC20 for IERC20Metadata; // For some unknown reason using this needs a little more gas than using the library without it.
	struct SwapAmount // needed to reduce stack deep;
	{
		uint256 balance0;
		uint256 balance1;
		uint112 reserve0;
		uint112 reserve1;
	}

	uint256 private constant _MINIMUM_LIQUIDITY = 10**3;
	uint256 private _price0CumulativeLast;
	uint256 private _price1CumulativeLast;
	uint256 private _kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event
	uint256 private _unlocked = 1;
	uint112 private _reserve0;           // uses single storage slot, accessible via getReserves
	uint112 private _reserve1;           // uses single storage slot, accessible via getReserves
	uint32  private _blockTimestampLast; // uses single storage slot, accessible via getReserves
	IExofiswapFactory private immutable _factory;
	IERC20Metadata private _token0;
	IERC20Metadata private _token1;

	modifier lock()
	{
		require(_unlocked == 1, "EP: LOCKED");
		_unlocked = 0;
		_;
		_unlocked = 1;
	}

	constructor() ExofiswapERC20("Plasma")
	{
		_factory = IExofiswapFactory(_msgSender());
	}

	// called once by the factory at time of deployment
	function initialize(IERC20Metadata token0Init, IERC20Metadata token1Init) override external
	{
		require(_msgSender() == address(_factory), "EP: FORBIDDEN");
		_token0 = token0Init;
		_token1 = token1Init;
	}

	// this low-level function should be called from a contract which performs important safety checks
	function burn(address to) override public lock returns (uint, uint)
	{
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1,) = getReserves(); // gas savings
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));
		uint256 liquidity = balanceOf(address(this));

		// Can not overflow
		bool feeOn = _mintFee(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1));
		uint256 totalSupplyValue = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 amount0 = MathUInt256.unsafeDiv(liquidity * sa.balance0, totalSupplyValue); // using balances ensures pro-rata distribution
		uint256 amount1 = MathUInt256.unsafeDiv(liquidity * sa.balance1, totalSupplyValue); // using balances ensures pro-rata distribution
		require(amount0 > 0 && amount1 > 0, "EP: INSUFFICIENT_LIQUIDITY");
		_burn(address(this), liquidity);
		SafeERC20.safeTransfer(_token0, to, amount0);
		SafeERC20.safeTransfer(_token1, to, amount1);
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));

		_update(sa);

		if (feeOn)
		{
			unchecked // Can not overflow
			{
				// _reserve0 and _reserve1 are up-to-date
				// What _update(sa) does is set _reserve0 to sa.balance0 and _reserve1 to sa.balance1
				// So there is no neet to access and converte the _reserves directly,
				// instead use the known balances that are already in the correct type.
				_kLast = sa.balance0 * sa.balance1; 
			}
		}
		emit Burn(msg.sender, amount0, amount1, to);
		return (amount0, amount1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function mint(address to) override public lock returns (uint256)
	{
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1,) = getReserves(); // gas savings
		sa.balance0 = _token0.balanceOf(address(this));
		sa.balance1 = _token1.balanceOf(address(this));
		uint256 amount0 = sa.balance0 - sa.reserve0;
		uint256 amount1 = sa.balance1 - sa.reserve1;

		bool feeOn = _mintFee(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1));
		uint256 totalSupplyValue = _totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
		uint256 liquidity;

		if (totalSupplyValue == 0)
		{
			IMigrator migrator = _factory.migrator();
			if (_msgSender() == address(migrator))
			{
				liquidity = migrator.desiredLiquidity();
				require(liquidity > 0 && liquidity != type(uint256).max, "EP: Liquidity Error");
			}
			else
			{
				require(address(migrator) == address(0), "EP: Migrator set");
				liquidity = MathUInt256.sqrt(amount0 * amount1) - _MINIMUM_LIQUIDITY;
				_mintMinimumLiquidity();
			}
		}
		else
		{
			//Div by uint can not overflow
			liquidity = 
				MathUInt256.min(
					MathUInt256.unsafeDiv(amount0 * totalSupplyValue, sa.reserve0),
					MathUInt256.unsafeDiv(amount1 * totalSupplyValue, sa.reserve1)
				);
		}
		require(liquidity > 0, "EP: INSUFFICIENT_LIQUIDITY");
		_mint(to, liquidity);

		_update(sa);
		if (feeOn)
		{
			// _reserve0 and _reserve1 are up-to-date
			// What _update(sa) does is set _reserve0 to sa.balance0 and _reserve1 to sa.balance1
			// So there is no neet to access and converte the _reserves directly,
			// instead use the known balances that are already in the correct type.
			_kLast = sa.balance0 * sa.balance1; 
		}
		emit Mint(_msgSender(), amount0, amount1);
		return liquidity;
	}

	// force balances to match reserves
	function skim(address to) override public lock
	{
		SafeERC20.safeTransfer(_token0, to, _token0.balanceOf(address(this)) - _reserve0);
		SafeERC20.safeTransfer(_token1, to, _token1.balanceOf(address(this)) - _reserve1);
	}

	// this low-level function should be called from a contract which performs important safety checks
	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) override public lock
	{
		require(amount0Out > 0 || amount1Out > 0, "EP: INSUFFICIENT_OUTPUT_AMOUNT");
		SwapAmount memory sa;
		(sa.reserve0, sa.reserve1, ) = getReserves(); // gas savings
		require(amount0Out < sa.reserve0, "EP: INSUFFICIENT_LIQUIDITY");
		require(amount1Out < sa.reserve1, "EP: INSUFFICIENT_LIQUIDITY");

		(sa.balance0, sa.balance1) = _transferTokens(to, amount0Out, amount1Out, data);

		(uint256 amount0In, uint256 amount1In) = _getInAmounts(amount0Out, amount1Out, sa);
		require(amount0In > 0 || amount1In > 0, "EP: INSUFFICIENT_INPUT_AMOUNT");
		{ 
			// This is a sanity check to make sure we don't lose from the swap.
			// scope for reserve{0,1} Adjusted, avoids stack too deep errors
			uint256 balance0Adjusted = (sa.balance0 * 1000) - (amount0In * 3); 
			uint256 balance1Adjusted = (sa.balance1 * 1000) - (amount1In * 3); 
			// 112 bit * 112 bit * 20 bit can not overflow a 256 bit value
			// Bigest possible number is 2,695994666715063979466701508702e+73
			// uint256 maxvalue is 1,1579208923731619542357098500869e+77
			// or 2**112 * 2**112 * 2**20 = 2**244 < 2**256
			require(balance0Adjusted * balance1Adjusted >= MathUInt256.unsafeMul(MathUInt256.unsafeMul(sa.reserve0, sa.reserve1), 1_000_000), "EP: K");
		}
		_update(sa);
		emit Swap(_msgSender(), amount0In, amount1In, amount0Out, amount1Out, to);
	}

	
	// force reserves to match balances
	function sync() override public lock
	{
		_update(SwapAmount(_token0.balanceOf(address(this)), _token1.balanceOf(address(this)), _reserve0, _reserve1));
	}
	
	function factory() override public view returns (IExofiswapFactory)
	{
		return _factory;
	}

	function getReserves() override public view returns (uint112, uint112, uint32)
	{
		return (_reserve0, _reserve1, _blockTimestampLast);
	}

	function kLast() override public view returns (uint256)
	{
		return _kLast;
	}
	
	function name() override(ERC20, IERC20Metadata) public view virtual returns (string memory)
	{
		return string(abi.encodePacked(_token0.symbol(), "/", _token1.symbol(), " ", super.name()));
	}

	function price0CumulativeLast() override public view returns (uint256)
	{
		return _price0CumulativeLast;
	}

	function price1CumulativeLast() override public view returns (uint256)
	{
		return _price1CumulativeLast;
	}


	function token0() override public view returns (IERC20Metadata)
	{
		return _token0;
	}
	
	function token1() override public view returns (IERC20Metadata)
	{
		return _token1;
	}

	function MINIMUM_LIQUIDITY() override public pure returns (uint256) //solhint-disable-line func-name-mixedcase
	{
		return _MINIMUM_LIQUIDITY;
	}

	function _mintMinimumLiquidity() private
	{
		require(_totalSupply == 0, "EP: Total supply not 0");

		_totalSupply += _MINIMUM_LIQUIDITY;
		_balances[address(0)] += _MINIMUM_LIQUIDITY;
		emit Transfer(address(0), address(0), _MINIMUM_LIQUIDITY);
	}

	function _transferTokens(address to, uint256 amount0Out, uint256 amount1Out, bytes calldata data) private returns (uint256, uint256)
	{
		require(address(to) != address(_token0) && to != address(_token1), "EP: INVALID_TO");
		if (amount0Out > 0) SafeERC20.safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
		if (amount1Out > 0) SafeERC20.safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
		if (data.length > 0) IExofiswapCallee(to).exofiswapCall(_msgSender(), amount0Out, amount1Out, data);
		return (_token0.balanceOf(address(this)), _token1.balanceOf(address(this)));
	}

	// if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
	function _mintFee(uint256 k) private returns (bool)
	{
		address feeTo = _factory.feeTo();
		uint256 kLastHelp = _kLast; // gas savings
		if (feeTo != address(0))
		{
			if (kLastHelp != 0)
			{
				uint256 rootK = MathUInt256.sqrt(k);
				uint256 rootKLast = MathUInt256.sqrt(kLastHelp);
				if (rootK > rootKLast)
				{
					uint256 numerator = _totalSupply * MathUInt256.unsafeSub(rootK, rootKLast);
					// Since rootK is the sqrt of k. Multiplication by 5 can never overflow
					uint256 denominator = MathUInt256.unsafeMul(rootK, 5) + rootKLast;
					uint256 liquidity = MathUInt256.unsafeDiv(numerator, denominator);
					if (liquidity > 0)
					{
						_mint(feeTo, liquidity);
					}
				}
			}
			return true;
		}
		if(kLastHelp != 0)
		{
			_kLast = 0;
		}
		return false;
	}

	// update reserves and, on the first call per block, price accumulators
	function _update(SwapAmount memory sa) private
	{
		require(sa.balance0 <= type(uint112).max, "EP: OVERFLOW");
		require(sa.balance1 <= type(uint112).max, "EP: OVERFLOW");
		// solhint-disable-next-line not-rely-on-time
		uint32 blockTimestamp = uint32(block.timestamp);
		if (sa.reserve1 != 0)
		{
			if (sa.reserve0 != 0)
			{	
				uint32 timeElapsed = MathUInt32.unsafeSub32(blockTimestamp, _blockTimestampLast); // overflow is desired
				if (timeElapsed > 0)
				{	
					// * never overflows, and + overflow is desired
					unchecked
					{
						_price0CumulativeLast += (UQ144x112.uqdiv(UQ144x112.encode(sa.reserve1),sa.reserve0) * timeElapsed);
						_price1CumulativeLast += (UQ144x112.uqdiv(UQ144x112.encode(sa.reserve0), sa.reserve1) * timeElapsed);
					}
				}
			}
		}
		_reserve0 = uint112(sa.balance0);
		_reserve1 = uint112(sa.balance1);
		_blockTimestampLast = blockTimestamp;
		emit Sync(_reserve0, _reserve1);
	}

	function _getInAmounts(uint256 amount0Out, uint256 amount1Out, SwapAmount memory sa)
		private pure returns(uint256, uint256)
	{
		uint256 div0 = MathUInt256.unsafeSub(sa.reserve0, amount0Out);
		uint256 div1 = MathUInt256.unsafeSub(sa.reserve1, amount1Out);
		return (sa.balance0 > div0 ? MathUInt256.unsafeSub(sa.balance0, div0) : 0, sa.balance1 > div1 ? MathUInt256.unsafeSub(sa.balance1, div1) : 0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/token/ERC20/IERC20.sol";
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
library SafeERC20
{
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal
    {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal
    {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal
    {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: exploitable approve");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal
    {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal
    {
        unchecked
        {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: reduced allowance <0");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0)
        {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 call failed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExofiswapCallee
{
    function exofiswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "./IExofiswapFactory.sol";
import "./IExofiswapPair.sol";
import "./IMigrator.sol";

interface IExofiswapFactory is IOwnable
{
	event PairCreated(IERC20Metadata indexed token0, IERC20Metadata indexed token1, IExofiswapPair pair, uint256 pairCount);

	function createPair(IERC20Metadata tokenA, IERC20Metadata tokenB) external returns (IExofiswapPair pair);
	function setFeeTo(address) external;
	function setMigrator(IMigrator) external;
	
	function allPairs(uint256 index) external view returns (IExofiswapPair);
	function allPairsLength() external view returns (uint);
	function feeTo() external view returns (address);
	function getPair(IERC20Metadata tokenA, IERC20Metadata tokenB) external view returns (IExofiswapPair);
	function migrator() external view returns (IMigrator);

	function pairCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExofiswapCallee.sol";
import "./IExofiswapERC20.sol";
import "./IExofiswapFactory.sol";

interface IExofiswapPair is IExofiswapERC20
{
	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
	event Sync(uint112 reserve0, uint112 reserve1);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);
	function initialize(IERC20Metadata token0Init, IERC20Metadata token1Init) external;
	function mint(address to) external returns (uint256 liquidity);
	function skim(address to) external;
	function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
	function sync() external;

	function factory() external view returns (IExofiswapFactory);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function kLast() external view returns (uint256);
	function price0CumulativeLast() external view returns (uint256);
	function price1CumulativeLast() external view returns (uint256);
	function token0() external view returns (IERC20Metadata);
	function token1() external view returns (IERC20Metadata);

	function MINIMUM_LIQUIDITY() external pure returns (uint256); //solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMigrator
{
	// Return the desired amount of liquidity token that the migrator wants.
	function desiredLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MathUInt32
{
	function unsafeSub32(uint32 a, uint32 b) internal pure returns (uint32)
	{
		unchecked
		{
			return a - b;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library MathUInt256
{
	function min(uint256 a, uint256 b) internal pure returns(uint256)
	{
		return a > b ? b : a;
	}

	// solhint-disable-next-line code-complexity
	function sqrt(uint256 x) internal pure returns (uint256)
	{
		if (x == 0)
		{
			return 0;
		}

		// Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
		uint256 xAux = x;
		uint256 result = 1;
		if (xAux >= 0x100000000000000000000000000000000)
		{
			xAux >>= 128;
			result <<= 64;
		}
		if (xAux >= 0x10000000000000000)
		{
			xAux >>= 64;
			result <<= 32;
		}
		if (xAux >= 0x100000000)
		{
			xAux >>= 32;
			result <<= 16;
		}
		if (xAux >= 0x10000)
		{
			xAux >>= 16;
			result <<= 8;
		}
		if (xAux >= 0x100)
		{
			xAux >>= 8;
			result <<= 4;
		}
		if (xAux >= 0x10)
		{
			xAux >>= 4;
			result <<= 2;
		}
		if (xAux >= 0x4)
		{
			result <<= 1;
		}

		// The operations can never overflow because the result is max 2^127 when it enters this block.
		unchecked
		{
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1;
			result = (result + x / result) >> 1; // Seven iterations should be enough
			uint256 roundedDownResult = x / result;
			return result >= roundedDownResult ? roundedDownResult : result;
		}
	}

	function unsafeDec(uint256 a) internal pure returns (uint256)
	{
		unchecked 
		{
			return a - 1;
		}
	}

	function unsafeDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a / b;
		}
	}

	function unsafeInc(uint256 a) internal pure returns (uint256)
	{
		unchecked 
		{
			return a + 1;
		}
	}

	function unsafeMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a * b;
		}
	}

	function unsafeSub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		unchecked
		{
			return a - b;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**144 - 1]
// resolution: 1 / 2**112

library UQ144x112
{
	uint256 private constant _Q112 = 2**112;

	// encode a uint112 as a UQ144x112
	function encode(uint112 y) internal pure returns (uint256)
	{
		unchecked
		{
			return uint256(y) * _Q112; // never overflows
		}
	}

	// divide a UQ144x112 by a uint112, returning a UQ144x112
    function uqdiv(uint256 x, uint112 y) internal pure returns (uint256)
	{
        return x / uint256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address
{
    /* solhint-disable max-line-length */
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
     /* solhint-enable max-line-length */
    function functionCall(address target, bytes memory data) internal returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0, "Address: call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory)
    {
        return functionCallWithValue(target, data, value, "Address: call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory)
    {
        require(address(this).balance >= value, "Address: balance to low for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

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
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory)
    {
        if (success)
        {
            return returndata;
        } else
        {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly
                {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
            else
            {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Ownable interface.
/// @author Ing. Michael Goldfinger
/// @notice This interface contains all visible functions and events for the Ownable contract module.
interface IOwnable
{
	/// @notice Emitted when ownership is moved from one address to another.
	/// @param previousOwner (indexed) The owner of the contract until now.
	/// @param newOwner (indexed) The new owner of the contract.
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @notice Leaves the contract without an owner. It will not be possible to call {onlyOwner} functions anymore.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 *
	 * Emits an [`OwnershipTransferred`](#ownershiptransferred) event indicating the renounced ownership.
	 *
	 * Requirements:
	 * - Can only be called by the current owner.
	 * 
	 * @dev Sets the zero address as the new contract owner.
	 */
	function renounceOwnership() external;

	/**
	 * @notice Transfers ownership of the contract to a new address.
	 *
	 * Emits an [`OwnershipTransferred`](#ownershiptransferred) event indicating the transfered ownership.
	 *
	 * Requirements:
	 * - Can only be called by the current owner.
	 *
	 * @param newOwner The new owner of the contract.
	 */
	function transferOwnership(address newOwner) external;

	/// @notice Returns the current owner.
	/// @return The current owner.
	function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "./MathUInt256.sol";
import "../interfaces/IExofiswapPair.sol";

library ExofiswapLibrary
{
	function safeTransferETH(address to, uint256 value) internal
	{
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "ER: ETH transfer failed");
	}

	// performs chained getAmountIn calculations on any number of pairs
	function getAmountsIn(IExofiswapFactory factory, uint256 amountOut, IERC20Metadata[] memory path)
	internal view returns (uint256[] memory amounts)
	{
		// can not underflow since path.length >= 2;
		uint256 j = path.length;
		require(j >= 2, "EL: INVALID_PATH");
		amounts = new uint256[](j);
		j = MathUInt256.unsafeDec(j);
		amounts[j] = amountOut;
		for (uint256 i = j; i > 0; i = j)
		{
			j = MathUInt256.unsafeDec(j);
			(uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[j], path[i]);
			amounts[j] = getAmountIn(amounts[i], reserveIn, reserveOut);
		}
	}

	// performs chained getAmountOut calculations on any number of pairs
	function getAmountsOut(IExofiswapFactory factory, uint256 amountIn, IERC20Metadata[] memory path)
	internal view returns (uint256[] memory amounts)
	{
		require(path.length >= 2, "EL: INVALID_PATH");
		amounts = new uint256[](path.length);
		amounts[0] = amountIn;
		// can not underflow since path.length >= 2;
		uint256 to = MathUInt256.unsafeDec(path.length);
		uint256 j;
		for (uint256 i; i < to; i = j)
		{
			j = MathUInt256.unsafeInc(i);
			(uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[j]);
			amounts[j] = getAmountOut(amounts[i], reserveIn, reserveOut);
		}
	}

	function getReserves(IExofiswapFactory factory, IERC20Metadata token0, IERC20Metadata token1) internal view returns (uint256, uint256)
	{
		(IERC20Metadata tokenL,) = sortTokens(token0, token1);
		(uint reserve0, uint reserve1,) = pairFor(factory, token0, token1).getReserves();
		return tokenL == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// calculates the CREATE2 address. It uses the factory for this since Factory already has the Pair contract included.
	// Otherwise this library would add the size of the Pair Contract to every contract using this function.
	function pairFor(IExofiswapFactory factory, IERC20Metadata token0, IERC20Metadata token1) internal pure returns (IExofiswapPair) {
		
		(IERC20Metadata tokenL, IERC20Metadata tokenR) = token0 < token1 ? (token0, token1) : (token1, token0);
		return IExofiswapPair(address(uint160(uint256(keccak256(abi.encodePacked(
				hex'ff', // CREATE2
				address(factory), // sender
				keccak256(abi.encodePacked(tokenL, tokenR)), // salt
				hex'3a547d6893e3ea827cc055d253d297b5f0386ebdfaf0cf83bb6693857d2c6485' // init code hash keccak256(type(ExofiswapPair).creationCode);
			))))));
	}

	// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint amountIn)
	{
		require(amountOut > 0, "EL: INSUFFICIENT_OUTPUT_AMOUNT");
		require(reserveIn > 0 && reserveOut > 0, "EL: INSUFFICIENT_LIQUIDITY");
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		// Div of uint can not overflow
		// numerator is calulated in a way that if no overflow happens it is impossible to be type(uint256).max.
		// The most simple explanation is that * 1000 is a multiplikation with an even number so the result hast to be even to.
		// since type(uint256).max is uneven the result has to be smaler than type(uint256).max or an overflow would have occured.
		return MathUInt256.unsafeInc(MathUInt256.unsafeDiv(numerator, denominator));
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256)
	{
		require(amountIn > 0, "EL: INSUFFICIENT_INPUT_AMOUNT");
		require(reserveIn > 0, "EL: INSUFFICIENT_LIQUIDITY");
		require(reserveOut > 0, "EL: INSUFFICIENT_LIQUIDITY");
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = (reserveIn * 1000) + amountInWithFee;
		// Div of uint can not overflow
		return MathUInt256.unsafeDiv(numerator, denominator);
	}

	// given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
	function quote(uint256 amount, uint256 reserve0, uint256 reserve1) internal pure returns (uint256) {
		require(amount > 0, "EL: INSUFFICIENT_AMOUNT");
		require(reserve0 > 0, "EL: INSUFFICIENT_LIQUIDITY");
		require(reserve1 > 0, "EL: INSUFFICIENT_LIQUIDITY");
		// Division with uint can not overflow.
		return MathUInt256.unsafeDiv(amount * reserve1, reserve0);
	}

	// returns sorted token addresses, used to handle return values from pairs sorted in this order
	function sortTokens(IERC20Metadata token0, IERC20Metadata token1) internal pure returns (IERC20Metadata tokenL, IERC20Metadata tokenR)
	{
		require(token0 != token1, "EL: IDENTICAL_ADDRESSES");
		(tokenL, tokenR) = token0 < token1 ? (token0, token1) : (token1, token0);
		require(address(tokenL) != address(0), "EL: ZERO_ADDRESS");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";
import "@exoda/contracts/utils/Context.sol";
import "./libraries/ExofiswapLibrary.sol";
import "./libraries/MathUInt256.sol";
import "./interfaces/IExofiswapFactory.sol";
import "./interfaces/IExofiswapPair.sol";
import "./interfaces/IExofiswapRouter.sol";
import "./interfaces/IWETH9.sol";

contract ExofiswapRouter is IExofiswapRouter, Context
{
	IExofiswapFactory private immutable _swapFactory;
	IWETH9 private immutable _wrappedEth;

	modifier ensure(uint256 deadline) {
		require(deadline >= block.timestamp, "ER: EXPIRED"); // solhint-disable-line not-rely-on-time
		_;
	}

	constructor(IExofiswapFactory swapFactory, IWETH9 wrappedEth)
	{
		_swapFactory = swapFactory;
		_wrappedEth = wrappedEth;
	}

	receive() override external payable
	{
		assert(_msgSender() == address(_wrappedEth)); // only accept ETH via fallback from the WETH contract
	}

	function addLiquidityETH(
		IERC20Metadata token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) override external virtual payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
	{
		IExofiswapPair pair;
		(amountToken, amountETH, pair) = _addLiquidity(
			token,
			_wrappedEth,
			amountTokenDesired,
			msg.value,
			amountTokenMin,
			amountETHMin
		);
		SafeERC20.safeTransferFrom(token, _msgSender(), address(pair), amountToken);
		_wrappedEth.deposit{value: amountETH}();
		assert(_wrappedEth.transfer(address(pair), amountETH));
		liquidity = pair.mint(to);
		// refund dust eth, if any
		if (msg.value > amountETH) ExofiswapLibrary.safeTransferETH(_msgSender(), MathUInt256.unsafeSub(msg.value, amountETH));
	}

	function addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity)
	{
		IExofiswapPair pair;
		(amountA, amountB, pair) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
		_safeTransferFrom(tokenA, tokenB, address(pair), amountA, amountB);
		liquidity = pair.mint(to);
	}

	function removeLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external virtual override ensure(deadline) returns (uint256, uint256)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, tokenA, tokenB);
		return _removeLiquidity(pair, tokenB < tokenA, liquidity, amountAMin, amountBMin, to);
	}

	function removeLiquidityETH(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256 amountToken, uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		(amountToken, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, amountToken);
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline) returns (uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		(, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHWithPermit(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external override virtual returns (uint256 amountToken, uint256 amountETH)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
		{
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
		}
		(amountToken, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		SafeERC20.safeTransfer(token, to, amountToken);
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) override external virtual returns (uint256 amountETH)
	{
		{
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, token, _wrappedEth);
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
			(, amountETH) = _removeLiquidity(pair, _wrappedEth < token, liquidity, amountTokenMin, amountETHMin, address(this));
		}
		SafeERC20.safeTransfer(token, to, token.balanceOf(address(this)));
		_wrappedEth.withdraw(amountETH);
		ExofiswapLibrary.safeTransferETH(to, amountETH);
	}

	function removeLiquidityWithPermit(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax, uint8 v, bytes32 r, bytes32 s
	) external override virtual returns (uint256 amountA, uint256 amountB)
	{
		IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, tokenA, tokenB);
		{
			uint256 value = approveMax ? type(uint256).max : liquidity;
			pair.permit(_msgSender(), address(this), value, deadline, v, r, s); // ensure(deadline) happens here
		}
		(amountA, amountB) = _removeLiquidity(pair, tokenB < tokenA, liquidity, amountAMin, amountBMin, to);
	}

	function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		require(path[lastItem] == _wrappedEth, "ER: INVALID_PATH"); // Overflow on lastItem will flail here to
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
		require(amounts[amounts.length - 1] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]);
		_swap(amounts, path, address(this));
		// Lenght of amounts array must be equal to length of path array.
		_wrappedEth.withdraw(amounts[lastItem]);
		ExofiswapLibrary.safeTransferETH(to, amounts[lastItem]);
	}

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline)
	{
		require(path[MathUInt256.unsafeDec(path.length)] == _wrappedEth, "ER: INVALID_PATH");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn);
		_swapSupportingFeeOnTransferTokens(path, address(this));
		uint256 amountOut = _wrappedEth.balanceOf(address(this));
		require(amountOut >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		_wrappedEth.withdraw(amountOut);
		ExofiswapLibrary.safeTransferETH(to, amountOut);
	}

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
		require(amounts[MathUInt256.unsafeDec(amounts.length)] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]);
		_swap(amounts, path, to);
	}

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual ensure(deadline)
	{
		SafeERC20.safeTransferFrom(path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn);
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		uint256 balanceBefore = path[lastItem].balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require((path[lastItem].balanceOf(to) - balanceBefore) >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
	}

	function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, IERC20Metadata[] calldata path, address to, uint256 deadline) override
		external virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		require(path[lastItem] == _wrappedEth, "ER: INVALID_PATH"); // Overflow on lastItem will fail here too
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= amountInMax, "ER: EXCESSIVE_INPUT_AMOUNT");
		SafeERC20.safeTransferFrom(
			path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]
		);
		_swap(amounts, path, address(this));
		// amounts and path must have the same item count...
		_wrappedEth.withdraw(amounts[lastItem]);
		ExofiswapLibrary.safeTransferETH(to, amounts[lastItem]);
	}

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external override virtual ensure(deadline) returns (uint256[] memory amounts)
	{
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= amountInMax, "ER: EXCESSIVE_INPUT_AMOUNT");
		SafeERC20.safeTransferFrom(
			path[0], _msgSender(), address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]
		);
		_swap(amounts, path, to);
	}

	function swapETHForExactTokens(uint256 amountOut, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual payable ensure(deadline) returns (uint256[] memory amounts)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		amounts = ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
		require(amounts[0] <= msg.value, "ER: EXCESSIVE_INPUT_AMOUNT");
		_wrappedEth.deposit{value: amounts[0]}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]));
		_swap(amounts, path, to);
		// refund dust eth, if any
		if (msg.value > amounts[0]) ExofiswapLibrary.safeTransferETH(_msgSender(), msg.value - amounts[0]);
	}

	function swapExactETHForTokens(uint256 amountOutMin, IERC20Metadata[] calldata path, address to, uint256 deadline)
		override external virtual payable ensure(deadline) returns (uint[] memory amounts)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		amounts = ExofiswapLibrary.getAmountsOut(_swapFactory, msg.value, path);
		require(amounts[MathUInt256.unsafeDec(amounts.length)] >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
		_wrappedEth.deposit{value: amounts[0]}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amounts[0]));
		_swap(amounts, path, to);
	}

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) override external virtual payable ensure(deadline)
	{
		require(path[0] == _wrappedEth, "ER: INVALID_PATH");
		uint256 amountIn = msg.value;
		_wrappedEth.deposit{value: amountIn}();
		assert(_wrappedEth.transfer(address(ExofiswapLibrary.pairFor(_swapFactory, path[0], path[1])), amountIn));
		uint256 lastItem = MathUInt256.unsafeDec(path.length);
		uint256 balanceBefore = path[lastItem].balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require(path[lastItem].balanceOf(to) - balanceBefore >= amountOutMin, "ER: INSUFFICIENT_OUTPUT_AMOUNT");
	}

	function factory() override external view returns (IExofiswapFactory)
	{
		return _swapFactory;
	}

	function getAmountsIn(uint256 amountOut, IERC20Metadata[] memory path) override
		public view virtual returns (uint[] memory amounts)
	{
		return ExofiswapLibrary.getAmountsIn(_swapFactory, amountOut, path);
	}

	// solhint-disable-next-line func-name-mixedcase
	function WETH() override public view returns(IERC20Metadata)
	{
		return _wrappedEth;
	}

	function getAmountsOut(uint256 amountIn, IERC20Metadata[] memory path) override
		public view virtual returns (uint256[] memory amounts)
	{
		return ExofiswapLibrary.getAmountsOut(_swapFactory, amountIn, path);
	}

	function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) override
		public pure virtual returns (uint256 amountIn)
	{
		return ExofiswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
	}

	function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) override
		public pure virtual returns (uint256)
	{
		return ExofiswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
	}

	function quote(uint256 amount, uint256 reserve0, uint256 reserve1) override public pure virtual returns (uint256)
	{
		return ExofiswapLibrary.quote(amount, reserve0, reserve1);
	}

	function _addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin
	) private returns (uint256, uint256, IExofiswapPair)
	{
		// create the pair if it doesn't exist yet
		IExofiswapPair pair = _swapFactory.getPair(tokenA, tokenB);
		if (address(pair) == address(0))
		{
			pair = _swapFactory.createPair(tokenA, tokenB);
		}
		(uint256 reserveA, uint256 reserveB, ) = pair.getReserves();
		if (reserveA == 0 && reserveB == 0)
		{
			return (amountADesired, amountBDesired, pair);
		}
		if(pair.token0() == tokenB)
		{
			(reserveB, reserveA) = (reserveA, reserveB);
		}
		uint256 amountBOptimal = ExofiswapLibrary.quote(amountADesired, reserveA, reserveB);
		if (amountBOptimal <= amountBDesired)
		{
			require(amountBOptimal >= amountBMin, "ER: INSUFFICIENT_B_AMOUNT");
			return (amountADesired, amountBOptimal, pair);
		}
		uint256 amountAOptimal = ExofiswapLibrary.quote(amountBDesired, reserveB, reserveA);
		assert(amountAOptimal <= amountADesired);
		require(amountAOptimal >= amountAMin, "ER: INSUFFICIENT_A_AMOUNT");
		return (amountAOptimal, amountBDesired, pair);
	}

	function _removeLiquidity(
	IExofiswapPair pair,
	bool reverse,
	uint256 liquidity,
	uint256 amountAMin,
	uint256 amountBMin,
	address to
	) private returns (uint256 amountA, uint256 amountB)
	{
		pair.transferFrom(_msgSender(), address(pair), liquidity); // send liquidity to pair
		(amountA, amountB) = pair.burn(to);
		if(reverse)
		{
			(amountA, amountB) = (amountB, amountA);
		}
		require(amountA >= amountAMin, "ER: INSUFFICIENT_A_AMOUNT");
		require(amountB >= amountBMin, "ER: INSUFFICIENT_B_AMOUNT");
	}

	function _safeTransferFrom(IERC20Metadata tokenA, IERC20Metadata tokenB, address pair, uint256 amountA, uint256 amountB) private
	{
		address sender = _msgSender();
		SafeERC20.safeTransferFrom(tokenA, sender, pair, amountA);
		SafeERC20.safeTransferFrom(tokenB, sender, pair, amountB);
	}

	// requires the initial amount to have already been sent to the first pair
	function _swap(uint256[] memory amounts, IERC20Metadata[] memory path, address to) private
	{
		// TODO: Optimize for Gas. Still higher than Uniswap....maybe get all pairs from factory at once helps....
		uint256 pathLengthSubTwo = MathUInt256.unsafeSub(path.length, 2);
		uint256 j;
		uint256 i;
		while (i < pathLengthSubTwo)
		{
			j = MathUInt256.unsafeInc(i);
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
			(uint256 amount0Out, uint256 amount1Out) = path[i] == pair.token0() ? (uint256(0), amounts[j]) : (amounts[j], uint256(0));
			pair.swap(amount0Out, amount1Out, address(ExofiswapLibrary.pairFor(_swapFactory, path[j], path[MathUInt256.unsafeInc(j)])), new bytes(0));
			i = j;
		}
		j = MathUInt256.unsafeInc(i);
		IExofiswapPair pair2 = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
		(uint256 amount0Out2, uint256 amount1Out2) = path[i] == pair2.token0() ? (uint256(0), amounts[j]) : (amounts[j], uint256(0));
		pair2.swap(amount0Out2, amount1Out2, to, new bytes(0));
	}

	function _swapSupportingFeeOnTransferTokens(IERC20Metadata[] memory path, address to) private
	{
		uint256 pathLengthSubTwo = MathUInt256.unsafeSub(path.length, 2);
		uint256 j;
		uint256 i;
		while (i < pathLengthSubTwo)
		{
			j = MathUInt256.unsafeInc(i);
			IExofiswapPair pair = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
			uint256 amountInput;
			uint256 amountOutput;
			IERC20Metadata token0 = pair.token0();
			{ // scope to avoid stack too deep errors
				(uint256 reserveInput, uint256 reserveOutput,) = pair.getReserves();
				if (path[j] == token0)
				{
					(reserveInput, reserveOutput) = (reserveOutput, reserveInput);
				}
				amountInput = (path[i].balanceOf(address(pair)) - reserveInput);
				amountOutput = ExofiswapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
			}
			(uint256 amount0Out, uint256 amount1Out) = path[i] == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
			address receiver = address(ExofiswapLibrary.pairFor(_swapFactory, path[j], path[MathUInt256.unsafeInc(j)]));
			pair.swap(amount0Out, amount1Out, receiver, new bytes(0));
			i = j;
		}
		j = MathUInt256.unsafeInc(i);
		IExofiswapPair pair2 = ExofiswapLibrary.pairFor(_swapFactory, path[i], path[j]);
		uint256 amountInput2;
		uint256 amountOutput2;
		IERC20Metadata token02 = pair2.token0();
		{ // scope to avoid stack too deep errors
			(uint256 reserveInput, uint256 reserveOutput,) = pair2.getReserves();
			if (path[j] == token02)
			{
				(reserveInput, reserveOutput) = (reserveOutput, reserveInput);
			}
			amountInput2 = (path[i].balanceOf(address(pair2)) - reserveInput);
			amountOutput2 = ExofiswapLibrary.getAmountOut(amountInput2, reserveInput, reserveOutput);
		}
		(uint256 amount0Out2, uint256 amount1Out2) = path[i] == token02? (uint256(0), amountOutput2) : (amountOutput2, uint256(0));
		pair2.swap(amount0Out2, amount1Out2, to, new bytes(0));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "./IExofiswapFactory.sol";

interface IExofiswapRouter {
	receive() external payable;

	function addLiquidityETH(
		IERC20Metadata token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

	function addLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

	function removeLiquidity(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityETHSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermit(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		IERC20Metadata token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function removeLiquidityWithPermit(
		IERC20Metadata tokenA,
		IERC20Metadata tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function swapETHForExactTokens(
		uint256 amountOut,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		IERC20Metadata[] calldata path,
		address to,
		uint256 deadline
	) external payable;

		function factory() external view returns (IExofiswapFactory);

	function getAmountsIn(uint256 amountOut, IERC20Metadata[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function WETH() external view returns (IERC20Metadata); // solhint-disable-line func-name-mixedcase

	function getAmountsOut(uint256 amountIn, IERC20Metadata[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256);

	function quote(
		uint256 amount,
		uint256 reserve0,
		uint256 reserve1
	) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata
{
	event Deposit(address indexed from, uint256 value);
	event Withdraw(address indexed to, uint256 value);
	
	function deposit() external payable;
	function withdraw(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20AltApprove.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Burnable.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the Fermion token.
 */
interface IFermion is IOwnable, IERC20AltApprove, IERC20Metadata, IERC20Burnable
{
	/**
	* @dev Mints `amount` tokens to `account`.
	*
	* Emits a {Transfer} event with `from` set to the zero address.
	*/
	function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @title ERC20Burnable interface.
 * @author Ing. Michael Goldfinger
 * @notice Interface for the extension of {ERC20} that allows token holders to destroy both their own tokens
 * and those that they have an allowance for.
 */
interface IERC20Burnable is IERC20
{
	/**
	* @notice Destroys {amount} tokens from the caller.
	*
	* Emits an {Transfer} event.
	*
	* @param amount The {amount} of tokens that should be destroyed.
	*/
	function burn(uint256 amount) external;

	/**
	* @notice Destroys {amount} tokens from {account}, deducting from the caller's allowance.
	*
	* Emits an {Approval} and an {Transfer} event.
	*
	* @param account The {account} where the tokens should be destroyed.
	* @param amount The {amount} of tokens that should be destroyed.
	*/
	function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";
import "./IFermion.sol";
import "./IMigratorDevice.sol";
import "./IMagneticFieldGeneratorStore.sol";

interface IMagneticFieldGenerator
{
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event Harvest(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
	event LogSetPool(uint256 indexed pid, uint256 allocPoint);
	event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accFermionPerShare);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// WARNING DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param lpToken Address of the LP ERC-20 token.
	/// @param lockPeriod Number of Blocks the pool should disallow withdraws of all kind.
	function add(uint256 allocPoint, IERC20 lpToken, uint256 lockPeriod) external;
	function deposit(uint256 pid, uint256 amount, address to) external;
	function disablePool(uint256 pid) external;
	function emergencyWithdraw(uint256 pid, address to) external;
	function handOverToSuccessor(IMagneticFieldGenerator successor) external;
	function harvest(uint256 pid, address to) external;
	function massUpdatePools() external;
	function migrate(uint256 pid) external;
	function renounceOwnership() external;
	function set(uint256 pid, uint256 allocPoint) external;
	function setFermionPerBlock(uint256 fermionPerBlock) external;
	function setMigrator(IMigratorDevice migratorContract) external;
	function setStore(IMagneticFieldGeneratorStore storeContract) external;
	function transferOwnership(address newOwner) external;
	function updatePool(uint256 pid) external returns(PoolInfo memory);
	function withdraw(uint256 pid, uint256 amount, address to) external;
	function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

	function getFermionContract() external view returns (IFermion);
	function getFermionPerBlock() external view returns (uint256);
	function getStartBlock() external view returns (uint256);
	function migrator() external view returns(IMigratorDevice);
	function owner() external view returns (address);
	function pendingFermion(uint256 pid, address user) external view returns (uint256);
	function poolInfo(uint256 pid) external view returns (PoolInfo memory);
	function poolLength() external view returns (uint256);
	function successor() external view returns (IMagneticFieldGenerator);
	function totalAllocPoint() external view returns (uint256);
	function userInfo(uint256 pid, address user) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";

interface IMigratorDevice
{
	// Perform LP token migration from legacy UniswapV2 to Exofi.
	// Take the current LP token address and return the new LP token address.
	// Migrator should have full access to the caller's LP token.
	// Return the new LP token address.
	//
	// XXX Migrator must have allowance access to UniswapV2 LP tokens.
	// Exofi must mint EXACTLY the same amount of ENERGY tokens or
	// else something bad will happen. Traditional UniswapV2 does not
	// do that so be careful!
	function migrate(IERC20 token) external returns (address);

	function beneficiary() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "../structs/PoolInfo.sol";
import "../structs/UserInfo.sol";

interface IMagneticFieldGeneratorStore is IOwnable
{
	function deletePoolInfo(uint256 pid) external;
	function newPoolInfo(PoolInfo memory pi) external;
	function updateUserInfo(uint256 pid, address user, UserInfo memory ui) external;
	function updatePoolInfo(uint256 pid, PoolInfo memory pi) external;
	function getPoolInfo(uint256 pid) external view returns (PoolInfo memory);
	function getPoolLength() external view returns (uint256);
	function getUserInfo(uint256 pid, address user) external view returns (UserInfo memory);
	
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";

// Info of each pool.
struct PoolInfo
{
	IERC20 lpToken; // Address of LP token contract.
	uint256 allocPoint; // How many allocation points assigned to this pool. FMNs to distribute per block.
	uint256 lastRewardBlock; // Last block number that FMNs distribution occurs.
	uint256 accFermionPerShare; // Accumulated FMNs per share, times _ACC_FERMION_PRECISSION. See below.
	uint256 initialLock; // Block until withdraw from the pool is not possible.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Info of each user.
struct UserInfo
{
	uint256 amount; // How many LP tokens the user has provided.
	int256 rewardDebt; // Reward debt. See explanation below.
	//
	// We do some fancy math here. Basically, any point in time, the amount of FMNs
	// entitled to a user but is pending to be distributed is:
	//
	//   pending reward = (user.amount * pool.accFermionPerShare) - user.rewardDebt
	//
	// Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
	//   1. The pool's `accFermionPerShare` (and `lastRewardBlock`) gets updated.
	//   2. User receives the pending reward sent to his/her address.
	//   3. User's `amount` gets updated.
	//   4. User's `rewardDebt` gets updated.
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@exoda/contracts/access/Ownable.sol";
import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";
import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IMagneticFieldGenerator.sol";

// MagneticFieldGenerator is the master of Fermion. He can make Fermion and he is a fair machine.
contract MagneticFieldGenerator is IMagneticFieldGenerator, Ownable
{
	using SafeERC20 for IERC20;
	
	// Accumulated Fermion Precision
	uint256 private constant _ACC_FERMION_PRECISSION = 1e12;
	// The block number when FMN mining starts.
	uint256 private immutable _startBlock;
	// FMN tokens created per block.
	uint256 private _fermionPerBlock;
	// Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 private _totalAllocPoint; // Initializes with 0
	// The FMN TOKEN!
	IFermion private immutable _fermion;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorDevice private _migrator;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMagneticFieldGenerator private _successor;
	IMagneticFieldGeneratorStore private _store;

	constructor(IFermion fermion, uint256 fermionPerBlock, uint256 startBlock)
	{
		_fermion = fermion;
		_fermionPerBlock = fermionPerBlock;
		_startBlock = startBlock;
	}

	function setStore(IMagneticFieldGeneratorStore storeContract) override external onlyOwner
	{
		_store = storeContract;
	}

	/// @inheritdoc IMagneticFieldGenerator
	function add(uint256 allocPoint, IERC20 lpToken, uint256 lockPeriod) override public onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
		_totalAllocPoint = _totalAllocPoint + allocPoint;
		_store.newPoolInfo(
			PoolInfo({
				lpToken: lpToken,
				allocPoint: allocPoint,
				lastRewardBlock: lastRewardBlock,
				accFermionPerShare: 0,
				initialLock: lockPeriod > 0 ? lastRewardBlock + lockPeriod : 0
			})
		);
		
		emit LogPoolAddition(_unsafeSub(_store.getPoolLength(), 1), allocPoint, lpToken); // Overflow not possible.
	}

	// Deposit LP tokens to MagneticFieldGenerator for FMN allocation.
	function deposit(uint256 pid, uint256 amount, address to) override public
	{
		PoolInfo memory pool = updatePool(pid);
		UserInfo memory user = _store.getUserInfo(pid, to);

		user.amount = user.amount + amount;
		user.rewardDebt += int256(((amount * pool.accFermionPerShare) / _ACC_FERMION_PRECISSION));
		_store.updateUserInfo(pid, to, user); // Save changes

		pool.lpToken.safeTransferFrom(address(_msgSender()), address(this), amount);
		emit Deposit(_msgSender(), pid, amount, to);
	}

	// Update the given pool's FMN allocation point to 0. Can only be called by the owner.
	// This is necessary if a pool reaches a accFermionPerShare overflow.
	function disablePool(uint256 pid) public override onlyOwner
	{
		// Underflow is impossible since _totalAllocPoint can not be lower that _poolInfo[pid].allocPoint.
		PoolInfo memory pi = _store.getPoolInfo(pid);
		_totalAllocPoint = _unsafeSub(_totalAllocPoint, pi.allocPoint);
		pi.allocPoint = 0;
		_store.updatePoolInfo(pid, pi);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 pid, address to) public override
	{
		PoolInfo memory pool = _store.getPoolInfo(pid);
		require(pool.initialLock < block.number, "MFG: pool locked");
		UserInfo memory user = _store.getUserInfo(pid,_msgSender());

		uint256 userAmount = user.amount;
		pool.lpToken.safeTransfer(to, userAmount);
		emit EmergencyWithdraw(_msgSender(), pid, userAmount, to);
		user.amount = 0;
		user.rewardDebt = 0;
		_store.updateUserInfo(pid, _msgSender(), user);
	}

	function handOverToSuccessor(IMagneticFieldGenerator suc) override public onlyOwner
	{
		//TODO: DO ALL participants
		require(address(_successor) == address(0), "MFG: Successor already set");
		require(suc.owner() == address(this), "MFG: Successor not owned by this");
		_successor = suc;
		_fermion.transferOwnership(address(suc));
		_fermion.transfer(address(suc), _fermion.balanceOf(address(this)));
		// Hand over all pools no need for user interaction
		massUpdatePools();
		_store.transferOwnership(address(suc));
		_successor.setStore(_store);

		suc.transferOwnership(owner());
	}

	// Update reward variables for all pools. Be careful of gas spending!
	function massUpdatePools() public override
	{
		// Overflow of pid not possible and need not to be checked.
		unchecked
		{
			uint256 length = _store.getPoolLength();
			for (uint256 pid = 0; pid < length; ++pid)
			{
				updatePool(pid);
			}
		}
	}

	// Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
	function migrate(uint256 pid) override public onlyOwner
	{
		require(address(_migrator) != address(0), "migrate: no migrator");
		PoolInfo memory pool = _store.getPoolInfo(pid);
		IERC20 lpToken = pool.lpToken;
		uint256 bal = lpToken.balanceOf(address(this));
		lpToken.safeApprove(address(_migrator), bal);
		IERC20 newLpToken = IERC20(_migrator.migrate(lpToken));
		require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
		pool.lpToken = newLpToken;
		_store.updatePoolInfo(pid, pool);
	}

	/// @notice Leaves the contract without owner. Can only be called by the current owner.
	function renounceOwnership() public override(Ownable, IMagneticFieldGenerator)
	{
		Ownable.renounceOwnership();
	}

	// Update the given pool's FMN allocation point. Can only be called by the owner.
	function set(uint256 pid, uint256 allocPoint) override public onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		PoolInfo memory pi = _store.getPoolInfo(pid);
		// Underflow is impossible since _totalAllocPoint can not be lower that _poolInfo[pid].allocPoint.
		_totalAllocPoint = _unsafeSub(_totalAllocPoint, pi.allocPoint) + allocPoint;
		pi.allocPoint = allocPoint;
		_store.updatePoolInfo(pid, pi);
		emit LogSetPool(pid, allocPoint);
	}

	function setFermionPerBlock(uint256 fermionPerBlock) override public onlyOwner
	{
		massUpdatePools();
		_fermionPerBlock = fermionPerBlock;
	}

	// Set the migrator contract. Can only be called by the owner.
	function setMigrator(IMigratorDevice migratorContract) override public onlyOwner
	{
		_migrator = migratorContract;
	}

	/// @notice Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
	function transferOwnership(address newOwner) public override(Ownable, IMagneticFieldGenerator)
	{
		Ownable.transferOwnership(newOwner);
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 pid) override public returns(PoolInfo memory)
	{
		PoolInfo memory pool = _store.getPoolInfo(pid);

		if (block.number <= pool.lastRewardBlock)
		{
			return pool;
		}

		uint256 lpSupply = pool.lpToken.balanceOf(address(this));

		if (lpSupply == 0)
		{
			pool.lastRewardBlock = block.number;
			_store.updatePoolInfo(pid, pool);
			return pool;
		}

		uint256 fermionReward = _getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint);
		pool.accFermionPerShare = _getAccFermionPerShare(pool.accFermionPerShare, fermionReward, lpSupply);
		_fermion.mint(address(this), fermionReward);
		pool.lastRewardBlock = block.number;
		_store.updatePoolInfo(pid, pool);
		emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accFermionPerShare);
		return pool;
	}

	// Harvests only Fermion tokens.
	function harvest(uint256 pid, address to) override public
	{
		// HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		// HINT: The owner can set pool allocPoint to 0 without pool reward update. After that all lp tokens can be withdrawn
		// HINT: including the rewards up to the the last sucessful pool reward update.
		PoolInfo memory pool = updatePool(pid);
		UserInfo memory user = _store.getUserInfo(pid, _msgSender());
		
		// Division of uint can not overflow.
		uint256 fermionShare = _unsafeDiv((user.amount *  pool.accFermionPerShare), _ACC_FERMION_PRECISSION);
		uint256 pending = uint256(int256(fermionShare) - user.rewardDebt);
		user.rewardDebt = int256(fermionShare);

		_store.updateUserInfo(pid, _msgSender(), user);
		// THOUGHTS on _safeFermionTransfer(_msgSender(), pending);
		// The intend was that if there is a rounding error and MFG does therefore not hold enouth Fermion,
		// the available amount of Fermion will be used.
		// Since all variables are used in divisions are uint rounding errors can only appear in the form of cut of decimals.
		// if(user.amount == 0 && user.rewardDebt == 0)
		// {
		// 	_poolInfo[pid].participants.remove(_msgSender());
		// }
		_fermion.transfer(to, pending);
		emit Harvest(_msgSender(), pid, pending, to);
	}

	// Withdraw LP tokens from MagneticFieldGenerator.
	function withdraw(uint256 pid, uint256 amount, address to) override public
	{
		// HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		// HINT: The owner can set pool allocPoint to 0 without pool reward update. After that all lp tokens can be withdrawn
		// HINT: including the rewards up to the the last sucessful pool reward update.
		PoolInfo memory pool = updatePool(pid);
		require(pool.initialLock < block.number, "MFG: pool locked");
		UserInfo memory user =  _store.getUserInfo(pid, _msgSender());
		
		uint256 userAmount = user.amount;
		require(userAmount >= amount, "MFG: amount exeeds stored amount");

		uint256 accFermionPerShare = pool.accFermionPerShare;
		// Since we only withdraw rewardDept will be negative.
		user.rewardDebt = user.rewardDebt - int256(_unsafeDiv(amount * accFermionPerShare, _ACC_FERMION_PRECISSION));
		
		// Can not overflow. Checked with require.
		userAmount = _unsafeSub(userAmount, amount);
		user.amount = userAmount;
		_store.updateUserInfo(pid, _msgSender(), user);
		pool.lpToken.safeTransfer(to, amount);
		emit Withdraw(_msgSender(), pid, amount, to);
	}

	// Withdraw LP tokens from MagneticFieldGenerator.
	function withdrawAndHarvest(uint256 pid, uint256 amount, address to) override public
	{
		// HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		// HINT: The owner can set pool allocPoint to 0 without pool reward update. After that all lp tokens can be withdrawn
		// HINT: including the rewards up to the the last sucessful pool reward update.
		PoolInfo memory pool = updatePool(pid);
		require(pool.initialLock < block.number, "MFG: pool locked");
		UserInfo memory user = _store.getUserInfo(pid, _msgSender());
		
		uint256 userAmount = user.amount;
		require(userAmount >= amount, "MFG: amount exeeds stored amount");
		
		uint256 accFermionPerShare = pool.accFermionPerShare;

		// Division of uint can not overflow.
		uint256 pending = uint256(int256(_unsafeDiv((user.amount * accFermionPerShare), _ACC_FERMION_PRECISSION)) - user.rewardDebt);
		_fermion.transfer(to, pending);

		// Can not overflow. Checked with require.
		userAmount = _unsafeSub(userAmount, amount);
		user.amount = userAmount;
		// Division of uint can not overflow.
		user.rewardDebt = int256(_unsafeDiv(userAmount * accFermionPerShare, _ACC_FERMION_PRECISSION));
		_store.updateUserInfo(pid, _msgSender(), user);
		pool.lpToken.safeTransfer(to, amount);
		emit Withdraw(_msgSender(), pid, amount, to);
		emit Harvest(_msgSender(), pid, pending, to);
	}

	function getFermionContract() public override view returns (IFermion)
	{
		return _fermion;
	}

	function getFermionPerBlock() public override view returns (uint256)
	{
		return _fermionPerBlock;
	}

	function getStartBlock() public override view returns (uint256)
	{
		return _startBlock;
	}

	/// @notice Returns the current migrator.
	function migrator() override public view returns(IMigratorDevice)
	{
		return _migrator;
	}

	/// @notice Returns the address of the current owner.
	function owner() public view override(Ownable, IMagneticFieldGenerator) returns (address)
	{
		return Ownable.owner();
	}

	// View function to see pending FMNs on frontend.
	function pendingFermion(uint256 pid, address user) public view override returns (uint256)
	{
		PoolInfo memory pool = _store.getPoolInfo(pid);
		UserInfo memory singleUserInfo = _store.getUserInfo(pid, user);
		uint256 accFermionPerShare = pool.accFermionPerShare;
		uint256 lpSupply = pool.lpToken.balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0)
		{
			accFermionPerShare = _getAccFermionPerShare(
				accFermionPerShare,
				_getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint)
				, lpSupply);
		}
		return uint256(int256(_unsafeDiv((singleUserInfo.amount * accFermionPerShare), _ACC_FERMION_PRECISSION)) - singleUserInfo.rewardDebt);
	}

	function poolInfo(uint256 pid) override public view returns (PoolInfo memory)
	{
		return _store.getPoolInfo(pid);
	}

	function poolLength() override public view returns (uint256)
	{
		return _store.getPoolLength();
	}

	/// @notice Returns the address of the sucessor.
	function successor() override public view returns (IMagneticFieldGenerator)
	{
		return _successor;
	}

	function totalAllocPoint() override public view returns (uint256)
	{
		return _totalAllocPoint;
	}

	function userInfo(uint256 pid, address user) override public view returns (UserInfo memory)
	{
		return _store.getUserInfo(pid, user);
	}

	function _getFermionReward(uint256 multiplier, uint256 allocPoint) private view returns (uint256)
	{
		// As long as the owner chooses sane values for _fermionPerBlock and pool.allocPoint it is unlikely that an overflow ever happens
		// Since _fermionPerBlock and pool.allocPoint are choosen by  the owner, it is the responsibility of the owner to ensure
		// that there is now overflow in multiplying these to values.
		// Divions can not generate an overflow if used with uint values. Div by 0 will always panic, wrapped or not.
		// The only place an overflow can happen (even very unlikeley) is if the multiplier gets big enouth to force an overflow.
		return _unsafeDiv(multiplier * _unsafeMul(_fermionPerBlock, allocPoint), _totalAllocPoint);
	}

	function _getAccFermionPerShare(uint256 currentAccFermionShare, uint256 fermionReward, uint256 lpSupply) private pure returns (uint256)
	{
		// Divions can not generate an overflow if used with uint values. Div by 0 will always panic, wrapped or not.

		// Check for overflow for automatic pool deactivation.
		return currentAccFermionShare + _unsafeDiv(fermionReward * _ACC_FERMION_PRECISSION, lpSupply); 
	}

	// Return reward multiplier over the given _from to _to block.
	function _getMultiplier(uint256 from, uint256 to) private pure returns (uint256)
	{
		unchecked
		{
			return to - from;
		}
	}

	function _unsafeDiv(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a / b;
		}
	}

	function _unsafeMul(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a * b;
		}
	}

	function _unsafeSub(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a - b;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/access/IOwnable.sol";
import "../utils/Context.sol";

/**
 * @title Ownable contract module.
 * @author Ing. Michael Goldfinger
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an address (an owner) that can be granted exclusive access to specific functions.
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with the function {transferOwnership(address newOwner)}".
 * @dev This module is used through inheritance. It will make available the modifier
 * {onlyOwner}, which can be applied to your functions to restrict their use to the owner.
 */
contract Ownable is IOwnable, Context
{
	address private _owner;

	/**
	* @notice Throws if called by any account other than the owner.
	*/
	modifier onlyOwner()
	{
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	/**
	* @notice Initializes the contract setting the deployer as the initial owner.
	* 
	* Emits an {OwnershipTransferred} event indicating the initially set ownership.
	*/
	constructor()
	{
		_transferOwnership(_msgSender());
	}

	/// @inheritdoc IOwnable
	function renounceOwnership() override public virtual onlyOwner 
	{
		_transferOwnership(address(0));
	}

	/// @inheritdoc IOwnable
	function transferOwnership(address newOwner) override public virtual onlyOwner
	{
		require(newOwner != address(0), "Ownable: new owner is address(0)");
		_transferOwnership(newOwner);
	}

	/// @inheritdoc IOwnable
	function owner() public view virtual override returns (address)
	{
		return _owner;
	}

	/**
	* @notice Transfers ownership of the contract to a new address.
	* Internal function without access restriction.
	* 
	* Emits an {OwnershipTransferred} event indicating the transfered ownership.
	*/
	function _transferOwnership(address newOwner) internal virtual
	{
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@exoda/contracts/access/Ownable.sol";
import "./interfaces/IMagneticFieldGeneratorStore.sol";

contract MagneticFieldGeneratorStore is IMagneticFieldGeneratorStore, Ownable
{
	mapping(uint256 => mapping(address => UserInfo)) private _userInfo;
	PoolInfo[] private _poolInfo;

	function newPoolInfo(PoolInfo memory pi) override external onlyOwner
	{
		_poolInfo.push(pi);
	}

	function deletePoolInfo(uint256 pid) override external onlyOwner
	{
		require(_poolInfo[pid].allocPoint == 0, "MFGS: Pool is active");
		_poolInfo[pid] = _poolInfo[_poolInfo.length - 1];
		_poolInfo.pop();
	}

	function updateUserInfo(uint256 pid, address user, UserInfo memory ui) override external onlyOwner
	{
		_userInfo[pid][user] = ui;
	}

	function updatePoolInfo(uint256 pid, PoolInfo memory pi) override external onlyOwner
	{
		_poolInfo[pid] = pi;
	}


	/// @notice Leaves the contract without owner. Can only be called by the current owner.
	/// This is a dangerous call be aware of the consequences
	function renounceOwnership() public override(IOwnable, Ownable)
	{
		Ownable.renounceOwnership();
	}

	/// @notice Returns the address of the current owner.
	function owner() public view override(IOwnable, Ownable) returns (address)
	{
		return Ownable.owner();
	}

	function getPoolInfo(uint256 pid) override external view returns (PoolInfo memory)
	{
		return _poolInfo[pid];
	}

	function getPoolLength() override external view returns (uint256)
	{
		return _poolInfo.length;
	}

	function getUserInfo(uint256 pid, address user) override external view returns (UserInfo memory)
	{
		return _userInfo[pid][user];
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Burnable.sol";
import "./interfaces/IVortexLock.sol";
import "@exoda/contracts/access/Ownable.sol";

contract VortexLock is IVortexLock, Ownable
{
	uint256 private immutable _startBlockPhase1;
	uint256 private immutable _startBlockPhase2;
	uint256 private immutable _startBlockPhase3;
	uint256 private immutable _startBlockPhase4;
	uint256 private immutable _endBlock;
	uint256 private immutable _finalBlock;
	uint256 private _benefitaryCount;
	uint256 private _amountPerBlockPhase1;
	uint256 private _amountPerBlockPhase2;
	uint256 private _amountPerBlockPhase3;
	uint256 private _amountPerBlockPhase4;
	uint256 private _cutOfAmount;
	mapping(address => uint256) private _lastClaimedBlock;
	mapping(address => uint256) private _alreadyClaimedAmount;
	IERC20Burnable private immutable _token;

	constructor(uint256 startBlock, uint256 endBlock, uint256 finalizingBlock, IERC20Burnable token) Ownable()
	{
		// Split the start and end intervall into 4 parts.
		unchecked
		{
			uint256 part = (endBlock - startBlock) / 4;
			_startBlockPhase1 = startBlock;
			_startBlockPhase2 = startBlock + part;
			_startBlockPhase3 = startBlock + (part * 2);
			_startBlockPhase4 = startBlock + (part * 3);
		}
		_endBlock = endBlock;
		_finalBlock = finalizingBlock;
		_token = token;
	}

	function loadToken(uint256 amount) override public onlyOwner
	{
		require(block.number < _startBlockPhase1, "VortexLock: Can only set before start block"); // solhint-disable-line reason-string
		uint256 fraction = (amount * 16) / 15;
		unchecked
		{
			uint256 ph1Blocks = _startBlockPhase2 - _startBlockPhase1;
			uint256 amountPhase1 = fraction / 2;
			_amountPerBlockPhase1 = amountPhase1 / ph1Blocks;
			uint256 cleanAmountP1 = _amountPerBlockPhase1 * ph1Blocks;
			uint256 leftAmount = amountPhase1 - cleanAmountP1;

			uint256 ph2Blocks = _startBlockPhase3 - _startBlockPhase2;
			uint256 amountPhase2 = (fraction / 4) + leftAmount;
			_amountPerBlockPhase2 = amountPhase2 / ph2Blocks;
			uint256 cleanAmountP2 = _amountPerBlockPhase2 * ph2Blocks;
			leftAmount = amountPhase2 - cleanAmountP2;
			
			uint256 ph3Blocks = _startBlockPhase4 - _startBlockPhase3;
			_amountPerBlockPhase3 = ((fraction / 8) + leftAmount) / ph3Blocks;
			uint256 cleanAmountP3 = _amountPerBlockPhase3 * ph3Blocks;

			// Minimize cut of decimal errors.
			_amountPerBlockPhase4 = (amount - (cleanAmountP1 + cleanAmountP2 + cleanAmountP3)) / (_endBlock - _startBlockPhase4);
		}
		uint256 allowance = _token.allowance(owner(), address(this));
		require(allowance == amount, "VortexLock: Allowance must be equal to amount");  // solhint-disable-line reason-string
		_token.transferFrom(owner(), address(this), amount);
	}

	/// @notice Runs the last task after reaching the final block.
	function die() override public
	{
		require(block.number > _finalBlock, "VortexLock: Can only be killed after final block"); // solhint-disable-line reason-string
		uint256 remainingAmount = _token.balanceOf(address(this));
		_token.burn(remainingAmount);
	}

	/// @notice Adds a benefitary as long as the startBlock is not reached.
	function addBeneficiary(address benefitary) override public onlyOwner
	{
		require(block.number < _startBlockPhase1, "VortexLock: Can only added before start block"); // solhint-disable-line reason-string
		_lastClaimedBlock[benefitary] = _startBlockPhase1;
		++_benefitaryCount;
	}

	function claim() override public
	{
		address sender = msg.sender;
		require(_lastClaimedBlock[sender] > 0, "VortexLock: Only benefitaries can claim"); // solhint-disable-line reason-string
		uint256 amount = getClaimableAmount();
		_lastClaimedBlock[sender] = block.number;
		_alreadyClaimedAmount[sender] += amount;
		_token.transfer(sender, amount);
	}

	function getClaimableAmount() override public view returns(uint256)
	{
		uint256 currentBlock = block.number;
		
		if ((currentBlock < _startBlockPhase1) || (currentBlock > _finalBlock))
		{
			return 0; // Not started yet or final Block reached.
		}
		if (_lastClaimedBlock[msg.sender] < _startBlockPhase1)
		{
			return 0; // Not in list
		}

		unchecked
		{
			uint256 ph1Blocks =_max(_min(_startBlockPhase2, currentBlock), _startBlockPhase1) - _startBlockPhase1;
			uint256 ph2Blocks = _max(_min(_startBlockPhase3, currentBlock), _startBlockPhase2) - _startBlockPhase2;
			uint256 ph3Blocks = _max(_min(_startBlockPhase4, currentBlock), _startBlockPhase3) - _startBlockPhase3;
			uint256 ph4Blocks = _max(_min(_endBlock, currentBlock), _startBlockPhase4) - _startBlockPhase4;
			uint256 ret =  (((ph1Blocks * _amountPerBlockPhase1) +
				(ph2Blocks * _amountPerBlockPhase2) +
				(ph3Blocks * _amountPerBlockPhase3) +
				(ph4Blocks * _amountPerBlockPhase4)) / _benefitaryCount) - _alreadyClaimedAmount[msg.sender];
			return ret;
		}
	}

	function _min(uint256 a, uint256 b) private pure returns(uint256)
	{
		return a <= b ? a : b;
	}

	function _max(uint256 a, uint256 b) private pure returns(uint256)
	{
		return a >= b ? a : b;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Burnable.sol";

interface IVortexLock is IOwnable
{
	function loadToken(uint256 amount) external;
	function die() external;
	function addBeneficiary(address benefitary) external;
	function claim() external;
	function getClaimableAmount() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../interfaces/token/ERC20/extensions/IERC20Burnable.sol";
import "../../../utils/Context.sol";

/**
* @notice Extension of {ERC20} that allows token holders to destroy both their own
* tokens and those that they have an allowance for, in a way that can be
* recognized off-chain (via event analysis).
*/
contract ERC20Burnable is Context, ERC20, IERC20Burnable
{
	/**
	* @notice Sets the values for {name} and {symbol}.
	*
	* The default value of {decimals} is 18. To select a different value for
	* {decimals} you should overload it.
	*
	* All two of these values are immutable: they can only be set once during
	* construction.
	*/
	constructor(string memory tokenName, string memory tokenSymbol) ERC20(tokenName, tokenSymbol)
	{} // solhint-disable-line no-empty-blocks

	/**
	* @notice Destroys `amount` tokens from the caller.
	*
	* See {ERC20-_burn}.
	*/
	function burn(uint256 amount) public virtual override
	{
		_burn(_msgSender(), amount);
	}

	/**
	* @notice Destroys `amount` tokens from `account`, deducting from the caller's allowance.
	*
	* See {ERC20-_burn} and {ERC20-allowance}.
	*
	* Requirements:
	* - the caller must have allowance for `account`'s tokens of at least `amount`.
	*/
	function burnFrom(address account, uint256 amount) public virtual override
	{
		_spendAllowance(account, _msgSender(), amount);
		_burn(account, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ERC20BurnableMock is ERC20Burnable
{
	constructor(string memory name, string memory symbol, uint256 supply) ERC20Burnable(name, symbol)
	{
		_mint(msg.sender, supply);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20
{
	constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol)
	{
		_mint(msg.sender, supply);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@exoda/contracts/access/Ownable.sol";
import "./interfaces/IFermion.sol";

/**
* @dev Implementation of the {IFermion} interface.
*/
contract Fermion is Ownable, ERC20Burnable, IFermion
{
	uint256 private constant _MAX_SUPPLY = (1000000000 * (10**18));

	constructor() ERC20Burnable("Fermion", "EXOFI")
	{
		_mint(owner(), (_MAX_SUPPLY * 4) / 10); // 40%
	}

	/// @notice Creates `amount` token to `to`. Must only be called by the owner (MagneticFieldGenerator).
	function mint(address to, uint256 amount) override public onlyOwner
	{
		require(totalSupply() < _MAX_SUPPLY, "Fermion: Max supply reached");
		_mint(to, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "@exoda/contracts/access/Ownable.sol";
import "./interfaces/IExofiswapFactory.sol";
import "./interfaces/IExofiswapPair.sol";
import "./ExofiswapPair.sol";

contract ExofiswapFactory is IExofiswapFactory, Ownable
{
	address private _feeTo;
	IMigrator private _migrator;
	mapping(IERC20Metadata => mapping(IERC20Metadata => IExofiswapPair)) private _getPair;
	IExofiswapPair[] private _allPairs;

	constructor()
	{} // solhint-disable-line no-empty-blocks

	function createPair(IERC20Metadata tokenA, IERC20Metadata tokenB) override public returns (IExofiswapPair)
	{
		require(tokenA != tokenB, "EF: IDENTICAL_ADDRESSES");
		(IERC20Metadata token0, IERC20Metadata token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(address(token0) != address(0), "EF: ZERO_ADDRESS");
		require(address(_getPair[token0][token1]) == address(0), "EF: PAIR_EXISTS"); // single check is sufficient

		bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		IExofiswapPair pair = new ExofiswapPair{salt: salt}(); // Use create2
		pair.initialize(token0, token1);

		_getPair[token0][token1] = pair;
		_getPair[token1][token0] = pair; // populate mapping in the reverse direction
		_allPairs.push(pair);
		emit PairCreated(token0, token1, pair, _allPairs.length);
		return pair;
	}

	function setFeeTo(address newFeeTo) override public onlyOwner
	{
		_feeTo = newFeeTo;
	}

	function setMigrator(IMigrator newMigrator) override public onlyOwner
	{
		_migrator = newMigrator;
	}

	function allPairs(uint256 index) override public view returns (IExofiswapPair)
	{
		return _allPairs[index];
	}

	function allPairsLength() override public view returns (uint256)
	{
		return _allPairs.length;
	}

	function feeTo() override public view returns (address)
	{
		return _feeTo;
	}

	function getPair(IERC20Metadata tokenA, IERC20Metadata tokenB) override public view returns (IExofiswapPair)
	{
		return _getPair[tokenA][tokenB];
	}

	function migrator() override public view returns (IMigrator)
	{
		return _migrator;
	}

	function pairCodeHash() override public pure returns (bytes32)
	{
		return keccak256(type(ExofiswapPair).creationCode);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IMigratorDevice.sol";
import "./FakeERC20.sol";

contract UniMigrator is IMigratorDevice
{
	address private immutable _beneficiary;

	constructor(address beneficiaryAddress)
	{
		_beneficiary = beneficiaryAddress;
	}

	function migrate(IERC20 src) override public returns (address)
	{
		require(address(src) == 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, "UniMigrator: Not uni token");
		uint256 bal = src.balanceOf(msg.sender);
		src.transferFrom(msg.sender, _beneficiary, bal);
		return address(new FakeERC20(bal));
	}

	function beneficiary() override public view returns(address)
	{
		return _beneficiary;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFakeERC20.sol";

contract FakeERC20 is IFakeERC20
{
	uint256 public amount;

	constructor(uint256 initialAmount)
	{
		amount = initialAmount;
	}

	function balanceOf(address) override public view returns (uint256)
	{
		return amount;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFakeERC20
{
	function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IMigratorDevice.sol";
import "../FakeERC20.sol";

contract UniMigratorMock is IMigratorDevice
{
	address private _beneficiary;
	address private _testToken;

	constructor(address beneficiaryAddress, address testToken)
	{
		_beneficiary = beneficiaryAddress;
		_testToken = testToken;
	}

	function migrate(IERC20 src) override public returns (address)
	{
		require(address(src) == _testToken, "UniMigratorMock: Not correct token"); //solhint-disable-line reason-string
		uint256 bal = src.balanceOf(msg.sender);
		src.transferFrom(msg.sender, _beneficiary, bal);
		return address(new FakeERC20(bal));
	}

	function beneficiary() override public view returns(address)
	{
		return _beneficiary;
	}
}