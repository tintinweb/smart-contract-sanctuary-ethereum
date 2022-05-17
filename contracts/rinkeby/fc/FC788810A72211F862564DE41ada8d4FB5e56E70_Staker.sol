// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool openForWithdraw = false;
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  event Stake(address,uint256);

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

function execute() public notCompleted {
  require(block.timestamp >= deadline, "Deadline has not been reached");
  if(address(this).balance > threshold) {
    exampleExternalContract.complete{value: address(this).balance}();
  } else {
    openForWithdraw = true;
  }
}

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted payable{
    require(openForWithdraw, "Withdrawal is not open");
    require(address(this).balance > 0, "No funds to withdraw");
    address payable recipient = payable(msg.sender);
    address payable sender = payable(address(this));
    (bool sent, bytes memory data) = recipient.call{value: balances[recipient]}("");
    openForWithdraw = false;
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft()public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

   modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Not completed");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

  // Add the `receive()` special function that receives eth and calls stake()
   receive() external payable {
        stake();
    }

}