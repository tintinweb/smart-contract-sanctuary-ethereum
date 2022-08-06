// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../farmentities/FarmEmpRole.sol";
import "../farmentities/FarmDistributorRole.sol";
import "../farmentities/FarmRetailerRole.sol";
import "../farmowner/Ownable.sol";

error Not__AnEmployee();
error Incorrect__ContainerId();
error Incorrect__WarehouseId();

contract SupplyChain is FarmEmpRole, FarmDistributorRole, FarmRetailerRole {
    /* Type declaartion */
    enum State {
        FARMING,
        BATCHED,
        INCONTAINER,
        WITHDISTRIBUTOR,
        WITHRETAILER,
        SOLD
    }

    /*State variables */
    uint256 private barnID = 0;
    uint256 private batchID = 0;
    uint256 private containerID = 0;
    uint256[] private allBarnIDS;
    uint256[] private allBatchIDS;
    uint256[] private allContainersIDS;
    Barn[] private barns;
    Batch[] private batches;
    Container[] private containersList;
    Warehouse[] private warehouseList;
    Product[] private products;
    uint256[] wareHouseIDS = [1, 2, 3];

    struct Barn {
        uint256 barnID;
        address owner;
        address farmEmp;
        string farmName;
        string farmLatitude;
        string farmLongitude;
        State batchState;
        uint256 temperature;
        uint256 humidity;
        uint256 airQuality;
        uint256 createdAt;
    }

    struct Batch {
        uint256 barnID;
        uint256 batchID;
        State batchState;
        uint256 nosOfProducts;
        uint256 createdAt;
    }

    struct Container {
        uint256 barnID;
        uint256 batchID;
        uint256 containerID;
        uint256 wareHouseID;
        uint256 temperature;
        uint256 humidity;
        uint256 airQuality;
        address distributor;
        address retailer;
        State batchState;
        uint256 createdAt;
        uint256 orderReceievedAt;
    }

    struct Warehouse {
        uint256 warehouseID;
        uint256 c_id;
        bool isDispatched;
        uint256 createdAt;
    }

    struct Product {
        uint256 productId;
        uint256 barnID;
        uint256 batchID;
        string mfgDate;
        string expiryDate;
        uint256 mrp;
        uint256 createdAt;
    }

    /*Events*/
    event BarnCreated(uint256 indexed barnID);
    event Batched(uint256 indexed barnID, uint256 indexed batchID);
    event Incontainer(uint256 indexed barnID, uint256 indexed batchID, uint256 indexed containerID);
    event WithDistributor(address indexed distributor, uint256 indexed containerID);
    event InWarehouse(uint256 indexed warehouseID, uint256 indexed containerID);
    event assignedRetailer(address indexed retailer, uint256 indexed containerID);

    function createBarn(
        address _farmEmp,
        string memory _farmName,
        string memory _farmLatitude,
        string memory _farmLongitude
    ) public onlyOwner {
        if (isEmployee(_farmEmp)) {
            barns.push(
                Barn(
                    barnID,
                    msg.sender,
                    _farmEmp,
                    _farmName,
                    _farmLatitude,
                    _farmLongitude,
                    State.FARMING,
                    0,
                    0,
                    0,
                    block.timestamp
                )
            );

            emit BarnCreated(barnID);
            allBarnIDS.push(barnID);
            barnID++;
        } else {
            revert Not__AnEmployee();
        }
    }

    function getBarnLength() public view returns (uint256) {
        return barns.length;
    }

    function createBatch(
        uint256 _barnID,
        string memory _mfgD,
        string memory _expiry,
        uint256 _mrp,
        uint256 _nosOfProducts
    ) public onlyEmployee {
        require(allBarnIDS[_barnID] == _barnID, "BarnID doesnt exists");
        batches.push(Batch(_barnID, batchID, State.BATCHED, _nosOfProducts, block.timestamp));
        allBatchIDS.push(batchID);
        emit Batched(_barnID, batchID);
        barns[_barnID].batchState = State.BATCHED;
        createProducts(_barnID, batchID, _mfgD, _expiry, _mrp, _nosOfProducts);
        batchID++;
    }

    function createProducts(
        uint256 _barnId,
        uint256 _batchId,
        string memory _mfgD,
        string memory _expiry,
        uint256 _mrp,
        uint256 _nosOfProducts
    ) internal {
        for (uint256 i = 1; i <= _nosOfProducts; i++) {
            products.push(Product(i, _barnId, _batchId, _mfgD, _expiry, _mrp, block.timestamp));
        }
    }

    function getBatchesLength() public view returns (uint256) {
        return batches.length;
    }

    function inContainer(
        uint256 _barnID,
        uint256 _batchID,
        uint256 _wareHouseID
    ) public onlyEmployee {
        require(allBatchIDS[_batchID] == _batchID, "BatchID doesnt exist");
        containersList.push(
            Container(
                _barnID,
                _batchID,
                containerID,
                _wareHouseID,
                0,
                0,
                0,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                State.INCONTAINER,
                block.timestamp,
                0
            )
        );
        allContainersIDS.push(containerID);
        emit Incontainer(_barnID, _batchID, containerID);
        batches[_batchID].batchState = State.INCONTAINER;
        storeInWarehouse(containerID, _wareHouseID);
        containerID++;
    }

    function storeInWarehouse(uint256 _containerID, uint256 _wareHouseID) internal {
        require(allContainersIDS[_containerID] == _containerID, "BatchID doesnt exist");
        warehouseList.push(Warehouse(_wareHouseID, _containerID, false, block.timestamp));
        emit InWarehouse(_wareHouseID, containerID);
    }

    function createOrder(uint256 _containerID) public onlyDistributor {
        containersList[_containerID].distributor = msg.sender;
        containersList[_containerID].batchState = State.WITHDISTRIBUTOR;
        containersList[_containerID].orderReceievedAt = block.timestamp;
        //  uint256 indexToBeRemoved = containerIdTowarehouseIndex[_containerID];
        // delete warehouse[indexToBeRemoved];
        //warehouseIndex--;
        emit WithDistributor(msg.sender, _containerID);
        uint256 w_id = containersList[_containerID].wareHouseID;
        dispatch(_containerID, w_id);
    }

    function dispatch(uint256 _containerID, uint256 _warehouseID) internal {
        for (uint256 i = 0; i < warehouseList.length; i++) {
            if (warehouseList[i].warehouseID == _warehouseID) {
                if (warehouseList[i].c_id == _containerID) {
                    warehouseList[_warehouseID].isDispatched = true;
                } else {
                    revert Incorrect__WarehouseId();
                }
            } else {
                revert Incorrect__ContainerId();
            }
        }
    }

    function assignRetailer(uint256 _containerID, address _retailer) public onlyDistributor {
        containersList[_containerID].retailer = _retailer;
        containersList[_containerID].batchState = State.WITHRETAILER;
        emit assignedRetailer(_retailer, _containerID);
    }

    // function inWareHouse(uint256 _containerID) internal {
    //     warehouse.push(_containerID);
    //     containerIdTowarehouseIndex[_containerID] = warehouseIndex;
    //     warehouseIndex++;
    // }

    function getContainerArrayLength() public view returns (uint256) {
        return containersList.length;
    }

    function getBarnsArray() public view returns (Barn[] memory) {
        return barns;
    }

    function getBatchesArray() public view returns (Batch[] memory) {
        return batches;
    }

    function getContainersArray() public view returns (Container[] memory) {
        return containersList;
    }

    function getWarehouseArray() public view returns (Warehouse[] memory) {
        return warehouseList;
    }

    function getWarehouseId() public view returns (uint256[] memory) {
        return wareHouseIDS;
    }

    // function getProductsByBatchID(uint256 _batchID) public returns (Product[] memory) {
    //     uint256 resultCount;

    //     for (uint256 i = 0; i < products.length; i++) {
    //         if (products[i].batchID == _batchID) {
    //             resultCount++;
    //         }
    //     }

    //     Product[] memory result = new Product[](resultCount);
    //     uint256 j;

    //     for (uint256 i = 0; i < products.length; i++) {
    //         if (products[i].batchID == _batchID) {
    //             result[j] = products[i];
    //             j++;
    //         }
    //     }

    //     return result;
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Roles.sol";
import "../farmowner/Ownable.sol";

contract FarmEmpRole is Ownable {
    using Roles for Roles.Role;

    /*events*/
    event EmployeeAdded(address indexed account);
    event EmployeeRemoved(address indexed account);

    /*State variables */
    Roles.Role private employees;
    address[] private allEmployees;

    modifier onlyEmployee() {
        require(isEmployee(msg.sender), "Caller is not a employeee");
        _;
    }

    function isEmployee(address account) public view returns (bool) {
        return employees.hasRole(account);
    }

    function addEmployee(address account) public onlyOwner {
        _addEmployee(account);
    }

    function _addEmployee(address account) internal {
        employees.addRole(account);
        allEmployees.push(account);
        emit EmployeeAdded(account);
    }

    function removeEmployee(address account) public onlyOwner {
        _removeEmployee(account);
    }

    function _removeEmployee(address account) internal {
        employees.removeRole(account);
        for (uint256 i = 0; i < allEmployees.length; i++) {
            if (allEmployees[i] == account) {
                allEmployees[i] = 0x0000000000000000000000000000000000000000;
            }
        }
        emit EmployeeRemoved(account);
    }

    function getAllEmployess() public view returns (address[] memory) {
        return allEmployees;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Roles.sol";
import "../farmowner/Ownable.sol";

contract FarmDistributorRole is Ownable {
    using Roles for Roles.Role;

    /*events*/
    event DistributorAdded(address indexed account);
    event DistributorRemoved(address indexed account);

    Roles.Role private distributors;
    address[] allDistributors;

    modifier onlyDistributor() {
        require(isDistributor(msg.sender), "Caller is not a Distributor");
        _;
    }

    function isDistributor(address account) public view returns (bool) {
        return distributors.hasRole(account);
    }

    function addDistributor(address account) public onlyOwner {
        _addDistributor(account);
    }

    function _addDistributor(address account) internal {
        distributors.addRole(account);
        allDistributors.push(account);
        emit DistributorAdded(account);
    }

    function removeDistributor(address account) public onlyOwner {
        _removeDistributor(account);
    }

    function _removeDistributor(address account) internal {
        distributors.removeRole(account);
        for (uint256 i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i] == account) {
                allDistributors[i] = 0x0000000000000000000000000000000000000000;
            }
        }
        emit DistributorRemoved(account);
    }

    function getAllDistributor() public view returns (address[] memory) {
        return allDistributors;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Roles.sol";
import "../farmowner/Ownable.sol";

contract FarmRetailerRole is Ownable {
    using Roles for Roles.Role;

    /*events*/
    event RetailerAdded(address indexed account);
    event RetailerRemoved(address indexed account);

    /*State variables */
    address[] private allRetailers;
    Roles.Role private retailers;

    modifier onlyRetailer() {
        require(isRetailer(msg.sender), "Caller is not a retailer");
        _;
    }

    function isRetailer(address account) public view returns (bool) {
        return retailers.hasRole(account);
    }

    function addRetailer(address account) public onlyOwner {
        _addRetailer(account);
    }

    function _addRetailer(address account) internal {
        retailers.addRole(account);
        allRetailers.push(account);
        emit RetailerAdded(account);
    }

    function removeRetailer(address account) public onlyOwner {
        _removeRetailer(account);
    }

    function _removeRetailer(address account) internal {
        retailers.removeRole(account);
        for (uint256 i = 0; i < allRetailers.length; i++) {
            if (allRetailers[i] == account) {
                allRetailers[i] = 0x0000000000000000000000000000000000000000;
            }
        }
        emit RetailerRemoved(account);
    }

    function getRetailers() public view returns (address[] memory) {
        return allRetailers;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Ownable {
    /*state variables */
    address private s_owner;

    /*events*/
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    constructor() {
        s_owner = msg.sender;
        emit TransferOwnership(address(0), s_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "Only contract owner can call this function");
        _;
    }

    function getOwner() public view returns (address) {
        return s_owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Only owner can call this function");
        s_owner = newOwner;
        emit TransferOwnership(s_owner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function addRole(Role storage role, address account) internal {
        require(account != address(0), "Not a valid address");
        require(!hasRole(role, account), "verify account does not have this role");

        role.bearer[account] = true;
    }

    function removeRole(Role storage role, address account) internal {
        require(account != address(0), "Not a valid address");
        require(!hasRole(role, account), "verify account does not have this role");
        role.bearer[account] = false;
    }

    function hasRole(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Account is not verified");
        return role.bearer[account];
    }
}