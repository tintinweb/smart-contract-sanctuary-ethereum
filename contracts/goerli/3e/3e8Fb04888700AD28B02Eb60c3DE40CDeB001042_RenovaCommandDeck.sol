/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}




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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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


interface IERC20PermitUpgradeable {
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






interface IERC20Upgradeable {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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



interface IERC4906Upgradeable is IERC165Upgradeable, IERC721Upgradeable {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

interface IRenovaItemBase is IERC4906Upgradeable {
    /// @notice Emitted when an item is minted.
    /// @param player The player who owns the item.
    /// @param tokenId The token ID.
    /// @param hashverseItemId The Hashverse Item ID.
    event Mint(
        address indexed player,
        uint256 tokenId,
        uint256 hashverseItemId
    );

    /// @notice Emitted when the Custom Metadata URI is updated.
    /// @param uri The new URI.
    event UpdateCustomURI(string uri);

    /// @notice Emitted when an item is bridged out of the current chain.
    /// @param player The player.
    /// @param tokenId The Token ID.
    /// @param hashverseItemId The Hashverse Item ID.
    /// @param dstWormholeChainId The Wormhole Chain ID of the chain the item is being bridged to.
    /// @param sequence The Wormhole sequence number.
    event XChainBridgeOut(
        address indexed player,
        uint256 tokenId,
        uint256 hashverseItemId,
        uint16 dstWormholeChainId,
        uint256 sequence,
        uint256 relayerFee
    );

    /// @notice Emitted when an item was bridged into the current chain.
    /// @param player The player.
    /// @param tokenId The Token ID.
    /// @param hashverseItemId The Hashverse Item ID.
    /// @param srcWormholeChainId The Wormhole Chain ID of the chain the item is being bridged from.
    event XChainBridgeIn(
        address indexed player,
        uint256 tokenId,
        uint256 hashverseItemId,
        uint16 srcWormholeChainId
    );

    /// @notice Bridges an item into the chain via Wormhole.
    /// @param vaa The Wormhole VAA.
    function wormholeBridgeIn(bytes memory vaa) external;

    /// @notice Bridges an item out of the chain via Wormhole.
    /// @param tokenId The Token ID.
    /// @param dstWormholeChainId The Wormhole Chain ID of the chain the item is being bridged to.
    function wormholeBridgeOut(
        uint256 tokenId,
        uint16 dstWormholeChainId,
        uint256 wormholeMessageFee
    ) external payable;

    /// @notice Sets the default royalty for the Item collection.
    /// @param receiver The receiver of royalties.
    /// @param feeNumerator The numerator of the fraction denoting the royalty percentage.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /// @notice Sets a custom base URI for the token metadata.
    /// @param customBaseURI The new Custom URI.
    function setCustomBaseURI(string memory customBaseURI) external;

    /// @notice Emits a refresh metadata event for a token.
    /// @param tokenId The ID of the token.
    function refreshMetadata(uint256 tokenId) external;

    /// @notice Emits a refresh metadata event for all tokens.
    function refreshAllMetadata() external;
}


interface IRenovaItem is IRenovaItemBase {
    /// @notice Emitted when the authorization status of a minter changes.
    /// @param minter The minter for which the status was updated.
    /// @param status The new status.
    event UpdateMinterAuthorization(address minter, bool status);

    /// @notice Initializer function.
    /// @param minter The initial authorized minter.
    /// @param wormhole The Wormhole Endpoint address. See {IWormholeBaseUpgradeable}.
    /// @param wormholeConsistencyLevel The Wormhole Consistency Level. See {IWormholeBaseUpgradeable}.
    function initialize(
        address minter,
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) external;

    /// @notice Mints an item.
    /// @param tokenOwner The owner of the item.
    /// @param hashverseItemId The Hashverse Item ID.
    function mint(address tokenOwner, uint256 hashverseItemId) external;

    /// @notice Updates the authorization status of a minter.
    /// @param minter The minter to update the authorization status for.
    /// @param status The new status.
    function updateMinterAuthorization(address minter, bool status) external;
}


interface IHashflowRouter {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function tradeSingleHop(RFQTQuote memory quote) external payable;
}



interface IRenovaAvatarBase is IERC4906Upgradeable {
    enum RenovaFaction {
        RESISTANCE,
        SOLUS
    }

    enum RenovaRace {
        GUARDIAN,
        EX_GUARDIAN,
        WARDEN_DROID,
        HASHBOT
    }

    enum RenovaGender {
        MALE,
        FEMALE
    }

    /// @notice Emitted when an Avatar is minted.
    /// @param player The owner of the Avatar.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    event Mint(
        address indexed player,
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender
    );

    /// @notice Emitted when the Custom Metadata URI is updated.
    /// @param uri The new URI.
    event UpdateCustomURI(string uri);

    /// @notice Returns the faction of a player.
    /// @param player The player.
    /// @return The faction.
    function factions(address player) external returns (RenovaFaction);

    /// @notice Returns the race of a player.
    /// @param player The player.
    /// @return The race.
    function races(address player) external returns (RenovaRace);

    /// @notice Returns the gender of a player.
    /// @param player The player.
    /// @return The gender.
    function genders(address player) external returns (RenovaGender);

    /// @notice Returns the token ID of a player.
    /// @param player The player.
    /// @return The token ID.
    function tokenIds(address player) external returns (uint256);

    /// @notice Sets a custom base URI for the token metadata.
    /// @param customBaseURI The new Custom URI.
    function setCustomBaseURI(string memory customBaseURI) external;

    /// @notice Emits a refresh metadata event for a token.
    /// @param tokenId The ID of the token.
    function refreshMetadata(uint256 tokenId) external;

    /// @notice Emits a refresh metadata event for all tokens.
    function refreshAllMetadata() external;
}



interface IRenovaAvatar is IRenovaAvatarBase {
    /// @notice Emitted when the Avatar is minted to another chain.
    /// @param player The owner of the Avatar.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    /// @param dstWormholeChainId The Wormhole Chain ID of the destination chain.
    /// @param sequence The Sequence number of the Wormhole message.
    event XChainMintOut(
        address indexed player,
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender,
        uint16 dstWormholeChainId,
        uint256 sequence,
        uint256 relayerFee
    );

    /// @notice Emitted when the StakingVault contract that tracks veHFT is updated.
    /// @param stakingVault The address of the new StakingVault contract.
    /// @param prevStakingVault The address of the previous StakingVault contract.
    event UpdateStakingVault(address stakingVault, address prevStakingVault);

    /// @notice Emitted when the minimum stake power required to mint changes.
    /// @param minStakePower The new required minimum stake power.
    event UpdateMinStakePower(uint256 minStakePower);

    /// @notice Initializer function.
    /// @param renovaCommandDeck The Renova Command Deck.
    /// @param stakingVault The address of the StakingVault contract.
    /// @param minStakePower The minimum amount of stake power required to mint an Avatar.
    /// @param wormhole The Wormhole Endpoint. See {IWormholeBaseUpgradeable}.
    /// @param wormholeConsistencyLevel The Wormhole Consistency Level. See {IWormholeBaseUpgradeable}.
    function initialize(
        address renovaCommandDeck,
        address stakingVault,
        uint256 minStakePower,
        address wormhole,
        uint8 wormholeConsistencyLevel
    ) external;

    /// @notice Updates the StakingVault contract used to track veHFT.
    /// @param stakingVault The address of the new StakingVault contract.
    function updateStakingVault(address stakingVault) external;

    /// @notice Updates the minimum stake power required to mint an Avatar.
    /// @param minStakePower The new minimum stake power required.
    function updateMinStakePower(uint256 minStakePower) external;

    /// @notice Mints an Avatar. Requires a minimum amount of stake power.
    /// @param faction The faction of the Avatar.
    /// @param race The race of the Avatar.
    /// @param gender The gender of the Avatar.
    function mint(
        RenovaFaction faction,
        RenovaRace race,
        RenovaGender gender
    ) external;

    /// @notice Mints the Avatar cross-chain, via Wormhole.
    /// @param dstWormholeChainId The Wormhole Chain ID of the chain to mint on. See {IWormholeBaseUpgradeable}.
    function wormholeMintSend(
        uint16 dstWormholeChainId,
        uint256 wormholeMessageFee
    ) external payable;
}



interface IRenovaQuest {
    enum QuestMode {
        SOLO,
        TEAM
    }

    struct TokenDeposit {
        address token;
        uint256 amount;
    }

    /// @notice Emitted when a token authorization status changes.
    /// @param token The address of the token.
    /// @param status Whether the token is allowed for trading.
    event UpdateTokenAuthorizationStatus(address token, bool status);

    /// @notice Emitted when a player registers for a quest.
    /// @param player The player registering for the quest.
    event RegisterPlayer(address indexed player);

    /// @notice Emitted when a player loads an item.
    /// @param player The player who loads the item.
    /// @param tokenId The Token ID of the loaded item.
    event LoadItem(address indexed player, uint256 tokenId);

    /// @notice Emitted when a player unloads an item.
    /// @param player The player who unloads the item.
    /// @param tokenId The Token ID of the unloaded item.
    event UnloadItem(address indexed player, uint256 tokenId);

    /// @notice Emitted when a player deposits a token for a Quest.
    /// @param player The player who deposits the token.
    /// @param token The address of the token (0x0 for native token).
    /// @param amount The amount of token being deposited.
    event DepositToken(address indexed player, address token, uint256 amount);

    /// @notice Emitted when a player withdraws a token from a Quest.
    /// @param player The player who withdraws the token.
    /// @param token The address of the token (0x0 for native token).
    /// @param amount The amount of token being withdrawn.
    event WithdrawToken(address indexed player, address token, uint256 amount);

    /// @notice Emitted when a player trades as part of the Quest.
    /// @param player The player who traded.
    /// @param baseToken The address of the token the player sold.
    /// @param quoteToken The address of the token the player bought.
    /// @param baseTokenAmount The amount sold.
    /// @param quoteTokenAmount The amount bought.
    event Trade(
        address indexed player,
        address baseToken,
        address quoteToken,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount
    );

    /// @notice Returns the Quest start time.
    /// @return The Quest start time.
    function startTime() external returns (uint256);

    /// @notice Returns the Quest end time.
    /// @return The Quest end time.
    function endTime() external returns (uint256);

    /// @notice Returns the address that has authority over the quest.
    /// @return The address that has authority over the quest.
    function questOwner() external returns (address);

    /// @notice Returns whether a player has registered for the Quest.
    /// @param player The address of the player.
    /// @return Whether the player has registered.
    function registered(address player) external returns (bool);

    /// @notice Used by the owner to allow / disallow a token for trading.
    /// @param token The address of the token.
    /// @param status The authorization status.
    function updateTokenAuthorization(address token, bool status) external;

    /// @notice Returns whether a token is allowed for deposits / trading.
    /// @param token The address of the token.
    /// @return Whether the token is allowed for trading.
    function allowedTokens(address token) external returns (bool);

    /// @notice Returns the number of registered players.
    /// @return The number of registered players.
    function numRegisteredPlayers() external returns (uint256);

    /// @notice Returns the number of registered players by faction.
    /// @param faction The faction.
    /// @return The number of registered players in the faction.
    function numRegisteredPlayersPerFaction(
        IRenovaAvatar.RenovaFaction faction
    ) external returns (uint256);

    /// @notice Returns the number of loaded items for a player.
    /// @param player The address of the player.
    /// @return The number of currently loaded items.
    function numLoadedItems(address player) external returns (uint256);

    /// @notice Returns the Token IDs for the loaded items for a player.
    /// @param player The address of the player.
    /// @param idx The index of the item in the array of loaded items.
    /// @return The Token ID of the item.
    function loadedItems(
        address player,
        uint256 idx
    ) external returns (uint256);

    /// @notice Returns the token balance for each token the player has in the Quest.
    /// @param player The address of the player.
    /// @param token The address of the token.
    /// @return The player's token balance for this Quest.
    function portfolioTokenBalances(
        address player,
        address token
    ) external returns (uint256);

    /// @notice Registers a player for the quests, loads items, and deposits tokens.
    /// @param tokenIds The token IDs for the items to load.
    /// @param tokenDeposits The tokens and amounts to deposit.
    function enterLoadDeposit(
        uint256[] memory tokenIds,
        TokenDeposit[] memory tokenDeposits
    ) external payable;

    /// @notice Registers a player for the quest.
    function enter() external;

    /// @notice Loads items into the Quest.
    /// @param tokenIds The Token IDs of the loaded items.
    function loadItems(uint256[] memory tokenIds) external;

    /// @notice Unloads an item.
    /// @param tokenId the Token ID of the item to unload.
    function unloadItem(uint256 tokenId) external;

    /// @notice Unloads all loaded items for the player.
    function unloadAllItems() external;

    /// @notice Deposits tokens prior to the beginning of the Quest.
    /// @param tokenDeposits The addresses and amounts of tokens to deposit.
    function depositTokens(
        TokenDeposit[] memory tokenDeposits
    ) external payable;

    /// @notice Withdraws the full balance of the selected tokens from the Quest.
    /// @param tokens The addresses of the tokens to withdraw.
    function withdrawTokens(address[] memory tokens) external;

    /// @notice Trades within the Quest.
    /// @param quote The Hashflow Quote.
    function trade(IHashflowRouter.RFQTQuote memory quote) external payable;
}



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

    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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



library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}



abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}


abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}



abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}



interface IRenovaCommandDeckBase {
    /// @notice Emitted every time the Hashflow Router is updated.
    /// @param newRouter The address of the new Hashflow Router.
    /// @param oldRouter The address of the old Hashflow Router.
    event UpdateHashflowRouter(address newRouter, address oldRouter);

    /// @notice Emitted every time the Quest Owner changes.
    /// @param newQuestOwner The address of the new Quest Owner.
    /// @param oldQuestOwner The address of the old Quest Owner.
    event UpdateQuestOwner(address newQuestOwner, address oldQuestOwner);

    /// @notice Emitted every time a Quest is created.
    /// @param questId The Quest ID.
    /// @param questAddress The address of the contract handling the Quest logic.
    /// @param questMode The Mode of the Quest (e.g. Multiplayer).
    /// @param maxPlayers The max number of players (0 for infinite).
    /// @param maxItemsPerPlayer The max number of items (0 for infinite) each player can equip.
    /// @param startTime The quest start time, in unix seconds.
    /// @param endTime The quest end time, in unix seconds.
    event CreateQuest(
        bytes32 questId,
        address questAddress,
        IRenovaQuest.QuestMode questMode,
        uint256 maxPlayers,
        uint256 maxItemsPerPlayer,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice Returns the Avatar contract address.
    /// @return The address of the Avatar contract.
    function renovaAvatar() external returns (address);

    /// @notice Returns the Item contract address.
    /// @return The address of the Item contract.
    function renovaItem() external returns (address);

    /// @notice Returns the Router contract address.
    /// @return The address of the Router contract.
    function hashflowRouter() external returns (address);

    /// @notice Returns the Quest Owner address.
    /// @return The address of the Quest Owner.
    function questOwner() external returns (address);

    /// @notice Returns the deployment contract address for a quest ID.
    /// @param questId The Quest ID.
    /// @return The deployed contract address if the quest ID is valid.
    function questDeploymentAddresses(
        bytes32 questId
    ) external returns (address);

    /// @notice Returns the ID of a quest deployed at a particular address.
    /// @param questAddress The address of the Quest contract.
    /// @return The quest ID.
    function questIdsByDeploymentAddress(
        address questAddress
    ) external returns (bytes32);

    /// @notice Loads items into a Quest.
    /// @param player The address of the player loading the items.
    /// @param tokenIds The Token IDs of the items to load.
    /// @dev This function helps save gas by only setting allowance to this contract.
    function loadItemsForQuest(
        address player,
        uint256[] memory tokenIds
    ) external;

    /// @notice Deposits tokens into a Quest.
    /// @param player The address of the player depositing the tokens.
    /// @param tokenDeposits The tokens and their amounts.
    /// @dev This function helps save gas by only setting allowance to this contract.
    function depositTokensForQuest(
        address player,
        IRenovaQuest.TokenDeposit[] memory tokenDeposits
    ) external;

    /// @notice Creates a Quest in the Hashverse.
    /// @param questId The Quest ID.
    /// @param questMode The mode of the Quest (e.g. SOLO).
    /**
     * @param maxPlayers The max number of players or 0 if uncapped. If the quest is
     * a multiplayer quest, this will be the max number of players for each Faction.
     */
    /// @param maxItemsPerPlayer The max number of items per player or 0 if uncapped.
    /// @param startTime The quest start time, in Unix seconds.
    /// @param endTime The quest end time, in Unix seconds.
    function createQuest(
        bytes32 questId,
        IRenovaQuest.QuestMode questMode,
        uint256 maxPlayers,
        uint256 maxItemsPerPlayer,
        uint256 startTime,
        uint256 endTime
    ) external;

    /// @notice Updates the Hashflow Router contract address.
    /// @param hashflowRouter The new Hashflow Router contract address.
    function updateHashflowRouter(address hashflowRouter) external;

    /// @notice Updates the Quest Owner address.
    /// @param questOwner The new Quest Owner address.
    function updateQuestOwner(address questOwner) external;
}

contract RenovaQuest is
    IRenovaQuest,
    IERC721Receiver,
    Context,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using Address for address payable;

    address private immutable _renovaCommandDeck;
    address private immutable _renovaAvatar;
    address private immutable _renovaItem;
    address private immutable _hashflowRouter;

    QuestMode private immutable _questMode;
    uint256 private immutable _maxPlayers;
    uint256 private immutable _maxItemsPerPlayer;

    uint256 public immutable startTime;
    uint256 public immutable endTime;

    /// @inheritdoc IRenovaQuest
    address public questOwner;

    /// @inheritdoc IRenovaQuest
    mapping(address => bool) public registered;

    /// @inheritdoc IRenovaQuest
    mapping(address => bool) public allowedTokens;

    /// @inheritdoc IRenovaQuest
    uint256 public numRegisteredPlayers;

    /// @inheritdoc IRenovaQuest
    mapping(IRenovaAvatar.RenovaFaction => uint256)
        public numRegisteredPlayersPerFaction;

    /// @inheritdoc IRenovaQuest
    mapping(address => uint256[]) public loadedItems;

    /// @inheritdoc IRenovaQuest
    mapping(address => uint256) public numLoadedItems;

    /// @inheritdoc IRenovaQuest
    mapping(address => mapping(address => uint256))
        public portfolioTokenBalances;

    constructor(
        QuestMode questMode,
        address renovaAvatar,
        address renovaItem,
        address hashflowRouter,
        uint256 maxPlayers,
        uint256 maxItemsPerPlayer,
        uint256 _startTime,
        uint256 _endTime,
        address _questOwner
    ) {
        _renovaCommandDeck = _msgSender();

        _questMode = questMode;

        _maxPlayers = maxPlayers;
        _maxItemsPerPlayer = maxItemsPerPlayer;

        require(
            _startTime > block.timestamp,
            'RenovaQuest::constructor Start time should be in the future.'
        );
        require(
            _endTime > _startTime,
            'RenovaQuest::constructor End time should be after start time.'
        );
        require(
            (_endTime - _startTime) <= (1 days) * 31,
            'RenovaQuest::constructor Quest too long.'
        );

        startTime = _startTime;
        endTime = _endTime;

        questOwner = _questOwner;

        _renovaAvatar = renovaAvatar;
        _renovaItem = renovaItem;
        _hashflowRouter = hashflowRouter;
    }

    /// @inheritdoc IRenovaQuest
    function updateTokenAuthorization(
        address token,
        bool status
    ) external override {
        require(
            _msgSender() == questOwner,
            'RenovaQuest::updateTokenAuthorization Sender must be quest owner.'
        );

        allowedTokens[token] = status;

        emit UpdateTokenAuthorizationStatus(token, status);
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc IRenovaQuest
    function enterLoadDeposit(
        uint256[] memory tokenIds,
        TokenDeposit[] memory tokenDeposits
    ) external payable override {
        _enter(_msgSender());

        if (tokenIds.length > 0) {
            _loadItems(_msgSender(), tokenIds);
        }

        if (tokenDeposits.length > 0) {
            _depositTokens(_msgSender(), tokenDeposits);
        }
    }

    /// @inheritdoc IRenovaQuest
    function enter() external override nonReentrant {
        _enter(_msgSender());
    }

    /// @inheritdoc IRenovaQuest
    function loadItems(uint256[] memory tokenIds) external override {
        _loadItems(_msgSender(), tokenIds);
    }

    /// @inheritdoc IRenovaQuest
    function depositTokens(
        TokenDeposit[] memory tokenDeposits
    ) external payable override nonReentrant {
        _depositTokens(_msgSender(), tokenDeposits);
    }

    function unloadItem(uint256 tokenId) external override {
        uint256 idx = 0;
        uint256 numLoadedItemsForPlayer = loadedItems[_msgSender()].length;

        while (
            idx < numLoadedItemsForPlayer &&
            loadedItems[_msgSender()][idx] != tokenId
        ) {
            idx++;
        }

        require(
            idx < numLoadedItemsForPlayer,
            'RenovaQuest::unloadItem Item not loaded.'
        );

        loadedItems[_msgSender()][idx] = loadedItems[_msgSender()][
            numLoadedItemsForPlayer - 1
        ];
        loadedItems[_msgSender()].pop();

        numLoadedItems[_msgSender()] -= 1;

        emit UnloadItem(_msgSender(), tokenId);
        IERC721(_renovaItem).safeTransferFrom(
            address(this),
            _msgSender(),
            tokenId
        );
    }

    /// @inheritdoc IRenovaQuest
    function unloadAllItems() external override {
        require(
            block.timestamp < startTime || block.timestamp >= endTime,
            'RenovaQuest::unloadAllItems Quest is ongoing.'
        );

        uint256[] memory allLoadedItems = loadedItems[_msgSender()];

        for (uint256 i = 0; i < allLoadedItems.length; i++) {
            emit UnloadItem(_msgSender(), allLoadedItems[i]);
            IERC721(_renovaItem).safeTransferFrom(
                address(this),
                _msgSender(),
                allLoadedItems[i]
            );
        }

        uint256[] memory empty;

        loadedItems[_msgSender()] = empty;
        numLoadedItems[_msgSender()] = 0;
    }

    /// @inheritdoc IRenovaQuest
    function withdrawTokens(
        address[] memory tokens
    ) external override nonReentrant {
        require(
            block.timestamp < startTime || block.timestamp >= endTime,
            'RenovaQuest::withdrawTokens Quest is ongoing.'
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = portfolioTokenBalances[_msgSender()][tokens[i]];
            if (amount == 0) {
                continue;
            }
            portfolioTokenBalances[_msgSender()][tokens[i]] = 0;

            emit WithdrawToken(_msgSender(), tokens[i], amount);

            if (tokens[i] == address(0)) {
                payable(_msgSender()).sendValue(amount);
            } else {
                IERC20(tokens[i]).safeTransfer(_msgSender(), amount);
            }
        }
    }

    /// @inheritdoc IRenovaQuest
    function trade(
        IHashflowRouter.RFQTQuote memory quote
    ) external payable override nonReentrant {
        require(
            block.timestamp >= startTime && block.timestamp < endTime,
            'RenovaQuest::trade Quest is not ongoing.'
        );
        require(
            allowedTokens[quote.quoteToken],
            'RenovaQuest::trade Quote Token not allowed.'
        );

        require(
            registered[_msgSender()],
            'RenovaQuest::trade Player not registered.'
        );

        require(
            portfolioTokenBalances[_msgSender()][quote.baseToken] >=
                quote.effectiveBaseTokenAmount,
            'RenovaQuest::trade Insufficient balance'
        );

        require(
            quote.trader == address(this),
            'RenovaQuest::trade Trader should be Quest contract.'
        );

        require(
            quote.effectiveTrader == _msgSender(),
            'RenovaQuest::trade Effective Trader should be player.'
        );

        uint256 quoteTokenAmount = quote.maxQuoteTokenAmount;
        if (quote.effectiveBaseTokenAmount < quote.maxBaseTokenAmount) {
            quoteTokenAmount =
                (quote.effectiveBaseTokenAmount * quote.maxQuoteTokenAmount) /
                quote.maxBaseTokenAmount;
        }

        portfolioTokenBalances[_msgSender()][quote.baseToken] -= quote
            .effectiveBaseTokenAmount;
        portfolioTokenBalances[_msgSender()][
            quote.quoteToken
        ] += quoteTokenAmount;

        emit Trade(
            _msgSender(),
            quote.baseToken,
            quote.quoteToken,
            quote.effectiveBaseTokenAmount,
            quoteTokenAmount
        );

        uint256 msgValue = 0;

        if (quote.baseToken == address(0)) {
            msgValue = quote.effectiveBaseTokenAmount;
        } else {
            require(
                IERC20(quote.baseToken).approve(
                    _hashflowRouter,
                    quote.effectiveBaseTokenAmount
                ),
                'RenovaQuest::trade Could not approve token.'
            );
        }

        uint256 balanceBefore = _questBalanceOf(quote.quoteToken);

        IHashflowRouter(_hashflowRouter).tradeSingleHop{value: msgValue}(quote);

        uint256 balanceAfter = _questBalanceOf(quote.quoteToken);

        require(
            balanceBefore + quoteTokenAmount == balanceAfter,
            'RenovaQuest::trade Did not receive enough quote token.'
        );
    }

    /// @notice Registers a player for the quest.
    /// @param player The address of the player.
    function _enter(address player) internal {
        require(
            block.timestamp < startTime,
            'RenovaQuest::_enter Can only enter before the quest starts.'
        );

        require(
            !registered[player],
            'RenovaQuest::_enter Player already registered.'
        );

        uint256 avatarTokenId = IRenovaAvatar(_renovaAvatar).tokenIds(player);
        require(
            avatarTokenId != 0,
            'RenovaQuest::_enter Player has not minted Avatar.'
        );

        IRenovaAvatar.RenovaFaction faction = IRenovaAvatar(_renovaAvatar)
            .factions(_msgSender());

        if (_questMode == QuestMode.SOLO) {
            require(
                _maxPlayers == 0 || numRegisteredPlayers < _maxPlayers,
                'RenovaQuest::_enter Player cap reached.'
            );
        } else {
            require(
                _maxPlayers == 0 ||
                    numRegisteredPlayersPerFaction[faction] < _maxPlayers,
                'RenovaQuest::_enter Player cap reached.'
            );
        }

        emit RegisterPlayer(player);

        numRegisteredPlayers++;
        numRegisteredPlayersPerFaction[faction]++;

        registered[player] = true;
    }

    /// @notice Loads items into the Quest.
    /// @param player The address of the player loading the items.
    /// @param tokenIds The Token IDs of the loaded items.
    function _loadItems(address player, uint256[] memory tokenIds) internal {
        require(
            block.timestamp < startTime,
            'RenovaQuest::loadItems Can only load item before the quest starts.'
        );

        require(
            registered[player],
            'RenovaQuest::loadItems Player not registered.'
        );

        uint256 _numLoadedItems = numLoadedItems[player];

        require(
            (_numLoadedItems + tokenIds.length) <= _maxItemsPerPlayer,
            'RenovaQuest::loadItems Too many items.'
        );

        IRenovaCommandDeck(_renovaCommandDeck).loadItemsForQuest(
            player,
            tokenIds
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            loadedItems[player].push(tokenIds[i]);

            emit LoadItem(player, tokenIds[i]);
        }

        _numLoadedItems += tokenIds.length;

        numLoadedItems[player] = _numLoadedItems;
    }

    /// @notice Deposits tokens prior to the beginning of the Quest.
    /// @param player The address of the player depositing tokens.
    /// @param tokenDeposits The addresses and amounts of tokens to deposit.
    function _depositTokens(
        address player,
        TokenDeposit[] memory tokenDeposits
    ) internal {
        require(
            block.timestamp < startTime,
            'RenovaQuest::depositToken Can only deposit before the quest starts.'
        );
        require(
            registered[player],
            'RenovaQuest::depositToken Player not registered.'
        );

        uint256 totalNativeToken = 0;

        for (uint256 i = 0; i < tokenDeposits.length; i += 1) {
            require(
                allowedTokens[tokenDeposits[i].token],
                'RenovaQuest::_depositTokens Token not allowed.'
            );
            if (tokenDeposits[i].token == address(0)) {
                totalNativeToken += tokenDeposits[i].amount;
            }

            emit DepositToken(
                player,
                tokenDeposits[i].token,
                tokenDeposits[i].amount
            );

            portfolioTokenBalances[player][
                tokenDeposits[i].token
            ] += tokenDeposits[i].amount;
        }

        require(
            msg.value == totalNativeToken,
            'RenovaQuest::depositToken msg.value should equal amount.'
        );

        IRenovaCommandDeck(_renovaCommandDeck).depositTokensForQuest(
            player,
            tokenDeposits
        );
    }

    /// @notice Returns the amount of token that this Quest currently holds.
    /// @param token The token to return the balance for.
    /// @return The balance.
    function _questBalanceOf(address token) internal view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
}




abstract contract RenovaCommandDeckBase is
    IRenovaCommandDeckBase,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @inheritdoc IRenovaCommandDeckBase
    address public renovaAvatar;

    /// @inheritdoc IRenovaCommandDeckBase
    address public renovaItem;

    /// @inheritdoc IRenovaCommandDeckBase
    address public hashflowRouter;

    /// @inheritdoc IRenovaCommandDeckBase
    address public questOwner;

    /// @inheritdoc IRenovaCommandDeckBase
    mapping(bytes32 => address) public questDeploymentAddresses;

    /// @inheritdoc IRenovaCommandDeckBase
    mapping(address => bytes32) public questIdsByDeploymentAddress;

    /// @dev Reserved for future upgrades.
    uint256[16] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Base class initializer function.
    /// @param _renovaAvatar The address of the Avatar contract.
    /// @param _renovaItem The address of the Item contract.
    /// @param _hashflowRouter The address of the Hashflow Router.
    function __RenovaCommandDeckBase_init(
        address _renovaAvatar,
        address _renovaItem,
        address _hashflowRouter,
        address _questOwner
    ) internal onlyInitializing {
        __Ownable_init();

        require(
            _renovaAvatar != address(0),
            'RenovaCommandDeckBase::__RenovaCommandDeckBase_init RenovaAvatar not defined.'
        );

        require(
            _renovaItem != address(0),
            'RenovaCommandDeckBase::__RenovaCommandDeckBase_init RenovaItem not defined.'
        );

        require(
            _hashflowRouter != address(0),
            'RenovaCommandDeckBase::__RenovaCommandDeckBase_init HashflowRouter not defined.'
        );

        require(
            _questOwner != address(0),
            'RenovaCommandDeckBase::__RenovaCommandDeckBase_init Quest owner not defined.'
        );

        renovaAvatar = _renovaAvatar;
        renovaItem = _renovaItem;
        hashflowRouter = _hashflowRouter;
        questOwner = _questOwner;

        emit UpdateHashflowRouter(hashflowRouter, address(0));
        emit UpdateQuestOwner(questOwner, address(0));
    }

    /// @inheritdoc IRenovaCommandDeckBase
    function loadItemsForQuest(
        address player,
        uint256[] memory tokenIds
    ) external override {
        require(
            questIdsByDeploymentAddress[_msgSender()] != bytes32(0),
            'RenovaCommandDeckBase::loadItemsForQuest Quest not registered.'
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(renovaItem).safeTransferFrom(
                player,
                _msgSender(),
                tokenIds[i]
            );
        }
    }

    function depositTokensForQuest(
        address player,
        IRenovaQuest.TokenDeposit[] memory tokenDeposits
    ) external override {
        require(
            questIdsByDeploymentAddress[_msgSender()] != bytes32(0),
            'RenovaCommandDeckBase::depositTokensForQuest Quest not registered.'
        );

        for (uint256 i = 0; i < tokenDeposits.length; i++) {
            if (tokenDeposits[i].token != address(0)) {
                IERC20Upgradeable(tokenDeposits[i].token).safeTransferFrom(
                    player,
                    _msgSender(),
                    tokenDeposits[i].amount
                );
            }
        }
    }

    /// @inheritdoc IRenovaCommandDeckBase
    function createQuest(
        bytes32 questId,
        IRenovaQuest.QuestMode questMode,
        uint256 maxPlayers,
        uint256 maxItemsPerPlayer,
        uint256 startTime,
        uint256 endTime
    ) external override {
        require(
            _msgSender() == questOwner,
            'RenovaCommandDeckBase::createQuest Sender must be Quest Owner.'
        );
        require(
            questDeploymentAddresses[questId] == address(0),
            'RenovaCommandDeckBase::createQuest Quest already created.'
        );

        RenovaQuest quest = new RenovaQuest(
            questMode,
            renovaAvatar,
            renovaItem,
            hashflowRouter,
            maxPlayers,
            maxItemsPerPlayer,
            startTime,
            endTime,
            questOwner
        );

        questDeploymentAddresses[questId] = address(quest);
        questIdsByDeploymentAddress[address(quest)] = questId;

        emit CreateQuest(
            questId,
            address(quest),
            questMode,
            maxPlayers,
            maxItemsPerPlayer,
            startTime,
            endTime
        );
    }

    /// @inheritdoc IRenovaCommandDeckBase
    function updateHashflowRouter(address _hashflowRouter) external onlyOwner {
        require(
            _hashflowRouter != address(0),
            'RenovaCommandDeckBase::updateHashflowRouter Cannot be 0 address.'
        );

        emit UpdateHashflowRouter(_hashflowRouter, hashflowRouter);

        hashflowRouter = _hashflowRouter;
    }

    function updateQuestOwner(address _questOwner) external onlyOwner {
        require(
            _questOwner != address(0),
            'RenovaCommandDeckBase::updateQuestOwner Cannot be 0 address.'
        );

        emit UpdateQuestOwner(_questOwner, questOwner);

        questOwner = _questOwner;
    }

    /// @inheritdoc OwnableUpgradeable
    function renounceOwnership() public view override onlyOwner {
        revert(
            'RenovaCommandDeckBase::renounceOwnership Cannot renounce ownership.'
        );
    }
}



/// @title IRenovaCommandDeck
/// @author Victor Ionescu
/// @notice See {IRenovaCommandDeckBase}
/// @dev Deployed on the main chain.
interface IRenovaCommandDeck is IRenovaCommandDeckBase {
    /// @notice Emitted when a new Merkle root is added for item minting.
    /// @param rootId The ID of the Root.
    /// @param root The Root.
    event UploadItemMerkleRoot(bytes32 rootId, bytes32 root);

    /// @notice Initializer function.
    /// @param renovaAvatar The address of the Avatar contract.
    /// @param renovaItem The address of the Item contract.
    /// @param hashflowRouter The address of the Hashflow Router.
    /// @param questOwner The address of the Quest Owner.
    function initialize(
        address renovaAvatar,
        address renovaItem,
        address hashflowRouter,
        address questOwner
    ) external;

    /// @notice Returns the Merkle root associated with a root ID.
    /// @param rootId The root ID.
    function itemMerkleRoots(bytes32 rootId) external returns (bytes32);

    /// @notice Uploads a Merkle root for minting items.
    /// @param rootId The root ID.
    /// @param root The Merkle root.
    function uploadItemMerkleRoot(bytes32 rootId, bytes32 root) external;

    /// @notice Mints an item via Merkle root.
    /// @param tokenOwner The wallet receiving the item.
    /// @param hashverseItemId The Hashverse Item ID of the minted item.
    /// @param rootId The ID of the Merkle root to use.
    /// @param mintIdx The mint "index" for cases where multiple items are awarded.
    /// @param proof The Merkle proof.
    function mintItem(
        address tokenOwner,
        uint256 hashverseItemId,
        bytes32 rootId,
        uint256 mintIdx,
        bytes32[] calldata proof
    ) external;

    /// @notice Mints an item via admin privileges.
    /// @param tokenOwner The wallet receiving the item.
    /// @param hashverseItemId The Hashverse Item ID of the minted item.
    function mintItemAdmin(
        address tokenOwner,
        uint256 hashverseItemId
    ) external;
}



contract RenovaCommandDeck is IRenovaCommandDeck, RenovaCommandDeckBase {
    /// @inheritdoc IRenovaCommandDeck
    mapping(bytes32 => bytes32) public itemMerkleRoots;

    mapping(bytes32 => mapping(address => mapping(uint256 => bool)))
        internal _mintedItems;

    /// @dev Reserved for future upgrades.
    uint256[16] private __gap;

    /// @inheritdoc IRenovaCommandDeck
    function initialize(
        address _renovaAvatar,
        address _renovaItem,
        address _hashflowRouter,
        address _questOwner
    ) external override initializer {
        __RenovaCommandDeckBase_init(
            _renovaAvatar,
            _renovaItem,
            _hashflowRouter,
            _questOwner
        );
    }

    /// @inheritdoc IRenovaCommandDeck
    function mintItem(
        address tokenOwner,
        uint256 hashverseItemId,
        bytes32 rootId,
        uint256 mintIdx,
        bytes32[] calldata proof
    ) external override {
        require(
            !_mintedItems[rootId][tokenOwner][mintIdx],
            'RenovaCommandDeck::mintItem Item already minted.'
        );

        bytes32 root = itemMerkleRoots[rootId];
        require(
            root != bytes32(0),
            'RenovaCommandDeck::mintItem Root not found.'
        );

        bytes32 leaf = keccak256(
            abi.encodePacked(tokenOwner, mintIdx, hashverseItemId)
        );

        require(
            MerkleProofUpgradeable.verifyCalldata(proof, root, leaf),
            'RenovaCommandDeck::mintItem Proof invalid.'
        );

        _mintedItems[rootId][tokenOwner][mintIdx] = true;

        _mintItem(tokenOwner, hashverseItemId);
    }

    /// @inheritdoc IRenovaCommandDeck
    function uploadItemMerkleRoot(
        bytes32 rootId,
        bytes32 root
    ) external override {
        require(
            _msgSender() == questOwner,
            'RenovaCommandDeck::uploadItemMerkleRoot Sender must be Quest Owner.'
        );
        require(
            itemMerkleRoots[rootId] == bytes32(0),
            'RenovaCommandDeck::uploadItemMerkleRoot Root already defined.'
        );

        itemMerkleRoots[rootId] = root;

        emit UploadItemMerkleRoot(rootId, root);
    }

    /// @inheritdoc IRenovaCommandDeck
    function mintItemAdmin(
        address tokenOwner,
        uint256 hashverseItemId
    ) external override onlyOwner {
        _mintItem(tokenOwner, hashverseItemId);
    }

    /// @notice Mints an Item to a specific owner.
    /// @param tokenOwner The owner of the Item.
    /// @param hashverseItemId The Hashverse Item ID.
    function _mintItem(address tokenOwner, uint256 hashverseItemId) internal {
        require(
            renovaItem != address(0),
            'RenovaCommandDeck::_mintItem RenovaItem not set.'
        );

        IRenovaItem(renovaItem).mint(tokenOwner, hashverseItemId);
    }
}