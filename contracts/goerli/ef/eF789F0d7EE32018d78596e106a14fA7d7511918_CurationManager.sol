// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title CurationManager
/// @notice Facilitates on-chain curation of a dynamic array of ethereum addresses 
contract CurationManager is Ownable {

    /* ===== ERRORS ===== */
    
    /// @notice invalid curation pass
    error Access_MissingPass();

    /// @notice unauthorized access
    error Access_Unauthorized();

    /// @notice curation is inactive
    error Inactive();

    /// @notice curation is finalized
    error Finalized();    

    /// @notice duplicate listing
    error ListingAlreadyExists();

    /// @notice exceeding curation limit
    error CurationLimitExceeded();    

    /* ===== EVENTS ===== */
    event ListingAdded(
        address indexed curator, 
        address indexed listingAddress
    );

    event ListingRemoved(
        address indexed curator,
        address indexed listingAddress
    );

    event TitleUpdated(
        address indexed sender, 
        string title
    );

    event CurationPassUpdated(
        address indexed sender, 
        address curationPass
    );

    event CurationLimitUpdated(
        address indexed sender, 
        uint256 curationLimit
    );    

    event CurationPaused(address sender);

    event CurationResumed(address sender);

    event CurationFinalized(address sender);

    /* ===== VARIABLES ===== */

    // dynamic array of ethereum addresss where curation listings are stored
    address[] public listings;

    // ethereum address -> curator address mapping
    mapping(address => address) public listingCurators;

    // title of curation contract 
    string public title;

    // intitalizing curation pass used to gate curation functionality 
    IERC721 public curationPass;

    // public bool that freezes all curation activity for curators
    bool public isActive;

    // public bool that freezes all curation activity for both contract owner + curators
    bool public isFinalized = false;

    // caps length of listings array. unlimited curation limit if set to 0
    uint256 public curationLimit;

    /* ===== MODIFIERS ===== */

    // checks if _msgSender is contract owner or has a curation pass
    modifier onlyOwnerOrCurator() {
        if (
            owner() != _msgSender() && curationPass.balanceOf(_msgSender()) == 0
        ) {
            revert Access_MissingPass();
        }

        _;
    }

    // checks if curation functionality is active
    modifier onlyIfActive() {
        if (isActive == false) {
            revert Inactive();
        }

        _;
    }

    // checks if curation functionality is finalized
    modifier onlyIfFinalized() {
        if (isFinalized == true) {
            revert Finalized();
        }

        _;
    }

    // checks if curation limit has been reached
    modifier onlyIfLimit() {
        if (curationLimit != 0 && listings.length == curationLimit) {
            revert CurationLimitExceeded();
        }        
        
        _;
    }    

    /* ===== CONSTRUCTOR ===== */

    constructor(
        string memory _title, 
        IERC721 _curationPass, 
        uint256 _curationLimit,
        bool _isActive
    ) {
        title = _title;
        curationPass = _curationPass;
        curationLimit = _curationLimit;
        isActive = _isActive;
        if (isActive == true) {
            emit CurationResumed(_msgSender());
        } else {
            emit CurationPaused(_msgSender());
        }
    }

    /* ===== CURATION FUNCTIONS ===== */

    /// @notice add listing to listings array + address -> curator mapping
    function addListing(address listing)
        external
        onlyIfActive
        onlyOwnerOrCurator
        onlyIfLimit
    {
        if (listingCurators[listing] != address(0)) {
            revert ListingAlreadyExists();
        }

        require(
            listing != address(0),
            "listing address cannot be the zero address"
        );

        listingCurators[listing] = _msgSender();

        listings.push(listing);

        emit ListingAdded(_msgSender(), listing);
    }

    /// @notice removes listing from listings array + address -> curator mapping
    function removeListing(address listing)
        external
        onlyIfActive
        onlyOwnerOrCurator
    {
        if (
            owner() != _msgSender() && listingCurators[listing] != _msgSender()
        ) {
            revert Access_Unauthorized();
        }

        delete listingCurators[listing];
        removeByValue(listing);

        emit ListingRemoved(_msgSender(), listing);
    }

    /* ===== OWNER FUNCTIONS ===== */

    /// @notice update publicly discoverable title of curation contract
    function updateTitle(string memory _title) public onlyOwner {
        title = _title;

        emit TitleUpdated(_msgSender(), _title);
    }

    /// @notice update address of ERC721 contract being used as curation pass
    function updateCurationPass(IERC721 _curationPass) public onlyOwner {
        curationPass = _curationPass;

        emit CurationPassUpdated(_msgSender(), address(_curationPass));
    }

    /// @notice update maximum length of listings array. 0 = infinite
    function updateCurationLimit(uint256 _newLimit) public onlyOwner {
        require(
            _newLimit > listings.length,
            "cannot set curationLimit to value equal to or smaller than current length of listings array"
        );
        curationLimit = _newLimit;

        emit CurationLimitUpdated(_msgSender(), _newLimit);
    }

    /// @notice flips state of isActive bool
    function flipIsActiveBool() 
        public 
        onlyIfFinalized
        onlyOwner 
    {
        if (isActive == true) {
            isActive = false;
            emit CurationPaused(_msgSender());
        } else {
            isActive = true;
            emit CurationResumed(_msgSender());
        }        
    }

    /// @notice updates contract so that no further curation can occur from contract owner or curator
    function finalizeCuration() public onlyOwner {
        if (isActive == false) {
            isFinalized == true;
            emit CurationFinalized(_msgSender());
            return;
        }

        isActive = false;
        emit CurationPaused(_msgSender());

        isFinalized = true;
        emit CurationFinalized(_msgSender());
    }

    // addListing functionality without isActive check
    function onwerAddListing(address listing)
        external
        onlyIfLimit
        onlyIfFinalized
        onlyOwner
    {
        if (listingCurators[listing] != address(0)) {
            revert ListingAlreadyExists();
        }

        require(
            listing != address(0),
            "listing address cannot be the zero address"
        );

        listingCurators[listing] = _msgSender();

        listings.push(listing);

        emit ListingAdded(_msgSender(), listing);
    }

    /// removeListing functionality without isActive or Access_Unauthorized check
    function ownerRemoveListing(address listing)
        external
        onlyIfFinalized
        onlyOwner
    {
        delete listingCurators[listing];
        removeByValue(listing);

        emit ListingRemoved(_msgSender(), listing);
    }    

    /* ===== VIEW FUNCTIONS ===== */

    // view function that returns array of all active listings
    function viewAllListings() 
        external 
        view 
        returns (address[] memory) 
    {
        // returns empty array if no active listings
        return listings;
    }    

    /* ===== INTERNAL HELPERS ===== */
    
    // finds index of listing in listings array
    function find(address value) internal view returns (uint256) {
        uint256 i = 0;
        while (listings[i] != value) {
            i++;
        }
        return i;
    }

    // moves listing to end of listings array and removes it
    function removeByIndex(uint256 index) internal {
        if (index >= listings.length) return;

        for (uint256 i = index; i < listings.length - 1; i++) {
            listings[i] = listings[i + 1];
        }

        listings.pop();
    }

    // combines find + removeByIndex internal functions to remove 
    function removeByValue(address value) internal {
        uint256 i = find(value);
        removeByIndex(i);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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