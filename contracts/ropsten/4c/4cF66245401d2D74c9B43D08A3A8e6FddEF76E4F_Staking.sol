// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.10;

import "../SafeMath.sol";
import "../IERC20.sol";
// import "./SafeBEP20.sol";
// import "./Ownable.sol";
import "../AuthorityControlled.sol";

import "./IChimp.sol";

// Staking is the master of Chimp. He can make Chimp and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Chimp is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Staking is AuthorityControlled {
    using SafeMath for uint256;

    // Info of each user.
    struct StakeInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 totalReward;    // Total reward
        //
        // We do some fancy math here. Basically, any point in time, the amount of Chimps
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accChimpPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accChimpPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // 用户质押/赎回明细记录
    struct StakeRecord {
        // 质押钱包地址
        address addr;
        // 当前质押数量
        uint256 amount;
        // 操作类型，1=质押，2=赎回
        uint8 opType;
        // 本次领取收益
        uint256 reward;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Chimps to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Chimps distribution occurs.
        uint256 accChimpPerShare;   // Accumulated Chimps per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        // uint256 totalStake; // The total amount of current stake
    }

    // The Chimp TOKEN!
    IChimp public chimp;
    // Dev address.
    address public devaddr;
    // Chimp tokens created per block.
    uint256 public chimpPerBlock;
    // Bonus muliplier for early chimp makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfos;
    // Info of each user that stakes LP tokens.(uint256是pid，address是用户的钱包地址)
    mapping (uint256 => mapping (address => StakeInfo)) public stakeInfos;
    // 用户质押/赎回记录(uint256是pid)
    mapping (uint256 => StakeRecord[]) public stakeRecords;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Chimp mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor (
        IChimp _chimp,
        address _devaddr,
        address _feeAddress,
        uint256 _chimpPerBlock,
        uint256 _startBlock,
        address authority_
    ) AuthorityControlled(authority_) {
        chimp = _chimp;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        chimpPerBlock = _chimpPerBlock;
        startBlock = _startBlock;
    }

    // Returns the total length of the pool
    function poolLength() external view returns (uint256) {
        return poolInfos.length;
    }

    // Returns the total stake/unstake length of a pool
    function pidRecordLength(uint256 _pid) external view returns (uint256) {
        return stakeRecords[_pid].length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyManager {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfos.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accChimpPerShare: 0,
            depositFeeBP: _depositFeeBP//,
            // totalStake: 0
        }));
    }

    // Update the given pool's Chimp allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyManager {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfos[_pid].allocPoint).add(_allocPoint);
        poolInfos[_pid].allocPoint = _allocPoint;
        poolInfos[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Chimps on frontend.
    function pendingChimp(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][_user];
        uint256 accChimpPerShare = pool.accChimpPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // LP小数位一般为18位，单币质押由于平台币小数位为6位，小数位需要做处理
        uint256 decimals = pool.lpToken.decimals() < 18 ? 10**(18 - pool.lpToken.decimals()) : 1;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 chimpReward = multiplier.mul(chimpPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accChimpPerShare = accChimpPerShare.add(chimpReward.mul(decimals).div(lpSupply));
        }
        return user.amount.mul(accChimpPerShare).div(decimals).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 chimpReward = multiplier.mul(chimpPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        chimp.mint(devaddr, chimpReward.div(10));
        chimp.mint(address(this), chimpReward);
        // LP小数位一般为18位，单币质押由于平台币小数位为6位，小数位需要做处理
        uint256 decimals = pool.lpToken.decimals() < 18 ? 10**(18 - pool.lpToken.decimals()) : 1;
        pool.accChimpPerShare = pool.accChimpPerShare.add(chimpReward.mul(decimals).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Staking for Chimp allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending;
        // LP小数位一般为18位，单币质押由于平台币小数位为6位，小数位需要做处理
        uint256 decimals = pool.lpToken.decimals() < 18 ? 10**(18 - pool.lpToken.decimals()) : 1;
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accChimpPerShare).div(decimals).sub(user.rewardDebt);
            if(pending > 0) {
                safeChimpTransfer(msg.sender, pending);
                user.totalReward = user.totalReward.add(pending);
            }
        }
        uint256 _realAmount = _amount;
        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.transfer(feeAddress, depositFee);
                _realAmount = _realAmount.sub(depositFee);
                user.amount = user.amount.add(_realAmount);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        // pool.totalStake = pool.totalStake.add(_realAmount);
        user.rewardDebt = user.amount.mul(pool.accChimpPerShare).div(decimals);
        // 保存质押/赎回明细记录
        stakeRecords[_pid].push(StakeRecord({addr: msg.sender, amount: _realAmount, opType: 1, reward: pending}));
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Staking.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        // LP小数位一般为18位，单币质押由于平台币小数位为6位，小数位需要做处理
        uint256 decimals = pool.lpToken.decimals() < 18 ? 10**(18 - pool.lpToken.decimals()) : 1;
        uint256 pending = user.amount.mul(pool.accChimpPerShare).div(decimals).sub(user.rewardDebt);
        if(pending > 0) {
            safeChimpTransfer(msg.sender, pending);
            user.totalReward = user.totalReward.add(pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        // pool.totalStake = pool.totalStake.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accChimpPerShare).div(decimals);
        // 保存质押/赎回明细记录
        stakeRecords[_pid].push(StakeRecord({addr: msg.sender, amount: _amount, opType: 2, reward: pending}));
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.transfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe chimp transfer function, just in case if rounding error causes pool to not have enough Chimps.
    function safeChimpTransfer(address _to, uint256 _amount) internal {
        uint256 chimpBal = chimp.balanceOf(address(this));
        if (_amount > chimpBal) {
            chimp.transfer(_to, chimpBal);
        } else {
            chimp.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function setDev(address _devaddr) public onlyManager {
        require(address(0) != devaddr, "dev: dev can't be null address");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public onlyManager {
        require(address(0) == feeAddress, "setFeeAddress: feeAddress can't be null address");
        feeAddress = _feeAddress;
    }

    function setChimp(address _chimp) public onlyManager {
        require(address(0) == feeAddress, "setChimp: chimp can't be null address");
        chimp = IChimp(_chimp);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function setChimpPerBlock(uint256 _chimpPerBlock) public onlyManager {
        massUpdatePools();
        chimpPerBlock = _chimpPerBlock;
    }
}