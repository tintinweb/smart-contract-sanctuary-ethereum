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

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;

  uint public deadline = block.timestamp + 5 minutes;

  uint256 public constant threshold = 1 ether;

  event Stake(address indexed sender, uint256 amount);

  modifier deadlineReached(bool requireReached){
    uint256 timeRemaining = timeLeft();
    if(requireReached){
      require(timeRemaining == 0, "Deadline is not reached yet");
    }
    else{
      require (timeRemaining > 0, "Deadline is already reached");
    }
    _;
  }

  modifier stakeNotCompleted(){
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }

  bool public openForWithdraw;

  function execute() public stakeNotCompleted deadlineReached(false){
    uint contractBalance = address(this).balance;

    // require(contractBalance >= threshold, "Threshold not reached");
    if(contractBalance >= threshold){
      // if the threshold is met send the balance to the external contract
    // (bool sent) = address(exampleExternalContract).call{value: contractBalance}
    // (abi.encodeWithSignature("complete()"));
    // require (sent, "exampleExternalContract.complete failed");

    exampleExternalContract.complete{value: address(this).balance}();
    }
    else{
      // if the threshold was not met, allow everyone to call a withdraw() function
      openForWithdraw = true;
    }
  }



  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() payable public deadlineReached(false) stakeNotCompleted {
    balances[msg.sender] += msg.value;
    
    emit Stake(msg.sender, msg.value);

  }
  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw(address payable _to) public deadlineReached(true) stakeNotCompleted{
    // check the amount staked did not reach the threshold by the deadline
    require(openForWithdraw, "Not open for withdraw");

    // get the sender balance
    uint userBalance = balances[msg.sender];
    //check if the sender has a balance to withdraw
    require(userBalance > 0, "userBalance is 0");

    // reset the sender's balance
    balances[msg.sender] = 0;
    //transfer sender's balance to the '_to' address
    (bool sent,) = _to.call{value: userBalance}("");
    // check transfer was successful
    require(sent, "Failed to send to address");

  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint){
    if(block.timestamp >= deadline){
      return 0;
    }else{
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable{
    stake();
  }


}