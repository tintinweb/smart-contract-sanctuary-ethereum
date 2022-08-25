// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ketchup.sol";
import "./RDX.sol";

contract MyMasterchef {
    struct UserInfo {
        uint256 amount; // total KCP token user provided
        uint256 rewardDebt;
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
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        RDX _rdx,
        uint256 _rdxPerBlock,
        uint256 _startBlock
    ) {
        owner = msg.sender;
        rdx = _rdx;
        rdxPerBlock = _rdxPerBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add new liquidity to the pool. Can be called by the owner.
    function add(uint256 _allocPoint, KCP _kcpToken) public {
        require(
            msg.sender == owner,
            "Caller is not the owner!"
        );
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

    // View function to see pending RDX on frontend.
    function pendingRdx(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRdxPerShare = pool.accRdxPerShare;
        uint256 lpSupply = pool.kcpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 rdxReward = ((block.number - pool.lastRewardBlock) *
                rdxPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRdxPerShare = accRdxPerShare + ((rdxReward * 10**18) / lpSupply);
        }
        return (user.amount * accRdxPerShare) / 10**18 - user.rewardDebt;
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
        uint256 rdxReward = ((block.number - pool.lastRewardBlock) *
            rdxPerBlock *
            pool.allocPoint) / totalAllocPoint;
        // Ignored step: minted RDX token for Masterchef: RDX token must be transfered manual to Masterchef before
        // update pool: accRdxPerShare, lastRewardBlock
        pool.accRdxPerShare =
            pool.accRdxPerShare +
            ((rdxReward * 10**18) / lpSupply);
        pool.lastRewardBlock = block.number;
        emit UpdatePool(_pid, rdxReward, lpSupply);
    }

    // claim pending reward RDX
    function claimPendingRdx(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 claimRdx = (user.amount * pool.accRdxPerShare) /
            10**18 -
            user.rewardDebt;
        // update rewardDebt
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 10**18;
        // transfer token
        safeRdxTransfer(msg.sender, claimRdx);
        emit Claim(_pid, claimRdx, pool.accRdxPerShare);
    }

    // Deposit KCP tokens to MasterChef for RDX allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        // transfer kcpToken
        pool.kcpToken.transferFrom(address(msg.sender), address(this), _amount);
        // update amount staking
        user.amount = user.amount + _amount;
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 10**18;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw KCP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (user.amount * pool.accRdxPerShare) /
            10**18 -
            user.rewardDebt;
        safeRdxTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = (user.amount * pool.accRdxPerShare) / 10**18;
        pool.kcpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.kcpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
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