// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMMNFT.sol";

contract EvolutionManager is Ownable {
    struct Animal {
        uint256 tokenId; // 0
        uint256 C; // 500
        bytes32[] proof;
        uint8 evolution;
        uint256 timeStaked;
    }

    uint256 public monkeyEvoPrice = 0.1 ether;
    uint256 public gorillaEvoPrice = 0.3 ether;
    uint256 public alienEvoPrice = 0.5 ether;

    // merkleRoots for proving the rarity C values of monkeys in each evolution
    bytes32[] public merkleRoots = new bytes32[](4);
    //Index is level monkeys = 0, gorillas = 1,
    IMMNFT[] public NFTs = new IMMNFT[](4);

    mapping(address => bool) public approvedAddresses;
    enum RarityGroup{ COMMON, UNCOMMON, RARE, SUPERRARE, LEGENDARY }
    mapping(RarityGroup => uint256) mmCScores;

    //////////////////
    function evolveMonkeys() external payable {
    }

      //////////////////
    function evolveGalacticGorillas(Animal[] calldata _ggorillas) external payable {
        require(
            _ggorillas.length == 4,
            "Exactly 3 monkeys required for evolution"
        );
        uint256 totalRarity;
        for (uint256 i; i < _ggorillas.length; i++) {
            Animal memory _ggorilla = _ggorillas[i];
            require(
                isOwnedBySender(_ggorilla.tokenId, _ggorilla.evolution, msg.sender),
                "monkey not owned by sender"
            );
            require(verifyRarity(_ggorilla), "rarity data submitted not correct");
            totalRarity += _ggorilla.C;
        }
        uint256 avgRarity = totalRarity / _ggorillas.length;
        RarityGroup rg = roundRarity(avgRarity, 1);

        require(msg.value >= monkeyEvoPrice, "invalid price");

        for (uint256 i; i < _ggorillas.length; i++) {
            Animal memory _ggorilla = _ggorillas[i];
            NFTs[_ggorilla.evolution].burn(_ggorilla.tokenId);
        }
        
        // Galactic Gorillas
        NFTs[2].mint(msg.sender, uint(rg));
    }

          //////////////////
    function evolveAlienGorillas(Animal[] calldata _ggorillas) external payable {
        require(
            _ggorillas.length == 2,
            "Exactly 2 alien gorillas required for evolution"
        );
        uint256 totalRarity;
        for (uint256 i; i < _ggorillas.length; i++) {
            Animal memory _ggorilla = _ggorillas[i];
            require(
                isOwnedBySender(_ggorilla.tokenId, _ggorilla.evolution, msg.sender),
                "monkey not owned by sender"
            );
            require(verifyRarity(_ggorilla), "rarity data submitted not correct");
            totalRarity += _ggorilla.C;
        }
        uint256 avgRarity = totalRarity / _ggorillas.length;
    
        RarityGroup rg = roundRarity(avgRarity, 2);

        require(msg.value >= monkeyEvoPrice, "invalid price");

        for (uint256 i; i < _ggorillas.length; i++) {
            Animal memory _ggorilla = _ggorillas[i];
            NFTs[_ggorilla.evolution].burn(_ggorilla.tokenId);
        }
        
        // Eternal Yeti
        NFTs[3].mint(msg.sender, uint(rg));
    }

    function roundRarity(uint256 rarity, uint256 evo) internal pure returns (RarityGroup rg) {
        if (evo == 0) return roundMooningMonkey(rarity);
        if (evo == 1) return roundGalacticGorillas(rarity);
        if (evo == 2) return roundAlienGorillas(rarity);
    }
    // Rounding works by checking whether it is within a range that would round to that value 
    // then grouping by those ranges. Simple example: 0,1,2,3,4 rounds down. 5,6,7,8,9,10 rounds up.
    // You will notice in the example the round down group is 1 smaller than the round up group.
    // We are rounding to Contribution thresholds of RarityGroups rather than decimal base rounding.

    // 100, 105, 110, 115, 120 (5 gaps, 2.5 rounding limits, truncated)
    function roundMooningMonkey(uint256 rarity) internal pure returns (RarityGroup rg) {
        if (rarity > 100 && rarity <= 102) return RarityGroup.COMMON;
        if (rarity > 102 && rarity <= 107) return RarityGroup.UNCOMMON;
        if (rarity > 107 && rarity <= 112) return RarityGroup.RARE;
        if (rarity > 112 && rarity <= 117) return RarityGroup.SUPERRARE;
        if (rarity > 117 && rarity <= 120) return RarityGroup.LEGENDARY;
    }
    // 720, 756, 792, 828, 864 (36 gaps, 18 rounding limits)
    function roundGalacticGorillas(uint256 rarity) internal pure returns (RarityGroup rg) {
        if (rarity > 720 && rarity <= 737) return RarityGroup.COMMON;
        if (rarity > 737 && rarity <= 773) return RarityGroup.UNCOMMON;
        if (rarity > 773 && rarity <= 809) return RarityGroup.RARE;
        if (rarity > 809 && rarity <= 845) return RarityGroup.SUPERRARE;
        if (rarity > 845 && rarity <= 864) return RarityGroup.LEGENDARY;
    }
    // 3888, 4082, 4277, 4471, 4666 (194 gaps, 97 rounding limits)
    function roundAlienGorillas(uint256 rarity) internal pure returns (RarityGroup rg) {
        if (rarity > 3888 && rarity <= 3984) return RarityGroup.COMMON;
        if (rarity > 3984 && rarity <= 4179) return RarityGroup.UNCOMMON;
        if (rarity > 4179 && rarity <= 4373) return RarityGroup.RARE;
        if (rarity > 4373 && rarity <= 4567) return RarityGroup.SUPERRARE;
        if (rarity > 4666 && rarity <= 4762) return RarityGroup.LEGENDARY;
    }

    ///////////////////

    function isOwnedBySender(
        uint256 tokenId,
        uint8 evolution,
        address sender
    ) public view returns (bool) {
        require(
            NFTs[evolution] != IMMNFT(address(0x0)),
            "NFT contract for this evolution not set"
        );
        IMMNFT NFT = NFTs[evolution];
        return NFT.ownerOf(tokenId) == sender;
    }

    /*
     *  Merkle Root functions
     */

    function verifyRarity(Animal memory animal) internal view returns (bool) {
        return (
            verify(
                merkleRoots[animal.evolution],
                keccak256(abi.encodePacked(animal.tokenId, animal.C)),
                animal.proof
            )
        );
    }

    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function setEvolutionContract(uint256 index, IMMNFT _nft)
        public
        adminOrOwner
    {
        NFTs[index] = _nft;
    }

    function setMerkleRoot(uint256 index, bytes32 root) public adminOrOwner {
        merkleRoots[index] = root;
    }

    function addApproved(address user) public adminOrOwner {
        approvedAddresses[user] = true;
    }

    function removeApproved(address user) public adminOrOwner {
        delete approvedAddresses[user];
    }

    function setMonkeyEvoPrice(uint256 price) external adminOrOwner {
        monkeyEvoPrice = price;
    }

    function setGorillaEvoPrice(uint256 price) external adminOrOwner {
        gorillaEvoPrice = price;
    }

    function setAlienEvoPrice(uint256 price) external adminOrOwner {
        alienEvoPrice = price;
    }

    modifier adminOrOwner() {
        require(
            msg.sender == owner() || approvedAddresses[msg.sender],
            "Unauthorized"
        );
        _;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMMNFT {
    function adminMint(uint256 count, address to) external;
    function mint(address to, uint256 rarirty) external;
    function adminMint(uint256 count, address to, uint256 rarity) external;
    function burn(uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function supply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
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