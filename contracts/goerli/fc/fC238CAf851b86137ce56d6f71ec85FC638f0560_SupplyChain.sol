/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract SupplyChain {

    enum PackageSnapshotStatus {
        PackageCreated, // 0
        PackageMoved, // 1
        PackageHandled, // 2
        PackageReported, // 3
        PackageAccepted // 4
    }

    struct PackageSnapshot {
        Department handler; // handler of package
        uint parent; // index of parent package. If it is a root package, set 0
        PackageSnapshotStatus status;
        string name;
        string description;
        uint created; // timestamp
        bool exists;
    }

    struct Department {
        address addr;
    }

    mapping (uint => PackageSnapshot) public snapshots;
    mapping (address => bool) public admins;

    modifier parentExists(uint parent) {
        if (parent != 0)
            require(snapshots[parent].exists == true, "PackageSnapshot with such nodeIndex does not exist");
        _;
    }

    modifier snapshotExists(uint index) {
        require(snapshots[index].exists == true, "PackageSnapshot with such index does not exist");
        _;
    }

    modifier notAdminYet() {
        require(!admins[msg.sender], "This user is already an admin");
        _;
    }

    modifier isAdmin() {
        require(admins[msg.sender], "This user is not an admin");
        _;
    }

    event Log(string message);
    event PackageSnapshotAdded(PackageSnapshot snapshot, uint id);
    event AdminAdded(address);
    event AdminRemoved(address);

    uint public snapshotNumber = 0;

    constructor () {
        
    }

    function makeMeAdmin() public notAdminYet {
        admins[msg.sender] = true;
        emit AdminAdded(msg.sender);
    }

    function makeMeUser() public isAdmin {
        admins[msg.sender] = false;
        emit AdminRemoved(msg.sender);
    }

    function addPackageSnapshot(uint parent, PackageSnapshotStatus status, string memory name, string memory description) public parentExists(parent) isAdmin 
    returns (uint) {
        Department memory department = Department({addr: msg.sender});
        PackageSnapshot memory snapshot = createPackageSnapshot(department, parent, status, name, description, block.timestamp);
        snapshots[++snapshotNumber] = snapshot;
        emit PackageSnapshotAdded(snapshot, snapshotNumber);
        return snapshotNumber;
    }

    function createPackageSnapshot(Department memory handler, uint parent, PackageSnapshotStatus status, string memory name, string memory description, uint created) 
    internal pure returns (PackageSnapshot memory) {
        return PackageSnapshot({handler: handler, parent: parent, status: status, name: name, description: description, created: created, exists: true});
    }
}