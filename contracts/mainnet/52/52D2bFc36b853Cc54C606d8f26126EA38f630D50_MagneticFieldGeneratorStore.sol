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