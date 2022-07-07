//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract SimpleStorage {
    struct Storage {
        string name;
    }

    uint256 public index;

    mapping(uint256 => Storage) names;

    function save(string memory _name) external {
        index += 1;
        Storage storage saveName = names[index];
        saveName.name = _name;
    }

    function retrieveName(uint256 _index)
        external
        view
        returns (string memory)
    {
        return names[_index].name;
    }
}