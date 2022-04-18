/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: MIT

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

contract milkCow is Context, Ownable {
    using SafeMath for uint256;
    uint256 private INITIAL_MONEY = 0; // Initial amount of ETH, to avoid the first buyer get 100k beans.
    uint256 private MILK_TO_HATCH_1COW = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 4;
    uint256 private MarketingFeeVal = 2;
    bool private initialized = false;
    address payable private devAdd;
    address payable private MarAdd;
    mapping (address => uint256) private hatcheryCows;
    mapping (address => uint256) private claimedMilk;
    mapping (address => uint256) private lastHatch;
    mapping (address => address) private referrals;
    mapping (address => bool) private whiteList;
    uint256 private marketMilk;
    
    constructor(address devAddress, address MarketingAddress) {
        devAdd = payable(devAddress);
        MarAdd = payable(MarketingAddress);
    }

    function setWhiteList(address[] memory users, bool val) public onlyOwner {
        require(!initialized, "WhiteList not useful any more after launch!");
        uint iniCow = 0;
        if (val) {
            iniCow = 1;
        }
        for ( uint i=0; i < users.length; i++) {
            whiteList[users[i]] = val;
            hatcheryCows[users[i]] = iniCow;
        }
    }
    
    function hatchMilk(address ref) public {
        require(initialized);
        
        if (
            ref == msg.sender
            || hatcheryCows[ref] == 0 // Only address with Cows can be ref!
            ) {
            ref = address(0);
        }
        
        if (
            referrals[msg.sender] == address(0) 
            && referrals[msg.sender] != msg.sender
            && hatcheryCows[ref] != 0 // Only address with Cows can be ref!
            ) {
            referrals[msg.sender] = ref;
        }
        
        uint256 MilkUsed = getMyMilk(msg.sender);
        uint256 newCows = SafeMath.div(MilkUsed,MILK_TO_HATCH_1COW);
        hatcheryCows[msg.sender] = SafeMath.add(hatcheryCows[msg.sender],newCows);
        claimedMilk[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        
        //send referral Milk
        claimedMilk[referrals[msg.sender]] = 
        SafeMath.add(
            claimedMilk[referrals[msg.sender]],
            SafeMath.div(SafeMath.mul(MilkUsed, 14), 100)
            );
        
        //boost market to nerf Cows hoarding
        marketMilk=SafeMath.add(marketMilk,SafeMath.div(MilkUsed,5));
    }
    
    function sellMilk() public {
        require(initialized);
        uint256 hasMilk = getMyMilk(msg.sender);
        uint256 MilkValue = calculateMilkSell(hasMilk);
        uint256 fee1 = devFee(MilkValue);
        uint256 fee2 = MarFee(MilkValue);
        uint256 fee = SafeMath.add(fee1,fee2);
        claimedMilk[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketMilk = SafeMath.add(marketMilk,hasMilk);
        devAdd.transfer(fee1);
        MarAdd.transfer(fee2);
        payable (msg.sender).transfer(SafeMath.sub(MilkValue,fee));
    }
    
    function buyMilk(address ref) public payable {
        require(msg.sender == tx.origin, "No contract allowed");
        require(initialized, "Not open!");
        uint256 accountValue = max(SafeMath.sub(address(this).balance,msg.value), INITIAL_MONEY);
        uint256 MilkBought = calculateMilkBuy(msg.value, accountValue);
        uint256 feeMilk = SafeMath.add(devFee(MilkBought), MarFee(MilkBought));
        MilkBought = SafeMath.sub(MilkBought,feeMilk);
        devAdd.transfer(devFee(msg.value));
        MarAdd.transfer(MarFee(msg.value));
        claimedMilk[msg.sender] = SafeMath.add(claimedMilk[msg.sender],MilkBought);
        hatchMilk(ref);
    }

    function seedMarket(uint256 initial_value) public onlyOwner {
        require(marketMilk == 0);
        initialized = true;
        marketMilk = 108000000000;
        INITIAL_MONEY = initial_value;
    }

//////////////////////////////////// view functions /////////////////////////////////

    function beanRewards(address adr) public view returns(uint256) {
        uint256 hasMilk = getMyMilk(adr);
        uint256 MilkValue = calculateMilkSell(hasMilk);
        return MilkValue;
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateMilkSell(uint256 Milk) public view returns(uint256) {
        return calculateTrade(Milk,marketMilk,address(this).balance);
    }
    
    function calculateMilkBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketMilk);
    }
    
    function calculateMilkBuySimple(uint256 eth) public view returns(uint256) {
        uint256 accountValue = max(address(this).balance, INITIAL_MONEY);
        return calculateMilkBuy(eth,accountValue);
    }

    function calculateCowsBuySimple(uint256 eth) public view returns(uint256) {
        uint256 MilkUsed = calculateMilkBuySimple(eth);
        return SafeMath.div(MilkUsed,MILK_TO_HATCH_1COW);
    }

    function checkWhiteList(address user) public view returns(bool) {
        return whiteList[user];
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyCows(address adr) public view returns(uint256) {
        return hatcheryCows[adr];
    }
    
    function getMyMilk(address adr) public view returns(uint256) {
        return SafeMath.add(claimedMilk[adr], getMilkSinceLastHatch(adr));
    }
    
    function getMilkSinceLastHatch(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(MILK_TO_HATCH_1COW,SafeMath.sub(block.timestamp,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryCows[adr]);
    }

    function MarFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,MarketingFeeVal),100);
    }

/////////////////////////// tools ////////////////////

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}