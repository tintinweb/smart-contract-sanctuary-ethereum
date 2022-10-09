/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File: @openzeppelin\contracts\utils\Strings.sol
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
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
// File: @openzeppelin\contracts\token\ERC721\IERC721Receiver.sol
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: @openzeppelin\contracts\utils\introspection\IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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
// File: contracts\Wallet.sol
// Libraries
/// @author credit to https://github.com/verumlotus/social-recovery-wallet.git
contract Wallet is IERC1155Receiver, IERC721Receiver {
    struct TXData {
        address to;
        bytes payload;
        uint256 value;
        bytes signature;
    }
    struct Guardian {
        bool isGuardian;
        uint64 removalTimestamp;
        uint64 addTimestamp;
        Recovery recovery;
    }
    struct Recovery {
        address proposedOwner;
        uint88 recoveryRound; // recovery round in which this recovery struct was created
        bool usedInExecuteRecovery; // set to true when we see this struct in RecoveryExecute
    }
    address public owner;
    uint256 public nonce;
    uint256 public constant actionDelay = 1 minutes; // just for testing
    uint256 public numberOfGuardians;
    bool public inRecovery;
    uint16 public currRecoveryRound;
    mapping(address => Guardian) public guardian;
    modifier onlySelf {
        require(msg.sender == address(this));
        _;
    }
    modifier onlyGuardian {
        require(guardian[msg.sender].isGuardian);
        _;
    }
    modifier onlyInRecovery {
        require(inRecovery);
        _;
    }
    modifier notInRecovery {
        require(! inRecovery);
        _;
    }
    constructor() { owner = address(0xdead); }
    function initialize(
        address initialOwner,
        address[] calldata guardians
    ) external {
        require(owner == address(0) && initialOwner != address(0));
        owner = initialOwner;
        numberOfGuardians = guardians.length;
        for(uint256 i = 0; i < guardians.length; i++) {
            address guardian_ = guardians[i];
            guardian[guardian_].isGuardian = true;
            require(guardian_ != address(0));
        }
    }
    receive() external payable {}
   // Transaction Logic
    function executeTx(TXData calldata t) public returns(bytes memory result) {
        if(msg.sender != owner) {
            bytes32 txHash = _getTransactionHash(t.to, t.payload, t.value, nonce++);
            _checkSignature(txHash, t.signature);
        }
        (bool ok, bytes memory res) = t.to.call{ value: t.value }(t.payload);
        require(ok, "Transaction Failed");
        return res;
    }
    function _getTransactionHash(
        address receiver,
        bytes memory data,
        uint256 value,
        uint256 currentNonce
    ) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(receiver, data, value, currentNonce));
    }
    function _checkSignature(bytes32 txHash, bytes memory signature) internal view {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(txHash);
        require(owner == ECDSA.recover(messageHash, signature));
    }
   // GUARDIAN MANAGEMENT
    function scheduleNewGuardian(address newGuardian) public onlySelf {
        Guardian storage g = guardian[newGuardian];
        require((! g.isGuardian) && g.addTimestamp == 0);
        g.addTimestamp = uint64(block.timestamp + actionDelay);
    }
    function addNewGuardian(address newGuardian) public onlySelf {
        Guardian storage g = guardian[newGuardian];
        uint256 timestamp = g.addTimestamp;
        require(timestamp != 0 && timestamp < block.timestamp);
        g.isGuardian = true;
        g.addTimestamp = 0;
        numberOfGuardians++;
    } 
    function scheduleGuardianRemoval(address oldGuardian) public onlySelf {
        Guardian storage g = guardian[oldGuardian];
        require(g.isGuardian && g.removalTimestamp == 0);
        g.removalTimestamp = uint64(block.timestamp + actionDelay);
    }
    function removeGuardian(address oldGuardian) public onlySelf {
        Guardian storage g = guardian[oldGuardian];
        uint256 timestamp = g.removalTimestamp;
        require(timestamp != 0 && timestamp < block.timestamp);
        g.isGuardian = false;
        g.removalTimestamp = 0;
        numberOfGuardians--;
    }
    function threshold() public view returns(uint256) {
        return numberOfGuardians / 2 + 1;
    }
   // Guardian Actions
    function initiateRecovery(address _proposedOwner) external onlyGuardian notInRecovery  {
        // new recovery round 
        currRecoveryRound++;
        guardian[msg.sender].recovery = Recovery(
            _proposedOwner,
            currRecoveryRound, 
            false
        );
        inRecovery = true;
    }
    function supportRecovery(address _proposedOwner) external onlyGuardian onlyInRecovery  {
        guardian[msg.sender].recovery = Recovery(
            _proposedOwner,
            currRecoveryRound, 
            false
        );
    }
    function cancelRecovery() onlySelf onlyInRecovery external {
        inRecovery = false;
    }
    function executeRecovery(
        address newOwner, 
        address[] calldata guardianList
    )
        external
        onlyGuardian
        onlyInRecovery 
    {
        require(newOwner != address(0), "address 0 cannot be new owner");
        // Need enough guardians to agree on same newOwner
        require(guardianList.length >= threshold(), "more guardians required to transfer ownership");
        // Let's verify that all guardians agreed on the same newOwner in the same round
        for (uint i = 0; i < guardianList.length; i++) {
            // has to be an active guardian
            Guardian storage g = guardian[guardianList[i]];
            require(g.isGuardian);
            // cache recovery struct in memory
            Recovery memory recovery = g.recovery;
            require(recovery.recoveryRound == currRecoveryRound, "round mismatch");
            require(recovery.proposedOwner == newOwner, "disagreement on new owner");
            require(!recovery.usedInExecuteRecovery, "duplicate guardian used in recovery");
            // set field to true in storage, not memory
            g.recovery.usedInExecuteRecovery = true;
        }
        inRecovery = false;
        owner = newOwner;
    }
    function getTxHashWithCurrentNonce(address to, bytes calldata payload, uint256 value) public view returns(bytes32) {
        return _getTransactionHash(to, payload, value, nonce);
    }
    function isValidSignatureForHash(bytes32 txHash, bytes calldata sig) external view returns(bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(txHash), sig) == owner;
    }
    function onERC721Received(address,address,uint256,bytes calldata) public pure override returns(bytes4) {
        return this.onERC721Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata , bytes calldata) public pure returns(bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public pure returns(bytes4) {
        return this.onERC1155Received.selector;
    }
    function supportsInterface(bytes4 id) public pure returns(bool) {
        return (
            id == type(IERC1155Receiver).interfaceId || 
            id == type(IERC721Receiver).interfaceId || 
            id == type(IERC165).interfaceId
        );
    }
}