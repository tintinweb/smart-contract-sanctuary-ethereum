// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error AuditTrail__IdentifierAlreadyAudited();

contract AuditTrail {
  enum AuditTrailEntryStatus {
    NA,
    VALID,
    INVALID
  }

  struct AuditTrailEntry {
    bytes32 identifier; // AuditRecord GUID
    bytes32 studyGuid;
    bytes32 studySiteGuid;
    bytes32 subjectGuid;
    string subjectKey;
    bytes32 formDataGuid;
    bytes32 dataHash;
  }

  address public owner;

  bytes32[] public auditEntries;
  mapping(bytes32 => mapping(bytes32 => AuditTrailEntry))
    public studyAuditTrailEntries;
  mapping(bytes32 => mapping(bytes32 => AuditTrailEntry))
    public studySiteAuditTrailEntries;
  mapping(bytes32 => mapping(bytes32 => AuditTrailEntry))
    public subjectAuditTrailEntries;
  mapping(bytes32 => mapping(bytes32 => AuditTrailEntry))
    public formAuditTrailEntries;

  mapping(bytes32 => AuditTrailEntry) public auditTrailEntries;

  event AuditEntryAdded(bytes32 identifier, AuditTrailEntry dataHash); //...

  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function audit(AuditTrailEntry memory entry) external ownerOnly {
    if (auditTrailEntries[entry.identifier].identifier != 0)
      revert AuditTrail__IdentifierAlreadyAudited();

    studyAuditTrailEntries[entry.studyGuid][entry.identifier] = entry;
    studySiteAuditTrailEntries[entry.studySiteGuid][entry.identifier] = entry;
    subjectAuditTrailEntries[entry.subjectGuid][entry.identifier] = entry;
    formAuditTrailEntries[entry.formDataGuid][entry.identifier] = entry;
    auditTrailEntries[entry.identifier] = entry;

    auditEntries.push(entry.identifier);
    emit AuditEntryAdded(entry.identifier, entry);
  }

  function validate(bytes32 identifier, bytes32 dataHash)
    external
    view
    returns (AuditTrailEntryStatus)
  {
    return
      auditTrailEntries[identifier].dataHash == dataHash
        ? AuditTrailEntryStatus.VALID
        : AuditTrailEntryStatus.INVALID;
  }

  function getAuditEntriesCount() public view returns (uint256) {
    return auditEntries.length;
  }
}