/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BlockshipProxy {

    Blockship blockshipContract;

    constructor (address blockshipContractAddress) {
        blockshipContract = Blockship(blockshipContractAddress);
    }

    // reads
    function balanceOf(address ownerAddr) external view returns (uint256) {
        return blockshipContract.balanceOf(ownerAddr);
    }

    function baseURI() external view returns (string memory) {
        return blockshipContract.baseURI();
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        return blockshipContract.getApproved(tokenId);
    }

    function isApprovedForAll(address ownerAddr, address operator) external view returns (bool) {
        return blockshipContract.isApprovedForAll(ownerAddr, operator);
    }

    function name() external view returns (string memory) {
        return blockshipContract.name();
    }

    function symbol() external view returns (string memory) {
        return blockshipContract.symbol();
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return blockshipContract.tokenURI(tokenId);
    }

    function owner() external view returns (address payable) {
        return blockshipContract.owner();
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return blockshipContract.ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return blockshipContract.supportsInterface(interfaceId);
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        return blockshipContract.tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(address ownerAddr, uint256 index) external view returns (uint256) {
        return blockshipContract.tokenOfOwnerByIndex(ownerAddr, index);
    }

    function totalSupply() external view returns (uint256) {
        return blockshipContract.totalSupply();
    }

    // writes
    function approve(address to, uint256 tokenId) external {
        blockshipContract.approve(to, tokenId);
    }

    function data_set(string memory _value, uint256 data_passthrough) external {
        blockshipContract.data_set(_value, data_passthrough);
    }

    function initialize_token(uint256 element, uint32 gasLimit) external payable {
        blockshipContract.initialize_token{value: msg.value}(element, gasLimit);
    }

    function mint() external payable {
        blockshipContract.mint{value: msg.value}();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        blockshipContract.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        blockshipContract.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool _approved) external {
        blockshipContract.setApprovalForAll(operator, _approved);
    }

    function setBaseURI(string memory baseURI_) external {
        blockshipContract.setBaseURI(baseURI_);
    }

    function set_base_uri(string memory baseURI_) external {
        blockshipContract.set_base_uri(baseURI_);
    }

    function set_oracle(address payable _acria_node) external {
        blockshipContract.set_oracle(_acria_node);
    }

    function set_price(uint256 _price) external {
        blockshipContract.set_price(_price);
    }

    function set_token_max(uint256 _max) external {
        blockshipContract.set_token_max(_max);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        blockshipContract.transferFrom(from, to, tokenId);
    }

    function value_callback_bytes(string memory _value, uint256 data, uint256 data_passthrough, bytes8 _requestID) external {
        blockshipContract.value_callback_bytes(_value, data, data_passthrough, _requestID);
    }
}

interface Blockship {
    // reads
    function balanceOf(address owner) external view returns (uint256 balance);
    function baseURI() external view returns (string memory);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function owner() external view returns (address payable owner);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function totalSupply() external view returns (uint256);

    // writes
    function approve(address to, uint256 tokenId) external;
    function data_set(string memory _value, uint256 data_passthrough) external;
    function initialize_token(uint256 element, uint32 gasLimit) external payable;
    function mint() external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function setBaseURI(string memory baseURI_) external;
    function set_base_uri(string memory baseURI_) external;
    function set_oracle(address payable _acria_node) external;
    function set_price(uint256 _price) external;
    function set_token_max(uint256 _max) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function value_callback_bytes(string memory _value, uint256 data, uint256 data_passthrough, bytes8 _requestID) external;
}