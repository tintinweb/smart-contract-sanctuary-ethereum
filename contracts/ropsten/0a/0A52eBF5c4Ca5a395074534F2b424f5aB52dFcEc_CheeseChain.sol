// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CheeseChain {

    uint public totalSteps; //starts at 0
    uint public totalLots; //starts at 0

    struct TestResult {
        bool result;
        uint timestamp;
    }

    struct Lot {
        TestResult testResult;
        uint lastStep;
        uint timeStamp;
    }

    struct Step {
        address owner;
        uint previousStep;
        uint timeStamp;
    }

    mapping(uint => Step) public steps;

    mapping(uint => Lot) public lots;

    event LotAdded(uint indexed _lotId, uint _timeStamp);
    event StepAdded(uint indexed _stepId, uint _timeStamp);

    function addLot() public {
        totalLots += 1;
        TestResult memory test = TestResult(false, 0);
        lots[totalLots] = Lot(test, 0, block.timestamp);
        emit LotAdded(totalLots, block.timestamp);
    }

    function addStep(uint lotNumber) public {
        totalSteps += 1;
        steps[totalSteps] = Step(msg.sender, lots[lotNumber].lastStep, block.timestamp);
        lots[lotNumber].lastStep = totalSteps;
        emit StepAdded(totalSteps, block.timestamp);
    }

    function addLabResult(uint lotNumber, bool result) public {
        lots[lotNumber].testResult = TestResult(result, block.timestamp);
    }

}