// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "./Ownable.sol";
import {IAccessContract} from "./interfaces/IAccessContract.sol";

// Custom errros
error AccessContract_ZeroAddress();
error AccessContract_NotHaveAccess(address sender);

/// @author Georgi Karagyozov
/// @notice NFT Land contract which represents a piece of the Earthverse.
contract AccessContract is Ownable, IAccessContract {
  address public earthverseDepositAddress;

  event EarthverseDepositAddressChanged(address oldAddress, address newAddress);

  modifier onlyEarthverseDeposit() {
    if (msg.sender != earthverseDepositAddress)
      revert AccessContract_NotHaveAccess(msg.sender);
    _;
  }

  /// @notice Аllows the contract owner to give a new address for earthverseDeposit.
  /// @param _earthverseDepositAddress: The address of earthverseDeposit contract.
  function setNewEarthverseDepositAddress(
    address _earthverseDepositAddress
  ) external onlyOwner {
    if (_earthverseDepositAddress == address(0))
      revert AccessContract_ZeroAddress();

    emit EarthverseDepositAddressChanged(
      earthverseDepositAddress,
      _earthverseDepositAddress
    );

    earthverseDepositAddress = _earthverseDepositAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEarthverseMarketplace} from "./interfaces/IEarthverseMarketplace.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AccessContract} from "./AccessContract.sol";

// Custom errors
error EarthverseMarketplace_NotOwner();
error EarthverseMarketplace_ZeroAddress();
error EarthverseMarketplace_PriceMustBeAboveZero();
error EarthverseMarketplace_AlreadyListed(uint256 tokenId);
error EarthverseMarketplace_PriceDoNotMet(uint256 itemId, uint256 price);
error EarthverseMarketplace_ItemDoesntExit(uint256 itemId);
error EarthverseMarketplace_SellerCannotBeBuyer();

/// @author Georgi Karagyozov
/// @notice EarthverseMarketplace contract which is used to store NFT Land and allow the buyer to purchase them.
contract EarthverseMarketplace is
  ReentrancyGuard,
  IEarthverseMarketplace,
  AccessContract
{
  uint256 public itemCount;

  struct ListingNFTLand {
    uint256 id;
    IERC721 nftLand;
    uint256 tokenId;
    uint256 price;
    address seller;
  }

  mapping(uint256 => ListingNFTLand) public listing;

  modifier isOwner(
    IERC721 nftLand,
    uint256 tokenId,
    address spender
  ) {
    address _owner = nftLand.ownerOf(tokenId);
    if (spender != _owner) revert EarthverseMarketplace_NotOwner();
    _;
  }

  modifier notListed(uint256 tokenId) {
    ListingNFTLand memory _listing = listing[tokenId];
    if (_listing.price > 0) revert EarthverseMarketplace_AlreadyListed(tokenId);
    _;
  }

  modifier zeroAddress(address _address) {
    if (_address == address(0)) revert EarthverseMarketplace_ZeroAddress();
    _;
  }

  // Events
  event NFTLandListed(
    uint256 itemId,
    uint256 indexed tokenId,
    uint256 indexed price,
    address indexed seller
  );

  event NFTLandBought(
    uint256 itemId,
    uint256 price,
    uint256 indexed tokenId,
    address indexed seller,
    address indexed buyer
  );

  /// @notice Allows the user/seller to add new NFT Land.
  /// @param nftLand: The address of NFT Land contract
  /// @param tokenId: The unique token mid of the NFT Land itself.
  /// @param price: The sale price of NFT Land.
  function listNFTLand(
    IERC721 nftLand,
    uint256 tokenId,
    uint256 price
  )
    external
    notListed(tokenId)
    isOwner(nftLand, tokenId, msg.sender)
    nonReentrant
  {
    if (price <= 0) revert EarthverseMarketplace_PriceMustBeAboveZero();

    ++itemCount;
    listing[itemCount] = ListingNFTLand(
      itemCount,
      nftLand,
      tokenId,
      price,
      msg.sender
    );

    nftLand.transferFrom(msg.sender, address(this), tokenId);
    emit NFTLandListed(itemCount, tokenId, price, msg.sender);
  }

  /// @notice Allows the buyer to buy a given NFT Land.
  /// @param buyer: Тhe address that will receive the NFT Land.
  /// @param itemId: Item id of listing mapping where this NFT Land is stored.
  /// @param price: The price offered by the buyer.
  /// @param decimalsOfInput: Decimal of the stablecoin(USDC, DAI, USDT etc.), through which NFT Land will be purchased by the buyer.
  /// @return The address of the old seller of this NFT Land.
  function buyNFTLand(
    address buyer,
    uint256 itemId,
    uint256 price,
    uint256 decimalsOfInput
  )
    external
    zeroAddress(buyer)
    onlyEarthverseDeposit
    nonReentrant
    returns (address)
  {
    if (itemId <= 0 || itemId > itemCount)
      revert EarthverseMarketplace_ItemDoesntExit(itemId);

    ListingNFTLand storage nftLandItem = listing[itemId];

    if (price < (nftLandItem.price * 10 ** decimalsOfInput))
      revert EarthverseMarketplace_PriceDoNotMet(itemId, nftLandItem.price);
    if (buyer == nftLandItem.seller)
      revert EarthverseMarketplace_SellerCannotBeBuyer();

    address oldSeller = nftLandItem.seller;
    nftLandItem.seller = buyer;

    emit NFTLandBought(
      itemId,
      nftLandItem.price,
      nftLandItem.tokenId,
      oldSeller,
      buyer
    );

    return oldSeller;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAccessContract {
  function setNewEarthverseDepositAddress(
    address _earthverseDepositAddress
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IEarthverseMarketplace {
  function listNFTLand(
    IERC721 nftLand,
    uint256 tokenId,
    uint256 price
  ) external;

  function buyNFTLand(
    address buyer,
    uint256 tokenId,
    uint256 price,
    uint256 decimalsOfInput
  ) external returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOwnable {
  function renounceOwnership(bool isRenounce) external;

  function transferOwnership(address newOwner, bool direct) external;

  function claimOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOwnable} from "./interfaces/IOwnable.sol";

error Ownable_ZeroAddress();
error Ownable_CallerIsNotTheOwner();
error Ownable_CallerIsNotPendingOwner();
error Ownable_NewOwnerMustBeADifferentAddressThanTheCurrentOwner();

/// @author Georgi Karagyozov
/// @notice Ownable contract used to manage Access Contract - AccessContract contract.
abstract contract Ownable is IOwnable {
  address private _owner;
  address public pendingOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /// @notice Initializes the contract setting the deployer as the initial owner.
  constructor() {
    _transferOwnership(msg.sender);
  }

  /// @notice Throws if called by any account other than the owner.
  modifier onlyOwner() {
    if (owner() != msg.sender) revert Ownable_CallerIsNotTheOwner();
    _;
  }

  /// @notice Returns the address of the current owner.
  function owner() public view returns (address) {
    return _owner;
  }

  /// @notice Leaves the contract without owner. It will not be possible to call `onlyOwner` modifier anymore.
  /// @param isRenounce: Boolean parameter with which you confirm renunciation of ownership
  function renounceOwnership(bool isRenounce) external onlyOwner {
    if (isRenounce) _transferOwnership(address(0));
  }

  /// @notice Transfers ownership of the contract to a new account.
  /// @param newOwner: The address of the new owner of the contract
  /// @param direct: Boolean parameter that will be used to change the owner of the contract directly
  function transferOwnership(address newOwner, bool direct) external onlyOwner {
    if (newOwner == address(0)) revert Ownable_CallerIsNotTheOwner();

    if (direct) {
      if (newOwner == _owner)
        revert Ownable_NewOwnerMustBeADifferentAddressThanTheCurrentOwner();

      _transferOwnership(newOwner);
      pendingOwner = address(0);
    } else {
      pendingOwner = newOwner;
    }
  }

  /// @notice The `pendingOwner` have to confirm, if he wants to be the new owner of the contract.
  function claimOwnership() external {
    if (msg.sender != pendingOwner) revert Ownable_CallerIsNotPendingOwner();

    _transferOwnership(pendingOwner);
    pendingOwner = address(0);
  }

  /// @notice Transfers ownership of the contract to a new account.
  /// @param newOwner: The address of the new owner of the contract
  function _transferOwnership(address newOwner) internal {
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);
  }
}