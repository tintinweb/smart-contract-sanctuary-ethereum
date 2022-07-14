// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PixelArtContract {
    uint constant ROWS = 3;
    uint constant COLUMNS = 3;
    bytes3[ROWS][COLUMNS] public colorsStorage;

    event Recorded(address indexed sender, uint _row, uint _column, bytes3 color);

    constructor() {
    }

    function writeColor(uint _row, uint _column, bytes3 color) external {
        require(_row < ROWS && _column < COLUMNS, "Incorrect row or column");
        colorsStorage[_row][_column] = color;
        emit Recorded(msg.sender, _row, _column, color);
    }
}