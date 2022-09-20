import './Regiment.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
pragma solidity 0.8.9;

contract Merkle {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    uint256 constant PathMaximalLength = 20;
    uint256 constant DefaultPathLength = 10;

    struct SpaceInfo {
        bytes32 operator;
        uint256 pathLength;
        uint256 maxLeafCount;
    }
    struct MerkleTree {
        bytes32 spaceId;
        uint256 merkleTreeIndex;
        uint256 firstLeafIndex;
        uint256 lastLeafIndex;
        bytes32 merkleTreeRoot;
        bool isFullTree;
    }

    address public regimentAddress;

    mapping(bytes32 => SpaceInfo) private spaceInfoMap;

    mapping(bytes32 => uint256) private RegimentSpaceIndexMap;

    mapping(bytes32 => EnumerableSet.Bytes32Set) private RegimentSpaceIdListMap;

    mapping(bytes32 => mapping(uint256 => MerkleTree)) private SpaceMerkleTree;

    mapping(bytes32 => uint256) private FullMerkleTreeCountMap;

    mapping(bytes32 => uint256) private LastRecordedMerkleTreeIndex;

    mapping(bytes32 => mapping(uint256 => EnumerableSet.Bytes32Set))
        private treeLeafList;

    event SpaceCreated(
        bytes32 regimentId,
        bytes32 spaceId,
        SpaceInfo spaceInfo
    );
    event MerkleTreeRecorded(
        bytes32 regimentId,
        bytes32 spaceId,
        uint256 merkleTreeIndex,
        uint256 lastRecordedLeafIndex
    );

    constructor(address _regimentAddress) {
        regimentAddress = _regimentAddress;
    }

    function createSpace(bytes32 regimentId, uint256 pathLength)
        external
        returns (bytes32)
    {
        bool isAdmin = Regiment(regimentAddress).IsRegimentAdmin(
            regimentId,
            msg.sender
        );
        require(isAdmin, 'No permission.');

        uint256 spaceIndex = RegimentSpaceIndexMap[regimentId];
        bytes32 spaceId = sha256(abi.encodePacked(regimentId, spaceIndex));

        require(pathLength <= PathMaximalLength, 'Path to deep');
        spaceInfoMap[spaceId] = SpaceInfo({
            maxLeafCount: 1 << pathLength,
            pathLength: pathLength,
            operator: regimentId
        });
        RegimentSpaceIndexMap[regimentId] = spaceIndex.add(1);
        RegimentSpaceIdListMap[regimentId].add(spaceId);

        emit SpaceCreated(regimentId, spaceId, spaceInfoMap[spaceId]);
        return spaceId;
    }

    function recordMerkleTree(bytes32 spaceId, bytes32[] memory leafNodeHash)
        external
        returns (uint256)
    {
        SpaceInfo storage spaceInfo = spaceInfoMap[spaceId];

        require(
            Regiment(regimentAddress).IsRegimentMember(
                spaceInfo.operator,
                msg.sender
            ),
            'No permission.'
        );
        uint256 lastRecordedMerkleTreeIndex = LastRecordedMerkleTreeIndex[
            spaceId
        ];

        uint256 expectIndex = saveLeaves(spaceId, leafNodeHash);

        for (
            ;
            lastRecordedMerkleTreeIndex <= expectIndex;
            lastRecordedMerkleTreeIndex++
        ) {
            updateMerkleTree(spaceId, lastRecordedMerkleTreeIndex);
        }
        return SpaceMerkleTree[spaceId][expectIndex].lastLeafIndex;
    }

    //view funciton
    function getSpaceInfo(bytes32 spaceId)
        public
        view
        returns (SpaceInfo memory)
    {
        return spaceInfoMap[spaceId];
    }

    function getRegimentSpaceIdListMap(bytes32 regimentId)
        public
        view
        returns (bytes32[] memory)
    {
        return RegimentSpaceIdListMap[regimentId].values();
    }

    function getRemainLeafCount(bytes32 spaceId) public view returns (uint256) {
        uint256 defaultIndex = LastRecordedMerkleTreeIndex[spaceId];
        return getRemainLeafCountForExactTree(spaceId, defaultIndex);
    }

    function getRemainLeafCountForExactTree(bytes32 spaceId, uint256 treeIndex)
        public
        view
        returns (uint256)
    {
        {
            SpaceInfo storage spaceInfo = spaceInfoMap[spaceId];
            MerkleTree storage tree = SpaceMerkleTree[spaceId][treeIndex];
            if (tree.spaceId == bytes32(0)) {
                return spaceInfo.maxLeafCount;
            }
            if (tree.isFullTree) {
                return 0;
            } else {
                uint256 currentTreeCount = tree
                    .lastLeafIndex
                    .sub(tree.firstLeafIndex)
                    .add(1);
                return spaceInfo.maxLeafCount.sub(currentTreeCount);
            }
        }
    }

    function getLeafLocatedMerkleTreeIndex(bytes32 spaceId, uint256 leaf_index)
        public
        view
        returns (uint256)
    {
        uint256 index = LastRecordedMerkleTreeIndex[spaceId];
        MerkleTree storage tree = SpaceMerkleTree[spaceId][index];
        uint256 lastRecordLeafIndex = tree.lastLeafIndex;
        require(lastRecordLeafIndex >= leaf_index, 'not recorded yet');
        SpaceInfo storage spaceInfo = spaceInfoMap[spaceId];
        uint256 merkleTreeIndex = leaf_index.div(spaceInfo.maxLeafCount);
        return merkleTreeIndex;
    }

    function getFullTreeCount(bytes32 spaceId) public view returns (uint256) {
        return FullMerkleTreeCountMap[spaceId];
    }

    function getLastLeafIndex(bytes32 spaceId) public view returns (uint256) {
        uint256 index = LastRecordedMerkleTreeIndex[spaceId];
        MerkleTree storage tree = SpaceMerkleTree[spaceId][index];
        return tree.lastLeafIndex;
    }

    function getMerkleTreeByIndex(bytes32 spaceId, uint256 merkle_tree_index)
        public
        view
        returns (MerkleTree memory)
    {
        return SpaceMerkleTree[spaceId][merkle_tree_index];
    }

    function getMerkleTreeCountBySpace(bytes32 spaceId)
        public
        view
        returns (uint256)
    {
        return LastRecordedMerkleTreeIndex[spaceId].add(1);
    }

    function getMerklePath(bytes32 spaceId, uint256 leafNodeIndex)
        public
        view
        returns (
            uint256 treeIndex,
            uint256 pathLength,
            bytes32[] memory neighbors,
            bool[] memory positions
        )
    {
        SpaceInfo storage spaceInfo = spaceInfoMap[spaceId];
        treeIndex = LastRecordedMerkleTreeIndex[spaceId];
        MerkleTree storage tree = SpaceMerkleTree[spaceId][treeIndex];
        uint256 lastRecordLeafIndex = tree.lastLeafIndex;
        require(lastRecordLeafIndex >= leafNodeIndex, 'not recorded yet');

        for (; treeIndex >= 0; treeIndex--) {
            if (
                leafNodeIndex >=
                SpaceMerkleTree[spaceId][treeIndex].firstLeafIndex
            ) break;
        }
        MerkleTree storage locatedTree = SpaceMerkleTree[spaceId][treeIndex];
        uint256 index = leafNodeIndex - locatedTree.firstLeafIndex;
        bytes32[] memory path = new bytes32[](spaceInfo.pathLength);
        bool[] memory isLeftNeighbors = new bool[](spaceInfo.pathLength);

        (pathLength, path, isLeftNeighbors) = _generatePath(
            locatedTree,
            index,
            spaceInfo.maxLeafCount * 2,
            spaceInfo.pathLength
        );

        neighbors = new bytes32[](pathLength);
        positions = new bool[](pathLength);

        for (uint256 i = 0; i < pathLength; i++) {
            neighbors[i] = path[i];
            positions[i] = isLeftNeighbors[i];
        }
        return (treeIndex, pathLength, neighbors, positions);
    }

    function merkleProof(
        bytes32 spaceId,
        uint256 _treeIndex,
        bytes32 _leafHash,
        bytes32[] calldata _merkelTreePath,
        bool[] calldata _isLeftNode
    ) external view returns (bool) {
        if (_merkelTreePath.length != _isLeftNode.length) {
            return false;
        }
        MerkleTree memory merkleTree = SpaceMerkleTree[spaceId][_treeIndex];

        for (uint256 i = 0; i < _merkelTreePath.length; i++) {
            if (_isLeftNode[i]) {
                _leafHash = sha256(abi.encode(_merkelTreePath[i], _leafHash));
                continue;
            }
            _leafHash = sha256(abi.encode(_leafHash, _merkelTreePath[i]));
        }
        return _leafHash == merkleTree.merkleTreeRoot;
    }

    //private funtion

    function _leavesToTree(bytes32[] memory _leaves, uint256 maximalTreeSize)
        private
        pure
        returns (bytes32[] memory, uint256)
    {
        uint256 leafCount = _leaves.length;
        bytes32 left;
        bytes32 right;

        uint256 newAdded = 0;
        uint256 i = 0;

        bytes32[] memory nodes = new bytes32[](maximalTreeSize);

        for (uint256 t = 0; t < leafCount; t++) {
            nodes[t] = _leaves[t];
        }

        uint256 nodeCount = leafCount;
        if (_leaves.length.mod(2) == 1) {
            nodes[leafCount] = (_leaves[leafCount.sub(1)]);
            nodeCount = nodeCount.add(1);
        }

        uint256 nodeToAdd = nodeCount.div(2);

        while (i < nodeCount.sub(1)) {
            left = nodes[i];
            i = i.add(1);

            right = nodes[i];
            i = i.add(1);

            nodes[nodeCount] = sha256(abi.encode(left, right));
            nodeCount = nodeCount.add(1);

            if (++newAdded != nodeToAdd) continue;

            if (nodeToAdd.mod(2) == 1 && nodeToAdd != 1) {
                nodeToAdd = nodeToAdd.add(1);
                nodes[nodeCount] = nodes[nodeCount.sub(1)];
                nodeCount = nodeCount.add(1);
            }

            nodeToAdd = nodeToAdd.div(2);
            newAdded = 0;
        }

        return (nodes, nodeCount);
    }

    function _generateMerkleTree(bytes32 spaceId, uint256 merkleTreeIndex)
        private
        view
        returns (MerkleTree memory, bytes32[] memory)
    {
        bytes32[] memory allNodes;
        uint256 nodeCount;
        bytes32[] memory leafNodes = treeLeafList[spaceId][merkleTreeIndex]
            .values();

        uint256 treeMaximalSize = spaceInfoMap[spaceId].maxLeafCount * 2;

        bool isFullTree = spaceInfoMap[spaceId].maxLeafCount ==
            leafNodes.length;
        uint256 firstLeafIndex = spaceInfoMap[spaceId].maxLeafCount *
            merkleTreeIndex;
        uint256 lastLeafIndex = firstLeafIndex.add(leafNodes.length).sub(1);
        (allNodes, nodeCount) = _leavesToTree(leafNodes, treeMaximalSize);
        MerkleTree memory merkleTree = MerkleTree(
            spaceId,
            merkleTreeIndex,
            firstLeafIndex,
            lastLeafIndex,
            allNodes[nodeCount - 1],
            isFullTree
        );

        bytes32[] memory treeNodes = new bytes32[](nodeCount);
        for (uint256 t = 0; t < nodeCount; t++) {
            treeNodes[t] = allNodes[t];
        }
        return (merkleTree, treeNodes);
    }

    function _generatePath(
        MerkleTree memory _merkleTree,
        uint256 _index,
        uint256 treeMaximalSize,
        uint256 pathLength
    )
        private
        view
        returns (
            uint256,
            bytes32[] memory,
            bool[] memory
        )
    {
        bytes32[] memory leaves = treeLeafList[_merkleTree.spaceId][
            _merkleTree.merkleTreeIndex
        ].values();
        bytes32[] memory allNodes;
        uint256 nodeCount;

        (allNodes, nodeCount) = _leavesToTree(leaves, treeMaximalSize);

        bytes32[] memory nodes = new bytes32[](nodeCount);
        for (uint256 t = 0; t < nodeCount; t++) {
            nodes[t] = allNodes[t];
        }

        return _generatePath(nodes, leaves.length, _index, pathLength);
    }

    function _generatePath(
        bytes32[] memory _nodes,
        uint256 _leafCount,
        uint256 _index,
        uint256 pathLength
    )
        private
        pure
        returns (
            uint256,
            bytes32[] memory neighbors,
            bool[] memory isLeftNeighbors
        )
    {
        neighbors = new bytes32[](pathLength);
        isLeftNeighbors = new bool[](pathLength);
        uint256 indexOfFirstNodeInRow = 0;
        uint256 nodeCountInRow = _leafCount;
        bytes32 neighbor;
        bool isLeftNeighbor;
        uint256 shift;
        uint256 i = 0;

        while (_index < _nodes.length.sub(1)) {
            if (_index.mod(2) == 0) {
                // add right neighbor node
                neighbor = _nodes[_index.add(1)];
                isLeftNeighbor = false;
            } else {
                // add left neighbor node
                neighbor = _nodes[_index.sub(1)];
                isLeftNeighbor = true;
            }

            neighbors[i] = neighbor;
            isLeftNeighbors[i] = isLeftNeighbor;
            i = i.add(1);

            nodeCountInRow = nodeCountInRow.mod(2) == 0
                ? nodeCountInRow
                : nodeCountInRow.add(1);
            shift = _index.sub(indexOfFirstNodeInRow).div(2);
            indexOfFirstNodeInRow = indexOfFirstNodeInRow.add(nodeCountInRow);
            _index = indexOfFirstNodeInRow.add(shift);
            nodeCountInRow = nodeCountInRow.div(2);
        }

        return (i, neighbors, isLeftNeighbors);
    }

    function saveLeaves(bytes32 spaceId, bytes32[] memory leafNodeHash)
        private
        returns (uint256)
    {
        uint256 savedLeafsCount = 0;
        uint256 currentTreeIndex = LastRecordedMerkleTreeIndex[spaceId];
        uint256 remainLeafCount;
        while (savedLeafsCount < leafNodeHash.length) {
            remainLeafCount = getRemainLeafCountForExactTree(
                spaceId,
                currentTreeIndex
            );
            uint256 restLeafCount = leafNodeHash.length.sub(savedLeafsCount);
            uint256 currentSaveCount = remainLeafCount >= restLeafCount
                ? restLeafCount
                : remainLeafCount;
            saveLeavesForExactTree(
                spaceId,
                currentTreeIndex,
                leafNodeHash,
                savedLeafsCount,
                savedLeafsCount.add(currentSaveCount).sub(1)
            );
            currentTreeIndex = currentTreeIndex.add(1);
            savedLeafsCount = savedLeafsCount.add(currentSaveCount);
        }
        return currentTreeIndex.sub(1);
    }

    function saveLeavesForExactTree(
        bytes32 spaceId,
        uint256 treeIndex,
        bytes32[] memory leafNodeHash,
        uint256 from,
        uint256 to
    ) private {
        EnumerableSet.Bytes32Set storage leafs = treeLeafList[spaceId][
            treeIndex
        ];
        for (uint256 i = from; i <= to; i++) {
            leafs.add(leafNodeHash[i]);
        }
    }

    function updateMerkleTree(bytes32 spaceId, uint256 treeIndex) private {
        (MerkleTree memory tree, ) = _generateMerkleTree(spaceId, treeIndex);
        SpaceInfo storage spaceInfo = spaceInfoMap[spaceId];
        SpaceMerkleTree[spaceId][treeIndex] = tree;
        if (tree.isFullTree) {
            FullMerkleTreeCountMap[spaceId] = FullMerkleTreeCountMap[spaceId]
                .add(1);
        }
        LastRecordedMerkleTreeIndex[spaceId] = treeIndex;
        emit MerkleTreeRecorded(
            spaceInfo.operator,
            spaceId,
            treeIndex,
            tree.lastLeafIndex
        );
    }
}

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
pragma solidity 0.8.9;

contract Regiment {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    address private controller;
    uint256 private memberJoinLimit;
    uint256 private regimentLimit;
    uint256 private maximumAdminsCount;

    uint256 public DefaultMemberJoinLimit = 256;
    uint256 public DefaultRegimentLimit = 1024;
    uint256 public DefaultMaximumAdminsCount = 3;
    uint256 public regimentCount;
    mapping(bytes32 => RegimentInfo) private regimentInfoMap;
    mapping(bytes32 => EnumerableSet.AddressSet) private regimentMemberListMap;

    event RegimentCreated(
        uint256 createTime,
        address manager,
        address[] initialMemberList,
        bytes32 regimentId
    );

    event NewMemberApplied(bytes32 regimentId, address applyMemberAddress);
    event NewMemberAdded(
        bytes32 regimentId,
        address newMemberAddress,
        address operatorAddress
    );

    event RegimentMemberLeft(
        bytes32 regimentId,
        address leftMemberAddress,
        address operatorAddress
    );

    struct RegimentInfo {
        uint256 createTime;
        address manager;
        EnumerableSet.AddressSet admins;
        bool isApproveToJoin;
    }
    struct RegimentInfoForView {
        uint256 createTime;
        address manager;
        address[] admins;
        bool isApproveToJoin;
    }
    modifier assertSenderIsController() {
        require(msg.sender == controller, 'Sender is not the Controller.');
        _;
    }

    constructor(
        uint256 _memberJoinLimit,
        uint256 _regimentLimit,
        uint256 _maximumAdminsCount
    ) {
        require(
            _memberJoinLimit <= DefaultMemberJoinLimit,
            'Invalid memberJoinLimit'
        );
        require(
            _regimentLimit <= DefaultRegimentLimit,
            'Invalid regimentLimit'
        );
        require(
            _maximumAdminsCount <= DefaultMaximumAdminsCount,
            'Invalid maximumAdminsCount'
        );
        controller = msg.sender;
        memberJoinLimit = _memberJoinLimit;
        regimentLimit = _regimentLimit;
        maximumAdminsCount = _maximumAdminsCount == 0
            ? DefaultMaximumAdminsCount
            : _maximumAdminsCount;
        require(memberJoinLimit <= regimentLimit, 'Incorrect MemberJoinLimit.');
    }

    function CreateRegiment(
        address manager,
        address[] calldata initialMemberList,
        bool isApproveToJoin
    ) external assertSenderIsController returns (bytes32) {
        bytes32 regimentId = sha256(abi.encodePacked(regimentCount, manager));
        regimentCount = regimentCount.add(1);
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        for (uint256 i; i < initialMemberList.length; i++) {
            memberList.add(initialMemberList[i]);
        }
        if (!memberList.contains(manager)) {
            memberList.add(manager);
        }
        require(
            memberList.length() <= memberJoinLimit,
            'Too many initial members.'
        );
        regimentInfoMap[regimentId].createTime = block.timestamp;
        regimentInfoMap[regimentId].manager = manager;
        regimentInfoMap[regimentId].isApproveToJoin = isApproveToJoin;
        emit RegimentCreated(
            block.timestamp,
            manager,
            initialMemberList,
            regimentId
        );
        return regimentId;
    }

    function JoinRegiment(
        bytes32 regimentId,
        address newMerberAddess,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(
            memberList.length() <= regimentLimit,
            'Regiment member reached the limit'
        );
        if (
            regimentInfo.isApproveToJoin ||
            memberList.length() >= memberJoinLimit
        ) {
            emit NewMemberApplied(regimentId, newMerberAddess);
        } else {
            memberList.add(newMerberAddess);
            emit NewMemberAdded(
                regimentId,
                newMerberAddess,
                originSenderAddress
            );
        }
    }

    function LeaveRegiment(
        bytes32 regimentId,
        address leaveMemberAddress,
        address originSenderAddress
    ) external assertSenderIsController {
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(originSenderAddress == leaveMemberAddress, 'No permission.');
        memberList.remove(leaveMemberAddress);
        emit RegimentMemberLeft(
            regimentId,
            leaveMemberAddress,
            originSenderAddress
        );
    }

    function AddRegimentMember(
        bytes32 regimentId,
        address newMerberAddess,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(
            memberList.length() <= regimentLimit,
            'Regiment member reached the limit'
        );
        require(
            regimentInfo.admins.contains(originSenderAddress) ||
                regimentInfo.manager == originSenderAddress,
            'Origin sender is not manager or admin of this regiment'
        );
        memberList.add(newMerberAddess);
        emit NewMemberAdded(regimentId, newMerberAddess, originSenderAddress);
    }

    function DeleteRegimentMember(
        bytes32 regimentId,
        address leaveMemberAddress,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        require(
            memberList.length() <= regimentLimit,
            'Regiment member reached the limit'
        );
        require(
            regimentInfo.admins.contains(originSenderAddress) ||
                regimentInfo.manager == originSenderAddress,
            'Origin sender is not manager or admin of this regiment'
        );
        memberList.remove(leaveMemberAddress);
        emit RegimentMemberLeft(
            regimentId,
            leaveMemberAddress,
            originSenderAddress
        );
    }

    function ChangeController(address _controller)
        external
        assertSenderIsController
    {
        controller = _controller;
    }

    function ResetConfig(
        uint256 _memberJoinLimit,
        uint256 _regimentLimit,
        uint256 _maximumAdminsCount
    ) external assertSenderIsController {
        memberJoinLimit = _memberJoinLimit == 0
            ? memberJoinLimit
            : _memberJoinLimit;
        regimentLimit = _regimentLimit == 0 ? regimentLimit : _regimentLimit;
        maximumAdminsCount = _maximumAdminsCount == 0
            ? maximumAdminsCount
            : _maximumAdminsCount;
        require(memberJoinLimit <= regimentLimit, 'Incorrect MemberJoinLimit.');
    }

    function TransferRegimentOwnership(
        bytes32 regimentId,
        address newManagerAddress,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        require(originSenderAddress == regimentInfo.manager, 'No permission.');
        regimentInfo.manager = newManagerAddress;
    }

    function AddAdmins(
        bytes32 regimentId,
        address[] calldata newAdmins,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        require(originSenderAddress == regimentInfo.manager, 'No permission.');
        for (uint256 i; i < newAdmins.length; i++) {
            require(
                !regimentInfo.admins.contains(newAdmins[i]),
                'someone is already an admin'
            );
            regimentInfo.admins.add(newAdmins[i]);
        }
        require(
            regimentInfo.admins.length() <= maximumAdminsCount,
            'Admins count cannot greater than maximumAdminsCount'
        );
    }

    function DeleteAdmins(
        bytes32 regimentId,
        address[] calldata deleteAdmins,
        address originSenderAddress
    ) external assertSenderIsController {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        require(originSenderAddress == regimentInfo.manager, 'No permission.');
        for (uint256 i; i < deleteAdmins.length; i++) {
            require(
                regimentInfo.admins.contains(deleteAdmins[i]),
                'someone is not an admin'
            );
            regimentInfo.admins.remove(deleteAdmins[i]);
        }
    }

    //view functions

    function GetController() external view returns (address) {
        return controller;
    }

    function GetConfig()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (maximumAdminsCount, memberJoinLimit, regimentLimit);
    }

    function GetRegimentInfo(bytes32 regimentId)
        external
        view
        returns (RegimentInfoForView memory)
    {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        return
            RegimentInfoForView({
                createTime: regimentInfo.createTime,
                manager: regimentInfo.manager,
                admins: regimentInfo.admins.values(),
                isApproveToJoin: regimentInfo.isApproveToJoin
            });
    }

    function IsRegimentMember(bytes32 regimentId, address memberAddress)
        external
        view
        returns (bool)
    {
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        return memberList.contains(memberAddress);
    }

    function IsRegimentAdmin(bytes32 regimentId, address adminAddress)
        external
        view
        returns (bool)
    {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        return regimentInfo.admins.contains(adminAddress);
    }

    function IsRegimentManager(bytes32 regimentId, address managerAddress)
        external
        view
        returns (bool)
    {
        RegimentInfo storage regimentInfo = regimentInfoMap[regimentId];
        return regimentInfo.manager == managerAddress;
    }

    function GetRegimentMemberList(bytes32 regimentId)
        external
        view
        returns (address[] memory)
    {
        EnumerableSet.AddressSet storage memberList = regimentMemberListMap[
            regimentId
        ];
        return memberList.values();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}