// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

contract Staker {
    //create a variable of type contract
    ExampleExternalContract public exampleExternalContract;

    //first you need to deploy the ExampleExternalContract contract, then feed the address here
    mapping(address => uint256) public balances;
    event Stake(address indexed staker, uint256);
    event Withdrawed(address indexed staker, uint256);
    uint256 public constant threshold = 1 ether;
    uint256 public immutable deadline;
    bool allowWithdraw;

    uint256 internal counter = 0;

    constructor(address payable exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        deadline = block.timestamp + 72 hours;
    }

    modifier deadlinePassed {
      require(block.timestamp<deadline,"deadline has passed, you can no longer stake");
      _;
      
    }

    modifier executeModifier{
      require(block.timestamp >= deadline,"please wait till the assigned deadline");
      _;
    }

    modifier withdrawModifier{
      require(!exampleExternalContract.completed(),'you cannot withdraw as we collectively have met the requirement');
      
      require(balances[msg.sender]>0,'you have no eth staked in this contract');
      _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable deadlinePassed{
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public executeModifier{
      if(address(this).balance>=threshold){
      exampleExternalContract.complete{value: address(this).balance}();  
      }else{
        allowWithdraw=true;
      }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public withdrawModifier {

      uint256 temp = balances[msg.sender];
      balances[msg.sender]=0;
      payable(msg.sender).transfer(temp);
      emit Withdrawed(msg.sender,temp);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() view public returns(uint256){
      return block.timestamp>=deadline?0:deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() payable external {
      stake();
    }
}

/*
TODO:
* Create a decentralized application where users can coordinate a group funding effort
* If the users cooperate, the money is collected in a second smart contract
* If they defect, the worst that can happen is everyone gets their money back.

* Collects ETH from numerous addresses using a payable stake() 
* Keep track of balance
* After some deadline if it has at least some threshold of ETH it sends it to an ExampleExternalContract and triggers the complete() action sending the full balance
* If not enough ETH is collected, allow users to withdraw().

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {

  bool public completed;
  address public immutable owner;

  constructor(){
    owner=msg.sender;
  }

  function complete() public payable {
    completed = true;
  }

  receive()external payable{}

  function withdraw() external{
    require(msg.sender==owner,'only owner can withdraw');
    (bool sent,)=payable(msg.sender).call{value:address(this).balance}("");
    require(sent,'something went wrong');
  }

}