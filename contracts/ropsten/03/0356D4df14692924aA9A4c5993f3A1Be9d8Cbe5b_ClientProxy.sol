// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IBosonClient } from "../../interfaces/IBosonClient.sol";
import { IBosonConfigHandler } from "../../interfaces/IBosonConfigHandler.sol";
import { BosonConstants } from "../../domain/BosonConstants.sol";
import { ClientLib } from "./ClientLib.sol";
import { Proxy } from "./Proxy.sol";

/**
 * @title ClientProxy
 *
 * @notice Delegates calls to a Boson Protocol Client implementation contract,
 * such that functions on it execute in the context (address, storage)
 * of this proxy, allowing the implementation contract to be upgraded
 * without losing the accumulated state data.
 *
 * Protocol clients are the contracts in the system that communicate with
 * the facets of the ProtocolDiamond rather than acting as facets themselves.
 *
 * Each Protocol client contract will be deployed behind its own proxy for
 * future upgradability.
 */
contract ClientProxy is IBosonClient, BosonConstants, Proxy {

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 role) {
        require(ClientLib.hasRole(role), "Access denied, caller doesn't have role");
        _;
    }

    constructor(
        address _accessController,
        address _protocolAddress,
        address _impl
    ) payable {

        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Store the AccessController address
        ps.accessController = IAccessControlUpgradeable(_accessController);

        // Store the Protocol Diamond address
        ps.protocolDiamond = _protocolAddress;

        // Store the implementation address
        ps.implementation = _impl;

    }

    /**
     * @dev Returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation()
    internal
    view
    override
    returns (address) {

        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Return the current implementation address
        return ps.implementation;

    }

    /**
     * @dev Set the implementation address
     */
    function setImplementation(address _impl)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Store the implementation address
        ps.implementation = _impl;

        // Notify watchers of state change
        emit Upgraded(_impl);

    }

    /**
     * @dev Get the implementation address
     */
    function getImplementation()
    external
    view
    override
    returns (address) {
        return _implementation();
    }

    /**
     * @notice Set the Boson Protocol AccessController
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * @param _accessController - the Boson Protocol AccessController address
     */
    function setAccessController(address _accessController)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Store the AccessController address
        ps.accessController = IAccessControlUpgradeable(_accessController);

        // Notify watchers of state change
        emit AccessControllerAddressChanged(_accessController);
    }

    /**
     * @notice Gets the address of the Boson Protocol AccessController contract.
     *
     * @return the address of the AccessController contract
     */
    function getAccessController()
    public
    view
    override
    returns(IAccessControlUpgradeable)
    {
        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Return the current AccessController address
        return ps.accessController;
    }

    /**
     * @notice Set the ProtocolDiamond address
     *
     * Emits an ProtocolAddressChanged event.
     *
     * @param _protocolAddress - the ProtocolDiamond address
     */
    function setProtocolAddress(address _protocolAddress)
    external
    onlyRole(UPGRADER)
    override
    {
        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Store the ProtocolDiamond address
        ps.protocolDiamond = _protocolAddress;

        // Notify watchers of state change
        emit ProtocolAddressChanged(_protocolAddress);
    }

    /**
     * @notice Gets the address of the ProtocolDiamond contract.
     *
     * @return the address of the ProtocolDiamond contract
     */
    function getProtocolAddress()
    public
    override
    view
    returns(address)
    {
        // Get the ProxyStorage struct
        ClientLib.ProxyStorage storage ps = ClientLib.proxyStorage();

        // Return the current ProtocolDiamond address
        return ps.protocolDiamond;
    }

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IBosonConfigHandler } from "./IBosonConfigHandler.sol";

/**
 * @title IBosonClient
 *
 * @notice Delegates calls to a Boson Protocol client implementation contract,
 * such that functions on it execute in the context (address, storage)
 * of this proxy, allowing the implementation contract to be upgraded
 * without losing the accumulated state data.
 *
 * Protocol clients are any contracts that communicate with the the ProtocolDiamond
 * from the outside, rather than acting as facets themselves. Protocol
 * client contracts will be deployed behind their own proxies for upgradeability.
 *
 * Example:
 * The BosonVoucher NFT contract acts as a client of the ProtocolDiamond when
 * accessing information about offers associated with the vouchers it maintains.
 *
 * The ERC-165 identifier for this interface is: 0x9bc69c79 // TODO: Recalc
 */
interface IBosonClient {
    // Events
    event Upgraded(address indexed implementation);
    event ProtocolAddressChanged(address indexed protocol);
    event AccessControllerAddressChanged(address indexed accessController);

    /**
     * @dev Set the implementation address
     */
    function setImplementation(address _implementation) external;

    /**
     * @dev Get the implementation address
     */
    function getImplementation() external view returns (address);

    /**
     * @notice Set the AccessController address
     *
     * Emits an AccessControllerAddressChanged event.
     *
     * @param _accessController - the AccessController address
     */
    function setAccessController(address _accessController) external;

    /**
     * @notice Gets the address of the AccessController.
     *
     * @return the address of the AccessController
     */
    function getAccessController() external view returns (IAccessControlUpgradeable);

    /**
     * @notice Set the ProtocolDiamond address
     *
     * Emits an ProtocolAddressChanged event.
     *
     * @param _protocol - the ProtocolDiamond address
     */
    function setProtocolAddress(address _protocol) external;

    /**
     * @notice Gets the address of the ProtocolDiamond
     *
     * @return the address of the ProtocolDiamond
     */
    function getProtocolAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../domain/BosonTypes.sol";

/**
 * @title IBosonConfigHandler
 *
 * @notice Handles management of various protocol-related settings.
 *
 * The ERC-165 identifier for this interface is: 0x19037fd6
 */
interface IBosonConfigHandler {
    /// Events
    event VoucherAddressChanged(address indexed voucher, address indexed changedBy);
    event TokenAddressChanged(address indexed tokenAddress, address indexed changedBy);
    event TreasuryAddressChanged(address indexed treasuryAddress, address indexed changedBy);
    event ProtocolFeePercentageChanged(uint16 feePercentage, address indexed changedBy);
    event MaxOffersPerGroupChanged(uint16 maxOffersPerGroup, address indexed changedBy);
    event MaxTwinsPerBundleChanged(uint16 maxTwinsPerBundle, address indexed changedBy);
    event MaxOffersPerBundleChanged(uint16 maxOffersPerBundle, address indexed changedBy);

    /**
     * @notice Sets the address of the Boson Token (ERC-20) contract.
     *
     * Emits a TokenAddressChanged event.
     *
     * @param _token - the address of the token contract
     */
    function setTokenAddress(address payable _token) external;

    /**
     * @notice The tokenAddress getter
     */
    function getTokenAddress() external view returns (address payable);

    /**
     * @notice Sets the address of the Boson Protocol treasury.
     *
     * Emits a TreasuryAddressChanged event.
     *
     * @param _treasuryAddress - the address of the treasury
     */
    function setTreasuryAddress(address payable _treasuryAddress) external;

    /**
     * @notice The treasuryAddress getter
     */
    function getTreasuryAddress() external view returns (address payable);

    /**
     * @notice Sets the address of the Voucher NFT address (proxy)
     *
     * Emits a VoucherAddressChanged event.
     *
     * @param _voucher - the address of the nft contract
     */
    function setVoucherAddress(address _voucher) external;

    /**
     * @notice The Voucher address getter
     */
    function getVoucherAddress() external view returns (address);

    /**
     * @notice Sets the protocol fee percentage.
     *
     * Emits a ProtocolFeePercentageChanged event.
     *
     * Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @param _feePercentage - the percentage that will be taken as a fee from the net of a Boson Protocol exchange
     */
    function setProtocolFeePercentage(uint16 _feePercentage) external;

    /**
     * @notice Get the protocol fee percentage
     */
    function getProtocolFeePercentage() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of offers that can be added to a group in a single transaction
     *
     * Emits a MaxOffersPerGroupChanged event.
     *
     * @param _maxOffersPerGroup - the maximum length of {BosonTypes.Group.offerIds}
     */
    function setMaxOffersPerGroup(uint16 _maxOffersPerGroup) external;

    /**
     * @notice Get the maximum offers per group
     */
    function getMaxOffersPerGroup() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of twin that can be added to a bundle in a single transaction
     *
     * Emits a MaxTwinsPerBundleChanged event.
     *
     * @param _maxTwinsPerBundle - the maximum length of {BosonTypes.Bundle.twinIds}
     */
    function setMaxTwinsPerBundle(uint16 _maxTwinsPerBundle) external;

    /**
     * @notice Get the maximum twins per bundle
     */
    function getMaxTwinsPerBundle() external view returns (uint16);

    /**
     * @notice Get the maximum offers per bundle
     */
    function getMaxOffersPerBundle() external view returns (uint16);

    /**
     * @notice Sets the maximum numbers of offer that can be added to a bundle in a single transaction
     *
     * Emits a MaxOffersPerBundleChanged event.
     *
     * @param _maxOffersPerBundle - the maximum length of {BosonTypes.Bundle.offerIds}
     */
    function setMaxOffersPerBundle(uint16 _maxOffersPerBundle) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonConstants
 *
 * @notice Constants used by the Boson Protocol contract ecosystem.
 */
contract BosonConstants {
    // Access Control Roles
    bytes32 internal constant ADMIN = keccak256("ADMIN"); // Role Admin
    bytes32 internal constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
    bytes32 internal constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
    bytes32 internal constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
    bytes32 internal constant RESOLVER = keccak256("RESOLVER"); // Role for resolving the outcome of an escalated dispute
    bytes32 internal constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

    // Revert Reasons: General
    string internal constant INVALID_ADDRESS = "Invalid address";

    // Revert Reasons: Facet initializer related
    string internal constant ALREADY_INITIALIZED = "Already initialized";

    // Revert Reasons: Access related
    string internal constant ACCESS_DENIED = "Access denied, caller doesn't have role";
    string internal constant NOT_OPERATOR = "Not seller's operator";
    string internal constant NOT_ADMIN = "Not seller's admin";

    // Revert Reasons: Account-related
    string internal constant NO_SUCH_SELLER = "No such seller";
    string internal constant MUST_BE_ACTIVE = "Account must be active";
    string internal constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
    string internal constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";

    // Revert Reasons: Offer related
    string internal constant NO_SUCH_OFFER = "No such offer";
    string internal constant OFFER_PERIOD_INVALID = "Offer period invalid";
    string internal constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
    string internal constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
    string internal constant OFFER_NOT_UPDATEABLE = "Offer not updateable";
    string internal constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
    string internal constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
    string internal constant OFFER_HAS_EXPIRED = "Offer has expired";
    string internal constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
    string internal constant OFFER_SOLD_OUT = "Offer has sold out";

    // Revert Reasons: Group related
    string internal constant NO_SUCH_GROUP = "No such offer";
    string internal constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
    string internal constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
    string internal constant NOTHING_UPDATED = "Nothing updated";
    string internal constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

    // Revert Reasons: Exchange related
    string internal constant NO_SUCH_EXCHANGE = "No such exchange";

    // Revert Reasons: Twin related
    string internal constant NO_SUCH_TWIN = "No such twin";
    string internal constant NO_TRANSFER_APPROVED = "No transfer approved";
    string internal constant UNSUPPORTED_TOKEN = "Unsupported token";

    // Revert Reasons: Bundle related
    string internal constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
    string internal constant TWIN_ALREADY_EXISTS_IN_SAME_BUNDLE = "Twin already exists in the same bundle";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "../../interfaces/IBosonConfigHandler.sol";

/**
 * @title ClientLib
 *
 * - Defines storage slot structure
 * - Provides slot accessor
 * - Defines hasRole function
 */
library ClientLib {

    struct ProxyStorage {

        // The AccessController address
        IAccessControlUpgradeable accessController;

        // The ProtocolDiamond address
        address protocolDiamond;

        // The client implementation address
        address implementation;
    }

    /**
     * @dev Storage slot with the address of the Boson Protocol AccessController
     *
     * This is obviously not a standard EIP-1967 slot. This is because that standard
     * wants a single piece of data (implementation address) whereas we have several.
     */
    bytes32 internal constant PROXY_SLOT = keccak256("Boson.Protocol.ClientProxy");

    /**
     * @notice Get the Proxy storage slot
     *
     * @return ps - Proxy storage slot cast to ProxyStorage
     */
    function proxyStorage() internal pure returns (ProxyStorage storage ps) {
        bytes32 position = PROXY_SLOT;
        assembly {
            ps.slot := position
        }
    }

    /**
     * @dev Checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    function hasRole(bytes32 role) internal view returns (bool) {
        ProxyStorage storage ps = proxyStorage();
        return ps.accessController.hasRole(role, msg.sender);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */
contract BosonTypes {
    enum EvaluationMethod {
        None,
        AboveThreshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed
    }

    enum DisputeState {
        Disputed,
        Retracted,
        Resolved,
        Escalated,
        Decided
    }

    struct Seller {
        uint256 id;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        bool active;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct Resolver {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        uint256 validFromDate;
        uint256 validUntilDate;
        uint256 redeemableFromDate;
        uint256 fulfillmentPeriodDuration;
        uint256 voucherValidDuration;
        address exchangeToken;
        string metadataUri;
        string offerChecksum;
        bool voided;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        Condition condition;
    }

    struct Condition {
        EvaluationMethod method;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        Voucher voucher;
        bool disputed;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        string complaint;
        DisputeState state;
        Resolution resolution;
    }

    struct Resolution {
        uint256 buyerPercent;
    }

    struct Receipt {
        Offer offer;
        Exchange exchange;
        Dispute dispute;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 supplyAvailable; // ERC-1155 / ERC-20
        uint256[] supplyIds; // ERC-721
        uint256 tokenId; // ERC-1155
        address tokenAddress; // all
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }
}