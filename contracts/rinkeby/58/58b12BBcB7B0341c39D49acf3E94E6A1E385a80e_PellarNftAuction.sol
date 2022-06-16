// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract PellarNftAuction is ERC721Holder, ERC1155Holder, Ownable {
  struct AuctionItem {
    bool inited;
    ITEM_TYPE itemType;
    address highestBidder;
    uint256 highestBid;
    uint256 windowTime;
    uint256 minimalBidGap;
    uint256 reservePrice;
    uint256 startAt;
    uint256 endAt;
  }

  struct AuctionHistory {
    address bidder;
    uint256 amount;
    uint256 timestamp;
  }

  // constants
  enum ITEM_TYPE {
    _721,
    _1155
  }

  // variables
  mapping(bytes32 => AuctionItem) public auctionItems;

  mapping(bytes32 => AuctionHistory[]) public auctionHistories;

  mapping(bytes32 => mapping(address => uint256)) public refunds;

  mapping(bytes32 => bool) public auctionEntered;

  // events
  event ItemListed(address indexed _contractId, uint256 indexed _tokenId, uint256 _salt, uint256 _reservePrice, uint256 _startAt, uint256 _endAt);
  event ItemBidded(
    address indexed _contractId,
    uint256 indexed _tokenId,
    uint256 _salt,
    address _newBidder,
    uint256 _newAmount,
    address indexed _oldBidder,
    uint256 _oldAmount
  );
  event AuctionWinnerWithdrawals(address indexed _contractId, uint256 indexed _tokenId, uint256 _salt, address indexed _winner, uint256 _highestBid);

  /* User */
  function bid(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external payable nonReentrant(_contractId, _tokenId, _salt) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(tx.origin == msg.sender, "Not allowed");
    require(auctionItem.inited, "Not allowed"); // require listed auction item
    require(block.timestamp >= auctionItem.startAt, "Auction inactive"); // require auction starts
    require(block.timestamp <= auctionItem.endAt, "Auction ended"); // require auction not ended
    require(
      msg.value >= (auctionItem.highestBid + auctionItem.minimalBidGap) && msg.value >= (auctionItem.reservePrice + auctionItem.minimalBidGap),
      "Bid underpriced"
    ); // require valid ether value

    address oldBidder = auctionItem.highestBidder;
    uint256 oldAmount = auctionItem.highestBid;

    if (oldBidder != address(0)) {
      // funds return for previous
      (bool success, ) = oldBidder.call{ value: oldAmount }("");
      if (!success) {
        refunds[auctionId][msg.sender] = oldAmount;
      }
    }

    // update state
    auctionItem.highestBidder = msg.sender;
    auctionItem.highestBid = msg.value;

    auctionHistories[auctionId].push(AuctionHistory({ bidder: msg.sender, amount: msg.value, timestamp: block.timestamp }));

    if (block.timestamp + auctionItem.windowTime >= auctionItem.endAt) {
      auctionItem.endAt += auctionItem.windowTime;
    }

    // event
    emit ItemBidded(_contractId, _tokenId, _salt, msg.sender, msg.value, oldBidder, oldAmount);
  }

  // verified
  function withdrawProductWon(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!"); // need auction to end
    require(msg.sender == auctionItem.highestBidder || msg.sender == owner(), "Winner only!"); // need winner

    address winner = auctionItem.highestBidder;
    auctionItem.highestBidder = address(0); // convert state to address 0

    if (auctionItem.itemType == ITEM_TYPE._721) {
      IERC721(_contractId).transferFrom(address(this), winner, _tokenId);
    } else {
      IERC1155(_contractId).safeTransferFrom(address(this), winner, _tokenId, 1, "");
    }

    // event
    emit AuctionWinnerWithdrawals(_contractId, _tokenId, _salt, winner, auctionItem.highestBid);
  }

  function bidderWithdraw(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);

    require(refunds[auctionId][msg.sender] > 0, "Not allowed");

    uint256 funds = refunds[auctionId][msg.sender];
    refunds[auctionId][msg.sender] = 0;
    payable(msg.sender).transfer(funds);
  }

  /* Admin */
  function setWindowTime(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _time
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];
    auctionItem.windowTime = _time;
  }

  function setMinimalBidGap(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _bidGap
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];
    auctionItem.minimalBidGap = _bidGap;
  }

  // verified
  function createAuction(
    ITEM_TYPE _type,
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _windowTime,
    uint256 _minimalBidGap,
    uint256 _reservePrice,
    uint256 _startAt,
    uint256 _endAt
  ) external onlyOwner {
    (bytes32 auctionId, AuctionItem memory auctionItem) = getAuctionAndBid(_contractId, _tokenId, _salt);
    require(!auctionItem.inited, "Already exists");
    require(_endAt >= block.timestamp && _startAt < _endAt, "Input invalid");

    if (_type == ITEM_TYPE._721) {
      IERC721(_contractId).transferFrom(msg.sender, address(this), _tokenId);
    } else {
      IERC1155(_contractId).safeTransferFrom(msg.sender, address(this), _tokenId, 1, "");
    }

    auctionItems[auctionId] = AuctionItem({
      inited: true,
      itemType: _type,
      highestBidder: address(0),
      highestBid: 0,
      windowTime: _windowTime,
      minimalBidGap: _minimalBidGap,
      reservePrice: _reservePrice,
      startAt: _startAt,
      endAt: _endAt
    });

    // emit
    emit ItemListed(_contractId, _tokenId, _salt, _reservePrice, _startAt, _endAt);
  }

  // verified
  function withdraw(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem storage auctionItem = auctionItems[auctionId];

    require(auctionItem.inited, "Not allowed");
    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(auctionItem.highestBid > 0, "No bids!");

    uint256 amount = auctionItem.highestBid;
    auctionItem.highestBid = 0;
    payable(msg.sender).transfer(amount);
  }

  // verified
  function withdrawFailedAuction(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) external onlyOwner {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    AuctionItem memory auctionItem = auctionItems[auctionId];

    require(block.timestamp > auctionItem.endAt, "Auction active!");
    require(auctionHistories[auctionId].length == 0, "Action has bids!");

    if (auctionItem.itemType == ITEM_TYPE._721) {
      IERC721(_contractId).transferFrom(address(this), msg.sender, _tokenId);
    } else {
      IERC1155(_contractId).safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
    }
  }

  /* View */
  function getAuctionAndBid(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) public view returns (bytes32 _auctionId, AuctionItem memory _auctionItem) {
    _auctionId = keccak256(abi.encodePacked(_contractId, _tokenId, _salt));
    _auctionItem = auctionItems[_auctionId];
  }

  function getAuctionHistories(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt,
    uint256 _from,
    uint256 _to
  ) public view returns (bool hasNext, AuctionHistory[] memory histories) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);

    uint256 size = auctionHistories[auctionId].length;
    hasNext = size > _to;

    _to = size > _to ? _to : size;

    histories = new AuctionHistory[](_to - _from);

    for (uint256 i = _from; i < _to; i++) {
      histories[i - _from] = auctionHistories[auctionId][i];
    }
  }

  /* Security */
  modifier nonReentrant(
    address _contractId,
    uint256 _tokenId,
    uint256 _salt
  ) {
    (bytes32 auctionId, ) = getAuctionAndBid(_contractId, _tokenId, _salt);
    require(!auctionEntered[auctionId], "ReentrancyGuard: reentrant call");
    auctionEntered[auctionId] = true;

    _;
    auctionEntered[auctionId] = false;
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
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