/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721 {

    event Transfer (address indexed from, address indexed to, uint256 tokenId);
    event Approval (address indexed owner, address indexed approved, uint256 tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
 
    function balanceOf(address owner)  view external returns(uint256 tokenId);
    function ownerOf(uint256 tokenId)  view external returns(address owner);

    function transferFrom (address from, address to, uint256 tokenId) external;
    function approve (address to, uint256 tokenId) external;
    function getApproved (uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool) external;
    function isApprovedForAll (address owner, address operator) external returns(bool);
    function safeTransferFrom (address from, address to, uint256 tokenId) external;


    function name() external view returns (string memory);
    function symbol() external view returns (string memory);


    function mint(address to , uint256 tokenId) external;
    function burn(address from, uint256 tokenId) external;



}
 

contract SHAZ721 is ERC721 {

   string private _name = "SHAZ";
    string private _symbol = "SHZ";

    mapping(uint256 => address) private owners;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;

    // uint256 private _totalSuppy = 1000 ether;

    constructor() {

    }

    // function totalSupply() public view virtual override returns (uint256) {
    //     return _totalSuppy;
    // }

    function name() public view virtual override returns (string memory){ 
        return _name;
    }

    function symbol() public view virtual override returns (string memory){
        return _symbol;
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return owners[tokenId] != address(0);
    }

    function _isOwnedOrApproved(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: Call for non-existent token");
        address owner = owners[tokenId];
        return (owner == spender || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _beforeTransfer(address from, address to, uint256 tokenId)  internal view returns (bool) {
        require(from != address(0), "ERC721: From Address should not be Zero");
        require(to != address(0), "ERC721: To Address should not be Zero");
        require(_exists(tokenId), "ERC721: Call for non existent token");
        require(owners[tokenId] == from, "ERC721: Owner is incorrect");

        return true;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return balances[owner];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address){
        return owners[tokenId];
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address){
        return owners[tokenId];
    }

    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override{
        _beforeTransfer(from, to, tokenId);
        require(_isOwnedOrApproved(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }



    function _transfer(address from, address to, uint tokenId) internal virtual {
    //    _beforeTransfer(from, to, tokenId);
        require(from != address(0), "ERC721: From Address should not be Zero");
        require(to != address(0), "ERC721: To Address should not be Zero");
        _approve(address(0), tokenId);

        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function isApprovedForAll(address owner,address operator) public view virtual override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner,  msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC721: approve to caller");
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: Call for non existent token" );
        return tokenApprovals[tokenId];
    }


    function transferFrom(address from,address to,uint256 tokenId) public virtual override{ 
        require(_isOwnedOrApproved(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }   

    function mint(address to, uint256 tokenId) public virtual override{
        require(to != address(0), "ERC721: Address belongs to zero");
        require(!_exists(tokenId), "Token Already Exists");

        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

    }

    function burn(address from, uint256 tokenId) public virtual override {
        require(from != address(0), "ERC721: Addres belongs to zero");
        require(_exists(tokenId), "ERC721: burn call belongs to non-existing token");

        balances[from] -= 1;
        owners[tokenId] = address(0);

        emit Transfer(from, address(0), tokenId);
    }  
}