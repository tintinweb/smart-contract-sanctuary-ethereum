pragma solidity 0.5.4;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/drafts/SignedSafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IERC1594Capped.sol";
import "../interfaces/IRewards.sol";
import "../interfaces/IRewardsUpdatable.sol";
import "../interfaces/IRewardable.sol";
import "../roles/RewarderRole.sol";
import "../lib/Whitelistable.sol";


/**
* @notice This contract determines the amount of rewards each user is entitled to and allows users to withdraw their rewards.
* @dev The rewards (in the form of a 'rewardsToken') are calculated based on a percentage ownership of a 'rewardableToken'.
* The rewards calculation takes into account token movements using a 'damping' factor.
* This contract makes use of pull payments over push payments to avoid DoS vulnerabilities.
*/
contract Rewards is IRewards, IRewardsUpdatable, RewarderRole, Pausable, Ownable, ReentrancyGuard, Whitelistable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using SignedSafeMath for int;

    IERC1594Capped private rewardableToken; // Rewardable tokens gives rewards when held.
    IERC20 private rewardsToken; // Rewards tokens are given out as rewards.
    address private rewardsNotifier; // Contract address where token movements are broadcast from.

    bool public isRunning = true;
    uint public maxShares; // Total TENX cap. Constant amount.
    uint public totalRewards; // The current size of the global pool of PAY rewards. Can decrease because of TENX burning.
    uint public totalDepositedRewards; // Total PAY rewards deposited for users so far. Monotonically increasing.
    uint public totalClaimedRewards; // Amount of rewards claimed by users so far. Monotonically increasing.
    mapping(address => int) private _dampings; // Balancing factor to account for rewardable token movements.
    mapping(address => uint) public claimedRewards; // Claimed PAY rewards per user.

    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed from, uint amount);
    event Reclaimed(uint amount);
    event NotifierUpdated(address implementation);

    constructor(IERC1594Capped _rewardableToken, IERC20 _rewardsToken) public {
        uint _cap = _rewardableToken.cap();
        require(_cap != 0, "Shares token cap must be non-zero.");
        maxShares = _cap;
        rewardableToken = _rewardableToken;
        rewardsToken = _rewardsToken;
        rewardsNotifier = address(_rewardableToken);
    }

    /**
    * @notice Modifier to check that functions are only callable by a predefined address.
    */   
    modifier onlyRewardsNotifier() {
        require(msg.sender == rewardsNotifier, "Can only be called by the rewards notifier contract.");
        _;
    }

    /**
    * @notice Modifier to check that the Rewards contract is currently running.
    */
    modifier whenRunning() {
        require(isRunning, "Rewards contract has stopped running.");
        _;
    }

    function () external payable { // Ether fallback function
        require(msg.value == 0, "Received non-zero msg.value.");
        withdraw();
    }

    /**
    * Releases a specified amount of rewards to all shares token holders.
    * @dev The rewards each user is allocated to receive is calculated dynamically.
    * Note that the contract needs to hold sufficient rewards token balance to disburse rewards.
    * @param _amount Amount of reward tokens to allocate to token holders.
    */
    function deposit(uint _amount) external onlyRewarder whenRunning whenNotPaused {
        require(_amount != 0, "Deposit amount must non-zero.");
        totalDepositedRewards = totalDepositedRewards.add(_amount);
        totalRewards = totalRewards.add(_amount);
        address from = msg.sender;
        emit Deposited(from, _amount);

        rewardsToken.safeTransferFrom(msg.sender, address(this), _amount); // [External contract call to PAYToken]
    }

    /**
    * @notice Links a RewardsNotifier contract to update this contract on token movements.
    * @param _notifier Contract address.
    */
    function setRewardsNotifier(address _notifier) external onlyOwner {
        require(address(_notifier) != address(0), "Rewards address must not be a zero address.");
        require(Address.isContract(address(_notifier)), "Address must point to a contract.");
        rewardsNotifier = _notifier;
        emit NotifierUpdated(_notifier);
    }

    /**
    * @notice Updates a damping factor to account for token transfers in the dynamic rewards calculation.
    * @dev This function adds +X damping to senders and -X damping to recipients, where X is _dampingChange().
    * This function is called in TENXToken `transfer()` and `transferFrom()`.
    * @param _from Sender address
    * @param _to Recipient address
    * @param _value Token movement amount
    */
    function updateOnTransfer(address _from, address _to, uint _value) external onlyRewardsNotifier nonReentrant returns (bool) {
        int fromUserShareChange = int(_value); // <_from> sends their _value to <_to>, change is positive
        int fromDampingChange = _dampingChange(totalShares(), totalRewards, fromUserShareChange);

        int toUserShareChange = int(_value).mul(-1); // <_to> receives _value from <_from>, change is negative
        int toDampingChange = _dampingChange(totalShares(), totalRewards, toUserShareChange);

        assert((fromDampingChange.add(toDampingChange)) == 0);

        _dampings[_from] = damping(_from).add(fromDampingChange);
        _dampings[_to] = damping(_to).add(toDampingChange);
        return true;
    }

    /**
    * @notice Updates a damping factor to account for token butning in the dynamic rewards calculation.
    * @param _account address
    * @param _value Token burn amount
    */
    function updateOnBurn(address _account, uint _value) external onlyRewardsNotifier nonReentrant returns (bool) { 
        uint totalSharesBeforeBurn = totalShares().add(_value); // In Rewardable.sol, this is executed after the burn has deducted totalShares()
        uint redeemableRewards = _value.mul(totalRewards).div(totalSharesBeforeBurn); // Calculate amount of rewards the burned amount is entitled to
        totalRewards = totalRewards.sub(redeemableRewards); // Remove redeemable rewards from the global pool
        _dampings[_account] = damping(_account).add(int(redeemableRewards)); // Only _account is able to withdraw the unclaimed redeemed rewards
        return true;
    }

    /**
    * @notice Emergency fallback to drain the contract's balance of PAY tokens.
    */
    function reclaimRewards() external onlyOwner {
        uint256 balance = rewardsToken.balanceOf(address(this));
        isRunning = false;
        rewardsToken.safeTransfer(owner(), balance);
        emit Reclaimed(balance);
    }

   /**
    * @notice Withdraw your balance of PAY rewards.
    * @dev Only the unclaimed rewards amount can be withdrawn by a user.
    */
    function withdraw() public whenRunning whenNotPaused onlyWhitelisted(msg.sender) nonReentrant {
        address payee = msg.sender;
        uint unclaimedReward = unclaimedRewards(payee);
        require(unclaimedReward > 0, "Unclaimed reward must be non-zero to withdraw.");
        require(supply() >= unclaimedReward, "Rewards contract must have sufficient PAY to disburse.");

        claimedRewards[payee] = claimedRewards[payee].add(unclaimedReward); // Add amount to claimed rewards balance
        totalClaimedRewards = totalClaimedRewards.add(unclaimedReward);
        emit Withdrawn(payee, unclaimedReward);

        // Send PAY reward to payee
        rewardsToken.safeTransfer(payee, unclaimedReward); // [External contract call]
    }

    /**
    * @notice Returns this contract's current reward token supply.
    * @dev The contract must have sufficient PAY allowance to deposit() rewards.
    * @return Total PAY balance of this contract
    */
    function supply() public view returns (uint) {
        return rewardsToken.balanceOf(address(this));
    }

    /**
    * @notice Returns the reward model's denominator. Used to calculate user rewards.
    * @dev The denominator is = INITIAL TOKEN CAP - TOTAL REWARDABLE TOKENS REDEEMED.
    * @return denominator
    */
    function totalShares() public view returns (uint) {
        uint totalRedeemed = rewardableToken.totalRedeemed();
        return maxShares.sub(totalRedeemed);
    }

    /**
    * @notice Returns the amount of a user's unclaimed (= total allocated - claimed) rewards. 
    * @param _payee User address.
    * @return total unclaimed rewards for user
    */
    function unclaimedRewards(address _payee) public view returns(uint) {
        require(_payee != address(0), "Payee must not be a zero address.");
        uint totalUserReward = totalUserRewards(_payee);
        if (totalUserReward == uint(0)) {
            return 0;
        }

        uint unclaimedReward = totalUserReward.sub(claimedRewards[_payee]);
        return unclaimedReward;
    }

    /**
    * @notice Returns a user's total PAY rewards.
    * @param _payee User address.
    * @return total claimed + unclaimed rewards for user
    */
    function totalUserRewards(address _payee) internal view returns (uint) {
        require(_payee != address(0), "Payee must not be a zero address.");
        uint userShares = rewardableToken.balanceOf(_payee); // [External contract call]
        int userDamping = damping(_payee);
        uint result = _totalUserRewards(totalShares(), totalRewards, userShares, userDamping);
        return result;
    }    

    /**
    * @notice Calculate a user's damping factor change. 
    * @dev The damping factor is used to take into account token movements in the rewards calculation.
    * dampingChange = total PAY rewards * percentage change in a user's TENX shares
    * @param _totalShares Total TENX cap (constant ~200M.)
    * @param _totalRewards The current size of the global pool of PAY rewards.
    * @param _sharesChange The user's change in TENX balance. Can be positive or negative.
    * @return damping change for a given change in tokens
    */
    function _dampingChange(
        uint _totalShares,
        uint _totalRewards,
        int _sharesChange
    ) internal pure returns (int) {
        return int(_totalRewards).mul(_sharesChange).div(int(_totalShares));
    }

    /**
    * @notice Calculates a user's total allocated (claimed + unclaimed) rewards.    
    * @dev The user's total allocated rewards = (percentage of user's TENX shares * total PAY rewards) + user's damping factor
    * @param _totalShares Total TENX cap (constant.)
    * @param _totalRewards Total PAY rewards deposited so far.
    * @param _userShares The user's TENX balance.
    * @param _userDamping The user's damping factor.
    * @return total claimed + unclaimed rewards for user
    */
    function _totalUserRewards(
        uint _totalShares,
        uint _totalRewards,
        uint _userShares,
        int _userDamping
    ) internal pure returns (uint) {
        uint maxUserReward = _userShares.mul(_totalRewards).div(_totalShares);
        int userReward = int(maxUserReward).add(_userDamping);
        uint result = (userReward > 0 ? uint(userReward) : 0);
        return result;
    }

    function damping(address account) internal view returns (int) {
        return _dampings[account];
    }
}

pragma solidity 0.5.4;

import "openzeppelin-solidity/contracts/access/Roles.sol";


// @notice Rewarders are capable of managing the Rewards contract and depositing PAY rewards.
contract RewarderRole {
    using Roles for Roles.Role;

    event RewarderAdded(address indexed account);
    event RewarderRemoved(address indexed account);

    Roles.Role internal _rewarders;

    modifier onlyRewarder() {
        require(isRewarder(msg.sender), "Only Rewarders can execute this function.");
        _;
    }

    constructor() internal {
        _addRewarder(msg.sender);
    }    

    function isRewarder(address account) public view returns (bool) {
        return _rewarders.has(account);
    }

    function addRewarder(address account) public onlyRewarder {
        _addRewarder(account);
    }

    function renounceRewarder() public {
        _removeRewarder(msg.sender);
    }
  
    function _addRewarder(address account) internal {
        _rewarders.add(account);
        emit RewarderAdded(account);
    }

    function _removeRewarder(address account) internal {
        _rewarders.remove(account);
        emit RewarderRemoved(account);
    }
}

pragma solidity 0.5.4;

import "openzeppelin-solidity/contracts/access/Roles.sol";


// @notice Moderators are able to modify whitelists and transfer permissions in Moderator contracts.
contract ModeratorRole {
    using Roles for Roles.Role;

    event ModeratorAdded(address indexed account);
    event ModeratorRemoved(address indexed account);

    Roles.Role internal _moderators;

    modifier onlyModerator() {
        require(isModerator(msg.sender), "Only Moderators can execute this function.");
        _;
    }

    constructor() internal {
        _addModerator(msg.sender);
    }

    function isModerator(address account) public view returns (bool) {
        return _moderators.has(account);
    }

    function addModerator(address account) public onlyModerator {
        _addModerator(account);
    }

    function renounceModerator() public {
        _removeModerator(msg.sender);
    }    

    function _addModerator(address account) internal {
        _moderators.add(account);
        emit ModeratorAdded(account);
    }    

    function _removeModerator(address account) internal {
        _moderators.remove(account);
        emit ModeratorRemoved(account);
    }
}

pragma solidity 0.5.4;

import "../roles/ModeratorRole.sol";


contract Whitelistable is ModeratorRole {
    event Whitelisted(address account);
    event Unwhitelisted(address account);

    mapping (address => bool) public isWhitelisted;

    modifier onlyWhitelisted(address account) {
        require(isWhitelisted[account], "Account is not whitelisted.");
        _;
    }

    modifier onlyNotWhitelisted(address account) {
        require(!isWhitelisted[account], "Account is whitelisted.");
        _;
    }

    function whitelist(address account) external onlyModerator {
        require(account != address(0), "Cannot whitelist zero address.");
        require(account != msg.sender, "Cannot whitelist self.");
        require(!isWhitelisted[account], "Address already whitelisted.");
        isWhitelisted[account] = true;
        emit Whitelisted(account);
    }

    function unwhitelist(address account) external onlyModerator {
        require(account != address(0), "Cannot unwhitelist zero address.");
        require(account != msg.sender, "Cannot unwhitelist self.");
        require(isWhitelisted[account], "Address not whitelisted.");
        isWhitelisted[account] = false;
        emit Unwhitelisted(account);
    }
}

pragma solidity 0.5.4;


interface IRewardsUpdatable {
    event NotifierUpdated(address implementation);

    function updateOnTransfer(address from, address to, uint amount) external returns (bool);
    function updateOnBurn(address account, uint amount) external returns (bool);
    function setRewardsNotifier(address notifier) external;
}

pragma solidity 0.5.4;


interface IRewards {
    event Deposited(address indexed from, uint amount);
    event Withdrawn(address indexed from, uint amount);
    event Reclaimed(uint amount);

    function deposit(uint amount) external;
    function withdraw() external;
    function reclaimRewards() external;
    function claimedRewards(address payee) external view returns (uint);
    function unclaimedRewards(address payee) external view returns (uint);
    function supply() external view returns (uint);
    function isRunning() external view returns (bool);
}

pragma solidity 0.5.4;

import "./IRewardsUpdatable.sol";


interface IRewardable {
    event RewardsUpdated(address implementation);

    function setRewards(IRewardsUpdatable rewards) external;
}

pragma solidity 0.5.4;


interface IERC1594Capped {
    function balanceOf(address who) external view returns (uint256);
    function cap() external view returns (uint256);
    function totalRedeemed() external view returns (uint256);
}

pragma solidity ^0.5.2;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

pragma solidity ^0.5.2;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must equal true).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

import "../access/roles/PauserRole.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

pragma solidity ^0.5.2;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error
 */
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }
}

pragma solidity ^0.5.2;

import "../Roles.sol";

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

pragma solidity ^0.5.2;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}