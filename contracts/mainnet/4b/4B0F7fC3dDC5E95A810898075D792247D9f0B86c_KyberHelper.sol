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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
pragma solidity 0.8.9;

import "./utils/IDefaultAccessControl.sol";
import "./IUnitPricesGovernance.sol";

interface IProtocolGovernance is IDefaultAccessControl, IUnitPricesGovernance {
    /// @notice CommonLibrary protocol params.
    /// @param maxTokensPerVault Max different token addresses that could be managed by the vault
    /// @param governanceDelay The delay (in secs) that must pass before setting new pending params to commiting them
    /// @param protocolTreasury The address that collects protocolFees, if protocolFee is not zero
    /// @param forceAllowMask If a permission bit is set in this mask it forces all addresses to have this permission as true
    /// @param withdrawLimit Withdraw limit (in unit prices, i.e. usd)
    struct Params {
        uint256 maxTokensPerVault;
        uint256 governanceDelay;
        address protocolTreasury;
        uint256 forceAllowMask;
        uint256 withdrawLimit;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedPermissionGrantsTimestamps(address target) external view returns (uint256);

    /// @notice Staged granted permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function stagedPermissionGrantsMasks(address target) external view returns (uint256);

    /// @notice Permission bitmask for the given address.
    /// @param target The given address
    /// @return Bitmask
    function permissionMasks(address target) external view returns (uint256);

    /// @notice Timestamp after which staged pending protocol parameters can be committed
    /// @return Zero if there are no staged parameters, timestamp otherwise.
    function stagedParamsTimestamp() external view returns (uint256);

    /// @notice Staged pending protocol parameters.
    function stagedParams() external view returns (Params memory);

    /// @notice Current protocol parameters.
    function params() external view returns (Params memory);

    /// @notice Addresses for which non-zero permissions are set.
    function permissionAddresses() external view returns (address[] memory);

    /// @notice Permission addresses staged for commit.
    function stagedPermissionGrantsAddresses() external view returns (address[] memory);

    /// @notice Return all addresses where rawPermissionMask bit for permissionId is set to 1.
    /// @param permissionId Id of the permission to check.
    /// @return A list of dirty addresses.
    function addressesByPermission(uint8 permissionId) external view returns (address[] memory);

    /// @notice Checks if address has permission or given permission is force allowed for any address.
    /// @param addr Address to check
    /// @param permissionId Permission to check
    function hasPermission(address addr, uint8 permissionId) external view returns (bool);

    /// @notice Checks if address has all permissions.
    /// @param target Address to check
    /// @param permissionIds A list of permissions to check
    function hasAllPermissions(address target, uint8[] calldata permissionIds) external view returns (bool);

    /// @notice Max different ERC20 token addresses that could be managed by the protocol.
    function maxTokensPerVault() external view returns (uint256);

    /// @notice The delay for committing any governance params.
    function governanceDelay() external view returns (uint256);

    /// @notice The address of the protocol treasury.
    function protocolTreasury() external view returns (address);

    /// @notice Permissions mask which defines if ordinary permission should be reverted.
    /// This bitmask is xored with ordinary mask.
    function forceAllowMask() external view returns (uint256);

    /// @notice Withdraw limit per token per block.
    /// @param token Address of the token
    /// @return Withdraw limit per token per block
    function withdrawLimit(address token) external view returns (uint256);

    /// @notice Addresses that has staged validators.
    function stagedValidatorsAddresses() external view returns (address[] memory);

    /// @notice Timestamp after which staged granted permissions for the given address can be committed.
    /// @param target The given address
    /// @return Zero if there are no staged permission grants, timestamp otherwise
    function stagedValidatorsTimestamps(address target) external view returns (uint256);

    /// @notice Staged validator for the given address.
    /// @param target The given address
    /// @return Validator
    function stagedValidators(address target) external view returns (address);

    /// @notice Addresses that has validators.
    function validatorsAddresses() external view returns (address[] memory);

    /// @notice Address that has validators.
    /// @param i The number of address
    /// @return Validator address
    function validatorsAddress(uint256 i) external view returns (address);

    /// @notice Validator for the given address.
    /// @param target The given address
    /// @return Validator
    function validators(address target) external view returns (address);

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, IMMEDIATE  -------------------

    /// @notice Rollback all staged validators.
    function rollbackStagedValidators() external;

    /// @notice Revoke validator instantly from the given address.
    /// @param target The given address
    function revokeValidator(address target) external;

    /// @notice Stages a new validator for the given address
    /// @param target The given address
    /// @param validator The validator for the given address
    function stageValidator(address target, address validator) external;

    /// @notice Commits validator for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitValidator(address target) external;

    /// @notice Commites all staged validators for which governance delay passed
    /// @return Addresses for which validators were committed
    function commitAllValidatorsSurpassedDelay() external returns (address[] memory);

    /// @notice Rollback all staged granted permission grant.
    function rollbackStagedPermissionGrants() external;

    /// @notice Commits permission grants for the given address.
    /// @dev Reverts if governance delay has not passed yet.
    /// @param target The given address.
    function commitPermissionGrants(address target) external;

    /// @notice Commites all staged permission grants for which governance delay passed.
    /// @return An array of addresses for which permission grants were committed.
    function commitAllPermissionGrantsSurpassedDelay() external returns (address[] memory);

    /// @notice Revoke permission instantly from the given address.
    /// @param target The given address.
    /// @param permissionIds A list of permission ids to revoke.
    function revokePermissions(address target, uint8[] memory permissionIds) external;

    /// @notice Commits staged protocol params.
    /// Reverts if governance delay has not passed yet.
    function commitParams() external;

    // -------------------  EXTERNAL, MUTATING, GOVERNANCE, DELAY  -------------------

    /// @notice Sets new pending params that could have been committed after governance delay expires.
    /// @param newParams New protocol parameters to set.
    function stageParams(Params memory newParams) external;

    /// @notice Stage granted permissions that could have been committed after governance delay expires.
    /// Resets commit delay and permissions if there are already staged permissions for this address.
    /// @param target Target address
    /// @param permissionIds A list of permission ids to grant
    function stagePermissionGrants(address target, uint8[] memory permissionIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./utils/IDefaultAccessControl.sol";

interface IUnitPricesGovernance is IDefaultAccessControl, IERC165 {
    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @return The amount of token
    function stagedUnitPrices(address token) external view returns (uint256);

    /// @notice Timestamp after which staged unit prices for the given token can be committed.
    /// @param token Address of the token
    /// @return Timestamp
    function stagedUnitPricesTimestamps(address token) external view returns (uint256);

    /// @notice Estimated amount of token worth 1 USD.
    /// @param token Address of the token
    /// @return The amount of token
    function unitPrices(address token) external view returns (uint256);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage estimated amount of token worth 1 USD staged for commit.
    /// @param token Address of the token
    /// @param value The amount of token
    function stageUnitPrice(address token, uint256 value) external;

    /// @notice Reset staged value
    /// @param token Address of the token
    function rollbackUnitPrice(address token) external;

    /// @notice Commit staged unit price
    /// @param token Address of the token
    function commitUnitPrice(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IProtocolGovernance.sol";

interface IVaultRegistry is IERC721 {
    /// @notice Get Vault for the giver NFT ID.
    /// @param nftId NFT ID
    /// @return vault Address of the Vault contract
    function vaultForNft(uint256 nftId) external view returns (address vault);

    /// @notice Get NFT ID for given Vault contract address.
    /// @param vault Address of the Vault contract
    /// @return nftId NFT ID
    function nftForVault(address vault) external view returns (uint256 nftId);

    /// @notice Checks if the nft is locked for all transfers
    /// @param nft NFT to check for lock
    /// @return `true` if locked, false otherwise
    function isLocked(uint256 nft) external view returns (bool);

    /// @notice Register new Vault and mint NFT.
    /// @param vault address of the vault
    /// @param owner owner of the NFT
    /// @return nft Nft minted for the given Vault
    function registerVault(address vault, address owner) external returns (uint256 nft);

    /// @notice Number of Vaults registered.
    function vaultsCount() external view returns (uint256);

    /// @notice All Vaults registered.
    function vaults() external view returns (address[] memory);

    /// @notice Address of the ProtocolGovernance.
    function protocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Address of the staged ProtocolGovernance.
    function stagedProtocolGovernance() external view returns (IProtocolGovernance);

    /// @notice Minimal timestamp when staged ProtocolGovernance can be applied.
    function stagedProtocolGovernanceTimestamp() external view returns (uint256);

    /// @notice Stage new ProtocolGovernance.
    /// @param newProtocolGovernance new ProtocolGovernance
    function stageProtocolGovernance(IProtocolGovernance newProtocolGovernance) external;

    /// @notice Commit new ProtocolGovernance.
    function commitStagedProtocolGovernance() external;

    /// @notice Lock NFT for transfers
    /// @dev Use this method when vault structure is set up and should become immutable. Can be called by owner.
    /// @param nft - NFT to lock
    function lockNft(uint256 nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC1271 {
    /// @notice Verifies offchain signature.
    /// @dev Should return whether the signature provided is valid for the provided hash
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    ///
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    ///
    /// MUST allow external calls
    /// @param _hash Hash of the data to be signed
    /// @param _signature Signature byte array associated with _hash
    /// @return magicValue 0x1626ba7e if valid, 0xffffffff otherwise
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
    /// @notice Emitted when a pool is created
    /// @param token0 First pool token by address sort order
    /// @param token1 Second pool token by address sort order
    /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @param tickDistance Minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed swapFeeUnits,
        int24 tickDistance,
        address pool
    );

    /// @notice Emitted when a new fee is enabled for pool creation via the factory
    /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
    event SwapFeeEnabled(uint24 indexed swapFeeUnits, int24 indexed tickDistance);

    /// @notice Emitted when vesting period changes
    /// @param vestingPeriod The maximum time duration for which LP fees
    /// are proportionally burnt upon LP removals
    event VestingPeriodUpdated(uint32 vestingPeriod);

    /// @notice Emitted when configMaster changes
    /// @param oldConfigMaster configMaster before the update
    /// @param newConfigMaster configMaster after the update
    event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

    /// @notice Emitted when fee configuration changes
    /// @param feeTo Recipient of government fees
    /// @param governmentFeeUnits Fee amount, in fee units,
    /// to be collected out of the fee charged for a pool swap
    event FeeConfigurationUpdated(address feeTo, uint24 governmentFeeUnits);

    /// @notice Emitted when whitelist feature is enabled
    event WhitelistEnabled();

    /// @notice Emitted when whitelist feature is disabled
    event WhitelistDisabled();

    /// @notice Returns the maximum time duration for which LP fees
    /// are proportionally burnt upon LP removals
    function vestingPeriod() external view returns (uint32);

    /// @notice Returns the tick distance for a specified fee.
    /// @dev Once added, cannot be updated or removed.
    /// @param swapFeeUnits Swap fee, in fee units.
    /// @return The tick distance. Returns 0 if fee has not been added.
    function feeAmountTickDistance(uint24 swapFeeUnits) external view returns (int24);

    /// @notice Returns the address which can update the fee configuration
    function configMaster() external view returns (address);

    /// @notice Returns the keccak256 hash of the Pool creation code
    /// This is used for pre-computation of pool addresses
    function poolInitHash() external view returns (bytes32);

    /// @notice Fetches the recipient of government fees
    /// and current government fee charged in fee units
    function feeConfiguration() external view returns (address _feeTo, uint24 _governmentFeeUnits);

    /// @notice Returns the status of whitelisting feature of NFT managers
    /// If true, anyone can mint liquidity tokens
    /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
    function whitelistDisabled() external view returns (bool);

    //// @notice Returns all whitelisted NFT managers
    /// If the whitelisting feature is turned on,
    /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
    function getWhitelistedNFTManagers() external view returns (address[] memory);

    /// @notice Checks if sender is a whitelisted NFT manager
    /// If the whitelisting feature is turned on,
    /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
    /// @param sender address to be checked
    /// @return true if sender is a whistelisted NFT manager, false otherwise
    function isWhitelistedNFTManager(address sender) external view returns (bool);

    /// @notice Returns the pool address for a given pair of tokens and a swap fee
    /// @dev Token order does not matter
    /// @param tokenA Contract address of either token0 or token1
    /// @param tokenB Contract address of the other token
    /// @param swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @return pool The pool address. Returns null address if it does not exist
    function getPool(
        address tokenA,
        address tokenB,
        uint24 swapFeeUnits
    ) external view returns (address pool);

    /// @notice Fetch parameters to be used for pool creation
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// @return factory The factory address
    /// @return token0 First pool token by address sort order
    /// @return token1 Second pool token by address sort order
    /// @return swapFeeUnits Fee to be collected upon every swap in the pool, in fee units
    /// @return tickDistance Minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 swapFeeUnits,
            int24 tickDistance
        );

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param swapFeeUnits Desired swap fee for the pool, in fee units
    /// @dev Token order does not matter. tickDistance is determined from the fee.
    /// Call will revert under any of these conditions:
    ///     1) pool already exists
    ///     2) invalid swap fee
    ///     3) invalid token arguments
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 swapFeeUnits
    ) external returns (address pool);

    /// @notice Enables a fee amount with the given tickDistance
    /// @dev Fee amounts may never be removed once enabled
    /// @param swapFeeUnits The fee amount to enable, in fee units
    /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
    function enableSwapFee(uint24 swapFeeUnits, int24 tickDistance) external;

    /// @notice Updates the address which can update the fee configuration
    /// @dev Must be called by the current configMaster
    function updateConfigMaster(address) external;

    /// @notice Updates the vesting period
    /// @dev Must be called by the current configMaster
    function updateVestingPeriod(uint32) external;

    /// @notice Updates the address receiving government fees and fee quantity
    /// @dev Only configMaster is able to perform the update
    /// @param feeTo Address to receive government fees collected from pools
    /// @param governmentFeeUnits Fee amount, in fee units,
    /// to be collected out of the fee charged for a pool swap
    function updateFeeConfiguration(address feeTo, uint24 governmentFeeUnits) external;

    /// @notice Enables the whitelisting feature
    /// @dev Only configMaster is able to perform the update
    function enableWhitelist() external;

    /// @notice Disables the whitelisting feature
    /// @dev Only configMaster is able to perform the update
    function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IKyberSwapElasticLMEvents} from './IKyberSwapElasticLMEvents.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IKyberSwapElasticLM is IKyberSwapElasticLMEvents {
  struct RewardData {
    address rewardToken;
    uint256 rewardUnclaimed;
  }

  struct LMPoolInfo {
    address poolAddress;
    uint32 startTime;
    uint32 endTime;
    uint32 vestingDuration;
    uint256 totalSecondsClaimed; // scaled by (1 << 96)
    RewardData[] rewards;
    uint256 feeTarget;
    uint256 numStakes;
  }

  struct PositionInfo {
    address owner;
    uint256 liquidity;
  }

  struct StakeInfo {
    uint128 secondsPerLiquidityLast;
    uint256[] rewardLast;
    uint256[] rewardPending;
    uint256[] rewardHarvested;
    int256 feeFirst;
    uint256 liquidity;
  }

  // input data in harvestMultiplePools function
  struct HarvestData {
    uint256[] pIds;
  }

  // avoid stack too deep error
  struct RewardCalculationData {
    uint128 secondsPerLiquidityNow;
    int256 feeNow;
    uint256 vestingVolume;
    uint256 totalSecondsUnclaimed;
    uint256 secondsPerLiquidity;
    uint256 secondsClaim; // scaled by (1 << 96)
  }

  /**
   * @dev Add new pool to LM
   * @param poolAddr pool address
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param vestingDuration time locking in reward locker
   * @param rewardTokens reward token list for pool
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function addPool(
    address poolAddr,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    address[] calldata rewardTokens,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Renew a pool to start another LM program
   * @param pId pool id to update
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param vestingDuration time locking in reward locker
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function renewPool(
    uint256 pId,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Deposit NFT
   * @param nftIds list nft id
   *
   */
  function deposit(uint256[] calldata nftIds) external;

  /**
   * @dev Withdraw NFT, must exit all pool before call.
   * @param nftIds list nft id
   *
   */
  function withdraw(uint256[] calldata nftIds) external;

  /**
   * @dev Join pools
   * @param pId pool id to join
   * @param nftIds nfts to join
   * @param liqs list liquidity value to join each nft
   *
   */
  function join(
    uint256 pId,
    uint256[] calldata nftIds,
    uint256[] calldata liqs
  ) external;

  /**
   * @dev Exit from pools
   * @param pId pool ids to exit
   * @param nftIds list nfts id
   * @param liqs list liquidity value to exit from each nft
   *
   */
  function exit(
    uint256 pId,
    uint256[] calldata nftIds,
    uint256[] calldata liqs
  ) external;

  /**
   * @dev Operator only. Call to withdraw all reward from list pools.
   * @param rewards list reward address erc20 token
   * @param amounts amount to withdraw
   *
   */
  function emergencyWithdrawForOwner(address[] calldata rewards, uint256[] calldata amounts)
    external;

  /**
   * @dev Withdraw NFT, can call any time, reward will be reset. Must enable this func by operator
   * @param pIds list pool to withdraw
   *
   */
  function emergencyWithdraw(uint256[] calldata pIds) external;

  function nft() external view returns (IERC721);

  function poolLength() external view returns (uint256);

  function getUserInfo(uint256 nftId, uint256 pId)
    external
    view
    returns (
      uint256 liquidity,
      uint256[] memory rewardPending,
      uint256[] memory rewardLast
    );

  function getPoolInfo(uint256 pId)
    external
    view
    returns (
      address poolAddress,
      uint32 startTime,
      uint32 endTime,
      uint32 vestingDuration,
      uint256 totalSecondsClaimed,
      uint256 feeTarget,
      uint256 numStakes,
      //index reward => reward data
      address[] memory rewardTokens,
      uint256[] memory rewardUnclaimeds
    );

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function getRewardCalculationData(uint256 nftId, uint256 pId)
    external
    view
    returns (RewardCalculationData memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IKyberSwapElasticLMEvents {
  event AddPool(
    uint256 indexed pId,
    address poolAddress,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    uint256 feeTarget
  );

  event RenewPool(
    uint256 indexed pid,
    uint32 startTime,
    uint32 endTime,
    uint32 vestingDuration,
    uint256 feeTarget
  );

  event Deposit(address sender, uint256 indexed nftId);

  event Withdraw(address sender, uint256 indexed nftId);

  event Join(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event Exit(address to, uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event SyncLiq(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event Harvest(address to, address reward, uint256 indexed amount);

  event EmergencyEnabled();

  event EmergencyWithdrawForOwner(address reward, uint256 indexed amount);

  event EmergencyWithdraw(address sender, uint256 indexed nftId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IPoolActions} from "./pool/IPoolActions.sol";
import {IPoolEvents} from "./pool/IPoolEvents.sol";
import {IPoolStorage} from "./pool/IPoolStorage.sol";

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Callback for IPool#swap
/// @notice Any contract that calls IPool#swap must implement this interface
interface ISwapCallback {
    /// @notice Called to `msg.sender` after swap execution of IPool#swap.
    /// @dev This function's implementation must pay tokens owed to the pool for the swap.
    /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
    /// deltaQty0 and deltaQty1 can both be 0 if no tokens were swapped.
    /// @param deltaQty0 The token0 quantity that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send deltaQty0 of token0 to the pool.
    /// @param deltaQty1 The token1 quantity that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send deltaQty1 of token1 to the pool.
    /// @param data Data passed through by the caller via the IPool#swap call
    function swapCallback(
        int256 deltaQty0,
        int256 deltaQty1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IRouterTokenHelper} from "./IRouterTokenHelper.sol";
import {IBasePositionManagerEvents} from "./base_position_manager/IBasePositionManagerEvents.sol";
import {IERC721Permit} from "./IERC721Permit.sol";

interface IBasePositionManager is IRouterTokenHelper, IBasePositionManagerEvents, IERC721Permit {
    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        // the current rToken that the position owed
        uint256 rTokenOwed;
        // fee growth per unit of liquidity as of the last update to liquidity
        uint256 feeGrowthInsideLast;
    }

    struct PoolInfo {
        address token0;
        uint24 fee;
        address token1;
    }

    /// @notice Params for the first time adding liquidity, mint new nft to sender
    /// @param token0 the token0 of the pool
    /// @param token1 the token1 of the pool
    ///   - must make sure that token0 < token1
    /// @param fee the pool's fee in bps
    /// @param tickLower the position's lower tick
    /// @param tickUpper the position's upper tick
    ///   - must make sure tickLower < tickUpper, and both are in tick distance
    /// @param ticksPrevious the nearest tick that has been initialized and lower than or equal to
    ///   the tickLower and tickUpper, use to help insert the tickLower and tickUpper if haven't initialized
    /// @param amount0Desired the desired amount for token0
    /// @param amount1Desired the desired amount for token1
    /// @param amount0Min min amount of token 0 to add
    /// @param amount1Min min amount of token 1 to add
    /// @param recipient the owner of the position
    /// @param deadline time that the transaction will be expired
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24[2] ticksPrevious;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Params for adding liquidity to the existing position
    /// @param tokenId id of the position to increase its liquidity
    /// @param amount0Desired the desired amount for token0
    /// @param amount1Desired the desired amount for token1
    /// @param amount0Min min amount of token 0 to add
    /// @param amount1Min min amount of token 1 to add
    /// @param deadline time that the transaction will be expired
    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Params for remove liquidity from the existing position
    /// @param tokenId id of the position to remove its liquidity
    /// @param amount0Min min amount of token 0 to receive
    /// @param amount1Min min amount of token 1 to receive
    /// @param deadline time that the transaction will be expired
    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Burn the rTokens to get back token0 + token1 as fees
    /// @param tokenId id of the position to burn r token
    /// @param amount0Min min amount of token 0 to receive
    /// @param amount1Min min amount of token 1 to receive
    /// @param deadline time that the transaction will be expired
    struct BurnRTokenParams {
        uint256 tokenId;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Creates a new pool if it does not exist, then unlocks if it has not been unlocked
    /// @param token0 the token0 of the pool
    /// @param token1 the token1 of the pool
    /// @param fee the fee for the pool
    /// @param currentSqrtP the initial price of the pool
    /// @return pool returns the pool address
    function createAndUnlockPoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 currentSqrtP
    ) external payable returns (address pool);

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function addLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    function burnRTokens(BurnRTokenParams calldata params)
        external
        returns (
            uint256 rTokenQty,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @dev Burn the token by its owner
     * @notice All liquidity should be removed before burning
     */
    function burn(uint256 tokenId) external payable;

    function positions(uint256 tokenId) external view returns (Position memory pos, PoolInfo memory info);

    function addressToPoolId(address pool) external view returns (uint80);

    function isRToken(address token) external view returns (bool);

    function factory() external view returns (address);

    function nextPoolId() external view returns (uint80);

    function nextTokenId() external view returns (uint256);

    function multicall(bytes[] calldata) external payable returns (bytes[] memory);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721, IERC721Enumerable {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
pragma abicoder v2;

import "../callback/ISwapCallback.sol";

/// @notice Functions for swapping tokens via KyberSwap v2
/// - Support swap with exact input or exact output
/// - Support swap with a price limit
/// - Support swap within a single pool and between multiple pools
interface IRouter is ISwapCallback {
    /// @dev Params for swapping exact input amount
    /// @param tokenIn the token to swap
    /// @param tokenOut the token to receive
    /// @param fee the pool's fee
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountIn the tokenIn amount to swap
    /// @param amountOutMinimum the minimum receive amount
    /// @param limitSqrtP the price limit, if reached, stop swapping
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @dev Params for swapping exact input using multiple pools
    /// @param path the encoded path to swap from tokenIn to tokenOut
    ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token0, fee01, token1, fee12, token2]
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountIn the tokenIn amount to swap
    /// @param amountOutMinimum the minimum receive amount
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    /// @dev Params for swapping exact output amount
    /// @param tokenIn the token to swap
    /// @param tokenOut the token to receive
    /// @param fee the pool's fee
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountOut the tokenOut amount of tokenOut
    /// @param amountInMaximum the minimum input amount
    /// @param limitSqrtP the price limit, if reached, stop swapping
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
        uint160 limitSqrtP;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    /// @dev Params for swapping exact output using multiple pools
    /// @param path the encoded path to swap from tokenIn to tokenOut
    ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token2, fee12, token1, fee01, token0]
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountOut the tokenOut amount of tokenOut
    /// @param amountInMaximum the minimum input amount
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IRouterTokenHelper {
    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The minAmount parameter prevents malicious contracts from stealing WETH from users.
    /// @param minAmount The minimum amount of WETH to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWeth(uint256 minAmount, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundEth() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The minAmount parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param minAmount The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function transferAllTokens(
        address token,
        uint256 minAmount,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBasePositionManagerEvents {
    /// @notice Emitted when a token is minted for a given position
    /// @param tokenId the newly minted tokenId
    /// @param poolId poolId of the token
    /// @param liquidity liquidity minted to the position range
    /// @param amount0 token0 quantity needed to mint the liquidity
    /// @param amount1 token1 quantity needed to mint the liquidity
    event MintPosition(
        uint256 indexed tokenId,
        uint80 indexed poolId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when a token is burned
    /// @param tokenId id of the token
    event BurnPosition(uint256 indexed tokenId);

    /// @notice Emitted when add liquidity
    /// @param tokenId id of the token
    /// @param liquidity the increase amount of liquidity
    /// @param amount0 token0 quantity needed to increase liquidity
    /// @param amount1 token1 quantity needed to increase liquidity
    /// @param additionalRTokenOwed additional rToken earned
    event AddLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 additionalRTokenOwed
    );

    /// @notice Emitted when remove liquidity
    /// @param tokenId id of the token
    /// @param liquidity the decease amount of liquidity
    /// @param amount0 token0 quantity returned when remove liquidity
    /// @param amount1 token1 quantity returned when remove liquidity
    /// @param additionalRTokenOwed additional rToken earned
    event RemoveLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 additionalRTokenOwed
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;
pragma abicoder v2;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IPoolStorage} from '../../pool/IPoolStorage.sol';
import {IBasePositionManager} from '../IBasePositionManager.sol';
import {MathConstants as C} from '../../../../../libraries/external/MathConstants.sol';
import {QtyDeltaMath} from '../../../../../libraries/external/QtyDeltaMath.sol';
import {FullMath} from '../../../../../libraries/external/FullMath.sol';
import {ReinvestmentMath} from '../../../../../libraries/external/ReinvestmentMath.sol';
import {SafeCast} from '../../../../../libraries/external/SafeCast.sol';
import {TickMath as T} from '../../../../../libraries/external/TickMath.sol';

contract TicksFeesReader {
  using SafeCast for uint256;

  /// @dev Simplest method that attempts to fetch all initialized ticks
  /// Has the highest probability of running out of gas
  function getAllTicks(IPoolStorage pool) external view returns (int24[] memory allTicks) {
    // + 3 because of MIN_TICK, 0 and MAX_TICK
    uint32 maxNumTicks = uint32((uint256(int256(T.MAX_TICK / pool.tickDistance()))) * 2 + 3);
    allTicks = new int24[](maxNumTicks);
    int24 currentTick = T.MIN_TICK;
    allTicks[0] = currentTick;
    uint32 i = 1;
    while (currentTick < T.MAX_TICK) {
      (, currentTick) = pool.initializedTicks(currentTick);
      allTicks[i] = currentTick;
      i++;
    }
  }

  /// @dev Fetches all initialized ticks with a specified startTick (searches uptick)
  /// @dev 0 length = Use maximum length
  function getTicksInRange(
    IPoolStorage pool,
    int24 startTick,
    uint32 length
  ) external view returns (int24[] memory allTicks) {
    (int24 previous, int24 next) = pool.initializedTicks(startTick);
    // startTick is uninitialized, return
    if (previous == 0 && next == 0) return allTicks;
    // calculate num ticks from starting tick
    uint32 maxNumTicks;
    if (length == 0) {
      maxNumTicks = uint32(uint256(int256((T.MAX_TICK - startTick) / pool.tickDistance())));
      if (startTick == 0 || startTick == T.MAX_TICK) {
        maxNumTicks++;
      }
    } else {
      maxNumTicks = length;
    }

    allTicks = new int24[](maxNumTicks);
    for (uint32 i = 0; i < maxNumTicks; i++) {
      allTicks[i] = startTick;
      if (startTick == T.MAX_TICK) break;
      (, startTick) = pool.initializedTicks(startTick);
    }
  }

  function getNearestInitializedTicks(IPoolStorage pool, int24 tick)
    external
    view
    returns (int24 previous, int24 next)
  {
    // if queried tick already initialized, fetch and return values
    (previous, next) = pool.initializedTicks(tick);
    if (previous != 0 || next != 0) return (previous, next);

    // search downtick from MAX_TICK
    if (tick > 0) {
      previous = T.MAX_TICK;
      while (previous > tick) {
        (previous, ) = pool.initializedTicks(previous);
      }
      (, next) = pool.initializedTicks(previous);
    } else {
      // search uptick from MIN_TICK
      next = T.MIN_TICK;
      while (next < tick) {
        (, next) = pool.initializedTicks(next);
      }
      (previous, ) = pool.initializedTicks(next);
    }
  }

  function getTotalRTokensOwedToPosition(
    IBasePositionManager posManager,
    IPoolStorage pool,
    uint256 tokenId
  ) public view returns (uint256 rTokenOwed) {
    (IBasePositionManager.Position memory pos, ) = posManager.positions(tokenId);
    require(
      posManager.addressToPoolId(address(pool)) == pos.poolId,
      'tokenId and pool dont match'
    );

    // sync pool fee growth
    (uint256 feeGrowthGlobal, ) = _syncFeeGrowthGlobal(pool);
    // calc feeGrowthInside
    uint256 feeGrowthInside = _calcFeeGrowthInside(pool, pos, feeGrowthGlobal);
    // take difference in feeGrowthInside against position feeGrowthInside
    if (feeGrowthInside != pos.feeGrowthInsideLast) {
      uint256 feeGrowthInsideDiff;
      unchecked {
        feeGrowthInsideDiff = feeGrowthInside - pos.feeGrowthInsideLast;
      }
      pos.rTokenOwed += FullMath.mulDivFloor(pos.liquidity, feeGrowthInsideDiff, C.TWO_POW_96);
    }
    rTokenOwed = pos.rTokenOwed;
  }

  function getTotalFeesOwedToPosition(
    IBasePositionManager posManager,
    IPoolStorage pool,
    uint256 tokenId
  ) external view returns (uint256 token0Owed, uint256 token1Owed) {
    (IBasePositionManager.Position memory pos, ) = posManager.positions(tokenId);
    require(
      posManager.addressToPoolId(address(pool)) == pos.poolId,
      'tokenId and pool dont match'
    );
    // sync pool fee growth and rTotalSupply
    (uint256 feeGrowthGlobal, uint256 rTotalSupply) = _syncFeeGrowthGlobal(pool);
    // calc feeGrowthInside
    uint256 feeGrowthInside = _calcFeeGrowthInside(pool, pos, feeGrowthGlobal);
    // take difference in feeGrowthInside against position feeGrowthInside
    if (feeGrowthInside != pos.feeGrowthInsideLast) {
      uint256 feeGrowthInsideDiff;
      unchecked {
        feeGrowthInsideDiff = feeGrowthInside - pos.feeGrowthInsideLast;
      }
      pos.rTokenOwed += FullMath.mulDivFloor(pos.liquidity, feeGrowthInsideDiff, C.TWO_POW_96);
    }

    (, uint128 reinvestL, ) = pool.getLiquidityState();
    uint256 deltaL = FullMath.mulDivFloor(pos.rTokenOwed, reinvestL, rTotalSupply);
    (uint160 sqrtP, , , ) = pool.getPoolState();
    // finally, calculate token amounts owed
    token0Owed = QtyDeltaMath.getQty0FromBurnRTokens(sqrtP, deltaL);
    token1Owed = QtyDeltaMath.getQty1FromBurnRTokens(sqrtP, deltaL);
  }

  function _syncFeeGrowthGlobal(IPoolStorage pool)
    internal
    view
    returns (uint256 feeGrowthGlobal, uint256 rTotalSupply)
  {
    (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast) = pool.getLiquidityState();
    feeGrowthGlobal = pool.getFeeGrowthGlobal();
    rTotalSupply = IERC20(address(pool)).totalSupply();
    // logic ported from Pool._syncFeeGrowth()
    uint256 rMintQty = ReinvestmentMath.calcrMintQty(
      uint256(reinvestL),
      uint256(reinvestLLast),
      baseL,
      rTotalSupply
    );

    if (rMintQty != 0) {
      // add rMintQty to rTotalSupply before deductGovermentFee
      rTotalSupply += rMintQty;

      rMintQty = _deductGovermentFee(pool, rMintQty);
      unchecked {
        feeGrowthGlobal += FullMath.mulDivFloor(rMintQty, C.TWO_POW_96, baseL);
      }
    }
  }

  /// @return the lp fee without governance fee
  function _deductGovermentFee(IPoolStorage pool, uint256 rMintQty)
    internal
    view
    returns (uint256)
  {
    // fetch governmentFeeUnits
    (, uint24 governmentFeeUnits) = pool.factory().feeConfiguration();
    if (governmentFeeUnits == 0) {
      return rMintQty;
    }

    // unchecked due to governmentFeeUnits <= 20000
    unchecked {
      uint256 rGovtQty = (rMintQty * governmentFeeUnits) / C.FEE_UNITS;
      return rMintQty - rGovtQty;
    }
  }

  function _calcFeeGrowthInside(
    IPoolStorage pool,
    IBasePositionManager.Position memory pos,
    uint256 feeGrowthGlobal
  ) internal view returns (uint256 feeGrowthInside) {
    (, , uint256 feeGrowthOutsideLowerTick, ) = pool.ticks(pos.tickLower);
    (, , uint256 feeGrowthOutsideUpperTick, ) = pool.ticks(pos.tickUpper);
    (, int24 currentTick, , ) = pool.getPoolState();

    unchecked {
      if (currentTick < pos.tickLower) {
        feeGrowthInside = feeGrowthOutsideLowerTick - feeGrowthOutsideUpperTick;
      } else if (currentTick >= pos.tickUpper) {
        feeGrowthInside = feeGrowthOutsideUpperTick - feeGrowthOutsideLowerTick;
      } else {
        feeGrowthInside = feeGrowthGlobal - feeGrowthOutsideLowerTick - feeGrowthOutsideUpperTick;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolActions {
    /// @notice Sets the initial price for the pool and seeds reinvestment liquidity
    /// @dev Assumes the caller has sent the necessary token amounts
    /// required for initializing reinvestment liquidity prior to calling this function
    /// @param initialSqrtP the initial sqrt price of the pool
    /// @param qty0 token0 quantity sent to and locked permanently in the pool
    /// @param qty1 token1 quantity sent to and locked permanently in the pool
    function unlockPool(uint160 initialSqrtP) external returns (uint256 qty0, uint256 qty1);

    /// @notice Adds liquidity for the specified recipient/tickLower/tickUpper position
    /// @dev Any token0 or token1 owed for the liquidity provision have to be paid for when
    /// the IMintCallback#mintCallback is called to this method's caller
    /// The quantity of token0/token1 to be sent depends on
    /// tickLower, tickUpper, the amount of liquidity, and the current price of the pool.
    /// Also sends reinvestment tokens (fees) to the recipient for any fees collected
    /// while the position is in range
    /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
    /// @param recipient Address for which the added liquidity is credited to
    /// @param tickLower Recipient position's lower tick
    /// @param tickUpper Recipient position's upper tick
    /// @param ticksPrevious The nearest tick that is initialized and <= the lower & upper ticks
    /// @param qty Liquidity quantity to mint
    /// @param data Data (if any) to be passed through to the callback
    /// @return qty0 token0 quantity sent to the pool in exchange for the minted liquidity
    /// @return qty1 token1 quantity sent to the pool in exchange for the minted liquidity
    /// @return feeGrowthInside position's updated feeGrowthInside value
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        int24[2] calldata ticksPrevious,
        uint128 qty,
        bytes calldata data
    )
        external
        returns (
            uint256 qty0,
            uint256 qty1,
            uint256 feeGrowthInside
        );

    /// @notice Remove liquidity from the caller
    /// Also sends reinvestment tokens (fees) to the caller for any fees collected
    /// while the position is in range
    /// Reinvestment tokens have to be burnt via #burnRTokens in exchange for token0 and token1
    /// @param tickLower Position's lower tick for which to burn liquidity
    /// @param tickUpper Position's upper tick for which to burn liquidity
    /// @param qty Liquidity quantity to burn
    /// @return qty0 token0 quantity sent to the caller
    /// @return qty1 token1 quantity sent to the caller
    /// @return feeGrowthInside position's updated feeGrowthInside value
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 qty
    )
        external
        returns (
            uint256 qty0,
            uint256 qty1,
            uint256 feeGrowthInside
        );

    /// @notice Burns reinvestment tokens in exchange to receive the fees collected in token0 and token1
    /// @param qty Reinvestment token quantity to burn
    /// @param isLogicalBurn true if burning rTokens without returning any token0/token1
    ///         otherwise should transfer token0/token1 to sender
    /// @return qty0 token0 quantity sent to the caller for burnt reinvestment tokens
    /// @return qty1 token1 quantity sent to the caller for burnt reinvestment tokens
    function burnRTokens(uint256 qty, bool isLogicalBurn) external returns (uint256 qty0, uint256 qty1);

    /// @notice Swap token0 -> token1, or vice versa
    /// @dev This method's caller receives a callback in the form of ISwapCallback#swapCallback
    /// @dev swaps will execute up to limitSqrtP or swapQty is fully used
    /// @param recipient The address to receive the swap output
    /// @param swapQty The swap quantity, which implicitly configures the swap as exact input (>0), or exact output (<0)
    /// @param isToken0 Whether the swapQty is specified in token0 (true) or token1 (false)
    /// @param limitSqrtP the limit of sqrt price after swapping
    /// could be MAX_SQRT_RATIO-1 when swapping 1 -> 0 and MIN_SQRT_RATIO+1 when swapping 0 -> 1 for no limit swap
    /// @param data Any data to be passed through to the callback
    /// @return qty0 Exact token0 qty sent to recipient if < 0. Minimally received quantity if > 0.
    /// @return qty1 Exact token1 qty sent to recipient if < 0. Minimally received quantity if > 0.
    function swap(
        address recipient,
        int256 swapQty,
        bool isToken0,
        uint160 limitSqrtP,
        bytes calldata data
    ) external returns (int256 qty0, int256 qty1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IFlashCallback#flashCallback
    /// @dev Fees collected are sent to the feeTo address if it is set in Factory
    /// @param recipient The address which will receive the token0 and token1 quantities
    /// @param qty0 token0 quantity to be loaned to the recipient
    /// @param qty1 token1 quantity to be loaned to the recipient
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 qty0,
        uint256 qty1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPoolEvents {
    /// @notice Emitted only once per pool when #initialize is first called
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtP The initial price of the pool
    /// @param tick The initial tick of the pool
    event Initialize(uint160 sqrtP, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @dev transfers reinvestment tokens for any collected fees earned by the position
    /// @param sender address that minted the liquidity
    /// @param owner address of owner of the position
    /// @param tickLower position's lower tick
    /// @param tickUpper position's upper tick
    /// @param qty liquidity minted to the position range
    /// @param qty0 token0 quantity needed to mint the liquidity
    /// @param qty1 token1 quantity needed to mint the liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 qty,
        uint256 qty0,
        uint256 qty1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev transfers reinvestment tokens for any collected fees earned by the position
    /// @param owner address of owner of the position
    /// @param tickLower position's lower tick
    /// @param tickUpper position's upper tick
    /// @param qty liquidity removed
    /// @param qty0 token0 quantity withdrawn from removal of liquidity
    /// @param qty1 token1 quantity withdrawn from removal of liquidity
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 qty,
        uint256 qty0,
        uint256 qty1
    );

    /// @notice Emitted when reinvestment tokens are burnt
    /// @param owner address which burnt the reinvestment tokens
    /// @param qty reinvestment token quantity burnt
    /// @param qty0 token0 quantity sent to owner for burning reinvestment tokens
    /// @param qty1 token1 quantity sent to owner for burning reinvestment tokens
    event BurnRTokens(address indexed owner, uint256 qty, uint256 qty0, uint256 qty1);

    /// @notice Emitted for swaps by the pool between token0 and token1
    /// @param sender Address that initiated the swap call, and that received the callback
    /// @param recipient Address that received the swap output
    /// @param deltaQty0 Change in pool's token0 balance
    /// @param deltaQty1 Change in pool's token1 balance
    /// @param sqrtP Pool's sqrt price after the swap
    /// @param liquidity Pool's liquidity after the swap
    /// @param currentTick Log base 1.0001 of pool's price after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 deltaQty0,
        int256 deltaQty1,
        uint160 sqrtP,
        uint128 liquidity,
        int24 currentTick
    );

    /// @notice Emitted by the pool for any flash loans of token0/token1
    /// @param sender The address that initiated the flash loan, and that received the callback
    /// @param recipient The address that received the flash loan quantities
    /// @param qty0 token0 quantity loaned to the recipient
    /// @param qty1 token1 quantity loaned to the recipient
    /// @param paid0 token0 quantity paid for the flash, which can exceed qty0 + fee
    /// @param paid1 token1 quantity paid for the flash, which can exceed qty0 + fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 qty0,
        uint256 qty1,
        uint256 paid0,
        uint256 paid1
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IFactory} from "../IFactory.sol";

interface IPoolStorage {
    /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
    /// @return The contract address
    function factory() external view returns (IFactory);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (IERC20);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (IERC20);

    /// @notice The fee to be charged for a swap in basis points
    /// @return The swap fee in basis points
    function swapFeeUnits() external view returns (uint24);

    /// @notice The pool tick distance
    /// @dev Ticks can only be initialized and used at multiples of this value
    /// It remains an int24 to avoid casting even though it is >= 1.
    /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
    /// @return The tick distance
    function tickDistance() external view returns (int24);

    /// @notice Maximum gross liquidity that an initialized tick can have
    /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxTickLiquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
    /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
    /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
    /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside,
            uint128 secondsPerLiquidityOutside
        );

    /// @notice Returns the previous and next initialized ticks of a specific tick
    /// @dev If specified tick is uninitialized, the returned values are zero.
    /// @param tick The tick to look up
    function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

    /// @notice Returns the information about a position by the position's key
    /// @return liquidity the liquidity quantity of the position
    /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
    function getPositions(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

    /// @notice Fetches the pool's prices, ticks and lock status
    /// @return sqrtP sqrt of current price: sqrt(token1/token0)
    /// @return currentTick pool's current tick
    /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
    /// @return locked true if pool is locked, false otherwise
    function getPoolState()
        external
        view
        returns (
            uint160 sqrtP,
            int24 currentTick,
            int24 nearestCurrentTick,
            bool locked
        );

    /// @notice Fetches the pool's liquidity values
    /// @return baseL pool's base liquidity without reinvest liqudity
    /// @return reinvestL the liquidity is reinvested into the pool
    /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
    function getLiquidityState()
        external
        view
        returns (
            uint128 baseL,
            uint128 reinvestL,
            uint128 reinvestLLast
        );

    /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
    function getFeeGrowthGlobal() external view returns (uint256);

    /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
    /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
    function getSecondsPerLiquidityData()
        external
        view
        returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

    /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
    /// @param tickLower The lower tick (of a position)
    /// @param tickUpper The upper tick (of a position)
    /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
    /// between the 2 ticks, per unit of liquidity.
    function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOracle {
    /// @notice Oracle price for tokens as a Q64.96 value.
    /// @notice Returns pricing information based on the indexes of non-zero bits in safetyIndicesSet.
    /// @notice It is possible that not all indices will have their respective prices returned.
    /// @dev The price is token1 / token0 i.e. how many weis of token1 required for 1 wei of token0.
    /// The safety indexes are:
    ///
    /// 1 - unsafe, this is typically a spot price that can be easily manipulated,
    ///
    /// 2 - 4 - more or less safe, this is typically a uniV3 oracle, where the safety is defined by the timespan of the average price
    ///
    /// 5 - safe - this is typically a chailink oracle
    /// @param token0 Reference to token0
    /// @param token1 Reference to token1
    /// @param safetyIndicesSet Bitmask of safety indices that are allowed for the return prices. For set of safety indexes = { 1 }, safetyIndicesSet = 0x2
    /// @return pricesX96 Prices that satisfy safetyIndex and tokens
    /// @return safetyIndices Safety indices for those prices
    function priceX96(
        address token0,
        address token1,
        uint256 safetyIndicesSet
    ) external view returns (uint256[] memory pricesX96, uint256[] memory safetyIndices);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IDefaultAccessControl is IAccessControlEnumerable {
    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is admin, `false` otherwise
    function isAdmin(address who) external view returns (bool);

    /// @notice Checks that the address is contract admin.
    /// @param who Address to check
    /// @return `true` if who is operator, `false` otherwise
    function isOperator(address who) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/kyber/IPool.sol";
import "../external/kyber/IFactory.sol";
import "../external/kyber/periphery/IBasePositionManager.sol";

import "../vaults/IKyberVault.sol";

interface IKyberHelper {
    function liquidityToTokenAmounts(
        uint128 liquidity,
        IPool pool,
        uint256 kyberNft
    ) external view returns (uint256[] memory tokenAmounts);

    function tokenAmountsToLiquidity(
        uint256[] memory tokenAmounts,
        IPool pool,
        uint256 kyberNft
    ) external view returns (uint128 liquidity);

    function tokenAmountsToMaximalLiquidity(
        uint160 sqrtRatioX96,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);

    function calculateTvlBySqrtPriceX96(
        IPool pool,
        uint256 kyberNft,
        uint160 sqrtPriceX96
    ) external view returns (uint256[] memory tokenAmounts);

    function calcTvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    function getBytesToMulticall(uint256[] memory tokenAmounts, IKyberVault.Options memory opts) external view returns (bytes[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../external/erc/IERC1271.sol";
import "./IVault.sol";

interface IIntegrationVault is IVault, IERC1271 {
    /// @notice Pushes tokens on the vault balance to the underlying protocol. For example, for Yearn this operation will take USDC from
    /// the contract balance and convert it to yUSDC.
    /// @dev Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Also notice that this operation doesn't guarantee that tokenAmounts will be invested in full.
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function push(
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice The same as `push` method above but transfers tokens to vault balance prior to calling push.
    /// After the `push` it returns all the leftover tokens back (`push` method doesn't guarantee that tokenAmounts will be invested in full).
    /// @param tokens Tokens to push
    /// @param tokenAmounts Amounts of tokens to push
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually invested. It could be less than tokenAmounts (but not higher)
    function transferAndPush(
        address from,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Pulls tokens from the underlying protocol to the `to` address.
    /// @dev Can only be called but Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    /// When called by vault owner this method just pulls the tokens from the protocol to the `to` address
    /// When called by strategy on vault other than zero vault it pulls the tokens to zero vault (required `to` == zero vault)
    /// When called by strategy on zero vault it pulls the tokens to zero vault, pushes tokens on the `to` vault, and reclaims everything that's left.
    /// Thus any vault other than zero vault cannot have any tokens on it
    ///
    /// Tokens **must** be a subset of Vault Tokens. However, the convention is that if tokenAmount == 0 it is the same as token is missing.
    ///
    /// Pull is fulfilled on the best effort basis, i.e. if the tokenAmounts overflows available funds it withdraws all the funds.
    /// @param to Address to receive the tokens
    /// @param tokens Tokens to pull
    /// @param tokenAmounts Amounts of tokens to pull
    /// @param options Additional options that could be needed for some vaults. E.g. for Uniswap this could be `deadline` param. For the exact bytes structure see concrete vault descriptions
    /// @return actualTokenAmounts The amounts actually withdrawn. It could be less than tokenAmounts (but not higher)
    function pull(
        address to,
        address[] memory tokens,
        uint256[] memory tokenAmounts,
        bytes memory options
    ) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Claim ERC20 tokens from vault balance to zero vault.
    /// @dev Cannot be called from zero vault.
    /// @param tokens Tokens to claim
    /// @return actualTokenAmounts Amounts reclaimed
    function reclaimTokens(address[] memory tokens) external returns (uint256[] memory actualTokenAmounts);

    /// @notice Execute one of whitelisted calls.
    /// @dev Can only be called by Vault Owner or Strategy. Vault owner is the owner of NFT for this vault in VaultManager.
    /// Strategy is approved address for the vault NFT.
    ///
    /// Since this method allows sending arbitrary transactions, the destinations of the calls
    /// are whitelisted by Protocol Governance.
    /// @param to Address of the reward pool
    /// @param selector Selector of the call
    /// @param data Abi encoded parameters to `to::selector`
    /// @return result Result of execution of the call
    function externalCall(
        address to,
        bytes4 selector,
        bytes memory data
    ) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IIntegrationVault.sol";
import "../external/kyber/periphery/IBasePositionManager.sol";
import "../external/kyber/IPool.sol";

import "../oracles/IOracle.sol";
import "../utils/IKyberHelper.sol";
import "../external/kyber/IKyberSwapElasticLM.sol";

interface IKyberVault is IERC721Receiver, IIntegrationVault {
    struct Options {
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Reference to IBasePositionManager of KyberSwap protocol.
    function positionManager() external view returns (IBasePositionManager);

    /// @notice Reference to KyberSwap pool.
    function pool() external view returns (IPool);

    /// @notice NFT of KyberSwap position manager
    function kyberNft() external view returns (uint256);
    
    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param fee_ Fee of the Kyber pool
    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        uint24 fee_
    ) external;

    function updateFarmInfo() external;

    function farm() external view returns (IKyberSwapElasticLM);

    function mellowOracle() external view returns (IOracle);

    function pid() external view returns (uint256);

    function isLiquidityInFarm() external view returns (bool);

    function kyberHelper() external view returns (IKyberHelper);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "../external/kyber/periphery/IBasePositionManager.sol";
import "../external/kyber/IKyberSwapElasticLM.sol";
import "../external/kyber/periphery/IRouter.sol";
import "../oracles/IOracle.sol";
import "./IVaultGovernance.sol";
import "./IKyberVault.sol";

interface IKyberVaultGovernance is IVaultGovernance {

    struct StrategyParams {
        IKyberSwapElasticLM farm;
        bytes[] paths;
        uint256 pid;
    }

    /// @notice Delayed Strategy Params
    /// @param nft VaultRegistry NFT of the vault
    function strategyParams(uint256 nft) external view returns (StrategyParams memory);

    /// @notice Delayed Strategy Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external;

    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        uint24 fee_
    ) external returns (IKyberVault vault, uint256 nft);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IVaultGovernance.sol";

interface IVault is IERC165 {
    /// @notice Checks if the vault is initialized

    function initialized() external view returns (bool);

    /// @notice VaultRegistry NFT for this vault
    function nft() external view returns (uint256);

    /// @notice Address of the Vault Governance for this contract.
    function vaultGovernance() external view returns (IVaultGovernance);

    /// @notice ERC20 tokens under Vault management.
    function vaultTokens() external view returns (address[] memory);

    /// @notice Checks if a token is vault token
    /// @param token Address of the token to check
    /// @return `true` if this token is managed by Vault
    function isVaultToken(address token) external view returns (bool);

    /// @notice Total value locked for this contract.
    /// @dev Generally it is the underlying token value of this contract in some
    /// other DeFi protocol. For example, for USDC Yearn Vault this would be total USDC balance that could be withdrawn for Yearn to this contract.
    /// The tvl itself is estimated in some range. Sometimes the range is exact, sometimes it's not
    /// @return minTokenAmounts Lower bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    /// @return maxTokenAmounts Upper bound for total available balances estimation (nth tokenAmount corresponds to nth token in vaultTokens)
    function tvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts);

    /// @notice Existential amounts for each token
    function pullExistentials() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IProtocolGovernance.sol";
import "../IVaultRegistry.sol";
import "./IVault.sol";

interface IVaultGovernance {
    /// @notice Internal references of the contract.
    /// @param protocolGovernance Reference to Protocol Governance
    /// @param registry Reference to Vault Registry
    struct InternalParams {
        IProtocolGovernance protocolGovernance;
        IVaultRegistry registry;
        IVault singleton;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @notice Timestamp in unix time seconds after which staged Delayed Strategy Params could be committed.
    /// @param nft Nft of the vault
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params could be committed.
    function delayedProtocolParamsTimestamp() external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Delayed Protocol Params Per Vault could be committed.
    /// @param nft Nft of the vault
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256);

    /// @notice Timestamp in unix time seconds after which staged Internal Params could be committed.
    function internalParamsTimestamp() external view returns (uint256);

    /// @notice Internal Params of the contract.
    function internalParams() external view returns (InternalParams memory);

    /// @notice Staged new Internal Params.
    /// @dev The Internal Params could be committed after internalParamsTimestamp
    function stagedInternalParams() external view returns (InternalParams memory);

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @notice Stage new Internal Params.
    /// @param newParams New Internal Params
    function stageInternalParams(InternalParams memory newParams) external;

    /// @notice Commit staged Internal Params.
    function commitInternalParams() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./external/FullMath.sol";
import "./ExceptionsLibrary.sol";

/// @notice CommonLibrary shared utilities
library CommonLibrary {
    uint256 constant DENOMINATOR = 10**9;
    uint256 constant D18 = 10**18;
    uint256 constant YEAR = 365 * 24 * 3600;
    uint256 constant Q128 = 2**128;
    uint256 constant Q96 = 2**96;
    uint256 constant Q48 = 2**48;
    uint256 constant Q160 = 2**160;
    uint256 constant UNI_FEE_DENOMINATOR = 10**6;

    /// @notice Sort uint256 using bubble sort. The sorting is done in-place.
    /// @param arr Array of uint256
    function sortUint(uint256[] memory arr) internal pure {
        uint256 l = arr.length;
        for (uint256 i = 0; i < l; ++i) {
            for (uint256 j = i + 1; j < l; ++j) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
    }

    /// @notice Checks if array of addresses is sorted and all adresses are unique
    /// @param tokens A set of addresses to check
    /// @return `true` if all addresses are sorted and unique, `false` otherwise
    function isSortedAndUnique(address[] memory tokens) internal pure returns (bool) {
        if (tokens.length < 2) {
            return true;
        }
        for (uint256 i = 0; i < tokens.length - 1; ++i) {
            if (tokens[i] >= tokens[i + 1]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Projects tokenAmounts onto subset or superset of tokens
    /// @dev
    /// Requires both sets of tokens to be sorted. When tokens are not sorted, it's undefined behavior.
    /// If there is a token in tokensToProject that is not part of tokens and corresponding tokenAmountsToProject > 0, reverts.
    /// Zero token amount is eqiuvalent to missing token
    function projectTokenAmounts(
        address[] memory tokens,
        address[] memory tokensToProject,
        uint256[] memory tokenAmountsToProject
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](tokens.length);
        uint256 t = 0;
        uint256 tp = 0;
        while ((t < tokens.length) && (tp < tokensToProject.length)) {
            if (tokens[t] < tokensToProject[tp]) {
                res[t] = 0;
                t++;
            } else if (tokens[t] > tokensToProject[tp]) {
                if (tokenAmountsToProject[tp] == 0) {
                    tp++;
                } else {
                    revert("TPS");
                }
            } else {
                res[t] = tokenAmountsToProject[tp];
                t++;
                tp++;
            }
        }
        while (t < tokens.length) {
            res[t] = 0;
            t++;
        }
        return res;
    }

    /// @notice Calculated sqrt of uint in X96 format
    /// @param xX96 input number in X96 format
    /// @return sqrt of xX96 in X96 format
    function sqrtX96(uint256 xX96) internal pure returns (uint256) {
        uint256 sqX96 = sqrt(xX96);
        return sqX96 << 48;
    }

    /// @notice Calculated sqrt of uint
    /// @param x input number
    /// @return sqrt of x
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    /// @notice Recovers signer address from signed message hash
    /// @param _ethSignedMessageHash signed message
    /// @param _signature contatenated ECDSA r, s, v (65 bytes)
    /// @return Recovered address if the signature is valid, address(0) otherwise
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Get ECDSA r, s, v from signature
    /// @param sig signature (65 bytes)
    /// @return r ECDSA r
    /// @return s ECDSA s
    /// @return v ECDSA v
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, ExceptionsLibrary.INVALID_LENGTH);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Exceptions stores project`s smart-contracts exceptions
library ExceptionsLibrary {
    string constant ADDRESS_ZERO = "AZ";
    string constant VALUE_ZERO = "VZ";
    string constant EMPTY_LIST = "EMPL";
    string constant NOT_FOUND = "NF";
    string constant INIT = "INIT";
    string constant DUPLICATE = "DUP";
    string constant NULL = "NULL";
    string constant TIMESTAMP = "TS";
    string constant FORBIDDEN = "FRB";
    string constant ALLOWLIST = "ALL";
    string constant LIMIT_OVERFLOW = "LIMO";
    string constant LIMIT_UNDERFLOW = "LIMU";
    string constant INVALID_VALUE = "INV";
    string constant INVARIANT = "INVA";
    string constant INVALID_TARGET = "INVTR";
    string constant INVALID_TOKEN = "INVTO";
    string constant INVALID_INTERFACE = "INVI";
    string constant INVALID_SELECTOR = "INVS";
    string constant INVALID_STATE = "INVST";
    string constant INVALID_LENGTH = "INVL";
    string constant LOCK = "LCKD";
    string constant DISABLED = "DIS";
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // diff: original uint256 twos = -denominator & denominator;
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // diff: original lib works under 0.7.6 with overflows enabled
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }

    function mulDivFloor(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0, "0 denom");
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1, "denom <= prod1");

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        unchecked {
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
        }
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivCeiling(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDivFloor(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {MathConstants as C} from "./MathConstants.sol";
import {FullMath} from "./FullMath.sol";
import {SafeCast} from "./SafeCast.sol";

library LiquidityMath {
    using SafeCast for uint256;

    /// @notice Gets liquidity from qty 0 and the price range
    /// qty0 = liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// => liquidity = qty0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param lowerSqrtP A lower sqrt price
    /// @param upperSqrtP An upper sqrt price
    /// @param qty0 amount of token0
    /// @return liquidity amount of returned liquidity to not exceed the qty0
    function getLiquidityFromQty0(
        uint160 lowerSqrtP,
        uint160 upperSqrtP,
        uint256 qty0
    ) internal pure returns (uint128) {
        uint256 liq = FullMath.mulDivFloor(lowerSqrtP, upperSqrtP, C.TWO_POW_96);
        unchecked {
            return FullMath.mulDivFloor(liq, qty0, upperSqrtP - lowerSqrtP).toUint128();
        }
    }

    /// @notice Gets liquidity from qty 1 and the price range
    /// @dev qty1 = liquidity * (sqrt(upper) - sqrt(lower))
    ///   thus, liquidity = qty1 / (sqrt(upper) - sqrt(lower))
    /// @param lowerSqrtP A lower sqrt price
    /// @param upperSqrtP An upper sqrt price
    /// @param qty1 amount of token1
    /// @return liquidity amount of returned liquidity to not exceed to qty1
    function getLiquidityFromQty1(
        uint160 lowerSqrtP,
        uint160 upperSqrtP,
        uint256 qty1
    ) internal pure returns (uint128) {
        unchecked {
            return FullMath.mulDivFloor(qty1, C.TWO_POW_96, upperSqrtP - lowerSqrtP).toUint128();
        }
    }

    /// @notice Gets liquidity given price range and 2 qties of token0 and token1
    /// @param currentSqrtP current price
    /// @param lowerSqrtP A lower sqrt price
    /// @param upperSqrtP An upper sqrt price
    /// @param qty0 amount of token0 - at most
    /// @param qty1 amount of token1 - at most
    /// @return liquidity amount of returned liquidity to not exceed the given qties
    function getLiquidityFromQties(
        uint160 currentSqrtP,
        uint160 lowerSqrtP,
        uint160 upperSqrtP,
        uint256 qty0,
        uint256 qty1
    ) internal pure returns (uint128) {
        if (currentSqrtP <= lowerSqrtP) {
            return getLiquidityFromQty0(lowerSqrtP, upperSqrtP, qty0);
        }
        if (currentSqrtP >= upperSqrtP) {
            return getLiquidityFromQty1(lowerSqrtP, upperSqrtP, qty1);
        }
        uint128 liq0 = getLiquidityFromQty0(currentSqrtP, upperSqrtP, qty0);
        uint128 liq1 = getLiquidityFromQty1(lowerSqrtP, currentSqrtP, qty1);
        return liq0 < liq1 ? liq0 : liq1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains constants needed for math libraries
library MathConstants {
    uint256 internal constant TWO_FEE_UNITS = 200_000;
    uint256 internal constant TWO_POW_96 = 2**96;
    uint128 internal constant MIN_LIQUIDITY = 100000;
    uint8 internal constant RES_96 = 96;
    uint24 internal constant BPS = 10000;
    uint24 internal constant FEE_UNITS = 100000;
    // it is strictly less than 5% price movement if jumping MAX_TICK_DISTANCE ticks
    int24 internal constant MAX_TICK_DISTANCE = 480;
    // max number of tick travel when inserting if data changes
    uint256 internal constant MAX_TICK_TRAVEL = 10;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from "./MathConstants.sol";
import {TickMath} from "./TickMath.sol";
import {FullMath} from "./FullMath.sol";
import {SafeCast} from "./SafeCast.sol";

/// @title Contains helper functions for calculating
/// token0 and token1 quantites from differences in prices
/// or from burning reinvestment tokens
library QtyDeltaMath {
    using SafeCast for uint256;
    using SafeCast for int128;

    function calcUnlockQtys(uint160 initialSqrtP) internal pure returns (uint256 qty0, uint256 qty1) {
        qty0 = FullMath.mulDivCeiling(C.MIN_LIQUIDITY, C.TWO_POW_96, initialSqrtP);
        qty1 = FullMath.mulDivCeiling(C.MIN_LIQUIDITY, initialSqrtP, C.TWO_POW_96);
    }

    /// @notice Gets the qty0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// rounds up if adding liquidity, rounds down if removing liquidity
    /// @param lowerSqrtP The lower sqrt price.
    /// @param upperSqrtP The upper sqrt price. Should be >= lowerSqrtP
    /// @param liquidity Liquidity quantity
    /// @param isAddLiquidity true = add liquidity, false = remove liquidity
    /// @return token0 qty required for position with liquidity between the 2 sqrt prices
    function calcRequiredQty0(
        uint160 lowerSqrtP,
        uint160 upperSqrtP,
        uint128 liquidity,
        bool isAddLiquidity
    ) internal pure returns (int256) {
        uint256 numerator1 = uint256(liquidity) << C.RES_96;
        uint256 numerator2;
        unchecked {
            numerator2 = upperSqrtP - lowerSqrtP;
        }
        return
            isAddLiquidity
                ? (divCeiling(FullMath.mulDivCeiling(numerator1, numerator2, upperSqrtP), lowerSqrtP)).toInt256()
                : (FullMath.mulDivFloor(numerator1, numerator2, upperSqrtP) / lowerSqrtP).revToInt256();
    }

    /// @notice Gets the token1 delta quantity between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// rounds up if adding liquidity, rounds down if removing liquidity
    /// @param lowerSqrtP The lower sqrt price.
    /// @param upperSqrtP The upper sqrt price. Should be >= lowerSqrtP
    /// @param liquidity Liquidity quantity
    /// @param isAddLiquidity true = add liquidity, false = remove liquidity
    /// @return token1 qty required for position with liquidity between the 2 sqrt prices
    function calcRequiredQty1(
        uint160 lowerSqrtP,
        uint160 upperSqrtP,
        uint128 liquidity,
        bool isAddLiquidity
    ) internal pure returns (int256) {
        unchecked {
            return
                isAddLiquidity
                    ? (FullMath.mulDivCeiling(liquidity, upperSqrtP - lowerSqrtP, C.TWO_POW_96)).toInt256()
                    : (FullMath.mulDivFloor(liquidity, upperSqrtP - lowerSqrtP, C.TWO_POW_96)).revToInt256();
        }
    }

    function calcRequiredQtys(
        uint160 sqrtP,
        uint160 lowerSqrtP,
        uint160 upperSqrtP,
        uint128 liquidity,
        bool isAddLiquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (lowerSqrtP > upperSqrtP) (lowerSqrtP, upperSqrtP) = (upperSqrtP, lowerSqrtP);

        if (sqrtP <= lowerSqrtP) {
            amount0 = uint256(calcRequiredQty0(lowerSqrtP, upperSqrtP, liquidity, isAddLiquidity));
        } else if (sqrtP < upperSqrtP) {
            amount0 = uint256(calcRequiredQty0(sqrtP, upperSqrtP, liquidity, isAddLiquidity));
            amount1 = uint256(calcRequiredQty1(lowerSqrtP, sqrtP, liquidity, isAddLiquidity));
        } else {
            amount1 = uint256(calcRequiredQty1(lowerSqrtP, upperSqrtP, liquidity, isAddLiquidity));
        }
    }

    /// @notice Calculates the token0 quantity proportion to be sent to the user
    /// for burning reinvestment tokens
    /// @param sqrtP Current pool sqrt price
    /// @param liquidity Difference in reinvestment liquidity due to reinvestment token burn
    /// @return token0 quantity to be sent to the user
    function getQty0FromBurnRTokens(uint160 sqrtP, uint256 liquidity) internal pure returns (uint256) {
        return FullMath.mulDivFloor(liquidity, C.TWO_POW_96, sqrtP);
    }

    /// @notice Calculates the token1 quantity proportion to be sent to the user
    /// for burning reinvestment tokens
    /// @param sqrtP Current pool sqrt price
    /// @param liquidity Difference in reinvestment liquidity due to reinvestment token burn
    /// @return token1 quantity to be sent to the user
    function getQty1FromBurnRTokens(uint160 sqrtP, uint256 liquidity) internal pure returns (uint256) {
        return FullMath.mulDivFloor(liquidity, sqrtP, C.TWO_POW_96);
    }

    function getQtysFromBurnRTokens(uint160 sqrtP, uint256 liquidity) internal pure returns (uint256, uint256) {
        return (getQty0FromBurnRTokens(sqrtP, liquidity), getQty1FromBurnRTokens(sqrtP, liquidity));
    }

    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divCeiling(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // return x / y + ((x % y == 0) ? 0 : 1);
        require(y > 0);
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MathConstants as C} from './MathConstants.sol';
import {FullMath} from './FullMath.sol';

/// @title Contains helper function to calculate the number of reinvestment tokens to be minted
library ReinvestmentMath {
  /// @dev calculate the mint amount with given reinvestL, reinvestLLast, baseL and rTotalSupply
  /// contribution of lp to the increment is calculated by the proportion of baseL with reinvestL + baseL
  /// then rMintQty is calculated by mutiplying this with the liquidity per reinvestment token
  /// rMintQty = rTotalSupply * (reinvestL - reinvestLLast) / reinvestLLast * baseL / (baseL + reinvestL)
  function calcrMintQty(
    uint256 reinvestL,
    uint256 reinvestLLast,
    uint128 baseL,
    uint256 rTotalSupply
  ) internal pure returns (uint256 rMintQty) {
    uint256 lpContribution = FullMath.mulDivFloor(
      baseL,
      reinvestL - reinvestLLast,
      baseL + reinvestL
    );
    rMintQty = FullMath.mulDivFloor(rTotalSupply, lpContribution, reinvestLLast);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to uint32, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint32
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        require((z = uint32(y)) == y);
    }

    /// @notice Cast a uint128 to a int128, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt128(uint128 y) internal pure returns (int128 z) {
        require(y < 2**127);
        z = int128(y);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y the uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }

    /// @notice Cast a int128 to a uint128 and reverses the sign.
    /// @param y The int128 to be casted
    /// @return z = -y, now type uint128
    function revToUint128(int128 y) internal pure returns (uint128 z) {
        unchecked {
            return type(uint128).max - uint128(y) + 1;
        }
    }

    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }

    /// @notice Cast a uint256 to a int256 and reverses the sign, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z = -y, now type int256
    function revToInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = -int256(y);
    }

    /// @notice Cast a int256 to a uint256 and reverses the sign.
    /// @param y The int256 to be casted
    /// @return z = -y, now type uint256
    function revToUint256(int256 y) internal pure returns (uint256 z) {
        unchecked {
            return type(uint256).max - uint256(y) + 1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        // diff: original require(absTick <= uint256(MAX_TICK), "T");
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.9;

import "../interfaces/external/kyber/periphery/helpers/TicksFeeReader.sol";
import "../interfaces/external/kyber/IKyberSwapElasticLM.sol";

import "../interfaces/utils/IKyberHelper.sol";

import "../interfaces/vaults/IKyberVault.sol";
import "../interfaces/vaults/IKyberVaultGovernance.sol";

import "../libraries/CommonLibrary.sol";
import "../libraries/external/LiquidityMath.sol";
import "../libraries/external/QtyDeltaMath.sol";
import "../libraries/external/TickMath.sol";

contract KyberHelper is IKyberHelper {
    IBasePositionManager public immutable positionManager;
    TicksFeesReader public immutable ticksManager;

    constructor(IBasePositionManager positionManager_, TicksFeesReader ticksManager_) {
        require(address(positionManager_) != address(0));
        positionManager = positionManager_;
        ticksManager = ticksManager_;
    }

    function liquidityToTokenAmounts(
        uint128 liquidity,
        IPool pool,
        uint256 kyberNft
    ) external view returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint256[](2);

        (IBasePositionManager.Position memory position, ) = positionManager.positions(kyberNft);

        (uint160 sqrtPriceX96, , , ) = pool.getPoolState();
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(position.tickUpper);

        (tokenAmounts[0], tokenAmounts[1]) = QtyDeltaMath.calcRequiredQtys(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            liquidity,
            true
        );
    }

    function tokenAmountsToLiquidity(
        uint256[] memory tokenAmounts,
        IPool pool,
        uint256 kyberNft
    ) external view returns (uint128 liquidity) {
        (IBasePositionManager.Position memory position, ) = positionManager.positions(kyberNft);

        (uint160 sqrtPriceX96, , , ) = pool.getPoolState();
        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(position.tickUpper);

        liquidity = LiquidityMath.getLiquidityFromQties(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            tokenAmounts[0],
            tokenAmounts[1]
        );
    }

    function tokenAmountsToMaximalLiquidity(
        uint160 sqrtRatioX96,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) public pure returns (uint128 liquidity) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            LiquidityMath.getLiquidityFromQty0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = LiquidityMath.getLiquidityFromQty0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = LiquidityMath.getLiquidityFromQty1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 > liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = LiquidityMath.getLiquidityFromQty1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    function calculateTvlBySqrtPriceX96(
        IPool pool,
        uint256 kyberNft,
        uint160 sqrtPriceX96
    ) public view returns (uint256[] memory tokenAmounts) {
        tokenAmounts = new uint256[](2);

        (IBasePositionManager.Position memory position, ) = positionManager.positions(kyberNft);

        uint160 sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(position.tickUpper);

        (tokenAmounts[0], tokenAmounts[1]) = QtyDeltaMath.calcRequiredQtys(
            sqrtPriceX96,
            sqrtPriceAX96,
            sqrtPriceBX96,
            position.liquidity,
            true
        );

        (uint256 feeAmount0, uint256 feeAmount1) = ticksManager.getTotalFeesOwedToPosition(
            positionManager,
            pool,
            kyberNft
        );

        tokenAmounts[0] += feeAmount0;
        tokenAmounts[1] += feeAmount1;
    }

    function calcTvl() external view returns (uint256[] memory minTokenAmounts, uint256[] memory maxTokenAmounts) {
        IKyberVault vault = IKyberVault(msg.sender);

        uint256 kyberNft = vault.kyberNft();
        if (kyberNft == 0) return (new uint256[](2), new uint256[](2));
        IKyberSwapElasticLM farm = vault.farm();

        address[] memory _vaultTokens = vault.vaultTokens();

        {
            IPool pool = vault.pool();
            uint160 sqrtPriceX96;
            (sqrtPriceX96, , , ) = pool.getPoolState();
            minTokenAmounts = calculateTvlBySqrtPriceX96(pool, kyberNft, sqrtPriceX96);
        }

        if (vault.isLiquidityInFarm()) {
            uint256 pointer = 0;

            address[] memory rewardTokens;
            uint256[] memory rewardsPending;

            {
                uint256 pid = vault.pid();
                (, , , , , , , rewardTokens, ) = farm.getPoolInfo(pid);
                (, rewardsPending, ) = farm.getUserInfo(kyberNft, pid);
            }

            for (uint256 i = 0; i < rewardTokens.length; ++i) {
                bool exists = false;
                for (uint256 j = 0; j < _vaultTokens.length; ++j) {
                    if (rewardTokens[i] == _vaultTokens[j]) {
                        exists = true;
                        minTokenAmounts[j] += rewardsPending[i];
                    }
                }
                if (!exists) {
                    address lastToken;

                    {
                        bytes memory path = IKyberVaultGovernance(address(vault.vaultGovernance()))
                            .strategyParams(vault.nft())
                            .paths[pointer];
                        lastToken = CommonLibrary.toAddress(path, path.length - 20);
                    }

                    uint256[] memory pricesX96;

                    {
                        IOracle mellowOracle = vault.mellowOracle();
                        (pricesX96, ) = mellowOracle.priceX96(rewardTokens[i], lastToken, 0x20);
                    }

                    if (pricesX96[0] != 0) {
                        uint256 amount = FullMath.mulDiv(rewardsPending[i], pricesX96[0], 2**96);
                        for (uint256 j = 0; j < _vaultTokens.length; ++j) {
                            if (lastToken == _vaultTokens[j]) {
                                minTokenAmounts[j] += amount;
                            }
                        }
                    }

                    pointer += 1;
                }
            }
        }

        maxTokenAmounts = minTokenAmounts;
    }

    function getBytesToMulticall(uint256[] memory tokenAmounts, IKyberVault.Options memory opts)
        external
        view
        returns (bytes[] memory data)
    {
        IKyberVault vault = IKyberVault(msg.sender);

        uint256 kyberNft = vault.kyberNft();
        IPool pool = vault.pool();
        address[] memory _vaultTokens = vault.vaultTokens();

        uint128 liquidityToPull;
        // scope the code below to avoid stack-too-deep exception
        {
            (IBasePositionManager.Position memory position, ) = positionManager.positions(kyberNft);

            (uint160 sqrtPriceX96, , , ) = pool.getPoolState();
            liquidityToPull = tokenAmountsToMaximalLiquidity(
                sqrtPriceX96,
                position.tickLower,
                position.tickUpper,
                tokenAmounts[0],
                tokenAmounts[1]
            );
            liquidityToPull = position.liquidity < liquidityToPull ? position.liquidity : liquidityToPull;
        }

        if (liquidityToPull == 0) {
            return new bytes[](0);
        }

        if (ticksManager.getTotalRTokensOwedToPosition(positionManager, pool, kyberNft) > 0) {
            data = new bytes[](4);

            data[0] = abi.encodePacked(
                IBasePositionManager.removeLiquidity.selector,
                abi.encode(kyberNft, liquidityToPull, opts.amount0Min, opts.amount1Min, opts.deadline)
            );

            data[1] = abi.encodePacked(
                IBasePositionManager.burnRTokens.selector,
                abi.encode(kyberNft, 0, 0, block.timestamp + 1)
            );

            data[2] = abi.encodePacked(
                IRouterTokenHelper.transferAllTokens.selector,
                abi.encode(_vaultTokens[0], uint256(0), msg.sender)
            );
            data[3] = abi.encodePacked(
                IRouterTokenHelper.transferAllTokens.selector,
                abi.encode(_vaultTokens[1], uint256(0), msg.sender)
            );
        } else {
            data = new bytes[](3);

            data[0] = abi.encodePacked(
                IBasePositionManager.removeLiquidity.selector,
                abi.encode(kyberNft, liquidityToPull, opts.amount0Min, opts.amount1Min, opts.deadline)
            );

            data[1] = abi.encodePacked(
                IRouterTokenHelper.transferAllTokens.selector,
                abi.encode(_vaultTokens[0], uint256(0), msg.sender)
            );
            data[2] = abi.encodePacked(
                IRouterTokenHelper.transferAllTokens.selector,
                abi.encode(_vaultTokens[1], uint256(0), msg.sender)
            );
        }
    }
}