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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

//  __      ________   _____           _                  _ 
//  \ \    / /  ____| |  __ \         | |                | |
//   \ \  / /| |__    | |__) | __ ___ | |_ ___   ___ ___ | |
//    \ \/ / |  __|   |  ___/ '__/ _ \| __/ _ \ / __/ _ \| |
//     \  /  | |      | |   | | | (_) | || (_) | (_| (_) | |
//      \/   |_|      |_|   |_|  \___/ \__\___/ \___\___/|_|
//      +-+-+-+-+ +-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+-+
//      |I|t|'|s| |a| |v|e|r|y| |f|u|n| |p|r|o|t|o|c|o|l|.|
//      +-+-+-+-+ +-+ +-+-+-+-+ +-+-+-+ +-+-+-+-+-+-+-+-+-+                                                                                     

// VF Protocol v0 BasicSale controller contract
// This contract manages the core smart contract logic for selling ERC721 tokens for ETH (referred to as a "Handshake")
// in a zero fee, peer to peer, permissionless, and decentralized way. This contract works in concert with an ERC721 Approve pattern implemented by
// the front end of VF Protocol. The transaction pattern assumes a Buyer and Seller have already "found" each other somewhere else and 
// now want to transact some ERC721 token for protocol (unwrapped) ETH. 
//
// It works as follows:
// 1. Seller initiates a Handshake by specifying ERC-721 Token, Price, and target Buyer (Seller is prompted in frontend to give VF Protocol "transferFrom" Approval)
// 2. Buyer now has 1 hour to accept Handshake in dApp (Accept triggers a transfer of ETH to VFProtocolv0 and ERC721 is transferred upon receipt of correct amount of ETH)
// 3. Seller withdraws ETH payment from VFProtocolv0 whenever convenient for her
// 

contract BasicSale is ReentrancyGuard, Pausable {

  event SaleInit(uint index, address seller, address buyer, uint price, address NFTContract, uint TokenID); // Logs all initiated Handshakes
  event BuyInit(uint index, address buyer, address seller, uint price, address NFTContract, uint TokenID); // Logs all accepted Handshakes
  event Withdrawals(address withdrawer, uint amountWithdrawn); //Logs all withdrawals  

  address private owner; // Authorized wallet for emergency withdrawals - hard code
  uint public index; // Handshake index 

// Core data structure for Handshake
  struct Sale {
    address seller; // NFT seller - set as msg.sender
    address buyer; // NFT Buyer - set by seller
    uint price; // In gwei
    uint saleInitTime; // Block.timestamp (used only for logging and expiration management)
    uint saleExpiration; // Block.timestamp + 1 hour for sale acceptance (used only for logging and expiration management)
    address nftContract; // NFT Contract - set by msg.sender via frontend UX
    uint tokenId; // NFT Contract token ID - set by msg.sender via frontend UX
    bool offerAccepted; // Triggered when buyer accepts Handshake
    bool offerCanceled; // Triggered when seller cancels Handshake
  }

  mapping (uint => Sale) sales; //Map of index : Handshakes struct <- has all transaction data inside
  mapping (address => uint) balances; //Map of seller wallet addresses : Withdrawalable ETH <- only increased by buyers accepting Handshakes 
  // Can call balanceOf to see if balance exists for wallet address

  // Set emergency multisig owner
  constructor() payable {
    owner = payable(address(0xe5D45e93d3Fb7c9f1c1F68fD7Af0b8e42C0806aB)); // Hard code owner address for emergency pause/withdrawal of errant ETH caught be "receive"
  }

  // Sets function only accessible by owner 
  modifier OnlyOwner {
    require(msg.sender == owner,"Not owner of contract");
    _;
  }

  // Emergency Pause functions only accessible by owner
  function pause() public OnlyOwner {
    _pause();
  }

// Emergency unpause functions only accessible by owner
  function unpause() public OnlyOwner {
    _unpause();
  }


  // Seller Creates Handshake with all pertinent transaction data
  function saleInit(address _buyer, uint _price, address _nftContract, uint _tokenId) public nonReentrant() whenNotPaused() {
      require(_buyer!=address(0), "Null Buyer Address");  //Checks if buyer address isn't 0 address
      require(_buyer!=msg.sender, "Seller cannot be Buyer"); //Checks if seller is buyer
      require(_price > 0, "Need non-zero price"); //Checks if price is non-zero
      require(_nftContract!=address(0), "Null Contract address"); //Checks that NFT contract isn't 0 address
      require(IERC721(_nftContract).ownerOf(_tokenId)==msg.sender, "Sender not owner or Token does not exist"); //Checks that msg.sender is token owner and if token exists 

      // Sale Struct from above
      Sale memory thisSale = Sale({
        seller: msg.sender, 
        buyer:_buyer,
        price: _price, // in GWEI
        saleInitTime: block.timestamp, // Manipulatable, but exactly 60 min isn't crucial
        saleExpiration: block.timestamp + 1 hours, // 1 hour to accept sale from Handshake creation
        nftContract: _nftContract,
        tokenId: _tokenId,
        offerAccepted: false,
        offerCanceled: false
      });

      sales[index] = thisSale; //Assign individual Handshake struct to location in handshakes mapping 
      index += 1; //Increment handshakes index for next Handshake
      emit SaleInit(index-1, msg.sender, thisSale.buyer, thisSale.price, thisSale.nftContract, thisSale.tokenId); //Emits Handshake initiation for subgraph tracking
      
      
  }

  // CAUTION: Now Approval for ERC721 transfer needs to happen with frontend interaction via JS so VFProtocolv0 contract can transfer
  
  // This is how the Buyer accepts the handshake (pass along index and send appropriate amount of ETH to VFProtocolv0)
 
  function buyInit(uint _index) public payable nonReentrant() whenNotPaused() {
    require(_index<index,"Index out of bounds"); //Checks if index exists
    require(IERC721(sales[_index].nftContract).getApproved(sales[_index].tokenId)==address(this),"Seller hasn't Approved VFP to Transfer"); //Confirms Approval pattern is met
    require(!sales[_index].offerAccepted, "Already Accepted"); // Check to ensure this Handshake hasn't already been accepted/paid
    require(!sales[_index].offerCanceled, "Offer Canceled"); // Checks to ensure seller didn't cancel offer
    require(block.timestamp<sales[_index].saleExpiration,"Time Expired"); // Checks to ensure 60 minute time limit hasn't passed
    require(sales[_index].buyer==msg.sender,"Not authorized buyer"); // Checks to ensure redeemer is whitelisted buyer
    require(msg.value==sales[_index].price,"Not correct amount of ETH"); // Checks to ensure enough ETH is sent to pay seller
    sales[_index].offerAccepted = true; // Sets acceptance to true after acceptance

    balances[sales[_index].seller] += msg.value; //Updates withdrawable ETH for seller after VFProtocolv0 receives ETH
    IERC721(sales[_index].nftContract).transferFrom(sales[_index].seller, sales[_index].buyer, sales[_index].tokenId); //Transfers NFT to buyer after payment
    emit BuyInit(_index, sales[_index].buyer,sales[_index].seller, sales[_index].price, sales[_index].nftContract, sales[_index].tokenId); //Emits Handshake Acceptance
  }

// Withdraw function for sellers to receive their payments. Seller submits index of ANY transaction on which they are seller, then runs checks and allow withdrawals
  function withdraw() external nonReentrant() whenNotPaused() {
    require(balances[msg.sender]>0,"No balance to withdraw"); //Checks if msg.sender has a balance
    uint withdrawAmount = balances[msg.sender]; //Locks withdraw amount
    balances[msg.sender] = 0; //Resets balance (Checks - Effects - Transfers pattern)
    (bool sent, bytes memory data) = payable(msg.sender).call{value: withdrawAmount}(""); //Sends ETH balance to seller
        require(sent, "Failed to send Ether"); //Reverts if it fails
    emit Withdrawals(msg.sender, withdrawAmount);
  }

  // Cancel function allows a seller to cancel handshake
  function cancel(uint _index) external  whenNotPaused() {
    require(_index<index,"Index out of bounds"); // Checks to ensure index exists
    require(sales[_index].seller==msg.sender,"Not authorized seller"); //Checks to ensure only seller can cancel Handshake
    require(sales[_index].offerAccepted==false,"Offer Already Accepted"); //Checks to ensure offer hasn't been accepted
    require(block.timestamp<sales[_index].saleExpiration,"Time Expired"); //Checks to see if time expired to avoid gas wastage
    sales[_index].offerCanceled = true;
  }

  // BalanceOf function returns the redeemable balance of a given address
  // Might make sense to only let YOU check your OWN balance? (Not sure if this is a good idea)
  function balanceOf(address requester) external view returns (uint256) {
        require(requester != address(0), "ERC721: address zero is not a valid owner");
        return balances[requester];
    }


  //Receive function to handle unknown transactions
  receive() external payable whenNotPaused() {
    balances[owner] += msg.value; //Catches stray ETH sent to contract
  } 


}