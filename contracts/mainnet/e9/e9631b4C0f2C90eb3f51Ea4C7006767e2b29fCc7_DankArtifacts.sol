// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";

interface IDankElements{
    function totalSupply() external view returns (uint);
    function getPurity(uint) external view returns (uint);
    function getEnergy(uint) external view returns (uint);
    function singularitySeed() external view returns (uint);
}

contract DankArtifacts is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    int constant textureSize = 32;
    int constant textureSizeHalf = textureSize/2;
    uint constant paletteSize = 16;
    address public dankElementsAddress;
    Artifact[] artifacts;

    struct Artifact {
        string name;
        string chapterName;
        string text;
        bool isLegendary;
        bytes colorTable;
        bytes pixels;
    }

    struct HSLColor
    {
        uint h;
        uint s;
        uint l;
    }

    struct Bounds
    {
        uint xMin;
        uint xMax;
        uint yMin;
        uint yMax;
    }

    constructor() ERC721("Dank Artifacts", "Dank Artifacts") {
    }

    function setDankElementsAddress (address _dankElementsAddress) public onlyOwner {
        require (dankElementsAddress == address(0), "Dank Elements contract address has already been set");
        dankElementsAddress = _dankElementsAddress;
    }

    function getElementTotalSupply () internal view returns (uint) {
        return IDankElements(dankElementsAddress).totalSupply();
    }

    function getSingularitySeed () internal view returns (uint) {
        return IDankElements(dankElementsAddress).singularitySeed();
    }

    function getElementPurity (uint tokenId) internal view returns (uint) {
        return IDankElements(dankElementsAddress).getPurity(tokenId);
    }

    function getElementEnergy (uint tokenId) internal view returns (uint) {
        return IDankElements(dankElementsAddress).getEnergy(tokenId);
    }
    
    function auraKnown (uint tokenId) public view returns (bool) {
        return artifacts[tokenId].isLegendary || (dankElementsAddress != address(0) && getSingularitySeed() != 0);
    }

    function getAura (uint tokenId) public view returns (uint) {
        if (auraKnown(tokenId)) {
            if (artifacts[tokenId].isLegendary) {
                return 100;
            }
            else {
                return (getElementPurity(tokenId) + getElementEnergy(tokenId)) / 2;
            }
        }
        return 0;
    }

    function safeMint(address to, Artifact memory artifact) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require (dankElementsAddress == address(0) || getSingularitySeed() == 0 || tokenId < getElementTotalSupply(), "Supply would exceed that of Dank Elements");
        artifacts.push(artifact);
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function getSVG (uint tokenId) public view returns (string memory) {

        Artifact memory artifact = artifacts[tokenId];

        string memory output = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMidYMid meet' viewBox='-240 -231 480 480'>",
                "<defs>",
                "<linearGradient id='glareGradient' x1='0' x2='0' y1='0' y2='1'>",
                "<stop offset='0%'  stop-color='white' stop-opacity='100%'/>",
                "<stop offset='100%' stop-color='white' stop-opacity='0'/>",
                "</linearGradient>",
                "</defs>"
            )
        );
        output = string(
            abi.encodePacked(
                output,
                "<style>",
                ".rotary, .sides g, .top g {animation-timing-function: ease-in-out; animation-iteration-count: infinite; animation-direction: alternate; animation-duration: 4s;}",
                ".sides g {animation-name:sideAnim;}",
                ".top g {animation-name:topAnim;}",
                "@keyframes frontAnim {from {transform: rotateX(-10deg) rotateY(35deg) translateZ(-0.04px);} to {transform: rotateX(-10deg) rotateY(-35deg) translateZ(-0.04px);}}",
                "@keyframes sideAnim {from {transform: rotateX(-10deg) rotateY(125deg) translateZ(var(--t));} to {transform: rotateX(-10deg) rotateY(55deg) translateZ(var(--t));}}",
                "@keyframes topAnim {from {transform: rotateX(80deg) rotateZ(145deg) translateZ(var(--t));} to {transform: rotateX(80deg) rotateZ(215deg) translateZ(var(--t));}}",
                "@keyframes lightingAnim {0% { fill-opacity: 0.0; fill:url(#glareGradient);} 15% { fill-opacity: 0.0; fill:url(#glareGradient);} 30% { fill-opacity: 0.15; fill:url(#glareGradient);} 50% { fill-opacity: 0.0; fill:url(#glareGradient);} 55% { fill-opacity: 0.0; fill:black;} 100% { fill-opacity: 0.25; fill:black;}}"
            )
        );

        Bounds memory bounds = Bounds(uint8(artifact.pixels[0]), uint8(artifact.pixels[1]), uint8(artifact.pixels[2]), uint8(artifact.pixels[3]));
        
        uint colorTableLength = artifact.colorTable.length / 3;
        string[paletteSize] memory theFace;
        string[textureSize+1] memory theSide;
        string[textureSize] memory theTop;
        HSLColor[paletteSize] memory palette;
        for (uint i = 0; i < paletteSize; i++) {
            if (i < colorTableLength) {
                palette[i] = HSLColor(uint(uint8(artifact.colorTable[i * 3 + 0]))*360/255, uint(uint8(artifact.colorTable[i * 3 + 1]))*100/255, uint(uint8(artifact.colorTable[i * 3 + 2]))*100/255); 
                theFace[i] = string(abi.encodePacked("<g fill='hsl(", Strings.toString(palette[i].h), ",", Strings.toString(palette[i].s), "%,", Strings.toString(palette[i].l), "%)'>"));
                output = string(abi.encodePacked(output, ".d", Strings.toString(i), "{fill:hsl(", Strings.toString(palette[i].h), ",", Strings.toString(palette[i].s), "%,", toString(mathMax(0, int(palette[i].l)-20)), "%)}"));
                output = string(abi.encodePacked(output, ".l", Strings.toString(i), "{fill:hsl(", Strings.toString(palette[i].h), ",", Strings.toString(palette[i].s), "%,", toString(mathMin(100, int(palette[i].l)+20)), "%)}"));
            }
            else {
                break;
            }
        }
        output = string(
            abi.encodePacked(
                output,
                "</style>",
                "<g shape-rendering='crispEdges' transform='scale(10)'>"
            )
        );
        string memory lightingString = "<path d='";

        for (uint y = bounds.yMin; y <= bounds.yMax; y++)
        {
            uint lightWidth;
            for (uint x = bounds.xMin; x <= bounds.xMax; x++)
            {
                uint curIndex = x-bounds.xMin + (y-bounds.yMin)*(1+bounds.xMax-bounds.xMin);
                uint8 colorIndex = indexToNibble(artifact.pixels, curIndex);

                if (palette[colorIndex].l != 100)
                {
                    theFace[colorIndex] = string(abi.encodePacked(theFace[colorIndex], "<path d='M", toString(int(x)-textureSizeHalf), ",", toString(textureSizeHalf-int(y)), "h1v1h-1z'/>"));
                    if (lightWidth == 0) {
                        lightingString = string(abi.encodePacked(lightingString, "M", toString(int(x)-textureSizeHalf), ",", toString(textureSizeHalf-int(y))));
                    }

                    if (x == bounds.xMin || palette[indexToNibble(artifact.pixels, curIndex-1)].l == 100) {
                        theSide[x] = string(abi.encodePacked(theSide[x], "<path class='d", Strings.toString(colorIndex), "' d='M0", ",", toString(textureSizeHalf-int(y)), "h1v1h-1z'/>"));
                    }
                    if (x == bounds.xMax || palette[indexToNibble(artifact.pixels, curIndex+1)].l == 100) {
                        theSide[x+1] = string(abi.encodePacked(theSide[x+1], "<path class='d", Strings.toString(colorIndex), "' d='M0", ",", toString(textureSizeHalf-int(y)), "h1v1h-1z'/>"));
                        lightingString = string(abi.encodePacked(lightingString, "h", Strings.toString(lightWidth+1), ",v1,h-", Strings.toString(lightWidth+1)));
                        lightWidth = 0;
                    }
                    else {
                        lightWidth++; 
                    }
                    if (y == bounds.yMax || palette[indexToNibble(artifact.pixels, curIndex + (1+bounds.xMax-bounds.xMin))].l == 100) {
                        theTop[y] = string(abi.encodePacked(theTop[y], "<path class='l", Strings.toString(colorIndex), "' d='M", toString(textureSizeHalf-int(x)-1), ",0h1v1h-1z'/>"));
                    }
                }
            }
        }
        lightingString = string(abi.encodePacked(lightingString, "' class='rotary' style='fill:url(#glareGradient); animation-name: lightingAnim; fill:url(#glareGradient);'></path>"));

        output = string(abi.encodePacked(output, "<g class='sides'>"));
        for (int i = 0; i < textureSize+1; i++) {
            if (bytes(theSide[uint(i)]).length != 0) {
                output = string(abi.encodePacked(output, "<g style='--t: ", toString(i - textureSizeHalf), "px;'>", theSide[uint(i)], "</g>"));
            }
        }
        output = string(abi.encodePacked(output, "</g>"));

        output = string(abi.encodePacked(output, "<g class='top'>"));
        for (int i = 0; i < textureSize; i++) {
            if (bytes(theTop[uint(i)]).length != 0) {
                output = string(abi.encodePacked(output, "<g style='--t: ", toString(i - textureSizeHalf), "px;'>", theTop[uint(i)], "</g>"));
            }
        }
        output = string(abi.encodePacked(output, "</g>"));

        output = string(abi.encodePacked(output, "<g class='rotary' style='animation-name:frontAnim;'>"));
        for (uint i = 0; i < paletteSize; i++) {
            if (i < colorTableLength) {
                output = string(abi.encodePacked(output, theFace[i], "</g>"));
            } else {
                break;
            }
        }
        output = string(abi.encodePacked(output, lightingString, "</g></g></svg>"));
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        Artifact memory artifact = artifacts[tokenId];

        string memory auraProperty;
        if (auraKnown(tokenId)) {
            auraProperty = string(abi.encodePacked('{"trait_type": "Aura", "value": ', Strings.toString(getAura(tokenId)), ', "max_value": 100}'));
        }
        else {
            auraProperty = string(abi.encodePacked('{"trait_type": "Aura", "value": "TBD"}'));
        }

        string memory legendaryProperty;
        if (artifact.isLegendary) {
            legendaryProperty = ', {"value": "legendary"}';
        }
        string memory attributes = string(abi.encodePacked('"attributes": [', auraProperty, legendaryProperty, ']}'));
        
        string memory output = string(
            abi.encodePacked(
                '{"name": "', artifact.name, ' (Chapter ', Strings.toString(tokenId), ')", ',
                '"description": "# Chapter ', Strings.toString(tokenId), ': ', artifact.chapterName, '\\n\\n', artifact.text, '", ',
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(tokenId))), '", ',
                attributes
            )
        );
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(bytes(output))
            )
        );
    }

    function indexToNibble (bytes memory pixels, uint index) private pure returns (uint8) {
        uint8 thing = uint8(pixels[index / 2 + 4]);
        if (index%2 == 0) {
            return thing >>4;
        }
        return thing & 0x0F;
    }

    function mathMax(int a, int b) private pure returns (int) {
        return a > b ? a : b;
    }
    function mathMin(int a, int b) private pure returns (int) {
        return a < b ? a : b;
    }

    function toString(int value) internal pure returns (string memory) {
        if (value < 0) {
             return string(abi.encodePacked("-", Strings.toString(uint(value * -1))));
        }
        return Strings.toString(uint(value));
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}