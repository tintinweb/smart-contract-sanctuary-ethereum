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
pragma solidity ^0.8.17;
import "../triggers/TriggerTypes.sol";
import "../utils/assets/TokenLib.sol";

struct ActionRuntimeParams {
    TriggerReturn[] triggerReturnArr;
    uint256[] collaterals;
}

struct Action {
    address callee; // eg. swapUni
    bytes data; // any custom param to send to the callee, encoded at compileTime
    Token[] inputTokens; // token to be used to initiate the action
    Token[] outputTokens; // token to be gotten as output
}

struct ActionConstraints {
    uint256 expiry; // this action will revert if used after this time
    uint256 activation; // this action will revert if used before this time
}

struct Position {
    // metadata that can optionally be used to indicate constraints that bound the actions
    // This can be be used by the smart contract to decide whether this position is acceptable
    // The constraints should match the index order of the nextActions
    ActionConstraints[] actionConstraints;
    // A list of actions that can be taken as next-steps to this action.
    // the next step in this action (which will typically be to close an open position).
    // Taking ANY of these actions will result in this position being closed.
    Action[] nextActions;
}

struct ActionResponse {
    //array of amounts with datatype.
    uint256[] tokenOutputs; // idx if ERC721, amount if erc20 or native
    // In future, we may have non-token outputs to be interpreted by the receiver
    // bytes otherOutputs;

    // The position should provide an exhaustive list of actions that can be used to close
    // the position for a given action. Otherwise, a position might end up being closed, but the
    // contract wouldnt know and will keep it marked pending.
    Position position;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IOps.sol";
import "./ITaskTreasury.sol";
import "../rules/IRoboCop.sol";
import "./IBotFrontend.sol";
import "./OpsReady.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BotFrontend is IBotFrontend, OpsReady, Ownable {
    ITaskTreasury public immutable treasury;
    address public barrenWuffetAddr;
    mapping(address => mapping(bytes32 => bytes32)) public ruleToTaskIdMap;
    mapping(address => bool) public robocopRegistry;

    modifier onlyBarrenWuffet() {
        require(msg.sender == barrenWuffetAddr);
        _;
    }

    modifier onlyRobocop() {
        require(robocopRegistry[msg.sender]);
        _;
    }

    constructor(address _treasuryAddr, address _ops) OpsReady(_ops) {
        treasury = ITaskTreasury(_treasuryAddr);
    }

    function setBarrenWuffet(address _barrentWuffetAddr) external onlyOwner {
        barrenWuffetAddr = _barrentWuffetAddr;
    }

    function startTask(bytes32 ruleHash) external onlyRobocop {
        // TODO: check() and execute() is done through this frontend too (instead of only task registration)
        // asking gelato to check() and execute() directly on the robocops would be more efficient
        bytes32 taskId = IOps(ops).createTask(
            address(this),
            this.executeTask.selector,
            address(this),
            abi.encodeWithSelector(this.checker.selector, msg.sender, ruleHash)
        );

        ruleToTaskIdMap[msg.sender][ruleHash] = taskId;
    }

    function stopTask(bytes32 ruleHash) external {
        IOps(ops).cancelTask(ruleToTaskIdMap[msg.sender][ruleHash]);
    }

    // If roboCop is not registered by BarrentWuffet, it can't use startTask
    function registerRobocop(address robocopAddr) external onlyBarrenWuffet {
        robocopRegistry[robocopAddr] = true;
    }

    function checker(address robocopAddr, bytes32 ruleHash)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = IRoboCop(robocopAddr).checkRule(ruleHash);
        execPayload = abi.encodeWithSelector(this.executeTask.selector, robocopAddr, ruleHash);
    }

    function executeTask(address robocopAddr, bytes32 ruleHash) external {
        IRoboCop(robocopAddr).executeRule(ruleHash);
    }

    function deposit(uint256 _amount) external payable {
        treasury.depositFunds{value: _amount}(address(this), ETH, _amount);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        treasury.withdrawFunds(payable(msg.sender), ETH, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBotFrontend {
    function startTask(bytes32 ruleHash) external;

    function stopTask(bytes32 ruleHash) external;

    function registerRobocop(address robocopAddr) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IOps {
    struct Time {
        uint128 nextExec;
        uint128 interval;
    }

    function gelato() external view returns (address payable);

    function taskCreator(bytes32 taskId) external view returns (address);

    function execAddresses(bytes32 taskId) external view returns (address);

    function fee() external view returns (uint256);

    function feeToken() external view returns (address);

    function timedTask(bytes32 taskId) external view returns (Time memory time);

    event ExecSuccess(
        uint256 indexed txFee,
        address indexed feeToken,
        address indexed execAddress,
        bytes execData,
        bytes32 taskId,
        bool callSuccess
    );
    event TaskCreated(
        address taskCreator,
        address execAddress,
        bytes4 selector,
        address resolverAddress,
        bytes32 taskId,
        bytes resolverData,
        bool useTaskTreasuryFunds,
        address feeToken,
        bytes32 resolverHash
    );
    event TaskCancelled(bytes32 taskId, address taskCreator);
    event TimerSet(bytes32 indexed taskId, uint128 indexed nextExec, uint128 indexed interval);

    /// @notice Execution API called by Gelato
    /// @param _txFee Fee paid to Gelato for execution, deducted on the TaskTreasury
    /// @param _feeToken Token used to pay for the execution. ETH = 0xeeeeee...
    /// @param _taskCreator On which contract should Gelato check when to execute the tx
    /// @param _useTaskTreasuryFunds If msg.sender's balance on TaskTreasury should pay for the tx
    /// @param _revertOnFailure To revert or not if call to execAddress fails
    /// @param _execAddress On which contract should Gelato execute the tx
    /// @param _execData Data used to execute the tx, queried from the Resolver by Gelato
    // solhint-disable function-max-lines
    // solhint-disable code-complexity
    function exec(
        uint256 _txFee,
        address _feeToken,
        address _taskCreator,
        bool _useTaskTreasuryFunds,
        bool _revertOnFailure,
        bytes32 _resolverHash,
        address _execAddress,
        bytes calldata _execData
    ) external;

    /// @notice Helper func to query fee and feeToken
    function getFeeDetails() external view returns (uint256, address);

    /// @notice Helper func to query all open tasks by a task creator
    /// @param _taskCreator Address who created the task
    function getTaskIdsByUser(address _taskCreator) external view returns (bytes32[] memory);

    /// @notice Helper func to query the _selector of a function you want to automate
    /// @param _func String of the function you want the selector from
    /// @dev Example: "transferFrom(address,address,uint256)" => 0x23b872dd
    function getSelector(string calldata _func) external pure returns (bytes4);

    /// @notice Create a timed task that executes every so often based on the inputted interval
    /// @param _startTime Timestamp when the first task should become executable. 0 for right now
    /// @param _interval After how many seconds should each task be executed
    /// @param _execAddress On which contract should Gelato execute the transactions
    /// @param _execSelector Which function Gelato should eecute on the _execAddress
    /// @param _resolverAddress On which contract should Gelato check when to execute the tx
    /// @param _resolverData Which data should be used to check on the Resolver when to execute the tx
    /// @param _feeToken Which token to use as fee payment
    /// @param _useTreasury True if Gelato should charge fees from TaskTreasury, false if not
    function createTimedTask(
        uint128 _startTime,
        uint128 _interval,
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken,
        bool _useTreasury
    ) external returns (bytes32 task);

    /// @notice Create a task that tells Gelato to monitor and execute transactions on specific contracts
    /// @dev Requires funds to be added in Task Treasury, assumes treasury sends fee to Gelato via Ops
    /// @param _execAddress On which contract should Gelato execute the transactions
    /// @param _execSelector Which function Gelato should eecute on the _execAddress
    /// @param _resolverAddress On which contract should Gelato check when to execute the tx
    /// @param _resolverData Which data should be used to check on the Resolver when to execute the tx
    function createTask(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData
    ) external returns (bytes32 task);

    /// @notice Create a task that tells Gelato to monitor and execute transactions on specific contracts
    /// @dev Requires no funds to be added in Task Treasury, assumes tasks sends fee to Gelato directly
    /// @param _execAddress On which contract should Gelato execute the transactions
    /// @param _execSelector Which function Gelato should eecute on the _execAddress
    /// @param _resolverAddress On which contract should Gelato check when to execute the tx
    /// @param _resolverData Which data should be used to check on the Resolver when to execute the tx
    /// @param _feeToken Which token to use as fee payment
    function createTaskNoPrepayment(
        address _execAddress,
        bytes4 _execSelector,
        address _resolverAddress,
        bytes calldata _resolverData,
        address _feeToken
    ) external returns (bytes32 task);

    /// @notice Cancel a task so that Gelato can no longer execute it
    /// @param _taskId The hash of the task, can be computed using getTaskId()
    function cancelTask(bytes32 _taskId) external;

    /// @notice Helper func to query the resolverHash
    /// @param _resolverAddress Address of resolver
    /// @param _resolverData Data passed to resolver
    function getResolverHash(address _resolverAddress, bytes memory _resolverData) external;

    /// @notice Returns TaskId of a task Creator
    /// @param _taskCreator Address of the task creator
    /// @param _execAddress Address of the contract to be executed by Gelato
    /// @param _selector Function on the _execAddress which should be executed
    /// @param _useTaskTreasuryFunds If msg.sender's balance on TaskTreasury should pay for the tx
    /// @param _feeToken FeeToken to use, address 0 if task treasury is used
    /// @param _resolverHash hash of resolver address and data
    function getTaskId(
        address _taskCreator,
        address _execAddress,
        bytes4 _selector,
        bool _useTaskTreasuryFunds,
        address _feeToken,
        bytes32 _resolverHash
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITaskTreasury {
    /// @notice Events ///
    event FundsDeposited(address indexed sender, address indexed token, uint256 indexed amount);

    event FundsWithdrawn(address indexed receiver, address indexed initiator, address indexed token, uint256 amount);

    /// @notice External functions ///

    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function useFunds(
        address token,
        uint256 amount,
        address user
    ) external;

    function addWhitelistedService(address service) external;

    function removeWhitelistedService(address service) external;

    /// @notice External view functions ///

    function gelato() external view returns (address);

    function getCreditTokensByUser(address user) external view returns (address[] memory);

    function getWhitelistedServices() external view returns (address[] memory);

    function userTokenBalance(address user, address token) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IOps.sol";

abstract contract OpsReady {
    address public immutable ops;
    address payable public immutable gelato;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier onlyOps() {
        require(msg.sender == ops, "OpsReady: onlyOps");
        _;
    }

    constructor(address _ops) {
        ops = _ops;
        gelato = IOps(_ops).gelato();
    }

    function _transfer(uint256 _amount, address _paymentToken) internal {
        if (_paymentToken == ETH) {
            (bool success, ) = gelato.call{value: _amount}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_paymentToken), gelato, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RuleTypes.sol";

interface IRoboCop {
    event Created(bytes32 indexed ruleHash);
    event Activated(bytes32 indexed ruleHash);
    event Deactivated(bytes32 indexed ruleHash);
    event Executed(bytes32 indexed ruleHash, address executor);
    event Redeemed(bytes32 indexed ruleHash);
    event CollateralAdded(bytes32 indexed ruleHash, uint256[] amounts);
    event CollateralReduced(bytes32 indexed ruleHash, uint256[] amounts);
    event PositionCreated(bytes32 positionHash, bytes precursorAction, bytes[] nextActions);
    event PositionsClosed(bytes closingAction, bytes32[] positionHashesClosed);

    function initialize(address owner, address botFrontendAddr) external;

    function getRule(bytes32 ruleHash) external view returns (Rule memory);

    function getInputTokens(bytes32 ruleHash) external view returns (Token[] memory);

    function getOutputTokens(bytes32 ruleHash) external view returns (Token[] memory);

    function redeemOutputs() external returns (Token[] memory, uint256[] memory);

    function getRuleHashesByStatus(RuleStatus status) external returns (bytes32[] memory);

    function addCollateral(bytes32 ruleHash, uint256[] memory amounts) external payable;

    function reduceCollateral(bytes32 ruleHash, uint256[] memory amounts) external;

    function createRule(Trigger[] calldata triggers, Action[] calldata actions) external returns (bytes32);

    function activateRule(bytes32 ruleHash) external;

    function deactivateRule(bytes32 ruleHash) external;

    function checkRule(bytes32 ruleHash) external view returns (bool valid);

    function hasPendingPosition() external view returns (bool);

    function actionClosesPendingPosition(Action calldata action) external view returns (bool);

    function executeRule(bytes32 ruleHash) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../actions/ActionTypes.sol";
import "../triggers/TriggerTypes.sol";

enum RuleStatus {
    ACTIVE, // Action can be executed when trigger is met, can add/withdraw collateral
    INACTIVE, // Action can not be executed even if trigger is met, can add/withdraw collateral
    EXECUTED, // Action has been executed, can withdraw output
    REDEEMED // Action has been executed, ouput has been withdrawn
}

struct Rule {
    Trigger[] triggers;
    Action[] actions;
    uint256[] collaterals; // idx if ERC721, amount if erc20 or native
    RuleStatus status;
    // Final output received after all the actions are done.
    uint256[] outputs; // idx if ERC721, amount if erc20 or native
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Ops {
    GT,
    LT
}

enum TriggerType {
    NULL,
    Price,
    Timestamp
}

struct Trigger {
    address callee;
    TriggerType triggerType;
    bytes createTimeParams; // any custom param to send to the callee, encoded at compileTime
}

struct TriggerReturn {
    TriggerType triggerType;
    bytes runtimeData;
}

function decodePriceTriggerCreateTimeParams(bytes memory createTimeParams)
    pure
    returns (
        address,
        address,
        Ops,
        uint256
    )
{
    return abi.decode(createTimeParams, (address, address, Ops, uint256));
}

function decodeTimestampTriggerCreateTimeParams(bytes memory createTimeParams) pure returns (Ops, uint256) {
    return abi.decode(createTimeParams, (Ops, uint256));
}

function decodePriceTriggerReturn(bytes memory runtimeData)
    pure
    returns (
        address,
        address,
        uint256
    )
{
    return abi.decode(runtimeData, (address, address, uint256));
}

function decodeTimestampTriggerReturn(bytes memory runtimeData) pure returns (uint256) {
    return abi.decode(runtimeData, (uint256));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Constants {
    address constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD = address(0);
    string constant TOKEN_TYPE_NOT_RECOGNIZED = "Token type not recognized";
    string constant UNREACHABLE_STATE = "This state should never be reached";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../Constants.sol";
import "./TokenTypes.sol";

library TokenLib {
    using SafeERC20 for IERC20;

    function equals(Token memory t1, Token memory t2) public pure returns (bool) {
        return (t1.t == t2.t && t1.addr == t2.addr && t1.id == t2.id);
    }

    function approve(
        Token memory token,
        address to,
        uint256 collateral
    ) public returns (uint256 ethCollateral) {
        if (isERC20(token)) {
            IERC20(token.addr).safeApprove(to, collateral);
        } else if (isETH(token)) {
            ethCollateral = collateral;
        } else if (isERC721(token)) {
            require(token.id == collateral);
            IERC721(token.addr).approve(to, collateral);
        } else {
            revert(Constants.TOKEN_TYPE_NOT_RECOGNIZED);
        }
    }

    function send(
        Token memory token,
        address receiver,
        uint256 amount
    ) public {
        if (isERC20(token)) {
            IERC20(token.addr).safeTransfer(receiver, amount);
        } else if (isETH(token)) {
            payable(receiver).transfer(amount);
        } else if (isERC721(token)) {
            require(token.id == amount);
            IERC721(token.addr).safeTransferFrom(address(this), receiver, amount);
        } else {
            revert("Wrong token type!");
        }
    }

    function balance(Token memory token) public view returns (uint256) {
        if (isERC20(token)) {
            return IERC20(token.addr).balanceOf(address(this));
        } else if (isETH(token)) {
            return address(this).balance;
        } else {
            revert("Wrong token type!");
        }
    }

    function take(
        Token memory token,
        address sender,
        uint256 collateral
    ) public {
        if (isERC20(token)) {
            IERC20(token.addr).safeTransferFrom(sender, address(this), collateral);
        } else if (isERC721(token)) {
            require(token.id == collateral);
            IERC721(token.addr).safeTransferFrom(sender, address(this), collateral);
        } else if (!isETH(token)) {
            revert("Wrong token type!");
        }
    }

    function isETH(Token memory token) public view returns (bool) {
        return equals(token, Token({t: TokenType.NATIVE, addr: Constants.ETH, id: 0}));
    }

    function isERC20(Token memory token) public view returns (bool) {
        return token.t == TokenType.ERC20;
    }

    function isERC721(Token memory token) public view returns (bool) {
        return token.t == TokenType.ERC721;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum TokenType {
    NATIVE,
    ERC721,
    ERC20
}

struct Token {
    TokenType t;
    address addr;
    uint256 id; // only used for ERC721, else set to 0
}