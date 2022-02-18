//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract Knight_levelup {
    string public name;
    uint256 public lvl;
    mapping(string => uint256) public actions;

    function levelup(string memory _action, uint _dmg ) external {
        lvl += 1;
        actions[_action] = _dmg;
    }
}