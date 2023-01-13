// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/// @notice IERC20 with Metadata + Permit
interface IERC20 is IERC2612 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

interface ILuck is IERC20 {
    function burn(address holder, uint256 amount) external;

    function mint(address recipient, uint256 amount) external;

    function setBurner(address burner, bool approved) external;

    function setMinter(address minter, bool approved) external;

    function burners(address burner) external view returns (bool);

    function minters(address minter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";

interface IRewarder {
    function onReward(address user, uint256 newLpAmount) external returns (uint256);

    function pendingTokens(address user) external view returns (uint256 pending);

    function rewardToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISaloon {
    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingHum,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(uint256 _pid) external view returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@rari-capital/solmate/src/auth/Owned.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ILuck.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/ISaloon.sol";

contract Saloon is Owned, ReentrancyGuard, ISaloon {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of LUCKs
        // entitled to a user but is pending to be distributed is:
        //
        //   ((user.amount * pool.accLuckPerShare) / 1e12) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accLuckPerShare` and `lastRewardTimestamp` gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract
        uint256 allocPoint; // How many allocation points assigned to this pool. LUCKs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that LUCKs distribution occurs.
        uint256 accLuckPerShare; // Accumulated LUCKs per share, times 1e12.
        IRewarder rewarder;
    }

    // It's the Luck of the Draw (LUCK token)
    ILuck public luck;

    // New Saloon address for future migrations
    ISaloon public newSaloon;

    // LUCK tokens created per second.
    uint256 public luckPerSec;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The timestamp when Luck mining starts.
    uint256 public startTimestamp;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Set of all LP tokens that have been added as pools
    mapping(address => bool) private lpTokens;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Amount of claimable Luck the user has
    mapping(uint256 => mapping(address => uint256)) public claimableLuck;

    event Add(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, IRewarder indexed rewarder);
    event Set(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositFor(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdatePool(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accLuckPerShare);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 luckPerSec);

    /// @notice Saloon constructor function
    /// @param _luck The Luck contract
    /// @param _luckPerSec Amount of LUCK emitted by the pool per second
    /// @param _startTimestamp The UNIX timestamp when LUCK emissions start
    constructor(
        ILuck _luck,
        uint256 _luckPerSec,
        uint256 _startTimestamp
    ) Owned(msg.sender) {
        require(address(_luck) != address(0), "Saloon:Init::InvalidToken");
        require(_luckPerSec != 0, "Saloon:Init::InvalidEmissionRate");

        luck = _luck;
        luckPerSec = _luckPerSec;
        startTimestamp = _startTimestamp;
    }

    /// @notice Deposit LP tokens for Luck allocation
    /// @dev it is possible to call this function with _amount == 0 to claim current rewards
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    function deposit(uint256 _pid, uint256 _amount) external override nonReentrant returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        uint256 pending;
        if (user.amount > 0) {
            // Harvest Luck
            pending = ((user.amount * pool.accLuckPerShare) / 1e12) + claimableLuck[_pid][msg.sender] - user.rewardDebt;
            claimableLuck[_pid][msg.sender] = 0;

            luck.mint(msg.sender, pending);
            emit Harvest(msg.sender, _pid, pending);
        }

        // update amount of lp staked by user
        user.amount += _amount;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accLuckPerShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        uint256 additionalRewards;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onReward(msg.sender, user.amount);
        }

        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(msg.sender, _pid, _amount);
        return (pending, additionalRewards);
    }

    /// @notice Deposit LP tokens on behalf of another user
    /// @param _pid the pool id
    /// @param _amount amount to deposit
    /// @param _user the user being represented
    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external override nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        // update pool in case user has deposited
        _updatePool(_pid);
        if (user.amount > 0) {
            // Harvest Luck
            uint256 pending = ((user.amount * pool.accLuckPerShare) / 1e12) + claimableLuck[_pid][msg.sender] - user.rewardDebt;
            claimableLuck[_pid][msg.sender] = 0;

            luck.mint(_user, pending);
            emit Harvest(_user, _pid, pending);
        }

        // update amount of lp staked by user
        user.amount += _amount;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accLuckPerShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        if (address(rewarder) != address(0)) {
            rewarder.onReward(_user, user.amount);
        }

        pool.lpToken.transferFrom(msg.sender, address(this), _amount);
        emit DepositFor(_user, _pid, _amount);
    }

    /// @notice Helper function to migrate fund from multiple pools to the new Saloon
    /// @notice user must initiate transaction from Saloon
    /// @dev Assume the orginal Saloon has stopped emisions
    /// hence we can skip updatePool() to save gas cost
    function migrate(uint256[] calldata _pids) external override nonReentrant {
        require(address(newSaloon) != (address(0)), "Saloon:Migrate::InvalidMigrator");

        _multiClaim(_pids);
        for (uint256 i = 0; i < _pids.length; ++i) {
            uint256 pid = _pids[i];
            UserInfo storage user = userInfo[pid][msg.sender];

            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];
                pool.lpToken.approve(address(newSaloon), user.amount);
                newSaloon.depositFor(pid, user.amount, msg.sender);
                user.amount = 0;
            }
        }
    }

    /// @notice claims rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function multiClaim(uint256[] memory _pids)
        external
        override
        nonReentrant
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        return _multiClaim(_pids);
    }

    /// @notice Update reward variables of the given pool to be up-to-date.
    /// @param _pid the pool id
    function updatePool(uint256 _pid) external override {
        _updatePool(_pid);
    }

    /// @notice Withdraw LP tokens from Saloon.
    /// @notice Automatically harvest pending rewards and sends to user
    /// @param _pid the pool id
    /// @param _amount the amount to withdraw
    function withdraw(uint256 _pid, uint256 _amount) external override nonReentrant returns (uint256, uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "Saloon:Withdraw::InvalidAmount");

        _updatePool(_pid);

        // Harvest Luck
        uint256 pending = ((user.amount * pool.accLuckPerShare) / 1e12) + claimableLuck[_pid][msg.sender] - user.rewardDebt;
        claimableLuck[_pid][msg.sender] = 0;

        luck.mint(msg.sender, pending);
        emit Harvest(msg.sender, _pid, pending);

        // update amount of lp staked
        user.amount = user.amount - _amount;

        // update reward debt
        user.rewardDebt = (user.amount * pool.accLuckPerShare) / 1e12;

        IRewarder rewarder = poolInfo[_pid].rewarder;
        uint256 additionalRewards = 0;
        if (address(rewarder) != address(0)) {
            additionalRewards = rewarder.onReward(msg.sender, user.amount);
        }

        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        return (pending, additionalRewards);
    }

    /// @notice Set the new Saloon Contract
    /// @param _newSaloon The address of the new Saloon
    function setNewSaloon(ISaloon _newSaloon) external onlyOwner {
        newSaloon = _newSaloon;
    }

    /// @notice updates emission rate
    /// @param _luckPerSec Luck amount to be updated
    /// @dev Pancake has to add hidden dummy pools inorder to alter the emission,
    /// @dev here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _luckPerSec) external onlyOwner {
        massUpdatePools();
        luckPerSec = _luckPerSec;
        emit UpdateEmissionRate(msg.sender, _luckPerSec);
    }

    /// @notice View function to see pending LUCK on frontend.
    /// @param _pid the pool id
    /// @param _user the user address
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        override
        returns (
            uint256 pendingLuck,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accLuckPerShare = pool.accLuckPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;
            uint256 luckReward = (secondsElapsed * luckPerSec * pool.allocPoint) / totalAllocPoint;
            accLuckPerShare += (luckReward * 1e12) / lpSupply;
        }
        pendingLuck = ((user.amount * accLuckPerShare) / 1e12) + claimableLuck[_pid][_user] - user.rewardDebt;

        // If it's a double reward farm, we return info about the bonus token
        if (address(pool.rewarder) != address(0)) {
            (bonusTokenAddress, bonusTokenSymbol) = rewarderBonusTokenInfo(_pid);
            pendingBonusToken = pool.rewarder.pendingTokens(_user);
        }
    }

    /// @notice returns pool length
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /// @notice Add a new lp to the pool. Can only be called by the owner.
    /// @dev Reverts if the same LP token is added more than once.
    /// @param _allocPoint allocation points for this LP
    /// @param _lpToken the corresponding lp token
    /// @param _rewarder the rewarder
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        IRewarder _rewarder
    ) public onlyOwner {
        require(address(_lpToken) != address(0), "Saloon:Add::InvalidToken");
        require(!lpTokens[address(_lpToken)], "Saloon:Add::AlreadyAdded");

        // update all pools
        massUpdatePools();

        // update last time rewards were calculated to now
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;

        // add _allocPoint to total alloc points
        totalAllocPoint = totalAllocPoint + _allocPoint;

        // update PoolInfo with the new LP
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accLuckPerShare: 0,
                rewarder: _rewarder
            })
        );

        // add lpToken to the lpTokens mapping
        lpTokens[address(_lpToken)] = true;
        emit Add(poolInfo.length - 1, _allocPoint, _lpToken, _rewarder);
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    /// @param _pid the pool id
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);

        // update user
        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    /// @notice Update the given pool's allocation point. Can only be called by the owner.
    /// @param _pid the pool id
    /// @param _allocPoint allocation points
    /// @param _rewarder the rewarder
    /// @param overwrite overwrite rewarder?
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool overwrite
    ) public onlyOwner {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (overwrite) {
            poolInfo[_pid].rewarder = _rewarder;
        }
        emit Set(_pid, _allocPoint, overwrite ? _rewarder : poolInfo[_pid].rewarder, overwrite);
    }

    /// @notice Update reward variables for all pools.
    /// @dev Be careful of gas spending!
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /// @notice Get bonus token info from the rewarder contract for a given pool, if it is a double reward farm
    /// @param _pid the pool id
    function rewarderBonusTokenInfo(uint256 _pid) public view override returns (address bonusTokenAddress, string memory bonusTokenSymbol) {
        PoolInfo storage pool = poolInfo[_pid];
        if (address(pool.rewarder) != address(0)) {
            bonusTokenAddress = address(pool.rewarder.rewardToken());
            bonusTokenSymbol = IERC20(pool.rewarder.rewardToken()).symbol();
        }
    }

    function _updatePool(uint256 _pid) private {
        PoolInfo storage pool = poolInfo[_pid];
        // update only if now > last time we updated rewards
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));

            // if balance of lp supply is 0, update lastRewardTime and quit function
            if (lpSupply == 0) {
                pool.lastRewardTimestamp = block.timestamp;
                return;
            }
            // calculate seconds elapsed since last update
            uint256 secondsElapsed = block.timestamp - pool.lastRewardTimestamp;

            // calculate LUCKs reward
            uint256 luckReward = (secondsElapsed * luckPerSec * pool.allocPoint) / totalAllocPoint;

            // update accLuckPerShare to reflect rewards
            pool.accLuckPerShare += (luckReward * 1e12) / lpSupply;

            // update lastRewardTimestamp to now
            pool.lastRewardTimestamp = block.timestamp;
            emit UpdatePool(_pid, pool.lastRewardTimestamp, lpSupply, pool.accLuckPerShare);
        }
    }

    /// @notice private function to claim rewards for multiple pids
    /// @param _pids array pids, pools to claim
    function _multiClaim(uint256[] memory _pids)
        private
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        )
    {
        // accumulate rewards for each one of the pids in pending
        uint256 pending;
        uint256[] memory amounts = new uint256[](_pids.length);
        uint256[] memory additionalRewards = new uint256[](_pids.length);
        for (uint256 i = 0; i < _pids.length; ++i) {
            _updatePool(_pids[i]);
            PoolInfo storage pool = poolInfo[_pids[i]];
            UserInfo storage user = userInfo[_pids[i]][msg.sender];
            if (user.amount > 0) {
                // increase pending to send all rewards once
                uint256 poolRewards = ((user.amount * pool.accLuckPerShare) / 1e12) + claimableLuck[_pids[i]][msg.sender] - user.rewardDebt;

                claimableLuck[_pids[i]][msg.sender] = 0;

                // update reward debt
                user.rewardDebt = (user.amount * pool.accLuckPerShare) / 1e12;

                // increase pending
                pending += poolRewards;

                amounts[i] = poolRewards;
                // if existant, get external rewarder rewards for pool
                IRewarder rewarder = pool.rewarder;
                if (address(rewarder) != address(0)) {
                    additionalRewards[i] = rewarder.onReward(msg.sender, user.amount);
                }
            }
        }
        // transfer all remaining rewards
        luck.mint(msg.sender, pending);
        for (uint256 i = 0; i < _pids.length; ++i) {
            // emit event for pool
            emit Harvest(msg.sender, _pids[i], amounts[i]);
        }

        return (pending, amounts, additionalRewards);
    }
}