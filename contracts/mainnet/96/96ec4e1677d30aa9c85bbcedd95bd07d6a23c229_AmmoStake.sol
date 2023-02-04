/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/mamstaking.sol


pragma solidity ^0.8.6;




interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}






interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}

contract AmmoStake is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;


    IERC721 public mam;
    IERC721 public mutant;

    IERC20 public token;


    struct Collection {
        
        uint16[] ids;
        uint256 numberStaked;
        uint16[] remainingIds;
        uint256 tokenStakedAt;
        bool daily;
        address owner;
          
        
    }
    

    mapping(uint16 => mapping(address => Collection)) public collection;
    mapping(address => uint16) public collectionsByAddress;
    mapping(uint16 => address) public collectionsById;
    mapping(uint16 => uint256) public totalStakedByCollection;
    mapping(address => bool) public blacklistedUsers;
   
    


    uint256 public dayRate = 1;
    uint256 public period = 45; //number of days
    


    uint16 public collectionCount = 1;
    uint256 public totalStaked;
    uint256 public mutantStaked;
    uint256 public amountPaid;
    uint256 public decimals = 18;
   

    bool public lockingPeriodEnforced = false;
    bool public escapeHatchOpen = false;
    


    event Staked(address indexed, uint256, uint16[]);
    event Unstake(address indexed, uint256);
    
    event Payout(address indexed, uint256);
    event DayRateChange(uint256);
    event PeriodChange(uint256);

   

    constructor(address _token)  {
        

        token = IERC20(_token);
        

    }

    

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function addNewCollection(address _nft) external onlyOwner {
        require(collectionsByAddress[_nft] == 0, "Collection already added");
        collectionsByAddress[_nft] = collectionCount;
        collectionsById[collectionCount] = _nft;
        collectionCount++;
    }

    function getCollectionById(uint16 _id) external view returns (address){
        return collectionsById[_id];
    }

    function getCollectionByAddress(address _addr) external view returns (uint16){
        return collectionsByAddress[_addr];
    }

    

    function stake(uint16[] memory tokenIds, uint16 collectionId) external {
        require(!blacklistedUsers[msg.sender], "User is blacklisted");
        require(collectionsById[collectionId] != address(0), "Invalid collection Id");
        IERC721 nft = IERC721(collectionsById[collectionId]); 
        uint256 quantity = tokenIds.length;
        collection[collectionId][msg.sender].tokenStakedAt = block.timestamp;
        collection[collectionId][msg.sender].numberStaked+= quantity;
        collection[collectionId][msg.sender].owner = msg.sender;
        collection[collectionId][msg.sender].daily = false;
        
        totalStakedByCollection[collectionId]+= quantity;
        totalStaked+=quantity;
        
        for(uint8 i; i < tokenIds.length; i++) {
            collection[collectionId][msg.sender].ids.push(tokenIds[i]);
            nft.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        
        emit Staked(msg.sender, quantity, tokenIds);
    }

    
    
    

    function calculateTime(address _owner, uint16 _type) public view returns (uint256) {
        uint256 timeElapsed;
        
        timeElapsed = block.timestamp - collection[_type][_owner].tokenStakedAt;
        
        
        return timeElapsed;
        
    }


    function calculateTokens(address _owner, uint16 _type) external view returns (uint256) {
        uint256 _payout;
       
        uint256 time = calculateTime(_owner, _type);
        
        
        _payout = dayRate * time * collection[_type][_owner].numberStaked;
        
        uint256 totalPayout = _payout *(10**decimals);
        return totalPayout.div(86400);
            
        
       
    }

    

    function unstakeById(address _owner, uint16 tokenId, uint16 _type) external nonReentrant {
        require(!blacklistedUsers[msg.sender], "User is blacklisted");
        require(collection[_type][_owner].owner == msg.sender, "Can't unstake someone else's nfts");
        require(tokenId != 0, "tokenId cannot be zero");
        IERC721 nft = IERC721(collectionsById[_type]);

        bool exists = false;
        uint256 time = calculateTime(_owner, _type);
        
        uint256 _payout;

         if(!collection[_type][_owner].daily && lockingPeriodEnforced) {
                require(time >= period*86400, "Staking period has not ended");
            }
        

        for(uint8 i; i < collection[_type][_owner].ids.length; i++) {
            if(collection[_type][_owner].ids[i] == tokenId) {
                nft.transferFrom(address(this), msg.sender, tokenId);
                delete collection[_type][_owner].ids[i];
               exists = true; 
                 
            } 
           
        }
        if(exists) {
            
            totalStaked--;
            totalStakedByCollection[_type]--;
            collection[_type][_owner].numberStaked--;
                
        _payout = dayRate * time;

        uint256 totalPayout = _payout *(10**decimals);
        uint256 totalPayoutPS = totalPayout.div(86400);
        amountPaid+= totalPayoutPS;
              
        token.transfer(msg.sender, totalPayoutPS);
                
        
        collection[_type][_owner].daily = true;
        collection[_type][_owner].tokenStakedAt = block.timestamp;

        emit Unstake(msg.sender, totalPayout);
        } else {
            revert("tokenId not staked or nonexistent");
        }

         
       
    }

    function payout(address _owner, uint16 _type) external nonReentrant {
        require(!blacklistedUsers[msg.sender], "User is blacklisted");
        require(collection[_type][_owner].owner == msg.sender, "Can't initiate someone else's payout");
        
        
        uint256 time = calculateTime(_owner, _type);
        
        uint256 _payout = dayRate * time * collection[_type][_owner].numberStaked;

         if(!collection[_type][_owner].daily && lockingPeriodEnforced) {
                require(time >= period*86400, "Staking period has not ended");
            }
        
        uint256 totalPayout = _payout *(10**decimals);
        uint256 totalPayoutPS = totalPayout.div(86400);
        amountPaid+= totalPayoutPS;
              
        token.transfer(_owner, totalPayoutPS);
                
       
        collection[_type][_owner].daily = true;
        collection[_type][_owner].tokenStakedAt = block.timestamp;

        emit Payout(_owner, totalPayout);
            
       
    }

    

    function unstake(address _owner, uint16 _type) external nonReentrant {
        require(!blacklistedUsers[msg.sender], "User is blacklisted");
        require(collection[_type][_owner].owner == msg.sender, "Can't unstake someone else's nfts");
        IERC721 nft = IERC721(collectionsById[_type]);
        
         uint256 time = calculateTime(_owner, _type);
        
        uint256 _payout = dayRate * time * collection[_type][_owner].numberStaked;

         if(!collection[_type][_owner].daily && lockingPeriodEnforced) {
                require(time >= period*86400, "Staking period has not ended");
            }
          

        for(uint8 i; i< collection[_type][_owner].ids.length; i++) {
            if(collection[_type][_owner].ids[i] != 0) {
                collection[_type][_owner].remainingIds.push(collection[_type][_owner].ids[i]);
            
            }
        }

        for(uint8 i; i < collection[_type][_owner].remainingIds.length; i++) {
            
                 nft.transferFrom(address(this), msg.sender, collection[_type][_owner].remainingIds[i]);
            
           
        }
         uint256 totalPayout = _payout *(10**decimals);
        uint256 totalPayoutPS = totalPayout.div(86400);
        amountPaid+= totalPayoutPS;
              
        token.transfer(msg.sender, totalPayoutPS);
        
        totalStaked-=collection[_type][_owner].numberStaked;
        totalStakedByCollection[_type] -= collection[_type][_owner].numberStaked;
            
        delete collection[_type][_owner];
            
        emit Unstake(msg.sender, totalPayoutPS);
     
    }



  function setTokenAddress(address _newToken) external onlyOwner {
      token = IERC20(_newToken);
  }

  function setDayRate(uint256 _newRate) external onlyOwner {
      require(_newRate != 0, "rate cannot be zero");
      dayRate = _newRate;
      emit DayRateChange(_newRate);
  }

  
  function enforceLockingPeriod(bool _state) external onlyOwner {
      lockingPeriodEnforced = _state;
  }

   /* This function can be triggered if for some reason holders are unable to 
      unstake their nfts.*/
  function openEscapeHatch(bool _state) external onlyOwner {
     escapeHatchOpen = _state;

  }
  /* EscapeHatchWithdrawal should only be called as a last resort if the contract is hacked or compromised
  * in any way. It is designed to allow the user to withdraw NFTs by id at minimum cost and without regard
  * for updating states or any other actions that would cause the function to be more expensive. Only use
  * this function if you do not plan on using this contract any further. 
  *Note: escapeHatchOpen must first be set to true by the owner.
  *@param _owner - user address
  *@param _type - collectionId
  *@param _ids - array containing tokenIds belonging to user
  */

  function escapeHatchWithdrawal(address _owner, uint8 _type, uint16[] calldata _ids) external {
      require(escapeHatchOpen, "Escape hatch is closed");
      IERC721 nft = IERC721(collectionsById[_type]);
      
          require(collection[_type][_owner].owner == msg.sender, "Can't unstake someone else's nft");
          for(uint8 i; i < _ids.length; i++) {
              nft.transferFrom(address(this), _owner, _ids[i]);
              
          }
     
      
  }


    function setPeriod(uint256 _time) external onlyOwner {
        period = _time;
        emit PeriodChange(_time);
    }

    

    function getEligibility(address _owner, uint8 _type) external view returns(bool) {
        bool eligible;
       
        eligible = collection[_type][_owner].daily;

        
        return eligible;
    }

    function setRewardEligible(address _owner, uint8 _type, bool _state) external onlyOwner {
    
            collection[_type][_owner].daily = _state;

       
    }
   
  

  function getNumberStaked(address _owner, uint16 _type) external view returns (uint256){
      return collection[_type][_owner].numberStaked;
  }

  
  
  function getIds(address _owner, uint16 _type) external view returns (uint16[] memory){
      return collection[_type][_owner].ids;
  }

  

  function blacklistUser(address _owner) external onlyOwner {
      blacklistedUsers[_owner] = true;
  }

  function removeFromBlacklist(address _owner) external onlyOwner {
      blacklistedUsers[_owner] = false;
  }

    function emergencyTokenWithdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance );
    }

    //This is to remove the native currency of the network (e.g. ETH, BNB, MATIC, etc.)
    function emergencyWithdraw() public onlyOwner nonReentrant {
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

     receive() external payable {}
    


   
}