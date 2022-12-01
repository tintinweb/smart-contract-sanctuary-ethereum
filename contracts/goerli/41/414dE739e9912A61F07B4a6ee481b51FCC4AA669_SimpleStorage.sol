// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    uint256 numeroFavo;

    People[] public people;
    uint256[] public numeros;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint _numeroFavo) public virtual {
        numeroFavo = _numeroFavo;
        numeroFavo += 1;
    }

    function retrieve() public view returns (uint256) {
        return numeroFavo;
    }

    //0xd9145CCE52D386f254917e481eB44e9943F39138
}