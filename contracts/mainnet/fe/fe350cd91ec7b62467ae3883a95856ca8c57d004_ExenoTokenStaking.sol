/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
// File: erc-payable-token/contracts/token/ERC1363/IERC1363Spender.sol



pragma solidity ^0.8.0;

/**
 * @title IERC1363Spender Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support approveAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Spender {
    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param sender address The address which called `approveAndCall` function
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))` unless throwing
     */
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {
    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(
        address operator,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165Checker.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: erc-payable-token/contracts/token/ERC1363/IERC1363.sol



pragma solidity ^0.8.0;



/**
 * @title IERC1363 Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for a Payable Token contract as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363 is IERC20, IERC165 {
    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address recipient, uint256 amount) external returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `recipient`
     * @return true unless throwing
     */
    function transferAndCall(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param sender address The address which you want to send tokens from
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param sender address The address which you want to send tokens from
     * @param recipient address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `recipient`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: erc-payable-token/contracts/payment/ERC1363Payable.sol



pragma solidity ^0.8.0;







/**
 * @title ERC1363Payable
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation proposal of a contract that wants to accept ERC1363 payments
 */
contract ERC1363Payable is IERC1363Receiver, IERC1363Spender, ERC165, Context {
    using ERC165Checker for address;

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * this by operator (`operator`) using {transferAndCall} or {transferFromAndCall}.
     */
    event TokensReceived(address indexed operator, address indexed sender, uint256 amount, bytes data);

    /**
     * @dev Emitted when the allowance of this for a `sender` is set by
     * a call to {approveAndCall}. `amount` is the new allowance.
     */
    event TokensApproved(address indexed sender, uint256 amount, bytes data);

    // The ERC1363 token accepted
    IERC1363 private _acceptedToken;

    /**
     * @param acceptedToken_ Address of the token being accepted
     */
    constructor(IERC1363 acceptedToken_) {
        require(address(acceptedToken_) != address(0), "ERC1363Payable: acceptedToken is zero address");
        require(acceptedToken_.supportsInterface(type(IERC1363).interfaceId));

        _acceptedToken = acceptedToken_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC1363Receiver).interfaceId ||
            interfaceId == type(IERC1363Spender).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*
     * @dev Note: remember that the token contract address is always the message sender.
     * @param operator The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender The address which are token transferred from
     * @param amount The amount of tokens transferred
     * @param data Additional data with no specified format
     */
    function onTransferReceived(
        address operator,
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        require(_msgSender() == address(_acceptedToken), "ERC1363Payable: acceptedToken is not message sender");

        emit TokensReceived(operator, sender, amount, data);

        _transferReceived(operator, sender, amount, data);

        return IERC1363Receiver(this).onTransferReceived.selector;
    }

    /*
     * @dev Note: remember that the token contract address is always the message sender.
     * @param sender The address which called `approveAndCall` function
     * @param amount The amount of tokens to be spent
     * @param data Additional data with no specified format
     */
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        require(_msgSender() == address(_acceptedToken), "ERC1363Payable: acceptedToken is not message sender");

        emit TokensApproved(sender, amount, data);

        _approvalReceived(sender, amount, data);

        return IERC1363Spender(this).onApprovalReceived.selector;
    }

    /**
     * @dev The ERC1363 token accepted
     */
    function acceptedToken() public view returns (IERC1363) {
        return _acceptedToken;
    }

    /**
     * @dev Called after validating a `onTransferReceived`. Override this method to
     * make your stuffs within your contract.
     * @param operator The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender The address which are token transferred from
     * @param amount The amount of tokens transferred
     * @param data Additional data with no specified format
     */
    function _transferReceived(
        address operator,
        address sender,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        // optional override
    }

    /**
     * @dev Called after validating a `onApprovalReceived`. Override this method to
     * make your stuffs within your contract.
     * @param sender The address which called `approveAndCall` function
     * @param amount The amount of tokens to be spent
     * @param data Additional data with no specified format
     */
    function _approvalReceived(
        address sender,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        // optional override
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/ExenoTokenStaking.sol


pragma solidity 0.8.4;








/**
 * @notice Staking utilizing a payable token (ERC1363)
 * No tokens are burnt or minted, whereas staked tokens are stored in this contract
 * Interest payouts are done from the wallet account (thus prior allowance is needed)
 * Note: Multiple staking contracts can be deployed simultaneously
 */
contract ExenoTokenStaking is
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC1363Payable
{
    using SafeERC20 for IERC1363;

    // The tokens being staked
    IERC1363 public immutable token;

    // Source of interest payouts
    address public immutable wallet;

    /**
     * Interest rate per annum
     * Expressed as 10**4, e.g. 1285 means 0.1285 or 12.85%
     */
    uint256 public annualizedInterestRate;

    /**
     * Rebase period, expressed in hours
     * 24 means rebasing every day, 168 means rebasing every week, etc
     */
    uint256 public immutable rebasePeriodInHours;

    // Mode of calculating start time for new stakes
    StakeStartMode public stakeStartMode;

    // Date when this staking contract is terminated
    uint256 public endDate;

    // The total amount of currently staked tokens
    uint256 public totalTokensStaked;

    // Available options for `stakeStartMode`
    enum StakeStartMode {
        IMMEDIATE,
        NEAREST_FULL_HOUR,
        NEAREST_MIDNIGHT,
        NEAREST_1AM,
        NEAREST_NOON,
        NEAREST_1PM
    }
    
    // Represents a single staking deposit
    struct Stake {
        address user;
        uint256 timestamp;
        uint256 amount;
    }

    // Represents a stakeholder with active stakes
    struct Stakeholder {
        address user;
        uint256 totalAmount;
        Stake[] stakes;
    }

    // Represents a financial record for a single stake
    struct Record {
        uint256 timestamp;
        uint256 amount;
        uint256 interest;
        uint256 claimable;
        uint256 nextRebaseClaimable;
        uint256 nextRebaseTimestamp;
    }

    // Represents all records owned by a stakeholder
    struct StakingStatus {
        uint256 timestamp;
        uint256 totalAmount;
        Record[] records;
    }

    /**
     * Contains all stakes done with this contract
     * The stakes for each address are stored at an index which can be found using the `stakes` mapping
     */
    Stakeholder[] internal _stakeholders;

    // Keeps track of the index for the stakers in the stakes array
    mapping(address => uint256) internal _stakeMap;

    // Triggered whenever someone stakes tokens
    event Staked(
        address indexed user,
        uint256 amount
    );

    // Triggered whenever someone unstakes tokens
    event Unstaked(
        address indexed user,
        uint256 amount,
        uint256 payout
    );

    // Triggered when interest-rate is updated
    event UpdateAnnualizedInterestRate(
        uint256 previousRate,
        uint256 currentRate
    );

    // Triggered when start-mode is updated
    event UpdateStakeStartMode(
        StakeStartMode previousMode,
        StakeStartMode currentMode
    );

    // Triggered when end-date is updated
    event ExtendEndDate(
        uint256 previousEndDate,
        uint256 currentEndDate
    );

    modifier validAddress(address a) {
        require(a != address(0),
            "ExenoTokenStaking: address cannot be zero");
        require(a != address(this),
            "ExenoTokenStaking: invalid address");
        _;
    }

    constructor(
        IERC1363 _token,
        uint256 _annualizedInterestRate,
        uint256 _rebasePeriodInHours,
        uint8 _stakeStartMode,
        address _wallet,
        uint256 _endDate
    )
        ERC1363Payable(_token)
        validAddress(_wallet)
    {
        require(_annualizedInterestRate > 0,
            "ExenoTokenStaking: invalid annualized interest rate");

        require(_rebasePeriodInHours > 0,
            "ExenoTokenStaking: invalid rebase period");

        require(_stakeStartMode <= uint256(StakeStartMode.NEAREST_1PM),
            "ExenoTokenStaking: invalid stake start mode");

        require(_endDate > block.timestamp,
            "ExenoTokenStaking: end-date cannot be in the past");

        token = _token;
        annualizedInterestRate = _annualizedInterestRate;
        rebasePeriodInHours = _rebasePeriodInHours;
        stakeStartMode = StakeStartMode(_stakeStartMode);
        wallet = _wallet;
        endDate = _endDate;
        
        // Index 0 indicates a non-existing stakeholder
        _stakeholders.push();
    }

    /**
     * @dev When tokens are sent to this contract with `transferAndCall` a new stake is created for the sender
     * @param sender The address performing the action
     * @param amount The amount of tokens transferred
     */
    function _transferReceived(address, address sender, uint256 amount, bytes memory)
        internal override validAddress(sender)
    {
        _stake(sender, amount);
    }

    /**
     * @dev Adds a stakeholder to the `_stakeholders` array
     * @param stakeholder The stakeholder to be added
     */
    function _addStakeholder(address stakeholder)
        internal validAddress(stakeholder) returns(uint256)
    {
        // Push a empty item to make space for the new stakeholder
        _stakeholders.push();
        // Calculate the index of the last item in the array
        uint256 userIndex = _stakeholders.length - 1;
        // Assign the address to the new index
        _stakeholders[userIndex].user = stakeholder;
        // Add index to the map
        _stakeMap[stakeholder] = userIndex;
        return userIndex;
    }

    /**
     * @dev Creates a new stake for a sender
     * @param stakeholder Who is staking
     * @param amount Amount of tokens to be staked
     */
    function _stake(address stakeholder, uint256 amount)
        internal validAddress(stakeholder) whenNotPaused
    {
        require(amount > 0,
            "ExenoTokenStaking: amount cannot be zero");

        require(endDate > block.timestamp,
            "ExenoTokenStaking: end-date is expired");

        // Make sure tokens have been received
        assert(_checkBalanceIntegrity(totalTokensStaked + amount));

        // Mappings in Solidity creates all values, so we can just check the address
        uint256 userIndex = _stakeMap[stakeholder];
        
        // Check if the stakeholder already has a staked index or if its the first time
        if (userIndex == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the index of the stakes
            // The index returned will be the index of the stakeholder in the _stakeholders array
            userIndex = _addStakeholder(stakeholder);
        }

        // Use the index to push a new stake
        _stakeholders[userIndex].stakes.push(
            Stake(stakeholder, _calculateStartTimestamp(), amount)
        );

        // Track the total amount of staked tokens for the user
        _stakeholders[userIndex].totalAmount += amount;

        // Track the total balance of staked tokens for all users
        totalTokensStaked += amount;

        // Emit an event that the stake has occurred
        emit Staked(stakeholder, amount);
    }

    /**
     * @dev Unstaking logic
     * @param userIndex Who is unstaking
     * @param stakeIndex Index of the stake is the users stake counter, starting at 0 for the first stake
     * @param amount Amount of tokens to be unstaked from stakeIndex
     * @return Amount of tokens to be paid as interest payout
     */
    function _unstake(uint256 userIndex, uint256 stakeIndex, uint256 amount)
        internal returns(uint256)
    {
        // Calculate duration
        (,uint256 recentRebaseDuration,,) = _calculateDuration(
            _stakeholders[userIndex].stakes[stakeIndex].timestamp);
        
        // Calculate payout
        uint256 payout = _calculatePayout(recentRebaseDuration, amount);
        
        // Reduce the stake by subtracting the unstaked amount
        _stakeholders[userIndex].stakes[stakeIndex].amount -= amount;

        // Track the total amount of staked tokens for the user
        _stakeholders[userIndex].totalAmount -= amount;

        // Track the balance of staked tokens for all users
        totalTokensStaked -= amount;
        
        return payout;
    }

    /**
     * @dev Purging logic for the stakes array
     * It should be applied after `_unstake` is called
     * @param userIndex User whose stakes are to be purged
     */
    function _purge(uint256 userIndex)
        internal
    {
        Stake[] storage stakes = _stakeholders[userIndex].stakes;

        uint256 i; //index of the current stake in the loop
        uint256 j; //index of the nearest non-zero stake

        // Loop through all stakes
        while (i < stakes.length && j < stakes.length) {
            // Amount equal zero indicates that a stake can be revmoved
            if (stakes[i].amount == 0) {
                // Find the nearest non-zero stake
                if (j == 0) j = i + 1;
                while (j < stakes.length && stakes[j].amount == 0) {
                    j++;
                }
                // If it's found, use it to replace the current stake and then delete it
                if (j < stakes.length) {
                    stakes[i] = stakes[j];
                    delete stakes[j];
                }
                j++;
            }
            i++;
        }

        // If stakes have been shifted, permanently remove the deleted ones
        if (j > i) {
            // At this stage all deleted stakes are at the end of the array
            for (uint256 k = 0; k < j - i; k++) {
                assert(stakes[stakes.length - 1].amount == 0);
                stakes.pop();
            }
        }
    }

    function _checkBalanceIntegrity(uint256 expectedBalance)
        internal view returns(bool)
    {
        return token.balanceOf(address(this)) >= expectedBalance;
    }

    /**
     * @dev Calculates start time for a new stake
     * @return startTimestamp
     */
    function _calculateStartTimestamp()
        internal view virtual returns(uint256)
    {
        if (stakeStartMode == StakeStartMode.IMMEDIATE) {
            return block.timestamp;
        }
        uint256 startTimestamp = block.timestamp;
        if (stakeStartMode == StakeStartMode.NEAREST_FULL_HOUR) {
            // Reverse time to the top of the hour and then add 1 hour
            startTimestamp = startTimestamp / 1 hours * 1 hours + 1 hours;
        } else if (stakeStartMode == StakeStartMode.NEAREST_MIDNIGHT) {
            // Reverse time to 00:00 UTC and then add 1 day
            startTimestamp = startTimestamp / 1 days * 1 days + 1 days;
        } else if (stakeStartMode == StakeStartMode.NEAREST_1AM) {
            // Reverse time to 00:00 UTC and then add 1 hour
            startTimestamp = startTimestamp / 1 days * 1 days + 1 hours;
        } else if (stakeStartMode == StakeStartMode.NEAREST_NOON) {
            // Reverse time to 00:00 UTC and then add 12 hours
            startTimestamp = startTimestamp / 1 days * 1 days + 12 hours;
        } else if (stakeStartMode == StakeStartMode.NEAREST_1PM) {
            // Reverse time to 00:00 UTC and then add 13 hours
            startTimestamp = startTimestamp / 1 days * 1 days + 13 hours;
        }
        // Shift by 1 day if the new start is earlier than the current time
        if (startTimestamp < block.timestamp) {
            startTimestamp += 1 days;
            assert(startTimestamp >= block.timestamp);
        }
        return startTimestamp;
    }

    /**
     * @dev Calculates durations for different scenarios
     * @param startTimestamp When staking started
     * @return actualDuration Actual duration, expressed in hours
     * @return recentRebaseDuration Recent rebase duration, expressed in hours
     * @return nextRebaseDuration Next rebase duration, expressed in hours
     * @return nextRebaseTimestamp Next rebase timestamp expressed in hours
     */
    function _calculateDuration(uint256 startTimestamp)
        internal view virtual returns(
            uint256 actualDuration,
            uint256 recentRebaseDuration,
            uint256 nextRebaseDuration,
            uint256 nextRebaseTimestamp
        )
    {
        // We assume the stake is going to be terminated now
        uint256 endTimestamp = block.timestamp;
        
        // In case endDate has already happened, allow endTimestamp to extend one extra rebase period
        if (endDate < endTimestamp) {
            endTimestamp = Math.min(endTimestamp, endDate + rebasePeriodInHours * 1 hours);
        }

        // Actual duration of the stake, expressed in hours
        actualDuration = 0;
        
        // When the stake is already started, actualDuration becomes non-zero
        if (startTimestamp < endTimestamp) {
            actualDuration = (endTimestamp - startTimestamp) / 1 hours;
        }

        // Duration of the most recent rebase, expressed in hours
        recentRebaseDuration = (actualDuration / rebasePeriodInHours) * rebasePeriodInHours;

        // If no additional interest can be accrued, reduce actualDuration to recentRebaseDuration
        if (endTimestamp < block.timestamp) {
            actualDuration = recentRebaseDuration;
        }

        // Duration of the next rebase, expressed in hours
        nextRebaseDuration = 0;
        nextRebaseTimestamp = 0;
        
        // If this in not the last rebase, set nextRebaseDuration by extending recentRebaseDuration by one rebase period
        if (startTimestamp + recentRebaseDuration * 1 hours < endDate) {
            nextRebaseDuration = recentRebaseDuration + rebasePeriodInHours;
            nextRebaseTimestamp = startTimestamp + nextRebaseDuration * 1 hours;
        }
    }

    /**
     * @dev Calculates interest payout
     * @param duration Duration expressed in hours
     * @param amount Amount of tokens staked
     * @return Actual or potential payout
     */
    function _calculatePayout(uint256 duration, uint256 amount)
        internal view virtual returns(uint256)
    {
        return duration * amount * annualizedInterestRate / 365 / 24 / 10**4;
    }

    function pause()
        external onlyOwner
    {
        _pause();
    }

    function unpause()
        external onlyOwner
    {
        _unpause();
    }

    /**
     * @notice Sets a new annualized-interest-rate
     * @param newAnnualizedInterestRate New value for the rate
     */
    function updateAnnualizedInterestRate(uint256 newAnnualizedInterestRate)
        external onlyOwner
    {
        require(newAnnualizedInterestRate > 0,
            "ExenoTokenStaking: invalid annualized interest rate");
        
        emit UpdateAnnualizedInterestRate(annualizedInterestRate, newAnnualizedInterestRate);
        annualizedInterestRate = newAnnualizedInterestRate;
    }

    /**
     * @notice Sets a new stake-start-mode
     * @param newStakeStartValue New value for the mode
     */
    function updateStakeStartMode(uint8 newStakeStartValue)
        external onlyOwner
    {
        require(newStakeStartValue <= uint256(StakeStartMode.NEAREST_1PM),
            "ExenoTokenStaking: invalid stake start mode");
        
        StakeStartMode newStakeStartMode = StakeStartMode(newStakeStartValue);
        emit UpdateStakeStartMode(stakeStartMode, newStakeStartMode);
        stakeStartMode = newStakeStartMode;
    }

    /**
     * @notice Sets a new end-date under the following conditions:
     * (1) the existing end-date has not expired yet
     * (2) the new end-date is later then existing end-date
     * @param newEndDate New value for the end-date
     */
    function extendEndDate(uint256 newEndDate)
        external onlyOwner
    {
        require(newEndDate > block.timestamp,
            "ExenoTokenStaking: new end-date cannot be in the past");

        require(newEndDate > endDate,
            "ExenoTokenStaking: new end-date cannot be prior to existing end-date");
        
        require(endDate > block.timestamp,
            "ExenoTokenStaking: cannot set a new end-date as existing end-date is expired");
        
        emit ExtendEndDate(endDate, newEndDate);
        endDate = newEndDate;
    }

    /**
     * @notice Generates a staking status report for a given stakeholder
     * @param stakeholder For whom is the report
     * @return StakingStatus report
     */
    function getStakingStatus(address stakeholder)
        external view validAddress(stakeholder) returns(StakingStatus memory)
    {
        Stake[] memory stakes = _stakeholders[_stakeMap[stakeholder]].stakes;
        Record[] memory records = new Record[](stakes.length);
        for (uint256 i = 0; i < stakes.length; i++) {
            uint256 timestamp = stakes[i].timestamp;
            records[i].timestamp = timestamp;
            (
                uint256 actualDuration,
                uint256 recentRebaseDuration,
                uint256 nextRebaseDuration,
                uint256 nextRebaseTimestamp
            ) = _calculateDuration(timestamp);
            uint256 amount = stakes[i].amount;
            records[i].amount = amount;
            records[i].interest = _calculatePayout(actualDuration, amount);
            records[i].claimable = _calculatePayout(recentRebaseDuration, amount);
            records[i].nextRebaseClaimable = _calculatePayout(nextRebaseDuration, amount);
            records[i].nextRebaseTimestamp = nextRebaseTimestamp;
        }
        StakingStatus memory status = StakingStatus(block.timestamp,
            _stakeholders[_stakeMap[stakeholder]].totalAmount, records);
        return status;
    }

    /**
     * @notice Returns the number of stakeholders
     * @return Number of stakeholders
     */
    function getNumberOfStakeholders()
        external view returns(uint256)
    {
        return _stakeholders.length - 1;
    }

    /**
     * @notice Shows the current amount of tokens available for payouts
     * @return Owner's balance and this contract's allowance
     */
    function checkAvailableFunds()
        external view returns(uint256, uint256)
    {
        return (token.balanceOf(wallet), token.allowance(wallet, address(this)));
    }

    /**
     * @notice Withdraws stake from a given staking index and makes appropriate transfers
     * @param amount Amount to unstake, zero indicates maximum available
     * @param stakeIndex Index of the stake is the users stake counter, starting at 0 for the first stake
     * @param skipPayout Whether to give up interest payout (do not use it unless you have to)
     */
    function unstake(uint256 amount, uint256 stakeIndex, bool skipPayout)
        external nonReentrant
    {
        address stakeholder = msg.sender;
        uint256 userIndex = _stakeMap[stakeholder];

        Stake[] memory stakes = _stakeholders[userIndex].stakes;

        require(stakes.length > 0,
            "ExenoTokenStaking: this account has never made any staking");

        require(stakeIndex < stakes.length,
            "ExenoTokenStaking: provided index is out of range");

        Stake memory currentStake = stakes[stakeIndex];

        if (amount > 0) {
            require(currentStake.amount >= amount,
                "ExenoTokenStaking: there is not enough stake on the provided index for the requested amount");
        } else {
            // Amount equal to zero indicates that the entire index needs to be unstaked
            require(currentStake.amount > 0,
                "ExenoTokenStaking: there is not enough stake on the provided index for the requested amount");
            amount = currentStake.amount;
        }

        // Unstake and calculate the payout
        uint256 payout = _unstake(userIndex, stakeIndex, amount);
        
        // Reduce payout to zero in case we don't need it
        if (skipPayout) payout = 0;
        
        require(token.balanceOf(wallet) >= payout,
            "ExenoTokenStaking: not enough balance for payout");

        require(token.allowance(wallet, address(this)) >= payout,
            "ExenoTokenStaking: not enough allowance for payout");

        assert(_checkBalanceIntegrity(totalTokensStaked));

        // Apply purging right after unstaking to eliminate empty stakes
        _purge(userIndex);

        // Return staked tokens to the stakeholder
        token.safeTransfer(stakeholder, amount);

        // Send payout to the stakeholder
        if (payout > 0) {
            token.safeTransferFrom(wallet, stakeholder, payout);
        }
        
        assert(_checkBalanceIntegrity(totalTokensStaked));

        // Emit an event that unstaking has occurred
        emit Unstaked(stakeholder, amount, payout);
    }
    
    /**
     * @notice Withdraws stake by applying the FIFO rule - no staking index needs to be provided
     * @param amount Amount to unstake, zero indicates maximum available
     */
    function unstakeFifo(uint256 amount)
        external nonReentrant
    {
        address stakeholder = msg.sender;
        uint256 userIndex = _stakeMap[stakeholder];

        Stake[] memory stakes = _stakeholders[userIndex].stakes;

        require(stakes.length > 0,
            "ExenoTokenStaking: this account has never made any staking");

        // Amount equal to zero indicates that all indexes need to be unstaked
        if (amount == 0) {
            amount = _stakeholders[userIndex].totalAmount;
            require(amount > 0,
                "ExenoTokenStaking: not enough stake on all indexes for the requested amount");
        }
        
        // FIFO unstaking loop
        uint256 amountLeft = amount;
        uint256 payout = 0;
        uint256 index = 0;
        while (amountLeft > 0 && index < stakes.length) {
            uint256 bite = Math.min(stakes[index].amount, amountLeft);
            payout += _unstake(userIndex, index, bite);
            amountLeft -= bite;
            index++;
        }

        require(amountLeft == 0,
            "ExenoTokenStaking: not enough stake on all indexes for the requested amount");

        require(token.balanceOf(wallet) >= payout,
            "ExenoTokenStaking: not enough balance for payout");

        require(token.allowance(wallet, address(this)) >= payout,
            "ExenoTokenStaking: not enough allowance for payout");

        assert(_checkBalanceIntegrity(totalTokensStaked));

        // Apply purging after the entire unstaking loop
        _purge(userIndex);

        // Return staked tokens to the stakeholder
        token.safeTransfer(stakeholder, amount);

        // Send payout to the stakeholder
        token.safeTransferFrom(wallet, stakeholder, payout);

        assert(_checkBalanceIntegrity(totalTokensStaked));

        // Emit an event that unstaking has occurred
        emit Unstaked(stakeholder, amount, payout);
    }
}