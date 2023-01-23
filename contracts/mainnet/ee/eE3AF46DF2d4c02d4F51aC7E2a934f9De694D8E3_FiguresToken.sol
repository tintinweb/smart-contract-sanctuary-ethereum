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
import "../extensions/ICreatorExtensionRoyalties.sol";

import "./ICreatorCore.sol";

/**
 * @dev Core creator implementation
 */
abstract contract CreatorCore is ReentrancyGuard, ICreatorCore, ERC165 {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AddressUpgradeable for address;

    uint256 internal _tokenCount = 0;

    // Base approve transfers address location
    address internal _approveTransferBase;

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
    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }
    mapping (address => RoyaltyConfig[]) internal _extensionRoyalty;
    mapping (uint256 => RoyaltyConfig[]) internal _tokenRoyalty;

    bytes4 private constant _CREATOR_CORE_V1 = 0x28f10a21;

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
        return interfaceId == type(ICreatorCore).interfaceId || interfaceId == _CREATOR_CORE_V1 || super.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE
            || interfaceId == _INTERFACE_ID_ROYALTIES_FOUNDATION || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    function requireExtension() internal view {
        require(_extensions.contains(msg.sender), "Must be registered extension");
    }

    /**
     * @dev Only allows non-blacklisted extensions
     */
    function requireNonBlacklist(address extension) internal view {
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }   

    /**
     * @dev See {ICreatorCore-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory extensions) {
        extensions = new address[](_extensions.length());
        for (uint i; i < _extensions.length();) {
            extensions[i] = _extensions.at(i);
            unchecked { ++i; }
        }
        return extensions;
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal {
        require(extension != address(this) && extension.isContract(), "Invalid");
        emit ExtensionRegistered(extension, msg.sender);
        _extensionBaseURI[extension] = baseURI;
        _extensionBaseURIIdentical[extension] = baseURIIdentical;
        _extensions.add(extension);
        _setApproveTransferExtension(extension, true);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override {
        requireExtension();
        _setApproveTransferExtension(msg.sender, enabled);
    }

    /**
     * @dev Set whether or not tokens minted by the extension defers transfer approvals to the extension
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal virtual;

    /**
     * @dev Unregister an extension
     */
    function _unregisterExtension(address extension) internal {
        emit ExtensionUnregistered(extension, msg.sender);
        _extensions.remove(extension);
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
    function _getRoyalties(uint256 tokenId) view internal returns (address payable[] memory receivers, uint256[] memory bps) {

        // Get token level royalties
        RoyaltyConfig[] memory royalties = _tokenRoyalty[tokenId];
        if (royalties.length == 0) {
            // Get extension specific royalties
            address extension = _tokensExtension[tokenId];
            if (extension != address(0)) {
                if (ERC165Checker.supportsInterface(extension, type(ICreatorExtensionRoyalties).interfaceId)) {
                    (receivers, bps) = ICreatorExtensionRoyalties(extension).getRoyalties(address(this), tokenId);
                    // Extension override exists, just return that
                    if (receivers.length > 0) return (receivers, bps);
                }
                royalties = _extensionRoyalty[extension];
            }
        }
        if (royalties.length == 0) {
            // Get the default royalty
            royalties = _extensionRoyalty[address(0)];
        }
        
        if (royalties.length > 0) {
            receivers = new address payable[](royalties.length);
            bps = new uint256[](royalties.length);
            for (uint i; i < royalties.length;) {
                receivers[i] = royalties[i].receiver;
                bps[i] = royalties[i].bps;
                unchecked { ++i; }
            }
        }
    }

    /**
     * Helper to get royalty receivers for a token
     */
    function _getRoyaltyReceivers(uint256 tokenId) view internal returns (address payable[] memory recievers) {
        (recievers, ) = _getRoyalties(tokenId);
    }

    /**
     * Helper to get royalty basis points for a token
     */
    function _getRoyaltyBPS(uint256 tokenId) view internal returns (uint256[] memory bps) {
        (, bps) = _getRoyalties(tokenId);
    }

    function _getRoyaltyInfo(uint256 tokenId, uint256 value) view internal returns (address receiver, uint256 amount){
        (address payable[] memory receivers, uint256[] memory bps) = _getRoyalties(tokenId);
        require(receivers.length <= 1, "More than 1 royalty receiver");
        
        if (receivers.length == 0) {
            return (address(this), 0);
        }
        return (receivers[0], bps[0]*value/10000);
    }

    /**
     * Set royalties for a token
     */
    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
       _checkRoyalties(receivers, basisPoints);
        delete _tokenRoyalty[tokenId];
        _setRoyalties(receivers, basisPoints, _tokenRoyalty[tokenId]);
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    /**
     * Set royalties for all tokens of an extension
     */
    function _setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) internal {
        _checkRoyalties(receivers, basisPoints);
        delete _extensionRoyalty[extension];
        _setRoyalties(receivers, basisPoints, _extensionRoyalty[extension]);
        if (extension == address(0)) {
            emit DefaultRoyaltiesUpdated(receivers, basisPoints);
        } else {
            emit ExtensionRoyaltiesUpdated(extension, receivers, basisPoints);
        }
    }

    /**
     * Helper function to check that royalties provided are valid
     */
    function _checkRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) private pure {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i; i < basisPoints.length;) {
            totalBasisPoints += basisPoints[i];
            unchecked { ++i; }
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }

    /**
     * Helper function to set royalties
     */
    function _setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints, RoyaltyConfig[] storage royalties) private {
        for (uint i; i < basisPoints.length;) {
            royalties.push(
                RoyaltyConfig(
                    {
                        receiver: receivers[i],
                        bps: uint16(basisPoints[i])
                    }
                )
            );
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {ICreatorCore-getApproveTransfer}.
     */
    function getApproveTransfer() external view override returns (address) {
        return _approveTransferBase;
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

    uint256 constant public VERSION = 2;

    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCore).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {CreatorCore-_setApproveTransferExtension}
     */
    function _setApproveTransferExtension(address extension, bool enabled) internal override {
        if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionApproveTransfer).interfaceId)) {
            _extensionApproveTransfers[extension] = enabled;
            emit ExtensionApproveTransferUpdated(extension, enabled);
        }
    }

    /**
     * @dev Set the base contract's approve transfer contract location
     */
    function _setApproveTransferBase(address extension) internal {
        _approveTransferBase = extension;
        emit ApproveTransferUpdated(extension);
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "CreatorCore: Invalid extension");
        require(permissions == address(0) || ERC165Checker.supportsInterface(permissions, type(IERC721CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * Check if an extension can mint
     */
    function _checkMintPermissions(address to, uint256 tokenId) internal {
        if (_extensionPermissions[msg.sender] != address(0)) {
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
           require(IERC721CreatorExtensionApproveTransfer(_tokensExtension[tokenId]).approveTransfer(msg.sender, from, to, tokenId), "Extension approval failure");
       } else if (_approveTransferBase != address(0)) {
          require(IERC721CreatorExtensionApproveTransfer(_approveTransferBase).approveTransfer(msg.sender, from, to, tokenId), "Extension approval failure");
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
    event ApproveTransferUpdated(address extension);
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

    /**
     * @dev Set the default approve transfer contract location.
     */
    function setApproveTransfer(address extension) external; 

    /**
     * @dev Get the default approve transfer contract location.
     */
    function getApproveTransfer() external view returns (address);
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
    function registerExtension(address extension, string calldata baseURI) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired {
        requireNonBlacklist(extension);
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
    function setBaseTokenURIExtension(string calldata uri) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external override {
        requireExtension();
        _setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override {
        requireExtension();
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external override {
        requireExtension();
        _setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override {
        requireExtension();
        require(tokenIds.length == uris.length, "Invalid input");
        for (uint i; i < tokenIds.length;) {
            _setTokenURIExtension(tokenIds[i], uris[i]);
            unchecked { ++i; }
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
        for (uint i; i < tokenIds.length;) {
            _setTokenURI(tokenIds[i], uris[i]);
            unchecked { ++i; }
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
        for (uint16 i = 0; i < count;) {
            tokenIds[i] = _mintBase(to, "");
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i; i < uris.length;) {
            tokenIds[i] = _mintBase(to, uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @dev Mint token with no extension
     */
    function _mintBase(address to, string memory uri) internal virtual returns(uint256 tokenId) {
        ++_tokenCount;
        tokenId = _tokenCount;

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        // Call post mint
        _postMintBase(to, tokenId);
    }


    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, "");
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, string calldata uri) public virtual override nonReentrant returns(uint256) {
        requireExtension();
        return _mintExtension(to, uri);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count;) {
            tokenIds[i] = _mintExtension(to, "");
            unchecked { ++i; }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] calldata uris) public virtual override nonReentrant returns(uint256[] memory tokenIds) {
        requireExtension();
        tokenIds = new uint256[](uris.length);
        for (uint i; i < uris.length;) {
            tokenIds[i] = _mintExtension(to, uris[i]);
            unchecked { ++i; }
        }
    }
    
    /**
     * @dev Mint token via extension
     */
    function _mintExtension(address to, string memory uri) internal virtual returns(uint256 tokenId) {
        ++_tokenCount;
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

    /**
     * @dev See {ICreatorCore-setApproveTransfer}.
     */
    function setApproveTransfer(address extension) external override adminRequired {
        _setApproveTransferBase(extension);
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
    function approveTransfer(address operator, address from, address to, uint256 tokenId) external returns (bool);
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
 * @dev Implement this if you want your extension to have overloadable royalties
 */
interface ICreatorExtensionRoyalties is IERC165 {

    /**
     * Get the royalties for a given creator/tokenId
     */
    function getRoyalties(address creator, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
        address owner = ERC721.ownerOf(tokenId);
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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
library Counters {
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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

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
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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

pragma solidity ^0.8.1;

library Figure0DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000011111111001111111100000000000000000000000000000000111111100011111110000000000000000000000000000000000111111100011111110000000000000000000000000000000011111100001111110000000000000000000000000000000000011111100001111110000000000000000000000000000000000011111100001111110000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000111111110011111111001111111100000000000000000000001111111000111111100011111110000000000000000000000001111111000111111100011111110000000000000000000000111111000011111100001111110000000000000000000000000111111000011111100001111110000000000000000000000000111111000011111100001111110000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000111000000011100000001110000000000000000000000000000111000000011100000001110000000000000000000000000000111000000011100000001110000000000000000000000000000111000000011100000001110000000000000000000000000000111000000011100000001110000000000000000000000000000111000000011100000001110000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000001111111100111111110011111111001111111100000000000011111110001111111000111111100011111110000000000000011111110001111111000111111100011111110000000000001111110000111111000011111100001111110000000000000001111110000111111000011111100001111110000000000000001111110000111111000011111100001111110000000000001111100000111110000011111000001111100000000000000001111100000111110000011111000001111100000000000000001111100000111110000011111000001111100000000000000001111100000111110000011111000001111100000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000001110000000111000000011100000001110000000000000000001110000000111000000011100000001110000000000000000001110000000111000000011100000001110000000000000000001110000000111000000011100000001110000000000000000001110000000111000000011100000001110000000000000000001110000000111000000011100000001110000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010";
    }

    function S2() public pure returns (string memory) {
        return
            "010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000000000000010000000001000000000100000000010000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000000000001100000000110000000011000000001100000000000011100000001110000000111000000011100000000000000000011100000001110000000111000000011100000000000000000011100000001110000000111000000011100000000000000000011100000001110000000111000000011100000000000000000011100000001110000000111000000011100000000000000000011100000001110000000111000000011100000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000000000011110000001111000000111100000011110000000000001111100000111110000011111000001111100000000000000001111100000111110000011111000001111100000000000000001111100000111110000011111000001111100000000000000001111100000111110000011111000001111100000000000011111100001111110000111111000011111100000000000000011111100001111110000111111000011111100000000000000011111100001111110000111111000011111100000000000011111110001111111000111111100011111110000000000000011111110001111111000111111100011111110000000000001111111100111111110011111111001111111100000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000000000000010000000001000000000100000000000000000000001100000000110000000011000000000000000000000000000001100000000110000000011000000000000000000000000000001100000000110000000011000000000000000000000000000001100000000110000000011000000000000000000000000000001100000000110000000011000000000000000000000000000001100000000110000000011000000000000000000000000000001100000000110000000011000000000000000000000011100000001110000000111000000000000000000000000000011100000001110000000111000000000000000000000000000011100000001110000000111000000000000000000000000000011100000001110000000111000000000000000000000000000011100000001110000000111000000000000000000000000000011100000001110000000111000000000000000000000011110000001111000000111100000000000000000000000000011110000001111000000111100000000000000000000000000011110000001111000000111100000000000000000000000000011110000001111000000111100000000000000000000000000011110000001111000000111100000000000000000000001111100000111110000011111000000000000000000000000001111100000111110000011111000000000000000000000000001111100000111110000011111000000000000000000000000001111100000111110000011111000000000000000000000011111100001111110000111111000000000000000000000000011111100001111110000111111000000000000000000000000011111100001111110000111111000000000000000000000011111110001111111000111111100000000000000000000000011111110001111111000111111100000000000000000000001111111100111111110011111111000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000000000000010000000001000000000000000000000000000000001100000000110000000000000000000000000000000000000001100000000110000000000000000000000000000000000000001100000000110000000000000000000000000000000000000001100000000110000000000000000000000000000000000000001100000000110000000000000000000000000000000000000001100000000110000000000000000000000000000000000000001100000000110000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000000000011100000001110000000000000000000000000000000011110000001111000000000000000000000000000000000000011110000001111000000000000000000000000000000000000011110000001111000000000000000000000000000000000000011110000001111000000000000000000000000000000000000011110000001111000000000000000000000000000000001111100000111110000000000000000000000000000000000001111100000111110000000000000000000000000000000000001111100000111110000000000000000000000000000000000001111100000111110000000000000000000000000000000011111100001111110000000000000000000000000000000000011111100001111110000000000000000000000000000000000011111100001111110000000000000000000000000000000011111110001111111000000000000000000000000000000000011111110001111111000000000000000000000000000000001111111100111111110000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure1DigitLib {
    function S1() public pure returns (string memory) {
        return
            "00000000011000000001100000000110000000011000000001000000000100000000011000000001100000000110000000010000000001000000000100000000011000000001100000000100000000010000000001000000000100000000011000000001000000000111000000011100000001110000000111000000010000000001000000000111000000011100000001110000000100000000010000000001000000000111000000011100000001000000000100000000010000000001000000000111000000010000000001111000000111100000011110000001111000000100000000010000000001111000000111100000011110000001000000000100000000010000000001111000000111100000010000000001000000000100000000010000000001111000000100000000111110000011111000001111100000111110000011000000001100000000111110000011111000001111100000110000000011000000001100000000111110000011111000001100000000110000000011000000001100000000111110000011000000011111100001111110000111111000011111100001110000000111000000011111100001111110000111111000011100000001110000000111000000011111100001111110000111000000011100000001110000000111000000011111100001110000000011110000001111000000111100000011110000001100000000110000000011110000001111000000111100000011000000001100000000110000000011110000001111000000110000000011000000001100000000110000000011110000001100000000111000000011100000001110000000111000000011000000001100000000111000000011100000001110000000110000000011000000001100000000111000000011100000001100000000110000000011000000001100000000111000000011";
    }

    function S2() public pure returns (string memory) {
        return
            "10000000011000000001100000000110000000010000000000100000000110000000011000000001000000000000000000001000000001100000000100000000000000000000000000000010000000010000000000000000000000000000000000000000110000000111000000011100000001110000000100000000001100000001110000000111000000010000000000000000000011000000011100000001000000000000000000000000000000110000000100000000000000000000000000000000000000001110000001111000000111100000011110000001000000000011100000011110000001111000000100000000000000000000111000000111100000010000000000000000000000000000001110000001000000000000000000000000000000000000000011100000111110000011111000001111100000110000000000111000001111100000111110000011000000000000000000001110000011111000001100000000000000000000000000000011100000110000000000000000000000000000000000000000111000011111100001111110000111111000011100000000001110000111111000011111100001110000000000000000000011100001111110000111000000000000000000000000000000111000011100000000000000000000000000000000000000001100000011110000001111000000111100000011000000000011000000111100000011110000001100000000000000000000110000001111000000110000000000000000000000000000001100000011000000000000000000000000000000000000000010000000111000000011100000001110000000110000000000100000001110000000111000000011000000000000000000001000000011100000001100000000000000000000000000000010000000110000000000000000000000000000000000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure2DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000011111111101111111110111111111000000000000000000000111111110011111111001111111100000000000000000000001111111000111111100011111110000000000000000000000011111100001111110000111111000000000000000000000000111110000011111000001111100000000000000000000000001111000000111100000011110000000000000000000000000011100000001110000000111000000000000000000000000000110000000011000000001100000000000000000000000000001000000000100000000010000000000000000000000000000011111111101111111110000000000000000000000000000000111111110011111111000000000000000000000000000000001111111000111111100000000000000000000000000000000011111100001111110000000000000000000000000000000000111110000011111000000000000000000000000000000000001111000000111100000000000000000000000000000000000011100000001110000000000000000000000000000000000000110000000011000000000000000000000000000000000000001000000000100000000000000000000000000000000000000000000000001111111110111111111000000000000000000000000000000011111111001111111100000000000000000000000000000000111111100011111110000000000000000000000000000000001111110000111111000000000000000000000000000000000011111000001111100000000000000000000000000000000000111100000011110000000000000000000000000000000000001110000000111000000000000000000000000000000000000011000000001100000000000000000000000000000000000000100000000010000000000000000000000000000011111111100000000000000000000000000000000000000000111111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000111111111000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000010000000000000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000000000000010000000001000000000100000000000000000000000000001100000000110000000011000000000000000000000000000111000000011100000001110000000000000000000000000011110000001111000000111100000000000000000000000001111100000111110000011111000000000000000000000000111111000011111100001111110000000000000000000000011111110001111111000111111100000000000000000000001111111100111111110011111111000000000000000000000111111111011111111101111111110000000000000000000000000000010000000001000000000000000000000000000000000000001100000000110000000000000000000000000000000000000111000000011100000000000000000000000000000000000011110000001111000000000000000000000000000000000001111100000111110000000000000000000000000000000000111111000011111100000000000000000000000000000000011111110001111111000000000000000000000000000000001111111100111111110000000000000000000000000000000111111111011111111100000000000000000000000000000000000000000000000001000000000100000000000000000000000000000000000000110000000011000000000000000000000000000000000000011100000001110000000000000000000000000000000000001111000000111100000000000000000000000000000000000111110000011111000000000000000000000000000000000011111100001111110000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000011111111101111111110000000000000000000000000000010000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000001111111110000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure3DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000011111111101111111110111111111000000000000000000000111111110011111111001111111100000000000000000000001111111000111111100011111110000000000000000000000011111100001111110000111111000000000000000000000000111110000011111000001111100000000000000000000000001111000000111100000011110000000000000000000000000011100000001110000000111000000000000000000000000000110000000011000000001100000000000000000000000000001000000000100000000010000000000000000000000000000011111111101111111110000000000000000000000000000000111111110011111111000000000000000000000000000000001111111000111111100000000000000000000000000000000011111100001111110000000000000000000000000000000000111110000011111000000000000000000000000000000000001111000000111100000000000000000000000000000000000011100000001110000000000000000000000000000000000000110000000011000000000000000000000000000000000000001000000000100000000000000000000000000000000000000000000000001111111110111111111000000000000000000000000000000011111111001111111100000000000000000000000000000000111111100011111110000000000000000000000000000000001111110000111111000000000000000000000000000000000011111000001111100000000000000000000000000000000000111100000011110000000000000000000000000000000000001110000000111000000000000000000000000000000000000011000000001100000000000000000000000000000000000000100000000010000000000000000000000000000011111111100000000000000000000000000000000000000000111111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000111111111000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000010000000000000000000";
    }

    function S2() public pure returns (string memory) {
        return S1();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure4DigitLib {
    function S1() public pure returns (string memory) {
        return
            "011111110101111111010111111101011111110100000000000111111101011111110101111111010000000000000000000001111111010111111101000000000000000000000000000000011111101101111110110111111011011111101100000000000111111011011111101101111110110000000000000000000001111110110111111011000000000000000000000000000000011111011101111101110111110111011111011100000000000111110111011111011101111101110000000000000000000001111101110111110111000000000000000000000000000000011110111101111011110111101111011110111100000000000111101111011110111101111011110000000000000000000001111011110111101111000000000000000000000000000000001111110100111111010011111101001111110100000000000011111101001111110100111111010000000000000000000000111111010011111101000000000000000000000000000000001111101100111110110011111011001111101100000000000011111011001111101100111110110000000000000000000000111110110011111011000000000000000000000000000000001111011100111101110011110111001111011100000000000011110111001111011100111101110000000000000000000000111101110011110111000000000000000000000000000000001110111100111011110011101111001110111100000000000011101111001110111100111011110000000000000000000000111011110011101111000000000000000000000000000000000111110100011111010001111101000111110100000000000001111101000111110100011111010000000000000000000000011111010001111101000000000000000000000000000000000111101100011110110001111011000111101100000000000001111011000111101100011110110000000000000000000000011110110001111011000000000000000000000000000000000111011100011101110001110111000111011100000000000001110111000111011100011101110000000000000000000000011101110001110111000000000000000000000000000000000110111100011011110001101111000110111100000000000001101111000110111100011011110000000000000000000000011011110001101111000000000000000000000000000000000011110100001111010000111101000011110100000000000000111101000011110100001111010000000000000000000000001111010000111101000000000000000000000000000000000011101100001110110000111011000011101100000000000000111011000011101100001110110000000000000000000000001110110000111011000000000000000000000000000000000011011100001101110000110111000011011100000000000000110111000011011100001101110000000000000000000000001101110000110111000000000000000000000000000000000010111100001011110000101111000010111100000000000000101111000010111100001011110000000000000000000000001011110000101111000000000000000000000000000000011111100101111110010111111001011111100100000000000111111001011111100101111110010000000000000000000001111110010111111001000000000000000000000000000000011111001101111100110111110011011111001100000000000111110011011111001101111100110000000000000000000001111100110111110011000000000000000000000000000000011110011101111001110111100111011110011100000000000111100111011110011101111001110000000000000000000001111001110111100111000000000000000000000000000000011110001101111000110111100011011110001100000000000111100011011110001101111000110000000000000000000001111000110111100011000000000000000000000000000000011111000101111100010111110001011111000100000000000111110001011111000101111100010000000000000000000001111100010111110001000000000000000000000000000000001111100100111110010011111001001111100100000000000011111001001111100100111110010000000000000000000000111110010011111001000000000000000000000000000000001111001100111100110011110011001111001100000000000011110011001111001100111100110000000000000000000000111100110011110011000000000000000000000000000000001110011100111001110011100111001110011100000000000011100111001110011100111001110000000000000000000000111001110011100111000000000000000000000000000000001110001100111000110011100011001110001100000000000011100011001110001100111000110000000000000000000000111000110011100011000000000000000000000000000000001111000100111100010011110001001111000100000000000011110001001111000100111100010000000000000000000000111100010011110001000000000000000000000000000000000111100100011110010001111001000111100100000000000001111001000111100100011110010000000000000000000000011110010001111001000000000000000000000000000000000111001100011100110001110011000111001100000000000001110011000111001100011100110000000000000000000000011100110001110011000000000000000000000000000000000110011100011001110001100111000110011100000000000001100111000110011100011001110000000000000000000000011001110001100111000000000000000000000000000000000110001100011000110001100011000110001100000000000001100011000110001100011000110000000000000000000000011000110001100011000000000000000000000000000000000111000100011100010001110001000111000100000000000001110001000111000100011100010000000000000000000000011100010001110001000000000000000000000000000000000011100100001110010000111001000011100100000000000000111001000011100100001110010000000000000000000000001110010000111001000000000000000000000000000000000011001100001100110000110011000011001100000000000000110011000011001100001100110000000000000000000000001100110000110011000000000000000000000000000000000010011100001001110000100111000010011100000000000000100111000010011100001001110000000000000000000000001001110000100111000000000000000000000000000000000010001100001000110000100011000010001100000000000000100011000010001100001000110000000000000000000000001000110000100011000000000000000000000000000000000011000100001100010000110001000011000100000000000000110001000011000100001100010000000000000000000000001100010000110001000000000000000000000000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000011111111011111111101111111110111111111010000000000111111101111111110111111111011111111101100000000001111110111111111011111111101111111110111000000000011111011111111101111111110111111111011110000000000000000000011111111011111111101111111110100000000000000000000111111101111111110111111111011000000000000000000001111110111111111011111111101110000000000000000000011111011111111101111111110111100000000000000000000000000000011111111011111111101000000000000000000000000000000111111101111111110110000000000000000000000000000001111110111111111011100000000000000000000000000000011111011111111101111000000000011111110011111111001111111100111111110010000000000111111001111111100111111110011111111001100000000001111100111111110011111111001111111100111000000000000000000001111111001111111100111111110010000000000000000000011111100111111110011111111001100000000000000000000111110011111111001111111100111000000000000000000000000000000111111100111111110010000000000000000000000000000001111110011111111001100000000000000000000000000000011111001111111100111000000000011111100011111110001111111000111111100010000000000111110001111111000111111100011111110001100000000000000000000111111000111111100011111110001000000000000000000001111100011111110001111111000110000000000000000000000000000001111110001111111000100000000000000000000000000000011111000111111100011000000000011111000011111100001111110000111111000010000000000000000000011111000011111100001111110000100000000000000000000000000000011111000011111100001";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure5DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000000000000010000000001000000000100000000000000000000000000001100000000110000000011000000000000000000000000000111000000011100000001110000000000000000000000000011110000001111000000111100000000000000000000000001111100000111110000011111000000000000000000000000111111000011111100001111110000000000000000000000011111110001111111000111111100000000000000000000001111111100111111110011111111000000000000000000000111111111011111111101111111110000000000000000000000000000010000000001000000000000000000000000000000000000001100000000110000000000000000000000000000000000000111000000011100000000000000000000000000000000000011110000001111000000000000000000000000000000000001111100000111110000000000000000000000000000000000111111000011111100000000000000000000000000000000011111110001111111000000000000000000000000000000001111111100111111110000000000000000000000000000000111111111011111111100000000000000000000000000000000000000000000000001000000000100000000000000000000000000000000000000110000000011000000000000000000000000000000000000011100000001110000000000000000000000000000000000001111000000111100000000000000000000000000000000000111110000011111000000000000000000000000000000000011111100001111110000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000011111111101111111110000000000000000000000000000010000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000001111111110000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000011111111101111111110111111111000000000000000000000111111110011111111001111111100000000000000000000001111111000111111100011111110000000000000000000000011111100001111110000111111000000000000000000000000111110000011111000001111100000000000000000000000001111000000111100000011110000000000000000000000000011100000001110000000111000000000000000000000000000110000000011000000001100000000000000000000000000001000000000100000000010000000000000000000000000000011111111101111111110000000000000000000000000000000111111110011111111000000000000000000000000000000001111111000111111100000000000000000000000000000000011111100001111110000000000000000000000000000000000111110000011111000000000000000000000000000000000001111000000111100000000000000000000000000000000000011100000001110000000000000000000000000000000000000110000000011000000000000000000000000000000000000001000000000100000000000000000000000000000000000000000000000001111111110111111111000000000000000000000000000000011111111001111111100000000000000000000000000000000111111100011111110000000000000000000000000000000001111110000111111000000000000000000000000000000000011111000001111100000000000000000000000000000000000111100000011110000000000000000000000000000000000001110000000111000000000000000000000000000000000000011000000001100000000000000000000000000000000000000100000000010000000000000000000000000000011111111100000000000000000000000000000000000000000111111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000111111111000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000010000000000000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure6DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000000000000010000000001000000000100000000000000000000000000001100000000110000000011000000000000000000000000000111000000011100000001110000000000000000000000000011110000001111000000111100000000000000000000000001111100000111110000011111000000000000000000000000111111000011111100001111110000000000000000000000011111110001111111000111111100000000000000000000001111111100111111110011111111000000000000000000000111111111011111111101111111110000000000000000000000000000010000000001000000000000000000000000000000000000001100000000110000000000000000000000000000000000000111000000011100000000000000000000000000000000000011110000001111000000000000000000000000000000000001111100000111110000000000000000000000000000000000111111000011111100000000000000000000000000000000011111110001111111000000000000000000000000000000001111111100111111110000000000000000000000000000000111111111011111111100000000000000000000000000000000000000000000000001000000000100000000000000000000000000000000000000110000000011000000000000000000000000000000000000011100000001110000000000000000000000000000000000001111000000111100000000000000000000000000000000000111110000011111000000000000000000000000000000000011111100001111110000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000011111111101111111110000000000000000000000000000010000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000111111111000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000011111111100000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000001111111110000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000001111111000111111100011111110000000000000000000000001111111000111111100011111110000000000000000000000111111110011111111001111111100000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000001111111000111111100000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000111111100011111110000000000000000000000000000000000111111100011111110000000000000000000000000000000011111111001111111100000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure7DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000000000000001111111100111111110011111111000000000000000000000011111110001111111000111111100000000000000000000000111111000011111100001111110000000000000000000000001111100000111110000011111000000000000000000000000011110000001111000000111100000000000000000000000000111000000011100000001110000000000000000000000000000000000000111111110011111111000000000000000000000000000000001111111000111111100000000000000000000000000000000011111100001111110000000000000000000000000000000000111110000011111000000000000000000000000000000000001111000000111100000000000000000000000000000000000011100000001110000000000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000001110000000";
    }

    function S2() public pure returns (string memory) {
        return
            "111111110011111111001111111100111111110011111111001111111000111111100011111110001111111000111111100011111100001111110000111111000011111100001111110000111110000011111000001111100000111110000011111000001111000000111100000011110000001111000000111100000011100000001110000000111000000011100000001110000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure8DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000001111111000111111100011111110000000000000000000000001111111000111111100011111110000000000000000000000111111110011111111001111111100000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000001111111000111111100000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000111111100011111110000000000000000000000000000000000111111100011111110000000000000000000000000000000011111111001111111100000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000001111111000111111100011111110000000000000000000000001111111000111111100011111110000000000000000000000111111110011111111001111111100000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000001111111000111111100000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000111111100011111110000000000000000000000000000000000111111100011111110000000000000000000000000000000011111111001111111100000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Figure9DigitLib {
    function S1() public pure returns (string memory) {
        return
            "000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000000000001000000000100000000010000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000000000000110000000011000000001100000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000000000001110000000111000000011100000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000000001111000000111100000011110000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000000000111110000011111000001111100000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000000001111110000111111000011111100000000000000000000001111111000111111100011111110000000000000000000000001111111000111111100011111110000000000000000000000111111110011111111001111111100000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000000000001000000000100000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000000000000110000000011000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000000000001110000000111000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000000001111000000111100000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000000000111110000011111000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000000001111110000111111000000000000000000000000000000001111111000111111100000000000000000000000000000000001111111000111111100000000000000000000000000000000111111110011111111000000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000000000000100000000010000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000000000011000000001100000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000000000111000000011100000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000000000111100000011110000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000000011111000001111100000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000000111111000011111100000000000000000000000000000000111111100011111110000000000000000000000000000000000111111100011111110000000000000000000000000000000011111111001111111100000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000001110000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000000111110000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000001111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000011110000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000011111110000000000000000000000000000000000000000001111111100000000000";
    }

    function S2() public pure returns (string memory) {
        return
            "000000000011111111101111111110111111111000000000000000000000111111110011111111001111111100000000000000000000001111111000111111100011111110000000000000000000000011111100001111110000111111000000000000000000000000111110000011111000001111100000000000000000000000001111000000111100000011110000000000000000000000000011100000001110000000111000000000000000000000000000110000000011000000001100000000000000000000000000001000000000100000000010000000000000000000000000000011111111101111111110000000000000000000000000000000111111110011111111000000000000000000000000000000001111111000111111100000000000000000000000000000000011111100001111110000000000000000000000000000000000111110000011111000000000000000000000000000000000001111000000111100000000000000000000000000000000000011100000001110000000000000000000000000000000000000110000000011000000000000000000000000000000000000001000000000100000000000000000000000000000000000000000000000001111111110111111111000000000000000000000000000000011111111001111111100000000000000000000000000000000111111100011111110000000000000000000000000000000001111110000111111000000000000000000000000000000000011111000001111100000000000000000000000000000000000111100000011110000000000000000000000000000000000001110000000111000000000000000000000000000000000000011000000001100000000000000000000000000000000000000100000000010000000000000000000000000000011111111100000000000000000000000000000000000000000111111110000000000000000000000000000000000000000001111111000000000000000000000000000000000000000000011111100000000000000000000000000000000000000000000111110000000000000000000000000000000000000000000001111000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001111111110000000000000000000000000000000000000000011111111000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000001111110000000000000000000000000000000000000000000011111000000000000000000000000000000000000000000000111100000000000000000000000000000000000000000000001110000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000111111111000000000000000000000000000000000000000001111111100000000000000000000000000000000000000000011111110000000000000000000000000000000000000000000111111000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000011110000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000010000000000000000000";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library FiguresDoubleDigitsLib {
    string public constant FS0S1 =
        "00000011100111001110011100000000000011100111001110000000000000000011100111000000000000000000000011100000000100001000010000100000000000000100001000010000000000000000000100001000000000000000000000000100";
    string public constant FS0S2 =
        "01110011100111001110000000111001110011100000000000011100111000000000000000001110000000000000000000000010000100001000010000000001000010000100000000000000100001000000000000000000010000000000000000000000";

    string public constant FS1S1 =
        "000011000110001100011000100001000011000110001100010000100001000011000110001000010000100001000011000100001110011100111001110010000100001110011100111001000010000100001110011100100001000010000100001110010000111101111011110111101000010000111101111011110100001000010000111101111010000100001000010000111101000111101111011110111101100011000111101111011110110001100011000111101111011000110001100011000111101100111101111011110111101110011100111101111011110111001110011100111101111011100111001110011100111101110001110011100111001110011000110001110011100111001100011000110001110011100110001100011000110001110011";

    string public constant FS1S2 =
        "100011000110001100010000010001100011000100000000001000110001000000000000000100010000000000000000000011001110011100111001000001100111001110010000000000110011100100000000000000011001000000000000000000001110111101111011110100000111011110111101000000000011101111010000000000000001110100000000000000000000110111101111011110110000011011110111101100000000001101111011000000000000000110110000000000000000000010111101111011110111000001011110111101110000000000101111011100000000000000010111000000000000000000001001110011100111001100000100111001110011000000000010011100110000000000000001001100000000000000000000";

    string public constant FS2S1 =
        "000001111011110111100000000000111001110011100000000000011000110001100000000000001000010000100000000000000111101111000000000000000011100111000000000000000001100011000000000000000000100001000000000000000000000000111101111000000000000000011100111000000000000000001100011000000000000000000100001000000000000001111000000000000000000000111000000000000000000000011000000000000000000000001000000000000000000000000000001111000000000000000000000111000000000000000000000011000000000000000000000001000000000000000000000000000001111000000000000000000000111000000000000000000000011000000000000000000000001000000000";

    string public constant FS2S2 =
        "000000111101111011110000000000001110011100111000000000000011000110001100000000000000100001000010000000000011110111100000000000000000111001110000000000000000001100011000000000000000000010000100000000000000000000011110111100000000000000000111001110000000000000000001100011000000000000000000010000100000000000111100000000000000000000001110000000000000000000000011000000000000000000000000100000000000000000000000000111100000000000000000000001110000000000000000000000011000000000000000000000000100000000000000000000000000111100000000000000000000001110000000000000000000000011000000000000000000000000100000";

    string public constant FS3S1 = FS2S1;

    string public constant FS3S2 = FS2S1;

    string public constant FS4S1 =
        "011010110101101011010000001101011010110100000000000110101101000000000000000001010010100101001010000000101001010010100000000000010100101000000000000000010010100101001010010000001001010010100100000000000100101001000000000000000";

    string public constant FS4S2 =
        "0000011101111011110111101000001101111011110111101100000110011100111001110010000010001100011000110001000000000011101111011110100000000001101111011110110000000000110011100111001000000000010001100011000100000000000000011101111010000000000000001101111011000000000000000110011100100000000000000010001100010000000000000000000011101000000000000000000001101100000000000000000000110010000000000000000000010001";

    string public constant FS5S1 = FS2S2;

    string public constant FS5S2 = FS3S2;

    string public constant FS6S1 = FS2S2;

    string public constant FS6S2 =
        "000000111001110011100000000000000000111001110000000000001110011100000000000000000000000000011100000000000000000111000000000000000001110000000000000000000000100001000010000000000000001000010000100000000000000010000100001000000000000100001000000000000000000001000010000000000000000000010000100000000000000000000001000010000000000000000000010000100000000000000000000100001000000000000100000000000000000000000001000000000000000000000000010000000000000000000000000001000000000000000000000000010000000000000000000000000100000000000000000000000000010000000000000000000000000100000000000000000000000001000000000000110000000000000000000000000000110000000000000000000000000000110000000000000110001100000000000000000000000110001100000000000000110001100000000000000000000000110001100000000000011000110001100000000000000110001100011000000";

    string public constant FS7S1 =
        "0000011110111101111011110000000000011110111101111000000000000000011110111100000000000000000000011110000000000000000000000000000000111001110011100111000000000000111001110011100000000000000000111001110000000000000000000000111000000011000110001100011000000000000011000110001100000000000000000011000110000000000000000000000011000";

    string public constant FS7S2 =
        "1111011110111101111011110111001110011100111001110011000110001100011000110001000010000100001000010000";

    string public constant FS8S1 =
        "000000111001110011100000000000000000111001110000000000001110011100000000000000000110001100011000000000000001100011000110000000000000000000000111000000000000000001110000000000000000011100000000000000000000001000010000100000000000000010000100001000000000000000100001000010000000000001100000000000000000000000000001100000000000000000000000000001100000000000000110000000000000000000000000000110000000000000000000000000000110000000000000000010000100000000000000000000100001000000000000000000001000010000000000001000010000000000000000000010000100000000000000000000100001000000000000000001100011000000000000000000000001100011000000000000001100011000000000000000000000001100011000000000000100000000000000000000000001000000000000000000000000010000000000000000000000000001000000000000000000000000010000000000000000000000000100000000000000000000000000010000000000000000000000000100000000000000000000000001000000";

    string public constant FS8S2 = FS8S1;

    string public constant FS9S1 =
        "000000111001110011100000000000011100111000000000000000000000011100111000000000000111000000000000000000000000000111000000000000000000000000000111000000000000100001000010000000000000001000010000100000000000000010000100001000000000000000001000010000000000000000000010000100000000000000000000100001000000000000100001000000000000000000001000010000000000000000000010000100000000000000000000000000010000000000000000000000000100000000000000000000000001000000000000000001000000000000000000000000010000000000000000000000000100000000000000000100000000000000000000000001000000000000000000000000010000000000000000000000000000000011000000000000000000110000000000000000001100000000000000000000000000000000001100000000000000000011000000000000000000110000000000000000000000000001100011000000000000011000110000000000000000000000001100011000000000000011000110000000000000000011000110001100000000000000110001100011000000";

    string public constant FS9S2 = FS2S1;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./digits/FiguresDoubleDigitsLib.sol";
import "./FiguresUtilLib.sol";

library FiguresDoubles {
    function chooseStringsDoubles(
        uint8 number,
        uint8 index1,
        uint8 index2
    ) public pure returns (bool[][2] memory b) {
        FiguresUtilLib.FigStrings memory strings = getFigStringsDoubles(number);
        return
            FiguresUtilLib._chooseStringsDouble(
                number,
                strings.s1,
                strings.s2,
                index1,
                index2
            );
    }

    function getFigStringsDoubles(uint8 number)
        private
        pure
        returns (FiguresUtilLib.FigStrings memory)
    {
        FiguresUtilLib.FigStrings memory figStrings;

        do {
            if (number == 0) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS0S1,
                    8
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS0S2,
                    8
                );
                break;
            }
            if (number == 1) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS1S1,
                    24
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS1S2,
                    24
                );
                break;
            }
            if (number == 2) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS2S1,
                    24
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS2S2,
                    24
                );
                break;
            }
            if (number == 3) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS3S1,
                    24
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS3S2,
                    24
                );
                break;
            }
            if (number == 4) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS4S1,
                    9
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS4S2,
                    16
                );
                break;
            }
            if (number == 5) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS5S1,
                    24
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS5S2,
                    24
                );
                break;
            }
            if (number == 6) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS6S1,
                    24
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS6S2,
                    33
                );
                break;
            }
            if (number == 7) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS7S1,
                    13
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS7S2,
                    4
                );
                break;
            }
            if (number == 8) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS8S1,
                    36
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS8S2,
                    36
                );
                break;
            }
            if (number == 9) {
                figStrings.s1 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS9S1,
                    36
                );
                figStrings.s2 = FiguresUtilLib._assignValuesDouble(
                    FiguresDoubleDigitsLib.FS9S2,
                    24
                );
                break;
            }
        } while (false);

        return figStrings;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library FiguresRenderLib {
    function _concat(string memory a, string memory b)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function _generateRect(
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height,
        string memory color,
        string memory style
    ) public pure returns (string memory) {
        string memory s = "";
        s = _concat(s, "<rect x='");
        s = _concat(s, Strings.toString(x));
        s = _concat(s, "' y='");
        s = _concat(s, Strings.toString(y));
        s = _concat(s, "' width='");
        s = _concat(s, Strings.toString(width));
        s = _concat(s, "' height='");
        s = _concat(s, Strings.toString(height));
        s = _concat(s, "' style='fill:rgb(");
        s = _concat(s, color);
        s = _concat(s, "); ");
        s = _concat(s, style);
        s = _concat(s, "'/>");
        return s;
    }

    function _generatePixelSVG(
        uint256 x,
        uint256 y,
        uint256 factor,
        string memory color
    ) public pure returns (string memory) {
        string memory s = "";
        s = _concat(s, "<rect x='");
        s = _concat(s, Strings.toString(x));
        s = _concat(s, "' y='");
        s = _concat(s, Strings.toString(y));
        s = _concat(s, "' width='");
        s = _concat(s, Strings.toString(factor));
        s = _concat(s, "' height='");
        s = _concat(s, Strings.toString(factor));
        s = _concat(s, "' style='fill:rgb(");
        s = _concat(s, color);
        s = _concat(s, "); mix-blend-mode: multiply;'/>");
        return s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./digits/Figure0DigitLib.sol";
import "./digits/Figure1DigitLib.sol";
import "./digits/Figure2DigitLib.sol";
import "./digits/Figure3DigitLib.sol";
import "./digits/Figure4DigitLib.sol";
import "./digits/Figure5DigitLib.sol";
import "./digits/Figure6DigitLib.sol";
import "./digits/Figure7DigitLib.sol";
import "./digits/Figure8DigitLib.sol";
import "./digits/Figure9DigitLib.sol";
import "./FiguresUtilLib.sol";

library FiguresSingles {
    function chooseStringsSingles(
        uint8 number,
        uint8 index1,
        uint8 index2
    ) public pure returns (bool[][2] memory b) {
        FiguresUtilLib.FigStrings memory strings = getFigStringsSingles(number);
        return
            FiguresUtilLib._chooseStringsSingle(
                number,
                strings.s1,
                strings.s2,
                index1,
                index2
            );
    }

    function getFigStringsSingles(uint8 number)
        private
        pure
        returns (FiguresUtilLib.FigStrings memory)
    {
        FiguresUtilLib.FigStrings memory figStrings;

        do {
            if (number == 0) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure0DigitLib.S1(),
                    144
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure0DigitLib.S2(),
                    144
                );
                break;
            }
            if (number == 1) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure1DigitLib.S1(),
                    28
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure1DigitLib.S2(),
                    28
                );
                break;
            }
            if (number == 2) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure2DigitLib.S1(),
                    54
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure2DigitLib.S2(),
                    54
                );
                break;
            }
            if (number == 3) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure3DigitLib.S1(),
                    54
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure3DigitLib.S2(),
                    54
                );
                break;
            }
            if (number == 4) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure4DigitLib.S1(),
                    108
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure4DigitLib.S2(),
                    30
                );
                break;
            }
            if (number == 5) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure5DigitLib.S1(),
                    54
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure5DigitLib.S2(),
                    54
                );
                break;
            }
            if (number == 6) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure6DigitLib.S1(),
                    54
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure6DigitLib.S2(),
                    216
                );
                break;
            }
            if (number == 7) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure7DigitLib.S1(),
                    18
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure7DigitLib.S2(),
                    6
                );
                break;
            }
            if (number == 8) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure8DigitLib.S1(),
                    216
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure8DigitLib.S2(),
                    216
                );
                break;
            }
            if (number == 9) {
                figStrings.s1 = FiguresUtilLib._assignValuesSingle(
                    Figure9DigitLib.S1(),
                    216
                );
                figStrings.s2 = FiguresUtilLib._assignValuesSingle(
                    Figure9DigitLib.S2(),
                    54
                );
                break;
            }
        } while (false);

        return figStrings;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./IFiguresToken.sol";
import "./FiguresSingles.sol";
import "./FiguresDoubles.sol";
import "./FiguresRenderLib.sol";
import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FiguresToken is ERC721Creator, IFiguresToken {
    using Counters for Counters.Counter;

    address public CONTROLLER_ADDRESS;

    string private _baseSvg = "";
    uint256 private _scaleFactor = 20;
    string[3] private _backgroundColors = [
        "255,120,211",
        "255,227,0",
        "25,180,255"
    ];

    struct RandomVariables {
        uint8 number;
        uint8[4] bgColor1Index;
        uint8[4] bgColor2Index;
        uint8 figureIndex1_1;
        uint8 figureIndex1_2;
        uint8 figureIndex2_1;
        uint8 figureIndex2_2;
    }

    mapping(uint256 => uint256) private _seeds;
    mapping(uint256 => RandomVariables) private _seedRandom;

    constructor() ERC721Creator("Figures", "FIG") {}

    function setControllerAddress(
        address controllerAddress
    ) external onlyOwner {
        CONTROLLER_ADDRESS = controllerAddress;
    }

    function getControllerAddress() public view returns (address) {
        return CONTROLLER_ADDRESS;
    }

    function withdrawETH(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev See {IFiguresToken-initializeSeed}.
     */
    function initializeSeed(uint256[] memory seed) external override {
        require(msg.sender == CONTROLLER_ADDRESS, "Permission denied");
        // generate all the random numbers you need here!
        _seedRandom[seed[0]] = RandomVariables({
            number: uint8(_random(100, seed[0])),
            bgColor1Index: [
                uint8(_random(20, seed[1])),
                uint8(_random(20, seed[2])),
                uint8(_random(20, seed[3])),
                uint8(_random(20, seed[4]))
            ],
            bgColor2Index: [
                uint8(_random(20, seed[5])),
                uint8(_random(20, seed[6])),
                uint8(_random(20, seed[7])),
                uint8(_random(20, seed[8]))
            ],
            // 360 is the max number of options for number '9'
            figureIndex1_1: uint8(_random(360, seed[9])),
            figureIndex1_2: uint8(_random(360, seed[10])),
            figureIndex2_1: uint8(_random(360, seed[11])),
            figureIndex2_2: uint8(_random(360, seed[12]))
        });
    }

    /**
     * @dev See {IFiguresToken-mint}.
     */
    function mint(
        uint256 tokenId,
        uint256 seed,
        address recipient
    ) external override {
        require(msg.sender == CONTROLLER_ADDRESS, "Permission denied");
        // Store render data for this token
        _seeds[tokenId] = seed;

        // Mint token
        _mint(recipient, tokenId);
    }

    /**
     * @dev See {IERC721-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return render(_seeds[tokenId], tokenId);
    }

    function tokenNumber(
        uint256 tokenId
    ) public view returns (uint8) {
        _requireMinted(tokenId);
        return _seedRandom[_seeds[tokenId]].number;
    }

    /**
     * @dev See {IFiguresToken-render}.
     */
    function render(
        uint256 seed,
        uint256 assetId
    ) public view override returns (string memory) {
        uint256 n;
        string memory s;
        string memory attributes;

        RandomVariables memory variables = _seedRandom[seed];

        n = variables.number;
        s = _concat(s, "data:image/svg+xml;utf8,");
        s = _concat(
            s,
            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='figures' width='"
        );
        s = _concat(s, Strings.toString(10 * _scaleFactor));
        s = _concat(s, "' height='");
        s = _concat(s, Strings.toString(10 * _scaleFactor));
        s = _concat(s, "'>");
        s = _concat(
            s,
            _drawBackground(variables.bgColor1Index, variables.bgColor2Index)
        );

        if (n < 10) {
            bool[][2] memory figArrays = FiguresSingles.chooseStringsSingles(
                uint8(n),
                variables.figureIndex1_1,
                variables.figureIndex1_2
            );
            s = _concat(
                s,
                _drawFigure(
                    false,
                    figArrays
                )
            );

        } else {
            uint8 leftNumber = uint8(n / 10);
            uint8 rightNumber = uint8(n % 10);

            bool[][2] memory figArraysLeft = FiguresDoubles.chooseStringsDoubles(
                leftNumber,
                variables.figureIndex1_1,
                variables.figureIndex1_2
            );

            bool[][2] memory figArraysRight = FiguresDoubles.chooseStringsDoubles(
                rightNumber,
                variables.figureIndex2_1,
                variables.figureIndex2_2
            );

            s = _concat(
                s,
                _drawFigure(
                    false,
                    figArraysLeft
                )
            );
            s = _concat(
                s,
                _drawFigure(
                    true,
                    figArraysRight
                )
            );
        }
        s = _concat(s, "</svg>");

        attributes = _concat('{"name":"Figure #', Strings.toString(assetId));

        attributes = _concat(attributes, '", "description":"Figure representation of ');

        attributes = _concat(attributes, Strings.toString(n));

        attributes = _concat(attributes, '.", "created_by":"Figures", "external_url":"https://figures.art/token/');

        attributes = _concat(attributes, Strings.toString(assetId));

        attributes = _concat(attributes, '", "attributes": [{"trait_type": "Number", "value":"');

        attributes = _concat(attributes, Strings.toString(n));

        attributes = _concat(attributes, '"}], "image":"');

        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,',
                    attributes,
                    s,
                    '"}'
                )
            );
    }

    function _random(
        uint256 number,
        uint256 count
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender,
                        count
                    )
                )
            ) % number;
    }

    function _concat(string memory a, string memory b)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function _drawBackground(
        uint8[4] memory bgColor1Index,
        uint8[4] memory bgColor2Index
    ) internal view returns (string memory) {
        // Draw first layer of bg by laying 4 randomly colored tiled
        string memory s = "";

        for (uint256 i = 0; i < 4; i++) {
            uint bgColor1IndexAvailable = bgColor1Index[i] % 3;
            uint bgColor2IndexAvailable = bgColor2Index[i] % 4;
            s = _concat(s, "<g>");
            s = _concat(
                s,
                (
                    FiguresRenderLib._generateRect(
                        (i % 2) * uint256(5) * _scaleFactor,
                        (i / 2) * uint256(5) * _scaleFactor,
                        uint256(5) * _scaleFactor,
                        uint256(5) * _scaleFactor,
                        _backgroundColors[bgColor1IndexAvailable],
                        ""
                    )
                )
            );
            if (bgColor2IndexAvailable == 3) {
                s = _concat(s, "</g>");
                continue;
            }

            s = _concat(
                s,
                (
                    FiguresRenderLib._generateRect(
                        (i % 2) * uint256(5) * _scaleFactor,
                        (i / 2) * uint256(5) * _scaleFactor,
                        uint256(5) * _scaleFactor,
                        uint256(5) * _scaleFactor,
                        _backgroundColors[bgColor2IndexAvailable],
                        "mix-blend-mode: multiply;"
                    )
                )
            );
            s = _concat(s, "</g>");
        }
        return s;
    }

    function _drawFigure(
        bool rightOffset,
        bool[][2] memory figArrays
    ) internal view returns (string memory) {
        uint256 rightOffsetX = 0;

        if (rightOffset) {
            rightOffsetX = uint256(5) * _scaleFactor;
        }

        string memory s = "";

        // k is top and bottom
        for (uint256 k = 0; k < 2; k++) {
            // i is each pixel
            for (uint256 i = 0; i < figArrays[k].length; ++i) {
                uint8 size = uint8(figArrays[k].length / 5);
                if (figArrays[k][i]) {
                    continue;
                }
                uint256 xOffset = _scaleFactor;
                uint256 yOffset = _scaleFactor;
                uint256 x = (i % size) * xOffset + rightOffsetX;
                uint256 y = 0;

                if (k == 1) {
                    y = (5 * yOffset);
                }
                y += (i / size) * yOffset;

                s = _concat(s, FiguresRenderLib._generatePixelSVG(x, y, _scaleFactor, "255,120,211"));
            }
        }

        return s;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library FiguresUtilLib {
    struct FigStrings {
        string[] s1;
        string[] s2;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _assignValuesSingle(string memory input, uint16 size)
        internal
        pure
        returns (string[] memory)
    {
        return _assignValues(input, size, 50);
    }

    function _assignValuesDouble(string memory input, uint16 size)
        internal
        pure
        returns (string[] memory)
    {
        return _assignValues(input, size, 25);
    }

    function _assignValues(
        string memory input,
        uint16 size,
        uint8 length
    ) internal pure returns (string[] memory) {
        string[] memory output = new string[](size);
        for (uint256 i = 0; i < size; i++) {
            output[i] = substring(input, i * length, i * length + length);
        }
        return output;
    }

    function _chooseStringsSingle(
        uint8 number,
        string[] memory strings1,
        string[] memory strings2,
        uint8 index1,
        uint8 index2
    ) internal pure returns (bool[][2] memory b) {
        return _chooseStrings(number, strings1, strings2, index1, index2, 50);
    }

    function _chooseStringsDouble(
        uint8 number,
        string[] memory strings1,
        string[] memory strings2,
        uint8 index1,
        uint8 index2
    ) internal pure returns (bool[][2] memory b) {
        return _chooseStrings(number, strings1, strings2, index1, index2, 25);
    }

    function _chooseStrings(
        uint8 number,
        string[] memory strings1,
        string[] memory strings2,
        uint8 index1,
        uint8 index2,
        uint8 length
    ) private pure returns (bool[][2] memory b) {
        string[2] memory s;
        // some arrays are shorter than the random number generated
        uint256 availableIndex1 = index1 % strings1.length;
        uint256 availableIndex2 = index2 % strings2.length;
        s[0] = strings1[availableIndex1];
        s[1] = strings2[availableIndex2];

        // Special cases for 0, 1, 7
        if (number == 0 || number == 1 || number == 7) {
            if (length == 25) {
                while (
                    keccak256(bytes(substring(s[0], 20, 24))) !=
                    keccak256(bytes(substring(s[1], 0, 4)))
                ) {
                    uint256 is2 = ((availableIndex2 + availableIndex1++) %
                        strings2.length);
                    s[1] = strings2[is2];
                }
            }
            if (length == 50) {
                while (
                    keccak256(bytes(substring(s[0], 40, 49))) !=
                    keccak256(bytes(substring(s[1], 0, 9)))
                ) {
                    uint256 is2 = ((availableIndex2 + availableIndex1++) %
                        strings2.length);
                    s[1] = strings2[is2];
                }
            }
        }

        b[0] = _returnBoolArray(s[0]);
        b[1] = _returnBoolArray(s[1]);

        return b;
    }

    function checkString(string memory s1, string memory s2) private pure {}

    function _returnBoolArray(string memory s)
        internal
        pure
        returns (bool[] memory)
    {
        bytes memory b = bytes(s);
        bool[] memory a = new bool[](b.length);
        for (uint256 i = 0; i < b.length; i++) {
            uint8 z = (uint8(b[i]));
            if (z == 48) {
                a[i] = true;
            } else if (z == 49) {
                a[i] = false;
            }
        }
        return a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IFiguresToken {
    /**
     * Initialize seed random variables used to render token
     * Can only be called by controller
     */
    function initializeSeed(uint256[] memory seed) external;

    /**
     * Mint a token with the given seed.
     * Can only be called by controller
     */
    function mint(
        uint256 tokenId,
        uint256 seed,
        address recipient
    ) external;

    /**
     * Render token based on seed
     */
    function render(uint256 seed, uint256 assetId)
        external
        view
        returns (string memory s);
}