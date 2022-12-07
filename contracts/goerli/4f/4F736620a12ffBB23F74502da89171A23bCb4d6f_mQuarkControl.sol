// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
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
pragma solidity 0.8.17;

library Order {
  struct SellOrder {
    address payable seller;
    uint256 fromTokenId;
    uint256 projectId;
    string slotUri;
    uint256 sellPrice;
  }

  struct BuyOrder {
    address buyer;
    address seller;
    uint256 fromTokenId;
    uint256 toTokenId;
    uint256 projectId;
    string slotUri;
    uint256 buyPrice;
  }
}

interface ImQuark {
  function setRoyalty(address receiver, uint256 royaltyPercentage) external;

  function createTemplate(string calldata uri) external;

  function createBatchTemplate(string[] calldata uris) external;

  //Single minting with no metadata
  function mint(address to, uint256 projectId, uint256 templateId, uint256 collectionId, uint256 variationId) external;

   function mintWithPreURI(
    address signer,
    address to,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    bytes calldata signature,
    string calldata uri
  ) external;

  //Multiple Tokens with no metadata
  function mintBatch(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    uint256[] calldata variationIds
  ) external;

  //Multiple Token with single metadata slot
  function mintBatchWithURISlot(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    uint256[] calldata variationIds,
    string calldata projectDefaultUri
  ) external;

  //Single Token with multiple Metadata slots
  function mintWithURISlots(
    address to,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256[] calldata projectIds,
    string[] calldata projectDefaultUris
  ) external;

  //Single Token => Single Metaverse
  function addURISlotToNFT(
    address owner,
    uint256 tokenId,
    uint256 projectId,
    string calldata projectDefaultUri
  ) external;

  //Single Token => Multiple Metaverses
  function addBatchURISlotsToNFT(
    address owner,
    uint256 tokenId,
    uint256[] calldata projectIds,
    string[] calldata projectDefaultUris
  ) external;

  //Multiple Tokens => Single Metaverse
  function addBatchURISlotToNFTs(
    address owner,
    uint256[] calldata tokenIds,
    uint256 projectId,
    string calldata projectMetadataTemplate
  ) external;

  function updateURISlot(
    address owner,
    bytes calldata signature,
    address projectWallet,
    uint256 projectId,
    uint256 tokenId,
    string calldata newURI
  ) external;

  function resetMetaverseURI(uint256 tokenId, uint256 projectId, string calldata projectTemplate) external;

  function createCollection(
    uint256 projectId,
    address signer,
    uint256 templateId_,
    uint16 totalSupply,
    bytes[] calldata signatures,
    string[] calldata uris
  ) external;

  function createBatchCollection(
    uint256 projectId,
    address _admin,
    uint256[] calldata _templateIds,
    uint16[] calldata amounts,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external;

  function createBatchCollectionWithoutURIs(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint16[] calldata totalSupplies
  ) external;

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function transferTokenProjectURI(
    Order.SellOrder calldata seller,
    Order.BuyOrder calldata buyer,
    bytes memory sellerSignature,
    bytes memory buyerSignature,
    string calldata _projectDefaultUri
  ) external;

  function getCreatedBaseIds() external view returns (uint256[] memory);

  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.17;

import "./IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    // mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    mapping (address => EnumerableSet.UintSet) private _ownerTokens;
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

    // /**
    //  * @dev See {IERC721-balanceOf}.
    //  */
    // function balanceOf(address owner) public view virtual override returns (uint256) {
    //     require(owner != address(0), "ERC721: address zero is not a valid owner");
    //     // return _balances[owner];
    // }

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

    function ownerTokens(address owner) public view returns(uint256[] memory) {
        return _ownerTokens[owner].values();
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
        // require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), to, tokenId);

        // _balances[to] += 1;
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
    // function _burn(uint256 tokenId) internal virtual {
    //     address owner = ERC721.ownerOf(tokenId);

    //     // _beforeTokenTransfer(owner, address(0), tokenId);

    //     // Clear approvals
    //     _approve(address(0), tokenId);

    //     // _balances[owner] -= 1;
    //     delete _owners[tokenId];

    //     emit Transfer(owner, address(0), tokenId);

    //     // _afterTokenTransfer(owner, address(0), tokenId);
    // }

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

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // _balances[from] -= 1;
        // _balances[to] += 1;
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
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual {}

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
    ) internal virtual {
        if(from != address(0)) {
            _ownerTokens[to].add(tokenId);
            _ownerTokens[from].remove(tokenId);
        }
        else  _ownerTokens[to].add(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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

    // /**
    //  * @dev Returns the number of tokens in ``owner``'s account.
    //  */
    // function balanceOf(address owner) external view returns (uint256 balance);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity 0.8.17;

import "./IERC721.sol";

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
pragma solidity ^0.8.7;

library EnumerableStringSet {
    
  struct StringSet {
    // Storage of set values
    string[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(string => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(StringSet storage set, string memory value) internal returns (bool) {
    if (!contains(set, value)) {
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
  function remove(StringSet storage set, string memory value) internal returns (bool) {
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
        string memory lastvalue = set._values[lastIndex];

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
  function contains(StringSet storage set, string memory value) internal view returns (bool) {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(StringSet storage set) internal view returns (uint256) {
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
  function at(StringSet storage set, uint256 index) internal view returns (string memory) {
    return set._values[index];
  }

  function values(StringSet storage set) internal view returns (string[] memory) {
    return set._values;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../lib/ERC721.sol";
import "../lib/StringSet.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title mQuark
/// @dev mQuark is an ERC721-compliant non-fungible token (NFT) contract for the mQuark protocol.
/// It is called by the mQuark Control contract to create templates and manage NFTs.
contract mQuark is ERC721, IERC2981 {
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableStringSet for EnumerableStringSet.StringSet;

  //* ==================================================================================================
  //*                                              Events
  //* ===================================================================================================

  // Event for when categories are set for a template
  event CategoriesSet(string category, uint256[] templateIds);
  // Event for when a category is removed from a template
  event CategoryRemoved(string category, uint256 templateId);
  // Event for when a collection is created
  event CollectionCreated(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint16 totalSupply,
    uint256 minId,
    uint256 maxId,
    // string collectionUri
    // string[] collectionUri
    string[] collectionUris
  );
  // Event for when an NFT is minted
  event NFTMinted(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256 tokenId,
    string uri,
    address to
  );
  event NFTMintedWithPreUri(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    string uri,
    uint256 tokenId,
    address to
  );
  // Event for when a URI slot is added for a project for a token
  event ProjectURISlotAdded(uint256 tokenId, uint256 projectId, string uri);
  // Event for when a URI slot is reset for a project for a token
  event ProjectSlotURIReset(uint256 tokenId, uint256 projectId);
  // Event for when a URI is updated for a project for a token
  event ProjectURIUpdated(bytes signature, uint256 projectId, uint256 tokenId, string updatedUri);
  // Event for when the royalty rate is set
  event RoyaltySet(address reciever, uint256 royaltyAmount);
  // Event for when a template is created
  event TemplateCreated(uint256 templateId, string uri);

  //* ===================================================================================================
  //*                                          STATE VARIABLES
  //* ===================================================================================================

  //* ============================ STRUCTS ==============================================================

  struct Collection {
    // the id of the project that the collection belongs to. This id is assigned by the contract.
    uint256 projectId;
    // the id of the template that the collection inherits from.
    uint256 templateId;
    // the created collection's id for a template id
    uint256 collectionId;
    // the total supply of the collection
    uint256 totalSupply;
    // the minimum token id that can be minted from the collection
    uint256 minTokenId;
    // the maximum token id that can be minted from the collection
    uint256 maxTokenId;
    // the number of minted tokens from the collection
    uint256 mintCount;
    // the URI of the collection (minted tokens inherit this URI)
    // string collectionURI;
    string[] collectionURIs;
  }

  struct SellOrder {
    // the order maker (the person selling the URI)
    address payable seller;
    // the token id whose project URI will be sold
    uint256 fromTokenId;
    // the project's id whose owner is selling the URI
    uint256 projectId;
    // the URI that will be sold
    string slotUri;
    // the price required for the URI
    uint256 sellPrice;
  }

  struct BuyOrder {
    // the order executer (the person buying the URI)
    address buyer;
    // the order maker (the person selling the URI)
    address seller;
    // the token id whose project URI will be bought
    uint256 fromTokenId;
    // the token id whose project URI will be updated with the sold URI
    uint256 toTokenId;
    // the project's id whose owner is selling the URI
    uint256 projectId;
    // the URI that will be bought
    string slotUri;
    // the price required for the URI
    uint256 buyPrice;
  }

  /// @dev Stores the ids of created templates
  EnumerableSet.UintSet private templateIds;

  /// @dev The admin of the contract, has access to some functions
  address public admin;

  /// @dev The mQuark Control address, used to check if the caller is mQuark Control when modifying functions
  address public immutable mQuarkControl;

  /// @dev The address of the royalty receiver, used when a second-hand sale happens on a marketplace
  address public royaltyReceiver;

  /// @dev The percentage of the sale price that goes to the royalty receiver
  uint256 public royaltyPercentage;

  /// @dev Keeps track of the last created template id
  uint256 public templateIdCounter;

  /// @dev Used during collection creation to determine which token id can be assigned as the
  /// minimum-mintable-first token id. After the last collection is created, its maximum-mintable-last
  /// token id is assigned to this variable.
  uint256 public globalTokenIdVariable;

  //* =========================== MAPPINGS ==============================================================

  /// @dev Mapping from a 'token id' and 'project id' to a 'project slot URI'
  mapping(uint256 => mapping(uint256 => string)) private _tokenProjectURIs;

  /// @dev Mapping from a 'template id' to a 'template URI'
  mapping(uint256 => string) private _templateURIs;

  /// @dev Mapping from a 'token id' to a 'token URI'
  mapping(uint256 => string) private _tokenIdURIs;

  /// @dev Mapping from a 'signature' to a 'boolean'
  /// @notice Prevents the same signature from being used twice
  mapping(bytes => bool) private _inoperativeSignatures;

  /// @dev Mapping from a 'project id' and 'template id' to a 'collection id'
  mapping(uint256 => mapping(uint256 => uint256)) private _projectCollectionIds;

  /// @dev Mapping from a 'template id', 'project id', and 'collection id' to a 'collection'
  mapping(uint256 => mapping(uint256 => mapping(uint256 => Collection))) private _projectCollections;

  /// @dev Mapping from a 'category' to a set of 'template ids'
  mapping(string => EnumerableSet.UintSet) private categoryTemplates;

  /// @dev Mapping from a 'template id' to a set of 'categories'
  mapping(uint256 => EnumerableStringSet.StringSet) private templateCategories;

  //* ======================== MODIFIERS ================================================================

  /// @dev Prevents modified functions from being called by anyone other than the admin.
  modifier onlyAdmin() {
    _onlyAdmin();
    _;
  }

  /// @dev Prevents modified functions from being called other than the mQuark Control contract.
  modifier onlymQuarkControl() {
    _onlymQuarkControl();
    _;
  }

  //* ==================================================================================================
  //*                                           CONSTRUCTOR
  //* ==================================================================================================

  /// @notice Initializes the contract by setting the deployer as the 'admin' and the mQuark Control address.
  /// @param mQuarkControl_ The deployed mQuark Control contract address.
  constructor(address mQuarkControl_) ERC721("mQuark", "QRK") {
    admin = msg.sender;
    mQuarkControl = mQuarkControl_;
  }

  //* ==================================================================================================
  //*                                         EXTERNAL Functions
  //* ==================================================================================================

  //* ======================= TEMPLATE Creation ========================================================

  /// @notice Creates a new template with the given URI, which will be inherited by collections.
  /// Only the contract owner or an authorized admin can call this function.
  /// @param uri The metadata URI that will represent the template.
  function createTemplate(string calldata uri) external onlyAdmin {
    // Generate a unique template ID
    uint256 _templateId = ++templateIdCounter;

    // Store the URI for the new template
    _templateURIs[_templateId] = uri;

    // Add the template ID to the list of template IDs
    templateIds.add(_templateId);

    emit TemplateCreated(_templateId, uri);
  }

  /// @notice Creates multiple templates with the given URIs, which will be inherited by collections.
  /// Only the contract owner or an authorized admin can call this function.
  /// @param uris The metadata URIs that will represent the templates.
  function createBatchTemplate(string[] calldata uris) external onlyAdmin {
    // Check that the number of URIs is valid
    uint256 _urisLength = uris.length;
    require(_urisLength < 256, "exceeds limit");

    // Initialize the template ID counter
    uint256 _templateId = templateIdCounter;

    // Loop through the URIs and create templates for each one
    for (uint8 i = 0; i < _urisLength; ) {
      // Increment the template ID to generate a unique ID
      ++_templateId;

      // Store the URI for the new template
      _templateURIs[_templateId] = uris[i];

      // Add the template ID to the list of template IDs
      templateIds.add(_templateId);

      emit TemplateCreated(_templateId, uris[i]);

      // Increment the loop counter
      unchecked {
        ++i;
      }
    }

    // Update the template ID counter
    templateIdCounter = _templateId;
  }

  //* ===================================================================================================

  //* ======================MINTING Functions============================================================

  /// @notice Performs a single NFT mint without any slots.
  /// @param to The address of the token receiver.
  /// @param projectId The collection owner's project ID.
  /// @param templateId The collection's inherited template's ID.
  /// @param collectionId The collection ID for its template.
  function mint(
    address to,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external onlymQuarkControl {
    // Ensure that a valid template ID is provided
    require(templateId != 0, "invalid template id");

    // Retrieve the collection data from storage
    Collection memory _tempData = _projectCollections[templateId][projectId][collectionId];

    require(_tempData.collectionURIs.length > variationId, "invalid variation");

    // Ensure that the token mint exists
    require(_tempData.minTokenId != 0, "unexisting token mint");

    // Ensure that there is enough supply to mint a new token
    require(_tempData.mintCount <= _tempData.totalSupply, "not enough supply");

    // Calculate the ID of the new token
    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;

    // Perform the mint operation
    _mint(to, _tokenId);

    // Store the token's URI in storage
    // _tokenIdURIs[_tokenId] = _tempData.collectionURI;
    _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationId];

    // Increment the mint count for the collection
    ++_projectCollections[templateId][projectId][collectionId].mintCount;

    emit NFTMinted(projectId, templateId, collectionId, variationId, _tokenId, _tempData.collectionURIs[variationId], to);
  }

  /// @notice Performs a single NFT mint without any slots.
  /// @param to The address of the token receiver.
  /// @param projectId The collection owner's project ID.
  /// @param templateId The collection's inherited template's ID.
  /// @param collectionId The collection ID for its template.
  function mintWithPreURI(
    address signer,
    address to,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    bytes calldata signature,
    string calldata uri
  ) external onlymQuarkControl {
    // Ensure that a valid template ID is provided
    require(templateId != 0, "invalid template id");

    bool isVerified = _verifyCollectionURIEditSignature(signature, signer, projectId, templateId, collectionId, uri);

    if (isVerified) {
      // Retrieve the collection data from storage
      Collection memory _tempData = _projectCollections[templateId][projectId][collectionId];

      // Ensure that the token mint exists
      require(_tempData.minTokenId != 0, "unexisting token mint");

      // Ensure that there is enough supply to mint a new token
      require(_tempData.mintCount <= _tempData.totalSupply, "not enough supply");

      // Calculate the ID of the new token
      uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;

      // Perform the mint operation
      _mint(to, _tokenId);

      // Store the token's URI in storage
      _tokenIdURIs[_tokenId] = uri;

      // Increment the mint count for the collection
      ++_projectCollections[templateId][projectId][collectionId].mintCount;

      emit NFTMintedWithPreUri(projectId, templateId, collectionId, uri, _tokenId, to);
    } else revert("verification failed");
  }

  /// @notice Performs a batch mint operation without any URI slots.
  /// @param to The address of the token receiver.
  /// @param projectId The collection owner's project ID.
  /// @param _templateIds The collection's inherited template's ID.
  /// @param collectionIds The collection ID for its template.
  /// @param amounts The number of mint amounts from each collection.
  function mintBatch(
    address to,
    uint256 projectId,
    uint256[] calldata _templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    uint256[] calldata variationIds
  ) external onlymQuarkControl {
    // Check that the number of template IDs and collection IDs match
    require(_templateIds.length == collectionIds.length, "collection mismatch");

    // Check that the number of template IDs and amounts match
    require(_templateIds.length == amounts.length, "amount mismatch");

    // Initialize variables for storing temporary data
    Collection memory _tempData;
    uint256 _tokenId;

    // Loop through the template IDs and mint tokens for each one
    uint8 _templateIdsLength = uint8(_templateIds.length);
    for (uint8 i = 0; i < _templateIdsLength; ) {
      // Check that the amount of tokens to mint is valid
      require(amounts[i] <= 10, "exceeds limit");
      uint8 _mintCount = amounts[i];

      // Ensure that the template ID and mint amount are valid
      require(_templateIds[i] != 0 && _mintCount != 0, "invalid id/amount");

      // Retrieve the collection data from storage
      _tempData = _projectCollections[_templateIds[i]][projectId][collectionIds[i]];

      require(_tempData.collectionURIs.length > variationIds[i], "invalid variation");

      // Ensure that the token mint exists
      require(_tempData.minTokenId != 0, "unexisting token mint");

      // Ensure that there is enough supply to mint the requested amount of tokens
      require((_tempData.mintCount + _mintCount) <= (_tempData.totalSupply), "not enough supply");
      // Loop through the mint count and mint tokens for the given template and collection IDs
      for (uint8 ii = 0; ii < _mintCount; ) {
        // Calculate the token ID
        _tokenId = _tempData.minTokenId + _tempData.mintCount;

        // Mint the token
        _mint(to, _tokenId);

        // Increment the mint count for the collection data
        ++_tempData.mintCount;

        // Store the URI of the token in the `_tokenIdURIs` mapping
        _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationIds[i]];

        emit NFTMinted(projectId, _templateIds[i], collectionIds[i], variationIds[i], _tokenId,_tempData.collectionURIs[variationIds[i]], to);

        // Increment the inner loop counter
        unchecked {
          ++ii;
        }
      }
      // Update the mint count for the collection data in storage
      _projectCollections[_templateIds[i]][projectId][collectionIds[i]].mintCount += _mintCount;

      // Increment the outer loop counter
      unchecked {
        ++i;
      }
    }
  }

  /// @dev Performs batch mint operation with single given project URI slot for every token
  /// @notice Reverts if the number of given templates are more than 256
  /// @param to token receiver
  /// @param projectId collection owner's project id
  /// @param templateIds_ collection's inherited template's ids
  /// @param collectionIds collection ids for its template
  /// @param amounts the number of mint amounts from each collection
  /// @param projectDefaultUri project slot will be pre-initialized with the project's default slot URI
  function mintBatchWithURISlot(
    address to,
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    uint256[] calldata variationIds,
    string calldata projectDefaultUri
  ) external onlymQuarkControl {
    // Check that the number of items to mint is valid
    require(templateIds_.length < 256, "exceeds limit");

    // Check that the number of template IDs and collection IDs match
    require(templateIds_.length == collectionIds.length, "template id/collection mismatch");

    // Check that the number of amounts and collection IDs match
    require(amounts.length == collectionIds.length, "amount mismatch");

    // Initialize variables for storing temporary data
    Collection memory _tempData;
    uint256 _tokenId;

    // Loop through the template IDs and mint tokens for each one
    uint8 templateIds_Length = uint8(templateIds_.length);
    for (uint8 i = 0; i < templateIds_Length; ) {
      // Ensure that the template ID and collection ID are valid
      require(templateIds_[i] != 0 && collectionIds[i] != 0, "invalid id/index");

      // Retrieve the collection data from storage
      _tempData = _projectCollections[templateIds_[i]][projectId][collectionIds[i]];

      require(_tempData.collectionURIs.length > variationIds[i], "invalid variation");

      // Ensure that the token mint exists
      require(_tempData.minTokenId != 0, "unexisting token");

      // Ensure that there is enough supply to mint the requested amount of tokens
      require((_tempData.mintCount) <= (_tempData.totalSupply), "not enough supply");

      // Calculate the initial token ID for the current mint operation
      _tokenId = _tempData.minTokenId + _tempData.mintCount;

      // Loop through the mint count and mint tokens for the given template and collection IDs
      uint8 _mintAmounts = amounts[i];
      _tokenId = _tempData.minTokenId + _tempData.mintCount;
      for (uint8 ii = 0; ii < _mintAmounts; ) {
        // Mint the token and add its URI and project URI slot data to storage
        _mint(to, _tokenId);
        _tokenProjectURIs[_tokenId][projectId] = projectDefaultUri;
        _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationIds[i]];

        // Increment the token ID and mint count
        ++_tokenId;
        ++_tempData.mintCount;
        emit NFTMinted(projectId, templateIds_[i], collectionIds[i], variationIds[i], _tokenId, _tempData.collectionURIs[variationIds[i]], to);
        emit ProjectURISlotAdded(_tokenId, projectId, projectDefaultUri);

        // Increment the inner loop counter
        unchecked {
          ++ii;
        }
      }

      // Update the mint count for the collection data in storage
      _projectCollections[templateIds_[i]][projectId][collectionIds[i]].mintCount += _mintAmounts;

      // Increment the outer loop counter
      unchecked {
        ++i;
      }
    }
  }

  /// Mints a single non-fungible token (NFT) with multiple metadata slots.
  /// Initializes the metadata slots with the given project's URI.
  /// @notice Reverts if the number of given templates is more than 256.
  /// @param to The address of the token receiver.
  /// @param templateId The ID of the collection's inherited template.
  /// @param collectionId The ID of the collection for its template.
  /// @param projectIds The IDs of the collection owner's project.
  /// @param projectSlotDefaultUris The project slot will be pre-initialized with the project's default slot URI.
  function mintWithURISlots(
    address to,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) external onlymQuarkControl {
    // Ensure that a valid template ID is provided
    require(templateId != 0, "invalid template id.");

    // Retrieve the collection data from storage
    Collection memory _tempData = _projectCollections[templateId][projectIds[0]][collectionId];

    require(_tempData.collectionURIs.length > variationId, "invalid variation");

    // Ensure that there is enough supply to mint a new token
    require(_tempData.mintCount <= _tempData.totalSupply, "not enough supply.");

    // Calculate the ID of the new token
    uint256 _tokenId = _tempData.minTokenId + _tempData.mintCount;

    // Perform the mint operation
    _mint(to, _tokenId);

    // Store the token's URI in storage
    _tokenIdURIs[_tokenId] = _tempData.collectionURIs[variationId];

    // Increment the mint count for the collection
    ++_projectCollections[templateId][projectIds[0]][collectionId].mintCount;

    // Initialize the metadata slots for the new token
    addBatchURISlotsToNFT(to, _tokenId, projectIds, projectSlotDefaultUris);

    emit NFTMinted(projectIds[0], templateId, collectionId, variationId, _tokenId,_tempData.collectionURIs[variationId], to);
  }

  //* =========================== URI SLOT Functions ==========================================

  /// Adds a single URI slot to a single non-fungible token (NFT).
  /// Initializes the added slot with the given project's default URI.
  /// @notice Reverts if the number of given projects is more than 256.
  /// @notice The added slot's initial state will be pre-filled with the project's default URI.
  /// @param owner The owner of the token.
  /// @param tokenId The ID of the token to which the slot will be added.
  /// @param projectId The ID of the slot's project.
  /// @param projectSlotDefaultUri The project's default URI that will be set to the added slot.
  function addURISlotToNFT(
    address owner,
    uint256 tokenId,
    uint256 projectId,
    string calldata projectSlotDefaultUri
  ) public onlymQuarkControl {
    // Ensures that the given address is the owner of the token
    require(ownerOf(tokenId) == owner, "you are not the owner");
    // Ensures that the project ID is greater than zero
    require(projectId > 0, "project id zero");
    // Ensures that the project URI slot is not already added
    require(_compareStrings(_tokenProjectURIs[tokenId][projectId], ""), "added slot");
    // Adds the project URI slot
    _tokenProjectURIs[tokenId][projectId] = projectSlotDefaultUri;

    emit ProjectURISlotAdded(tokenId, projectId, projectSlotDefaultUri);
  }

  /// Adds multiple URI slots to a single token in a batch operation.
  /// @notice Reverts if the number of projects is more than 256.
  /// @notice Slots' initial state will be pre-filled with the given default URI values.
  /// @param owner The owner of the token.
  /// @param tokenId The ID of the token to which the slots will be added.
  /// @param projectIds An array of IDs for the slots that will be added.
  /// @param projectSlotDefaultUris An array of default URI values for the added
  function addBatchURISlotsToNFT(
    address owner,
    uint256 tokenId,
    uint256[] calldata projectIds,
    string[] calldata projectSlotDefaultUris
  ) public onlymQuarkControl {
    // Calculate the number of projects by getting the length of the `projectIds` array.
    uint256 projectCount = projectIds.length;

    // Check that the number of projects is less than 256, and revert if this is not the case.
    require(projectCount < 256, "exceeds limit");

    // Iterate over the `projectIds` and `projectSlotDefaultUris` arrays.
    // For each item in the arrays, call the `addURISlotToNFT` function.
    for (uint256 i = 0; i < projectCount; ) {
      addURISlotToNFT(owner, tokenId, projectIds[i], projectSlotDefaultUris[i]);

      // Increment the counter variable `i` by 1.
      unchecked {
        ++i;
      }
    }
  }

  /// Adds the same URI slot to multiple tokens in a batch operation.
  /// @notice Reverts if the number of tokens is more than 20.
  /// @notice Slots' initial state will be pre-filled with the given default URI value.
  /// @param owner The owner of the tokens.
  /// @param tokenIds An array of IDs for the tokens to which the slot will be added.
  /// @param projectId The ID of the project for the slot that will be added.
  /// @param projectDefaultUris The default URI value for the added slot.
  function addBatchURISlotToNFTs(
    address owner,
    uint256[] calldata tokenIds,
    uint256 projectId,
    string calldata projectDefaultUris
  ) public onlymQuarkControl {
    // Calculate the number of tokens by getting the length of the `tokenIds` array.
    uint256 mintingLength = tokenIds.length;

    // Check that the number of tokens is less than or equal to 20, and revert if this is not the case.
    require(mintingLength <= 20, "exceeds limit");

    // Iterate over the `tokenIds` array.
    // For each item in the array, call the `addURISlotToNFT` function with the given `projectId` and `projectDefaultUris` values.
    for (uint8 i = 0; i < mintingLength; ) {
      addURISlotToNFT(owner, tokenIds[i], projectId, projectDefaultUris);

      // Increment the counter variable `i` by 1.
      unchecked {
        ++i;
      }
    }
  }

  /// Updates the URI slot of a single token.
  /// @notice The project must sign the new URI with its private key.
  /// @param owner The address of the owner of the token.
  /// @param signature The signed data for the updated URI, using the project's private key.
  /// @param project The address of the project.
  /// @param projectId The ID of the project.
  /// @param tokenId The ID of the token.
  /// @param updatedUri The updated, signed URI value.
  function updateURISlot(
    address owner,
    bytes calldata signature,
    address project,
    uint256 projectId,
    uint256 tokenId,
    string calldata updatedUri
  ) external onlymQuarkControl {
    // Check that the owner of the token matches the given `owner` address.
    require(ownerOf(tokenId) == owner, "you are not the owner");

    // Check that the given URI slot exists.
    require(!_compareStrings(_tokenProjectURIs[tokenId][projectId], ""), "uri slot unexist");

    // Verify the signed data for the updated URI using the `_verifyUpdateTokenURISignature` function.
    bool isVerified = _verifyUpdateTokenURISignature(signature, project, projectId, tokenId, updatedUri);

    // If the signed data is verified, update the URI slot and emit the `ProjectURIUpdated` event.
    // Otherwise, revert the transaction.
    if (isVerified) {
      _inoperativeSignatures[signature] = true;
      _tokenProjectURIs[tokenId][projectId] = updatedUri;

      emit ProjectURIUpdated(signature, projectId, tokenId, updatedUri);
    } else {
      revert("verification failed");
    }
  }

  /// Transfers the URI slot of a single token to another token's URI slot for the same project.
  /// Also resets the URI slot of the sold token to the default URI value for the project.
  /// @notice Reverts if slots are not added for both tokens.
  /// @notice Reverts if the URI to be sold doesn't match the current URI of the token.
  /// @notice Reverts if one of the tokens is not owned by the seller or buyer.
  /// @param seller A struct containing details about the sell order.
  /// @param buyer A struct containing details about the buy order.
  /// @param sellerSignature The signed data for the sell order, using the seller's private key.
  /// @param buyerSignature The signed data for the buy order, using the buyer's private key.
  /// @param _projectDefaultUri The default URI value for the project.
  function transferTokenProjectURI(
    SellOrder calldata seller,
    BuyOrder calldata buyer,
    bytes memory sellerSignature,
    bytes memory buyerSignature,
    string calldata _projectDefaultUri
  ) external onlymQuarkControl {
    // Check that the URI values for the sell and buy orders match.
    require(_compareStrings(seller.slotUri, buyer.slotUri), "uri mismatch");

    // Check that the seller is the owner of the token specified in the sell order.
    require(ownerOf(seller.fromTokenId) == seller.seller, "seller is not owner");

    // Check that the buyer is the owner of the token specified in the buy order.
    require(ownerOf(buyer.toTokenId) == buyer.buyer, "buyer is not owner");

    // Check that the URI value for the token specified in the sell order matches the value in the sell order.
    require(
      _compareStrings(_tokenProjectURIs[seller.fromTokenId][seller.projectId], seller.slotUri),
      "uri mismatch in contract"
    );

    // Calculate the message hash for the sell order using the `keccak256` function.
    bytes32 _messageHash = keccak256(
      abi.encode(seller.seller, seller.fromTokenId, seller.projectId, seller.slotUri, seller.sellPrice)
    );

    // Get the signer of the message hash for the sell order using the `_getHashSigner` function.
    address _signer = _getHashSigner(_messageHash, sellerSignature);

    // Check that the signer of the message hash matches the seller's address.
    require(seller.seller == _signer, "seller failed");

    // Calculate the message hash for the buy order using the `keccak256` function.
    _messageHash = keccak256(
      abi.encode(
        buyer.buyer,
        buyer.seller,
        buyer.fromTokenId,
        buyer.toTokenId,
        buyer.projectId,
        buyer.slotUri,
        buyer.buyPrice
      )
    );

    // Get the signer of the message hash for the buy order using the `_getHashSigner` function.
    _signer = _getHashSigner(_messageHash, buyerSignature);

    // Check that the signer of the message hash matches the buyer's address.
    require(buyer.buyer == _signer, "buyer failed");

    // Update the URI slot of the token specified in the buy order with the URI value from the sell order.
    _tokenProjectURIs[buyer.toTokenId][buyer.projectId] = seller.slotUri;

    // Update the URI slot of the token specified in the sell order with the default URI value for the project.
    _tokenProjectURIs[seller.fromTokenId][seller.projectId] = _projectDefaultUri;
  }

  //* ================================================================================================

  //* ==================================COLLECTION Creation===========================================

  /// Creates a new collection based on a selected template, with the given total supply,
  /// and assigns it to the registered project with the specified ID. Also, accepts variations of a collection.
  /// Every variation has to have a unique URI and every URI has to be signed.
  /// Reverts if the given signer and signature do not match or if the signature is not valid.
  /// @param projectId The ID of the registered project that will own the collection.
  /// @param signer The address of the signer that signed the parameters used to create the signature.
  /// @param templateId_ The ID of the selected template to use for creating the collection.
  /// @param totalSupply The total supply of tokens for the new collection.
  /// @param signatures The signature created using the given parameters and signed by the signer.
  /// @param uris The URI that will be assigned to the collection.
  function createCollection(
    uint256 projectId,
    address signer,
    uint256 templateId_,
    uint16 totalSupply,
    bytes[] calldata signatures,
    // string calldata uri
    string[] calldata uris
  ) external onlymQuarkControl {
    // Calculate the last used token ID and the ID of the new collection.
    uint256 _lastUsedTokenId = globalTokenIdVariable;
    uint256 _collectionId;
    _collectionId = ++_projectCollectionIds[projectId][templateId_];

    // Check that the signature is valid using the `_verifyCollectionURIEditSignature` function.
    // bool isVerified = _verifyCollectionURIEditSignature(signature, signer, projectId, templateId_, _collectionId, uri);
    for (uint256 i = 0; i < signatures.length; ) {
      bool isVerified = _verifyCollectionURIEditSignature(
        signatures[i],
        signer,
        projectId,
        templateId_,
        _collectionId,
        uris[i]
      );

      if (isVerified) {
        // Create a temporary Collection struct to hold the data for the new collection.
        Collection memory _tempData = _projectCollections[templateId_][projectId][_collectionId];

        // Update the inoperative signatures mapping and the temporary Collection struct with the specified values.
        _inoperativeSignatures[signatures[i]] = true;
        _tempData = Collection(
          projectId,
          templateId_,
          _collectionId,
          totalSupply,
          (_lastUsedTokenId + 1),
          _lastUsedTokenId + totalSupply,
          0,
          uris
        );

        // Update the last used token ID and the collection data in the `_projectCollections` mapping.
        _lastUsedTokenId += totalSupply;
        _projectCollections[templateId_][projectId][_collectionId] = _tempData;

        emit CollectionCreated(
          projectId,
          templateId_,
          _collectionId,
          totalSupply,
          _tempData.minTokenId,
          _tempData.maxTokenId,
          uris
        );
      } else {
        // If the signature is not valid, revert the transaction.
        revert("verification failed");
      }
      unchecked {
        ++i;
      }
    }

    // Update the global token ID variable with the new last used token ID.
    globalTokenIdVariable = _lastUsedTokenId;
  }

  /// Performs a batch operation to create multiple collections at once.
  /// Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
  /// @param projectId The ID of the registered project that will own the collections.
  /// @param signer The address of the signer that signed the parameters used to create the signatures.
  /// @param templateIds_ The IDs of the selected templates to use for creating the collections.
  /// @param totalSupplies The total supplies of tokens for the new collections.
  /// @param signatures The signatures created using the given parameters and signed by the signer.
  /// Second dimension includes, each signatures of each variation.
  /// @param uris The URIs that will be assigned to the collections. Second dimension includes variations.
  function createBatchCollection(
    uint256 projectId,
    address signer,
    uint256[] calldata templateIds_,
    uint16[] calldata totalSupplies,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external onlymQuarkControl {
    // Get the last used token ID.
    uint256 _lastUsedTokenId = globalTokenIdVariable;
    uint256 _collectionId;
    bool isVerified;
    // Loop through the templates.
    uint256 templateCount = templateIds_.length;
    for (uint256 i = 0; i < templateCount; ) {
      // Increment the collection ID for the given template.
      _collectionId = ++_projectCollectionIds[projectId][templateIds_[i]];
      for (uint256 j = 0; j < signatures[i].length; ) {
        // Verify the signature for the current collection.
        isVerified = _verifyCollectionURIEditSignature(
          signatures[i][j],
          signer,
          projectId,
          templateIds_[i],
          _collectionId,
          uris[i][j]
        );
        // Store the signature as inoperative.
        if (isVerified)
          _inoperativeSignatures[signatures[i][j]] = true;
          // Revert if the signature is invalid.
        else revert("verification failed");

        unchecked {
          ++j;
        }
      }

      // If the signature is valid, create the collection.
      Collection memory _tempData = _projectCollections[templateIds_[i]][projectId][_collectionId];

      // Set the data for the collection.
      _tempData = Collection(
        projectId,
        templateIds_[i],
        _collectionId,
        totalSupplies[i],
        (_lastUsedTokenId + 1),
        _lastUsedTokenId + totalSupplies[i],
        0,
        uris[i]
      );

      // Update the last used token ID.
      _lastUsedTokenId += totalSupplies[i];

      // Save the collection data.
      _projectCollections[templateIds_[i]][projectId][_collectionId] = _tempData;

      emit CollectionCreated(
        projectId,
        templateIds_[i],
        _collectionId,
        totalSupplies[i],
        _tempData.minTokenId,
        _tempData.maxTokenId,
        uris[i]
      );

      // Increment the counter variable `i` by 1.
      unchecked {
        ++i;
      }
    }

    // Update the global token ID variable with the new last used token ID.
    globalTokenIdVariable = _lastUsedTokenId;
  }

  /// Performs a batch operation to create multiple collections at once.
  /// Reverts if the given signer and any of the signatures do not match or if any of the signatures are not valid.
  /// @param projectId The ID of the registered project that will own the collections.
  /// @param templateIds_ The IDs of the selected templates to use for creating the collections.
  /// @param totalSupplies The total supplies of tokens for the new collections.
  function createBatchCollectionWithoutURIs(
    uint256 projectId,
    uint256[] calldata templateIds_,
    uint16[] calldata totalSupplies
  ) external onlymQuarkControl {
    // Get the last used token ID.
    uint256 _lastUsedTokenId = globalTokenIdVariable;
    uint256 _collectionId;

    // Loop through the templates.
    uint256 templateCount = templateIds_.length;
    for (uint256 i = 0; i < templateCount; ) {
      // Increment the collection ID for the given template.
      _collectionId = ++_projectCollectionIds[projectId][templateIds_[i]];
      string[] memory tempUri = new string[](1);
      // If the signature is valid, create the collection.

      Collection memory _tempData = _projectCollections[templateIds_[i]][projectId][_collectionId];

      // Set the data for the collection.
      _tempData = Collection(
        projectId,
        templateIds_[i],
        _collectionId,
        totalSupplies[i],
        (_lastUsedTokenId + 1),
        _lastUsedTokenId + totalSupplies[i],
        0,
        tempUri
      );

      // Update the last used token ID.
      _lastUsedTokenId += totalSupplies[i];

      // Save the collection data.
      _projectCollections[templateIds_[i]][projectId][_collectionId] = _tempData;

      emit CollectionCreated(
        projectId,
        templateIds_[i],
        _collectionId,
        totalSupplies[i],
        _tempData.minTokenId,
        _tempData.maxTokenId,
        tempUri
      );

      // Increment the counter variable `i` by 1.
      unchecked {
        ++i;
      }
    }

    // Update the global token ID variable with the new last used token ID.
    globalTokenIdVariable = _lastUsedTokenId;
  }

  //* ================================================================================================

  //* ==================================CATEGORY Functions============================================

  /// @notice Assigns given templates to a category
  /// @dev Only the contract's admin can set the template category
  /// @param category The name of the category for the templates (e.g. "vehicle")
  /// @param templateIds_ The ids of the templates that will be assigned to the given category (1, 2, 3, ...)
  function setTemplateCategory(string calldata category, uint256[] calldata templateIds_) external onlyAdmin {
    // Iterate through the given array of template ids
    uint256 templateLength = templateIds_.length;
    for (uint256 i = 0; i < templateLength; ) {
      // Check if the template exists
      require(templateIds.contains(templateIds_[i]) == true, "not exists");
      // Add the template to the given category
      categoryTemplates[category].add(templateIds_[i]);
      // Add the category to the template
      templateCategories[templateIds_[i]].add(category);
      // Increment the iterator
      {
        ++i;
      }
    }

    emit CategoriesSet(category, templateIds_);
  }

  /// @notice Removes given template from a given category.
  /// @param category category name for the template (e.g. "vehicle")
  /// @param templateId template id that will be set to the given category(1,2,3.. etc.)
  function removeCategoryFromTemplate(string memory category, uint256 templateId) external onlyAdmin {
    // Removes the given template id from the given category
    categoryTemplates[category].remove(templateId);

    // Removes the given category from the given template
    templateCategories[templateId].remove(category);

    emit CategoryRemoved(category, templateId);
  }

  //* =================================================================================================

  //* ==================== ROYALTY ================================================================

  ///! @notice Royalty interface should be changed with new accepted OpenSea standard
  /// @dev See EIP 2981
  function setRoyalty(address _receiver, uint256 _royaltyPercentage) external onlyAdmin {
    royaltyReceiver = _receiver;
    royaltyPercentage = _royaltyPercentage;
    emit RoyaltySet(_receiver, _royaltyPercentage);
  }

  //* ================================================================================================
  //*                                          VIEW Functions
  //* ================================================================================================

  /// @return token uri, for the given token id
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);
    return _tokenIdURIs[tokenId];
  }

  /// Every project will be able to place a slot to tokens if owners want
  /// These slots will store the uri that refers 'something' on the project
  /// Slots are viewable by other projects but modifiable only by the owner of the token who has a valid signature by the project
  /// @notice Returns the project URI for the given token ID
  /// @param tokenId The ID of the token whose project URI is to be returned
  /// @param projectId The ID of the project associated with the given token
  /// @return The URI of the given token's project slot
  function tokenProjectURI(uint256 tokenId, uint256 projectId) public view returns (string memory) {
    return _tokenProjectURIs[tokenId][projectId];
  }

  /// Templates defines what a token is. Every template id has its own properties and attributes.
  /// Collections are created by templates. Inherits the properties and attributes of the template.
  /// @param templateId template id
  /// @return template's uri
  function templateUri(uint256 templateId) external view returns (string memory) {
    return _templateURIs[templateId];
  }

  /// @return receiver is the royalty receiver address
  /// @return royaltyAmount the percentage of royalty
  function royaltyInfo(
    uint256 /*_tokenId*/,
    uint256 _salePrice
  ) external view override returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyReceiver;
    royaltyAmount = (royaltyPercentage * _salePrice) / 100;
  }

  /// @notice This function returns the total number of templates that have been created.
  /// @return The total number of templates that have been created
  function getCreatedTemplateIds() external view returns (uint256) {
    // Return the length of the template IDs array, which is the total number of templates that have been created
    return templateIds.length();
  }

  /// @notice This function returns an array of all the template IDs that are in a given category.
  /// If the array of templates for the given category is too large, this function may revert.
  /// @param category The name of the category to get the templates for
  /// @return An array of all the template IDs that are in the given category
  function getAllCategoryTemplates(string memory category) public view returns (uint256[] memory) {
    // Return the values of the mapping of templates for the given category
    return categoryTemplates[category].values();
  }

  /// @notice This function returns an array of template IDs for a given category, starting from a given index and up to a given length.
  /// If the batch size is too large, this function may revert. If the start index and batch size exceed the current length of the category,
  /// the returned array will be shorter than the batch size.
  /// @param category The name of the category to get the templates for
  /// @param startIndex The starting index of the templates to return
  /// @param batchLength The number of templates to return
  /// @return An array of template IDs for the given category, starting from the given index and up to the given length
  function getCategoryTemplatesByIndex(
    string memory category,
    uint16 startIndex,
    uint16 batchLength
  ) public view returns (uint256[] memory) {
    // Calculate the end index of the templates to return
    uint16 endIndex = startIndex + batchLength;
    if (batchLength + startIndex > categoryTemplates[category].length())
      endIndex = uint16(categoryTemplates[category].length());
    // Create the array of templates to return
    uint256[] memory _templateIds = new uint256[](endIndex - startIndex);

    // Populate the array with the templates from the given category, starting from the given index and up to the given length
    unchecked {
      for (uint16 i = startIndex; i < endIndex; ) {
        _templateIds[i - startIndex] = categoryTemplates[category].at(i);
        ++i;
      }
    }

    // Return the array of templates
    return _templateIds;
  }

  /// @notice This function returns the categories that a given template is in. If the template is not in any categories, it returns an empty array.
  /// @param templateId The ID of the template to get the categories for
  /// @return An array of the names of the categories that the given template is in
  function getTemplatesCategory(uint256 templateId) public view returns (string[] memory) {
    // Return the values of the mapping of categories for the given template
    return templateCategories[templateId].values();
  }

  /// @notice This function returns the number of templates that are in a given category.
  /// @param category The name of the category to get the template count for
  /// @return The number of templates in the given category
  function getCategoryTemplateLength(string calldata category) public view returns (uint256) {
    // Return the length of the templates array for the given category
    return categoryTemplates[category].length();
  }

  /// @notice This function returns the last collection ID for a given project and template.
  /// @param projectId The ID of the project to get the last collection ID for
  /// @param templateId The ID of the template to get the last collection ID for
  /// @return The last collection ID for the given project and template
  function getProjectLastCollectionId(uint256 projectId, uint256 templateId) external view returns (uint256) {
    // Return the last collection ID for the given project and template
    return _projectCollectionIds[projectId][templateId];
  }

  /// @notice This function checks whether a given token has been assigned a slot for a given project.
  /// @param tokenId The ID of the token to check
  /// @param projectId The ID of the project to check
  /// @return isAdded true if the given token has been assigned a slot for the given project, false otherwise
  function isSlotAddedForProject(uint256 tokenId, uint256 projectId) external view returns (bool isAdded) {
    // Get the URI slot for the given token and project
    string memory slot = _tokenProjectURIs[tokenId][projectId];

    // Check if the slot is empty or not
    isAdded = !_compareStrings(slot, "");
  }

  /// The function getProjectCollection is used to retrieve the details of a specific collection that was created by a registered project.
  /// @param templateId The ID of the template used to create the collection.
  /// @param projectId The ID of the project that created the collection.
  /// @param collectionId  The ID of the collection.
  /// @return _projectId The ID of the project that created the collection.
  /// @return _templateId The ID of the template used to create the collection.
  /// @return _totalSupply The total number of tokens in the collection.
  /// @return _collectionId The ID of the collection.
  /// @return _minTokenId The minimum token ID in the collection.
  /// @return _maxTokenId The maximum token ID in the collection.
  /// @return _mintCount The number of tokens that have been minted for this collection.
  /// @return _collectionURI The URI associated with the collection.
  function getProjectCollection(
    uint256 templateId,
    uint256 projectId,
    uint256 collectionId
  )
    external
    view
    returns (
      uint256 _projectId,
      uint256 _templateId,
      uint256 _totalSupply,
      uint256 _collectionId,
      uint256 _minTokenId,
      uint256 _maxTokenId,
      uint256 _mintCount,
      string[] memory _collectionURI
    )
  {
    // get the collection object
    Collection memory _collection = _projectCollections[templateId][projectId][collectionId];

    // return the values
    return (
      _collection.projectId,
      _collection.templateId,
      _collection.totalSupply,
      _collection.collectionId,
      _collection.minTokenId,
      _collection.maxTokenId,
      _collection.mintCount,
      _collection.collectionURIs
    );
  }

  /// @dev See ERC 165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return
      (interfaceId == type(IERC2981).interfaceId) ||
      (interfaceId == type(IERC721).interfaceId) ||
      (interfaceId == type(IERC721Metadata).interfaceId) ||
      super.supportsInterface(interfaceId);
  }

  //* ================================================================================================
  //*                                       INTERNAL Functions
  //* ================================================================================================

  /// @return _signer the singer of the given signature
  function _getHashSigner(bytes32 hash, bytes memory signature) internal pure returns (address _signer) {
    bytes32 _signed = ECDSA.toEthSignedMessageHash(hash);
    _signer = ECDSA.recover(_signed, signature);
  }

  /// @notice This function checks the validity of a given signature by verifying that it is signed by the given signer.
  /// @param signature The signature to verify
  /// @param signer The signer of the signature
  /// @param projectId The ID of the project associated with the signature
  /// @param templateId The ID of the template associated with the signature
  /// @param collectionId The ID of the collection associated with the signature
  /// @param uri The URI associated with the signature
  /// @return true if the signature is valid, false otherwise
  function _verifyCollectionURIEditSignature(
    bytes memory signature,
    address signer,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    string memory uri
  ) internal view returns (bool) {
    // Check if the signature has already been used
    require(!_inoperativeSignatures[signature], "used signature");

    // Generate the message hash to verify the signature
    bytes32 _messageHash = keccak256(abi.encode(signer, projectId, templateId, collectionId, uri));

    // Get the signer address of the hash and signature
    address _signer = _getHashSigner(_messageHash, signature);

    // Return whether the signer address matches the expected signer address
    return (_signer == signer);
  }

  /// @notice This function checks the validity of a given signature by verifying that it is signed by the given project address.
  /// @param signature The signature to verify
  /// @param project The address of the project that signed the signature
  /// @param projectId The ID of the project associated with the signature
  /// @param tokenId The ID of the token associated with the signature
  /// @param _uri The URI associated with the signature
  /// @return true if the signature is valid, false otherwise
  function _verifyUpdateTokenURISignature(
    bytes memory signature,
    address project,
    uint256 projectId,
    uint256 tokenId,
    string memory _uri
  ) internal view returns (bool) {
    // Check if the signature has already been used
    require(!_inoperativeSignatures[signature], "used signature");
    // Generate the message hash to verify the signature
    bytes32 _messageHash = keccak256(abi.encode(project, projectId, tokenId, _uri));

    // Get the signer address of the hash and signature
    address _signer = _getHashSigner(_messageHash, signature);

    // Return whether the signer address matches the expected project address
    return (project == _signer);
  }

  /// @notice This function compares two strings and returns true if they are equal.
  /// @param firstStr The first string to compare
  /// @param secondStr The second string to compare
  /// @return true if the strings are equal, false otherwise
  function _compareStrings(string memory firstStr, string memory secondStr) internal pure returns (bool) {
    // Compare the keccak256 hash of the two strings
    return (keccak256(abi.encodePacked(firstStr)) == keccak256(abi.encodePacked(secondStr)));
  }

  /// @notice This function checks if the caller of the function is the admin of the contract.
  /// @dev This function should be called at the beginning of functions that are only allowed to be called by the contract admin.
  function _onlyAdmin() internal view {
    // Check if the caller is the admin
    require(admin == msg.sender, "caller is not unauthorized");
  }

  /// @notice This function checks if the caller of the function is the mQuark Control contract.
  /// @dev This function should be called at the beginning of functions that are only allowed to be called by the mQuark Control contract.
  function _onlymQuarkControl() internal view {
    // Check if the caller is the mQuark Control contract
    require(msg.sender == mQuarkControl, "caller is not unauthorized");
  }

  //* ================================================================================================
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/mQuark/ImQuark.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/escrow/Escrow.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// @title mQuark Control
// mQuark protocol's Wapper contract. Registers projects, manages balances and withdrawals.
// @notice Projects are registered here. This contract is the only one that can mint mQuark tokens.
// @notice This contract is also the only one that can withdraw funds from the protocol.
// @author mQuark
contract mQuarkControl is ReentrancyGuard, PullPayment, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;

  //* ==================================================================================================
  //*                                              Events
  //* ===================================================================================================

  // Emitted when a wallet is authorized or unauthorized to register projects
  event AuthorizedToRegisterWalletSet(address wallet, bool isAuthorized);
  // Emitted when funds are deposited into multiple projects at once
  event BatchSlotFundsDeposit(
    uint256 amount,
    uint256 projectPercentage,
    uint256[] projectIds,
    uint256[] projectsShares
  );
  // Emitted when the creator's percentage is set
  event CreatorPercentageSet(uint256 percentage);
  // Emitted when funds are deposited into a project
  event FundsDeposit(uint256 amount, uint256 projectPercentage, uint256 projectId);
  // Emitted when funds are withdrawn from the protocol
  event FundsWithdrawn(address mquark, uint256 amount);
  // Emitted when mQuark tokens are minted and deposited into multiple projects at once
  event MintBatchSlotFundsDeposit(
    uint256 amount,
    uint256 projectPercentage,
    uint256[] projectIds,
    uint256[] projectsShares
  );
  // Emitted when the mQuark contract is set
  event MQuarkSet(address mquark);
  // Emitted when a project is registered
  event ProjectRegistered(
    address project,
    address creator,
    uint256 projectId,
    string projectName,
    string creatorName,
    string thumbnail,
    string projectDefaultSlotURI
  );
  // Emitted when funds are withdrawn from a project
  event ProjectFundsWithdrawn(uint256 projectId, uint256 amount);
  // Emitted when a project is removed
  event ProjectRemoved(uint256 projectId);
  // Emitted when the price of a slot is set
  event SlotPriceSet(uint256 projectId, uint256 price);
  // Emitted when the prices of templates are set
  event TemplatePricesSet(uint256[] templateIds, uint256[] prices);
  // Emitted when a token is transferred from one project to another with a URI
  event TokenProjectUriTransferred(
    uint256 fromTokenId,
    uint256 toTokenId,
    uint256 projectId,
    uint256 price,
    string uri,
    address from,
    address to
  );

  //* ===================================================================================================
  //*                                          STATE VARIABLES
  //* ===================================================================================================

  //* ============================ STRUCTS ==============================================================

  struct Project {
    // The wallet address of the project
    address wallet;
    // The wallet address of the project's creator
    address creator;
    // The unique ID of the project
    uint256 id;
    // The balance of the project
    uint256 balance;
    // The name of the project
    string name;
    // The thumbnail image of the project
    string thumbnail;
    // The default URI for the project's tokens
    string projectSlotDefaultURI;
  }

  /// @dev The admin address of the contract
  address public immutable admin;

  /// @dev The last registered project ID
  uint256 public projectIdIndex;

  /// @dev The percentage of funds that go to projects from mints and slot purchases
  uint256 public projectPercentage;

  /// @dev The percentage of funds that go to the contract admin from mints and slot purchases
  uint256 public adminPercentage;

  /// @dev Limits the selected templates to prevent out of gas errors
  uint16 constant MAX_SELECTING_LIMIT = 350;

  /// @dev The ERC721 contract interface
  ImQuark public mQuark;

  /// @dev The wallet addresses of projects registered with the contract
  EnumerableSet.AddressSet private projectWallets;

  /// @dev The address of the verifier, who signs collection URIs
  address public verifier;

  /// @dev This role will be used to check the validity of signatures
  bytes32 public constant SIGNATURE_VERIFIER_ROLE = keccak256("SIGNATURE_VERIFIER");

  //* =========================== MAPPINGS ==============================================================

  // mapping from 'admin address' to balance
  mapping(address => uint256) public adminBalance;

  // mapping from 'project id' to 'project struct'
  mapping(uint256 => Project) private _registeredProjects;

  // mapping from project address to 'project id'
  mapping(address => uint256) private _projectIds;

  // mapping from 'creator address' to 'boolean'
  // @dev This approved wallets can register projects(aka creators)
  mapping(address => bool) private _authorizedToRegisterProject;

  // mapping from 'template id' to 'mint price' in wei
  mapping(uint256 => uint256) private _templateMintPrices;

  // mapping from 'project id' to 'project uri slot price' in wei
  mapping(uint256 => uint256) private _projectSlotPrices;

  //* ======================== MODIFIERS ================================================================

  modifier onlyAdmin() {
    require(admin == msg.sender, "not authorized");
    _;
  }

  modifier onlyAuthorized() {
    require(_authorizedToRegisterProject[msg.sender] == true, "not authorized");
    _;
  }

  modifier onlyOwners(uint256 projectId) {
    require(
      _registeredProjects[projectId].creator == msg.sender || _registeredProjects[projectId].wallet == msg.sender,
      "unauthorized access"
    );
    _;
  }

  //* ==================================================================================================
  //*                                           CONSTRUCTOR
  //* ==================================================================================================

  constructor() {
    admin = msg.sender;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  //* ==================================================================================================
  //*                                         EXTERNAL Functions
  //* ==================================================================================================

  /// Checks the validity of given parameters and whether paid ETH amount is valid
  /// Makes a call to mQuark contract to mint single NFT.
  /// @param projectId collection owner's project id
  /// @param templateId collection's inherited template's id
  /// @param collectionId collection id for its template
  function mint(
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external payable nonReentrant {
    require(_registeredProjects[projectId].id != 0, "unregistered project");
    require(msg.value == _templateMintPrices[templateId], "sent value is wrong");
    require(msg.value != 0, "sent value is zero");
    mQuark.mint(msg.sender, projectId, templateId, collectionId, variationId);

    _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  function mintWithURI(
    address signer,
    uint256 projectId,
    uint256 templateId,
    uint256 collectionId,
    bytes calldata signature,
    string calldata uri
  ) external payable nonReentrant {
    require(_registeredProjects[projectId].id != 0, "unregistered project");
    require(_projectIds[signer] == projectId,"wrong parameter");
    require(msg.value == _templateMintPrices[templateId], "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    mQuark.mintWithPreURI(signer,msg.sender, projectId, templateId, collectionId, signature, uri);

    _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// Makes a call to mQuark contract to mint multiple NFT.
  /// @notice Each index will be matched to each other in given arrays, thus order of array indexes matters.
  /// @param projectId collection owner's project id
  /// @param templateIds collection's inherited template's id
  /// @param collectionIds collection id for its template
  /// @param amounts the number of mint amounts from each collection
  function mintBatch(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    uint256[] calldata variationIds
  ) external payable nonReentrant {
    require(_registeredProjects[projectId].id != 0, "unregistered project");
    require(templateIds.length == amounts.length, "amount mismatch");
    require(templateIds.length <= 20, "minting more than limit");
    require(this.totalPriceMintBatch(templateIds, amounts) == msg.value, "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    mQuark.mintBatch(msg.sender, projectId, templateIds, collectionIds, amounts, variationIds);
    _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[admin] += (msg.value * (adminPercentage)) / 100;
    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// Makes a call to mQuark contract to mint multiple NFTs with a single specified uri slot
  /// @notice Each index will be matched to each other in given arrays, thus order of array indexes matters.
  /// @param projectId collection owner's project id
  /// @param templateIds collection's inherited template's ids
  /// @param collectionIds collection ids for its template
  /// @param amounts the number of mint amounts from each collection
  function mintBatchWithURISlot(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint256[] calldata collectionIds,
    uint8[] calldata amounts,
    uint256[] calldata variationIds
  ) external payable nonReentrant {
    require(templateIds.length == collectionIds.length, "collection mismatch");
    require(templateIds.length == amounts.length, "amount mismatch");
    require(_registeredProjects[projectId].id != 0, "unregistered project");
    require(
      this.totalPriceMintBatchWithSingleSlotForEach(projectId, templateIds, amounts) == msg.value,
      "sent value is wrong"
    );

    mQuark.mintBatchWithURISlot(
      msg.sender,
      projectId,
      templateIds,
      collectionIds,
      amounts,
      variationIds,
      _registeredProjects[projectId].projectSlotDefaultURI
    );

    _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;
    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// Makes a call to mQuark contract to mint single NFT with multiple specified metadata slots.
  /// Performs mint operation with a single given projects uri slots for every token
  /// @param projectIds collection owner's project id
  /// @param templateId collection's inherited template's id
  /// @param collectionId collection id for its template
  function mintWithURISlots(
    uint256[] calldata projectIds,
    uint256 templateId,
    uint256 collectionId,
    uint256 variationId
  ) external payable nonReentrant {
    require(projectIds.length < 256, "minting more than limit");
    require(_templateMintPrices[templateId] > 0, "minting zero value NFT");

    string[] memory _projectSlotDefaultUris = new string[](projectIds.length);
    uint256 _totalPriceUriSlots;
    uint256 _priceUriSlot;
    uint256[] memory _projectsMetedataPriceShares = new uint256[](projectIds.length);

    uint256 projectCount = projectIds.length;
    for (uint8 i = 0; i < projectCount; ) {
      require(_registeredProjects[projectIds[i]].id == projectIds[i], "unregistered project");
      require(_projectSlotPrices[projectIds[i]] > 0, "slot value is zero");
      _priceUriSlot = _projectSlotPrices[projectIds[i]];
      _projectSlotDefaultUris[i] = (_registeredProjects[projectIds[i]].projectSlotDefaultURI);
      _totalPriceUriSlots += _priceUriSlot;
      _registeredProjects[projectIds[i]].balance += (_priceUriSlot * projectPercentage) / 100;
      _projectsMetedataPriceShares[i] = _priceUriSlot;

      unchecked {
        ++i;
      }
    }
    uint256 _templateMintPrice = _templateMintPrices[templateId];
    require(msg.value == (_totalPriceUriSlots + _templateMintPrice), "sent value is wrong");

    mQuark.mintWithURISlots(msg.sender, templateId, collectionId, variationId, projectIds, _projectSlotDefaultUris);
    _registeredProjects[projectIds[0]].balance += ((_templateMintPrice * projectPercentage) / 100);
    adminBalance[admin] += ((msg.value * adminPercentage) / 100);

    /** @notice Base mint price should be considered at zero index! */
    emit MintBatchSlotFundsDeposit(msg.value, projectPercentage, projectIds, _projectsMetedataPriceShares);
  }

  //* ================================================================================================

  //* =========================== URI SLOT Functions ==========================================

  /// Makes a call to mQuark contract to add single NFT uri slot to a single NFT
  /// @notice Slot's initial state will be pre-filled with project's default uri
  /// @param tokenId the token id to which the slot will be added
  /// @param projectId slot's project's id
  function addURISlotToNFT(uint256 tokenId, uint256 projectId) external payable nonReentrant {
    require(_registeredProjects[projectId].id == projectId, "unregistered project");
    require(_projectSlotPrices[projectId] == msg.value, "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    mQuark.addURISlotToNFT(msg.sender, tokenId, projectId, _registeredProjects[projectId].projectSlotDefaultURI);
    _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// Makes a call to mQuark contract to add multiple metadata slots to single NFT
  /// Adds different multiple uri slots to a single token
  /// @notice Reverts the number of given projects are more than 256
  /// @notice Slots' initial state will be pre-filled with projects' default uris
  /// @param tokenId the token id to which the slot will be added
  /// @param projectIds slots' project ids
  function addBatchURISlotsToNFT(uint256 tokenId, uint256[] calldata projectIds) external payable nonReentrant {
    string[] memory projectSlotDefaultUris = new string[](projectIds.length);
    uint256 _price;
    uint256 _totalAmount;
    uint256[] memory _projectsShares = new uint256[](projectIds.length);
    uint256 _projects = projectIds.length;

    for (uint256 i = 0; i < _projects; ) {
      require(_registeredProjects[projectIds[i]].id == projectIds[i], "unregistered project");
      require(_projectSlotPrices[projectIds[i]] > 0, "slot value is zero");
      _price = _projectSlotPrices[projectIds[i]];
      projectSlotDefaultUris[i] = (_registeredProjects[projectIds[i]].projectSlotDefaultURI);
      _totalAmount += _price;
      _registeredProjects[projectIds[i]].balance += (_price * projectPercentage) / 100;
      _projectsShares[i] = _price;
      unchecked {
        ++i;
      }
    }

    require(msg.value == _totalAmount, "sent value is wrong");

    adminBalance[admin] += (msg.value * adminPercentage) / 100;
    mQuark.addBatchURISlotsToNFT(msg.sender, tokenId, projectIds, projectSlotDefaultUris);
    emit BatchSlotFundsDeposit(msg.value, projectPercentage, projectIds, _projectsShares);
  }

  /// Makes a call to mQuark contract to add the same single uri slot to multiple NFTs
  /// @notice Slots' initial state will be pre-filled with projects' default uris
  /// @param tokenIds the token ids to which the slot will be added
  /// @param projectId slot's project's id
  function addBatchURISlotToNFTs(uint256[] calldata tokenIds, uint256 projectId) external payable nonReentrant {
    require(_registeredProjects[projectId].id == projectId, "unregistered project");
    require((_projectSlotPrices[projectId] * tokenIds.length) == msg.value, "sent value is wrong");
    require(msg.value != 0, "sent value is zero");

    mQuark.addBatchURISlotToNFTs(msg.sender, tokenIds, projectId, _registeredProjects[projectId].projectSlotDefaultURI);

    _registeredProjects[projectId].balance += (msg.value * projectPercentage) / 100;
    adminBalance[admin] += (msg.value * adminPercentage) / 100;

    emit FundsDeposit(msg.value, projectPercentage, projectId);
  }

  /// Makes a call to mQuark contract to update a given uri slot
  /// Updates the project's slot uri of a single token
  /// @notice Project should sign the new uri with its private key
  /// @param signature signed data by project's private key
  /// @param updateInfo encoded data
  function updateURISlot(bytes calldata signature, bytes calldata updateInfo) external {
    (address project, uint256 projectId, uint256 tokenId, string memory updatedUri) = abi.decode(
      updateInfo,
      (address, uint, uint, string)
    );
    Project memory _registeredProject = _registeredProjects[projectId];

    require(_registeredProject.wallet == project, "wrong project wallet");
    require(_registeredProject.id == projectId, "wrong project id");
    require(_registeredProject.wallet != address(0), "unregistered project");

    mQuark.updateURISlot(msg.sender, signature, project, projectId, tokenId, updatedUri);
  }

  /// Makes a call to mQuark tı transfers a project slot uri of a single token to another token's the same project slot
  /// @notice If orders doesn't match, it reverts
  /// @param seller the struct that contains sell order details
  /// @param buyer the struct that contains buy order details
  /// @param sellerSignature signed data by seller's private key
  /// @param buyerSignature signed data by buyer's private key
  function transferTokenProjectURI(
    Order.SellOrder calldata seller,
    Order.BuyOrder calldata buyer,
    bytes calldata sellerSignature,
    bytes calldata buyerSignature
  ) external payable nonReentrant {
    require(msg.sender == buyer.buyer, "unauthorized to transfer");
    require(seller.sellPrice == buyer.buyPrice, "not equal price");
    require(msg.value == buyer.buyPrice, "send corret amount");
    require(seller.fromTokenId == buyer.fromTokenId, "unmatched token");
    require(seller.projectId == buyer.projectId, "unmatched project");
    require(seller.seller == buyer.seller, "unmatched seller");

    string memory defualtProjectSlotUri = _registeredProjects[seller.projectId].projectSlotDefaultURI;
    mQuark.transferTokenProjectURI(seller, buyer, sellerSignature, buyerSignature, defualtProjectSlotUri);

    (bool sent, ) = seller.seller.call{value: msg.value}("");
    require(sent, "failed to send ether");
    emit TokenProjectUriTransferred(
      seller.fromTokenId,
      buyer.toTokenId,
      seller.projectId,
      seller.sellPrice,
      seller.slotUri,
      seller.seller,
      buyer.buyer
    );
  }

  //* ================================================================================================

  //* ==================================COLLECTION Creation===========================================

  /// Makes a call to mQuark contract to create a collection
  /// @dev Developer portal is used to get a valid signature
  /// @param projectId collection's project's id who is creator(registered to the contract)
  /// @param templateId selected template id to create the collection
  /// @param totalSupply collection's total supply
  /// @param signatures signature that is created by given parameters signed by signer
  /// @param uris the uri that will be assigned to collection
  function createCollection(
    uint256 projectId,
    uint256 templateId,
    uint16 totalSupply,
    bytes[] calldata signatures,
    string[] calldata uris
  ) external onlyOwners(projectId) {
    require(_templateMintPrices[templateId] > 0, "selected invalid template");
    require(totalSupply < MAX_SELECTING_LIMIT, "amount selected more than limit");
    mQuark.createCollection(projectId, verifier, templateId, totalSupply, signatures, uris);
  }

  /// Makes a call to mQuark contract to create collections
  /// @dev Developer portal is used to get a valid signature
  /// @param projectId collection's project's id who is creator(registered to the contract)
  /// @param templateIds selected template ids to create the collections
  /// @param totalSupplies collections' total supplies
  /// @param signatures signatures that are created by given parameters signed by signer
  /// @param uris the uris that will be assigned to collections
  function createCollections(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint16[] calldata totalSupplies,
    bytes[][] calldata signatures,
    string[][] calldata uris
  ) external onlyOwners(projectId) {
    uint256 _templatesLength = templateIds.length;
    require(_templatesLength < 50, "templates selected more than limit");
    require(_templatesLength == totalSupplies.length, "length mismatch");
    require(_templatesLength == signatures.length, "length mismatch");
    require(_templatesLength == uris.length, "length mismatch");

    uint16 _maxSelectingLimit = MAX_SELECTING_LIMIT;
    for (uint256 i = 0; i < _templatesLength; ) {
      require(_templateMintPrices[templateIds[i]] > 0, "selected invalid template");
      require(totalSupplies[i] < _maxSelectingLimit, "amount selected more than limit");
      require(signatures[i].length == uris[i].length, "signatures mismatch");
      unchecked {
        ++i;
      }
    }

    mQuark.createBatchCollection(projectId, verifier, templateIds, totalSupplies, signatures, uris);
  }

   function createBatchCollectionWithoutURIs(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint16[] calldata totalSupplies
  ) external onlyOwners(projectId) {
    uint256 _templatesLength = templateIds.length;
    require(_templatesLength < 50, "templates selected more than limit");
    require(_templatesLength == totalSupplies.length, "length mismatch");

    uint16 _maxSelectingLimit = MAX_SELECTING_LIMIT;
    for (uint256 i = 0; i < _templatesLength; ) {
      require(_templateMintPrices[templateIds[i]] > 0, "selected invalid template");
      require(totalSupplies[i] < _maxSelectingLimit, "amount selected more than limit");
      unchecked {
        ++i;
      }
    }

    mQuark.createBatchCollectionWithoutURIs(projectId, templateIds, totalSupplies);
  }


  //* ================================================================================================

  //* =========================== Project Registration ================================================

  /// Projets are registered to the contract
  /// @param project wallet address
  /// @param creator creator wallet of the project
  /// @param projectName project name
  /// @param creatorName creator name of the project
  /// @param thumbnail thumbnail url
  /// @param projectSlotDefaultURI the uri that will be assigned to project slot initially
  function registerProject(
    address project,
    address creator,
    string calldata projectName,
    string calldata creatorName,
    string calldata thumbnail,
    string calldata projectSlotDefaultURI
  ) external onlyAuthorized {
    require(!projectWallets.contains(project), "already registered");

    unchecked {
      uint256 _projectId = ++projectIdIndex;
      _registeredProjects[_projectId] = Project(
        project,
        creator,
        _projectId,
        _registeredProjects[_projectId].balance,
        projectName,
        thumbnail,
        projectSlotDefaultURI
      );
      projectWallets.add(project);
      _projectIds[project] = _projectId;
      emit ProjectRegistered(project, creator, _projectId, projectName, creatorName, thumbnail, projectSlotDefaultURI);
    }
  }

  /// Removes the registered project from the contract
  /// @param prjectId if of the registered project
  function removeProject(uint256 prjectId) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_registeredProjects[prjectId].id != 0, "unregistered project");

    _registeredProjects[prjectId].wallet = address(0);
    _registeredProjects[prjectId].creator = address(0);
    _registeredProjects[prjectId].id = 0;
    _registeredProjects[prjectId].name = "";
    _registeredProjects[prjectId].thumbnail = "";
    _registeredProjects[prjectId].projectSlotDefaultURI = "";
    projectWallets.remove(_registeredProjects[prjectId].wallet);

    emit ProjectRemoved(prjectId);
  }

  //* ================================================================================================

  //* ====================== SET Functions =============================================================

  /// Sets the contract address of deployed mQuark contract
  /// @param mQuarkAddr address of mQuark Contract
  function setmQuark(address mQuarkAddr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(address(mQuark) == address(0), "already set");
    mQuark = ImQuark(mQuarkAddr);
    emit MQuarkSet(mQuarkAddr);
  }

  /// Sets a wallet as an authorized or unauthorized to register projects
  /// @param wallet wallet address that will be set
  /// @param isAuthorized boolean value(true is authorized, false is unauthorized)
  function setAuthorizedToRegister(address wallet, bool isAuthorized) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _authorizedToRegisterProject[wallet] = isAuthorized;
    emit AuthorizedToRegisterWalletSet(wallet, isAuthorized);
  }

  /// Sets Templates mint prices(wei)
  /// @notice Collections inherit the template's mint price
  /// @param templateIds: IDs of Templates which are categorized NFTs
  /// @param prices: Prices of each given templates in wei unit
  function setTemplatePrices(
    uint256[] calldata templateIds,
    uint256[] calldata prices
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(templateIds.length == prices.length, "ids and prices mismatch");
    uint256 _templateIdsLength = templateIds.length;
    for (uint256 i = 0; i < _templateIdsLength; ) {
      _templateMintPrices[templateIds[i]] = prices[i];
      unchecked {
        ++i;
      }
    }
    emit TemplatePricesSet(templateIds, prices);
  }

  /// Sets projects percantage from minting and uri slot purchases
  /// @notice percentage should be between 0-100
  /// @param percentage: Percantage amount
  function setCreatorPercentage(uint256 percentage) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(percentage <= 100, "invalid value");
    projectPercentage = percentage;
    adminPercentage = (100 - percentage);
    emit CreatorPercentageSet(percentage);
  }

  /// Sets a project's uri slot price for every NFT minted
  /// @param projectId project id
  /// @param price slot price in wei
  function setProjectURISlotPrice(uint256 projectId, uint256 price) external onlyOwners(projectId) {
    _projectSlotPrices[projectId] = price;
    emit SlotPriceSet(projectId, price);
  }

  /// Sets given address as verifier, this address is sent to mQuark contract to verify signatures
  function setVerifierAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
    verifier = addr;
  }

  //* ================================================================================================

  //* ===================== FUND Transfers ==============================================================

  /// Contract admin transfers its balance to escrow contract
  /// @notice Uses {PullPayment} method of Oppenzeppelin.
  /// @param amount amount of funds that will be transferred in wei
  function transferFunds(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(amount <= adminBalance[msg.sender], "insufficient balance");
    adminBalance[msg.sender] -= amount;
    _asyncTransfer(msg.sender, amount);
    emit FundsWithdrawn(msg.sender, amount);
  }

  /// Projects transfers their balance to escrow contract
  /// @notice Uses {PullPayment} method of Oppenzeppelin.
  /// @param project project registered wallet address
  /// @param amount amount of funds that will be transferred in wei
  function projectTransferFunds(
    address payable project,
    uint256 projectId,
    uint256 amount
  ) external onlyOwners(projectId) {
    require(amount <= _registeredProjects[projectId].balance, "insufficient balance");
    _registeredProjects[projectId].balance -= amount;
    _asyncTransfer(project, amount);
    emit ProjectFundsWithdrawn(projectId, amount);
  }

  //* ================================================================================================

  //* ================================================================================================
  //*                                          VIEW Functions
  //* ================================================================================================

  /// Calculates mint base price
  /// @param templateIds template id of tokens
  /// @param amounts amount of each template ids
  /// @return totalPrice calculated total price amount of ids for a project
  function totalPriceMintBatch(
    uint256[] calldata templateIds,
    uint8[] calldata amounts
  ) external view returns (uint256 totalPrice) {
    uint256 _templateIdsLength = templateIds.length;
    for (uint8 i = 0; i < _templateIdsLength; ) {
      require(templateIds[i] != 0 && amounts[i] != 0, "invalid id/amount");
      totalPrice += (_templateMintPrices[templateIds[i]] * amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// Calculates total price of batch same slot uri purchases
  /// @param tokenAmounts token amounts for each template
  /// @param projectId slot's project Id
  function totalPriceBatchAddProjectSlot(
    uint256 projectId,
    uint8[] calldata tokenAmounts
  ) external view returns (uint256 totalPrice) {
    require(_projectSlotPrices[projectId] > 0, "slot value is zero");
    uint256 _amountsLength = tokenAmounts.length;
    for (uint8 i = 0; i < _amountsLength; ) {
      totalPrice += (_projectSlotPrices[projectId] * tokenAmounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// Multiple (tokens^slot))
  /// Calculate total price of mint batch tokens with single slot uri
  /// @param projectId slot's project Id
  /// @param templateIds template id of tokens
  /// @param amounts amount of each template ids
  function totalPriceMintBatchWithSingleSlotForEach(
    uint256 projectId,
    uint256[] calldata templateIds,
    uint8[] calldata amounts
  ) external view returns (uint256) {
    uint256 _slotPrice = this.totalPriceBatchAddProjectSlot(projectId, amounts);
    uint256 _mintPrices = this.totalPriceMintBatch(templateIds, amounts);
    return (_slotPrice + _mintPrices);
  }

  /// Single (token^slots)
  /// Calculates total price of a mint with multiple slots
  function totalPriceMintWithSlots(uint256[] calldata projectIds, uint256 templateId) public view returns (uint256) {
    uint256 _mintPrice = _templateMintPrices[templateId];
    uint256 _slotPrices;
    for (uint256 i = 0; i < projectIds.length; i++) _slotPrices += _projectSlotPrices[projectIds[i]];
    return (_mintPrice + _slotPrices);
  }

  /// Returns project's balance
  function getProjectBalance(uint256 projectId) external view returns (uint256) {
    return _registeredProjects[projectId].balance;
  }

  /// Returns registered project
  /// @return wallet project wallet address
  /// @return creator project creator address
  /// @return id project id
  /// @return balance project balance
  /// @return name project name
  /// @return thumbnail project thumbnail
  /// @return projectSlotDefaultURI project slot default uri
  function getRegisteredProject(
    uint256 projectId
  )
    external
    view
    returns (
      address wallet,
      address creator,
      uint256 id,
      uint256 balance,
      string memory name,
      string memory thumbnail,
      string memory projectSlotDefaultURI
    )
  {
    Project memory _project = _registeredProjects[projectId];
    return (
      _project.wallet,
      _project.creator,
      _project.id,
      _project.balance,
      _project.name,
      _project.thumbnail,
      _project.projectSlotDefaultURI
    );
  }

  /// Returns given project's id
  /// @param projectAddr project wallet address
  function getProjectId(address projectAddr) external view returns (uint256) {
    return _projectIds[projectAddr];
  }

  /// Returns whethere a given address is authorized to register a project
  function getAuthorizedToRegisterProject(address addr) external view returns (bool) {
    return _authorizedToRegisterProject[addr];
  }

  /// Returns template mint price
  function getTemplateMintPrice(uint256 templateId) external view returns (uint256) {
    return _templateMintPrices[templateId];
  }

  /// Returns project slot price
  function getProjectSlotPrice(uint256 projectId) external view returns (uint256) {
    return _projectSlotPrices[projectId];
  }

  //* ================================================================================================
}