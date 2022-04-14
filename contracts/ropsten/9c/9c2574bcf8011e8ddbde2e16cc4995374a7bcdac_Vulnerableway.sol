/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.6.6;


contract test{
    fallback() payable external{
        selfdestruct;
    }
}

contract Vulnerableway {
    function withdraw(address payable _to) public payable {
        // This forwards 2300 gas, which may not be enough if the recipient
        // is a contract and gas costs change.
        _to.send(msg.value);
    }
}

contract  Fixedway {
    function withdraw(address payable _to) public payable {
        // This forwards all available gas. Be sure to check the return value!
         _to.call{value:msg.value}("");

    }
}