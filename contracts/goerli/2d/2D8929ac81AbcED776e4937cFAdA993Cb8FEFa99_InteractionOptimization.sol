//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract InteractionOptimization {
    uint256 public number;
    uint256 public additionResult;
    uint256 public sum;
    uint256[] public result;
    mapping(uint256 => uint256[]) public turnNumberToResult;
    uint256[] public resultForMapping;

    uint256 private number1;
    uint256 private sum1;
    uint256 private additionResult1;
    uint256[] private result1;
    mapping(uint256 => uint256[]) private turnNumberToResult1;
    uint256[] public resultForMapping1;

    uint256[] private cheaperResult;

    //cost 65883 gas
    function setNumber(uint256 _number) public {
        number = _number;
        number1 = _number;
    }

    //cost 45754 gas
    function setAdditionResult() public {
        additionResult = number + number;
    }

    //cost 45732 gas
    function setAdditionResult1() public {
        additionResult1 = number1 + number1;
    }

    //cost 47821 gas
    function getSum() public {
        sum = number + additionResult;
    }

    //cost 47798 gas
    function getSum1() public {
        sum1 = number1 + additionResult1;
    }

    //cost 252293 gas
    function getMultiplyOfNumber(uint256 howManyTurns) public {
        for (uint256 i = 1; i < howManyTurns; i++) {
            uint256 mul = i * number;
            result.push(mul);
        }
    }

    //cost 252336 gas
    function getMultiplyOfNumber1(uint256 howManyTurns) public {
        for (uint256 i = 1; i < howManyTurns; i++) {
            uint256 mul = i * number1;
            result1.push(mul);
        }
    }

    // cost 251507 gas
    function cheaperMultiply(uint256 howManyTurns) public {
        uint256 num = number1;
        for (uint256 i = 1; i < howManyTurns; i++) {
            uint256 mul = i * num;
            cheaperResult.push(mul);
        }
    }

    //cost 475761 gas
    function setTurnNumberToResult(uint256 howManyTurns) public {
        resultForMapping = new uint256[](0);
        for (uint256 i = 1; i < howManyTurns; i++) {
            uint256 mul = i * number;
            resultForMapping.push(mul);
        }
        turnNumberToResult[howManyTurns] = resultForMapping;
    }

    //cost 475829 gas
    function setTurnNumberToResult1(uint256 howManyTurns) public {
        resultForMapping1 = new uint256[](0);
        for (uint256 i = 1; i < howManyTurns; i++) {
            uint256 mul = i * number;
            resultForMapping1.push(mul);
        }
        turnNumberToResult1[howManyTurns] = resultForMapping1;
    }
}