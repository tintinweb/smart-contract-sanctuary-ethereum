// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

// importing the main Crypto Monkey NFT contract
import "./IMonkeyContract.sol";
// preparing for some functions to be restricted 
import "@openzeppelin/contracts/access/Ownable.sol";
// preparing safemath to rule out over- and underflow  
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// importing openzeppelin script to guard against re-entrancy
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// importing openzeppelin script to make contract pausable
import "@openzeppelin/contracts/security/Pausable.sol";

contract MonkeyMarketplace is Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;
  
  // STATE VARIABLES

  // interface of main Crypto Monkey NFT contract
  IMonkeyContract private _monkeyContractInterface;
  // contract address of main contract will be saved here (set by constructor)
  address public savedMainContractAddress;  

  // general event for market transactions
  event MarketTransaction(string TxType, address owner, uint256 tokenId);

  // specific event just for successful sales
  event MonkeySold (address seller, address buyer, uint256 price, uint256 tokenId); 

  // "blueprint" for sell offers
  // index refers to the offer's position in the offersArray
  struct Offer {
    address payable seller;
    uint256 price;
    uint256 index;
    uint256 tokenId;    
    bool active;
  }

  // Array of all offers
  // can be queried by onlyOwner via showOfferArrayEntry
  Offer[] private offersArray; 

  // Mapping of Token ID to its active offer (if it has one)
  mapping (uint256 => Offer) tokenIdToOfferMapping;    

  // setting and saving the main Crypto Monkey contract's address, (also calling the contract and checking address) 
  constructor (address _constructorMonkeyContractAddress) {
    _monkeyContractInterface = IMonkeyContract(_constructorMonkeyContractAddress);
    require(_monkeyContractInterface.getMonkeyContractAddress() == _constructorMonkeyContractAddress, "CONSTRUCTOR: Monkey contract address must be the same.");
    savedMainContractAddress = _constructorMonkeyContractAddress; 
  } 
 
  // contract can be paused by onlyOwner
  function pause() public onlyOwner {
    _pause();
  }

  // contract can be unpaused by onlyOwner
  function unpause() public onlyOwner {
    _unpause();
  }

  // to check whether a NFT is on sale at the moment
  function isTokenOnSale(uint256 _tokenId) public view returns (bool tokenIsOnSale) {
    return (
      tokenIdToOfferMapping[_tokenId].active
    );
  }
  
  // Get the details about an offer for _tokenId. Throws an error if there is no active offer for _tokenId.  
  function getOffer(uint256 _tokenId) public view returns (
    address seller,
    uint256 price,
    uint256 index,
    uint256 tokenId,
    bool active
    )
  {
    require (tokenIdToOfferMapping[_tokenId].active, "Market: No active offer for this tokenId.");

    Offer memory offer = tokenIdToOfferMapping[_tokenId]; 
    return (
    offer.seller,
    offer.price,
    offer.index, 
    offer.tokenId,
    offer.active       
    );
  }

  /**
  * Get all tokenId's that are currently for sale. 
  * Returns an empty array if none exist.
  * adds a Token ID to the 'result' array each time the loop finds an active offer in the offersArray  
  */
  function getAllTokenOnSale() public view returns(uint256[] memory listOfTokenIdsOnSale) {  

    // counting active offers, needed to create correct hardcoded length of 'result' array
    uint256 numberOfActiveOffers;
    
    // looking through offersArray at each postion
    for (uint256 actCount = 0; actCount < offersArray.length; actCount++) {

      // each time an active offer is found, numberOfActiveOffers is increased by 1
      if (offersArray[actCount].active) {
        numberOfActiveOffers++;
      }
    }     

    // if no active offers are found, an empty array is returned
    if (numberOfActiveOffers == 0){
      return new uint256[](0);
    }
    // looking again through offersArray at each postion
    else {
      // 'result' array with hardcoded length, defined by active offers found above
      uint256[] memory result = new uint256[](numberOfActiveOffers);      

      // index position in result array
      uint256 newIndex = 0 ;

      for (uint256 k = 0; k < offersArray.length; k++) {
        
        // each time an active offer is found, its tokenId is put into the next position in the 'result' array
        if (offersArray[k].active) {
          result[newIndex] = offersArray[k].tokenId;
          newIndex++;
        }         
      }
      // returning result array
      return result; 

    }
   
  }

  /**
  * Creates a new offer for _tokenId for the price _price.
  * Emits the MarketTransaction event with txType "Create offer"
  * Requirement: Only the owner of _tokenId can create an offer.
  * Requirement: There can only be one active offer for a token at a time.
  * Requirement: Marketplace contract (this) needs to be an approved operator when the offer is created.
  */    
  function setOffer(uint256 _price, uint256 _tokenId) public whenNotPaused {    
    //Only the owner of _tokenId can create an offer.
    require( _monkeyContractInterface.ownerOf(_tokenId) == _msgSender(), "Only monkey owner can set offer for this tokenId" );
    //Marketplace contract (this) needs to be an approved operator when the offer is created.
    require( _monkeyContractInterface.isApprovedForAll(_msgSender(), address(this)), "Marketplace address needs operator status from monkey owner." );
    //Offer price must be greater than 0
    require(_price >= 1000000000000, "offer price must be at least 1000000000000 WEI, i.e. 0.000001 ETH ");
    // checking the entry for this Token ID in the tokenIdToOfferMapping
    Offer memory tokenOffer = tokenIdToOfferMapping[_tokenId];

    // There can only be one active offer for a token at a time. 
    // If active offer exists for this Token ID, seller and price are updated.
    if (tokenOffer.active == true) {
      offersArray[tokenOffer.index].seller = payable(_msgSender());
      offersArray[tokenOffer.index].price = _price;   
    }
    else {
      // If no active offer is found, a new offer is created from the Offer struct "blueprint".
      Offer memory _newOffer = Offer({
        seller: payable(_msgSender()),
        price: _price,
        tokenId: _tokenId,      
        active: true,
        index: offersArray.length  
      });

      // saving new offer (it's a struct) to mapping 
      tokenIdToOfferMapping[_tokenId] = _newOffer;    
      // adding new offer (it's a struct) to array of offers
      offersArray.push(_newOffer);  
    }  
    // emitting event for offer creation
    emit MarketTransaction("Create offer", _msgSender(), _tokenId);
  }

  /**
  * Removes an existing offer.
  * Emits the MarketTransaction event with txType "Remove offer"
  * Requirement: Only the seller of _tokenId can remove an offer.
  */
  function removeOffer(uint256 _tokenId) public whenNotPaused {
    // checking the entry for this Token ID in the tokenIdToOfferMapping
    Offer memory tokenOffer = tokenIdToOfferMapping[_tokenId];
    // Active offer must be present
    require(tokenOffer.active == true, "Market: No active offer for this tokenId." );
    //  Only the owner of _tokenId can delete an offer.
    require(tokenOffer.seller == _msgSender(), "You're not the owner");    
    // setting array entry inactive
    offersArray[tokenOffer.index].active = false;
    // deleting mapping entry
    delete tokenIdToOfferMapping[_tokenId];      
    // emitting event for offer removal
    emit MarketTransaction("Remove offer", _msgSender(), _tokenId);    
  }

  /**
  * Executes the purchase of _tokenId.
  * Sends the funds to the seller and transfers the token using transfer in Monkeycontract.   
  * Emits the MarketTransaction event with txType "Buy".
  * Requirement: The msg.value needs to equal the price of _tokenId
  * Requirement: There must be an active offer for _tokenId
  */
  function buyMonkey(uint256 _tokenId) public payable nonReentrant whenNotPaused{    
    // checking the entry for this Token ID in the tokenIdToOfferMapping
    Offer memory tokenOffer = tokenIdToOfferMapping[_tokenId];
    // Active offer must be present
    require(tokenOffer.active == true, "Market: No active offer for this tokenId. TEST" );
    // sent value must be equal to price
    require(tokenOffer.price == msg.value, "Market: Not sending the correct amount."); 

    // saving seller before deleting mapping entry           
    address payable _oldOwner = tokenOffer.seller;

    // deactivating offer by setting array entry inactive
    offersArray[tokenOffer.index].active = false;

    // deleting offer mapping entry
    delete tokenIdToOfferMapping[_tokenId];    

    // transferring the NFT
    _monkeyContractInterface.transferNFT(_oldOwner, _msgSender(), _tokenId);  

    // transferring sent funds to _oldOwner
    _oldOwner.transfer(msg.value);

    // emitting events
    emit MarketTransaction("Buy", _msgSender(), _tokenId);
    emit MonkeySold (_oldOwner, _msgSender(), msg.value, _tokenId);
  }

  // onlyOwner can check the length of offersArray
  function showLengthOfOffersArray() public view onlyOwner returns(uint256 length) {
    return offersArray.length;
  }
  
  // onlyOwner can check entries in the offersArray 
  function showOfferArrayEntry(uint256 arrayPosition) public view onlyOwner returns(address seller, uint256 price, uint256 index, uint256 tokenId, bool active) { 
    Offer memory offer = offersArray[arrayPosition]; 
    return (
    offer.seller,
    offer.price,
    offer.index, 
    offer.tokenId,
    offer.active       
    );    
  }  

  // function for owner to withdraw any ETH that has accumulated in this contract
  function withdrawETH () public onlyOwner {
    address payable receiver = payable(_msgSender());
    receiver.transfer(address(this).balance);
  }     
   
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMonkeyContract is IERC721Enumerable{
  
  // Creation event, emitted after successful NFT creation with these parameters
  event MonkeyCreated(
    address owner,
    uint256 tokenId,
    uint256 parent1Id,
    uint256 parent2Id,
    uint256 genes
  );
  
  // Breeding event, emitted after successful NFT breeding with these parameters
  event BreedingSuccessful (
    uint256 tokenId, 
    uint256 genes, 
    uint256 birthtime, 
    uint256 parent1Id, 
    uint256 parent2Id, 
    uint256 generation, 
    address owner
  );  

  // public function to show contract's own address
  function getMonkeyContractAddress() external view returns (address);
  
  /// * @dev combining two owned NFTs creates a new third one
  /// * @dev needs BananaToken, available from faucet in BananaToken.sol
  /// * @dev returns the Token ID of the new CryptoMonkey NFT 
  /// * @param _parent1Id The Token ID of the first "parent" CryptoMonkey NFT 
  /// * @param _parent2Id TThe Token ID of the second "parent" CryptoMonkey NFT
  
  function breed(uint256 _parent1Id, uint256 _parent2Id) external returns (uint256);
  
  // Function to mint demo Monkey NFTs with hardcoded generation 99
  // needs BananaToken, available from faucet in BananaToken.sol
  function createDemoMonkey(
    uint256 _genes,
    address _owner
  ) external returns (uint256);

  // returns all the main details of a CryptoMonkey NFT
  function getMonkeyDetails(address _owner) external view returns(
    uint256 genes,
    uint256 birthtime,
    uint256 parent1Id,
    uint256 parent2Id,
    uint256 generation,
    address owner,
    address approvedAddress
  );

  // returns an array with the NFT Token IDs that the provided sender address owns
  function findMonkeyIdsOfAddress(address sender) external view returns (uint256[] memory); 
  
  /// * @dev Assign ownership of a specific CryptoMonkey NFT to an address.
  /// * @dev This poses no restriction on msg.sender
  /// * @dev Once onlyOwner has connected a market (_marketConnected true), NFTs cannot be sent via this function while on sale 
  /// * @param _from The address from who to transfer from, can be 0 for creation of a monkey
  /// * @param _to The address to who to transfer to, cannot be 0 address
  /// * @param _tokenId The Token ID of the transferring CryptoMonkey NFT  
  function transferNFT(address _from, address _to, uint256 _tokenId) external;

  // overriding ERC721's function, including whenNotPaused for added security
  function transferFrom(address from, address to, uint256 tokenId) external override;

  // overriding ERC721's function, including whenNotPaused for added security
  function safeTransferFrom(address from, address to, uint256 tokenId) external override;

  // overriding ERC721's function, including whenNotPaused for added security
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external override;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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