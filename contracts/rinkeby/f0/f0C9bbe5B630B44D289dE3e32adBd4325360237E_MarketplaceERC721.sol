// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract MarketplaceERC721 {

    uint tokenIdCounter; // created to generate new tokenIds for each token

    string private _name; // name of token

    string private _symbol; // symbol of token

    mapping(uint256 => address) private _owners; // mapping for owners of tokens

    mapping(address => uint256) private _balances; // mapping for token balances of users

    mapping(uint256 => address) private _tokenApprovals; // mapping for specific token approvals

    mapping(address => mapping(address => bool)) private _operatorApprovals; // mapping for full approvals

    mapping(uint256 => string) private _tokenURIs; // mapping for token URIs

    constructor(string memory name_, string memory symbol_) { // constructor of my ERC721 token
        _name = name_;
        _symbol = symbol_;
    }

    // ---EVENTS---

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ---READING FUNCTIONS---

    // returns name of contract
    function name() external view returns (string memory) {
        return _name;
    }

    // returns symbol of contract
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    // balance of specific user
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Enter correct address, please");
        return _balances[owner];
    }

    // returns owner of specific token
    function ownerOf(uint256 tokenId) external view returns (address) {
        require(_owners[tokenId] != address(0), "The token does not exist");
        return _owners[tokenId];
    }

    // returns tokenURI of specific token
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_owners[tokenId] != address(0), "The token does not exist");
        return _tokenURIs[tokenId];
    }

    // returns account, approved to transfer this token
    function getApproved(uint256 tokenId) external view returns (address) {
        require(_owners[tokenId] != address(0), "The token does not exist");
        return _tokenApprovals[tokenId];
    }

    // returns operator status for this account
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        require(owner != operator, "You can use your tokens");
        return _operatorApprovals[msg.sender][operator];
    }
    
    // ---WRITING FUNCTIONS---
    function approve(address to, uint256 tokenId) external {
        require(_owners[tokenId] == msg.sender, "Not an owner of this token");
        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    // sets operator status to another account
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "You don't need to approve yourself");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        //require(_tokenApprovals[tokenId] == msg.sender || (_operatorApprovals[from][to] == true && _owners[tokenId] == from) || _owners[tokenId == msg.sender]);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function mint(address _to, string memory _tokenURI) external {
        _balances[_to] += 1;
        _owners[tokenIdCounter] = _to;
        _tokenURIs[tokenIdCounter] = _tokenURI;
        emit Transfer(address(0), _to, tokenIdCounter);
        tokenIdCounter += 1;
    }

    
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}