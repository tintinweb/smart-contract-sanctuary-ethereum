// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/vaults/IPancakeSwapVaultGovernance.sol";
import "../interfaces/vaults/IPancakeSwapVault.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../utils/ContractMeta.sol";
import "./VaultGovernance.sol";

/// @notice Governance that manages all PancakeSwap Vaults params and can deploy a new PancakeSwap Vault.
contract PancakeSwapVaultGovernance is ContractMeta, IPancakeSwapVaultGovernance, VaultGovernance {
    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    /// @param delayedProtocolParams_ Initial Protocol Params
    constructor(InternalParams memory internalParams_, DelayedProtocolParams memory delayedProtocolParams_)
        VaultGovernance(internalParams_)
    {
        require(address(delayedProtocolParams_.positionManager) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(delayedProtocolParams_.oracle) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _delayedProtocolParams = abi.encode(delayedProtocolParams_);
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IPancakeSwapVaultGovernance
    function delayedProtocolParams() public view returns (DelayedProtocolParams memory) {
        // params are initialized in constructor, so cannot be 0
        return abi.decode(_delayedProtocolParams, (DelayedProtocolParams));
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory) {
        if (_stagedDelayedProtocolParams.length == 0) {
            return
                DelayedProtocolParams({
                    positionManager: INonfungiblePositionManager(address(0)),
                    oracle: IOracle(address(0))
                });
        }
        return abi.decode(_stagedDelayedProtocolParams, (DelayedProtocolParams));
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function strategyParams(uint256 nft) external view returns (StrategyParams memory) {
        if (_strategyParams[nft].length == 0) {
            return
                StrategyParams({
                    swapSlippageD: 0,
                    poolForSwap: address(0),
                    cake: address(0),
                    underlyingToken: address(0),
                    smartRouter: address(0),
                    averageTickTimespan: 0
                });
        }
        return abi.decode(_strategyParams[nft], (StrategyParams));
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function stagedDelayedStrategyParams(uint256 nft) external view returns (DelayedStrategyParams memory) {
        if (_stagedDelayedStrategyParams[nft].length == 0) {
            return DelayedStrategyParams({safetyIndicesSet: 0});
        }
        return abi.decode(_stagedDelayedStrategyParams[nft], (DelayedStrategyParams));
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function delayedStrategyParams(uint256 nft) external view returns (DelayedStrategyParams memory) {
        if (_delayedStrategyParams[nft].length == 0) {
            return DelayedStrategyParams({safetyIndicesSet: 0x2A});
        }
        return abi.decode(_delayedStrategyParams[nft], (DelayedStrategyParams));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || type(IPancakeSwapVaultGovernance).interfaceId == interfaceId;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @inheritdoc IPancakeSwapVaultGovernance
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external {
        require(params.swapSlippageD <= 1e9, ExceptionsLibrary.LIMIT_OVERFLOW);
        require(params.averageTickTimespan > 0, ExceptionsLibrary.LIMIT_UNDERFLOW);
        require(
            params.poolForSwap != address(0) &&
                params.cake != address(0) &&
                params.underlyingToken != address(0) &&
                params.smartRouter != address(0),
            ExceptionsLibrary.ADDRESS_ZERO
        );

        _setStrategyParams(nft, abi.encode(params));
        emit SetStrategyParams(tx.origin, msg.sender, nft, params);
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external {
        require(address(params.positionManager) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(params.oracle) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _stageDelayedProtocolParams(abi.encode(params));
        emit StageDelayedProtocolParams(tx.origin, msg.sender, params, _delayedProtocolParamsTimestamp);
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function commitDelayedProtocolParams() external {
        _commitDelayedProtocolParams();
        emit CommitDelayedProtocolParams(
            tx.origin,
            msg.sender,
            abi.decode(_delayedProtocolParams, (DelayedProtocolParams))
        );
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function stageDelayedStrategyParams(uint256 nft, DelayedStrategyParams calldata params) external {
        require(params.safetyIndicesSet > 1, ExceptionsLibrary.LIMIT_UNDERFLOW);
        _stageDelayedStrategyParams(nft, abi.encode(params));
        emit StageDelayedStrategyParams(tx.origin, msg.sender, nft, params, _delayedStrategyParamsTimestamp[nft]);
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function commitDelayedStrategyParams(uint256 nft) external {
        _commitDelayedStrategyParams(nft);
        emit CommitDelayedStrategyParams(
            tx.origin,
            msg.sender,
            nft,
            abi.decode(_delayedStrategyParams[nft], (DelayedStrategyParams))
        );
    }

    /// @inheritdoc IPancakeSwapVaultGovernance
    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        uint24 fee_,
        address helper_,
        address masterChef_,
        address erc20Vault_
    ) external returns (IPancakeSwapVault vault, uint256 nft) {
        address vaddr;
        (vaddr, nft) = _createVault(owner_);
        vault = IPancakeSwapVault(vaddr);
        vault.initialize(nft, vaultTokens_, fee_, helper_, masterChef_, erc20Vault_);
        emit DeployedVault(tx.origin, msg.sender, vaultTokens_, abi.encode(fee_), owner_, vaddr, nft);
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _contractName() internal pure override returns (bytes32) {
        return bytes32("PancakeSwapVaultGovernance");
    }

    function _contractVersion() internal pure override returns (bytes32) {
        return bytes32("1.0.0");
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when new DelayedProtocolParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StageDelayedProtocolParams(
        address indexed origin,
        address indexed sender,
        DelayedProtocolParams params,
        uint256 when
    );
    /// @notice Emitted when new DelayedProtocolParams are committed
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that are committed
    event CommitDelayedProtocolParams(address indexed origin, address indexed sender, DelayedProtocolParams params);

    /// @notice Emitted when new DelayedStrategyParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StageDelayedStrategyParams(
        address indexed origin,
        address indexed sender,
        uint256 indexed nft,
        DelayedStrategyParams params,
        uint256 when
    );

    /// @notice Emitted when new DelayedStrategyParams are committed
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New params that are committed
    event CommitDelayedStrategyParams(
        address indexed origin,
        address indexed sender,
        uint256 indexed nft,
        DelayedStrategyParams params
    );

    /// @notice Emitted when new StrategyParams are set
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New set params
    event SetStrategyParams(address indexed origin, address indexed sender, uint256 indexed nft, StrategyParams params);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IPoolInitializer.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps PancakeSwap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is IPoolInitializer, IPeripheryPayments, IPeripheryImmutableState, IERC721 {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./pool/IPancakeV3PoolImmutables.sol";
import "./pool/IPancakeV3PoolState.sol";
import "./pool/IPancakeV3PoolDerivedState.sol";
import "./pool/IPancakeV3PoolActions.sol";
import "./pool/IPancakeV3PoolOwnerActions.sol";
import "./pool/IPancakeV3PoolEvents.sol";

/// @title The interface for a PancakeSwap V3 Pool
/// @notice A PancakeSwap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IPancakeV3Pool is
    IPancakeV3PoolImmutables,
    IPancakeV3PoolState,
    IPancakeV3PoolDerivedState,
    IPancakeV3PoolActions,
    IPancakeV3PoolOwnerActions,
    IPancakeV3PoolEvents
{
    function lmPool() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the PancakeSwap V3 deployer
    function deployer() external view returns (address);

    /// @return Returns the address of the PancakeSwap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount. And in PancakeSwap Router, this would be called
    /// at the very end of swap
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IPancakeV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IPancakeV3MintCallback#pancakeV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IPancakeV3SwapCallback#pancakeV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IPancakeV3FlashCallback#pancakeV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IPancakeV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IPancakeV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    /// @param protocolFeesToken0 The protocol fee of token0 in the swap
    /// @param protocolFeesToken1 The protocol fee of token1 in the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick,
        uint128 protocolFeesToken0,
        uint128 protocolFeesToken1
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(
        uint32 feeProtocol0Old,
        uint32 feeProtocol1Old,
        uint32 feeProtocol0New,
        uint32 feeProtocol1New
    );

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IPancakeV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IPancakeV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IPancakeV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint32 feeProtocol0, uint32 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Set the LM pool to enable liquidity mining
    function setLmPool(address lmPool) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IPancakeV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint32 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface IContractMeta {
    function contractName() external view returns (string memory);
    function contractNameBytes() external view returns (bytes32);

    function contractVersion() external view returns (string memory);
    function contractVersionBytes() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IIntegrationVault.sol";
import "../external/pancakeswap/INonfungiblePositionManager.sol";
import "../external/pancakeswap/IPancakeV3Pool.sol";

interface IPancakeSwapVault is IERC721Receiver, IIntegrationVault {
    struct Options {
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Reference to INonfungiblePositionManager of UniswapV3 protocol.
    function positionManager() external view returns (INonfungiblePositionManager);

    /// @notice Pancake farming pool manager
    function masterChef() external view returns (address);

    /// @notice erc20 vault of the rootvault system
    function erc20Vault() external view returns (address);

    /// @notice Reference to PancakeV3Pool pool.
    function pool() external view returns (IPancakeV3Pool);

    /// @notice NFT of UniV3 position manager
    function uniV3Nft() external view returns (uint256);

    /// @notice Returns tokenAmounts corresponding to liquidity, based on the current Uniswap position
    /// @param liquidity Liquidity that will be converted to token amounts
    /// @return tokenAmounts Token amounts for the specified liquidity
    function liquidityToTokenAmounts(uint128 liquidity) external view returns (uint256[] memory tokenAmounts);

    /// @notice Returns liquidity corresponding to token amounts, based on the current Uniswap position
    /// @param tokenAmounts Token amounts that will be converted to liquidity
    /// @return liquidity Liquidity for the specified token amounts
    function tokenAmountsToLiquidity(uint256[] memory tokenAmounts) external view returns (uint128 liquidity);

    function stakeUniV3Nft() external;

    function unstakeUniV3Nft() external;

    /// @notice Initialized a new contract.
    /// @dev Can only be initialized by vault governance
    /// @param nft_ NFT of the vault in the VaultRegistry
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param fee_ Fee of the UniV3 pool
    /// @param uniV3Helper_ address of helper for UniV3 arithmetic with ticks
    function initialize(
        uint256 nft_,
        address[] memory vaultTokens_,
        uint24 fee_,
        address uniV3Helper_,
        address masterChef_,
        address erc20Vault_
    ) external;

    /// @notice Collect UniV3 fees to zero vault.
    function collectEarnings() external returns (uint256[] memory collectedEarnings);

    function compound() external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../external/pancakeswap/INonfungiblePositionManager.sol";
import "../oracles/IOracle.sol";
import "./IVaultGovernance.sol";
import "./IPancakeSwapVault.sol";

interface IPancakeSwapVaultGovernance is IVaultGovernance {
    /// @notice Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param positionManager Reference to PancakeSwap INonfungiblePositionManager
    struct DelayedProtocolParams {
        INonfungiblePositionManager positionManager;
        IOracle oracle;
    }

    /// @param safetyIndicesSet Safety indices for oracle
    struct DelayedStrategyParams {
        uint32 safetyIndicesSet;
    }

    struct StrategyParams {
        uint256 swapSlippageD;
        address poolForSwap;
        address cake;
        address underlyingToken;
        address smartRouter;
        uint32 averageTickTimespan;
    }

    /// @notice Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function delayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Delayed Protocol Params staged for commit after delay.
    function stagedDelayedProtocolParams() external view returns (DelayedProtocolParams memory);

    /// @notice Stage Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    /// @param params New params
    function stageDelayedProtocolParams(DelayedProtocolParams calldata params) external;

    /// @notice Commit Delayed Protocol Params, i.e. Params that could be changed by Protocol Governance with Protocol Governance delay.
    function commitDelayedProtocolParams() external;

    /// @notice Delayed Strategy Params
    /// @param nft VaultRegistry NFT of the vault
    function strategyParams(uint256 nft) external view returns (StrategyParams memory);

    /// @notice Delayed Strategy Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function setStrategyParams(uint256 nft, StrategyParams calldata params) external;

    /// @notice Delayed Strategy Params
    /// @param nft VaultRegistry NFT of the vault
    function delayedStrategyParams(uint256 nft) external view returns (DelayedStrategyParams memory);

    /// @notice Delayed Strategy Params staged for commit after delay.
    /// @param nft VaultRegistry NFT of the vault
    function stagedDelayedStrategyParams(uint256 nft) external view returns (DelayedStrategyParams memory);

    /// @notice Stage Delayed Strategy Params, i.e. Params that could be changed by Strategy or Protocol Governance with Protocol Governance delay.
    /// @param nft VaultRegistry NFT of the vault
    /// @param params New params
    function stageDelayedStrategyParams(uint256 nft, DelayedStrategyParams calldata params) external;

    /// @notice Commit Delayed Strategy Params, i.e. Params that could be changed by Strategy or Protocol Governance with Protocol Governance delay.
    /// @dev Can only be called after delayedStrategyParamsTimestamp
    /// @param nft VaultRegistry NFT of the vault
    function commitDelayedStrategyParams(uint256 nft) external;

    /// @notice Deploys a new vault.
    /// @param vaultTokens_ ERC20 tokens that will be managed by this Vault
    /// @param owner_ Owner of the vault NFT
    /// @param fee_ Fee of the UniV3 pool
    /// @param helper_ address of helper for UniV3 arithmetic with ticks
    function createVault(
        address[] memory vaultTokens_,
        address owner_,
        uint24 fee_,
        address helper_,
        address masterChef_,
        address erc20Vault_
    ) external returns (IPancakeSwapVault vault, uint256 nft);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Stores permission ids for addresses
library PermissionIdsLibrary {
    // The msg.sender is allowed to register vault
    uint8 constant REGISTER_VAULT = 0;
    // The msg.sender is allowed to create vaults
    uint8 constant CREATE_VAULT = 1;
    // The token is allowed to be transfered by vault
    uint8 constant ERC20_TRANSFER = 2;
    // The token is allowed to be added to vault
    uint8 constant ERC20_VAULT_TOKEN = 3;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by any strategy
    uint8 constant ERC20_APPROVE = 4;
    // Trusted protocols that are allowed to be approved of vault ERC20 tokens by trusted strategy
    uint8 constant ERC20_APPROVE_RESTRICTED = 5;
    // Strategy allowed using restricted API
    uint8 constant TRUSTED_STRATEGY = 6;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/utils/IContractMeta.sol";

abstract contract ContractMeta is IContractMeta {
    // -------------------  EXTERNAL, VIEW  -------------------

    function contractName() external pure returns (string memory) {
        return _bytes32ToString(_contractName());
    }

    function contractNameBytes() external pure returns (bytes32) {
        return _contractName();
    }

    function contractVersion() external pure returns (string memory) {
        return _bytes32ToString(_contractVersion());
    }

    function contractVersionBytes() external pure returns (bytes32) {
        return _contractVersion();
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _contractName() internal pure virtual returns (bytes32);

    function _contractVersion() internal pure virtual returns (bytes32);

    function _bytes32ToString(bytes32 b) internal pure returns (string memory s) {
        s = new string(32);
        uint256 len = 32;
        for (uint256 i = 0; i < 32; ++i) {
            if (uint8(b[i]) == 0) {
                len = i;
                break;
            }
        }
        assembly {
            mstore(s, len)
            mstore(add(s, 0x20), b)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IProtocolGovernance.sol";
import "../interfaces/vaults/IVaultGovernance.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../libraries/PermissionIdsLibrary.sol";

/// @notice Internal contract for managing different params.
/// @dev The contract should be overriden by the concrete VaultGovernance,
/// define different params structs and use abi.decode / abi.encode to serialize
/// to bytes in this contract. It also should emit events on params change.
abstract contract VaultGovernance is IVaultGovernance, ERC165 {
    InternalParams internal _internalParams;
    InternalParams private _stagedInternalParams;
    uint256 internal _internalParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedStrategyParams;
    mapping(uint256 => bytes) internal _stagedDelayedStrategyParams;
    mapping(uint256 => uint256) internal _delayedStrategyParamsTimestamp;

    mapping(uint256 => bytes) internal _delayedProtocolPerVaultParams;
    mapping(uint256 => bytes) internal _stagedDelayedProtocolPerVaultParams;
    mapping(uint256 => uint256) internal _delayedProtocolPerVaultParamsTimestamp;

    bytes internal _delayedProtocolParams;
    bytes internal _stagedDelayedProtocolParams;
    uint256 internal _delayedProtocolParamsTimestamp;

    mapping(uint256 => bytes) internal _strategyParams;
    bytes internal _protocolParams;
    bytes internal _operatorParams;

    /// @notice Creates a new contract.
    /// @param internalParams_ Initial Internal Params
    constructor(InternalParams memory internalParams_) {
        require(address(internalParams_.protocolGovernance) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(internalParams_.registry) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(internalParams_.singleton) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _internalParams = internalParams_;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /// @inheritdoc IVaultGovernance
    function delayedStrategyParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedStrategyParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolPerVaultParamsTimestamp(uint256 nft) external view returns (uint256) {
        return _delayedProtocolPerVaultParamsTimestamp[nft];
    }

    /// @inheritdoc IVaultGovernance
    function delayedProtocolParamsTimestamp() external view returns (uint256) {
        return _delayedProtocolParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParamsTimestamp() external view returns (uint256) {
        return _internalParamsTimestamp;
    }

    /// @inheritdoc IVaultGovernance
    function internalParams() external view returns (InternalParams memory) {
        return _internalParams;
    }

    /// @inheritdoc IVaultGovernance
    function stagedInternalParams() external view returns (InternalParams memory) {
        return _stagedInternalParams;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165) returns (bool) {
        return super.supportsInterface(interfaceID) || interfaceID == type(IVaultGovernance).interfaceId;
    }

    // -------------------  EXTERNAL, MUTATING  -------------------

    /// @inheritdoc IVaultGovernance
    function stageInternalParams(InternalParams memory newParams) external {
        _requireProtocolAdmin();
        require(address(newParams.protocolGovernance) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(newParams.registry) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        require(address(newParams.singleton) != address(0), ExceptionsLibrary.ADDRESS_ZERO);
        _stagedInternalParams = newParams;
        _internalParamsTimestamp = block.timestamp + _internalParams.protocolGovernance.governanceDelay();
        emit StagedInternalParams(tx.origin, msg.sender, newParams, _internalParamsTimestamp);
    }

    /// @inheritdoc IVaultGovernance
    function commitInternalParams() external {
        _requireProtocolAdmin();
        require(_internalParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= _internalParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _internalParams = _stagedInternalParams;
        delete _internalParamsTimestamp;
        delete _stagedInternalParams;
        emit CommitedInternalParams(tx.origin, msg.sender, _internalParams);
    }

    // -------------------  INTERNAL, VIEW  -------------------

    function _requireAtLeastStrategy(uint256 nft) internal view {
        require(
            (_internalParams.protocolGovernance.isAdmin(msg.sender) ||
                _internalParams.registry.getApproved(nft) == msg.sender ||
                (_internalParams.registry.ownerOf(nft) == msg.sender)),
            ExceptionsLibrary.FORBIDDEN
        );
    }

    function _requireProtocolAdmin() internal view {
        require(_internalParams.protocolGovernance.isAdmin(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }

    function _requireAtLeastOperator() internal view {
        IProtocolGovernance governance = _internalParams.protocolGovernance;
        require(governance.isAdmin(msg.sender) || governance.isOperator(msg.sender), ExceptionsLibrary.FORBIDDEN);
    }

    // -------------------  INTERNAL, MUTATING  -------------------

    function _createVault(address owner) internal returns (address vault, uint256 nft) {
        IProtocolGovernance protocolGovernance = IProtocolGovernance(_internalParams.protocolGovernance);
        require(
            protocolGovernance.hasPermission(msg.sender, PermissionIdsLibrary.CREATE_VAULT),
            ExceptionsLibrary.FORBIDDEN
        );
        IVaultRegistry vaultRegistry = _internalParams.registry;
        nft = vaultRegistry.vaultsCount() + 1;
        vault = Clones.cloneDeterministic(address(_internalParams.singleton), bytes32(nft));
        vaultRegistry.registerVault(address(vault), owner);
    }

    /// @notice Set Delayed Strategy Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _stagedDelayedStrategyParams[nft] = params;
        uint256 delayFactor = _delayedStrategyParams[nft].length == 0 ? 0 : 1;
        _delayedStrategyParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Strategy Params
    function _commitDelayedStrategyParams(uint256 nft) internal {
        _requireAtLeastStrategy(nft);
        uint256 thisDelayedStrategyParamsTimestamp = _delayedStrategyParamsTimestamp[nft];
        require(thisDelayedStrategyParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= thisDelayedStrategyParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _delayedStrategyParams[nft] = _stagedDelayedStrategyParams[nft];
        delete _stagedDelayedStrategyParams[nft];
        delete _delayedStrategyParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Per Vault Params
    /// @param nft Nft of the vault
    /// @param params New params
    function _stageDelayedProtocolPerVaultParams(uint256 nft, bytes memory params) internal {
        _requireProtocolAdmin();
        _stagedDelayedProtocolPerVaultParams[nft] = params;
        uint256 delayFactor = _delayedProtocolPerVaultParams[nft].length == 0 ? 0 : 1;
        _delayedProtocolPerVaultParamsTimestamp[nft] =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Per Vault Params
    function _commitDelayedProtocolPerVaultParams(uint256 nft) internal {
        _requireProtocolAdmin();
        uint256 thisDelayedProtocolPerVaultParamsTimestamp = _delayedProtocolPerVaultParamsTimestamp[nft];
        require(thisDelayedProtocolPerVaultParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= thisDelayedProtocolPerVaultParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _delayedProtocolPerVaultParams[nft] = _stagedDelayedProtocolPerVaultParams[nft];
        delete _stagedDelayedProtocolPerVaultParams[nft];
        delete _delayedProtocolPerVaultParamsTimestamp[nft];
    }

    /// @notice Set Delayed Protocol Params
    /// @param params New params
    function _stageDelayedProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        uint256 delayFactor = _delayedProtocolParams.length == 0 ? 0 : 1;
        _stagedDelayedProtocolParams = params;
        _delayedProtocolParamsTimestamp =
            block.timestamp +
            _internalParams.protocolGovernance.governanceDelay() *
            delayFactor;
    }

    /// @notice Commit Delayed Protocol Params
    function _commitDelayedProtocolParams() internal {
        _requireProtocolAdmin();
        require(_delayedProtocolParamsTimestamp != 0, ExceptionsLibrary.NULL);
        require(block.timestamp >= _delayedProtocolParamsTimestamp, ExceptionsLibrary.TIMESTAMP);
        _delayedProtocolParams = _stagedDelayedProtocolParams;
        delete _stagedDelayedProtocolParams;
        delete _delayedProtocolParamsTimestamp;
    }

    /// @notice Set immediate strategy params
    /// @dev Should require nft > 0
    /// @param nft Nft of the vault
    /// @param params New params
    function _setStrategyParams(uint256 nft, bytes memory params) internal {
        _requireAtLeastStrategy(nft);
        _strategyParams[nft] = params;
    }

    /// @notice Set immediate operator params
    /// @param params New params
    function _setOperatorParams(bytes memory params) internal {
        _requireAtLeastOperator();
        _operatorParams = params;
    }

    /// @notice Set immediate protocol params
    /// @param params New params
    function _setProtocolParams(bytes memory params) internal {
        _requireProtocolAdmin();
        _protocolParams = params;
    }

    // --------------------------  EVENTS  --------------------------

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    /// @param when When the params could be committed
    event StagedInternalParams(address indexed origin, address indexed sender, InternalParams params, uint256 when);

    /// @notice Emitted when InternalParams are staged for commit
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param params New params that were staged for commit
    event CommitedInternalParams(address indexed origin, address indexed sender, InternalParams params);

    /// @notice Emitted when New Vault is deployed
    /// @param origin Origin of the transaction (tx.origin)
    /// @param sender Sender of the call (msg.sender)
    /// @param vaultTokens Vault tokens for this vault
    /// @param options Options for deploy. The details of the options structure are specified in subcontracts
    /// @param owner Owner of the VaultRegistry NFT for this vault
    /// @param vaultAddress Address of the new Vault
    /// @param vaultNft VaultRegistry NFT for the new Vault
    event DeployedVault(
        address indexed origin,
        address indexed sender,
        address[] vaultTokens,
        bytes options,
        address owner,
        address vaultAddress,
        uint256 vaultNft
    );
}