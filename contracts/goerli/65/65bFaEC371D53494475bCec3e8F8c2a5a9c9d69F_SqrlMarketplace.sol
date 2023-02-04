/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: SqrlMarketplace.sol


pragma solidity ^0.8.17;





interface ISqrl721Core is IERC721 {
  function getArtist(uint _tokenId) external returns (address);
}

contract SqrlMarketplace is IERC721Receiver, Ownable {

  using SafeMath for uint;

  struct Listing {
    uint tokenId;
    uint listingPrice;
    address nftOwner;
  }

  struct Offer {
    uint projectId;
    uint tokenId;
    address buyer;
    uint price;
    uint time;
  }

  ISqrl721Core _tokenContract;

  address public commissionAddress;

  mapping(uint => Listing) listing; //mapping of token id to Listing
  mapping(uint => Listing[]) projectListings; //mapping of projectId to Listing
  mapping(uint => Offer[]) tokenOffers; //mapping of token id to Offers
  mapping(uint => address[]) public tokenTurnover; //keeps track of how many times a token has been sold
  mapping(address => uint[]) offersByAddress;

  event ListingCreated(uint tokenId, address owner, uint price);
  event ListingCancelled(uint tokenId);
  event ListingFilled(uint tokenId, address buyer, uint price);

  event OfferCreated(uint projectId, uint tokenId, address buyer, uint price, uint time);
  event OfferCancelled(uint tokenId, address buyer);
  event OfferAccepted(uint tokenId, address seller, uint price);

  event ArtistRoyaltyPaid(uint tokenId, uint salePrice, uint royaltyAmount);
  event CollectorRoyaltyPaid(uint tokenId, uint salePrice, uint royaltyAmount);
  event SqrlRoyaltyPaid(uint tokenId, uint salePrice, uint royaltyAmount);
  event Sale(uint tokenId, address newOwner, uint salePrice);

  uint[6] artistCommission = [  // % with 4 decimal places e.g. 930000 = 93%
    50000,
    50000,
    50000,
    50000,
    50000,
    50000
  ];
  uint[6] sqrlCommission = [
    30000,
    20000,
    20000,
    22500,
    25000,
    26875
  ];
  uint[6] collector1Commission = [
    0,
    10000,
    5000,
    2500,
    1250,
    625
  ];
  uint[6] collector2Commission = [
    0,
    0,
    5000,
    2500,
    1250,
    625
  ];
  uint[6] collector3Commission = [
    0,
    0,
    0,
    2500,
    1250,
    625
  ];
  uint[6] collector4Commission = [
    0,
    0,
    0,
    0,
    1250,
    625
  ];
  uint[6] collector5Commission = [
    0,
    0,
    0,
    0,
    0,
    625
  ];

  constructor(address _tokenAddress, address _commissionAddress) {
      _tokenContract = ISqrl721Core(_tokenAddress);
      commissionAddress = _commissionAddress;
  }

  function getOffers(uint _tokenId) external view returns (Offer[] memory) {
    return tokenOffers[_tokenId];
  }

  function getOffersByAddress(address _address) external view returns (uint[] memory) {
    return offersByAddress[_address];
  }

  function getListing(uint _tokenId) external view returns (Listing memory) {
    return listing[_tokenId];
  }

  function getListings(uint _projectId) external view returns (Listing[] memory) {
    return projectListings[_projectId];
  }

  function createListing(uint _projectId, uint _tokenId, uint _price) external {
    Listing storage isListing = listing[_tokenId];
    if (isListing.nftOwner == msg.sender) {
      require(_price > 0, "A valid list price must be set");
      require(_price != isListing.listingPrice, "Amount is the same as current list price");
      listing[_tokenId] = Listing(_tokenId, _price, msg.sender);

      uint index = indexOfListing(projectListings[_projectId], _tokenId);

      if (projectListings[_projectId].length > 1) {
        projectListings[_projectId][index] = projectListings[_projectId][projectListings[_projectId].length - 1];
      }

      projectListings[_projectId].pop();

      projectListings[_projectId].push(listing[_tokenId]);

      emit ListingCreated(_tokenId, msg.sender, _price);
    } else {
      require(
        _tokenContract.ownerOf(_tokenId) == msg.sender,
        "Only the token owner can create or change a list price"
      );
      require(_price > 0, "A valid list price must be set");

      //stake nft to contract for listing duration
      listing[_tokenId] = Listing(_tokenId, _price, msg.sender);
      _tokenContract.safeTransferFrom(msg.sender, address(this), _tokenId);

      projectListings[_projectId].push(listing[_tokenId]);

      emit ListingCreated(_tokenId, msg.sender, _price);
    }

  }

  function cancelListing(uint _projectId, uint _tokenId) external {
    Listing storage _listing = listing[_tokenId];
    require(
      _listing.nftOwner == msg.sender,
      "Only the token owner can cancel a list price"
    );
    require(
      _listing.listingPrice > 0,
      "There is currently no list price set"
    );

    _tokenContract.safeTransferFrom(
      address(this),
      _listing.nftOwner,
      _tokenId
    );

    _listing.listingPrice = 0;
    _listing.nftOwner = address(0);

    uint index = indexOfListing(projectListings[_projectId], _tokenId);

    if (projectListings[_projectId].length > 1) {
      projectListings[_projectId][index] = projectListings[_projectId][projectListings[_projectId].length - 1];
    }

    projectListings[_projectId].pop();

    emit ListingCancelled(_tokenId);
  }

  function fillListing(uint _projectId, uint _tokenId) external payable {
    Listing storage _listing = listing[_tokenId];

    require(
      _listing.listingPrice > 0,
      "A listing price has not been set for this NFT"
    );

    require(msg.value == _listing.listingPrice, "This amount does not match the listing price");

    require(
        msg.sender != _listing.nftOwner,
        "You are the owner, cancel listing to get token back"
    );

    //payment pipeline to pay artist, platform and first few collectors
    _payPipeline(_tokenId, _listing.listingPrice, _listing.nftOwner);

    emit Sale(_tokenId, msg.sender, _listing.listingPrice);

    //transfer token to new owner
    _tokenContract.safeTransferFrom(address(this), msg.sender, _tokenId);

    emit ListingFilled(
      _tokenId,
      msg.sender,
      _listing.listingPrice
    );

    //increment the sale counter
    tokenTurnover[_tokenId].push(_listing.nftOwner);

    //reset listing information
    _listing.listingPrice = 0;
    _listing.nftOwner = address(0);

    uint index = indexOfListing(projectListings[_projectId],_tokenId);

    if (projectListings[_projectId].length > 1) {
      projectListings[_projectId][index] = projectListings[_projectId][projectListings[_projectId].length - 1];
    }

    projectListings[_projectId].pop();
  }

  function createOffer(uint _projectId, uint _tokenId, uint _price) external payable {
    address owner = _tokenContract.ownerOf(_tokenId);
    require(
        owner != msg.sender,
        "You cannot make an offer on your own NFT"
    );

    require(msg.value == _price, "msg.value must match amount");
    require(msg.value > 0, "You cannot create a zero value offer");

    if (offerBuyerExists(tokenOffers[_tokenId], msg.sender)) {
      uint256 index = indexOfBuyer(
        tokenOffers[_tokenId],
        msg.sender
      );
      uint256 indexOBA = indexOfToken(offersByAddress[msg.sender], _tokenId);

      require(_price != tokenOffers[_tokenId][index].price, "Amount is the same as current offer price");

      payable(tokenOffers[_tokenId][index].buyer).transfer(tokenOffers[_tokenId][index].price);

      if (tokenOffers[_tokenId].length > 1) {
        tokenOffers[_tokenId][index] = tokenOffers[_tokenId][tokenOffers[_tokenId].length - 1];
      }
      tokenOffers[_tokenId].pop();

      tokenOffers[_tokenId].push(Offer(_projectId, _tokenId, msg.sender, _price, block.timestamp));

      if (offersByAddress[msg.sender].length > 1) {
        offersByAddress[msg.sender][indexOBA] = offersByAddress[msg.sender][offersByAddress[msg.sender].length - 1];
      }
      offersByAddress[msg.sender].pop();

      offersByAddress[msg.sender].push(_tokenId);

      emit OfferCreated(_projectId, _tokenId, msg.sender, _price, block.timestamp);
    } else {
      tokenOffers[_tokenId].push(Offer(_projectId, _tokenId, msg.sender, _price, block.timestamp));
      offersByAddress[msg.sender].push(_tokenId);

      emit OfferCreated(_projectId, _tokenId, msg.sender, _price, block.timestamp);
    }
  }

  function cancelOffer(uint _tokenId) external {
    uint index = indexOfBuyer(
      tokenOffers[_tokenId],
      msg.sender
    );

    uint256 indexOBA = indexOfToken(offersByAddress[msg.sender], _tokenId);

    payable(tokenOffers[_tokenId][index].buyer).transfer(tokenOffers[_tokenId][index].price);

    if (tokenOffers[_tokenId].length > 1) {
      tokenOffers[_tokenId][index] = tokenOffers[_tokenId][tokenOffers[_tokenId].length - 1];
    }
    tokenOffers[_tokenId].pop();

    if (offersByAddress[msg.sender].length > 1) {
      offersByAddress[msg.sender][indexOBA] = offersByAddress[msg.sender][offersByAddress[msg.sender].length - 1];
    }
    offersByAddress[msg.sender].pop();

    emit OfferCancelled(_tokenId, msg.sender);
  }

  function acceptOffer(uint _tokenId, address _buyer) external {
    uint256 index = indexOfBuyer(tokenOffers[_tokenId], _buyer);
    uint256 indexOBA = indexOfToken(offersByAddress[_buyer], _tokenId);
    Offer storage _offer = tokenOffers[_tokenId][index];
    Listing storage _listing = listing[_tokenId];
    address owner = _tokenContract.ownerOf(_tokenId);

    if (_listing.nftOwner != msg.sender) {
      require(owner == msg.sender, "Only the owner can accept the offer");
    }

    _payPipeline(_tokenId, _offer.price, owner);

    emit Sale(_tokenId, msg.sender, _offer.price);

    //transfer token to new owner
    _tokenContract.safeTransferFrom(msg.sender, _buyer, _tokenId);

    emit OfferAccepted(_tokenId, owner, _offer.price);

    if (tokenOffers[_tokenId].length > 1) {
        tokenOffers[_tokenId][index] = tokenOffers[_tokenId][tokenOffers[_tokenId].length - 1];
    }
    tokenOffers[_tokenId].pop();

    if (offersByAddress[_buyer].length > 1) {
      offersByAddress[_buyer][indexOBA] = offersByAddress[_buyer][offersByAddress[_buyer].length - 1];
    }
    offersByAddress[_buyer].pop();

    //increment the sale counter
    tokenTurnover[_tokenId].push(owner);
  }

  function getRoyaltySplit(uint _tokenId)
    internal
    view
  returns (uint[7] memory splits) {
    uint _tokenTurnover = tokenTurnover[_tokenId].length;
    if (_tokenTurnover > 5) {
      _tokenTurnover = 5;
    }

    splits = [
      artistCommission[_tokenTurnover],
      sqrlCommission[_tokenTurnover],
      collector1Commission[_tokenTurnover],
      collector2Commission[_tokenTurnover],
      collector3Commission[_tokenTurnover],
      collector4Commission[_tokenTurnover],
      collector5Commission[_tokenTurnover]
    ];
    return splits;
  }

  function indexOfListing(Listing[] memory arr, uint searchFor) private pure returns (uint) {
    for (uint i = 0; i < arr.length; i++) {
      if (arr[i].tokenId == searchFor) {
          return i;
      }
    }
    revert("Listing not found");
  }

  function indexOfBuyer(Offer[] memory arr, address searchFor) private pure returns (uint) {
    for (uint i = 0; i < arr.length; i++) {
      if (arr[i].buyer == searchFor) {
          return i;
      }
    }
    revert("Buyer not found");
  }

  function indexOfToken(uint[] memory arr, uint searchFor) private pure returns (uint) {
    for (uint i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
          return i;
      }
    }
    revert("Token not found");
  }

  function offerBuyerExists(Offer[] memory arr, address searchFor) private pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i].buyer == searchFor) {
          return true;
      }
    }
    return false;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function _payPipeline(uint _tokenId, uint _paymentAmount, address _currentOwner) internal {
    uint[7] memory splits = getRoyaltySplit(_tokenId);

    uint _artistAmount = _paymentAmount.mul(splits[0]).div(1_000_000);
    address _artistAddress = _tokenContract.getArtist(_tokenId);

    //pay royalty to creator/artist
    if (_artistAmount > 0) {
      payable(_artistAddress).transfer(_artistAmount);

      emit ArtistRoyaltyPaid(_tokenId, _paymentAmount, _artistAmount);
    }

    uint _amount = 0;

    //pay fee to platform
    if (splits[1] > 0) {
      _amount = _paymentAmount.mul(splits[1]).div(1_000_000);
      payable(commissionAddress).transfer(_amount);

      emit SqrlRoyaltyPaid(_tokenId, _paymentAmount, _amount);
    }

    uint remaining = _paymentAmount -
        (_artistAmount +
        _amount);

    //pay fee to 1st collector
    if (splits[2] > 0) {
      _amount = _paymentAmount.mul(splits[2]).div(1_000_000);
      payable(tokenTurnover[_tokenId][0]).transfer(_amount);

      emit CollectorRoyaltyPaid(_tokenId, _paymentAmount, _amount);

      remaining -= _amount;
    }

    //pay fee to 2nd collector
    if (splits[3] > 0) {
      _amount = _paymentAmount.mul(splits[3]).div(1_000_000);
      payable(tokenTurnover[_tokenId][1]).transfer(_amount);

      emit CollectorRoyaltyPaid(_tokenId, _paymentAmount, _amount);

      remaining -= _amount;
    }

    //pay fee to 3rd collector
    if (splits[4] > 0) {
      _amount = _paymentAmount.mul(splits[4]).div(1_000_000);
      payable(tokenTurnover[_tokenId][2]).transfer(_amount);

      emit CollectorRoyaltyPaid(_tokenId, _paymentAmount, _amount);

      remaining -= _amount;
    }

    //pay fee to 4th collector
    if (splits[5] > 0) {
      _amount = _paymentAmount.mul(splits[5]).div(1_000_000);
      payable(tokenTurnover[_tokenId][3]).transfer(_amount);

      emit CollectorRoyaltyPaid(_tokenId, _paymentAmount, _amount);

      remaining -= _amount;
    }

    //pay fee to 5th collector
    if (splits[6] > 0) {
      _amount = _paymentAmount.mul(splits[6]).div(1_000_000);
      payable(tokenTurnover[_tokenId][4]).transfer(_amount);

      emit CollectorRoyaltyPaid(_tokenId, _paymentAmount, _amount);

      remaining -= _amount;
    }

    //pay remaining amount to seller
    if (remaining > 0) {
      payable(_currentOwner).transfer(remaining);
    }
  }

  function updateCommissionAddress(address _commissionAddress) external onlyOwner {
    commissionAddress = _commissionAddress;
  }

  function updateTokenAddress(address _tokenAddress) external onlyOwner {
    _tokenContract = ISqrl721Core(_tokenAddress);
  }
}