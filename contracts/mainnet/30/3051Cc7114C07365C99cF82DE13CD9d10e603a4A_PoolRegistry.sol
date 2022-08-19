// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ILiquidityGaugeStratFrax {
	struct Reward {
		address token;
		address distributor;
		uint256 period_finish;
		uint256 rate;
		uint256 last_update;
		uint256 integral;
	}

	// solhint-disable-next-line
	function deposit_reward_token(address _rewardToken, uint256 _amount) external;

	function claim_rewards(address _addr, address _recipient) external;

	// solhint-disable-next-line
	function claim_rewards_for(address _user, address _recipient) external;

	// // solhint-disable-next-line
	// function claim_rewards_for(address _user) external;

	// solhint-disable-next-line
	function deposit(
		uint256 _value,
		address _addr,
		bool _claim_reward
	) external;

	// solhint-disable-next-line
	function reward_tokens(uint256 _i) external view returns (address);

	function reward_count() external view returns (uint256);

	function initialized() external view returns (bool);

	function withdraw(
		uint256 _value,
		address _addr,
		bool _claim_rewards
	) external;

	// solhint-disable-next-line
	function reward_data(address _tokenReward) external view returns (Reward memory);

	function balanceOf(address) external returns (uint256);

	function claimable_reward(address _user, address _reward_token) external view returns (uint256);

	function user_checkpoint(address _user) external returns (bool);

	function commit_transfer_ownership(address) external;

	function initialize(
		address _admin,
		address _SDT,
		address _voting_escrow,
		address _veBoost_proxy,
		address _distributor,
		uint256 _pid,
		address _poolRegistry
	) external;

	function add_reward(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/ILiquidityGaugeStratFrax.sol";

interface IProxyFactory {
	function clone(address) external returns (address);
}

contract PoolRegistry {
	address public owner;
	address public constant PROXY_FACTORY = address(0x60d4a8F3947BfC3a836a2b311e9A4c8325f985f5);
	address public constant SDT = address(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);
	address public constant VE_SDT = address(0x0C30476f66034E11782938DF8e4384970B6c9e8a);
	address public constant VEBOOST = address(0xD67bdBefF01Fc492f1864E61756E5FBB3f173506);

	address public operator;
	address public rewardImplementation; // Liquidity Gauge Contract model
	address public distributor;
	PoolInfo[] public poolInfo;
	mapping(uint256 => mapping(address => address)) public vaultMap; //pool -> user -> vault
	mapping(uint256 => address[]) public poolVaultList; //pool -> vault array

	struct PoolInfo {
		address implementation; // Personal Vault model
		address stakingAddress; // Frax Gauge for stacking LP token
		address stakingToken; // LP token
		address rewardsAddress; // Liquidity Gauge V4 from Stake DAO for extra rewards
		uint8 active;
	}

	event PoolCreated(
		uint256 indexed poolid,
		address indexed implementation,
		address stakingAddress,
		address stakingToken
	);

	event PoolDeactivated(uint256 indexed poolid);
	event AddUserVault(address indexed user, uint256 indexed poolid);
	event OperatorChanged(address indexed account);
	event RewardImplementationChanged(address indexed implementation);
	event RewardActiveOnCreationChanged(bool value);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "!auth");
		_;
	}

	modifier onlyOperator() {
		require(operator == msg.sender, "!op auth");
		_;
	}

	/// @notice set operator/manager
	/// @param _op new operator address
	function setOperator(address _op) external onlyOwner {
		operator = _op;
		emit OperatorChanged(_op);
	}

	/// @notice set distributor
	/// @param _distributor new distributor address
	function setDistributor(address _distributor) external onlyOperator {
		distributor = _distributor;
	}

	/// @notice set extra reward implementation contract for future pools (LG model)
	/// @param _imp new LG model address
	function setRewardImplementation(address _imp) external onlyOperator {
		rewardImplementation = _imp;
		emit RewardImplementationChanged(_imp);
	}

	/// @notice get number of pools
	function poolLength() external view returns (uint256) {
		return poolInfo.length;
	}

	/// @notice get number of vaults made for a specific pool
	/// @param _pid pool id 
	function poolVaultLength(uint256 _pid) external view returns (uint256) {
		return poolVaultList[_pid].length;
	}

	/// @notice add a new pool and implementation
	/// @param _implementation personal vault contract model address
	/// @param _stakingAddress Frax gauge stacking LP token address
	/// @param _stakingToken LP token address for Frax gauge
	function addPool(
		address _implementation,
		address _stakingAddress,
		address _stakingToken
	) external onlyOperator {
		require(_implementation != address(0), "!imp");
		require(_stakingAddress != address(0), "!stkAdd");
		require(_stakingToken != address(0), "!stkTok");

		address rewards;
		if (rewardImplementation != address(0)) {
			rewards = IProxyFactory(PROXY_FACTORY).clone(rewardImplementation);
			ILiquidityGaugeStratFrax(rewards).initialize(
				owner,
				SDT,
				VE_SDT,
				VEBOOST,
				distributor,
				poolInfo.length,
				address(this)
			);
		}

		poolInfo.push(
			PoolInfo({
				implementation: _implementation,
				stakingAddress: _stakingAddress,
				stakingToken: _stakingToken,
				rewardsAddress: rewards,
				active: 1
			})
		);
		emit PoolCreated(poolInfo.length - 1, _implementation, _stakingAddress, _stakingToken);
	}

	/// @notice update rewards contract on a specific pool, when updated with setRewardImplementation().
	/// @dev each user must call changeRewards on vault to update to new contract
	/// @param _pid pool id for the new rewards contract
	function createNewPoolRewards(uint256 _pid) external onlyOperator {
		require(rewardImplementation != address(0), "!imp");

		//spawn new clone
		address rewards = IProxyFactory(PROXY_FACTORY).clone(rewardImplementation);
		ILiquidityGaugeStratFrax(rewards).initialize(owner, SDT, VE_SDT, VEBOOST, distributor, _pid, address(this));

		//change address
		poolInfo[_pid].rewardsAddress = rewards;
	}

	/// @notice deactivates pool so that new vaults can not be made.
	/// @dev can not force shutdown/withdraw user funds
	/// @param _pid pool id to desactivate
	function deactivatePool(uint256 _pid) external onlyOperator {
		poolInfo[_pid].active = 0;
		emit PoolDeactivated(_pid);
	}

	/// @notice clone a new user vault
	/// @param _pid pool id reference for new user vault
	/// @param _user owner's address of the created vault
	function addUserVault(uint256 _pid, address _user)
		external
		onlyOperator
		returns (
			address vault,
			address stakingAddress,
			address stakingToken,
			address rewards
		)
	{
		require(vaultMap[_pid][_user] == address(0), "already exists");

		PoolInfo storage pool = poolInfo[_pid];
		require(pool.active > 0, "!active");

		//create
		vault = IProxyFactory(PROXY_FACTORY).clone(pool.implementation);
		//add to user map
		vaultMap[_pid][_user] = vault;
		//add to pool vault list
		poolVaultList[_pid].push(vault);

		//return values
		stakingAddress = pool.stakingAddress;
		stakingToken = pool.stakingToken;
		rewards = pool.rewardsAddress;

		emit AddUserVault(_user, _pid);
	}
}