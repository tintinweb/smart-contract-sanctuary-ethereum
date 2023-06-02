// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract ApplicationStatus {
  uint private _id = 1;

  mapping(uint => StatusInfo) private _statutus;

  struct StatusInfo {
    uint id;
    address worker;
    address company;
    string status;
  }

  event Progress(
    uint indexed id,
    address indexed worker,
    address indexed company,
    string previousStatus,
    string newStatus
  );

  function applyFor(
    address worker,
    address company,
    string memory status_
  ) external returns (StatusInfo memory) {
    _statutus[_id] = StatusInfo(_id, worker, company, status_);

    emit Progress(_id, worker, company, "", status_);

    return _statutus[_id++];
  }

  function updateStatus(
    uint id,
    // address worker,
    // address company,
    string memory newStatus
  ) external returns (StatusInfo memory) {
    StatusInfo storage statusInfo = _statutus[id];

    require(statusInfo.id == id, "id of status doesn't exist.");
    // require(status.worker == worker, "worker doesn't match.");
    // require(status.company == company, "company doesn't match.");
    require(
      keccak256(abi.encodePacked(statusInfo.status)) != keccak256(abi.encodePacked(newStatus)),
      "status doesn't change."
    );

    string memory previousStatus = statusInfo.status;
    statusInfo.status = newStatus;

    emit Progress(id, statusInfo.worker, statusInfo.company, previousStatus, newStatus);

    return statusInfo;
  }

  function status(uint id) external view returns (StatusInfo memory) {
    require(_statutus[id].id == id, "id of status doesn't exist.");

    StatusInfo memory statusInfo = _statutus[id];

    return statusInfo;
  }
}