//SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SHO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint32 constant HUNDRED_PERCENT = 1e6;

    struct User1 {
        uint16 claimedUnlocksCount;
        uint16 eliminatedAfterUnlock;
        uint120 allocation;
    }

    struct User2 {
        uint120 allocation;
        uint120 debt;

        uint16 claimedUnlocksCount;
        uint120 currentUnlocked;
        uint120 currentClaimed;

        uint120 totalUnlocked;
        uint120 totalClaimed;
    }

    mapping(address => User1) public users1;
    mapping(address => User2) public users2;

    IERC20 public immutable shoToken;
    uint64 public immutable startTime;
    address public immutable feeCollector;
    uint32 public immutable baseFeePercentage1;
    uint32 public immutable baseFeePercentage2;
    uint32 public immutable freeClaimablePercentage;
    address public immutable burnValley;
    uint32 public immutable burnPercentage;

    uint32[] public unlockPercentages;
    uint32[] public unlockPeriods;
    uint120[] public extraFees2;
    bool public whitelistingAllowed = true;

    uint16 passedUnlocksCount;
    uint120 public globalTotalAllocation1;
    uint120 public globalTotalAllocation2;

    uint16 public collectedFeesUnlocksCount;
    uint120 public extraFees1Allocation;
    uint120 public extraFees1AllocationUncollectable;

    event Whitelist (
        address user,
        uint120 allocation,
        uint8 option
    );

    event Claim1 (
        address indexed user,
        uint16 currentUnlock,
        uint120 claimedTokens
    );

    event Claim2 (
        address indexed user,
        uint16 currentUnlock,
        uint120 claimedTokens,
        uint120 baseClaimed,
        uint120 chargedfee
    );

    event FeeCollection (
        uint16 currentUnlock,
        uint120 totalFee,
        uint120 extraFee,
        uint120 burned
    );

    event UserElimination (
        address user,
        uint16 currentUnlock
    );

    event Update (
        uint16 passedUnlocksCount
    );

    modifier onlyWhitelistedUser1() {
        require(users1[msg.sender].allocation > 0, "SHO: caller is not whitelisted or does not have the correct option");
        _;
    }

    modifier onlyWhitelistedUser2() {
        require(users2[msg.sender].allocation > 0, "SHO: caller is not whitelisted or does not have the correct option");
        _;
    }

    /**
        @param _shoToken token that whitelisted users claim
        @param _unlockPercentagesDiff array of unlock percentages as differentials
            (how much of total user's whitelisted allocation can a user claim per unlock) 
        @param _unlockPeriodsDiff array of unlock periods as differentials
            (when unlocks happen from startTime)
        @param _baseFeePercentage1 base fee in percentage for option 1 users
        @param _baseFeePercentage2 base fee in percentage for option 2 users
        @param _feeCollector EOA that receives fees
        @param _startTime when users can start claiming
        @param _burnValley burned tokens are sent to this address if the SHO token is not burnable
        @param _burnPercentage burn percentage of extra fees
        @param _freeClaimablePercentage how much can users of type 2 claim in the current unlock without a fee
     */
    constructor(
        IERC20 _shoToken,
        uint32[] memory _unlockPercentagesDiff,
        uint32[] memory _unlockPeriodsDiff,
        uint32 _baseFeePercentage1,
        uint32 _baseFeePercentage2,
        address _feeCollector,
        uint64 _startTime,
        address _burnValley,
        uint32 _burnPercentage,
        uint32 _freeClaimablePercentage
    ) {
        require(address(_shoToken) != address(0), "SHO: sho token zero address");
        require(_unlockPercentagesDiff.length > 0, "SHO: 0 unlock percentages");
        require(_unlockPercentagesDiff.length <= 800, "SHO: too many unlock percentages");
        require(_unlockPeriodsDiff.length == _unlockPercentagesDiff.length, "SHO: different array lengths");
        require(_baseFeePercentage1 <= HUNDRED_PERCENT, "SHO: base fee percentage 1 higher than 100%");
        require(_baseFeePercentage2 <= HUNDRED_PERCENT, "SHO: base fee percentage 2 higher than 100%");
        require(_feeCollector != address(0), "SHO: fee collector zero address");
        require(_startTime > block.timestamp, "SHO: start time must be in future");
        require(_burnValley != address(0), "SHO: burn valley zero address");
        require(_burnPercentage <= HUNDRED_PERCENT, "SHO: burn percentage higher than 100%");
        require(_freeClaimablePercentage <= HUNDRED_PERCENT, "SHO: free claimable percentage higher than 100%");

        // build arrays of sums for easier calculations
        uint32[] memory _unlockPercentages = _buildArraySum(_unlockPercentagesDiff);
        uint32[] memory _unlockPeriods = _buildArraySum(_unlockPeriodsDiff);
        require(_unlockPercentages[_unlockPercentages.length - 1] == HUNDRED_PERCENT, "SHO: invalid unlock percentages");

        shoToken = _shoToken;
        unlockPercentages = _unlockPercentages;
        unlockPeriods = _unlockPeriods;
        baseFeePercentage1 = _baseFeePercentage1;
        baseFeePercentage2 = _baseFeePercentage2;
        feeCollector = _feeCollector;
        startTime = _startTime;
        burnValley = _burnValley;
        burnPercentage = _burnPercentage;
        freeClaimablePercentage = _freeClaimablePercentage;
        extraFees2 = new uint120[](_unlockPercentagesDiff.length);
    }

    /** 
        @param userAddresses addresses to whitelist
        @param allocations users total allocation
        @param options user types
    */
    function whitelistUsers(
        address[] calldata userAddresses,
        uint120[] calldata allocations,
        uint8[] calldata options,
        bool last
    ) external onlyOwner {
        require(whitelistingAllowed, "SHO: whitelisting not allowed anymore");
        require(userAddresses.length != 0, "SHO: zero length array");
        require(userAddresses.length == allocations.length, "SHO: different array lengths");
        require(userAddresses.length == options.length, "SHO: different array lengths");

        uint120 _globalTotalAllocation1;
        uint120 _globalTotalAllocation2;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            if (userAddress == feeCollector) {
                require(burnPercentage == 0);
                globalTotalAllocation1 += allocations[i];
                extraFees1Allocation += _applyBaseFee(allocations[i], 1);
                continue;
            }

            require(options[i] == 1 || options[i] == 2, "SHO: invalid user option");
            require(users1[userAddress].allocation == 0, "SHO: some users are already whitelisted");
            require(users2[userAddress].allocation == 0, "SHO: some users are already whitelisted");

            if (options[i] == 1) {
                users1[userAddress].allocation = allocations[i];
                _globalTotalAllocation1 += allocations[i];
            } else if (options[i] == 2) {
                users2[userAddress].allocation = allocations[i];
                _globalTotalAllocation2 += allocations[i];
            }

            emit Whitelist(
                userAddresses[i],
                allocations[i],
                options[i]
            );
        }
            
        globalTotalAllocation1 += _globalTotalAllocation1;
        globalTotalAllocation2 += _globalTotalAllocation2;
        
        if (last) {
            whitelistingAllowed = false;
        }
    }

    /**
        Users type 1 claims all the available amount without increasing the fee.
        (there's still the baseFee deducted from their allocation).
    */
    function claimUser1() onlyWhitelistedUser1 external nonReentrant returns (uint120 amountToClaim) {
        update();
        User1 memory user = users1[msg.sender];
        require(passedUnlocksCount > 0, "SHO: no unlocks passed");
        require(user.claimedUnlocksCount < passedUnlocksCount, "SHO: nothing to claim");

        uint16 currentUnlock = passedUnlocksCount - 1;
        if (user.eliminatedAfterUnlock > 0) {
            require(user.claimedUnlocksCount < user.eliminatedAfterUnlock, "SHO: nothing to claim");
            currentUnlock = user.eliminatedAfterUnlock - 1;
        }

        uint32 lastUnlockPercentage = user.claimedUnlocksCount > 0 ? unlockPercentages[user.claimedUnlocksCount - 1] : 0;
        amountToClaim = _applyPercentage(user.allocation, unlockPercentages[currentUnlock] - lastUnlockPercentage);
        amountToClaim = _applyBaseFee(amountToClaim, 1);

        user.claimedUnlocksCount = currentUnlock + 1;
        users1[msg.sender] = user;
        shoToken.safeTransfer(msg.sender, amountToClaim);
        emit Claim1(
            msg.sender, 
            currentUnlock,
            amountToClaim
        );
    }

    /**
        Removes all the future allocation of passed user type 1 addresses.
        They can still claim the unlock they were eliminated in.
        @param userAddresses whitelisted user addresses to eliminate
     */
    function eliminateUsers1(address[] calldata userAddresses) external onlyOwner {
        update();
        require(passedUnlocksCount > 0, "SHO: no unlocks passed");
        uint16 currentUnlock = passedUnlocksCount - 1;
        require(currentUnlock < unlockPeriods.length - 1, "SHO: eliminating in the last unlock");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address userAddress = userAddresses[i];
            User1 memory user = users1[userAddress];
            require(user.allocation > 0, "SHO: some user not option 1");
            require(user.eliminatedAfterUnlock == 0, "SHO: some user already eliminated");

            uint120 userAllocation = _applyBaseFee(user.allocation, 1);
            uint120 uncollectable = _applyPercentage(userAllocation, unlockPercentages[currentUnlock]);

            extraFees1Allocation += userAllocation;
            extraFees1AllocationUncollectable += uncollectable;

            users1[userAddress].eliminatedAfterUnlock = currentUnlock + 1;
            emit UserElimination(
                userAddress,
                currentUnlock
            );
        }
    }
    
    /**
        User type 2 claims all the remaining amount of previous unlocks and can claim up to baseFeePercentage of the current unlock tokens without causing a fee.
        @param extraAmountToClaim the extra amount is also equal to the charged fee (user claims 100 more the first unlock, can claim 200 less the second unlock)
    */
    function claimUser2(
        uint120 extraAmountToClaim
    ) external nonReentrant onlyWhitelistedUser2 returns (
        uint120 amountToClaim, 
        uint120 baseClaimAmount, 
        uint120 currentUnlocked
    ) {
        update();
        User2 memory user = users2[msg.sender];
        require(passedUnlocksCount > 0, "SHO: no unlocks passed");
        uint16 currentUnlock = passedUnlocksCount - 1;

        if (user.claimedUnlocksCount < passedUnlocksCount) {
            amountToClaim = _updateUserCurrent(user, currentUnlock);
            baseClaimAmount = _getCurrentBaseClaimAmount(user, currentUnlock);
            amountToClaim += baseClaimAmount;
            user.currentClaimed += baseClaimAmount;
        } else {
            require(extraAmountToClaim > 0, "SHO: nothing to claim");
        }

        currentUnlocked = user.currentUnlocked;

        if (extraAmountToClaim > 0) {
            require(extraAmountToClaim <= user.currentUnlocked - user.currentClaimed, "SHO: passed extra amount too high");
            amountToClaim += extraAmountToClaim;
            user.currentClaimed += extraAmountToClaim;
            _chargeFee(user, extraAmountToClaim, currentUnlock);
        }

        require(amountToClaim > 0, "SHO: nothing to claim");

        user.totalClaimed += amountToClaim;
        users2[msg.sender] = user;
        shoToken.safeTransfer(msg.sender, amountToClaim);
        emit Claim2(
            msg.sender, 
            currentUnlock,
            amountToClaim,
            baseClaimAmount,
            extraAmountToClaim
        );
    }

    /**
        It's important that the fees are collectable not depedning on if users are claiming.
        Anybody can call this but the fees go to the fee collector.
     */ 
    function collectFees() external nonReentrant returns (uint120 baseFee, uint120 extraFee, uint120 burned) {
        update();
        require(collectedFeesUnlocksCount < passedUnlocksCount, "SHO: no fees to collect");
        uint16 currentUnlock = passedUnlocksCount - 1;

        // base fee from users type 1 and 2
        uint32 lastUnlockPercentage = collectedFeesUnlocksCount > 0 ? unlockPercentages[collectedFeesUnlocksCount - 1] : 0;
        uint120 globalAllocation1 = _applyPercentage(globalTotalAllocation1, unlockPercentages[currentUnlock] - lastUnlockPercentage);
        uint120 globalAllocation2 = _applyPercentage(globalTotalAllocation2, unlockPercentages[currentUnlock] - lastUnlockPercentage);
        baseFee = _applyPercentage(globalAllocation1, baseFeePercentage1);
        baseFee += _applyPercentage(globalAllocation2, baseFeePercentage2);

        // extra fees from users type 2
        uint120 extraFee2;
        for (uint16 i = collectedFeesUnlocksCount; i <= currentUnlock; i++) {
            extraFee2 += extraFees2[i];
        }

        // extra fees from users type 1
        uint120 extraFees1AllocationTillNow = _applyPercentage(extraFees1Allocation, unlockPercentages[currentUnlock]);
        uint120 extraFee1 = extraFees1AllocationTillNow - extraFees1AllocationUncollectable;
        extraFees1AllocationUncollectable = extraFees1AllocationTillNow;

        extraFee = extraFee1 + extraFee2;
        uint120 totalFee = baseFee + extraFee;
        burned = _burn(extraFee);
        collectedFeesUnlocksCount = currentUnlock + 1;
        shoToken.safeTransfer(feeCollector, totalFee - burned);
        emit FeeCollection(
            currentUnlock,
            totalFee,
            extraFee,
            burned
        );
    }

    /**  
        Updates passedUnlocksCount.
    */
    function update() public {
        uint16 _passedUnlocksCount = getPassedUnlocksCount();
        if (_passedUnlocksCount > passedUnlocksCount) {
            passedUnlocksCount = _passedUnlocksCount;
            emit Update(_passedUnlocksCount);
        }
    }

    // PUBLIC VIEW FUNCTIONS

    function getPassedUnlocksCount() public view returns (uint16 _passedUnlocksCount) {
        require(block.timestamp >= startTime, "SHO: before startTime");
        uint256 timeSinceStart = block.timestamp - startTime;
        uint256 maxReleases = unlockPeriods.length;
        _passedUnlocksCount = passedUnlocksCount;

        while (_passedUnlocksCount < maxReleases && timeSinceStart >= unlockPeriods[_passedUnlocksCount]) {
            _passedUnlocksCount++;
        }
    }

    function getTotalUnlocksCount() public view returns (uint16 totalUnlocksCount) {
        return uint16(unlockPercentages.length);
    }

    // PRIVATE FUNCTIONS

    function _burn(uint120 amount) private returns (uint120 burned) {
        burned = _applyPercentage(amount, burnPercentage);
        if (burned == 0) return 0;

        uint256 balanceBefore = shoToken.balanceOf(address(this));
        address(shoToken).call(abi.encodeWithSignature("burn(uint256)", burned));
        uint256 balanceAfter = shoToken.balanceOf(address(this));

        if (balanceBefore == balanceAfter) {
            shoToken.safeTransfer(burnValley, burned);
        }
    }

    function _updateUserCurrent(User2 memory user, uint16 currentUnlock) private view returns (uint120 claimableFromPreviousUnlocks) {
        claimableFromPreviousUnlocks = _getClaimableFromPreviousUnlocks(user, currentUnlock);

        uint120 newUnlocked = claimableFromPreviousUnlocks - (user.currentUnlocked - user.currentClaimed);

        uint32 unlockPercentageDiffCurrent = currentUnlock > 0 ?
            unlockPercentages[currentUnlock] - unlockPercentages[currentUnlock - 1] : unlockPercentages[currentUnlock];

        uint120 currentUnlocked = _applyPercentage(user.allocation, unlockPercentageDiffCurrent);
        currentUnlocked = _applyBaseFee(currentUnlocked, 2);

        newUnlocked += currentUnlocked;
        if (newUnlocked >= user.debt) {
            newUnlocked -= user.debt;
        } else {
            newUnlocked = 0;
        }

        if (claimableFromPreviousUnlocks >= user.debt) {
            claimableFromPreviousUnlocks -= user.debt;
            user.debt = 0;
        } else {
            user.debt -= claimableFromPreviousUnlocks;
            claimableFromPreviousUnlocks = 0;
        }

        if (currentUnlocked >= user.debt) {
            currentUnlocked -= user.debt;
            user.debt = 0;
        } else {
            user.debt -= currentUnlocked;
            currentUnlocked = 0;
        }
        
        user.totalUnlocked += newUnlocked;
        user.currentUnlocked = currentUnlocked;
        user.currentClaimed = 0;
        user.claimedUnlocksCount = passedUnlocksCount;
    }

    function _getClaimableFromPreviousUnlocks(User2 memory user, uint16 currentUnlock) private view returns (uint120 claimableFromPreviousUnlocks) {
        uint32 lastUnlockPercentage = user.claimedUnlocksCount > 0 ? unlockPercentages[user.claimedUnlocksCount - 1] : 0;
        uint32 previousUnlockPercentage = currentUnlock > 0 ? unlockPercentages[currentUnlock - 1] : 0;
        uint120 claimableFromMissedUnlocks = _applyPercentage(user.allocation, previousUnlockPercentage - lastUnlockPercentage);
        claimableFromMissedUnlocks = _applyBaseFee(claimableFromMissedUnlocks, 2);
        
        claimableFromPreviousUnlocks = user.currentUnlocked - user.currentClaimed;
        claimableFromPreviousUnlocks += claimableFromMissedUnlocks;
    }

    function _getCurrentBaseClaimAmount(User2 memory user, uint16 currentUnlock) private view returns (uint120 baseClaimAmount) {
        if (currentUnlock < unlockPeriods.length - 1) {
            baseClaimAmount =_applyPercentage(user.currentUnlocked, freeClaimablePercentage);
        } else {
            baseClaimAmount = user.currentUnlocked;
        }
    }

    function _chargeFee(User2 memory user, uint120 fee, uint16 currentUnlock) private {
        user.debt += fee;

        while (fee > 0 && currentUnlock < unlockPeriods.length - 1) {
            uint16 nextUnlock = currentUnlock + 1;
            uint120 nextUserAvailable = _applyPercentage(user.allocation, unlockPercentages[nextUnlock] - unlockPercentages[currentUnlock]);
            nextUserAvailable = _applyBaseFee(nextUserAvailable, 2);

            uint120 currentUnlockFee = fee <= nextUserAvailable ? fee : nextUserAvailable;
            extraFees2[nextUnlock] += currentUnlockFee;
            fee -= currentUnlockFee;
            currentUnlock++;
        }
    }

    function _applyPercentage(uint120 value, uint32 percentage) private pure returns (uint120) {
        return uint120(uint256(value) * percentage / HUNDRED_PERCENT);
    }

    function _applyBaseFee(uint120 value, uint8 option) private view returns (uint120) {
        return value - _applyPercentage(value, option == 1 ? baseFeePercentage1 : baseFeePercentage2);
    }

    function _buildArraySum(uint32[] memory diffArray) internal pure returns (uint32[] memory) {
        uint256 len = diffArray.length;
        uint32[] memory sumArray = new uint32[](len);
        uint32 lastSum = 0;
        for (uint256 i = 0; i < len; i++) {
            if (i > 0) {
                lastSum = sumArray[i - 1];
            }
            sumArray[i] = lastSum + diffArray[i];
        }
        return sumArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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