// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "contracts/Interfaces/ICollection721A.sol";
import "contracts/Interfaces/ICollection1155.sol";
import "contracts/Interfaces/IRoyaltySplitter.sol";

/**
 * @notice The contract to create and govern collections.
 *
 * @dev Each collection has two access control groups: _Minters_ and _Admins_.
 * Their members lists are managed by *Factory admins*. The contract creator
 * gets the _Chief admin role_ allowing exclusively grant *Factory admin* role to an address.
 */
contract Factory is AccessControl {
    address public defaultPaymentSplitter;

    /**
     * @dev The variable should store Collection-1155 byte code. It is set when implementation change is needed.
     */
    bytes public collection1155ByteCode;

    /**
     * @dev The variable should store Collection-721A byte code. It is set when implementation change is needed.
     */
    bytes public collection721AByteCode;

    bytes private PaymentSplitterBytecode;

    /**
     * @dev Hash of the *Factory admin* role.
     */
    bytes32 public constant FACTORY_ADMIN = keccak256(abi.encodePacked("Factory Admin"));

    /**
     * @notice Is emitted when collection-1155 is created.
     * @param createdCollection Address of the created 1155 collection
     */
    event Collection1155Created(address indexed createdCollection);

    /**
     * @notice Is emitted when collection-1155 is created.
     * @param createdCollection Address of the created 721A collection
     */
    event Collection721ACreated(address indexed createdCollection);

    /**
     * @notice Structure for configuration of the PaymentSplitter proxy contract.
     * @param payees Addresses that will receive royalties
     * @param shares Proportions for payments distribution
     */
    struct PaymentSplitterConfig {
        address[] payees;
        uint256[] shares;
    }

    modifier onlyCollectionMinter(address collection) {
        bytes32 minterRole = keccak256(abi.encodePacked("Minter", collection));
        _checkRole(minterRole);
        _;
    }

    modifier onlyCollectionAdmin(address collection) {
        bytes32 adminRole = keccak256(abi.encodePacked("Admin", collection));
        _checkRole(adminRole);
        _;
    }

    constructor() {
        _setupRole(FACTORY_ADMIN, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Method to create 1155 collection.
     * @dev Can be called only by Factory admin
     * @param name Token name
     * @param symbol Token symbol
     * @param isBurnable Flag to determine whether collection tokens are burnable or not
     * @param paymentSplitter Address for proxy implementation
     * @param paymentSplitterConfig Structure for configuration of the PaymentSplitter proxy contract
     */
    function create721ACollection(
        string calldata name,
        string calldata symbol,
        bool isBurnable,
        address paymentSplitter,
        PaymentSplitterConfig calldata paymentSplitterConfig
    ) external onlyRole(FACTORY_ADMIN) {
        _createCollection(
            false,
            "",
            name,
            symbol,
            isBurnable,
            paymentSplitter,
            paymentSplitterConfig
        );
    }

    /**
     * @notice Method to create 1155 collection.
     * @dev Can be called only by Factory admin
     * @param uri Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
     * @param paymentSplitter Address for proxy implementation
     * @param paymentSplitterConfig Structure for configuration of the PaymentSplitter proxy contract
     */
    function create1155Collection(
        string memory uri,
        bool isBurnable,
        address paymentSplitter,
        PaymentSplitterConfig calldata paymentSplitterConfig
    ) external onlyRole(FACTORY_ADMIN) {
        _createCollection(true, uri, "", "", isBurnable, paymentSplitter, paymentSplitterConfig);
    }

    function _createCollection(
        bool isERC1155,
        string memory uri,
        string memory name,
        string memory symbol,
        bool isBurnable,
        address paymentSplitter,
        PaymentSplitterConfig memory paymentSplitterConfig
    ) internal {
        bytes32 salt = keccak256(abi.encodePacked(uri, name, symbol));
        address createdCollection = _deployCollection(isERC1155, salt);
        if (isERC1155) {
            ICollection1155(createdCollection).initialize(uri, isBurnable);
        } else {
            ICollection721A(createdCollection).initialize(name, symbol, isBurnable);
        }
        address paymentSplitterClone = Clones.clone(paymentSplitter);
        IRoyaltySplitter(paymentSplitterClone).initialize(
            paymentSplitterConfig.payees,
            paymentSplitterConfig.shares
        );
        ICollection(createdCollection).setPaymentSplitter(paymentSplitterClone);

        bytes32 collectionAdminRole = keccak256(abi.encodePacked("Admin", createdCollection));
        _setupRole(collectionAdminRole, msg.sender);
        _setRoleAdmin(collectionAdminRole, FACTORY_ADMIN);

        bytes32 collectionMinterRole = keccak256(abi.encodePacked("Minter", createdCollection));
        _setupRole(collectionMinterRole, msg.sender);
        _setRoleAdmin(collectionMinterRole, FACTORY_ADMIN);
    }

    function _deployCollection(bool isERC1155, bytes32 salt) private returns (address collection) {
        bytes memory bytecode = isERC1155 ? collection1155ByteCode : collection721AByteCode;
        collection = Create2.deploy(0, salt, bytecode);

        if (isERC1155) {
            emit Collection1155Created(collection);
        } else {
            emit Collection721ACreated(collection);
        }
    }

    /**
     * @notice Method to mint 1155 collection tokens.
     * @dev Can be called only by Collection minter.
     * @param collection Address of the 1155 collection
     * @param to Token recipient address
     * @param id Token type to mint
     * @param amount Amount of created token
     */
    function mint1155(
        ICollection1155 collection,
        address to,
        uint256 id,
        uint256 amount
    ) external onlyCollectionMinter(address(collection)) {
        collection.mint(to, id, amount);
    }

    /**
     * @notice Method to mint 1155 collection tokens.
     * @dev `ids` and `amounts` must have the same length. Can be called only by Collection minter.
     * @param collection Address of the 1155 collection
     * @param to Tokens recipient address
     * @param ids Array of Token types to mint
     * @param amounts Array of created tokens Amounts
     */
    function mint1155Batch(
        ICollection1155 collection,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyCollectionMinter(address(collection)) {
        collection.mintBatch(to, ids, amounts);
    }

    /**
     * @notice Method to mint 721A collection tokens.
     * @param collection Address of the 721A collection
     * @param to Tokens recipient address
     * @param quantity Amount of created tokens
     */
    function mint721A(
        ICollection721A collection,
        address to,
        uint256 quantity
    ) external onlyCollectionMinter(address(collection)) {
        collection.mint(to, quantity);
    }

    /**
     * @notice Method to change collection's royalty receiver address.
     * @dev Can be called only by collection admin
     * @param collection Address of the collection
     * @param newRoyaltyReciever Tokens recipient address
     */
    function setRoyaltyReciever(ICollection collection, address newRoyaltyReciever)
        external
        onlyCollectionAdmin(address(collection))
    {
        collection.setPaymentSplitter(newRoyaltyReciever);
    }

    /**
     * @notice Method to set collection's royalty fee.
     * @dev Ultimate fee is calculated as `numerator` / 10000. Can be called only by Collection admin
     * @param collection Address of the collection
     * @param numerator Number between 0 and 10000
     */
    function setRoyaltyFee(ICollection collection, uint256 numerator)
        external
        onlyCollectionAdmin(address(collection))
    {
        collection.setRoyaltyFee(numerator);
    }

    /**
     * @notice Method to transfer collections ownership.
     * @dev Can be called only by collection admin.
     * @param collection Address of the collection
     * @param newOwner Address to transfer ownership
     */
    function transferCollectionOwnership(ICollection collection, address newOwner)
        external
        onlyCollectionAdmin(address(collection))
    {
        collection.transferOwnership(newOwner);
    }

    /**
     * @notice Method to change 1155 collection implementation code.
     * @dev Can be called only by factory admin.
     * @param newCollection1155Bytecode New implementation bytecode
     */
    function setCollection1155Bytecode(bytes memory newCollection1155Bytecode)
        external
        onlyRole(FACTORY_ADMIN)
    {
        collection1155ByteCode = newCollection1155Bytecode;
    }

    /**
     * @notice Method to change 721A collection implementation code.
     * @dev Can be called only by factory admin.
     * @param newCollection721ABytecode New implementation bytecode
     */
    function setCollection721ABytecode(bytes memory newCollection721ABytecode)
        external
        onlyRole(FACTORY_ADMIN)
    {
        collection721AByteCode = newCollection721ABytecode;
    }

    /**
     * @notice Method to change collection's opensea config uri.
     * @dev Can be called only by factory admin
     * @param collection Address of the collection
     * @param newMetaDataUri New uri
     */
    function setCollectionMetaDataUri(ICollection collection, string calldata newMetaDataUri)
        external
        onlyCollectionAdmin(address(collection))
    {
        collection.setMetaDataUri(newMetaDataUri);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "./ICollection.sol";

interface ICollection721A is ICollection {
    function initialize(
        string calldata name,
        string calldata symbol,
        bool isBurnable
    ) external;

    function mint(address to, uint256 quantity) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "./ICollection.sol";

interface ICollection1155 is ICollection {
    function initialize(string memory uri, bool isBurnable) external;

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

interface IRoyaltySplitter {
    function initialize(address[] memory payees, uint256[] memory shares) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

interface ICollection {
    function setPaymentSplitter(address newPaymentSplitter) external;

    function setRoyaltyFee(uint256 numerator) external;

    function transferOwnership(address newOwner) external;

    function contractURI() external view returns (string memory);

    function setURI(string calldata newuri) external;

    function setMetaDataUri(string calldata newMetaDataUrl) external;
}