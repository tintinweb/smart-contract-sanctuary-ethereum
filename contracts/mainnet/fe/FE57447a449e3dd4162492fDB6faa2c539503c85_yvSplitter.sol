// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract yvSplitter {
    address[] recievers = [0x98e0b03e9a722B57CE97EEB0eb2930C6FeC55584, 0x65893Cf800F070D7c5e115BB6d1DFd492396B1BB];
    uint256[] shares = [67, 33];

    function withdraw() external {
        uint256 balance = address(this).balance;
        for (uint256 i; i < recievers.length; i++) {
            uint256 amountToSend = (balance * shares[i]) / 100;
            payable(recievers[i]).transfer(amountToSend);
        }
    }

    function withdrawERC20(IERC20 token) external {
        uint256 balance = token.balanceOf(address(this));
        for (uint256 i; i < recievers.length; i++) {
            uint256 amountToSend = (balance * shares[i]) / 100;
            token.transfer(recievers[i], amountToSend);
        }
    }

    receive() external payable {}
}