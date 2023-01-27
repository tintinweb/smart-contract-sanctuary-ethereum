// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAccuCoin.sol";

contract Cryptopati is Ownable, Pausable {
    IAccuCoin public accuCoin; // Address of the Accu Coin
    address public platform; // Platform wallet manages certain functions
    uint256 public initialAmount = 100 ether; // Amount that can be claimed initially
    bool public isInitialClaimable = true; // Boolean indicating whether the initial claiming for tokens is open
    uint256 public replenishAmount = 10 ether; // Amount that can be claimed when replenished
    uint256 public replenishDuration = 4 hours; // Duration after which tokens will be replenished
    bool public isReplenishable = true; // Boolean indicating whether the claiming for tokens is replenishable
    uint256 private multiplierAmount; //multiplier amount of the users invested token to a question
    struct Question {
        uint256 multiplier;
        uint256 timeDuration;
        bool exist;
        bool unlocked;
    }
    struct User {
        bool unlocked;
        uint256 totalCommitAmount;
        uint256 totalAmountCollected;
    }

    mapping(string => Question) private _questions; // Question ID => Question {}
    mapping(address => User) public userInfo;
    mapping(address => mapping(string => User)) public _userToQuestionId;
    mapping(address => uint256) public userLastClaim; // Timestamp at which user claimed token last
    mapping(address => mapping(string => uint256)) public userCommitAmount; //stores the commitAmount for each question
    /* Events */
    event QuestionAdd(string questionId);
    event ClaimTokens(address indexed user, uint256 amount);
    event UnlockQuestion(
        address indexed user,
        string questionId,
        uint256 commitAmount
    );
    event WinQuestion(
        address indexed user,
        string questionId,
        uint256 rewardAmount
    );

    /* Modifiers */
    modifier onlyValid(string calldata questionId) {
        require(questionExist(questionId), "Cryptopati: invalid question");
        _;
    }

    constructor(IAccuCoin _accuCoin, address _platform) Ownable() {
        accuCoin = _accuCoin;
        platform = _platform;
    }

    /**
     * @notice This method is used pause user functionalities of the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice This method is used unpause user functionalities of the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice This method is used to address of accu coin
     * @param _accuCoin Address of accu coin
     */
    function setAccuCoin(IAccuCoin _accuCoin) external onlyOwner {
        accuCoin = _accuCoin;
    }

    /**
     * @notice This method is used to set platform wallet address
     * @param _platform Address of the platform wallet
     */
    function setPlatform(address _platform) external onlyOwner {
        platform = _platform;
    }

    /**
     * @notice This method is used to toggle initial token claim
     */
    function toggleIsInitialClaimable() external onlyOwner {
        isInitialClaimable = !isInitialClaimable;
    }

    /**
     * @notice This method is used to toggle token replenish claim
     */
    function toggleIsReplenishable() external onlyOwner {
        isReplenishable = !isReplenishable;
    }

    /**
     * @notice This method is used to set token claim settings
     * @param _initialAmount Initial amount that can be claimed by an address
     * @param _replenishAmount Amount of tokens that can be claimed when replenished
     * @param _replenishDuration Duration in which token will replenish
     */
    function configureClaim(
        uint256 _initialAmount,
        uint256 _replenishAmount,
        uint256 _replenishDuration
    ) external onlyOwner {
        initialAmount = _initialAmount;
        replenishAmount = _replenishAmount;
        replenishDuration = _replenishDuration;
    }

    /**
     * @notice This method is used to claim tokens initially or when replenished
     */
    function claimTokens()
        external
        whenNotPaused
        returns (uint256 claimAmount)
    {
        if (userLastClaim[msg.sender] != 0) {
            require(isReplenishable, "Cryptopati: token replenish is paused");
            require(
                block.timestamp - userLastClaim[msg.sender] >=
                    replenishDuration,
                "Cryptopati: wait replenish duration to claim more tokens"
            );
            claimAmount = replenishAmount;
        } else {
            require(isInitialClaimable, "Cryptopati: initial claim is paused");
            claimAmount = initialAmount;
        }
        userLastClaim[msg.sender] = block.timestamp;
        accuCoin.mint(msg.sender, claimAmount);
        emit ClaimTokens(msg.sender, claimAmount);
    }

    /**
     * @notice This method is used to check if a question exist
     * @param questionId ID of the question
     */
    function questionExist(
        string calldata questionId
    ) public view returns (bool) {
        return _questions[questionId].exist;
    }

    /**
     * @notice This method is used to get question details
     * @param questionId ID of the question
     */
    function getQuestion(
        string calldata questionId
    ) external view onlyValid(questionId) returns (Question memory) {
        return _questions[questionId];
    }

    /**
     * @notice This method is used to get question details
     * @param questionId ID of the question
     */
    function addQuestion(
        string calldata questionId,
        uint256 multiplier,
        uint256 timeDuration
    ) external onlyOwner {
        require(
            !_questions[questionId].exist,
            "Cryptopati: questionId already added"
        );

        _questions[questionId] = Question(
            multiplier,
            timeDuration,
            true,
            false
        );

        emit QuestionAdd(questionId);
    }

    /**
     * @notice This method is used to unlock the question
     * @param questionId ID of the question
     * @param commitAmount Amount user invests to unlock the question
     */
    function unlockQuestion(
        string calldata questionId,
        uint256 commitAmount
    ) external whenNotPaused onlyValid(questionId) {
        require(
            _userToQuestionId[msg.sender][questionId].unlocked == false,
            "Cryptopati: Question already unlocked"
        );

        userCommitAmount[msg.sender][questionId] += commitAmount;
        userInfo[msg.sender].totalCommitAmount += commitAmount;
        accuCoin.transferFrom(
            msg.sender,
            platform,
            userCommitAmount[msg.sender][questionId]
        );
        _userToQuestionId[msg.sender][questionId].unlocked = true;

        emit UnlockQuestion(msg.sender, questionId, commitAmount);
    }

    /**
     * @notice This method is used to transfer reward if answer is correct
     * @param questionId ID of the question
     * @param result boolean value
     * @param _addressUser address of the user to sent reward
     * @param submitTimestamp time at which answer was submitted
     */
    function answerQuestion(
        string calldata questionId,
        bool result,
        address _addressUser,
        uint256 submitTimestamp
    ) external onlyValid(questionId) {
        require(msg.sender == platform, "Cryptopati: only platform");

        require(
            block.timestamp - submitTimestamp <=
                _questions[questionId].timeDuration,
            "Cryptopati: Out of Time"
        );
        require(
            _userToQuestionId[_addressUser][questionId].unlocked == true,
            "Crptopati: Question not unlocked"
        );

        if (result == true) {
            multiplierAmount =
                (userCommitAmount[msg.sender][questionId] *
                    _questions[questionId].multiplier) -
                userCommitAmount[msg.sender][questionId];

            accuCoin.mint(_addressUser, multiplierAmount);
            accuCoin.transfer(
                _addressUser,
                userCommitAmount[msg.sender][questionId]
            );
            userInfo[_addressUser].totalAmountCollected += (userCommitAmount[
                msg.sender
            ][questionId] + multiplierAmount);
        }

        emit WinQuestion(
            _addressUser,
            questionId,
            userCommitAmount[msg.sender][questionId] + multiplierAmount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAccuCoin is IERC20 {
    function mint(address, uint256) external;
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