// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../manifold/libraries-solidity/access/AdminControlUpgradeable.sol";
import "../../openzeppelin-upgradeable/access/IAccessControlUpgradeable.sol";
import "../../openzeppelin/utils/introspection/ERC165Checker.sol";
import "../../manifold/libraries-solidity/access/IAdminControl.sol";
import "../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../manifold/royalty-registry/specs/INiftyGateway.sol";
import "../../manifold/royalty-registry/specs/IFoundation.sol";
import "../../manifold/royalty-registry/libraries/SuperRareContracts.sol";
import "../../manifold/royalty-registry/specs/IManifold.sol";
import "../../manifold/royalty-registry/specs/IRarible.sol";
import "../../manifold/royalty-registry/specs/IFoundation.sol";
import "../../manifold/royalty-registry/specs/ISuperRare.sol";
import "../../manifold/royalty-registry/specs/IEIP2981.sol";
import "../../manifold/royalty-registry/specs/IZoraOverride.sol";
import "../../manifold/royalty-registry/specs/IArtBlocksOverride.sol";
import "../../manifold/royalty-registry/specs/IKODAV2Override.sol";
import {IRoyaltySplitter, Recipient} from "../../manifold/royalty-registry/overrides/IRoyaltySplitter.sol";
import "../../mojito/interfaces/IRoyaltyEngine.sol";
import "../../openzeppelin/utils/Address.sol";
/**
 * @dev RoyaltyEngine to lookup royalty configurations.The main purpose of this contract to getRoyalty
 * information from standards.If own royalty is configured, it fetchs the royalty information from
 * own Royalty, else returns royalty information from other standards
 */
contract RoyaltyEngine is IRoyaltyEngine, AdminControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    using Address for address;

    // Maximum basis points allowed to set during the royalty
    uint256 public immutable maxBps;

    // Track blacklisted collectionAddress
    EnumerableSet.AddressSet private blacklistedCollectionAddress;

    // Track blacklisted walletAddress
    EnumerableSet.AddressSet private blacklistedWalletAddress;

    //Royalty Configurations stored at the collection level
    mapping(address => address payable[]) internal collectionRoyaltyReceivers;
    mapping(address => uint256[]) internal collectionRoyaltyBPS;

    //Royalty Configurations stored at the token level
    mapping(address => mapping(uint256 => address payable[]))
        internal tokenRoyaltyReceivers;
    mapping(address => mapping(uint256 => uint256[])) internal tokenRoyaltyBPS;

    /// @notice Emitted when an Withdraw Payout is executed
    /// @param toAddress To Address amount is transferred
    /// @param amount The amount transferred
    event WithdrawPayout(address toAddress, uint256 amount);

    constructor(uint256 maxBasisPoints) {
        require(
            maxBasisPoints < 10_000,
            "maxBasisPoints should not be equal or exceed than the value 10_000"
        );
        maxBps = maxBasisPoints;
        __Ownable_init();
    }

    /**
     * @notice Setting royalty for collection.
     * @param collectionAddress contract address
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(collectionAddress, msg.sender) ||
                _isCollectionOwner(collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        require(
            receivers.length == basisPoints.length,
            "Invalid input length for receivers and basis points"
        );
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(
            totalBasisPoints < maxBps,
            "Total basis points should be less than the maximum basis points"
        );
        collectionRoyaltyReceivers[collectionAddress] = receivers;
        collectionRoyaltyBPS[collectionAddress] = basisPoints;
        emit RoyaltiesUpdated(collectionAddress, receivers, basisPoints);
    }

    /**
     * @notice Setting royalty for token.
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setTokenRoyalty(
        address collectionAddress,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external override {
        require(
            isAdmin(msg.sender) ||
                _isCollectionAdmin(collectionAddress, msg.sender) ||
                _isCollectionOwner(collectionAddress, msg.sender),
            "sender should be a Mojito Admin or a Collection Admin or a Collection Owner"
        );
        require(
            !blacklistedCollectionAddress.contains(collectionAddress) &&
                !blacklistedWalletAddress.contains(msg.sender),
            "Sender and CollectionAddress should not be blacklisted"
        );
        require(
            receivers.length == basisPoints.length,
            "Invalid input length for receivers and basis points"
        );
        uint256 totalBasisPoints;
        for (uint256 i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(
            totalBasisPoints < maxBps,
            "Total basis points should be less than the maximum basis points"
        );
        tokenRoyaltyReceivers[collectionAddress][tokenId] = receivers;
        tokenRoyaltyBPS[collectionAddress][tokenId] = basisPoints;
        emit TokenRoyaltiesUpdated(
            collectionAddress,
            tokenId,
            receivers,
            basisPoints
        );
    }

    /**
     * @notice getting royalty information
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @return recipients returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
     **/
    function getRoyalty(address collectionAddress, uint256 tokenId)
        external
        view
        override
        returns (
            address payable[] memory recipients,
            uint256[] memory basisPoints
        )
    {
        if (tokenRoyaltyReceivers[collectionAddress][tokenId].length > 0) {
            recipients = tokenRoyaltyReceivers[collectionAddress][tokenId];
            basisPoints = tokenRoyaltyBPS[collectionAddress][tokenId];
        } else if (collectionRoyaltyReceivers[collectionAddress].length > 0) {
            recipients = collectionRoyaltyReceivers[collectionAddress];
            basisPoints = collectionRoyaltyBPS[collectionAddress];
        } else {
            (recipients, basisPoints) = getRoyaltyStandardInfo(
                collectionAddress,
                tokenId
            );
        }
        return (recipients, basisPoints);
    }

    /**
     * @notice getting royalty information from Other royalty standard.
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @return recipients returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
     **/
    function getRoyaltyStandardInfo(address collectionAddress, uint256 tokenId)
        private
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory basisPoints
        )
    {
        uint256 value = 1 ether;
        // MANIFOLD : Supports manifold interface to get Royalty Info
        try IManifold(collectionAddress).getRoyalties(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            require(
                recipients_.length == bps.length,
                "recipient's length should be equal to basis point length"
            );
            return (recipients_, bps);
        } catch {}

        // EIP2981 AND ROYALTYSPLITTER : Supports EIP2981 and royaltysplitter interface to get Royalty Info
        try IEIP2981(collectionAddress).royaltyInfo(tokenId, value) returns (
            address recipient,
            uint256 amount
        ) {
            require(amount < value, "Invalid royalty amount");
            try IRoyaltySplitter(collectionAddress).getRecipients() returns (
                Recipient[] memory splitRecipients
            ) {
                recipients = new address payable[](splitRecipients.length);
                basisPoints = new uint256[](splitRecipients.length);
                uint256 sum = 0;
                uint256 splitRecipientsLength = splitRecipients.length;
                for (uint256 i = 0; i < splitRecipientsLength; ) {
                    Recipient memory splitRecipient = splitRecipients[i];
                    recipients[i] = payable(splitRecipient.recipient);
                    uint256 splitAmount = (splitRecipient.bps * amount) /
                        10_000;
                    sum += splitAmount;
                    basisPoints[i] = splitRecipient.bps;
                    unchecked {
                        ++i;
                    }
                }
                // sum can be less than amount, otherwise small-value listings can break
                require(sum <= amount, "Invalid split");

                return (recipients, basisPoints);
            } catch {
                recipients = new address payable[](1);
                basisPoints = new uint256[](1);
                recipients[0] = payable(recipient);
                basisPoints[0] = (amount * 10_000) / value;
                return (recipients, basisPoints);
            }
        } catch {}

        // SUPERRARE : Supports superrare interface to get Royalty Info
        if (
            collectionAddress == SuperRareContracts.SUPERRARE_V1 ||
            collectionAddress == SuperRareContracts.SUPERRARE_V2
        ) {
            try
                ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                    .tokenCreator(collectionAddress, tokenId)
            returns (address payable creator) {
                try
                    ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY)
                        .calculateRoyaltyFee(collectionAddress, tokenId, value)
                returns (uint256 amount) {
                    recipients = new address payable[](1);
                    basisPoints = new uint256[](1);
                    recipients[0] = creator;
                    basisPoints[0] = (amount * 10_000) / value;
                    return (recipients, basisPoints);
                } catch {}
            } catch {}
        }
        // RaribleV2 : Supports rarible v2 interface to get Royalty Info
        try
            IRaribleV2(collectionAddress).getRaribleV2Royalties(tokenId)
        returns (IRaribleV2.Part[] memory royalties) {
            recipients = new address payable[](royalties.length);
            basisPoints = new uint256[](royalties.length);
            for (uint256 i = 0; i < royalties.length; i++) {
                recipients[i] = royalties[i].account;
                basisPoints[i] = royalties[i].value;
            }
            require(
                recipients.length == basisPoints.length,
                "Invalid royalty amount"
            );
            return (recipients, basisPoints);
        } catch {}

        // RaribleV1 :Supports manifold interface to get Royalty Info
        try IRaribleV1(collectionAddress).getFeeRecipients(tokenId) returns (
            address payable[] memory recipients_
        ) {
            recipients_ = IRaribleV1(collectionAddress).getFeeRecipients(
                tokenId
            );
            try IRaribleV1(collectionAddress).getFeeBps(tokenId) returns (
                uint256[] memory bps
            ) {
                require(
                    recipients_.length == bps.length,
                    "recipients length should be equal to bps length"
                );
                return (recipients_, bps);
            } catch {}
        } catch {}

        //FOUNDATION : Supports foundation interface to get Royalty Info
        try IFoundation(collectionAddress).getFees(tokenId) returns (
            address payable[] memory recipients_,
            uint256[] memory bps
        ) {
            require(
                recipients_.length == bps.length,
                "recipients length should be equal to bps length"
            );
            return (recipients_, bps);
        } catch {}

        // ZORA : Supports Zora interface to get Royalty Info
        try
            IZoraOverride(collectionAddress).convertBidShares(
                collectionAddress,
                tokenId
            )
        returns (address payable[] memory recipients_, uint256[] memory bps) {
            require(
                recipients_.length == bps.length,
                "recipients length should be equal to bps length"
            );
            return (recipients_, bps);
        } catch {}

        // ARTBLOCKS : Supports artblocks interface to get Royalty Info
        try
            IArtBlocksOverride(collectionAddress).getRoyalties(
                collectionAddress,
                tokenId
            )
        returns (address payable[] memory recipients_, uint256[] memory bps) {
            require(
                recipients_.length == bps.length,
                "recipients length should be equal to bps length"
            );
            return (recipients_, bps);
        } catch {}

        // KNOWNORGIN : Supports knownorgin interface to get Royalty Info
        try
            IKODAV2Override(collectionAddress).getKODAV2RoyaltyInfo(
                collectionAddress,
                tokenId,
                value
            )
        returns (
            address payable[] memory _recipients,
            uint256[] memory _amounts
        ) {
            require(
                _recipients.length == _amounts.length,
                "recipients length should be equal to bps length"
            );
            uint256 totalAmount;
            recipients = new address payable[](_recipients.length);
            basisPoints = new uint256[](_recipients.length);
            for (uint256 i; i < _recipients.length; i++) {
                recipients[i] = payable(_recipients[i]);
                basisPoints[i] = (_amounts[i] * 10_000) / value;
                totalAmount += _amounts[i];
            }
            require(totalAmount < value, "Invalid royalty amount");
            return (recipients, basisPoints);
        } catch {}

        return (recipients, basisPoints);
    }

    /**
     * @notice Compute royalty Shares
     * @param collectionAddress contract address
     * @param tokenId Token Id
     * @param amount amount involved to compute the Shares.
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps.
     * @return feeAmount returns set of Shares.
     **/
    function getRoyaltySplitshare(
        address collectionAddress,
        uint256 tokenId,
        uint256 amount
    )
        external
        view
        override
        returns (
            address payable[] memory receivers,
            uint256[] memory basisPoints,
            uint256[] memory feeAmount
        )
    {
        if (tokenRoyaltyReceivers[collectionAddress][tokenId].length > 0) {
            receivers = tokenRoyaltyReceivers[collectionAddress][tokenId];
            basisPoints = tokenRoyaltyBPS[collectionAddress][tokenId];
            for (uint256 i = 0; i < receivers.length; i++) {
                feeAmount[i] = (basisPoints[i] * amount) / 10_000;
            }
        } else if (collectionRoyaltyReceivers[collectionAddress].length > 0) {
            receivers = collectionRoyaltyReceivers[collectionAddress];
            basisPoints = collectionRoyaltyBPS[collectionAddress];
            for (uint256 i = 0; i < receivers.length; i++) {
                feeAmount[i] = (basisPoints[i] * amount) / 10_000;
            }
        }
        return (receivers, basisPoints, feeAmount);
    }

    /**
     * @notice checks the admin role of caller
     * @param collectionAddress contract address
     * @param collectionAdmin admin address of the collection.
     * @param isAdmin address is admin or not
     **/
    function _isCollectionAdmin(
        address collectionAddress,
        address collectionAdmin
    ) internal view returns (bool isAdmin) {
        if (
            ERC165Checker.supportsInterface(
                collectionAddress,
                type(IAdminControl).interfaceId
            ) && IAdminControl(collectionAddress).isAdmin(collectionAdmin)
        ) {
            return true;
        }
    }

    /**
     * @notice checks the Owner role of caller
     * @param collectionAddress contract address
     * @param collectionAdmin admin address of the collection.
     * @param isOwner address is owner or not
     **/
    function _isCollectionOwner(
        address collectionAddress,
        address collectionAdmin
    ) internal view returns (bool isOwner) {
        try OwnableUpgradeable(collectionAddress).owner() returns (
            address owner
        ) {
            if (owner == collectionAdmin) return true;
        } catch {}

        try
            IAccessControlUpgradeable(collectionAddress).hasRole(
                0x00,
                collectionAdmin
            )
        returns (bool hasRole) {
            if (hasRole) return true;
        } catch {}

        // Nifty Gateway overrides
        try
            INiftyBuilderInstance(collectionAddress).niftyRegistryContract()
        returns (address niftyRegistry) {
            try
                INiftyRegistry(niftyRegistry).isValidNiftySender(
                    collectionAdmin
                )
            returns (bool valid) {
                return valid;
            } catch {}
        } catch {}

        // Foundation overrides
        try
            IFoundationTreasuryNode(collectionAddress).getFoundationTreasury()
        returns (address payable foundationTreasury) {
            try
                IFoundationTreasury(foundationTreasury).isAdmin(collectionAdmin)
            returns (bool) {
                return isOwner;
            } catch {}
        } catch {}

        // Superrare & OpenSea & Rarible overrides
        // Tokens already support Ownable overrides

        return false;
    }

    /**
     * @notice Adds Collection address as blacklist
     * @param commonAddress  the Address to be blacklisted
     **/
    function blacklistAddress(address commonAddress)
        external
        override
        adminRequired
    {
        if (
            Address.isContract(commonAddress)
        ) {
            if (!blacklistedCollectionAddress.contains(commonAddress)) {
                blacklistedCollectionAddress.add(commonAddress);
            }
        } else {
            if (!blacklistedWalletAddress.contains(commonAddress)) {
                blacklistedWalletAddress.add(commonAddress);
            }
        }
        emit AddedBlacklistedAddress(commonAddress, msg.sender);
    }

    /**
     * @notice revoke the blacklistedAddress
     * @param commonAddress address info
     **/
    function revokeBlacklistedAddress(address commonAddress)
        external
        override
        adminRequired
    {
        if (blacklistedCollectionAddress.contains(commonAddress)) {
            emit RevokedBlacklistedAddress(commonAddress, msg.sender);
            blacklistedCollectionAddress.remove(commonAddress);
        } else if (blacklistedWalletAddress.contains(commonAddress)) {
            emit RevokedBlacklistedAddress(commonAddress, msg.sender);
            blacklistedWalletAddress.remove(commonAddress);
        }
    }

    /**
     * @notice checks the blacklistedAddress
     * @param commonAddress address info
     **/
    function isBlacklistedAddress(address commonAddress)
        external
        view
        returns (bool)
    {
        return (blacklistedCollectionAddress.contains(commonAddress) ||
            blacklistedWalletAddress.contains(commonAddress));
    }

    /// @notice Withdraw the funds to owner
    function withdraw() external adminRequired {
        bool success;
        address payable to = payable(msg.sender);
        (success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, "withdraw failed");
        emit WithdrawPayout(to, address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../../../openzeppelin/utils/structs/EnumerableSet.sol";
import "../../../openzeppelin/utils/introspection/ERC165.sol";
import "../../../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "./IAdminControl.sol";

abstract contract AdminControlUpgradeable is
    OwnableUpgradeable,
    IAdminControl,
    ERC165
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IAdminControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(
            owner() == msg.sender || _admins.contains(msg.sender),
            "AdminControl: Must be owner or admin"
        );
        _;
    }

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins()
        external
        view
        override
        returns (address[] memory admins)
    {
        admins = new address[](_admins.length());
        for (uint256 i = 0; i < _admins.length(); i++) {
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
    function isAdmin(address admin) public view override returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Checker.sol)

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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../../../openzeppelin/utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Nifty builder instance
 */
interface INiftyBuilderInstance {
   function niftyRegistryContract() external view returns (address);
}

/**
 * @dev Nifty registry
 */
interface INiftyRegistry {
    /**
     * @dev function to see if sending key is valid
     */
    function isValidNiftySender(address sending_key) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFoundation {
    /*
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

interface IFoundationTreasuryNode {
    function getFoundationTreasury() external view returns (address payable);
}

interface IFoundationTreasury {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SuperRareContracts {
    address public constant SUPERRARE_REGISTRY = 0x17B0C8564E53f22364A6C8de6F7ca5CE9BEa4e5D;
    address public constant SUPERRARE_V1 = 0x41A322b28D0fF354040e2CbC676F0320d8c8850d;
    address public constant SUPERRARE_V2 = 0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}


interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }
    function getRaribleV2Royalties(uint256 id) external view returns (Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISuperRareRegistry {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Get the token creator which will receive royalties of the given token
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     */
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * EIP-2981
 */
interface IEIP2981 {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Paired down version of the Zora Market interface
 */
interface IZoraMarket {
    struct ZoraDecimal {
        uint256 value;
    }

    struct ZoraBidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        ZoraDecimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        ZoraDecimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        ZoraDecimal owner;
    }

    function bidSharesForToken(uint256 tokenId) external view returns (ZoraBidShares memory);
}

/**
 * Paired down version of the Zora Media interface
 */
interface IZoraMedia {

    /**
     * Auto-generated accessors of public variables
     */
    function marketContract() external view returns(address);
    function previousTokenOwners(uint256 tokenId) external view returns(address);
    function tokenCreators(uint256 tokenId) external view returns(address);

    /**
     * ERC721 function
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * Interface for a Zora media override
 */
interface IZoraOverride {

    /**
     * @dev Convert bid share configuration of a Zora Media token into an array of receivers and bps values
     *      Does not support prevOwner and sell-on amounts as that is specific to Zora marketplace implementation
     *      and requires updates on the Zora Media and Marketplace to update the sell-on amounts/previous owner values.
     *      An off-Zora marketplace sale will break the sell-on functionality.
     */
    function convertBidShares(address media, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *  Interface for an Art Blocks override
 */
interface IArtBlocksOverride {
    /**
     * @dev Get royalites of a token at a given tokenAddress.
     *      Returns array of receivers and basisPoints.
     *
     *  bytes4(keccak256('getRoyalties(address,uint256)')) == 0x9ca7dc7a
     *
     *  => 0x9ca7dc7a = 0x9ca7dc7a
     */
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

/// @author: knownorigin.io

pragma solidity ^0.8.0;

interface IKODAV2 {
    function editionOfTokenId(uint256 _tokenId) external view returns (uint256 _editionNumber);

    function artistCommission(uint256 _editionNumber)
        external
        view
        returns (address _artistAccount, uint256 _artistCommission);

    function editionOptionalCommission(uint256 _editionNumber)
        external
        view
        returns (uint256 _rate, address _recipient);
}

interface IKODAV2Override {
    /// @notice Emitted when the royalties fee changes
    event CreatorRoyaltiesFeeUpdated(uint256 _oldCreatorRoyaltiesFee, uint256 _newCreatorRoyaltiesFee);

    /// @notice For the given KO NFT and token ID, return the addresses and the amounts to pay
    function getKODAV2RoyaltyInfo(address _tokenAddress, uint256 _id, uint256 _amount)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    /// @notice Allows the owner() to update the creator royalties
    function updateCreatorRoyalties(uint256 _creatorRoyaltiesFee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

struct Recipient {
    address payable recipient;
    uint16 bps;
}

interface IRoyaltySplitter is IERC165 {
    /**
     * @dev Set the splitter recipients. Total bps must total 10000.
     */
    function setRecipients(Recipient[] calldata recipients) external;

    /**
     * @dev Get the splitter recipients;
     */
    function getRecipients() external view returns (Recipient[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for RoyaltyEngine
 */
interface IRoyaltyEngine {
    /**
     * @notice Emits when an collection level Royalty is configured
     * @param collectionAddress contract address 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    event RoyaltiesUpdated(
        address indexed collectionAddress,
        address payable[] receivers,
        uint256[] basisPoints
    );

    /**
     * @notice Emits when an Token level Royalty is configured
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    event TokenRoyaltiesUpdated(
        address collectionAddress,
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );
    
    /**
     * @notice Emits when address is added into Black List.
     * @param account BlackListed NFT contract address or wallet address
     * @param sender caller address
    **/
    event AddedBlacklistedAddress(
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Eits when address is removed from Black List.
     * @param account BlackListed NFT contract address or wallet address
     * @param sender caller address
    **/
    event RevokedBlacklistedAddress(
        address indexed account,
        address indexed sender
    );
    
    /**
     * @notice Setting royalty for NFT Collection.
     * @param collectionAddress NFT contract address 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;
    
    /**
     * @notice Setting royalty for token.
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setTokenRoyalty(
        address collectionAddress,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @notice getting royalty information from Other royalty standard.
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
    **/
    function getRoyalty(address collectionAddress, uint256 tokenId)
        external
	view
        returns (address payable[] memory receivers, uint256[] memory basisPoints);
    
    /**
     * @notice Compute royalty Shares
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param amount amount involved to compute the Shares. 
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps.
     * @return feeAmount returns set of Shares.
    **/
    function getRoyaltySplitshare(
        address collectionAddress,
        uint256 tokenId,
        uint256 amount
    )
        external
	view
        returns (
            address payable[] memory receivers,
            uint256[] memory basisPoints,
            uint256[] memory feeAmount
        );
    
    /**
     * @notice Adds address as blacklist
     * @param commonAddress user wallet address 
    **/
    function blacklistAddress(address commonAddress) external;

    /**
     * @notice revoke the blacklistedAddress
     * @param commonAddress address info
    **/
    function revokeBlacklistedAddress(address commonAddress) external;
        
    /**
     * @notice checks the blacklistedAddress
     * @param commonAddress address info
    **/
    function isBlacklistedAddress(address commonAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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