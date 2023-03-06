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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.14;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { FlowMatchExecutorTypes } from "../libs/FlowMatchExecutorTypes.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { SignatureChecker } from "../libs/SignatureChecker.sol";
import { IFlowExchange } from "../interfaces/IFlowExchange.sol";

/**
@title FlowMatchExecutor
@author Joe
@notice The contract that is called to execute order matches
*/
contract FlowMatchExecutor is
    IERC1271,
    IERC721Receiver,
    Ownable,
    Pausable,
    SignatureChecker
{
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    IFlowExchange public immutable exchange;
    IERC20 public immutable weth;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
      //////////////////////////////////////////////////////////////*/
    event InitiatorChanged(address indexed oldVal, address indexed newVal);

    ///@notice admin events
    event ETHWithdrawn(address indexed destination, uint256 amount);
    event ERC20Withdrawn(
        address indexed destination,
        address indexed currency,
        uint256 amount
    );

    address public initiator;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier netNonNegative() {
        uint256 initialBalance = address(this).balance +
            weth.balanceOf(address(this));
        _;
        uint256 finalBalance = address(this).balance +
            weth.balanceOf(address(this));

        require(
            finalBalance >= initialBalance,
            "Transaction not non-negative"
        );
    }

    modifier onlyInitiator() {
        require(msg.sender == initiator, "only initiator can call");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IFlowExchange _exchange, address _initiator, address _weth) {
        exchange = _exchange;
        initiator = _initiator;
        weth = IERC20(_weth);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    ///////////////////////////////////////////////// OVERRIDES ///////////////////////////////////////////////////////

    // returns the magic value if the message is signed by the owner of this contract, invalid value otherwise
    function isValidSignature(
        bytes32 message,
        bytes calldata signature
    ) external view override returns (bytes4) {
        _assertValidSignatureHelper(initiator, message, signature);
        return 0x1626ba7e; // EIP-1271 magic value
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    ///////////////////////////////////////////////// EXTERNAL FUNCTIONS ///////////////////////////////////////////////////////

    /**
     * @notice The entry point for executing brokerage matches. Callable only by owner
     * @param batches The batches of calls to make
     */
    function executeBrokerMatches(
        FlowMatchExecutorTypes.Batch[] calldata batches
    ) external whenNotPaused onlyInitiator netNonNegative {
        uint256 numBatches = batches.length;
        for (uint256 i; i < numBatches; ) {
            _broker(batches[i].externalFulfillments);
            _matchOrders(batches[i].matches);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice The entry point for executing native matches. Callable only by owner
     * @param matches The matches to make
     */
    function executeNativeMatches(
        FlowMatchExecutorTypes.MatchOrders[] calldata matches
    ) external whenNotPaused onlyInitiator netNonNegative {
        _matchOrders(matches);
    }

    //////////////////////////////////////////////////// INTERNAL FUNCTIONS ///////////////////////////////////////////////////////

    /**
     * @notice broker a trade by fulfilling orders on other exchanges and transferring nfts to the intermediary
     * @param externalFulfillments The specification of the external calls to make and nfts to transfer
     */
    function _broker(
        FlowMatchExecutorTypes.ExternalFulfillments
            calldata externalFulfillments
    ) internal {
        uint256 numCalls = externalFulfillments.calls.length;
        if (numCalls > 0) {
            for (uint256 i; i < numCalls; ) {
                _call(externalFulfillments.calls[i]);
                unchecked {
                    ++i;
                }
            }
        }

        uint256 numNftsToTransfer = externalFulfillments.nftsToTransfer.length;
        if (numNftsToTransfer > 0) {
            for (uint256 i; i < numNftsToTransfer; ) {
                bool isApproved = IERC721(
                    externalFulfillments.nftsToTransfer[i].collection
                ).isApprovedForAll(address(this), address(exchange));

                if (!isApproved) {
                    IERC721(externalFulfillments.nftsToTransfer[i].collection)
                        .setApprovalForAll(address(exchange), true);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Execute a call to the specified contract
     * @param params The call to execute
     */
    function _call(
        FlowMatchExecutorTypes.Call memory params
    ) internal returns (bytes memory) {
        (bool _success, bytes memory _result) = params.to.call{
            value: params.value
        }(params.data);
        require(_success, "external call failed");
        return _result;
    }

    /**
     * @notice Function called to execute a batch of matches by calling the exchange contract
     * @param matches The batch of matches to execute on the exchange
     */
    function _matchOrders(
        FlowMatchExecutorTypes.MatchOrders[] calldata matches
    ) internal {
        uint256 numMatches = matches.length;
        if (numMatches > 0) {
            for (uint256 i; i < numMatches; ) {
                FlowMatchExecutorTypes.MatchOrdersType matchType = matches[i]
                    .matchType;
                if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToOneSpecific
                ) {
                    exchange.matchOneToOneOrders(
                        matches[i].buys,
                        matches[i].sells
                    );
                } else if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToOneUnspecific
                ) {
                    exchange.matchOrders(
                        matches[i].sells,
                        matches[i].buys,
                        matches[i].constructs
                    );
                } else if (
                    matchType ==
                    FlowMatchExecutorTypes.MatchOrdersType.OneToMany
                ) {
                    if (matches[i].buys.length == 1) {
                        exchange.matchOneToManyOrders(
                            matches[i].buys[0],
                            matches[i].sells
                        );
                    } else if (matches[i].sells.length == 1) {
                        exchange.matchOneToManyOrders(
                            matches[i].sells[0],
                            matches[i].buys
                        );
                    } else {
                        revert("invalid one to many order");
                    }
                } else {
                    revert("invalid match type");
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    //////////////////////////////////////////////////// ADMIN FUNCTIONS ///////////////////////////////////////////////////////

    function withdrawETH(address destination) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = destination.call{ value: amount }("");
        require(sent, "failed");
        emit ETHWithdrawn(destination, amount);
    }

    /// @dev Used for withdrawing exchange fees paid to the contract in ERC20 tokens
    function withdrawTokens(
        address destination,
        address currency,
        uint256 amount
    ) external onlyOwner {
        IERC20(currency).transfer(destination, amount);
        emit ERC20Withdrawn(destination, currency, amount);
    }

    function updateInitiator(address _initiator) external onlyOwner {
        address oldVal = initiator;
        initiator = _initiator;
        emit InitiatorChanged(oldVal, _initiator);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { OrderTypes } from "../libs/OrderTypes.sol";

/**
 * @title IFlowExchange
 * @author Joe
 * @notice Exchange interface that must be implemented by the Flow Exchange
 */
interface IFlowExchange {
    function matchOneToOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders1,
        OrderTypes.MakerOrder[] calldata makerOrders2
    ) external;

    function matchOneToManyOrders(
        OrderTypes.MakerOrder calldata makerOrder,
        OrderTypes.MakerOrder[] calldata manyMakerOrders
    ) external;

    function matchOrders(
        OrderTypes.MakerOrder[] calldata sells,
        OrderTypes.MakerOrder[] calldata buys,
        OrderTypes.OrderItem[][] calldata constructs
    ) external;

    function takeMultipleOneOrders(
        OrderTypes.MakerOrder[] calldata makerOrders
    ) external payable;

    function takeOrders(
        OrderTypes.MakerOrder[] calldata makerOrders,
        OrderTypes.OrderItem[][] calldata takerNfts
    ) external payable;

    function transferMultipleNFTs(
        address to,
        OrderTypes.OrderItem[] calldata items
    ) external;

    function cancelAllOrders(uint256 minNonce) external;

    function cancelMultipleOrders(uint256[] calldata orderNonces) external;

    function isNonceValid(
        address user,
        uint256 nonce
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant OneWord = 0x20;
uint256 constant OneWordShift = 0x5;
uint256 constant ThirtyOneBytes = 0x1f;
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant BulkOrder_Typehash_Height_One = (
    0x25f1d312acdce9bb5f11c5585e941709b8456695fe5aacf9998bd3acadfd7fec
);
uint256 constant BulkOrder_Typehash_Height_Two = (
    0xb7870d22600c57d01e7ff46f87ea8741898e43ce73f7d5bfb269c715ea8d4242
);
uint256 constant BulkOrder_Typehash_Height_Three = (
    0xe9ccc656222762d6d2e94ef74311f23818493f907cde851440e6d8773f56c5fe
);
uint256 constant BulkOrder_Typehash_Height_Four = (
    0x14300c4bb2d1850e661a7bb2347e8ac0fa0736fa434a6d0ae1017cb485ce1a7c
);
uint256 constant BulkOrder_Typehash_Height_Five = (
    0xd2a9fdbc6e34ad83660cd4ad49310a663134bbdaea7c34c7c6a95cf9aa8618b1
);
uint256 constant BulkOrder_Typehash_Height_Six = (
    0x4c2c782f8c9daf12d0ec87e76fc496ffeed835292ca7ff04ac92375bbc0f4cc7
);
uint256 constant BulkOrder_Typehash_Height_Seven = (
    0xab5bd2a739337f6f3d8743b51df07f176805bae22da4b25be5d8cdd688498382
);
uint256 constant BulkOrder_Typehash_Height_Eight = (
    0x96596fb6c680230945bae686c1776a9920c438436a98dba61ca767f370b6ef0c
);
uint256 constant BulkOrder_Typehash_Height_Nine = (
    0x40d250b9c55bcc275a49429cae143a873752d755dfa1072e47e10d5252fb8d3b
);
uint256 constant BulkOrder_Typehash_Height_Ten = (
    0xeaf49b43e05b65ffed9bd664ee39555b22fa8ba157aa058f19fc7fee92d386f4
);
uint256 constant BulkOrder_Typehash_Height_Eleven = (
    0x9d5d1c872408322fe8c431a1b66583d09e5dd77e0ac5f99b55131b3fe8363ffb
);
uint256 constant BulkOrder_Typehash_Height_Twelve = (
    0xdb50e721ad63671fc79a925f372d22d69adfe998243b341129c4ef29a20c7a74
);
uint256 constant BulkOrder_Typehash_Height_Thirteen = (
    0x908c5a945faf8d6b1d5aba44fc097fb8c22cca14f60bf75bf680224813809637
);
uint256 constant BulkOrder_Typehash_Height_Fourteen = (
    0x7968127d641eabf208fbdc9d69f10fed718855c94a809679d41b7bcf18104b74
);
uint256 constant BulkOrder_Typehash_Height_Fifteen = (
    0x814b44e912b2ccd234edcf03da0b9d37c459baf9d512034ed96bc93032c37bab
);
uint256 constant BulkOrder_Typehash_Height_Sixteen = (
    0x3a8ceb52e9851a307cf6bd49c73a2ec0d37712e6c4d68c4dcf84df0ad574f59a
);
uint256 constant BulkOrder_Typehash_Height_Seventeen = (
    0xdd2197b5843051f931afa0a534e25a1d824e11ccb5e100c716e9e40406c68b3a
);
uint256 constant BulkOrder_Typehash_Height_Eighteen = (
    0x84b50d02c0d7ec2a815ec27a71290ad861c7cd3addd94f5f7c0736df33fe1827
);
uint256 constant BulkOrder_Typehash_Height_Nineteen = (
    0xdaa31608975cb535532462ce63bbb075b6d81235cd756da2117e745baed067c1
);
uint256 constant BulkOrder_Typehash_Height_Twenty = (
    0x5089f7eef268ce27189a0f19e64dd8210ecadff4be5176a5bd4fd1f176f483a1
);
uint256 constant BulkOrder_Typehash_Height_TwentyOne = (
    0x907e1899005168c54e8279a0e7fc8f890b1de622a79e1ea1447bde837732da56
);
uint256 constant BulkOrder_Typehash_Height_TwentyTwo = (
    0x73ea6321c43a7d88f2d0f797219c7dd3405b1208e89c6d00c6df5c2cc833aa1d
);
uint256 constant BulkOrder_Typehash_Height_TwentyThree = (
    0xb2036d7869c41d1588416aba4ce6e52b45a330fd934c05995b14653db5db9293
);
uint256 constant BulkOrder_Typehash_Height_TwentyFour = (
    0x99e8d8ff7ddc6198258cce0fe5930c7fe7799405517eca81dbf14c1707c163ad
);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { OrderTypes } from "./OrderTypes.sol";

/**
 * @title FlowMatchExecutorTyoes
 * @author Joe
 * @notice This library contains the match executor types
 */
library FlowMatchExecutorTypes {
    struct Call {
        bytes data;
        uint256 value;
        address payable to;
    }

    struct ExternalFulfillments {
        Call[] calls;
        OrderTypes.OrderItem[] nftsToTransfer;
    }

    enum MatchOrdersType {
        OneToOneSpecific,
        OneToOneUnspecific,
        OneToMany
    }

    struct MatchOrders {
        OrderTypes.MakerOrder[] buys;
        OrderTypes.MakerOrder[] sells;
        OrderTypes.OrderItem[][] constructs;
        MatchOrdersType matchType;
    }

    struct Batch {
        ExternalFulfillments externalFulfillments;
        MatchOrders[] matches;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { CostPerWord, ExtraGasBuffer, FreeMemoryPointerSlot, MemoryExpansionCoefficientShift, OneWord, OneWordShift, ThirtyOneBytes } from "./Constants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
    /**
     * @dev Internal view function to revert and pass along the revert reason if
     *      data was returned by the last call and that the size of that data
     *      does not exceed the currently allocated memory size.
     */
    function _revertWithReasonIfOneIsReturned() internal view {
        assembly {
            // If it returned a message, bubble it up as long as sufficient gas
            // remains to do so:
            if returndatasize() {
                // Ensure that sufficient gas is available to copy returndata
                // while expanding memory where necessary. Start by computing
                // the word size of returndata and allocated memory.
                let returnDataWords := shr(
                    OneWordShift,
                    add(returndatasize(), ThirtyOneBytes)
                )

                // Note: use the free memory pointer in place of msize() to work
                // around a Yul warning that prevents accessing msize directly
                // when the IR pipeline is activated.
                let msizeWords := shr(
                    OneWordShift,
                    mload(FreeMemoryPointerSlot)
                )

                // Next, compute the cost of the returndatacopy.
                let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                if gt(returnDataWords, msizeWords) {
                    cost := add(
                        cost,
                        add(
                            mul(sub(returnDataWords, msizeWords), CostPerWord),
                            shr(
                                MemoryExpansionCoefficientShift,
                                sub(
                                    mul(returnDataWords, returnDataWords),
                                    mul(msizeWords, msizeWords)
                                )
                            )
                        )
                    )
                }

                // Finally, add a small constant and compare to gas remaining;
                // bubble up the revert data if enough gas is still available.
                if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                    returndatacopy(0, 0, returndatasize())

                    // Revert, specifying memory region with copied returndata.
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @dev Internal view function to branchlessly select either the caller (if
     *      a supplied recipient is equal to zero) or the supplied recipient (if
     *      that recipient is a nonzero value).
     *
     * @param recipient The supplied recipient.
     *
     * @return updatedRecipient The updated recipient.
     */
    function _substituteCallerForEmptyRecipient(
        address recipient
    ) internal view returns (address updatedRecipient) {
        // Utilize assembly to perform a branchless operation on the recipient.
        assembly {
            // Add caller to recipient if recipient equals 0; otherwise add 0.
            updatedRecipient := add(recipient, mul(iszero(recipient), caller()))
        }
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }

    /**
     * @dev Internal pure function to compare two addresses without first
     *      masking them. Note that dirty upper bits will cause otherwise equal
     *      addresses to be recognized as unequal.
     *
     * @param a The first address.
     * @param b The second address
     *
     * @return areEqual A boolean representing whether the addresses are equal.
     */
    function _unmaskedAddressComparison(
        address a,
        address b
    ) internal pure returns (bool areEqual) {
        // Utilize assembly to perform the comparison without masking.
        assembly {
            areEqual := eq(a, b)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title OrderTypes
 * @author nneverlander. Twitter @nneverlander
 * @notice This library contains the order types used by the main exchange and complications
 */
library OrderTypes {
    /// @dev the tokenId and numTokens (==1 for ERC721)
    struct TokenInfo {
        uint256 tokenId;
        uint256 numTokens;
    }

    /// @dev an order item is a collection address and tokens from that collection
    struct OrderItem {
        address collection;
        TokenInfo[] tokens;
    }

    struct MakerOrder {
        ///@dev is order sell or buy
        bool isSellOrder;
        ///@dev signer of the order (maker address)
        address signer;
        ///@dev Constraints array contains the order constraints. Total constraints: 7. In order:
        // numItems - min (for buy orders) / max (for sell orders) number of items in the order
        // start price in wei
        // end price in wei
        // start time in block.timestamp
        // end time in block.timestamp
        // nonce of the order
        // max tx.gasprice in wei that a user is willing to pay for gas
        // 1 for trustedExecution, 0 or non-existent for not trustedExecution
        uint256[] constraints;
        ///@dev nfts array contains order items where each item is a collection and its tokenIds
        OrderItem[] nfts;
        ///@dev address of complication for trade execution (e.g. FlowOrderBookComplication), address of the currency (e.g., WETH)
        address[] execParams;
        ///@dev additional parameters like traits for trait orders, private sale buyer for OTC orders etc
        bytes extraParams;
        ///@dev the order signature uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
        bytes sig;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.8.14;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { LowLevelHelpers } from "./LowLevelHelpers.sol";

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { OrderTypes } from "../libs/OrderTypes.sol";
import { EIP2098_allButHighestBitMask, OneWord, OneWordShift, BulkOrder_Typehash_Height_One, BulkOrder_Typehash_Height_Two, BulkOrder_Typehash_Height_Three, BulkOrder_Typehash_Height_Four, BulkOrder_Typehash_Height_Five, BulkOrder_Typehash_Height_Six, BulkOrder_Typehash_Height_Seven, BulkOrder_Typehash_Height_Eight, BulkOrder_Typehash_Height_Nine, BulkOrder_Typehash_Height_Ten, BulkOrder_Typehash_Height_Eleven, BulkOrder_Typehash_Height_Twelve, BulkOrder_Typehash_Height_Thirteen, BulkOrder_Typehash_Height_Fourteen, BulkOrder_Typehash_Height_Fifteen, BulkOrder_Typehash_Height_Sixteen, BulkOrder_Typehash_Height_Seventeen, BulkOrder_Typehash_Height_Eighteen, BulkOrder_Typehash_Height_Nineteen, BulkOrder_Typehash_Height_Twenty, BulkOrder_Typehash_Height_TwentyOne, BulkOrder_Typehash_Height_TwentyTwo, BulkOrder_Typehash_Height_TwentyThree, BulkOrder_Typehash_Height_TwentyFour } from "./Constants.sol";

/**
 * @title SignatureChecker
 * @notice This contract allows verification of signatures for both EOAs and contracts
 */
contract SignatureChecker is LowLevelHelpers {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();

    /**
     * @notice Returns whether the signer matches the signed message
     * @param orderHash the hash containing the signed message
     * @param signer the signer address to confirm message validity
     * @param sig the signature
     * @param domainSeparator parameter to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 orderHash,
        address signer,
        bytes calldata sig,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        bytes32 originalDigest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, orderHash)
        );
        bytes32 digest;

        bytes memory extractedSignature;
        if (_isValidBulkOrderSize(sig)) {
            (orderHash, extractedSignature) = _computeBulkOrderProof(
                sig,
                orderHash
            );
            digest = keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, orderHash)
            );
        } else {
            digest = originalDigest;
            extractedSignature = sig;
        }

        _assertValidSignature(
            signer,
            digest,
            originalDigest,
            sig,
            extractedSignature
        );

        return true;
    }

    /**
     * @dev Determines whether the specified bulk order size is valid.
     *
     * @param signature The signature of the bulk order to check.
     *
     * @return validLength True if bulk order size is valid, false otherwise.
     */
    function _isValidBulkOrderSize(
        bytes memory signature
    ) internal pure returns (bool validLength) {
        validLength =
            signature.length < 837 &&
            signature.length > 98 &&
            ((signature.length - 67) % 32) < 2;
    }

    /**
     * @dev Computes the bulk order hash for the specified proof and leaf. Note
     *      that if an index that exceeds the number of orders in the bulk order
     *      payload will instead "wrap around" and refer to an earlier index.
     *
     * @param proofAndSignature The proof and signature of the bulk order.
     * @param leaf              The leaf of the bulk order tree.
     *
     * @return bulkOrderHash The bulk order hash.
     * @return signature     The signature of the bulk order.
     */
    function _computeBulkOrderProof(
        bytes memory proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash, bytes memory signature) {
        bytes32 root = leaf;

        // proofAndSignature with odd length is a compact signature (64 bytes).
        uint256 length = proofAndSignature.length % 2 == 0 ? 65 : 64;

        // Create a new array of bytes equal to the length of the signature.
        signature = new bytes(length);

        // Iterate over each byte in the signature.
        for (uint256 i = 0; i < length; ++i) {
            // Assign the byte from the proofAndSignature to the signature.
            signature[i] = proofAndSignature[i];
        }

        // Compute the key by extracting the next three bytes from the
        // proofAndSignature.
        uint256 key = (((uint256(uint8(proofAndSignature[length])) << 16) |
            ((uint256(uint8(proofAndSignature[length + 1]))) << 8)) |
            (uint256(uint8(proofAndSignature[length + 2]))));

        uint256 height = (proofAndSignature.length - length) / 32;

        // Create an array of bytes32 to hold the proof elements.
        bytes32[] memory proofElements = new bytes32[](height);

        // Iterate over each proof element.
        for (uint256 elementIndex = 0; elementIndex < height; ++elementIndex) {
            // Compute the starting index for the current proof element.
            uint256 start = (length + 3) + (elementIndex * 32);

            // Create a new array of bytes to hold the current proof element.
            bytes memory buffer = new bytes(32);

            // Iterate over each byte in the proof element.
            for (uint256 i = 0; i < 32; ++i) {
                // Assign the byte from the proofAndSignature to the buffer.
                buffer[i] = proofAndSignature[start + i];
            }

            // Decode the current proof element from the buffer and assign it to
            // the proofElements array.
            proofElements[elementIndex] = abi.decode(buffer, (bytes32));
        }

        // Iterate over each proof element.
        for (uint256 i = 0; i < proofElements.length; ++i) {
            // Retrieve the proof element.
            bytes32 proofElement = proofElements[i];

            // Check if the current bit of the key is set.
            if ((key >> i) % 2 == 0) {
                // If the current bit is not set, then concatenate the root and
                // the proof element, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(root, proofElement));
            } else {
                // If the current bit is set, then concatenate the proof element
                // and the root, and compute the keccak256 hash of the
                // concatenation to assign it to the root.
                root = keccak256(abi.encodePacked(proofElement, root));
            }
        }

        // Compute the bulk order hash and return it.
        bulkOrderHash = keccak256(
            abi.encodePacked(_lookupBulkOrderTypehash(height), root)
        );

        // Return the signature.
        return (bulkOrderHash, signature);
    }

    /**
     * @dev Internal pure function to look up one of twenty-four potential bulk
     *      order typehash constants based on the height of the bulk order tree.
     *      Note that values between one and twenty-four are supported, which is
     *      enforced by _isValidBulkOrderSize.
     *
     * @param _treeHeight The height of the bulk order tree. The value must be
     *                    between one and twenty-four.
     *
     * @return _typeHash The EIP-712 typehash for the bulk order type with the
     *                   given height.
     */
    function _lookupBulkOrderTypehash(
        uint256 _treeHeight
    ) internal pure returns (bytes32 _typeHash) {
        // Utilize assembly to efficiently retrieve correct bulk order typehash.
        assembly {
            // Use a Yul function to enable use of the `leave` keyword
            // to stop searching once the appropriate type hash is found.
            function lookupTypeHash(treeHeight) -> typeHash {
                // Handle tree heights one through eight.
                if lt(treeHeight, 9) {
                    // Handle tree heights one through four.
                    if lt(treeHeight, 5) {
                        // Handle tree heights one and two.
                        if lt(treeHeight, 3) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 1),
                                BulkOrder_Typehash_Height_One,
                                BulkOrder_Typehash_Height_Two
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height three and four via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 3),
                            BulkOrder_Typehash_Height_Three,
                            BulkOrder_Typehash_Height_Four
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height five and six.
                    if lt(treeHeight, 7) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 5),
                            BulkOrder_Typehash_Height_Five,
                            BulkOrder_Typehash_Height_Six
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height seven and eight via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 7),
                        BulkOrder_Typehash_Height_Seven,
                        BulkOrder_Typehash_Height_Eight
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height nine through sixteen.
                if lt(treeHeight, 17) {
                    // Handle tree height nine through twelve.
                    if lt(treeHeight, 13) {
                        // Handle tree height nine and ten.
                        if lt(treeHeight, 11) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 9),
                                BulkOrder_Typehash_Height_Nine,
                                BulkOrder_Typehash_Height_Ten
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height eleven and twelve via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 11),
                            BulkOrder_Typehash_Height_Eleven,
                            BulkOrder_Typehash_Height_Twelve
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height thirteen and fourteen.
                    if lt(treeHeight, 15) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 13),
                            BulkOrder_Typehash_Height_Thirteen,
                            BulkOrder_Typehash_Height_Fourteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }
                    // Handle height fifteen and sixteen via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 15),
                        BulkOrder_Typehash_Height_Fifteen,
                        BulkOrder_Typehash_Height_Sixteen
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height seventeen through twenty.
                if lt(treeHeight, 21) {
                    // Handle tree height seventeen and eighteen.
                    if lt(treeHeight, 19) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 17),
                            BulkOrder_Typehash_Height_Seventeen,
                            BulkOrder_Typehash_Height_Eighteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height nineteen and twenty via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 19),
                        BulkOrder_Typehash_Height_Nineteen,
                        BulkOrder_Typehash_Height_Twenty
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height twenty-one and twenty-two.
                if lt(treeHeight, 23) {
                    // Utilize branchless logic to determine typehash.
                    typeHash := ternary(
                        eq(treeHeight, 21),
                        BulkOrder_Typehash_Height_TwentyOne,
                        BulkOrder_Typehash_Height_TwentyTwo
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle height twenty-three & twenty-four w/ branchless logic.
                typeHash := ternary(
                    eq(treeHeight, 23),
                    BulkOrder_Typehash_Height_TwentyThree,
                    BulkOrder_Typehash_Height_TwentyFour
                )

                // Exit the function once typehash has been located.
                leave
            }

            // Implement ternary conditional using branchless logic.
            function ternary(cond, ifTrue, ifFalse) -> c {
                c := xor(ifFalse, mul(cond, xor(ifFalse, ifTrue)))
            }

            // Look up the typehash using the supplied tree height.
            _typeHash := lookupTypeHash(_treeHeight)
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer            The signer for the order.
     * @param digest            The digest to verify signature against.
     * @param originalDigest    The original digest to verify signature against.
     * @param originalSignature The original signature.
     * @param signature         A signature from the signer indicating that the
     *                          order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        bytes memory originalSignature,
        bytes memory signature
    ) internal view {
        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            if (
                IERC1271(signer).isValidSignature(
                    originalDigest,
                    originalSignature
                ) != 0x1626ba7e
            ) {
                revert BadContractSignature();
            }

            // Return early if the ERC-1271 signature check succeeded.
            return;
        } else {
            _assertValidSignatureHelper(signer, digest, signature);
        }
    }

    function _assertValidSignatureHelper(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal pure {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 sig. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            // Decode signature into r, vs.
            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            // Decompose vs into s and v.
            s = vs & EIP2098_allButHighestBitMask;

            // If the highest bit is set, v = 28, otherwise v = 27.
            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
        }
    }
}