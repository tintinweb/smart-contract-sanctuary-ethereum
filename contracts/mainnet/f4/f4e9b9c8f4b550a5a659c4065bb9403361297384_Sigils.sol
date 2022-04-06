// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
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

library Buffer {
    function hasCapacityFor(bytes memory buffer, uint256 needed) internal pure returns (bool) {
        uint256 size;
        uint256 used;
        assembly {
            size := mload(buffer)
            used := mload(add(buffer, 32))
        }
        return size >= 32 && used <= size - 32 && used + needed <= size - 32;
    }

    function toString(bytes memory buffer) internal pure returns (string memory) {
        require(hasCapacityFor(buffer, 0), "Buffer.toString: invalid buffer");
        string memory ret;
        assembly {
            ret := add(buffer, 32)
        }
        return ret;
    }

    function append(bytes memory buffer, string memory str) internal view {
        require(hasCapacityFor(buffer, bytes(str).length), "Buffer.append: no capacity");
        assembly {
            let len := mload(add(buffer, 32))
            pop(staticcall(gas(), 0x4, add(str, 32), mload(str), add(len, add(buffer, 64)), mload(str)))
            mstore(add(buffer, 32), add(len, mload(str)))
        }
    }
}

interface Cryptomancy
{
    function balanceOf (address account, uint256 id) external view returns (uint256);
}

interface CDROM
{
    function ownerOf (uint256 tokenId) external view returns (address);
}

contract Sigils is ERC721, ReentrancyGuard {
    address public _owner;
    uint256 public maxSupply = 9393;
    uint256 private _count = 0;
    uint256 private _price = 10000000 gwei;

    address private cryptomancyAddress = 0x7c7fC6d9F2c2e45f12657DAB3581EAd2BD53bDF1;
    address private cdAddress = 0xad78E15a5465C09F6E6522b0d98b1F3b6B67Ee7e;
    Cryptomancy cryptomancyContract = Cryptomancy(cryptomancyAddress);
    CDROM cdContract = CDROM(cdAddress);
    mapping(uint256 => bool) private _cryptomancyMints;
    mapping(uint256 => bool) private _cdMints;

    struct sigilValues {
        uint8[] sigil;
        uint8 gradient;
        uint8 color;
        uint8 planetHour;
        uint8 planetDay;
        uint8 darkBG;
        uint16 rareNumber;
        bytes intent;
        string texture;
    }
    mapping (uint256 => sigilValues) public idSigils;

    // array of uint array that is used to map letters to coordinates
    // these coordinates are equidistanct points around the circumphrence of a circle
    uint[2][22] private _coords = [[uint(0),uint(0)],[uint(235),uint(420)],[uint(279),uint(411)],[uint(333),uint(385)],[uint(376),uint(345)],[uint(406),uint(293)],[uint(419),uint(235)],[uint(415),uint(175)],[uint(393),uint(120)],[uint(356),uint(73)],[uint(307),uint(40)],[uint(250),uint(22)],[uint(190),uint(22)],[uint(133),uint(40)],[uint(84),uint(73)],[uint(47),uint(120)],[uint(25),uint(175)],[uint(21),uint(235)],[uint(34),uint(293)],[uint(64),uint(345)],[uint(107),uint(385)],[uint(161),uint(411)]];

    // array of planet descriptions and symbols for use in sigil generation
    string[8] private _planetSymbols = ['invalid', unicode'♄', unicode'♃', unicode'♂', unicode'☉', unicode'♀', unicode'☿', unicode'☽'];
    string[8] private _planetNames = ["invalid", "Saturn", "Jupiter", "Mars", "Sun", "Venus", "Mercury", "Moon"];

    // Light background gradients with hash to visualise (use color highlight vscode plugin)
    // #9e7682,#ad7780,#bb797c,#c7837c,#d29381,#dda587,#e5b88e,#edcb96
    // #e9d758,#e9e46c,#e3e880,#dce894,#d9e7a8,#d9e7bc,#dde6d0,#e5e6e4
    // #fff4f3,#ffe9ef,#ffe0f3,#ffd6fd,#f0ccff,#d8c2ff,#bab9ff,#afc9ff
    // #c5decd,#afd8be,#9ad2b1,#86cca6,#72c69c,#60c094,#4eba8e,#3eb489
    // #ec9192,#ec9ba9,#eca5bc,#ecafcd,#ecb8da,#ecc2e4,#eccceb,#e9d6ec
    // #ffc4eb,#fbb9d0,#f6b0b1,#f0bea9,#e8cea2,#dedb9d,#c4d39a,#abc798
    // #bdd2a6,#aacda3,#a0c7a7,#9ec1b1,#9cbbb7,#9aaeb4,#99a2ad,#9899a6
    // #eff8e2,#ebf4dc,#e8f0d7,#e4ebd2,#dfe5ce,#dadecb,#d5d7c9,#cecfc7
    // #f3dfc1,#f1dabd,#eed6b9,#ebd1b5,#e8ccb1,#e4c7ae,#e1c3ab,#ddbea8
    // #b2a3b5,#a796b4,#9687b4,#7d78b4,#6976b6,#5880b8,#4695bb,#3aafb9
    // #91818a,#a88591,#bd8b91,#cf9994,#deb2a0,#eacdae,#f3e6c0,#faf8d4
    bytes6[8][11] private _gradientsLight = [[bytes6('9e7682'),bytes6('ad7780'),bytes6('bb797c'),bytes6('c7837c'),bytes6('d29381'),bytes6('dda587'),bytes6('e5b88e'),bytes6('edcb96')],[bytes6('e9d758'),bytes6('e9e46c'),bytes6('e3e880'),bytes6('dce894'),bytes6('d9e7a8'),bytes6('d9e7bc'),bytes6('dde6d0'),bytes6('e5e6e4')],[bytes6('fff4f3'),bytes6('ffe9ef'),bytes6('ffe0f3'),bytes6('ffd6fd'),bytes6('f0ccff'),bytes6('d8c2ff'),bytes6('bab9ff'),bytes6('afc9ff')],[bytes6('c5decd'),bytes6('afd8be'),bytes6('9ad2b1'),bytes6('86cca6'),bytes6('72c69c'),bytes6('60c094'),bytes6('4eba8e'),bytes6('3eb489')],[bytes6('ec9192'),bytes6('ec9ba9'),bytes6('eca5bc'),bytes6('ecafcd'),bytes6('ecb8da'),bytes6('ecc2e4'),bytes6('eccceb'),bytes6('e9d6ec')],[bytes6('ffc4eb'),bytes6('fbb9d0'),bytes6('f6b0b1'),bytes6('f0bea9'),bytes6('e8cea2'),bytes6('dedb9d'),bytes6('c4d39a'),bytes6('abc798')],[bytes6('bdd2a6'),bytes6('aacda3'),bytes6('a0c7a7'),bytes6('9ec1b1'),bytes6('9cbbb7'),bytes6('9aaeb4'),bytes6('99a2ad'),bytes6('9899a6')],[bytes6('eff8e2'),bytes6('ebf4dc'),bytes6('e8f0d7'),bytes6('e4ebd2'),bytes6('dfe5ce'),bytes6('dadecb'),bytes6('d5d7c9'),bytes6('cecfc7')],[bytes6('f3dfc1'),bytes6('f1dabd'),bytes6('eed6b9'),bytes6('ebd1b5'),bytes6('e8ccb1'),bytes6('e4c7ae'),bytes6('e1c3ab'),bytes6('ddbea8')],[bytes6('b2a3b5'),bytes6('a796b4'),bytes6('9687b4'),bytes6('7d78b4'),bytes6('6976b6'),bytes6('5880b8'),bytes6('4695bb'),bytes6('3aafb9')],[bytes6('91818a'),bytes6('a88591'),bytes6('bd8b91'),bytes6('cf9994'),bytes6('deb2a0'),bytes6('eacdae'),bytes6('f3e6c0'),bytes6('faf8d4')]];
    bytes12[11] private _gradientsLightDesc = [
        bytes12('kitchen wall'),
        bytes12('bike dreamer'),
        bytes12('cotton candy'),
        bytes12('falling tree'),
        bytes12('heart desire'),
        bytes12('fluorescence'),
        bytes12('forest mists'),
        bytes12('ancient moor'),
        bytes12('desert peaks'),
        bytes12('shimmer pool'),
        bytes12('night wander')
    ];

    // Dark gradients
    // #800815,#920832,#a40757,#b60783,#c905b6,#c404db,#a602ed,#7f00ff
    // #884274,#994272,#aa406a,#bb3b59,#cc3541,#dd3c2e,#ee5524,#ff7518
    // #1e0336,#1a044b,#0c0461,#041276,#03328c,#035ca1,#018fb7,#00cccc
    // #453a94,#574097,#67479a,#774d9d,#86549f,#945ba2,#a063a5,#a86aa4
    // #090a0f,#161826,#22253c,#2e3153,#393b6a,#434381,#4e4c97,#5a55ae
    // #0d3b66,#102370,#1f137a,#461684,#701a8d,#971e8f,#a12271,#ab274f
    // #aa4465,#a64258,#a2414c,#9e3f40,#9b463d,#974e3b,#93553a,#8f5c38
    // #590925,#5a113a,#5b1a4c,#5c235b,#552c5e,#4f355f,#4c3e60,#4d4861
    // #093a3e,#0e4d52,#135f65,#197077,#208189,#28919a,#31a0aa,#3aafb9
    // #3d5a6c,#3d4a66,#3d3e5f,#443d59,#493c53,#4b3c4e,#483b46,#433a3f
    // #17301c,#1d3a27,#244434,#2b4e42,#325750,#3a5f5e,#426468,#4a6670
    bytes6[8][11] private _gradientsDark = [[bytes6('800815'),bytes6('920832'),bytes6('a40757'),bytes6('b60783'),bytes6('c905b6'),bytes6('c404db'),bytes6('a602ed'),bytes6('7f00ff')],[bytes6('884274'),bytes6('994272'),bytes6('aa406a'),bytes6('bb3b59'),bytes6('cc3541'),bytes6('dd3c2e'),bytes6('ee5524'),bytes6('ff7518')],[bytes6('1e0336'),bytes6('1a044b'),bytes6('0c0461'),bytes6('041276'),bytes6('03328c'),bytes6('035ca1'),bytes6('018fb7'),bytes6('00cccc')],[bytes6('453a94'),bytes6('574097'),bytes6('67479a'),bytes6('774d9d'),bytes6('86549f'),bytes6('945ba2'),bytes6('a063a5'),bytes6('a86aa4')],[bytes6('090a0f'),bytes6('161826'),bytes6('22253c'),bytes6('2e3153'),bytes6('393b6a'),bytes6('434381'),bytes6('4e4c97'),bytes6('5a55ae')],[bytes6('0d3b66'),bytes6('102370'),bytes6('1f137a'),bytes6('461684'),bytes6('701a8d'),bytes6('971e8f'),bytes6('a12271'),bytes6('ab274f')],[bytes6('aa4465'),bytes6('a64258'),bytes6('a2414c'),bytes6('9e3f40'),bytes6('9b463d'),bytes6('974e3b'),bytes6('93553a'),bytes6('8f5c38')],[bytes6('590925'),bytes6('5a113a'),bytes6('5b1a4c'),bytes6('5c235b'),bytes6('552c5e'),bytes6('4f355f'),bytes6('4c3e60'),bytes6('4d4861')],[bytes6('093a3e'),bytes6('0e4d52'),bytes6('135f65'),bytes6('197077'),bytes6('208189'),bytes6('28919a'),bytes6('31a0aa'),bytes6('3aafb9')],[bytes6('3d5a6c'),bytes6('3d4a66'),bytes6('3d3e5f'),bytes6('443d59'),bytes6('493c53'),bytes6('4b3c4e'),bytes6('483b46'),bytes6('433a3f')],[bytes6('17301c'),bytes6('1d3a27'),bytes6('244434'),bytes6('2b4e42'),bytes6('325750'),bytes6('3a5f5e'),bytes6('426468'),bytes6('4a6670')]];
    bytes12[11] private _gradientsDarkDesc = [
        bytes12('booba paints'),
        bytes12('hallowed eve'),
        bytes12('fallen light'),
        bytes12('logos flight'),
        bytes12('seeping dark'),
        bytes12('volcanic art'),
        bytes12('archaeologer'),
        bytes12('lava bubbles'),
        bytes12('escaping out'),
        bytes12('night terror'),
        bytes12('misty copses')
    ];
    // #e3be46,#e1bb43,#dab53c,#d1ac32,#c8a229,#bf9a21,#b8931b,#b69119
    bytes6[8] private _gradientGold = [bytes6('e3be46'),bytes6('e1bb43'),bytes6('dab53c'),bytes6('d1ac32'),bytes6('c8a229'),bytes6('bf9a21'),bytes6('b8931b'),bytes6('b69119')];

    bytes6[11] private _colorsLight = [bytes6('ffc4eb'),bytes6('e9e46c'),bytes6('9ad2b1'),bytes6('ec9192'),bytes6('3aafb9'),bytes6('e5e6e4'),bytes6('fff4f3'),bytes6('e5b88e'),bytes6('c5decd'),bytes6('e9d6ec'),bytes6('b2a3b5')];
    bytes6[11] private _colorsDark = [bytes6('3f19af'),bytes6('101010'),bytes6('0D3B66'),bytes6('800815'),bytes6('ff7518'),bytes6('090a0f'),bytes6('433a3f'),bytes6('4a6670'),bytes6('17301c'),bytes6('34403a'),bytes6('1e0336')];

    constructor() ERC721("Sigils", "SIGIL") {
        _owner = msg.sender;
    }

    // shuffle numbers in a way that prevents repeats
    function _shuffle(string memory seed) private view returns (uint8[21] memory){
        uint8[21] memory _numArray = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21];
        for (uint256 i = 0; i < _numArray.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))) % (_numArray.length - i);
            uint8 temp = _numArray[n];
            _numArray[n] = _numArray[i];
            _numArray[i] = temp;
        }
        return _numArray;
    }

    // return a randomised number
    function _random(uint mod, string memory seed1, string memory seed2, string memory seed3, string memory seed4) private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed1, seed2, seed3, seed4)))%mod);
    }

    // unpack coordinates array
    function _drawSigil(sigilValues storage s) private view returns (string memory) {
        bytes memory sigilBuffer = new bytes(8192);
        uint8 _sigNum = s.sigil[0];

        Buffer.append(sigilBuffer, string(abi.encodePacked(toString(_coords[_sigNum][0]), ', ', toString(_coords[_sigNum][1]))));
        for (uint i=1; i<s.sigil.length; ++i) {
            _sigNum = s.sigil[i];
            Buffer.append(sigilBuffer, string(abi.encodePacked(' ', toString(_coords[_sigNum][0]), ', ', toString(_coords[_sigNum][1]))));
        }

        return Buffer.toString(sigilBuffer);
    }

    function _genSigil(sigilValues storage s, bytes6 color, bytes6[8] storage gradient) private view returns (string memory) {
        uint[2] memory _firstCoords = _coords[s.sigil[0]];
        uint[2] memory _lastCoords = _coords[s.sigil[s.sigil.length-1]];

        string memory sigilCoords = _drawSigil(s);

        bytes memory svgBuffer = new bytes(8192);

        Buffer.append(svgBuffer, '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg version="1.1" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 440 440"><defs><linearGradient id="lg" x1="0" x2="0" y1="0" y2="1">');

        for (uint i=0; i<gradient.length; i++) {
            string memory offset;
            if (i == 0) { offset = '0'; }
            if (i == 1) { offset = '14'; }
            if (i == 2) { offset = '28'; }
            if (i == 3) { offset = '42'; }
            if (i == 4) { offset = '56'; }
            if (i == 5) { offset = '70'; }
            if (i == 6) { offset = '84'; }
            if (i == 7) { offset = '100'; }
            Buffer.append(svgBuffer, string(abi.encodePacked('<stop offset="', offset, '%" stop-color="#', gradient[i], '"/>')));
        }

        bytes6 floodColor;
        if (s.darkBG == 1) {
            floodColor = color;
        } else {
            floodColor = bytes6('f0f0f0');
        }

        string memory circle;
        if (s.rareNumber == 93 || s.rareNumber == 888) {
            // mega rares have a special effect layer
            circle = string(abi.encodePacked('<filter id="circEff" color-interpolation-filters="sRGB" x="0" y="0" width="200%" height="200%"><feTurbulence type="turbulence" baseFrequency=".01,.2" numOctaves="2" seed="',toString(s.rareNumber),'"/><feDiffuseLighting surfaceScale="1" diffuseConstant="1" lighting-color="#ffffff" x="0%" y="0%" width="100%" height="100%"><feDistantLight azimuth="15" elevation="105"/></feDiffuseLighting><feComposite in2="SourceGraphic" operator="in"/><feBlend in2="SourceGraphic" mode="multiply"/></filter><circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision" filter="url(#circEff)"/>'));
        } else if (s.rareNumber >= 655 && s.rareNumber <= 677) {
            // not so rare but still cool, gets rock filter
            circle = string(abi.encodePacked('<filter id="circEff" color-interpolation-filters="sRGB" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency=".07,.03" numOctaves="4" seed="',toString(s.rareNumber),'"/><feDiffuseLighting surfaceScale="5" diffuseConstant="0.75" lighting-color="#fff" x="0%" y="0%" width="100%" height="100%"><feDistantLight azimuth="3" elevation="100"/></feDiffuseLighting><feComposite in2="SourceGraphic" operator="in"/><feBlend in="SourceGraphic" mode="multiply"/></filter><circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision" filter="url(#circEff)"/>'));
        } else if (s.rareNumber >= 10 && s.rareNumber <= 50) {
            // these guys get a fabric effect
            circle = string(abi.encodePacked('<filter id="circEff" color-interpolation-filters="sRGB" x="0" y="0" width="100%" height="100%"><feTurbulence type="turbulence" baseFrequency=".03,.003" numOctaves="1" seed="',toString(s.rareNumber),'"/><feColorMatrix type="matrix" values="0 0 0 0 0,0 0 0 0 0,0 0 0 0 0,0 0 0 -1.5 1.1"/><feComposite in="SourceGraphic" operator="in"/><feBlend in="SourceGraphic" mode="screen"/></filter><circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision" filter="url(#circEff)"/>'));
        } else {
            circle = '<circle cx="220" cy="220" r="215" stroke-width="0" fill="url(#lg)" shape-rendering="geometricPrecision"/>';
        }
        Buffer.append(svgBuffer, string(abi.encodePacked('</linearGradient></defs><filter id="shadow" x="0" y="0" width="200%" height="200%" filterUnits="userSpaceOnUse"><feGaussianBlur in="SourceAlpha" stdDeviation="4"/><feOffset dx="0" dy="0" result="offsetblur"/><feFlood flood-color="#', floodColor, '" flood-opacity="0.75"/><feComposite in2="offsetblur" operator="in"/><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>',circle)));
        Buffer.append(svgBuffer, string(abi.encodePacked('<g fill="none" stroke="#', color, '" stroke-width="5" stroke-linejoin="round" filter="url(#shadow)" shape-rendering="geometricPrecision"><polyline points="', sigilCoords, '" />')));

        Buffer.append(svgBuffer, string(abi.encodePacked('<polyline points="', toString(_lastCoords[0]), ', ', toString(_lastCoords[1] + 10), ', ', toString(_lastCoords[0]), ', ', toString(_lastCoords[1] - 10), '" stroke-linecap="round" />')));
        Buffer.append(svgBuffer, string(abi.encodePacked('<circle cx="', toString(_firstCoords[0]), '" cy="', toString(_firstCoords[1]), '" r="5" fill="#', color, '"/></g>')));
        Buffer.append(svgBuffer, string(abi.encodePacked('<text x="110" y="330" fill="#', color, '" font-size="80px" font-weight="bold" stroke="transparent" fill-opacity="0.25" dominant-baseline="middle" text-anchor="middle">', _planetSymbols[s.planetDay], '</text><text x="330" y="330" fill="#', color, '" font-size="80px" font-weight="bold" stroke="transparent" fill-opacity="0.25" dominant-baseline="middle" text-anchor="middle">', _planetSymbols[s.planetHour], '</text></svg>')));

        return Buffer.toString(svgBuffer);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory jsonOut;
        string memory svgOut;

        sigilValues storage s = idSigils[tokenId];

        bytes6 color;
        bytes6[8] storage gradient;
        bytes12 gradientDesc;
        if (s.rareNumber == 93 || s.rareNumber == 888) {
            // this is a super rare mega gold card
            color = bytes6('FDF2C3'); // #FDF2C3
            gradient = _gradientGold;
            gradientDesc = bytes12('gold bullrun');
        } else {
            // this is a boring normal card
            if (s.darkBG == 1) {
                color = _colorsLight[s.color];
                gradient = _gradientsDark[s.gradient];
                gradientDesc = _gradientsDarkDesc[s.gradient];
            } else {
                color = _colorsDark[s.color];
                gradient = _gradientsLight[s.gradient];
                gradientDesc = _gradientsLightDesc[s.gradient];
            }
        }

        svgOut = _genSigil(s, color, gradient);

        bytes memory jsonBuffer = new bytes(8192);
        Buffer.append(jsonBuffer, string(abi.encodePacked('{"name": "Sigil #', toString(tokenId), '", "attributes": [ { "trait_type": "Color", "value": "#', color ,'" }, { "trait_type": "Gradient", "value": "', gradientDesc, '" }, { "trait_type": "Intent", "value": "', s.intent, '" },')));
        Buffer.append(jsonBuffer, string(abi.encodePacked(' { "trait_type": "Texture", "value": "', s.texture, '" }, { "trait_type": "Planetary Day", "value": "', _planetNames[s.planetDay], '"}, { "trait_type": "Planetary Hour", "value": "', _planetNames[s.planetHour], '"} ], "description": "Sigils are an on-chain representation of pure intent. Users input their intent after deep reflection and receive this image in response.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgOut)), '"}')));
        jsonOut = Base64.encode(bytes(Buffer.toString(jsonBuffer)));
        bytes memory result = new bytes(8192);
        Buffer.append(result, 'data:application/json;base64,');
        Buffer.append(result, jsonOut);
        return Buffer.toString(result);
    }

    function mint(string memory intent, uint8 planetDay, uint8 planetHour) internal {
        bytes memory intentBytes = bytes(intent);
        require(intentBytes.length > 2, "Must provide at least 3 chars");
        // we arent actually checking for repeating letters - the only time this happens is when people do dumb stuff via directly interacting with the contract, and who cares if those people make their sigils look dumb
        require(intentBytes.length < 22, "No repeating letters");
        require(planetDay < 8, "Invalid planetDay");
        require(planetHour < 8, "Invalid planetHour");

        uint8 ord;
        uint8[] memory intentArray = new uint8[](intentBytes.length);
        uint8[21] memory shuffleArray = _shuffle(toString(_count));
        for (uint i=0; i<intentBytes.length; ++i) {
            ord = toUint8(bytes.concat(intentBytes[i]), 0);
            require(ord > 97 && ord <= 122, "Only use lowercase latin letters");
            require(ord != 101 && ord != 105 && ord != 111 && ord != 117, "No vowels permitted");
            // we need to reduce the numbers down to the range of 1-21
            // we also map them to the shuffled number thats in shuffleArray
            uint8 shufOrd;
            if (ord > 97 && ord < 101) {
                shufOrd = ord - 98;
            } else if (ord > 101 && ord < 105) {
                shufOrd = ord - 99;
            } else if (ord > 105 && ord < 111) {
                shufOrd = ord - 100;
            } else if (ord > 111 && ord < 117) {
                shufOrd = ord - 101;
            } else if (ord > 117) {
                shufOrd = ord - 102;
            }
            intentArray[i] = shuffleArray[shufOrd];
        }

        if (planetDay == 0) {
            // get a random planet, use static seed
            planetDay = _random(7, 'planetDay', intent, string(abi.encodePacked(msg.sender)), toString(_count)) + 1;
        }
        if (planetHour == 0) {
            // get a random planet, use static seed
            planetHour = _random(7, 'planetHour', intent, string(abi.encodePacked(msg.sender)), toString(_count)) + 1;
        }

        sigilValues storage thisSigil = idSigils[_count];
        thisSigil.planetDay = planetDay;
        thisSigil.planetHour = planetHour;
        thisSigil.sigil = intentArray;
        thisSigil.intent = intentBytes;
        thisSigil.gradient = _random(11, 'gradient', intent, string(abi.encodePacked(msg.sender)), toString(_count));
        thisSigil.color = _random(11, 'color', intent, string(abi.encodePacked(msg.sender)), toString(_count));
        thisSigil.darkBG = _random(2, 'color', intent, string(abi.encodePacked(msg.sender)), toString(_count));

        uint16 rareNumber = _random(1000, 'rarity', intent, string(abi.encodePacked(msg.sender)), toString(_count));
        thisSigil.rareNumber = rareNumber;
        if (rareNumber == 93 || rareNumber == 888) {
            thisSigil.texture = 'gold';
        } else if (rareNumber >= 655 && rareNumber <= 677) {
            thisSigil.texture = 'rock';
        } else if (rareNumber >= 10 && rareNumber <= 50) {
            thisSigil.texture = 'fabric';
        } else {
            thisSigil.texture = 'flat';
        }

        _safeMint(_msgSender(), _count);
        ++_count;
    }

    function mintWithCryptomancy(uint256 _cryptomancyId, string memory _intent, uint8 _planetDay, uint8 _planetHour) external nonReentrant {
        require(cryptomancyContract.balanceOf(msg.sender, _cryptomancyId) > 0, "Not the owner of this Cryptomancy.");
        require(!_cryptomancyMints[_cryptomancyId], "This Cryptomancy has already been used.");
        _cryptomancyMints[_cryptomancyId] = true;
        mint(_intent, _planetDay, _planetHour);
    }

    function mintWithCD(uint256 _cdId, string memory _intent, uint8 _planetDay, uint8 _planetHour) external nonReentrant {
        require(cdContract.ownerOf(_cdId) == msg.sender, "Not the owner of this Ghost CD.");
        require(!_cdMints[_cdId], "This Ghost CD has already been used.");
        _cdMints[_cdId] = true;
        mint(_intent, _planetDay, _planetHour);
    }

    function mintSigil(string memory _intent, uint8 _planetDay, uint8 _planetHour) public payable nonReentrant {
        require(msg.value >= _price, "Price is 0.01 ETH!");
        // maxSupply should only apply for the paid ones, cd-rom and cryptomancy will always succeed
        require(_count < maxSupply, "Capped!");
        mint(_intent, _planetDay, _planetHour);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function withdraw() external {
        address payable ownerDestination = payable(_owner);

        ownerDestination.transfer(address(this).balance);
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function totalSupply() external view returns (uint256) {
        return _count;
    }

    function claimPrice() external view returns (uint256) {
        return _price;
    }

    function hasClaimedCryptomancy(uint256 id) external view returns (bool) {
        return _cryptomancyMints[id];
    }

    function hasClaimedCD(uint256 id) external view returns (bool) {
        return _cdMints[id];
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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