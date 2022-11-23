// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract QAANFT is IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    // owner of token
    address private _owner;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Send locker
    bool private _locked;
    // link to object
    string private _baseURI;
    // approved address for this token
    address private _tokenApproval;
    // extension for tokenURI;
    string private _baseExtension;
    constructor (string memory name_, string memory symbol_, string memory baseURI_) {
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _locked = false;
        _baseExtension = ".json";
    }
    function balanceOf(address tokenOwner) public view virtual override returns (uint256) {
        require(tokenOwner != address(0), "ERC721: balance query for the zero address");
        if(_owner == tokenOwner)
            return 1;
        else
            return 0;
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _owner;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function toString(uint256 value) internal pure returns (string memory) {
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       require(tokenId==1, "Only one element in the collection");
       return string(abi.encodePacked(_baseURI, tokenId.toString(), _baseExtension));
    }
    function baseURI() public view virtual returns (string memory) {
       return _baseURI;
    }
    function totalSupply() public view virtual returns (uint256) {
       return 1;
    }
    function approve(address to, uint256 tokenId) public virtual override {
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return _tokenApproval;
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_owner == msg.sender);
        require(operator != msg.sender, "ERC721: approve to caller");
    }
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_owner == from);
        require(_locked!=false);
        require(to != address(0), "ERC721: transfer to the zero address");
        _owner=to;
        _locked=true;
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
    }    
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
        || interfaceId == type(IERC721Metadata).interfaceId;
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return 0==0;
    }
    function renounceOwnership() public virtual {
    }
    function transferOwnership(address newOwner) public virtual {
    }
    function mint(address _to, uint256 _mintAmount) public payable {
    }
    fallback() external payable virtual {
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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