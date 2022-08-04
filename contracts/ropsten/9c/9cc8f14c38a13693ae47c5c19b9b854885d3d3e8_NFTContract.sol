/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity ^0.6.6;

contract NFTContract {
    uint public hashNo = 10;
    uint public cidNo = 20;
    
    function setHash(uint _hash) public {
        hashNo = _hash;
    }
    function setCID(uint _cid) public {
        cidNo = _cid;
    }
}