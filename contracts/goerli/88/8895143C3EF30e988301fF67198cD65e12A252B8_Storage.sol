//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Storage {
    struct InkValues {
        uint8 cyan;
        uint8 magenta;
        uint8 yellow;
        uint8 black;
    }

    InkValues[] inkBook;
    string[] inkName;

    mapping(string => InkValues) public search;

    function storeNewInk(
        string memory _inkName,
        uint8 _cyan,
        uint8 _magenta,
        uint8 _yellow,
        uint8 _black
    ) public {
        inkBook.push(InkValues(_cyan, _magenta, _yellow, _black));
        inkName.push(_inkName);
    }
}