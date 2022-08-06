// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../farmentities/FarmEmpRole.sol";
import "../farmentities/FarmSupplierRole.sol";
import "../farmentities/FarmRetailerRole.sol";
import "../farmowner/Ownable.sol";

error Not__AnEmployee();

contract SupplyChain is FarmEmpRole, FarmerSupplierRole, FarmRetailerRole {
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
    Container[] private containers;

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
    }

    struct Batch {
        uint256 barnID;
        uint256 batchID;
        State batchState;
    }

    struct Container {
        uint256 barnID;
        uint256 batchID;
        uint256 containerID;
        uint256 temperature;
        uint256 humidity;
        uint256 airQuality;
        address distributor;
        address retailer;
        State batchState;
    }

    struct Product {
        uint256 barnID;
        uint256 batchID;
        uint256 containerID;
        string mfgDate;
        string expiryDate;
        uint256 mrp;
        State batchState;
    }

    /*Events*/
    event BarnCreated(uint256 indexed barnID);
    event Batched(uint256 indexed barnID, uint256 indexed batchID);
    event Incontainer(uint256 indexed barnID, uint256 indexed batchID, uint256 indexed containerID);
    event WithDistributor(
        address indexed distributor,
        uint256 indexed barnID,
        uint256 indexed batchID
    );

    //event Retailer(address indexed retailer, address indexed distributor, uint256 indexed batchID);

    // event Sold(
    //     address indexed buyer,
    //     address indexed distributor,
    //     uint256 indexed barnID,
    //     uint256 indexed batchID
    // );

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
                    0
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

    function createBatch(uint256 _barnID) public onlyEmployee {
        require(allBarnIDS[_barnID] == _barnID, "BarnID doesnt exist");
        batches.push(Batch(_barnID, batchID, State.BATCHED));
        allBatchIDS.push(batchID);
        emit Batched(_barnID, batchID);
        barns[_barnID].batchState = State.BATCHED;
        batchID++;
    }

    function getBatchesLength() public view returns (uint256) {
        return batches.length;
    }

    function inContainer(uint256 _barnID, uint256 _batchID) public onlyEmployee {
        require(allBatchIDS[_batchID] == _batchID, "BatchID doesnt exist");
        containers.push(
            Container(
                _barnID,
                _batchID,
                containerID,
                0,
                0,
                0,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                State.INCONTAINER
            )
        );
        allContainersIDS.push(containerID);
        emit Incontainer(_barnID, _batchID, containerID);
        batches[_batchID].batchState = State.INCONTAINER;
        containerID++;
    }

    function getContainerArrayLength() public view returns (uint256) {
        return containers.length;
    }
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

    Roles.Role private employees;

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
        emit EmployeeAdded(account);
    }

    function removeEmployee(address account) public onlyOwner {
        _removeEmployee(account);
    }

    function _removeEmployee(address account) internal {
        employees.removeRole(account);
        emit EmployeeRemoved(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Roles.sol";
import "../farmowner/Ownable.sol";

contract FarmerSupplierRole is Ownable {
    using Roles for Roles.Role;

    /*events*/
    event SupplierAdded(address indexed account);
    event SupplierRemoved(address indexed account);

    Roles.Role private suppliers;

    modifier onlySupplier() {
        require(isSupplier(msg.sender), "Caller is not a Supplier");
        _;
    }

    function isSupplier(address account) public view returns (bool) {
        return suppliers.hasRole(account);
    }

    function addSupplier(address account) public onlyOwner {
        _addSupplier(account);
    }

    function _addSupplier(address account) internal {
        suppliers.addRole(account);
        emit SupplierAdded(account);
    }

    function removeSupplier(address account) public onlyOwner {
        _removeSupplier(account);
    }

    function _removeSupplier(address account) internal {
        suppliers.removeRole(account);
        emit SupplierRemoved(account);
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
        emit RetailerAdded(account);
    }

    function removeRetailer(address account) public onlyOwner {
        _removeRetailer(account);
    }

    function _removeRetailer(address account) internal {
        retailers.removeRole(account);
        emit RetailerRemoved(account);
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