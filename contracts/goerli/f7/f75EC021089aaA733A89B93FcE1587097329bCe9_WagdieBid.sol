// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 

contract WagdieBid is Ownable {

    event AuctionUpdated(uint16 auctionId, string reward, string imageUrl, uint40 endsAt);
    event CurrentAuction(uint16 auctionId);
    event AuctionFinished(uint16 auctionId, address winner);

    event BidWagdie(uint256 wagdieId, uint16 auctionId);
    event BidRemoved(uint256 wagdieId, uint16 auctionId);
    
    address constant public WAGDIE = 0x55591b07665661D6f4f0556fc5d31e69bF0A3B46;
    uint16 public currentAuction = 0;

    uint16 public auctionsCreated = 0;

    uint16 lastAuctionId = 0;
    
    bool private emergencyWithdrawActive = false;

    mapping(uint16 => Auction) public auctions;
    mapping(uint16 => Wagdie) public wagdieBids;

    struct Auction {
        address winner;
        uint40 endsAt;
        bool finished;
        string reward;
        string imageUrl;
    }

    struct Wagdie {
        address owner;
        uint16 auctionId;
    }

    constructor() {

    }

    function _addTimeToAuction(uint16 _auctionId) internal {
        Auction storage auction = auctions[_auctionId];

        auction.endsAt = auction.endsAt + 10 minutes;

        emit AuctionUpdated(_auctionId, auction.reward, auction.imageUrl, auction.endsAt);
    }


    function bidWagdie(uint16[] calldata wagdieIds) public {
        Auction memory auction = auctions[currentAuction];

        require(auction.endsAt != 0, "Auction is not set");
        require(!auction.finished, "Auction is finished");
        require(block.timestamp < auction.endsAt, "Auction is finished");
        require(wagdieIds.length > 0, "You must bid at least 1 wagdie");

        if(auction.endsAt - block.timestamp <= 10 minutes)
            _addTimeToAuction(currentAuction);

        for(uint i = 0; i < wagdieIds.length; i++)
            _bidWagdie(wagdieIds[i], currentAuction);
    }

    function _bidWagdie(uint16 wagdieId, uint16 auctionId) internal {
        IERC721(WAGDIE).transferFrom(msg.sender, address(this), wagdieId);

        wagdieBids[wagdieId] = Wagdie(msg.sender, auctionId);

        emit BidWagdie(wagdieId, auctionId);
    }

    function removeBids(uint16[] calldata wagdieIds) public {

        for(uint i = 0; i < wagdieIds.length; i++)
            _removeBid(wagdieIds[i]);

    }

    function _removeBid(uint16 wagdieId) internal {

        Wagdie memory wagdie = wagdieBids[wagdieId];
        require(wagdie.owner == msg.sender, "You are not the owner of this wagdie");

        Auction memory auction = auctions[wagdie.auctionId];
        require(auction.finished, "Auction is not finished");
        require(auction.winner != msg.sender, "You are the winner of this auction");

        IERC721(WAGDIE).transferFrom(address(this), msg.sender, wagdieId);

        emit BidRemoved(wagdieId, wagdie.auctionId);
    }

    function emergencyWithdraw(uint16[] calldata wagdieIds) public {
        require(emergencyWithdrawActive, "Emergency withdraw is not active");

        for(uint i = 0; i < wagdieIds.length; i++) {
            require(wagdieBids[wagdieIds[i]].owner == msg.sender, "You are not the owner of this wagdie");

            IERC721(WAGDIE).transferFrom(address(this), msg.sender, wagdieIds[i]);
        }
    }

    function finishAuction(address winner) public onlyOwner {
        Auction storage auction = auctions[currentAuction];

        require(!auction.finished, "Auction is finished");
        require(block.timestamp >= auction.endsAt, "Auction is not finished");

        auction.finished = true;
        auction.winner = winner;

        emit AuctionFinished(currentAuction, winner);
    }

    function createAuction(string memory _reward, string memory _imageUrl, uint40 _length) public onlyOwner {
        uint16 _auctionId = ++auctionsCreated;

        lastAuctionId = _auctionId;

        Auction storage auction = auctions[_auctionId];

        require(_length > 0, "Length must be more than 0");

        require(!auction.finished, "Auction is finished");
        require(auction.endsAt == 0, "Auction is already set");

        auction.reward = _reward;
        auction.imageUrl = _imageUrl;

        //Length of auction in hours for easy input, example _length = 12 will be 12 hours of auction time.
        _length = _length * 1 hours;

        auction.endsAt = uint40(block.timestamp) + _length;

        emit AuctionUpdated(_auctionId, _reward, _imageUrl, _length);
    }

    function updateAuction(uint16 _auctionId, string memory _reward, string memory _imageUrl, uint40 _length) public onlyOwner {
        Auction storage auction = auctions[_auctionId];

        require(!auction.finished, "Auction is finished");

        auction.reward = _reward;
        auction.imageUrl = _imageUrl;

        //Length of auction in hours for easy input, example _length = 12 will be 12 hours of auction time.
        _length = _length * 1 hours;

        auction.endsAt = uint40(block.timestamp) + _length;

        emit AuctionUpdated(_auctionId, _reward, _imageUrl, _length);
    }

    function setCurrentAuction(uint16 _auctionId) public onlyOwner {
        require(auctions[_auctionId].endsAt != 0, "Set the auction before setting it as current");

        currentAuction = _auctionId;

        emit CurrentAuction(_auctionId);
    }

    function getLastAuctionCreated() public view returns (uint16) {
        return lastAuctionId;
    }

    function setEmergencyWithdrawl(bool _emergencyWithdraw) public onlyOwner {
        emergencyWithdrawActive = _emergencyWithdraw;
    }

    function moveWinnersWagdies(uint16 auctionId, uint16[] calldata wagdieIds, address to) public onlyOwner {
        Auction memory auction = auctions[auctionId];

        require(auction.finished, "Auction is not finished");

        for(uint i = 0; i < wagdieIds.length; i++) {
            Wagdie storage wagdie = wagdieBids[wagdieIds[i]];

            require(wagdie.owner == auction.winner, "Wagdie is not the winners");

            IERC721(WAGDIE).transferFrom(address(this), to, wagdieIds[i]);

            wagdie.auctionId = 0;
            wagdie.owner = address(0);

            emit BidRemoved(wagdieIds[i], auctionId);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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