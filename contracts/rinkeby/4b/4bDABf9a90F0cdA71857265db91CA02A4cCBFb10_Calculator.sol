// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./SafeMath.sol";
import "./Ownable.sol";

contract Calculator is Ownable {
    using SafeMath for uint256;

    uint256 result = 0;
    event Result(uint256 result);

    function Add(uint256 param1, uint256 param2) public onlyOwner {
        result = param1.add(param2);
        emit Result(result);
    }

    function Subtract(uint256 param1, uint256 param2) public {
        result = param1.sub(param2);
        emit Result(result);
    }

    function Multiply(uint256 param1, uint256 param2) public {
        result = param1.mul(param2);
        emit Result(result);
    }

    function Divide(uint256 param1, uint256 param2) public {
        result = param1.div(param2);
        emit Result(result);
    }

    function Mod(uint256 param1, uint256 param2) public {
        result = param1.mod(param2);
        emit Result(result);
    }
}