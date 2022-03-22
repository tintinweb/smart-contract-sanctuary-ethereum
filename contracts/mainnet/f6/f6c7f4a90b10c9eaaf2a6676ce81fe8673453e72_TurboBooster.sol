/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}
/// @notice Flexible and target agnostic role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/MultiRolesAuthority.sol)
contract MultiRolesAuthority is Auth, Authority {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, bytes4 indexed functionSig, bool enabled);

    event TargetCustomAuthorityUpdated(address indexed target, Authority indexed authority);

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                       CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => Authority) public getTargetCustomAuthority;

    /*///////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(bytes4 => bool) public isCapabilityPublic;

    mapping(bytes4 => bytes32) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(uint8 role, bytes4 functionSig) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[functionSig]) >> role) & 1 != 0;
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        Authority customAuthority = getTargetCustomAuthority[target];

        if (address(customAuthority) != address(0)) return customAuthority.canCall(user, target, functionSig);

        return
            isCapabilityPublic[functionSig] || bytes32(0) != getUserRoles[user] & getRolesWithCapability[functionSig];
    }

    /*///////////////////////////////////////////////////////////////
               CUSTOM TARGET AUTHORITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setTargetCustomAuthority(address target, Authority customAuthority) public virtual requiresAuth {
        getTargetCustomAuthority[target] = customAuthority;

        emit TargetCustomAuthorityUpdated(target, customAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                  PUBLIC CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(bytes4 functionSig, bool enabled) public virtual requiresAuth {
        isCapabilityPublic[functionSig] = enabled;

        emit PublicCapabilityUpdated(functionSig, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                      USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                  ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setRoleCapability(
        uint8 role,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, functionSig, enabled);
    }
}

/// @title CERC20
/// @author Compound Labs and Rari Capital
/// @notice Minimal Compound/Fuse Comptroller interface.
abstract contract CERC20 is ERC20 {
    /// @notice Deposit an amount of underlying tokens to the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to deposit.
    /// @return An error code or zero if there was no error in the deposit.
    function mint(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Borrow an amount of underlying tokens from the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to borrow.
    /// @return An error code or zero if there was no error in the borrow.
    function borrow(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Repay an amount of underlying tokens to the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to repay.
    /// @return An error code or zero if there was no error in the repay.
    function repayBorrow(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Returns the underlying balance of a specific user.
    /// @param user The user who's balance the CERC20 will retrieve.
    /// @return The amount of underlying tokens the user is entitled to.
    function balanceOfUnderlying(address user) external view virtual returns (uint256);

    /// @notice Returns the amount of underlying tokens a cToken redeemable for.
    /// @return The amount of underlying tokens a cToken is redeemable for.
    function exchangeRateStored() external view virtual returns (uint256);

    /// @notice Withdraw a specific amount of underlying tokens from the CERC20.
    /// @param underlyingAmount Amount of underlying tokens to withdraw.
    /// @return An error code or zero if there was no error in the withdraw.
    function redeemUnderlying(uint256 underlyingAmount) external virtual returns (uint256);

    /// @notice Return teh current borrow balance of a user in the CERC20.
    /// @param user The user to get the borrow balance for.
    /// @return The current borrow balance of the user.
    function borrowBalanceCurrent(address user) external virtual returns (uint256);

    /// @notice Repay a user's borrow on their behalf.
    /// @param user The user who's borrow to repay.
    /// @param underlyingAmount The amount of debt to repay.
    /// @return An error code or zero if there was no error in the repayBorrowBehalf.
    function repayBorrowBehalf(address user, uint256 underlyingAmount) external virtual returns (uint256);
}
/// @notice Price Feed
/// @author Compound Labs
/// @notice Minimal cToken price feed interface.
interface PriceFeed {
    /// @notice Get the underlying price of the cToken's asset.
    /// @param cToken The cToken to get the underlying price of.
    /// @return The underlying asset price scaled by 1e18.
    function getUnderlyingPrice(CERC20 cToken) external view returns (uint256);

    function add(address[] calldata underlyings, address[] calldata _oracles) external;

    function changeAdmin(address newAdmin) external;
}

/// @title Comptroller
/// @author Compound Labs and Rari Capital
/// @notice Minimal Compound/Fuse Comptroller interface.
interface Comptroller {
    /// @notice Retrieves the admin of the Comptroller.
    /// @return The current administrator of the Comptroller.
    function admin() external view returns (address);

    /// @notice Retrieves the price feed of the Comptroller.
    /// @return The current price feed of the Comptroller.
    function oracle() external view returns (PriceFeed);

    /// @notice Maps underlying tokens to their equivalent cTokens in a pool.
    /// @param token The underlying token to find the equivalent cToken for.
    /// @return The equivalent cToken for the given underlying token.
    function cTokensByUnderlying(ERC20 token) external view returns (CERC20);

    /// @notice Get's data about a cToken.
    /// @param cToken The cToken to get data about.
    /// @return isListed Whether the cToken is listed in the Comptroller.
    /// @return collateralFactor The collateral factor of the cToken.

    function markets(CERC20 cToken) external view returns (bool isListed, uint256 collateralFactor);

    /// @notice Enters into a list of cToken markets, enabling them as collateral.
    /// @param cTokens The list of cTokens to enter into, enabling them as collateral.
    /// @return A list of error codes, or 0 if there were no failures in entering the cTokens.
    function enterMarkets(CERC20[] calldata cTokens) external returns (uint256[] memory);

    function _setPendingAdmin(address newPendingAdmin)
        external
        returns (uint256);

    function _setBorrowCapGuardian(address newBorrowCapGuardian) external;

    function _setMarketSupplyCaps(
        CERC20[] calldata cTokens,
        uint256[] calldata newSupplyCaps
    ) external;

    function _setMarketBorrowCaps(
        CERC20[] calldata cTokens,
        uint256[] calldata newBorrowCaps
    ) external;

    function _setPauseGuardian(address newPauseGuardian)
        external
        returns (uint256);

    function _setMintPaused(CERC20 cToken, bool state)
        external
        returns (bool);

    function _setBorrowPaused(CERC20 cToken, bool borrowPaused)
        external
        returns (bool);

    function _setTransferPaused(bool state) external returns (bool);

    function _setSeizePaused(bool state) external returns (bool);

    function _setPriceOracle(address newOracle)
        external
        returns (uint256);

    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        returns (uint256);

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        returns (uint256);

    function _setCollateralFactor(
        CERC20 cToken,
        uint256 newCollateralFactorMantissa
    ) external returns (uint256);

    function _acceptAdmin() external virtual returns (uint256);

    function _deployMarket(
        bool isCEther,
        bytes calldata constructionData,
        uint256 collateralFactorMantissa
    ) external returns (uint256);

    function borrowGuardianPaused(address cToken)
        external
        view
        returns (bool);

    function comptrollerImplementation()
        external
        view
        returns (address);

    function rewardsDistributors(uint256 index)
        external
        view
        returns (address);

    function _addRewardsDistributor(address distributor)
        external
        returns (uint256);

    function _setWhitelistEnforcement(bool enforce)
        external
        returns (uint256);

    function _setWhitelistStatuses(
        address[] calldata suppliers,
        bool[] calldata statuses
    ) external returns (uint256);

    function _unsupportMarket(CERC20 cToken) external returns (uint256);

    function _toggleAutoImplementations(bool enabled)
        external
        returns (uint256);
}

// OpenZeppelin Contracts v4.4.1 (governance/TimelockController.sol)



// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)



// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)



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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)



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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)



// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`, and a list of
     * initial proposers and executors. The proposers receive both the
     * proposer and the canceller role (for backward compatibility). The
     * executors receive the executor role.
     *
     * NOTE: At construction, both the deployer and the timelock itself are
     * administrators. This helps further configuration of the timelock by the
     * deployer. After configuration is done, it is recommended that the
     * deployer renounces its admin position and relies on timelocked
     * operations to perform future maintenance.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}
/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (not just any non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the addition in the
                // order of operations or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}
/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*///////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
/// @dev Do not use in production! ERC-4626 is still in the last call stage and is subject to change.
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*///////////////////////////////////////////////////////////////
                           ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*///////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}


/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}






/// @title Fuse Admin
/// @author Fei Protocol
/// @notice Minimal Fuse Admin interface.
interface FuseAdmin {
    /// @notice Whitelists or blacklists a user from accessing the cTokens in the pool.
    /// @param users The users to whitelist or blacklist.
    /// @param enabled Whether to whitelist or blacklist each user.
    function _setWhitelistStatuses(address[] calldata users, bool[] calldata enabled) external;

    function _deployMarket(
        address underlying,
        address irm,
        string calldata name,
        string calldata symbol,
        address impl,
        bytes calldata data,
        uint256 reserveFactor,
        uint256 adminFee,
        uint256 collateralFactorMantissa
    ) external;
}


interface IReverseRegistrar {
    /**
     @notice sets reverse ENS Record
     @param name the ENS record to set
     After calling this, a user has a fully configured reverse record claiming the provided name as that account's canonical name.
     */
    function setName(string memory name) external returns (bytes32);
}

/**
 @title helper contract to set reverse ens record with solmate Auth
 @author joeysantoro
 @notice sets reverse ENS record against canonical ReverseRegistrar https://docs.ens.domains/contract-api-reference/reverseregistrar.
*/
abstract contract ENSReverseRecordAuth is Auth {

    /// @notice the ENS Reverse Registrar
    IReverseRegistrar public constant REVERSE_REGISTRAR = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

    function setENSName(string memory name) external requiresAuth {
        REVERSE_REGISTRAR.setName(name);
    }
}

/// @title Turbo Clerk
/// @author Transmissions11
/// @notice Fee determination module for Turbo Safes.
contract TurboClerk is Auth, ENSReverseRecordAuth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Clerk contract.
    /// @param _owner The owner of the Clerk.
    /// @param _authority The Authority of the Clerk.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                        DEFAULT FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default fee on Safe interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    uint256 public defaultFeePercentage;

    /// @notice Emitted when the default fee percentage is updated.
    /// @param newDefaultFeePercentage The new default fee percentage.
    event DefaultFeePercentageUpdated(address indexed user, uint256 newDefaultFeePercentage);

    /// @notice Sets the default fee percentage.
    /// @param newDefaultFeePercentage The new default fee percentage.
    function setDefaultFeePercentage(uint256 newDefaultFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newDefaultFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the default fee percentage.
        defaultFeePercentage = newDefaultFeePercentage;

        emit DefaultFeePercentageUpdated(msg.sender, newDefaultFeePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                        CUSTOM FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps collaterals to their custom fees on interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    mapping(ERC20 => uint256) public getCustomFeePercentageForCollateral;

    /// @notice Maps Safes to their custom fees on interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    mapping(TurboSafe => uint256) public getCustomFeePercentageForSafe;

    /// @notice Emitted when a collateral's custom fee percentage is updated.
    /// @param collateral The collateral who's custom fee percentage was updated.
    /// @param newFeePercentage The new custom fee percentage.
    event CustomFeePercentageUpdatedForCollateral(
        address indexed user,
        ERC20 indexed collateral,
        uint256 newFeePercentage
    );

    /// @notice Sets a collateral's custom fee percentage.
    /// @param collateral The collateral to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the collateral.
    function setCustomFeePercentageForCollateral(ERC20 collateral, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForCollateral[collateral] = newFeePercentage;

        emit CustomFeePercentageUpdatedForCollateral(msg.sender, collateral, newFeePercentage);
    }

    /// @notice Emitted when a Safe's custom fee percentage is updated.
    /// @param safe The Safe who's custom fee percentage was updated.
    /// @param newFeePercentage The new custom fee percentage.
    event CustomFeePercentageUpdatedForSafe(address indexed user, TurboSafe indexed safe, uint256 newFeePercentage);

    /// @notice Sets a Safe's custom fee percentage.
    /// @param safe The Safe to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the Safe.
    function setCustomFeePercentageForSafe(TurboSafe safe, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForSafe[safe] = newFeePercentage;

        emit CustomFeePercentageUpdatedForSafe(msg.sender, safe, newFeePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the fee on interest taken by the protocol for a Safe.
    /// @param safe The Safe to get the fee percentage for.
    /// @param collateral The collateral/asset of the Safe.
    /// @return The fee percentage for the Safe.
    function getFeePercentageForSafe(TurboSafe safe, ERC20 collateral) external view returns (uint256) {
        // Get the custom fee percentage for the Safe.
        uint256 customFeePercentageForSafe = getCustomFeePercentageForSafe[safe];

        // If a custom fee percentage is set for the Safe, return it.
        if (customFeePercentageForSafe != 0) return customFeePercentageForSafe;

        // Get the custom fee percentage for the collateral type.
        uint256 customFeePercentageForCollateral = getCustomFeePercentageForCollateral[collateral];

        // If a custom fee percentage is set for the collateral, return it.
        if (customFeePercentageForCollateral != 0) return customFeePercentageForCollateral;

        // Otherwise, return the default fee percentage.
        return defaultFeePercentage;
    }
}






/// @title Turbo Master
/// @author Transmissions11
/// @notice Factory for creating and managing Turbo Safes.
/// @dev Must be authorized to call the Turbo Fuse Pool's FuseAdmin.
contract TurboMaster is Auth, ENSReverseRecordAuth {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Turbo Fuse Pool the Safes will interact with.
    Comptroller public immutable pool;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Master contract.
    /// @param _pool The Turbo Fuse Pool the Master will use.
    /// @param _fei The Fei token on the network.
    /// @param _owner The owner of the Master.
    /// @param _authority The Authority of the Master.
    constructor(
        Comptroller _pool,
        ERC20 _fei,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        pool = _pool;

        fei = _fei;

        // Prevent the first safe from getting id 0.
        safes.push(TurboSafe(address(0)));
    }

    /*///////////////////////////////////////////////////////////////
                            BOOSTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Booster module used by the Master and its Safes.
    TurboBooster public booster;

    /// @notice Emitted when the Booster is updated.
    /// @param user The user who triggered the update of the Booster.
    /// @param newBooster The new Booster contract used by the Master.
    event BoosterUpdated(address indexed user, TurboBooster newBooster);

    /// @notice Update the Booster used by the Master.
    /// @param newBooster The new Booster contract to be used by the Master.
    function setBooster(TurboBooster newBooster) external requiresAuth {
        booster = newBooster;

        emit BoosterUpdated(msg.sender, newBooster);
    }

    /*///////////////////////////////////////////////////////////////
                             CLERK STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Clerk module used by the Master and its Safes.
    TurboClerk public clerk;

    /// @notice Emitted when the Clerk is updated.
    /// @param user The user who triggered the update of the Clerk.
    /// @param newClerk The new Clerk contract used by the Master.
    event ClerkUpdated(address indexed user, TurboClerk newClerk);

    /// @notice Update the Clerk used by the Master.
    /// @param newClerk The new Clerk contract to be used by the Master.
    function setClerk(TurboClerk newClerk) external requiresAuth {
        clerk = newClerk;

        emit ClerkUpdated(msg.sender, newClerk);
    }

    /*///////////////////////////////////////////////////////////////
                  DEFAULT SAFE AUTHORITY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default authority to be used by created Safes.
    Authority public defaultSafeAuthority;

    /// @notice Emitted when the default safe authority is updated.
    /// @param user The user who triggered the update of the default safe authority.
    /// @param newDefaultSafeAuthority The new default authority to be used by created Safes.
    event DefaultSafeAuthorityUpdated(address indexed user, Authority newDefaultSafeAuthority);

    /// @notice Set the default authority to be used by created Safes.
    /// @param newDefaultSafeAuthority The new default safe authority.
    function setDefaultSafeAuthority(Authority newDefaultSafeAuthority) external requiresAuth {
        // Update the default safe authority.
        defaultSafeAuthority = newDefaultSafeAuthority;

        emit DefaultSafeAuthorityUpdated(msg.sender, newDefaultSafeAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                             SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The total Fei currently boosting Vaults.
    uint256 public totalBoosted;

    /// @notice Maps Safe addresses to the id they are stored under in the Safes array.
    mapping(TurboSafe => uint256) public getSafeId;

    /// @notice Maps Vault addresses to the total amount of Fei they've being boosted with.
    mapping(ERC4626 => uint256) public getTotalBoostedForVault;

    /// @notice Maps collateral types to the total amount of Fei boosted by Safes using it as collateral.
    mapping(ERC20 => uint256) public getTotalBoostedAgainstCollateral;

    /// @notice An array of all Safes created by the Master.
    /// @dev The first Safe is purposely invalid to prevent any Safes from having an id of 0.
    TurboSafe[] public safes;

    /// @notice Returns all Safes created by the Master.
    /// @return An array of all Safes created by the Master.
    /// @dev This is provided because Solidity converts public arrays into index getters,
    /// but we need a way to allow external contracts and users to access the whole array.
    function getAllSafes() external view returns (TurboSafe[] memory) {
        return safes;
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Safe is created.
    /// @param user The user who created the Safe.
    /// @param asset The asset of the Safe.
    /// @param safe The newly deployed Safe contract.
    /// @param id The index of the Safe in the safes array.
    event TurboSafeCreated(address indexed user, ERC20 indexed asset, TurboSafe safe, uint256 id);

    /// @notice Creates a new Turbo Safe which supports a specific asset.
    /// @param asset The ERC20 token that the Safe should accept.
    /// @return safe The newly deployed Turbo Safe which accepts the provided asset.
    function createSafe(ERC20 asset) external requiresAuth returns (TurboSafe safe, uint256 id) {
        // Create a new Safe using the default authority and provided asset.
        safe = new TurboSafe(msg.sender, defaultSafeAuthority, asset);

        // Add the safe to the list of Safes.
        safes.push(safe);

        unchecked {
            // Get the index/id of the new Safe.
            // Cannot underflow, we just pushed to it.
            id = safes.length - 1;
        }

        // Store the id/index of the new Safe.
        getSafeId[safe] = id;

        emit TurboSafeCreated(msg.sender, asset, safe, id);

        // Prepare a users array to whitelist the Safe.
        address[] memory users = new address[](1);
        users[0] = address(safe);

        // Prepare an enabled array to whitelist the Safe.
        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        // Whitelist the Safe to access the Turbo Fuse Pool.
        FuseAdmin(pool.admin())._setWhitelistStatuses(users, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CALLBACK LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Callback triggered whenever a Safe boosts a Vault.
    /// @param asset The asset of the Safe.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei used to boost the Vault.
    function onSafeBoost(
        ERC20 asset,
        ERC4626 vault,
        uint256 feiAmount
    ) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        // Update the total amount of Fei being using to boost Vaults.
        totalBoosted += feiAmount;

        // Cache the new total boosted for the Vault.
        uint256 newTotalBoostedForVault;

        // Cache the new total boosted against the Vault's collateral.
        uint256 newTotalBoostedAgainstCollateral;

        // Update the total amount of Fei being using to boost the Vault.
        getTotalBoostedForVault[vault] = (newTotalBoostedForVault = getTotalBoostedForVault[vault] + feiAmount);

        // Update the total amount of Fei boosted against the collateral type.
        getTotalBoostedAgainstCollateral[asset] = (newTotalBoostedAgainstCollateral =
            getTotalBoostedAgainstCollateral[asset] +
            feiAmount);

        // Check with the booster that the Safe is allowed to boost the Vault using this amount of Fei.
        require(
            booster.canSafeBoostVault(
                safe,
                asset,
                vault,
                feiAmount,
                newTotalBoostedForVault,
                newTotalBoostedAgainstCollateral
            ),
            "BOOSTER_REJECTED"
        );
    }

    /// @notice Callback triggered whenever a Safe withdraws from a Vault.
    /// @param asset The asset of the Safe.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei withdrawn from the Vault.
    function onSafeLess(
        ERC20 asset,
        ERC4626 vault,
        uint256 feiAmount
    ) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        // Update the total amount of Fei being using to boost the Vault.
        getTotalBoostedForVault[vault] -= feiAmount;

        // Update the total amount of Fei being using to boost Vaults.
        totalBoosted -= feiAmount;

        // Update the total amount of Fei boosted against the collateral type.
        getTotalBoostedAgainstCollateral[asset] -= feiAmount;
    }

    /*///////////////////////////////////////////////////////////////
                              SWEEP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a token is sweeped from the Master.
    /// @param user The user who sweeped the token from the Master.
    /// @param to The recipient of the sweeped tokens.
    /// @param amount The amount of the token that was sweeped.
    event TokenSweeped(address indexed user, address indexed to, ERC20 indexed token, uint256 amount);

    /// @notice Claim tokens sitting idly in the Master.
    /// @param to The recipient of the sweeped tokens.
    /// @param token The token to sweep and send.
    /// @param amount The amount of the token to sweep.
    function sweep(
        address to,
        ERC20 token,
        uint256 amount
    ) external requiresAuth {
        emit TokenSweeped(msg.sender, to, token, amount);

        // Transfer the sweeped tokens to the recipient.
        token.safeTransfer(to, amount);
    }
}

/// @title Turbo Safe
/// @author Transmissions11
/// @notice Fuse liquidity accelerator.
contract TurboSafe is Auth, ERC4626, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract that created the Safe.
    /// @dev Fees are paid directly to the Master, where they can be swept.
    TurboMaster public immutable master;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /// @notice The Turbo Fuse Pool contract that collateral is held in and Fei is borrowed from.
    Comptroller public immutable pool;

    /// @notice The Fei cToken in the Turbo Fuse Pool that Fei is borrowed from.
    CERC20 public immutable feiTurboCToken;

    /// @notice The cToken that accepts the asset in the Turbo Fuse Pool.
    CERC20 public immutable assetTurboCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Safe that accepts a specific asset.
    /// @param _owner The owner of the Safe.
    /// @param _authority The Authority of the Safe.
    /// @param _asset The ERC20 compliant token the Safe should accept.
    constructor(
        address _owner,
        Authority _authority,
        ERC20 _asset
    )
        Auth(_owner, _authority)
        ERC4626(
            _asset,
            // ex: Dai Stablecoin Turbo Safe
            string(abi.encodePacked(_asset.name(), " Turbo Safe")),
            // ex: tsDAI
            string(abi.encodePacked("ts", _asset.symbol()))
        )
    {
        master = TurboMaster(msg.sender);

        fei = master.fei();

        // An asset of Fei makes no sense.
        require(asset != fei, "INVALID_ASSET");

        pool = master.pool();

        feiTurboCToken = pool.cTokensByUnderlying(fei);

        assetTurboCToken = pool.cTokensByUnderlying(asset);

        // If the provided asset is not supported by the Turbo Fuse Pool, revert.
        require(address(assetTurboCToken) != address(0), "UNSUPPORTED_ASSET");

        // Construct an array of market(s) to enable as collateral.
        CERC20[] memory marketsToEnter = new CERC20[](1);
        marketsToEnter[0] = assetTurboCToken;

        // Enter the market(s) and ensure to properly revert if there is an error.
        require(pool.enterMarkets(marketsToEnter)[0] == 0, "ENTER_MARKETS_FAILED");

        // Preemptively approve the asset to the Turbo Fuse Pool's corresponding cToken.
        asset.safeApprove(address(assetTurboCToken), type(uint256).max);

        // Preemptively approve Fei to the Turbo Fuse Pool's Fei cToken.
        fei.safeApprove(address(feiTurboCToken), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                               SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The current total amount of Fei the Safe is using to boost Vaults.
    uint256 public totalFeiBoosted;

    /// @notice Maps Vaults to the total amount of Fei they've being boosted with.
    /// @dev Used to determine the fees to be paid back to the Master.
    mapping(ERC4626 => uint256) public getTotalFeiBoostedForVault;

    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks the caller is authorized using either the Master's Authority or the Safe's local Authority.
    modifier requiresLocalOrMasterAuth() {
        // Check if the caller is the owner first:
        if (msg.sender != owner) {
            Authority masterAuth = master.authority(); // Avoid wasting gas calling the Master twice.

            // If the Master's Authority does not exist or does not accept upfront:
            if (address(masterAuth) == address(0) || !masterAuth.canCall(msg.sender, address(this), msg.sig)) {
                Authority auth = authority; // Memoizing saves us a warm SLOAD, around 100 gas.

                // The only authorization option left is via the local Authority, otherwise revert.
                require(
                    address(auth) != address(0) && auth.canCall(msg.sender, address(this), msg.sig),
                    "UNAUTHORIZED"
                );
            }
        }

        _;
    }

    /// @dev Checks the caller is authorized using the Master's Authority.
    modifier requiresMasterAuth() {
        Authority masterAuth = master.authority(); // Avoid wasting gas calling the Master twice.

        // Revert if the Master's Authority does not approve of the call and the caller is not the Master's owner.
        require(
            (address(masterAuth) != address(0) && masterAuth.canCall(msg.sender, address(this), msg.sig)) ||
                msg.sender == master.owner(),
            "UNAUTHORIZED"
        );

        _;
    }

    /*///////////////////////////////////////////////////////////////
                             ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Called after any type of deposit occurs.
    /// @param assetAmount The amount of assets being deposited.
    /// @dev Using requiresAuth here prevents unauthorized users from depositing.
    function afterDeposit(uint256 assetAmount, uint256) internal override nonReentrant requiresAuth {
        // Collateralize the assets in the Turbo Fuse Pool.
        require(assetTurboCToken.mint(assetAmount) == 0, "MINT_FAILED");
    }

    /// @notice Called before any type of withdrawal occurs.
    /// @param assetAmount The amount of assets being withdrawn.
    /// @dev Using requiresAuth here prevents unauthorized users from withdrawing.
    function beforeWithdraw(uint256 assetAmount, uint256) internal override nonReentrant requiresAuth {
        // Withdraw the assets from the Turbo Fuse Pool.
        require(assetTurboCToken.redeemUnderlying(assetAmount) == 0, "REDEEM_FAILED");
    }

    /// @notice Returns the total amount of assets held in the Safe.
    /// @return The total amount of assets held in the Safe.
    function totalAssets() public view override returns (uint256) {
        return assetTurboCToken.balanceOf(address(this)).mulWadDown(assetTurboCToken.exchangeRateStored());
    }

    /*///////////////////////////////////////////////////////////////
                           BOOST/LESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Vault is boosted by the Safe.
    /// @param user The user who boosted the Vault.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei that was boosted to the Vault.
    event VaultBoosted(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Borrow Fei from the Turbo Fuse Pool and deposit it into an authorized Vault.
    /// @param vault The Vault to deposit the borrowed Fei into.
    /// @param feiAmount The amount of Fei to borrow and supply into the Vault.
    function boost(ERC4626 vault, uint256 feiAmount) external nonReentrant requiresAuth {
        // Ensure the Vault accepts Fei asset.
        require(vault.asset() == fei, "NOT_FEI");

        // Call the Master where it will do extra validation
        // and update it's total count of funds used for boosting.
        master.onSafeBoost(asset, vault, feiAmount);

        // Increase the boost total proportionately.
        totalFeiBoosted += feiAmount;

        // Update the total Fei deposited into the Vault proportionately.
        getTotalFeiBoostedForVault[vault] += feiAmount;

        emit VaultBoosted(msg.sender, vault, feiAmount);

        // Borrow the Fei amount from the Fei cToken in the Turbo Fuse Pool.
        require(feiTurboCToken.borrow(feiAmount) == 0, "BORROW_FAILED");

        // Approve the borrowed Fei to the specified Vault.
        fei.safeApprove(address(vault), feiAmount);

        // Deposit the Fei into the specified Vault.
        vault.deposit(feiAmount, address(this));
    }

    /// @notice Emitted when a Vault is withdrawn from by the Safe.
    /// @param user The user who lessed the Vault.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei that was withdrawn from the Vault.
    event VaultLessened(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Withdraw Fei from a deposited Vault and use it to repay debt in the Turbo Fuse Pool.
    /// @param vault The Vault to withdraw the Fei from.
    /// @param feiAmount The amount of Fei to withdraw from the Vault and repay in the Turbo Fuse Pool.
    function less(ERC4626 vault, uint256 feiAmount) external nonReentrant requiresLocalOrMasterAuth {
        // Update the total Fei deposited into the Vault proportionately.
        getTotalFeiBoostedForVault[vault] -= feiAmount;

        // Decrease the boost total proportionately.
        totalFeiBoosted -= feiAmount;

        emit VaultLessened(msg.sender, vault, feiAmount);

        // Withdraw the specified amount of Fei from the Vault.
        vault.withdraw(feiAmount, address(this), address(this));

        // Get out current amount of Fei debt in the Turbo Fuse Pool.
        uint256 feiDebt = feiTurboCToken.borrowBalanceCurrent(address(this));

        // Call the Master to allow it to update its accounting.
        master.onSafeLess(asset, vault, feiAmount);

        // If our debt balance decreased, repay the minimum.
        // The surplus Fei will accrue as fees and can be sweeped.
        if (feiAmount > feiDebt) feiAmount = feiDebt;

        // Repay Fei debt in the Turbo Fuse Pool, unless we would repay nothing.
        if (feiAmount != 0) require(feiTurboCToken.repayBorrow(feiAmount) == 0, "REPAY_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                              SLURP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Vault is slurped from by the Safe.
    /// @param user The user who slurped the Vault.
    /// @param vault The Vault that was slurped.
    /// @param protocolFeeAmount The amount of Fei accrued as fees to the Master.
    /// @param safeInterestAmount The amount of Fei accrued as interest to the Safe.
    event VaultSlurped(
        address indexed user,
        ERC4626 indexed vault,
        uint256 protocolFeeAmount,
        uint256 safeInterestAmount
    );

    /// @notice Accrue any interest earned by the Safe in the Vault.
    /// @param vault The Vault to accrue interest from, if any.
    /// @dev Sends a portion of the interest to the Master, as determined by the Clerk.
    function slurp(ERC4626 vault) external nonReentrant requiresLocalOrMasterAuth returns(uint256 safeInterestAmount) {
        // Cache the total Fei currently boosting the Vault.
        uint256 totalFeiBoostedForVault = getTotalFeiBoostedForVault[vault];

        // Ensure the Safe has Fei currently boosting the Vault.
        require(totalFeiBoostedForVault != 0, "NO_FEI_BOOSTED");

        // Compute the amount of Fei interest the Safe generated by boosting the Vault.
        uint256 interestEarned = vault.previewRedeem(vault.balanceOf(address(this))) - totalFeiBoostedForVault;

        // Compute what percentage of the interest earned will go back to the Safe.
        uint256 protocolFeePercent = master.clerk().getFeePercentageForSafe(this, asset);

        // Compute the amount of Fei the protocol will retain as fees.
        uint256 protocolFeeAmount = interestEarned.mulWadDown(protocolFeePercent);

        // Compute the amount of Fei the Safe will retain as interest.
        safeInterestAmount = interestEarned - protocolFeeAmount;

        emit VaultSlurped(msg.sender, vault, protocolFeeAmount, safeInterestAmount);

        vault.withdraw(interestEarned, address(this), address(this));

        // If we have unaccrued fees, withdraw them from the Vault and transfer them to the Master.
        if (protocolFeeAmount != 0) fei.transfer(address(master), protocolFeeAmount);
    }

    /*///////////////////////////////////////////////////////////////
                              SWEEP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a token is sweeped from the Safe.
    /// @param user The user who sweeped the token from the Safe.
    /// @param to The recipient of the sweeped tokens.
    /// @param amount The amount of the token that was sweeped.
    event TokenSweeped(address indexed user, address indexed to, ERC20 indexed token, uint256 amount);

    /// @notice Claim tokens sitting idly in the Safe.
    /// @param to The recipient of the sweeped tokens.
    /// @param token The token to sweep and send.
    /// @param amount The amount of the token to sweep.
    function sweep(
        address to,
        ERC20 token,
        uint256 amount
    ) external requiresAuth {
        // Ensure the caller is not trying to steal Vault shares or collateral cTokens.
        require(getTotalFeiBoostedForVault[ERC4626(address(token))] == 0 && token != assetTurboCToken, "INVALID_TOKEN");

        emit TokenSweeped(msg.sender, to, token, amount);

        // Transfer the sweeped tokens to the recipient.
        token.safeTransfer(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               GIB LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Safe is gibbed.
    /// @param user The user who gibbed the Safe.
    /// @param to The recipient of the impounded collateral.
    /// @param assetAmount The amount of underling tokens impounded.
    event SafeGibbed(address indexed user, address indexed to, uint256 assetAmount);

    /// @notice Impound a specific amount of a Safe's collateral.
    /// @param to The address to send the impounded collateral to.
    /// @param assetAmount The amount of the asset to impound.
    /// @dev Debt must be repaid in advance, or the redemption will fail.
    function gib(address to, uint256 assetAmount) external nonReentrant requiresMasterAuth {
        emit SafeGibbed(msg.sender, to, assetAmount);

        // Withdraw the specified amount of assets from the Turbo Fuse Pool.
        require(assetTurboCToken.redeemUnderlying(assetAmount) == 0, "REDEEM_FAILED");

        // Transfer the assets to the authorized caller.
        asset.safeTransfer(to, assetAmount);
    }
}



/// @title Turbo Booster
/// @author Transmissions11
/// @notice Boost authorization module.
contract TurboBooster is Auth, ENSReverseRecordAuth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Booster contract.
    /// @param _owner The owner of the Booster.
    /// @param _authority The Authority of the Booster.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                      GLOBAL FREEZE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether boosting is currently frozen.
    bool public frozen;

    /// @notice Emitted when boosting is frozen or unfrozen.
    /// @param user The user who froze or unfroze boosting.
    /// @param frozen Whether boosting is now frozen.
    event FreezeStatusUpdated(address indexed user, bool frozen);

    /// @notice Sets whether boosting is frozen.
    /// @param freeze Whether boosting will be frozen.
    function setFreezeStatus(bool freeze) external requiresAuth {
        // Update freeze status.
        frozen = freeze;

        emit FreezeStatusUpdated(msg.sender, freeze);
    }

    /*///////////////////////////////////////////////////////////////
                     VAULT BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    ERC4626[] public boostableVaults;

    /// @notice exposes an array of boostable vaults. Only used for visibility.
    function getBoostableVaults() external view returns(ERC4626[] memory) {
        return boostableVaults;
    }

    /// @notice Maps Vaults to the cap on the amount of Fei used to boost them.
    mapping(ERC4626 => uint256) public getBoostCapForVault;

    /// @notice Emitted when a Vault's boost cap is updated.
    /// @param vault The Vault who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the Vault.
    event BoostCapUpdatedForVault(address indexed user, ERC4626 indexed vault, uint256 newBoostCap);

    /// @notice Sets a Vault's boost cap.
    /// @param vault The Vault to set the boost cap for.
    /// @param newBoostCap The new boost cap for the Vault.
    function setBoostCapForVault(ERC4626 vault, uint256 newBoostCap) external requiresAuth {
        require(newBoostCap != 0, "cap is zero");

        // Add to boostable vaults array
        if (getBoostCapForVault[vault] == 0) {
            boostableVaults.push(vault);
        }
        
        // Update the boost cap for the Vault.
        getBoostCapForVault[vault] = newBoostCap;

        emit BoostCapUpdatedForVault(msg.sender, vault, newBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                     COLLATERAL BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps collateral types to the cap on the amount of Fei boosted against them.
    mapping(ERC20 => uint256) public getBoostCapForCollateral;

    /// @notice Emitted when a collateral type's boost cap is updated.
    /// @param collateral The collateral type who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the collateral type.
    event BoostCapUpdatedForCollateral(address indexed user, ERC20 indexed collateral, uint256 newBoostCap);

    /// @notice Sets a collateral type's boost cap.
    /// @param collateral The collateral type to set the boost cap for.
    /// @param newBoostCap The new boost cap for the collateral type.
    function setBoostCapForCollateral(ERC20 collateral, uint256 newBoostCap) external requiresAuth {
        // Update the boost cap for the collateral type.
        getBoostCapForCollateral[collateral] = newBoostCap;

        emit BoostCapUpdatedForCollateral(msg.sender, collateral, newBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a Safe is authorized to boost a Vault.
    /// @param safe The Safe to check is authorized to boost the Vault.
    /// @param collateral The collateral/asset of the Safe.
    /// @param vault The Vault to check the Safe is authorized to boost.
    /// @param feiAmount The amount of Fei asset to check the Safe is authorized boost the Vault with.
    /// @param newTotalBoostedForVault The total amount of Fei that will boosted to the Vault after boost (if it is not rejected).
    /// @param newTotalBoostedAgainstCollateral The total amount of Fei that will be boosted against the Safe's collateral type after this boost.
    /// @return Whether the Safe is authorized to boost the Vault with the given amount of Fei asset.
    function canSafeBoostVault(
        TurboSafe safe,
        ERC20 collateral,
        ERC4626 vault,
        uint256 feiAmount,
        uint256 newTotalBoostedForVault,
        uint256 newTotalBoostedAgainstCollateral
    ) external view returns (bool) {
        return
            !frozen &&
            getBoostCapForVault[vault] >= newTotalBoostedForVault &&
            getBoostCapForCollateral[collateral] >= newTotalBoostedAgainstCollateral;
    }
}

/** 
 @title Turbo Admin of Turbo Fuse Pool and Turbo Timelock
*/
contract TurboAdmin is Auth, ENSReverseRecordAuth {
    /// @notice generic error thrown when comptroller call fails
    error ComptrollerError();

    /// @notice the fuse comptroller associated with the TurboAdmin
    Comptroller public immutable comptroller;

    /// @notice the turbo timelock
    TimelockController public immutable timelock;

    /// @notice constant zero interest rate model
    address public constant ZERO_IRM = 0xC9dB5A1034BcBcca3f59dD61dbeE31b78CeFD126;

    /// @notice cToken implementation
    address public constant CTOKEN_IMPL = 0x67Db14E73C2Dce786B5bbBfa4D010dEab4BBFCF9;

    /// @param _comptroller the fuse comptroller
    constructor(Comptroller _comptroller, TimelockController _timelock, Authority _authority) Auth(address(0), _authority) {
        comptroller = _comptroller;
        timelock = _timelock;
    }

    // ************ TURBO ADMIN FUNCTIONS ************

    function addCollateral(
        address underlying,
        string calldata name,
        string calldata symbol,
        uint256 collateralFactorMantissa,
        uint256 supplyCap
    ) external requiresAuth {
        bytes memory constructorData = abi.encode(
            underlying,
            address(comptroller),
            ZERO_IRM,
            name,
            symbol,
            CTOKEN_IMPL,
            new bytes(0),
            0, // zero admin fee
            0 // zero reserve factor
        );

        if (
            comptroller._deployMarket(
                false,
                constructorData,
                collateralFactorMantissa
            ) != 0
        ) revert ComptrollerError();
        
        // set borrow paused
        CERC20 cToken = comptroller.cTokensByUnderlying(ERC20(underlying));
        _setBorrowPausedInternal(cToken, true);

        CERC20[] memory markets = new CERC20[](1);
        markets[0] = cToken;
        uint256[] memory caps = new uint256[](1);
        caps[0] = supplyCap;

        comptroller._setMarketSupplyCaps(markets, caps);
    }

    // ************ BORROW GUARDIAN FUNCTIONS ************
    /**
     * @notice Set the given supply caps for the given cToken markets. Supplying that brings total underlying supply to or above supply cap will revert.
     * @dev Admin or borrowCapGuardian function to set the supply caps. A supply cap of 0 corresponds to unlimited supplying.
     * @param cTokens The addresses of the markets (tokens) to change the supply caps for
     * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited supplying.
     */
    function _setMarketSupplyCaps(
        CERC20[] memory cTokens,
        uint256[] calldata newSupplyCaps
    ) external requiresAuth {
        _setMarketSupplyCapsInternal(cTokens, newSupplyCaps);
    }

    function _setMarketSupplyCapsByUnderlying(
        address[] calldata underlyings,
        uint256[] calldata newSupplyCaps
    ) external requiresAuth {
        _setMarketSupplyCapsInternal(
            _underlyingToCTokens(underlyings),
            newSupplyCaps
        );
    }

    function _setMarketSupplyCapsInternal(
        CERC20[] memory cTokens,
        uint256[] calldata newSupplyCaps
    ) internal {
        comptroller._setMarketSupplyCaps(cTokens, newSupplyCaps);
    }

    function _underlyingToCTokens(address[] calldata underlyings)
        internal
        view
        returns (CERC20[] memory)
    {
        CERC20[] memory cTokens = new CERC20[](underlyings.length);
        for (uint256 i = 0; i < underlyings.length; i++) {
            CERC20 cToken = comptroller.cTokensByUnderlying(ERC20(underlyings[i]));
            require(address(cToken) != address(0), "cToken doesn't exist");
            cTokens[i] = CERC20(cToken);
        }
        return cTokens;
    }

    /**
     * @notice Set the given borrow caps for the given cToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
     * @param cTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
     */
    function _setMarketBorrowCaps(
        CERC20[] memory cTokens,
        uint256[] calldata newBorrowCaps
    ) external requiresAuth {
        _setMarketBorrowCapsInternal(cTokens, newBorrowCaps);
    }

    function _setMarketBorrowCapsInternal(
        CERC20[] memory cTokens,
        uint256[] calldata newBorrowCaps
    ) internal {
        comptroller._setMarketBorrowCaps(cTokens, newBorrowCaps);
    }

    function _setMarketBorrowCapsByUnderlying(
        address[] calldata underlyings,
        uint256[] calldata newBorrowCaps
    ) external requiresAuth {
        _setMarketBorrowCapsInternal(
            _underlyingToCTokens(underlyings),
            newBorrowCaps
        );
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian)
        external
        requiresAuth
    {
        comptroller._setBorrowCapGuardian(newBorrowCapGuardian);
    }

    // ************ PAUSE GUARDIAN FUNCTIONS ************
    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian)
        external
        requiresAuth
        returns (uint256)
    {
        return comptroller._setPauseGuardian(newPauseGuardian);
    }

    function _setMintPausedByUnderlying(ERC20 underlying, bool state)
        external
        requiresAuth
        returns (bool)
    {
        CERC20 cToken = comptroller.cTokensByUnderlying(underlying);
        require(address(cToken) != address(0), "cToken doesn't exist");
        return _setMintPausedInternal(cToken, state);
    }

    function _setMintPaused(CERC20 cToken, bool state)
        external
        requiresAuth
        returns (bool)
    {
        return _setMintPausedInternal(cToken, state);
    }

    function _setMintPausedInternal(CERC20 cToken, bool state)
        internal
        returns (bool)
    {
        return comptroller._setMintPaused(cToken, state);
    }

    function _setBorrowPausedByUnderlying(ERC20 underlying, bool state)
        external
        requiresAuth
        returns (bool)
    {
        CERC20 cToken = comptroller.cTokensByUnderlying(underlying);
        require(address(cToken) != address(0), "cToken doesn't exist");
        return _setBorrowPausedInternal(cToken, state);
    }

    function _setBorrowPausedInternal(CERC20 cToken, bool state)
        internal
        returns (bool)
    {
        return comptroller._setBorrowPaused(cToken, state);
    }

    function _setBorrowPaused(CERC20 cToken, bool state)
        external
        requiresAuth
        returns (bool)
    {
        return _setBorrowPausedInternal(CERC20(cToken), state);
    }

    function _setTransferPaused(bool state)
        external
        requiresAuth
        returns (bool)
    {
        return comptroller._setTransferPaused(state);
    }

    function _setSeizePaused(bool state)
        external
        requiresAuth
        returns (bool)
    {
        return comptroller._setSeizePaused(state);
    }

    // ************ FUSE ADMIN FUNCTIONS ************

    function oracleAdd(
        address[] calldata underlyings,
        address[] calldata _oracles
    ) external requiresAuth {
        comptroller.oracle().add(underlyings, _oracles);
    }

    function oracleChangeAdmin(address newAdmin) external requiresAuth {
        comptroller.oracle().changeAdmin(newAdmin);
    }

    function _addRewardsDistributor(address distributor)
        external
        requiresAuth
    {
        if (comptroller._addRewardsDistributor(distributor) != 0)
            revert ComptrollerError();
    }

    function _setWhitelistEnforcement(bool enforce)
        external
        requiresAuth
    {
        if (comptroller._setWhitelistEnforcement(enforce) != 0)
            revert ComptrollerError();
    }

    function _setWhitelistStatuses(
        address[] calldata suppliers,
        bool[] calldata statuses
    ) external requiresAuth {
        if (comptroller._setWhitelistStatuses(suppliers, statuses) != 0)
            revert ComptrollerError();
    }

    function _setPriceOracle(address newOracle) public requiresAuth {
        if (comptroller._setPriceOracle(newOracle) != 0)
            revert ComptrollerError();
    }

    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        requiresAuth
    {
        if (comptroller._setCloseFactor(newCloseFactorMantissa) != 0)
            revert ComptrollerError();
    }

    function _setCollateralFactor(
        CERC20 cToken,
        uint256 newCollateralFactorMantissa
    ) public requiresAuth {
        if (
            comptroller._setCollateralFactor(
                cToken,
                newCollateralFactorMantissa
            ) != 0
        ) revert ComptrollerError();
    }

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        requiresAuth
    {
        if (
            comptroller._setLiquidationIncentive(
                newLiquidationIncentiveMantissa
            ) != 0
        ) revert ComptrollerError();
    }

    function _deployMarket(
        address underlying,
        address irm,
        string calldata name,
        string calldata symbol,
        address impl,
        bytes calldata data,
        uint256 reserveFactor,
        uint256 adminFee,
        uint256 collateralFactorMantissa
    ) external requiresAuth {
        bytes memory constructorData = abi.encode(
            underlying,
            address(comptroller),
            irm,
            name,
            symbol,
            impl,
            data,
            reserveFactor,
            adminFee
        );

        if (
            comptroller._deployMarket(
                false,
                constructorData,
                collateralFactorMantissa
            ) != 0
        ) revert ComptrollerError();
    }

    function _unsupportMarket(CERC20 cToken) external requiresAuth {
        if (comptroller._unsupportMarket(cToken) != 0)
            revert ComptrollerError();
    }

    function _toggleAutoImplementations(bool enabled)
        public
        requiresAuth
    {
        if (comptroller._toggleAutoImplementations(enabled) != 0)
            revert ComptrollerError();
    }

    function scheduleSetPendingAdmin(address newPendingAdmin) public requiresAuth {
        _schedule(address(this), abi.encodeWithSelector(this._setPendingAdmin.selector, newPendingAdmin));
    }

    function _setPendingAdmin(address newPendingAdmin)
        public
    {
        require(msg.sender == address(timelock), "timelock");

        if (comptroller._setPendingAdmin(newPendingAdmin) != 0)
            revert ComptrollerError();
    }

    function _acceptAdmin() public {
        if (comptroller._acceptAdmin() != 0) revert ComptrollerError();
    }

    // ************ TIMELOCK ADMIN FUNCTIONS ************
    function schedule(address target, bytes memory data) public requiresAuth {
        _schedule(target, data);
    }

    function _schedule(address target, bytes memory data) internal {
        timelock.schedule(target, 0, data, bytes32(0), keccak256(abi.encodePacked(block.timestamp)), 15 days);
    }

    function cancel(bytes32 id) public requiresAuth {
        timelock.cancel(id);
    }

    function execute(address target, bytes memory data, bytes32 salt) public requiresAuth {
        timelock.execute(target, 0, data, bytes32(0), salt);
    }
}

/// @title Fei
/// @author Fei Protocol
/// @notice Minimal interface for the Fei token.
abstract contract Fei is ERC20 {
    function mint(address to, uint256 amount) external virtual;
}







/// @title Turbo Gibber
/// @author Transmissions11
/// @notice Atomic impounder module.
contract TurboGibber is Auth, ReentrancyGuard, ENSReverseRecordAuth {
    using SafeTransferLib for Fei;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract.
    /// @dev Used to validate Safes are legitimate.
    TurboMaster public immutable master;

    /// @notice The Fei token on the network.
    Fei public immutable fei;

    /// @notice The Fei cToken in the Turbo Fuse Pool.
    CERC20 public immutable feiTurboCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Gibber contract.
    /// @param _master The Master of the Gibber.
    /// @param _owner The owner of the Gibber.
    /// @param _authority The Authority of the Gibber.
    constructor(
        TurboMaster _master,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        master = _master;

        fei = Fei(address(master.fei()));

        feiTurboCToken = master.pool().cTokensByUnderlying(fei);

        // Preemptively approve to the Fei cToken in the Turbo Fuse Pool.
        fei.safeApprove(address(feiTurboCToken), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                          ATOMIC IMPOUND LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted an impound is executed.
    /// @param user The user who executed the impound.
    /// @param safe The Safe that was impounded.
    /// @param feiAmount The amount of Fei that was repaid.
    /// @param assetAmount The amount of assets impounded.
    event ImpoundExecuted(address indexed user, TurboSafe indexed safe, uint256 feiAmount, uint256 assetAmount);

    /// @notice Impound a safe.
    /// @param safe The Safe to be impounded.
    /// @param feiAmount The amount of Fei to repay the Safe's debt with.
    /// @param assetAmount The amount of assets to impound.
    /// @param to The recipient of the impounded collateral tokens.
    function impound(
        TurboSafe safe,
        uint256 feiAmount,
        uint256 assetAmount,
        address to
    ) external requiresAuth nonReentrant {
        // Ensure the Safe is registered with the Master.
        require(master.getSafeId(safe) != 0);

        emit ImpoundExecuted(msg.sender, safe, feiAmount, assetAmount);

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Repay the safe's Fei debt with the minted Fei, ensuring to catch cToken errors.
        require(feiTurboCToken.repayBorrowBehalf(address(safe), feiAmount) == 0, "REPAY_FAILED");

        // Impound some of the safe's collateral and send it to the chosen recipient.
        safe.gib(to, assetAmount);
    }

    /// @notice Impound all of a safe's collateral.
    /// @param safe The Safe to be impounded.
    /// @param to The recipient of the impounded collateral tokens.
    function impoundAll(TurboSafe safe, address to) external requiresAuth nonReentrant {
        // Ensure the Safe is registered with the Master.
        require(master.getSafeId(safe) != 0);

        // Get the asset cToken in the Turbo Fuse Pool.
        CERC20 assetTurboCToken = safe.assetTurboCToken();

        // Get the amount of assets to impound from the Safe.
        uint256 assetAmount = assetTurboCToken.balanceOfUnderlying(address(safe));

        // Get the amount of Fei debt to repay for the Safe.
        uint256 feiAmount = feiTurboCToken.borrowBalanceCurrent(address(safe));

        emit ImpoundExecuted(msg.sender, safe, feiAmount, assetAmount);

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Repay the safe's Fei debt with the minted Fei, ensuring to catch cToken errors.
        require(feiTurboCToken.repayBorrowBehalf(address(safe), feiAmount) == 0, "REPAY_FAILED");

        // Impound all of the safe's collateral and send it to the chosen recipient.
        safe.gib(to, assetAmount);
    }
}

/// @title Turbo Savior
/// @author Transmissions11
/// @notice Safe repayment module.
contract TurboSavior is Auth, ReentrancyGuard, ENSReverseRecordAuth {
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract.
    /// @dev Used to validate Safes are legitimate.
    TurboMaster public immutable master;

    /// @notice The Fei token on the network.
    Fei public immutable fei;

    /// @notice The Turbo Fuse Pool used by the Master.
    Comptroller public immutable pool;

    /// @notice The Fei cToken in the Turbo Fuse Pool.
    CERC20 public immutable feiTurboCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Savior contract.
    /// @param _master The Master of the Savior.
    /// @param _owner The owner of the Savior.
    /// @param _authority The Authority of the Savior.
    constructor(
        TurboMaster _master,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        master = _master;

        fei = Fei(address(master.fei()));

        pool = master.pool();

        feiTurboCToken = pool.cTokensByUnderlying(fei);
    }

    /*///////////////////////////////////////////////////////////////
                              LINE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice The minimum percentage debt must make up of the borrow limit for a Safe to be saved.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    uint256 public minDebtPercentageForSaving;

    /// @notice Emitted when the minimum debt percentage for saving is updated.
    /// @param newDefaultFeePercentage The new minimum debt percentage for saving.
    event MinDebtPercentageForSavingUpdated(address indexed user, uint256 newDefaultFeePercentage);

    /// @notice Sets the minimum debt percentage.
    /// @param newMinDebtPercentageForSaving The new minimum debt percentage.
    function setMinDebtPercentageForSaving(uint256 newMinDebtPercentageForSaving) external requiresAuth {
        // A minimum debt percentage over 100% makes no sense.
        require(newMinDebtPercentageForSaving <= 1e18, "PERCENT_TOO_HIGH");

        // Update the minimum debt percentage.
        minDebtPercentageForSaving = newMinDebtPercentageForSaving;

        emit MinDebtPercentageForSavingUpdated(msg.sender, newMinDebtPercentageForSaving);
    }

    /*///////////////////////////////////////////////////////////////
                              SAVE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a save is executed.
    /// @param user The user who executed the save.
    /// @param safe The Safe that was saved.
    /// @param vault The Vault that was lessed.
    /// @param feiAmount The amount of Fei that was lessed.
    event SafeSaved(address indexed user, TurboSafe indexed safe, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Save a Safe (call less on owner's behalf to prevent liquidation).
    /// @param safe The Safe to be saved.
    /// @param vault The Vault to less from.
    /// @param feiAmount The amount of Fei to less from the Safe.
    function save(
        TurboSafe safe,
        ERC4626 vault,
        uint256 feiAmount
    ) external requiresAuth nonReentrant {
        // Ensure the Safe is registered with the Master.
        require(master.getSafeId(safe) != 0);

        emit SafeSaved(msg.sender, safe, vault, feiAmount);

        // Cache the Safe's collateral asset.
        CERC20 assetTurboCToken = safe.assetTurboCToken();

        // Cache the pool's current oracle.
        PriceFeed oracle = pool.oracle();

        // Get the Safe's asset's collateral factor in the Turbo Fuse Pool.
        (, uint256 collateralFactor) = pool.markets(assetTurboCToken);

        // Compute the value of the Safe's collateral. Rounded down to favor saving.
        uint256 borrowLimit = assetTurboCToken
            .balanceOf(address(safe))
            .mulWadDown(assetTurboCToken.exchangeRateStored())
            .mulWadDown(collateralFactor)
            .mulWadDown(oracle.getUnderlyingPrice(assetTurboCToken));

        // Compute the value of the Safe's debt. Rounding up to favor saving them.
        uint256 debtValue = feiTurboCToken.borrowBalanceCurrent(address(safe)).mulWadUp(
            oracle.getUnderlyingPrice(feiTurboCToken)
        );

        // Ensure the Safe's debt percentage is high enough to justify saving, otherwise revert.
        require(
            borrowLimit != 0 && debtValue.divWadUp(borrowLimit) >= minDebtPercentageForSaving,
            "DEBT_PERCENT_TOO_LOW"
        );

        // Less the Fei from the Safe.
        safe.less(vault, feiAmount);
    }
}


/// @title ERC4626 interface
/// @author Fei Protocol
/// See: https://eips.ethereum.org/EIPS/eip-4626
abstract contract IERC4626 is ERC20 {

    /*////////////////////////////////////////////////////////
                      Events
    ////////////////////////////////////////////////////////*/

    /// @notice `sender` has exchanged `assets` for `shares`,
    /// and transferred those `shares` to `receiver`.
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    /// @notice `sender` has exchanged `shares` for `assets`,
    /// and transferred those `assets` to `receiver`.
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    /*////////////////////////////////////////////////////////
                      Vault properties
    ////////////////////////////////////////////////////////*/

    /// @notice The address of the underlying ERC20 token used for
    /// the Vault for accounting, depositing, and withdrawing.
    function asset() external view virtual returns(address asset);

    /// @notice Total amount of the underlying asset that
    /// is "managed" by Vault.
    function totalAssets() external view virtual returns(uint256 totalAssets);

    /*////////////////////////////////////////////////////////
                      Deposit/Withdrawal Logic
    ////////////////////////////////////////////////////////*/

    /// @notice Mints `shares` Vault shares to `receiver` by
    /// depositing exactly `assets` of underlying tokens.
    function deposit(uint256 assets, address receiver) external virtual returns(uint256 shares);

    /// @notice Mints exactly `shares` Vault shares to `receiver`
    /// by depositing `assets` of underlying tokens.
    function mint(uint256 shares, address receiver) external virtual returns(uint256 assets);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function withdraw(uint256 assets, address receiver, address owner) external virtual returns(uint256 shares);

    /// @notice Redeems `shares` from `owner` and sends `assets`
    /// of underlying tokens to `receiver`.
    function redeem(uint256 shares, address receiver, address owner) external virtual returns(uint256 assets);

    /*////////////////////////////////////////////////////////
                      Vault Accounting Logic
    ////////////////////////////////////////////////////////*/

    /// @notice The amount of shares that the vault would
    /// exchange for the amount of assets provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToShares(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice The amount of assets that the vault would
    /// exchange for the amount of shares provided, in an
    /// ideal scenario where all the conditions are met.
    function convertToAssets(uint256 shares) external view virtual returns(uint256 assets);

    /// @notice Total number of underlying assets that can
    /// be deposited by `owner` into the Vault, where `owner`
    /// corresponds to the input parameter `receiver` of a
    /// `deposit` call.
    function maxDeposit(address owner) external view virtual returns(uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their deposit at the current block, given
    /// current on-chain conditions.
    function previewDeposit(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice Total number of underlying shares that can be minted
    /// for `owner`, where `owner` corresponds to the input
    /// parameter `receiver` of a `mint` call.
    function maxMint(address owner) external view virtual returns(uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their mint at the current block, given
    /// current on-chain conditions.
    function previewMint(uint256 shares) external view virtual returns(uint256 assets);

    /// @notice Total number of underlying assets that can be
    /// withdrawn from the Vault by `owner`, where `owner`
    /// corresponds to the input parameter of a `withdraw` call.
    function maxWithdraw(address owner) external view virtual returns(uint256 maxAssets);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    function previewWithdraw(uint256 assets) external view virtual returns(uint256 shares);

    /// @notice Total number of underlying shares that can be
    /// redeemed from the Vault by `owner`, where `owner` corresponds
    /// to the input parameter of a `redeem` call.
    function maxRedeem(address owner) external view virtual returns(uint256 maxShares);

    /// @notice Allows an on-chain or off-chain user to simulate
    /// the effects of their redeemption at the current block,
    /// given current on-chain conditions.
    function previewRedeem(uint256 shares) external view virtual returns(uint256 assets);
}

/** 
 @title ERC4626Router Base Interface
 @author joeysantoro
 @notice A canonical router between ERC4626 Vaults https://eips.ethereum.org/EIPS/eip-4626

 The base router is a multicall style router inspired by Uniswap v3 with built-in features for permit, WETH9 wrap/unwrap, and ERC20 token pulling/sweeping/approving.
 It includes methods for the four mutable ERC4626 functions deposit/mint/withdraw/redeem as well.

 These can all be arbitrarily composed using the multicall functionality of the router.

 NOTE the router is capable of pulling any approved token from your wallet. This is only possible when your address is msg.sender, but regardless be careful when interacting with the router or ERC4626 Vaults.
 The router makes no special considerations for unique ERC20 implementations such as fee on transfer. 
 There are no built in protections for unexpected behavior beyond enforcing the minSharesOut is received.
 */
interface IERC4626RouterBase {
    /************************** Errors **************************/

    /// @notice thrown when amount of assets received is below the min set by caller
    error MinAmountError();

    /// @notice thrown when amount of shares received is below the min set by caller
    error MinSharesError();

    /// @notice thrown when amount of assets received is above the max set by caller
    error MaxAmountError();

    /// @notice thrown when amount of shares received is above the max set by caller
    error MaxSharesError();

    /************************** Mint **************************/
    
    /** 
     @notice mint `shares` from an ERC4626 vault.
     @param vault The ERC4626 vault to mint shares from.
     @param to The destination of ownership shares.
     @param shares The amount of shares to mint from `vault`.
     @param maxAmountIn The max amount of assets used to mint.
     @return amountIn the amount of assets used to mint by `to`.
     @dev throws MaxAmountError   
    */
    function mint(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 maxAmountIn
    ) external payable returns (uint256 amountIn);

    /************************** Deposit **************************/
    
    /** 
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinSharesError   
    */
    function deposit(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /** 
     @notice withdraw `amount` from an ERC4626 vault.
     @param vault The ERC4626 vault to withdraw assets from.
     @param to The destination of assets.
     @param amount The amount of assets to withdraw from vault.
     @param minSharesOut The min amount of shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MaxSharesError   
    */
    function withdraw(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /** 
     @notice redeem `shares` shares from an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param to The destination of assets.
     @param shares The amount of shares to redeem from vault.
     @param minAmountOut The min amount of assets received by `to`.
     @return amountOut the amount of assets received by `to`.
     @dev throws MinAmountError   
    */
    function redeem(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut);
}
// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISelfPermit.sol


/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}
// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/external/IERC20PermitAllowed.sol


/// @title Interface for permit
/// @notice Interface used by DAI/CHAI for permit
interface IERC20PermitAllowed {
    /// @notice Approve the spender to spend some tokens via the holder signature
    /// @dev This is the permit interface used by DAI and CHAI
    /// @param holder The address of the token holder, the token owner
    /// @param spender The address of the token spender
    /// @param nonce The holder's nonce, increases at each call to permit
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract SelfPermit is ISelfPermit {
    /// @inheritdoc ISelfPermit
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        ERC20(token).permit(msg.sender, address(this), value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (ERC20(token).allowance(msg.sender, address(this)) < value) selfPermit(token, value, deadline, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable override {
        IERC20PermitAllowed(token).permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
    }

    /// @inheritdoc ISelfPermit
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override {
        if (ERC20(token).allowance(msg.sender, address(this)) < type(uint256).max)
            selfPermitAllowed(token, nonce, expiry, v, r, s);
    }
}// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol


// forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/IMulticall.sol
   

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}/**
 @title Periphery Payments
 @notice Immutable state used by periphery contracts
 Largely Forked from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/PeripheryPayments.sol 
 Changes:
 * no interface
 * no inheritdoc
 * add immutable WETH9 in constructor instead of PeripheryImmutableState
 * receive from any address
 * Solmate interfaces and transfer lib
 * casting
 * add approve, wrapWETH9 and pullToken
*/ 
abstract contract PeripheryPayments {
    using SafeTransferLib for *;

    IWETH9 public immutable WETH9;

    constructor(IWETH9 _WETH9) {
        WETH9 = _WETH9;
    }

    receive() external payable {}

    function approve(ERC20 token, address to, uint256 amount) public payable {
        token.safeApprove(to, amount);
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable {
        uint256 balanceWETH9 = WETH9.balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, 'Insufficient WETH9');

        if (balanceWETH9 > 0) {
            WETH9.withdraw(balanceWETH9);
            recipient.safeTransferETH(balanceWETH9);
        }
    }

    function wrapWETH9() public payable {
        if (address(this).balance > 0) WETH9.deposit{value: address(this).balance}(); // wrap everything
    }

    function pullToken(ERC20 token, uint256 amount, address recipient) public payable {
        token.safeTransferFrom(msg.sender, recipient, amount);
    }

    function sweepToken(
        ERC20 token,
        uint256 amountMinimum,
        address recipient
    ) public payable {
        uint256 balanceToken = token.balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            token.safeTransfer(recipient, balanceToken);
        }
    }

    function refundETH() external payable {
        if (address(this).balance > 0) SafeTransferLib.safeTransferETH(msg.sender, address(this).balance);
    }
}

abstract contract IWETH9 is ERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable virtual;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external virtual;
}
/// @title ERC4626 Router Base Contract
/// @author joeysantoro
abstract contract ERC4626RouterBase is IERC4626RouterBase, SelfPermit, Multicall, PeripheryPayments {
    using SafeTransferLib for ERC20;

    /// @inheritdoc IERC4626RouterBase
    function mint(
        IERC4626 vault, 
        address to,
        uint256 shares,
        uint256 maxAmountIn
    ) public payable virtual override returns (uint256 amountIn) {
        if ((amountIn = vault.mint(shares, to)) > maxAmountIn) {
            revert MaxAmountError();
        }
    }

    /// @inheritdoc IERC4626RouterBase
    function deposit(
        IERC4626 vault, 
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        if ((sharesOut = vault.deposit(amount, to)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    /// @inheritdoc IERC4626RouterBase
    function withdraw(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 maxSharesOut
    ) public payable virtual override returns (uint256 sharesOut) {
        if ((sharesOut = vault.withdraw(amount, to, msg.sender)) > maxSharesOut) {
            revert MaxSharesError();
        }
    }

    /// @inheritdoc IERC4626RouterBase
    function redeem(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) public payable virtual override returns (uint256 amountOut) {
        if ((amountOut = vault.redeem(shares, to, msg.sender)) < minAmountOut) {
            revert MinAmountError();
        }
    }
}







/**
 @title a router which can perform multiple Turbo actions between Master and the Safes
 @notice routes custom users flows between actions on the master and safes.

 Extends the ERC4626RouterBase to allow for flexible combinations of actions involving ERC4626 and permit, weth, and Turbo specific actions.

 Safe Creation has functions bundled with deposit (and optionally boost) because a newly created Safe address can only be known at runtime. 
 The caller is always atomically given the owner role of a new safe.

 Authentication requires the caller to be the owner of the Safe to perform any ERC4626 method or TurboSafe requiresAuth method. 
 Assumes the Safe's authority gives permission to call these functions to the TurboRouter.
 */
contract TurboRouter is ERC4626RouterBase, ENSReverseRecordAuth {
    using SafeTransferLib for ERC20;

    TurboMaster public immutable master;

    constructor (TurboMaster _master, address _owner, Authority _authority, IWETH9 weth) Auth(_owner, _authority) PeripheryPayments(weth) {
        master = _master;
    }

    modifier authenticate(address target) {
        require(msg.sender == Auth(target).owner() || Auth(target).authority().canCall(msg.sender, target, msg.sig), "NOT_AUTHED");

        _;
    }

    function createSafe(ERC20 underlying) external returns (TurboSafe safe) {
        (safe, ) = master.createSafe(underlying);

        safe.setOwner(msg.sender);
    }

    function createSafeAndDeposit(ERC20 underlying, address to, uint256 amount, uint256 minSharesOut) external returns (TurboSafe safe) {
        (safe, ) = master.createSafe(underlying);

        // approve max from router to save depositor gas in future.
        approve(underlying, address(safe), type(uint256).max);

        super.deposit(IERC4626(address(safe)), to, amount, minSharesOut);

        safe.setOwner(msg.sender);
    }

    function createSafeAndDepositAndBoost(
        ERC20 underlying, 
        address to, 
        uint256 amount, 
        uint256 minSharesOut, 
        ERC4626 boostedVault, 
        uint256 boostedFeiAmount
    ) public returns (TurboSafe safe) {
        (safe, ) = master.createSafe(underlying);

        // approve max from router to save depositor gas in future.
        approve(underlying, address(safe), type(uint256).max);

        super.deposit(IERC4626(address(safe)), to, amount, minSharesOut);

        safe.boost(boostedVault, boostedFeiAmount);

        safe.setOwner(msg.sender);
    }

    function createSafeAndDepositAndBoostMany(
        ERC20 underlying, 
        address to, 
        uint256 amount, 
        uint256 minSharesOut, 
        ERC4626[] calldata boostedVaults, 
        uint256[] calldata boostedFeiAmounts
    ) public returns (TurboSafe safe) {
        (safe, ) = master.createSafe(underlying);

        // approve max from router to save depositor gas in future.
        approve(underlying, address(safe), type(uint256).max);

        super.deposit(IERC4626(address(safe)), to, amount, minSharesOut);

        unchecked {
            require(boostedVaults.length == boostedFeiAmounts.length, "length");
            for (uint256 i = 0; i < boostedVaults.length; i++) {
                safe.boost(boostedVaults[i], boostedFeiAmounts[i]);
            }     
        }

        safe.setOwner(msg.sender);
    }

    function deposit(IERC4626 safe, address to, uint256 amount, uint256 minSharesOut) 
        public 
        payable 
        override 
        authenticate(address(safe)) 
        returns (uint256) 
    {
        return super.deposit(safe, to, amount, minSharesOut);
    }

    function mint(IERC4626 safe, address to, uint256 shares, uint256 maxAmountIn) 
        public 
        payable 
        override 
        authenticate(address(safe)) 
        returns (uint256) 
    {
        return super.mint(safe, to, shares, maxAmountIn);
    }

    function withdraw(IERC4626 safe, address to, uint256 amount, uint256 maxSharesOut) 
        public 
        payable 
        override 
        authenticate(address(safe)) 
        returns (uint256) 
    {
        return super.withdraw(safe, to, amount, maxSharesOut);
    }

    function redeem(IERC4626 safe, address to, uint256 shares, uint256 minAmountOut) 
        public 
        payable 
        override 
        authenticate(address(safe)) 
        returns (uint256) 
    {
        return super.redeem(safe, to, shares, minAmountOut);
    }

    function slurp(TurboSafe safe, ERC4626 vault) external authenticate(address(safe)) {
        safe.slurp(vault);
    }

    function boost(TurboSafe safe, ERC4626 vault, uint256 feiAmount) public authenticate(address(safe)) {
        safe.boost(vault, feiAmount);
    }

    function less(TurboSafe safe, ERC4626 vault, uint256 feiAmount) external authenticate(address(safe)) {
        safe.less(vault, feiAmount);
    }

    function lessAll(TurboSafe safe, ERC4626 vault) external authenticate(address(safe)) {
        safe.less(vault, vault.maxWithdraw(address(safe)));
    }

    function sweep(TurboSafe safe, address to, ERC20 token, uint256 amount) external authenticate(address(safe)) {
        safe.sweep(to, token, amount);
    }

    function sweepAll(TurboSafe safe, address to, ERC20 token) external authenticate(address(safe)) {
        safe.sweep(to, token, token.balanceOf(address(safe)));
    }

    function slurpAndLessAll(TurboSafe safe, ERC4626 vault) external authenticate(address(safe)) {
        safe.slurp(vault);
        safe.less(vault, vault.maxWithdraw(address(safe)));
    }
}




/**
 @title Turbo Configurer
 IS INTENDED FOR MAINNET DEPLOYMENT

 This contract is a helper utility to completely configure the turbo system, assuming the contracts are deployed.
 The deployment should follow the logic in Deployer.sol.

 Each function details its access control assumptions.
 */ 
contract Configurer {

    /// @notice Fei DAO Timelock, to be granted TURBO_ADMIN_ROLE and GOVERN_ROLE
    address constant feiDAOTimelock = 0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c;
    
    /// @notice Tribe Guardian, to be granted GUARDIAN_ROLE
    address constant guardian = 0xB8f482539F2d3Ae2C9ea6076894df36D1f632775;

    ERC20 fei = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    ERC20 tribe = ERC20(0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B);

    /******************** ROLES ********************/

    /// @notice HIGH CLEARANCE. capable of calling `gib` to impound collateral. 
    uint8 public constant GIBBER_ROLE = 1;
    
    /// @notice HIGH CLEARANCE. Optional module which can interact with any user's vault by default.
    uint8 public constant ROUTER_ROLE = 2;

    /// @notice Capable of lessing any vault. Exposed on optional TurboSavior module.
    uint8 public constant SAVIOR_ROLE = 3;

    /// @notice Operational admin of Turbo, can whitelist collaterals, strategies, and configure most parameters.
    uint8 public constant TURBO_ADMIN_ROLE = 4;
    
    /// @notice Pause and security Guardian role
    uint8 public constant GUARDIAN_ROLE = 5;
    
    /// @notice HIGH CLEARANCE. Capable of critical governance functionality on TurboAdmin such as oracle upgrades. 
    uint8 public constant GOVERN_ROLE = 6;

    /// @notice limited version of TURBO_ADMIN_ROLE which can manage collateral and vault parameters.
    uint8 public constant TURBO_STRATEGIST_ROLE = 7;

    /******************** CONFIGURATION ********************/

    /// @notice configure the turbo timelock. Requires TIMELOCK_ADMIN_ROLE over timelock.
    function configureTimelock(TimelockController turboTimelock, TurboAdmin admin) public {
        turboTimelock.grantRole(turboTimelock.TIMELOCK_ADMIN_ROLE(), address(admin));
        turboTimelock.grantRole(turboTimelock.EXECUTOR_ROLE(), address(admin));
        turboTimelock.grantRole(turboTimelock.PROPOSER_ROLE(), address(admin));
        turboTimelock.revokeRole(turboTimelock.TIMELOCK_ADMIN_ROLE(), address(this));
    }

    /// @notice configure the turbo authority. Requires ownership over turbo authority.
    function configureAuthority(MultiRolesAuthority turboAuthority) public {
        // GIBBER_ROLE
        turboAuthority.setRoleCapability(GIBBER_ROLE, TurboSafe.gib.selector, true);
        
        // TURBO_ADMIN_ROLE
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboSafe.slurp.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboSafe.less.selector, true);
        
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.createSafe.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.setBooster.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.setClerk.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.setDefaultSafeAuthority.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.sweep.selector, true);
        
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboClerk.setDefaultFeePercentage.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboClerk.setCustomFeePercentageForCollateral.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboClerk.setCustomFeePercentageForSafe.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboBooster.setFreezeStatus.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboBooster.setBoostCapForVault.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboBooster.setBoostCapForCollateral.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboSavior.setMinDebtPercentageForSaving.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketSupplyCaps.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketSupplyCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketBorrowCaps.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketBorrowCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMintPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMintPaused.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setBorrowPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setBorrowPaused.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.oracleAdd.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.addCollateral.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._deployMarket.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._addRewardsDistributor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setWhitelistStatuses.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setCloseFactor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setCollateralFactor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setLiquidationIncentive.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.schedule.selector, true);
        
        // GUARDIAN_ROLE
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboSafe.less.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboBooster.setFreezeStatus.selector, true);
        
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketSupplyCaps.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketSupplyCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketBorrowCaps.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketBorrowCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMintPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMintPaused.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setBorrowPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setBorrowPaused.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setTransferPaused.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setSeizePaused.selector, true);
        
        // GOVERN_ROLE
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setBorrowCapGuardian.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setPauseGuardian.selector, true);

        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.oracleChangeAdmin.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setWhitelistEnforcement.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setPriceOracle.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._unsupportMarket.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._toggleAutoImplementations.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.scheduleSetPendingAdmin.selector, true);

        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.schedule.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.cancel.selector, true);


        turboAuthority.setPublicCapability(TurboAdmin.execute.selector, true);
    
        // TURBO_STRATEGIST_ROLE
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboAdmin.addCollateral.selector, true);
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboAdmin._setMarketSupplyCaps.selector, true);
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboAdmin._setMarketSupplyCapsByUnderlying.selector, true);
        
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboBooster.setBoostCapForVault.selector, true);
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboBooster.setBoostCapForCollateral.selector, true);
    
        turboAuthority.setPublicCapability(TurboSavior.save.selector, true);
    }

        /// @notice configure the default authority. Requires ownership over default authority.
    function configureDefaultAuthority(MultiRolesAuthority defaultAuthority) public {
        // ROUTER_ROLE
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.boost.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.less.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.slurp.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.sweep.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.deposit.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.mint.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.withdraw.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.redeem.selector, true);


        // SAVIOR_ROLE
        defaultAuthority.setRoleCapability(SAVIOR_ROLE, TurboSafe.less.selector, true);
    }

    /// @notice configure the turbo pool through turboAdmin. TurboAdmin requires pool ownership, and Configurer requires TURBO_ADMIN_ROLE.
    function configurePool(TurboAdmin turboAdmin, TurboBooster booster) public {
        turboAdmin._deployMarket(
            address(fei), 
            turboAdmin.ZERO_IRM(),
            "Turbo Fei", 
            "fFEI", 
            turboAdmin.CTOKEN_IMPL(), 
            new bytes(0), 
            0, 
            0, 
            0
        );
        turboAdmin.addCollateral(
            address(tribe), 
            "Turbo Tribe", 
            "fTRIBE",
            60e16,
            50_000_000e18
        );
        booster.setBoostCapForCollateral(tribe, 2_000_000e18); // 1M boost cap TRIBE

        address[] memory users = new address[](1);
        users[0] = feiDAOTimelock;

        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        turboAdmin._setWhitelistStatuses(users, enabled);
    }

    /// @notice requires TURBO_ADMIN_ROLE.
    function configureClerk(TurboClerk clerk) public {
        clerk.setDefaultFeePercentage(75e16); // 75% default revenue split
    }

    /// @notice requires TURBO_ADMIN_ROLE.
    function configureSavior(TurboSavior savior) public {
        savior.setMinDebtPercentageForSaving(80e16); // 80%
    }

    /// @notice requires ownership of Turbo Authority and default authority.
    function configureRoles(
        MultiRolesAuthority turboAuthority,
        MultiRolesAuthority defaultAuthority,
        TurboRouter router,
        TurboSavior savior,
        TurboGibber gibber
    ) public {
        defaultAuthority.setUserRole(address(router), ROUTER_ROLE, true);
        defaultAuthority.setUserRole(address(savior), SAVIOR_ROLE, true);
        turboAuthority.setUserRole(address(gibber), GIBBER_ROLE, true);
    }

    /// @notice requires TURBO_ADMIN_ROLE and ownership over Turbo Authority.
    function configureMaster(
        TurboMaster master, 
        TurboClerk clerk, 
        TurboBooster booster,
        TurboAdmin admin,
        MultiRolesAuthority defaultAuthority
    ) public {
        MultiRolesAuthority turboAuthority = MultiRolesAuthority(address(master.authority()));

        turboAuthority.setUserRole(address(master), TURBO_ADMIN_ROLE, true);
        turboAuthority.setUserRole(address(admin), TURBO_ADMIN_ROLE, true);
        turboAuthority.setUserRole(address(feiDAOTimelock), TURBO_ADMIN_ROLE, true);
        
        turboAuthority.setUserRole(address(feiDAOTimelock), GOVERN_ROLE, true);

        turboAuthority.setUserRole(address(guardian), GUARDIAN_ROLE, true);

        master.setClerk(clerk);
        master.setBooster(booster);
        master.setDefaultSafeAuthority(defaultAuthority);
    }

    function configureAdmin(MultiRolesAuthority turboAuthority, Comptroller pool, TurboAdmin admin) public {
        // temporarily assume ownership of pool (required by deployer)
        pool._acceptAdmin();
        
        // Temporarily grant the deployer the turbo admin role for setup
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, true);
        pool._setPendingAdmin(address(admin));
        admin._acceptAdmin();
    }
    
    function resetOwnership(
        MultiRolesAuthority defaultAuthority,
        MultiRolesAuthority turboAuthority,
        TimelockController turboTimelock,
        address admin
    ) public {
        if (admin != address(0)) {
            turboAuthority.setUserRole(admin, TURBO_ADMIN_ROLE, true);
        }
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, false);
        turboAuthority.setOwner(address(turboTimelock));
        defaultAuthority.setOwner(address(turboTimelock));
    }
}