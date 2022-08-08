/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: UNLICENSED
/*  ______    ___    ______    ______   _____          ____     ______           ____     ______    __ __  ______
   / ____/   /   |  / ____/   / ____/  / ___/         / __ \   / ____/          / __ \   / ____/   / //_/ /_  __/
  / /_      / /| | / /       / __/     \__ \         / / / /  / /_             / /_/ /  / __/     / ,<     / /
 / __/     / ___ |/ /___    / /___    ___/ /        / /_/ /  / __/            / _, _/  / /___    / /| |   / /
/_/       /_/  |_|\____/   /_____/   /____/         \____/  /_/              /_/ |_|  /_____/   /_/ |_|  /_/
                                                                                                                 */


/*





                                                              @@@@@@@@@            @
                                                        @@@@@@@@@@@@@            @@@@
                                            ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
                                      @@@@@@@@@@@@@@@@@@@@@@&%%%@@@@@@@@@@@@@@@@@@@@@
                                    @@@@@@@@@@@@@@@%%%%%@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@.,
                                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&%@@@@@I,,[email protected]@@@@@@@@@@@.
                                    @@@@@@@@@@@@@@@I°.....°(@@@@@@@@@.°...........,@
                                       @I°@.........°@@@@@@@I.............°@@@@@°[email protected]             °°°
                                       @[email protected]@°........,..........°.....°@@[email protected]        ,°°°°°°°°°°
                                       @[email protected]@@[email protected]@I,[email protected]         I°,I
                                       @....&[email protected]@@@@@[email protected]@@@@[email protected]         I°°°°°°°°
                                       @[email protected]@@@@@[email protected]@@@@[email protected]         .I°°°°°°°°
                                       @....°,[email protected]@@@@@[email protected]@@@@[email protected]             I°°°°°°°°
                                       @[email protected]@@@@@@[email protected]@@@@[email protected]            I°°°°°°°°
                                   @°,..,@[email protected]@@@@@[email protected]@@@@[email protected]           I°°°°I
                                  @,[email protected]@@@@@[email protected]@@@@[email protected]            I
                                  @..°°[email protected]@@@@@[email protected]@@@@[email protected]           I°°
                                  @..°°I,[email protected]@@@@@[email protected]@@@@[email protected]          I°°°°°°,
                                  @....°°°[email protected]@@@@@@[email protected]@@@@@[email protected]           I°°°°°°,
                                    @@[email protected]@@@@@@I.°[email protected]@@@@@I.°@            I°°°°°°,
                                         @.................,°....°@@@@@°......,,°[email protected]     .I°°I°°°°°.
                                          @.......................................°@     I. I
                                          @.................    @@@.  [email protected]@@@@@°[email protected]  @,,,,,,,,,@
                                          @I...........,   °° ,°...°°@@@@@&°°°°@@@@@@°#@@@@@@@#(@
                                           @°.......°[email protected]@@@&[email protected]@@@@@,,,,,,,,(((@
                                             @I°.....°@°....................,@      @(,,,,,,,(((@
                                                [email protected]°°°°°°°°°°°°@......          [email protected]@@@@@@.
                                                        @°°°°°°°,°°°°@
                                                    @@&@I°°..°...I..°@@
                                                 @&&&&@@@@.......°[email protected]@&&@
                                            @@@&&@&%%%@    °@@[email protected]@,@%%%&,
                                 @@@&&%%%%%%%%%%@%%%%%&@        @,    @%%%%@%%%%&&@@@
                            @&%%%%%%%%%%%%%%%@@&&&&&%%%@    %@@&&&&@@ @%%%@@@%%%%%%%%%%%&&,
                          @&%%&%%%%%%%%%%%%%%%@%%%%%%%%&@@@.  @&%%&@  @&%%%%@%%%%%%%%%%%%%&@
                         @&%%%%%%&%%%%%%%%%%%%%@%%%%%%%%%@    @%%%%@   @%%%%@%%%%%%%%%%%%&%&@
                         @%%%%%%%%%%&%%%%%%%%%%%&%%%%%%%%@%&.&&%%%%&@ @@%%%&%%%%%%%%%%%%&%%%&@
                        @&%%%%%%%%%%%&%%%%%%%%%%%&%%%%%%%@%(%&&%%%%%@@(@%%%&%%%%%%%%%%%%&%%%%@
                        @%%%%%%%%%%%%%&%%%%%%%%%%%%&%%%%%%@((((%@@@@%((%@%%%%%%%%%%%%%%&%%%%%&@
                        @%%%%%%%%%%%%%%&%%%%%%%%%%%%&%%%%%@(((((((@(%%((@%%%%%%%%%%%%%%&%%%%%%@
                       @&%%%%%%%%%%%%%%&%%%%%%%%%%%%%&%%%%@%((((((@(((((@%&%%%%%%%%%%%%&%%%%%%@
                       @%%%%%%%%%%%%%%%%@%%%%%%%%%%%%%%&%%@(((( %%@(%%((@&%%%%%%%%%%%%@%%%%%%%&@                        */



/*
   _____    ____    _____  ____ _   __  __         _____  ____ _   ____  ____
  / ___/   / __ \  / ___/ / __ `/  / / / /        / ___/ / __ `/  / __ \/_  /
 (__  )   / /_/ / / /    / /_/ /  / /_/ /        / /__  / /_/ /  / / / / / /_
/____/   / .___/ /_/     \__,_/   \__, /         \___/  \__,_/  /_/ /_/ /___/
        /_/                      /____/                                      */

//THE GREAT REKT LAUNCH EVENT WILL NOT BE FORGOTTEN -pixelrogueart

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

pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}



pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

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

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;









contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }


    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }


    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }


    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }


    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }


    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }


    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }


    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }


    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }


    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity ^0.8.0;

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;


    mapping(uint256 => string) private _tokenURIs;


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();


        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
pragma solidity ^0.8.0;





pragma solidity ^0.8.14;


contract FACES_OF_REKT_CONTRACT is ERC721URIStorage, Ownable {

    using ECDSA for bytes32;

    string private _baseURIextended = "ipfs://QmYhVWUyJPkMuS5GwF7uxha73GVnK1EAxRmEa8doQmwZi6/"; // This one is used on OpenSea to define the metadata IPFS address

    bool private mint_paused = true; // in case someone tries to rekt our mint we can pause at will

    bool whitelist_mint = true;

    uint16 public totalSupply = 0;

    mapping(uint => uint256) public xp_to_level;

    struct token  {
        uint256 id;
        uint level;
        uint256 experience;
        bool is_staked;
        uint256 stake_date;
    }

    mapping(uint8 => bytes32) private whiteListMapping;

    mapping(uint256 => token) public token_struct;

    struct market_cap {
        uint64 cap;
        uint64 lastcap;
        uint32 xp;
    }

    market_cap cap = market_cap(
        1081871520784139,
        1181871520784139,
        1
    );

    address public interacter_address;

    constructor() ERC721("Faces of Rekt", "FOR") {

            uint256 half_day = 43200;

            for(uint8 i = 1; i <= 20; i++) {
                i > 8 ? 
                xp_to_level[i] = (((2 ** 8 ) * half_day) + ((604800*4)*2) ) : 
                xp_to_level[i] = (2 ** i) * half_day;
            }

    }

    // Set the Metadata IPFS url (see docs.opensea.io)
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    // In case we need to pause the mint
    function switchMintState() external onlyOwner() {
        mint_paused = !mint_paused;
    }

    function switchWhitelistMintState() external onlyOwner() {
        whitelist_mint = !whitelist_mint;
    }

    // For OpenSEA
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setWhitelistMerkleRoot(bytes32 newMerkleRoot_, uint8 _id) external onlyOwner {
        whiteListMapping[_id] = newMerkleRoot_;
    }



   /* function give_xp_from_games (uint16 tokenId, uint32 xp_amount) external {
        require(msg.sender == interacter_address, "Only our interacter address can do that m8");

        // TODO

    }*/

   /* function setMarketCap (bytes32[] memory proof, uint8 amount, uint64 marketCap, uint8 whitelistID) external {

        require(MerkleProof.verify(
                proof,
                whiteListMapping[whitelistID],
                keccak256(abi.encodePacked(msg.sender, amount))), "Not whitelisted");

        // todo

function _beforeTokenTransfer(
        address from,
        address to,
        uint16 tokenId
    ) internal virtual override {
        require(!token_struct[tokenId].is_staked, "Staked transfer");
    }

    }*/


    function M_I_N_T(address to) public {
        require(totalSupply < 10000, "sold out");
        require(!mint_paused, ">MINT PAUSED< If you're getting this message, shit went down (again). >MINT PAUSED<");
        
        token_struct[totalSupply] = token(
                                    totalSupply,
                                    1,
                                    0,
                                    false,
                                    0
                                );

        _safeMint(to, totalSupply);

         totalSupply += 1;

    }

    function levelUpStaking(uint16 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "you're not the owner of this token");
        require(level(tokenId) > token_struct[tokenId].level, "same level");

        token_struct[tokenId].experience += ((block.timestamp - token_struct[tokenId].stake_date) * (token_struct[tokenId].level + cap.xp));
        token_struct[tokenId].stake_date = block.timestamp;
        token_struct[tokenId].level = level(tokenId);
    }

    function level(uint16 tokenId) view public returns (uint) {

        if (token_struct[tokenId].is_staked) {
            for ( uint i = 0; i <= 100 ; i++) {
                if (
                    (((block.timestamp - token_struct[tokenId].stake_date) * (token_struct[tokenId].level + cap.xp) + token_struct[tokenId].experience) < xp_to_level[i])
                ) {
                    return i;
                }
            }
        }else {
            return token_struct[tokenId].level;
        }

    }

    function switch_stake(uint16 tokenId) external {

        require(ownerOf(tokenId) == msg.sender, "you're not the owner of this token");

        token_struct[tokenId].is_staked ?
        token_struct[tokenId].experience += ((block.timestamp - token_struct[tokenId].stake_date) * (token_struct[tokenId].level + cap.xp)) :
        token_struct[tokenId].stake_date = block.timestamp;
        token_struct[tokenId].is_staked = !token_struct[tokenId].is_staked;

    }

    function check_Xp_Owned(uint16 tokenId)public view returns (uint256) {
        require(token_struct[tokenId].is_staked, "Token not staked");

        return ((block.timestamp - token_struct[tokenId].stake_date) * ((token_struct[tokenId].level + 2) + cap.xp));

    }


    

}