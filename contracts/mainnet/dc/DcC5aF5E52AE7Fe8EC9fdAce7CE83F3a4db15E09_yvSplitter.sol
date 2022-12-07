// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract yvSplitter {
    address[] recievers = [0x98e0b03e9a722B57CE97EEB0eb2930C6FeC55584, 0xFF1fe72346002C71030cB8690Ddc4993b88C376E];
    uint256[] shares = [67, 33];

    function withdraw() external {
        uint256 balance = address(this).balance;
        for (uint256 i; i < recievers.length; i++) {
            uint256 amountToSend = (balance * shares[i]) / 100;
            payable(recievers[i]).transfer(amountToSend);
        }
    }

    receive() external payable {}
}