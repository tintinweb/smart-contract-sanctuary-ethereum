// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity = 0.8.12;

// Inheritance
import "./Ownable.sol";
import "./interfaces/IERC20.sol";

// Based on https://docs.synthetix.io/contracts/SynthetixEscrow
contract Escrow is Ownable {

    /* The escrow token. */
    address public token;

    mapping(address => uint) private allAccounts;
    mapping(uint => address) private accountMapperCounter;
    uint public accountsCount;

    /* An account's total vested balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalVestedAccountBalance;

    //amount per distribution user
    mapping(address => uint) public singleDistributionAmount;

    mapping(uint => uint) public vestingSchedules;
    mapping(uint => uint) private leftVestingSchedules;
    uint private countSchedules;

    /* The total remaining vested balance, for verifying the actual balance of this contract against. */
    uint public totalVestedBalance;
    uint public constant TIME_INDEX = 0;
    uint public constant QUANTITY_INDEX = 1;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _token, uint[] memory _times) {
        token = _token;

        for (uint i = 0; i < _times.length; i++) {
            require(block.timestamp < _times[i], 'Time in past');
            vestingSchedules[i] = _times[i];
            leftVestingSchedules[i] = _times[i];
        }
        countSchedules = _times.length;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) public view returns (uint) {
        return totalVestedAccountBalance[account];
    }

    function getNextVestingTime() external view returns (uint) {
        return leftVestingSchedules[0];
    }

    function getSingleDistributionAmount(address account) external view returns (uint) {
        return singleDistributionAmount[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Destroy the vesting information associated with an account.
     */
    function purgeAccount(address account) external onlyOwner {
        uint indexAccount = allAccounts[account];
        delete allAccounts[account];
        delete accountMapperCounter[indexAccount];
        totalVestedBalance = totalVestedBalance - totalVestedAccountBalance[account];
        delete singleDistributionAmount[account];
        delete totalVestedAccountBalance[account];
        accountsCount--;
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should be accompanied by either enough balance already available
     * in this contract, or a corresponding call to.endow(), to ensure that when
     * the funds are withdrawn, there is enough balance, as well as correctly calculating
     * the fees.
     * This may only be called by the owner during the contract's setup period.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only in the foundation's command to add to these lists.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of SNX that will vest.
     */
    function appendVestingEntry (
        address account,
        uint quantity
    ) public onlyOwner {

        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalVestedBalance = totalVestedBalance + quantity;
        require(
            totalVestedBalance <= IERC20(token).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        totalVestedAccountBalance[account] = quantity;

        uint percentDistributionPerMonth = 20;
        uint amountDistribution = (quantity / 100) * percentDistributionPerMonth;
        singleDistributionAmount[account] = amountDistribution;
        accountsCount++;
        allAccounts[account] = accountsCount;
        accountMapperCounter[accountsCount] = account;
    }

    /**
     * @notice Construct a vesting schedule to release a quantities of SNX
     * over a series of intervals.
     * @dev Assumes that the quantities are nonzero
     * and that the sequence of timestamps is strictly increasing.
     * This may only be called by the owner during the contract's setup period.
     */
    function addVestingEntry(
        address[] calldata account,
        uint[] memory quantities
    ) external onlyOwner {
        require(account.length == quantities.length, 'Not the same count of elements');

        for (uint i = 0; i < account.length; i++) {
            appendVestingEntry(account[i], quantities[i]);
        }
    }

    function vest() external onlyOwner {

        for(uint i= 0; i < accountsCount; i++){
            
            if (block.timestamp < leftVestingSchedules[i]) {
                break;
            }

            for(uint j = 1; i <= accountsCount; j++) { 
                address account = accountMapperCounter[j];
                uint amount = allAccounts[account];
                require(IERC20(token).transfer(msg.sender, amount));
                totalVestedBalance = totalVestedBalance - amount;
                emit Vested(account, block.timestamp, amount);
            }
            delete leftVestingSchedules[i];
        }
    }
    

    /* ========== EVENTS ========== */

    event Vested(address indexed beneficiary, uint time, uint value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.12;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}