// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./IEIP712VerifierAuction.sol";
import "../../buyNow/base/EIP712VerifierBuyNow.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Verification of MetaTXs for Auctions, that extends
 *  the verification for BuyNows inherited in EIP712VerifierBuyNow.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IEIP712VerifierAuction
 */

contract EIP712VerifierAuction is IEIP712VerifierAuction, EIP712VerifierBuyNow {
    using ECDSA for bytes32;
    bytes32 private constant _TYPEHASH_BID =
        keccak256(
            "BidInput(bytes32 paymentId,uint256 endsAt,uint256 bidAmount,uint256 feeBPS,uint256 universeId,uint256 deadline,address bidder,address seller)"
        );

    constructor(string memory name, string memory version) EIP712VerifierBuyNow(name, version) {}

    /// @inheritdoc IEIP712VerifierAuction
    function verifyBid(
        BidInput calldata bidInput,
        bytes calldata signature,
        address signer
    ) public view returns (bool) {
        address recoveredSigner = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH_BID, bidInput))
        ).recover(signature);
        return signer == recoveredSigner;
    }

    /// @inheritdoc IEIP712VerifierAuction
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BidInput calldata bidInput
    ) public pure returns (bool) {
        /*
         * @dev The sellerSignature is also required off-chain (in the L2) to initiate the listing;
         *  in the L2, 'paymentId' is basically the digest of all listing extended set of params,
         *  so in the current implementation, the code basically has to check that the seller signed 'paymentId'.
        */
        return bidInput.seller == bidInput.paymentId.toEthSignedMessageHash().recover(sellerSignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/**
 * @title Interface for structs required in MetaTXs using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines 2 structures (BuyNowInput, AssetTransferResult),
 *  required for the BuyNow processes. These structures require a separate implementation
 *  of their corresponding EIP712-verifying functions.
 */

interface ISignableStructsBuyNow {
    /**
     * @notice The main struct that characterizes a buyNow
     * @dev Used as input to the buyNow method
     * @dev it needs to be signed following EIP712
     */
    struct BuyNowInput {
        // the unique Id that identifies a payment,
        // common to both Auctions and BuyNows,
        // obtained from hashing params related to the listing, 
        // including a sufficiently large source of entropy.
        bytes32 paymentId;

        // the price of the asset, an integer expressed in the
        // lowest unit of the currency.
        uint256 amount;

        // the fee that will be charged by the feeOperator,
        // expressed as percentage Basis Points (bps), applied to amount.
        // e.g. feeBPS = 500 applies a 5% fee.
        uint256 feeBPS;

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // the deadline for the payment to arrive to this
        // contract, otherwise it will be rejected.
        uint256 deadline;

        // the buyer, providing the required funds, who shall receive
        // the asset on a successful payment.
        address buyer;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on a successful payment.
        address seller;
    }

    /**
     * @notice The struct that specifies the success or failure of an asset transfer
     * @dev It needs to be signed by the operator following EIP712
     * @dev Must arrive when the asset is in ASSET_TRANSFERING state, to then move to PAID or REFUNDED
     */
    struct AssetTransferResult {
        // the unique Id that identifies a payment previously initiated in this contract.
        bytes32 paymentId;

        // a bool set to true if the asset was successfully transferred, false otherwise
        bool wasSuccessful;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./ISignableStructsBuyNow.sol";

/**
 * @title Interface to Verification of MetaTXs for BuyNows.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the interface to the two verifying functions
 *  for the structs defined in ISignableStructsBuyNow (BuyNowInput, AssetTransferResult),
 *  used within the BuyNow process, as well as to the function that verifies
 *  the seller signature agreeing to list the asset.
 *  Potential future changes in any of these signing methods can be handled by having
 *  the main contract redirect to a different verifier contract.
 */

interface IEIP712VerifierBuyNow is ISignableStructsBuyNow {
    /**
     * @notice Verifies that the provided BuyNowInput struct has been signed
     *  by the provided signer.
     * @param buyNowInp The provided BuyNowInput struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the
     *  provided signer having signed the input struct
     */
    function verifyBuyNow(
        BuyNowInput calldata buyNowInp,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    /**
     * @notice Verifies that the provided AssetTransferResult struct
     *  has been signed by the provided signer.
     * @param transferResult The provided AssetTransferResult struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the signer
     *  having signed the input struct
     */
    function verifyAssetTransferResult(
        AssetTransferResult calldata transferResult,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    /**
     * @notice Verifies the seller signature showing agreement 
     *  to list the asset as ruled by this explicit paymentId.
     * @dev To anticipate for future potential differences in verifiers for
     *  BuyNow/Auction listings, the interfaces to verifiers for both flows are 
     *  kept separate, accepting the entire respective structs as input.
     *  For the same reason, the interface declares the method as 'view', prepared
     *  to use EIP712 flows, even if the initial implementation can be 'pure'.
     * @param sellerSignature the signature of the seller agreeing to list the asset as ruled by
     *  this explicit paymentId
     * @param buyNowInp The provided BuyNowInput struct
     * @return Returns true if the seller signature is correct
     */
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BuyNowInput calldata buyNowInp
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./IEIP712VerifierBuyNow.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Verification of MetaTXs for BuyNows.
 * @author Freeverse.io, www.freeverse.io
 * @notice Full contract documentation in IEIP712VerifierBuyNow
 */

contract EIP712VerifierBuyNow is IEIP712VerifierBuyNow, EIP712 {
    using ECDSA for bytes32;
    bytes32 private constant _TYPEHASH_PAYMENT =
        keccak256(
            "BuyNowInput(bytes32 paymentId,uint256 amount,uint256 feeBPS,uint256 universeId,uint256 deadline,address buyer,address seller)"
        );

    bytes32 private constant _TYPEHASH_ASSETTRANSFER =
        keccak256("AssetTransferResult(bytes32 paymentId,bool wasSuccessful)");

    constructor(string memory name, string memory version) EIP712(name, version) {}

    /// @inheritdoc IEIP712VerifierBuyNow
    function verifyBuyNow(
        BuyNowInput calldata buyNowInp,
        bytes calldata signature,
        address signer
    ) public view returns (bool) {
        address recoveredSigner = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH_PAYMENT, buyNowInp))
        ).recover(signature);
        return signer == recoveredSigner;
    }

    /// @inheritdoc IEIP712VerifierBuyNow
    function verifyAssetTransferResult(
        AssetTransferResult calldata transferResult,
        bytes calldata signature,
        address signer
    ) public view returns (bool) {
        address recoveredSigner = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH_ASSETTRANSFER,
                    transferResult.paymentId,
                    transferResult.wasSuccessful
                )
            )
        ).recover(signature);
        return signer == recoveredSigner;
    }

    /// @inheritdoc IEIP712VerifierBuyNow
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BuyNowInput calldata buyNowInp
    ) public pure returns (bool) {
        /*
         * @dev The sellerSignature is also required off-chain (in the L2) to initiate the listing;
         *  in the L2, 'paymentId' is basically the digest of all listing extended set of params,
         *  so in the current implementation, the code basically has to check that the seller signed 'paymentId'.
        */
        return buyNowInp.seller == buyNowInp.paymentId.toEthSignedMessageHash().recover(sellerSignature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/**
 * @title Interface for Structs required in MetaTXs using EIP712.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the structure BidInput, required for auction processes.
 *  This structure requires a separate implementation of its EIP712-verifying function.
 */

interface ISignableStructsAuction {

    /**
    * @notice The main struct that characterizes a bid
    * @dev Used as input to the bid/relayedBid methods to either start
    * @dev an auction or increment a previous existing bid;
    * @dev it needs to be signed following EIP712
    */
    struct BidInput {
        // the unique Id that identifies a payment process,
        // common to both Auctions and BuyNows,
        // obtained from hashing params related to the listing, 
        // including a sufficiently large source of entropy.
        bytes32 paymentId;

        // the time at which the auction ends if
        // no bids arrive during the final minutes;
        // this value is stored on arrival of the first bid,
        // and possibly incremented on arrival of late bids
        uint256 endsAt;

        // the bid amount, an integer expressed in the
        // lowest unit of the currency.
        uint256 bidAmount;

        // the fee that will be charged by the feeOperator,
        // expressed as percentage Basis Points (bps), applied to amount.
        // e.g. feeBPS = 500 implements a 5% fee.
        uint256 feeBPS;

        // the id of the universe that the asset belongs to.
        uint256 universeId;

        // the deadline for the payment to arrive to this
        // contract, otherwise it will be rejected.
        uint256 deadline;

        // the bidder, providing the required funds, who shall receive
        // the asset in case of winning the auction.       
        address bidder;

        // the seller of the asset, who shall receive the funds
        // (subtracting fees) on successful completion of the auction.
        address seller;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "./ISignableStructsAuction.sol";

/**
 * @title Interface to Verification of MetaTXs for Auctions.
 * @author Freeverse.io, www.freeverse.io
 * @dev This contract defines the interface to the verifying function
 *  for the struct defined in ISignableStructsAuction (BidInput),
 *  used in auction processes, as well as to the function that verifies
 *  the seller signature agreeing to list the asset.
 *  Potential future changes in any of these signing methods can be handled by having
 *  the main contract redirect to a different verifier contract.
 */

interface IEIP712VerifierAuction is ISignableStructsAuction {
    /**
     * @notice Verifies that the provided BidInput struct has been signed
     *  by the provided signer.
     * @param bidInput The provided BidInput struct
     * @param signature The provided signature of the input struct
     * @param signer The signer's address that we want to verify
     * @return Returns true if the signature corresponds to the
     *  provided signer having signed the input struct
     */
    function verifyBid(
        BidInput calldata bidInput,
        bytes calldata signature,
        address signer
    ) external view returns (bool);

    /**
     * @notice Verifies the seller signature showing agreement
     *  to list the asset as ruled by this explicit paymentId.
     * @dev To anticipate for future potential differences in verifiers for
     *  BuyNow/Auction listings, the interfaces to verifiers for both flows are
     *  kept separate, accepting the entire respective structs as input.
     *  For the same reason, the interface declares the method as 'view', prepared
     *  to use EIP712 flows, even if the initial implementation can be 'pure'.
     * @param sellerSignature the signature of the seller agreeing to list the asset as ruled by
     *  this explicit paymentId
     * @param bidInput The provided BuyNowInput struct
     * @return Returns true if the seller signature is correct
     */
    function verifySellerSignature(
        bytes calldata sellerSignature,
        BidInput calldata bidInput
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
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