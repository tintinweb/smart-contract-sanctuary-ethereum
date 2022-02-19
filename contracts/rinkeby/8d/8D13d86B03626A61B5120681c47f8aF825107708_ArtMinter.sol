// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    string public name;
    string public symbol;
    
    address public minter;
    uint256 public totalSupply = 0;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_) {
        minter = msg.sender;
        name = name_;
        symbol = symbol_;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    function mint(address to) public returns (uint256) {
        require(msg.sender == minter);
        uint256 tokenIdToMint = ++totalSupply;
        _mint(to, tokenIdToMint);
        return tokenIdToMint;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner);
    }
}


contract ArtMinter {
    event ArtMinted(address sender, uint256 tokenId);
    uint256 constant COST_OF_ART = 0.03 ether;

    address payable public owner;
    ERC721 public iERC721;
    constructor() {
        owner = payable(msg.sender);
        iERC721 = new ERC721("art", "ART");
    }
    
    function mint() external payable {
        require(msg.value >= COST_OF_ART);
        uint256 tokenId = iERC721.mint(msg.sender);
        emit ArtMinted(msg.sender, tokenId);
        owner.transfer(msg.value);
    }
}