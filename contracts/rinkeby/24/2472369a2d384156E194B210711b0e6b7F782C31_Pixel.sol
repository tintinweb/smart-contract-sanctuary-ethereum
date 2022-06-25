// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Pixel is ERC721, Ownable {
    using Strings for uint256;

    string[] private backgroundColors = ["#00a2e8", "#ffa500"];
    string[] private baseColors = ["#c4a484", "#f2be9e"];
    string[] private face = [
        '<path stroke="#7f7f7f" d="M16 22h4" /><path stroke="#000000" d="M17 23h1" />',
        '<path stroke="#a1a1a1" d="M15 22h3" /><path stroke="#000000" d="M16 23h1" /><path stroke="#ffffff" d="M17 23h1" />'
    ];
    string[] private mouth = [
        '<path stroke="#573600" d="M14 24h1M13 25h2M25 25h3M13 26h12M13 27h14M13 28h13M27 28h2M14 29h11M26 29h6M15 30h9M25 30h7M16 31h6M24 31h6M16 32h4M22 32h8M17 33h1M20 33h8M21 34h6M23 35h2" /><path stroke="#000000" d="M28 25h1M25 26h4M30 26h2M27 27h2M30 27h2M26 28h1M29 28h3M25 29h1M24 30h1M22 31h2M20 32h2M18 33h2" />',
        '<path stroke="#154734" d="M15 30h1M14 31h1M13 32h1M12 33h1M10 34h1M10 35h2M10 36h2M10 37h1M9 38h1M10 39h1" /><path stroke="#808080" d="M13 33h1M12 34h1M5 37h1M11 37h1M10 38h1M9 39h1M9 40h1" /><path stroke="#424242" d="M9 34h1M7 35h1M7 36h1" /><path stroke="#212121" d="M11 34h1" /><path stroke="#263238" d="M8 35h2M6 36h1" /><path stroke="#a1a1a1" d="M9 41h1" />'
    ];
    string[] private hair = [
        '<path stroke="#000000" d="M20 6h7M18 7h2M27 7h2M14 8h4M29 8h2M12 9h3M31 9h1M12 10h1M32 10h1M12 11h1M32 11h1M11 12h2M33 12h1M11 13h2M17 13h1M19 13h4M33 13h1M11 14h3M16 14h1M21 14h1M33 14h1M11 15h2M14 15h2M22 15h1M33 15h1M11 16h2M22 16h1M33 16h1M11 17h2M22 17h2M33 17h1M11 18h2M23 18h1M25 18h1M33 18h2M11 19h2M23 19h2M26 19h1M28 19h1M30 19h1M34 19h1M11 20h2M23 20h2M26 20h1M28 20h1M30 20h1M34 20h1M11 21h2M24 21h1M26 21h3M30 21h1M34 21h1M11 22h2M24 22h1M27 22h1M30 22h1M34 22h1M11 23h3M27 23h1M31 23h1M34 23h1M11 24h3M31 24h1M34 24h1M10 25h3M31 25h2M34 25h1M10 26h3M32 26h1M34 26h1M10 27h2M32 27h1M34 27h1M10 28h2M32 28h1M34 28h1M11 29h1M32 29h4M11 30h1M32 30h3M11 31h1M12 32h1" /><path stroke="#99d9ea" d="M20 7h7M18 8h11M15 9h16M13 10h19M13 11h19M13 12h20M13 13h4M18 13h1M23 13h10M14 14h2M18 14h1M22 14h11M18 15h1M23 15h10M18 16h1M23 16h10M18 17h1M24 17h9M18 18h1M24 18h1M26 18h7M18 19h1M27 19h1M29 19h1M31 19h3M18 20h1M27 20h1M29 20h1M31 20h3M18 21h1M29 21h1M31 21h3M18 22h1M29 22h1M31 22h3M18 23h1M29 23h1M32 23h2M18 24h1M29 24h1M32 24h2M18 25h1M29 25h1M33 25h1M18 26h1M29 26h1M33 26h1M29 27h1M33 27h1M33 28h1" /><path stroke="#a1a1a1" d="M10 12h1M10 13h1M10 14h1M17 14h1M10 15h1M13 15h1M17 15h1M10 16h1M19 16h1M10 17h1M19 17h1M10 18h1M19 18h1M10 19h1M19 19h1M10 20h1M19 20h1M10 21h1M19 21h1M10 22h1M10 23h1M10 24h1M19 24h1M19 25h1" />',
        '<path stroke="#000000" d="M19 6h9M17 7h2M27 7h2M15 8h3M29 8h1M14 9h1M30 9h2M12 10h3M32 10h1M32 11h1M10 12h4M32 12h2M11 13h1M15 13h2M19 13h3M33 13h1M11 14h4M17 14h1M21 14h2M33 14h2M11 15h2M17 15h1M22 15h1M33 15h2M11 16h2M22 16h2M25 16h3M11 17h1M23 17h3M27 17h1M33 17h2M11 18h2M23 18h1M27 18h1M34 18h1M11 19h2M26 19h1M34 19h2M11 20h2M26 20h1M35 20h1M11 21h2M27 21h1M35 21h1M10 22h3M26 22h1M28 22h1M33 22h3M10 23h3M27 23h1M32 23h3M10 24h3M26 24h2M31 24h4M10 25h4M26 25h1M30 25h5M10 26h4M26 26h1M30 26h5M11 27h2M29 27h5M11 28h2M29 28h6M11 29h2M29 29h6M11 30h1M29 30h1M31 30h5" /><path stroke="#a52a2a" d="M19 7h8M18 8h11M15 9h15M15 10h17M13 11h19M14 12h18M12 13h3M17 13h2M22 13h11M18 14h1M23 14h10M18 15h1M23 15h10M18 16h1M24 16h1M28 16h6M18 17h2M28 17h5M18 18h2M28 18h6M18 19h2M27 19h7M18 20h2M27 20h8M18 21h2M28 21h7M18 22h2M29 22h4M18 23h1M28 23h4M18 24h1M28 24h3M18 25h1M27 25h3M29 26h1" /><path stroke="#ffffff" d="M13 29h1" />'
    ];
    string[] private outfit = [
        '<path stroke="#000000" d="M34 29h2M32 30h2M35 30h1M30 31h2M35 31h2M30 32h1M34 32h1M36 32h1M28 33h3M33 33h1M36 33h1M27 34h2M36 34h2M24 35h3M35 35h3M23 36h3M37 36h1M22 37h2M37 37h1M21 38h2M38 38h1M21 39h1M38 39h1M20 40h2M39 40h1M20 41h3M29 41h1M35 41h3M39 41h1M20 42h1M40 42h1M19 43h3M40 43h1M19 44h2M40 44h1M18 45h3M41 45h1M18 46h3M22 46h1M40 46h2M18 47h1M20 47h1M22 47h1M30 47h1M40 47h2M17 48h1M20 48h1M22 48h1M25 48h1M31 48h1M39 48h3M17 49h5M39 49h3" /><path stroke="#5487ff" d="M34 30h1M32 31h3M31 32h3M31 33h2M29 34h4M27 35h5M27 36h4M25 37h5M25 38h4M25 39h3M24 40h3M23 41h3M21 42h5M22 43h3M21 44h4M21 45h3M21 46h1M19 47h1M21 47h1M19 48h1" /><path stroke="#efe4b0" d="M35 32h1M34 33h2M33 34h1M35 34h1M32 35h1M31 36h2M35 36h2M30 37h2M33 37h4M29 38h3M33 38h5M28 39h3M32 39h6M27 40h3M31 40h8M26 41h3M30 41h4M26 42h3M30 42h1M33 42h7M25 43h3M29 43h1M31 43h8M25 44h2M28 44h11M24 45h3M28 45h1M30 45h9M23 46h6M30 46h10M23 47h2M26 47h1M28 47h2M31 47h8M23 48h2M28 48h3M32 48h7M22 49h3M29 49h10" /><path stroke="#a1a1a1" d="M34 34h1M34 35h1M34 36h1M32 37h1M32 38h1M31 39h1M30 40h1M34 41h1M38 41h1M29 42h1M31 42h2M28 43h1M30 43h1M39 43h1M27 44h1M39 44h1M27 45h1M29 45h1M39 45h2M29 46h1M25 47h1M39 47h1M25 49h1" /><path stroke="#c3c3c3" d="M33 35h1M33 36h1" /><path stroke="#7092be" d="M26 36h1M24 37h1M23 38h2M22 39h3M22 40h2" /><path stroke="#f75b63" d="M27 47h1M26 49h1" /><path stroke="#f26f9b" d="M18 48h1M21 48h1M26 48h2M27 49h2" />',
        '<path stroke="#808080" d="M34 29h1M35 30h1M33 33h1M31 34h1M36 34h1M15 38h1M17 38h1M16 39h1M25 39h1M34 39h1M18 40h1M22 40h1M34 40h1M35 41h1M36 42h1M28 43h1M36 43h1M28 45h1M11 46h1M29 46h1M29 47h1M22 48h1M12 49h1M22 49h1" /><path stroke="#000000" d="M35 29h1M32 30h2M35 31h2M35 32h2M22 33h2M35 33h4M21 34h3M32 34h3M38 34h1M19 35h5M30 35h1M33 35h1M38 35h1M18 36h3M29 36h2M36 36h1M38 36h1M16 37h5M27 37h1M29 37h1M36 37h4M18 38h3M25 38h1M27 38h1M33 38h1M39 38h2M15 39h1M18 39h2M21 39h1M31 39h2M40 39h2M15 40h1M30 40h1M40 40h3M15 41h1M18 41h3M26 41h1M40 41h3M13 42h3M18 42h1M24 42h2M28 42h1M41 42h1M43 42h1M12 43h2M17 43h1M42 43h3M12 44h1M17 44h2M28 44h1M36 44h1M43 44h2M12 45h2M16 45h2M43 45h2M12 46h1M16 46h2M22 46h1M44 46h1M11 47h1M16 47h2M22 47h1M44 47h1M11 48h1M16 48h1M21 48h1M44 48h1M11 49h1M16 49h1M20 49h2M44 49h1" /><path stroke="#880e4f" d="M34 30h1M31 31h4M29 32h6M28 33h5M34 33h1M27 34h4M35 34h1M25 35h5M21 36h2M25 36h4M21 37h1M23 37h4M21 38h4M20 39h1M22 39h1M21 41h1M19 42h3M18 43h4M19 44h3M18 45h4M18 46h4M18 47h4M17 48h4M17 49h3" /><path stroke="#90ee90" d="M37 34h1M31 35h2M34 35h4M31 36h5M37 36h1M28 37h1M30 37h6M16 38h1M26 38h1M28 38h5M34 38h5M17 39h1M23 39h2M26 39h5M33 39h1M35 39h5M16 40h2M19 40h3M23 40h7M31 40h3M35 40h5M16 41h2M22 41h4M27 41h8M36 41h4M16 42h2M22 42h2M26 42h2M29 42h7M37 42h4M42 42h1M14 43h3M22 43h6M29 43h7M37 43h5M13 44h4M22 44h6M29 44h7M37 44h6M14 45h2M22 45h6M29 45h14M13 46h3M23 46h6M30 46h14M12 47h4M23 47h6M30 47h14M12 48h4M23 48h21M13 49h3M23 49h21" />',
        '<path stroke="#000000" d="M19 5h9M15 6h5M27 6h4M13 7h3M31 7h2M12 8h2M32 8h3M14 9h3M34 9h1M16 10h2M34 10h1M17 11h2M34 11h1M18 12h2M34 12h1M19 13h2M33 13h2M19 14h2M33 14h1M20 15h1M33 15h1M20 16h1M33 16h1M20 17h1M33 17h2M20 18h1M34 18h1M20 19h1M34 19h1M20 20h1M34 20h1M20 21h1M35 21h1M20 22h1M35 22h1M20 23h1M35 23h1M20 24h1M35 24h2M20 25h1M36 25h1M20 26h1M36 26h1M20 27h1M26 27h1M36 27h1M20 28h2M25 28h1M36 28h1M21 29h2M35 29h2M22 30h1M27 30h1M32 30h4M22 31h1M25 31h2M35 31h2M22 32h1M24 32h2M36 32h1M22 33h1M24 33h1M36 33h2M18 34h3M22 34h1M37 34h1M19 35h4M37 35h1M20 36h3M37 36h1M21 37h2M37 37h2M21 38h2M38 38h1M21 39h1M38 39h2M21 40h1M32 40h3M39 40h1M21 41h1M39 41h2M20 42h2M30 42h1M40 42h1M19 43h2M40 43h1M19 44h1M40 44h1M18 45h2M41 45h1M18 46h1M41 46h1M18 47h1M24 47h1M41 47h1M17 48h2M24 48h1M41 48h1M17 49h1M24 49h1M41 49h1" /><path stroke="#c40424" d="M20 6h7M16 7h15M14 8h18M17 9h17M18 10h16M19 11h3M24 11h10M20 12h11M32 12h2M21 13h12M21 14h2M24 14h9M21 15h2M24 15h9M21 16h2M24 16h9M21 17h2M24 17h9M21 18h2M24 18h10M21 19h2M24 19h10M21 20h2M24 20h10M21 21h2M24 21h11M21 22h14M21 23h14M21 24h11M33 24h2M21 25h15M21 26h3M25 26h7M33 26h3M21 27h4M27 27h5M33 27h3M22 28h2M26 28h10M23 29h1M25 29h3M32 29h3M23 30h3M28 30h3M23 31h2M27 31h8M23 32h1M26 32h10M25 33h11M24 34h13M23 35h14M23 36h14M23 37h14M23 38h15M23 39h9M33 39h5M23 40h9M36 40h3M23 41h8M35 41h4M23 42h7M31 42h9M21 43h1M23 43h4M28 43h12M20 44h1M22 44h4M27 44h13M20 45h1M22 45h4M27 45h13M19 46h2M22 46h19M19 47h2M22 47h2M25 47h1M27 47h14M19 48h2M22 48h2M25 48h1M27 48h14M18 49h3M22 49h2M25 49h1M27 49h14" /><path stroke="#7f7f7f" d="M22 11h2M31 12h1M23 14h1M32 24h1M32 26h1M32 27h1M24 29h1M28 29h4M26 30h1M31 30h1M22 39h1M32 39h1M35 40h1M34 41h1M22 42h1M27 43h1M26 44h1M21 45h1M26 45h1M21 46h1M26 47h1M26 48h1M26 49h1" /><path stroke="#454545" d="M23 15h1M23 16h1M23 17h1M23 18h1M23 19h1M23 20h1M31 41h3" /><path stroke="#a1a1a1" d="M23 21h1M24 26h1M25 27h1M24 28h1M23 33h1M23 34h1M22 43h1M21 44h1" /><path stroke="#ffffff" d="M22 40h1M22 41h1M21 47h1M21 48h1M21 49h1" />'
    ];
    string[] private accessory = [
        '" d="M8 47h1M7 48h1M9 48h1M8 49h1M10 49h1M12 49h1" /><path stroke="#808080" d="M7 34h2M18 43h1M17 44h1M13 48h1M6 49h1" /><path stroke="#000000" d="M9 34h2M6 35h3M11 35h1M5 36h2M8 36h2M12 36h1M4 37h2M9 37h2M13 37h1M3 38h2M10 38h2M14 38h1M2 39h2M11 39h2M15 39h1M1 40h2M12 40h2M16 40h1M1 41h1M13 41h2M17 41h1M1 42h2M14 42h2M18 42h1M2 43h2M15 43h3M3 44h2M16 44h1M4 45h2M15 45h2M5 46h4M14 46h2M6 47h2M9 47h1M13 47h2M6 48h1M8 48h1M10 48h1M12 48h1M7 49h1M9 49h1M11 49h1M13 49h1" /><path stroke="#fafafa" d="M9 35h1M11 36h1M12 38h1M14 39h1M14 40h1M16 41h1M16 42h1" /><path stroke="#f8f6f0" d="M10 35h1M10 36h1M11 37h2M13 38h1M13 39h1M15 40h1M15 41h1M17 42h1" /><path stroke="#455a64" d="M7 36h1M6 37h3M5 38h3M9 38h1M4 39h4M9 39h2M3 40h5M9 40h3M2 41h3M6 41h2M9 41h4M3 42h3M7 42h1M9 42h5M4 43h3M8 43h1M14 43h1M5 44h3M9 44h7M6 45h3M10 45h5M9 46h1M11 46h3M10 47h3M11 48h1" /><path stroke="#cd7f32" d="M8 38h1M8 39h1M8 40h1M5 41h1M8 41h1M6 42h1M8 42h1M7 43h1M9 43h5M8 44h1M9 45h1M10 46h1" />'
    ];

    uint256 supplyMinted = 0;

    constructor() ERC721("Pixel", "PIX") {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getBackgroundColor(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        return pickTraits(tokenId, "BACKGROUND", backgroundColors);
    }

    function getBaseColor(uint256 tokenId)
        private
        view
        returns (string memory)
    {
        return pickTraits(tokenId, "BASE", baseColors);
    }

    function getFace(uint256 tokenId) private view returns (string memory) {
        return pickTraits(tokenId, "FACE", face);
    }

    function getMouth(uint256 tokenId) private view returns (string memory) {
        return pickTraits(tokenId, "MOUTH", mouth);
    }

    function getHair(uint256 tokenId) private view returns (string memory) {
        return pickTraits(tokenId, "HAIR", hair);
    }

    function getOutfit(uint256 tokenId) private view returns (string memory) {
        return pickTraits(tokenId, "OUTFIT", outfit);
    }

    function getAcc(uint256 tokenId) private view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked("ACCESSORY", tokenId.toString()))
        );
        uint256 rn = rand % 10;
        string[3] memory parts;

        if (rn < 4) {
            parts[0] = '<path stroke="';
            parts[1] = getBaseColor(tokenId);
            parts[2] = pickTraits(tokenId, "ACCESSORY", accessory);

            return string(abi.encodePacked(parts[0], parts[1], parts[2]));
        } else {
            return "";
        }
    }

    function pickTraits(
        uint256 tokenId,
        string memory parts,
        string[] memory array
    ) private pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(parts, tokenId.toString()))
        );
        string memory output = array[rand % array.length];
        return output;
    }

    function getPixel(uint256 tokenId) private view returns (string memory) {
        string[11] memory parts;
        string memory output;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -0.5 50 50" shape-rendering="crispEdges"><path fill="';
        parts[1] = getBackgroundColor(tokenId);
        parts[2] = '" d="M0 0h50v50H0z"/><path stroke="';
        parts[3] = getBaseColor(tokenId);
        parts[
            4
        ] = '" d="M19 12h8M17 13h11M14 14h15M14 15h16M13 16h18M13 17h19M13 18h19M13 19h19M13 20h19M13 21h19M13 22h19M14 23h18M14 24h18M14 25h14M29 25h3M14 26h14M29 26h3M14 27h13M28 27h4M15 28h11M27 28h5M16 29h9M26 29h6M17 30h7M25 30h7M17 31h5M24 31h8M18 32h2M22 32h12M23 33h12M25 34h10M25 35h10M23 36h12M22 37h14" /><path stroke="#000000" d="M29 14h2M12 15h2M30 15h2M12 16h1M31 16h2M12 17h1M32 17h1M12 18h1M32 18h1M12 19h1M32 19h1M12 20h1M32 20h1M12 21h1M32 21h1M12 22h1M32 22h1M13 23h1M32 23h1M13 24h1M32 24h1M13 25h1M28 25h1M32 25h1M13 26h1M28 26h1M32 26h1M13 27h1M27 27h1M32 27h1M13 28h2M26 28h1M32 28h1M14 29h2M25 29h1M32 29h1M15 30h2M24 30h1M32 30h1M16 31h1M22 31h2M32 31h2M16 32h2M20 32h2M34 32h2M17 33h6M35 33h1M22 34h3M35 34h1M24 35h1M35 35h1M35 36h2M36 37h1" />';
        parts[5] = getFace(tokenId);
        parts[6] = getMouth(tokenId);
        parts[7] = getHair(tokenId);
        parts[8] = getOutfit(tokenId);
        parts[9] = getAcc(tokenId);
        parts[10] = "</svg>";

        output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[6],
                parts[7],
                parts[8],
                parts[9],
                parts[10]
            )
        );

        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory json;
        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "TestPixel #',
                        tokenId.toString(),
                        '", "description": "testing123", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(getPixel(tokenId))),
                        '"}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));
        return json;
    }

    function mint() external {
        supplyMinted += 1;
        _safeMint(msg.sender, supplyMinted);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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