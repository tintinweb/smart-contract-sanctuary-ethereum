/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-13
 */

// SPDX-License-Identifier: MIT

// Special Thanks to @BoringCrypto for his ideas and patience

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedSafeMath.sol
library SignedSafeMath {
	int256 private constant _INT256_MIN = -2**255;

	/**
	 * @dev Returns the multiplication of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(int256 a, int256 b) internal pure returns (int256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

		int256 c = a * b;
		require(c / a == b, "SignedSafeMath: multiplication overflow");

		return c;
	}

	/**
	 * @dev Returns the integer division of two signed integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(int256 a, int256 b) internal pure returns (int256) {
		require(b != 0, "SignedSafeMath: division by zero");
		require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

		int256 c = a / b;

		return c;
	}

	/**
	 * @dev Returns the subtraction of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

		return c;
	}

	/**
	 * @dev Returns the addition of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

		return c;
	}

	function toUInt256(int256 a) internal pure returns (uint256) {
		require(a >= 0, "Integer < 0");
		return uint256(a);
	}
}

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a + b) >= b, "BoringMath: Add Overflow");
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a - b) <= a, "BoringMath: Underflow");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
	}

	function to128(uint256 a) internal pure returns (uint128 c) {
		require(a <= uint128(-1), "BoringMath: uint128 Overflow");
		c = uint128(a);
	}

	function to64(uint256 a) internal pure returns (uint64 c) {
		require(a <= uint64(-1), "BoringMath: uint64 Overflow");
		c = uint64(a);
	}

	function to32(uint256 a) internal pure returns (uint32 c) {
		require(a <= uint32(-1), "BoringMath: uint32 Overflow");
		c = uint32(a);
	}
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
	function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
		require((c = a + b) >= b, "BoringMath: Add Overflow");
	}

	function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
		require((c = a - b) <= a, "BoringMath: Underflow");
	}
}

contract BoringOwnableData {
	address public owner;
	address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/// @notice `owner` defaults to msg.sender on construction.
	constructor() public {
		owner = msg.sender;
		emit OwnershipTransferred(address(0), msg.sender);
	}

	/// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
	/// Can only be invoked by the current `owner`.
	/// @param newOwner Address of the new owner.
	/// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
	/// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
	function transferOwnership(
		address newOwner,
		bool direct,
		bool renounce
	) public onlyOwner {
		if (direct) {
			// Checks
			require(newOwner != address(0) || renounce, "Ownable: zero address");

			// Effects
			emit OwnershipTransferred(owner, newOwner);
			owner = newOwner;
			pendingOwner = address(0);
		} else {
			// Effects
			pendingOwner = newOwner;
		}
	}

	/// @notice Needs to be called by `pendingOwner` to claim ownership.
	function claimOwnership() public {
		address _pendingOwner = pendingOwner;

		// Checks
		require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

		// Effects
		emit OwnershipTransferred(owner, _pendingOwner);
		owner = _pendingOwner;
		pendingOwner = address(0);
	}

	/// @notice Only allows the `owner` to execute the function.
	modifier onlyOwner() {
		require(msg.sender == owner, "Ownable: caller is not the owner");
		_;
	}
}

interface IERC20 {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	function decimals() external view returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function permit(
		address owner,
		address spender,
		uint256 rawAmount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

interface ITeleToken is IERC20 {
	function mint(address account, uint256 amount) external;
}

library BoringERC20 {
	bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
	bytes4 private constant SIG_NAME = 0x06fdde03; // name()
	bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
	bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
	bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

	function returnDataToString(bytes memory data) internal pure returns (string memory) {
		if (data.length >= 64) {
			return abi.decode(data, (string));
		} else if (data.length == 32) {
			uint8 i = 0;
			while (i < 32 && data[i] != 0) {
				i++;
			}
			bytes memory bytesArray = new bytes(i);
			for (i = 0; i < 32 && data[i] != 0; i++) {
				bytesArray[i] = data[i];
			}
			return string(bytesArray);
		} else {
			return "???";
		}
	}

	/// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
	/// @param token The address of the ERC-20 token contract.
	/// @return (string) Token symbol.
	function safeSymbol(IERC20 token) internal view returns (string memory) {
		(bool success, bytes memory data) = address(token).staticcall(
			abi.encodeWithSelector(SIG_SYMBOL)
		);
		return success ? returnDataToString(data) : "???";
	}

	/// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
	/// @param token The address of the ERC-20 token contract.
	/// @return (string) Token name.
	function safeName(IERC20 token) internal view returns (string memory) {
		(bool success, bytes memory data) = address(token).staticcall(
			abi.encodeWithSelector(SIG_NAME)
		);
		return success ? returnDataToString(data) : "???";
	}

	/// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
	/// @param token The address of the ERC-20 token contract.
	/// @return (uint8) Token decimals.
	function safeDecimals(IERC20 token) internal view returns (uint8) {
		(bool success, bytes memory data) = address(token).staticcall(
			abi.encodeWithSelector(SIG_DECIMALS)
		);
		return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
	}

	/// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
	/// Reverts on a failed transfer.
	/// @param token The address of the ERC-20 token.
	/// @param to Transfer tokens to.
	/// @param amount The token amount.
	function safeTransfer(
		IERC20 token,
		address to,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = address(token).call(
			abi.encodeWithSelector(SIG_TRANSFER, to, amount)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"BoringERC20: Transfer failed"
		);
	}

	/// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
	/// Reverts on a failed transfer.
	/// @param token The address of the ERC-20 token.
	/// @param from Transfer tokens from.
	/// @param to Transfer tokens to.
	/// @param amount The token amount.
	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 amount
	) internal {
		(bool success, bytes memory data) = address(token).call(
			abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
		);
		require(
			success && (data.length == 0 || abi.decode(data, (bool))),
			"BoringERC20: TransferFrom failed"
		);
	}
}

contract BaseBoringBatchable {
	/// @dev Helper function to extract a useful revert message from a failed call.
	/// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
	function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
		// If the _res length is less than 68, then the transaction failed silently (without a revert message)
		if (_returnData.length < 68) return "Transaction reverted silently";

		assembly {
			// Slice the sighash.
			_returnData := add(_returnData, 0x04)
		}
		return abi.decode(_returnData, (string)); // All that remains is the revert string
	}

	/// @notice Allows batched call to self (this contract).
	/// @param calls An array of inputs for each call.
	/// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
	/// @return successes An array indicating the success of a call, mapped one-to-one to `calls`.
	/// @return results An array with the returned data of each function call, mapped one-to-one to `calls`.
	// F1: External is ok here because this is the batch function, adding it to a batch makes no sense
	// F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
	// C3: The length of the loop is fully under user control, so can't be exploited
	// C7: Delegatecall is only used on the same contract, so it's safe
	function batch(bytes[] calldata calls, bool revertOnFail)
		external
		payable
		returns (bool[] memory successes, bytes[] memory results)
	{
		successes = new bool[](calls.length);
		results = new bytes[](calls.length);
		for (uint256 i = 0; i < calls.length; i++) {
			(bool success, bytes memory result) = address(this).delegatecall(calls[i]);
			require(success || !revertOnFail, _getRevertMsg(result));
			successes[i] = success;
			results[i] = result;
		}
	}
}

contract BoringBatchable is BaseBoringBatchable {
	/// @notice Call wrapper that performs `ERC20.permit` on `token`.
	/// Lookup `IERC20.permit`.
	// F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
	//     if part of a batch this could be used to grief once as the second call would not need the permit
	function permitToken(
		IERC20 token,
		address from,
		address to,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		token.permit(from, to, amount, deadline, v, r, s);
	}
}

interface IRewarder {
	using BoringERC20 for IERC20;

	function onTeleReward(
		uint256 pid,
		address user,
		address recipient,
		uint256 teleAmount,
		uint256 newLpAmount
	) external;

	function pendingTokens(
		uint256 pid,
		address user,
		uint256 teleAmount
	) external view returns (IERC20[] memory, uint256[] memory);
}

interface IMigratorChef {
	// Take the current LP token address and return the new LP token address.
	// Migrator should have full access to the caller's LP token.
	function migrate(IERC20 token) external returns (IERC20);
}

/// @notice The (older) MasterChef contract gives out a constant number of TELE tokens per block.
/// It is the only address with minting rights for TELE.
/// The idea for this MasterChef V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the MasterChef V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract MasterChefV2 is BoringOwnable, BoringBatchable {
	using BoringMath for uint256;
	using BoringMath128 for uint128;
	using BoringERC20 for IERC20;
	using BoringERC20 for ITeleToken;
	using SignedSafeMath for int256;

	/// @notice Info of each MCV2 user.
	/// `amount` LP token amount the user has provided.
	/// `rewardDebt` The amount of TELE entitled to the user.
	struct UserInfo {
		uint256 amount;
		int256 rewardDebt;
	}

	/// @notice Info of each MCV2 pool.
	/// `allocPoint` The amount of allocation points assigned to the pool.
	/// Also known as the amount of TELE to distribute per block.
	struct PoolInfo {
		uint128 accTelePerShare;
		uint64 lastRewardBlock;
		uint64 allocPoint;
	}

	/// @notice Address of TELE contract.
	ITeleToken public immutable TELE;
	// Dev address.
	address public devaddr;
	// Block number when bonus TELE period ends.
	uint256 public bonusEndBlock;
	// Bonus muliplier for early tele makers.
	uint256 public constant BONUS_MULTIPLIER = 10;
	// @notice The migrator contract. It has a lot of power. Can only be set through governance (owner).
	IMigratorChef public migrator;

	/// @notice Info of each MCV2 pool.
	PoolInfo[] public poolInfo;
	/// @notice Address of the LP token for each MCV2 pool.
	IERC20[] public lpToken;
	/// @notice Address of each `IRewarder` contract in MCV2.
	IRewarder[] public rewarder;

	/// @notice Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	/// @dev Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint;
	// The block number when TELE mining starts.
	uint256 public startBlock;

	uint256 private constant TELE_PER_BLOCK = 1e20;
	uint256 private constant ACC_TELE_PRECISION = 1e12;

	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
	event EmergencyWithdraw(
		address indexed user,
		uint256 indexed pid,
		uint256 amount,
		address indexed to
	);
	event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
	event LogPoolAddition(
		uint256 indexed pid,
		uint256 allocPoint,
		IERC20 indexed lpToken,
		IRewarder indexed rewarder
	);
	event LogSetPool(
		uint256 indexed pid,
		uint256 allocPoint,
		IRewarder indexed rewarder,
		bool overwrite
	);
	event LogUpdatePool(
		uint256 indexed pid,
		uint64 lastRewardBlock,
		uint256 lpSupply,
		uint256 accTelePerShare
	);
	event LogInit();

	/// @param _tele The TELE token contract address.
	constructor(
		ITeleToken _tele,
		address _devaddr,
		uint256 _startBlock,
		uint256 _bonusEndBlock
	) public {
		TELE = _tele;
		devaddr = _devaddr;
		bonusEndBlock = _bonusEndBlock;
		startBlock = _startBlock;
	}

	// "0x9ce64725dc0c23fe1faba922172e97c1b41333b8","0xf53DE030D0cD90Ce2a86DF95b7C36e9586D42344","10727307","10797307"
	// "10","0x180573511496e881ae3f7d3d38d90d708cf98d57","0x0000000000000000000000000000000000000000"
	// "0","99999999000","0x2fDFf969140496C6Fe9275C852B6053980283356"

	/// @notice Returns the number of MCV2 pools.
	function poolLength() public view returns (uint256 pools) {
		pools = poolInfo.length;
	}

	/// @notice Add a new LP to the pool. Can only be called by the owner.
	/// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
	/// @param allocPoint AP of the new pool.
	/// @param _lpToken Address of the LP ERC-20 token.
	/// @param _rewarder Address of the rewarder delegate.
	function add(
		uint256 allocPoint,
		IERC20 _lpToken,
		IRewarder _rewarder
	) public onlyOwner {
		uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
		totalAllocPoint = totalAllocPoint.add(allocPoint);
		lpToken.push(_lpToken);
		rewarder.push(_rewarder);

		poolInfo.push(
			PoolInfo({
				allocPoint: allocPoint.to64(),
				lastRewardBlock: lastRewardBlock.to64(),
				accTelePerShare: 0
			})
		);
		emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken, _rewarder);
	}

	/// @notice Update the given pool's TELE allocation point and `IRewarder` contract. Can only be called by the owner.
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _allocPoint New AP of the pool.
	/// @param _rewarder Address of the rewarder delegate.
	/// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
	function set(
		uint256 _pid,
		uint256 _allocPoint,
		IRewarder _rewarder,
		bool overwrite
	) public onlyOwner {
		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint.to64();
		if (overwrite) {
			rewarder[_pid] = _rewarder;
		}
		emit LogSetPool(_pid, _allocPoint, overwrite ? _rewarder : rewarder[_pid], overwrite);
	}

	/// @notice Set the `migrator` contract. Can only be called by the owner.
	/// @param _migrator The contract address to set.
	function setMigrator(IMigratorChef _migrator) public onlyOwner {
		migrator = _migrator;
	}

	/// @notice Migrate LP token to another LP contract through the `migrator` contract.
	/// @param _pid The index of the pool. See `poolInfo`.
	function migrate(uint256 _pid) public {
		require(address(migrator) != address(0), "MasterChefV2: no migrator set");
		IERC20 _lpToken = lpToken[_pid];
		uint256 bal = _lpToken.balanceOf(address(this));
		_lpToken.approve(address(migrator), bal);
		IERC20 newLpToken = migrator.migrate(_lpToken);
		require(
			bal == newLpToken.balanceOf(address(this)),
			"MasterChefV2: migrated balance must match"
		);
		lpToken[_pid] = newLpToken;
	}

	// Return reward multiplier over the given _from to _to block.
	function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
		if (_to <= bonusEndBlock) {
			return _to.sub(_from).mul(BONUS_MULTIPLIER);
		} else if (_from >= bonusEndBlock) {
			return _to.sub(_from);
		} else {
			return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
		}
	}

	/// @notice View function to see pending TELE on frontend.
	/// @param _pid The index of the pool. See `poolInfo`.
	/// @param _user Address of user.
	/// @return pending TELE reward for a given user.
	function pendingTele(uint256 _pid, address _user) external view returns (uint256 pending) {
		PoolInfo memory pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accTelePerShare = pool.accTelePerShare;
		uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 blocks = block.number.sub(pool.lastRewardBlock);
			uint256 teleReward = blocks.mul(TELE_PER_BLOCK).mul(pool.allocPoint) / totalAllocPoint;
			accTelePerShare = accTelePerShare.add(teleReward.mul(ACC_TELE_PRECISION) / lpSupply);
		}
		pending = int256(user.amount.mul(accTelePerShare) / ACC_TELE_PRECISION)
			.sub(user.rewardDebt)
			.toUInt256();
	}

	/// @notice Update reward variables for all pools. Be careful of gas spending!
	/// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
	function massUpdatePools(uint256[] calldata pids) external {
		uint256 len = pids.length;
		for (uint256 i = 0; i < len; ++i) {
			updatePool(pids[i]);
		}
	}

	/// @notice Update reward variables of the given pool.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @return pool Returns the pool that was updated.
	function updatePool(uint256 pid) public returns (PoolInfo memory pool) {
		pool = poolInfo[pid];
		if (block.number > pool.lastRewardBlock) {
			uint256 lpSupply = lpToken[pid].balanceOf(address(this));
			if (lpSupply > 0) {
				uint256 blocks = block.number.sub(pool.lastRewardBlock);
				// telePerBlock() = 182355301068602080 = 0.1 tele
				uint256 teleReward = blocks.mul(TELE_PER_BLOCK).mul(pool.allocPoint) /
					totalAllocPoint;
				pool.accTelePerShare = pool.accTelePerShare.add(
					(teleReward.mul(ACC_TELE_PRECISION) / lpSupply).to128()
				);
				TELE.mint(devaddr, teleReward / 10);
				TELE.mint(address(this), teleReward);
			}
			pool.lastRewardBlock = block.number.to64();
			poolInfo[pid] = pool;
			emit LogUpdatePool(pid, pool.lastRewardBlock, lpSupply, pool.accTelePerShare);
		}
	}

	/// @notice Deposit LP tokens to MCV2 for TELE allocation.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param amount LP token amount to deposit.
	/// @param to The receiver of `amount` deposit benefit.
	function deposit(
		uint256 pid,
		uint256 amount,
		address to
	) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][to];

		// Effects
		user.amount = user.amount.add(amount);
		user.rewardDebt = user.rewardDebt.add(
			int256(amount.mul(pool.accTelePerShare) / ACC_TELE_PRECISION)
		);

		// Interactions
		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onTeleReward(pid, to, to, 0, user.amount);
		}

		lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

		emit Deposit(msg.sender, pid, amount, to);
	}

	/// @notice Withdraw LP tokens from MCV2.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param amount LP token amount to withdraw.
	/// @param to Receiver of the LP tokens.
	function withdraw(
		uint256 pid,
		uint256 amount,
		address to
	) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][msg.sender];

		// Effects
		user.rewardDebt = user.rewardDebt.sub(
			int256(amount.mul(pool.accTelePerShare) / ACC_TELE_PRECISION)
		);
		user.amount = user.amount.sub(amount);

		// Interactions
		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onTeleReward(pid, msg.sender, to, 0, user.amount);
		}

		lpToken[pid].safeTransfer(to, amount);

		emit Withdraw(msg.sender, pid, amount, to);
	}

	/// @notice Harvest proceeds for transaction sender to `to`.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param to Receiver of TELE rewards.
	function harvest(uint256 pid, address to) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][msg.sender];
		int256 accumulatedTele = int256(user.amount.mul(pool.accTelePerShare) / ACC_TELE_PRECISION);
		uint256 _pendingTele = accumulatedTele.sub(user.rewardDebt).toUInt256();

		// Effects
		user.rewardDebt = accumulatedTele;

		// Interactions
		if (_pendingTele != 0) {
			TELE.safeTransfer(to, _pendingTele);
		}

		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onTeleReward(pid, msg.sender, to, _pendingTele, user.amount);
		}

		emit Harvest(msg.sender, pid, _pendingTele);
	}

	/// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param amount LP token amount to withdraw.
	/// @param to Receiver of the LP tokens and TELE rewards.
	function withdrawAndHarvest(
		uint256 pid,
		uint256 amount,
		address to
	) public {
		PoolInfo memory pool = updatePool(pid);
		UserInfo storage user = userInfo[pid][msg.sender];
		int256 accumulatedTele = int256(user.amount.mul(pool.accTelePerShare) / ACC_TELE_PRECISION);
		uint256 _pendingTele = accumulatedTele.sub(user.rewardDebt).toUInt256();

		// Effects
		user.rewardDebt = accumulatedTele.sub(
			int256(amount.mul(pool.accTelePerShare) / ACC_TELE_PRECISION)
		);
		user.amount = user.amount.sub(amount);

		// Interactions
		TELE.safeTransfer(to, _pendingTele);

		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onTeleReward(pid, msg.sender, to, _pendingTele, user.amount);
		}

		lpToken[pid].safeTransfer(to, amount);

		emit Withdraw(msg.sender, pid, amount, to);
		emit Harvest(msg.sender, pid, _pendingTele);
	}

	/// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
	/// @param pid The index of the pool. See `poolInfo`.
	/// @param to Receiver of the LP tokens.
	function emergencyWithdraw(uint256 pid, address to) public {
		UserInfo storage user = userInfo[pid][msg.sender];
		uint256 amount = user.amount;
		user.amount = 0;
		user.rewardDebt = 0;

		IRewarder _rewarder = rewarder[pid];
		if (address(_rewarder) != address(0)) {
			_rewarder.onTeleReward(pid, msg.sender, to, 0, 0);
		}

		// Note: transfer can fail or succeed if `amount` is zero.
		lpToken[pid].safeTransfer(to, amount);
		emit EmergencyWithdraw(msg.sender, pid, amount, to);
	}

	// Update dev address by the previous dev.
	function setDev(address _devaddr) public {
		require(msg.sender == devaddr, "You are not allowed to do this!");
		devaddr = _devaddr;
	}
}