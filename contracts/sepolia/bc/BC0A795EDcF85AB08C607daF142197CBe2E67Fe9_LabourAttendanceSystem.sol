// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract LabourAttendanceSystem {
    struct Labourer {
        uint256 id;
        string name;
        string fingerprint;
        string location;
        uint256 lastAttendance;
    }

    address public owner;

    mapping(address => Labourer) public labourers;

    event NewLabourer(address indexed labourerAddress, uint256 indexed id, string name, string location);
    event LabourerAttendance(address indexed labourerAddress, uint256 indexed id, string location, uint256 timestamp);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function addLabourer(uint256 _id, string memory _name, string memory _fingerprint, string memory _location) public {
        require(labourers[msg.sender].id == 0, "Labourer already exists");
        labourers[msg.sender] = Labourer(_id, _name, _fingerprint, _location, 0);
        emit NewLabourer(msg.sender, _id, _name, _location);
    }

    function markAttendance(string memory _fingerprint, string memory _location) public {
        require(bytes(_fingerprint).length > 0, "Fingerprint is required");
        require(bytes(_location).length > 0, "Location is required");
        Labourer storage labourer = labourers[msg.sender];
        require(bytes(labourer.fingerprint).length > 0, "Labourer does not exist");
        require(keccak256(bytes(labourer.fingerprint)) == keccak256(bytes(_fingerprint)), "Fingerprint does not match");
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp - labourer.lastAttendance > 86400, "Attendance already marked today");
        labourer.location = _location;
        labourer.lastAttendance = currentTimestamp;
        emit LabourerAttendance(msg.sender, labourer.id, _location, currentTimestamp);
    }

    
    
}