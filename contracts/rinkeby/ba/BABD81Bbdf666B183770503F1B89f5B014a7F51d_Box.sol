// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Box {
    uint256 private value;

    event ValueChanged(uint256 _newValue);

    // protoze chceme aby to byly Proxies, tak nemame constructor!
    // misto toho se dela nejaky typ Initializera (spoustece), coz je nejaka funkce, ktera se vola hned po deploynuti conttractu
    // v tomhle demu zadna Initializer fce neni

    function store(uint256 _newValue) public {
        value = _newValue;
        emit ValueChanged(_newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}