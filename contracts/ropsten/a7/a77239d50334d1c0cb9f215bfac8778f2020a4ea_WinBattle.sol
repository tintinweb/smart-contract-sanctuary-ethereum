/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtheremonLite {
    function initMonster(string memory _monsterName) public {}

    function getName(address _monsterAddress)
        public
        view
        returns (string memory)
    {}

    function getNumWins(address _monsterAddress)
        public
        view
        returns (uint256)
    {}

    function getNumLosses(address _monsterAddress)
        public
        view
        returns (uint256)
    {}

    function battle() public returns (bool) {}
}

contract WinBattle {
    address parent = 0x3be82246fF8Df285029786Ed28D0bDb55544B0c6;
    EtheremonLite el;

    constructor() {
        el = EtheremonLite(parent);
        el.initMonster("hcd36");
    }

    function win() public {
        uint256 prob = uint256(blockhash(block.number - 1)) / 85;
        if (prob % 3 == 0) {
            for (uint256 i = 0; i < 3; i++) {
                el.battle();
            }
        }
    }
}