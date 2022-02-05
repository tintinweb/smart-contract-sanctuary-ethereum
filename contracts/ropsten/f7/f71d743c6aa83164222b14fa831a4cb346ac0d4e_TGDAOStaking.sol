/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

/**
 * @dev Allows the owner to retrieve ETH or tokens sent to this contract by mistake.
 */
contract RecoverableFunds is Ownable {

    function retrieveTokens(address recipient, address tokenAddress) public virtual onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    function retriveETH(address payable recipient) public virtual onlyOwner {
        recipient.transfer(address(this).balance);
    }

}

/**
 * @dev TGDAO Staking
 */
contract TGDAOStaking is RecoverableFunds {

    using SafeMath for uint256;

    uint public PERCENT_DIVIDER = 100;

    struct StakeType {
        bool active;
        uint periodInDays;
        uint apy;
        uint finesPeriodsCount;
        mapping(uint => uint) fineDays;
        mapping(uint => uint) fines;
    }

    struct Staker {
        bool exists;
        mapping(uint => bool) closed;
        mapping(uint => uint) amount;
        mapping(uint => uint) amountAfter;
        mapping(uint => uint) stakeType;
        mapping(uint => uint) start;
        mapping(uint => uint) finished;
        uint count;
        uint summerDeposit;
        uint summerAfter;
    }

    uint public countOfStakeTypes;

    StakeType[] public stakeTypes;

    mapping(address => Staker) public stakers;

    address[] public stakersAddresses;

    uint public stakersAddressesCount;

    IERC20 public token;

    bool public firstConfigured;

    event Deposit(address account, uint amount, uint stakingTypeIndex, uint stakeIndex);

    event Withdraw(address account, uint amount, uint stakingTypeIndex, uint stakeIndex);

    function configure(address tokenAddress) public onlyOwner {
        require(!firstConfigured, "Already configured");

        uint[] memory fineDays = new uint[](3);
        uint[] memory fines = new uint[](3);

        // 1st
        fineDays[0] = 30;
        fineDays[1] = 60;
        fineDays[2] = 90;

        fines[0] = 30;
        fines[1] = 25;
        fines[2] = 20;

        addStakeTypeWithFines(3 * 30, 7, fines, fineDays);

        // 2nd
        fineDays[0] = 60;
        fineDays[1] = 120;
        fineDays[2] = 180;

        fines[0] = 30;
        fines[1] = 25;
        fines[2] = 20;

        addStakeTypeWithFines(6 * 30, 14, fines, fineDays);


        // 3d
        fineDays[0] = 120;
        fineDays[1] = 240;
        fineDays[2] = 360;

        fines[0] = 30;
        fines[1] = 25;
        fines[2] = 20;

        addStakeTypeWithFines(12 * 30, 21, fines, fineDays);
        token = IERC20(tokenAddress);

        firstConfigured = true;
    }

    function addStakeTypeWithFines(uint periodInDays, uint apy, uint[] memory fines, uint[] memory fineDays) public onlyOwner {
        uint stakeTypeIndex = addStakeType(periodInDays, apy);
        setStakeTypeFines(stakeTypeIndex, fines, fineDays);
    }


    function setStakeTypeFines(uint stakeTypeIndex, uint[] memory fines, uint[] memory fineDays) public onlyOwner {
        require(stakeTypeIndex < countOfStakeTypes, "Wrong stake type index");
        require(fines.length > 0, "Fines array length must be greater than 0");
        require(fines.length == fineDays.length, "Fines and fine days arrays must be equals");
        StakeType storage stakeType = stakeTypes[stakeTypeIndex];
        stakeType.finesPeriodsCount = fines.length;
        for (uint i = 0; i < fines.length; i++) {
            require(fines[i] <= 1000, "Fines can't be more than 1000");
            stakeType.fines[i] = fines[i];
            require(fineDays[i] <= 100000, "Fine days can't be more than 10000");
            stakeType.fineDays[i] = fineDays[i];
        }
    }

    function changeStakeType(uint stakeTypeIndex, bool active, uint periodInDays, uint apy) public onlyOwner {
        require(stakeTypeIndex < countOfStakeTypes, "Wrong stake type index");
        require(apy < 1000, "Apy can't be grater than 1000");
        require(periodInDays < 100000, "Apy can't be grater than 100000");
        StakeType storage stakeType = stakeTypes[stakeTypeIndex];
        stakeType.active = active;
        stakeType.periodInDays = periodInDays;
        stakeType.apy = apy;
    }

    function addStakeType(uint periodInDays, uint apy) public onlyOwner returns (uint) {
        stakeTypes.push();
        StakeType storage stakeType = stakeTypes[countOfStakeTypes++];
        stakeType.active = true;
        stakeType.periodInDays = periodInDays;
        stakeType.apy = apy;
        return countOfStakeTypes - 1;
    }

    function setToken(address tokenAddress) public onlyOwner {
        token = IERC20(tokenAddress);
    }

    function deposit(uint8 stakeTypeIndex, uint256 amount) public returns (uint) {
        require(stakeTypeIndex < countOfStakeTypes, "Wrong stake type index");
        StakeType storage stakeType = stakeTypes[stakeTypeIndex];
        require(stakeType.active, "Stake type not active");

        Staker storage staker = stakers[_msgSender()];
        if (!staker.exists) {
            staker.exists = true;
            stakersAddresses.push(_msgSender());
            stakersAddressesCount++;
        }

        token.transferFrom(_msgSender(), address(this), amount);

        staker.closed[staker.count] = false;
        staker.amount[staker.count] = amount;
        staker.start[staker.count] = block.timestamp;
        staker.stakeType[staker.count] = stakeTypeIndex;
        staker.count += 1;
        staker.summerDeposit += amount;

        emit Deposit(_msgSender(), amount, stakeTypeIndex, staker.count - 1);

        return staker.count;
    }

    function calculateWithdrawValue(address stakerAddress, uint stakeIndex) public view returns (uint) {
        Staker storage staker = stakers[stakerAddress];
        require(staker.exists, "Staker not registered");
        require(!staker.closed[stakeIndex], "Stake already closed");

        uint stakeTypeIndex = staker.stakeType[stakeIndex];
        StakeType storage stakeType = stakeTypes[staker.stakeType[stakeTypeIndex]];
        require(stakeType.active, "Stake type not active");

        uint startTimestamp = staker.start[stakeIndex];
        if (block.timestamp >= startTimestamp + stakeType.periodInDays * (1 days)) {
            // Rewards calculation
            return staker.amount[stakeIndex]  + staker.amount[stakeIndex]* stakeType.periodInDays * stakeType.apy / (365 * PERCENT_DIVIDER);
        } else {
            uint stakePeriodIndex = stakeType.finesPeriodsCount - 1;
            for (uint i = stakeType.finesPeriodsCount; i > 0; i--) {
                if (block.timestamp < startTimestamp + stakeType.fineDays[i - 1] * (1 days)) {
                    stakePeriodIndex = i - 1;
                }
            }
            // Fines calculation
            return staker.amount[stakeIndex].mul(PERCENT_DIVIDER - stakeType.fines[stakePeriodIndex]).div(PERCENT_DIVIDER);
        }
    }

    function withdraw(uint8 stakeIndex) public {
        Staker storage staker = stakers[_msgSender()];
        staker.amountAfter[stakeIndex] = calculateWithdrawValue(_msgSender(), stakeIndex);

        require(token.balanceOf(address(this)) >= staker.amountAfter[stakeIndex], "Staking contract does not have enough funds! Owner should deposit funds...");

        staker.summerAfter = staker.summerAfter.add(staker.amountAfter[stakeIndex]);
        staker.finished[stakeIndex] = block.timestamp;
        staker.closed[stakeIndex] = true;

        require(token.transfer(_msgSender(), staker.amountAfter[stakeIndex]), "Can't transfer reward");
        uint stakeTypeIndex = staker.stakeType[stakeIndex];

        emit Withdraw(_msgSender(), staker.amountAfter[stakeIndex], stakeTypeIndex, stakeIndex);
    }

    function withdrawAll(address to) public onlyOwner {
        token.transfer(to, token.balanceOf(address(this)));
    }

    function getStakeTypeFinePeriodAndFine(uint8 stakeTypeIndex, uint periodIndex) public view returns (uint, uint) {
        require(stakeTypeIndex < countOfStakeTypes, "Wrong stake type index");
        StakeType storage stakeType = stakeTypes[stakeTypeIndex];
        //require(stakeType.active, "Stake type not active");
        require(periodIndex < stakeType.finesPeriodsCount, "Requetsed period idnex greater than max period index");
        return (stakeType.fineDays[periodIndex], stakeType.fines[periodIndex]);
    }

    modifier stakerStakeChecks(address stakerAddress, uint stakeIndex) {
        Staker storage staker = stakers[stakerAddress];
        require(staker.exists, "Staker not registered");
        require(stakeIndex < staker.count, "Wrong stake index");
        _;
    }

    function getStakerStakeParams(address stakerAddress, uint stakeIndex) public view stakerStakeChecks(stakerAddress, stakeIndex)
    returns (bool closed, uint amount, uint amountAfter, uint stakeType, uint start, uint finished) {
        Staker storage staker = stakers[stakerAddress];

        uint[] memory uintValues = new uint[](5);
        uintValues[0] = staker.amount[stakeIndex];
        uintValues[1] = staker.amountAfter[stakeIndex];
        uintValues[2] = staker.stakeType[stakeIndex];
        uintValues[3] = staker.start[stakeIndex];
        uintValues[4] = staker.finished[stakeIndex];

        return (staker.closed[stakeIndex], uintValues[0], uintValues[1], uintValues[2], uintValues[3], uintValues[4]);
    }

}