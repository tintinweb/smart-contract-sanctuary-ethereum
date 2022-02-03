// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

//Utilities
import "./interfaces/IUnipilotFarm.sol";
import "./interfaces/IUnipilotStake.sol";
import "./helper/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

// openzeppelin helpers
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract UnipilotFarm is IUnipilotFarm, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // bool isFarmingActive;
    address private governance;
    address private immutable pilot;
    address private stakeContract;
    uint256 public rewardPerBlock;
    uint256 public totalPools;
    uint256 public farmingGrowthBlockLimit;

    //reveal pool address on basis of index
    mapping(uint256 => address) private pools;

    //reveal struct pool data on basis of pool
    mapping(address => PoolInfo) public poolInfo;

    //reveal struct pool alt data on basis of pool
    mapping(address => AltInfo) public poolAltInfo;

    //reveal pool user's data on basis of pool and user address
    mapping(address => mapping(address => UserInfo)) public userInfo;

    //reveal status of pool
    mapping(address => bool) public poolWhitelist;

    constructor(
        address _governance,
        address _pilot,
        uint256 _rewardPerBlock
    ) {
        governance = _governance;
        pilot = _pilot;
        rewardPerBlock = _rewardPerBlock;
        // isFarmingActive = true;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "NA");
        _;
    }

    // modifier isActive() {
    //     require(isFarmingActive, "FNA");
    //     _;
    // }

    modifier isLimitActive() {
        require(farmingGrowthBlockLimit == 0, "LA");
        _;
    }

    modifier onlyStake() {
        require(msg.sender == stakeContract, "NS");
        _;
    }

    ///@notice use for pool initialize
    ///@dev governance have rights
    ///@param _pool list of pools to be add in farm
    ///@param _multiplier multiplier w.r.t pool index
    function initializer(address[] memory _pool, uint256[] memory _multiplier)
        external
        override
        onlyGovernance
    {
        require(_pool.length == _multiplier.length, "LNS");
        uint256 blocknum = block.number;
        for (uint256 i = 0; i < _pool.length; i++) {
            if (
                !poolWhitelist[_pool[i]] &&
                poolInfo[_pool[i]].totalLpLocked == 0
            ) {
                insertPool(_pool[i], _multiplier[i]);
            } else {
                if (poolInfo[_pool[i]].reward == RewardType.Dual) {
                    poolInfo[_pool[i]].lastRewardBlock = blocknum;
                    poolAltInfo[_pool[i]].lastRewardBlock = blocknum;
                } else if (poolInfo[_pool[i]].reward == RewardType.Alt) {
                    poolAltInfo[_pool[i]].lastRewardBlock = blocknum;
                } else {
                    poolInfo[_pool[i]].lastRewardBlock = blocknum;
                }
            }
            poolWhitelist[_pool[i]] = true;
            emit PoolWhitelistStatus(_pool[i], true);
        }
    }

    ///@notice use for deposit funds
    ///@param _pool pool where to farm
    ///@param _amount the amount of tokens want to deposit
    function stakeLp(address _pool, uint256 _amount)
        external
        override
        // isActive
        isLimitActive
    {
        require(_pool != address(0) && _amount > 0, "IV");

        address caller = msg.sender;
        PoolInfo storage poolState = poolInfo[_pool];
        UserInfo memory userState = userInfo[_pool][caller];
        require(poolWhitelist[_pool], "TNL");

        if (poolState.lastRewardBlock != poolState.startBlock) {
            uint256 blockDiff = block.number.sub(poolState.lastRewardBlock);
            poolState.globalReward = getGlobalReward(
                _pool,
                blockDiff,
                poolState.multiplier,
                poolState.globalReward
            );
        }

        // check if user already have reward in this lp, payout the debt
        // before increasing the lp count
        if (userState.reward > 0) {
            claimReward(_pool);
        }

        poolState.totalLpLocked = poolState.totalLpLocked.add(_amount);
        userInfo[_pool][caller] = UserInfo({
            pool: _pool,
            reward: poolState.globalReward,
            altReward: userState.altReward,
            LpLiquidity: userState.LpLiquidity.add(_amount),
            boosterActive: userState.boosterActive
        });

        IERC20(poolState.stakingToken).safeTransferFrom(
            caller,
            address(this),
            _amount
        );

        if (
            poolState.reward == RewardType.Dual ||
            (poolState.reward == RewardType.Alt &&
                poolAltInfo[_pool].rewardToken != address(0))
        ) {
            updateAltState(_pool);
        }

        poolState.lastRewardBlock = block.number;
        emit Deposit(caller, _pool, _amount, poolState.totalLpLocked);
    }

    ///@notice use for withdraw funds
    ///@param _pool pool where to earn reward
    ///@param _amount the amount of tokens want to withdraw
    function unstakeLp(address _pool, uint256 _amount) external override {
        require(_pool != address(0) && _amount > 0, "IA");
        address caller = msg.sender;
        PoolInfo storage poolState = poolInfo[_pool];
        UserInfo memory userState = userInfo[_pool][caller];

        claimReward(_pool);

        require(
            userState.LpLiquidity >= _amount ||
                poolState.totalLpLocked >= _amount,
            "AGTL"
        );
        poolState.totalLpLocked = poolState.totalLpLocked.sub(_amount);
        userState.LpLiquidity = userState.LpLiquidity.sub(_amount);

        IERC20(_pool).safeTransfer(caller, _amount);

        emit Withdraw(caller, _pool, _amount);

        if (poolState.totalLpLocked == 0) {
            poolState.startBlock = block.number;
            poolState.lastRewardBlock = block.number;
            poolState.globalReward = 0;

            AltInfo memory altState = poolAltInfo[_pool];
            altState.startBlock = block.number;
            altState.lastRewardBlock = block.number;
            altState.globalReward = 0;
        }

        if (userState.LpLiquidity == 0) {
            delete userInfo[_pool][caller];
        }
    }

    ///@notice use for withdraw rewards
    ///@param _pool earn reward from this pool
    function claimReward(address _pool)
        public
        override
        nonReentrant
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        )
    {
        require(_pool != address(0), "PNE");
        address caller = msg.sender;
        uint256 timestamp = block.timestamp;
        uint256 blocknum = block.number;
        PoolInfo storage poolState = poolInfo[_pool];
        AltInfo storage poolAltState = poolAltInfo[_pool];
        (reward, altReward, gr, altGr) = currentReward(_pool);

        if (poolState.reward == RewardType.Dual) {
            poolAltState.globalReward = gr;
            poolAltState.lastRewardBlock = blocknum;
            userInfo[_pool][caller].reward = gr;

            poolState.globalReward = altGr;
            poolState.lastRewardBlock = blocknum;
            userInfo[_pool][caller].altReward = altGr;

            IERC20(pilot).safeTransfer(caller, reward);
            IERC20(poolAltState.rewardToken).safeTransfer(caller, altReward);
            emit Reward(pilot, caller, _pool, reward, timestamp);
            emit Reward(
                poolAltState.rewardToken,
                caller,
                _pool,
                altReward,
                timestamp
            );
        } else if (poolState.reward == RewardType.Alt) {
            userInfo[_pool][caller].altReward = altGr;
            poolState.globalReward = altGr;
            poolState.lastRewardBlock = blocknum;
            IERC20(poolAltState.rewardToken).safeTransfer(caller, altReward);
            emit Reward(
                poolAltState.rewardToken,
                caller,
                _pool,
                altReward,
                timestamp
            );
        } else {
            userInfo[_pool][caller].reward = gr;
            poolAltState.globalReward = gr;
            poolAltState.lastRewardBlock = blocknum;
            IERC20(pilot).safeTransfer(caller, reward);
            emit Reward(pilot, caller, _pool, reward, timestamp);
        }
    }

    /// @notice toggles to the whitelist and blacklist of vaults
    /// @dev Must be called by the current governance
    /// @param _pool Array of address of pools for bulk update
    function whitelistPools(address[] memory _pool)
        external
        override
        onlyGovernance
    {
        for (uint256 i = 0; i < _pool.length; i++) {
            address toggleAddress = _pool[i];
            bool status = !poolWhitelist[pools[i]];
            poolWhitelist[pools[i]] = status;
            emit PoolWhitelistStatus(toggleAddress, status);
        }
    }

    ///@notice use for update reward of block on contract
    ///@dev governance have rights
    ///@param _value define value of reward per block
    function updateRewardPerBlock(uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_value > 0, "IV");
        emit RewardPerBlock(
            rewardPerBlock,
            rewardPerBlock = _value,
            block.timestamp
        );
        address[] memory pools = PoolListed();
        for (uint256 i = 0; i < pools.length; i++) {
            if (poolWhitelist[pools[i]]) {
                if (poolInfo[pools[i]].totalLpLocked != 0) {
                    updatePoolState(pools[i]);
                }
            }
        }
    }

    ///@notice use for update multiplier of particular pool
    ///@dev governance have rights
    ///@param _pool define pool
    ///@param _value define value of multiplier
    function updateMultiplier(address _pool, uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_pool != address(0) && _value > 0, "IV");
        updatePoolState(_pool);
        emit Multiplier(
            _pool,
            poolInfo[_pool].multiplier,
            poolInfo[_pool].multiplier = _value,
            block.timestamp
        );
    }

    ///@notice use for update multiplier of particular pool
    ///@dev governance have rights
    ///@param _pool define pool
    ///@param _value define value of multiplier
    function updateAltMultiplier(address _pool, uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_pool != address(0) && _value > 0, "IV");
        updateAltState(_pool);
        emit Multiplier(
            _pool,
            poolAltInfo[_pool].multiplier,
            poolAltInfo[_pool].multiplier = _value,
            block.timestamp
        );
    }

    ///@notice use for update governance
    ///@dev governance have rights
    ///@param _newGovernance define new address
    function updateGovernance(address _newGovernance)
        external
        override
        onlyGovernance
    {
        require(_newGovernance != address(0), "IA");

        emit GovernanceUpdated(
            governance,
            governance = _newGovernance,
            block.timestamp
        );
    }

    ///@notice use for read list of pools
    ///@dev governance have rights
    function PoolListed() public view override returns (address[] memory) {
        uint256 _poolsLength = totalPools;
        require(totalPools > 0, "NPE");
        address[] memory poolList = new address[](_poolsLength);
        for (uint256 i = 0; i < totalPools; i++) {
            poolList[i] = pools[i + 1];
        }
        return poolList;
    }

    ///@notice use for update reward type
    ///@dev governance have rights
    ///@param _pool define new address
    ///@param _rewardType define new reward type
    ///@param _altToken define update alt address
    function updateRewardType(
        address _pool,
        RewardType _rewardType,
        address _altToken
    ) external override onlyGovernance {
        AltInfo storage altState = poolAltInfo[_pool];

        emit AltUpdated(
            _pool,
            poolInfo[_pool].reward,
            poolInfo[_pool].reward = _rewardType,
            altState.rewardToken != address(0)
                ? altState.rewardToken
                : altState.rewardToken = _altToken,
            block.timestamp
        );
        if (
            poolInfo[_pool].reward == RewardType.Alt ||
            poolInfo[_pool].reward == RewardType.Dual
        ) {
            updatePoolState(_pool);
            updateAltState(_pool);
        } else {
            updatePoolState(_pool);
        }
    }

    // ///@notice use for update state of farming
    // ///@dev governance have rights
    // function toggleFarmingStatus() external override onlyGovernance {
    //     emit FarmingStatus(isFarmingActive, isFarmingActive = !isFarmingActive, block.timestamp);
    //     address[] memory pools = PoolListed();
    //     for (uint256 i = 0; i < totalPools; i++) {
    //         poolInfo[pools[i]].lastRewardBlock = block.number;

    //         if (poolInfo[pools[i]].reward == RewardType.Alt || poolInfo[pools[i]].reward == RewardType.Dual) {
    //             poolAltInfo[pools[i]].lastRewardBlock = block.number;
    //         }
    //     }
    // }

    function updateLastBlock() private {
        address[] memory pools = PoolListed();
        for (uint256 i = 0; i < totalPools; i++) {
            poolInfo[pools[i]].lastRewardBlock = block.number;

            if (
                poolInfo[pools[i]].reward == RewardType.Alt ||
                poolInfo[pools[i]].reward == RewardType.Dual
            ) {
                poolAltInfo[pools[i]].lastRewardBlock = block.number;
            }
        }
    }

    /// @notice Migrate funds to Governance address or in new Contract
    /// @dev only governance can call this
    /// @param _newContract address of new contract or wallet address
    /// @param _tokenAddress address of token which want to migrate
    /// @param _amount withdraw that amount which are required
    function migrateFunds(
        address _newContract,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyGovernance {
        require(_newContract != address(0), "CNE");
        IERC20(_tokenAddress).safeTransfer(_newContract, _amount);
        emit MigrateFunds(_newContract, _tokenAddress, _amount);
    }

    /// @notice Use to stop staking NFT(s) in contract after block limit
    function updateFarmingLimit(uint256 _blockNumber)
        external
        override
        onlyGovernance
    {
        emit UpdateFarmingLimit(
            farmingGrowthBlockLimit,
            farmingGrowthBlockLimit = _blockNumber,
            block.timestamp
        );
        updateLastBlock();
    }

    /// @notice toggle booster status on user
    function toggleBooster(address _pool, address _user) external onlyStake {
        emit ToggleBooster(
            _user,
            _pool,
            userInfo[_pool][_user].boosterActive,
            userInfo[_pool][_user].boosterActive = !userInfo[_pool][_user]
                .boosterActive
        );
    }

    // @notice set stake contract address
    function setStake(address _stakeContract) external override onlyGovernance {
        emit Stake(
            stakeContract,
            stakeContract = _stakeContract,
            block.timestamp
        );
    }

    ///@notice use for read reward on particular pool of user
    ///@param _pool define pool
    function currentReward(address _pool)
        public
        view
        override
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        )
    {
        PoolInfo storage poolState = poolInfo[_pool];
        UserInfo memory userState = userInfo[_pool][msg.sender];

        // if (isFarmingActive) {
        // Direction _check = Direction.Pilot;
        // gr = verifyLimit(_pool, _check);
        if (poolState.reward == RewardType.Dual) {
            gr = verifyLimit(_pool, Direction.Pilot);
            reward = gr.sub(userState.reward);
            reward = (reward.mul(userState.LpLiquidity)).div(1e18);
            altGr = verifyLimit(_pool, Direction.Alt);
            altReward = altGr.sub(userState.altReward);
            altReward = (altReward.mul(userState.LpLiquidity).div(1e18));
        } else if (poolState.reward == RewardType.Alt) {
            altGr = verifyLimit(_pool, Direction.Alt);
            altReward = altGr.sub(userState.altReward);
            altReward = (altReward.mul(userState.LpLiquidity).div(1e18));
        } else {
            gr = verifyLimit(_pool, Direction.Pilot);
            reward = gr.sub(userState.reward);
            reward = (reward.mul(userState.LpLiquidity)).div(1e18);
        }

        if (userState.boosterActive) {
            uint256 multiplier = IUnipilotStake(stakeContract)
                .getBoostMultiplier(msg.sender, userState.pool);
            uint256 boostedReward = (reward.mul(multiplier)).div(1e18);
            reward = reward.add((boostedReward));
        }
    }

    ///@notice use for read global reward
    ///@param _pool define pool
    ///@param _blockDiff define block difference
    ///@param _multiplier define multiplier
    ///@param _lastGlobalReward define last global reward
    function getGlobalReward(
        address _pool,
        uint256 _blockDiff,
        uint256 _multiplier,
        uint256 _lastGlobalReward
    ) public view returns (uint256 _globalReward) {
        if (poolWhitelist[_pool]) {
            _globalReward = FullMath.mulDiv(rewardPerBlock, _multiplier, 1e18);
            _globalReward = FullMath
                .mulDiv(
                    _blockDiff.mul(_globalReward),
                    1e18,
                    poolInfo[_pool].totalLpLocked
                )
                .add(_lastGlobalReward);
        } else {
            _globalReward = poolInfo[_pool].globalReward;
        }
    }

    ///@notice use for update pool states, call where required
    ///@param _pool define pool
    function updatePoolState(address _pool) private {
        PoolInfo storage poolState = poolInfo[_pool];
        if (poolState.totalLpLocked > 0) {
            uint256 currentGlobalReward = getGlobalReward(
                _pool,
                (block.number).sub(poolState.lastRewardBlock),
                poolState.multiplier,
                poolState.globalReward
            );

            poolState.globalReward = currentGlobalReward;
            poolState.lastRewardBlock = block.number;
        }
    }

    ///@notice use for update alt pool states, call where required
    ///@param _pool define pool
    function updateAltState(address _pool) private {
        AltInfo storage altState = poolAltInfo[_pool];

        if (altState.lastRewardBlock != altState.startBlock) {
            uint256 blockDiff = (block.number).sub(altState.lastRewardBlock);

            altState.globalReward = getGlobalReward(
                _pool,
                blockDiff,
                altState.multiplier,
                altState.globalReward
            );
        }

        altState.lastRewardBlock = block.number;

        userInfo[_pool][msg.sender].altReward = altState.globalReward;
    }

    ///@notice use for insert pool in farm
    ///@param _pool define pool
    ///@param _multiplier define multiplier
    function insertPool(address _pool, uint256 _multiplier) private {
        totalPools++;
        pools[totalPools] = _pool;
        poolInfo[_pool] = PoolInfo({
            stakingToken: _pool,
            startBlock: block.number,
            globalReward: 0,
            lastRewardBlock: block.number,
            totalLpLocked: 0,
            multiplier: _multiplier,
            isRewardActive: true,
            reward: RewardType.Pilot
        });

        emit Pool(
            _pool,
            rewardPerBlock,
            poolInfo[_pool].multiplier,
            poolInfo[_pool].lastRewardBlock,
            block.timestamp
        );
    }

    function verifyLimit(address _pool, Direction _check)
        private
        view
        returns (uint256 globalReward)
    {
        Cache memory state;

        if (_check == Direction.Pilot) {
            state = Cache({
                globalReward: poolInfo[_pool].globalReward,
                lastRewardBlock: poolInfo[_pool].lastRewardBlock,
                multiplier: poolInfo[_pool].multiplier
            });
        } else if (_check == Direction.Alt) {
            state = Cache({
                globalReward: poolAltInfo[_pool].globalReward,
                lastRewardBlock: poolAltInfo[_pool].lastRewardBlock,
                multiplier: poolInfo[_pool].multiplier
            });
        }

        if (
            state.lastRewardBlock < farmingGrowthBlockLimit &&
            block.number > farmingGrowthBlockLimit
        ) {
            globalReward = getGlobalReward(
                _pool,
                farmingGrowthBlockLimit.sub(state.lastRewardBlock),
                state.multiplier,
                state.globalReward
            );
        } else if (
            state.lastRewardBlock > farmingGrowthBlockLimit &&
            farmingGrowthBlockLimit > 0
        ) {
            globalReward = state.globalReward;
        } else {
            uint256 blockDifference = (block.number).sub(state.lastRewardBlock);
            globalReward = getGlobalReward(
                _pool,
                blockDifference,
                state.multiplier,
                state.globalReward
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IUnipilotFarm {
    struct UserInfo {
        address pool;
        uint256 reward;
        uint256 altReward;
        uint256 LpLiquidity;
        bool boosterActive;
    }

    struct PoolInfo {
        address stakingToken;
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 globalReward;
        uint256 totalLpLocked;
        uint256 multiplier;
        bool isRewardActive;
        RewardType reward;
    }

    struct AltInfo {
        address rewardToken;
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 multiplier;
    }

    struct Cache {
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 multiplier;
    }

    event Pool(
        address pool,
        uint256 rewardPerBlock,
        uint256 multiplier,
        uint256 lastRewardBlock,
        uint256 timestamp
    );

    enum Direction {
        Pilot,
        Alt
    }

    enum RewardType {
        Pilot,
        Alt,
        Dual
    }

    event Deposit(
        address user,
        address pool,
        uint256 amount,
        uint256 totalLpLocked
    );

    event Withdraw(address user, address pool, uint256 amount);

    event Reward(
        address token,
        address user,
        address pool,
        uint256 reward,
        uint256 timestamp
    );

    event Multiplier(
        address pool,
        uint256 old,
        uint256 updated,
        uint256 timestamp
    );

    event RewardPerBlock(uint256 old, uint256 updated, uint256 timestamp);

    event PoolWhitelistStatus(address indexed _pool, bool status);

    event FarmingStatus(bool old, bool updated, uint256 timestamp);

    event AltUpdated(
        address pool,
        RewardType old,
        RewardType updated,
        address altToken,
        uint256 timestamp
    );

    event GovernanceUpdated(address old, address updated, uint256 timestamp);

    event MigrateFunds(
        address newContract,
        address _tokenAddress,
        uint256 _amount
    );

    event UpdateFarmingLimit(uint256 old, uint256 updated, uint256 timestamp);

    event Stake(address old, address updated, uint256 timestamp);

    event ToggleBooster(
        address userAddress,
        address poolAddress,
        bool old,
        bool updated
    );

    function initializer(address[] memory _pool, uint256[] memory _multiplier)
        external;

    function whitelistPools(address[] memory _pool) external;

    function stakeLp(address pool, uint256 amount) external;

    function unstakeLp(address pool, uint256 amount) external;

    function claimReward(address pool)
        external
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        );

    function updateRewardPerBlock(uint256 value) external;

    function updateMultiplier(address pool, uint256 value) external;

    function updateAltMultiplier(address pool, uint256 value) external;

    function currentReward(address pool)
        external
        view
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        );

    function PoolListed() external view returns (address[] memory);

    function updateGovernance(address newGovernance) external;

    function updateRewardType(
        address _pool,
        RewardType _rewardType,
        address _altToken
    ) external;

    // function toggleFarmingStatus() external;

    function migrateFunds(
        address _newContract,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function updateFarmingLimit(uint256 _blockNumber) external;

    function setStake(address _stakeContract) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IUnipilotStake {
    function getBoostMultiplier(
        address userAddress,
        address poolAddress
    ) external view returns (uint256);

    function userMultiplier(address userAddress, address poolAddress)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ReentrancyGuard {
    uint8 private _unlocked = 1;

    modifier nonReentrant() {
        require(_unlocked == 1, "ReentrancyGuard: reentrant call");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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