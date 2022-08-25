//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OnchainCurationManagerV1.sol";

contract OnchainCurationManagerFactory {

    event CreatedCurationManager(
        address indexed creator,
        address indexed curationContractAddress
    );

    function createNewCurationManager(
        string memory _curationEntity,
        string memory _curationSeasonTitle,
        address _initialCurationPassAddress, 
        uint256 _initialCurationLimit, 
        bool _initialPauseState
    )   external returns (address) 
    {
        OnchainCurationManagerV1 newCurationManager = new OnchainCurationManagerV1(
            _curationEntity,
            _curationSeasonTitle,
            _initialCurationPassAddress,
            _initialCurationLimit,
            _initialPauseState
        );

        emit CreatedCurationManager(
            msg.sender,
            address(newCurationManager)
        );

        address newCurationManagerAddress = address(newCurationManager);

        return newCurationManagerAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice Onchain Curation Manager V1
contract OnchainCurationManagerV1 is 
    Ownable, 
    ReentrancyGuard  
{

    /* ===== VARIABLES ===== */

    // iniitalize curation entity
    string public curationEntity;       

    // iniitalize curation season #
    uint256 public curationSeason;    
    
    /// define struct containing season details
    struct SeasonDetails {
        string title;
        address curationPassAddress;
        uint256 curationLimit;
        bool pauseState;
    }

    // initialize seasonDetails struct
    SeasonDetails public seasonDetails;

    // dynamic array that returns all listings currently being curated
    address[] public currentSeasonListings;

    // mapping that stores address of curator for each curated listing in each curation season
    // uint256 season => address listing => address curator
    mapping(uint256 => mapping(address => address)) public curationSeasonDashboard;
    
    // mapping that stores hash of array of prior seasons's final curation lists
    mapping(uint256 => bytes) public curationSeasonArchive;    

    /* ===== EVENTS ===== */
    // /// @notice Emitted when a season is finalized
    // event SeasonFinalized(
    //     uint256 indexed curationSeason,
    //     address indexed finalCurationPassAddress,
    //     uint256 indexed finalCurationLimit,
    //     uint256 finalCurationListLength
    // );

    /* ===== MODIFIERS ===== */

    // checks if msg.sender owns the curation pass NFT
    modifier curationPassCheck() {
        require(
            IERC721(seasonDetails.curationPassAddress).balanceOf(msg.sender) > 0,
            "you do not own the Curation Pass NFT"
        );
        _;
    }

    // checks if listing is already present in curation list
    modifier duplicateCheck(address _listing) {
        require(
            viewCuratorByListingBySeason(curationSeason, _listing) == address(0),   
            "you cannot add a listing that is already on the curation list for this season"
        );
        _;
    }

    // checks if there is curationLimit has been reached
    modifier limitCheck() {
        require(
            currentSeasonListings.length < seasonDetails.curationLimit,
            "the curation list is full. remove a listing before adding another"
        );
        _;        
    }

    // checks if msg.sender is the curator for the listing being removed
    modifier removalCheck(address _listing) {
        require(
            msg.sender == curationSeasonDashboard[curationSeason][_listing],
            "you can only remove listings you have curated yourself"
        );
        _;        
    }    

    // checks if inputted listing + curator addresses are equal to address(0)
    modifier zeroAddressCheck(address _listing, address _curator) {
        require(
            _listing != address(0), 
            "listing address cannot be the zero address"
        );
        require(
            _curator != address(0), 
            "curator address cannot be the zero address"
        );
        _;
    }

    // checks if curation functionality is paused
    modifier pauseCheck() {
        require(
            seasonDetails.pauseState == false,   
            "all curatorial functions are currently paused"
        );
        _;
    }

    /* ===== CONSTRUCTOR ===== */

    // initializes cueration
    constructor(
        string memory _curationEntity,
        string memory _curationSeasonTitle,
        address _initialCurationPassAddress, 
        uint256 _initialCurationLimit, 
        bool _initialPauseState
    ) {
        curationEntity = _curationEntity;
        seasonDetails.title = _curationSeasonTitle;
        seasonDetails.curationPassAddress = _initialCurationPassAddress;
        seasonDetails.curationLimit = _initialCurationLimit;
        seasonDetails.pauseState = _initialPauseState;
        curationSeason = 1;
    }

    /* ===== OWNER FUNCTIONS ===== */

    // update curation entity name
    function setCurationEntity(string calldata _newCurationEntity) 
        onlyOwner 
        external 
    {
        curationEntity = _newCurationEntity;
    }        
    
    // update curation season name
    function setCurationSeasonTitle(string calldata _newCurationSeasonTitle) 
        onlyOwner 
        external 
    {
        seasonDetails.title = _newCurationSeasonTitle;
    }    

    // update ERC721 contract being used to token gate functionality to this contract
    function setCurationPassAddress(address _curationPassAddress) 
        onlyOwner 
        external 
    {
        seasonDetails.curationPassAddress = _curationPassAddress;
    }

    // update maximum number of listings that can be stored within curation list
    function setCurationLimit(uint256 _newCurationLimit) 
        onlyOwner 
        external 
    {
        require(
            _newCurationLimit > currentSeasonListings.length, 
            "cannot set curationLimit to value equal to or smaller than current length of currentSeasonListings array"
        );
        seasonDetails.curationLimit = _newCurationLimit;
    }

    // update value of pause switch
    function setPauseState(bool _newPauseState) 
        onlyOwner 
        external 
    {
        require(
            _newPauseState =! seasonDetails.pauseState, 
            "you cannot update the pause state to its current value"
        );
        // curationPauseState = _newPauseState;
        seasonDetails.pauseState = _newPauseState;
    }

    /// @notice contract owner listing removal function without
    //          removalCheck, pauseCheck, or curationPassCheck
    function ownerRemoveListing(address _listing, address _curator)
        onlyOwner
        nonReentrant
        external
    {
        require(
            curationSeasonDashboard[curationSeason][_listing] == _curator,
            "curator address is not mapped to inputted listing"
        );            
        listingsArrayRemoval(_listing);
        delete curationSeasonDashboard[curationSeason][_listing];
    }    

    /// @notice contract owner listing add function without
    //          pauseCheck or curationPassCheck
    function ownerAddListing(address _listing, address _curator) 
        onlyOwner
        nonReentrant       
        duplicateCheck(_listing)
        limitCheck
        zeroAddressCheck(_listing, _curator)
        external 
    {
        currentSeasonListings.push(_listing);
        curationSeasonDashboard[curationSeason][_listing] = _curator;
    }    


    function resetCurrentSeason()
        onlyOwner
        nonReentrant
        external
    {
        require(
            currentSeasonListings.length > 0,
            "cannot call this function when the curation list is empty"
        );
        for (uint256 i = 0; i < currentSeasonListings.length; i++) {
            curationSeasonDashboard[curationSeason][currentSeasonListings[i]] = address(0);
        }
        delete currentSeasonListings;
    }

    function finalizeSeason(
        string memory _newCurationSeasonTitle,
        address _newCurationPassAddress, 
        uint256 _newCurationLimit, 
        bool _newPauseState
    )
        onlyOwner
        nonReentrant
        external
    {
        seasonDetails.pauseState = true;
        curationSeasonArchive[curationSeason] = abi.encode(
            currentSeasonListings,
            seasonDetails.title,
            seasonDetails.curationPassAddress,
            seasonDetails.curationLimit
        );
        delete currentSeasonListings;

        curationSeason++;

        seasonDetails.title = _newCurationSeasonTitle;
        seasonDetails.curationPassAddress = _newCurationPassAddress;
        seasonDetails.curationLimit = _newCurationLimit;
        seasonDetails.pauseState = _newPauseState;        
    }

    /* ===== CURATION FUNCTIONS ===== */

    // adds listing to array of all active listings + assings curator to listing -> curator mapping
    function addListing(address _listing, address _curator) 
        nonReentrant  
        pauseCheck       
        curationPassCheck
        duplicateCheck(_listing)
        limitCheck
        zeroAddressCheck(_listing, _curator)
        external 
    {
        currentSeasonListings.push(_listing);
        curationSeasonDashboard[curationSeason][_listing] = _curator;
    }

    /// @notice removes listing from array of all active listings + 
    //          removes curator from listing -> curator mapping
    function removeListing(address _listing, address _curator)
        nonReentrant
        pauseCheck
        curationPassCheck
        removalCheck(_listing)
        external
    {
        require(
            curationSeasonDashboard[curationSeason][_listing] == _curator,
            "curator address is not mapped to inputted listing"
        );
        listingsArrayRemoval(_listing);
        delete curationSeasonDashboard[curationSeason][_listing];
    }

    /// @notice removes listing from array of all active listings
    //          can only be called internally by removeListing function
    function listingsArrayRemoval(address _listing) 
        internal 
    {
        for (uint256 i = 0; i < currentSeasonListings.length; i++) {
            if (currentSeasonListings[i] == _listing) {
                currentSeasonListings[i] = currentSeasonListings[currentSeasonListings.length - 1];
                currentSeasonListings.pop();
            }
        }
    }

    /* ===== VIEW FUNCTIONS ===== */

    // view function that returns curation entity name
    function viewCurationEntity() 
        public 
        view 
        returns (string memory) 
    {
        return curationEntity;
    }            

    // view function that returns current curation season
    function viewCurationSeason() 
        public 
        view 
        returns (uint256) 
    {
        return curationSeason;
    }        

    // view seasonDetails
    function viewSeasonDetails() 
        public 
        view 
        returns (string memory, address, uint256, bool) 
    {
        return (
            seasonDetails.title, 
            seasonDetails.curationPassAddress, 
            seasonDetails.curationLimit, 
            seasonDetails.pauseState
        );
    }       

    // view function that returns curation season title
    function viewCurationSeasonTitle() 
        public 
        view 
        returns (string memory) 
    {
        return seasonDetails.title;
    }             

    // view function that returns the maximum number of listings the curation list can hold
    function viewCurationLimit() 
        public 
        view 
        returns (uint256) 
    {
        return seasonDetails.curationLimit;
    }    

    // view function that returns current state of curationPauseState
    function viewCurationPauseState() 
        public 
        view 
        returns (bool) 
    {
        return seasonDetails.pauseState;
    }    
    
    // view function that returns address of NFT contract being used as curation pass
    function viewCurationPassAddress() 
        public 
        view 
        returns (address) 
    {
        return seasonDetails.curationPassAddress;
    }

    // view function that returns array of all active listings
    function viewCurrentSeasonListings() 
        public 
        view 
        returns (address[] memory) 
    {
        // returns empty array if no active listings
        return currentSeasonListings;
    }    


    // view function that returns the curator of a given listing from the current season
    function viewCuratorByListingBySeason(uint256 _curationSeason, address _listing) 
        public 
        view 
        returns (address) 
    {
        // returns address(0) if no curator associated with a given curation season + listing
        return curationSeasonDashboard[_curationSeason][_listing];
    }    

    // view function that returns decoded array of curated listings from a previous season
    function viewCurationArchive(uint256 _curationSeason)
        public
        view
        returns (
            address[] memory pastSeasonListings,
            string memory pastSeasonTitle,
            address pastSeasonCurationPassAddress,
            uint256 pastSeasonCurationLimit
        ) 
    {
        (pastSeasonListings, pastSeasonTitle, pastSeasonCurationPassAddress, pastSeasonCurationLimit) = abi.decode(
            curationSeasonArchive[_curationSeason], 
            (address[], string, address, uint256)
        );

        // returns an error if you enter current or feature curation season #
        return (
            pastSeasonListings, 
            pastSeasonTitle, 
            pastSeasonCurationPassAddress, 
            pastSeasonCurationLimit
        );
    }

    function hasCurationLimitBeenReached() 
        public 
        view 
        returns (bool) 
    {
        if (currentSeasonListings.length < seasonDetails.curationLimit) {
            return false;
        } else {
            return true;
        }
    }

    // view function that checks an addresses' balance of the curation pass NFT
    function viewUserBalanceOfCurationPass(address _address) 
        public 
        view 
        returns (uint256) 
    {
        return IERC721(seasonDetails.curationPassAddress).balanceOf(_address);
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