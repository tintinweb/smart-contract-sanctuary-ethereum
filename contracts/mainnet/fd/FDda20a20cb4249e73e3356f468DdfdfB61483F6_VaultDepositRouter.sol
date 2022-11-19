// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./VaultOwnershipChecker.sol";
import "../interfaces/IVaultDepositRouter.sol";
import "../interfaces/IVaultInventoryReporter.sol";
import "../interfaces/IVaultFactory.sol";
import "../external/interfaces/IPunks.sol";

/**
 * @title VaultInventoryReporter
 * @author Non-Fungible Technologies, Inc.
 *
 * The VaultInventoryReporter contract is a helper contract that
 * works with Arcade asset vaults and the vault inventory reporter.
 * By depositing to asset vaults by calling the functions in this contract,
 * inventory registration will be automatically updated.
 */
contract VaultDepositRouter is IVaultDepositRouter, VaultOwnershipChecker {
    using SafeERC20 for IERC20;

    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    address public immutable factory;
    IVaultInventoryReporter public immutable reporter;

    // ========================================= CONSTRUCTOR ===========================================

    constructor(address _factory, address _reporter) {
        if (_factory == address(0)) revert VDR_ZeroAddress();
        if (_reporter == address(0)) revert VDR_ZeroAddress();

        factory = _factory;
        reporter = IVaultInventoryReporter(_reporter);
    }

    // ====================================== DEPOSIT OPERATIONS ========================================

    /**
     * @notice Deposit an ERC20 token to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param amount                        The amount of tokens to deposit.
     */
    function depositERC20(
        address vault,
        address token,
        uint256 amount
    ) external override validate(vault, msg.sender) {
        IERC20(token).safeTransferFrom(msg.sender, vault, amount);

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);

        items[0] = IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.ERC_20,
            tokenAddress: token,
            tokenId: 0,
            tokenAmount: amount
        });

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit multiple ERC20 tokens to the vault, registering inventory on the reporter
     *         simultaneously.
     *
     * @param vault                          The vault to deposit to.
     * @param tokens                         The tokens to deposit.
     * @param amounts                        The amount of tokens to deposit, for each token.
     */
    function depositERC20Batch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != amounts.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            IERC20(token).safeTransferFrom(msg.sender, vault, amount);

            items[i] = IVaultInventoryReporter.Item({
                itemType: IVaultInventoryReporter.ItemType.ERC_20,
                tokenAddress: token,
                tokenId: 0,
                tokenAmount: amount
            });
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit an ERC721 token to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     */
    function depositERC721(
        address vault,
        address token,
        uint256 id
    ) external override validate(vault, msg.sender) {
        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);

        items[0] = _depositERC721(vault, token, id);

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit ERC721 tokens to the vault, registering inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param tokens                        The token to deposit.
     * @param ids                           The ID of the token to deposit, for each token.
     */
    function depositERC721Batch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata ids
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != ids.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            items[i] = _depositERC721(vault, tokens[i], ids[i]);
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit an ERC1155 token to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     * @param amount                        The amount of tokens to deposit.
     */
    function depositERC1155(
        address vault,
        address token,
        uint256 id,
        uint256 amount
    ) external override validate(vault, msg.sender) {
        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);
        items[0] = _depositERC1155(vault, token, id, amount);

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit ERC1155 tokens to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param tokens                        The token to deposit.
     * @param ids                           The ID of the tokens to deposit.
     * @param amounts                       The amount of tokens to deposit, for each token.
     */
    function depositERC1155Batch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != ids.length) revert VDR_BatchLengthMismatch();
        if (numItems != amounts.length) revert VDR_BatchLengthMismatch();
        if (ids.length != amounts.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            items[i] = _depositERC1155(vault, tokens[i], ids[i], amounts[i]);
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit a CryptoPunk to the vault, registering its inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     */
    function depositPunk(
        address vault,
        address token,
        uint256 id
    ) external override validate(vault, msg.sender) {
        IPunks(token).buyPunk(id);
        IPunks(token).transferPunk(vault, id);

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](1);

        items[0] = IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.PUNKS,
            tokenAddress: token,
            tokenId: id,
            tokenAmount: 0
        });

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    /**
     * @notice Deposit CryptoPunks to the vault, registering inventory on the reporter
     *         simultaneously.
     *
     * @param vault                         The vault to deposit to.
     * @param tokens                        The token to deposit.
     * @param ids                           The ID of the tokens to deposit.
     */
    function depositPunkBatch(
        address vault,
        address[] calldata tokens,
        uint256[] calldata ids
    ) external override validate(vault, msg.sender) {
        uint256 numItems = tokens.length;
        if (numItems != ids.length) revert VDR_BatchLengthMismatch();

        IVaultInventoryReporter.Item[] memory items = new IVaultInventoryReporter.Item[](numItems);

        for (uint256 i = 0; i < numItems; i++) {
            address token = tokens[i];
            uint256 id = ids[i];

            IPunks(token).buyPunk(id);
            IPunks(token).transferPunk(vault, id);

            items[i] = IVaultInventoryReporter.Item({
                itemType: IVaultInventoryReporter.ItemType.PUNKS,
                tokenAddress: token,
                tokenId: id,
                tokenAmount: 0
            });
        }

        reporter.add(vault, items);

        // No events because both token and reporter will emit
    }

    // ============================================ HELPERS =============================================

    /**
     * @dev Collect an ERC1155 from the caller, and return the Item struct.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     * @param amount                        The amount of tokens to deposit.
     *
     * @return item                         The Item struct for the asset collected.
     */
    function _depositERC1155(
        address vault,
        address token,
        uint256 id,
        uint256 amount
    ) internal returns (IVaultInventoryReporter.Item memory) {
        IERC1155(token).safeTransferFrom(msg.sender, vault, id, amount, "");

        return IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.ERC_1155,
            tokenAddress: token,
            tokenId: id,
            tokenAmount: amount
        });
    }

    /**
     * @dev Collect an ERC721 from the caller, and return the Item struct.
     *
     * @param vault                         The vault to deposit to.
     * @param token                         The token to deposit.
     * @param id                            The ID of the token to deposit.
     *
     * @return item                         The Item struct for the asset collected.
     */
    function _depositERC721(
        address vault,
        address token,
        uint256 id
    ) internal returns (IVaultInventoryReporter.Item memory) {
        IERC721(token).safeTransferFrom(msg.sender, vault, id);

        return IVaultInventoryReporter.Item({
            itemType: IVaultInventoryReporter.ItemType.ERC_721,
            tokenAddress: token,
            tokenId: id,
            tokenAmount: 0
        });
    }

    /**
     * @dev Validates that the caller is allowed to deposit to the specified vault (owner or approved),
     *      and that the specified vault exists. Reverts on failed validation.
     *
     * @param vault                         The vault that will be deposited to.
     * @param caller                        The caller who wishes to deposit.
     */
    modifier validate(address vault, address caller) {
        _checkApproval(factory, vault, caller);

        _;
    }
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IVaultDepositRouter.sol";
import "../interfaces/IVaultInventoryReporter.sol";
import "../interfaces/IVaultFactory.sol";

/**
 * @title VaultOwnershipChecker
 * @author Non-Fungible Technologies, Inc.
 *
 * This abstract contract contains utility functions for checking AssetVault
 * ownership or approval, which is needed for many contracts which work with vaults.
 */
abstract contract VaultOwnershipChecker {

    // ============= Errors ==============

    error VOC_ZeroAddress();
    error VOC_InvalidVault(address vault);
    error VOC_NotOwnerOrApproved(address vault, address owner, address caller);

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
        ) revert VOC_NotOwnerOrApproved(vault, owner, caller);
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

        if (caller != owner) revert VOC_NotOwnerOrApproved(vault, owner, caller);
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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