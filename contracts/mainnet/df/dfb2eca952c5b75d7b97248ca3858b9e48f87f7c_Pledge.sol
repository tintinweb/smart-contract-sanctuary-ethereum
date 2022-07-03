// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract Pledge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Info of each Pledge user.
    /// `amount` token amount the user has provided.
    /// `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
    /// `pending` Pending Rewards.
    /// `depositTime` Last pledge time
    ///
    /// We do some fancy math here. Basically, any point in time, the amount of Tokens
    /// entitled to a user but is pending to be distributed is:
    ///
    ///   pending reward = (user share * pool.tokenPerShare) - user.rewardDebt
    ///
    ///   Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    ///   1. The pool's `tokenPerShare` (and `lastRewardBlock`) gets updated.
    ///   2. User receives the pending reward sent to his/her address.
    ///   3. User's `amount` gets updated. Pool's `totalBoostedShare` gets updated.
    ///   4. User's `rewardDebt` gets updated.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pending;
        uint256 depositTime;
    }

    /// @notice Info of each Pledge pool.
    /// `allocReward` The amount of allocation points assigned to the pool.
    ///     Also known as the amount of "multipliers". it defines the % of
    /// `tokenPerShare` Accumulated Tokens per share.
    /// `lastRewardBlock` Last block number that pool update action is executed.
    /// `breachTime` breach time.
    /// `breachFeeRate` breach fee rate.
    /// `feeRate` fee rate.
    /// `totalBoostedShare` The total amount of user shares in each pool. After considering the share boosts.
    struct PoolInfo {
        uint256 allocReward;
        uint256 tokenPerShare;
        uint256 lastRewardBlock;
        uint256 breachTime;
        uint256 breachFeeRate;
        uint256 feeRate;
        uint256 totalBoostedShare;
    }

    address public feeTo;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the token for each pool.
    address[] public token;
    mapping(address => bool) public tokenMap;

    /// @notice Info of each pool user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public constant ACC_TOKEN_PRECISION = 1e18;


    event AddPool(uint256 indexed pid, uint256 allocReward, address indexed token, uint256 breachTime, uint256 breachFeeRate, uint256 feeRate);
    event SetPool(uint256 indexed pid, uint256 allocReward, uint256 breachTime, uint256 breachFeeRate, uint256 feeRate);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 tokenSupply, uint256 tokenPerShare);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 fee, uint256 pending);
    event Pending(address indexed user, uint256 pending, uint256 time);
    event Divert(address indexed token, address indexed user, uint256 amount);

    constructor() {

    }

    /// @notice Returns the number of Pledge pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// DO NOT add the same token more than once. Rewards will be messed up if you do.
    /// @param _allocReward Number of allocation reward for the new pool.
    /// @param _breachTime Breach Time for the new pool.
    /// @param _breachFeeRate Breach Fee Rate for the new pool.
    /// @param _feeRate Fee Rate for the new pool.
    /// @param _token Address of the LP token.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function add(
        uint256 _allocReward,
        uint256 _breachTime,
        uint256 _breachFeeRate,
        uint256 _feeRate,
        address _token,
        bool _withUpdate
    ) external onlyOwner {
        require(!tokenMap[_token], "token already exists");
        require(_breachFeeRate <= 1000, "Breach Fee Rate ratio cannot be greater than 1000");
        require(_feeRate <= 1000, "Fee Rate ratio cannot be greater than 1000");

        if (_withUpdate) {
            massUpdatePools();
        }

        token.push(_token);
        tokenMap[_token] = true;
        poolInfo.push(
            PoolInfo({
                allocReward: _allocReward,
                lastRewardBlock: block.number,
                breachTime: _breachTime,
                breachFeeRate: _breachFeeRate,
                feeRate: _feeRate,
                tokenPerShare: 0,
                totalBoostedShare: 0
            })
        );

        emit AddPool(token.length - 1, _allocReward, _token, _breachTime, _breachFeeRate, _feeRate);

    }

    /// @notice Update the given pool's Token allocation point. Can only be called by the owner.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _allocReward New number of allocation reward for the pool.
    /// @param _breachTime Breach Time for the new pool.
    /// @param _breachFeeRate Breach Fee Rate for the new pool.
    /// @param _feeRate Fee Rate for the new pool.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function set(
        uint256 _pid,
        uint256 _allocReward,
        uint256 _breachTime,
        uint256 _breachFeeRate,
        uint256 _feeRate,
        bool _withUpdate
    ) external onlyOwner {
        // No matter _withUpdate is true or false, we need to execute updatePool once before set the pool parameters.
        updatePool(_pid);

        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo[_pid].allocReward = _allocReward;
        poolInfo[_pid].breachTime = _breachTime;
        poolInfo[_pid].breachFeeRate = _breachFeeRate;
        poolInfo[_pid].feeRate = _feeRate;
        emit SetPool(_pid, _allocReward, _breachTime, _breachFeeRate, _feeRate);
    }

    /// @notice View function for checking pending Token rewards.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _user Address of the user.
    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 tokenPerShare = pool.tokenPerShare;
        uint256 tokenSupply = pool.totalBoostedShare;

        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = block.number - pool.lastRewardBlock;

            uint256 tokenReward = multiplier * pool.allocReward;

            tokenPerShare = tokenPerShare + tokenReward * ACC_TOKEN_PRECISION / tokenSupply;
        }

        uint256 boostedAmount = user.amount * tokenPerShare;
        return boostedAmount / ACC_TOKEN_PRECISION - user.rewardDebt;
    }

    /// @notice View function for checking all pool token amount.
    /// @param _user Address of the user.
    function amountTokenAll(address _user) external view returns (uint256[] memory pids) {
        uint256 pools = poolInfo.length;
        pids = new uint256[](pools);
        for (uint256 i = 0; i < pools; i++) {
            pids[i] = userInfo[i][_user].amount;
        }
    }

    /// @notice Update reward for all the active pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo memory pool = poolInfo[pid];
            if (pool.allocReward != 0) {
                updatePool(pid);
            }
        }
    }

    /// @notice Update reward variables for the given pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePool(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 tokenSupply = pool.totalBoostedShare;
            if (tokenSupply > 0) {
                uint256 multiplier = block.number - pool.lastRewardBlock;
                uint256 tokenReward = multiplier * pool.allocReward;
                pool.tokenPerShare = pool.tokenPerShare + tokenReward * ACC_TOKEN_PRECISION / tokenSupply;
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
            emit UpdatePool(_pid, pool.lastRewardBlock, tokenSupply, pool.tokenPerShare);
        }
    }

    /// @notice Deposit tokens to pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to deposit.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amount > 0) {
            user.pending = user.pending + (user.amount * pool.tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        }

        if (_amount > 0) {
            uint256 before = IERC20(token[_pid]).balanceOf(address(this));
            IERC20(token[_pid]).safeTransferFrom(msg.sender, address(this), _amount);
            _amount = IERC20(token[_pid]).balanceOf(address(this)) - before;
            user.amount = user.amount + _amount;

            // Update total boosted share.
            pool.totalBoostedShare = pool.totalBoostedShare + _amount;
        }

        user.rewardDebt = user.amount * pool.tokenPerShare / ACC_TOKEN_PRECISION;
        user.depositTime = block.timestamp;
        poolInfo[_pid] = pool;

        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens from pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to withdraw.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: Insufficient");

        uint256 pending = user.pending + (user.amount * pool.tokenPerShare / ACC_TOKEN_PRECISION) - user.rewardDebt;
        user.pending = 0;
        if (pending > 0) {
            IERC20(token[_pid]).safeTransfer(msg.sender, pending);
        }

        uint256 fee = 0;
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            if (feeTo != address(0)) {
                uint256 feeRate = (user.depositTime + pool.breachTime >= block.timestamp) ? pool.breachFeeRate : pool.feeRate;
                if (feeRate > 0) {
                    fee = _amount * feeRate / 1000;
                    IERC20(token[_pid]).safeTransfer(feeTo, fee);
                }
            }
            IERC20(token[_pid]).safeTransfer(msg.sender, _amount - fee);

        }
        user.rewardDebt = user.amount * pool.tokenPerShare / ACC_TOKEN_PRECISION;
        poolInfo[_pid].totalBoostedShare = poolInfo[_pid].totalBoostedShare - _amount;

        emit Withdraw(msg.sender, _pid, _amount - fee, fee, pending);
        if (pending > 0) {
            emit Pending(msg.sender, pending, block.timestamp);
        }
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function divert(address _token, address _user, uint256 _amount) external onlyOwner {

        IERC20(_token).transfer(_user, _amount);

        emit Divert(_token, _user, _amount);
    }

}