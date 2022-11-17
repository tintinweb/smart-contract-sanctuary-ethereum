// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../extensions/ICreatorExtensionTokenURI.sol";

import "./ICreatorCore.sol";

/**
 * @dev Core creator implementation
 */
abstract contract CreatorCore is ReentrancyGuard, ICreatorCore, ERC165 {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressUpgradeable for address;

    uint256 _tokenCount = 0;

    // Track registered extensions data
    EnumerableSet.AddressSet internal _extensions;
    EnumerableSet.AddressSet internal _blacklistedExtensions;
    mapping (address => address) internal _extensionPermissions;
    mapping (address => bool) internal _extensionApproveTransfers;
    
    // For tracking which extension a token was minted by
    mapping (uint256 => address) internal _tokensExtension;

    // The baseURI for a given extension
    mapping (address => string) private _extensionBaseURI;
    mapping (address => bool) private _extensionBaseURIIdentical;

    // The prefix for any tokens with a uri configured
    mapping (address => string) private _extensionURIPrefix;

    // Mapping for individual token URIs
    mapping (uint256 => string) internal _tokenURIs;

    
    // Royalty configurations
    mapping (address => address payable[]) internal _extensionRoyaltyReceivers;
    mapping (address => uint256[]) internal _extensionRoyaltyBPS;
    mapping (uint256 => address payable[]) internal _tokenRoyaltyReceivers;
    mapping (uint256 => uint256[]) internal _tokenRoyaltyBPS;

    /**
     * External interface identifiers for royalties
     */

    /**
     *  @dev CreatorCore
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *  bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     *
     *  => 0xb9c4d9fb ^ 0x0ebd4c7f = 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    /**
     *  @dev Foundation
     *
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_FOUNDATION = 0xd5a06d4c;

    /**
     *  @dev EIP-2981
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorCore).interfaceId || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    modifier extensionRequired() {
        require(_extensions.contains(msg.sender), "Must be registered extension");
        _;
    }

    /**
     * @dev Only allows non-blacklisted extensions
     */
    modifier nonBlacklistRequired(address extension) {
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
        _;
    }   

    /**
     * @dev See {ICreatorCore-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory extensions) {
        extensions = new address[](_extensions.length());
        for (uint i = 0; i < _extensions.length(); i++) {
            extensions[i] = _extensions.at(i);
        }
        return extensions;
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal {
        require(extension != address(0) && extension != address(this), "Creator: Invalid");
        require(extension.isContract(), "Creator: Extension must be a contract");
        if (!_extensions.contains(extension)) {
            _extensionBaseURI[extension] = baseURI;
            _extensionBaseURIIdentical[extension] = baseURIIdentical;
            emit ExtensionRegistered(extension, msg.sender);
            _extensions.add(extension);
        }
    }

    /**
     * @dev Unregister an extension
     */
    function _unregisterExtension(address extension) internal {
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
    }

    /**
     * @dev Blacklist an extension
     */
    function _blacklistExtension(address extension) internal {
       require(extension != address(0) && extension != address(this), "Cannot blacklist yourself");
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
       if (!_blacklistedExtensions.contains(extension)) {
           emit ExtensionBlacklisted(extension, msg.sender);
           _blacklistedExtensions.add(extension);
       }
    }

    /**
     * @dev Set base token uri for an extension
     */
    function _setBaseTokenURIExtension(string calldata uri, bool identical) internal {
        _extensionBaseURI[msg.sender] = uri;
        _extensionBaseURIIdentical[msg.sender] = identical;
    }

    /**
     * @dev Set token uri prefix for an extension
     */
    function _setTokenURIPrefixExtension(string calldata prefix) internal {
        _extensionURIPrefix[msg.sender] = prefix;
    }

    /**
     * @dev Set token uri for a token of an extension
     */
    function _setTokenURIExtension(uint256 tokenId, string calldata uri) internal {
        require(_tokensExtension[tokenId] == msg.sender, "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Set base token uri for tokens with no extension
     */
    function _setBaseTokenURI(string memory uri) internal {
        _extensionBaseURI[address(0)] = uri;
    }

    /**
     * @dev Set token uri prefix for tokens with no extension
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _extensionURIPrefix[address(0)] = prefix;
    }


    /**
     * @dev Set token uri for a token with no extension
     */
    function _setTokenURI(uint256 tokenId, string calldata uri) internal {
        require(tokenId > 0 && tokenId <= _tokenCount && _tokensExtension[tokenId] == address(0), "Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Retrieve a token's URI
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        require(tokenId > 0 && tokenId <= _tokenCount, "Invalid token");

        address extension = _tokensExtension[tokenId];
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            if (bytes(_extensionURIPrefix[extension]).length != 0) {
                return string(abi.encodePacked(_extensionURIPrefix[extension],_tokenURIs[tokenId]));
            }
            return _tokenURIs[tokenId];
        }

        if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionTokenURI).interfaceId)) {
            return ICreatorExtensionTokenURI(extension).tokenURI(address(this), tokenId);
        }

        if (!_extensionBaseURIIdentical[extension]) {
            return string(abi.encodePacked(_extensionBaseURI[extension], tokenId.toString()));
        } else {
            return _extensionBaseURI[extension];
        }
    }

    /**
     * Get token extension
     */
    function _tokenExtension(uint256 tokenId) internal view returns (address extension) {
        extension = _tokensExtension[tokenId];

        require(extension != address(0), "No extension for token");
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");

        return extension;
    }

    /**
     * Helper to get royalties for a token
     */
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] storage, uint256[] storage) {
        return (_getRoyaltyReceivers(tokenId), _getRoyaltyBPS(tokenId));
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] storage) {
        if (_tokenRoyaltyReceivers[tokenId].length > 0) {
            return _tokenRoyaltyReceivers[tokenId];
        } else if (_extensionRoyaltyReceivers[_tokensExtension[tokenId]].length > 0) {
            return _extensionRoyaltyReceivers[_tokensExtension[tokenId]];
        }
        return _extensionRoyaltyReceivers[address(0)];
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] storage) {
        if (_tokenRoyaltyBPS[tokenId].length > 0) {
            return _tokenRoyaltyBPS[tokenId];
        } else if (_extensionRoyaltyBPS[_tokensExtension[tokenId]].length > 0) {
            return _extensionRoyaltyBPS[_tokensExtension[tokenId]];
        }
        return _extensionRoyaltyBPS[address(0)];        
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount){
        address payable[] storage receivers = _getRoyaltyReceivers(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");
        
        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], _getRoyaltyBPS(tokenId)[0]*value/10000);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _tokenRoyaltyReceivers[tokenId] = receivers;
        _tokenRoyaltyBPS[tokenId] = basisPoints;
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
        _extensionRoyaltyReceivers[extension] = receivers;
        _extensionRoyaltyBPS[extension] = basisPoints;
        if (extension == address(0)) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit ExtensionRoyaltiesUpdated(extension, receivers, basisPoints);
        }
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/ERC1155/IERC1155CreatorExtensionApproveTransfer.sol";
import "../extensions/ERC1155/IERC1155CreatorExtensionBurnable.sol";
import "../permissions/ERC1155/IERC1155CreatorMintPermissions.sol";
import "./IERC1155CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator implementation
 */
abstract contract ERC1155CreatorCore is CreatorCore, IERC1155CreatorCore {

    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC1155CreatorCore).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override extensionRequired {
        require(!enabled || ERC165Checker.supportsInterface(msg.sender, type(IERC1155CreatorExtensionApproveTransfer).interfaceId), "Extension must implement IERC1155CreatorExtensionApproveTransfer");
        if (_extensionApproveTransfers[msg.sender] != enabled) {
            _extensionApproveTransfers[msg.sender] = enabled;
            emit ExtensionApproveTransferUpdated(msg.sender, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "Invalid extension");
        require(permissions == address(0x0) || ERC165Checker.supportsInterface(permissions, type(IERC1155CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * Check if an extension can mint
     */
    function _checkMintPermissions(address[] memory to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        if (_extensionPermissions[msg.sender] != address(0x0)) {
            IERC1155CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenIds, amounts);
        }
    }

    /**
     * Post burn actions
     */
    function _postBurn(address owner, uint256[] memory tokenIds, uint256[] memory amounts) internal virtual {
        require(tokenIds.length > 0, "Invalid input");
        address extension = _tokensExtension[tokenIds[0]];
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == extension, "Mismatched token originators");
        }
        // Callback to originating extension if needed
        if (extension != address(0)) {
           if (ERC165Checker.supportsInterface(extension, type(IERC1155CreatorExtensionBurnable).interfaceId)) {
               IERC1155CreatorExtensionBurnable(extension).onBurn(owner, tokenIds, amounts);
           }
        }
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        require(tokenIds.length > 0, "Invalid input");
        address extension = _tokensExtension[tokenIds[0]];
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == extension, "Mismatched token originators");
        }
        if (_extensionApproveTransfers[extension]) {
            require(IERC1155CreatorExtensionApproveTransfer(extension).approveTransfer(from, to, tokenIds, amounts), "Extension approval failure");
        }
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/ERC721/IERC721CreatorExtensionApproveTransfer.sol";
import "../extensions/ERC721/IERC721CreatorExtensionBurnable.sol";
import "../permissions/ERC721/IERC721CreatorMintPermissions.sol";
import "./IERC721CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC721 creator implementation
 */
abstract contract ERC721CreatorCore is CreatorCore, IERC721CreatorCore {

    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCore).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override extensionRequired {
        require(!enabled || ERC165Checker.supportsInterface(msg.sender, type(IERC721CreatorExtensionApproveTransfer).interfaceId), "Extension must implement IERC721CreatorExtensionApproveTransfer");
        if (_extensionApproveTransfers[msg.sender] != enabled) {
            _extensionApproveTransfers[msg.sender] = enabled;
            emit ExtensionApproveTransferUpdated(msg.sender, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "CreatorCore: Invalid extension");
        require(permissions == address(0x0) || ERC165Checker.supportsInterface(permissions, type(IERC721CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * Check if an extension can mint
     */
    function _checkMintPermissions(address to, uint256 tokenId) internal {
        if (_extensionPermissions[msg.sender] != address(0x0)) {
            IERC721CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenId);
        }
    }

    /**
     * Override for post mint actions
     */
    function _postMintBase(address, uint256) internal virtual {}

    
    /**
     * Override for post mint actions
     */
    function _postMintExtension(address, uint256) internal virtual {}

    /**
     * Post-burning callback and metadata cleanup
     */
    function _postBurn(address owner, uint256 tokenId) internal virtual {
        // Callback to originating extension if needed
        if (_tokensExtension[tokenId] != address(0)) {
           if (ERC165Checker.supportsInterface(_tokensExtension[tokenId], type(IERC721CreatorExtensionBurnable).interfaceId)) {
               IERC721CreatorExtensionBurnable(_tokensExtension[tokenId]).onBurn(owner, tokenId);
           }
        }
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }    
        // Delete token origin extension tracking
        delete _tokensExtension[tokenId];    
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256 tokenId) internal {
       if (_extensionApproveTransfers[_tokensExtension[tokenId]]) {
           require(IERC721CreatorExtensionApproveTransfer(_tokensExtension[tokenId]).approveTransfer(from, to, tokenId), "ERC721Creator: Extension approval failure");
       }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator interface
 */
interface IERC1155CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     *
     * @param to       - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param amounts  - Can be a single element array (all recipients get the same amount) or a multi-element array
     * @param uris     - If no elements, all tokens use the default uri.
     *                   If any element is an empty string, the corresponding token uses the default uri.
     *
     *
     * Requirements: If to is a multi-element array, then uris must be empty or single element array
     *               If to is a multi-element array, then amounts must be a single element array or a multi-element array of the same size
     *               If to is a single element array, uris must be empty or the same length as amounts
     *
     * Examples:
     *    mintBaseNew(['0x....1', '0x....2'], [1], [])
     *        Mints a single new token, and gives 1 each to '0x....1' and '0x....2'.  Token uses default uri.
     *    
     *    mintBaseNew(['0x....1', '0x....2'], [1, 2], [])
     *        Mints a single new token, and gives 1 to '0x....1' and 2 to '0x....2'.  Token uses default uri.
     *    
     *    mintBaseNew(['0x....1'], [1, 2], ["", "http://token2.com"])
     *        Mints two new tokens to '0x....1'. 1 of the first token, 2 of the second.  1st token uses default uri, second uses "http://token2.com".
     *    
     * @return Returns list of tokenIds minted
     */
    function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint existing token with no extension. Can only be called by an admin.
     *
     * @param to        - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param tokenIds  - Can be a single element array (all recipients get the same token) or a multi-element array
     * @param amounts   - Can be a single element array (all recipients get the same amount) or a multi-element array
     *
     * Requirements: If any of the parameters are multi-element arrays, they need to be the same length as other multi-element arrays
     *
     * Examples:
     *    mintBaseExisting(['0x....1', '0x....2'], [1], [10])
     *        Mints 10 of tokenId 1 to each of '0x....1' and '0x....2'.
     *    
     *    mintBaseExisting(['0x....1', '0x....2'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 2 to '0x....2'.
     *    
     *    mintBaseExisting(['0x....1'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 and 20 of tokenId 2 to '0x....1'.
     *    
     *    mintBaseExisting(['0x....1', '0x....2'], [1], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 1 to '0x....2'.
     *    
     */
    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev mint a token from an extension. Can only be called by a registered extension.
     *
     * @param to       - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param amounts  - Can be a single element array (all recipients get the same amount) or a multi-element array
     * @param uris     - If no elements, all tokens use the default uri.
     *                   If any element is an empty string, the corresponding token uses the default uri.
     *
     *
     * Requirements: If to is a multi-element array, then uris must be empty or single element array
     *               If to is a multi-element array, then amounts must be a single element array or a multi-element array of the same size
     *               If to is a single element array, uris must be empty or the same length as amounts
     *
     * Examples:
     *    mintExtensionNew(['0x....1', '0x....2'], [1], [])
     *        Mints a single new token, and gives 1 each to '0x....1' and '0x....2'.  Token uses default uri.
     *    
     *    mintExtensionNew(['0x....1', '0x....2'], [1, 2], [])
     *        Mints a single new token, and gives 1 to '0x....1' and 2 to '0x....2'.  Token uses default uri.
     *    
     *    mintExtensionNew(['0x....1'], [1, 2], ["", "http://token2.com"])
     *        Mints two new tokens to '0x....1'. 1 of the first token, 2 of the second.  1st token uses default uri, second uses "http://token2.com".
     *    
     * @return Returns list of tokenIds minted
     */
    function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint existing token from extension. Can only be called by a registered extension.
     *
     * @param to        - Can be a single element array (all tokens go to same address) or multi-element array (single token to many recipients)
     * @param tokenIds  - Can be a single element array (all recipients get the same token) or a multi-element array
     * @param amounts   - Can be a single element array (all recipients get the same amount) or a multi-element array
     *
     * Requirements: If any of the parameters are multi-element arrays, they need to be the same length as other multi-element arrays
     *
     * Examples:
     *    mintExtensionExisting(['0x....1', '0x....2'], [1], [10])
     *        Mints 10 of tokenId 1 to each of '0x....1' and '0x....2'.
     *    
     *    mintExtensionExisting(['0x....1', '0x....2'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 2 to '0x....2'.
     *    
     *    mintExtensionExisting(['0x....1'], [1, 2], [10, 20])
     *        Mints 10 of tokenId 1 and 20 of tokenId 2 to '0x....1'.
     *    
     *    mintExtensionExisting(['0x....1', '0x....2'], [1], [10, 20])
     *        Mints 10 of tokenId 1 to '0x....1' and 20 of tokenId 1 to '0x....2'.
     *    
     */
    function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev burn tokens. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(address account, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev Total amount of tokens in with a given tokenId.
     */
    function totalSupply(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./core/ERC1155CreatorCore.sol";

/**
 * @dev ERC1155Creator implementation
 */
contract ERC1155Creator is AdminControl, ERC1155, ERC1155CreatorCore {

    mapping(uint256 => uint256) private _totalSupply;

    constructor () ERC1155("") {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155CreatorCore, AdminControl) returns (bool) {
        return ERC1155CreatorCore.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) internal virtual override {
        _approveTransfer(from, to, ids, amounts);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_) external override extensionRequired {
        _setBaseTokenURIExtension(uri_, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_, bool identical) external override extensionRequired {
        _setBaseTokenURIExtension(uri_, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override extensionRequired {
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri_) external override extensionRequired {
        _setTokenURIExtension(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override extensionRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURIExtension(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri_) external override adminRequired {
        _setBaseTokenURI(uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri_) external override adminRequired {
        _setTokenURI(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseNew}.
     */
    function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory) {
        return _mintNew(address(0), to, amounts, uris);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseExisting}.
     */
    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant adminRequired {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId > 0 && tokenId <= _tokenCount, "Invalid token");
            require(_tokensExtension[tokenId] == address(0), "A token was created by an extension");
        }
        _mintExisting(address(0), to, tokenIds, amounts);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionNew}.
     */
    function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant extensionRequired returns(uint256[] memory tokenIds) {
        return _mintNew(msg.sender, to, amounts, uris);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionExisting}.
     */
    function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant extensionRequired {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == address(msg.sender), "A token was not created by this extension");
        }
        _mintExisting(msg.sender, to, tokenIds, amounts);
    }

    /**
     * @dev Mint new tokens
     */
    function _mintNew(address extension, address[] memory to, uint256[] memory amounts, string[] memory uris) internal returns(uint256[] memory tokenIds) {
        if (to.length > 1) {
            // Multiple receiver.  Give every receiver the same new token
            tokenIds = new uint256[](1);
            require(uris.length <= 1 && (amounts.length == 1 || to.length == amounts.length), "Invalid input");
        } else {
            // Single receiver.  Generating multiple tokens
            tokenIds = new uint256[](amounts.length);
            require(uris.length == 0 || amounts.length == uris.length, "Invalid input");
        }

        // Assign tokenIds
        for (uint i = 0; i < tokenIds.length; i++) {
            _tokenCount++;
            tokenIds[i] = _tokenCount;
            // Track the extension that minted the token
            _tokensExtension[_tokenCount] = extension;
        }

        if (extension != address(0)) {
            _checkMintPermissions(to, tokenIds, amounts);
        }

        if (to.length == 1 && tokenIds.length == 1) {
           // Single mint
           _mint(to[0], tokenIds[0], amounts[0], new bytes(0));
        } else if (to.length > 1) {
            // Multiple receivers.  Receiving the same token
            if (amounts.length == 1) {
                // Everyone receiving the same amount
                for (uint i = 0; i < to.length; i++) {
                    _mint(to[i], tokenIds[0], amounts[0], new bytes(0));
                }
            } else {
                // Everyone receiving different amounts
                for (uint i = 0; i < to.length; i++) {
                    _mint(to[i], tokenIds[0], amounts[i], new bytes(0));
                }
            }
        } else {
            _mintBatch(to[0], tokenIds, amounts, new bytes(0));
        }

        for (uint i = 0; i < tokenIds.length; i++) {
            if (i < uris.length && bytes(uris[i]).length > 0) {
                _tokenURIs[tokenIds[i]] = uris[i];
            }
        }
        return tokenIds;
    }

    /**
     * @dev Mint existing tokens
     */
    function _mintExisting(address extension, address[] memory to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        if (extension != address(0)) {
            _checkMintPermissions(to, tokenIds, amounts);
        }

        if (to.length == 1 && tokenIds.length == 1 && amounts.length == 1) {
             // Single mint
            _mint(to[0], tokenIds[0], amounts[0], new bytes(0));            
        } else if (to.length == 1 && tokenIds.length == amounts.length) {
            // Batch mint to same receiver
            _mintBatch(to[0], tokenIds, amounts, new bytes(0));
        } else if (tokenIds.length == 1 && amounts.length == 1) {
            // Mint of the same token/token amounts to various receivers
            for (uint i = 0; i < to.length; i++) {
                _mint(to[i], tokenIds[0], amounts[0], new bytes(0));
            }
        } else if (tokenIds.length == 1 && to.length == amounts.length) {
            // Mint of the same token with different amounts to different receivers
            for (uint i = 0; i < to.length; i++) {
                _mint(to[i], tokenIds[0], amounts[i], new bytes(0));
            }
        } else if (to.length == tokenIds.length && to.length == amounts.length) {
            // Mint of different tokens and different amounts to different receivers
            for (uint i = 0; i < to.length; i++) {
                _mint(to[i], tokenIds[i], amounts[i], new bytes(0));
            }
        } else {
            revert("Invalid input");
        }
    }

    /**
     * @dev See {IERC1155CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address) {
        return _tokenExtension(tokenId);
    }

    /**
     * @dev See {IERC1155CreatorCore-burn}.
     */
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) public virtual override nonReentrant {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner nor approved");
        require(tokenIds.length == amounts.length, "Invalid input");
        if (tokenIds.length == 1) {
            _burn(account, tokenIds[0], amounts[0]);
        } else {
            _burnBatch(account, tokenIds, amounts);
        }
        _postBurn(account, tokenIds, amounts);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURI(tokenId);
    }
    
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 tokenId) external view virtual override returns (uint256) {
        return _totalSupply[tokenId];
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "./core/ERC721CreatorCore.sol";

/**
 * @dev ERC721Creator implementation
 */
contract ERC721Creator is AdminControl, ERC721, ERC721CreatorCore {

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721CreatorCore, AdminControl) returns (bool) {
        return ERC721CreatorCore.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        _approveTransfer(from, to, tokenId);    
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri) external override extensionRequired {
        _setBaseTokenURIExtension(uri, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external override extensionRequired {
        _setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override extensionRequired {
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external override extensionRequired {
        _setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override extensionRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURIExtension(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBase(to, "");
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to, string calldata uri) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBase(to, uri);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, uint16 count) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _mintBase(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintBase(to, uris[i]);
        }
        return tokenIds;
    }

    /**
     * @dev Mint token with no extension
     */
    function _mintBase(address to, string memory uri) internal virtual returns(uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        // Call post mint
        _postMintBase(to, tokenId);
        return tokenId;
    }


    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to) public virtual override nonReentrant extensionRequired returns(uint256) {
        return _mintExtension(to, "");
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, string calldata uri) public virtual override nonReentrant extensionRequired returns(uint256) {
        return _mintExtension(to, uri);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count) public virtual override nonReentrant extensionRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _mintExtension(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] calldata uris) public virtual override nonReentrant extensionRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintExtension(to, uris[i]);
        }
    }
    
    /**
     * @dev Mint token via extension
     */
    function _mintExtension(address to, string memory uri) internal virtual returns(uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        _checkMintPermissions(to, tokenId);

        // Track the extension that minted the token
        _tokensExtension[tokenId] = msg.sender;

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }
        
        // Call post mint
        _postMintExtension(to, tokenId);
        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenExtension(tokenId);
    }

    /**
     * @dev See {IERC721CreatorCore-burn}.
     */
    function burn(uint256 tokenId) public virtual override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        _postBurn(owner, tokenId);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        require(_exists(tokenId), "Nonexistent token");
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        require(_exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Base creator extension variables
 */
abstract contract CreatorExtension is ERC165 {

    /**
     * @dev Legacy extension interface identifiers
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */
    bytes4 constant internal LEGACY_EXTENSION_INTERFACE = 0x7005caad;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == LEGACY_EXTENSION_INTERFACE
            || super.supportsInterface(interfaceId);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC1155CreatorExtensionApproveTransfer is IERC165 {

    /**
     * @dev Set whether or not the creator contract will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC1155CreatorExtensionBurnable is IERC165 {
    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../CreatorExtension.sol";

/**
 * @dev Base ERC721 creator extension variables
 */
abstract contract ERC721CreatorExtension is CreatorExtension {

    /**
     * @dev Legacy extension interface identifiers (see CreatorExtension for more)
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */

    // Required to be recognized as a contract to receive onBurn for older creator contracts
    bytes4 constant internal LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE = 0xf3f4e68b;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../../core/IERC721CreatorCore.sol";
import "./ERC721CreatorExtension.sol";
import "./IERC721CreatorExtensionApproveTransfer.sol";

/**
 * @dev Suggested implementation for extensions that require the creator to
 * check with it before a transfer occurs
 */
abstract contract ERC721CreatorExtensionApproveTransfer is AdminControl, ERC721CreatorExtension, IERC721CreatorExtensionApproveTransfer {

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "creator must implement IERC721CreatorCore");
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC721CreatorExtensionApproveTransfer is IERC165 {

    /**
     * @dev Set whether or not the creator will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(address from, address to, uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC721CreatorExtensionBurnable is IERC165 {
    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155Creator compliant extension contracts.
 */
interface IERC1155CreatorMintPermissions is IERC165 {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IERC721CreatorMintPermissions is IERC165 {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IAdminControl.sol";

abstract contract AdminControlUpgradeable is OwnableUpgradeable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/*
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
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
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

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
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
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
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
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
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
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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

// SPDX-License-Identifier: MIT

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "../libraries/single-creator/ERC721/ERC721SingleCreatorExtension.sol";

/**
 * Extension which allows for the creation of NFTs with dynamically changing image/animation metadata 
 */
abstract contract DynamicArweaveHash is ERC721SingleCreatorExtension, CreatorExtension, Ownable, ICreatorExtensionTokenURI {

    using Strings for uint256;

    string[] public imageArweaveHashes;
    string[] public animationArweaveHashes;

    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId 
        || super.supportsInterface(interfaceId);
    }


    function tokenURI(address, uint256 tokenId) external view virtual override returns (string memory) {
        string memory uri = string(abi.encodePacked('data:application/json;utf8,{"name":"', _getName(), '","description":"', _getDescription()));
        if (imageArweaveHashes.length > 0) {
            uri = string(abi.encodePacked(uri, '", "image":"https://arweave.net/', _getImageHash(tokenId)));
        }
        if (animationArweaveHashes.length > 0) {
            uri = string(abi.encodePacked(uri, '", "animation_url":"https://arweave.net/', _getAnimationHash(tokenId)));
        }
        uri = string(abi.encodePacked(uri, '"}'));
        return uri;
    }

    function _mint(address to) internal returns(uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function _getName() internal view virtual returns(string memory);

    function _getDescription() internal view virtual returns(string memory);

    function _getImageHash(uint256 tokenId) internal view virtual returns(string memory);

    function _getAnimationHash(uint256 tokenId) internal view virtual returns(string memory);

    function setImageArweaveHashes(string[] memory _arweaveHashes) external virtual onlyOwner {
        imageArweaveHashes = _arweaveHashes;
    }

    function setAnimationAreaveHashes(string[] memory _arweaveHashes) external virtual onlyOwner {
        animationArweaveHashes = _arweaveHashes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC721/IERC721CreatorExtensionApproveTransfer.sol";

import "../libraries/ABDKMath64x64.sol";
import "../libraries/single-creator/ERC721/ERC721SingleCreatorExtension.sol";

contract DynamicSVGExample is ERC721SingleCreatorExtension, CreatorExtension, Ownable, ICreatorExtensionTokenURI, IERC721CreatorExtensionApproveTransfer {

    using Strings for uint256;
    using ABDKMath64x64 for int128;

    uint256 private _creationTimestamp;
    uint256 private _completionTimestamp;

    string constant private _RADIUS_TAG = '<RADIUS>';
    string constant private _HUE1_TAG = '<HUE1>';
    string constant private _SATURATION1_TAG = '<SATURATION1>';
    string constant private _LIGHTNESS1_TAG = '<LIGHTNESS1>';
    string constant private _HUE2_TAG = '<HUE2>';
    string constant private _SATURATION2_TAG = '<SATURATION2>';
    string constant private _LIGHTNESS2_TAG = '<LIGHTNESS2>';

    string[] private _imageParts;

    constructor(address creator) ERC721SingleCreatorExtension(creator) {
        _imageParts.push("data:image/svg+xml;utf8,");
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='fade' width='1000' height='1000' viewBox='-0.5 -0.5 1 1'>");
            _imageParts.push("<defs><linearGradient id='g' x1='0%' x2='0%' y1='1%' y2='100%'><stop offset='0%' stop-color='hsl(");
                _imageParts.push(_HUE1_TAG);
                _imageParts.push(",");
                _imageParts.push(_SATURATION1_TAG);
                _imageParts.push("%,");
                _imageParts.push(_LIGHTNESS1_TAG);
                _imageParts.push("%)' /><stop offset='50%' stop-color='hsl(");
                _imageParts.push(_HUE2_TAG);
                _imageParts.push(",");
                _imageParts.push(_SATURATION2_TAG);
                _imageParts.push("%,");
                _imageParts.push(_LIGHTNESS2_TAG);
            _imageParts.push("%)' /><stop offset='100%' stop-color='hsl(0,0%,15%)' /></linearGradient></defs>");
            _imageParts.push("<g><rect x='-0.5' y='-0.5' width='1' height='1' fill='hsl(0,0%,15%)' /><circle cx='0' cy='0' r='");
                _imageParts.push(_RADIUS_TAG);
            _imageParts.push("' fill='url(#g)'><animateTransform attributeName='transform' type='rotate' from='0' to='360' dur='60s' repeatCount='indefinite' /></circle></g>");
        _imageParts.push("</svg>");

        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId 
        || interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function mint(address to) external onlyOwner {
        IERC721CreatorCore(_creator).mintExtension(to);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        int128 completion = 1;
        if (_completionTimestamp > block.timestamp) {
            completion = ABDKMath64x64.divu(_completionTimestamp-block.timestamp, 31536000);
        }
        int128 distance = completion.pow(3).mul(ABDKMath64x64.div(48, 100)).add(ABDKMath64x64.div(2, 100))+1;

        //x^y = 2^(y*log_2(x))
        int128 c1curve = ABDKMath64x64.exp_2(ABDKMath64x64.div(75,100).mul(ABDKMath64x64.log_2(completion)));
        int128 c2curve = ABDKMath64x64.exp_2(ABDKMath64x64.div(125,100).mul(ABDKMath64x64.log_2(completion)));
        int128 w1value = ABDKMath64x64.fromUInt(uint256(uint160(IERC721(creator).ownerOf(tokenId)) & 0xFF)).div(ABDKMath64x64.fromUInt(255));
        int128 w2value = ABDKMath64x64.fromUInt(uint256((uint160(IERC721(creator).ownerOf(tokenId)) >> 8) & 0xFF)).div(ABDKMath64x64.fromUInt(255));

        int128 randHue = ABDKMath64x64.mul(w1value, ABDKMath64x64.fromUInt(360));
        int128 randOffset = ABDKMath64x64.mul(w2value, ABDKMath64x64.fromUInt(180)).add(ABDKMath64x64.fromUInt(360)).sub(ABDKMath64x64.fromUInt(90));

        return string(abi.encodePacked('data:application/json;utf8,{"name":"Dynamic", "description":"Days passed: ',((block.timestamp-_creationTimestamp)/86400).toString(),'", "image":"',
            _generateImage(distance, completion, c1curve, c2curve, randHue, randOffset),
            '"}'));
    }

    function updateImageParts(string[] memory imageParts) public onlyOwner {
        _imageParts = imageParts;
    }

    function _generateImage(int128 distance, int128 completion, int128 c1curve, int128 c2curve, int128 randHue, int128 randOffset) private view returns (string memory radius) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _RADIUS_TAG)) {
                byteString = abi.encodePacked(byteString, _radiusString(distance));
            } else if (_checkTag(_imageParts[i], _HUE1_TAG)) {
                byteString = abi.encodePacked(byteString, _hue1string(completion, randHue));
            } else if (_checkTag(_imageParts[i], _SATURATION1_TAG)) {
                byteString = abi.encodePacked(byteString, _saturation1String(c1curve));
            } else if (_checkTag(_imageParts[i], _LIGHTNESS1_TAG)) {
                byteString = abi.encodePacked(byteString, _lightness1String(c1curve));
            } else if (_checkTag(_imageParts[i], _HUE2_TAG)) {
                byteString = abi.encodePacked(byteString, _hue2string(completion, randHue, randOffset));
            } else if (_checkTag(_imageParts[i], _SATURATION2_TAG)) {
                byteString = abi.encodePacked(byteString, _saturation2String(c2curve));
            } else if (_checkTag(_imageParts[i], _LIGHTNESS2_TAG)) {
                byteString = abi.encodePacked(byteString, _lightness2String(c2curve));
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _radiusString(int128 distance) private pure returns (string memory) {
        return _floatToString(distance);
    }

    function _hue1string(int128 completion, int128 randHue) private pure returns (string memory) {
        int128 hueValue = randHue.add(completion.mul(ABDKMath64x64.fromUInt(60)));
        uint256 decimal4 = (hueValue & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(_toString(hueValue.toInt() % 360), '.', _decimal4ToString(decimal4)));
    }

    function _saturation1String(int128 c1curve) private pure returns (string memory) {
        return _floatToString(c1curve.mul(ABDKMath64x64.fromUInt(100)));
    }

    function _lightness1String(int128 c1curve) private pure returns (string memory) {
        return _floatToString(c1curve.mul(ABDKMath64x64.fromUInt(70))+ABDKMath64x64.fromUInt(15));
    }

    function _hue2string(int128 completion, int128 randHue, int128 randOffset) private pure returns (string memory) {
        int128 hueValue = randHue.add(completion.mul(ABDKMath64x64.fromUInt(60)).add(randOffset));
        uint256 decimal4 = (hueValue & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(_toString(hueValue.toInt() % 360), '.', _decimal4ToString(decimal4)));
    }

    function _saturation2String(int128 c2curve) private pure returns (string memory) {
        return _floatToString(c2curve.mul(ABDKMath64x64.fromUInt(50)));
    }

    function _lightness2String(int128 c2curve) private pure returns (string memory) {
        return _floatToString(c2curve.mul(ABDKMath64x64.fromUInt(35))+ABDKMath64x64.fromUInt(15));
    }

    function _toString(int128 value) private pure returns (string memory) {
        return uint256(int256(value)).toString();
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(uint256(int256(value.toInt())).toString(), '.', _decimal4ToString(decimal4)));
    }

    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }
    
    function setApproveTransfer(address creator, bool enabled) public override onlyOwner {
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    function approveTransfer(address, address, uint256) public override returns (bool) {
        require(msg.sender == _creator, "Invalid requester");
        _creationTimestamp = block.timestamp;
        _completionTimestamp = block.timestamp+31536000;        
        return true;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./DynamicArweaveHash.sol";

/**
 * A token that changes with time
 */
contract TimeToken is DynamicArweaveHash {

    // The image cycle cadence
    uint256 private _cadence;
    // The token name
    string private _name;
    // The token description
    string private _description;
    // Token creation timestamp (used to calculate cycle)
    uint256 private _creationTimestamp;
    // Minted token id
    uint256 private _tokenId;

    constructor(address creator, string memory name, string memory description, uint256 cadence) ERC721SingleCreatorExtension(creator) {
        _creationTimestamp = block.timestamp;
        _cadence = cadence;
        _name = name;
        _description = description;
    }

    function mint(address to) public virtual onlyOwner returns(uint256) {
        require(_tokenId == 0, "Already minted");
        _tokenId = _mint(to);
        return _tokenId;
    }

    function _getName() internal view virtual override returns(string memory) {
        return _name;
    }

    function _getDescription() internal view virtual override returns(string memory) {
        return _description;
    }

    function _getImageHash(uint256) internal view override returns(string memory) {
        return imageArweaveHashes[(block.timestamp - _creationTimestamp)/_cadence % imageArweaveHashes.length];
    }

    function _getAnimationHash(uint256) internal view override returns(string memory) {
        return animationArweaveHashes[(block.timestamp - _creationTimestamp)/_cadence % animationArweaveHashes.length];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "../libraries/single-creator/ERC721/ERC721SingleCreatorExtensionBase.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721Edition.sol";

/**
 * ERC721 Edition Base Implementation
 */
abstract contract ERC721EditionBase is ERC721SingleCreatorExtensionBase, CreatorExtension, ICreatorExtensionTokenURI, IERC721Edition, ReentrancyGuard {
    using Strings for uint256;

    struct IndexRange {
        uint256 startIndex;
        uint256 count;
    }

    uint256 internal _maxSupply;
    uint256 internal _totalSupply;
    IndexRange[] private _indexRanges;
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IERC721Edition).interfaceId || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev Initialize the edition contract
     */
    function _initialize(address creator, uint256 maxSupply_) internal {
        require(_creator == address(0), "Already initialized");
        super._setCreator(creator);
        _maxSupply = maxSupply_;
    }

    /**
     * @dev Mint tokens to a single recipient
     */
    function _mint(address recipient, uint16 count) internal nonReentrant {
        require(count > 0, "Invalid amount requested");
        require(_totalSupply+count <= _maxSupply, "Too many requested");
        
        uint256[] memory tokenIds = IERC721CreatorCore(_creator).mintExtensionBatch(recipient, count);
        _updateIndexRanges(tokenIds[0], count);
    }

    /**
     * @dev Mint tokens to a set of recipients
     */
    function _mint(address[] calldata recipients) internal nonReentrant {
        require(recipients.length > 0, "Invalid amount requested");
        require(_totalSupply+recipients.length <= _maxSupply, "Too many requested");
        
        uint256 startIndex = IERC721CreatorCore(_creator).mintExtension(recipients[0]);
        for (uint256 i = 1; i < recipients.length; i++) {
            IERC721CreatorCore(_creator).mintExtension(recipients[i]);
        }
        _updateIndexRanges(startIndex, recipients.length);
    }

    /**
     * @dev Update the index ranges, which is used to figure out the index from a tokenId
     */
    function _updateIndexRanges(uint256 startIndex, uint256 count) internal {
        if (_indexRanges.length == 0) {
           _indexRanges.push(IndexRange(startIndex, count));
        } else {
          IndexRange storage lastIndexRange = _indexRanges[_indexRanges.length-1];
          if ((lastIndexRange.startIndex + lastIndexRange.count) == startIndex) {
             lastIndexRange.count += count;
          } else {
            _indexRanges.push(IndexRange(startIndex, count));
          }
        }
        _totalSupply += count;
    }

    /**
     * @dev Index from tokenId
     */
    function _tokenIndex(address creator, uint256 tokenId) internal view returns(uint256) {
        require(creator == _creator, "Invalid token");
        
        uint256 offset;
        for (uint i = 0; i < _indexRanges.length; i++) {
            IndexRange memory currentIndex = _indexRanges[i];
            if (tokenId < currentIndex.startIndex) break;
            if (tokenId >= currentIndex.startIndex && tokenId < currentIndex.startIndex + currentIndex.count) {
               return tokenId - currentIndex.startIndex + offset;
            }
            offset += currentIndex.count;
        }
        revert("Invalid token");
    }

    /**
     * @dev See {IERC721Edition-totalSupply}.
     */
    function totalSupply() external view override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Edition-maxSupply}.
     */
    function maxSupply() external view override returns(uint256) {
        return _maxSupply;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./IERC721NumberedEdition.sol";
import "./ERC721NumberedEditionBase.sol";

/**
 * ERC721 Edition Contract
 */
contract ERC721NumberedEdition is ERC721NumberedEditionBase, AdminControl {

    constructor(address creator, uint256 maxSupply_, string[] memory uriParts) {
        _initialize(creator, maxSupply_, uriParts);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721NumberedEditionBase, AdminControl) returns (bool) {
        return ERC721NumberedEditionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721NumberedEdition-updateURIParts}.
     */
    function updateURIParts(string[] calldata uriParts) external override adminRequired {
        _updateURIParts(uriParts);
    }

    /**
     * @dev See {IERC721NumberedEdition-mint}.
     */
    function mint(address recipient, uint16 count) external override adminRequired {
        _mint(recipient, count);
    }

    /**
     * @dev See {IERC721NumberedEdition-mint}.
     */
    function mint(address[] calldata recipients) external override adminRequired {
        _mint(recipients);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "../libraries/single-creator/ERC721/ERC721SingleCreatorExtensionBase.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721NumberedEdition.sol";
import "./ERC721EditionBase.sol";

/**
 * ERC721 Numbered Edition Base Implementation
 */
abstract contract ERC721NumberedEditionBase is ERC721EditionBase, IERC721NumberedEdition {
    using Strings for uint256;

    string constant internal _EDITION_TAG = '<EDITION>';
    string constant internal _TOTAL_TAG = '<TOTAL>';    
    string constant internal _MAX_TAG = '<MAX>'; 
    string[] private _uriParts;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EditionBase) returns (bool) {
        return interfaceId == type(IERC721NumberedEdition).interfaceId || ERC721EditionBase.supportsInterface(interfaceId);
    }

    /**
     * @dev Initialize the Open Edition contract
     */
    function _initialize(address creator, uint256 maxSupply_, string[] memory uriParts) internal {
        require(_creator == address(0), "Already initialized");
        super._initialize(creator, maxSupply_);
        _uriParts = uriParts;
    }

    /**
     * @dev Update the URI data
     */
    function _updateURIParts(string[] memory uriParts) internal {
        _uriParts = uriParts;
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        return _generateURI(_tokenIndex(creator, tokenId));
    }

    function _generateURI(uint256 tokenIndex) private view returns(string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _uriParts.length; i++) {
            if (_checkTag(_uriParts[i], _EDITION_TAG)) {
                byteString = abi.encodePacked(byteString, (tokenIndex+1).toString());
            } else if (_checkTag(_uriParts[i], _TOTAL_TAG)) {
                byteString = abi.encodePacked(byteString, _totalSupply.toString());
            } else if (_checkTag(_uriParts[i], _MAX_TAG)) {
                byteString = abi.encodePacked(byteString, _maxSupply.toString());
            } else {
                byteString = abi.encodePacked(byteString, _uriParts[i]);
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";

import "./ERC721NumberedEditionBase.sol";

/**
 * ERC721 Numbered Edition Contract Implementation
 */
contract ERC721NumberedEditionImplementation is ERC721NumberedEditionBase, AdminControlUpgradeable {

    function initialize(address creator, uint256 maxSupply_, string[] memory uriParts) public initializer {
        __Ownable_init();
        _initialize(creator, maxSupply_, uriParts);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721NumberedEditionBase, AdminControlUpgradeable) returns (bool) {
        return ERC721NumberedEditionBase.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Edition-updateURIParts}.
     */
    function updateURIParts(string[] calldata uriParts) external override adminRequired {
        _updateURIParts(uriParts);
    }

    /**
     * @dev See {IERC721Edition-mint}.
     */
    function mint(address recipient, uint16 count) external override adminRequired {
        _mint(recipient, count);
    }

    /**
     * @dev See {IERC721Edition-mint}.
     */
    function mint(address[] calldata recipients) external override adminRequired {
        _mint(recipients);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 
/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721NumberedEditionTemplate is Proxy {
    
    constructor(address editionImplementation, address creator, uint256 maxSupply) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = editionImplementation;

        // Insert your uri data here
        string[] memory uriParts = new string[](10);
        uriParts[0] = 'data:application/json;utf8,{"name":"Template Edition #';
        uriParts[1] = '<EDITION>';
        uriParts[2] = '/';
        uriParts[3] = '<TOTAL>';
        uriParts[4] = ', "description":"Template Description",';
        uriParts[5] = '"attributes":[{"display_type":"number","trait_type":"Edition","value":';
        uriParts[6] = '<EDITION>';
        uriParts[7] = ',"max_value":';
        uriParts[8] = '<TOTAL>';
        uriParts[9] = '}]}';

        Address.functionDelegateCall(
            editionImplementation,
            abi.encodeWithSignature("initialize(address,uint256,string[])", creator, maxSupply, uriParts)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./IERC721PrefixEdition.sol";
import "./ERC721PrefixEditionBase.sol";

/**
 * ERC721 Edition Contract
 */
contract ERC721PrefixEdition is ERC721PrefixEditionBase, AdminControl {

    constructor(address creator, uint256 maxSupply_, string memory prefix) {
        _initialize(creator, maxSupply_, prefix);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721PrefixEditionBase, AdminControl) returns (bool) {
        return ERC721PrefixEditionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721PrefixEdition-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IERC721PrefixEdition-mint}.
     */
    function mint(address recipient, uint16 count) external override adminRequired {
        _mint(recipient, count);
    }

    /**
     * @dev See {IERC721PrefixEdition-mint}.
     */
    function mint(address[] calldata recipients) external override adminRequired {
        _mint(recipients);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "../libraries/single-creator/ERC721/ERC721SingleCreatorExtensionBase.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721PrefixEdition.sol";
import "./ERC721EditionBase.sol";

/**
 * ERC721 Prefix Edition Base Implementation
 */
abstract contract ERC721PrefixEditionBase is ERC721EditionBase, IERC721PrefixEdition {
    using Strings for uint256;

    string private _tokenPrefix;
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721EditionBase) returns (bool) {
        return interfaceId == type(IERC721PrefixEdition).interfaceId || ERC721EditionBase.supportsInterface(interfaceId);
    }

    /**
     * @dev Initialize the Open Edition contract
     */
    function _initialize(address creator, uint256 maxSupply_, string memory prefix) internal {
        require(_creator == address(0), "Already initialized");
        super._initialize(creator, maxSupply_);
        _tokenPrefix = prefix;
    }

    /**
     * Set the token URI prefix
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _tokenPrefix = prefix;
    }
    
    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_tokenPrefix, (_tokenIndex(creator, tokenId)+1).toString()));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";

import "./ERC721PrefixEditionBase.sol";

/**
 * ERC721 Prefix Edition Contract Implementation
 */
contract ERC721PrefixEditionImplementation is ERC721PrefixEditionBase, AdminControlUpgradeable {

    function initialize(address creator, uint256 maxSupply_, string memory prefix) public initializer {
        __Ownable_init();
        _initialize(creator, maxSupply_, prefix);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721PrefixEditionBase, AdminControlUpgradeable) returns (bool) {
        return ERC721PrefixEditionBase.supportsInterface(interfaceId) || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721PrefixEdition-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IERC721Edition-mint}.
     */
    function mint(address recipient, uint16 count) external override adminRequired {
        _mint(recipient, count);
    }

    /**
     * @dev See {IERC721Edition-mint}.
     */
    function mint(address[] calldata recipients) external override adminRequired {
        _mint(recipients);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 
/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721PrefixEditionTemplate is Proxy {
    
    constructor(address editionImplementation, address creator, uint256 maxSupply, string memory prefix) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = editionImplementation;

        Address.functionDelegateCall(
            editionImplementation,
            abi.encodeWithSignature("initialize(address,uint256,string)", creator, maxSupply, prefix)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * ERC721 Edition interface
 */
interface IERC721Edition {

    /**
     * @dev Mint NFTs to a single recipient
     */
    function mint(address recipient, uint16 count) external;

    /**
     * @dev Mint NFTS to the recipients
     */
    function mint(address[] calldata recipients) external;

    /**
     * @dev Total supply of editions
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev Max supply of editions
     */
    function maxSupply() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721Edition.sol";

/**
 * ERC721 Numbered Edition interface
 */
interface IERC721NumberedEdition is IERC721Edition {

    /**
     * @dev Update the URI parts used to construct the metadata for the open edition
     */
    function updateURIParts(string[] calldata uriParts) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721Edition.sol";

/**
 * ERC721 Prefix Edition interface
 */
interface IERC721PrefixEdition is IERC721Edition {

    /**
     * @dev Set the token uri prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Nifty Gateway ERC721 Numbered Edition interface
 */
interface INiftyGatewayERC721NumberedEdition {

    /**
     * @dev Activate for nifty
     */
    function activate(address[] calldata minters, address niftyOmnibusWallet) external;

    /**
     * @dev Mint NFTs to nifty gateway
     */
    function mintNifty(uint256 niftyType, uint16 count) external;

    /**
     * @dev Mint count (used by nifty gateway)
     */
    function _mintCount(uint256 niftyType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./INiftyGatewayERC721NumberedEdition.sol";
import "../ERC721NumberedEditionBase.sol";

/**
 * Nifty Gateway ERC721 Numbered Edition Contract Implementation
 */
contract NiftyGatewayERC721NumberedEditionImplementation is ERC721NumberedEditionBase, AdminControlUpgradeable, INiftyGatewayERC721NumberedEdition {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _minters;
    address private _niftyOmnibusWallet;

    function initialize(address creator, uint256 maxSupply_, string[] memory uriParts) public initializer {
        __Ownable_init();
        _initialize(creator, maxSupply_, uriParts);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControlUpgradeable, ERC721NumberedEditionBase) returns (bool) {
        return interfaceId == type(INiftyGatewayERC721NumberedEdition).interfaceId || AdminControlUpgradeable.supportsInterface(interfaceId) || ERC721NumberedEditionBase.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721NumberedEdition-activate}.
     */
    function activate(address[] calldata minters, address niftyOmnibusWallet) external override adminRequired {
        for (uint i = 0; i < minters.length; i++) {
            _minters.add(minters[i]);
        }
        _niftyOmnibusWallet = niftyOmnibusWallet;
    }

    /**
     * @dev See {IERC721NumberedEdition-updateURIParts}.
     */
    function updateURIParts(string[] calldata uriParts) external override adminRequired {
        _updateURIParts(uriParts);
    }

    /**
     * @dev See {IERC721NumberedEdition-mint}.
     */
    function mint(address recipient, uint16 count) external override adminRequired {
        _mint(recipient, count);
    }

    /**
     * @dev See {IERC721NumberedEdition-mint}.
     */
    function mint(address[] calldata recipients) external override adminRequired {
        _mint(recipients);
    }

    /**
     * @dev See {INiftyGatewayERC721NumberedEdition-mintNifty}.
     */
    function mintNifty(uint256 niftyType, uint16 count) external override {
        require(_minters.contains(msg.sender), "Unauthorized");
        require(niftyType == 1, "Only supported niftyType is 1");
        _mint(_niftyOmnibusWallet, uint16(count));
    }

    /**
     * @dev See {INiftyGatewayERC721NumberedEdition-_mintCount}.
     */
    function _mintCount(uint256 niftyType) external view override returns (uint256) {
        require(niftyType == 1, "Only supported niftyType is 1");
        return _totalSupply;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC721/ERC721CreatorExtensionApproveTransfer.sol";

/**
 * Provide token enumeration functionality
 *
 * IMPORTANT: You must call _activate for each creator contract you want enumeration to work for
 */
abstract contract ERC721OwnerEnumerableExtension is ERC721CreatorExtensionApproveTransfer {

    mapping (address => mapping(address => uint256)) private _creatorOwnerBalance;
    mapping (address => mapping(address => mapping(uint256 => uint256))) private _creatorTokensByOwner;
    mapping (address => mapping(uint256 => uint256)) private _creatorTokensIndex;

    /**
     * @dev must call this to activate enumeration capability
     */
    function _activate(address creator) internal {
        IERC721CreatorCore(creator).setApproveTransferExtension(true);
    }

    /**
     * @dev Get the token for an owner by index (for a given creator contract this extension mints to)
     */
    function tokenOfOwnerByIndex(address creator, address owner, uint256 index) public view virtual returns (uint256) {
        require(index < _creatorOwnerBalance[creator][owner], "ERC721Enumerable: owner index out of bounds");
        return _creatorTokensByOwner[creator][owner][index];
    }

    /**
     * @dev Get the balance for the owner for this extension (for a given creator contract this extension mints to)
     */
    function balanceOf(address creator, address owner) public view virtual returns(uint256) {
        return _creatorOwnerBalance[creator][owner];
    }

    function approveTransfer(address from, address to, uint256 tokenId) external override returns (bool) {
        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        return true;
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _creatorOwnerBalance[msg.sender][to];
        _creatorTokensByOwner[msg.sender][to][length] = tokenId;
        _creatorTokensIndex[msg.sender][tokenId] = length;
        _creatorOwnerBalance[msg.sender][to] += 1;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _creatorOwnerBalance[msg.sender][from] - 1;
        uint256 tokenIndex = _creatorTokensIndex[msg.sender][tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _creatorTokensByOwner[msg.sender][from][lastTokenIndex];

            _creatorTokensByOwner[msg.sender][from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _creatorTokensIndex[msg.sender][lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _creatorTokensIndex[msg.sender][tokenId];
        delete _creatorTokensByOwner[msg.sender][from][lastTokenIndex];
        _creatorOwnerBalance[msg.sender][from] -= 1;        
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC721/ERC721CreatorExtensionApproveTransfer.sol";

import "../../libraries/single-creator/ERC721/ERC721SingleCreatorExtension.sol";
import "../../libraries/single-creator/ERC721/ERC721SingleCreatorExtensionBase.sol";

/**
 * Provide token enumeration functionality (Base Class. Use if you are using multiple inheritance where other contracts
 * already derive from either ERC721SingleCreatorExtension or ERC1155SingleCreatorExtension).
 *
 * IMPORTANT: You must call _activate in order for enumeration to work
 */
abstract contract ERC721OwnerEnumerableSingleCreatorBase is ERC721SingleCreatorExtensionBase, ERC721CreatorExtensionApproveTransfer {

    mapping(address => uint256) private _ownerBalance;
    mapping(address => mapping(uint256 => uint256)) private _tokensByOwner;
    mapping(uint256 => uint256) private _tokensIndex;

    /**
     * @dev must call this to activate enumeration capability
     */
    function _activate() internal {
        IERC721CreatorCore(_creator).setApproveTransferExtension(true);
    }

    /**
     * @dev Get the token for an owner by index
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < _ownerBalance[owner], "ERC721Enumerable: owner index out of bounds");
        return _tokensByOwner[owner][index];
    }

    /**
     * @dev Get the balance for the owner for this extension
     */
    function balanceOf(address owner) public view virtual returns(uint256) {
        return _ownerBalance[owner];
    }

    function approveTransfer(address from, address to, uint256 tokenId) external override returns (bool) {
        require(msg.sender == _creator, "Invalid caller");
        if (from != address(0) && from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0) && to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        return true;
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _ownerBalance[to];
        _tokensByOwner[to][length] = tokenId;
        _tokensIndex[tokenId] = length;
        _ownerBalance[to] += 1;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownerBalance[from] - 1;
        uint256 tokenIndex = _tokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _tokensByOwner[from][lastTokenIndex];

            _tokensByOwner[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _tokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _tokensIndex[tokenId];
        delete _tokensByOwner[from][lastTokenIndex];
        _ownerBalance[from] -= 1;        
    }

}

/**
 * Provide token enumeration functionality (Extension)
 *
 * IMPORTANT: You must call _activate in order for enumeration to work
 */
abstract contract ERC721OwnerEnumerableSingleCreatorExtension is ERC721OwnerEnumerableSingleCreatorBase, ERC721SingleCreatorExtension {
    constructor(address creator) ERC721SingleCreatorExtension(creator) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Font interface
 */
interface IFontWOFF {
    function woff() external view returns(string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./ERC721LazyMintWhitelistBase.sol";
import "./IERC721LazyMintWhitelist.sol";

/**
 * Lazy Mint with Whitelist for ERC721 tokens
 */
contract ERC721LazyMintWhitelist is ERC721LazyMintWhitelistBase, AdminControl, IERC721LazyMintWhitelist {

    constructor(address creator, string memory prefix) {
        _initialize(creator, prefix);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721LazyMintWhitelistBase) returns (bool) {
        return interfaceId == type(IERC721LazyMintWhitelist).interfaceId || AdminControl.supportsInterface(interfaceId) || ERC721LazyMintWhitelistBase.supportsInterface(interfaceId);
    }

    function premint(address[] memory to) external override adminRequired {
        _premint(to);
    }

    function mint(bytes32[] memory merkleProof) external override payable {
        _mint(merkleProof);
    }

    function setAllowList(bytes32 _merkleRoot) external override adminRequired {
        _setAllowList(_merkleRoot);
    }

    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    function withdraw(address _to, uint amount) external override adminRequired {
        _withdraw(_to, amount);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../libraries/ABDKMath64x64.sol";
import "../libraries/single-creator/ERC721/ERC721SingleCreatorExtensionBase.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * Lazy mint with whitelist ERC721 tokens
 */
abstract contract ERC721LazyMintWhitelistBase is ERC721SingleCreatorExtensionBase, ICreatorExtensionTokenURI, ReentrancyGuard {
    using Strings for uint256;
    using ABDKMath64x64 for uint;

    string private _tokenPrefix;
    uint256 public _tokensMinted;
    mapping(uint256 => uint256) private _tokenEdition;
    uint private MINT_PRICE = 0.1 ether; // to be changed
    uint private MAX_MINTS = 50; // to be changed
    bytes32 merkleRoot;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId;
    }

    function _initialize(address creator, string memory prefix) internal {
      require(_creator == address(0), "Already initialized");
      _setCreator(creator);
      _tokenPrefix = prefix;
    }

    function onAllowList(address claimer, bytes32[] memory proof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _setAllowList(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Mint token if you are on the whitelist
     */
    function _premint(address[] memory to) internal {
        for (uint i = 0; i < to.length; i++) {
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(to[i])] = _tokensMinted + i + 1;
        }
        _tokensMinted += to.length;
        MAX_MINTS += to.length; // Extend max mints when preminting
    }
    
    /**
     * @dev Mint token if you are on the whitelist
     */
    function _mint(bytes32[] memory merkleProof) internal {
        require(_tokensMinted < MAX_MINTS, "Not enough mints left");
        require(MINT_PRICE == msg.value, "Not enough ETH");
        require(onAllowList(msg.sender, merkleProof), "Not on allowlist");

        _tokenEdition[IERC721CreatorCore(_creator).mintExtension(msg.sender)] = _tokensMinted + 1;
        _tokensMinted += 1;
    }

    /**
     * Set the token URI prefix
     */
    function _setTokenURIPrefix(string calldata prefix) internal {
        _tokenPrefix = prefix;
    }

    function _withdraw(address _to, uint amount) internal {
        payable(_to).transfer(amount);
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return  string(abi.encodePacked(_tokenPrefix, _tokenEdition[tokenId].toString()));
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControlUpgradeable.sol";

import "./ERC721LazyMintWhitelistBase.sol";
import "./IERC721LazyMintWhitelist.sol";

/**
 * Lazy Mint and whitelist ERC721 tokens
 */
contract ERC721LazyMintWhitelistImplementation is ERC721LazyMintWhitelistBase, AdminControlUpgradeable, IERC721LazyMintWhitelist {

    function initialize(address creator, string memory prefix) public initializer {
        __Ownable_init();
        _initialize(creator, prefix);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControlUpgradeable, ERC721LazyMintWhitelistBase) returns (bool) {
        return interfaceId == type(IERC721LazyMintWhitelist).interfaceId || AdminControlUpgradeable.supportsInterface(interfaceId) || ERC721LazyMintWhitelistBase.supportsInterface(interfaceId);
    }

    function premint(address[] memory to) external override adminRequired {
        _premint(to);
    }

    function mint(bytes32[] memory merkleProof) external override payable {
        _mint(merkleProof);
    }

    function setAllowList(bytes32 _merkleRoot) external override adminRequired {
        _setAllowList(_merkleRoot);
    }

    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    function withdraw(address _to, uint amount) external override adminRequired {
        _withdraw(_to, amount);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 
/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721LazyMintWhitelistTemplate is Proxy {
    
    constructor(address lazyMintWhitelistImplementation, address creator, string memory prefix) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = lazyMintWhitelistImplementation;

        Address.functionDelegateCall(
            lazyMintWhitelistImplementation,
            abi.encodeWithSignature("initialize(address,string)", creator, prefix)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * ERC721 Lazy Mint with Whitelist interface
 */
interface IERC721LazyMintWhitelist {

    /**
     * @dev premints gifted nfts
     */
    function premint(address[] memory to) external;
    

    /**
     * @dev external mint function 
     */
    function mint(bytes32[] memory merkleProof) external payable;

    /**
     * @dev sets the allowList
     */
    function setAllowList(bytes32 _merkleRoot) external;

    /**
     * @dev Set the token uri prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev Withdraw funds from the contract
     */
    function withdraw(address _to, uint amount) external;
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import {IDelegationRegistry} from "./IDelegationRegistry.sol";
/**
 * @notice code taken from https://github.com/0xfoobar/delegation-registry
 * following 2 lines modified by jack ([email protected]) to make openzeppelin imports work
 */
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title DelegationRegistry
 * @custom:version 1.0
 * @notice An immutable registry contract to be deployed as a standalone primitive.
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow.
 * @custom:coauthor foobar (0xfoobar)
 * @custom:coauthor wwchung (manifoldxyz)
 * @custom:coauthor purplehat (artblocks)
 * @custom:coauthor ryley-o (artblocks)
 * @custom:coauthor andy8052 (tessera)
 * @custom:coauthor punk6529 (open metaverse)
 * @custom:coauthor loopify (loopiverse)
 * @custom:coauthor emiliano (nftrentals)
 * @custom:coauthor arran (proof)
 * @custom:coauthor james (collabland)
 * @custom:coauthor john (gnosis safe)
 * @custom:coauthor 0xrusowsky
 */
contract DelegationRegistry is IDelegationRegistry, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice The global mapping and single source of truth for delegations
    /// @dev vault -> vaultVersion -> delegationHash
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) internal delegations;

    /// @notice A mapping of wallets to versions (for cheap revocation)
    mapping(address => uint256) internal vaultVersion;

    /// @notice A mapping of wallets to delegates to versions (for cheap revocation)
    mapping(address => mapping(address => uint256)) internal delegateVersion;

    /// @notice A secondary mapping to return onchain enumerability of delegations that a given address can perform
    /// @dev delegate -> delegationHashes
    mapping(address => EnumerableSet.Bytes32Set) internal delegationHashes;

    /// @notice A secondary mapping used to return delegation information about a delegation
    /// @dev delegationHash -> DelegateInfo
    mapping(bytes32 => IDelegationRegistry.DelegationInfo) internal delegationInfo;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165) returns (bool) {
        return interfaceId == type(IDelegationRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * -----------  WRITE -----------
     */

    /**
     * @inheritdoc IDelegationRegistry
     */
    function delegateForAll(address delegate, bool value) external override {
        bytes32 delegationHash = _computeAllDelegationHash(msg.sender, delegate);
        _setDelegationValues(
            delegate, delegationHash, value, IDelegationRegistry.DelegationType.ALL, msg.sender, address(0), 0
        );
        emit IDelegationRegistry.DelegateForAll(msg.sender, delegate, value);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function delegateForContract(address delegate, address contract_, bool value) external override {
        bytes32 delegationHash = _computeContractDelegationHash(msg.sender, delegate, contract_);
        _setDelegationValues(
            delegate, delegationHash, value, IDelegationRegistry.DelegationType.CONTRACT, msg.sender, contract_, 0
        );
        emit IDelegationRegistry.DelegateForContract(msg.sender, delegate, contract_, value);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external override {
        bytes32 delegationHash = _computeTokenDelegationHash(msg.sender, delegate, contract_, tokenId);
        _setDelegationValues(
            delegate, delegationHash, value, IDelegationRegistry.DelegationType.TOKEN, msg.sender, contract_, tokenId
        );
        emit IDelegationRegistry.DelegateForToken(msg.sender, delegate, contract_, tokenId, value);
    }

    /**
     * @dev Helper function to set all delegation values and enumeration sets
     */
    function _setDelegationValues(
        address delegate,
        bytes32 delegateHash,
        bool value,
        IDelegationRegistry.DelegationType type_,
        address vault,
        address contract_,
        uint256 tokenId
    ) internal {
        if (value) {
            delegations[vault][vaultVersion[vault]].add(delegateHash);
            delegationHashes[delegate].add(delegateHash);
            delegationInfo[delegateHash] =
                DelegationInfo({vault: vault, delegate: delegate, type_: type_, contract_: contract_, tokenId: tokenId});
        } else {
            delegations[vault][vaultVersion[vault]].remove(delegateHash);
            delegationHashes[delegate].remove(delegateHash);
            delete delegationInfo[delegateHash];
        }
    }

    /**
     * @dev Helper function to compute delegation hash for wallet delegation
     */
    function _computeAllDelegationHash(address vault, address delegate) internal view returns (bytes32) {
        uint256 vaultVersion_ = vaultVersion[vault];
        uint256 delegateVersion_ = delegateVersion[vault][delegate];
        return keccak256(abi.encode(delegate, vault, vaultVersion_, delegateVersion_));
    }

    /**
     * @dev Helper function to compute delegation hash for contract delegation
     */
    function _computeContractDelegationHash(address vault, address delegate, address contract_)
        internal
        view
        returns (bytes32)
    {
        uint256 vaultVersion_ = vaultVersion[vault];
        uint256 delegateVersion_ = delegateVersion[vault][delegate];
        return keccak256(abi.encode(delegate, vault, contract_, vaultVersion_, delegateVersion_));
    }

    /**
     * @dev Helper function to compute delegation hash for token delegation
     */
    function _computeTokenDelegationHash(address vault, address delegate, address contract_, uint256 tokenId)
        internal
        view
        returns (bytes32)
    {
        uint256 vaultVersion_ = vaultVersion[vault];
        uint256 delegateVersion_ = delegateVersion[vault][delegate];
        return keccak256(abi.encode(delegate, vault, contract_, tokenId, vaultVersion_, delegateVersion_));
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function revokeAllDelegates() external override {
        ++vaultVersion[msg.sender];
        emit IDelegationRegistry.RevokeAllDelegates(msg.sender);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function revokeDelegate(address delegate) external override {
        _revokeDelegate(delegate, msg.sender);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function revokeSelf(address vault) external override {
        _revokeDelegate(msg.sender, vault);
    }

    /**
     * @dev Revoke the `delegate` hotwallet from the `vault` coldwallet.
     */
    function _revokeDelegate(address delegate, address vault) internal {
        ++delegateVersion[vault][delegate];
        // For enumerations, filter in the view functions
        emit IDelegationRegistry.RevokeDelegate(vault, msg.sender);
    }

    /**
     * -----------  READ -----------
     */

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegationsByDelegate(address delegate)
        external
        view
        returns (IDelegationRegistry.DelegationInfo[] memory info)
    {
        EnumerableSet.Bytes32Set storage potentialDelegationHashes = delegationHashes[delegate];
        uint256 potentialDelegationHashesLength = potentialDelegationHashes.length();
        uint256 delegationCount = 0;
        info = new IDelegationRegistry.DelegationInfo[](potentialDelegationHashesLength);
        for (uint256 i = 0; i < potentialDelegationHashesLength;) {
            bytes32 delegateHash = potentialDelegationHashes.at(i);
            IDelegationRegistry.DelegationInfo memory delegationInfo_ = delegationInfo[delegateHash];
            address vault = delegationInfo_.vault;
            IDelegationRegistry.DelegationType type_ = delegationInfo_.type_;
            bool valid = false;
            if (type_ == IDelegationRegistry.DelegationType.ALL) {
                if (delegateHash == _computeAllDelegationHash(vault, delegate)) {
                    valid = true;
                }
            } else if (type_ == IDelegationRegistry.DelegationType.CONTRACT) {
                if (delegateHash == _computeContractDelegationHash(vault, delegate, delegationInfo_.contract_)) {
                    valid = true;
                }
            } else if (type_ == IDelegationRegistry.DelegationType.TOKEN) {
                if (
                    delegateHash
                        == _computeTokenDelegationHash(vault, delegate, delegationInfo_.contract_, delegationInfo_.tokenId)
                ) {
                    valid = true;
                }
            }
            if (valid) {
                info[delegationCount++] = delegationInfo_;
            }
            unchecked {
                ++i;
            }
        }
        if (potentialDelegationHashesLength > delegationCount) {
            assembly {
                let decrease := sub(potentialDelegationHashesLength, delegationCount)
                mstore(info, sub(mload(info), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory delegates) {
        return _getDelegatesForLevel(vault, IDelegationRegistry.DelegationType.ALL, address(0), 0);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegatesForContract(address vault, address contract_)
        external
        view
        override
        returns (address[] memory delegates)
    {
        return _getDelegatesForLevel(vault, IDelegationRegistry.DelegationType.CONTRACT, contract_, 0);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        override
        returns (address[] memory delegates)
    {
        return _getDelegatesForLevel(vault, IDelegationRegistry.DelegationType.TOKEN, contract_, tokenId);
    }

    function _getDelegatesForLevel(
        address vault,
        IDelegationRegistry.DelegationType delegationType,
        address contract_,
        uint256 tokenId
    ) internal view returns (address[] memory delegates) {
        EnumerableSet.Bytes32Set storage delegationHashes_ = delegations[vault][vaultVersion[vault]];
        uint256 potentialDelegatesLength = delegationHashes_.length();
        uint256 delegatesCount = 0;
        delegates = new address[](potentialDelegatesLength);
        for (uint256 i = 0; i < potentialDelegatesLength;) {
            bytes32 delegationHash = delegationHashes_.at(i);
            DelegationInfo storage delegationInfo_ = delegationInfo[delegationHash];
            if (delegationInfo_.type_ == delegationType) {
                if (delegationType == IDelegationRegistry.DelegationType.ALL) {
                    // check delegate version by validating the hash
                    if (delegationHash == _computeAllDelegationHash(vault, delegationInfo_.delegate)) {
                        delegates[delegatesCount++] = delegationInfo_.delegate;
                    }
                } else if (delegationType == IDelegationRegistry.DelegationType.CONTRACT) {
                    if (delegationInfo_.contract_ == contract_) {
                        // check delegate version by validating the hash
                        if (
                            delegationHash == _computeContractDelegationHash(vault, delegationInfo_.delegate, contract_)
                        ) {
                            delegates[delegatesCount++] = delegationInfo_.delegate;
                        }
                    }
                } else if (delegationType == IDelegationRegistry.DelegationType.TOKEN) {
                    if (delegationInfo_.contract_ == contract_ && delegationInfo_.tokenId == tokenId) {
                        // check delegate version by validating the hash
                        if (
                            delegationHash
                                == _computeTokenDelegationHash(vault, delegationInfo_.delegate, contract_, tokenId)
                        ) {
                            delegates[delegatesCount++] = delegationInfo_.delegate;
                        }
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
        if (potentialDelegatesLength > delegatesCount) {
            assembly {
                let decrease := sub(potentialDelegatesLength, delegatesCount)
                mstore(delegates, sub(mload(delegates), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (IDelegationRegistry.ContractDelegation[] memory contractDelegations)
    {
        EnumerableSet.Bytes32Set storage delegationHashes_ = delegations[vault][vaultVersion[vault]];
        uint256 potentialLength = delegationHashes_.length();
        uint256 delegationCount = 0;
        contractDelegations = new IDelegationRegistry.ContractDelegation[](potentialLength);
        for (uint256 i = 0; i < potentialLength;) {
            bytes32 delegationHash = delegationHashes_.at(i);
            DelegationInfo storage delegationInfo_ = delegationInfo[delegationHash];
            if (delegationInfo_.type_ == IDelegationRegistry.DelegationType.CONTRACT) {
                // check delegate version by validating the hash
                if (
                    delegationHash
                        == _computeContractDelegationHash(vault, delegationInfo_.delegate, delegationInfo_.contract_)
                ) {
                    contractDelegations[delegationCount++] = IDelegationRegistry.ContractDelegation({
                        contract_: delegationInfo_.contract_,
                        delegate: delegationInfo_.delegate
                    });
                }
            }
            unchecked {
                ++i;
            }
        }
        if (potentialLength > delegationCount) {
            assembly {
                let decrease := sub(potentialLength, delegationCount)
                mstore(contractDelegations, sub(mload(contractDelegations), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getTokenLevelDelegations(address vault)
        external
        view
        returns (IDelegationRegistry.TokenDelegation[] memory tokenDelegations)
    {
        EnumerableSet.Bytes32Set storage delegationHashes_ = delegations[vault][vaultVersion[vault]];
        uint256 potentialLength = delegationHashes_.length();
        uint256 delegationCount = 0;
        tokenDelegations = new IDelegationRegistry.TokenDelegation[](potentialLength);
        for (uint256 i = 0; i < potentialLength;) {
            bytes32 delegationHash = delegationHashes_.at(i);
            DelegationInfo storage delegationInfo_ = delegationInfo[delegationHash];
            if (delegationInfo_.type_ == IDelegationRegistry.DelegationType.TOKEN) {
                // check delegate version by validating the hash
                if (
                    delegationHash
                        == _computeTokenDelegationHash(
                            vault, delegationInfo_.delegate, delegationInfo_.contract_, delegationInfo_.tokenId
                        )
                ) {
                    tokenDelegations[delegationCount++] = IDelegationRegistry.TokenDelegation({
                        contract_: delegationInfo_.contract_,
                        tokenId: delegationInfo_.tokenId,
                        delegate: delegationInfo_.delegate
                    });
                }
            }
            unchecked {
                ++i;
            }
        }
        if (potentialLength > delegationCount) {
            assembly {
                let decrease := sub(potentialLength, delegationCount)
                mstore(tokenDelegations, sub(mload(tokenDelegations), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function checkDelegateForAll(address delegate, address vault) public view override returns (bool) {
        bytes32 delegateHash =
            keccak256(abi.encode(delegate, vault, vaultVersion[vault], delegateVersion[vault][delegate]));
        return delegations[vault][vaultVersion[vault]].contains(delegateHash);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        public
        view
        override
        returns (bool)
    {
        bytes32 delegateHash =
            keccak256(abi.encode(delegate, vault, contract_, vaultVersion[vault], delegateVersion[vault][delegate]));
        return delegations[vault][vaultVersion[vault]].contains(delegateHash)
            ? true
            : checkDelegateForAll(delegate, vault);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        bytes32 delegateHash = keccak256(
            abi.encode(delegate, vault, contract_, tokenId, vaultVersion[vault], delegateVersion[vault][delegate])
        );
        return delegations[vault][vaultVersion[vault]].contains(delegateHash)
            ? true
            : checkDelegateForContract(delegate, vault, contract_);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Library of legacy interface constants
 */
library LegacyInterfaces {

    // LEGACY ERC721CreatorCore interface
    bytes4 internal constant IERC721CreatorCore_v1 = 0x478c8530;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC1155SingleCreatorExtensionBase.sol";

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC1155SingleCreatorExtension is ERC1155SingleCreatorExtensionBase {

    constructor(address creator) {
        _setCreator(creator);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";

import "../../LegacyInterfaces.sol";
import "../SingleCreatorExtensionBase.sol";

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC1155SingleCreatorExtensionBase is SingleCreatorExtensionBase {

    function _setCreator(address creator) internal override {
        require(ERC165Checker.supportsInterface(creator, type(IERC1155CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, type(IERC1155CreatorCore).interfaceId ^ type(ICreatorCore).interfaceId), 
                "Creator contract must implement IERC1155CreatorCore");
        super._setCreator(creator);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC721SingleCreatorExtensionBase.sol";

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC721SingleCreatorExtension is ERC721SingleCreatorExtensionBase {

    constructor(address creator) {
        _setCreator(creator);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "../../LegacyInterfaces.sol";
import "../SingleCreatorExtensionBase.sol";

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC721SingleCreatorExtensionBase is SingleCreatorExtensionBase {

    function _setCreator(address creator) internal override {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, LegacyInterfaces.IERC721CreatorCore_v1), 
                "Creator contract must implement IERC721CreatorCore");
        super._setCreator(creator);
    }
  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract SingleCreatorExtensionBase {
    address internal _creator;

    /**
     * @dev Override with appropriate interface checks if necessary
     */
    function _setCreator(address creator) internal virtual {
      _creator = creator;
    }

    function creatorContract() public view returns(address) {
        return _creator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                     .%(#.                                       //
//                                      #(((#%,                                    //
//                                      (#(((((#%*                                 //
//                                      /#((((((((##*                              //
//                                      (#((((((((((##%.                           //
//                                     ,##(/*/(////((((#%*                         //
//                                   .###(//****/////(((##%,                       //
//                  (,          ,%#((((((///******/////((##%(                      //
//                *((,         ,##(///////*********////((###%*                     //
//              /((((         ,##(//////************/(((((###%                     //
//             /((((         ,##((////***************/((((###%                     //
//             (((          .###((///*****************((((####                     //
//             .            (##((//*******************((((##%*                     //
//               (#.       .###((/********************((((##%.      %.             //
//             ,%(#.       .###(/********,,,,,,,*****/(((###%#     ((%,            //
//            /%#/(/       /###(//****,,,,,,,,,,,****/((((((##%%%%#((#%.           //
//           /##(//(#.    ,###((/****,,,,,,,,,,,,,***/((/(((((((((#####%           //
//          *%##(/////((###((((/***,,,,,,,,,,,,,,,***//((((((((((####%%%/          //
//          ####(((//////(//////**,,,,,,.....,,,,,,****/(((((//((####%%%%          //
//         .####(((/((((((/////**,,,,,.......,,,,,,,,*****/////(#####%%%%          //
//         .#%###((////(((//***,,,,,,..........,,,,,,,,*****//((#####%%%%          //
//          /%%%###/////*****,,,,,,,..............,,,,,,,****/(((####%%%%          //
//           /%%###(////****,,,,,,.....        ......,,,,,,**(((####%%%%           //
//            ,#%###(///****,,,,,....            .....,,,,,***/(/(##%%(            //
//              (####(//****,,....                 ....,,,,,***/(####              //
//                (###(/***,,,...                    ...,,,,***(##/                //
//             #.   (#((/**,,,,..                    ...,,,,*((#,                  //
//               ,#(##(((//,,,,..                   ...,,,*/(((#((/                //
//                  *#(((///*,,....                ....,*//((((                    //
//                      *(///***,....            ...,***//,                        //
//                           ,//***,...       ..,,*,                               //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./IERC1155BurnRedeem.sol";

/**
 * @title Burn Redeem
 * @author manifold.xyz
 * @notice Burn Redeem shared extension for Manifold Creator contracts.
 */
contract ERC1155BurnRedeem is IERC165, IERC1155BurnRedeem, ICreatorExtensionTokenURI {
    using Strings for uint256;

    string private constant ARWEAVE_PREFIX = "https://arweave.net/";
    string private constant IPFS_PREFIX = "ipfs://";
    uint256 private constant MAX_UINT_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // stores mapping from tokenId to the burn redeem it represents
    // { creatorContractAddress => { tokenId => BurnRedeem } }
    mapping(address => mapping(uint256 => BurnRedeem)) private _burnRedeems;

    // { contractAddress => { tokenId => { redeemIndex } }
    mapping(address => mapping(uint256 => uint256)) private _redeemTokenIds;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC1155BurnRedeem).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice This extension is shared, not single-creator. So we must ensure
     * that a burn redeems's initializer is an admin on the creator contract
     * @param creatorContractAddress    the address of the creator contract to check the admin against
     */
    modifier creatorAdminRequired(address creatorContractAddress) {
        AdminControl creatorCoreContract = AdminControl(creatorContractAddress);
        require(creatorCoreContract.isAdmin(msg.sender), "Wallet is not an admin");
        _;
    }

    /**
     * See {IERC1155BurnRedeem-initializeBurnRedeem}.
     */
    function initializeBurnRedeem(
        address creatorContractAddress,
        uint256 index,
        BurnRedeemParameters calldata burnRedeemParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        // Revert if burnRedeem at index already exists
        require(_burnRedeems[creatorContractAddress][index].burnTokenAddress == address(0), "Burn redeem already initialized");

        // Sanity checks
        require(ERC165Checker.supportsInterface(burnRedeemParameters.burnTokenAddress, type(IERC1155CreatorCore).interfaceId), "burnToken must be ERC1155Creator");
        require(burnRedeemParameters.endDate == 0 || burnRedeemParameters.startDate < burnRedeemParameters.endDate, "startDate after endDate");
        require(burnRedeemParameters.totalSupply == 0 || burnRedeemParameters.totalSupply % burnRedeemParameters.redeemAmount == 0, "Remainder left from totalSupply");

         // Create the burn redeem
        _burnRedeems[creatorContractAddress][index] = BurnRedeem({
            redeemTokenId: MAX_UINT_256,
            burnTokenId: burnRedeemParameters.burnTokenId,
            burnTokenAddress: burnRedeemParameters.burnTokenAddress,
            startDate: burnRedeemParameters.startDate,
            endDate: burnRedeemParameters.endDate,
            burnAmount: burnRedeemParameters.burnAmount,
            redeemAmount: burnRedeemParameters.redeemAmount,
            redeemedCount: 0,
            totalSupply: burnRedeemParameters.totalSupply,
            storageProtocol: burnRedeemParameters.storageProtocol,
            location: burnRedeemParameters.location
        });
        
        emit BurnRedeemInitialized(creatorContractAddress, index, msg.sender);
    }

    /**
     * See {IERC1155BurnRedeem-updateBurnRedeem}.
     */
    function updateBurnRedeem(
        address creatorContractAddress,
        uint256 index,
        BurnRedeemParameters calldata burnRedeemParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        BurnRedeem memory burnRedeem = _burnRedeems[creatorContractAddress][index];

        // Sanity checks
        require(ERC165Checker.supportsInterface(burnRedeemParameters.burnTokenAddress, type(IERC1155CreatorCore).interfaceId), "burnToken must be ERC1155Creator");
        require(burnRedeem.burnTokenAddress != address(0), "Burn redeem not initialized");
        require(burnRedeemParameters.totalSupply == 0 || burnRedeemParameters.totalSupply % burnRedeemParameters.redeemAmount == 0, "Remainder left from totalSupply");
        require(burnRedeemParameters.endDate == 0 || burnRedeemParameters.startDate < burnRedeemParameters.endDate, "startDate after endDate");

        // Overwrite the existing burnRedeem
        _burnRedeems[creatorContractAddress][index] = BurnRedeem({
            redeemTokenId: burnRedeem.redeemTokenId,
            burnTokenId: burnRedeemParameters.burnTokenId,
            burnTokenAddress: burnRedeemParameters.burnTokenAddress,
            startDate: burnRedeemParameters.startDate,
            endDate: burnRedeemParameters.endDate,
            burnAmount: burnRedeemParameters.burnAmount,
            redeemAmount: burnRedeemParameters.redeemAmount,
            redeemedCount: burnRedeem.redeemedCount,
            totalSupply: burnRedeemParameters.totalSupply,
            storageProtocol: burnRedeemParameters.storageProtocol,
            location: burnRedeemParameters.location
        });
    }

    /**
     * See {IERC1155BurnRedeem-getBurnRedeem}.
     */
    function getBurnRedeem(address creatorContractAddress, uint256 index) external override view returns(BurnRedeem memory) {
        require(_burnRedeems[creatorContractAddress][index].burnTokenAddress != address(0), "Burn redeem not initialized");
        return _burnRedeems[creatorContractAddress][index];
    }

    /**
     * See {IERC1155BurnRedeem-isEligible}.
     */
    function isEligible(address wallet, address creatorContractAddress, uint256 index) external override view returns(uint256) {
        BurnRedeem memory burnRedeem = _burnRedeems[creatorContractAddress][index];
        uint256 burnNumberOwned = IERC1155(burnRedeem.burnTokenAddress).balanceOf(wallet, burnRedeem.burnTokenId);
        return (burnRedeem.burnAmount / burnNumberOwned) * burnRedeem.redeemAmount;
    }

    /**
     * See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creatorContractAddress, uint256 tokenId) external override view returns(string memory uri) {
        uint256 tokenBurnRedeem = _redeemTokenIds[creatorContractAddress][tokenId];
        require(tokenBurnRedeem > 0, "Token does not exist");
        BurnRedeem memory burnRedeem = _burnRedeems[creatorContractAddress][tokenBurnRedeem];

        string memory prefix = "";
        if (burnRedeem.storageProtocol == StorageProtocol.ARWEAVE) {
            prefix = ARWEAVE_PREFIX;
        } else if (burnRedeem.storageProtocol == StorageProtocol.IPFS) {
            prefix = IPFS_PREFIX;
        }
        uri = string(abi.encodePacked(prefix, burnRedeem.location));
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns(bytes4) {
        _onERC1155Received(from, id, value, data);
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns(bytes4) {
        _onERC1155BatchReceived(from, ids, values, data);
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice ERC1155 token transfer callback
     * @param from      the person sending the tokens
     * @param id        the token id of the burn token
     * @param value     the number of tokens to burn
     * @param data      bytes corresponding to the targeted burn redeem action(s), formatted [address mintTo (does not repeat), address creatorContractAddress, uint256 index, uint256 amount, ...]
     */
    function _onERC1155Received(
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) private {
        // Check calldata is valid
        require(data.length % 96 == 32, "Invalid data");
        uint256 redemptionCount = (data.length - 32)/96;

        // Single value arrays used for mint calls
        address[] memory mintToAddress = new address[](1);
        mintToAddress[0] = abi.decode(data[0:32], (address));
        uint256[] memory redemptionAmount = new uint256[](1);

        uint256 amountRequired = 0;

        // Iterate over redemptions in calldata and mint redeem tokens for each
        for (uint256 i = 0; i < redemptionCount;) {
            // Read calldata
            (address creatorContractAddress, uint256 index, uint32 amount) = abi.decode(data[32+i*96:32+(i+1)*96], (address, uint256, uint32));

            (BurnRedeem storage burnRedeem, uint256 amountToBurn, uint256 amountToRedeem) = _retrieveActiveBurnRedeem(creatorContractAddress, index, id, amount);

            // Do mint if needed
            if (amountToRedeem > 0) {
                amountRequired += amountToBurn;
                redemptionAmount[0] = amountToRedeem;
                _mintRedeem(creatorContractAddress, index, burnRedeem, mintToAddress, redemptionAmount);
                emit BurnRedeemMint(creatorContractAddress, burnRedeem.redeemTokenId, amountToRedeem, msg.sender, id);
            }
            unchecked { ++i; }
        }

        require(amountRequired <= value, "Invalid value sent");
        require(amountRequired > 0, "None available");

        // Do burn
        if (amountRequired > 0) {
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = id;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = amountRequired;
            IERC1155CreatorCore(msg.sender).burn(address(this), tokenIds, amounts);
        }

        // Return remaining tokens
        if (amountRequired < value) {
            IERC1155(msg.sender).safeTransferFrom(address(this), from, id, value - amountRequired, "");
        }
    }

    /**
     * @notice ERC1155 batch token transfer callbackx
     * @param ids       a list of the token ids of the burn token
     * @param values    a list of the number of tokens to burn for each id
     * @param data      bytes corresponding to the targeted burn redeem action(s), formatted [address mintTo (does not repeat), address creatorContractAddress, uint256 index, uint256 amount, ...]
     *                  note: the data parameter must be in the same order as the ids and values parameters
     */
    function _onERC1155BatchReceived(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) private {
        // Check calldata is valid
        require(data.length % 96 == 32, "Invalid data");
        uint256 redemptionCount = (data.length - 32)/96;
        require(redemptionCount == ids.length, "Invalid data");

        // Single value arrays used for mint calls
        address[] memory mintToAddress = new address[](1);
        mintToAddress[0] = abi.decode(data[0:32], (address));
        uint256[] memory redemptionAmount = new uint256[](1);

        // Track excess values
        uint256[] memory burnedValues = new uint256[](redemptionCount);
        uint256[] memory remainingValues = new uint256[](redemptionCount);

        // Track if tokens were redeemed
        bool tokensRedeemed = false;
        bool excessValues = false;

        // Iterate over redemptions in calldata and mint redeem tokens for each
        for (uint256 i = 0; i < redemptionCount;) {
            // Read calldata
            (address creatorContractAddress, uint256 index, uint32 amount) = abi.decode(data[32+i*96:32+(i+1)*96], (address, uint256, uint32));

            (BurnRedeem storage burnRedeem, uint256 amountToBurn, uint256 amountToRedeem) = _retrieveActiveBurnRedeem(creatorContractAddress, index, ids[i], amount);

            // Do mint if needed
            if (amountToRedeem > 0) {
                // Store burned and excess values
                burnedValues[i] = amountToBurn;
                if (amountToBurn != values[i]) {
                    remainingValues[i] = values[i] - amountToBurn;
                    excessValues = true;
                }

                // Store values for mint
                redemptionAmount[0] = amountToRedeem;
                tokensRedeemed = true;

                _mintRedeem(creatorContractAddress, index, burnRedeem, mintToAddress, redemptionAmount);
                emit BurnRedeemMint(creatorContractAddress, burnRedeem.redeemTokenId, amountToRedeem, msg.sender, ids[i]);
            } else {
                // Store excess values
                remainingValues[i] = values[i];
                excessValues = true;
            }
            unchecked { ++i; }
        }

        require(tokensRedeemed, "None available");

        // Return remaining tokens
        if (excessValues) {
            for (uint256 i = 0; i < redemptionCount; i++) {
                if (remainingValues[i] > 0) {
                    IERC1155(msg.sender).safeTransferFrom(address(this), from, ids[i], remainingValues[i], "");
                }
            }
        }

        // Do burn
        IERC1155CreatorCore(msg.sender).burn(address(this), ids, burnedValues);
    }

    /**
     * Mint a redemption
     */
    function _mintRedeem(address creatorContractAddress, uint256 index, BurnRedeem storage burnRedeem, address[] memory mintToAddress, uint256[] memory redeemAmounts) private {
        if (burnRedeem.redeemTokenId == MAX_UINT_256) {
            // No token minted yet, mint new token
            string [] memory uris = new string[](1);
            uint256[] memory newTokenIds = IERC1155CreatorCore(creatorContractAddress).mintExtensionNew(mintToAddress, redeemAmounts, uris);

            burnRedeem.redeemTokenId = newTokenIds[0];
            _redeemTokenIds[creatorContractAddress][newTokenIds[0]] = index;

        } else {
            // Mint exisiting token
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = burnRedeem.redeemTokenId;
            IERC1155CreatorCore(creatorContractAddress).mintExtensionExisting(mintToAddress, tokenIds, redeemAmounts);
        }
    }

    /**
     * Returns active burn redeem, amount to burn and amount of redemptions that can occur
     */
    function _retrieveActiveBurnRedeem(address creatorContractAddress, uint256 index, uint256 burnTokenId, uint256 amount) private returns(BurnRedeem storage burnRedeem, uint256 amountToBurn, uint256 amountToRedeem) {
        burnRedeem = _burnRedeems[creatorContractAddress][index];

        // Sanity checks
        require(burnRedeem.startDate == 0 || burnRedeem.startDate < block.timestamp, "Transaction before start date");
        require(burnRedeem.endDate == 0 || burnRedeem.endDate >= block.timestamp, "Transaction after end date");
        require(burnRedeem.burnTokenAddress == msg.sender && burnRedeem.burnTokenId == burnTokenId, "Token not eligible");

        if (burnRedeem.totalSupply == 0 || burnRedeem.redeemedCount < burnRedeem.totalSupply) {
            amountToRedeem = burnRedeem.redeemAmount * amount;
            amountToBurn = burnRedeem.burnAmount * amount;

            // Too many requested, consume the remaining
            if (burnRedeem.totalSupply > 0 && burnRedeem.redeemedCount + amountToRedeem > burnRedeem.totalSupply) {
                amountToRedeem = burnRedeem.totalSupply - burnRedeem.redeemedCount;
                amountToBurn = amountToRedeem / burnRedeem.redeemAmount * burnRedeem.burnAmount;
            }
            unchecked{ burnRedeem.redeemedCount += uint32(amountToRedeem); }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * Burn Redeem interface
 */
interface IERC1155BurnRedeem is IERC1155Receiver {
    enum StorageProtocol { INVALID, NONE, ARWEAVE, IPFS }

    struct BurnRedeemParameters {
        uint256 burnTokenId;
        address burnTokenAddress;
        uint48 startDate;
        uint48 endDate;
        uint32 burnAmount;
        uint32 redeemAmount;
        uint32 totalSupply;
        StorageProtocol storageProtocol;
        string location;
    }

    struct BurnRedeem {
        uint256 redeemTokenId;
        uint256 burnTokenId;
        address burnTokenAddress;
        uint48 startDate;
        uint48 endDate;
        uint32 burnAmount;
        uint32 redeemAmount;
        uint32 redeemedCount;
        uint32 totalSupply;
        StorageProtocol storageProtocol;
        string location;
    }

    event BurnRedeemInitialized(address indexed creatorContract, uint256 indexed index, address initializer);
    event BurnRedeemMint(address indexed creatorContract, uint256 indexed tokenId, uint256 amount, address burnTokenAddress, uint256 burnTokenId);

    /**
     * @notice initialize a new burn redeem, emit initialize event, and return the newly created index
     * @param creatorContractAddress    the creator contract the burn will mint redeem tokens for
     * @param index                     the index of the burnRedeem in the mapping of creatorContractAddress' _burnRedeems
     * @param burnRedeemParameters      the parameters which will affect the minting behavior of the burn redeem
     */
    function initializeBurnRedeem(address creatorContractAddress, uint256 index, BurnRedeemParameters calldata burnRedeemParameters) external;

    /**
     * @notice update an existing burn redeem at index
     * @param creatorContractAddress    the creator contract corresponding to the burn redeem
     * @param index                     the index of the burn redeem in the list of creatorContractAddress' _burnRedeems
     * @param burnRedeemParameters      the parameters which will affect the minting behavior of the burn redeem
     */
    function updateBurnRedeem(address creatorContractAddress, uint256 index, BurnRedeemParameters calldata burnRedeemParameters) external;

    /**
     * @notice get a burn redeem corresponding to a creator contract and index
     * @param creatorContractAddress    the address of the creator contract
     * @param index                     the index of the burn redeem
     * @return                          the burn redeem object
     */
    function getBurnRedeem(address creatorContractAddress, uint256 index) external view returns(BurnRedeem memory);

    /**
     * @notice check if an wallet can participate in the provided burn redeem
     * @param wallet                    the wallet to check ownership against
     * @param creatorContractAddress    the creator contract address
     * @param index                     the index of the burn redeem for which we will mint
     * @return                          the max number of tokens the wallet can mint (0 if ineligible)
     */
    function isEligible(address wallet, address creatorContractAddress, uint256 index) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Manifold ERC721 Edition Controller interface
 */
interface IManifoldERC721Edition {

    event SeriesCreated(address caller, address creator, uint256 series, uint256 maxSupply);

    /**
     * @dev Create a new series.  Returns the series id.
     */
    function createSeries(address creator, uint256 maxSupply, string calldata prefix) external returns(uint256);

    /**
     * @dev Get the latest series created.
     */
    function latestSeries(address creator) external view returns(uint256);

    /**
     * @dev Set the token uri prefix
     */
    function setTokenURIPrefix(address creator, uint256 series, string calldata prefix) external;
    
    /**
     * @dev Mint NFTs to a single recipient
     */
    function mint(address creator, uint256 series, address recipient, uint16 count) external;

    /**
     * @dev Mint NFTS to the recipients
     */
    function mint(address creator, uint256 series, address[] calldata recipients) external;

    /**
     * @dev Total supply of editions
     */
    function totalSupply(address creator, uint256 series) external view returns(uint256);

    /**
     * @dev Max supply of editions
     */
    function maxSupply(address creator, uint256 series) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IManifoldERC721Edition.sol";

/**
 * Manifold ERC721 Edition Controller Implementation
 */
contract ManifoldERC721Edition is CreatorExtension, ICreatorExtensionTokenURI, IManifoldERC721Edition, ReentrancyGuard {
    using Strings for uint256;

    struct IndexRange {
        uint256 startIndex;
        uint256 count;
    }

    mapping(address => mapping(uint256 => string)) _tokenPrefix;
    mapping(address => mapping(uint256 => uint256)) _maxSupply;
    mapping(address => mapping(uint256 => uint256)) _totalSupply;
    mapping(address => mapping(uint256 => IndexRange[])) _indexRanges;
    mapping(address => uint256) _currentSeries;
    
    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier creatorAdminRequired(address creator) {
        require(IAdminControl(creator).isAdmin(msg.sender), "Must be owner or admin of creator contract");
        _;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IManifoldERC721Edition).interfaceId ||
               CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IManifoldERC721Edition-totalSupply}.
     */
    function totalSupply(address creator, uint256 series) external view override returns(uint256) {
        return _totalSupply[creator][series];
    }

    /**
     * @dev See {IManifoldERC721Edition-maxSupply}.
     */
    function maxSupply(address creator, uint256 series) external view override returns(uint256) {
        return _maxSupply[creator][series];
    }

    /**
     * @dev See {IManifoldERC721Edition-createSeries}.
     */
    function createSeries(address creator, uint256 maxSupply_, string calldata prefix) external override creatorAdminRequired(creator) returns(uint256) {
        _currentSeries[creator] += 1;
        uint256 series = _currentSeries[creator];
        _maxSupply[creator][series] = maxSupply_;
        _tokenPrefix[creator][series] = prefix;
        emit SeriesCreated(msg.sender, creator, series, maxSupply_);
        return series;
    }

    /**
     * @dev See {IManifoldERC721Edition-latestSeries}.
     */
    function latestSeries(address creator) external view override returns(uint256) {
        return _currentSeries[creator];
    }

    /**
     * See {IManifoldERC721Edition-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(address creator, uint256 series, string calldata prefix) external override creatorAdminRequired(creator) {
        require(series > 0 && series <= _currentSeries[creator], "Invalid series");
        _tokenPrefix[creator][series] = prefix;
    }
    
    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        (uint256 series, uint256 index) = _tokenSeriesAndIndex(creator, tokenId);
        return string(abi.encodePacked(_tokenPrefix[creator][series], (index+1).toString()));
    }
    
    /**
     * @dev See {IManifoldERC721Edition-mint}.
     */
    function mint(address creator, uint256 series, address recipient, uint16 count) external override nonReentrant creatorAdminRequired(creator) {
        require(count > 0, "Invalid amount requested");
        require(_totalSupply[creator][series]+count <= _maxSupply[creator][series], "Too many requested");
        
        uint256[] memory tokenIds = IERC721CreatorCore(creator).mintExtensionBatch(recipient, count);
        _updateIndexRanges(creator, series, tokenIds[0], count);
    }

    /**
     * @dev See {IManifoldERC721Edition-mint}.
     */
    function mint(address creator, uint256 series, address[] calldata recipients) external override nonReentrant creatorAdminRequired(creator) {
        require(recipients.length > 0, "Invalid amount requested");
        require(_totalSupply[creator][series]+recipients.length <= _maxSupply[creator][series], "Too many requested");
        
        uint256 startIndex = IERC721CreatorCore(creator).mintExtension(recipients[0]);
        for (uint256 i = 1; i < recipients.length;) {
            IERC721CreatorCore(creator).mintExtension(recipients[i]);
            unchecked{i++;}
        }
        _updateIndexRanges(creator, series, startIndex, recipients.length);
    }

    /**
     * @dev Update the index ranges, which is used to figure out the index from a tokenId
     */
    function _updateIndexRanges(address creator, uint256 series, uint256 startIndex, uint256 count) internal {
        IndexRange[] storage indexRanges = _indexRanges[creator][series];
        if (indexRanges.length == 0) {
           indexRanges.push(IndexRange(startIndex, count));
        } else {
          IndexRange storage lastIndexRange = indexRanges[indexRanges.length-1];
          if ((lastIndexRange.startIndex + lastIndexRange.count) == startIndex) {
             lastIndexRange.count += count;
          } else {
            indexRanges.push(IndexRange(startIndex, count));
          }
        }
        _totalSupply[creator][series] += count;
    }

    /**
     * @dev Index from tokenId
     */
    function _tokenSeriesAndIndex(address creator, uint256 tokenId) internal view returns(uint256, uint256) {
        require(_currentSeries[creator] > 0, "Invalid token");
        for (uint series=1; series <= _currentSeries[creator]; series++) {
            IndexRange[] memory indexRanges = _indexRanges[creator][series];
            uint256 offset;
            for (uint i = 0; i < indexRanges.length; i++) {
                IndexRange memory currentIndex = indexRanges[i];
                if (tokenId < currentIndex.startIndex) break;
                if (tokenId >= currentIndex.startIndex && tokenId < currentIndex.startIndex + currentIndex.count) {
                   return (series, tokenId - currentIndex.startIndex + offset);
                }
                offset += currentIndex.count;
            }
        }
        revert("Invalid token");
    }

}

// SPDX-License-Identifier: MIT
// solhint-disable reason-string

pragma solidity ^0.8.0;

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC1155LazyPayableClaim.sol";
import "../../libraries/delegation-registry/IDelegationRegistry.sol";

/**
 * @title Lazy Payable Claim
 * @author manifold.xyz
 * @notice Lazy claim with optional whitelist ERC1155 tokens
 */
contract ERC1155LazyPayableClaim is IERC165, IERC1155LazyPayableClaim, ICreatorExtensionTokenURI, ReentrancyGuard {
    using Strings for uint256;

    string private constant ARWEAVE_PREFIX = "https://arweave.net/";
    string private constant IPFS_PREFIX = "ipfs://";
    uint256 private constant MINT_INDEX_BITMASK = 0xFF;
    // solhint-disable-next-line
    address public immutable DELEGATION_REGISTRY;
    uint32 private constant MAX_UINT_32 = 0xffffffff;
    uint256 private constant MAX_UINT_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // stores mapping from tokenId to the claim it represents
    // { contractAddress => { tokenId => Claim } }
    mapping(address => mapping(uint256 => Claim)) private _claims;

    // ONLY USED FOR NON-MERKLE MINTS: stores the number of tokens minted per wallet per claim, in order to limit maximum
    // { contractAddress => { claimIndex => { walletAddress => walletMints } } }
    mapping(address => mapping(uint256 => mapping(address => uint256))) private _mintsPerWallet;

    // ONLY USED FOR MERKLE MINTS: stores mapping from claim to indices minted
    // { contractAddress => { claimIndex => { claimIndexOffset => index } } }
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _claimMintIndices;

    // { contractAddress => { tokenId => { claimIndex } }
    mapping(address => mapping(uint256 => uint256)) private _claimTokenIds;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC1155LazyPayableClaim).interfaceId ||
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    constructor(address delegationRegistry) {
        DELEGATION_REGISTRY = delegationRegistry;
    }

    /**
     * @notice This extension is shared, not single-creator. So we must ensure
     * that a claim's initializer is an admin on the creator contract
     * @param creatorContractAddress    the address of the creator contract to check the admin against
     */
    modifier creatorAdminRequired(address creatorContractAddress) {
        require(IAdminControl(creatorContractAddress).isAdmin(msg.sender), "Wallet is not an administrator for contract");
        _;
    }

    /**
     * See {IERC1155LazyClaim-initializeClaim}.
     */
    function initializeClaim(
        address creatorContractAddress,
        uint256 claimIndex,
        ClaimParameters calldata claimParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        // Revert if claim at claimIndex already exists
        require(_claims[creatorContractAddress][claimIndex].storageProtocol == StorageProtocol.INVALID, "Claim already initialized");

        // Sanity checks
        require(claimParameters.storageProtocol != StorageProtocol.INVALID, "Cannot initialize with invalid storage protocol");
        require(claimParameters.endDate == 0 || claimParameters.startDate < claimParameters.endDate, "Cannot have startDate greater than or equal to endDate");
        require(claimParameters.merkleRoot == "" || claimParameters.walletMax == 0, "Cannot provide both mintsPerWallet and merkleRoot");

         // Create the claim
        _claims[creatorContractAddress][claimIndex] = Claim({
            total: 0,
            totalMax: claimParameters.totalMax,
            walletMax: claimParameters.walletMax,
            startDate: claimParameters.startDate,
            endDate: claimParameters.endDate,
            storageProtocol: claimParameters.storageProtocol,
            merkleRoot: claimParameters.merkleRoot,
            location: claimParameters.location,
            tokenId: MAX_UINT_256,
            cost: claimParameters.cost,
            paymentReceiver: claimParameters.paymentReceiver
        });
        
        emit ClaimInitialized(creatorContractAddress, claimIndex, msg.sender);
    }

    /**
     * See {IERC1155LazyClaim-updateClaim}.
     */
    function updateClaim(
        address creatorContractAddress,
        uint256 claimIndex,
        ClaimParameters calldata claimParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        // Sanity checks
        require(_claims[creatorContractAddress][claimIndex].storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(claimParameters.storageProtocol != StorageProtocol.INVALID, "Cannot set invalid storage protocol");
        require(claimParameters.endDate == 0 || claimParameters.startDate < claimParameters.endDate, "Cannot have startDate greater than or equal to endDate");

        Claim memory currentClaim = _claims[creatorContractAddress][claimIndex];

        // Overwrite the existing claim
        _claims[creatorContractAddress][claimIndex] = Claim({
            total: currentClaim.total,
            totalMax: claimParameters.totalMax,
            walletMax: claimParameters.walletMax,
            startDate: claimParameters.startDate,
            endDate: claimParameters.endDate,
            storageProtocol: claimParameters.storageProtocol,
            merkleRoot: claimParameters.merkleRoot,
            location: claimParameters.location,
            tokenId: currentClaim.tokenId,
            cost: claimParameters.cost,
            paymentReceiver: claimParameters.paymentReceiver
        });
    }

    /**
     * See {IERC721LazyClaim-updateTokenURIParams}.
     */
    function updateTokenURIParams(
        address creatorContractAddress, uint256 claimIndex,
        StorageProtocol storageProtocol,
        string calldata location
    ) external override creatorAdminRequired(creatorContractAddress)  {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(storageProtocol != StorageProtocol.INVALID, "Cannot set invalid storage protocol");

        claim.storageProtocol = storageProtocol;
        claim.location = location;
    }

    /**
     * See {IERC1155LazyClaim-getClaim}.
     */
    function getClaim(address creatorContractAddress, uint256 claimIndex) external override view returns(Claim memory claim) {
        claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
    }

    /**
     * See {IERC1155LazyClaim-checkMintIndex}.
     */
    function checkMintIndex(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex) public override view returns(bool) {
        Claim memory claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(claim.merkleRoot != "", "Can only check merkle claims");
        uint256 claimMintIndex = mintIndex >> 8;
        uint256 claimMintTracking = _claimMintIndices[creatorContractAddress][claimIndex][claimMintIndex];
        uint256 mintBitmask = 1 << (mintIndex & MINT_INDEX_BITMASK);
        return mintBitmask & claimMintTracking != 0;
    }

    /**
     * See {IERC1155LazyClaim-checkMintIndices}.
     */
    function checkMintIndices(address creatorContractAddress, uint256 claimIndex, uint32[] calldata mintIndices) external override view returns(bool[] memory minted) {
        uint256 mintIndicesLength = mintIndices.length;
        minted = new bool[](mintIndicesLength);
        for (uint256 i = 0; i < mintIndicesLength;) {
            minted[i] = checkMintIndex(creatorContractAddress, claimIndex, mintIndices[i]);
            unchecked{ ++i; }
        }
    }

    /**
     * See {IERC1155LazyClaim-getTotalMints}.
     */
    function getTotalMints(address minter, address creatorContractAddress, uint256 claimIndex) external override view returns(uint32) {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(claim.walletMax != 0, "Can only retrieve for non-merkle claims with walletMax");
        return  uint32(_mintsPerWallet[creatorContractAddress][claimIndex][minter]);
    }

    /**
     * See {IERC1155LazyClaim-mint}.
     */
    function mint(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex, bytes32[] calldata merkleProof, address mintFor) external payable override nonReentrant {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        
        // Safely retrieve the claim
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");

        // Check price
        require(msg.value == claim.cost, "Must pay more.");

        // Check timestamps
        require(claim.startDate == 0 || claim.startDate < block.timestamp, "Transaction before start date");
        require(claim.endDate == 0 || claim.endDate >= block.timestamp, "Transaction after end date");

        // Check totalMax
        require(claim.totalMax == 0 || claim.total < claim.totalMax, "Maximum tokens already minted for this claim");

        if (claim.merkleRoot != "") {
            // Merkle mint
            _checkMerkleAndUpdate(claim, creatorContractAddress, claimIndex, mintIndex, merkleProof, mintFor);
        } else {
            // Non-merkle mint
            if (claim.walletMax != 0) {
                require(_mintsPerWallet[creatorContractAddress][claimIndex][msg.sender] < claim.walletMax, "Maximum tokens already minted for this wallet");
                unchecked{ _mintsPerWallet[creatorContractAddress][claimIndex][msg.sender]++; }
            }
        }
        unchecked{ claim.total++; }

        // Do mint
        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        _mintClaim(creatorContractAddress, claimIndex, claim, recipients, amounts);

        // Transfer proceeds to receiver
        // solhint-disable-next-line
        (bool sent, ) = claim.paymentReceiver.call{value: msg.value}("");
        require(sent, "Failed to transfer to receiver");

        emit ClaimMint(creatorContractAddress, _claimTokenIds[creatorContractAddress][claimIndex]);
    }

    /**
     * See {IERC1155LazyClaim-mintBatch}.
     */
    function mintBatch(address creatorContractAddress, uint256 claimIndex, uint16 mintCount, uint32[] calldata mintIndices, bytes32[][] calldata merkleProofs, address mintFor) external payable override nonReentrant {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        
        // Safely retrieve the claim
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");

        // Check price
        require(msg.value == claim.cost * mintCount, "Must pay more.");

        // Check timestamps
        require(claim.startDate == 0 || claim.startDate < block.timestamp, "Transaction before start date");
        require(claim.endDate == 0 || claim.endDate >= block.timestamp, "Transaction after end date");

        // Check totalMax
        require(claim.totalMax == 0 || claim.total+mintCount <= claim.totalMax, "Too many requested for this claim");

        if (claim.merkleRoot != "") {
            require(mintCount == mintIndices.length && mintCount == merkleProofs.length, "Invalid input");
            // Merkle mint
            for (uint256 i = 0; i < mintCount; ) {
                uint32 mintIndex = mintIndices[i];
                bytes32[] memory merkleProof = merkleProofs[i];
                _checkMerkleAndUpdate(claim, creatorContractAddress, claimIndex, mintIndex, merkleProof, mintFor);
                unchecked { ++i; }
            }
        } else {
            // Non-merkle mint
            if (claim.walletMax != 0) {
                require(_mintsPerWallet[creatorContractAddress][claimIndex][msg.sender]+mintCount <= claim.walletMax, "Too many requested for this wallet");
                unchecked{ _mintsPerWallet[creatorContractAddress][claimIndex][msg.sender] += mintCount; }
            }
        }
        unchecked{ claim.total += mintCount; }

        // Do mint
        address[] memory recipients = new address[](1);
        recipients[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = mintCount;
        _mintClaim(creatorContractAddress, claimIndex, claim, recipients, amounts);
        // solhint-disable-next-line
        (bool sent, ) = claim.paymentReceiver.call{value: msg.value}("");
        require(sent, "Failed to transfer to receiver");

        emit ClaimMintBatch(creatorContractAddress, claimIndex, mintCount);
    }

    /**
     * See {IERC1155LazyPayableClaim-airdrop}.
     */
    function airdrop(address creatorContractAddress, uint256 claimIndex, address[] calldata recipients,
        uint256[] calldata amounts) external override creatorAdminRequired(creatorContractAddress) {
        require(recipients.length == amounts.length, "Unequal number of recipients and amounts provided");

        // Fetch the claim
        Claim storage claim = _claims[creatorContractAddress][claimIndex];

        uint256 totalAmount;
        for (uint256 i = 0; i < amounts.length;) {
            totalAmount += amounts[i];
            unchecked{ ++i; }
        }
        require(totalAmount <= MAX_UINT_32, "Too many requested");
        claim.total += uint32(totalAmount);

        // Airdrop the tokens
        _mintClaim(creatorContractAddress, claimIndex, claim, recipients, amounts);
    }

    /**
     * Mint a claim
     */
    function _mintClaim(address creatorContractAddress, uint256 claimIndex, Claim storage claim, address[] memory recipients, uint256[] memory amounts) private {
        if (claim.tokenId == MAX_UINT_256) {
            // Hasn't been created yet, use mintExtensionNew
            string [] memory uris = new string[](1);
            uint256[] memory newTokenIds = IERC1155CreatorCore(creatorContractAddress).mintExtensionNew(recipients, amounts, uris);
            _claimTokenIds[creatorContractAddress][newTokenIds[0]] = claimIndex;
            claim.tokenId = newTokenIds[0];
        } else {
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = claim.tokenId;
            IERC1155CreatorCore(creatorContractAddress).mintExtensionExisting(recipients, tokenIds, amounts);
        }
    }

    /**
     * Helper to check merkle proof and whether or not the mintIndex was consumed. Also updates the consumed counts
     */
    function _checkMerkleAndUpdate(Claim storage claim, address creatorContractAddress, uint256 claimIndex, uint32 mintIndex, bytes32[] memory merkleProof, address mintFor) private {
        // Merkle mint
        bytes32 leaf;
        if (mintFor == msg.sender) {
            leaf = keccak256(abi.encodePacked(msg.sender, mintIndex));
        } else {
            // Direct verification failed, try delegate verification
            IDelegationRegistry dr = IDelegationRegistry(DELEGATION_REGISTRY);
            require(dr.checkDelegateForContract(msg.sender, mintFor, address(this)), "Invalid delegate");
            leaf = keccak256(abi.encodePacked(mintFor, mintIndex));
        }
        require(MerkleProof.verify(merkleProof, claim.merkleRoot, leaf), "Could not verify merkle proof");

        // Check if mintIndex has been minted
        uint256 claimMintIndex = mintIndex >> 8;
        uint256 claimMintTracking = _claimMintIndices[creatorContractAddress][claimIndex][claimMintIndex];
        uint256 mintBitmask = 1 << (mintIndex & MINT_INDEX_BITMASK);
        require(mintBitmask & claimMintTracking == 0, "Already minted");
        _claimMintIndices[creatorContractAddress][claimIndex][claimMintIndex] = claimMintTracking | mintBitmask;
    }

    /**
     * See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creatorContractAddress, uint256 tokenId) external override view returns(string memory uri) {
        uint224 tokenClaim = uint224(_claimTokenIds[creatorContractAddress][tokenId]);
        require(tokenClaim > 0, "Token does not exist");
        Claim memory claim = _claims[creatorContractAddress][tokenClaim];

        string memory prefix = "";
        if (claim.storageProtocol == StorageProtocol.ARWEAVE) {
            prefix = ARWEAVE_PREFIX;
        } else if (claim.storageProtocol == StorageProtocol.IPFS) {
            prefix = IPFS_PREFIX;
        }
        uri = string(abi.encodePacked(prefix, claim.location));
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable reason-string
pragma solidity ^0.8.0;

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721LazyPayableClaim.sol";
import "../../libraries/delegation-registry/IDelegationRegistry.sol";

/**
 * @title Lazy Payable Claim
 * @author manifold.xyz
 * @notice Lazy payable claim with optional whitelist ERC721 tokens
 */
contract ERC721LazyPayableClaim is IERC165, IERC721LazyPayableClaim, ICreatorExtensionTokenURI, ReentrancyGuard {
    using Strings for uint256;

    string private constant ARWEAVE_PREFIX = "https://arweave.net/";
    string private constant IPFS_PREFIX = "ipfs://";
    uint256 private constant MINT_INDEX_BITMASK = 0xFF;
    // solhint-disable-next-line
    address public immutable DELEGATION_REGISTRY;
    uint32 private constant MAX_UINT_32 = 0xffffffff;
    uint256 private constant MAX_UINT_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // stores mapping from tokenId to the claim it represents
    // { contractAddress => { tokenId => Claim } }
    mapping(address => mapping(uint256 => Claim)) private _claims;

    // ONLY USED FOR NON-MERKLE MINTS: stores the number of tokens minted per wallet per claim, in order to limit maximum
    // { contractAddress => { claimIndex => { walletAddress => walletMints } } }
    mapping(address => mapping(uint256 => mapping(address => uint256))) private _mintsPerWallet;

    // ONLY USED FOR MERKLE MINTS: stores mapping from claim to indices minted
    // { contractAddress => {claimIndex => { claimIndexOffset => index } } }
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private _claimMintIndices;

    struct TokenClaim {
        uint224 claimIndex;
        uint32 mintOrder;
    }
    // stores which tokenId corresponds to which claimIndex, used to generate token uris
    // { contractAddress => { tokenId => TokenClaim } }
    mapping(address => mapping(uint256 => TokenClaim)) private _tokenClaims;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC721LazyPayableClaim).interfaceId ||
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    constructor(address delegationRegistry) {
        DELEGATION_REGISTRY = delegationRegistry;
    }

    /**
     * @notice This extension is shared, not single-creator. So we must ensure
     * that a claim's initializer is an admin on the creator contract
     * @param creatorContractAddress    the address of the creator contract to check the admin against
     */
    modifier creatorAdminRequired(address creatorContractAddress) {
        AdminControl creatorCoreContract = AdminControl(creatorContractAddress);
        require(creatorCoreContract.isAdmin(msg.sender), "Wallet is not an administrator for contract");
        _;
    }

    /**
     * See {IERC721LazyClaim-initializeClaim}.
     */
    function initializeClaim(
        address creatorContractAddress,
        uint256 claimIndex,
        ClaimParameters calldata claimParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        // Revert if claim at claimIndex already exists
        require(_claims[creatorContractAddress][claimIndex].storageProtocol == StorageProtocol.INVALID, "Claim already initialized");

        // Sanity checks
        require(claimParameters.storageProtocol != StorageProtocol.INVALID, "Cannot initialize with invalid storage protocol");
        require(claimParameters.endDate == 0 || claimParameters.startDate < claimParameters.endDate, "Cannot have startDate greater than or equal to endDate");
        require(claimParameters.merkleRoot == "" || claimParameters.walletMax == 0, "Cannot provide both mintsPerWallet and merkleRoot");

        // Create the claim
        _claims[creatorContractAddress][claimIndex] = Claim({
            total: 0,
            totalMax: claimParameters.totalMax,
            walletMax: claimParameters.walletMax,
            startDate: claimParameters.startDate,
            endDate: claimParameters.endDate,
            storageProtocol: claimParameters.storageProtocol,
            identical: claimParameters.identical,
            merkleRoot: claimParameters.merkleRoot,
            location: claimParameters.location,
            cost: claimParameters.cost,
            paymentReceiver: claimParameters.paymentReceiver
        });

        emit ClaimInitialized(creatorContractAddress, claimIndex, msg.sender);
    }

    /**
     * See {IERC721LazyClaim-udpateClaim}.
     */
    function updateClaim(
        address creatorContractAddress,
        uint256 claimIndex,
        ClaimParameters calldata claimParameters
    ) external override creatorAdminRequired(creatorContractAddress) {
        // Sanity checks
        require(_claims[creatorContractAddress][claimIndex].storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(claimParameters.storageProtocol != StorageProtocol.INVALID, "Cannot set invalid storage protocol");
        require(claimParameters.endDate == 0 || claimParameters.startDate < claimParameters.endDate, "Cannot have startDate greater than or equal to endDate");

        // Overwrite the existing claim
        _claims[creatorContractAddress][claimIndex] = Claim({
            total: _claims[creatorContractAddress][claimIndex].total,
            totalMax: claimParameters.totalMax,
            walletMax: claimParameters.walletMax,
            startDate: claimParameters.startDate,
            endDate: claimParameters.endDate,
            storageProtocol: claimParameters.storageProtocol,
            identical: claimParameters.identical,
            merkleRoot: claimParameters.merkleRoot,
            location: claimParameters.location,
            cost: claimParameters.cost,
            paymentReceiver: claimParameters.paymentReceiver
        });
    }

    /**
     * See {IERC721LazyClaim-updateTokenURIParams}.
     */
    function updateTokenURIParams(
        address creatorContractAddress, uint256 claimIndex,
        StorageProtocol storageProtocol,
        bool identical,
        string calldata location
    ) external override creatorAdminRequired(creatorContractAddress)  {
        Claim memory claim = _claims[creatorContractAddress][claimIndex];
        require(_claims[creatorContractAddress][claimIndex].storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(storageProtocol != StorageProtocol.INVALID, "Cannot set invalid storage protocol");

        // Overwrite the existing claim
        _claims[creatorContractAddress][claimIndex] = Claim({
            total: claim.total,
            totalMax: claim.totalMax,
            walletMax: claim.walletMax,
            startDate: claim.startDate,
            endDate: claim.endDate,
            storageProtocol: storageProtocol,
            identical: identical,
            merkleRoot: claim.merkleRoot,
            location: location,
            cost: claim.cost,
            paymentReceiver: claim.paymentReceiver
        });
    }

    /**
     * See {IERC721LazyClaim-getClaim}.
     */
    function getClaim(address creatorContractAddress, uint256 claimIndex) external override view returns(Claim memory claim) {
        claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
    }

    /**
     * See {IERC721LazyClaim-checkMintIndex}.
     */
    function checkMintIndex(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex) public override view returns(bool) {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(claim.merkleRoot != "", "Can only check merkle claims");
        uint256 claimMintIndex = mintIndex >> 8;
        uint256 claimMintTracking = _claimMintIndices[creatorContractAddress][claimIndex][claimMintIndex];
        uint256 mintBitmask = 1 << (mintIndex & MINT_INDEX_BITMASK);
        return mintBitmask & claimMintTracking != 0;
    }

    /**
     * See {IERC721LazyClaim-checkMintIndices}.
     */
    function checkMintIndices(address creatorContractAddress, uint256 claimIndex, uint32[] calldata mintIndices) external override view returns(bool[] memory minted) {
        uint256 mintIndicesLength = mintIndices.length;
        minted = new bool[](mintIndices.length);
        for (uint256 i = 0; i < mintIndicesLength;) {
            minted[i] = checkMintIndex(creatorContractAddress, claimIndex, mintIndices[i]);
            unchecked{ ++i; }
        }
    }

    /**
     * See {IERC721LazyClaim-getTotalMints}.
     */
    function getTotalMints(address minter, address creatorContractAddress, uint256 claimIndex) external override view returns(uint32) {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");
        require(claim.walletMax != 0, "Can only retrieve for non-merkle claims with walletMax");
        return  uint32(_mintsPerWallet[creatorContractAddress][claimIndex][minter]);
    }

    /**
     * See {IERC721LazyClaim-mint}.
     */
    function mint(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex, bytes32[] calldata merkleProof, address mintFor) external payable override {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        // Safely retrieve the claim
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");

        // Check price
        require(msg.value == claim.cost, "Must pay more.");

        // Check timestamps
        require(claim.startDate == 0 || claim.startDate < block.timestamp, "Transaction before start date");
        require(claim.endDate == 0 || claim.endDate >= block.timestamp, "Transaction after end date");

        // Check totalMax
        require(claim.totalMax == 0 || claim.total < claim.totalMax, "Maximum tokens already minted for this claim");

        if (claim.merkleRoot != "") {
            // Merkle mint
            _checkMerkleAndUpdate(claim, creatorContractAddress, claimIndex, mintIndex, merkleProof, mintFor);
        } else {
            // Non-merkle mint
            if (claim.walletMax != 0) {
                require(_mintsPerWallet[creatorContractAddress][claimIndex][msg.sender] < claim.walletMax, "Maximum tokens already minted for this wallet");
                unchecked{ _mintsPerWallet[creatorContractAddress][claimIndex][msg.sender]++; }
            }
        }
        unchecked{ claim.total++; }

        // Do mint
        uint256 newTokenId = IERC721CreatorCore(creatorContractAddress).mintExtension(msg.sender);

        // Insert the new tokenId into _tokenClaims for the current claim address & index
        _tokenClaims[creatorContractAddress][newTokenId] = TokenClaim(uint224(claimIndex), claim.total);
        // solhint-disable-next-line
        (bool sent, ) = claim.paymentReceiver.call{value: msg.value}("");
        require(sent, "Failed to transfer to receiver");

        emit ClaimMint(creatorContractAddress, claimIndex);
    }

    /**
     * See {IERC721LazyClaim-mintBatch}.
     */
    function mintBatch(address creatorContractAddress, uint256 claimIndex, uint16 mintCount, uint32[] calldata mintIndices, bytes32[][] calldata merkleProofs, address mintFor) external payable override {
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        
        // Safely retrieve the claim
        require(claim.storageProtocol != StorageProtocol.INVALID, "Claim not initialized");

        // Check price
        require(msg.value == claim.cost * mintCount, "Must pay more.");

        // Check timestamps
        require(claim.startDate == 0 || claim.startDate < block.timestamp, "Transaction before start date");
        require(claim.endDate == 0 || claim.endDate >= block.timestamp, "Transaction after end date");

        // Check totalMax
        require(claim.totalMax == 0 || claim.total+mintCount <= claim.totalMax, "Too many requested for this claim");
        
        uint256 newMintIndex = claim.total+1;
        unchecked{ claim.total += mintCount; }

        if (claim.merkleRoot != "") {
            require(mintCount == mintIndices.length && mintCount == merkleProofs.length, "Invalid input");
            // Merkle mint
            for (uint256 i = 0; i < mintCount;) {
                uint32 mintIndex = mintIndices[i];
                bytes32[] memory merkleProof = merkleProofs[i];
                
                _checkMerkleAndUpdate(claim, creatorContractAddress, claimIndex, mintIndex, merkleProof, mintFor);
                unchecked { ++i; }
            }
        } else {
            // Non-merkle mint
            if (claim.walletMax != 0) {
                require(_mintsPerWallet[creatorContractAddress][claimIndex][msg.sender]+mintCount <= claim.walletMax, "Too many requested for this wallet");
                unchecked{ _mintsPerWallet[creatorContractAddress][claimIndex][msg.sender] += mintCount; }
            }
            
        }
        uint256[] memory newTokenIds = IERC721CreatorCore(creatorContractAddress).mintExtensionBatch(msg.sender, mintCount);
        for (uint256 i = 0; i < mintCount;) {
            _tokenClaims[creatorContractAddress][newTokenIds[i]] = TokenClaim(uint224(claimIndex), uint32(newMintIndex+i));
            unchecked { ++i; }
        }
        // solhint-disable-next-line
        (bool sent, ) = claim.paymentReceiver.call{value: msg.value}("");
        require(sent, "Failed to transfer to receiver");

        emit ClaimMintBatch(creatorContractAddress, claimIndex, mintCount);
    }

    /**
     * See {IERC721LazyClaim-airdrop}.
     */
    function airdrop(address creatorContractAddress, uint256 claimIndex, address[] calldata recipients,
            uint16[] calldata amounts) external override creatorAdminRequired(creatorContractAddress) {
        require(recipients.length == amounts.length, "Unequal number of recipients and amounts provided");

        // Fetch the claim, create newMintIndex to keep track of token ids created by the airdrop
        Claim storage claim = _claims[creatorContractAddress][claimIndex];
        uint256 newMintIndex = claim.total+1;

        for (uint256 i = 0; i < recipients.length;) {
            // Airdrop the tokens
            uint256[] memory newTokenIds = IERC721CreatorCore(creatorContractAddress).mintExtensionBatch(recipients[i], amounts[i]);
            
            // Register the tokenClaims, so that tokenURI will work for airdropped tokens
            for (uint256 j = 0; j < newTokenIds.length;) {
                _tokenClaims[creatorContractAddress][newTokenIds[j]] = TokenClaim(uint224(claimIndex), uint32(newMintIndex+j));
                unchecked { ++j; }
            }

            // Increment claim.total and newMintIndex for the next airdrop
            unchecked{ claim.total += uint32(newTokenIds.length); }
            unchecked{ newMintIndex += newTokenIds.length; }

            unchecked{ ++i; }
        }
    }

    /**
     * Helper to check merkle proof and whether or not the mintIndex was consumed. Also updates the consumed counts
     */
    function _checkMerkleAndUpdate(Claim storage claim, address creatorContractAddress, uint256 claimIndex, uint32 mintIndex, bytes32[] memory merkleProof, address mintFor) private {
        // Merkle mint
        bytes32 leaf;
        if (mintFor == msg.sender) {
            leaf = keccak256(abi.encodePacked(msg.sender, mintIndex));
        } else {
            // Direct verification failed, try delegate verification
            IDelegationRegistry dr = IDelegationRegistry(DELEGATION_REGISTRY);
            require(dr.checkDelegateForContract(msg.sender, mintFor, address(this)), "Invalid delegate");
            leaf = keccak256(abi.encodePacked(mintFor, mintIndex));
        }
        require(MerkleProof.verify(merkleProof, claim.merkleRoot, leaf), "Could not verify merkle proof");

        // Check if mintIndex has been minted
        uint256 claimMintIndex = mintIndex >> 8;
        uint256 claimMintTracking = _claimMintIndices[creatorContractAddress][claimIndex][claimMintIndex];
        uint256 mintBitmask = 1 << (mintIndex & MINT_INDEX_BITMASK);
        require(mintBitmask & claimMintTracking == 0, "Already minted");
        _claimMintIndices[creatorContractAddress][claimIndex][claimMintIndex] = claimMintTracking | mintBitmask;
    }

    /**
     * See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creatorContractAddress, uint256 tokenId) external override view returns(string memory uri) {
        TokenClaim memory tokenClaim = _tokenClaims[creatorContractAddress][tokenId];
        require(tokenClaim.claimIndex > 0, "Token does not exist");
        Claim memory claim = _claims[creatorContractAddress][tokenClaim.claimIndex];

        string memory prefix = "";
        if (claim.storageProtocol == StorageProtocol.ARWEAVE) {
            prefix = ARWEAVE_PREFIX;
        } else if (claim.storageProtocol == StorageProtocol.IPFS) {
            prefix = IPFS_PREFIX;
        }
        uri = string(abi.encodePacked(prefix, claim.location));

        // Depending on params, we may want to append a suffix to location
        if (!claim.identical) {
            uri = string(abi.encodePacked(uri, "/", uint256(tokenClaim.mintOrder).toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Lazy Claim interface
 */
interface IERC1155LazyPayableClaim {
    enum StorageProtocol { INVALID, NONE, ARWEAVE, IPFS }

    struct ClaimParameters {
        uint32 totalMax;
        uint32 walletMax;
        uint48 startDate;
        uint48 endDate;
        StorageProtocol storageProtocol;
        bytes32 merkleRoot;
        string location;
        uint256 cost;
        address payable paymentReceiver;
    }

    struct Claim {
        uint32 total;
        uint32 totalMax;
        uint32 walletMax;
        uint48 startDate;
        uint48 endDate;
        StorageProtocol storageProtocol;
        bytes32 merkleRoot;
        string location;
        uint256 tokenId;
        uint256 cost;
        address payable paymentReceiver;
    }

    event ClaimInitialized(address indexed creatorContract, uint256 indexed claimIndex, address initializer);
    event ClaimMint(address indexed creatorContract, uint256 indexed claimIndex);
    event ClaimMintBatch(address indexed creatorContract, uint256 indexed claimIndex, uint16 mintCount);

    /**
     * @notice initialize a new claim, emit initialize event, and return the newly created index
     * @param creatorContractAddress    the creator contract the claim will mint tokens for
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param claimParameters           the parameters which will affect the minting behavior of the claim
     */
    function initializeClaim(address creatorContractAddress, uint256 claimIndex, ClaimParameters calldata claimParameters) external;

    /**
     * @notice update an existing claim at claimIndex
     * @param creatorContractAddress    the creator contract corresponding to the claim
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param claimParameters           the parameters which will affect the minting behavior of the claim
     */
    function updateClaim(address creatorContractAddress, uint256 claimIndex, ClaimParameters calldata claimParameters) external;

    /**
     * @notice update tokenURI parameters for an existing claim at claimIndex
     * @param creatorContractAddress    the creator contract corresponding to the claim
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param storageProtocol           the new storage protocol
     * @param location                  the new location
     */
    function updateTokenURIParams(address creatorContractAddress, uint256 claimIndex, StorageProtocol storageProtocol, string calldata location) external;

    /**
     * @notice get a claim corresponding to a creator contract and index
     * @param creatorContractAddress    the address of the creator contract
     * @param claimIndex                the index of the claim
     * @return                          the claim object
     */
    function getClaim(address creatorContractAddress, uint256 claimIndex) external view returns(Claim memory);

    /**
     * @notice check if a mint index has been consumed or not (only for merkle claims)
     *
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param claimIndex                the index of the claim
     * @param mintIndex                 the mint index of the claim
     * @return                          whether or not the mint index was consumed
     */
    function checkMintIndex(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex) external view returns(bool);

    /**
     * @notice check if multiple mint indices has been consumed or not (only for merkle claims)
     *
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param claimIndex                the index of the claim
     * @param mintIndices               the mint index of the claim
     * @return                          whether or not the mint index was consumed
     */
    function checkMintIndices(address creatorContractAddress, uint256 claimIndex, uint32[] calldata mintIndices) external view returns(bool[] memory);

    /**
     * @notice get mints made for a wallet (only for non-merkle claims with walletMax)
     *
     * @param minter                    the address of the minting address
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param claimIndex                the index of the claim
     * @return                          how many mints the minter has made
     */
    function getTotalMints(address minter, address creatorContractAddress, uint256 claimIndex) external view returns(uint32);

    /**
     * @notice allow a wallet to lazily claim a token according to parameters
     * @param creatorContractAddress    the creator contract address
     * @param claimIndex                the index of the claim for which we will mint
     * @param mintIndex                 the mint index (only needed for merkle claims)
     * @param merkleProof               if the claim has a merkleRoot, verifying merkleProof ensures that address + minterValue was used to construct it  (only needed for merkle claims)
     */
    function mint(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex, bytes32[] calldata merkleProof, address mintFor) external payable;

    /**
     * @notice allow a wallet to lazily claim a token according to parameters
     * @param creatorContractAddress    the creator contract address
     * @param claimIndex                the index of the claim for which we will mint
     * @param mintCount                 the number of claims to mint
     * @param mintIndices               the mint index (only needed for merkle claims)
     * @param merkleProofs              if the claim has a merkleRoot, verifying merkleProof ensures that address + minterValue was used to construct it  (only needed for merkle claims)
     */
    function mintBatch(address creatorContractAddress, uint256 claimIndex, uint16 mintCount, uint32[] calldata mintIndices, bytes32[][] calldata merkleProofs, address mintFor) external payable;

    /**
     * @notice allow admin to airdrop arbitrary tokens 
     * @param creatorContractAddress    the creator contract the claim will mint tokens for
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param recipients                addresses to airdrop to
     * @param amounts                   number of tokens to airdrop to each address in addresses
     */
    function airdrop(address creatorContractAddress, uint256 claimIndex, address[] calldata recipients, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Lazy Payable Claim interface
 */
interface IERC721LazyPayableClaim {
    enum StorageProtocol { INVALID, NONE, ARWEAVE, IPFS }

    struct ClaimParameters {
        uint32 totalMax;
        uint32 walletMax;
        uint48 startDate;
        uint48 endDate;
        StorageProtocol storageProtocol;
        bool identical;
        bytes32 merkleRoot;
        string location;
        uint cost;
        address payable paymentReceiver;
    }

    struct Claim {
        uint32 total;
        uint32 totalMax;
        uint32 walletMax;
        uint48 startDate;
        uint48 endDate;
        StorageProtocol storageProtocol;
        bool identical;
        bytes32 merkleRoot;
        string location;
        uint cost;
        address payable paymentReceiver;
    }

    event ClaimInitialized(address indexed creatorContract, uint256 indexed claimIndex, address initializer);
    event ClaimMint(address indexed creatorContract, uint256 indexed claimIndex);
    event ClaimMintBatch(address indexed creatorContract, uint256 indexed claimIndex, uint16 mintCount);

    /**
     * @notice initialize a new claim, emit initialize event, and return the newly created index
     * @param creatorContractAddress    the creator contract the claim will mint tokens for
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param claimParameters           the parameters which will affect the minting behavior of the claim
     */
    function initializeClaim(address creatorContractAddress, uint256 claimIndex, ClaimParameters calldata claimParameters) external;

    /**
     * @notice update an existing claim at claimIndex
     * @param creatorContractAddress    the creator contract corresponding to the claim
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param claimParameters           the parameters which will affect the minting behavior of the claim
     */
    function updateClaim(address creatorContractAddress, uint256 claimIndex, ClaimParameters calldata claimParameters) external;

    /**
     * @notice update tokenURI parameters for an existing claim at claimIndex
     * @param creatorContractAddress    the creator contract corresponding to the claim
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param storageProtocol           the new storage protocol
     * @param identical                 the new value of identical
     * @param location                  the new location
     */
    function updateTokenURIParams(address creatorContractAddress, uint256 claimIndex, StorageProtocol storageProtocol, bool identical, string calldata location) external;

    /**
     * @notice get a claim corresponding to a creator contract and index
     * @param creatorContractAddress    the address of the creator contract
     * @param claimIndex                the index of the claim
     * @return                          the claim object
     */
    function getClaim(address creatorContractAddress, uint256 claimIndex) external view returns(Claim memory);

    /**
     * @notice check if a mint index has been consumed or not (only for merkle claims)
     *
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param claimIndex                the index of the claim
     * @param mintIndex                 the mint index of the claim
     * @return                          whether or not the mint index was consumed
     */
    function checkMintIndex(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex) external view returns(bool);

    /**
     * @notice check if multiple mint indices has been consumed or not (only for merkle claims)
     *
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param claimIndex                the index of the claim
     * @param mintIndices               the mint index of the claim
     * @return                          whether or not the mint index was consumed
     */
    function checkMintIndices(address creatorContractAddress, uint256 claimIndex, uint32[] calldata mintIndices) external view returns(bool[] memory);

    /**
     * @notice get mints made for a wallet (only for non-merkle claims with walletMax)
     *
     * @param minter                    the address of the minting address
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param claimIndex                the index of the claim
     * @return                          how many mints the minter has made
     */
    function getTotalMints(address minter, address creatorContractAddress, uint256 claimIndex) external view returns(uint32);

    /**
     * @notice allow a wallet to lazily claim a token according to parameters
     * @param creatorContractAddress    the creator contract address
     * @param claimIndex                the index of the claim for which we will mint
     * @param mintIndex                 the mint index (only needed for merkle claims)
     * @param merkleProof               if the claim has a merkleRoot, verifying merkleProof ensures that address + minterValue was used to construct it  (only needed for merkle claims)
     */
    function mint(address creatorContractAddress, uint256 claimIndex, uint32 mintIndex, bytes32[] calldata merkleProof, address mintFor) external payable;

    /**
     * @notice allow a wallet to lazily claim a token according to parameters
     * @param creatorContractAddress    the creator contract address
     * @param claimIndex                the index of the claim for which we will mint
     * @param mintCount                 the number of claims to mint
     * @param mintIndices               the mint index (only needed for merkle claims)
     * @param merkleProofs              if the claim has a merkleRoot, verifying merkleProof ensures that address + minterValue was used to construct it  (only needed for merkle claims)
     */
    function mintBatch(address creatorContractAddress, uint256 claimIndex, uint16 mintCount, uint32[] calldata mintIndices, bytes32[][] calldata merkleProofs, address mintFor) external payable;

    /**
     * @notice allow admin to airdrop arbitrary tokens 
     * @param creatorContractAddress    the creator contract the claim will mint tokens for
     * @param claimIndex                the index of the claim in the list of creatorContractAddress' _claims
     * @param recipients                addresses to airdrop to
     * @param amounts                   number of tokens to airdrop to each address in addresses
     */
    function airdrop(address creatorContractAddress, uint256 claimIndex, address[] calldata recipients, uint16[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IERC721FrozenMetadata.sol";

/**
 * Manifold ERC721 Frozen Metadata Implementation
 */
contract ERC721FrozenMetadata is IERC165, IERC721FrozenMetadata, ReentrancyGuard {
    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier creatorAdminRequired(address creator) {
        require(IAdminControl(creator).isAdmin(msg.sender), "Must be owner or admin of creator contract");
        _;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC721FrozenMetadata).interfaceId;
    }
    
    /**
     * @dev See {IManifoldERC721Edition-mint}.
     */
    function mintToken(address creator, address recipient, string calldata tokenURI) external override nonReentrant creatorAdminRequired(creator) returns(uint256) {
        require(bytes(tokenURI).length > 0, "Cannot mint blank string");
        
        return IERC721CreatorCore(creator).mintExtension(recipient, tokenURI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Manifold ERC721 Frozen Metadata interface
 */
interface IERC721FrozenMetadata {

    /**
     * @dev Mints a new token. Returns the tokenId
     */
    function mintToken(address creator, address recipient, string calldata tokenURI) external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";

import "../enumerable/ERC721/ERC721OwnerEnumerableExtension.sol";
import "../enumerable/ERC721/ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "../redeem/ERC721/ERC721RedeemBase.sol";

contract MockERC721Creator is ERC721Creator {
     constructor (string memory _name, string memory _symbol) ERC721Creator(_name, _symbol) {}
}

contract MockERC1155Creator is ERC1155Creator {
     constructor () ERC1155Creator() {}
}

contract MockERC721OwnerEnumerableExtension is ERC721OwnerEnumerableExtension {
    function testMint(address creator, address to) public {
        ERC721Creator(creator).mintExtension(to);
    }
}

contract MockERC721OwnerEnumerableSingleCreatorExtension is ERC721OwnerEnumerableSingleCreatorExtension {
    constructor(address creator) ERC721OwnerEnumerableSingleCreatorExtension(creator) {}

    function testMint(address to) public {
        ERC721Creator(_creator).mintExtension(to);
    }
}

contract MockERC721RedeemEnumerable is ERC721OwnerEnumerableSingleCreatorBase, ERC721RedeemBase {
    constructor(address creator, uint16 redemptionRate_, uint16 redemptionMax_) ERC721RedeemBase(creator, redemptionRate_, redemptionMax_) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721RedeemBase, ERC721CreatorExtensionApproveTransfer) returns (bool) {
        return ERC721RedeemBase.supportsInterface(interfaceId) || ERC721CreatorExtensionApproveTransfer.supportsInterface(interfaceId);
    }
}

contract MockETHReceiver {
    fallback() external payable {
        // Transfer caps gas at 2300. This function needs to consume more gas than that.
        for (uint j = 0; j < 2300;) {
            unchecked{ j++; }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";

import "./ERC1155RedeemBase.sol";
import "./IERC1155ClaimRedeem.sol";

/**
 * @dev Claim redemption via ERC721 NFT
 */
abstract contract ERC1155ClaimRedeem is ReentrancyGuard, ERC1155RedeemBase, IERC1155ClaimRedeem {

    mapping (address => mapping (uint256 => bool)) private _claimedERC721;    
    uint256 internal _redemptionTokenId;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155RedeemBase, IERC165) returns (bool) {
        return interfaceId == type(IERC1155ClaimRedeem).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155ClaimRedeem-initialize}.
     */
    function initialize(string calldata uri) external virtual override adminRequired {
        require(_redemptionTokenId == 0, "Already initialized");
        address[] memory receivers = new address[](1);
        receivers[0] = address(this);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0;
        string[] memory uris = new string[](1);
        uris[0] = uri;
        _redemptionTokenId = IERC1155CreatorCore(_creator).mintExtensionNew(receivers, amounts, uris)[0];
    }

    /**
     * @dev See {IERC1155ClaimRedeem-updateURI}.
     */
    function updateURI(string calldata uri) external virtual override adminRequired {
        require(_redemptionTokenId != 0, "Not initialized");
        IERC1155CreatorCore(_creator).setTokenURIExtension(_redemptionTokenId, uri);
    }

    function _recordRedemption(address contract_, uint256 tokenId) internal {
        require(!_claimedERC721[contract_][tokenId], "Already claimed");
        _claimedERC721[contract_][tokenId] = true;
    }

    /**
     * @dev See {IRedeemBase-redeemable}
     */
    function redeemable(address contract_, uint256 tokenId) public view virtual override(RedeemBase, IRedeemBase) returns(bool) {
       if (_claimedERC721[contract_][tokenId]) return false;
       return super.redeemable(contract_, tokenId);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC1155CreatorCore.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../../libraries/single-creator/ERC1155/ERC1155SingleCreatorExtension.sol";

import "../RedeemBase.sol";
import "./IERC1155RedeemBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
abstract contract ERC1155RedeemBase is ERC1155SingleCreatorExtension, RedeemBase, IERC1155RedeemBase {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(RedeemBase, IERC165) returns (bool) {
        return interfaceId == type(IERC1155RedeemBase).interfaceId || RedeemBase.supportsInterface(interfaceId);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC1155RedeemBase.sol";

/**
 * @dev Claim redemption interface
 */
interface IERC1155ClaimRedeem is IERC1155RedeemBase {

    /**
     * @dev Initialize the redemption app.  Must be called.
     */
    function initialize(string calldata uri) external;

    /**
     * @dev Change the uri of the extension token
     */
    function updateURI(string calldata uri) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../IRedeemBase.sol";

/**
 * @dev Base redemption interface
 */
interface IERC1155RedeemBase is IRedeemBase {


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "./ERC721RedeemBase.sol";
import "./IERC721BurnRedeem.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
contract ERC721BurnRedeem is ReentrancyGuard, ERC721RedeemBase, IERC721BurnRedeem, IERC1155Receiver, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping (address => mapping (uint256 => address)) private _recoverableERC721;

    constructor(address creator, uint16 redemptionRate, uint16 redemptionMax) ERC721RedeemBase(creator, redemptionRate, redemptionMax) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721RedeemBase, IERC165) returns (bool) {
        return interfaceId == type(IERC721BurnRedeem).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721BurnRedeem-setERC721Recoverable}
     */
    function setERC721Recoverable(address contract_, uint256 tokenId, address recoverer) external virtual override adminRequired {
        require(ERC165Checker.supportsInterface(contract_, type(IERC721).interfaceId), "BurnRedeem: Must implement IERC721");
        _recoverableERC721[contract_][tokenId] = recoverer;
    }

    /**
     * @dev See {IERC721BurnRedeem-recoverERC721}
     */
    function recoverERC721(address contract_, uint256 tokenId) external virtual override {
        address recoverer = _recoverableERC721[contract_][tokenId];
        require(recoverer == msg.sender, "BurnRedeem: Permission denied");
        IERC721(contract_).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @dev See {IERC721BurnRedeem-redeemERC721}
     */
    function redeemERC721(address[] calldata contracts, uint256[] calldata tokenIds) external virtual override nonReentrant {
        require(contracts.length == tokenIds.length, "BurnRedeem: Invalid parameters");
        require(contracts.length == _redemptionRate, "BurnRedeem: Incorrect number of NFTs being redeemed");

        // Attempt Burn
        for (uint i = 0; i < contracts.length; i++) {
            // Check that we can burn
            require(redeemable(contracts[i], tokenIds[i]), "BurnRedeem: Invalid NFT");

            try IERC721(contracts[i]).ownerOf(tokenIds[i]) returns (address ownerOfAddress) {
                require(ownerOfAddress == msg.sender, "BurnRedeem: Caller must own NFTs");
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            if (!IERC721(contracts[i]).isApprovedForAll(msg.sender, address(this))) {
                try IERC721(contracts[i]).getApproved(tokenIds[i]) returns (address approvedAddress) {
                    require(approvedAddress == address(this), "BurnRedeem: Contract must be given approval to burn NFT");
                } catch (bytes memory) {
                    revert("BurnRedeem: Bad token contract");
                }
            }
            
            // Then burn
            try IERC721(contracts[i]).transferFrom(msg.sender, address(0xdEaD), tokenIds[i]) {
            } catch (bytes memory) {
                revert("BurnRedeem: Burn failure");
            }
        }

        // Mint reward
        _mintRedemption(msg.sender);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data) external override nonReentrant returns (bytes4) {
        require(redeemable(msg.sender, tokenId), "BurnRedeem: Invalid NFT");
        require(_redemptionRate == 1, "BurnRedeem: Can only allow direct receiving of redemptions of 1 NFT");
        
        
        // Burn it
        try IERC721(msg.sender).safeTransferFrom(address(this), address(0xdEaD), tokenId, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC721Received.selector;
    }


    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(redeemable(msg.sender, id), "BurnRedeem: Invalid NFT");
        require(value == _redemptionRate, "BurnRedeem: Incorrect number of NFTs being redeemed");

        // Burn it
        try IERC1155(msg.sender).safeTransferFrom(address(this), address(0xdEaD), id, value, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(ids.length == values.length, "BurnRedeem: Invalid input");

        uint256 totalValue = 0;
        for (uint i=0; i<ids.length; i++) {
            require(redeemable(msg.sender, ids[i]), "BurnRedeem: Invalid NFT");
            totalValue += values[i];
        }

        require(totalValue == _redemptionRate, "BurnRedeem: Incorrect number of NFTs being redeemed");

        // Burn it
        try IERC1155(msg.sender).safeBatchTransferFrom(address(this), address(0xdEaD), ids, values, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC1155BatchReceived.selector;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "./ERC721RedeemSetBase.sol";
import "./IERC721BurnRedeemSet.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
contract ERC721BurnRedeemSet is ReentrancyGuard, ERC721RedeemSetBase, IERC721BurnRedeemSet, IERC1155Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping (address => mapping (uint256 => address)) private _recoverableERC721;
    RedemptionItem[] private _redemptionSet;

    constructor(address creator, RedemptionItem[] memory redemptionSet, uint16 redemptionMax) ERC721RedeemSetBase(creator, redemptionSet, redemptionMax) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721RedeemSetBase, IERC165) returns (bool) {
        return interfaceId == type(IERC721BurnRedeemSet).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721BurnRedeemSet-setERC721Recoverable}
     */
    function setERC721Recoverable(address contract_, uint256 tokenId, address recoverer) external virtual override adminRequired {
        require(ERC165Checker.supportsInterface(contract_, type(IERC721).interfaceId), "BurnRedeem: Must implement IERC721");
        _recoverableERC721[contract_][tokenId] = recoverer;
    }

    /**
     * @dev See {IERC721BurnRedeemSet-recoverERC721}
     */
    function recoverERC721(address contract_, uint256 tokenId) external virtual override {
        address recoverer = _recoverableERC721[contract_][tokenId];
        require(recoverer == msg.sender, "BurnRedeem: Permission denied");
        IERC721(contract_).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @dev See {IERC721BurnRedeemSet-redeemERC721}
     */
    function redeemERC721(address[] calldata contracts, uint256[] calldata tokenIds) external virtual override nonReentrant {
        require(contracts.length == tokenIds.length, "BurnRedeem: Invalid parameters");
        require(_validateCompleteSet(contracts, tokenIds), "BurnRedeem: Incomplete set");

        // Attempt Burn
        for (uint i=0; i<contracts.length; i++) {
            try IERC721(contracts[i]).ownerOf(tokenIds[i]) returns (address ownerOfAddress) {
                require(ownerOfAddress == msg.sender, "BurnRedeem: Caller must own NFTs");
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            if (!IERC721(contracts[i]).isApprovedForAll(msg.sender, address(this))) {
                try IERC721(contracts[i]).getApproved(tokenIds[i]) returns (address approvedAddress) {
                    require(approvedAddress == address(this), "BurnRedeem: Contract must be given approval to burn NFT");
                } catch (bytes memory) {
                    revert("BurnRedeem: Bad token contract");
                }
            }
            
            // Burn
            try IERC721(contracts[i]).transferFrom(msg.sender, address(0xdEaD), tokenIds[i]) {
            } catch (bytes memory) {
                revert("BurnRedeem: Burn failure");
            }
        }

        // Mint reward
        _mintRedemption(msg.sender);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override pure returns(bytes4) {
        revert("BurnRedeem: Incomplete set");
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(ids.length == values.length, "BurnRedeem: Invalid input");
        address[] memory contracts = new address[](ids.length);
        for (uint i=0; i<ids.length; i++) {
            require(values[i] == 1, "BurnRedeem: Can only use one of each token");
            contracts[i] = msg.sender;
        }

        require(_validateCompleteSet(contracts, ids), "BurnRedeem: Incomplete set");

        // Burn it
        try IERC1155(msg.sender).safeBatchTransferFrom(address(this), address(0xdEaD), ids, values, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC1155BatchReceived.selector;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";

import "../../libraries/single-creator/ERC721/ERC721SingleCreatorExtension.sol";

import "../RedeemBase.sol";
import "./IERC721RedeemBase.sol";

/**
 * @dev Redeem NFT base logic
 */
abstract contract ERC721RedeemBase is ERC721SingleCreatorExtension, RedeemBase, CreatorExtension, IERC721RedeemBase {

    uint16 internal immutable _redemptionRate;
    uint16 private _redemptionMax;
    uint16 private _redemptionCount;
    uint256[] private _mintedTokens;
    mapping(uint256 => uint256) internal _mintNumbers;

    constructor(address creator, uint16 redemptionRate_, uint16 redemptionMax_) ERC721SingleCreatorExtension(creator) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, LegacyInterfaces.IERC721CreatorCore_v1), 
                "Redeem: Minting reward contract must implement IERC721CreatorCore");
        _redemptionRate = redemptionRate_;
        _redemptionMax = redemptionMax_;
    }     

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(RedeemBase, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(IERC721RedeemBase).interfaceId || RedeemBase.supportsInterface(interfaceId) || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionMax}
     */
    function redemptionMax() external view virtual override returns(uint16) {
        return _redemptionMax;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRate}
     */
    function redemptionRate() external view virtual override returns(uint16) {
        return _redemptionRate;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRemaining}
     */
    function redemptionRemaining() public view virtual override returns(uint16) {
        return _redemptionMax-_redemptionCount;
    }

    /**
     * @dev See {IERC721RedeemBase-mintNumber}.
     */
    function mintNumber(uint256 tokenId) external view virtual override returns(uint256) {
        return _mintNumbers[tokenId];
    }

    /**
     * @dev See {IERC721RedeemBase-mintedTokens}.
     */
    function mintedTokens() external view override returns(uint256[] memory) {
        return _mintedTokens;
    }

    /**
     * @dev mint token that was redeemed for
     */
    function _mintRedemption(address to) internal virtual returns (uint256) {
        require(_redemptionCount < _redemptionMax, "Redeem: No redemptions remaining");
        _redemptionCount++;
        
        // Mint token
        uint256 tokenId = _mint(to, _redemptionCount);

        _mintedTokens.push(tokenId);
        _mintNumbers[tokenId] = _redemptionCount;
        return tokenId;
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16) internal virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";

import "../../libraries/single-creator/ERC721/ERC721SingleCreatorExtension.sol";

import "../RedeemSetBase.sol";
import "./IERC721RedeemSetBase.sol";

/**
 * @dev Redeem NFT base logic
 */
abstract contract ERC721RedeemSetBase is ERC721SingleCreatorExtension, RedeemSetBase, CreatorExtension, IERC721RedeemSetBase {

    uint16 private _redemptionMax;
    uint16 private _redemptionCount;
    uint256[] private _mintedTokens;
    mapping(uint256 => uint256) internal _mintNumbers;

    constructor(address creator, RedemptionItem[] memory redemptionSet, uint16 redemptionMax_) ERC721SingleCreatorExtension(creator) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, LegacyInterfaces.IERC721CreatorCore_v1), 
                "Redeem: Minting reward contract must implement IERC721CreatorCore");
        _redemptionMax = redemptionMax_;
        configureRedemptionSet(redemptionSet);
    }     

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(RedeemSetBase, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(IERC721RedeemSetBase).interfaceId || RedeemSetBase.supportsInterface(interfaceId) || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionMax}
     */
    function redemptionMax() external view virtual override returns(uint16) {
        return _redemptionMax;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRemaining}
     */
    function redemptionRemaining() public view virtual override returns(uint16) {
        return _redemptionMax-_redemptionCount;
    }

    /**
     * @dev See {IERC721RedeemBase-mintNumber}.
     */
    function mintNumber(uint256 tokenId) external view virtual override returns(uint256) {
        return _mintNumbers[tokenId];
    }

    /**
     * @dev See {IERC721RedeemBase-mintedTokens}.
     */
    function mintedTokens() external view override returns(uint256[] memory) {
        return _mintedTokens;
    }

    /**
     * @dev mint token that was redeemed for
     */
    function _mintRedemption(address to) internal virtual returns (uint256) {
        require(_redemptionCount < _redemptionMax, "Redeem: No redemptions remaining");
        _redemptionCount++;
        
        // Mint token
        uint256 tokenId = _mint(to, _redemptionCount);

        _mintedTokens.push(tokenId);
        _mintNumbers[tokenId] = _redemptionCount;
        return tokenId;
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16) internal virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721RedeemBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
interface IERC721BurnRedeem is IERC721RedeemBase {

    /**
     * @dev Enable recovery of a given token. Can only be called by contract owner/admin.
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function setERC721Recoverable(address contract_, uint256 tokenId, address recoverer) external;

    /**
     * @dev Recover a token.  Returns it to the recoverer set by setERC721Recoverable
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function recoverERC721(address contract_, uint256 tokenId) external;

    /**
     * @dev Redeem ERC721 tokens for redemption reward NFT.
     * Requires the user to grant approval beforehand by calling contract's 'approve' function.
     * If the it cannot redeem the NFT, it will clear approvals
     */
    function redeemERC721(address[] calldata contracts, uint256[] calldata tokenIds) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721RedeemSetBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT (Set)
 */
interface IERC721BurnRedeemSet is IERC721RedeemSetBase {

    /**
     * @dev Enable recovery of a given token. Can only be called by contract owner/admin.
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function setERC721Recoverable(address contract_, uint256 tokenId, address recoverer) external;

    /**
     * @dev Recover a token.  Returns it to the recoverer set by setERC721Recoverable
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function recoverERC721(address contract_, uint256 tokenId) external;

    /**
     * @dev Redeem ERC721 tokens for redemption reward NFT.
     * Requires the user to grant approval beforehand by calling contract's 'approve' function.
     * If the it cannot redeem the NFT, it will clear approvals
     */
    function redeemERC721(address[] calldata contracts, uint256[] calldata tokenIds) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../IRedeemBase.sol";

/**
 * @dev Base redemption interface
 */
interface IERC721RedeemBase is IRedeemBase {
    /**
     * @dev Get the max number of redemptions
     */
    function redemptionMax() external view returns(uint16);

    /**
     * @dev Get the redemption rate
     */
    function redemptionRate() external view returns(uint16);

    /**
     * @dev Get number of redemptions left
     */
    function redemptionRemaining() external view returns(uint16);

    /**
     * @dev Get the mint number of a created token id
     */
    function mintNumber(uint256 tokenId) external view returns(uint256);

    /**
     * @dev Get list of all minted tokens
     */
    function mintedTokens() external view returns(uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../IRedeemSetBase.sol";

/**
 * @dev Base redemption interface
 */
interface IERC721RedeemSetBase is IRedeemSetBase {
    /**
     * @dev Get the max number of redemptions
     */
    function redemptionMax() external view returns(uint16);
    
    /**
     * @dev Get number of redemptions left
     */
    function redemptionRemaining() external view returns(uint16);

    /**
     * @dev Get the mint number of a created token id
     */
    function mintNumber(uint256 tokenId) external view returns(uint256);

    /**
     * @dev Get list of all minted tokens
     */
    function mintedTokens() external view returns(uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

/**
 * @dev Base redemption interface
 */
interface IRedeemBase is IAdminControl {

    event UpdateApprovedContracts(address[] contracts, bool[] approved);
    event UpdateApprovedTokens(address contract_, uint256[] tokenIds, bool[] approved);
    event UpdateApprovedTokenRanges(address contract_, uint256[] minTokenIds, uint256[] maxTokenIds);

    /**
     * @dev Update approved contracts that can be used to redeem. Can only be called by contract owner/admin.
     */
    function updateApprovedContracts(address[] calldata contracts, bool[] calldata approved) external;

    /**
     * @dev Update approved tokens that can be used to redeem. Can only be called by contract owner/admin.
     */
    function updateApprovedTokens(address contract_, uint256[] calldata tokenIds, bool[] calldata approved) external;

    /**
     * @dev Update approved token ranges that can be used to redeem. Can only be called by contract owner/admin.
     * Clears out old ranges
     */
    function updateApprovedTokenRanges(address contract_, uint256[] calldata minTokenIds, uint256[] calldata maxTokenIds) external;

    /**
     * @dev Check if an NFT is redeemable
     */
    function redeemable(address contract_, uint256 tokenId) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

/**
 * @dev Base redemption interface
 */
interface IRedeemSetBase is IAdminControl {

    event RedeemSetApprovedTokenRange(address tokenAddress, uint256 minTokenId, uint256 maxTokenId);
    
    struct RedemptionItem {
        address tokenAddress;
        uint256 minTokenId;
        uint256 maxTokenId;
    }

    /**
     * @dev Get the attributes of the complete set needed for redemption
     */
    function getRedemptionSet() external view returns(RedemptionItem[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./IRedeemBase.sol";

struct range{
   uint256 min;
   uint256 max;
}

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
abstract contract RedeemBase is AdminControl, IRedeemBase {
     using EnumerableSet for EnumerableSet.UintSet;

     // approved contract tokens
    mapping(address => bool) internal _approvedContracts;

    // approved specific tokens
    mapping(address => EnumerableSet.UintSet) internal _approvedTokens;
    mapping(address => range[]) internal _approvedTokenRange;
     
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IRedeemBase).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedContracts}
     */
    function updateApprovedContracts(address[] memory contracts, bool[] memory approved) public virtual override adminRequired {
        require(contracts.length == approved.length, "Redeem: Invalid input parameters");
        for (uint i=0; i < contracts.length; i++) {
            _approvedContracts[contracts[i]] = approved[i];
        }
        emit UpdateApprovedContracts(contracts, approved);
    }
    
    /**
     * @dev See {IRedeemBase-updateApprovedTokens}
     */
    function updateApprovedTokens(address contract_, uint256[] memory tokenIds, bool[] memory approved) public virtual override adminRequired {
        require(tokenIds.length == approved.length, "Redeem: Invalid input parameters");

        for (uint i=0; i < tokenIds.length; i++) {
            if (approved[i] && !_approvedTokens[contract_].contains(tokenIds[i])) {
                _approvedTokens[contract_].add(tokenIds[i]);
            } else if (!approved[i] && _approvedTokens[contract_].contains(tokenIds[i])) {
                _approvedTokens[contract_].remove(tokenIds[i]);
            }
        }
        emit UpdateApprovedTokens(contract_, tokenIds, approved);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedTokenRanges}
     */
    function updateApprovedTokenRanges(address contract_, uint256[] memory minTokenIds, uint256[] memory maxTokenIds) public virtual override adminRequired {
        require(minTokenIds.length == maxTokenIds.length, "Redeem: Invalid input parameters");
        delete _approvedTokenRange[contract_];
        for (uint i=0; i < minTokenIds.length; i++) {
            require(minTokenIds[i] < maxTokenIds[i], "Redeem: min must be less than max");
            _approvedTokenRange[contract_].push(range(minTokenIds[i], maxTokenIds[i]));
        }
        emit UpdateApprovedTokenRanges(contract_, minTokenIds, maxTokenIds);
    }

    /**
     * @dev See {IRedeemBase-redeemable}
     */    
    function redeemable(address contract_, uint256 tokenId) public view virtual override returns(bool) {
         if (_approvedContracts[contract_]) {
             return true;
         }
         if (_approvedTokens[contract_].contains(tokenId)) {
             return true;
         }
         if (_approvedTokenRange[contract_].length > 0) {
             for (uint i=0; i < _approvedTokenRange[contract_].length; i++) {
                 if (_approvedTokenRange[contract_][i].max != 0 && tokenId >= _approvedTokenRange[contract_][i].min && tokenId <= _approvedTokenRange[contract_][i].max) {
                     return true;
                 }
             }
         }
         return false;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./IRedeemSetBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT (set)
 */
abstract contract RedeemSetBase is AdminControl, IRedeemSetBase {
    // approved specific tokens
    RedemptionItem[] private _redemptionSet;

    function configureRedemptionSet(RedemptionItem[] memory redemptionSet) internal {
      for (uint i = 0; i < redemptionSet.length; i++) {
          RedemptionItem memory redemptionItem = redemptionSet[i];
          require(redemptionItem.minTokenId <= redemptionItem.maxTokenId, "Redeem: min must be less or equal to max");
          _redemptionSet.push(redemptionItem);
          emit RedeemSetApprovedTokenRange(redemptionItem.tokenAddress, redemptionItem.minTokenId, redemptionItem.maxTokenId);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IRedeemSetBase).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRedeemSetBase-getRedemptionSet}
     */
    function getRedemptionSet() external override view returns(RedemptionItem[] memory) {
        return _redemptionSet;
    }

    /**
     * @dev Check to see if we have a complete redemption set
     */
    function _validateCompleteSet(address[] memory contracts, uint256[] memory tokenIds) internal view virtual returns (bool) {
       require(_redemptionSet.length == tokenIds.length, "Incorrect number of NFTs being redeemed");
       // Check complete set
       bool[] memory completions = new bool[](_redemptionSet.length);
       for (uint i = 0; i < contracts.length; i++) {
           for (uint j = 0; j < _redemptionSet.length; j++) {
               RedemptionItem memory redemptionItem = _redemptionSet[j];
               if (contracts[i] == redemptionItem.tokenAddress && tokenIds[i] >= redemptionItem.minTokenId && tokenIds[i] <= redemptionItem.maxTokenId) {
                   // Found redemption token
                   completions[j] = true;
                   break;
               }
           }
       }
       for (uint i = 0; i < completions.length; i++) {
           if (!completions[i]) return false;
       }
       return true;
    }

}