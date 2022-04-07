// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ZombieMarket.sol";
import "./ZombieFeed.sol";
import "./ZombieAttack.sol";

// 实现核心逻辑
contract ZombieCore is ZombieFeed, ZombieMarket, ZombieAttack {
    string public constant name = "MikeCryptoZombie";
    string public constant symbol = "MKCZ";

    // fallback() external payable {}

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function checkBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}