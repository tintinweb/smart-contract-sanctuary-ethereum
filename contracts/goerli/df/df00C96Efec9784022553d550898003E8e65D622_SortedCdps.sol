// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/ISortedCdps.sol";
import "./Interfaces/ICdpManager.sol";
import "./Interfaces/IBorrowerOperations.sol";

/*
 * A sorted doubly linked list with nodes sorted in descending order.
 *
 * Nodes map to active Cdps in the system by ID.
 * Nodes are ordered according to their current nominal individual collateral ratio (NICR),
 * which is like the ICR but without the price, i.e., just collateral / debt.
 *
 * The list optionally accepts insert position hints.
 *
 * NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Cdps
 * change dynamically as liquidation events occur.
 *
 * The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Cdps,
 * but maintains their order. A node inserted based on current NICR will maintain the correct position,
 * relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
 * Thus, Nodes remain sorted by current NICR.
 *
 * Nodes need only be re-inserted upon a Cdp operation - when the owner adds or removes collateral or debt
 * to their position.
 *
 * The list is a modification of the following audited SortedDoublyLinkedList:
 * https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
 *
 *
 * Changes made in the Liquity implementation:
 *
 * - Keys have been removed from nodes
 *
 * - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
 *   The list relies on the property that ordering by ICR is maintained as the ETH:USD price varies.
 *
 * - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
 */
contract SortedCdps is ISortedCdps {
    string public constant NAME = "SortedCdps";

    address public immutable borrowerOperationsAddress;

    ICdpManager public immutable cdpManager;

    // Information for a node in the list
    struct Node {
        bytes32 nextId; // Id of next node (smaller NICR) in the list
        bytes32 prevId; // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Data {
        bytes32 head; // Head of the list. Also the node in the list with the largest NICR
        bytes32 tail; // Tail of the list. Also the node in the list with the smallest NICR
        uint256 maxSize; // Maximum size of the list
        uint256 size; // Current size of the list
        mapping(bytes32 => Node) nodes; // Track the corresponding ids for each node in the list
    }

    Data public data;

    mapping(bytes32 => address) public cdpOwners;
    uint256 public nextCdpNonce;
    bytes32 public constant dummyId =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    // Mapping from cdp owner to list of owned cdp IDs
    mapping(address => mapping(uint256 => bytes32)) public override _ownedCdps;

    // Mapping from cdp ID to index within owner cdp list
    mapping(bytes32 => uint256) public override _ownedCdpIndex;

    // Mapping from cdp owner to its owned cdps count
    mapping(address => uint256) public override _ownedCount;

    // --- Dependency setters ---
    constructor(uint256 _size, address _cdpManagerAddress, address _borrowerOperationsAddress) {
        if (_size == 0) {
            _size = type(uint256).max;
        }

        data.maxSize = _size;

        cdpManager = ICdpManager(_cdpManagerAddress);
        borrowerOperationsAddress = _borrowerOperationsAddress;

        emit CdpManagerAddressChanged(_cdpManagerAddress);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
    }

    // https://github.com/balancer-labs/balancer-v2-monorepo/blob/18bd5fb5d87b451cc27fbd30b276d1fb2987b529/pkg/vault/contracts/PoolRegistry.sol
    function toCdpId(
        address owner,
        uint256 blockHeight,
        uint256 nonce
    ) public pure returns (bytes32) {
        bytes32 serialized;

        serialized |= bytes32(nonce);
        serialized |= bytes32(blockHeight) << (8 * 8); // to accommendate more than 4.2 billion blocks
        serialized |= bytes32(uint256(uint160(owner))) << (12 * 8);

        return serialized;
    }

    function getOwnerAddress(bytes32 cdpId) public pure override returns (address) {
        uint256 _tmp = uint256(cdpId) >> (12 * 8);
        return address(uint160(_tmp));
    }

    function existCdpOwners(bytes32 cdpId) public view override returns (address) {
        return cdpOwners[cdpId];
    }

    function nonExistId() public pure override returns (bytes32) {
        return dummyId;
    }

    function cdpOfOwnerByIndex(address owner, uint256 index) public view override returns (bytes32) {
        require(index < _ownedCount[owner], "!index");
        return _ownedCdps[owner][index];
    }

    function cdpCountOf(address owner) public view override returns (uint256) {
        return _ownedCount[owner];
    }

    // Returns array of all user owned CDPs
    function getCdpsOf(address owner) public view override returns (bytes32[] memory) {
        uint countOfCdps = _ownedCount[owner];
        bytes32[] memory cdps = new bytes32[](countOfCdps);
        for (uint cdpIx = 0; cdpIx < countOfCdps; ++cdpIx) {
            cdps[cdpIx] = _ownedCdps[owner][cdpIx];
        }
        return cdps;
    }

    function insert(
        address owner,
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external override returns (bytes32) {
        bytes32 _id = toCdpId(owner, block.number, nextCdpNonce);
        require(cdpManager.getCdpStatus(_id) == 0, "SortedCdps: new id is NOT nonExistent!");

        _insertWithGeneratedId(owner, _id, _NICR, _prevId, _nextId);
        return _id;
    }

    /*
     * @dev Add a node to the list
     * @param owner cdp owner
     * @param _id Node's id
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function _insertWithGeneratedId(
        address owner,
        bytes32 _id,
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) internal {
        _requireCallerIsBOorCdpM();
        _insert(cdpManager, _id, _NICR, _prevId, _nextId);

        nextCdpNonce += 1;
        cdpOwners[_id] = owner;
        _addCdpToOwnerEnumeration(owner, _id);
    }

    function _insert(
        ICdpManager _cdpManager,
        bytes32 _id,
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) internal {
        // List must not be full
        require(!isFull(), "SortedCdps: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedCdps: List already contains the node");
        // Node id must not be null
        require(_id != dummyId, "SortedCdps: Id cannot be zero");
        // NICR must be non-zero
        require(_NICR > 0, "SortedCdps: NICR must be positive");

        bytes32 prevId = _prevId;
        bytes32 nextId = _nextId;

        if (!_validInsertPosition(_cdpManager, _NICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_cdpManager, _NICR, prevId, nextId);
        }

        if (prevId == dummyId && nextId == dummyId) {
            // Insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == dummyId) {
            // Insert before `prevId` as the head
            data.nodes[_id].nextId = data.head;
            data.nodes[data.head].prevId = _id;
            data.head = _id;
        } else if (nextId == dummyId) {
            // Insert after `nextId` as the tail
            data.nodes[_id].prevId = data.tail;
            data.nodes[data.tail].nextId = _id;
            data.tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            data.nodes[_id].nextId = nextId;
            data.nodes[_id].prevId = prevId;
            data.nodes[prevId].nextId = _id;
            data.nodes[nextId].prevId = _id;
        }

        data.size = data.size + 1;
        emit NodeAdded(_id, _NICR);
    }

    function remove(bytes32 _id) external override {
        _requireCallerIsCdpManager();
        _remove(_id);

        address _owner = cdpOwners[_id];
        _removeCdpFromOwnerEnumeration(_owner, _id);
        delete cdpOwners[_id];
    }

    function batchRemove(bytes32[] memory _ids) external override {
        _requireCallerIsCdpManager();
        uint _len = _ids.length;
        require(_len > 1, "SortedCdps: batchRemove() only apply to multiple cdpIds!");

        bytes32 _firstPrev = data.nodes[_ids[0]].prevId;
        bytes32 _lastNext = data.nodes[_ids[_len - 1]].nextId;

        require(
            _firstPrev != dummyId || _lastNext != dummyId,
            "SortedCdps: batchRemove() leave ZERO node left!"
        );

        for (uint i = 0; i < _len; ++i) {
            require(contains(_ids[i]), "SortedCdps: List does not contain the id");
        }

        // orphan nodes in between to save gas
        if (_firstPrev != dummyId) {
            data.nodes[_firstPrev].nextId = _lastNext;
        } else {
            data.head = _lastNext;
        }
        if (_lastNext != dummyId) {
            data.nodes[_lastNext].prevId = _firstPrev;
        } else {
            data.tail = _firstPrev;
        }

        // delete node & owner storages to get gas refund
        for (uint i = 0; i < _len; ++i) {
            _removeCdpFromOwnerEnumeration(cdpOwners[_ids[i]], _ids[i]);
            delete cdpOwners[_ids[i]];
            delete data.nodes[_ids[i]];
            emit NodeRemoved(_ids[i]);
        }
        data.size = data.size - _len;
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(bytes32 _id) internal {
        // List must contain the node
        require(contains(_id), "SortedCdps: List does not contain the id");

        if (data.size > 1) {
            // List contains more than a single node
            if (_id == data.head) {
                // The removed node is the head
                // Set head to next node
                data.head = data.nodes[_id].nextId;
                // Set prev pointer of new head to null
                data.nodes[data.head].prevId = dummyId;
            } else if (_id == data.tail) {
                // The removed node is the tail
                // Set tail to previous node
                data.tail = data.nodes[_id].prevId;
                // Set next pointer of new tail to null
                data.nodes[data.tail].nextId = dummyId;
            } else {
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                data.nodes[data.nodes[_id].prevId].nextId = data.nodes[_id].nextId;
                // Set prev pointer of next node to the previous node
                data.nodes[data.nodes[_id].nextId].prevId = data.nodes[_id].prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            data.head = dummyId;
            data.tail = dummyId;
        }

        delete data.nodes[_id];
        data.size = data.size - 1;
        emit NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new NICR
     * @param _id Node's id
     * @param _newNICR Node's new NICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(
        bytes32 _id,
        uint256 _newNICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external override {
        _requireCallerIsBOorCdpM();
        // List must contain the node
        require(contains(_id), "SortedCdps: List does not contain the id");
        // NICR must be non-zero
        require(_newNICR > 0, "SortedCdps: NICR must be positive");

        // Remove node from the list
        _remove(_id);

        _insert(cdpManager, _id, _newNICR, _prevId, _nextId);
    }

    /**
     * @dev Private function to add a cdp to ownership-tracking data structures.
     * @param to address representing the owner of the given cdp ID
     * @param cdpId bytes32 ID of the cdp to be added to the owned list of the given owner
     */
    function _addCdpToOwnerEnumeration(address to, bytes32 cdpId) private {
        uint256 length = _ownedCount[to];
        _ownedCdps[to][length] = cdpId;
        _ownedCdpIndex[cdpId] = length;
        _ownedCount[to] = length + 1;
    }

    /**
     * @dev Private function to remove a cdp from ownership-tracking data structures.
     * This has O(1) time complexity, but alters the ordering within the _ownedCdps.
     * @param from address representing the owner of the given cdp ID
     * @param cdpId bytes32 ID of the cdp to be removed from the owned list of the given owner
     */
    function _removeCdpFromOwnerEnumeration(address from, bytes32 cdpId) private {
        uint256 lastCdpIndex = _ownedCount[from] - 1;
        uint256 cdpIndex = _ownedCdpIndex[cdpId];

        if (cdpIndex != lastCdpIndex) {
            bytes32 lastCdpId = _ownedCdps[from][lastCdpIndex];
            _ownedCdps[from][cdpIndex] = lastCdpId; // Move the last cdp to the slot of the to-delete cdp
            _ownedCdpIndex[lastCdpId] = cdpIndex; // Update the moved cdp's index
        }

        delete _ownedCdpIndex[cdpId];
        delete _ownedCdps[from][lastCdpIndex];
        _ownedCount[from] = lastCdpIndex;
    }

    /**
     * @dev Checks if the list contains a given node
     * @param _id The ID of the node
     * @return true if the node exists, false otherwise
     */
    function contains(bytes32 _id) public view override returns (bool) {
        bool _exist = _id != dummyId && (data.head == _id || data.tail == _id);
        if (!_exist) {
            Node memory _node = data.nodes[_id];
            _exist = _id != dummyId && (_node.nextId != dummyId && _node.prevId != dummyId);
        }
        return _exist;
    }

    /**
     * @dev Checks if the list is full
     * @return true if the list is full, false otherwise
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /**
     * @dev Checks if the list is empty
     * @return true if the list is empty, false otherwise
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /**
     * @dev Returns the current size of the list
     * @return The current size of the list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /**
     * @dev Returns the maximum size of the list
     * @return The maximum size of the list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /**
     * @dev Returns the first node in the list (node with the largest NICR)
     * @return The ID of the first node
     */
    function getFirst() external view override returns (bytes32) {
        return data.head;
    }

    /**
     * @dev Returns the last node in the list (node with the smallest NICR)
     * @return The ID of the last node
     */
    function getLast() external view override returns (bytes32) {
        return data.tail;
    }

    /**
     * @dev Returns the next node (with a smaller NICR) in the list for a given node
     * @param _id The ID of the node
     * @return The ID of the next node
     */
    function getNext(bytes32 _id) external view override returns (bytes32) {
        return data.nodes[_id].nextId;
    }

    /**
     * @dev Returns the previous node (with a larger NICR) in the list for a given node
     * @param _id The ID of the node
     * @return The ID of the previous node
     */
    function getPrev(bytes32 _id) external view override returns (bytes32) {
        return data.nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @return true if the position is valid, false otherwise
     */
    function validInsertPosition(
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view override returns (bool) {
        return _validInsertPosition(cdpManager, _NICR, _prevId, _nextId);
    }

    function _validInsertPosition(
        ICdpManager _cdpManager,
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) internal view returns (bool) {
        if (_prevId == dummyId && _nextId == dummyId) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == dummyId) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _NICR >= _cdpManager.getNominalICR(_nextId);
        } else if (_nextId == dummyId) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _NICR <= _cdpManager.getNominalICR(_prevId);
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
            return
                data.nodes[_prevId].nextId == _nextId &&
                _cdpManager.getNominalICR(_prevId) >= _NICR &&
                _NICR >= _cdpManager.getNominalICR(_nextId);
        }
    }

    /*
     * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
     * @param _cdpManager CdpManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(
        ICdpManager _cdpManager,
        uint256 _NICR,
        bytes32 _startId
    ) internal view returns (bytes32, bytes32) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _NICR >= _cdpManager.getNominalICR(_startId)) {
            return (dummyId, _startId);
        }

        bytes32 prevId = _startId;
        bytes32 nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != dummyId && !_validInsertPosition(_cdpManager, _NICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
     * @param _cdpManager CdpManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(
        ICdpManager _cdpManager,
        uint256 _NICR,
        bytes32 _startId
    ) internal view returns (bytes32, bytes32) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _NICR <= _cdpManager.getNominalICR(_startId)) {
            return (_startId, dummyId);
        }

        bytes32 nextId = _startId;
        bytes32 prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != dummyId && !_validInsertPosition(_cdpManager, _NICR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Find the insert position for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     * @return The IDs of the previous and next nodes for the insert position
     */
    function findInsertPosition(
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view override returns (bytes32, bytes32) {
        return _findInsertPosition(cdpManager, _NICR, _prevId, _nextId);
    }

    function _findInsertPosition(
        ICdpManager _cdpManager,
        uint256 _NICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) internal view returns (bytes32, bytes32) {
        bytes32 prevId = _prevId;
        bytes32 nextId = _nextId;

        if (prevId != dummyId) {
            if (!contains(prevId) || _NICR > _cdpManager.getNominalICR(prevId)) {
                // `prevId` does not exist anymore or now has a smaller NICR than the given NICR
                prevId = dummyId;
            }
        }

        if (nextId != dummyId) {
            if (!contains(nextId) || _NICR < _cdpManager.getNominalICR(nextId)) {
                // `nextId` does not exist anymore or now has a larger NICR than the given NICR
                nextId = dummyId;
            }
        }

        if (prevId == dummyId && nextId == dummyId) {
            // No hint - descend list starting from head
            return _descendList(_cdpManager, _NICR, data.head);
        } else if (prevId == dummyId) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_cdpManager, _NICR, nextId);
        } else if (nextId == dummyId) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_cdpManager, _NICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_cdpManager, _NICR, prevId);
        }
    }

    // --- 'require' functions ---

    /// @dev Asserts that the caller of the function is the CdpManager
    function _requireCallerIsCdpManager() internal view {
        require(msg.sender == address(cdpManager), "SortedCdps: Caller is not the CdpManager");
    }

    /// @dev Asserts that the caller of the function is either the BorrowerOperations contract or the CdpManager
    function _requireCallerIsBOorCdpM() internal view {
        require(
            msg.sender == borrowerOperationsAddress || msg.sender == address(cdpManager),
            "SortedCdps: Caller is neither BO nor CdpM"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralTokenOracle {
    // Return beacon specification data.
    function getBeaconSpec()
        external
        view
        returns (
            uint64 epochsPerFrame,
            uint64 slotsPerEpoch,
            uint64 secondsPerSlot,
            uint64 genesisTime
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 *
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to
     * a value in the near future. The deadline argument can be set to uint(-1) to
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);

    function version() external view returns (string memory);

    function permitTypeHash() external view returns (bytes32);

    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolEBTCDebtUpdated(uint _EBTCDebt);
    event ActivePoolCollBalanceUpdated(uint _coll);
    event CollateralAddressChanged(address _collTokenAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusAddress);
    event ActivePoolFeeRecipientClaimableCollIncreased(uint _coll, uint _fee);
    event ActivePoolFeeRecipientClaimableCollDecreased(uint _coll, uint _fee);
    event FlashLoanSuccess(address _receiver, address _token, uint _amount, uint _fee);
    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Functions ---
    function sendStEthColl(address _account, uint _amount) external;

    function receiveColl(uint _value) external;

    function sendStEthCollAndLiquidatorReward(
        address _account,
        uint _shares,
        uint _liquidatorRewardShares
    ) external;

    function allocateFeeRecipientColl(uint _shares) external;

    function claimFeeRecipientColl(uint _shares) external;

    function feeRecipientAddress() external view returns (address);

    function getFeeRecipientClaimableColl() external view returns (uint);

    function setFeeRecipientAddress(address _feeRecipientAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the Cdp Manager.
interface IBorrowerOperations {
    // --- Events ---

    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event SortedCdpsAddressChanged(address _sortedCdpsAddress);
    event EBTCTokenAddressChanged(address _ebtcTokenAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollateralAddressChanged(address _collTokenAddress);
    event FlashLoanSuccess(address _receiver, address _token, uint _amount, uint _fee);

    event CdpCreated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        address indexed _creator,
        uint arrayIndex
    );
    event CdpUpdated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _oldDebt,
        uint _oldColl,
        uint _debt,
        uint _coll,
        uint _stake,
        BorrowerOperation _operation
    );

    enum BorrowerOperation {
        openCdp,
        closeCdp,
        adjustCdp
    }

    // --- Functions ---

    function openCdp(
        uint _EBTCAmount,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount
    ) external returns (bytes32);

    function addColl(
        bytes32 _cdpId,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAmount
    ) external;

    function withdrawColl(
        bytes32 _cdpId,
        uint _amount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function withdrawEBTC(
        bytes32 _cdpId,
        uint _amount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function repayEBTC(
        bytes32 _cdpId,
        uint _amount,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function closeCdp(bytes32 _cdpId) external;

    function adjustCdp(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _debtChange,
        bool isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint
    ) external;

    function adjustCdpWithColl(
        bytes32 _cdpId,
        uint _collWithdrawal,
        uint _debtChange,
        bool isDebtIncrease,
        bytes32 _upperHint,
        bytes32 _lowerHint,
        uint _collAddAmount
    ) external;

    function claimCollateral() external;

    function feeRecipientAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ILiquityBase.sol";
import "./IEBTCToken.sol";
import "./IFeeRecipient.sol";
import "./ICollSurplusPool.sol";
import "./ICdpManagerData.sol";

// Common interface for the Cdp Manager.
interface ICdpManager is ILiquityBase, ICdpManagerData {
    // --- Functions ---
    function getCdpIdsCount() external view returns (uint);

    function getIdFromCdpIdsArray(uint _index) external view returns (bytes32);

    function getNominalICR(bytes32 _cdpId) external view returns (uint);

    function getCurrentICR(bytes32 _cdpId, uint _price) external view returns (uint);

    function liquidate(bytes32 _cdpId) external;

    function partiallyLiquidate(
        bytes32 _cdpId,
        uint256 _partialAmount,
        bytes32 _upperPartialHint,
        bytes32 _lowerPartialHint
    ) external;

    function liquidateCdps(uint _n) external;

    function batchLiquidateCdps(bytes32[] calldata _cdpArray) external;

    function redeemCollateral(
        uint _EBTCAmount,
        bytes32 _firstRedemptionHint,
        bytes32 _upperPartialRedemptionHint,
        bytes32 _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external;

    function updateStakeAndTotalStakes(bytes32 _cdpId) external returns (uint);

    function updateCdpRewardSnapshots(bytes32 _cdpId) external;

    function addCdpIdToArray(bytes32 _cdpId) external returns (uint index);

    function applyPendingRewards(bytes32 _cdpId) external;

    function getTotalStakeForFeeTaken(uint _feeTaken) external view returns (uint, uint);

    function syncUpdateIndexInterval() external returns (uint);

    function getPendingEBTCDebtReward(bytes32 _cdpId) external view returns (uint);

    function hasPendingRewards(bytes32 _cdpId) external view returns (bool);

    function getEntireDebtAndColl(
        bytes32 _cdpId
    ) external view returns (uint debt, uint coll, uint pendingEBTCDebtReward);

    function closeCdp(bytes32 _cdpId) external;

    function removeStake(bytes32 _cdpId) external;

    function getRedemptionRate() external view returns (uint);

    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint EBTCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _EBTCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getCdpStatus(bytes32 _cdpId) external view returns (uint);

    function getCdpStake(bytes32 _cdpId) external view returns (uint);

    function getCdpDebt(bytes32 _cdpId) external view returns (uint);

    function getCdpColl(bytes32 _cdpId) external view returns (uint);

    function getCdpLiquidatorRewardShares(bytes32 _cdpId) external view returns (uint);

    function setCdpStatus(bytes32 _cdpId, uint num) external;

    function increaseCdpColl(bytes32 _cdpId, uint _collIncrease) external returns (uint);

    function decreaseCdpColl(bytes32 _cdpId, uint _collDecrease) external returns (uint);

    function increaseCdpDebt(bytes32 _cdpId, uint _debtIncrease) external returns (uint);

    function decreaseCdpDebt(bytes32 _cdpId, uint _collDecrease) external returns (uint);

    function setCdpLiquidatorRewardShares(bytes32 _cdpId, uint _liquidatorRewardShares) external;

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICollSurplusPool.sol";
import "./IEBTCToken.sol";
import "./ISortedCdps.sol";
import "./IActivePool.sol";
import "../Dependencies/ICollateralTokenOracle.sol";

// Common interface for the Cdp Manager.
interface ICdpManagerData {
    // --- Events ---

    event LiquidationLibraryAddressChanged(address _liquidationLibraryAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event EBTCTokenAddressChanged(address _newEBTCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedCdpsAddressChanged(address _sortedCdpsAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollateralAddressChanged(address _collTokenAddress);
    event StakingRewardSplitSet(uint256 _stakingRewardSplit);
    event RedemptionFeeFloorSet(uint256 _redemptionFeeFloor);
    event MinuteDecayFactorSet(uint256 _minuteDecayFactor);
    event BetaSet(uint256 _beta);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _liqReward);
    event Redemption(uint _attemptedEBTCAmount, uint _actualEBTCAmount, uint _ETHSent, uint _ETHFee);
    event CdpUpdated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _oldDebt,
        uint _oldColl,
        uint _debt,
        uint _coll,
        uint _stake,
        CdpManagerOperation _operation
    );
    event CdpLiquidated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _debt,
        uint _coll,
        CdpManagerOperation _operation
    );
    event CdpPartiallyLiquidated(
        bytes32 indexed _cdpId,
        address indexed _borrower,
        uint _debt,
        uint _coll,
        CdpManagerOperation operation
    );
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_EBTCDebt);
    event CdpSnapshotsUpdated(bytes32 _cdpId, uint _L_EBTCDebt);
    event CdpIndexUpdated(bytes32 _cdpId, uint _newIndex);
    event CollateralGlobalIndexUpdated(uint _oldIndex, uint _newIndex, uint _updTimestamp);
    event CollateralIndexUpdateIntervalUpdated(uint _oldInterval, uint _newInterval);
    event CollateralFeePerUnitUpdated(uint _oldPerUnit, uint _newPerUnit, uint _feeTaken);
    event CdpFeeSplitApplied(
        bytes32 _cdpId,
        uint _oldPerUnitCdp,
        uint _newPerUnitCdp,
        uint _collReduced,
        uint collLeft
    );

    enum CdpManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral,
        partiallyLiquidate
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a cdp
    struct Cdp {
        uint debt;
        uint coll;
        uint stake;
        uint liquidatorRewardShares;
        Status status;
        uint128 arrayIndex;
    }

    /*
     * --- Variable container structs for liquidations ---
     *
     * These structs are used to hold, return and assign variables inside the liquidation functions,
     * in order to avoid the error: "CompilerError: Stack too deep".
     **/

    struct LocalVar_CdpDebtColl {
        uint256 entireDebt;
        uint256 entireColl;
        uint256 pendingDebtReward;
    }

    struct LocalVar_InternalLiquidate {
        bytes32 _cdpId;
        uint256 _partialAmount; // used only for partial liquidation, default 0 means full liquidation
        uint256 _price;
        uint256 _ICR;
        bytes32 _upperPartialHint;
        bytes32 _lowerPartialHint;
        bool _recoveryModeAtStart;
        uint256 _TCR;
        uint256 totalColSurplus;
        uint256 totalColToSend;
        uint256 totalDebtToBurn;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;
        bool sequenceLiq;
    }

    struct LocalVar_RecoveryLiquidate {
        uint256 entireSystemDebt;
        uint256 entireSystemColl;
        uint256 totalDebtToBurn;
        uint256 totalColToSend;
        uint256 totalColSurplus;
        bytes32 _cdpId;
        uint256 _price;
        uint256 _ICR;
        uint256 totalDebtToRedistribute;
        uint256 totalColReward;
        bool sequenceLiq;
    }

    struct LocalVariables_OuterLiquidationFunction {
        uint price;
        bool recoveryModeAtStart;
        uint liquidatedDebt;
        uint liquidatedColl;
    }

    struct LocalVariables_LiquidationSequence {
        uint i;
        uint ICR;
        bytes32 cdpId;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
        uint price;
        uint TCR;
    }

    struct LocalVariables_RedeemCollateralFromCdp {
        bytes32 _cdpId;
        uint _maxEBTCamount;
        uint _price;
        bytes32 _upperPartialRedemptionHint;
        bytes32 _lowerPartialRedemptionHint;
        uint _partialRedemptionHintNICR;
    }

    struct LiquidationValues {
        uint entireCdpDebt;
        uint debtToOffset;
        uint totalCollToSendToLiquidator;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
        uint collReward;
    }

    struct LiquidationTotals {
        uint totalDebtInSequence;
        uint totalDebtToOffset;
        uint totalCollToSendToLiquidator;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
        uint totalCollReward;
    }

    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingEBTC;
        uint totalEBTCToRedeem;
        uint totalETHDrawn;
        uint ETHFee;
        uint ETHToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalEBTCSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint eBtcToRedeem;
        uint stEthToRecieve;
        bool cancelledPartial;
        bool fullRedemption;
    }

    function totalStakes() external view returns (uint);

    function ebtcToken() external view returns (IEBTCToken);

    function stFeePerUnitg() external view returns (uint);

    function stFeePerUnitgError() external view returns (uint);

    function stFPPSg() external view returns (uint);

    function calcFeeUponStakingReward(
        uint256 _newIndex,
        uint256 _prevIndex
    ) external view returns (uint256, uint256, uint256);

    function claimStakingSplitFee() external;

    function getAccumulatedFeeSplitApplied(
        bytes32 _cdpId,
        uint _stFeePerUnitg,
        uint _stFeePerUnitgError,
        uint _totalStakes
    ) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollSurplusPool {
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralAddressChanged(address _collTokenAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event CollateralSent(address _to, uint _amount);

    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Contract setters ---

    function getStEthColl() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;

    function receiveColl(uint _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../Dependencies/IERC20.sol";
import "../Dependencies/IERC2612.sol";

interface IEBTCToken is IERC20, IERC2612 {
    // --- Events ---

    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event EBTCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeRecipient {
    // --- Events --

    event EBTCTokenAddressSet(address _ebtcTokenAddress);
    event CdpManagerAddressSet(address _cdpManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);
    event CollateralAddressSet(address _collTokenAddress);

    event ReceiveFee(address indexed _sender, address indexed _token, uint _amount);
    event CollateralSent(address _account, uint _amount);

    // --- Functions ---

    function receiveStEthFee(uint _ETHFee) external;

    function receiveEbtcFee(uint _EBTCFee) external;

    function claimStakingSplitFee() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPriceFeed.sol";

interface ILiquityBase {
    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the Pools.
interface IPool {
    // --- Events ---

    event ETHBalanceUpdated(uint _newBalance);
    event EBTCBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralSent(address _to, uint _amount);

    // --- Functions ---

    function getStEthColl() external view returns (uint);

    function getEBTCDebt() external view returns (uint);

    function increaseEBTCDebt(uint _amount) external;

    function decreaseEBTCDebt(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
    event PriceFeedStatusChanged(Status newStatus);
    event FallbackCallerChanged(address _oldFallbackCaller, address _newFallbackCaller);
    event UnhealthyFallbackCaller(address _fallbackCaller, uint256 timestamp);

    // --- Structs ---

    struct ChainlinkResponse {
        uint80 roundEthBtcId;
        uint80 roundStEthEthId;
        uint256 answer;
        uint256 timestampEthBtc;
        uint256 timestampStEthEth;
        bool success;
    }

    struct FallbackResponse {
        uint256 answer;
        uint256 timestamp;
        bool success;
    }

    // --- Enum ---

    enum Status {
        chainlinkWorking,
        usingFallbackChainlinkUntrusted,
        bothOraclesUntrusted,
        usingFallbackChainlinkFrozen,
        usingChainlinkFallbackUntrusted
    }

    // --- Function ---
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the SortedCdps Doubly Linked List.
interface ISortedCdps {
    // --- Events ---

    event CdpManagerAddressChanged(address _cdpManagerAddress);
    event SortedCdpsAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(bytes32 _id, uint _NICR);
    event NodeRemoved(bytes32 _id);

    // --- Functions ---

    function remove(bytes32 _id) external;

    function batchRemove(bytes32[] memory _ids) external;

    function reInsert(bytes32 _id, uint256 _newICR, bytes32 _prevId, bytes32 _nextId) external;

    function contains(bytes32 _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (bytes32);

    function getLast() external view returns (bytes32);

    function getNext(bytes32 _id) external view returns (bytes32);

    function getPrev(bytes32 _id) external view returns (bytes32);

    function validInsertPosition(
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view returns (bool);

    function findInsertPosition(
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external view returns (bytes32, bytes32);

    function insert(
        address owner,
        uint256 _ICR,
        bytes32 _prevId,
        bytes32 _nextId
    ) external returns (bytes32);

    function getOwnerAddress(bytes32 _id) external pure returns (address);

    function existCdpOwners(bytes32 _id) external view returns (address);

    function nonExistId() external view returns (bytes32);

    function cdpCountOf(address owner) external view returns (uint256);

    function getCdpsOf(address owner) external view returns (bytes32[] memory);

    function cdpOfOwnerByIndex(address owner, uint256 index) external view returns (bytes32);

    // Mapping from cdp owner to list of owned cdp IDs
    // mapping(address => mapping(uint256 => bytes32)) public _ownedCdps;
    function _ownedCdps(address, uint256) external view returns (bytes32);

    // Mapping from cdp ID to index within owner cdp list
    // mapping(bytes32 => uint256) public _ownedCdpIndex;
    function _ownedCdpIndex(bytes32) external view returns (uint256);

    // Mapping from cdp owner to its owned cdps count
    // mapping(address => uint256) public _ownedCount;
    function _ownedCount(address) external view returns (uint256);
}