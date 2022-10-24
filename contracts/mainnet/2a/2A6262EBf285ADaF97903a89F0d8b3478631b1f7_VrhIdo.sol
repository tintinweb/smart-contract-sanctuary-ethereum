// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "SafeMath.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    //function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function burn(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface USDT {
    function decimals() external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

struct LockedBalance{
    int128 amount;
    uint256 end;
}

interface VotingEscrow {
    function create_lock_for(address _for, uint256 _value, uint256 _unlock_time) external;
    function deposit_for(address _addr, uint256 _value) external;
    function locked(address arg0) external returns(LockedBalance memory);
}

contract VrhIdo is Ownable {
    using SafeMath for uint256;


    event Purchase(address indexed buyer,uint256 indexed round, uint256 paymentAmount, uint256 vrhAmount, uint256 lockedVrhAmount, uint256 lockedEnd, uint256 ratio);

    struct IdoRound{
        uint256 startTime;
        uint256 endTime;
        uint256 idoRoundSupply;
        uint256 ratio;// for example: usdt 10**6 can buy token 5x(10**18)  then ratio = 5x(10**18)
        uint256 salesVolume;
        uint256 burnVolume;
    }

    IdoRound[] private idoRoundList;
    uint256 private MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private YEAR = 86400 * 365;
    uint256 private WEEK = 7 * 86400;

    address public vrhTokenAddress;
    address public quoteTokenAddress;
    address public votingEscrowAddress;
    address public fundAddress;

    uint256 public lockedVrhRatio;

    uint256 public quoteTokenDecimals;


    constructor(address _vrhTokenAddress, address _quoteTokenAddress, address _votingEscrowAddress, address _fundAddress, uint256 _lockedVrhRatio) {

        vrhTokenAddress = _vrhTokenAddress;
        quoteTokenAddress = _quoteTokenAddress;
        votingEscrowAddress = _votingEscrowAddress;
        fundAddress = _fundAddress;

        lockedVrhRatio = _lockedVrhRatio;

        if(_quoteTokenAddress == address(0)){
            quoteTokenDecimals = 18;
        }else{
            quoteTokenDecimals = USDT(quoteTokenAddress).decimals();
        }

        IERC20(vrhTokenAddress).approve(votingEscrowAddress, MAX_INT);
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        require(_fundAddress != address(0));
        fundAddress = _fundAddress;
    }

    function addIdoRound(uint256 _startTime, uint256 _endTime, uint256 _idoRoundSupply, uint256 _ratio) external onlyOwner {

        require(_startTime > block.timestamp, "startTime error");
        require(_endTime > _startTime, "endTime error");
        require(_idoRoundSupply > 0, "idoRoundSupply error");
        require(_ratio > 0, "ratio error");

        if(idoRoundList.length > 0){
            IdoRound memory lastIdoRound = idoRoundList[idoRoundList.length - 1];
            require(_startTime >= lastIdoRound.endTime, "startTime error");
        }

        IdoRound memory idoRound = IdoRound(_startTime, _endTime, _idoRoundSupply, _ratio, 0, 0);

        idoRoundList.push(idoRound);

    }

    function burn(uint256 index) external onlyOwner {

        IdoRound memory idoRound = idoRoundList[index];

        require(idoRound.idoRoundSupply > 0, "index error");
        require(idoRound.burnVolume == 0, "already burned");
        require(idoRound.idoRoundSupply > idoRound.salesVolume, "nothing to burn");
        require(block.timestamp > idoRound.endTime, "idoRound ongoing");

        uint256 burnVolume = idoRound.idoRoundSupply.sub(idoRound.salesVolume);

        IERC20(vrhTokenAddress).burn(burnVolume);

        idoRoundList[index].burnVolume = burnVolume;

    }



    function purchase(uint256 amount, uint256 yearCount) external payable {

        require(amount > 0, "amount error");
        require(idoRoundList.length > 0, "no idoRound");
        require(yearCount > 0 && yearCount <= 4, "yearCount error");

        uint256 index = MAX_INT;
        for(uint256 i=0;i<idoRoundList.length;i++){
            if(block.timestamp >= idoRoundList[i].startTime && block.timestamp < idoRoundList[i].endTime){
                index = i;
                break;
            }
        }
        require(index < MAX_INT, "no active idoRound");

        IdoRound memory idoRound = idoRoundList[index];

        uint256 totalVrhAmount ;

        if(quoteTokenAddress == address(0)){
            require(msg.value == amount, "amount error");

            totalVrhAmount = amount.mul(idoRound.ratio).div(10**18);

            payable(fundAddress).transfer(msg.value);
        }else{
            //require(msg.value == 0, "return eth");
            USDT(quoteTokenAddress).transferFrom(msg.sender, fundAddress, amount);

            totalVrhAmount = amount.mul(idoRound.ratio).div(10**quoteTokenDecimals);
        }

        require(idoRound.idoRoundSupply.sub(idoRound.salesVolume) >= totalVrhAmount, "vrh insufficient");

        uint256 lockedVrhAmount = totalVrhAmount.mul(lockedVrhRatio).div(10000);
        uint256 vrhAmount = totalVrhAmount.sub(lockedVrhAmount);


        IERC20(vrhTokenAddress).transfer(msg.sender, vrhAmount);

        uint256 end;

        LockedBalance memory lockedBalance = VotingEscrow(votingEscrowAddress).locked(msg.sender);

        if(lockedBalance.amount > 0){
            end = lockedBalance.end;
            VotingEscrow(votingEscrowAddress).deposit_for(msg.sender, lockedVrhAmount);
        }else{
            end = block.timestamp.add(yearCount.mul(YEAR)).div(WEEK).mul(WEEK);
            VotingEscrow(votingEscrowAddress).create_lock_for(msg.sender, lockedVrhAmount, end);
        }

        idoRoundList[index].salesVolume += totalVrhAmount;

        emit Purchase(msg.sender, index, amount, vrhAmount, lockedVrhAmount, end, idoRound.ratio);
    }

    function withdrawToken(address token, address to) external onlyOwner{
        IERC20 iERC20 = IERC20(token);
        uint256 balance = iERC20.balanceOf(address(this));
        require(balance > 0, "token insufficient");
        iERC20.transfer(to==address(0)?msg.sender:to, balance);
    }

    function withdraw(address to) external onlyOwner{
        uint256 balance = address(this).balance;
        payable(to==address(0)?msg.sender:to).transfer(balance);
    }

    function getIdoRound(uint256 index) public view returns (IdoRound memory){
        IdoRound memory idoRound;
        if(index < idoRoundList.length){
            return idoRoundList[index];
        }
        return idoRound;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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