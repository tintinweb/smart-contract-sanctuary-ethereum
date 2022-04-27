// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IRandomNumberGenerator {
    function computerSeed(uint256) external view returns(uint256);
    function getResultNumber() external view returns(uint256, uint256, uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

import "../interfaces/IRandomNumberGenerator.sol";

contract DataStorage {
    uint256 constant N_PETS = 9;
    uint256 constant N_EGGS = 6;
    uint256 constant BASE_POWER = 10000;
    uint256 constant MULTIPLIER = 15;
    uint256 constant PRECISION = 10;
        uint256 constant SAMPLE_SPACE = 10000000000;

    uint256[N_EGGS] private pandoBoxCreating;
    mapping (uint256 => mapping(uint256 => uint256)) private droidBotCreating;
    mapping (uint256 => mapping(uint256 => mapping(uint256 => uint256))) private droidBotUpgrading;
    uint256[N_PETS - 1] public nTickets;

    constructor() {
        pandoBoxCreating = [9000000000 , 700000000, 200000000, 75000000, 20000000, 5000000];
        nTickets = [1, 2, 3, 4, 5, 8, 11, 17];
        droidBotCreating[0][0] = 9000000000;
        droidBotCreating[0][1] = 650000000;
        droidBotCreating[0][2] = 210400000;
        droidBotCreating[0][3] = 84160000;
        droidBotCreating[0][4] = 33664000;
        droidBotCreating[0][5] = 13465600;
        droidBotCreating[0][6] = 5386240;
        droidBotCreating[0][7] = 2154496;
        droidBotCreating[0][8] = 769664;


        droidBotCreating[1][0] = 0;
        droidBotCreating[1][1] = 9000000000;
        droidBotCreating[1][2] = 650000000;
        droidBotCreating[1][3] = 211000000;
        droidBotCreating[1][4] = 84400000;
        droidBotCreating[1][5] = 33760000;
        droidBotCreating[1][6] = 13504000;
        droidBotCreating[1][7] = 5401600;
        droidBotCreating[1][8] = 1934400;

        droidBotCreating[2][0] = 0;
        droidBotCreating[2][1] = 0;
        droidBotCreating[2][2] = 9000000000;
        droidBotCreating[2][3] = 650000000;
        droidBotCreating[2][4] = 212500000;
        droidBotCreating[2][5] = 85000000;
        droidBotCreating[2][6] = 34000000;
        droidBotCreating[2][7] = 13600000;
        droidBotCreating[2][8] = 4900000;

        droidBotCreating[3][0] = 0;
        droidBotCreating[3][1] = 0;
        droidBotCreating[3][2] = 0;
        droidBotCreating[3][3] = 9000000000;
        droidBotCreating[3][4] = 650000000;
        droidBotCreating[3][5] = 216500000;
        droidBotCreating[3][6] = 86600000;
        droidBotCreating[3][7] = 34640000;
        droidBotCreating[3][8] = 12260000;

        droidBotCreating[4][0] = 0;
        droidBotCreating[4][1] = 0;
        droidBotCreating[4][2] = 0;
        droidBotCreating[4][3] = 0;
        droidBotCreating[4][4] = 9000000000;
        droidBotCreating[4][5] = 650000000;
        droidBotCreating[4][6] = 227000000;
        droidBotCreating[4][7] = 90800000;
        droidBotCreating[4][8] = 32200000;

        droidBotCreating[5][0] = 0;
        droidBotCreating[5][1] = 0;
        droidBotCreating[5][2] = 0;
        droidBotCreating[5][3] = 0;
        droidBotCreating[5][4] = 0;
        droidBotCreating[5][5] = 9000000000;
        droidBotCreating[5][6] = 650000000;
        droidBotCreating[5][7] = 258000000;
        droidBotCreating[5][8] = 92000000;

        droidBotUpgrading[0][0][0] = 2670000000;
        droidBotUpgrading[0][0][1] = 7000000000;
        droidBotUpgrading[0][0][2] = 257000000;
        droidBotUpgrading[0][0][3] = 51120000;
        droidBotUpgrading[0][0][4] = 15336000;
        droidBotUpgrading[0][0][5] = 4600800;
        droidBotUpgrading[0][0][6] = 1380240;
        droidBotUpgrading[0][0][7] = 414072;
        droidBotUpgrading[0][0][8] = 148888;

        droidBotUpgrading[1][1][0] = 0;
        droidBotUpgrading[1][1][1] = 2670000000;
        droidBotUpgrading[1][1][2] = 7000000000;
        droidBotUpgrading[1][1][3] = 257000000;
        droidBotUpgrading[1][1][4] = 51200000;
        droidBotUpgrading[1][1][5] = 15360000;
        droidBotUpgrading[1][1][6] = 4608000;
        droidBotUpgrading[1][1][7] = 1382400;
        droidBotUpgrading[1][1][8] = 449600;

        droidBotUpgrading[1][0][0] = 0;
        droidBotUpgrading[1][0][1] = 6485500000;
        droidBotUpgrading[1][0][2] = 3300000000;
        droidBotUpgrading[1][0][3] = 167050000;
        droidBotUpgrading[1][0][4] = 33280000;
        droidBotUpgrading[1][0][5] = 9984000;
        droidBotUpgrading[1][0][6] = 2995200;
        droidBotUpgrading[1][0][7] = 898560;
        droidBotUpgrading[1][0][8] = 292240;

        droidBotUpgrading[2][2][0] = 0;
        droidBotUpgrading[2][2][1] = 0;
        droidBotUpgrading[2][2][2] = 2670000000;
        droidBotUpgrading[2][2][3] = 7000000000;
        droidBotUpgrading[2][2][4] = 257000000;
        droidBotUpgrading[2][2][5] = 51200000;
        droidBotUpgrading[2][2][6] = 15360000;
        droidBotUpgrading[2][2][7] = 4608000;
        droidBotUpgrading[2][2][8] = 1832000;

        droidBotUpgrading[2][1][0] = 0;
        droidBotUpgrading[2][1][1] = 0;
        droidBotUpgrading[2][1][2] = 6485700000;
        droidBotUpgrading[2][1][3] = 3300000000;
        droidBotUpgrading[2][1][4] = 167050000;
        droidBotUpgrading[2][1][5] = 33280000;
        droidBotUpgrading[2][1][6] = 9984000;
        droidBotUpgrading[2][1][7] = 2995200;
        droidBotUpgrading[2][1][8] = 990800;

        droidBotUpgrading[2][0][0] = 0;
        droidBotUpgrading[2][0][1] = 0;
        droidBotUpgrading[2][0][2] = 8651700000;
        droidBotUpgrading[2][0][3] = 1200000000;
        droidBotUpgrading[2][0][4] = 115650000;
        droidBotUpgrading[2][0][5] = 23040000;
        droidBotUpgrading[2][0][6] = 6912000;
        droidBotUpgrading[2][0][7] = 2073600;
        droidBotUpgrading[2][0][8] = 624400;

        droidBotUpgrading[3][3][0] = 0;
        droidBotUpgrading[3][3][1] = 0;
        droidBotUpgrading[3][3][2] = 0;
        droidBotUpgrading[3][3][3] = 2670000000;
        droidBotUpgrading[3][3][4] = 7000000000;
        droidBotUpgrading[3][3][5] = 257000000;
        droidBotUpgrading[3][3][6] = 51200000;
        droidBotUpgrading[3][3][7] = 15360000;
        droidBotUpgrading[3][3][8] = 6440000;

        droidBotUpgrading[3][2][0] = 0;
        droidBotUpgrading[3][2][1] = 0;
        droidBotUpgrading[3][2][2] = 0;
        droidBotUpgrading[3][2][3] = 6486600000;
        droidBotUpgrading[3][2][4] = 3300000000;
        droidBotUpgrading[3][2][5] = 167050000;
        droidBotUpgrading[3][2][6] = 33280000;
        droidBotUpgrading[3][2][7] = 9984000;
        droidBotUpgrading[3][2][8] = 3086000;

        droidBotUpgrading[3][1][0] = 0;
        droidBotUpgrading[3][1][1] = 0;
        droidBotUpgrading[3][1][2] = 0;
        droidBotUpgrading[3][1][3] = 8652200000;
        droidBotUpgrading[3][1][4] = 1200000000;
        droidBotUpgrading[3][1][5] = 115650000;
        droidBotUpgrading[3][1][6] = 23040000;
        droidBotUpgrading[3][1][7] = 6912000;
        droidBotUpgrading[3][1][8] = 2198000;

        droidBotUpgrading[3][0][0] = 0;
        droidBotUpgrading[3][0][1] = 0;
        droidBotUpgrading[3][0][2] = 0;
        droidBotUpgrading[3][0][3] = 9517800000;
        droidBotUpgrading[3][0][4] = 400000000;
        droidBotUpgrading[3][0][5] = 64250000;
        droidBotUpgrading[3][0][6] = 12800000;
        droidBotUpgrading[3][0][7] = 3840000;
        droidBotUpgrading[3][0][8] = 1310000;

        droidBotUpgrading[4][4][0] = 0;
        droidBotUpgrading[4][4][1] = 0;
        droidBotUpgrading[4][4][2] = 0;
        droidBotUpgrading[4][4][3] = 0;
        droidBotUpgrading[4][4][4] = 2676000000;
        droidBotUpgrading[4][4][5] = 7000000000;
        droidBotUpgrading[4][4][6] = 257000000;
        droidBotUpgrading[4][4][7] = 51200000;
        droidBotUpgrading[4][4][8] = 15800000;

        droidBotUpgrading[4][3][0] = 0;
        droidBotUpgrading[4][3][1] = 0;
        droidBotUpgrading[4][3][2] = 0;
        droidBotUpgrading[4][3][3] = 0;
        droidBotUpgrading[4][3][4] = 6488600000;
        droidBotUpgrading[4][3][5] = 3300000000;
        droidBotUpgrading[4][3][6] = 167050000;
        droidBotUpgrading[4][3][7] = 33280000;
        droidBotUpgrading[4][3][8] = 11070000;

        droidBotUpgrading[4][2][0] = 0;
        droidBotUpgrading[4][2][1] = 0;
        droidBotUpgrading[4][2][2] = 0;
        droidBotUpgrading[4][2][3] = 0;
        droidBotUpgrading[4][2][4] = 8654200000;
        droidBotUpgrading[4][2][5] = 1200000000;
        droidBotUpgrading[4][2][6] = 115650000;
        droidBotUpgrading[4][2][7] = 23040000;
        droidBotUpgrading[4][2][8] = 7110000;

        droidBotUpgrading[4][1][0] = 0;
        droidBotUpgrading[4][1][1] = 0;
        droidBotUpgrading[4][1][2] = 0;
        droidBotUpgrading[4][1][3] = 0;
        droidBotUpgrading[4][1][4] = 9519500000;
        droidBotUpgrading[4][1][5] = 400000000;
        droidBotUpgrading[4][1][6] = 64250000;
        droidBotUpgrading[4][1][7] = 12800000;
        droidBotUpgrading[4][1][8] = 3450000;

        droidBotUpgrading[4][0][0] = 0;
        droidBotUpgrading[4][0][1] = 0;
        droidBotUpgrading[4][0][2] = 0;
        droidBotUpgrading[4][0][3] = 0;
        droidBotUpgrading[4][0][4] = 9858900000;
        droidBotUpgrading[4][0][5] = 120000000;
        droidBotUpgrading[4][0][6] = 16705000;
        droidBotUpgrading[4][0][7] = 3328000;
        droidBotUpgrading[4][0][8] = 1067000;

        droidBotUpgrading[5][5][0] = 0;
        droidBotUpgrading[5][5][1] = 0;
        droidBotUpgrading[5][5][2] = 0;
        droidBotUpgrading[5][5][3] = 0;
        droidBotUpgrading[5][5][4] = 0;
        droidBotUpgrading[5][5][5] = 2660000000;
        droidBotUpgrading[5][5][6] = 7000000000;
        droidBotUpgrading[5][5][7] = 257000000;
        droidBotUpgrading[5][5][8] = 83000000;

        droidBotUpgrading[5][4][0] = 0;
        droidBotUpgrading[5][4][1] = 0;
        droidBotUpgrading[5][4][2] = 0;
        droidBotUpgrading[5][4][3] = 0;
        droidBotUpgrading[5][4][4] = 0;
        droidBotUpgrading[5][4][5] = 6477600000;
        droidBotUpgrading[5][4][6] = 3300000000;
        droidBotUpgrading[5][4][7] = 167050000;
        droidBotUpgrading[5][4][8] = 55350000;

        droidBotUpgrading[5][4][0] = 0;
        droidBotUpgrading[5][4][1] = 0;
        droidBotUpgrading[5][4][2] = 0;
        droidBotUpgrading[5][4][3] = 0;
        droidBotUpgrading[5][4][4] = 0;
        droidBotUpgrading[5][4][5] = 6477600000;
        droidBotUpgrading[5][4][6] = 3300000000;
        droidBotUpgrading[5][4][7] = 167050000;
        droidBotUpgrading[5][4][8] = 55350000;

        droidBotUpgrading[5][4][0] = 0;
        droidBotUpgrading[5][4][1] = 0;
        droidBotUpgrading[5][4][2] = 0;
        droidBotUpgrading[5][4][3] = 0;
        droidBotUpgrading[5][4][4] = 0;
        droidBotUpgrading[5][4][5] = 6477600000;
        droidBotUpgrading[5][4][6] = 3300000000;
        droidBotUpgrading[5][4][7] = 167050000;
        droidBotUpgrading[5][4][8] = 55350000;

        droidBotUpgrading[5][3][0] = 0;
        droidBotUpgrading[5][3][1] = 0;
        droidBotUpgrading[5][3][2] = 0;
        droidBotUpgrading[5][3][3] = 0;
        droidBotUpgrading[5][3][4] = 0;
        droidBotUpgrading[5][3][5] = 8646200000;
        droidBotUpgrading[5][3][6] = 1200000000;
        droidBotUpgrading[5][3][7] = 115650000;
        droidBotUpgrading[5][3][8] = 38150000;

        droidBotUpgrading[5][2][0] = 0;
        droidBotUpgrading[5][2][1] = 0;
        droidBotUpgrading[5][2][2] = 0;
        droidBotUpgrading[5][2][3] = 0;
        droidBotUpgrading[5][2][4] = 0;
        droidBotUpgrading[5][2][5] = 9514500000;
        droidBotUpgrading[5][2][6] = 400000000;
        droidBotUpgrading[5][2][7] = 64250000;
        droidBotUpgrading[5][2][8] = 21250000;

        droidBotUpgrading[5][1][0] = 0;
        droidBotUpgrading[5][1][1] = 0;
        droidBotUpgrading[5][1][2] = 0;
        droidBotUpgrading[5][1][3] = 0;
        droidBotUpgrading[5][1][4] = 0;
        droidBotUpgrading[5][1][5] = 9841800000;
        droidBotUpgrading[5][1][6] = 125000000;
        droidBotUpgrading[5][1][7] = 25700000;
        droidBotUpgrading[5][1][8] = 7500000;

        droidBotUpgrading[5][0][0] = 0;
        droidBotUpgrading[5][0][1] = 0;
        droidBotUpgrading[5][0][2] = 0;
        droidBotUpgrading[5][0][3] = 0;
        droidBotUpgrading[5][0][4] = 0;
        droidBotUpgrading[5][0][5] = 9956600000;
        droidBotUpgrading[5][0][6] = 30000000;
        droidBotUpgrading[5][0][7] = 10280000;
        droidBotUpgrading[5][0][8] = 3120000;

        droidBotUpgrading[6][6][0] = 0;
        droidBotUpgrading[6][6][1] = 0;
        droidBotUpgrading[6][6][2] = 0;
        droidBotUpgrading[6][6][3] = 0;
        droidBotUpgrading[6][6][4] = 0;
        droidBotUpgrading[6][6][5] = 0;
        droidBotUpgrading[6][6][6] = 2600000000;
        droidBotUpgrading[6][6][7] = 7000000000;
        droidBotUpgrading[6][6][8] = 400000000;

        droidBotUpgrading[6][5][0] = 0;
        droidBotUpgrading[6][5][1] = 0;
        droidBotUpgrading[6][5][2] = 0;
        droidBotUpgrading[6][5][3] = 0;
        droidBotUpgrading[6][5][4] = 0;
        droidBotUpgrading[6][5][5] = 0;
        droidBotUpgrading[6][5][6] = 6470000000;
        droidBotUpgrading[6][5][7] = 3300000000;
        droidBotUpgrading[6][5][8] = 230000000;

        droidBotUpgrading[6][4][0] = 0;
        droidBotUpgrading[6][4][1] = 0;
        droidBotUpgrading[6][4][2] = 0;
        droidBotUpgrading[6][4][3] = 0;
        droidBotUpgrading[6][4][4] = 0;
        droidBotUpgrading[6][4][5] = 0;
        droidBotUpgrading[6][4][6] = 8650000000;
        droidBotUpgrading[6][4][7] = 1200000000;
        droidBotUpgrading[6][4][8] = 150000000;

        droidBotUpgrading[6][3][0] = 0;
        droidBotUpgrading[6][3][1] = 0;
        droidBotUpgrading[6][3][2] = 0;
        droidBotUpgrading[6][3][3] = 0;
        droidBotUpgrading[6][3][4] = 0;
        droidBotUpgrading[6][3][5] = 0;
        droidBotUpgrading[6][3][6] = 9550000000;
        droidBotUpgrading[6][3][7] = 400000000;
        droidBotUpgrading[6][3][8] = 50000000;

        droidBotUpgrading[6][2][0] = 0;
        droidBotUpgrading[6][2][1] = 0;
        droidBotUpgrading[6][2][2] = 0;
        droidBotUpgrading[6][2][3] = 0;
        droidBotUpgrading[6][2][4] = 0;
        droidBotUpgrading[6][2][5] = 0;
        droidBotUpgrading[6][2][6] = 9865000000;
        droidBotUpgrading[6][2][7] = 125000000;
        droidBotUpgrading[6][2][8] = 10000000;

        droidBotUpgrading[6][1][0] = 0;
        droidBotUpgrading[6][1][1] = 0;
        droidBotUpgrading[6][1][2] = 0;
        droidBotUpgrading[6][1][3] = 0;
        droidBotUpgrading[6][1][4] = 0;
        droidBotUpgrading[6][1][5] = 0;
        droidBotUpgrading[6][1][6] = 9967000000;
        droidBotUpgrading[6][1][7] = 30000000;
        droidBotUpgrading[6][1][8] = 3000000;

        droidBotUpgrading[6][0][0] = 0;
        droidBotUpgrading[6][0][1] = 0;
        droidBotUpgrading[6][0][2] = 0;
        droidBotUpgrading[6][0][3] = 0;
        droidBotUpgrading[6][0][4] = 0;
        droidBotUpgrading[6][0][5] = 0;
        droidBotUpgrading[6][0][6] = 9990000000;
        droidBotUpgrading[6][0][7] = 7500000;
        droidBotUpgrading[6][0][8] = 2500000;

        droidBotUpgrading[7][7][0] = 0;
        droidBotUpgrading[7][7][1] = 0;
        droidBotUpgrading[7][7][2] = 0;
        droidBotUpgrading[7][7][3] = 0;
        droidBotUpgrading[7][7][4] = 0;
        droidBotUpgrading[7][7][5] = 0;
        droidBotUpgrading[7][7][6] = 0;
        droidBotUpgrading[7][7][7] = 3000000000;
        droidBotUpgrading[7][7][8] = 7000000000;

        droidBotUpgrading[7][6][0] = 0;
        droidBotUpgrading[7][6][1] = 0;
        droidBotUpgrading[7][6][2] = 0;
        droidBotUpgrading[7][6][3] = 0;
        droidBotUpgrading[7][6][4] = 0;
        droidBotUpgrading[7][6][5] = 0;
        droidBotUpgrading[7][6][6] = 0;
        droidBotUpgrading[7][6][7] = 6700000000;
        droidBotUpgrading[7][6][8] = 3300000000;

        droidBotUpgrading[7][7][0] = 0;
        droidBotUpgrading[7][7][1] = 0;
        droidBotUpgrading[7][7][2] = 0;
        droidBotUpgrading[7][7][3] = 0;
        droidBotUpgrading[7][7][4] = 0;
        droidBotUpgrading[7][7][5] = 0;
        droidBotUpgrading[7][7][6] = 0;
        droidBotUpgrading[7][7][7] = 3000000000;
        droidBotUpgrading[7][7][8] = 7000000000;

        droidBotUpgrading[7][6][0] = 0;
        droidBotUpgrading[7][6][1] = 0;
        droidBotUpgrading[7][6][2] = 0;
        droidBotUpgrading[7][6][3] = 0;
        droidBotUpgrading[7][6][4] = 0;
        droidBotUpgrading[7][6][5] = 0;
        droidBotUpgrading[7][6][6] = 0;
        droidBotUpgrading[7][6][7] = 6700000000;
        droidBotUpgrading[7][6][8] = 3300000000;

        droidBotUpgrading[7][5][0] = 0;
        droidBotUpgrading[7][5][1] = 0;
        droidBotUpgrading[7][5][2] = 0;
        droidBotUpgrading[7][5][3] = 0;
        droidBotUpgrading[7][5][4] = 0;
        droidBotUpgrading[7][5][5] = 0;
        droidBotUpgrading[7][5][6] = 0;
        droidBotUpgrading[7][5][7] = 8800000000;
        droidBotUpgrading[7][5][8] = 1200000000;

        droidBotUpgrading[7][4][0] = 0;
        droidBotUpgrading[7][4][1] = 0;
        droidBotUpgrading[7][4][2] = 0;
        droidBotUpgrading[7][4][3] = 0;
        droidBotUpgrading[7][4][4] = 0;
        droidBotUpgrading[7][4][5] = 0;
        droidBotUpgrading[7][4][6] = 0;
        droidBotUpgrading[7][4][7] = 9600000000;
        droidBotUpgrading[7][4][8] = 400000000;

        droidBotUpgrading[7][3][0] = 0;
        droidBotUpgrading[7][3][1] = 0;
        droidBotUpgrading[7][3][2] = 0;
        droidBotUpgrading[7][3][3] = 0;
        droidBotUpgrading[7][3][4] = 0;
        droidBotUpgrading[7][3][5] = 0;
        droidBotUpgrading[7][3][6] = 0;
        droidBotUpgrading[7][3][7] = 9875000000;
        droidBotUpgrading[7][3][8] = 125000000;

        droidBotUpgrading[7][2][0] = 0;
        droidBotUpgrading[7][2][1] = 0;
        droidBotUpgrading[7][2][2] = 0;
        droidBotUpgrading[7][2][3] = 0;
        droidBotUpgrading[7][2][4] = 0;
        droidBotUpgrading[7][2][5] = 0;
        droidBotUpgrading[7][2][6] = 0;
        droidBotUpgrading[7][2][7] = 9970000000;
        droidBotUpgrading[7][2][8] = 30000000;

        droidBotUpgrading[7][1][0] = 0;
        droidBotUpgrading[7][1][1] = 0;
        droidBotUpgrading[7][1][2] = 0;
        droidBotUpgrading[7][1][3] = 0;
        droidBotUpgrading[7][1][4] = 0;
        droidBotUpgrading[7][1][5] = 0;
        droidBotUpgrading[7][1][6] = 0;
        droidBotUpgrading[7][1][7] = 9992500000;
        droidBotUpgrading[7][1][8] = 7500000;

        droidBotUpgrading[7][0][0] = 0;
        droidBotUpgrading[7][0][1] = 0;
        droidBotUpgrading[7][0][2] = 0;
        droidBotUpgrading[7][0][3] = 0;
        droidBotUpgrading[7][0][4] = 0;
        droidBotUpgrading[7][0][5] = 0;
        droidBotUpgrading[7][0][6] = 0;
        droidBotUpgrading[7][0][7] = 9999000000;
        droidBotUpgrading[7][0][8] = 1000000;
    }

    function getPandoBoxPower() external pure returns(uint256) {
        return 0;
    }

    function getSampleSpace() external view returns(uint256) {
        return SAMPLE_SPACE;
    }

    function getDroidBotPower(uint256 _droidBotLevel, uint256 _rand) external view returns (uint256) {
        uint256 _seed = _rand % 2000;
        uint256 _power = BASE_POWER * (2**(_droidBotLevel)) - BASE_POWER * (2**(_droidBotLevel)) / 10;
        return _power + _power * _seed / BASE_POWER;
    }

    function getPandoBoxCreatingProbability() external view returns(uint256[] memory _pandoBoxCreating) {
        _pandoBoxCreating = new uint256[](N_EGGS);
        for (uint256 i = 0; i < N_EGGS; i++) {
            _pandoBoxCreating[i] = pandoBoxCreating[i];
        }
    }

    function getDroidBotCreatingProbability(uint256 _pandoBoxLevel) external view returns(uint256[] memory _droidBotCreating) {
        _droidBotCreating = new uint256[](N_PETS);
        for (uint256 i = 0; i < N_PETS; i++) {
            _droidBotCreating[i] = droidBotCreating[_pandoBoxLevel][i];
        }
    }

    function getDroidBotUpgradingProbability(uint256 _droidBot0Level, uint256 _droidBot1Level) external view returns(uint256[] memory _droidBotUpgrading) {
        _droidBotUpgrading = new uint256[](N_PETS);
        for (uint256 i = 0; i < N_PETS; i++) {
            _droidBotUpgrading[i] = droidBotUpgrading[_droidBot0Level][_droidBot1Level][i];
        }
    }

    function getJDroidBotCreating(uint256 _pandoBoxLevel) external pure returns (uint256, uint256) {
        return (10000 * (MULTIPLIER ** _pandoBoxLevel) / (PRECISION ** _pandoBoxLevel), 2000000 * (MULTIPLIER ** _pandoBoxLevel) / (PRECISION ** _pandoBoxLevel));
    }

    function getJDroidBotUpgrading(uint256 _droidBot1Level) external pure returns (uint256, uint256) {
        //_droidBot1Level <= _droidBot0Level
        return (10000 * (MULTIPLIER ** _droidBot1Level) / (PRECISION ** _droidBot1Level), 2000000 * (MULTIPLIER ** _droidBot1Level) / (PRECISION ** _droidBot1Level));
    }

    function getNumberOfTicket(uint256 _lv) external returns (uint256) {
        return nTickets[_lv];
    }
}