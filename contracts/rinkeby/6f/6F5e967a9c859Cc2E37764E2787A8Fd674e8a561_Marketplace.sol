// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import {DirectSale} from "./DirectSale.sol";


import {AuctionSale} from "./AuctionSale.sol";

import {Core} from "./Core.sol";

error Marketplace_Only_Admin_Can_Access();

error Marketplace_Not_Valid_Contract_To_Add();

enum TokenStandard {
    ERC721,
    ERC1155
}

contract Marketplace is
    Initializable,
    DirectSale,
    AuctionSale,
    AccessControlUpgradeable
{
    using ERC165CheckerUpgradeable for address;

    event RegisterContract(
        address contractAddress,
        TokenStandard tokenStandard
    );

    event SetAdmin(address account);

    event SetDissrupPayment(address dissrupPayout);

    event RevokeAdmin(address account);

    function initialize(address dissrupPayout) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        super._setDissrupPayment(dissrupPayout);
    }

    function addContractAllowlist(address contractAddress) external onlyAdmin {
        TokenStandard tokenStandard;
        // 0x80ac58cd == ERC721
        if (contractAddress.supportsInterface(bytes4(0x80ac58cd))) {
            tokenStandard = TokenStandard.ERC721;

            // 0xd9b67a26 == ERC1155
        } else if (contractAddress.supportsInterface(bytes4(0xd9b67a26))) {
            tokenStandard = TokenStandard.ERC1155;
        } else {
            revert Marketplace_Not_Valid_Contract_To_Add();
        }

        super._addContractAllowlist(contractAddress);

        emit RegisterContract(contractAddress, tokenStandard);
    }

    function setDissrupPayment(address dissrupPayout) external onlyAdmin {
        super._setDissrupPayment(dissrupPayout);

        emit SetDissrupPayment(dissrupPayout);
    }

    function setAdmin(address account) external onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, account);

        emit SetAdmin(account);
    }

    function revokeAdmin(address account) external onlyAdmin {
        require(msg.sender != account, "Cannot remove yourself!");

        _revokeRole(DEFAULT_ADMIN_ROLE, account);

        emit RevokeAdmin(account);
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert Marketplace_Only_Admin_Can_Access();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
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
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
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
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {Constants} from "./Constants.sol";

import {Core} from "./Core.sol";

import {Payment} from "./Payment.sol";

/*
 * @notice revert in case of price below MIN_PRICE
 */
error Direct_Sale_Price_Too_Low();
/*
 * @notice revert in case of nft is been on list
 */
error Direct_Sale_Not_The_Owner(address msgSender, address seller);

error Direct_Sale_Amount_Cannot_Be_Zero();

error Direct_Sale_Contract_Address_Is_Not_Approved(address nftAddress);

error Direct_Sale_Not_A_Valid_Params_For_Buy();

error Direct_Sale_Required_Amount_To_Big_To_Buy();

error Direct_Sale_Not_Enough_Ether_To_Buy();

abstract contract DirectSale is
    Constants,
    Core,
    Payment,
    ReentrancyGuardUpgradeable
{
    struct DirectSaleList {
        address seller;
        uint256 amount;
        uint256 price;
    }

    uint256 internal _directSaleId;

    mapping(address => mapping(uint256 => mapping(uint256 => DirectSaleList)))
        private assetAndSaleIdToDirectSale;

    event ListDirectSale(
        uint256 saleId,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed seller,
        uint256 amount,
        uint256 price,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );

    event UpdateDirectSale(
        uint256 saleId,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed seller,
        uint256 price,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );

    event CancelDirectSale(
        address indexed nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address indexed seller
    );

    event BuyDirectSale(
        address indexed nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        address indexed buyer,
        uint256 dissrupCut,
        address indexed seller,
        uint256 sellerCut,
        address[] royalties,
        uint256[] royaltiesCuts
    );

    function listDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) external nonReentrant {
        if (price < Constants.MIN_PRICE) {
            // revert in case of price below MIN_PRICE
            revert Direct_Sale_Price_Too_Low();
        }

        if (amount == 0) {
            // revert in case amount is 0
            revert Direct_Sale_Amount_Cannot_Be_Zero();
        }

        if (_saleContractAllowlist[nftAddress] == false) {
            // revert in case contract is not approved by dissrup
            revert Direct_Sale_Contract_Address_Is_Not_Approved(nftAddress);
        }
        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);
        }

        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][++_directSaleId];

        address seller = msg.sender;

        // transfer asset to contract
        _trasferNFT(seller, address(this), nftAddress, tokenId, amount);

        _setRoyalties(_directSaleId, royaltiesPayees, royaltiesShares);

        // save to local map  the sale params
        directSale.seller = seller;
        directSale.amount = amount;
        directSale.price = price;

        emit ListDirectSale(
            _directSaleId,
            nftAddress,
            tokenId,
            seller,
            amount,
            price,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function updateDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 price,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) external nonReentrant {
        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        address seller = directSale.seller;

        if (seller != msg.sender) {
            //revert in case the msg.sender is not the owner (the lister) of the list
            revert Direct_Sale_Not_The_Owner(msg.sender, seller);
        }

        // check price
        if (price < MIN_PRICE) {
            revert Direct_Sale_Price_Too_Low();
        }

        // update price in storage
        directSale.price = price;

        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);

            _setRoyalties(saleId, royaltiesPayees, royaltiesShares);
        }
        emit UpdateDirectSale(
            saleId,
            nftAddress,
            tokenId,
            seller,
            price,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function cancelDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external nonReentrant {
        DirectSaleList memory directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (msg.sender != directSale.seller) {
            revert Direct_Sale_Not_The_Owner(msg.sender, directSale.seller);
        }

        _trasferNFT(
            address(this),
            directSale.seller,
            nftAddress,
            tokenId,
            directSale.amount
        );

        delete assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId];

        emit CancelDirectSale(nftAddress, tokenId, saleId, directSale.seller);
    }

    function buyDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount
    ) external payable nonReentrant {
        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (directSale.seller == address(0)) {
            // revert in case of a direct sale list is not exist
            revert Direct_Sale_Not_A_Valid_Params_For_Buy();
        }

        if (directSale.amount < amount) {
            // revert in case the require to buy is more then exist in marketplace
            revert Direct_Sale_Required_Amount_To_Big_To_Buy();
        }

        uint256 totalPrice = directSale.price * amount;
        address buyer = msg.sender;
        uint256 payment = msg.value;

        if (payment < totalPrice) {
            revert Direct_Sale_Not_Enough_Ether_To_Buy();
        }

        if (payment > totalPrice) {
            uint256 refund = payment - totalPrice;
            payable(buyer).transfer(refund);
        }

        _trasferNFT(address(this), buyer, nftAddress, tokenId, amount);

        directSale.amount = directSale.amount - amount;

        (
            uint256 dissrupCut,
            uint256 sellerCut,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        ) = _splitPayment(directSale.seller, totalPrice, saleId);

        emit BuyDirectSale(
            nftAddress,
            tokenId,
            saleId,
            amount,
            buyer,
            dissrupCut,
            directSale.seller,
            sellerCut,
            royaltiesPayees,
            royaltiesCuts
        );

        if (directSale.amount == 0) {
            delete assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {Constants} from "./Constants.sol";

import {Core} from "./Core.sol";

import {Payment} from "./Payment.sol";

error Auction_Sale_Contract_Address_Is_Not_Approved(address nftAddress);

error Auction_Sale_Amount_Cannot_Be_Zero();

error Auction_Sale_Price_Too_Low();

error Cannot_Update_Ongoing_Auction();

error Auction_Sale_Only_Seller_Can_Update();

error Cannot_Cancel_Ongoing_Auction();

error Auction_Sale_Only_Seller_Can_Cancel();

error Auction_Sale_Not_A_Valid_List();

error Auction_Sale_Already_Ended();

error Auction_Sale_Msg_Value_Lower_Then_Reserve_Price();

error Auction_Sale_Bid_Must_Be_Greater_Then(uint256 minimumBid);

error Auction_Sale_Seller_Cannot_Bid();

error Auction_Sale_Cannot_Settle_Onging_Auction();

abstract contract AuctionSale is
    Constants,
    Core,
    Payment,
    ReentrancyGuardUpgradeable
{
    struct AuctionSaleList {
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address bidder;
        uint256 bid;
        uint256 reservePrice;
        uint256 amount;
        address seller;
    }

    uint256 internal _auctionSaleId;

    mapping(address => mapping(uint256 => mapping(uint256 => AuctionSaleList)))
        private _assetAndSaleIdToAuctionSale;

    event ListAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        uint256 duration,
        uint256 reservePrice,
        uint256 extensionDuration,
        address seller,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );
    event CancelAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        address seller
    );
    event UpdateAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 duration,
        uint256 reservePrice,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );
    event Bid(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address lastBidder,
        uint256 lastBid,
        address newBidder,
        uint256 newBid,
        uint256 endtime
    );

    event Settle(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address winner,
        uint256 winnerBid,
        uint256 dissrupCut,
        address seller,
        uint256 sellerCut,
        address[] royaltiesPayees,
        uint256[] royaltiesCuts,
        address settler
    );

    function listAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 duration,
        uint256 reservePrice,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) external nonReentrant {
        if (_saleContractAllowlist[nftAddress] == false) {
            revert Auction_Sale_Contract_Address_Is_Not_Approved(nftAddress);
        }
        if (reservePrice < MIN_PRICE) {
            revert Auction_Sale_Price_Too_Low();
        }
        if (amount == 0) {
            revert Auction_Sale_Amount_Cannot_Be_Zero();
        }

        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);
        }

        _trasferNFT(msg.sender, address(this), nftAddress, tokenId, amount);

        AuctionSaleList storage auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][++_auctionSaleId];

        _setRoyalties(_auctionSaleId, royaltiesPayees, royaltiesShares);

        auctionSale.amount = amount;
        auctionSale.bidder = address(0);
        auctionSale.bid = 0;
        auctionSale.endTime = 0;
        auctionSale.extensionDuration = EXTENSION_DURATION;
        auctionSale.duration = duration;
        auctionSale.reservePrice = reservePrice;
        auctionSale.seller = msg.sender;

        emit ListAuctionSale(
            nftAddress,
            tokenId,
            _auctionSaleId,
            auctionSale.amount,
            auctionSale.duration,
            auctionSale.reservePrice,
            auctionSale.extensionDuration,
            auctionSale.seller,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function updateAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 duration,
        uint256 reservePrice,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) external nonReentrant {
        if (reservePrice < MIN_PRICE) {
            revert Auction_Sale_Price_Too_Low();
        }
        AuctionSaleList storage auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];

        if (auctionSale.seller != msg.sender) {
            revert Auction_Sale_Only_Seller_Can_Update();
        }

        if (auctionSale.endTime != 0) {
            revert Cannot_Update_Ongoing_Auction();
        }
        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);

            _setRoyalties(saleId, royaltiesPayees, royaltiesShares);
        }

        auctionSale.reservePrice = reservePrice;

        auctionSale.duration = duration;

        emit UpdateAuctionSale(
            nftAddress,
            tokenId,
            saleId,
            auctionSale.duration,
            reservePrice,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function cancelAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external nonReentrant {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        if (auctionSale.seller != msg.sender) {
            revert Auction_Sale_Only_Seller_Can_Cancel();
        }
        if (auctionSale.endTime != 0) {
            revert Cannot_Cancel_Ongoing_Auction();
        }
        _trasferNFT(
            address(this),
            auctionSale.seller,
            nftAddress,
            tokenId,
            auctionSale.amount
        );

        delete _assetAndSaleIdToAuctionSale[nftAddress][tokenId][saleId];

        emit CancelAuctionSale(
            nftAddress,
            tokenId,
            saleId,
            auctionSale.amount,
            auctionSale.seller
        );
    }

    function bid(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external payable nonReentrant {
        AuctionSaleList storage auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        address lastBidder;
        uint256 lastBid;
        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        if (msg.sender == auctionSale.seller) {
            revert Auction_Sale_Seller_Cannot_Bid();
        }
        if (auctionSale.bidder == address(0)) {
            //first bid!
            if (msg.value < auctionSale.reservePrice) {
                revert Auction_Sale_Msg_Value_Lower_Then_Reserve_Price();
            }

            auctionSale.bidder = msg.sender;
            auctionSale.bid = msg.value;

            auctionSale.endTime =
                uint256(block.timestamp) +
                auctionSale.duration;
        } else {
            if (auctionSale.endTime < block.timestamp) {
                revert Auction_Sale_Already_Ended();
            }

            // not the fisrt bid
            uint256 minimumRasieForBid = _getMinBidForReserveAuction(
                auctionSale.bid
            );

            if (minimumRasieForBid > msg.value) {
                revert Auction_Sale_Bid_Must_Be_Greater_Then(
                    minimumRasieForBid
                );
            }
            if (
                auctionSale.endTime - block.timestamp <
                auctionSale.extensionDuration
            ) {
                auctionSale.endTime += auctionSale.extensionDuration;
            }

            lastBidder = auctionSale.bidder;
            lastBid = auctionSale.bid;
            // return ether to last bidder
            payable(lastBidder).transfer(lastBid);

            //
            auctionSale.bidder = msg.sender;
            auctionSale.bid = msg.value;
        }

        emit Bid(
            nftAddress,
            tokenId,
            saleId,
            lastBidder,
            lastBid,
            auctionSale.bidder,
            auctionSale.bid,
            auctionSale.endTime
        );
    }

    function settle(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external nonReentrant {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        address seller = auctionSale.seller;
        if (seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        if (auctionSale.endTime > block.timestamp) {
            revert Auction_Sale_Cannot_Settle_Onging_Auction();
        }
        address winner = auctionSale.bidder;
        uint256 winnerBid = auctionSale.bid;

        _trasferNFT(
            address(this),
            winner,
            nftAddress,
            tokenId,
            auctionSale.amount
        );

        (
            uint256 dissrupCut,
            uint256 sellerCut,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        ) = _splitPayment(seller, winnerBid, saleId);

        delete _assetAndSaleIdToAuctionSale[nftAddress][tokenId][saleId];

        emit Settle(
            nftAddress,
            tokenId,
            saleId,
            winner,
            winnerBid,
            dissrupCut,
            seller,
            sellerCut,
            royaltiesPayees,
            royaltiesCuts,
            msg.sender
        );
    }

    function isAuctionEnded(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) public view returns (bool) {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];

        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        return
            (auctionSale.endTime > 0) &&
            (auctionSale.endTime < block.timestamp);
    }

    function getEndTimeForReserveAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) public view returns (uint256) {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        return auctionSale.endTime;
    }

    function _getMinBidForReserveAuction(uint256 currentBid)
        internal
        pure
        returns (uint256)
    {
        uint256 minimumIncrement = currentBid / 10;

        if (minimumIncrement < (0.1 ether)) {
            // The next bid must be at least 0.1 ether greater than the current.
            return currentBid + (0.1 ether);
        }
        return (currentBid + minimumIncrement);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IERC1155ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";

error Not_Valid_Contract();

error Core_Amount_Is_Not_Valid_For_ERC721();

abstract contract Core {
    using ERC165CheckerUpgradeable for address;

    mapping(address => bool) internal _saleContractAllowlist;

    function _trasferNFT(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (_isERC721(nftAddress)) {
            if (amount > 1) {
                revert Core_Amount_Is_Not_Valid_For_ERC721();
            }
            _transferERC721(from, to, nftAddress, tokenId);
        } else if (_isERC1155(nftAddress)) {
            _transferERC1155(from, to, nftAddress, tokenId, amount);
        } else {
            revert Not_Valid_Contract();
        }
    }

    function _addContractAllowlist(address contractAddress) internal {
        _saleContractAllowlist[contractAddress] = true;
    }

    function _transferERC1155(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) private {
        IERC1155Upgradeable(nftAddress).safeTransferFrom(
            from,
            to,
            tokenId,
            amount,
            ""
        );
    }

    function _transferERC721(
        address from,
        address to,
        address nftAddress,
        uint256 tokenId
    ) private {
        IERC721Upgradeable(nftAddress).safeTransferFrom(from, to, tokenId);
    }

    function _isERC1155(address nftAddress) private view returns (bool) {
        return
            nftAddress.supportsInterface(type(IERC1155Upgradeable).interfaceId);
    }

    function _isERC721(address nftAddress) private view returns (bool) {
        return
            nftAddress.supportsInterface(type(IERC721Upgradeable).interfaceId);
    }

    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC721Received.selector;
        }
        return 0x0;
    }

    function onERC1155Received(
        address _operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC1155Received.selector;
        }
        return 0x0;
    }

    function onERC1155BatchReceived(
        address _operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external view returns (bytes4) {
        if (_operator == address(this)) {
            return this.onERC1155BatchReceived.selector;
        }

        return 0x0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
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

pragma solidity ^0.8.7;

abstract contract Constants {
    /**
     * @notice minmum price for sale asset.
     */
    uint256 internal constant MIN_PRICE = 100;
    /**
     * @notice the shares in manifold come in diffrant basis so need to be divided by offset (from 5000 to 50%)
     */
    uint256 internal constant MANIFOLD_ROYALTIES_BASIS_POINT = 100;

    uint256 internal constant EXTENSION_DURATION = 15 minutes;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import {Constants} from "./Constants.sol";

error Payment_Royalties_Make_More_Then_85_Precent();

error Payment_Royalties_Payees_Not_Equal_Shares_Lenght();

abstract contract Payment is Constants {
    address internal _dissrupPayout;

    struct Royalty {
        address payee;
        uint256 share;
    }

    using ERC165CheckerUpgradeable for address;
    event PayToRoyalties(address payable[] payees, uint256[] shares);

    mapping(uint256 => Royalty[]) internal _saleToRoyalties;

    function _setDissrupPayment(address dissrupPayout) internal virtual {
        _dissrupPayout = dissrupPayout;
    }

    function _splitPayment(
        address seller,
        uint256 price,
        uint256 saleId
    )
        internal
        returns (
            uint256 dissrupCut,
            uint256 sellerCut,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        )
    {
        // 15% of price
        dissrupCut = SafeMathUpgradeable.mul(
            SafeMathUpgradeable.div(price, 100),
            15
        );

        payable(_dissrupPayout).transfer(dissrupCut);
        uint256 royaltiesTotalCut;
        (
            royaltiesTotalCut,
            royaltiesPayees,
            royaltiesCuts
        ) = _payToRoyaltiesIfExist(saleId, price);

        sellerCut = (price) - (dissrupCut + royaltiesTotalCut);

        payable(seller).transfer(sellerCut);
    }

    function _checkRoyalties(
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) internal pure {
        uint256 totalShares;
        if (royaltiesPayees.length != royaltiesShares.length) {
            revert Payment_Royalties_Payees_Not_Equal_Shares_Lenght();
        }

        for (uint256 i = 0; i < royaltiesPayees.length; i++) {
            totalShares = totalShares + royaltiesShares[i];
        }
        // dissrup cut is 15%
        if (totalShares > 85) {
            revert Payment_Royalties_Make_More_Then_85_Precent();
        }
    }

    function _setRoyalties(
        uint256 saleId,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    ) internal {
        for (uint256 i = 0; i < royaltiesPayees.length; i++) {
            Royalty memory royalty = Royalty({
                payee: royaltiesPayees[i],
                share: royaltiesShares[i]
            });

            _saleToRoyalties[saleId].push(royalty);
        }
    }

    function _payToRoyaltiesIfExist(uint256 saleId, uint256 price)
        private
        returns (
            uint256 royaltiesTotalCuts,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        )
    {
        Royalty[] storage royalties = _saleToRoyalties[saleId];
        royaltiesCuts = new uint256[](royalties.length);
        royaltiesPayees = new address[](royalties.length);

        for (uint256 i = 0; i < royalties.length; i++) {
            Royalty memory royalty = royalties[i];

            uint256 cut = SafeMathUpgradeable.mul(
                SafeMathUpgradeable.div(price, 100),
                royalty.share
            );
            royaltiesCuts[i] = cut;
            royaltiesPayees[i] = royalty.payee;
            royaltiesTotalCuts += cut;
            payable(royalty.payee).transfer(cut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}