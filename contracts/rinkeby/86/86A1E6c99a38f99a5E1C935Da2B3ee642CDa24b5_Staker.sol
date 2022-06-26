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

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;

    uint256 deadline = block.timestamp + 10 hours;

    event Stake(address indexed sender, uint256 amount);
    event Complete(uint256 amount);

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() notCompleted public payable {
        // update the user's balance
        balances[msg.sender] += msg.value;
        // emit the event to notify the blockchain that we have correctly Staked some fund for the user
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

    function execute() notCompleted external {
        require(block.timestamp >= deadline, "deadline hasn't expired");
        require(
            address(this).balance >= threshold,
            "threshold hasn't been reached"
        );
        uint256 contractBalance = address(this).balance;
        exampleExternalContract.complete{value: address(this).balance}();
        require(exampleExternalContract.completed(), "transaction failed");
        emit Complete(contractBalance);
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function

    // Add a `withdraw()` function to let users withdraw their balance

    function withdraw() notCompleted external {
        uint256 userBalance = balances[msg.sender];
        balances[msg.sender] = 0;
        require(userBalance > 0, "no balance to withdraw");
        require(
            address(this).balance < threshold,
            "threshold has been reached"
        );
        require(timeLeft() == 0, "deadline hasn't expired");
        payable(msg.sender).transfer(userBalance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    function timeLeft() public view returns (uint256) {
        return deadline >= block.timestamp ? deadline - block.timestamp : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()

    function receive() notCompleted external payable {
        stake();
    }

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }
}