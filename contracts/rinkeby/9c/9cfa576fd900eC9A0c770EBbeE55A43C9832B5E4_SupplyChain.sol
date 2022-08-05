// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../farmentities/FarmEmpRole.sol";
import "../farmentities/FarmSupplierRole.sol";
import "../farmentities/FarmRetailerRole.sol";
import "../farmowner/Ownable.sol";

contract SupplyChain is FarmEmpRole, FarmerSupplierRole, FarmRetailerRole {
    // enum State {
    //     FARMING,
    //     PROCESSED,
    //     PACKED,
    //     WITHDISTRIBUTOR,
    //     WITHRETAILER,
    //     SOLD
    // }
    // struct Barn {
    //     uint256 barnID;
    //     address ownerID;
    //     address farmEmpID;
    //     string farmName;
    //     string farmLatitude;
    //     string farmLongitude;
    // }
    // struct Batch {
    //     uint256 barnID;
    //     uint256 batchID;
    //     State batchState;
    //     address distributorID;
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