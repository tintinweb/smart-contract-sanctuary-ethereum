pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMintableERC20.sol";
import "./Initializable.sol";

contract Staking is Ownable, ReentrancyGuard, Initializable {

    event Deposited(
        address indexed sender,
        address indexed owner,
        uint256 amount
    );

    event DepositedPresale(
        address indexed owner,
        uint256 ethSupplied
    );

    event Withdrawal(
        address indexed sender,
        uint256 amount
    );

    event RewardReceived(
        address indexed owner,
        uint256 rewardAmount
    );

    struct Deposit {
        bool isPresaled;
        uint256 startTime;
        uint256 deposited;
        uint256 rewardTaken;
    }

    struct PresaleDeposit {
        uint256 startTime;
        uint128 ethDeposited;
        uint128 rewardTaken;
    }

    modifier onlyPresale() {
        require(msg.sender == presale, "Not Presale");
        _;
    }

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant BASIS_POINTS_USDT = 1e18 * 10000;
    uint256 public constant REWARD_PERCENTAGE = 28;
    uint256 public constant REWARD_PERCENTAGE_USDT = 6 * 1e18;
    uint256 public publicStakeStartTime;

    address public presale;
    IMintableERC20 public token;
    IERC20 public usdt;

    mapping(address => mapping(uint256 => Deposit)) public userInfos;
    mapping(address => uint256) public userInfosLength;

    mapping(address => mapping(uint256 => PresaleDeposit)) public userInfosPresale;
    mapping(address => uint256) public userInfosPresaleLength;

    constructor() {

    }

    function init(address _presale, address _token, address _usdt) external onlyOwner {
        presale = _presale;
        token = IMintableERC20(_token);
        usdt = IERC20(_usdt);
    }

    function stakePresale(address _to, uint256 _amount, uint256 _ethDeposited) external onlyPresale {
        uint256 nextDepositId = userInfosLength[_to];
        Deposit memory freshDeposit = Deposit(
            true,
            block.timestamp,
            _amount,
            0
        );

        userInfos[_to][nextDepositId] = freshDeposit;
        userInfosLength[_to]++;

        PresaleDeposit memory freshPresaleDeposit = PresaleDeposit(
            block.timestamp,
            uint128(_ethDeposited),
            0
        );

        userInfosPresale[_to][nextDepositId] = freshPresaleDeposit;
        userInfosPresaleLength[_to]++;

        emit Deposited(
            msg.sender,
            _to,
            _amount
        );

        emit DepositedPresale(
            msg.sender,
            _ethDeposited
        );
    }

    function stake(uint256 _amount) external {
        token.transferFrom(msg.sender, address(this), _amount);

        Deposit memory freshDeposit = Deposit(
            false,
            block.timestamp,
            _amount,
            0
        );

        userInfos[msg.sender][userInfosLength[msg.sender]] = freshDeposit;
        userInfosLength[msg.sender]++;

        emit Deposited(
            msg.sender,
            msg.sender,
            _amount
        );
    }

    function receiveRewards() external nonReentrant {
        uint256 rewardAmount = 0;

        uint256 userDepositsLength = userInfosLength[msg.sender];

        for(uint256 i = 0; i < userDepositsLength; i++) {
            Deposit memory deposit = userInfos[msg.sender][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
            uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
            uint256 availableReward = ((deposit.deposited * REWARD_PERCENTAGE * rewardMultiplier * daysSinceStart) / BASIS_POINTS) - deposit.rewardTaken;

            userInfos[msg.sender][i].rewardTaken += availableReward;

            rewardAmount += availableReward;
            emit RewardReceived(msg.sender, availableReward);
        }

        token.mint(msg.sender, rewardAmount);

        emit RewardReceived(
            msg.sender,
            rewardAmount
        );
    }

    function receiveRewardsUsdt() external {
        uint256 rewardAmount = 0;

        uint256 userDepositsLength = userInfosPresaleLength[msg.sender];

        for(uint256 i = 0; i < userDepositsLength; i++) {
            PresaleDeposit memory deposit = userInfosPresale[msg.sender][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
            uint256 availableReward = ((deposit.ethDeposited * REWARD_PERCENTAGE_USDT * daysSinceStart) / BASIS_POINTS_USDT) - deposit.rewardTaken;

            userInfosPresale[msg.sender][i].rewardTaken += uint128(availableReward);

            rewardAmount += availableReward;
        }

        usdt.transfer(msg.sender, rewardAmount);
    }

    function receiveReward(uint256 _depositIndex) external nonReentrant {
        require(_depositIndex <= userInfosLength[msg.sender], "Too high index");

        Deposit memory deposit = userInfos[msg.sender][_depositIndex];
        uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
        uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
        uint256 availableReward = ((deposit.deposited * REWARD_PERCENTAGE * rewardMultiplier * daysSinceStart) / BASIS_POINTS) - deposit.rewardTaken;
        userInfos[msg.sender][_depositIndex].rewardTaken += availableReward;

        token.mint(msg.sender, availableReward);

        emit RewardReceived(msg.sender, availableReward);
    }

    function withdraw(uint256 _depositIndex) external nonReentrant {
        Deposit memory deposit = userInfos[msg.sender][_depositIndex];

        uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
        uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;

        uint256 rewardsAvailable = ((deposit.deposited * REWARD_PERCENTAGE * rewardMultiplier * daysSinceStart) / BASIS_POINTS) - deposit.rewardTaken;

        token.mint(address(this), rewardsAvailable);
        token.transfer(msg.sender, deposit.deposited + rewardsAvailable);

        userInfos[msg.sender][_depositIndex].deposited = 0;
        userInfos[msg.sender][_depositIndex].rewardTaken += rewardsAvailable;

        if(_depositIndex < userInfosPresaleLength[msg.sender]) {
            PresaleDeposit memory deposit2 = userInfosPresale[msg.sender][_depositIndex];
            uint256 daysSinceStart2 = (block.timestamp - deposit.startTime) / 86400;
            uint256 availableReward = ((deposit2.ethDeposited * REWARD_PERCENTAGE_USDT * daysSinceStart2) / BASIS_POINTS_USDT) - deposit2.rewardTaken;

            userInfosPresale[msg.sender][_depositIndex].rewardTaken += uint128(availableReward);
            userInfosPresale[msg.sender][_depositIndex].ethDeposited = 0;

            usdt.transfer(msg.sender, availableReward);
        }

        emit Withdrawal(msg.sender, deposit.deposited);
    }

    function getAllDeposits(address _to) external view returns(Deposit[] memory) {
        uint256 depositsLength = userInfosLength[_to];
        Deposit[] memory result = new Deposit[](depositsLength);

        for(uint256 i = 0; i < depositsLength; i++) {
            result[i] = userInfos[_to][i];
        }

        return result;
    }

    function getAvailableRewards(address _to) external view returns(uint256[] memory) {
        uint256 userRewardsLength = userInfosLength[_to];

        uint256[] memory result = new uint256[](userRewardsLength);

        for(uint256 i = 0; i < userRewardsLength; i++) {
            Deposit memory deposit = userInfos[_to][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;

            uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
            result[i] = (deposit.deposited * REWARD_PERCENTAGE * daysSinceStart * rewardMultiplier) / BASIS_POINTS - deposit.rewardTaken;
        }

        return result;
    }

    function getAvailableRewardsUsdt(address _to) external view returns(uint256) {
        uint256 rewardAmount = 0;

        uint256 userDepositsLength = userInfosPresaleLength[_to];

        for(uint256 i = 0; i < userDepositsLength; i++) {
            PresaleDeposit memory deposit = userInfosPresale[_to][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
            uint256 availableReward = ((deposit.ethDeposited * REWARD_PERCENTAGE_USDT * daysSinceStart) / BASIS_POINTS_USDT) - deposit.rewardTaken;

            rewardAmount += availableReward;
        }

        return rewardAmount;
    }

    function addUSDTSupply(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
    }
}

pragma solidity ^0.8.9;

abstract contract Initializable {
    bool public initialized;

    modifier notInitialized() {
        require(!initialized, "Already initialized");
        _;
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {

    function mint(address _to, uint256 _amount) external;

    function burn(uint256 _amount) external;

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