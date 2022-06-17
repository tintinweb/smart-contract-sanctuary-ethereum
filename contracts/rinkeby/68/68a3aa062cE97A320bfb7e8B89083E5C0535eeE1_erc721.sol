/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract erc721 {
    string private _name;
    string private _symbol;
    
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = _owners[_tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function isApprovedOrOwner (address _spender, uint256 _tokenId) public view returns (bool)  {
        address _owner = ownerOf(_tokenId);
        return (_spender == _owner || isApprovedForAll(_owner, _spender) || getApproved(_tokenId) == _spender);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public returns(bool) {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: caller is not token owner nor approved");
        require(_to != address(0), "ERC721: transfer to the zero address");
        _tokenApprovals[_tokenId] = address(0);
        emit Approval(ownerOf(_tokenId), address(0), _tokenId);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        return true;
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(msg.sender != _operator, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function approve(address _approved, uint256 _tokenId) public {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_owners[_tokenId] != address(0), "ERC721: invalid token ID");
        return _tokenApprovals[_tokenId];
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory){

    }

    function mint(address _to, uint256 _tokenId) public  {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(_owners[_tokenId] == address(0), "ERC721: token already minted");
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(address(0), _to, _tokenId);
    }

    function burn(uint256 _tokenId) public  {
        address owner = ownerOf(_tokenId);
        _tokenApprovals[_tokenId] = address(0);
        emit Approval(ownerOf(_tokenId), address(0), _tokenId);
        _balances[owner] -= 1;
        delete _owners[_tokenId];
        emit Transfer(owner, address(0), _tokenId);
    }
}