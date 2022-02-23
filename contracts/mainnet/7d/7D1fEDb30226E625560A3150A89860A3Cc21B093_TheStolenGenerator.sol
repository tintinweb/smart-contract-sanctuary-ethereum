/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library UInt256Extensions {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

    uint32 internal constant day = 86400;
    uint16 internal constant hour = 3600;
    uint8 internal constant minute = 60;

    function secondsCutDays(uint256 secondTime)
    internal
    pure
    returns (uint256)
    {
        return secondTime / day;
    }

    function secondsToDayTimeUints(uint256 secondTime)
    internal
    pure
    returns (
        uint256 d,
        uint256 h,
        uint256 m,
        uint256 s
    )
    {
        d = secondTime / day;
        h = (secondTime - d * day) / hour;
        m = (secondTime - d * day - h * hour) / minute;
        s = secondTime - d * day - h * hour - m * minute;
    }

    function secondsToDayTimeString(uint256 secondTime)
    internal
    pure
    returns (string memory)
    {
        uint256 d = secondTime / day;
        uint256 h = (secondTime - d * day) / hour;
        uint256 m = (secondTime - d * day - h * hour) / minute;
        uint256 s = secondTime - d * day - h * hour - m * minute;

        return
        string(
            abi.encodePacked(
                UInt256Extensions.toString(d),
                "D ",
                UInt256Extensions.toString(h),
                "H ",
                UInt256Extensions.toString(m),
                "M ",
                UInt256Extensions.toString(s),
                "S"
            )
        );
    }
}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}



contract TheStolenGenerator{
    using UInt256Extensions for uint;


    address internal _thestolen;

    struct FactionImage{
        bool fillFaction;
        bool fillOwner;
        bool fillHighscore;
        uint16 member;
        string factionName;
        address owner;
        uint256 highscore;
        uint256 factionSteals;
        uint256 steals;
        uint256 current;
    }

    string constant colorActive = "cb0429";
    string constant colorNormal = "000000";

    string constant _imageStart = "<svg style=\'fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round;\' version=\'1.1\' viewBox=\'0 0 2000 2000\' xml:space=\'preserve\' xmlns=\'http://www.w3.org/2000/svg\' >";
    string constant _fonts = " <defs><linearGradient gradientTransform=\'matrix(1 0 0 1 65 -70)\' gradientUnits=\'userSpaceOnUse\' id=\'LinearGradient\' x1=\'1010\' x2=\'1530\' y1=\'1010\' y2=\'1420\'><stop offset=\'0\' stop-color=\'#757575\' stop-opacity=\'0.220818\'/> <stop offset=\'1\' stop-color=\'#ffffff\' stop-opacity=\'0.452692\'/></linearGradient><style type=\'text/css\'>@font-face{font-family: \'Oswald\'; font-weight: 900; src: url(data:application/font-woff2;charset=utf-8;base64,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) format(\'woff2\'); font-weight: normal; font-style: normal;}</style><rect height=\'100%\' width=\'100%\' fill=\'#ffffff\'/></defs>";
    string constant _card = "<path d=\'M614 270L1386 270C1399.25 270 1410 281.976 1410 296.748L1410 1703.25C1410 1718.02 1399.25 1730 1386 1730L614 1730C600.745 1730 590 1718.02 590 1703.25L590 296.748C590 281.976 600.745 270 614 270Z\' fill=\'#ffffff\' opacity=\'1\' stroke=\'#000000\' stroke-linecap=\'round\' stroke-linejoin=\'round\' stroke-width=\'20\'/><path d=\'M920 360L1080 360C1085.52 360 1090 366.716 1090 375L1090 375C1090 383.284 1085.52 390 1080 390L920 390C914.477 390 910 383.284 910 375L910 375C910 366.716 914.477 360 920 360Z\' fill=\'#000000\' opacity=\'1\'/>";
    string constant _end = "<path d=\'M590 1750C590 1750 580 1750 580 1740L1420.65 260.643C1420.65 260.643 1430 269.357 1430 280L1430 1730C1430 1740 1420 1750 1410 1750\' fill=\'url(#LinearGradient)\' opacity=\'1\'/></svg>";

    constructor (address thestolen){
        _thestolen = thestolen;
    }


    function factionTokenURI(FactionImage memory tokenData) external view returns(string memory){
        require(_thestolen == msg.sender, "Not the real stolen contract");

        string memory currentI;

        if(tokenData.fillOwner && tokenData.fillFaction){
            currentI = returnImageText(["cc0c0d","96","middle","1000","1000",UInt256Extensions.secondsToDayTimeString(tokenData.current)]);
        }

        string memory highscoreTime = UInt256Extensions.secondsToDayTimeString(tokenData.highscore);
        string memory steals = UInt256Extensions.toString(tokenData.steals);

        string memory factionImage = string(abi.encodePacked(
                _imageStart,
                _fonts,
                _card,
                returnImageText([tokenData.fillFaction ? colorActive : colorNormal,"80","middle","1000","600",tokenData.factionName]),
                returnImageText(["000000","48","middle","1000","520","FACTION PASS"]),
                returnImageText(["000000","32","start","650","670","HIGHSCORE"]),
                returnImageText(["000000","32","start","650","710","MEMBERS"]),
                returnImageText(["000000","32","start","650","750","STEALS"])
            ));
        factionImage = string(abi.encodePacked(
                factionImage,
                returnImageText([tokenData.fillHighscore ? colorActive : colorNormal,"32","start","830","670",highscoreTime]),
                returnImageText(["cc0c0d","32","start","830","710",UInt256Extensions.toString(tokenData.member)]),
                returnImageText(["cc0c0d","32","start","830","750",UInt256Extensions.toString(tokenData.factionSteals)]),
                returnImageText([tokenData.fillOwner ? colorActive : colorNormal,"32","end","1380","1700",toAsciiString(tokenData.owner)]),
                returnImageText(["000000","32","end","1380","1660","STEALS"]),
                currentI,
                returnImageText(["cc0c0d","32","end","1280","1660",steals])
            ));

        factionImage = string(abi.encodePacked(
                factionImage,
                _end
            ));

        string memory out = "";
        out = string(abi.encodePacked(
                returnNameMeta(string(abi.encodePacked(tokenData.factionName," Faction Pass"))),
                "\"image_data\":\"data:image/svg+xml;base64,",
                Base64.encode(bytes(factionImage)),
                "\",",
                returnAttributeMeta(),
                returnTraitMeta("Faction",tokenData.factionName),
                ",",
                returnTraitMeta("Owner Steals",UInt256Extensions.toString(tokenData.steals)),
                "]}"
            ));

        out = string(Base64.encode(bytes(out)));
        out = string(abi.encodePacked("data:application/json;base64,",out));

        return out;
    }

    string constant flagImage = "<path d=\'M866.025 1097.5L999.641 1174.64L1133.26 1097.5L999.641 1020.36\' fill=\'#ededed\'/> <path d=\'M921.698 1091.07L999.641 1136.07L1077.58 1091.07L999.641 1046.07L921.698 1091.07\' fill=\'#ededed\'/> <path d=\'M921.698 1091.07L921.698 1103.93L999.641 1148.93L999.641 1136.07\' fill=\'#d9d9d9\'/> <path d=\'M999.641 1148.93L1077.58 1103.93L1077.58 1091.07L999.641 1136.07\' fill=\'#a6a6a6\'/> <path d=\'M866.025 1097.5L866.025 1110.36L999.641 1187.5L999.641 1174.64\' fill=\'#d9d9d9\'/> <path d=\'M999.641 1187.5L1133.26 1110.36L1133.26 1097.5L999.641 1174.64\' fill=\'#a6a6a6\'/> <path d=\'M999.641 1097.5L1021.91 1084.64L1021.91 557.5L999.641 570.357\' fill=\'#a6a6a6\'/> <path d=\'M999.641 1097.5L977.372 1084.64L977.372 557.5L999.641 570.357\' fill=\'#ededed\'/> <path d=\'M977.372 557.5L999.641 570.357L1021.91 557.5L1004.42 547.4L999.641 544.643\' fill=\'#d9d9d9\'/> <path d=\'M1020.44 740.775L1255.74 604.926L1255.74 422.5L1021.91 557.5\' fill=\'#b50c0c\'/> <path d=\'M999.641 544.643L1021.91 557.5L1255.74 422.5L1233.47 409.643\' fill=\'#cc0c0d\'/>";

    function flagTokenURI(string memory factionName, uint256 current) external view returns(string memory){
        require(_thestolen == msg.sender, "Not the real stolen contract");

        string memory c = UInt256Extensions.secondsToDayTimeString(current);
        if(current > 0){
            c = UInt256Extensions.secondsToDayTimeString(current);
        }

        string memory factionNameI;
        string memory currentI;

        if(current > 0){
            factionNameI = returnImageText(["cc0c0d","240","middle","1000","1475",factionName]);
            currentI = returnImageText(["cc0c0d","64","middle","1000","1550",c]);
        }

        string memory flagCompleteImage = string(abi.encodePacked(
                _imageStart,
                _fonts,
                flagImage,
                factionNameI,
                currentI,
                "</svg>"
            ));

        string memory out = "";
        out = string(abi.encodePacked(
                returnNameMeta("FLAG"),
                "\"image_data\":\"data:image/svg+xml;base64,",
                Base64.encode(bytes(flagCompleteImage)),
                "\",",
                returnAttributeMeta(),
                returnTraitMeta("Flag","FLAG"),
                ",",
                returnTraitMeta("Faction Holding",factionName),
                "]}"
            ));

        out = string(Base64.encode(bytes(out)));
        out = string(abi.encodePacked("data:application/json;base64,",out));

        return out;
    }

    function returnImageText(string[6] memory imageText) internal pure returns(string memory){
        string memory out =  string(abi.encodePacked(
                "<text fill=\'#",
                imageText[0] ,
                "\' font-family=\'Oswald\' font-weight=\'900\' font-size=\'",
                imageText[1],
                "\' text-anchor=\'",
                imageText[2]));
        out = string(abi.encodePacked(
                out,
                "\' x=\'",
                imageText[3],
                "\' y=\'",
                imageText[4]
            ));
        out = string(abi.encodePacked(
                out,
                "\'><tspan>",
                imageText[5],
                "</tspan></text>"
            ));
        return out;
    }

    function returnNameMeta(string memory tokenName) internal pure returns(string memory){
        return string(abi.encodePacked("{\"name\":\"" , tokenName , "\","));
    }

    function returnAttributeMeta() internal pure returns(string memory){
        return "\"attributes\":[";
    }

    function returnTraitMeta(string memory dataType, string memory dataValue) internal pure returns(string memory){
        return string(abi.encodePacked("{\"trait_type\":\"" , dataType , "\",\"value\":\"" , dataValue , "\"}"));
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57) & 0x5f;
    }
}