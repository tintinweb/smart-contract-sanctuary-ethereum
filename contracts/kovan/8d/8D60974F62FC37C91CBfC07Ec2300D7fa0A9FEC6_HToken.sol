// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
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
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import "./IScaledBalanceToken.sol";
import "./IHasaiPoolAddressesProvider.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IHToken is IERC20Upgradeable, IScaledBalanceToken {
  /**
   * @dev Emitted when an hToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param reserveId The id of the reserves
   * @param treasury The address of the treasury
   * @param hTokenDecimals the decimals of the underlying
   * @param hTokenName the name of the hToken
   * @param hTokenSymbol the symbol of the hToken
   **/
  event Initialize(
    address indexed underlyingAsset,
    address indexed pool,
    uint256 indexed reserveId,
    address treasury,
    uint8 hTokenDecimals,
    string hTokenName,
    string hTokenSymbol
  );

  /**
   * @dev Initializes the hToken
   * @param pool The address of the lending pool where this hToken will be used
   * @param reserveId The id of the reserves
   * @param treasury The address of the Hasai treasury, receiving the fees on this hToken
   * @param underlyingAsset The address of the underlying asset of this hToken (E.g. WETH for aWETH)
   * @param hTokenDecimals The decimals of the hToken, same as the underlying asset's
   * @param hTokenName The name of the hToken
   * @param hTokenSymbol The symbol of the hToken
   */
  function initialize(
    IHasaiPoolAddressesProvider pool,
    uint256 reserveId,
    address treasury,
    address underlyingAsset,
    uint8 hTokenDecimals,
    string calldata hTokenName,
    string calldata hTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` hTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after hTokens are burned
   * @param from The owner of the hTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns hTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the hTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints hTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers hTokens in the event of a borrow being liquidated, in case the liquidators reclaims the hToken
   * @param from The address getting liquidated, current owner of the hTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the HasaiPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  function transferUnderlyingNFTTo(address nft, address target, uint256 nftId, bool flag)
    external
    returns (uint256);

  /**
   * @dev Invoked to execute actions on the hToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the underlying asset of this hToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "../libraries/utils/DataTypes.sol";

interface IHasaiPool {
    /**
     * @dev Emitted on deposit()
     * @param reserveId The id of the reserve
     * @param user The beneficiary of the deposit, receiving the hTokens
     * @param onBehalfOf The beneficiary of the deposit, receiving the hTokens
     * @param amount The amount deposited
     **/
    event Deposit(
        uint256 indexed reserveId,
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserveId The id of the reserve
     * @param user The address initiating the withdrawal, owner of hTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        uint256 indexed reserveId,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserveId The id of the reserve
     * @param user he address that will be getting the debt
     * @param asset The address of the borrowed nft
     * @param nftId The tokenId of the borrowed nft
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param loanMode The loan mode: 1 for Float, 2 for Fixed
     * @param borrowRate The numeric rate at which the user has borrowed
     **/
    event Borrow(
        uint256 indexed reserveId,
        address indexed user,
        address indexed asset,
        uint256 nftId,
        uint256 borrowRateMode,
        uint256 loanMode,
        uint256 amount,
        uint256 borrowRate
    );

    /**
     * @dev Emitted on repay()
     * @param reserveId The id of the reserve
     * @param borrowId The id of the borrow info
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param nft The nft corresponding to repayment
     * @param nftId The tokenId of the borrowed nft
     * @param amount The amount repaid
     **/
    event Repay(
        uint256 indexed reserveId,
        uint256 borrowId,
        address indexed user,
        address indexed nft,
        uint256 nftId,
        uint256 amount
    );

    event LiquidationCall(
        uint256 indexed reserveId,
        uint256 borrowId,
        address indexed user,
        address indexed nft,
        uint256 id,
        uint256 amount
    );

    event BidCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user,
        uint256 amount
    );

    event ClaimCall(
        uint256 indexed reserveId,
        uint256 indexed borrowId,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserveId The id of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        uint256 indexed reserveId,
        address indexed user
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when new stable debt is increased
     * @param reserveId The id of the reserve
     * @param asset The address of nft
     * @param user The address of the user who triggered the minting
     * @param amount The amount minted
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param newRate The rate of the debt after the minting
     * @param newTotalSupply The new total supply of the stable debt token after the action
     **/
    event StableDebtIncrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new stable debt is decreased
     * @param reserveId The id of the reserve
     * @param user The address of the user
     * @param amount The amount being burned
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The the increase in balance since the last action of the user
     * @param avgStableRate The new average stable rate after the burning
     * @param newTotalSupply The new total supply of the stable debt token after the action
     **/
    event StableDebtDecrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new varibale debt is increased
     * @param reserveId The id of the reserve
     * @param asset The address performing the nft
     * @param user The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event VariableDebtIncrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 value,
        uint256 index
    );

    /**
     * @dev Emitted when variable debt is decreased
     * @param reserveId The id of the reserve
     * @param asset The address of the nft
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event VariableDebtDecrease(
        uint256 indexed reserveId,
        address indexed asset,
        address indexed user,
        uint256 amount,
        uint256 index
    );

    event SetMinBorrowTime(uint40 time);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying hTokens.
     * @param reserveId The id of the reserve
     * @param onBehalfOf The beneficiary of the deposit, receiving the hTokens
     **/
    function deposit(uint256 reserveId, address onBehalfOf) external payable;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent hTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param reserveId The id of the reserve
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole hToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow an estimate `amount` of the reserve underlying asset according to the value of the nft
     * @param reserveId The id of the reserve
     * @param asset The address of the nft to be borrowed
     * @param nftId The tokenId of the nft to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     **/
    function borrow(
        uint256 reserveId,
        address asset,
        uint256 nftId,
        uint256 interestRateMode
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve
     * @param reserveId The id of the reserve
     * @param borrowId The id of the borrow to repay
     * @return The final amount repaid
     **/
    function repay(uint256 reserveId, uint256 borrowId)
        external
        payable
        returns (uint256);

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param reserveId The id of the reserve
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(uint256 reserveId, address user)
        external;

    /**
     * @dev Function to liquidate an expired borrow info.
     * @param reserveId The id of the reserve to liquidate
     * @param borrowId The id of liquidate borrow target
     **/
    function liquidationCall(uint256 reserveId, uint256 borrowId)
        external
        payable;

    /**
     * @dev Function to bid for the liquidate auction.
     * @param reserveId The id of the reserve to liquidate
     * @param borrowId The id of liquidate borrow target
     **/
    function bidCall(uint256 reserveId, uint256 borrowId) external payable;

    /**
     * @dev Function to claim the liquidate NFT.
     * @param reserveId The id of the reserve to liquidate
     * @param borrowId The id of liquidate borrow target
     **/
    function claimCall(uint256 reserveId, uint256 borrowId) external;

    /**
     * @dev Returns the user account data across the specified reserve
     * @param reserveId The id of the reserve
     * @param user The address of the user
     **/
    function getUserAccountData(uint256 reserveId, address user)
        external
        view
        returns (
            uint256 stableDebt,
            uint256 variableDebt,
            uint256[] memory borrowIds
        );

    function initReserve(
        address asset,
        address hTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function addNFT(uint256 reserveId, address asset) external;

    function setReserveInterestRateStrategyAddress(
        uint256 reserveId,
        address rateStrategyAddress
    ) external;

    function setConfiguration(uint256 reserveId, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param reserveId The id of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(uint256 reserveId)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param reserveId The id of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(uint256 reserveId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param reserveId The id of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(uint256 reserveId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param reserveId The id of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(uint256 reserveId)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getReservesList() external view returns (address[] memory);

    function setPause(bool val) external;

    // function setMinBorrowTime(uint40 _time) external;

    function paused() external view returns (bool);

    function getReservesCount() external view returns (uint256);

    // function getReserveRate(uint256 reserveId)
    //     external
    //     view
    //     returns (DataTypes.Rate memory);
}

interface IPriceOracle {
    function addConsumer(address _addr) external;

    function requestNFTPrice(
        address _nft,
        address _callbackAddr,
        bytes4 _callbackFn
    ) external returns (bytes32);

    function requestNFTPriceFloor(
        address _nft,
        address _callbackAddr,
        bytes4 _callbackFn
    ) external returns (bytes32);
}

interface IPunk {
    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Hasai Governance
 * @author Hasai
 **/
interface IHasaiPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event HasaiPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event HasaiPoolLiquidatorUpdated(address indexed newAddress);
    event HasaiPoolConfiguratorUpdated(address indexed newAddress);
    event HasaiPoolFactoryUpdated(address indexed newAddress);
    event RateStrategyUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress);
    event AddressRevoke(bytes32 id, address indexed oldAddress);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function revokeAddress(bytes32 id, address oldAddress) external;

    function getAddress(bytes32 id) external view returns (address[] memory);

    function hasRole(bytes32 id, address account) external view returns (bool);

    function getHasaiPool() external view returns (address[] memory);

    function isHasaiPool(address account) external view returns (bool);

    function setHasaiPool(address pool) external;

    function getHasaiPoolLiquidator() external view returns (address[] memory);
    
    function isLiquidator(address account) external view returns (bool);

    function setHasaiPoolLiquidator(address liquidator) external;

    function getHasaiPoolConfigurator() external view returns (address[] memory);
    
    function isConfigurator(address account) external view returns (bool);

    function setHasaiPoolConfigurator(address configurator) external;

    function getHasaiPoolFactory() external view returns (address[] memory);
    
    function isFactory(address account) external view returns (bool);

    function setHasaiPoolFactory(address factory) external;

    function getPoolAdmin() external view returns (address[] memory);
    
    function isAdmin(address account) external view returns (bool);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address[] memory);
    
    function isEmergencyAdmin(address account) external view returns (bool);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address[] memory);

    function isOracle(address account) external view returns (bool);

    function setPriceOracle(address priceOracle) external;

    function getRateStrategy() external view returns (address[] memory);

    function isStrategy(address account) external view returns (bool);

    function setRateStrategy(address rateStrategy) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        // variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        // the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address hTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint256 id;
        address[] nfts;
    }

    struct ReserveConfigurationMap {
        // bit 0-15: factor
        // bit 16-31: borrow ratio
        // bit 32-71: period
        // bit 72-111: min borrow time
        // bit 112: reserve is active
        uint256 data;
    }

    struct Request {
        address user;
        address nft;
        uint256 id;
        InterestRateMode rateMode;
        LoanMode loanMode;
        uint256 reserveId;
    }

    enum Status {
        BORROW,
        REPAY,
        AUCTION,
        WITHDRAW
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    enum LoanMode {
        NONE,
        FIXED,
        FLOAT
    }

    struct BorrowInfo {
        address nft;
        uint256 nftId;
        address user;
        uint64 startTime;
        uint256 price;
        uint256 borrowId;
        uint64 liquidateTime;
        Status status;
        InterestRateMode rateMode;
        LoanMode loanMode;
    }

    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 borrowId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    struct InitReserveInput {
        uint256 reserveId;
        address hTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        uint16 factor;
        uint16 borrowRatio;
        uint40 period;
        uint40 minBorrowTime;
    }

    struct RateStrategyInput {
        uint256 reserveId;
        uint256 optimalUtilizationRate;
        uint256 baseVariableBorrowRate;
        uint256 variableSlope1;
        uint256 variableSlope2;
        uint256 baseStableBorrowRate;
        uint256 stableSlope1;
        uint256 stableSlope2;
    }
    
    struct Rate {
        /**
         * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
         * Expressed in ray
         **/
        uint256 optimalUtilizationRate;
        /**
         * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
         * 1-optimal utilization rate. Added as a constant here for gas optimizations.
         * Expressed in ray
         **/
        uint256 excessUtilizationRate;
        // Base variable borrow rate when Utilization rate = 0. Expressed in ray
        uint256 baseVariableBorrowRate;
        // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 variableRateSlope1;
        // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 variableRateSlope2;
        // Base stable borrow rate when Utilization rate = 0. Expressed in ray
        uint256 baseStableBorrowRate;
        // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 stableRateSlope1;
        // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
        uint256 stableRateSlope2;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title Errors library
 * @author Hasai
 * @notice Defines the error messages emitted by the different contracts of the Hasai protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (HToken, VariableDebtToken and StableDebtToken)
 *  - HT = HToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = HasaiPool
 *  - HF = HasaiFactory
 *  - LPC = HasaiPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = HasaiPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '25'; // 'The caller must be the pool admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '41'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '3'; // 'User cannot withdraw more than the available balance'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '4'; // 'Invalid interest rate mode selected'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '5'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NOT_NFT_OWNER = '6'; // 'User is not the owner of the nft'
  string public constant VL_NOT_SUPPORT = '7'; // 'User's nft for borrow is not support'
  string public constant VL_TOO_EARLY = '8'; // 'Action is earlier than requested'
  string public constant VL_TOO_LATE = '9'; // 'Action is later than requested'
  string public constant VL_BAD_STATUS = '10'; // 'Action with wrong borrow status'
  string public constant VL_INVALID_USER = '11'; // 'User is not borrow owner'
  string public constant VL_AUCTION_ALREADY_SETTLED = '12'; // 'Auction is already done'
  string public constant VL_BAD_BORROW_ID = '13'; // 'Bid for wrong borrow id'
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '14'; // 'User does not have any stable rate loan for this reserve'
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '15'; // 'Interest rate rebalance conditions were not met'
  string public constant LP_LIQUIDATION_CALL_FAILED = '16'; // 'Liquidation call failed'
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '17'; // 'The requested amount is too small for an action.'
  string public constant LP_CALLER_NOT_HASAI_POOL_CONFIGURATOR = '18'; // 'The caller of the function is not the Hasai pool configurator'
  string public constant LP_CALLER_NOT_HASAI_POOL_ORACLE = '19'; // 'The caller of the function is not the Hasai pool oracle'
  string public constant LP_CALLER_NOT_HASAI_POOL_FACTORY = '20'; // 'The caller of the function is not the Hasai pool factory'
  string public constant LP_NFT_ALREADY_EXIST = '21'; // 'The initial reserve nft is already exist'
  string public constant LP_WETH_TRANSFER_FAILED = '22'; // ' Failed to transfer eth and weth'
  string public constant CT_CALLER_MUST_BE_HASAI_POOL = '23'; // 'The caller of this function must be a Hasai pool'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '24'; // 'Reserve has already been initialized'
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '26'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = '27'; // 'The caller must be the emergency admin'
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '28'; // 'Health factor is not below the threshold'
  string public constant LPCM_NO_ERRORS = '29'; // 'No errors'
  string public constant MATH_MULTIPLICATION_OVERFLOW = '30';
  string public constant MATH_ADDITION_OVERFLOW = '31';
  string public constant MATH_DIVISION_BY_ZERO = '32';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '33'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '34'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '35'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '36'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '37'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '38'; //invalid amount to mint
  string public constant LP_FAILED_REPAY_WITH_COLLATERAL = '39';
  string public constant CT_INVALID_BURN_AMOUNT = '40'; //invalid amount to burn
  string public constant LP_IS_PAUSED = '42'; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '43';
  string public constant RC_INVALID_RESERVE_FACTOR = '44';
  string public constant RC_INVALID_BORROW_RATIO = '45';
  string public constant RC_INVALID_PERIOD = '46';
  string public constant RC_INVALID_MIN_BORROW_TIME = '47';
  string public constant LP_NOT_CONTRACT = '48';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '49';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '50';
  string public constant SDT_CREATION_FAILED = '51';
  string public constant VDT_CREATION_FAILED = '52';
  string public constant HF_LIQUIDITY_INSUFFICIENT = '53';
  string public constant HT_CREATION_FAILED = '54';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Hasai
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 **/
abstract contract BasicERC20 is ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable
{

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return The name of the token
     **/
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @return The symbol of the token
     **/
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @return The decimals of the token
     **/
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @return The total supply of the token
     **/
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return The balance of the token
     **/
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev Executes a transfer of tokens from _msgSender() to recipient
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens being transferred
     * @return `true` if the transfer succeeds, `false` otherwise
     **/
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the allowance of spender on the tokens owned by owner
     * @param owner The owner of the tokens
     * @param spender The user allowed to spend the owner's tokens
     * @return The amount of owner's tokens spender is allowed to spend
     **/
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Allows `spender` to spend the tokens owned by _msgSender()
     * @param spender The user allowed to spend _msgSender() tokens
     * @return `true`
     **/
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
     * @param sender The owner of the tokens
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens being transferred
     * @return `true` if the transfer succeeds, `false` otherwise
     **/
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     **/
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        require(_allowances[_msgSender()][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 oldSenderBalance = _balances[sender];
        require(oldSenderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = oldSenderBalance - amount;
        _balances[recipient] = _balances[recipient] + amount;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply + amount;

        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance + amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply + amount;

        uint256 oldAccountBalance = _balances[account];
        require(oldAccountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = oldAccountBalance - amount;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setName(string memory newName) internal {
        _name = newName;
    }

    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../libraries/utils/WadRayMath.sol";
import "../libraries/utils/Errors.sol";
import "../interfaces/IHasaiPool.sol";
import "../interfaces/IHToken.sol";
import "../interfaces/IHasaiPoolAddressesProvider.sol";
import "./BasicERC20.sol";

/**
 * @title Hasai ERC20 HToken
 * @dev Implementation of the interest bearing token for the Hasai protocol
 * @author Hasai
 */
contract HToken is
  Initializable,
  BasicERC20('HTOKEN_IMPL', 'HTOKEN_IMPL', 0),
  IHToken,
  ERC721HolderUpgradeable
{
  using WadRayMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IHasaiPoolAddressesProvider internal _addressesProvider;
  address internal _treasury;
  address internal _underlyingAsset;
  uint256 internal _reserveId;

  modifier onlyHasaiPool {
    require(_msgSender() == address(_getHasaiPool()), Errors.CT_CALLER_MUST_BE_HASAI_POOL);
    _;
  }

  /**
   * @dev Initializes the hToken
   * @param provider The address of the address provider where this hToken will be used
   * @param reserveId The id of the reserves
   * @param treasury The address of the Hasai treasury, receiving the fees on this hToken
   * @param underlyingAsset The address of the underlying asset of this hToken (E.g. WETH for aWETH)
   * @param hTokenDecimals The decimals of the hToken, same as the underlying asset's
   * @param hTokenName The name of the hToken
   * @param hTokenSymbol The symbol of the hToken
   */
  function initialize(
    IHasaiPoolAddressesProvider provider,
    uint256 reserveId,
    address treasury,
    address underlyingAsset,
    uint8 hTokenDecimals,
    string calldata hTokenName,
    string calldata hTokenSymbol
  ) external override initializer {

    _setName(hTokenName);
    _setSymbol(hTokenSymbol);
    _setDecimals(hTokenDecimals);

    _addressesProvider = provider;
    _treasury = treasury;
    _underlyingAsset = underlyingAsset;

    emit Initialize(
      underlyingAsset,
      _addressesProvider.getHasaiPool()[0],
      reserveId,
      treasury,
      hTokenDecimals,
      hTokenName,
      hTokenSymbol
    );
  }

  /**
   * @dev Burns hTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * - Only callable by the HasaiPool, as extra state updates there need to be managed
   * @param user The owner of the hTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyHasaiPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
    _burn(user, amountScaled);

    IERC20Upgradeable(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Transfer(user, address(0), amount);
    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  /**
   * @dev Mints `amount` hTokens to `user`
   * - Only callable by the HasaiPool, as extra state updates there need to be managed
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyHasaiPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    _mint(user, amountScaled);

    emit Transfer(address(0), user, amount);
    emit Mint(user, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Mints hTokens to the reserve treasury
   * - Only callable by the HasaiPool
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external override onlyHasaiPool {
    if (amount == 0) {
      return;
    }

    address treasury = _treasury;

    // Compared to the normal mint, we don't check for rounding errors.
    // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
    // In that case, the treasury will experience a (very small) loss, but it
    // wont cause potentially valid transactions to fail.
    _mint(treasury, amount.rayDiv(index));

    emit Transfer(address(0), treasury, amount);
    emit Mint(treasury, amount, index);
  }

  /**
   * @dev Transfers hTokens in the event of a borrow being liquidated, in case the liquidators reclaims the hToken
   * - Only callable by the HasaiPool
   * @param from The address getting liquidated, current owner of the hTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external override onlyHasaiPool {
    // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
    // so no need to emit a specific event here
    _transfer(from, to, value);

    emit Transfer(from, to, value);
  }

  /**
   * @dev Calculates the balance of the user: principal balance + interest generated by the principal
   * @param user The user whose balance is calculated
   * @return The balance of the user
   **/
  function balanceOf(address user)
    public
    view
    override(BasicERC20, IERC20Upgradeable)
    returns (uint256)
  {
    IHasaiPool pool = _getHasaiPool();
    return super.balanceOf(user).rayMul(pool.getReserveNormalizedIncome(_reserveId));
  }

  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev calculates the total supply of the specific hToken
   * since the balance of every single user increases over time, the total supply
   * does that too.
   * @return the current total supply
   **/
  function totalSupply() public view override(BasicERC20, IERC20Upgradeable) returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    IHasaiPool pool = _getHasaiPool();
    return currentSupplyScaled.rayMul(pool.getReserveNormalizedIncome(_reserveId));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the address of the Hasai treasury, receiving the fees on this hToken
   **/
  function RESERVE_TREASURY_ADDRESS() public view returns (address) {
    return _treasury;
  }

  /**
   * @dev Returns the address of the underlying asset of this hToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() public override view returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this hToken is used
   **/
  function POOL() public view returns (IHasaiPool) {
    return _getHasaiPool();
  }

  /**
   * @dev Transfers the underlying asset to `target`. Used by the HasaiPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the hTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address target, uint256 amount)
    external
    override
    onlyHasaiPool
    returns (uint256)
  {
    IERC20Upgradeable(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  /**
   * @dev Transfers the underlying asset to `target`. Used by the HasaiPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param nft The nft address
   * @param target The recipient of the hTokens
   * @param nftId The token id of nft
   * @return The amount transferred
   **/
  function transferUnderlyingNFTTo(address nft, address target, uint256 nftId, bool flag)
    external
    override
    onlyHasaiPool
    returns (uint256)
  {
    if (flag) {
      IPunk(nft).transferPunk(target, nftId);
      return nftId;
    } else {
      return transferUnderlyingNFTTo(nft, target, nftId);
    }
  }

  function transferUnderlyingNFTTo(address nft, address target, uint256 nftId)
    internal
    returns (uint256)
  {
    IERC721Upgradeable(nft).safeTransferFrom(address(this), target, nftId);
    return nftId;
  }

  function _getHasaiPool() internal view returns (IHasaiPool) {
    return IHasaiPool(_addressesProvider.getHasaiPool()[0]);
  }

  /**
   * @dev Invoked to execute actions on the hToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external override onlyHasaiPool {}

  /**
   * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    IHasaiPool pool = _getHasaiPool();

    uint256 index = pool.getReserveNormalizedIncome(_reserveId);

    super._transfer(from, to, amount.rayDiv(index));

    emit BalanceTransfer(from, to, amount, index);
  }

  event NFTReceived(
        address indexed operator,
        address indexed from,
        uint256 indexed tokenId,
        bytes data
    );

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721HolderUpgradeable) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}