// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "./ExampleExternalContract.sol";

// Author: Tai Nguyen Nhan :-) 4
contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    event Stake(address indexed from, uint256 value);

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithDraw = false;

    modifier passedDeadline() {
        require(block.timestamp >= deadline, "Deadline not passed");
        _;
    }

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Staking is completed");
        _;
    }

    function stake() public payable notCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function execute() public passedDeadline notCompleted {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else if (address(this).balance < threshold) {
            openForWithDraw = true;
        }
    }

    function withdraw() public notCompleted {
        if (openForWithDraw) {
            uint256 money = balances[msg.sender];
            balances[msg.sender] = 0;

            (bool success, ) = msg.sender.call{value: money}("");
            require(success, "Transaction failed");
        }
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        uint256 time = deadline - block.timestamp;
        return time;
    }

    receive() external payable {
        stake();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {
    bool public completed;

    function complete() public payable {
        completed = true;
    }
}