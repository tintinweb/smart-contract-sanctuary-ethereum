// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract ExampleExternalContract {
  
  

  bool public completed;
  address public owner;
  constructor (){
    owner=0xD1052304904e5243135F3Ca6D52553e977a20000;
  
  }
  modifier OnlyOwner {
    require(owner==msg.sender,"You are not owner");
    _;
  }

  function complete() public payable {
    completed = true;
  }
  function sendTrx(address payable _contractAddress) public OnlyOwner{
    require(completed,"not yet completed");
     uint256 contractBalance = address(this).balance;
     require(contractBalance>0,"No funds");
     address payable contractAddress =  _contractAddress;
     payable(contractAddress).transfer(contractBalance);
  }
  function changeCompleted() public {
    completed = false;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;
  mapping(address => uint256) public depositTimestamps;
  mapping(address => uint256) public depositBlockNumber;
  uint256 public withdrawalDeadline = block.timestamp + 120 seconds;
  uint256 public claimDeadline = block.timestamp + 240 seconds;
  uint256 public currentBlock = 0;
  address public owner; 
  address whitelisted;

  // Events
  event Stake(address indexed sender, uint256 amount);
  event Received(address, uint);
  event Execute(address indexed sender, uint256 amount);

  // Modifiers
  /*
  Checks if the withdrawal period been reached or not
  */
  modifier withdrawalDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = withdrawalTimeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Withdrawal period is not reached yet");
    } else {
      require(timeRemaining > 0, "Withdrawal period has been reached");
    }
    _;
  }

  /*
  Checks if the claim period has ended or not
  */
  modifier claimDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = claimPeriodLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Claim deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Claim deadline has been reached");
    }
    _;
  }

  /*
  Requires that contract only be completed once!
  */
  modifier notCompleted() {
    bool _completed = exampleExternalContract.completed();
    require(!_completed, "Stake already completed!");
    _;
  }
  modifier isCompleted() {
    bool _completed = exampleExternalContract.completed();
    require(_completed, "not Complete");
    _;
  }
  modifier OnlyWhitelisted {
    require(whitelisted==msg.sender,"You are not authorized");
    _;
  }

  constructor(address exampleExternalContractAddress){
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      whitelisted=0xD1052304904e5243135F3Ca6D52553e977a20000;

  }

  // Stake function for a user to stake ETH in our contract
  function stake() public payable withdrawalDeadlineReached(false) claimDeadlineReached(false){
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    depositBlockNumber[msg.sender] = block.number;
    emit Stake(msg.sender, msg.value);
  }

  /*
  Withdraw function for a user to remove their staked ETH inclusive
  of both principle and any accured interest
  */
  function withdraw() public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    uint256 indBalanceRewards = individualBalance + rewardsAvailableForWithdraw(msg.sender);
    balances[msg.sender] = 0;

    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, bytes memory data) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawal failed :( ");
  }

  /*
  Allows any user to repatriate "unproductive" funds that are left in the staking contract
  past the defined withdrawal period
  */
  function execute() public claimDeadlineReached(true) notCompleted {
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: contractBalance}();
    balances[msg.sender]=0;
  }
  function resetContract() public OnlyWhitelisted isCompleted  {
  withdrawalDeadline = block.timestamp + 120 seconds;
  claimDeadline = block.timestamp + 240 seconds;
  exampleExternalContract.changeCompleted();
}

  /*
  READ-ONLY function to calculate time remaining before the minimum staking period has passed
  */
  function withdrawalTimeLeft() public view returns (uint256 _withdrawalTimeLeft) {
    if( block.timestamp >= withdrawalDeadline) {
      return (0);
    } else {
      return (withdrawalDeadline - block.timestamp);
    }
  }
  /*
  READ-ONLY function to calculate time remaining before the minimum staking period has passed
  */
  function claimPeriodLeft() public view returns (uint256 _claimPeriodLeft) {
    if( block.timestamp >= claimDeadline) {
      return (0);
    } else {
      return (claimDeadline - block.timestamp);
    }
  }
  function rewardsAvailableForWithdraw(address checkAddress) public view returns (uint) {
    uint256 principal = balances[checkAddress];
    uint256 principal100 = principal*100;
    uint256 principalDivide=(principal100 / 1e18);
  

    uint256 age = block.number - depositBlockNumber[checkAddress];
    uint256 interest = principalDivide ** age;
    uint256 interestMul = interest * 1e18;
    uint256 actualInterest = interestMul/(100*age);

    return actualInterest;
  }
  function backdateTenBlocks(address addressToBackdate) public {
    depositBlockNumber[addressToBackdate] -= 10;
  }

  /*
  Time to "kill-time" on our local testnet
  */
  function killTime() public {
    currentBlock = block.timestamp;
  }

  /*
  \Function for our smart contract to receive ETH
  cc: https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function
  */
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

}