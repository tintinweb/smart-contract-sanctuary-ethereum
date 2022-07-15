/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @openzeppelin/contracts-upgradeable/introspection/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/introspection/[email protected]


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(address(0)).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(address(0)).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/cryptography/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interfaces/IHordTreasury.sol

pragma solidity 0.6.12;

/**
 * IHordTreasury contract.
 * @author Nikola Madjarevic
 * Date created: 14.7.21.
 * Github: madjarevicn
 */
interface IHordTreasury {
    function depositToken(address token, uint256 amount) external;
}


// File contracts/interfaces/IHordConfiguration.sol

pragma solidity 0.6.12;

/**
 * IHordConfiguration contract.
 * @author Nikola Madjarevic
 * Date created: 4.8.21.
 * Github: madjarevicn
 */
interface IHordConfiguration {
    function hordToken() external view returns(address);
    function minChampStake() external view returns(uint256);
    function minFollowerUSDStake() external view returns(uint256);
    function maxFollowerUSDStake() external view returns(uint256);
    function gasUtilizationRatio() external view returns(uint256);
    function percentPrecision() external view returns(uint256);
    function maxUSDAllocationPerTicket() external view returns (uint256);
    function totalSupplyHPoolTokens() external view returns (uint256);
    function ticketSaleDurationSecs() external view returns (uint256);
    function privateSubscriptionDurationSecs() external view returns (uint256);
    function publicSubscriptionDurationSecs() external view returns (uint256);
    function maxDurationValue() external view returns (uint256);
    function percentBurntFromPublicSubscription() external view returns (uint256);
    function championFeePercent() external view returns (uint256);
    function protocolFeePercent() external view returns (uint256);
    function tradingFeePercent() external view returns (uint256);
    function minTimeToStake() external view returns (uint256);
    function minAmountToStake() external view returns (uint256);
    function platformStakeRatio() external view returns (uint256);
    function calculateTradingFee(uint256 amount) external view returns (uint256);
    function exitFeeAmount(uint256 usdAmountWei) external view returns (uint256);
}


// File contracts/interfaces/IHPoolFactory.sol

pragma solidity 0.6.12;


/**
 * IHPoolFactory contract.
 * @author Nikola Madjarevic
 * Date created: 29.7.21.
 * Github: madjarevicn
 */
interface IHPoolFactory {
    function deployHPool(
        uint256 hPoolId,
        uint256 bePoolId,
        address championAddress,
        address uniswapRouter
    )
    external
    returns (address);

    function hPoolHelper() external view returns(address);
}


// File contracts/interfaces/IHPoolHelper.sol

pragma solidity 0.6.12;


interface IHPoolHelper {
    function useNonce(uint256 poolNonce, address hPool) view external;
    function isChampionAddress(address signer, address hPool) view external;
    function getBestBuyRoute(address token) view external returns(address[] memory);
    function getBestSellRoute(address token)  view external returns(address[] memory);
}


// File contracts/interfaces/IVPoolConfiguration.sol

pragma solidity 0.6.12;

interface IVPoolConfiguration {
    function hordToken() external view returns(address);
    function baseToken() external view returns(address);
    function hordChampion() external view returns(address);
    function minChampStake() external view returns(uint256);
    function minFollowerUSDStake() external view returns(uint256);
    function maxFollowerUSDStake() external view returns(uint256);
    function gasUtilizationRatio() external view returns(uint256);
    function percentPrecision() external view returns(uint256);
    function totalSupplyVPoolTokens() external view returns (uint256);
    function whitelistingDurationSecs() external view returns (uint256);
    function maxDurationValue() external view returns (uint256);
    function vPoolSubscriptionDurationSecs() external view returns (uint256);
    function platformStakeRatio() external view returns (uint256);
    function maxUserParticipation() external view returns (uint256);
    function minUserParticipation() external view returns (uint256);
    function timeToAcceptOpenOrders() external view returns (uint256);
    function maxOfProjectTokens() external view returns (uint256);
}


// File contracts/interfaces/IPool.sol

pragma solidity 0.6.12;


/**
 * IHPool contract.
 * @author Nikola Madjarevic
 * Date created: 29.7.21.
 * Github: madjarevicn
 */
interface IPool {

    function initialize(
        uint256 _hPoolId,
        uint256 _bePoolId,
        address _hordCongress,
        address _hordMaintainersRegistry,
        address _hordPoolManager,
        address _championAddress,
        address _signatureValidator,
        address _hPoolImplementation,
        address _hPoolHelper,
        address uniswapRouter
    ) external;
    function depositBudget(uint256 usdValueWei, uint256 totalDeposit) external payable;
    function mintHPoolToken(
        string memory name,
        string memory symbol,
        uint256 _totalSupply,
        address hordConfiguration,
        address matchingMarket
    ) external;
    function swapExactTokensForTokens(
        address[] memory path,
        address token,
        bool isWETHSource,
        uint256 amountSrc,
        uint256 minAmountOut,
        bool isLiquidation
    ) external returns (uint256);
    function isPoolEnded() external view returns (bool);
    function championAddress() external view returns (address);
    function bePoolId() external view returns (uint256);
    function totalBaseAssetAtLaunch() external view returns (uint256);
    function paused() external view returns (bool);
}


// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.6.12;

/**
 * IMaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/HordUpgradable.sol

pragma solidity 0.6.12;

/**
 * HordUpgradables contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    event MaintainersRegistrySet(address maintainersRegistry);
    event CongressAndMaintainersSet(address hordCongress, address maintainersRegistry);

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "Hord: Restricted only to Maintainer");
        _;
    }

    // Only chainport congress modifier
    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "Hord: Restricted only to HordCongress");
        _;
    }

    modifier onlyHordCongressOrMaintainer {
        require(msg.sender == hordCongress || maintainersRegistry.isMaintainer(msg.sender),
            "Hord: Only Congress or Maintainer."
        );
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        require(_hordCongress != address(0), "HordCongress can not be 0x0 address");
        require(_maintainersRegistry != address(0), "MaintainersRegistry can not be 0x0 address");

        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);

        emit CongressAndMaintainersSet(hordCongress, address(maintainersRegistry));
    }

}


// File contracts/pools/VPoolManager.sol

pragma solidity 0.6.12;











/**
 * VPoolManager contract.
 * @author Srdjan Simonovic
 * Date created: 15.03.22.
 * Github: s2imonovic
 */
contract VPoolManager is HordUpgradable, ReentrancyGuardUpgradeable {

    using SafeMath for *;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    // States of the pool contract
    enum PoolState {
        PENDING_INIT,
        WHITELISTING,
        VPOOL_SUBSCRIPTION,
        SUBSCRIPTION_FAILED,
        ASSET_STATE_TRANSITION_IN_PROGRESS,
        ACTIVE
    }

    // Address for HORD token
    address public hordToken;
    // Address for base token
    address public baseToken;
    // Address matchingMarket contract
    address public matchingMarket;
    // Constant, representing 1ETH in WEI units.
    uint256 public constant one = 1e18;

    // Subscription struct, represents subscription of user
    struct Subscription {
        address user;
        uint256 amountUsd;
        bool isSubscriptionWithdrawnPoolTerminated;
    }

    // VPool struct
    struct vPool {
        PoolState poolState;
        address championAddress;
        address poolContractAddress;
        uint256 createdAt;
        uint256 endTimeWhitelisting;
        uint256 startTimeVPoolSubscription;
        uint256 endTimeVPoolSubscription;
        uint256 treasuryFeePaid;
        uint256 bePoolId;
        uint256 followersUSDDeposit;
    }

    // Instance of VPool Configuration contract
    IVPoolConfiguration vPoolConfiguration;
    // Instance of uniswap
    IUniswapV2Router02 public uniswapRouter;
    // Instance of Hord treasury contract
    IHordTreasury hordTreasury;
    // Instance of HPool Factory contract
    IHPoolFactory hPoolFactory;

    // All vPools
    vPool[] public vPools;
    // All VPoolTokens
    mapping(address => bool) public isVPoolToken;
    //Number of subscriptions on vPool
    mapping(uint256 => uint256) public numberOfSubscriptions;
    // Map user address to pool id to his subscription for that pool
    mapping(address => mapping(uint256 => Subscription)) internal userToPoolIdToSubscription;
    // Mapping user to ids of all pools he has subscribed for
    mapping(address => uint256[]) internal userToPoolIdsSubscribedFor;
    // Support listing pools per champion
    mapping(address => uint256[]) internal championAddressToVPoolIds;
    // Store whitelisted addresses
    mapping(address => bool) public isWhitelisted;

    /**
        * Events
     */
    event PoolInitRequested(
        uint256 poolId,
        address champion,
        uint256 timestamp,
        uint256 bePoolId
    );
    event VPoolStateChanged(uint256 poolId, PoolState newState);
    event Subscribed(
        uint256 poolId,
        address user,
        uint256 amountUSD
    );
    event SubscriptionWithdrawn(
        address user,
        uint256 poolId,
        uint256 amountUsd
    );

    event ServiceFeePaid(uint256 poolId, uint256 amount);
    event VPoolLaunchFailed(uint256 poolId);
    event MatchingMarketSet(address matchingMarketSet);
    event UniswapRouterSet(address uniswapRouter);
    event WhitelistStatusChanged(address _address, bool status);

    /**
         * @notice          Function to check is contract with exact poolId exists.
         * @param           poolId is the ID of the pool contract.
     */
    modifier isPoolIdValid(uint256 poolId) {
        require(poolId < vPools.length, "vPool with poolId does not exist.");
        _;
    }

    /**
         * @notice          Initializer function, can be called only once, replacing constructor
         * @param           _hordCongress is the address of HordCongress contract
         * @param           _maintainersRegistry is the address of the MaintainersRegistry contract
         * @param           _hordTreasury is the address of the HordTreasury contract
         * @param           _hPoolFactory is the address of the HPoolFactory contract
         * @param           _uniswapRouter is the address of the UniswapRouter contract
         * @param           _vPoolConfiguration is the address of the VPoolConfiguration contract
     */
    function initialize(
        address _hordCongress,
        address _maintainersRegistry,
        address _hordTreasury,
        address _hPoolFactory,
        address _uniswapRouter,
        address _vPoolConfiguration
    )
    external
    initializer
    {
        require(_vPoolConfiguration != address(0), "VPoolConfiguration can not be 0x0 address");

        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);

        __ReentrancyGuard_init();

        vPoolConfiguration = IVPoolConfiguration(_vPoolConfiguration);
        hordToken = vPoolConfiguration.hordToken();
        baseToken = vPoolConfiguration.baseToken();

        hordTreasury = IHordTreasury(_hordTreasury);
        hPoolFactory = IHPoolFactory(_hPoolFactory);

        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    /**
     * @notice          Internal function to pay service to hord treasury contract
     */
    function payServiceFeeToTreasury(
        uint256 poolId,
        uint256 amount
    )
    internal
    isPoolIdValid(poolId)
    {
        IERC20(baseToken).safeApprove(address(hordTreasury), amount);
        hordTreasury.depositToken(baseToken, amount);

        emit ServiceFeePaid(poolId, amount);
    }

    function setActivityForExactHPool(
        uint256 poolId,
        bool paused
    )
    external
    isPoolIdValid(poolId)
    {
        vPool storage vp = vPools[poolId];
        require(msg.sender == vp.poolContractAddress, "Caller is not VPool contract");

        if(paused) {
            vp.poolState = PoolState.ASSET_STATE_TRANSITION_IN_PROGRESS;
        } else {
            vp.poolState = PoolState.ACTIVE;
        }
    }

    /**
     * @notice          Function to set matchingMarket contract address
     */
    function setMatchingMarket(
        address _matchingMarket
    )
    external
    onlyHordCongress
    {
        require(_matchingMarket != address(0), "MatchingMarket can not be 0x0 address.");
        matchingMarket = _matchingMarket;

        isWhitelisted[_matchingMarket] = true;

        emit MatchingMarketSet(_matchingMarket);
    }

    /**
     * @notice          Function to set uniswap router
     */
    function setUniswapRouter(
        address _uniswapRouter
    )
    public
    onlyHordCongress
    {
        require(_uniswapRouter != address(0), "Uniswap router can not be 0x0 address.");
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        emit UniswapRouterSet(_uniswapRouter);
    }

    /**
         * @notice          Function where champion can create his pool.
         *                  In case champion is not approved, maintainer can cancel his pool creation,
         *                  and return him back the funds.
         * @param           bePoolId is value from BE which is used for signing transaction
     */
    function createPool(
        uint256 bePoolId
    )
    external
    {
        require(msg.sender == vPoolConfiguration.hordChampion(), "Wrong champion address.");
        // Create vPool structure
        vPool memory vp;

        vp.poolState = PoolState.PENDING_INIT;
        vp.championAddress = msg.sender;
        vp.createdAt = block.timestamp;
        vp.bePoolId = bePoolId;

        // Compute ID to match position in array
        uint256 poolId = vPools.length;
        // Push vPool structure
        vPools.push(vp);

        // Add Id to list of ids for champion
        championAddressToVPoolIds[msg.sender].push(poolId);

        // Trigger events
        emit PoolInitRequested(
            poolId,
            msg.sender,
            block.timestamp,
            bePoolId
        );

        emit VPoolStateChanged(poolId, vp.poolState);
    }
/**
         * @notice          Function to start whitelisting phase. Can be started only if current
         *                  state of the vPool is PENDING_INIT.
         * @param           poolId is the ID of the pool contract.
     */
    function startWhitelistingPhase(
        uint256 poolId
    )
    external
    onlyMaintainer
    isPoolIdValid(poolId)
    {
        vPool storage vp = vPools[poolId];

        require(vp.poolState == PoolState.PENDING_INIT, "vPool is not in PENDING_INIT state.");
        vp.poolState = PoolState.WHITELISTING;
        vp.endTimeWhitelisting = block.timestamp.add(vPoolConfiguration.whitelistingDurationSecs());

        emit VPoolStateChanged(poolId, vp.poolState);
    }

    /**
         * @notice          Function to start vPool subscription phase. Can be started only if current
         *                  state of the vPool is WHITELISTING.
         * @param           poolId is the ID of the pool contract.
     */
    function startVPoolSubscriptionPhase(
        uint256 poolId
    )
    external
    onlyMaintainer
    isPoolIdValid(poolId)
    {
        vPool storage vp = vPools[poolId];

        require(vp.poolState == PoolState.WHITELISTING, "vPool is not in WHITELISTING state.");
        require(block.timestamp > vp.endTimeWhitelisting, "Whitelisting phase is not finished yet.");
        vp.poolState = PoolState.VPOOL_SUBSCRIPTION;
        vp.startTimeVPoolSubscription = block.timestamp;
        vp.endTimeVPoolSubscription = block.timestamp.add(vPoolConfiguration.vPoolSubscriptionDurationSecs());

        emit VPoolStateChanged(poolId, vp.poolState);
    }

    function subscribeForVPool(
        bytes memory signature,
        uint256 poolId,
        uint256 amountUsd
    )
    external
    isPoolIdValid(poolId)
    nonReentrant
    {
        require(verifyWhitelistSignature(signature, poolId, msg.sender), "Invalid signer address.");
        require(
            amountUsd >= vPoolConfiguration.minUserParticipation() &&
            amountUsd <= vPoolConfiguration.maxUserParticipation(),
            "Wrong amount."
        );

        vPool storage vp = vPools[poolId];

        require(
            vp.poolState == PoolState.VPOOL_SUBSCRIPTION,
            "vPool is not in VPOOL_SUBSCRIPTION state."
        );
        require(
            msg.sender != vp.championAddress,
            "Msg.sender is champion"
        );
        require(msg.sender == tx.origin, "Only direct calls.");
        require(
            block.timestamp <= vp.endTimeVPoolSubscription,
            "The time has elapsed for the vPool subscription phase."
        );

        Subscription memory s = userToPoolIdToSubscription[msg.sender][poolId];
        require(s.amountUsd == 0, "User can not subscribe more than once.");

        s.amountUsd = amountUsd;
        s.user = msg.sender;

        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amountUsd);

        // Store subscription
        numberOfSubscriptions[poolId] = numberOfSubscriptions[poolId].add(1);
        userToPoolIdToSubscription[msg.sender][poolId] = s;
        userToPoolIdsSubscribedFor[msg.sender].push(poolId);

        vp.followersUSDDeposit = vp.followersUSDDeposit.add(s.amountUsd);

        emit Subscribed(
            poolId,
            msg.sender,
            s.amountUsd
        );
    }

    /**
         * @notice          Maintainer should end subscription phase in case all the criteria is reached
         * @param           poolId is the ID of the pool contract.
         * @param           name is the name of the VPoolToken.
         * @param           symbol is the symbol of the VPoolToken.
     */
    function endSubscriptionPhaseAndInitVPool(
        uint256 poolId,
        string memory name,
        string memory symbol
    )
    external
    onlyMaintainer
    isPoolIdValid(poolId)
    {
        vPool storage vp = vPools[poolId];
        require(
            (vp.poolState == PoolState.VPOOL_SUBSCRIPTION && vp.endTimeVPoolSubscription < block.timestamp),
            "Conditions for init vPool are not met."
        );
        require(
            vp.followersUSDDeposit >= vPoolConfiguration.minFollowerUSDStake() &&
            vp.followersUSDDeposit <= vPoolConfiguration.maxFollowerUSDStake(),
            "vPool subscription amount is below threshold."
        );

        vp.poolState = PoolState.ASSET_STATE_TRANSITION_IN_PROGRESS;

        // Deploy the VPool contract
        IPool poolContract = IPool(
            hPoolFactory.deployHPool(
                poolId,
                vp.bePoolId,
                vp.championAddress,
                address(uniswapRouter)
            )
        );

        //Mint VPoolToken for certain VPool
        poolContract.mintHPoolToken(name, symbol, vp.followersUSDDeposit, address(vPoolConfiguration), address(matchingMarket));

        // Add vPoolContract on white list
        isWhitelisted[address(poolContract)] = true;
        // Store addresses of all VPoolTokens
        isVPoolToken[address(poolContract)] = true;
        // Set the deployed address of VPool
        vp.poolContractAddress = address(poolContract);

        // Compute treasury fee
        uint256 treasuryFeeETH = vp
            .followersUSDDeposit
            .mul(vPoolConfiguration.gasUtilizationRatio())
            .div(vPoolConfiguration.percentPrecision());

        payServiceFeeToTreasury(poolId, treasuryFeeETH);

        uint256 amountUSDAfterFees = vp.followersUSDDeposit.sub(treasuryFeeETH);

        IERC20(baseToken).safeTransfer(address(poolContract), amountUSDAfterFees);

        poolContract.depositBudget(amountUSDAfterFees, vp.followersUSDDeposit);

        vp.treasuryFeePaid = treasuryFeeETH;

        // Trigger event that pool state is changed
        emit VPoolStateChanged(poolId, vp.poolState);
    }

    /**
         * @notice          Function terminates vPool if subscription amount is below threshold.
         * @param           poolId is the ID of the pool contract.
     */
    function endSubscriptionPhaseAndTerminatePool(
        uint256 poolId
    )
    external
    onlyMaintainer
    isPoolIdValid(poolId)
    {
        vPool storage vp = vPools[poolId];

        require(
            (vp.poolState == PoolState.VPOOL_SUBSCRIPTION && vp.endTimeVPoolSubscription < block.timestamp),
            "Conditions for init vPool are not met."
        );
        require(
            vp.followersUSDDeposit < vPoolConfiguration.minFollowerUSDStake() ||
            vp.followersUSDDeposit > vPoolConfiguration.maxFollowerUSDStake(),
            "vPool subscription amount is below / above threshold."
        );

        // Set new pool state
        vp.poolState = PoolState.SUBSCRIPTION_FAILED;

        // Trigger event
        emit VPoolStateChanged(poolId, vp.poolState);
        emit VPoolLaunchFailed(poolId);
    }

    /**
         * @notice          Function to withdraw deposit. It can be called whenever after subscription phase.
         * @param           poolId is the ID of the pool for which user is withdrawing.
     */
    function withdrawDeposit(
        uint256 poolId
    )
    external
    isPoolIdValid(poolId)
    nonReentrant
    {
        vPool memory vp = vPools[poolId];
        Subscription storage s = userToPoolIdToSubscription[msg.sender][poolId];

        require(
            vp.poolState == PoolState.SUBSCRIPTION_FAILED,
            "Pool is not in valid state."
        );
        require(
            !s.isSubscriptionWithdrawnPoolTerminated,
            "Subscription already withdrawn"
        );

        // Mark that user withdrawn his subscription.
        s.isSubscriptionWithdrawnPoolTerminated = true;
        // Transfer subscription back to user
        IERC20(baseToken).safeTransfer(msg.sender, s.amountUsd);

        // Fire SubscriptionWithdrawn event
        emit SubscriptionWithdrawn(
            msg.sender,
            poolId,
            s.amountUsd
        );
    }

    function verifyWhitelistSignature(
        bytes memory signature,
        uint256 poolId,
        address userAddress
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(poolId, userAddress)
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return maintainersRegistry.isMaintainer(messageHash.recover(signature));
    }

    /**
        * @notice  Function to add white list status to
        * @param   _address is address to be given white list status
     */
    function addWhitelistStatus(
        address _address
    )
    external
    onlyHordCongress
    {
        isWhitelisted[_address] = true;
        emit WhitelistStatusChanged(_address, true);
    }

    /**
        * @notice  Function to remove white list status
        * @param   _address is address to be remove white list status
     */
    function removeWhitelistStatus(
        address _address
    )
    external
    onlyHordCongress
    {
        isWhitelisted[_address] = false;
        emit WhitelistStatusChanged(_address, false);
    }

    /**
        * @notice          Function to get IDs of all pools for the champion.
     */
    function getChampionPoolIds(
        address champion
    )
    external
    view
    returns (uint256[] memory)
    {
        return championAddressToVPoolIds[champion];
    }

    /**
        * @notice          Function to get IDs of pools for which user subscribed
     */
    function getPoolsUserSubscribedFor(
        address user
    )
    external
    view
    returns (uint256[] memory)
    {
        return userToPoolIdsSubscribedFor[user];
    }

    /**
         * @notice          Function to get user subscription for the pool.
         * @param           poolId is the ID of the pool
         * @param           user is the address of user
         * @return          amount of ETH user deposited and number of tickets taken from user.
     */
    function getUserSubscriptionForPool(
        uint256 poolId,
        address user
    )
    external
    view
    returns (uint256, bool)
    {
        Subscription memory subscription = userToPoolIdToSubscription[user][poolId];

        return (subscription.amountUsd, subscription.isSubscriptionWithdrawnPoolTerminated);
    }

    /**
         * @notice          Function to get information for specific pool
         * @param           poolId is the ID of the pool
     */
    function getPoolInfo(uint256 poolId)
    external
    view
    returns (
        uint256,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        // Load pool into memory
        vPool memory vp = vPools[poolId];

        return (
            uint256(vp.poolState),
            vp.championAddress,
            vp.poolContractAddress,
            vp.createdAt,
            vp.treasuryFeePaid,
            vp.endTimeWhitelisting,
            vp.endTimeVPoolSubscription,
            vp.startTimeVPoolSubscription
        );
    }

}