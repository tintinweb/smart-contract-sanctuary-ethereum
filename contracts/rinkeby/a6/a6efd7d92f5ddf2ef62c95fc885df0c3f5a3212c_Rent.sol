/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A rental market for Hyperfy Land
/// @author Philbert Burrow
/// @notice This contract requires a centralized party to honor agreements

/// TODO Missing payment escrow and release
/// TODO Create function that locks token in the staking contract

interface IStake {
    function lock(uint256 tokenId, bool status) external;
    function getOwner(uint256 tokenId) external view returns (address);
    function getLockStatus(uint256 tokenId) external view returns (bool);
}

contract Rent is ReentrancyGuard, Ownable {

    address landContract;
    IERC721 public land;
    uint256 tokenIdCount;
    IStake public stake;
    address stakeContract;

    struct Availability {
        uint256 pricePerDay;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 totalDays;
        bool inUse;
        address renter;
        mapping(address => uint256) owed;
    }

    struct TimeSlot {
        uint256 timeStart;
        uint256 timeEnd;
    }
    
    mapping(uint256 => TimeSlot) public timeSlot;
    mapping(uint256 => Availability) availabilityInfo;
    mapping(address => bool) public isBanned;

    /// @notice Sets the address of the land NFT
    /// @param _landContract sets the global land contract address

    function setLandAddress(address _landContract) public onlyOwner {
        landContract = _landContract;
        land = IERC721(landContract);
    }

    /// @notice Sets the address of the staking contracct and applies an interface to it
    /// @param _stakeContract sets the global staking contract address

    function setStakeAddress(address _stakeContract) public onlyOwner {
        stakeContract = _stakeContract;
        stake = IStake(stakeContract);
    }

    event newListing(uint256 indexed tokenId, uint256 pricePerDay, uint256 timeStart, uint256 timeEnd);

    /// @notice Creates a listing for a rental period defined by unix timestamps
    /// @dev Creates a unique ID for the listing, which can be searched via tokenId and then reversed searched via the unique ID (tokenId)
    /// @param tokenId The ID of the land to list
    /// @param pricePerDay The price per day for the listing
    /// @param timeStart The unix timestamp for the start of the listing
    /// @param timeEnd The unix timestamp for the end of the listing

    function list(uint256 tokenId, uint256 pricePerDay, uint256 timeStart, uint256 timeEnd) public {
        require(stake.getOwner(tokenId) == msg.sender, "You are not the owner of this token");

        uint256 totalDays = (timeEnd - timeStart) / 86400;

        availabilityInfo[tokenId].pricePerDay = pricePerDay;
        availabilityInfo[tokenId].timeStart = timeStart;
        availabilityInfo[tokenId].timeEnd = timeEnd;
        availabilityInfo[tokenId].totalDays = totalDays;

        stake.lock(tokenId, true);
        emit newListing(tokenId, pricePerDay, timeStart, timeEnd);
    }

    /// @notice deletes availability information for a listing if it is not being rented
    /// @param tokenId The ID of the availability to delete

    function delist(uint256 tokenId) public {
        require(stake.getOwner(tokenId) == msg.sender, "You are not the owner of this token");
        require(availabilityInfo[tokenId].inUse == false, "This listing is in use");

        if(availabilityInfo[tokenId].owed[msg.sender] > 0) {
            claim(tokenId);
        }

        delete availabilityInfo[tokenId];
        stake.lock(tokenId, false);
    }

    event newRent(uint256 indexed tokenId, address indexed renter, uint256 timeEnd);

    /// @notice Places a bid on a listing
    /// @dev Stores bid in an array which can be found via getavailabilityInfo()
    /// @param tokenId The ID of the listing to bid on
    /// TODO check 

    function rent(uint256 tokenId, uint256 timeEnd) public payable {
        require(availabilityInfo[tokenId].inUse == false, "in use");
        require(availabilityInfo[tokenId].timeEnd > block.timestamp, "listing has expired");
        require(availabilityInfo[tokenId].timeStart < block.timestamp, "listing has not started");
        require(availabilityInfo[tokenId].pricePerDay > 0, "price per day is zero");
        require(stake.getOwner(tokenId) != address(0), "This listing is not available");
        require(isBanned[msg.sender] == false, "You are banned from bidding on this contract");
        require(timeEnd >= block.timestamp + 1 days, "minimum rent time is 1 day");
        uint256 totalCost = availabilityInfo[tokenId].pricePerDay * (timeEnd - block.timestamp) / 86400;
        require(msg.value == totalCost, "Wrong price");
        require(stake.getOwner(tokenId) != msg.sender, "You are the owner of this token");

        availabilityInfo[tokenId].inUse = true;
        availabilityInfo[tokenId].renter = msg.sender;
        timeSlot[tokenId].timeEnd = timeEnd;
        timeSlot[tokenId].timeStart = block.timestamp;

        address recipient = stake.getOwner(tokenId);
        availabilityInfo[tokenId].owed[recipient] = msg.value;

        emit newRent(tokenId, msg.sender, timeEnd);
    }

    event claimed(uint256 indexed tokenId, address indexed renter, uint256 timeEnd);

    /// @notice Claims money owed from rental period and updates listing status
    /// @dev Checks if listing expired > revert usage info > unlock token

    function claim(uint256 tokenId) public {

        require(availabilityInfo[tokenId].owed[msg.sender] > 0, "You are not owed anything");
        require(block.timestamp > timeSlot[tokenId].timeEnd, "timeSlot has not ended");

        // address payable recipient = payable(msg.sender);
        // uint256 amount = availabilityInfo[tokenId].owed[msg.sender];
        
        payable(msg.sender).transfer(availabilityInfo[tokenId].owed[msg.sender]);

        delete availabilityInfo[tokenId].inUse;
        delete availabilityInfo[tokenId].renter;
        delete timeSlot[tokenId];
        delete availabilityInfo[tokenId].owed[msg.sender];

    }

    event newBan(address indexed sender, bool banned);

    /// @notice Bans or unbans a user from bidding through this contract
    /// @param addr The address of the user to ban
    /// @param status True if the user should be banned, false if they should be unbanned
    
    function ban(address addr, bool status) public onlyOwner {
        isBanned[addr] = status;
        emit newBan(addr, status);
    }

    /// @notice Returns listing information for a given listing ID
    /// @dev includes all varialbes from the availabilityInfo struct AND the tokenId of the listing's associated NFT
    /// @param tokenId The ID of the listing to return information for
    /// @return uint256 pricePerDay The price per day of the listing
    /// @return uint256 timeStart The unix timestamp when the rental agreement starts
    /// @return uint256 timeEnd The unix timestamp when the rental agreement ends
    /// @return uint256 totalDays The total number of days the rental agreement lasts
    /// @return bool inUse True if the listing is currently active, false if it is not
    /// @return address renter The address of the renter of the listing, if it is active

    function getAvailabilityInfo(uint256 tokenId) public view returns (uint256, uint256, uint256, uint256, bool, address) {
        return (availabilityInfo[tokenId].pricePerDay, availabilityInfo[tokenId].timeStart, availabilityInfo[tokenId].timeEnd, availabilityInfo[tokenId].totalDays, availabilityInfo[tokenId].inUse, availabilityInfo[tokenId].renter);
    }

    /// @notice Returns information about the active rental period
    /// @dev if no active rental period, returns 0 for all variables
    /// @param tokenId The ID of the listing to return information for

    function getActiveTimeSlot(uint256 tokenId) public view returns (uint256, uint256) {
        return (timeSlot[tokenId].timeStart, timeSlot[tokenId].timeEnd);
    }

    /// @notice Returns how much ETH a

    function getOwed(address addr, uint256 tokenId) public view returns (uint256) {
        return availabilityInfo[tokenId].owed[addr];
    }

    /// @notice Returns the ban status of a user
    /// @param addr The address of the user to check
    /// @return bool True if the user is banned, false if not

    function getBanStatus(address addr) public view returns(bool) {
        return isBanned[addr];
    }

    /// @notice used to enable safe transfers of the land NFT

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
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