// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Tree Library

pragma solidity ^0.8.0;

library Tree {
    // The tree can store up to UINT32_MAX vertices, the type uses uint256 for gas optimization purpose.
    // It's the library caller's responsibility to check the input arguments are within the proper range
    uint256 constant UINT32_MAX = 2**32 - 1;
    // count of trailing ones for [0:256)
    // each number takes one byte
    bytes constant trailing1table =
        hex"00010002000100030001000200010004000100020001000300010002000100050001000200010003000100020001000400010002000100030001000200010006000100020001000300010002000100040001000200010003000100020001000500010002000100030001000200010004000100020001000300010002000100070001000200010003000100020001000400010002000100030001000200010005000100020001000300010002000100040001000200010003000100020001000600010002000100030001000200010004000100020001000300010002000100050001000200010003000100020001000400010002000100030001000200010008";

    struct TreeCtx {
        uint32 deepestVertex;
        uint32 deepestDepth;
        uint32 verticesLength;
        mapping(uint256 => Vertex) vertices;
    }

    struct Vertex {
        uint32 depth; // depth of the vertex in the tree
        uint32 ancestorsLength;
        // Each uint256 value stores 8 ancestors, each takes a uint32 slot,
        // the key used to access the value should be preprocessed,
        // 0 => uint32[7],uint32[6],uint32[5],uint32[4],uint32[3],uint32[2],uint32[1],uint32[0]
        // 1 => uint32[15],uint32[14],uint32[13],uint32[12],uint32[11],uint32[10],uint32[9],uint32[8]
        // A vertex can have up to 32 ancestors
        mapping(uint256 => uint256) ancestors; // pointers to ancestors' indices in the vertices map (tree)
    }

    event VertexInserted(uint256 _parent);

    /// @notice Insert a vertex to the tree
    /// @param _tree pointer to the tree storage
    /// @param _parent the index of parent vertex in the vertices map (tree)
    /// @return index of the inserted vertex
    /// @dev the tree can hold up to UINT32_MAX vertices, if the insertVertex is called when tree is full, the transaction will be reverted
    function insertVertex(TreeCtx storage _tree, uint256 _parent)
        external
        returns (uint256)
    {
        uint256 treeSize = _tree.verticesLength;

        _tree.verticesLength++;
        Vertex storage v = _tree.vertices[treeSize];

        if (treeSize == 0) {
            // insert the very first vertex into the tree
            // v is initialized with zeros already
        } else {
            // insert vertex to the tree attaching to another vertex
            require(_parent < treeSize, "parent index exceeds tree size");

            uint256 parentDepth = _tree.vertices[_parent].depth;

            // construct the ancestors map in batch
            batchSetAncestors(v, parentDepth);
        }

        uint256 depth = v.depth;
        if (depth > _tree.deepestDepth) {
            _tree.deepestDepth = uint32(depth);
            _tree.deepestVertex = uint32(treeSize);
        }

        emit VertexInserted(_parent);

        return treeSize;
    }

    /// @notice Set ancestors in batches, each of which has up to 8 ancestors
    /// @param _v pointer to the vertex storage
    /// @param _parentDepth the parent depth
    function batchSetAncestors(Vertex storage _v, uint256 _parentDepth)
        private
    {
        // calculate all ancestors' depths of the new vertex
        uint256[] memory requiredDepths = getRequiredDepths(_parentDepth + 1);
        uint256 batchPointer; // point to the beginning of a batch

        while (batchPointer < requiredDepths.length) {
            uint256 ancestorsBatch; // stores up to 8 ancestors
            uint256 offset; // 0~8
            while (
                offset < 8 && batchPointer + offset < requiredDepths.length
            ) {
                ancestorsBatch =
                    ancestorsBatch |
                    (requiredDepths[batchPointer + offset] << (offset * 32));

                ++offset;
            }
            _v.ancestors[batchPointer / 8] = ancestorsBatch;

            batchPointer += offset;
        }

        _v.depth = uint32(_parentDepth + 1);
        _v.ancestorsLength = uint32(requiredDepths.length);
    }

    /// @notice Get an ancestor of a vertex from its ancestor cache by offset
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    /// @param _ancestorOffset the offset of the ancestor in ancestor cache
    /// @return index of ancestor vertex in the tree
    function getAncestor(
        TreeCtx storage _tree,
        uint256 _vertex,
        uint256 _ancestorOffset
    ) public view returns (uint256) {
        require(
            _vertex < _tree.verticesLength,
            "vertex index exceeds tree size"
        );

        Vertex storage v = _tree.vertices[_vertex];

        require(_ancestorOffset < v.ancestorsLength, "offset exceeds cache size");

        uint256 key = _ancestorOffset / 8;
        uint256 offset = _ancestorOffset % 8;
        uint256 ancestor = (v.ancestors[key] >> (offset * 32)) & 0xffffffff;

        return ancestor;
    }

    /// @notice Search an ancestor of a vertex in the tree at a certain depth
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    /// @param _depth the depth of the ancestor
    /// @return index of ancestor at depth of _vertex
    function getAncestorAtDepth(
        TreeCtx storage _tree,
        uint256 _vertex,
        uint256 _depth
    ) external view returns (uint256) {
        require(
            _vertex < _tree.verticesLength,
            "vertex index exceeds tree size"
        );
        require(
            _depth <= _tree.vertices[_vertex].depth,
            "search depth > vertex depth"
        );

        uint256 vertex = _vertex;

        while (_depth != _tree.vertices[vertex].depth) {
            Vertex storage v = _tree.vertices[vertex];
            uint256 ancestorsLength = v.ancestorsLength;
            // start searching from the oldest ancestor (smallest depth)
            // example: search ancestor at depth d(20, b'0001 0100) from vertex v at depth (176, b'1011 0000)
            //    b'1011 0000 -> b'1010 0000 -> b'1000 0000
            // -> b'0100 0000 -> b'0010 0000 -> b'0001 1000
            // -> b'0001 0100

            // given that ancestorsOffset is unsigned, when -1 at 0, it'll underflow and become UINT32_MAX
            // so the continue condition has to be ancestorsOffset < ancestorsLength,
            // can't be ancestorsOffset >= 0
            uint256 temp_v = vertex;
            for (
                uint256 ancestorsOffset = ancestorsLength - 1;
                ancestorsOffset < ancestorsLength;

            ) {
                vertex = getAncestor(_tree, temp_v, ancestorsOffset);

                // stop at the ancestor who's closest to the target depth
                if (_tree.vertices[vertex].depth >= _depth) {
                    break;
                }

                unchecked {
                    --ancestorsOffset;
                }
            }
        }

        return vertex;
    }

    /// @notice Get depth of vertex
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    function getDepth(TreeCtx storage _tree, uint256 _vertex)
        external
        view
        returns (uint256)
    {
        return getVertex(_tree, _vertex).depth;
    }

    /// @notice Get vertex from the tree
    /// @param _tree pointer to the tree storage
    /// @param _vertex the index of the vertex in the vertices map (tree)
    function getVertex(TreeCtx storage _tree, uint256 _vertex)
        public
        view
        returns (Vertex storage)
    {
        require(
            _vertex < _tree.verticesLength,
            "vertex index exceeds tree size"
        );

        return _tree.vertices[_vertex];
    }

    /// @notice Get current tree size
    /// @param _tree pointer to the tree storage
    function getTreeSize(TreeCtx storage _tree)
        external
        view
        returns (uint256)
    {
        return _tree.verticesLength;
    }

    /// @notice Get current tree size
    /// @param _tree pointer to the tree storage
    /// @return index number and depth of the deepest vertex
    function getDeepest(TreeCtx storage _tree)
        external
        view
        returns (uint256, uint256)
    {
        return (_tree.deepestVertex, _tree.deepestDepth);
    }

    function getRequiredDepths(uint256 _depth)
        private
        pure
        returns (uint256[] memory)
    {
        // parent is always included in the ancestors
        uint256 depth = _depth - 1;
        uint256 count = 1;

        // algorithm 1
        // get count of trailing ones of _depth from trailing1table
        for (uint256 i = 0; i < 4; ) {
            uint256 partialCount = uint8(
                trailing1table[(depth >> (i * 8)) & 0xff]
            );
            count = count + partialCount;
            if (partialCount != 8) {
                break;
            }

            unchecked {
                ++i;
            }
        }

        // algorithm 2
        // get count of trailing ones by counting them
        // {
        //     while (depth & 1 > 0) {
        //         depth = depth >> 1;
        //         ++count;
        //     }

        //     depth = _depth - 1;
        // }

        uint256[] memory depths = new uint256[](count);

        // construct the depths array by removing the trailing ones from lsb one by one
        // example _depth = b'1100 0000: b'1011 1111 -> b'1011 1110 -> b'1011 1100
        //                            -> b'1011 1000 -> b'1011 0000 -> b'1010 0000
        //                            -> b'1000 0000
        for (uint256 i = 0; i < count; ) {
            depths[i] = depth;
            depth = depth & (UINT32_MAX << (i + 1));

            unchecked {
                ++i;
            }
        }

        return depths;
    }
}