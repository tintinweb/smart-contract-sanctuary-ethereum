// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld{
    //wanted to deploy a contract in eth before merge

    function HelloEthereum() public pure returns(string memory){
        return("I love Ethereum");
    }
}