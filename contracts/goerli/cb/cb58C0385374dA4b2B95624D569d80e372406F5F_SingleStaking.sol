/**
 *Submitted for verification at Etherscan.io on 2020-10-31
*/

/**
 * The Note Protocol Staking Smart Contract
**/

// File: @openzeppelin/contracts/math/SafeMath.sol
pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `mint`. This is
     * zero by default.
     *
     * This value changes when `mint` are called.
     */
    function mint(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `burn`. This is
     * zero by default.
     *
     * This value changes when `burn` are called.
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/IMigratableStakingContract.sol
pragma solidity 0.5.16;


/// @title An interface for staking contracts which support stake migration.
interface IMigratableStakingContract {
    /// @dev Returns the address of the underlying staked token.
    /// @return IERC20 The address of the token.
    function getToken() external view returns (IERC20);

    /// @dev Stakes THENODE tokens on behalf of msg.sender. This method assumes that the user has already approved at least
    /// @param _stakeOwner address The specified stake owner.
    /// @param _amount uint256 The number of tokens to stake.
    function acceptMigration(address _stakeOwner, uint256 _amount) external;

    event AcceptedMigration(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
}

// File: contracts/IStakingContract.sol
pragma solidity 0.5.16;


/// @title An interface for staking contracts.
interface IStakingContract {
    /// @dev Stakes THENODE tokens on behalf of msg.sender. This method assumes that the user has already approved at least
    /// @param _amount uint256 The amount of tokens to stake.
    function stake(uint256 _amount) external;

    /// @dev Unstakes THENODE tokens from msg.sender. If successful, this will start the cooldown period, after which
    /// @param _amount uint256 The amount of tokens to unstake.
    function unstake(uint256 _amount) external;

    /// @dev Requests to withdraw all of staked THENODE tokens back to msg.sender. Stake owners can withdraw their THENODE
    function withdraw() external;

    /// @dev Restakes unstaked THENODE tokens (in or after cooldown) for msg.sender.
    function restake() external;

    /// @dev Distributes staking rewards to a list of addresses by directly adding rewards to their stakes. This method
    /// @param _totalAmount uint256 The total amount of rewards to distributes.
    /// @param _stakeOwners address[] The addresses of the stake owners.
    /// @param _amounts uint256[] The amounts of the rewards.
    function distributeRewards(uint256 _totalAmount, address[] calldata _stakeOwners, uint256[] calldata _amounts) external;

    /// @dev Returns the stake of the specified stake owner (excluding unstaked tokens).
    /// @param _stakeOwner address The address to check.
    /// @return uint256 The total stake.
    function getStakeBalanceOf(address _stakeOwner) external view returns (uint256);

    /// @dev Returns the total amount staked tokens (excluding unstaked tokens).
    /// @return uint256 The total staked tokens of all stake owners.
    function getTotalStakedTokens() external view returns (uint256);

    /// @dev Returns the time that the cooldown period ends (or ended) and the amount of tokens to be released.
    /// @param _stakeOwner address The address to check.
    /// @return cooldownAmount uint256 The total tokens in cooldown.
    /// @return cooldownEndTime uint256 The time when the cooldown period ends (in seconds).
    function getUnstakeStatus(address _stakeOwner) external view returns (uint256 cooldownAmount,
        uint256 cooldownEndTime);

    /// @dev Migrates the stake of msg.sender from this staking contract to a new approved staking contract.
    /// @param _newStakingContract IMigratableStakingContract The new staking contract which supports stake migration.
    /// @param _amount uint256 The amount of tokens to migrate.
    function migrateStakedTokens(IMigratableStakingContract _newStakingContract, uint256 _amount) external;

    event Staked(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event Unstaked(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event Withdrew(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event Restaked(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
    event MigratedStake(address indexed stakeOwner, uint256 amount, uint256 totalStakedAmount);
}

// File: contracts/IStakeChangeNotifier.sol
pragma solidity 0.5.16;

/// @title An interface for notifying of stake change events (e.g., stake, unstake, partial unstake, restate, etc.).
interface IStakeChangeNotifier {
    /// @dev Notifies of stake change event.
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount uint256 The difference in the total staked amount.
    /// @param _sign bool The sign of the added (true) or subtracted (false) amount.
    /// @param _updatedStake uint256 The updated total staked amount.
    function stakeChange(address _stakeOwner, uint256 _amount, bool _sign, uint256 _updatedStake) external;

    /// @dev Notifies of multiple stake change events.
    /// @param _stakeOwners address[] The addresses of subject stake owners.
    /// @param _amounts uint256[] The differences in total staked amounts.
    /// @param _signs bool[] The signs of the added (true) or subtracted (false) amounts.
    /// @param _updatedStakes uint256[] The updated total staked amounts.
    function stakeChangeBatch(address[] calldata _stakeOwners, uint256[] calldata _amounts, bool[] calldata _signs,
        uint256[] calldata _updatedStakes) external;

    /// @dev Notifies of stake migration event.
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount uint256 The migrated amount.
    function stakeMigration(address _stakeOwner, uint256 _amount) external;
}

// File: contracts/SingleStaking.sol
pragma solidity 0.5.16;

/// @title THENODE staking smart contract.
contract SingleStaking is IStakingContract, IMigratableStakingContract {
    using SafeMath for uint256;

    struct Stake {
        uint256 amount;
        uint256 cooldownAmount;
        uint256 cooldownEndTime;
    }

    struct WithdrawResult {
        uint256 withdrawnAmount;
        uint256 stakedAmount;
        uint256 stakedAmountDiff;
    }

    uint public constant MAX_APPROVED_STAKING_CONTRACTS = 10;
    mapping(address => Stake) internal stakes;

    uint256 internal totalStakedTokens;
    uint256 public cooldownPeriodInSec;
    address public migrationManager;
    address public emergencyManager;

    // The list of staking contracts that are approved by this contract. It would be only allowed to migrate a stake to
    // one of these contracts.
    IMigratableStakingContract[] public approvedStakingContracts;
    IStakeChangeNotifier public notifier;
    IERC20 internal token;

    // Note: This can be turned off only once by the emergency manager of the contract.
    bool public acceptingNewStakes = true;

    // Note: This can be turned off only once by the emergency manager of the contract.
    bool public releasingAllStakes = false;

    event MigrationManagerUpdated(address indexed migrationManager);
    event MigrationDestinationAdded(IMigratableStakingContract indexed stakingContract);
    event MigrationDestinationRemoved(IMigratableStakingContract indexed stakingContract);
    event EmergencyManagerUpdated(address indexed emergencyManager);
    event StakeChangeNotifierUpdated(IStakeChangeNotifier indexed notifier);
    event StoppedAcceptingNewStake();
    event ReleasedAllStakes();

    modifier onlyMigrationManager() {
        require(msg.sender == migrationManager, "SingleStaking: caller is not the migration manager");

        _;
    }

    modifier onlyEmergencyManager() {
        require(msg.sender == emergencyManager, "SingleStaking: caller is not the emergency manager");

        _;
    }

    modifier onlyWhenAcceptingNewStakes() {
        require(acceptingNewStakes && !releasingAllStakes, "SingleStaking: not accepting new stakes");

        _;
    }

    modifier onlyWhenStakesReleased() {
        require(releasingAllStakes, "SingleStaking: not releasing all stakes");

        _;
    }

    modifier onlyWhenStakesNotReleased() {
        require(!releasingAllStakes, "SingleStaking: releasing all stakes");

        _;
    }

    /// @dev Initializes the staking contract.
    /// @param _cooldownPeriodInSec uint256 The period (in seconds) between a stake owner's request to stop staking and being
    /// able to withdraw them.
    /// @param _migrationManager address The address responsible for managing migration to a new staking contract.
    /// @param _emergencyManager address The address responsible for emergency operations and graceful return of staked
    /// tokens back to their owners.
    /// @param _token IERC20 The address of the THENODE token.
    constructor(uint256 _cooldownPeriodInSec, address _migrationManager, address _emergencyManager, IERC20 _token) public {
        require(_cooldownPeriodInSec > 0, "cooldown period must be greater than 0");
        require(_migrationManager != address(0), "migration manager must not be 0");
        require(_emergencyManager != address(0), "emergency manager must not be 0");
        require(address(_token) != address(0), "THENODE token must not be 0");

        cooldownPeriodInSec = _cooldownPeriodInSec;
        migrationManager = _migrationManager;
        emergencyManager = _emergencyManager;
        token = _token;
    }

    /// @dev Sets the address of the migration manager.
    /// @param _newMigrationManager address The address of the new migration manager.
    function setMigrationManager(address _newMigrationManager) external onlyMigrationManager {
        require(_newMigrationManager != address(0), "address must not be 0");
        require(migrationManager != _newMigrationManager, "address must be different than the current address");

        migrationManager = _newMigrationManager;
        emit MigrationManagerUpdated(_newMigrationManager);
    }

    /// @dev Sets the address of the emergency manager.
    /// @param _newEmergencyManager address The address of the new emergency manager.
    function setEmergencyManager(address _newEmergencyManager) external onlyEmergencyManager {
        require(_newEmergencyManager != address(0), "address must not be 0");
        require(emergencyManager != _newEmergencyManager, "address must be different than the current address");

        emergencyManager = _newEmergencyManager;
        emit EmergencyManagerUpdated(_newEmergencyManager);
    }

    /// @dev Sets the address of the stake change notifier contract.
    /// @param _newNotifier IStakeChangeNotifier The address of the new stake change notifier contract.
    function setStakeChangeNotifier(IStakeChangeNotifier _newNotifier) external onlyMigrationManager {
        require(notifier != _newNotifier, "address must be different than the current address");

        notifier = _newNotifier;
        emit StakeChangeNotifierUpdated(notifier);
    }

    /// @dev Adds a new contract to the list of approved staking contracts migration destinations.
    /// @param _newStakingContract IMigratableStakingContract The new contract to add.
    function addMigrationDestination(IMigratableStakingContract _newStakingContract) external onlyMigrationManager {
        require(address(_newStakingContract) != address(0), "address must not be 0");

        uint length = approvedStakingContracts.length;
        require(length + 1 <= MAX_APPROVED_STAKING_CONTRACTS, "can't add more staking contracts");

        for (uint i = 0; i < length; ++i) {
            require(approvedStakingContracts[i] != _newStakingContract, "can't add a duplicate staking contract");
        }

        approvedStakingContracts.push(_newStakingContract);
        emit MigrationDestinationAdded(_newStakingContract);
    }

    /// @dev Removes a contract from the list of approved staking contracts migration destinations.
    /// @param _stakingContract IMigratableStakingContract The contract to remove.
    function removeMigrationDestination(IMigratableStakingContract _stakingContract) external onlyMigrationManager {
        require(address(_stakingContract) != address(0), "address must not be 0");

        (uint i, bool exists) = findApprovedStakingContractIndex(_stakingContract);
        require(exists, "staking contract doesn't exist");

        approvedStakingContracts[i] = approvedStakingContracts[approvedStakingContracts.length - 1];
        approvedStakingContracts.pop();

        emit MigrationDestinationRemoved(_stakingContract);
    }

    /// @dev Stakes THENODE tokens on behalf of msg.sender. This method assumes that the user has already approved at least
    /// @param _amount uint256 The amount of tokens to stake.
    function stake(uint256 _amount) external onlyWhenAcceptingNewStakes {
        address stakeOwner = msg.sender;

        uint256 totalStakedAmount = stake(stakeOwner, _amount);
        emit Staked(stakeOwner, _amount, totalStakedAmount);

        stakeChange(stakeOwner, _amount, true, totalStakedAmount);
    }

    /// @dev Unstakes THENODE tokens from msg.sender. If successful, this will start the cooldown period, after which
    /// msg.sender would be able to withdraw all of his tokens.
    /// @param _amount uint256 The amount of tokens to unstake.
    function unstake(uint256 _amount) external {
        require(_amount > 0, "amount must be greater than 0");

        address stakeOwner = msg.sender;
        Stake storage stakeData = stakes[stakeOwner];
        uint256 stakedAmount = stakeData.amount;
        uint256 cooldownAmount = stakeData.cooldownAmount;
        uint256 cooldownEndTime = stakeData.cooldownEndTime;

        require(_amount <= stakedAmount, "can't unstake more than the current stake");
        require(cooldownAmount == 0 || cooldownEndTime > now, "unable to unstake when there are tokens pending withdrawal");

        stakeData.amount = stakedAmount.sub(_amount);
        stakeData.cooldownAmount = cooldownAmount.add(_amount);
        stakeData.cooldownEndTime = now.add(cooldownPeriodInSec);

        totalStakedTokens = totalStakedTokens.sub(_amount);

        uint256 totalStakedAmount = stakeData.amount;
        emit Unstaked(stakeOwner, _amount, totalStakedAmount);

        stakeChange(stakeOwner, _amount, false, totalStakedAmount);
    }

    /// @dev Requests to withdraw all of staked THENODE tokens back to msg.sender. Stake owners can withdraw their THENODE
    /// tokens only after previously unstaking them and after the cooldown period has passed (unless the contract was
    /// requested to release all stakes).
    function withdraw() external {
        address stakeOwner = msg.sender;

        WithdrawResult memory res = withdraw(stakeOwner);
        emit Withdrew(stakeOwner, res.withdrawnAmount, res.stakedAmount);

        if (res.stakedAmountDiff == 0) {
            return;
        }

        stakeChange(stakeOwner, res.stakedAmountDiff, false, res.stakedAmount);
    }

    /// @dev Restakes unstaked THENODE tokens (in or after cooldown) for msg.sender.
    function restake() external onlyWhenAcceptingNewStakes {
        address stakeOwner = msg.sender;
        Stake storage stakeData = stakes[stakeOwner];
        uint256 cooldownAmount = stakeData.cooldownAmount;

        require(cooldownAmount > 0, "no unstaked tokens");

        stakeData.amount = stakeData.amount.add(cooldownAmount);
        stakeData.cooldownAmount = 0;
        stakeData.cooldownEndTime = 0;

        totalStakedTokens = totalStakedTokens.add(cooldownAmount);

        uint256 totalStakedAmount = stakeData.amount;
        emit Restaked(stakeOwner, cooldownAmount, totalStakedAmount);

        stakeChange(stakeOwner, cooldownAmount, true, totalStakedAmount);
    }

    /// @dev Stakes THENODE tokens on behalf of msg.sender. This method assumes that the user has already approved at least
    /// the required amount using ERC20 approve.
    /// @param _stakeOwner address The specified stake owner.
    /// @param _amount uint256 The amount of tokens to stake.
    function acceptMigration(address _stakeOwner, uint256 _amount) external onlyWhenAcceptingNewStakes {
        uint256 totalStakedAmount = stake(_stakeOwner, _amount);
        emit AcceptedMigration(_stakeOwner, _amount, totalStakedAmount);

        stakeChange(_stakeOwner, _amount, true, totalStakedAmount);
    }

    /// @dev Migrates the stake of msg.sender from this staking contract to a new approved staking contract.
    /// @param _newStakingContract IMigratableStakingContract The new staking contract which supports stake migration.
    /// @param _amount uint256 The amount of tokens to migrate.
    function migrateStakedTokens(IMigratableStakingContract _newStakingContract, uint256 _amount) external
        onlyWhenStakesNotReleased {
        require(isApprovedStakingContract(_newStakingContract), "migration destination wasn't approved");
        require(_amount > 0, "amount must be greater than 0");

        address stakeOwner = msg.sender;
        Stake storage stakeData = stakes[stakeOwner];
        uint256 stakedAmount = stakeData.amount;

        require(stakedAmount > 0, "no staked tokens");
        require(_amount <= stakedAmount, "amount exceeds staked token balance");

        stakeData.amount = stakedAmount.sub(_amount);

        totalStakedTokens = totalStakedTokens.sub(_amount);

        require(_newStakingContract.getToken() == token, "staked tokens must be the same");
        require(token.approve(address(_newStakingContract), _amount), "couldn't approve transfer");

        emit MigratedStake(stakeOwner, _amount, stakeData.amount);
        _newStakingContract.acceptMigration(stakeOwner, _amount);

        stakeMigration(stakeOwner, _amount);
    }

    /// @dev Distributes staking rewards to a list of addresses by directly adding rewards to their stakes. This method
    /// assumes that the user has already approved at least the required amount using ERC20 approve. Since this is a
    /// convenience method, we aren't concerned about reaching block gas limit by using large lists. We assume that
    /// callers will be able to batch/paginate their requests properly.
    /// @param _totalAmount uint256 The total amount of rewards to distributes.
    /// @param _stakeOwners address[] The addresses of the stake owners.
    /// @param _amounts uint256[] The amounts of the rewards.
    function distributeRewards(uint256 _totalAmount, address[] calldata _stakeOwners, uint256[] calldata _amounts) external
        onlyWhenAcceptingNewStakes {
        require(_totalAmount > 0, "total amount must be greater than 0");

        uint256 stakeOwnersLength = _stakeOwners.length;
        uint256 amountsLength = _amounts.length;

        require(stakeOwnersLength > 0 && amountsLength > 0, "lists can't be empty");
        require(stakeOwnersLength == amountsLength, "lists must be of the same size");

        // Transfer all the tokens to the smart contract and update the stake owners list accordingly.
        require(token.transferFrom(msg.sender, address(this), _totalAmount), "sufficient allowance");

        bool[] memory signs = new bool[](amountsLength);
        uint256[] memory totalStakedAmounts = new uint256[](amountsLength);

        uint256 expectedTotalAmount = 0;
        for (uint i = 0; i < stakeOwnersLength; ++i) {
            address stakeOwner = _stakeOwners[i];
            uint256 amount = _amounts[i];

            require(stakeOwner != address(0), "stake owner can't be 0");
            require(amount > 0, "amount must be greater than 0");

            Stake storage stakeData = stakes[stakeOwner];
            stakeData.amount = stakeData.amount.add(amount);

            expectedTotalAmount = expectedTotalAmount.add(amount);

            uint256 totalStakedAmount = stakeData.amount;
            signs[i] = true;
            totalStakedAmounts[i] = totalStakedAmount;

            emit Staked(stakeOwner, amount, totalStakedAmount);
        }

        require(_totalAmount == expectedTotalAmount, "incorrect total amount");
        totalStakedTokens = totalStakedTokens.add(_totalAmount);

        stakeChangeBatch(_stakeOwners, _amounts, signs, totalStakedAmounts);
    }

    /// @dev Returns the stake of the specified stake owner (excluding unstaked tokens).
    /// @param _stakeOwner address The address to check.
    /// @return uint256 The stake of the stake owner.
    function getStakeBalanceOf(address _stakeOwner) external view returns (uint256) {
        return stakes[_stakeOwner].amount;
    }

    /// @dev Returns the total amount staked tokens (excluding unstaked tokens).
    /// @return uint256 The total staked tokens of all stake owners.
    function getTotalStakedTokens() external view returns (uint256) {
        return totalStakedTokens;
    }

    /// @dev Returns the time that the cooldown period ends (or ended) and the amount of tokens to be released.
    /// @param _stakeOwner address The address to check.
    /// @return cooldownAmount uint256 The total tokens in cooldown.
    /// @return cooldownEndTime uint256 The time when the cooldown period ends (in seconds).
    function getUnstakeStatus(address _stakeOwner) external view returns (uint256 cooldownAmount,
        uint256 cooldownEndTime) {
        Stake memory stakeData = stakes[_stakeOwner];
        cooldownAmount = stakeData.cooldownAmount;
        cooldownEndTime = stakeData.cooldownEndTime;
    }

    /// @dev Returns the address of the underlying staked token.
    /// @return IERC20 The address of the token.
    function getToken() external view returns (IERC20) {
        return token;
    }

    /// @dev Requests the contract to stop accepting new staking requests.
    function stopAcceptingNewStakes() external onlyEmergencyManager onlyWhenAcceptingNewStakes {
        acceptingNewStakes = false;
        emit StoppedAcceptingNewStake();
    }

    /// @dev Requests the contract to release all stakes.
    function releaseAllStakes() external onlyEmergencyManager onlyWhenStakesNotReleased {
        releasingAllStakes = true;
        emit ReleasedAllStakes();
    }

    /// @dev Requests withdraw of released tokens for a list of addresses.
    /// @param _stakeOwners address[] The addresses of the stake owners.
    function withdrawReleasedStakes(address[] calldata _stakeOwners) external onlyWhenStakesReleased {
        uint256 stakeOwnersLength = _stakeOwners.length;
        uint256[] memory stakedAmountDiffs = new uint256[](stakeOwnersLength);
        bool[] memory signs = new bool[](stakeOwnersLength);
        uint256[] memory totalStakedAmounts = new uint256[](stakeOwnersLength);

        for (uint i = 0; i < stakeOwnersLength; ++i) {
            address stakeOwner = _stakeOwners[i];

            WithdrawResult memory res = withdraw(stakeOwner);
            stakedAmountDiffs[i] = res.stakedAmountDiff;
            signs[i] = false;
            totalStakedAmounts[i] = res.stakedAmount;

            emit Withdrew(stakeOwner, res.withdrawnAmount, res.stakedAmount);
        }

        stakeChangeBatch(_stakeOwners, stakedAmountDiffs, signs, totalStakedAmounts);
    }

    /// @dev Returns whether a specific staking contract was approved as a migration destination.
    /// @param _stakingContract IMigratableStakingContract The staking contract to look for.
    /// @return exists bool The approval status.
    function isApprovedStakingContract(IMigratableStakingContract _stakingContract) public view returns (bool exists) {
        (, exists) = findApprovedStakingContractIndex(_stakingContract);
    }

    /// @dev Returns whether stake change notification is enabled.
    function shouldNotifyStakeChange() view internal returns (bool) {
        return address(notifier) != address(0);
    }

    /// @dev Notifies of stake change events.
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount int256 The difference in the total staked amount.
    /// @param _sign bool The sign of the added (true) or subtracted (false) amount.
    /// @param _updatedStake uint256 The updated total staked amount.
    function stakeChange(address _stakeOwner, uint256 _amount, bool _sign, uint256 _updatedStake) internal {
        if (!shouldNotifyStakeChange()) {
            return;
        }

        notifier.stakeChange(_stakeOwner, _amount, _sign, _updatedStake);
    }

    /// @dev Notifies of multiple stake change events.
    /// @param _stakeOwners address[] The addresses of subject stake owners.
    /// @param _amounts uint256[] The differences in total staked amounts.
    /// @param _signs bool[] The signs of the added (true) or subtracted (false) amounts.
    /// @param _updatedStakes uint256[] The updated total staked amounts.
    function stakeChangeBatch(address[] memory _stakeOwners, uint256[] memory _amounts, bool[] memory _signs,
        uint256[] memory _updatedStakes) internal {
        if (!shouldNotifyStakeChange()) {
            return;
        }

        notifier.stakeChangeBatch(_stakeOwners, _amounts, _signs, _updatedStakes);
    }

    /// @dev Notifies of stake migration event.
    /// @param _stakeOwner address The address of the subject stake owner.
    /// @param _amount uint256 The migrated amount.
    function stakeMigration(address _stakeOwner, uint256 _amount) internal {
        if (!shouldNotifyStakeChange()) {
            return;
        }

        notifier.stakeMigration(_stakeOwner, _amount);
    }

    /// @dev Stakes amount of THENODE tokens on behalf of the specified stake owner.
    /// @param _stakeOwner address The specified stake owner.
    /// @param _amount uint256 The amount of tokens to stake.
    /// @return totalStakedAmount uint256 The total stake of the stake owner.
    function stake(address _stakeOwner, uint256 _amount) private returns (uint256 totalStakedAmount) {
        require(_stakeOwner != address(0), "stake owner can't be 0");
        require(_amount > 0, "amount must be greater than 0");
        require(token.burn(_amount / 100), "couldn't burn token");

        Stake storage stakeData = stakes[_stakeOwner];
        stakeData.amount = stakeData.amount.add(_amount);

        totalStakedTokens = totalStakedTokens.add(_amount);
        totalStakedAmount = stakeData.amount;

        require(token.transferFrom(msg.sender, address(this), _amount.sub(_amount / 100)), "insufficient allowance");
    }

    /// @dev Requests to withdraw all of staked THENODE tokens back to the specified stake owner. Stake owners can withdraw
    /// their THENODE tokens only after previously unstaking them and after the cooldown period has passed (unless the
    /// contract was requested to release all stakes).
    /// @return res WithdrawResult The result of the withdraw operation.
    function withdraw(address _stakeOwner) private returns (WithdrawResult memory res) {
        require(_stakeOwner != address(0), "stake owner can't be 0");

        Stake storage stakeData = stakes[_stakeOwner];
        res.stakedAmount = stakeData.amount;
        res.withdrawnAmount = stakeData.cooldownAmount;
        res.stakedAmountDiff = 0;

        if (!releasingAllStakes) {
            require(res.withdrawnAmount > 0, "no unstaked tokens");
            require(stakeData.cooldownEndTime <= now, "tokens are still in cooldown");
        } else {
            res.withdrawnAmount = res.withdrawnAmount.add(res.stakedAmount);
            res.stakedAmountDiff = res.stakedAmount;

            require(res.withdrawnAmount > 0, "no staked or unstaked tokens");

            stakeData.amount = 0;
            totalStakedTokens = totalStakedTokens.sub(res.stakedAmount);
            res.stakedAmount = 0;
        }

        stakeData.cooldownAmount = 0;
        stakeData.cooldownEndTime = 0;

        require(token.burn(res.withdrawnAmount / 100), "couldn't burn token");
        require(token.mint(_stakeOwner, res.withdrawnAmount.sub(res.withdrawnAmount / 100)), "couldn't transfer stake");
    }

    /// @dev Returns an index of an existing approved staking contract.
    /// @param _stakingContract IMigratableStakingContract The staking contract to look for.
    /// @return index uint The index of the located staking contract (in the case that it was found).
    /// @return exists bool The search result.
    function findApprovedStakingContractIndex(IMigratableStakingContract _stakingContract) private view returns
        (uint index, bool exists) {
        uint length = approvedStakingContracts.length;
        for (index = 0; index < length; ++index) {
            if (approvedStakingContracts[index] == _stakingContract) {
                exists = true;
                return (index, exists);
            }
        }

        exists = false;
    }
}