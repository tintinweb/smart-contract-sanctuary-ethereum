// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

    bool public completed = false;

    address public owner;

    // @notice Change completed to true if everything is ok for Staker.sol, and only Staker.sol can call it
    function complete() public payable returns (bool) {
        require(owner == msg.sender, "You are not the owner");
        completed = true;
        return true;
    }

    // @notice Set the owner of the contract on deploy
    // @param _owner The address of the owner of the contract
    function setOwnerOnDeploy(address _owner) public {
        require(owner == 0x0000000000000000000000000000000000000000, "Already set");
        owner = _owner;
    }

    // @notice A simple withdraw function that let everyone withdraw the contract funds
    function withdraw() public {
        uint amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {

    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint public deadline;

    uint256 public constant threshold = 2 ether;

    bool public openForWithdraw = false;

    event Stake(address benficiary, uint256 amount);


    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
        exampleExternalContract.setOwnerOnDeploy(address(this));
    }

    // @notice Stake some ether to the contract to be able to withdraw it later in the ExampleExternalContract
    function stake() public payable notCompleted {
        require(msg.value > 0, "Amount must be greater than 0");
        require(!openForWithdraw, "To late to stake more");
        if (deadline == 0) {
            deadline = block.timestamp + 72 hours;
        } else {
            require(block.timestamp < deadline, "To late to stake more");
        }
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // @notice If the deadline has passed and the threshold is met, it send the Ether to the other contract otherwise it let the user withdraw the fund
    function execute() public notCompleted {
        require(timeLeft() == 0, "Deadline has not passed");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete();
            uint amount = address(this).balance;
            bool success = exampleExternalContract.complete{value: amount}();
            require(success, "Failed to send Ether");
        } else {
            openForWithdraw = true;
        }
        deadline = 0;
    }

    // @notice A withdraw function that let everyone withdraw theyr funds
    function withdraw() public notCompleted {
        require(balances[msg.sender] > 0, "You can only withdraw if you have a balance");
        require(openForWithdraw == true, "You can only withdraw if you are authorised");
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
        if (address(this).balance == 0) {
            openForWithdraw = false;
        }
    }

    // @notice Return the time left before the deadline
    function timeLeft() public view returns (uint256) {
        require(deadline > 0, "Deadline has not been set");
        if ( block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // @notice Call the stake() function if some Ether is send to the contract
    receive() external payable{
        stake();
    }

    // @notice Create a require that check if the completed function of exampleExternalContract is false
    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "ExampleExternalContract has already been completed");
        _;
    }

}