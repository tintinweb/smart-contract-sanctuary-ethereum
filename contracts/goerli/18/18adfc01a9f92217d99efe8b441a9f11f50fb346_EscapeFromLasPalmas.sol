/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract EscapeFromLasPalmas {
    address public owner;
    uint8 public tokenIdCounter;
    uint256 public price = 1000000000000000; // 0.001 ether
    uint256 public maxSupply = 10;

    constructor() {
        owner = msg.sender;
    }

    // ERC721 --------------------------------------------------------------->>
    mapping(address => uint256) public balanceOf; // Ignored - always returns default
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public approvedForToken;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _candidate, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _candidate, bool _approved);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(ownerOf[_tokenId] == _from, "WRONG_FROM"); 
        require(msg.sender == _from || msg.sender == approvedForToken[_tokenId] || isApprovedForAll[_from][msg.sender], "UNAUTHORIZED");

        delete approvedForToken[_tokenId]; // Clear approvals from the previous tokenOwner
        ownerOf[_tokenId] = _to; // Transfer
        emit Transfer(_from, _to, _tokenId); // Emit Transfer
    }

    function approve(address _candidate, uint256 _tokenId) public {
        address tokenOwner = ownerOf[_tokenId];
        require(msg.sender == tokenOwner || isApprovedForAll[tokenOwner][msg.sender], "NOT_AUTHORIZED");
        approvedForToken[_tokenId] = _candidate;
        emit Approval(tokenOwner, _candidate, _tokenId);
    }

    function setApprovalForAll(address _candidate, bool _approved) public {
        isApprovedForAll[msg.sender][_candidate] = _approved;
        emit ApprovalForAll(msg.sender, _candidate, _approved);
    }

    // UNSAFE - USE AT OWN RISK
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public { transferFrom(_from, _to, _tokenId); }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) public { transferFrom(_from, _to, _tokenId); }
    // <<--------------------------------------------------------------- ERC721


    // ERC721Metadata ------------------------------------------------------->>
    string public name = "Escape from Las Palmas";
    string public symbol = "EFLP";

    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        string memory htmlUri = string(abi.encodePacked('https://billybones.s3.amazonaws.com/public/eflp', toHexString(_tokenId, 1), '.html'));
        string memory json = string(abi.encodePacked('{"name": "eflp", "description": "this is eflp", "animation_url": "', htmlUri, '"}'));
        string memory jsonUri = string(abi.encodePacked("data:application/json;base64,", base64Encode(bytes(json))));  
        return jsonUri;
    }
    // <<------------------------------------------------------- ERC721Metadata


    // ERC165 --------------------------------------------------------------->>
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == 0x80ac58cd || // IERC721
               _interfaceId == 0x5b5e139f || // IERC721Metadata
               _interfaceId == 0x01ffc9a7; // IERC165
    }
    // <<--------------------------------------------------------------- ERC165


    // Other functions ------------------------------------------------------>>
    function mint() public payable {
        tokenIdCounter++;
        require(tokenIdCounter <= maxSupply, "SOLD_OUT");
        require(msg.value >= price, "SEND_MORE_ETH");
        
        ownerOf[tokenIdCounter] = msg.sender;
        emit Transfer(address(0), msg.sender, tokenIdCounter);
    }

    // Required by etherscan.io
    function totalSupply() public view virtual returns (uint256) {
        return tokenIdCounter;
    }

    function withdraw() public {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "WITHDRAW_ERROR");
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes16 _SYMBOLS = "0123456789abcdef";
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
    // <<----------------------------------------------------- Other functions
}