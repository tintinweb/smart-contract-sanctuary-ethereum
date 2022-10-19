/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: contracts\IToken.sol

pragma solidity ^0.8.0;
interface IToken is IERC20{
    
    struct externalPosition{
        address externalContract;
        uint256 id;
    }

    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _quantity) external;

    function approveComponent(address _token, address _spender, uint256 _amount) external;

    function getComponents() external view returns(address[] memory);

    function getExternalComponents() external view returns(externalPosition[] memory);

    function getShare(address _component) external view returns(uint);

    function editComponent(address _component, uint256 _amount) external;

    function getCumulativeShare() external view returns(uint256);

    function basePrice() external view returns(uint256);

    function addNode(address _node) external;

    function updateTransferFee(uint256 newFee) external;
    
    function editFeeWallet(address newWallet) external;
}

// File: contracts\exchange\MinimalSwap.sol

pragma solidity ^0.8.0;

interface IUniswapV2Pair { 
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface WETH9{
    function deposit() external payable;
    function withdraw(uint wad) external;
    function balanceOf(address account) external returns(uint256);
    function approve(address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 wad) external;
    function transfer(address to, uint256 amount) external;
    function totalSupply() external view returns(uint256);
}

contract MinimalSwap{
    
    WETH9 WETH;

    constructor(address _WETH){
        WETH = WETH9(_WETH);
    }

    function _getAmountOut(address pool, uint256 amountIn, bool fromWETH) internal view returns(uint256){
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (reserve0, reserve1) = pair.token0() == address(WETH) 
        ? fromWETH ? (reserve0, reserve1) : (reserve1, reserve0)
        : fromWETH ? (reserve1, reserve0) : (reserve0, reserve1);
        uint256 aInFee = amountIn * 997;
        uint256 numerator =  aInFee * reserve1;
        uint256 denominator = (reserve0 * 1000) + aInFee;
        return numerator/denominator;
    }

    //From should be address for all cases, but redeem
    function _rawPoolSwap(address poolAddr, uint256 amountIn, address to, address from, bool fromWETH) internal returns(uint256) {
        uint256 amountOut = _getAmountOut(poolAddr, amountIn, fromWETH);
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
        (address token0, address token1) = (pool.token0(), pool.token1());
        WETH9 tokenIn = fromWETH ? WETH : token0 == address(WETH) ? WETH9(token1) : WETH9(token0);
        (uint256 amount0out, uint256 amount1out) = address(tokenIn) == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        tokenIn.transferFrom(from, poolAddr, amountIn);
        pool.swap(amount0out, amount1out, to, new bytes(0));
        return amountOut;
    }

    function _getPoolToken(address pool) internal view returns(address token){
        (address token0, address token1) = (IUniswapV2Pair(pool).token0(), IUniswapV2Pair(pool).token1());
        token = token0 == address(WETH) ? token1 : token0;
    }
}

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin\contracts\utils\introspection\ERC165.sol


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

// File: @openzeppelin\contracts\token\ERC1155\utils\ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin\contracts\token\ERC1155\utils\ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin\contracts\utils\Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin\contracts\utils\cryptography\ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: @openzeppelin\contracts\security\ReentrancyGuard.sol


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

// File: contracts\nodes\IssuanceManagerNode.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IHostChainManager{
    function getPendingWeth(uint256 id) external view returns(uint256);
    function depositWETH(uint256 chainId) external payable;
    function withdrawFunds(uint256 amtToken, uint256 id, address toUser) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data) external;
}

contract IssuanceManagerBeta is MinimalSwap, ERC1155Holder, ReentrancyGuard{
    using ECDSA for bytes32;

    uint256 private constant PRECISION = 10 ** 12;
    address private externalSigner;
    uint256 private scMin;

    constructor(address _WETH, uint256 _scMin) MinimalSwap(_WETH){
        externalSigner = msg.sender;
        scMin = _scMin;
    }

    function _executeswap(address component, uint256 cumulativeShare, uint256 msgVal, IToken indexToken)
     private returns(uint256 amountOut) {
        uint256 share = indexToken.getShare(component);
        uint256 value = (msgVal * share) / cumulativeShare;

        return _rawPoolSwap(component, value, address(indexToken), address(this), true);
    }

    function _executeSwaptoETH(address pool, uint256 indexQty, IToken indexToken)
     private returns(uint256 amountOut){
        address token = _getPoolToken(pool);
        uint256 amountIn = IERC20(token).balanceOf(address(indexToken));
        // 0 index qty signals an exit
        if(indexQty > 0){
            // % of supply/ownership of index * balance of given token 
            amountIn = (indexQty * amountIn) / indexToken.totalSupply();
        }

        indexToken.approveComponent(token, address(this), amountIn);
        //IERC20(token).transferFrom(address(indexToken), address(this), amountIn);

        amountOut = _rawPoolSwap(pool, amountIn, address(this), address(indexToken), false);
    }

    function _executeExternalSwaptoETH(IToken indexToken, IToken.externalPosition memory position, uint256 qty, address to)
     private {
        uint256 amountIn = IHostChainManager(position.externalContract).balanceOf(address(indexToken), uint256(position.id));
        if(qty > 0){
            amountIn = (qty * amountIn) / indexToken.totalSupply();
        }
        IHostChainManager(position.externalContract).safeTransferFrom(address(indexToken), address(this), uint256(position.id), amountIn, "");
        IHostChainManager(position.externalContract).withdrawFunds(amountIn, uint256(position.id), to);
    }
    
    function _swapEthForAll(IToken indexToken, uint256 ethVal,
        address[] memory components, IToken.externalPosition[] memory _externals)
        private {

        uint256 cumulativeShare = indexToken.getCumulativeShare();
        uint256 externalWeth = 0;
        //TODO: batching here can save gas
        for(uint i =0; i < _externals.length; i++){
            IToken.externalPosition memory position = _externals[i];
            uint256 share = _getExternalShare(indexToken,  position.externalContract, position.id);
            uint256 val = (ethVal * share) / cumulativeShare;
            require(val >= scMin, "Insufficient side chain bridge amount, add additional value");
            IHostChainManager(position.externalContract).depositWETH{value: val}(position.id);
            externalWeth += val;
        }

        WETH.deposit{value: msg.value - externalWeth}();
        //Buy each component
        for(uint i = 0; i<components.length; i++){
            _executeswap(components[i], cumulativeShare, ethVal, indexToken);
        }
    }

    function _getExternalShare(IToken indexToken, address contractAddress, uint256 id)
     private view returns (uint256){
        address uid = address(uint160(uint256(keccak256(abi.encode(contractAddress, id)))));
        return indexToken.getShare(uid);
    }

    function _valueSet(IToken indexToken, address[] memory components,
     IToken.externalPosition[] memory _externals, uint256[] memory externalValues)
     private view returns (uint256 wethValue){
        wethValue = 0;
        for (uint i = 0; i < components.length; i++){
            uint256 bal = IERC20(_getPoolToken(components[i])).balanceOf(address(indexToken));
            wethValue += _getAmountOut(components[i], bal, false);
        }
        for(uint i = 0; i < _externals.length; i++){
            uint256 bal = IHostChainManager(_externals[i].externalContract).balanceOf(address(indexToken), _externals[i].id);
            uint256 pendingbal = IHostChainManager(_externals[i].externalContract).getPendingWeth(_externals[i].id);
            bal = bal > 0 ? ((bal * externalValues[i]) / 10**5) : bal;
            pendingbal = pendingbal > 0 ? (pendingbal * 995) / 1000 : pendingbal;
            wethValue += bal + pendingbal;
        }
    }

    function _exit(address component, IToken indexToken) private returns (uint256 amountOut){
        return _executeSwaptoETH(component, 0, indexToken);
    }

    function _validateExternalData(uint256[] memory externalValues, bytes memory sigs) private view{
        if(externalValues.length > 0){
            bytes32 _hash = keccak256(abi.encodePacked(externalValues)).toEthSignedMessageHash();
            address _signer = _hash.recover(sigs);
            require(_signer == externalSigner, "Invalid External Data");
            require(block.timestamp < externalValues[externalValues.length - 1], "Quote Expired");
        }
    }

    function seedNewSet(IToken indexToken, uint minQty, address to) external payable {
        require(indexToken.totalSupply() == 0, "Token Already seeded");
        uint256 outputTokens = (msg.value * 10 ** 18) / indexToken.basePrice();
        require(outputTokens >= minQty, "Insuffiecient return amount");
        IToken.externalPosition[] memory _externals = indexToken.getExternalComponents();
        _swapEthForAll(indexToken, msg.value, indexToken.getComponents(), _externals);
        indexToken.mint(to, (outputTokens / PRECISION) * PRECISION);
    }

    function issueForExactETH(IToken indexToken, uint minQty, address to,
     uint256[] memory externalValues, bytes memory sigs) external payable {
        _validateExternalData(externalValues, sigs);
        uint256 preSupply = indexToken.totalSupply();
        address[] memory components = indexToken.getComponents();
        IToken.externalPosition[] memory _externals = indexToken.getExternalComponents();
        uint256 preValue = _valueSet(indexToken, components, _externals, externalValues);
        _swapEthForAll(indexToken, msg.value, components, _externals);
        uint256 outputTokens =
         ((((preSupply * _valueSet(indexToken, components, _externals, externalValues))
         / preValue) - preSupply) / PRECISION) * PRECISION; 
        require(outputTokens >= minQty, "Insuffiecient return amount");
        indexToken.mint(to, outputTokens);
    }

    function redeem(IToken indexToken, uint qty, address to) external nonReentrant{
        //NOTE: This function must only be called with verified qtys avail for bridging on side chains
        //Risk loss of funds if not checked
        require(indexToken.balanceOf(to) >= qty, "User does not have sufficeint balance");
        
        address[] memory components = indexToken.getComponents();
        uint256 funds = 0;
        for(uint i = 0; i<components.length; i++){
            funds += _executeSwaptoETH(components[i], qty, indexToken);
        }
        IToken.externalPosition[] memory _externals = indexToken.getExternalComponents();
        //TODO: batching here will save gas
        for(uint i =0; i < _externals.length; i++){
            _executeExternalSwaptoETH(indexToken, _externals[i], qty, to);
        }
        WETH.withdraw(funds);
        indexToken.burn(to, qty);
        (bool sent, ) = payable(to).call{value: funds}("");
        require(sent, "Failed to Transfer");
    }

    function getTokenQty(IToken indexToken, uint index) external view returns(uint256){
        address component = _getPoolToken(indexToken.getComponents()[index]);
        uint256 balance = IERC20(component).balanceOf(address(indexToken));
        return balance;
    }

    function rebalanceExitedFunds(IToken indexToken, address[] memory exitedPositions, uint256[] memory replacementIndex)
     external {
        //sells out of exited positions and buys selected index(typically the token that replaced it)
        uint preBalance = WETH.balanceOf(address(this));
        address[] memory components = indexToken.getComponents();
        for(uint i = 0; i < exitedPositions.length; i++){
            address component = exitedPositions[i];
            require(indexToken.getShare(component) == 0, "position not exited");
            uint256 amountWOut= _exit(component, indexToken);
            IERC20 token = IERC20(_getPoolToken(component));
            require(token.balanceOf(address(indexToken)) == 0 &&
            token.balanceOf(address(this)) == 0, "Token not exited properly");
            _rawPoolSwap(components[replacementIndex[i]], amountWOut, address(indexToken), address(this), true);
        }
        if(WETH.balanceOf(address(this)) - preBalance > 0){
            IToken.externalPosition[] memory _externals = indexToken.getExternalComponents();
            _swapEthForAll(indexToken, WETH.balanceOf(address(this)) - preBalance, indexToken.getComponents(), _externals);
        }
    }

    function getIndexValue(IToken indexToken, uint256[] memory externalValues, bytes memory sigs)
     external view returns(uint256){
        _validateExternalData(externalValues, sigs);
        IToken.externalPosition[] memory _externals = indexToken.getExternalComponents();
        return _valueSet(indexToken, indexToken.getComponents(), _externals, externalValues);
    }

    function updateSigner(address newSigner) external{
        require(msg.sender == externalSigner);
        externalSigner = newSigner;
    }

    function updateBridgeMin(uint256 newScMin) external {
        require(msg.sender == externalSigner);
        scMin = newScMin;
    }

    receive() external payable {}

    fallback() external payable{}
}