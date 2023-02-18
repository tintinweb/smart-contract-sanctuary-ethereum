// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherDistributor {
    event EvenDistribution(address[] addresses, uint256 amount);
    event RandomDistribution(address recipient, uint256 amount);

    function distributeEvenly(address[] memory addresses) payable public {
        uint256 count = addresses.length;
        require(count > 0, "No addresses provided");
        require(msg.value > 0, "No ether provided");

        uint256 amountPerAddress = msg.value / count;

        for (uint256 i = 0; i < count; i++) {
            payable(addresses[i]).transfer(amountPerAddress);
        }

        emit EvenDistribution(addresses, amountPerAddress);
    }

    function distributeRandomly(address[] memory addresses) payable public {
        uint256 count = addresses.length;
        require(count > 0, "No addresses provided");
        require(msg.value > 0, "No ether provided");

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % count;

        payable(addresses[randomIndex]).transfer(msg.value);

        emit RandomDistribution(addresses[randomIndex], msg.value);
    }
}