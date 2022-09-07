// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.16;

import "../implementations/RMRKNestingMultiResourceImpl.sol";

contract RMRKNestingFactory {
    address[] public nestingCollections;

    event NewRMRKNestingContract(
        address indexed nestingContract,
        address indexed deployer
    );

    function getCollections() external view returns (address[] memory) {
        return nestingCollections;
    }

    function deployRMRKNesting(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 pricePerMint, //in WEI
        string memory collectionMetadata
    ) public {
        RMRKNestingMultiResourceImpl nestingContract = new RMRKNestingMultiResourceImpl(
                name,
                symbol,
                maxSupply,
                pricePerMint,
                collectionMetadata
            );
        nestingCollections.push(address(nestingContract));
        nestingContract.transferOwnership(msg.sender);
        emit NewRMRKNestingContract(address(nestingContract), msg.sender);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "../RMRK/utils/RMRKMintingUtils.sol";
import "../RMRK/utils/RMRKCollectionMetadata.sol";
import "../RMRK/nesting/RMRKNestingMultiResource.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error RMRKMintUnderpriced();
error RMRKMintZero();

//Minimal public implementation of IRMRKNesting for testing.
contract RMRKNestingMultiResourceImpl is
    RMRKMintingUtils,
    RMRKCollectionMetadata,
    RMRKNestingMultiResource
{
    using Strings for uint256;

    // Manage resources via increment
    uint256 private _totalResources;

    //Mapping of uint64 resource ID to tokenEnumeratedResource for tokenURI
    mapping(uint64 => bool) internal _tokenEnumeratedResource;

    //fallback URI
    string internal _fallbackURI;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 pricePerMint_,
        string memory collectionMetadata_
    )
        RMRKNestingMultiResource(name_, symbol_)
        RMRKMintingUtils(maxSupply_, pricePerMint_)
        RMRKCollectionMetadata(collectionMetadata_)
    {}

    /*
    Template minting logic
    */
    function mint(address to, uint256 numToMint) external payable saleIsOpen {
        (uint256 nextToken, uint256 totalSupplyOffset) = _preMint(numToMint);

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _safeMint(to, i);
            unchecked {
                ++i;
            }
        }
    }

    /*
    Template minting logic
    */
    function mintNesting(
        address to,
        uint256 numToMint,
        uint256 destinationId
    ) external payable saleIsOpen {
        (uint256 nextToken, uint256 totalSupplyOffset) = _preMint(numToMint);

        for (uint256 i = nextToken; i < totalSupplyOffset; ) {
            _nestMint(to, i, destinationId);
            unchecked {
                ++i;
            }
        }
    }

    function _preMint(uint256 numToMint) private returns (uint256, uint256) {
        if (numToMint == uint256(0)) revert RMRKMintZero();
        if (numToMint + _totalSupply > _maxSupply) revert RMRKMintOverMax();

        uint256 mintPriceRequired = numToMint * _pricePerMint;
        if (mintPriceRequired != msg.value) revert RMRKMintUnderpriced();

        uint256 nextToken = _totalSupply + 1;
        unchecked {
            _totalSupply += numToMint;
        }
        uint256 totalSupplyOffset = _totalSupply + 1;

        return (nextToken, totalSupplyOffset);
    }

    //update for reentrancy
    function burn(uint256 tokenId) public onlyApprovedOrDirectOwner(tokenId) {
        _burn(tokenId);
    }

    function getFallbackURI() external view virtual returns (string memory) {
        return _fallbackURI;
    }

    function setFallbackURI(string memory fallbackURI) external onlyOwner {
        _fallbackURI = fallbackURI;
    }

    function isTokenEnumeratedResource(uint64 resourceId)
        public
        view
        virtual
        returns (bool)
    {
        return _tokenEnumeratedResource[resourceId];
    }

    function setTokenEnumeratedResource(uint64 resourceId, bool state)
        external
        onlyOwner
    {
        // TODO: shall we check that resource exists?
        _tokenEnumeratedResource[resourceId] = state;
    }

    function addResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) external {
        if (ownerOf(tokenId) == address(0)) revert ERC721InvalidTokenId();
        _addResourceToToken(tokenId, resourceId, overwrites);
    }

    function addResourceEntry(string memory metadataURI) external onlyOwner {
        unchecked {
            _totalResources += 1;
        }
        _addResourceEntry(uint64(_totalResources), metadataURI);
    }

    function totalResources() external view returns (uint256) {
        return _totalResources;
    }

    function transfer(address to, uint256 tokenId) public virtual {
        transferFrom(_msgSender(), to, tokenId);
    }

    function nestTransfer(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual {
        nestTransferFrom(_msgSender(), to, tokenId, destinationId);
    }

    function _tokenURIAtIndex(uint256 tokenId, uint256 index)
        internal
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        if (_activeResources[tokenId].length > index) {
            uint64 activeResId = _activeResources[tokenId][index];
            Resource memory _activeRes = getResource(activeResId);
            string memory uri = string(
                abi.encodePacked(
                    _baseURI(),
                    _activeRes.metadataURI,
                    _tokenEnumeratedResource[activeResId]
                        ? tokenId.toString()
                        : ""
                )
            );

            return uri;
        } else {
            return _fallbackURI;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
import "../access/OwnableLock.sol";

pragma solidity ^0.8.15;

error RMRKMintOverMax();

/**
 * @dev Top-level utilities for managing minting. Implements OwnableLock by default.
 * Max supply-related and pricing variables are immutable after deployment.
 */

contract RMRKMintingUtils is OwnableLock {
    uint256 internal _totalSupply;
    uint256 internal immutable _maxSupply;
    uint256 internal immutable _pricePerMint;

    constructor(uint256 maxSupply_, uint256 pricePerMint_) {
        _maxSupply = maxSupply_;
        _pricePerMint = pricePerMint_;
    }

    modifier saleIsOpen() {
        if (_totalSupply >= _maxSupply) revert RMRKMintOverMax();
        _;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function pricePerMint() public view returns (uint256) {
        return _pricePerMint;
    }

    function withdrawRaised(address to, uint256 amount) external onlyOwner {
        _withdraw(to, amount);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.15;

import "../multiresource/IRMRKMultiResource.sol";
import "./IRMRKNesting.sol";
import "../library/RMRKLib.sol";
import "./RMRKNesting.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";

// MultiResource
error RMRKBadPriorityListLength();
error RMRKIndexOutOfRange();
error RMRKMaxPendingResourcesReached();
error RMRKNoResourceMatchingId();
error RMRKResourceAlreadyExists();
error RMRKWriteToZero();
error RMRKNotApprovedForResourcesOrOwner();
error RMRKApprovalForResourcesToCurrentOwner();
error RMRKApproveForResourcesCallerIsNotOwnerNorApprovedForAll();
error RMRKApproveForResourcesToCaller();

/**
 * @dev Mid-level contract implementing multiresource on top of nesting.
 *
 */

contract RMRKNestingMultiResource is RMRKNesting, IRMRKMultiResource {
    using RMRKLib for uint256;
    using Address for address;
    using Strings for uint256;
    using RMRKLib for uint64[];
    using RMRKLib for uint128[];

    // ------------------- RESOURCES --------------
    //mapping of uint64 Ids to resource object
    mapping(uint64 => string) internal _resources;

    //mapping of tokenId to new resource, to resource to be replaced
    mapping(uint256 => mapping(uint64 => uint64)) internal _resourceOverwrites;

    //mapping of tokenId to all resources
    mapping(uint256 => uint64[]) internal _activeResources;

    //mapping of tokenId to an array of resource priorities
    mapping(uint256 => uint16[]) internal _activeResourcePriorities;

    //Double mapping of tokenId to active resources
    mapping(uint256 => mapping(uint64 => bool)) internal _tokenResources;

    //mapping of tokenId to all resources by priority
    mapping(uint256 => uint64[]) internal _pendingResources;

    //List of all resources
    uint64[] internal _allResources;

    // Mapping from token ID to approved address for resources
    mapping(uint256 => address) internal _tokenApprovalsForResources;

    // Mapping from owner to operator approvals for resources
    mapping(address => mapping(address => bool))
        internal _operatorApprovalsForResources;

    function _onlyApprovedForResourcesOrOwner(uint256 tokenId) private view {
        if (!_isApprovedForResourcesOrOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedForResourcesOrOwner();
    }

    modifier onlyApprovedForResourcesOrOwner(uint256 tokenId) {
        _onlyApprovedForResourcesOrOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_)
        RMRKNesting(name_, symbol_)
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, RMRKNesting)
        returns (bool)
    {
        return
            RMRKNesting.supportsInterface(interfaceId) ||
            interfaceId == type(IRMRKMultiResource).interfaceId;
    }

    // ------------------------------- RESOURCES ------------------------------

    // --------------------------- GETTING RESOURCES --------------------------

    function getResource(uint64 resourceId)
        public
        view
        virtual
        returns (Resource memory)
    {
        string memory resourceData = _resources[resourceId];
        if (bytes(resourceData).length == 0) revert RMRKNoResourceMatchingId();
        Resource memory resource = Resource({
            id: resourceId,
            metadataURI: resourceData
        });
        return resource;
    }

    function getAllResources() public view virtual returns (uint64[] memory) {
        return _allResources;
    }

    function getActiveResources(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _activeResources[tokenId];
    }

    function getPendingResources(uint256 tokenId)
        public
        view
        virtual
        returns (uint64[] memory)
    {
        return _pendingResources[tokenId];
    }

    function getActiveResourcePriorities(uint256 tokenId)
        public
        view
        virtual
        returns (uint16[] memory)
    {
        return _activeResourcePriorities[tokenId];
    }

    function getResourceOverwrites(uint256 tokenId, uint64 resourceId)
        public
        view
        virtual
        returns (uint64)
    {
        return _resourceOverwrites[tokenId][resourceId];
    }

    // --------------------------- HANDLING RESOURCES -------------------------

    function acceptResource(uint256 tokenId, uint256 index)
        external
        virtual
        onlyApprovedForResourcesOrOwner(tokenId)
    {
        _acceptResource(tokenId, index);
    }

    function rejectResource(uint256 tokenId, uint256 index)
        external
        virtual
        onlyApprovedForResourcesOrOwner(tokenId)
    {
        _rejectResource(tokenId, index);
    }

    function rejectAllResources(uint256 tokenId)
        external
        virtual
        onlyApprovedForResourcesOrOwner(tokenId)
    {
        _rejectAllResources(tokenId);
    }

    function setPriority(uint256 tokenId, uint16[] calldata priorities)
        external
        virtual
        onlyApprovedForResourcesOrOwner(tokenId)
    {
        _setPriority(tokenId, priorities);
    }

    function _acceptResource(uint256 tokenId, uint256 index) internal {
        if (index >= _pendingResources[tokenId].length)
            revert RMRKIndexOutOfRange();
        uint64 resourceId = _pendingResources[tokenId][index];
        _pendingResources[tokenId].removeItemByIndex(index);

        uint64 overwrite = _resourceOverwrites[tokenId][resourceId];
        if (overwrite != uint64(0)) {
            // We could check here that the resource to overwrite actually exists but it is probably harmless.
            _activeResources[tokenId].removeItemByValue(overwrite);
            emit ResourceOverwritten(tokenId, overwrite, resourceId);
            delete (_resourceOverwrites[tokenId][resourceId]);
        }
        _activeResources[tokenId].push(resourceId);
        //Push 0 value of uint16 to array, e.g., uninitialized
        _activeResourcePriorities[tokenId].push(uint16(0));
        emit ResourceAccepted(tokenId, resourceId);
    }

    function _rejectResource(uint256 tokenId, uint256 index) internal {
        if (index >= _pendingResources[tokenId].length)
            revert RMRKIndexOutOfRange();
        uint64 resourceId = _pendingResources[tokenId][index];
        _pendingResources[tokenId].removeItemByIndex(index);
        _tokenResources[tokenId][resourceId] = false;
        delete (_resourceOverwrites[tokenId][resourceId]);

        emit ResourceRejected(tokenId, resourceId);
    }

    function _rejectAllResources(uint256 tokenId) internal {
        uint256 len = _pendingResources[tokenId].length;
        for (uint256 i; i < len; ) {
            uint64 resourceId = _pendingResources[tokenId][i];
            delete _resourceOverwrites[tokenId][resourceId];
            unchecked {
                ++i;
            }
        }

        delete (_pendingResources[tokenId]);
        emit ResourceRejected(tokenId, uint64(0));
    }

    function _setPriority(uint256 tokenId, uint16[] calldata priorities)
        internal
    {
        uint256 length = priorities.length;
        if (length != _activeResources[tokenId].length)
            revert RMRKBadPriorityListLength();
        _activeResourcePriorities[tokenId] = priorities;

        emit ResourcePrioritySet(tokenId);
    }

    // This is expected to be implemented with custom guard:
    function _addResourceEntry(uint64 id, string memory metadataURI) internal {
        if (id == uint64(0)) revert RMRKWriteToZero();
        if (bytes(_resources[id]).length > 0)
            revert RMRKResourceAlreadyExists();
        _resources[id] = metadataURI;
        _allResources.push(id);

        emit ResourceSet(id);
    }

    // This is expected to be implemented with custom guard:
    function _addResourceToToken(
        uint256 tokenId,
        uint64 resourceId,
        uint64 overwrites
    ) internal {
        if (_tokenResources[tokenId][resourceId])
            revert RMRKResourceAlreadyExists();

        if (bytes(_resources[resourceId]).length == 0)
            revert RMRKNoResourceMatchingId();

        if (_pendingResources[tokenId].length >= 128)
            revert RMRKMaxPendingResourcesReached();

        _tokenResources[tokenId][resourceId] = true;

        _pendingResources[tokenId].push(resourceId);

        if (overwrites != uint64(0)) {
            _resourceOverwrites[tokenId][resourceId] = overwrites;
            emit ResourceOverwriteProposed(tokenId, resourceId, overwrites);
        }

        emit ResourceAddedToToken(tokenId, resourceId);
    }

    // ----------------------------- TOKEN URI --------------------------------

    /**
     * @dev See {IERC721Metadata-tokenURI}. Overwritten for MR
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(RMRKNesting, IRMRKMultiResource)
        returns (string memory)
    {
        return _tokenURIAtIndex(tokenId, 0);
    }

    function tokenURIAtIndex(uint256 tokenId, uint256 index)
        public
        view
        virtual
        returns (string memory)
    {
        return _tokenURIAtIndex(tokenId, index);
    }

    function _tokenURIAtIndex(uint256 tokenId, uint256 index)
        internal
        view
        virtual
        returns (string memory)
    {
        _requireMinted(tokenId);
        // TODO: Discuss is this is the best default path.
        // We could return empty string so it returns something if a token has no resources, but it might hide erros
        if (!(index < _activeResources[tokenId].length))
            revert RMRKIndexOutOfRange();

        uint64 activeResId = _activeResources[tokenId][index];
        Resource memory _activeRes = getResource(activeResId);
        string memory uri = string(
            abi.encodePacked(_baseURI(), _activeRes.metadataURI)
        );

        return uri;
    }

    // ----------------------- APPROVALS FOR RESOURCES ------------------------

    function approveForResources(address to, uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert RMRKApprovalForResourcesToCurrentOwner();

        if (
            _msgSender() != owner &&
            !isApprovedForAllForResources(owner, _msgSender())
        ) revert RMRKApproveForResourcesCallerIsNotOwnerNorApprovedForAll();
        _approveForResources(to, tokenId);
    }

    function getApprovedForResources(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        _requireMinted(tokenId);
        return _tokenApprovalsForResources[tokenId];
    }

    function setApprovalForAllForResources(address operator, bool approved)
        external
        virtual
    {
        address owner = _msgSender();
        if (owner == operator) revert RMRKApproveForResourcesToCaller();

        _operatorApprovalsForResources[owner][operator] = approved;
        emit ApprovalForAllForResources(owner, operator, approved);
    }

    function isApprovedForAllForResources(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _operatorApprovalsForResources[owner][operator];
    }

    function _approveForResources(address to, uint256 tokenId)
        internal
        virtual
    {
        _tokenApprovalsForResources[tokenId] = to;
        emit ApprovalForResources(ownerOf(tokenId), to, tokenId);
    }

    function _cleanApprovals(address owner, uint256 tokenId)
        internal
        virtual
        override
    {
        _approveForResources(owner, tokenId);
    }

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    function _isApprovedForResourcesOrOwner(address user, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAllForResources(owner, user) ||
            getApprovedForResources(tokenId) == user);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

contract RMRKCollectionMetadata {
    constructor(string memory collectionMetadata_) {
        collectionMetadata = collectionMetadata_;
    }

    string public collectionMetadata;

    function _setCollectionMetadata(string memory newMetadata) internal {
        collectionMetadata = newMetadata;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/*
Minimal ownable lock, based on "openzeppelin's access/Ownable.sol";
*/
error RMRKLocked();
error RMRKNotOwner();
error RMRKNewOwnerIsZeroAddress();

contract OwnableLock is Context {
    bool private _lock;
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Throws if the lock flag is set to true.
     */
    modifier notLocked() {
        _onlyNotLocked();
        _;
    }

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
     * @dev Sets the lock -- once locked functions marked notLocked cannot be accessed.
     */
    function setLock() external onlyOwner {
        _lock = true;
    }

    /**
     * @dev Returns lock status.
     */
    function getLock() public view returns (bool) {
        return _lock;
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
        if (owner() == address(0)) revert RMRKNewOwnerIsZeroAddress();
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

    function _onlyOwner() private view {
        if (owner() != _msgSender()) revert RMRKNotOwner();
    }

    function _onlyNotLocked() private view {
        if (getLock()) revert RMRKLocked();
    }
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKNesting is IERC165 {
    struct RMRKOwner {
        uint256 tokenId;
        address ownerAddress;
        bool isNft;
    }

    /**
     * @dev emitted when a child NFT is added to a token's pending array
     */
    event ChildProposed(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex
    );

    /**
     * @dev emitted when a child NFT accepts a token from its pending array, migrating it to the active array.
     */
    event ChildAccepted(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex
    );

    /**
     * @dev emitted when a token accepts removes a child token from its pending array.
     */
    event ChildRejected(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex
    );

    /**
     * @dev emitted when a token removes all a child tokens from its pending array.
     */
    event AllChildrenRejected(uint256 indexed tokenId);

    /**
     * @dev emitted when a token unnests a child from itself, transferring ownership to the root owner.
     */
    event ChildUnnested(
        uint256 indexed tokenId,
        address indexed childAddress,
        uint256 indexed childId,
        uint256 childIndex
    );

    /**
     * @dev Struct used to store child object data.
     */
    struct Child {
        uint256 tokenId;
        address contractAddress;
    }

    /**
     * @dev Returns the 'root' owner of an NFT. If this is a child of another NFT, this will return an EOA
     * address. Otherwise, it will return the immediate owner.
     *
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Returns the immediate owner of an NFT -- if the owner is another RMRK NFT, the uint256 will reflect
     *
     */
    function rmrkOwnerOf(uint256 tokenId)
        external
        view
        returns (
            address,
            uint256,
            bool
        );

    //TODO: Docs
    function burnChild(uint256 tokenId, uint256 childIndex) external;

    //TODO: Docs
    function burnFromParent(uint256 tokenId) external;

    /**
     * @dev Function to be called into by other instances of RMRK nesting contracts to update the `child` struct
     * of the parent.
     *
     * Requirements:
     *
     * - `ownerOf` on the child contract must resolve to the called contract.
     * - the pending array of the parent contract must not be full.
     */
    function addChild(uint256 parentTokenId, uint256 childTokenId) external;

    /**
     * @dev Function called to accept a pending child. Migrates the child at `index` on `parentTokenId` to
     * the accepted children array.
     *
     * Requirements:
     *
     * - `parentTokenId` must exist
     *
     */
    function acceptChild(uint256 parentTokenId, uint256 index) external;

    /**
     * @dev Function called to reject a pending child. Removes the child from the pending array mapping.
     * The child's ownership structures are not updated.
     *
     * Requirements:
     *
     * - `parentTokenId` must exist
     *
     */
    function rejectChild(
        uint256 parentTokenId,
        uint256 index,
        address to
    ) external;

    /**
     * @dev Function called to reject all pending children. Removes the children from the pending array mapping.
     * The children's ownership structures are not updated.
     *
     * Requirements:
     *
     * - `parentTokenId` must exist
     *
     */
    function rejectAllChildren(uint256 parentTokenId) external;

    /**
     * @dev Function called to unnest a child from `tokenId`'s child array. The owner of the token
     * is set to `to`, or is not updated in the event `to` is the zero address
     *
     * Requirements:
     *
     * - `tokenId` must exist
     *
     */
    function unnestChild(
        uint256 tokenId,
        uint256 index,
        address to
    ) external;

    /**
     * @dev Function called to reclaim an abandoned child created by unnesting with `to` as the zero
     * address. This function will set the child's owner to the rootOwner of the caller, allowing
     * the rootOwner management permissions for the child.
     *
     * Requirements:
     *
     * - `tokenId` must exist
     *
     */
    function reclaimChild(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) external;

    /**
     * @dev Returns array of child objects existing for `parentTokenId`.
     *
     */
    function childrenOf(uint256 parentTokenId)
        external
        view
        returns (Child[] memory);

    /**
     * @dev Returns array of pending child objects existing for `parentTokenId`.
     *
     */
    function pendingChildrenOf(uint256 parentTokenId)
        external
        view
        returns (Child[] memory);

    /**
     * @dev Returns a single child object existing at `index` on `parentTokenId`.
     *
     */
    function childOf(uint256 parentTokenId, uint256 index)
        external
        view
        returns (Child memory);

    /**
     * @dev Returns a single pending child object existing at `index` on `parentTokenId`.
     *
     */
    function pendingChildOf(uint256 parentTokenId, uint256 index)
        external
        view
        returns (Child memory);

    /**
     * @dev Function called when calling transferFrom with the target as another NFT via `tokenId`
     * on `to`.
     *
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKMultiResource is IERC165 {
    /**
     * @notice emitted when a resource object is initialized at resourceId
     */
    event ResourceSet(uint64 indexed resourceId);

    /**
     * @notice emitted when a resource object at resourceId is added to tokenId's pendingResource array
     */
    event ResourceAddedToToken(
        uint256 indexed tokenId,
        uint64 indexed resourceId
    );

    /**
     * @notice emitted when a resource object at resourceId is accepted by tokenId and migrated from tokenId's pendingResource array to resource array
     */
    event ResourceAccepted(uint256 indexed tokenId, uint64 indexed resourceId);

    /**
     * @notice emitted when a resource object at resourceId is rejected from tokenId and is dropped from the pendingResource array
     */
    event ResourceRejected(uint256 indexed tokenId, uint64 indexed resourceId);

    /**
     * @notice emitted when tokenId's prioritiy array is reordered.
     */
    event ResourcePrioritySet(uint256 indexed tokenId);

    /**
     * @notice emitted when a resource object at resourceId is proposed to tokenId, and that proposal will initiate an overwrite of overwrites with resourceId if accepted.
     */
    event ResourceOverwriteProposed(
        uint256 indexed tokenId,
        uint64 indexed resourceId,
        uint64 indexed overwritesId
    );

    /**
     * @notice emitted when a pending resource with an overwrite is accepted, overwriting tokenId's resource overwritten
     */
    event ResourceOverwritten(
        uint256 indexed tokenId,
        uint64 indexed oldResourceId,
        uint64 indexed newResourceId
    );

    /**
     * @notice emitted when owner approves approved to manage the resources of tokenId. Approvals are cleared on action.
     */
    event ApprovalForResources(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @notice emitted when owner approves operator to manage the resources of tokenId. Approvals are not cleared on action.
     */
    event ApprovalForAllForResources(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Resource object used by the RMRK NFT protocol
     */
    struct Resource {
        uint64 id; //8 bytes
        string metadataURI; //32+
    }

    /**
     * @notice Accepts a resource at `index` on pending array of `tokenId`.
     * Migrates the resource from the token's pending resource array to the active resource array.
     *
     * Active resources cannot be removed by anyone, but can be replaced by a new resource.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - `index` must be in range of the length of the pending resource array.
     *
     * Emits an {ResourceAccepted} event.
     */
    function acceptResource(uint256 tokenId, uint256 index) external;

    /**
     * @notice Rejects a resource at `index` on pending array of `tokenId`.
     * Removes the resource from the token's pending resource array.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - `index` must be in range of the length of the pending resource array.
     *
     * Emits a {ResourceRejected} event.
     */
    function rejectResource(uint256 tokenId, uint256 index) external;

    /**
     * @notice Rejects all resources from the pending array of `tokenId`.
     * Effecitvely deletes the array.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits a {ResourceRejected} event with resourceId = 0.
     */
    function rejectAllResources(uint256 tokenId) external;

    /**
     * @notice Sets a new priority array on `tokenId`.
     * The priority array is a non-sequential list of uint16s, where lowest uint64 is considered highest priority.
     * `0` priority is a special case which is equibvalent to unitialized.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - The length of `priorities` must be equal to the length of the active resources array.
     *
     * Emits a {ResourcePrioritySet} event.
     */
    function setPriority(uint256 tokenId, uint16[] calldata priorities)
        external;

    /**
     * @notice Returns IDs of active resources of `tokenId`.
     * Resource data is stored by reference, in order to access the data corresponding to the id, call `getResource(resourceId)`
     */
    function getActiveResources(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    /**
     * @notice Returns IDs of pending resources of `tokenId`.
     * Resource data is stored by reference, in order to access the data corresponding to the id, call `getResource(resourceId)`
     */
    function getPendingResources(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    /**
     * @notice Returns priorities of active resources of `tokenId`.
     */
    function getActiveResourcePriorities(uint256 tokenId)
        external
        view
        returns (uint16[] memory);

    //TODO: double check this definition, make sure it's clear enough
    /**
     * @notice Returns pending overwrite of `resourceId` on `tokenId`.
     * Resource data is stored by reference, in order to access the data corresponding to the id, call `getResource(resourceId)`
     */
    function getResourceOverwrites(uint256 tokenId, uint64 resourceId)
        external
        view
        returns (uint64);

    /**
     * @notice Returns raw bytes of `customResourceId` of `resourceId`
     * Raw bytes are stored by reference in a double mapping structure of `resourceId` => `customResourceId`
     *
     * Custom data is intended to be stored as generic bytes and decode by various protocols on an as-needed basis
     *
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /**
     * @notice Returns metadata string tokenURI of tokenId
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     */
    function getResource(uint64 resourceId)
        external
        view
        returns (Resource memory);

    /**
     * @notice Returns the ids of all stored resources
     */
    function getAllResources() external view returns (uint64[] memory);

    // Approvals

    //TODO: Make 'management action' more explicit?
    //TODO: Check event
    /**
     * @notice Gives permission to `to`  to manage `tokenId` resources.
     * The approval is cleared when a management action is taken.
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
    function approveForResources(address to, uint256 tokenId) external;

    /**
     * @notice Returns the account approved to manage resources of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedForResources(uint256 tokenId)
        external
        view
        returns (address);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its resources.
     */
    function setApprovalForAllForResources(address operator, bool approved)
        external;

    /**
     * @notice Returns if the `operator` is allowed to manage all resources of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAllForResources(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.15;

import "./IRMRKNesting.sol";
import "../library/RMRKLib.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "hardhat/console.sol";

error ERC721AddressZeroIsNotaValidOwner();
error ERC721ApprovalToCurrentOwner();
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
error ERC721ApprovedQueryForNonexistentToken();
error ERC721ApproveToCaller();
error ERC721InvalidTokenId();
error ERC721MintToTheZeroAddress();
error ERC721NotApprovedOrOwner();
error ERC721TokenAlreadyMinted();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToNonReceiverImplementer();
error ERC721TransferToTheZeroAddress();
error RMRKCallerIsNotOwnerContract();
error RMRKChildIndexOutOfRange();
error RMRKIsNotContract();
error RMRKMaxPendingChildrenReached();
error RMRKMintToNonRMRKImplementer();
error RMRKNestingTransferToNonRMRKNestingImplementer();
error RMRKNotApprovedOrDirectOwner();
error RMRKPendingChildIndexOutOfRange();
error RMRKInvalidChildReclaim();
error RMRKChildAlreadyExists();

/**
 * @dev RMRK nesting implementation. This contract is heirarchy agnostic, and can
 * support an arbitrary number of nested levels up and down, as long as gas limits
 * allow
 *
 */

contract RMRKNesting is
    Context,
    IERC165,
    IERC721,
    IERC721Metadata,
    IRMRKNesting
{
    using RMRKLib for uint256;
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ------------------- NESTING --------------

    // Mapping from token ID to RMRKOwner struct
    mapping(uint256 => RMRKOwner) internal _RMRKOwners;

    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) internal _children;

    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) internal _pendingChildren;

    // Mapping of child token address to child token Id to position in children array.
    // This may be able to be gas optimized if we can use the child as a mapping element directly.
    // We might have a first extra mapping from token Id, but since the same child cannot be
    // nested into multiple tokens we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) internal _posInChildArray;

    // -------------------------- MODIFIERS ----------------------------

    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721NotApprovedOrOwner();
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Internal function for checking token ownership relative to immediate parent.
     * @dev This does not delegate to ownerOf, which returns the root owner.
     * Reverts if caller is not immediate owner.
     * Used for parent-scoped transfers.
     * @param tokenId tokenId to check owner against.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedOrDirectOwner();
    }

    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ------------------------------- ERC721 ---------------------------------
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IRMRKNesting).interfaceId;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ERC721AddressZeroIsNotaValidOwner();
        return _balances[owner];
    }

    ////////////////////////////////////////
    //              METADATA
    ////////////////////////////////////////

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    ////////////////////////////////////////
    //              TRANSFERS
    ////////////////////////////////////////

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
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
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId);
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
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
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
        (address immediateOwner, , ) = rmrkOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, 0, to, false);
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) internal virtual {
        (address immediateOwner, , ) = rmrkOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        // Destination contract checks:
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IRMRKNesting).interfaceId))
            revert RMRKNestingTransferToNonRMRKNestingImplementer();

        _beforeTokenTransfer(from, to, tokenId);
        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, destinationId, to, true);
        _balances[to] += 1;

        // Sending to NFT:
        _sendToNFT(tokenId, destinationId, from, to);
    }

    function _sendToNFT(
        uint256 tokenId,
        uint256 destinationId,
        address from,
        address to
    ) private {
        IRMRKNesting destContract = IRMRKNesting(to);
        destContract.addChild(destinationId, tokenId);

        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    ////////////////////////////////////////
    //              MINTING
    ////////////////////////////////////////

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
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
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
        _innerMint(to, tokenId, 0);

        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) internal virtual {
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IRMRKNesting).interfaceId))
            revert RMRKMintToNonRMRKImplementer();

        _innerMint(to, tokenId, destinationId);
        _sendToNFT(tokenId, destinationId, address(0), to);
    }

    function _innerMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) private {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _RMRKOwners[tokenId] = RMRKOwner({
            ownerAddress: to,
            tokenId: destinationId,
            isNft: destinationId > 0
        });
    }

    ////////////////////////////////////////
    //              Ownership
    ////////////////////////////////////////

    /**
     * @notice Returns the root owner of the current RMRK NFT.
     * @dev In the event the NFT is owned by another NFT, it will recursively ask the parent.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(IRMRKNesting, IERC721)
        returns (address)
    {
        (address owner, uint256 ownerTokenId, bool isNft) = rmrkOwnerOf(
            tokenId
        );
        if (isNft) {
            owner = IRMRKNesting(owner).ownerOf(ownerTokenId);
        }
        return owner;
    }

    /**
     * @notice Returns the immediate provenance data of the current RMRK NFT.
     * @dev In the event the NFT is owned by a wallet, tokenId will be zero and isNft will be false. Otherwise,
     * the returned data is the contract address and tokenID of the owner NFT, as well as its isNft flag.
     */
    function rmrkOwnerOf(uint256 tokenId)
        public
        view
        virtual
        returns (
            address,
            uint256,
            bool
        )
    {
        RMRKOwner memory owner = _RMRKOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.isNft);
    }

    ////////////////////////////////////////
    //              BURNING
    ////////////////////////////////////////

    //update for reentrancy
    //Suggest delegate to _burn method, as both run same code
    function burnFromParent(uint256 tokenId) external {
        (address _RMRKOwner, , ) = rmrkOwnerOf(tokenId);
        if (_RMRKOwner != _msgSender()) revert RMRKCallerIsNotOwnerContract();
        address owner = ownerOf(tokenId);
        _burnForOwner(tokenId, owner);
        _balances[_RMRKOwner] -= 1;
    }

    function burnChild(uint256 tokenId, uint256 index)
        external
        onlyApprovedOrDirectOwner(tokenId)
    {
        if (_children[tokenId].length <= index)
            revert RMRKChildIndexOutOfRange();

        Child memory child = _children[tokenId][index];
        IRMRKNesting(child.contractAddress).burnFromParent(child.tokenId);
        _removeChildByIndex(_children[tokenId], index);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */

    //update for reentrancy
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        (address rmrkOwner, , ) = rmrkOwnerOf(tokenId);
        _balances[rmrkOwner] -= 1;
        _burnForOwner(tokenId, owner);
    }

    function _burnForOwner(uint256 tokenId, address rootOwner) private {
        _beforeTokenTransfer(rootOwner, address(0), tokenId);
        _approve(address(0), tokenId);
        _cleanApprovals(address(0), tokenId);

        Child[] memory children = childrenOf(tokenId);

        uint256 length = children.length; //gas savings
        for (uint256 i; i < length; ) {
            address childContractAddress = children[i].contractAddress;
            uint256 childTokenId = children[i].tokenId;
            IRMRKNesting(childContractAddress).burnFromParent(childTokenId);
            unchecked {
                ++i;
            }
        }
        delete _RMRKOwners[tokenId];
        delete _pendingChildren[tokenId];
        delete _children[tokenId];
        delete _tokenApprovals[tokenId];

        _afterTokenTransfer(rootOwner, address(0), tokenId);
        emit Transfer(rootOwner, address(0), tokenId);
    }

    ////////////////////////////////////////
    //              APPROVALS
    ////////////////////////////////////////

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (_msgSender() == operator) revert ERC721ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to,
        bool isNft
    ) internal {
        _RMRKOwners[tokenId] = RMRKOwner({
            ownerAddress: to,
            tokenId: destinationId,
            isNft: isNft
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _cleanApprovals(address(0), tokenId);
    }

    function _cleanApprovals(address owner, uint256 tokenId) internal virtual {}

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    //TODO: Code review here -- Accepting perms that aren't always used
    function _isApprovedOrDirectOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        (address owner, uint256 parentTokenId, ) = rmrkOwnerOf(tokenId);
        if (parentTokenId != 0) {
            return (spender == owner);
        }
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */

    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId();
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
        return _RMRKOwners[tokenId].ownerAddress != address(0);
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
    ) internal returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonReceiverImplementer();
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    ////////////////////////////////////////
    //      CHILD MANAGEMENT PUBLIC
    ////////////////////////////////////////

    /**
     * @dev Function designed to be used by other instances of RMRK-Core contracts to update children.
     * param1 parentTokenId is the tokenId of the parent token on (this).
     * param2 childTokenId is the tokenId of the child instance
     */

    //update for reentrancy
    function addChild(uint256 parentTokenId, uint256 childTokenId)
        public
        virtual
    {
        if (!_exists(parentTokenId)) revert ERC721InvalidTokenId();

        if (!_msgSender().isContract()) revert RMRKIsNotContract();
        // TODO: Check if it's worth to call back the sender to assert it is the owner of the childId
        // Probably not worth it since a malicious child contract could only affect itself.

        Child memory child = Child({
            contractAddress: _msgSender(),
            tokenId: childTokenId
        });

        uint256 length = _pendingChildren[parentTokenId].length;

        if (length < 128) {
            _pendingChildren[parentTokenId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }

        // Previous lenght matches the index for the new child
        emit ChildProposed(parentTokenId, _msgSender(), childTokenId, length);
    }

    /**
     * @notice Sends an instance of Child from the pending children array at index to children array for tokenId.
     * @param tokenId tokenId of parent token to accept a child on
     * @param index index of child in _pendingChildren array to accept.
     */
    function acceptChild(uint256 tokenId, uint256 index)
        public
        virtual
        onlyApprovedOrOwner(tokenId)
    {
        if (_pendingChildren[tokenId].length <= index)
            revert RMRKPendingChildIndexOutOfRange();

        Child memory child = _pendingChildren[tokenId][index];

        if (_posInChildArray[child.contractAddress][child.tokenId] != 0)
            revert RMRKChildAlreadyExists();

        _removeChildByIndex(_pendingChildren[tokenId], index);

        _children[tokenId].push(child);

        _posInChildArray[child.contractAddress][child.tokenId] = _children[
            tokenId
        ].length;

        emit ChildAccepted(
            tokenId,
            child.contractAddress,
            child.tokenId,
            index
        );
    }

    /**
     * @notice Deletes all pending children.
     * @dev This does not update the ownership storage data on children. If necessary, ownership
     * can be reclaimed by the rootOwner of the previous parent (this).
     */
    function rejectAllChildren(uint256 tokenId)
        public
        virtual
        onlyApprovedOrOwner(tokenId)
    {
        delete (_pendingChildren[tokenId]);
        emit AllChildrenRejected(tokenId);
    }

    /**
     * @notice Deletes a single child from the pending array by index.
     * @param tokenId tokenId whose pending child is to be rejected
     * @param index index on tokenId pending child array to reject
     * @param to if an address which is not the zero address is passed, this will attempt to transfer
     * the child to `to` via a call-in to the child address.
     * @dev If `to` is the zero address, the child's ownership structures will not be updated, resulting in an
     * 'orphaned' child. If a call with a populated `to` field fails, call this function with `to` set to the
     * zero address to orphan the child. Orphaned children can be reclaimed by a call to reclaimChild on this
     * contract by the root owner.
     */

    function rejectChild(
        uint256 tokenId,
        uint256 index,
        address to
    ) public virtual onlyApprovedOrOwner(tokenId) {
        if (_pendingChildren[tokenId].length <= index)
            revert RMRKPendingChildIndexOutOfRange();

        Child memory pendingChild = _pendingChildren[tokenId][index];

        _removeChildByIndex(_pendingChildren[tokenId], index);

        if (to != address(0)) {
            IERC721(pendingChild.contractAddress).safeTransferFrom(
                address(this),
                to,
                pendingChild.tokenId
            );
        }

        emit ChildRejected(
            tokenId,
            pendingChild.contractAddress,
            pendingChild.tokenId,
            index
        );
    }

    /**
     * @notice Function to unnest a child from the active token array.
     * @param tokenId is the tokenId of the parent token to unnest from.
     * @param index is the index of the child token ID.
     * @param to is the address to transfer this
     */
    function unnestChild(
        uint256 tokenId,
        uint256 index,
        address to
    ) public virtual onlyApprovedOrOwner(tokenId) {
        if (_children[tokenId].length <= index)
            revert RMRKChildIndexOutOfRange();

        Child memory child = _children[tokenId][index];
        delete _posInChildArray[child.contractAddress][child.tokenId];
        _removeChildByIndex(_children[tokenId], index);

        if (to != address(0)) {
            IERC721(child.contractAddress).safeTransferFrom(
                address(this),
                to,
                child.tokenId
            );
        }

        emit ChildUnnested(
            tokenId,
            child.contractAddress,
            child.tokenId,
            index
        );
    }

    function reclaimChild(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) public onlyApprovedOrOwner(tokenId) {
        (address owner, uint256 ownerTokenId, bool isNft) = IRMRKNesting(
            childAddress
        ).rmrkOwnerOf(childTokenId);
        if (owner != address(this) || ownerTokenId != tokenId || !isNft)
            revert RMRKInvalidChildReclaim();
        IERC721(childAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            childTokenId
        );
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT GETTERS
    ////////////////////////////////////////

    /**
     * @notice Returns all confirmed children
     */

    function childrenOf(uint256 parentTokenId)
        public
        view
        returns (Child[] memory)
    {
        Child[] memory children = _children[parentTokenId];
        return children;
    }

    /**
     * @notice Returns all pending children
     */

    function pendingChildrenOf(uint256 parentTokenId)
        public
        view
        returns (Child[] memory)
    {
        Child[] memory pendingChildren = _pendingChildren[parentTokenId];
        return pendingChildren;
    }

    function childOf(uint256 parentTokenId, uint256 index)
        public
        view
        returns (Child memory)
    {
        if (_children[parentTokenId].length <= index)
            revert RMRKChildIndexOutOfRange();
        Child memory child = _children[parentTokenId][index];
        return child;
    }

    function pendingChildOf(uint256 parentTokenId, uint256 index)
        public
        view
        returns (Child memory)
    {
        if (_pendingChildren[parentTokenId].length <= index)
            revert RMRKPendingChildIndexOutOfRange();
        Child memory child = _pendingChildren[parentTokenId][index];
        return child;
    }

    //HELPERS

    // For child storage array, callers must check valid length
    function _removeChildByIndex(Child[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

library RMRKLib {
    function removeItemByValue(uint64[] storage array, uint64 value) internal {
        uint64[] memory memArr = array; //Copy array to memory, check for gas savings here
        uint256 length = memArr.length; //gas savings
        for (uint256 i; i < length; ) {
            if (memArr[i] == value) {
                removeItemByIndex(array, i);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    //For resource storage array
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    // indexOf adapted from Cryptofin-Solidity arrayUtils
    function indexOf(uint64[] memory A, uint64 a)
        internal
        pure
        returns (uint256, bool)
    {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked {
                ++i;
            }
        }
        return (0, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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