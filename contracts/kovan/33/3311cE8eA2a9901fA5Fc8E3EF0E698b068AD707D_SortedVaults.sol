/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: CheckContract

contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// Part: IPriceFeed

interface IPriceFeed {
    // -- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // ---Function---
    function fetchPrice() external view returns (uint);
}

// Part: ISortedVaults

// Common interface for the SortedVaults Doubly Linked List.
interface ISortedVaults {

    // --- Events ---
    
    event SortedVaultsAddressChanged(address _sortedDoublyLinkedListAddress);
    event BorrowerOpsAddressChanged(address _borrowerOpsAddress);
    event VaultManagerAddressChanged(address _vaultManagerAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _VaultManagerAddress, address _borrowerOpsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// Part: OpenZeppelin/[email protected]/Context

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

// Part: IOrumBase

interface IOrumBase {
    function priceFeed() external view returns (IPriceFeed);
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// Part: IVaultManager

// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event USDCTokenAddressChanged(address _newUSDCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oETHTokenAddressChanged(address _newoETHTokenAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _USDCGasCompensation);
    event Test_LiquidationoETHFee(uint _oETHFee);
    event Redemption(uint _attemptedUSDCAmount, uint _actualUSDCAmount, uint _oETHSent, uint _oETHFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event VaultIndexUpdated(address _borrower, uint _newIndex);
    event TEST_error(uint _debtInoETH, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);
    event TEST_offsetValues(uint _debtInoETH, uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint _totalCollProfit, uint _stakingRToRedistribute);
    event Coll_getOffsetValues(uint _debt, uint _coll, uint _stakingRToRedistribute);
    event LTermsUpdated(uint _L_STAKINGR);
    event VaultSnapshotsUpdated(uint L_STAKINGR);
    event SystemSnapshotsUpdated(uint totalStakesSnapshot, uint totalCollateralSnapshot);
    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external; 

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll,
        uint pendingStakingReward
    );

    function closeVault(address _borrower) external;

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint USDCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _USDCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);

    function applyStakingRewards(address _borrower) external;

    function updateVaultRewardSnapshots(address _borrower) external;

    function getPendingStakingoethReward(address _borrower) external view returns (uint);

    function removeStake(address _borrower) external;

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function redistributeStakingRewards(uint _coll) external;

    
}

// File: SortedVaults.sol

/*
* A sorted doubly linked list with nodes sorted in descending order.
*
* Nodes map to active Vaults in the system - the ID property is the address of a Vault owner.
* Nodes are ordered according to their current nominal individual collateral ratio (NICR),
* which is like the ICR but without the price, i.e., just collateral / debt.
*
* The list optionally accepts insert position hints.
*
* NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Vaults
* change dynamically as liquidation events occur.
*
* The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Vaults,
* but maintains their order. A node inserted based on current NICR will maintain the correct position,
* relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
* Thus, Nodes remain sorted by current NICR.
*
* Nodes need only be re-inserted upon a Vault operation - when the owner adds or removes collateral or debt
* to their position.
*
* The list is a modification of the following audited SortedDoublyLinkedList:
* https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
*
*
* Changes made in the Orum implementation:
*
* - Keys have been removed from nodes
*
* - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
*   The list relies on the property that ordering by ICR is maintained as the oETH:USD price varies.
*
* - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
*/
contract SortedVaults is Ownable, CheckContract, ISortedVaults {

    string constant public NAME = "SortedVaults";
    
    address public borrowerOpsAddress;

    IVaultManager public vaultManager;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId;                  // Id of next node (smaller NICR) in the list
        address prevId;                  // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest NICR
        address tail;                        // Tail of the list. Also the node in the list with the smallest NICR
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    Data public data;

    // --- Dependency setters ---

    function setParams(uint256 _size, address _vaultManagerAddress, address _borrowerOpsAddress) external override onlyOwner {
        require(_size > 0, "SortedVaults: Size cannot be zero");
        checkContract(_vaultManagerAddress);
        checkContract(_borrowerOpsAddress);

        data.maxSize = _size;

        vaultManager = IVaultManager(_vaultManagerAddress);
        borrowerOpsAddress = _borrowerOpsAddress;

        emit VaultManagerAddressChanged(_vaultManagerAddress);
        emit BorrowerOpsAddressChanged(_borrowerOpsAddress);
    }

    /*
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function insert (address _id, uint256 _NICR, address _prevId, address _nextId) external override {
        IVaultManager vaultManagerCached = vaultManager;

        _requireCallerIsBOorVaultM(vaultManagerCached);
        _insert(vaultManagerCached, _id, _NICR, _prevId, _nextId);
    }

    function _insert(IVaultManager _vaultManager, address _id, uint256 _NICR, address _prevId, address _nextId) internal {
        // List must not be full
        require(!isFull(), "SortedVaults: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedVaults: List already contains the node");
        // Node id must not be null
        require(_id != address(0), "SortedVaults: Id cannot be zero");
        // NICR must be non-zero
        require(_NICR > 0, "SortedVaults: NICR must be positive");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!_validInsertPosition(_vaultManager, _NICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_vaultManager, _NICR, prevId, nextId);
        }

         data.nodes[_id].exists = true;

        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            data.nodes[_id].nextId = data.head;
            data.nodes[data.head].prevId = _id;
            data.head = _id;
        } else if (nextId == address(0)) {
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

        data.size += 1;
        emit NodeAdded(_id, _NICR);
    }

    function remove(address _id) external override {
        _requireCallerIsVaultManager();
        _remove(_id);
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(address _id) internal {
        // List must contain the node
        require(contains(_id), "SortedVaults: List does not contain the id");

        if (data.size > 1) {
            // List contains more than a single node
            if (_id == data.head) {
                // The removed node is the head
                // Set head to next node
                data.head = data.nodes[_id].nextId;
                // Set prev pointer of new head to null
                data.nodes[data.head].prevId = address(0);
            } else if (_id == data.tail) {
                // The removed node is the tail
                // Set tail to previous node
                data.tail = data.nodes[_id].prevId;
                // Set next pointer of new tail to null
                data.nodes[data.tail].nextId = address(0);
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
            data.head = address(0);
            data.tail = address(0);
        }

        delete data.nodes[_id];
        data.size -= 1;
        emit NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new NICR
     * @param _id Node's id
     * @param _newNICR Node's new NICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(address _id, uint256 _newNICR, address _prevId, address _nextId) external override {
        IVaultManager vaultManagerCached = vaultManager;

        _requireCallerIsBOorVaultM(vaultManagerCached);
        // List must contain the node
        require(contains(_id), "SortedVaults: List does not contain the id");
        // NICR must be non-zero
        require(_newNICR > 0, "SortedVaults: NICR must be positive");

        // Remove node from the list
        _remove(_id);

        _insert(vaultManagerCached, _id, _newNICR, _prevId, _nextId);
    }

    /*
     * @dev Checks if the list contains a node
     */
    function contains(address _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    /*
     * @dev Checks if the list is full
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /*
     * @dev Returns the maximum size of the list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /*
     * @dev Returns the first node in the list (node with the largest NICR)
     */
    function getFirst() external view override returns (address) {
        return data.head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest NICR)
     */
    function getLast() external view override returns (address) {
        return data.tail;
    }

    /*
     * @dev Returns the next node (with a smaller NICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id) external view override returns (address) {
        return data.nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger NICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id) external view override returns (address) {
        return data.nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function validInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view override returns (bool) {
        return _validInsertPosition(vaultManager, _NICR, _prevId, _nextId);
    }

    function _validInsertPosition(IVaultManager _vaultManager, uint256 _NICR, address _prevId, address _nextId) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _NICR >= _vaultManager.getNominalICR(_nextId);
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _NICR <= _vaultManager.getNominalICR(_prevId);
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
            return data.nodes[_prevId].nextId == _nextId &&
                   _vaultManager.getNominalICR(_prevId) >= _NICR &&
                   _NICR >= _vaultManager.getNominalICR(_nextId);
        }
    }

    /*
     * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
     * @param _vaultManager VaultManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(IVaultManager _vaultManager, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _NICR >= _vaultManager.getNominalICR(_startId)) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_vaultManager, _NICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
     * @param _vaultManager VaultManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(IVaultManager _vaultManager, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _NICR <= _vaultManager.getNominalICR(_startId)) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_vaultManager, _NICR, prevId, nextId)) {
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
     */
    function findInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view override returns (address, address) {
        return _findInsertPosition(vaultManager, _NICR, _prevId, _nextId);
    }

    function _findInsertPosition(IVaultManager _vaultManager, uint256 _NICR, address _prevId, address _nextId) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _NICR > _vaultManager.getNominalICR(prevId)) {
                // `prevId` does not exist anymore or now has a smaller NICR than the given NICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _NICR < _vaultManager.getNominalICR(nextId)) {
                // `nextId` does not exist anymore or now has a larger NICR than the given NICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_vaultManager, _NICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_vaultManager, _NICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_vaultManager, _NICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_vaultManager, _NICR, prevId);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsVaultManager() internal view {
        require(msg.sender == address(vaultManager), "SortedVaults: Caller is not the VaultManager");
    }

    function _requireCallerIsBOorVaultM(IVaultManager _vaultManager) internal view {
        require(msg.sender == borrowerOpsAddress || msg.sender == address(_vaultManager),
                "SortedVaults: Caller is neither BO nor VaultM");
    }
}