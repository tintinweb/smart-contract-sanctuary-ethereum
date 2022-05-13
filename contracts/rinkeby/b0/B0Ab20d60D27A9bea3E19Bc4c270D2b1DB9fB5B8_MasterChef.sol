// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;

pragma solidity ^0.6.12;

import "./MasterChefGetter.sol";
import "./MasterChefStruct.sol";
import "./MasterChefSetter.sol";
import "../interfaces/IMigratorChef.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Initializable, Setter, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_state._mutex, "ERR_REENTRY");
        _state._mutex = true;
        _;
        _state._mutex = false;
    }

    // constructor(address _devaddr) public {
    //     devaddr = _devaddr;
    // }

    function initialize(address _devaddr) public initializer {
        _state.devaddr = _devaddr;
        __Ownable_init();
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        address[] memory rewardTokens,
        uint256[] memory share,
        // uint256[] memory rewardPerBlock,
        IERC20 lpToken,
        uint256 scorePerBlock,
        uint256 period,
        uint256 reductionRate,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        _state.poolInfo.push(
            Structs.PoolInfo({
                startBlock: block.number,
                rewardTokens: rewardTokens,
                lpToken: lpToken,
                share: share, // rewardPerBlock: rewardPerBlock,
                scorePerBlock: scorePerBlock,
                lastRewardBlock: block.number,
                period: period,
                reductionRate: reductionRate,
                totalScore: 0,
                endReduceBlock: 0,
                lockPercent: 0,
                lockBlocks: 0
            })
        );
        uint256 poolIndex = _state.poolInfo.length - 1;

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _setRewardPerBlockForOneToken(
                _state.rewardOneTokenPerBlock[rewardTokens[i]],
                rewardTokens[i]
            );
        }

        emit AddPool(poolIndex, address(lpToken), rewardTokens);
    }

    function setLockBlocksLockPercent(
        uint256 pid,
        uint256 lockBlocks,
        uint256 lockPercent
    ) public onlyOwner {
        _setLockBlocksLockPercent(pid, lockBlocks, lockPercent);
    }

    function depositFund(address tokenAddress, uint256 amount)
        public
        onlyOwner
    {
        IERC20 rewardToken = IERC20(tokenAddress);
        require(
            rewardToken.balanceOf(msg.sender) >= amount,
            "Deposit fund exist balance"
        );
        rewardToken.transferFrom(address(msg.sender), address(this), amount);
        emit LogDepositFund(tokenAddress, amount);
    }

    function withdrawFund(address tokenAddress, uint256 amount)
        public
        onlyOwner
    {
        IERC20 rewardToken = IERC20(tokenAddress);
        require(
            rewardToken.balanceOf(address(this)) >= amount,
            "Withdraw fund exist balance"
        );
        rewardToken.transfer(address(msg.sender), amount);
        emit LogWithdrawFund(tokenAddress, amount);
    }

    function setReductionRate(uint256 _pid, uint256 _rate) public onlyOwner {
        _setReductionRate(_pid, _rate);
    }

    function setShareToken(uint256 _pid, uint256[] memory share)
        public
        onlyOwner
    {
        _setShareToken(_pid, share);
    }

    function setContinuousReduction(uint256 _pid, uint256 _endBlock)
        public
        onlyOwner
    {
        _setContinuousReduction(_pid, _endBlock);
    }

    function setPeriod(uint256 _pid, uint256 _period) public onlyOwner {
        _setPeriod(_pid, _period);
    }

    // function getRewardFor

    function setRewardPerBlockForOneToken(
        uint256 rewardPerBlock,
        address tokenAddress
    ) public onlyOwner {
        _setRewardPerBlockForOneToken(rewardPerBlock, tokenAddress);
    }


    function setScorePerBlock(uint256 _pid, uint256 _scorePerBlock)
        public
        onlyOwner
    {
        _setScorePerBlock(_pid, _scorePerBlock);
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        _setMigrator(_migrator);
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(_state.migrator) != address(0), "migrate: no migrator");
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(_state.migrator), bal);
        IERC20 newLpToken = _state.migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = _state.poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updateUser(uint256 _pid, address userAddress) public {
        Structs.PoolInfo memory pool = _state.poolInfo[_pid];
        Structs.UserInfo storage user = _state.userInfo[_pid][userAddress];
        user.score = getUserScore(_pid, userAddress);
        user.lastBlock = block.number;
        user.scorePerBlock = pool.scorePerBlock;
    }

    // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public _logs_ _lock_ {
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        Structs.UserInfo storage user = _state.userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            updateUser(_pid, msg.sender);
        } else {
            user.lastBlock = block.number;
            user.rewardDebt = [0, 0];
            user.scorePerBlock = pool.scorePerBlock;
        }

        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public _logs_ _lock_ {
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        Structs.UserInfo storage user = _state.userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        updateUser(_pid, msg.sender);
        user.amount = user.amount.sub(_amount);
        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function claimTokenReward(uint256 _pid, uint256 tokenIndex)
        public
        _logs_
        _lock_
    {
        // require(!isPause(_pid), "Can't claim reward while reward pausing");

        uint256 reward;
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        Structs.UserInfo storage user = _state.userInfo[_pid][msg.sender];

        updatePool(_pid);
        updateUser(_pid, msg.sender);
        for (uint256 i = 0; i < user.lockedAmount.length; i++) {
            Structs.LockedAmount memory lockedAmount = user.lockedAmount[i];
            if (lockedAmount.endBlock > block.number) {
                continue;
            } else if (lockedAmount.token == pool.rewardTokens[tokenIndex]) {
                reward += lockedAmount.amount;
                user.lockedAmount[i].amount = 0;
            }
        }

        uint256[2] memory pendingRewardToken = pendingReward(_pid, msg.sender);
        uint256 userReward = pendingRewardToken[tokenIndex];
        uint256 lockedAmount =
            userReward.mul(_state.poolInfo[_pid].lockPercent).div(BONE);
        reward += userReward.sub(lockedAmount);
        user.rewardDebt[tokenIndex] += userReward;
        uint256 amount =
            safeRewardTransfer(
                pool.rewardTokens[tokenIndex],
                msg.sender,
                reward
            );
        emit LogClaimReward(pool.rewardTokens[tokenIndex], msg.sender, amount, _pid);
        user.lockedAmount.push(
            Structs.LockedAmount({
                token: pool.rewardTokens[tokenIndex],
                amount: lockedAmount, // How many LP tokens the user has provided.
                endBlock: block.number.add(_state.poolInfo[_pid].lockBlocks)
            })
        );
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public _logs_ _lock_ {
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        Structs.UserInfo storage user = _state.userInfo[_pid][msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = [0, 0];
        user.score = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeRewardTransfer(
        address token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        IERC20 rewardToken = IERC20(token);
        uint256 sushiBal = rewardToken.balanceOf(address(this));
        if (_amount > sushiBal) {
            rewardToken.transfer(_to, sushiBal);
            return sushiBal;
        } else {
            rewardToken.transfer(_to, _amount);
            return _amount;
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == _state.devaddr, "dev: wut?");
        _state.devaddr = _devaddr;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./MasterChefState.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Getter is State {
    using SafeMath for uint256;

    function poolLength() external view returns (uint256) {
        return _state.poolInfo.length;
    }

    function canSetRewardPerBlock(
        address[] memory rewardTokens,
        address tokenAddress
    ) public pure returns (bool) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            if (rewardTokens[i] == tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function viewRewardPerBlockForOneToken(
        uint256 rewardPerBlock,
        address tokenAddress,
        uint256 pid
    ) public view returns (uint256[] memory) {
        uint256 totalShare = 0;
        for (uint256 i = 0; i < _state.poolInfo.length; i++) {
            for (
                uint256 j = 0;
                j < _state.poolInfo[i].rewardTokens.length;
                ++j
            ) {
                uint256 share = _state.poolInfo[i].rewardTokens[j] ==
                    tokenAddress
                    ? _state.poolInfo[i].share[j]
                    : 0;
                totalShare = totalShare + share;
            }
        }

        uint256[] memory rewards = new uint256[](2);

        if (totalShare == 0) return rewards;

        for (uint256 j = 0; j < _state.poolInfo[pid].rewardTokens.length; ++j) {
            rewards[j] = _state.poolInfo[pid].rewardTokens[j] == tokenAddress
                ? (rewardPerBlock * _state.poolInfo[pid].share[j]) / totalShare
                : (
                    _state.history[pid].length != 0
                        ? _state
                        .history[pid][_state.history[pid].length - 1]
                            .rewardPerBlock[j]
                        : 0
                );
        }

        return rewards;
    }

    function getRewardMultiplier(
        uint256 fromBlock,
        uint256 toBlock,
        uint256 pid
    ) public view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](2);

        for (uint256 i = 0; i < _state.history[pid].length; i++) {
            if (fromBlock < _state.history[pid][i].startBlock) {
                fromBlock = _state.history[pid][i].startBlock;
                if (fromBlock > toBlock) {
                    break;
                }
            }
            if (
                fromBlock > _state.history[pid][i].endBlock &&
                _state.history[pid][i].endBlock != 0
            ) continue;
            else if (
                fromBlock >= _state.history[pid][i].startBlock &&
                (toBlock <= _state.history[pid][i].endBlock ||
                    _state.history[pid][i].endBlock == 0)
            ) {
                for (
                    uint256 j = 0;
                    j < _state.history[pid][i].rewardPerBlock.length;
                    j++
                ) {
                    rewards[j] +=
                        _state.history[pid][i].rewardPerBlock[j] *
                        (toBlock - fromBlock);
                }
                break;
            } else if (
                fromBlock >= _state.history[pid][i].startBlock &&
                toBlock > _state.history[pid][i].endBlock
            ) {
                for (
                    uint256 j = 0;
                    j < _state.history[pid][i].rewardPerBlock.length;
                    j++
                ) {
                    rewards[j] +=
                        _state.history[pid][i].rewardPerBlock[j] *
                        (_state.history[pid][i].endBlock - fromBlock);
                }

                fromBlock = _state.history[pid][i].endBlock;
            }
        }
        return rewards;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _pid,
        uint256 _from,
        uint256 _to,
        uint256 scorePerBlock,
        uint256 period,
        uint256 rate
    ) public view returns (uint256, uint256) {
        require(_from <= _to, "invalid block input");
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        uint256 multiplier;
        uint256 start = _from;
        uint256 firstRange = period - ((_from - pool.startBlock) % period);

        if (firstRange < _to.sub(_from)) {
            multiplier += firstRange.mul(scorePerBlock);
            start += firstRange;
            if (pool.endReduceBlock == 0 || pool.endReduceBlock > start) {
                scorePerBlock = scorePerBlock.mul(rate).div(BONE);
            }
            while (start < _to) {
                if (start.add(period) < _to) {
                    multiplier += period.mul(scorePerBlock);
                    start += period;
                    scorePerBlock = scorePerBlock.mul(rate).div(BONE);
                } else {
                    multiplier += (_to.sub(start)).mul(scorePerBlock);
                    break;
                }
            }
        } else {
            multiplier += _to.sub(_from).mul(scorePerBlock);
            return (multiplier, scorePerBlock);
        }
        return (multiplier, scorePerBlock);
    }

    function getUserScore(uint256 _pid, address userAddress)
        public
        view
        returns (uint256)
    {
        Structs.UserInfo memory user = _state.userInfo[_pid][userAddress];
        Structs.History[] memory poolHistory = _state.history[_pid];
        uint256 length = poolHistory.length;
        uint256 oldScore = user.score;
        for (uint256 i = length - 1; i >= 0; i--) {
            if (user.lastBlock >= poolHistory[i].startBlock) {
                (uint256 multiplier, ) = getMultiplier(
                    _pid,
                    user.lastBlock,
                    poolHistory[i].endBlock == 0
                        ? block.number
                        : poolHistory[i].endBlock,
                    user.scorePerBlock,
                    poolHistory[i].period,
                    poolHistory[i].rate
                );
                oldScore += multiplier.mul(user.amount).div(BONE);
                break;
            } else {
                (uint256 multiplier, ) = getMultiplier(
                    _pid,
                    poolHistory[i].startBlock,
                    poolHistory[i].endBlock == 0
                        ? block.number
                        : poolHistory[i].endBlock,
                    poolHistory[i].firstScorePerBlock,
                    poolHistory[i].period,
                    poolHistory[i].rate
                );
                oldScore += multiplier.mul(user.amount).div(BONE);
            }

            if (i == 0) {
                break;
            }
        }
        return oldScore;
    }

    // View function to see pending SUSHIs on frontend.
    function pendingReward(uint256 _pid, address _user)
        public
        view
        returns (uint256[2] memory)
    {
        uint256[2] memory pendingRewards = [uint256(0), uint256(0)];
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        Structs.UserInfo storage user = _state.userInfo[_pid][_user];
        (uint256 poolMultiplier, ) = getMultiplier(
            _pid,
            pool.lastRewardBlock,
            block.number,
            pool.scorePerBlock,
            pool.period,
            pool.reductionRate
        );
        uint256 userScore = getUserScore(_pid, _user);
        uint256 totalScore = poolMultiplier
            .mul(pool.lpToken.balanceOf(address(this)))
            .div(BONE)
            .add(pool.totalScore);

        for (uint256 i = 0; i < pool.rewardTokens.length; i++) {
            uint256 reward = getRewardMultiplier(
                pool.startBlock,
                block.number,
                _pid
            )[i];

            uint256 userReward = (reward * userScore) / totalScore;
            if (userReward >= user.rewardDebt[i]) {
                pendingRewards[i] = userReward.sub(user.rewardDebt[i]);
            } else {
                pendingRewards[i] = uint256(0);
            }
        }
        return pendingRewards;
    }

    function getPoolInfor(uint256 _pid) public view returns (Structs.PoolInfo memory) {
        return _state.poolInfo[_pid];
    }

    function getUserInfor(uint256 _pid, address user)
        public
        view
        returns (Structs.UserInfo memory)
    {
        return _state.userInfo[_pid][user];
    }

    function getPoolHistory(uint256 _pid)
        public
        view
        returns (Structs.History[] memory)
    {
        return _state.history[_pid];
    }

    function getLockedUserAmountIndex(uint256 _pid, address _user)
        public
        view
        returns (
            bool isSet,
            uint256 _begin,
            uint256 _end
        )
    {
        Structs.UserInfo storage user = _state.userInfo[_pid][_user];
        bool set;

        for (uint256 i = 0; i < user.lockedAmount.length; i++) {
            Structs.LockedAmount memory lockedAmount = user.lockedAmount[i];
            if (lockedAmount.endBlock > block.number) {
                if (user.lockedAmount[i].amount != 0 && !set) {
                    _begin = i;
                    set = true;
                }
                continue;
            }
        }
        return (set, _begin, user.lockedAmount.length - 1);
    }

    function getLockedUserAmount(
        uint256 _pid,
        uint256 index,
        address user
    ) public view returns (Structs.LockedAmount memory) {
        return _state.userInfo[_pid][user].lockedAmount[index];
    }

    function getDevAddress(
        
    ) public view returns (address) {
        return _state.devaddr;
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.6.12;

interface Structs {
  // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256[] rewardDebt; // Reward debt. See explanation below.
        uint256 lastBlock; // last block that update user score
        uint256 score; // user score
        LockedAmount[] lockedAmount;
        uint256 scorePerBlock;

        //
        // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct LockedAmount {
        address token;
        uint256 amount; // reward tokens locked
        uint256 endBlock; // block that user can withdraw lockReward
    }

    struct PauseReward {
        uint256 start;
        uint256 end;
    }

    struct History {
        uint256 period;
        uint256 firstScorePerBlock;
        uint256 lastScorePerBlock;
        uint256 startBlock;
        uint256 endBlock;
        uint256 rate;
        uint256[] rewardPerBlock;
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 startBlock; // block start farming reward
        address[] rewardTokens; // rewards tokens of pool
        IERC20 lpToken; // lp token to stake
        uint256[] share;
        // uint256[] rewardPerBlock;
        uint256 scorePerBlock; // Score earned for each token staked on 1 block
        uint256 lastRewardBlock; // last block update
        uint256 period; // The reduction period of scorePerBlock
        uint256 reductionRate; // The reduction rate
        uint256 totalScore; // Pool's total score, as of the last update
        uint256 endReduceBlock; // Block stops the regular decrease. If not stop default is 0
        uint256 lockPercent;
        uint256 lockBlocks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./MasterChefState.sol";
import "./MasterChefGetter.sol";

contract Setter is Getter {
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        Structs.PoolInfo storage pool = _state.poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        // uint256 blockPassed = block.number - pool.lastRewardBlock;
        for (uint256 i = 0; i < pool.rewardTokens.length; i++) {
            IERC20 rewardToken = IERC20(pool.rewardTokens[i]);
            uint256 reward = getRewardMultiplier(
                pool.lastRewardBlock,
                block.number,
                _pid
            )[i];
            if (reward > 0) {
                rewardToken.transfer(_state.devaddr, reward.div(10));
            }
            // uint256 reward = blockPassed.mul(pool.rewardPerBlock[i]);
        }

        (uint256 multiplier, uint256 currentScorePerBlock) = getMultiplier(
            _pid,
            pool.lastRewardBlock,
            block.number,
            pool.scorePerBlock,
            pool.period,
            pool.reductionRate
        );
        pool.totalScore += pool
            .lpToken
            .balanceOf(address(this))
            .mul(multiplier)
            .div(BONE);
        pool.lastRewardBlock = block.number;
        pool.scorePerBlock = currentScorePerBlock > MIN_SCORE_PER_BLOCK
            ? currentScorePerBlock
            : MIN_SCORE_PER_BLOCK;
    }

    function _setRewardPerBlockForOneToken(
        uint256 rewardPerBlock,
        address tokenAddress
    ) internal {
        _state.rewardOneTokenPerBlock[tokenAddress] = rewardPerBlock;
        for (uint256 i = 0; i < _state.poolInfo.length; i++) {
            if (
                canSetRewardPerBlock(
                    _state.poolInfo[i].rewardTokens,
                    tokenAddress
                )
            ) {
                if (
                    _state.history[i].length > 0 &&
                    _state
                    .history[i][_state.history[i].length - 1].startBlock ==
                    block.number
                ) {
                    _state
                    .history[i][_state.history[i].length - 1]
                        .rewardPerBlock = viewRewardPerBlockForOneToken(
                        rewardPerBlock,
                        tokenAddress,
                        i
                    );
                } else {
                    if (_state.history[i].length > 0) {
                        _state
                        .history[i][_state.history[i].length - 1]
                            .lastScorePerBlock = _state
                            .poolInfo[i]
                            .scorePerBlock;

                        _state
                        .history[i][_state.history[i].length - 1]
                            .endBlock = block.number;
                    }
                    _state.history[i].push(
                        Structs.History({
                            period: _state.poolInfo[i].period,
                            firstScorePerBlock: _state
                                .poolInfo[i]
                                .scorePerBlock,
                            lastScorePerBlock: 0,
                            startBlock: block.number,
                            endBlock: 0,
                            rate: _state.poolInfo[i].reductionRate,
                            rewardPerBlock: viewRewardPerBlockForOneToken(
                                rewardPerBlock,
                                tokenAddress,
                                i
                            )
                        })
                    );
                }
            }
        }
        emit LogSetRewardPerBlockForOneToken(rewardPerBlock, tokenAddress);
    }

    function _setReductionRate(uint256 _pid, uint256 _rate) internal {
        updatePool(_pid);
        uint256 length = _state.history[_pid].length;
        _state.history[_pid][length - 1].endBlock = block.number;
        uint256[] memory rewardPerBlock = _state
        .history[_pid][length - 1].rewardPerBlock;
        _state.history[_pid][length - 1].lastScorePerBlock = _state
            .poolInfo[_pid]
            .scorePerBlock;
        _state.history[_pid].push(
            Structs.History({
                period: _state.poolInfo[_pid].period,
                firstScorePerBlock: _state.poolInfo[_pid].scorePerBlock,
                lastScorePerBlock: 0,
                startBlock: block.number,
                endBlock: 0,
                rate: _rate,
                rewardPerBlock: rewardPerBlock
            })
        );
        _state.poolInfo[_pid].reductionRate = _rate;
        emit LogSetReductionRate(_pid, _rate);
    }

    function _setLockBlocksLockPercent(
        uint256 pid,
        uint256 lockBlocks,
        uint256 lockPercent
    ) internal {
        _state.poolInfo[pid].lockBlocks = lockBlocks;
        _state.poolInfo[pid].lockPercent = lockPercent;
        emit LogSetLockBlocksLockPercent(pid, lockBlocks, lockPercent);
    }

    function _setShareToken(uint256 _pid, uint256[] memory share) internal {
        updatePool(_pid);
        _state.poolInfo[_pid].share = share;

        for (
            uint256 i = 0;
            i < _state.poolInfo[_pid].rewardTokens.length;
            i++
        ) {
            _setRewardPerBlockForOneToken(
                _state.rewardOneTokenPerBlock[
                    _state.poolInfo[_pid].rewardTokens[i]
                ],
                _state.poolInfo[_pid].rewardTokens[i]
            );
        }
        emit LogSetShareToken(_pid, share);
    }

    function _setContinuousReduction(uint256 _pid, uint256 _endBlock) internal {
        _state.poolInfo[_pid].endReduceBlock = _endBlock;
        emit LogSetContinuousReduction(_pid, _endBlock);
    }

    function _setPeriod(uint256 _pid, uint256 _period) internal {
        updatePool(_pid);
        uint256 length = _state.history[_pid].length;
        _state.history[_pid][length - 1].endBlock = block.number;
        _state.history[_pid][length - 1].lastScorePerBlock = _state
            .poolInfo[_pid]
            .scorePerBlock;
        _state.history[_pid].push(
            Structs.History({
                period: _period,
                firstScorePerBlock: _state.poolInfo[_pid].scorePerBlock,
                lastScorePerBlock: 0,
                startBlock: block.number,
                endBlock: 0,
                rate: _state.poolInfo[_pid].reductionRate,
                rewardPerBlock: _state.history[_pid][length - 1].rewardPerBlock
            })
        );
        _state.poolInfo[_pid].period = _period;
        emit LogSetPeriod(_pid, _period);
    }

    function _setScorePerBlock(uint256 _pid, uint256 _scorePerBlock) internal {
        updatePool(_pid);
        uint256 length = _state.history[_pid].length;
        _state.history[_pid][length - 1].endBlock = block.number;
        _state.history[_pid][length - 1].lastScorePerBlock = _state
            .poolInfo[_pid]
            .scorePerBlock;
        _state.history[_pid].push(
            Structs.History({
                period: _state.poolInfo[_pid].period,
                firstScorePerBlock: _scorePerBlock,
                lastScorePerBlock: 0,
                startBlock: block.number,
                endBlock: 0,
                rate: _state.poolInfo[_pid].reductionRate,
                rewardPerBlock: _state.history[_pid][length - 1].rewardPerBlock
            })
        );
        _state.poolInfo[_pid].scorePerBlock = _scorePerBlock;
        emit LogSetScorePerBlock(_pid, _scorePerBlock);
    }

    // Set the migrator contract. Can only be called by the owner.
    function _setMigrator(IMigratorChef _migrator) internal {
        _state.migrator = _migrator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMigratorChef {
    // Perform LP token migration from legacy UniswapV2 to SushiSwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./MasterChefStruct.sol";
import "../interfaces/IMigratorChef.sol";

contract Event {
    event AddPool(uint256 pid, address lpToken, address[] rewards);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event LOG_CALL(
        bytes4 indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    event LogDepositFund(address token, uint256 amount);

    event LogWithdrawFund(address token, uint256 amount);

    event LogSetReductionRate(uint256 pid, uint256 rate);

    event LogSetShareToken(uint256 pid, uint256[] share);

    event LogSetScorePerBlock(uint256 pid, uint256 scorePerBlock);

    event LogSetContinuousReduction(uint256 pid, uint256 endBlock);

    event LogSetPeriod(uint256 pid, uint256 period);

    event LogClaimReward(address token, address user, uint256 amount, uint256 pid);
    event LogSetRewardPerBlockForOneToken(
        uint256 rewardPerBlock,
        address tokenAddress
    );

    event LogSetLockBlocksLockPercent(
        uint256 pid,
        uint256 lockBlocks,
        uint256 lockPercent
    );
}

contract Storage {

    struct MasterChefState {

        bool _mutex;
        // Dev address.
        address devaddr;
        // The migrator contract. It has a lot of power. Can only be set through governance (owner).
        IMigratorChef  migrator;
        // Info of each pool.
        Structs.PoolInfo[]  poolInfo;

        // mapping(uint256 => PauseReward[]) public pauseRewards;

        mapping(uint256 => Structs.History[])  history;

        mapping(address => uint256)  rewardOneTokenPerBlock;

        // Info of each user that stakes LP tokens.
        mapping(uint256 => mapping(address => Structs.UserInfo)) userInfo;
    }

}

contract State is Event {
    Storage.MasterChefState _state;

    uint256 constant public BONE = 10**18;

    uint256 constant public MIN_SCORE_PER_BLOCK = 10**6;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}