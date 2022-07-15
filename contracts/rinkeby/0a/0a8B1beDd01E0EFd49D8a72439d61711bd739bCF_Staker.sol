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

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;

  event Stake(address indexed sender, uint256 amount);

  mapping(address => uint256) public balances;

  function stake() public payable {
    balances[msg.sender] += msg.value;
    
    emit Stake(msg.sender, msg.value);
  }

  function execute() public {

    require(timeLeft() == 0, "Deadline not expired");

    uint256 contractBalance = address(this).balance;

    require(contractBalance >= threshold, "Threshold is not reached");

    (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed");
  }

  function withdraw(address payable depositor) public {
    uint256 userBalance = balances[depositor];

    require(timeLeft() == 0, "Deadline not expired");

    require(userBalance > 0, "Can't withdraw, there is no balance");

    balances[depositor] = 0;

    (bool sent,) = depositor.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  function timeLeft() public view returns (uint256 timeleft) {
    return deadline >= block.timestamp ? deadline - block.timestamp: 0;
  }

  function receive() public {
    stake();
  }
}