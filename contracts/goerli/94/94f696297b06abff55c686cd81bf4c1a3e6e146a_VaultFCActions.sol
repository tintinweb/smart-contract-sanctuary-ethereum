/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



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
}// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)



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
}// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)




// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)



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
interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function lock() external;
}// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)



/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)





/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IFIATExcl {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

interface IFIAT is IFIATExcl, IERC20, IERC20Permit, IERC20Metadata {}

interface IMoneta {
    function codex() external view returns (ICodex);

    function fiat() external view returns (IFIAT);

    function live() external view returns (uint256);

    function lock() external;

    function enter(address user, uint256 amount) external;

    function exit(address user, uint256 amount) external;
}// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */
interface IPriceFeed {
    function peek() external returns (bytes32, bool);

    function read() external view returns (bytes32);
}

interface ICollybus {
    function vaults(address) external view returns (uint128, uint128);

    function spots(address) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function rateIds(address, uint256) external view returns (uint256);

    function redemptionPrice() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external;

    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external;

    function updateDiscountRate(uint256 rateId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;

    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view returns (uint256 price);

    function lock() external;
}

interface IVault {
    function codex() external view returns (ICodex);

    function collybus() external view returns (ICollybus);

    function token() external view returns (address);

    function tokenScale() external view returns (uint256);

    function underlierToken() external view returns (address);

    function underlierScale() external view returns (uint256);

    function vaultType() external view returns (bytes32);

    function live() external view returns (uint256);

    function lock() external;

    function setParam(bytes32 param, address data) external;

    function maturity(uint256 tokenId) external returns (uint256);

    function fairPrice(
        uint256 tokenId,
        bool net,
        bool face
    ) external view returns (uint256);

    function enter(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;

    function exit(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;
}

interface IVaultFC is IVault {

    function currencyId() external view returns (uint256);

    function tenor() external view returns (uint256);

    function redeemAndExit(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external returns (uint256 redeemed);

    function redeems(
        uint256 tokenId,
        uint256 amount,
        uint256 cTokenExRate
    ) external view returns (uint256);
}
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)





/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)





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

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
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
interface IDebtAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function tokenToSellBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function aer() external view returns (address);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(
        address recipient,
        uint256 tokensToSell,
        uint256 bid
    ) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 tokensToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock() external;

    function cancelAuction(uint256 id) external;
}
interface ISurplusAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(uint256 creditToSell, uint256 bid) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 creditToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock(uint256 credit) external;

    function cancelAuction(uint256 id) external;
}

interface IAer {
    function codex() external view returns (ICodex);

    function surplusAuction() external view returns (ISurplusAuction);

    function debtAuction() external view returns (IDebtAuction);

    function debtQueue(uint256) external view returns (uint256);

    function queuedDebt() external view returns (uint256);

    function debtOnAuction() external view returns (uint256);

    function auctionDelay() external view returns (uint256);

    function debtAuctionSellSize() external view returns (uint256);

    function debtAuctionBidSize() external view returns (uint256);

    function surplusAuctionSellSize() external view returns (uint256);

    function surplusBuffer() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function queueDebt(uint256 debt) external;

    function unqueueDebt(uint256 queuedAt) external;

    function settleDebtWithSurplus(uint256 debt) external;

    function settleAuctionedDebt(uint256 debt) external;

    function startDebtAuction() external returns (uint256 auctionId);

    function startSurplusAuction() external returns (uint256 auctionId);

    function transferCredit(address to, uint256 credit) external;

    function lock() external;
}

interface IPublican {
    function vaults(address vault) external view returns (uint256, uint256);

    function codex() external view returns (ICodex);

    function aer() external view returns (IAer);

    function baseInterest() external view returns (uint256);

    function init(address vault) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function virtualRate(address vault) external returns (uint256 rate);

    function collect(address vault) external returns (uint256 rate);
}
/// @title VaultActions
/// @notice A set of base vault actions to inherited from
abstract contract VaultActions {
    /// ======== Custom Errors ======== ///

    error VaultActions__exitMoneta_zeroUserAddress();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable codex;
    /// @notice Moneta
    IMoneta public immutable moneta;
    /// @notice FIAT token
    IFIAT public immutable fiat;
    /// @notice Publican
    IPublican public immutable publican;

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_
    ) {
        codex = ICodex(codex_);
        moneta = IMoneta(moneta_);
        fiat = IFIAT(fiat_);
        publican = IPublican(publican_);
    }

    /// @notice Sets `amount` as the allowance of `spender` over the UserProxy's FIAT
    /// @param spender Address of the spender
    /// @param amount Amount of tokens to approve [wad]
    function approveFIAT(address spender, uint256 amount) external {
        fiat.approve(spender, amount);
    }

    /// @dev Redeems FIAT for internal credit
    /// @param to Address of the recipient
    /// @param amount Amount of FIAT to exit [wad]
    function exitMoneta(address to, uint256 amount) public {
        if (to == address(0)) revert VaultActions__exitMoneta_zeroUserAddress();

        // proxy needs to delegate ability to transfer internal credit on its behalf to Moneta first
        if (codex.delegates(address(this), address(moneta)) != 1) codex.grantDelegate(address(moneta));

        moneta.exit(to, amount);
    }

    /// @dev The user needs to previously call approveFIAT with the address of Moneta as the spender
    /// @param from Address of the account which provides FIAT
    /// @param amount Amount of FIAT to enter [wad]
    function enterMoneta(address from, uint256 amount) public {
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) fiat.transferFrom(from, address(this), amount);

        moneta.enter(address(this), amount);
    }

    /// @notice Deposits `amount` of `token` with `tokenId` from `from` into the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function enterVault(
        address vault,
        address token,
        uint256 tokenId,
        address from,
        uint256 amount
    ) public virtual;

    /// @notice Withdraws `amount` of `token` with `tokenId` to `to` from the `vault`
    /// @dev Virtual method to be implement in token specific UserAction contracts
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual;

    /// @notice method for adjusting collateral and debt balances of a position.
    /// 1. updates the interest rate accumulator for the given vault
    /// 2. enters FIAT into Moneta if deltaNormalDebt is negative (applies rate to deltaNormalDebt)
    /// 3. enters Collateral into Vault if deltaCollateral is positive
    /// 3. modifies collateral and debt balances in Codex
    /// 4. exits FIAT from Moneta if deltaNormalDebt is positive (applies rate to deltaNormalDebt)
    /// 5. exits Collateral from Vault if deltaCollateral is negative
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the vault's collateral token
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) for this Position [wad]
    function modifyCollateralAndDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) public {
        // update the interest rate accumulator in Codex for the vault
        if (deltaNormalDebt != 0) publican.collect(vault);

        if (deltaNormalDebt < 0) {
            // add due interest from normal debt
            (, uint256 rate, , ) = codex.vaults(vault);
            enterMoneta(creditor, uint256(-wmul(rate, deltaNormalDebt)));
        }

        // transfer tokens to be used as collateral into Vault
        if (deltaCollateral > 0) {
            enterVault(
                vault,
                token,
                tokenId,
                collateralizer,
                wmul(uint256(deltaCollateral), IVault(vault).tokenScale())
            );
        }

        // update collateral and debt balanaces
        codex.modifyCollateralAndDebt(
            vault,
            tokenId,
            position,
            address(this),
            address(this),
            deltaCollateral,
            deltaNormalDebt
        );

        // redeem newly generated internal credit for FIAT
        if (deltaNormalDebt > 0) {
            // forward all generated credit by applying rate
            (, uint256 rate, , ) = codex.vaults(vault);
            exitMoneta(creditor, wmul(uint256(deltaNormalDebt), rate));
        }

        // withdraw tokens not be used as collateral anymore from Vault
        if (deltaCollateral < 0) {
            exitVault(
                vault,
                token,
                tokenId,
                collateralizer,
                wmul(uint256(-deltaCollateral), IVault(vault).tokenScale())
            );
        }
    }
}
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title Vault1155Actions
/// @notice A set of vault actions for modifying positions collateralized by ERC1155 tokens
contract Vault1155Actions is VaultActions {
    /// ======== Custom Errors ======== ///

    error Vault1155Actions__enterVault_zeroVaultAddress();
    error Vault1155Actions__enterVault_zeroTokenAddress();
    error Vault1155Actions__exitVault_zeroVaultAddress();
    error Vault1155Actions__exitVault_zeroToAddress();
    error Vault1155Actions__exitVault_zeroTokenAddress();

    constructor(
        address codex_,
        address moneta_,
        address fiat_,
        address publican_
    ) VaultActions(codex_, moneta_, fiat_, publican_) {}

    /// @notice Deposits amount of `token` with `tokenId` from `from` into the `vault`
    /// @dev Implements virtual method defined in VaultActions for ERC1155 tokens
    /// @param vault Address of the Vault to enter
    /// @param token Address of the collateral token
    /// @param tokenId ERC1155 TokenId
    /// @param from Address from which to take the deposit from
    /// @param amount Amount of collateral tokens to deposit [tokenScale]
    function enterVault(
        address vault,
        address token,
        uint256 tokenId,
        address from,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert Vault1155Actions__enterVault_zeroVaultAddress();
        if (token == address(0)) revert Vault1155Actions__enterVault_zeroTokenAddress();

        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            IERC1155(token).safeTransferFrom(from, address(this), tokenId, amount, new bytes(0));
        }

        IERC1155(token).setApprovalForAll(address(vault), true);
        IVault(vault).enter(tokenId, address(this), amount);
    }

    /// @notice Withdraws amount of `token` with `tokenId` to `to` from the `vault`
    /// @dev Implements virtual method defined in VaultActions for ERC1155 tokens
    /// @param vault Address of the Vault to exit
    /// @param token Address of the collateral token
    /// @param tokenId ERC1155 TokenId
    /// @param to Address which receives the withdrawn collateral tokens
    /// @param amount Amount of collateral tokens to exit [tokenScale]
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public virtual override {
        if (vault == address(0)) revert Vault1155Actions__exitVault_zeroVaultAddress();
        if (token == address(0)) revert Vault1155Actions__exitVault_zeroTokenAddress();
        if (to == address(0)) revert Vault1155Actions__exitVault_zeroToAddress();

        IVault(vault).exit(tokenId, to, amount);
    }
}
interface INotional {
    enum DepositActionType {
        None,
        DepositAsset,
        DepositUnderlying,
        DepositAssetAndMintNToken,
        DepositUnderlyingAndMintNToken,
        RedeemNToken,
        ConvertCashToNToken
    }

    struct MarketParameters {
        bytes32 storageSlot;
        uint256 maturity;
        int256 totalfCash;
        int256 totalAssetCash;
        int256 totalLiquidity;
        uint256 lastImpliedRate;
        uint256 oracleRate;
        uint256 previousTradeTime;
    }

    enum TokenType {
        UnderlyingToken,
        cToken,
        cETH,
        Ether,
        NonMintable
    }

    struct Token {
        address tokenAddress;
        bool hasTransferFee;
        int256 decimals;
        TokenType tokenType;
        uint256 maxCollateralBalance;
    }

    struct BalanceActionWithTrades {
        DepositActionType actionType;
        uint16 currencyId;
        uint256 depositActionAmount;
        uint256 withdrawAmountInternalPrecision;
        bool withdrawEntireCashBalance;
        bool redeemToUnderlying;
        bytes32[] trades;
    }

    struct AssetRateParameters {
        address rateOracle;
        int256 rate;
        int256 underlyingDecimals;
    }

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions) external payable;

    function getSettlementRate(uint16 currencyId, uint40 maturity) external view returns (AssetRateParameters memory);

    function settleAccount(address account) external;

    function withdraw(
        uint16 currencyId,
        uint88 amountInternalPrecision,
        bool redeemToUnderlying
    ) external returns (uint256);

    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);
}

/// @title Constants
/// @notice Copied from https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Constants.sol
/// Replaced OZ safe math with Math.sol
library Constants {
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;

    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;

    uint256 internal constant DAY = 86400;
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;

    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    uint8 internal constant FCASH_ASSET_TYPE = 1;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;

    bytes2 internal constant UNMASK_FLAGS = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES = uint16(UNMASK_FLAGS);
}

/// @title DatetTime
/// @notice Copied from
/// https://github.com/notional-finance/contracts-v2/blob/master/contracts/internal/markets/DateTime.sol
/// Added Custom Errors
library DateTime {
    error DateTime__getReferenceTime_invalidBlockTime();
    error DateTime__getTradedMarket_invalidIndex();
    error DateTime__getMarketIndex_zeroMaxMarketIndex();
    error DateTime__getMarketIndex_invalidMaxMarketIndex();
    error DateTime__getMarketIndex_marketNotFound();

    function getReferenceTime(uint256 blockTime) internal pure returns (uint256) {
        if (blockTime < Constants.QUARTER) revert DateTime__getReferenceTime_invalidBlockTime();
        return blockTime - (blockTime % Constants.QUARTER);
    }

    function getTradedMarket(uint256 index) internal pure returns (uint256) {
        if (index == 1) return Constants.QUARTER;
        if (index == 2) return 2 * Constants.QUARTER;
        if (index == 3) return Constants.YEAR;
        if (index == 4) return 2 * Constants.YEAR;
        if (index == 5) return 5 * Constants.YEAR;
        if (index == 6) return 10 * Constants.YEAR;
        if (index == 7) return 20 * Constants.YEAR;

        revert DateTime__getTradedMarket_invalidIndex();
    }

    function getMarketIndex(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (uint256, bool) {
        if (maxMarketIndex == 0) revert DateTime__getMarketIndex_zeroMaxMarketIndex();
        if (maxMarketIndex > Constants.MAX_TRADED_MARKET_INDEX) revert DateTime__getMarketIndex_invalidMaxMarketIndex();

        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            uint256 marketMaturity = add(tRef, DateTime.getTradedMarket(i));
            // If market matches then is not idiosyncratic
            if (marketMaturity == maturity) return (i, false);
            // Returns the market that is immediately greater than the maturity
            if (marketMaturity > maturity) return (i, true);
        }

        revert DateTime__getMarketIndex_marketNotFound();
    }
}

/// @title EncodeDecode
/// @notice Copied from
/// https://github.com/notional-finance/notional-solidity-sdk/blob/master/contracts/lib/EncodeDecode.sol
/// Added Custom Errors
library EncodeDecode {
    error EncodeDecode__encodeERC1155Id_MAX_CURRENCIES();
    error EncodeDecode__encodeERC1155Id_invalidMaturity();
    error EncodeDecode__encodeERC1155Id_MAX_LIQUIDITY_TOKEN_INDEX();

    enum TradeActionType {
        Lend,
        Borrow,
        AddLiquidity,
        RemoveLiquidity,
        PurchaseNTokenResidual,
        SettleCashDebt
    }

    function decodeERC1155Id(uint256 id)
        internal
        pure
        returns (
            uint16 currencyId,
            uint40 maturity,
            uint8 assetType
        )
    {
        assetType = uint8(id);
        maturity = uint40(id >> 8);
        currencyId = uint16(id >> 48);
    }

    function encodeERC1155Id(
        uint256 currencyId,
        uint256 maturity,
        uint256 assetType
    ) internal pure returns (uint256) {
        if (currencyId > Constants.MAX_CURRENCIES) revert EncodeDecode__encodeERC1155Id_MAX_CURRENCIES();
        if (maturity > type(uint40).max) revert EncodeDecode__encodeERC1155Id_invalidMaturity();
        if (assetType > Constants.MAX_LIQUIDITY_TOKEN_INDEX) {
            revert EncodeDecode__encodeERC1155Id_MAX_LIQUIDITY_TOKEN_INDEX();
        }

        return
            uint256(
                (bytes32(uint256(uint16(currencyId))) << 48) |
                    (bytes32(uint256(uint40(maturity))) << 8) |
                    bytes32(uint256(uint8(assetType)))
            );
    }

    function encodeLendTrade(
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 minImpliedRate
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(uint8(TradeActionType.Lend)) << 248) |
                    (uint256(marketIndex) << 240) |
                    (uint256(fCashAmount) << 152) |
                    (uint256(minImpliedRate) << 120)
            );
    }

    function encodeBorrowTrade(
        uint8 marketIndex,
        uint88 fCashAmount,
        uint32 maxImpliedRate
    ) internal pure returns (bytes32) {
        return
            bytes32(
                uint256(
                    (uint256(uint8(TradeActionType.Borrow)) << 248) |
                        (uint256(marketIndex) << 240) |
                        (uint256(fCashAmount) << 152) |
                        (uint256(maxImpliedRate) << 120)
                )
            );
    }
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a PRBProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

/// @title VaultFCActions
/// @notice A set of vault actions for modifying positions collateralized by Notional Finance fCash tokens
contract VaultFCActions is Vault1155Actions {
    using SafeERC20 for IERC20;

    /// ======== Custom Errors ======== ///

    error VaultFCActions__buyCollateralAndModifyDebt_zeroMaxUnderlierAmount();
    error VaultFCActions__sellCollateralAndModifyDebt_zeroFCashAmount();
    error VaultFCActions__sellCollateralAndModifyDebt_matured();
    error VaultFCActions__redeemCollateralAndModifyDebt_zeroFCashAmount();
    error VaultFCActions__redeemCollateralAndModifyDebt_notMatured();
    error VaultFCActions__getMarketIndex_invalidMarket();
    error VaultFCActions__getUnderlierToken_invalidUnderlierTokenType();
    error VaultFCActions__getCToken_invalidAssetTokenType();
    error VaultFCActions__sellfCash_amountOverflow();
    error VaultFCActions__redeemfCash_amountOverflow();
    error VaultFCActions__vaultRedeemAndExit_zeroVaultAddress();
    error VaultFCActions__vaultRedeemAndExit_zeroTokenAddress();
    error VaultFCActions__vaultRedeemAndExit_zeroToAddress();
    error VaultFCActions__onERC1155Received_invalidCaller();
    error VaultFCActions__onERC1155Received_invalidValue();

    /// ======== Storage ======== ///

    /// @notice Address of the Notional V2 monolith
    INotional public immutable notionalV2;
    /// @notice Scale for all fCash tokens (== tokenScale)
    uint256 public immutable fCashScale;

    constructor(
        address codex,
        address moneta,
        address fiat,
        address publican_,
        address notionalV2_
    ) Vault1155Actions(codex, moneta, fiat, publican_) {
        notionalV2 = INotional(notionalV2_);
        fCashScale = uint256(Constants.INTERNAL_TOKEN_PRECISION);
    }

    /// ======== Position Management ======== ///

    /// @notice Buys fCash from underliers before it modifies a Position's collateral
    /// and debt balances and mints/burns FIAT using the underlier token.
    /// The underlier is swapped to fCash token used as collateral.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the collateral token (fCash)
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param fCashAmount Amount of fCash to buy via underliers and add as collateral [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param minImpliedRate Min. accepted annualized implied lending rate for swapping underliers for fCash [1e9]
    /// @param maxUnderlierAmount Max. amount of underlier to swap for fCash [underlierScale]
    function buyCollateralAndModifyDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        uint256 fCashAmount,
        int256 deltaNormalDebt,
        uint32 minImpliedRate,
        uint256 maxUnderlierAmount
    ) public {
        if (maxUnderlierAmount == 0) revert VaultFCActions__buyCollateralAndModifyDebt_zeroMaxUnderlierAmount();

        // buy fCash and transfer tokens to be used as collateral into VaultFC
        _buyFCash(tokenId, collateralizer, maxUnderlierAmount, minImpliedRate, uint88(fCashAmount));
        int256 deltaCollateral = toInt256(wdiv(fCashAmount, fCashScale));

        // enter fCash and collateralize position
        modifyCollateralAndDebt(
            vault,
            token,
            tokenId,
            position,
            address(this),
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );
    }

    /// @notice Sells the fCash for underliers after it modifies a Position's collateral and debt balances
    /// and mints/burns FIAT using the underlier token.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the collateral token (fCash)
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param fCashAmount Amount of fCash to remove as collateral and to swap for underliers [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    /// @param maxImpliedRate Max. accepted annualized implied borrow rate for swapping fCash for underliers [1e9]
    function sellCollateralAndModifyDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        uint256 fCashAmount,
        int256 deltaNormalDebt,
        uint32 maxImpliedRate
    ) public {
        if (fCashAmount == 0) revert VaultFCActions__sellCollateralAndModifyDebt_zeroFCashAmount();
        if (block.timestamp >= getMaturity(tokenId)) revert VaultFCActions__sellCollateralAndModifyDebt_matured();

        int256 deltaCollateral = -toInt256(wdiv(fCashAmount, fCashScale));

        // withdraw fCash from the position
        modifyCollateralAndDebt(
            vault,
            token,
            tokenId,
            position,
            address(this),
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );

        // sell fCash
        _sellfCash(tokenId, collateralizer, uint88(fCashAmount), maxImpliedRate);
    }

    /// @notice Redeems fCash for underliers after it modifies a Position's collateral and debt balances
    /// and mints/burns FIAT using the underlier token.
    /// @dev The user needs to previously approve the UserProxy for spending collateral tokens or FIAT tokens
    /// If `position` is not the UserProxy, the `position` owner needs grant a delegate to UserProxy via Codex
    /// @param vault Address of the Vault
    /// @param token Address of the collateral token (fCash)
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param position Address of the position's owner
    /// @param collateralizer Address of who puts up or receives the collateral delta as underlier tokens
    /// @param creditor Address of who provides or receives the FIAT delta for the debt delta
    /// @param fCashAmount Amount of fCash to remove as collateral and to redeem for underliers [tokenScale]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function redeemCollateralAndModifyDebt(
        address vault,
        address token,
        uint256 tokenId,
        address position,
        address collateralizer,
        address creditor,
        uint256 fCashAmount,
        int256 deltaNormalDebt
    ) public {
        if (fCashAmount == 0) revert VaultFCActions__redeemCollateralAndModifyDebt_zeroFCashAmount();
        if (block.timestamp < getMaturity(tokenId)) revert VaultFCActions__redeemCollateralAndModifyDebt_notMatured();

        int256 deltaCollateral = -toInt256(wdiv(fCashAmount, fCashScale));

        // withdraw fCash from the position and redeem them for underliers
        modifyCollateralAndDebt(
            vault,
            token,
            tokenId,
            position,
            collateralizer,
            creditor,
            deltaCollateral,
            deltaNormalDebt
        );
    }

    /// @notice Buys fCash tokens (shares) from the Notional AMM
    /// @dev The amount of underlier set as argument is the upper limit to be paid
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param from Address who pays for the fCash
    /// @param maxUnderlierAmount Max. amount of underlier to swap for fCash [underlierScale]
    /// @param minImpliedRate Min. accepted annualized implied lending rate for lending out underliers for fCash [1e9]
    /// @param fCashAmount Amount of fCash to buy via underliers [tokenScale]
    function _buyFCash(
        uint256 tokenId,
        address from,
        uint256 maxUnderlierAmount,
        uint32 minImpliedRate,
        uint88 fCashAmount
    ) internal {
        (IERC20 underlier, ) = getUnderlierToken(tokenId);

        uint256 balanceBefore = 0;
        // if `from` is set to an external address then transfer amount to the proxy first
        // requires `from` to have set an allowance for the proxy
        if (from != address(0) && from != address(this)) {
            balanceBefore = underlier.balanceOf(address(this));
            underlier.safeTransferFrom(from, address(this), maxUnderlierAmount);
        }

        INotional.BalanceActionWithTrades[] memory action = new INotional.BalanceActionWithTrades[](1);
        action[0].actionType = INotional.DepositActionType.DepositUnderlying;
        action[0].depositActionAmount = maxUnderlierAmount;
        action[0].currencyId = getCurrencyId(tokenId);
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = true;
        action[0].trades = new bytes32[](1);
        action[0].trades[0] = EncodeDecode.encodeLendTrade(getMarketIndex(tokenId), fCashAmount, minImpliedRate);

        if (underlier.allowance(address(this), address(notionalV2)) < maxUnderlierAmount) {
            // approve notionalV2 to transfer underlier tokens on behalf of proxy
            underlier.approve(address(notionalV2), maxUnderlierAmount);
        }

        notionalV2.batchBalanceAndTradeAction(address(this), action);

        // Send any residuals underlier back to the sender
        if (from != address(0) && from != address(this)) {
            uint256 balanceAfter = underlier.balanceOf(address(this));
            uint256 residual = balanceAfter - balanceBefore;
            if (residual > 0) underlier.safeTransfer(from, residual);
        }
    }

    /// @dev Sells an fCash tokens (shares) back on the Notional AMM
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param fCashAmount The amount of fCash to sell [tokenScale]
    /// @param to Receiver of the underlier tokens
    /// @param maxImpliedRate Max. accepted annualized implied borrow rate for swapping fCash for underliers [1e9]
    function _sellfCash(
        uint256 tokenId,
        address to,
        uint88 fCashAmount,
        uint32 maxImpliedRate
    ) internal {
        if (fCashAmount > type(uint88).max) revert VaultFCActions__sellfCash_amountOverflow();

        (IERC20 underlier, ) = getUnderlierToken(tokenId);

        INotional.BalanceActionWithTrades[] memory action = new INotional.BalanceActionWithTrades[](1);
        action[0].actionType = INotional.DepositActionType.None;
        action[0].currencyId = getCurrencyId(tokenId);
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = true;
        action[0].trades = new bytes32[](1);
        action[0].trades[0] = EncodeDecode.encodeBorrowTrade(getMarketIndex(tokenId), fCashAmount, maxImpliedRate);

        uint256 balanceBefore = underlier.balanceOf(address(this));
        notionalV2.batchBalanceAndTradeAction(address(this), action);
        uint256 balanceAfter = underlier.balanceOf(address(this));

        // Send the resulting underlier to the user
        underlier.safeTransfer(to, balanceAfter - balanceBefore);
    }

    /// @notice Redeems fCash for underliers (if fCash has matured) and transfers them from the `vault` to `to`
    /// @param vault Address of the Vault to exit
    /// @param token Address of the collateral token (fCash)
    /// @param tokenId fCash Id (ERC1155 token id)
    /// @param to Address which receives the fCash / redeemed underlier tokens
    /// @param amount Amount of collateral tokens to exit or redeem and exit [tokenScale]
    function exitVault(
        address vault,
        address token,
        uint256 tokenId,
        address to,
        uint256 amount
    ) public override {
        if (block.timestamp < getMaturity(tokenId)) {
            super.exitVault(vault, token, tokenId, to, amount);
        } else {
            if (vault == address(0)) revert VaultFCActions__vaultRedeemAndExit_zeroVaultAddress();
            if (token == address(0)) revert VaultFCActions__vaultRedeemAndExit_zeroTokenAddress();
            if (to == address(0)) revert VaultFCActions__vaultRedeemAndExit_zeroToAddress();
            IVaultFC(vault).redeemAndExit(tokenId, to, amount);
        }
    }

    /// ======== View Methods ======== ///

    /// @notice Returns an amount of fCash tokens for a given amount of the fCashs underlier token (e.g. USDC)
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param amount Amount of underlier token [underlierScale]
    /// @return Amount of fCash [tokenScale]
    function underlierToFCash(uint256 tokenId, uint256 amount) public view returns (uint256) {
        (, uint256 underlierScale) = getUnderlierToken(tokenId);
        return
            uint256(
                _adjustForRounding(
                    notionalV2.getfCashAmountGivenCashAmount(
                        getCurrencyId(tokenId),
                        -int88(toInt256(div(mul(amount, fCashScale), underlierScale))),
                        getMarketIndex(tokenId),
                        block.timestamp
                    )
                )
            );
    }

    /// @notice Returns a amount of the fCashs underlier token for a given amount of fCash tokens (e.g. fUSDC)
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @param amount Amount of fCash [tokenScale]
    /// @return Amount of underlier [underlierScale]
    function fCashToUnderlier(uint256 tokenId, uint256 amount) external view returns (uint256) {
        (, uint256 underlierScale) = getUnderlierToken(tokenId);
        (, int256 netUnderlyingCash) = notionalV2.getCashAmountGivenfCashAmount(
            getCurrencyId(tokenId),
            -int88(toInt256(amount)),
            getMarketIndex(tokenId),
            block.timestamp
        );
        return div(mul(underlierScale, uint256(_adjustForRounding(netUnderlyingCash))), uint256(fCashScale));
    }

    /// @notice Returns the underlying fCash currency
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @return currencyId (Notional Finance)
    function getCurrencyId(uint256 tokenId) public pure returns (uint16 currencyId) {
        (currencyId, , ) = EncodeDecode.decodeERC1155Id(tokenId);
    }

    /// @notice Returns the current market index for this fCash asset. If this returns
    /// zero that means it is idiosyncratic and cannot be traded.
    /// @param tokenId fCash Id (ERC1155 tokenId)
    /// @return Index of the Notional Finance market
    function getMarketIndex(uint256 tokenId) public view returns (uint8) {
        (uint256 marketIndex, bool isInvalidMarket) = DateTime.getMarketIndex(
            Constants.MAX_TRADED_MARKET_INDEX,
            getMaturity(tokenId),
            block.timestamp
        );
        if (isInvalidMarket) revert VaultFCActions__getMarketIndex_invalidMarket();

        // Market index as defined does not overflow this conversion
        return uint8(marketIndex);
    }

    /// @notice Returns the underlying fCash maturity of the token
    function getMaturity(uint256 tokenId) public pure returns (uint40 maturity) {
        (, maturity, ) = EncodeDecode.decodeERC1155Id(tokenId);
    }

    /// @notice Returns the underlier of the token of the token that this token settles to, and its precision scale.
    /// E.g. for fUSDC it returns the USDC address and the scale of USDC
    /// @param tokenId fCash ID (ERC1155 tokenId)
    /// @return underlierToken Address of the underlier (for fUSDC it would be USDC)
    /// @return underlierScale Precision of the underlier (USDC it would be 1e6)
    function getUnderlierToken(uint256 tokenId) public view returns (IERC20 underlierToken, uint256 underlierScale) {
        (, INotional.Token memory underlier) = notionalV2.getCurrency(getCurrencyId(tokenId));
        if (underlier.tokenType != INotional.TokenType.UnderlyingToken) {
            revert VaultFCActions__getUnderlierToken_invalidUnderlierTokenType();
        }
        // decimals is 1eDecimals
        return (IERC20(underlier.tokenAddress), uint256(underlier.decimals));
    }

    /// @notice Returns the cToken (from Compound) which the fCash settles to at maturity
    /// @param tokenId fCash ID (ERC1155 tokenId)
    /// @return cToken Address of the cToken
    /// @return cTokenScale Precision scale of the cToken (1e8)
    function getCToken(uint256 tokenId) public view returns (IERC20 cToken, uint256 cTokenScale) {
        (INotional.Token memory asset, ) = notionalV2.getCurrency(getCurrencyId(tokenId));
        if (asset.tokenType != INotional.TokenType.cToken) {
            revert VaultFCActions__getCToken_invalidAssetTokenType();
        }
        // decimals is 1eDecimals
        return (IERC20(asset.tokenAddress), uint256(asset.decimals));
    }

    /// @dev Adjusts the returned cash values for potential rounding issues in calculations
    function _adjustForRounding(int256 x) private pure returns (int256) {
        int256 y = (x < 1e7) ? int256(1) : (x / 1e7);
        return x - y;
    }

    /// ======== ERC1155 ======== ///

    /// @notice Grants or revokes permission to `spender` to transfer the UserProxy's ERC1155 tokens,
    /// according to `approved`
    /// @param token Address of the ERC1155 token
    /// @param spender Address of the spender
    /// @param approved Boolean indicating `spender` approval
    function setApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external {
        IERC1155(token).setApprovalForAll(spender, approved);
    }
}