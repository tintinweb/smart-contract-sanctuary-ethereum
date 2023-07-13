/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: UPDATED PBMC/staking.sol


pragma solidity ^0.8.20;




interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address recipient, uint256 amount) external returns (bool);
}

contract StakingContract is Ownable, ReentrancyGuard, Pausable {
    uint256 public maxAmount = 100000 * 10**18;
    uint256 public minAmount = 100 * 10**18;
    uint256 public totalReward;
    IERC20 public token;
    uint256 public totalStakers;
    uint256 public totalStakeAmount;

    struct User {
        address stakeHolder;
        uint256 amount;
        uint256 reward;
        uint256 id;
        uint256 interestRate;
        uint256 startTime;
        uint256 duration;
        bool active;
    }

    struct UserInfo {
        User[] usersDetails;
    }

    struct Stakeholder {
        // contain all the plans according to the timeperiod of a user
        User[] userThreeMonthPlans;
        User[] userSixMonthPlans;
        User[] userOneYearPlans;
    }
    //events
    event staked(address indexed stakeHolder, uint256 amount, uint256 duration);

    event unstaked(
        address indexed stakeHolder,
        uint256 amount,
        uint256 duration
    );

    UserInfo private userInfos;
    Stakeholder[] stakeholders; //first element of this list is zero or empty to avoid confusion
    mapping(address => uint256) stakeholderToIndex;
    mapping(address => mapping(uint256 => uint256)) public userPlanToStakeCount;
    mapping(uint256 => uint256) monthToInterest;

    constructor(address _address) {
        token = IERC20(_address);
        monthToInterest[3] = 22;
        monthToInterest[6] = 45;
        monthToInterest[12] = 100;

        // push an empty struct to stakeholders array to avoid confusion  whether stakeholder does not exist or his index is zero.
        // no stakeholder will have 0 index now.
        stakeholders.push();
    }

    function stake(uint256 amount, uint256 month)
        external
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        require(amount >= minAmount, "You have to spend more");
        require(amount <= maxAmount, "You have to spend less");
        require(monthToInterest[month] != 0, "choose a valid plan");
        uint256 userLength;
        uint256 interest = monthToInterest[month];
        uint256 index = stakeholderToIndex[msg.sender];
        require(
            userPlanToStakeCount[msg.sender][month] < 5,
            "You have reached the maximum limit to stake for this plan"
        );

        if (index == 0) {
            totalStakers += 1;
            index = addStakeholder(msg.sender);
        }
        if (month == 3) {
            userLength = stakeholders[index].userThreeMonthPlans.length;
        } else if (month == 6) {
            userLength = stakeholders[index].userSixMonthPlans.length;
        } else if (month == 12) {
            userLength = stakeholders[index].userOneYearPlans.length;
        } else {
            revert("Please select a valid plan");
        }
        Stakeholder storage stakeholder = stakeholders[index];
        token.transferFrom(msg.sender, address(this), amount);
        uint256 reward = calculateReward(amount, interest, month);
        User memory newUser = User(
            msg.sender,
            amount,
            reward,
            userLength,
            interest,
            block.timestamp,
            month,
            true
        );

        if (month == 3) {
            stakeholder.userThreeMonthPlans.push(newUser);
        } else if (month == 6) {
            stakeholder.userSixMonthPlans.push(newUser);
        } else if (month == 12) {
            stakeholder.userOneYearPlans.push(newUser);
        }
        userInfos.usersDetails.push(newUser);
        totalStakeAmount += amount;
        userPlanToStakeCount[msg.sender][month] += 1;
        emit staked(msg.sender, amount, month);
        return true;
    }

    function unstake(uint256 month, uint256 id)
        external
        nonReentrant
        returns (bool)
    {
        uint256 index = stakeholderToIndex[msg.sender];
        Stakeholder storage stakeholder = stakeholders[index];
        uint256 secondInMonth = 60*60*24*30;
        User storage user;
        if (month == 3) {
            user = stakeholder.userThreeMonthPlans[id];
        } else if (month == 6) {
            user = stakeholder.userSixMonthPlans[id];
        } else if (month == 12) {
            user = stakeholder.userOneYearPlans[id];
        } else {
            revert("please enter a valid month");
        }

        uint256 endTimeStamp = (user.duration * secondInMonth) + user.startTime;
        require(block.timestamp > endTimeStamp, "plan is still active");
        require(user.active == true, "you have already unstaked");
        token.transfer(msg.sender, user.amount + user.reward);
        totalReward += user.reward;
        user.active = false;
        userPlanToStakeCount[msg.sender][month] -= 1;
        emit unstaked(msg.sender, user.amount, month);
        return true;
    }

    function calculateReward(
        uint256 amount,
        uint256 interestRate,
        uint256 month
    ) public pure returns (uint256) {
        uint256 reward = (amount * interestRate * month) / (1000 * 12);
        return reward;
    }

    function updateMinAmount(uint256 _minAmount)
        external
        onlyOwner
        returns (uint256)
    {
        minAmount = _minAmount;
        return minAmount;
    }

    function updateMaxAmount(uint256 _maxAmount)
        external
        onlyOwner
        returns (uint256)
    {
        maxAmount = _maxAmount;
        return maxAmount;
    }

    function withdraw() external onlyOwner returns (uint256) {
        uint256 contractBalance = token.balanceOf(address(this));
        require(
            contractBalance > 0,
            "Contract does not have any balance to withdraw"
        );
        token.transfer(msg.sender, contractBalance);
        return contractBalance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getUsersPlans() external view returns (Stakeholder memory) {
        return stakeholders[stakeholderToIndex[msg.sender]];
    }

    //add a new stakeholder to the stakeholders array
    function addStakeholder(address _address) internal returns (uint256) {
        stakeholders.push();
        uint256 index = stakeholders.length - 1;
        stakeholderToIndex[_address] = index;
        return index;
    }

    function getAllUsersInfo() external view returns (UserInfo memory) {
        return userInfos;
    }
}