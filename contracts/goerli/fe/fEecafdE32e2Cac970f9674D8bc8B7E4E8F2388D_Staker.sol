// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

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
    event tokensStaked(address from, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);
    event received(address from, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadlineTimestamp = block.timestamp + 72 hours;
    bool public openForWithdraw;
    // Contract's Modifiers
    /**
     * @notice Modifier that require the deadline to be reached or not
     * @param requireDeadlinePassed Check if the deadline has reached or not
     */
    modifier deadlinePassed(bool requireDeadlinePassed) {
        uint256 timeRemaining = timeLeft();
        if (requireDeadlinePassed) {
            require(timeRemaining == 0, "Deadline has passed");
        } else {
            require(timeRemaining > 0, "Deadline has not passed yet");
        }
        _;
    }

    /**
     * @notice Modifier that require the external contract to not be completed
     */
    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }

    modifier stakeThresholdMet() {
        require(
            address(this).balance >= threshold,
            "Total balance not over the staking threshhold"
        );
        _;
    }
    modifier StakeAmountGT0(uint256 amtStaked) {
        require(amtStaked > 0, "You can't stake without tokens!");
        _;
    }

    function stake() public payable StakeAmountGT0(msg.value) returns (bool) {
        balances[msg.sender] += msg.value;
        emit tokensStaked(msg.sender, msg.value);
        return true;
    }

    function getContractBalance() public view returns (uint256) {
        //view amount of ETH the contract contains
        return address(this).balance;
    }

    function getDepositorBalance() public view returns (uint256) {
        //view amount of ETH the contract contains
        return balances[msg.sender];
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public stakeNotCompleted deadlinePassed(true) {
        uint256 contractBalance = address(this).balance;
        // check the contract has enough ETH to reach the treshold
        if (contractBalance >= threshold) {
            // Execute the external contract, transfer all the balance to the contract
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    ///#value: 100
    function withdraw() public deadlinePassed(true) {
        require(openForWithdraw, "Not open for withdraw");
        require(balances[msg.sender] > 0, "User has no deposits");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to send ether");
        emit TokensUnstaked(msg.sender, balance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        return
            block.timestamp >= deadlineTimestamp
                ? 0
                : deadlineTimestamp - block.timestamp;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable StakeAmountGT0(msg.value) {
        emit received(msg.sender, msg.value);
    }
}