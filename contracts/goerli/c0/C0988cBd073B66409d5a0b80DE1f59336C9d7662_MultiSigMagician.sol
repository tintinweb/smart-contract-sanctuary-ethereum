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
pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

/// A magician who can create a new MultiSigWallet for you.
contract MultiSigMagician {
    MultiSigWallet[] public multiSigs;
    mapping(address => bool) existsMultiSig;

    event Create(
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

    constructor() {}

    modifier onlyRegisteredWallet() {
        require(
            existsMultiSig[msg.sender],
            "caller must be create by the MultiSigMagician"
        );
        _;
    }

    function emitOwners(
        address _contractAddress,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) external onlyRegisteredWallet {
        emit Owners(_contractAddress, _owners, _signaturesRequired);
    }

    function create(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired
    ) public payable {
        uint256 walletId = multiSigs.length;

        MultiSigWallet multiSig = new MultiSigWallet{value: msg.value}(
            _chainId,
            _owners,
            _signaturesRequired,
            payable(address(this)) // pass the magician address to the wallet, the wallet may call `emitOwners` when it's `owners` changes
        );
        address walletAddress = address(multiSig);
        require(!existsMultiSig[walletAddress], "wallet already exists");

        multiSigs.push(multiSig);
        existsMultiSig[address(multiSig)] = true;

        emit Create(
            walletId,
            walletAddress,
            msg.sender,
            _owners,
            _signaturesRequired
        );
        emit Owners(walletAddress, _owners, _signaturesRequired);
    }

    function numberOfMultiSigs() public view returns (uint256) {
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
        _signaturesRequired = wallet.signaturesRequired();
        _balance = address(wallet).balance;
    }

    receive() external payable {}

    fallback() external payable {}
}

/*
⚽️ GOALS 🥅

[ ] can you edit and deploy the contract with a 2/3 multisig with two of your addresses and the buidlguidl multisig as the third signer? (buidlguidl.eth is like your backup recovery.) 
[ ] can you propose basic transactions with the frontend that sends them to the backend?
[ ] can you “vote” on the transaction as other signers? 
[ ] can you execute the transaction and does it do the right thing?
[ ] can you add and remove signers with a custom dialog (that just sends you to the create transaction dialog with the correct calldata)
[ ] BONUS: for contributing back to the challenges and making components out of these UI elements that can go back to master or be forked to make a formal challenge
[ ] BONUS: multisig as a service! Create a deploy button with a copy paste dialog for sharing so _anyone_ can make a multisig at your url with your frontend
[ ] BONUS: testing lol

 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultiSigMagician.sol";

contract MultiSigWallet {
    using ECDSA for bytes32;

    // keep a reference to the magician, for message forwarding
    MultiSigMagician private magician;

    // event Deposit with sender, ether amount, wallet balance
    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 balance
    );

    // event ExecuteTrasaction with executer(must be owner), receiver address,
    // ether amount, custom data(bytes), nonce, the execution hash and the execution result(bytes).
    event ExecuteTransaction(
        address indexed owner,
        address indexed to,
        uint256 value,
        bytes data,
        uint256 nonce,
        bytes32 hash,
        bytes result
    );

    // event OwnerChanged with related owner address, wheather added(true for added, false for removed)
    event OwnerChanged(address indexed owner, bool added);

    // keep owners' addresses
    address[] public owners;

    // use mapping to keep wheather a address is one of the owners' addresses
    mapping(address => bool) public isOwner;

    // multiSigs wallet should has a minimum signatures required when execute transaction
    uint256 public signaturesRequired;

    // the nonce
    uint256 public nonce;

    // the chainId
    uint256 public chainId;

    // modifier onlyOwner (one of the owners can execute)
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // modifier onlySelf (only the contract itself can execute)
    modifier onlySelf() {
        require(msg.sender == address(this), "not self(the contract itself)");
        _;
    }

    // modifier atLeast1Signatures (this is a multiSigs wallet, 0 signatures
    // required is meaningless and dangerous)
    modifier atLeast1Signatures(uint256 _signaturesRequired) {
        require(_signaturesRequired > 0, "at least 1 signatures required");
        _;
    }

    // the constructor, with chainId, owners' addresses(length should be >= 1), signatures required (should be >= 1), the magician contract address.
    // it should be payable, because when deploy the contract we want to send some ether to it.
    constructor(
        uint256 _chainId,
        address[] memory _owners,
        uint256 _signaturesRequired,
        address payable _multiSigMagician
    ) payable atLeast1Signatures(_signaturesRequired) {
        uint256 ownersCount = _owners.length;
        require(ownersCount > 0, "at least 1 owners required");
        require(
            _signaturesRequired <= ownersCount,
            "signatures required can't be greater than owners count"
        );

        chainId = _chainId;
        signaturesRequired = _signaturesRequired;
        magician = MultiSigMagician(_multiSigMagician);

        for (uint256 i = 0; i < ownersCount; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid address(0)");
            require(!isOwner[owner], "duplicate owner address");

            isOwner[owner] = true;
            owners.push(owner);

            emit OwnerChanged(owner, true);
        }
    }

    /// === flowing function can only be executed by the contract itself === ///

    // add new Owner to this multisig wallet, with the new owner address, new signatures required when execute transaction.
    // can only be executed by the contract itself (use the onlySelf modifier)
    function addOwner(address _owner, uint256 _signaturesRequired)
        public
        onlySelf
        atLeast1Signatures(_signaturesRequired)
    {
        require(_owner != address(0), "invalid address(0)");
        require(!isOwner[_owner], "owner address already registered as owner");

        isOwner[_owner] = true;
        owners.push(_owner);

        require(
            _signaturesRequired <= owners.length,
            "signatures required cannot be greater than owners count"
        );
        signaturesRequired = _signaturesRequired;

        emit OwnerChanged(_owner, true);
        magician.emitOwners(address(this), owners, signaturesRequired);
    }

    // remove Owner from this multisig wallet, whih the owner address, new signatures required when execute transaction.
    // can only be executed by the contract itself
    function removeOwner(address _owner, uint256 _signaturesRequired)
        public
        onlySelf
        atLeast1Signatures(_signaturesRequired)
    {
        require(isOwner[_owner], "not a owner");
        uint256 ownersCount = owners.length;
        require(
            _signaturesRequired <= ownersCount - 1,
            "signatures required cannot be greater than owners count"
        );
        signaturesRequired = _signaturesRequired;

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
        magician.emitOwners(address(this), owners, signaturesRequired);
    }

    // update signatures required when execute transactions for this wallet
    // can only be executed by the contract itself
    function updateSignaturesRequired(uint256 _signaturesRequired)
        public
        onlySelf
        atLeast1Signatures(_signaturesRequired)
    {
        require(
            _signaturesRequired <= owners.length,
            "signatures required cannot be greater than owners count"
        );
        signaturesRequired = _signaturesRequired;
    }

    /// === the tranction execution function === ///

    // execute transaction function, only for owner, with receiver address, ether amount, custom data
    // and signatures arr(should be sorted by the signer's address, ascending).
    function executeTransaction(
        address payable _receiver,
        uint256 _value,
        bytes calldata _data,
        bytes[] calldata _signatures
    ) public onlyOwner returns (bytes memory) {
        bytes32 _hash = getTransactionHash(nonce, _receiver, _value, _data);

        nonce++;

        // verify signature (recover signer's address with the hash and signature, then check if the address is one of the owners)
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
            validSignature >= signaturesRequired,
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

    /// === hash calculation & signer recovery functions === ///

    // getTransactionHash function with nonce, to address, ether amount, custom data
    // return bytes32 data
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

    // recover signer address
    function recover(bytes32 _hash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return _hash.toEthSignedMessageHash().recover(_signature);
    }

    /// === the receive and fallback functions === ///

    // receive
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // fallback
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}