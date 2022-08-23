// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../tokens/HelixToken.sol";
import "../interfaces/IReferralRegister.sol";
import "../interfaces/IFeeMinter.sol";
import "../timelock/OwnableTimelockUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract MasterChef is Initializable, PausableUpgradeable, OwnableUpgradeable, OwnableTimelockUpgradeable {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of HelixTokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHelixTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accHelixTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. HelixTokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that HelixTokens distribution occurs.
        uint256 accHelixTokenPerShare; // Accumulated HelixTokens per share, times 1e12. See below.
    }

    // Used by bucket deposits and withdrawals to enable a caller to deposit lpTokens
    // and accrue yield into distinct, uniquely indentified "buckets" such that each
    // bucket can be interacted with individually and without affecting deposits and 
    // yields in other buckets
    struct BucketInfo {
        uint256 amount;             // How many LP tokens have been deposited into the bucket
        uint256 rewardDebt;         // Reward debt. See explanation in UserInfo
        uint256 yield;              // Accrued but unwithdrawn yield
    }
     
    // The HelixToken TOKEN!
    HelixToken public helixToken;

    // Called to get helix token to mint per block rates
    IFeeMinter public feeMinter;

    //Pools, Farms, Dev, Refs percent decimals
    uint256 public percentDec;

    //Pools and Farms percent from token per block
    uint256 public stakingPercent;

    //Developers percent from token per block
    uint256 public devPercent;

    // Dev address.
    address public devaddr;

    // Last block then develeper withdraw dev and ref fee
    uint256 public lastBlockDevWithdraw;

    // Bonus muliplier for early HelixToken makers.
    uint256 public BONUS_MULTIPLIER;

    // Referral Register contract
    IReferralRegister public refRegister;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The block number when HelixToken mining starts.
    uint256 public startBlock;

    // Deposited amount HelixToken in MasterChef
    uint256 public depositedHelix;

    // Maps poolId => depositorAddress => bucketId => BucketInfo
    // where the depositor is depositing funds into a uniquely identified deposit "bucket"
    // and where those funds are only accessible by the depositor
    // Used by the bucket deposit and withdraw functions
    mapping(uint256 => mapping(address => mapping(uint256 => BucketInfo))) public bucketInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Maps a lpToken address to a poolId
    mapping(address => uint256) public poolIds;

    event Deposit(
        address indexed user, 
        uint256 indexed pid, 
        uint256 amount
    );

    event Withdraw(
        address indexed user, 
        uint256 indexed pid, 
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    // Emitted when the owner adds a new LP Token to the pool
    event Added(uint256 indexed poolId, address indexed lpToken, bool withUpdate);

    // Emitted when the owner sets the pool alloc point
    event AllocPointSet(uint256 indexed poolId, uint256 allocPoint, bool withUpdate);

    // Emitted when the owner sets a new referral register contract
    event ReferralRegisterSet(address referralRegister);

    // Emitted when the pool is updated
    event PoolUpdated(uint256 indexed poolId);

    // Emitted when the owner sets a new dev address
    event DevAddressSet(address devAddress);

    // Emitted when the owner updates the helix per block rate
    event HelixPerBlockUpdated(uint256 rate);

    // Emitted when the feeMinter is set
    event SetFeeMinter(address indexed setter, address indexed feeMinter);
    
    // Emitted when a depositor deposits amount of lpToken into bucketId and stakes to poolId
    event BucketDeposit(
        address indexed depositor, 
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 amount
    );

    event BucketWithdraw(
        address indexed depositor, 
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 amount
    );

    event BucketWithdrawAmountTo(
        address indexed depositor, 
        address indexed recipient,
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 amount
    );

    event BucketWithdrawYieldTo(
        address indexed depositor, 
        address indexed recipient,
        uint256 indexed bucketId,
        uint256 poolId, 
        uint256 yield 
    );

    event UpdateBucket(
        address indexed depositor,
        uint256 indexed bucketId,
        uint256 indexed poolId
    );

    modifier isNotHelixPoolId(uint256 poolId) {
        require(poolId != 0, "MasterChef: invalid pool id");
        _;
    }

    modifier isNotZeroAddress(address _address) {
        require(_address != address(0), "MasterChef: zero address");
        _;
    }

    function initialize(
        HelixToken _HelixToken,
        address _devaddr,
        address _feeMinter,
        uint256 _startBlock,
        uint256 _stakingPercent,
        uint256 _devPercent,
        IReferralRegister _referralRegister
    ) external initializer {
        __Ownable_init();
        __OwnableTimelock_init();
        helixToken = _HelixToken;
        devaddr = _devaddr;
        feeMinter = IFeeMinter(_feeMinter);
        startBlock = _startBlock != 0 ? _startBlock : block.number;
        stakingPercent = _stakingPercent;
        devPercent = _devPercent;
        lastBlockDevWithdraw = _startBlock != 0 ? _startBlock : block.number;
        refRegister = _referralRegister;
        
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _HelixToken,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accHelixTokenPerShare: 0
        }));
        poolIds[address(_HelixToken)] = 0;

        totalAllocPoint = 1000;
        percentDec = 1000000;
        BONUS_MULTIPLIER = 1;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyTimelock {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Return the lpToken address associated with poolId _pid
    function getLpToken(uint256 _pid) external view returns(address) {
        return address(poolInfo[_pid].lpToken);
    }
    
    // Return the poolId associated with the lpToken address
    function getPoolId(address _lpToken) external view returns (uint256) {
        uint256 poolId = poolIds[_lpToken];
        if (poolId == 0) {
            require(_lpToken == address(helixToken), "MasterChef: token not added");
        }
        return poolId;
    }

    function withdrawDevAndRefFee() external {
        require(lastBlockDevWithdraw < block.number, "MasterChef: wait for new block");
        uint256 blockDelta = getMultiplier(lastBlockDevWithdraw, block.number);
        uint256 helixTokenReward = blockDelta * _getDevToMintPerBlock();
        lastBlockDevWithdraw = block.number;
        helixToken.mint(devaddr, helixTokenReward);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyTimelock {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + (_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accHelixTokenPerShare: 0
            })
        );

        uint256 poolId = poolInfo.length - 1;
        poolIds[address(_lpToken)] = poolId;

        emit Added(poolId, address(_lpToken), _withUpdate);
    }

    // Update the given pool's HelixToken allocation point. Can only be called by the owner.
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyTimelock {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - (poolInfo[_pid].allocPoint) + (_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;

        emit AllocPointSet(_pid, _allocPoint, _withUpdate);
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
         return (_to - _from) * (BONUS_MULTIPLIER);
    }

    // Set ReferralRegister address
    function setReferralRegister(address _address) external onlyOwner {
        refRegister = IReferralRegister(_address);
        emit ReferralRegisterSet(_address);
    }

    // View function to see pending HelixTokens on frontend.
    function pendingHelixToken(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accHelixTokenPerShare = pool.accHelixTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedHelix;
        }

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 blockDelta = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 toMintPerBlock = _getStakeToMintPerBlock();
            uint256 helixTokenReward = blockDelta * toMintPerBlock * (pool.allocPoint) / (totalAllocPoint);
            accHelixTokenPerShare = accHelixTokenPerShare + (helixTokenReward * (1e12) / (lpSupply));
        }

        uint256 pending = user.amount * (accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        return pending;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedHelix;
        }
        if (lpSupply <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockDelta = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 toMintPerBlock = _getStakeToMintPerBlock();
        uint256 helixTokenReward = blockDelta * toMintPerBlock * pool.allocPoint / (totalAllocPoint);
        pool.accHelixTokenPerShare = pool.accHelixTokenPerShare + (helixTokenReward * (1e12) / (lpSupply));
        pool.lastRewardBlock = block.number;
        helixToken.mint(address(this), helixTokenReward);

        emit PoolUpdated(_pid);
    }

    // Deposit LP tokens to MasterChef for HelixToken allocation.
    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused isNotHelixPoolId(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount = user.amount + (_amount);
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);

        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(address(pool.lpToken), address(msg.sender), address(this), _amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external whenNotPaused isNotHelixPoolId(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "MasterChef: insufficient balance");

        updatePool(_pid);

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount -= _amount;
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);

        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Deposit _amount of lpToken into _bucketId and accrue yield by staking _amount to _poolId
    function bucketDeposit(
        uint256 _bucketId,          // Unique bucket to deposit _amount into
        uint256 _poolId,            // Pool to deposit _amount into
        uint256 _amount             // Amount of lpToken being deposited
    ) 
        external 
        whenNotPaused
        isNotHelixPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        updatePool(_poolId);

        // If the bucket already has already accrued rewards, 
        // increment the yield before resetting the rewardDebt
        if (bucket.amount > 0) {
            bucket.yield += bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        }
    
        // Update the bucket amount and reset the rewardDebt
        bucket.amount += _amount;
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);

        // Transfer amount of lpToken from caller to chef
        require(
            _amount <= pool.lpToken.allowance(msg.sender, address(this)), 
            "MasterChef: insufficient allowance"
        );
        TransferHelper.safeTransferFrom(address(pool.lpToken), msg.sender, address(this), _amount);

        emit BucketDeposit(msg.sender, _bucketId, _poolId, _amount);
    }

    // Withdraw _amount of lpToken and all accrued yield from _bucketId and _poolId
    function bucketWithdraw(uint256 _bucketId, uint256 _poolId, uint256 _amount) external whenNotPaused isNotHelixPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        require(_amount <= bucket.amount, "MasterChef: insufficient balance");

        updatePool(_poolId);
    
        // Calculate the total yield to withdraw
        uint256 pending = bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        uint256 yield = bucket.yield + pending;

        // Update the bucket state
        bucket.amount -= _amount;
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);
        bucket.yield = 0;

        // Withdraw the yield and lpToken
        refRegister.rewardStake(msg.sender, yield);
        safeHelixTokenTransfer(msg.sender, yield);
        TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);

        emit BucketWithdraw(msg.sender, _bucketId, _poolId, _amount);
    }

    // Withdraw _amount of lpToken from _bucketId and from _poolId
    // and send the withdrawn _amount to _recipient
    function bucketWithdrawAmountTo(
        address _recipient,
        uint256 _bucketId,
        uint256 _poolId, 
        uint256 _amount
    ) 
        external 
        whenNotPaused
        isNotZeroAddress(_recipient)
        isNotHelixPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];

        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];
        require(
            _amount <= bucket.amount, 
            "MasterChef: insufficient balance"
        );

        updatePool(_poolId);

        // Update the bucket state
        bucket.yield += bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        bucket.amount -= _amount;
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);

        // Transfer only lpToken to the recipient
        TransferHelper.safeTransfer(address(pool.lpToken), _recipient, _amount);

        emit BucketWithdrawAmountTo(msg.sender, _recipient, _bucketId, _poolId, _amount);
    }

    // Withdraw total yield in HelixToken from _bucketId and _poolId and send to _recipient
    function bucketWithdrawYieldTo(
        address _recipient,
        uint256 _bucketId,
        uint256 _poolId,
        uint256 _yield
    ) 
        external 
        whenNotPaused
        isNotZeroAddress(_recipient)
        isNotHelixPoolId(_poolId)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        updatePool(_poolId);

        // Total yield is any pending yield plus any previously calculated yield
        uint256 pending = bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        uint256 yield = bucket.yield + pending;

        require(
            _yield <= yield,
            "MasterChef: insufficient balance"
        );

        // Update bucket state
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);
        yield -= _yield;

        refRegister.rewardStake(msg.sender, yield);
        safeHelixTokenTransfer(_recipient, _yield);

        emit BucketWithdrawYieldTo(msg.sender, _recipient, _bucketId, _poolId, _yield);
    }

    // Update _poolId and _bucketId yield and rewardDebt
    function updateBucket(uint256 _bucketId, uint256 _poolId) external isNotHelixPoolId(_poolId) {
        PoolInfo storage pool = poolInfo[_poolId];
        BucketInfo storage bucket = bucketInfo[_poolId][msg.sender][_bucketId];

        updatePool(_poolId);

        bucket.yield += bucket.amount * (pool.accHelixTokenPerShare) / (1e12) - (bucket.rewardDebt);
        bucket.rewardDebt = bucket.amount * (pool.accHelixTokenPerShare) / (1e12);

        emit UpdateBucket(msg.sender, _bucketId, _poolId);
    }

    function getBucketYield(uint256 _bucketId, uint256 _poolId) 
        external 
        view 
        isNotHelixPoolId(_poolId)
        returns (uint256 yield) 
    {
        BucketInfo memory bucket = bucketInfo[_poolId][msg.sender][_bucketId];
        yield = bucket.yield;
    }

    // Stake HelixToken tokens to MasterChef
    function enterStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];

        updatePool(0);
        depositedHelix += _amount;

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount += _amount;
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);
        
        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(address(pool.lpToken), address(msg.sender), address(this), _amount);
        }

        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw HelixToken tokens from STAKING.
    function leaveStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];

        updatePool(0);
        depositedHelix -= _amount;

        require(user.amount >= _amount, "MasterChef: insufficient balance");

        uint256 pending = user.amount * (pool.accHelixTokenPerShare) / (1e12) - (user.rewardDebt);
        user.amount -= _amount;
        user.rewardDebt = user.amount * (pool.accHelixTokenPerShare) / (1e12);

        if (pending > 0) {
            refRegister.rewardStake(msg.sender, pending);
            safeHelixTokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);
        }

        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        TransferHelper.safeTransfer(address(pool.lpToken), address(msg.sender), _amount);

        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    /// Return the portion of toMintPerBlock assigned to staking and farms
    function getStakeToMintPerBlock() external view returns (uint256) {
        return _getStakeToMintPerBlock();
    }

    /// Return the portion of toMintPerBlock assigned to dev team
    function getDevToMintPerBlock() external view returns (uint256) {
        return _getDevToMintPerBlock();
    }

    /// Return the toMintPerBlock rate assigned to this contract by the feeMinter
    function getToMintPerBlock() external view returns (uint256) {
        return _getToMintPerBlock();
    }
    // Safe HelixToken transfer function, just in case if rounding error causes pool to not have enough HelixTokens.
    function safeHelixTokenTransfer(address _to, uint256 _amount) internal {
        uint256 helixTokenBal = helixToken.balanceOf(address(this));
        uint256 toTransfer = _amount > helixTokenBal ? helixTokenBal : _amount;
        require(helixToken.transfer(_to, toTransfer), "MasterChef: transfer failed");
    }

    function setDevAddress(address _devaddr) external onlyTimelock {
        devaddr = _devaddr;
        emit DevAddressSet(_devaddr);
    }

    function setFeeMinter(address _feeMinter) external onlyTimelock {
        feeMinter = IFeeMinter(_feeMinter);
        emit SetFeeMinter(msg.sender, _feeMinter);
    }

    // Return the portion of toMintPerBlock assigned to staking and farms
    function _getStakeToMintPerBlock() private view returns (uint256) {
        return _getToMintPerBlock() * stakingPercent / percentDec;
    }

    // Return the portion of toMintPerBlock assigned to dev team
    function _getDevToMintPerBlock() private view returns (uint256) {
        return _getToMintPerBlock() * devPercent / percentDec;
    }

    // Return the toMintPerBlock rate assigned to this contract by the feeMinter
    function _getToMintPerBlock() private view returns (uint256) {
        require(address(feeMinter) != address(0), "MasterChef: fee minter unassigned");
        return feeMinter.getToMintPerBlock(address(this));
    }

    function setDevAndStakingPercents(uint256 _devPercent, uint256 _stakingPercent) external onlyOwner {
        require(_stakingPercent + _devPercent == 1000000, "MasterChef: invalid percents");
        stakingPercent = _stakingPercent;
        devPercent = _devPercent;
    }
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

// Copied and modified from YAM code:
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
// Which is copied and modified from COMPOUND:
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

import "../libraries/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// Geometry governance token
contract HelixToken is ERC20("Helix", "HELIX") {
    using EnumerableSet for EnumerableSet.AddressSet;

    // @notice Checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // Set of addresses which can mint HELIX
    EnumerableSet.AddressSet private _minters;
 
    /// @dev A record of each accounts delegate
    mapping(address => address) internal _delegates;

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event that's emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event that's emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Helix: not minter");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Helix: zero address");
        _;
    }

    /// @notice Creates _amount of token to _to.
    function mint(address _to, uint256 _amount)
        external 
        onlyMinter
        returns (bool)
    {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
        return true;
    }

    /// @notice Destroys _amount tokens from _account reducing the total supply
    function burn(address _account, uint256 _amount) external onlyMinter {
        _burn(_account, _amount);
    }

    /// @notice Delegate votes from msg.sender to _delegatee
    /// @param _delegatee The address to delegate votes to
    function delegate(address _delegatee) external {
        return _delegate(msg.sender, _delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param _delegatee The address to delegate votes to
     * @param _nonce The contract state required to match the signature
     * @param _expiry The time at which to expire the signature
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address _delegatee,
        uint256 _nonce,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                _getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, _delegatee, _nonce, _expiry)
        );

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, _v, _r, _s);

        require(signatory != address(0), "Helix: invalid signature");
        require(_nonce == nonces[signatory]++, "Helix: invalid nonce");
        require(block.timestamp <= _expiry, "Helix: signature expired");

        return _delegate(signatory, _delegatee);
    }

    /**
     * @dev used by owner to delete minter of token
     * @param _delMinter address of minter to be deleted.
     * @return true if successful.
     */
    function delMinter(address _delMinter) external onlyOwner onlyValidAddress(_delMinter) returns (bool) {
        return EnumerableSet.remove(_minters, _delMinter);
    }

    /// @notice Delegate votes from msg.sender to _delegatee
    /// @param _delegator The address to get delegatee for
    function delegates(address _delegator) external view returns (address) {
        return _delegates[_delegator];
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param _account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address _account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[_account];
        return
            nCheckpoints > 0 ? checkpoints[_account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber)
        external
        view
        returns (uint256)
    {
        require(_blockNumber < block.number, "Helix: invalid blockNumber");

        uint32 nCheckpoints = numCheckpoints[_account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][nCheckpoints - 1].fromBlock <= _blockNumber) {
            return checkpoints[_account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].fromBlock > _blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.fromBlock == _blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @dev used by get the minter at n location
     * @param _index index of address set
     * @return address of minter at index.
     */
    function getMinter(uint256 _index)
        external
        view
        onlyOwner
        returns (address)
    {
        require(_index <= getMinterLength() - 1, "Helix: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    /**
     * @dev used by owner to add minter of token
     * @param _addMinter address of minter to be added.
     * @return true if successful.
     */
    function addMinter(address _addMinter) public onlyOwner onlyValidAddress(_addMinter) returns (bool) {
        return EnumerableSet.add(_minters, _addMinter);
    }

    /// @dev used to get the number of minters for this token
    /// @return number of minters.
    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    /// @dev used to check if an address is a minter of token
    /// @return true or false based on minter status.
    function isMinter(address _account) public view returns (bool) {
        return EnumerableSet.contains(_minters, _account);
    }

    // internal function used delegate votes
    function _delegate(address _delegator, address _delegatee) internal {
        address currentDelegate = _delegates[_delegator];
        uint256 delegatorBalance = balanceOf(_delegator); // balance of underlying HELIXs (not scaled);
        _delegates[_delegator] = _delegatee;

        emit DelegateChanged(_delegator, currentDelegate, _delegatee);

        _moveDelegates(currentDelegate, _delegatee, delegatorBalance);
    }

    // send delegate votes from src to dst in amount
    function _moveDelegates(
        address _srcRep,
        address _dstRep,
        uint256 _amount
    ) internal {
        if (_srcRep != _dstRep && _amount > 0) {
            if (_srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[_srcRep];
                uint256 srcRepOld = srcRepNum > 0
                    ? checkpoints[_srcRep][srcRepNum - 1].votes
                    : 0;
                uint256 srcRepNew = srcRepOld - _amount;
                _writeCheckpoint(_srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (_dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[_dstRep];
                uint256 dstRepOld = dstRepNum > 0
                    ? checkpoints[_dstRep][dstRepNum - 1].votes
                    : 0;
                uint256 dstRepNew = dstRepOld + _amount;
                _writeCheckpoint(_dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint32 _nCheckpoints,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = _safe32(
            block.number,
            "HELIX::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            _nCheckpoints > 0 &&
            checkpoints[_delegatee][_nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[_delegatee][_nCheckpoints - 1].votes = _newVotes;
        } else {
            checkpoints[_delegatee][_nCheckpoints] = Checkpoint(
                blockNumber,
                _newVotes
            );
            numCheckpoints[_delegatee] = _nCheckpoints + 1;
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    // @dev used get current chain ID
    // @return id as a uint
    function _getChainId() internal view returns (uint256 id) {
        id = block.chainid;
    }

    /*
     * @dev Checks if value is 32 bits
     * @param _n value to be checked
     * @param _errorMessage error message to throw if fails
     * @return The number if valid.
     */
    function _safe32(uint256 _n, string memory _errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(_n < 2**32, _errorMessage);
        return uint32(_n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IHelixToken.sol";

interface IReferralRegister {
    function toMintPerBlock() external view returns (uint256);
    function helixToken() external view returns (IHelixToken);
    function stakeRewardPercent() external view returns (uint256);
    function swapRewardPercent() external view returns (uint256);
    function lastMintBlock() external view returns (uint256);
    function referrers(address _referred) external view returns (address);
    function rewards(address _referrer) external view returns (uint256);

    function initialize(
        IHelixToken _helixToken, 
        address _feeHandler,
        uint256 _stakeRewardPercent, 
        uint256 _swapRewardPercent,
        uint256 _toMintPerBlock,
        uint256 _lastMintBlock
    ) external; 

    function rewardStake(address _referred, uint256 _stakeAmount) external;
    function rewardSwap(address _referred, uint256 _swapAmount) external;
    function withdraw() external;
    function setToMintPerBlock(uint256 _toMintPerBlock) external;
    function setStakeRewardPercent(uint256 _stakeRewardPercent) external;
    function setSwapRewardPercent(uint256 _swapRewardPercent) external;
    function addReferrer(address _referrer) external;
    function removeReferrer() external;
    function update() external;
    function addRecorder(address _recorder) external returns (bool);
    function removeRecorder(address _recorder) external returns (bool);
    function setLastRewardBlock(uint256 _lastMintBlock) external;
    function pause() external;
    function unpause() external;
    function setFeeHandler(address _feeHandler) external;
    function setCollectorPercent(uint256 _collectorPercent) external;
    function getRecorder(uint256 _index) external view returns (address);
    function getRecorderLength() external view returns (uint256);
    function isRecorder(address _address) external view returns (bool);
}

// SPDX-License-Identifer: MIT
pragma solidity >=0.8.0;

interface IFeeMinter {
    function totalToMintPerBlock() external view returns (uint256);
    function minters(uint256 index) external view returns (address);
    function setTotalToMintPerBlock(uint256 _totalToMintPerBlock) external;
    function setToMintPercents(address[] calldata _minters, uint256[] calldata _toMintPercents) external;
    function getToMintPerBlock(address _minter) external view returns (uint256);
    function getMinters() external view returns (address[] memory);
    function getToMintPercent(address _minter) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract OwnableTimelockUpgradeable is Initializable, ContextUpgradeable {
    error CallerIsNotTimelockOwner();
    error ZeroTimelockAddress();

    address private _timelockOwner;

    event TimelockOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OwnableTimelock_init() internal onlyInitializing {
        __OwnableTimelock_init_unchained();
    }

    function __OwnableTimelock_init_unchained() internal onlyInitializing {
        _transferTimelockOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyTimelock() {
        _checkTimelockOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function timelockOwner() public view virtual returns (address) {
        return _timelockOwner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkTimelockOwner() internal view virtual {
        if (timelockOwner() != _msgSender()) revert CallerIsNotTimelockOwner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceTimelockOwnership() public virtual onlyTimelock {
        _transferTimelockOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferTimelockOwnership(address newOwner) public virtual onlyTimelock {
        if (newOwner == address(0)) revert ZeroTimelockAddress();
        _transferTimelockOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferTimelockOwnership(address newOwner) internal virtual {
        address oldOwner = _timelockOwner;
        _timelockOwner = newOwner;
        emit TimelockOwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    uint256 private constant _maxSupply = 1000000000 * 1e18;        // 1B
    uint256 private constant _preMineSupply = 0;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;

        _mint(msg.sender, _preMineSupply); // mint token to msg owner
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token symbol.
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @notice supply that was mented to the contract owner.
     */

    function preMineSupply() public pure returns (uint256) {
        return _preMineSupply;
    }

    /**
     * @notice max supply that can eer be minted.
     */
    function maxSupply() public pure returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        if (amount + _totalSupply > _maxSupply) {
            revert();
            // return false;
        }

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal virtual {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()] - amount
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHelixToken {
    function mint(address to, uint256 amount) external returns(bool);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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