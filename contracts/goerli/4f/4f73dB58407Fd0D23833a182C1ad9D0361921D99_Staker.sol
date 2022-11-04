// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {
   address payable owner ;
  constructor (){
     owner = payable(msg.sender);
  }

  bool public completed;

  function complete() public payable {
    completed = true;
  }

  function takeFundsOut() public  {
    require(msg.sender == owner,"only owner can take the funds");
    (bool sent,)=address(owner).call{value: address(this).balance}("");
    require(sent,"Transaction was not sent");
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    address public owner;

      constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
        owner= msg.sender;
    }

    function transferOwnership(address newOwner)external {
     require(owner == msg.sender,"Only OWNER");
     owner = newOwner;
    }

//Mappings
    mapping(address => uint256) public balances;

//variables
    uint256 public stakingDeadline = block.timestamp + 1 minutes;
    uint256 public currentBlock = 0;

//events
    event Stake(address indexed sender, uint256 amount);
    event Received(address, uint256);
    event Execute(address indexed sender, uint256 amount);

//view functions    
      function withdrawalTimeLeft() public view returns (uint256) {
    if( block.timestamp >= stakingDeadline) {
      return (0);
    } else {
      return (stakingDeadline - block.timestamp);
    }
  }


//Modifiers
/**
 * Check that the staking deadline has not reached yet.
 */
  modifier stakingDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = withdrawalTimeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Withdrawal period is not reached yet");
    } else {
      require(timeRemaining > 0, "Withdrawal period has been reached");
    }
    _;
  }

  /*
  check that the transfer of eth from this contract
  to external contract is not performed yet
  */
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }  

   // Stake function for a user to stake ETH in our contract
  
  function stake() public payable stakingDeadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    emit Stake(msg.sender, msg.value);
  }
  /*
  Withdraw function for a user to remove their staked ETH 
  */
  
  function withdraw() public stakingDeadlineReached(true) notCompleted{
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    balances[msg.sender] = 0;

    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, ) = msg.sender.call{value: individualBalance}("");
    require(sent, "RIP; withdrawal failed :( ");
  }

  
  function execute() public notCompleted {
    require(msg.sender == owner ," Only owner can send these tokens to external Contract");
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: contractBalance}();
  }

   receive() external payable {
      emit Received(msg.sender, msg.value);
  }

}