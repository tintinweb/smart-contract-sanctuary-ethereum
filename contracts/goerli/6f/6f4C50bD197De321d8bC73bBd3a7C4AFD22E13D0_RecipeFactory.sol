// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

import "./interfaces/IRecipeFactory.sol";
import "./interfaces/IENS.sol";
import "./Recipe.sol";
import {MerkleProof} from "./openzeppelin/MerkleProof.sol";

contract RecipeFactory is IRecipeFactory {
    /// @inheritdoc IRecipeFactory
    address public override owner;
    /// @inheritdoc IRecipeFactory
    address public override ens;
    /// @inheritdoc IRecipeFactory
    bytes32 public override root;

    /// @inheritdoc IRecipeFactory
    mapping(bytes32 => address) public override recipes;
    mapping(bytes32 => bool) private verifier;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor(address _ens, bytes32 _root) {
        owner = msg.sender;
        ens = _ens;
        root = _root;
    }

    /// @inheritdoc IRecipeFactory
    function setOwner(address _owner) external override onlyOwner {
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IRecipeFactory
    function makeRecipe(bytes32[] memory _ingredients, bytes32[][] memory proofs) external override {
        require(_ingredients.length > 2 && _ingredients.length < 7, "IIL"); // incorrect ingredient length
        quickSort(_ingredients, int256(0), int256(_ingredients.length - 1));
        bytes32 hash = 0;
        bool has = false;
        address _owner;
        for (uint256 i = 0; i < _ingredients.length; i++) {
            require(MerkleProof.verify(proofs[i], root, _ingredients[i]), "!I"); // invalid ingredient
            require(!verifier[_ingredients[i]], "DI"); // duplicate ingredient
            hash = keccak256(abi.encode(_ingredients[i], hash));
            verifier[_ingredients[i]] = true;
            _owner = ENS(ens).owner(_ingredients[i]);
            has = has || _owner == msg.sender;
        }
        require(has, "!IO"); // not ingredient owner
        require(recipes[hash] == address(0), "DR"); // duplicate recipe
        clean(_ingredients);
        recipes[hash] = address(new Recipe{salt: hash}(_ingredients, ens));
        emit RecipeCreated(recipes[hash], _ingredients);
    }


    function clean(bytes32[] memory _ingredients) internal {
        for (uint256 i = 0; i < _ingredients.length; i++) {
            delete verifier[_ingredients[i]];
        }
    }

    function quickSort(
        bytes32[] memory arr,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        bytes32 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

import './interfaces/IRecipe.sol';
import './interfaces/IENS.sol';

contract Recipe is IRecipe {
    /// @inheritdoc IRecipe
    bytes32[] public override ingredientList;
    /// @inheritdoc IRecipe
    mapping(bytes32 => address) public override ingredientOwner;
    // @inheritdoc IRecipe
    mapping(bytes32 => bool) public override ingredients;
    // @inheritdoc IRecipe
    uint8 public override ingredientAmount;
    // @inheritdoc IRecipe
    uint8 public override ingredientCounter;
    // @inheritdoc IRecipe
    bool public override isFinished;
    // @inheritdoc IRecipe
    address public override ens;

    constructor(bytes32[] memory _ingredients, address _ens) {
        ingredientList = _ingredients;
        for (uint256 i = 0; i < _ingredients.length; i++) {
            ingredients[_ingredients[i]] = true;
        }
        ens = _ens;
        ingredientAmount = uint8(_ingredients.length);
    }

    // @inheritdoc IRecipe
    function addIngredient(bytes32 ingredient) external override{
        require(ingredientOwner[ingredient] == address(0), 'DI'); // duplicate ingredient
        require(ingredients[ingredient], '!I'); // not ingredient
        address _owner = ENS(ens).owner(ingredient);
        require(msg.sender == _owner, '!owner'); // not owner

        ingredientOwner[ingredient] = msg.sender;
        ingredientCounter++;
        emit IngredientAdded(ingredient, msg.sender);

        if (ingredientCounter == ingredientAmount) {
            isFinished = true;
            emit RecipeCompleted();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

/// @title The interface for the RecipeFactory
/// @notice The Recipe Factory allows new recipes to be deployed
interface IRecipeFactory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a recipe is created
    /// @param ingredients The ingredients needed for the recipe
    event RecipeCreated(address recipeAddress, bytes32[] ingredients);

    /// @notice Returns the recipe's address
    /// @param key The byte32 representation of the recipe
    /// @return The address of the recipe
    function recipes(bytes32 key) external view returns (address);

    /// @notice Returns the contract owner
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the ens contract
    /// @return The address of the ens contract
    function ens() external view returns (address);

    /// @notice Returns the root of the ingredients Merkle proof
    /// @return Returns the root of the ingredients Merkle proof
    function root() external view returns (bytes32);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Creates a new recipe
    /// @param ingredients The ingredients for the recipe
    function makeRecipe(
        bytes32[] memory ingredients,
        bytes32[][] memory proofs
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

abstract contract ENS {
    function owner(bytes32 node) external virtual view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
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
     * @dev Calldata version of {processMultiProof}
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
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

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
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

interface IRecipe {
    event RecipeCompleted();
    event IngredientAdded(bytes32 ingredient, address owner);

    /// @notice Returns the amount of ingredients in the recipe
    /// @return The amount of ingredients in the recipe
    function ingredientAmount() external view returns(uint8);

    /// @notice Returns the counter of ingredients cooked
    /// @return The counter of ingredients cooked
    function ingredientCounter() external view returns(uint8);

    /// @notice Returns the ens contract address
    /// @return The ens contract address
    function ens() external view returns (address);

    /// @notice Returns the state of the recipe
    /// @return True if the recipe is finished
    function isFinished() external view returns (bool);

    /// @notice Returns the ingredient at index
    /// @param index The index
    /// @return The ingredient at index
    function ingredientList(uint index) external view returns(bytes32);

    /// @notice Returns the address of the ingredient owner
    /// @param ingredient The ingredient
    /// @return The address of the ingredient owner
    function ingredientOwner(bytes32 ingredient) external view returns(address);

    /// @notice Returns true if ingredient is part of the recipe
    /// @param ingredient The ingredient
    /// @return True if ingredient is part of the recipe
    function ingredients(bytes32 ingredient) external view returns(bool);

    /// @notice Add an ingredient to the recipe
    /// @param ingredient The ingredient to add
    function addIngredient(bytes32 ingredient) external;
}