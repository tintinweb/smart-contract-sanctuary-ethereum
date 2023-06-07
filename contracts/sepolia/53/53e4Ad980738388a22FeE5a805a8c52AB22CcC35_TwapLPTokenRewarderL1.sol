// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './abstracts/TwapLPTokenRewarder.sol';

contract TwapLPTokenRewarderL1 is TwapLPTokenRewarder {
    using SafeMath for uint256;
    using SafeMath for int256;
    using TransferHelper for address;

    constructor(address _itgr) TwapLPTokenRewarder(_itgr) {}

    function sendReward(uint256 amount, address to) internal override {
        IIntegralToken(itgr).mint(to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import '../libraries/SafeMath.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/ITwapLPTokenRewarder.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IIntegralToken.sol';

abstract contract TwapLPTokenRewarder is ITwapLPTokenRewarder {
    using SafeMath for uint256;
    using SafeMath for int256;
    using TransferHelper for address;

    uint256 private locked;

    uint256 internal constant ACCUMULATED_ITGR_PRECISION = 1e12;

    address public immutable itgr;
    address public owner;
    uint256 public totalAllocationPoints;
    uint256 public itgrPerSecond;
    bool public stakeDisabled;
    PoolInfo[] public pools;
    address[] public lpTokens;

    mapping(uint256 => mapping(address => UserInfo)) public users;
    mapping(address => bool) public addedLpTokens;

    constructor(address _itgr) {
        itgr = _itgr;
        owner = msg.sender;

        emit OwnerSet(msg.sender);
    }

    modifier lock() {
        require(locked == 0, 'LR06');
        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @notice Set the owner of the contract.
     * @param _owner New owner of the contract.
     */
    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'LR00');
        require(_owner != address(0), 'LR02');
        require(_owner != owner, 'LR01');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    /**
     * @notice Set the amount of ITGR per second.
     * @param _itgrPerSecond Amount of ITGR per second.
     */
    function setItgrPerSecond(uint256 _itgrPerSecond, bool withPoolsUpdate) external override {
        require(msg.sender == owner, 'LR00');
        require(_itgrPerSecond != itgrPerSecond, 'LR01');

        if (withPoolsUpdate) {
            updateAllPools();
        }

        itgrPerSecond = _itgrPerSecond;
        emit ItgrPerSecondSet(_itgrPerSecond);
    }

    /**
     * @notice Set a flag for disabling new staking.
     * @param _stakeDisabled Flag if new staking will not be accepted.
     */
    function setStakeDisabled(bool _stakeDisabled) external override {
        require(msg.sender == owner, 'LR00');
        require(_stakeDisabled != stakeDisabled, 'LR01');
        stakeDisabled = _stakeDisabled;
        emit StakeDisabledSet(stakeDisabled);
    }

    /**
     * @notice View function to see the number of pools.
     */
    function poolCount() external view override returns (uint256 length) {
        length = pools.length;
    }

    /**
     * @notice Add a new LP pool.
     * @param token Staked LP token.
     * @param allocationPoints Allocation points of the new pool.
     * @dev Call `updatePools` or `updateAllPools` function before adding a new pool to update all active pools.
     */
    function addPool(
        address token,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external override {
        require(msg.sender == owner, 'LR00');
        require(addedLpTokens[token] == false, 'LR69');

        if (withPoolsUpdate) {
            updateAllPools();
        }

        totalAllocationPoints = totalAllocationPoints.add(allocationPoints);
        lpTokens.push(token);
        pools.push(
            PoolInfo({
                accumulatedItgrPerShare: 0,
                allocationPoints: allocationPoints.toUint64(),
                lastRewardTimestamp: block.timestamp.toUint64()
            })
        );

        addedLpTokens[token] = true;

        emit PoolAdded(pools.length.sub(1), token, allocationPoints);
    }

    /**
     * @notice Update allocationPoints of the given LP pool.
     * @param pid ID of the LP pool.
     * @param allocationPoints New allocation points of the pool.
     * @dev Call `updatePools` or `updateAllPools` function before setting allocation points to update all active pools.
     */
    function setPoolAllocationPoints(
        uint256 pid,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external override {
        require(msg.sender == owner, 'LR00');

        if (withPoolsUpdate) {
            updateAllPools();
        }

        totalAllocationPoints = totalAllocationPoints.sub(pools[pid].allocationPoints).add(allocationPoints);
        pools[pid].allocationPoints = allocationPoints.toUint64();

        emit PoolSet(pid, allocationPoints);
    }

    /**
     * @notice Stake LP tokens for ITGR rewards.
     * @param pid ID of the LP pool.
     * @param amount Amount of LP token to stake.
     * @param to Receiver of staked LP token `amount` profit.
     */
    function stake(
        uint256 pid,
        uint256 amount,
        address to
    ) external override lock {
        require(!stakeDisabled, 'LR70');
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][to];

        lpTokens[pid].safeTransferFrom(msg.sender, address(this), amount);

        user.lpAmount = user.lpAmount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        emit Staked(msg.sender, pid, amount, to);
    }

    /**
     * @notice Remove staked LP tokens WITHOUT CLAIMING REWARDS. Using this function will NOT cause losing accrued rewards for the amount of unstaked LP token.
     * @param pid ID of the LP pool.
     * @param amount Amount of staked LP toked to unstake.
     * @param to LP tokens receiver.
     */
    function unstake(
        uint256 pid,
        uint256 amount,
        address to
    ) external override lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        user.lpAmount = user.lpAmount.sub(amount);
        user.rewardDebt = user.rewardDebt.sub(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        lpTokens[pid].safeTransfer(to, amount);

        emit Unstaked(msg.sender, pid, amount, to);
    }

    /**
     * @notice Remove ALL staked LP tokens WITHOUT CLAIMING REWARDS. Using this function will cause losing accrued rewards.
     * @param pid ID of the LP pool.
     * @param to LP tokens receiver.
     */
    function emergencyUnstake(uint256 pid, address to) external override lock {
        UserInfo storage user = users[pid][msg.sender];
        uint256 amount = user.lpAmount;

        user.lpAmount = 0;
        user.rewardDebt = 0;

        lpTokens[pid].safeTransfer(to, amount);

        emit EmergencyUnstaked(msg.sender, pid, amount, to);
    }

    /**
     * @notice Remove staked LP token and claim ITGR rewards for a given LP token.
     * @param pid ID of the LP pool.
     * @param amount Amount of staked LP token to unstake.
     * @param to Reward and LP tokens receiver.
     */
    function unstakeAndClaim(
        uint256 pid,
        uint256 amount,
        address to
    ) external override lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        int256 accumulatedItgr = (user.lpAmount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION)
            .toInt256();
        uint256 _claimable = uint256(accumulatedItgr.sub(user.rewardDebt));

        user.lpAmount = user.lpAmount.sub(amount);
        user.rewardDebt = accumulatedItgr.sub(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        if (_claimable > 0) {
            sendReward(_claimable, to);
        }
        lpTokens[pid].safeTransfer(to, amount);

        emit Unstaked(msg.sender, pid, amount, to);
        emit Claimed(msg.sender, pid, _claimable, to);
    }

    /**
     * @notice Claim ITGR reward for given LP token.
     * @param pid ID of the LP pool.
     * @param to Reward tokens receiver.
     */
    function claim(uint256 pid, address to) external override lock {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        int256 accumulatedItgr = (user.lpAmount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION)
            .toInt256();
        uint256 _claimable = uint256(accumulatedItgr.sub(user.rewardDebt));

        user.rewardDebt = accumulatedItgr;

        if (_claimable > 0) {
            sendReward(_claimable, to);
        }

        emit Claimed(msg.sender, pid, _claimable, to);
    }

    /**
     * @notice View function to see claimable ITGR rewards for a user that is staking LP tokens.
     * @param pid ID of the LP pool.
     * @param userAddress User address that is staking LP tokens.
     */
    function claimable(uint256 pid, address userAddress) external view override returns (uint256 _claimable) {
        PoolInfo memory pool = pools[pid];
        UserInfo storage user = users[pid][userAddress];

        uint256 accumulatedItgrPerShare = pool.accumulatedItgrPerShare;
        uint256 lpSupply = IERC20(lpTokens[pid]).balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTimestamp);
            uint256 itgrReward = time.mul(itgrPerSecond).mul(pool.allocationPoints).div(totalAllocationPoints);
            accumulatedItgrPerShare = accumulatedItgrPerShare.add(
                itgrReward.mul(ACCUMULATED_ITGR_PRECISION) / lpSupply
            );
        }

        _claimable = uint256(
            (user.lpAmount.mul(accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256().sub(user.rewardDebt)
        );
    }

    /**
     * @notice Withdraw all ITGR tokens from the contract.
     * @param to Receiver of the ITGR tokens.
     */
    function withdraw(address to) external lock {
        require(msg.sender == owner, 'LR00');

        uint256 balance = IERC20(itgr).balanceOf(address(this));
        if (balance > 0) {
            itgr.safeTransfer(to, balance);
        }
    }

    /**
     * @notice Update reward variables of the given LP pools.
     * @param pids IDs of the LP pools to be updated.
     */
    function updatePools(uint256[] calldata pids) external override {
        uint256 pidsLength = pids.length;
        for (uint256 i; i < pidsLength; ++i) {
            updatePool(pids[i]);
        }
    }

    /**
     * @notice Update reward variables of all LP pools.
     */
    function updateAllPools() public override {
        uint256 poolLength = pools.length;
        for (uint256 i; i < poolLength; ++i) {
            updatePool(i);
        }
    }

    /**
     * @notice Update reward variables of the given LP pool.
     * @param pid ID of the LP pool.
     * @dev This function does not require a lock. Consider adding a lock in case of future modifications.
     */
    function updatePool(uint256 pid) public override returns (PoolInfo memory pool) {
        pool = pools[pid];
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lpSupply = IERC20(lpTokens[pid]).balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTimestamp);
                uint256 itgrReward = time.mul(itgrPerSecond).mul(pool.allocationPoints).div(totalAllocationPoints);
                pool.accumulatedItgrPerShare = pool.accumulatedItgrPerShare.add(
                    (itgrReward.mul(ACCUMULATED_ITGR_PRECISION) / lpSupply)
                );
            }
            pool.lastRewardTimestamp = block.timestamp.toUint64();
            pools[pid] = pool;

            emit PoolUpdated(pid, pool.lastRewardTimestamp, lpSupply, pool.accumulatedItgrPerShare);
        }
    }

    function sendReward(uint256 amount, address to) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

interface IIntegralToken {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

interface ITwapLPTokenRewarder {
    struct UserInfo {
        uint256 lpAmount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint256 accumulatedItgrPerShare;
        uint64 lastRewardTimestamp;
        uint64 allocationPoints;
    }

    event Staked(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Unstaked(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyUnstaked(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Claimed(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event PoolAdded(uint256 indexed pid, address indexed lpToken, uint256 allocationPoints);
    event PoolSet(uint256 indexed pid, uint256 allocationPoints);
    event PoolUpdated(
        uint256 indexed pid,
        uint64 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accumulatedItgrPerShare
    );
    event ItgrPerSecondSet(uint256 itgrPerSecond);
    event StakeDisabledSet(bool stakeDisabled);
    event OwnerSet(address owner);

    function setOwner(address _owner) external;

    function setItgrPerSecond(uint256 _itgrPerSecond, bool withPoolsUpdate) external;

    function setStakeDisabled(bool _disabled) external;

    function poolCount() external view returns (uint256 length);

    function addPool(
        address token,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external;

    function setPoolAllocationPoints(
        uint256 pid,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external;

    function updatePool(uint256 pid) external returns (PoolInfo memory pool);

    function updatePools(uint256[] calldata pids) external;

    function updateAllPools() external;

    function stake(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function unstake(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyUnstake(uint256 pid, address to) external;

    function claim(uint256 pid, address to) external;

    function unstakeAndClaim(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function claimable(uint256 pid, address userAddress) external view returns (uint256 _claimable);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM4E');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM12');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM2A');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM43');
        return a / b;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (a != mul(b, c)) {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM50');
        return uint32(n);
    }

    function toUint64(uint256 n) internal pure returns (uint64) {
        require(n <= type(uint64).max, 'SM54');
        return uint64(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM51');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM34');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');
    }

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        c = a * b;
        require(c / a == b, 'SM29');
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        return a / b;
    }

    function neg_floor_div(int256 a, int256 b) internal pure returns (int256 c) {
        c = div(a, b);
        if ((a < 0 && b > 0) || (a >= 0 && b < 0)) {
            if (a != mul(b, c)) {
                c = sub(c, 1);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH4B');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH05');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH0E');
    }

    function safeTransferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal {
        (bool success, ) = to.call{ value: value, gas: gasLimit }('');
        require(success, 'TH3F');
    }

    function transferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal returns (bool success) {
        (success, ) = to.call{ value: value, gas: gasLimit }('');
    }
}