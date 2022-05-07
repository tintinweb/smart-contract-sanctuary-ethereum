/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// InuDAO by 0xInuarashi
// Seriously. Just a Joke. (Or maybe not)

abstract contract ERC721ICompliant {
    // Name and Symbol
    string public name;
    string public symbol;

    // Constructor
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_; }

    // Magic Events 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Magic Logic
    function totalSupply() public virtual view returns (uint256) {}
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {}
    function balanceOf(address address_) public virtual view returns (uint256) {}

    // Magic Compliance
    function supportsInterface(bytes4 interfaceId_) public virtual pure returns (bool) { 
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    // Magic NFT Metadata
    string internal baseTokenURI;
    string internal baseTokenURI_EXT;

    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; }
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } 
        return string(_buffer); 
    }

    function _setBaseTokenURI(string memory uri_) internal {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal {
        baseTokenURI_EXT = ext_;
    }

    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        return string(abi.encodePacked(
            baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

contract InuDAOToken is ERC721ICompliant("InuDAO", "InuDAO"), Ownable {

    // Internal Trackers
    uint256 public totalMembers;
    function totalSupply() public view override returns (uint256) {
        return totalMembers - burnedTokenIdsUnassigned.length; 
    }

    // Token Settings
    function setBaseTokenURI(string memory uri_) public onlyOwner {
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string memory ext_) public onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // Ownership Tracker
    struct OwnerData {
        address owner;
        uint40 memberSince;
    }
    mapping(uint256 => OwnerData) public tokenToOwnerData;
    function ownerOf(uint256 tokenId_) public view override returns (address) {
        return tokenToOwnerData[tokenId_].owner;
    }

    // Membership Tracker
    mapping(address => uint256) public addressToMemberId;
    function balanceOf(address member_) public view override returns (uint256) {
        return addressToMemberId[member_] != 0 ? 1 : 0; 
    }

    // Next Token Tracker
    uint256[] public burnedTokenIdsUnassigned;
    function getNextTokenId() public view returns (uint256) {
        return burnedTokenIdsUnassigned.length > 0 ? 
            burnedTokenIdsUnassigned[burnedTokenIdsUnassigned.length - 1] : 
            totalMembers + 1;
    }
    
    function mint(address to_) external onlyOwner {
        uint256 _tokenId = getNextTokenId();
        
        if (_tokenId == totalMembers + 1) { totalMembers++; }
        else { burnedTokenIdsUnassigned.pop(); }

        tokenToOwnerData[_tokenId] = OwnerData(to_, uint40(block.timestamp));
        addressToMemberId[to_] = _tokenId;

        emit Transfer(address(0), to_, _tokenId);
    }

    function burn(address from_) external onlyOwner {
        uint256 _tokenId = addressToMemberId[from_];
        
        require(_tokenId != 0, "Invalid member");

        delete tokenToOwnerData[_tokenId];
        delete addressToMemberId[from_];
        burnedTokenIdsUnassigned.push(_tokenId);

        emit Transfer(from_, address(0), _tokenId);
    }
}