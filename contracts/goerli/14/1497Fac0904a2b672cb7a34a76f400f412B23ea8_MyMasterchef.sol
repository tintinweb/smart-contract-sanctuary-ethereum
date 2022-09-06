// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KCP.sol";
import "./RDX.sol";

contract MyMasterchef {
    struct UserInfo {
        uint256 amount; // total KCP token user provided
        uint256 rewardDebt;
        uint256 reward; // actual reward earn
    }

    struct PoolInfo {
        KCP kcpToken; // Address of KCP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. RDX to distribute per block.
        uint256 lastRewardBlock; // Last block number that RDX distribution occurs.
        uint256 accRdxPerShare; // Accumulated RDX per share
    }

    // RDX token - reward token
    RDX public rdx;

    // RDX23 tokens created per block.
    uint256 public rdxPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes KCP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when RDX staking starts.
    uint256 public startBlock;

    address public owner;

    event UpdatePool(uint256 pid, uint256 rdxReward, uint256 accRdxPerShare);
    event Claim(uint256 pid, uint256 rdxReward, uint256 accRdxPerShare);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        RDX _rdx,
        uint256 _rdxPerBlock,
        uint256 _startBlock
    ) {
        owner = msg.sender;
        rdx = _rdx;
        rdxPerBlock = _rdxPerBlock * 10**18; // in decimals
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add new liquidity to the pool. Can be called by the owner.
    function add(uint256 _allocPoint, KCP _kcpToken) public {
        require(msg.sender == owner, "Caller is not the owner!");
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                kcpToken: _kcpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRdxPerShare: 0
            })
        );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // for case 1st deposit
        uint256 lpSupply = pool.kcpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 rdxReward = (block.number - pool.lastRewardBlock) *
            rdxPerBlock *
            (pool.allocPoint / totalAllocPoint);
        // Ignored step: minted RDX token for Masterchef: RDX token must be transfered manual to Masterchef before
        // update pool: accRdxPerShare, lastRewardBlock
        pool.accRdxPerShare += ((rdxReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
        emit UpdatePool(_pid, rdxReward, lpSupply);
    }

    // View function to see pending RDX on frontend.
    function pendingRdx(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accRdxPerShare = pool.accRdxPerShare;
        uint256 lpSupply = pool.kcpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rdxReward = ((block.number - pool.lastRewardBlock) *
                rdxPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRdxPerShare = accRdxPerShare + ((rdxReward * 1e12) / lpSupply);
        }
        return
            user.reward +
            (user.amount * accRdxPerShare) /
            1e12 -
            user.rewardDebt;
    }

    // claim pending reward RDX
    function claimPendingRdx(uint256 _pid, uint256 _amount) public {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            1e12 -
            user.rewardDebt;
        // update rewardDebt
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 1e12;
        // update reward
        user.reward = user.reward + pending - _amount;
        // transfer token
        safeRdxTransfer(msg.sender, _amount);
        emit Claim(_pid, user.reward, pool.accRdxPerShare);
    }

    // Deposit KCP tokens to MasterChef for RDX allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // transfer kcpToken
        pool.kcpToken.transferFrom(address(msg.sender), address(this), _amount);
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            1e12 -
            user.rewardDebt;
        // update amount staking
        user.amount = user.amount + _amount;
        // update reward
        user.reward = user.reward + pending;
        // update rewardDebt
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw KCP tokens and all unclaimed RDX from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        updatePool(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "exceeds withdrawal limit");
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            1e12 -
            user.rewardDebt;
        // withdraw all reward
        safeRdxTransfer(msg.sender, user.reward + pending);
        user.amount = user.amount - _amount;
        user.reward = 0; // reset reward to zero
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 1e12;
        pool.kcpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Safe transfer function, check case if not enough balance for transfer
    function safeRdxTransfer(address _to, uint256 _amount) internal {
        uint256 rdxBal = rdx.balanceOf(address(this));
        if (_amount > rdxBal) {
            rdx.transfer(_to, rdxBal);
        } else {
            rdx.transfer(_to, _amount);
        }
    }
}