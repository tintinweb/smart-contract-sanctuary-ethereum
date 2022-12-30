// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IFeeStorage} from "../../Collections/FeeStorage/IFeeStorage.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenAuction
 */
contract SingleTokenAuction is Pausable, ReentrancyGuard {
    struct Item { uint256 uid; address token_address; uint256 token_id; address owner_of; address curator_address; uint256 curator_fee; uint256 start_price; bool approved; uint256 highest_bid; address highest_bidder; uint256 end_time; uint256 duration; }

    Item[] private _items;
    mapping(address => mapping(uint256 => mapping(address => bool))) private _active_items;
    mapping(uint256 => bool) private _finished;

    address private _meta_unit_tracker_address;
    address private _creator_fee_storage;
  
    constructor(address owner_of_, address meta_unit_tracker_address_, address creator_fee_storage_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        _creator_fee_storage = creator_fee_storage_;
    }
   
    event itemAdded(uint256 uid, address token_address, uint256 token_id, address owner_of, address curator_address, uint256 curator_fee, uint256 start_price, bool approved, uint256 highest_bid, address highest_bidder,uint256 end_time);
    event auctionApproved(uint256 uid, uint256 end_time);
    event bidAdded(uint256 uid, uint256 highest_bid, address highest_bidder);
    event itemResolved(uint256 uid);

    function sale(address token_address, uint256 token_id, address curator_address, uint256 curator_fee, uint256 start_price, uint256 duration) public notPaused nonReentrant {
        require(IERC721(token_address).ownerOf(token_id) == msg.sender, "You are not an owner");
        require(IERC721(token_address).getApproved(token_id) == address(this), "Token is not approved to contract");
        require(!_active_items[token_address][token_id][msg.sender], "Item is already on sale");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, msg.sender, curator_address, curator_fee, start_price, false, 0, address(0), 0, duration));
        _active_items[token_address][token_id][msg.sender] == true;
        emit itemAdded(newItemId, token_address, token_id, msg.sender, curator_address, curator_fee, start_price, false, 0, address(0), duration);
        if (curator_address == msg.sender) {
            setCuratorApproval(newItemId);
        }
    }

    function setCuratorApproval(uint256 uid) public notPaused nonReentrant {
        require(uid < _items.length && _items[uid].uid == uid, "Token does not exists");
        Item memory item = _items[uid];
        require(!item.approved, "Auction is already approved");
        require(item.curator_address == msg.sender, "You are not curator");
        _items[uid].approved = true;
        _items[uid].end_time = block.timestamp + item.duration;
        emit auctionApproved(uid, _items[uid].end_time);
    }

    function bid(uint256 uid) public payable nonReentrant {
        require(uid < _items.length && _items[uid].uid == uid, "Order does not exists");
        Item memory item = _items[uid];
        IERC721 token = IERC721(item.token_address);
        require(block.timestamp <= item.end_time, "Auction has been finished");
        require(token.getApproved(item.token_id) == address(this), "Token is not approved to contract");
        require(token.ownerOf(item.token_id) == item.owner_of, "Token is already sold");
        require(item.approved, "Auction is not approved");
        require(msg.value > item.start_price, "Bid is lower than start price");
        require(msg.value > item.highest_bid, "Bid is lower than previous one");
        require(item.owner_of != msg.sender, "You are an owner of this auction");
        require(item.curator_address != msg.sender, "You are an curator of this auction");
        if (item.highest_bidder != address(0)) {
            payable(item.highest_bidder).send(item.highest_bid);
        }
        _items[uid].highest_bid = msg.value;
        _items[uid].highest_bidder = msg.sender;
        emit bidAdded(uid, _items[uid].highest_bid, _items[uid].highest_bidder);
    }

    function resolve(uint256 uid) public notPaused nonReentrant {
        require(uid < _items.length && _items[uid].uid == uid, "Order does not exists");
        Item memory item = _items[uid];
        IERC721 token = IERC721(item.token_address);
        require(block.timestamp >= item.end_time, "Auction does not finish");
        require(item.curator_address == msg.sender, "You are not curator");
        require(item.approved, "Auction is not approved");
        require(token.getApproved(item.token_id) == address(this), "Token is not approved to contract");
        require(!_finished[uid], "Auction has been resolved");
        if (item.highest_bidder != address(0)) {
            uint256 creator_fee_total = 0;
            address royalty_fee_receiver = address(0);
            uint256 royalty_fee = 0;
            try IFeeStorage(_creator_fee_storage).feeInfo(item.token_address, item.highest_bid) returns (address[] memory creator_fee_receiver_, uint256[] memory creator_fee_, uint256 total_) {
                for (uint256 i = 0; i < creator_fee_receiver_.length; i ++) {
                    payable(creator_fee_receiver_[i]).send(creator_fee_[i]);
                }
                creator_fee_total = total_;
            } catch {}
            try IERC2981(item.token_address).royaltyInfo(item.token_id, item.highest_bid) returns (address royalty_fee_receiver_, uint256 royalty_fee_) {
                royalty_fee_receiver = royalty_fee_receiver_;
                royalty_fee = royalty_fee_;
            } catch {}
            uint256 project_fee = (item.highest_bid * 25) / 1000;
            uint256 curator_fee = (item.highest_bid * item.curator_fee) / 1000;
            if (royalty_fee_receiver != address(0)) payable(royalty_fee_receiver).send(royalty_fee);
            payable(_owner_of).send(project_fee);
            payable(item.curator_address).send(curator_fee);
            payable(item.owner_of).send((item.highest_bid - creator_fee_total - royalty_fee - project_fee - curator_fee));
            IMetaUnitTracker(_meta_unit_tracker_address).track(item.owner_of, item.highest_bid);
            IERC721(item.token_address).safeTransferFrom(item.owner_of, item.highest_bidder, item.token_id);
        }
        _finished[uid] = true;
        _active_items[item.token_address][item.token_id][item.owner_of] = false;
        emit itemResolved(uid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaUnitTracker {
    struct Transaction { address owner_of; uint256 value; uint256 timestamp; }

    function track(address eth_address_, uint256 value_) external;
    function getUserResalesSum(address eth_address_) external view returns(uint256);
    function getUserTransactionQuantity(address eth_address_) external view returns(uint256);
    function getTransactions() external view returns (Transaction[] memory);
    function getTransactionsForPeriod(uint256 from_, uint256 to_) external view returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISingleToken {
    function getRoyalty(uint256 token_id) external returns (uint256);

    function getCreator(uint256 token_id) external returns (address);

    function mint(string memory token_uri, uint256 royalty) external;

    function burn(uint256 token_id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeStorage {
    function feeInfo(address token_address, uint256 salePrice) external view returns (address[] memory, uint256[] memory, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne DAO
 * @title Pausable
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
     * @dev setup owner of this contract with paused off state.
     */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
     * @dev modifier which can be used on child contract for checking if contract services are paused.
     */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
     * @dev function which setup paused variable.
     * @param paused_ new boolean value of paused condition.
     */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
     * @dev function which setup owner variable.
     * @param owner_of_ new owner of contract.
     */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
    }

    /**
     * @dev function returns owner of contract.
     */
    function owner() public view returns (address) {
        return _owner_of;
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}