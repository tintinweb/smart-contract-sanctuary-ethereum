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

import "@exoda/contracts/access/Ownable.sol";
import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";
import "@exoda/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IFermionReactor.sol";
import "./interfaces/IFermion.sol";

contract FermionReactor is IFermionReactor, Ownable
{
	uint256 private immutable _lowerLimit;
	uint256 private immutable _upperLimit;
	uint256 private immutable _rate;
	IFermion private immutable _fermion;
	bool private _active;

	constructor(uint256 lowerLimit, uint256 upperLimit, IFermion fermion, uint256 rate) Ownable()
	{
		require(rate > 0, "FR: Rate < 0");
		require(upperLimit > lowerLimit, "FR: upperLimit <= lowerLimit");
		_lowerLimit = lowerLimit;
		_upperLimit = upperLimit;
		_rate = rate;
		_fermion = fermion;
		_active = true;
	}

	function buyFermion() override external payable
	{
		require(_active, "FR: Contract is not active");
		uint256 amountETH = msg.value;
		require(amountETH >= _lowerLimit, "FR: Insufficient ETH");
		require(amountETH <= _upperLimit, "FR: ETH exceeds upper Limit");
		// Get available Fermions
		uint256 fAvailable = _fermion.balanceOf(address(this));
		// Calculate Fermion Amount
		uint256 fAmount = amountETH * _rate;
		// Check if enought Fermions
		if(fAvailable < fAmount)
		{
			unchecked
			{
				// If not enouth use max possible amount of Fermions and refund unused eth
				fAmount = fAvailable;
				amountETH = fAmount / _rate;
				// refund unused eth
				_safeTransferETH(_msgSender(), (msg.value - amountETH));
				_active = false;
			}
		}
		// Transfer ETH to owner
		_safeTransferETH(owner(), amountETH);
		// Transfer Fermions to caller
		SafeERC20.safeTransfer(_fermion, _msgSender(), fAmount);
		emit Buy(_msgSender(), amountETH, fAmount);
	}

	function disable() override external onlyOwner
	{
		_active = false;
		uint256 fAvailable = _fermion.balanceOf(address(this));
		SafeERC20.safeTransfer(_fermion, owner(), fAvailable);
	}

	function transferOtherERC20Token(IERC20 token) override external onlyOwner returns (bool)
	{
		require(token != _fermion, "FR: Fermion can not be removed.");
		return token.transfer(owner(), token.balanceOf(address(this)));
	}

	function getFermionAddress() override external view returns(IFermion)
	{
		return _fermion;
	}

	function getLowerEthLimit() override external view returns(uint256)
	{
		return _lowerLimit;
	}

	function getRate() override external view returns(uint256)
	{
		return _rate;
	}

	function getUpperEthLimit() override external view returns(uint256)
	{
		return _upperLimit;
	}

	function isActive() override external view returns(bool)
	{
		return _active;
	}

	function _safeTransferETH(address to, uint256 value) private
	{
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{value: value}(new bytes(0));
		require(success, "FR: ETH transfer failed");
	}
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

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";

import "./IFermion.sol";
import "./IMagneticFieldGenerator.sol";

interface IFermionReactor is IOwnable
{
	event Buy(address indexed user, uint256 ethAmount, uint256 fermionAmount);

	function buyFermion() external payable;
	
	function disable() external;
	function transferOtherERC20Token(IERC20 token) external returns(bool);

	function getFermionAddress() external view returns(IFermion);
	function getLowerEthLimit() external view returns(uint256);
	function getRate() external view returns(uint256);
	function getUpperEthLimit() external view returns(uint256);
	function isActive() external view returns(bool);
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
	event Migrate(uint256 indexed pid, uint256 balance, IERC20 indexed fromToken, IERC20 indexed toToken);
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