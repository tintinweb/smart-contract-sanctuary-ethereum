/**
 *Submitted for verification at Etherscan.io on 2023-01-04
*/

// SPDX-License-Identifier: MIT

/*
 * Inugami Referral (GAMI)
 *
 * We are Inugami, We are many.
 *
 * Website: https://weareinugami.com
 * dApp: https://app.weareinugami.com/
 *
 * Twitter: https://twitter.com/WeAreInugami_
 * Telegram: https://t.me/weareinugami
 */

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// File: Inugami/OwnerAdminSettings.sol



pragma solidity >=0.8.0 <0.9.0;



contract OwnerAdminSettings is ReentrancyGuard, Context {

  address internal _owner;

  struct Admin {
        address WA;
        uint8 roleLevel;
  }
  mapping(address => Admin) internal admins;

  mapping(address => bool) internal isAdminRole;

  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 
            );
    _;
  }

  modifier onlyDev() {
    require(admins[_msgSender()].roleLevel == 1);
    _;
  }

  modifier onlyAntiBot() {
    require(admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2
            );
    _;
  }

  modifier onlyAdminRoles() {
    require(_msgSender() == getOwner() ||
            admins[_msgSender()].roleLevel == 1 ||
            admins[_msgSender()].roleLevel == 2 || 
            admins[_msgSender()].roleLevel == 5
            );
    _;
  }

  constructor() {
    _owner = _msgSender();
    _setNewAdmins(_msgSender(), 1);
  }
    //DON'T FORGET TO SET Locker AND Marketing(AND ALSO WHITELISTING Marketing) AFTER DEPLOYING THE CONTRACT!!!
    //DON'T FORGET TO SET ADMINS!!

  //Owner and Admins
  //Set New Owner. Can be done only by the owner.
  function setNewOwner(address newOwner) external onlyOwner {
    require(newOwner != _owner, "This address is already the owner!");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

    //Sets up admin accounts.
    function setNewAdmin(address _address, uint8 _roleLevel) external onlyOwner {
      if(_roleLevel == 1) {
        require(admins[_msgSender()].roleLevel == 1, "You are not authorized to set a dev");
      }
      
      _setNewAdmins(_address, _roleLevel);
    }

    function _setNewAdmins(address _address, uint8 _roleLevel) internal {

            Admin storage newAdmin = admins[_address];
            newAdmin.WA = _address;
            newAdmin.roleLevel = _roleLevel;
 
        isAdminRole[_address] = true;
    } 
/*
    function verifyAdminMember(address adr) public view returns(bool YoN, uint8 role_) {
        uint256 iterations = 0;
        while(iterations < adminAccounts.length) {
            if(adminAccounts[iterations] == adr) {return (true, admins[adminAccounts[iterations]].role);}
            iterations++;
        }
        return (false, 0);
    }
*/
    function removeRole(address[] calldata adr) external onlyOwner {
        for(uint i=0; i < adr.length; i++) {
            _removeRole(adr[i]);
        }
    }

    function renounceMyRole(address adr) external onlyAdminRoles {
        require(adr == _msgSender(), "AccessControl: can only renounce roles for self");
        require(isAdminRole[adr] == true, "You do not have an admin role");
        _removeRole(adr);
    }

    function _removeRole(address adr) internal {

          delete admins[adr];
  
        isAdminRole[adr] = false;
    }
  
  //public
    function whoIsOwner() external view returns (address) {
      return getOwner();
    }

    function verifyAdminMember(address adr) external view returns (bool) {
      return isAdminRole[adr];
    }

    function showAdminRoleLevel(address adr) external view returns (uint8) {
      return admins[adr].roleLevel;
    }

  //internal

    function getOwner() internal view returns (address) {
      return _owner;
    }

}
// File: Inugami/Referral_ERC20_721_BonusBps.sol


pragma solidity ^0.8.0;








/*
 * Inugami Referral (GAMI)
 *
 * We are Inugami, We are many.
 *
 * Website: https://weareinugami.com
 * dApp: https://app.weareinugami.com/
 *
 * Twitter: https://twitter.com/WeAreInugami_
 * Telegram: https://t.me/weareinugami
 */

contract InugamiReferral is OwnerAdminSettings {
    //Library
    using SafeERC20 for IERC20;

    address public constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Router02 private uniswapRouter;

    address public rewardsToken;
    uint8 private tokenDecimals;
    event TokenContractSet(address Setter, address TokenContract);

    bool public contractSwitch;
    event ReferralContractStatusSet(address Setter, bool ReferralContractStatus);

    uint16 public baseRateBps;
    event BaseRateBpsSet(address Setter, uint16 BaseRateBps);

    uint private rewardsThreshold;
    event RewardsThresholdSet(address Setter, uint256 RewardsThreshold);

    bool public bonusStatus;
    bool public bonusStatusERC20;

    bool public bonusStatusERC721;
    bool public bonusERC721Amt;
    bool public bonusERC721Id;

    uint256 private maxERC20BonusBPS;
    uint256 private maxERC721BonusBPS;

    event BonusStatusSet(address Setter, bool BonusStatus, bool BonusStatusERC20, bool BonusStatusERC721, bool ERC721RewardsByAmt, bool ERC721RewardsById);


    mapping (address => uint) private rewards;
    mapping (address => address) private referrers;
    mapping (address => Referral[]) private referrals;

    struct Referral {
        address referee;
        uint48 timestamp;
        uint deposit;
        uint reward;
    }

    address[] internal partnershipsERC20;
    mapping(address => uint256) internal partnershipIndicesERC20;

    struct PartnerERC20 {
        uint8 decimalsPT;
        uint16 bronzeBonusBPSPT;
        uint16 silverBonusBPSPT;
        uint16 goldBonusBPSPT;
        uint16 platinumBonusBPSPT;
        uint16 diamondBonusBPSPT;
        uint256 bronzeHReqPT;
        uint256 silverHReqPT;
        uint256 goldHReqPT;
        uint256 platinumHReqPT;
        uint256 diamondHReqPT;
    }

    mapping(address => PartnerERC20) public partnersERC20;

    event NewPartnershipERC20Added(address Setter, address TokenCA);
    event PartnershipERC20Managed(address Setter, address TokenCA);
    event PartnershipERC20Removed(address Setter, address TokenCA);


    address[] internal partnershipsERC721;
    mapping(address => uint256) internal partnershipIndicesERC721;

    struct PartnerERC721 {
        uint16 silverBonusBPSPT;
        uint16 goldBonusBPSPT;
        uint16 platinumBonusBPSPT;
        uint16 diamondBonusBPSPT;
        uint32 silverHReqAmt;
        uint32 goldHReqAmt;
        uint32 platinumHReqAmt;
        uint32 diamondHReqAmt;
        uint32 silverHReqId;
        uint32 goldHReqId;
        uint32 platinumHReqId;
        uint32 diamondHReqId;
    }

    mapping(address => PartnerERC721) public partnersERC721;

    event NewPartnershipERC721Added(address Setter, address TokenCA);
    event PartnershipERC721AmountManaged(address Setter, address TokenCA);
    event PartnershipERC721IDManaged(address Setter, address TokenCA);
    event PartnershipERC721Removed(address Setter, address TokenCA);


    event RewardsClaimed(address Claimer, uint256 TokenAmount);
    event BuyWithReferral(address Referrer, address Referree, uint48 TimeStamp, uint256 ETHamount, uint256 TokenAmount, uint256 RewardAmount);
    event RewardsTokensDeposited(address Depositor, uint256 TokenAmount);
    event RewardsTokensWithdrawn(address Withdrawer, address Recipient, uint256 TokenAmount);
    event ETHWithdrawn(address Withdrawer, address Recipient, uint256 ETHamount);
    

    constructor(address _tokenCA,
                bool _ContractSwitch,
                uint16 _baseRateBps,
                bool _bonusStatusERC20,
                bool _bonusStatusERC721,
                bool _ERC721RewardsByAmt,
                bool _ERC721RewardsById,
                uint _thresholdAmt)
    {
        uniswapRouter = IUniswapV2Router02(routerAddress);

        rewardsToken = _tokenCA;

        contractSwitch = _ContractSwitch;

        baseRateBps = _baseRateBps;

        bonusStatusERC20 = _bonusStatusERC20;
        bonusStatusERC721 = _bonusStatusERC721;
        bonusERC721Amt = _ERC721RewardsByAmt;
        bonusERC721Id = _ERC721RewardsById;

        if(bonusStatusERC20 || bonusStatusERC721) {
            bonusStatus = true;
        } else {
            bonusStatus = false;
        }

        tokenDecimals = ERC20(_tokenCA).decimals();
        rewardsThreshold = _thresholdAmt * 10**tokenDecimals;
    }

    function getRewardsSupply() public view returns (uint) {
        return IERC20(rewardsToken).balanceOf(address(this));
    }

    function getRewardsThreshold() public view returns (uint) {
        return rewardsThreshold;
    }

    function getReferralsCount() public view returns (uint) {
        return referrals[msg.sender].length;
    }

    function getRewardsAccumulated() public view returns (uint) {
        return rewards[msg.sender];
    }

    function getReferralsData() public view returns (Referral[] memory) {
        return referrals[msg.sender];
    }

    function getClaimStatus() public view returns (bool) {
        return rewards[msg.sender] >= rewardsThreshold;
    }

    function claimRewards() external {
        require(contractSwitch, "Contract must be active!");
        require(rewards[msg.sender] >= rewardsThreshold, "Rewards accumulated are below the rewards claim threshold!");

        uint quantity = rewards[msg.sender];
        rewards[msg.sender] = 0;

        IERC20(rewardsToken).safeTransfer(msg.sender, quantity);

        emit RewardsClaimed(msg.sender, quantity);
    }

    function buyTokens(address referrer) external payable {
        require(contractSwitch, "Contract must be active!");
        require(referrer != address(0), "Referrer must be a valid, non-null address!");
        require(referrer != msg.sender, "You cannot be your own referrer!");
        if (referrers[msg.sender] == address(0)) {
            referrers[msg.sender] = referrer;
        }
        require(referrers[msg.sender] == referrer, "Referrer cannot be changed!");

        uint quantity = IERC20(rewardsToken).balanceOf(msg.sender);

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = rewardsToken;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, msg.sender, block.timestamp);

        quantity = IERC20(rewardsToken).balanceOf(msg.sender) - quantity;
        uint256 rewardAmt;
        if(bonusStatus) {
            rewardAmt = (quantity * calculateRewRate(referrer)) / 10000;
        } else {
            rewardAmt = (quantity * baseRateBps) / 10000;
        }

        rewards[referrer] += rewardAmt;

        referrals[referrer].push(Referral(msg.sender, uint48(block.timestamp), msg.value, rewardAmt));

        emit BuyWithReferral(referrer, msg.sender, uint48(block.timestamp), msg.value, quantity, rewardAmt);
    }

//==============================================================================================
//Admin Functions

    function getReferralsCountAdmin(address adr) external view onlyAdminRoles returns (uint) {
        return referrals[adr].length;
    }

    function getRewardsAccumulatedAdmin(address adr) external view onlyAdminRoles returns (uint) {
        return rewards[adr];
    }

    function getReferralsDataAdmin(address adr) external view onlyAdminRoles returns (Referral[] memory) {
        return referrals[adr];
    }

    function getClaimStatusAdmin(address adr) external view onlyAdminRoles returns (bool) {
        return rewards[adr] >= rewardsThreshold;
    }

    function depositRewardsTokens(uint amount) external onlyAdminRoles {
        //Go to the token contract to approve the amount to this contract address.
        //Otherwise, simply use a wallet app of your convenience to send desired amount of tokens to this contract address.
        IERC20(rewardsToken).safeTransferFrom(msg.sender, address(this), amount);

        emit RewardsTokensDeposited(msg.sender, amount);
    }

    function withdrawRewardsTokens(address recipient, uint amount) external onlyOwner {
        if(IERC20(rewardsToken).allowance(address(this), recipient) < amount) {
            IERC20(rewardsToken).safeApprove(recipient, amount);
        }
        IERC20(rewardsToken).safeTransfer(recipient, amount);

        emit RewardsTokensWithdrawn(msg.sender, recipient, amount);
    }

    function withdrawStuckETH(address recipient) external onlyOwner {
        emit ETHWithdrawn(msg.sender, recipient, address(this).balance);

        payable (msg.sender).transfer(address(this).balance);
    }

    function setReferralContractStatus(bool switch_) external onlyOwner {
        require(contractSwitch != switch_, "Already set to desired state!");
        contractSwitch = switch_;

        emit ReferralContractStatusSet(msg.sender, contractSwitch);
    }

    function setTokenContract(address tokenCA_) external onlyOwner {
        require(rewardsToken != tokenCA_, "Already set to desired Token!");
        require(tokenCA_ != address(0), "New token contract must not be a null address!");

        rewardsToken = tokenCA_;
        tokenDecimals = ERC20(tokenCA_).decimals();

        emit TokenContractSet(msg.sender, rewardsToken);
    }

    function setRewardsBaseRateBps(uint16 bps_) external onlyOwner {
        require(bps_ > 0, "Rewards rate cannot be 0!");
        require(bps_ <= 10000, "Rewards rate cannot be above 100%!");

        baseRateBps = bps_;

        emit BaseRateBpsSet(msg.sender, baseRateBps);
    }

    function setRewardsThreshold(uint amount) external onlyOwner {
        require(rewardsThreshold != amount * 10**tokenDecimals, "Already set to desired amount!");

        rewardsThreshold = amount * 10**tokenDecimals;

        emit RewardsThresholdSet(msg.sender, rewardsThreshold);
    }

    function setBonusStatus(bool bonusStatusERC20_, bool bonusStatusERC721_, bool ERC721RewardsByAmt_, bool ERC721RewardsById_) external onlyOwner {
        bonusStatusERC20 = bonusStatusERC20_;

        bonusStatusERC721 = bonusStatusERC721_;
        bonusERC721Amt = ERC721RewardsByAmt_;
        bonusERC721Id = ERC721RewardsById_;

        if(bonusStatusERC20 || bonusStatusERC721) {
            bonusStatus = true;
        } else {
            bonusStatus = false;
        }

        emit BonusStatusSet(msg.sender, bonusStatus, bonusStatusERC20, bonusStatusERC721, bonusERC721Amt, bonusERC721Id);
    }

    function calculateRewRate(address adr) public view returns(uint256) {
        if(bonusStatusERC20 && !bonusStatusERC721) {
            return baseRateBps + getPartnershipBonusBPSERC20(adr);
        } else if(!bonusStatusERC20 && bonusStatusERC721) {
            return baseRateBps + getPartnershipBonusBPSERC721(adr);
        } else if(bonusStatusERC20 && bonusStatusERC721) {
            return baseRateBps + getPartnershipBonusBPSERC20(adr) + getPartnershipBonusBPSERC721(adr);
        }
    }

    function managePartnershipERC20(address tokenCA, uint256 minBronze, uint256 minSilver, 
        uint256 minGold, uint256 minPlatinum, uint256 minDiamond, uint16 BPSBronze,
        uint16 BPSSilver, uint16 BPSGold, uint16 BPSPlatinum, uint16 BPSDiamond)
        external onlyOwner {

        if(verifyPartnershipERC20(tokenCA)){
            maxERC20BonusBPS = maxERC20BonusBPS - partnersERC20[tokenCA].diamondBonusBPSPT;
        }
        if(!verifyPartnershipERC20(tokenCA)){
            PartnerERC20 storage partner = partnersERC20[tokenCA];
            partner.decimalsPT = ERC20(tokenCA).decimals();
            partnershipsERC20.push(tokenCA);
            partnershipIndicesERC20[tokenCA] = partnershipsERC20.length;

            emit NewPartnershipERC20Added(msg.sender, tokenCA);
        }
        uint8 decimals = partnersERC20[tokenCA].decimalsPT;
        partnersERC20[tokenCA].bronzeHReqPT = minBronze * 10**decimals;
        partnersERC20[tokenCA].silverHReqPT = minSilver * 10**decimals;
        partnersERC20[tokenCA].goldHReqPT = minGold * 10**decimals;
        partnersERC20[tokenCA].platinumHReqPT = minPlatinum * 10**decimals;
        partnersERC20[tokenCA].diamondHReqPT = minDiamond * 10**decimals;

        partnersERC20[tokenCA].bronzeBonusBPSPT = BPSBronze;
        partnersERC20[tokenCA].silverBonusBPSPT = BPSSilver;
        partnersERC20[tokenCA].goldBonusBPSPT = BPSGold;
        partnersERC20[tokenCA].platinumBonusBPSPT = BPSPlatinum;
        partnersERC20[tokenCA].diamondBonusBPSPT = BPSDiamond;

        maxERC20BonusBPS += BPSDiamond;

        emit PartnershipERC20Managed(msg.sender, tokenCA);
    }

    function removePartnershipERC20(address tokenCA) external onlyOwner {

        maxERC20BonusBPS = maxERC20BonusBPS - partnersERC20[tokenCA].diamondBonusBPSPT;

        partnershipsERC20[partnershipIndicesERC20[tokenCA]] = partnershipsERC20[partnershipsERC20.length-1];
        partnershipIndicesERC20[partnershipsERC20[partnershipsERC20.length-1]] = partnershipIndicesERC20[tokenCA];
        partnershipsERC20.pop();
        delete partnersERC20[tokenCA];

        emit PartnershipERC20Removed(msg.sender, tokenCA);
    }

    function getPartnershipBonusBPSERC20(address adr) public view returns(uint256) {
        uint8 partnershipCount = uint8(partnershipsERC20.length);
        if(partnershipCount == 0) { return 0; }

        uint8 iterations = 0;
        uint16 bonus = 0;
        uint16 totalBonusBps = 0;
        while(iterations < partnershipCount) {
            IERC20 partner = IERC20(partnershipsERC20[iterations]);
            if(partner.balanceOf(adr) >= partnersERC20[partnershipsERC20[iterations]].diamondHReqPT){
                bonus = partnersERC20[partnershipsERC20[iterations]].diamondBonusBPSPT;
            }   else if(partner.balanceOf(adr) >= partnersERC20[partnershipsERC20[iterations]].platinumHReqPT) {
                    if(partnersERC20[partnershipsERC20[iterations]].platinumBonusBPSPT > bonus) {
                    bonus = partnersERC20[partnershipsERC20[iterations]].platinumBonusBPSPT;
                    }
                }   else if(partner.balanceOf(adr) >= partnersERC20[partnershipsERC20[iterations]].goldHReqPT) {
                        if(partnersERC20[partnershipsERC20[iterations]].goldBonusBPSPT > bonus) {
                        bonus = partnersERC20[partnershipsERC20[iterations]].goldBonusBPSPT;
                        }
                    }   else if(partner.balanceOf(adr) >= partnersERC20[partnershipsERC20[iterations]].silverHReqPT) {
                            if(partnersERC20[partnershipsERC20[iterations]].silverBonusBPSPT > bonus) {
                            bonus = partnersERC20[partnershipsERC20[iterations]].silverBonusBPSPT;
                            }
                        }   else if(partner.balanceOf(adr) >= partnersERC20[partnershipsERC20[iterations]].bronzeHReqPT) {
                                if(partnersERC20[partnershipsERC20[iterations]].bronzeBonusBPSPT > bonus) {
                                bonus = partnersERC20[partnershipsERC20[iterations]].bronzeBonusBPSPT;
                                }
                            } else {
                                bonus = 0;
                            } 
        totalBonusBps += bonus;
        iterations++;
        }
        return totalBonusBps;
    }

    function getPartnershipCountERC20() external view returns(uint256) {
        return partnershipsERC20.length;
    }

    function verifyPartnershipERC20(address token) public view returns(bool) {
        if(partnershipsERC20.length == 0) { return false; }

        uint256 iterations = 0;

        while(iterations < partnershipsERC20.length) {
            if(partnershipsERC20[iterations] == token) {return true;}
            iterations++;
        }
        return false;
    }


    function managePartnershipERC721Amt(address tokenCA, uint32 minSilver, 
        uint32 minGold, uint32 minPlatinum, uint32 minDiamond,
        uint16 BPSSilver, uint16 BPSGold, uint16 BPSPlatinum, uint16 BPSDiamond)
        external onlyOwner {

        if(verifyPartnershipERC721(tokenCA)){
            maxERC721BonusBPS = maxERC721BonusBPS - partnersERC721[tokenCA].diamondBonusBPSPT;
        }
        if(!verifyPartnershipERC721(tokenCA)){
            partnershipsERC721.push(tokenCA);
            partnershipIndicesERC721[tokenCA] = partnershipsERC721.length;
            emit NewPartnershipERC721Added(msg.sender, tokenCA);
        }
        partnersERC721[tokenCA].silverHReqAmt = minSilver;
        partnersERC721[tokenCA].goldHReqAmt = minGold;
        partnersERC721[tokenCA].platinumHReqAmt = minPlatinum;
        partnersERC721[tokenCA].diamondHReqAmt = minDiamond;

        partnersERC721[tokenCA].silverBonusBPSPT = BPSSilver;
        partnersERC721[tokenCA].goldBonusBPSPT = BPSGold;
        partnersERC721[tokenCA].platinumBonusBPSPT = BPSPlatinum;
        partnersERC721[tokenCA].diamondBonusBPSPT = BPSDiamond;

        maxERC721BonusBPS += BPSDiamond;

        emit PartnershipERC721AmountManaged(msg.sender, tokenCA);
    }

    function managePartnershipERC721Id(address tokenCA, uint32 minSilverId, 
        uint32 minGoldId, uint32 minPlatinumId, uint32 minDiamondId,
        uint16 BPSSilver, uint16 BPSGold, uint16 BPSPlatinum, uint16 BPSDiamond)
        external onlyOwner {

        if(verifyPartnershipERC721(tokenCA)){
            maxERC721BonusBPS = maxERC721BonusBPS - partnersERC721[tokenCA].diamondBonusBPSPT;
        }
        if(!verifyPartnershipERC721(tokenCA)){
            partnershipsERC721.push(tokenCA);
            partnershipIndicesERC721[tokenCA] = partnershipsERC721.length;
            emit NewPartnershipERC721Added(msg.sender, tokenCA);
        }
        partnersERC721[tokenCA].silverHReqId = minSilverId;
        partnersERC721[tokenCA].goldHReqId = minGoldId;
        partnersERC721[tokenCA].platinumHReqId = minPlatinumId;
        partnersERC721[tokenCA].diamondHReqId = minDiamondId;

        partnersERC721[tokenCA].silverBonusBPSPT = BPSSilver;
        partnersERC721[tokenCA].goldBonusBPSPT = BPSGold;
        partnersERC721[tokenCA].platinumBonusBPSPT = BPSPlatinum;
        partnersERC721[tokenCA].diamondBonusBPSPT = BPSDiamond;

        maxERC721BonusBPS += BPSDiamond;

        emit PartnershipERC721IDManaged(msg.sender, tokenCA);
    }

    function removePartnershipERC721(address tokenCA) external onlyOwner {

        maxERC721BonusBPS = maxERC721BonusBPS - partnersERC721[tokenCA].diamondBonusBPSPT;

        partnershipsERC721[partnershipIndicesERC721[tokenCA]] = partnershipsERC721[partnershipsERC721.length-1];
        partnershipIndicesERC721[partnershipsERC721[partnershipsERC721.length-1]] = partnershipIndicesERC721[tokenCA];
        partnershipsERC721.pop();
        delete partnersERC721[tokenCA];

        emit PartnershipERC721Removed(msg.sender, tokenCA);
    }

    function getPartnershipBonusBPSERC721(address adr) public view returns(uint16) {
        uint8 partnershipCount = uint8(partnershipsERC721.length);
        if(partnershipCount == 0) { return 0; }

        uint16 totalBonusBps = 0;

        if (bonusERC721Amt) {
            uint8 iterations = 0;
            uint16 bonus = 0;
            while(iterations < partnershipCount) {
                IERC721 partner = IERC721(partnershipsERC721[iterations]);
                if(partner.balanceOf(adr) >= partnersERC721[partnershipsERC721[iterations]].diamondHReqAmt){
                    bonus = partnersERC721[partnershipsERC721[iterations]].diamondBonusBPSPT;
                }   else if(partner.balanceOf(adr) >= partnersERC721[partnershipsERC721[iterations]].platinumHReqAmt) {
                        if(partnersERC721[partnershipsERC721[iterations]].platinumBonusBPSPT > bonus) {
                        bonus = partnersERC721[partnershipsERC721[iterations]].platinumBonusBPSPT;
                        }
                    }   else if(partner.balanceOf(adr) >= partnersERC721[partnershipsERC721[iterations]].goldHReqAmt) {
                            if(partnersERC721[partnershipsERC721[iterations]].goldBonusBPSPT > bonus) {
                            bonus = partnersERC721[partnershipsERC721[iterations]].goldBonusBPSPT;
                            }
                        }   else if(partner.balanceOf(adr) >= partnersERC721[partnershipsERC721[iterations]].silverHReqAmt) {
                                if(partnersERC721[partnershipsERC721[iterations]].silverBonusBPSPT > bonus) {
                                bonus = partnersERC721[partnershipsERC721[iterations]].silverBonusBPSPT;
                                }
                            } else {
                                    bonus = 0;
                                } 
            totalBonusBps += bonus;
            iterations++;
            }         
        }

        if (bonusERC721Id) {
            uint16 iterations = 0;
            while(iterations < partnershipCount) {
                IERC721 partner = IERC721(partnershipsERC721[iterations]);
                totalBonusBps += getERC721IdBps(adr, partnershipsERC721[iterations], partner.balanceOf(adr));
                iterations++;
            }
        }

        return totalBonusBps;
    }

    function getERC721IdBps(address adr, address tokenCA, uint256 tokenBalance) internal view returns(uint16) {
        IERC721Enumerable ipartner = IERC721Enumerable(tokenCA);
        uint16 bonus = 0;
                for (uint16 index = 0; index < tokenBalance; index++) {
                    if(ipartner.tokenOfOwnerByIndex(adr, index) <= partnersERC721[tokenCA].diamondHReqId){
                        return partnersERC721[tokenCA].diamondBonusBPSPT;
                    }   else if(ipartner.tokenOfOwnerByIndex(adr, index) <= partnersERC721[tokenCA].platinumHReqId) {
                            bonus = partnersERC721[tokenCA].platinumBonusBPSPT;
                        }   else if(ipartner.tokenOfOwnerByIndex(adr, index) <= partnersERC721[tokenCA].goldHReqId) {
                                if(partnersERC721[tokenCA].goldBonusBPSPT > bonus) {
                                bonus = partnersERC721[tokenCA].goldBonusBPSPT;
                                }
                            }   else if(ipartner.tokenOfOwnerByIndex(adr, index) <= partnersERC721[tokenCA].silverHReqId) {
                                    if(partnersERC721[tokenCA].silverBonusBPSPT > bonus) {
                                    bonus = partnersERC721[tokenCA].silverBonusBPSPT;
                                    }
                                }
                }
        return bonus;
    }

    function getPartnershipCountERC721() external view returns(uint256) {
        return partnershipsERC721.length;
    }

    function verifyPartnershipERC721(address token) public view returns(bool) {
        if(partnershipsERC721.length == 0) { return false; }

        uint256 iterations = 0;

        while(iterations < partnershipsERC721.length) {
            if(partnershipsERC721[iterations] == token) {return true;}
            iterations++;
        }
        return false;
    }

    receive() payable external {}
}