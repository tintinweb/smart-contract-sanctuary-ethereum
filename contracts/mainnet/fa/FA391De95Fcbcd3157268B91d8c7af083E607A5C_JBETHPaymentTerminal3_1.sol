// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0-rc.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/Address.sol';
import './abstract/JBPayoutRedemptionPaymentTerminal3_1.sol';
import './libraries/JBSplitsGroups.sol';

/**
  @notice
  Manages all inflows and outflows of ETH funds into the protocol ecosystem.

  @dev
  Inherits from -
  JBPayoutRedemptionPaymentTerminal3_1: Generic terminal managing all inflows and outflows of funds into the protocol ecosystem.
*/
contract JBETHPaymentTerminal3_1 is JBPayoutRedemptionPaymentTerminal3_1 {
  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Checks the balance of tokens in this contract.

    @return The contract's balance, as a fixed point number with the same amount of decimals as this terminal.
  */
  function _balance() internal view override returns (uint256) {
    return address(this).balance;
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _baseWeightCurrency The currency to base token issuance on.
    @param _operatorStore A contract storing operator assignments.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _splitsStore A contract that stores splits for each project.
    @param _prices A contract that exposes price feeds.
    @param _store A contract that stores the terminal's data.
    @param _owner The address that will own this contract.
  */
  constructor(
    uint256 _baseWeightCurrency,
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBDirectory _directory,
    IJBSplitsStore _splitsStore,
    IJBPrices _prices,
    IJBSingleTokenPaymentTerminalStore _store,
    address _owner
  )
    JBPayoutRedemptionPaymentTerminal3_1(
      JBTokens.ETH,
      18, // 18 decimals.
      JBCurrencies.ETH,
      _baseWeightCurrency,
      JBSplitsGroups.ETH_PAYOUT,
      _operatorStore,
      _projects,
      _directory,
      _splitsStore,
      _prices,
      _store,
      _owner
    )
  // solhint-disable-next-line no-empty-blocks
  {

  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Transfers tokens.

    @param _from The address from which the transfer should originate.
    @param _to The address to which the transfer should go.
    @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  */
  function _transferFrom(
    address _from,
    address payable _to,
    uint256 _amount
  ) internal override {
    _from; // Prevents unused var compiler and natspec complaints.

    Address.sendValue(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../interfaces/IJBOperatable.sol';

/** 
  @notice
  Modifiers to allow access to functions based on the message sender's operator status.

  @dev
  Adheres to -
  IJBOperatable: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.
*/
abstract contract JBOperatable is IJBOperatable {
  //*********************************************************************//
  // --------------------------- custom errors -------------------------- //
  //*********************************************************************//
  error UNAUTHORIZED();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Only allows the speficied account or an operator of the account to proceed. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
  */
  modifier requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) {
    _requirePermission(_account, _domain, _permissionIndex);
    _;
  }

  /** 
    @notice
    Only allows the speficied account, an operator of the account to proceed, or a truthy override flag. 

    @param _account The account to check for.
    @param _domain The domain namespace to look for an operator within. 
    @param _permissionIndex The index of the permission to check for. 
    @param _override A condition to force allowance for.
  */
  modifier requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) {
    _requirePermissionAllowingOverride(_account, _domain, _permissionIndex, _override);
    _;
  }

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /** 
    @notice 
    A contract storing operator assignments.
  */
  IJBOperatorStore public immutable override operatorStore;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _operatorStore A contract storing operator assignments.
  */
  constructor(IJBOperatorStore _operatorStore) {
    operatorStore = _operatorStore;
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Require the message sender is either the account or has the specified permission.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _permissionIndex The permission index that an operator must have within the specified domain to be allowed.
  */
  function _requirePermission(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) internal view {
    if (
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }

  /** 
    @notice
    Require the message sender is either the account, has the specified permission, or the override condition is true.

    @param _account The account to allow.
    @param _domain The domain namespace within which the permission index will be checked.
    @param _domain The permission index that an operator must have within the specified domain to be allowed.
    @param _override The override condition to allow.
  */
  function _requirePermissionAllowingOverride(
    address _account,
    uint256 _domain,
    uint256 _permissionIndex,
    bool _override
  ) internal view {
    if (
      !_override &&
      msg.sender != _account &&
      !operatorStore.hasPermission(msg.sender, _account, _domain, _permissionIndex) &&
      !operatorStore.hasPermission(msg.sender, _account, 0, _permissionIndex)
    ) revert UNAUTHORIZED();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import '@paulrberg/contracts/math/PRBMath.sol';
import './../interfaces/IJBController.sol';
import './../interfaces/IJBPayoutRedemptionPaymentTerminal3_1.sol';
import './../libraries/JBConstants.sol';
import './../libraries/JBCurrencies.sol';
import './../libraries/JBFixedPointNumber.sol';
import './../libraries/JBFundingCycleMetadataResolver.sol';
import './../libraries/JBOperations.sol';
import './../libraries/JBTokens.sol';
import './../structs/JBPayDelegateAllocation.sol';
import './../structs/JBTokenAmount.sol';
import './JBOperatable.sol';
import './JBSingleTokenPaymentTerminal.sol';

/**
  @notice
  Generic terminal managing all inflows and outflows of funds into the protocol ecosystem.

  @dev
  A project can transfer its funds, along with the power to reconfigure and mint/burn their tokens, from this contract to another allowed terminal of the same token type contract at any time.

  @dev
  Adheres to -
  IJBPayoutRedemptionPaymentTerminal3_1: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  JBSingleTokenPaymentTerminal: Generic terminal managing all inflows of funds into the protocol ecosystem for one token.
  JBOperatable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
  Ownable: Includes convenience functionality for checking a message sender's permissions before executing certain transactions.
*/
abstract contract JBPayoutRedemptionPaymentTerminal3_1 is
  JBSingleTokenPaymentTerminal,
  JBOperatable,
  Ownable,
  IJBPayoutRedemptionPaymentTerminal3_1
{
  // A library that parses the packed funding cycle metadata into a friendlier format.
  using JBFundingCycleMetadataResolver for JBFundingCycle;

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error FEE_TOO_HIGH();
  error INADEQUATE_DISTRIBUTION_AMOUNT();
  error INADEQUATE_RECLAIM_AMOUNT();
  error INADEQUATE_TOKEN_COUNT();
  error NO_MSG_VALUE_ALLOWED();
  error PAY_TO_ZERO_ADDRESS();
  error PROJECT_TERMINAL_MISMATCH();
  error REDEEM_TO_ZERO_ADDRESS();
  error TERMINAL_IN_SPLIT_ZERO_ADDRESS();
  error TERMINAL_TOKENS_INCOMPATIBLE();

  //*********************************************************************//
  // ---------------------------- modifiers ---------------------------- //
  //*********************************************************************//

  /** 
    @notice 
    A modifier that verifies this terminal is a terminal of provided project ID.
  */
  modifier isTerminalOf(uint256 _projectId) {
    if (!directory.isTerminalOf(_projectId, this)) revert PROJECT_TERMINAL_MISMATCH();
    _;
  }

  //*********************************************************************//
  // --------------------- internal stored constants ------------------- //
  //*********************************************************************//

  /**
    @notice
    Maximum fee that can be set for a funding cycle configuration.

    @dev
    Out of MAX_FEE (50_000_000 / 1_000_000_000).
  */
  uint256 internal constant _FEE_CAP = 50_000_000;

  /**
    @notice
    The fee beneficiary project ID is 1, as it should be the first project launched during the deployment process.
  */
  uint256 internal constant _FEE_BENEFICIARY_PROJECT_ID = 1;

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  /**
    @notice
    Fees that are being held to be processed later.

    _projectId The ID of the project for which fees are being held.
  */
  mapping(uint256 => JBFee[]) internal _heldFeesOf;

  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /**
    @notice
    Mints ERC-721's that represent project ownership and transfers.
  */
  IJBProjects public immutable override projects;

  /**
    @notice
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  /**
    @notice
    The contract that stores splits for each project.
  */
  IJBSplitsStore public immutable override splitsStore;

  /**
    @notice
    The contract that exposes price feeds.
  */
  IJBPrices public immutable override prices;

  /**
    @notice
    The contract that stores and manages the terminal's data.
  */
  IJBSingleTokenPaymentTerminalStore public immutable override store;

  /**
    @notice
    The currency to base token issuance on.

    @dev
    If this differs from `currency`, there must be a price feed available to convert `currency` to `baseWeightCurrency`.
  */
  uint256 public immutable override baseWeightCurrency;

  /**
    @notice
    The group that payout splits coming from this terminal are identified by.
  */
  uint256 public immutable override payoutSplitsGroup;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
    @notice
    The platform fee percent.

    @dev
    Out of MAX_FEE (25_000_000 / 1_000_000_000)
  */
  uint256 public override fee = 25_000_000; // 2.5%

  /**
    @notice
    The data source that returns a discount to apply to a project's fee.
  */
  IJBFeeGauge public override feeGauge;

  /**
    @notice
    Addresses that can be paid towards from this terminal without incurring a fee.

    @dev
    Only addresses that are considered to be contained within the ecosystem can be feeless. Funds sent outside the ecosystem may incur fees despite being stored as feeless.

    _address The address that can be paid toward.
  */
  mapping(address => bool) public override isFeelessAddress;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice
    Gets the current overflowed amount in this terminal for a specified project, in terms of ETH.

    @dev
    The current overflow is represented as a fixed point number with 18 decimals.

    @param _projectId The ID of the project to get overflow for.

    @return The current amount of ETH overflow that project has in this terminal, as a fixed point number with 18 decimals.
  */
  function currentEthOverflowOf(uint256 _projectId)
    external
    view
    virtual
    override
    returns (uint256)
  {
    // Get this terminal's current overflow.
    uint256 _overflow = store.currentOverflowOf(this, _projectId);

    // Adjust the decimals of the fixed point number if needed to have 18 decimals.
    uint256 _adjustedOverflow = (decimals == 18)
      ? _overflow
      : JBFixedPointNumber.adjustDecimals(_overflow, decimals, 18);

    // Return the amount converted to ETH.
    return
      (currency == JBCurrencies.ETH)
        ? _adjustedOverflow
        : PRBMath.mulDiv(
          _adjustedOverflow,
          10**decimals,
          prices.priceFor(currency, JBCurrencies.ETH, decimals)
        );
  }

  /**
    @notice
    The fees that are currently being held to be processed later for each project.

    @param _projectId The ID of the project for which fees are being held.

    @return An array of fees that are being held.
  */
  function heldFeesOf(uint256 _projectId) external view override returns (JBFee[] memory) {
    return _heldFeesOf[_projectId];
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev 
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(JBSingleTokenPaymentTerminal, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBPayoutRedemptionPaymentTerminal3_1).interfaceId ||
      _interfaceId == type(IJBPayoutTerminal3_1).interfaceId ||
      _interfaceId == type(IJBAllowanceTerminal3_1).interfaceId ||
      _interfaceId == type(IJBRedemptionTerminal).interfaceId ||
      _interfaceId == type(IJBOperatable).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- internal views ------------------------- //
  //*********************************************************************//

  /** 
    @notice
    Checks the balance of tokens in this contract.

    @return The contract's balance.
  */
  function _balance() internal view virtual returns (uint256);

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _token The token that this terminal manages.
    @param _decimals The number of decimals the token fixed point amounts are expected to have.
    @param _currency The currency that this terminal's token adheres to for price feeds.
    @param _baseWeightCurrency The currency to base token issuance on.
    @param _payoutSplitsGroup The group that denotes payout splits from this terminal in the splits store.
    @param _operatorStore A contract storing operator assignments.
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _splitsStore A contract that stores splits for each project.
    @param _prices A contract that exposes price feeds.
    @param _store A contract that stores the terminal's data.
    @param _owner The address that will own this contract.
  */
  constructor(
    // payable constructor save the gas used to check msg.value==0
    address _token,
    uint256 _decimals,
    uint256 _currency,
    uint256 _baseWeightCurrency,
    uint256 _payoutSplitsGroup,
    IJBOperatorStore _operatorStore,
    IJBProjects _projects,
    IJBDirectory _directory,
    IJBSplitsStore _splitsStore,
    IJBPrices _prices,
    IJBSingleTokenPaymentTerminalStore _store,
    address _owner
  )
    payable
    JBSingleTokenPaymentTerminal(_token, _decimals, _currency)
    JBOperatable(_operatorStore)
  {
    baseWeightCurrency = _baseWeightCurrency;
    payoutSplitsGroup = _payoutSplitsGroup;
    projects = _projects;
    directory = _directory;
    splitsStore = _splitsStore;
    prices = _prices;
    store = _store;

    transferOwnership(_owner);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice
    Contribute tokens to a project.

    @param _projectId The ID of the project being paid.
    @param _amount The amount of terminal tokens being received, as a fixed point number with the same amount of decimals as this terminal. If this terminal's token is ETH, this is ignored and msg.value is used in its place.
    @param _token The token being paid. This terminal ignores this property since it only manages one token. 
    @param _beneficiary The address to mint tokens for and pass along to the funding cycle's data source and delegate.
    @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point number with the same amount of decimals as this terminal.
    @param _preferClaimedTokens A flag indicating whether the request prefers to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
    @param _memo A memo to pass along to the emitted event, and passed along the the funding cycle's data source and delegate.  A data source can alter the memo before emitting in the event and forwarding to the delegate.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return The number of tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  */
  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable virtual override isTerminalOf(_projectId) returns (uint256) {
    _token; // Prevents unused var compiler and natspec complaints.

    // ETH shouldn't be sent if this terminal's token isn't ETH.
    if (token != JBTokens.ETH) {
      if (msg.value > 0) revert NO_MSG_VALUE_ALLOWED();

      // Get a reference to the balance before receiving tokens.
      uint256 _balanceBefore = _balance();

      // Transfer tokens to this terminal from the msg sender.
      _transferFrom(msg.sender, payable(address(this)), _amount);

      // The amount should reflect the change in balance.
      _amount = _balance() - _balanceBefore;
    }
    // If this terminal's token is ETH, override _amount with msg.value.
    else _amount = msg.value;

    return
      _pay(
        _amount,
        msg.sender,
        _projectId,
        _beneficiary,
        _minReturnedTokens,
        _preferClaimedTokens,
        _memo,
        _metadata
      );
  }

  /**
    @notice
    Holders can redeem their tokens to claim the project's overflowed tokens, or to trigger rules determined by the project's current funding cycle's data source.

    @dev
    Only a token holder or a designated operator can redeem its tokens.

    @param _holder The account to redeem tokens for.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
    @param _token The token being reclaimed. This terminal ignores this property since it only manages one token. 
    @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
    @param _beneficiary The address to send the terminal tokens to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return reclaimAmount The amount of terminal tokens that the project tokens were redeemed for, as a fixed point number with 18 decimals.
  */
  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _metadata
  )
    external
    virtual
    override
    requirePermission(_holder, _projectId, JBOperations.REDEEM)
    returns (uint256 reclaimAmount)
  {
    _token; // Prevents unused var compiler and natspec complaints.

    return
      _redeemTokensOf(
        _holder,
        _projectId,
        _tokenCount,
        _minReturnedTokens,
        _beneficiary,
        _memo,
        _metadata
      );
  }

  /**
    @notice
    Distributes payouts for a project with the distribution limit of its current funding cycle.

    @dev
    Payouts are sent to the preprogrammed splits. Any leftover is sent to the project's owner.

    @dev
    Anyone can distribute payouts on a project's behalf. The project can preconfigure a wildcard split that is used to send funds to msg.sender. This can be used to incentivize calling this function.

    @dev
    All funds distributed outside of this contract or any feeless terminals incure the protocol fee.

    @param _projectId The ID of the project having its payouts distributed.
    @param _amount The amount of terminal tokens to distribute, as a fixed point number with same number of decimals as this terminal.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's distribution limit currency.
    @param _token The token being distributed. This terminal ignores this property since it only manages one token. 
    @param _minReturnedTokens The minimum number of terminal tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with the same number of decimals as this terminal.
    @param _metadata Bytes to send along to the emitted event, if provided.

    @return netLeftoverDistributionAmount The amount that was sent to the project owner, as a fixed point number with the same amount of decimals as this terminal.
  */
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) external virtual override returns (uint256 netLeftoverDistributionAmount) {
    _token; // Prevents unused var compiler and natspec complaints.

    return _distributePayoutsOf(_projectId, _amount, _currency, _minReturnedTokens, _metadata);
  }

  /**
    @notice
    Allows a project to send funds from its overflow up to the preconfigured allowance.

    @dev
    Only a project's owner or a designated operator can use its allowance.

    @dev
    Incurs the protocol fee.

    @param _projectId The ID of the project to use the allowance of.
    @param _amount The amount of terminal tokens to use from this project's current allowance, as a fixed point number with the same amount of decimals as this terminal.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's overflow allowance currency.
    @param _token The token being distributed. This terminal ignores this property since it only manages one token. 
    @param _minReturnedTokens The minimum number of tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with 18 decimals.
    @param _beneficiary The address to send the funds to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the emitted event, if provided.

    @return netDistributedAmount The amount of tokens that was distributed to the beneficiary, as a fixed point number with the same amount of decimals as the terminal.
  */
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes calldata _metadata
  )
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.USE_ALLOWANCE)
    returns (uint256 netDistributedAmount)
  {
    _token; // Prevents unused var compiler and natspec complaints.

    return
      _useAllowanceOf(
        _projectId,
        _amount,
        _currency,
        _minReturnedTokens,
        _beneficiary,
        _memo,
        _metadata
      );
  }

  /**
    @notice
    Allows a project owner to migrate its funds and operations to a new terminal that accepts the same token type.

    @dev
    Only a project's owner or a designated operator can migrate it.

    @param _projectId The ID of the project being migrated.
    @param _to The terminal contract that will gain the project's funds.

    @return balance The amount of funds that were migrated, as a fixed point number with the same amount of decimals as this terminal.
  */
  function migrate(uint256 _projectId, IJBPaymentTerminal _to)
    external
    virtual
    override
    requirePermission(projects.ownerOf(_projectId), _projectId, JBOperations.MIGRATE_TERMINAL)
    returns (uint256 balance)
  {
    // The terminal being migrated to must accept the same token as this terminal.
    if (!_to.acceptsToken(token, _projectId)) revert TERMINAL_TOKENS_INCOMPATIBLE();

    // Record the migration in the store.
    balance = store.recordMigration(_projectId);

    // Transfer the balance if needed.
    if (balance > 0) {
      // Trigger any inherited pre-transfer logic.
      _beforeTransferTo(address(_to), balance);

      // If this terminal's token is ETH, send it in msg.value.
      uint256 _payableValue = token == JBTokens.ETH ? balance : 0;

      // Withdraw the balance to transfer to the new terminal;
      _to.addToBalanceOf{value: _payableValue}(_projectId, balance, token, '', bytes(''));
    }

    emit Migrate(_projectId, _to, balance, msg.sender);
  }

  /**
    @notice
    Receives funds belonging to the specified project.

    @param _projectId The ID of the project to which the funds received belong.
    @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
    @param _token The token being paid. This terminal ignores this property since it only manages one currency. 
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Extra data to pass along to the emitted event.
  */
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable virtual override isTerminalOf(_projectId) {
    // Do not refund held fees by default.
    addToBalanceOf(_projectId, _amount, _token, false, _memo, _metadata);
  }

  /**
    @notice
    Process any fees that are being held for the project.

    @dev
    Only a project owner, an operator, or the contract's owner can process held fees.

    @param _projectId The ID of the project whos held fees should be processed.
  */
  function processFees(uint256 _projectId)
    external
    virtual
    override
    requirePermissionAllowingOverride(
      projects.ownerOf(_projectId),
      _projectId,
      JBOperations.PROCESS_FEES,
      msg.sender == owner()
    )
  {
    // Get a reference to the project's held fees.
    JBFee[] memory _heldFees = _heldFeesOf[_projectId];

    // Delete the held fees.
    delete _heldFeesOf[_projectId];

    // Push array length in stack
    uint256 _heldFeeLength = _heldFees.length;

    // Process each fee.
    for (uint256 _i; _i < _heldFeeLength; ) {
      // Get the fee amount.
      uint256 _amount = _feeAmount(
        _heldFees[_i].amount,
        _heldFees[_i].fee,
        _heldFees[_i].feeDiscount
      );

      // Process the fee.
      _processFee(_amount, _heldFees[_i].beneficiary, _projectId);

      emit ProcessFee(_projectId, _amount, true, _heldFees[_i].beneficiary, msg.sender);

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice
    Allows the fee to be updated.

    @dev
    Only the owner of this contract can change the fee.

    @param _fee The new fee, out of MAX_FEE.
  */
  function setFee(uint256 _fee) external virtual override onlyOwner {
    // The provided fee must be within the max.
    if (_fee > _FEE_CAP) revert FEE_TOO_HIGH();

    // Store the new fee.
    fee = _fee;

    emit SetFee(_fee, msg.sender);
  }

  /**
    @notice
    Allows the fee gauge to be updated.

    @dev
    Only the owner of this contract can change the fee gauge.

    @param _feeGauge The new fee gauge.
  */
  function setFeeGauge(IJBFeeGauge _feeGauge) external virtual override onlyOwner {
    // Store the new fee gauge.
    feeGauge = _feeGauge;

    emit SetFeeGauge(_feeGauge, msg.sender);
  }

  /**
    @notice
    Sets whether projects operating on this terminal can pay towards the specified address without incurring a fee.

    @dev
    Only the owner of this contract can set addresses as feeless.

    @param _address The address that can be paid towards while still bypassing fees.
    @param _flag A flag indicating whether the terminal should be feeless or not.
  */
  function setFeelessAddress(address _address, bool _flag) external virtual override onlyOwner {
    // Set the flag value.
    isFeelessAddress[_address] = _flag;

    emit SetFeelessAddress(_address, _flag, msg.sender);
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Receives funds belonging to the specified project.

    @param _projectId The ID of the project to which the funds received belong.
    @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
    @param _token The token being paid. This terminal ignores this property since it only manages one currency. 
    @param _shouldRefundHeldFees A flag indicating if held fees should be refunded based on the amount being added.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Extra data to pass along to the emitted event.
  */
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    bool _shouldRefundHeldFees,
    string calldata _memo,
    bytes calldata _metadata
  ) public payable virtual override isTerminalOf(_projectId) {
    _token; // Prevents unused var compiler and natspec complaints.

    // If this terminal's token isn't ETH, make sure no msg.value was sent, then transfer the tokens in from msg.sender.
    if (token != JBTokens.ETH) {
      // Amount must be greater than 0.
      if (msg.value > 0) revert NO_MSG_VALUE_ALLOWED();

      // Get a reference to the balance before receiving tokens.
      uint256 _balanceBefore = _balance();

      // Transfer tokens to this terminal from the msg sender.
      _transferFrom(msg.sender, payable(address(this)), _amount);

      // The amount should reflect the change in balance.
      _amount = _balance() - _balanceBefore;
    }
    // If the terminal's token is ETH, override `_amount` with msg.value.
    else _amount = msg.value;

    // Add to balance.
    _addToBalanceOf(_projectId, _amount, _shouldRefundHeldFees, _memo, _metadata);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /** 
    @notice
    Transfers tokens.

    @param _from The address from which the transfer should originate.
    @param _to The address to which the transfer should go.
    @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  */
  function _transferFrom(
    address _from,
    address payable _to,
    uint256 _amount
  ) internal virtual {
    _from; // Prevents unused var compiler and natspec complaints.
    _to; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
  }

  /** 
    @notice
    Logic to be triggered before transferring tokens from this terminal.

    @param _to The address to which the transfer is going.
    @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  */
  function _beforeTransferTo(address _to, uint256 _amount) internal virtual {
    _to; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
  }

  /** 
    @notice
    Logic to be triggered if a transfer should be undone

    @param _to The address to which the transfer went.
    @param _amount The amount of the transfer, as a fixed point number with the same number of decimals as this terminal.
  */
  function _cancelTransferTo(address _to, uint256 _amount) internal virtual {
    _to; // Prevents unused var compiler and natspec complaints.
    _amount; // Prevents unused var compiler and natspec complaints.
  }

  /**
    @notice
    Holders can redeem their tokens to claim the project's overflowed tokens, or to trigger rules determined by the project's current funding cycle's data source.

    @dev
    Only a token holder or a designated operator can redeem its tokens.

    @param _holder The account to redeem tokens for.
    @param _projectId The ID of the project to which the tokens being redeemed belong.
    @param _tokenCount The number of project tokens to redeem, as a fixed point number with 18 decimals.
    @param _minReturnedTokens The minimum amount of terminal tokens expected in return, as a fixed point number with the same amount of decimals as the terminal.
    @param _beneficiary The address to send the terminal tokens to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return reclaimAmount The amount of terminal tokens that the project tokens were redeemed for, as a fixed point number with 18 decimals.
  */
  function _redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) internal returns (uint256 reclaimAmount) {
    // Can't send reclaimed funds to the zero address.
    if (_beneficiary == address(0)) revert REDEEM_TO_ZERO_ADDRESS();

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the funding cycle during which the redemption is being made.
    JBFundingCycle memory _fundingCycle;

    // Scoped section prevents stack too deep. `_delegateAllocations` only used within scope.
    {
      JBRedemptionDelegateAllocation[] memory _delegateAllocations;

      // Record the redemption.
      (_fundingCycle, reclaimAmount, _delegateAllocations, _memo) = store.recordRedemptionFor(
        _holder,
        _projectId,
        _tokenCount,
        _memo,
        _metadata
      );

      // The amount being reclaimed must be at least as much as was expected.
      if (reclaimAmount < _minReturnedTokens) revert INADEQUATE_RECLAIM_AMOUNT();

      // Burn the project tokens.
      if (_tokenCount > 0)
        IJBController(directory.controllerOf(_projectId)).burnTokensOf(
          _holder,
          _projectId,
          _tokenCount,
          '',
          false
        );

      // If delegate allocations were specified by the data source, fulfill them.
      if (_delegateAllocations.length != 0) {
        // Keep a reference to the token amount being forwarded to the delegate.
        JBTokenAmount memory _forwardedAmount = JBTokenAmount(token, 0, decimals, currency);

        JBDidRedeemData memory _data = JBDidRedeemData(
          _holder,
          _projectId,
          _fundingCycle.configuration,
          _tokenCount,
          JBTokenAmount(token, reclaimAmount, decimals, currency),
          _forwardedAmount,
          _beneficiary,
          _memo,
          _metadata
        );

        uint256 _numDelegates = _delegateAllocations.length;

        for (uint256 _i; _i < _numDelegates; ) {
          // Get a reference to the delegate being iterated on.
          JBRedemptionDelegateAllocation memory _delegateAllocation = _delegateAllocations[_i];

          // Trigger any inherited pre-transfer logic.
          _beforeTransferTo(address(_delegateAllocation.delegate), _delegateAllocation.amount);

          // Keep track of the msg.value to use in the delegate call
          uint256 _payableValue;

          // If this terminal's token is ETH, send it in msg.value.
          if (token == JBTokens.ETH) _payableValue = _delegateAllocation.amount;

          // Pass the correct token forwardedAmount to the delegate
          _data.forwardedAmount.value = _delegateAllocation.amount;

          _delegateAllocation.delegate.didRedeem{value: _payableValue}(_data);

          emit DelegateDidRedeem(
            _delegateAllocation.delegate,
            _data,
            _delegateAllocation.amount,
            msg.sender
          );
          unchecked {
            ++_i;
          }
        }
      }
    }

    // Send the reclaimed funds to the beneficiary.
    if (reclaimAmount > 0) _transferFrom(address(this), _beneficiary, reclaimAmount);

    emit RedeemTokens(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _holder,
      _beneficiary,
      _tokenCount,
      reclaimAmount,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /**
    @notice
    Distributes payouts for a project with the distribution limit of its current funding cycle.

    @dev
    Payouts are sent to the preprogrammed splits. Any leftover is sent to the project's owner.

    @dev
    Anyone can distribute payouts on a project's behalf. The project can preconfigure a wildcard split that is used to send funds to msg.sender. This can be used to incentivize calling this function.

    @dev
    All funds distributed outside of this contract or any feeless terminals incure the protocol fee.

    @param _projectId The ID of the project having its payouts distributed.
    @param _amount The amount of terminal tokens to distribute, as a fixed point number with same number of decimals as this terminal.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's distribution limit currency.
    @param _minReturnedTokens The minimum number of terminal tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with the same number of decimals as this terminal.
    @param _metadata Bytes to send along to the emitted event, if provided.

    @return netLeftoverDistributionAmount The amount that was sent to the project owner, as a fixed point number with the same amount of decimals as this terminal.
  */
  function _distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) internal returns (uint256 netLeftoverDistributionAmount) {
    // Record the distribution.
    (JBFundingCycle memory _fundingCycle, uint256 _distributedAmount) = store.recordDistributionFor(
      _projectId,
      _amount,
      _currency
    );

    // The amount being distributed must be at least as much as was expected.
    if (_distributedAmount < _minReturnedTokens) revert INADEQUATE_DISTRIBUTION_AMOUNT();

    // Get a reference to the project owner, which will receive tokens from paying the platform fee
    // and receive any extra distributable funds not allocated to payout splits.
    address payable _projectOwner = payable(projects.ownerOf(_projectId));

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the fee amount that was paid.
    uint256 _fee;

    // Scoped section prevents stack too deep. `_feeDiscount`, `_feeEligibleDistributionAmount`, and `_leftoverDistributionAmount` only used within scope.
    {
      // Get the amount of discount that should be applied to any fees taken.
      // If the fee is zero, set the discount to 100% for convenience.
      uint256 _feeDiscount = fee == 0
        ? JBConstants.MAX_FEE_DISCOUNT
        : _currentFeeDiscount(_projectId);

      // The amount distributed that is eligible for incurring fees.
      uint256 _feeEligibleDistributionAmount;

      // The amount leftover after distributing to the splits.
      uint256 _leftoverDistributionAmount;

      // Payout to splits and get a reference to the leftover transfer amount after all splits have been paid.
      // Also get a reference to the amount that was distributed to splits from which fees should be taken.
      (_leftoverDistributionAmount, _feeEligibleDistributionAmount) = _distributeToPayoutSplitsOf(
        _projectId,
        _fundingCycle.configuration,
        payoutSplitsGroup,
        _distributedAmount,
        _feeDiscount
      );

      if (_feeDiscount != JBConstants.MAX_FEE_DISCOUNT) {
        // Leftover distribution amount is also eligible for a fee since the funds are going out of the ecosystem to _beneficiary.
        unchecked {
          _feeEligibleDistributionAmount += _leftoverDistributionAmount;
        }
      }

      // Take the fee.
      _fee = _feeEligibleDistributionAmount != 0
        ? _takeFeeFrom(
          _projectId,
          _fundingCycle,
          _feeEligibleDistributionAmount,
          _projectOwner,
          _feeDiscount
        )
        : 0;

      // Transfer any remaining balance to the project owner and update returned leftover accordingly.
      if (_leftoverDistributionAmount != 0) {
        // Subtract the fee from the net leftover amount.
        netLeftoverDistributionAmount =
          _leftoverDistributionAmount -
          _feeAmount(_leftoverDistributionAmount, fee, _feeDiscount);

        // Transfer the amount to the project owner.
        _transferFrom(address(this), _projectOwner, netLeftoverDistributionAmount);
      }
    }

    emit DistributePayouts(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _projectOwner,
      _amount,
      _distributedAmount,
      _fee,
      netLeftoverDistributionAmount,
      _metadata,
      msg.sender
    );
  }

  /**
    @notice
    Allows a project to send funds from its overflow up to the preconfigured allowance.

    @dev
    Only a project's owner or a designated operator can use its allowance.

    @dev
    Incurs the protocol fee.

    @param _projectId The ID of the project to use the allowance of.
    @param _amount The amount of terminal tokens to use from this project's current allowance, as a fixed point number with the same amount of decimals as this terminal.
    @param _currency The expected currency of the amount being distributed. Must match the project's current funding cycle's overflow allowance currency.
    @param _minReturnedTokens The minimum number of tokens that the `_amount` should be valued at in terms of this terminal's currency, as a fixed point number with 18 decimals.
    @param _beneficiary The address to send the funds to.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Bytes to send along to the emitted event, if provided.

    @return netDistributedAmount The amount of tokens that was distributed to the beneficiary, as a fixed point number with the same amount of decimals as the terminal.
  */
  function _useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string memory _memo,
    bytes calldata _metadata
  ) internal returns (uint256 netDistributedAmount) {
    // Record the use of the allowance.
    (JBFundingCycle memory _fundingCycle, uint256 _distributedAmount) = store.recordUsedAllowanceOf(
      _projectId,
      _amount,
      _currency
    );

    // The amount being withdrawn must be at least as much as was expected.
    if (_distributedAmount < _minReturnedTokens) revert INADEQUATE_DISTRIBUTION_AMOUNT();

    // Scoped section prevents stack too deep. `_fee`, `_projectOwner`, `_feeDiscount`, and `_netAmount` only used within scope.
    {
      // Keep a reference to the fee amount that was paid.
      uint256 _fee;

      // Get a reference to the project owner, which will receive tokens from paying the platform fee.
      address _projectOwner = projects.ownerOf(_projectId);

      // Get the amount of discount that should be applied to any fees taken.
      // If the fee is zero or if the fee is being used by an address that doesn't incur fees, set the discount to 100% for convenience.
      uint256 _feeDiscount = fee == 0 || isFeelessAddress[msg.sender]
        ? JBConstants.MAX_FEE_DISCOUNT
        : _currentFeeDiscount(_projectId);

      // Take a fee from the `_distributedAmount`, if needed.
      _fee = _feeDiscount == JBConstants.MAX_FEE_DISCOUNT
        ? 0
        : _takeFeeFrom(_projectId, _fundingCycle, _distributedAmount, _projectOwner, _feeDiscount);

      unchecked {
        // The net amount is the withdrawn amount without the fee.
        netDistributedAmount = _distributedAmount - _fee;
      }

      // Transfer any remaining balance to the beneficiary.
      if (netDistributedAmount > 0)
        _transferFrom(address(this), _beneficiary, netDistributedAmount);
    }

    emit UseAllowance(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _beneficiary,
      _amount,
      _distributedAmount,
      netDistributedAmount,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /**
    @notice
    Pays out splits for a project's funding cycle configuration.

    @param _projectId The ID of the project for which payout splits are being distributed.
    @param _domain The domain of the splits to distribute the payout between.
    @param _group The group of the splits to distribute the payout between.
    @param _amount The total amount being distributed, as a fixed point number with the same number of decimals as this terminal.
    @param _feeDiscount The amount of discount to apply to the fee, out of the MAX_FEE.

    @return leftoverAmount If the leftover amount if the splits don't add up to 100%.
    @return feeEligibleDistributionAmount The total amount of distributions that are eligible to have fees taken from.
  */
  function _distributeToPayoutSplitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    uint256 _amount,
    uint256 _feeDiscount
  ) internal returns (uint256 leftoverAmount, uint256 feeEligibleDistributionAmount) {
    // Set the leftover amount to the initial amount.
    leftoverAmount = _amount;
    // The total percentage available to split
    uint256 leftoverPercentage = JBConstants.SPLITS_TOTAL_PERCENT;

    // Get a reference to the project's payout splits.
    JBSplit[] memory _splits = splitsStore.splitsOf(_projectId, _domain, _group);

    // Transfer between all splits.
    for (uint256 _i; _i < _splits.length; ) {
      // Get a reference to the split being iterated on.
      JBSplit memory _split = _splits[_i];

      // The amount to send towards the split.
      uint256 _payoutAmount = _split.percent == leftoverPercentage
        ? leftoverAmount
        : PRBMath.mulDiv(_amount, _split.percent, JBConstants.SPLITS_TOTAL_PERCENT);

      // Decrement the leftover percentage.
      leftoverPercentage -= _split.percent;

      // The payout amount substracting any applicable incurred fees.
      uint256 _netPayoutAmount = _distributeToPayoutSplit(
        _split,
        _projectId,
        _group,
        _payoutAmount,
        _feeDiscount
      );

      // If the split allocator is set as feeless, this distribution is not eligible for a fee.
      if (_netPayoutAmount != 0 && _netPayoutAmount != _payoutAmount)
        feeEligibleDistributionAmount += _payoutAmount;

      if (_payoutAmount > 0) {
        // Subtract from the amount to be sent to the beneficiary.
        unchecked {
          leftoverAmount = leftoverAmount - _payoutAmount;
        }
      }

      emit DistributeToPayoutSplit(
        _projectId,
        _domain,
        _group,
        _split,
        _payoutAmount,
        _netPayoutAmount,
        msg.sender
      );

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice
    Pays out a split for a project's funding cycle configuration.
  
    @param _split The split to distribute payouts to.
    @param _amount The total amount being distributed to the split, as a fixed point number with the same number of decimals as this terminal.
    @param _feeDiscount The amount of discount to apply to the fee, out of the MAX_FEE.

    @return netPayoutAmount The amount sent to the split after subtracting fees.
  */
  function _distributeToPayoutSplit(
    JBSplit memory _split,
    uint256 _projectId,
    uint256 _group,
    uint256 _amount,
    uint256 _feeDiscount
  ) internal returns (uint256 netPayoutAmount) {
    // If there's an allocator set, transfer to its `allocate` function.
    if (_split.allocator != IJBSplitAllocator(address(0))) {
      // If the split allocator is set as feeless, this distribution is not eligible for a fee.
      if (
        _feeDiscount == JBConstants.MAX_FEE_DISCOUNT || isFeelessAddress[address(_split.allocator)]
      )
        netPayoutAmount = _amount;
        // This distribution is eligible for a fee since the funds are leaving this contract and the allocator isn't listed as feeless.
      else {
        unchecked {
          netPayoutAmount = _amount - _feeAmount(_amount, fee, _feeDiscount);
        }
      }

      // Trigger any inherited pre-transfer logic.
      _beforeTransferTo(address(_split.allocator), netPayoutAmount);

      // Create the data to send to the allocator.
      JBSplitAllocationData memory _data = JBSplitAllocationData(
        token,
        netPayoutAmount,
        decimals,
        _projectId,
        _group,
        _split
      );

      // Trigger the allocator's `allocate` function.
      uint256 _error;
      bytes memory _reason;

      if (
        ERC165Checker.supportsInterface(
          address(_split.allocator),
          type(IJBSplitAllocator).interfaceId
        )
      )
        // If this terminal's token is ETH, send it in msg.value.
        try _split.allocator.allocate{value: token == JBTokens.ETH ? netPayoutAmount : 0}(_data) {

        } catch (bytes memory reason) {
          _reason = reason;
          _error = 1;
        }
      else _error = 2;


      if (_error != 0) {
        // Trigger any inhereted post-transfer cancelation logic.
        _cancelTransferTo(address(_split.allocator), netPayoutAmount);

        // Set the net payout amount to 0 to signal the reversion.
        netPayoutAmount = 0;

        // Add undistributed amount back to project's balance.
        store.recordAddedBalanceFor(_projectId, _amount);

        emit PayoutReverted(_projectId, _split, _amount, _error == 1 ? _reason : abi.encode("IERC165 fail"), msg.sender);
      }

      // Otherwise, if a project is specified, make a payment to it.
    } else if (_split.projectId != 0) {
      // Get a reference to the Juicebox terminal being used.
      IJBPaymentTerminal _terminal = directory.primaryTerminalOf(_split.projectId, token);

      // The project must have a terminal to send funds to.
      if (_terminal == IJBPaymentTerminal(address(0))) revert TERMINAL_IN_SPLIT_ZERO_ADDRESS();

      // If the terminal is set as feeless, this distribution is not eligible for a fee.
      if (
        _terminal == this ||
        _feeDiscount == JBConstants.MAX_FEE_DISCOUNT ||
        isFeelessAddress[address(_terminal)]
      )
        netPayoutAmount = _amount;
        // This distribution is eligible for a fee since the funds are leaving this contract and the terminal isn't listed as feeless.
      else {
        unchecked {
          netPayoutAmount = _amount - _feeAmount(_amount, fee, _feeDiscount);
        }
      }

      // Trigger any inherited pre-transfer logic.
      _beforeTransferTo(address(_terminal), netPayoutAmount);

      // Send the projectId in the metadata.
      bytes memory _projectMetadata = new bytes(32);
      _projectMetadata = bytes(abi.encodePacked(_projectId));

      // Add to balance if prefered.
      if (_split.preferAddToBalance)
        try
          _terminal.addToBalanceOf{value: token == JBTokens.ETH ? netPayoutAmount : 0}(
            _split.projectId,
            netPayoutAmount,
            token,
            '',
            _projectMetadata
          )
        {} catch (bytes memory reason) {
          // Trigger any inhereted post-transfer cancelation logic.
          _cancelTransferTo(address(_terminal), netPayoutAmount);

          // Set the net payout amount to 0 to signal the reversion.
          netPayoutAmount = 0;

          // Add undistributed amount back to project's balance.
          store.recordAddedBalanceFor(_projectId, _amount);

          emit PayoutReverted(_projectId, _split, _amount, reason, msg.sender);
        }
      else
        try
          _terminal.pay{value: token == JBTokens.ETH ? netPayoutAmount : 0}(
            _split.projectId,
            netPayoutAmount,
            token,
            _split.beneficiary != address(0) ? _split.beneficiary : msg.sender,
            0,
            _split.preferClaimed,
            '',
            _projectMetadata
          )
        {} catch (bytes memory reason) {
          // Trigger any inhereted post-transfer cancelation logic.
          _cancelTransferTo(address(_terminal), netPayoutAmount);

          // Set the net payout amount to 0 to signal the reversion.
          netPayoutAmount = 0;

          // Add undistributed amount back to project's balance.
          store.recordAddedBalanceFor(_projectId, _amount);

          emit PayoutReverted(_projectId, _split, _amount, reason, msg.sender);
        }
    } else {
      // Keep a reference to the beneficiary.
      address payable _beneficiary = _split.beneficiary != address(0)
        ? _split.beneficiary
        : payable(msg.sender);

      // If there's a full discount, this distribution is not eligible for a fee.
      // Don't enforce feeless address for the beneficiary since the funds are leaving the ecosystem.
      if (_feeDiscount == JBConstants.MAX_FEE_DISCOUNT)
        netPayoutAmount = _amount;
        // This distribution is eligible for a fee since the funds are leaving this contract and the beneficiary isn't listed as feeless.
      else {
        unchecked {
          netPayoutAmount = _amount - _feeAmount(_amount, fee, _feeDiscount);
        }
      }

      // If there's a beneficiary, send the funds directly to the beneficiary. Otherwise send to the msg.sender.
      _transferFrom(address(this), _beneficiary, netPayoutAmount);
    }
  }

  /**
    @notice
    Takes a fee into the platform's project, which has an id of _FEE_BENEFICIARY_PROJECT_ID.

    @param _projectId The ID of the project having fees taken from.
    @param _fundingCycle The funding cycle during which the fee is being taken.
    @param _amount The amount of the fee to take, as a floating point number with 18 decimals.
    @param _beneficiary The address to mint the platforms tokens for.
    @param _feeDiscount The amount of discount to apply to the fee, out of the MAX_FEE.

    @return feeAmount The amount of the fee taken.
  */
  function _takeFeeFrom(
    uint256 _projectId,
    JBFundingCycle memory _fundingCycle,
    uint256 _amount,
    address _beneficiary,
    uint256 _feeDiscount
  ) internal returns (uint256 feeAmount) {
    feeAmount = _feeAmount(_amount, fee, _feeDiscount);

    if (_fundingCycle.shouldHoldFees()) {
      // Store the held fee.
      _heldFeesOf[_projectId].push(JBFee(_amount, uint32(fee), uint32(_feeDiscount), _beneficiary));

      emit HoldFee(_projectId, _amount, fee, _feeDiscount, _beneficiary, msg.sender);
    } else {
      // Process the fee.
      _processFee(feeAmount, _beneficiary, _projectId); // Take the fee.

      emit ProcessFee(_projectId, feeAmount, false, _beneficiary, msg.sender);
    }
  }

  /**
    @notice
    Process a fee of the specified amount.

    @param _amount The fee amount, as a floating point number with 18 decimals.
    @param _beneficiary The address to mint the platform's tokens for.
    @param _from The project ID the fee is being paid from.
  */
  function _processFee(
    uint256 _amount,
    address _beneficiary,
    uint256 _from
  ) internal {
    // Get the terminal for the protocol project.
    IJBPaymentTerminal _terminal = directory.primaryTerminalOf(_FEE_BENEFICIARY_PROJECT_ID, token);

    // If this terminal's token is ETH, send it in msg.value.
    uint256 _payableValue = token == JBTokens.ETH ? _amount : 0;

    // Send the projectId in the metadata.
    bytes memory _projectMetadata = new bytes(32);
    _projectMetadata = bytes(abi.encodePacked(_from));

    // Trigger any inherited pre-transfer logic if funds will be transferred.
    if (address(_terminal) != address(this)) _beforeTransferTo(address(_terminal), _amount);

    try
      // Send the fee.
      _terminal.pay{value: _payableValue}(
        _FEE_BENEFICIARY_PROJECT_ID,
        _amount,
        token,
        _beneficiary,
        0,
        false,
        '',
        _projectMetadata
      )
    {} catch (bytes memory reason) {
      // Trigger any inhereted post-transfer cancelation logic if the pre-transfer logic was triggered.
      if (address(_terminal) != address(this)) _cancelTransferTo(address(_terminal), _amount);

      // Add fee amount back to project's balance.
      store.recordAddedBalanceFor(_from, _amount);

      emit FeeReverted(_from, _FEE_BENEFICIARY_PROJECT_ID, _amount, reason,  msg.sender);
    }
  }

  /**
    @notice
    Contribute tokens to a project.

    @param _amount The amount of terminal tokens being received, as a fixed point number with the same amount of decimals as this terminal. If this terminal's token is ETH, this is ignored and msg.value is used in its place.
    @param _payer The address making the payment.
    @param _projectId The ID of the project being paid.
    @param _beneficiary The address to mint tokens for and pass along to the funding cycle's data source and delegate.
    @param _minReturnedTokens The minimum number of project tokens expected in return, as a fixed point number with the same amount of decimals as this terminal.
    @param _preferClaimedTokens A flag indicating whether the request prefers to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract. Leaving them unclaimed saves gas.
    @param _memo A memo to pass along to the emitted event, and passed along the the funding cycle's data source and delegate.  A data source can alter the memo before emitting in the event and forwarding to the delegate.
    @param _metadata Bytes to send along to the data source, delegate, and emitted event, if provided.

    @return beneficiaryTokenCount The number of tokens minted for the beneficiary, as a fixed point number with 18 decimals.
  */
  function _pay(
    uint256 _amount,
    address _payer,
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string memory _memo,
    bytes memory _metadata
  ) internal returns (uint256 beneficiaryTokenCount) {
    // Cant send tokens to the zero address.
    if (_beneficiary == address(0)) revert PAY_TO_ZERO_ADDRESS();

    // Define variables that will be needed outside the scoped section below.
    // Keep a reference to the funding cycle during which the payment is being made.
    JBFundingCycle memory _fundingCycle;

    // Scoped section prevents stack too deep. `_delegateAllocations` and `_tokenCount` only used within scope.
    {
      JBPayDelegateAllocation[] memory _delegateAllocations;
      uint256 _tokenCount;

      // Bundle the amount info into a JBTokenAmount struct.
      JBTokenAmount memory _bundledAmount = JBTokenAmount(token, _amount, decimals, currency);

      // Record the payment.
      (_fundingCycle, _tokenCount, _delegateAllocations, _memo) = store.recordPaymentFrom(
        _payer,
        _bundledAmount,
        _projectId,
        baseWeightCurrency,
        _beneficiary,
        _memo,
        _metadata
      );

      // Mint the tokens if needed.
      if (_tokenCount > 0)
        // Set token count to be the number of tokens minted for the beneficiary instead of the total amount.
        beneficiaryTokenCount = IJBController(directory.controllerOf(_projectId)).mintTokensOf(
          _projectId,
          _tokenCount,
          _beneficiary,
          '',
          _preferClaimedTokens,
          true
        );

      // The token count for the beneficiary must be greater than or equal to the minimum expected.
      if (beneficiaryTokenCount < _minReturnedTokens) revert INADEQUATE_TOKEN_COUNT();

      // If delegate allocations were specified by the data source, fulfill them.
      if (_delegateAllocations.length != 0) {
        // Keep a reference to the token amount being forwarded to the delegate.
        JBTokenAmount memory _forwardedAmount = JBTokenAmount(token, _amount, decimals, currency);

        JBDidPayData memory _data = JBDidPayData(
          _payer,
          _projectId,
          _fundingCycle.configuration,
          _bundledAmount,
          _forwardedAmount,
          beneficiaryTokenCount,
          _beneficiary,
          _preferClaimedTokens,
          _memo,
          _metadata
        );

        // Get a reference to the number of delegates to allocate to.
        uint256 _numDelegates = _delegateAllocations.length;

        for (uint256 _i; _i < _numDelegates; ) {
          // Get a reference to the delegate being iterated on.
          JBPayDelegateAllocation memory _delegateAllocation = _delegateAllocations[_i];

          // Trigger any inherited pre-transfer logic.
          _beforeTransferTo(address(_delegateAllocation.delegate), _delegateAllocation.amount);

          // Keep track of the msg.value to use in the delegate call
          uint256 _payableValue;

          // If this terminal's token is ETH, send it in msg.value.
          if (token == JBTokens.ETH) _payableValue = _delegateAllocation.amount;

          // Pass the correct token forwardedAmount to the delegate
          _data.forwardedAmount.value = _delegateAllocation.amount;

          _delegateAllocation.delegate.didPay{value: _payableValue}(_data);

          emit DelegateDidPay(
            _delegateAllocation.delegate,
            _data,
            _delegateAllocation.amount,
            msg.sender
          );

          unchecked {
            ++_i;
          }
        }
      }
    }

    emit Pay(
      _fundingCycle.configuration,
      _fundingCycle.number,
      _projectId,
      _payer,
      _beneficiary,
      _amount,
      beneficiaryTokenCount,
      _memo,
      _metadata,
      msg.sender
    );
  }

  /**
    @notice
    Receives funds belonging to the specified project.

    @param _projectId The ID of the project to which the funds received belong.
    @param _amount The amount of tokens to add, as a fixed point number with the same number of decimals as this terminal. If this is an ETH terminal, this is ignored and msg.value is used instead.
    @param _shouldRefundHeldFees A flag indicating if held fees should be refunded based on the amount being added.
    @param _memo A memo to pass along to the emitted event.
    @param _metadata Extra data to pass along to the emitted event.
  */
  function _addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    bool _shouldRefundHeldFees,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    // Refund any held fees to make sure the project doesn't pay double for funds going in and out of the protocol.
    uint256 _refundedFees = _shouldRefundHeldFees ? _refundHeldFees(_projectId, _amount) : 0;

    // Record the added funds with any refunded fees.
    store.recordAddedBalanceFor(_projectId, _amount + _refundedFees);

    emit AddToBalance(_projectId, _amount, _refundedFees, _memo, _metadata, msg.sender);
  }

  /**
    @notice
    Refund fees based on the specified amount.

    @param _projectId The project for which fees are being refunded.
    @param _amount The amount to base the refund on, as a fixed point number with the same amount of decimals as this terminal.

    @return refundedFees How much fees were refunded, as a fixed point number with the same number of decimals as this terminal
  */
  function _refundHeldFees(uint256 _projectId, uint256 _amount)
    internal
    returns (uint256 refundedFees)
  {
    // Get a reference to the project's held fees.
    JBFee[] memory _heldFees = _heldFeesOf[_projectId];

    // Delete the current held fees.
    delete _heldFeesOf[_projectId];

    // Get a reference to the leftover amount once all fees have been settled.
    uint256 leftoverAmount = _amount;

    // Push length in stack
    uint256 _heldFeesLength = _heldFees.length;

    // Process each fee.
    for (uint256 _i; _i < _heldFeesLength; ) {
      if (leftoverAmount == 0) _heldFeesOf[_projectId].push(_heldFees[_i]);
      else if (leftoverAmount >= _heldFees[_i].amount) {
        unchecked {
          leftoverAmount = leftoverAmount - _heldFees[_i].amount;
          refundedFees += _feeAmount(
            _heldFees[_i].amount,
            _heldFees[_i].fee,
            _heldFees[_i].feeDiscount
          );
        }
      } else {
        unchecked {
          _heldFeesOf[_projectId].push(
            JBFee(
              _heldFees[_i].amount - leftoverAmount,
              _heldFees[_i].fee,
              _heldFees[_i].feeDiscount,
              _heldFees[_i].beneficiary
            )
          );
          refundedFees += _feeAmount(leftoverAmount, _heldFees[_i].fee, _heldFees[_i].feeDiscount);
        }
        leftoverAmount = 0;
      }

      unchecked {
        ++_i;
      }
    }

    emit RefundHeldFees(_projectId, _amount, refundedFees, leftoverAmount, msg.sender);
  }

  /** 
    @notice 
    Returns the fee amount based on the provided amount for the specified project.

    @param _amount The amount that the fee is based on, as a fixed point number with the same amount of decimals as this terminal.
    @param _fee The percentage of the fee, out of MAX_FEE. 
    @param _feeDiscount The percentage discount that should be applied out of the max amount, out of MAX_FEE_DISCOUNT.

    @return The amount of the fee, as a fixed point number with the same amount of decimals as this terminal.
  */
  function _feeAmount(
    uint256 _amount,
    uint256 _fee,
    uint256 _feeDiscount
  ) internal pure returns (uint256) {
    // Calculate the discounted fee.
    uint256 _discountedFee = _fee -
      PRBMath.mulDiv(_fee, _feeDiscount, JBConstants.MAX_FEE_DISCOUNT);

    // The amount of tokens from the `_amount` to pay as a fee.
    return
      _amount - PRBMath.mulDiv(_amount, JBConstants.MAX_FEE, _discountedFee + JBConstants.MAX_FEE);
  }

  /** 
    @notice
    Get the fee discount from the fee gauge for the specified project.

    @param _projectId The ID of the project to get a fee discount for.
    
    @return feeDiscount The fee discount, which should be interpreted as a percentage out MAX_FEE_DISCOUNT.
  */
  function _currentFeeDiscount(uint256 _projectId) internal view returns (uint256) {
    // Can't take a fee if the protocol project doesn't have a terminal that accepts the token.
    if (
      directory.primaryTerminalOf(_FEE_BENEFICIARY_PROJECT_ID, token) ==
      IJBPaymentTerminal(address(0))
    ) return JBConstants.MAX_FEE_DISCOUNT;

    // Get the fee discount.
    if (feeGauge != IJBFeeGauge(address(0)))
      // If the guage reverts, keep the discount at 0.
      try feeGauge.currentDiscountFor(_projectId) returns (uint256 discount) {
        // If the fee discount is greater than the max, we ignore the return value
        if (discount <= JBConstants.MAX_FEE_DISCOUNT) return discount;
      } catch {
        return 0;
      }

    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './../interfaces/IJBSingleTokenPaymentTerminal.sol';

/**
  @notice
  Generic terminal managing all inflows of funds into the protocol ecosystem for one token.

  @dev
  Adheres to -
  IJBSingleTokenPaymentTerminals: General interface for the methods in this contract that interact with the blockchain's state according to the protocol's rules.

  @dev
  Inherits from -
  ERC165: Introspection on interface adherance. 
*/
abstract contract JBSingleTokenPaymentTerminal is ERC165, IJBSingleTokenPaymentTerminal {
  //*********************************************************************//
  // ---------------- public immutable stored properties --------------- //
  //*********************************************************************//

  /**
    @notice
    The token that this terminal accepts.
  */
  address public immutable override token;

  /**
    @notice
    The number of decimals the token fixed point amounts are expected to have.
  */
  uint256 public immutable override decimals;

  /**
    @notice
    The currency to use when resolving price feeds for this terminal.
  */
  uint256 public immutable override currency;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /** 
    @notice
    A flag indicating if this terminal accepts the specified token.

    @param _token The token to check if this terminal accepts or not.
    @param _projectId The project ID to check for token acceptance.

    @return The flag.
  */
  function acceptsToken(address _token, uint256 _projectId) external view override returns (bool) {
    _projectId; // Prevents unused var compiler and natspec complaints.

    return _token == token;
  }

  /** 
    @notice
    The decimals that should be used in fixed number accounting for the specified token.

    @param _token The token to check for the decimals of.

    @return The number of decimals for the token.
  */
  function decimalsForToken(address _token) external view override returns (uint256) {
    _token; // Prevents unused var compiler and natspec complaints.

    return decimals;
  }

  /** 
    @notice
    The currency that should be used for the specified token.

    @param _token The token to check for the currency of.

    @return The currency index.
  */
  function currencyForToken(address _token) external view override returns (uint256) {
    _token; // Prevents unused var compiler and natspec complaints.

    return currency;
  }

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev 
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBPaymentTerminal).interfaceId ||
      _interfaceId == type(IJBSingleTokenPaymentTerminal).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
    @param _token The token that this terminal manages.
    @param _decimals The number of decimals the token fixed point amounts are expected to have.
    @param _currency The currency that this terminal's token adheres to for price feeds.
  */
  constructor(
    address _token,
    uint256 _decimals,
    uint256 _currency
  ) {
    token = _token;
    decimals = _decimals;
    currency = _currency;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBAllowanceTerminal3_1 {
  function useAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  ) external returns (uint256 netDistributedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBFeeGauge {
  function currentDiscountFor(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBFeeHoldingTerminal {
  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    bool _shouldRefundHeldFees,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBOperatorStore.sol';

interface IJBOperatable {
  function operatorStore() external view returns (IJBOperatorStore);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBOperatorData.sol';

interface IJBOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(JBOperatorData calldata _operatorData) external;

  function setOperators(JBOperatorData[] calldata _operatorData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidPayData.sol';

/**
  @title
  Pay delegate

  @notice
  Delegate called after JBTerminal.pay(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBPayDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.pay(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidPayData struct:
                  address payer;
                  uint256 projectId;
                  uint256 currentFundingCycleConfiguration;
                  JBTokenAmount amount;
                  JBTokenAmount forwardedAmount;
                  uint256 projectTokenCount;
                  address beneficiary;
                  bool preferClaimedTokens;
                  string memo;
                  bytes metadata;
  */
  function didPay(JBDidPayData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBFee.sol';
import './IJBAllowanceTerminal3_1.sol';
import './IJBDirectory.sol';
import './IJBFeeGauge.sol';
import './IJBFeeHoldingTerminal.sol';
import './IJBPayDelegate.sol';
import './IJBPaymentTerminal.sol';
import './IJBPayoutTerminal3_1.sol';
import './IJBPrices.sol';
import './IJBProjects.sol';
import './IJBRedemptionDelegate.sol';
import './IJBRedemptionTerminal.sol';
import './IJBSingleTokenPaymentTerminalStore.sol';
import './IJBSplitsStore.sol';

interface IJBPayoutRedemptionPaymentTerminal3_1 is
  IJBPaymentTerminal,
  IJBPayoutTerminal3_1,
  IJBAllowanceTerminal3_1,
  IJBRedemptionTerminal,
  IJBFeeHoldingTerminal
{
  event AddToBalance(
    uint256 indexed projectId,
    uint256 amount,
    uint256 refundedFees,
    string memo,
    bytes metadata,
    address caller
  );

  event Migrate(
    uint256 indexed projectId,
    IJBPaymentTerminal indexed to,
    uint256 amount,
    address caller
  );

  event DistributePayouts(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 distributedAmount,
    uint256 fee,
    uint256 beneficiaryDistributionAmount,
    bytes metadata,
    address caller
  );

  event UseAllowance(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 amount,
    uint256 distributedAmount,
    uint256 netDistributedamount,
    string memo,
    bytes metadata,
    address caller
  );

  event HoldFee(
    uint256 indexed projectId,
    uint256 indexed amount,
    uint256 indexed fee,
    uint256 feeDiscount,
    address beneficiary,
    address caller
  );

  event ProcessFee(
    uint256 indexed projectId,
    uint256 indexed amount,
    bool indexed wasHeld,
    address beneficiary,
    address caller
  );

  event RefundHeldFees(
    uint256 indexed projectId,
    uint256 indexed amount,
    uint256 indexed refundedFees,
    uint256 leftoverAmount,
    address caller
  );

  event Pay(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address payer,
    address beneficiary,
    uint256 amount,
    uint256 beneficiaryTokenCount,
    string memo,
    bytes metadata,
    address caller
  );

  event DelegateDidPay(
    IJBPayDelegate indexed delegate,
    JBDidPayData data,
    uint256 delegatedAmount,
    address caller
  );

  event RedeemTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address holder,
    address beneficiary,
    uint256 tokenCount,
    uint256 reclaimedAmount,
    string memo,
    bytes metadata,
    address caller
  );

  event DelegateDidRedeem(
    IJBRedemptionDelegate indexed delegate,
    JBDidRedeemData data,
    uint256 delegatedAmount,
    address caller
  );

  event DistributeToPayoutSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 amount,
    uint256 netAmount,
    address caller
  );

  event SetFee(uint256 fee, address caller);

  event SetFeeGauge(IJBFeeGauge indexed feeGauge, address caller);

  event SetFeelessAddress(address indexed addrs, bool indexed flag, address caller);

  event PayoutReverted(uint256 indexed projectId, JBSplit split, uint256 amount, bytes reason, address caller);

  event FeeReverted(
    uint256 indexed projectId,
    uint256 indexed feeProjectId,
    uint256 amount,
    bytes reason,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function store() external view returns (IJBSingleTokenPaymentTerminalStore);

  function baseWeightCurrency() external view returns (uint256);

  function payoutSplitsGroup() external view returns (uint256);

  function heldFeesOf(uint256 _projectId) external view returns (JBFee[] memory);

  function fee() external view returns (uint256);

  function feeGauge() external view returns (IJBFeeGauge);

  function isFeelessAddress(address _contract) external view returns (bool);

  function migrate(uint256 _projectId, IJBPaymentTerminal _to) external returns (uint256 balance);

  function processFees(uint256 _projectId) external;

  function setFee(uint256 _fee) external;

  function setFeeGauge(IJBFeeGauge _feeGauge) external;

  function setFeelessAddress(address _contract, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPayoutTerminal3_1 {
  function distributePayoutsOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency,
    address _token,
    uint256 _minReturnedTokens,
    bytes calldata _metadata
  ) external returns (uint256 netLeftoverDistributionAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBDidRedeemData.sol';

/**
  @title
  Redemption delegate

  @notice
  Delegate called after JBTerminal.redeemTokensOf(..) logic completion (if passed by the funding cycle datasource)

  @dev
  Adheres to:
  IERC165 for adequate interface integration
*/
interface IJBRedemptionDelegate is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.redeemTokensOf(..), after the execution of its logic

    @dev
    Critical business logic should be protected by an appropriate access control
    
    @param _data the data passed by the terminal, as a JBDidRedeemData struct:
                address holder;
                uint256 projectId;
                uint256 currentFundingCycleConfiguration;
                uint256 projectTokenCount;
                JBTokenAmount reclaimedAmount;
                JBTokenAmount forwardedAmount;
                address payable beneficiary;
                string memo;
                bytes metadata;
  */
  function didRedeem(JBDidRedeemData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBRedemptionTerminal {
  function redeemTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    address _token,
    uint256 _minReturnedTokens,
    address payable _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  ) external returns (uint256 reclaimAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminal is IJBPaymentTerminal {
  function token() external view returns (address);

  function currency() external view returns (uint256);

  function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBFundingCycle.sol';
import './../structs/JBPayDelegateAllocation.sol';
import './../structs/JBRedemptionDelegateAllocation.sol';
import './../structs/JBTokenAmount.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBPrices.sol';
import './IJBSingleTokenPaymentTerminal.sol';

interface IJBSingleTokenPaymentTerminalStore {
  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function directory() external view returns (IJBDirectory);

  function prices() external view returns (IJBPrices);

  function balanceOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function usedDistributionLimitOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleNumber
  ) external view returns (uint256);

  function usedOverflowAllowanceOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _fundingCycleConfiguration
  ) external view returns (uint256);

  function currentOverflowOf(IJBSingleTokenPaymentTerminal _terminal, uint256 _projectId)
    external
    view
    returns (uint256);

  function currentTotalOverflowOf(
    uint256 _projectId,
    uint256 _decimals,
    uint256 _currency
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    IJBSingleTokenPaymentTerminal _terminal,
    uint256 _projectId,
    uint256 _tokenCount,
    bool _useTotalOverflow
  ) external view returns (uint256);

  function currentReclaimableOverflowOf(
    uint256 _projectId,
    uint256 _tokenCount,
    uint256 _totalSupply,
    uint256 _overflow
  ) external view returns (uint256);

  function recordPaymentFrom(
    address _payer,
    JBTokenAmount memory _amount,
    uint256 _projectId,
    uint256 _baseWeightCurrency,
    address _beneficiary,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 tokenCount,
      JBPayDelegateAllocation[] memory delegateAllocations,
      string memory memo
    );

  function recordRedemptionFor(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bytes calldata _metadata
  )
    external
    returns (
      JBFundingCycle memory fundingCycle,
      uint256 reclaimAmount,
      JBRedemptionDelegateAllocation[] memory delegateAllocations,
      string memory memo
    );

  function recordDistributionFor(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 distributedAmount);

  function recordUsedAllowanceOf(
    uint256 _projectId,
    uint256 _amount,
    uint256 _currency
  ) external returns (JBFundingCycle memory fundingCycle, uint256 withdrawnAmount);

  function recordAddedBalanceFor(uint256 _projectId, uint256 _amount) external;

  function recordMigration(uint256 _projectId) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function setFor(uint256 _projectId, IJBToken _token) external;

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Global constants used across Juicebox contracts.
*/
library JBConstants {
  uint256 public constant MAX_RESERVED_RATE = 10_000;
  uint256 public constant MAX_REDEMPTION_RATE = 10_000;
  uint256 public constant MAX_DISCOUNT_RATE = 1_000_000_000;
  uint256 public constant SPLITS_TOTAL_PERCENT = 1_000_000_000;
  uint256 public constant MAX_FEE = 1_000_000_000;
  uint256 public constant MAX_FEE_DISCOUNT = 1_000_000_000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBCurrencies {
  uint256 public constant ETH = 1;
  uint256 public constant USD = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library JBFixedPointNumber {
  function adjustDecimals(
    uint256 _value,
    uint256 _decimals,
    uint256 _targetDecimals
  ) internal pure returns (uint256) {
    // If decimals need adjusting, multiply or divide the price by the decimal adjuster to get the normalized result.
    if (_targetDecimals == _decimals) return _value;
    else if (_targetDecimals > _decimals) return _value * 10**(_targetDecimals - _decimals);
    else return _value / 10**(_decimals - _targetDecimals);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGlobalFundingCycleMetadata.sol';
import './JBConstants.sol';
import './JBGlobalFundingCycleMetadataResolver.sol';

library JBFundingCycleMetadataResolver {
  function global(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (JBGlobalFundingCycleMetadata memory)
  {
    return JBGlobalFundingCycleMetadataResolver.expandMetadata(uint8(_fundingCycle.metadata >> 8));
  }

  function reservedRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint16(_fundingCycle.metadata >> 24));
  }

  function redemptionRate(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 40));
  }

  function ballotRedemptionRate(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (uint256)
  {
    // Redemption rate is a number 0-10000. It's inverse was stored so the most common case of 100% results in no storage needs.
    return JBConstants.MAX_REDEMPTION_RATE - uint256(uint16(_fundingCycle.metadata >> 56));
  }

  function payPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 72) & 1) == 1;
  }

  function distributionsPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 73) & 1) == 1;
  }

  function redeemPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 74) & 1) == 1;
  }

  function burnPaused(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 75) & 1) == 1;
  }

  function mintingAllowed(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 76) & 1) == 1;
  }

  function terminalMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 77) & 1) == 1;
  }

  function controllerMigrationAllowed(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 78) & 1) == 1;
  }

  function shouldHoldFees(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return ((_fundingCycle.metadata >> 79) & 1) == 1;
  }

  function preferClaimedTokenOverride(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 80) & 1) == 1;
  }

  function useTotalOverflowForRedemptions(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return ((_fundingCycle.metadata >> 81) & 1) == 1;
  }

  function useDataSourceForPay(JBFundingCycle memory _fundingCycle) internal pure returns (bool) {
    return (_fundingCycle.metadata >> 82) & 1 == 1;
  }

  function useDataSourceForRedeem(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (bool)
  {
    return (_fundingCycle.metadata >> 83) & 1 == 1;
  }

  function dataSource(JBFundingCycle memory _fundingCycle) internal pure returns (address) {
    return address(uint160(_fundingCycle.metadata >> 84));
  }

  function metadata(JBFundingCycle memory _fundingCycle) internal pure returns (uint256) {
    return uint256(uint8(_fundingCycle.metadata >> 244));
  }

  /**
    @notice
    Pack the funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleMetadata(JBFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // version 1 in the bits 0-7 (8 bits).
    packed = 1;
    // global metadta in bits 8-23 (16 bits).
    packed |=
      JBGlobalFundingCycleMetadataResolver.packFundingCycleGlobalMetadata(_metadata.global) <<
      8;
    // reserved rate in bits 24-39 (16 bits).
    packed |= _metadata.reservedRate << 24;
    // redemption rate in bits 40-55 (16 bits).
    // redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.redemptionRate) << 40;
    // ballot redemption rate rate in bits 56-71 (16 bits).
    // ballot redemption rate is a number 0-10000. Store the reverse so the most common case of 100% results in no storage needs.
    packed |= (JBConstants.MAX_REDEMPTION_RATE - _metadata.ballotRedemptionRate) << 56;
    // pause pay in bit 72.
    if (_metadata.pausePay) packed |= 1 << 72;
    // pause tap in bit 73.
    if (_metadata.pauseDistributions) packed |= 1 << 73;
    // pause redeem in bit 74.
    if (_metadata.pauseRedeem) packed |= 1 << 74;
    // pause burn in bit 75.
    if (_metadata.pauseBurn) packed |= 1 << 75;
    // allow minting in bit 76.
    if (_metadata.allowMinting) packed |= 1 << 76;
    // allow terminal migration in bit 77.
    if (_metadata.allowTerminalMigration) packed |= 1 << 77;
    // allow controller migration in bit 78.
    if (_metadata.allowControllerMigration) packed |= 1 << 78;
    // hold fees in bit 79.
    if (_metadata.holdFees) packed |= 1 << 79;
    // prefer claimed token override in bit 80.
    if (_metadata.preferClaimedTokenOverride) packed |= 1 << 80;
    // useTotalOverflowForRedemptions in bit 81.
    if (_metadata.useTotalOverflowForRedemptions) packed |= 1 << 81;
    // use pay data source in bit 82.
    if (_metadata.useDataSourceForPay) packed |= 1 << 82;
    // use redeem data source in bit 83.
    if (_metadata.useDataSourceForRedeem) packed |= 1 << 83;
    // data source address in bits 84-243.
    packed |= uint256(uint160(address(_metadata.dataSource))) << 84;
    // metadata in bits 244-252 (8 bits).
    packed |= _metadata.metadata << 244;
  }

  /**
    @notice
    Expand the funding cycle metadata.

    @param _fundingCycle The funding cycle having its metadata expanded.

    @return metadata The metadata object.
  */
  function expandMetadata(JBFundingCycle memory _fundingCycle)
    internal
    pure
    returns (JBFundingCycleMetadata memory)
  {
    return
      JBFundingCycleMetadata(
        global(_fundingCycle),
        reservedRate(_fundingCycle),
        redemptionRate(_fundingCycle),
        ballotRedemptionRate(_fundingCycle),
        payPaused(_fundingCycle),
        distributionsPaused(_fundingCycle),
        redeemPaused(_fundingCycle),
        burnPaused(_fundingCycle),
        mintingAllowed(_fundingCycle),
        terminalMigrationAllowed(_fundingCycle),
        controllerMigrationAllowed(_fundingCycle),
        shouldHoldFees(_fundingCycle),
        preferClaimedTokenOverride(_fundingCycle),
        useTotalOverflowForRedemptions(_fundingCycle),
        useDataSourceForPay(_fundingCycle),
        useDataSourceForRedeem(_fundingCycle),
        dataSource(_fundingCycle),
        metadata(_fundingCycle)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBFundingCycleMetadata.sol';

library JBGlobalFundingCycleMetadataResolver {
  function setTerminalsAllowed(uint8 _data) internal pure returns (bool) {
    return (_data & 1) == 1;
  }

  function setControllerAllowed(uint8 _data) internal pure returns (bool) {
    return ((_data >> 1) & 1) == 1;
  }

  function transfersPaused(uint8 _data) internal pure returns (bool) {
    return ((_data >> 2) & 1) == 1;
  }

  /**
    @notice
    Pack the global funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all global metadata params. The first 8 bits specify the version.
  */
  function packFundingCycleGlobalMetadata(JBGlobalFundingCycleMetadata memory _metadata)
    internal
    pure
    returns (uint256 packed)
  {
    // allow set terminals in bit 0.
    if (_metadata.allowSetTerminals) packed |= 1;
    // allow set controller in bit 1.
    if (_metadata.allowSetController) packed |= 1 << 1;
    // pause transfers in bit 2.
    if (_metadata.pauseTransfers) packed |= 1 << 2;
  }

  /**
    @notice
    Expand the global funding cycle metadata.

    @param _packedMetadata The packed metadata to expand.

    @return metadata The global metadata object.
  */
  function expandMetadata(uint8 _packedMetadata)
    internal
    pure
    returns (JBGlobalFundingCycleMetadata memory metadata)
  {
    return
      JBGlobalFundingCycleMetadata(
        setTerminalsAllowed(_packedMetadata),
        setControllerAllowed(_packedMetadata),
        transfersPaused(_packedMetadata)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBOperations {
  uint256 public constant RECONFIGURE = 1;
  uint256 public constant REDEEM = 2;
  uint256 public constant MIGRATE_CONTROLLER = 3;
  uint256 public constant MIGRATE_TERMINAL = 4;
  uint256 public constant PROCESS_FEES = 5;
  uint256 public constant SET_METADATA = 6;
  uint256 public constant ISSUE = 7;
  uint256 public constant SET_TOKEN = 8;
  uint256 public constant MINT = 9;
  uint256 public constant BURN = 10;
  uint256 public constant CLAIM = 11;
  uint256 public constant TRANSFER = 12;
  uint256 public constant REQUIRE_CLAIM = 13; // unused in v3
  uint256 public constant SET_CONTROLLER = 14;
  uint256 public constant SET_TERMINALS = 15;
  uint256 public constant SET_PRIMARY_TERMINAL = 16;
  uint256 public constant USE_ALLOWANCE = 17;
  uint256 public constant SET_SPLITS = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBSplitsGroups {
  uint256 public constant ETH_PAYOUT = 1;
  uint256 public constant RESERVED_TOKENS = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBTokens {
  /** 
    @notice 
    The ETH token address in Juicebox is represented by 0x000000000000000000000000000000000000EEEe.
  */
  address public constant ETH = address(0x000000000000000000000000000000000000EEEe);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member payer The address from which the payment originated.
  @member projectId The ID of the project for which the payment was made.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the payment is being made.
  @member amount The amount of the payment. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member projectTokenCount The number of project tokens minted for the beneficiary.
  @member beneficiary The address to which the tokens were minted.
  @member preferClaimedTokens A flag indicating whether the request prefered to mint project tokens into the beneficiaries wallet rather than leaving them unclaimed. This is only possible if the project has an attached token contract.
  @member memo The memo that is being emitted alongside the payment.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidPayData {
  address payer;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  JBTokenAmount amount;
  JBTokenAmount forwardedAmount;
  uint256 projectTokenCount;
  address beneficiary;
  bool preferClaimedTokens;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBTokenAmount.sol';

/** 
  @member holder The holder of the tokens being redeemed.
  @member projectId The ID of the project with which the redeemed tokens are associated.
  @member currentFundingCycleConfiguration The configuration of the funding cycle during which the redemption is being made.
  @member projectTokenCount The number of project tokens being redeemed.
  @member reclaimedAmount The amount reclaimed from the treasury. Includes the token being reclaimed, the value, the number of decimals included, and the currency of the amount.
  @member forwardedAmount The amount of the payment that is being sent to the delegate. Includes the token being paid, the value, the number of decimals included, and the currency of the amount.
  @member beneficiary The address to which the reclaimed amount will be sent.
  @member memo The memo that is being emitted alongside the redemption.
  @member metadata Extra data to send to the delegate.
*/
struct JBDidRedeemData {
  address holder;
  uint256 projectId;
  uint256 currentFundingCycleConfiguration;
  uint256 projectTokenCount;
  JBTokenAmount reclaimedAmount;
  JBTokenAmount forwardedAmount;
  address payable beneficiary;
  string memo;
  bytes metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member amount The total amount the fee was taken from, as a fixed point number with the same number of decimals as the terminal in which this struct was created.
  @member fee The percent of the fee, out of MAX_FEE.
  @member feeDiscount The discount of the fee.
  @member beneficiary The address that will receive the tokens that are minted as a result of the fee payment.
*/
struct JBFee {
  uint256 amount;
  uint32 fee;
  uint32 feeDiscount;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';

/** 
  @member terminal The terminal within which the distribution limit and the overflow allowance applies.
  @member token The token for which the fund access constraints apply.
  @member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  @member distributionLimitCurrency The currency of the distribution limit.
  @member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  @member overflowAllowanceCurrency The currency of the overflow allowance.
*/
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
*/
struct JBFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
  @member pauseTransfers A flag indicating if the project token transfer functionality should be paused during the funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
  bool pauseTransfers;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct JBOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBPayDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBPayDelegateAllocation {
  IJBPayDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IJBRedemptionDelegate.sol';

/** 
 @member delegate A delegate contract to use for subsequent calls.
 @member amount The amount to send to the delegate.
*/
struct JBRedemptionDelegateAllocation {
  IJBRedemptionDelegate delegate;
  uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* 
  @member token The token the payment was made in.
  @member value The amount of tokens that was paid, as a fixed point number.
  @member decimals The number of decimals included in the value fixed point number.
  @member currency The expected currency of the value.
**/
struct JBTokenAmount {
  address token;
  uint256 value;
  uint256 decimals;
  uint256 currency;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}