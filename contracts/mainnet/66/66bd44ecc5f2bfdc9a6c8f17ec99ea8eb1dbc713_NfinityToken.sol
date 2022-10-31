// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/


pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import "./IDescriptor.sol";
import {Tools} from "./Tools.sol";

contract Descriptor is Ownable {
    string[] rarityNames = ["Common", "Uncommon", "Rare", "Epic", "Legendary"];


    uint8[2][] nodesOfLevel = [
    [3, 4],
    [3, 5],
    [4, 6],
    [5, 7],
    [6, 11]
    ];

    uint8[2][5] bgColorIndexOfRarity = [
    [6, 7],
    [3, 5],
    [1, 1],
    [2, 2],
    [0, 0]
    ];

    uint16[4][] team1Regions = [
    [229, 305, 572, 377], // front court
    [222, 359, 581, 428], //
    [218, 424, 582, 514], // midfield
    [213, 513, 586, 586], //
    [202, 573, 599, 655], // backfield
    [333, 636, 467, 690], // freethrow lane
    [364, 710, 437, 710]  // door
    ];

    uint16[4][] team2Regions = [
    [202, 573, 599, 655], // front court
    [213, 513, 586, 586], //
    [218, 424, 582, 514], // midfield
    [222, 359, 581, 428], //
    [229, 305, 572, 377], // backfield
    [344, 281, 458, 327], // freethrow lane
    [365, 250, 436, 250]  // door
    ];

    uint16[2][11][2][] teamFormations = [
    [
    [[358, 653], [248, 532], [313, 523], [396, 532], [499, 578], [577, 527], [315, 491], [401, 429], [562, 427], [298, 383], [480, 404]],
    [[397, 294], [285, 360], [456, 336], [369, 381], [551, 410], [273, 464], [574, 470], [231, 540], [524, 583], [281, 576], [419, 596]]],
    [[[360, 672], [221, 518], [339, 533], [416, 570], [565, 532], [225, 496], [436, 443], [535, 426], [228, 394], [454, 412], [565, 387]],
    [[439, 308], [301, 343], [455, 325], [376, 372], [520, 361], [305, 434], [504, 492], [229, 562], [404, 569], [370, 595], [409, 609]]],
    [[[383, 647], [259, 522], [336, 514], [398, 532], [464, 524], [518, 520], [218, 441], [374, 442], [472, 507], [306, 361], [521, 415]],
    [[406, 317], [253, 376], [375, 335], [455, 359], [535, 327], [379, 439], [525, 482], [346, 540], [441, 529], [205, 618], [563, 610]]],
    [[[412, 689], [214, 617], [308, 594], [417, 643], [563, 653], [229, 447], [515, 489], [352, 369], [482, 421], [322, 342], [508, 354]],
    [[361, 313], [233, 382], [357, 394], [387, 360], [488, 383], [519, 422], [282, 460], [350, 456], [543, 445], [263, 582], [506, 583]]],
    [[[351, 666], [238, 605], [302, 600], [485, 576], [592, 605], [228, 450], [398, 476], [486, 469], [267, 310], [365, 315], [550, 311]],
    [[452, 321], [376, 350], [485, 352], [241, 371], [354, 419], [483, 400], [250, 463], [561, 435], [273, 585], [535, 516], [377, 586]]],
    [[[401, 675], [249, 578], [330, 625], [492, 608], [507, 621], [223, 483], [516, 510], [308, 365], [567, 361], [359, 317], [494, 362]],
    [[389, 302], [284, 319], [563, 345], [236, 399], [356, 359], [528, 362], [267, 473], [511, 473], [318, 547], [433, 538], [598, 602]]],
    [[[372, 660], [278, 544], [338, 572], [443, 527], [513, 570], [371, 430], [470, 485], [300, 404], [267, 363], [368, 333], [512, 315]],
    [[433, 311], [233, 336], [361, 319], [440, 352], [526, 358], [261, 510], [414, 430], [556, 450], [293, 616], [407, 651], [468, 619]]],
    [[[338, 689], [268, 615], [419, 621], [323, 515], [456, 521], [579, 536], [227, 490], [360, 469], [484, 436], [288, 424], [579, 370]],
    [[429, 285], [294, 370], [567, 326], [277, 425], [441, 396], [529, 389], [294, 493], [407, 485], [474, 497], [249, 549], [557, 585]]],
    [[[434, 640], [220, 603], [382, 625], [415, 647], [555, 636], [255, 430], [579, 502], [389, 378], [565, 398], [322, 342], [431, 334]],
    [[352, 325], [227, 408], [398, 379], [444, 388], [495, 369], [240, 513], [431, 506], [561, 435], [288, 538], [454, 517], [520, 525]]],
    [[[445, 642], [245, 515], [320, 557], [403, 562], [537, 532], [304, 453], [428, 493], [493, 485], [293, 424], [416, 368], [461, 396]],
    [[433, 313], [260, 346], [380, 319], [410, 367], [565, 357], [336, 433], [415, 495], [502, 431], [264, 583], [365, 596], [597, 638]]],
    [[[397, 650], [286, 589], [381, 600], [467, 642], [565, 595], [331, 504], [508, 501], [363, 400], [476, 376], [305, 340], [567, 364]],
    [[435, 310], [300, 342], [378, 333], [431, 315], [499, 335], [222, 462], [444, 487], [397, 538], [583, 513], [382, 651], [416, 602]]],
    [[[352, 677], [290, 587], [417, 625], [398, 577], [469, 576], [290, 470], [570, 494], [330, 394], [366, 347], [433, 319], [313, 307]],
    [[394, 295], [249, 357], [524, 362], [223, 425], [458, 366], [556, 389], [324, 441], [387, 433], [531, 476], [382, 550], [421, 527]]],
    [[[455, 682], [382, 575], [418, 581], [325, 553], [342, 527], [550, 551], [269, 453], [518, 424], [342, 406], [562, 424], [313, 307]],
    [[430, 317], [306, 379], [346, 410], [434, 395], [496, 415], [340, 468], [508, 507], [582, 515], [249, 642], [447, 573], [486, 642]]],
    [[[420, 666], [260, 548], [308, 551], [412, 523], [525, 533], [251, 455], [418, 482], [339, 373], [248, 362], [362, 342], [466, 337]],
    [[427, 312], [296, 328], [321, 355], [434, 326], [529, 334], [326, 458], [353, 424], [517, 503], [267, 582], [352, 595], [555, 615]]],
    [[[343, 665], [355, 642], [530, 624], [304, 581], [521, 552], [246, 442], [438, 436], [445, 402], [270, 372], [541, 350], [516, 325]],
    [[454, 320], [392, 364], [520, 372], [272, 412], [552, 405], [264, 474], [418, 435], [540, 488], [566, 517], [312, 614], [426, 585]]],
    [[[347, 656], [297, 537], [376, 584], [447, 513], [551, 551], [367, 469], [534, 497], [387, 364], [246, 350], [379, 320], [516, 325]],
    [[404, 315], [390, 368], [424, 349], [352, 411], [548, 419], [218, 428], [419, 432], [448, 525], [270, 623], [551, 645], [426, 585]]],
    [[[462, 649], [282, 618], [405, 624], [299, 532], [381, 551], [506, 584], [253, 513], [363, 499], [535, 454], [250, 365], [538, 387]],
    [[448, 318], [347, 336], [537, 376], [302, 395], [522, 363], [330, 500], [551, 441], [502, 515], [236, 640], [515, 589], [426, 585]]],
    [[[430, 656], [260, 583], [447, 577], [554, 530], [261, 481], [339, 511], [466, 510], [541, 462], [338, 396], [419, 408], [490, 400]],
    [[392, 306], [395, 335], [546, 352], [325, 410], [401, 423], [315, 510], [539, 500], [517, 583], [268, 609], [440, 637], [426, 585]]],
    [[[385, 665], [357, 644], [551, 597], [333, 515], [507, 585], [357, 503], [412, 498], [310, 383], [394, 329], [481, 305], [520, 362]],
    [[384, 312], [303, 369], [367, 340], [440, 376], [490, 330], [367, 437], [496, 462], [369, 525], [486, 528], [234, 616], [444, 624]]],
    [[[376, 668], [296, 514], [341, 534], [474, 549], [554, 513], [231, 442], [426, 437], [561, 477], [321, 411], [355, 371], [520, 362]],
    [[454, 293], [289, 353], [459, 353], [282, 367], [346, 424], [522, 398], [345, 439], [575, 455], [304, 552], [567, 522], [371, 617]]]];

    string[] footballColors = [
    '#e4001e',
    '#1d9cfe',
    '#ff9504',
    '#00a143'
    ];

    mapping(uint256 => mapping(uint256 => string)) elementGroups;

    constructor() Ownable(){
    }

    function setElement(uint256 groupIndex, uint256[] calldata index, string[] calldata content) external onlyOwner {
        for (uint i = 0; i < index.length; i ++) {
            elementGroups[groupIndex][index[i]] = content[i];
        }
    }

    function renderBg(uint256 groupBg, uint256 groupColor, uint256 colorIndex) internal view returns (string memory s) {
        s = "";
        if (colorIndex == 0) {
            s = string(abi.encodePacked(s, elementGroups[groupBg][0]));
        } else {
            s = string(abi.encodePacked(s, elementGroups[groupBg][1], elementGroups[groupColor][colorIndex - 1], elementGroups[groupBg][2]));
        }
    }

    function renderElement(uint256 group, uint256 index) internal view returns (string memory){
        return elementGroups[group][index];
    }

    function renderWrapText(uint256 group, uint256 index, string memory text) internal view returns (string memory){
        return string(
            abi.encodePacked(
                elementGroups[group][index * 2],
                text,
                elementGroups[group][index * 2 + 1]
            )
        );
    }

    function renderStars(uint256 value) internal view returns (string memory){
        string memory s = "";
        for (uint256 i = 0; i <= value; i ++) {
            s = string(abi.encodePacked(
                    s,
                    '<use xlink:href="#star" transform="translate(',
                    Strings.toString(104 + i * 36),
                    ',983)" id="stm',
                    Strings.toString(i),
                    '" />\n'
                ));
        }
        return s;
    }

    function renderScoreBar(uint256 v, uint256 y, uint256 id) internal pure returns (string memory){
        uint256 x = 553 + v * 114 / 125;
        uint256 w = (10000 - v * 10000 / 125) * 114 / 10000;
        return string(abi.encodePacked(
                "<rect x=\"", Strings.toString(x),
                "\" y=\"", Strings.toString(y),
                "\" width=\"", Strings.toString(w),
                "\" height=\"4\" id=\"", Strings.toString(id),
                "\" />\n"
            ));
    }

    function renderTeam1Member(uint256 index, uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(
                '<use xlink:href="#team1member" transform="translate(',
                Strings.toString(x), ",", Strings.toString(y),
                ')" />\n'
            ));
    }

    function renderTeam2Member(uint256 index, uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(
                '<use xlink:href="#team2member" transform="translate(',
                Strings.toString(x), ",", Strings.toString(y),
                ')" />\n'
            ));
    }

    function renderTeam(IDescriptor.CardInfo calldata card) internal view returns (string memory){
        //        console.log(101);

        uint256 dir = Tools.Random8Bits(card.seed, 8, 0, 1);
        uint256 startType = Tools.Random8Bits(card.seed, 9, 1, 2) * 2 - 1;
        uint256 goalType = Tools.Random8Bits(card.seed, 10, card.rarity < 2 ? 1 : 0, startType == 0 ? 2 : 3);


        // may be one
        uint256 team1FormationIndex = Tools.Random8Bits(card.seed, 13, 0, uint8(teamFormations.length - 1));
        uint256 team2FormationIndex = Tools.Random8Bits(card.seed, 14, 0, uint8(teamFormations.length - 1));
        string memory data = "";

        // goalKeeper1
        uint256[2] memory gk1;
        {
            uint256 sx = teamFormations[team1FormationIndex][0][0][0];
            uint256 sy = teamFormations[team2FormationIndex][0][0][1];
            gk1 = [sx, sy];
            data = string(abi.encodePacked(data, renderTeam1Member(1, sx, sy)));
        }
        // goalKeeper2
        uint256[2] memory gk2;
        {
            uint256 sx = teamFormations[team2FormationIndex][0][0][0];
            uint256 sy = teamFormations[team2FormationIndex][0][0][1];
            gk2 = [sx, sy];
            data = string(abi.encodePacked(data, renderTeam2Member(1, sx, sy)));
        }
        uint256[2][] memory points = new uint256[2][](12);
        uint256 pointCounter = 0;

        if (startType == 0) {
            uint256 side = Tools.Random8Bits(card.seed, 15, 0, 1);
            uint256 sx = side == 0 ? Tools.Random16Bits(card.seed, 18, 146, 164) : Tools.Random16Bits(card.seed, 16, 624, 658);
            uint256 sy = Tools.Random16Bits(card.seed, 17, 296, 678);
            points[pointCounter++] = [sx, sy];
            data = string(abi.encodePacked(data, dir == 0 ? renderTeam1Member(1, sx, sy) : renderTeam2Member(1, sx, sy)));} else if (startType == 1) {
        } else if (startType == 1) {
            // pass
        }
        else if (startType == 2) {
            uint256 side = Tools.Random8Bits(card.seed, 15, 0, 1);
            uint256 sx;
            uint256 sy;
            if (dir == 0) {
                if (side == 0) {
                    sx = 227;
                    sy = 281;
                } else {
                    sx = 578;
                    sy = 281;
                }
            } else {
                if (side == 0) {
                    sx = 176;
                    sy = 696;
                } else {
                    sx = 624;
                    sy = 696;
                }
            }
            points[pointCounter++] = [sx, sy];
            data = string(abi.encodePacked(data, dir == 0 ? renderTeam1Member(1, sx, sy) : renderTeam2Member(1, sx, sy)));
        } else if (startType == 3) {
            points[pointCounter++] = dir == 0 ? gk1 : gk2;
        }

        int16 dy1 = int16(uint16(Tools.Random8Bits(card.seed, 18, 0, 31))) - 15;
        uint16 inPath = uint16(0xFFFF & (card.seed >> (19 * 8)));
        // 19 & 20

        {
            uint256 team1max = Tools.Random8Bits(card.seed, 11, nodesOfLevel[card.rarity][0], nodesOfLevel[card.rarity][1]);
            for (uint j = 0; j < 10; j ++) {
                if (startType == 0 || startType == 2) {
                    if (dir == 0 && j == 0) {
                        continue;
                    }
                }
                uint256 sx = teamFormations[team1FormationIndex][0][j + 1][0];
                uint256 sy = uint256(uint16(int16(teamFormations[team1FormationIndex][0][j + 1][1]) + dy1));
                gk1 = [sx, sy];
                data = string(abi.encodePacked(data, renderTeam1Member(1, sx, sy)));
                if (dir == 0) {
                    if (pointCounter < 2) {
                        points[pointCounter++] = gk1;
                    } else if (pointCounter < team1max) {
                        if (((inPath >> j) & 0x1) == 1) {
                            points[pointCounter++] = gk1;
                        }
                    }
                }
            }
        }
        {
            uint256 team2max = Tools.Random8Bits(card.seed, 12, nodesOfLevel[card.rarity][0], nodesOfLevel[card.rarity][1]);
            for (uint j = 0; j < 10; j ++) {
                if (startType == 0 || startType == 2) {
                    if (dir == 1 && j == 0) {
                        continue;
                    }
                }

                uint256 sx = teamFormations[team2FormationIndex][1][j + 1][0];
                uint256 sy = uint256(uint16(int16(teamFormations[team1FormationIndex][1][j + 1][1]) + dy1));
                gk2 = [sx, sy];
                data = string(abi.encodePacked(data, renderTeam2Member(1, sx, sy)));
                if (dir == 1) {
                    if (pointCounter < 2) {
                        points[pointCounter++] = gk2;
                    } else if (pointCounter < team2max) {
                        if (((inPath >> j) & 0x1) == 1) {
                            points[pointCounter++] = gk2;
                        }
                    }
                }
            }
        }
        string memory z = "";
        {
            if (goalType == 0) {
                uint256 sx = Tools.Random16Bits(card.seed, 21, dir == 0 ? team2Regions[6][0] : team1Regions[6][0], dir == 0 ? team2Regions[6][2] : team1Regions[6][2]);
                uint256 sy = dir == 0 ? team2Regions[6][1] : team1Regions[6][1];
                points[pointCounter++] = [sx, sy];
            } else if (goalType == 1) {
                uint256 side = Tools.Random8Bits(card.seed, 22, 0, 1);
                uint256 sx = side == 0 ? 164 : 648;
                uint256 sy = Tools.Random16Bits(card.seed, 23, 284, 700);
                points[pointCounter++] = [sx, sy];
            } else if (goalType == 2) {
                uint256 side = Tools.Random8Bits(card.seed, 22, 0, 1);
                uint256 sx = side == 0 ? Tools.Random16Bits(card.seed, 23, 222, 357) : Tools.Random16Bits(card.seed, 23, 445, 578);
                uint256 sy = dir == 0 ? 236 : 740;
                points[pointCounter++] = [sx, sy];
            } else if (goalType == 3) {
                z = "z";
            }
        }

        string memory pData = genPathData(points, pointCounter, z);
        data = string(abi.encodePacked(genPath(pData), data));


        uint8 dur = Tools.Random8Bits(card.seed, 25, 12, uint8(10 + pointCounter * 6));
        uint8 ballColor = Tools.Random8Bits(card.seed, 26, 0, 3);
        data = string(abi.encodePacked(data, genFootball(points[0][0], points[0][1], pData, dur, ballColor)));

        return data;
    }

    function genPathData(uint256[2][] memory points, uint256 pointCounter, string memory z) internal view returns (string memory path){
        path = "";
        if (pointCounter > 1) {
            path = "M";
            for (uint i = 0; i < pointCounter; i ++) {
                path = string(abi.encodePacked(path, " ", Strings.toString(points[i][0]), ",", Strings.toString(points[i][1])));
            }
            path = string(abi.encodePacked(path, z));
        }
    }

    function genPath(string memory path) internal view returns (string memory pathData){
        return string(abi.encodePacked(
                "<path style=\"opacity:0.97506925;fill:none;fill-opacity:0.416413;stroke-width:3;stroke-dasharray:11.564, 23.128;stroke:#f5f500;stroke-opacity:1\" d=\"",
                path,
                "\" id=\"path",
                "R42",
                "\" />\n"
            ));
    }

    function genFootball(uint256 x, uint256 y, string memory pathData, uint8 dur, uint8 ballColor) internal view returns (string memory path){
        return string(abi.encodePacked(
                "<g id=\"g1449\" transform=\"translate(-286.58244,-526.37697)\"> <path class=\"cls-6\" d=\"m 286.6417,510.61358 a 26,26 0 0 1 7.91,1.21 22,22 0 0 1 6.49,3.32 16.4,16.4 0 0 1 4.42,5 12.42,12.42 0 0 1 0.12,12.23 16.07,16.07 0 0 1 -4.36,5 21.85,21.85 0 0 1 -6.54,3.42 26.51,26.51 0 0 1 -16.09,0 21.85,21.85 0 0 1 -6.54,-3.42 16.24,16.24 0 0 1 -4.37,-5 12.38,12.38 0 0 1 0.13,-12.23 16.4,16.4 0 0 1 4.42,-5 22,22 0 0 1 6.49,-3.32 26,26 0 0 1 7.92,-1.21 z\" id=\"path1292\" style=\"fill:#ffffff\" /> <path class=\"cls-17\" d=\"m 298.4717,517.19358 a 15.05,15.05 0 0 1 2,1.92 13.2,13.2 0 0 1 1.55,2.16 11.16,11.16 0 0 1 1,2.38 10,10 0 0 1 -0.93,7.54 13.27,13.27 0 0 1 -3.59,4.11 17.67,17.67 0 0 1 -5.35,2.8 21,21 0 0 1 -6.55,1 c -0.45,0 -0.89,0 -1.34,0 -0.45,0 -0.87,-0.06 -1.31,-0.12 -0.44,-0.06 -0.85,-0.12 -1.28,-0.2 -0.43,-0.08 -0.83,-0.16 -1.24,-0.26 h -0.14 -0.15 a 19.67,19.67 0 0 1 -2.32,-0.76 16.71,16.71 0 0 1 -2.13,-1 16.12,16.12 0 0 1 -1.91,-1.25 14.64,14.64 0 0 1 -1.65,-1.47 l -0.09,-0.11 a 13.6,13.6 0 0 1 -1.37,-1.7 11.22,11.22 0 0 1 -1,-1.86 9.92,9.92 0 0 1 -0.63,-2 9.68,9.68 0 0 1 -0.2,-2.09 c 0,-0.21 0,-0.42 0,-0.63 0,-0.21 0,-0.41 0.07,-0.62 0.07,-0.21 0.06,-0.41 0.1,-0.61 0.04,-0.2 0.09,-0.41 0.15,-0.61 v -0.09 a 10.78,10.78 0 0 1 0.65,-1.77 13.48,13.48 0 0 1 1,-1.67 13.23,13.23 0 0 1 1.27,-1.55 15.79,15.79 0 0 1 1.53,-1.4 h 0.08 0.09 0.08 0.09 a 17.35,17.35 0 0 1 2.47,-1.52 19.33,19.33 0 0 1 2.8,-1.15 21.74,21.74 0 0 1 3.09,-0.72 22.28,22.28 0 0 1 3.3,-0.25 21.81,21.81 0 0 1 3.37,0.26 21,21 0 0 1 3.13,0.75 19.61,19.61 0 0 1 2.85,1.19 17.48,17.48 0 0 1 2.51,1.3 z m -3.21,14.63 3.55,0.69 a 11,11 0 0 0 1.06,-1.43 9.33,9.33 0 0 0 0.79,-1.54 8.59,8.59 0 0 0 0.49,-1.64 8.16,8.16 0 0 0 0.15,-1.72 c 0,-0.13 0,-0.27 0,-0.4 v -0.41 c 0,-0.13 0,-0.26 0,-0.4 0,-0.14 0,-0.26 -0.07,-0.39 h -3 a 1.36,1.36 0 0 1 -0.29,0 1.14,1.14 0 0 1 -0.26,-0.09 1.07,1.07 0 0 1 -0.22,-0.15 1.2,1.2 0 0 1 -0.17,-0.21 l -0.53,-0.8 -4.12,1.89 -1.74,4.73 2.59,2.64 1,-0.57 a 0.39,0.39 0 0 1 0.19,-0.1 h 0.22 0.23 0.2 m -15.41,0.74 2.44,-2.48 -1.85,-5 -3.91,-1.79 -0.58,0.89 a 0.61,0.61 0 0 1 -0.12,0.16 0.83,0.83 0 0 1 -0.18,0.13 l -0.25,0.08 a 1.36,1.36 0 0 1 -0.29,0 h -3 c 0,0.13 0,0.26 -0.07,0.39 -0.07,0.13 0,0.27 0,0.4 v 0.41 c 0,0.13 0,0.27 0,0.4 a 8.88,8.88 0 0 0 0.15,1.72 9.39,9.39 0 0 0 1.28,3.18 11,11 0 0 0 1.06,1.43 l 3.56,-0.69 h 0.41 0.16 l 0.14,0.06 0.13,0.09 1,0.57 m 1.9,-16.91 c -0.48,0.13 -0.94,0.28 -1.4,0.45 -0.46,0.17 -0.89,0.35 -1.32,0.55 -0.43,0.2 -0.84,0.41 -1.23,0.64 -0.39,0.23 -0.78,0.48 -1.15,0.74 l 1.41,2.23 a 0.64,0.64 0 0 1 0.06,0.18 0.82,0.82 0 0 1 0,0.36 l -0.06,0.18 -0.57,0.87 3.92,1.8 4.17,-1.92 v -3.54 h -1 -0.24 l -0.22,-0.07 -0.21,-0.1 -0.18,-0.12 -2,-2.22 m 5.92,2.54 v 3.63 l 4.08,1.88 4,-1.84 -0.64,-1 a 0.64,0.64 0 0 1 -0.06,-0.18 0.82,0.82 0 0 1 0,-0.36 1.21,1.21 0 0 1 0,-0.18 l 1.41,-2.23 c -0.35,-0.24 -0.72,-0.48 -1.1,-0.7 -0.38,-0.22 -0.78,-0.42 -1.19,-0.62 -0.41,-0.2 -0.84,-0.36 -1.27,-0.52 -0.43,-0.16 -0.88,-0.31 -1.34,-0.44 l -2,2.2 -0.23,0.12 -0.24,0.1 -0.23,0.07 h -0.24 -1 m 2.54,16.22 1.51,-0.88 -2.46,-2.51 h -5.26 l -2.46,2.51 1.51,0.88 a 1.74,1.74 0 0 1 0.2,0.13 1.83,1.83 0 0 1 0.13,0.16 1.34,1.34 0 0 1 0.07,0.18 1.1,1.1 0 0 1 0,0.18 v 2.17 l 0.77,0.11 c 0.26,0 0.52,0.06 0.79,0.09 h 0.8 0.8 0.81 0.8 l 0.78,-0.09 0.78,-0.11 v -2.17 a 1.1,1.1 0 0 1 0,-0.18 1.34,1.34 0 0 1 0.07,-0.18 1,1 0 0 1 0.14,-0.16 l 0.19,-0.13\" id=\"path1294\" style=\"fill:",
                footballColors[ballColor],
                ';fill-opacity:1" /><animateMotion path="',
                pathData,
                '"\n dur="',
                Strings.toString(dur / 10),
                ".",
                Strings.toString(dur % 10),
                's" begin="0s" repeatCount="indefinite" rotate="none" /></g>\n'
            ));
    }

    function renderImage(IDescriptor.CardInfo calldata card, uint256 tokenId) internal view returns (bytes memory){
        bytes memory image =
        abi.encodePacked(
            renderBg(1, 6, Tools.Random8Bits(card.seed, 1, bgColorIndexOfRarity[card.rarity][0], bgColorIndexOfRarity[card.rarity][1])), // background
            renderElement(2, card.nation), // flag
            renderWrapText(0, 0, Strings.toString(tokenId)), // tokenId Text
            renderWrapText(0, 1, rarityNames[card.rarity]), // Rarity name
            renderStars(card.rarity), // tokenId Text
            renderScoreBar(card.attack, 903, 101), renderWrapText(4, 0, Strings.toString(card.attack)),
            renderScoreBar(card.defensive, 953, 102), renderWrapText(4, 1, Strings.toString(card.defensive)),
            renderScoreBar(card.physical, 1003, 103), renderWrapText(4, 2, Strings.toString(card.physical)),
            renderScoreBar(card.tactical, 1053, 104), renderWrapText(4, 3, Strings.toString(card.tactical)),
            renderScoreBar(card.luck, 1103, 105), renderWrapText(4, 4, Strings.toString(card.luck)),
            renderElement(5, Tools.Random8Bits(card.seed, 7, 0, 7)),
            renderTeam(card),
            "</svg>"
        );
        return image;
    }

    function renderMeta(IDescriptor.CardInfo calldata card, uint256 tokenId) external view returns (string memory){
        bytes memory data;
        if (card.seed == 0) {
            string memory image = Base64.encode(abi.encodePacked(elementGroups[1][3]));
            data = bytes(
                abi.encodePacked(
                    '{"name":"', 'Nfinity #', Strings.toString(tokenId), '", ',
                    '"image": "', 'data:image/svg+xml;base64,', image,
                    '"}')
            );
        } else {
            string memory image = Base64.encode(renderImage(card, tokenId));
            string memory attributes = '[';
            attributes = string.concat(attributes, '{"trait_type": "Rank", "value": "', rarityNames[card.rarity], '"},');
            attributes = string.concat(attributes, '{"trait_type": "Nation", "value": "', elementGroups[7][card.nation], '"},');
            attributes = string.concat(attributes, '{"trait_type": "Attack", "value": ', Strings.toString(card.attack), '},');
            attributes = string.concat(attributes, '{"trait_type": "Defensive", "value": ', Strings.toString(card.defensive), '},');
            attributes = string.concat(attributes, '{"trait_type": "Physical", "value": ', Strings.toString(card.physical), '},');
            attributes = string.concat(attributes, '{"trait_type": "Tactical", "value": ', Strings.toString(card.tactical), '},');
            attributes = string.concat(attributes, '{"trait_type": "Luck", "value": ', Strings.toString(card.luck), '}');
            attributes = string.concat(attributes, ']');
            data = bytes(
                abi.encodePacked(
                    '{"name":"', 'Nfinity #', Strings.toString(tokenId), '", ',
                    '"attributes":', attributes, ', ',
                    '"image": "', 'data:image/svg+xml;base64,', image,
                    '"}')
            );

        }

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    data
                )));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/

pragma solidity ^0.8.17;

interface IDescriptor {
    struct CardInfo {
        uint seed;
        uint8 nation;
        uint8 rarity;        // [0, 4]
        uint8 attack;       // range
        uint8 defensive;    // range
        uint8 physical;     // range
        uint8 tactical;     // range
        uint8 luck;         // range
//        uint8 team1Max;
//        uint8 team2Max;
    }

    function renderMeta(CardInfo calldata card, uint256 tokenId) external pure returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/


pragma solidity ^0.8.17;

library Tools {
    function Random8Bits(uint256 seed, uint8 part, uint8 minInclusive, uint8 maxInclusive) internal pure returns (uint8) {
        return uint8((0xFF & (seed >> (part << 3))) * (maxInclusive - minInclusive + 1) / 0x100 + minInclusive);
    }

    function Random16Bits(uint256 seed, uint8 part, uint16 minInclusive, uint16 maxInclusive) internal pure returns (uint16) {
        return uint16((0xFFFF & (seed >> (part << 3))) * (maxInclusive - minInclusive + 1) / 0x10000 + minInclusive);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
             ░┴W░
             ▒m▓░
           ╔▄   "╕
         ╓▓╣██,   '
       ,▄█▄▒▓██▄    >
      é╣▒▒▀███▓██▄
     ▓▒▒▒▒▒▒███▓███         ███╗   ██╗███████╗████████╗    ██╗███╗   ██╗███████╗██╗███╗   ██╗██╗████████╗██╗   ██╗
  ,╢▓▀███▒▒▒██▓██████       ████╗  ██║██╔════╝╚══██╔══╝    ██║████╗  ██║██╔════╝██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
 @╢╢Ñ▒╢▒▀▀▓▓▓▓▓██▓████▄     ██╔██╗ ██║█████╗     ██║       ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║   ██║    ╚████╔╝
╙▓╢╢╢╢╣Ñ▒▒▒▒██▓███████▀▀    ██║╚██╗██║██╔══╝     ██║       ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║     ╚██╔╝
   "╩▓╢╢╢╣╣▒███████▀▀       ██║ ╚████║██║        ██║       ██║██║ ╚████║██║     ██║██║ ╚████║██║   ██║      ██║
      `╨▓╢╢╢████▀           ╚═╝  ╚═══╝╚═╝        ╚═╝       ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝
          ╙▓█▀

*/

pragma solidity ^0.8.17;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC721EnumerableSlim} from "./ERC721EnumerableSlim.sol";
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "./IDescriptor.sol";
import {Tools} from "./Tools.sol";

contract NfinityToken is ERC721EnumerableSlim, Ownable, ReentrancyGuard {
    uint256 constant DIVIDER = 1_000_000;
    uint256 public constant WINNER_GAP_SECONDS = 24 * 3600;
    uint256 constant MAX_REVEAL_COUNT = 3;

    IDescriptor public descriptor;
    address public gameContractAddress;

    // game configs
    uint256 public mintCostRate;
    uint256 public jackpotRate = 310_000;
    uint256 public gamepotRate = 0;
    uint256 public constant fomopotRate = 430_000;

    mapping(address => uint256) public otherPoolRate; // n/1000000, current rate

    // game status
    struct GameStatus {
        // The internal noun ID tracker
        uint32 lastMintNftId;
        uint32 lastMintTs;
        uint32 lastRevealedNftId;
        uint32 lastUnlockedNftId;
        uint128 currentPrice;
        uint128 fomoPer; // fomo per nft starts from 1 till the end, wei
    }

    GameStatus public gameStatus;

    // moneys
    uint256 public initPrice;
    uint256 public jackpotPoolSink; // jackpot pool (before jackpot rate changed)
    uint256 public gamepotPoolSink;
    uint256 public mintPool; // all income from mint
    uint256 public mintPoolSink; // jackpot + gamepot (sink by mint)

    // user status
    mapping(uint256 => uint256) public fomoExpired; // wei
    mapping(uint256 => uint256) public fomoClaimed; // wei
    mapping(address => uint256) public userClaimed; // wei
    mapping(uint256 => uint256) public jackpotClaimed; // wei
    uint256 public gamepotClaimed; // wei
    mapping(uint256 => uint256) public cardSeeds;

    uint[5] probabilities = [720_000, 880_000, 979_000, 999_000, 1_000_000];


    //    uint256 public py = 0;  // previous 100 time duration
    uint256 public yts = 0; // current 100 start timestamp

    event Claimed(uint256 indexed tokenId, address indexed claimer, uint256 amount);

    struct CardStats {
        uint256 claimableFomo;
        uint256 claimedFomo;
        uint256 tokenId;
        uint256 price;
        IDescriptor.CardInfo card;
    }

    struct UserStats {
        uint256 totalClaimableFomo;
        uint256 totalClaimedFomo;
        uint256 totalClaimableJackpot;
        uint256 totalClaimedJackpot;
        uint256 totalClaimableUser;
        uint256 totalClaimedUser;
    }

    constructor(IDescriptor _descriptor, uint128 _initPrice) ERC721('NfinityToken', 'NfinityToken') {
        descriptor = _descriptor;
        gameStatus.currentPrice = _initPrice;
        initPrice = _initPrice;
        mintCostRate = 1000200;
        otherPoolRate[address(0xc668023e7d0fb8cC28339011979d563AFAbd6630)] = 100000;
        otherPoolRate[address(0xB2F63f284515Aaf013d9CFa553cf32A314De13A6)] = 60000;
        otherPoolRate[address(0x2685E91A7e3D8336F5e3dD9e3C07F869fE350B9a)] = 100000;
    }

    function deposit() external payable {
        jackpotPoolSink += msg.value;
    }

    fallback() external payable {jackpotPoolSink += msg.value;}

    receive() external payable {jackpotPoolSink += msg.value;}

    function unchecked_inc(uint i) internal pure returns (uint) {
    unchecked {
        return i + 1;
    }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'non-exists token');
        IDescriptor.CardInfo memory card = getCardInfo(tokenId);
        return descriptor.renderMeta(card, tokenId);
    }

    function _publicMintable() internal view returns (bool){
        uint lastMintTs = gameStatus.lastMintTs;
        return lastMintTs > 0 && block.timestamp < lastMintTs + WINNER_GAP_SECONDS;
    }

    function publicMintable() external view returns (bool){
        return _publicMintable();
    }

    function winTs() external view returns (uint){
        return gameStatus.lastMintTs + WINNER_GAP_SECONDS;
    }

    function lastMintNftId() external view returns (uint){
        return gameStatus.lastMintNftId;
    }

    function currentPrice() external view returns (uint){
        return gameStatus.currentPrice;
    }

    function startMint() external onlyOwner payable {
        require(gameStatus.lastMintNftId == 0, "already started");
        return _mint(1);
    }

    function settleGame(address _gameContractAddress) external onlyOwner {
        gameContractAddress = _gameContractAddress;
        jackpotPoolSink += (mintPool - mintPoolSink) * jackpotRate / DIVIDER;
        gamepotPoolSink += (mintPool - mintPoolSink) * gamepotRate / DIVIDER;
        mintPoolSink = mintPool;
        if (gameContractAddress == address(0)) {
            jackpotRate = 300_000;
            gamepotRate = 0;
        } else {
            jackpotRate = 200_000;
            gamepotRate = 100_000;
        }
    }

    function revealCards(uint256 start, uint256 end) external onlyOwner {
        for (uint256 tokenId = start; tokenId <= end; tokenId = unchecked_inc(tokenId)) {
            cardSeeds[tokenId] = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tokenId)));
        }
        gameStatus.lastRevealedNftId = uint32(end);
        gameStatus.lastUnlockedNftId = uint32(end);
    }

    function revealPreviousCards(uint256 lastRevealedNftId, uint256 lastUnlockedNftId) internal returns (uint256 newLastRevealedNftId){

    unchecked{
        uint256 tokenId = lastRevealedNftId + 1;
        uint256 count = 0;
        while (tokenId <= lastUnlockedNftId) {
            cardSeeds[tokenId] = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, tokenId)));
            ++count;
            ++tokenId;
            if (count >= MAX_REVEAL_COUNT) {
                break;
            }
        }
        return tokenId - 1;
    }
    }

    function updateProbability() internal {
        if (yts != 0) {
            // starts from 5000
            uint y = block.timestamp - yts;
            if (y > 168 * 3600) {
                probabilities = [430_000, 730_000, 930_000, 990_000, 1000_000];
            } else if (y > 48 * 3600) {
                probabilities = [560_000, 800_000, 960_000, 995_000, 1000_000];
            } else if (y > 12 * 3600) {
                probabilities = [620_000, 840_000, 970_000, 997_000, 1000_000];
            } else {
                probabilities = [720_000, 880_000, 979_000, 999_000, 1000_000];
            }
        }

        yts = block.timestamp;
    }

    function getCardInfo(uint256 tokenId) public view returns (IDescriptor.CardInfo memory cardInfo){
        uint256 seed = cardSeeds[tokenId];
        uint cardClassSeed = ((seed >> (256 - 16)) & 0xFFFF) * DIVIDER / 0x10000;
        uint rarity;

        //  73  [40, 55, 75,]
        for (uint i = 0; i < 5; i = unchecked_inc(i)) {
            if (cardClassSeed <= probabilities[i]) {
                rarity = i;
                break;
            }
        }
        cardInfo.rarity = uint8(rarity);
        cardInfo.seed = seed;

        uint8 v1;
        uint8 v2;

        if (rarity == 0) {
            v1 = 10;
            v2 = 40;
        } else if (rarity == 1) {
            v1 = 20;
            v2 = 50;
        } else if (rarity == 2) {
            v1 = 40;
            v2 = 80;
        } else if (rarity == 3) {
            v1 = 60;
            v2 = 100;
        } else if (rarity == 4) {
            v1 = 90;
            v2 = 120;
        }

        cardInfo.nation = Tools.Random8Bits(seed, 0, 0, 31);
        cardInfo.attack = Tools.Random8Bits(seed, 2, v1, v2);
        cardInfo.defensive = Tools.Random8Bits(seed, 3, v1, v2);
        cardInfo.physical = Tools.Random8Bits(seed, 4, v1, v2);
        cardInfo.tactical = Tools.Random8Bits(seed, 5, v1, v2);
        cardInfo.luck = Tools.Random8Bits(seed, 6, v1, v2);
    }

    function _mint(uint256 mintCount) internal nonReentrant {
        require(tx.origin == msg.sender, "eoa");
        // fail fast if value not enough
        uint256 minPrice = _mintPrice(mintCount);
        require(msg.value >= minPrice, "pay it");

        GameStatus memory oldGameStatus = gameStatus;
        uint256 newLastMintNftId = oldGameStatus.lastMintNftId;
        uint256 newLastMintTs = oldGameStatus.lastMintTs;
        uint256 newLastRevealedNftId = oldGameStatus.lastRevealedNftId;
        uint256 newLastUnlockedNftId = oldGameStatus.lastUnlockedNftId;

        uint256 newCurrentPrice = oldGameStatus.currentPrice;
        uint256 newFomoPer = oldGameStatus.fomoPer;

        if (block.timestamp != newLastMintTs) {
            // advance unlocked block
            newLastUnlockedNftId = newLastMintNftId;
        }

        for (uint256 i = 0; i < mintCount; i = unchecked_inc(i)) {
            newLastMintNftId = unchecked_inc(newLastMintNftId);
            _safeMint(msg.sender, newLastMintNftId);
            if (newLastMintNftId % 100 == 0) {
                if (newLastMintNftId >= 5000) {
                    updateProbability();
                }
            }

            // reveal previous cards only after block + 1;
            // to prevent flashbots bundle attack (to some extent)
            if (newLastRevealedNftId < newLastUnlockedNftId) {
                newLastRevealedNftId = revealPreviousCards(newLastRevealedNftId, newLastUnlockedNftId);
            }

            if (newLastMintNftId > 1) {
                //  for token id = 2, per = 1
                newFomoPer += newCurrentPrice * fomopotRate / (newLastMintNftId - 1) / DIVIDER;
                fomoExpired[newLastMintNftId] = newFomoPer;
            }
            newCurrentPrice = newCurrentPrice * mintCostRate / DIVIDER;
        }

        oldGameStatus.lastMintNftId = uint32(newLastMintNftId);
        oldGameStatus.lastMintTs = uint32(block.timestamp);
        oldGameStatus.lastRevealedNftId = uint32(newLastRevealedNftId);
        oldGameStatus.lastUnlockedNftId = uint32(newLastUnlockedNftId);
        oldGameStatus.currentPrice = uint128(newCurrentPrice);
        oldGameStatus.fomoPer = uint128(newFomoPer);

        gameStatus = oldGameStatus;

        mintPool += minPrice;

        // change
        payable(msg.sender).transfer(msg.value - minPrice);
    }

    function mint(uint256 mintCount) public payable {
        require(_publicMintable(), "cannot mint");
        require(mintCount != 0, "bad mint");
        require(mintCount <= 10, "too much");
        return _mint(mintCount);
    }

    function _mintPrice(uint256 mintCount) internal view returns (uint256 price){
        uint256 nextPrice = gameStatus.currentPrice;
        for (uint256 i = 0; i < mintCount; i = unchecked_inc(i)) {
            price += nextPrice;
            nextPrice = nextPrice * mintCostRate / DIVIDER;
        }
    }

    function mintPrice(uint256 mintCount) external view returns (uint256 price){
        return _mintPrice(mintCount);
    }

    function setMintCostRate(uint256 rate) external onlyOwner {
        mintCostRate = rate;
    }

    function setDescriptor(address _descriptor) external onlyOwner {
        descriptor = IDescriptor(_descriptor);
    }

    function jackpot() public view returns (uint256 value){
        return jackpotPoolSink + (mintPool - mintPoolSink) * jackpotRate / DIVIDER;
    }

    function claimNftProfit(uint256 tokenId) public nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "not owned");
        uint256 jackpotProfit = claimableJackpotProfit(tokenId);
        uint256 fomoProfit = claimableFomoProfit(tokenId);

        fomoClaimed[tokenId] += fomoProfit;
        jackpotClaimed[tokenId] += jackpotProfit;
        payable(msg.sender).transfer(fomoProfit + jackpotProfit);
        emit Claimed(tokenId, msg.sender, fomoProfit + jackpotProfit);
    }

    function claimNftProfitBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i = unchecked_inc(i)) {
            claimNftProfit(tokenIds[i]);
        }
    }

    function claimUserProfit() external nonReentrant {
        uint256 distributeValue = claimableUserProfit(msg.sender);
        userClaimed[msg.sender] += distributeValue;
        payable(msg.sender).transfer(distributeValue);
        emit Claimed(0, msg.sender, distributeValue);
    }

    function claimGameProfit() external nonReentrant {
        require(msg.sender == gameContractAddress, "not game");
        uint256 distributeValue = gamepotPoolSink + (mintPool - mintPoolSink) * gamepotRate / DIVIDER - gamepotClaimed;
        gamepotClaimed += distributeValue;
        payable(msg.sender).transfer(distributeValue);
        emit Claimed(0, msg.sender, distributeValue);
    }

    function claimableUserProfit(address user) public view returns (uint256 distributeValue){
        distributeValue = otherPoolRate[user] * mintPool / DIVIDER;
        // otherPool
        distributeValue -= userClaimed[user];
    }

    function claimableJackpotProfit(uint256 tokenId) public view returns (uint256 distributeValue){
        distributeValue = 0;
        uint _lastMintNftId = gameStatus.lastMintNftId;
        uint lastMintTs = gameStatus.lastMintTs;

        if (lastMintTs != 0 && block.timestamp >= lastMintTs + WINNER_GAP_SECONDS && _lastMintNftId == tokenId) {
            distributeValue += jackpot();
        }
        // do not count the profit user already claimed
        distributeValue -= jackpotClaimed[tokenId];
    }

    function claimableFomoProfit(uint256 tokenId) public view returns (uint256 distributeValue){
        // fomo
        distributeValue = gameStatus.fomoPer;
        // do not count the profit before user in
        distributeValue -= fomoExpired[tokenId];
        // do not count the profit user already claimed
        distributeValue -= fomoClaimed[tokenId];
    }

    function historyMintPrice(uint256 tokenId) public view returns (uint256 price){
        uint _lastMintNftId = gameStatus.lastMintNftId;
        require(tokenId <= _lastMintNftId, "future id");
        if (tokenId == 1) {
            return initPrice;
        }
        return (fomoExpired[tokenId] - fomoExpired[tokenId - 1]) * (tokenId - 1) * DIVIDER / fomopotRate;
    }

    function cardStats(uint256 tokenId) public view returns (CardStats memory stats){
        stats = CardStats({
        claimableFomo : claimableFomoProfit(tokenId),
        claimedFomo : fomoClaimed[tokenId],
        tokenId : tokenId,
        price : historyMintPrice(tokenId),
        card : getCardInfo(tokenId)
        });
    }

    function batchCardStats(address user, uint256 offset, uint256 limit) external view returns (CardStats[] memory stats){
        uint256 balance = balanceOf(user);
        uint256 right = balance;
        if (offset + limit < right) {
            right = offset + limit;
        }
        stats = new CardStats[](right - offset);
        for (uint256 i = offset; i < right; i = unchecked_inc(i)) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            stats[i - offset] = cardStats(tokenId);
        }
    }

    function userStats(address user) external view returns (UserStats memory stats){
        uint256 totalClaimableFomo;
        uint256 totalClaimedFomo;
        uint256 totalClaimableJackpot;
        uint256 totalClaimedJackpot;
        uint256 totalClaimableUser;
        uint256 totalClaimedUser;
        uint256 balance = balanceOf(user);

        for (uint256 i = 0; i < balance; i = unchecked_inc(i)) {
            uint256 tokenId = tokenOfOwnerByIndex(user, i);
            totalClaimableFomo += claimableFomoProfit(tokenId);
            totalClaimedFomo += fomoClaimed[tokenId];
            totalClaimableJackpot += claimableJackpotProfit(tokenId);
            totalClaimedJackpot += jackpotClaimed[tokenId];
        }
        totalClaimableUser = claimableUserProfit(user);
        totalClaimedUser = userClaimed[user];

        stats = UserStats({
        totalClaimableFomo : totalClaimableFomo,
        totalClaimedFomo : totalClaimedFomo,
        totalClaimableJackpot : totalClaimableJackpot,
        totalClaimedJackpot : totalClaimedJackpot,
        totalClaimableUser : totalClaimableUser,
        totalClaimedUser : totalClaimedUser
        });
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableSlim is ERC721 {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256 private _totalSupply = 0;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _totalSupply++;
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _totalSupply--;
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

interface INfinityToken {
    function mint(uint256 mintCount) external payable;
}

contract Exploit is IERC721Receiver {
    INfinityToken c;

    constructor(address t){
        console.log("constructor");
        c = INfinityToken(t);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {
        console.log(gasleft());
        console.log("receive", msg.value);
        c.mint{value : msg.value}(1);
    }

    //    fallback() external payable {
    //        //        for (uint256 i = 0; i < 100; i ++) {
    //        //            console.log("payable1111", msg.value);
    //        //        }
    //
    //        c.mint{value : msg.value}(1);
    //    }

    function p1() internal {
        console.log("internal");
        console.log(msg.value);
    }

    function p2() public payable {
        console.log("public");
        console.log(msg.value);
    }

    function execute() external payable {
        //        console.log("execute");
        //        p1();
        //        p2();
        c.mint{value : msg.value}(1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}