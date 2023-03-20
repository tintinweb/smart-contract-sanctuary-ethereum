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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IIncentivesController {
  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param totalSupply The total supply of the asset in the lending pool
   * @param userBalance The balance of the user of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IUToken} from "./IUToken.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPool {
  /**
   * @dev Emitted when _rescuer is modified in the LendPool
   * @param newRescuer The address of the new rescuer
   **/
  event RescuerChanged(address indexed newRescuer);

  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the uTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of uTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(address indexed user, address indexed reserve, uint256 amount, address indexed to);

  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   * @param nftConfigFee an estimated gas cost fee for configuring the NFT
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral,
    uint256 nftConfigFee
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when an NFT is purchased via Buyout.
   * @param user The address of the user initiating the Buyout
   * @param reserve The address of the underlying asset of the reserve
   * @param buyoutAmount The amount of reserve paid by the buyer
   * @param borrowAmount The loan borrowed amount
   * @param nftAsset The amount of reserve received by the borrower
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The loan borrower address
   * @param onBehalfOf The receiver of the underlying NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Buyout(
    address user,
    address indexed reserve,
    uint256 buyoutAmount,
    uint256 borrowAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address borrower,
    address onBehalfOf,
    uint256 indexed loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated on NFTX.
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event LiquidateNFTX(
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );
  /**
   * @dev Emitted when an NFT configuration is triggered.
   * @param user The NFT holder
   * @param nftAsset The NFT collection address
   * @param nftTokenId The NFT token Id
   **/
  event ValuationApproved(address indexed user, address indexed nftAsset, uint256 indexed nftTokenId);
  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when the pause time is updated.
   */
  event PausedTimeUpdated(uint256 startTime, uint256 durationTime);

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
   * gets added to the LendPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
  @dev Emitted after the address of the interest rate strategy contract has been updated
  */
  event ReserveInterestRateAddressChanged(address indexed asset, address indexed rateAddress);

  /**
  @dev Emitted after setting the configuration bitmap of the reserve as a whole
  */
  event ReserveConfigurationChanged(address indexed asset, uint256 configuration);

  /**
  @dev Emitted after setting the configuration bitmap of the NFT collection as a whole
  */
  event NftConfigurationChanged(address indexed asset, uint256 configuration);

  /**
  @dev Emitted after setting the configuration bitmap of the NFT as a whole
  */
  event NftConfigurationByIdChanged(address indexed asset, uint256 indexed nftTokenId, uint256 configuration);

  /**
  @dev Emitted after setting the new safe health factor value for redeems
  */
  event SafeHealthFactorUpdated(uint256 indexed newSafeHealthFactor);

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying uTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 uusdc
   * @param reserve The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the uTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of uTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(address reserve, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent uTokens owned
   * E.g. User has 100 uusdc, calls withdraw() and receives 100 USDC, burning the 100 uusdc
   * @param reserve The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole uToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(address reserve, uint256 amount, address to) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256, bool);

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(address nftAsset, uint256 nftTokenId, uint256 bidPrice, address onBehalfOf) external;

  /**
   * @dev Function to buyout a non-healthy position collateral-wise
   * - The bidder want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param buyoutAmount The buyout price of the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function buyout(address nftAsset, uint256 nftTokenId, uint256 buyoutAmount, address onBehalfOf) external;

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(address nftAsset, uint256 nftTokenId, uint256 amount, uint256 bidFine) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(address nftAsset, uint256 nftTokenId, uint256 amount) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX & Sushiswap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateNFTX(address nftAsset, uint256 nftTokenId, uint256 amountOutMin) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The collateral asset is sold on NFTX & Sushiswap
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidateSudoSwap(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amountOutMin,
    address LSSVMPair,
    uint256 amountOutMinSudoswap
  ) external returns (uint256);

  /**
   * @dev Approves valuation of an NFT for a user
   * @dev Just the NFT holder can trigger the configuration
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function approveValuation(address nftAsset, uint256 nftTokenId) external payable;

  /**
   * @dev Validates and finalizes an uToken transfer
   * - Only callable by the overlying uToken of the `asset`
   * @param asset The address of the underlying asset of the uToken
   * @param from The user from which the uTokens are transferred
   * @param to The user receiving the uTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The uToken balance of the `from` user before the transfer
   * @param balanceToBefore The uToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external view;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getReserveConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfiguration(address asset) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @param tokenId the Token Id of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfigByTokenId(
    address asset,
    uint256 tokenId
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @dev Returns the list of the initialized reserves
   * @return the list of initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @dev Returns the state and configuration of the nft
   * @param asset The address of the underlying asset of the nft
   * @return The status of the nft
   **/
  function getNftData(address asset) external view returns (DataTypes.NftData memory);

  /**
   * @dev Returns the configuration of the nft asset
   * @param asset The address of the underlying asset of the nft
   * @param tokenId NFT asset ID
   * @return The configuration of the nft asset
   **/
  function getNftAssetConfig(
    address asset,
    uint256 tokenId
  ) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  )
    external
    view
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    );

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    );

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(
    address nftAsset,
    uint256 nftTokenId
  )
    external
    view
    returns (uint256 loanId, address bidderAddress, uint256 bidPrice, uint256 bidBorrowAmount, uint256 bidFine);

  /**
   * @dev Returns the list of nft addresses in the protocol
   **/
  function getNftsList() external view returns (address[] memory);

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendPool contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external;

  function setPausedTime(uint256 startTime, uint256 durationTime) external;

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view returns (bool);

  function getPausedTime() external view returns (uint256, uint256);

  /**
   * @dev Returns the cached LendPoolAddressesProvider connected to this contract
   **/

  function getAddressesProvider() external view returns (ILendPoolAddressesProvider);

  /**
   * @dev Initializes a reserve, activating it, assigning an uToken and nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param uTokenAddress The address of the uToken that will be assigned to the reserve
   * @param debtTokenAddress The address of the debtToken that will be assigned to the reserve
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address uTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external;

  /**
   * @dev Initializes a nft, activating it, assigning nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the nft
   **/
  function initNft(address asset, address uNftAddress) external;

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateAddress(address asset, address rateAddress) external;

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setReserveConfiguration(address asset, uint256 configuration) external;

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param configuration The new configuration bitmap
   **/
  function setNftConfiguration(address asset, uint256 configuration) external;

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param nftTokenId the NFT tokenId
   * @param configuration The new configuration bitmap
   **/
  function setNftConfigByTokenId(address asset, uint256 nftTokenId, uint256 configuration) external;

  /**
   * @dev Sets the max supply and token ID for a given asset
   * @param asset The address to set the data
   * @param maxSupply The max supply value
   * @param maxTokenId The max token ID value
   **/
  function setNftMaxSupplyAndTokenId(address asset, uint256 maxSupply, uint256 maxTokenId) external;

  /**
   * @dev Sets the max number of reserves in the protocol
   * @param val the value to set the max number of reserves
   **/
  function setMaxNumberOfReserves(uint256 val) external;

  /**
   * @dev Sets the max number of NFTs in the protocol
   * @param val the value to set the max number of NFTs
   **/
  function setMaxNumberOfNfts(uint256 val) external;

  /**
   * @notice Assigns the rescuer role to a given address.
   * @param newRescuer New rescuer's address
   */
  function updateRescuer(address newRescuer) external;

  /**
   * @notice Update the safe health factor value for redeems
   * @param newSafeHealthFactor New safe health factor value
   */
  function updateSafeHealthFactor(uint256 newSafeHealthFactor) external;

  /**
   * @dev Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve the reserve object
   **/
  function updateReserveState(address reserve) external;

  /**
   * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
   * @param reserve The address of the reserve to be updated
   **/
  function updateReserveInterestRates(address reserve) external;

  /**
   * @notice Rescue tokens or ETH locked up in this contract.
   * @param tokenContract ERC20 token contract address
   * @param to        Recipient address
   * @param amount    Amount to withdraw
   * @param rescueETH bool to know if we want to rescue ETH or other token
   */
  function rescue(IERC20 tokenContract, address to, uint256 amount, bool rescueETH) external;

  /**
   * @notice Rescue NFTs locked up in this contract.
   * @param nftAsset ERC721 asset contract address
   * @param tokenId ERC721 token id
   * @param to Recipient address
   */
  function rescueNFT(IERC721Upgradeable nftAsset, uint256 tokenId, address to) external;

  /**
   * @dev Sets the fee percentage for liquidations
   * @param percentage the fee percentage to be set
   **/
  function setLiquidateFeePercentage(uint256 percentage) external;

  /**
   * @dev Sets the max timeframe between NFT config triggers and borrows
   * @param timeframe the number of seconds for the timeframe
   **/
  function setTimeframe(uint256 timeframe) external;

  /**
   * @dev Adds and address to be allowed to sell on NFTX
   * @param nftAsset the nft address of the NFT to sell
   * @param val if true is allowed to sell if false is not
   **/
  function setIsMarketSupported(address nftAsset, uint8 market, bool val) external;

  /**
   * @dev sets the fee for configuringNFTAsCollateral
   * @param configFee the amount to charge to the user
   **/
  function setConfigFee(uint256 configFee) external;

  /**
   * @dev sets the fee to be charged on first bid on nft
   * @param auctionDurationConfigFee the amount to charge to the user
   **/
  function setAuctionDurationConfigFee(uint256 auctionDurationConfigFee) external;

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendPool
   */
  function getMaxNumberOfReserves() external view returns (uint256);

  /**
   * @dev Returns the maximum number of nfts supported to be listed in this LendPool
   */
  function getMaxNumberOfNfts() external view returns (uint256);

  /**
   * @dev Returns the fee percentage for liquidations
   **/
  function getLiquidateFeePercentage() external view returns (uint256);

  /**
   * @notice Returns current rescuer
   * @return Rescuer's address
   */
  function rescuer() external view returns (address);

  /**
   * @notice Returns current safe health factor
   * @return The safe health factor value
   */
  function getSafeHealthFactor() external view returns (uint256);

  /**
   * @dev Returns the max timeframe between NFT config triggers and borrows
   **/
  function getTimeframe() external view returns (uint256);

  /**
   * @dev Returns the configFee amount
   **/
  function getConfigFee() external view returns (uint256);

  /**
   * @dev Returns the auctionDurationConfigFee amount
   **/
  function getAuctionDurationConfigFee() external view returns (uint256);

  /**
   * @dev Returns if the address is allowed to sell or not on NFTX
   */
  function getIsMarketSupported(address nftAsset, uint8 market) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Unlockd Governance
 * @author Unlockd
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event UNFTRegistryUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event UnlockdDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);
  event NFTXVaultFactoryUpdated(address indexed newAddress);
  event SushiSwapRouterUpdated(address indexed newAddress);
  event LSSVMRouterUpdated(address indexed newAddress);
  event LendPoolLiquidatorUpdated(address indexed newAddress);
  event LtvManagerUpdated(address indexed newAddress);

  /**
   * @dev Returns the id of the Unlockd market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl, bytes memory encodedCallData) external;

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @dev Returns the address of the LendPool proxy
   * @return The LendPool proxy address
   **/
  function getLendPool() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendPool implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  /**
   * @dev Returns the address of the LendPoolConfigurator proxy
   * @return The LendPoolConfigurator proxy address
   **/
  function getLendPoolConfigurator() external view returns (address);

  /**
   * @dev Updates the implementation of the LendPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendPoolConfigurator implementation
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the LendPool admin
   * @return the LendPoolAdmin address
   **/
  function getPoolAdmin() external view returns (address);

  /**
   * @dev sets the address of the LendPool admin
   * @param admin the LendPoolAdmin address
   **/
  function setPoolAdmin(address admin) external;

  /**
   * @dev returns the address of the emergency admin
   * @return the EmergencyAdmin address
   **/
  function getEmergencyAdmin() external view returns (address);

  /**
   * @dev sets the address of the emergency admin
   * @param admin the EmergencyAdmin address
   **/
  function setEmergencyAdmin(address admin) external;

  /**
   * @dev returns the address of the reserve oracle
   * @return the ReserveOracle address
   **/
  function getReserveOracle() external view returns (address);

  /**
   * @dev sets the address of the reserve oracle
   * @param reserveOracle the ReserveOracle address
   **/
  function setReserveOracle(address reserveOracle) external;

  /**
   * @dev returns the address of the NFT oracle
   * @return the NFTOracle address
   **/
  function getNFTOracle() external view returns (address);

  /**
   * @dev sets the address of the NFT oracle
   * @param nftOracle the NFTOracle address
   **/
  function setNFTOracle(address nftOracle) external;

  /**
   * @dev returns the address of the lendpool loan
   * @return the LendPoolLoan address
   **/
  function getLendPoolLoan() external view returns (address);

  /**
   * @dev sets the address of the lendpool loan
   * @param loan the LendPoolLoan address
   * @param encodedCallData calldata to execute
   **/
  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  /**
   * @dev returns the address of the UNFT Registry
   * @return the UNFTRegistry address
   **/
  function getUNFTRegistry() external view returns (address);

  /**
   * @dev sets the address of the UNFT registry
   * @param factory the UNFTRegistry address
   **/
  function setUNFTRegistry(address factory) external;

  /**
   * @dev returns the address of the incentives controller
   * @return the IncentivesController address
   **/
  function getIncentivesController() external view returns (address);

  /**
   * @dev sets the address of the incentives controller
   * @param controller the IncentivesController address
   **/
  function setIncentivesController(address controller) external;

  /**
   * @dev returns the address of the UI data provider
   * @return the UIDataProvider address
   **/
  function getUIDataProvider() external view returns (address);

  /**
   * @dev sets the address of the UI data provider
   * @param provider the UIDataProvider address
   **/
  function setUIDataProvider(address provider) external;

  /**
   * @dev returns the address of the Unlockd data provider
   * @return the UnlockdDataProvider address
   **/
  function getUnlockdDataProvider() external view returns (address);

  /**
   * @dev sets the address of the Unlockd data provider
   * @param provider the UnlockdDataProvider address
   **/
  function setUnlockdDataProvider(address provider) external;

  /**
   * @dev returns the address of the wallet balance provider
   * @return the WalletBalanceProvider address
   **/
  function getWalletBalanceProvider() external view returns (address);

  /**
   * @dev sets the address of the wallet balance provider
   * @param provider the WalletBalanceProvider address
   **/
  function setWalletBalanceProvider(address provider) external;

  function getNFTXVaultFactory() external view returns (address);

  /**
   * @dev sets the address of the NFTXVault Factory contract
   * @param factory the NFTXVault Factory address
   **/
  function setNFTXVaultFactory(address factory) external;

  /**
   * @dev returns the address of the SushiSwap router contract
   **/
  function getSushiSwapRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the LSSVM router address
   **/
  function setSushiSwapRouter(address router) external;

  /**
   * @dev returns the address of the LSSVM router contract
   **/
  function getLSSVMRouter() external view returns (address);

  /**
   * @dev sets the address of the LSSVM router contract
   * @param router the SushiSwap router address
   **/
  function setLSSVMRouter(address router) external;

  /**
   * @dev returns the address of the LendPool liquidator contract
   **/
  function getLendPoolLiquidator() external view returns (address);

  /**
   * @dev sets the address of the LendPool liquidator contract
   * @param liquidator the LendPool liquidator address
   **/
  function setLendPoolLiquidator(address liquidator) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface ILendPoolLoan {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    address indexed onBehalfOf,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is updated
   * @param user The address initiating the action
   */
  event LoanUpdated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is auction by the liquidator
   * @param user The address initiating the action
   */
  event LoanAuctioned(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 borrowIndex,
    address bidder,
    uint256 price,
    address previousBidder,
    uint256 previousPrice
  );

  /**
   * @dev Emitted when a loan is bought out
   * @param loanId The loanId that was bought out
   */
  event LoanBoughtOut(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidBorrowAmount,
    uint256 borrowIndex,
    uint256 buyoutAmount
  );

  /**
   * @dev Emitted when a loan is redeemed
   * @param user The address initiating the action
   */
  event LoanRedeemed(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate on NFTX
   */
  event LoanLiquidatedNFTX(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex,
    uint256 sellPrice
  );

  /**
   * @dev Emitted when a loan is liquidate on SudoSwap
   */
  event LoanLiquidatedSudoSwap(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex,
    uint256 sellPrice,
    address LSSVMPair
  );

  /**
   * @dev Emitted when a loan is liquidated in an external market
   */
  event LoanLiquidatedMarket(
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  function initNft(address nftAsset, address uNftAddress) external;

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow
   * @param onBehalfOf The address receiving the loan
   * @param nftAsset The address of the underlying NFT asset
   * @param nftTokenId The token Id of the underlying NFT asset
   * @param uNftAddress The address of the uNFT token
   * @param reserveAsset The address of the underlying reserve asset
   * @param amount The loan amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address uNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external returns (uint256);

  /**
   * @dev Update the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Active
   * @param initiator The address of the user updating the loan
   * @param loanId The loan ID
   * @param amountAdded The amount added to the loan
   * @param amountTaken The amount taken from the loan
   * @param borrowIndex The index to get the scaled loan amount
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param amount The amount repaid
   * @param borrowIndex The index to get the scaled loan amount
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Auction the given loan
   *
   * Requirements:
   *  - The price must be greater than current highest price
   *  - The loan must be in state Active or Auction
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting auctioned
   * @param bidPrice The bid price of this auction
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Buyout the given loan
   *
   * Requirements:
   *  - The price has to be the valuation price of the nft
   *  - The loan must be in state Active or Auction
   */
  function buyoutLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    uint256 buyoutAmount
  ) external;

  /**
   * @dev Redeem the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Auction
   * @param initiator The address of the user initiating the borrow
   * @param loanId The loan getting redeemed
   * @param amountTaken The taken amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function redeemLoan(address initiator, uint256 loanId, uint256 amountTaken, uint256 borrowIndex) external;

  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned
   * @param uNftAddress The address of uNFT
   * @param borrowAmount The borrow amount
   * @param borrowIndex The index to get the scaled loan amount
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan on NFTX
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Auction
   *
   * @param loanId The loan getting burned
   */
  function liquidateLoanNFTX(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    uint256 amountOutMin
  ) external returns (uint256 sellPrice);

  /**
   * @dev Liquidate the given loan on SudoSwap
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Auction
   *
   * @param loanId The loan getting burned
   */
  function liquidateLoanSudoSwap(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    DataTypes.SudoSwapParams memory sudoswapParams
  ) external returns (uint256 sellPrice);

  /**
   * @dev Liquidate the given loan on an external market
   * @param loanId The loan getting burned
   * @param uNftAddress The address of the underlying uNft
   * @param borrowAmount Amount borrowed in the loan
   * @param borrowIndex The reserve index
   */
  function liquidateLoanMarket(uint256 loanId, address uNftAddress, uint256 borrowAmount, uint256 borrowIndex) external;

  /**
   * @dev Updates the `_marketAdapters` mapping, setting the params to
   * valid/unvalid adapters through the `flag` parameter
   * @param adapters The adapters addresses to be updated
   * @param flag `true` to set addresses as valid adapters, `false` otherwise
   */
  function updateMarketAdapters(address[] calldata adapters, bool flag) external;

  /**
   *  @dev returns the borrower of a specific loan
   * param loanId the loan to get the borrower from
   */
  function borrowerOf(uint256 loanId) external view returns (address);

  /**
   *  @dev returns the loan corresponding to a specific NFT
   * param nftAsset the underlying NFT asset
   * param tokenId the underlying token ID for the NFT
   */
  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  /**
   *  @dev returns the loan corresponding to a specific loan Id
   * param loanId the loan Id
   */
  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  /**
   *  @dev returns the collateral and reserve corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanCollateralAndReserve(
    uint256 loanId
  ) external view returns (address nftAsset, uint256 nftTokenId, address reserveAsset, uint256 scaledAmount);

  /**
   *  @dev returns the reserve and borrow __scaled__ amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the reserve and borrow  amount corresponding to a specific loan
   * param loanId the loan Id
   */
  function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanHighestBid(uint256 loanId) external view returns (address, uint256);

  /**
   *  @dev returns the collateral amount for a given NFT
   * param nftAsset the underlying NFT asset
   */
  function getNftCollateralAmount(address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the collateral amount for a given NFT and a specific user
   * param user the user
   * param nftAsset the underlying NFT asset
   */
  function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);

  /**
   *  @dev returns the counter tracker for all the loan ID's in the protocol
   */
  function getLoanIdTracker() external view returns (CountersUpgradeable.Counter memory);

  function reMintUNFT(address nftAsset, uint256 tokenId, address oldOnBehalfOf, address newOnBehalfOf) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

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
pragma solidity 0.8.4;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IUNFT is IERC721MetadataUpgradeable, IERC721ReceiverUpgradeable, IERC721EnumerableUpgradeable {
  /**
   * @dev Emitted when an uNFT is initialized
   * @param underlyingAsset The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the uNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned uNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Initializes the uNFT
   * @param underlyingAsset The address of the underlying asset of this uNFT (E.g. PUNK for bPUNK)
   */
  function initialize(address underlyingAsset, string calldata uNftName, string calldata uNftSymbol) external;

  /**
   * @dev Mints uNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the uNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user uNFT token
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IUNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event UNFTCreated(address indexed nftAsset, address uNftImpl, address uNftProxy, uint256 totals);
  event UNFTUpgraded(address indexed nftAsset, address uNftImpl, address uNftProxy, uint256 totals);

  /**
   * @dev gets the uNFT address
   * @param nftAsset The address of the underlying NFT asset
   **/
  function getUNFTAddresses(address nftAsset) external view returns (address uNftProxy, address uNftImpl);

  /**
   * @dev gets the uNFT address by index
   * @param index the uNFT index
   **/
  function getUNFTAddressesByIndex(uint16 index) external view returns (address uNftProxy, address uNftImpl);

  /**
   * @dev gets the list of uNFTs
   **/
  function getUNFTAssetList() external view returns (address[] memory);

  /**
   * @dev gets the length of the list of uNFTs
   **/
  function allUNFTAssetLength() external view returns (uint256);

  /**
   * @dev initializes the contract
   **/
  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  /**
   * @dev sets the uNFT generic implementation
   * @dev genericImpl the implementation contract
   **/
  function setUNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create uNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   **/
  function createUNFT(address nftAsset) external returns (address uNftProxy);

  /**
   * @dev Create uNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   * @param uNftImpl The address of the deployed implement of the UNFT
   **/
  function createUNFTWithImpl(address nftAsset, address uNftImpl) external returns (address uNftProxy);

  /**
   * @dev Update uNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the UNFT
   * @param uNftImpl The address of the deployed implement of the UNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeUNFTWithImpl(
    address nftAsset,
    address uNftImpl,
    bytes memory encodedCallData
  ) external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IUToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when an uToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this uToken
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController
  );

  /**
   * @dev Initializes the bToken
   * @param addressProvider The address of the address provider where this bToken will be used
   * @param treasury The address of the Unlockd treasury, receiving the fees on this bToken
   * @param underlyingAsset The address of the underlying asset of this bToken
   * @param uTokenDecimals The amount of token decimals
   * @param uTokenName The name of the token
   * @param uTokenSymbol The token symbol
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 uTokenDecimals,
    string calldata uTokenName,
    string calldata uTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);
  /**
   * @dev Emitted after setting of addresses as managers
   * @param managers the managers to be updated
   * @param flag `true` to set addresses as managers, `false` otherwise
   **/
  event UTokenManagersUpdated(address[] indexed managers, bool flag);

  /**
   * @dev Mints `amount` uTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(address user, uint256 amount, uint256 index) external returns (bool);

  /**
   * @dev Emitted after uTokens are burned
   * @param from The owner of the uTokens, getting them burned
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
   * @dev Emitted when treasury address is updated in utoken
   * @param _newTreasuryAddress The new treasury address
   **/
  event TreasuryAddressUpdated(address indexed _newTreasuryAddress);

  /**
    @dev Emitted after sweeping liquidity from the uToken to deposit it to external lending protocol
  * @param uToken The uToken swept
  * @param underlyingAsset The underlying asset from the uToken
  * @param amount The amount deposited to the lending protocol
  */
  event UTokenSwept(address indexed uToken, address indexed underlyingAsset, uint256 indexed amount);

  /**
   * @dev Takes reserve liquidity from uToken and deposits it to external lening protocol
   **/
  function sweepUToken() external;

  /**
   * @dev Burns uTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the uTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(address user, address receiverOfUnderlying, uint256 amount, uint256 index) external;

  /**
   * @dev Mints uTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Deposits `amount` to the lending protocol currently active
   * @param amount The amount of tokens to deposit
   */
  function depositReserves(uint256 amount) external;

  /**
   * @dev Withdraws `amount` from the lending protocol currently active
   * @param amount The amount of tokens to withdraw
   */
  function withdrawReserves(uint256 amount) external returns (uint256);

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow() and withdraw()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @return The available liquidity in reserve
   **/
  function getAvailableLiquidity() external view returns (uint256);

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this uToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @dev Returns the address of the treasury set to this uToken
   **/
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @dev Sets the address of the treasury to this uToken
   **/
  function setTreasuryAddress(address treasury) external;

  /**
   * @dev Updates the uToken manager addresses
   **/
  function updateUTokenManagers(address[] calldata managers, bool flag) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/interface/INFTXVault.sol
 */
interface INFTXVault is IERC20 {
  function mint(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts /* ignored for ERC721 vaults */
  ) external returns (uint256);

  function allValidNFTs(uint256[] calldata tokenIds) external view returns (bool);

  function vaultId() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @dev https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/interface/INFTXVaultFactory.sol
 */
interface INFTXVaultFactoryV2 {
  // Read functions.
  function feeDistributor() external view returns (address);

  function numVaults() external view returns (uint256);

  function vaultsForAsset(address asset) external view returns (address[] memory);

  function vaultFees(uint256 vaultId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  // Write functions.
  function createVault(
    string calldata name,
    string calldata symbol,
    address _assetAddress,
    bool is1155,
    bool allowAllItems
  ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILSSVMPair {
  enum CurveErrorCodes {
    OK, // No error
    INVALID_NUMITEMS, // The numItem value is 0
    SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
  }

  function getBuyNFTQuote(
    uint256 numNFTs
  )
    external
    view
    returns (CurveErrorCodes error, uint256 newSpotPrice, uint256 newDelta, uint256 inputAmount, uint256 protocolFee);

  function getSellNFTQuote(
    uint256 numNFTs
  )
    external
    view
    returns (CurveErrorCodes error, uint256 newSpotPrice, uint256 newDelta, uint256 outputAmount, uint256 protocolFee);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {SudoSwapSeller} from "../../libraries/markets/SudoSwapSeller.sol";

/**
 * @title ILSSVMRouter
 * @author Unlockd
 * @notice Defines the basic interface for the NFTX Marketplace Zap.
 **/

interface ILSSVMRouter {
  function swapNFTsForToken(
    SudoSwapSeller.PairSwapSpecific[] calldata swapList,
    uint256 minOutput,
    address tokenRecipient,
    uint256 deadline
  ) external returns (uint256 outputAmount);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title Errors library
 * @author Unlockd
 * @notice Defines the error messages emitted by the different contracts of the Unlockd protocol
 */
library Errors {
  enum ReturnCode {
    SUCCESS,
    FAILED
  }

  string public constant SUCCESS = "0";

  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
  string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
  string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
  string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
  string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";
  string public constant CALLER_NOT_POOL_LIQUIDATOR = "105";
  string public constant INVALID_ZERO_ADDRESS = "106";
  string public constant CALLER_NOT_LTV_MANAGER = "107";
  string public constant CALLER_NOT_PRICE_MANAGER = "108";
  string public constant CALLER_NOT_UTOKEN_MANAGER = "109";

  //math library errors
  string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
  string public constant MATH_ADDITION_OVERFLOW = "201";
  string public constant MATH_DIVISION_BY_ZERO = "202";

  //validation & check errors
  string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "307"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_ACTIVE_NFT = "310";
  string public constant VL_NFT_FROZEN = "311";
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
  string public constant VL_INVALID_HEALTH_FACTOR = "313";
  string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
  string public constant VL_INVALID_TARGET_ADDRESS = "315";
  string public constant VL_INVALID_RESERVE_ADDRESS = "316";
  string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
  string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
  string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD = "319";
  string public constant VL_TIMEFRAME_EXCEEDED = "320";
  string public constant VL_VALUE_EXCEED_TREASURY_BALANCE = "321";

  //lend pool errors
  string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
  string public constant LP_NOT_CONTRACT = "403";
  string public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD = "404";
  string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
  string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
  string public constant LP_INVALID_USER_NFT_AMOUNT = "407";
  string public constant LP_INCONSISTENT_PARAMS = "408";
  string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
  string public constant LP_CALLER_MUST_BE_AN_UTOKEN = "410";
  string public constant LP_INVALID_NFT_AMOUNT = "411";
  string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
  string public constant LP_DELEGATE_CALL_FAILED = "413";
  string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
  string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
  string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
  string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
  string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
  string public constant LP_CALLER_NOT_LEND_POOL_LIQUIDATOR_NOR_GATEWAY = "419";
  string public constant LP_CONSECUTIVE_BIDS_NOT_ALLOWED = "420";
  string public constant LP_INVALID_OVERFLOW_VALUE = "421";
  string public constant LP_CALLER_NOT_NFT_HOLDER = "422";
  string public constant LP_NFT_NOT_ALLOWED_TO_SELL = "423";
  string public constant LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY = "424";
  string public constant LP_COLLECTION_NOT_SUPPORTED = "425";
  string public constant LP_MSG_VALUE_DIFFERENT_FROM_CONFIG_FEE = "426";
  string public constant LP_INVALID_SAFE_HEALTH_FACTOR = "427";
  string public constant LP_AMOUNT_LESS_THAN_DEBT = "428";
  string public constant LP_AMOUNT_DIFFERENT_FROM_REQUIRED_BUYOUT_PRICE = "429";
  string public constant LP_CALLER_NOT_DEBT_TOKEN_MANAGER = "430";

  //lend pool loan errors
  string public constant LPL_INVALID_LOAN_STATE = "480";
  string public constant LPL_INVALID_LOAN_AMOUNT = "481";
  string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
  string public constant LPL_AMOUNT_OVERFLOW = "483";
  string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
  string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
  string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
  string public constant LPL_BID_USER_NOT_SAME = "487";
  string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
  string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
  string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
  string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
  string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
  string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
  string public constant LPL_INVALID_BID_FINE = "494";
  string public constant LPL_BID_PRICE_LESS_THAN_MIN_BID_REQUIRED = "495";
  string public constant LPL_BID_NOT_BUYOUT_PRICE = "496";
  string public constant LPL_BUYOUT_DURATION_HAS_END = "497";
  string public constant LPL_BUYOUT_PRICE_LESS_THAN_BORROW = "498";
  string public constant LPL_CALLER_MUST_BE_MARKET_ADAPTER = "499";

  //common token errors
  string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
  string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
  string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";
  string public constant CT_CALLER_MUST_BE_DEBT_MARKET = "504"; // 'The caller of this function must be a debt market'

  //reserve logic errors
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

  //configure errors
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
  string public constant LPC_INVALID_UNFT_ADDRESS = "703";
  string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
  string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";
  string public constant LPC_PARAMS_MISMATCH = "706"; // NFT assets & token ids mismatch
  string public constant LPC_FEE_PERCENTAGE_TOO_HIGH = "707";
  string public constant LPC_INVALID_LTVMANAGER_ADDRESS = "708";
  string public constant LPC_INCONSISTENT_PARAMS = "709";
  string public constant LPC_INVALID_SAFE_HEALTH_FACTOR = "710";
  //reserve config errors
  string public constant RC_INVALID_LTV = "730";
  string public constant RC_INVALID_LIQ_THRESHOLD = "731";
  string public constant RC_INVALID_LIQ_BONUS = "732";
  string public constant RC_INVALID_DECIMALS = "733";
  string public constant RC_INVALID_RESERVE_FACTOR = "734";
  string public constant RC_INVALID_REDEEM_DURATION = "735";
  string public constant RC_INVALID_AUCTION_DURATION = "736";
  string public constant RC_INVALID_REDEEM_FINE = "737";
  string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
  string public constant RC_INVALID_MIN_BID_FINE = "739";
  string public constant RC_INVALID_MAX_BID_FINE = "740";
  string public constant RC_INVALID_MAX_CONFIG_TIMESTAMP = "741";

  //address provider erros
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";

  //NFTXHelper
  string public constant NFTX_INVALID_VAULTS_LENGTH = "800";

  //NFTOracleErrors
  string public constant NFTO_INVALID_PRICEM_ADDRESS = "900";

  //Debt Market
  string public constant DM_CALLER_NOT_THE_OWNER = "1000";
  string public constant DM_DEBT_SHOULD_EXIST = "1001";
  string public constant DM_INVALID_AMOUNT = "1002";
  string public constant DM_FAIL_ON_SEND_ETH = "1003";
  string public constant DM_DEBT_SHOULD_NOT_BE_SOLD = "1004";
  string public constant DM_DEBT_ALREADY_EXIST = "1005";
  string public constant DM_LOAN_SHOULD_EXIST = "1006";
  string public constant DM_AUCTION_ALREADY_ENDED = "1007";
  string public constant DM_BID_PRICE_HIGHER_THAN_SELL_PRICE = "1008";
  string public constant DM_BID_PRICE_LESS_THAN_PREVIOUS_BID = "1009";
  string public constant DM_INVALID_SELL_TYPE = "1010";
  string public constant DM_AUCTION_NOT_ALREADY_ENDED = "1011";
  string public constant DM_INVALID_CLAIM_RECEIVER = "1012";
  string public constant DM_AMOUNT_DIFFERENT_FROM_SELL_PRICE = "1013";
  string public constant DM_BID_PRICE_LESS_THAN_MIN_BID_PRICE = "1014";
  string public constant DM_BORROWED_AMOUNT_DIVERGED = "1015";
  string public constant DM_INVALID_AUTHORIZED_ADDRESS = "1016";
  string public constant DM_CALLER_NOT_THE_OWNER_OR_AUTHORIZED = "1017";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {INFTXVaultFactoryV2} from "../../interfaces/nftx/INFTXVaultFactoryV2.sol";
import {INFTXVault} from "../../interfaces/nftx/INFTXVault.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

import {Errors} from "../../libraries/helpers/Errors.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title NFTXSeller library
 * @author Unlockd
 * @notice Implements NFTX selling logic
 */
library NFTXSeller {
  // ADDRESS_ID to fetch Wrapped Ether address from Addresses Provider
  bytes32 public constant ADDRESS_ID_WETH = keccak256("WETH");

  /**
   * @dev Sells an asset in an NFTX liquid market
   * @param addressesProvider The addresses provider
   * @param nftAsset The underlying NFT address
   * @param nftTokenId The underlying NFT token Id
   * @param reserveAsset The reserve asset to exchange for the NFT
   */
  function sellNFTX(
    ILendPoolAddressesProvider addressesProvider,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountOutMin
  ) internal returns (uint256) {
    address vaultFactoryAddress = addressesProvider.getNFTXVaultFactory();
    address sushiSwapRouterAddress = addressesProvider.getSushiSwapRouter();
    address lendPoolAddress = addressesProvider.getLendPool();
    address WETH = addressesProvider.getAddress(ADDRESS_ID_WETH);

    // Get NFTX Vaults for the asset
    address[] memory vaultAddresses = INFTXVaultFactoryV2(vaultFactoryAddress).vaultsForAsset(nftAsset);

    require(vaultAddresses.length > 0, Errors.NFTX_INVALID_VAULTS_LENGTH);

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = nftTokenId;

    //Always get the first vault address
    address vaultAddress = vaultAddresses[0];
    INFTXVault nftxVault = INFTXVault(vaultAddress);

    if (nftxVault.allValidNFTs(tokenIds)) {
      // Deposit NFT to NFTX Vault
      IERC721Upgradeable(nftAsset).approve(vaultAddress, nftTokenId);
      nftxVault.mint(tokenIds, new uint256[](1));
      uint256 depositAmount = IERC20Upgradeable(vaultAddress).balanceOf(address(this));

      // Swap on SushiSwap
      IERC20Upgradeable(vaultAddress).approve(sushiSwapRouterAddress, depositAmount);

      address[] memory swapPath;
      if (reserveAsset != address(WETH)) {
        swapPath = new address[](3);
        swapPath[2] = reserveAsset;
      } else {
        swapPath = new address[](2);
      }
      swapPath[0] = vaultAddress;
      swapPath[1] = WETH;

      uint256[] memory amounts = IUniswapV2Router02(sushiSwapRouterAddress).swapExactTokensForTokens(
        depositAmount,
        amountOutMin,
        swapPath,
        lendPoolAddress,
        block.timestamp
      );
      if (swapPath.length == 3) {
        return amounts[2];
      }
      return amounts[1];
    }

    revert("NFTX: vault not available");
  }

  /**
   * @dev Get the NFTX price in reserve asset
   * @param addressesProvider The addresses provider
   * @param nftAsset The underlying NFT address
   * @param nftTokenId The underlying NFT token Id
   * @param reserveAsset The ERC20 reserve asset
   */
  function getNFTXPrice(
    ILendPoolAddressesProvider addressesProvider,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset
  ) internal view returns (uint256) {
    address vaultFactoryAddress = addressesProvider.getNFTXVaultFactory();
    address sushiSwapRouterAddress = addressesProvider.getSushiSwapRouter();
    address WETH = addressesProvider.getAddress(ADDRESS_ID_WETH);

    // Get NFTX Vaults for the asset
    address[] memory vaultAddresses = INFTXVaultFactoryV2(vaultFactoryAddress).vaultsForAsset(nftAsset);

    require(vaultAddresses.length > 0, Errors.NFTX_INVALID_VAULTS_LENGTH);

    uint256[] memory tokenIds = new uint256[](1);
    tokenIds[0] = nftTokenId;

    // Always get the first vault address
    address vaultAddress = vaultAddresses[0];
    INFTXVault nftxVault = INFTXVault(vaultAddress);
    (uint256 mintFee, , , , ) = INFTXVaultFactoryV2(vaultFactoryAddress).vaultFees(nftxVault.vaultId());

    if (nftxVault.allValidNFTs(tokenIds)) {
      address[] memory swapPath;
      if (reserveAsset != address(WETH)) {
        swapPath = new address[](3);
        swapPath[2] = reserveAsset;
      } else {
        swapPath = new address[](2);
      }
      swapPath[0] = vaultAddress;
      swapPath[1] = WETH;

      uint256 depositAmount = 1 ether - mintFee;

      uint256[] memory amounts = IUniswapV2Router02(sushiSwapRouterAddress).getAmountsOut(depositAmount, swapPath);

      if (amounts.length == 3) {
        return amounts[2];
      }
      return amounts[1];
    }

    revert("NFTX: vault not available");
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {ILSSVMRouter} from "../../interfaces/sudoswap/ILSSVMRouter.sol";
import {ILSSVMPair} from "../../interfaces/sudoswap/ILSSVMPair.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

/*
 * @title SudoSwap library
 * @author Unlockd
 * @notice Implements SudoSwap selling logic
 */
library SudoSwapSeller {
  struct PairSwapSpecific {
    ILSSVMPair pair;
    uint256[] nftIds;
  }
  // Address ID for Sudoswap LSSVM router in addresses provider
  bytes32 public constant ADDRESS_ID_LSSVM_ROUTER = keccak256("LSSVM_ROUTER");

  /**
   * @dev Sells an asset in a SudoSwap liquid market
   * @param addressesProvider The addresses provider
   * @param nftTokenId The underlying NFT token Id
   */
  function sellSudoSwap(
    ILendPoolAddressesProvider addressesProvider,
    address nftAsset,
    uint256 nftTokenId,
    address LSSVMPair,
    uint256 amountOutMinSudoswap
  ) internal returns (uint256 amount) {
    address LSSVMRouterAddress = addressesProvider.getAddress(ADDRESS_ID_LSSVM_ROUTER);
    address lendPoolAddress = addressesProvider.getLendPool();

    ILSSVMRouter LSSVMRouter = ILSSVMRouter(LSSVMRouterAddress);

    uint256[] memory nftTokenIds = new uint256[](1);
    nftTokenIds[0] = nftTokenId;

    PairSwapSpecific[] memory pairSwaps = new PairSwapSpecific[](1);
    pairSwaps[0] = PairSwapSpecific({pair: ILSSVMPair(LSSVMPair), nftIds: nftTokenIds});

    IERC721Upgradeable(nftAsset).approve(LSSVMRouterAddress, nftTokenId);

    amount = LSSVMRouter.swapNFTsForToken(pairSwaps, amountOutMinSudoswap, lendPoolAddress, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title WadRayMath library
 * @author Unlockd
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = RAY / 2;

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
    return HALF_RAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return HALF_WAD;
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

    require(a <= (type(uint256).max - HALF_WAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + HALF_WAD) / WAD;
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

    require(a <= (type(uint256).max - HALF_RAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + HALF_RAY) / RAY;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address uTokenAddress;
    address debtTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NftData {
    //stores the nft configuration
    NftConfigurationMap configuration;
    //address of the uNFT contract
    address uNftAddress;
    //the id of the nft. Represents the position in the list of the active nfts
    uint8 id;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct NftConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 56: NFT is active
    //bit 57: NFT is frozen
    //bit 64-71: Redeem duration
    //bit 72-79: Auction duration
    //bit 80-95: Redeem fine
    //bit 96-111: Redeem threshold
    //bit 112-127: Min bid fine
    //bit 128-159: Timestamp Config
    uint256 data;
  }

  /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> Auction -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }

  struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the id of nft token
    uint256 nftTokenId;
    //address of reserve asset token
    address reserveAsset;
    //scaled borrow amount. Expressed in ray
    uint256 scaledAmount;
    //start time of first bid time
    uint256 bidStartTimestamp;
    //bidder address of higest bid
    address bidderAddress;
    //price of higest bid
    uint256 bidPrice;
    //borrow amount of loan
    uint256 bidBorrowAmount;
    //bidder address of first bid
    address firstBidderAddress;
  }

  struct ExecuteDepositParams {
    address initiator;
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteWithdrawParams {
    address initiator;
    address asset;
    uint256 amount;
    address to;
  }

  struct ExecuteBorrowParams {
    address initiator;
    address asset;
    uint256 amount;
    address nftAsset;
    uint256 nftTokenId;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteRepayParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteAuctionParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 bidPrice;
    address onBehalfOf;
    uint256 auctionDurationConfigFee;
  }

  struct ExecuteRedeemParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
    uint256 bidFine;
    uint256 safeHealthFactor;
  }

  struct ExecuteLiquidateParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteBuyoutParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
    address onBehalfOf;
  }

  struct ExecuteLiquidateMarketsParams {
    address nftAsset;
    uint256 nftTokenId;
    uint256 liquidateFeePercentage;
    uint256 amountOutMin;
  }

  struct SudoSwapParams {
    address LSSVMPair;
    uint256 amountOutMinSudoswap;
  }
  struct ExecuteLendPoolStates {
    uint256 pauseStartTime;
    uint256 pauseDurationTime;
  }

  struct ExecuteYearnParams {
    address underlyingAsset;
    uint256 amount;
  }

  enum DebtMarketType {
    FixedPrice, //0
    Auction, //1
    Mixed //2
  }

  enum DebtMarketState {
    //No bids
    New,
    //Exist bids
    Active,
    //Is sold
    Sold,
    Canceled
  }

  struct DebtMarketListing {
    uint256 debtId;
    address debtor;
    address nftAsset;
    uint256 tokenId;
    DebtMarketType sellType;
    DebtMarketState state;
    uint256 sellPrice;
    address reserveAsset;
    uint256 scaledAmount;
    address bidderAddress;
    uint256 bidPrice;
    uint256 auctionEndTimestamp;
    uint256 startBiddingPrice;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IUNFT} from "../interfaces/IUNFT.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {NFTXSeller} from "../libraries/markets/NFTXSeller.sol";
import {SudoSwapSeller} from "../libraries/markets/SudoSwapSeller.sol";
import {IUNFTRegistry} from "../interfaces/IUNFTRegistry.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract LendPoolLoan is Initializable, ILendPoolLoan, ContextUpgradeable, IERC721ReceiverUpgradeable {
  using WadRayMath for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  ILendPoolAddressesProvider private _addressesProvider;
  bytes32 public constant DEBT_MARKET = keccak256("DEBT_MARKET");

  CountersUpgradeable.Counter private _loanIdTracker;
  mapping(uint256 => DataTypes.LoanData) private _loans;

  // nftAsset + nftTokenId => loanId
  mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
  mapping(address => uint256) private _nftTotalCollateral;
  mapping(address => mapping(address => uint256)) private _userNftCollateral;
  mapping(address => bool) private _marketAdapters;

  /**
   * @dev Only lending pool can call functions marked by this modifier
   **/
  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }
  modifier onlyDebtMarket() {
    require(_msgSender() == _addressesProvider.getAddress(DEBT_MARKET), Errors.CT_CALLER_MUST_BE_DEBT_MARKET);
    _;
  }

  /**
   * @dev Only adapter of external markets can call functions marked by this modifier
   **/
  modifier onlyMarketAdapter() {
    require(_marketAdapters[_msgSender()], Errors.LPL_CALLER_MUST_BE_MARKET_ADAPTER);
    _;
  }
  /**
   * @dev Only pool admin can call functions marked by this modifier
   **/
  modifier onlyPoolAdmin() {
    require(_msgSender() == _addressesProvider.getPoolAdmin(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  // called once by the factory at time of deployment
  function initialize(ILendPoolAddressesProvider provider) external initializer {
    require(address(provider) != address(0), Errors.INVALID_ZERO_ADDRESS);

    __Context_init();
    require(address(provider) != address(0), Errors.INVALID_ZERO_ADDRESS);
    _addressesProvider = provider;

    // Avoid having loanId = 0
    _loanIdTracker.increment();

    emit Initialized(address(_getLendPool()));
  }

  function initNft(address nftAsset, address uNftAddress) external override onlyLendPool {
    IERC721Upgradeable(nftAsset).setApprovalForAll(uNftAddress, true);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address uNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external override onlyLendPool returns (uint256) {
    require(_nftToLoanIds[nftAsset][nftTokenId] == 0, Errors.LP_NFT_HAS_USED_AS_COLLATERAL);

    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(borrowIndex);

    uint256 loanId = _loanIdTracker.current();
    _loanIdTracker.increment();

    _nftToLoanIds[nftAsset][nftTokenId] = loanId;

    // transfer underlying NFT asset to pool and mint uNFT to onBehalfOf
    IERC721Upgradeable(nftAsset).safeTransferFrom(_msgSender(), address(this), nftTokenId);

    IUNFT(uNftAddress).mint(onBehalfOf, nftTokenId);

    // Save Info
    DataTypes.LoanData storage loanData = _loans[loanId];
    loanData.loanId = loanId;
    loanData.state = DataTypes.LoanState.Active;
    loanData.borrower = onBehalfOf;
    loanData.nftAsset = nftAsset;
    loanData.nftTokenId = nftTokenId;
    loanData.reserveAsset = reserveAsset;
    loanData.scaledAmount = amountScaled;

    _userNftCollateral[onBehalfOf][nftAsset] += 1;
    _nftTotalCollateral[nftAsset] += 1;

    emit LoanCreated(initiator, onBehalfOf, loanId, nftAsset, nftTokenId, reserveAsset, amount, borrowIndex);

    return (loanId);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    uint256 amountScaled = 0;

    if (amountAdded > 0) {
      amountScaled = amountAdded.rayDiv(borrowIndex);
      require(amountScaled != 0, Errors.LPL_INVALID_LOAN_AMOUNT);

      loan.scaledAmount += amountScaled;
    }

    if (amountTaken > 0) {
      amountScaled = amountTaken.rayDiv(borrowIndex);
      require(amountScaled != 0, Errors.LPL_INVALID_TAKEN_AMOUNT);

      require(loan.scaledAmount >= amountScaled, Errors.LPL_AMOUNT_OVERFLOW);
      loan.scaledAmount -= amountScaled;
    }

    emit LoanUpdated(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      amountAdded,
      amountTaken,
      borrowIndex
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Repaid;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and transfer underlying NFT asset to user
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanRepaid(initiator, loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, amount, borrowIndex);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];
    address previousBidder = loan.bidderAddress;
    uint256 previousPrice = loan.bidPrice;

    // Ensure valid loan state
    if (loan.bidStartTimestamp == 0) {
      require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

      loan.state = DataTypes.LoanState.Auction;
      loan.bidStartTimestamp = block.timestamp;
      loan.firstBidderAddress = onBehalfOf;
    } else {
      require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

      require(bidPrice > loan.bidPrice, Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
    }

    loan.bidBorrowAmount = borrowAmount;
    loan.bidderAddress = onBehalfOf;
    loan.bidPrice = bidPrice;

    emit LoanAuctioned(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.bidBorrowAmount,
      borrowIndex,
      onBehalfOf,
      bidPrice,
      previousBidder,
      previousPrice
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function buyoutLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    uint256 buyoutAmount
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Defaulted;
    _loans[loanId].bidBorrowAmount = borrowAmount;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and transfer underlying NFT asset to user
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanBoughtOut(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.bidBorrowAmount,
      borrowIndex,
      buyoutAmount
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function redeemLoan(
    address initiator,
    uint256 loanId,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    uint256 amountScaled = amountTaken.rayDiv(borrowIndex);
    require(amountScaled != 0, Errors.LPL_INVALID_TAKEN_AMOUNT);

    require(loan.scaledAmount >= amountScaled, Errors.LPL_AMOUNT_OVERFLOW);
    loan.scaledAmount -= amountScaled;

    loan.state = DataTypes.LoanState.Active;
    loan.bidStartTimestamp = 0;
    loan.bidBorrowAmount = 0;
    loan.bidderAddress = address(0);
    loan.bidPrice = 0;
    loan.firstBidderAddress = address(0);

    emit LoanRedeemed(initiator, loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, amountTaken, borrowIndex);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Defaulted;
    _loans[loanId].bidBorrowAmount = borrowAmount;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and transfer underlying NFT asset to user
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanLiquidated(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoanNFTX(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    uint256 amountOutMin
  ) external override onlyLendPool returns (uint256 sellPrice) {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Defaulted;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and sell underlying NFT on NFTX
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    require(IERC721Upgradeable(loan.nftAsset).ownerOf(loan.nftTokenId) == address(this), "Invalid Call");

    // Sell NFT on NFTX
    sellPrice = NFTXSeller.sellNFTX(
      _addressesProvider,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      amountOutMin
    );

    emit LoanLiquidatedNFTX(
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex,
      sellPrice
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoanSudoSwap(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex,
    DataTypes.SudoSwapParams memory sudoswapParams
  ) external override onlyLendPool returns (uint256 sellPrice) {
    // Must use storage to change state

    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    loan.state = DataTypes.LoanState.Defaulted;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT and sell underlying NFT on SudoSwap
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    require(IERC721Upgradeable(loan.nftAsset).ownerOf(loan.nftTokenId) == address(this), "Invalid Call");

    // Sell NFT on SudoSwap
    sellPrice = SudoSwapSeller.sellSudoSwap(
      _addressesProvider,
      loan.nftAsset,
      loan.nftTokenId,
      sudoswapParams.LSSVMPair,
      sudoswapParams.amountOutMinSudoswap
    );

    emit LoanLiquidatedSudoSwap(
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex,
      sellPrice,
      sudoswapParams.LSSVMPair
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoanMarket(
    uint256 loanId,
    address uNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyMarketAdapter {
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    loan.state = DataTypes.LoanState.Defaulted;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALID_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn uNFT
    IUNFT(uNftAddress).burn(loan.nftTokenId);

    //transfer to sender
    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanLiquidatedMarket(loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, borrowAmount, borrowIndex);
  }

  function updateMarketAdapters(address[] calldata adapters, bool flag) external override onlyPoolAdmin {
    uint256 cachedLength = adapters.length;
    for (uint256 i = 0; i < cachedLength; ) {
      require(adapters[i] != address(0), Errors.INVALID_ZERO_ADDRESS);
      _marketAdapters[adapters[i]] = flag;
      unchecked {
        ++i;
      }
    }
  }

  function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function borrowerOf(uint256 loanId) external view override returns (address) {
    return _loans[loanId].borrower;
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view override returns (uint256) {
    return _nftToLoanIds[nftAsset][nftTokenId];
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoan(uint256 loanId) external view override returns (DataTypes.LoanData memory loanData) {
    return _loans[loanId];
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanCollateralAndReserve(
    uint256 loanId
  ) external view override returns (address nftAsset, uint256 nftTokenId, address reserveAsset, uint256 scaledAmount) {
    return (
      _loans[loanId].nftAsset,
      _loans[loanId].nftTokenId,
      _loans[loanId].reserveAsset,
      _loans[loanId].scaledAmount
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanReserveBorrowAmount(uint256 loanId) external view override returns (address, uint256) {
    uint256 scaledAmount = _loans[loanId].scaledAmount;
    if (scaledAmount == 0) {
      return (_loans[loanId].reserveAsset, 0);
    }
    uint256 amount = scaledAmount.rayMul(_getLendPool().getReserveNormalizedVariableDebt(_loans[loanId].reserveAsset));

    return (_loans[loanId].reserveAsset, amount);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view override returns (address, uint256) {
    return (_loans[loanId].reserveAsset, _loans[loanId].scaledAmount);
  }

  function getLoanHighestBid(uint256 loanId) external view override returns (address, uint256) {
    return (_loans[loanId].bidderAddress, _loans[loanId].bidPrice);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getNftCollateralAmount(address nftAsset) external view override returns (uint256) {
    return _nftTotalCollateral[nftAsset];
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getUserNftCollateralAmount(address user, address nftAsset) external view override returns (uint256) {
    return _userNftCollateral[user][nftAsset];
  }

  /**
   * @dev returns the LendPool address
   */
  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressesProvider.getLendPool());
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function getLoanIdTracker() external view override returns (CountersUpgradeable.Counter memory) {
    return _loanIdTracker;
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function reMintUNFT(
    address nftAsset,
    uint256 tokenId,
    address oldOnBehalfOf,
    address newOnBehalfOf
  ) external override onlyDebtMarket {
    DataTypes.NftData memory nftData = ILendPool(_addressesProvider.getLendPool()).getNftData(nftAsset);

    require(_userNftCollateral[oldOnBehalfOf][nftAsset] >= 1, Errors.LP_INVALID_USER_NFT_AMOUNT);

    _userNftCollateral[oldOnBehalfOf][nftAsset] -= 1;
    _userNftCollateral[newOnBehalfOf][nftAsset] += 1;

    uint256 loanId = _nftToLoanIds[nftAsset][tokenId];

    DataTypes.LoanData storage loan = _loans[loanId];
    loan.borrower = newOnBehalfOf;

    IUNFT(nftData.uNftAddress).burn(tokenId);
    IUNFT(nftData.uNftAddress).mint(newOnBehalfOf, tokenId);
  }
}