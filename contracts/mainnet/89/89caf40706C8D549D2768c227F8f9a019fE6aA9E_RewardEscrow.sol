pragma solidity 0.5.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


/**
 * @title SharesTimelock interface
 */
interface ISharesTimeLock {
    function depositByMonths(uint256 amount, uint256 months, address receiver) external;
}


/**
 * @title DoughEscrow interface
 */
interface IDoughEscrow {
    function balanceOf(address account) external view returns (uint);
    function appendVestingEntry(address account, uint quantity) external;
}

interface IBuyback {
    function buyback(uint256 _tokenInQty, address _receiver) external returns (bool success);
    function maxAvailableToBuy() external view returns (uint available);     
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       RewardEscrow.sol
version:    1.1
author:     Jackson Chan
            Clinton Ennis

date:       2019-03-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
Escrows the DOUGH rewards from the inflationary supply awarded to
users for staking their DOUGH and maintaining the c-rationn target.

SNW rewards are escrowed for 1 year from the claim date and users
can call vest in 12 months time.
-----------------------------------------------------------------
*/


/**
 * @title A contract to hold escrowed DOUGH and free them at given schedules.
 */
contract RewardEscrow is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public dough;

    mapping(address => bool) public isRewardContract;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of DOUGH vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account's total escrowed dough balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalEscrowedAccountBalance;

    /* An account's total vested reward dough. */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining escrowed balance, for verifying the actual dough balance of this contract against. */
    uint public totalEscrowedBalance;

    uint constant TIME_INDEX = 0;
    uint constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules.
    * There are 5 years of the supply scedule */
    uint constant public MAX_VESTING_ENTRIES = 52*5;

    uint8 public constant decimals = 18;
    string public name;
    string public symbol;

    uint256 public constant STAKE_DURATION = 36;
    ISharesTimeLock public sharesTimeLock;

    /* @dev added in 1.1 */

    /* Commonly used burn address 
     * @dev as a constant this does not affect proxy storage */
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;    

    /* Address of the buyback contract for early exits */
    IBuyback public buyback;

    /* Admin function to permit calling the burn function */
    bool public burnEnabled;

    /* ========== Initializer ========== */

    function initialize (address _dough, string memory _name, string memory _symbol) public initializer
    {
        dough = IERC20(_dough);
        name = _name;
        symbol = _symbol;
        Ownable.initialize(msg.sender);
    }


    /* ========== SETTERS ========== */

    /**
     * @notice set the dough contract address as we need to transfer DOUGH when the user vests
     */
    function setDough(address _dough)
    external
    onlyOwner
    {
        dough = IERC20(_dough);
        emit DoughUpdated(address(_dough));
    }

    /**
     * @notice set the dough contract address as we need to transfer DOUGH when the user vests
     */
    function setTimelock(address _timelock)
    external
    onlyOwner
    {
        sharesTimeLock = ISharesTimeLock(_timelock);
        emit TimelockUpdated(address(_timelock));
    }

    /**
     * @notice Add a whitelisted rewards contract
     */
    function addRewardsContract(address _rewardContract) external onlyOwner {
        isRewardContract[_rewardContract] = true;
        emit RewardContractAdded(_rewardContract);
    }

    /**
     * @notice Remove a whitelisted rewards contract
    */
    function removeRewardsContract(address _rewardContract) external onlyOwner {
        isRewardContract[_rewardContract] = false;
        emit RewardContractRemoved(_rewardContract);
    }

    /**
     * @notice set the address for the dough buyback functionality
     */
    function setBuyback(address _buyback)
    external
    onlyOwner
    {
        buyback = IBuyback(_buyback);
        emit BuybackContractUpdated(_buyback);
    }

    /**
     * @notice if enabled, will allow users to burn edough 
     */
    function setBurnEnabled(bool _enabled)
    external
    onlyOwner
    {
        burnEnabled =  _enabled;
        emit BurnEnabledUpdated(_enabled);
    }    

    /**
     * @notice approve DOUGH to be transfered to another address
     * @dev call to linked contracts such as eDOUGH buyback to save on approvals each time
     * @param _spender the address to approve
     * @param _amount the quantity to approve
     */
    function approve(address _spender, uint _amount) external onlyOwner returns (bool) {
        require(_spender != address(0), "Cannot approve to zero address");
        dough.safeApprove(_spender, _amount);
        return true;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account)
    public
    view
    returns (uint)
    {
        return totalEscrowedAccountBalance[account];
    }

    /**
     * @notice A simple alias to totalEscrowedBalance: provides ERC20 totalSupply integration.
    */
    function totalSupply() external view returns (uint256) {
        return totalEscrowedBalance;
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account)
    public
    view
    returns (uint)
    {
        return vestingSchedules[account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, dough quantity).
     */
    function getVestingScheduleEntry(address account, uint index)
    public
    view
    returns (uint[2] memory)
    {
        return vestingSchedules[account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index)
    public
    view
    returns (uint)
    {
        return getVestingScheduleEntry(account,index)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of DOUGH associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index)
    public
    view
    returns (uint)
    {
        return getVestingScheduleEntry(account,index)[QUANTITY_INDEX];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account)
    public
    view
    returns (uint)
    {
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, DOUGH quantity). */
    function getNextVestingEntry(address account)
    public
    view
    returns (uint[2] memory)
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account)
    external
    view
    returns (uint)
    {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account)
    external
    view
    returns (uint)
    {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }

    /**
     * @notice return the full vesting schedule entries vest for a given user.
     */
    function checkAccountSchedule(address account)
        public
        view
        returns (uint[520] memory)
    {
        uint[520] memory _result;
        uint schedules = numVestingEntries(account);
        for (uint i = 0; i < schedules; i++) {
            uint[2] memory pair = getVestingScheduleEntry(account, i);
            _result[i*2] = pair[0];
            _result[i*2 + 1] = pair[1];
        }
        return _result;
    }

    /**
     * @notice how much eDOUGH can currently be sold back to the DAO, based on vesting + available balance of the buyback contract
     * @dev this does not account for the deadline passing - this must be checked separately
     * @param _recipient the account to check for
     * @return total units of DOUGH that can be sold to the DAO at the price listed in the buyback contract 
     * @return lastFulfillableVestingEntry last index of the sorted vesting array where we are able to completely fulfil the order
     * @dev use lastFulfillableVestingEntry in the buyback function to zero out all values at and before, while keeping this a view function 
     */
    function getAvailableForBuyBack(address _recipient) public view returns (uint total, uint lastFulfillableVestingEntry) {
        uint numEntries = numVestingEntries(_recipient);
        uint maxAvailableDough = buyback.maxAvailableToBuy();

        // iterate though the user's entries 
        for (uint i = 0; i < numEntries; i++) {
            uint[2] memory entry = getVestingScheduleEntry(_recipient, i);        
            uint quantity = entry[QUANTITY_INDEX];
            // we check if quantity and vestingTime is greater than 0 (otherwise, the entry was already claimed)
            if(quantity > 0 && entry[TIME_INDEX] > 0) {
                // edough claimants can enter into buyback at any point as long as we can afford it
                // No partial vests - must fulfill the entire entry
                if (total.add(quantity) <= maxAvailableDough) {
                    // cache the index so we can zero all entries in a non-view function
                    lastFulfillableVestingEntry = i;
                    total = total.add(quantity);
                } else {
                    // save gas by stopping the loop
                    break;
                }
            }
        }
    }    

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successfull call to dough.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only withinn the 4 year period of the weekly inflation schedule.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of DOUGH that will be escrowed.
     */
    function appendVestingEntry(address account, uint quantity)
    public
    onlyRewardsContract
    {
        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalEscrowedBalance = totalEscrowedBalance.add(quantity);
        require(totalEscrowedBalance <= dough.balanceOf(address(this)),
        "Must be enough balance in the contract to provide for the vesting entry");

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        /* Escrow the tokens for 1 year. */
        uint time = now + 52 weeks;

        if (scheduleLength == 0) {
            totalEscrowedAccountBalance[account] = quantity;
        } else {
            /* Disallow adding new vested DOUGH earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(getVestingTime(account, numVestingEntries(account) - 1) < time, "Cannot add new vested entries earlier than the last one");
            totalEscrowedAccountBalance[account] = totalEscrowedAccountBalance[account].add(quantity);
        }

        // If last window is less than a week old add amount to that one.
        if(
            vestingSchedules[account].length != 0 && 
            vestingSchedules[account][vestingSchedules[account].length - 1][0] > time - 1 weeks
        ) {
            vestingSchedules[account][vestingSchedules[account].length - 1][1] = vestingSchedules[account][vestingSchedules[account].length - 1][1].add(quantity);
        } else {
            vestingSchedules[account].push([time, quantity]);
        }
        
        emit Transfer(address(0), account, quantity);
        emit VestingEntryCreated(account, now, quantity);
    }

    /**
     * @notice Allow a user to withdraw any DOUGH in their schedule that have vested.
     */
    function vest()
    external
    {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty == 0) {
                continue;
            }

            vestingSchedules[msg.sender][i] = [0, 0];
            total = total.add(qty);
        }

        if (total != 0) {
            totalEscrowedBalance = totalEscrowedBalance.sub(total);
            totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);
            dough.safeTransfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
            emit Transfer(msg.sender, address(0), total);
        }
    }

    /**
     * @notice Allow a user to withdraw any DOUGH in their schedule to skip waiting and migrate to veDOUGH at maximum stake.
     * 
     */
    function migrateToVeDOUGH()
    external
    {
        require(address(sharesTimeLock) != address(0), "SharesTimeLock not set");
        uint numEntries = numVestingEntries(msg.sender); // get the number of entries for msg.sender
        
        /* 
        // As per PIP-67: 
        // We propose that a bridge be created to swap eDOUGH to veDOUGH with a non-configurable time lock of 3 years.
        // Only eDOUGH that has vested for 6+ months will be eligible for this bridge.
        // https://snapshot.org/#/piedao.eth/proposal/0xaf04cb5391de0cb3d9c9e694a2bf6e5d20f0e4e1c48e0a1d6f85c5233aa580b6
        */
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint[2] memory entry = getVestingScheduleEntry(msg.sender, i);        
            (uint quantity, uint vestingTime) = (entry[QUANTITY_INDEX], entry[TIME_INDEX]);
            
            // we check if quantity and vestingTime is greater than 0 (otherwise, the entry was already claimed)
            if(quantity > 0 && vestingTime > 0) {
                uint activationTime = entry[TIME_INDEX].sub(26 weeks); // point in time when the bridge becomes possible (52 weeks - 26 weeks = 26 weeks (6 months))

                if(block.timestamp >= activationTime) {
                    vestingSchedules[msg.sender][i] = [0, 0];
                    total = total.add(quantity);
                }
            }
        }

        // require amount to stake > 0, else we emit events and update the state
        require(total > 0, 'No vesting entries to bridge');

        totalEscrowedBalance = totalEscrowedBalance.sub(total);
        totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
        totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);

        // Approve DOUGH to Timelock (we need to approve)
        dough.safeApprove(address(sharesTimeLock), 0);
        dough.safeApprove(address(sharesTimeLock), total);

        // Deposit to timelock
        sharesTimeLock.depositByMonths(total, STAKE_DURATION, msg.sender);

        emit MigratedToVeDOUGH(msg.sender, now, total);
        emit Transfer(msg.sender, address(0), total);
    }
    

    /**
     * @notice eDOUGH that has been vesting for less than 6 months can be sold back to the DAO at a fixed price
     * @dev as part of setup, ensure approve has been called with the address of the vesting contract
     */
    function eDoughBuyback()
    external
    {
        require(address(buyback) != address(0), "Buyback contract not set");

        (uint total, uint lastFulfillableVestingEntry) = getAvailableForBuyBack(msg.sender);
        require(total > 0, 'Nothing available for buyback');

        // for all entries we can completely fulfil, zero them out
        for (uint i = 0; i <= lastFulfillableVestingEntry; i++) {
            vestingSchedules[msg.sender][i] = [0, 0];
        }

        totalEscrowedBalance = totalEscrowedBalance.sub(total);
        totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
        totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);

        // buyback will execute transfers - will throw if price has expired
        bool success = buyback.buyback(total, msg.sender);
        require(success, "Buyback failed");

        emit Buyback(msg.sender, block.timestamp, total);
        emit Transfer(msg.sender, address(buyback), total);
    }

    function eDoughBurn()
    external
    {
        require(burnEnabled, "Burn disabled");
        // we can just burn the entire user balance
        uint userBalance = balanceOf(msg.sender);
        require(userBalance > 0, 'Nothing to burn');

        // get the user's vesting entries and zero them out
        uint numEntries = numVestingEntries(msg.sender); 
        for (uint i = 0; i < numEntries; i++) {
            // user is burning everything once, so just zero their entire schedule
            if (vestingSchedules[msg.sender][i][0] != 0) {
                vestingSchedules[msg.sender][i] = [0, 0];
            }
        }

        // sub off the escrow but don't increment state variables (we resolve off-chain)
        totalEscrowedBalance = totalEscrowedBalance.sub(userBalance);
        totalEscrowedAccountBalance[msg.sender] = 0;

        // burn corresponding DOUGH
        dough.safeTransfer(BURN_ADDRESS, userBalance);

        emit Burned(msg.sender, userBalance);
        emit Transfer(msg.sender, BURN_ADDRESS, userBalance);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRewardsContract() {
        require(isRewardContract[msg.sender], "Only reward contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event DoughUpdated(address newDough);

    event TimelockUpdated(address newTimelock);

    event Vested(address indexed beneficiary, uint time, uint value);

    event MigratedToVeDOUGH(address indexed beneficiary, uint time, uint value);

    event VestingEntryCreated(address indexed beneficiary, uint time, uint value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event RewardContractAdded(address indexed rewardContract);

    event RewardContractRemoved(address indexed rewardContract);

    event BuybackContractUpdated(address newBuyback);

    event Buyback(address indexed beneficiary, uint time, uint value);

    event Burned(address indexed from, uint value);

    event BurnEnabledUpdated(bool enabled);
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
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
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}