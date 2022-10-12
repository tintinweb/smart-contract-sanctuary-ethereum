// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*************************************************************
**           _               -x-++--+-x                     **
**     _____|_|_ __   ___   __  __ ___  _  ___  __   ___    **
**    / __  | | '_ \ / _ \ /  \/ / _ \| |__|  | '_ \/ __|   **
**   / /_/ /|_|_| |_| (_) /_/\__/ (_) |\__,_|_| | | \__ \   **
**  /_____/          \___/       \___/        |_| |_|___/   **
**                                                          **
*************************************************************/ 

// Project  : DinoNouns
// Buidler  : Nero One
// Note     : Interactive on-chain DinoNouns - Dino Utility -

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error NotOwner();

contract DinoUtility {
    address public dinoRenderer = 0x4484a56a643DBBE2E074C3Ad53D1B8de4CcC604D;
    address public dinoMain = 0xB43e886c7D7d4b3EDa65E016B5bcEf56548AEB7b;
    address public nounsDescriptor = 0x0Cfdb3Ba1694c2bb2CFACB0339ad7b1Ae5932B63;
    address public nounsSeeder = 0xCC8a0FB5ab3C7132c1b2A0109142Fb112c4Ce515;

    string private extraJS;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function getNounsSVG(string calldata _name, uint256 _id)
        public
        view
        returns (string memory)
    {
        INounsDescriptor descriptor = INounsDescriptor(nounsDescriptor);

        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(_name, _id))
        );

        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 glassesCount = descriptor.glassesCount();

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    descriptor.generateSVGImage(
                        INounsSeeder.Seed({
                            background: uint48(1),
                            body: uint48(
                                uint48(pseudorandomness >> 48) % bodyCount
                            ),
                            accessory: uint48(
                                uint48(pseudorandomness >> 96) % accessoryCount
                            ),
                            head: uint48(69),
                            glasses: uint48(
                                uint48(pseudorandomness >> 192) % glassesCount
                            )
                        })
                    )
                )
            );
    }

    function getMetadata(string calldata _name, uint256 _id)
        external
        view
        returns (string memory)
    {
        string memory _dinoName = _name;
        string
            memory _desc = "DinoNouns - A dynamic interactive experience\\n\\nInteractive Dino for you to play with. Jump, run, teach them words.\\nYou can even interact with the contract to change the name.\\n\\nWant more customize your DinoTerminal? Add your own custom CSS by interacting with the contract.\\n\\nProudly built by Nero One";
        string memory _image = getNounsSVG(_name, _id);
        string memory _animURL = IDinoRenderer(dinoRenderer).getDinoHTML(
            _name,
            _id
        );

        string[4] memory attr;

        attr[0] = '{"trait_type":"Type","value":"Interactive';
        attr[1] = '"},{"trait_type":"Dino Name","value":"';
        attr[2] = _dinoName;
        attr[3] = '"}';

        string memory _attr = string(
            abi.encodePacked(attr[0], attr[1], attr[2], attr[3])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _dinoName,
                        '", "description": "',
                        _desc,
                        '", "image": "',
                        _image,
                        '", "animation_url": "',
                        _animURL,
                        '", "attributes": [',
                        _attr,
                        "]",
                        "}"
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function getCSS(uint256 _id) external view returns (string memory) {
        string memory customCSS = IDinoMain(dinoMain).getCustomCSS(_id);
        string memory CSS = string(
            abi.encodePacked(
                "<style>@font-face{font-family:Bayon;font-style:normal;font-weight:400;src:url(data:font/woff2;base64,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)format('woff2');unicode-range:U+??,U+131,U+152-153,U+2BB-2BC,U+2C6,U+2DA,U+2DC,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD}#accFill{fill:var(--accentColor)}#accStroke{stroke:var(--accentColor)}#primFill{fill:var(--primaryColor)}#primStroke{stroke:var(--primaryColor)}*{--primaryColor:#d0c8c6;--accentColor:#34ac80;font-family:Bayon,sans-serif;font-size:1.1em}a{color:var(--accentColor)}body{height:100vh;width:100vw;min-width:500px;min-height:500px;color:#0e0e0e;background-color:#e1d7d5;flex-direction:column;justify-content:center;align-items:center;margin:0;display:flex;overflow:hidden}#inputText{width:173px;height:43px;background:0 0;font-size:24px;line-height:43px;position:absolute;top:353px;left:58px;border:0!important;outline:0!important}#dinoName{width:180px;height:63px;text-align:center;font-size:35px;font-weight:400;line-height:1em;position:absolute;top:290px;left:160px}#dinoImage{animation:1.2s ease-in-out infinite idle}#dinoTitle{position:absolute;top:42px;left:208px}#log{width:356px;height:1em;color:#646464;text-align:left;font-size:24px;line-height:1em;position:absolute;top:419px;left:58px;overflow:hidden}span#reaction{text-align:left;width:96px;height:4em;word-break:break-word;font-size:1em;line-height:1em;position:absolute;top:116px;left:346px;overflow:hidden}.wrapper{position:relative}.dino{z-index:-1;width:200.86px;height:204.96px;position:absolute;top:85px;left:156px}.btns{background:var(--primaryColor);border-radius:15px;position:absolute;box-shadow:0 4px 4px #00000040}.btns:active{box-shadow:inset 0 4px 4px #00000040}#btnA{width:42px;height:42px;text-align:center;top:353px;left:253px}#btnB{width:42px;height:42px;text-align:center;top:353px;left:307px}#btnX{width:42px;height:42px;text-align:center;top:353px;left:361px}#btnY{width:42px;height:42px;text-align:center;top:353px;left:415px}#btnLvl{width:56px;height:56px;background:#656565;border-radius:1.5em;position:absolute;top:42px;left:406px;box-shadow:inset 0 -5px 2px #00000040}#lvlTxt{width:2em;height:43px;text-align:center;color:#ececec;position:absolute;top:49px;left:411px}@keyframes run{0%{transform:translate(0)}50%{transform:translate(30px)}to{transform:translate(0)}}@keyframes jump{0%{transform:translateY(0)}50%{transform:translateY(-30px)}to{transform:translateY(0)}}@keyframes idle{0%{transform:translateY(0)}50%{transform:translateY(3px)}to{transform:translateY(0)}}@media screen and (max-width:350px){.wrapper{position:relative;scale:.6}}</style>",
                "<style>",
                customCSS,
                "</style>"
            )
        );

        return string(CSS);
    }

    function getExtraJS() external view returns (string memory) {
        return extraJS;
    }

    function setExtraJS(string calldata _js) external onlyOwner {
        extraJS = _js;
    }

    function setDinoRendererAddress(address _address) external onlyOwner {
        dinoRenderer = _address;
    }

    function setDinoMainAddress(address _address) external onlyOwner {
        dinoMain = _address;
    }
}

interface IDinoRenderer {
    function getDinoHTML(string calldata _name, uint256 _id)
        external
        view
        returns (string memory);
}

interface INounsDescriptor {
    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function generateSVGImage(INounsSeeder.Seed memory seed)
        external
        view
        returns (string memory);
}

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor)
        external
        view
        returns (Seed memory);
}

interface IDinoMain {
    function getCustomCSS(uint256 _id) external view returns (string memory);
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