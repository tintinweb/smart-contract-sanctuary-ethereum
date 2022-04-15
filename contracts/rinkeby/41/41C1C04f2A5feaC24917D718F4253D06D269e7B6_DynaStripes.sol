// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC2981/ERC2981PerTokenRoyalties.sol";
import "./DynaTokenBase.sol";
import "./ColourWork.sol";
import "./StringUtils.sol";
import "./DynaModel.sol";
import "./DynaTraits.sol";

contract DynaStripes is DynaTokenBase, ERC2981PerTokenRoyalties {
    uint16 public constant TOKEN_LIMIT = 1119; // first digits of "dyna" in ascii: (100 121 110 97) --> 1119
    uint16 public constant ROYALTY_BPS = 1000;
    uint16 private tokenLimit = 100;
    mapping(uint16 => DynaModel.DynaParams) private dynaParamsMapping;
    mapping(uint24 => bool) private usedRandomSeeds;
    uint256 private mintPrice = 0.01 ether;

    constructor() DynaTokenBase("DynaStripes55", "DS55") { }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(DynaTokenBase, ERC2981PerTokenRoyalties)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // for OpenSea
    function contractURI() public pure returns (string memory) {
        return "https://www.dynastripes.com/storefront-metadata";
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getTokenLimit() public view returns (uint16) {
        return tokenLimit;
    }
    function setTokenLimit(uint16 limit) public onlyOwner {
        if (limit > TOKEN_LIMIT) {
            limit = TOKEN_LIMIT;
        }
        tokenLimit = limit;
    }

    function payOwner(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Amount too high");
        address payable owner = payable(owner());
        owner.transfer(amount);
    }

    receive() external payable { }

    function mintStripes(uint24 randomSeed, 
                         uint8 zoom,
                         uint8 tintRed,
                         uint8 tintGreen,
                         uint8 tintBlue,
                         uint8 tintAlpha,
                         uint16 rotationDegrees, 
                         uint8 rotationRange, 
                         uint8 stripeWidthMin, 
                         uint8 stripeWidthMax, 
                         uint8 speedMin, 
                         uint8 speedMax) public payable {
        require(_currentIndex < tokenLimit && _currentIndex < TOKEN_LIMIT, "Token limit reached");
        require(msg.value >= mintPrice, "Not enough ETH");
        require(zoom <= 100, "bad zoom");
        require(tintRed <= 255 && tintGreen <= 255 && tintBlue <= 255 && tintAlpha < 230, "bad color");
        require(rotationDegrees <= 360 && rotationRange <= 180, "bad rotation");
        require(stripeWidthMin >= 25 && stripeWidthMax <= 250 && stripeWidthMin <= stripeWidthMax, "bad stripe width");
        require(speedMin >= 25 && speedMax <= 250 && speedMin <= speedMax, "bad speed");
        require(randomSeed < 5000000 && usedRandomSeeds[randomSeed] == false, "bad random seed");

        // this should be safe given only 1119 tokens
        uint16 tokenId = uint16(_currentIndex);

        _setTokenRoyalty(tokenId, msg.sender, ROYALTY_BPS);
        dynaParamsMapping[tokenId] = DynaModel.DynaParams(randomSeed, zoom, tintRed, tintGreen, tintBlue, tintAlpha, rotationDegrees, rotationRange, stripeWidthMin, stripeWidthMax, speedMin, speedMax);
        _safeMint(msg.sender, 1);
        usedRandomSeeds[randomSeed] = true;
    }

    function banRandomSeeds(uint24[] memory seeds) public onlyOwner {
        for (uint i; i < seeds.length; i++) {
            usedRandomSeeds[seeds[i]] = true;
        }
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(_tokenId), "ID doesn't exist");
        require(_tokenId < TOKEN_LIMIT, "ID doesn't exist");

        // string memory name = DynaTraits.getName(dynaParamsMapping[uint16(_tokenId)]);
        // string memory copyright = string(abi.encodePacked("\"copyright\": \"Holder of this NFT owns its copyright. Sale of this NFT assigns copyright to buyer. Buyer & seller agree payment of royalty to minter on sale.\""));
        // string memory traits = DynaTraits.getTraits(dynaParamsMapping[uint16(_tokenId)]);
        // string memory svg = generateSvg(_tokenId);

        // return "https://s3.eu-west-1.amazonaws.com/eu.raaza.net/dynasample.json";
        // return "https://mumbai.dynastripes.com/dynasample";
        return "data:application/json;base64,eyJuYW1lIjogIkRTUyBYWCIsICJkZXNjcmlwdGlvbiI6ICJBIGxvdmVseSBEeW5hU3RyaXBlcyB3b3JrLiIsICJhdHRyaWJ1dGVzIjogW3siaXNzdWUiOiAiZm91cnRoIn1dLCAiaW1hZ2UiOiAiaHR0cHM6Ly93d3cuZHluYXN0cmlwZXMuY29tL2R5bmFzYW1wbGUuc3ZnIn0KCg==";
          
        // return string(abi.encodePacked(
        //     "data:text/plain,{\"name\":\"DS #", 
        //     StringUtils.uintToString(_tokenId), 
        //     ": ",
        //     name,
        //     "\", \"description\": \"on-chain generative DynaStripes artwork\", ", 
        //     copyright, 
        //     // ", ", 
        //     traits, 
        //     ", \"image\":\"http://www.dynastripes.com/dynasample.svg\"}"
        //     // ", \"image\":\"data:image/svg+xml,", 
        //     // svg, 
        //     // "\"}"
        // )); 
    }
    
    function generateSvg(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId) && tokenId < TOKEN_LIMIT, "bad token ID");

        DynaModel.DynaParams memory dynaParams = dynaParamsMapping[uint16(tokenId)];
        (string memory viewBox, string memory clipRect) = getViewBoxClipRect(dynaParams.zoom);
        string memory rendering = dynaParams.rotationRange == 0 ? "crispEdges" : "auto";
        string memory defs = string(abi.encodePacked("<defs><clipPath id='masterClip'><rect ", clipRect, "/></clipPath></defs>"));
        string memory rects = getRects(dynaParams);

        return string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='", viewBox, "' shape-rendering='", rendering, "'>", defs, "<g clip-path='url(#masterClip)'>", rects, "</g></svg>"));
    }

    function getViewBoxClipRect(uint zoom) private pure returns (string memory, string memory) {
        zoom = zoom * 20;
        string memory widthHeight = StringUtils.uintToString(1000 + zoom);

        if (zoom > 1000) {
            string memory offset = StringUtils.uintToString((zoom - 1000) / 2);
            string memory viewBox = string(abi.encodePacked("-", offset, " -", offset, " ",  widthHeight, " ", widthHeight));
            string memory clipRect = string(abi.encodePacked("x='-", offset, "' y='-", offset, "' width='",  widthHeight, "' height='", widthHeight, "'"));
            return (viewBox, clipRect);
        } else {
            string memory offset = StringUtils.uintToString((zoom == 1000 ? 0 : (1000 - zoom) / 2));
            string memory viewBox = string(abi.encodePacked(offset, " ", offset, " ",  widthHeight, " ", widthHeight));
            string memory clipRect = string(abi.encodePacked("x='", offset, "' y='", offset, "' width='",  widthHeight, "' height='", widthHeight, "'"));

            return (viewBox, clipRect);
        }
    }

    function getRects(DynaModel.DynaParams memory dynaParams) private pure returns (string memory) {
        uint randomSeed = dynaParams.randomSeed;
        uint xPos = 0;
        string memory rects = "";

        while ((2000 - xPos) > 0) {

            uint stripeWidth = randomIntFromInterval(randomSeed, dynaParams.stripeWidthMin, dynaParams.stripeWidthMax) * 2;
    
            if (stripeWidth > 2000 - xPos) {
                stripeWidth = 2000 - xPos;
            } else if ((2000 - xPos) - stripeWidth < dynaParams.stripeWidthMin) {
                stripeWidth += (2000 - xPos) - stripeWidth;
            }

            string memory firstColour = getColour(randomSeed + 3, dynaParams);
            string memory colours = string(abi.encodePacked(firstColour, ";", getColour(randomSeed + 13, dynaParams), ";", firstColour));
            
            rects = string(abi.encodePacked(rects, "<rect x='", StringUtils.uintToString(xPos), "' y='0' width='", StringUtils.uintToString(stripeWidth), "' height='2000' fill='", firstColour, "' opacity='0.8'", " transform='rotate(",  getRotation(randomSeed + 1, dynaParams), " 1000 1000)'><animate begin= '0s' dur='", getSpeed(randomSeed + 2, dynaParams), "ms' attributeName='fill' values='", colours, ";' fill='freeze' repeatCount='indefinite'/></rect>"));
            
            xPos += stripeWidth;
            randomSeed += 100;
        }

        return rects; 
    }

    function getRotation(uint randomSeed, DynaModel.DynaParams memory dynaParams) private pure returns (string memory) {
        uint randomDegrees = randomIntFromInterval(randomSeed, 0, dynaParams.rotationRange);
        uint rotation;

        if (randomDegrees == 0) {
            rotation = dynaParams.rotationDegrees;
        } else if (randomDegrees < dynaParams.rotationRange) {
            rotation = 360 + dynaParams.rotationDegrees - randomDegrees + dynaParams.rotationRange / 2; 
        } else {
            rotation = dynaParams.rotationDegrees + randomDegrees - dynaParams.rotationRange / 2;
        }
        if (rotation > 360) {
            rotation = rotation - 360;
        }

        return StringUtils.uintToString(rotation);
    }

    function getSpeed(uint randomSeed, DynaModel.DynaParams memory dynaParams) private pure returns (string memory) {
        uint speed = randomIntFromInterval(randomSeed, dynaParams.speedMin, dynaParams.speedMax) * 20;
        return StringUtils.uintToString(speed);
    }

    function getColour(uint _randomSeed, DynaModel.DynaParams memory _dynaParams) private pure returns (string memory) {
        uint red = ColourWork.safeTint(randomIntFromInterval(_randomSeed, 0, 255), _dynaParams.tintRed, _dynaParams.tintAlpha);
        uint green = ColourWork.safeTint(randomIntFromInterval(_randomSeed + 1, 0, 255), _dynaParams.tintGreen, _dynaParams.tintAlpha);
        uint blue = ColourWork.safeTint(randomIntFromInterval(_randomSeed + 2, 0, 255), _dynaParams.tintBlue, _dynaParams.tintAlpha);

        return ColourWork.rgbString(red, green, blue);        
    }

    // ----- Utils

    function randomIntFromInterval(uint randomSeed, uint min, uint max) private pure returns (uint) {
        if (max <= min) {
            return min;
        }

        uint seed = uint(keccak256(abi.encode(randomSeed)));
        return uint(seed % (max - min)) + min;
    }
}

// Love you John, Christine, Clara and Lynus! 😁❤️

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './IERC2981Royalties.sol';

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties {
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        _royalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract DynaTokenBase is ERC721A, Ownable, Pausable {

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity)
        internal
        whenNotPaused
        override(ERC721A)
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // For OpenSea support
    
    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721A.isApprovedForAll(_owner, _operator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./StringUtils.sol";

library ColourWork {

    function safeTint(uint colourComponent, uint tintComponent, uint alpha) internal pure returns (uint) {        
        unchecked {
            if (alpha == 0) {
                return uint8(colourComponent);
            }
            uint safelyTinted;

            if (colourComponent <= tintComponent) {
                uint offset = ((tintComponent - colourComponent) * alpha) / 255; 
                safelyTinted = colourComponent + offset;            
            } else {
                uint offset = ((colourComponent - tintComponent) * alpha) / 255; 
                safelyTinted = colourComponent - offset;
            }

            return uint8(safelyTinted);            
        }
    }   

    function rgbString(uint red, uint green, uint blue) internal pure returns (string memory) {
        return string(abi.encodePacked("rgb(", StringUtils.smallUintToString(red), ", ", StringUtils.smallUintToString(green), ", ", StringUtils.smallUintToString(blue), ")"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library StringUtils {
    function uintToString(uint _i) internal pure returns (string memory str) {
        unchecked {
            if (_i == 0) {
                return "0";
            }

            uint j = _i;
            uint length;
            while (j != 0) {
                length++;
                j /= 10;
            }

            bytes memory bstr = new bytes(length);
            uint k = length;
            j = _i;
            while (j != 0) {
                bstr[--k] = bytes1(uint8(48 + j % 10));
                j /= 10;
            }
            
            str = string(bstr);
        }
    }

    // ONLY TO BE USED FOR 8 BIT INTS! Not specifying type to save gas
    function smallUintToString(uint _i) internal pure returns (string memory) {
        require(_i < 256, "input too big");
        unchecked {
            if (_i == 0) {
                return "0";
            }

            bytes memory bstr;

            if (_i < 10) {
                // 1 byte
                bstr = new bytes(1);

                bstr[0] = bytes1(uint8(48 + _i % 10));

            } else if (_i < 100) {
                // 2 bytes
                bstr = new bytes(2);
                bstr[1] = bytes1(uint8(48 + _i % 10));
                bstr[0] = bytes1(uint8(48 + (_i / 10) % 10));
            } else {
                // greater than 100
                bstr = new bytes(3);
                bstr[2] = bytes1(uint8(48 + _i % 10));
                bstr[1] = bytes1(uint8(48 + (_i / 10) % 10));
                bstr[0] = bytes1(uint8(48 + (_i / 100) % 10));
            }
        return string(bstr);
        }
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library DynaModel {
    struct DynaParams {
        uint24 randomSeed;
        uint8 zoom; // 0 - 100
        uint8 tintRed; // 0 - 255
        uint8 tintGreen; // 0 - 255
        uint8 tintBlue; // 0 - 255
        uint8 tintAlpha; // 0 - 255
        uint16 rotationDegrees; // 0 - 360
        uint8 rotationRange; // 0 - 180
        uint8 stripeWidthMin; // 25 - 250
        uint8 stripeWidthMax; // 25 - 250
        uint8 speedMin; // 25 - 250 
        uint8 speedMax; // 25 - 250
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./DynaModel.sol";
import "./StringUtils.sol";

library DynaTraits {

    function getTraits(DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {
        // string memory zoomTraits = string(abi.encodePacked("{\"trait_type\": \"zoom\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.zoom), "}")); 
        // string memory tintTraits = string(abi.encodePacked("{\"trait_type\": \"tint red\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.tintRed), "}, {\"trait_type\": \"tint green\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.tintGreen), "}, {\"trait_type\": \"tint blue\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.tintBlue), "}, {\"trait_type\": \"tint alpha\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.tintAlpha), "}")); 
        // string memory rotationTraits = string(abi.encodePacked("{\"trait_type\": \"rotation degrees\", \"display_type\": \"number\", \"value\": ", StringUtils.uintToString(dynaParams.rotationDegrees), "}, {\"trait_type\": \"rotation range\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.rotationRange), "}")); 
        // string memory widthTraits = string(abi.encodePacked("{\"trait_type\": \"stripe width min\",  \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.stripeWidthMin), "}, {\"trait_type\": \"stripe width max\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.stripeWidthMax), "}"));
        // string memory speedTraits = string(abi.encodePacked("{\"trait_type\": \"speed min\", \"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.speedMin), "}, {\"trait_type\": \"speed max\",\"display_type\": \"number\", \"value\": ", StringUtils.smallUintToString(dynaParams.speedMax), "}"));

        // string memory descriptiveTraits = getTextTraits(dynaParams);      
        return "\"attributes\":[{\"issue\": \"second\"}]";
        // return string(abi.encodePacked(
        //     "\"attributes\": [", 
        //     descriptiveTraits, 
        //     ",",
        //     zoomTraits, 
        //     ", ", 
        //     tintTraits, 
        //     ", ", 
        //     rotationTraits, 
        //     ", ", 
        //     widthTraits, 
        //     ", ", 
        //     speedTraits, 
        //     "]"
        // ));    
    }

    function getTextTraits(DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {
        string memory speed = getSpeed(dynaParams.tintAlpha, dynaParams.speedMin, dynaParams.speedMax);        
        string memory color = getColor(dynaParams.tintRed, dynaParams.tintGreen, dynaParams.tintBlue, dynaParams.tintAlpha);
        string memory form = getForm(dynaParams.zoom, dynaParams.rotationDegrees, dynaParams.rotationRange, dynaParams.stripeWidthMin, dynaParams.stripeWidthMax);

        return string(abi.encodePacked(
            "{\"trait_type\": \"speed\", \"value\": \"", 
            speed, 
            "\"}, {\"trait_type\": \"color\", \"value\": \"", 
            color, 
            "\"}, {\"trait_type\": \"form\", \"value\": \"", 
            form, 
            "\"}"
        ));
    }

    function getName(DynaModel.DynaParams memory dynaParams) internal pure returns (string memory) {

        return string(abi.encodePacked(
            getSpeed(dynaParams.tintAlpha, dynaParams.speedMin, dynaParams.speedMax), 
            " ", 
            getColor(dynaParams.tintRed, dynaParams.tintGreen, dynaParams.tintBlue, dynaParams.tintAlpha), 
            " ", 
            getForm(dynaParams.zoom, dynaParams.rotationDegrees, dynaParams.rotationRange, dynaParams.stripeWidthMin, dynaParams.stripeWidthMax)));
    }

    function getSpeed(
                uint8 alpha,
                uint8 min, 
                uint8 max) private pure returns (string memory) { 

        string memory speed;

        if (alpha > 130 && min > 220) {
            speed = "languid";
        } else if (alpha > 130 && min > 200) {
            speed = "pedestrian";
        } else {
            if (max <= 25 && alpha < 180) {
                speed = "manic";
            } else if (min == max) {
                if (max < 30) {
                    speed = "blinking";
                } else if (max > 200) {
                    speed = "throbbing";
                } else {
                    speed = "pulsing";        
                }
            } else if (max < 35) {
                speed = "flashing";
            } else if (max < 70) {
                speed = "flickering";
            } else if (max < 105) {
                speed = "quivering";
            } else if (max < 150) {
                speed = "vibrating";
            } else if (min > 200) {
                speed = "meandering";
            } else if (min > 150) {
                speed = "drifting";
            } else if (min > 120) {
                speed = "flowing";
            } else if (min > 100) {
                speed = "shifting";
            } else if (max - min > 150) {
                speed = "scintillating";        
            } else {
                speed = "oscillating"; 
            } 

            if (alpha > 213) {
                speed = string(abi.encodePacked("gently ", speed));
            } else if (alpha > 200) {
                speed = string(abi.encodePacked("tepidly ", speed));
            } else if (alpha < 20) {
                speed = string(abi.encodePacked("magnificently ", speed));
            } else if (alpha < 50) {
                speed = string(abi.encodePacked("powerfully ", speed));
            }    
        }

        return speed;
    }

    function getColor(
                    uint8 red,
                    uint8 green,
                    uint8 blue,
                    uint8 alpha) private pure returns (string memory) { 

        string memory color; 

        if (alpha > 127) {
            uint difference = 150;
            if (alpha > 200 && red < 50 && green < 50 && blue < 50) {
                color = "gloomy";
            } else if (alpha > 200 && red > 200 && green > 200 && blue > 200) {
                color = "pale";
            } else if (red > green && red - green >= difference && red > blue && red - blue >= difference) {
                color = "red";
            } else if (green > red && blue == 0) {
            color = "green";
            } else if (green > red && green - red >= difference && green > blue && green - blue >= difference) {
                color = "green";
            } else if (blue > red && blue - red >= difference && blue > green && blue - green >= difference) {
                color = "blue";
            } else if (red == 255 && green == 0 && blue > 100) {
                color = "pink";
	        } else if (red > green && red - green >= difference && blue > green && blue - green >= difference && red > 200) {
                color = "purple";
            } else if (red == 255 && blue == 0 && green > 200) {
                color = "yellow";
            } else if (red == 255 && blue == 0) {
                color = "orange";
            } else if (red == 0 && green < 200 && blue == 255) {
                color = "blue";
            } else if (blue > red && blue - red >= difference && green > red && green - red >= difference) {
                color = "cyan";
            } else {
                color = "saturated";
            }
        } else if (alpha == 0) {
            color = "kaleidoscopic";
        } else if (alpha < 25) {
            color = "chromatic";
        } else if (alpha < 50) {
            color = "vivid";
        } else if (alpha < 85) {
            color = "tinged";
        } else {
            color = "tinted"; // medium tint
        }

        return color;
    }

    function getForm(
                    uint8 zoom,
                    uint16 rotationDegrees, 
                    uint8 rotationRange, 
                    uint8 widthMin, 
                    uint8 widthMax) internal pure returns (string memory) { 

        string memory form;
        rotationDegrees = rotationDegrees % 180; // forms rotated 180 degrees are same

        if (rotationRange == 0) {
            if (zoom > 50 && rotationDegrees % 90 == 0) {
                form = "perfect square";
            } else if (zoom > 91 && (rotationDegrees == 45 || rotationDegrees == 135)) {
                form = "perfect diamond";
            } else if (zoom <= 50 && rotationDegrees == 0) {
                form = "vertical stripes";
            } else if (zoom <= 50 && rotationDegrees % 90 == 0) {
                form = "horizontal stripes";
            } else if (zoom <= 25) {
                form = "diagonal stripes";
            } else {
                form = "rotated square";
            }
        } else if (zoom < 30) {
            if (zoom < 20 && widthMin > 70 && rotationRange < 60 && rotationRange > 10) {
                form = "ribbons";
            } else if ( zoom < 20 && rotationRange < 30 && widthMin > 200) {
                form = "banners";
            } else if (zoom < 20 && widthMax < 75 && rotationRange < 60 && rotationRange > 10) {
                form = "streamers";
            } else if (widthMax < 60 && rotationRange > 130) {
                form = "laser beams";
            } else if (widthMax < 120 && rotationDegrees >= 45 && rotationDegrees < 135) {
                form = "beams";
            } else if (widthMax < 120 && rotationRange < 90) {
                form = "poles";
            } else if (rotationDegrees >= 45 && rotationDegrees < 135) {
                form = "streaks";
            } else { // rotation < 45 || rotation > 135
                form = "shafts";
            }
        } else if (zoom > 50 && widthMax < 60 && rotationRange < 30) {
            form = "match sticks";
        } else if (zoom > 50 && widthMax < 60 && rotationRange < 60) {
            form = "scattered match sticks";
        } else if (zoom > 50 && widthMin > 70 && widthMax < 110 && rotationRange > 10 && rotationRange < 40) {
            form = "twigs";
        } else if (zoom > 50 && widthMin > 70 && widthMax < 110 && rotationRange > 10 && rotationRange < 60) {
            form = "scattered twigs";
        } else if (zoom > 80 &&widthMax < 60 && rotationRange > 130) {
            form = "birds nest";
        } else if ( zoom > 70 && rotationRange < 70 && widthMin > 200 && (rotationDegrees <= 25 || rotationDegrees >= 155)) {
            form = "pillars";
        } else if ( zoom > 70 && rotationRange < 70 && widthMin > 200 && (rotationDegrees <= 115 && rotationDegrees >= 65)) {
            form = "bricks";
        } else if (zoom > 55 && widthMin > 70 && rotationRange >= 5 && rotationRange <= 30 && (rotationDegrees <= 10 || rotationDegrees >= 170)) {
            form = "cluttered books";
        } else if (zoom > 55 && widthMin > 70 && rotationRange <= 30 && rotationDegrees >= 80 && rotationDegrees <= 100) {
            form = "stacked books";
        } else if (zoom > 55 && widthMin > 70 && rotationRange < 60 && rotationDegrees >= 50 && rotationDegrees <= 130) {
            form = "tumbling books";
        } else if (zoom > 55 && widthMin > 50 && widthMax < 150 && rotationRange < 50 && rotationDegrees >= 80 && rotationDegrees <= 100) {
            form = "broken ladder";
        } else if (zoom > 55 && rotationRange > 10 && rotationRange < 60 && rotationDegrees >= 50 && rotationDegrees <= 130 && widthMax - widthMin >= 150) {
            form = "collapsing building";
        } else if (widthMin > 25 && widthMax < 200 && rotationRange <= 15) {
            form = "jitters";
        } else if (widthMin > 25 && widthMax < 200 && rotationRange <= 45) {
            form = "wobbles";
        } else if ( zoom > 50 && widthMin > 200) {
            form = "blocks";
        } else if ( zoom > 90 && widthMax - widthMin >= 150 && rotationRange > 150) {
            form = "masterpiece";
        } else if (rotationRange > 100 && widthMax < 150) {
            form = "lunacy";
        } else if (rotationRange < 60 && widthMin > 150) {
            form = "tranquility";
        } else if (widthMin > 120) {
            form = "bars";
        } else if (widthMax < 100 && rotationRange > 60) {
            form = "scattered lines";
        } else if (widthMax < 100) {
            form = "lines";
        } else if (zoom > 40 && rotationRange > 90) {
            form = "reverie";
        } else {
            form = "abstraction";
        }

        return form;
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    // Compiler will pack the following 
    // _currentIndex and _burnCounter into a single 256bit word.
    
    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // The number of tokens burned.
    uint128 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = uint128(updatedIndex);
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked { 
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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