// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./libraries/RescueLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RecordsMerkleTree is Ownable {
    enum Position {
        LEFT,
        MIDDLE,
        RIGHT
    }

    // Representation of a (tree) node
    // A node contains a value and pointers (which are index in an array of other nodes).
    // By convention a node that has no (left,middle,right) children will point to index 0.
    struct Node {
        uint256 val;
        uint64 left; // Pointer (index) to the left child
        uint64 middle; // Pointer (index) to the middle child
        uint64 right; // Pointer (index) to the right child
    }

    uint256 internal _rootValue;
    uint64 internal _numLeaves;
    uint8 internal _merkleTreeHeight;

    mapping(uint256 => uint256) internal _flattenedFrontier;

    /// @dev Create a records Merkle tree of the given height.
    /// @param merkleTreeHeight The height
    constructor(uint8 merkleTreeHeight) {
        _rootValue = 0;
        _numLeaves = 0;
        _merkleTreeHeight = merkleTreeHeight;
    }

    /// @dev Is the given node a terminal node?
    /// @param node A node
    /// @return _ True if the node is terminal, false otherwise.
    function _isTerminal(Node memory node) private pure returns (bool) {
        return (node.left == 0) && (node.middle == 0) && (node.right == 0);
    }

    /// @dev Does the given node have children?
    /// @param node A node
    /// @return _ True if the node has at least one child, false otherwise
    function _hasChildren(Node memory node) private pure returns (bool) {
        return !_isTerminal(node);
    }

    /// @dev Is the given node null?
    /// @param node A node
    /// @return _ True if the node is NULL, false otherwise
    function _isNull(Node memory node) private pure returns (bool) {
        return (node.val == 0 && _isTerminal(node));
    }

    /// @dev Create a new "hole node" at the given position in the
    /// tree. A cursor position can be obtained from an extant node or
    /// from a function that returns a position such as _buildTreeFromFrontier.
    /// @param cursor The index of the node in the array of nodes
    /// @param posSibling The position of the sibling i.e. (LEFT, MIDDLE or RIGHT)
    /// @return _ The new created node
    function _createHoleNode(uint64 cursor, Position posSibling)
        private
        pure
        returns (Node memory)
    {
        // Copy pasting these values to save gas
        // indexHoleNode = cursor - 3;
        // indexFirstSibling = cursor - 2;
        // indexSecondSibling = cursor - 1;

        Node memory node;
        if (posSibling == Position.LEFT) {
            node = Node(0, cursor - 3, cursor - 2, cursor - 1);
        } else if (posSibling == Position.MIDDLE) {
            node = Node(0, cursor - 2, cursor - 3, cursor - 1);
        } else if (posSibling == Position.RIGHT) {
            node = Node(0, cursor - 2, cursor - 1, cursor - 3);
        }

        return node;
    }

    /// @dev Create a Merkle tree from the given frontier.
    /// @param nodes The list of nodes to be filled or updated
    /// @return A cursor to the root node of the create tree
    function _buildTreeFromFrontier(Node[] memory nodes) internal view returns (uint64) {
        // Tree is empty
        if (_numLeaves == 0) {
            nodes[0] = Node(0, 0, 0, 0); // Empty node
            nodes[1] = Node(0, 0, 0, 0); // Root node
            return 1;
        }

        // Tree is not empty

        // Set the first node to the NULL node
        nodes[0] = Node(0, 0, 0, 0);

        // Insert the leaf
        nodes[1] = Node(_flattenedFrontier[0], 0, 0, 0);

        // Insert the siblings
        nodes[2] = Node(_flattenedFrontier[1], 0, 0, 0);
        nodes[3] = Node(_flattenedFrontier[2], 0, 0, 0);

        // Compute the position of each node
        uint64 absolutePosition = _numLeaves - 1;
        uint8 localPosition = uint8(absolutePosition % 3);

        // We process the nodes of the Merkle path
        uint64 cursor = 4;
        uint64 cursorFrontier = 3;

        // Build the tree expect the root node
        while (cursor < 3 * _merkleTreeHeight + 1) {
            nodes[cursor] = _createHoleNode(cursor, Position(localPosition));

            // Create the siblings of the "hole node". These siblings have no children
            nodes[cursor + 1] = Node(_flattenedFrontier[cursorFrontier], 0, 0, 0);
            nodes[cursor + 2] = Node(_flattenedFrontier[cursorFrontier + 1], 0, 0, 0);

            // Move forward
            absolutePosition /= 3;
            localPosition = uint8(absolutePosition % 3);

            cursor += 3;
            cursorFrontier += 2;
        }

        // Add the root node
        nodes[cursor] = _createHoleNode(cursor, Position(localPosition));
        return cursor;
    }

    /// @dev Compute the index of the next node when going down in the tree.
    /// @param nodes The list of nodes of the tree
    /// @param nodeIndex The index of the starting node
    /// @param pos The position for going down, i.e. LEFT, MIDDLE or RIGHT.
    /// @return The index of the next node
    function _nextNodeIndex(
        Node[] memory nodes,
        uint64 nodeIndex,
        Position pos
    ) private pure returns (uint64) {
        uint64 res;

        if (pos == Position.LEFT) {
            res = nodes[nodeIndex].left;
        } else if (pos == Position.MIDDLE) {
            res = nodes[nodeIndex].middle;
        } else if (pos == Position.RIGHT) {
            res = nodes[nodeIndex].right;
        }

        return res;
    }

    /// @dev Update the child of a node based on the position (which child to select) and an index to the new child.
    /// @param node node for which we want to update the child
    /// @param newChildIndex index of the new child
    /// @param pos position of the child node relative to the node (i.e. LEFT, MIDDLE or RIGHT)
    function _updateChildNode(
        Node memory node,
        uint64 newChildIndex,
        Position pos
    ) private pure {
        // Update the node
        if (pos == Position.LEFT) {
            node.left = newChildIndex;
        } else if (pos == Position.MIDDLE) {
            node.middle = newChildIndex;
        } else if (pos == Position.RIGHT) {
            node.right = newChildIndex;
        }
    }

    function _computeNodePos(uint64 absolutePos, uint64 branchIndex)
        private
        view
        returns (uint64, uint64)
    {
        uint64 localPos;
        uint64 divisor = uint64(3**(_merkleTreeHeight - branchIndex - 1));

        localPos = absolutePos / divisor;
        absolutePos = absolutePos % divisor;

        return (absolutePos, localPos);
    }

    /// @notice Insert an element into the tree in the position num_leaves.
    /// @param nodes The array of nodes
    /// @param rootIndex The index of the root node
    /// @param maxIndex The index of the latest element inserted in the nodes array
    /// @param element The value of the element to insert into the tree
    /// @return updated the value of maxIndex
    function _pushElement(
        Node[] memory nodes,
        uint64 rootIndex,
        uint64 maxIndex,
        uint256 element
    ) private returns (uint64) {
        require(_numLeaves < 3**_merkleTreeHeight, "The tree is full.");

        // Get the position of the leaf from the smart contract state
        uint64 leafPos = _numLeaves;
        uint64 branchIndex = 0;
        uint64 currentNodeIndex = rootIndex;
        uint64 previousNodeIndex = rootIndex;

        // Go down inside the tree until finding the first terminal node.
        uint64 absolutePos = leafPos;
        uint64 localPos = 0;
        while (!_isNull(nodes[currentNodeIndex])) {
            (absolutePos, localPos) = _computeNodePos(absolutePos, branchIndex);

            previousNodeIndex = currentNodeIndex;
            currentNodeIndex = _nextNodeIndex(nodes, currentNodeIndex, Position(localPos));

            branchIndex += 1;
        }

        // maxIndex tracks the index of the last element inserted in the tree
        uint64 newNodeIndex = maxIndex + 1;

        // Create new nodes until completing the path one level above the leaf level
        // Always inserting to the left

        // To compensate the extra increment at the end of the previous loop ,
        // except if the tree is reduced to a single root node.
        if (branchIndex > 0) {
            branchIndex -= 1;
        }

        while (branchIndex < _merkleTreeHeight - 1) {
            nodes[newNodeIndex] = Node(0, 0, 0, 0);
            _updateChildNode(nodes[previousNodeIndex], newNodeIndex, Position(localPos));

            // Prepare the next iteration of the loop
            previousNodeIndex = newNodeIndex;
            newNodeIndex += 1;
            branchIndex += 1;
            (absolutePos, localPos) = _computeNodePos(absolutePos, branchIndex);
        }

        // The last node contains the leaf value (compute the hash)
        // Remember position is computed with the remainder

        // Leaf node where the value is hash(0,_numLeaves,element)
        uint256 val = RescueLib.hash(0, _numLeaves, element);
        nodes[newNodeIndex] = Node(val, 0, 0, 0);
        _updateChildNode(nodes[previousNodeIndex], newNodeIndex, Position(localPos));

        // Increment the number of leaves
        _numLeaves += 1;

        // Return the new value of maxIndex
        return newNodeIndex;
    }

    /// @dev Store the frontier.
    /// @param nodes The list of node of the tree
    /// @param rootIndex The index of the root node
    function _storeFrontier(Node[] memory nodes, uint64 rootIndex) private {
        uint64 frontierSize = 2 * _merkleTreeHeight + 1;

        /// Collect the values from the root to the leaf but in reverse order
        uint64 currentNodeIndex = rootIndex;
        uint64 firstSiblingIndex = 0;
        uint64 secondSiblingIndex = 0;
        // Go down until the leaf
        for (uint256 i = 0; i < _merkleTreeHeight; i++) {
            // Pick the non-empty node that is most right
            Node memory currentNode = nodes[currentNodeIndex];
            if (!_isNull(nodes[currentNode.right])) {
                // Keep to the right
                currentNodeIndex = currentNode.right;
                firstSiblingIndex = currentNode.left;
                secondSiblingIndex = currentNode.middle;
            } else if (!_isNull(nodes[currentNode.middle])) {
                // Keep to the middle
                currentNodeIndex = currentNode.middle;
                firstSiblingIndex = currentNode.left;
                secondSiblingIndex = currentNode.right;
            } else {
                // Keep to the left
                currentNodeIndex = currentNode.left;
                firstSiblingIndex = currentNode.middle;
                secondSiblingIndex = currentNode.right;
            }
            uint256 secondSiblingPos = frontierSize - 1 - (2 * i);
            uint256 firstSiblingPos = secondSiblingPos - 1;
            _flattenedFrontier[secondSiblingPos] = nodes[secondSiblingIndex].val;
            _flattenedFrontier[firstSiblingPos] = nodes[firstSiblingIndex].val;
        }
        // currentNodeIndex points to the leaf
        _flattenedFrontier[0] = nodes[currentNodeIndex].val;
    }

    /// @dev Update the state of the record merkle tree by inserting new elements.
    /// @param elements The list of elements to be appended to the current merkle tree described by the frontier.
    function updateRecordsMerkleTree(uint256[] memory elements) external onlyOwner {
        // The total number of nodes is bounded by 3*height+1 + 3*N*height = 3*(N+1)*height + 1
        // where N is the number of new records
        uint256 numElements = elements.length;
        Node[] memory nodes = new Node[](3 * (numElements + 1) * _merkleTreeHeight + 2);

        /// Insert the new elements ///

        // maxIndex tracks the index of the last element inserted in the tree
        uint64 rootIndex = _buildTreeFromFrontier(nodes);
        uint64 maxIndex = rootIndex;
        for (uint32 i = 0; i < elements.length; i++) {
            maxIndex = _pushElement(nodes, rootIndex, maxIndex, elements[i]);
        }
        //// Compute the root hash value ////
        _rootValue = _computeRootValueAndUpdateTree(nodes, rootIndex);

        //// Store the frontier
        _storeFrontier(nodes, rootIndex);
    }

    /// @notice Returns the root value of the Merkle tree.
    function getRootValue() public view returns (uint256) {
        return _rootValue;
    }

    /// @notice Returns the height of the Merkle tree.
    function getHeight() public view returns (uint8) {
        return _merkleTreeHeight;
    }

    /// @notice Returns the number of leaves of the Merkle tree.
    function getNumLeaves() public view returns (uint64) {
        return _numLeaves;
    }

    /// @dev Update the tree by hashing the children of each node.
    /// @param nodes The tree. Note that the nodes are updated by this function.
    /// @param rootNodePos The index of the root node in the list of nodes.
    /// @return The value obtained at the root.
    function _computeRootValueAndUpdateTree(Node[] memory nodes, uint256 rootNodePos)
        private
        returns (uint256)
    {
        // If the root node has no children return its value
        Node memory rootNode = nodes[rootNodePos];
        if (_isTerminal(rootNode)) {
            return rootNode.val;
        } else {
            uint256 valLeft = _computeRootValueAndUpdateTree(nodes, rootNode.left);
            uint256 valMiddle = _computeRootValueAndUpdateTree(nodes, rootNode.middle);
            uint256 valRight = _computeRootValueAndUpdateTree(nodes, rootNode.right);

            nodes[rootNode.left].val = valLeft;
            nodes[rootNode.middle].val = valMiddle;
            nodes[rootNode.right].val = valRight;

            return RescueLib.hash(valLeft, valMiddle, valRight);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library RescueLib {
    /// The constants are obtained from the Sage script
    /// https://github.com/EspressoSystems/Marvellous/blob/fcd4c41672f485ac2f62526bc87a16789d4d0459/rescue254.sage

    uint256 private constant _N_ROUNDS = 12;
    uint256 private constant _STATE_SIZE = 4;
    uint256 private constant _SCHEDULED_KEY_SIZE = (2 * _N_ROUNDS + 1) * _STATE_SIZE;

    // Obtained by running KeyScheduling([0,0,0,0]). See Algorithm 2 of AT specification document.
    // solhint-disable-next-line var-name-mixedcase

    uint256 private constant _PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 private constant _ALPHA = 5;

    uint256 private constant _ALPHA_INV =
        17510594297471420177797124596205820070838691520332827474958563349260646796493;

    // MDS is hardcoded
    function _linearOp(
        uint256 s0,
        uint256 s1,
        uint256 s2,
        uint256 s3
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Matrix multiplication
        unchecked {
            return (
                mulmod(
                    21888242871839275222246405745257275088548364400416034343698204186575808479992,
                    s0,
                    _PRIME
                ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575806058117,
                        s1,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575491214367,
                        s2,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186535831058117,
                        s3,
                        _PRIME
                    ),
                mulmod(19500, s0, _PRIME) +
                    mulmod(3026375, s1, _PRIME) +
                    mulmod(393529500, s2, _PRIME) +
                    mulmod(49574560750, s3, _PRIME),
                mulmod(
                    21888242871839275222246405745257275088548364400416034343698204186575808491587,
                    s0,
                    _PRIME
                ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575807886437,
                        s1,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575729688812,
                        s2,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186565891044437,
                        s3,
                        _PRIME
                    ),
                mulmod(156, s0, _PRIME) +
                    mulmod(20306, s1, _PRIME) +
                    mulmod(2558556, s2, _PRIME) +
                    mulmod(320327931, s3, _PRIME)
            );
        }
    }

    function _expAlphaInv4Setup(uint256[6] memory scratch) private pure {
        assembly {
            let p := scratch
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x80), _ALPHA_INV) // Exponent
            mstore(add(p, 0xa0), _PRIME) // Modulus
        }
    }

    function _expAlphaInv4(
        uint256[6] memory scratch,
        uint256 s0,
        uint256 s1,
        uint256 s2,
        uint256 s3
    )
        private
        view
        returns (
            uint256 o0,
            uint256 o1,
            uint256 o2,
            uint256 o3
        )
    {
        assembly {
            // define pointer
            let p := scratch
            let basep := add(p, 0x60)
            mstore(basep, s0) // Base
            // store data assembly-favouring ways
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o0 := mload(basep)
            mstore(basep, s1) // Base
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o1 := mload(basep)
            mstore(basep, s2) // Base
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o2 := mload(basep)
            mstore(basep, s3) // Base
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o3 := mload(basep)
        }
    }

    // Computes the Rescue permutation on some input
    // Recall that the scheduled key is precomputed in our case
    // @param input input for the permutation
    // @return permutation output
    function perm(
        uint256 s0,
        uint256 s1,
        uint256 s2,
        uint256 s3
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256[6] memory alphaInvScratch;

        _expAlphaInv4Setup(alphaInvScratch);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 14613516837064033601098425266946467918409544647446217386229959902054563533267,
                s1 + 376600575581954944138907282479272751264978206975465380433764825531344567663,
                s2 + 7549886658634274343394883631367643327196152481472281919735617268044202589860,
                s3 + 3682071510138521345600424597536598375718773365536872232193107639375194756918
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                18657517374128716281071590782771170166993445602755371021955596036781411817786;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                7833794394096838639430144230563403530989402760602204539559270044687522640191;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                21303828694647266539931030987057572024333442749881970102454081226349775826204;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                10601447988834057856019990466870413629636256450824419416829818546423193802418;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 3394657260998945409283098835682964352503279447198495330506177586645995289229,
                s1 + 18437084083724939316390841967750487133622937044030373241106776324730657101302,
                s2 + 9281739916935170266925270432337475828741505406943764438550188362765269530037,
                s3 + 7363758719535652813463843693256839865026387361836644774317493432208443086206
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                307094088106440279963968943984309088038734274328527845883669678290790702381;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                20802277384865839022876847241719852837518994021170013346790603773477912819001;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                19754579269464973651593381036132218829220609572271224048608091445854164824042;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                3618840933841571232310395486452077846249117988789467996234635426899783130819;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 2604166168648013711791424714498680546427073388134923208733633668316805639713,
                s1 + 21355705619901626246699129842094174300693414345856149669339147704587730744579,
                s2 + 492957643799044929042114590851019953669919577182050726596188173945730031352,
                s3 + 8495959434717951575638107349559891417392372124707619959558593515759091841138
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                15608173629791582453867933160400609222904457931922627396107815347244961625587;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                16346164988481725869223011419855264063160651334419415042919928342589111681923;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                21085652277104054699752179865196164165969290053517659864117475352262716334100;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                20640310021063232205677193759981403045043444605175178332133134865746039279935;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 6015589261538006311719125697023069952804098656652050863009463360598997670240,
                s1 + 12498423882721726012743791752811798719201859023192663855805526312393108407357,
                s2 + 10785527781711732350693172404486938622378708235957779975342240483505724965040,
                s3 + 5563181134859229953817163002660048854420912281911747312557025480927280392569
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                4585980485870975597083581718044393941512074846925247225127276913719050121968;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                8135760428078872176830812746579993820254685977237403304445687861806698035222;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                4525715538433244696411192727226186804883202134636681498489663161593606654720;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                2537497100749435007113677475828631400227339157221711397900070636998427379023;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 6957758175844522415482704083077249782181516476067074624906502033584870962925,
                s1 + 17134288156316028142861248367413235848595762718317063354217292516610545487813,
                s2 + 20912428573104312239411321877435657586184425249645076131891636094671938892815,
                s3 + 16000236205755938926858829908701623009580043315308207671921283074116709575629
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                10226182617544046880850643054874064693998595520540061157646952229134207239372;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                18584346134948015676264599354709457865255277240606855245909703396343731224626;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                9263628039314899758000383385773954136696958567872461042004915206775147151562;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                21095966719856094705113273596585696209808876361583941931684481364905087347856;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 2671157351815122058649197205531097090514563992249109660044882868649840700911,
                s1 + 19371695134219415702961622134896564229962454573253508904477489696588594622079,
                s2 + 5458968308231210904289987830881528056037123818964633914555287871152343390175,
                s3 + 7336332584551233792026746889434554547883125466404119632794862500961953384162
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                10351436748086126474964482623536554036637945319698748519226181145454116702488;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                10588209357420186457766745724579739104572139534486480334142455690083813419064;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                14330277147584936710957102218096795520430543834717433464500965846826655802131;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                20752197679372238381408962682213349118865256502118746003818603260257076802028;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 19390446529582160674621825412345750405397926216690583196542690617266028463414,
                s1 + 4169994013656329171830126793466321040216273832271989491631696813297571003664,
                s2 + 3014817248268674641565961681956715664833306954478820029563459099892548946802,
                s3 + 14285412497877984113655094566695921704826935980354186365694472961163628072901
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                16224484149774307577146165975762490690838415946665379067259822320752729067513;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                5404416528124718330316441408560295270695591369912905197499507811036327404407;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                20127204244332635127213425090893250761286848618448128307344971109698523903374;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                14939477686176063572999014162186372798386193194442661892600584389296609365740;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 183740587182448242823071506013879595265109215202349952517434740768878294134,
                s1 + 15366166801397358994305040367078329374182896694582870542425225835844885654667,
                s2 + 10066796014802701613007252979619633540090232697942390802486559078446300507813,
                s3 + 4824035239925904398047276123907644574421550988870123756876333092498925242854
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                5526416022516734657935645023952329824887761902324086126076396040056459740202;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                18157816292703983306114736850721419851645159304249709756659476015594698876611;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                767446206481623130855439732549764381286210118638028499466788453347759203223;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                16303412231051555792435190427637047658258796056382698277687500021321460387129;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 15475465085113677237835653765189267963435264152924949727326000496982746660612,
                s1 + 14574823710073720047190393602502575509282844662732045439760066078137662816054,
                s2 + 13746490178929963947720756220409862158443939172096620003896874772477437733602,
                s3 + 13804898145881881347835367366352189037341704254740510664318597456840481739975
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                3523599105403569319090449327691358425990456728660349400211678603795116364226;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                8632053982708637954870974502506145434219829622278773822242070316888003350278;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                20293222318844554840191640739970825558851264905959070636369796127300969629060;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                7583204376683983181255811699503668584283525661852773339144064901897953897564;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 7562572155566079175343789986900217168516831778275127159068657756836798778249,
                s1 + 12689811910161401007144285031988539999455902164332232460061366402869461973371,
                s2 + 21878400680687418538050108788381481970431106443696421074205107984690362920637,
                s3 + 3428721187625124675258692786364137915132424621324969246210899039774126165479
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                2552744099402346352193097862110515290335034445517764751557635302899937367219;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                13706727374402840004346872704605212996406886221231239230397976011930486183550;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                19786308443934570499119114884492461847023732197118902978413499381102456961966;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                11767081169862697956461405434786280425108140215784390008330611807075539962898;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 1273319740931699377003430019539548781935202579355152343831464213279794249000,
                s1 + 20225620070386241931202098463018472034137960205721651875253423327929063224115,
                s2 + 13107884970924459680133954992354588464904218518440707039430314610799573960437,
                s3 + 10574066469653966216567896842413898230152427846140046825523989742590727910280
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                21386271527766270535632132320974945129946865648321206442664310421414128279311;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                15743262855527118149527268525857865250723531109306484598629175225221686341453;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                16251140915157602891864152518526119259367827194524273940185283798897653655734;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                5420158299017134702074915284768041702367316125403978919545323705661634647751;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 14555572526833606349832007897859411042036463045080050783981107823326880950231,
                s1 + 15234942318869557310939446038663331226792664588406507247341043508129993934298,
                s2 + 19560004467494472556570844694553210033340577742756929194362924850760034377042,
                s3 + 21851693551359717578445799046408060941161959589978077352548456186528047792150
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                19076469206110044175016166349949136119962165667268661130584159239385341119621;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                19132104531774396501521959463346904008488403861940301898725725957519076019017;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                6606159937109409334959297158878571243749055026127553188405933692223704734040;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                13442678592538344046772867528443594004918096722084104155946229264098946917042;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            return (
                s0 + 11975757366382164299373991853632416786161357061467425182041988114491638264212,
                s1 + 10571372363668414752587603575617060708758897046929321941050113299303675014148,
                s2 + 5405426474713644587066466463343175633538103521677501186003868914920014287031,
                s3 + 18665277628144856329335676361545218245401014824195451740181902217370165017984
            );
        }
    }

    // Computes the hash of three field elements and returns a single element
    // In our case the rate is 3 and the capacity is 1
    // This hash function the one used in the Records Merkle tree.
    // @param a first element
    // @param b second element
    // @param c third element
    // @return the first element of the Rescue state
    function hash(
        uint256 a,
        uint256 b,
        uint256 c
    ) public view returns (uint256 o) {
        (o, a, b, c) = perm(a % _PRIME, b % _PRIME, c % _PRIME, 0);
        o %= _PRIME;
    }

    function checkBounded(uint256[15] memory inputs) internal pure {
        for (uint256 i = 0; i < inputs.length; ++i) {
            require(inputs[i] < _PRIME, "inputs must be below _PRIME");
        }
    }

    // Must be public so it doesn't get inlined into CAPE.sol and blow
    // the size limit
    function commit(uint256[15] memory inputs) public view returns (uint256) {
        checkBounded(inputs);

        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;

        for (uint256 i = 0; i < 5; i++) {
            unchecked {
                (a, b, c, d) = perm(
                    (a + inputs[3 * i + 0]) % _PRIME,
                    (b + inputs[3 * i + 1]) % _PRIME,
                    (c + inputs[3 * i + 2]) % _PRIME,
                    d
                );

                (a, b, c, d) = (a % _PRIME, b % _PRIME, c % _PRIME, d % _PRIME);
            }
        }

        return a;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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