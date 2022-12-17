/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at BscScan.com on 2022-12-17
*/

pragma solidity 0.5.16;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
}

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract SuperMiner is Context, Ownable {
    uint256 public SECONDS_IN_A_DAY=86400;

    uint256 public MINIMAL_DEPOSIT_AMOUNT;
    uint256 public MAXIMUM_DEPOSIT_AMOUNT;
    uint public commissionPercent;
    uint public refCommissionPercent;
    uint public inlineBonusPercent;
    uint public farmingPercent;

    uint public firstLineReferralPercent = 10;
    uint public secondLineReferralPercent = 6;
    uint public thirdLineReferralPercent = 5;
    uint public fourthLineReferralPercent = 3;
    uint public fifthLineReferralPercent = 1;

    bool public initialized = false;

    address payable public ceoAddress;

    mapping (address => uint256) public deposits;
    mapping (address => uint256) public balances;
    mapping (address => uint) public claimDates;
    mapping (address => address) public parent;
    mapping (address => uint256) public countChildren;
    mapping (address => uint) public activateTime;


    constructor() public{
        ceoAddress = msg.sender;
        commissionPercent = 10;
        refCommissionPercent = 25;
        inlineBonusPercent = 5;
        farmingPercent = 15;
        MINIMAL_DEPOSIT_AMOUNT = 1 * (10 ** 16);
        MAXIMUM_DEPOSIT_AMOUNT = 5 * (10 ** 18);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function init() public onlyOwner {
        deposits[owner()] = 0;
        claimDates[owner()] = now;
        parent[owner()] = owner();
        balances[owner()] = 0;
        activateTime[owner()] = now;
        initialized = true;
    }

    function setCeoAddress(address newCeoAddress) public onlyOwner {
        require(newCeoAddress != address(0), "newCeoAddress: new ceo address is the zero address");
        ceoAddress = address(uint160(newCeoAddress));
    }

    function setCommissionPercent(uint newCommission) public onlyOwner {
        require(newCommission >= 0);
        require(newCommission <= 10, 'Commission should be less then or equal 10');
        commissionPercent = newCommission;
    }

    function setMaximumDepositAmount(uint256 amount) public onlyOwner {
        require(amount >= 0);
        MAXIMUM_DEPOSIT_AMOUNT = amount;
    }

    function getBalance(address user) public view returns (uint256) {
        return calculateBalance(user);
    }

    function calculateBalance(address user) private view returns (uint256) {
        if (deposits[user] == 0) {
            return balances[user];
        }
        return SafeMath.add(balances[user], SafeMath.mul(SafeMath.div(percentByUserDeposit(user), SECONDS_IN_A_DAY), countSeconds(user)));
    }

    function percentByUserDeposit(address user) private view returns(uint256) {
        return SafeMath.mul(SafeMath.div(deposits[user], 1000), farmingPercent);
    }

    function countSeconds(address user) private view returns (uint) {
        return SafeMath.sub(now, claimDates[user]);
    }

    function invest(address ref) public payable {
        require(initialized, "Invest: contract is not active");
        require(activateTime[ref] != 0, 'Invest: parent is not active');

        address user = msg.sender;
        uint256 amount = msg.value;

        require(amount >= MINIMAL_DEPOSIT_AMOUNT, 'Invest: error minimum amount');
        require(SafeMath.add(deposits[user], amount) <= MAXIMUM_DEPOSIT_AMOUNT, 'Invest: attempt to exceed the limit');

        uint256 referralAmount = getReferralCommission(amount);
        balances[user] = getBalance(user);
        deposits[user] = SafeMath.add(deposits[user], SafeMath.sub(amount, referralAmount));
        claimDates[user] = now;

        if (activateTime[user] == 0) {
            activateTime[user] = now;
        }

        if (user == owner()) {
            balances[owner()] = SafeMath.add(balances[owner()], referralAmount);
        } else {
            if (parent[user] == address(0)) {
                parent[user] = ref;
                countChildren[ref] = SafeMath.add(countChildren[ref], 1);
            }
            createReferralIncome(user, amount);
        }
    }

    function refill() public {
        address user = msg.sender;
        require(parent[user] != address(0), "Refill Action: Cant get user parent");

        uint256 amountToRefill = getBalance(user);
        uint256 referralCommission = getReferralCommission(amountToRefill);

        require(amountToRefill > MINIMAL_DEPOSIT_AMOUNT, 'Refill Action: error minimum amount');
        require(SafeMath.add(deposits[user], amountToRefill) <= MAXIMUM_DEPOSIT_AMOUNT, 'Refill Action: attempt to exceed the limit');

        claimDates[user] = now;
        balances[user] = 0;
        deposits[user] = SafeMath.add(deposits[user], SafeMath.sub(amountToRefill, referralCommission));
        createReferralIncome(user, amountToRefill);
    }

    function createReferralIncome(address user, uint256 amount) private {
        uint256 leftReferral = 0;
        uint256 userDepositReferralAmount = 0;
        uint256 depositReferralAmount = 0;
        //1 line
        address currentParent = parent[user];
        userDepositReferralAmount = getReferralAmount(amount, firstLineReferralPercent);
        depositReferralAmount = min(userDepositReferralAmount, getReferralAmount(deposits[currentParent], firstLineReferralPercent));
        leftReferral = SafeMath.add(leftReferral, depositReferralAmount);

        balances[currentParent] = SafeMath.add(balances[currentParent], depositReferralAmount);

        //2 line
        currentParent = parent[currentParent];
        userDepositReferralAmount = getReferralAmount(amount, secondLineReferralPercent);
        depositReferralAmount = min(userDepositReferralAmount, getReferralAmount(deposits[currentParent], secondLineReferralPercent));
        leftReferral = SafeMath.add(leftReferral, depositReferralAmount);

        balances[currentParent] = SafeMath.add(balances[currentParent], depositReferralAmount);

        //3 line
        currentParent = parent[currentParent];
        userDepositReferralAmount = getReferralAmount(amount, thirdLineReferralPercent);
        depositReferralAmount = min(userDepositReferralAmount, getReferralAmount(deposits[currentParent], thirdLineReferralPercent));
        leftReferral = SafeMath.add(leftReferral, depositReferralAmount);

        balances[currentParent] = SafeMath.add(balances[currentParent], depositReferralAmount);

        //4 line
        currentParent = parent[currentParent];
        userDepositReferralAmount = getReferralAmount(amount, fourthLineReferralPercent);
        depositReferralAmount = min(userDepositReferralAmount, getReferralAmount(deposits[currentParent], fourthLineReferralPercent));
        leftReferral = SafeMath.add(leftReferral, depositReferralAmount);

        balances[currentParent] = SafeMath.add(balances[currentParent], depositReferralAmount);

        //5 line
        currentParent = parent[currentParent];
        userDepositReferralAmount = getReferralAmount(amount, fifthLineReferralPercent);
        depositReferralAmount = min(userDepositReferralAmount, getReferralAmount(deposits[currentParent], fifthLineReferralPercent));
        leftReferral = SafeMath.add(leftReferral, depositReferralAmount);

        balances[currentParent] = SafeMath.add(balances[currentParent], depositReferralAmount);


        if (getReferralCommission(amount) > leftReferral) {
            balances[owner()] = SafeMath.add(balances[owner()], SafeMath.sub(getReferralCommission(amount), leftReferral));
        }
    }

    function withdraw() public {
        address user = msg.sender;

        uint256 amountOnContract = address(this).balance;

        uint256 amountToWithdraw = min(getBalance(user), amountOnContract);

        claimDates[user] = now;
        balances[user] = 0;

        ceoAddress.transfer(getCeoCommission(amountToWithdraw));
        msg.sender.transfer(SafeMath.sub(amountToWithdraw, getCeoCommission(amountToWithdraw)));
    }

    function withdrawDeposit() public {
        address user = msg.sender;
        uint256 amountOnContract = address(this).balance;

        uint256 momentumUserBalance = getBalance(user);
        uint256 userDeposit = deposits[user];

        balances[user] = momentumUserBalance;
        claimDates[user] = now;
        deposits[user] = 0;

        uint256 amountToWithdraw = min(userDeposit, amountOnContract);

        ceoAddress.transfer(getCeoCommission(amountToWithdraw));
        msg.sender.transfer(SafeMath.sub(amountToWithdraw, getCeoCommission(amountToWithdraw)));
    }

    function getReferralAmount(uint256 amount, uint256 percent) private pure returns(uint256) {
        return SafeMath.mul(SafeMath.div(amount, 100), percent);
    }

    function getReferralCommission(uint256 amount) private view returns(uint256) {
        return SafeMath.mul(SafeMath.div(amount, 100), refCommissionPercent);
    }

    function getCeoCommission(uint256 amount) private view returns(uint256) {
        return SafeMath.mul(SafeMath.div(amount, 100), commissionPercent);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}