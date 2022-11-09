/**
 *Submitted for verification at BscScan.com on 2022-06-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-15
*/

// SPDX-License-Identifier: MIT

    /* 
     * ████████╗██╗░░██╗███████╗  ███████╗░░███╗░░░█████╗░███████╗░░███╗░░██╗░░░██╗
     * ╚══██╔══╝██║░░██║██╔════╝  ██╔════╝░████║░░██╔══██╗██╔════╝░████║░░╚██╗░██╔╝
     * ░░░██║░░░███████║█████╗░░  █████╗░░██╔██║░░███████║█████╗░░██╔██║░░░╚████╔╝░
     * ░░░██║░░░██╔══██║██╔══╝░░  ██╔══╝░░╚═╝██║░░██╔══██║██╔══╝░░╚═╝██║░░░░╚██╔╝░░
     * ░░░██║░░░██║░░██║███████╗  ██║░░░░░███████╗██║░░██║██║░░░░░███████╗░░░██║░░░
     * ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝  ╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚══════╝░░░╚═╝░░░
     * 
     * ██████╗░██████╗░░█████╗░░░░░░██╗███████╗░█████╗░████████╗
     * ██╔══██╗██╔══██╗██╔══██╗░░░░░██║██╔════╝██╔══██╗╚══██╔══╝
     * ██████╔╝██████╔╝██║░░██║░░░░░██║█████╗░░██║░░╚═╝░░░██║░░░
     * ██╔═══╝░██╔══██╗██║░░██║██╗░░██║██╔══╝░░██║░░██╗░░░██║░░░
     * ██║░░░░░██║░░██║╚█████╔╝╚█████╔╝███████╗╚█████╔╝░░░██║░░░
     * ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░╚════╝░╚══════╝░╚════╝░░░░╚═╝░░░
     * 
     * A community driven NFT Art plateform.
     * For growing your revenus
     * and generating passive income  
     * 
     * Artwork is create thanks to Neuronal Networks with the use of Artificial Intelligence combined with Deep Learning technics. 
     * It's a work of fine art combination of keywords and images to render this unique digital art. 
     * Get your NFT profile picture or NFT token picture updated to new kind of digital artwork.
     * 
     * Differentiate your project on the telegram network and social medias with a personalized video featuring your project name and branding.
     * Get your own NFT - https://f1af1y.typeform.com/getdigitalart and/or contact https://t.me/F1af1Y for special requests.
     * 
     * Telegram - https://t.me/NFTs_Central
     * Announcement Channel - https://t.me/F1af1YsafuNFTs
     * 
     * Twitter - https://twitter.com/f1af1y
     * Tiktok - https://tiktok.com/@f1af1y/
     * Instagram - https://instagram.com/f1af1y/
     * 
     * Made with ❤️ from F1af1Y team.    
     */

pragma solidity ^0.8.9;

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

contract TheF1af1YProject is Context, Ownable {
    using SafeMath for uint256;

    uint256 private SHARES_TO_INVEST_1INVESTOR = 720000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private treasuryFeeVal = 200;
    bool private initialized = false;
    address payable public recAdd;
    mapping (address => uint256) private Factory;
    mapping (address => uint256) private claimedShares;
    mapping (address => uint256) private lastInvest;
    mapping (address => address) private referrals;
    uint256 private marketShares;
    
    constructor() {
        recAdd = payable(msg.sender);
    }
    
    function ContributeToRewards () public payable {
    }

    function Invest(address ref) public {
        require(initialized);
        if(ref == msg.sender || ref == address(0) || Factory[ref] == 0) {
            ref = recAdd;
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 sharesUsed = getMyShares(msg.sender);
        uint256 newInvestor = SafeMath.div(sharesUsed,SHARES_TO_INVEST_1INVESTOR);
        Factory[msg.sender] = SafeMath.add(Factory[msg.sender],newInvestor);
        claimedShares[msg.sender] = 0;
        lastInvest[msg.sender] = block.timestamp;
        
        //send referral shares
        claimedShares[referrals[msg.sender]] = SafeMath.add(claimedShares[referrals[msg.sender]],SafeMath.div(sharesUsed,10));
        
        //boost market to nerf investor hoarding
        marketShares=SafeMath.add(marketShares,SafeMath.div(sharesUsed,5));
    }
    
    function sellShares() public {
        require(initialized);
        uint256 hasShares = getMyShares(msg.sender);
        uint256 shareValue = calculateShareSell(hasShares);
        uint256 fee = treasuryFee(shareValue);
        claimedShares[msg.sender] = 0;
        lastInvest[msg.sender] = block.timestamp;
        marketShares = SafeMath.add(marketShares,hasShares);
        recAdd.transfer(fee);
        payable (msg.sender).transfer(SafeMath.sub(shareValue,fee));
    }
    
    function shareRewards(address adr) public view returns(uint256) {
        uint256 hasShares = getMyShares(adr);
        uint256 shareValue = calculateShareSell(hasShares);
        return shareValue;
    }
    
    function buyShares(address ref) public payable {
        require(initialized);
        uint256 sharesBought = calculateShareBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        sharesBought = SafeMath.sub(sharesBought,treasuryFee(sharesBought));
        uint256 fee = treasuryFee(msg.value);
        recAdd.transfer(fee);
        claimedShares[msg.sender] = SafeMath.add(claimedShares[msg.sender],sharesBought);
        Invest(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateShareSell(uint256 shares) public view returns(uint256) {
        return calculateTrade(shares,marketShares,address(this).balance);
    }
    
    function calculateShareBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketShares);
    }
    
    function calculateShareBuySimple(uint256 eth) public view returns(uint256) {
        return calculateShareBuy(eth,address(this).balance);
    }
    
    function treasuryFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,treasuryFeeVal),1000);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketShares == 0);
        initialized = true;
        marketShares = 42000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyInvestor(address adr) public view returns(uint256) {
        return Factory[adr];
    }
    
    function getMyShares(address adr) public view returns(uint256) {
        return SafeMath.add(claimedShares[adr],getSharesSinceLastInvest(adr));
    }
    
    function getSharesSinceLastInvest(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(SHARES_TO_INVEST_1INVESTOR,SafeMath.sub(block.timestamp,lastInvest[adr]));
        return SafeMath.mul(secondsPassed,Factory[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function setTreasuryFeeAddress(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        recAdd = payable(account);
    }
}