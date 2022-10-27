// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CallWhitelistApprovals.sol";
import "../interfaces/ICallDelegator.sol";
import "../interfaces/IAssetVault.sol";
import "../external/interfaces/IPunks.sol";
import "./OwnableERC721.sol";

import { AV_WithdrawsDisabled, AV_WithdrawsEnabled, AV_AlreadyInitialized, AV_CallDisallowed, AV_NonWhitelistedCall, AV_NonWhitelistedApproval } from "../errors/Vault.sol";

/**
 * @title AssetVault
 * @author Non-Fungible Technologies, Inc.
 *
 * The Asset Vault is a vault for the storage of collateralized assets.
 * Designed for one-time use, like a piggy bank. Once withdrawals are enabled,
 * and the bank is broken, the vault can no longer be used or transferred.
 *
 * It starts in a deposit-only state. Funds cannot be withdrawn at this point. When
 * the owner calls "enableWithdraw()", the state is set to a withdrawEnabled state.
 * Withdraws cannot be disabled once enabled. This restriction protects integrations
 * and purchasers of AssetVaults from unexpected withdrawal and frontrunning attacks.
 * For example: someone buys an AV assuming it contains token X, but I withdraw token X
 * immediately before the sale concludes.
 *
 * @dev Asset Vaults support arbitrary external calls by either:
 *     - the current owner of the vault
 *     - someone who the current owner "delegates" through the ICallDelegator interface
 *
 * This is to enable airdrop claims by borrowers during loans and other forms of NFT utility.
 * In practice, LoanCore delegates to the borrower during the period of an open loan.
 * Arcade.xyz maintains an allowed and restricted list of calls to balance between utility and security.
 */
contract AssetVault is IAssetVault, OwnableERC721, Initializable, ERC1155Holder, ERC721Holder, ReentrancyGuard {
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IERC20;

    // ============================================ STATE ==============================================

    /// @notice True if withdrawals are allowed out of this vault.
    /// @dev Note once set to true, it cannot be reverted back to false.
    bool public override withdrawEnabled;

    /// @notice Whitelist contract to determine if a given external call is allowed.
    ICallWhitelist public override whitelist;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @dev Initializes values so initialize cannot be called on template.
     */
    constructor() {
        withdrawEnabled = true;
        OwnableERC721._setNFT(msg.sender);
    }

    // ========================================== INITIALIZER ===========================================

    /**
     * @notice Initializes the contract, used on clone deployments. In practice,
     *         always called by the VaultFactory contract.
     *
     * @param _whitelist            The contract maintaining the whitelist of allowed
     *                              arbitrary calls.
     */
    function initialize(address _whitelist) external override initializer {
        if (withdrawEnabled || ownershipToken != address(0)) revert AV_AlreadyInitialized(ownershipToken);
        // set ownership to inherit from the factory who deployed us
        // The factory should have a tokenId == uint256(address(this))
        // whose owner has ownership control over this contract
        OwnableERC721._setNFT(msg.sender);
        whitelist = ICallWhitelist(_whitelist);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @inheritdoc OwnableERC721
     */
    function owner() public view override returns (address ownerAddress) {
        return OwnableERC721.owner();
    }

    // ===================================== WITHDRAWAL OPERATIONS ======================================

    /**
     * @notice Enables withdrawals on the vault. Irreversible. Caller must be the
     *         owner of the underlying ownership NFT.
     *
     * @dev Any integration should be aware that a withdraw-enabled vault cannot
     *      be transferred (will revert).
     *
     */
    function enableWithdraw() external override onlyOwner onlyWithdrawDisabled {
        withdrawEnabled = true;
        emit WithdrawEnabled(msg.sender);
    }

    /**
     * @notice Withdraw entire balance of a given ERC20 token from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param token                 The ERC20 token to withdraw.
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawERC20(address token, address to) external override onlyOwner onlyWithdrawEnabled {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, balance);
        emit WithdrawERC20(msg.sender, token, to, balance);
    }

    /**
     * @notice Withdraw entire balance of a given ERC20 token from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner. The specified token must
     *         exist and be owned by this contract.
     *
     * @param token                 The token to withdraw.
     * @param tokenId               The ID of the NFT to withdraw.
     * @param to                    The recipient of the withdrawn token.
     *
     */
    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
        emit WithdrawERC721(msg.sender, token, to, tokenId);
    }

    /**
     * @notice Withdraw entire balance of a given ERC1155 token from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param token                 The ERC1155 token to withdraw.
     * @param tokenId               The ID of the token to withdraw.
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        uint256 balance = IERC1155(token).balanceOf(address(this), tokenId);
        IERC1155(token).safeTransferFrom(address(this), to, tokenId, balance, "");
        emit WithdrawERC1155(msg.sender, token, to, tokenId, balance);
    }

    /**
     * @notice Withdraw entire balance of ETH from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param to                    The recipient of the withdrawn funds.
     */
    function withdrawETH(address to) external override onlyOwner onlyWithdrawEnabled nonReentrant {
        // perform transfer
        uint256 balance = address(this).balance;
        payable(to).sendValue(balance);
        emit WithdrawETH(msg.sender, to, balance);
    }

    /**
     * @notice Withdraw cryptoPunk from the vault.
     *         The vault must be in a "withdrawEnabled" state (non-transferrable),
     *         and the caller must be the owner.
     *
     * @param punks                 The CryptoPunk contract address.
     * @param punkIndex             The index of the CryptoPunk to withdraw (i.e. token ID).
     * @param to                    The recipient of the withdrawn punk.
     */
    function withdrawPunk(
        address punks,
        uint256 punkIndex,
        address to
    ) external override onlyOwner onlyWithdrawEnabled {
        IPunks(punks).transferPunk(to, punkIndex);
        emit WithdrawPunk(msg.sender, punks, to, punkIndex);
    }

    // ====================================== UTILITY OPERATIONS ========================================

    /**
     * @notice Call a function on an external contract. Intended for claiming airdrops
     *         and other forms of NFT utility. All allowed calls are whitelist by the
     *         "whitelist" contract. The vault must have withdrawals disabled, and the caller
     *         must either be the owner, or the owner must have explicitly
     *         delegated this ability to the caller through ICallDelegator interface.
     *
     * @param to                    The contract address to call.
     * @param data                  The data to call the contract with.
     */
    function call(address to, bytes calldata data) external override onlyWithdrawDisabled nonReentrant {
        if (msg.sender != owner() && !ICallDelegator(owner()).canCallOn(msg.sender, address(this)))
            revert AV_CallDisallowed(msg.sender);

        if (!whitelist.isWhitelisted(to, bytes4(data[:4]))) revert AV_NonWhitelistedCall(to, bytes4(data[:4]));

        to.functionCall(data);

        emit Call(msg.sender, to, data);
    }

    /**
     * @notice Approve a token for spending by an external contract. Note that any token
     *         approved in the whitelist does not make good collateral, because the allowed
     *         spender may be able to withdraw it from the vault.
     *
     * @param token                 The token to approve.
     * @param spender               The approved spender.
     * @param amount                The amount to approve.
     */
    function callApprove(address token, address spender, uint256 amount) external override onlyWithdrawDisabled nonReentrant {
        if (msg.sender != owner() && !ICallDelegator(owner()).canCallOn(msg.sender, address(this)))
            revert AV_CallDisallowed(msg.sender);

        if (!CallWhitelistApprovals(address(whitelist)).isApproved(token, spender)) revert AV_NonWhitelistedApproval(token, spender);

        // Do approval
        IERC20(token).approve(spender, amount);

        emit Approve(msg.sender, token, spender, amount);
    }

    // ============================================ HELPERS =============================================

    /**
     * @dev For methods only callable with withdraws enabled (all withdrawal operations).
     */
    modifier onlyWithdrawEnabled() {
        if (!withdrawEnabled) revert AV_WithdrawsDisabled();
        _;
    }

    /**
     * @dev For methods only callable with withdraws disabled (call operations and enabling withdraws).
     */
    modifier onlyWithdrawDisabled() {
        if (withdrawEnabled) revert AV_WithdrawsEnabled();
        _;
    }

    /**
     * @dev Fallback "receive Ether" function. Contract can hold Ether
     *      which can be accessed using withdrawETH.
     */
    receive() external payable {}
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CallWhitelist.sol";
import "../interfaces/IERC721Permit.sol";

/**
 * @title CallWhitelistApprovals
 * @author Non-Fungible Technologies, Inc.
 *
 * Adds approvals functionality to CallWhitelist. Certain spenders
 * can be approved for tokens on vaults, with the requisite ability
 * to withdraw. Should not be used for tokens acting as collateral.
 *
 * The contract owner can add or remove approved token/spender pairs.
 */
contract CallWhitelistApprovals is CallWhitelist {
    event ApprovalSet(address indexed caller, address indexed token, address indexed spender, bool isApproved);

    // ============================================ STATE ==============================================

    // ================= Whitelist State ==================

    /// @notice Approved spenders of vault tokens.
    /// @dev    token -> spender -> isApproved
    mapping(address => mapping(address => bool)) private approvals;

    /**
     * @notice Returns true if the given spender is approved to spend the given token.
     *
     * @param token                The token approval to check.
     * @param spender              The token spender.
     *
     * @return isApproved          True if approved, else false.
     */
    function isApproved(address token, address spender) public view returns (bool) {
        return approvals[token][spender];
    }

    // ======================================== UPDATE OPERATIONS =======================================

    /**
     * @notice Sets approval status of a given token for a spender. Note that this is
     *         NOT a token approval - it is permission to create a token approval from
     *         the asset vault.
     *
     * @param token                The token approval to set.
     * @param spender              The token spender.
     * @param _isApproved          Whether the spender should be approved.
     */
    function setApproval(address token, address spender, bool _isApproved) external onlyOwner {
        approvals[token][spender] = _isApproved;
        emit ApprovalSet(msg.sender, token, spender, _isApproved);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICallDelegator {
    // ============== View Functions ==============

    function canCallOn(address caller, address vault) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ICallWhitelist.sol";

interface IAssetVault {
    // ============= Events ==============

    event WithdrawEnabled(address operator);
    event WithdrawERC20(address indexed operator, address indexed token, address recipient, uint256 amount);
    event WithdrawERC721(address indexed operator, address indexed token, address recipient, uint256 tokenId);
    event WithdrawPunk(address indexed operator, address indexed token, address recipient, uint256 tokenId);

    event WithdrawERC1155(
        address indexed operator,
        address indexed token,
        address recipient,
        uint256 tokenId,
        uint256 amount
    );

    event WithdrawETH(address indexed operator, address indexed recipient, uint256 amount);
    event Call(address indexed operator, address indexed to, bytes data);
    event Approve(address indexed operator, address indexed token, address indexed spender, uint256 amount);

    // ================= Initializer ==================

    function initialize(address _whitelist) external;

    // ================ View Functions ================

    function withdrawEnabled() external view returns (bool);

    function whitelist() external view returns (ICallWhitelist);

    // ================ Withdrawal Operations ================

    function enableWithdraw() external;

    function withdrawERC20(address token, address to) external;

    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawETH(address to) external;

    function withdrawPunk(
        address punks,
        uint256 punkIndex,
        address to
    ) external;

    // ================ Utility Operations ================

    function call(address to, bytes memory data) external;

    function callApprove(address token, address spender, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IPunks {
    function balanceOf(address owner) external view returns (uint256);

    function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

    function buyPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;
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

/**
 * @notice Approval disallowed.
 *
 * @param token                             The token to approve.
 * @param spender                           The spender to approve.
 */
error AV_NonWhitelistedApproval(address token, address spender);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ICallWhitelist.sol";
import "../interfaces/IERC721Permit.sol";

/**
 * @title CallWhitelist
 * @author Non-Fungible Technologies, Inc.
 *
 * Maintains a whitelist for calls that can be made from an AssetVault.
 * Intended to be used to allow for "claim" and other-utility based
 * functions while an asset is being held in escrow. Some functions
 * are blacklisted, e.g. transfer functions, to prevent callers from
 * being able to circumvent withdrawal rules for escrowed assets.
 * Whitelists are specified in terms of "target contract" (callee)
 * and function selector.
 *
 * The contract owner can add or remove items from the whitelist.
 */
contract CallWhitelist is Ownable, ICallWhitelist {
    using SafeERC20 for IERC20;
    // ============================================ STATE ==============================================

    // ============= Global Immutable State ==============

    /**
     * @dev Global blacklist for transfer functions.
     */
    bytes4 private constant ERC20_TRANSFER = IERC20.transfer.selector;
    bytes4 private constant ERC20_ERC721_APPROVE = IERC20.approve.selector;
    bytes4 private constant ERC20_ERC721_TRANSFER_FROM = IERC20.transferFrom.selector;

    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_DATA = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC721_ERC1155_SET_APPROVAL = IERC721.setApprovalForAll.selector;

    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = IERC1155.safeTransferFrom.selector;
    bytes4 private constant ERC1155_SAFE_BATCH_TRANSFER_FROM = IERC1155.safeBatchTransferFrom.selector;

    // ================= Whitelist State ==================

    /**
     * @notice Whitelist of callable functions on contracts. Maps addresses that
     *         can be called to function selectors which can be called on it.
     *         For example, if we want to allow function call 0x0000 on a contract
     *         at 0x1111, the mapping will contain whitelist[0x1111][0x0000] = true.
     */
    mapping(address => mapping(bytes4 => bool)) private whitelist;

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns true if the given function on the given callee is whitelisted.
     *
     * @param callee                The contract that is intended to be called.
     * @param selector              The function selector that is intended to be called.
     *
     * @return isWhitelisted        True if whitelisted, else false.
     */
    function isWhitelisted(address callee, bytes4 selector) external view override returns (bool) {
        return !isBlacklisted(selector) && whitelist[callee][selector];
    }

    /**
     * @notice Returns true if the given function selector is on the global blacklist.
     *         Blacklisted function selectors cannot be called on any contract.
     *
     * @param selector              The function selector to check.
     *
     * @return isBlacklisted        True if blacklisted, else false.
     */
    function isBlacklisted(bytes4 selector) public pure override returns (bool) {
        return
            selector == ERC20_TRANSFER ||
            selector == ERC20_ERC721_APPROVE ||
            selector == ERC20_ERC721_TRANSFER_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM ||
            selector == ERC721_SAFE_TRANSFER_FROM_DATA ||
            selector == ERC721_ERC1155_SET_APPROVAL ||
            selector == ERC1155_SAFE_TRANSFER_FROM ||
            selector == ERC1155_SAFE_BATCH_TRANSFER_FROM;
    }

    // ======================================== UPDATE OPERATIONS =======================================

    /**
     * @notice Add the given callee and selector to the whitelist. Can only be called by owner.
     * @dev    A blacklist supersedes a whitelist, so should not add blacklisted selectors.
     *
     * @param callee                The contract to whitelist.
     * @param selector              The function selector to whitelist.
     */
    function add(address callee, bytes4 selector) external override onlyOwner {
        whitelist[callee][selector] = true;
        emit CallAdded(msg.sender, callee, selector);
    }

    /**
     * @notice Remove the given calle and selector from the whitelist. Can only be called by owner.
     *
     * @param callee                The contract to whitelist.
     * @param selector              The function selector to whitelist.
     */
    function remove(address callee, bytes4 selector) external override onlyOwner {
        whitelist[callee][selector] = false;
        emit CallRemoved(msg.sender, callee, selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Permit is IERC721 {
    // ================ Permit Functionality ================

    function permit(
        address owner,
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ================ View Functions ================

    function nonces(address owner) external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

interface ICallWhitelist {
    // ============= Events ==============

    event CallAdded(address operator, address callee, bytes4 selector);
    event CallRemoved(address operator, address callee, bytes4 selector);

    // ================ View Functions ================

    function isWhitelisted(address callee, bytes4 selector) external view returns (bool);

    function isBlacklisted(bytes4 selector) external view returns (bool);

    // ================ Update Operations ================

    function add(address callee, bytes4 selector) external;

    function remove(address callee, bytes4 selector) external;
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