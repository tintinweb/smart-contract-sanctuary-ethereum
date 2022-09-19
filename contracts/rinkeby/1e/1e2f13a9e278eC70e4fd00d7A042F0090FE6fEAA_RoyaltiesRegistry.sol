// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IRoyaltiesRegistry.sol";
import "./specs/IRarible.sol";
import "../../libraries/BPS.sol";
import "../../tokens/IERC721LA.sol";
import "../../extensions/AccessControl.sol";
import "./RoyaltiesState.sol";
import "../../extensions/LAInitializable.sol";


/**
 * @notice Registry to lookup royalty configurations for different royalty specs
 */
contract RoyaltiesRegistry is ERC165, AccessControl, LAInitializable, IRoyaltiesRegistry {
    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               CONSTANTS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    uint256 private constant MAX_BPS = 10_000;
    uint256 private constant EDITION_TOKEN_MULTIPLIER = 10e5;

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               MODIFIERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    modifier isAuthorized(address collectionAddress) {
        bool isOwner = hasRole(DEPLOYER_ROLE, msg.sender);
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
        bool isOwner = hasRole(DEPLOYER_ROLE, msg.sender);
        bool isEditionCreator = _isEditionCreator(collectionAddress, editionId);
        if (!isOwner && !isEditionCreator) {
            revert NotApproved();
        }
        _;
    }

    /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
     *                               INITIALIZERS
     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
    function initialize() public notInitialized  {
        _grantRole(DEPLOYER_ROLE, msg.sender);
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
        view
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
pragma solidity ^0.8.4;
import "./LAInitializable.sol";

abstract contract AccessControl {
    error AccessControlNotAllowed();

    bytes32 public constant COLLECTION_ADMIN_ROLE =
        keccak256("COLLECTION_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEPLOYER_ROLE = 0x00;

    struct RoleState {
        mapping(bytes32 => mapping(address => bool)) _roles;
    }

    function _getAccessControlState()
        internal
        pure
        returns (RoleState storage state)
    {
        bytes32 position = keccak256("liveart.AccessControl");
        assembly {
            state.slot := position
        }
    }

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Checks that msg.sender has a specific role.
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @notice Checks that msg.sender has COLLECTION_ADMIN_ROLE
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyAdmin() {
        _checkRole(COLLECTION_ADMIN_ROLE);
        _;
    }

    /**
     * @notice Checks that msg.sender has MINTER_ROLE
     * Reverts with a AccessControlNotAllowed.
     *
     */
    modifier onlyMinter() {
        _checkRole(MINTER_ROLE);
        _;
    }

    /**
     * @notice Checks if role is assigned to account
     *
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        RoleState storage state = _getAccessControlState();
        return state._roles[role][account];
    }

    /**
     * @notice Revert with a AccessControlNotAllowed message if `msg.sender` is missing `role`.
     *
     */
    function _checkRole(bytes32 role) internal view virtual {
        if (!hasRole(role, msg.sender)) {
            revert AccessControlNotAllowed();
        }
    }

    /**
     * @notice Grants `role` to `account`.
     *
     * @dev If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        onlyRole(COLLECTION_ADMIN_ROLE)
    {
        _grantRole(role, account);
    }

    /**
     * @notice Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have COLLECTION_ADMIN_ROLE role.
     */
    function revokeRole(bytes32 role, address account)
        public
        onlyRole(COLLECTION_ADMIN_ROLE)
    {
        _revokeRole(role, account);
    }

    /**
     * @notice Revokes `role` from the calling account.
     *
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        if (account != msg.sender) {
            revert AccessControlNotAllowed();
        }

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        RoleState storage state = _getAccessControlState();
        if (!hasRole(role, account)) {
            state._roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        RoleState storage state = _getAccessControlState();
        if (hasRole(role, account)) {
            state._roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
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

abstract contract LAInitializable {
    error AlreadyInitialized();

    struct InitializableState {
        bool _initialized;
    }

    function _getInitializableState() internal pure returns (InitializableState storage state) {
        bytes32 position = keccak256("liveart.Initializable");
        assembly {
            state.slot := position
        }
    }

    modifier notInitialized() {
        InitializableState storage state = _getInitializableState();
        if (state._initialized) {
            revert AlreadyInitialized();
        }
        _;
        state._initialized = true;
    }

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
        view
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