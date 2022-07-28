// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Nyoom {
    mapping(address => uint256) private dough;

    constructor() {}

    function coinage(address _who) public view returns (uint256) {
        return dough[_who];
    }

    function stonks(uint256 _currency) public {
        dough[msg.sender] += _currency;
    }

    function notStonks(uint256 _legalTender) public {
        require(
            dough[msg.sender] >= _legalTender,
            "You don't got enough moolah to lose"
        );
        dough[msg.sender] -= _legalTender;
    }

    function shareThisBread(address _to, uint256 _loot) public {
        require(
            dough[msg.sender] >= _loot,
            "You can't share what you don't have"
        );
        dough[msg.sender] -= _loot;
        dough[_to] += _loot;
    }
}