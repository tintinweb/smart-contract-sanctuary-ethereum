// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./AlphaToken.sol";
import "./AlphaLocker.sol";


interface IMigratorAlpha {
    // Perform LP token migration from legacy UniswapV2 to EdenSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // EdenSwap must mint EXACTLY the same amount of EdenSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// TopDog is the master of Bone. He can make Bone and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once BONE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract Masterchef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ALPHAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBonePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBonePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. ALPHAs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that ALPHAs distribution occurs.
        uint256 accBonePerShare; // Accumulated ALPHAs per share, times 1e12. See below.
    }

    // The Alpha TOKEN!
    AlphaToken public alpha;
    // The Bone Token Locker contract
    AlphaLocker public alphaLocker;
    // Dev address.
    address public devAlphaDistributor;

    address public tAlphaAlphaDistributor;
    address public xParaAlphaDistributor;
    address public xOmegaAlphaDistributor;

    uint256 public devPercent;
    uint256 public tAlphaPercent;
    uint256 public xParaPercent;
    uint256 public xOmegaPercent;

    // Block number when bonus BONE period ends.
    uint256 public bonusEndBlock;
    // BONE tokens created per block.
    uint256 public bonePerBlock;
    // Bonus muliplier for early bone makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorAlpha public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when BONE mining starts.
    uint256 public startBlock;
    // reward percentage to be sent to user directly
    uint256 public rewardMintPercent;
    // devReward percentage to be sent to user directly
    uint256 public devRewardMintPercent;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event RewardPerBlock(address indexed user, uint _newReward);
    event SetAddress(string indexed which, address indexed user, address newAddr);
    event SetPercent(string indexed which, address indexed user, uint256 newPercent);


    constructor(
        AlphaToken _alpha,
        AlphaLocker _alphaLocker,
        address _devAlphaDistributor,
        address _tAlphaAlphaDistributor,
        address _xParaAlphaDistributor,
        address _xOmegaAlphaDistributor,
        uint256 _bonePerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _rewardMintPercent,
        uint256 _devRewardMintPercent
    ) public {
        require(address(_alpha) != address(0), "_alpha is a zero address");
        require(address(_alphaLocker) != address(0), "_alphaLocker is a zero address");
        alpha = _alpha;
        alphaLocker = _alphaLocker;
        devAlphaDistributor = _devAlphaDistributor;
        bonePerBlock = _bonePerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;

        tAlphaAlphaDistributor = _tAlphaAlphaDistributor;
        xParaAlphaDistributor = _xParaAlphaDistributor;
        xOmegaAlphaDistributor = _xOmegaAlphaDistributor;

        rewardMintPercent = _rewardMintPercent;
        devRewardMintPercent = _devRewardMintPercent;

        devPercent = 10;
        tAlphaPercent = 1;
        xParaPercent = 3;
        xOmegaPercent = 1;
    } 

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated lpToken");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accBonePerShare: 0
        }));
    }

    // update Reward Rate
    function updateRewardPerBlock(uint256 _perBlock) public onlyOwner {
        massUpdatePools();
        bonePerBlock = _perBlock;
        emit RewardPerBlock(msg.sender, _perBlock);
    }

    // Update the given pool's BONE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorAlpha _migrator) public onlyOwner {
        migrator = _migrator;
        emit SetAddress("Migrator", msg.sender, address(_migrator));
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_from < startBlock) {
            _from = startBlock;
        }
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending ALPHAs on frontend.
    function pendingBone(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBonePerShare = pool.accBonePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 boneReward = multiplier.mul(bonePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accBonePerShare = accBonePerShare.add(boneReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accBonePerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
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
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 boneReward = multiplier.mul(bonePerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        uint256 devBoneReward = boneReward.mul(devPercent).div(100); // devPercent rewards to dev address
        alpha.mint(devAlphaDistributor, devBoneReward.mul(devRewardMintPercent).div(100)); // partial devPercent rewards to dev address

        alpha.mint(address(alphaLocker), devBoneReward.sub(devBoneReward.mul(devRewardMintPercent).div(100))); // rest devPercent rewards locked to bone token contract
        alphaLocker.lock(devAlphaDistributor, devBoneReward.sub(devBoneReward.mul(devRewardMintPercent).div(100)), true);

        alpha.mint(tAlphaAlphaDistributor, boneReward.mul(tAlphaPercent).div(100)); // tAlphaPercent rewards to tBoneBoneDistributor address
        alpha.mint(xParaAlphaDistributor, boneReward.mul(xParaPercent).div(100)); // xParaPercent rewards to xParaAlphaDistributor address
        alpha.mint(xOmegaAlphaDistributor, boneReward.mul(xOmegaPercent).div(100)); // xOmegaPercent rewards to xOmegaAlphaDistributor address
        alpha.mint(address(this), boneReward);

        pool.accBonePerShare = pool.accBonePerShare.add(boneReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to TopDog for BONE allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accBonePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                // safeBoneTransfer(msg.sender, pending);
                uint256 sendAmount = pending.mul(rewardMintPercent).div(100);
                safeBoneTransfer(msg.sender, sendAmount);
                safeBoneTransfer(address(alphaLocker), pending.sub(sendAmount)); // Rest amount sent to Bone token contract
                alphaLocker.lock(msg.sender, pending.sub(sendAmount), false); //function called for token time-lock
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBonePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from TopDog.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBonePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
                uint256 sendAmount = pending.mul(rewardMintPercent).div(100);
                safeBoneTransfer(msg.sender, sendAmount);
                safeBoneTransfer(address(alphaLocker), pending.sub(sendAmount)); // Rest amount sent to Bone token contract
                alphaLocker.lock(msg.sender, pending.sub(sendAmount), false); //function called for token time-lock
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBonePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe bone transfer function, just in case if rounding error causes pool to not have enough ALPHAs.
    function safeBoneTransfer(address _to, uint256 _amount) internal {
        uint256 boneBal = alpha.balanceOf(address(this));
        if (_amount > boneBal) {
            alpha.transfer(_to, boneBal);
        } else {
            alpha.transfer(_to, _amount);
        }
    }

    // Update boneLocker address by the owner.
    function boneLockerUpdate(address _alphaLocker) public onlyOwner {
        alphaLocker = AlphaLocker(_alphaLocker);
    }

    // Update dev bone distributor address by the owner.
    function devBoneDistributorUpdate(address _devAlphaDistributor) public onlyOwner {
        devAlphaDistributor = _devAlphaDistributor;
    }

    // Update rewardMintPercent value, currently set to 33%, called by the owner
    function setRewardMintPercent(uint256 _newPercent) public onlyOwner{
        rewardMintPercent = _newPercent;
        emit SetPercent("RewardMint", msg.sender, _newPercent);
    }

    // Update devRewardMintPercent value, currently set to 50%, called by the owner
    function setDevRewardMintPercent(uint256 _newPercent) public onlyOwner{
        devRewardMintPercent = _newPercent;
        emit SetPercent("DevRewardMint", msg.sender, _newPercent);
    }

    // Update locking period for users and dev
    function setLockingPeriod(uint256 _newLockingPeriod, uint256 _newDevLockingPeriod) public onlyOwner{
        alphaLocker.setLockingPeriod(_newLockingPeriod, _newDevLockingPeriod);
    }

    // Call emergency withdraw to transfer bone tokens to any other address, onlyOwner function
    function callEmergencyWithdraw(address _to) public onlyOwner{
        alphaLocker.emergencyWithdrawOwner(_to);
    }

    // Update tBoneBoneDistributor address by the owner.
    function tBoneBoneDistributorUpdate(address _tAlphaAlphaDistributor) public onlyOwner {
        tAlphaAlphaDistributor = _tAlphaAlphaDistributor;
        emit SetAddress("tAlpha-AlphaDistributor", msg.sender, _tAlphaAlphaDistributor);
    }

    // Update xParaAlphaDistributor address by the owner.
    function xParaAlphaDistributorUpdate(address _xParaAlphaDistributor) public onlyOwner {
        xParaAlphaDistributor = _xParaAlphaDistributor;
        emit SetAddress("xShib-BoneDistributor", msg.sender, _xParaAlphaDistributor);
    }

    // Update xOmegaAlphaDistributor address by the owner.
    function xOmegaAlphaDistributorUpdate(address _xOmegaAlphaDistributor) public onlyOwner {
        xOmegaAlphaDistributor = _xOmegaAlphaDistributor;
        emit SetAddress("xLeash-BoneDistributor", msg.sender, _xOmegaAlphaDistributor);
    }

    // Update devPercent by the owner.
    function devPercentUpdate(uint _devPercent) public onlyOwner {
        require(_devPercent <= 10, "topDog: Percent too high");
        devPercent = _devPercent;
        emit SetPercent("Dev share", msg.sender, _devPercent);
    }

    // Update tAlphaPercent by the owner.
    function tAlphaPercentUpdate(uint _tAlphaPercent) public onlyOwner {
        tAlphaPercent = _tAlphaPercent;
        emit SetPercent("tBone share", msg.sender, _tAlphaPercent);
    }

    // Update xParaPercent by the owner.
    function xParaPercentUpdate(uint _xParaPercent) public onlyOwner {
        xParaPercent = _xParaPercent;
        emit SetPercent("xShib share", msg.sender, _xParaPercent);
    }

    // Update xOmegaPercent by the owner.
    function xOmegaPercentUpdate(uint _xOmegaPercent) public onlyOwner {
        xOmegaPercent = _xOmegaPercent;
        emit SetPercent("xLeash share", msg.sender, _xOmegaPercent);
    }
}