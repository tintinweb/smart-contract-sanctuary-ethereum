// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract GasTest1 {
    uint[] public arrayFunds;
    uint public totalFunds;

    constructor() {
        arrayFunds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    }

    function optionA() external {
        for (uint i = 0; i < arrayFunds.length; i++) {
            totalFunds = totalFunds + arrayFunds[i];
        }
    }

    function optionB() external {
        uint _totalFunds;
        for (uint i = 0; i < arrayFunds.length; i++) {
            _totalFunds = _totalFunds + arrayFunds[i];
        }
        totalFunds = _totalFunds;
    }

    function optionC() external {
        uint _totalFunds;
        uint[] memory _arrayFunds = arrayFunds;
        for (uint i = 0; i < _arrayFunds.length; i++) {
            _totalFunds = _totalFunds + _arrayFunds[i];
        }
        totalFunds = _totalFunds;
    }

    function optionD() external {
        uint _totalFunds;
        uint[] memory _arrayFunds = arrayFunds;
        for (uint i = 0; i < _arrayFunds.length; i = unsafe_inc(i)) {
            _totalFunds = _totalFunds + _arrayFunds[i];
        }
        totalFunds = _totalFunds;
    }

    function unsafe_inc(uint x) private pure returns (uint) {
        unchecked {
            return x + 1;
        }
    }
}