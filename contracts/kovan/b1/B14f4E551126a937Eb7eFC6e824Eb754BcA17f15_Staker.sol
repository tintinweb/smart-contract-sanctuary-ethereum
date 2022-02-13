pragma solidity >= 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

pragma solidity >=0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress)  public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;

  event Stake(address, uint256);
  event Withdraw(address, uint256);


  modifier notCompleted() {
    require(exampleExternalContract.completed() == false);
    _;
  }


  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:s
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    if(block.timestamp >= deadline && address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else if(address(this).balance <= threshold) {
      openForWithdraw = true;
    }
  }

  function timeLeft() public view returns (uint256) {
    return block.timestamp >= deadline ? 0 : deadline - block.timestamp;
  }

  function withdraw(address payable user) public notCompleted {
    require(openForWithdraw, "You can't withdraw since openForWithdraw is false");
    (bool success, ) = user.call{value: balances[user] }("");
    require(success, "Failed to send any ether");
    emit Withdraw(user, balances[user]);
  }

  receive() external payable {
    stake();
  }
}