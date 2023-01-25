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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Note     : On-chain metadata for Riot Pass
// Dev      : 3L33T

/*************************************************************
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ██████████████████████████████████▀▀█▀█████▀▀▀██████████████████████████████████
    █████████████████████████████▀▀███  " ████   ▐███▀ ▀▀███████████████████████████
    ████████████████████████▀▀███▄ ▐██µ   ███▌ ▐  ██▀  ▀ ▐██████████████████████████
    ██████████████████████▌ █  ▀██▄ ▀██ ▐▄ ██  ▄  ██  ▌ ████` ██████████████████████
    ███████████████████████▄  ▄  ██▄▄██████████████▄▄█ ╓██▀ ,███████████████████████
    █████████████████████████  ▀▄▄█████▀▀▀▀▀█▀▀▀▀████████  ▄████████████████████████
    ██████████████████▄█ ██████████▀▀      ▀█▄      ▀▀████████▄`█▀██████████████████
    █████████████████ ███ ███████▀*      ▀█▐█▌▄█▀⌐  ,▀ ▀██████▐▄██ █████████████████
    █████████████████▐▀█▀▄██████    ▄  ▐█████████▄ ¬    ▐█████ ██▀█▐████████████████
    ████████████████▀▌ ████████     `▀    ▐███ `   ╛     ██████▄█ ██████████████████
    ███████████████`███ ███████         ,██ ▀█▄ ▄       ▄███████▀▌▄▄▐███████████████
    ███████████████▐███ ██████▌▐  ,ⁿ   "▀   `▀▀▀▀   `* , ▐██████ ███▌███████████████
    ████████████████▌▐████████▌ ¥  ▄██████^"▌ⁿ▄▄█████▄r▌ ▐███████▐▌j▄███████████████
    ████████████████▌▐▀███████▌ⁿ" ████████  ▌ ████████ ▀▀▐████████▌]████████████████
    ███████████████ ███ ██████▌,P '▀█████▀▐███▀██████▀ ▀,▐██████▌▄██ ███████████████
    ████████████████'█▀▄██████▌   ▄'  ═"  ▐███  ⁿ   ▀    ███████ ███▐███████████████
    ██████████████████▌"█▀█████  ▀        ████       '▄  ████████ █▄████████████████
    ██████████████████▐███▄███████████,,   ▀▌▌1╒╒╔███████████▀▄█▄███████████████████
    ███████████████████▀█▀▀█████████████▐▀▀▌▌▌██▐███████████▌████▄██████████████████
    ██████████████████████▄ ████▀▀███████████████████▀▀▀████▀ █▌▄███████████████████
    ██████████████████████████▀  ▀ ██▀███████████▀▀█▌ ▀▀▀███████████████████████████
    █████████████████████████▌ ▄ ▐██ ▄█   ▐█  ▄█⌐ ▌ ███▀▌ ██████████████████████████
    ███████████████████████████▄███ ╒██ █ ]█⌐ ▄██  ▄ ██▄▄███████████████████████████
    ███████████████████████████████▄██▌ ▀ ██▌ ▀███▄█▄███████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
    ████████████████████████████████████████████████████████████████████████████████
                                                                                                                    
*************************************************************/

import "@openzeppelin/contracts/utils/Base64.sol";

error NotOwner();
error NoQuantitiesAndPoints();

contract RiotMetadata {
    string public desc =
        "Hikari Riot Pass is a membership pass by Hikari Riders backed by NFT technology.\\nThis pass will grant the holder access to perks within the Hikari Riders ecosystem.";
    string public animURL = "ar://BfJC-XcqUalYqEkQcOh0cSD6DCNKXu9qBmYktPQUpU8";
    string public image = "ar://PPhGPCcE445tddFMZYzXNIU_Rl-wbz0Gc_PZ76waNuY";
    address public owner;

    mapping(uint256 => uint256) public points;

    constructor() {
        owner = msg.sender;
    }

    event newDesc(string desc);
    event newAnimURL(string animURL);
    event newImage(string image);
    event pointsUpdated(uint256 indexed id, uint256 points);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setDescription(string calldata _desc) external onlyOwner {
        desc = _desc;
        emit newDesc(desc);
    }

    function setAnimationURL(string calldata _animURL) external onlyOwner {
        animURL = _animURL;
        emit newAnimURL(animURL);
    }

    function setImageURL(string calldata _image) external onlyOwner {
        image = _image;
        emit newImage(image);
    }

    function updatePoints(uint256 _id, uint256 _points) external onlyOwner {
        points[_id] = _points;
        emit pointsUpdated(_id, _points);
    }

    function updatePointsBatch(
        uint256[] calldata _ids,
        uint256[] calldata _points
    ) external onlyOwner {
        uint256 idl = _ids.length;
        uint256 ptl = _points.length;

        if (ptl != idl) revert NoQuantitiesAndPoints();

        for (uint256 i = 0; i < idl; ) {
            points[_ids[i]] = _points[i];
            unchecked {
                ++i;
            }
        }
        delete ptl;
        delete idl;
    }

    function fetchMetadata(uint256 _tokenID)
        external
        view
        returns (string memory)
    {
        string memory _name = "Hikari Riot Pass #";
        string memory _desc = desc;
        string memory _image = image;
        string memory _animURL = animURL;

        string[7] memory attr;

        attr[0] = '{"trait_type":"ID","value":"';
        attr[1] = toString(_tokenID);
        attr[2] = '"},{"trait_type":"Supply","value":2500},';
        attr[3] = '{"trait_type":"Type","value":"Pass"},';
        attr[4] = '{"trait_type":"Point","value":';
        attr[5] = toString(points[_tokenID]);
        attr[6] = "}";

        string memory _attr = string(
            abi.encodePacked(
                attr[0],
                attr[1],
                attr[2],
                attr[3],
                attr[4],
                attr[5],
                attr[6]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        toString(_tokenID),
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

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}