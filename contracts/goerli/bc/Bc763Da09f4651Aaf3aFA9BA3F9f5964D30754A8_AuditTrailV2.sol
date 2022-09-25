// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error AuditTrail__IdentifierAlreadyAudited();
error AuditTrail__PdfAlreadyAttached();
error AuditTrail__RawDataAlreadyAttached();
error AuditTrail__NotFound();

contract AuditTrailV2 {
  enum AuditTrailEntryStatus {
    NA,
    VALID,
    INVALID
  }

  struct AuditTrailEntry {
    bytes32 identifier; // FormData Guid
    bytes32 studyGuid;
    bytes32 studySiteGuid;
    bytes32 subjectGuid;
    string subjectKey;
    bytes32 dataHash;
  }

  struct AuditTrailEntryReqeust {
    string identifier; // FormData Guid
    string studyGuid;
    string studySiteGuid;
    string subjectGuid;
    string subjectKey;
    bytes32 dataHash;
  }

  address public owner;

  bytes32[] public auditEntries;

  mapping(bytes32 => AuditTrailEntry) public auditTrailEntries;
  mapping(bytes32 => bytes32[]) public studyEntries;
  mapping(bytes32 => bytes32[]) public studySiteEntries;
  mapping(bytes32 => bytes32[]) public subjectEntries;

  mapping(bytes32 => bytes32) public pdfHashes;
  mapping(bytes32 => bytes32) public rawDataHashes;

  event AuditEntryAdded(
    string indexed studyGuid,
    string indexed studySiteGuid,
    string indexed subjectGuid,
    string subjectKey,
    string identifier,
    bytes32 dataHash
  );

  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function audit(AuditTrailEntryReqeust memory request) external ownerOnly {
    AuditTrailEntry memory entry = AuditTrailEntry(
      stringToBytes32(request.identifier),
      stringToBytes32(request.studyGuid),
      stringToBytes32(request.studySiteGuid),
      stringToBytes32(request.subjectGuid),
      request.subjectKey,
      request.dataHash
    );

    if (auditTrailEntries[entry.identifier].identifier != 0)
      revert AuditTrail__IdentifierAlreadyAudited();

    auditEntries.push(entry.identifier);
    studyEntries[entry.studyGuid].push(entry.identifier);
    studySiteEntries[entry.studySiteGuid].push(entry.identifier);
    subjectEntries[entry.subjectGuid].push(entry.identifier);
    auditTrailEntries[entry.identifier] = entry;

    emit AuditEntryAdded(
      request.studyGuid,
      request.studySiteGuid,
      request.subjectGuid,
      request.subjectKey,
      request.identifier,
      request.dataHash
    );
  }

  function attachPdf(string memory identifier, bytes32 hash)
    external
    ownerOnly
  {
    bytes32 identifierBytes = stringToBytes32(identifier);

    if (pdfHashes[identifierBytes] != 0)
      revert AuditTrail__PdfAlreadyAttached();

    pdfHashes[identifierBytes] = hash;
  }

  function attachRawData(string memory identifier, bytes32 hash)
    external
    ownerOnly
  {
    bytes32 identifierBytes = stringToBytes32(identifier);

    if (rawDataHashes[identifierBytes] != 0)
      revert AuditTrail__RawDataAlreadyAttached();

    rawDataHashes[identifierBytes] = hash;
  }

  function validate(string memory identifier, bytes32 dataHash)
    external
    view
    returns (AuditTrailEntryStatus)
  {
    bytes32 identifierBytes = stringToBytes32(identifier);
    return
      auditTrailEntries[identifierBytes].dataHash == dataHash
        ? AuditTrailEntryStatus.VALID
        : AuditTrailEntryStatus.INVALID;
  }

  function getAuditEntriesCount() public view returns (uint256) {
    return auditEntries.length;
  }

  function getEntry(string memory identifier)
    public
    view
    returns (AuditTrailEntryReqeust memory)
  {
    bytes32 identifierBytes = stringToBytes32(identifier);

    if (auditTrailEntries[identifierBytes].identifier == 0)
      revert AuditTrail__NotFound();

    AuditTrailEntry memory storedEntry = auditTrailEntries[identifierBytes];

    AuditTrailEntryReqeust memory entry = AuditTrailEntryReqeust(
      bytes32ToString(storedEntry.identifier),
      bytes32ToString(storedEntry.studyGuid),
      bytes32ToString(storedEntry.studySiteGuid),
      bytes32ToString(storedEntry.subjectGuid),
      storedEntry.subjectKey,
      storedEntry.dataHash
    );

    return entry;
  }

  function getPdfHash(string memory identifier) public view returns (bytes32) {
    bytes32 identifierBytes = stringToBytes32(identifier);

    if (pdfHashes[identifierBytes] == 0) return "";

    return pdfHashes[identifierBytes];
  }

  function getRawDataHash(string memory identifier)
    public
    view
    returns (bytes32)
  {
    bytes32 identifierBytes = stringToBytes32(identifier);

    if (rawDataHashes[identifierBytes] == 0) return "";

    return rawDataHashes[identifierBytes];
  }

  function getStudyEntries(string memory studyGuid)
    public
    view
    returns (string[] memory)
  {
    bytes32 studyGuidBytes = stringToBytes32(studyGuid);
    bytes32[] memory storedEntries = studyEntries[studyGuidBytes];
    string[] memory entries = new string[](storedEntries.length);
    for (uint256 i = 0; i < storedEntries.length; i++) {
      entries[i] = bytes32ToString(storedEntries[i]);
    }
    return entries;
  }

  function getSubjectEntries(string memory subjectGuid)
    public
    view
    returns (string[] memory)
  {
    bytes32 subjectGuidBytes = stringToBytes32(subjectGuid);
    bytes32[] memory storedEntries = subjectEntries[subjectGuidBytes];
    string[] memory entries = new string[](storedEntries.length);
    for (uint256 i = 0; i < storedEntries.length; i++) {
      entries[i] = bytes32ToString(storedEntries[i]);
    }
    return entries;
  }

  function stringToBytes32(string memory str) internal pure returns (bytes32) {
    return bytes32(bytes(str));
  }

  function bytes32ToString(bytes32 b) internal pure returns (string memory) {
    return string(abi.encodePacked(b));
  }
}