// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultyGoalVault is Ownable {
    struct UserSavings {
        uint256 goal;
        uint256 balance;
    }

    mapping(address => bool) public whitelistedTokens;
    mapping(address => mapping(uint256 => UserSavings)) public userSavings;
    mapping(address => uint256) public nextDepositId;

    uint256 public protocolFee = 0 ether;  // Initialize with default fee
    uint256 public penaltyPercent = 10;  // 10% early withdrawal penalty

    event CreateGoal(address indexed user, uint256 indexed depositId, address indexed token, uint256 goal, uint256 amount);
    event Deposit(address indexed user, uint256 depositId, address indexed token, uint256 amount);
    event Withdraw(address indexed user, uint256 depositId, address indexed token, uint256 amount);
    

    function setWhitelistToken(address token, bool status) external onlyOwner {
        whitelistedTokens[token] = status;
    }

    function setProtocolFee(uint256 newFee) external onlyOwner {
        protocolFee = newFee;
    }

    function createGoal(address token, uint256 amount, uint256 goal) external payable {
        require(msg.value >= protocolFee, "Protocol fee not met");
        require(whitelistedTokens[token], "Token not whitelisted");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 depositId = nextDepositId[msg.sender]++;
        UserSavings storage userSaving = userSavings[msg.sender][depositId];
        userSaving.goal = goal;
        userSaving.balance += amount;

        // Transfer protocol fee to the contract owner
        payable(owner()).transfer(protocolFee);

        emit CreateGoal(msg.sender, depositId, token, goal, amount);
    }

    function deposit(uint256 depositId, address token, uint256 amount) external {
        require(whitelistedTokens[token], "Token not whitelisted");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        UserSavings storage userSaving = userSavings[msg.sender][depositId];
        userSaving.balance += amount;

        emit Deposit(msg.sender, depositId, token, amount);
    }

    function withdraw(uint256 depositId, address token) external {
        UserSavings storage userSaving = userSavings[msg.sender][depositId];
        require(userSaving.balance >= userSaving.goal, "Goal not reached yet");

        uint256 amount = userSaving.balance;
        userSaving.balance = 0;

        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");

        emit Withdraw(msg.sender, depositId, token, amount);
    }

    function earlyWithdraw(uint256 depositId, address token) external {
        UserSavings storage userSaving = userSavings[msg.sender][depositId];
        require(userSaving.balance > 0, "No savings to withdraw");

        uint256 penaltyAmount = (userSaving.balance * penaltyPercent) / 100;
        uint256 amount = userSaving.balance - penaltyAmount;

        userSaving.balance = 0;

        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        require(IERC20(token).transfer(owner(), penaltyAmount), "Penalty transfer failed");

        emit Withdraw(msg.sender, depositId, token, amount);
    }
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