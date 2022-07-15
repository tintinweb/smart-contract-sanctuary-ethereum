// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IBoostToken.sol";
import "./interfaces/IStrikeBoostFarm.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IVStrike.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/EnumerableSet.sol";
import "./libraries/SafeMath.sol";
import "./libraries/Ownable.sol";
import "./libraries/ReentrancyGuard.sol";

// StrikeFarm is the master of Farm.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once STRIKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract StrikeBoostFarm is IStrikeBoostFarm, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 pendingAmount; // non-eligible lp amount for reward
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositedDate; // Latest deposited date
        //
        // We do some fancy math here. Basically, any point in time, the amount of STRIKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        uint256[] boostFactors;
        uint256 boostRewardDebt; // Boost Reward debt. See explanation below.
        uint256 boostedDate; // Latest boosted date
        uint256 accBoostReward;
        uint256 accBaseReward;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. STRIKEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that STRIKEs distribution occurs.
        uint256 accRewardPerShare; // Accumulated STRIKEs per share, times 1e12. See below.
        uint256 totalBoostCount; // Total valid boosted accounts count.
        uint256 rewardEligibleSupply; // total LP supply of users which staked boost token.
    }
    // The STRIKE TOKEN!
    address public strk;
    // The vSTRIKE TOKEN!
    address public vStrk;
    // The Reward TOKEN!
    address public rewardToken;
    // Block number when bonus STRIKE period ends.
    uint256 public bonusEndBlock;
    // STRIKE tokens created per block.
    uint256 public rewardPerBlock;
    // Bonus muliplier for early STRIKEex makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // VSTRIKE minting rate
    uint256 public constant VSTRK_RATE = 10;
    // Info of each pool.
    PoolInfo[] private poolInfo;
    // Total STRIKE amount deposited in STRIKE single pool. To reduce tx-fee, not included in struct PoolInfo.
    uint256 private lpSupplyOfStrikePool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // claimable time limit for base reward
    uint256 public claimBaseRewardTime = 1 days;
    uint256 public unstakableTime = 2 days;
    uint256 public initialBoostMultiplier = 20;
    uint256 public boostMultiplierFactor = 10;

    // Boosting Part
    // Minimum vaild boost NFT count
    uint16 public minimumValidBoostCount = 1;
    // Maximum boost NFT count
    uint16 public maximumBoostCount = 20;
    // NFT contract for boosting
    IBoostToken public boostFactor;
    // Boosted with NFT or not
    mapping (uint256 => bool) public isBoosted;
    // claimable time limit for boost reward
    uint256 public claimBoostRewardTime = 30 days;
    // boosted user list
    mapping(uint256 => address[]) private boostedUsers;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when STRIKE mining starts.
    uint256 public startBlock;
    uint256 private accMulFactor = 1e12;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event ClaimBaseRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event ClaimBoostRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Boost(address indexed user, uint256 indexed pid, uint256 tokenId);
    event UnBoost(address indexed user, uint256 indexed pid, uint256 tokenId);

    constructor(
        address _strk,
        address _rewardToken,
        address _vStrk,
        address _boost,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        strk = _strk;
        rewardToken = _rewardToken;
        vStrk = _vStrk;
        boostFactor = IBoostToken(_boost);
        rewardPerBlock = _rewardPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    function getPoolInfo(uint _pid) external view returns (
        IERC20 lpToken,
        uint256 lpSupply,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint accRewardPerShare,
        uint totalBoostCount,
        uint256 rewardEligibleSupply
    ) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 amount;
        if (strk == address(pool.lpToken)) {
            amount = lpSupplyOfStrikePool;
        } else {
            amount = pool.lpToken.balanceOf(address(this));
        }
        return (
            pool.lpToken,
            amount,
            pool.allocPoint,
            pool.lastRewardBlock,
            pool.accRewardPerShare,
            pool.totalBoostCount,
            pool.rewardEligibleSupply
        );
    }

    function getUserInfo(uint256 _pid, address _user) external view returns(
        uint256 amount,
        uint256 pendingAmount,
        uint256 rewardDebt,
        uint256 depositedDate,
        uint256[] memory boostFactors,
        uint256 boostRewardDebt,
        uint256 boostedDate,
        uint256 accBoostReward,
        uint256 accBaseReward
    ) {
        UserInfo storage user = userInfo[_pid][_user];

        return (
            user.amount,
            user.pendingAmount,
            user.rewardDebt,
            user.depositedDate,
            user.boostFactors,
            user.boostRewardDebt,
            user.boostedDate,
            user.accBoostReward,
            user.accBaseReward
        );
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0,
                totalBoostCount: 0,
                rewardEligibleSupply: 0
            })
        );
    }

    // Update the given pool's STRIKE allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Update the given STRIKE per block. Can only be called by the owner.
    function setRewardPerBlock(
        uint256 speed
    ) public onlyOwner {
        rewardPerBlock = speed;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    function getValidBoostFactors(uint256 userBoostFactors) internal view returns (uint256) {
        uint256 validBoostFactors = userBoostFactors > minimumValidBoostCount ? userBoostFactors - minimumValidBoostCount : 0;

        return validBoostFactors;
    }

    function getBoostMultiplier(uint256 boostFactorCount) internal view returns (uint256) {
        if (boostFactorCount <= minimumValidBoostCount) {
            return 0;
        }
        uint256 initBoostCount = boostFactorCount.sub(minimumValidBoostCount + 1);

        return initBoostCount.mul(boostMultiplierFactor).add(initialBoostMultiplier);
    }

    // View function to see pending STRIKEs on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
            );
        }
        uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
        uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        uint256 boostReward = boostMultiplier.mul(baseReward).div(100).add(user.accBoostReward).sub(user.boostRewardDebt);
        return baseReward.add(boostReward).add(user.accBaseReward);
    }

    // View function to see pending STRIKEs on frontend.
    function pendingBaseReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
            );
        }

        uint256 newReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        return newReward.add(user.accBaseReward);
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

        if (pool.rewardEligibleSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward =
            multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accRewardPerShare = pool.accRewardPerShare.add(
            reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Check the eligible user or not for reward
    function checkRewardEligible(uint boost) internal view returns(bool) {
        if (boost >= minimumValidBoostCount) {
            return true;
        }

        return false;
    }

    // Check claim eligible
    function checkRewardClaimEligible(uint depositedTime) internal view returns(bool) {
        if (block.timestamp - depositedTime > claimBaseRewardTime) {
            return true;
        }

        return false;
    }

    // Claim base lp reward
    function _claimBaseRewards(uint256 _pid, address _user) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        bool claimEligible = checkRewardClaimEligible(user.depositedDate);

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);

        uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        uint256 boostReward = boostMultiplier.mul(baseReward).div(100);
        user.accBoostReward = user.accBoostReward.add(boostReward);
        uint256 rewards;

        if (claimEligible && baseReward > 0) {
            rewards = baseReward.add(user.accBaseReward);
            safeRewardTransfer(_user, rewards);
            user.accBaseReward = 0;
        } else {
            rewards = 0;
            user.accBaseReward = baseReward.add(user.accBaseReward);
        }

        emit ClaimBaseRewards(_user, _pid, rewards);

        user.depositedDate = block.timestamp;
    }

    function claimBaseRewards(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        bool claimEligible = checkRewardClaimEligible(user.depositedDate);
        require(claimEligible == true, "not claim eligible");
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    // Deposit LP tokens to STRIKEswap for STRIKE allocation.
    function deposit(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        bool rewardEligible = checkRewardEligible(user.boostFactors.length);

        _claimBaseRewards(_pid, msg.sender);

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        if (strk == address(pool.lpToken)) {
            lpSupplyOfStrikePool = lpSupplyOfStrikePool.add(_amount);
        }
        if (rewardEligible) {
            user.amount = user.amount.add(user.pendingAmount).add(_amount);
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.add(_amount);
            user.pendingAmount = 0;
        } else {
            user.pendingAmount = user.pendingAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        if (_amount > 0) {
            IVStrike(vStrk).mint(msg.sender, _amount.mul(VSTRK_RATE));
        }
        user.boostedDate = block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from STRIKEexFarm.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount >= _amount, "withdraw: not good");
        require(block.timestamp - user.depositedDate > unstakableTime, "not eligible to withdraw");
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);
        if (user.amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(_amount);
        } else {
            user.pendingAmount = user.pendingAmount.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;
        user.boostedDate = block.timestamp;
        if (strk == address(pool.lpToken)) {
            lpSupplyOfStrikePool = lpSupplyOfStrikePool.sub(_amount);
        }
        if (_amount > 0) {
            IVStrike(vStrk).burnFrom(msg.sender, _amount.mul(VSTRK_RATE));
        }
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // transfer VSTRIKE
    function move(uint256 _pid, address _sender, address _recipient, uint256 _vstrikeAmount) override external nonReentrant {
        require(vStrk == msg.sender);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage sender = userInfo[_pid][_sender];
        UserInfo storage recipient = userInfo[_pid][_recipient];

        uint256 amount = _vstrikeAmount.div(VSTRK_RATE);

        require(sender.amount + sender.pendingAmount >= amount, "transfer exceeds amount");
        require(block.timestamp - sender.depositedDate > unstakableTime, "not eligible to undtake");
        updatePool(_pid);
        _claimBaseRewards(_pid, _sender);

        if (sender.amount > 0) {
            sender.amount = sender.amount.sub(amount);
        } else {
            sender.pendingAmount = sender.pendingAmount.sub(amount);
        }
        sender.rewardDebt = sender.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        sender.boostedDate = block.timestamp;
        // will loose unclaimed boost reward
        sender.accBoostReward = 0;
        sender.boostRewardDebt = 0;

        bool claimEligible = checkRewardClaimEligible(recipient.depositedDate);
        bool rewardEligible = checkRewardEligible(recipient.boostFactors.length);

        if (claimEligible && rewardEligible) {
            _claimBaseRewards(_pid, _recipient);
        }

        if (rewardEligible) {
            recipient.amount = recipient.amount.add(recipient.pendingAmount).add(amount);
            recipient.pendingAmount = 0;
        } else {
            recipient.pendingAmount = recipient.pendingAmount.add(amount);
        }
        recipient.rewardDebt = recipient.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        recipient.boostedDate = block.timestamp;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount.add(user.pendingAmount));
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        if (user.amount > 0) {
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.amount);
        }
        user.amount = 0;
        user.pendingAmount = 0;
        user.rewardDebt = 0;
        user.boostRewardDebt = 0;
        user.accBoostReward = 0;
    }

    // Safe rewardToken transfer function, just in case if rounding error causes pool to not have enough STRIKEs.
    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 availableBal = IERC20(rewardToken).balanceOf(address(this));

        // Protect users liquidity
        if (strk == rewardToken) {
            if (availableBal > lpSupplyOfStrikePool) {
                availableBal = availableBal - lpSupplyOfStrikePool;
            } else {
                availableBal = 0;
            }
        }

        if (_amount > availableBal) {
            IERC20(rewardToken).transfer(_to, availableBal);
        } else {
            IERC20(rewardToken).transfer(_to, _amount);
        }
    }

    function setAccMulFactor(uint256 _factor) external onlyOwner {
        accMulFactor = _factor;
    }

    function updateInitialBoostMultiplier(uint _initialBoostMultiplier) external onlyOwner {
        initialBoostMultiplier = _initialBoostMultiplier;
    }

    function updatedBoostMultiplierFactor(uint _boostMultiplierFactor) external onlyOwner {
        boostMultiplierFactor = _boostMultiplierFactor;
    }

    // Update reward token address by owner.
    function updateRewardToken(address _reward) external onlyOwner {
        rewardToken = _reward;
    }

    // Update claimBaseRewardTime
    function updateClaimBaseRewardTime(uint256 _claimBaseRewardTime) external onlyOwner {
        claimBaseRewardTime = _claimBaseRewardTime;
    }

    // Update unstakableTime
    function updateUnstakableTime(uint256 _unstakableTime) external onlyOwner {
        unstakableTime = _unstakableTime;
    }

    // NFT Boosting
    // get boosted users
    function getBoostedUserCount(uint256 _pid) external view returns(uint256) {
        return boostedUsers[_pid].length;
    }

    // View function to see pending STRIKEs on frontend.
    function pendingBoostReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;

        if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward =
                multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accRewardPerShare = accRewardPerShare.add(
                reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
            );
        }

        uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
        uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
        uint256 boostReward = boostMultiplier.mul(baseReward).div(100);
        return user.accBoostReward.sub(user.boostRewardDebt).add(boostReward);
    }

    // for deposit reward token to contract
    function getTotalPendingBoostRewards() external view returns (uint256) {
        uint256 totalRewards;
        for (uint i; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 accRewardPerShare = pool.accRewardPerShare;

            for (uint j; j < boostedUsers[i].length; j++) {
                UserInfo storage user = userInfo[i][boostedUsers[i][j]];

                if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
                    uint256 multiplier =
                        getMultiplier(pool.lastRewardBlock, block.number);
                    uint256 reward =
                        multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                            totalAllocPoint
                        );
                    accRewardPerShare = accRewardPerShare.add(
                        reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
                    );
                }
                uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
                uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
                uint256 initBoostReward = boostMultiplier.mul(baseReward).div(100);
                uint256 boostReward = user.accBoostReward.sub(user.boostRewardDebt).add(initBoostReward);
                totalRewards = totalRewards.add(boostReward);
            }
        }

        return totalRewards;
    }

    // for deposit reward token to contract
    function getClaimablePendingBoostRewards() external view returns (uint256) {
        uint256 totalRewards;
        for (uint i; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 accRewardPerShare = pool.accRewardPerShare;

            for (uint j; j < boostedUsers[i].length; j++) {
                UserInfo storage user = userInfo[i][boostedUsers[i][j]];

                if (block.timestamp - user.boostedDate >= claimBoostRewardTime) {
                    if (block.number > pool.lastRewardBlock && pool.rewardEligibleSupply > 0) {
                        uint256 multiplier =
                            getMultiplier(pool.lastRewardBlock, block.number);
                        uint256 reward =
                            multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(
                                totalAllocPoint
                            );
                        accRewardPerShare = accRewardPerShare.add(
                            reward.mul(accMulFactor).div(pool.rewardEligibleSupply)
                        );
                    }
                    uint256 boostMultiplier = getBoostMultiplier(user.boostFactors.length);
                    uint256 baseReward = user.amount.mul(accRewardPerShare).div(accMulFactor).sub(user.rewardDebt);
                    uint256 initBoostReward = boostMultiplier.mul(baseReward).div(100);
                    uint256 boostReward = user.accBoostReward.sub(user.boostRewardDebt).add(initBoostReward);
                    totalRewards = totalRewards.add(boostReward);
                }
            }
        }

        return totalRewards;
    }

    // Claim boost reward
    function claimBoostReward(uint256 _pid) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.timestamp - user.boostedDate > claimBoostRewardTime, "not eligible to claim");
        PoolInfo storage pool = poolInfo[_pid];
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        uint256 boostReward = user.accBoostReward.sub(user.boostRewardDebt);
        safeRewardTransfer(msg.sender, boostReward);
        emit ClaimBoostRewards(msg.sender, _pid, boostReward);
        user.boostRewardDebt = user.boostRewardDebt.add(boostReward);
        user.boostedDate = block.timestamp;
    }

    function _boost(uint256 _pid, uint _tokenId) internal {
        require (isBoosted[_tokenId] == false, "already boosted");

        boostFactor.transferFrom(msg.sender, address(this), _tokenId);
        // boostFactor.updateStakeTime(_tokenId, true);

        isBoosted[_tokenId] = true;

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.pendingAmount > 0) {
            user.amount = user.pendingAmount;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.add(user.amount);
            user.pendingAmount = 0;
        }
        user.boostFactors.push(_tokenId);
        pool.totalBoostCount = pool.totalBoostCount + 1;

        emit Boost(msg.sender, _pid, _tokenId);
    }

    function boost(uint256 _pid, uint _tokenId) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount > 0, "no stake tokens");
        require(user.boostFactors.length + 1 <= maximumBoostCount);
        PoolInfo storage pool = poolInfo[_pid];
        if (user.boostFactors.length == 0) {
            boostedUsers[_pid].push(msg.sender);
        }
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        _boost(_pid, _tokenId);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        user.boostedDate = block.timestamp;
    }

    function boostPartially(uint _pid, uint tokenAmount) external {
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount > 0, "no stake tokens");
        require(user.boostFactors.length + tokenAmount <= maximumBoostCount);
        PoolInfo storage pool = poolInfo[_pid];
        if (user.boostFactors.length == 0) {
            boostedUsers[_pid].push(msg.sender);
        }
        uint256 ownerTokenCount = boostFactor.balanceOf(msg.sender);
        require(tokenAmount <= ownerTokenCount);
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint i; i < tokenAmount; i++) {
            uint _tokenId = boostFactor.tokenOfOwnerByIndex(msg.sender, 0);

            _boost(_pid, _tokenId);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        user.boostedDate = block.timestamp;
    }

    function boostAll(uint _pid, uint256[] memory _tokenIds) external {
        uint256 tokenIdLength = _tokenIds.length;
        require(tokenIdLength > 0, "");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount + user.pendingAmount > 0, "no stake tokens");
        uint256 ownerTokenCount = boostFactor.balanceOf(msg.sender);
        require(ownerTokenCount > 0, "");
        PoolInfo storage pool = poolInfo[_pid];
        if (user.boostFactors.length == 0) {
            boostedUsers[_pid].push(msg.sender);
        }
        uint256 availableTokenAmount = maximumBoostCount - user.boostFactors.length;
        require(availableTokenAmount > 0, "overflow maximum boosting");

        if (tokenIdLength < availableTokenAmount) {
            availableTokenAmount = tokenIdLength;
        }
        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint256 i; i < availableTokenAmount; i++) {
            _boost(_pid, _tokenIds[i]);
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
        user.boostedDate = block.timestamp;
    }

    function _unBoost(uint _pid, uint _tokenId) internal {
        require (isBoosted[_tokenId] == true);

        boostFactor.transferFrom(address(this), msg.sender, _tokenId);
        // boostFactor.updateStakeTime(_tokenId, false);

        isBoosted[_tokenId] = false;

        emit UnBoost(msg.sender, _pid, _tokenId);
    }

    function unBoost(uint _pid, uint _tokenId) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.boostFactors.length > 0, "");
        uint factorLength = user.boostFactors.length;

        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        bool found = false;
        uint dfId; // will be deleted factor index
        for (uint j; j < factorLength; j++) {
            if (_tokenId == user.boostFactors[j]) {
                dfId = j;
                found = true;
                break;
            }
        }
        require(found, "not found boosted tokenId");
        _unBoost(_pid, _tokenId);
        user.boostFactors[dfId] = user.boostFactors[factorLength - 1];
        user.boostFactors.pop();
        pool.totalBoostCount = pool.totalBoostCount - 1;

        user.boostedDate = block.timestamp;
        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;

        uint boostedUserCount = boostedUsers[_pid].length;
        if (user.boostFactors.length == 0) {
            user.pendingAmount = user.amount;
            user.amount = 0;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.pendingAmount);

            uint index;
            for (uint j; j < boostedUserCount; j++) {
                if (address(msg.sender) == address(boostedUsers[_pid][j])) {
                    index = j;
                    break;
                }
            }
            boostedUsers[_pid][index] = boostedUsers[_pid][boostedUserCount - 1];
            boostedUsers[_pid].pop();
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    function unBoostPartially(uint _pid, uint tokenAmount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.boostFactors.length > 0, "");
        require(tokenAmount <= user.boostFactors.length, "");
        uint factorLength = user.boostFactors.length;

        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint i = 1; i <= tokenAmount; i++) {
            uint index = factorLength - i;
            uint _tokenId = user.boostFactors[index];

            _unBoost(_pid, _tokenId);
            user.boostFactors.pop();
            pool.totalBoostCount = pool.totalBoostCount - 1;
        }
        user.boostedDate = block.timestamp;
        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;

        uint boostedUserCount = boostedUsers[_pid].length;
        if (user.boostFactors.length == 0) {
            user.pendingAmount = user.amount;
            user.amount = 0;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.pendingAmount);

            uint index;
            for (uint j; j < boostedUserCount; j++) {
                if (address(msg.sender) == address(boostedUsers[_pid][j])) {
                    index = j;
                    break;
                }
            }
            boostedUsers[_pid][index] = boostedUsers[_pid][boostedUserCount - 1];
            boostedUsers[_pid].pop();
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    function unBoostAll(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint factorLength = user.boostFactors.length;
        require(factorLength > 0, "");

        updatePool(_pid);
        _claimBaseRewards(_pid, msg.sender);

        for (uint i = 0; i < factorLength; i++) {
            uint _tokenId = user.boostFactors[i];
            _unBoost(_pid, _tokenId);
        }
        delete user.boostFactors;
        pool.totalBoostCount = pool.totalBoostCount - factorLength;
        user.boostedDate = block.timestamp;

        // will loose unclaimed boost reward
        user.accBoostReward = 0;
        user.boostRewardDebt = 0;

        uint boostedUserCount = boostedUsers[_pid].length;
        if (user.boostFactors.length == 0) {
            user.pendingAmount = user.amount;
            user.amount = 0;
            pool.rewardEligibleSupply = pool.rewardEligibleSupply.sub(user.pendingAmount);

            uint index;
            for (uint j; j < boostedUserCount; j++) {
                if (address(msg.sender) == address(boostedUsers[_pid][j])) {
                    index = j;
                    break;
                }
            }
            boostedUsers[_pid][index] = boostedUsers[_pid][boostedUserCount - 1];
            boostedUsers[_pid].pop();
        }
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(accMulFactor);
    }

    // Update boostFactor address. Can only be called by the owner.
    function setBoostFactor(
        address _address
    ) external onlyOwner {
        boostFactor = IBoostToken(_address);
    }

    // Update claimBoostRewardTime
    function updateClaimBoostRewardTime(uint256 _claimBoostRewardTime) external onlyOwner {
        claimBoostRewardTime = _claimBoostRewardTime;
    }

    // Update minimum valid boost token count. Can only be called by the owner.
    function updateMinimumValidBoostCount(uint16 _count) external onlyOwner {
        minimumValidBoostCount = _count;
    }

    // Update maximum valid boost token count. Can only be called by the owner.
    function updateMaximumBoostCount(uint16 _count) external onlyOwner {
        maximumBoostCount = _count;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721Enumerable.sol";

interface IBoostToken is IERC721Enumerable {
    function updateStakeTime(uint tokenId, bool isStake) external;

    function getTokenOwner(uint tokenId) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IStrikeBoostFarm {
    function move(uint256 pid, address sender, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IVStrike {
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Mint} event.
     */
    function mint(address recipient, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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