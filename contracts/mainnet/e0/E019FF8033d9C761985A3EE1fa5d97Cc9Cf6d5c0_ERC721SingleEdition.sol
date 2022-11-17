// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "../metadata/interfaces/IMetadataRenderer.sol";
import "../metadata/interfaces/IEditionsMetadataRenderer.sol";
import "./interfaces/IEditionCollection.sol";
import "./ERC721MinimizedBase.sol";
import "../tokenManager/interfaces/IPostTransfer.sol";
import "../utils/ERC721/ERC721Upgradeable.sol";
import "./interfaces/IERC721EditionMint.sol";

/**
 * @title ERC721 Single Edition
 * @author [email protected], [email protected]
 * @dev Single Edition Per Collection
 */
contract ERC721SingleEdition is IERC721EditionMint, IEditionCollection, ERC721MinimizedBase, ERC721Upgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Contract metadata
     */
    string public contractURI;

    /**
     * @dev Keeps track of current token ID in supply
     */
    uint256 private _currentId;

    /**
     * @dev Generates metadata for contract and token
     */
    address private _metadataRendererAddress;

    /**
     * @notice Total size of edition that can be minted
     */
    uint256 public size;

    /**
     * @dev Emitted when edition is created
     * @param size Edition size
     * @param editionTokenManager Token manager for edition
     */
    event EditionCreated(uint256 indexed size, address indexed editionTokenManager);

    /**
     * @param creator Creator/owner of contract
     * @param defaultRoyalty Default royalty object for contract (optional)
     * @param _defaultTokenManager Default token manager for contract (optional)
     * @param _contractURI Contract metadata
     * @param _name Name of token edition
     * @param _symbol Symbol of the token edition
     * @param _editionInfo Edition info
     * @param _size Edition size
     * @param metadataRendererAddress Contract returning metadata for each edition
     * @param trustedForwarder Trusted minimal forwarder
     * @param initialMinter Initial minter to register
     */
    function initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager,
        string memory _contractURI,
        string memory _name,
        string memory _symbol,
        bytes memory _editionInfo,
        uint256 _size,
        address metadataRendererAddress,
        address trustedForwarder,
        address initialMinter
    ) external initializer nonReentrant {
        __ERC721MinimizedBase_initialize(creator, defaultRoyalty, _defaultTokenManager);
        __ERC721_init(_name, _symbol);
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        size = _size;
        _metadataRendererAddress = metadataRendererAddress;
        IMetadataRenderer(metadataRendererAddress).initializeMetadata(_editionInfo);
        _minters.add(initialMinter);
        _currentId = 1;
        contractURI = _contractURI;

        emit EditionCreated(_size, _defaultTokenManager);
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipient}
     */
    function mintOneToRecipient(uint256 editionId, address recipient)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(recipient, 1);
    }

    /**
     * @dev See {IERC721EditionMint-mintAmountToRecipient}
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");

        return _mintEditionsToOne(recipient, amount);
    }

    /**
     * @dev See {IERC721EditionMint-mintOneToRecipients}
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients)
        external
        onlyMinter
        nonReentrant
        returns (uint256)
    {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(recipients, 1);
    }

    /**
     * @dev See {IERC721EditionMint-mintAmountToRecipients}
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external onlyMinter nonReentrant returns (uint256) {
        require(_mintFrozen == 0, "Mint frozen");
        require(_editionExists(editionId), "Edition doesn't exist");
        return _mintEditions(recipients, amount);
    }

    /**
     * @dev See {IEditionCollection-getEditionId}
     */
    function getEditionId(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Token Id doesn't exist");
        return 0;
    }

    /**
     * @dev See {IEditionCollection-getEditionDetails}
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return _getEditionDetails();
    }

    /**
     * @dev See {IEditionCollection-getEditionsDetailsAndUri}
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory)
    {
        require(editionIds.length == 1, "One possible edition id");
        EditionDetails[] memory editionsDetails = new EditionDetails[](1);
        string[] memory uris = new string[](1);

        // expected to be 0, validated in editionURI call
        uint256 editionId = editionIds[0];

        uris[0] = editionURI(editionId);
        editionsDetails[0] = _getEditionDetails();

        return (editionsDetails, uris);
    }

    /**
     * @dev See {IERC721-transferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override nonReentrant {
        ERC721Upgradeable.transferFrom(from, to, tokenId);

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postTransferFrom(_msgSender(), from, to, tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}. Overrides default behaviour to check associated tokenManager.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override nonReentrant {
        ERC721Upgradeable.safeTransferFrom(from, to, tokenId, data);

        address _manager = defaultManager;
        if (_manager != address(0) && IERC165Upgradeable(_manager).supportsInterface(type(IPostTransfer).interfaceId)) {
            IPostTransfer(_manager).postSafeTransferFrom(_msgSender(), from, to, tokenId, data);
        }
    }

    /**
     * @dev Conforms to ERC-2981.
     * @param // Token id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        return ERC721MinimizedBase.royaltyInfo(0, _salePrice);
    }

    /**
     * @dev Get URI for given edition id
     * @param editionId edition id to get uri for
     * @return base64-encoded json metadata object
     */
    function editionURI(uint256 editionId) public view returns (string memory) {
        require(_editionExists(editionId), "Edition doesn't exist");
        return IEditionsMetadataRenderer(_metadataRendererAddress).editionURI(editionId);
    }

    /**
     * @dev Get URI for given token id
     * @param tokenId token id to get uri for
     * @return base64-encoded json metadata object
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "No token");
        return IMetadataRenderer(_metadataRendererAddress).tokenURI(tokenId);
    }

    /**
     * @dev Used to get token manager of token id
     * @param tokenId ID of the token
     */
    function tokenManagerByTokenId(uint256 tokenId) public view returns (address) {
        return tokenManager(tokenId);
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipients Recipients of newly minted tokens
     * @param _amount Amount minted to each recipient
     */
    function _mintEditions(address[] memory recipients, uint256 _amount) internal returns (uint256) {
        uint256 recipientsLength = recipients.length;

        uint256 tempCurrent = _currentId;
        uint256 endAt = tempCurrent + (recipientsLength * _amount) - 1;

        require(size == 0 || endAt <= size, "Sold out");

        for (uint256 i = 0; i < recipientsLength; i++) {
            for (uint256 j = 0; j < _amount; j++) {
                _mint(recipients[i], tempCurrent);
                tempCurrent += 1;
            }
        }
        _currentId = tempCurrent;
        return _currentId;
    }

    /**
     * @dev Private function to mint without any access checks. Called by the public edition minting functions.
     * @param recipient Recipient of newly minted token
     * @param _amount Amount minted to recipient
     */
    function _mintEditionsToOne(address recipient, uint256 _amount) internal returns (uint256) {
        uint256 tempCurrent = _currentId;
        uint256 endAt = tempCurrent + _amount - 1;

        require(size == 0 || endAt <= size, "Sold out");

        for (uint256 j = 0; j < _amount; j++) {
            _mint(recipient, tempCurrent);
            tempCurrent += 1;
        }
        _currentId = tempCurrent;
        return _currentId;
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ERC721MinimizedBase, ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Returns whether `editionId` exists.
     */
    function _editionExists(uint256 editionId) internal pure returns (bool) {
        return editionId == 0;
    }

    /**
     * @dev Get edition details
     */
    function _getEditionDetails() private view returns (EditionDetails memory) {
        return EditionDetails(this.name(), size, _currentId - 1, 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Context.sol";

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
/* solhint-disable */
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Used to interface with core of EditionsMetadataRenderer
 * @author Zora, [email protected]
 */
interface IMetadataRenderer {
    /**
     * @dev Store metadata for an edition
     * @param data Metadata
     */
    function initializeMetadata(bytes memory data) external;

    /**
     * @dev Get uri for token
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Used to interface with EditionsMetadataRenderer
 * @author [email protected], [email protected]
 */
interface IEditionsMetadataRenderer {
    /**
     * @dev Token edition info
     * @param name Edition name
     * @param description Edition description
     * @param imageUrl Edition image url
     * @param animationUrl Edition animation url
     * @param externalUrl Edition external url
     * @param attributes Edition attributes
     */
    struct TokenEditionInfo {
        string name;
        string description;
        string imageUrl;
        string animationUrl;
        string externalUrl;
        string attributes;
    }

    /**
     * @dev Updates name on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param name New name of edition
     */
    function updateName(
        address editionsAddress,
        uint256 editionId,
        string calldata name
    ) external;

    /**
     * @dev Updates description on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param description New description of edition
     */
    function updateDescription(
        address editionsAddress,
        uint256 editionId,
        string calldata description
    ) external;

    /**
     * @dev Updates imageUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param imageUrl New imageUrl of edition
     */
    function updateImageUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata imageUrl
    ) external;

    /**
     * @dev Updates animationUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param animationUrl New animationUrl of edition
     */
    function updateAnimationUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata animationUrl
    ) external;

    /**
     * @dev Updates externalUrl on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param externalUrl New externalUrl of edition
     */
    function updateExternalUrl(
        address editionsAddress,
        uint256 editionId,
        string calldata externalUrl
    ) external;

    /**
     * @dev Updates attributes on edition. Managed by token manager if existent
     * @param editionsAddress Address of collection that edition is on
     * @param editionId ID of edition to update
     * @param attributes New attributes of edition
     */
    function updateAttributes(
        address editionsAddress,
        uint256 editionId,
        string calldata attributes
    ) external;

    /**
     * @dev Get an edition's uri. HAS to be called by collection
     * @param editionId Edition's id to get uri for
     */
    function editionURI(uint256 editionId) external view returns (string memory);

    /**
     * @dev Get an edition's info.
     * @param editionsAddress Address of collection that edition is on
     * @param editionsId Edition's id to get info for
     */
    function editionInfo(address editionsAddress, uint256 editionsId) external view returns (TokenEditionInfo memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Interfaces with the details of editions on collections
 * @author [email protected], [email protected]
 */
interface IEditionCollection {
    /**
     * @dev Edition details
     * @param name Edition name
     * @param size Edition size
     * @param supply Total number of tokens minted on edition
     * @param initialTokenId Token id of first token minted in edition
     */
    struct EditionDetails {
        string name;
        uint256 size;
        uint256 supply;
        uint256 initialTokenId;
    }

    /**
     * @dev Get the edition a token belongs to
     * @param tokenId The token id of the token
     */
    function getEditionId(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get an edition's details
     * @param editionId Edition id
     */
    function getEditionDetails(uint256 editionId) external view returns (EditionDetails memory);

    /**
     * @dev Get the details and uris of a number of editions
     * @param editionIds List of editions to get info for
     */
    function getEditionsDetailsAndUri(uint256[] calldata editionIds)
        external
        view
        returns (EditionDetails[] memory, string[] memory uris);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../royaltyManager/interfaces/IRoyaltyManager.sol";
import "../tokenManager/interfaces/ITokenManager.sol";
import "../utils/Ownable.sol";
import "../utils/ERC2981/IERC2981Upgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../utils/ERC165/ERC165CheckerUpgradeable.sol";

/**
 * @title Minimized Base ERC721
 * @author [email protected]
 * @dev Core piece of Highlight NFT contracts (V2), branch for ERC721SingleEdition
 */
abstract contract ERC721MinimizedBase is
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ERC2771ContextUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165CheckerUpgradeable for address;

    /**
     * @dev Set of minters allowed to mint on contract
     */
    EnumerableSet.AddressSet internal _minters;

    /**
     * @dev Global token/edition manager default
     */
    address public defaultManager;

    /**
     * @dev Default royalty for entire contract
     */
    IRoyaltyManager.Royalty internal _defaultRoyalty;

    /**
     * @dev Royalty manager - optional contract that defines the conditions around setting royalties
     */
    address public royaltyManager;

    /**
     * @dev Freezes minting on smart contract forever
     */
    uint8 internal _mintFrozen;

    /**
     * @dev Emitted when minter is registered or unregistered
     * @param minter Minter that was changed
     * @param registered True if the minter was registered, false if unregistered
     */
    event MinterRegistrationChanged(address indexed minter, bool indexed registered);

    /**
     * @dev Emitted when default token manager changed
     * @param newDefaultTokenManager New default token manager. Zero address if old one was removed
     */
    event DefaultTokenManagerChanged(address indexed newDefaultTokenManager);

    /**
     * @dev Emitted when default royalty is set
     * @param recipientAddress Royalty recipient
     * @param royaltyPercentageBPS Percentage of sale (in basis points) owed to royalty recipient
     */
    event DefaultRoyaltySet(address indexed recipientAddress, uint16 indexed royaltyPercentageBPS);

    /**
     * @dev Emitted when royalty manager is updated
     * @param newRoyaltyManager New royalty manager. Zero address if old one was removed
     */
    event RoyaltyManagerChanged(address indexed newRoyaltyManager);

    /**
     * @dev Emitted when mints are frozen permanently
     */
    event MintsFrozen();

    /**
     * @dev Restricts calls to minters
     */
    modifier onlyMinter() {
        require(_minters.contains(_msgSender()), "Not minter");
        _;
    }

    /**
     * @dev Restricts calls if input royalty bps is over 10000
     */
    modifier royaltyValid(uint16 _royaltyBPS) {
        require(_royaltyBPS <= 10000, "Over BPS limit");
        _;
    }

    /**
     * @dev Registers a minter
     * @param minter New minter
     */
    function registerMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.add(minter), "Already a minter");

        emit MinterRegistrationChanged(minter, true);
    }

    /**
     * @dev Unregisters a minter
     * @param minter Minter to unregister
     */
    function unregisterMinter(address minter) external onlyOwner nonReentrant {
        require(_minters.remove(minter), "Not yet minter");

        emit MinterRegistrationChanged(minter, false);
    }

    /**
     * @dev Set default token manager if current token manager allows it
     * @param _defaultTokenManager New default token manager
     */
    function setDefaultTokenManager(address _defaultTokenManager) external nonReentrant {
        require(_isValidTokenManager(_defaultTokenManager), "Invalid TM");
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        if (currentTokenManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(ITokenManager(currentTokenManager).canSwap(msgSender, 0, _defaultTokenManager), "Can't swap");
        }

        defaultManager = _defaultTokenManager;

        emit DefaultTokenManagerChanged(_defaultTokenManager);
    }

    /**
     * @dev Removes default token manager if current token manager allows it
     */
    function removeDefaultTokenManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentTokenManager = defaultManager;
        require(currentTokenManager != address(0), "Default TM not existent");
        require(ITokenManager(currentTokenManager).canRemoveItself(msgSender, 0), "Can't remove");

        defaultManager = address(0);

        emit DefaultTokenManagerChanged(address(0));
    }

    /**
     * @dev Sets default royalty if royalty manager allows it
     * @param _royalty New default royalty
     */
    function setDefaultRoyalty(IRoyaltyManager.Royalty calldata _royalty)
        external
        nonReentrant
        royaltyValid(_royalty.royaltyPercentageBPS)
    {
        address msgSender = _msgSender();

        address _royaltyManager = royaltyManager;
        if (_royaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(_royaltyManager).canSetDefaultRoyalty(_royalty, msgSender), "Can't set");
        }

        _defaultRoyalty = _royalty;

        emit DefaultRoyaltySet(_royalty.recipientAddress, _royalty.royaltyPercentageBPS);
    }

    /**
     * @dev Sets royalty manager if current one allows it
     * @param _royaltyManager New royalty manager
     */
    function setRoyaltyManager(address _royaltyManager) external nonReentrant {
        require(_isValidRoyaltyManager(_royaltyManager), "Invalid RM");
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        if (currentRoyaltyManager == address(0)) {
            require(msgSender == owner(), "Not owner");
        } else {
            require(IRoyaltyManager(currentRoyaltyManager).canSwap(_royaltyManager, msgSender), "Can't swap");
        }

        royaltyManager = _royaltyManager;

        emit RoyaltyManagerChanged(_royaltyManager);
    }

    /**
     * @dev Removes royalty manager if current one allows it
     */
    function removeRoyaltyManager() external nonReentrant {
        address msgSender = _msgSender();

        address currentRoyaltyManager = royaltyManager;
        require(currentRoyaltyManager != address(0), "RM non-existent");
        require(IRoyaltyManager(currentRoyaltyManager).canRemoveItself(msgSender), "Can't remove");

        royaltyManager = address(0);

        emit RoyaltyManagerChanged(address(0));
    }

    /**
     * @dev Freeze mints on contract forever
     */
    function freezeMints() external onlyOwner nonReentrant {
        _mintFrozen = 1;

        emit MintsFrozen();
    }

    /**
     * @dev Conforms to ERC-2981. Editions should overwrite to return royalty for entire edition
     * @param // Edition id
     * @param _salePrice Sale price of token
     */
    function royaltyInfo(
        uint256, /* _tokenGroupingId */
        uint256 _salePrice
    ) public view virtual override returns (address receiver, uint256 royaltyAmount) {
        IRoyaltyManager.Royalty memory royalty = _defaultRoyalty;

        receiver = royalty.recipientAddress;
        royaltyAmount = (_salePrice * uint256(royalty.royaltyPercentageBPS)) / 10000;
    }

    /**
     * @dev Returns the token manager for the id passed in.
     * @param // Token ID or Edition ID for Editions implementing contracts
     */
    function tokenManager(
        uint256 /* id */
    ) public view returns (address manager) {
        return defaultManager;
    }

    /**
     * @dev Initializes the contract, setting the creator as the initial owner.
     * @param creator Contract creator
     * @param defaultRoyalty Default royalty for the contract
     * @param _defaultTokenManager Default token manager for the contract
     */
    function __ERC721MinimizedBase_initialize(
        address creator,
        IRoyaltyManager.Royalty memory defaultRoyalty,
        address _defaultTokenManager
    ) internal onlyInitializing royaltyValid(defaultRoyalty.royaltyPercentageBPS) {
        __Ownable_init();
        __ReentrancyGuard_init();
        _transferOwnership(creator);

        _defaultRoyalty = defaultRoyalty;

        defaultManager = _defaultTokenManager;
    }

    /**
     * @dev Returns true if address is a valid tokenManager
     * @param _tokenManager Token manager being checked
     */
    function _isValidTokenManager(address _tokenManager) internal view returns (bool) {
        return _tokenManager.supportsInterface(type(ITokenManager).interfaceId);
    }

    /**
     * @dev Returns true if address is a valid royaltyManager
     * @param _royaltyManager Royalty manager being checked
     */
    function _isValidRoyaltyManager(address _royaltyManager) internal view returns (bool) {
        return _royaltyManager.supportsInterface(type(IRoyaltyManager).interfaceId);
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @author [email protected]
 * @dev If token managers implement this, transfer actions will call
 *      postSafeTransferFrom or postTransferFrom on the token manager.
 */
interface IPostTransfer {
    /**
     * @dev Hook called by community after safe transfers, if token manager of transferred token implements this
     *      interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     * @param data Arbitrary data
     */
    function postSafeTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    /**
     * @dev Hook called by community after transfers, if token manager of transferred token implements this interface.
     * @param operator Operator transferring tokens
     * @param from Token(s) sender
     * @param to Token(s) recipient
     * @param id Transferred token's id
     */
    function postTransferFrom(
        address operator,
        address from,
        address to,
        uint256 id
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.10;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../ERC165/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
/* solhint-disable */
contract ERC721Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (
                bytes4 retval
            ) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Mint interface on editions contracts
 * @author [email protected]
 */
interface IERC721EditionMint {
    /**
     * @dev Mints one NFT to one recipient
     * @param editionId Edition to mint the NFT on
     * @param recipient Recipient of minted NFT
     */
    function mintOneToRecipient(uint256 editionId, address recipient) external returns (uint256);

    /**
     * @dev Mints an amount of NFTs to one recipient
     * @param editionId Edition to mint the NFTs on
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external returns (uint256);

    /**
     * @dev Mints one NFT each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients) external returns (uint256);

    /**
     * @dev Mints an amount of NFTs each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted per recipient
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external returns (uint256);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title IRoyaltyManager
 * @author [email protected]
 * @dev Enables interfacing with custom royalty managers that define conditions on setting royalties for NFT contracts
 */
interface IRoyaltyManager {
    /**
     * @dev Struct containing values required to adhere to ERC-2981
     * @param recipientAddress Royalty recipient - can be EOA, royalty splitter contract, etc.
     * @param royaltyPercentageBPS Royalty cut, in basis points
     */
    struct Royalty {
        address recipientAddress;
        uint16 royaltyPercentageBPS;
    }

    /**
     * @dev Defines conditions around being able to swap royalty manager for another one
     * @param newRoyaltyManager New royalty manager being swapped in
     * @param sender msg sender
     */
    function canSwap(address newRoyaltyManager, address sender) external view returns (bool);

    /**
     * @dev Defines conditions around being able to remove current royalty manager
     * @param sender msg sender
     */
    function canRemoveItself(address sender) external view returns (bool);

    /**
     * @dev Defines conditions around being able to set granular royalty (per token or per edition)
     * @param id Edition / token ID whose royalty is being set
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetGranularRoyalty(
        uint256 id,
        Royalty calldata royalty,
        address sender
    ) external view returns (bool);

    /**
     * @dev Defines conditions around being able to set default royalty
     * @param royalty Royalty being set
     * @param sender msg sender
     */
    function canSetDefaultRoyalty(Royalty calldata royalty, address sender) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @title ITokenManager
 * @author [email protected]
 * @dev Enables interfacing with custom token managers
 */
interface ITokenManager {
    /**
     * @dev Returns whether metadata updater is allowed to update
     * @param sender Updater
     * @param id Token/edition who's uri is being updated
     *           If id is 0, implementation should decide behaviour for base uri update
     * @param newData Token's new uri if called by general contract, and any metadata field if called by editions
     * @return If invocation can update metadata
     */
    function canUpdateMetadata(
        address sender,
        uint256 id,
        bytes calldata newData
    ) external view returns (bool);

    /**
     * @dev Returns whether token manager can be swapped for another one by invocator
     * @dev Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @param newTokenManager New token manager being swapped to
     * @return If invocation can swap token managers
     */
    function canSwap(
        address sender,
        uint256 id,
        address newTokenManager
    ) external view returns (bool);

    /**
     * @dev Returns whether token manager can be removed
     * @dev Default token manager implementations should ignore id
     * @param sender Swapper
     * @param id Token grouping id (token id or edition id)
     * @return If invocation can remove token manager
     */
    function canRemoveItself(address sender, uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981Upgradeable.sol)

pragma solidity 0.8.10;

import "../ERC165/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 *      Openzeppelin contract slightly modified by [email protected] highlight.xyz to be upgradeable.
 */
abstract contract ERC2771ContextUpgradeable is Initializable {
    address private _trustedForwarder;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function __ERC2771ContextUpgradeable__init__(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /* solhint-disable no-inline-assembly */
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            /* solhint-enable no-inline-assembly */
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity 0.8.10;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
/* solhint-disable */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
/* solhint-disable */
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
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

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.10;

import "../ERC165/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
/* solhint-disable */
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.10;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
/* solhint-disable */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.10;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
/* solhint-disable */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity 0.8.10;

import "./IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
/* solhint-disable */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}