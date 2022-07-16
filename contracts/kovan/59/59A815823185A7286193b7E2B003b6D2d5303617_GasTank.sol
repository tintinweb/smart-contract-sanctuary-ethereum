//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./interfaces/IGasTank.sol";
import "./interfaces/ITreasury.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title GasTank Contract
/// @notice Contract in which the user will deposit ETH (to pay gas costs) and DAEM (to pay tips).
/// Executors will inform the GasTank each time a script is run and this will subtract the due amounts.
contract GasTank is IGasTank, Ownable {
    ITreasury public treasury;
    IERC20 internal DAEMToken;
    mapping(address => uint256) gasBalances;
    mapping(address => uint256) tipBalances;
    mapping(address => uint256) rewardFromGas;
    mapping(address => uint256) rewardFromTips;
    mapping(address => bool) executors;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0));
        treasury = ITreasury(_treasury);
    }

    function setDAEMToken(address _token) external onlyOwner {
        require(_token != address(0));
        DAEMToken = IERC20(_token);
    }

    function addExecutor(address executor) external onlyOwner {
        executors[executor] = true;
    }

    function removeExecutor(address executor) external onlyOwner {
        executors[executor] = false;
    }

    /** Checks whether the contract is ready to operate */
    function preliminaryCheck() external view {
        require(address(treasury) != address(0), "Treasury");
        require(address(DAEMToken) != address(0), "DAEMToken");
    }

    /* ========== VIEWS ========== */

    /// @inheritdoc IGasTank
    function gasBalanceOf(address user) external view override returns (uint256) {
        return gasBalances[user];
    }

    /// @inheritdoc IGasTank
    function tipBalanceOf(address user) external view override returns (uint256) {
        return tipBalances[user];
    }

    /// @inheritdoc IGasTank
    function claimable(address user) external view override returns (uint256) {
        uint256 dueFromGas = rewardFromGas[user];
        uint256 dueFromTips = rewardFromTips[user];

        uint256 gasConvertedToDAEM = dueFromGas > 0 ? treasury.ethToDAEM(dueFromGas) : 0;
        uint256 tipsMinusTaxes = (dueFromTips * treasury.TIPS_AFTER_TAXES_PERCENTAGE()) / 10000;

        return gasConvertedToDAEM + tipsMinusTaxes;
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /// @inheritdoc IGasTank
    function depositGas() external payable override {
        gasBalances[msg.sender] = gasBalances[msg.sender] + msg.value;
    }

    /// @inheritdoc IGasTank
    function withdrawGas(uint256 amount) external override {
        require(gasBalances[msg.sender] >= amount);
        gasBalances[msg.sender] = gasBalances[msg.sender] - amount;
        payable(msg.sender).transfer(amount);
    }

    /// @inheritdoc IGasTank
    function withdrawAllGas() external override {
        uint256 amount = gasBalances[msg.sender];
        gasBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /// @inheritdoc IGasTank
    function depositTip(uint256 amount) external override {
        require(amount > 0, "Cannot deposit 0");
        DAEMToken.transferFrom(msg.sender, address(this), amount);
        tipBalances[msg.sender] += amount;
    }

    /// @inheritdoc IGasTank
    function withdrawTip(uint256 amount) external override {
        require(amount > 0, "Cannot withdraw 0");
        require(tipBalances[msg.sender] >= amount, "Insufficient tip balance");
        tipBalances[msg.sender] -= amount;
        DAEMToken.transfer(msg.sender, amount);
    }

    /// @inheritdoc IGasTank
    function withdrawAllTip() external override {
        require(tipBalances[msg.sender] >= 0, "Insufficient tip balance");
        DAEMToken.transfer(msg.sender, tipBalances[msg.sender]);
        tipBalances[msg.sender] = 0;
    }

    /// @inheritdoc IGasTank
    function addReward(
        bytes32 scriptId,
        uint256 ethAmount,
        uint256 tipAmount,
        address user,
        address executor
    ) external override {
        require(executors[_msgSender()], "Unauthorized. Only Executors");
        gasBalances[user] -= ethAmount;
        rewardFromGas[executor] += ethAmount;

        if (tipAmount > 0) {
            // if any tip is specified, we immediately send the funds to the treasury
            // and we increase the tips balance of the executor. The treasury will
            // apply the tax itself.
            tipBalances[user] -= tipAmount;
            rewardFromTips[executor] += tipAmount;
            DAEMToken.transferFrom(user, address(treasury), tipAmount);
        }

        emit ScriptExecuted(scriptId, user, executor);
    }

    /// @inheritdoc IGasTank
    function claimReward() external override {
        uint256 dueFromGas = rewardFromGas[msg.sender];
        require(dueFromGas > 0, "Nothing to claim");
        uint256 dueFromTips = rewardFromTips[msg.sender];

        rewardFromGas[msg.sender] = 0;
        rewardFromTips[msg.sender] = 0;
        treasury.requestPayout{value: dueFromGas}(msg.sender, dueFromTips);
    }

    /// @inheritdoc IGasTank
    function claimAndStakeReward() external override {
        uint256 dueFromGas = rewardFromGas[msg.sender];
        require(dueFromGas > 0, "Nothing to claim");
        uint256 dueFromTips = rewardFromTips[msg.sender];

        rewardFromGas[msg.sender] = 0;
        rewardFromTips[msg.sender] = 0;
        treasury.stakePayout{value: dueFromGas}(msg.sender, dueFromTips);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IGasTank {
    /// @notice Event fired each time a script has been executed.
    /// @dev This event will be listened to in the Storage and
    /// it will trigger the creation of new transactions in the DB.
    event ScriptExecuted(bytes32 scriptId, address scriptOwner, address executor);

    /// @notice Get the amount of ETH the user has deposited in the gas tank
    /// @param user the address of the user to inspect
    /// @return the user gas balance
    function gasBalanceOf(address user) external view returns (uint256);

    /// @notice Add ETH to the gas tank
    function depositGas() external payable;

    /// @notice Withdraw ETH from the gas tank
    /// @param amount the amount of gas to withdraw
    function withdrawGas(uint256 amount) external;

    /// @notice Withdraw all ETH from the gas tank
    function withdrawAllGas() external;

    /// @notice Get the amount of DAEM the user has deposited in the tip jar
    /// @param user the address of the user to inspect
    /// @return the user gas balance
    function tipBalanceOf(address user) external view returns (uint256);

    /// @notice Deposits DAEM into the tip jar
    /// @param amount the amount of DAEM to deposit
    function depositTip(uint256 amount) external;

    /// @notice Withdraws DAEM from the tip jar
    /// @param amount the amount of DAEM to deposit
    function withdrawTip(uint256 amount) external;

    /// @notice Withdraws all DAEM from the tip jar
    function withdrawAllTip() external;

    /// @notice Removes funds from the gas tank of a user,
    /// in order to have them employed as payment for the execution of a script.
    /// @dev note: only executor contracts can call this function.
    /// @param scriptId the id of the script being executed
    /// @param ethAmount the amount of ETH to withdraw from the user gas tank
    /// @param tipAmount the amount of DAEM to withdraw from the user tip jar
    /// @param user the script owner
    /// @param executor the script executor
    function addReward(
        bytes32 scriptId,
        uint256 ethAmount,
        uint256 tipAmount,
        address user,
        address executor
    ) external;

    /// @notice The amount of tokens that can be claimed as payment for an executor work
    /// @param user the address of the user to inspect
    function claimable(address user) external view returns (uint256);

    /// @notice Claim the token received as payment for an executor work
    function claimReward() external;

    /// @notice Immediately deposit the user's claimable amount into the treasury for staking purposes
    function claimAndStakeReward() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface ITreasury {
    /// @notice The percentage that will be given to the executor after the taxes on tips have been calculated
    function TIPS_AFTER_TAXES_PERCENTAGE() external view returns (uint16);

    /// @notice The amount of DAEM tokens left to be distributed
    function tokensForDistribution() external view returns (uint256);

    /// @notice Function called by the gas tank to initialize a payout to the specified user
    /// @param user the user to be paid
    /// @param dueFromTips the amount the user earned via DAEM tips
    function requestPayout(address user, uint256 dueFromTips) external payable;

    /// @notice Function called by the gas tank to immediately stake the payout of the specified user
    /// @param user the user to be paid
    /// @param dueFromTips the amount the user earned via DAEM tips
    function stakePayout(address user, uint256 dueFromTips) external payable;

    /// @notice Given an amount of Ethereum, calculates how many DAEM it corresponds to
    /// @param ethAmount the ethereum amount
    function ethToDAEM(uint256 ethAmount) external view returns (uint256);
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