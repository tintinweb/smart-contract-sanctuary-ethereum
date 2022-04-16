/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

// File contracts/ExampleExternalContract.sol


pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}


// File contracts/Staker.sol


pragma solidity 0.8.4;
contract Staker {
  //constant
  uint256 constant THRESHOLD = 1 ether;
  
  //state variables
  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw;
  //constructor
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }


  //events
  event Stake(address indexed account, uint256 amount);
  
  //modifier
  modifier notCompleted(){
    require(false == exampleExternalContract.completed(), "It is completed now");
    _;
  }

  //public view
  function timeLeft() external view returns(uint256){
    if(block.timestamp >= deadline)
    {
        
        return 0;
    }
    
    uint256 _timeLeft = deadline - block.timestamp;
    
    return _timeLeft;
  }

  //public function 

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted {
      
      emit Stake(msg.sender, msg.value);
      balances[msg.sender] += msg.value;
      
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function execute() public notCompleted {
    require(block.timestamp >= deadline, "deadline hasn't come");
    if(address(this).balance >= THRESHOLD){
     
      exampleExternalContract.complete{value: address(this).balance}();
    }
    else{
      openForWithdraw = true;
    }
  }




  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted {
    require(true == openForWithdraw, "not open for withdraw now");
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
    require(success, 'withdraw success');
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable{
    stake();
  }

}