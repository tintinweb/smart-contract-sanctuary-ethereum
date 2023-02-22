// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

error Withdraw__HasEther();
error No_MetThreshold();

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    address[] public s_player;
    mapping(address => uint256) public s_addressToAmountStake;
    uint256 public totalEther;
    uint public constant threshold = 1 ether;
    uint public deadline = block.timestamp + 72 hours;

    /* Events */
    event Stake(address indexed player, uint256 indexed stake);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // Modifiers
    modifier onlyPlayerAndHasEther() {
        // require(msg.sender == i_owner);
        require(
            s_addressToAmountStake[msg.sender] > 0,
            "Your account has no balance"
        );
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        require(block.timestamp < deadline, "time has passed");
        s_addressToAmountStake[msg.sender] += msg.value;
        s_player.push(payable(msg.sender));
        totalEther += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public onlyPlayerAndHasEther {
        require(
            totalEther >= threshold && block.timestamp >= deadline,
            "The bet has not reached the limit or the time has not expired"
        );

        exampleExternalContract.complete{value: address(this).balance}();
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public onlyPlayerAndHasEther {
        require(
            totalEther < threshold && block.timestamp >= deadline,
            "Bets reached the limit or the time has not expired"
        );
        (bool success, ) = payable(msg.sender).call{
            value: s_addressToAmountStake[msg.sender]
        }("");
        if (success) s_addressToAmountStake[msg.sender] = 0;
        require(success);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) return 0;
        else return deadline - block.timestamp;
        // uint256 time = block.timestamp >= deadline;
        // return time > 0 ? time : 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    function recieve() external payable {
        stake();
    }
}