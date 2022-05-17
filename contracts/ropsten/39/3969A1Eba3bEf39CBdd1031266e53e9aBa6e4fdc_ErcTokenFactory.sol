// SPDX-License-Identifier: MIT
pragma solidity ^0.4.14;

import {CommonToken} from "./MANAToken.sol";

contract ErcTokenFactory{
    event TokenAddress(CommonToken token);

    function newErc20Instance(string _symbol,string _name,uint8 _decimals) public returns (CommonToken)
    {
       CommonToken token =   new CommonToken(_symbol,_name,_decimals,msg.sender);
       TokenAddress(token);
       return token;
    }
}