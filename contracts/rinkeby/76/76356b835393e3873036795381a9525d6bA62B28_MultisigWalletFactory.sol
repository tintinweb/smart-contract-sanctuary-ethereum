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

pragma solidity >=0.8.10;

//pragma experimental ABIEncoderV2;

// functions for recovering and managing Ethereum account ECDSA signatures
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// MultisigWallet Factory
import "./MultisigWalletFactory.sol";

contract MultisigWallet {
    MultisigWalletFactory public multisigWalletFactory;

    // Pass the bytes32 as the first parameter when calling the ECDSA functions
    using ECDSA for bytes32;
    // Deposit event
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    // ExecuteTransactions event from calldata
    event ExecuteTransaction(
        address indexed owner,
        address payable to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );
    event Owner(address indexed owner, bool added);

    // Keep track of the MultisigWallet Owners
    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public nonce;
    uint256 public chainId;
    uint256 public signaturesRequired;

    // Only Owners of the MultisigWallet
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not Owner");
        _;
    }

    // Only the MultisigWallet instance
    modifier onlySelf() {
        require(msg.sender == address(this), "Not Self");
        _;
    }

    // Non Zero signatures
    modifier nonZeroSignatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "Must be non-zero sigs required");
        _;
    }

    constructor(
        uint256 _chainId,
        address[] memory _initialOwners,
        uint256 _signaturesRequired,
        address _factory
    ) payable nonZeroSignatures(_signaturesRequired) {
        multisigWalletFactory = MultisigWalletFactory(_factory);
        signaturesRequired = _signaturesRequired;

        // Validate Owners & Signatures required
        require(_initialOwners.length > 0, "Owners required");
        require(
            _signaturesRequired > 0 &&
                _signaturesRequired <= _initialOwners.length,
            "Invalid required number of owners"
        );

        // Update MultisigWallet Owners
        for (uint256 i; i < _initialOwners.length; i++) {
            address owner = _initialOwners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "Owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);

            emit Owner(owner, isOwner[owner]);
        }

        chainId = _chainId;
    }

    // Enable receiving deposits
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // Get the transaction hash
    function getTransactionHash(
        uint256 _nonce,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    chainId,
                    _nonce,
                    _to,
                    _value,
                    _data
                )
            );
    }

    // Returns the address that signed a hashed message (`hash`) with `signature`.
    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    // Excute the calldata transaction
    function executeTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data,
        bytes[] memory _signatures
    ) public onlyOwner returns (bytes memory) {
        bytes32 _hash = getTransactionHash(nonce, _to, _value, _data);

        nonce++;

        // Valid signatures counter
        uint256 validSignatures;
        address duplicateGuard;

        // Recover the signing addresess and validate if unique and update valid signatures
        for (uint256 i = 0; i < _signatures.length; i++) {
            address recovered = recover(_hash, _signatures[i]);
            require(
                recovered > duplicateGuard,
                "executeTransaction: duplicate or unordered signatures"
            );
            duplicateGuard = recovered;

            if (isOwner[recovered]) {
                validSignatures++;
            }
        }

        // Validate number of signatures against required
        require(
            validSignatures >= signaturesRequired,
            "executeTransaction: not enough valid signatures"
        );

        // Execute the calldata
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "executeTransaction: tx failed");

        // Emit the ExecuteTransaction event
        emit ExecuteTransaction(
            msg.sender,
            _to,
            _value,
            _data,
            nonce - 1,
            _hash,
            result
        );
        return result;
    }

    // Add a new Owner
    function addOwner(address _newOwner, uint256 _newSignaturesRequired)
        public
        onlySelf
        nonZeroSignatures(_newSignaturesRequired)
    {
        require(_newOwner != address(0), "addSigner: zero address");
        require(!isOwner[_newOwner], "addSigner: owner not unique");

        isOwner[_newOwner] = true;
        owners.push(_newOwner);
        signaturesRequired = _newSignaturesRequired;

        emit Owner(_newOwner, isOwner[_newOwner]);
        multisigWalletFactory.emitOwners(
            address(this),
            owners,
            _newSignaturesRequired
        );
    }

    // Remove a Owner
    function removeOwner(address _oldOwner, uint256 _newSignaturesRequired)
        public
        onlySelf
        nonZeroSignatures(_newSignaturesRequired)
    {
        require(isOwner[_oldOwner], "removeSigner: not owner");

        _removeOwnerList(_oldOwner);
        signaturesRequired = _newSignaturesRequired;

        emit Owner(_oldOwner, isOwner[_oldOwner]);
        multisigWalletFactory.emitOwners(
            address(this),
            owners,
            _newSignaturesRequired
        );
    }

    // Pop Owner from the list
    function _removeOwnerList(address _oldOwner) private {
        isOwner[_oldOwner] = false;
        uint256 ownersLength = owners.length;
        address[] memory poppedOwners = new address[](owners.length);
        for (uint256 i = ownersLength - 1; i >= 0; i--) {
            if (owners[i] != _oldOwner) {
                poppedOwners[i] = owners[i];
                owners.pop();
            } else {
                owners.pop();
                for (uint256 j = i; j < ownersLength - 1; j++) {
                    owners.push(poppedOwners[j]);
                }
                return;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// MultisigWallet instance contract
import "./MultisigWallet.sol";

contract MultisigWalletFactory {
    // Keep track of MultisigWallet instances
    MultisigWallet[] public multisigWallets;
    mapping(address => bool) existsMultisigWallet;

    // MultisigWallet Create event
    event Create(
        uint256 indexed contractId,
        address indexed contractAddress,
        address creator,
        address[] owners,
        uint256 signaturesRequired
    );

    // MultisigWallet Owners event
    event Owners(
        address indexed contractAddress,
        address[] owners,
        uint256 indexed signaturesRequired
    );

    constructor() {}

    // Only registered wallet instances can call the logger
    modifier onlyRegistered() {
        require(
            existsMultisigWallet[msg.sender],
            "caller not registered to use logger"
        );
        _;
    }

    // Emit Owner events used from MultisigWallet instance
    function emitOwners(
        address _contractAddress,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) external onlyRegistered {
        emit Owners(_contractAddress, _owners, _signaturesRequired);
    }

    // Get the number of wallets
    function numberOfMultisigWallets() public view returns (uint256) {
        return multisigWallets.length;
    }

    // Create a MultisigWallet instance and make it payable
    function createMultisigWallet(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) public payable {
        // MultisigWallet ID
        uint256 id = numberOfMultisigWallets();

        // Create a new instance
        MultisigWallet multisigWallet = (new MultisigWallet){value: msg.value}(
            _chainId,
            _owners,
            _signaturesRequired,
            address(this)
        );
        // Update
        multisigWallets.push(multisigWallet);
        existsMultisigWallet[address(multisigWallet)] = true;

        // Emit Create and Initial Owners events
        emit Create(
            id,
            address(multisigWallet),
            msg.sender,
            _owners,
            _signaturesRequired
        );
        emit Owners(address(multisigWallet), _owners, _signaturesRequired);
    }

    // Get MultisigWallet information
    function getMultisigWallet(uint256 _index)
        public
        view
        returns (
            address multisigWalletAddress,
            uint256 signaturesRequired,
            uint256 balance
        )
    {
        MultisigWallet multisigWallet = multisigWallets[_index];
        return (
            address(multisigWallet),
            multisigWallet.signaturesRequired(),
            address(multisigWallet).balance
        );
    }
}