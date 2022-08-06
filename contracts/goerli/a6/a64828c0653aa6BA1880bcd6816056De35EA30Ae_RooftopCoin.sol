// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract RooftopCoin {

    uint256 private emision;

    mapping(address => uint256) private balance;

    address public owner;

    event SendEvent(address indexed receiver, uint256 indexed amount);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier checkBalance(uint256 _amount) {
        require(balance[owner] >= _amount, "Fondos insuficientes");
        _;
    }

    constructor(uint _emision) {
        owner = msg.sender;
        emision = _emision;
        balance[owner] = _emision;
    }

    function send(address _addr, uint256 _amount)
        external
        isOwner
        checkBalance(_amount)
    {
        _send(_addr, _amount);
    }

    function _send(address _addr, uint256 _amount) internal isOwner {
        emit SendEvent(_addr, _amount);
        balance[owner] = balance[owner] - _amount;
        balance[_addr] = balance[_addr] + _amount;
    }

    function getBalance(address _addr) external view returns (uint256) {
        return balance[_addr];
    }

    function calc(uint256 _value) external pure returns (uint256) {
        uint256 a = 1;
        uint256 b = 3;
        return (a + b + _value);
    }
}