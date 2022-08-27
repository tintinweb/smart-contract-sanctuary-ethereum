// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./MultiSigWallet.sol";

contract MultiSigBuilder {
    MultiSigWallet[] public multiSigs;
    mapping(address => bool) public walletExists;

    //events
    event MultiSigWalletCreated(
        uint256 indexed contractId,
        address indexed walletAddress,
        address creator,
        address[] owners,
        uint256 numSignatureRequired
    );
    event WalletOwners(
        address indexed walletAddress,
        address[] owners,
        uint256 indexed numSignatureRequired
    );

    function buildMultiSigWallet(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _numSignaturesRequired
    ) public payable {
        uint256 walletId = multiSigs.length;
        MultiSigWallet newWallet = new MultiSigWallet{value: msg.value}(
            _chainId,
            _owners,
            _numSignaturesRequired,
            payable(address(this))
        );
        address walletAddress = address(newWallet);
        require(!walletExists[walletAddress], "This wallet already exist");

        multiSigs.push(newWallet);
        walletExists[walletAddress] = true;

        emit MultiSigWalletCreated(
            walletId,
            walletAddress,
            msg.sender,
            _owners,
            _numSignaturesRequired
        );
        emit WalletOwners(walletAddress, _owners, _numSignaturesRequired);
    }

    function numberOfMultiSigsWallet() public view returns (uint256) {
        return multiSigs.length;
    }

    function getMultiSigWallet(uint256 _index)
        public
        view
        returns (
            address walletAddress,
            uint256 numSignatureRequired,
            uint256 balance
        )
    {
        MultiSigWallet wallet = multiSigs[_index];
        walletAddress = address(wallet);
        numSignatureRequired = wallet.numSignaturesRequired();
        balance = address(wallet).balance;
    }

    function emitOwners(
        address _contractAddress,
        address[] memory _owners,
        uint256 _numSignaturesRequired
    ) external {
        require(
            walletExists[msg.sender],
            "caller must be created by the MultiSigBuilder"
        );
        emit WalletOwners(_contractAddress, _owners, _numSignaturesRequired);
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultiSigBuilder.sol";

contract MultiSigWallet {
    using ECDSA for bytes32;

    address[] public owners;
    uint256 public numSignaturesRequired;
    mapping(address => bool) public isOwner;
    uint256 public nonce;
    uint256 public chainId;

    MultiSigBuilder public multiSigBuilder;

    //events
    event ExecuteTransaction(
        address indexed owner,
        address indexed to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );
    event OwnerChanged(address indexed owner, bool added);
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    modifier onlySelf() {
        require(msg.sender == address(this), "Only contract can execute");
        _;
    }

    constructor(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _numSignaturesRequired,
        address payable _creatorAddress
    ) payable {
        require(_owners.length > 0, "Owners count can not be 0");
        require(
            _numSignaturesRequired > 0 &&
                _numSignaturesRequired <= _owners.length,
            "Invalid number for the required confirmation"
        );
        for (uint8 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(address(owner) != address(0), "Invalid address sent");
            require(!isOwner[owner], "Owner already exist");
            isOwner[owner] = true;
            owners.push(owner);
            emit OwnerChanged(owner, true);
        }
        chainId = _chainId;
        numSignaturesRequired = _numSignaturesRequired;
        multiSigBuilder = MultiSigBuilder(_creatorAddress);
    }

    // Add new Owner to this multisig wallet, with the new owner address and new number of signatures required when executing a transaction.
    function addOwner(address _address, uint256 _numSignaturesRequired)
        public
        onlySelf
    {
        require(address(_address) != address(0), "Invalid address sent");
        require(!isOwner[_address], "Owner already exist");
        require(
            _numSignaturesRequired > 0 &&
                _numSignaturesRequired <= owners.length + 1,
            "Invalid number for the required confirmation"
        );
        isOwner[_address] = true;
        owners.push(_address);
        numSignaturesRequired = _numSignaturesRequired;
        emit OwnerChanged(_address, true);
    }

    // Remove a owner
    function removeOwner(address _address, uint256 _numSignaturesRequired)
        public
        onlySelf
    {
        require(isOwner[_address], "This address is not owner");
        require(
            _numSignaturesRequired > 0 &&
                _numSignaturesRequired <= owners.length - 1,
            "Invalid number for the required confirmation"
        );
        for (uint8 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            if (owner == _address) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        delete isOwner[_address];
        numSignaturesRequired = _numSignaturesRequired;
        emit OwnerChanged(_address, false);
        multiSigBuilder.emitOwners(
            address(this),
            owners,
            _numSignaturesRequired
        );
    }

    function updateSignaturesRequired(uint256 newSignaturesRequired)
        public
        onlySelf
    {
        require(
            newSignaturesRequired > 0 && newSignaturesRequired <= owners.length,
            "Given signature count is not valid"
        );
        numSignaturesRequired = newSignaturesRequired;
    }

    function getTransactionHash(
        uint256 _nonce,
        address _receiver,
        uint256 _value,
        bytes calldata _data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    chainId,
                    _nonce,
                    _receiver,
                    _value,
                    _data
                )
            );
    }

    function recover(bytes32 _hash, bytes memory _signedSignature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signedSignature);
    }

    function executeTransaction(
        address payable _receiver,
        uint256 _value,
        bytes calldata _data,
        bytes[] calldata _signedSignatures
    ) public returns (bytes memory) {
        require(isOwner[msg.sender], "Only owners can execute");
        bytes32 _hash = getTransactionHash(nonce, _receiver, _value, _data);
        nonce++;

        uint256 validSignatures;
        address duplicateGuard;

        for (uint256 i = 0; i < _signedSignatures.length; i++) {
            bytes memory signature = _signedSignatures[i];
            address recoveredAddress = recover(_hash, signature);
            require(
                duplicateGuard < recoveredAddress,
                "duplicate or unordered signatures"
            );
            duplicateGuard = recoveredAddress;
            if (isOwner[recoveredAddress]) {
                validSignatures += 1;
            }
        }
        require(
            validSignatures >= numSignaturesRequired,
            "Not enough owners signed this trasnaction"
        );

        (bool success, bytes memory result) = _receiver.call{value: _value}(
            _data
        );
        require(success, "Transaction failed");
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

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
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