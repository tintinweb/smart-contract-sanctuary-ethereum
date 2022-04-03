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

// import "../node_modules/hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    event Stake(address, uint256);

    event Time(uint256);

    // track all user accounts balances
    mapping(address => uint256) public balances;

    // set the default threshold
    uint256 public constant threshold = 1 ether;

    //set the deadline to 1 week
    uint256 public deadline = block.timestamp + 72 minutes;

    // get contractBal
    // uint256 private contractBal = address(this).balance;

    // Set the state to be open for withdrawal
    bool public openForWithdraw;

    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        // Track the balance
        balances[msg.sender] += msg.value;

        // Emit the staking balance
        emit Stake(msg.sender, msg.value);
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed(),
            "Staking period has completed"
        );
        _;
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public notCompleted {
        uint256 contractBal = address(this).balance;

        require(block.timestamp > deadline, "Wait time has not yet expired");
        require(openForWithdraw == false, "Function can only be called once");

        if (contractBal > threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        }

        //  Set open withdraw to true
        openForWithdraw = true;
    }

    // if the `threshold` was not met, allow everyone to call a `withdraw()` function

    // Add a `withdraw()` function to let users withdraw their balance
    function withdraw() public notCompleted {
        // get the stakeholder address
        address _stakeholder = msg.sender;

        // Get the stakeholder stake amount
        uint256 stakeholderStakeBal = balances[_stakeholder];

        require(
            openForWithdraw == true,
            "Funds are not yet allowed for withdrawal"
        );

        // check if the user has balance to withdraw
        require(stakeholderStakeBal > 0, "You don't have balance to withdraw");

        uint stakeholderBalance = _stakeholder.balance;

        // transfer sender's balance to the `_to` address
        (bool sent, ) = _stakeholder.call{value: stakeholderStakeBal}("");

        // Transfer stake stakeholder balance
        stakeholderStakeBal += stakeholderBalance;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        this.stake();
    }
}