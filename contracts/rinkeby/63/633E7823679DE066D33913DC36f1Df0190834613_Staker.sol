// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  /// @notice Track individual balances
  mapping (address => uint256) public balances;

  /// @notice Threshold amount
  uint256 public constant threshold = 1 ether;

  /// @notice Deadline for when funds can be deposited
  uint256 public deadline = block.timestamp + 80 hours;

  /// @notice Track if contract is currently accepting withdrawls
  bool public openForWithdraw;

  /// @notice Event to indicate a user has staked
  event Stake(address, uint256);

  /// @notice Check if 
  modifier notCompleted {
    require(!exampleExternalContract.completed());
    _;
  }

  /// @notice Constructor
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  /// @notice Stake users's funds
  function stake() public payable {
    require(block.timestamp < deadline, "Deadline for staking has passed");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  /// @notice Check if threshold is met and if so, execute the contract call
  function execute() external notCompleted {
    require(block.timestamp >= deadline, "Staking still in progress");
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  /// @notice Withdraw user funds
  function withdraw() external notCompleted {
    require(openForWithdraw, "Contract is not open for withdrawls");
    uint256 userBal = balances[msg.sender]; 
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(userBal);
  }

  /// @notice Calculate time left before deadline
  /// @return The time left before the deadline
  function timeLeft() public view returns (uint256) {
    return (block.timestamp >= deadline) 
      ? 0 : deadline - block.timestamp;
  }

  /// @notice Fallback to handle if funds are send without function signature
  receive() external payable {
    stake();
  }
}