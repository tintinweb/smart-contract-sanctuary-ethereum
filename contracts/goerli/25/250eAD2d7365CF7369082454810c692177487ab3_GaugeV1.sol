// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBribeV1.sol";
import "./interfaces/IPairV1.sol";
import "./interfaces/IVoterV1.sol";
import "./interfaces/IVe.sol";
import "./interfaces/IGaugeV1.sol";
import "./libraries/Math.sol";
import "./libraries/TransferHelper.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// Gauges are used to incentivize pools, they emit reward tokens over 7 days
// for staked LP tokens
// solhint-disable not-rely-on-time, reentrancy /*
contract GaugeV1 is IGaugeV1, ReentrancyGuard, Ownable {
    event Deposit(address indexed account, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed account, uint256 tokenId, uint256 amount);
    event AddReward(address token);
    event NotifyReward(address indexed reward, uint256 amount);
    event ClaimReward(
        address indexed account,
        address indexed reward,
        uint256 amount
    );
    event ClaimFees(uint256 claimed0, uint256 claimed1);

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
    // VE token used for gauges
    address public immutable ve;
    address public immutable bribe;
    address public immutable voter;
    address public immutable token0;
    address public immutable token1;

    // Total amount of `pair` token deposited
    uint256 public totalSupply;
    // Account => amount of `pair` token deposited
    mapping(address => uint256) public balanceOf;

    // Sum of derived balances
    uint256 public derivedSupply;
    mapping(address => uint256) public derivedBalanceOf;

    // Default snx staking contract implementation
    mapping(address => uint256) public rewardRate;
    // Token => time reward finishes
    mapping(address => uint256) public rewardFinishTime;
    // Token => last time reward per token was updated
    mapping(address => uint256) public lastUpdateTime;
    // Token => reward per token stored
    // Reward per token stored = sum(reward rate * dt / supply)
    mapping(address => uint256) public rewardPerTokenStored;

    // Last time `getRewards` was called for token, account
    // Token => account => timestamp
    mapping(address => mapping(address => uint256)) public lastEarnedTime;
    // Token => account => rewardPerTokenStored
    mapping(address => mapping(address => uint256))
        public userRewardPerTokenStored;

    // Account to ve token id
    mapping(address => uint256) public tokenIdOf;

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

    modifier checkIsReward(address _token) {
        require(isReward[_token], "not reward");
        _;
    }

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
        (token0, token1) = IPairV1(pair).tokens();
        owner = IVoterV1(_voter).owner();

        _addReward(IVe(_ve).halo());
    }

    function _addReward(address _token) private {
        require(!isReward[_token], "token already added");

        rewards.push(_token);
        isReward[_token] = true;

        emit AddReward(_token);
    }

    /**
     * @notice Add reward
     * @param _token Address of reward token
     */
    function addReward(address _token) external onlyOwner {
        require(_token != address(0), "token = zero address");
        require(_token != pair, "token = pair");
        _addReward(_token);
    }

    /**
     * @notice Claim trading fees from `pair`
     */
    function claimFees()
        external
        lock
        returns (uint256 claimed0, uint256 claimed1)
    {
        (claimed0, claimed1) = IPairV1(pair).claimFees();
        if (claimed0 > 0 || claimed1 > 0) {
            uint256 _fees0 = fees0 + claimed0;
            uint256 _fees1 = fees1 + claimed1;

            // Bribe rewards = token0 and token1, to be released over 1 week
            if (_fees0 / WEEK > 0) {
                fees0 = 0;
                IERC20(token0).approve(bribe, _fees0);
                IBribeV1(bribe).notifyRewardAmount(token0, _fees0);
            } else {
                fees0 = _fees0;
            }

            if (_fees1 / WEEK > 0) {
                fees1 = 0;
                IERC20(token1).approve(bribe, _fees1);
                IBribeV1(bribe).notifyRewardAmount(token1, _fees1);
            } else {
                fees1 = _fees1;
            }

            emit ClaimFees(claimed0, claimed1);
        }
    }

    /**
     * @notice Insert or update a Checkpoint struct
     * @param _checkpoints Storage mapping from index to Checkpoint struct
     * @param n Number of checkpoints
     * @param value Value to store into a Checkpoint struct
     * @param t Timestamp for Checkpoint struct
     */
    function _checkpoint(
        mapping(uint256 => Checkpoint) storage _checkpoints,
        uint256 n,
        uint256 value,
        uint256 t
    ) private returns (bool isNew) {
        if (n > 0 && _checkpoints[n - 1].timestamp == t) {
            // Update latest checkpoint
            _checkpoints[n - 1].value = value;
        } else {
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

    /**
     * @notice Checkpoint `rewardPerToken`
     * @param token Address of reward token
     * @param reward Amount of reward
     * @param timestamp Timestamp
     */
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
     * w = VE balance of user
     * V = total VE balance
     *
     * If w = 0, returns 0.4 * b
     * Otherwise output <= b
     * b / (0.4 * b) = 2.5 boost
     * @param account Account to calculate balance of
     * @param tokenId Token id of VE
     * @return Calculated balance + boost
     */
    function _calculateDerivedBalance(address account, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256 bal = balanceOf[account];
        uint256 derived = (bal * 40) / 100;
        uint256 veTotal = IVe(ve).totalSupply();

        // ownerOf may fail if token doesn't exist - ERC721 spec
        if (tokenId > 0 && account == IVe(ve).ownerOf(tokenId) && veTotal > 0) {
            uint256 veBal = IVe(ve).balanceOfNFT(tokenId);
            derived += (((totalSupply * veBal) / veTotal) * 60) / 100;
        }

        return Math.min(derived, bal);
    }

    function calculateDerivedBalance(address account)
        external
        view
        returns (uint256)
    {
        return _calculateDerivedBalance(account, tokenIdOf[account]);
    }

    function _updateDerivedBalanceAndSupply(address account, uint256 tokenId)
        private
    {
        // Reset and recalculate derived supply
        derivedSupply -= derivedBalanceOf[account];
        uint256 bal = _calculateDerivedBalance(account, tokenId);
        // Update
        derivedBalanceOf[account] = bal;
        derivedSupply += bal;

        _checkpointBalance(account, bal);
        _checkpointSupply();
    }

    /**
     * @notice Stake `amount` of `pair` token
     * @param amount Amount of `pair` token to deposit
     * @param tokenId Optional token id of VE
     */
    function deposit(uint256 amount, uint256 tokenId) external lock {
        require(amount > 0, "amount = 0");

        IERC20(pair).transferFrom(msg.sender, address(this), amount);
        totalSupply += amount;
        balanceOf[msg.sender] += amount;

        if (tokenId > 0) {
            require(IVe(ve).ownerOf(tokenId) == msg.sender, "not ve owner");

            if (tokenIdOf[msg.sender] == 0) {
                tokenIdOf[msg.sender] = tokenId;
                IVoterV1(voter).attachVeTokenToGauge(tokenId, msg.sender);
            } else {
                require(
                    tokenIdOf[msg.sender] == tokenId,
                    "token id != registered token id"
                );
            }
        } else {
            tokenId = tokenIdOf[msg.sender];
        }

        _updateDerivedBalanceAndSupply(msg.sender, tokenId);

        emit Deposit(msg.sender, tokenId, amount);
    }

    /**
     * @notice Unstake `pair`
     * @param amount Amount of `pair` token to withdraw
     * @param tokenId Optional token id of VE
     */
    function withdraw(uint256 amount, uint256 tokenId) external lock {
        require(amount > 0, "amount = 0");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        IERC20(pair).transfer(msg.sender, amount);

        if (tokenId > 0) {
            require(tokenId == tokenIdOf[msg.sender], "not ve owner");
            delete tokenIdOf[msg.sender];
            IVoterV1(voter).detachVeTokenFromGauge(tokenId, msg.sender);
        } else {
            tokenId = tokenIdOf[msg.sender];
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
        uint256 n,
        uint256 t
    ) private view returns (uint256) {
        if (n == 0) {
            return 0;
        }

        if (_checkpoints[n - 1].timestamp <= t) {
            return n - 1;
        }
        if (t < _checkpoints[0].timestamp) {
            return 0;
        }

        // Binary search
        uint256 min = 0;
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
            ((dt * rewardRate[token] * PRECISION) / derivedSupply);
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
     * @notice Update `rewardPerTokenStored` of `token`
     * @param token Address of reward token to update
     */
    function _updateRewardPerToken(address token) private {
        uint256 reward = rewardPerTokenStored[token];
        uint256 updateTime = lastUpdateTime[token];

        uint256 n = numSupplyCheckpoints;
        if (n == 0) {
            lastUpdateTime[token] = block.timestamp;
            return;
        }

        uint256 rate = rewardRate[token];
        if (rate == 0) {
            lastUpdateTime[token] = block.timestamp;
            return;
        }

        uint256 finishTime = rewardFinishTime[token];

        uint256 start = getPriorSupplyIndex(updateTime);
        uint256 end = n - 1;

        for (uint256 i = start; i < end; ++i) {
            Checkpoint memory s0 = supplyCheckpoints[i];
            if (s0.value > 0) {
                Checkpoint memory s1 = supplyCheckpoints[i + 1];
                (uint256 _reward, uint256 endTime) = _calculateRewardPerToken(
                    s1.timestamp,
                    s0.timestamp,
                    s0.value,
                    updateTime,
                    finishTime,
                    rate
                );
                reward += _reward;
                _checkpointRewardPerToken(token, reward, endTime);
                updateTime = endTime;
            }
        }

        // Checkpoint `rewardPerToken` up to most recent checkpoint
        Checkpoint memory s = supplyCheckpoints[end];
        if (s.value > 0) {
            (uint256 _reward, ) = _calculateRewardPerToken(
                lastTimeRewardApplicable(token),
                Math.max(s.timestamp, updateTime),
                s.value,
                updateTime,
                finishTime,
                rate
            );
            reward += _reward;
            _checkpointRewardPerToken(token, reward, block.timestamp);
            updateTime = block.timestamp;
        }

        rewardPerTokenStored[token] = reward;
        lastUpdateTime[token] = updateTime;
    }

    /**
     * @notice Update `rewardPerTokenStored`
     * @param token Address of reward token
     * @param end Index of supply checkpoints to sync up to
     */
    function updateRewardPerToken(address token, uint256 end)
        external
        lock
        checkIsReward(token)
    {
        uint256 n = numSupplyCheckpoints;
        if (n == 0) {
            lastUpdateTime[token] = block.timestamp;
            return;
        }

        uint256 rate = rewardRate[token];
        if (rate == 0) {
            lastUpdateTime[token] = block.timestamp;
            return;
        }

        uint256 reward = rewardPerTokenStored[token];
        uint256 updateTime = lastUpdateTime[token];
        uint256 finishTime = rewardFinishTime[token];

        uint256 start = getPriorSupplyIndex(updateTime);
        end = Math.min(end, n - 1);

        for (uint256 i = start; i < end; ++i) {
            Checkpoint memory s0 = supplyCheckpoints[i];
            if (s0.value > 0) {
                Checkpoint memory s1 = supplyCheckpoints[i + 1];
                (uint256 _reward, uint256 endTime) = _calculateRewardPerToken(
                    s1.timestamp,
                    s0.timestamp,
                    s0.value,
                    updateTime,
                    finishTime,
                    rate
                );
                reward += _reward;
                _checkpointRewardPerToken(token, reward, endTime);
                updateTime = endTime;
            }
        }

        rewardPerTokenStored[token] = reward;
        lastUpdateTime[token] = updateTime;
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
                     = ∫ r(t)b(u, t) / s(t) dt
                       t0

                                          t'
        Define reward per token = I(t') = ∫ r(t) / s(t) dt
                                          0

        Balance of user, u, is constant > 0 for intervals t_0, t_1, ..., t_n
        b(u, t) = b_i for t_i <= t <= t_(i+1), 0 <= i <= n - 1
                = 0 otherwise

        R(u, t_(i+1), t_i) = b_i (I(t_(i+1)) - I(t_i))

                    n-1
        R(u, t, 0) = Σ b_i (I(t_(i+1)) - I(t_i))
                   i = 0
        */
        uint256 start = getPriorBalanceIndex(account, startTime);
        uint256 end = n - 1;
        uint256 reward = 0;

        if (start < end) {
            Checkpoint memory c0 = checkpoints[account][start];
            uint256 r0 = getPriorRewardPerToken(token, c0.timestamp);

            for (uint256 i = start; i < end; ++i) {
                Checkpoint memory c1 = checkpoints[account][i + 1];
                uint256 r1 = getPriorRewardPerToken(token, c1.timestamp);
                reward += (c0.value * (r1 - r0)) / PRECISION;

                c0 = c1;
                r0 = r1;
            }
        }

        // Calculate reward from last checkpoint to now
        Checkpoint memory c = checkpoints[account][end];
        uint256 r = Math.max(
            getPriorRewardPerToken(token, c.timestamp),
            userRewardPerTokenStored[token][account]
        );
        reward += (c.value * (rewardPerToken(token) - r)) / PRECISION;

        return reward;
    }

    function getRewards(address[] calldata tokens) external lock {
        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            require(isReward[token], "not reward");

            _updateRewardPerToken(token);

            uint256 reward = earned(token, msg.sender);
            lastEarnedTime[token][msg.sender] = block.timestamp;
            userRewardPerTokenStored[token][msg.sender] = rewardPerTokenStored[
                token
            ];

            if (reward > 0) {
                TransferHelper.safeTransfer(token, msg.sender, reward);
            }

            emit ClaimReward(msg.sender, token, reward);
        }

        _updateDerivedBalanceAndSupply(msg.sender, tokenIdOf[msg.sender]);
    }

    /**
     * @notice Update reward rate
     * @param _token Address of reward token
     * @param _amount Amount of reward
     */
    function notifyRewardAmount(address _token, uint256 _amount)
        external
        lock
        checkIsReward(_token)
    {
        require(_amount > 0, "amount = 0");

        if (rewardRate[_token] == 0) {
            _checkpointRewardPerToken(_token, 0, block.timestamp);
        }

        _updateRewardPerToken(_token);

        TransferHelper.safeTransferFrom(
            _token,
            msg.sender,
            address(this),
            _amount
        );

        // Set reward rate
        uint256 finishTime = rewardFinishTime[_token];
        if (block.timestamp >= finishTime) {
            rewardRate[_token] = _amount / WEEK;
        } else {
            uint256 remainingRewards = (finishTime - block.timestamp) *
                rewardRate[_token];
            rewardRate[_token] = (_amount + remainingRewards) / WEEK;
        }

        require(rewardRate[_token] > 0, "reward rate = 0");
        // Check _token balance >= reward rate * 1 week
        uint256 bal = IERC20(_token).balanceOf(address(this));
        require(rewardRate[_token] <= bal / WEEK, "reward rate too high");

        rewardFinishTime[_token] = block.timestamp + WEEK;

        emit NotifyReward(_token, _amount);
    }

    function numRewards() external view returns (uint256) {
        return rewards.length;
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

interface IBribeV1 {
    function notifyRewardAmount(address token, uint256 amount) external;

    function deposit(uint256 amount, uint256 tokenId) external;

    function withdraw(uint256 amount, uint256 tokenId) external;
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

interface IPairV1 is IERC20Metadata {
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

    // PairV1
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

interface IVoterV1 is IOwnable {
    function ve() external view returns (address);

    function attachVeTokenToGauge(uint256 _tokenId, address account) external;

    function detachVeTokenFromGauge(uint256 _tokenId, address account) external;

    function distribute(address _gauge) external;

    function notifyRewardAmount(uint256 amount) external;

    function createGauge(address _pool) external returns (address);

    function vote(
        uint256 _tokenId,
        address[] calldata _pools,
        int256[] calldata _weights
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {Point} from "../libraries/PointLib.sol";

interface IVe is IERC721Metadata {
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

interface IGaugeV1 {
    function notifyRewardAmount(address token, uint256 amount) external;

    function getRewards(address[] memory tokens) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);
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

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
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
     * @return min Epoch that is equal to or immediately before `_block`
     */
    function findBlockEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 _block,
        uint256 max
    ) internal view returns (uint256 min) {
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
    }

    /**
     * @notice Binary search to find epoch equal to or immediately before `timestamp`.
     *         WARNING: If `timestamp` < `pointHistory[0].timestamp`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm almost the same as `findBlockEpoch`
     * @param pointHistory Mapping from uint => Point
     * @param timestamp Timestamp to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return min Epoch that is equal to or immediately before `timestamp`
     */
    function findTimestampEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 timestamp,
        uint256 max
    ) internal view returns (uint256 min) {
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
    }

    /**
     * @notice Calculates bias (used for VE total supply and user balance),
     * returns 0 if bias < 0
     * @param point Point
     * @param dt time delta in seconds
     */
    function calculateBias(Point memory point, uint256 dt)
        internal
        pure
        returns (uint256)
    {
        int128 bias = point.bias - point.slope * int128(int256(dt));
        if (bias > 0) {
            return uint256(int256(bias));
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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