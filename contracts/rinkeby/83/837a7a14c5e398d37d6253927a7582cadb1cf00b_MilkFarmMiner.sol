/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-05
*/

/*
    MilkFarm Miner - BSC BNB Miner
    Developed by Kraitor <TG: kraitordev>
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

contract MilkFarmMiner is Context, Ownable {
    using SafeMath for uint256;

    event Hire(address indexed adr, uint256 milks, uint256 amount);
    event Drink(address indexed adr, uint256 milks, uint256 amount, uint256 penalty);

    /*
    *   Those are the fees for the miner
    *   They cannot be modified once the contract is deployed
    */
    uint256 private rewardsPercentage = 15;
    uint256 private devFeeVal = 1;
    uint256 private sellTaxVal = 4;

    uint256 private MILKS_TO_HATCH_1MILKER = 576000; //for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    bool private initialized = false;
    address payable private recAdd;
    mapping (address => uint256) private investments;
    mapping (address => uint256) private withdrawals;

    mapping (address => uint256) private hiredMilkers;
    mapping (address => uint256) private claimedMilks;
    mapping (address => uint256) private lastHire;
    mapping (address => uint256[]) private sellsTimestamps;
    mapping (address => uint256) private customSellTaxes;
    mapping (address => address) private referrals;
    uint256 private marketMilks;
    
    constructor() {
        recAdd = payable(msg.sender);
    }

    // This function is called by anyone who want to contribute to TVL
    function ContributeToTVL() public payable {

    }

    function rehireMilkers(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 milksUsed = getMyMilks(msg.sender);
        uint256 newMilkers = SafeMath.div(milksUsed,MILKS_TO_HATCH_1MILKER);
        hiredMilkers[msg.sender] = SafeMath.add(hiredMilkers[msg.sender],newMilkers);
        claimedMilks[msg.sender] = 0;
        lastHire[msg.sender] = block.timestamp;
        
        //send referral milks
        claimedMilks[referrals[msg.sender]] = SafeMath.add(claimedMilks[referrals[msg.sender]],SafeMath.div(milksUsed,8));
        
        //boost market to nerf miners hoarding
        marketMilks=SafeMath.add(marketMilks,SafeMath.div(milksUsed,5));
    }
    
    function drinkMilks() public {
        require(initialized);

        uint256 hasMilks = getMyMilks(msg.sender);
        uint256 milksValue = calculateMilkSell(hasMilks);
        uint256 sellTax = calculateSellTax(milksValue, msg.sender);
        uint256 penalty = getSellPenalty(msg.sender);

        claimedMilks[msg.sender] = 0;
        lastHire[msg.sender] = block.timestamp;
        marketMilks = SafeMath.add(marketMilks,hasMilks);
        recAdd.transfer(sellTax);
        withdrawals[msg.sender] += SafeMath.sub(milksValue,sellTax);
        payable (msg.sender).transfer(SafeMath.sub(milksValue,sellTax));

        // Push the timestamp
        sellsTimestamps[msg.sender].push(block.timestamp);

        emit Drink(msg.sender, milksValue, SafeMath.sub(milksValue,sellTax), penalty);
    }

    function setRewardsPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage >= 15, 'Percentage cannot be less than 15');
        rewardsPercentage = _percentage;
    }

    function getRewardsPercentage() public view returns (uint256) {
        return rewardsPercentage;
    }

    function getMarketMilks() public view returns (uint256) {
        return marketMilks;
    }
    
    function milksRewards(address adr) public view returns(uint256) {
        uint256 hasMilks = getMyMilks(adr);
        uint256 milksValue = calculateMilkSell(hasMilks);
        return milksValue;
    }

    function milksRewardsIncludingTaxes(address adr) public view returns(uint256) {
        uint256 hasMilks = getMyMilks(adr);
        (uint256 milksValue,) = calculateMilkSellIncludingTaxes(hasMilks, adr);
        return milksValue;
    }
    
    function hireMilkers(address ref) public payable {
        require(initialized);
        uint256 milksBought = calculateHireMilkers(msg.value,SafeMath.sub(address(this).balance,msg.value));

        uint256 milksBoughtFee = calculateBuyTax(milksBought);
        milksBought = SafeMath.sub(milksBought,milksBoughtFee);

        uint256 fee = calculateBuyTax(msg.value);
        recAdd.transfer(fee);
        claimedMilks[msg.sender] = SafeMath.add(claimedMilks[msg.sender],milksBought);
        investments[msg.sender] += msg.value;
        rehireMilkers(ref);

        emit Hire(msg.sender, milksBought, msg.value);
    }

    function getSellPenalty(address addr) public view returns (uint256) {

        // If there is custom sell tax for this address, then return it
        if(customSellTaxes[addr] > 0) {
            return customSellTaxes[addr];
        }

        uint256 sellsInRow = getSellsInRow(addr);
        uint256 numberOfSells = sellsTimestamps[addr].length;
        uint256 _sellTax = sellTaxVal;

        if(numberOfSells > 0) {
            uint256 lastSell = sellsTimestamps[addr][numberOfSells - 1];

            if(sellsInRow == 0) {
                if((block.timestamp - 30 days) > lastSell) { // 1% sell tax for everyone who hold / rehire during 30+ days
                    _sellTax = 0;
                } else if((lastSell + 4 days) <= block.timestamp) { // 5% sell tax for everyone who sell after 4 days of last sell
                    _sellTax = sellTaxVal;
                } else if((lastSell + 3 days) <= block.timestamp) { // 8% sell tax for everyone who sell after 3 days of last sell
                    _sellTax = 7;
                } else { // otherwise 10% sell tax
                    _sellTax = 9;
                }
            } else if(sellsInRow == 1) {  // 20% sell tax for everyone who sell 2 days in a row
                _sellTax = 19;
            } else if(sellsInRow >= 2) {  // 40% sell tax for everyone who sell 3 or more days in a row
                _sellTax = 39;
            }
        }

        return SafeMath.add(_sellTax, devFeeVal);
    }

    function getSellsInRow(address addr) public view returns(uint256) {
        uint256 sellsInRow = 0;
        uint256 numberOfSells = sellsTimestamps[addr].length;
        if(numberOfSells == 1) {
            if(sellsTimestamps[addr][0] >= (block.timestamp - 1 days)) {
                return 1;
            }
        } else if(numberOfSells > 1) {
            uint256 lastSell = sellsTimestamps[addr][numberOfSells - 1];

            if((lastSell + 1 days) <= block.timestamp) {
                return 0;
            } else {

                for(uint256 i = numberOfSells - 1; i > 0; i--) {
                    if(isSellInRow(sellsTimestamps[addr][i-1], sellsTimestamps[addr][i])) {
                        sellsInRow++;
                    } else {
                        if(i == (numberOfSells - 1))
                            sellsInRow = 0;

                        break;
                    }
                }

                if((lastSell + 1 days) > block.timestamp) {
                    sellsInRow++;
                }
            }
        }

        return sellsInRow;
    }

    function getSellsByAddress(address addr) public view returns (uint256[] memory timestamps) {
        return sellsTimestamps[addr];
    }

    function isSellInRow(uint256 previousDay, uint256 currentDay) private pure returns(bool) {
        return currentDay <= (previousDay + 1 days);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        uint256 valueTrade = SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
        if(rewardsPercentage > 15) {
            return SafeMath.div(SafeMath.mul(valueTrade,rewardsPercentage), 15);
        }

        return valueTrade;
    }
    
    function calculateMilkSell(uint256 milks) public view returns(uint256) {
        return calculateTrade(milks,marketMilks,address(this).balance);
    }

    function calculateMilkSellIncludingTaxes(uint256 milks, address addr) public view returns(uint256, uint256) {
        uint256 totalTrade = calculateTrade(milks,marketMilks,address(this).balance);
        uint256 penalty = getSellPenalty(addr);
        uint256 sellTax = calculateSellTax(totalTrade, addr);

        return (
            SafeMath.sub(totalTrade, sellTax),
            penalty
        );
    }
    
    function calculateHireMilkers(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketMilks);
    }
    
    function calculateHireMilkersSimple(uint256 eth) public view returns(uint256) {
        return calculateHireMilkers(eth,address(this).balance);
    }
    
    function calculateBuyTax(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function calculateSellTax(uint256 amount, address sender) private view returns(uint256) {
        uint256 tax = getSellPenalty(sender);
        return SafeMath.div(SafeMath.mul(amount,tax),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketMilks == 0);
        initialized = true;
        marketMilks = 108000000000;
    }

    function setCustomSellTaxForAddress(address adr, uint256 percentage) public onlyOwner {
        customSellTaxes[adr] = percentage;
    }

    function getCustomSellTaxForAddress(address adr) public view returns (uint256) {
        return customSellTaxes[adr];
    }

    function removeCustomSellTaxForAddress(address adr) public onlyOwner {
        delete customSellTaxes[adr];
    }

    function isInitialized() public view returns (bool) {
        return initialized;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMilkers(address adr) public view returns(uint256) {
        return hiredMilkers[adr];
    }
    
    function getMyMilks(address adr) public view returns(uint256) {
        return SafeMath.add(claimedMilks[adr],getMilksSinceLastHire(adr));
    }
    
    function getMilksSinceLastHire(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(MILKS_TO_HATCH_1MILKER,SafeMath.sub(block.timestamp,lastHire[adr]));
        return SafeMath.mul(secondsPassed,hiredMilkers[adr]);
    }

    function getTotalInvestmentByAddress(address adr) public view returns(uint256) {
        return investments[adr];
    }

    function getTotalWithdrawal(address adr) public view returns(uint256) {
        return withdrawals[adr];
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}