/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;




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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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


// File @openzeppelin/contracts/security/[email protected]


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


// File contracts/interfaces/IBribeVault.sol




interface IBribeVault {
    function depositBribeERC20(
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address token,
        uint256 amount,
        address briber
    ) external;

    function getBribe(bytes32 bribeIdentifier)
        external
        view
        returns (address token, uint256 amount);

    function depositBribe(
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address briber
    ) external payable;
}


// File contracts/BribeBase.sol
// SPDX-License-Identifier: MIT





contract BribeBase is AccessControl, ReentrancyGuard {
    address public immutable BRIBE_VAULT;
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    // Used for generating the bribe and reward identifiers
    bytes32 public immutable PROTOCOL;

    // Arbitrary bytes mapped to deadlines
    mapping(bytes32 => uint256) public proposalDeadlines;

    // Voter addresses mapped to addresses which will claim rewards on their behalf
    mapping(address => address) public rewardForwarding;

    // Tracks whitelisted tokens
    mapping(address => uint256) public indexOfWhitelistedToken;
    address[] public allWhitelistedTokens;

    event GrantTeamRole(address teamMember);
    event RevokeTeamRole(address teamMember);
    event SetProposal(bytes32 indexed proposal, uint256 deadline);
    event DepositBribe(
        bytes32 indexed proposal,
        address indexed token,
        uint256 amount,
        bytes32 bribeIdentifier,
        bytes32 rewardIdentifier,
        address indexed briber
    );
    event SetRewardForwarding(address from, address to);
    event AddWhitelistTokens(address[] tokens);
    event RemoveWhitelistTokens(address[] tokens);

    constructor(address _BRIBE_VAULT, string memory _PROTOCOL) {
        require(_BRIBE_VAULT != address(0), "Invalid _BRIBE_VAULT");
        BRIBE_VAULT = _BRIBE_VAULT;

        require(bytes(_PROTOCOL).length != 0, "Invalid _PROTOCOL");
        PROTOCOL = keccak256(abi.encodePacked(_PROTOCOL));

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAuthorized() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(TEAM_ROLE, msg.sender),
            "Not authorized"
        );
        _;
    }

    /**
        @notice Grant the team role to an address
        @param  teamMember  address  Address to grant the teamMember role
     */
    function grantTeamRole(address teamMember)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(teamMember != address(0), "Invalid teamMember");
        _grantRole(TEAM_ROLE, teamMember);

        emit GrantTeamRole(teamMember);
    }

    /**
        @notice Revoke the team role from an address
        @param  teamMember  address  Address to revoke the teamMember role
     */
    function revokeTeamRole(address teamMember)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(hasRole(TEAM_ROLE, teamMember), "Invalid teamMember");
        _revokeRole(TEAM_ROLE, teamMember);

        emit RevokeTeamRole(teamMember);
    }

    /**
        @notice Return the list of currently whitelisted token addresses
     */
    function getWhitelistedTokens() external view returns (address[] memory) {
        return allWhitelistedTokens;
    }

    /**
        @notice Return whether the specified token is whitelisted
        @param  token  address Token address to be checked
     */
    function isWhitelistedToken(address token) public view returns (bool) {
        if (allWhitelistedTokens.length == 0) {
            return false;
        }

        return
            indexOfWhitelistedToken[token] != 0 ||
            allWhitelistedTokens[0] == token;
    }

    /**
        @notice Add whitelist tokens
        @param  tokens  address[]  Tokens to add to whitelist
     */
    function addWhitelistTokens(address[] calldata tokens)
        external
        onlyAuthorized
    {
        for (uint256 i; i < tokens.length; ++i) {
            require(tokens[i] != address(0), "Invalid token");
            require(tokens[i] != BRIBE_VAULT, "Cannot whitelist BRIBE_VAULT");
            require(
                !isWhitelistedToken(tokens[i]),
                "Token already whitelisted"
            );

            // Perform creation op for the unordered key set
            allWhitelistedTokens.push(tokens[i]);
            indexOfWhitelistedToken[tokens[i]] =
                allWhitelistedTokens.length -
                1;
        }

        emit AddWhitelistTokens(tokens);
    }

    /**
        @notice Remove whitelist tokens
        @param  tokens  address[]  Tokens to remove from whitelist
     */
    function removeWhitelistTokens(address[] calldata tokens)
        external
        onlyAuthorized
    {
        for (uint256 i; i < tokens.length; ++i) {
            require(isWhitelistedToken(tokens[i]), "Token not whitelisted");

            // Perform deletion op for the unordered key set
            // by swapping the affected row to the end/tail of the list
            uint256 index = indexOfWhitelistedToken[tokens[i]];
            address tail = allWhitelistedTokens[
                allWhitelistedTokens.length - 1
            ];

            allWhitelistedTokens[index] = tail;
            indexOfWhitelistedToken[tail] = index;

            delete indexOfWhitelistedToken[tokens[i]];
            allWhitelistedTokens.pop();
        }

        emit RemoveWhitelistTokens(tokens);
    }

    /**
        @notice Set a single proposal
        @param  proposal  bytes32  Proposal
        @param  deadline  uint256  Proposal deadline
     */
    function _setProposal(bytes32 proposal, uint256 deadline) internal {
        require(proposal != bytes32(0), "Invalid proposal");
        require(deadline > block.timestamp, "Deadline must be in the future");

        proposalDeadlines[proposal] = deadline;

        emit SetProposal(proposal, deadline);
    }

    /**
        @notice Generate the BribeVault identifier based on a scheme
        @param  proposal          bytes32  Proposal
        @param  proposalDeadline  uint256  Proposal deadline
        @param  token             address  Token
        @return identifier        bytes32  BribeVault identifier
     */
    function generateBribeVaultIdentifier(
        bytes32 proposal,
        uint256 proposalDeadline,
        address token
    ) public view returns (bytes32 identifier) {
        return
            keccak256(
                abi.encodePacked(PROTOCOL, proposal, proposalDeadline, token)
            );
    }

    /**
        @notice Generate the reward identifier based on a scheme
        @param  proposalDeadline  uint256  Proposal deadline
        @param  token             address  Token
        @return identifier        bytes32  Reward identifier
     */
    function generateRewardIdentifier(uint256 proposalDeadline, address token)
        public
        view
        returns (bytes32 identifier)
    {
        return keccak256(abi.encodePacked(PROTOCOL, proposalDeadline, token));
    }

    /**
        @notice Get bribe from BribeVault
        @param  proposal          bytes32  Proposal
        @param  proposalDeadline  uint256  Proposal deadline
        @param  token             address  Token
        @return bribeToken        address  Token address
        @return bribeAmount       address  Token amount
     */
    function getBribe(
        bytes32 proposal,
        uint256 proposalDeadline,
        address token
    ) external view returns (address bribeToken, uint256 bribeAmount) {
        return
            IBribeVault(BRIBE_VAULT).getBribe(
                generateBribeVaultIdentifier(proposal, proposalDeadline, token)
            );
    }

    /**
        @notice Deposit bribe for a proposal (ERC20 tokens only)
        @param  proposal  bytes32  Proposal
        @param  token     address  Token
        @param  amount    uint256  Token amount
     */
    function depositBribeERC20(
        bytes32 proposal,
        address token,
        uint256 amount
    ) external nonReentrant {
        uint256 proposalDeadline = proposalDeadlines[proposal];
        require(
            proposalDeadlines[proposal] > block.timestamp,
            "Proposal deadline has passed"
        );
        require(token != address(0), "Invalid token");
        require(isWhitelistedToken(token), "Token is not whitelisted");
        require(amount != 0, "Bribe amount must be greater than 0");

        bytes32 bribeIdentifier = generateBribeVaultIdentifier(
            proposal,
            proposalDeadline,
            token
        );
        bytes32 rewardIdentifier = generateRewardIdentifier(
            proposalDeadline,
            token
        );

        IBribeVault(BRIBE_VAULT).depositBribeERC20(
            bribeIdentifier,
            rewardIdentifier,
            token,
            amount,
            msg.sender
        );

        emit DepositBribe(
            proposal,
            token,
            amount,
            bribeIdentifier,
            rewardIdentifier,
            msg.sender
        );
    }

    /**
        @notice Deposit bribe for a proposal (native token only)
        @param  proposal  bytes32  Proposal
     */
    function depositBribe(bytes32 proposal) external payable nonReentrant {
        uint256 proposalDeadline = proposalDeadlines[proposal];
        require(
            proposalDeadlines[proposal] > block.timestamp,
            "Proposal deadline has passed"
        );
        require(msg.value != 0, "Bribe amount must be greater than 0");

        bytes32 bribeIdentifier = generateBribeVaultIdentifier(
            proposal,
            proposalDeadline,
            BRIBE_VAULT
        );
        bytes32 rewardIdentifier = generateRewardIdentifier(
            proposalDeadline,
            BRIBE_VAULT
        );

        // NOTE: Native token bribes have BRIBE_VAULT set as the address
        IBribeVault(BRIBE_VAULT).depositBribe{value: msg.value}(
            bribeIdentifier,
            rewardIdentifier,
            msg.sender
        );

        emit DepositBribe(
            proposal,
            BRIBE_VAULT,
            msg.value,
            bribeIdentifier,
            rewardIdentifier,
            msg.sender
        );
    }

    /**
        @notice Voters can opt in or out of reward-forwarding
        @notice Opt-in: A voter sets another address to forward rewards to
        @notice Opt-out: A voter sets their own address or the zero address
        @param  to  address  Account that rewards will be sent to
     */
    function setRewardForwarding(address to) external {
        rewardForwarding[msg.sender] = to;

        emit SetRewardForwarding(msg.sender, to);
    }
}


// File contracts/RibbonBoostBribe.sol


pragma solidity 0.8.12;

contract RibbonBoostBribe is BribeBase {
    // Limit the number of active deadline per proposal creator, replacing expired one when needed
    uint256 public maxDeadlineCount = 3;
    // Limit the duration for proposals (in epochs/weeks)
    uint256 public maxDuration = 16;
    mapping(address => uint256[]) public bribeDeadlines;

    event SetMaxDeadlineCount(uint256 count);
    event SetMaxDuration(uint256 duration);
    event AddBoostProposal(
        address indexed creator,
        address indexed receiver,
        uint256 deadline
    );

    constructor(address _BRIBE_VAULT)
        BribeBase(_BRIBE_VAULT, "RIBBON_FINANCE_BOOST")
    {}

    /**
        @notice Add or replace deadline record when available
        @param  creator   address  Proposal creator
        @param  deadline  uint56   Deadline
     */
    function _addDeadline(address creator, uint256 deadline) internal {
        uint256[] storage deadlines = bribeDeadlines[creator];
        uint256 len = deadlines.length;

        if (len < maxDeadlineCount) {
            deadlines.push(deadline);
        } else {
            uint256 index = len;
            for (uint256 i; i < len; ++i) {
                if (deadlines[i] <= block.timestamp) {
                    index = i;
                    break;
                }
            }

            require(index < len, "Bribe request limit reached");

            deadlines[index] = deadline;
        }
    }

    /**
        @notice Set the maximum deadline count per creator
        @param  _count  uint256  Limit count
     */
    function setMaxDeadlineCount(uint256 _count)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_count > maxDeadlineCount, "Invalid count");
        maxDeadlineCount = _count;

        emit SetMaxDeadlineCount(_count);
    }

    /**
        @notice Set the maximum proposal duration (in weeks/epochs)
        @param  _duration  uint256  Duration limit
     */
    function setMaxDuration(uint256 _duration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_duration > 1, "Invalid duration");
        maxDuration = _duration;

        emit SetMaxDuration(_duration);
    }

    /**
        @notice Add new boost bribe proposal
        @param  receiver  address  Boost receiver
        @param  duration  uint256  Duration before deadline in epochs (weeks)
     */
    function addBoostProposal(address receiver, uint256 duration)
        external
        nonReentrant
    {
        require(receiver != address(0), "Invalid receiver");

        // Duration must be between 1-[maxDuration] weeks, starting from the next epoch
        require(duration > 0 && duration <= maxDuration, "Invalid duration");
        uint256 nextEpoch = (block.timestamp / 604800) * 604800 + 604800;
        uint256 deadline = nextEpoch + (604800 * duration);

        // Add a new deadline record when possible
        // Else, fetch the first found expired deadline and replace it with the new one
        _addDeadline(msg.sender, deadline);

        // To allow multiple deadlines per receiver
        // we use both receiver and deadline for the proposal identifier
        _setProposal(keccak256(abi.encodePacked(receiver, deadline)), deadline);

        // Required for the filtering off-chain
        // otherwise we won't know the list of receivers to generate the proposal identifiers
        emit AddBoostProposal(msg.sender, receiver, deadline);
    }
}