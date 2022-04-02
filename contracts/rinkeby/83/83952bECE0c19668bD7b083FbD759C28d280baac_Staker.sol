// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
mapping ( address => uint256 ) public balances;
uint256 public constant threshold = 1 ether;
uint256 public deadline = block.timestamp + 72 hours;
bool openForWithdraw = false;
address public owner;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);   
  }
event Stake(address _staker, uint256 amount);

// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
function stake() public payable {
  balances[msg.sender] += msg.value;
  // console.log("Getting the balance :", msg.value);
emit Stake(msg.sender, msg.value);

}

function stake(address _from, uint256 amount) private {
  balances[_from] += amount;
emit Stake(_from, amount);
}

modifier notCompleted{
    require(!exampleExternalContract.completed(), "Cant withdraw");
    _;
  }
  
  function execute() public notCompleted{
    
    require(block.timestamp > deadline);
    if(address(this).balance >= threshold){
    exampleExternalContract.complete{value: address(this).balance}();
    } else{
      openForWithdraw = true;
    }
    
  }

  function timeLeft() public view returns(uint256) {
    
    if(block.timestamp >= deadline){ 
      return 0;
    } 
    else{
return ( deadline - block.timestamp);
    }  
  }


  function withdraw( ) public notCompleted payable {
    require(openForWithdraw, "Not yet time to withdraw");
    (bool sent, )=  msg.sender.call{value: balances[msg.sender]}(" ");
    balances[msg.sender] = 0;
    require(sent, "Failed to send ether");
  }

receive() external payable notCompleted{
  stake(msg.sender, msg.value);

} 


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()


}