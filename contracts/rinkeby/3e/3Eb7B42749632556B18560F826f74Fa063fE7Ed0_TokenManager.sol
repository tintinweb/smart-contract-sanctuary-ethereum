/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract TokenManager{
    address owner;

    mapping(string => address) private tokenList;
    mapping(address => string) private specy;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    // Event list
    event TransferOwnership(address newOwner);
    event RenounceOwnership(uint32 time_stamp);
    event AddNewToken(string token_name, address token_address);
    event RemoveToken(string token_name);


    constructor() {
        owner = msg.sender;
    }



    //@@ this function is for adding new token into token list
    function setToken(string memory _name, address _address) public onlyOwner{
        require(_address != address(0), "That address is not correct. Please recheck token's address.");
        require(tokenList[_name] != _address, "That token already exists.");

        tokenList[_name] = _address;

        specy[_address] = _name;
        
        emit AddNewToken(_name, _address);
    }



    //@@ this function is for deleting token into token list
    // Warning: If you delete a token address, the token address will not be found in any pools associated with that token
    // In that case, the liquidity of your exchage website may be affected
    function removeToken(string memory _name) public onlyOwner{
        delete specy[tokenList[_name]];

        delete tokenList[_name];

        emit RemoveToken(_name);
    }



    //@@ this function is for getting the address of certain token
    function getTokenAddress(string memory _name) public view returns(address) {
        return tokenList[_name];
    }


    function getTokenName(address _address) public view returns(string memory) {
        return specy[_address];
    }



    //@@ this function is for trasfering the Ownership of token'manager
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Please recheck new Owner address.");
        owner = _newOwner;

        emit TransferOwnership(_newOwner);
    }



    //@@ this function is for renouncing ownership of token'manager
    // Warning: after runing this function,  you can't run any functions in this contract like addToken, removeToken...
    function renounceOwnership() public onlyOwner {
        owner = address(0);

        emit RenounceOwnership(uint32(block.timestamp));
    }
}