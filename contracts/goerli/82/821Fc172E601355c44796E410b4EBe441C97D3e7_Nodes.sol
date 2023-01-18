// SPDX-License-Identifier: AGPL-3.0-only

/*
    Nodes.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin
    @author Dmytro Stebaiev
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "@skalenetwork/skale-manager-interfaces/INodes.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/IDelegationController.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/IValidatorService.sol";
import "@skalenetwork/skale-manager-interfaces/IBountyV2.sol";

import "./Permissions.sol";
import "./ConstantsHolder.sol";
import "./utils/Random.sol";
import "./utils/SegmentTree.sol";

import "./NodeRotation.sol";


/**
 * @title Nodes
 * @dev This contract contains all logic to manage SKALE Network nodes states,
 * space availability, stake requirement checks, and exit functions.
 *
 * Nodes may be in one of several states:
 *
 * - Active:            Node is registered and is in network operation.
 * - Leaving:           Node has begun exiting from the network.
 * - Left:              Node has left the network.
 * - In_Maintenance:    Node is temporarily offline or undergoing infrastructure
 * maintenance
 *
 * Note: Online nodes contain both Active and Leaving states.
 */
contract Nodes is Permissions, INodes {

    using Random for IRandom.RandomGenerator;
    using SafeCastUpgradeable for uint;
    using SegmentTree for SegmentTree.Tree;

    bytes32 constant public COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");
    bytes32 public constant NODE_MANAGER_ROLE = keccak256("NODE_MANAGER_ROLE");

    // array which contain all Nodes
    Node[] public nodes;

    SpaceManaging[] public spaceOfNodes;

    // mapping for checking which Nodes and which number of Nodes owned by user
    mapping (address => CreatedNodes) public nodeIndexes;
    // mapping for checking is IP address busy
    mapping (bytes4 => bool) public nodesIPCheck;
    // mapping for checking is Name busy
    mapping (bytes32 => bool) public nodesNameCheck;
    // mapping for indication from Name to Index
    mapping (bytes32 => uint) public nodesNameToIndex;
    // mapping for indication from space to Nodes
    mapping (uint8 => uint[]) public spaceToNodes;

    mapping (uint => uint[]) public validatorToNodeIndexes;

    uint public override numberOfActiveNodes;
    uint public numberOfLeavingNodes;
    uint public numberOfLeftNodes;

    mapping (uint => string) public domainNames;

    mapping (uint => bool) private _invisible;

    SegmentTree.Tree private _nodesAmountBySpace;

    mapping (uint => bool) public override incompliant;

    modifier checkNodeExists(uint nodeIndex) {
        _checkNodeIndex(nodeIndex);
        _;
    }

    modifier onlyNodeOrNodeManager(uint nodeIndex) {
        _checkNodeOrNodeManager(nodeIndex, msg.sender);
        _;
    }

    modifier onlyCompliance() {
        require(hasRole(COMPLIANCE_ROLE, msg.sender), "COMPLIANCE_ROLE is required");
        _;
    }

    modifier nonZeroIP(bytes4 ip) {
        require(ip != 0x0 && !nodesIPCheck[ip], "IP address is zero or is not available");
        _;
    }

    /**
     * @dev Allows Schains and SchainsInternal contracts to occupy available
     * space on a node.
     *
     * Returns whether operation is successful.
     */
    function removeSpaceFromNode(uint nodeIndex, uint8 space)
        external
        override
        checkNodeExists(nodeIndex)
        allowTwo("NodeRotation", "SchainsInternal")
        returns (bool)
    {
        if (spaceOfNodes[nodeIndex].freeSpace < space) {
            return false;
        }
        if (space > 0) {
            _moveNodeToNewSpaceMap(
                nodeIndex,
                (uint(spaceOfNodes[nodeIndex].freeSpace) - space).toUint8()
            );
        }
        return true;
    }

    /**
     * @dev Allows Schains contract to occupy free space on a node.
     *
     * Returns whether operation is successful.
     */
    function addSpaceToNode(uint nodeIndex, uint8 space)
        external
        override
        checkNodeExists(nodeIndex)
        allow("SchainsInternal")
    {
        if (space > 0) {
            _moveNodeToNewSpaceMap(
                nodeIndex,
                (uint(spaceOfNodes[nodeIndex].freeSpace) + space).toUint8()
            );
        }
    }

    /**
     * @dev Allows SkaleManager to change a node's last reward date.
     */
    function changeNodeLastRewardDate(uint nodeIndex)
        external
        override
        checkNodeExists(nodeIndex)
        allow("SkaleManager")
    {
        nodes[nodeIndex].lastRewardDate = block.timestamp;
    }

    /**
     * @dev Allows SkaleManager to change a node's finish time.
     */
    function changeNodeFinishTime(uint nodeIndex, uint time)
        external
        override
        checkNodeExists(nodeIndex)
        allow("SkaleManager")
    {
        nodes[nodeIndex].finishTime = time;
    }

    /**
     * @dev Allows SkaleManager contract to create new node and add it to the
     * Nodes contract.
     *
     * Emits a {NodeCreated} event.
     *
     * Requirements:
     *
     * - Node IP must be non-zero.
     * - Node IP must be available.
     * - Node name must not already be registered.
     * - Node port must be greater than zero.
     */
    function createNode(address from, NodeCreationParams calldata params)
        external
        override
        allow("SkaleManager")
        nonZeroIP(params.ip)
    {
        // checks that Node has correct data
        require(!nodesNameCheck[keccak256(abi.encodePacked(params.name))], "Name is already registered");
        require(params.port > 0, "Port is zero");
        require(from == _publicKeyToAddress(params.publicKey), "Public Key is incorrect");
        uint validatorId = IValidatorService(
            contractManager.getContract("ValidatorService")).getValidatorIdByNodeAddress(from);
        uint8 totalSpace = ConstantsHolder(contractManager.getContract("ConstantsHolder")).TOTAL_SPACE_ON_NODE();
        nodes.push(Node({
            name: params.name,
            ip: params.ip,
            publicIP: params.publicIp,
            port: params.port,
            publicKey: params.publicKey,
            startBlock: block.number,
            lastRewardDate: block.timestamp,
            finishTime: 0,
            status: NodeStatus.Active,
            validatorId: validatorId
        }));
        uint nodeIndex = nodes.length - 1;
        validatorToNodeIndexes[validatorId].push(nodeIndex);
        bytes32 nodeId = keccak256(abi.encodePacked(params.name));
        nodesIPCheck[params.ip] = true;
        nodesNameCheck[nodeId] = true;
        nodesNameToIndex[nodeId] = nodeIndex;
        nodeIndexes[from].isNodeExist[nodeIndex] = true;
        nodeIndexes[from].numberOfNodes++;
        domainNames[nodeIndex] = params.domainName;
        spaceOfNodes.push(SpaceManaging({
            freeSpace: totalSpace,
            indexInSpaceMap: spaceToNodes[totalSpace].length
        }));
        _setNodeActive(nodeIndex);
        emit NodeCreated(
            nodeIndex,
            from,
            params.name,
            params.ip,
            params.publicIp,
            params.port,
            params.nonce,
            params.domainName);
    }

    /**
     * @dev Allows NODE_MANAGER_ROLE to initiate a node exit procedure.
     *
     * Returns whether the operation is successful.
     *
     * Emits an {ExitInitialized} event.
     */
    function initExit(uint nodeIndex)
        external
        override
        checkNodeExists(nodeIndex)
    {
        require(hasRole(NODE_MANAGER_ROLE, msg.sender), "NODE_MANAGER_ROLE is required");
        require(isNodeActive(nodeIndex), "Node should be Active");
        _setNodeLeaving(nodeIndex);
        NodeRotation(contractManager.getContract("NodeRotation")).freezeSchains(nodeIndex);
        emit ExitInitialized(nodeIndex, block.timestamp);
    }

    /**
     * @dev Allows SkaleManager contract to complete a node exit procedure.
     *
     * Returns whether the operation is successful.
     *
     * Emits an {ExitCompleted} event.
     *
     * Requirements:
     *
     * - Node must have already initialized a node exit procedure.
     */
    function completeExit(uint nodeIndex)
        external
        override
        checkNodeExists(nodeIndex)
        allow("SkaleManager")
        returns (bool)
    {
        require(isNodeLeaving(nodeIndex), "Node is not Leaving");

        _setNodeLeft(nodeIndex);

        emit ExitCompleted(nodeIndex);
        return true;
    }

    /**
     * @dev Allows SkaleManager contract to delete a validator's node.
     *
     * Requirements:
     *
     * - Validator ID must exist.
     */
    function deleteNodeForValidator(uint validatorId, uint nodeIndex)
        external
        override
        checkNodeExists(nodeIndex)
        allow("SkaleManager")
    {
        IValidatorService validatorService = IValidatorService(contractManager.getValidatorService());
        require(validatorService.validatorExists(validatorId), "Validator ID does not exist");
        uint[] memory validatorNodes = validatorToNodeIndexes[validatorId];
        uint position = _findNode(validatorNodes, nodeIndex);
        if (position < validatorNodes.length) {
            validatorToNodeIndexes[validatorId][position] =
                validatorToNodeIndexes[validatorId][validatorNodes.length - 1];
        }
        validatorToNodeIndexes[validatorId].pop();
        address nodeOwner = _publicKeyToAddress(nodes[nodeIndex].publicKey);
        if (validatorService.getValidatorIdByNodeAddress(nodeOwner) == validatorId) {
            if (nodeIndexes[nodeOwner].numberOfNodes == 1 && !validatorService.validatorAddressExists(nodeOwner)) {
                validatorService.removeNodeAddress(validatorId, nodeOwner);
            }
            nodeIndexes[nodeOwner].isNodeExist[nodeIndex] = false;
            nodeIndexes[nodeOwner].numberOfNodes--;
        }
    }

    /**
     * @dev Allows SkaleManager contract to check whether a validator has
     * sufficient stake to create another node.
     *
     * Requirements:
     *
     * - Validator must be included on trusted list if trusted list is enabled.
     * - Validator must have sufficient stake to operate an additional node.
     */
    function checkPossibilityCreatingNode(address nodeAddress) external override allow("SkaleManager") {
        IValidatorService validatorService = IValidatorService(contractManager.getValidatorService());
        uint validatorId = validatorService.getValidatorIdByNodeAddress(nodeAddress);
        require(validatorService.isAuthorizedValidator(validatorId), "Validator is not authorized to create a node");
        require(
            _checkValidatorPositionToMaintainNode(validatorId, validatorToNodeIndexes[validatorId].length),
            "Validator must meet the Minimum Staking Requirement");
    }

    /**
     * @dev Allows SkaleManager contract to check whether a validator has
     * sufficient stake to maintain a node.
     *
     * Returns whether validator can maintain node with current stake.
     *
     * Requirements:
     *
     * - Validator ID and nodeIndex must both exist.
     */
    function checkPossibilityToMaintainNode(
        uint validatorId,
        uint nodeIndex
    )
        external
        override
        checkNodeExists(nodeIndex)
        allow("Bounty")
        returns (bool)
    {
        IValidatorService validatorService = IValidatorService(contractManager.getValidatorService());
        require(validatorService.validatorExists(validatorId), "Validator ID does not exist");
        uint[] memory validatorNodes = validatorToNodeIndexes[validatorId];
        uint position = _findNode(validatorNodes, nodeIndex);
        require(position < validatorNodes.length, "Node does not exist for this Validator");
        return _checkValidatorPositionToMaintainNode(validatorId, position);
    }

    /**
     * @dev Allows Node to set In_Maintenance status.
     *
     * Requirements:
     *
     * - Node must already be Active.
     * - `msg.sender` must be owner of Node, validator, or SkaleManager.
     */
    function setNodeInMaintenance(uint nodeIndex) external override onlyNodeOrNodeManager(nodeIndex) {
        require(nodes[nodeIndex].status == NodeStatus.Active, "Node is not Active");
        _setNodeInMaintenance(nodeIndex);
        emit MaintenanceNode(nodeIndex, true);
    }

    /**
     * @dev Allows Node to remove In_Maintenance status.
     *
     * Requirements:
     *
     * - Node must already be In Maintenance.
     * - `msg.sender` must be owner of Node, validator, or SkaleManager.
     */
    function removeNodeFromInMaintenance(uint nodeIndex) external override onlyNodeOrNodeManager(nodeIndex) {
        require(nodes[nodeIndex].status == NodeStatus.In_Maintenance, "Node is not In Maintenance");
        _setNodeActive(nodeIndex);
        emit MaintenanceNode(nodeIndex, false);
    }

    /**
     * @dev Marks the node as incompliant
     *
     */
    function setNodeIncompliant(uint nodeIndex) external override onlyCompliance checkNodeExists(nodeIndex) {
        if (!incompliant[nodeIndex]) {
            incompliant[nodeIndex] = true;
            _makeNodeInvisible(nodeIndex);
            emit IncompliantNode(nodeIndex, true);
        }
    }

    /**
     * @dev Marks the node as compliant
     *
     */
    function setNodeCompliant(uint nodeIndex) external override onlyCompliance checkNodeExists(nodeIndex) {
        if (incompliant[nodeIndex]) {
            incompliant[nodeIndex] = false;
            _tryToMakeNodeVisible(nodeIndex);
            emit IncompliantNode(nodeIndex, false);
        }
    }

    function setDomainName(uint nodeIndex, string memory domainName)
        external
        override
        onlyNodeOrNodeManager(nodeIndex)
    {
        domainNames[nodeIndex] = domainName;
    }

    function makeNodeVisible(uint nodeIndex) external override allow("SchainsInternal") {
        _tryToMakeNodeVisible(nodeIndex);
    }

    function makeNodeInvisible(uint nodeIndex) external override allow("SchainsInternal") {
        _makeNodeInvisible(nodeIndex);
    }

    function changeIP(
        uint nodeIndex,
        bytes4 newIP,
        bytes4 newPublicIP
    )
        external
        override
        onlyAdmin
        checkNodeExists(nodeIndex)
        nonZeroIP(newIP)
    {
        if (newPublicIP != 0x0) {
            require(newIP == newPublicIP, "IP address is not the same");
            nodes[nodeIndex].publicIP = newPublicIP;
        }
        nodesIPCheck[nodes[nodeIndex].ip] = false;
        nodesIPCheck[newIP] = true;
        emit IPChanged(nodeIndex, nodes[nodeIndex].ip, newIP);
        nodes[nodeIndex].ip = newIP;
    }

    function getRandomNodeWithFreeSpace(
        uint8 freeSpace,
        IRandom.RandomGenerator memory randomGenerator
    )
        external
        view
        override
        returns (uint)
    {
        uint8 place = _nodesAmountBySpace.getRandomNonZeroElementFromPlaceToLast(
            freeSpace == 0 ? 1 : freeSpace,
            randomGenerator
        ).toUint8();
        require(place > 0, "Node not found");
        return spaceToNodes[place][randomGenerator.random(spaceToNodes[place].length)];
    }

    /**
     * @dev Checks whether it is time for a node's reward.
     */
    function isTimeForReward(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (bool)
    {
        return IBountyV2(contractManager.getBounty()).getNextRewardTimestamp(nodeIndex) <= block.timestamp;
    }

    /**
     * @dev Returns IP address of a given node.
     *
     * Requirements:
     *
     * - Node must exist.
     */
    function getNodeIP(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (bytes4)
    {
        require(nodeIndex < nodes.length, "Node does not exist");
        return nodes[nodeIndex].ip;
    }

    /**
     * @dev Returns domain name of a given node.
     *
     * Requirements:
     *
     * - Node must exist.
     */
    function getNodeDomainName(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (string memory)
    {
        return domainNames[nodeIndex];
    }

    /**
     * @dev Returns the port of a given node.
     *
     * Requirements:
     *
     * - Node must exist.
     */
    function getNodePort(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (uint16)
    {
        return nodes[nodeIndex].port;
    }

    /**
     * @dev Returns the public key of a given node.
     */
    function getNodePublicKey(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (bytes32[2] memory)
    {
        return nodes[nodeIndex].publicKey;
    }

    /**
     * @dev Returns an address of a given node.
     */
    function getNodeAddress(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (address)
    {
        return _publicKeyToAddress(nodes[nodeIndex].publicKey);
    }


    /**
     * @dev Returns the finish exit time of a given node.
     */
    function getNodeFinishTime(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (uint)
    {
        return nodes[nodeIndex].finishTime;
    }

    /**
     * @dev Checks whether a node has left the network.
     */
    function isNodeLeft(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (bool)
    {
        return nodes[nodeIndex].status == NodeStatus.Left;
    }

    function isNodeInMaintenance(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (bool)
    {
        return nodes[nodeIndex].status == NodeStatus.In_Maintenance;
    }

    /**
     * @dev Returns a given node's last reward date.
     */
    function getNodeLastRewardDate(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (uint)
    {
        return nodes[nodeIndex].lastRewardDate;
    }

    /**
     * @dev Returns a given node's next reward date.
     */
    function getNodeNextRewardDate(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (uint)
    {
        return IBountyV2(contractManager.getBounty()).getNextRewardTimestamp(nodeIndex);
    }

    /**
     * @dev Returns the total number of registered nodes.
     */
    function getNumberOfNodes() external view override returns (uint) {
        return nodes.length;
    }

    /**
     * @dev Returns the total number of online nodes.
     *
     * Note: Online nodes are equal to the number of active plus leaving nodes.
     */
    function getNumberOnlineNodes() external view override returns (uint) {
        return numberOfActiveNodes + numberOfLeavingNodes ;
    }

    /**
     * @dev Return active node IDs.
     */
    function getActiveNodeIds() external view override returns (uint[] memory activeNodeIds) {
        activeNodeIds = new uint[](numberOfActiveNodes);
        uint indexOfActiveNodeIds = 0;
        for (uint indexOfNodes = 0; indexOfNodes < nodes.length; indexOfNodes++) {
            if (isNodeActive(indexOfNodes)) {
                activeNodeIds[indexOfActiveNodeIds] = indexOfNodes;
                indexOfActiveNodeIds++;
            }
        }
    }

    /**
     * @dev Return a given node's current status.
     */
    function getNodeStatus(uint nodeIndex)
        external
        view
        override
        checkNodeExists(nodeIndex)
        returns (NodeStatus)
    {
        return nodes[nodeIndex].status;
    }

    /**
     * @dev Return a validator's linked nodes.
     *
     * Requirements:
     *
     * - Validator ID must exist.
     */
    function getValidatorNodeIndexes(uint validatorId) external view override returns (uint[] memory) {
        IValidatorService validatorService = IValidatorService(contractManager.getValidatorService());
        require(validatorService.validatorExists(validatorId), "Validator ID does not exist");
        return validatorToNodeIndexes[validatorId];
    }

    /**
     * @dev Returns number of nodes with available space.
     */
    function countNodesWithFreeSpace(uint8 freeSpace) external view override returns (uint count) {
        if (freeSpace == 0) {
            return _nodesAmountBySpace.sumFromPlaceToLast(1);
        }
        return _nodesAmountBySpace.sumFromPlaceToLast(freeSpace);
    }

    /**
     * @dev constructor in Permissions approach.
     */
    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);

        numberOfActiveNodes = 0;
        numberOfLeavingNodes = 0;
        numberOfLeftNodes = 0;
        _nodesAmountBySpace.create(128);
    }

    /**
     * @dev Returns the Validator ID for a given node.
     */
    function getValidatorId(uint nodeIndex)
        public
        view
        override
        checkNodeExists(nodeIndex)
        returns (uint)
    {
        return nodes[nodeIndex].validatorId;
    }

    /**
     * @dev Checks whether a node exists for a given address.
     */
    function isNodeExist(address from, uint nodeIndex)
        public
        view
        override
        checkNodeExists(nodeIndex)
        returns (bool)
    {
        return nodeIndexes[from].isNodeExist[nodeIndex];
    }

    /**
     * @dev Checks whether a node's status is Active.
     */
    function isNodeActive(uint nodeIndex)
        public
        view
        override
        checkNodeExists(nodeIndex)
        returns (bool)
    {
        return nodes[nodeIndex].status == NodeStatus.Active;
    }

    /**
     * @dev Checks whether a node's status is Leaving.
     */
    function isNodeLeaving(uint nodeIndex)
        public
        view
        override
        checkNodeExists(nodeIndex)
        returns (bool)
    {
        return nodes[nodeIndex].status == NodeStatus.Leaving;
    }

    function _removeNodeFromSpaceToNodes(uint nodeIndex, uint8 space) internal {
        uint indexInArray = spaceOfNodes[nodeIndex].indexInSpaceMap;
        uint len = spaceToNodes[space].length - 1;
        if (indexInArray < len) {
            uint shiftedIndex = spaceToNodes[space][len];
            spaceToNodes[space][indexInArray] = shiftedIndex;
            spaceOfNodes[shiftedIndex].indexInSpaceMap = indexInArray;
        }
        spaceToNodes[space].pop();
        delete spaceOfNodes[nodeIndex].indexInSpaceMap;
    }

    /**
     * @dev Moves a node to a new space mapping.
     */
    function _moveNodeToNewSpaceMap(uint nodeIndex, uint8 newSpace) private {
        if (!_invisible[nodeIndex]) {
            uint8 space = spaceOfNodes[nodeIndex].freeSpace;
            _removeNodeFromTree(space);
            _addNodeToTree(newSpace);
            _removeNodeFromSpaceToNodes(nodeIndex, space);
            _addNodeToSpaceToNodes(nodeIndex, newSpace);
        }
        spaceOfNodes[nodeIndex].freeSpace = newSpace;
    }

    /**
     * @dev Changes a node's status to Active.
     */
    function _setNodeActive(uint nodeIndex) private {
        nodes[nodeIndex].status = NodeStatus.Active;
        numberOfActiveNodes = numberOfActiveNodes + 1;
        if (_invisible[nodeIndex]) {
            _tryToMakeNodeVisible(nodeIndex);
        } else {
            uint8 space = spaceOfNodes[nodeIndex].freeSpace;
            _addNodeToSpaceToNodes(nodeIndex, space);
            _addNodeToTree(space);
        }
    }

    /**
     * @dev Changes a node's status to In_Maintenance.
     */
    function _setNodeInMaintenance(uint nodeIndex) private {
        nodes[nodeIndex].status = NodeStatus.In_Maintenance;
        numberOfActiveNodes = numberOfActiveNodes - 1;
        _makeNodeInvisible(nodeIndex);
    }

    /**
     * @dev Changes a node's status to Left.
     */
    function _setNodeLeft(uint nodeIndex) private {
        nodesIPCheck[nodes[nodeIndex].ip] = false;
        nodesNameCheck[keccak256(abi.encodePacked(nodes[nodeIndex].name))] = false;
        delete nodesNameToIndex[keccak256(abi.encodePacked(nodes[nodeIndex].name))];
        if (nodes[nodeIndex].status == NodeStatus.Active) {
            numberOfActiveNodes--;
        } else {
            numberOfLeavingNodes--;
        }
        nodes[nodeIndex].status = NodeStatus.Left;
        numberOfLeftNodes++;
        delete spaceOfNodes[nodeIndex].freeSpace;
    }

    /**
     * @dev Changes a node's status to Leaving.
     */
    function _setNodeLeaving(uint nodeIndex) private {
        nodes[nodeIndex].status = NodeStatus.Leaving;
        numberOfActiveNodes--;
        numberOfLeavingNodes++;
        _makeNodeInvisible(nodeIndex);
    }

    function _makeNodeInvisible(uint nodeIndex) private {
        if (!_invisible[nodeIndex]) {
            uint8 space = spaceOfNodes[nodeIndex].freeSpace;
            _removeNodeFromSpaceToNodes(nodeIndex, space);
            _removeNodeFromTree(space);
            _invisible[nodeIndex] = true;
        }
    }

    function _tryToMakeNodeVisible(uint nodeIndex) private {
        if (_invisible[nodeIndex] && _canBeVisible(nodeIndex)) {
            _makeNodeVisible(nodeIndex);
        }
    }

    function _makeNodeVisible(uint nodeIndex) private {
        if (_invisible[nodeIndex]) {
            uint8 space = spaceOfNodes[nodeIndex].freeSpace;
            _addNodeToSpaceToNodes(nodeIndex, space);
            _addNodeToTree(space);
            delete _invisible[nodeIndex];
        }
    }

    function _addNodeToSpaceToNodes(uint nodeIndex, uint8 space) private {
        spaceToNodes[space].push(nodeIndex);
        spaceOfNodes[nodeIndex].indexInSpaceMap = spaceToNodes[space].length - 1;
    }

    function _addNodeToTree(uint8 space) private {
        if (space > 0) {
            _nodesAmountBySpace.addToPlace(space, 1);
        }
    }

    function _removeNodeFromTree(uint8 space) private {
        if (space > 0) {
            _nodesAmountBySpace.removeFromPlace(space, 1);
        }
    }

    function _checkValidatorPositionToMaintainNode(uint validatorId, uint position) private returns (bool) {
        IDelegationController delegationController = IDelegationController(
            contractManager.getContract("DelegationController")
        );
        uint delegationsTotal = delegationController.getAndUpdateDelegatedToValidatorNow(validatorId);
        uint msr = IConstantsHolder(contractManager.getConstantsHolder()).msr();
        return (position + 1) * msr <= delegationsTotal;
    }

    function _checkNodeIndex(uint nodeIndex) private view {
        require(nodeIndex < nodes.length, "Node with such index does not exist");
    }

    function _checkNodeOrNodeManager(uint nodeIndex, address sender) private view {
        IValidatorService validatorService = IValidatorService(contractManager.getValidatorService());

        require(
            isNodeExist(sender, nodeIndex) ||
            hasRole(NODE_MANAGER_ROLE, msg.sender) ||
            getValidatorId(nodeIndex) == validatorService.getValidatorId(sender),
            "Sender is not permitted to call this function"
        );
    }

    function _canBeVisible(uint nodeIndex) private view returns (bool) {
        return !incompliant[nodeIndex] && nodes[nodeIndex].status == NodeStatus.Active;
    }

    /**
     * @dev Returns the index of a given node within the validator's node index.
     */
    function _findNode(uint[] memory validatorNodeIndexes, uint nodeIndex) private pure returns (uint) {
        uint i;
        for (i = 0; i < validatorNodeIndexes.length; i++) {
            if (validatorNodeIndexes[i] == nodeIndex) {
                return i;
            }
        }
        return validatorNodeIndexes.length;
    }

    function _publicKeyToAddress(bytes32[2] memory pubKey) private pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(pubKey[0], pubKey[1]));
        bytes20 addr;
        for (uint8 i = 12; i < 32; i++) {
            addr |= bytes20(hash[i] & 0xFF) >> ((i - 12) * 8);
        }
        return address(addr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    INodes.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

import "./utils/IRandom.sol";

interface INodes {
    // All Nodes states
    enum NodeStatus {Active, Leaving, Left, In_Maintenance}

    struct Node {
        string name;
        bytes4 ip;
        bytes4 publicIP;
        uint16 port;
        bytes32[2] publicKey;
        uint startBlock;
        uint lastRewardDate;
        uint finishTime;
        NodeStatus status;
        uint validatorId;
    }

    // struct to note which Nodes and which number of Nodes owned by user
    struct CreatedNodes {
        mapping (uint => bool) isNodeExist;
        uint numberOfNodes;
    }

    struct SpaceManaging {
        uint8 freeSpace;
        uint indexInSpaceMap;
    }

    struct NodeCreationParams {
        string name;
        bytes4 ip;
        bytes4 publicIp;
        uint16 port;
        bytes32[2] publicKey;
        uint16 nonce;
        string domainName;
    }
    
    /**
     * @dev Emitted when a node is created.
     */
    event NodeCreated(
        uint nodeIndex,
        address owner,
        string name,
        bytes4 ip,
        bytes4 publicIP,
        uint16 port,
        uint16 nonce,
        string domainName
    );

    /**
     * @dev Emitted when a node completes a network exit.
     */
    event ExitCompleted(
        uint nodeIndex
    );

    /**
     * @dev Emitted when a node begins to exit from the network.
     */
    event ExitInitialized(
        uint nodeIndex,
        uint startLeavingPeriod
    );

    /**
     * @dev Emitted when a node set to in compliant or compliant.
     */
    event IncompliantNode(
        uint indexed nodeIndex,
        bool status
    );

    /**
     * @dev Emitted when a node set to in maintenance or from in maintenance.
     */
    event MaintenanceNode(
        uint indexed nodeIndex,
        bool status
    );

    /**
     * @dev Emitted when a node status changed.
     */
    event IPChanged(
        uint indexed nodeIndex,
        bytes4 previousIP,
        bytes4 newIP
    );
    
    function removeSpaceFromNode(uint nodeIndex, uint8 space) external returns (bool);
    function addSpaceToNode(uint nodeIndex, uint8 space) external;
    function changeNodeLastRewardDate(uint nodeIndex) external;
    function changeNodeFinishTime(uint nodeIndex, uint time) external;
    function createNode(address from, NodeCreationParams calldata params) external;
    function initExit(uint nodeIndex) external;
    function completeExit(uint nodeIndex) external returns (bool);
    function deleteNodeForValidator(uint validatorId, uint nodeIndex) external;
    function checkPossibilityCreatingNode(address nodeAddress) external;
    function checkPossibilityToMaintainNode(uint validatorId, uint nodeIndex) external returns (bool);
    function setNodeInMaintenance(uint nodeIndex) external;
    function removeNodeFromInMaintenance(uint nodeIndex) external;
    function setNodeIncompliant(uint nodeIndex) external;
    function setNodeCompliant(uint nodeIndex) external;
    function setDomainName(uint nodeIndex, string memory domainName) external;
    function makeNodeVisible(uint nodeIndex) external;
    function makeNodeInvisible(uint nodeIndex) external;
    function changeIP(uint nodeIndex, bytes4 newIP, bytes4 newPublicIP) external;
    function numberOfActiveNodes() external view returns (uint);
    function incompliant(uint nodeIndex) external view returns (bool);
    function getRandomNodeWithFreeSpace(
        uint8 freeSpace,
        IRandom.RandomGenerator memory randomGenerator
    )
        external
        view
        returns (uint);
    function isTimeForReward(uint nodeIndex) external view returns (bool);
    function getNodeIP(uint nodeIndex) external view returns (bytes4);
    function getNodeDomainName(uint nodeIndex) external view returns (string memory);
    function getNodePort(uint nodeIndex) external view returns (uint16);
    function getNodePublicKey(uint nodeIndex) external view returns (bytes32[2] memory);
    function getNodeAddress(uint nodeIndex) external view returns (address);
    function getNodeFinishTime(uint nodeIndex) external view returns (uint);
    function isNodeLeft(uint nodeIndex) external view returns (bool);
    function isNodeInMaintenance(uint nodeIndex) external view returns (bool);
    function getNodeLastRewardDate(uint nodeIndex) external view returns (uint);
    function getNodeNextRewardDate(uint nodeIndex) external view returns (uint);
    function getNumberOfNodes() external view returns (uint);
    function getNumberOnlineNodes() external view returns (uint);
    function getActiveNodeIds() external view returns (uint[] memory activeNodeIds);
    function getNodeStatus(uint nodeIndex) external view returns (NodeStatus);
    function getValidatorNodeIndexes(uint validatorId) external view returns (uint[] memory);
    function countNodesWithFreeSpace(uint8 freeSpace) external view returns (uint count);
    function getValidatorId(uint nodeIndex) external view returns (uint);
    function isNodeExist(address from, uint nodeIndex) external view returns (bool);
    function isNodeActive(uint nodeIndex) external view returns (bool);
    function isNodeLeaving(uint nodeIndex) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IDelegationController.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IDelegationController {
    enum State {
        PROPOSED,
        ACCEPTED,
        CANCELED,
        REJECTED,
        DELEGATED,
        UNDELEGATION_REQUESTED,
        COMPLETED
    }

    struct Delegation {
        address holder; // address of token owner
        uint validatorId;
        uint amount;
        uint delegationPeriod;
        uint created; // time of delegation creation
        uint started; // month when a delegation becomes active
        uint finished; // first month after a delegation ends
        string info;
    }

    /**
     * @dev Emitted when validator was confiscated.
     */
    event Confiscated(
        uint indexed validatorId,
        uint amount
    );

    /**
     * @dev Emitted when validator was confiscated.
     */
    event SlashesProcessed(
        address indexed holder,
        uint limit
    );

    /**
     * @dev Emitted when a delegation is proposed to a validator.
     */
    event DelegationProposed(
        uint delegationId
    );

    /**
     * @dev Emitted when a delegation is accepted by a validator.
     */
    event DelegationAccepted(
        uint delegationId
    );

    /**
     * @dev Emitted when a delegation is cancelled by the delegator.
     */
    event DelegationRequestCanceledByUser(
        uint delegationId
    );

    /**
     * @dev Emitted when a delegation is requested to undelegate.
     */
    event UndelegationRequested(
        uint delegationId
    );
    
    function getAndUpdateDelegatedToValidatorNow(uint validatorId) external returns (uint);
    function getAndUpdateDelegatedAmount(address holder) external returns (uint);
    function getAndUpdateEffectiveDelegatedByHolderToValidator(address holder, uint validatorId, uint month)
        external
        returns (uint effectiveDelegated);
    function delegate(
        uint validatorId,
        uint amount,
        uint delegationPeriod,
        string calldata info
    )
        external;
    function cancelPendingDelegation(uint delegationId) external;
    function acceptPendingDelegation(uint delegationId) external;
    function requestUndelegation(uint delegationId) external;
    function confiscate(uint validatorId, uint amount) external;
    function getAndUpdateEffectiveDelegatedToValidator(uint validatorId, uint month) external returns (uint);
    function getAndUpdateDelegatedByHolderToValidatorNow(address holder, uint validatorId) external returns (uint);
    function processSlashes(address holder, uint limit) external;
    function processAllSlashes(address holder) external;
    function getEffectiveDelegatedValuesByValidator(uint validatorId) external view returns (uint[] memory);
    function getEffectiveDelegatedToValidator(uint validatorId, uint month) external view returns (uint);
    function getDelegatedToValidator(uint validatorId, uint month) external view returns (uint);
    function getDelegation(uint delegationId) external view returns (Delegation memory);
    function getFirstDelegationMonth(address holder, uint validatorId) external view returns(uint);
    function getDelegationsByValidatorLength(uint validatorId) external view returns (uint);
    function getDelegationsByHolderLength(address holder) external view returns (uint);
    function getState(uint delegationId) external view returns (State state);
    function getLockedInPendingDelegations(address holder) external view returns (uint);
    function hasUnprocessedSlashes(address holder) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IValidatorService.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IValidatorService {
    struct Validator {
        string name;
        address validatorAddress;
        address requestedAddress;
        string description;
        uint feeRate;
        uint registrationTime;
        uint minimumDelegationAmount;
        bool acceptNewRequests;
    }
    
    /**
     * @dev Emitted when a validator registers.
     */
    event ValidatorRegistered(
        uint validatorId
    );

    /**
     * @dev Emitted when a validator address changes.
     */
    event ValidatorAddressChanged(
        uint validatorId,
        address newAddress
    );

    /**
     * @dev Emitted when a validator is enabled.
     */
    event ValidatorWasEnabled(
        uint validatorId
    );

    /**
     * @dev Emitted when a validator is disabled.
     */
    event ValidatorWasDisabled(
        uint validatorId
    );

    /**
     * @dev Emitted when a node address is linked to a validator.
     */
    event NodeAddressWasAdded(
        uint validatorId,
        address nodeAddress
    );

    /**
     * @dev Emitted when a node address is unlinked from a validator.
     */
    event NodeAddressWasRemoved(
        uint validatorId,
        address nodeAddress
    );

    /**
     * @dev Emitted when whitelist disabled.
     */
    event WhitelistDisabled(bool status);

    /**
     * @dev Emitted when validator requested new address.
     */
    event RequestNewAddress(uint indexed validatorId, address previousAddress, address newAddress);

    /**
     * @dev Emitted when validator set new minimum delegation amount.
     */
    event SetMinimumDelegationAmount(uint indexed validatorId, uint previousMDA, uint newMDA);

    /**
     * @dev Emitted when validator set new name.
     */
    event SetValidatorName(uint indexed validatorId, string previousName, string newName);

    /**
     * @dev Emitted when validator set new description.
     */
    event SetValidatorDescription(uint indexed validatorId, string previousDescription, string newDescription);

    /**
     * @dev Emitted when validator start or stop accepting new delegation requests.
     */
    event AcceptingNewRequests(uint indexed validatorId, bool status);
    
    function registerValidator(
        string calldata name,
        string calldata description,
        uint feeRate,
        uint minimumDelegationAmount
    )
        external
        returns (uint validatorId);
    function enableValidator(uint validatorId) external;
    function disableValidator(uint validatorId) external;
    function disableWhitelist() external;
    function requestForNewAddress(address newValidatorAddress) external;
    function confirmNewAddress(uint validatorId) external;
    function linkNodeAddress(address nodeAddress, bytes calldata sig) external;
    function unlinkNodeAddress(address nodeAddress) external;
    function setValidatorMDA(uint minimumDelegationAmount) external;
    function setValidatorName(string calldata newName) external;
    function setValidatorDescription(string calldata newDescription) external;
    function startAcceptingNewRequests() external;
    function stopAcceptingNewRequests() external;
    function removeNodeAddress(uint validatorId, address nodeAddress) external;
    function getAndUpdateBondAmount(uint validatorId) external returns (uint);
    function getMyNodesAddresses() external view returns (address[] memory);
    function getTrustedValidators() external view returns (uint[] memory);
    function checkValidatorAddressToId(address validatorAddress, uint validatorId)
        external
        view
        returns (bool);
    function getValidatorIdByNodeAddress(address nodeAddress) external view returns (uint validatorId);
    function checkValidatorCanReceiveDelegation(uint validatorId, uint amount) external view;
    function getNodeAddresses(uint validatorId) external view returns (address[] memory);
    function validatorExists(uint validatorId) external view returns (bool);
    function validatorAddressExists(address validatorAddress) external view returns (bool);
    function checkIfValidatorAddressExists(address validatorAddress) external view;
    function getValidator(uint validatorId) external view returns (Validator memory);
    function getValidatorId(address validatorAddress) external view returns (uint);
    function isAcceptingNewRequests(uint validatorId) external view returns (bool);
    function isAuthorizedValidator(uint validatorId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IBountyV2.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IBountyV2 {

    /**
     * @dev Emitted when bounty reduction is turned on or turned off.
     */
    event BountyReduction(bool status);
    /**
     * @dev Emitted when a node creation window was changed.
     */
    event NodeCreationWindowWasChanged(
        uint oldValue,
        uint newValue
    );

    function calculateBounty(uint nodeIndex) external returns (uint);
    function enableBountyReduction() external;
    function disableBountyReduction() external;
    function setNodeCreationWindowSeconds(uint window) external;
    function handleDelegationAdd(uint amount, uint month) external;
    function handleDelegationRemoving(uint amount, uint month) external;
    function estimateBounty(uint nodeIndex) external view returns (uint);
    function getNextRewardTimestamp(uint nodeIndex) external view returns (uint);
    function getEffectiveDelegatedSum() external view returns (uint[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    Permissions.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";
import "@skalenetwork/skale-manager-interfaces/IPermissions.sol";

import "./thirdparty/openzeppelin/AccessControlUpgradeableLegacy.sol";


/**
 * @title Permissions
 * @dev Contract is connected module for Upgradeable approach, knows ContractManager
 */
contract Permissions is AccessControlUpgradeableLegacy, IPermissions {
    using AddressUpgradeable for address;

    IContractManager public contractManager;

    /**
     * @dev Modifier to make a function callable only when caller is the Owner.
     *
     * Requirements:
     *
     * - The caller must be the owner.
     */
    modifier onlyOwner() {
        require(_isOwner(), "Caller is not the owner");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is an Admin.
     *
     * Requirements:
     *
     * - The caller must be an admin.
     */
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is the Owner
     * or `contractName` contract.
     *
     * Requirements:
     *
     * - The caller must be the owner or `contractName`.
     */
    modifier allow(string memory contractName) {
        require(
            contractManager.getContract(contractName) == msg.sender || _isOwner(),
            "Message sender is invalid");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is the Owner
     * or `contractName1` or `contractName2` contract.
     *
     * Requirements:
     *
     * - The caller must be the owner, `contractName1`, or `contractName2`.
     */
    modifier allowTwo(string memory contractName1, string memory contractName2) {
        require(
            contractManager.getContract(contractName1) == msg.sender ||
            contractManager.getContract(contractName2) == msg.sender ||
            _isOwner(),
            "Message sender is invalid");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is the Owner
     * or `contractName1`, `contractName2`, or `contractName3` contract.
     *
     * Requirements:
     *
     * - The caller must be the owner, `contractName1`, `contractName2`, or
     * `contractName3`.
     */
    modifier allowThree(string memory contractName1, string memory contractName2, string memory contractName3) {
        require(
            contractManager.getContract(contractName1) == msg.sender ||
            contractManager.getContract(contractName2) == msg.sender ||
            contractManager.getContract(contractName3) == msg.sender ||
            _isOwner(),
            "Message sender is invalid");
        _;
    }

    function initialize(address contractManagerAddress) public virtual override initializer {
        AccessControlUpgradeableLegacy.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setContractManager(contractManagerAddress);
    }

    function _isOwner() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _isAdmin(address account) internal view returns (bool) {
        address skaleManagerAddress = contractManager.contracts(keccak256(abi.encodePacked("SkaleManager")));
        if (skaleManagerAddress != address(0)) {
            AccessControlUpgradeableLegacy skaleManager = AccessControlUpgradeableLegacy(skaleManagerAddress);
            return skaleManager.hasRole(keccak256("ADMIN_ROLE"), account) || _isOwner();
        } else {
            return _isOwner();
        }
    }

    function _setContractManager(address contractManagerAddress) private {
        require(contractManagerAddress != address(0), "ContractManager address is not set");
        require(contractManagerAddress.isContract(), "Address is not contract");
        contractManager = IContractManager(contractManagerAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ConstantsHolder.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@skalenetwork/skale-manager-interfaces/IConstantsHolder.sol";

import "./Permissions.sol";


/**
 * @title ConstantsHolder
 * @dev Contract contains constants and common variables for the SKALE Network.
 */
contract ConstantsHolder is Permissions, IConstantsHolder {

    // initial price for creating Node (100 SKL)
    uint public constant NODE_DEPOSIT = 100 * 1e18;

    uint8 public constant TOTAL_SPACE_ON_NODE = 128;

    // part of Node for Small Skale-chain (1/128 of Node)
    uint8 public constant SMALL_DIVISOR = 128;

    // part of Node for Medium Skale-chain (1/32 of Node)
    uint8 public constant MEDIUM_DIVISOR = 32;

    // part of Node for Large Skale-chain (full Node)
    uint8 public constant LARGE_DIVISOR = 1;

    // part of Node for Medium Test Skale-chain (1/4 of Node)
    uint8 public constant MEDIUM_TEST_DIVISOR = 4;

    // typically number of Nodes for Skale-chain (16 Nodes)
    uint public constant NUMBER_OF_NODES_FOR_SCHAIN = 16;

    // number of Nodes for Test Skale-chain (2 Nodes)
    uint public constant NUMBER_OF_NODES_FOR_TEST_SCHAIN = 2;

    // number of Nodes for Test Skale-chain (4 Nodes)
    uint public constant NUMBER_OF_NODES_FOR_MEDIUM_TEST_SCHAIN = 4;

    // number of seconds in one year
    uint32 public constant SECONDS_TO_YEAR = 31622400;

    // initial number of monitors
    uint public constant NUMBER_OF_MONITORS = 24;

    uint public constant OPTIMAL_LOAD_PERCENTAGE = 80;

    uint public constant ADJUSTMENT_SPEED = 1000;

    uint public constant COOLDOWN_TIME = 60;

    uint public constant MIN_PRICE = 10**6;

    uint public constant MSR_REDUCING_COEFFICIENT = 2;

    uint public constant DOWNTIME_THRESHOLD_PART = 30;

    uint public constant BOUNTY_LOCKUP_MONTHS = 2;

    uint public constant ALRIGHT_DELTA = 134161;
    uint public constant BROADCAST_DELTA = 177490;
    uint public constant COMPLAINT_BAD_DATA_DELTA = 80995;
    uint public constant PRE_RESPONSE_DELTA = 100061;
    uint public constant COMPLAINT_DELTA = 106611;
    uint public constant RESPONSE_DELTA = 48132;

    // MSR - Minimum staking requirement
    uint public msr;

    // Reward period - 30 days (each 30 days Node would be granted for bounty)
    uint32 public rewardPeriod;

    // Allowable latency - 150000 ms by default
    uint32 public allowableLatency;

    /**
     * Delta period - 1 hour (1 hour before Reward period became Monitors need
     * to send Verdicts and 1 hour after Reward period became Node need to come
     * and get Bounty)
     */
    uint32 public deltaPeriod;

    /**
     * Check time - 2 minutes (every 2 minutes monitors should check metrics
     * from checked nodes)
     */
    uint public checkTime;

    //Need to add minimal allowed parameters for verdicts

    uint public launchTimestamp;

    uint public rotationDelay;

    uint public proofOfUseLockUpPeriodDays;

    uint public proofOfUseDelegationPercentage;

    uint public limitValidatorsPerDelegator;

    uint256 public firstDelegationsMonth; // deprecated

    // date when schains will be allowed for creation
    uint public schainCreationTimeStamp;

    uint public minimalSchainLifetime;

    uint public complaintTimeLimit;

    uint public minNodeBalance;

    bytes32 public constant CONSTANTS_HOLDER_MANAGER_ROLE = keccak256("CONSTANTS_HOLDER_MANAGER_ROLE");

    modifier onlyConstantsHolderManager() {
        require(hasRole(CONSTANTS_HOLDER_MANAGER_ROLE, msg.sender), "CONSTANTS_HOLDER_MANAGER_ROLE is required");
        _;
    }

    /**
     * @dev Allows the Owner to set new reward and delta periods
     * This function is only for tests.
     */
    function setPeriods(uint32 newRewardPeriod, uint32 newDeltaPeriod) external override onlyConstantsHolderManager {
        require(
            newRewardPeriod >= newDeltaPeriod && newRewardPeriod - newDeltaPeriod >= checkTime,
            "Incorrect Periods"
        );
        emit ConstantUpdated(
            keccak256(abi.encodePacked("RewardPeriod")),
            uint(rewardPeriod),
            uint(newRewardPeriod)
        );
        rewardPeriod = newRewardPeriod;
        emit ConstantUpdated(
            keccak256(abi.encodePacked("DeltaPeriod")),
            uint(deltaPeriod),
            uint(newDeltaPeriod)
        );
        deltaPeriod = newDeltaPeriod;
    }

    /**
     * @dev Allows the Owner to set the new check time.
     * This function is only for tests.
     */
    function setCheckTime(uint newCheckTime) external override onlyConstantsHolderManager {
        require(rewardPeriod - deltaPeriod >= checkTime, "Incorrect check time");
        emit ConstantUpdated(
            keccak256(abi.encodePacked("CheckTime")),
            uint(checkTime),
            uint(newCheckTime)
        );
        checkTime = newCheckTime;
    }

    /**
     * @dev Allows the Owner to set the allowable latency in milliseconds.
     * This function is only for testing purposes.
     */
    function setLatency(uint32 newAllowableLatency) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("AllowableLatency")),
            uint(allowableLatency),
            uint(newAllowableLatency)
        );
        allowableLatency = newAllowableLatency;
    }

    /**
     * @dev Allows the Owner to set the minimum stake requirement.
     */
    function setMSR(uint newMSR) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("MSR")),
            uint(msr),
            uint(newMSR)
        );
        msr = newMSR;
    }

    /**
     * @dev Allows the Owner to set the launch timestamp.
     */
    function setLaunchTimestamp(uint timestamp) external override onlyConstantsHolderManager {
        require(
            block.timestamp < launchTimestamp,
            "Cannot set network launch timestamp because network is already launched"
        );
        emit ConstantUpdated(
            keccak256(abi.encodePacked("LaunchTimestamp")),
            uint(launchTimestamp),
            uint(timestamp)
        );
        launchTimestamp = timestamp;
    }

    /**
     * @dev Allows the Owner to set the node rotation delay.
     */
    function setRotationDelay(uint newDelay) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("RotationDelay")),
            uint(rotationDelay),
            uint(newDelay)
        );
        rotationDelay = newDelay;
    }

    /**
     * @dev Allows the Owner to set the proof-of-use lockup period.
     */
    function setProofOfUseLockUpPeriod(uint periodDays) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("ProofOfUseLockUpPeriodDays")),
            uint(proofOfUseLockUpPeriodDays),
            uint(periodDays)
        );
        proofOfUseLockUpPeriodDays = periodDays;
    }

    /**
     * @dev Allows the Owner to set the proof-of-use delegation percentage
     * requirement.
     */
    function setProofOfUseDelegationPercentage(uint percentage) external override onlyConstantsHolderManager {
        require(percentage <= 100, "Percentage value is incorrect");
        emit ConstantUpdated(
            keccak256(abi.encodePacked("ProofOfUseDelegationPercentage")),
            uint(proofOfUseDelegationPercentage),
            uint(percentage)
        );
        proofOfUseDelegationPercentage = percentage;
    }

    /**
     * @dev Allows the Owner to set the maximum number of validators that a
     * single delegator can delegate to.
     */
    function setLimitValidatorsPerDelegator(uint newLimit) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("LimitValidatorsPerDelegator")),
            uint(limitValidatorsPerDelegator),
            uint(newLimit)
        );
        limitValidatorsPerDelegator = newLimit;
    }

    function setSchainCreationTimeStamp(uint timestamp) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("SchainCreationTimeStamp")),
            uint(schainCreationTimeStamp),
            uint(timestamp)
        );
        schainCreationTimeStamp = timestamp;
    }

    function setMinimalSchainLifetime(uint lifetime) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("MinimalSchainLifetime")),
            uint(minimalSchainLifetime),
            uint(lifetime)
        );
        minimalSchainLifetime = lifetime;
    }

    function setComplaintTimeLimit(uint timeLimit) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("ComplaintTimeLimit")),
            uint(complaintTimeLimit),
            uint(timeLimit)
        );
        complaintTimeLimit = timeLimit;
    }

    function setMinNodeBalance(uint newMinNodeBalance) external override onlyConstantsHolderManager {
        emit ConstantUpdated(
            keccak256(abi.encodePacked("MinNodeBalance")),
            uint(minNodeBalance),
            uint(newMinNodeBalance)
        );
        minNodeBalance = newMinNodeBalance;
    }

    function reinitialize() external override reinitializer(2) {
        minNodeBalance = 1.5 ether;
    }

    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);

        msr = 0;
        rewardPeriod = 2592000;
        allowableLatency = 150000;
        deltaPeriod = 3600;
        checkTime = 300;
        launchTimestamp = type(uint).max;
        rotationDelay = 12 hours;
        proofOfUseLockUpPeriodDays = 90;
        proofOfUseDelegationPercentage = 50;
        limitValidatorsPerDelegator = 20;
        firstDelegationsMonth = 0;
        complaintTimeLimit = 1800;
        minNodeBalance = 1.5 ether;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    SegmentTree.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@skalenetwork/skale-manager-interfaces/utils/IRandom.sol";

/**
 * @title Random
 * @dev The library for generating of pseudo random numbers
 */
library Random {

    /**
     * @dev Create an instance of RandomGenerator
     */
    function create(uint seed) internal pure returns (IRandom.RandomGenerator memory) {
        return IRandom.RandomGenerator({seed: seed});
    }

    function createFromEntropy(bytes memory entropy) internal pure returns (IRandom.RandomGenerator memory) {
        return create(uint(keccak256(entropy)));
    }

    /**
     * @dev Generates random value
     */
    function random(IRandom.RandomGenerator memory self) internal pure returns (uint) {
        self.seed = uint(sha256(abi.encodePacked(self.seed)));
        return self.seed;
    }

    /**
     * @dev Generates random value in range [0, max)
     */
    function random(IRandom.RandomGenerator memory self, uint max) internal pure returns (uint) {
        assert(max > 0);
        uint maxRand = type(uint).max - type(uint).max % max;
        if (type(uint).max - maxRand == max - 1) {
            return random(self) % max;
        } else {
            uint rand = random(self);
            while (rand >= maxRand) {
                rand = random(self);
            }
            return rand % max;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    SegmentTree.sol - SKALE Manager
    Copyright (C) 2021-Present SKALE Labs
    @author Artem Payvin
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "./Random.sol";

/**
 * @title SegmentTree
 * @dev This library implements segment tree data structure
 *
 * Segment tree allows effectively calculate sum of elements in sub arrays
 * by storing some amount of additional data.
 *
 * IMPORTANT: Provided implementation assumes that arrays is indexed from 1 to n.
 * Size of initial array always must be power of 2
 *
 * Example:
 *
 * Array:
 * +---+---+---+---+---+---+---+---+
 * | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
 * +---+---+---+---+---+---+---+---+
 *
 * Segment tree structure:
 * +-------------------------------+
 * |               36              |
 * +---------------+---------------+
 * |       10      |       26      |
 * +-------+-------+-------+-------+
 * |   3   |   7   |   11  |   15  |
 * +---+---+---+---+---+---+---+---+
 * | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
 * +---+---+---+---+---+---+---+---+
 *
 * How the segment tree is stored in an array:
 * +----+----+----+---+---+----+----+---+---+---+---+---+---+---+---+
 * | 36 | 10 | 26 | 3 | 7 | 11 | 15 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
 * +----+----+----+---+---+----+----+---+---+---+---+---+---+---+---+
 */
library SegmentTree {
    using Random for IRandom.RandomGenerator;

    struct Tree {
        uint[] tree;
    }

    /**
     * @dev Allocates storage for segment tree of `size` elements
     *
     * Requirements:
     *
     * - `size` must be greater than 0
     * - `size` must be power of 2
     */
    function create(Tree storage segmentTree, uint size) external {
        require(size > 0, "Size can't be 0");
        require(size & size - 1 == 0, "Size is not power of 2");
        segmentTree.tree = new uint[](size * 2 - 1);
    }

    /**
     * @dev Adds `delta` to element of segment tree at `place`
     *
     * Requirements:
     *
     * - `place` must be in range [1, size]
     */
    function addToPlace(Tree storage self, uint place, uint delta) external {
        require(_correctPlace(self, place), "Incorrect place");
        uint leftBound = 1;
        uint rightBound = getSize(self);
        uint step = 1;
        self.tree[0] = self.tree[0] + delta;
        while(leftBound < rightBound) {
            uint middle = (leftBound + rightBound) / 2;
            if (place > middle) {
                leftBound = middle + 1;
                step = step + step + 1;
            } else {
                rightBound = middle;
                step = step + step;
            }
            self.tree[step - 1] = self.tree[step - 1] + delta;
        }
    }

    /**
     * @dev Subtracts `delta` from element of segment tree at `place`
     *
     * Requirements:
     *
     * - `place` must be in range [1, size]
     * - initial value of target element must be not less than `delta`
     */
    function removeFromPlace(Tree storage self, uint place, uint delta) external {
        require(_correctPlace(self, place), "Incorrect place");
        uint leftBound = 1;
        uint rightBound = getSize(self);
        uint step = 1;
        self.tree[0] = self.tree[0] - delta;
        while(leftBound < rightBound) {
            uint middle = (leftBound + rightBound) / 2;
            if (place > middle) {
                leftBound = middle + 1;
                step = step + step + 1;
            } else {
                rightBound = middle;
                step = step + step;
            }
            self.tree[step - 1] = self.tree[step - 1] - delta;
        }
    }

    /**
     * @dev Adds `delta` to element of segment tree at `toPlace`
     * and subtracts `delta` from element at `fromPlace`
     *
     * Requirements:
     *
     * - `fromPlace` must be in range [1, size]
     * - `toPlace` must be in range [1, size]
     * - initial value of element at `fromPlace` must be not less than `delta`
     */
    function moveFromPlaceToPlace(
        Tree storage self,
        uint fromPlace,
        uint toPlace,
        uint delta
    )
        external
    {
        require(_correctPlace(self, fromPlace) && _correctPlace(self, toPlace), "Incorrect place");
        uint leftBound = 1;
        uint rightBound = getSize(self);
        uint step = 1;
        uint middle = (leftBound + rightBound) / 2;
        uint fromPlaceMove = fromPlace > toPlace ? toPlace : fromPlace;
        uint toPlaceMove = fromPlace > toPlace ? fromPlace : toPlace;
        while (toPlaceMove <= middle || middle < fromPlaceMove) {
            if (middle < fromPlaceMove) {
                leftBound = middle + 1;
                step = step + step + 1;
            } else {
                rightBound = middle;
                step = step + step;
            }
            middle = (leftBound + rightBound) / 2;
        }

        uint leftBoundMove = leftBound;
        uint rightBoundMove = rightBound;
        uint stepMove = step;
        while(leftBoundMove < rightBoundMove && leftBound < rightBound) {
            uint middleMove = (leftBoundMove + rightBoundMove) / 2;
            if (fromPlace > middleMove) {
                leftBoundMove = middleMove + 1;
                stepMove = stepMove + stepMove + 1;
            } else {
                rightBoundMove = middleMove;
                stepMove = stepMove + stepMove;
            }
            self.tree[stepMove - 1] = self.tree[stepMove - 1] - delta;
            middle = (leftBound + rightBound) / 2;
            if (toPlace > middle) {
                leftBound = middle + 1;
                step = step + step + 1;
            } else {
                rightBound = middle;
                step = step + step;
            }
            self.tree[step - 1] = self.tree[step - 1] + delta;
        }
    }

    /**
     * @dev Returns random position in range [`place`, size]
     * with probability proportional to value stored at this position.
     * If all element in range are 0 returns 0
     *
     * Requirements:
     *
     * - `place` must be in range [1, size]
     */
    function getRandomNonZeroElementFromPlaceToLast(
        Tree storage self,
        uint place,
        IRandom.RandomGenerator memory randomGenerator
    )
        external
        view
        returns (uint)
    {
        require(_correctPlace(self, place), "Incorrect place");

        uint vertex = 1;
        uint leftBound = 0;
        uint rightBound = getSize(self);
        uint currentFrom = place - 1;
        uint currentSum = sumFromPlaceToLast(self, place);
        if (currentSum == 0) {
            return 0;
        }
        while(leftBound + 1 < rightBound) {
            if (_middle(leftBound, rightBound) <= currentFrom) {
                vertex = _right(vertex);
                leftBound = _middle(leftBound, rightBound);
            } else {
                uint rightSum = self.tree[_right(vertex) - 1];
                uint leftSum = currentSum - rightSum;
                if (Random.random(randomGenerator, currentSum) < leftSum) {
                    // go left
                    vertex = _left(vertex);
                    rightBound = _middle(leftBound, rightBound);
                    currentSum = leftSum;
                } else {
                    // go right
                    vertex = _right(vertex);
                    leftBound = _middle(leftBound, rightBound);
                    currentFrom = leftBound;
                    currentSum = rightSum;
                }
            }
        }
        return leftBound + 1;
    }

    /**
     * @dev Returns sum of elements in range [`place`, size]
     *
     * Requirements:
     *
     * - `place` must be in range [1, size]
     */
    function sumFromPlaceToLast(Tree storage self, uint place) public view returns (uint sum) {
        require(_correctPlace(self, place), "Incorrect place");
        if (place == 1) {
            return self.tree[0];
        }
        uint leftBound = 1;
        uint rightBound = getSize(self);
        uint step = 1;
        while(leftBound < rightBound) {
            uint middle = (leftBound + rightBound) / 2;
            if (place > middle) {
                leftBound = middle + 1;
                step = step + step + 1;
            } else {
                rightBound = middle;
                step = step + step;
                sum = sum + self.tree[step];
            }
        }
        sum = sum + self.tree[step - 1];
    }

    /**
     * @dev Returns amount of elements in segment tree
     */
    function getSize(Tree storage segmentTree) internal view returns (uint) {
        if (segmentTree.tree.length > 0) {
            return segmentTree.tree.length / 2 + 1;
        } else {
            return 0;
        }
    }

    /**
     * @dev Checks if `place` is valid position in segment tree
     */
    function _correctPlace(Tree storage self, uint place) private view returns (bool) {
        return place >= 1 && place <= getSize(self);
    }

    /**
     * @dev Calculates index of left child of the vertex
     */
    function _left(uint vertex) private pure returns (uint) {
        return vertex * 2;
    }

    /**
     * @dev Calculates index of right child of the vertex
     */
    function _right(uint vertex) private pure returns (uint) {
        return vertex * 2 + 1;
    }

    /**
     * @dev Calculates arithmetical mean of 2 numbers
     */
    function _middle(uint left, uint right) private pure returns (uint) {
        return (left + right) / 2;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    NodeRotation.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/ISkaleDKG.sol";
import "@skalenetwork/skale-manager-interfaces/INodeRotation.sol";
import "@skalenetwork/skale-manager-interfaces/IConstantsHolder.sol";
import "@skalenetwork/skale-manager-interfaces/INodes.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";

import "./utils/Random.sol";
import "./Permissions.sol";


/**
 * @title NodeRotation
 * @dev This contract handles all node rotation functionality.
 */
contract NodeRotation is Permissions, INodeRotation {
    using Random for IRandom.RandomGenerator;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * nodeIndex - index of Node which is in process of rotation (left from schain)
     * newNodeIndex - index of Node which is rotated(added to schain)
     * freezeUntil - time till which Node should be turned on
     * rotationCounter - how many _rotations were on this schain
     * previousNodes - queue of nodeIndex -> previous nodeIndexes
     * newNodeIndexes - set of all newNodeIndexes for this schain
     */
    struct RotationWithPreviousNodes {
        uint nodeIndex;
        uint newNodeIndex;
        uint freezeUntil;
        uint rotationCounter;
        //    schainHash =>        nodeIndex => nodeIndex
        mapping (uint256 => uint256) previousNodes;
        EnumerableSetUpgradeable.UintSet newNodeIndexes;
        mapping (uint256 => uint256) indexInLeavingHistory;
    }

    mapping (bytes32 => RotationWithPreviousNodes) private _rotations;

    mapping (uint => INodeRotation.LeavingHistory[]) public leavingHistory;

    mapping (bytes32 => bool) public waitForNewNode;

    bytes32 public constant DEBUGGER_ROLE = keccak256("DEBUGGER_ROLE");

    /**
     * @dev Emitted when rotation delay skipped.
     */
    event RotationDelaySkipped(bytes32 indexed schainHash);

    modifier onlyDebugger() {
        require(hasRole(DEBUGGER_ROLE, msg.sender), "DEBUGGER_ROLE is required");
        _;
    }

    /**
     * @dev Allows SkaleManager to remove, find new node, and rotate node from
     * schain.
     *
     * Requirements:
     *
     * - A free node must exist.
     */
    function exitFromSchain(uint nodeIndex) external override allow("SkaleManager") returns (bool, bool) {
        ISchainsInternal schainsInternal = ISchainsInternal(contractManager.getContract("SchainsInternal"));
        bytes32 schainHash = schainsInternal.getActiveSchain(nodeIndex);
        if (schainHash == bytes32(0)) {
            return (true, false);
        }
        _checkBeforeRotation(schainHash, nodeIndex);
        _startRotation(schainHash, nodeIndex);
        rotateNode(nodeIndex, schainHash, true, false);
        return (schainsInternal.getActiveSchain(nodeIndex) == bytes32(0) ? true : false, true);
    }

    /**
     * @dev Allows Nodes contract to freeze all schains on a given node.
     */
    function freezeSchains(uint nodeIndex) external override allow("Nodes") {
        bytes32[] memory schains = ISchainsInternal(
            contractManager.getContract("SchainsInternal")
        ).getActiveSchains(nodeIndex);
        for (uint i = 0; i < schains.length; i++) {
            _checkBeforeRotation(schains[i], nodeIndex);
        }
    }

    /**
     * @dev Allows Schains contract to remove a rotation from an schain.
     */
    function removeRotation(bytes32 schainHash) external override allow("Schains") {
        delete _rotations[schainHash].nodeIndex;
        delete _rotations[schainHash].newNodeIndex;
        delete _rotations[schainHash].freezeUntil;
        delete _rotations[schainHash].rotationCounter;
    }

    /**
     * @dev Allows Owner to immediately rotate an schain.
     */
    function skipRotationDelay(bytes32 schainHash) external override onlyDebugger {
        _rotations[schainHash].freezeUntil = block.timestamp;
        emit RotationDelaySkipped(schainHash);
    }

    /**
     * @dev Returns rotation details for a given schain.
     */
    function getRotation(bytes32 schainHash) external view override returns (INodeRotation.Rotation memory) {
        return Rotation({
            nodeIndex: _rotations[schainHash].nodeIndex,
            newNodeIndex: _rotations[schainHash].newNodeIndex,
            freezeUntil: _rotations[schainHash].freezeUntil,
            rotationCounter: _rotations[schainHash].rotationCounter
        });
    }

    /**
     * @dev Returns leaving history for a given node.
     */
    function getLeavingHistory(uint nodeIndex) external view override returns (INodeRotation.LeavingHistory[] memory) {
        return leavingHistory[nodeIndex];
    }

    function isRotationInProgress(bytes32 schainHash) external view override returns (bool) {
        bool foundNewNode = isNewNodeFound(schainHash);
        return foundNewNode ?
            leavingHistory[_rotations[schainHash].nodeIndex][
                _rotations[schainHash].indexInLeavingHistory[_rotations[schainHash].nodeIndex]
            ].finishedRotation >= block.timestamp :
            _rotations[schainHash].freezeUntil >= block.timestamp;
    }

    /**
     * @dev Returns a previous node of the node in schain.
     * If there is no previous node for given node would return an error:
     * "No previous node"
     */
    function getPreviousNode(bytes32 schainHash, uint256 nodeIndex) external view override returns (uint256) {
        require(_rotations[schainHash].newNodeIndexes.contains(nodeIndex), "No previous node");
        return _rotations[schainHash].previousNodes[nodeIndex];
    }

    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);
    }

    /**
     * @dev Allows SkaleDKG and SkaleManager contracts to rotate a node from an
     * schain.
     */
    function rotateNode(
        uint nodeIndex,
        bytes32 schainHash,
        bool shouldDelay,
        bool isBadNode
    )
        public
        override
        allowTwo("SkaleDKG", "SkaleManager")
        returns (uint newNode)
    {
        ISchainsInternal schainsInternal = ISchainsInternal(contractManager.getContract("SchainsInternal"));
        schainsInternal.removeNodeFromSchain(nodeIndex, schainHash);
        if (!isBadNode) {
            schainsInternal.removeNodeFromExceptions(schainHash, nodeIndex);
        }
        newNode = selectNodeToGroup(schainHash);
        _finishRotation(schainHash, nodeIndex, newNode, shouldDelay);
    }

    /**
     * @dev Allows SkaleManager, Schains, and SkaleDKG contracts to
     * pseudo-randomly select a new Node for an Schain.
     *
     * Requirements:
     *
     * - Schain is active.
     * - A free node already exists.
     * - Free space can be allocated from the node.
     */
    function selectNodeToGroup(bytes32 schainHash)
        public
        override
        allowThree("SkaleManager", "Schains", "SkaleDKG")
        returns (uint nodeIndex)
    {
        ISchainsInternal schainsInternal = ISchainsInternal(contractManager.getContract("SchainsInternal"));
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        require(schainsInternal.isSchainActive(schainHash), "Group is not active");
        uint8 space = schainsInternal.getSchainsPartOfNode(schainHash);
        schainsInternal.makeSchainNodesInvisible(schainHash);
        require(schainsInternal.isAnyFreeNode(schainHash), "No free Nodes available for rotation");
        IRandom.RandomGenerator memory randomGenerator = Random.createFromEntropy(
            abi.encodePacked(uint(blockhash(block.number - 1)), schainHash)
        );
        nodeIndex = nodes.getRandomNodeWithFreeSpace(space, randomGenerator);
        require(nodes.removeSpaceFromNode(nodeIndex, space), "Could not remove space from nodeIndex");
        schainsInternal.makeSchainNodesVisible(schainHash);
        schainsInternal.addSchainForNode(nodes, nodeIndex, schainHash);
        schainsInternal.setException(schainHash, nodeIndex);
        schainsInternal.setNodeInGroup(schainHash, nodeIndex);
    }

    function isNewNodeFound(bytes32 schainHash) public view override returns (bool) {
        return _rotations[schainHash].newNodeIndexes.contains(_rotations[schainHash].newNodeIndex) &&
            _rotations[schainHash].previousNodes[_rotations[schainHash].newNodeIndex] ==
            _rotations[schainHash].nodeIndex;
    }


    /**
     * @dev Initiates rotation of a node from an schain.
     */
    function _startRotation(bytes32 schainHash, uint nodeIndex) private {
        _rotations[schainHash].newNodeIndex = nodeIndex;
        waitForNewNode[schainHash] = true;
    }

    function _startWaiting(bytes32 schainHash, uint nodeIndex) private {
        IConstantsHolder constants = IConstantsHolder(contractManager.getContract("ConstantsHolder"));
        _rotations[schainHash].nodeIndex = nodeIndex;
        _rotations[schainHash].freezeUntil = block.timestamp + constants.rotationDelay();
    }

    /**
     * @dev Completes rotation of a node from an schain.
     */
    function _finishRotation(
        bytes32 schainHash,
        uint nodeIndex,
        uint newNodeIndex,
        bool shouldDelay)
        private
    {
        leavingHistory[nodeIndex].push(
            LeavingHistory(
                schainHash,
                shouldDelay ? block.timestamp +
                    IConstantsHolder(contractManager.getContract("ConstantsHolder")).rotationDelay()
                : block.timestamp
            )
        );
        require(_rotations[schainHash].newNodeIndexes.add(newNodeIndex), "New node was already added");
        _rotations[schainHash].newNodeIndex = newNodeIndex;
        _rotations[schainHash].rotationCounter++;
        _rotations[schainHash].previousNodes[newNodeIndex] = nodeIndex;
        _rotations[schainHash].indexInLeavingHistory[nodeIndex] = leavingHistory[nodeIndex].length - 1;
        delete waitForNewNode[schainHash];
        ISkaleDKG(contractManager.getContract("SkaleDKG")).openChannel(schainHash);
    }

    function _checkBeforeRotation(bytes32 schainHash, uint nodeIndex) private {
        require(
            ISkaleDKG(contractManager.getContract("SkaleDKG")).isLastDKGSuccessful(schainHash),
            "DKG did not finish on Schain"
        );
        if (_rotations[schainHash].freezeUntil < block.timestamp) {
            _startWaiting(schainHash, nodeIndex);
        } else {
            require(_rotations[schainHash].nodeIndex == nodeIndex, "Occupied by rotation on Schain");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IRandom.sol - SKALE Manager Interfaces
    Copyright (C) 2022-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;


interface IRandom {
    struct RandomGenerator {
        uint seed;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IContractManager.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IContractManager {
    /**
     * @dev Emitted when contract is upgraded.
     */
    event ContractUpgraded(string contractsName, address contractsAddress);

    function initialize() external;
    function setContractsAddress(string calldata contractsName, address newContractsAddress) external;
    function contracts(bytes32 nameHash) external view returns (address);
    function getDelegationPeriodManager() external view returns (address);
    function getBounty() external view returns (address);
    function getValidatorService() external view returns (address);
    function getTimeHelpers() external view returns (address);
    function getConstantsHolder() external view returns (address);
    function getSkaleToken() external view returns (address);
    function getTokenState() external view returns (address);
    function getPunisher() external view returns (address);
    function getContract(string calldata name) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IPermissions.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IPermissions {
    function initialize(address contractManagerAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/thirdparty/openzeppelin/IAccessControlUpgradeableLegacy.sol";
import "./InitializableWithGap.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 */
abstract contract AccessControlUpgradeableLegacy is InitializableWithGap, ContextUpgradeable, IAccessControlUpgradeableLegacy {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IAccessControlUpgradeableLegacy.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IAccessControlUpgradeableLegacy {
    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract InitializableWithGap is Initializable {
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IConstantsHolder.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IConstantsHolder {

    /**
     * @dev Emitted when constants updated.
     */
    event ConstantUpdated(
        bytes32 indexed constantHash,
        uint previousValue,
        uint newValue
    );

    function setPeriods(uint32 newRewardPeriod, uint32 newDeltaPeriod) external;
    function setCheckTime(uint newCheckTime) external;
    function setLatency(uint32 newAllowableLatency) external;
    function setMSR(uint newMSR) external;
    function setLaunchTimestamp(uint timestamp) external;
    function setRotationDelay(uint newDelay) external;
    function setProofOfUseLockUpPeriod(uint periodDays) external;
    function setProofOfUseDelegationPercentage(uint percentage) external;
    function setLimitValidatorsPerDelegator(uint newLimit) external;
    function setSchainCreationTimeStamp(uint timestamp) external;
    function setMinimalSchainLifetime(uint lifetime) external;
    function setComplaintTimeLimit(uint timeLimit) external;
    function setMinNodeBalance(uint newMinNodeBalance) external;
    function reinitialize() external;
    function msr() external view returns (uint);
    function launchTimestamp() external view returns (uint);
    function rotationDelay() external view returns (uint);
    function limitValidatorsPerDelegator() external view returns (uint);
    function schainCreationTimeStamp() external view returns (uint);
    function minimalSchainLifetime() external view returns (uint);
    function complaintTimeLimit() external view returns (uint);
    function minNodeBalance() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISkaleDKG.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ISkaleDKG {

    struct Fp2Point {
        uint a;
        uint b;
    }

    struct G2Point {
        Fp2Point x;
        Fp2Point y;
    }

    struct Channel {
        bool active;
        uint n;
        uint startedBlockTimestamp;
        uint startedBlock;
    }

    struct ProcessDKG {
        uint numberOfBroadcasted;
        uint numberOfCompleted;
        bool[] broadcasted;
        bool[] completed;
    }

    struct ComplaintData {
        uint nodeToComplaint;
        uint fromNodeToComplaint;
        uint startComplaintBlockTimestamp;
        bool isResponse;
        bytes32 keyShare;
        G2Point sumOfVerVec;
    }

    struct KeyShare {
        bytes32[2] publicKey;
        bytes32 share;
    }
    
    /**
     * @dev Emitted when a channel is opened.
     */
    event ChannelOpened(bytes32 schainHash);

    /**
     * @dev Emitted when a channel is closed.
     */
    event ChannelClosed(bytes32 schainHash);

    /**
     * @dev Emitted when a node broadcasts key share.
     */
    event BroadcastAndKeyShare(
        bytes32 indexed schainHash,
        uint indexed fromNode,
        G2Point[] verificationVector,
        KeyShare[] secretKeyContribution
    );

    /**
     * @dev Emitted when all group data is received by node.
     */
    event AllDataReceived(bytes32 indexed schainHash, uint nodeIndex);

    /**
     * @dev Emitted when DKG is successful.
     */
    event SuccessfulDKG(bytes32 indexed schainHash);

    /**
     * @dev Emitted when a complaint against a node is verified.
     */
    event BadGuy(uint nodeIndex);

    /**
     * @dev Emitted when DKG failed.
     */
    event FailedDKG(bytes32 indexed schainHash);

    /**
     * @dev Emitted when a new node is rotated in.
     */
    event NewGuy(uint nodeIndex);

    /**
     * @dev Emitted when an incorrect complaint is sent.
     */
    event ComplaintError(string error);

    /**
     * @dev Emitted when a complaint is sent.
     */
    event ComplaintSent(bytes32 indexed schainHash, uint indexed fromNodeIndex, uint indexed toNodeIndex);
    
    function alright(bytes32 schainHash, uint fromNodeIndex) external;
    function broadcast(
        bytes32 schainHash,
        uint nodeIndex,
        G2Point[] memory verificationVector,
        KeyShare[] memory secretKeyContribution
    )
        external;
    function complaintBadData(bytes32 schainHash, uint fromNodeIndex, uint toNodeIndex) external;
    function preResponse(
        bytes32 schainId,
        uint fromNodeIndex,
        G2Point[] memory verificationVector,
        G2Point[] memory verificationVectorMultiplication,
        KeyShare[] memory secretKeyContribution
    )
        external;
    function complaint(bytes32 schainHash, uint fromNodeIndex, uint toNodeIndex) external;
    function response(
        bytes32 schainHash,
        uint fromNodeIndex,
        uint secretNumber,
        G2Point memory multipliedShare
    )
        external;
    function openChannel(bytes32 schainHash) external;
    function deleteChannel(bytes32 schainHash) external;
    function setStartAlrightTimestamp(bytes32 schainHash) external;
    function setBadNode(bytes32 schainHash, uint nodeIndex) external;
    function finalizeSlashing(bytes32 schainHash, uint badNode) external;
    function getChannelStartedTime(bytes32 schainHash) external view returns (uint);
    function getChannelStartedBlock(bytes32 schainHash) external view returns (uint);
    function getNumberOfBroadcasted(bytes32 schainHash) external view returns (uint);
    function getNumberOfCompleted(bytes32 schainHash) external view returns (uint);
    function getTimeOfLastSuccessfulDKG(bytes32 schainHash) external view returns (uint);
    function getComplaintData(bytes32 schainHash) external view returns (uint, uint);
    function getComplaintStartedTime(bytes32 schainHash) external view returns (uint);
    function getAlrightStartedTime(bytes32 schainHash) external view returns (uint);
    function isChannelOpened(bytes32 schainHash) external view returns (bool);
    function isLastDKGSuccessful(bytes32 groupIndex) external view returns (bool);
    function isBroadcastPossible(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function isComplaintPossible(
        bytes32 schainHash,
        uint fromNodeIndex,
        uint toNodeIndex
    )
        external
        view
        returns (bool);
    function isAlrightPossible(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function isPreResponsePossible(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function isResponsePossible(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function isNodeBroadcasted(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function isAllDataReceived(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function checkAndReturnIndexInGroup(
        bytes32 schainHash,
        uint nodeIndex,
        bool revertCheck
    )
        external
        view
        returns (uint, bool);
    function isEveryoneBroadcasted(bytes32 schainHash) external view returns (bool);
    function hashData(
        KeyShare[] memory secretKeyContribution,
        G2Point[] memory verificationVector
    )
        external
        pure
        returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    INodeRotation.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface INodeRotation {
    /**
     * nodeIndex - index of Node which is in process of rotation (left from schain)
     * newNodeIndex - index of Node which is rotated(added to schain)
     * freezeUntil - time till which Node should be turned on
     * rotationCounter - how many _rotations were on this schain
     */
    struct Rotation {
        uint nodeIndex;
        uint newNodeIndex;
        uint freezeUntil;
        uint rotationCounter;
    }

    struct LeavingHistory {
        bytes32 schainHash;
        uint finishedRotation;
    }

    function exitFromSchain(uint nodeIndex) external returns (bool, bool);
    function freezeSchains(uint nodeIndex) external;
    function removeRotation(bytes32 schainHash) external;
    function skipRotationDelay(bytes32 schainHash) external;
    function rotateNode(
        uint nodeIndex,
        bytes32 schainHash,
        bool shouldDelay,
        bool isBadNode
    )
        external
        returns (uint newNode);
    function selectNodeToGroup(bytes32 schainHash) external returns (uint nodeIndex);
    function getRotation(bytes32 schainHash) external view returns (Rotation memory);
    function getLeavingHistory(uint nodeIndex) external view returns (LeavingHistory[] memory);
    function isRotationInProgress(bytes32 schainHash) external view returns (bool);
    function isNewNodeFound(bytes32 schainHash) external view returns (bool);
    function getPreviousNode(bytes32 schainHash, uint256 nodeIndex) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ISchainsInternal - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

import "./INodes.sol";

interface ISchainsInternal {
    struct Schain {
        string name;
        address owner;
        uint indexInOwnerList;
        uint8 partOfNode;
        uint lifetime;
        uint startDate;
        uint startBlock;
        uint deposit;
        uint64 index;
        uint generation;
        address originator;
    }

    struct SchainType {
        uint8 partOfNode;
        uint numberOfNodes;
    }

    /**
     * @dev Emitted when schain type added.
     */
    event SchainTypeAdded(uint indexed schainType, uint partOfNode, uint numberOfNodes);

    /**
     * @dev Emitted when schain type removed.
     */
    event SchainTypeRemoved(uint indexed schainType);

    function initializeSchain(
        string calldata name,
        address from,
        address originator,
        uint lifetime,
        uint deposit) external;
    function createGroupForSchain(
        bytes32 schainHash,
        uint numberOfNodes,
        uint8 partOfNode
    )
        external
        returns (uint[] memory);
    function changeLifetime(bytes32 schainHash, uint lifetime, uint deposit) external;
    function removeSchain(bytes32 schainHash, address from) external;
    function removeNodeFromSchain(uint nodeIndex, bytes32 schainHash) external;
    function deleteGroup(bytes32 schainHash) external;
    function setException(bytes32 schainHash, uint nodeIndex) external;
    function setNodeInGroup(bytes32 schainHash, uint nodeIndex) external;
    function removeHolesForSchain(bytes32 schainHash) external;
    function addSchainType(uint8 partOfNode, uint numberOfNodes) external;
    function removeSchainType(uint typeOfSchain) external;
    function setNumberOfSchainTypes(uint newNumberOfSchainTypes) external;
    function removeNodeFromAllExceptionSchains(uint nodeIndex) external;
    function removeAllNodesFromSchainExceptions(bytes32 schainHash) external;
    function makeSchainNodesInvisible(bytes32 schainHash) external;
    function makeSchainNodesVisible(bytes32 schainHash) external;
    function newGeneration() external;
    function addSchainForNode(INodes nodes,uint nodeIndex, bytes32 schainHash) external;
    function removeSchainForNode(uint nodeIndex, uint schainIndex) external;
    function removeNodeFromExceptions(bytes32 schainHash, uint nodeIndex) external;
    function isSchainActive(bytes32 schainHash) external view returns (bool);
    function schainsAtSystem(uint index) external view returns (bytes32);
    function numberOfSchains() external view returns (uint64);
    function getSchains() external view returns (bytes32[] memory);
    function getSchainsPartOfNode(bytes32 schainHash) external view returns (uint8);
    function getSchainListSize(address from) external view returns (uint);
    function getSchainHashesByAddress(address from) external view returns (bytes32[] memory);
    function getSchainHashesForNode(uint nodeIndex) external view returns (bytes32[] memory);
    function getSchainOwner(bytes32 schainHash) external view returns (address);
    function getSchainOriginator(bytes32 schainHash) external view returns (address);
    function isSchainNameAvailable(string calldata name) external view returns (bool);
    function isTimeExpired(bytes32 schainHash) external view returns (bool);
    function isOwnerAddress(address from, bytes32 schainHash) external view returns (bool);
    function getSchainName(bytes32 schainHash) external view returns (string memory);
    function getActiveSchain(uint nodeIndex) external view returns (bytes32);
    function getActiveSchains(uint nodeIndex) external view returns (bytes32[] memory activeSchains);
    function getNumberOfNodesInGroup(bytes32 schainHash) external view returns (uint);
    function getNodesInGroup(bytes32 schainHash) external view returns (uint[] memory);
    function isNodeAddressesInGroup(bytes32 schainHash, address sender) external view returns (bool);
    function getNodeIndexInGroup(bytes32 schainHash, uint nodeHash) external view returns (uint);
    function isAnyFreeNode(bytes32 schainHash) external view returns (bool);
    function checkException(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function checkHoleForSchain(bytes32 schainHash, uint indexOfNode) external view returns (bool);
    function checkSchainOnNode(uint nodeIndex, bytes32 schainHash) external view returns (bool);
    function getSchainType(uint typeOfSchain) external view returns(uint8, uint);
    function getGeneration(bytes32 schainHash) external view returns (uint);
    function isSchainExist(bytes32 schainHash) external view returns (bool);
}