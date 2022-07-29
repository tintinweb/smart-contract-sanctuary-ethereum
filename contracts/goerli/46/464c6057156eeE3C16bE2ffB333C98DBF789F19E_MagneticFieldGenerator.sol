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
import "./interfaces/IMagneticFieldGenerator.sol";

// MagneticFieldGenerator is the master of Fermion. He can make Fermion and he is a fair machine.
contract MagneticFieldGenerator is IMagneticFieldGenerator, Ownable
{
	using SafeERC20 for IERC20;
	
	// FMN tokens created per block.
	uint256 private immutable _fermionPerBlock;
	// The FMN TOKEN!
	IFermion private immutable _fermion;
	// The block number when FMN mining starts.
	uint256 private immutable _startBlock;
	// Accumulated Fermion Precision
	uint256 private constant _ACC_FERMION_PRECISSION = 1e12;
	// Info of each pool.
	PoolInfo[] private _poolInfo;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorDevice private _migrator;
	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMagneticFieldGenerator private _successor;
	// Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) private _userInfo;
	// Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 private _totalAllocPoint; // Initializes with 0

	constructor(IFermion fermion, uint256 fermionPerBlock, uint256 startBlock)
	{
		_fermion = fermion;
		_fermionPerBlock = fermionPerBlock;
		_startBlock = startBlock;
	}

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// WARNING DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param lpToken Address of the LP ERC-20 token.
	function add(uint256 allocPoint, IERC20 lpToken) override public onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
		_totalAllocPoint = _totalAllocPoint + allocPoint;
		_poolInfo.push(
			PoolInfo({
				lpToken: lpToken,
				allocPoint: allocPoint,
				lastRewardBlock: lastRewardBlock,
				accFermionPerShare: 0
			})
		);
		emit LogPoolAddition(_poolInfo.length - 1, allocPoint, lpToken);
	}

	// Deposit LP tokens to MagneticFieldGenerator for FMN allocation.
	function deposit(uint256 pid, uint256 amount, address to) override public
	{
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = _userInfo[pid][to];

		user.amount = user.amount + amount;
		user.rewardDebt += int256(((amount * pool.accFermionPerShare) / _ACC_FERMION_PRECISSION));

		pool.lpToken.safeTransferFrom(address(_msgSender()), address(this), amount);
		emit Deposit(_msgSender(), pid, amount, to);
	}

	// Update the given pool's FMN allocation point to 0. Can only be called by the owner.
	// This is necessary if a pool reaches a accFermionPerShare overflow.
	function disablePool(uint256 pid) public override onlyOwner
	{
		// Underflow is impossible since _totalAllocPoint can not be lower that _poolInfo[pid].allocPoint.
		_totalAllocPoint = _unsafeSub(_totalAllocPoint, _poolInfo[pid].allocPoint);
		_poolInfo[pid].allocPoint = 0;
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 pid, address to) public override
	{
		PoolInfo storage pool = _poolInfo[pid];
		UserInfo storage user = _userInfo[pid][_msgSender()];

		uint256 userAmount = user.amount;
		pool.lpToken.safeTransfer(to, userAmount);
		emit EmergencyWithdraw(_msgSender(), pid, userAmount, to);
		user.amount = 0;
		user.rewardDebt = 0;
	}

	function handOverToSuccessor(IMagneticFieldGenerator suc) override public onlyOwner
	{
		require(address(_successor) == address(0), "MFG: Successor already set");
		require(suc.owner() == address(this), "MFG: Successor not owned by this");
		_successor = suc;
		_fermion.transferOwnership(address(suc));
		_fermion.transfer(address(suc), _fermion.balanceOf(address(this)));
		_handOverPools();
		suc.transferOwnership(owner());
	}

	// Update reward variables for all pools. Be careful of gas spending!
	function massUpdatePools() public override
	{
		// Overflow of pid not possible and need not to be checked.
		unchecked
		{
			uint256 length = _poolInfo.length;
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
		PoolInfo storage pool = _poolInfo[pid];
		IERC20 lpToken = pool.lpToken;
		uint256 bal = lpToken.balanceOf(address(this));
		lpToken.safeApprove(address(_migrator), bal);
		IERC20 newLpToken = IERC20(_migrator.migrate(lpToken));
		require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
		pool.lpToken = newLpToken;
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
		// Underflow is impossible since _totalAllocPoint can not be lower that _poolInfo[pid].allocPoint.
		_totalAllocPoint = _unsafeSub(_totalAllocPoint, _poolInfo[pid].allocPoint) + allocPoint;
		_poolInfo[pid].allocPoint = allocPoint;
		emit LogSetPool(pid, allocPoint);
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
		PoolInfo storage pool = _poolInfo[pid];

		if (block.number <= pool.lastRewardBlock)
		{
			return pool;
		}

		uint256 lpSupply = pool.lpToken.balanceOf(address(this));

		if (lpSupply == 0)
		{
			pool.lastRewardBlock = block.number;
			return pool;
		}

		uint256 fermionReward = _getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint);
		pool.accFermionPerShare = _getAccFermionPerShare(pool.accFermionPerShare, fermionReward, lpSupply);
		_fermion.mint(address(this), fermionReward);
		pool.lastRewardBlock = block.number;
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
		UserInfo storage user = _userInfo[pid][_msgSender()];
		
		// Division of uint can not overflow.
		uint256 fermionShare = _unsafeDiv((user.amount *  pool.accFermionPerShare), _ACC_FERMION_PRECISSION);
		uint256 pending = uint256(int256(fermionShare) - user.rewardDebt);
		user.rewardDebt = int256(fermionShare);
		// THOUGHTS on _safeFermionTransfer(_msgSender(), pending);
		// The intend was that if there is a rounding error and MFG does therefore not hold enouth Fermion,
		// the available amount of Fermion will be used.
		// Since all variables are used in divisions are uint rounding errors can only appear in the form of cut of decimals.
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
		UserInfo storage user = _userInfo[pid][_msgSender()];
		
		uint256 userAmount = user.amount;
		require(userAmount >= amount, "MFG: amount exeeds stored amount");

		uint256 accFermionPerShare = pool.accFermionPerShare;
		// Since we only withdraw rewardDept will be negative.
		user.rewardDebt = user.rewardDebt - int256(_unsafeDiv(amount * accFermionPerShare, _ACC_FERMION_PRECISSION));
		
		// Can not overflow. Checked with require.
		userAmount = _unsafeSub(userAmount, amount);
		user.amount = userAmount;
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
		UserInfo storage user = _userInfo[pid][_msgSender()];
		
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
		PoolInfo memory pool = _poolInfo[pid];
		UserInfo storage singleUserInfo = _userInfo[pid][user];
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
		return _poolInfo[pid];
	}

	function poolLength() override public view returns (uint256)
	{
		return _poolInfo.length;
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
		return _userInfo[pid][user];
	}

	function _handOverPools() private
	{
		// Overflow of pid not possible and need not to be checked.
		unchecked
		{
			uint256 length = _poolInfo.length;
			for (uint256 pid = 0; pid < length; ++pid)
			{
				_handOverSinglePool(pid);
			}
		}
	}

	function _handOverSinglePool(uint256 pid) private
	{
		PoolInfo memory pool = updatePool(pid);
		
		if(pool.allocPoint > 0)
		{
			_successor.add(pool.allocPoint , pool.lpToken);
			disablePool(pid);
		}
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

import "@exoda/contracts/interfaces/token/ERC20/IERC20.sol";
import "./IFermion.sol";
import "./IMigratorDevice.sol";

interface IMagneticFieldGenerator
{
	// Info of each pool.
	struct PoolInfo
	{
		IERC20 lpToken; // Address of LP token contract.
		uint256 allocPoint; // How many allocation points assigned to this pool. FMNs to distribute per block.
		uint256 lastRewardBlock; // Last block number that FMNs distribution occurs.
		uint256 accFermionPerShare; // Accumulated FMNs per share, times _ACC_FERMION_PRECISSION. See below.
	}

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

	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event Harvest(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
	event LogSetPool(uint256 indexed pid, uint256 allocPoint);
	event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accFermionPerShare);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);

	function add(uint256 allocPoint, IERC20 lpToken) external;
	function deposit(uint256 pid, uint256 amount, address to) external;
	function disablePool(uint256 pid) external;
	function emergencyWithdraw(uint256 pid, address to) external;
	function handOverToSuccessor(IMagneticFieldGenerator successor) external;
	function harvest(uint256 pid, address to) external;
	function massUpdatePools() external;
	function migrate(uint256 pid) external;
	function renounceOwnership() external;
	function set(uint256 pid, uint256 allocPoint) external;
	function setMigrator(IMigratorDevice migratorContract) external;
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