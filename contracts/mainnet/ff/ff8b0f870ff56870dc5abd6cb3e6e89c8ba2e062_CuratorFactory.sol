// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { UUPS } from "./lib/proxy/UUPS.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ERC1967Proxy } from "./lib/proxy/ERC1967Proxy.sol";
import { ICuratorFactory } from "./interfaces/ICuratorFactory.sol";
import { ICurator } from "./interfaces/ICurator.sol";
import { Curator } from "./Curator.sol";

/**
 * @notice Storage contracts
 */
abstract contract CuratorFactoryStorageV1 {
    address public defaultMetadataRenderer;

    mapping(address => mapping(address => bool)) internal isUpgrade;

    uint256[50] __gap;
}

/**
 * @notice Base contract for curation functioanlity. Inherits ERC721 standard from CuratorSkeletonNFT.sol
 *      (curation information minted as non-transferable "listingRecords" to curators to allow for easy integration with NFT indexers)
 * @dev For curation contracts: assumes 1. linear mint order
 * @author [email protected]
 *
 */
contract CuratorFactory is ICuratorFactory, UUPS, Ownable, CuratorFactoryStorageV1 {
    address public immutable curatorImpl;
    bytes32 public immutable curatorHash;

    constructor(address _curatorImpl) payable initializer {
        curatorImpl = _curatorImpl;
        curatorHash = keccak256(abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(_curatorImpl, "")));
    }

    function setDefaultMetadataRenderer(address _renderer) external {
        defaultMetadataRenderer = _renderer;

        emit HasNewMetadataRenderer(_renderer);
    }

    function initialize(address _owner, address _defaultMetadataRenderer) external initializer {
        __Ownable_init(_owner);
        defaultMetadataRenderer = _defaultMetadataRenderer;
    }

    function deploy(
        address curationManager,
        string memory name,
        string memory symbol,
        address tokenPass,
        bool initialPause,
        uint256 curationLimit,
        address renderer,
        bytes memory rendererInitializer,
        ICurator.Listing[] memory listings
    ) external returns (address curator) {
        if (renderer == address(0)) {
            renderer = defaultMetadataRenderer;
        }

        curator = address(
            new ERC1967Proxy(
                curatorImpl,
                abi.encodeWithSelector(
                    ICurator.initialize.selector,
                    curationManager,
                    name,
                    symbol,
                    tokenPass,
                    initialPause,
                    curationLimit,
                    renderer,
                    rendererInitializer,
                    listings
                )
            )
        );

        emit CuratorDeployed(curator, curationManager, msg.sender);
    }

    function isValidUpgrade(address _baseImpl, address _newImpl) external view returns (bool) {
        return isUpgrade[_baseImpl][_newImpl];
    }

    function addValidUpgradePath(address _baseImpl, address _newImpl) external onlyOwner {
        isUpgrade[_baseImpl][_newImpl] = true;
        emit RegisteredUpgradePath(_baseImpl, _newImpl);
    }

    function _authorizeUpgrade(address _newImpl) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IUUPS } from "../interfaces/IUUPS.sol";
import { ERC1967Upgrade } from "./ERC1967Upgrade.sol";

/// @title UUPS
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/UUPSUpgradeable.sol)
/// - Uses custom errors declared in IUUPS
/// - Inherits a modern, minimal ERC1967Upgrade
abstract contract UUPS is IUUPS, ERC1967Upgrade {
    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    /// @dev The address of the implementation
    address private immutable __self = address(this);

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures that execution is via proxy delegatecall with the correct implementation
    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    /// @dev Ensures that execution is via direct call
    modifier notDelegated() {
        if (address(this) != __self) revert ONLY_CALL();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Hook to authorize an implementation upgrade
    /// @param _newImpl The new implementation address
    function _authorizeUpgrade(address _newImpl) internal virtual;

    /// @notice Upgrades to an implementation
    /// @param _newImpl The new implementation address
    function upgradeTo(address _newImpl) external onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, "", false);
    }

    /// @notice Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function upgradeToAndCall(address _newImpl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_newImpl);
        _upgradeToAndCallUUPS(_newImpl, _data, true);
    }

    /// @notice The storage slot of the implementation address
    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IOwnable } from "../interfaces/IOwnable.sol";
import { Initializable } from "../utils/Initializable.sol";

/// @title Ownable
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (access/OwnableUpgradeable.sol)
/// - Uses custom errors declared in IOwnable
/// - Adds optional two-step ownership transfer (`safeTransferOwnership` + `acceptOwnership`)
abstract contract Ownable is IOwnable, Initializable {
    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending owner
    address internal _pendingOwner;

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) revert ONLY_OWNER();
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner) internal onlyInitializing {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @notice The address of the owner
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";

import { IERC1967Upgrade } from "../interfaces/IERC1967Upgrade.sol";
import { ERC1967Upgrade } from "./ERC1967Upgrade.sol";

/// @title ERC1967Proxy
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Proxy.sol)
/// - Inherits a modern, minimal ERC1967Upgrade
contract ERC1967Proxy is IERC1967Upgrade, Proxy, ERC1967Upgrade {
    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @dev Initializes the proxy with an implementation contract and encoded function call
    /// @param _logic The implementation address
    /// @param _data The encoded function call
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev The address of the current implementation
    function _implementation() internal view virtual override returns (address) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @notice Curator factory allows deploying and setting up new curators
 * @author [email protected]
 */
interface ICuratorFactory {
    /// @notice Emitted when a curator is deployed
    event CuratorDeployed(address curator, address owner, address deployer);
    /// @notice Emitted when a valid upgrade path is registered by the owner
    event RegisteredUpgradePath(address implFrom, address implTo);
    /// @notice Emitted when a new metadata renderer is set
    event HasNewMetadataRenderer(address);

    /// @notice Getter to determine if a contract upgrade path is valid.
    function isValidUpgrade(address baseImpl, address newImpl) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * Curator interfaces
 */
interface ICurator {
    /// @notice Convience getter for Generic/unknown types (default 0). Used for metadata as well.
    function CURATION_TYPE_GENERIC() external view returns (uint16);
    /// @notice Convience getter for NFT contract types. Used for metadata as well.
    function CURATION_TYPE_NFT_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for generic contract types. Used for metadata as well.
    function CURATION_TYPE_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for curation contract types. Used for metadata as well.
    function CURATION_TYPE_CURATION_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for NFT item types. Used for metadata as well.
    function CURATION_TYPE_NFT_ITEM() external view returns (uint16);
    /// @notice Convience getter for wallet types. Used for metadata as well.
    function CURATION_TYPE_WALLET() external view returns (uint16);
    /// @notice Convience getter for ZORA drops contract types. Used for metadata as well.
    function CURATION_TYPE_ZORA_EDITION() external view returns (uint16);

    /// @notice Shared listing struct for both access and storage.
    struct Listing {
        /// @notice Address that is curated
        address curatedAddress;
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint96 selectedTokenId;
        /// @notice Address that curated this entry
        address curator;
        /// @notice Curation type (see public getters on contract for list of types)
        uint16 curationTargetType;
        /// @notice Optional sort order, can be negative. Utilized optionally like css z-index for sorting.
        int32 sortOrder;
        /// @notice If the token ID applies to the curation (can be whole contract or a specific tokenID)
        bool hasTokenId;
        /// @notice ChainID for curated contract
        uint16 chainId;
    }

    /// @notice Getter for a single listing id
    function getListing(uint256 listingIndex) external view returns (Listing memory);

    /// @notice Getter for a all listings
    function getListings() external view returns (Listing[] memory activeListings);

    /// @notice Total supply getter for number of active listings
    function totalSupply() external view returns (uint256);

    /// @notice Removes a list of listings. Same as `burn` but supports multiple listings.
    function removeListings(uint256[] calldata listingIds) external;

    /// @notice Removes a single listing. Named for ERC721 de-facto compat
    function burn(uint256 listingId) external;

    /// @notice Emitted when a listing is added
    event ListingAdded(address indexed curator, Listing listing);

    /// @notice Emitted when a listing is removed
    event ListingRemoved(address indexed curator, Listing listing);

    /// @notice The token pass has been updated for the curation
    /// @dev Any users that have already curated something still can delete their curation.
    event TokenPassUpdated(address indexed owner, address tokenPass);

    /// @notice A new renderer is set
    event SetRenderer(address);

    /// @notice Curation Pause has been udpated.
    event CurationPauseUpdated(address indexed owner, bool isPaused);

    /// @notice Curation limit has beeen updated
    event UpdatedCurationLimit(uint256 newLimit);

    /// @notice Sort order has been updated
    event UpdatedSortOrder(uint256[] ids, int32[] sorts, address updatedBy);

    /// @notice This contract is scheduled to be frozen
    event ScheduledFreeze(uint256 timestamp);

    /// @notice Pass is required to manage curation but not held by attempted updater.
    error PASS_REQUIRED();

    /// @notice Only the curator of a listing (or owner) can manage that curation
    error ONLY_CURATOR();

    /// @notice Wrong curator for the listing when attempting to access the listing.
    error WRONG_CURATOR_FOR_LISTING(address setCurator, address expectedCurator);

    /// @notice Action is unable to complete because the curation is paused.
    error CURATION_PAUSED();

    /// @notice The pause state needs to be toggled and cannot be set to it's current value.
    error CANNOT_SET_SAME_PAUSED_STATE();

    /// @notice Error attempting to update the curation after it has been frozen
    error CURATION_FROZEN();

    /// @notice The curation has gone above the curation limit
    error TOO_MANY_ENTRIES();

    /// @notice Access not allowed by given user
    error ACCESS_NOT_ALLOWED();

    /// @notice attempt to get owner of an unowned / burned token
    error TOKEN_HAS_NO_OWNER();

    /// @notice Array input lengths don't match for sort orders
    error INVALID_INPUT_LENGTH();

    /// @notice Curation limit can only be increased, not decreased.
    error CANNOT_UPDATE_CURATION_LIMIT_DOWN();

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _tokenPass,
        bool _pause,
        uint256 _curationLimit,
        address _renderer,
        bytes memory _rendererInitializer,
        Listing[] memory _initialListings
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { UUPS } from "./lib/proxy/UUPS.sol";
import { ICurator } from "./interfaces/ICurator.sol";
import { Ownable } from "./lib/utils/Ownable.sol";
import { ICuratorFactory } from "./interfaces/ICuratorFactory.sol";
import { CuratorSkeletonNFT } from "./CuratorSkeletonNFT.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";
import { CuratorStorageV1 } from "./CuratorStorageV1.sol";

/**
 * @notice Base contract for curation functioanlity. Inherits ERC721 standard from CuratorSkeletonNFT.sol
 *      (curation information minted as non-transferable "listingRecords" to curators to allow for easy integration with NFT indexers)
 * @dev For curation contracts: assumes 1. linear mint order
 * @author [email protected]
 *
 */

contract Curator is 
    ICurator, 
    UUPS, 
    Ownable, 
    CuratorStorageV1, 
    CuratorSkeletonNFT 
{
    // Public constants for curation types.
    // Allows for adding new types later easily compared to a enum.
    uint16 public constant CURATION_TYPE_GENERIC = 0;
    uint16 public constant CURATION_TYPE_NFT_CONTRACT = 1;
    uint16 public constant CURATION_TYPE_CURATION_CONTRACT = 2;
    uint16 public constant CURATION_TYPE_CONTRACT = 3;
    uint16 public constant CURATION_TYPE_NFT_ITEM = 4;
    uint16 public constant CURATION_TYPE_WALLET = 5;
    uint16 public constant CURATION_TYPE_ZORA_EDITION = 6;

    /// @notice Reference to factory contract
    ICuratorFactory private immutable curatorFactory;

    /// @notice Modifier that ensures curation functionality is active and not frozen
    modifier onlyActive() {
        if (isPaused && msg.sender != owner()) {
            revert CURATION_PAUSED();
        }

        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }

        _;
    }

    /// @notice Modifier that restricts entry access to an admin or curator
    /// @param listingId to check access for
    modifier onlyCuratorOrAdmin(uint256 listingId) {
        if (owner() != msg.sender || idToListing[listingId].curator != msg.sender) {
            revert ACCESS_NOT_ALLOWED();
        }

        _;
    }

    /// @notice Global constructor – these variables will not change with further proxy deploys
    /// @param _curatorFactory Curator Factory Address
    constructor(address _curatorFactory) payable initializer {
        curatorFactory = ICuratorFactory(_curatorFactory);
    }


    ///  @dev Create a new curation contract
    ///  @param _owner User that owns and can accesss contract admin functionality
    ///  @param _name Contract name
    ///  @param _symbol Contract symbol
    ///  @param _curationPass ERC721 contract whose ownership gates access to curation functionality
    ///  @param _pause Sets curation active state upon initialization 
    ///  @param _curationLimit Sets cap for number of listings that can be curated at any time. Doubles as MaxSupply check. 0 = uncapped 
    ///  @param _renderer Renderer contract to use
    ///  @param _rendererInitializer Bytes encoded string to pass into renderer. Leave blank if using SVGMetadataRenderer
    ///  @param _initialListings Array of Listing structs to curate (aka mint) upon initialization
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _curationPass,
        bool _pause,
        uint256 _curationLimit,
        address _renderer,
        bytes memory _rendererInitializer,
        Listing[] memory _initialListings
    ) external initializer {
        // Setup owner role
        __Ownable_init(_owner);
        // Setup contract name + symbol
        contractName = _name;
        contractSymbol = _symbol;
        // Setup curation pass. MUST be set to a valid ERC721 address
        curationPass = IERC721Upgradeable(_curationPass);
        // Setup metadata renderer
        _updateRenderer(IMetadataRenderer(_renderer), _rendererInitializer);
        // Setup initial curation active state
        if (_pause) {
            _setCurationPaused(_pause);
        }
        // Setup intial curation limit
        if (_curationLimit != 0) {
            _updateCurationLimit(_curationLimit);
        }
        // Setup initial listings to curate
        if (_initialListings.length != 0) {
            _addListings(_initialListings, _owner);
        }
    }

    /// @dev Getter for acessing Listing information for a specific tokenId
    /// @param index aka tokenId to retrieve Listing info for 
    function getListing(uint256 index) external view override returns (Listing memory) {
        ownerOf(index);
        return idToListing[index];
    }

    /// @dev Getter for acessing Listing information for all active listings
    function getListings() external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](numAdded - numRemoved);

            uint256 activeIndex;

            for (uint256 i; i < numAdded; ++i) {
                if (idToListing[i].curator == address(0)) {
                    continue;
                }

                activeListings[activeIndex] = idToListing[i];
                ++activeIndex;
            }
        }
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***          ADMIN FUNCTIONS           ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev Allows contract owner to update curation limit
    /// @param newLimit new curationLimit to assign
    function updateCurationLimit(uint256 newLimit) external onlyOwner {
        _updateCurationLimit(newLimit);
    }

    function _updateCurationLimit(uint256 newLimit) internal {

        // Prevents owner from updating curationLimit below current number of active Listings
        if (curationLimit < newLimit && curationLimit != 0) {
            revert CANNOT_UPDATE_CURATION_LIMIT_DOWN();
        }
        curationLimit = newLimit;
        emit UpdatedCurationLimit(newLimit);
    }

    /// @dev Allows contract owner to freeze all contract functionality starting from a given Unix timestamp
    /// @param timestamp unix timestamp in seconds
    function freezeAt(uint256 timestamp) external onlyOwner {

        // Prevents owner from adjusting freezeAt time if contract alrady frozen
        if (frozenAt != 0 && frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
        }
        frozenAt = timestamp;
        emit ScheduledFreeze(frozenAt);
    }

    /// @dev Allows contract owner to update renderer address and pass in an optional initializer for the new renderer
    /// @param _newRenderer address of new renderer
    /// @param _rendererInitializer bytes encoded string value passed into new renderer 
    function updateRenderer(address _newRenderer, bytes memory _rendererInitializer) external onlyOwner {
        _updateRenderer(IMetadataRenderer(_newRenderer), _rendererInitializer);
    }

    function _updateRenderer(IMetadataRenderer _newRenderer, bytes memory _rendererInitializer) internal {
        renderer = _newRenderer;

        // If data provided, call initalize to new renderer replacement.
        if (_rendererInitializer.length > 0) {
            renderer.initializeWithData(_rendererInitializer);
        }
        emit SetRenderer(address(renderer));
    }

    /// @dev Allows contract owner to update the ERC721 Curation Pass being used to restrict access to curation functionality
    /// @param _curationPass address of new ERC721 Curation Pass
    function updateCurationPass(IERC721Upgradeable _curationPass) public onlyOwner {
        curationPass = _curationPass;

        emit TokenPassUpdated(msg.sender, address(_curationPass));
    }

    /// @dev Allows contract owner to update the ERC721 Curation Pass being used to restrict access to curation functionality
    /// @param _setPaused boolean of new curation active state
    function setCurationPaused(bool _setPaused) public onlyOwner {
        
        // Prevents owner from updating the curation active state to the current active state
        if (isPaused == _setPaused) {
            revert CANNOT_SET_SAME_PAUSED_STATE();
        }

        _setCurationPaused(_setPaused);
    }

    function _setCurationPaused(bool _setPaused) internal {
        isPaused = _setPaused;

        emit CurationPauseUpdated(msg.sender, isPaused);
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***         CURATOR FUNCTIONS          ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev Allows owner or curator to curate Listings --> which mints a listingRecord token to the msg.sender
    /// @param listings array of Listing structs
    function addListings(Listing[] memory listings) external onlyActive {
        
        // Access control for non owners to acess addListings functionality 
        if (msg.sender != owner()) {
            
            // ensures that curationPass is a valid ERC721 address
            if (address(curationPass).code.length == 0) {
                revert PASS_REQUIRED();
            }

            // checks if non-owner msg.sender owns the Curation Pass
            try curationPass.balanceOf(msg.sender) returns (uint256 count) {
                if (count == 0) {
                    revert PASS_REQUIRED();
                }
            } catch {
                revert PASS_REQUIRED();
            }
        }

        _addListings(listings, msg.sender);
    }

    function _addListings(Listing[] memory listings, address sender) internal {
        if (curationLimit != 0 && numAdded - numRemoved + listings.length > curationLimit) {
            revert TOO_MANY_ENTRIES();
        }

        for (uint256 i = 0; i < listings.length; ++i) {
            if (listings[i].curator != sender) {
                revert WRONG_CURATOR_FOR_LISTING(listings[i].curator, msg.sender);
            }
            if (listings[i].chainId == 0) {
                listings[i].chainId = uint16(block.chainid);
            }
            idToListing[numAdded] = listings[i];
            _mint(listings[i].curator, numAdded);
            ++numAdded;
        }
    }

    /// @dev Allows owner or curator to curate Listings --> which mints listingRecords to the msg.sender
    /// @param tokenIds listingRecords to update SortOrders for    
    /// @param sortOrders sortOrdres to update listingRecords
    function updateSortOrders(uint256[] calldata tokenIds, int32[] calldata sortOrders) external onlyActive {
        
        // prevents users from submitting invalid inputs
        if (tokenIds.length != sortOrders.length) {
            revert INVALID_INPUT_LENGTH();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setSortOrder(tokenIds[i], sortOrders[i]);
        }
        emit UpdatedSortOrder(tokenIds, sortOrders, msg.sender);
    }

    // prevents non-owners from updating the SortOrder on a listingRecord they did not curate themselves 
    function _setSortOrder(uint256 listingId, int32 sortOrder) internal onlyCuratorOrAdmin(listingId) {
        idToListing[listingId].sortOrder = sortOrder;
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***     listingRecord NFT Functions    ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev allows owner or curators to burn a specfic listingRecord NFT which also removes it from the listings mapping
    /// @param listingId listingId to burn        
    function burn(uint256 listingId) public onlyActive {

        // ensures that msg.sender must be contract owner or the curator of the specific listingId 
        _burnTokenWithChecks(listingId);
    }


    /// @dev allows owner or curators to burn specfic listingRecord NFTs which also removes them from the listings mapping
    /// @param listingIds array of listingIds to burn    
    function removeListings(uint256[] calldata listingIds) external onlyActive {
        unchecked {
            for (uint256 i = 0; i < listingIds.length; ++i) {
                _burnTokenWithChecks(listingIds[i]);
            }
        }
    }

    function _exists(uint256 id) internal view virtual override returns (bool) {
        return idToListing[id].curator != address(0);
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        for (uint256 i = 0; i < numAdded; ++i) {
            if (idToListing[i].curator == _owner) {
                ++balance;
            }
        }
    }

    function name() external view override returns (string memory) {
        return contractName;
    }

    function symbol() external view override returns (string memory) {
        return contractSymbol;
    }

    function totalSupply() public view override(CuratorSkeletonNFT, ICurator) returns (uint256) {
        return numAdded - numRemoved;
    }

    /// @param id id to check owner for
    function ownerOf(uint256 id) public view virtual override returns (address) {
        if (!_exists(id)) {
            revert TOKEN_HAS_NO_OWNER();
        }
        return idToListing[id].curator;
    }

    /// @notice Token URI Getter, proxies to metadataRenderer
    /// @param tokenId id to get tokenURI info for     
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return renderer.tokenURI(tokenId);
    }

    /// @notice Contract URI Getter, proxies to metadataRenderer    
    function contractURI() external view override returns (string memory) {
        return renderer.contractURI();
    }

    function _burnTokenWithChecks(uint256 listingId) internal onlyActive onlyCuratorOrAdmin(listingId) {
        Listing memory _listing = idToListing[listingId];
        // Process NFT Burn
        _burn(listingId);

        // Remove listing
        delete idToListing[listingId];
        unchecked {
            ++numRemoved;
        }

        emit ListingRemoved(msg.sender, _listing);
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***         UPGRADE FUNCTIONS          ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @notice Connects this contract to the factory upgrade gate
    /// @param _newImpl proposed new upgrade implementation    
    /// @dev Only can be called by contract owner    
    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        if (!curatorFactory.isValidUpgrade(_getImplementation(), _newImpl)) {
            revert INVALID_UPGRADE(_newImpl);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { IERC1967Upgrade } from "./IERC1967Upgrade.sol";

/// @title IUUPS
/// @author Rohan Kulkarni
/// @notice The external UUPS errors and functions
interface IUUPS is IERC1967Upgrade, IERC1822Proxiable {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if not called directly
    error ONLY_CALL();

    /// @dev Reverts if not called via delegatecall
    error ONLY_DELEGATECALL();

    /// @dev Reverts if not called via proxy
    error ONLY_PROXY();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Upgrades to an implementation
    /// @param newImpl The new implementation address
    function upgradeTo(address newImpl) external;

    /// @notice Upgrades to an implementation with an additional function call
    /// @param newImpl The new implementation address
    /// @param data The encoded function call
    function upgradeToAndCall(address newImpl, bytes memory data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";

import { IERC1967Upgrade } from "../interfaces/IERC1967Upgrade.sol";
import { Address } from "../utils/Address.sol";

/// @title ERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/ERC1967/ERC1967Upgrade.sol)
/// - Uses custom errors declared in IERC1967Upgrade
/// - Removes ERC1967 admin and beacon support
abstract contract ERC1967Upgrade is IERC1967Upgrade {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.rollback')) - 1)
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Upgrades to an implementation with security checks for UUPS proxies and an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCallUUPS(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_newImpl);
        } else {
            try IERC1822Proxiable(_newImpl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert UNSUPPORTED_UUID();
            } catch {
                revert ONLY_UUPS();
            }

            _upgradeToAndCall(_newImpl, _data, _forceCall);
        }
    }

    /// @dev Upgrades to an implementation with an additional function call
    /// @param _newImpl The new implementation address
    /// @param _data The encoded function call
    function _upgradeToAndCall(
        address _newImpl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_newImpl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_newImpl, _data);
        }
    }

    /// @dev Performs an implementation upgrade
    /// @param _newImpl The new implementation address
    function _upgradeTo(address _newImpl) internal {
        _setImplementation(_newImpl);

        emit Upgraded(_newImpl);
    }

    /// @dev Stores the address of an implementation
    /// @param _impl The implementation address
    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_UPGRADE(_impl);

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    /// @dev The address of the current implementation
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IOwnable
/// @author Rohan Kulkarni
/// @notice The external Ownable events, errors, and functions
interface IOwnable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IInitializable } from "../interfaces/IInitializable.sol";
import { Address } from "../utils/Address.sol";

/// @title Initializable
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (proxy/utils/Initializable.sol)
/// - Uses custom errors declared in IInitializable
abstract contract Initializable is IInitializable {
    ///                                                          ///
    ///                           STORAGE                        ///
    ///                                                          ///

    /// @dev Indicates the contract has been initialized
    uint8 internal _initialized;

    /// @dev Indicates the contract is being initialized
    bool internal _initializing;

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    /// @dev Ensures an initialization function is only called within an `initializer` or `reinitializer` function
    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    /// @dev Enables initializing upgradeable contracts
    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

        _initialized = 1;

        if (isTopLevelCall) {
            _initializing = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;

            emit Initialized(1);
        }
    }

    /// @dev Enables initializer versioning
    /// @param _version The version to set
    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    /// @dev Prevents future initialization
    function _disableInitializers() internal virtual {
        if (_initializing) revert INITIALIZING();

        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;

            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IERC1967Upgrade
/// @author Rohan Kulkarni
/// @notice The external ERC1967Upgrade events and errors
interface IERC1967Upgrade {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the implementation is upgraded
    /// @param impl The address of the implementation
    event Upgraded(address impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an implementation is an invalid upgrade
    /// @param impl The address of the invalid implementation
    error INVALID_UPGRADE(address impl);

    /// @dev Reverts if an implementation upgrade is not stored at the storage slot of the original
    error UNSUPPORTED_UUID();

    /// @dev Reverts if an implementation does not support ERC1822 proxiableUUID()
    error ONLY_UUPS();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
pragma solidity ^0.8.10;

import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import { IERC5192 } from "./IERC5192.sol";

/// @author [email protected]
/// @notice Base non-transferrable optimized nft contract
/// @notice Modified for base class usage and supports EIP-5192
abstract contract CuratorSkeletonNFT is
    IERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable,
    IERC5192
{
    /// @notice modifier signifying contract function is not supported
    modifier notSupported() {
        revert("Fn not supported: nontransferrable NFT");
        _;
    }

    /**
        Common NFT functions
     */

    /// @notice NFT Metadata Name
    function name() virtual external view returns (string memory);

    /// @notice NFT Metadata Symbol
    function symbol() virtual external view returns (string memory);

    /*
     *  EIP-5192 Functions
     */
    function locked(uint256) external pure returns (bool) {
      return true;
    }


    /*
     *  NFT Functions
     */

    /// @notice blanaceOf getter for NFT compat
    function balanceOf(address user) public virtual view returns (uint256);

    /// @notice ownerOf getter, checks if token exists
    function ownerOf(uint256 id) public virtual view returns (address);

    /// @notice approvals not supported
    function getApproved(uint256) public pure returns (address) {
        return address(0x0);
    }

    /// @notice tokenURI method
    function tokenURI(uint256 tokenId) external virtual view returns (string memory);

    /// @notice contractURI method
    function contractURI() external virtual view returns (string memory);

    /// @notice approvals not supported
    function isApprovedForAll(address, address) public pure returns (bool) {
        return false;
    }

    /// @notice approvals not supported
    function approve(address, uint256) public notSupported {}

    /// @notice approvals not supported
    function setApprovalForAll(address, bool) public notSupported {}

    /// @notice internal safemint function
    function _mint(address to, uint256 id) internal {
        require(
            to != address(0x0),
            "Mint: cannot mint to 0x0"
        );
        emit Locked(id);
        _transferFrom(address(0x0), to, id);
    }

    /// @notice intenral safeBurn function
    function _burn(uint256 id) internal {
      _transferFrom(ownerOf(id), address(0x0), id);
    }

    /// @notice transfer function to be overridden
    function transferFrom(
        address from,
        address to,
        uint256 checkTokenId
    ) external virtual {}

    /// @notice not supported
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public notSupported {
        // no impl
    }

    /// @notice not supported
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public notSupported {
        // no impl
    }

    /// @notice internal transfer function for virtual nfts
    /// @param from address to move from
    /// @param to address to move to
    /// @param id id of nft to move
    /// @dev no storage used in this function
    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        emit Transfer(from, to, id);
    }

    /// @notice erc721 enumerable partial impl
    function totalSupply() public virtual view returns (uint256);

    /// @notice Supports ERC721, ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC165Upgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IERC5192).interfaceId;
    }

    /// @notice internal exists fn for a given token id
    function _exists(uint256 id) internal virtual view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { ICurator } from "./interfaces/ICurator.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IMetadataRenderer } from "./interfaces/IMetadataRenderer.sol";


/**
 @notice Curator storage variables contract.
 @author [email protected]
 */
abstract contract CuratorStorageV1 is ICurator {
    /// @notice Standard ERC721 name for the contract
    string internal contractName;

    /// @notice Standard ERC721 symbol for the curator contract
    string internal contractSymbol;

    /// Curation pass as an ERC721 that allows other users to curate.
    /// @notice Address to ERC721 with `balanceOf` function.
    IERC721Upgradeable public curationPass;

    /// Stores virtual mapping array length parameters
    /// @notice Array total size (total size)
    uint40 public numAdded;

    /// @notice Array active size = numAdded - numRemoved
    /// @dev Blank entries are retained within array
    uint40 public numRemoved;

    /// @notice If curation is paused by the owner
    bool public isPaused;

    /// @notice timestamp that the curation is frozen at (if never, frozen = 0)
    uint256 public frozenAt;

    /// @notice Limit of # of items that can be curated
    uint256 public curationLimit;

    /// @notice Address of the NFT Metadata renderer contract
    IMetadataRenderer public renderer;

    /// @notice Listing id => Listing struct mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank entries (not garbage compacted!)
    mapping(uint256 => Listing) public idToListing;

    /// @notice Storage gap
    uint256[49] __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title EIP712
/// @author Rohan Kulkarni
/// @notice Modified from OpenZeppelin Contracts v4.7.3 (utils/Address.sol)
/// - Uses custom errors `INVALID_TARGET()` & `DELEGATE_CALL_FAILED()`
/// - Adds util converting address to bytes32
library Address {
    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if the target of a delegatecall is not a contract
    error INVALID_TARGET();

    /// @dev Reverts if a delegatecall has failed
    error DELEGATE_CALL_FAILED();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Utility to convert an address to bytes32
    function toBytes32(address _account) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_account)) << 96);
    }

    /// @dev If an address is a contract
    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    /// @dev Performs a delegatecall on an address
    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    /// @dev Verifies a delegatecall was successful
    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IInitializable
/// @author Rohan Kulkarni
/// @notice The external Initializable events and errors
interface IInitializable {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when the contract has been initialized or reinitialized
    event Initialized(uint256 version);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if incorrectly initialized with address(0)
    error ADDRESS_ZERO();

    /// @dev Reverts if disabling initializers during initialization
    error INITIALIZING();

    /// @dev Reverts if calling an initialization function outside of initialization
    error NOT_INITIALIZING();

    /// @dev Reverts if reinitializing incorrectly
    error ALREADY_INITIALIZED();
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC5192 {
  /// @notice Emitted when the locking status is changed to locked.
  /// @dev If a token is minted and the status is locked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Locked(uint256 tokenId);

  /// @notice Emitted when the locking status is changed to unlocked.
  /// @dev If a token is minted and the status is unlocked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Unlocked(uint256 tokenId);

  /// @notice Returns the locking status of an Soulbound Token
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param tokenId The identifier for an SBT.
  function locked(uint256 tokenId) external view returns (bool);
}