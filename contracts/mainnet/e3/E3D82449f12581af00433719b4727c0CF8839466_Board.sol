// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./ITTT.sol";

contract Board {
    string constant svg0 =
        "<svg version='1.1' width='600' height='600' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 600 600'> <style> .xo { font: normal 123px Andale Mono, monospace; fill: ";
    string constant svg1 = "; } .bg { fill: ";
    string constant svg2 = "; } .fg { stroke: ";
    string constant svg3 = "; } @keyframes pulse { from { stroke: ";
    string constant svg4 = "; } to { stroke: ";
    string constant svg5 =
        "; } } .xoline { stroke-width: 10; animation-iteration-count: infinite; animation-direction: alternate; animation-name: pulse; animation-duration: 1s; animation-timing-function: ease-in; } .tieStroke { stroke: ";
    string constant svg6 =
        "; } </style> <defs> <filter id='f1' x='0' y='0' width='200%' height='200%'> <feOffset result='offOut' in='SourceAlpha' dx='15' dy='15' /> <feBlend in='SourceGraphic' in2='offOut' mode='normal' /> </filter> <g id='o'> <rect class='xo' width='200' height='200' /> <circle class='xoline' cx='98' cy='98' stroke='white' fill='transparent' stroke-width='4' r='90' /> </g> <g id='x'> <rect class='xo' width='200' height='200' /> <path class='xoline' d='M 0 0 L 200 200 M 200 0 L 0 200' stroke='white' stroke-width='4' /> </g> <filter id='glow' x='-10%' y='-50%' with='200%' height='200%'> <feGaussianBlur in='SourceGraphic' stdDeviation='5'> <animate attributeName='stdDeviation' from='0' to='10' dur='2s' repeatCount='indefinite' values='1; 10; 5; 1;' /> </feGaussianBlur> </filter> </defs> <rect width='100%' height='100%' class='bg fg' stroke-width='20'> <animate id='strobo' attributeName='";
    string constant svg7 = "' values='";
    string constant svg8 = "; hsl(";
    string constant svg9 = ", 100%, 100%); hsl(";
    string constant svg10 =
        ", 100%, 0%);' dur='200ms' repeatCount='indefinite'/> <animate id='psychedelic' attributeName='";
    string constant svg11 =
        "' values='#B500D1;#4500AD;#00BFE6;#008F07;#FFD900;#FF8C00;#F50010;#B500D1;' dur='1s' repeatCount='indefinite'/> </rect> ";
    string constant svg12 = " <path visibility='";
    string constant svg13 =
        "' d='M 0 200 H 600 M 00 400 H 600 M 200 0 V 600 M 400 00 V 600' stroke-width='10' stroke-linejoin='round' class='fg' /> <g visibility='";
    string constant svg14 =
        "' class='rainbowTie'> <rect y='-600' height='86' fill='#B500D1' width='600'/> <rect y='-516' height='86' fill='#4500AD' width='600'/> <rect y='-430' height='86' fill='#00BFE6' width='600'/> <rect y='-344' height='86' fill='#008F07' width='600'/> <rect y='-258' height='86' fill='#FFD900' width='600'/> <rect y='-172' height='86' fill='#FF8C00' width='600'/> <rect y='-86' height='86' fill='#F50010' width='600'/> <rect y='0' height='86' fill='#B500D1' width='600'/> <rect y='86' height='86' fill='#4500AD' width='600'/> <rect y='172' height='86' fill='#00BFE6' width='600'/> <rect y='258' height='86' fill='#008F07' width='600'/> <rect y='344' height='86' fill='#FFD900' width='600'/> <rect y='430' height='86' fill='#FF8C00' width='600'/> <rect y='516' height='86' fill='#F50010' width='600'/> <animateTransform attributeName='transform' attributeType='XML' type='translate' from='0 0' to='0 600' dur='5s' repeatCount='indefinite'/> </g> <g id='tie' visibility='";
    string constant svg15 =
        "'> <mask id='tieMask'> <path d='M 280 80 L 250 480 L 300 530 L 350 480 L 320 80 L 325 60 L 300 50 L 275 60 L 280 80 L 320 80' fill='white' stroke-linejoin='round' /> </mask> <path d='M 280 80 L 250 480 L 300 530 L 350 480 L 320 80 L 325 60 L 300 50 L 275 60 L 280 80 L 320 80' stroke-linejoin='round' class='bg' /> <path visibility='";
    string constant svg16 =
        "' d='M 280 80 L 250 480 L 300 530 L 350 480 L 320 80 L 325 60 L 300 50 L 275 60 L 280 80 L 320 80' stroke-linejoin='round' stroke-width='10' filter='url(#glow)' class='tieStroke' /> <g mask='url(#tieMask)'> <rect x='250' y='100' height='15' fill='#B500D1' width='200' transform='rotate(20)' /> <rect x='250' y='115' height='15' fill='#4500AD' width='200' transform='rotate(20)' /> <rect x='250' y='130' height='15' fill='#00BFE6' width='200' transform='rotate(20)' /> <rect x='250' y='145' height='15' fill='#008F07' width='200' transform='rotate(20)' /> <rect x='250' y='160' height='15' fill='#FFD900' width='200' transform='rotate(20)' /> <rect x='250' y='175' height='15' fill='#FF8C00' width='200' transform='rotate(20)' /> <rect x='250' y='190' height='15' fill='#F50010' width='200' transform='rotate(20)' /> </g> <path d='M 280 80 L 250 480 L 300 530 L 350 480 L 320 80 L 325 60 L 300 50 L 275 60 L 280 80 L 320 80' fill='transparent' stroke-width='10' stroke-linejoin='round' class='tieStroke'> <animate id='strobo-tie' attributeName='";
    string constant svg17 = "' values='";
    string constant svg18 = "; hsl(";
    string constant svg19 = ", 100%, 100%); hsl(";
    string constant svg20 =
        ", 100%, 0%);' dur='200ms' repeatCount='indefinite'/> </path> </g> </svg>";

    string[70] flags = [
        unicode"🇩🇪",
        unicode"🇮🇹",
        unicode"🇯🇵",
        unicode"🇧🇬",
        unicode"🇭🇺",
        unicode"🇷🇴",
        unicode"🇸🇰",
        unicode"🇦🇹",
        unicode"🇪🇹",
        unicode"🇨🇳",
        unicode"🇦🇺",
        unicode"🇧🇷",
        unicode"🇨🇦",
        unicode"🇳🇿",
        unicode"🇿🇦",
        unicode"🇷🇺",
        unicode"🇬🇧",
        unicode"🇺🇸",
        unicode"🇦🇷",
        unicode"🇧🇴",
        unicode"🇨🇱",
        unicode"🇨🇴",
        unicode"🇨🇷",
        unicode"🇨🇺",
        unicode"🇩🇴",
        unicode"🇪🇨",
        unicode"🇪🇬",
        unicode"🇸🇻",
        unicode"🇬🇹",
        unicode"🇭🇹",
        unicode"🇭🇳",
        unicode"🇮🇶",
        unicode"🇱🇧",
        unicode"🇱🇷",
        unicode"🇲🇽",
        unicode"🇲🇳",
        unicode"🇳🇮",
        unicode"🇵🇦",
        unicode"🇵🇾",
        unicode"🇵🇪",
        unicode"🇸🇦",
        unicode"🇹🇷",
        unicode"🇺🇾",
        unicode"🇻🇪",
        unicode"🇩🇿",
        unicode"🇦🇱",
        unicode"🇧🇪",
        unicode"🇲🇲",
        unicode"🇨🇿",
        unicode"🇩🇰",
        unicode"🇪🇪",
        unicode"🇫🇮",
        unicode"🇫🇷",
        unicode"🇬🇷",
        unicode"🇮🇸",
        unicode"🇮🇳",
        unicode"🇮🇷",
        unicode"🇱🇻",
        unicode"🇱🇹",
        unicode"🇱🇺",
        unicode"🇲🇦",
        unicode"🇳🇱",
        unicode"🇵🇬",
        unicode"🇳🇴",
        unicode"🇵🇭",
        unicode"🇵🇱",
        unicode"🇸🇬",
        unicode"🇸🇾",
        unicode"🇹🇭",
        unicode"🇹🇳"
    ];

    string[70] countries = [
        "Germany",
        "Italy",
        "Japan ",
        "Bulgaria",
        "Hungary",
        "Romania",
        "Slovakia",
        "Austria",
        "Ethiopia",
        "China",
        "Australia",
        "Brazil",
        "Canada",
        "New Zealand",
        "South Africa",
        "Russia",
        "United Kingdom",
        "United States",
        "Argentina",
        "Bolivia",
        "Chile",
        "Colombia",
        "Costa Rica",
        "Cuba",
        "Dominican Republic",
        "Ecuador",
        "Egypt",
        "El Salvador",
        "Guatemala",
        "Haiti",
        "Honduras",
        "Iraq",
        "Lebanon",
        "Liberia",
        "Mexico",
        "Mongolia",
        "Nicaragua",
        "Panama",
        "Paraguay",
        "Peru",
        "Saudi Arabia",
        "Turkey",
        "Uruguay",
        "Venezuela",
        "Algeria",
        "Albania",
        "Belgium",
        "Burma",
        "Czech Republic",
        "Denmark",
        "Estonia",
        "Finland",
        "France",
        "Greece",
        "Iceland",
        "India",
        "Iran",
        "Latvia",
        "Lithuania",
        "Luxembourg",
        "Morocco",
        "The Netherlands",
        "New Guinea",
        "Norway",
        "Philippines",
        "Poland",
        "Singapore",
        "Syria",
        "Thailand",
        "Tunisia"
    ];

    uint256 constant maxLum = 98;
    uint256 constant maxLevel = 5;

    uint256 constant base = 350;
    uint256 constant psychedelic = 49;
    uint256 constant strobo = 7;
    uint256 constant neon = 7;
    uint256 constant prison = 6;
    uint256 constant peace = 1;

    uint256 constant baseLastId = base;
    uint256 constant psychedelicLastId = base + psychedelic;
    uint256 constant stroboLastId = psychedelicLastId + strobo;
    uint256 constant neonLastId = stroboLastId + neon;
    uint256 constant prisonLastId = neonLastId + prison;
    uint256 constant peaceLastId = prisonLastId + peace;

    function svgComponents() internal pure returns (string[21] memory) {
        return [
            svg0,
            svg1,
            svg2,
            svg3,
            svg4,
            svg5,
            svg6,
            svg7,
            svg8,
            svg9,
            svg10,
            svg11,
            svg12,
            svg13,
            svg14,
            svg15,
            svg16,
            svg17,
            svg18,
            svg19,
            svg20
        ];
    }

    function createSvg(bytes[16] memory overrideValues)
        internal
        pure
        returns (bytes memory)
    {
        bytes[16] memory defaultValues = [
            bytes("transparent"),
            "transparent",
            "transparent",
            "transparent",
            "transparent",
            "transparent",
            "",
            "transparent",
            "0",
            "0",
            "",
            "",
            "",
            "hidden",
            "",
            "hidden"
        ];

        string[21] memory allSvgs = svgComponents();
        bytes memory finalSvg;

        for (uint256 i = 0; i < 16; i++) {
            if (overrideValues[i].length > 0) {
                defaultValues[i] = overrideValues[i];
            }
            finalSvg = abi.encodePacked(finalSvg, allSvgs[i], defaultValues[i]);
        }

        return
            abi.encodePacked(
                finalSvg,
                allSvgs[16],
                defaultValues[6],
                allSvgs[17],
                defaultValues[7],
                allSvgs[18],
                defaultValues[8],
                allSvgs[19],
                defaultValues[9],
                allSvgs[20]
            );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function colorAtIndex(uint256 index)
        internal
        pure
        returns (uint256[3] memory)
    {
        if (index == 0) {
            return [uint256(292), 100, 41];
        } else if (index == 1) {
            return [uint256(264), 100, 34];
        } else if (index == 2) {
            return [uint256(190), 100, 45];
        } else if (index == 3) {
            return [uint256(123), 100, 28];
        } else if (index == 4) {
            return [uint256(51), 100, 50];
        } else if (index == 5) {
            return [uint256(33), 100, 50];
        } else {
            return [uint256(356), 100, 48];
        }
    }

    function getBaseTie(uint256 tieId) internal pure returns (bytes memory) {
        uint256 colorIndex = tieId / 50;
        uint256 level = (tieId % 50) / 10;
        if (level >= 4) {
            level = 5;
        }
        uint256 tieStrokeIndex = (tieId % 10) / 2; // the nth complementari from background color
        (
            uint256[3] memory boardStroke,
            uint256[3] memory boardBg,
            ,
            ,

        ) = getBoardColors(colorIndex, level);

        uint256 tieLum = tieId % 2 == 0 ? boardStroke[2] + 10 : boardBg[2] - 10;
        uint256 tieHue = boardBg[0] +
            (((tieStrokeIndex + 1) * (360 / 6)) % 360);
        uint256[3] memory tieStroke = [tieHue, boardBg[1], tieLum];

        bytes[16] memory components;
        components[1] = colorToHsl(boardBg);
        components[2] = abi.encodePacked(
            "hsla(",
            uint2str(boardStroke[0]),
            ",",
            uint2str(boardStroke[1]),
            "%,",
            uint2str(boardStroke[2]),
            "%,0.2)"
        );
        components[5] = colorToHsl(tieStroke);

        return createSvg(components);
    }

    function getPsychedelicTie(uint256 tieId)
        internal
        pure
        returns (bytes memory)
    {
        uint256 strokeIndex = (tieId - baseLastId) / 7;
        uint256 bgIndex = (tieId - baseLastId) % 7;

        bytes[16] memory components;
        components[2] = colorToHsl(colorAtIndex(strokeIndex));
        components[5] = components[2];
        components[1] = colorToHsl(colorAtIndex(bgIndex));
        components[10] = bytes("fill");
        components[12] = bytes("hidden");

        return createSvg(components);
    }

    function getStroboTie(uint256 tieId) internal pure returns (bytes memory) {
        uint256[3] memory color = colorAtIndex(tieId - psychedelicLastId);

        bytes[16] memory components;
        components[1] = bytes("black");
        components[2] = colorToHsl(color);
        components[6] = bytes("stroke");
        components[7] = components[2];
        components[8] = bytes(uint2str(color[0]));
        components[9] = components[8];
        components[12] = bytes("hidden");

        return createSvg(components);
    }

    function getNeonTie(uint256 tieId) internal pure returns (bytes memory) {
        uint256[3] memory color = colorAtIndex(tieId - stroboLastId);

        bytes[16] memory components;
        components[1] = bytes("black");
        components[5] = colorToHsl(color);
        components[15] = bytes("visible");
        components[12] = bytes("hidden");

        return createSvg(components);
    }

    function getPrison(uint256 tieId) internal pure returns (bytes memory) {
        uint256 index = tieId - neonLastId;
        uint256[6] memory prisonBgs = [uint256(90), 90, 60, 60, 40, 50];
        uint256[6] memory prisonFgs = [uint256(20), 60, 40, 20, 10, 20];

        bytes[16] memory components;
        components[1] = colorToHsl([0, 0, prisonBgs[index]]);
        components[2] = colorToHsl([0, 0, prisonFgs[index]]);
        components[5] = components[2];

        return createSvg(components);
    }

    function getPeaceTie() internal pure returns (bytes memory) {
        bytes[16] memory components;
        components[5] = bytes("black");
        components[1] = bytes("white");
        components[13] = bytes("visible");

        return createSvg(components);
    }

    function getPositionSVG(
        bool isPlayerX,
        uint256 x,
        uint256 y
    ) internal pure returns (bytes memory) {
        string[3] memory positions = ["0", "200", "400"];
        string memory xPosition = positions[x];
        string memory yPosition = positions[y];
        string memory player = isPlayerX ? "x" : "o";

        return
            abi.encodePacked(
                "<use href='#",
                player,
                "' x='",
                xPosition,
                "' y='",
                yPosition,
                "' />"
            );
    }

    function getGameComponents(uint256 stateX, uint256 stateO)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory xos;

        for (uint256 i = 0; i < 9; i++) {
            if (stateX & (1 << i) > 0) {
                xos = abi.encodePacked(xos, getPositionSVG(true, i / 3, i % 3));
            } else if (stateO & (1 << i) > 0) {
                xos = abi.encodePacked(
                    xos,
                    getPositionSVG(false, i / 3, i % 3)
                );
            }
        }

        return xos;
    }

    function getBoardColors(uint256 colorIndex, uint256 level)
        internal
        pure
        returns (
            uint256[3] memory boardStroke,
            uint256[3] memory boardBg,
            uint256[3] memory xoStrokeFrom,
            uint256[3] memory xoStrokeTo,
            uint256[3] memory xoBg
        )
    {
        uint256[3] memory color = colorAtIndex(colorIndex);
        uint256 startingLum = color[2];
        uint256 window = maxLum - startingLum;

        uint256 lumAlt;
        if (level == 0) {
            lumAlt = maxLum;
        } else {
            lumAlt = startingLum + ((window / maxLevel) * (maxLevel - level));
        }

        if (level < maxLevel) {
            boardStroke = [color[0], color[1], color[2]];
            xoBg = [color[0], color[1], startingLum + 8];
        } else {
            boardStroke = [color[0], color[1], 90];
            xoBg = [color[0], color[1], 98];
        }

        boardBg = [color[0], color[1], lumAlt];
        xoStrokeFrom = [color[0], color[1], color[2]];

        xoStrokeTo = [color[0], color[1], maxLum];
    }

    function colorToHsl(uint256[3] memory color)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "hsl(",
                uint2str(color[0]),
                ",",
                uint2str(color[1]),
                "%,",
                uint2str(color[2]),
                "%)"
            );
    }

    function _buildBoard(
        uint256 tokenId,
        uint256 stateX,
        uint256 stateO,
        uint256 level
    ) internal pure returns (bytes memory) {
        if (level > maxLevel) {
            level = maxLevel;
        }

        uint256 colorIndex = (tokenId - 1) / 10;
        require(colorIndex <= 6, "Invalid token id");

        (
            uint256[3] memory boardStroke,
            uint256[3] memory boardBg,
            uint256[3] memory xoStrokeFrom,
            uint256[3] memory xoStrokeTo,
            uint256[3] memory xoBg
        ) = getBoardColors(colorIndex, level);

        bytes[16] memory components;
        components[0] = colorToHsl(xoBg);
        components[1] = colorToHsl(boardBg);
        components[2] = colorToHsl(boardStroke);
        components[3] = colorToHsl(xoStrokeFrom);
        components[4] = colorToHsl(xoStrokeTo);
        components[11] = getGameComponents(stateX, stateO);
        components[14] = bytes("hidden");
        return createSvg(components);
    }

    function getTie(uint256 tieId) external pure returns (string memory json) {
        bytes memory svg;
        string memory traitType;
        uint256 realTieId = tieId - 500;
        if (realTieId < baseLastId) {
            svg = getBaseTie(realTieId);
            traitType = "base";
        } else if (realTieId < psychedelicLastId) {
            svg = getPsychedelicTie(realTieId);
            traitType = "psychedelic";
        } else if (realTieId < stroboLastId) {
            svg = getStroboTie(realTieId);
            traitType = "strobo";
        } else if (realTieId < neonLastId) {
            svg = getNeonTie(realTieId);
            traitType = "neon";
        } else if (realTieId < prisonLastId) {
            svg = getPrison(realTieId);
            traitType = "prison";
        } else if (realTieId < peaceLastId) {
            svg = getPeaceTie();
            traitType = "peace";
        }

        json = string(
            abi.encodePacked(
                'data:text/plain,{"name":"Tie #',
                uint2str(realTieId + 1),
                '","description":"A ',
                traitType,
                ' Tie!","attributes":[{"trait_type":"Type","value":"',
                traitType,
                '"}], "created_by":"@the_innerspace","image":"',
                svg,
                '"}'
            )
        );
    }

    function getBoard(uint256 tokenId, address tttAddress)
        external
        view
        returns (string memory)
    {
        ITTT ttt = ITTT(tttAddress);
        uint256 opponentBoardId = ttt.getOpponent(tokenId);

        uint256 xBoard;
        uint256 oBoard;
        string memory status = opponentBoardId > 0 ? "Playing" : "Not playing";
        string memory opponent = opponentBoardId > 0
            ? flags[opponentBoardId - 1]
            : "None";
        uint256 level = ttt.victories(tokenId);
        uint256 shade = level < maxLevel ? level : maxLevel;

        if (tokenId < opponentBoardId) {
            xBoard = ttt.boardState(tokenId);
            oBoard = ttt.boardState(opponentBoardId);
        } else {
            xBoard = ttt.boardState(opponentBoardId);
            oBoard = ttt.boardState(tokenId);
        }

        bytes memory image = _buildBoard(tokenId, xBoard, oBoard, shade);
        bytes memory json = abi.encodePacked(
            '{"name":"',
            countries[tokenId - 1],
            " ",
            flags[tokenId - 1],
            '","description":"","created_by":"@the_innerspace","attributes":[{"trait_type":"Level","value":',
            uint2str(level),
            '},{"trait_type": "State","value":"',
            status,
            '"},{"trait_type": "Opponent","value":"',
            opponent,
            '"}],',
            '"image":"',
            image,
            '"}'
        );

        return string(abi.encodePacked("data:text/plain,", json));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ITTT {
    function boardState(uint256 boardIndex) external view returns (uint256);

    function getOpponent(uint256 boardIndex) external view returns (uint256);

    function victories(uint256 boardIndex) external view returns (uint256);
}