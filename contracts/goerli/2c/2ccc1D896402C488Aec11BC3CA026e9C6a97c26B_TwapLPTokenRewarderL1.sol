// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './libraries/TwapLPTokenRewarder.sol';
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IERC20.sol';
import './interfaces/IIntegralToken.sol';

contract TwapLPTokenRewarderL1 is TwapLPTokenRewarder {
    using SafeMath for uint256;
    using SafeMath for int256;
    using TransferHelper for address;

    constructor(address _itgr) {
        ITGR = _itgr;
        owner = msg.sender;
    }

    function claim(uint256 pid) public override {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        int256 accumulatedItgr = (user.lpAmount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION)
            .toInt256();
        uint256 _claimable = uint256(accumulatedItgr.sub(user.rewardDebt));

        user.rewardDebt = accumulatedItgr;

        if (_claimable != 0) {
            IIntegralToken(ITGR).mint(msg.sender, _claimable);
        }

        emit Claimed(msg.sender, pid, _claimable);
    }

    function unstakeAndClaim(uint256 pid, uint256 amount) public override {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        int256 accumulatedItgr = (user.lpAmount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION)
            .toInt256();
        uint256 _claimable = uint256(accumulatedItgr.sub(user.rewardDebt));

        user.rewardDebt = accumulatedItgr.sub(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );
        user.lpAmount = user.lpAmount.sub(amount);

        if (_claimable != 0) {
            IIntegralToken(ITGR).mint(msg.sender, _claimable);
        }
        address(lpTokens[pid]).safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, pid, amount);
        emit Claimed(msg.sender, pid, _claimable);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

import './SafeMath.sol';
import './TransferHelper.sol';
import '../interfaces/ITwapLPTokenRewarder.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IIntegralToken.sol';

abstract contract TwapLPTokenRewarder is ITwapLPTokenRewarder {
    using SafeMath for uint256;
    using SafeMath for int256;
    using TransferHelper for address;

    address public owner;

    /// @notice Address of ITGR token.
    address public ITGR;

    PoolInfo[] public pools;
    IERC20[] public lpTokens;
    mapping(uint256 => mapping(address => UserInfo)) public users;
    mapping(address => bool) public addedLpTokens;

    uint256 public totalAllocationPoints;
    uint256 public itgrPerSecond;

    uint256 public constant ACCUMULATED_ITGR_PRECISION = 1e12;

    /**
     * @notice Set the owner of the contract.
     * @param _owner New owner of the contract.
     */
    function setOwner(address _owner) external override {
        require(msg.sender == owner, 'TO00');
        require(_owner != address(0), 'TO02');
        require(_owner != owner, 'TO01');
        owner = _owner;
        emit OwnerSet(_owner);
    }

    /**
     * @notice Set the amount of ITGR per second.
     * @param _itgrPerSecond Amount of ITGR per second.
     */
    function setItgrPerSecond(uint256 _itgrPerSecond) external override {
        require(msg.sender == owner, 'TR00');
        itgrPerSecond = _itgrPerSecond;

        emit ItgrPerSecondSet(_itgrPerSecond);
    }

    /**
     * @notice View function to see the number of pools.
     */
    function poolsLength() public view override returns (uint256 lenght) {
        lenght = pools.length;
    }

    /**
     * @notice Add a new LP pool.
     * @param token Staked LP token.
     * @param allocationPoints Allocation points of the new pool.
     */
    function addPool(IERC20 token, uint256 allocationPoints) public override {
        require(msg.sender == owner, 'TR00');
        require(addedLpTokens[address(token)] == false, 'TR55');
        totalAllocationPoints = totalAllocationPoints.add(allocationPoints);

        lpTokens.push(token);
        pools.push(
            PoolInfo({
                accumulatedItgrPerShare: 0,
                allocationPoints: allocationPoints.toUint64(),
                lastRewardTimestamp: block.timestamp.toUint64()
            })
        );

        addedLpTokens[address(token)] = true;

        emit PoolAdded(pools.length.sub(1), allocationPoints);
    }

    /**
     * @notice Update allocationPoints of the given LP pool.
     * @param pid ID of the LP pool.
     * @param allocationPoints New allocation points of the pool.
     */
    function setPool(uint256 pid, uint256 allocationPoints) public override {
        require(msg.sender == owner, 'TR00');
        totalAllocationPoints = totalAllocationPoints.sub(pools[pid].allocationPoints).add(allocationPoints);
        pools[pid].allocationPoints = allocationPoints.toUint64();

        emit PoolSet(pid, allocationPoints);
    }

    /**
     * @notice Update reward variables of the given LP pool.
     * @param pid ID of the LP pool.
     */
    function updatePool(uint256 pid) public override returns (PoolInfo memory pool) {
        pool = pools[pid];
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lpSupply = lpTokens[pid].balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 time = block.timestamp.sub(pool.lastRewardTimestamp);
                uint256 itgrReward = time.mul(itgrPerSecond).mul(pool.allocationPoints) / totalAllocationPoints;
                pool.accumulatedItgrPerShare = pool.accumulatedItgrPerShare.add(
                    (itgrReward.mul(ACCUMULATED_ITGR_PRECISION) / lpSupply)
                );
            }
            pool.lastRewardTimestamp = block.timestamp.toUint64();
            pools[pid] = pool;

            emit PoolUpdated(pid, pool.lastRewardTimestamp, lpSupply, pool.accumulatedItgrPerShare);
        }
    }

    /**
     * @notice Stake LP tokens for ITGR rewards.
     * @param pid ID of the LP pool.
     * @param amount Amount of LP token to stake.
     */
    function stake(uint256 pid, uint256 amount) public override {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        user.lpAmount = user.lpAmount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        address(lpTokens[pid]).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, pid, amount);
    }

    /**
     * @notice Remove staked LP tokens.
     * @param pid ID of the LP pool.
     * @param amount Amount of staked LP toked to unstake.
     */
    function unstake(uint256 pid, uint256 amount) public override {
        PoolInfo memory pool = updatePool(pid);
        UserInfo storage user = users[pid][msg.sender];

        user.lpAmount = user.lpAmount.sub(amount);
        user.rewardDebt = user.rewardDebt.sub(
            (amount.mul(pool.accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256()
        );

        address(lpTokens[pid]).safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, pid, amount);
    }

    /**
     * @notice Claim ITGR reward for given LP token.
     * @param pid ID of the LP pool.
     */
    function claim(uint256 pid) public virtual override;

    /**
     * @notice Remove staked LP token and claim ITGR rewards for given LP token.
     * @param pid ID of the LP pool.
     * @param amount Amount of staked LP token to unstake.
     */
    function unstakeAndClaim(uint256 pid, uint256 amount) public virtual override;

    /**
     * @notice View function to see claimable ITGR rewards for an account that is staking LP tokens.
     * @param pid ID of the LP pool.
     * @param account Account address that is staking LP tokens.
     */
    function claimable(uint256 pid, address account) public view override returns (uint256 _claimable) {
        PoolInfo memory pool = pools[pid];
        UserInfo storage user = users[pid][account];

        uint256 accumulatedItgrPerShare = pool.accumulatedItgrPerShare;
        uint256 lpSupply = lpTokens[pid].balanceOf(address(this));

        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 time = block.timestamp.sub(pool.lastRewardTimestamp);
            uint256 itgrReward = time.mul(itgrPerSecond).mul(pool.allocationPoints) / totalAllocationPoints;
            accumulatedItgrPerShare = accumulatedItgrPerShare.add(
                (itgrReward.mul(ACCUMULATED_ITGR_PRECISION)) / lpSupply
            );
        }

        _claimable = uint256(
            (user.lpAmount.mul(accumulatedItgrPerShare) / ACCUMULATED_ITGR_PRECISION).toInt256().sub(user.rewardDebt)
        );
    }
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
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
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

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');

        return c;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');

        return c;
    }

    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        int256 c = a * b;
        require(c / a == b, 'SM29');

        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        int256 c = a / b;

        return c;
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

import '../interfaces/IERC20.sol';

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

    event Staked(address user, uint256 pid, uint256 amount);
    event Unstaked(address user, uint256 pid, uint256 amount);
    event Claimed(address user, uint256 pid, uint256 amount);
    event PoolAdded(uint256 pid, uint256 allocationPoints);
    event PoolSet(uint256 pid, uint256 allocationPoints);
    event PoolUpdated(uint256 pid, uint64 lastRewardTimestamp, uint256 lpSupply, uint256 accumulatedItgrPerShare);
    event ItgrPerSecondSet(uint256 itgrPerSecond);
    event OwnerSet(address owner);

    function setOwner(address _owner) external;

    function setItgrPerSecond(uint256 _itgrPerSecond) external;

    function poolsLength() external view returns (uint256 length);

    function addPool(IERC20 token, uint256 allocationPoints) external;

    function setPool(uint256 pid, uint256 allocationPoints) external;

    function updatePool(uint256 pid) external returns (PoolInfo memory pool);

    function stake(uint256 pid, uint256 amount) external;

    function unstake(uint256 pid, uint256 amount) external;

    function claim(uint256 pid) external;

    function unstakeAndClaim(uint256 pid, uint256 amount) external;

    function claimable(uint256 pid, address account) external view returns (uint256 _claimable);
}