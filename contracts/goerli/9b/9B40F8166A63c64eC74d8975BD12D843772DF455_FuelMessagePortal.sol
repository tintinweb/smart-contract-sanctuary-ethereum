// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/// @notice Merkle Tree Node structure.
struct BinaryMerkleProof {
    bytes32[] proof;
    uint256 key;
    uint256 numLeaves;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {Node} from "./Node.sol";
import {nodeDigest, leafDigest, hashNode} from "./TreeHasher.sol";
import {hashLeaf} from "./TreeHasher.sol";
import {MerkleBranch} from "./Branch.sol";
import {BinaryMerkleProof} from "./BinaryMerkleProof.sol";
import {Constants} from "../Constants.sol";
import {pathLengthFromKey, getStartingBit} from "../Utils.sol";
import {getBitAtFromMSB} from "../Utils.sol";
import {verifyBinaryTree, verifyBinaryTreeDigest} from "./BinaryMerkleTreeUtils.sol";
import {computeBinaryTreeRoot} from "./BinaryMerkleTreeUtils.sol";
import {getPtrToNode, getNodeAtPtr} from "./BinaryMerkleTreeUtils.sol";
import {addBranch, sideNodesForRoot} from "./BinaryMerkleTreeUtils.sol";

/// @title Binary Merkle Tree.
/// @notice spec can be found at https://github.com/FuelLabs/fuel-specs/blob/master/specs/protocol/cryptographicprimitives.md#binary-merkle-tree.
library BinaryMerkleTree {
    /// @notice Verify if element (key, data) exists in Merkle tree, given data, proof, and root.
    /// @param root: The root of the tree in which verify the given leaf
    /// @param data: The data of the leaf to verify
    /// @param key: The key of the leaf to verify.
    /// @param proof: Binary Merkle Proof for the leaf.
    /// @param numLeaves: The number of leaves in the tree
    /// @return : Whether the proof is valid
    /// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
    function verify(
        bytes32 root,
        bytes memory data,
        bytes32[] memory proof,
        uint256 key,
        uint256 numLeaves
    ) public pure returns (bool) {
        return verifyBinaryTree(root, data, proof, key, numLeaves);
    }

    /// @notice Verify if element (key, digest) exists in Merkle tree, given digest, proof, and root.
    /// @param root: The root of the tree in which verify the given leaf
    /// @param digest: The digest of the data of the leaf to verify
    /// @param key: The key of the leaf to verify.
    /// @param proof: Binary Merkle Proof for the leaf.
    /// @param numLeaves: The number of leaves in the tree
    /// @return : Whether the proof is valid
    /// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
    function verifyDigest(
        bytes32 root,
        bytes32 digest,
        bytes32[] memory proof,
        uint256 key,
        uint256 numLeaves
    ) public pure returns (bool) {
        return verifyBinaryTreeDigest(root, digest, proof, key, numLeaves);
    }

    /// @notice Computes Merkle tree root from leaves.
    /// @param data: list of leaves' data in ascending for leaves order.
    /// @return : The root of the tree
    function computeRoot(bytes[] memory data) public pure returns (bytes32) {
        return computeBinaryTreeRoot(data);
    }

    /// @notice Appends a new element by calculating new root, returns new root and if successful, pure function.
    /// @param numLeaves, number of leaves in the tree currently.
    /// @param data, The data of the leaf to append.
    /// @param proof, Binary Merkle Proof to use for the leaf.
    /// @return : The root of the new tree
    /// @return : Whether the proof is valid
    function append(
        uint256 numLeaves,
        bytes memory data,
        bytes32[] memory proof
    ) public pure returns (bytes32, bool) {
        bytes32 digest = leafDigest(data);

        // Since appended leaf is last leaf in tree by definition, its path consists only of set bits
        // (because all side nodes will be on its left)
        // Therefore, the number of steps in the proof should equal number of bits set in the key
        // E.g. If appending the 7th leaf, key = 0b110 => proofLength = 2.

        uint256 proofLength = 0;
        while (numLeaves > 0) {
            proofLength += numLeaves & 1;
            numLeaves = numLeaves >> 1;
        }

        if (proof.length != proofLength) {
            return (Constants.NULL, false);
        }

        // If proof length is correctly 0, tree is empty, and we are appending the first leaf
        if (proofLength == 0) {
            digest = leafDigest(data);
        }
        // Otherwise tree non-empty so we calculate nodes up to root
        else {
            for (uint256 i = 0; i < proofLength; ++i) {
                digest = nodeDigest(proof[i], digest);
            }
        }

        return (digest, true);
    }

    /// @notice Update a given leaf
    /// @param key: The key of the leaf to be added
    /// @param value: The data to update the leaf with
    /// @param sideNodes: The sideNodes from the leaf to the root
    /// @param numLeaves: The total number of leaves in the tree
    /// @return currentPtr : The pointer to the root of the tree
    function updateWithSideNodes(
        bytes32 key,
        bytes memory value,
        bytes32[] memory sideNodes,
        uint256 numLeaves
    ) public pure returns (bytes32 currentPtr) {
        Node memory currentNode = hashLeaf(value);
        currentPtr = getPtrToNode(currentNode);

        // If numleaves <= 1, then the root is just the leaf hash (or ZERO)
        if (numLeaves > 1) {
            uint256 startingBit = getStartingBit(numLeaves);
            uint256 pathLength = pathLengthFromKey(uint256(key), numLeaves);

            for (uint256 i = 0; i < pathLength; i += 1) {
                if (getBitAtFromMSB(key, startingBit + pathLength - 1 - i) == 1) {
                    currentNode = hashNode(
                        sideNodes[i],
                        currentPtr,
                        getNodeAtPtr(sideNodes[i]).digest,
                        currentNode.digest
                    );
                } else {
                    currentNode = hashNode(
                        currentPtr,
                        sideNodes[i],
                        currentNode.digest,
                        getNodeAtPtr(sideNodes[i]).digest
                    );
                }

                currentPtr = getPtrToNode(currentNode);
            }
        }
    }

    /// @notice Add an array of branches and update one of them
    /// @param branches: The array of branches to add
    /// @param root: The root of the tree
    /// @param key: The key of the leaf to be added
    /// @param value: The data to update the leaf with
    /// @param numLeaves: The total number of leaves in the tree
    /// @return newRoot : The new root of the tree
    function addBranchesAndUpdate(
        MerkleBranch[] memory branches,
        bytes32 root,
        bytes32 key,
        bytes memory value,
        uint256 numLeaves
    ) public pure returns (bytes32 newRoot) {
        bytes32 rootPtr = Constants.ZERO;
        for (uint256 i = 0; i < branches.length; i++) {
            rootPtr = addBranch(
                branches[i].key,
                branches[i].value,
                branches[i].proof,
                root,
                rootPtr,
                numLeaves
            );
        }

        bytes32[] memory sideNodes = sideNodesForRoot(key, rootPtr, numLeaves);
        bytes32 newRootPtr = updateWithSideNodes(key, value, sideNodes, numLeaves);

        return getNodeAtPtr(newRootPtr).digest;
    }

    /// @notice Derive the proof for a new appended leaf from the proof for the last appended leaf
    /// @param oldProof: The proof to the last appeneded leaf
    /// @param lastLeaf: The last leaf hash
    /// @param key: The key of the new leaf
    /// @return : The proof for the appending of the new leaf
    /// @dev This function assumes that oldProof has been verified in position (key - 1)
    function deriveAppendProofFromLastProof(
        bytes32[] memory oldProof,
        bytes32 lastLeaf,
        uint256 key
    ) public pure returns (bytes32[] memory) {
        // First prepend last leaf to its proof.
        bytes32[] memory newProofBasis = new bytes32[](oldProof.length + 1);
        newProofBasis[0] = leafDigest(abi.encodePacked(lastLeaf));
        for (uint256 i = 0; i < oldProof.length; i += 1) {
            newProofBasis[i + 1] = oldProof[i];
        }

        // If the new leaf is "even", this will already be the new proof
        if (key & 1 == 1) {
            return newProofBasis;
        }

        // Otherwise, get the expected length of the new proof (it's the last leaf by definition, so numLeaves = key + 1)
        // Assuming old proof was valid, this will always be shorter than the old proof.
        uint256 expectedProofLength = pathLengthFromKey(key, key + 1);

        bytes32[] memory newProof = new bytes32[](expectedProofLength);

        // "Hash up" through old proof until we have the correct first sidenode
        bytes32 firstSideNode = newProofBasis[0];
        uint256 hashedUpIndex = 0;
        while (hashedUpIndex < (newProofBasis.length - expectedProofLength)) {
            firstSideNode = nodeDigest(newProofBasis[hashedUpIndex + 1], firstSideNode);
            hashedUpIndex += 1;
        }

        // Set the calculated first side node as the first element in the proof
        newProof[0] = firstSideNode;

        // Then append the remaining (unchanged) sidenodes, if any
        for (uint256 j = 1; j < expectedProofLength; j += 1) {
            newProof[j] = newProofBasis[hashedUpIndex + j];
        }

        return newProof;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {Node} from "./Node.sol";
import {nodeDigest, leafDigest} from "./TreeHasher.sol";
import {parseNode, isLeaf} from "./TreeHasher.sol";
import {BinaryMerkleProof} from "./BinaryMerkleProof.sol";
import {Constants} from "../Constants.sol";
import {pathLengthFromKey, getStartingBit} from "../Utils.sol";
import {getBitAtFromMSB, reverseSideNodes} from "../Utils.sol";
import {shrinkBytes32Array} from "../Utils.sol";

/// @notice Get the pointer to a node in memory
/// @param node: The node to get the pointer to
/// @return ptr : The pointer to the node
// solhint-disable-next-line func-visibility
function getPtrToNode(Node memory node) pure returns (bytes32 ptr) {
    assembly {
        ptr := node
    }
}

/// @notice Get a node at a given pointer
/// @param ptr: The pointer to the node
/// @return node : The node
// solhint-disable-next-line func-visibility
function getNodeAtPtr(bytes32 ptr) pure returns (Node memory node) {
    assembly {
        node := ptr
    }
}

/// @notice Verify if element (key, data) exists in Merkle tree, given data, proof, and root.
/// @param root: The root of the tree in which verify the given leaf
/// @param data: The data of the leaf to verify
/// @param key: The key of the leaf to verify.
/// @param proof: Binary Merkle Proof for the leaf.
/// @param numLeaves: The number of leaves in the tree
/// @return : Whether the proof is valid
/// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
// solhint-disable-next-line func-visibility
function verifyBinaryTree(
    bytes32 root,
    bytes memory data,
    bytes32[] memory proof,
    uint256 key,
    uint256 numLeaves
) pure returns (bool) {
    // A sibling at height 1 is created by getting the hash of the data to prove.
    return verifyBinaryTreeDigest(root, leafDigest(data), proof, key, numLeaves);
}

/// @notice Verify if element (key, digest) exists in Merkle tree, given digest, proof, and root.
/// @param root: The root of the tree in which verify the given leaf
/// @param digest: The digest of the data of the leaf to verify
/// @param key: The key of the leaf to verify.
/// @param proof: Binary Merkle Proof for the leaf.
/// @param numLeaves: The number of leaves in the tree
/// @return : Whether the proof is valid
/// @dev numLeaves is necessary to determine height of sub-tree containing the data to prove
// solhint-disable-next-line func-visibility
function verifyBinaryTreeDigest(
    bytes32 root,
    bytes32 digest,
    bytes32[] memory proof,
    uint256 key,
    uint256 numLeaves
) pure returns (bool) {
    // Check proof is correct length for the key it is proving
    if (numLeaves <= 1) {
        if (proof.length != 0) {
            return false;
        }
    } else if (proof.length != pathLengthFromKey(key, numLeaves)) {
        return false;
    }

    // Check key is in tree
    if (key >= numLeaves) {
        return false;
    }

    // Null proof is only valid if numLeaves = 1
    // If so, just verify digest is root
    if (proof.length == 0) {
        if (numLeaves == 1) {
            return (root == digest);
        } else {
            return false;
        }
    }

    uint256 height = 1;
    uint256 stableEnd = key;

    // While the current subtree (of height 'height') is complete, determine
    // the position of the next sibling using the complete subtree algorithm.
    // 'stableEnd' tells us the ending index of the last full subtree. It gets
    // initialized to 'key' because the first full subtree was the
    // subtree of height 1, created above (and had an ending index of
    // 'key').

    while (true) {
        // Determine if the subtree is complete. This is accomplished by
        // rounding down the key to the nearest 1 << 'height', adding 1
        // << 'height', and comparing the result to the number of leaves in the
        // Merkle tree.

        uint256 subTreeStartIndex = (key / (1 << height)) * (1 << height);
        uint256 subTreeEndIndex = subTreeStartIndex + (1 << height) - 1;

        // If the Merkle tree does not have a leaf at index
        // 'subTreeEndIndex', then the subtree of the current height is not
        // a complete subtree.
        if (subTreeEndIndex >= numLeaves) {
            break;
        }
        stableEnd = subTreeEndIndex;

        // Determine if the key is in the first or the second half of
        // the subtree.
        if (proof.length <= height - 1) {
            return false;
        }
        if (key - subTreeStartIndex < (1 << (height - 1))) {
            digest = nodeDigest(digest, proof[height - 1]);
        } else {
            digest = nodeDigest(proof[height - 1], digest);
        }

        height += 1;
    }

    // Determine if the next hash belongs to an orphan that was elevated. This
    // is the case IFF 'stableEnd' (the last index of the largest full subtree)
    // is equal to the number of leaves in the Merkle tree.
    if (stableEnd != numLeaves - 1) {
        if (proof.length <= height - 1) {
            return false;
        }
        digest = nodeDigest(digest, proof[height - 1]);
        height += 1;
    }

    // All remaining elements in the proof set will belong to a left sibling\
    // i.e proof sideNodes are hashed in "from the left"
    while (height - 1 < proof.length) {
        digest = nodeDigest(proof[height - 1], digest);
        height += 1;
    }

    return (digest == root);
}

/// @notice Computes Merkle tree root from leaves.
/// @param data: list of leaves' data in ascending for leaves order.
/// @return : The root of the tree
// solhint-disable-next-line func-visibility
function computeBinaryTreeRoot(bytes[] memory data) pure returns (bytes32) {
    if (data.length == 0) {
        return Constants.EMPTY;
    }
    bytes32[] memory nodes = new bytes32[](data.length);
    for (uint256 i = 0; i < data.length; ++i) {
        nodes[i] = leafDigest(data[i]);
    }
    uint256 size = (nodes.length + 1) >> 1;
    uint256 odd = nodes.length & 1;
    // pNodes are nodes in previous level.
    // We use pNodes to avoid damaging the input leaves.
    bytes32[] memory pNodes = nodes;
    while (true) {
        uint256 i = 0;
        for (; i < size - odd; ++i) {
            uint256 j = i << 1;
            nodes[i] = nodeDigest(pNodes[j], pNodes[j + 1]);
        }
        if (odd == 1) {
            nodes[i] = pNodes[i << 1];
        }
        if (size == 1) {
            break;
        }
        odd = (size & 1);
        size = (size + 1) >> 1;
        pNodes = nodes;
    }
    return nodes[0];
}

/// @notice Appends a new element by calculating new root, returns new root and if successful, pure function.
/// @param numLeaves, number of leaves in the tree currently.
/// @param data, The data of the leaf to append.
/// @param proof, Binary Merkle Proof to use for the leaf.
/// @return : The root of the new tree
/// @return : Whether the proof is valid
// solhint-disable-next-line func-visibility
function appendBinaryTree(
    uint256 numLeaves,
    bytes memory data,
    bytes32[] memory proof
) pure returns (bytes32, bool) {
    bytes32 digest = leafDigest(data);

    // Since appended leaf is last leaf in tree by definition, its path consists only of set bits
    // (because all side nodes will be on its left)
    // Therefore, the number of steps in the proof should equal number of bits set in the key
    // E.g. If appending the 7th leaf, key = 0b110 => proofLength = 2.

    uint256 proofLength = 0;
    while (numLeaves > 0) {
        proofLength += numLeaves & 1;
        numLeaves = numLeaves >> 1;
    }

    if (proof.length != proofLength) {
        return (Constants.NULL, false);
    }

    // If proof length is correctly 0, tree is empty, and we are appending the first leaf
    if (proofLength == 0) {
        digest = leafDigest(data);
    }
    // Otherwise tree non-empty so we calculate nodes up to root
    else {
        for (uint256 i = 0; i < proofLength; ++i) {
            digest = nodeDigest(proof[i], digest);
        }
    }

    return (digest, true);
}

/// @notice Adds a branch to the in-storage sparse representation of tree
/// @dev We store the minimum subset of nodes necessary to calculate the root
/// @param key: The key of the leaf
/// @param value : The data of the leaf
/// @param root : The root of the tree containing the added branch
/// @param rootPtr : The pointer to the root node
/// @param proof: The proof (assumed valid) of the leaf up to the root
/// @param numLeaves: The total number of leaves in the tree
/// @return : The pointer to the root node
// solhint-disable-next-line func-visibility
function addBranch(
    bytes32 key,
    bytes memory value,
    bytes32[] memory proof,
    bytes32 root,
    bytes32 rootPtr,
    uint256 numLeaves
) pure returns (bytes32) {
    // Handle case where tree has only one leaf (so it is the root)
    if (numLeaves == 1) {
        Node memory rootNode = Node(root, Constants.NULL, Constants.NULL);
        rootPtr = getPtrToNode(rootNode);
        return rootPtr;
    }
    uint256 startingBit = getStartingBit(numLeaves);

    AddBranchVariables memory variables;

    bytes32[] memory sideNodePtrs = new bytes32[](proof.length);
    bytes32[] memory nodePtrs = new bytes32[](proof.length);

    // Set root
    // When adding the first branch, rootPtr will not be set yet, set it here.
    if (rootPtr == Constants.NULL) {
        // Set the new root
        Node memory rootNode = Node(root, Constants.NULL, Constants.NULL);
        rootPtr = getPtrToNode(rootNode);
        variables.parent = rootNode;
    }
    // On subsequent branches, we need to retrieve root
    else {
        variables.parent = getNodeAtPtr(rootPtr);
    }

    // Step backwards through proof (from root down to leaf), getting pointers to the nodes/sideNodes
    // If node is not yet added, set digest to NULL (we'll set it when we hash back up the branch)
    for (uint256 i = proof.length; i > 0; i -= 1) {
        uint256 j = i - 1;

        // Descend into left or right subtree depending on key
        // If leaf is in the right subtree:
        if (getBitAtFromMSB(key, startingBit + proof.length - i) == 1) {
            // Subtree is on the right, so sidenode is on the left.
            // Check to see if sidenode already exists. If not, create it. and associate with parent
            if (variables.parent.leftChildPtr == Constants.NULL) {
                variables.sideNode = Node(proof[j], Constants.NULL, Constants.NULL);
                variables.sideNodePtr = getPtrToNode(variables.sideNode);
                variables.parent.leftChildPtr = variables.sideNodePtr;
            } else {
                variables.sideNodePtr = variables.parent.leftChildPtr;
            }

            // Check to see if node already exists. If not, create it. and associate with parent
            // Its digest is initially null. We calculate and set it when we climb back up the tree
            if (variables.parent.rightChildPtr == Constants.NULL) {
                variables.node = Node(Constants.NULL, Constants.NULL, Constants.NULL);
                variables.nodePtr = getPtrToNode(variables.node);
                variables.parent.rightChildPtr = variables.nodePtr;
            } else {
                variables.nodePtr = variables.parent.rightChildPtr;
                variables.node = getNodeAtPtr(variables.nodePtr);
            }

            // Mirror image of preceding code block, for when leaf is in the left subtree
            // If subtree is on the left, sideNode is on the right
        } else {
            if (variables.parent.rightChildPtr == Constants.NULL) {
                variables.sideNode = Node(proof[j], Constants.NULL, Constants.NULL);
                variables.sideNodePtr = getPtrToNode(variables.sideNode);
                variables.parent.rightChildPtr = variables.sideNodePtr;
            } else {
                variables.sideNodePtr = variables.parent.rightChildPtr;
            }

            if (variables.parent.leftChildPtr == Constants.NULL) {
                variables.node = Node(Constants.NULL, Constants.NULL, Constants.NULL);
                variables.nodePtr = getPtrToNode(variables.node);
                variables.parent.leftChildPtr = variables.nodePtr;
            } else {
                variables.nodePtr = variables.parent.leftChildPtr;
                variables.node = getNodeAtPtr(variables.nodePtr);
            }
        }

        // Keep pointers to sideNode and node
        sideNodePtrs[j] = variables.sideNodePtr;
        nodePtrs[j] = variables.nodePtr;

        variables.parent = variables.node;
    }

    // Set leaf digest
    Node memory leaf = getNodeAtPtr(nodePtrs[0]);
    leaf.digest = leafDigest(value);

    if (proof.length == 0) {
        return rootPtr;
    }

    // Go back up the tree, setting the digests of nodes on the branch
    for (uint256 i = 1; i < nodePtrs.length; i += 1) {
        variables.node = getNodeAtPtr(nodePtrs[i]);
        variables.node.digest = nodeDigest(
            getNodeAtPtr(variables.node.leftChildPtr).digest,
            getNodeAtPtr(variables.node.rightChildPtr).digest
        );
    }

    return rootPtr;
}

/// @notice Get the sidenodes for a given leaf key up to the root
/// @param key: The key for which to find the sidenodes
/// @param rootPtr: The memory pointer to the root of the tree
/// @param numLeaves : The total number of leaves in the tree
/// @return The sidenodes up to the root.
// solhint-disable-next-line func-visibility
function sideNodesForRoot(
    bytes32 key,
    bytes32 rootPtr,
    uint256 numLeaves
) pure returns (bytes32[] memory) {
    // Allocate a large enough array for the sidenodes (we'll shrink it later)
    bytes32[] memory sideNodes = new bytes32[](256);

    Node memory currentNode = getNodeAtPtr(rootPtr);

    // If the root is a placeholder, the tree is empty, so there are no sidenodes to return.
    // The leaf pointer is the root pointer
    if (currentNode.digest == Constants.ZERO) {
        bytes32[] memory emptySideNodes;
        return emptySideNodes;
    }

    // If the root is a leaf, the tree has only one leaf, so there are also no sidenodes to return.
    // The leaf pointer is the root pointer
    if (isLeaf(currentNode)) {
        bytes32[] memory emptySideNodes;
        return emptySideNodes;
    }

    // Tree has at least 2 leaves
    SideNodesFunctionVariables memory variables;

    variables.sideNodeCount = 0;

    uint256 startingBit = getStartingBit(numLeaves);
    uint256 pathLength = pathLengthFromKey(uint256(key), numLeaves);

    // Descend the tree from the root according to the key, collecting side nodes
    for (uint256 i = startingBit; i < startingBit + pathLength; i++) {
        (variables.leftNodePtr, variables.rightNodePtr) = parseNode(currentNode);
        // Bifurcate left or right depending on bit in key
        if (getBitAtFromMSB(key, i) == 1) {
            (variables.nodePtr, variables.sideNodePtr) = (
                variables.rightNodePtr,
                variables.leftNodePtr
            );
        } else {
            (variables.nodePtr, variables.sideNodePtr) = (
                variables.leftNodePtr,
                variables.rightNodePtr
            );
        }

        sideNodes[variables.sideNodeCount] = variables.sideNodePtr;
        variables.sideNodeCount += 1;

        currentNode = getNodeAtPtr(variables.nodePtr);
    }

    return reverseSideNodes(shrinkBytes32Array(sideNodes, variables.sideNodeCount));
}

struct AddBranchVariables {
    bytes32 nodePtr;
    bytes32 sideNodePtr;
    Node node;
    Node parent;
    Node sideNode;
}

/// @notice A struct to hold variables of the sidenodes function in memory
/// @dev Necessary to circumvent stack-too-deep errors caused by too many
/// @dev variables on the stack.
struct SideNodesFunctionVariables {
    bytes32 leftNodePtr;
    bytes32 rightNodePtr;
    bytes32 nodePtr;
    bytes32 sideNodePtr;
    uint256 sideNodeCount;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

struct MerkleBranch {
    bytes32[] proof;
    bytes32 key;
    bytes value;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/// @notice Merkle Tree Node structure.
struct Node {
    bytes32 digest;
    // Left child.
    bytes32 leftChildPtr;
    // Right child.
    bytes32 rightChildPtr;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {CryptographyLib} from "../Cryptography.sol";
import {Constants} from "../Constants.sol";
import {Node} from "./Node.sol";

/// @notice hash some data
/// @param data: The data to be hashed
// solhint-disable-next-line func-visibility
function hash(bytes memory data) pure returns (bytes32) {
    return CryptographyLib.hash(data);
}

/// @notice Calculate the digest of a node
/// @param left : The left child
/// @param right: The right child
/// @return digest : The node digest
// solhint-disable-next-line func-visibility
function nodeDigest(bytes32 left, bytes32 right) pure returns (bytes32 digest) {
    digest = hash(abi.encodePacked(Constants.NODE_PREFIX, left, right));
}

/// @notice Calculate the digest of a leaf
/// @param data : The data of the leaf
/// @return digest : The leaf digest
// solhint-disable-next-line func-visibility
function leafDigest(bytes memory data) pure returns (bytes32 digest) {
    digest = hash(abi.encodePacked(Constants.LEAF_PREFIX, data));
}

/// @notice Hash a leaf node.
/// @param data, raw data of the leaf.
/// @return The leaf represented as a Node struct
// solhint-disable-next-line func-visibility
function hashLeaf(bytes memory data) pure returns (Node memory) {
    bytes32 digest = leafDigest(data);
    return Node(digest, Constants.NULL, Constants.NULL);
}

/// @notice Hash a node, which is not a leaf.
/// @param left, left child hash.
/// @param right, right child hash.
/// @param leftPtr, the pointer to the left child
/// @param rightPtr, the pointer to the right child
/// @return : The new Node object
// solhint-disable-next-line func-visibility
function hashNode(
    bytes32 leftPtr,
    bytes32 rightPtr,
    bytes32 left,
    bytes32 right
) pure returns (Node memory) {
    bytes32 digest = nodeDigest(left, right);
    return Node(digest, leftPtr, rightPtr);
}

/// @notice Parse a node's data into its left and right children
/// @param node: The node to be parsed
/// @return : Pointers to the left and right children
// solhint-disable-next-line func-visibility
function parseNode(Node memory node) pure returns (bytes32, bytes32) {
    return (node.leftChildPtr, node.rightChildPtr);
}

/// @notice See if node has children, otherwise it is a leaf
/// @param node: The node to be parsed
/// @return : Whether the node is a leaf.
// solhint-disable-next-line func-visibility
function isLeaf(Node memory node) pure returns (bool) {
    return (node.leftChildPtr == Constants.ZERO || node.rightChildPtr == Constants.ZERO);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

library Constants {
    ///////////////
    // Constants //
    ///////////////

    /// @dev Maximum tree height
    uint256 internal constant MAX_HEIGHT = 256;

    /// @dev Empty node hash
    bytes32 internal constant EMPTY = sha256("");

    /// @dev Default value for sparse Merkle tree node
    bytes32 internal constant ZERO = bytes32(0);

    /// @dev The null pointer
    bytes32 internal constant NULL = bytes32(0);

    /// @dev The prefixes of leaves and nodes
    bytes1 internal constant LEAF_PREFIX = 0x00;
    bytes1 internal constant NODE_PREFIX = 0x01;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

/// @notice This library abstracts the hashing function used for the merkle tree implementation
library CryptographyLib {
    /// @notice The hash method
    /// @param data The bytes input data.
    /// @return The returned hash result.
    function hash(bytes memory data) internal pure returns (bytes32) {
        return sha256(data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import {Constants} from "./Constants.sol";

/// @notice Calculate the starting bit of the path to a leaf
/// @param numLeaves : The total number of leaves in the tree
/// @return startingBit : The starting bit of the path
// solhint-disable-next-line func-visibility
function getStartingBit(uint256 numLeaves) pure returns (uint256 startingBit) {
    // Determine height of the left subtree. This is the maximum path length, so all paths start at this offset from the right-most bit
    startingBit = 0;
    while ((1 << startingBit) < numLeaves) {
        startingBit += 1;
    }
    return Constants.MAX_HEIGHT - startingBit;
}

/// @notice Calculate the length of the path to a leaf
/// @param key: The key of the leaf
/// @param numLeaves: The total number of leaves in the tree
/// @return pathLength : The length of the path to the leaf
/// @dev A precondition to this function is that `numLeaves > 1`, so that `(pathLength - 1)` does not cause an underflow when pathLength = 0.
// solhint-disable-next-line func-visibility
function pathLengthFromKey(uint256 key, uint256 numLeaves) pure returns (uint256 pathLength) {
    // Get the height of the left subtree. This is equal to the offset of the starting bit of the path
    pathLength = 256 - getStartingBit(numLeaves);

    // Determine the number of leaves in the left subtree
    uint256 numLeavesLeftSubTree = (1 << (pathLength - 1));

    // If leaf is in left subtree, path length is full height of left subtree
    if (key <= numLeavesLeftSubTree - 1) {
        return pathLength;
    }
    // Otherwise, if left sub tree has only one leaf, path has one additional step
    else if (numLeavesLeftSubTree == 1) {
        return 1;
    }
    // Otherwise, if right sub tree has only one leaf, path has one additional step
    else if (numLeaves - numLeavesLeftSubTree <= 1) {
        return 1;
    }
    // Otherwise, add 1 to height and recurse into right subtree
    else {
        return 1 + pathLengthFromKey(key - numLeavesLeftSubTree, numLeaves - numLeavesLeftSubTree);
    }
}

/// @notice Gets the bit at an offset from the most significant bit
/// @param data: The data to check the bit
/// @param position: The position of the bit to check
// solhint-disable-next-line func-visibility
function getBitAtFromMSB(bytes32 data, uint256 position) pure returns (uint256) {
    if (uint8(data[position / 8]) & (1 << (8 - 1 - (position % 8))) > 0) {
        return 1;
    } else {
        return 0;
    }
}

/// @notice Reverses an array
/// @param sideNodes: The array of sidenodes to be reversed
/// @return The reversed array
// solhint-disable-next-line func-visibility
function reverseSideNodes(bytes32[] memory sideNodes) pure returns (bytes32[] memory) {
    uint256 left = 0;
    uint256 right = sideNodes.length - 1;

    while (left < right) {
        (sideNodes[left], sideNodes[right]) = (sideNodes[right], sideNodes[left]);
        left = left + 1;
        right = right - 1;
    }
    return sideNodes;
}

/// @notice Counts the number of leading bits two bytes32 have in common
/// @param data1: The first piece of data to compare
/// @param data2: The second piece of data to compare
/// @return The number of shared leading bits
// solhint-disable-next-line func-visibility
function countCommonPrefix(bytes32 data1, bytes32 data2) pure returns (uint256) {
    uint256 count = 0;

    for (uint256 i = 0; i < Constants.MAX_HEIGHT; i++) {
        if (getBitAtFromMSB(data1, i) == getBitAtFromMSB(data2, i)) {
            count += 1;
        } else {
            break;
        }
    }
    return count;
}

/// @notice Shrinks an over-allocated dynamic array of bytes32 to the correct size
/// @param inputArray: The bytes32 array to be shrunk
/// @param length: The length to shrink to
/// @return finalArray : The full array of bytes32
/// @dev Needed where an unknown number of elements are to be pushed to a dynamic array
/// @dev We fist allocate a large-enough array, and then shrink once we're done populating it
// solhint-disable-next-line func-visibility
function shrinkBytes32Array(bytes32[] memory inputArray, uint256 length)
    pure
    returns (bytes32[] memory finalArray)
{
    finalArray = new bytes32[](length);
    for (uint256 i = 0; i < length; i++) {
        finalArray[i] = inputArray[i];
    }
    return finalArray;
}

/// @notice compares a byte array to the (bytes32) default (ZERO) value
/// @param value : The bytes to compare
/// @dev No byte array comparison in solidity, so compare keccak hashes
// solhint-disable-next-line func-visibility
function isDefaultValue(bytes memory value) pure returns (bool) {
    return keccak256(value) == keccak256(abi.encodePacked(Constants.ZERO));
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @notice This is the Fuel protocol cryptography library.
library CryptographyLib {
    /////////////
    // Methods //
    /////////////

    // secp256k1n / 2
    uint256 private constant MAX_SIGNATURE_S_VALUE = 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /// @notice The primary hash method for Fuel.
    /// @param data The bytes input data.
    /// @return The returned hash result.
    function hash(bytes memory data) internal pure returns (bytes32) {
        return sha256(data);
    }

    function addressFromSignatureComponents(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 message
    ) internal pure returns (address) {
        // reject high s values to prevent signature malleability
        // https://eips.ethereum.org/EIPS/eip-2
        require(uint256(s) <= MAX_SIGNATURE_S_VALUE, "signature-invalid-s");

        address signer = ecrecover(message, v, r, s);
        require(signer != address(0), "signature-invalid");

        return signer;
    }

    /// @notice Get the signing address from a signature and the signed data
    /// @param signature: The compact (64 byte) ECDSA signature
    /// @param message: The message which was signed over
    /// @return : The address of the signer, or address(0) in case of an error
    function addressFromSignature(bytes memory signature, bytes32 message) internal pure returns (address) {
        // ECDSA signatures must be 64 bytes (https://eips.ethereum.org/EIPS/eip-2098)
        require(signature.length == 64, "signature-invalid-length");

        // Signature is concatenation of r and v-s, both 32 bytes
        // https://github.com/celestiaorg/celestia-specs/blob/ec98170398dfc6394423ee79b00b71038879e211/src/specs/data_structures.md#signature
        bytes32 vs;
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, vs) = abi.decode(signature, (bytes32, bytes32));

        // v is first bit of vs as uint8
        // yParity parameter is always either 0 or 1 (canonically the values used have been 27 and 28), so adjust accordingly
        v = 27 + uint8(uint256(vs) & (1 << 255) > 0 ? 1 : 0);

        // s is vs with first bit replaced by a 0
        s = bytes32((uint256(vs) << 1) >> 1);

        return addressFromSignatureComponents(v, r, s, message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @notice Common predicates for Fuel InputMessages
library InputMessagePredicates {
    bytes32 public constant CONTRACT_MESSAGE_PREDICATE =
        0xc453f2ed45abb180e0a17aa88e78941eb8169c5f949ee218b45afcb0cfd2c0a8;
}

/// @title IFuelMessagePortal
/// @notice The Fuel Message Portal contract sends and receives messages between the EVM and Fuel
interface IFuelMessagePortal {
    ////////////
    // Events //
    ////////////

    /// @notice Emitted when a Message is sent from the EVM to Fuel
    event SentMessage(bytes32 indexed sender, bytes32 indexed recipient, uint64 nonce, uint64 amount, bytes data);

    ///////////////////////////////
    // Public Functions Outgoing //
    ///////////////////////////////

    /// @notice Send a message to a recipient on Fuel
    /// @param recipient The message receiver address or predicate root
    /// @param data The message data to be sent to the receiver
    function sendMessage(bytes32 recipient, bytes memory data) external payable;

    /// @notice Send only ETH to the given recipient
    /// @param recipient The recipient address
    function sendETH(bytes32 recipient) external payable;

    ///////////////////////////////
    // Public Functions Incoming //
    ///////////////////////////////

    /// @notice Used by message receiving contracts to get the address on Fuel that sent the message
    function getMessageSender() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {verifyBinaryTree} from "@fuel-contracts/merkle-sol/contracts/tree/binary/BinaryMerkleTree.sol";
import {FuelSidechainConsensus} from "./FuelSidechainConsensus.sol";
import {SidechainBlockHeader, SidechainBlockHeaderLib} from "./types/SidechainBlockHeader.sol";
import {SidechainBlockHeaderLite, SidechainBlockHeaderLiteLib} from "./types/SidechainBlockHeaderLite.sol";
import {ExcessivelySafeCall} from "../vendor/ExcessivelySafeCall.sol";
import {CryptographyLib} from "../lib/Cryptography.sol";
import {IFuelMessagePortal} from "../messaging/IFuelMessagePortal.sol";

/// @notice Structure for proving an element in a merkle tree
struct MerkleProof {
    uint256 key;
    bytes32[] proof;
}

/// @notice Structure containing all message details
struct Message {
    bytes32 sender;
    bytes32 recipient;
    bytes32 nonce;
    uint64 amount;
    bytes data;
}

/// @title FuelMessagePortal
/// @notice The Fuel Message Portal contract sends messages to and from Fuel
contract FuelMessagePortal is
    IFuelMessagePortal,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SidechainBlockHeaderLib for SidechainBlockHeader;
    using SidechainBlockHeaderLiteLib for SidechainBlockHeaderLite;

    ///////////////
    // Constants //
    ///////////////

    /// @dev The number of decimals that the base Fuel asset uses
    uint256 public constant FUEL_BASE_ASSET_DECIMALS = 9;
    uint256 public constant ETH_DECIMALS = 18;

    /// @dev The max message data size in bytes
    uint256 public constant MAX_MESSAGE_DATA_SIZE = 2 ** 16;

    /// @dev Non-zero null value to optimize gas costs
    bytes32 internal constant NULL_MESSAGE_SENDER = 0x000000000000000000000000000000000000000000000000000000000000dead;

    /////////////
    // Storage //
    /////////////

    /// @notice Current message sender for other contracts to reference
    bytes32 internal s_incomingMessageSender;

    /// @notice The Fuel sidechain consensus contract
    FuelSidechainConsensus public s_sidechainConsensus;

    /// @notice The waiting period for message root states (in milliseconds)
    uint64 public s_incomingMessageTimelock;

    /// @notice Nonce for the next message to be sent
    uint64 public s_outgoingMessageNonce;

    /// @notice Mapping of message hash to boolean success value
    mapping(bytes32 => bool) public s_incomingMessageSuccessful;

    /////////////////////////////
    // Constructor/Initializer //
    /////////////////////////////

    /// @notice Constructor disables initialization for the implementation contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Contract initializer to setup starting values
    /// @param sidechainConsensus Consensus contract
    function initialize(FuelSidechainConsensus sidechainConsensus) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        //consensus contract
        s_sidechainConsensus = sidechainConsensus;

        //outgoing message data
        s_outgoingMessageNonce = 0;

        //incoming message data
        s_incomingMessageSender = NULL_MESSAGE_SENDER;
        s_incomingMessageTimelock = 0;
    }

    /////////////////////
    // Admin Functions //
    /////////////////////

    /// @notice Pause outbound messages
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause outbound messages
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets the waiting period for message root states
    /// @param messageTimelock The waiting period for message root states (in milliseconds)
    function setIncomingMessageTimelock(uint64 messageTimelock) external onlyOwner {
        s_incomingMessageTimelock = messageTimelock;
    }

    ///////////////////////////////////////
    // Incoming Message Public Functions //
    ///////////////////////////////////////

    /// @notice Relays a message published on Fuel from a given block
    /// @param message The message to relay
    /// @param blockHeader The block containing the message
    /// @param messageInBlockProof Proof that message exists in block
    /// @param poaSignature Authority signature proving block validity
    /// @dev Made payable to reduce gas costs
    function relayMessageFromFuelBlock(
        Message calldata message,
        SidechainBlockHeader calldata blockHeader,
        MerkleProof calldata messageInBlockProof,
        bytes calldata poaSignature
    ) external payable whenNotPaused {
        //verify block header
        require(
            s_sidechainConsensus.verifyBlock(blockHeader.computeConsensusHeaderHash(), poaSignature),
            "Invalid block"
        );

        //execute message
        _executeMessageInHeader(message, blockHeader, messageInBlockProof);
    }

    /// @notice Relays a message published on Fuel from a given block
    /// @param message The message to relay
    /// @param rootBlockHeader The root block for proving chain history
    /// @param blockHeader The block containing the message
    /// @param blockInHistoryProof Proof that the message block exists in the history of the root block
    /// @param messageInBlockProof Proof that message exists in block
    /// @param poaSignature Authority signature proving block validity
    /// @dev Made payable to reduce gas costs
    function relayMessageFromPrevFuelBlock(
        Message calldata message,
        SidechainBlockHeaderLite calldata rootBlockHeader,
        SidechainBlockHeader calldata blockHeader,
        MerkleProof calldata blockInHistoryProof,
        MerkleProof calldata messageInBlockProof,
        bytes calldata poaSignature
    ) external payable whenNotPaused {
        //verify root block header
        require(
            s_sidechainConsensus.verifyBlock(rootBlockHeader.computeConsensusHeaderHash(), poaSignature),
            "Invalid root block"
        );

        //verify block in history
        require(
            verifyBinaryTree(
                rootBlockHeader.prevRoot,
                abi.encodePacked(blockHeader.computeConsensusHeaderHash()),
                blockInHistoryProof.proof,
                blockInHistoryProof.key,
                rootBlockHeader.height - 1
            ),
            "Invalid block in history proof"
        );

        //execute message
        _executeMessageInHeader(message, blockHeader, messageInBlockProof);
    }

    ///////////////////////////////////////
    // Outgoing Message Public Functions //
    ///////////////////////////////////////

    /// @notice Send a message to a recipient on Fuel
    /// @param recipient The target message receiver address or predicate root
    /// @param data The message data to be sent to the receiver
    function sendMessage(bytes32 recipient, bytes memory data) external payable whenNotPaused {
        _sendOutgoingMessage(recipient, data);
    }

    /// @notice Send only ETH to the given recipient
    /// @param recipient The target message receiver
    function sendETH(bytes32 recipient) external payable whenNotPaused {
        _sendOutgoingMessage(recipient, new bytes(0));
    }

    //////////////////////////////
    // General Public Functions //
    //////////////////////////////

    /// @notice Used by message receiving contracts to get the address on Fuel that sent the message
    /// @return sender the address of the sender on Fuel
    function getMessageSender() external view returns (bytes32) {
        require(s_incomingMessageSender != NULL_MESSAGE_SENDER, "Current message sender not set");
        return s_incomingMessageSender;
    }

    /// @notice Gets the number of decimals used in the Fuel base asset
    /// @return decimals of the Fuel base asset
    function getFuelBaseAssetDecimals() public pure returns (uint8) {
        return uint8(FUEL_BASE_ASSET_DECIMALS);
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    /// @notice Performs all necessary logic to send a message to a target on Fuel
    /// @param recipient The message receiver address or predicate root
    /// @param data The message data to be sent to the receiver
    function _sendOutgoingMessage(bytes32 recipient, bytes memory data) private {
        bytes32 sender = bytes32(uint256(uint160(msg.sender)));
        unchecked {
            //make sure data size is not too large
            require(data.length < MAX_MESSAGE_DATA_SIZE, "message-data-too-large");

            //make sure amount fits into the Fuel base asset decimal level
            uint256 precision = 10 ** (ETH_DECIMALS - FUEL_BASE_ASSET_DECIMALS);
            uint256 amount = msg.value / precision;
            if (msg.value > 0) {
                require(amount * precision == msg.value, "amount-precision-incompatability");
                require(amount <= ((2 ** 64) - 1), "amount-precision-incompatability");
            }

            //emit message for Fuel clients to pickup (messageID calculated offchain)
            emit SentMessage(sender, recipient, s_outgoingMessageNonce, uint64(amount), data);

            // increment nonce for next message
            ++s_outgoingMessageNonce;
        }
    }

    /// @notice Executes a message in the given header
    /// @param message The message to execute
    /// @param blockHeader The block containing the message
    /// @param messageInBlockProof Proof that message exists in block
    function _executeMessageInHeader(
        Message calldata message,
        SidechainBlockHeader calldata blockHeader,
        MerkleProof calldata messageInBlockProof
    ) private nonReentrant {
        //verify message validity
        bytes32 messageId = CryptographyLib.hash(
            abi.encodePacked(message.sender, message.recipient, message.nonce, message.amount, message.data)
        );
        require(!s_incomingMessageSuccessful[messageId], "Already relayed");
        require(
            (blockHeader.timestamp - 4611686018427387914) <=
                // solhint-disable-next-line not-rely-on-time
                (block.timestamp - s_incomingMessageTimelock),
            "Timelock not elapsed"
        );

        //verify message in block
        require(
            verifyBinaryTree(
                blockHeader.outputMessagesRoot,
                abi.encodePacked(messageId),
                messageInBlockProof.proof,
                messageInBlockProof.key,
                blockHeader.outputMessagesCount
            ),
            "Invalid message in block proof"
        );

        //make sure we have enough gas to finish after function
        //TODO: revisit these values
        require(gasleft() >= 45000, "Insufficient gas for relay");

        //set message sender for receiving contract to reference
        s_incomingMessageSender = message.sender;

        //relay message
        (bool success, ) = ExcessivelySafeCall.excessivelySafeCall(
            address(uint160(uint256(message.recipient))),
            gasleft() - 40000,
            message.amount * (10 ** (ETH_DECIMALS - FUEL_BASE_ASSET_DECIMALS)),
            0,
            message.data
        );

        //make sure relay succeeded
        require(success, "Message relay failed");

        //unset message sender reference
        s_incomingMessageSender = NULL_MESSAGE_SENDER;

        //keep track of successfully relayed messages
        s_incomingMessageSuccessful[messageId] = true;
    }

    /// @notice Executes a message in the given header
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        //should revert if msg.sender is not authorized to upgrade the contract (currently only owner)
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {CryptographyLib} from "../lib/Cryptography.sol";

/// @notice The Fuel v2 Sidechain PoA system.
contract FuelSidechainConsensus is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    /////////////
    // Storage //
    /////////////

    /// @dev The Current PoA key
    address public s_authorityKey;

    /////////////////////////////
    // Constructor/Initializer //
    /////////////////////////////

    /// @notice Constructor disables initialization for the implementation contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Contract initializer to setup starting values
    /// @param authorityKey Public key of the block producer authority
    function initialize(address authorityKey) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // data
        s_authorityKey = authorityKey;
    }

    /////////////////////
    // Admin Functions //
    /////////////////////

    /// @notice Sets the PoA key
    /// @param authorityKey Address of the PoA authority
    function setAuthorityKey(address authorityKey) external onlyOwner {
        s_authorityKey = authorityKey;
    }

    /// @notice Pause block commitments
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause block commitments
    function unpause() external onlyOwner {
        _unpause();
    }

    //////////////////////
    // Public Functions //
    //////////////////////

    /// @notice Verify a given block.
    /// @param blockHash The hash of a block
    /// @param signature The signature over the block hash
    function verifyBlock(bytes32 blockHash, bytes calldata signature) external view whenNotPaused returns (bool) {
        return CryptographyLib.addressFromSignature(signature, blockHash) == s_authorityKey;
    }

    ////////////////////////
    // Internal Functions //
    ////////////////////////

    /// @notice Executes a message in the given header
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        //should revert if msg.sender is not authorized to upgrade the contract (currently only owner)
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import {CryptographyLib} from "../../lib/Cryptography.sol";

/// @title Fuel Sidechain Block Header
/// @dev The Fuel sidechain block header structure
struct SidechainBlockHeader {
    ///////////////
    // Consensus //
    ///////////////
    // Merkle root of all previous consensus header hashes (not including this block)
    bytes32 prevRoot;
    // Height of this block
    uint64 height;
    // Time this block was created, in TAI64 format
    uint64 timestamp;
    /////////////////
    // Application //
    /////////////////
    //Height of the data availability layer up to which (inclusive) input messages are processed
    uint64 daHeight;
    // Number of transactions in this block
    uint64 txCount;
    // Number of output messages in this block
    uint64 outputMessagesCount;
    // Merkle root of transactions in this block
    bytes32 txRoot;
    // Merkle root of output messages in this block
    bytes32 outputMessagesRoot;
}

/// @title Block Header Library
/// @dev Provides useful functions for dealing with Fuel blocks
library SidechainBlockHeaderLib {
    /////////////
    // Methods //
    /////////////

    /// @notice Serialize a block application header.
    /// @param header The block header structure.
    /// @return The serialized block application header.
    function serializeApplicationHeader(SidechainBlockHeader memory header) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                header.daHeight,
                header.txCount,
                header.outputMessagesCount,
                header.txRoot,
                header.outputMessagesRoot
            );
    }

    /// @notice Produce the block application header hash.
    /// @param header The block header structure.
    /// @return The block application header hash.
    function computeApplicationHeaderHash(SidechainBlockHeader memory header) internal pure returns (bytes32) {
        return CryptographyLib.hash(serializeApplicationHeader(header));
    }

    /// @notice Serialize a block consensus header.
    /// @param header The block header structure.
    /// @return The serialized block consensus header.
    function serializeConsensusHeader(SidechainBlockHeader memory header) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                header.prevRoot,
                (uint32)(header.height),
                header.timestamp,
                computeApplicationHeaderHash(header)
            );
    }

    /// @notice Produce the block consensus header hash.
    /// @param header The block header structure.
    /// @return The block consensus header hash.
    function computeConsensusHeaderHash(SidechainBlockHeader memory header) internal pure returns (bytes32) {
        return CryptographyLib.hash(serializeConsensusHeader(header));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import {CryptographyLib} from "../../lib/Cryptography.sol";

/// @title Lightweight Fuel Sidechain Block Header
/// @dev The Fuel sidechain block header structure with just a hash of the application header
struct SidechainBlockHeaderLite {
    // Merkle root of all previous consensus header hashes (not including this block)
    bytes32 prevRoot;
    // Height of this block
    uint64 height;
    // Time this block was created, in TAI64 format
    uint64 timestamp;
    // Hash of serialized application header for this block
    bytes32 applicationHash;
}

/// @title Block Header Library
/// @dev Provides useful functions for dealing with Fuel blocks
library SidechainBlockHeaderLiteLib {
    /////////////
    // Methods //
    /////////////

    /// @notice Serialize a block consensus header.
    /// @param header The block header structure.
    /// @return The serialized block consensus header.
    function serializeConsensusHeader(SidechainBlockHeaderLite memory header) internal pure returns (bytes memory) {
        return abi.encodePacked(header.prevRoot, (uint32)(header.height), header.timestamp, header.applicationHash);
    }

    /// @notice Produce the block consensus header hash.
    /// @param header The block header structure.
    /// @return The block consensus header hash.
    function computeConsensusHeaderHash(SidechainBlockHeaderLite memory header) internal pure returns (bytes32) {
        return CryptographyLib.hash(serializeConsensusHeader(header));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.9;

library ExcessivelySafeCall {
    uint256 private constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _value The value in wei to send to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas limit
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        //solhint-disable-next-line reason-string
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}