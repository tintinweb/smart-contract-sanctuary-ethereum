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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

//*~~~> SPDX-License-Identifier: MIT make it better, stronger, faster

/*~~~>
    Thank you Phunks for your inspiration and phriendship.
      Never stop phighting, never surrender, always stand up for what is right and make the best of all situations towards all people.
      Phunks are phreedom phighters!
      
      "When the power of love overcomes the love of power the world will know peace." - Jimi Hendrix <3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@PhunkyJON was here programming trustless, unstoppable [email protected](((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 <~~~*/

pragma solidity  0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IEscrow.sol";
import "./interfaces/IRewardsController.sol";
import "./interfaces/IRoleProvider.sol";

interface IERC20 {
  function transfer(address to, uint value) external returns (bool);
}

contract NFTMarket is ReentrancyGuard {

  /*~~~> 
    Roles allow for designated accessibility
  <~~~*/
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE"); 
  bytes32 public constant DEV = keccak256("DEV");

  address public roleAdd;

  modifier hasAdmin(){
    require(IRoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), "DOES NOT HAVE ADMIN ROLE");
    _;
  }
  modifier hasContractAdmin(){
    require(IRoleProvider(roleAdd).hasContractRole(msg.sender), "DOES NOT HAVE CONTRACT ROLE");
    _;
  }
  modifier hasDevAdmin(){
    require(IRoleProvider(roleAdd).hasTheRole(DEV, msg.sender), "DOES NOT HAVE DEV ROLE");
    _;
  }

  /*~~~> increments itemIds upon creation <~~~*/
  uint256 public itemIds;

  //*~~~> global address variable from Role Provider contract
  bytes32 public constant REWARDS = keccak256("REWARDS");
  
  bytes32 public constant BIDS = keccak256("BIDS");
  
  bytes32 public constant OFFERS = keccak256("OFFERS");
  
  bytes32 public constant TRADES = keccak256("TRADES");

  bytes32 public constant NFTADD = keccak256("NFT");

  /*~~~> Open storage indexes <~~~*/
  uint[] private openStorage;

  /*~~~> Minimum listing value <~~~*/
  uint public minVal;

  /*~~~> sets deployment address as default admin role <~~~*/
  constructor(address newrole) {
    roleAdd = newrole;
    minVal = 1e15;
  }

  /*~~~> Declaring object structures for listed items for sale <~~~*/
  struct MktItem {
    bool is1155;
    uint itemId;
    uint amount1155;
    uint price;
    uint tokenId;
    address nftContract;
    address payable seller;
  }

  /*~~~> Memory array of item id to market item <~~~*/
  mapping(uint256 => MktItem) private idToMktItem;
  // Maps the balance of items that the user has listed for sale
  mapping(address => uint) public addressToUserBal;

  /*~~~> Declaring event object structure for Nft Listed for sale <~~~*/
  event ItemListed (
    uint itemId,
    uint amount1155,
    uint price,
    uint indexed tokenId, 
    address indexed nftContract, 
    address indexed seller
    );

  /*~~~> Declaring event object structures for delistings <~~~*/
  event ItemDelisted(
    uint indexed itemId,
    uint indexed tokenId,
    address indexed nftContract
    );

  /*~~~> Declaring event object structures for NFTs bought <~~~*/
  event ItemBought(
    uint itemId,
    uint indexed tokenId, 
    address indexed nftContract, 
    address fromAddress, 
    address indexed toAddress
    );

  /*~~~> Declaring event object structure for Item price updated <~~~*/
  event ItemUpdated(
    uint itemId,
    uint indexed tokenId,
    uint price,
    address indexed nftContract,
    address indexed seller
  );

    //~~~> To set the minimum listing price
  function setMinimumValue(uint minWei) external hasDevAdmin returns(bool){
    minVal = minWei;
    return true;
  }

  /// @notice 
  /*~~~> Public function to list NFTs for sale <~~~*/
  ///@dev
  /*~~~>
    is1155: (true) if item is ERC1155;
    amount1155: amount of ERC1155 to trade;
    tokenId: token Id of the item to list;
    price: eth value wanted for purchase;
    nftContract: contract address of item to list on the market;
  <~~~*/
  ///@return Bool
  function listMarketItems(
    bool[] memory is1155,
    uint[] memory amount1155,
    uint[] memory tokenId,
    uint[] memory price,
    address[] memory nftContract
  ) external nonReentrant returns(bool){
    require(tokenId.length>0);
    require(tokenId.length == nftContract.length);
    uint user = addressToUserBal[msg.sender];
    if (user==0) {
        require(IRewardsController(IRoleProvider(roleAdd).fetchAddress(REWARDS)).createUser(msg.sender));
      }
    uint tokenLen = tokenId.length;
    for (uint i=0;i<tokenLen;i++){
        require(price[i] >= minVal);
        uint itemId;
        uint len = openStorage.length;
        if (len>=1){
          itemId=openStorage[len-1];
          _remove();
        } else {
          itemId = itemIds+=1;
        }
        if(!is1155[i]){
        require(transferFromERC721(nftContract[i], tokenId[i], address(this)));
        require(approveERC721(nftContract[i], address(this), tokenId[i]));
        idToMktItem[itemId] =  MktItem(false, itemId, amount1155[i], price[i], tokenId[i], nftContract[i], payable(msg.sender));
      } else {
        IERC1155(nftContract[i]).safeTransferFrom(msg.sender, address(this), tokenId[i], amount1155[i], "");
        IERC1155(nftContract[i]).setApprovalForAll(address(this), true);
        idToMktItem[itemId] =  MktItem(true, itemId, amount1155[i], price[i], tokenId[i], nftContract[i], payable(msg.sender));
      }
      emit ItemListed(itemId, amount1155[i], price[i], tokenId[i], nftContract[i], msg.sender);
    }
    //*~~~> Add new count to user balances
    addressToUserBal[msg.sender] += tokenLen;
    return true;
  }


  /// @notice 
  /*~~~> Public function to delist NFTs <~~~*/
  ///@dev
  /*~~~>
    itemId: itemId for internal storage location;
  <~~~*/
  ///@return Bool
  function delistMarketItems(
    uint256[] calldata itemId
  ) public nonReentrant returns(bool){

    address rewardsAdd = IRoleProvider(roleAdd).fetchAddress(REWARDS);
    address bidsAdd = IRoleProvider(roleAdd).fetchAddress(BIDS);
    address offersAdd = IRoleProvider(roleAdd).fetchAddress(OFFERS);
    address tradesAdd = IRoleProvider(roleAdd).fetchAddress(TRADES);

    for (uint i=0;i<itemId.length;i++){
      MktItem memory it = idToMktItem[itemId[i]];
      require(it.seller == msg.sender, "Not owner");

      uint bidId = IBids(bidsAdd).fetchBidId(itemId[i]);
      if (bidId>0) {
      /*~~~> Kill bid and refund bidValue <~~~*/
        //~~~> Call the contract to refund the ETH offered for a bid
        require(IBids(bidsAdd).refundBid(bidId));
      }
        /*~~~> Check for the case where there is a trade and refund it. <~~~*/
      uint offerId = IOffers(offersAdd).fetchOfferId(itemId[i]);
      if (offerId > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the NFT offered for trade
        require(IOffers(offersAdd).refundOffer(itemId[i], offerId));
      }
      /*~~~> Check for the case where there is an offer and refund it. <~~~*/
      uint tradeId = ITrades(tradesAdd).fetchTradeId(itemId[i]);
      if (tradeId > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the ERC20 offered for trade
        require(ITrades(tradesAdd).refundTrade(itemId[i], tradeId));
      }
      if(it.is1155){
        IERC1155(it.nftContract).safeTransferFrom(address(this), msg.sender, it.tokenId, it.amount1155, "");
      } else {
        require(transferERC721(it.nftContract, it.seller, it.tokenId));
      }
      openStorage.push(itemId[i]);
      idToMktItem[itemId[i]] =  MktItem(false, itemId[i], 0, 0, 0, address(0x0), payable(0x0));
      emit ItemDelisted(itemId[i], it.tokenId, it.nftContract);
      //*~~~> remove count from user balances
      addressToUserBal[msg.sender] -= 1;
      }
      //*~~~> Check to see if user has any remaining items listed after iteration
      if (addressToUserBal[msg.sender]==0){
        //*~~~> If not, remove them from claims allowance
          require(IRewardsController(rewardsAdd).setUser(false, msg.sender));
        } else { //*~~~> Allow claims
          require(IRewardsController(rewardsAdd).setUser(true, msg.sender));
        }
      return true;
  }

  /// @notice 
  /*~~~> Public function to buy(purchase) NFTs <~~~*/
  ///@dev
  /*~~~>
    itemId: itemId for internal storage location;
  <~~~*/
  ///@return Bool
  function buyMarketItems(
    uint256[] memory itemId
    ) public payable nonReentrant returns(bool) {
    
    address bidsAdd = IRoleProvider(roleAdd).fetchAddress(BIDS);
    address offersAdd = IRoleProvider(roleAdd).fetchAddress(OFFERS);
    address tradesAdd = IRoleProvider(roleAdd).fetchAddress(TRADES);
    address rewardsAdd = IRoleProvider(roleAdd).fetchAddress(REWARDS);

    uint balance = IERC721(IRoleProvider(roleAdd).fetchAddress(NFTADD)).balanceOf(msg.sender);
    uint prices=0;
    uint length = itemId.length;
    for (uint i=0; i < length; i++) {
      MktItem memory it = idToMktItem[itemId[i]];
      prices += it.price;
    }
    require(msg.value == prices);
    for (uint i=0; i<length; i++) {
      MktItem memory it = idToMktItem[itemId[i]];
      if(balance<1){
        /*~~~> Calculating the platform fee <~~~*/
        uint256 saleFee = calcFee(it.price);
        uint256 userAmnt = it.price - saleFee;
        // send saleFee to rewards controller
        require(sendEther(rewardsAdd, saleFee));
        // send (listed amount - saleFee) to seller
        require(sendEther(it.seller, userAmnt));
      } else {
        require(sendEther(it.seller, it.price));
      }
      if (IBids(bidsAdd).fetchBidId(itemId[i])>0) {
      /*~~~> Kill bid and refund bidValue <~~~*/
        //~~~> Call the contract to refund the ETH offered for a bid
        require(IBids(bidsAdd).refundBid(IBids(bidsAdd).fetchBidId(itemId[i])));
      }
        /*~~~> Check for the case where there is a trade and refund it. <~~~*/
      if (IOffers(offersAdd).fetchOfferId(itemId[i]) > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the NFT offered for trade
        require(IOffers(offersAdd).refundOffer(itemId[i], IOffers(offersAdd).fetchOfferId(itemId[i])));
      }
      /*~~~> Check for the case where there is an offer and refund it. <~~~*/
      if (ITrades(tradesAdd).fetchTradeId(itemId[i]) > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the ERC20 offered for trade
        require(ITrades(tradesAdd).refundTrade(itemId[i], ITrades(tradesAdd).fetchTradeId(itemId[i])));
      }
      addressToUserBal[it.seller] -= 1;
      emit ItemBought(itemId[i], it.tokenId, it.nftContract, it.seller, msg.sender);
      if(it.is1155){
        IERC1155(it.nftContract).safeTransferFrom(address(this), msg.sender, it.tokenId, it.amount1155, "");
        idToMktItem[itemId[i]] = MktItem(true, itemId[i], 0, 0, 0, address(0x0), payable(0x0));
      } else {
        require(transferERC721(it.nftContract, msg.sender, it.tokenId));
        idToMktItem[itemId[i]] = MktItem(false, itemId[i], 0, 0, 0, address(0x0), payable(0x0));
      }
      openStorage.push(itemId[i]);
      //*~~~> Check to see if user has any remaining items listed after iteration
      if (addressToUserBal[it.seller]==0){
        //*~~~> If not, remove them from claims allowance
          require(IRewardsController(rewardsAdd).setUser(false, it.seller));
        } else { //*~~~> Allow claims
          require(IRewardsController(rewardsAdd).setUser(true, it.seller));
        }
    }
    return true;
  }

  /// @notice 
    /*~~~> 
      Internal function to transferFrom ERC721 NFTs, including crypto kitties/punks
    <~~~*/
  /// @dev
    /*~~~>
      assetAddr: address of the token to be transfered;
      tokenId: Id of the token to be transfered;
      to: address of recipient;
    <~~~*/
function transferFromERC721(address assetAddr, uint256 tokenId, address to) internal virtual returns(bool) {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        // Cryptokitties.
        data = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, tokenId);
    } else if (assetAddr == punks) {
        // CryptoPunks.
        bytes memory punkIndexToAddress = abi.encodeWithSignature("punkIndexToAddress(uint256)", tokenId);
        (bool checkSuccess, bytes memory result) = address(assetAddr).staticcall(punkIndexToAddress);
        (address nftOwner) = abi.decode(result, (address));
        require(checkSuccess && nftOwner == msg.sender, "Not the NFT owner");
        data = abi.encodeWithSignature("transferPunk(address,uint256)", msg.sender, tokenId);
    } else {
        // Default.
        // We push to avoid an unneeded transfer.
        data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, to, tokenId);
    }
    (bool success, bytes memory resultData) = address(assetAddr).call(data);
    require(success, string(resultData));
    return true;
  }

  /// @notice 
    /*~~~> 
      Internal function to approve ERC721 NFTs for transfer, including crypto kitties/punks
    <~~~*/
  /// @dev
    /*~~~>
      assetAddr: address of the token to be transfered;
      to: address of recipient;
      tokenId: Id of the token to be transfered;
    <~~~*/
  function approveERC721(address assetAddr, address to, uint256 tokenId) internal virtual returns(bool) {
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == punks) {
        // CryptoPunks.
        data = abi.encodeWithSignature("offerPunkForSaleToAddress(uint256,uint256,address)", tokenId, 0, to);
        (bool success, bytes memory resultData) = address(assetAddr).call(data);
        require(success, string(resultData));
    } else {
      data = abi.encodeWithSignature("approve(address,uint256)", to, tokenId);
    }
    return(true);
  }

  /// @notice 
    /*~~~> 
      Internal function to transfer ERC721 NFTs, including crypto kitties/punks
    <~~~*/
  /// @dev
    /*~~~>
      assetAddr: address of the token to be transfered;
      to: address of the recipient;
      tokenId: Id of the token to be transfered;
    <~~~*/
  function transferERC721(address assetAddr, address to, uint256 tokenId) internal virtual returns(bool) {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        // Changed in v1.0.4.
        data = abi.encodeWithSignature("transfer(address,uint256)", to, tokenId);
    } else if (assetAddr == punks) {
        // CryptoPunks.
        data = abi.encodeWithSignature("transferPunk(address,uint256)", to, tokenId);
    } else {
        // Default.
        data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", address(this), to, tokenId);
    }
    (bool success, bytes memory returnData) = address(assetAddr).call(data);
    require(success, string(returnData));
    return true;
  }

  /// @notice 
  /*~~~> 
    Calculating the platform fee, 
      Base fee set at 2% (i.e. value * 200 / 10,000) 
      Future fees can be set by the controlling DAO 
    <~~~*/
  /// @return platform fee
  function calcFee(uint256 value) internal returns (uint256)  {
      address rewardsAdd = IRoleProvider(roleAdd).fetchAddress(REWARDS);
      uint fee = IRewardsController(rewardsAdd).getFee();
      uint256 percent = ((value * fee) / 10000);
      return percent;
    }
    
  ///@notice
  /*~~~> Function to update price, only seller can call <~~~*/
  ///@dev
  /*~~~>
    itemId: internal id of item listed for sale;
    _price: market price update
  <~~~*/
  function updateMarketItemPrice(uint itemId, uint price) external nonReentrant {
    MktItem memory it = idToMktItem[itemId];
    require(msg.sender == it.seller);
    require(price >= minVal);
    idToMktItem[it.itemId] = MktItem(it.is1155, it.itemId, price, it.amount1155, it.tokenId, it.nftContract, it.seller);
    emit ItemUpdated(itemId, it.tokenId, price, it.nftContract, it.seller);
  }

  ///@notice //*~~~> Read functions for internal contract state
  function fetchMarketItems() public view returns (MktItem[] memory) {
    uint itemCount = itemIds;
    MktItem[] memory items = new MktItem[](itemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMktItem[i + 1].itemId > 0) {
        MktItem storage currentItem = idToMktItem[i + 1];
        items[i] = currentItem;
      }
    }
    return items;
  }
  
  function fetchItemsBySeller(address userAdd) public view returns (MktItem[] memory) {
    uint itemCount = itemIds;
    MktItem[] memory items = new MktItem[](itemCount);
    for (uint i=0; i < itemCount; i++) {
      if (idToMktItem[i + 1].seller == userAdd) {
        MktItem storage currentItem = idToMktItem[i + 1];
        items[i] = currentItem;
      }
    }
    return items;
  }

  function fetchAmountListed(address userAdd) public view returns (uint howMany){
    uint user = addressToUserBal[userAdd];
    return user;
  }

  /// @notice 
  /*~~~> 
    Internal function for removing elements from an array
    Only used for internal storage array index recycling

      In order to reduce storage array size of listed items 
        while maintaining specific enumerable bidId's, 
        any sold or removed item spots are recycled by referring to their index,
        else a new storage spot is created;

        We use the last item in the storage (length of array - 1 for 0 based index position),
        in order to pop off the item and avoid rewriting 
  <~~~*/
  function _remove() internal {
      openStorage.pop();
    }

  ///@notice
  /*~~~> ERC20 withdraw ability for funds accidentally sent
    Only ETH is exchanged here, so there is no avenue for attack.
  <~~~*/
  function withdrawToken(address receiver, address tokenContract, uint256 amount) external nonReentrant hasDevAdmin returns(bool) {
    require(IERC20(tokenContract).transfer(receiver, amount));
    return true;
  }

  ///@notice internal function to transfer NFT only this contract can call
  function transferForSale(address receiver, uint itemId) internal {

    address bidsAdd = IRoleProvider(roleAdd).fetchAddress(BIDS);
    address tradesAdd = IRoleProvider(roleAdd).fetchAddress(TRADES);
    address offersAdd = IRoleProvider(roleAdd).fetchAddress(OFFERS);

    MktItem memory it = idToMktItem[itemId];
    if ( it.is1155 ){
        IERC1155(it.nftContract).safeTransferFrom(address(this), payable(receiver), it.tokenId, it.amount1155, "");
      } else {
        require(transferERC721(it.nftContract, payable(receiver), it.tokenId));
      }
      uint bidId = IBids(bidsAdd).fetchBidId(itemId);
      if (bidId>0) {
      /*~~~> Kill bid and refund bidValue <~~~*/
        //~~~> Call the contract to refund the ETH offered for a bid
        require(IBids(bidsAdd).refundBid(bidId));
      }
        /*~~~> Check for the case where there is a trade and refund it. <~~~*/
      uint offerId = IOffers(offersAdd).fetchOfferId(itemId);
      if (offerId > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the NFT offered for trade
        require(IOffers(offersAdd).refundOffer(itemId, offerId));
      }
      /*~~~> Check for the case where there is an offer and refund it. <~~~*/
      uint tradeId = ITrades(tradesAdd).fetchTradeId(itemId);
      if (tradeId > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the ERC20 offered for trade
        require(ITrades(tradesAdd).refundTrade(itemId, tradeId));
      }
      openStorage.push(itemId);
      idToMktItem[itemId] = MktItem(false, itemId, 0, 0, 0, address(0x0), payable(0x0));
      emit ItemBought(itemId, it.tokenId, it.nftContract, it.seller, receiver);
  }

  ///@notice external function to transfer NFT
  /*~~~>
    Only marketplace proxy contracts can call the function. 
  <~~~*/
  function transferNftForSale(address receiver, uint itemId) public nonReentrant hasContractAdmin returns(bool) {
    transferForSale(receiver, itemId);
    return true;
  }

  /// @notice
  /*~~~> 
    Internal function for sending ether
  <~~~*/
  /// @return Bool
  function sendEther(address recipient, uint ethvalue) internal returns (bool){
    (bool success, bytes memory data) = address(recipient).call{value: ethvalue}("");
    return(success);
  }

  //*~~~> Fallback functions
  ///@notice
  /*~~~> External ETH transfer without function call forwarded to role provider contract <~~~*/
  event FundsForwarded(uint value, address from, address to);
  receive() external payable {
    require(sendEther(roleAdd, msg.value));
    emit FundsForwarded(msg.value, msg.sender, roleAdd);
  }
  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
  function onERC721Received(
      address, 
      address, 
      uint256, 
      bytes calldata
    )external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }
}

//*~~~> SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IOffers {
  function fetchOfferId(uint marketId) external returns(uint);
  function refundOffer(uint itemID, uint offerId) external returns (bool);
}
interface ITrades {
  function fetchTradeId(uint marketId) external returns(uint);
  function refundTrade(uint itemId, uint tradeId) external returns (bool);
}
interface IBids {
  function fetchBidId(uint marketId) external returns(uint);
  function refundBid(uint bidId) external returns (bool);
}

//*~~~> SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRewardsController {
  function createNftHodler(uint tokenId) external returns (bool);
  function depositERC20Rewards(uint amount, address tokenAddress) external returns(bool);
  function getFee() external view returns(uint);
  function setFee(uint fee) external returns (bool);
  function depositEthRewards(uint reward) external payable returns(bool);
  function createUser(address userAddress) external returns(bool);
  function setUser(bool canClaim, address userAddress) external returns(bool);
}

//*~~~> SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRoleProvider {
  function hasTheRole(bytes32 role, address theaddress) external returns(bool);
  function fetchAddress(bytes32 thevar) external returns(address);
  function hasContractRole(address theaddress) external view returns(bool);
}