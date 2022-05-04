// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {
    bool public completed = false;

    function complete() public payable {
        completed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    event Stake(address indexed _address, uint256 _balance); //this is the event to log addresses and balances

    mapping(address => uint256) public balances; //mapping to hold all addresses and their balances

    uint256 public constant threshold = 1 ether; //constant to hold threshold

    uint256 public deadline = block.timestamp + 72 hours;

    modifier deadlineReached(bool requireReaced) {
        uint256 timeRemaining = timeLeft();
        if (requireReaced) {
            require(timeRemaining == 0, "Deadline is not reached yet");
        } else {
            require(timeRemaining > 0, "Deadline is already reached");
        }
        _;
    }

    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed noo");
        _;
    }

    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    function stake() public payable deadlineReached(false) stakeNotCompleted {
        //require(msg.value >= threshold); //make sure the client is sending at least 1 ether
        //exampleExternalContract.complete();
        //payable(address(msg.sender)).transfer(msg.value);
        balances[msg.sender] += msg.value; //set the balance of the mapping for that particular address
        emit Stake(msg.sender, msg.value); //emit the event
    }

    receive() external payable {
        stake();
    }

    function execute() public stakeNotCompleted deadlineReached(false) {
        uint256 contractBalance = address(this).balance;

        // check the contract has enough ETH to reach the treshold
        require(contractBalance >= threshold, "Threshold not reached");

        // Execute the external contract, transfer all the balance to the contract
        // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}();
        (bool sent, ) = address(exampleExternalContract).call{
            value: contractBalance
        }(abi.encodeWithSignature("complete()"));
        require(sent, "exampleExternalContract.complete failed");
    }

    function withdraw() public deadlineReached(true) stakeNotCompleted {
        uint256 userBalance = balances[msg.sender];

        // check if the user has balance to withdraw
        require(userBalance > 0, "You don't have balance to withdraw");

        // reset the balance of the user
        balances[msg.sender] = 0;

        // Transfer balance back to the user
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        require(sent, "Failed to send user balance back to the user");
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function

    // Add a `withdraw()` function to let users withdraw their balance

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}