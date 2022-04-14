/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8.0;

contract Second_contract {
    function theDoo(address cont) public  returns(bytes memory){
        bytes memory b;
        bool c;
        (c , b) = cont.call(abi.encodeWithSignature("dodo"));
        return b;
    }
}