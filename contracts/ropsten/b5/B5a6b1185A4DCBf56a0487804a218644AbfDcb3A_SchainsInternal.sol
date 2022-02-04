// SPDX-License-Identifier: AGPL-3.0-only

/*
    SchainsInternal.sol - SKALE Manager
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

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";
import "@skalenetwork/skale-manager-interfaces/ISkaleDKG.sol";
import "@skalenetwork/skale-manager-interfaces/INodes.sol";

import "./Permissions.sol";
import "./ConstantsHolder.sol";
import "./utils/Random.sol";


/**
 * @title SchainsInternal
 * @dev Contract contains all functionality logic to internally manage Schains.
 */
contract SchainsInternal is Permissions, ISchainsInternal {

    using Random for IRandom.RandomGenerator;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // mapping which contain all schains
    mapping (bytes32 => Schain) public schains;

    mapping (bytes32 => bool) public override isSchainActive;

    mapping (bytes32 => uint[]) public schainsGroups;

    mapping (bytes32 => mapping (uint => bool)) private _exceptionsForGroups;
    // mapping shows schains by owner's address
    mapping (address => bytes32[]) public schainIndexes;
    // mapping shows schains which Node composed in
    mapping (uint => bytes32[]) public schainsForNodes;

    mapping (uint => uint[]) public holesForNodes;

    mapping (bytes32 => uint[]) public holesForSchains;

    // array which contain all schains
    bytes32[] public override schainsAtSystem;

    uint64 public override numberOfSchains;
    // total resources that schains occupied
    uint public sumOfSchainsResources;

    mapping (bytes32 => bool) public usedSchainNames;

    mapping (uint => SchainType) public schainTypes;
    uint public numberOfSchainTypes;

    //   schain hash =>   node index  => index of place
    // index of place is a number from 1 to max number of slots on node(128)
    mapping (bytes32 => mapping (uint => uint)) public placeOfSchainOnNode;

    mapping (uint => bytes32[]) private _nodeToLockedSchains;

    mapping (bytes32 => uint[]) private _schainToExceptionNodes;

    EnumerableSetUpgradeable.UintSet private _keysOfSchainTypes;

    uint public currentGeneration;

    bytes32 public constant SCHAIN_TYPE_MANAGER_ROLE = keccak256("SCHAIN_TYPE_MANAGER_ROLE");
    bytes32 public constant DEBUGGER_ROLE = keccak256("DEBUGGER_ROLE");
    bytes32 public constant GENERATION_MANAGER_ROLE = keccak256("GENERATION_MANAGER_ROLE");

    modifier onlySchainTypeManager() {
        require(hasRole(SCHAIN_TYPE_MANAGER_ROLE, msg.sender), "SCHAIN_TYPE_MANAGER_ROLE is required");
        _;
    }

    modifier onlyDebugger() {
        require(hasRole(DEBUGGER_ROLE, msg.sender), "DEBUGGER_ROLE is required");
        _;
    }

    modifier onlyGenerationManager() {
        require(hasRole(GENERATION_MANAGER_ROLE, msg.sender), "GENERATION_MANAGER_ROLE is required");
        _;
    }

    modifier schainExists(bytes32 schainHash) {
        require(isSchainExist(schainHash), "The schain does not exist");
        _;
    }

    /**
     * @dev Allows Schain contract to initialize an schain.
     */
    function initializeSchain(
        string calldata name,
        address from,
        address originator,
        uint lifetime,
        uint deposit
    )
        external
        override
        allow("Schains")
    {
        bytes32 schainHash = keccak256(abi.encodePacked(name));

        schains[schainHash] = Schain({
            name: name,
            owner: from,
            indexInOwnerList: schainIndexes[from].length,
            partOfNode: 0,
            startDate: block.timestamp,            
            startBlock: block.number,
            lifetime: lifetime,
            deposit: deposit,
            index: numberOfSchains,
            generation: currentGeneration,
            originator: originator
        });
        isSchainActive[schainHash] = true;
        numberOfSchains++;
        schainIndexes[from].push(schainHash);
        schainsAtSystem.push(schainHash);
        usedSchainNames[schainHash] = true;
    }

    /**
     * @dev Allows Schain contract to create a node group for an schain.
     *
     * Requirements:
     * 
     * - Message sender is Schains smart contract
     * - Schain must exist
     */
    function createGroupForSchain(
        bytes32 schainHash,
        uint numberOfNodes,
        uint8 partOfNode
    )
        external
        override
        allow("Schains")
        schainExists(schainHash)
        returns (uint[] memory)
    {
        ConstantsHolder constantsHolder = ConstantsHolder(contractManager.getContract("ConstantsHolder"));
        schains[schainHash].partOfNode = partOfNode;
        if (partOfNode > 0) {
            sumOfSchainsResources = sumOfSchainsResources +
                numberOfNodes * constantsHolder.TOTAL_SPACE_ON_NODE() / partOfNode;
        }
        return _generateGroup(schainHash, numberOfNodes);
    }

    /**
     * @dev Allows Schains contract to change the Schain lifetime through
     * an additional SKL token deposit.
     *
     * Requirements:
     * 
     * - Message sender is Schains smart contract
     * - Schain must exist
     */
    function changeLifetime(
        bytes32 schainHash,
        uint lifetime,
        uint deposit
    )
        external
        override
        allow("Schains")
        schainExists(schainHash)
    {
        schains[schainHash].deposit = schains[schainHash].deposit + deposit;
        schains[schainHash].lifetime = schains[schainHash].lifetime + lifetime;
    }

    /**
     * @dev Allows Schains contract to remove an schain from the network.
     * Generally schains are not removed from the system; instead they are
     * simply allowed to expire.
     *
     * Requirements:
     * 
     * - Message sender is Schains smart contract
     * - Schain must exist
     */
    function removeSchain(bytes32 schainHash, address from)
        external
        override
        allow("Schains")
        schainExists(schainHash)
    {
        isSchainActive[schainHash] = false;
        uint length = schainIndexes[from].length;
        uint index = schains[schainHash].indexInOwnerList;
        if (index != length - 1) {
            bytes32 lastSchainHash = schainIndexes[from][length - 1];
            schains[lastSchainHash].indexInOwnerList = index;
            schainIndexes[from][index] = lastSchainHash;
        }
        schainIndexes[from].pop();

        // TODO:
        // optimize
        for (uint i = 0; i + 1 < schainsAtSystem.length; i++) {
            if (schainsAtSystem[i] == schainHash) {
                schainsAtSystem[i] = schainsAtSystem[schainsAtSystem.length - 1];
                break;
            }
        }
        schainsAtSystem.pop();

        delete schains[schainHash];
        numberOfSchains--;
    }

    /**
     * @dev Allows Schains and SkaleDKG contracts to remove a node from an
     * schain for node rotation or DKG failure.
     *
     * Requirements:
     * 
     * - Message sender is Schains, SkaleDKG or NodeRotation smart contract
     * - Schain must exist
     */
    function removeNodeFromSchain(
        uint nodeIndex,
        bytes32 schainHash
    )
        external
        override
        allowThree("NodeRotation", "SkaleDKG", "Schains")
        schainExists(schainHash)
    {
        uint indexOfNode = _findNode(schainHash, nodeIndex);
        uint indexOfLastNode = schainsGroups[schainHash].length - 1;

        if (indexOfNode == indexOfLastNode) {
            schainsGroups[schainHash].pop();
        } else {
            delete schainsGroups[schainHash][indexOfNode];
            if (holesForSchains[schainHash].length > 0 && holesForSchains[schainHash][0] > indexOfNode) {
                uint hole = holesForSchains[schainHash][0];
                holesForSchains[schainHash][0] = indexOfNode;
                holesForSchains[schainHash].push(hole);
            } else {
                holesForSchains[schainHash].push(indexOfNode);
            }
        }

        removeSchainForNode(nodeIndex, placeOfSchainOnNode[schainHash][nodeIndex] - 1);
        delete placeOfSchainOnNode[schainHash][nodeIndex];
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        nodes.addSpaceToNode(nodeIndex, schains[schainHash].partOfNode);
    }

    /**
     * @dev Allows Schains contract to delete a group of schains
     *
     * Requirements:
     * 
     * - Message sender is Schains smart contract
     * - Schain must exist
     */
    function deleteGroup(bytes32 schainHash) external override allow("Schains") schainExists(schainHash) {
        // delete channel
        ISkaleDKG skaleDKG = ISkaleDKG(contractManager.getContract("SkaleDKG"));
        delete schainsGroups[schainHash];
        skaleDKG.deleteChannel(schainHash);
    }

    /**
     * @dev Allows Schain and NodeRotation contracts to set a Node like
     * exception for a given schain and nodeIndex.
     *
     * Requirements:
     * 
     * - Message sender is Schains or NodeRotation smart contract
     * - Schain must exist
     */
    function setException(
        bytes32 schainHash,
        uint nodeIndex
    )
        external
        override
        allowTwo("Schains", "NodeRotation")
        schainExists(schainHash)
    {
        _setException(schainHash, nodeIndex);
    }

    /**
     * @dev Allows Schains and NodeRotation contracts to add node to an schain
     * group.
     *
     * Requirements:
     * 
     * - Message sender is Schains or NodeRotation smart contract
     * - Schain must exist
     */
    function setNodeInGroup(
        bytes32 schainHash,
        uint nodeIndex
    )
        external
        override
        allowTwo("Schains", "NodeRotation")
        schainExists(schainHash)
    {
        if (holesForSchains[schainHash].length == 0) {
            schainsGroups[schainHash].push(nodeIndex);
        } else {
            schainsGroups[schainHash][holesForSchains[schainHash][0]] = nodeIndex;
            uint min = type(uint).max;
            uint index = 0;
            for (uint i = 1; i < holesForSchains[schainHash].length; i++) {
                if (min > holesForSchains[schainHash][i]) {
                    min = holesForSchains[schainHash][i];
                    index = i;
                }
            }
            if (min == type(uint).max) {
                delete holesForSchains[schainHash];
            } else {
                holesForSchains[schainHash][0] = min;
                holesForSchains[schainHash][index] =
                    holesForSchains[schainHash][holesForSchains[schainHash].length - 1];
                holesForSchains[schainHash].pop();
            }
        }
    }

    /**
     * @dev Allows Schains contract to remove holes for schains
     *
     * Requirements:
     * 
     * - Message sender is Schains smart contract
     * - Schain must exist
     */
    function removeHolesForSchain(bytes32 schainHash) external override allow("Schains") schainExists(schainHash) {
        delete holesForSchains[schainHash];
    }

    /**
     * @dev Allows Admin to add schain type
     */
    function addSchainType(uint8 partOfNode, uint numberOfNodes) external override onlySchainTypeManager {
        require(_keysOfSchainTypes.add(numberOfSchainTypes + 1), "Schain type is already added");
        schainTypes[numberOfSchainTypes + 1].partOfNode = partOfNode;
        schainTypes[numberOfSchainTypes + 1].numberOfNodes = numberOfNodes;
        numberOfSchainTypes++;
        emit SchainTypeAdded(numberOfSchainTypes, partOfNode, numberOfNodes);
    }

    /**
     * @dev Allows Admin to remove schain type
     */
    function removeSchainType(uint typeOfSchain) external override onlySchainTypeManager {
        require(_keysOfSchainTypes.remove(typeOfSchain), "Schain type is already removed");
        delete schainTypes[typeOfSchain].partOfNode;
        delete schainTypes[typeOfSchain].numberOfNodes;
        emit SchainTypeRemoved(typeOfSchain);
    }

    /**
     * @dev Allows Admin to set number of schain types
     */
    function setNumberOfSchainTypes(uint newNumberOfSchainTypes) external override onlySchainTypeManager {
        numberOfSchainTypes = newNumberOfSchainTypes;
    }

    function removeNodeFromAllExceptionSchains(uint nodeIndex) external override allow("SkaleManager") {
        uint len = _nodeToLockedSchains[nodeIndex].length;
        for (uint i = len; i > 0; i--) {
            removeNodeFromExceptions(_nodeToLockedSchains[nodeIndex][i - 1], nodeIndex);
        }
    }

    /**
     * @dev Clear list of nodes that can't be chosen to schain with id {schainHash}
     */
    function removeAllNodesFromSchainExceptions(bytes32 schainHash) external override allow("Schains") {
        for (uint i = 0; i < _schainToExceptionNodes[schainHash].length; ++i) {
            removeNodeFromExceptions(schainHash, _schainToExceptionNodes[schainHash][i]);
        }
    }

    /**
     * @dev Mark all nodes in the schain as invisible
     *
     * Requirements:
     * 
     * - Message sender is NodeRotation or SkaleDKG smart contract
     * - Schain must exist
     */

    function makeSchainNodesInvisible(
        bytes32 schainHash
    )
        external
        override
        allowTwo("NodeRotation", "SkaleDKG")
        schainExists(schainHash)
    {
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        for (uint i = 0; i < _schainToExceptionNodes[schainHash].length; i++) {
            nodes.makeNodeInvisible(_schainToExceptionNodes[schainHash][i]);
        }
    }

    /**
     * @dev Mark all nodes in the schain as visible
     *
     * Requirements:
     * 
     * - Message sender is NodeRotation or SkaleDKG smart contract
     * - Schain must exist
     */
    function makeSchainNodesVisible(
        bytes32 schainHash
    )
        external
        override
        allowTwo("NodeRotation", "SkaleDKG")
        schainExists(schainHash)
    {
        _makeSchainNodesVisible(schainHash);
    }

    /**
     * @dev Increments generation for all new schains
     *
     * Requirements:
     * 
     * - Sender must be granted with GENERATION_MANAGER_ROLE
     */
    function newGeneration() external override onlyGenerationManager {
        currentGeneration += 1;
    }

    /**
     * @dev Returns all Schains in the network.
     */
    function getSchains() external view override returns (bytes32[] memory) {
        return schainsAtSystem;
    }

    /**
     * @dev Returns all occupied resources on one node for an Schain.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getSchainsPartOfNode(bytes32 schainHash) external view override schainExists(schainHash) returns (uint8) {
        return schains[schainHash].partOfNode;
    }

    /**
     * @dev Returns number of schains by schain owner.
     */
    function getSchainListSize(address from) external view override returns (uint) {
        return schainIndexes[from].length;
    }

    /**
     * @dev Returns hashes of schain names by schain owner.
     */
    function getSchainHashesByAddress(address from) external view override returns (bytes32[] memory) {
        return schainIndexes[from];
    }

    /**
     * @dev Returns hashes of schain names by schain owner.
     */
    function getSchainIdsByAddress(address from) external view override returns (bytes32[] memory) {
        return schainIndexes[from];
    }

    /**
     * @dev Returns hashes of schain names running on a node.
     */
    function getSchainHashesForNode(uint nodeIndex) external view override returns (bytes32[] memory) {
        return schainsForNodes[nodeIndex];
    }

    /**
     * @dev Returns hashes of schain names running on a node.
     */
    function getSchainIdsForNode(uint nodeIndex) external view override returns (bytes32[] memory) {
        return schainsForNodes[nodeIndex];
    }

    /**
     * @dev Returns the owner of an schain.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getSchainOwner(bytes32 schainHash) external view override schainExists(schainHash) returns (address) {
        return schains[schainHash].owner;
    }

    /**
     * @dev Returns an originator of the schain.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getSchainOriginator(bytes32 schainHash)
        external
        view
        override
        schainExists(schainHash)
        returns (address)
    {
        require(schains[schainHash].originator != address(0), "Originator address is not set");
        return schains[schainHash].originator;
    }

    /**
     * @dev Checks whether schain name is available.
     * TODO Need to delete - copy of web3.utils.soliditySha3
     */
    function isSchainNameAvailable(string calldata name) external view override returns (bool) {
        bytes32 schainHash = keccak256(abi.encodePacked(name));
        return schains[schainHash].owner == address(0) &&
            !usedSchainNames[schainHash] &&
            keccak256(abi.encodePacked(name)) != keccak256(abi.encodePacked("Mainnet"));
    }

    /**
     * @dev Checks whether schain lifetime has expired.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function isTimeExpired(bytes32 schainHash) external view override schainExists(schainHash) returns (bool) {
        return uint(schains[schainHash].startDate) + schains[schainHash].lifetime < block.timestamp;
    }

    /**
     * @dev Checks whether address is owner of schain.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function isOwnerAddress(
        address from,
        bytes32 schainHash
    )
        external
        view
        override
        schainExists(schainHash)
        returns (bool)
    {
        return schains[schainHash].owner == from;
    }

    /**
     * @dev Returns schain name.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getSchainName(bytes32 schainHash)
        external
        view
        override schainExists(schainHash)
        returns (string memory)
    {
        return schains[schainHash].name;
    }

    /**
     * @dev Returns last active schain of a node.
     */
    function getActiveSchain(uint nodeIndex) external view override returns (bytes32) {
        for (uint i = schainsForNodes[nodeIndex].length; i > 0; i--) {
            if (schainsForNodes[nodeIndex][i - 1] != bytes32(0)) {
                return schainsForNodes[nodeIndex][i - 1];
            }
        }
        return bytes32(0);
    }

    /**
     * @dev Returns active schains of a node.
     */
    function getActiveSchains(uint nodeIndex) external view override returns (bytes32[] memory activeSchains) {
        uint activeAmount = 0;
        for (uint i = 0; i < schainsForNodes[nodeIndex].length; i++) {
            if (schainsForNodes[nodeIndex][i] != bytes32(0)) {
                activeAmount++;
            }
        }

        uint cursor = 0;
        activeSchains = new bytes32[](activeAmount);
        for (uint i = schainsForNodes[nodeIndex].length; i > 0; i--) {
            if (schainsForNodes[nodeIndex][i - 1] != bytes32(0)) {
                activeSchains[cursor++] = schainsForNodes[nodeIndex][i - 1];
            }
        }
    }

    /**
     * @dev Returns number of nodes in an schain group.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getNumberOfNodesInGroup(bytes32 schainHash)
        external
        view
        override
        schainExists(schainHash)
        returns (uint)
    {
        return schainsGroups[schainHash].length;
    }

    /**
     * @dev Returns nodes in an schain group.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getNodesInGroup(bytes32 schainHash)
        external
        view
        override
        schainExists(schainHash)
        returns (uint[] memory)
    {
        return schainsGroups[schainHash];
    }

    /**
     * @dev Checks whether sender is a node address from a given schain group.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function isNodeAddressesInGroup(
        bytes32 schainHash,
        address sender
    )
        external
        view
        override
        schainExists(schainHash)
        returns (bool)
    {
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        for (uint i = 0; i < schainsGroups[schainHash].length; i++) {
            if (nodes.getNodeAddress(schainsGroups[schainHash][i]) == sender) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Returns node index in schain group.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getNodeIndexInGroup(
        bytes32 schainHash,
        uint nodeId
    )
        external
        view
        override
        schainExists(schainHash)
        returns (uint)
    {
        for (uint index = 0; index < schainsGroups[schainHash].length; index++) {
            if (schainsGroups[schainHash][index] == nodeId) {
                return index;
            }
        }
        return schainsGroups[schainHash].length;
    }

    /**
     * @dev Checks whether there are any nodes with free resources for given
     * schain.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function isAnyFreeNode(bytes32 schainHash) external view override schainExists(schainHash) returns (bool) {
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        uint8 space = schains[schainHash].partOfNode;
        return nodes.countNodesWithFreeSpace(space) > 0;
    }

    /**
     * @dev Returns whether any exceptions exist for node in a schain group.
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function checkException(bytes32 schainHash, uint nodeIndex)
        external
        view
        override
        schainExists(schainHash)
        returns (bool)
    {
        return _exceptionsForGroups[schainHash][nodeIndex];
    }

    /**
     * @dev Checks if the node is in holes for the schain
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function checkHoleForSchain(
        bytes32 schainHash,
        uint indexOfNode
    )
        external
        view
        override
        schainExists(schainHash)
        returns (bool)
    {
        for (uint i = 0; i < holesForSchains[schainHash].length; i++) {
            if (holesForSchains[schainHash][i] == indexOfNode) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Checks if the node is assigned for the schain
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function checkSchainOnNode(
        uint nodeIndex,
        bytes32 schainHash
    )
        external
        view
        override
        schainExists(schainHash)
        returns (bool)
    {
        return placeOfSchainOnNode[schainHash][nodeIndex] != 0;
    }

    function getSchainType(uint typeOfSchain) external view override returns(uint8, uint) {
        require(_keysOfSchainTypes.contains(typeOfSchain), "Invalid type of schain");
        return (schainTypes[typeOfSchain].partOfNode, schainTypes[typeOfSchain].numberOfNodes);
    }

    /**
     * @dev Returns generation of a particular schain
     *
     * Requirements:
     * 
     * - Schain must exist
     */
    function getGeneration(bytes32 schainHash) external view override schainExists(schainHash) returns (uint) {
        return schains[schainHash].generation;
    }

    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);

        numberOfSchains = 0;
        sumOfSchainsResources = 0;
        numberOfSchainTypes = 0;
    }

    /**
     * @dev Allows Schains and NodeRotation contracts to add schain to node.
     *
     * Requirements:
     * 
     * - Message sender is Schains or NodeRotation smart contract
     * - Schain must exist
     */
    function addSchainForNode(
        uint nodeIndex,
        bytes32 schainHash
    )
        public
        override
        allowTwo("Schains", "NodeRotation")
        schainExists(schainHash)
    {
        if (holesForNodes[nodeIndex].length == 0) {
            schainsForNodes[nodeIndex].push(schainHash);
            placeOfSchainOnNode[schainHash][nodeIndex] = schainsForNodes[nodeIndex].length;
        } else {
            uint lastHoleOfNode = holesForNodes[nodeIndex][holesForNodes[nodeIndex].length - 1];
            schainsForNodes[nodeIndex][lastHoleOfNode] = schainHash;
            placeOfSchainOnNode[schainHash][nodeIndex] = lastHoleOfNode + 1;
            holesForNodes[nodeIndex].pop();
        }
    }

    /**
     * @dev Allows Schains, NodeRotation, and SkaleDKG contracts to remove an 
     * schain from a node.
     */
    function removeSchainForNode(uint nodeIndex, uint schainIndex)
        public
        override
        allowThree("NodeRotation", "SkaleDKG", "Schains")
    {
        uint length = schainsForNodes[nodeIndex].length;
        if (schainIndex == length - 1) {
            schainsForNodes[nodeIndex].pop();
        } else {
            delete schainsForNodes[nodeIndex][schainIndex];
            if (holesForNodes[nodeIndex].length > 0 && holesForNodes[nodeIndex][0] > schainIndex) {
                uint hole = holesForNodes[nodeIndex][0];
                holesForNodes[nodeIndex][0] = schainIndex;
                holesForNodes[nodeIndex].push(hole);
            } else {
                holesForNodes[nodeIndex].push(schainIndex);
            }
        }
    }

    /**
     * @dev Allows Schains contract to remove node from exceptions
     *
     * Requirements:
     * 
     * - Message sender is Schains, NodeRotation or SkaleManager smart contract
     * - Schain must exist
     */
    function removeNodeFromExceptions(bytes32 schainHash, uint nodeIndex)
        public
        override
        allowThree("Schains", "NodeRotation", "SkaleManager")
        schainExists(schainHash)
    {
        _exceptionsForGroups[schainHash][nodeIndex] = false;
        uint len = _nodeToLockedSchains[nodeIndex].length;
        for (uint i = len; i > 0; i--) {
            if (_nodeToLockedSchains[nodeIndex][i - 1] == schainHash) {
                if (i != len) {
                    _nodeToLockedSchains[nodeIndex][i - 1] = _nodeToLockedSchains[nodeIndex][len - 1];
                }
                _nodeToLockedSchains[nodeIndex].pop();
                break;
            }
        }
        len = _schainToExceptionNodes[schainHash].length;
        for (uint i = len; i > 0; i--) {
            if (_schainToExceptionNodes[schainHash][i - 1] == nodeIndex) {
                if (i != len) {
                    _schainToExceptionNodes[schainHash][i - 1] = _schainToExceptionNodes[schainHash][len - 1];
                }
                _schainToExceptionNodes[schainHash].pop();
                break;
            }
        }
    }

    /**
     * @dev Checks whether schain exists.
     */
    function isSchainExist(bytes32 schainHash) public view override returns (bool) {
        return bytes(schains[schainHash].name).length != 0;
    }

    function _getNodeToLockedSchains() internal view returns (mapping(uint => bytes32[]) storage) {
        return _nodeToLockedSchains;
    }

    function _getSchainToExceptionNodes() internal view returns (mapping(bytes32 => uint[]) storage) {
        return _schainToExceptionNodes;
    }

    /**
     * @dev Generates schain group using a pseudo-random generator.
     */
    function _generateGroup(bytes32 schainHash, uint numberOfNodes) private returns (uint[] memory nodesInGroup) {
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        uint8 space = schains[schainHash].partOfNode;
        nodesInGroup = new uint[](numberOfNodes);

        require(nodes.countNodesWithFreeSpace(space) >= nodesInGroup.length, "Not enough nodes to create Schain");
        IRandom.RandomGenerator memory randomGenerator = Random.createFromEntropy(
            abi.encodePacked(uint(blockhash(block.number - 1)), schainHash)
        );
        for (uint i = 0; i < numberOfNodes; i++) {
            uint node = nodes.getRandomNodeWithFreeSpace(space, randomGenerator);
            nodesInGroup[i] = node;
            _setException(schainHash, node);
            addSchainForNode(node, schainHash);
            nodes.makeNodeInvisible(node);
            require(nodes.removeSpaceFromNode(node, space), "Could not remove space from Node");
        }
        // set generated group
        schainsGroups[schainHash] = nodesInGroup;
        _makeSchainNodesVisible(schainHash);
    }

    function _setException(bytes32 schainHash, uint nodeIndex) private {
        _exceptionsForGroups[schainHash][nodeIndex] = true;
        _nodeToLockedSchains[nodeIndex].push(schainHash);
        _schainToExceptionNodes[schainHash].push(nodeIndex);
    }

    function _makeSchainNodesVisible(bytes32 schainHash) private {
        INodes nodes = INodes(contractManager.getContract("Nodes"));
        for (uint i = 0; i < _schainToExceptionNodes[schainHash].length; i++) {
            nodes.makeNodeVisible(_schainToExceptionNodes[schainHash][i]);
        }
    }

    /**
     * @dev Returns local index of node in schain group.
     */
    function _findNode(bytes32 schainHash, uint nodeIndex) private view returns (uint) {
        uint[] memory nodesInGroup = schainsGroups[schainHash];
        uint index;
        for (index = 0; index < nodesInGroup.length; index++) {
            if (nodesInGroup[index] == nodeIndex) {
                return index;
            }
        }
        return index;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
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
    function addSchainForNode(uint nodeIndex, bytes32 schainHash) external;
    function removeSchainForNode(uint nodeIndex, uint schainIndex) external;
    function removeNodeFromExceptions(bytes32 schainHash, uint nodeIndex) external;
    function isSchainActive(bytes32 schainHash) external view returns (bool);
    function schainsAtSystem(uint index) external view returns (bytes32);
    function numberOfSchains() external view returns (uint64);
    function getSchains() external view returns (bytes32[] memory);
    function getSchainsPartOfNode(bytes32 schainHash) external view returns (uint8);
    function getSchainListSize(address from) external view returns (uint);
    function getSchainHashesByAddress(address from) external view returns (bytes32[] memory);
    function getSchainIdsByAddress(address from) external view returns (bytes32[] memory);
    function getSchainHashesForNode(uint nodeIndex) external view returns (bytes32[] memory);
    function getSchainIdsForNode(uint nodeIndex) external view returns (bytes32[] memory);
    function getSchainOwner(bytes32 schainHash) external view returns (address);
    function getSchainOriginator(bytes32 schainHash) external view returns (address);
    function isSchainNameAvailable(string calldata name) external view returns (bool);
    function isTimeExpired(bytes32 schainHash) external view returns (bool);
    function isOwnerAddress(address from, bytes32 schainId) external view returns (bool);
    function getSchainName(bytes32 schainHash) external view returns (string memory);
    function getActiveSchain(uint nodeIndex) external view returns (bytes32);
    function getActiveSchains(uint nodeIndex) external view returns (bytes32[] memory activeSchains);
    function getNumberOfNodesInGroup(bytes32 schainHash) external view returns (uint);
    function getNodesInGroup(bytes32 schainHash) external view returns (uint[] memory);
    function isNodeAddressesInGroup(bytes32 schainId, address sender) external view returns (bool);
    function getNodeIndexInGroup(bytes32 schainHash, uint nodeId) external view returns (uint);
    function isAnyFreeNode(bytes32 schainHash) external view returns (bool);
    function checkException(bytes32 schainHash, uint nodeIndex) external view returns (bool);
    function checkHoleForSchain(bytes32 schainHash, uint indexOfNode) external view returns (bool);
    function checkSchainOnNode(uint nodeIndex, bytes32 schainHash) external view returns (bool);
    function getSchainType(uint typeOfSchain) external view returns(uint8, uint);
    function getGeneration(bytes32 schainHash) external view returns (uint);
    function isSchainExist(bytes32 schainHash) external view returns (bool);
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

pragma solidity 0.8.11;

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

pragma solidity 0.8.11;

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
    uint public constant COMPLAINT_DELTA = 104611;
    uint public constant RESPONSE_DELTA = 49132;

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

pragma solidity 0.8.11;

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
    function msr() external view returns (uint);
    function launchTimestamp() external view returns (uint);
    function rotationDelay() external view returns (uint);
    function limitValidatorsPerDelegator() external view returns (uint);
    function schainCreationTimeStamp() external view returns (uint);
    function minimalSchainLifetime() external view returns (uint);
    function complaintTimeLimit() external view returns (uint);
}