/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// File: contracts/OrganicFarm.sol



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

contract OrganicFarm is Context, Ownable {

    using SafeMath for uint256;

    uint256 private SEEDS_TO_PLANT_1FARMERS = 1440000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private developerFee = 5;
    bool private initialized = false;
    address addr0 = address(0x0);
    address payable private DevAddress; 
    address payable private EcosystemAddress;   
    mapping (address => uint256) private seedFarmers;
    mapping (address => uint256) private claimedSeeds;
    mapping (address => uint256) private lastPlanted;
    mapping (address => address) private referrals;
    uint256 private marketSeeds;

    constructor(address payable _DevAddress) {
        DevAddress = _DevAddress;
        EcosystemAddress = payable(msg.sender);

    }
    
    function replantSeeds(address ref) public {
        require(initialized);
        if(ref == msg.sender || ref == address(0) || seedFarmers[ref] == 0) {
            ref = EcosystemAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 seedsUsed = getMySeeds(msg.sender);
        uint256 newFarmers = SafeMath.div(seedsUsed, SEEDS_TO_PLANT_1FARMERS);
       seedFarmers[msg.sender] = SafeMath.add(
            seedFarmers[msg.sender],
            newFarmers
        );
        claimedSeeds[msg.sender] = 0;
        lastPlanted[msg.sender] = block.timestamp;

        //send referral eggs
        address r1 = referrals[msg.sender];
        if (r1 != addr0) {
            claimedSeeds[r1] = SafeMath.add(
                claimedSeeds[r1],
                SafeMath.div(SafeMath.mul(seedsUsed, 8), 100)
            );
            address r2 = referrals[r1];
            if (r2 != addr0 && r2 != msg.sender) {
                claimedSeeds[r2] = SafeMath.add(
                    claimedSeeds[r2],
                    SafeMath.div(SafeMath.mul(seedsUsed, 2), 100)
                );
                address r3 = referrals[r2];
                if (r3 != addr0 && r3 != msg.sender) {
                    claimedSeeds[r3] = SafeMath.add(
                        claimedSeeds[r3],
                        SafeMath.div(SafeMath.mul(seedsUsed, 1), 100)
                    );
                }
            }
        }

        //boost market to nerf miners hoarding
        marketSeeds = SafeMath.add(marketSeeds, SafeMath.div(seedsUsed, 8));
    }
    
    function harvestSeeds() public {
        require(initialized);
        uint256 hasSeeds = getMySeeds(msg.sender);
        uint256 seedValue = calculateSeedSell(hasSeeds);
        uint256 fee = devFee(seedValue);
        claimedSeeds[msg.sender] = 0;
        lastPlanted[msg.sender] = block.timestamp;
        marketSeeds = SafeMath.add(marketSeeds, hasSeeds);
        payable(DevAddress).transfer(fee);
        payable(msg.sender).transfer(SafeMath.sub(seedValue, fee));
    }
    
    function seedRewards(address adr) public view returns(uint256) {
        uint256 hasSeeds = getMySeeds(adr);
        uint256 seedValue = calculateSeedSell(hasSeeds);
        return seedValue;
    }
    
    function plantSeeds(address ref) public payable {
        require(initialized);
        uint256 seedsBought = calculateSeedBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        seedsBought = SafeMath.sub(seedsBought,devFee(seedsBought));
        uint256 fee = devFee(msg.value);
        DevAddress.transfer(fee);
        claimedSeeds[msg.sender] = SafeMath.add(claimedSeeds[msg.sender],seedsBought);
        replantSeeds(ref);
    }
  
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateSeedSell(uint256 seeds) public view returns(uint256) {
        return calculateTrade(seeds,marketSeeds,address(this).balance);
    }
    
    function calculateSeedBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSeeds);
    }
    
    function calculateSeedBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSeedBuy(eth,address(this).balance);
    }

    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,developerFee),100);
    }

    function seedMarket() public payable onlyOwner {
        require(marketSeeds == 0);
        initialized = true;
        marketSeeds = 144000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyFarmers(address adr) public view returns(uint256) {
        return seedFarmers[adr];
    }
    
    function getMySeeds(address adr) public view returns(uint256) {
        return SafeMath.add(claimedSeeds[adr],getSeedsSinceLastPlant(adr));
    }
    
    function getSeedsSinceLastPlant(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(SEEDS_TO_PLANT_1FARMERS,SafeMath.sub(block.timestamp,lastPlanted[adr]));
        return SafeMath.mul(secondsPassed,seedFarmers[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}