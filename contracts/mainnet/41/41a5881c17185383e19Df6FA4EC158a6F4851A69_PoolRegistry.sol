// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IProxyFactory.sol";
import "./interfaces/IRewards.sol";

contract PoolRegistry {

    address public constant owner = address(0x59CFCD384746ec3035299D90782Be065e466800B);
    address public constant proxyFactory = address(0x66807B5598A848602734B82E432dD88DBE13fC8f);

    address public operator;
    address public rewardImplementation;
    bool public rewardsStartActive;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => address)) public vaultMap; //pool -> user -> vault
    mapping(uint256 => address[]) public poolVaultList; //pool -> vault array
    
    struct PoolInfo {
        address implementation;
        address stakingAddress;
        address stakingToken;
        address rewardsAddress;
        uint8 active;
    }

    event PoolCreated(uint256 indexed poolid, address indexed implementation, address stakingAddress, address stakingToken);
    event PoolDeactivated(uint256 indexed poolid);
    event AddUserVault(address indexed user, uint256 indexed poolid);
    event OperatorChanged(address indexed account);
    event RewardImplementationChanged(address indexed implementation);
    event RewardActiveOnCreationChanged(bool value);

    constructor() {}

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "!op auth");
        _;
    }

    //set operator/manager
    function setOperator(address _op) external onlyOwner{
        operator = _op;
        emit OperatorChanged(_op);
    }

    //set extra reward implementation contract for future pools
    function setRewardImplementation(address _imp) external onlyOperator{
        rewardImplementation = _imp;
        emit RewardImplementationChanged(_imp);
    }

    //set rewards to be active when pool is created
    function setRewardActiveOnCreation(bool _active) external onlyOperator{
        rewardsStartActive = _active;
        emit RewardActiveOnCreationChanged(_active);
    }

    //get number of pools
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //get number of vaults made for a specific pool
    function poolVaultLength(uint256 _pid) external view returns (uint256) {
        return poolVaultList[_pid].length;
    }

    //add a new pool and implementation
    function addPool(address _implementation, address _stakingAddress, address _stakingToken) external onlyOperator{
        require(_implementation != address(0), "!imp");
        require(_stakingAddress != address(0), "!stkAdd");
        require(_stakingToken != address(0), "!stkTok");

        address rewards;
        if(rewardImplementation != address(0)){
           rewards = IProxyFactory(proxyFactory).clone(rewardImplementation);
           IRewards(rewards).initialize(poolInfo.length, rewardsStartActive);
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
        emit PoolCreated(poolInfo.length-1, _implementation, _stakingAddress, _stakingToken);
    }

    //replace rewards contract on a specific pool.
    //each user must call changeRewards on vault to update to new contract
    function createNewPoolRewards(uint256 _pid) external onlyOperator{
        require(rewardImplementation != address(0), "!imp");

        //spawn new clone
        address rewards = IProxyFactory(proxyFactory).clone(rewardImplementation);
        IRewards(rewards).initialize(_pid, rewardsStartActive);

        //change address
        poolInfo[_pid].rewardsAddress = rewards;
    }
    //deactivates pool so that new vaults can not be made.
    //can not force shutdown/withdraw user funds
    function deactivatePool(uint256 _pid) external onlyOperator{
        poolInfo[_pid].active = 0;
        emit PoolDeactivated(_pid);
    }

    //clone a new user vault
    function addUserVault(uint256 _pid, address _user) external onlyOperator returns(address vault, address stakingAddress, address stakingToken, address rewards){
        require(vaultMap[_pid][_user] == address(0), "already exists");

        PoolInfo storage pool = poolInfo[_pid];
        require(pool.active > 0, "!active");

        //create
        vault = IProxyFactory(proxyFactory).clone(pool.implementation);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewards{
    struct EarnedData {
        address token;
        uint256 amount;
    }
    
    function initialize(uint256 _pid, bool _startActive) external;
    function addReward(address _rewardsToken, address _distributor) external;
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
    function deposit(address _owner, uint256 _amount) external;
    function withdraw(address _owner, uint256 _amount) external;
    function getReward(address _forward) external;
    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external;
    function balanceOf(address account) external view returns (uint256);
    function claimableRewards(address _account) external view returns(EarnedData[] memory userRewards);
    function rewardTokens(uint256 _rid) external view returns (address);
    function rewardTokenLength() external view returns(uint256);
    function active() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IProxyFactory {
    function clone(address _target) external returns(address);
}