/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity 0.8.16;

contract Deployed {
    uint256 currentNumber;

    event NewNumber(uint256 indexed number);

    function setNumber(uint256 newNumber) external {
        currentNumber = newNumber;
        emit NewNumber(newNumber);
    }
}