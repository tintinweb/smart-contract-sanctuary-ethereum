// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Vesting AVRK Smart Contract
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VestingAVRK is Ownable, ReentrancyGuard, Pausable {
    enum VestingType {
        PUBLIC_SALE,
        STRATEGIC,
        SEED,
        PRIVATE_SALE,
        STAKING_REWARD,
        PLAY_TO_EARN,
        CORE_TEAM,
        ECOSYSTEM_FUND
    }

    /**
     * Category 0 - Public Sale
     * Category 1 - Strategic
     * Category 2 - Seed
     * Category 3 - Private Sale
     * Category 4 - Staking Reward
     * Category 5 - Play to Earn
     * Category 6 - Core Team
     * Category 7 - Ecosystem Fund
     */
    struct VestingSchedule {
        VestingType indexId;
        string name;
        uint8 monthlyStartReward;
        uint256 lockPeriod;
        uint256 vestingEnd;
        uint256 monthlyTokens;
        uint256 totalTokenAllocation;
    }

    struct RecipientImport {
        address account;
        uint256 percentage;
    }

    struct RecipientDetail {
        VestingType vestIndexID;
        uint256 percentage;
        uint256 vestingEnd;
        uint256 totalTokenAllocated;
        uint256 totalVestTokensClaimed;
        bool isVesting;
    }

    /**
     * @notice detail: information about vest allocation.
     * @notice vestIndexID: Index of vesting.
     * @notice isVesting: for checking user registered or not.
     */
    struct RecipientInformation {
        mapping(VestingType => RecipientDetail) detail;
        VestingType[] vestIndexIds;
        bool isVesting;
    }

    /**
     * @notice AVRK Token have 18 of decimal
     */
    uint256 private constant DECIMALS_MUL = 10**18;

    /**
     * @notice vesting start time
     */
    uint256 public vestStartTime;

    /**
     * @notice track type of investor
     */
    mapping(VestingType => VestingSchedule) public vestTypes;

    /**
     * @notice keep track user info
     */
    mapping(address => RecipientInformation) public recipientInformation;

    /**
     * @dev Emitted when a new recipient added to vesting
     * @param vestingIndex Index of Vesting type.
     * @param recipient Address of recipient.
     * @param percentage Percentage of rewards that users get.
     */
    event RecipientAdded(
        VestingType indexed vestingIndex,
        address recipient,
        uint256 percentage
    );

    /**
     * @dev Emitted when claim reward vesting.
     * @param recipient Address of user for which withdraw tokens.
     * @param amount The amount of tokens which was withdrawn.
     */
    event ClaimFromVesting(address indexed recipient, uint256 amount);

    /**
     * @notice address contract AVRK Token
     */
    IERC20 public AVRK;

    /**
     * @dev modifier for checking user registered
     * @param _user Address of user.
     */
    modifier checkUserStatus(address _user) {
        require(
            recipientInformation[_user].isVesting,
            "checkUserStatus: Address not registered"
        );
        _;
    }

    /**
     * @dev Constructor of the contract Vesting.
     * @notice Initialize all vesting schedules.
     * @param _avrk Address of token.
     * @param _vestStartTime Vesting Start time event unix timestamp.
     */
    constructor(IERC20 _avrk, uint256 _vestStartTime) {
        AVRK = _avrk;
        vestStartTime = _vestStartTime;

        _pause();
        _initializeVestingSchedules();
    }

    /// -----------------------------------------------------------------------
    /// External and Public Functions
    /// -----------------------------------------------------------------------

    /**
     *   @notice get time elapsed by Unix Timestamp
     */
    function getTimeElapsed() public view returns (uint256) {
        return block.timestamp - vestStartTime;
    }

    /**
     *   @notice get Month elapsed by total month
     */
    function getMonthElapsed() public view returns (uint256) {
        return getTimeElapsed() / (_monthInSeconds());
    }

    /**
     *   @notice get days elapsed by total days
     */
    function getDaysElapsed() public view returns (uint256) {
        return getTimeElapsed() / (_daysInSeconds());
    }

    /**
     * @dev To claim reward vesting.
     * @notice external function for user claim reward vesting.
     * @notice use Modifier checkUserStatus for validate user.
     * @notice use nonReentrant for prevent Re entrancy attack.
     */
    function claimVesting()
        external
        whenNotPaused
        checkUserStatus(_msgSender())
        nonReentrant
    {
        require(
            block.timestamp >= vestStartTime,
            "claimVesting: Vesting Time didn't start yet"
        );

        RecipientInformation storage user = recipientInformation[_msgSender()];
        uint256 totalToPay;

        for (uint256 i = 0; i < user.vestIndexIds.length; i++) {
            uint256 amountToPay = _calculateClaimableTokens(
                user.detail[user.vestIndexIds[i]]
            );
            totalToPay += amountToPay;
            user
                .detail[user.vestIndexIds[i]]
                .totalVestTokensClaimed += amountToPay;
        }
        require(totalToPay > 0, "claimVesting: Nothing to withdraw");

        require(
            AVRK.transfer(_msgSender(), totalToPay),
            "claimVesting: Failed transfer token"
        );
        emit ClaimFromVesting(_msgSender(), totalToPay);
    }

    /// -----------------------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------------------

    /**
     * @notice pause function pause contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice pause function unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Adds recipients for vesting.
     * @notice external function for add recipients.
     * @param _userImport Addresses and percentage of recipients.
     * @param _vestingType index of vesting type.
     */
    function addRecipients(
        RecipientImport[] calldata _userImport,
        VestingType _vestingType
    ) external onlyOwner {
        for (uint256 i = 0; i < _userImport.length; i++) {
            _addRecipient(
                _vestingType,
                _userImport[i].account,
                _userImport[i].percentage
            );
        }
    }

    /**
     * @notice external function for update percentage vesting user.
     * @param _vestingIndex Index of vesting type.
     * @param _user Addresses of user.
     * @param _percentageRate Percentage rate of user.
     */
    function updatePercentageRecipient(
        VestingType _vestingIndex,
        address _user,
        uint256 _percentageRate
    ) external onlyOwner checkUserStatus(_user) {
        RecipientInformation storage user = recipientInformation[_user];

        require(
            user.detail[_vestingIndex].totalVestTokensClaimed <= 0,
            "updatePercentageUser: total user claims is greater than 0"
        );

        user.detail[_vestingIndex].percentage = _percentageRate;
    }

    /**
     * @notice withdraw token from contract
     */
    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = AVRK.balanceOf(address(this));

        require(
            AVRK.transfer(_msgSender(), tokenSupply),
            "withdrawTokens: Failed transfer token"
        );
    }

    /// -----------------------------------------------------------------------
    /// Get functions for frontend
    /// -----------------------------------------------------------------------

    /**
     * @dev to get detail recipient information
     * @param _user Addresses of user.
     * @notice RecipientDetail[] => array of list of vesting information owned by users
     * @notice vestingStartTime => vesting start date format unix timestamp
     * @notice lockedBalance => total balance currently locked
     * @notice unlockedBalance => total balance currently unlocked that can be claimed
     * @notice totalClaimed => the amount of balance that has been claimed by the user
     */
    function getRecipientInfo(address _user)
        external
        view
        checkUserStatus(_user)
        returns (
            RecipientDetail[] memory,
            uint256 vestingStartTime,
            uint256 lockedBalance,
            uint256 unlockedBalance,
            uint256 totalClaimed
        )
    {
        RecipientInformation storage user = recipientInformation[_user];

        vestingStartTime = vestStartTime;

        RecipientDetail[] memory userDetail = new RecipientDetail[](
            user.vestIndexIds.length
        );

        for (uint256 i; i < user.vestIndexIds.length; i++) {
            userDetail[i].vestIndexID = user
                .detail[user.vestIndexIds[i]]
                .vestIndexID;
            userDetail[i].percentage = user
                .detail[user.vestIndexIds[i]]
                .percentage;
            userDetail[i].totalTokenAllocated = user
                .detail[user.vestIndexIds[i]]
                .totalTokenAllocated;
            userDetail[i].vestingEnd = user
                .detail[user.vestIndexIds[i]]
                .vestingEnd;
            userDetail[i].totalVestTokensClaimed = user
                .detail[user.vestIndexIds[i]]
                .totalVestTokensClaimed;

            unlockedBalance += _calculateClaimableTokens(
                user.detail[user.vestIndexIds[i]]
            );
            totalClaimed += user
                .detail[user.vestIndexIds[i]]
                .totalVestTokensClaimed;
            lockedBalance += (
                user.detail[user.vestIndexIds[i]].totalTokenAllocated
            );
        }

        return (
            userDetail,
            vestingStartTime,
            lockedBalance - (unlockedBalance + totalClaimed),
            unlockedBalance,
            totalClaimed
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /**
     * @dev To calculate tokens that can be claimed.
     * @param _userVestData User vesting information
     * @return actualClaimableAmount amount tokens that can be claimed.
     */
    function _calculateClaimableTokens(RecipientDetail memory _userVestData)
        internal
        view
        returns (uint256)
    {
        uint256 availableToken = _calculateAvailableTokens(_userVestData);

        uint256 actualClaimableAmount = availableToken -
            (_userVestData.totalVestTokensClaimed);

        return actualClaimableAmount;
    }

    /**
     * @dev To calculate available tokens.
     * @param _userVestData User vesting information
     * @return availableToken Total of all tokens in index vesting by user.
     */
    function _calculateAvailableTokens(RecipientDetail memory _userVestData)
        internal
        view
        returns (uint256)
    {
        if (vestStartTime > block.timestamp) {
            return 0; //return 0 if vestStartTime not start
        }

        VestingSchedule memory vestData = vestTypes[_userVestData.vestIndexID];

        uint256 availableToken;
        uint256 vestingDaysTotal = vestData.vestingEnd / (_daysInSeconds());
        uint256 totalDaysElapsed = getDaysElapsed();
        uint256 totalMonthsElapsed = getMonthElapsed();
        uint256 partialDaysElapsed = totalDaysElapsed % 30;

        if (partialDaysElapsed > 0 && totalMonthsElapsed > 0) {
            totalMonthsElapsed += 1;
        }

        /**
         * if the vesting period is over
         */
        if (totalDaysElapsed > vestingDaysTotal) {
            availableToken = _percentage(
                vestData.totalTokenAllocation,
                _userVestData.percentage
            );
        }
        /**
         * if the vesting period is still running
         */
        else {
            if (totalMonthsElapsed < 1) {
                return 0; //return if totalMonthsElapsed 0
            }

            uint256 actualTotalMonthElapsed;

            /**
             * if there is an interval period
             * divide by interval period(lock period) to get actual month
             */
            if (vestData.lockPeriod > 0) {
                actualTotalMonthElapsed =
                    (totalMonthsElapsed - 1) /
                    (vestData.lockPeriod / _monthInSeconds());
            } else {
                /**
                 * if the type of vesting is strategic, it has a special calculation
                 * after 21 months. then next has 3 month a period interval
                 */
                if (
                    _userVestData.vestIndexID == VestingType.STRATEGIC &&
                    (totalMonthsElapsed > 21)
                ) {
                    /**
                     * 21 subtract monthly start reward to calculate the number of months before month 21
                     * after that the number of months is subtracted by 21
                     * and divided by 3 to get the number of months after the time interval
                     * substract with 22 because montly start reward begin with + 1
                     * if monthly start reward at 6th months so subtract with 7
                     * because after 7 months pass, then we can get the prize
                     */
                    actualTotalMonthElapsed = 22 - vestData.monthlyStartReward;
                    actualTotalMonthElapsed += (totalMonthsElapsed - 22) / (3);
                } else if (totalMonthsElapsed > vestData.monthlyStartReward) {
                    actualTotalMonthElapsed =
                        totalMonthsElapsed -
                        vestData.monthlyStartReward;
                } else {
                    return 0; //return if totalMonthsElapsed 0
                }
            }

            availableToken = _percentage(
                vestData.monthlyTokens * (actualTotalMonthElapsed),
                _userVestData.percentage
            );
        }

        return availableToken;
    }

    /**
     * @dev calculate the percentage value.
     * @param _totalAmount Total Amoun to be calculated.
     * @param _rate Percentage rate.
     */
    function _percentage(uint256 _totalAmount, uint256 _rate)
        internal
        pure
        returns (uint256)
    {
        return (_totalAmount * (_rate)) / (1000);
    }

    function _daysInSeconds() internal pure returns (uint256) {
        return 86400;
    }

    function _monthInSeconds() internal pure returns (uint256) {
        return 2592000;
    }

    /**
     * @dev Add recipients for vesting.
     * @notice internal function for add recipients.
     * @param _vestingIndex Index of vesting.
     * @param _user Addresses of user.
     * @param _percentageRate Percentage rate of user.
     */
    function _addRecipient(
        VestingType _vestingIndex,
        address _user,
        uint256 _percentageRate
    ) internal {
        RecipientInformation storage user = recipientInformation[_user];

        if (user.detail[_vestingIndex].isVesting) {
            return;
        }

        VestingSchedule memory vestData = vestTypes[_vestingIndex];

        uint256 totalTokenAllocated = _percentage(
            vestData.totalTokenAllocation,
            _percentageRate
        );

        RecipientDetail memory userVestingData = RecipientDetail({
            vestIndexID: _vestingIndex,
            percentage: _percentageRate,
            vestingEnd: vestData.vestingEnd,
            totalTokenAllocated: totalTokenAllocated,
            totalVestTokensClaimed: 0,
            isVesting: true
        });

        user.detail[_vestingIndex] = userVestingData;
        user.vestIndexIds.push(_vestingIndex);
        user.isVesting = true;

        emit RecipientAdded(_vestingIndex, _user, _percentageRate);
    }

    /**
     *   @dev Internal function initialize all vesting types with their schedule
     */
    function _initializeVestingSchedules() internal {
        _addVestingSchedule(
            VestingType.PUBLIC_SALE,
            VestingSchedule({
                indexId: VestingType.PUBLIC_SALE,
                name: "PUBLIC_SALE",
                lockPeriod: 0,
                monthlyStartReward: 0, // in the first day
                vestingEnd: 0, // 1 days
                monthlyTokens: 12_500_000 * DECIMALS_MUL,
                totalTokenAllocation: 12_500_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.STRATEGIC,
            VestingSchedule({
                indexId: VestingType.STRATEGIC,
                name: "STRATEGIC",
                lockPeriod: 0,
                monthlyStartReward: 7, //in the month 7
                vestingEnd: 86400 * 990, // 33 months
                monthlyTokens: 650_000 * DECIMALS_MUL,
                totalTokenAllocation: 12_500_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.SEED,
            VestingSchedule({
                indexId: VestingType.SEED,
                name: "SEED",
                lockPeriod: 0,
                vestingEnd: 86400 * 540, // 18 months
                monthlyStartReward: 7, //in the month 7
                monthlyTokens: 2_000_000 * DECIMALS_MUL,
                totalTokenAllocation: 25_000_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.PRIVATE_SALE,
            VestingSchedule({
                indexId: VestingType.PRIVATE_SALE,
                name: "PRIVATE_SALE",
                lockPeriod: 0,
                vestingEnd: 86400 * 540, // 18 months
                monthlyStartReward: 7, //in the month 7
                monthlyTokens: 2_000_000 * DECIMALS_MUL,
                totalTokenAllocation: 25_000_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.STAKING_REWARD,
            VestingSchedule({
                indexId: VestingType.STAKING_REWARD,
                name: "STAKING_REWARD",
                lockPeriod: 86400 * 90, // 3 months,
                monthlyStartReward: 0, //in the first month
                vestingEnd: 86400 * 1800, // 60 months
                monthlyTokens: 6_250_000 * DECIMALS_MUL,
                totalTokenAllocation: 125_000_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.PLAY_TO_EARN,
            VestingSchedule({
                indexId: VestingType.PLAY_TO_EARN,
                name: "PLAY_TO_EARN",
                lockPeriod: 86400 * 90, // 3 months,
                monthlyStartReward: 0, //in the first month
                vestingEnd: 86400 * 1800, // 60 months
                monthlyTokens: 7_500_000 * DECIMALS_MUL,
                totalTokenAllocation: 150_000_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.CORE_TEAM,
            VestingSchedule({
                indexId: VestingType.CORE_TEAM,
                name: "CORE_TEAM",
                lockPeriod: 86400 * 90, // 3 months,
                monthlyStartReward: 0, //in the first month
                vestingEnd: 86400 * 1800, // 60 months
                monthlyTokens: 5_000_000 * DECIMALS_MUL,
                totalTokenAllocation: 100_000_000 * DECIMALS_MUL
            })
        );

        _addVestingSchedule(
            VestingType.ECOSYSTEM_FUND,
            VestingSchedule({
                indexId: VestingType.ECOSYSTEM_FUND,
                name: "ECOSYSTEM_FUND",
                lockPeriod: 86400 * 90, // 3 months,
                monthlyStartReward: 0, //in the first month
                vestingEnd: 86400 * 1800, // 60 months
                monthlyTokens: 2_500_000 * DECIMALS_MUL,
                totalTokenAllocation: 50_000_000 * DECIMALS_MUL
            })
        );
    }

    /**
     * @dev Internal function adds vesting schedules for vesting type
     */
    function _addVestingSchedule(
        VestingType _type,
        VestingSchedule memory _schedule
    ) internal {
        vestTypes[_type] = _schedule;
    }

    function addMonths() external onlyOwner {
        vestStartTime = vestStartTime - _monthInSeconds();
    }

    function setMonths(uint256 _month) external onlyOwner {
        vestStartTime = vestStartTime - (_month * _monthInSeconds());
    }

    function resetMonths() external onlyOwner {
        vestStartTime = block.timestamp;
    }

    function subMonths() external onlyOwner {
        vestStartTime = vestStartTime + _monthInSeconds();
    }

    function resetUser(address _user) external onlyOwner {
        RecipientInformation storage user = recipientInformation[_user];

        for (uint256 i; i < user.vestIndexIds.length; i++) {
            delete user.detail[user.vestIndexIds[i]];
        }

        delete recipientInformation[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}