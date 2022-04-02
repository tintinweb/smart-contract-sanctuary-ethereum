// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

library Board {
    string constant svg1 =
        "<?xml version='1.0' encoding='utf-8'?><svg version='1.1' width='600' height='600' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 600 600'><style>.xo{font: normal 123px Andale Mono,monospace;fill:";
    string constant svg2 = "}.bg{fill:";
    string constant svg3 = ";stroke:";
    string constant svg4 = ";stroke-width:20px;}.hash{stroke:";
    string constant svg5 = "}@keyframes pulse{from{stroke:";
    string constant svg6 = ";}to{stroke:";
    string constant svg7 =
        ";}}.xoline{stroke-width:10;animation-iteration-count:infinite;animation-direction:alternate;animation-name:pulse;animation-duration:1s;animation-timing-function:ease-in;}</style><defs><filter id='f1' x='0' y='0' width='200%' height='200%'><feOffset result='offOut' in='SourceAlpha' dx='15' dy='15'/><feBlend in='SourceGraphic' in2='offOut' mode='normal'/></filter><g id='o'><rect class='xo' width='200' height='200' /><circle class='xoline' cx='98' cy='98' stroke='white' fill='transparent' stroke-width='4' r='90'/></g><g id='x'><rect class='xo' width='200' height='200'/><path class='xoline' d='M 0 0 L 200 200 M 200 0 L 0 200' stroke='white' stroke-width='4'/></g></defs><rect width='100%' height='100%' class='bg'/>";
    string constant svg8 =
        "<path d='M 0 200 H 600 M 00 400 H 600 M 200 0 V 600 M 400 00 V 600' stroke-width='10' stroke-linejoin='round' class='hash'></path></svg>";

    uint256 constant maxLum = 98;
    uint256 constant maxLevel = 5;

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

    function tokenIdToColors(uint256 tokenId)
        internal
        pure
        returns (uint256[3] memory)
    {
        uint256 index = (tokenId - 1) / 10;
        require(index <= 6, "Invalid token id");
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

    function getXOs(uint256 stateX, uint256 stateO)
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

    function getGameComponents(uint256 stateX, uint256 stateO)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory xos = getXOs(stateX, stateO);

        return abi.encodePacked(svg7, xos, svg8);
    }

    function getBoardColors(uint256 tokenId, uint256 level)
        internal
        pure
        returns (
            bytes memory boardStroke,
            bytes memory boardBg,
            bytes memory xoStrokeFrom,
            bytes memory xoStrokeTo,
            bytes memory xoBg
        )
    {
        uint256[3] memory color = tokenIdToColors(tokenId);
        string memory hueStr = uint2str(color[0]);
        string memory satStr = uint2str(color[1]);
        string memory lumStr = uint2str(color[2]);
        uint256 startingLum = color[2];
        uint256 window = maxLum - startingLum;

        string memory lumAltStr = uint2str(
            startingLum + ((window / maxLevel) * (maxLevel - level + 1))
        );

        if (level < maxLevel) {
            boardStroke = abi.encodePacked(
                "hsl(",
                hueStr,
                ",",
                satStr,
                "%,",
                lumStr,
                "%)"
            );
            xoBg = abi.encodePacked(
                "hsl(",
                hueStr,
                ",",
                satStr,
                "%,",
                uint2str(startingLum + 8),
                "%)"
            );
        } else {
            boardStroke = abi.encodePacked(
                "hsl(",
                hueStr,
                ",",
                satStr,
                "%,90%)"
            );
            xoBg = abi.encodePacked("hsl(", hueStr, ",", satStr, "%,98%)");
        }

        boardBg = abi.encodePacked(
            "hsl(",
            hueStr,
            ",",
            satStr,
            "%,",
            lumAltStr,
            "%)"
        );

        xoStrokeFrom = abi.encodePacked(
            "hsl(",
            hueStr,
            ",",
            satStr,
            "%,",
            satStr,
            "%)"
        );

        xoStrokeTo = abi.encodePacked(
            "hsl(",
            hueStr,
            ",",
            satStr,
            "%,",
            uint2str(maxLum),
            "%)"
        );
    }

    function getLayout(uint256 tokenId, uint256 level)
        internal
        pure
        returns (bytes memory)
    {
        (
            bytes memory boardStroke,
            bytes memory boardBg,
            bytes memory xoStrokeFrom,
            bytes memory xoStrokeTo,
            bytes memory xoBg
        ) = getBoardColors(tokenId, level);

        return
            abi.encodePacked(
                svg1,
                xoBg,
                svg2,
                boardBg,
                svg3,
                boardStroke,
                svg4,
                boardStroke,
                svg5,
                xoStrokeFrom,
                svg6,
                xoStrokeTo
            );
    }

    function buildBoard(
        uint256 tokenId,
        uint256 stateX,
        uint256 stateO,
        uint256 level
    ) public pure returns (bytes memory) {
        if (level > maxLevel) {
            level = maxLevel;
        }

        return
            abi.encodePacked(
                getLayout(tokenId, level),
                getGameComponents(stateX, stateO)
            );
    }
}