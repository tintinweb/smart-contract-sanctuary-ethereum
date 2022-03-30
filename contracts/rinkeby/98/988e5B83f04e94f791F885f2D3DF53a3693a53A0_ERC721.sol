//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

contract ERC721 {
    string private _name;
    string private _symbol;
    address private _owner;

    mapping(uint256 => string) private _tokens;
    uint256 private _totalSupply;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory) {
        return _tokens[tokenId];
    }

    function balanceOf(address owner) public view returns (uint256){
        require(owner != address(0), "ERC721: balanceOf zero address");

        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address){
        return _owners[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from != address(0), "ERC721: transferFrom zero address from");
        require(to != address(0), "ERC721: transferFrom zero address to");
        require(((_owners[tokenId] == msg.sender) || (_tokenApprovals[tokenId] == msg.sender) || (_operatorApprovals[from][msg.sender] == true)), "ERC721: transferFrom no access to this token");

        _owners[tokenId] = to;
    }

    function approve(address to, uint256 tokenId) public {
        require(to != address(0), "ERC721: approve zero address");
        require(_owners[tokenId] == msg.sender, "ERC721: approve you are not owner of token");

        _tokenApprovals[tokenId] = to;
    }

    function getApproved(uint256 tokenId) public view returns (address){
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != address(0), "ERC721: setApprovalForAll zero address");

        _operatorApprovals[msg.sender][operator] = approved;
    }

    function isApprovalForAll(address owner, address operator) public view returns(bool) {
        require(owner != address(0), "ERC721: isApprovalForAll zero address owner");
        require(operator != address(0), "ERC721: isApprovalForAll zero address operator");

        return _operatorApprovals[owner][operator];
    }

    function mint(address to, string memory url) public{
        require(_owner == msg.sender, "ERC721: mint can call only by owner");
        require(to != address(0), "ERC721: mint zero address");
        require(bytes(url).length != 0, "ERC721: mint empty url");

        _tokens[_totalSupply] = url;
        _owners[_totalSupply] = to;
        _balances[to] += 1;
        _totalSupply += 1;
    }
}