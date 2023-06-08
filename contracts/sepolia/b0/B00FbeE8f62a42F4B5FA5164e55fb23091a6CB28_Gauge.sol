pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

import "interfaces/IFarm.sol";
import "./SqrtMath.sol";
import "./TransferHelper.sol";

/// @title Gause is a voting contract for liquidity pool
/// @notice Each liquidity pool will have its own Gauge contract.
/// User deposit sGOV token, i.e., sDyson token, to Gauge contract to earn additional reward.
/// This is an ERC20 contract with checkpoints.
contract Gauge {
    using SqrtMath for *;
    using TransferHelper for address;

    uint private constant REWARD_RATE_BASE_UNIT = 1e18;
    uint private constant BONUS_MULTIPLIER = 22.5e36;
    uint private constant MAX_BONUS = 1.5e18;

    IFarm public immutable farm;
    /// @dev sGOV token, i.e., sDyson token
    address public immutable SGOV;
    /// @notice Pool Id of the liquidity pool registered in Farm contract
    address public immutable poolId;
    /// @notice The first week this contract is deployed
    uint public immutable genesis;

    /// @notice Weight determines the how much reward user can earn in Farm contract.
    /// The higher the `weight`, the lower the reward
    uint public weight;
    /// @notice This is the latest total supply
    /// Use `totalSupplyAt` to query total supply in previous week
    uint public totalSupply;
    /// @notice Base reward rate
    uint public base;
    /// @notice Slope of reward rate
    /// The higher the `slope`, the faster the reward rate increases
    uint public slope;
    /// @notice Current week, i.e., number of weeks since 1970/01/01. Checkpoint is recored on per week basis
    /// @dev IMPORTANT: `thisWeek` is updated by calling `tick`, `deposit` or `applyWithdrawal`.
    /// It is EXPECTED that either one of these functions are called at least once every week
    uint public thisWeek;
    address public owner;

    struct Checkpoint {
        uint week;
        uint amount;
    }

    /// @notice Number of checkpoints user has recorded
    mapping(address => uint) public numCheckpoints;
    mapping(address => mapping(uint => Checkpoint)) checkpoints;
    mapping(uint => uint) internal _totalSupplyAt;
    /// @notice Total amount of sGov token pending for withdrawal
    mapping(address => uint) public pendingWithdrawal;
    /// @notice The week user can complete his withdrawal
    mapping(address => uint) public weekToWithdraw;

    event TransferOwnership(address newOwner);
    event Deposit(address indexed user, uint indexed week, uint amount);
    event ApplyWithdrawal(address indexed user, uint indexed week, uint amount);
    event Withdraw(address indexed user, uint amount);

    constructor(address _farm, address _sgov, address _poolId, uint _weight, uint _base, uint _slope) {
        require(_sgov != address(0), "SGOV_CANNOT_BE_ZERO");
        owner = msg.sender;
        farm = IFarm(_farm);
        SGOV = _sgov;
        poolId = _poolId;
        weight = _weight;
        base = _base;
        slope = _slope;
        thisWeek = block.timestamp / 1 weeks;
        genesis = block.timestamp / 1 weeks;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FORBIDDEN");
        _;
    }

    function transferOwnership(address _owner) external onlyOwner {
        require(_owner != address(0), "OWNER_CANNOT_BE_ZERO");
        owner = _owner;

        emit TransferOwnership(_owner);
    }

    /// @notice rescue token stucked in this contract
    /// @param tokenAddress Address of token to be rescued
    /// @param to Address that will receive token
    /// @param amount Amount of token to be rescued
    function rescueERC20(address tokenAddress, address to, uint256 amount) onlyOwner external {
        require(tokenAddress != SGOV);
        tokenAddress.safeTransfer(to, amount);
    }

    function setParams(uint _weight, uint _base, uint _slope) external onlyOwner {
        weight = _weight;
        base = _base;
        slope = _slope;
    }

    /// @notice User's latest balance, i.e., balance recorded in user's latest checkpoint
    function balanceOf(address account) public view returns (uint) {
        uint nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].amount : 0;
    }

    /// @notice User's balance at given week. If no checkpoint recorded at given week,
    /// search for latest checkpoint amoung previous ones.
    /// @dev Due to first `require` check, you can't query balance of current week. Use `balanceOf` instead.
    /// @param account User's address
    /// @param week The week we are interested to find out user's balance
    /// @return User's balance at given week
    function balanceOfAt(address account, uint week) external view returns (uint) {
        require(week < block.timestamp / 1 weeks, "NOT YET");
        require(week <= thisWeek, "NOT YET");
        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        // Check user's balance in latest checkpoint
        if (checkpoints[account][nCheckpoints - 1].week <= week) {
            return checkpoints[account][nCheckpoints - 1].amount;
        }
        // Check user's balance in his first checkpoint
        if (checkpoints[account][0].week > week) {
            return 0;
        }
        // Binary search to find user's balance in the checkpoint closest to given `week`
        uint lower = 0;
        uint upper = nCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.week == week) {
                return cp.amount;
            } else if (cp.week < week) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].amount;
    }

    /// @dev If this is a new week, add a new checkpoint
    function _writeCheckpoint(address account, uint amount) internal {
        uint _week = block.timestamp / 1 weeks;
        uint nCheckpoints = numCheckpoints[account];
        if (nCheckpoints > 0 && checkpoints[account][nCheckpoints - 1].week == _week) {
            checkpoints[account][nCheckpoints - 1].amount = amount;
        } else {
            checkpoints[account][nCheckpoints] = Checkpoint(_week, amount);
            numCheckpoints[account]++;
        }
    }

    function totalSupplyAt(uint week) public view returns (uint) {
        require(week < block.timestamp / 1 weeks, "NOT YET");

        if (week >= thisWeek) {
            return totalSupply;
        }
        else {
            return _totalSupplyAt[week];
        }
    }

    /// @notice If this is a new week, update `thisWeek`, reward rate and record total supply of past week
    function tick() public {
        uint _week = block.timestamp / 1 weeks;

        if (_week > thisWeek) {
            for(uint i = thisWeek; i < _week; ++i) {
                _totalSupplyAt[i] = totalSupply;
            }
            thisWeek = _week;
            updateRewardRate();
        }
    }

    /// @dev Update latest total supply and trigger `tick`
    function updateTotalSupply(uint _totalSupply) internal {
        tick();
        totalSupply = _totalSupply;
    }

    /// @notice Compute new reward rate base on latest total supply, `slope` and `base`
    function nextRewardRate() public view returns (uint newRewardRate) {
        // rewardRate = token * slope + base
        newRewardRate = totalSupply * slope / REWARD_RATE_BASE_UNIT + base;
    }

    /// @dev Update reward rate recorded in Farm contract
    function updateRewardRate() internal {
        try farm.setPoolRewardRate(poolId, nextRewardRate(), weight) {} catch {}
    }

    /// @notice User deposit sGov token
    /// @param amount Amount of sGov token
    function deposit(uint amount) external {
        require(amount > 0, "CANNOT DEPOSIT 0");
        SGOV.safeTransferFrom(msg.sender, address(this), amount);
        _writeCheckpoint(msg.sender, balanceOf(msg.sender) + amount);
        updateTotalSupply(totalSupply + amount);
        emit Deposit(msg.sender, block.timestamp / 1 weeks, amount);
    }

    /// @notice User requests for withdrawal of his sGov token
    /// Withdrawal will have a delay of 1 week
    /// @param amount Amount of sGov token to withdraw
    function applyWithdrawal(uint amount) external {
        require(amount > 0 ,"CANNOT WITHDRAW 0");
        require(amount <= balanceOf(msg.sender) ,"CANNOT WITHDRAW MORE THAN BALANCE");
        uint _week = block.timestamp / 1 weeks;
        _writeCheckpoint(msg.sender, balanceOf(msg.sender) - amount);
        updateTotalSupply(totalSupply - amount);
        pendingWithdrawal[msg.sender] += amount;
        weekToWithdraw[msg.sender] = _week + 1;
        emit ApplyWithdrawal(msg.sender, _week, amount);
    }

    /// @notice User completes his withdrawal
    /// @return amount Amount of sGov token withdrawn
    function withdraw() external returns (uint amount) {
        require(block.timestamp / 1 weeks >= weekToWithdraw[msg.sender], "NOT YET");
        amount = pendingWithdrawal[msg.sender];
        require(amount > 0 ,"CANNOT WITHDRAW 0");
        pendingWithdrawal[msg.sender] = 0;
        SGOV.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /// @notice User's bonus ratio computed base on his latest balance.
    /// Bonus ratio approaches max when balance gets closer to 1/10 of total supply.
    /// Bonus ratio will be capped at 1.5x
    /// @param user User's address
    /// @return _bonus User's bonus ratio 
    function bonus(address user) external view returns (uint _bonus) {
        uint balance = balanceOf(user);
        if(balance > 0) {
            _bonus = (balance * BONUS_MULTIPLIER / totalSupply).sqrt();
            _bonus = _bonus > MAX_BONUS ? MAX_BONUS : _bonus;
        }
    }

}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT

interface IFarm {
    function grantAP(address to, uint amount) external;

    function setPoolRewardRate(address poolId, uint _rewardRate, uint _w) external;
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

//https://github.com/Gaussian-Process/solidity-sqrt/blob/main/src/FixedPointMathLib.sol
library SqrtMath {
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // This segment is to get a reasonable initial estimate for the Babylonian method.
            // If the initial estimate is bad, the number of correct bits increases ~linearly
            // each iteration instead of ~quadratically.
            // The idea is to get z*z*y within a small factor of x.
            // More iterations here gets y in a tighter range. Currently, we will have
            // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
            // between y and y+1 is small. If x < 256 this is not possible, but those cases
            // are easy enough to verify exhaustively.
            z := 181 // The 'correct' value is 1, but this saves a multiply later
            let y := x
            // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
            // this is to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }
            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
            // and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

            // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
            // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
            z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

            // Run the Babylonian method seven times. This should be enough given initial estimate.
            // Possibly with a quadratic/cubic polynomial above we could get 4-6.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
            // The solmate implementation assigns zRoundDown := div(x, z) first, but
            // since this case is rare, we choose to save gas on the assignment and
            // repeat division in the rare case.
            // If you don't care whether floor or ceil is returned, you can skip this.
            if lt(div(x, z), z) {
                z := div(x, z)
            }
        }
    }
}

pragma solidity 0.8.17;

// SPDX-License-Identifier: AGPL-3.0

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}