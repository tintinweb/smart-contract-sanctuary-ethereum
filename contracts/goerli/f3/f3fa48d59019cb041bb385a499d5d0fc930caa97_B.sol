/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract BInterface {
    function ca(uint x) virtual external returns (uint);

    function getValue() virtual public view returns (uint);
}

contract B is BInterface{
    uint internal num;

    address public admin;

    address public token;

    constructor(){
        admin = msg.sender;
    }


    function ca(uint x) external virtual override returns (uint){
        num = num + x;

        return num;
    }

    function getValue() public view virtual override returns (uint){
        return num;
    }

    function setToken(address _token) external returns (bool){
        require(_token != address(0), "Token is zero address");
        token = _token;
        return true;
    }
}