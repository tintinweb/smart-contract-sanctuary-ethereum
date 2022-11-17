// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./VaultOwnershipChecker.sol";
import "./OwnableERC721.sol";
import "../interfaces/IVaultInventoryReporter.sol";
import "../external/interfaces/IPunks.sol";

/**
 * @title VaultInventoryReporter
 * @author Non-Fungible Technologies, Inc.
 *
 * The VaultInventoryReporter contract is a global tracker of reported
 * inventory in all Arcade Asset Vaults. This reporting should _always_
 * be accurate, but will _not_ be comprehensive - that is, many vaults
 * will end up having unreported inventory. This contract should
 * be used specifically to verify _whether_ certain items are in the
 * reported inventory, and not to get a sense of truth as to _all_
 * the items in a particular vault.
 *
 * Based on the method of storing inventory based on an itemsHash,
 * the report is also idempotent - any matching itemsHash will simply
 * update a status or amount, and will not increment any stored value.
 */
contract VaultInventoryReporter is IVaultInventoryReporter, VaultOwnershipChecker, EIP712, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Counters for Counters.Counter;

    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /// @dev To prevent gas consumption issues, registering more than 50 items
    ///      in a single transaction will revert.
    uint256 public constant MAX_ITEMS_PER_REGISTRATION = 50;

    // ============= Inventory State ==============

    /// @notice vault address -> itemHash -> Item metadata
    mapping(address => mapping(bytes32 => Item)) public inventoryForVault;
    /// @notice vault address -> itemHash[] (for enumeration)
    mapping(address => EnumerableSet.Bytes32Set) private inventoryKeysForVault;
    /// @notice Approvals to modify inventory contents for a vault
    ///         vault -> approved address
    mapping(address => address) public approved;
    /// @notice Approvals to modify inventory contents for a vault,
    ///         which apply to any vault. Can be set by admins.
    ///         caller -> isApproved
    mapping(address => bool) public globalApprovals;

    // ============= Permit Functionality ==============

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address target,address vault,uint256 nonce,uint256 deadline)");

    /// @dev Nonce for permit signatures.
    mapping(address => Counters.Counter) private _nonces;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * @param name                  The name of the signing domain.
     */
    constructor(string memory name) EIP712(name, "1") {}

    // ===================================== INVENTORY OPERATIONS ======================================

    /**
     * @notice Add items to the vault's registered inventory. If specified items
     *         are not owned by the vault, add will revert.
     *
     * @param vault                         The address of the vault.
     * @param items                         The list of items to add.
     */
    // solhint-disable-next-line code-complexity
    function add(address vault, Item[] calldata items) public override validate(msg.sender, vault) {
        // For each item, verify the vault actually owns it, or revert
        uint256 numItems = items.length;

        if (numItems == 0) revert VIR_NoItems();
        if (numItems > MAX_ITEMS_PER_REGISTRATION) revert VIR_TooManyItems(MAX_ITEMS_PER_REGISTRATION);

        for (uint256 i = 0; i < numItems; i++) {
            Item calldata item = items[i];

            if (item.tokenAddress == address(0)) revert VIR_InvalidRegistration(vault, i);

            bytes32 itemHash = _hash(item);

            if (item.itemType == ItemType.ERC_721) {
                if (IERC721(item.tokenAddress).ownerOf(item.tokenId) != vault) {
                    revert VIR_NotVerified(vault, i);
                }
            } else if (item.itemType == ItemType.ERC_1155) {
                if (IERC1155(item.tokenAddress).balanceOf(vault, item.tokenId) < item.tokenAmount) {
                    revert VIR_NotVerified(vault, i);
                }
            } else if (item.itemType == ItemType.ERC_20) {
                if (IERC20(item.tokenAddress).balanceOf(vault) < item.tokenAmount) {
                    revert VIR_NotVerified(vault, i);
                }
            } else if (item.itemType == ItemType.PUNKS) {
                if (IPunks(item.tokenAddress).punkIndexToAddress(item.tokenId) != vault) {
                    revert VIR_NotVerified(vault, i);
                }
            }

            // If all checks pass, add item to inventory, replacing anything with the same item hash
            // Does not encode itemType, meaning updates can be made if wrong item type was submitted
            inventoryForVault[vault][itemHash] = item;
            inventoryKeysForVault[vault].add(itemHash);

            emit Add(vault, msg.sender, itemHash);
        }
    }

    /**
     * @notice Remove items from the vault's registered inventory. If specified items
     *         are not registered as inventory, the function will not revert.
     *
     * @param vault                         The address of the vault.
     * @param items                         The list of items to remove.
     */
    function remove(address vault, Item[] calldata items) public override validate(msg.sender, vault) {
        uint256 numItems = items.length;

        if (numItems == 0) revert VIR_NoItems();
        if (numItems > MAX_ITEMS_PER_REGISTRATION) revert VIR_TooManyItems(MAX_ITEMS_PER_REGISTRATION);

        for (uint256 i = 0; i < numItems; i++) {
            bytes32 itemHash = _hash(items[i]);

            if (inventoryKeysForVault[vault].contains(itemHash)) {

                delete inventoryForVault[vault][itemHash];
                inventoryKeysForVault[vault].remove(itemHash);

                emit Remove(vault, msg.sender, itemHash);
            }

        }
    }

    /**
     * @notice Remove all items from the vault's registered inventory.
     *
     * @param vault                         The address of the vault.
     */
    function clear(address vault) public override validate(msg.sender, vault) {
        uint256 numItems = inventoryKeysForVault[vault].length();
        bytes32[] memory itemHashSet = new bytes32[](numItems);

        if (numItems > MAX_ITEMS_PER_REGISTRATION) revert VIR_TooManyItems(MAX_ITEMS_PER_REGISTRATION);

        // Clear vault lookup
        for (uint256 i = 0; i < numItems; i++) {
            bytes32 itemHash = inventoryKeysForVault[vault].at(i);

            delete inventoryForVault[vault][itemHash];
            itemHashSet[i] = itemHash;
        }

        // Remove keys
        for (uint256 i = 0; i < numItems; i++) {
            inventoryKeysForVault[vault].remove(itemHashSet[i]);
        }

        emit Clear(vault, msg.sender);
    }

    /**
     * @notice Add items to the vault's registered inventory, using permit. If specified items
     *         are not owned by the vault, add will revert.
     *
     * @param vault                         The address of the vault.
     * @param items                         The list of items to add.
     * @param deadline                      The maximum timestamp the signature is valid for.
     * @param v                             Component of the signature.
     * @param r                             Component of the signature.
     * @param s                             Component of the signature.
     */
    function addWithPermit(
        address vault,
        Item[] calldata items,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        uint256 tokenId = uint256(uint160(vault));
        address factory = OwnableERC721(vault).ownershipToken();
        address owner = IERC721(factory).ownerOf(tokenId);

        permit(
            owner,
            msg.sender,
            vault,
            deadline,
            v,
            r,
            s
        );

        add(vault, items);
    }

    /**
     * @notice Remove items from the vault's registered inventory, using permit. If specified items
     *         are not registered as inventory, the function will not revert.
     *
     * @param vault                         The address of the vault.
     * @param items                         The list of items to remove.
     * @param deadline                      The maximum timestamp the signature is valid for.
     * @param v                             Component of the signature.
     * @param r                             Component of the signature.
     * @param s                             Component of the signature.
     */
    function removeWithPermit(
        address vault,
        Item[] calldata items,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        uint256 tokenId = uint256(uint160(vault));
        address factory = OwnableERC721(vault).ownershipToken();
        address owner = IERC721(factory).ownerOf(tokenId);

        permit(
            owner,
            msg.sender,
            vault,
            deadline,
            v,
            r,
            s
        );

        remove(vault, items);
    }

    /**
     * @notice Remove all items from the vault's registered inventory, using permit.
     *
     * @param vault                         The address of the vault.
     * @param deadline                      The maximum timestamp the signature is valid for.
     * @param v                             Component of the signature.
     * @param r                             Component of the signature.
     * @param s                             Component of the signature.
     */
    function clearWithPermit(
        address vault,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        uint256 tokenId = uint256(uint160(vault));
        address factory = OwnableERC721(vault).ownershipToken();
        address owner = IERC721(factory).ownerOf(tokenId);

        permit(
            owner,
            msg.sender,
            vault,
            deadline,
            v,
            r,
            s
        );

        clear(vault);
    }

    // ========================================= VERIFICATION ==========================================

    /**
     * @notice Check each item in a vault's inventory against on-chain state,
     *         returning true if all items in inventory are still held by the vault,
     *         and false if otherwise.
     *
     * @param vault                         The address of the vault.
     *
     * @return verified                     Whether the vault inventory is still accurate.
     */
    function verify(address vault) external view override returns (bool) {
        uint256 numItems = inventoryKeysForVault[vault].length();

        for (uint256 i = 0; i < numItems; i++) {
            bytes32 itemHash = inventoryKeysForVault[vault].at(i);

            if (!_verifyItem(vault, inventoryForVault[vault][itemHash])) return false;
        }

        return true;
    }

    /**
     * @notice Check a specific item in the vault's inventory against on-chain state,
     *         returning true if all items in inventory are still held by the vault,
     *         and false if otherwise. Reverts if item not in inventory.
     *
     * @param vault                         The address of the vault.
     * @param item                          The item to verify.
     *
     * @return verified                     Whether the vault inventory is still accurate.
     */
    function verifyItem(address vault, Item memory item) external view override returns (bool) {
        bytes32 itemHash = _hash(item);

        if (!inventoryKeysForVault[vault].contains(itemHash)) {
            revert VIR_NotInInventory(vault, itemHash);
        }

        return _verifyItem(vault, item);
    }

    // ========================================= ENUMERATION ===========================================

    /**
     * @notice Return a list of items in the vault. Does not check for staleness.
     *
     * @param vault                         The address of the vault.
     *
     * @return items                        An array of items in the vault.
     */
    function enumerate(address vault) external view override returns (Item[] memory items) {
        uint256 numItems = inventoryKeysForVault[vault].length();
        items = new Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            bytes32 itemHash = inventoryKeysForVault[vault].at(i);

            items[i] = inventoryForVault[vault][itemHash];
        }
    }

    /**
     * @notice Return a list of items in the vault. Checks for staleness and reverts if
     *         a reported asset is no longer owned.
     *
     * @param vault                         The address of the vault.
     *
     * @return items                        An array of items in the vault.
     */
    function enumerateOrFail(address vault) external view override returns (Item[] memory items) {
        uint256 numItems = inventoryKeysForVault[vault].length();
        items = new Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            bytes32 itemHash = inventoryKeysForVault[vault].at(i);

            if (!_verifyItem(vault, inventoryForVault[vault][itemHash])) {
                revert VIR_NotVerified(vault, i);
            }

            items[i] = inventoryForVault[vault][itemHash];

        }
    }

    /**
     * @notice Return a list of lookup keys for items in the vault, which is each item's
     *         itemHash value. Does not check for staleness.
     *
     * @param vault                         The address of the vault.
     *
     * @return keys                         An array of lookup keys for all vault items.
     */
    function keys(address vault) external view override returns (bytes32[] memory) {
        return inventoryKeysForVault[vault].values();
    }

    /**
     * @notice Return the lookup key at the specified index. Does not check for staleness.
     *
     * @param vault                         The address of the vault.
     * @param index                         The index of the key to look up.
     *
     * @return key                          The key at the specified index.
     */
    function keyAtIndex(address vault, uint256 index) external view override returns (bytes32) {
        return inventoryKeysForVault[vault].at(index);
    }

    /**
     * @notice Return the item stored by the lookup key at the specified index.
     *         Does not check for staleness.
     *
     * @param vault                         The address of the vault.
     * @param index                         The index of the key to look up.
     *
     * @return item                         The item at the specified index.
     */
    function itemAtIndex(address vault, uint256 index) external view override returns (Item memory) {
        bytes32 itemHash = inventoryKeysForVault[vault].at(index);
        return inventoryForVault[vault][itemHash];
    }

    // ========================================= PERMISSIONS ===========================================

    /**
     * @notice Sets an approval for a vault. If approved, a caller is allowed to make updates
     *         to the vault's reported inventory. The caller itself must be the owner or approved
     *         for the vault's corresponding ownership token. Can unset an approval by sending
     *         the zero address as a target.
     *
     * @param vault                         The vault to set approval for.
     * @param target                        The address to set approval for.
     */
    function setApproval(address vault, address target) external override {
        address factory = OwnableERC721(vault).ownershipToken();
        _checkApproval(factory, vault, msg.sender);

        // Set approval, overwriting any previous
        // If zero, results in no approvals
        approved[vault] = target;

        emit SetApproval(vault, target);
    }

    /**
     * @notice Reports whether the target is an owner of the vault, or approved
     *         to report inventory on behalf of the vault. Note that this approval
     *         does NOT equate to a token approval.
     *
     * @param vault                         The vault to check approval for.
     * @param target                        The address to check approval for.
     *
     * @return isApproved                   Whether the target is approved for the vault.
     */
    function isOwnerOrApproved(address vault, address target) public view override returns (bool) {
        address factory = OwnableERC721(vault).ownershipToken();
        uint256 tokenId = uint256(uint160(vault));
        address owner = IERC721(factory).ownerOf(tokenId);

        return owner == target || approved[vault] == target;
    }

    /**
     * @notice Sets a global approval for an address, such that the address can
     *         update any vault. Can be used by protocol admins in order to
     *         smooth integration with other contracts which integrate with the reporter
     *         (like VaultDepositRouter).
     *
     * @param target                        The address to set approval for.
     * @param isApproved                    Whether the address should be approved.
     */
    function setGlobalApproval(address target, bool isApproved) external override onlyOwner {
        globalApprovals[target] = isApproved;
        emit SetGlobalApproval(target, isApproved);
    }

    /**
     * @notice Reports whether the target is has been put on the "global approval" list
     *         - an admin managed list for contracts which integrate with the reporter.
     *
     * @param target                        The address to check approval for.
     *
     * @return isApproved                   Whether the target is approved for the vault.
     */
    function isGloballyApproved(address target) public view override returns (bool) {
        return globalApprovals[target];
    }

    /**
     * @notice Allows the target to update inventory for a particular vault,
     *         given owner's signed approval. Note that, unlike token approvals,
     *         an inventory reporting approval cannot be "spent" - the signature
     *         will work for an unlimited number of applications until the deadline.
     *         Therefore unlike a token permit which is often spent before its
     *         deadline, an inventory permit should be considered unqualified approval
     *         until the deadline.
     *
     * @param owner                 The owner of the vault being permitted.
     * @param target                The address allowed to report inventory for the token.
     * @param vault                 The given vault for the permission.
     * @param deadline              The maximum timestamp the signature is valid for.
     * @param v                     Component of the signature.
     * @param r                     Component of the signature.
     * @param s                     Component of the signature.
     */
    function permit(
        address owner,
        address target,
        address vault,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        if (block.timestamp > deadline) revert VIR_PermitDeadlineExpired(deadline);
        address factory = OwnableERC721(vault).ownershipToken();
        _checkOwnership(factory, vault, owner);

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, target, vault, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);

        if (signer != owner) revert VIR_InvalidPermitSignature(signer);

        // Set approval, overwriting any previous
        // If zero, results in no approvals
        approved[vault] = target;
    }

    // =========================================== HELPERS =============================================

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     *
     * @return separator             The bytes for the domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev Read the Item struct and check owner/balance function according
     *      to item type.
     *
     * @param vault                         The address of the vault.
     * @param item                          The item to verify.
     *
     * @return verified                     Whether the vault inventory is still accurate.
     */
    // solhint-disable-next-line code-complexity
    function _verifyItem(address vault, Item memory item) internal view returns (bool) {
        if (item.itemType == ItemType.ERC_721) {
            if (IERC721(item.tokenAddress).ownerOf(item.tokenId) != vault) {
                return false;
            }
        } else if (item.itemType == ItemType.ERC_1155) {
            if (IERC1155(item.tokenAddress).balanceOf(vault, item.tokenId) < item.tokenAmount) {
                return false;
            }
        } else if (item.itemType == ItemType.ERC_20) {
            if (IERC20(item.tokenAddress).balanceOf(vault) < item.tokenAmount) {
                return false;
            }
        } else if (item.itemType == ItemType.PUNKS) {
            if (IPunks(item.tokenAddress).punkIndexToAddress(item.tokenId) != vault) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Hash the fields of the Item struct.
     *
     * @param item                          The item to hash.
     *
     * @return hash                         The digest of the hash.
     */
    function _hash(Item memory item) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(item.tokenAddress, item.tokenId, item.tokenAmount));
    }

    /**
     * @dev Consumes the nonce - returns the current value and increments.
     *
     * @param owner                 The address of the user to consume a nonce for.
     *
     * @return current              The current nonce, before incrementation.
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev Checks that the caller is owner or approved for the vault
     *      before any update action.
     *
     * @param caller                        The msg.sender.
     * @param vault                         The vault being called on.
     */
    modifier validate(address caller, address vault) {
        // If caller is not owner or approved for vault, then revert
        if (!isGloballyApproved(caller) && !isOwnerOrApproved(vault, caller)) revert VIR_NotApproved(vault, caller);

        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

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

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IVaultDepositRouter.sol";
import "../interfaces/IVaultInventoryReporter.sol";
import "../interfaces/IVaultFactory.sol";

abstract contract VaultOwnershipChecker {

    // ============= Errors ==============

    error VOC_ZeroAddress();
    error VOC_InvalidVault(address vault);
    error VOC_NotOwnerOrApproved(address vault, address caller);

    // ================ Ownership Check ================

    /**
     * @dev Validates that the caller is allowed to deposit to the specified vault (owner or approved),
     *      and that the specified vault exists. Reverts on failed validation.
     *
     * @param factory                       The vault ownership token for the specified vault.
     * @param vault                         The vault that will be deposited to.
     * @param caller                        The caller who wishes to deposit.
     */
    function _checkApproval(address factory, address vault, address caller) internal view {
        if (vault == address(0)) revert VOC_ZeroAddress();
        if (!IVaultFactory(factory).isInstance(vault)) revert VOC_InvalidVault(vault);

        uint256 tokenId = uint256(uint160(vault));
        address owner = IERC721(factory).ownerOf(tokenId);

        if (
            caller != owner
            && IERC721(factory).getApproved(tokenId) != caller
            && !IERC721(factory).isApprovedForAll(owner, caller)
        ) revert VOC_NotOwnerOrApproved(vault, caller);
    }

    /**
     * @dev Validates that the caller is directly the owner of the vault,
     *      and that the specified vault exists. Reverts on failed validation.
     *
     * @param factory                       The vault ownership token for the specified vault.
     * @param vault                         The vault that will be deposited to.
     * @param caller                        The caller who wishes to deposit.
     */
    function _checkOwnership(address factory, address vault, address caller) public view {
        if (vault == address(0)) revert VOC_ZeroAddress();
        if (!IVaultFactory(factory).isInstance(vault)) revert VOC_InvalidVault(vault);

        uint256 tokenId = uint256(uint160(vault));
        address owner = IERC721(factory).ownerOf(tokenId);

        if (caller != owner) revert VOC_NotOwnerOrApproved(vault, caller);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { OERC721_CallerNotOwner } from "../errors/Vault.sol";

/**
 * @title OwnableERC721
 * @author Non-Fungible Technologies, Inc.
 *
 * Uses ERC721 ownership for access control to a set of contracts.
 * Ownership of underlying contract determined by ownership of a token ID,
 * where the token ID converts to an on-chain address.
 */
abstract contract OwnableERC721 {
    // ============================================ STATE ==============================================

    /// @dev The ERC721 token that contract owners should have ownership of.
    address public ownershipToken;

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Specifies the owner of the underlying token ID, derived
     *         from the contract address of the contract implementing.
     *
     * @return ownerAddress         The owner of the underlying token derived from
     *                              the calling address.
     */
    function owner() public view virtual returns (address ownerAddress) {
        return IERC721(ownershipToken).ownerOf(uint256(uint160(address(this))));
    }

    // ============================================ HELPERS =============================================

    /**
     * @dev Set the ownership token - the ERC721 that specified who controls
     *      defined addresses.
     */
    function _setNFT(address _ownershipToken) internal {
        ownershipToken = _ownershipToken;
    }

    /**
     * @dev Similar to Ownable - checks the method is being called by the owner,
     *      where the owner is defined by the token ID in the ownership token which
     *      maps to the calling contract address.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert OERC721_CallerNotOwner(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVaultInventoryReporter {
    // ============= Events ==============

    event Add(address indexed vault, address indexed reporter, bytes32 itemHash);
    event Remove(address indexed vault, address indexed reporter, bytes32 itemHash);
    event Clear(address indexed vault, address indexed reporter);
    event SetApproval(address indexed vault, address indexed target);
    event SetGlobalApproval(address indexed target, bool isApproved);

    // ============= Errors ==============

    error VIR_NoItems();
    error VIR_TooManyItems(uint256 maxItems);
    error VIR_InvalidRegistration(address vault, uint256 itemIndex);
    error VIR_NotVerified(address vault, uint256 itemIndex);
    error VIR_NotInInventory(address vault, bytes32 itemHash);
    error VIR_NotApproved(address vault, address target);
    error VIR_PermitDeadlineExpired(uint256 deadline);
    error VIR_InvalidPermitSignature(address signer);

    // ============= Data Types ==============

    enum ItemType {
        ERC_721,
        ERC_1155,
        ERC_20,
        PUNKS
    }

    struct Item {
        ItemType itemType;
        address tokenAddress;
        uint256 tokenId;                // Not used for ERC20 items - will be ignored
        uint256 tokenAmount;            // Not used for ERC721 items - will be ignored
    }

    // ================ Inventory Operations ================

    function add(address vault, Item[] calldata items) external;

    function remove(address vault, Item[] calldata items) external;

    function clear(address vault) external;

    function addWithPermit(
        address vault,
        Item[] calldata items,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeWithPermit(
        address vault,
        Item[] calldata items,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function clearWithPermit(
        address vault,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address owner,
        address target,
        address vault,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // ================ Verification ================

    function verify(address vault) external view returns (bool);

    function verifyItem(address vault, Item calldata item) external view returns (bool);

    // ================ Enumeration ================

    function enumerate(address vault) external view returns (Item[] memory);

    function enumerateOrFail(address vault) external view returns (Item[] memory);

    function keys(address vault) external view returns (bytes32[] memory);

    function keyAtIndex(address vault, uint256 index) external view returns (bytes32);

    function itemAtIndex(address vault, uint256 index) external view returns (Item memory);

    // ================ Permissions ================

    function setApproval(address vault, address target) external;

    function isOwnerOrApproved(address vault, address target) external view returns (bool);

    function setGlobalApproval(address caller, bool isApproved) external;

    function isGloballyApproved(address target) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IPunks {
    function balanceOf(address owner) external view returns (uint256);

    function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

    function buyPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.11;

interface IVaultDepositRouter {
    // ============= Errors ==============

    error VDR_ZeroAddress();
    error VDR_InvalidVault(address vault);
    error VDR_NotOwnerOrApproved(address vault, address caller);
    error VDR_BatchLengthMismatch();

    // ================ Deposit Operations ================

    function depositERC20(address vault, address token, uint256 amount) external;

    function depositERC20Batch(address vault, address[] calldata tokens, uint256[] calldata amounts) external;

    function depositERC721(address vault, address token, uint256 id) external;

    function depositERC721Batch(address vault, address[] calldata tokens, uint256[] calldata ids) external;

    function depositERC1155(address vault, address token, uint256 id, uint256 amount) external;

    function depositERC1155Batch(address vault, address[] calldata tokens, uint256[] calldata ids, uint256[] calldata amounts) external;

    function depositPunk(address vault, address token, uint256 id) external;

    function depositPunkBatch(address vault, address[] calldata tokens, uint256[] calldata ids) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IVaultFactory {
    // ============= Events ==============

    event VaultCreated(address vault, address to);

    // ================ View Functions ================

    function isInstance(address instance) external view returns (bool validity);

    function instanceCount() external view returns (uint256);

    function instanceAt(uint256 tokenId) external view returns (address);

    function instanceAtIndex(uint256 index) external view returns (address);

    // ================ Factory Operations ================

    function initializeBundle(address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title VaultErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for vault contracts used by the protocol.
 * All errors prefixed by the contract that throws them (e.g., "AV_" for Asset Vault).
 * Errors located in one place to make it possible to holistically look at all
 * asset vault failure cases.
 */

// ==================================== Asset Vault ======================================
/// @notice All errors prefixed with AV_, to separate from other contracts in the protocol.

/**
 * @notice Vault withdraws must be enabled.
 */
error AV_WithdrawsDisabled();

/**
 * @notice Vault withdraws enabled.
 */
error AV_WithdrawsEnabled();

/**
 * @notice Asset vault already initialized.
 *
 * @param ownershipToken                    Caller of initialize function in asset vault contract.
 */
error AV_AlreadyInitialized(address ownershipToken);

/**
 * @notice Call disallowed.
 *
 * @param caller                             Msg.sender of the function call.
 */
error AV_CallDisallowed(address caller);

/**
 * @notice Call disallowed.
 *
 * @param to                                The contract address to call.
 * @param data                              The data to call the contract with.
 */
error AV_NonWhitelistedCall(address to, bytes4 data);

// ==================================== Ownable ERC721 ======================================
/// @notice All errors prefixed with OERC721_, to separate from other contracts in the protocol.

/**
 * @notice Function caller is not the owner.
 *
 * @param caller                             Msg.sender of the function call.
 */
error OERC721_CallerNotOwner(address caller);

// ==================================== Vault Factory ======================================
/// @notice All errors prefixed with VF_, to separate from other contracts in the protocol.

/**
 * @notice Template contract is invalid.
 *
 * @param template                           Template contract to be cloned.
 */
error VF_InvalidTemplate(address template);

/**
 * @notice Global index out of bounds.
 *
 * @param tokenId                            AW-V2 tokenId of the asset vault.
 */
error VF_TokenIdOutOfBounds(uint256 tokenId);

/**
 * @notice Cannot transfer with withdraw enabled.
 *
 * @param tokenId                            AW-V2 tokenId of the asset vault.
 */
error VF_NoTransferWithdrawEnabled(uint256 tokenId);