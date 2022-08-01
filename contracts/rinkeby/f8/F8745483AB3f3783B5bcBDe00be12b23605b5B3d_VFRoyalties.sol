// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVFRoyalties.sol";
import "./VFAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract VFRoyalties is IVFRoyalties, Context, ERC165 {
    //Struct for maintaining royalty information
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    //Default royalty informations
    RoyaltyInfo private _defaultRoyaltyInfo;

    //Contract address to royalty information map
    mapping(address => RoyaltyInfo) private _contractRoyalInfo;

    //Contract for function access control
    VFAccessControl private _controlContract;

    /**
     * @dev Initializes the contract by setting a `controlContractAddress`, `defaultReceiver`,
     * and `defaultFeeNumerator` for the royalties contract.
     */
    constructor(
        address controlContractAddress,
        address defaultReceiver,
        uint96 defaultFeeNumerator
    ) {
        _controlContract = VFAccessControl(controlContractAddress);
        setDefaultRoyalty(defaultReceiver, defaultFeeNumerator);
    }

    modifier onlyRole(bytes32 role) {
        _controlContract.checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IVFRoyalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IVFRoyalties-setControlContract}.
     */
    function setControlContract(address controlContractAddress)
        external
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            IERC165(controlContractAddress).supportsInterface(
                type(IVFAccessControl).interfaceId
            ),
            "Contract does not support required interface"
        );
        _controlContract = VFAccessControl(controlContractAddress);
    }

    /**
     * @dev See {IVFRoyalties-royaltyInfo}.
     */
    function royaltyInfo(
        uint256,
        address contractAddress,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory contractRoyaltyInfo = _contractRoyalInfo[
            contractAddress
        ];

        if (contractRoyaltyInfo.receiver == address(0)) {
            contractRoyaltyInfo = _defaultRoyaltyInfo;
        }

        royaltyAmount =
            (salePrice * contractRoyaltyInfo.royaltyFraction) /
            _feeDenominator();

        return (contractRoyaltyInfo.receiver, royaltyAmount);
    }

    /**
     * @dev See {IVFRoyalties-setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        virtual
        onlyRole(_controlContract.getAdminRole())
    {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev See {IVFRoyalties-deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty()
        external
        virtual
        onlyRole(_controlContract.getAdminRole())
    {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev See {IVFRoyalties-setContractRoyalties}.
     */
    function setContractRoyalties(
        address contractAddress,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(_controlContract.getAdminRole()) {
        require(
            feeNumerator <= _feeDenominator(),
            "ERC2981: royalty fee will exceed salePrice"
        );
        require(receiver != address(0), "ERC2981: invalid receiver");

        _contractRoyalInfo[contractAddress] = RoyaltyInfo(
            receiver,
            feeNumerator
        );
    }

    /**
     * @dev See {IVFRoyalties-resetContractRoyalty}.
     */
    function resetContractRoyalty(address contractAddress)
        external
        virtual
        onlyRole(_controlContract.getAdminRole())
    {
        delete _contractRoyalInfo[contractAddress];
    }

    /**
     * @dev Get the fee denominator
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVFRoyalties {
    /**
     * @dev Update the access control contract
     *
     * Requirements:
     *
     * - the caller must be an admin role
     * - `controlContractAddress` must support the IVFAccesControl interface
     */
    function setControlContract(address controlContractAddress) external;

    /**
     * @dev Get royalty information for a contract based on the `salePrice` of a token
     */
    function royaltyInfo(
        uint256,
        address contractAddress,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external;

    /**
     * @dev Sets the royalty information for `contractAddress`.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setContractRoyalties(
        address contractAddress,
        address receiver,
        uint96 feeNumerator
    ) external;

    /**
     * @dev Removes royalty information for `contractAddress`.
     */
    function resetContractRoyalty(address contractAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IVFAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VFAccessControl is IVFAccessControl, Context, ERC165, ReentrancyGuard {
    //Struct for maintaining role information
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    //Role information
    mapping(bytes32 => RoleData) private _roles;

    //Admin role
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    //Token contract role
    bytes32 public constant TOKEN_CONTRACT_ROLE =
        keccak256("TOKEN_CONTRACT_ROLE");
    //Sales contract role
    bytes32 public constant SALES_CONTRACT_ROLE =
        keccak256("SALES_CONTRACT_ROLE");
    //Burner role
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    //Minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    //Array of addresses that can mint
    address[] public minterAddresses;
    //Index of next minter in minterAddresses
    uint8 private _currentMinterIndex = 0;

    //Array of roles that can mint
    bytes32[] public minterRoles;

    /**
     * @dev Initializes the contract by assigning the msg sender the admin, minter,
     * and burner role. Along with adding the minter role and sales contract role
     * to the minter roles array.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());
        minterRoles.push(MINTER_ROLE);
        minterRoles.push(SALES_CONTRACT_ROLE);
    }

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
        checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IVFAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IVFAccessControl-hasRole}.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev See {IVFAccessControl-checkRole}.
     */
    function checkRole(bytes32 role, address account) public view virtual {
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
     * @dev See {IVFAccessControl-getAdminRole}.
     */
    function getAdminRole() external view virtual returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getTokenContractRole}.
     */
    function getTokenContractRole() external view virtual returns (bytes32) {
        return TOKEN_CONTRACT_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getSalesContractRole}.
     */
    function getSalesContractRole() external view virtual returns (bytes32) {
        return SALES_CONTRACT_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getBurnerRole}.
     */
    function getBurnerRole() external view virtual returns (bytes32) {
        return BURNER_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getMinterRole}.
     */
    function getMinterRole() external view virtual returns (bytes32) {
        return MINTER_ROLE;
    }

    /**
     * @dev See {IVFAccessControl-getMinterRoles}.
     */
    function getMinterRoles() external view virtual returns (bytes32[] memory) {
        return minterRoles;
    }

    /**
     * @dev See {IVFAccessControl-getRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev See {IVFAccessControl-grantRole}.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev See {IVFAccessControl-revokeRole}.
     */
    function revokeRole(bytes32 role, address account)
        external
        virtual
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev See {IVFAccessControl-renounceRole}.
     */
    function renounceRole(bytes32 role, address account) external virtual {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev See {IVFAccessControl-selectNextMinter}.
     */
    function selectNextMinter()
        external
        onlyRole(SALES_CONTRACT_ROLE)
        returns (address payable)
    {
        address nextMinter = minterAddresses[_currentMinterIndex];
        if (_currentMinterIndex + 1 < minterAddresses.length) {
            _currentMinterIndex++;
        } else {
            _currentMinterIndex = 0;
        }
        return payable(nextMinter);
    }

    /**
     * @dev See {IVFAccessControl-grantMinterRole}.
     */
    function grantMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, minter);
        minterAddresses.push(minter);
        _currentMinterIndex = 0;
    }

    /**
     * @dev See {IVFAccessControl-revokeMinterRole}.
     */
    function revokeMinterRole(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(MINTER_ROLE, minter);
        uint256 index;
        for (index = 0; index < minterAddresses.length; index++) {
            if (minter == minterAddresses[index]) {
                minterAddresses[index] = minterAddresses[
                    minterAddresses.length - 1
                ];
                break;
            }
        }
        minterAddresses.pop();
        _currentMinterIndex = 0;
    }

    /**
     * @dev See {IVFAccessControl-fundMinters}.
     */
    function fundMinters() external payable nonReentrant {
        uint256 totalMinters = minterAddresses.length;
        uint256 amount = msg.value / totalMinters;
        for (uint256 index = 0; index < totalMinters; index++) {
            payable(minterAddresses[index]).transfer(amount);
        }
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
     * @dev Widthraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function withdrawMoney() external onlyRole(DEFAULT_ADMIN_ROLE) {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
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

interface IVFAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function checkRole(bytes32 role, address account) external view;

    /**
     * @dev Returns bytes of default admin role
     */
    function getAdminRole() external view returns (bytes32);

    /**
     * @dev Returns bytes of token contract role
     */
    function getTokenContractRole() external view returns (bytes32);

    /**
     * @dev Returns bytes of sales contract role
     */
    function getSalesContractRole() external view returns (bytes32);

    /**
     * @dev Returns bytes of burner role
     */
    function getBurnerRole() external view returns (bytes32);

    /**
     * @dev Returns bytes of minter role
     */
    function getMinterRole() external view returns (bytes32);

    /**
     * @dev Returns a bytes array of roles that can be minters
     */
    function getMinterRoles() external view returns (bytes32[] memory);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;

    /**
     * @dev Selects the next minter from the minters array using the current minter index.
     * The current minter index should be incremented after each selection.  If the
     * current minter index + 1 is equal to the minters array length then the current
     * minter index should be set back to 0
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function selectNextMinter() external returns (address payable);

    /**
     * @dev Grants `minter` minter role and adds `minter` to minters array
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function grantMinterRole(address minter) external;

    /**
     * @dev Revokes minter role from `minter` and removes `minter` from minters array
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function revokeMinterRole(address minter) external;

    /**
     * @dev Distributes ETH evenly to all addresses in minters array
     */
    function fundMinters() external payable;
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