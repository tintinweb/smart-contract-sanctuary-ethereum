// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";

abstract contract Defii is IDefii {
    using SafeERC20 for IERC20;

    address public owner;
    address public incentiveVault;
    address public factory;

    constructor() {
        // prevent usage implementation as defii
        owner = msg.sender;
    }

    // Current version of Defii contract. Each version have some new features.
    // After adding new features to Defii contract, add new version to this comment
    // and increase returned version

    // version 1: just Defii with enter, harvest, exit
    // version 2: Added DefiiFactory.getAllWallets, DefiiFactory.getAllDefiis,
    //            DefiiFactory.getAllAllocations, DefiiFactory.getAllInfos
    // version 3: Added incentiveVault
    // version 4: Added Defii.getBalance and DefiiFactory.getAllBalances
    function version() external pure returns (uint16) {
        return 4;
    }

    /// @notice Sets owner and factory addresses. Could run only once, called by factory.
    /// @param owner_ Owner (for ACL and transfers out)
    /// @param factory_ For validation and info about executor
    /// @param incentiveVault_ Address, that collect all incentive tokens
    function init(
        address owner_,
        address factory_,
        address incentiveVault_
    ) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
        incentiveVault = incentiveVault_;
        _postInit();
    }

    /// @notice Calculates balances of given tokens. Returns difference of token amount before exit and after exit.
    /// @dev Should marked as view in ABI
    /// @param tokens Owner (for ACL and transfers out)
    /// @return balances Info about token balances
    function getBalance(address[] calldata tokens)
        external
        returns (BalanceItem[] memory balances)
    {
        (, bytes memory result) = address(this).call(
            abi.encodeWithSelector(this.getBalanceAndRevert.selector, tokens)
        );
        balances = abi.decode(result, (BalanceItem[]));
    }

    /// @notice Use getBalance. This function always reverts.
    function getBalanceAndRevert(address[] calldata tokens) external {
        BalanceItem[] memory balances = new BalanceItem[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = BalanceItem({
                token: tokens[i],
                decimals: IERC20Metadata(tokens[i]).decimals(),
                balance: IERC20(tokens[i]).balanceOf(address(this)),
                incentiveVaultBalance: IERC20(tokens[i]).balanceOf(
                    incentiveVault
                )
            });
        }

        if (hasAllocation()) {
            _exit();

            for (uint256 i = 0; i < tokens.length; i++) {
                balances[i].balance =
                    IERC20(tokens[i]).balanceOf(address(this)) -
                    balances[i].balance;
                balances[i].incentiveVaultBalance =
                    IERC20(tokens[i]).balanceOf(incentiveVault) -
                    balances[i].incentiveVaultBalance;
            }
        }

        bytes memory returnData = abi.encode(balances);
        uint256 returnDataLength = returnData.length;
        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }

    //////
    // owner functions
    //////

    /// @notice Change address of incentive vault.
    /// @param incentiveVault_ New incentive vault address
    function changeIncentiveVault(address incentiveVault_) external onlyOwner {
        incentiveVault = incentiveVault_;
    }

    /// @notice Enters to DEFI instrument. Could run only by owner.
    function enter() external onlyOwner {
        _enter();
    }

    /// @notice Runs custom transaction. Could run only by owner.
    /// @param target Address
    /// @param value Transaction value (e.g. 1 AVAX)
    /// @param data Enocded function call
    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner {
        (bool success, ) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    /// @notice Runs custom multiple transactions. Could run only by owner.
    /// @param targets List of address
    /// @param values List of transactions value (e.g. 1 AVAX)
    /// @param datas List of enocded function calls
    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external onlyOwner {
        require(
            targets.length == values.length,
            "targets and values length not match"
        );
        require(
            targets.length == datas.length,
            "targets and datas length not match"
        );

        for (uint256 i = 0; i < targets.length; i++) {
            runTx(targets[i], values[i], datas[i]);
        }
    }

    //////
    // owner and executor functions
    //////

    /// @notice Exit from DEFI instrument. Could run by owner or executor. Don't withdraw funds to owner account.
    function exit() external onlyOnwerOrExecutor {
        _exit();
    }

    /// @notice Exit from DEFI instrument. Could run by owner or executor.
    function exitAndWithdraw() external onlyOnwerOrExecutor {
        _exit();
        _withdrawFunds();
    }

    /// @notice Claim rewards and withdraw to owner.
    function harvest() external onlyOnwerOrExecutor {
        _harvest();
    }

    /// @notice Claim rewards, sell it and and withdraw to owner.
    /// @param params Encoded params (use encodeParams function for it)
    function harvestWithParams(bytes memory params)
        external
        onlyOnwerOrExecutor
    {
        _harvestWithParams(params);
    }

    /// @notice Withdraw funds to owner (some hardcoded assets, which uses in instrument).
    function withdrawFunds() external onlyOnwerOrExecutor {
        _withdrawFunds();
    }

    /// @notice Withdraw ERC20 to owner
    /// @param token ERC20 address
    function withdrawERC20(IERC20 token) public onlyOnwerOrExecutor {
        _withdrawERC20(token);
    }

    /// @notice Withdraw native token to owner (e.g ETH, AVAX, ...)
    function withdrawETH() public onlyOnwerOrExecutor {
        _withdrawETH();
    }

    receive() external payable {}

    function hasAllocation() public view virtual returns (bool);

    //////
    // internal functions - common logic
    //////

    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    function _claimIncentive(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(incentiveVault, tokenAmount);
        }
    }

    //////
    // internal functions - defii specific logic
    //////

    function _postInit() internal virtual {}

    function _enter() internal virtual;

    function _exit() internal virtual;

    function _harvest() internal virtual {
        revert("Use harvestWithParams");
    }

    function _withdrawFunds() internal virtual;

    function _harvestWithParams(bytes memory) internal virtual {
        revert("Run harvest");
    }

    //////
    // modifiers
    //////

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOnwerOrExecutor() {
        require(
            msg.sender == owner ||
                msg.sender == IDefiiFactory(factory).executor(),
            "Only owner or executor"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Defii} from "../Defii.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";
import {DefiiWithCustomExit} from "../DefiiWithCustomExit.sol";

contract UniswapV3EthUsdcUsdt is DefiiWithCustomEnter, DefiiWithCustomExit {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager constant nfpManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    /// @notice Encode params for enterWithParamas function
    /// @param tickLower Left tick for position
    /// @param tickUpper Right tick for position
    /// @param fee The pool's fee in hundredths of a bip, i.e. 1e-6 (e.g 100 for 0.01%)
    /// @return encodedParams Encoded params for enterWithParams function
    function enterParams(
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external view returns (bytes memory encodedParams) {
        uint256 usdcBalance = USDC.balanceOf(address(this));

        IUniswapV3Pool pool = nfpManager.factory().getPool(USDC, USDT, fee);
        (uint256 sqrtPriceX96, int24 tickCurrent, , , , , ) = pool.slot0();
        uint256 token0AmountToSwap = calcToken0AmountToSwap(
            tickLower,
            tickUpper,
            tickCurrent,
            sqrtPriceX96,
            usdcBalance
        );

        encodedParams = abi.encode(
            tickLower,
            tickUpper,
            fee,
            findNft(tickLower, tickUpper, fee),
            token0AmountToSwap
        );
    }

    function findNft(
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) public view returns (uint256) {
        uint256 numPositions = nfpManager.balanceOf(address(this));
        for (uint256 i = 0; i < numPositions; i++) {
            uint256 positionId = nfpManager.tokenOfOwnerByIndex(
                address(this),
                i
            );

            (
                ,
                ,
                ,
                ,
                uint24 positionFee,
                int24 positionTickLower,
                int24 positionTickUpper,
                ,
                ,
                ,
                ,

            ) = nfpManager.positions(positionId);

            if (
                tickLower == positionTickLower &&
                tickUpper == positionTickUpper &&
                fee == positionFee
            ) {
                return positionId;
            }
        }
        return 0;
    }

    function calcToken0AmountToSwap(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 P,
        uint256 token0Balance
    ) public pure returns (uint256 token0AmountToSwap) {
        if (tickLower > tickCurrent) return 0;
        if (tickUpper < tickCurrent) return token0Balance;

        uint256 Q96 = 0x1000000000000000000000000;
        uint256 Q64 = 0x10000000000000000;
        uint256 Q32 = 0x100000000;

        uint256 pa = TickMath.getSqrtRatioAtTick(tickLower);
        uint256 pb = TickMath.getSqrtRatioAtTick(tickUpper);

        uint256 num = P * pb;
        uint256 denom = pb - P;

        // k in Q32 format
        uint256 k = ((num / denom) * (P - pa)) / Q96 / Q64;

        uint256 token0AmountToLiquidity = (token0Balance * Q32) / (k + Q32);
        token0AmountToSwap = token0Balance - token0AmountToLiquidity;
    }

    function exitParams(uint256 positionId)
        external
        pure
        returns (bytes memory encodedParams)
    {
        encodedParams = abi.encode(positionId);
    }

    function hasAllocation() public view override returns (bool) {
        return nfpManager.balanceOf(address(this)) > 0;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external view returns (bytes4) {
        require(tx.origin == owner, "Only owner could init tx with NFT mint");
        return this.onERC721Received.selector;
    }

    function _postInit() internal override {
        USDC.approve(address(nfpManager), type(uint256).max);
        USDC.approve(address(router), type(uint256).max);
        USDT.safeIncreaseAllowance(address(nfpManager), type(uint256).max);
    }

    function _enterWithParams(bytes memory params) internal override {
        (
            int24 tickLower,
            int24 tickUpper,
            uint24 fee,
            uint256 nftId,
            uint256 usdcToSwap
        ) = abi.decode(params, (int24, int24, uint24, uint256, uint256));

        if (usdcToSwap > 0) {
            router.exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: address(USDC),
                    tokenOut: address(USDT),
                    fee: 100,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: usdcToSwap,
                    amountOutMinimum: (usdcToSwap * 999) / 1000, // slippage 0.1 %
                    sqrtPriceLimitX96: 0
                })
            );
        }

        uint256 usdcAmount = USDC.balanceOf(address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this));

        if (nftId > 0) {
            nfpManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: nftId,
                    amount0Desired: usdcAmount,
                    amount1Desired: usdtAmount,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
        } else {
            nfpManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: address(USDC),
                    token1: address(USDT),
                    fee: fee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: usdcAmount,
                    amount1Desired: usdtAmount,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: address(this),
                    deadline: block.timestamp
                })
            );
        }
    }

    function _exit() internal override(Defii, DefiiWithCustomExit) {
        uint256 numPositions = nfpManager.balanceOf(address(this));
        for (uint256 i = 0; i < numPositions; i++) {
            uint256 positionId = nfpManager.tokenOfOwnerByIndex(
                address(this),
                i
            );
            _exitOnePosition(positionId);
        }
    }

    function _exitWithParams(bytes memory params) internal override {
        uint256 positionId = abi.decode(params, (uint256));
        _exitOnePosition(positionId);
    }

    function _exitOnePosition(uint256 positionId) internal {
        (, , , , , , , uint128 positionLiquidity, , , , ) = nfpManager
            .positions(positionId);

        nfpManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: positionId,
                liquidity: positionLiquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        nfpManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: positionId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function _harvest() internal override {
        INonfungiblePositionManager.CollectParams memory collectParams;
        uint256 numPositions = nfpManager.balanceOf(address(this));
        for (uint256 i = 0; i < numPositions; i++) {
            uint256 positionId = nfpManager.tokenOfOwnerByIndex(
                address(this),
                i
            );

            collectParams.tokenId = positionId;
            collectParams.recipient = address(this);
            collectParams.amount0Max = type(uint128).max;
            collectParams.amount1Max = type(uint128).max;
            nfpManager.collect(collectParams);
        }
        _withdrawFunds();
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
        withdrawERC20(USDT);
    }
}

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
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint24(MAX_TICK), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0)
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0)
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0)
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }
}

interface IUniswapV3Factory {
    function getPool(
        IERC20 tokenA,
        IERC20 tokenB,
        uint24 fee
    ) external view returns (IUniswapV3Pool pool);
}

interface INonfungiblePositionManager is IERC721Enumerable {
    function factory() external view returns (IUniswapV3Factory);

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

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

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

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    function burn(uint256 tokenId) external payable;

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";

abstract contract DefiiWithCustomEnter is Defii {
    function enterWithParams(bytes memory params) external onlyOwner {
        _enterWithParams(params);
    }

    function _enterWithParams(bytes memory params) internal virtual;

    function _enter() internal virtual override {
        revert("Run enterWithParams");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";

abstract contract DefiiWithCustomExit is Defii {
    function exitWithParams(bytes memory params) external onlyOnwerOrExecutor {
        _exitWithParams(params);
    }

    function exitWithParamsAndWithdraw(
        bytes memory params
    ) public onlyOnwerOrExecutor {
        _exitWithParams(params);
        _withdrawFunds();
    }

    function _exitWithParams(bytes memory params) internal virtual;

    function _exit() internal virtual override {
        revert("Run exitWithParams");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./IDefiiFactory.sol";

interface IDefii {
    function hasAllocation() external view returns (bool);

    function incentiveVault() external view returns (address);

    function version() external pure returns (uint16);

    function init(
        address owner_,
        address factory_,
        address incentiveVault_
    ) external;

    function getBalance(address[] calldata tokens)
        external
        returns (BalanceItem[] memory balances);

    function changeIncentiveVault(address incentiveVault_) external;

    function enter() external;

    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) external;

    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external;

    function exit() external;

    function exitAndWithdraw() external;

    function harvest() external;

    function withdrawERC20(IERC20 token) external;

    function withdrawETH() external;

    function withdrawFunds() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Info {
    address wallet;
    address defii;
    bool hasAllocation;
    address incentiveVault;
}

struct Balance {
    address wallet;
    BalanceItem[] balance;
}

struct BalanceItem {
    address token;
    uint256 decimals;
    uint256 balance;
    uint256 incentiveVaultBalance;
}

interface IDefiiFactory {
    function executor() external view returns (address executor);

    function getDefiiFor(address wallet) external view returns (address defii);

    function getAllWallets() external view returns (address[] memory);

    function getAllDefiis() external view returns (address[] memory);

    function getAllAllocations() external view returns (bool[] memory);

    function getAllInfos() external view returns (Info[] memory);

    function getAllBalances(address[] calldata tokens)
        external
        returns (Balance[] memory);

    function createDefii() external;

    function createDefiiFor(address owner, address incentiveVault) external;
}