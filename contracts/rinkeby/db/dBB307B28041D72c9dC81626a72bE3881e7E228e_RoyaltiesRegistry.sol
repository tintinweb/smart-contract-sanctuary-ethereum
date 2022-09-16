// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "./IRoyaltiesRegistry.sol";
import "./specs/IRarible.sol";
import "../../libraries/BPS.sol";
import "../../tokens/IERC721LA.sol";
import "./RoyaltiesState.sol";

/**
 * @notice Registry to lookup royalty configurations for different royalty specs
 */
contract RoyaltiesRegistry is ERC165, OwnableUpgradeable, IRoyaltiesRegistry {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               LIBRARIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    using AddressUpgradeable for address;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 private constant MAX_BPS = 10_000;
    uint256 private constant EDITION_TOKEN_MULTIPLIER = 10e5;
    bytes32 public constant DEPLOYER_ROLE = 0x00;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier isAuthorized(address collectionAddress) {
        bool isOwner = owner() == msg.sender;
        bool isCollectionAdmin = _hasCollectionAdminRole(collectionAddress);
        bool isMinter = _hasMinterRole(collectionAddress);

        if (!isOwner && !isCollectionAdmin && !isMinter) {
            revert NotApproved();
        }
        _;
    }

    modifier isEditionCreatorOrOwner(
        address collectionAddress,
        uint256 editionId
    ) {
        bool isOwner = owner() == msg.sender;
        bool isEditionCreator = _isEditionCreator(collectionAddress, editionId);
        if (!isOwner && !isEditionCreator) {
            revert NotApproved();
        }
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function initialize() public initializer {
        __Ownable_init_unchained();
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               IERC165
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165, IRoyaltiesRegistry)
        returns (bool)
    {
        return
            interfaceId == type(IRoyaltiesRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               AUTHORIZATION
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    /// @dev Returns whether `caller` is the admin of the `collectionContract`.
    /// @notice `tx.origin` is used to get the original caller as `msg.sender` is the proxy contract.
    function _hasCollectionAdminRole(address collectionAddress)
        internal
        view
        returns (bool)
    {
        bool hasRole = IERC721LA(collectionAddress).isCollectionAdmin(
            tx.origin
        );
        return hasRole;
    }

    /// @dev Returns whether `caller` is the admin of the `collectionContract`.
    /// @notice `tx.origin` is used to get the original caller as `msg.sender` is the proxy contract.
    function _isEditionCreator(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        (uint256 editionId, ) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );
        ERC721State.Edition memory edition = IERC721LA(collectionAddress)
            .getEdition(editionId);
        bool isCreator = edition.createdBy == tx.origin;
        return isCreator;
    }

    /// @dev Returns whether `caller` is the minter of the `collectionContract`.
    /// @notice `tx.origin` is used to get the original caller as `msg.sender` is the proxy contract.
    function _hasMinterRole(address collectionAddress)
        internal
        view
        returns (bool)
    {
        bool hasRole = IERC721LA(collectionAddress).isMinter(tx.origin);
        return hasRole;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               PRIMARY ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function registerCollectionPrimaryRoyaltyReceivers(
        address collectionAddress,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isAuthorized(collectionAddress) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();
        _validateRoyaltyReceivers(royaltyReceivers);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state._collectionPrimaryRoyaltyReceivers[collectionAddress].push(
                royaltyReceivers[i]
            );
        }
    }

    function registerEditionPrimaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isEditionCreatorOrOwner(collectionAddress, tokenId) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, ) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._editionPrimaryRoyaltyReceivers[collectionAddress][editionId].push(
                    royaltyReceivers[i]
                );
        }
    }

    function registerTokenPrimaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isEditionCreatorOrOwner(collectionAddress, tokenId) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._tokenPrimaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ].push(royaltyReceivers[i]);
        }
    }

    /// @dev Returns the royalties for the given `tokenId`.
    function primaryRoyaltyInfo(address collectionAddress, uint256 tokenId)
        external
        isAuthorized(collectionAddress)
        returns (RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers)
    {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        royaltyReceivers = state._tokenPrimaryRoyaltyReceivers[
            collectionAddress
        ][editionId][tokenNumber];

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionPrimaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionPrimaryRoyaltyReceivers[
                collectionAddress
            ];
        }

        return royaltyReceivers;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               SECONDARY ROYALTIES
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function registerCollectionSecondaryRoyaltyReceivers(
        address collectionAddress,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isAuthorized(collectionAddress) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state._collectionSecondaryRoyaltyReceivers[collectionAddress].push(
                royaltyReceivers[i]
            );
        }
    }

    function registerEditionSecondaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isEditionCreatorOrOwner(collectionAddress, tokenId) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, ) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._editionSecondaryRoyaltyReceivers[collectionAddress][editionId]
                .push(royaltyReceivers[i]);
        }
    }

    function registerTokenSecondaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) public isEditionCreatorOrOwner(collectionAddress, tokenId) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        _validateRoyaltyReceivers(royaltyReceivers);

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ].push(royaltyReceivers[i]);
        }
    }

    /// @dev for external platforms we always return resale royalties
    function _getRoyaltyReceivers(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (address payable[] memory)
    {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();
        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionSecondaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionSecondaryRoyaltyReceivers[
                collectionAddress
            ];
        }

        address payable[] memory receivers = new address payable[](
            royaltyReceivers.length
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            receivers[i] = royaltyReceivers[i].wallet;
        }

        return receivers;
    }

    /// @dev for external platforms we always return resale royalties
    function _getRoyaltyBPS(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (uint256[] memory)
    {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );

        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ];
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionSecondaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }
        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionSecondaryRoyaltyReceivers[
                collectionAddress
            ];
        }
        uint256[] memory royaltyBPS = new uint256[](royaltyReceivers.length);

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            royaltyBPS[i] = royaltyReceivers[i].secondarySalePercentage;
        }

        return royaltyBPS;
    }

    /// @dev see: EIP-2981
    function royaltyInfo(
        address collectionAddress,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        RoyaltiesState.RoyaltiesRegistryState storage state = RoyaltiesState
            ._getRoyaltiesState();

        (uint256 editionId, uint256 tokenNumber) = parseEditionFromTokenId(
            collectionAddress,
            tokenId
        );
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers = state
            ._tokenSecondaryRoyaltyReceivers[collectionAddress][editionId][
                tokenNumber
            ];

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._editionSecondaryRoyaltyReceivers[
                collectionAddress
            ][editionId];
        }

        if (royaltyReceivers.length == 0) {
            royaltyReceivers = state._collectionSecondaryRoyaltyReceivers[
                collectionAddress
            ];
        }

        if (royaltyReceivers.length > 1) {
            revert MultipleRoyaltyRecievers();
        }

        if (royaltyReceivers.length == 0) {
            return (address(this), 0);
        }

        return (
            royaltyReceivers[0].wallet,
            BPS._calculatePercentage(
                salePrice,
                royaltyReceivers[0].secondarySalePercentage
            )
        );
    }

    /// @dev CreatorCore - Supports Manifold, ArtBlocks
    function getRoyalties(address collectionAddress, uint256 tokenId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev Foundation
    function getFees(address collectionAddress, uint256 editionId)
        public
        view
        returns (address payable[] memory, uint256[] memory)
    {
        return getRoyalties(collectionAddress, editionId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeBps(address collectionAddress, uint256 tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return _getRoyaltyBPS(collectionAddress, tokenId);
    }

    /// @dev Rarible: RoyaltiesV1
    function getFeeRecipients(address collectionAddress, uint256 editionId)
        public
        view
        returns (address payable[] memory)
    {
        return _getRoyaltyReceivers(collectionAddress, editionId);
    }

    /// @dev Rarible: RoyaltiesV2
    function getRaribleV2Royalties(address collectionAddress, uint256 tokenId)
        public
        view
        returns (IRaribleV2.Part[] memory)
    {
        address payable[] memory royaltyReceivers = _getRoyaltyReceivers(
            collectionAddress,
            tokenId
        );

        if (royaltyReceivers.length == 0) {
            return new IRaribleV2.Part[](0);
        }

        uint256[] memory bps = _getRoyaltyBPS(collectionAddress, tokenId);

        IRaribleV2.Part[] memory parts = new IRaribleV2.Part[](
            royaltyReceivers.length
        );

        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            parts[i] = IRaribleV2.Part({
                account: payable(royaltyReceivers[i]),
                value: uint96(bps[i])
            });
        }
        return parts;
    }

    /// @dev CreatorCore - Support for KODA
    function getKODAV2RoyaltyInfo(address collectionAddress, uint256 tokenId)
        public
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /// @dev CreatorCore - Support for Zora
    function convertBidShares(address collectionAddress, uint256 tokenId)
        public
        view
        returns (address payable[] memory recipients_, uint256[] memory bps)
    {
        return (
            _getRoyaltyReceivers(collectionAddress, tokenId),
            _getRoyaltyBPS(collectionAddress, tokenId)
        );
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                         INTERNAL / PUBLIC HELPERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

    function parseEditionFromTokenId(address collectionAddress, uint256 tokenId)
        internal
        view
        returns (uint256 editionId, uint256 tokenNumber)
    {
        (, bytes memory result) = collectionAddress.staticcall(
            abi.encodeWithSignature("parseEditionFromTokenId(uint256)", tokenId)
        );

        (editionId, tokenNumber) = abi.decode(result, (uint256, uint256));
    }

    function _validateRoyaltyReceivers(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) internal pure {
        (
            uint256 totalPrimarySaleBPS,
            uint256 totalSecondarySaleBPS
        ) = _calculateTotalRoyalties(royaltyReceivers);

        if (totalPrimarySaleBPS > MAX_BPS) {
            revert PrimarySalePercentageOutOfRange();
        }

        if (totalSecondarySaleBPS > MAX_BPS) {
            revert SecondarySalePercentageOutOfRange();
        }
    }

    function _calculateTotalRoyalties(
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    )
        internal
        pure
        returns (uint256 totalFirstSaleBPS, uint256 totalSecondarySaleBPS)
    {
        uint256 _totalFirstSaleBPS;
        uint256 _totalSecondarySaleBPS;
        for (uint256 i = 0; i < royaltyReceivers.length; i++) {
            _totalFirstSaleBPS += royaltyReceivers[i].primarySalePercentage;
            _totalSecondarySaleBPS += royaltyReceivers[i]
                .secondarySalePercentage;
        }

        return (_totalFirstSaleBPS, _totalSecondarySaleBPS);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./specs/IRarible.sol";
import "./RoyaltiesState.sol";

/// @dev Royalty registry interface
interface IRoyaltiesRegistry is IERC165 {
    /// @dev Raised when trying to set a royalty override for a token
    error NotApproved();
    error NotOwner();

    /// @dev Raised when providing multiple royalty overrides when only one is expected
    error MultipleRoyaltyRecievers();

    /// @dev Raised when sales percentage is not between 0 and 100
    error PrimarySalePercentageOutOfRange();
    error SecondarySalePercentageOutOfRange();

    /**
     * Raised trying to set edition or token royalties
     */
    error NotEditionCreator();

    // ==============================
    //            EVENTS
    // ==============================
    event RoyaltyOverride(
        address owner,
        address tokenAddress,
        address royaltyAddress
    );

    event RoyaltyTokenOverride(
        address owner,
        address tokenAddress,
        uint256 tokenId,
        address royaltyAddress
    );

    // ==============================
    //            IERC165
    // ==============================

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool);

    // ==============================
    //            SECONDARY ROYALTY
    // ==============================

    /*
    @notice Called with the sale price to determine how much royalty is owed and to whom.
    @param _contractAddress - The collection address
    @param _tokenId - the NFT asset queried for royalty information
    @param _value - the sale price of the NFT asset specified by _tokenId
    @return _receiver - address of who should be sent the royalty payment
    @return _royaltyAmount - the royalty payment amount for value sale price
    */
    function royaltyInfo(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _value
    ) external view returns (address _receiver, uint256 _royaltyAmount);

    /**
     *  Return RoyaltyReceivers for primary sales
     *
     */
    function primaryRoyaltyInfo(address collectionAddress, uint256 tokenId)
        external
        returns (RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers);

    /**
     *  @dev CreatorCore - Supports Manifold, ArtBlocks
     *
     *  getRoyalties
     */
    function getRoyalties(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    /**
     *  @dev Foundation
     *
     *  getFees
     */
    function getFees(address collectionAddress, uint256 editionId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  getFeeBps
     */
    function getFeeBps(address collectionAddress, uint256 tokenId)
        external
        view
        returns (uint256[] memory);

    /**
     *  @dev Rarible: RoyaltiesV1
     *
     *  getFeeRecipients
     */
    function getFeeRecipients(address collectionAddress, uint256 editionId)
        external
        view
        returns (address payable[] memory);

    /**
     *  @dev Rarible: RoyaltiesV2
     *
     *  getRaribleV2Royalties
     */
    function getRaribleV2Royalties(address collectionAddress, uint256 tokenId)
        external
        view
        returns (IRaribleV2.Part[] memory);

    /**
     *  @dev CreatorCore - Support for KODA
     *
     *  getKODAV2RoyaltyInfo
     */
    function getKODAV2RoyaltyInfo(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps);

    /**
     *  @dev CreatorCore - Support for Zora
     *
     *  convertBidShares
     */
    function convertBidShares(address collectionAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients_, uint256[] memory bps);

    /*
    @notice Called from a collection contract to set a primary royalty override
    @param collectionAddress - The collection address
    @param RoyaltyReceiver[] - The royalty receivers details
    */
    function registerCollectionPrimaryRoyaltyReceivers(
        address collectionAddress,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) external;

    /*
    @notice Called from a collection contract to set a secondary royalty override
    @param collectionAddress - The collection address
    @param RoyaltyReceiver[] - The royalty receivers details
    */
    function registerCollectionSecondaryRoyaltyReceivers(
        address collectionAddress,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) external;

    /*
    @notice Called from a collection contract to set a primary royalty override
    @param collectionAddress - The collection address
    @param tokenId - The token id
    @param RoyaltyReceiver[] - The royalty receivers details
    */
    function registerEditionPrimaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) external;

    /*
    @notice Called from a collection contract to set a secondary royalty override
    @param collectionAddress - The collection address
    @param tokenId - The token id
    @param RoyaltyReceiver[] - The royalty receivers details
    */
    function registerEditionSecondaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) external;

    /*
    @notice Called from a collection contract to set a primary royalty override
    @param collectionAddress - The collection address
    @param tokenId - The token id
    @param RoyaltyReceiver[] - The royalty receivers details
    */
    function registerTokenPrimaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) external;

    /*
    @notice Called from a collection contract to set a secondary royalty override
    @param collectionAddress - The collection address
    @param tokenId - The token id
    @param RoyaltyReceiver[] - The royalty receivers details
    */
    function registerTokenSecondaryRoyaltyReceivers(
        address collectionAddress,
        uint256 tokenId,
        RoyaltiesState.RoyaltyReceiver[] memory royaltyReceivers
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint256[] memory);

    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);
}

interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }

    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library BPS {
    function _calculatePercentage(uint256 number, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        // https://ethereum.stackexchange.com/a/55702
        // https://www.investopedia.com/terms/b/basispoint.asp
        return (number * percentage) / 10000;
    }
}

// SPDX-License-Identifier: MIT
import "../libraries/BitMaps/BitMaps.sol";
import "../platform/royalties/IRoyaltiesRegistry.sol";
import "./IERC721Events.sol";
import "./ERC721State.sol";
pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721LA compliant contract.
 */
abstract contract IERC721LA is IERC721Events {
    using BitMaps for BitMaps.BitMap;

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool);

    // ==============================
    //            IERC721
    // ==============================

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view virtual returns (uint256);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    // function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        external
        view
        virtual
        returns (address owner);

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
    ) external virtual;

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
    ) external virtual;

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
    ) external virtual;

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
    function approve(address to, uint256 tokenId) external virtual;

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
    function setApprovalForAll(address operator, bool _approved)
        external
        virtual;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        virtual
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        virtual
        returns (bool);

    // ==============================
    //        IERC721LA Burnable
    // ==============================

    /*
    @notice Called with the token ID to mark the token as burned. 
    @param _tokenId - the NFT token queried for burn
    */
    function burn(uint256 tokenId) external virtual;

    /*
    @notice Called when checking if the token is burned. 
    @param _tokenId - the NFT token queried.
    */
    function isBurned(uint256 tokenId) external view virtual returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view virtual returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);

    // ==============================
    //        Editions
    // ==============================

    /**
     * @dev fetch edition struct data by editionId
     */
    function getEdition(uint256 _editionId)
        external
        view
        virtual
        returns (ERC721State.Edition memory);

    // ==============================
    //        Helpers
    // ==============================

    function isCollectionAdmin(address account)
        external
        view
        virtual
        returns (bool);

    function isMinter(address account) external view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library RoyaltiesState {
    struct RoyaltyReceiver {
        address payable wallet;
        uint48 primarySalePercentage;
        uint48 secondarySalePercentage;
    }

    /**
     * @dev Storage layout
     * This pattern allow us to extend current contract using DELETGATE_CALL
     * without worrying about storage slot conflicts
     */
    struct RoyaltiesRegistryState {
        mapping(address => RoyaltyReceiver[]) _collectionPrimaryRoyaltyReceivers;
        mapping(address => RoyaltyReceiver[]) _collectionSecondaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => RoyaltyReceiver[])) _editionPrimaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => RoyaltyReceiver[])) _editionSecondaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => mapping(uint256 => RoyaltyReceiver[]))) _tokenPrimaryRoyaltyReceivers;
        mapping(address => mapping(uint256 => mapping(uint256 => RoyaltyReceiver[]))) _tokenSecondaryRoyaltyReceivers;
    }

    /**
     * @dev Get storage data from dedicated slot.
     * This pattern avoids storage conflict during proxy upgrades
     * and give more flexibility when creating extensions
     */
    function _getRoyaltiesState()
        internal
        pure
        returns (RoyaltiesRegistryState storage state)
    {
        bytes32 storageSlot = keccak256("liveart.RoyalitiesState");
        assembly {
            state.slot := storageSlot
        }
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
pragma solidity ^0.8.4;

import "./BitScan.sol";
/**
 * Derived from: https://github.com/estarriolvetch/solidity-bits
 */
/**
 * @dev This Library is a modified version of Openzeppelin's BitMaps library.
 * Functions of finding the index of the closest set bit from a given index are added.
 * The indexing of each bucket is modifed to count from the MSB to the LSB instead of from the LSB to the MSB.
 * The modification of indexing makes finding the closest previous set bit more efficient in gas usage.
 */

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */

error BitMapHeadNotFound();

library BitMaps {
    using BitScan for uint256;
    uint256 private constant MASK_INDEX_ZERO = (1 << 255);
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }

    /**
     * @dev Find the closest index of the set bit before `index`.
     */
    function scanForward(
        BitMap storage bitmap,
        uint256 index,
        uint256 lowerBound
    ) internal view returns (uint256 matchedIndex) {
        uint256 bucket = index >> 8;
        uint256 lowerBoundBucket = lowerBound >> 8;

        // index within the bucket
        uint256 bucketIndex = (index & 0xff);

        // load a bitboard from the bitmap.
        uint256 bb = bitmap._data[bucket];

        // offset the bitboard to scan from `bucketIndex`.
        bb = bb >> (0xff ^ bucketIndex); // bb >> (255 - bucketIndex)

        if (bb > 0) {
            unchecked {
                return (bucket << 8) | (bucketIndex - bb.bitScanForward256());
            }
        } else {
            while (true) {
                // require(bucket > lowerBound, "BitMaps: The set bit before the index doesn't exist.");
                if (bucket < lowerBoundBucket) {
                    revert BitMapHeadNotFound();
                }
                unchecked {
                    bucket--;
                }
                // No offset. Always scan from the least significiant bit now.
                bb = bitmap._data[bucket];

                if (bb > 0) {
                    unchecked {
                        return (bucket << 8) | (255 - bb.bitScanForward256());
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/BitMaps/BitMaps.sol";
import "../platform/royalties/IRoyaltiesRegistry.sol";

interface IERC721Events {
    event EditionCreated(
        address indexed contractAddress,
        address indexed createdBy,
        uint256 editionId,
        uint24 maxSupply,
        string baseURI,
        uint24 contractMintPrice
    );
    event EditionUpdated(
        address indexed contractAddress,
        uint256 editionId,
        uint256 maxSupply,
        string baseURI
    );
    
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/BitMaps/BitMaps.sol";
import "../platform/royalties/IRoyaltiesRegistry.sol";

library ERC721State {
    using BitMaps for BitMaps.BitMap;

    struct Edition {
        // Edition base URI
        string baseURI;
        // Max. number of token mintable per edition
        uint24 maxSupply;
        // Currently minted token coutner
        uint24 currentSupply;
        // Burned token counter
        uint24 burnedSupply;
        // Edition creator address
        address createdBy;
        // Public mint price (enables direct contract minting)
        uint24 contractMintPriceInFinney;
    }

    /**
     * @dev Storage layout
     * This pattern allow us to extend current contract using DELETGATE_CALL
     * without worrying about storage slot conflicts
     */
    struct ERC721LAState {
        // The number of edition created, indexed from 1
        uint64 _editionCounter;
        // Max token by edition. Defines the number of 0 in token Id (see editions)
        uint24 _edition_max_tokens;
        // Contract Name
        string _name;
        // Ticker
        string _symbol;
        // Edtion by editionId
        mapping(uint256 => Edition) _editions;
        // Owner by tokenId
        mapping(uint256 => address) _owners;
        // Token Id to operator address
        mapping(uint256 => address) _tokenApprovals;
        // Owned token count by address
        mapping(address => uint256) _balances;
        // Allower to allowee
        mapping(address => mapping(address => bool)) _operatorApprovals;
        // Tracking of batch heads
        BitMaps.BitMap _batchHead;
        // LiveArt global royalty registry address
        IRoyaltiesRegistry _royaltyRegistry;
        // Amount of ETH withdrawn by edition
        mapping(uint256 => uint256) _withdrawnBalancesByEdition;
    }

    /**
     * @dev Get storage data from dedicated slot.
     * This pattern avoids storage conflict during proxy upgrades
     * and give more flexibility when creating extensions
     */
    function _getERC721LAState()
        internal
        pure
        returns (ERC721LAState storage state)
    {
        bytes32 storageSlot = keccak256("liveart.ERC721LA");
        assembly {
            state.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: MIT
/**
   _____       ___     ___ __           ____  _ __      
  / ___/____  / (_)___/ (_) /___  __   / __ )(_) /______
  \__ \/ __ \/ / / __  / / __/ / / /  / __  / / __/ ___/
 ___/ / /_/ / / / /_/ / / /_/ /_/ /  / /_/ / / /_(__  ) 
/____/\____/_/_/\__,_/_/\__/\__, /  /_____/_/\__/____/  
                           /____/                        

- npm: https://www.npmjs.com/package/solidity-bits
- github: https://github.com/estarriolvetch/solidity-bits

 */

pragma solidity ^0.8.4;


library BitScan {
    uint256 constant private DEBRUIJN_256 = 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    bytes constant private LOOKUP_TABLE_256 = hex"0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a7506264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee30e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7ff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c816365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6fe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5fd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8";

    /**
        @dev Isolate the least significant set bit.
     */ 
    function isolateLS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            return bb & (0 - bb);
        }
    } 

    /**
        @dev Isolate the most significant set bit.
     */ 
    function isolateMS1B256(uint256 bb) pure internal returns (uint256) {
        require(bb > 0);
        unchecked {
            bb |= bb >> 256;
            bb |= bb >> 128;
            bb |= bb >> 64;
            bb |= bb >> 32;
            bb |= bb >> 16;
            bb |= bb >> 8;
            bb |= bb >> 4;
            bb |= bb >> 2;
            bb |= bb >> 1;
            
            return (bb >> 1) + 1;
        }
    } 

    /**
        @dev Find the index of the lest significant set bit. (trailing zero count)
     */ 
    function bitScanForward256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return uint8(LOOKUP_TABLE_256[(isolateLS1B256(bb) * DEBRUIJN_256) >> 248]);
        }   
    }

    /**
        @dev Find the index of the most significant set bit.
     */ 
    function bitScanReverse256(uint256 bb) pure internal returns (uint8) {
        unchecked {
            return 255 - uint8(LOOKUP_TABLE_256[((isolateMS1B256(bb) * DEBRUIJN_256) >> 248)]);
        }   
    }

}