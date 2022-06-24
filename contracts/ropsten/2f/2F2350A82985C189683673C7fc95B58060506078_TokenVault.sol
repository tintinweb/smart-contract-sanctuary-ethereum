// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";

/// @title TokenVault compounder for BitGear staking pool
/// @dev Compunder to Token => Token staking
contract TokenVault is Ownable, Pausable {
    /// @notice Deposit and reward token address
    IERC20 public immutable token;

    /// @notice Address of staking contract
    IStaking public immutable staking;

    /// @notice Divider to calculate fee to harvester
    /// @dev Use in [callFee/PERCENT_BASE] = actualPercent
    /// @dev example: 25/10000 = 0.0025 (0.25%)
    uint256 public constant PERCENT_BASE = 10000;

    /// @notice Harvester fee can't be more then this
    uint256 public constant MAX_CALL_FEE = 1000; // 10%

    /// @notice pool_id constant to interact with first pool at staking
    uint256 public constant PID = 0;

    /// @notice Summ of all shares
    uint256 public totalShares;

    /// @notice Call fee to calculate harvester reward
    /// @dev harvesterReward == overallPoolReward*(callFee/PERCENT_BASE)
    uint256 public callFee;

    /// @notice Keeps tracking of allowance of tokens to staking contract
    uint256 private allowance;

    /// @notice Keeps info about each user
    /// @dev mapping [user.address] => {shares, lastUserActionTime}
    mapping(address => UserInfo) public userInfo;

    /// @notice UserInfo struct to keep user data: shares, actionTime, all deposits, total profit.
    struct UserInfo {
        uint256 shares;
        uint256 lastUserActionTime;
        uint256 deposit;
        uint256 earned;
    }

    /// @notice Deposit event
    /// @dev userAddress[address], tokenAmount [BN], shares [BN]
    event Deposit(address indexed sender, uint256 amount, uint256 shares);

    /// @notice Withdraw event
    /// @dev userAddress[address], tokenAmount [BN], shares [BN]
    event Withdraw(address indexed sender, uint256 amount, uint256 shares);

    /// @notice Emergency withdraw
    /// @dev userAddress[address], tokenAmount [BN], shares [BN]
    event EmergencyWithdraw(
        address indexed sender,
        uint256 amount,
        uint256 shares
    );

    /// @notice Harvest event
    /// @dev harvester[address] harvestRevard[BN]
    event Harvest(address indexed sender, uint256 callFee);

    /// @notice Pause event
    event Pause();
    /// @notice Unpause event
    event Unpause();

    /// @notice Checks if the _msgSender() is a contract or a proxy
    modifier notContract() {
        require(!_isContract(_msgSender()), "contract not allowed");
        require(_msgSender() == tx.origin, "proxy contract not allowed");
        _;
    }

    /// @notice Invokes when contract deploys
    /// @dev Check that addresses are correct
    /// @param _token [address] of compounding token
    /// @param _staking [address] of staking contract
    constructor(IERC20 _token, IStaking _staking) {
        require(
            address(_token) != address(0) && address(_staking) != address(0),
            "Wrong address"
        );
        token = _token;
        staking = _staking;
        allowance = type(uint256).max;
        callFee = 25; // 2.5%
        IERC20(_token).approve(address(_staking), allowance);
    }

    /// @notice Deposits funds into the tokenVault
    /// @dev Only possible when contract not paused.
    /// @param _amount [BN] number of tokens to deposit (in wei)
    function deposit(uint256 _amount) external whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];

        uint256 currentShares;
        uint256 amountToStake = _amount;
        uint256 totalPoolAmount = balanceOf();
        uint256 poolReward = staking.pendingReward(PID, address(this));

        if (poolReward != 0) {
            staking.withdraw(PID, 0);
            totalPoolAmount += poolReward;
            amountToStake += poolReward;
        }

        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / totalPoolAmount;
        } else {
            currentShares = _amount;
        }
        user.deposit += _amount;
        user.shares += currentShares;
        totalShares += currentShares;

        user.lastUserActionTime = block.timestamp;

        _checkAllowance(amountToStake);

        token.transferFrom(sender, address(this), _amount);
        staking.deposit(PID, amountToStake);

        emit Deposit(sender, _amount, currentShares);
    }

    /// @notice Manual harvest to yield reward
    function harvest() external notContract whenNotPaused {
        _earn(true);
    }

    /// @notice Changes call fee
    /// @dev Can be only less or equal 10000 (10%)
    /// @param _callFee [BN] share that harvester yields
    function setCallFee(uint256 _callFee) external onlyOwner {
        require(
            _callFee <= MAX_CALL_FEE,
            "callFee cannot be more than MAX_CALL_FEE"
        );
        callFee = _callFee;
    }

    /// @notice Withdraw function for users case of emergency at staking
    /// @dev Only works when contract is on pause
    function emergencyUserWithdraw() external notContract whenPaused {
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        require(user.shares > 0, "Nothing to withdraw");

        uint256 currentAmountToWithdraw = (token.balanceOf(address(this)) *
            user.shares) / totalShares;
        uint256 lastShares = user.shares;

        user.lastUserActionTime = block.timestamp;
        totalShares = totalShares - user.shares;

        user.deposit = 0;
        user.shares = 0;

        token.transfer(sender, currentAmountToWithdraw);

        emit EmergencyWithdraw(sender, currentAmountToWithdraw, lastShares);
    }

    /// @notice Function to get mistaken sent tokens to owner.
    /// @param _token [address] address of token
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_msgSender(), amount);
    }

    /// @notice Triggers stopped state and emergencyWithdraw from staking.
    /// @dev Only possible when contract not paused, if you are owner. Cannot be reverted
    function pause() external onlyOwner whenNotPaused {
        _pause();
        staking.emergencyWithdraw(PID);
        allowance = 0;
        token.approve(address(staking), allowance);
        emit Pause();
    }

    /// @notice Get reward that harvester can yield
    /// @return [BN] token amount in wei
    function calculateHarvestRewards() external view returns (uint256) {
        uint256 amount = staking.pendingReward(PID, address(this));
        uint256 currentCallFee = (amount * callFee) / (PERCENT_BASE);
        return currentCallFee;
    }

    /// @notice Get amount that not harvested yet
    /// @return [BN] token amount in wei
    function calculateTotalPendingRewards() external view returns (uint256) {
        return staking.pendingReward(PID, address(this));
    }

    /// @notice Get user balance without pool pending reward
    /// @param _of [address] address of user
    /// @return [BN] token amount in wei
    function calculateCurrentBalance(address _of)
        external
        view
        returns (uint256)
    {
        return
            totalShares == 0
                ? 0
                : ((balanceOf() * userInfo[_of].shares) / (totalShares));
    }

    /// @notice Get price per 1 ether shares
    /// @dev Usie while calculating user.shares
    /// @return [BN] price in wei
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : (total() * 1e18) / (totalShares);
    }

    /// @notice Get total stake. If user decide to withdraw, he will get this amount of funds
    /// @return [BN] amount in wei
    function getTotalStakeOf(address _of) external view returns (uint256) {
        uint256 pending = (total() * userInfo[_of].shares) / (totalShares);

        return pending;
    }

    /// @notice Triggers withdraw of all funds of user
    function withdrawAll() external notContract {
        withdrawShares(userInfo[_msgSender()].shares);
    }

    /// @notice Withdraws certain amount of shares
    /// @dev Contract compounding funds and withdraws desired amount
    /// @param _shares [BN] amount of shares in wei
    function withdrawShares(uint256 _shares) public notContract whenNotPaused {
        address sender = _msgSender();
        UserInfo storage user = userInfo[sender];
        require(_shares > 0, "Nothing to withdraw");
        require(_shares <= user.shares, "Withdraw amount exceeds balance");

        _earn(false);

        uint256 stakingBalance = balanceOf();
        uint256 fullUserBalance = (stakingBalance * user.shares) / totalShares;
        uint256 currentAmountToWithdraw = (stakingBalance * _shares) /
            totalShares;
        uint256 finalUserBalance = fullUserBalance - currentAmountToWithdraw;

        user.lastUserActionTime = block.timestamp;
        user.shares = user.shares - _shares;
        totalShares = totalShares - _shares;

        if (finalUserBalance < user.deposit) {
            user.earned +=
                currentAmountToWithdraw +
                finalUserBalance -
                user.deposit;
            user.deposit = finalUserBalance;
        } else {
            user.earned += currentAmountToWithdraw;
        }

        staking.withdraw(PID, currentAmountToWithdraw);
        token.transfer(sender, currentAmountToWithdraw);

        emit Withdraw(sender, currentAmountToWithdraw, _shares);
    }

    /// @notice Staked balance of contract
    /// @return [BN] token amount
    function balanceOf() public view returns (uint256) {
        (uint256 amount, , ) = staking.userInfo(PID, address(this));

        return amount;
    }

    /// @notice Total amount of contract funds
    /// @return [BN] token amount
    function total() internal view returns (uint256) {
        (uint256 amount, , ) = staking.userInfo(PID, address(this));
        amount += staking.pendingReward(PID, address(this));
        return amount;
    }

    /// @notice Invokes compounding process
    /// @dev Withdraws reward and deposits it again
    function _earn(bool _fromHarvest) internal {
        address sender = _msgSender();
        uint256 pendingReward = staking.pendingReward(PID, address(this));

        if (pendingReward != 0) {
            staking.withdraw(PID, 0);

            if (_fromHarvest) {
                uint256 callerFee = ((pendingReward) * callFee) / PERCENT_BASE;
                pendingReward -= callerFee;
                token.transfer(sender, callerFee);
                emit Harvest(sender, callerFee);
            }
            _checkAllowance(pendingReward);
            staking.deposit(PID, pendingReward);
        }
    }

    /// @notice Should check token allowance
    /// @dev Approves to max when it's over
    function _checkAllowance(uint256 _deposit) internal {
        if (allowance >= _deposit) {
            allowance -= _deposit;
        } else {
            token.approve(address(staking), type(uint256).max);
            allowance = type(uint256).max - _deposit;
        }
    }

    /// @notice Checks that caller is an address to prevent attacks and abuses
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
pragma solidity ^0.8.0;

interface IStaking {
    function poolLength() external view returns(uint256);
    function rewardPerSecond() external view returns(uint256);
    function pendingReward(uint256 _pid, address _user) external view returns(uint256); 
    function setRewardPerSecond(uint256 _rewardPerSecond, bool _withUpdate) external;
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256,uint256);
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