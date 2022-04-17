/**
 *Submitted for verification at BscScan.com on 2022-04-11
*/

// SPDX-License-Identifier: MIT

/*
Golden Nugget - BSC BNB Miner
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
// pragma solidity 0.5.17;

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

contract GoldenNugget is Context, Ownable {
    event SetRange(uint256 indexed fromNumber, uint256 indexed toNumber);

    using SafeMath for uint256;

    uint256 private Gold_To_Mine = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 3;
    uint256 private bonusFeeVal = 1;
    uint256 private internalPool;
    uint256 private reinvestmentCount = 0;
    uint256 private randomNumber = 0;
    uint256 private startNumber = 0;
    uint256 private endNumber = 0;
    bool private initialized = false;
    bool private setRndNum = false;
    address payable private recAdd;
    mapping (address => uint256) private Working_Miners;
    mapping (address => uint256) private claimedGold;
    mapping (address => uint256) private lastMined;
    mapping (address => address) private referrals;
    uint256 private marketGold;
    
    constructor() {
        recAdd = payable(msg.sender);
    }
    
    function BuryGold(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 GoldUsed = getMyGold(msg.sender);
        uint256 newMiners = SafeMath.div(GoldUsed,Gold_To_Mine);
        Working_Miners[msg.sender] = SafeMath.add(Working_Miners[msg.sender],newMiners);
        claimedGold[msg.sender] = 0;
        lastMined[msg.sender] = block.timestamp;
        
        //send referral Gold
        claimedGold[referrals[msg.sender]] = SafeMath.add(claimedGold[referrals[msg.sender]],SafeMath.div(GoldUsed,8));
        
        //boost market to nerf miners hoarding
        marketGold=SafeMath.add(marketGold,SafeMath.div(GoldUsed,5));
    }
    
    function sellGold() public {
        require(initialized);
        uint256 hasGold = getMyGold(msg.sender);
        uint256 eggValue = calculateGoldsell(hasGold);
        uint256 fee = devFee(eggValue);
        claimedGold[msg.sender] = 0;
        lastMined[msg.sender] = block.timestamp;
        marketGold = SafeMath.add(marketGold,hasGold);
        recAdd.transfer(fee);
        internalPool = SafeMath.add(internalPool, bonusFee(eggValue));
        payable (msg.sender).transfer(SafeMath.sub(SafeMath.sub(eggValue,fee), bonusFee(eggValue)));
    }
    
    function NuggetRewards(address adr) public view returns(uint256) {
        uint256 hasGold = getMyGold(adr);
        uint256 eggValue = calculateGoldsell(hasGold);
        return eggValue;
    }
    
    function buyGold(address ref) public payable {
        require(initialized);
        uint256 GoldBought = calculateGoldBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        GoldBought = SafeMath.sub(SafeMath.sub(GoldBought, devFee(GoldBought)), bonusFee(GoldBought));
        uint256 fee = devFee(msg.value);
        recAdd.transfer(fee);
        internalPool = SafeMath.add(internalPool, bonusFee(msg.value));
        claimedGold[msg.sender] = SafeMath.add(claimedGold[msg.sender],GoldBought);
        if(setRndNum)
            reinvestmentCount = SafeMath.add(reinvestmentCount, 1);
        if(randomNumber == reinvestmentCount) {
            claimedGold[msg.sender] = SafeMath.add(claimedGold[msg.sender], internalPool);
            internalPool = 0;
            reinvestmentCount = 0;
            setRndNum = false;
        }
        BuryGold(ref);
    }

    function setNumberRange(uint256 _sNumber, uint256 _eNumber) public onlyOwner {
        require(initialized);
        startNumber = _sNumber;
        endNumber = _eNumber;
        setRndNum = true;
        randomNumber = requestRandomNumber(_sNumber, _eNumber);
        emit SetRange(_sNumber, _eNumber);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateGoldsell(uint256 Gold) public view returns(uint256) {
        return calculateTrade(Gold,marketGold,address(this).balance);
    }
    
    function calculateGoldBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketGold);
    }
    
    function calculateGoldBuySimple(uint256 eth) public view returns(uint256) {
        return calculateGoldBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function bonusFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,bonusFeeVal),100);
    }

    function seedMarket() public payable onlyOwner {
        require(marketGold == 0);
        initialized = true;
        marketGold = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return Working_Miners[adr];
    }
    
    function getMyGold(address adr) public view returns(uint256) {
        return SafeMath.add(claimedGold[adr],getGoldSinceLastBury(adr));
    }
    
    function getGoldSinceLastBury(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(Gold_To_Mine,SafeMath.sub(block.timestamp,lastMined[adr]));
        return SafeMath.mul(secondsPassed,Working_Miners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function requestRandomNumber(uint256 _startNumber, uint256 _endNumber) public view returns(uint256) {
        return SafeMath.add(SafeMath.mod(uint256(keccak256(abi.encode(blockhash(block.timestamp), _startNumber, _endNumber))), SafeMath.sub(_endNumber, _startNumber)), _startNumber);
    }
}