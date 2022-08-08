/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Destruct{
    function destroyMe(address payable add) public{
        selfdestruct(add);
    }
}


contract Proxy{
    uint x = 5;
    Destruct d = new Destruct();
    event Log(uint x);

    function runDestoryMe(address payable add) public returns(uint){
        bytes memory data = abi.encodeWithSelector(Destruct.destroyMe.selector, add);
        address(d).delegatecall(data);
        emit Log(x);
        return x;
    }
}