// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "./MultiSigWallet.sol";


contract MultiSigCreator {
    /* ========== STATE VARIABLES ========== */
    MultiSigWallet[] public multiSigs;
    mapping(address => bool) isMultiSig;

    /* ========== Events  ========== */
    event MultiSigWalletCreated(
        uint256 indexed contractId,
        address indexed contractAddress,
        address creator,
        address[] owners,
        uint256 signaturesRequired
    );

    event Owners(
        address indexed contractAddress,
        address[] owners,
        uint256 indexed signaturesRequired
    );

    /* ========== Modifiers  ========== */
    modifier isRegistered() {
        require(
            isMultiSig[msg.sender],
            "caller must be create by the MultiSigMagician"
        );
        _;
    }

    /* ========== Functions  ========== */
    function createMultiSigWallet(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) public payable {
        uint256 walletId = multiSigs.length;
        MultiSigWallet newWallet = new MultiSigWallet{value: msg.value}(
            _chainId,
            _owners,
            _signaturesRequired,
            payable(address(this))
        );

        address walletAddress = address(newWallet);
        require(
            !isMultiSig[walletAddress],
            "createMultiSigWallet : wallet already exists"
        );

        multiSigs.push(newWallet);
        isMultiSig[walletAddress] = true;

        emit MultiSigWalletCreated(
            walletId,
            walletAddress,
            msg.sender,
            _owners,
            _signaturesRequired
        );

        emit Owners(walletAddress, _owners, _signaturesRequired);
    }

    function numberOfMultiSigsCreated() public view returns (uint256) {
        return multiSigs.length;
    }

    function getMultiSig(uint256 _index)
        public
        view
        returns (
            address _walletAddress,
            uint256 _signaturesRequired,
            uint256 _balance
        )
    {
        MultiSigWallet wallet = multiSigs[_index];
        _walletAddress = address(wallet);
        _signaturesRequired = wallet.minSignaturesRequired();
        _balance = address(wallet).balance;
    }

    function emitOwners(
        address _contractAddress,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) external isRegistered {
        emit Owners(_contractAddress, _owners, _signaturesRequired);
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultiSigCreator.sol";


contract MultiSigWallet {
    /* ========== Types Declaration ========== */
    using ECDSA for bytes32;

    MultiSigCreator public multiSigCreator;

    /* ========== Events ========== */

    event OwnerChanged(address indexed owner, bool added);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ExecuteTransaction(
        address indexed owner,
        address indexed to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );

    /* ========== STATE VARIABLES ========== */
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public minSignaturesRequired;
    uint256 public nonce;
    uint256 chainId;

    /* ========== Modifiers ========== */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only Owner and execute");
        _;
    }
    modifier onlySelf() {
        require(msg.sender == address(this), "not self(the contract itself)");
        _;
    }

    modifier atLeastOneSignatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "at least 1 signatures required");
        _;
    }

    /* ========== Functions ========== */
    constructor(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired,
        address payable _creatorAddress
    ) payable atLeastOneSignatures(_signaturesRequired) {
        uint256 ownersCount = _owners.length;
        require(ownersCount > 0, "at least 1 owners required");
        require(
            _signaturesRequired <= ownersCount,
            "signatures required can't be greater than owners count"
        );

        for (uint i = 0; i < ownersCount; i++) {
            address owner = _owners[i];
            require(
                address(owner) != address(0),
                "Adress of Owner cannot be zero address"
            );
            require(!isOwner[owner], "Duplicate address not allowed");

            isOwner[owner] = true;
            owners.push(owner);

            emit OwnerChanged(owner, true);
        }

        chainId = _chainId;
        minSignaturesRequired = _signaturesRequired;
        multiSigCreator = MultiSigCreator(_creatorAddress);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function addOwner(address _owner, uint256 _signaturesRequired)
        public
        onlySelf
        atLeastOneSignatures(_signaturesRequired)
    {
        require(
            address(_owner) != address(0),
            "addOwner : Adress of Owner cannot be zero address"
        );
        require(!isOwner[_owner], "addOwner: Duplicate address not allowed");
        require(
            _signaturesRequired <= owners.length,
            "signatures required cannot be greater than owners count"
        );

        owners.push(_owner);
        minSignaturesRequired = _signaturesRequired;
        isOwner[_owner] = true;
        emit OwnerChanged(_owner, true);
    }

    function removeOwner(address _owner, uint256 _signaturesRerequired)
        public
        onlySelf
        atLeastOneSignatures(_signaturesRerequired)
    {
        require(isOwner[_owner], "removeOwner: not a owner");
        uint256 ownersCount = owners.length;
        require(
            _signaturesRerequired <= ownersCount - 1,
            "removeOwner: signatures required cannot be greater than owners count"
        );
        minSignaturesRequired = _signaturesRerequired;

        delete isOwner[_owner];
        for (uint256 i = 0; i < ownersCount; i++) {
            address owner = owners[i];
            if (owner == _owner) {
                owners[i] = owners[ownersCount - 1];
                owners.pop();
                break;
            }
        }

        emit OwnerChanged(_owner, false);
        multiSigCreator.emitOwners(
            address(this),
            owners,
            _signaturesRerequired
        );
    }

    function updateSignaturesRequired(uint256 _signaturesRequired)
        public
        onlySelf
        atLeastOneSignatures(_signaturesRequired)
    {
        require(
            _signaturesRequired <= owners.length,
            "signatures required cannot be greater than owners count"
        );
        minSignaturesRequired = _signaturesRequired;
    }

    function executeTransaction(
        address payable _receiver,
        uint256 _value,
        bytes calldata _data,
        bytes[] calldata _signatures
    ) public onlyOwner returns (bytes memory) {
        bytes32 _hash = getTransactionHash(nonce, _receiver, _value, _data);

        nonce++;
        uint256 validSignature;
        address duplicateGuard;

        for (uint256 i = 0; i < _signatures.length; i++) {
            bytes memory signature = _signatures[i];
            address recoveredAddress = recover(_hash, signature);

            require(
                duplicateGuard < recoveredAddress,
                "duplicate or unordered signatures"
            );
            duplicateGuard = recoveredAddress;

            if (isOwner[recoveredAddress]) {
                validSignature += 1;
            }
        }

        require(
            validSignature >= minSignaturesRequired,
            "not enough count of signatures"
        );

        (bool success, bytes memory result) = _receiver.call{value: _value}(
            _data
        );
        require(success, "call failed");

        emit ExecuteTransaction(
            msg.sender,
            _receiver,
            _value,
            _data,
            nonce - 1,
            _hash,
            result
        );

        return result;
    }

    function getTransactionHash(
        uint256 _nonce,
        address _receiver,
        uint256 value,
        bytes calldata data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    chainId,
                    _nonce,
                    _receiver,
                    value,
                    data
                )
            );
    }

    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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