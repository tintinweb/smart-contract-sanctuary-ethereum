pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(address owner, address resolver)
        external
        returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

import "@ens/registry/IReverseRegistrar.sol";

pragma solidity ^0.8.16;

abstract contract PrimaryEns {

    IReverseRegistrar immutable public REVERSE_REGISTRAR;

    address private deployer ;

    constructor(){
        deployer = msg.sender;
        REVERSE_REGISTRAR = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    }

    /*
     * @description Set the primary name of the contract
     * @param _ens The ENS that is set to the contract address. Must be full name
     * including the .eth. Can also be a subdomain.
     */
    function setPrimaryName(string calldata _ens) public {
        require(msg.sender == deployer, "only deployer");
        REVERSE_REGISTRAR.setName(_ens);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
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

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
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
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IManager {
    function IdToLabelMap(
        uint256 _tokenId
    ) external view returns (string memory label);

    function IdToOwnerId(
        uint256 _tokenId
    ) external view returns (uint256 ownerId);

    function IdToDomain(
        uint256 _tokenId
    ) external view returns (string memory domain);

    function TokenLocked(uint256 _tokenId) external view returns (bool locked);

    function IdImageMap(
        uint256 _tokenId
    ) external view returns (string memory image);

    function IdToHashMap(
        uint256 _tokenId
    ) external view returns (bytes32 _hash);

    function text(
        bytes32 node,
        string calldata key
    ) external view returns (string memory _value);

    function DefaultMintPrice(
        uint256 _tokenId
    ) external view returns (uint256 _priceInWei);

    function transferDomainOwnership(uint256 _id, address _newOwner) external;

    function TokenOwnerMap(uint256 _id) external view returns (address);

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRegister {
    function canRegister(
        uint256 _tokenId,
        string memory _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) external returns (bool);

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRegister.sol";
import "./IManager.sol";
import "lib/EnsPrimaryContractNamer/src/PrimaryEns.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";

contract WhitelistRegistrationRules is IRegister, PrimaryEns, IERC721Receiver {
    IManager public immutable domainManager;
    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => uint256) public mintPrices;
    mapping(uint256 => uint256) public maxMintPerAddress;

    mapping(uint256 => mapping(address => uint256)) public mintCount;

    address private tokenOwner;

    bytes4 constant ERC721_SELECTOR = this.onERC721Received.selector;

    event UpdateMerkleRoot(uint256 indexed _tokenId, bytes32 _merkleRoot);
    event UpdateMintPrice(uint256 indexed _tokenId, uint256 _priceInWei);
    event UpdateMaxMint(uint256 indexed _tokenId, uint256 _maxMint);

    constructor(address _esf) {
        domainManager = IManager(_esf);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) public returns (bytes4) {
        domainManager.transferFrom(address(this), tokenOwner, _tokenId);
        return ERC721_SELECTOR;
    }

    function canRegister(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) public view returns (bool) {
        require(_addr == address(this), "incorrect minting address");
        return true;
    }

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs,
        address _mintTo
    ) external payable {
        //only do price and whitelist checks for none owner addresses
        if (msg.sender != domainManager.TokenOwnerMap(_id)) {
            uint256 maxMint = maxMintPerAddress[_id];

            bytes32 leaf;

            if (maxMint == 0) {
                leaf = keccak256(abi.encodePacked(msg.sender, _label));
            } else {
                leaf = keccak256(abi.encodePacked(msg.sender));
                require(
                    mintCount[_id][msg.sender] < maxMint,
                    "mint count exceeded"
                );
                unchecked {
                    ++mintCount[_id][msg.sender];
                }
            }

            if (merkleRoots[_id] != bytes32(uint256(0x1337))) {
                require(
                    MerkleProof.verify(_proofs, merkleRoots[_id], leaf),
                    "not authorised"
                );
            }

            require(
                domainManager.DefaultMintPrice(_id) != 0,
                "not for primary sale"
            );
            require(msg.value == mintPrices[_id], "incorrect price");
        }

        tokenOwner = _mintTo;
        domainManager.registerSubdomain{value: msg.value}(_id, _label, _proofs);
        delete tokenOwner;
    }

    function ownerBulkMint(
        uint256 _tokenId,
        address[] calldata _addr,
        string[] calldata _labels
    ) public payable isTokenOwner(_tokenId) {
        require(_addr.length == _labels.length, "arrays need to be same length");

        bytes32[] memory emptyProofs = new bytes32[](0);

        for(uint256 i; i < _addr.length;){

            tokenOwner = _addr[i];

            domainManager.registerSubdomain{value: msg.value}(_tokenId, _labels[i], emptyProofs);

            unchecked{
                ++i;
            }
        }

        delete tokenOwner;
    }

    function updateMerkleRoot(
        uint256 _tokenId,
        bytes32 _merkleRoot
    ) public isTokenOwner(_tokenId) {
        merkleRoots[_tokenId] = _merkleRoot;

        emit UpdateMerkleRoot(_tokenId, _merkleRoot);
    }

    function updateMintPrices(
        uint256 _tokenId,
        uint256 _price
    ) public isTokenOwner(_tokenId) {
        mintPrices[_tokenId] = _price;

        emit UpdateMintPrice(_tokenId, _price);
    }

    function updateMintPriceMaxMintAndMerkleRoot(
        uint256 _tokenId,
        uint256 _price,
        bytes32 _merkleRoot,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        mintPrices[_tokenId] = _price;
        merkleRoots[_tokenId] = _merkleRoot;
        maxMintPerAddress[_tokenId] = _maxMint;

        emit UpdateMerkleRoot(_tokenId, _merkleRoot);
        emit UpdateMintPrice(_tokenId, _price);
        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMintPriceAndMaxMint(
        uint256 _tokenId,
        uint256 _price,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        mintPrices[_tokenId] = _price;
        maxMintPerAddress[_tokenId] = _maxMint;

        emit UpdateMintPrice(_tokenId, _price);
        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMint(
        uint256 _tokenId,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        maxMintPerAddress[_tokenId] = _maxMint;

        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMintAndMerkle(
        uint256 _tokenId,
        uint256 _maxMint,
        bytes32 _merkleRoot
    ) public isTokenOwner(_tokenId) {
        maxMintPerAddress[_tokenId] = _maxMint;
        merkleRoots[_tokenId] = _merkleRoot;

        emit UpdateMerkleRoot(_tokenId, _merkleRoot);
        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) external view returns (uint256) {
        return
            (msg.sender == domainManager.TokenOwnerMap(_tokenId))
                ? 0
                : mintPrices[_tokenId];
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(
            domainManager.TokenOwnerMap(_tokenId) == msg.sender,
            "not authorised"
        );
        _;
    }
}