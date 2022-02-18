/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721  {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function mint(address user, string memory ipfsHash ) external returns(uint256 tokenId);
}


contract BLINE_NFT_MARKETPLACE is  Ownable {
  using SafeMath for uint256;  
  address public settlementFeeAddress = 0x969fDF6d23f468f006aAB77B24fD49016daC1e3b;
  uint256 public settlementFeePercentage = 200; // 2% decimal number 100
  IERC721 public ERC721 = IERC721(0xc0CA5f776AB69A2e2B3391a5c97FE4D816847CDa);

    enum SellType {Invalid, FIXED_PRICE, AUCTION}

  struct _tokenDetails{
      address creator;
      address owner;
      uint256 royalty;
      uint256 auctionStart;
      uint256 auctionExpire;
      uint256 salePrice;
      SellType sellType;
      bool isActive;
  }
  mapping(uint256 => _tokenDetails) public tokenDetails;

 struct _bidDetail {
     uint256 amount;
     address bidder;
     bool isActive;
 }
 mapping(uint256 => _bidDetail) public bidDetail;

  constructor() {

  }
  
    function _mint(string memory ipfsHash,uint256 salePrice, uint256 royalty,SellType sellType, uint256 auctionStart, uint256 auctionExpire ) public payable returns(uint256 tokenId){
        require(
            sellType == SellType.FIXED_PRICE || sellType == SellType.AUCTION,
            "Wrong sell type"
        );
        
        tokenId =  ERC721.mint(msg.sender,ipfsHash);
        payable(settlementFeeAddress).transfer(msg.value);
        tokenDetails[tokenId] = _tokenDetails(msg.sender,msg.sender,royalty,auctionStart,auctionExpire,salePrice,sellType,true);
    }

    function updateDetails(uint256 tokenId,uint256 salePrice,SellType sellType, uint256 auctionStart, uint256 auctionExpire) public {
        require(msg.sender == ERC721.ownerOf(tokenId), "Caller is not token owner");
        require(
            sellType == SellType.FIXED_PRICE || sellType == SellType.AUCTION,
            "Wrong sell type"
        ); 
        tokenDetails[tokenId].salePrice = salePrice; 
        tokenDetails[tokenId].auctionStart = auctionStart;       
        tokenDetails[tokenId].auctionExpire = auctionExpire;       
        tokenDetails[tokenId].sellType = sellType;  
        tokenDetails[tokenId].isActive = true;
    }

    function buy(uint256 tokenId) payable public {
        require(tokenDetails[tokenId].isActive, "Invalid token ID");
        require(tokenDetails[tokenId].sellType == SellType(1), "Invalid sell type");
        require(msg.value >= tokenDetails[tokenId].salePrice, "Insufficient amount to buy");

        ERC721.safeTransferFrom(tokenDetails[tokenId].owner,msg.sender,tokenId);
        
        uint256 royaltyAmt;
        uint256 feeAmt;
        if(tokenDetails[tokenId].royalty > 0){
            royaltyAmt = tokenDetails[tokenId].salePrice.mul(tokenDetails[tokenId].royalty).div(10000);
            payable(tokenDetails[tokenId].creator).transfer(royaltyAmt);
        }
        if(settlementFeePercentage > 0){
            feeAmt = tokenDetails[tokenId].salePrice.mul(settlementFeePercentage).div(10000);
            payable(settlementFeeAddress).transfer(feeAmt);
        }
        payable(tokenDetails[tokenId].owner).transfer(tokenDetails[tokenId].salePrice.sub(royaltyAmt).sub(feeAmt));
        tokenDetails[tokenId].owner = msg.sender;
    }


  function placeBid(uint256 tokenId) external payable {
        require(tokenDetails[tokenId].isActive, "Invalid token ID");
        require(tokenDetails[tokenId].auctionStart <= block.timestamp, "Auction is not started");
        require(tokenDetails[tokenId].auctionExpire >= block.timestamp, "Auction has been closed");

        require(tokenDetails[tokenId].sellType == SellType(2), "Invalid sell type");
        require(bidDetail[tokenId].amount < msg.value, "Amount should be more than previous bid");

        if(bidDetail[tokenId].isActive){
            payable(bidDetail[tokenId].bidder).transfer(bidDetail[tokenId].amount);
        }
        bidDetail[tokenId] = _bidDetail(msg.value,msg.sender,true);
  }


  function acceptBid(uint256 tokenId) external {
    require(tokenDetails[tokenId].isActive, "Invalid token ID");
    require(bidDetail[tokenId].isActive, "Bid not available for sale");
    require(tokenDetails[tokenId].owner == msg.sender || owner() == msg.sender, "Caller is not item owner"); 


    ERC721.safeTransferFrom(tokenDetails[tokenId].owner,bidDetail[tokenId].bidder,tokenId);

    uint256 royaltyAmt;
    uint256 feeAmt;
    if(tokenDetails[tokenId].royalty > 0){
        royaltyAmt = bidDetail[tokenId].amount.mul(tokenDetails[tokenId].royalty).div(10000);
        payable(tokenDetails[tokenId].creator).transfer(royaltyAmt);
       
    }
    if(settlementFeePercentage > 0){
        feeAmt = bidDetail[tokenId].amount.mul(settlementFeePercentage).div(10000);
         payable(settlementFeeAddress).transfer(feeAmt);
    }
    
     payable(tokenDetails[tokenId].owner).transfer(bidDetail[tokenId].amount.sub(royaltyAmt).sub(feeAmt));
    tokenDetails[tokenId].owner = bidDetail[tokenId].bidder;
    tokenDetails[tokenId].isActive = false;

  }


  function setsettlementFeeAddress(address _settlementFeeAddress) public onlyOwner{
      settlementFeeAddress = _settlementFeeAddress;
  }
  function setsettlementFeePercentage(uint256 _settlementFeePercentage) public onlyOwner{
      settlementFeePercentage = _settlementFeePercentage;
  }
  
  
}