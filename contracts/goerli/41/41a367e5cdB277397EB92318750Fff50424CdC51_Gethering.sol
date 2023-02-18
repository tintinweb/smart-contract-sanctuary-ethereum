// SPDX-License-Identifier: MIT

pragma solidity >=0.8.18;

import "./deps.sol";

contract Gethering is ERC721 {
    uint public totalSupply;
    uint public mintedNumber;

    struct Mask {
        uint code;
        uint pixelsNumber;
        uint getheredTimes;

        bool burned;
    }

    mapping(uint256 => Mask) public tokenInfo;

    uint public constant MASK_SIZE = 2;
    uint public constant PIC_SIZE = 256;
    uint public constant MINT_SIZE = MASK_SIZE ** 2;
    uint public constant PIXEL_SIZE = PIC_SIZE / MASK_SIZE;

    mapping(uint8 => uint8) public MINT_MAP;

    constructor() ERC721("Gethering", "GTHRNG")
    {

        for (uint8 i = uint8(MINT_SIZE); i > 0; i--)
        {
            uint8 j = uint8(uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % i) + 1;
            (MINT_MAP[i], MINT_MAP[j]) = (MINT_MAP[j] > 0 ? MINT_MAP[j] : j, MINT_MAP[i] > 0 ? MINT_MAP[i] : i);
        }

        for (uint j = 0; j < MINT_SIZE; ++j)
        {
            mint();
        }

    }

    function mint() public 
    {
        require(totalSupply < MINT_SIZE, string.concat("Can't mint more than ", Strings.toString(MINT_SIZE)));

        _mint(msg.sender, ++totalSupply);

        tokenInfo[totalSupply].code = 1 << (MINT_MAP[uint8(++mintedNumber)] - 1);
        tokenInfo[totalSupply].pixelsNumber = 1;
        tokenInfo[totalSupply].burned = false;
    }

    function gether(uint token1, uint token2) public 
    {
        Mask memory mask1 = tokenInfo[token1];
        Mask memory mask2 = tokenInfo[token2];

        _mint(msg.sender, ++totalSupply);

        tokenInfo[totalSupply].code = (mask1.code | mask2.code) % (2 ** MINT_SIZE);
        tokenInfo[totalSupply].pixelsNumber = mask1.pixelsNumber + mask2.pixelsNumber;
        tokenInfo[totalSupply].getheredTimes = (mask1.getheredTimes >= mask2.getheredTimes ? mask1.getheredTimes : mask2.getheredTimes) + 1;

        burn(token1);
        burn(token2);
    }

    function burn(uint token) private
    {
        tokenInfo[token].burned = true;
        _burn(token);
    }

    function tokenURI(uint token) public view override(ERC721) returns(string memory encoded_metadata)
    {
        encoded_metadata = string(abi.encodePacked("data:application/json;base64,", metadataJson(token)));
    }

    function metadataJson(uint token) public view returns(string memory metadata)
    {
        string memory image;
        string[] memory attributes;
        
        Mask memory mask = tokenInfo[token]; 

        (image, attributes) = getImage(mask);

        string[] memory entries = new string[](attributes.length);

        for (uint i = 0; i < attributes.length; ++i)
        {
            entries[i] = string(abi.encodePacked("{\"trait_type\":\"element\",\"value\":\"", attributes[i], "\"}"));
        }

        string memory attributesJson = "[";
        for (uint i = 0; i < entries.length; ++i)
        {
            if (i == 0)
            {
                attributesJson = string(abi.encodePacked(attributesJson, entries[i]));
            }
            else 
            {
                attributesJson = string(abi.encodePacked(attributesJson, ",", entries[i]));
            }
        }
        attributesJson = string(abi.encodePacked(attributesJson,"]"));

        metadata = Base64.encode(
            abi.encodePacked(
                "{\"image\": \"", image,
                "\",\"name\":\"", mask.burned ? "Burned " : "", "Piece #", Strings.toString(token), 
                "\",\"description\":\"Piece of Gethering.\",\"attributes\":", attributesJson, "}"));
    }   

    function getImage(Mask memory mask) public pure returns(string memory image, string[] memory attributes)
    {        
        bytes memory header = hex""
        hex"424D"
        hex"00000000" 
        hex"00000000"
        hex"36000000"

        hex"28000000"
        hex"ff000000"
        hex"ff000000"
        hex"0100"
        hex"1000"
        hex"00000000"
        hex"00000000"
        hex"00000000"
        hex"00000000"
        hex"00000000"
        hex"00000000"
        hex""; 

        bytes memory imageBytes;

        (imageBytes, attributes) = getContentBytes(mask);
        image = string(abi.encodePacked("data:image/bmp;base64,", Base64.encode(abi.encodePacked(header, imageBytes))));
    }

    function getContentBytes(Mask memory mask) public pure returns(bytes memory content, string[] memory attributes)
    {
        content = new bytes(PIC_SIZE ** 2 * 2);
        
        if (mask.burned) {
            attributes = new string[](1);
            attributes[0] = string(abi.encodePacked("Burned"));

            setBackground(content, 0x77);
        } else {
            setBackground(content, abi.encodePacked(uint(255 - mask.getheredTimes))[31]);

            uint number = mask.code;

            for (uint i = 0; i < MASK_SIZE; i++)
            {
                uint line = number % (1 << MASK_SIZE);

                for (uint j = 0; j < MASK_SIZE; j++)
                {
                    if (line % 2 == 1) {
                        addPixel(content, j, MASK_SIZE - 1 - i, 0x00);
                    }

                    line = line >> 1;
                }

                number = number >> MASK_SIZE;
            }

            if (mask.getheredTimes > 0) {
                attributes = new string[](2);
                attributes[0] = string(abi.encodePacked("Gethered: ", Strings.toString(mask.pixelsNumber)));
                attributes[1] = string(abi.encodePacked("Pixels: ", Strings.toString(mask.pixelsNumber)));
            } else {
                attributes = new string[](1);
                attributes[0] = string(abi.encodePacked("Minted"));
            }
        }
    }

    function setBackground(bytes memory content, bytes1 color) private pure
    {
        for (uint i = 0; i < content.length / 2; ++i)
        {
            content[2 * i] = color;
            content[2 * i + 1] = color;           
        }
    }

    function addPixel(bytes memory content, uint x, uint y, bytes1 color) private pure
    {

        for (uint xi = PIXEL_SIZE * x; xi < PIXEL_SIZE * (x + 1); xi++)
        {
            for (uint yi = PIXEL_SIZE * y; yi < PIXEL_SIZE * (y + 1); yi++)
            {
                uint flat = centricToFlat(xi, yi);
                content[flat] = color;
                content[flat + 1] = color;
            }

        }
    }

    function centricToFlat(uint x, uint y) public pure returns(uint flat) 
    {
        flat = (PIC_SIZE * y + x) * 2;
    }

}