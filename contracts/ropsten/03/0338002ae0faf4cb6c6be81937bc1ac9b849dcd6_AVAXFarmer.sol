/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

/*

░█████╗░██╗░░░██╗░█████╗░██╗░░██╗███████╗░█████╗░██████╗░███╗░░░███╗███████╗██████╗░
██╔══██╗██║░░░██║██╔══██╗╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗████╗░████║██╔════╝██╔══██╗
███████║╚██╗░██╔╝███████║░╚███╔╝░█████╗░░███████║██████╔╝██╔████╔██║█████╗░░██████╔╝
██╔══██║░╚████╔╝░██╔══██║░██╔██╗░██╔══╝░░██╔══██║██╔══██╗██║╚██╔╝██║██╔══╝░░██╔══██╗
██║░░██║░░╚██╔╝░░██║░░██║██╔╝╚██╗██║░░░░░██║░░██║██║░░██║██║░╚═╝░██║███████╗██║░░██║
╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═╝░░╚═╝
5% Fees
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
    address public _marketing;
    address public _team;
    address public _web;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _marketing = 0x9A22b45338CB8764C4D5384A3C8c25411355EF45;
      _team = 0x513CDC7297659e71845F76E7119566A957767c8F;
      _web = 0x513CDC7297659e71845F76E7119566A957767c8F;
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

contract AVAXFarmer is Context, Ownable {
    using SafeMath for uint256;

    uint256 private FARMERS_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    uint256 private marketingFeeVal = 2;
    uint256 private webFeeVal = 1;
    uint256 private teamFeeVal = 0;
    bool private initialized = false;
    address payable private recAdd;
    address payable private marketingAdd;
    address payable private teamAdd;
    address payable private webAdd;
    mapping (address => uint256) private farmMiners;
    mapping (address => uint256) private claimedWork;
    mapping (address => uint256) private lastHarvest;
    mapping (address => address) private referrals;
    uint256 private marketFarmers;
    
    constructor() { 
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketing);
        teamAdd = payable(_team);
        webAdd = payable(_web);
    }
    
    function harvestFarmers(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 farmersUsed = getMyFarmers(msg.sender);
        uint256 newMiners = SafeMath.div(farmersUsed,FARMERS_TO_HATCH_1MINERS);
        farmMiners[msg.sender] = SafeMath.add(farmMiners[msg.sender],newMiners);
        claimedWork[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        
        //send referral farmers
        claimedWork[referrals[msg.sender]] = SafeMath.add(claimedWork[referrals[msg.sender]],SafeMath.div(farmersUsed,8));
        
        //boost market to nerf miners hoarding
        marketFarmers=SafeMath.add(marketFarmers,SafeMath.div(farmersUsed,5));
    }
    
    function sellFarmers() public {
        require(initialized);
        uint256 hasFarmers = getMyFarmers(msg.sender);
        uint256 farmValue = calculateWorkSell(hasFarmers);
        uint256 fee1 = devFee(farmValue);
        uint256 fee2 = marketingFee(farmValue);
        uint256 fee3 = webFee(farmValue);
        uint256 fee4 = teamFee(farmValue);
        claimedWork[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketFarmers = SafeMath.add(marketFarmers,hasFarmers);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);        
        teamAdd.transfer(fee3);
        webAdd.transfer(fee4);
        payable (msg.sender).transfer(SafeMath.sub(farmValue,fee1));

    }
    
    function farmRewards(address adr) public view returns(uint256) {
        uint256 hasFarmers = getMyFarmers(adr);
        uint256 farmValue = calculateWorkSell(hasFarmers);
        return farmValue;
    }
    
    function buyFarmers(address ref) public payable {
        require(initialized);
        uint256 farmersBought = calculateWorkBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        farmersBought = SafeMath.sub(farmersBought,devFee(farmersBought));
        farmersBought = SafeMath.sub(farmersBought,marketingFee(farmersBought));
        farmersBought = SafeMath.sub(farmersBought,webFee(farmersBought));
        farmersBought = SafeMath.sub(farmersBought,teamFee(farmersBought));

        uint256 fee1 = devFee(msg.value);
        uint256 fee2 = marketingFee(msg.value);
        uint256 fee3 = webFee(msg.value);
        uint256 fee4 = teamFee(msg.value);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        teamAdd.transfer(fee3);
        webAdd.transfer(fee4);

        claimedWork[msg.sender] = SafeMath.add(claimedWork[msg.sender],farmersBought);
        harvestFarmers(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateWorkSell(uint256 farmers) public view returns(uint256) {
        return calculateTrade(farmers,marketFarmers,address(this).balance);
    }
    
    function calculateWorkBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketFarmers);
    }
    
    function calculateWorkBuySimple(uint256 eth) public view returns(uint256) {
        return calculateWorkBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingFeeVal),100);
    }
    
    function webFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,webFeeVal),100);
    }

    function teamFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,teamFeeVal),100);
    }

    function openFarm() public payable onlyOwner {
        require(marketFarmers == 0);
        initialized = true;
        marketFarmers = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return farmMiners[adr];
    }
    
    function getMyFarmers(address adr) public view returns(uint256) {
        return SafeMath.add(claimedWork[adr],getFarmersSinceLastHarvest(adr));
    }
    
    function getFarmersSinceLastHarvest(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(FARMERS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHarvest[adr]));
        return SafeMath.mul(secondsPassed,farmMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    function transferToAddressETH(address payable recipient, uint256 amount) public {
        recipient.transfer(amount);
    }
}