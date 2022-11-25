/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT

    /*                                                   
 ____          ____       _______________     _______________      ______         ____                          
|    \        /    |     |               |   |               |    |      \       |    |    
:     \      /     |     |   _________   |   |   _________   |    |       \      |    |       
:      \    /      |     |  |         |  |   |  |         |  |    |        \     |    |                  
|       \  /       |     |  |         |  |   |  |         |  |    |    |\   \    |    |             
|   |\   \/   /|   |     |  |         |  |   |  |         |  |    |    | \   \   |    |                 
'   : \      / |   |     |  |         |  |   |  |         |  |    |    |  \   \  |    |                     
|   |  \____/  |   |     |  |         |  |   |  |         |  |    |    |   \   \ |    |                     
|   :          |   |     |  |_________|  |   |  |_________|  |    |    |    \   \|    |                     
|   |          |   |     |               |   |               |    |    |     \        |                     
|___|          |___|     |_______________|   |_______________|    |____|      \_______|                                

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
            // Gas optimization: this is cheDMINERr than requiring 'a' not being zero, but the
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
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

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
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

contract MoonMines is Context, Ownable {
    using SafeMath for uint256;

    uint256 private Minerals_TO_Hire_1DMINER = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 6;
    bool private initialized = false;
    address payable private recAdd;
    mapping (address => uint256) private Factory;
    mapping (address => uint256) private claimedMinerals;
    mapping (address => uint256) private lastHire;
    mapping (address => address) private referrals;
    uint256 private marketMinerals;
    
    constructor() {
        recAdd = payable(msg.sender);
    }
    
    function ContributeToTVL () public payable {

    }

    function HireDMiners(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 MineralsUsed = getMyMinerals(msg.sender);
        uint256 newDMINER = SafeMath.div(MineralsUsed,Minerals_TO_Hire_1DMINER);
        Factory[msg.sender] = SafeMath.add(Factory[msg.sender],newDMINER);
        claimedMinerals[msg.sender] = 0;
        lastHire[msg.sender] = block.timestamp;
        
        //send referral Minerals
        claimedMinerals[referrals[msg.sender]] = SafeMath.add(claimedMinerals[referrals[msg.sender]],SafeMath.div(MineralsUsed,8));
        
        //boost market to nerf DMINER hoarding
        marketMinerals=SafeMath.add(marketMinerals,SafeMath.div(MineralsUsed,5));
    }
    
    function SellMinerals() public {
        require(initialized);
        uint256 hasMinerals = getMyMinerals(msg.sender);
        uint256 MineralsValue = calculateMineralSell(hasMinerals);
        uint256 fee = devFee(MineralsValue);
        claimedMinerals[msg.sender] = 0;
        lastHire[msg.sender] = block.timestamp;
        marketMinerals = SafeMath.add(marketMinerals,hasMinerals);
        recAdd.transfer(fee);
        payable (msg.sender).transfer(SafeMath.sub(MineralsValue,fee));
    }
    
    function MineralRewards(address adr) public view returns(uint256) {
        uint256 hasMinerals = getMyMinerals(adr);
        uint256 MineralsValue = calculateMineralSell(hasMinerals);
        return MineralsValue;
    }
    
    function BuyDogeMiners(address ref) public payable {
        require(initialized);
        uint256 MineralsBought = calculateHireDMiners(msg.value,SafeMath.sub(address(this).balance,msg.value));
        MineralsBought = SafeMath.sub(MineralsBought,devFee(MineralsBought));
        uint256 fee = devFee(msg.value);
        recAdd.transfer(fee);
        claimedMinerals[msg.sender] = SafeMath.add(claimedMinerals[msg.sender],MineralsBought);
        HireDMiners(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateMineralSell(uint256 Minerals) public view returns(uint256) {
        return calculateTrade(Minerals,marketMinerals,address(this).balance);
    }
    
    function calculateHireDMiners(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketMinerals);
    }
    
    function calculateHireDMinersSimple(uint256 eth) public view returns(uint256) {
        return calculateHireDMiners(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketMinerals == 0);
        initialized = true;
        marketMinerals = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyDMINER(address adr) public view returns(uint256) {
        return Factory[adr];
    }
    
    function getMyMinerals(address adr) public view returns(uint256) {
        return SafeMath.add(claimedMinerals[adr],getMineralsSinceLastHire(adr));
    }
    
    function getMineralsSinceLastHire(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(Minerals_TO_Hire_1DMINER,SafeMath.sub(block.timestamp,lastHire[adr]));
        return SafeMath.mul(secondsPassed,Factory[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}