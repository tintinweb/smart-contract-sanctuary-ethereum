// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IV1Bribe.sol";
import "./interfaces/IV1Pair.sol";
import "./interfaces/IV1Voter.sol";
import "./interfaces/IV1Ve.sol";
import "./interfaces/IV1Gauge.sol";
import "./libraries/Math.sol";
import "./libraries/TransferHelper.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// TODO: check code with Synthetix StakingReward and Curve LiquidityGauge

// Gauges are used to incentivize pools, they emit reward tokens over 7 days
// for staked LP tokens
// solhint-disable not-rely-on-time, reentrancy /*
contract V1Gauge is IV1Gauge, ReentrancyGuard, Ownable {
    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event AddReward(address token);

    // Checkpoint for derived balance of users, `rewardRateStored` and `derivedSupply`
    struct Checkpoint {
        uint256 timestamp;
        uint256 value;
    }

    // Rewards are released over 7 days
    uint256 private constant WEEK = 7 days;
    uint256 private constant PRECISION = 1e18;

    // Pair token that needs to be staked for rewards
    address public immutable pair;
    // Ve token used for gauges
    address public immutable ve;
    address public immutable bribe;
    address public immutable voter;
    address public immutable token0;
    address public immutable token1;

    // Total amount of `pair` token deposited
    uint256 public totalSupply;
    // account => amount of `pair` token deposited
    mapping(address => uint256) public balanceOf;

    // Sum of derived balances
    uint256 public derivedSupply;
    mapping(address => uint256) public derivedBalanceOf;

    // Default snx staking contract implementation
    mapping(address => uint256) public rewardRate;
    // token => time reward finishes
    mapping(address => uint256) public rewardFinishTime;
    // token => last time reward per token was updated
    mapping(address => uint256) public lastUpdateTime;
    // token => reward per token stored
    // reward per token stored = sum(reward rate * dt / supply)
    mapping(address => uint256) public rewardPerTokenStored;

    // Last time `getReward` was called for token, account
    // token => account => timestamp
    mapping(address => mapping(address => uint256)) public lastEarnedTime;
    // token => account => rewardPerTokenStored
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenStored;

    // TODO: only 1 NFT for account is ok?
    // account to Ve token id
    mapping(address => uint256) public tokenIds;

    address[] public rewards;
    mapping(address => bool) public isReward;

    // Balance checkpoints for each account
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;
    // Number of checkpoints for each account
    mapping(address => uint256) public numCheckpoints;
    // `derivedSupply` checkpoints
    mapping(uint256 => Checkpoint) public supplyCheckpoints;
    // Number of checkpoints for `derivedSupply`
    uint256 public numSupplyCheckpoints;
    // `rewardPerTokenStored` checkpoints for each token
    mapping(address => mapping(uint256 => Checkpoint))
        public rewardPerTokenCheckpoints;
    // Number of `rewardPerTokenStored` checkpoints for each token
    mapping(address => uint256) public numRewardPerTokenCheckpoints;

    uint256 public fees0;
    uint256 public fees1;

    constructor(
        address _pair,
        address _bribe,
        address _ve,
        address _voter
    ) {
        pair = _pair;
        bribe = _bribe;
        ve = _ve;
        voter = _voter;
        (token0, token1) = IV1Pair(pair).tokens();

        owner = IV1Voter(_voter).owner();
    }

    modifier checkIsReward(address _token) {
        require(isReward[_token], "not reward");
        _;
    }

    function addReward(address _token) external onlyOwner {
        require(_token != address(0), "token = zero address");
        require(_token != pair, "token = pair");
        require(!isReward[_token], "token already added");

        rewards.push(_token);
        isReward[_token] = true;

        emit AddReward(_token);
    }

    function numRewards() external view returns (uint256) {
        return rewards.length;
    }

    function _claimFees() private returns (uint256 claimed0, uint256 claimed1) {
        (claimed0, claimed1) = IV1Pair(pair).claimFees();
        if (claimed0 > 0 || claimed1 > 0) {
            uint256 _fees0 = fees0 + claimed0;
            uint256 _fees1 = fees1 + claimed1;

            // Bribe rewards = token0 and token1, to be released over 1 week
            // Don't send if
            // - fee <= remaining bribe reward amount
            // - or bribe reward rate = 0
            // Bribe reward rate = reward amount / week = fee / week
            // TODO: remove _fees0 > bribe.left?
            if (_fees0 > IV1Bribe(bribe).left(token0) && _fees0 / WEEK > 0) {
                fees0 = 0;
                IERC20(token0).approve(bribe, _fees0);
                IV1Bribe(bribe).notifyRewardAmount(token0, _fees0);
            } else {
                fees0 = _fees0;
            }

            if (_fees1 > IV1Bribe(bribe).left(token1) && _fees1 / WEEK > 0) {
                fees1 = 0;
                IERC20(token1).approve(bribe, _fees1);
                IV1Bribe(bribe).notifyRewardAmount(token1, _fees1);
            } else {
                fees1 = _fees1;
            }

            emit ClaimFees(msg.sender, claimed0, claimed1);
        }
    }

    /**
     * @notice Claim trading fees from `pair`
     */
    function claimFees()
        external
        lock
        returns (uint256 claimed0, uint256 claimed1)
    {
        return _claimFees();
    }

    function _checkpoint(
        mapping(uint256 => Checkpoint) storage _checkpoints,
        // number of checkpoints
        uint256 n,
        uint256 value,
        // timestamp
        uint256 t
    ) private returns (bool isNew) {
        // TODO: check checkpoints[n-1].timestamp <= t
        if (n > 0 && _checkpoints[n - 1].timestamp == t) {
            // Update latest checkpoint
            _checkpoints[n - 1].value = value;
        } else {
            // TODO: if n = 0 and checkpoints[0].timestamp == t?
            // Insert new checkpoint
            _checkpoints[n] = Checkpoint({timestamp: t, value: value});
            isNew = true;
        }
    }

    /**
     * @notice Checkpoint derived balance of `account`
     * @param account Account to checkpoint
     * @param derivedBalance New balance to checkpoint
     */
    function _checkpointBalance(address account, uint256 derivedBalance)
        private
    {
        bool isNew = _checkpoint(
            checkpoints[account],
            numCheckpoints[account],
            derivedBalance,
            block.timestamp
        );

        if (isNew) {
            ++numCheckpoints[account];
        }
    }

    /**
     * @notice Checkpoint `derivedSupply`
     */
    function _checkpointSupply() private {
        bool isNew = _checkpoint(
            supplyCheckpoints,
            numSupplyCheckpoints,
            derivedSupply,
            block.timestamp
        );

        if (isNew) {
            ++numSupplyCheckpoints;
        }
    }

    function _checkpointRewardPerToken(
        address token,
        uint256 reward,
        uint256 timestamp
    ) private {
        bool isNew = _checkpoint(
            rewardPerTokenCheckpoints[token],
            numRewardPerTokenCheckpoints[token],
            reward,
            timestamp
        );

        if (isNew) {
            ++numRewardPerTokenCheckpoints[token];
        }
    }

    /**
     * @notice Calculate balance + boost
     * @dev Equation from Curve's LiquidityGauge
     * balance + boost = min(0.4 * b + 0.6 * S * w / V, b)
     * b = balance of user
     * S = total amount deposited
     * w = Ve balance of user
     * V = total Ve balance
     *
     * If w = 0, returns 0.4 * b
     * Otherwise output <= b
     * b / (0.4 * b) = 2.5 boost
     * @param account Account to calculate balance of
     * @param tokenId Token id of Ve
     * @return Calculated balance + boost
     */
    function _calculateDerivedBalance(address account, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256 bal = balanceOf[account];

        uint256 derived = (bal * 40) / 100;
        uint256 veTotal = IV1Ve(ve).totalSupply();

        uint256 boost;
        // ownerOf may fail if token doesn't exist - ERC721 spec
        if (
            tokenId > 0 && account == IV1Ve(ve).ownerOf(tokenId) && veTotal > 0
        ) {
            uint256 veBal = IV1Ve(ve).balanceOfNFT(tokenId);
            boost = (((totalSupply * veBal) / veTotal) * 60) / 100;
        }

        return Math.min(derived + boost, bal);
    }

    function calculateDerivedBalance(address account)
        external
        view
        returns (uint256)
    {
        return _calculateDerivedBalance(account, tokenIds[account]);
    }

    function _updateDerivedBalanceAndSupply(address account, uint256 tokenId)
        private
    {
        // reset derived supply
        derivedSupply -= derivedBalanceOf[account];
        // recalculate
        uint256 derivedBal = _calculateDerivedBalance(account, tokenId);
        // update
        derivedBalanceOf[account] = derivedBal;
        derivedSupply += derivedBal;

        _checkpointBalance(account, derivedBal);
        _checkpointSupply();
    }

    /**
     * @notice Stake `amount` of `pair` token
     * @param amount Amount of `pair` token to deposit
     * @param tokenId Optional token id of Ve
     */
    function deposit(uint256 amount, uint256 tokenId) external lock {
        require(amount > 0, "amount = 0");

        IERC20(pair).transferFrom(msg.sender, address(this), amount);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        // TODO: what is this doing?
        // If we provide a tokenId that is not the initial zero one for the first slot
        if (tokenId > 0) {
            // Ownership check
            require(IV1Ve(ve).ownerOf(tokenId) == msg.sender, "not ve owner");

            // If we dont have a entry yet at the mapping(account -> uint256)
            if (tokenIds[msg.sender] == 0) {
                // We set our index
                tokenIds[msg.sender] = tokenId;
                // And we attach essentially adding to attachments in Ve  mapping token id -> count of attachments
                IV1Voter(voter).attachVeTokenToGauge(tokenId, msg.sender);
            } else {
                // If we do already have a entry make sure that we are presenting the proper id for it
                require(
                    tokenIds[msg.sender] == tokenId,
                    "token id != registered token id"
                );
            }
        } else {
            // If tokenId provided is 0 then get the token id from the mapping
            tokenId = tokenIds[msg.sender];
        }

        _updateDerivedBalanceAndSupply(msg.sender, tokenId);

        emit Deposit(msg.sender, tokenId, amount);
    }

    /**
     * @notice Unstake `pair`
     * @param amount Amount of `pair` token to withdraw
     * @param tokenId Optional token id of Ve
     */
    function withdraw(uint256 amount, uint256 tokenId) external lock {
        require(amount > 0, "amount = 0");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        IERC20(pair).transfer(msg.sender, amount);

        // TODO: what is this doing?
        if (tokenId > 0) {
            require(tokenId == tokenIds[msg.sender], "not ve owner");
            delete tokenIds[msg.sender];
            IV1Voter(voter).detachVeTokenFromGauge(tokenId, msg.sender);
        } else {
            tokenId = tokenIds[msg.sender];
        }

        _updateDerivedBalanceAndSupply(msg.sender, tokenId);

        emit Withdraw(msg.sender, tokenId, amount);
    }

    /**
     * @notice Binary search to find checkpoint equal to or immediately before `t`.
     *         WARNING: If `t` < `checkpoints[0].timestamp`
     *         this function returns the index of first checkpoint `0`.
     * @param _checkpoints Mapping from uint => Checkpoint
     * @param n Number of checkpooints. Don't search beyond `n`
     * @param t Timestamp to find
     * @return Checkpoint that is equal to or immediately before `t`
     */
    function _getPriorCheckpointIndex(
        mapping(uint256 => Checkpoint) storage _checkpoints,
        // number of checkpoints
        uint256 n,
        // timestamp
        uint256 t
    ) private view returns (uint256) {
        if (n == 0) {
            return 0;
        }

        if (_checkpoints[n - 1].timestamp <= t) {
            return n - 1;
        }
        if (t <= _checkpoints[0].timestamp) {
            return 0;
        }

        // Binary search
        uint256 min;
        uint256 max = n - 1;
        while (min < max) {
            // 255 iterations will be enough for 256-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (_checkpoints[mid].timestamp <= t) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return min;
    }

    /**
     * @notice Determine the prior balance for an account as of `timestamp`
     * @param account The address of the account to check
     * @param timestamp The timestamp to get the balance at
     * @return The index of checkpoint prior to given timestamp
     */
    function getPriorBalanceIndex(address account, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return
            _getPriorCheckpointIndex(
                checkpoints[account],
                numCheckpoints[account],
                timestamp
            );
    }

    /**
     * @notice Determine the prior supply as of `timestamp`
     * @param timestamp The timestamp to get the supply at
     * @return The index of checkpoint prior to given timestamp
     */
    function getPriorSupplyIndex(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return
            _getPriorCheckpointIndex(
                supplyCheckpoints,
                numSupplyCheckpoints,
                timestamp
            );
    }

    /**
     * @notice Determine the prior reward per token as of `timestamp`
     * @param token Token address
     * @param timestamp The timestamp to get the reward per token at
     * @return Reward per token prior to `timestamp`
     */
    function getPriorRewardPerToken(address token, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 i = _getPriorCheckpointIndex(
            rewardPerTokenCheckpoints[token],
            numRewardPerTokenCheckpoints[token],
            timestamp
        );

        Checkpoint memory checkpoint = rewardPerTokenCheckpoints[token][i];

        if (i == 0 && timestamp < checkpoint.timestamp) {
            return 0;
        }

        return checkpoint.value;
    }

    function lastTimeRewardApplicable(address token)
        public
        view
        returns (uint256)
    {
        return Math.min(block.timestamp, rewardFinishTime[token]);
    }

    function rewardPerToken(address token) public view returns (uint256) {
        if (derivedSupply == 0) {
            return rewardPerTokenStored[token];
        }

        // b = block.timestamp
        // u = last update time
        // f = reward finish time
        // u <= b always true
        //
        // When b <= f, dt = b - u
        // --|---|------|----
        //   u   b      f
        // When f <= b, and u <= f, dt = f - u
        // --|----------|--|--
        //   u          f  b
        // When f <= b, and f <= u, dt = f - f = 0
        // -------------|--|---|-
        //              f  u   b
        uint256 dt = lastTimeRewardApplicable(token) -
            Math.min(lastUpdateTime[token], rewardFinishTime[token]);

        return
            rewardPerTokenStored[token] +
            (dt * rewardRate[token] * PRECISION) /
            derivedSupply;
    }

    /**
     * @notice Calculate reward per token
     * @param t1 Timestamp 1
     * @param t0 Timestamp 0
     * @param _supply Supply at timestamp 0
     * @param _lastUpdateTime Timestamp of last update
     * @param _rewardFinishTime Time reward ends
     * @param _rewardRate Reward rate
     * @dev t0 must be <= t1
     * @dev _supply must be > 0
     */
    function _calculateRewardPerToken(
        uint256 t1,
        uint256 t0,
        uint256 _supply,
        uint256 _lastUpdateTime,
        uint256 _rewardFinishTime,
        uint256 _rewardRate
    ) private pure returns (uint256 reward, uint256 endTime) {
        // TODO: check t0 <= t1
        // TODO: check supply > 0

        /*
        l = last update time
        s = max(t0, l)
        e = max(t1, l)

        l <= t0 <= t1
        s = t0
        e = t1

        t0 <= l <= t1
        s = l
        e = t1

        t0 <= t1 <= l
        s = l
        e = l

        -----------------------
        f = reward finish time
        s = min(s, f)
        e = min(e, f)

        f <= s <= e
        s = f
        e = f

        s <= f <= e
        s = s
        e = f

        s <= e <= f
        s = s
        e = e
        */
        uint256 startTime = Math.min(
            Math.max(t0, _lastUpdateTime),
            _rewardFinishTime
        );
        endTime = Math.max(t1, _lastUpdateTime);
        reward =
            ((Math.min(endTime, _rewardFinishTime) - startTime) *
                _rewardRate *
                PRECISION) /
            _supply;
    }

    /**
     * @notice Update reward per token up to end
     * @param token Address of reward token
     * @param end Index of supply checkpoints to sync up to
     */
    function _updateRewardPerTokenTo(address token, uint256 end)
        private
        returns (uint256, uint256)
    {
        uint256 _lastUpdateTime = lastUpdateTime[token];
        uint256 reward = rewardPerTokenStored[token];

        uint256 n = numSupplyCheckpoints;
        if (n == 0) {
            return (reward, _lastUpdateTime);
        }

        uint256 _rewardRate = rewardRate[token];
        if (_rewardRate == 0) {
            return (reward, block.timestamp);
        }

        uint256 start = getPriorSupplyIndex(_lastUpdateTime);
        require(end < n, "end >= num supply checkpoints");

        uint256 _rewardFinishTime = rewardFinishTime[token];

        for (uint256 i = start; i < end; ++i) {
            Checkpoint memory s0 = supplyCheckpoints[i];
            if (s0.value > 0) {
                Checkpoint memory s1 = supplyCheckpoints[i + 1];
                (uint256 _reward, uint256 endTime) = _calculateRewardPerToken(
                    s1.timestamp,
                    s0.timestamp,
                    s0.value,
                    _lastUpdateTime,
                    _rewardFinishTime,
                    _rewardRate
                );
                reward += _reward;
                _checkpointRewardPerToken(token, reward, endTime);
                _lastUpdateTime = endTime;
            }
        }

        return (reward, _lastUpdateTime);
    }

    /**
     * @notice Update `rewardPerTokenStored` of `token`
     * @param token Address of reward token to update
     */
    function _updateRewardPerToken(address token) private {
        uint256 n = numSupplyCheckpoints;
        if (n == 0) {
            return;
        }

        uint256 end = n - 1;
        (uint256 reward, uint256 _lastUpdateTime) = _updateRewardPerTokenTo(
            token,
            end
        );

        // TODO: if end = block.timestamp?
        // Checkpoint `rewardPerToken` up to most recent checkpoint
        Checkpoint memory s = supplyCheckpoints[end];
        if (s.value > 0) {
            (uint256 _reward, ) = _calculateRewardPerToken(
                lastTimeRewardApplicable(token),
                Math.max(s.timestamp, _lastUpdateTime),
                s.value,
                _lastUpdateTime,
                rewardFinishTime[token],
                rewardRate[token]
            );
            reward += _reward;
            _checkpointRewardPerToken(token, reward, block.timestamp);
            _lastUpdateTime = block.timestamp;
        }

        rewardPerTokenStored[token] = reward;
        // TODO: correct update time?
        lastUpdateTime[token] = _lastUpdateTime;
    }

    /**
     * @notice Batch update reward per token
     * @param token Address of reward token
     * @param end Index of supply checkpoints to sync up to
     */
    function batchUpdateRewardPerToken(address token, uint256 end)
        external
        checkIsReward(token)
    {
        (uint256 reward, uint256 _lastUpdateTime) = _updateRewardPerTokenTo(
            token,
            end
        );
        rewardPerTokenStored[token] = reward;
        lastUpdateTime[token] = _lastUpdateTime;
    }

    /**
     * @notice earned is an estimation, it won't be exact till the
     * supply > rewardPerToken calculations have run
     */
    function earned(address token, address account)
        public
        view
        returns (uint256)
    {
        uint256 n = numCheckpoints[account];
        if (n == 0) {
            return 0;
        }

        uint256 startTime = Math.max(
            lastEarnedTime[token][account],
            rewardPerTokenCheckpoints[token][0].timestamp
        );

        /* 
        How to calculate reward for user

        r(t) = reward rate at time t
        b(u, t) = balance of user u at time t
        s(t) = total supply at time t

        R(u, t1, t0) = reward earned for user u from t0 to t1
                       t1
                     = ∫ r(t')b(u, t') / s(t') dt'
                       t0

               t
        I(t) = ∫ r(t') / s(t') dt'
               0

        Balance of user, u_0, is constant for intervals t_0, t_1, ..., t_n
        b(u_0, t) = b_i for t_i <= t <= t_(i+1), 0 <= i < n
                  = 0 otherwise

        R(u_0, t_(i+1), t_i) = b_i (I(t_(i+1)) - I(t_i))

                      n-1
        R(u_0, t, 0) = Σ b_i (I(t_(i+1)) - I(t_i))
                     i = 0
        */
        uint256 start = getPriorBalanceIndex(account, startTime);
        uint256 end = n - 1;
        uint256 reward;

        // TODO: i <= end - 1?
        for (uint256 i = start; i < end; ++i) {
            Checkpoint memory c0 = checkpoints[account][i];
            Checkpoint memory c1 = checkpoints[account][i + 1];
            uint256 r0 = getPriorRewardPerToken(token, c0.timestamp);
            uint256 r1 = getPriorRewardPerToken(token, c1.timestamp);
            reward += (c0.value * (r1 - r0)) / PRECISION;
        }

        // TODO: if end = block.timestamp?
        // Calculate reward from last checkpoint to now
        Checkpoint memory c = checkpoints[account][end];
        // TODO: why max? user reward per token <= prior reward per token?
        // TODO: bug? example
        // user 1 get reward        deposit    current block
        // -----|-----------------|----|---------|----
        //      r0, c0            |    c1
        //                        | user 2 get reward
        // -----------------------|-------------------
        //                        r1
        // r should be r0?
        uint256 r = Math.max(
            getPriorRewardPerToken(token, c.timestamp),
            userRewardPerTokenStored[token][account]
        );
        reward += (c.value * (rewardPerToken(token) - r)) / PRECISION;

        return reward;
    }

    function getReward(address account, address[] calldata tokens)
        external
        lock
    {
        require(msg.sender == account || msg.sender == voter, "not authorized");
        // TODO: remove? voter.distribute() -> gauge.notifyRewards()
        _unlocked = 1;
        IV1Voter(voter).distribute(address(this));
        _unlocked = 2;

        for (uint256 i; i < tokens.length; ++i) {
            address token = tokens[i];
            require(isReward[token], "not reward");

            _updateRewardPerToken(token);

            uint256 reward = earned(token, account);
            lastEarnedTime[token][account] = block.timestamp;
            userRewardPerTokenStored[token][account] = rewardPerTokenStored[
                token
            ];

            if (reward > 0) {
                TransferHelper.safeTransfer(token, account, reward);
            }

            emit ClaimRewards(msg.sender, token, reward);
        }

        _updateDerivedBalanceAndSupply(account, tokenIds[account]);
    }

    /**
     * @notice Returns remaining rewards - reward rate * duration left
     * @param token Address of reward token
     * @return Amount of rewards left
     */
    function left(address token) external view returns (uint256) {
        uint256 _rewardFinishTime = rewardFinishTime[token];
        if (block.timestamp >= _rewardFinishTime) {
            return 0;
        }
        return (_rewardFinishTime - block.timestamp) * rewardRate[token];
    }

    // TODO: anyone can call?
    // TODO: no Synthetix style updateReward modifier?
    function notifyRewardAmount(address token, uint256 amount)
        external
        lock
        checkIsReward(token)
    {
        require(amount > 0, "amount = 0");

        if (rewardRate[token] == 0) {
            _checkpointRewardPerToken(token, 0, block.timestamp);
        }

        _updateRewardPerToken(token);

        // TODO: remove?
        _claimFees();

        // Set reward rate
        if (block.timestamp >= rewardFinishTime[token]) {
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                amount
            );
            rewardRate[token] = amount / WEEK;
        } else {
            uint256 remainingRewards = (rewardFinishTime[token] -
                block.timestamp) * rewardRate[token];
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                address(this),
                amount
            );
            rewardRate[token] = (amount + remainingRewards) / WEEK;
        }

        require(rewardRate[token] > 0, "reward rate = 0");
        // Check token balance >= reward rate * 1 week
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(rewardRate[token] <= bal / WEEK, "reward rate too high");

        rewardFinishTime[token] = block.timestamp + WEEK;

        emit NotifyReward(msg.sender, token, amount);
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
pragma solidity 0.8.11;

interface IV1Bribe {
    function notifyRewardAmount(address token, uint256 amount) external;

    function left(address token) external view returns (uint256);

    function deposit(uint256 amount, uint256 tokenId) external;

    function withdraw(uint256 amount, uint256 tokenId) external;

    function getRewardForOwner(uint256 tokenId, address[] memory tokens)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Structure to capture time period obervations every 30 minutes, used for local oracles
struct Observation {
    uint256 timestamp;
    uint256 reserve0Cumulative;
    uint256 reserve1Cumulative;
}

interface IV1Pair is IERC20Metadata {
    // IERC20
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // V1Pair
    function claimFees() external returns (uint256, uint256);

    function tokens() external returns (address, address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getReserveCumulatives() external view returns (uint256, uint256);

    function getObservationCount() external view returns (uint256);

    function observations(uint256 i) external view returns (Observation memory);

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256 amountOut);

    function calcAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IOwnable.sol";

interface IV1Voter is IOwnable {
    function ve() external view returns (address);

    function attachVeTokenToGauge(uint256 _tokenId, address account) external;

    function detachVeTokenFromGauge(uint256 _tokenId, address account) external;

    function distribute(address _gauge) external;

    function notifyRewardAmount(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Point} from "../libraries/PointLib.sol";

interface IV1Ve is IERC721Metadata {
    function halo() external view returns (address);

    function balanceOfNFT(uint256) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function setVoted(uint256 tokenId, bool _voted) external;

    function attach(uint256 tokenId) external;

    function detach(uint256 tokenId) external;

    function epoch() external view returns (uint256);

    function userPointEpoch(uint256 tokenId) external view returns (uint256);

    function pointHistory(uint256 i) external view returns (Point memory);

    function userPointHistory(uint256 tokenId, uint256 i)
        external
        view
        returns (Point memory);

    function checkpoint() external;

    function depositFor(uint256 tokenId, uint256 value) external;

    function createLockFor(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function findTimestampEpoch(uint256 _timestamp)
        external
        view
        returns (uint256);

    function findUserEpochFromTimestamp(
        uint256 _tokenId,
        uint256 _timestamp,
        uint256 _maxUserEpoch
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity 0.8.11;

interface IV1Gauge {
    function notifyRewardAmount(address token, uint256 amount) external;

    function getReward(address account, address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function left(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : b - a;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    error EthTransferFailed();
    error Erc20TransferFailed();
    error Erc20ApproveFailed();

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) {
            revert EthTransferFailed();
        }
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        // !success -> error
        // success and data = 0 -> ok
        // success and data = false -> error
        // success and data = true -> ok
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert Erc20TransferFailed();
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert Erc20TransferFailed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

abstract contract ReentrancyGuard {
    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    modifier lock() {
        // solhint-disable-next-line
        require(_unlocked == 1, "reentrant");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    event NewOwner(address owner);

    address public owner;
    address public pendingOwner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != msg.sender, "new owner = current owner");
        pendingOwner = _newOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "not pending owner");
        owner = msg.sender;
        pendingOwner = address(0);
        emit NewOwner(msg.sender);
    }

    function deleteOwner() external onlyOwner {
        require(pendingOwner == address(0), "pending owner != 0 address");
        owner = address(0);
        emit NewOwner(address(0));
    }
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
pragma solidity 0.8.11;

interface IOwnable {
    function owner() external view returns (address);

    function setOwner(address _newOwner) external;

    function acceptOwner() external;

    function deleteOwner() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

struct Point {
    int128 bias;
    int128 slope; // amount locked / max time
    uint256 timestamp;
    uint256 blk; // block number
}

library PointLib {
    /**
     * @notice Binary search to find epoch equal to or immediately before `_block`.
     *         WARNING: If `_block` < `pointHistory[0].blk`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm copied from Curve's VotingEscrow
     * @param pointHistory Mapping from uint => Point
     * @param _block Block to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return Epoch that is equal to or immediately before `_block`
     */
    function findBlockEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 _block,
        uint256 max
    ) internal view returns (uint256) {
        uint256 min;

        while (min < max) {
            // Max 128 iterations will be enough for 128-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (pointHistory[mid].blk <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return min;
    }

    /**
     * @notice Binary search to find epoch equal to or immediately before `timestamp`.
     *         WARNING: If `timestamp` < `pointHistory[0].timestamp`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm almost the same as `findBlockEpoch`
     * @param pointHistory Mapping from uint => Point
     * @param timestamp Timestamp to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return Epoch that is equal to or immediately before `timestamp`
     */
    function findTimestampEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 timestamp,
        uint256 max
    ) internal view returns (uint256) {
        uint256 min;

        while (min < max) {
            // Max 128 iterations will be enough for 128-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (pointHistory[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return min;
    }

    /**
     * @notice Calculates bias (used for VE total supply and user balance),
     * returns 0 if bias < 0
     * @param point Point
     * @param dt time delta in seconds
     */
    function calculateBias(Point memory point, int128 dt)
        internal
        pure
        returns (uint256)
    {
        require(dt >= 0, "dt < 0");

        int128 bias = point.bias - point.slope * dt;
        if (bias > 0) {
            return uint256(int256(bias));
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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