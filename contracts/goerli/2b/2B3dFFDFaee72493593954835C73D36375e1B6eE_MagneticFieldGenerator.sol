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
abstract contract Ownable is Context, IOwnable
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
	function renounceOwnership() public virtual override onlyOwner
	{
		_transferOwnership(address(0));
	}

	/// @inheritdoc IOwnable
	function transferOwnership(address newOwner) public virtual override onlyOwner
	{
		// solhint-disable-next-line reason-string
		require(newOwner != address(0), "Ownable: new owner is the zero address");
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



// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./cobra/token/ERC20/utils/SafeERC20.sol";
import "./cobra/access/Ownable.sol";
import "./cobra/interfaces/token/ERC20/IERC20.sol";
import "./interfaces/IFermion.sol";
import "./interfaces/IMagneticFieldGenerator.sol";

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
	function migrate(IERC20 token) external returns (IERC20);
}

// MagneticFieldGenerator is the master of Fermion. He can make Fermion and he is a fair machine.
contract MagneticFieldGenerator is IMagneticFieldGenerator, Ownable
{
	using SafeERC20 for IERC20;
	
	// Info of each user.
	struct UserInfo
	{
		uint256 amount; // How many LP tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
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

	// Info of each pool.
	struct PoolInfo
	{
		IERC20 lpToken; // Address of LP token contract.
		uint256 allocPoint; // How many allocation points assigned to this pool. FMNs to distribute per block.
		uint256 lastRewardBlock; // Last block number that FMNs distribution occurs.
		uint256 accFermionPerShare; // Accumulated FMNs per share, times _ACC_FERMION_PRECISSION. See below.
	}

	// Dev address.
	address private _developer;
	// FMN tokens created per block.
	uint256 private _fermionPerBlock;

	// The FMN TOKEN!
	IFermion private immutable _fermion;
	// The block number when FMN mining starts.
	uint256 private immutable _startBlock;
	// Accumulated Fermion Precision
	uint256 private constant _ACC_FERMION_PRECISSION = 1e12;

	// The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorDevice public migrator;
	// Info of each pool.
	PoolInfo[] public poolInfo;
	// Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	// Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint = 0;

	/**
     * @dev Throws if called by any account other than the developer.
     */
    modifier onlyDeveloper()
	{
		// solhint-disable-next-line reason-string
        require(developer() == _msgSender(), "MagneticFieldGenerator: caller is not the developer");
        _;
    }

	constructor(IFermion fermion, address initialDeveloper, uint256 fermionPerBlock, uint256 startBlock)
	{
		_fermion = fermion;
		_developer = initialDeveloper;
		_fermionPerBlock = fermionPerBlock;
		_startBlock = startBlock;
	}

	// Add a new lp to the pool. Can only be called by the owner.
	// WARNING DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	function add(uint256 allocPoint, IERC20 lpToken) public override onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
		totalAllocPoint = totalAllocPoint + allocPoint;
		poolInfo.push(
			PoolInfo({
				lpToken: lpToken,
				allocPoint: allocPoint,
				lastRewardBlock: lastRewardBlock,
				accFermionPerShare: 0
			})
		);
	}

	// Deposit LP tokens to MagneticFieldGenerator for FMN allocation.
	function deposit(uint256 pid, uint256 amount) public override
	{
		PoolInfo storage pool = poolInfo[pid];
		UserInfo storage user = userInfo[pid][msg.sender];

		updatePool(pid);

		uint256 userAmount = user.amount;
		if (userAmount > 0)
		{
			// Divion of uint values can not overflow.
			// _unsafeDiv((user.amount * pool.accFermionPerShare), _ACC_FERMION_PRECISSION) can only be >= user.rewardDebt
			uint256 pending = _unsafeSub(_unsafeDiv((userAmount * pool.accFermionPerShare), _ACC_FERMION_PRECISSION), user.rewardDebt);
			_safeFermionTransfer(msg.sender, pending);
		}

		pool.lpToken.safeTransferFrom(address(msg.sender), address(this), amount);
		
		userAmount = userAmount + amount;
		user.amount = userAmount;
		// This are the rewards the user would have till now since the pool creation.
		// This is a cheap way to get the reward for the user starting at a given time.
		user.rewardDebt = ((userAmount * pool.accFermionPerShare) / _ACC_FERMION_PRECISSION);
		emit Deposit(msg.sender, pid, amount);
	}

	// Update the given pool's FMN allocation point to 0. Can only be called by the owner.
	// This is necessary if a pool reaches a accFermionPerShare overflow.
	function disablePool(uint256 pid) public override onlyOwner
	{
		// Underflow is impossible since totalAllocPoint can not be lower that poolInfo[pid].allocPoint.
		totalAllocPoint = _unsafeSub(totalAllocPoint, poolInfo[pid].allocPoint);
		poolInfo[pid].allocPoint = 0;
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 pid) public override
	{
		PoolInfo storage pool = poolInfo[pid];
		UserInfo storage user = userInfo[pid][msg.sender];

		uint256 userAmount = user.amount;
		pool.lpToken.safeTransfer(address(msg.sender), userAmount);
		emit EmergencyWithdraw(msg.sender, pid, userAmount);
		user.amount = 0;
		user.rewardDebt = 0;
	}

	// Update reward vairables for all pools. Be careful of gas spending!
	function massUpdatePools() public override
	{
		// Overflow of pid not possible and need not to be checked.
		unchecked
		{
			uint256 length = poolInfo.length;
			for (uint256 pid = 0; pid < length; ++pid)
			{
				updatePool(pid);
			}
		}
	}

	/// @notice Leaves the contract without owner. Can only be called by the current owner.
	function renounceOwnership() public override(Ownable, IMagneticFieldGenerator)
	{
		Ownable.renounceOwnership();
	}

	// Update the given pool's FMN allocation point. Can only be called by the owner.
	function set(uint256 pid, uint256 allocPoint) public override onlyOwner
	{
		// Do every time.
		// If a pool prevents massUpdatePools because of accFermionPerShare overflow disable the responsible pool with disablePool.
		massUpdatePools();
		// Underflow is impossible since totalAllocPoint can not be lower that poolInfo[pid].allocPoint.
		totalAllocPoint = _unsafeSub(totalAllocPoint, poolInfo[pid].allocPoint) + allocPoint;
		poolInfo[pid].allocPoint = allocPoint;
	}

	// Update dev address by the previous dev.
	function transferDevelopment(address newDeveloper) public override onlyDeveloper
	{
		// solhint-disable-next-line reason-string
		require(newDeveloper != address(0), "MagneticFieldGenerator: new developer is the zero address");
		_transferDevelopment(newDeveloper);
	}

	/// @notice Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.
	function transferOwnership(address newOwner) public override(Ownable, IMagneticFieldGenerator)
	{
		Ownable.transferOwnership(newOwner);
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 pid) public override
	{
		PoolInfo storage pool = poolInfo[pid];

		if (block.number <= pool.lastRewardBlock)
		{
			return;
		}

		uint256 lpSupply = pool.lpToken.balanceOf(address(this));

		if (lpSupply == 0)
		{
			pool.lastRewardBlock = block.number;
			return;
		}

		uint256 fermionReward = _getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint);
		pool.accFermionPerShare = _getAccFermionPerShare(pool.accFermionPerShare, fermionReward, lpSupply);
		_fermion.mint(_developer, _unsafeDiv(fermionReward, 10)); //TODO: Developer gets Fermion?
		_fermion.mint(address(this), fermionReward);
		pool.lastRewardBlock = block.number;
	}

	// Withdraw LP tokens from MagneticFieldGenerator.
	function withdraw(uint256 pid, uint256 amount) public override
	{
		//HINT: pool.accFermionPerShare can only grow till it overflows, at that point every withdraw will fail.
		//HINT: The owner can set pool allocPoint to 0 without pool reward update. After all lp tokens can be withdrawn
		//HINT: includen the rewards up to the the last sucessful pool reward update.

		PoolInfo storage pool = poolInfo[pid];
		UserInfo storage user = userInfo[pid][msg.sender];
		
		uint256 userAmount = user.amount;
		// solhint-disable-next-line reason-string
		require(userAmount >= amount, "MagneticFieldGenerator: amount exeeds stored amount");
		
		updatePool(pid);

		uint256 accFermionPerShare = pool.accFermionPerShare;
		// user.rewardDept can not be greater than _unsafeDiv((userAmount * pool.accFermionPerShare), _ACC_FERMION_PRECISSION)
		// Division of uint can not overflow.
		uint256 pending = _unsafeSub(_unsafeDiv((userAmount * accFermionPerShare), _ACC_FERMION_PRECISSION), user.rewardDebt);
		_safeFermionTransfer(msg.sender, pending);

		// Can not overflow. Checked with require.
		userAmount = _unsafeSub(userAmount, amount);
		user.amount = userAmount;
		// Division of uint can not overflow.
		user.rewardDebt = _unsafeDiv(userAmount * accFermionPerShare, _ACC_FERMION_PRECISSION);
		pool.lpToken.safeTransfer(address(msg.sender), amount);
		emit Withdraw(msg.sender, pid, amount);
	}

	function developer() public override view returns (address)
	{
		return _developer;
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

	/// @notice Returns the address of the current owner.
	function owner() public view override(Ownable, IMagneticFieldGenerator) returns (address)
	{
		return Ownable.owner();
	}

	// View function to see pending FMNs on frontend.
	function pendingFermion(uint256 pid, address user) public view override returns (uint256)
	{
		PoolInfo storage pool = poolInfo[pid];
		UserInfo storage singleUserInfo = userInfo[pid][user];
		uint256 accFermionPerShare = pool.accFermionPerShare;
		uint256 lpSupply = pool.lpToken.balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0)
		{
			accFermionPerShare = _getAccFermionPerShare(
				accFermionPerShare,
				_getFermionReward(_getMultiplier(pool.lastRewardBlock, block.number), pool.allocPoint)
				, lpSupply);
		}
		return _unsafeDiv((singleUserInfo.amount * accFermionPerShare), _ACC_FERMION_PRECISSION) - singleUserInfo.rewardDebt;
	}

	function poolLength() public override  view returns (uint256)
	{
		return poolInfo.length;
	}

	// Safe Fermion transfer function, just in case if rounding error causes pool to not have enough FMNs.
	function _safeFermionTransfer(address to, uint256 amount) private
	{
		uint256 fermionBal = _fermion.balanceOf(address(this));
		if (amount > fermionBal)
		{
			_fermion.transfer(to, fermionBal);
		}
		else
		{
			_fermion.transfer(to, amount);
		}
	}

	/**
	* @dev Transfers development of the contract to a new account (`newDeveloper`).
	* Internal function without access restriction.
	*/
	function _transferDevelopment(address newDeveloper) private
	{
		address oldDeveloper = _developer;
		_developer = newDeveloper;
		emit DevelopmentTransferred(oldDeveloper, newDeveloper);
	}

	function _getFermionReward(uint256 multiplier, uint256 allocPoint) private view returns (uint256)
	{
		// As long as the owner chooses sane values for _fermionPerBlock and pool.allocPoint it is unlikely that an overflow ever happens
		// Since _fermionPerBlock and pool.allocPoint are choosen by  the owner, it is the responsibility of the owner to ensure
		// that there is now overflow in multiplying these to values.
		// Divions can not generate an overflow if used with uint values. Div by 0 will always panic, wrapped or not.
		// The only place an overflow can happen (even very unlikeley) is if the multiplier gets big enouth to force an overflow.
		return _unsafeDiv(multiplier * _unsafeMul(_fermionPerBlock, allocPoint), totalAllocPoint);
	}

	function _getAccFermionPerShare(uint256 currentAccFermionShare, uint256 fermionReward, uint256 lpSupply) private pure returns (uint256)
	{
		//TODO: Evaluate why fermion Reward is multplied with _ACC_FERMION_PRECISSION
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

	function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256)
	{
		unchecked
		{
			return a + b;
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

	// Set the migrator contract. Can only be called by the owner.
	function setMigrator(IMigratorDevice migratorContract) public onlyOwner {
		migrator = migratorContract;
	}

	// Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
	function migrate(uint256 pid) public {
		require(address(migrator) != address(0), "migrate: no migrator");
		PoolInfo storage pool = poolInfo[pid];
		IERC20 lpToken = pool.lpToken;
		uint256 bal = lpToken.balanceOf(address(this));
		lpToken.safeApprove(address(migrator), bal);
		IERC20 newLpToken = migrator.migrate(lpToken);
		require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
		pool.lpToken = newLpToken;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
	 * @notice Emitted when {value} tokens are moved from one address {from} to another {to}.
	 *
	 * NOTE: {value} may be zero.
	 * @param from (indexed) The origin of the transfer.
	 * @param to (indexed) The target of the transfer.
	 * @param value The amount of tokens that got transfered.
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

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

import "../cobra/interfaces/token/ERC20/IERC20.sol";
import "../cobra/interfaces/token/ERC20/extensions/IERC20Metadata.sol";
import "../cobra/interfaces/access/IOwnable.sol";

/**
 * @dev Interface of the Fermion token.
 */
interface IFermion is IERC20, IERC20Metadata, IOwnable
{
	/**
	* @dev Destroys `amount` tokens from the caller.
	*
	* Emits a {Transfer} event with `to` set to the zero address.
	*
	* Requirements:
	* - caller must have at least `amount` tokens.
	*/
	function burn(uint256 amount) external;
	
	/**
	* @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
	*
	* Emits a {Transfer} event with `to` set to the zero address.
	*
	* Requirements:
	* - caller must have allowance for `account` and `amount` or greater.
	* - `account` must have at least `amount` tokens.
	*/
	function burnFrom(address account, uint256 amount) external;

	/**
	* @dev Atomically increases the allowance granted to `spender` by the caller.
	*             
	* This is an alternative to {approve} that can be used as a mitigation for
	* problems described in {https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit}.
	*
	* Emits an {Approval} event indicating the updated allowance.
	*
	* Requirements:
	* - `spender` cannot be the zero address.
	*/
	function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
	function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
	function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFermion.sol";

interface IMagneticFieldGenerator
{
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event DevelopmentTransferred(address indexed previousDeveloper, address indexed newDeveloper);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

	function add(uint256 allocPoint, IERC20 lpToken) external;
	function deposit(uint256 pid, uint256 amount) external;
	function disablePool(uint256 pid) external;
	function emergencyWithdraw(uint256 pid) external;
	function massUpdatePools() external;
	function renounceOwnership() external;
	function set(uint256 pid, uint256 allocPoint) external;
	function transferOwnership(address newOwner) external;
	function transferDevelopment(address newDevelopmentAddress) external;
	function updatePool(uint256 pid) external;
	function withdraw(uint256 pid, uint256 amount) external;

	function developer() external view returns (address);
	function getFermionContract() external view returns (IFermion);
	function getFermionPerBlock() external view returns (uint256);
	function getStartBlock() external view returns (uint256);
	function owner() external view returns (address);
	function pendingFermion(uint256 pid, address user) external view returns (uint256);
	function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

import "../../interfaces/token/ERC20/IERC20.sol";
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
contract ERC20 is Context, IERC20Metadata {
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;
	uint256 private _totalSupply;
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
	constructor(string memory name_, string memory symbol_)
	{
		_name = name_;
		_symbol = symbol_;
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
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
	{
		address owner = _msgSender();
		uint256 currentAllowance = allowance(owner, spender);
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
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
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

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
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
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

	/**
	* @notice Hook that is called after any transfer of tokens. This includes
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
	function _afterTokenTransfer(address from, address to, uint256 amount) internal pure virtual
	{}  // solhint-disable-line no-empty-blocks

	/**
	* @notice Hook that is called before any transfer of tokens. This includes
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
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal pure virtual
	{} // solhint-disable-line no-empty-blocks


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../cobra/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20
{
	constructor(string memory name, string memory symbol, uint256 supply) ERC20(name, symbol)
	{
		_mint(msg.sender, supply);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../interfaces/token/ERC20/extensions/IERC20Burnable.sol";
import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
* @notice Extension of {ERC20} that allows token holders to destroy both their own
* tokens and those that they have an allowance for, in a way that can be
* recognized off-chain (via event analysis).
*/
abstract contract ERC20Burnable is Context, ERC20, IERC20Burnable {
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

import "./cobra/token/ERC20/extensions/ERC20Burnable.sol";
import "./cobra/access/Ownable.sol";
import "./interfaces/IFermion.sol";

/**
* @dev Implementation of the {IFermion} interface.
* The IFermion interface extends the IERC20, IERC20Metadata, IERC20Burnable, IOwnable interfaces.
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
contract Fermion is ERC20Burnable, Ownable, IFermion
{
	// solhint-disable-next-line no-empty-blocks
	constructor() ERC20("Fermion", "FMN") {}

	/// @notice Destroys `amount` tokens from the caller.
	function burn(uint256 amount) public override (ERC20Burnable, IFermion)
	{
		super.burn(amount);
	}

	/// @notice Destroys `amount` tokens from `account`, deducting from the caller's allowance.
	function burnFrom(address account, uint256 amount) public override(ERC20Burnable, IFermion)
	{
		ERC20Burnable.burnFrom(account, amount);
	}

	/// @notice Atomically decreases the allowance granted to `spender` by the caller.
	function decreaseAllowance(address spender, uint256 subtractedValue) public override(ERC20, IFermion) returns (bool)
	{
		return ERC20.decreaseAllowance(spender, subtractedValue);
	}

	/// @notice Atomically increases the allowance granted to `spender` by the caller.
	function increaseAllowance(address spender, uint256 addedValue) public override(ERC20, IFermion) returns (bool)
	{
		return ERC20.increaseAllowance(spender, addedValue);
	}

	/// @notice Creates `amount` token to `to`. Must only be called by the owner (MagneticFieldGenerator).
	function mint(address to, uint256 amount) public override onlyOwner
	{
		_mint(to, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/token/ERC20/extensions/IERC20Burnable.sol";
import "../token/ERC20/extensions/ERC20Burnable.sol";

interface IERC20BurnableMock is IERC20Burnable
{
	function mint(address to, uint256 amount) external;
}

// solhint-disable-next-line no-empty-blocks
contract ERC20BurnableMock is ERC20Burnable, IERC20BurnableMock
{
	constructor(string memory name, string memory symbol) ERC20(name, symbol)
	{} // solhint-disable-line no-empty-blocks

	/// @notice Creates `amount` token to `to`.
	function mint(address to, uint256 amount) public override
	{
		_mint(to, amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/Ownable.sol";

// solhint-disable-next-line no-empty-blocks
contract OwnableMock is Ownable
{
	// No additional code.
}