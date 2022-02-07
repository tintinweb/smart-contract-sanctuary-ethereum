/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract Genesis is ERC721, ERC721Metadata {
    string public _name;
    string public _symbol;
    uint256 public _balance;
    address public _owner;

    constructor() {
        _balance = 1;
        _name = "Genesis";
        _symbol = "A0";
        
        _owner = 0xd0E922378E3440Eb8586aE034C28309F393E0FbB;
        emit Transfer(address(0), _owner, _balance);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }

  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        //return "https://gist.githubusercontent.com/smatthewenglish/dd4086bceaf4252d7c91de36de105958/raw/20f0c11d66f87327695038e754c462a0ddf06063/falling.json";
        
        string memory tokenName = "MyToken #666";
        string memory tokenDescription = "An example SVG-based, fully on-chain NFT";
        string memory svgString = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"><circle cx={500} cy={500} r={400} fill="papayawhip" /></svg>';

        string memory json = string(abi.encodePacked('{"name":"', tokenName, '","description":"', tokenDescription, '","image": "data:image/svg+xml;base64,', encode(bytes(svgString)), '"}'));
        return string(abi.encodePacked("data:application/json;base64,", encode(bytes(json))));    
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balance;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(msg.sender != _owner, "ERC721: not yours to give away!");
        _owner = 0xAB915162DB74d70b7C2E2aE57Be147Ebbd9e18F5;
        emit Transfer(from, 0xAB915162DB74d70b7C2E2aE57Be147Ebbd9e18F5, _balance);
    }

    function burn() public virtual {
        require(msg.sender != _owner, "ERC721: not yours to break!");
        _owner = 0x000000000000000000000000000000000000dEaD;
        emit Transfer(_owner, 0x000000000000000000000000000000000000dEaD, _balance);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {}

    function getApproved(uint256 tokenId) public view virtual override returns (address) {}

    function setApprovalForAll(address operator, bool approved) public virtual override {}

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 ERC165 = 0x01ffc9a7;
        bytes4 ERC721 = 0x80ac58cd;
        bytes4 ERC721Metadata = 0x5b5e139f;
        return interfaceId == ERC165 
            || interfaceId == ERC721
            || interfaceId == ERC721Metadata;
    }
}