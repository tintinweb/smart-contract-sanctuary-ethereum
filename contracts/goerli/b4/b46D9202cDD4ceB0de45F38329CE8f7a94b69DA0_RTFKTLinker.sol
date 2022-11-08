/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


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

// File: contracts/linking.sol



/*
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    D. Digital Collectible Terms [Document #2-D, https://rtfkt.com/legal-2D]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
*/


/// THIS IS AN EXPERIMENTAL CONTRACT SUBJECT TO CHANGES
///// TO DO : 
/////  - Move to Diamond (EIP-2535) or Proxy. Hard choice to make.
/////  - Potentially create functions to be called by Transfer events for future collections (to reduce needs of on-chain listener)

pragma solidity ^0.8.17;


abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract RTFKTLinker {
    using ECDSA for bytes32;
    
    constructor(address signer_) {
        authorizedOwners[msg.sender] = true;

        authorizedCollections[0x2aAC33d81cf2022f55A261f0dc12FEbbA043BF16] = true;
        authorizedCollections[0xc8754D565f98D8fbBc8e2A12B3397785AE6B32C0] = true;
        authorizedCollections[0xDC60A118D40cF9d1544a81722B5A4905DEE65c7E] = true;
        authorizedCollections[0xdFAb314836B085dB90a5720Cb5280A2b7AFeD829] = true;

        signer = signer_;
    }


    // NEED TO BE UNCOMMENTED BEFORE REAL DEPLOYMENT
    modifier isAuthorizedOwner() {
        // require(authorizedOwners[msg.sender], "Unauthorized"); 
        _;
    }

    address public signer;
    mapping (address => bool) public authorizedOwners;
    mapping (address => bool) public authorizedCollections;
    mapping (string => mapping (address => uint256) ) public tagIdToTokenId; // Tag ID => Contract address => Token ID (0 = no token ID)
    mapping (address => mapping (uint256 => string) ) public tokenIdtoTagId; // Contract address => Token ID => Tag ID (null = no tag ID)
    mapping (address => mapping (uint256 => address[2])) public linkOwner; // Array of 2 | 0 : current owner, 1 : potential new owner (when pending) | 0x0000000000000000000000000000000000000000 = null

    event link(address initiator, string tagId, uint256 tokenId, address collectionAddress);
    event unlink(address initiator, string tagId, uint256 tokenId, address collectionAddress);
    event transfer(address from, address to, string tagId, uint256 tokenId, address collectionAddress);

    ///////////////////////////
    // SETTER
    ///////////////////////////

    function linkNft(string calldata tagId, uint256 tokenId, address collectionAddress, bytes calldata signature) public {
        require(authorizedCollections[collectionAddress], "This collection has not been approved");
        require(_isValidSignature(_hash(collectionAddress, tokenId, tagId), signature), "Invalid signature");

        ERC721 tokenContract = ERC721(collectionAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender, "You don't own the NFT");
        require( tagIdToTokenId[tagId][collectionAddress] == 0, "This item is already linked" );

        // Set the tokenID, tagId and address of link owner
        tagIdToTokenId[tagId][collectionAddress] = tokenId;
        tokenIdtoTagId[collectionAddress][tokenId] = tagId;
        linkOwner[collectionAddress][tokenId][0] = msg.sender;

        emit link(msg.sender, tagId, tokenId, collectionAddress);
    }

    // Work for normal unlinking AND dissaproving linking
    function unlinkNft(string calldata tagId, uint256 tokenId, address collectionAddress) public {
        require( tagIdToTokenId[tagId][collectionAddress] != 0, "This item is not linked" );
        require(msg.sender == linkOwner[collectionAddress][tokenId][0], "You don't own the link");

        // Remove tokenId, tagId and address of link owner
        tagIdToTokenId[tagId][collectionAddress] = 0;
        tokenIdtoTagId[collectionAddress][tokenId] = "";
        linkOwner[collectionAddress][tokenId][0] = 0x0000000000000000000000000000000000000000;
        emit unlink(msg.sender, tagId, tokenId, collectionAddress);

    }

    function approveTransfer(string calldata tagId, uint256 tokenId, address collectionAddress) public {
        require( tagIdToTokenId[tagId][collectionAddress] != 0, "This item is not linked" );
        require(msg.sender == linkOwner[collectionAddress][tokenId][0], "You don't own the link");
        require(linkOwner[collectionAddress][tokenId][1] != 0x0000000000000000000000000000000000000000, "There is no pending approval");

        linkOwner[collectionAddress][tokenId][0] = linkOwner[collectionAddress][tokenId][1];
        linkOwner[collectionAddress][tokenId][1] = 0x0000000000000000000000000000000000000000;
        
        emit transfer(msg.sender, linkOwner[collectionAddress][tokenId][0], tagId, tokenId, collectionAddress);
    }

    
    ///////////////////////////
    // GETTER
    ///////////////////////////

    function getCurrentLinkOwner(address collectionAddress, uint256 tokenId) view public returns(address) {
        return linkOwner[collectionAddress][tokenId][0];
    }

    function getIfLinkIsPending(address collectionAddress, uint256 tokenId) view public returns(bool) {
        return (linkOwner[collectionAddress][tokenId][1] == 0x0000000000000000000000000000000000000000) ? false : true;
    }

    ///////////////////////////
    // CONTRACT MANAGEMENT 
    ///////////////////////////

    function toggleAuthorizedOwners(address[] calldata ownersAddress) public isAuthorizedOwner {
        for(uint256 i = 0; i < ownersAddress.length; i++) {
            authorizedOwners[ownersAddress[i]] = !authorizedOwners[ownersAddress[i]];
        }
    }

    function toggleAuthorizedCollection(address[] calldata collectionAddress) public isAuthorizedOwner {
        for(uint256 i = 0; i < collectionAddress.length; i++) {
            authorizedCollections[collectionAddress[i]] = !authorizedCollections[collectionAddress[i]];
        }
    }

    function setSigner(address signerAddress) public isAuthorizedOwner {
        signer = signerAddress;
    }

    function setLinkOwner(address collectionAddress, uint256 tokenId, address newOwner, uint256 typeOfOwner) public isAuthorizedOwner {
        require(typeOfOwner <= 1 && typeOfOwner >= 0, "You can't choose under 0 or over 1");

        linkOwner[collectionAddress][tokenId][typeOfOwner] = newOwner;
    }

    function forceUnlink(string calldata tagId, uint256 tokenId, address collectionAddress) public isAuthorizedOwner {
        require( tagIdToTokenId[tagId][collectionAddress] != 0, "This item is not linked" );

        address previousOwner = linkOwner[collectionAddress][tokenId][0];

        tagIdToTokenId[tagId][collectionAddress] = 0;
        tokenIdtoTagId[collectionAddress][tokenId] = "";
        linkOwner[collectionAddress][tokenId][0] = 0x0000000000000000000000000000000000000000;

        emit unlink(previousOwner, tagId, tokenId, collectionAddress);
    }

    function forceLinking(string calldata tagId, uint256 tokenId, address collectionAddress, address newOwner) public isAuthorizedOwner {
        require(authorizedCollections[collectionAddress], "This collection has not been approved");
        require( tagIdToTokenId[tagId][collectionAddress] == 0, "This item is already linked" );

        // Set the tokenID, tagId and address of link owner
        tagIdToTokenId[tagId][collectionAddress] = tokenId;
        tokenIdtoTagId[collectionAddress][tokenId] = tagId;
        linkOwner[collectionAddress][tokenId][0] = newOwner;

        emit link(newOwner, tagId, tokenId, collectionAddress);
    }

    ///////////////////////////
    // INTERNAL FUNCTIONS
    ///////////////////////////

    function _isValidSignature(bytes32 digest, bytes calldata signature) internal view returns (bool) {
        return digest.toEthSignedMessageHash().recover(signature) == signer;
    }

    function _hash(address collectionAddress, uint256 tokenId, string calldata tagId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            msg.sender,
            collectionAddress,
            tokenId,
            stringToBytes32(tagId)
        ));
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

}