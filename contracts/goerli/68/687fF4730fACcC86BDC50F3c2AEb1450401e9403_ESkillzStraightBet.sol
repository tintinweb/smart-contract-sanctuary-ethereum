//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
interface ISport {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function mintMore(address _toAddress, uint256 amount) external returns (bool);
}

contract ESkillzStraightBet is Ownable {
    using SafeMath for uint256;
    uint256 public GameIDs;
    uint256 public minBetAmounts;
    address public sport;
    struct Bet {
        address player;
        uint256 amount;
        uint256 gameType; // sp 0, mp 1
    }
    
    mapping(uint256 => Bet[]) public gamebetting;
    //mapping(address => uint256) public staking;
    mapping(uint256 => uint256) public totalAmountsOfDay;
    uint256 public eskillz_fee;
    address public feeReceiver;
    uint256 startTimeStamp;
    event BetEvent(uint256 _game, uint256 _amount);

    modifier onlySportContract {
      require(msg.sender == sport);
      _;
    }

    constructor (address _sport) { 
        sport = _sport;  
        eskillz_fee = 500; 
        feeReceiver = 0x099b7b28AC913efbb3236946769AC6D3819329ab;
        ISport(sport).approve(feeReceiver, 1000000000000000000);  
        minBetAmounts = 1000000000;
        startTimeStamp = block.timestamp;    
    }
   
    function  SetGameIDToZero() external onlyOwner{

      GameIDs = 0;

    }

    function  SetMinBetAmounts(uint256 _amounts) external onlyOwner{

      minBetAmounts = _amounts;

    }
  
    function  CreateSPGame(address _sender, uint256 amount) external onlySportContract{
      require(minBetAmounts<= amount, "Bet amounts must be bigger than minBetAmounts");
      totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] +=amount;
      GameIDs++;
      ISport(sport).transferFrom(_sender, address(this), amount);
      delete(gamebetting[GameIDs]);
      gamebetting[GameIDs].push(Bet(_sender, amount, 0));
      emit BetEvent(GameIDs, amount);
    }
    
    function SetSPGameResult(uint256 GameID, uint256 result) external {
        
        (uint256 amountToWinner,uint256 amountToESkillz) = getAmountsSPGameToDistribute(GameID);
        require(gamebetting[GameID][0].player == msg.sender, "Other Players can not access.");
        require(gamebetting[GameID][0].gameType == 0, "You can set the SP game only");
        require(ISport(sport).balanceOf(address(this)) >= gamebetting[GameID][0].amount, "Dport Balance of Bet contract is not enough.");
        ISport(sport).mintMore(msg.sender, gamebetting[GameID][0].amount*result/100);
        ISport(sport).transfer(msg.sender, amountToWinner);
        ISport(sport).transfer(feeReceiver, amountToESkillz);
        if(totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] >= (gamebetting[GameID][0].amount)){

            totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] -=(gamebetting[GameID][0].amount);
        }
        else{
            if((block.timestamp- startTimeStamp)/ 1 days > 0){

                totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days - 1] -=(gamebetting[GameID][0].amount);
            }
        }
        delete(gamebetting[GameID]);
    }

    function  CreateMPGame(address _sender, uint256 amount) external onlySportContract{
      require(minBetAmounts<= amount, "Bet amounts must be bigger than minBetAmounts");
      totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] += amount;
      GameIDs++;
      ISport(sport).transferFrom(_sender, address(this), amount);
      delete(gamebetting[GameIDs]);
      gamebetting[GameIDs].push(Bet(_sender, amount, 1));
      emit BetEvent(GameIDs, amount);
    }

    function  JoinMPGame(address _sender, uint256 gameID, uint256 amount) external onlySportContract{
      require(gamebetting[gameID].length == 1, "Players can not join.");
      require(gamebetting[gameID][0].player != _sender, "Same Players can not join.");
      require(amount== gamebetting[gameID][0].amount, "Your bet amount must equals create amount");
      require(gamebetting[gameID][0].gameType == 1, "You can join the MP game only");
      totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] += amount;
      ISport(sport).transferFrom(_sender, address(this), amount);
      gamebetting[gameID].push(Bet(_sender, amount, 1));
      emit BetEvent(gameID, amount);
    }

    function SetMPGameResult(uint256 GameID) external {
        (uint256 amountToWinner,uint256 amountToESkillz) = getAmountsMPGameToDistribute(GameID);
        require(gamebetting[GameID][0].gameType == 1 && gamebetting[GameID][1].gameType == 1, "You can set the MP game only");
        require(msg.sender == gamebetting[GameID][0].player || msg.sender == gamebetting[GameID][1].player, "msg sender must includes in this game");
        require(ISport(sport).balanceOf(address(this)) >= gamebetting[GameID][0].amount *2, "Dport Balance of Bet contract is not enough.");

        if(msg.sender == gamebetting[GameID][0].player) {
            ISport(sport).transfer(gamebetting[GameID][0].player, amountToWinner);
           
        } else {
            ISport(sport).transfer(gamebetting[GameID][1].player, amountToWinner);
            
        }  
        ISport(sport).transfer(feeReceiver, amountToESkillz);
        if(totalAmountsOfDay[(block.timestamp - startTimeStamp) / 1 days] >= (amountToWinner + amountToESkillz)){

            totalAmountsOfDay[(block.timestamp - startTimeStamp) / 1 days] -=(amountToWinner + amountToESkillz);
        }
        else{
            if((block.timestamp - startTimeStamp)/ 1 days > 0){

                totalAmountsOfDay[(block.timestamp - startTimeStamp) / 1 days - 1] -=(amountToWinner + amountToESkillz);
            }
        }    
        delete(gamebetting[GameID]);
    }

    function getAmountsSPGameToDistribute(uint256 game) private view returns (uint256, uint256) {
        uint256 amountToESkillz = gamebetting[game][0].amount*eskillz_fee/10000;
        uint256 amountToWinner = gamebetting[game][0].amount - amountToESkillz;
        return(amountToWinner, amountToESkillz);
    }

    function getAmountsMPGameToDistribute(uint256 game) private view returns (uint256, uint256) {
        uint256 amountToESkillz = gamebetting[game][0].amount*eskillz_fee/10000;
        uint256 amountToWinner = 2 * gamebetting[game][0].amount - amountToESkillz;
        return(amountToWinner, amountToESkillz);
    }   

    function getPlayerLength(uint256 game) external view returns (uint256) {
        return gamebetting[game].length;
    }
    
    function setFeeReceiver(address _address) external onlyOwner {
        feeReceiver = _address;
        ISport(sport).approve(feeReceiver, 1000000000000000000);  
    }

    function setFee(uint256 _fee) external onlyOwner {
        eskillz_fee = _fee;
    }

    function setSportAddress(address _sport) external onlyOwner {
        sport = _sport;
    }

    function getAvailableAmountOfContract() external view returns(uint256){
        if((block.timestamp- startTimeStamp)/ 1 days > 0){
            return ISport(sport).balanceOf(address(this)) - totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] - totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days - 1];
        }
        else{
            return 0;
        }
    }

    function withdraw(uint256 _amount) external {
        require((block.timestamp- startTimeStamp)/ 1 days > 0 ,"withdraw day should be bigger than start day + 1 day.");
        uint256 remainAmounts = totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] + totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days - 1];
        require(ISport(sport).balanceOf(address(this)) - _amount > remainAmounts, "Balance must be bigger than amount + bettingAmounts of today and yesterday.");
        require(feeReceiver == msg.sender || owner() == msg.sender, "msg sender must be feeReceiver or contract owner");
        ISport(sport).transfer(feeReceiver, _amount);         
    }	

    function withdrawAll() external{

        require((block.timestamp- startTimeStamp)/ 1 days > 0 ,"withdraw day should be bigger than start day + 1 day.");
        uint256 remainAmounts = totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days] + totalAmountsOfDay[(block.timestamp- startTimeStamp)/ 1 days - 1];
        require(ISport(sport).balanceOf(address(this)) > remainAmounts, "Balance must be bigger than amount + bettingAmounts of today and yesterday.");
        require(feeReceiver == msg.sender || owner() == msg.sender, "msg sender must be feeReceiver or contract owner");
        ISport(sport).transfer(feeReceiver, ISport(sport).balanceOf(address(this)) - remainAmounts);      
    }
	
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