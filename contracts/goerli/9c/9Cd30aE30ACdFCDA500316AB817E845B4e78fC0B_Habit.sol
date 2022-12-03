// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Habit {
  // Events that will be emitted on changes.
  event HabitCreated(
    address indexed user,
    uint256 habitId,
    uint256 startTime,
    uint256 totalAmount,
    uint256 totalReports,
    uint256 interval
  );

  event HabitReported(
    uint256 habitId,
    uint256 reportedAt,
    uint32 successCount,
    uint32 missedCount
  );

  struct HabitCore {
    address user;
    uint256 startTime;
    uint256 totalAmount;
    uint32 totalReports;
    uint256 interval;
    bool ended;
    uint32 successCount;
    uint32 missedCount;
    uint256 amountWithdrawn;
  }

  mapping(uint256 => HabitCore) private _habits;

  uint256 public totalDeposits;
  uint256 public totalWithdrawals;

  constructor() {}

  function createHabit(
    uint256 habitId,
    uint32 totalReports,
    uint256 interval
  ) public payable {
    HabitCore storage habit = _habits[habitId];
    require(habit.totalAmount == 0, "Habit with this id already exists");
    require(msg.value > totalReports, "Invalid amount");

    habit.user = msg.sender;
    habit.startTime = block.timestamp;
    habit.totalAmount = msg.value;
    habit.totalReports = totalReports;
    habit.interval = interval;

    emit HabitCreated(
      habit.user,
      habitId,
      habit.startTime,
      msg.value,
      totalReports,
      interval
    );
  }

  function getHabit(
    uint256 habitId
  ) external view returns (HabitCore memory habit) {
    return _habits[habitId];
  }

  function report(uint256 habitId) public {
    HabitCore storage habit = _habits[habitId];
    require(habit.totalAmount != 0, "Habit with this id does not exists");
    require(habit.user == msg.sender, "Invalid user");
    habit.successCount++;

    emit HabitReported(
      habitId,
      block.timestamp,
      habit.successCount,
      habit.missedCount
    );
  }
}