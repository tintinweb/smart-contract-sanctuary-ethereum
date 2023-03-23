// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Strings.sol";
import "./base64.sol";

contract ONCHAINDOTTING is ERC721A {
    address public owner;

    uint256 public maxSupply = 5555;

    uint256 public maxMint = 30;

    uint256 public maxFreePerTx = 2;

    uint256 public mintPrice = 0.001 ether;

    uint256 public maxBalance = 30;
    
    bool public initialized; 

    bool public operatorFilteringEnabled;

    function mintPublic(uint256 tokenQuantity) public payable {
        require(
            tokenQuantity <= maxMint, 
            "Mint too many tokens at a time"
        );
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            totalSupply() + tokenQuantity <= maxSupply,
            "Sale would exceed max supply"
        );
        uint256 money = mintPrice;
        uint256 quantity = tokenQuantity;
        _safeMint(_msgSenderERC721A(), quantity, money);
    }

    function teamMint(address addr, uint256 tokenQuantity) public onlyOwner {
        require(
            totalSupply() + tokenQuantity <= maxSupply,
            "Sale would exceed max supply"
        );
        address to = addr;
        uint256 quantity = tokenQuantity;
        _safeMint(to, quantity);
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        super.initial("ONCHAIN DOTTING", "DOTTING");
        owner = tx.origin;
    }

    function setMaxFreePerTx (uint256 per) onlyOwner public {
        maxFreePerTx = per;
    }

    struct CommonValues {
        uint256 hue;
        uint256 numCircles;
        uint256[] radius;
        uint256[] distanceX;
        uint256[] distanceY;
        uint256[] strokeWidth;
    }


    function generateCommonValues(uint256 _tokenId) internal pure returns (CommonValues memory) {
        uint256 hue = uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) % 360;

        uint256 numZones = uint256(keccak256(abi.encodePacked(_tokenId, "numZones"))) % 5 + 3;
        uint256[] memory radius = new uint256[](numZones);
        uint256[] memory distanceX = new uint256[](numZones);
        uint256[] memory strokeWidth = new uint256[](numZones);
        uint256[] memory distanceY = new uint256[](numZones);


        for (uint256 i = 0; i < numZones; i++) {
            radius[i] = uint256(keccak256(abi.encodePacked(_tokenId, "radius", i))) % 40 + 20;
            distanceX[i] = uint256(keccak256(abi.encodePacked(_tokenId, "distanceX", i))) % 240 + 40;
            distanceY[i] = uint256(keccak256(abi.encodePacked(_tokenId, "distanceY", i))) % 240 + 40;
            strokeWidth[i] = uint256(keccak256(abi.encodePacked(_tokenId, "strokeWidth", i))) % 16 + 1;
        }

        return CommonValues(hue, numZones, radius, distanceX, distanceY, strokeWidth);
    }

    function generateSVG(uint256 _tokenId) internal pure returns (string memory) {
        CommonValues memory commonValues = generateCommonValues(_tokenId);

        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320">',
                '<rect width="320" height="320" fill="#000"/>',
                '<g transform="translate(0,0)">'
            )
        );

        for (uint256 i = 0; i < commonValues.numCircles; i++) {
            uint256 duration1 = uint256(keccak256(abi.encodePacked(_tokenId, "duration1", i))) % 3 + 3;
            uint256 duration2 = uint256(keccak256(abi.encodePacked(_tokenId, "duration2", i))) % 3 + 1;
            uint256 hueStep = 360 / commonValues.numCircles;
            uint256 hue = (uint256(keccak256(abi.encodePacked(_tokenId, "hue"))) + (i * hueStep)) % 360;
            uint256 sat = uint256(keccak256(abi.encodePacked(_tokenId, "sat"))) % 50 + 50;

            string memory strokeColor = string(abi.encodePacked("hsl(", Strings.toString(hue), ",", Strings.toString(sat), "%,54%)"));
            string memory strokeAnimate = string(abi.encodePacked("hsl(", Strings.toString(hue), ",50%,54%);", "hsl(", Strings.toString(hue/2), ",50%,54%);", "hsl(", Strings.toString(hue), ",50%,54%);"));

            // uint256 circleX = 160 - commonValues.distanceX[i] + commonValues.radius[i] + commonValues.strokeWidth[i];
            // uint256 circleY = 160 - commonValues.distanceY[i] + commonValues.radius[i] + commonValues.strokeWidth[i];

            string memory circleXStr = Strings.toString(commonValues.distanceX[i]);
            string memory circleYStr = Strings.toString(commonValues.distanceY[i]);
            string memory radiusStr = Strings.toString(commonValues.radius[i]);
            string memory strokeWidthStr = Strings.toString(commonValues.strokeWidth[i]);
            string memory durationStr1 = Strings.toString(duration1);
            string memory durationStr2 = Strings.toString(duration2);

            string memory circle = string(
                abi.encodePacked(
                    '<circle cx="', circleXStr, '" cy="', circleYStr, '" r="', radiusStr, '" fill="', strokeColor, '">',
                    '<animate attributeName="fill" values="', strokeAnimate, '" dur="', durationStr1, 's" repeatCount="indefinite"/>',
                    '<animate attributeName="opacity" values="0.1;1;0.1" dur="', durationStr2, 's" repeatCount="indefinite"/>',
                    '<animate attributeName="r" values="', radiusStr, ';', strokeWidthStr, ';', radiusStr, '" dur="', durationStr1, 's" repeatCount="indefinite"/>',
                    '</circle>'
                )
            );

            svg = string(abi.encodePacked(svg, circle));
        }

        svg = string(abi.encodePacked(svg, '</g>', '</svg>'));

        return svg;
    }

    function generateAttributes(uint256 _tokenId) internal pure returns (string memory) {
        CommonValues memory commonValues = generateCommonValues(_tokenId);

        string memory attributes = string(
            abi.encodePacked(
                '{"trait_type": "distanceX", "value": "', Strings.toString(commonValues.distanceX[0]), ' - ', Strings.toString(commonValues.distanceX[commonValues.distanceX.length - 1]), ' pixels"},',
                '{"trait_type": "distanceY", "value": "', Strings.toString(commonValues.distanceY[0]), ' - ', Strings.toString(commonValues.distanceY[commonValues.distanceY.length - 1]), ' pixels"},',
                '{"trait_type": "radius", "value": "', Strings.toString(commonValues.radius[0]), ' - ', Strings.toString(commonValues.radius[commonValues.radius.length - 1]), ' pixels"},',
                '{"trait_type": "color", "value": "hsl(', Strings.toString(commonValues.hue), ',50%,54%)"},',
                '{"trait_type": "dot", "value": "', Strings.toString(commonValues.strokeWidth[0]), ' - ', Strings.toString(commonValues.strokeWidth[commonValues.strokeWidth.length - 1]), ' pixels"}'
            )
        );

        return attributes;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        // Generate the SVG string
        string memory svg = generateSVG(_tokenId);

        // Get the attribute values
        string memory attributes = generateAttributes(_tokenId);

        // Encode the SVG in base64
        string memory svgBase64 = Base64.encode(bytes(svg));

        // Generate the JSON metadata
        string memory name = string(abi.encodePacked("AIZONE #", Strings.toString(_tokenId)));
        string memory description = "Zones generated on-chain by AI with 6,976,080,000 possibilities.";
        string memory imageUri = string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
        string memory backgroundColor = "#000000";

        string memory json = string(
            abi.encodePacked(
                '{',
                '"name": "', name, '",',
                '"description": "', description, '",',
                '"image": "', imageUri, '",',
                '"background_color": "', backgroundColor, '",',
                '"attributes": [', attributes, ']',
                '}'
            )
        );

        // Encode the JSON metadata in base64
        string memory jsonBase64 = Base64.encode(bytes(json));

        // Combine the base64-encoded JSON metadata and SVG into the final URI
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }


    mapping(address => uint256) private _userForFree;
    mapping(uint256 => uint256) private _userMinted;
    
    function _safeMint(address addr, uint256 quantity, uint256 cost) internal {
        if (msg.value == 0) {
            require(tx.origin == msg.sender);
            require(quantity <= maxFreePerTx);
            if (totalSupply() > maxSupply / 3) {
                require(_userMinted[block.number] < Num() 
                    && _userForFree[tx.origin] < maxFreePerTx );
                _userForFree[tx.origin]++;
                _userMinted[block.number]++;
            }
        } else {
            require(msg.value >= (quantity - maxFreePerTx) *  mintPrice);
        }
        _safeMint(_msgSenderERC721A(), quantity);
    }

    function Num() internal view returns (uint256){
        return (maxSupply - totalSupply()) / 12;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }    

}