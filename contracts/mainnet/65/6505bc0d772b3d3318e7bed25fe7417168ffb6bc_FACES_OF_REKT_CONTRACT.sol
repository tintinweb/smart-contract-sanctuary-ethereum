/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

//By interacting with this contract, you agree to our terms and conditions. Please check our website for the latest version.

// SPDX-License-Identifier: UNLICENSED
/*  ______    ___    ______    ______   _____          ____     ______           ____     ______    __ __  ______
   / ____/   /   |  / ____/   / ____/  / ___/         / __ \   / ____/          / __ \   / ____/   / //_/ /_  __/
  / /_      / /| | / /       / __/     \__ \         / / / /  / /_             / /_/ /  / __/     / ,<     / /
 / __/     / ___ |/ /___    / /___    ___/ /        / /_/ /  / __/            / _, _/  / /___    / /| |   / /
/_/       /_/  |_|\____/   /_____/   /____/         \____/  /_/              /_/ |_|  /_____/   /_/ |_|  /_/
                                                                                                                 */


/*
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOOOOO,,,,,,,,,,,,O,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOOOOOOOOO,,,,,,,,,,,,OOOO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,°OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOIFOOOOROOOOOOOOOOELSEOOOOOOOOOOOOOOOO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOOOOOOOOOOOOOOOOOOE###OOOOOOWHILEOOOOOOOOOO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOOOOOOOOOOO#####OOOOOOOOOOOOOO##OOOOOOOOOOOOOOOOO°],,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOFOROOOOOOOOOOOOOOOOOOOOOEE#OOOOO]°°]OOOOOOOOOOOO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOOOOOOOOOOOOOO]°.....°(OOOOOOOOO.°...........,O,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O]°O.........°OOOOOOO].............]OOOOO°..O,,,,,,,,,,,,,°°°,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O...........OO°........°..........°.....°OO.O,,,,,,,,°°°°°°°°°°°,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O..............OOO}}°..............OO°}},...O,,,,,,,,,}}°°}}]°}}],,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O....E........OOOOOO}}............COODE}}]..O,,,,,,,,,}}}}]°°°°°°°°,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O.............,COOODE]............,COODE}}.°O,,,,,,,,,,}}°}}°°°°°°°°,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O....°,........COOODE].............COODE}}.O,,,,,,,,,,,,,}}]°°°°°°°°,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O.....O........COOODE].............COODE]°.O,,,,,,,,,,,,]°]°°°°°°°°,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O°,,,,O,...........COOODE].............COODE}}.O,,,,,,,,,,,}}°°°°}}],,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O,..}}].............COOODE].............COODE}}.O,,,,,,,,,,,,]°],,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O..°°}}.............COOODE].............COODE}}.O,,,,,,,,,,,]°°,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O..°°°°°............COOODE].............COODE]°..O,,,,,,,,,,}}°°°°°°°°,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O....°°°...........COOOODE]............COODE}}..O,,,,,,,,,,,}}]°°°°°°°,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OO...O...........COOODE}}.°.°......O.COODE}}].°O,,,,,,,,,,,,°]°°°°°°°,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O.................°°....°OOOOO°......°°°..O,,,,,,°]°°°°]°°°°°°,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O.......................................°O,,,,,],,}}}}°,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O.................    OOO.  .OOOOOO°....O,,O°°°°°°°°°O,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O°...........,   ,° ,°,,,°°OOOOOE}}}}COOODE#COOOOODE##O,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O°.......°..OOOOE...................COOODE°°°°°°°°###O,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O°°.....°O°....................°O,,,,,,O#°°°°°°°###O,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O°°°°°°°°°°°°O,,,,,,,,,,,,,,,,,COOOODE,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,O°°°°°°°°°°°°O,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OO#O]°°..°...]..°OO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OE###OOOO.......°...OO#EO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOO##O####O    °OO.....OO.O###E°,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,OOO############O######O        O.    O####O######OOO,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,OE###############OO########O    #OO###EOO O###OOO###########EE°,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,O###################O#########OOO.  O####O  O#####O##############O,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,O#####################O#########O    O####O   O####O###############O,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,O###############################O#E.#######O OO#####################O,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,O################################O##########OO#O#####################O,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,O#################################O#####OOOO####O#####################O,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,O#################################O#######O#####O#####################O,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,O##################################O#(#####O#####O#####################O,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,O################O#################O((##,##O#####O#############O########O,,,,,,,,,,,,,,,,,,,,,,,,
 */
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// -------------------------------------------- ERC 721A n Stuff, just removed the comments, didn't edit anything this time ------------------

pragma solidity ^0.8.0;

library MerkleProof {

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {

        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {

        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;


        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {

        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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

pragma solidity ^0.8.0;

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

    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {

        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.1;

library Address {

    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

pragma solidity ^0.8.4;

interface IERC721A {

    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    error MintERC2309QuantityExceedsLimit();
    error OwnershipNotInitializedForExtraData();


    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

pragma solidity ^0.8.4;

interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721A is IERC721A {
    struct TokenApprovalRef {
        address value;
    }


    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    uint256 private constant _BITPOS_AUX = 192;

    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    uint256 private constant _BITMASK_BURNED = 1 << 224;

    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;


    uint256 private _currentIndex;

    uint256 private _burnCounter;

    string private _name;

    string private _symbol;

    mapping(uint256 => uint256) private _packedOwnerships;

    mapping(address => uint256) private _packedAddressData;

    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }


    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    function totalSupply() public view virtual override returns (uint256) {
    unchecked {
        return _currentIndex - _burnCounter - _startTokenId();
    }
    }

    function __burn_non_minted_token(uint16 amount) internal virtual {
        _currentIndex += amount;
    }

    function _totalMinted() internal view virtual returns (uint256) {
    unchecked {
        return _currentIndex - _startTokenId();
    }
    }

    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == 0x01ffc9a7 ||
        interfaceId == 0x80ac58cd ||
        interfaceId == 0x5b5e139f;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

    unchecked {
        if (_startTokenId() <= curr)
            if (curr < _currentIndex) {
                uint256 packed = _packedOwnerships[curr];
                if (packed & _BITMASK_BURNED == 0) {
                    while (packed == 0) {
                        packed = _packedOwnerships[--curr];
                    }
                    return packed;
                }
            }
    }
        revert OwnerQueryForNonexistentToken();
    }

    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            owner := and(owner, _BITMASK_ADDRESS)
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        assembly {
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
        _startTokenId() <= tokenId &&
        tokenId < _currentIndex &&
        _packedOwnerships[tokenId] & _BITMASK_BURNED == 0;
    }

    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            owner := and(owner, _BITMASK_ADDRESS)
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    function _getApprovedSlotAndAddress(uint256 tokenId)
    private
    view
    returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        assembly {
            if approvedAddress {
                sstore(approvedAddressSlot, 0)
            }
        }

    unchecked {
        --_packedAddressData[from];
        ++_packedAddressData[to];

        _packedOwnerships[tokenId] = _packOwnershipData(
            to,
            _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
        );

        if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
            uint256 nextTokenId = tokenId + 1;
            if (_packedOwnerships[nextTokenId] == 0) {
                if (nextTokenId != _currentIndex) {
                    _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                }
            }
        }
    }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }


    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    unchecked {
        _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

        _packedOwnerships[startTokenId] = _packOwnershipData(
            to,
            _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
        );

        uint256 toMasked;
        uint256 end = startTokenId + quantity;

        assembly {
            toMasked := and(to, _BITMASK_ADDRESS)
            log4(
            0,
            0,
            _TRANSFER_EVENT_SIGNATURE,
            0,
            toMasked,
            startTokenId
            )

            for {
                let tokenId := add(startTokenId, 1)
            } iszero(eq(tokenId, end)) {
                tokenId := add(tokenId, 1)
            } {
                log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
            }
        }
        if (toMasked == 0) revert MintToZeroAddress();

        _currentIndex = end;
    }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    unchecked {
        _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

        _packedOwnerships[startTokenId] = _packOwnershipData(
            to,
            _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
        );

        emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

        _currentIndex = startTokenId + quantity;
    }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

    unchecked {
        if (to.code.length != 0) {
            uint256 end = _currentIndex;
            uint256 index = end - quantity;
            do {
                if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } while (index < end);
            if (_currentIndex != end) revert();
        }
    }
    }

    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }


    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        assembly {
            if approvedAddress {
                sstore(approvedAddressSlot, 0)
            }
        }

    unchecked {
        _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

        _packedOwnerships[tokenId] = _packOwnershipData(
            from,
            (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
        );

        if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
            uint256 nextTokenId = tokenId + 1;
            if (_packedOwnerships[nextTokenId] == 0) {
                if (nextTokenId != _currentIndex) {
                    _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                }
            }
        }
    }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

    unchecked {
        _burnCounter++;
    }
    }


    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }


    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            str := add(mload(0x40), 0x80)
            mstore(0x40, str)

            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }
}


// -------------------------------------------- ERC 721A n Stuff, just removed the comments, didn't edit anything this time ------------------
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

pragma solidity ^0.8.14;

contract FACES_OF_REKT_CONTRACT is ERC721A, Ownable {

    using ECDSA for bytes32;

    string public _baseURIextended = "ipfs://QmPNh2m595pWnxRbSUSXxnTL91KHLQv1TQEgG8H4HUdDfR/"; // This one is used on OpenSea to define the metadata IPFS address

    bool public mint_paused = true; // in case someone tries to rekt our mint we can pause at will

    bool public whitelist_mint = true;

    struct token  {
        uint256 experience;
        bool is_staked;
        uint256 stake_date;
    }

    mapping(uint256 => token) public token_struct;

    mapping(uint8 => bytes32) public whiteListMapping;

    uint256 capMultiplier = 1;

    address public interacter_address;

    address public can_contract_address = 0x01E690c5D3cc89cea84F2a3C2CcB38410Ce2992D;

    address public multi_sig_wallet = 0x1eD3486C2Abe166cC10a57F54fA9E4D41F87dea4;

    uint public wl_mint_price = 0.05 ether;

    uint public public_mint_price = 0.08  ether;

    mapping(address => uint8) private free_mint_already_minted ;

    constructor() ERC721A("Faces of Rekt", "FoR") {
        whiteListMapping[0] = 0xa6ed8e5f435cf2dee09434b2fc9bd6cf7bba099d9af57bfdb60803d8d8818294;
        whiteListMapping[1] = 0x32a9ce9fccbe0bf6a0e0b5fd4147e3690c7be43f9b95d848a2d6c15b34015c1a;
    }

    function set_Base_URI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function set_Can_Address(address canContract) external onlyOwner() {
        can_contract_address = canContract;
    }

    function switch_Mint_State() external onlyOwner() {

        mint_paused = !mint_paused;

    }

    function switch_Whitelist_Mint_State() external onlyOwner() {

        whitelist_mint = !whitelist_mint;

    }

    function burn(uint16 amount) external onlyOwner() {

        __burn_non_minted_token(amount);

    }

    function _baseURI() internal view virtual override returns (string memory) {

        return _baseURIextended;

    }

    function set_Whitelist_MerkleRoot(bytes32 newMerkleRoot_, uint8 _id) external onlyOwner {

        whiteListMapping[_id] = newMerkleRoot_;

    }


    function bulk_give_Exp (uint256 xp_amount, uint16[]memory id_array) external {

        require(msg.sender == interacter_address || msg.sender == owner(), "Not an interacter");

        for (uint index = 0; index < id_array.length; index++) {

            token_struct[id_array[index]].experience += xp_amount;

        }

    }

    function giveExp (uint16 tokenId, uint256 xp_amount) external {

        require(msg.sender == interacter_address || msg.sender == owner(), "Not an interacter");
        token_struct[tokenId].experience += xp_amount;

    }

    function setMarketCapMultiplier (bytes32[] memory proof, uint256 _capMultiplier) external {

        require(MerkleProof.verify(
            proof,
            whiteListMapping[2],
            keccak256(abi.encodePacked(msg.sender))) || msg.sender == owner(), "Not whitelisted");

        capMultiplier = _capMultiplier;
    }

    function M_I_N_T(bytes32[] memory proof, uint16 quantity) public payable {


        require((totalSupply() + quantity) < 10000, "Sold out");

        if (whitelist_mint) {

            require(msg.value == (wl_mint_price * quantity));

            require(MerkleProof.verify(
                    proof,
                    whiteListMapping[0],
                    keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");

            Can_contract spray_can = Can_contract(can_contract_address);

            if(quantity + _numberMinted(msg.sender) > 2) {
                require(
                    spray_can.balanceOf(msg.sender)
                    >= quantity + _numberMinted(msg.sender),
                    "Can't mint more faces than canz");
            }

        } else {
            require(msg.value == (public_mint_price * quantity));
        }

        require(!mint_paused, ">MINT PAUSED< If you're getting this message, shit went down. >MINT PAUSED<");



        _safeMint(msg.sender, quantity);

    }

    function getExpBonus(uint16 tokenId) external { // this is used in order to "save" the bonus exp you got from any of ours events

        require(ownerOf(tokenId) == msg.sender, "You're not the owner of this token"); // ofc you can only grab that for your tokens

        token_struct[tokenId].experience += (block.timestamp - token_struct[tokenId].stake_date) * capMultiplier; // today minus stake date times multiplier
        token_struct[tokenId].stake_date = block.timestamp; // and today is your new stake date
        // so basically what we did was multiplying the amount of time you've already staked by our event multiplier, and then set today as the new stake date.

    }

    function switch_stake(uint16 tokenId) external { // switchs between staked and not staked.

        require(ownerOf(tokenId) == msg.sender, "You're not the owner of this token"); // of course you can't unstake or stake someone else's token right?

        token_struct[tokenId].is_staked ? // the token is staked?

        token_struct[tokenId].experience += (block.timestamp - token_struct[tokenId].stake_date) : // yes? then give exp

        token_struct[tokenId].stake_date = block.timestamp; // no? then start staking date

        token_struct[tokenId].is_staked = !token_struct[tokenId].is_staked; // either way its now the oposite.

    }

    function check_Xp_Owned(uint16 tokenId)public view returns (uint256) { // at any time, us or any of you, can check how much xp a token has

        return token_struct[tokenId].is_staked ? // is staked

        (block.timestamp - token_struct[tokenId].stake_date + token_struct[tokenId].experience) : // if it is, calcs the time staked, plus the experience saved.

        token_struct[tokenId].experience; // else just return the experience saved.

    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {

        require(!token_struct[startTokenId].is_staked, "Staked transfer"); // this is to prevent sale while staking
        // the problem with this is that people can still list their token on open sea or rarible etc... but only who buys gets the error.
        // you also get the error trying to do a free transfer.
    }

    function withdraw() external onlyOwner {            // only the owner can withdraw
        address payable to = payable(multi_sig_wallet); // goes direct to the multi_sig_wallet
        to.transfer(address(this).balance);             // to is the gnosis wallet, address(this) is the contract.


    }

    function dev_mint(uint16 quantity) external onlyOwner { // dev mint for airdrops and free mints
        require((totalSupply() + quantity) < 10000, "Sold out");
        _safeMint(msg.sender, quantity);
    }

    function free_M_I_N_T(bytes32[] memory proof) public {


        require(totalSupply() + 1 < 10000, "sold out");
        require(MerkleProof.verify(
                proof,
                whiteListMapping[1],
                keccak256(abi.encodePacked(msg.sender))), "Not whitelisted");
        require(free_mint_already_minted[msg.sender] < 1, "Only one free mint please");
        require(!mint_paused, ">MINT PAUSED< If you're getting this message, shit went down. >MINT PAUSED<");

        _safeMint(msg.sender, 1);
        free_mint_already_minted[msg.sender] += 1;

    }

}

pragma solidity 0.8.14;

interface Can_contract {

    function balanceOf(address owner) external view returns (uint256 balance);

}