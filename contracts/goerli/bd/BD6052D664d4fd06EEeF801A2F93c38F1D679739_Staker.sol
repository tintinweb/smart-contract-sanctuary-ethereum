// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExampleExternalContract {

  bool public completed;

    // // Function to receive Ether. msg.data must be empty
    // receive() external payable {}

    // // Fallback function is called when msg.data is not empty
    // fallback() external payable {}


  function complete() public payable{
    require(address(this).balance>0,"ExampleExternalContract : The balance of the smart contract is not enough");
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) private balances;
    mapping(address=>uint256)private countStake;
    event Stake(address from, uint256 amount,uint256 _countStake);
    uint256 lowAmount = 0.05 ether;
    uint256 public startTime;
    uint256 public deadlineTime;
    uint256 public threshold = 3 ether;

    constructor(address  exampleExternalContractAddress, uint256 _deadline) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        startTime = block.timestamp;
        deadlineTime = startTime + _deadline;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable{
        require(msg.value >= lowAmount, "Staker : Insufficient inventory");
        require(msg.value % lowAmount == 0,"Staker : must be a multiple of lowAmount");
        uint256 count=(msg.value / lowAmount);
        countStake[msg.sender] += count ;
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value,count);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public payable {
        require(block.timestamp > deadlineTime, "Staker : Time is not over");
        require(
            address(this).balance >= threshold,
            "Staker : Threshold is not met"
        );
        exampleExternalContract.complete{value: address(this).balance}();
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public payable {
        require(block.timestamp > deadlineTime, "Staker : Time is not over");
        require(address(this).balance < threshold, "Staker : threshold is met");
        require(address(this).balance>=balances[msg.sender],"Staker : The balance of the smart contract is not enough" );
        uint256 payment = balances[msg.sender];
        balances[msg.sender] = 0;
        countStake[msg.sender]=0;
        payable(msg.sender).transfer(payment);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if(block.timestamp > deadlineTime){
            return 0;
        }else{
          return deadlineTime - block.timestamp;
        }
    }

    
    // Add the `receive()` special function that receives eth and calls stake()
    // receive() external payable {
    //     stake();
    // }

    function getBalance()public view returns(uint256){
        return balances[msg.sender];
    }

    function getBalanceExampleExternalContract()public view returns(uint256){
        return address(exampleExternalContract).balance;
    }

    function getBalanceStaker()public view returns(uint256){
        return address(this).balance;        
    }

}