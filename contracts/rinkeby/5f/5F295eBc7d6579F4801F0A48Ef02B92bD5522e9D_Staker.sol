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

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw = false;

    modifier deadlineCheck() {
        require(timeLeft() == 0, "Time isn't over yet.");
        _;
    }

    modifier stakeConditions() {
        require(timeLeft() != 0, "Sorry you can't stake anymore, time over!");
        require(msg.value > 0 ether, "Value must be upper than 0 ether!");
        _;
    }

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Already executed!");
        _;
    }
    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    event Stake(address sender, uint256 value);

    function stake() public payable notCompleted stakeConditions {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public notCompleted deadlineCheck {
        // require(, "Threshold not reached, you can't execute!");
        if (address(this).balance > threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public deadlineCheck {
        if (address(this).balance <= threshold) openForWithdraw = true;

        require(openForWithdraw, "Withdraws closed for a now!");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}