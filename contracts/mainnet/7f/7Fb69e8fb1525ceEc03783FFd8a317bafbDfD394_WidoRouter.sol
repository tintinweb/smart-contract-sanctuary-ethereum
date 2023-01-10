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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureS,
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

interface IWidoRouter {
    /// @notice OrderInput object describing the desired token inputs
    /// @param tokenAddress Address of the input token
    /// @param fromTokenAmount Amount of the input token to spend on the user's behalf
    /// @dev amount must == msg.value when token == address(0)
    struct OrderInput {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice OrderOutput object describing the desired token outputs
    /// @param tokenAddress Address of the output token
    /// @param minOutputAmount Minimum amount of the output token the user is willing to accept for this order
    struct OrderOutput {
        address tokenAddress;
        uint256 minOutputAmount;
    }

    /// @notice Order object describing the requirements of the zap
    /// @param inputs Array of input objects, see OrderInput
    /// @param outputs Array of output objects, see OrderOutput
    /// @param user Address of user placing the order
    /// @param nonce Number used once to ensure an order requested by a signature only executes once
    /// @param expiration Timestamp until which the order is valid to execute
    struct Order {
        OrderInput[] inputs;
        OrderOutput[] outputs;
        address user;
        uint32 nonce;
        uint32 expiration;
    }

    /// @notice Step object describing a single token transformation
    /// @param fromToken Address of the from token
    /// @param targetAddress Address of the contract performing the transformation
    /// @param data Data which the swap contract will be called with
    /// @param amountIndex Index for the from token amount that can be found in data and needs to be updated with the most recent value.
    struct Step {
        address fromToken;
        address targetAddress;
        bytes data;
        int32 amountIndex;
    }

    function verifyOrder(Order calldata order, uint8 v, bytes32 r, bytes32 s) external view returns (bool);

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable;

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable;

    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;
import "./IWidoRouter.sol";

interface IWidoTokenManager {
    function pullTokens(address user, IWidoRouter.OrderInput[] calldata inputs) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IWidoRouter.sol";
import "./WidoTokenManager.sol";

error SlippageTooHigh(uint256 expectedAmount, uint256 actualAmount);

/// @title Wido Router
/// @notice Zap in or out of any ERC20 token, liquid or illiquid, in a single transaction.
/// @notice DO NOT APPROVE THIS CONTRACT FOR SPENDING YOUR TOKENS.
/// @author Wido
contract WidoRouter is IWidoRouter, Ownable, ReentrancyGuard {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        );

    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Order(OrderInput[] inputs,OrderOutput[] outputs,address user,uint32 nonce,uint32 expiration)OrderInput(address tokenAddress,uint256 amount)OrderOutput(address tokenAddress,uint256 minOutputAmount)"
            )
        );

    bytes32 private constant ORDER_INPUT_TYPEHASH =
        keccak256(abi.encodePacked("OrderInput(address tokenAddress,uint256 amount)"));

    bytes32 private constant ORDER_OUTPUT_TYPEHASH =
        keccak256(abi.encodePacked("OrderOutput(address tokenAddress,uint256 minOutputAmount)"));

    // Nonce for executing order with EIP-712 signatures.
    mapping(address => uint256) public nonces;

    // Address of the wrapped native token
    address public immutable wrappedNativeToken;

    // Address of fee bank
    address public bank;

    WidoTokenManager public immutable widoTokenManager;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param sender The msg.sender
    /// @param recipient Recipient of the final tokens of the order
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    event FulfilledOrder(
        Order order,
        address indexed sender,
        address recipient,
        uint256 feeBps,
        address indexed partner
    );

    /// @notice Event emitted when the bank address is updated
    /// @param bank The updated address of the bank
    event SetBank(
        address bank
    );

    constructor(
        address _wrappedNativeToken,
        address _bank // uint256 _feeBps
    ) {
        require(_wrappedNativeToken != address(0) && _bank != address(0), "Addresses cannot be zero address");

        wrappedNativeToken = _wrappedNativeToken;
        bank = _bank;
        widoTokenManager = new WidoTokenManager();
    }

    /// @notice Sets the bank address
    /// @param _bank The address of the new bank
    function setBank(address _bank) external onlyOwner {
        require(_bank != address(0) && _bank != address(this), "Bank address cannot be zero address or Wido Router address");
        bank = _bank;
        emit SetBank(_bank);
    }

    /// @notice Approve a token spending
    /// @param token The ERC20 token to approve
    /// @param spender The address of the spender
    /// @param amount The minimum allowance to grant to the spender
    function _approveToken(address token, address spender, uint256 amount) internal {
        ERC20 _token = ERC20(token);
        if (_token.allowance(address(this), spender) < amount) {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice Executes steps in the route to transfer to token
    /// @param route Step data for token transformation
    /// @dev Updates the amount in the byte data with the current balance as to not leave any dust
    /// @dev Expects step data to be properly chained for the token transformation tokenA -> tokenB -> tokenC
    function _executeSteps(Step[] calldata route) private {
        for (uint256 i = 0; i < route.length; ) {
            Step calldata step = route[i];

            require(step.targetAddress != address(widoTokenManager), "Wido: forbidden call to WidoTokenManager");

            uint256 balance;
            uint256 value;
            if (step.fromToken == address(0)) {
                value = address(this).balance;
            } else {
                value = 0;
                balance = ERC20(step.fromToken).balanceOf(address(this));
                require(balance > 0, "Not enough balance for the step");
                _approveToken(step.fromToken, step.targetAddress, balance);
            }

            bytes memory editedSwapData;
            if (step.amountIndex >= 0) {
                uint256 idx = uint256(int256(step.amountIndex));
                editedSwapData = bytes.concat(step.data[:idx], abi.encode(balance), step.data[idx + 32:]);
            } else {
                editedSwapData = step.data;
            }

            (bool success, bytes memory result) = step.targetAddress.call{value: value}(editedSwapData);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            unchecked {
                i++;
            }
        }
    }

    function hash(OrderInput[] memory orderInput) internal pure returns (bytes32) {
        bytes32[] memory result = new bytes32[](orderInput.length);
        for (uint256 i = 0; i < orderInput.length; ) {
            result[i] = keccak256(abi.encode(ORDER_INPUT_TYPEHASH, orderInput[i]));
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(result));
    }

    function hash(OrderOutput[] memory orderOutput) internal pure returns (bytes32) {
        bytes32[] memory result = new bytes32[](orderOutput.length);
        for (uint256 i = 0; i < orderOutput.length; ) {
            result[i] = keccak256(abi.encode(ORDER_OUTPUT_TYPEHASH, orderOutput[i]));
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(result));
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    hash(order.inputs),
                    hash(order.outputs),
                    order.user,
                    order.nonce,
                    order.expiration
                )
            );
    }

    /// @notice Verifies if the order is valid
    /// @param order Order to be validated
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return bool True if the order is valid
    function verifyOrder(Order calldata order, uint8 v, bytes32 r, bytes32 s) public view override returns (bool) {
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256("WidoRouter"), keccak256("1"), block.chainid, address(this))
        );
        address recoveredAddress = ECDSA.recover(
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(order))),
            v,
            r,
            s
        );
        require(recoveredAddress != address(0) && order.user == recoveredAddress, "Invalid signature");
        require(order.nonce == nonces[order.user], "Invalid nonce");
        require(order.expiration == 0 || block.timestamp <= order.expiration, "Expired request");
        for (uint256 i = 0; i < order.inputs.length; ) {
            IWidoRouter.OrderInput calldata input = order.inputs[i];
            require(input.amount > 0, "Amount should be greater than 0");
            unchecked {
                i++;
            }
        }
        return true;
    }

    /// @notice Executes the validated order
    /// @param order Order to be executed
    /// @param route Route to execute for the token swap
    /// @param recipient The address of the final token receiver
    /// @param feeBps Fee in basis points (bps)
    /// @dev Expects the steps in the route to transform order.fromToken to order.toToken
    /// @dev Expects at least order.minToTokenAmount to be transferred to the recipient
    function _executeOrder(Order calldata order, Step[] calldata route, address recipient, uint256 feeBps) private {
        widoTokenManager.pullTokens(order.user, order.inputs);

        for (uint256 i = 0; i < order.inputs.length; ) {
            IWidoRouter.OrderInput calldata input = order.inputs[i];

            uint256 balance;
            if (input.tokenAddress == address(0)) {
                balance = address(this).balance;
            } else {
                balance = ERC20(input.tokenAddress).balanceOf(address(this));
            }
            require(balance >= input.amount, "Balance lower than order amount");
            _collectFees(input.tokenAddress, balance, feeBps);

            unchecked {
                i++;
            }
        }

        _executeSteps(route);

        for (uint256 i = 0; i < order.outputs.length; ) {
            IWidoRouter.OrderOutput calldata output = order.outputs[i];

            if (output.tokenAddress == address(0)) {
                uint256 balance = address(this).balance;
                if (balance < output.minOutputAmount) {
                    revert SlippageTooHigh(output.minOutputAmount, balance);
                }
                recipient.safeTransferETH(balance);
            } else {
                uint256 balance = ERC20(output.tokenAddress).balanceOf(address(this));
                if (balance < output.minOutputAmount) {
                    revert SlippageTooHigh(output.minOutputAmount, balance);
                }
                ERC20(output.tokenAddress).safeTransfer(recipient, balance);
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice Returns the amount of tokens or native tokens after accounting for fee
    /// @param fromToken Address of the token for the fee
    /// @param amount Amount of tokens to subtract the fee
    /// @param feeBps Fee in basis points (bps)
    /// @dev Sends the fee to the bank to not maintain any balance in the contract
    function _collectFees(address fromToken, uint256 amount, uint256 feeBps) private {
        require(feeBps <= 100, "Fee out of range");
        uint256 fee = (amount * feeBps) / 10000;
        if (fee > 0) {
            if (fromToken == address(0)) {
                bank.safeTransferETH(fee);
            } else {
                ERC20(fromToken).safeTransfer(bank, fee);
            }
        }
    }

    /// @notice Executes order to transform ERC20 token from order.fromToken to order.toToken
    /// @param order Order describing the expectation of the token transformation
    /// @param route Route describes the details of the token transformation
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable override nonReentrant {
        require(msg.sender == order.user, "Invalid order user");
        _executeOrder(order, route, order.user, feeBps);
        emit FulfilledOrder(order, msg.sender, order.user, feeBps, partner);
    }

    /// @notice Executes order to transform ERC20 token from order.fromToken to order.toToken
    /// @param order Order describing the expectation of the token transformation
    /// @param route Route describes the details of the token transformation
    /// @param recipient Destination address where the final tokens are sent
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable override nonReentrant {
        require(msg.sender == order.user, "Invalid order user");
        _executeOrder(order, route, recipient, feeBps);
        emit FulfilledOrder(order, msg.sender, recipient, feeBps, partner);
    }

    /// @notice Executes the order with valid EIP-712 signature
    /// @param order Order describing the expectation of the token transformation
    /// @param route Expects a valid route to transform order.fromToken to order.toToken
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signation
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external override nonReentrant {
        require(verifyOrder(order, v, r, s), "Invalid order");
        nonces[order.user]++;
        _executeOrder(order, route, order.user, feeBps);
        emit FulfilledOrder(order, msg.sender, order.user, feeBps, partner);
    }

    /// @notice Allow receiving of native tokens
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWidoTokenManager.sol";

contract WidoTokenManager is IWidoTokenManager, Ownable {
    using SafeTransferLib for ERC20;

    /// @notice Transfers tokens or native tokens from the user
    /// @param user The address of the order user
    /// @param inputs Array of input objects, see OrderInput and Order
    function pullTokens(address user, IWidoRouter.OrderInput[] calldata inputs) external override onlyOwner {
        for (uint256 i = 0; i < inputs.length; i++) {
            IWidoRouter.OrderInput calldata input = inputs[i];

            if (input.tokenAddress == address(0)) {
                continue;
            }

            ERC20(input.tokenAddress).safeTransferFrom(user, owner(), input.amount);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}