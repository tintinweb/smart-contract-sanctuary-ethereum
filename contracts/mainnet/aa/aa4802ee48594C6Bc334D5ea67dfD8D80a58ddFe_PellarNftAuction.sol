// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";


//   $$$$$$$\  $$$$$$$$\ $$\       $$\        $$$$$$\  $$$$$$$\
//   $$  __$$\ $$  _____|$$ |      $$ |      $$  __$$\ $$  __$$\
//   $$ |  $$ |$$ |      $$ |      $$ |      $$ /  $$ |$$ |  $$ |
//   $$$$$$$  |$$$$$\    $$ |      $$ |      $$$$$$$$ |$$$$$$$  |
//   $$  ____/ $$  __|   $$ |      $$ |      $$  __$$ |$$  __$$<
//   $$ |      $$ |      $$ |      $$ |      $$ |  $$ |$$ |  $$ |
//   $$ |      $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$ |  $$ |$$ |  $$ |
//   \__|      \________|\________|\________|\__|  \__|\__|  \__|
//
//  Pellar 2022


contract PellarNftAuction is ERC721Holder, ERC1155Holder, Ownable {
  struct AuctionItem {
    address owner;
    address contractId;
    uint256 tokenId;
    uint256 reservePrice;
    uint256 startAt;
    uint256 endAt;
    address highestBidder;
    uint256 highestBid;
    uint256 bidCount;
    uint256 blockNumber;
  }

  // variables
  uint256 public windowTime = 5 minutes;
  mapping(bytes32 => AuctionItem) public auctionItems;
  mapping(bytes32 => uint256) public latestPrice;
  mapping(bytes32 => bool) public auctionEntered;

  // events
  event ItemListed(address indexed _contractId, uint256 indexed _tokenId, address indexed _sender, uint256 _reservePrice, uint256 _startAt, uint256 _endAt);
  event ItemBidded(address indexed _contractId, uint256 indexed _tokenId, address _newBidder, uint256 _newAmount, address indexed _oldBidder, uint256 _oldAmount, uint256 _bidCount);
  event AuctionWinnerWithdrawals(address indexed _contractId, uint256 indexed _tokenId, address indexed _winner, uint256 _highestBid);

  /* User */
  // verified
  function bid(address _contractId, uint256 _tokenId) external payable nonReentrant(_contractId, _tokenId) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(tx.origin == msg.sender, "Not allowed");
    require(block.timestamp >= auctionItem.startAt, "Auction inactive"); // require auction starts
    require(block.timestamp <= auctionItem.endAt, "Auction ended"); // require auction not ended
    require(auctionItem.owner != msg.sender && auctionItem.owner != address(0), "Not allowed"); // require not owner or not listed auction item
    require(msg.value > auctionItem.highestBid && msg.value > auctionItem.reservePrice, "Bid underpriced"); // require valid ether value

    address oldBidder = auctionItem.highestBidder;
    uint256 oldAmount = auctionItem.highestBid;

    if (oldBidder != address(0)) {
      // funds return for previous
      payable(oldBidder).transfer(oldAmount);
    }

    // update state
    auctionItem.highestBidder = msg.sender;
    auctionItem.highestBid = msg.value;
    auctionItem.bidCount++;

    latestPrice[auctionId] = msg.value;

    if (block.timestamp + windowTime >= auctionItem.endAt) {
      auctionItem.endAt += windowTime;
    }

    // event
    emit ItemBidded(_contractId, _tokenId, msg.sender, msg.value, oldBidder, oldAmount, auctionItem.bidCount);
  }

  // verified
  function withdrawProductWon(address _contractId, uint256 _tokenId) external {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem memory auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!"); // need auction to end
    require(msg.sender == auctionItem.highestBidder || msg.sender == owner(), "Winner only!"); // need winner

    address winner = auctionItem.highestBidder;
    auctionItem.highestBidder = address(0); // convert state to address 0
    IERC721(_contractId).transferFrom(address(this), winner, _tokenId);

    // event
    emit AuctionWinnerWithdrawals(_contractId, _tokenId, winner, auctionItem.highestBid);
  }

  /* Admin */
  function setWindowTime(uint256 _time) external onlyOwner {
    windowTime = _time;
  }

  // verified
  function createAuction(address _contractId, uint256 _tokenId, uint256 _reservePrice, uint256 _startAt, uint256 _endAt) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    require(_endAt >= block.timestamp && _startAt < _endAt, "Input invalid");
    require(IERC721(_contractId).ownerOf(_tokenId) == msg.sender, "Not allowed"); // require owner
    require(latestPrice[auctionId] == 0, "Need withdraw"); // need withdraw first if bid this product again

    IERC721(_contractId).transferFrom(msg.sender, address(this), _tokenId);

    auctionItems[auctionId] = AuctionItem({
      owner: msg.sender,
      contractId: _contractId,
      tokenId: _tokenId,
      reservePrice: _reservePrice,
      startAt: _startAt,
      endAt: _endAt,
      highestBidder: address(0),
      highestBid: 0,
      bidCount: 0,
      blockNumber: block.number
    });

    // emit
    emit ItemListed(_contractId, _tokenId, msg.sender, _reservePrice, _startAt, _endAt);
  }

  // verified
  function withdraw(address _contractId, uint256 _tokenId) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(latestPrice[auctionId] > 0, "No bids!");

    uint256 amount = latestPrice[auctionId];
    latestPrice[auctionId] = 0; // non reentrancy security
    payable(msg.sender).transfer(amount);
  }

  // verified
  function withdrawFailedAuction(address _contractId, uint256 _tokenId) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    AuctionItem memory auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(auctionItem.bidCount == 0, "Action has bids!");

    IERC721(_contractId).transferFrom(address(this), msg.sender, _tokenId);
  }

  /* View */
  function getAuctionAndBid(address _contractId, uint256 _tokenId) public view returns (bytes32 _auctionId, AuctionItem memory _auctionItem) {
    _auctionId = keccak256(abi.encodePacked(_contractId, _tokenId));
    _auctionItem = auctionItems[_auctionId];
  }

  /* Security */
  modifier nonReentrant(address _contractId, uint256 _tokenId) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId);
    require(!auctionEntered[auctionId], "ReentrancyGuard: reentrant call");
    auctionEntered[auctionId] = true;

    _;
    auctionEntered[auctionId] = false;
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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