// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../libs/LibOrder.sol";
import "../libs/LibDutchOrder.sol";
import "../libs/LibEthSigHash.sol";
import "../interfaces/ISubModule.sol";

/**
 * @title Merito's Dutch Auction SubModule Contract
 * @author Merit Circle
 * @notice Contract that verifies dutch orders.
 * @dev The contract manages to create and verify dutch order with the proper signature for further usage.
 */
contract ERC721DutchAuctionModule is ISubModule {
    address public immutable ERC721Module;

    /**
     * @notice Sets parent module.
     * @dev On deployments sets the module that manages order matching.
     * @param _ERC721Module Address of the ERC721Module contract.
     */
    constructor(address _ERC721Module) {
        ERC721Module = _ERC721Module;
    }

    /**
     * @notice Hashes dutch orders.
     * @dev Produces a keccak256 hash after encoding the dutch order struct.
     * @param _order Dutch order struct to be encoded and hashed.
     * @return Keccak256 hash of the order.
     */
    function hashOrder(LibDutchOrder.Order memory _order) public view returns (bytes32) {
        return keccak256(abi.encode(_order, address(this)));
    }

    /**
     * @notice Validates a dutch order.
     * @dev From a regular order creates a dutch order using the encoded data in the _data parameter.
     * @param _order Order struct to be validated (Includes signature and verification method).
     * @param _data Encoded parameters of a dutch order. Includes signature, startTokenAmount, endTokenAmount, start and end.
     * @return Whether or not the order and the dutch order parameters conform a valid order.
     */
    // This function has no sideEffects so no need to check msg.sender
    function validateAndHandleOrder(LibOrder.Order calldata _order, bytes calldata _data) external view returns (bool) {
        (bytes memory signature, uint256 startTokenAmount, uint256 endTokenAmount, uint256 start, uint256 end) = abi
            .decode(_data, (bytes, uint256, uint256, uint256, uint256));
        // If price should be higher revert verification
        if (LibDutchOrder.getCurrentPrice(startTokenAmount, endTokenAmount, start, end) > _order.tokenAmount) {
            return false;
        }

        LibDutchOrder.Order memory dutchOrder = LibDutchOrder.Order({
            maker: _order.maker,
            taker: _order.taker,
            nft: _order.nft,
            token: _order.token,
            orderId: _order.orderId,
            nftId: _order.nftId,
            startTokenAmount: startTokenAmount,
            endTokenAmount: endTokenAmount,
            start: start,
            end: end,
            validTill: _order.validTill,
            feeFraction: _order.feeFraction
        });

        // Check if order signature is valid
        bytes32 ethSigHash = LibEthSigHash.hash(hashOrder(dutchOrder));
        return SignatureChecker.isValidSignatureNow(_order.maker, ethSigHash, signature);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Merito's Order Library Contract
 * @author Merit Circle
 * @notice Library that contains order structs.
 * @dev This contract defines an order as a struct, buy and sell type of orders, a verified order as a struct and the verification methods as enums.
 */
library LibOrder {
    bool public constant BUY_TYPE = true;
    bool public constant SELL_TYPE = false;
    uint8 public constant SIGNATURE_VERIFICATION = 0;
    uint8 public constant CONTRACT_VERIFICATION = 1;

    struct Order {
        address maker;
        address taker;
        address nft;
        address token;
        uint256 orderId;
        uint256 nftId;
        uint256 tokenAmount;
        uint256 validTill;
        bool orderType;
        uint256 feeFraction;
    }

    struct VerifiedOrder {
        Order order;
        uint8 verificationMethod;
        bytes signature;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./LibOrder.sol";

/**
 * @title Merito's Dutch Order Library Contract
 * @author Merit Circle
 * @notice Library that contains dutch order structs.
 * @dev This contract defines dutch orders and signed dutch orders as structs. The functions also provides the signed orders for the submodules and calculate the price of the dutch orders.
 */
library LibDutchOrder {
    error AuctionNotStartedError();
    error StartEndError();

    struct Order {
        address maker;
        address taker;
        address nft;
        address token;
        uint256 orderId; // consider using a smaller type
        uint256 nftId;
        uint256 startTokenAmount;
        uint256 endTokenAmount;
        uint256 start;
        uint256 end;
        uint256 validTill;
        uint256 feeFraction;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    /**
     * @notice Formats a dutch order into a regular order.
     * @dev Generates a regular order from a dutch order struct and calculates its current price in the process. Sets the order type to sell for matching.
     * @param _dutchOrder Dutch order struct to be matched/filled.
     * @return result Order struct from the original dutch order.
     */
    function getOrder(Order calldata _dutchOrder) internal view returns (LibOrder.Order memory result) {
        result.maker = _dutchOrder.maker;
        result.taker = _dutchOrder.taker;
        result.nft = _dutchOrder.nft;
        result.token = _dutchOrder.token;
        result.orderId = _dutchOrder.orderId;
        result.nftId = _dutchOrder.nftId;
        result.tokenAmount = getCurrentPrice(
            _dutchOrder.startTokenAmount,
            _dutchOrder.endTokenAmount,
            _dutchOrder.start,
            _dutchOrder.end
        );
        result.validTill = _dutchOrder.validTill;
        result.orderType = LibOrder.SELL_TYPE;
        result.feeFraction = _dutchOrder.feeFraction;
    }

    /**
     * @notice Prepares an order ready for matching from a dutch order.
     * @dev Uses the generated order and adds contract verification method and signature for usage in other functions. Encodes dutch order parameters and encodes verifier address for future verification.
     * @param _dutchOrder Dutch order struct to be matched/filled.
     * @param _verifierAddress Address from the contract for future verification.
     * @return result Verified order struct from the original dutch order.
     */
    function getSignedOrder(SignedOrder calldata _dutchOrder, address _verifierAddress)
        internal
        view
        returns (LibOrder.VerifiedOrder memory result)
    {
        result.order = getOrder(_dutchOrder.order);
        result.verificationMethod = LibOrder.CONTRACT_VERIFICATION;
        result.signature = abi.encode(
            _verifierAddress,
            abi.encode(
                _dutchOrder.signature,
                _dutchOrder.order.startTokenAmount,
                _dutchOrder.order.endTokenAmount,
                _dutchOrder.order.start,
                _dutchOrder.order.end
            )
        );
    }

    /**
     * @notice Retrieves price of the auction.
     * @dev Calculates the current price of the auction in case it is valid. In case the auction ended, it will output the ending price of the auction.
     * @param _startTokenAmount Starting price of the auction.
     * @param _endTokenAmount Ending price of the auction.
     * @param _start Starting timestamp of the auction.
     * @param _end Ending timestamp of the auction.
     * @return Current price of the auction.
     */
    function getCurrentPrice(
        uint256 _startTokenAmount,
        uint256 _endTokenAmount,
        uint256 _start,
        uint256 _end
    ) internal view returns (uint256) {
        if (_start > block.timestamp) {
            revert AuctionNotStartedError();
        }
        if (_start > _end) {
            revert StartEndError();
        }
        if (_end < block.timestamp) {
            return _endTokenAmount;
        }

        uint256 totalTime = _end - _start;
        uint256 timePassed = block.timestamp - _start;

        // if price is going down
        if (_startTokenAmount > _endTokenAmount) {
            uint256 priceDifference = _startTokenAmount - _endTokenAmount;
            return _startTokenAmount - ((priceDifference * timePassed) / totalTime);
        } else {
            // if price is going up
            uint256 priceDifference = _endTokenAmount - _startTokenAmount;
            return _startTokenAmount + ((priceDifference * timePassed) / totalTime);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Merito's ETH Signature Hash Library Contract
 * @author Merit Circle
 * @notice Library that computes the special Ethereum hash signature.
 * @dev This contract produces the hash necessary to sign and recover signatures in Ethereum.
 */
library LibEthSigHash {
    /**
     * @notice Produces a hash that can be used for signatures in Ethereum.
     * @dev Generates the hash from an input using the special constants that Ethereum needs to comply with the protocol signature standard.
     * @param _hash Hash of information to be signed.
     * @return Ethereum hash of input information.
     */
    function hash(bytes32 _hash) internal pure returns (bytes32) {
        // https://github.com/0xProject/protocol/blob/24397c51a8c7bf704948c8fc6874843bccd5d244/contracts/zero-ex/contracts/src/features/libs/LibSignature.sol#L90-L96
        bytes32 ethSigHash;
        assembly {
            // Use scratch space
            mstore(0, 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000) // length of 28 bytes
            mstore(28, _hash) // length of 32 bytes
            ethSigHash := keccak256(0, 60)
        }
        return ethSigHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libs/LibOrder.sol";

/**
 * @title Merito's SubModule Interface Contract
 * @author Merit Circle
 * @notice Interface submodules.
 * @dev The interface defines a function to validate and handle orders.
 */
interface ISubModule {
    /**
     * @notice Validates an order.
     * @dev From a regular order creates a dutch order using the encoded data in the _data parameter.
     * @param _order Order struct to be validated.
     * @param _data Encoded parameters of a dutch order. Includes signature, startTokenAmount, endTokenAmount, start and end.
     * @return Whether or not the order and the dutch order parameters conform a valid order.
     */
    function validateAndHandleOrder(LibOrder.Order calldata _order, bytes calldata _data) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}