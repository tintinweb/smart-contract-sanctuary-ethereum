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

interface IData {
    function convert() external view returns (string memory);
}

abstract contract MetaDataGenerate {
    IData public target = IData(0x7F101f35Ade4234661e26bE679a9490c2E80b880);

    uint256 public bornTime = 1673060400;
    string internal constant BASE64_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    string public SIMPLE_1 = string.concat(
        '<?xml version="1.0" standalone="no"?>',
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="278pt" height="238pt" viewBox="0.00 0.00 278.19 238.00">',
        '<g id="graph0" class="graph" transform="translate(4,234) scale(1)" data-name="G">',
        '<polygon fill="#2e3e56" stroke="none" points="-4,4 -4,-234 274.19,-234 274.19,4 -4,4" style=""/>',
        '<g id="clust1" class="cluster" data-name="clusterMyToken">',
        '<ellipse fill="#ff9797" stroke="#ff9797"',
        ' stroke-width=',
        '"'
    );

    string public SIMPLE_2 = string.concat(
        '"',
        ' cx="140" cy="-100" rx="20.55" ry="20" style=""/>',
        '<text text-anchor="middle" x="140" y="-95" font-family="Times,serif" font-size="15.00" style="">Life</text>',
        '</g><g id="node2" class="node" pointer-events="visible" data-name="MyToken._mint"></g></g></svg>'
    );
    
    function grow() public view returns (string memory){
        uint _size = ((block.timestamp - bornTime) / 60) * 2;
        return uint2str(_size);
    }

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Base64.sol";
import "./Utilities.sol";

library Segments {
    // Four digits: a, b, c, d
    struct Number {
        uint a;
        uint b;
        uint c;
        uint d;
    }
    string constant svg0 = '<?xml version="1.0" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><circle cx="100" cy="100" r="90" stroke="black" stroke-width="5" fill="white"/>';
    string constant svg1 = '<g transform=';
    
    string constant svg2 = '<g transform=';
    
    string constant svg3 = '<g transform=';
    
    string constant svg4 = '<g transform="rotate(0,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g>';
    string constant svg5 = '<circle cx="100" cy="100" r="4" stroke="black" stroke-width="1" fill="white" />';
    string constant svg6 = '<g transform="rotate(30,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(60,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(90,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g>';
    string constant svg7 = '<g transform="rotate(120,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(150,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(180,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(210,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(240,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(270,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(300,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g><g transform="rotate(330,100,100)"><line x1="100" y1="20" x2="100" y2="30" stroke="black" stroke-width="2" /></g></svg>';
    
    function getNumbers(uint input, uint length) internal pure returns (Number memory result) {
        if (length == 1) {
            result.d = input;
        } else if (length == 2) {
            result.c = (input / 10);
            result.d = (input % 10);
        } else if (length == 3) {
            result.b = (input / 100);
            result.c = ((input % 100) / 10);
            result.d = (input % 10);
        } else if (length == 4) {
            result.a = (input / 1000);
            result.b = ((input % 1000) / 100);
            result.c = ((input % 100) / 10);
            result.d = (input % 10);
        }
        return result;
    }

    function getBaseColorName(uint index) internal pure returns (string memory) {
        string[4] memory baseColorNames = ["White", "Red", "Green", "Blue"];
        return baseColorNames[index];
    }

    function getMetadata(uint tokenId, uint value, uint baseColor, bool burned) internal view returns (string memory) {
        string memory json;

        if (burned) {
            json = string(abi.encodePacked(
            '{"name": "TIME ',
            utils.uint2str(tokenId),
            ' [BURNED]", "description": "Numbers are art, and we are artists.", "attributes":[{"trait_type": "Burned", "value": "Yes"}], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(renderSvg(value))),
            '"}'
        ));
        } else {
            json = string(abi.encodePacked(
            '{"name": "TIME ',
            utils.uint2str(tokenId),
            '", "description": "Blockchain is time.", "attributes":[{"trait_type": "Days", "max_value": 9999, "value": ',
            utils.uint2str(value % 60),
            '}],',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(renderSvg(value))),
            '"}'
        ));
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }

    function getNumberStyle(uint position, uint input) internal pure returns (string memory) {
        string memory p = utils.uint2str(position);
        if (input == 0) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"3,","#p",p,"5,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 1) {
            return string(abi.encodePacked(
                "#p",p,"3,","#p",p,"6 {fill-opacity:1}"
            ));
        } else if (input == 2) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"3,","#p",p,"4,","#p",p,"5,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 3) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"3,","#p",p,"4,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 4) {
            return string(abi.encodePacked(
                "#p",p,"2,","#p",p,"3,","#p",p,"4,","#p",p,"6 {fill-opacity:1}"
            ));
        } else if (input == 5) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"4,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 6) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"4,","#p",p,"5,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 7) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"3,","#p",p,"6 {fill-opacity:1}"
            ));
        } else if (input == 8) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"3,","#p",p,"4,","#p",p,"5,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else if (input == 9) {
            return string(abi.encodePacked(
                "#p",p,"1,","#p",p,"2,","#p",p,"3,","#p",p,"4,","#p",p,"6,","#p",p,"7 {fill-opacity:1}"
            ));
        } else {
            return "error";
        }
    }

    function renderSvg(uint age) public pure returns (string memory) {
        uint angleSec = (age % 60) * 6;
        uint angleMin = ((age / 60) % 60) * 6;
        uint angleHr = ((age / 3600) % 12) * 6;

        string memory second = string(abi.encodePacked(
            '"',
            'rotate(',
            utils.uint2str(angleSec),
            ',100,100)">',
            '<line x1="100" y1="100" x2="100" y2="30" stroke="red" stroke-width="2" /></g>' 
        ));
        string memory minute = string(abi.encodePacked(
            '"',
            'rotate(',
            utils.uint2str(angleMin),
            ',100,100)"',
            '<line x1="100" y1="100" x2="100" y2="40" stroke="black" stroke-width="4" /></g>'
        ));
        string memory hour = string(abi.encodePacked(
            '"',
            'rotate(',
            utils.uint2str(angleHr),
            ',100,100)">'
            '<line x1="100" y1="100" x2="100" y2="60" stroke="black" stroke-width="6" /></g>'
        ));

        return string(abi.encodePacked(
            svg0,
            svg1,
            hour,
            svg2,
            minute,
            svg3,
            second,
            svg4,
            svg5,
            svg6,
            svg7
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Simple.sol";
import "./MetaDataGenerate.sol";
import "./Segments.sol";

contract Test is ERC721Simple, MetaDataGenerate {
    mapping(address => uint[]) public owns;
    mapping(address => uint) public len;

    constructor () ERC721Simple("All Metadata On-Chain Testing", "AMOC-Testing") {
        _batchMint(msg.sender, 1);
    }
    
    function batchMint(uint amount) external {
        _batchMint(msg.sender, amount);        
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override
        returns (string memory) 
    {
        uint256 value = age(tokenId);

        return Segments.getMetadata(tokenId, value, 0, false);
    }
}

/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░   .         .  .         .  .         .  .         .   ░░
░░    . . . . .    . . . . .    . . . . .    . . . . .    ░░
░░                                                        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library utils {
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

    // Get a pseudo random number
    function random(uint input, uint min, uint max) internal pure returns (uint) {
        uint randRange = max - min;
        return max - (uint(keccak256(abi.encodePacked(input + 2023))) % randRange) - 1;
    }

    function initValue(uint tokenId) internal pure returns (uint value) {
        if (tokenId < 1000) {
            value = random(tokenId, 1, 51);
        } else if (tokenId < 2000) {
            value = random(tokenId, 1, 46);
        }  else if (tokenId < 3000) {
            value = random(tokenId, 1, 41);
        }  else if (tokenId < 4000) {
            value = random(tokenId, 1, 36);
        }  else if (tokenId < 5000) {
            value = random(tokenId, 1, 31);
        }  else if (tokenId < 6000) {
            value = random(tokenId, 1, 26);
        }  else if (tokenId < 7000) {
            value = random(tokenId, 1, 21);
        }  else if (tokenId < 8000) {
            value = random(tokenId, 1, 16);
        }  else if (tokenId < 9000) {
            value = random(tokenId, 1, 11);
        }  else if (tokenId < 10000) {
            value = random(tokenId, 1, 6);
        } else {
            value = 1;
        }
        return value;
    }

    function getRgbs(uint tokenId, uint baseColor) internal pure returns (uint256[3] memory rgbValues) {
        if (baseColor > 0) {
            for (uint i = 0; i < 3; i++) {
                if (baseColor == i + 1) {
                    rgbValues[i] = 255;
                } else {
                    rgbValues[i] = utils.random(tokenId + i, 0, 256);
                }
            }
        } else {
            for (uint i = 0; i < 3; i++) {
                rgbValues[i] = 255;
            }
        }
        return rgbValues;
    }

    function getMintPhase(uint tokenId) internal pure returns (uint mintPhase) {
        if (tokenId <= 1000) {
            mintPhase = 1;
        } else if (tokenId <= 5000) {
            mintPhase = 2;
        } else {
            mintPhase = 3;
        }
    }

    function secondsRemaining(uint end) internal view returns (uint) {
        if (block.timestamp <= end) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }

    function minutesRemaining(uint end) internal view returns (uint) {
        if (secondsRemaining(end) >= 60) {
            return (end - block.timestamp) / 60;
        } else {
            return 0;
        }
    }
}