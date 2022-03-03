// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IKaijuNFT } from "./IKaijuNFT.sol";

/// @title Merkle tree driven minting of Kaiju NFTs
contract MerkleMinter is Pausable, Ownable {
    event MerkleTreeUpdated(TreeType indexed treeType);
    event Purchased(bytes32 indexed nfcId, TreeType indexed treeType, address indexed recipient);

    enum TreeType { OPEN, GATED }

    struct KaijuDNA { bytes32 nfcId; uint256 birthday; string tokenUri; }
    struct MerkleTreeMetadata { bytes32 root; string dataIPFSHash; }

    MerkleTreeMetadata public gatedMerkleTreeMetadata; // single claim to a Kaiju by a specific address
    MerkleTreeMetadata public openMerkleTreeMetadata; // first come first serve Kaiju NFT

    IKaijuNFT public nft;
    uint256 public pricePerNFTInETH;
    uint256 public gatedMintPricePerNFTInETH;
    mapping(bytes32 => bool) public proofUsed;

    constructor(IKaijuNFT _nft, uint256 _pricePerNFTInETH, uint256 _gatedMintPricePerNFTInETH, address _owner) {
        require(address(_nft) != address(0), "Invalid nft");
        require(_owner != address(0) && _owner != address(_nft) && _owner != address(this), "Invalid owner");

        nft = _nft;
        pricePerNFTInETH = _pricePerNFTInETH;
        gatedMintPricePerNFTInETH = _gatedMintPricePerNFTInETH;

        _transferOwnership(_owner);
        _pause();
    }

    function canOpenMint(KaijuDNA calldata _dna, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_dna.nfcId, _dna.tokenUri, _dna.birthday));
        return MerkleProof.verify(_merkleProof, openMerkleTreeMetadata.root, node) && !proofUsed[node];
    }

    function openMint(address _recipient, KaijuDNA calldata _dna, bytes32[] calldata _merkleProof)
    public whenNotPaused payable {
        require(msg.value >= pricePerNFTInETH, "ETH pls");
        require(_recipient != address(0) && _recipient != address(this), "Blocked");

        bytes32 node = keccak256(abi.encodePacked(_dna.nfcId, _dna.tokenUri, _dna.birthday));
        require(!proofUsed[node], "Proof used");
        require(MerkleProof.verify(_merkleProof, openMerkleTreeMetadata.root, node), "Proof invalid");
        proofUsed[node] = true;

        require(nft.mintTo(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday), "Failed");

        emit Purchased(_dna.nfcId, TreeType.OPEN, _recipient);
    }

    function multiOpenMint(address _recipient, KaijuDNA[] calldata _dnas, bytes32[][] calldata _merkleProofs)
    external payable {
        uint256 numItemsToMint = _dnas.length;
        require(numItemsToMint > 0 && msg.value == (pricePerNFTInETH * numItemsToMint), "ETH pls");
        unchecked {
            for (uint256 i; i < numItemsToMint; ++i) {
                openMint(_recipient, _dnas[i], _merkleProofs[i]);
            }
        }
    }

    function canGatedMint(address _recipient, KaijuDNA calldata _dna, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday));
        return MerkleProof.verify(_merkleProof, gatedMerkleTreeMetadata.root, node) && !proofUsed[node];
    }

    function gatedMint(address _recipient, KaijuDNA calldata _dna, bytes32[] calldata _merkleProof)
    public whenNotPaused payable {
        require(msg.value >= gatedMintPricePerNFTInETH, "ETH pls");
        require(_recipient != address(0) && _recipient != address(this), "Blocked");

        bytes32 node = keccak256(abi.encodePacked(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday));
        require(!proofUsed[node], "Proof used");
        require(MerkleProof.verify(_merkleProof, gatedMerkleTreeMetadata.root, node), "Proof invalid");
        proofUsed[node] = true;

        require(nft.mintTo(_recipient, _dna.nfcId, _dna.tokenUri, _dna.birthday), "Failed");

        emit Purchased(_dna.nfcId, TreeType.GATED, _recipient);
    }

    function multiGatedMint(address _recipient, KaijuDNA[] calldata _dnas, bytes32[][] calldata _merkleProofs)
    external payable {
        uint256 numItemsToMint = _dnas.length;
        require(numItemsToMint > 0 && msg.value == (gatedMintPricePerNFTInETH * numItemsToMint), "ETH pls");
        unchecked {
            for (uint256 i; i < numItemsToMint; ++i) {
                gatedMint(_recipient, _dnas[i], _merkleProofs[i]);
            }
        }
    }

    function pause() onlyOwner whenNotPaused external { _pause(); }

    function unpause() onlyOwner whenPaused external { _unpause(); }

    function withdrawSaleProceeds(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient");
        _recipient.transfer(_amount);
    }

    function updateMerkleTree(MerkleTreeMetadata calldata _metadata, TreeType _treeType) external onlyOwner whenPaused {
        _updateMerkleTree(_metadata, _treeType);
    }

    function updatePrice(uint256 _newPrice) external onlyOwner {
        pricePerNFTInETH = _newPrice;
    }

    function updateGatedPrice(uint256 _newPrice) external onlyOwner {
        gatedMintPricePerNFTInETH = _newPrice;
    }

    function updateNFT(IKaijuNFT _nft) external onlyOwner {
        require(address(_nft) != address(0), "Invalid nft");
        nft = _nft;
    }

    function _updateMerkleTree(MerkleTreeMetadata calldata _metadata, TreeType _treeType) private {
        require(bytes(_metadata.dataIPFSHash).length == 46, "Invalid hash");
        require(_metadata.root != bytes32(0), "Invalid root");

        if (_treeType == TreeType.GATED) {
            gatedMerkleTreeMetadata = _metadata;
        } else {
            openMerkleTreeMetadata = _metadata;
        }

        emit MerkleTreeUpdated(_treeType);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IKaijuNFT {
    function mintTo(address to, bytes32 nfcId, string calldata tokenURI, uint256 birthDate)
    external
    returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}