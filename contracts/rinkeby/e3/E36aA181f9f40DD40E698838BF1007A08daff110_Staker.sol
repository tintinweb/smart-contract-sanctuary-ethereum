// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }
  
  event Stake(address staker, uint256 value);

  mapping(address => uint256) public balances;
 
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  
  bool public openForWithdraw = false;
  bool public completed;

  modifier notCompleted(){
      require(completed == false, "already completed!");
      _;
  }

  function stake() public payable  {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, balances[msg.sender]);
  }


  function execute() public notCompleted {
    require(block.timestamp >= deadline, "deadline not finished");
    if(address(this).balance >= threshold){
        exampleExternalContract.complete{value: address(this).balance}();
        completed = true;

    } else {
        openForWithdraw = true;
    }
  }

/*   function Balances()public view returns(uint) {
    return (balances[msg.sender]);
  } */


  function withdraw() external notCompleted {
    require(openForWithdraw == true, "Withdraw is not open yet!");
    payable(msg.sender).transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }

  function timeLeft() public view returns(uint256) {
    if(block.timestamp >= deadline){
      return 0;
    }
    return(deadline - block.timestamp);
  }

  receive() external payable  {
    balances[msg.sender] = msg.value;
    emit Stake(msg.sender, msg.value);
  }

}