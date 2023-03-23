// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ExecuteArgs, TransferInfo, DestinationTransferStatus} from "../libraries/LibConnextStorage.sol";
import {TokenId} from "../libraries/TokenId.sol";

interface IConnext {

  // ============ BRIDGE ==============

  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);

  function xcallIntoLocal(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  ) external payable returns (bytes32);

  function execute(ExecuteArgs calldata _args) external returns (bytes32 transferId);

  function forceUpdateSlippage(TransferInfo calldata _params, uint256 _slippage) external;

  function forceReceiveLocal(TransferInfo calldata _params) external;

  function bumpTransfer(bytes32 _transferId) external payable;

  function routedTransfers(bytes32 _transferId) external view returns (address[] memory);

  function transferStatus(bytes32 _transferId) external view returns (DestinationTransferStatus);

  function remote(uint32 _domain) external view returns (address);

  function domain() external view returns (uint256);

  function nonce() external view returns (uint256);

  function approvedSequencers(address _sequencer) external view returns (bool);

  function xAppConnectionManager() external view returns (address);

  // ============ ROUTERS ==============

  function LIQUIDITY_FEE_NUMERATOR() external view returns (uint256);

  function LIQUIDITY_FEE_DENOMINATOR() external view returns (uint256);

  function getRouterApproval(address _router) external view returns (bool);

  function getRouterRecipient(address _router) external view returns (address);

  function getRouterOwner(address _router) external view returns (address);

  function getProposedRouterOwner(address _router) external view returns (address);

  function getProposedRouterOwnerTimestamp(address _router) external view returns (uint256);

  function maxRoutersPerTransfer() external view returns (uint256);

  function routerBalances(address _router, address _asset) external view returns (uint256);

  function getRouterApprovalForPortal(address _router) external view returns (bool);

  function initializeRouter(address _owner, address _recipient) external;

  function setRouterRecipient(address _router, address _recipient) external;

  function proposeRouterOwner(address _router, address _proposed) external;

  function acceptProposedRouterOwner(address _router) external;

  function addRouterLiquidityFor(
    uint256 _amount,
    address _local,
    address _router
  ) external payable;

  function addRouterLiquidity(uint256 _amount, address _local) external payable;

  function removeRouterLiquidityFor(
    TokenId memory _canonical,
    uint256 _amount,
    address payable _to,
    address _router
  ) external;

  function removeRouterLiquidity(TokenId memory _canonical, uint256 _amount, address payable _to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @notice Enum representing status of destination transfer
 * @dev Status is only assigned on the destination domain, will always be "none" for the
 * origin domains
 * @return uint - Index of value in enum
 */
enum DestinationTransferStatus {
  None, // 0
  Reconciled, // 1
  Executed, // 2
  Completed // 3 - executed + reconciled
}

/**
 * @notice These are the parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 *
 * @param originDomain - The originating domain (i.e. where `xcall` is called)
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called)\
 * @param canonicalDomain - The canonical domain of the asset you are bridging
 * @param to - The address you are sending funds (and potentially data) to
 * @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param receiveLocal - If true, will use the local asset on the destination instead of adopted.
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
 * a user takes 1% slippage, this is expressed as 1_000)
 * @param originSender - The msg.sender of the xcall
 * @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
 * @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
 * @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
 * @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
 */
struct TransferInfo {
  uint32 originDomain;
  uint32 destinationDomain;
  uint32 canonicalDomain;
  address to;
  address delegate;
  bool receiveLocal;
  bytes callData;
  uint256 slippage;
  address originSender;
  uint256 bridgedAmt;
  uint256 normalizedIn;
  uint256 nonce;
  bytes32 canonicalId;
}

/**
 * @notice
 * @param params - The TransferInfo. These are consistent across sending and receiving chains.
 * @param routers - The routers who you are sending the funds on behalf of.
 * @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
 * for the signed transfer ID.
 * @param sequencer - The sequencer who assigned the router path to this transfer.
 * @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
 * for the path that was signed.
 */
struct ExecuteArgs {
  TransferInfo params;
  address[] routers;
  bytes[] routerSignatures;
  address sequencer;
  bytes sequencerSignature;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.17;

// ============= Structs =============

// Tokens are identified by a TokenId:
// domain - 4 byte chain ID of the chain from which the token originates
// id - 32 byte identifier of the token address on the origin chain, in that chain's address format
struct TokenId {
  uint32 domain;
  bytes32 id;
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import { IConnext } from "connext/IConnext.sol";
import { IXReceiver } from "connext/IXReceiver.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

contract Connext is IXReceiver, Ownable {

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ReceivedOnDestination(address token, uint amountLD);

    event TransferSent(
        address tokenIn,
        address bridgeToken,
        uint256 tokenInAmount,
        uint256 bridgeTokenAmount,
        uint32 dstChainId, 
        address dstChainTo
    );

    event TransferComplete(
        uint32 srcChainId,
        address receiver,
        address localToken,
        uint256 localTokenAmount,
        address swapToken,
        uint256 swapTokenAmount,
        bool swapSuccess
    );

    event Withdrawal(
        address to,
        address token,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SwapParams {
        address tokenIn;
        uint256 tokenInAmount;
        uint256 fee;
        address router;
        bytes txnCallData;
    }
    
    struct BridgeParams {
        uint16 bridgeSlippage;
        uint32 dstDomainId;
        uint256 fee;
        address dstConnextReceiver;
    }

    // TODO: Make the ordering consistent
    struct ReceivingSwapParams {
        address dstChainTo;
        address router;
        address dstSwapToken;
        uint256 fee;
        bytes txnCallData;
    }

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/

    address public connextCoreContract;
    address public bridgeTokenAddress;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address private constant NATIVE_TOKEN = address(0);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/ 

    constructor(address _connextCoreContract, address _bridgeTokenAddress) {
        connextCoreContract = _connextCoreContract;
        bridgeTokenAddress = _bridgeTokenAddress;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTERS
    //////////////////////////////////////////////////////////////*/

    function setConnextCoreContract(address _connext) external onlyOwner {
        connextCoreContract = _connext;
    }

    function setBridgeToken(address _token) external onlyOwner {
        bridgeTokenAddress = _token;
    }

    /*//////////////////////////////////////////////////////////////
                             INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/ 

    /// @param _tokenIn The token user wants to transfer to dstChain 
    /// @param _tokenInAmount The amount of src chain token to transfer to the destination chain  
    /// @param _swapTxnFee The fee for swap transaction
    /// @param _swapRouter The address of contract that swaps token in for bridge token
    /// @param _swapTxnCallData The call data for swap transaction
    function swap(
        address _tokenIn, 
        uint256 _tokenInAmount, 
        address _tokenOut,
        uint256 _swapTxnFee, 
        address _swapRouter, 
        bytes memory _swapTxnCallData
    ) internal returns (uint256) {

        // TODO: account for ETH swap
        // TODO: better way to get amount out?
        // TODO: make signatures internal
        // TODO: should we pass in a struct?
        // TODO: Make sure _swapRouter is actually the 0x router

        if (address(_tokenIn) != NATIVE_TOKEN) {
            uint256 allowance = IERC20(_tokenIn).allowance(address(this), _swapRouter);
            if (allowance < _tokenInAmount) {
                SafeERC20.safeApprove(IERC20(_tokenIn), _swapRouter, 0);
                SafeERC20.safeApprove(IERC20(_tokenIn), _swapRouter, _tokenInAmount);
            }
        }

        uint256 previousTokenOutBalance = IERC20(_tokenOut).balanceOf(address(this));
        (bool success, ) = _swapRouter.call{value: _swapTxnFee}(_swapTxnCallData);

        uint256 tokenOutAmount = IERC20(_tokenOut).balanceOf(address(this)) - previousTokenOutBalance; 

        return tokenOutAmount;
    }

    /// @param _bridgeTxn The struct containing the bridge transaction data
    /// @param _receivingSwapTxn The struct containing receiving swap data
    /// @param _bridgeTokenAmount The amount of bridge token to transfer to the destination chain
        function bridge(
            BridgeParams calldata _bridgeTxn,
            ReceivingSwapParams calldata _receivingSwapTxn,
            uint256 _bridgeTokenAmount
        ) internal {
        // encode payload data to send to destination contract, which it will handle with xReceive()
        bytes memory data = abi.encode(_receivingSwapTxn);

        // this contract needs to approve the connextCoreContract to spend its bridgeToken!
        SafeERC20.safeApprove(IERC20(bridgeTokenAddress), connextCoreContract, 0);
        SafeERC20.safeApprove(IERC20(bridgeTokenAddress), connextCoreContract, _bridgeTokenAmount);

        // TODO: change the delegate address from msg sender
        IConnext(connextCoreContract).xcall{value: _bridgeTxn.fee}(
            _bridgeTxn.dstDomainId,
            _bridgeTxn.dstConnextReceiver,
            bridgeTokenAddress,
            msg.sender,
            _bridgeTokenAmount,
            _bridgeTxn.bridgeSlippage,
            data
        );
    }

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @param _swapTxn The struct containing the swap transaction data
    /// @param _bridgeTxn The struct containing the bridge transaction data
    function transfer(
        SwapParams calldata _swapTxn,
        BridgeParams calldata _bridgeTxn,
        ReceivingSwapParams calldata _receivingSwapTxn
    ) external payable {

        // TODO: add logic to handle if swapToken is ETH
        // TODO: account for swap slippage

        require(msg.value >= (_swapTxn.fee + _bridgeTxn.fee), "insufficient value for fees");
        require(_swapTxn.tokenInAmount > 0, "transfer amount must be greater than 0");

        uint256 bridgeTokenAmount = _swapTxn.tokenInAmount;

        // transfer _tokenIn to this contract if _tokenIn is not ETH
        if (address(_swapTxn.tokenIn) != address(0)) {
            require(
                IERC20(_swapTxn.tokenIn).allowance(msg.sender, address(this)) >= _swapTxn.tokenInAmount, 
                "ERC 20 approval required by user"
            );

            SafeERC20.safeTransferFrom(
                IERC20(_swapTxn.tokenIn), 
                msg.sender, 
                address(this), 
                _swapTxn.tokenInAmount
            );
        } 

        // swap _tokenIn for bridgeToken if _tokenIn is not bridgeToken
        if (address(_swapTxn.tokenIn) != bridgeTokenAddress) {
            bridgeTokenAmount = swap(
                _swapTxn.tokenIn, 
                _swapTxn.tokenInAmount, 
                bridgeTokenAddress,
                _swapTxn.fee, 
                _swapTxn.router, 
                _swapTxn.txnCallData
            );

            require((bridgeTokenAmount > 0), "SWAP FAILED");
        }

        bridge(
            _bridgeTxn,
            _receivingSwapTxn,
            bridgeTokenAmount
        );

        emit TransferSent(
            _swapTxn.tokenIn, 
            bridgeTokenAddress, 
            _swapTxn.tokenInAmount, 
            bridgeTokenAmount, 
            _bridgeTxn.dstDomainId,
            _receivingSwapTxn.dstChainTo
        );
    }

    /// @param _transferId The unique id of the xchain transaction
    /// @param _amount The amount of token passed into the contract in Wei units
    /// @param _asset The address of token passed into the contract
    /// @param _originSender The address of the contract or EOA that called xcall on the origin chain
    /// @param _origin The domain ID of the chain that the transaction is coming from
    /// @param _calldata The data, in bytes, that is passed into xcall on the origin chain
    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _calldata
    ) external returns (bytes memory) {
        ReceivingSwapParams memory receivingSwapTxn = abi.decode(_calldata, (ReceivingSwapParams));

        if (_asset == receivingSwapTxn.dstSwapToken) { 
            // No swap needed on dst chain
            SafeERC20.safeTransfer(IERC20(_asset), receivingSwapTxn.dstChainTo, _amount);

            emit TransferComplete(
                _origin, 
                receivingSwapTxn.dstChainTo, 
                _asset, 
                _amount, 
                receivingSwapTxn.dstSwapToken, 
                0, 
                true
            );
            
            // TODO: should that bool be true?
        } else {
            // Swap needed on dst chain
            uint256 preLocalTokenBalance = IERC20(_asset).balanceOf(address(this));
            uint256 dstSwapTokenBalance = swap(
                _asset, 
                _amount, 
                receivingSwapTxn.dstSwapToken, 
                receivingSwapTxn.fee, 
                receivingSwapTxn.router, 
                receivingSwapTxn.txnCallData
            );

            // Post swap token balances
            uint256 postLocalTokenBalance = IERC20(_asset).balanceOf(address(this));
            uint256 localTokenSwappedOutBalance = preLocalTokenBalance - postLocalTokenBalance;
            uint256 leftOverLocalTokenBalance = _amount - localTokenSwappedOutBalance;

            // Send receiving address swapped token
            if (dstSwapTokenBalance > 0) {
                SafeERC20.safeTransfer(IERC20(receivingSwapTxn.dstSwapToken), receivingSwapTxn.dstChainTo, dstSwapTokenBalance);
            }

            // Send receiving address left over local token
            if (leftOverLocalTokenBalance > 0) {
                SafeERC20.safeTransfer(IERC20(_asset), receivingSwapTxn.dstChainTo, leftOverLocalTokenBalance);
            } 

            emit TransferComplete(
                _origin, 
                receivingSwapTxn.dstChainTo, 
                _asset,
                leftOverLocalTokenBalance, 
                receivingSwapTxn.dstSwapToken, 
                dstSwapTokenBalance, 
                (dstSwapTokenBalance > 0)
            );
        }
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}
}