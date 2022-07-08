// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TimeularOnTheBlock {
  // events
  event TimeEntryCommitted(
    string timeEntryId,
    string userId,
    string activityName,
    string startTime,
    string stopTime
  );

  function commitTimeEntry(
    string memory timeEntryId,
    string memory userId,
    string memory activityName,
    string memory startTime,
    string memory stopTime
  ) public {
    emit TimeEntryCommitted(timeEntryId, userId, activityName, startTime, stopTime);
  }
}