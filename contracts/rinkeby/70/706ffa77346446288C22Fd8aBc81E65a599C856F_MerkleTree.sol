// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './interface/IMerkleTree.sol';
import './utils/Checkers.sol';

contract MerkleTree is IMerkleTree, Checkers {
    mapping(address => mapping(uint256 => MerkleTreeNode)) userNodes;

    /************************************************
     *  Variables & Constant 
     ***********************************************/

    uint256 public constant nums = 49;
    MerkleTree[nums] public merkleTrees;

    /************************************************
     *  Getters count for something of Mekrle Tree 
     ***********************************************/

    /// get "index" of Merkle Tree
    function getMerkleTreesIndex(uint256 _groupId) private view returns (uint256 idsIndex) {
        for (uint256 i = 0; i < nums; i++) {
            if (_groupId == merkleTrees[i].groupId) return idsIndex = i;
        }
    }

    function getSameLevelNodesLength(uint256 _groupId, uint256 _level) external view returns (uint256 index) {
        (, index) = getNodesByLevel(_groupId, _level);
    }

    /// get "amounts" of Merkle Tree
    function getNodeCounts(uint256 _groupId) public view groupIdCheck(_groupId) returns (uint256 nodeCounts) {
        uint256 idsIndexs = getMerkleTreesIndex(_groupId);
        nodeCounts = merkleTrees[idsIndexs].nodes.length;
    }

    /************************************************
     *  Getters info for info of Mekrle Tree Node
     ***********************************************/

    /// get "all nodes" of Merkle Tree
    function getAllNodes(uint256 _groupId) public view groupIdCheck(_groupId) returns (MerkleTreeNode[] memory allNodes) {
        uint256 idsIndexs = getMerkleTreesIndex(_groupId);
        allNodes = merkleTrees[idsIndexs].nodes;
    }

    /// get "all nodes" the same "level"
    function getNodesByLevel(uint256 _groupId, uint256 _level) private view returns (MerkleTreeNode[] memory nodes, uint256 counts) {
        MerkleTreeNode[] memory allNodes = getAllNodes(_groupId);
        for (uint256 i = 0; i < allNodes.length; i++) {
            if (_level == allNodes[i].level) {
                nodes[counts] = allNodes[i];
                // nodes.push(allNodes[i]);
                counts++;
            }
        }
    }

    /// get "node" by hash
    function getNodeByHash(uint256 _groupId, bytes32 _hash) public view groupIdCheck(_groupId) returns (MerkleTreeNode memory node) {
        MerkleTreeNode[] memory allNodes = getAllNodes(_groupId);
        for (uint256 i = 0; i < allNodes.length; i++) {
            if (_hash == allNodes[i].hash) node = allNodes[i];
        }
    }

    /// get "node" from groupId, level, index
    function getNode(
        uint256 _groupId,
        uint256 _level,
        uint256 _index
    ) public view allCheck(_groupId, _level, _index) returns (MerkleTreeNode memory node) {
        (MerkleTreeNode[] memory nodes, ) = getNodesByLevel(_groupId, _level);
        for (uint256 i = 0; i < nodes.length; i++) {
            if (_index == nodes[i].index) {
                node = nodes[i];
            }
        }
    }

    /************************************************
     *  Add Node
     ***********************************************/
    /// add Node
    function addNode(
        address _signer,
        bytes32 _hash,
        uint256 _groupId,
        bytes32 _groupName,
        uint256 _level,
        uint256 _index
    ) public {
        MerkleTreeNode memory node;
        uint256 treeIndex = getMerkleTreesIndex(_groupId);
        {
            node.hash = _hash;
            node.groupId = _groupId;
            node.groupName = _groupName;
            node.index = _index;
            node.level = _level;
        }
        merkleTrees[treeIndex].nodes.push(node);
        userNodes[_signer][_groupId] = node;///check
    }
    
    /// Collectively execute addNode func
    function batchAddNode(address _signer, BatchAddNode[] memory txs) external {
        for (uint256 i; i < txs.length; i++) {
            addNode(_signer, txs[i].hash, txs[i].groupId, txs[i].groupName, txs[i].level, txs[i].index);
        }
    }

    /************************************************
     *  Update Node
     ***********************************************/

    /// update hash of Node
    function updateNodeHash(
        address _signer,
        uint256 _groupId,
        bytes32 _hash
    ) public  {
        // MerkleTreeNode memory node = getNode(_groupId, _level, _index);
        MerkleTreeNode storage node = userNodes[_signer][_groupId];
        node.hash = _hash;
    }

    /// update "siblingHash" and "parent" of Node
    function updateNodeProperties(
        address _signer,
        uint256 _groupId,
        // uint256 _level,
        // uint256 _index,
        uint256 _parentLevel,
        uint256 _parentIndex,
        bytes32 _siblingHash
    ) public {
        // MerkleTreeNode memory node = getNode(_groupId, _level, _index); //this is target node
        MerkleTreeNode storage node = userNodes[_signer][_groupId];
        {
            node.siblingHash = _siblingHash;
            node.parent.groupId = _groupId;
            node.parent.level = _parentLevel;
            node.parent.index = _parentIndex;
        }
    }

    /// Collectively execute updateNode func
    function batchUpdateNode(address _signer,BatchUpdateNode[] memory txs) external  {
        for (uint256 i; i < txs.length; i++) {
            updateNodeHash(_signer, txs[i].groupId,txs[i].hash);
        }
    }

    /// Collectively execute updateNodeProperties func
    function batchUpdateNodePro(address _signer,BatchUpdateNodePro[] memory txs) external {
        for (uint256 i; i < txs.length; i++) {
            updateNodeProperties(_signer,txs[i].groupId, txs[i].parentLevel, txs[i].parentIndex, txs[i].siblingHash);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './IMerkleTreeNode.sol';

/**
 * level 3            [0]                        ↑
 * level 2      [0]          [1]                 |
 * level 1   [0]   [1]    [2]   [3]              | 　Merkle Tree
 * level 0  [0][1][2][3][4][5][6][7] // [index]  |
 *              groupId = 12                     ↓
 */
interface IMerkleTree is IMerkleTreeNode {
    struct MerkleTree {
        uint256 groupId;
        MerkleTreeNode[] nodes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Checkers {

    /************************************************
     *  Private functions
     ***********************************************/
    function _levelCheck(uint256 _level) private pure {
        require(_level <= 16, 'Error');
    }

    function _groupIdCheck(uint256 _groupId) private pure {
        require(_groupId <= 49, 'Error');
    }
    
    function _indexCheck(uint256 _index) private pure {
        require(_index <= 2**16, 'Error');
    }
    
    /************************************************
     *  Modifiers
     ***********************************************/

    modifier groupIdCheck(uint256 _groupId) {
        _groupIdCheck(_groupId);
        _;
    }

    modifier levelCheck(uint256 _level) {
        _levelCheck(_level);
        _;
    }

    modifier indexCheck(uint256 _index) {
        _indexCheck(_index);
        _;
    }

    modifier allCheck(
        uint256 _groupId,
        uint256 _level,
        uint256 _index
    ) {
        _groupIdCheck(_groupId);
        _levelCheck(_level);
        _indexCheck(_index);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * level 3            [0]
 * level 2      [0]          [1]
 * level 1   [0]   [1]    [2]   [3]
 * level 0  [0][1][2][3][4][5][6][7] // [index]
 */
/// [0] is Node

interface IMerkleTreeNode {
    struct MerkleTreeNode {
        uint256 id; ///不要だったら消す`${MODEL_MERKLE_TREE}#${groupId}_0_${currentIndex}`
        bytes32 hash; //hash
        uint256 groupId;
        bytes32 groupName;
        uint256 index;
        uint256 level;
        bytes32 siblingHash;
        /// next to node's hash, for[2],siblingHash is [3]'s hash
        ParentLocate parent;
    }
    struct ParentLocate {
        uint256 groupId;
        uint256 index;
        uint256 level;
    }

    struct BatchAddNode {
        bytes32 hash;
        uint256 groupId;
        bytes32 groupName;
        uint256 index;
        uint256 level;
    }

    struct BatchUpdateNode {
        bytes32 hash;
        uint256 groupId;
        uint256 index;
        uint256 level;
    }

    struct BatchUpdateNodePro {
        uint256 groupId;
        uint256 index;
        uint256 level;
        uint256 parentIndex;
        uint256 parentLevel;
        bytes32 siblingHash;
    }
}