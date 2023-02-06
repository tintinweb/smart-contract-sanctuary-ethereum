// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ControlStructures {
    function fizzBuzz(uint _number) public pure returns (string memory) {
        if(_number % 3 == 0 && _number % 5 == 0) {
            return "FizzBuzz";
        } else if(_number % 3 == 0) {
            return "Fizz";
        } else if(_number % 5 == 0) {
            return "Buzz";
        } else {
            return "Splat";
        }
    }

    error AfterHours(uint _time);
    function doNotDisturb(uint _time) public pure returns (string memory) {
        assert(_time < 2400);
        if(_time > 2200 || _time < 800) {
            revert AfterHours(_time);
        }
        require(_time < 1200 || _time > 1259, "At lunch!");

        if(_time >= 800 && _time <= 1199) {
            return "Morning!";
        } else if (_time >= 1300 && _time <= 1799) {
            return "Afternoon!";
        } else {
            return "Evening";
        }
    }
}