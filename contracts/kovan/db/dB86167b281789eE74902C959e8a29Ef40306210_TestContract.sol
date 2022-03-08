/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    uint256 public tokenId;
    struct character {
        string name;
        uint256 gender;
        uint256 father;
        uint256 mother;
    }

    constructor() {
        tokenId = 0;
    }

    character[] public obj;

    function createCharacter(string memory name, uint256 gender) external {
        obj[tokenId++] = character(name, gender, 0, 0);
    }

    function createChildCharacter(uint256 father, uint256 mother) external {
        obj[tokenId++] = character(
            // string.concat(obj[father].name, obj[mother].name),
            obj[father].name,
            tokenId % 2,
            father,
            mother
        );
    }

    function getParent(uint256 id)
        external
        view
        returns (character memory, character memory)
    {
        return (obj[obj[id].father], obj[obj[id].mother]);
    }

    function changeName(uint256 id, string memory name) external {
        obj[id].name = name;
    }

    function getChildrenFromParent(uint256 father, uint256 mother)
        external
        view
        returns (character[] memory)
    {
        character[] memory res;
        uint256 j = 0;
        for (uint256 i = 0; i < tokenId; i++) {
            if (obj[i].father == father && obj[i].mother == mother) {
                res[j++] = obj[i];
            }
        }
        return res;
    }

    function getChildFromTokenId(uint256 id)
        external
        view
        returns (character memory)
    {
        return obj[id];
    }
}