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

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;

    mapping(address => uint256) public balances;

    event Stake(address indexed sender, uint256 amount);
    event Received(address, uint256);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    modifier notCompleted() {
        require(
            exampleExternalContract.completed() == false,
            "Already Completed"
        );
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable notCompleted {
        require(timeLeft() > 0, "Deadline is expired");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() external notCompleted {
        require(timeLeft() == 0, "Deadline is not expired");

        uint256 currentBalance = address(this).balance;
        require(
            openForWithdraw == false || currentBalance > 0,
            "No funds were collected"
        );

        if (currentBalance >= threshold) {
            (bool succ, ) = address(exampleExternalContract).call{
                value: currentBalance
            }(abi.encodeWithSignature("complete()"));
            require(succ, "call Failed");
        } else {
            openForWithdraw = true;
        }
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() external {
        uint256 userBalance = balances[msg.sender];
        // require(timeLeft() == 0, "Deadline is not expired");

        require(openForWithdraw, "Can't Withdraw");

        require(userBalance > 0, "Dont have any balance");

        //prevent reentracy attacks
        balances[msg.sender] = 0;

        (bool succ, ) = payable(msg.sender).call{value: userBalance}("");
        require(succ, "Failed to withdraw user funds");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return deadline >= block.timestamp ? deadline - block.timestamp : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {}
}