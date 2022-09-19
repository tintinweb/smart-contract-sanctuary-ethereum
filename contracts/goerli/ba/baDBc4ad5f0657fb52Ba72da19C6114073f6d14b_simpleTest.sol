pragma solidity 0.8.4;

contract simpleTest {

    uint public number;

    function addNumber() public {
        number++;
    }

    function subNumber() public {
        number--;
    }

    function testAdd(uint _t) public {
        number += _t;
    }

    function testSub(uint _t) public {
        number -= _t;
    }

    /// @return alo test test
    function testComment() public view returns (uint256) {
        uint alo = number;
        return alo;
    }

    /// @return test test
    function testComment2() public view returns (uint256) {
        uint alo = number;
        return alo;
    }

    /// @return test test
    function testComment3() public view returns (uint256) {
        return number;
    }

    address public owner;

    function updateOwner(address newOwner) external {
        owner = newOwner;
    }

    constructor() {
        owner = msg.sender;
    }

}