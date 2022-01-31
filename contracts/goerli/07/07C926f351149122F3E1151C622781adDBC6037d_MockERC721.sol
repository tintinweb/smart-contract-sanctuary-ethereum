// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10;


//import "../lib/solmate/src/tokens/ERC721.sol";
//import "../lib/solmate/src/tokens/ERC1155.sol";
import "./ERC721.sol";
import "./ERC1155.sol";
import "./Ownable.sol";

contract MockERC721 is ERC721, Ownable {
    string public baseUri;

    constructor(string memory name, string memory symbol, string memory _uri) ERC721(name, symbol) {
        baseUri = _uri;
    } 

    function mint() public {
        _mint(msg.sender, totalSupply);
    }

    function tokenURI(uint id) public view override returns (string memory) {
        return baseUri;
    }

    function setTokenURI(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, Ownable) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x7f5828d0;   // ERC165 Interface ID for ERC173
    }
}

contract MockERC1155 is ERC1155, Ownable {

    string public name;
    string public symbol;
    string public baseUri;

    constructor(string memory _name, string memory _symbol, string memory _uri) {
        name = _name;
        symbol = _symbol;
        baseUri = _uri;
    } 

    function mint(uint tokenId, uint amount) public {
        _mint(msg.sender, tokenId, amount, "");
    }

    function setTokenURI(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    function uri(uint id) public view override returns (string memory) {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC1155, Ownable) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c || // ERC165 Interface ID for ERC1155MetadataURI
            interfaceId == 0x7f5828d0;   // ERC165 Interface ID for ERC173
    }
}