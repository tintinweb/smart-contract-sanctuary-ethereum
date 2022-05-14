// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/ether-tree/TheForest.sol)
// https://omnuslab.com/ethertree
// https://ethertree.org

// EtherTree 100 total supply ERC721

/**
*
* @dev EtherTree
*
* Distribution contract for the ether tree project. This token implements a few innovations:
* - Pre minted token supply. The total supply was minted on contract creation (which saves gas). 
* - All metadata is revealed, opensea site is up etc. so people know exactly what they are buying in to.
* - Which creates the issue of random assignment, which is solved by RandomlyAlloacted and IceRing, in their first mainnet incarnation.
*   For more details see  https://omnuslab.com/RandomlyAllocated and https://omnuslab.com/IceRing
*/

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@omnus/contracts/token/RandomlyAllocated/RandomlyAllocatedEtherTree.sol"; 

/**
*
* @dev Contract implements RandomlyAllocated and IceRing (which is in RandomlyAllocated)
*
*/
contract TheForest is Ownable, RandomlyAllocated, IERC721Receiver {

  IERC721 public immutable etherTree; 
  IERC721 public immutable wassiesByWassies;
  address payable public immutable etherTreesury; 
  address public immutable ice; 
  address public immutable oat; 

  uint256 public constant PRICE        =  5000000000000000; // 0.005 eth
  uint256 public constant WASSIE_PRICE =  1000000000000000; // 0.001 eth

  mapping(address => bool) private youveGotOneAlready;

  constructor(address etherTree_, address wassiesByWassies_, address payable etherTreesury_, address ice_, address oat_) 
    RandomlyAllocated(100, oat_, ice_, 0, 0, 0) {
    
    etherTree = IERC721(etherTree_);
    wassiesByWassies = IERC721(wassiesByWassies_);
    etherTreesury = etherTreesury_;
    ice = ice_;
    oat = oat_;
  }

  /**
  *
  * @dev Events
  *
  */
  event EthWithdrawal(uint256 indexed withdrawal);

  /**
  *
  * @dev Do not accept random calls:
  *
  */
  
  receive() external payable {
    revert();
  }

  fallback() external payable {
    revert();
  }

  /** 
  *
  * @dev owner can withdraw eth to treasury:
  *
  */ 
  function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
    (bool success, ) = etherTreesury.call{value: _amount}("");
    require(success, "Transfer failed.");
    emit EthWithdrawal(_amount);
    return true;
  }

  /**
  *
  * @dev claimTree
  *
  */
  function claimTree(bool wassie) payable external {

    uint256 requiredPrice;
    if (wassie) {
      requiredPrice = WASSIE_PRICE;
    }
    else {
      requiredPrice = PRICE;
    }

    bool isEligible;
    string memory reason;

    (isEligible, reason) = canClaimATree(wassie, msg.value, requiredPrice);

    require(isEligible, reason);

    // Send them their randomly selected tree!
    etherTree.safeTransferFrom(address(this), msg.sender, _getItem(0));

    youveGotOneAlready[msg.sender] = true;

  }

  /**
  *
  * @dev canClaimATree - check is the caller address is eligible
  *
  */
  function canClaimATree(bool wassie, uint256 payment, uint256 price) public view returns(bool isEligible, string memory message) {

    // 1) See if they have already claimed one - it's one per address:
    if (youveGotOneAlready[msg.sender]) {
      return(false, "Hey, one each please!");
    }

    // 2) Check passed payment:
    if (payment != price) {
      return(false, "Incorrect ETH amount passed.");
    }

    // 3) If claiming to be a wassie, check for a wassie:
    if (wassie && wassiesByWassies.balanceOf(msg.sender) < 1) {
      return(false, "Must have a wassie for this price. Pay normie price, or checkout yellowbird.ethertree.org");
    }

    // 3) If claiming to not be a wassie, check for a wassie:
    if (!wassie && wassiesByWassies.balanceOf(msg.sender) > 0) {
      return(false, "You have a wassie! Press the other button it's cheaper!");
    }

    // 4) We got here? Good to go:
    return(true, "");

  }

  /**
  *
  * @dev onERC721Received: Always returns `IERC721Receiver.onERC721Received.selector`. We need this to custody NFTs on the contract:
  *
  */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) external virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/RandomlyAllocated/RandomlyAllocated.sol)
// https://omnuslab.com/randomallocation

// RandomlyAllocated (Allocate the items in a fixed length collection, calling IceRing to randomly assign each ID.

pragma solidity ^0.8.13;

/**
*
* @dev RandomlyAllocated
*
* This contract extension allows the selection of items from a finite collection, each selection using the IceRing
* entropy source and removing the assigned item from selection. Intended for use with random token mints etc.
*
*/

import "@openzeppelin/contracts/utils/Context.sol";  
import "@omnus/contracts/entropy/IceRing.sol";

/**
*
* @dev Contract module which allows children to randomly allocated items from a decaying array.
* You must pass in:
* 1) The length of the collection you wish to select from (e.g. 1,000)
* 2) The IceRing contract address for this chain.
* 3) The ERC20Payable contract acting as relay.
* 
* The contract will pass back the item from the array that has been selected and remove that item from the array,
* hence you have a decaying list of items to select from.
*
*/

abstract contract RandomlyAllocated is Context, IceRing {

  // The parent array holds an index addressing each of the underlying 32 entry uint8 children arrays. The number of each
  // entry in the parentArray denotes how many times 32 we elevate the number in the child array when it is selected, with 
  // each child array running from 0 to 32 (one slot). For example, if we have parentArray 4 then every number in childArray
  // 4 is elevated by 4*32, position 0 in childArray 4 therefore representing number 128 (4 * 32 + 0)
  uint16[] public parentArray; 
  // Mapping of parentArray to childArray:
  mapping (uint16 => uint8[]) childArray;

  uint256 public continueLoadFromArray;
  
  uint256 public immutable entropyMode;
  
  // In theory this approach could handle a collection of 2,097,120 items. But as that would required 65,535 parentArray entries
  // we would need to load these items in batches. Set a notional parent array max size of 1,600 items, which gives a collection
  // max size of 51,200 (1,600 * 32):
  uint256 private constant COLLECTION_LIMIT = 51200; 
  // Each child array holds 32 items (1 slot wide):
  uint256 private constant CHILD_ARRAY_WIDTH = 32;
  // Max number of child arrays that can be loaded in one block
  uint16 private constant LOAD_LIMIT = 125;
  // Save a small amount of gas by holding these values as constants:
  uint256 private constant EXPONENT_18 = 10 ** 18;
  uint256 private constant EXPONENT_36 = 10 ** 36;

  /**
  *
  * @dev must be passed supply details, ERC20 payable contract and ice contract addresses, as well as entropy mode and fee (if any)
  *
  */
  constructor(uint16 supply_, address ERC20SpendableContract_, address iceContract_, uint256 entropyMode_, uint256 ethFee_, uint256 oatFee_)
    IceRing(ERC20SpendableContract_, iceContract_, ethFee_, oatFee_) {
    
    require(supply_ < (COLLECTION_LIMIT + 1),"Max supply of 51,200");

    entropyMode = entropyMode_;

    uint256 numberOfParentEntries = supply_ / CHILD_ARRAY_WIDTH;

    uint256 finalChildWidth = supply_ % CHILD_ARRAY_WIDTH;

    // If the supply didn't divide perfectly by the child width we have a remainder child at the end. We will load this now
    // so that all subsequent child loads can safely assume a full width load:
    if (finalChildWidth != 0) {

      // Set the final child array now:
      // Exclude 98 (yellow bird) as that is available for free at yellowbird.ethertree.org:
      childArray[uint16(numberOfParentEntries)] = [0,1,3];

      // Add one to the numberOfParentEntries to include the finalChild (as this will have been truncated off the calc above):
      numberOfParentEntries += 1;

    }

    // Now load the parent array:
    for(uint256 i = 0; i < numberOfParentEntries;) {
      parentArray.push(uint16(i));
      unchecked{ i++; }
    }

    // Load complete, all set up and ready to go.
  }

  /**
  *
  * @dev View total remaining items left in the array
  *
  */
  function remainingParentItems() external view returns(uint256) {
    return(parentArray.length);
  }

  /**
  *
  * @dev View parent array
  *
  */
  function parentItemsArray() external view returns(uint16[] memory) {
    return(parentArray);
  }

  /**
  *
  * @dev View items array
  *
  */
  function childItemsArray(uint16 index_) external view returns(uint8[] memory) {
    return(childArray[index_]);
  }

  /**
  *
  * @dev View total remaining IDs
  *
  */
  function countOfRemainingIds() external view returns(uint256 totalRemainingIds) {
        
    for (uint16 i = 0; i < parentArray.length; i++) {
      // A child array with a length of 0 means that this entry in the parent array has yet to 
      // have the child array created. If the child array was fully depleted to 0 Ids the parent
      // array will have been deleted. Therefore a parent array with no corresponding child array
      // needs to increase the total count by the full 32 items that will be loaded into the child
      // array when it is instantiate.
      if (childArray[i].length == 0) {
        totalRemainingIds += 32;
      }
      else {
        totalRemainingIds += uint256(childArray[i].length);
      }
    }
          
    return(totalRemainingIds);
  }

  /**
  *
  * @dev Allocate item from array:
  *
  */
  function _getItem(uint256 accessMode_) internal returns(uint256 allocatedItem_) { //mode: 0 = light, 1 = standard, 2 = heavy
    
    require(parentArray.length != 0, "ID allocation exhausted");

    // Retrieve a uint256 of entropy from IceRing. We will use separate parts of this entropy uint for number in range
    // calcs for array selection:
    uint256 entropy = _getEntropy(accessMode_);

    // First select the entry from the parent array, using the left most 18 entropy digits:
    uint16 parentIndex = uint16(((entropy % EXPONENT_18) * parentArray.length) / EXPONENT_18);

    uint16 parent = parentArray[parentIndex];

    // Check if we need to load the child (we will the first time it is accessed):
    if (childArray[parent].length == 0) {
      // Exclude blueberrybird5:
      if (parent == 0) {
        childArray[parent] = [0,1,2,3,4,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];  
      }
      else {
        childArray[parent] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
      }  
    }

    // Select the item from the child array, using the a different 18 entropy digits, and add on the elevation factor from the parent:
    uint256 childIndex = (((entropy % EXPONENT_36) / EXPONENT_18) * childArray[parent].length) / EXPONENT_18;
    
    allocatedItem_ = uint256(childArray[parent][childIndex]) + (parent * CHILD_ARRAY_WIDTH);

    // Pop this item from the child array. First set the last item index:
    uint256 lastChildIndex = childArray[parent].length - 1;

    // When the item to remove from the array is the last item, the swap operation is unnecessary
    if (childIndex != lastChildIndex) {
      childArray[parent][childIndex] = childArray[parent][lastChildIndex];
    }

    // Remove the last position of the array:
    childArray[parent].pop();

    // Check if the childArray is no more:
    if (childArray[parent].length == 0) {
      // Remove the parent as the child allocation is exhausted. First set the last index:
      uint256 lastParentIndex = parentArray.length - 1;

      // When the item to remove from the array is the last item, the swap operation is unnecessary
      if (parentIndex != lastParentIndex) {
        parentArray[parentIndex] = parentArray[lastParentIndex];
      }

      parentArray.pop();

    }

    return(allocatedItem_);
  }

  /**
  *
  * @dev Retrieve Entropy
  *
  */
  function _getEntropy(uint256 accessMode_) internal returns(uint256 entropy_) { 
    
    // Access mode of 0 is direct access, ETH payment may be required:
    if (accessMode_ == 0) { 
      if (entropyMode == 0) entropy_ = (_getEntropyETH(ENTROPY_LIGHT));
      else if (entropyMode == 1) entropy_ = (_getEntropyETH(ENTROPY_STANDARD));
      else if (entropyMode == 2) entropy_ = (_getEntropyETH(ENTROPY_HEAVY));
      else revert("Unrecognised entropy mode");
    }
    // Access mode of 0 is token relayed access, OAT payment may be required:
    else {
      if (entropyMode == 0) entropy_ = (_getEntropyOAT(ENTROPY_LIGHT));
      else if (entropyMode == 1) entropy_ = (_getEntropyOAT(ENTROPY_STANDARD));
      else if (entropyMode == 2) entropy_ = (_getEntropyOAT(ENTROPY_HEAVY));
      else revert("Unrecognised entropy mode");
    }

    return(entropy_);

  }

  /**
  *
  * @dev _loadChildren: Optional function that can be used to pre-load child arrays. This can be used to shift gas costs out of
  * execution by pre-loading some or all of the child arrays.
  *
  */
  function _loadChildren() internal {

    require(continueLoadFromArray < parentArray.length, "Load Children: load already complete");
        
    // Determine how many arrays we will be checking and loading on this call:
    uint256 loadUntil;

    // Example: Parent array length is 300 (index 0 to 299). On the first call to this function
    // the storage var continueLoadFromArray will be 0. Therefore the statement below will be
    // if (300 - 0) > 125, which it is. We therefore set loadUntil to 0 + 125 (the load limit)
    // which is 125.
    // On the second call to this function continueLoadFromArray will be 125 (we set it to the loadUntil
    // value at the end of this function). (300 - 125) is 175, so still greater than the load limit of 125.
    // We therefore set loadUntil to 125 + 125 = 250.
    // On the third call to this function continueLoadFromArray will be 250. (300 - 250) = 50, which is less 
    // that our load limit. We therefore set loadUntil to the length of the parent array, which is 300. Note
    // that when processing the parent array items we terminate the look when i < loadUntil, meaning that in 
    // are example we will load index 0 all the way to 299, which is as it should be.
    if ((parentArray.length - continueLoadFromArray) > LOAD_LIMIT) {
      loadUntil = continueLoadFromArray + LOAD_LIMIT;
    }
    else {
      loadUntil = parentArray.length;
    }

    for(uint256 i = continueLoadFromArray; i < loadUntil;) {
      if (childArray[uint16(i)].length == 0) {
        childArray[uint16(i)] = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
      }
      unchecked{ i++; }
    }

    continueLoadFromArray = loadUntil;

  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/entropy/IceRing.sol)
// https://omnuslab.com/icering

// ICERiNG (In Chain Entropy - Randomised Number Generator)

pragma solidity ^0.8.13;

/**
* @dev ICE - In-Chain Entropy
*
* This protocol generates in-chain entropy (OK, ON-chain not in-chain, but that didn't make a cool acronym...).
* Solidity and blockchains are deterministic, so standard warnings apply, this produces pseudorandomness. For very strict levels of 
* randomness the answer remains to go off-chain, but that carries a cost and also introduces an off-chain dependency that could fail or,
* worse, some day be tampered with or become vulnerable. 
* 
* The core premise of this protocol is that we aren't chasing true random (does that even exist? Philosophers?). What we are chasing 
* is a source or sources of entropy that are unpredictable in that they can't practically be controlled or predicted by a single entity.
*
* A key source of entropy in this protocol is contract balances, namely the balances of contracts that change with every block. Think large 
* value wallets, like exchange wallets. We store a list of these contract addresses and every request combine the eth value of these addresses
* with the current block time and a modulo and hash it. 
* 
* Block.timestamp has been used as entropy before, but it has a significant drawback in that it can be controlled by miners. If the incentive is
* high enough a miner could look to control the outcome by controlling the timestamp. 
* 
* When we add into this a variable contract balance we require a single entity be able to control both the block.timestamp and, for example, the 
* eth balance of a binance hot wallet. In the same block. To make it even harder, we loop through our available entropy sources, so the one that
* a transaction uses depends on where in the order we are, which depends on any other txns using this protocol before it. So to be sure of the 
* outcome an entity needs to control the block.timestamp, either control other txns using this in the block or make sure it's the first txn in 
* the block, control the balance of another parties wallet than changes with every block, then be able to hash those known variables to see if the
* outcome is a positive one for them. Whether any entity could achieve that is debatable, but you would imagine that if it is possible it 
* would come at significant cost.
*
* The protocol can be used in two ways: to return a full uin256 of entropy or a number within a given range. Each of these can be called in light,
* standard or heavy mode:
*   Light    - uses the balance of the last contract loaded into the entropy list for every generation. This reduces storage reads
*              at the disadvantage of reducing the variability of the seed.
*   Standard - increments through our list of sources using a different one as the seed each time, returning to the first item at the end of the 
*              loop and so on.
*   Heavy    - creates a hash of hashes using ALL of the entropy seed sources. In principle this would require a single entity to control both
*              the block timestamp and the precise balances of a range of addresses within that block. 
*
*                                                             D I S C L A I M E R
*                                                             ===================    
*                   Use at your own risk, obvs. I've tried hard to make this good quality entropy, but whether random exists is
*                   a question for philosophers not solidity devs. If there is a lot at stake on whatever it is you are doing 
*                   please DYOR on what option is best for you. There are no guarantees the entropy seeds here will be maintained
*                   (I mean, no one might ever use this). No liability is accepted etc.
*/

import "@openzeppelin/contracts/utils/Context.sol";  
import "@omnus/contracts/token/ERC20Spendable/IERC20Spendable.sol";
import "@omnus/contracts/entropy/IIce.sol"; 

/**
*
* @dev - library contract for Ice access
*
*/
abstract contract IceRing is Context {

  uint256 constant NUMBER_IN_RANGE_LIGHT = 0;
  uint256 constant NUMBER_IN_RANGE_STANDARD = 1;
  uint256 constant NUMBER_IN_RANGE_HEAVY = 2;
  uint256 constant ENTROPY_LIGHT = 3;
  uint256 constant ENTROPY_STANDARD = 4;
  uint256 constant ENTROPY_HEAVY = 5;
  
  uint256 public ethFee;
  uint256 public oatFee;

  IERC20Spendable public immutable ERC20SpendableContract; 
  address public immutable IceAddress; 
  IIce public immutable IceContract;

  event ETHFeeUpdated(uint256 oldFee, uint256 newFee);
  event OATFeeUpdated(uint256 oldFee, uint256 newFee);

  /**
  *
  * @dev - Constructor - both the ICE contract and the ERC20Spendable contract need to be provided:
  *
  */
  constructor(address _ERC20SpendableContract, address _IceAddress, uint256 _ethFee, uint256 _oatFee) {
    ERC20SpendableContract = IERC20Spendable(_ERC20SpendableContract); 
    IceAddress = _IceAddress;
    IceContract = IIce(IceAddress);
    ethFee = _ethFee;
    oatFee = _oatFee;
  }


  /**
  *
  * @dev Update fee. Implement an external call that calls this in child contract, likely ownerOnly.
  *
  */
  function _updateETHFee(uint256 _ethFee) internal {
    uint256 oldETHFee = ethFee;
    ethFee = _ethFee;
    emit ETHFeeUpdated(oldETHFee, _ethFee);
  }

  /**
  *
  * @dev Update fee. Implement an external call that calls this in child contract, likely ownerOnly.
  *
  */
  function _updateOATFee(uint256 _oatFee) internal {
    uint256 oldOATFee = oatFee;
    oatFee = _oatFee;
    emit OATFeeUpdated(oldOATFee, oatFee);
  }

  /**
  *
  * @dev Get entropy, access direct:
  *
  */
  function _getEntropyETH(uint256 _mode) internal returns(uint256 ice_) {

    (bool success, uint256 result) = IceContract.iceRingEntropy{value: ethFee}(_mode);
    
    require(success, "Ice call failed"); 

    return(result);
  }

  /**
  *
  * @dev Get number in range, access direct:
  *
  */
  function _getNumberInRangeETH(uint256 _mode, uint256 _upperBound) internal returns(uint256 ice_) {

    (bool success, uint256 result) = IceContract.iceRingNumberInRange{value: ethFee}(_mode, _upperBound);
    
    require(success, "Ice call failed"); 

    return(result);
  }

  /**
  *
  * @dev Get entropy, access through the ERC20 payable relay:
  *
  */
  function _getEntropyOAT(uint256 _mode) internal returns(uint256 ice_) {

    uint256[] memory arguments = new uint256[](1);
    arguments[0] = _mode;

    ice_ = ERC20SpendableContract.spendToken(IceAddress, oatFee, arguments)[0]; 

    return(ice_);
  }
  
  /**
  *
  * @dev Get number in range, access through the ERC20 payable relay:
  *
  */
  function _getNumberInRangeOAT(uint256 _mode, uint256 _upperBound) internal returns(uint256 ice_) {

    uint256[] memory arguments = new uint256[](2);
    arguments[0] = _mode;
    arguments[1] = _upperBound;

    ice_ = ERC20SpendableContract.spendToken(IceAddress, oatFee, arguments)[0]; 

    return(ice_);
  }

}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/entropy/IIce.sol)
// https://omnuslab.com/icering

// IIce (In Chain Entropy - Interface)

pragma solidity ^0.8.13;

/**
* @dev ICE - In-Chain Entropy
*
* This protocol generates in-chain entropy (OK, ON-chain not in-chain, but that didn't make a cool acronym...).
* Solidity and blockchains are deterministic, so standard warnings apply, this produces pseudorandomness. For very strict levels of 
* randomness the answer remains to go off-chain, but that carries a cost and also introduces an off-chain dependency that could fail or,
* worse, some day be tampered with or become vulnerable. 
* 
* The core premise of this protocol is that we aren't chasing true random (does that even exist? Philosophers?). What we are chasing 
* is a source or sources of entropy that are unpredictable in that they can't practically be controlled or predicted by a single entity.
*
* A key source of entropy in this protocol is contract balances, namely the balances of contracts that change with every block. Think large 
* value wallets, like exchange wallets. We store a list of these contract addresses and every request combine the eth value of these addresses
* with the current block time and a modulo and hash it. 
* 
* Block.timestamp has been used as entropy before, but it has a significant drawback in that it can be controlled by miners. If the incentive is
* high enough a miner could look to control the outcome by controlling the timestamp. 
* 
* When we add into this a variable contract balance we require a single entity be able to control both the block.timestamp and, for example, the 
* eth balance of a binance hot wallet. In the same block. To make it even harder, we loop through our available entropy sources, so the one that
* a transaction uses depends on where in the order we are, which depends on any other txns using this protocol before it. So to be sure of the 
* outcome an entity needs to control the block.timestamp, either control other txns using this in the block or make sure it's the first txn in 
* the block, control the balance of another parties wallet than changes with every block, then be able to hash those known variables to see if the
* outcome is a positive one for them. Whether any entity could achieve that is debatable, but you would imagine that if it is possible it 
* would come at significant cost.
*
* The protocol can be used in two ways: to return a full uin256 of entropy or a number within a given range. Each of these can be called in light,
* standard or heavy mode:
*   Light    - uses the balance of the last contract loaded into the entropy list for every generation. This reduces storage reads
*              at the disadvantage of reducing the variability of the seed.
*   Standard - increments through our list of sources using a different one as the seed each time, returning to the first item at the end of the 
*              loop and so on.
*   Heavy    - creates a hash of hashes using ALL of the entropy seed sources. In principle this would require a single entity to control both
*              the block timestamp and the precise balances of a range of addresses within that block. 
*
*                                                             D I S C L A I M E R
*                                                             ===================    
*                   Use at your own risk, obvs. I've tried hard to make this good quality entropy, but whether random exists is
*                   a question for philosophers not solidity devs. If there is a lot at stake on whatever it is you are doing 
*                   please DYOR on what option is best for you. No liability is accepted etc.
*/

/**
*
* @dev Implementation of the Ice interface.
*
*/

interface IIce {
  event EntropyAdded (address _entropyAddress);
  event EntropyUpdated (uint256 _index, address _newAddress, address _oldAddress); 
  event EntropyCleared (); 
  event EntropyServed(address seedAddress, uint256 seedValue, uint256 timeStamp, uint256 modulo, uint256 entropy);
  event BaseFeeUpdated(uint256 oldFee, uint256 newFee);
  event ETHExponentUpdated(uint256 oldETHExponent, uint256 newETHExponent);
  event OATExponentUpdated(uint256 oldOATExponent, uint256 newOATExponent);
  event TreasurySet(address treasury);
  event TokenWithdrawal(uint256 indexed withdrawal, address indexed tokenAddress);
  event EthWithdrawal(uint256 indexed withdrawal);

  function iceRingEntropy(uint256 _mode) external payable returns(bool, uint256 entropy_);
  function iceRingNumberInRange(uint256 _mode, uint256 _upperBound) external payable returns(bool, uint256 numberInRange_);
  function viewEntropyAddress(uint256 _index) external view returns (address entropyAddress);
  function addEntropy(address _entropyAddress) external;
  function updateEntropy(uint256 _index, address _newAddress) external;
  function deleteAllEntropy() external;
  function updateBaseFee(uint256 _newBasefee) external;
  function updateOATFeeExponent(uint256 _newOatExponent) external;
  function updateETHFeeExponent(uint256 _newEthExponent) external;
  function getConfig() external view returns(uint256 seedIndex_, uint256 counter_, uint256 modulo_, address seedAddress_, uint256 baseFee_, uint256 ethExponent_, uint256 oatExponent_);
  function getEthFee() external view returns (uint256 ethFee);
  function getOatFee() external view returns (uint256 oatFee); 
  function validateProof(uint256 _seedValue, uint256 _modulo, uint256 _timeStamp, uint256 _entropy) external pure returns(bool valid);
}

// SPDX-License-Identifier: MIT
// Omnus Contracts (contracts/token/ERC20Spendable/ISpendableERC20.sol)
// https://omnuslab.com/spendable

// IERC20Spendable - Interface definition for contracts to implement spendable ERC20 functionality

pragma solidity ^0.8.13;

/**
*
* @dev ERC20Spendable - library contract for an ERC20 extension to allow ERC20s to 
* operate as 'spendable' items, i.e. a token that can trigger an action on another contract
* at the same time as being transfered. Similar to ERC677 and the hooks in ERC777, but with more
* of an empasis on interoperability (returned values) than ERC677 and specifically scoped interaction
* rather than the general hooks of ERC777. 
*
* Interface Definition IERC20Spendable
*
*/

interface IERC20Spendable{

  /**
  *
  * @dev New function, spendToken, that allows the transfer of the owners token to the receiver, a call on the receiver, and 
  * the return of information from the receiver back up the call stack:
  *
  */
  function spendToken(address receiver, uint256 _tokenPaid, uint256[] memory _arguments) external returns(uint256[] memory);

}