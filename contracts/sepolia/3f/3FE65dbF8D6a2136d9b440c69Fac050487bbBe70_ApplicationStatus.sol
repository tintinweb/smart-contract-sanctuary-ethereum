// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract ApplicationStatus {
  uint private _id = 1;

  mapping(uint => Status) private _statutus;

  struct Status {
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
    string memory status
  ) external returns (Status memory) {
    _statutus[_id] = Status(_id, worker, company, status);

    emit Progress(_id, worker, company, "", status);

    return _statutus[_id++];
  }

  function updateStatus(
    uint id,
    // address worker,
    // address company,
    string memory newStatus
  ) external returns (Status memory) {
    Status storage status = _statutus[id];

    require(status.id == id, "id of status doesn't exist.");
    // require(status.worker == worker, "worker doesn't match.");
    // require(status.company == company, "company doesn't match.");
    require(
      keccak256(abi.encodePacked(status.status)) != keccak256(abi.encodePacked(newStatus)),
      "status doesn't change."
    );

    string memory previousStatus = status.status;
    status.status = newStatus;

    emit Progress(id, status.worker, status.company, previousStatus, newStatus);

    return status;
  }
}