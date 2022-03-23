/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// File: contracts/ExampleExternalContract.sol


pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// File: contracts/Staker.sol


pragma solidity 0.8.4;


contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 3 days;
  bool openForWithdraw = false;

  event Stake(address, uint256);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }


  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() external payable onlyIfClosed receivedEth {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() external onlyIfClosed {
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else if (deadline < block.timestamp) {
      openForWithdraw = true;
    }
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable _to) public onlyIfOpen {
    require(balances[_to] > 0, "Nothing to withdraw");
    (bool success, ) = _to.call{value: balances[_to] }("");
    if (success) {
      balances[_to] = 0;
    }
    require(success, "Failed to send ETH");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() external view returns (uint256) {
    if (block.timestamp < deadline) {
      return deadline - block.timestamp;
    }
    return 0;
  }


  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable receivedEth onlyIfOpen {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  modifier onlyIfOpen() {
    require(openForWithdraw, "Not open for withdrawal yet - call execute() if the deadline has passed");
    _;
  }

  modifier onlyIfClosed() {
    require(!openForWithdraw, "Not open for staking anymore");
    _;
  }

  modifier receivedEth() {
    require(msg.value > 0, "No ETH received");
    _;
  }
}