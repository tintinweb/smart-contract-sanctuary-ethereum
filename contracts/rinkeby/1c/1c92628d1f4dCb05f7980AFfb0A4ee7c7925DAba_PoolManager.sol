/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

contract TokenManager{
    address owner;

    mapping(string => address) token;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addToken(string memory _name, address _address) public onlyOwner returns(bool){
        require(_address != address(0), "That address not exists.");
        require(token[_name] != _address, "That token already exists.");

        token[_name] = _address;

        return true;
    }

    function removeToken(string memory _name) public onlyOwner returns(bool){
        delete token[_name];
        
        return true;
    }

    function getTokenAddress(string memory _name) public view returns(address) {
        return token[_name];
    }
}

contract PoolManager is TokenManager {
    mapping(address => mapping(address => address)) pools;

    function addPool(string memory _token1, string memory _token2, address _poolAddr) public returns(bool) {
        require(getTokenAddress(_token1) != address(0), "Address of first token is not exists.");
        require(getTokenAddress(_token2) != address(0), "Address of second token is not exists.");
        require(_poolAddr != address(0), "Address of pool is wrong.");

        pools[getTokenAddress(_token1)][getTokenAddress(_token2)] = _poolAddr;
        return true;
    }

    function removePool(string memory _token1, string memory _token2) public returns(bool){
        require(getTokenAddress(_token1) != address(0), "Address of first token is not exists.");
        require(getTokenAddress(_token2) != address(0), "Address of second token is not exists.");

        delete pools[getTokenAddress(_token1)][getTokenAddress(_token2)];
        return true;
    }

    function getPoolAddress(string memory _token1, string memory _token2) public view returns(address){
        require(getTokenAddress(_token1) != address(0), "Address of first token is not exists.");
        require(getTokenAddress(_token2) != address(0), "Address of second token is not exists.");

        return pools[getTokenAddress(_token1)][getTokenAddress(_token2)];
    }
}