/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// File: contracts/interfaces/IERC20.sol

pragma solidity >=0.4.22 <0.9.0;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

// File: contracts/interfaces/IPlanetConventionalPool.sol

pragma solidity >=0.4.22 <0.9.0;

interface IPlanetConventionalPool {
    function userTokenStakeInfo(
        address _user
    )
        external
        view
        returns (
            uint256 _amount,
            uint256 _time,
            uint256 _reward,
            uint256 _startTime
        );

    function userLpStakeInfo(
        address _user
    )
        external
        view
        returns (
            uint256 _lpAmount,
            uint256 _amount,
            uint256 _time,
            uint256 _reward,
            uint256 _startTime
        );

    function getUserInfo(
        address _user
    )
        external
        view
        returns (
            bool _isExists,
            uint256 _stakeCount,
            uint256 _totalStakedToken,
            uint256 _totalStakedLp,
            uint256 _totalWithdrawanToken,
            uint256 _totalWithdrawanLp
        );
}

// File: contracts/interfaces/OwnershipManager.sol

pragma solidity >=0.4.22 <0.9.0;

abstract contract OwnershipManager {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            owner() == msg.sender,
            "OwnershipManager: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "OwnershipManager: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/interfaces/IPairInterface.sol

pragma solidity >=0.4.22 <0.9.0;

interface IPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts/PlanetStakingPool.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;





/**
 * @notice Token staking pool enables users to stake their tokens,
 *         to earn % APY for providing their tokens to the staking pool.
 */
contract PlanetStakingPool is OwnershipManager {
    struct StakingDetails {
        uint256 stakedAt;
        uint256 lastStakedAt;
        uint256 tokenAmount;
        uint256 rewardedAt;
    }
    // Tracking of internal account level staking details.
    mapping(address => StakingDetails) public stakingDetails;

    struct AccountDetails {
        uint256 tokenAmount;
        uint256 firstStakedAt;
        uint256 expectedRewards;
        uint256 totalStakeEntries;
        uint256 totalUnstakedTokens;
        uint256 totalHarvestedRewards;
    }
    // Tracking of global account level staking details.
    mapping(address => AccountDetails) public accountDetails;

    // Staking Pool token dependency.
    IERC20 public immutable PLANET_TOKEN;

    // Staking pool migration dependency.
    IPlanetConventionalPool public legacyStakingPool;

    // Tracking of staking pool details.
    uint256 public totalStakedTokens;
    uint256 public totalUniqueStakers;
    uint256 public totalExpectedRewards;
    uint256 public totalHarvestedRewards;
    uint256 public totalUnstakedTokens;

    // Staking pool % APY configurations.
    uint256 public rewardMultiplier = 5262;
    uint256 public rewardDivider = 1e12;

    // Staking pool account requirements.
    uint256 public minimumStakingAmount = 1e16;

    // Staking pool requirements.
    uint256 public maximumStakingAmount = 1e30;
    uint256 public lockinPeriod = 90 days;
    uint256 public stakingAllowedPeriod = 14 days;
    // uint256 public stakingStartDate = 1689156874;
    // uint256 public stakingLockinDate = stakingStartDate + 14 days;
    // uint256 public harvestDate = stakingLockinDate + lockinPeriod;

    // Staking pool taxation settings.
    uint256 public unstakeTaxRemovedAt = 15 days;
    uint256 public unstakeTaxPercentage = 20;

    // Tracking of taxation exempts on accounts.
    mapping(address => bool) public isExemptFromTaxation;

    // Tracking of banned accounts
    mapping(address => bool) public isBanned;

    // Staking pool reward provisioning distributor endpoint.
    address payable public rewardVault;

    // Emergency state
    bool public isPaused;
    bool public isEmergencyWithdrawEnabled;

    // Staking pool events to log core functionality.
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Harvested(address indexed staker, uint256 rewards);
    event Exempted(address indexed staker, bool isExempt);
    event Banned(address indexed staker, bool isBanned);
    event Paused(bool isPaused);
    event EmergencyWithdrawalEnabled(bool isEnabled);
    event EmergencyWithdrawn(
        address indexed staker,
        uint256 tokenAmount,
        uint256 stakedAt,
        uint256 rewardedAt
    );

    modifier onlyIfNotPaused() {
        require(!isPaused, "PlanetWBNBStakingPool: all actions are paused");
        _;
    }

    modifier onlyIfNotBanned() {
        require(!isBanned[msg.sender], "PlanetWBNBStakingPool: account banned");
        _;
    }

    /**
     * @dev Initialize contract by deploying a staking pool and setting
     *      up external dependencies.
     *
     * @param initialOwner --> The manager of access restricted functionality.
     * @param rewardToken --> The token that will be rewarded for staking in the pool.
     * @param distributor --> The reward distribution endpoint that will do reward provisioning.
     */
    constructor(
        address payable initialOwner,
        address rewardToken,
        address payable distributor
    )
        // address legacyPool
        OwnershipManager(initialOwner)
    {
        PLANET_TOKEN = IERC20(rewardToken);
        rewardVault = distributor;
        // legacyStakingPool = IPlanetConventionalPool(legacyPool);
    }

    /**
     * @notice Set the staking pool APY configurations, the reward multiplier and
     *         reward divider forms the % APY rewarded from the staking pool.
     *
     * @param newRewardMultiplier --> The multiplier used for reward calculations.
     * @param newRewardDivider --> The divider used for reward calculations.
     */
    function SetPoolAPYSettings(
        uint256 newRewardMultiplier,
        uint256 newRewardDivider
    ) external onlyOwner {
        rewardMultiplier = newRewardMultiplier;
        rewardDivider = newRewardDivider;
    }

    /**
     * @notice Set the minimum token staking requirement,
     *         the account must comply with the minimum to stake.
     *
     * @param newMinimumStakingAmount --> The minimum token amount for entry.
     */
    function SetMinimumStakingAmount(
        uint256 newMinimumStakingAmount
    ) external onlyOwner {
        minimumStakingAmount = newMinimumStakingAmount;
    }

    /**
     * @notice Set the max token staking requirement for all users,
     *         the pool must comply with the max to stake.
     *
     * @param newMaximumStakingAmount --> The maximum token amount for all users.
     */
    function SetMaximumStakingAmount(
        uint256 newMaximumStakingAmount
    ) external onlyOwner {
        maximumStakingAmount = newMaximumStakingAmount;
    }

    /**
     * @notice Set the token staking lockin period.
     *
     * @param newLockinPeriod --> The lockin period in days.
     */
    function SetLockinPeriodAmount(uint256 newLockinPeriod) external onlyOwner {
        lockinPeriod = newLockinPeriod * 1 days;
    }

    /**
     * @notice Set exempt taxation on an account,
     *         exempted accounts are not obligued to taxation.
     *
     * @param account --> The account to exempt from taxation.
     * @param isExempt --> The exempt taxation state of an account.
     */
    function SetExemptFromTaxation(
        address account,
        bool isExempt
    ) external onlyOwner {
        isExemptFromTaxation[account] = isExempt;
        emit Exempted(account, isExempt);
    }

    /**
     * @notice Set the staking pool taxation settings, the staking pool
     *         punishes premature withdrawal from the staking pool.
     *
     * @param newUnstakeTaxPercentage --> The new taxation percentage from unstaking.
     * @param newUnstakeTaxRemovedAt --> The new duration for taxation of rewards.
     */
    function SetUnstakeTaxAndDuration(
        uint256 newUnstakeTaxPercentage,
        uint256 newUnstakeTaxRemovedAt
    ) external onlyOwner {
        unstakeTaxPercentage = newUnstakeTaxPercentage;
        unstakeTaxRemovedAt = newUnstakeTaxRemovedAt;
    }

    /**
     * @notice Set the reward provisioning endpoint,
     *         this should be the distributor that handle rewards.
     *
     * @param newRewardVault --> The new distributor for reward provisioning.
     */
    function setRewardVault(address payable newRewardVault) external onlyOwner {
        rewardVault = newRewardVault;
    }

    /**
     * @notice Set restrictions on an account.
     *
     * @param account --> The account to restrict.
     * @param state --> The state of the restriction.
     */
    function setBanState(address account, bool state) external onlyOwner {
        isBanned[account] = state;
        emit Banned(account, state);
    }

    /**
     * @notice Set the staking pool in a pause.
     *
     * @param state --> The state of the staking pool.
     */
    function setPoolPauseState(bool state) external onlyOwner {
        isPaused = state;
        emit Paused(state);
    }

    /**
     * @notice Set the staking pool withdrawals into emergency.
     *
     * @param state --> The state of the emergency.
     */
    function setAllowEmergencyWithdraw(bool state) external onlyOwner {
        isEmergencyWithdrawEnabled = state;
        emit EmergencyWithdrawalEnabled(state);
    }

    /**
     * @notice Stake tokens to accumulate token rewards,
     *         token reward accumulation is based on the % APY.
     *
     * @param amount --> The amount of tokens that the account wish,
     *         to stake in the staking pool.
     */
    function stake(uint256 amount) external onlyIfNotPaused onlyIfNotBanned {
        address account = msg.sender;

        // // Check that staking has started
        // require(
        //     stakingStartDate <= block.timestamp,
        //     "PlanetStakingPool: staking not started"
        // );

        uint256 firstStakedAt = accountDetails[account].firstStakedAt;

        // Check that staking has not locked
        require(
            (block.timestamp - firstStakedAt) < stakingAllowedPeriod ||
                firstStakedAt == 0,
            "PlanetStakingPool: staking period ended"
        );

        // Check that the staked amount complies with the minimum staking requirement.
        require(
            amount >= minimumStakingAmount,
            "PlanetStakingPool: staking amount not sufficient"
        );

        // Check that the staked amount does not overflow the pool
        require(
            totalStakedTokens + amount <= maximumStakingAmount,
            "PlanetStakingPool: sufficient token staked"
        );

        // Check if the account is unique (First Stake), if yes then add it to global tracking and capture first staking time.
        if (accountDetails[account].totalStakeEntries == 0) {
            totalUniqueStakers++;
            accountDetails[account].firstStakedAt = block.timestamp;
        }

        // Transfer the staked amount of tokens to the staking pool.
        PLANET_TOKEN.transferFrom(account, address(this), amount);

        // Update internal account staking details.
        stakingDetails[account].tokenAmount += amount;
        stakingDetails[account].lastStakedAt = block.timestamp;
        // stakingDetails[account].rewardedAt = block.timestamp;

        // Update global account staking details.
        accountDetails[account].totalStakeEntries++;
        // accountDetails[account].totalStakedTokens += amount;

        totalExpectedRewards -= accountDetails[account].expectedRewards;

        uint256 rewards = calculateTokenReward(account);

        totalExpectedRewards += rewards;

        accountDetails[account].expectedRewards = rewards;

        // Update global staking pool details.
        totalStakedTokens += amount;

        // Log successful activity.
        emit Staked(account, amount);
    }

    /**
     * @notice Unstake tokens to withdraw your position from the staking pools,
     *         available rewards are transferred to the staking account.
     */
    function unstake() external onlyIfNotPaused onlyIfNotBanned {
        address account = msg.sender;

        uint256 unstakeDate = getUnstakeDate(account);

        require(
            unstakeDate >= block.timestamp,
            "PlanetStakingPool: can not unstake yet"
        );

        uint256 rewards = calculateTokenReward(account);
        if (rewards > 0) {
            PLANET_TOKEN.transferFrom(rewardVault, account, rewards);
        }

        // Update internal account staking details.
        stakingDetails[account].rewardedAt = block.timestamp;

        uint256 amount = stakingDetails[account].tokenAmount;
        delete stakingDetails[account].tokenAmount;

        // Transfer the staked amount of tokens back to the account.
        PLANET_TOKEN.transfer(account, amount);

        // Update global account staking details.
        accountDetails[account].totalUnstakedTokens += amount;
        accountDetails[account].totalHarvestedRewards += rewards;

        // Update global staking pool details.
        totalHarvestedRewards += rewards;
        totalUnstakedTokens += amount;

        // Log successful activity.
        emit Unstaked(account, amount);
        emit Harvested(account, rewards);
    }

    /**
     * @notice Withdraw your staking position in case of an emergency,
     *         you will give up pending rewards.
     */
    function emergencyWithdraw() external {
        require(
            isEmergencyWithdrawEnabled,
            "PlanetWBNBStakingPool: not enabled"
        );
        uint256 tokenAmount = stakingDetails[msg.sender].tokenAmount;

        require(tokenAmount > 0, "PlanetWBNBStakingPool: nothing to withdraw");

        delete stakingDetails[msg.sender].tokenAmount;

        if (isBanned[msg.sender]) {
            PLANET_TOKEN.transfer(owner(), tokenAmount);
        } else {
            PLANET_TOKEN.transfer(msg.sender, tokenAmount);
        }

        emit EmergencyWithdrawn(
            msg.sender,
            tokenAmount,
            stakingDetails[msg.sender].stakedAt,
            stakingDetails[msg.sender].rewardedAt
        );
    }

    /**
     * @notice Calculate the unsettled rewards for an account from staking
     *         in the pool, rewards that has not been compounded yet.
     *
     * @param account --> The account to use for reward calculation.
     */
    function calculateTokenReward(
        address account
    ) public view returns (uint256 reward) {
        uint256 rewardDuration = lockinPeriod;

        // Calculate the reward rate of an account.
        reward =
            (stakingDetails[account].tokenAmount *
                rewardDuration *
                rewardMultiplier) /
            rewardDivider;
    }

    /**
     * @notice Calculate the Unstake Date.
     *
     */
    function getUnstakeDate(
        address account
    ) public view returns (uint256 unstakeDate) {
        uint256 stakingLockinDate = accountDetails[account].firstStakedAt;
        unstakeDate = stakingLockinDate + lockinPeriod;
    }
}