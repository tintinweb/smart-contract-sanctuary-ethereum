pragma solidity ^0.8.0;

contract project {
    event entervalue(uint256 yournumber);
    event enternvalue(string name);

    function CoolectNumb(uint256 _enterNumber) public {
        emit entervalue(_enterNumber);
    }

    function CoolectName(string memory _enterName) public {
        emit enternvalue(_enterName);
    }
}