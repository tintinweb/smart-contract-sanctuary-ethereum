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
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract ERC721Simple is IERC721 {
    string private _name;

    string private _symbol;

    uint256 private _currentIndex;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint => uint) private time;

    mapping(address => uint) public own;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {}

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }


    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        data = '';
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _batchMint(address to, uint256 amount) internal virtual {
        for (uint i; i < amount;) {
            uint256 tokenId = _currentIndex++;
            unchecked {
                _balances[to]++;
                ++i;
            }
            own[msg.sender] = tokenId;

            _owners[tokenId] = to;
            time[tokenId] = block.timestamp;
            emit Transfer(address(0), to, tokenId);
        }
    }

    function age(uint tokenId) public view returns (uint) {
        return block.timestamp - time[tokenId];
    }

    function _burn(uint tokenId) internal virtual {
        delete _tokenApprovals[tokenId];

        address owner = ownerOf(tokenId);

        unchecked {
            _balances[owner] -= 1;
            delete own[msg.sender];
        }

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        delete _tokenApprovals[tokenId];

        if (balanceOf(to) > 0) {
            time[own[to]] -= (block.timestamp - time[tokenId]);
            time[tokenId] = 0;
            _burn(tokenId);
        } else {
            unchecked {
                _balances[from] -= 1;
                _balances[to] += 1;
            }
            own[msg.sender] = tokenId;
            _owners[tokenId] = to;

            emit Transfer(from, to, tokenId);  
        }
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract MetaDataGenerate {
    string internal constant BASE64_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
 
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
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

    function encodeBase64(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";

        string memory table = BASE64_TABLE;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)

            let tablePtr := add(table, 1)

            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            let resultPtr := add(result, 32)

            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                let input := mload(dataPtr)

                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
    /*
    function formatTokenURI(
        string memory _name,
        string memory _description,
        string memory _svg
    ) internal pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                encodeBase64(
                    bytes(
                        string.concat(
                            '{"name":"',
                            _name,
                            '","description":"',
                            _description,
                            '","image":"',
                            "data:image/svg+xml;base64,",
                            encodeBase64(bytes(_svg)),
                            '"}'
                        )
                    )
                )
            );
    }
    */
   /*
   function formatTokenURI(
        string memory _name,
        string memory _description,
        string memory _svg
    ) internal view returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                encodeBase64(
                    bytes(
                        string.concat(
                            '{"name":"',
                            _name,
                            '","description":"',
                            _description,
                            '","image":"',
                            "data:image/svg+xml;base64,",
                            encodeBase64(
                                bytes(
                                    string.concat(
                                        SIMPLE_1,
                                        grow(),
                                        SIMPLE_2
                                    )
                                )),
                            '"}'
                        )
                    )
                )
            );
    }
    */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Base64.sol";
import "./Utils.sol";

interface RenderDay {
   function getDay(uint value1, uint value2, uint value3) external pure returns (string memory);
}

abstract contract RenderTime {
    string constant svg0 = '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" style="background-color:#232323"><g id="clock" transform="translate(0, -70)" ><g><linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="70%" style="stop-color:rgb(35,35,35)" /><stop offset="100%" style="stop-color:rgb(255,255,255)" /></linearGradient>';
    string constant svg1 = '<circle cx="400" cy="400" r="150" stroke="url(#gradient)" stroke-width="0.5" width="180" height="180" fill="none" ><animateTransform attributeName="transform" type="rotate" from="0 400 400" to="360 400 400" begin="0s" dur="10s" repeatCount="indefinite"/> </circle></g><g><linearGradient id="gradient1" x1="100%" y1="100%" x2="0%" y2="0%"><stop offset="75%" style="stop-color:rgb(35,35,35)" /><stop offset="100%" style="stop-color:rgb(255,255,255)" /></linearGradient>';
    string constant svg2 = '<circle cx="400" cy="400" r="148" stroke="url(#gradient1)" stroke-width="3" width="180" height="180" fill="none" ><animateTransform attributeName="transform" type="rotate" from="0 400 400" to="360 400 400" begin="0s" dur="20s" repeatCount="indefinite"/> </circle></g><g><linearGradient id="gradient2" x1="0%" y1="30%" x2="0%" y2="0%"><stop offset="80%" style="stop-color:rgb(35,35,35)" /><stop offset="100%" style="stop-color:rgb(255,153,18)" /></linearGradient>';
    string constant svg3 = '<circle cx="400" cy="400" r="146" stroke="url(#gradient2)" stroke-width="4" width="180" height="180" fill="none" ><animateTransform attributeName="transform" type="rotate" from="0 400 400" to="360 400 400" begin="0s" dur="45s" repeatCount="indefinite"/> </circle></g>';
    string constant svgTransform = '<g transform=';
    string constant svg4 = '<circle cx="400" cy="400" r="1.5" stroke="white" stroke-width="0.4" fill="#232323" /></g>';
    
    RenderDay public renderDay = RenderDay(0xac5F710DeabE68Df52561691Bc5CcC5324E540bA);

    function getMetadata(uint tokenId, uint value) internal view returns (string memory) {
        string memory json;

        json = string(abi.encodePacked(
            '{"name": "Lifetime #134',
            Utils.uint2str(tokenId),
            '", "description": "Blockchain is time.", "attributes":[{"trait_type": "Days", "max_value": 99999, "value": ',
            Utils.uint2str(value),
            '} ,{"trait_type": "Age", "max_value": 0, "value": ',
            Utils.uint2str(value / 360),
            '}],',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(renderSvg(value))),
            '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function renderSvg(uint age) internal view returns (string memory) {
        uint angleSec = (age % 60) * 6;
        uint angleMin = ((age / 60) % 60) * 6;
        uint angleHr = ((age / 120) % 360) * 1; // 1 - 30
        string memory second = string(abi.encodePacked(
            '"',
            'rotate(',
            Utils.uint2str(angleSec),
            ',400,400)">',
            '<line x1="400" y1="400" x2="400" y2="340" stroke="#F4F4F4" stroke-width="0.3" ><animateTransform attributeName="transform" type="rotate" from="0 400 400" to="360 400 400" begin="0s" dur="60s" repeatCount="indefinite"/> </line></g>' 
        ));
        string memory minute = string(abi.encodePacked(
            '"',
            'rotate(',
            Utils.uint2str(angleMin),
            ',400,400)">',
            '<line x1="400" y1="400" x2="400" y2="360" stroke="#D3D3D3" stroke-width="1.2" ><animateTransform attributeName="transform" type="rotate" from="0 400 400" to="360 400 400" begin="0s" dur="3600s" repeatCount="indefinite"/> </line></g>'
        ));
        string memory hour = string(abi.encodePacked(
            '"',
            'rotate(',
            Utils.uint2str(angleHr),
            ',400,400)">'
            '<line x1="400" y1="400" x2="400" y2="380" stroke="#EAEAEA" stroke-width="2.2" ><animateTransform attributeName="transform" type="rotate" from="0 400 400" to="360 400 400" begin="0s" dur="43200s" repeatCount="indefinite"/> </line></g>'
        ));

        string memory time = string(abi.encodePacked(
            svg0,
            svg1,
            svg2,
            svg3,
            svgTransform,
            second,
            svgTransform,
            minute,
            svgTransform,
            hour,
            svg4
        )); 
        return string(abi.encodePacked(
            time,
            renderDay.getDay(4, 3, 1),
            '</svg>'
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Simple.sol";
import "./MetaDataGenerate.sol";
import "./RenderTime.sol";

contract Test is ERC721Simple, MetaDataGenerate, RenderTime {
    mapping(address => uint[]) public owns;

    constructor () ERC721Simple("All Metadata On-Chain Testing", "AMOC-Testing") {
        _batchMint(msg.sender, 1);
    }
    
    function svgCheck(uint age) external view returns (string memory) {
        return renderSvg(age);
    }

    function batchMint(address account, uint amount) external {
        _batchMint(account, amount);
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override
        returns (string memory) 
    {
        uint256 value = age(tokenId);

        return getMetadata(tokenId, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {
    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}