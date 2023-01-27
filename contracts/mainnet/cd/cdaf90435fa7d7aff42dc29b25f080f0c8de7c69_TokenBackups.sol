// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

struct BackupWitness {
    address[] signers;
    uint256 threshold;
}

library BackupWitnessLib {
    string private constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    bytes internal constant WITNESS_TYPE = abi.encodePacked("TokenBackups(", "address[] signers,", "uint256 threshold)");

    bytes32 internal constant WITNESS_TYPE_HASH = keccak256(WITNESS_TYPE);

    string internal constant PERMIT2_WITNESS_TYPE =
        string(abi.encodePacked("TokenBackups witness)", WITNESS_TYPE, TOKEN_PERMISSIONS_TYPE));

    /// @notice hash the given witness
    function hash(BackupWitness memory witness) internal pure returns (bytes32) {
        return keccak256(abi.encode(WITNESS_TYPE_HASH, keccak256(abi.encodePacked(witness.signers)), witness.threshold));
    }
}

pragma solidity 0.8.17;

/// @notice EIP712 helpers for pal signatures
/// @dev Maintains cross-chain replay protection in the event of a fork
/// @dev Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol
contract EIP712 {
    // Cache the domain separator as an immutable value, but also store the chain id that it
    // corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private constant _VERSION_HASH = keccak256("1");
    bytes32 private constant _HASHED_NAME = keccak256("TokenBackups");
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    constructor() {
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Returns the domain separator for the current chain.
    /// @dev Uses cached version if chainid and address are unchanged from construction.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Builds a domain separator using the current chainId and contract address.
    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, _VERSION_HASH, block.chainid, address(this)));
    }

    /// @notice Creates an EIP-712 typed data hash
    function _hashTypedData(bytes32 dataHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1271 {
    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

struct RecoveryInfo {
    address oldAddress;
    ISignatureTransfer.SignatureTransferDetails[] transferDetails;
}

library PalSignatureLib {
    bytes internal constant SIGNATURE_TRANSFER_DETAILS_TYPE =
        abi.encodePacked("SignatureTransferDetails(", "address to,", "uint256 requestedAmount)");

    bytes32 internal constant SIGNATURE_TRANSFER_DETAILS_TYPE_HASH = keccak256(SIGNATURE_TRANSFER_DETAILS_TYPE);

    bytes internal constant RECOVERY_SIGS_TYPE = abi.encodePacked(
        "RecoveryInfo(",
        "address oldAddress,",
        "uint256 sigDeadline,",
        "SignatureTransferDetails[] details)",
        SIGNATURE_TRANSFER_DETAILS_TYPE
    );

    bytes32 internal constant RECOVERY_SIGS_TYPE_HASH = keccak256(RECOVERY_SIGS_TYPE);

    function hash(ISignatureTransfer.SignatureTransferDetails memory details) internal pure returns (bytes32) {
        return keccak256(abi.encode(SIGNATURE_TRANSFER_DETAILS_TYPE_HASH, details.to, details.requestedAmount));
    }

    function hash(ISignatureTransfer.SignatureTransferDetails[] memory details) internal pure returns (bytes32) {
        bytes32[] memory hashes = new bytes32[](details.length);
        for (uint256 i = 0; i < details.length; i++) {
            hashes[i] = hash(details[i]);
        }
        return keccak256(abi.encodePacked(hashes));
    }

    /// @notice hash the given witness
    function hash(RecoveryInfo memory data, uint256 sigDeadline) internal pure returns (bytes32) {
        return keccak256(abi.encode(RECOVERY_SIGS_TYPE_HASH, data.oldAddress, sigDeadline, hash(data.transferDetails)));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {BackupWitnessLib, BackupWitness} from "./BackupWitnessLib.sol";
import {RecoveryInfo, PalSignatureLib} from "./PalSignatureLib.sol";
import {IERC1271} from "./IERC1271.sol";
import {EIP712} from "./EIP712.sol";

contract TokenBackups is EIP712 {
    using BackupWitnessLib for BackupWitness;
    using PalSignatureLib for RecoveryInfo;

    error NotEnoughSignatures();
    error InvalidThreshold();
    error InvalidNewAddress();
    error InvalidSigner();
    error InvalidSignature();
    error NotSorted();
    error InvalidSignatureLength();
    error InvalidContractSignature();
    error InvalidSignerLength();
    error SignatureExpired();

    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    // Sigs from your friends!!!
    // Both inputs should be sorted in ascending order by address.
    struct Pal {
        bytes sig;
        address addr;
        uint256 sigDeadline;
    }

    ISignatureTransfer private immutable _PERMIT2;

    constructor(address permit2) {
        _PERMIT2 = ISignatureTransfer(permit2);
    }

    function recover(
        Pal[] calldata pals,
        bytes calldata backup,
        ISignatureTransfer.PermitBatchTransferFrom calldata permitData,
        RecoveryInfo calldata recoveryInfo,
        BackupWitness calldata witnessData
    ) public {
        _verifySignatures(pals, recoveryInfo, witnessData);

        // owner is the old account address
        _PERMIT2.permitWitnessTransferFrom(
            permitData,
            recoveryInfo.transferDetails,
            recoveryInfo.oldAddress,
            witnessData.hash(),
            BackupWitnessLib.PERMIT2_WITNESS_TYPE,
            backup
        );
    }

    // revert if invalid
    // Note: sigs must be sorted
    function _verifySignatures(Pal[] calldata pals, RecoveryInfo calldata details, BackupWitness calldata witness)
        internal
        view
    {
        if (witness.threshold == 0) {
            revert InvalidThreshold();
        }

        if (witness.signers.length < witness.threshold) {
            revert InvalidSignerLength();
        }

        if (pals.length != witness.threshold) {
            revert NotEnoughSignatures();
        }

        address lastOwner = address(0);
        address currentOwner;

        for (uint256 i = 0; i < pals.length; ++i) {
            Pal calldata pal = pals[i];
            if (pal.sigDeadline < block.timestamp) {
                revert SignatureExpired();
            }
            bytes32 msgHash = details.hash(pal.sigDeadline);

            currentOwner = pal.addr;

            _verifySignature(pal.sig, _hashTypedData(msgHash), currentOwner);

            if (currentOwner <= lastOwner) {
                revert NotSorted();
            }

            bool isSigner;
            for (uint256 j = 0; j < witness.signers.length; j++) {
                if (witness.signers[j] == currentOwner) {
                    isSigner = true;
                    break;
                }
            }

            if (!isSigner) {
                revert InvalidSigner();
            }

            lastOwner = currentOwner;
        }
    }

    function _verifySignature(bytes calldata signature, bytes32 hash, address claimedSigner) private view {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }
            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) revert InvalidSignature();

            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(hash, signature);
            if (magicValue != IERC1271.isValidSignature.selector) revert InvalidContractSignature();
        }
    }
}