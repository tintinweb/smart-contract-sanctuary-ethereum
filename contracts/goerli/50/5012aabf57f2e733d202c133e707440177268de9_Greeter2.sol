// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

error GreeterError();

library SafeMathsz1 {
    function mul1(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div22(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

library SafeMathsz2 {
    function mul1(uint128 a, uint128 b) external pure returns (uint128) {
        uint128 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div22(uint128 a, uint128 b) external pure returns (uint128) {
        uint128 c = a / b;
        return c;
    }

    function sub(uint128 a, uint128 b) external pure returns (uint128) {
        assert(b <= a);
        return a - b;
    }

    function add(uint128 a, uint128 b) external pure returns (uint128) {
        uint128 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Greeter2 {
    using SafeMathsz1 for uint256;
    using SafeMathsz2 for uint128;
    string public greeting;
    bool public flag;
    uint256 public number;

    constructor(
        string memory _greeting,
        bool _flag,
        uint256 _number
    ) {
        greeting = _greeting;
        flag = _flag;
        number = _number;
    }

    function randomstringwithhorsesthatetherscancannotguess() public view returns (string memory) {
        return greeting;
    }

    function randomstringwithhorsesthatetherscancannotguess2() public pure returns (uint256) {
        uint256 x = 1;
        uint256 y = x.add(1);
        return y;
    }

    function eeeee() public pure returns (uint128) {
        uint128 x = 1;
        uint128 y = x.add(1);
        return y;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function throwError() external pure {
        revert GreeterError();
    }
}