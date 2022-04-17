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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IRoleProvider.sol";
import "./interfaces/IEscrow.sol";

contract RewardsControl is ReentrancyGuard {

  address public roleAdd;

  //*~~~> Platform fee
  uint public fee;

  //*~~~> upgradable proxy contract addresses
  bytes32 public constant DAO = keccak256("DAO");

  bytes32 public constant NFTADD = keccak256("NFT");

  bytes32 public constant MINT = keccak256("MINT");
  

  /*~~~> Open storage indexes <~~~*/
  uint[] private openStorage;
  
  /*~~~> I envisioned, designed and initally created these contracts <~~~*/
  address private JON = 0x39a79815fA7431434E49757ED4118b873Ca1F580;
  
  /*~~~> 
    Thank you WhaleGoddess!!!
    None of this would have been possible without your patience, love and support!
    You helped me completely revise and rewrite these complex contracts into this present state, 
      but what I hold most importantly is that you took the time to hear me and debate ideas,
      to scrutinize the things out of order and be patient with me!
    Not many were able to help and I was completely alone for months, 
      but your cheerful assistance and enthusiastic nature shines brightly of what a true friend
      and compassionate human is.
   <~~~*/
  address private WHALE = 0x41538872240Ef02D6eD9aC45cf4Ff864349D51ED;
  
  uint private devCount;
  uint private userCount;
  uint private nftHodlerCount;

  uint private tokenCount;

  mapping(uint256 => User) private idToUser; //Internal index => User
  mapping(uint256 => NftHodler) private nftIdToHodler; // Tracking NFT ids => Hodler placement, to limit claims
  mapping(address => User) private addressToUser;
  mapping(address => uint256) private addressToId; //For user Id
  mapping(address => uint256) private addressToTokenId; // For token Id
  mapping(address => uint256) public addressToRewardsId;
  mapping(uint256 => RewardsToken) public idToRewardsToken;
  mapping(uint256 => DevTeam) private idToDevTeam;
  mapping(address => uint256) private addressToDevTeamId;
  mapping(uint256 => ClaimClock) private idToClock;
  
  //*~~~> Set initial ERC20 to avoid accessing an out-of-bounds or negative index
  constructor(address newRole, address getPhunky) {
    roleAdd = newRole;
    addressToTokenId[getPhunky]=1;
    fee = 200;
  }

  //*~~~> Declaring object structures for Split Rewards & Tokens <~~~*/
  struct User {
    bool canClaim;
    uint claims;
    uint timestamp;
    uint userId;
    address userAddress;
  }
  struct NftHodler {
    uint timestamp;
    uint hodlerId;
    uint tokenId;
  }
  struct DevTeam {
    uint timestamp;
    uint devId;
    address devAddress;
  }
  struct RewardsToken {
    uint tokenId;
    uint tokenAmount;
    address tokenAddress;
  }

  struct ClaimClock {
    uint alpha; // initial claim cutoff
    uint delta; // mid claim cutoff
    uint omega; // final claim cutoff
    uint howManyUsers; // total user count set with each distribution call
  }
  
  /*~~~>
    Roles for designated accessibility
  <~~~*/
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE"); 
  bytes32 public constant DEV = keccak256("DEV"); 
  modifier hasAdmin(){
    require(IRoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), "DOES NOT HAVE ADMIN ROLE");
    _;
  }
  modifier hasDevAdmin(){
    require(IRoleProvider(roleAdd).hasTheRole(DEV, msg.sender), "DOES NOT HAVE DEV ROLE");
    _;
  }
  modifier hasContractAdmin(){
    require(IRoleProvider(roleAdd).hasContractRole(msg.sender), "DOES NOT HAVE CONTRACT ROLE");
    _;
  }

  // Admin only functions to set proxy addresses
  function setRoleAddress(address newRole) external hasAdmin returns(bool){
    roleAdd = newRole;
    return true;
  }

  //*~~~> Declaring event structures
  event NewUser(uint indexed userId, address indexed userAddress);
  event RewardsClaimed(address indexed userAddress, uint amount, uint[] erc20Amount, address[] contractAddress);
  event NewDev(address indexed devAddress);
  event RemovedDev(address indexed devAddress);
  event DevClaimed(address indexed devAddress, uint amount, uint[] erc20Amount, address[] contractAddress);
  event DaoClaimed(address indexed daoAddress, uint amount, uint[] erc20Amount, address[] contractAddress);
  event SetTime(uint indexed alpha, uint delta, uint omega, uint currentUserCount);
  event TokensReceived(address indexed tokenAddress, uint indexed amount);
  event Received(address from, uint value);

  /// @notice
  /*~~~>
    For setting fees for the Bids, Offers, MarketMint and Marketplace contracts
    Base fee set at 2% (i.e. value * 200 / 10,000) 
    Future fees can be set by the controlling DAO 
  <~~~*/
  function setFee(uint newFee) external hasAdmin returns (bool) {
    fee = newFee;
    return true;
  }

  /// @notice
  /*~~~>
    for adding dev addresses to claimable array
  <~~~*/
  /// @dev
  /*~~~>
    devAddress: new dev;
  <~~~*/
  /// @return Bool
  function addDev(address devAddress) external hasDevAdmin nonReentrant returns(bool) {
    uint devLen = devCount;
    devLen+=1;
    uint id = devLen;
    idToDevTeam[id] = DevTeam(block.timestamp, id, devAddress);
    addressToDevTeamId[devAddress] = id;
    devCount=devLen;
    emit NewDev(devAddress);
    return true;
  }

  /// @notice
  /*~~~>
    for removing dev addresses from claimable array
  <~~~*/
  /// @dev
  /*~~~>
    devAddress: dev to be removed;
  <~~~*/
  /// @return removed Bool
  function removeDev(address devAddress) external hasDevAdmin nonReentrant returns(bool) {
    uint id = addressToDevTeamId[devAddress];
    idToDevTeam[id] = DevTeam(0, 0, address(0x0));
    addressToDevTeamId[devAddress] = 0;
    emit RemovedDev(devAddress);
    return true;
  }

  /// @notice
    /*~~~> 
      Creating new users for rewards
        <~~~*/
   /// @dev
    /*~~~>
     userAddress: user address;
        <~~~*/
    /// @return Bool
  function createUser(address userAddress) external hasContractAdmin nonReentrant returns(bool) {
    uint userId;
    if(addressToId[userAddress] > 0){
      userId = addressToId[userAddress];
    } else {
      uint len = openStorage.length;
      if (len >= 1){
        userId = openStorage[len-1];
        removeStorage();
      } else {
        userCount;
        userId = userCount;
        addressToId[userAddress] = userId;
      }
    }
    User memory user = User(false, 0, block.timestamp, userId, userAddress);
    idToUser[userId] = user;
    addressToUser[userAddress] = user; 
    emit NewUser(userId, userAddress);
    return true;
  }

  /// @notice
    /*~~~> 
      Creating new NFT hodler placements for rewards
        <~~~*/
   /// @dev
    /*~~~>
     tokenId: NFT tokenId to track claims;
        <~~~*/
    /// @return Bool
  function createNftHodler(uint tokenId) external hasContractAdmin nonReentrant returns(bool) {
    address mrktNft = IRoleProvider(roleAdd).fetchAddress(NFTADD);
    nftHodlerCount+=1;
    uint hodlerId = nftHodlerCount;
    NftHodler memory hodler = NftHodler(block.timestamp, hodlerId, tokenId);
    nftIdToHodler[tokenId] = hodler;
    emit NewUser(hodlerId, mrktNft);
    return true;
  }

  /// @notice
  /*~~~> For setting the NFTs created in bootstrap phase <~~~*/
  function createOGHodlers(uint[] memory tokenId) external hasDevAdmin nonReentrant returns(bool){
    address mrktNft = IRoleProvider(roleAdd).fetchAddress(NFTADD);
    uint count = nftHodlerCount;
    for (uint i=0; i<tokenId.length; i++){
      count+=1;
      uint hodlerId = count;
      NftHodler memory hodler = NftHodler(block.timestamp, hodlerId, tokenId[i]);
      nftIdToHodler[tokenId[i]] = hodler;
      emit NewUser(hodlerId, mrktNft);
    }
    nftHodlerCount=count;
    return true;
  }
  
  /// @notice
  //*~~~> Resetting the user data to revoke claim access after last item sells
  /// @dev
    /*~~~>
     userAddress: user address;
        <~~~*/
  /// @return Bool
  function setUser(bool canClaim, address userAddress) external hasContractAdmin nonReentrant returns(bool) {
    uint userId = addressToId[userAddress];
    User memory user = idToUser[userId];
    if(canClaim){
      idToUser[userId] = User(true, 0, user.timestamp, user.userId, userAddress);
    } else {
      // push old user Id for recycling
      openStorage.push(userId);
      // reset user to Id mapping
      idToUser[userId] = User(false, 0, 0, user.userId,  userAddress);
    }
    return true;
  }

  /*~~~> Public function anyone can call to split the accumulated user rewards
    When called, the current timestamp is saved as alpha time.
    Old aplha time becomes delta,
      old delta time becomes omega.
    Total user count is saved.
    Can only be called every 3 days.
  <~~~*/
  function setClaimClock() external nonReentrant {
    uint users = fetchUserAmnt();
    ClaimClock memory clock = idToClock[8];
    require(clock.alpha < (block.timestamp - 3 days));
    uint alpha = block.timestamp;
    uint delta = clock.alpha;
    uint omega = clock.delta;
    uint totalUsers = users + nftHodlerCount;
    idToClock[8] = ClaimClock(alpha, delta, omega, totalUsers);
    emit SetTime(alpha, delta, omega, totalUsers);
  }

  /// @notice
  /*~~~> 
    Function for claiming User rewards
  <~~~*/
  /// @dev
  /*~~~>
    Withdraws Eth deposited, 
      then checks against the Rewards deposited for withdraw,
      then checks against Redemptions for withdraw;
  <~~~*/
  //*~~~> Claims all eligible rewards for user
  ///@dev address[] contractAddress: Addresses of the ERC20's to be claimed
  function claimRewards(address[] calldata contractAddress) external nonReentrant {
    uint id = addressToId[msg.sender];
    User memory user = idToUser[id];
    ClaimClock memory clock = idToClock[8];
    require(user.canClaim == true, "Ineligible!");
    /// Users receives 2/3 of total rewards
    uint userEthSplit = (address(this).balance - (address(this).balance / 3));
    uint userSplits = userEthSplit - (userEthSplit / clock.howManyUsers);
    /*~~~> Distribute according to timestamp cutoff
      if user.timestamp:
          > clock.alpha = no claims;
          < clock.alpha > clock.delta && claims == 0 = full claim, else no claim;
          < clock.delta > clock.omega && claims <= 1 = 1/2 claim, else no claim;
          < clock.omega && claims <= 2 = 1/3 claim, else no claim;
          claims == 3 no claims;
    <~~~*/
    ///*~~~> i.e. alpha: 100, delta: 98, omega:96  ::
      ///*~~~> user.timestamp == 99, is less than alpha, greater than omega, 0 claims, gets rewards;
    if (user.timestamp < clock.alpha && user.timestamp > clock.delta){
      if (user.claims==0){
        // Transfer the full ETH portion
        require(sendEther(msg.sender, userSplits));
      // Cycle through selected rewards tokens and send full portion
      uint tokenLen = contractAddress.length;
      for (uint i; i < tokenLen; i++) {
        uint tokenId = addressToRewardsId[contractAddress[i]];
        RewardsToken memory toke = idToRewardsToken[tokenId];
        if(toke.tokenAmount > 0){
          uint userErcSplits = (toke.tokenAmount - (toke.tokenAmount / 3));
          uint ercSplit = (userErcSplits / clock.howManyUsers);
          require(IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit));
          /// update new amount
          toke.tokenAmount = (toke.tokenAmount - ercSplit);
        }
        idToRewardsToken[tokenId] = RewardsToken(tokenId, toke.tokenAmount, toke.tokenAddress);
      }
        user.claims += 1;
      }
    }
    ///*~~~> i.e. alpha: 100, delta: 98, omega:96  ::
      ///*~~~> user.timestamp == 97, is less than delta, greater than omega, 1 or less claims, gets 1/2 full rewards;
    if (user.timestamp < clock.delta && user.timestamp > clock.omega){
      if(user.claims <= 1){
        // Transfer half ETH portion
        require(sendEther(msg.sender, (userSplits / 2)));
      // Cycle through selected rewards tokens and send half portion
      uint tokenLen = contractAddress.length;
      for (uint i; i < tokenLen; i++) {
        uint tokenId = addressToRewardsId[contractAddress[i]];
        RewardsToken memory toke = idToRewardsToken[tokenId];
        if(toke.tokenAmount > 0){
          uint userErcSplits = (toke.tokenAmount - (toke.tokenAmount / 3));
          uint ercSplit = ((userErcSplits / clock.howManyUsers) / 2);
          require(IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit));
          /// update new amount
          toke.tokenAmount = (toke.tokenAmount - ercSplit);
        }
        idToRewardsToken[tokenId] = RewardsToken(tokenId, toke.tokenAmount, toke.tokenAddress);
      }
        user.claims += 1;
      }
    }
    ///*~~~> i.e. alpha: 100, delta: 98, omega:96  ::
      ///*~~~> user.timestamp == 95, is less than omega, 2 or less claims, gets 1/3 full reward;
    if (user.timestamp < clock.omega && user.claims <= 2){
        // Transfer 1/3 ETH portion
        require(sendEther(msg.sender,(userSplits / 3)));
      uint tokenLen = contractAddress.length;
      // Cycle through selected rewards tokens and send 1/3 portion
      for (uint i; i < tokenLen; i++) {
        uint tokenId = addressToRewardsId[contractAddress[i]];
        RewardsToken memory toke = idToRewardsToken[tokenId];
        if(toke.tokenAmount > 0){
          uint userErcSplits = (toke.tokenAmount - (toke.tokenAmount / 3));
          uint ercSplit = ((userErcSplits / clock.howManyUsers) / 3);
          require(IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit));
          /// update new amount
          toke.tokenAmount = (toke.tokenAmount - ercSplit);
        }
        idToRewardsToken[tokenId] = RewardsToken(tokenId, toke.tokenAmount, toke.tokenAddress);
      }
      user.claims += 1;
    }
    if(user.claims == 3){
      idToUser[user.userId] = User(false, 0, user.timestamp, user.userId, user.userAddress);
      clock.howManyUsers -= 1;
    } else {
      idToUser[user.userId] = User(true, user.claims, user.timestamp, user.userId, user.userAddress);
    }
    idToClock[8] = ClaimClock(clock.alpha, clock.delta, clock.omega, clock.howManyUsers);
  }

  /// @notice
  /*~~~> 
    Function for claiming NFT rewards
  <~~~*/
  /// @dev
  /*~~~>
    Withdraws Eth deposited, 
      then checks against the Rewards deposited for withdraw,
      then checks against Redemptions for withdraw;
  <~~~*/
  //*~~~> Claims eligible rewards for NFT holders <~~~*//
    ///@dev address[] contractAddress: Addresses of the ERC20's to be claimed
  function claimNFTRewards(uint nftId, address[] calldata contractAddress) external nonReentrant {
    ClaimClock memory clock = idToClock[8];
    
    address mrktNft = IRoleProvider(roleAdd).fetchAddress(NFTADD);

    ///*~~~> require msg.sender to be a platform NFT holder
    require(IERC721(mrktNft).balanceOf(msg.sender) > 0, "Ineligible!");

    NftHodler memory hodler = nftIdToHodler[nftId];
    ///*~~~> Limiting claim abilities to once a day
    require(hodler.timestamp < (block.timestamp - 1 days));
    uint userRewards = (address(this).balance - (address(this).balance / 3));
    uint splits = userRewards - (userRewards / clock.howManyUsers);
    require(sendEther(msg.sender, splits));
    
    uint len = contractAddress.length;
    address[] memory adds;
    uint[] memory amnts;
    for (uint i; i < len; i++) {
      uint tokenId = addressToRewardsId[contractAddress[i]];
      RewardsToken memory toke = idToRewardsToken[tokenId];
      if(toke.tokenAmount > 0) {
        adds[i] = toke.tokenAddress;
        uint userSplit = (toke.tokenAmount - (toke.tokenAmount / 3));
        uint ercSplit = (userSplit / clock.howManyUsers);
        amnts[i] = ercSplit;
        /// transfer token amount divided by total user amount 
        require(IERC20(toke.tokenAddress).transfer(payable(msg.sender), ercSplit));
         /// update new amount
        toke.tokenAmount -= ercSplit;
      }
      idToRewardsToken[tokenId] = RewardsToken(tokenId, toke.tokenAmount, toke.tokenAddress);
    }
    idToClock[8] = ClaimClock(clock.alpha, clock.delta, clock.omega, clock.howManyUsers);
    emit RewardsClaimed(msg.sender, splits, amnts, adds);
  }

  /// @notice
  /*~~~> 
    Function for claiming Dev rewards
  <~~~*/
  /// @dev
  /*~~~>
    Withdraws Eth deposited, 
      then checks against the Rewards deposited for withdraw,
      then checks against Redemptions for withdraw;
  <~~~*/
    ///@dev address[] contractAddress: Addresses of the ERC20's to be claimed
  function claimDevRewards(address[] calldata contractAddress) external nonReentrant {
    uint devId = addressToDevTeamId[msg.sender];
    require(devId>0);
    DevTeam memory dev = idToDevTeam[devId];
    address devMultiPass = IRoleProvider(roleAdd).fetchAddress(DEV);
    /// ensuring msg.sender is a dev address
    if(msg.sender != devMultiPass || msg.sender != dev.devAddress){
      require(msg.sender == WHALE || msg.sender == JON);
    }
    ///*~~~> Limiting claim abilities to once a day
    require(dev.timestamp < (block.timestamp - 1 days), "Ineligible!");
    uint len = contractAddress.length;
    address[] memory adds;
    uint[] memory amnts;
    for (uint i; i < len; i++) {
      uint tokenId = addressToRewardsId[contractAddress[i]];
      RewardsToken memory token = idToRewardsToken[tokenId];
      if(token.tokenAmount > 0){
        adds[i] = token.tokenAddress;
        uint devTokenSig = (token.tokenAmount / 24);
        uint devTokenSplit = (devTokenSig / devCount);
        /// transfer token amount
        if(msg.sender != devMultiPass){
          amnts[i] = devTokenSplit;
          require(IERC20(token.tokenAddress).transfer(payable(dev.devAddress), devTokenSplit));
          token.tokenAmount -= devTokenSplit;
        } else {
          amnts[i] = devTokenSig;
          require(IERC20(token.tokenAddress).transfer(payable(devMultiPass), devTokenSig));
          token.tokenAmount -= devTokenSig;
        }
        idToDevTeam[devId] = DevTeam(block.timestamp, devId, dev.devAddress);
      }
      idToRewardsToken[tokenId] = RewardsToken(tokenId, token.tokenAmount, token.tokenAddress);
    }
    /// Devs receive 1/2 of 1/4 of 1/3 of total amounts; (1/24)
    // Dev multisig receives (1/24)
    uint devSig = (address(this).balance / 24);
    uint devSplit = (devSig / devCount);
    if(msg.sender != devMultiPass){
      require(sendEther(dev.devAddress, devSplit));
      emit DevClaimed(msg.sender, devSplit, amnts, adds);
    } else {
      require(sendEther(devMultiPass, devSig));
      emit DevClaimed(msg.sender, devSig, amnts, adds);
    }
  }

  /// @notice
  /*~~~> 
    Function for claiming Dao rewards
  <~~~*/
  /// @dev
  /*~~~>
    Withdraws Eth deposited, 
      then checks against the Rewards deposited for withdraw,
      then checks against Redemptions for withdraw;
  <~~~*/
    ///@dev address[] contractAddress: Addresses of the ERC20's to be claimed
  function claimDaoRewards(address[] calldata tokenAddress) external nonReentrant {
    address daoAdd = IRoleProvider(roleAdd).fetchAddress(DAO);
    require(msg.sender == daoAdd);
    /// Dao gets 3/4 of 1/3 of total amount (3/12);
    uint daoSplit = (address(this).balance / 3);
    uint daoAmount = (daoSplit - (daoSplit / 4));
    require(sendEther(daoAdd, daoAmount));
    /// update new amount
    uint count = tokenAddress.length;
    address[] memory adds;
    uint[] memory amnts;
    for (uint i; i < count; i++) {
      uint tokenId = addressToRewardsId[tokenAddress[i]];
      RewardsToken memory token = idToRewardsToken[tokenId];
      adds[i] = token.tokenAddress;
      uint daoTokenSplit = (token.tokenAmount / 3);
      uint daoTokenAmount = (daoTokenSplit - (daoTokenSplit / 4));
      if (daoTokenAmount > 0) {
        amnts[i] = daoTokenSplit;
        IERC20(token.tokenAddress).transfer(daoAdd, daoTokenAmount);
        token.tokenAmount -= daoTokenAmount;
        idToRewardsToken[tokenId] = RewardsToken(tokenId, token.tokenAmount, token.tokenAddress);
      }
    }
    emit DaoClaimed(msg.sender, daoAmount, amnts, adds);
  }

  /// @notice
  /*~~~>
    Deposits ERC20 tokens for rewards
  <~~~*/
  /// @dev
  /*~~~>
    amount: how much ERC20 to be deposited
    tokenAddress: contract address of the ERC20
  <~~~*/
  /// @return Bool
  function depositERC20Rewards(uint amount, address tokenAddress) external nonReentrant returns(bool){
    uint tokenId = addressToTokenId[tokenAddress];
    //*~~~> Check to see if the token address exists already
    if(tokenId>0){
      RewardsToken memory reward = idToRewardsToken[tokenId];
      uint newAmnt = (reward.tokenAmount + amount);
      idToRewardsToken[tokenId] = RewardsToken(tokenId, newAmnt, tokenAddress);
    } else {
      tokenCount+=1;
      addressToTokenId[tokenAddress] = tokenCount;
      idToRewardsToken[tokenId] = RewardsToken(tokenId, amount, tokenAddress);
    }
    emit TokensReceived(tokenAddress, amount);
    return true;  
  }

    /// @notice 
  /*~~~> 
    Internal function for removing elements from an array
    Only used for internal storage array index recycling

      In order to reduce storage array size of listed items 
        while maintaining specific enumerable id's, 
        any sold or removed item spots are recycled by referring to their index,
        else a new storage spot is created;

        We use the last item in the storage (length of array - 1 for 0 based index position),
        in order to pop off the item and avoid rewriting 
  <~~~*/
  function removeStorage() internal {
      openStorage.pop();
    }

  //*~~~> Fee for contract use
    function getFee() public view returns(uint){
    return fee;
  }  

  //*~~~> Read functions for fetching amounts and data
  function fetchUsers() public view returns (User[] memory user){
    User[] memory users = new User[](userCount);
    for (uint i; i < userCount; i++) {
      if (idToUser[i+1].canClaim) {
        User storage currentUser = idToUser[i+1];
        users[i] = currentUser;
      }
    }
    return users;
  }

  function fetchHodler(uint tokenId) public view returns (NftHodler memory){
    NftHodler memory hodler = nftIdToHodler[tokenId];
    return hodler;
  }

  function fetchDevs() public view returns (DevTeam[] memory dev){
    DevTeam[] memory devs = new DevTeam[](devCount);
    for (uint i; i < devCount; i++) {
      if (idToDevTeam[i+1].devAddress != address(0x0)) {
        DevTeam storage currentDev = idToDevTeam[i+1];
        devs[i] = currentDev;
      }
    }
    return devs;
  }

  function fetchUserAmnt() public view returns (uint amount) {
    for (uint i; i < userCount; i++) {
      if (idToUser[i+1].canClaim == true) {
        amount++;
      }
    }
    return amount;
  }

  function fetchRewardTokens() public view returns (RewardsToken[] memory token){
    RewardsToken[] memory tokens = new RewardsToken[](tokenCount);
    for (uint i; i < tokenCount; i++) {
      tokens[i] = idToRewardsToken[i+1];
    }
    return tokens;
  }

  function fetchUserByAddress(address userAdd) public view returns (User memory user){
    user = addressToUser[userAdd]; 
    return user;
  }

  function fetchClaimTime() public view returns (ClaimClock memory time){
    return idToClock[8];
  }

  function fetchEthAmount() public view returns(uint totalEth){
    return address(this).balance;
  }

  //*~~~> Fallback functions
  function transferNft(address receiver, address nftContract, uint tokenId) nonReentrant public hasAdmin {
    IERC721(nftContract).safeTransferFrom(address(this), receiver, tokenId);
  }

  function transfer1155(address receiver, address nftContract, uint tokenId, uint amount) nonReentrant public hasAdmin {
    IERC1155(nftContract).safeTransferFrom(address(this), receiver, tokenId, amount, "");
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
  
  /*~~~>
  Fallback functions
  <~~~*/
  receive() external payable {
    emit Received(msg.sender, msg.value);
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

interface IRoleProvider {
  function hasTheRole(bytes32 role, address theaddress) external returns(bool);
  function fetchAddress(bytes32 thevar) external returns(address);
  function hasContractRole(address theaddress) external view returns(bool);
}