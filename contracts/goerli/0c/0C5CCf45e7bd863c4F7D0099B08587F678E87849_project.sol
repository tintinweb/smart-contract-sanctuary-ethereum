pragma solidity ^0.8.0;

contract project {
    event entervalue(uint256 yournumber);

    function CoolectNumb(uint256 _enterNumber) public {
        emit entervalue(_enterNumber);
    }
}