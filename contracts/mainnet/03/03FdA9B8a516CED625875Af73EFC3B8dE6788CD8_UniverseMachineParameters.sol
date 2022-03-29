// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) Joshua Davis. All rights reserved. */

pragma solidity ^0.8.13;

import "../Kohi/ColorMath.sol";
import "../Kohi/Matrix.sol";

import "./IUniverseMachineParameters.sol";
import "./Parameters.sol";
import "./XorShift.sol";
import "./Star.sol";

/*
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//                                            ,,╓╓╥╥╥╥╥╥╥╥╖╓,                                             //
//                                      ╓╥H╢▒░░▄▄▄▄██████▄▄▄▄░░▒▒H╖,                                      //
//                                 ,╓H▒░░▄████████████████████████▄░░▒H╖                                  //
//                              ╓╥▒░▄██████████████████████████████████▄░▒b,                              //
//                           ╓║▒░▄████████████████████████████████████████▄░▒H╓                           //
//                        ╓╥▒░▄██████████████████████████████████████████████▄░▒╥,                        //
//                      ╓╢░▄████▓███████████████████████████████████████████████▄░▒╖                      //
//                    ╥▒░████▓████████████████████████████████████████████████████▄░▒╖                    //
//                  ╥▒░████▓█████████████████████████████████████████████████████████░▒╖                  //
//                ╥▒░████▓████████████████████████████████████████████████████████▓████░▒╖                //
//              ╓▒░█████▓███████████████████████████████████████████████████████████▓████░▒╖              //
//            ,║▒▄████▓███████████████████░'▀██████████████████░]█████████████████████▓███▄▒▒             //
//           ╓▒░█████▓████████████████████▒  ░███████████████▀   ███████████████████████▓███░▒╖           //
//          ╥▒▄█████▓█████████████████████░    └▀▀▀▀▀▀▀▀██▀░    ;████████████████████████▓███▄▒╥          //
//         ╢▒██████▓██████████████████████▌,                    ░█████████████████████████████▌▒▒         //
//        ▒▒██████▓████████████████████████▌     ,, ,╓, ,,     ¿████████████████████████████████▒▒        //
//       ╢▒██████▓█████████████████████████▌    ▒██▒█░█░██░   .█████████████████████████████▓███▌▒▒       //
//      ]▒▐█████▓███████████████████████████▒       ░▀▀        ██████████████████████████████████░▒┐      //
//      ▒░██████▓███████████████████████████                   ▐█████████████████████████████▓████▒▒      //
//     ]▒▐█████▓███████████████████████████░                   ░█████████████████████████████▓████░▒L     //
//     ▒▒██████▓██████████████████████████▌                     ░████████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████░                      ▐███████████████████████████▓█████▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ░███████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ▒██████████████████████████▓█████▌▒[     //
//     ]▒░████▓███████████████████████████░                      ▐██████████████████████████▓█████░▒      //
//      ▒▒████▓███████████████████████████▌                      ▐█████████████████████████▓█████▌▒▒      //
//      ╙▒░████▓██████████████████████████▌                      ▐███████████████████████████████░▒       //
//       ╙▒░███▓███████████████████████████░                    ░███████████████████████████████░▒`       //
//        ╙▒░███▓██████████████████████████▌                   ,█████████████████████████▓█████░▒╜        //
//         ╙▒░███▓██████████████████████████░                 ,▐████████████████████████▓█████░▒`         //
//          ╙▒░███▓███████████████████████████░             ;▄██████████████████████████████▀░▒           //
//            ╢▒▀███▓█████████████████████████▄█▌▄▄███▄▄▄,░▄▄▄███████████████████████▓█████░▒╜            //
//             ╙▒░▀███▓█████████████████████████████████████████████████████████████▓████▀░▒`             //
//               ╙▒░████▓█████████████████████████████████████████████████████████▓████▀░▒╜               //
//                 ╨▒░███████████████████████████████████████████████████████████▓███▀░▒╜                 //
//                   ╙▒░▀██████████████████████████████████████████████████████▓███▀░▒╜                   //
//                     ╙▒░▀█████████████████████████████████████████████████▓████▀░▒╜                     //
//                       `╨▒░▀████████████████████████████████████████████████▀▒░╨`                       //
//                          ╙▒░░▀██████████████████████████████████████████▀░░▒╜                          //
//                             ╙╣░░▀████████████████████████████████████▀▒░▒╜                             //
//                                ╙╨▒░░▀████████████████████████████▀░░▒╜`                                //
//                                    ╙╨╢▒░░▀▀███████████████▀▀▀▒░▒▒╜`                                    //
//                                         `╙╙╨╨▒▒░░░░░░░░▒▒╨╨╜"`                                         //
//                                                                                                        //
//       ▄▄▄██▀▀▀▒█████    ██████  ██░ ██  █    ██  ▄▄▄      ▓█████▄  ▄▄▄    ██▒   █▓ ██▓  ██████         //
//         ▒██  ▒██▒  ██▒▒██    ▒ ▓██░ ██▒ ██  ▓██▒▒████▄    ▒██▀ ██▌▒████▄ ▓██░   █▒▓██▒▒██    ▒         //
//         ░██  ▒██░  ██▒░ ▓██▄   ▒██▀▀██░▓██  ▒██░▒██  ▀█▄  ░██   █▌▒██  ▀█▄▓██  █▒░▒██▒░ ▓██▄           //
//      ▓██▄██▓ ▒██   ██░  ▒   ██▒░▓█ ░██ ▓▓█  ░██░░██▄▄▄▄██ ░▓█▄   ▌░██▄▄▄▄██▒██ █░░░██░  ▒   ██▒        //
//       ▓███▒  ░ ████▓▒░▒██████▒▒░▓█▒░██▓▒▒█████▓  ▓█   ▓██▒░▒████▓  ▓█   ▓██▒▒▀█░  ░██░▒██████▒▒        //
//       ▒▓▒▒░  ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░▒▓▒ ▒ ▒  ▒▒   ▓▒█░ ▒▒▓  ▒  ▒▒   ▓▒█░░ ▐░  ░▓  ▒ ▒▓▒ ▒ ░        //
//       ▒ ░▒░    ░ ▒ ▒░ ░ ░▒  ░ ░ ▒ ░▒░ ░░░▒░ ░ ░   ▒   ▒▒ ░ ░ ▒  ▒   ▒   ▒▒ ░░ ░░   ▒ ░░ ░▒  ░ ░        //
//       ░ ░ ░  ░ ░ ░ ▒  ░  ░  ░   ░  ░░ ░ ░░░ ░ ░   ░   ▒    ░ ░  ░   ░   ▒     ░░   ▒ ░░  ░  ░          //
//       ░   ░      ░ ░        ░   ░  ░  ░   ░           ░  ░   ░          ░  ░   ░   ░        ░          //
//                                                          ░                  ░                          //
//     ██▓███   ██▀███   ▄▄▄     ▓██   ██▓  ██████ ▄▄▄█████▓ ▄▄▄     ▄▄▄█████▓ ██▓ ▒█████   ███▄    █     //
//    ▓██░  ██▒▓██ ▒ ██▒▒████▄    ▒██  ██▒▒██    ▒ ▓  ██▒ ▓▒▒████▄   ▓  ██▒ ▓▒▓██▒▒██▒  ██▒ ██ ▀█   █     //
//    ▓██░ ██▓▒▓██ ░▄█ ▒▒██  ▀█▄   ▒██ ██░░ ▓██▄   ▒ ▓██░ ▒░▒██  ▀█▄ ▒ ▓██░ ▒░▒██▒▒██░  ██▒▓██  ▀█ ██▒    //
//    ▒██▄█▓▒ ▒▒██▀▀█▄  ░██▄▄▄▄██  ░ ▐██▓░  ▒   ██▒░ ▓██▓ ░ ░██▄▄▄▄██░ ▓██▓ ░ ░██░▒██   ██░▓██▒  ▐▌██▒    //
//    ▒██▒ ░  ░░██▓ ▒██▒ ▓█   ▓██▒ ░ ██▒▓░▒██████▒▒  ▒██▒ ░  ▓█   ▓██▒ ▒██▒ ░ ░██░░ ████▓▒░▒██░   ▓██░    //
//    ▒▓▒░ ░  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░  ██▒▒▒ ▒ ▒▓▒ ▒ ░  ▒ ░░    ▒▒   ▓▒█░ ▒ ░░   ░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒     //
//    ░▒ ░       ░▒ ░ ▒░  ▒   ▒▒ ░▓██ ░▒░ ░ ░▒  ░ ░    ░      ▒   ▒▒ ░   ░     ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░    //
//    ░░         ░░   ░   ░   ▒   ▒ ▒ ░░  ░  ░  ░    ░        ░   ▒    ░       ▒ ░░ ░ ░ ▒     ░   ░ ░     //
//                ░           ░  ░░ ░           ░                 ░  ░         ░      ░ ░           ░     //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

contract UniverseMachineParameters is IUniverseMachineParameters {

    int32 public constant StageW = 1505;
    int32 public constant StageH = 2228;
    
    uint8 public constant NumCols = 4;
    uint8 public constant NumRows = 7;
    uint16 public constant GridSize = NumCols * NumRows;

    uint8 public constant NumTextures = 8;
    uint16 public constant NumColors = 750;

    uint8 public constant ColorSpread = 150;    
    int16 public constant GridMaxMargin = -335;
    uint8 public constant StarMax = 150;

    uint32[5][10] clrs;
    uint8[4][56] masterSet;

    constructor() {
        clrs = [
            [0xFFA59081, 0xFFF26B8F, 0xFF3C7373, 0xFF7CC4B0, 0xFFF2F2F5],
            [0xFFF2F2F5, 0xFF0C2F40, 0xFF335E71, 0xFF71AABF, 0xFFA59081],
            [0xFFF35453, 0xFF007074, 0xFFD2D8BE, 0xFFEFCF89, 0xFFF49831],
            [0xFF2B5D75, 0xFFF35453, 0xFFF2F2F5, 0xFF5E382C, 0xFFCB7570],
            [0xFFF9C169, 0xFF56C4B5, 0xFF214B73, 0xFF16163F, 0xFF9A5E1F],
            [0xFFFBE5B6, 0xFFF9C169, 0xFF9C7447, 0xFF775D40, 0xFF4A5343],
            [0xFFE2EBE1, 0xFFE7D9AD, 0xFF63AA62, 0xFF0C3A3C, 0xFF87C4C2],
            [0xFFE8E8E8, 0xFFB9B9B9, 0xFF666666, 0xFF262626, 0xFF65D8E4],
            [0xFF466E8B, 0xFFFEF5E7, 0xFFF1795E, 0xFF666073, 0xFF192348],
            [0xFFFFFFFF, 0xFF8C8C8C, 0xFF404040, 0xFF8C8C8C, 0xFFF2F2F2]
        ];

        masterSet = [
            [1, 5, 4, 2],
            [6, 5, 4, 3],
            [4, 1, 4, 2],
            [4, 1, 0, 2],
            [4, 1, 2, 2],
            [4, 5, 4, 1],
            [3, 5, 3, 0],
            [3, 0, 3, 0],
            [3, 5, 2, 0],
            [3, 2, 2, 0],
            [3, 1, 2, 0],
            [3, 0, 2, 0],
            [2, 4, 4, 1],
            [2, 4, 2, 1],
            [2, 3, 4, 1],
            [2, 3, 0, 1],
            [2, 1, 4, 1],
            [2, 1, 0, 1],
            [2, 1, 4, 2],
            [2, 1, 0, 2],
            [2, 1, 2, 2],
            [2, 0, 4, 1],
            [2, 5, 4, 1],
            [2, 5, 0, 1],
            [2, 5, 4, 2],
            [2, 5, 0, 2],
            [2, 5, 2, 2],
            [1, 4, 0, 1],
            [1, 3, 4, 1],
            [1, 3, 0, 1],
            [1, 3, 2, 1],
            [1, 1, 4, 1],
            [1, 1, 4, 2],
            [1, 1, 0, 2],
            [1, 1, 2, 2],
            [1, 0, 4, 0],
            [1, 0, 4, 1],
            [1, 5, 2, 1],
            [1, 5, 4, 2],
            [1, 5, 0, 2],
            [1, 5, 2, 2],
            [0, 1, 2, 2],
            [0, 5, 4, 2],
            [0, 5, 2, 2],
            [6, 4, 2, 1],
            [6, 3, 4, 1],
            [6, 3, 2, 1],
            [6, 1, 4, 2],
            [6, 1, 0, 2],
            [6, 1, 2, 2],
            [6, 0, 4, 1],
            [6, 0, 0, 1],
            [6, 0, 2, 1],
            [6, 5, 4, 2],
            [6, 5, 0, 2],
            [6, 5, 2, 2]
        ];
    }

    function getUniverse(uint8 index)
        external
        override
        view
        returns (uint8[4] memory universe)
    {
        return masterSet[uint32(index)];
    }

    function getParameters(uint256 tokenId, int32 seed)
        external
        override
        view
        returns (Parameters memory parameters) 
    {
        {
            (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                seed,
                1 * Fix64V1.ONE,
                55 * Fix64V1.ONE
            );
            parameters.whichMasterSet = tokenId == 0 ? 0 : uint32(value);
            seed = modifiedSeed;
        }

        {
            (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                seed,
                0 * Fix64V1.ONE,
                9 * Fix64V1.ONE
            );
            parameters.whichColor = value;
            seed = modifiedSeed;
        }

        {
            (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                seed,
                0 * Fix64V1.ONE,
                int16(GridSize - 1) * Fix64V1.ONE
            );
            parameters.endIdx = value;
            seed = modifiedSeed;
        }

        buildColors(parameters);

        {
            (Universe memory universe, int32 modifiedSeed) = buildUniverse(parameters, seed);
            seed = modifiedSeed;

            buildGrid(parameters);

            buildPaths(parameters, universe);

            buildStars(parameters, seed);
        }        
    }

    function buildColors(Parameters memory parameters) private view {

        uint32[5] memory whichClr = clrs[uint32(parameters.whichColor)];
        
        int64 inter = Fix64V1.div(Fix64V1.ONE, int64(uint64(uint8(ColorSpread))) * Fix64V1.ONE);

        parameters.myColorsR = new uint8[](NumColors);
        parameters.myColorsG = new uint8[](NumColors);
        parameters.myColorsB = new uint8[](NumColors);        

        uint32 index = 0;
        for (uint32 i = 0; i < whichClr.length; i++)
        {
            uint32 j = i == whichClr.length - 1 ? 0 : i + 1;

            for (uint32 x = 0; x < ColorSpread; x++)
            {
                int64 m = int64(uint64(uint8(x))) * Fix64V1.ONE;
                uint32 c = ColorMath.lerp(whichClr[i], whichClr[j], Fix64V1.mul(inter, m));
                
                parameters.myColorsR[index] = uint8(c >> 16);
                parameters.myColorsG[index] = uint8(c >>  8);
                parameters.myColorsB[index] = uint8(c >>  0);

                index++;
            }
        }
        parameters.cLen = int16(NumColors);
    }

    struct Universe {
        int32[] whichBezierPattern;
        int32[] whichGridPos;
        int32[] whichBezierH1a;
        int32[] whichBezierH1b;
        int32[] whichBezierH2a;
        int32[] whichBezierH2b;
    }

    function buildUniverse(Parameters memory parameters, int32 seed)
        private
        view
        returns (Universe memory universe, int32)
    {
        parameters.whichTex = new int32[](GridSize);
        parameters.whichColorFlow = new int32[](GridSize);
        parameters.whichRot = new int32[](GridSize);
        parameters.whichRotDir = new int32[](GridSize);

        universe.whichBezierPattern = new int32[](GridSize);
        universe.whichGridPos = new int32[](GridSize);
        universe.whichBezierH1a = new int32[](GridSize);
        universe.whichBezierH1b = new int32[](GridSize);
        universe.whichBezierH2a = new int32[](GridSize);
        universe.whichBezierH2b = new int32[](GridSize);        

        for (uint16 i = 0; i < GridSize; i++) {
            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][0];

                if (_case == 0) {
                    universe.whichBezierPattern[i] = 0;
                } else if (_case == 1) {
                    universe.whichBezierPattern[i] = 1;
                } else if (_case == 2) {
                    universe.whichBezierPattern[i] = 2;
                } else if (_case == 3) {
                    universe.whichBezierPattern[i] = 3;
                } else if (_case == 4) {
                    universe.whichBezierPattern[i] = 4;
                } else if (_case == 5) {
                    universe.whichBezierPattern[i] = 5;
                } else if (_case == 6) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        int8(5) * Fix64V1.ONE
                    );
                    universe.whichBezierPattern[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][1];

                if (_case == 0) {
                    parameters.whichTex[i] = 0;
                } else if (_case == 1) {
                    parameters.whichTex[i] = 1;
                } else if (_case == 2) {
                    parameters.whichTex[i] = 2;
                } else if (_case == 3) {
                    parameters.whichTex[i] = 3;
                } else if (_case == 4) {
                    parameters.whichTex[i] = 4;
                } else if (_case == 5) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        (int8(NumTextures) - 2) * Fix64V1.ONE
                    );
                    parameters.whichTex[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][2];

                if (_case == 0) {
                    parameters.whichColorFlow[i] = 0;
                } else if (_case == 1) {
                    parameters.whichColorFlow[i] = 1;
                } else if (_case == 2) {
                    parameters.whichColorFlow[i] = 2;
                } else if (_case == 3) {
                    parameters.whichColorFlow[i] = 3;
                } else if (_case == 4) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        3 * Fix64V1.ONE
                    );
                    parameters.whichColorFlow[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                uint256 _case = masterSet[uint32(parameters.whichMasterSet)][3];

                if (_case == 0) {
                    parameters.whichRot[i] = 0;
                } else if (_case == 1) {
                    parameters.whichRot[i] = 1;
                } else if (_case == 2) {
                    parameters.whichRot[i] = 2;
                } else if (_case == 3) {
                    parameters.whichRot[i] = 3;
                } else if (_case == 4) {
                    (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                        seed,
                        0,
                        2 * Fix64V1.ONE
                    );
                    parameters.whichRot[i] = value;
                    seed = modifiedSeed;
                }
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    0 * Fix64V1.ONE,
                    1 * Fix64V1.ONE
                );
                parameters.whichRotDir[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    0 * Fix64V1.ONE,
                    (int16(GridSize) - 1) * Fix64V1.ONE
                );
                universe.whichGridPos[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)),
                    Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)
                );
                universe.whichBezierH1a[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(StageH * Fix64V1.ONE),
                    StageH * Fix64V1.ONE
                );
                universe.whichBezierH1b[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)),
                    Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)
                );
                universe.whichBezierH2a[i] = value;
                seed = modifiedSeed;
            }

            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    -(StageH * Fix64V1.ONE),
                    StageH * Fix64V1.ONE
                );
                universe.whichBezierH2b[i] = value;
                seed = modifiedSeed;
            }
        }

        return (universe, seed);
    }

    function buildGrid(Parameters memory parameters) private pure {
        parameters.gridPoints = new Vector2[](GridSize);

        int64 ratio = Fix64V1.div(
            int8(NumCols) * Fix64V1.ONE,
            int8(NumRows) * Fix64V1.ONE
        );
        int64 margin = Fix64V1.min(
            GridMaxMargin * Fix64V1.ONE,
            Fix64V1.div(StageW * Fix64V1.ONE, Fix64V1.TWO)
        );

        int64 width = Fix64V1.sub(
            StageW * Fix64V1.ONE,
            Fix64V1.mul(margin, Fix64V1.TWO)
        );
        int64 height = Fix64V1.div(width, ratio);

        if (
            height >
            Fix64V1.sub(StageH * Fix64V1.ONE, Fix64V1.mul(margin, Fix64V1.TWO))
        ) {
            height = Fix64V1.sub(
                StageH * Fix64V1.ONE,
                Fix64V1.mul(margin, Fix64V1.TWO)
            );
            width = Fix64V1.mul(height, ratio);
        }

        for (uint16 i = 0; i < GridSize; i++) {
            uint16 col = i % NumCols;
            int64 row = Fix64V1.floor(
                Fix64V1.div(int16(i) * Fix64V1.ONE, int8(NumCols) * Fix64V1.ONE)
            );
            int64 x = Fix64V1.add(
                Fix64V1.div(-width, Fix64V1.TWO),
                Fix64V1.mul(
                    int16(col) * Fix64V1.ONE,
                    Fix64V1.div(
                        width,
                        Fix64V1.sub(int8(NumCols) * Fix64V1.ONE, Fix64V1.ONE)
                    )
                )
            );
            int64 y = Fix64V1.add(
                Fix64V1.div(-height, Fix64V1.TWO),
                Fix64V1.mul(
                    row,
                    Fix64V1.div(
                        height,
                        Fix64V1.sub(int8(NumRows) * Fix64V1.ONE, Fix64V1.ONE)
                    )
                )
            );

            parameters.gridPoints[i] = Vector2(x, y);
        }
    }

    function buildPaths(Parameters memory parameters, Universe memory universe) private pure {
        
        parameters.paths = new Bezier[](GridSize);
        parameters.numPaths = 0;

        for (uint256 i = 0; i < GridSize; i++) {
            Vector2 memory p1 = Vector2(
                parameters.gridPoints[i].x,
                parameters.gridPoints[i].y
            );
            Vector2 memory p2 = p1;
            Vector2 memory p3 = Vector2(
                parameters.gridPoints[uint32(parameters.endIdx)].x,
                parameters.gridPoints[uint32(parameters.endIdx)].y
            );
            Vector2 memory p4 = p3;

            uint32 _case = uint32(universe.whichBezierPattern[i]);

            if (_case == 1) {
                p3 = p4 = Vector2(
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].x,
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].y
                );
            } else if (_case == 2) {
                p3 = Vector2(
                    universe.whichBezierH1a[i] * Fix64V1.ONE,
                    universe.whichBezierH1b[i] * Fix64V1.ONE
                );
                p4 = Vector2(
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].x,
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].y
                );
            } else if (_case == 3) {
                p3 = p4 = Vector2(
                    parameters.gridPoints[i].x,
                    parameters.gridPoints[i].y
                );
            } else if (_case == 4) {
                p2 = Vector2(
                    universe.whichBezierH1a[i] * Fix64V1.ONE,
                    universe.whichBezierH1b[i] * Fix64V1.ONE
                );
                p3 = Vector2(
                    universe.whichBezierH2a[i] * Fix64V1.ONE,
                    universe.whichBezierH2b[i] * Fix64V1.ONE
                );
                p4 = Vector2(
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].x,
                    parameters.gridPoints[uint32(universe.whichGridPos[i])].y
                );
            } else if (_case == 5) {
                p2 = Vector2(
                    universe.whichBezierH1a[i] * Fix64V1.ONE,
                    universe.whichBezierH1b[i] * Fix64V1.ONE
                );
                p3 = Vector2(
                    universe.whichBezierH2a[i] * Fix64V1.ONE,
                    universe.whichBezierH2b[i] * Fix64V1.ONE
                );
            }

            parameters.paths[parameters.numPaths++] = BezierMethods.create(
                p1,
                p2,
                p3,
                p4
            );
        }
    }

    function buildStars(Parameters memory parameters, int32 seed)
        private
        pure
        returns (int32)
    {
        parameters.starPositions = new Star[](StarMax);

        for (uint8 i = 0; i < StarMax; ++i) {
            int32 x;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    Fix64V1.mul(
                        parameters.gridPoints[0].x,
                        5368709120 /* 1.25 */
                    ),
                    Fix64V1.mul(
                        parameters.gridPoints[GridSize - 1].x,
                        5368709120 /* 1.25 */
                    )
                );
                x = value;
                seed = modifiedSeed;
            }

            int32 y;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    Fix64V1.mul(
                        parameters.gridPoints[0].y,
                        4724464128 /* 1.1 */
                    ),
                    Fix64V1.mul(
                        parameters.gridPoints[GridSize - 1].y,
                        4724464128 /* 1.1 */
                    )
                );
                y = value;
                seed = modifiedSeed;
            }

            int32 sTemp;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    1 * Fix64V1.ONE,
                    3 * Fix64V1.ONE
                );
                sTemp = value;
                seed = modifiedSeed;
            }

            int32 c;
            {
                (int32 value, int32 modifiedSeed) = XorShift.nextInt(
                    seed,
                    0,
                    (parameters.cLen - 1) * Fix64V1.ONE
                );
                c = value;
                seed = modifiedSeed;
            }

            parameters.starPositions[i] = Star(
                x,
                y,
                int16((sTemp == 1) ? 1000 : (sTemp == 2) ? 2000 : 3000),
                c
            );
        }

        return seed;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IUniverseMachineParameters).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";

library ColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) internal pure returns (uint32) {
        uint32 c;
        c |= uint32(a) << 24;
        c |= uint32(r) << 16;
        c |= uint32(g) << 8;
        c |= uint32(b) << 0;
        return c & 0xffffffff;
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) internal pure returns (uint32) {
        int64 bk = Fix64V1.sub(Fix64V1.ONE, k);

        int64 a = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 24))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 24))) * Fix64V1.ONE, k)
        );
        int64 r = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 16))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 16))) * Fix64V1.ONE, k)
        );
        int64 g = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 8))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 8))) * Fix64V1.ONE, k)
        );
        int64 b = Fix64V1.add(
            Fix64V1.mul(int64(uint64((uint8)(s >> 0))) * Fix64V1.ONE, bk),
            Fix64V1.mul(int64(uint64((uint8)(t >> 0))) * Fix64V1.ONE, k)
        );

        int32 ra = (int32(a / Fix64V1.ONE) << 24);
        int32 rr = (int32(r / Fix64V1.ONE) << 16);
        int32 rg = (int32(g / Fix64V1.ONE) << 8);
        int32 rb = (int32(b / Fix64V1.ONE));

        int32 x = ra | rr | rg | rb;
        return uint32(x) & 0xffffffff;
    }

    function tint(uint32 targetColor, uint32 tintColor)
        internal
        pure
        returns (uint32 newColor)
    {
        uint8 a = (uint8)(targetColor >> 24);
        uint8 r = (uint8)(targetColor >> 16);
        uint8 g = (uint8)(targetColor >> 8);
        uint8 b = (uint8)(targetColor >> 0);

        if (a != 0 && r == 0 && g == 0 && b == 0) {
            return targetColor;
        }

        uint8 tr = (uint8)(tintColor >> 16);
        uint8 tg = (uint8)(tintColor >> 8);
        uint8 tb = (uint8)(tintColor >> 0);

        uint32 tinted = toColor(a, tr, tg, tb);
        return tinted;
    }
}

contract TestColorMath {
    function toColor(
        uint8 a,
        uint8 r,
        uint8 g,
        uint8 b
    ) external pure returns (uint32) {
        return ColorMath.toColor(a, r, g, b);
    }

    function lerp(
        uint32 s,
        uint32 t,
        int64 k
    ) external pure returns (uint32) {
        return ColorMath.lerp(s, t, k);
    }

    function tint(uint32 targetColor, uint32 tintColor)
        external
        pure
        returns (uint32 newColor)
    {
        return ColorMath.tint(targetColor, tintColor);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./Trig256.sol";
import "./MathUtils.sol";
import "./Vector2.sol";

struct Matrix {
    int64 sx;
    int64 shy;
    int64 shx;
    int64 sy;
    int64 tx;
    int64 ty;
}

library MatrixMethods {
    function newIdentity() internal pure returns (Matrix memory value) {
        value.sx = Fix64V1.ONE;
        value.shy = 0;
        value.shx = 0;
        value.sy = Fix64V1.ONE;
        value.tx = 0;
        value.ty = 0;
    }

    function newRotation(int64 radians) internal pure returns (Matrix memory) {
        int64 v0 = Trig256.cos(radians);
        int64 v1 = Trig256.sin(radians);
        int64 v2 = -Trig256.sin(radians);
        int64 v3 = Trig256.cos(radians);

        return Matrix(v0, v1, v2, v3, 0, 0);
    }

    function newScale(int64 scale) internal pure returns (Matrix memory) {
        return Matrix(scale, 0, 0, scale, 0, 0);
    }

    function newScale(int64 scaleX, int64 scaleY)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(scaleX, 0, 0, scaleY, 0, 0);
    }

    function newTranslation(int64 x, int64 y)
        internal
        pure
        returns (Matrix memory)
    {
        return Matrix(Fix64V1.ONE, 0, 0, Fix64V1.ONE, x, y);
    }

    function transform(
        Matrix memory self,
        int64 x,
        int64 y
    ) internal pure returns (int64, int64) {
        int64 tmp = x;
        x = Fix64V1.add(
            Fix64V1.mul(tmp, self.sx),
            Fix64V1.add(Fix64V1.mul(y, self.shx), self.tx)
        );
        y = Fix64V1.add(
            Fix64V1.mul(tmp, self.shy),
            Fix64V1.add(Fix64V1.mul(y, self.sy), self.ty)
        );
        return (x, y);
    }

    function transform(Matrix memory self, Vector2 memory v)
        internal
        pure
        returns (Vector2 memory result)
    {
        result = v;
        transform(self, result.x, result.y);
        return result;
    }

    function invert(Matrix memory self) internal pure {
        int64 d = Fix64V1.div(
            Fix64V1.ONE,
            Fix64V1.sub(
                Fix64V1.mul(self.sx, self.sy),
                Fix64V1.mul(self.shy, self.shx)
            )
        );

        self.sy = Fix64V1.mul(self.sx, d);
        self.shy = Fix64V1.mul(-self.shy, d);
        self.shx = Fix64V1.mul(-self.shx, d);

        self.ty = Fix64V1.sub(
            Fix64V1.mul(-self.tx, self.shy),
            Fix64V1.mul(self.ty, self.sy)
        );
        self.sx = Fix64V1.mul(self.sy, d);
        self.tx = Fix64V1.sub(
            Fix64V1.mul(-self.tx, Fix64V1.mul(self.sy, d)),
            Fix64V1.mul(self.ty, self.shx)
        );
    }

    function isIdentity(Matrix memory self) internal pure returns (bool) {
        return
            isEqual(self.sx, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.shy, 0, MathUtils.Epsilon) &&
            isEqual(self.shx, 0, MathUtils.Epsilon) &&
            isEqual(self.sy, Fix64V1.ONE, MathUtils.Epsilon) &&
            isEqual(self.tx, 0, MathUtils.Epsilon) &&
            isEqual(self.ty, 0, MathUtils.Epsilon);
    }

    function isEqual(
        int64 v1,
        int64 v2,
        int64 epsilon
    ) internal pure returns (bool) {
        return Fix64V1.abs(Fix64V1.sub(v1, v2)) <= epsilon;
    }

    function mul(Matrix memory self, Matrix memory other)
        internal
        pure
        returns (Matrix memory)
    {
        int64 t0 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.sx),
            Fix64V1.mul(self.shy, other.shx)
        );
        int64 t1 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.sx),
            Fix64V1.mul(self.sy, other.shx)
        );
        int64 t2 = Fix64V1.add(
            Fix64V1.mul(self.tx, other.sx),
            Fix64V1.add(Fix64V1.mul(self.ty, other.shx), other.tx)
        );
        int64 t3 = Fix64V1.add(
            Fix64V1.mul(self.sx, other.shy),
            Fix64V1.mul(self.shy, other.sy)
        );
        int64 t4 = Fix64V1.add(
            Fix64V1.mul(self.shx, other.shy),
            Fix64V1.mul(self.sy, other.sy)
        );
        int64 t5 = Fix64V1.add(
            Fix64V1.mul(self.tx, other.shy),
            Fix64V1.add(Fix64V1.mul(self.ty, other.sy), other.ty)
        );

        self.shy = t3;
        self.sy = t4;
        self.ty = t5;
        self.sx = t0;
        self.shx = t1;
        self.tx = t2;

        return self;
    }
}

contract TestMatrixMethods {
    function mul(Matrix memory self, Matrix memory other)
        external
        pure
        returns (Matrix memory)
    {
        return MatrixMethods.mul(self, other);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./Parameters.sol";

interface IUniverseMachineParameters is IERC165 {

    function getUniverse(uint8 index) external view returns (uint8[4] memory universe);

    function getParameters(uint256 tokenId, int32 seed)
        external
        view
        returns (Parameters memory parameters);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Bezier.sol";
import "./Star.sol";

struct Parameters {

    uint32 whichMasterSet;
    int32 whichColor;
    int32 endIdx;
    int32 cLen;

    uint8[] myColorsR;
    uint8[] myColorsG;
    uint8[] myColorsB;

    int32[] whichTex;
    int32[] whichColorFlow;
    int32[] whichRot;
    int32[] whichRotDir;       
    
    Vector2[] gridPoints;

    Bezier[] paths;
    uint32 numPaths;

    Star[] starPositions;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/Fix64V1.sol";

library XorShift {
    function nextFloat(int32 seed)
        internal
        pure
        returns (int64 value, int32 modifiedSeed)
    {
        seed ^= seed << 13;
        seed ^= seed >> 17;
        seed ^= seed << 5;

        int256 t0;
        if (seed < 0) {
            t0 = ~seed + 1;
        } else {
            t0 = seed;
        }

        value = Fix64V1.div(int64((t0 % 1000) * Fix64V1.ONE), 1000 * Fix64V1.ONE);  
        return (value, seed);
    }

    function nextFloatRange(int32 seed, int64 a, int64 b) internal pure returns (int64 value, int32 modifiedSeed)
    {
        (int64 nextValue, int32 nextSeed) = nextFloat(seed);
        modifiedSeed = nextSeed;        
        value = Fix64V1.add(a, Fix64V1.mul(Fix64V1.sub(b, a), nextValue));
    }

    function nextInt(int32 seed, int64 a, int64 b) internal pure returns (int32 value, int32 modifiedSeed)
    {
        (int64 nextValue, int32 nextSeed) = nextFloatRange(seed, a, Fix64V1.add(b, Fix64V1.ONE));
        modifiedSeed = nextSeed;   

        int64 floor = Fix64V1.floor(nextValue);
        value = int32(floor / Fix64V1.ONE);
    }    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Star {
    int32 x;
    int32 y;
    int32 s;
    int32 c;
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

/*
    Provides mathematical operations and representation in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath
    
    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Fix64V1 {
    int64 public constant FRACTIONAL_PLACES = 32;
    int64 public constant ONE = 4294967296; // 1 << FRACTIONAL_PLACES
    int64 public constant TWO = ONE * 2;
    int64 public constant THREE = ONE * 3;
    int64 public constant PI = 0x3243F6A88;
    int64 public constant TWO_PI = 0x6487ED511;
    int64 public constant MAX_VALUE = type(int64).max;
    int64 public constant MIN_VALUE = type(int64).min;
    int64 public constant PI_OVER_2 = 0x1921FB544;

    function countLeadingZeros(uint64 x) internal pure returns (int64) {
        int64 result = 0;
        while ((x & 0xF000000000000000) == 0) {
            result += 4;
            x <<= 4;
        }
        while ((x & 0x8000000000000000) == 0) {
            result += 1;
            x <<= 1;
        }
        return result;
    }

    function div(int64 x, int64 y) internal pure returns (int64) {
        if (y == 0) {
            revert("attempted to divide by zero");
        }

        int64 xl = x;
        int64 yl = y;

        uint64 remainder = uint64(xl >= 0 ? xl : -xl);
        uint64 divider = uint64((yl >= 0 ? yl : -yl));
        uint64 quotient = 0;
        int64 bitPos = 64 / 2 + 1;

        while ((divider & 0xF) == 0 && bitPos >= 4) {
            divider >>= 4;
            bitPos -= 4;
        }

        while (remainder != 0 && bitPos >= 0) {
            int64 shift = countLeadingZeros(remainder);
            if (shift > bitPos) {
                shift = bitPos;
            }
            remainder <<= uint64(shift);
            bitPos -= shift;

            uint64 d = remainder / divider;
            remainder = remainder % divider;
            quotient += d << uint64(bitPos);

            if ((d & ~(uint64(0xFFFFFFFFFFFFFFFF) >> uint64(bitPos)) != 0)) {
                return ((xl ^ yl) & MIN_VALUE) == 0 ? MAX_VALUE : MIN_VALUE;
            }

            remainder <<= 1;
            --bitPos;
        }

        ++quotient;
        int64 result = int64(quotient >> 1);
        if (((xl ^ yl) & MIN_VALUE) != 0) {
            result = -result;
        }

        return int64(result);
    }

    function mul(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;

        uint64 xlo = (uint64)((xl & (int64)(0x00000000FFFFFFFF)));
        int64 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint64 ylo = (uint64)(yl & (int64)(0x00000000FFFFFFFF));
        int64 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint64 lolo = xlo * ylo;
        int64 lohi = int64(xlo) * yhi;
        int64 hilo = xhi * int64(ylo);
        int64 hihi = xhi * yhi;

        uint64 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int64 midResult1 = lohi;
        int64 midResult2 = hilo;
        int64 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int64 sum = int64(loResult) + midResult1 + midResult2 + hiResult;

        return int64(sum);
    }

    function mul_256(int256 x, int256 y) internal pure returns (int256) {
        int256 xl = x;
        int256 yl = y;

        uint256 xlo = uint256((xl & int256(0x00000000FFFFFFFF)));
        int256 xhi = xl >> 32; // FRACTIONAL_PLACES
        uint256 ylo = uint256(yl & int256(0x00000000FFFFFFFF));
        int256 yhi = yl >> 32; // FRACTIONAL_PLACES

        uint256 lolo = xlo * ylo;
        int256 lohi = int256(xlo) * yhi;
        int256 hilo = xhi * int256(ylo);
        int256 hihi = xhi * yhi;

        uint256 loResult = lolo >> 32; // FRACTIONAL_PLACES
        int256 midResult1 = lohi;
        int256 midResult2 = hilo;
        int256 hiResult = hihi << 32; // FRACTIONAL_PLACES

        int256 sum = int256(loResult) + midResult1 + midResult2 + hiResult;

        return sum;
    }

    function floor(int256 x) internal pure returns (int64) {
        return int64(x & 0xFFFFFFFF00000000);
    }

    function round(int256 x) internal pure returns (int256) {
        int256 fractionalPart = x & 0x00000000FFFFFFFF;
        int256 integralPart = floor(x);
        if (fractionalPart < 0x80000000) return integralPart;
        if (fractionalPart > 0x80000000) return integralPart + ONE;
        if ((integralPart & ONE) == 0) return integralPart;
        return integralPart + ONE;
    }

    function sub(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;
        int64 diff = xl - yl;
        if (((xl ^ yl) & (xl ^ diff) & MIN_VALUE) != 0)
            diff = xl < 0 ? MIN_VALUE : MAX_VALUE;
        return diff;
    }

    function add(int64 x, int64 y) internal pure returns (int64) {
        int64 xl = x;
        int64 yl = y;
        int64 sum = xl + yl;
        if ((~(xl ^ yl) & (xl ^ sum) & MIN_VALUE) != 0)
            sum = xl > 0 ? MAX_VALUE : MIN_VALUE;
        return sum;
    }

    function sign(int64 x) internal pure returns (int8) {
        return x == int8(0) ? int8(0) : x > int8(0) ? int8(1) : int8(-1);
    }

    function abs(int64 x) internal pure returns (int64) {
        int64 mask = x >> 63;
        return (x + mask) ^ mask;
    }

    function max(int64 a, int64 b) internal pure returns (int64) {
        return a >= b ? a : b;
    }

    function min(int64 a, int64 b) internal pure returns (int64) {
        return a < b ? a : b;
    }

    function map(
        int64 n,
        int64 start1,
        int64 stop1,
        int64 start2,
        int64 stop2
    ) internal pure returns (int64) {
        int64 value = mul(
            div(sub(n, start1), sub(stop1, start1)),
            add(sub(stop2, start2), start2)
        );

        return
            start2 < stop2
                ? constrain(value, start2, stop2)
                : constrain(value, stop2, start2);
    }

    function constrain(
        int64 n,
        int64 low,
        int64 high
    ) internal pure returns (int64) {
        return max(min(n, high), low);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./SinLut256.sol";

/*
    Provides trigonometric functions in Q31.Q32 format.

    exp: Adapted from Petteri Aimonen's libfixmath

    See: https://github.com/PetteriAimonen/libfixmath
         https://github.com/PetteriAimonen/libfixmath/blob/master/LICENSE

    other functions: Adapted from André Slupik's FixedMath.NET
                     https://github.com/asik/FixedMath.Net/blob/master/LICENSE.txt
         
    THIRD PARTY NOTICES:
    ====================

    libfixmath is Copyright (c) 2011-2021 Flatmush <[email protected]>,
    Petteri Aimonen <[email protected]>, & libfixmath AUTHORS

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Copyright 2012 André Slupik

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    This project uses code from the log2fix library, which is under the following license:           
    The MIT License (MIT)

    Copyright (c) 2015 Dan Moulding
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

library Trig256 {
    int64 private constant LARGE_PI = 7244019458077122842;
    int64 private constant LN2 = 0xB17217F7;
    int64 private constant LN_MAX = 0x157CD0E702;
    int64 private constant LN_MIN = -0x162E42FEFA;
    int64 private constant E = -0x2B7E15162;

    function sin(int64 x) internal pure returns (int64) {
        (int64 clamped, bool flipHorizontal, bool flipVertical) = clamp(x);

        int64 lutInterval = Fix64V1.div(
            ((256 - 1) * Fix64V1.ONE),
            Fix64V1.PI_OVER_2
        );
        int256 rawIndex = Fix64V1.mul_256(clamped, lutInterval);
        int64 roundedIndex = int64(Fix64V1.round(rawIndex));
        int64 indexError = Fix64V1.sub(int64(rawIndex), roundedIndex);

        roundedIndex = roundedIndex >> 32; /* FRACTIONAL_PLACES */

        int64 nearestValueIndex = flipHorizontal
            ? (256 - 1) - roundedIndex
            : roundedIndex;

        int64 nearestValue = SinLut256.sinlut(nearestValueIndex);

        int64 secondNearestValue = SinLut256.sinlut(
            flipHorizontal
                ? (256 - 1) - roundedIndex - Fix64V1.sign(indexError)
                : roundedIndex + Fix64V1.sign(indexError)
        );

        int64 delta = Fix64V1.mul(
            indexError,
            Fix64V1.abs(Fix64V1.sub(nearestValue, secondNearestValue))
        );
        int64 interpolatedValue = nearestValue +
            (flipHorizontal ? -delta : delta);
        int64 finalValue = flipVertical
            ? -interpolatedValue
            : interpolatedValue;

        return finalValue;
    }

    function cos(int64 x) internal pure returns (int64) {
        int64 xl = x;
        int64 angle;
        if (xl > 0) {
            angle = Fix64V1.add(
                xl,
                Fix64V1.sub(0 - Fix64V1.PI, Fix64V1.PI_OVER_2)
            );
        } else {
            angle = Fix64V1.add(xl, Fix64V1.PI_OVER_2);
        }
        return sin(angle);
    }

    function sqrt(int64 x) internal pure returns (int64) {
        int64 xl = x;
        if (xl < 0) revert("negative value passed to sqrt");

        uint64 num = uint64(xl);
        uint64 result = uint64(0);
        uint64 bit = uint64(1) << (64 - 2);

        while (bit > num) bit >>= 2;
        for (uint8 i = 0; i < 2; ++i) {
            while (bit != 0) {
                if (num >= result + bit) {
                    num -= result + bit;
                    result = (result >> 1) + bit;
                } else {
                    result = result >> 1;
                }

                bit >>= 2;
            }

            if (i == 0) {
                if (num > (uint64(1) << (64 / 2)) - 1) {
                    num -= result;
                    num = (num << (64 / 2)) - uint64(0x80000000);
                    result = (result << (64 / 2)) + uint64(0x80000000);
                } else {
                    num <<= 64 / 2;
                    result <<= 64 / 2;
                }

                bit = uint64(1) << (64 / 2 - 2);
            }
        }

        if (num > result) ++result;
        return int64(result);
    }

    function log2_256(int256 x) internal pure returns (int256) {
        if (x <= 0) {
            revert("negative value passed to log2_256");
        }

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int256 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int256 y = 0;

        int256 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int256 z = rawX;

        for (
            uint8 i = 0;
            i < 32; /* FRACTIONAL_PLACES */
            i++
        ) {
            z = Fix64V1.mul_256(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }
            b >>= 1;
        }

        return y;
    }

    function log_256(int256 x) internal pure returns (int256) {
        return Fix64V1.mul_256(log2_256(x), LN2);
    }

    function log2(int64 x) internal pure returns (int64) {
        if (x <= 0) revert("non-positive value passed to log2");

        // This implementation is based on Clay. S. Turner's fast binary logarithm
        // algorithm (C. S. Turner,  "A Fast Binary Logarithm Algorithm", IEEE Signal
        //     Processing Mag., pp. 124,140, Sep. 2010.)

        int64 b = 1 << 31; // FRACTIONAL_PLACES - 1
        int64 y = 0;

        int64 rawX = x;
        while (rawX < Fix64V1.ONE) {
            rawX <<= 1;
            y -= Fix64V1.ONE;
        }

        while (rawX >= Fix64V1.ONE << 1) {
            rawX >>= 1;
            y += Fix64V1.ONE;
        }

        int64 z = rawX;

        for (int32 i = 0; i < Fix64V1.FRACTIONAL_PLACES; i++) {
            z = Fix64V1.mul(z, z);
            if (z >= Fix64V1.ONE << 1) {
                z = z >> 1;
                y += b;
            }

            b >>= 1;
        }

        return y;
    }

    function log(int64 x) internal pure returns (int64) {
        return Fix64V1.mul(log2(x), LN2);
    }

    function exp(int64 x) internal pure returns (int64) {
        if (x == 0) return Fix64V1.ONE;
        if (x == Fix64V1.ONE) return E;
        if (x >= LN_MAX) return Fix64V1.MAX_VALUE;
        if (x <= LN_MIN) return 0;

        /* The algorithm is based on the power series for exp(x):
         * http://en.wikipedia.org/wiki/Exponential_function#Formal_definition
         *
         * From term n, we get term n+1 by multiplying with x/n.
         * When the sum term drops to zero, we can stop summing.
         */

        // The power-series converges much faster on positive values
        // and exp(-x) = 1/exp(x).

        bool neg = (x < 0);
        if (neg) x = -x;

        int64 result = Fix64V1.add(int64(x), Fix64V1.ONE);
        int64 term = x;

        for (uint32 i = 2; i < 40; i++) {
            term = Fix64V1.mul(x, Fix64V1.div(term, int32(i) * Fix64V1.ONE));
            result = Fix64V1.add(result, int64(term));
            if (term == 0) break;
        }

        if (neg) {
            result = Fix64V1.div(Fix64V1.ONE, result);
        }

        return result;
    }

    function clamp(int64 x)
        internal
        pure
        returns (
            int64,
            bool,
            bool
        )
    {
        int64 clamped2Pi = x;
        for (uint8 i = 0; i < 29; ++i) {
            clamped2Pi %= LARGE_PI >> i;
        }
        if (x < 0) {
            clamped2Pi += Fix64V1.TWO_PI;
        }

        bool flipVertical = clamped2Pi >= Fix64V1.PI;
        int64 clampedPi = clamped2Pi;
        while (clampedPi >= Fix64V1.PI) {
            clampedPi -= Fix64V1.PI;
        }

        bool flipHorizontal = clampedPi >= Fix64V1.PI_OVER_2;

        int64 clampedPiOver2 = clampedPi;
        if (clampedPiOver2 >= Fix64V1.PI_OVER_2)
            clampedPiOver2 -= Fix64V1.PI_OVER_2;

        return (clampedPiOver2, flipHorizontal, flipVertical);
    }

    function acos(int64 x) internal pure returns (int64 result) {
        if (x < -Fix64V1.ONE || x > Fix64V1.ONE) revert("invalid range for x");
        if (x == 0) return Fix64V1.PI_OVER_2;

        int64 t1 = Fix64V1.ONE - Fix64V1.mul(x, x);
        int64 t2 = Fix64V1.div(sqrt(t1), x);

        result = atan(t2);
        return x < 0 ? result + Fix64V1.PI : result;
    }

    function atan(int64 z) internal pure returns (int64 result) {
        if (z == 0) return 0;

        bool neg = z < 0;
        if (neg) z = -z;

        int64 two = Fix64V1.TWO;
        int64 three = Fix64V1.THREE;

        bool invert = z > Fix64V1.ONE;
        if (invert) z = Fix64V1.div(Fix64V1.ONE, z);

        result = Fix64V1.ONE;
        int64 term = Fix64V1.ONE;

        int64 zSq = Fix64V1.mul(z, z);
        int64 zSq2 = Fix64V1.mul(zSq, two);
        int64 zSqPlusOne = Fix64V1.add(zSq, Fix64V1.ONE);
        int64 zSq12 = Fix64V1.mul(zSqPlusOne, two);
        int64 dividend = zSq2;
        int64 divisor = Fix64V1.mul(zSqPlusOne, three);

        for (uint8 i = 2; i < 30; ++i) {
            term = Fix64V1.mul(term, Fix64V1.div(dividend, divisor));
            result = Fix64V1.add(result, term);

            dividend = Fix64V1.add(dividend, zSq2);
            divisor = Fix64V1.add(divisor, zSq12);

            if (term == 0) break;
        }

        result = Fix64V1.mul(result, Fix64V1.div(z, zSqPlusOne));

        if (invert) {
            result = Fix64V1.sub(Fix64V1.PI_OVER_2, result);
        }

        if (neg) {
            result = -result;
        }

        return result;
    }

    function atan2(int64 y, int64 x) internal pure returns (int64 result) {
        int64 e = 1202590848; /* 0.28 */
        int64 yl = y;
        int64 xl = x;

        if (xl == 0) {
            if (yl > 0) {
                return Fix64V1.PI_OVER_2;
            }
            if (yl == 0) {
                return 0;
            }
            return -Fix64V1.PI_OVER_2;
        }

        int64 z = Fix64V1.div(y, x);

        if (
            Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z))) ==
            type(int64).max
        ) {
            return y < 0 ? -Fix64V1.PI_OVER_2 : Fix64V1.PI_OVER_2;
        }

        if (Fix64V1.abs(z) < Fix64V1.ONE) {
            result = Fix64V1.div(
                z,
                Fix64V1.add(Fix64V1.ONE, Fix64V1.mul(e, Fix64V1.mul(z, z)))
            );
            if (xl < 0) {
                if (yl < 0) {
                    return Fix64V1.sub(result, Fix64V1.PI);
                }

                return Fix64V1.add(result, Fix64V1.PI);
            }
        } else {
            result = Fix64V1.sub(
                Fix64V1.PI_OVER_2,
                Fix64V1.div(z, Fix64V1.add(Fix64V1.mul(z, z), e))
            );

            if (yl < 0) {
                return Fix64V1.sub(result, Fix64V1.PI);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

import "./Fix64V1.sol";
import "./Trig256.sol";

library MathUtils {
    int32 public constant RecursionLimit = 32;
    int64 public constant AngleTolerance = 42949672; /* 0.01 */
    int64 public constant Epsilon = 4; /* 0.000000001 */

    function calcSquareDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        return Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy));
    }

    function calcDistance(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2
    ) internal pure returns (int64) {
        int64 dx = Fix64V1.sub(x2, x1);
        int64 dy = Fix64V1.sub(y2, y1);
        int64 distance = Trig256.sqrt(
            Fix64V1.add(Fix64V1.mul(dx, dx), Fix64V1.mul(dy, dy))
        );
        return distance;
    }

    function crossProduct(
        int64 x1,
        int64 y1,
        int64 x2,
        int64 y2,
        int64 x,
        int64 y
    ) internal pure returns (int64) {
        return
            Fix64V1.sub(
                Fix64V1.mul(Fix64V1.sub(x, x2), Fix64V1.sub(y2, y1)),
                Fix64V1.mul(Fix64V1.sub(y, y2), Fix64V1.sub(x2, x1))
            );
    }

    struct CalcIntersection {
        int64 aX1;
        int64 aY1;
        int64 aX2;
        int64 aY2;
        int64 bX1;
        int64 bY1;
        int64 bX2;
        int64 bY2;
    }

    function calcIntersection(CalcIntersection memory f)
        internal
        pure
        returns (
            int64 x,
            int64 y,
            bool
        )
    {
        int64 num = Fix64V1.mul(
            Fix64V1.sub(f.aY1, f.bY1),
            Fix64V1.sub(f.bX2, f.bX1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aX1, f.bX1), Fix64V1.sub(f.bY2, f.bY1));
        int64 den = Fix64V1.mul(
            Fix64V1.sub(f.aX2, f.aX1),
            Fix64V1.sub(f.bY2, f.bY1)
        ) - Fix64V1.mul(Fix64V1.sub(f.aY2, f.aY1), Fix64V1.sub(f.bX2, f.bX1));

        if (Fix64V1.abs(den) < Epsilon) {
            x = 0;
            y = 0;
            return (x, y, false);
        }

        int64 r = Fix64V1.div(num, den);
        x = Fix64V1.add(f.aX1, Fix64V1.mul(r, Fix64V1.sub(f.aX2, f.aX1)));
        y = Fix64V1.add(f.aY1, Fix64V1.mul(r, Fix64V1.sub(f.aY2, f.aY1)));
        return (x, y, true);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community, Inc. All rights reserved. */

pragma solidity ^0.8.13;

struct Vector2 {
    int64 x;
    int64 y;
}

// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) 2021 Kohi Art Community Inc. All rights reserved. */

pragma solidity ^0.8.13;

library SinLut256 {
    /**
     * @notice Lookup tables for computing the sine value for a given angle.
     * @param i The clamped and rounded angle integral to index into the table.
     * @return The sine value in fixed-point (Q31.32) space.
     */
    function sinlut(int256 i) external pure returns (int64) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) {
                                        return 0;
                                    } else {
                                        return 26456769;
                                    }
                                } else {
                                    if (i == 2) {
                                        return 52912534;
                                    } else {
                                        return 79366292;
                                    }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) {
                                        return 105817038;
                                    } else {
                                        return 132263769;
                                    }
                                } else {
                                    if (i == 6) {
                                        return 158705481;
                                    } else {
                                        return 185141171;
                                    }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) {
                                        return 211569835;
                                    } else {
                                        return 237990472;
                                    }
                                } else {
                                    if (i == 10) {
                                        return 264402078;
                                    } else {
                                        return 290803651;
                                    }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) {
                                        return 317194190;
                                    } else {
                                        return 343572692;
                                    }
                                } else {
                                    if (i == 14) {
                                        return 369938158;
                                    } else {
                                        return 396289586;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) {
                                        return 422625977;
                                    } else {
                                        return 448946331;
                                    }
                                } else {
                                    if (i == 18) {
                                        return 475249649;
                                    } else {
                                        return 501534935;
                                    }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) {
                                        return 527801189;
                                    } else {
                                        return 554047416;
                                    }
                                } else {
                                    if (i == 22) {
                                        return 580272619;
                                    } else {
                                        return 606475804;
                                    }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) {
                                        return 632655975;
                                    } else {
                                        return 658812141;
                                    }
                                } else {
                                    if (i == 26) {
                                        return 684943307;
                                    } else {
                                        return 711048483;
                                    }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) {
                                        return 737126679;
                                    } else {
                                        return 763176903;
                                    }
                                } else {
                                    if (i == 30) {
                                        return 789198169;
                                    } else {
                                        return 815189489;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) {
                                        return 841149875;
                                    } else {
                                        return 867078344;
                                    }
                                } else {
                                    if (i == 34) {
                                        return 892973912;
                                    } else {
                                        return 918835595;
                                    }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) {
                                        return 944662413;
                                    } else {
                                        return 970453386;
                                    }
                                } else {
                                    if (i == 38) {
                                        return 996207534;
                                    } else {
                                        return 1021923881;
                                    }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) {
                                        return 1047601450;
                                    } else {
                                        return 1073239268;
                                    }
                                } else {
                                    if (i == 42) {
                                        return 1098836362;
                                    } else {
                                        return 1124391760;
                                    }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) {
                                        return 1149904493;
                                    } else {
                                        return 1175373592;
                                    }
                                } else {
                                    if (i == 46) {
                                        return 1200798091;
                                    } else {
                                        return 1226177026;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) {
                                        return 1251509433;
                                    } else {
                                        return 1276794351;
                                    }
                                } else {
                                    if (i == 50) {
                                        return 1302030821;
                                    } else {
                                        return 1327217884;
                                    }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) {
                                        return 1352354586;
                                    } else {
                                        return 1377439973;
                                    }
                                } else {
                                    if (i == 54) {
                                        return 1402473092;
                                    } else {
                                        return 1427452994;
                                    }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) {
                                        return 1452378731;
                                    } else {
                                        return 1477249357;
                                    }
                                } else {
                                    if (i == 58) {
                                        return 1502063928;
                                    } else {
                                        return 1526821503;
                                    }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) {
                                        return 1551521142;
                                    } else {
                                        return 1576161908;
                                    }
                                } else {
                                    if (i == 62) {
                                        return 1600742866;
                                    } else {
                                        return 1625263084;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) {
                                        return 1649721630;
                                    } else {
                                        return 1674117578;
                                    }
                                } else {
                                    if (i == 66) {
                                        return 1698450000;
                                    } else {
                                        return 1722717974;
                                    }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) {
                                        return 1746920580;
                                    } else {
                                        return 1771056897;
                                    }
                                } else {
                                    if (i == 70) {
                                        return 1795126012;
                                    } else {
                                        return 1819127010;
                                    }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) {
                                        return 1843058980;
                                    } else {
                                        return 1866921015;
                                    }
                                } else {
                                    if (i == 74) {
                                        return 1890712210;
                                    } else {
                                        return 1914431660;
                                    }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) {
                                        return 1938078467;
                                    } else {
                                        return 1961651733;
                                    }
                                } else {
                                    if (i == 78) {
                                        return 1985150563;
                                    } else {
                                        return 2008574067;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) {
                                        return 2031921354;
                                    } else {
                                        return 2055191540;
                                    }
                                } else {
                                    if (i == 82) {
                                        return 2078383740;
                                    } else {
                                        return 2101497076;
                                    }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) {
                                        return 2124530670;
                                    } else {
                                        return 2147483647;
                                    }
                                } else {
                                    if (i == 86) {
                                        return 2170355138;
                                    } else {
                                        return 2193144275;
                                    }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) {
                                        return 2215850191;
                                    } else {
                                        return 2238472027;
                                    }
                                } else {
                                    if (i == 90) {
                                        return 2261008923;
                                    } else {
                                        return 2283460024;
                                    }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) {
                                        return 2305824479;
                                    } else {
                                        return 2328101438;
                                    }
                                } else {
                                    if (i == 94) {
                                        return 2350290057;
                                    } else {
                                        return 2372389494;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) {
                                        return 2394398909;
                                    } else {
                                        return 2416317469;
                                    }
                                } else {
                                    if (i == 98) {
                                        return 2438144340;
                                    } else {
                                        return 2459878695;
                                    }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) {
                                        return 2481519710;
                                    } else {
                                        return 2503066562;
                                    }
                                } else {
                                    if (i == 102) {
                                        return 2524518435;
                                    } else {
                                        return 2545874514;
                                    }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) {
                                        return 2567133990;
                                    } else {
                                        return 2588296054;
                                    }
                                } else {
                                    if (i == 106) {
                                        return 2609359905;
                                    } else {
                                        return 2630324743;
                                    }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) {
                                        return 2651189772;
                                    } else {
                                        return 2671954202;
                                    }
                                } else {
                                    if (i == 110) {
                                        return 2692617243;
                                    } else {
                                        return 2713178112;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) {
                                        return 2733636028;
                                    } else {
                                        return 2753990216;
                                    }
                                } else {
                                    if (i == 114) {
                                        return 2774239903;
                                    } else {
                                        return 2794384321;
                                    }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) {
                                        return 2814422705;
                                    } else {
                                        return 2834354295;
                                    }
                                } else {
                                    if (i == 118) {
                                        return 2854178334;
                                    } else {
                                        return 2873894071;
                                    }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) {
                                        return 2893500756;
                                    } else {
                                        return 2912997648;
                                    }
                                } else {
                                    if (i == 122) {
                                        return 2932384004;
                                    } else {
                                        return 2951659090;
                                    }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) {
                                        return 2970822175;
                                    } else {
                                        return 2989872531;
                                    }
                                } else {
                                    if (i == 126) {
                                        return 3008809435;
                                    } else {
                                        return 3027632170;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) {
                                        return 3046340019;
                                    } else {
                                        return 3064932275;
                                    }
                                } else {
                                    if (i == 130) {
                                        return 3083408230;
                                    } else {
                                        return 3101767185;
                                    }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) {
                                        return 3120008443;
                                    } else {
                                        return 3138131310;
                                    }
                                } else {
                                    if (i == 134) {
                                        return 3156135101;
                                    } else {
                                        return 3174019130;
                                    }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) {
                                        return 3191782721;
                                    } else {
                                        return 3209425199;
                                    }
                                } else {
                                    if (i == 138) {
                                        return 3226945894;
                                    } else {
                                        return 3244344141;
                                    }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) {
                                        return 3261619281;
                                    } else {
                                        return 3278770658;
                                    }
                                } else {
                                    if (i == 142) {
                                        return 3295797620;
                                    } else {
                                        return 3312699523;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) {
                                        return 3329475725;
                                    } else {
                                        return 3346125588;
                                    }
                                } else {
                                    if (i == 146) {
                                        return 3362648482;
                                    } else {
                                        return 3379043779;
                                    }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) {
                                        return 3395310857;
                                    } else {
                                        return 3411449099;
                                    }
                                } else {
                                    if (i == 150) {
                                        return 3427457892;
                                    } else {
                                        return 3443336630;
                                    }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) {
                                        return 3459084709;
                                    } else {
                                        return 3474701532;
                                    }
                                } else {
                                    if (i == 154) {
                                        return 3490186507;
                                    } else {
                                        return 3505539045;
                                    }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) {
                                        return 3520758565;
                                    } else {
                                        return 3535844488;
                                    }
                                } else {
                                    if (i == 158) {
                                        return 3550796243;
                                    } else {
                                        return 3565613262;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) {
                                        return 3580294982;
                                    } else {
                                        return 3594840847;
                                    }
                                } else {
                                    if (i == 162) {
                                        return 3609250305;
                                    } else {
                                        return 3623522808;
                                    }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) {
                                        return 3637657816;
                                    } else {
                                        return 3651654792;
                                    }
                                } else {
                                    if (i == 166) {
                                        return 3665513205;
                                    } else {
                                        return 3679232528;
                                    }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) {
                                        return 3692812243;
                                    } else {
                                        return 3706251832;
                                    }
                                } else {
                                    if (i == 170) {
                                        return 3719550786;
                                    } else {
                                        return 3732708601;
                                    }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) {
                                        return 3745724777;
                                    } else {
                                        return 3758598821;
                                    }
                                } else {
                                    if (i == 174) {
                                        return 3771330243;
                                    } else {
                                        return 3783918561;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) {
                                        return 3796363297;
                                    } else {
                                        return 3808663979;
                                    }
                                } else {
                                    if (i == 178) {
                                        return 3820820141;
                                    } else {
                                        return 3832831319;
                                    }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) {
                                        return 3844697060;
                                    } else {
                                        return 3856416913;
                                    }
                                } else {
                                    if (i == 182) {
                                        return 3867990433;
                                    } else {
                                        return 3879417181;
                                    }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) {
                                        return 3890696723;
                                    } else {
                                        return 3901828632;
                                    }
                                } else {
                                    if (i == 186) {
                                        return 3912812484;
                                    } else {
                                        return 3923647863;
                                    }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) {
                                        return 3934334359;
                                    } else {
                                        return 3944871565;
                                    }
                                } else {
                                    if (i == 190) {
                                        return 3955259082;
                                    } else {
                                        return 3965496515;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) {
                                        return 3975583476;
                                    } else {
                                        return 3985519583;
                                    }
                                } else {
                                    if (i == 194) {
                                        return 3995304457;
                                    } else {
                                        return 4004937729;
                                    }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) {
                                        return 4014419032;
                                    } else {
                                        return 4023748007;
                                    }
                                } else {
                                    if (i == 198) {
                                        return 4032924300;
                                    } else {
                                        return 4041947562;
                                    }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) {
                                        return 4050817451;
                                    } else {
                                        return 4059533630;
                                    }
                                } else {
                                    if (i == 202) {
                                        return 4068095769;
                                    } else {
                                        return 4076503544;
                                    }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) {
                                        return 4084756634;
                                    } else {
                                        return 4092854726;
                                    }
                                } else {
                                    if (i == 206) {
                                        return 4100797514;
                                    } else {
                                        return 4108584696;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) {
                                        return 4116215977;
                                    } else {
                                        return 4123691067;
                                    }
                                } else {
                                    if (i == 210) {
                                        return 4131009681;
                                    } else {
                                        return 4138171544;
                                    }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) {
                                        return 4145176382;
                                    } else {
                                        return 4152023930;
                                    }
                                } else {
                                    if (i == 214) {
                                        return 4158713929;
                                    } else {
                                        return 4165246124;
                                    }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) {
                                        return 4171620267;
                                    } else {
                                        return 4177836117;
                                    }
                                } else {
                                    if (i == 218) {
                                        return 4183893437;
                                    } else {
                                        return 4189791999;
                                    }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) {
                                        return 4195531577;
                                    } else {
                                        return 4201111955;
                                    }
                                } else {
                                    if (i == 222) {
                                        return 4206532921;
                                    } else {
                                        return 4211794268;
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) {
                                        return 4216895797;
                                    } else {
                                        return 4221837315;
                                    }
                                } else {
                                    if (i == 226) {
                                        return 4226618635;
                                    } else {
                                        return 4231239573;
                                    }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) {
                                        return 4235699957;
                                    } else {
                                        return 4239999615;
                                    }
                                } else {
                                    if (i == 230) {
                                        return 4244138385;
                                    } else {
                                        return 4248116110;
                                    }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) {
                                        return 4251932639;
                                    } else {
                                        return 4255587827;
                                    }
                                } else {
                                    if (i == 234) {
                                        return 4259081536;
                                    } else {
                                        return 4262413632;
                                    }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) {
                                        return 4265583990;
                                    } else {
                                        return 4268592489;
                                    }
                                } else {
                                    if (i == 238) {
                                        return 4271439015;
                                    } else {
                                        return 4274123460;
                                    }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) {
                                        return 4276645722;
                                    } else {
                                        return 4279005706;
                                    }
                                } else {
                                    if (i == 242) {
                                        return 4281203321;
                                    } else {
                                        return 4283238485;
                                    }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) {
                                        return 4285111119;
                                    } else {
                                        return 4286821154;
                                    }
                                } else {
                                    if (i == 246) {
                                        return 4288368525;
                                    } else {
                                        return 4289753172;
                                    }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) {
                                        return 4290975043;
                                    } else {
                                        return 4292034091;
                                    }
                                } else {
                                    if (i == 250) {
                                        return 4292930277;
                                    } else {
                                        return 4293663567;
                                    }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) {
                                        return 4294233932;
                                    } else {
                                        return 4294641351;
                                    }
                                } else {
                                    if (i == 254) {
                                        return 4294885809;
                                    } else {
                                        return 4294967296;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Kohi/Vector2.sol";
import "../Kohi/Fix64V1.sol";
import "../Kohi/Trig256.sol";

struct Bezier
{
    Vector2 a;
    Vector2 b;
    Vector2 c;
    Vector2 d;
    int32 len;
    int64[] arcLengths;
}

library BezierMethods {

    function create(Vector2 memory t, Vector2 memory h, Vector2 memory s, Vector2 memory i) internal pure returns (Bezier memory result) {
        result.a = t;
        result.b = h;
        result.c = s;
        result.d = i;
        result.len = 100;
        result.arcLengths = new int64[](uint32(result.len + 1));
        result.arcLengths[0] = 0;

        int64 n = xFunc(result, 0);
        int64 r = yFunc(result, 0);
        int64 e = 0;

        for (int32 ax = 1; ax <= result.len; ax += 1)
        {
            int64 z = Fix64V1.mul(42949672 /* 0.01 */, ax * Fix64V1.ONE);
            int64 c = xFunc(result, z);
            int64 u = yFunc(result, z);

            int64 y = Fix64V1.sub(n, c);
            int64 o = Fix64V1.sub(r, u);

            int64 t0 = Fix64V1.mul(y, y);
            int64 t1 = Fix64V1.mul(o, o);

            int64 sqrt = Fix64V1.add(t0, t1);
            e = Fix64V1.add(e, Trig256.sqrt(sqrt));
            result.arcLengths[uint32(ax)] = e;
            n = c;
            r = u;
        }
    }

    function xFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.x)));
        int64 t2 = Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(Fix64V1.mul(t0, t0), 3 * Fix64V1.ONE), t), self.b.x);
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.x)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.x)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));
    }

    function yFunc(Bezier memory self, int64 t) internal pure returns (int64) {
        int64 t0 = Fix64V1.sub(Fix64V1.ONE, t);
        int64 t1 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(t0, self.a.y)));
        int64 t2 = Fix64V1.mul(t0, Fix64V1.mul(t0, Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t, self.b.y))));
        int64 t3 = Fix64V1.mul(3 * Fix64V1.ONE, Fix64V1.mul(t0, Fix64V1.mul(Fix64V1.mul(t, t), self.c.y)));
        int64 t4 = Fix64V1.mul(t, Fix64V1.mul(t, Fix64V1.mul(t, self.d.y)));

        return Fix64V1.add(Fix64V1.add(t1, t2), Fix64V1.add(t3, t4));        
    }

    function mx(Bezier memory self,int64 t) internal pure returns (int64) {
        return xFunc(self, map(self, t));
    }

    function my(Bezier memory self,int64 t) internal pure returns (int64) {
        return yFunc(self, map(self, t));
    }

    function map(Bezier memory self, int64 t) private pure returns (int64) {
        int64 h = Fix64V1.mul(t, self.arcLengths[uint32(self.len)]);
        int32 n = 0;
        int32 s = 0;
        for (int32 i = self.len; s < i;)
        {
            n = s + ((i - s) / 2 | 0);
            if (self.arcLengths[uint32(n)] < h)
            {
                s = n + 1;
            }
            else
            {
                i = n;
            }
        }
        if (self.arcLengths[uint32(n)] > h)
        {
            n--;
        }
        int64 r = self.arcLengths[uint32(n)];
        return r == h ? Fix64V1.div(n * Fix64V1.ONE, self.len * Fix64V1.ONE) :
            Fix64V1.div(
                Fix64V1.add(n * Fix64V1.ONE, Fix64V1.div(Fix64V1.sub(h, r), Fix64V1.sub(self.arcLengths[uint32(n + 1)], r))),
                self.len * Fix64V1.ONE);
    }
}