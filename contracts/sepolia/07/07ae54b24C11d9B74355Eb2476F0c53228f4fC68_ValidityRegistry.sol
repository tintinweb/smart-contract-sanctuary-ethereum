// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/// @title Registry contract for storage and proof of digital credentials
/// @author Xinchen (Mike) Liu
// @evangelist Michael Cutro
/// @notice This contract is used to issue digital credentials with encoded information which can be used as a proof of identity.

//certificate type and possible to point it off chain, certificate subtype,

interface IRegistry {
    event Issued(uint256 indexed studentId);
    event Revoked(uint256 indexed studentId);

    function encode(
        string memory fullName,
        string memory birthday
    ) external view returns (uint256);

    function readRecord(uint256 studentId) external view returns (bytes32);

    function setRecord(uint256 studentId, bytes32 additionalRecord) external;

    function issue(uint256 studentId, bytes32 additionalRecord) external;

    function batchIssue(
        uint256[] calldata studentIds,
        bytes32[] calldata additionalRecords
    ) external;

    function batchUpdateRecord(
        uint256[] calldata studentIds,
        bytes32[] calldata additionalRecords
    ) external;

    function revoke(uint256 studentId) external;

    function verify(
        string memory fullName,
        string memory birthday
    ) external view returns (bool);
}

contract ValidityRegistry is IRegistry {
    // Registry name
    string private _name;
    // Owner address
    address private _owner;
    // Salt for encoding
    bytes32 private _salt;
    // Status of a diploma
    enum Status {
        Pending,
        Issued,
        Revoked
    }
    // Record of a diploma
    struct Record {
        Status status;
        bytes32 additionalRecord;
    }
    // Mapping from studentId to Record
    mapping(uint256 => Record) private _records;

    constructor(string memory name_) {
        _name = name_;
        _owner = msg.sender;
        _salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function encode(
        string memory fullName,
        string memory birthday
    ) public view onlyOwner returns (uint256) {
        string memory inputString = string(
            abi.encodePacked(fullName, "|", birthday)
        );
        bytes32 initialHash = keccak256(abi.encodePacked(inputString, _salt));
        bytes32 studentId = keccak256(
            abi.encodePacked(initialHash, inputString)
        );
        return uint256(studentId);
    }

    function verify(
        string memory fullName,
        string memory birthday
    ) external view onlyOwner returns (bool) {
        return _exists(encode(fullName, birthday));
    }

    function readRecord(uint256 studentId) external view returns (bytes32) {
        require(_exists(studentId), "Diploma cannot be found");
        return _records[studentId].additionalRecord;
    }

    function setRecord(
        uint256 studentId,
        bytes32 additionalRecord
    ) external onlyOwner {
        require(_exists(studentId), "Diploma cannot be found");
        _records[studentId].additionalRecord = additionalRecord;
    }

    function batchUpdateRecord(
        uint256[] calldata studentIds,
        bytes32[] calldata additionalRecords
    ) external onlyOwner {
        require(
            studentIds.length == additionalRecords.length,
            "Lengths do not match"
        );
        for (uint i = 0; i < studentIds.length; i++) {
            uint256 studentId = studentIds[i];
            bytes32 additionalRecord = additionalRecords[i];
            require(_exists(studentId), "Diploma cannot be found");
            _records[studentId].additionalRecord = additionalRecord;
        }
    }

    function issue(
        uint256 studentId,
        bytes32 additionalRecord
    ) external onlyOwner {
        _issue(studentId, additionalRecord);
        emit Issued(studentId);
    }

    function batchIssue(
        uint256[] calldata studentIds,
        bytes32[] calldata additionalRecords
    ) external onlyOwner {
        for (uint i = 0; i < studentIds.length; i++) {
            uint256 studentId = studentIds[i];
            bytes32 additionalRecord = additionalRecords[i];
            _issue(studentId, additionalRecord);
            emit Issued(studentId);
        }
    }

    function revoke(uint256 studentId) external onlyOwner {
        _revoke(studentId);
        emit Revoked(studentId);
    }

    function _exists(uint256 studentId) internal view virtual returns (bool) {
        return _records[studentId].status == Status.Issued;
    }

    function _issue(
        uint256 studentId,
        bytes32 additionalRecord
    ) internal virtual {
        require(!_exists(studentId), "Diploma already issued");
        _records[studentId].status = Status.Issued;
        _records[studentId].additionalRecord = additionalRecord;
    }

    function _revoke(uint256 studentId) internal virtual {
        _records[studentId].status = Status.Revoked;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}